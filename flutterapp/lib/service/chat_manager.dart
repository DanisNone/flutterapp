import 'dart:async';
import 'dart:convert';

import 'package:flutterapp/model/conversation_info.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/model/user_info.dart';
import 'package:flutterapp/routes/all_routes.dart';
import 'package:flutterapp/service/jwttoken_manager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SyncResumeState {
  final int? serverCursor;

  const SyncResumeState({this.serverCursor});

  Map<String, dynamic> toJson() => {
        if (serverCursor != null) 'server_cursor': serverCursor,
      };
}

class ChatListener {
  final void Function(bool)? connection;
  final void Function(Message)? newMessage;
  final void Function(List<Message>)? loadMessages;
  final void Function(List<ConversationInfo>)? conversations;
  final void Function(String query, List<UserInfo> users)? onSearchResult;
  final void Function(int conversationId, int userId, int lastReadId)? onMessageRead;
  final void Function(Map<String, dynamic> event)? onEvent;
  final void Function(dynamic)? error;

  ChatListener({
    this.connection,
    this.newMessage,
    this.loadMessages,
    this.conversations,
    this.onSearchResult,
    this.onMessageRead,
    this.onEvent,
    this.error,
  });
}

/// Transport-only WebSocket service.
/// Keeps connection, reconnect, request sending, and event decoding.
/// No chat history cache lives here.
class ChatManager {
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  bool _isConnected = false;
  bool _allowReconnect = true;

  final List<ChatListener> _listeners = [];

  Timer? _reconnectTimer;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  bool _isReconnecting = false;

  Future<void>? _connectingFuture;
  final List<Map<String, dynamic>> _outgoingQueue = [];
  SyncResumeState? _resumeState;

  bool get isConnected => _isConnected;

  void updateResumeState(SyncResumeState? state) {
    _resumeState = state;
  }

  void resetSession() {
    _allowReconnect = false;
    _cancelReconnectTimer();
    _isReconnecting = false;
    _connectingFuture = null;
    _resumeState = null;
    _outgoingQueue.clear();

    _setConnection(false);

    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  Future<void> _ensureConnected() async {
    if (_isConnected && _channel != null) return;

    if (_connectingFuture != null) {
      await _connectingFuture;
      return;
    }

    _connectingFuture = _connectInternal();
    try {
      await _connectingFuture;
    } finally {
      _connectingFuture = null;
    }
  }

  Future<void> _connectInternal() async {
    if (_channel != null) return;

    try {
      final token = await JWTTokenManager().getJWTToken(update: true);
      _cancelReconnectTimer();
      _allowReconnect = true;

      final uri = Uri.parse(webSocketUrl).replace(
        queryParameters: {'token': token.accessToken},
      );

      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _channelSubscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );

      _sendResumeFrame();
      _setConnection(true);
    } catch (e) {
      _onError(e);
    }
  }

  void _setConnection(bool value) {
    _isConnected = value;
    if (value) {
      _flushOutgoingQueue();
    }
    for (final listener in _listeners) {
      listener.connection?.call(value);
    }
  }

  void _sendResumeFrame() {
    if (_channel == null) return;

    final state = _resumeState;
    final payload = <String, dynamic>{
      'type': 'sync.resume',
      'data': state?.toJson() ?? <String, dynamic>{},
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  void _queueOrSend(Map<String, dynamic> payload) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(payload));
      return;
    }

