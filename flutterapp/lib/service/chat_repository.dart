import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutterapp/model/chat_thread_state.dart';
import 'package:flutterapp/model/conversation_info.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/service/chat_manager.dart';

class ChatRepository extends ChangeNotifier {
  ChatRepository(ChatManager transport) {
    attachTransport(transport);
  }

  static const int _pageSize = 50;
  static const Duration _pendingAckWindow = Duration(hours: 1);

  ChatManager? _transport;
  ChatListener? _listener;

  bool _isConnected = false;

  final Map<int, _ThreadCache> _threads = {};
  final List<ConversationInfo> _conversations = [];
  final Map<int, int> _lastReadSentByConversation = {};
  final Map<String, Message> _pendingOutgoing = {};
  final Set<int> _activeThreads = {};

  bool _conversationsLoaded = false;
  bool _loadingConversations = false;
  String? _conversationsError;
  Completer<void>? _conversationsCompleter;

  int? _serverCursor;

  final Random _random = Random();
  int _localMessageCounter = 0;

  bool get isConnected => _isConnected;
  bool get conversationsLoaded => _conversationsLoaded;
  bool get conversationsLoading => _loadingConversations;
  String? get conversationsError => _conversationsError;

  List<ConversationInfo> get conversations => List.unmodifiable(_conversations);

  void attachTransport(ChatManager transport) {
    if (identical(_transport, transport)) return;

    if (_transport != null && _listener != null) {
      _transport!.removeListener(_listener!);
    }

    _transport = transport;
    _listener = ChatListener(
      connection: _handleConnectionChanged,
      newMessage: _handleLegacyIncomingMessage,
      loadMessages: _handleLegacyLoadedMessages,
      conversations: _handleLegacyConversations,
      onMessageRead: _handleMessageRead,
      onEvent: _handleSyncEvent,
      error: _handleTransportError,
    );
    _transport!.addListener(_listener!);
    _isConnected = _transport!.isConnected;
    _publishResumeState();
  }

  void clear() {
    _threads.clear();
    _conversations.clear();
    _lastReadSentByConversation.clear();
    _pendingOutgoing.clear();
    _activeThreads.clear();
    _serverCursor = null;
    _conversationsLoaded = false;
    _loadingConversations = false;
    _conversationsError = null;
    _conversationsCompleter = null;
    _transport?.resetSession();
    notifyListeners();
  }

  ChatThreadState? threadFor(int conversationId) {
    final cache = _threads[conversationId];
    if (cache == null) return null;

    return ChatThreadState(
      conversationId: conversationId,
      messages: List.unmodifiable(cache.messages),
      initialLoaded: cache.initialLoaded,
      loadingInitial: cache.loadingInitial,
      loadingOlder: cache.loadingOlder,
      hasMoreOlder: cache.hasMoreOlder,
      errorMessage: cache.errorMessage,
    );
  }

  Future<void> loadConversations({bool force = false}) async {
    if (_transport == null) return;

    if (_loadingConversations) {
      return _conversationsCompleter?.future ?? Future<void>.value();
    }

    if (_conversationsLoaded && !force) {
      return Future<void>.value();
    }

    _loadingConversations = true;
    _conversationsError = null;
    _conversationsCompleter = Completer<void>();
    notifyListeners();

    await _transport!.loadConversations(
      cursor: _serverCursor,
      forceFull: force || !_conversationsLoaded,
    );
    return _conversationsCompleter!.future;
  }

  Future<void> ensureThreadLoaded(
    int conversationId, {
    bool force = false,
  }) async {
    if (_transport == null) return;

    _activeThreads.add(conversationId);

    final cache = _threads.putIfAbsent(
      conversationId,
      () => _ThreadCache(),
    );

    if (cache.loadingInitial) {
      return cache.initialCompleter?.future ?? Future<void>.value();
    }

    if (cache.initialLoaded && !force) {
      return Future<void>.value();
    }

    cache.loadingInitial = true;
    cache.errorMessage = null;
    cache.initialCompleter = Completer<void>();
    notifyListeners();

    await _transport!.loadLast(conversationId);
    return cache.initialCompleter!.future;
  }

