import 'dart:async';
import 'dart:convert';

import 'package:flutterapp/model/conversation_info.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/model/user_info.dart';
import 'package:flutterapp/routes/all_routes.dart';
import 'package:flutterapp/service/jwttoken_manager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatListener {
  final void Function(bool)? connection;
  final void Function(Message)? newMessage;
  final void Function(List<Message>)? loadMessages;
  final void Function(List<ConversationInfo>)? conversations;
  final void Function(String query, List<UserInfo> users)? onSearchResult;
  final void Function(int conversationId, int userId, int lastReadId)? onMessageRead;
  final void Function(dynamic)? error;

  ChatListener({
    this.connection,
    this.newMessage,
    this.loadMessages,
    this.conversations,
    this.onSearchResult,
    this.error,
    this.onMessageRead
  });
}

/// Transport-only WebSocket service.
/// Keeps connection, reconnect, request sending, and event decoding.
/// No chat history cache lives here.
class ChatManager {
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  bool _isConnected = false;

  final List<ChatListener> _listeners = [];

  Timer? _reconnectTimer;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  bool _isReconnecting = false;

  Future<void>? _connectingFuture;
  final List<({int conversationId, String text})> _messagesQueue = [];

  bool get isConnected => _isConnected;

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

      final uri = Uri.parse(webSocketUrl).replace(
        queryParameters: {"token": token.accessToken},
      );

      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _channelSubscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );

      _setConnection(true);
      _isReconnecting = false;
    } catch (e) {
      _onError(e);
    }
  }

  void _setConnection(bool value) {
    _isConnected = value;
    if (value) {
      _flushMessageQueue();
    }
    for (final listener in _listeners) {
      listener.connection?.call(value);
    }
  }

  Future<void> _sendRequest(Map<String, dynamic> payload) async {
    await _ensureConnected();
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(payload));
  }

  Future<void> loadConversations() {
    return _sendRequest({"type": "get_conversations"});
  }

  Future<void> loadLast(int conversationId) {
    return _sendRequest({
      "type": "get_messages",
      "data": {
        "conversation_id": conversationId,
        "last_message_date": DateTime.now().toUtc().toIso8601String(),
      },
    });
  }

  Future<void> loadBefore(Message message) {
    return _sendRequest({
      "type": "get_messages",
      "data": {
        "conversation_id": message.conversationId,
        "last_message_date": message.createdAt.toUtc().toIso8601String(),
      },
    });
  }

  Future<void> searchUsers(String query) {
    return _sendRequest({
      "type": "search_user",
      "data": {"search_string": query},
    });
  }

  Future<void> markConversationAsRead(
    int conversationId,
    int lastMessageReadId,
  ) {
    return _sendRequest({
      "type": "mark_message_as_read",
      "data": {
        "conversation_id": conversationId,
        "last_message_read_id": lastMessageReadId,
      },
    });
  }

  void sendMessage(int conversationId, String text) {
    _messagesQueue.add((conversationId: conversationId, text: text));
    unawaited(_ensureConnected());
    _flushMessageQueue();
  }

  void _flushMessageQueue() {
    while (_messagesQueue.isNotEmpty && _isConnected && _channel != null) {
      final msg = _messagesQueue.removeAt(0);
      _channel!.sink.add(
        jsonEncode({
          "type": "send_message",
          "data": {
            "conversation_id": msg.conversationId,
            "text": msg.text,
          },
        }),
      );
    }
  }

  void _onData(dynamic response) {
    if (response == null) return;

    try {
      final decoded = response is String
          ? jsonDecode(response)
          : Map<String, dynamic>.from(response);

      switch (decoded["type"]) {
        case "conversations":
          final convs = (decoded["data"] as List)
              .map((o) => ConversationInfo.fromJson(o))
              .toList();
          for (final l in _listeners) {
            l.conversations?.call(convs);
          }
          break;

        case "new_message":
          final data = Map<String, dynamic>.from(decoded["data"]);
          final msgMap = Map<String, dynamic>.from(data["message"]);
          if (data["conversation"]?["id"] != null) {
            msgMap["conversation_id"] = data["conversation"]["id"];
          }
          final msg = Message.fromJson(msgMap);
          for (final l in _listeners) {
            l.newMessage?.call(msg);
          }
          break;

        case "messages":
          final messages = (decoded["data"] as List)
              .map((m) => Message.fromJson(m))
              .toList();
          for (final l in _listeners) {
            l.loadMessages?.call(messages);
          }
          break;

        case "find_user_result":
          final users = (decoded["data"]["users"] as List)
              .map((u) => UserInfo.fromJson(u))
              .toList();
          for (final l in _listeners) {
            l.onSearchResult?.call(
              decoded["data"]["search_string"],
              users,
            );
          }
          break;
    case "messages_read":
        final data = Map<String, dynamic>.from(decoded["data"]);
        final conversationId = data["conversation_id"] as int;
        final userId = data["user_id"] as int;
        final lastReadId = data["last_message_read_id"] as int;

        for (final l in _listeners) {
          l.onMessageRead?.call(conversationId, userId, lastReadId);
        }
        break;
      }
    } catch (e) {
      _onError(e);
    }
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
    if (_isReconnecting) return;
    _isReconnecting = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () async {
      _isReconnecting = false;
      if (!_isConnected) {
        await _ensureConnected();
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isReconnecting = false;
  }

  void addListener(ChatListener listener) {
    _listeners.add(listener);
    listener.connection?.call(_isConnected);
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

  void dispose() {
    _cancelReconnectTimer();
    _closeChannel();
    _listeners.clear();
  }
}