    _outgoingQueue.add(payload);
    unawaited(_ensureConnected());
  }

  void _flushOutgoingQueue() {
    if (_channel == null || _outgoingQueue.isEmpty) return;

    while (_outgoingQueue.isNotEmpty) {
      final payload = _outgoingQueue.removeAt(0);
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  Future<void> loadConversations({
    int? cursor,
    bool forceFull = false,
  }) {
    _queueOrSend({
      'type': 'sync.request',
      'data': {
        'cursor': ?cursor,
        'scope': 'conversations',
        'force_full': forceFull,
      },
    });
    return Future<void>.value();
  }

  Future<void> loadLast(
    int conversationId, {
    int? afterMessageId,
  }) {
    _queueOrSend({
      'type': 'thread.request',
      'data': {
        'conversation_id': conversationId,
        'limit': 50,
        'after_message_id': ?afterMessageId,
        'mode': afterMessageId == null ? 'latest' : 'after',
      },
    });
    return Future<void>.value();
  }

  Future<void> loadBefore(Message message) {
    _queueOrSend({
      'type': 'thread.request',
      'data': {
        'conversation_id': message.conversationId,
        'before_message_id': message.id,
        'limit': 50,
        'mode': 'before',
      },
    });
    return Future<void>.value();
  }

  Future<void> searchUsers(String query) {
    _queueOrSend({
      'type': 'search.request',
      'data': {'query': query},
    });
    return Future<void>.value();
  }

  Future<void> markConversationAsRead(
    int conversationId,
    int lastMessageReadId,
  ) {
    _queueOrSend({
      'type': 'read.update',
      'data': {
        'conversation_id': conversationId,
        'last_message_read_id': lastMessageReadId,
      },
    });
    return Future<void>.value();
  }

  bool sendMessage(
    int conversationId,
    String text, {
    required String clientMessageId,
  }) {
    if (_channel == null || !_isConnected) {
      return false;
    }

    _channel!.sink.add(
      jsonEncode({
        'type': 'message.send',
        'data': {
          'conversation_id': conversationId,
          'text': text,
          'client_message_id': clientMessageId,
        },
      }),
    );
    return true;
  }

  void _onData(dynamic response) {
    if (response == null) return;

    try {
      final decoded = response is String
          ? jsonDecode(response)
          : Map<String, dynamic>.from(response as Map);

      final event = Map<String, dynamic>.from(decoded);
      for (final listener in _listeners) {
        listener.onEvent?.call(event);
      }

      final type = (decoded['type']?.toString() ?? '').toLowerCase();
      final data = _eventData(decoded['data']);

      switch (type) {
        case 'conversations':
        case 'sync.snapshot':
          final convs = _parseConversations(decoded['data']);
          for (final l in _listeners) {
            l.conversations?.call(convs);
          }
          break;

        case 'sync.delta':
        case 'delta':
          break;

        case 'new_message':
        case 'message.upsert':
          final message = _parseSingleMessage(decoded['data']);
          if (message != null) {
            for (final l in _listeners) {
              l.newMessage?.call(message);
            }
          }
          break;

        case 'thread.delta':
          break;

        case 'thread.snapshot':
          final messages = _parseMessages(decoded['data']);
          for (final l in _listeners) {
            l.loadMessages?.call(messages);
          }
          break;

        case 'message.ack':
          break;

        case 'search.result':
          final rawData = decoded['data'];
          final rawMap = rawData is Map ? Map<String, dynamic>.from(rawData) : <String, dynamic>{};
          final users = _parseUsers(data['users'] ?? rawMap['users']);
          final query = (data['query'] ?? '').toString();
          for (final l in _listeners) {
            l.onSearchResult?.call(query, users);
          }
          break;

        case 'read.update':
          final conversationId = _readInt(data['conversation_id']);
          final userId = _readInt(data['user_id']);
          final lastReadId = _readInt(
            data['last_message_read_id'],
          );
          if (conversationId != null && userId != null && lastReadId != null) {
            for (final l in _listeners) {
              l.onMessageRead?.call(conversationId, userId, lastReadId);
            }
          }
          break;
      }
    } catch (e) {
      _onError(e);
    }
  }

  Map<String, dynamic> _eventData(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  List<ConversationInfo> _parseConversations(dynamic raw) {
    final list = raw is Map ? raw['conversations'] : raw;
    if (list is! List) return <ConversationInfo>[];
    return list
        .whereType<Map>()
        .map((o) => ConversationInfo.fromJson(Map<String, dynamic>.from(o)))
        .toList();
  }

  List<Message> _parseMessages(dynamic raw) {
    final list = raw is Map ? raw['messages'] : raw;
    if (list is! List) return <Message>[];
    return list
        .whereType<Map>()
        .map((o) => Message.fromJson(Map<String, dynamic>.from(o)))
        .toList();
  }

  Message? _parseSingleMessage(dynamic raw) {
    if (raw is Map) {
      final data = Map<String, dynamic>.from(raw);
      if (data['message'] is Map) {
        final msg = Map<String, dynamic>.from(data['message'] as Map);
        final convId = _readInt(data['conversation_id']);
        if (convId != null) {
          msg['conversation_id'] = convId;
        }
        return Message.fromJson(msg);
      }
      return Message.fromJson(data);
    }
    return null;
  }

  List<UserInfo> _parseUsers(dynamic raw) {
    if (raw is! List) return <UserInfo>[];
    return raw
        .whereType<Map>()
        .map((o) => UserInfo.fromJson(Map<String, dynamic>.from(o)))
        .toList();
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

  void _onError(dynamic error) {
    _setConnection(false);
    for (final l in _listeners) {
      l.error?.call(error);
    }
    _closeChannel();
    _scheduleReconnect();
  }

  void _onDone() {
    _setConnection(false);
    _closeChannel();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_allowReconnect) return;
    if (_isReconnecting) return;
    _isReconnecting = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () async {
      _isReconnecting = false;
      await _ensureConnected();
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isReconnecting = false;
  }

  void addListener(ChatListener listener) {
    _listeners.add(listener);
  }

  void removeListener(ChatListener listener) {
    _listeners.remove(listener);
  }

  void _closeChannel() {
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel?.sink.close();
    _channel = null;
  }
}
