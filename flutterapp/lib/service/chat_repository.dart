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

  bool _conversationsLoaded = false;
  bool _loadingConversations = false;
  String? _conversationsError;
  Completer<void>? _conversationsCompleter;

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
      newMessage: _handleIncomingMessage,
      loadMessages: _handleLoadedMessages,
      conversations: _handleConversations,
      onMessageRead: _handleMessageRead,
      error: _handleTransportError,
    );
    _transport!.addListener(_listener!);
    _isConnected = _transport!.isConnected;
  }

  void clear() {
    _threads.clear();
    _conversations.clear();
    _lastReadSentByConversation.clear();
    _conversationsLoaded = false;
    _loadingConversations = false;
    _conversationsError = null;
    _conversationsCompleter = null;
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

    await _transport!.loadConversations();
    return _conversationsCompleter!.future;
  }

  Future<void> ensureThreadLoaded(
    int conversationId, {
    bool force = false,
  }) async {
    if (_transport == null) return;

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
    _sortAndReindex(cache);
    _touchConversationPreview(conversationId, trimmed, optimistic.createdAt);

    notifyListeners();
    _transport?.sendMessage(conversationId, trimmed);
  }

  void markConversationAsRead(int conversationId, int lastMessageReadId) {
    if (lastMessageReadId <= 0) return;

    final prev = _lastReadSentByConversation[conversationId];
    if (prev != null && lastMessageReadId <= prev) return;

    _lastReadSentByConversation[conversationId] = lastMessageReadId;
    _transport?.markConversationAsRead(conversationId, lastMessageReadId);
  }

  void _handleMessageRead(int conversationId, int userId, int lastReadId) {
    final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIndex == -1) return;

    final conv = _conversations[convIndex];

    final user = conv.userInfoById(userId);
    if (user == null) return;

    if (user.lastMessageReadId < lastReadId) {
      user.lastMessageReadId = lastReadId;
      notifyListeners();
    }
  }

  void _handleConnectionChanged(bool connected) {
    _isConnected = connected;
    notifyListeners();
  }

  void _handleConversations(List<ConversationInfo> conversations) {
    _conversations
      ..clear()
      ..addAll(conversations);

    _conversationsLoaded = true;
    _loadingConversations = false;
    _conversationsError = null;

    _completeCompleter(_conversationsCompleter);
    notifyListeners();
  }

  void _handleLoadedMessages(List<Message> messages) {
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

    notifyListeners();
  }

  void _handleIncomingMessage(Message message) {
    final cache = _threads.putIfAbsent(message.conversationId, () => _ThreadCache());

    final changed = _upsertServerMessage(cache, message);
    if (!changed) return;

    cache.errorMessage = null;
    _sortAndReindex(cache);
    _touchConversationPreview(message.conversationId, message.text, message.createdAt);

    notifyListeners();
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

  void _touchConversationPreview(
    int conversationId,
    String lastMessage,
    DateTime lastUpdate,
  ) {
    for (var i = 0; i < _conversations.length; i++) {
      if (_conversations[i].id != conversationId) continue;

      final conv = _conversations.removeAt(i);
      conv.lastMessage = lastMessage;
      conv.lastUpdate = lastUpdate.toUtc();
      _conversations.insert(0, conv);
      break;
    }
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