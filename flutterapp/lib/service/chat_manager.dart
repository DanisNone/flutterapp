import 'dart:async';
import 'dart:convert';

import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/routes/all_routes.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatListener {
  Function(bool)? _connection;
  Function(Message)? _newMessage;
  Function(dynamic)? _error;

  Function(bool)? get connection => _connection;
  Function(Message)? get newMessage => _newMessage;
  Function(dynamic)? get error => _error;

  ChatListener({
    Function(bool)? connection,
    Function(Message)? newMessage,
    Function(dynamic)? error,
  }) {
    _connection = connection;
    _newMessage = newMessage;
    _error = error;
  }
}

class ChatManager {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  final List<ChatListener> _listeners = [];
  JWTToken? _token;
  
  // Для автоматического reconnect
  Timer? _reconnectTimer;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  int _reconnectAttempts = 0;
  bool _isReconnecting = false;
  StreamSubscription? _channelSubscription;

  bool get isConnected => _isConnected;

  void setToken(JWTToken token) {
    _token = token;
    _connect();
  }

  void _connect() {
    if (_token == null) return;
    
    try {
      _closeConnection();
      
      final uri = Uri.parse(webSocketUrl).replace(
        queryParameters: {"token": _token!.accessToken},
      );
      
      _channel = WebSocketChannel.connect(uri);
      _channelSubscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );
      
      _setConnection(true);
    } catch (e) {
      _setConnection(false);
      _scheduleReconnect();
    }
  }

  void _setConnection(bool value) {
    if (_isConnected == value) return;
    
    _isConnected = value;
    for (var listener in _listeners) {
      listener.connection?.call(value);
    }
  }

  void _onData(dynamic response) {
    try {
      Map<String, dynamic> decoded = jsonDecode(response);
      if (decoded["type"] != "new_message") {
        return; // TODO add logic
      }
      
      Map<String, dynamic> data = decoded["data"];
      data["message"]["conversation_id"] = data["conversation"]["id"] as int;
      final message = Message.fromJson(data["message"]);
      
      for (var listener in _listeners) {
        listener.newMessage?.call(message);
      }
    } catch (e) {
      _onError(e);
    }
  }

  void _onError(dynamic error) {
    _setConnection(false);
    
    for (var listener in _listeners) {
      listener.error?.call(error);
    }
    
    _scheduleReconnect();
  }

  void _onDone() {
    _setConnection(false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isReconnecting) return;
    
    _reconnectTimer?.cancel();    
    _isReconnecting = true;
    _reconnectAttempts++;
    
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isConnected && _token != null) {
        _connect();
      }
      _isReconnecting = false;
    });
  }

  void reconnect(Function(bool) callback) {
    // Отменяем текущий таймер и сбрасываем счетчик для ручного reconnect
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _isReconnecting = false;
    
    if (_token != null) {
      _connect();
    }
    callback(_isConnected);
  }

  void sendMessage(int conversationId, String text) {
    if (!_isConnected || _channel == null) {
      return;
    }
    
    try {
      _channel!.sink.add(jsonEncode({
        "conversation_id": conversationId,
        "text": text
      }));
    } catch (e) {
      _onError(e);
    }
  }

  void _closeConnection() {
    _reconnectTimer?.cancel();
    _channelSubscription?.cancel();
    
    if (_channel != null) {
      try {
        _channel!.sink.close();
      } catch (e) {
        _onError(e);
      }
      _channel = null;
    }
  }

  void addListener(ChatListener callback) {
    _listeners.add(callback);
  }

  void removeListener(ChatListener callback) {
    _listeners.remove(callback);
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _closeConnection();
    _listeners.clear();
    _isReconnecting = false;
  }
}