  Future<void> loadOlder(int conversationId) async {
    if (_transport == null) return;

    _activeThreads.add(conversationId);

    final cache = _threads.putIfAbsent(
      conversationId,
      () => _ThreadCache(),
    );

    if (!cache.initialLoaded || cache.loadingInitial || cache.loadingOlder) {
      return cache.olderCompleter?.future ?? Future<void>.value();
    }

    if (!cache.hasMoreOlder || cache.messages.isEmpty) {
      return Future<void>.value();
    }

    cache.loadingOlder = true;
    cache.errorMessage = null;
    cache.olderCompleter = Completer<void>();
    notifyListeners();

    await _transport!.loadBefore(cache.messages.first);
    return cache.olderCompleter!.future;
  }

  Future<void> searchUsers(String query) {
    return _transport?.searchUsers(query) ?? Future<void>.value();
  }

  void sendMessage(
    int conversationId,
    String text, {
    required int senderId,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final cache = _threads.putIfAbsent(
      conversationId,
      () => _ThreadCache(),
    );

    final optimistic = Message(
      id: null,
      text: trimmed,
      senderId: senderId,
      createdAt: DateTime.now().toUtc(),
      conversationId: conversationId,
      clientKey: _nextClientKey(),
    );

    cache.messages.add(optimistic);
    cache.errorMessage = null;
    _pendingOutgoing[optimistic.clientKey!] = optimistic;
    _sortAndReindex(cache);
    _touchConversationPreview(conversationId, trimmed, optimistic.createdAt);

    notifyListeners();
    _dispatchPendingOutgoing();
  }

  void markConversationAsRead(int conversationId, int lastMessageReadId) {
    if (lastMessageReadId <= 0) return;

    final prev = _lastReadSentByConversation[conversationId];
    if (prev != null && lastMessageReadId <= prev) return;

    _lastReadSentByConversation[conversationId] = lastMessageReadId;
    _transport?.markConversationAsRead(conversationId, lastMessageReadId);
  }

  void _handleSyncEvent(Map<String, dynamic> event) {
    final type = (event['type']?.toString() ?? '').toLowerCase();
    final data = _eventData(event['data']);

    switch (type) {
      case 'sync.snapshot':
      case 'snapshot':
        _handleSnapshot(event, data);
        break;

      case 'sync.delta':
      case 'delta':
        _handleDelta(event, data);
        break;

      case 'thread.snapshot':
      case 'messages':
        _handleThreadPayload(event, data, replaceServerMessages: true);
        break;

      case 'thread.delta':
      case 'new_message':
      case 'message.upsert':
        _handleThreadPayload(event, data, replaceServerMessages: false);
        break;

      case 'message.ack':
        _handleMessageAck(event, data);
        break;

      case 'read.update':
      case 'messages_read':
        _handleReadUpdate(event, data);
        break;
    }
  }

  void _handleSnapshot(Map<String, dynamic> event, Map<String, dynamic> data) {
    _updateServerCursor(event, data);

    final conversations = _parseConversations(data['conversations']);
    if (conversations.isNotEmpty) {
      _conversations
        ..clear()
        ..addAll(conversations);
      _sortConversations();
      _conversationsLoaded = true;
      _loadingConversations = false;
      _conversationsError = null;
      _completeCompleter(_conversationsCompleter);
    }

    final threadBlocks = data['threads'];
    if (threadBlocks is List) {
      if (_looksLikeMessagesList(threadBlocks)) {
        _groupAndApplyMessages(
          _parseMessages(threadBlocks),
          replaceServerMessages: true,
          completeInitial: true,
          touchPreview: true,
        );
      } else {
        for (final rawThread in threadBlocks.whereType<Map>()) {
          final thread = Map<String, dynamic>.from(rawThread);
          final conversationId = _readInt(
            thread['conversation_id'],
          );
          if (conversationId == null) continue;
          final messages = _parseMessages(
            thread['messages'],
          );
          _applyThreadMessages(
            conversationId,
            messages,
            replaceServerMessages: true,
            completeInitial: true,
            setHasMoreOlder: thread['has_more_older'],
            touchPreview: true,
          );
        }
      }
    }

    final directMessages = data['messages'];
    if (directMessages is List && _looksLikeMessagesList(directMessages)) {
      _groupAndApplyMessages(
        _parseMessages(directMessages),
        replaceServerMessages: true,
        completeInitial: true,
        touchPreview: true,
      );
    }

    if (_loadingConversations) {
      _conversationsLoaded = true;
      _loadingConversations = false;
      _conversationsError = null;
      _completeCompleter(_conversationsCompleter);
    }

    _publishResumeState();
    notifyListeners();
  }

  void _handleDelta(Map<String, dynamic> event, Map<String, dynamic> data) {
    _updateServerCursor(event, data);

    final conversationsUpsert = _parseConversations(data['conversations']);
    for (final conversation in conversationsUpsert) {
      _upsertConversation(conversation);
    }

    final conversationDeletes = _parseIntList(data['conversations_deleted']);
    if (conversationDeletes.isNotEmpty) {
      _conversations.removeWhere((conversation) => conversationDeletes.contains(conversation.id));
      _pendingOutgoing.removeWhere((_, message) => conversationDeletes.contains(message.conversationId));
      for (final id in conversationDeletes) {
        _threads.remove(id);
        _activeThreads.remove(id);
      }
    }

    final threadBlocks = data['threads'];
    if (threadBlocks is List) {
      if (_looksLikeMessagesList(threadBlocks)) {
        _groupAndApplyMessages(
          _parseMessages(threadBlocks),
          replaceServerMessages: false,
          touchPreview: true,
        );
      } else {
        for (final rawThread in threadBlocks.whereType<Map>()) {
          final thread = Map<String, dynamic>.from(rawThread);
          final conversationId = _readInt(thread['conversation_id']);
          if (conversationId == null) continue;
          final messages = _parseMessages(thread['messages']);
          _applyThreadMessages(
            conversationId,
            messages,
            replaceServerMessages: false,
            touchPreview: true,
          );
        }
      }
    }

    final directMessages = data['messages'];
    if (directMessages is List && _looksLikeMessagesList(directMessages)) {
      for (final message in _parseMessages(directMessages)) {
        _handleServerMessage(message, touchPreview: true);
      }
    }

    _applyReadUpdates(data['reads']);

    _sortConversations();
    if (_loadingConversations) {
      _conversationsLoaded = true;
      _loadingConversations = false;
      _conversationsError = null;
      _completeCompleter(_conversationsCompleter);
    }

    _publishResumeState();
    notifyListeners();
  }

  void _handleThreadPayload(
    Map<String, dynamic> event,
    Map<String, dynamic> data, {
    required bool replaceServerMessages,
  }) {
    _updateServerCursor(event, data);

    final conversationId = _readInt(
      data['conversation_id']
    );
    if (conversationId == null) return;

    final messages = _parseMessages(data['messages']);

    _applyThreadMessages(
      conversationId,
      messages,
      replaceServerMessages: replaceServerMessages,
      completeInitial: replaceServerMessages,
      completeOlder: !replaceServerMessages &&
          (_threads[conversationId]?.loadingOlder ?? false),
      setHasMoreOlder: data['has_more_older'],
      touchPreview: !(_threads[conversationId]?.loadingOlder ?? false),
    );

    _publishResumeState();
    notifyListeners();
  }

  void _handleMessageAck(Map<String, dynamic> event, Map<String, dynamic> data) {
    _updateServerCursor(event, data);

    final ackMessage = _parseSingleMessage(data['message']);
    final clientMessageId =
        (data['client_message_id'] ?? ackMessage?.clientKey)
            ?.toString();
    if (ackMessage == null) return;

    final cache = _threads.putIfAbsent(ackMessage.conversationId, () => _ThreadCache());

    if (clientMessageId != null && _pendingOutgoing.containsKey(clientMessageId)) {
      _pendingOutgoing.remove(clientMessageId);
    }

    final changed = _upsertServerMessage(cache, ackMessage);
    if (changed) {
      cache.errorMessage = null;
      _sortAndReindex(cache);
      _touchConversationPreview(
        ackMessage.conversationId,
        ackMessage.text,
        ackMessage.createdAt,
      );
      notifyListeners();
    }
  }

  void _handleReadUpdate(Map<String, dynamic> event, Map<String, dynamic> data) {
    _updateServerCursor(event, data);

    final conversationId = _readInt(data['conversation_id']);
    final userId = _readInt(data['user_id']);
    final lastReadId = _readInt(data['last_message_read_id']);

    if (conversationId == null || userId == null || lastReadId == null) return;
    _applyReadUpdate(conversationId, userId, lastReadId);
    _publishResumeState();
    notifyListeners();
  }

  void _handleLegacyConversations(List<ConversationInfo> conversations) {
    _conversations
      ..clear()
      ..addAll(conversations);
    _sortConversations();

    _conversationsLoaded = true;
    _loadingConversations = false;
    _conversationsError = null;

    _completeCompleter(_conversationsCompleter);
    _publishResumeState();
    notifyListeners();
  }

  void _handleLegacyLoadedMessages(List<Message> messages) {
    final conversationId = _resolveConversationId(messages);
    if (conversationId == null) return;

    final cache = _threads.putIfAbsent(conversationId, () => _ThreadCache());
    final wasInitialLoad = cache.loadingInitial;
    final wasOlderLoad = cache.loadingOlder;
    final rawCount = messages.length;

    for (final message in messages) {
      _upsertServerMessage(cache, message);
    }

    cache.initialLoaded = true;
    cache.loadingInitial = false;
    cache.loadingOlder = false;
    cache.errorMessage = null;

    if (rawCount < _pageSize) {
      cache.hasMoreOlder = false;
    }

    _sortAndReindex(cache);

    if (wasInitialLoad) {
      _completeCompleter(cache.initialCompleter);
    } else if (wasOlderLoad) {
      _completeCompleter(cache.olderCompleter);
    }

    if (wasInitialLoad || !wasOlderLoad) {
      _touchConversationPreviewFromList(conversationId, messages);
    }
    _publishResumeState();
    notifyListeners();
  }

  void _handleLegacyIncomingMessage(Message message) {
    _updateServerCursorFromMessage(message);
    _handleServerMessage(message, touchPreview: true);
    _publishResumeState();
    notifyListeners();
  }

  void _handleMessageRead(int conversationId, int userId, int lastReadId) {
    _applyReadUpdate(conversationId, userId, lastReadId);
    _publishResumeState();
    notifyListeners();
  }

  void _handleConnectionChanged(bool connected) {
    _isConnected = connected;
    if (connected) {
      _publishResumeState();
      _dispatchPendingOutgoing();
      unawaited(_refreshAfterReconnect());
    }
    notifyListeners();
  }

  Future<void> _refreshAfterReconnect() async {
    if (_transport == null) return;

    if (_conversationsLoaded || _loadingConversations || _conversationsError != null) {
      unawaited(loadConversations(force: true));
    }

    for (final conversationId in _activeThreads.toList()) {
      final cache = _threads[conversationId];
      if (cache == null) continue;
      if (!cache.initialLoaded) {
        unawaited(ensureThreadLoaded(conversationId, force: true));
      }
    }

    _dispatchPendingOutgoing();
  }

  void _handleTransportError(dynamic error) {
    final message = error.toString();

    if (_loadingConversations) {
      _loadingConversations = false;
      _conversationsError = message;
      _completeCompleterWithError(_conversationsCompleter, error);
    }

    for (final cache in _threads.values) {
      if (cache.loadingInitial) {
        cache.loadingInitial = false;
        cache.errorMessage = message;
        _completeCompleterWithError(cache.initialCompleter, error);
      }
      if (cache.loadingOlder) {
        cache.loadingOlder = false;
        cache.errorMessage = message;
        _completeCompleterWithError(cache.olderCompleter, error);
      }
    }

    notifyListeners();
  }

  bool _looksLikeMessagesList(List list) {
    if (list.isEmpty) return true;
    final first = list.first;
    if (first is! Map) return false;
    final map = Map<String, dynamic>.from(first);
    return map.containsKey('text') || map.containsKey('sender_id') || map.containsKey('senderId');
  }

  void _groupAndApplyMessages(
    List<Message> messages, {
    required bool replaceServerMessages,
    bool completeInitial = false,
    bool completeOlder = false,
    bool touchPreview = false,
  }) {
    final grouped = <int, List<Message>>{};
    for (final message in messages) {
      grouped.putIfAbsent(message.conversationId, () => <Message>[]).add(message);
    }

    for (final entry in grouped.entries) {
      _applyThreadMessages(
        entry.key,
        entry.value,
        replaceServerMessages: replaceServerMessages,
        completeInitial: completeInitial,
        completeOlder: completeOlder,
        touchPreview: touchPreview,
      );
    }
  }

  void _handleServerMessage(
    Message message, {
    required bool touchPreview,
  }) {
    final cache = _threads.putIfAbsent(message.conversationId, () => _ThreadCache());
    final changed = _upsertServerMessage(cache, message);
    if (!changed) return;

    if (message.clientKey != null) {
      _pendingOutgoing.remove(message.clientKey);
    }

    cache.errorMessage = null;
    _sortAndReindex(cache);
    if (touchPreview) {
      _touchConversationPreview(message.conversationId, message.text, message.createdAt);
    }
  }

  void _applyThreadMessages(
    int conversationId,
    List<Message> messages, {
    required bool replaceServerMessages,
    bool completeInitial = false,
    bool completeOlder = false,
    dynamic setHasMoreOlder,
    bool touchPreview = false,
  }) {
    final cache = _threads.putIfAbsent(conversationId, () => _ThreadCache());
    final wasInitialLoad = cache.loadingInitial;
    final wasOlderLoad = cache.loadingOlder;

    if (replaceServerMessages) {
      cache.messages.removeWhere((message) => message.id != null);
    }

    for (final message in messages) {
      _upsertServerMessage(cache, message);
      if (message.clientKey != null) {
        _pendingOutgoing.remove(message.clientKey);
      }
    }

    cache.initialLoaded = cache.initialLoaded || completeInitial || wasInitialLoad || replaceServerMessages;
    cache.loadingInitial = false;
    cache.loadingOlder = false;
    cache.errorMessage = null;

    if (completeInitial) {
      _completeCompleter(cache.initialCompleter);
    } else if (wasInitialLoad) {
      _completeCompleter(cache.initialCompleter);
    }

    if (completeOlder || wasOlderLoad) {
      _completeCompleter(cache.olderCompleter);
    }

    if (setHasMoreOlder != null) {
      cache.hasMoreOlder = _readBool(setHasMoreOlder) ??
          (messages.length >= _pageSize && cache.hasMoreOlder);
    } else if (messages.length < _pageSize) {
      cache.hasMoreOlder = false;
    }

    _sortAndReindex(cache);

    if (touchPreview && messages.isNotEmpty) {
      _touchConversationPreviewFromList(conversationId, messages);
    }
  }

  void _applyReadUpdates(dynamic raw) {
    if (raw == null) return;

    if (raw is List) {
      for (final item in raw.whereType<Map>()) {
        final data = Map<String, dynamic>.from(item);
        final conversationId = _readInt(data['conversation_id']);
        final userId = _readInt(data['user_id']);
        final lastReadId = _readInt(data['last_message_read_id']);
        if (conversationId != null && userId != null && lastReadId != null) {
          _applyReadUpdate(conversationId, userId, lastReadId);
        }
      }
      return;
    }

    if (raw is Map) {
      final data = Map<String, dynamic>.from(raw);
      final conversationId = _readInt(data['conversation_id']);
      final userId = _readInt(data['user_id']);
      final lastReadId = _readInt(data['last_message_read_id']);
      if (conversationId != null && userId != null && lastReadId != null) {
        _applyReadUpdate(conversationId, userId, lastReadId);
      }
    }
  }

  void _applyReadUpdate(int conversationId, int userId, int lastReadId) {
    final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIndex == -1) return;

    final conv = _conversations[convIndex];
    final user = conv.userInfoById(userId);
    if (user == null) return;

    if (user.lastMessageReadId < lastReadId) {
      user.lastMessageReadId = lastReadId;
    }
  }

