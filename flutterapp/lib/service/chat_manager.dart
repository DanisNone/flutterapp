import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutterapp/model/conversation_info.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/routes/all_routes.dart';

class ChatListener {
  final void Function(bool)? connection;
  final void Function(Message)? newMessage;
  final void Function(List<Message>)? loadMessages;
  final void Function(List<ConversationInfo>)? conversations;
  final void Function(dynamic)? error;

  ChatListener({
    this.connection,
    this.newMessage,
    this.loadMessages,
    this.error,
    this.conversations,
  });
}

class ChatManager {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  final List<ChatListener> _listeners = [];
  final List<(int, String)> _messagesQueue = [];
  JWTToken? _token;

  Timer? _reconnectTimer;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  bool _isReconnecting = false;
  StreamSubscription? _channelSubscription;

  bool get isConnected => _isConnected;

  /// Устанавливает токен и пытается подключиться
  void setToken(JWTToken token) {
    if (_token == token && _isConnected) return;
    _token = token;
    _connect();
  }

  Future<void> _connect() async {
    if (_token == null) return;
    if (_channel != null) return;

    try {
      await _token!.updateToken();
      _cancelReconnectTimer();
      final uri = Uri.parse(
        webSocketUrl,
      ).replace(queryParameters: {"token": _token!.accessToken});

      _isConnected = true;
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _channelSubscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );

      _setConnection(_isConnected);
      _isReconnecting = false;
    } catch (e) {
      _setConnection(false);
      _onError(e);
    }
  }

  void _setConnection(bool value) {
    if (value) _sendMessage();
    _isConnected = value;
    for (var listener in _listeners) {
      try {
        listener.connection?.call(value);
      } catch (_) {
        // Игнорируем исключения слушателей
      }
    }
  }

  void loadConversations() {
    _connect();
    _channel!.sink.add(jsonEncode({"type": "get_conversations"}));
  }

  void loadLast(int conversationId) async {
    _connect();

    final payload = {
      "type": "get_messages",
      "data": {
        "conversation_id": conversationId,
        "last_message_date": DateTime.now().toUtc().toString(),
      },
    };
    _channel!.sink.add(jsonEncode(payload));
  }

  void loadBefore(Message message) async {
    _connect();

    final payload = {
      "type": "get_messages",
      "data": {
        "conversation_id": message.conversationId,
        "last_message_date": message.createdAt.toString(),
      },
    };
    _channel!.sink.add(jsonEncode(payload));
  }

  void _addMessage(Map<String, dynamic> data) {
    final conversation = data["conversation"] as Map<String, dynamic>?;
    final messageMap = Map<String, dynamic>.from(data["message"] as Map);

    if (conversation != null && conversation.containsKey("id")) {
      messageMap["conversation_id"] = conversation["id"];
    }

    final message = Message.fromJson(messageMap);

    for (var listener in _listeners) {
      try {
        listener.newMessage?.call(message);
      } catch (_) {}
    }
  }

  void _onData(dynamic response) {
    try {
      if (response == null) return;

      Map<String, dynamic> decoded;
      if (response is String) {
        decoded = jsonDecode(response);
      } else if (response is Map) {
        decoded = Map<String, dynamic>.from(response);
      } else {
        return;
      }
      if (decoded["type"] == "conversations") {
        List<ConversationInfo> convs = (decoded["data"] as List)
            .map((o) => ConversationInfo.fromJson(o as Map<String, dynamic>))
            .toList();
        for (var listener in _listeners) {
          try {
            listener.conversations?.call(convs);
          } catch (e) {
            // игнорим ошибки в callback
          }
        }
      } else if (decoded["type"] == "new_message") {
        final data = Map<String, dynamic>.from(decoded["data"] as Map);
        _addMessage(data);
      } else if (decoded["type"] == "messages") {
        final data = List<Map<String, dynamic>>.from(decoded["data"] as List);
        final messages = data.map(Message.fromJson).toList();
        for (var listener in _listeners) {
          try {
            listener.loadMessages?.call(messages);
          } catch (_) {}
        }
      } else {
        throw Exception("unknown websocket answer type: ${decoded["type"]}");
      }
    } catch (e) {
      _onError(e);
    }
  }

  void _onError(dynamic error) {
    _setConnection(false);

    for (var listener in _listeners) {
      try {
        listener.error?.call(error);
      } catch (_) {}
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
      if (!_isConnected && _token != null) {
        await _connect();
        if (!_isConnected) {
          _scheduleReconnect();
        }
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isReconnecting = false;
  }

  Future<bool> reconnect() async {
    _cancelReconnectTimer();
    _isReconnecting = false;

    // Закроем текущее, если есть
    _closeChannel();

    if (_token != null) {
      await _connect();
    }

    return _isConnected;
  }

  void _sendMessage() {
    while (_messagesQueue.isNotEmpty) {
      try {
        if (!_isConnected || _channel == null) {
          break;
        }
        final payload = {
          "type": "send_message",
          "data": {
            "conversation_id": _messagesQueue.first.$1,
            "text": _messagesQueue.first.$2,
          },
        };
        _channel!.sink.add(jsonEncode(payload));
        _messagesQueue.removeAt(0);
      } catch (e) {
        _onError(e);
        break;
      }
    }
  }

  void sendMessage(int conversationId, String text) {
    _messagesQueue.add((conversationId, text));
    _sendMessage();
  }

  Future<void> deleteMessage(int messageId) async {
    if (!_isConnected || _channel == null) {
      throw Exception('Нет соединения с сервером');
    }
    throw Exception("not implemented");
  }

  void _closeChannel() {
    try {
      _channelSubscription?.cancel();
    } catch (_) {}
    _channelSubscription = null;

    if (_channel != null) {
      try {
        _channel!.sink.close();
      } catch (_) {}
      _channel = null;
    }

    _setConnection(false);
  }

  void addListener(ChatListener listener) {
    _listeners.add(listener);
    try {
      listener.connection?.call(_isConnected);
    } catch (_) {}
  }

  void removeListener(ChatListener listener) {
    _listeners.remove(listener);
  }

  void dispose() {
    _cancelReconnectTimer();
    _closeChannel();
    _listeners.clear();
    _isReconnecting = false;
  }
}
