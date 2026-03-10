import 'dart:convert';

import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/routes/all_routes.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatListener {
  Function(bool)? _connection;
  Function(Message)? _newMessage;
  Function? _error;

  Function(bool)? get connection => _connection;
  Function(Message)? get newMessage => _newMessage;
  Function? get error => _error;

  ChatListener({
    Function(bool)? connection,
    Function(Message)? newMessage,
    Function? error,
  }) {
    _connection = connection;
    _newMessage = newMessage;
    _error = error;
  }
}

class ChatManager {
  late WebSocketChannel _channel;
  bool _isConnected = false;
  final List<ChatListener> _listeners = [];
  JWTToken? token;

  void setToken(JWTToken token) {
    this.token = token;
    final uri = Uri.parse(webSocketUrl).replace(
      queryParameters: {"token": token.accessToken},
    );
    try {
      _channel = WebSocketChannel.connect(uri);
      _channel.stream.listen(
        _onData,
        onError: _onError
      );
      _setConnection(true);
      print("connection good");
    } catch (e) {
      _setConnection(false);
      print("connection bad");
    }
  }

  void _setConnection(bool value) {
    _isConnected = value;
    for (var listener in _listeners) {
      listener.connection?.call(value);
    }
  }

  void addListener(ChatListener callback) {
    _listeners.add(callback);
  }

  void popListener() {
    _listeners.removeLast();
  }

  void _onData(dynamic response) 
  {
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
  }
  void _onError(error) {
    for (var listener in _listeners) {
      listener.error?.call(error);
    }
  }
  void sendMessage(int conversationId, String text) {
    _channel.sink.add(jsonEncode({
      "conversation_id": conversationId,
      "text": text
    }));
  }

  void reconnect(Function(bool) callback) {
    setToken(token!);
    callback(_isConnected);
  }

  void dispose() {
    print("chatmanager dispose");
    if (_isConnected) {
      _channel.sink.close();
    }
  }
}