  void _upsertConversation(ConversationInfo conversation) {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index == -1) {
      _conversations.add(conversation);
    } else {
      _conversations[index] = conversation;
    }
    _sortConversations();
    _conversationsLoaded = true;
    _conversationsError = null;
    _loadingConversations = false;
    _completeCompleter(_conversationsCompleter);
  }

  void _sortConversations() {
    _conversations.sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
  }

  void _updateServerCursor(Map<String, dynamic> event, Map<String, dynamic> data) {
    final cursor = _readInt(event['server_cursor']);
    if (cursor != null) {
      _serverCursor = cursor;
    }
  }

  void _updateServerCursorFromMessage(Message message) {
    // No-op placeholder for compatibility with legacy payloads.
  }

  void _publishResumeState() {
    _transport?.updateResumeState(
      SyncResumeState(serverCursor: _serverCursor),
    );
  }

  void _touchConversationPreview(
    int conversationId,
    String lastMessage,
    DateTime lastUpdate,
  ) {
    for (var i = 0; i < _conversations.length; i++) {
      if (_conversations[i].id != conversationId) continue;

      final conv = _conversations[i];
      conv.lastMessage = lastMessage;
      conv.lastUpdate = lastUpdate.toUtc();
      _sortConversations();
      break;
    }
  }

  void _touchConversationPreviewFromList(
    int conversationId,
    List<Message> messages,
  ) {
    if (messages.isEmpty) return;
    final lastMessage = messages.last;
    _touchConversationPreview(
      conversationId,
      lastMessage.text,
      lastMessage.createdAt,
    );
  }

  int? _resolveConversationId(List<Message> messages) {
    if (messages.isNotEmpty) {
      return messages.first.conversationId;
    }

    final pending = _threads.entries
        .where((entry) => entry.value.loadingInitial || entry.value.loadingOlder)
        .map((entry) => entry.key)
        .toList();

    if (pending.length == 1) {
      return pending.first;
    }

    if (_threads.isNotEmpty) {
      return _threads.keys.first;
    }

    return null;
  }

  bool _upsertServerMessage(_ThreadCache cache, Message incoming) {
    if (incoming.id != null) {
      final pending = _matchPendingMessage(cache, incoming);
      if (pending != null) {
        final index = cache.messages.indexWhere((m) => m.clientKey == pending.clientKey);
        if (index != -1) {
          cache.messages[index] = incoming.copyWith(clientKey: pending.clientKey);
        } else {
          cache.messages.add(incoming.copyWith(clientKey: pending.clientKey));
        }
        return true;
      }

      if (cache.messagesById.containsKey(incoming.id!)) {
        return false;
      }
    }

    if (incoming.clientKey != null && cache.pendingMessages.containsKey(incoming.clientKey)) {
      return false;
    }

    cache.messages.add(incoming);
    return true;
  }

  Message? _matchPendingMessage(_ThreadCache cache, Message incoming) {
    final candidates = cache.pendingMessages.values.where((pending) {
      if (pending.conversationId != incoming.conversationId) return false;
      if (pending.senderId != incoming.senderId) return false;
      if (pending.text != incoming.text) return false;

      final delta = pending.createdAt.toUtc().difference(incoming.createdAt.toUtc()).abs();
      return delta <= _pendingAckWindow;
    }).toList();

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final da = a.createdAt.toUtc().difference(incoming.createdAt.toUtc()).abs();
      final db = b.createdAt.toUtc().difference(incoming.createdAt.toUtc()).abs();
      return da.compareTo(db);
    });

    final match = candidates.first;
    if (match.clientKey != null) {
      cache.pendingMessages.remove(match.clientKey);
    }
    return match;
  }

  void _sortAndReindex(_ThreadCache cache) {
    cache.messages.sort(_compareMessages);

    cache.messagesById.clear();
    cache.pendingMessages.clear();

    for (final message in cache.messages) {
      if (message.id != null) {
        cache.messagesById[message.id!] = message;
      }
      if (message.id == null && message.clientKey != null) {
        cache.pendingMessages[message.clientKey!] = message;
      }
    }
  }

  int _compareMessages(Message a, Message b) {
    final timeCompare = a.createdAt.toUtc().compareTo(b.createdAt.toUtc());
    if (timeCompare != 0) return timeCompare;

    final aKey = a.id?.toString() ?? a.clientKey ?? '';
    final bKey = b.id?.toString() ?? b.clientKey ?? '';
    return aKey.compareTo(bKey);
  }

  List<ConversationInfo> _parseConversations(dynamic raw) {
    if (raw is! List) return <ConversationInfo>[];
    return raw
        .whereType<Map>()
        .map((o) => ConversationInfo.fromJson(Map<String, dynamic>.from(o)))
        .toList();
  }

  List<Message> _parseMessages(dynamic raw) {
    if (raw is! List) return <Message>[];
    return raw
        .whereType<Map>()
        .map((o) => Message.fromJson(Map<String, dynamic>.from(o)))
        .toList();
  }

  Message? _parseSingleMessage(dynamic raw) {
    if (raw is! Map) return null;
    return Message.fromJson(Map<String, dynamic>.from(raw));
  }

  List<int> _parseIntList(dynamic raw) {
    if (raw is! List) return <int>[];
    return raw
        .map((value) => _readInt(value))
        .whereType<int>()
        .toList();
  }

  Map<String, dynamic> _eventData(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  bool? _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    if (value is num) return value != 0;
    return null;
  }

  int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String _nextClientKey() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = _localMessageCounter++ + _random.nextInt(1000);
    return '$timestamp-$suffix';
  }

  void _completeCompleter(Completer<void>? completer) {
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _completeCompleterWithError(Completer<void>? completer, dynamic error) {
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
    }
  }

  void _dispatchPendingOutgoing() {
    if (_transport == null || !_isConnected) return;

    for (final message in _pendingOutgoing.values.toList()) {
      final sent = _transport!.sendMessage(
        message.conversationId,
        message.text,
        clientMessageId: message.clientKey!,
      );
      if (!sent) break;
    }
  }

  @override
  void dispose() {
    if (_transport != null && _listener != null) {
      _transport!.removeListener(_listener!);
    }
    super.dispose();
  }
}

class _ThreadCache {
  final List<Message> messages = [];
  final Map<int, Message> messagesById = {};
  final Map<String, Message> pendingMessages = {};

  bool initialLoaded = false;
  bool loadingInitial = false;
  bool loadingOlder = false;
  bool hasMoreOlder = true;
  String? errorMessage;

  Completer<void>? initialCompleter;
  Completer<void>? olderCompleter;
}
