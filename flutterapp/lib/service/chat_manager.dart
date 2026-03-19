import 'dart:async';
import 'dart:convert';
import 'package:flutterapp/model/conversation_info.dart';
import 'package:flutterapp/model/user_info.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/routes/all_routes.dart';

class ChatListener {
  final void Function(bool)? connection;
  final void Function(Message)? newMessage;
  final void Function(List<Message>)? loadMessages;
  final void Function(List<ConversationInfo>)? conversations;
  final void Function(String query, List<UserInfo> users)? onSearchResult;
  final void Function(dynamic)? error;

  ChatListener({this.connection, this.newMessage, this.loadMessages, this.conversations, this.onSearchResult, this.error});
}

class ChatManager {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  final List<ChatListener> _listeners = [];
  final List<({int conversationId, String text})> _messagesQueue = [];
  JWTToken? _token;

  Timer? _reconnectTimer;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  bool _isReconnecting = false;
  StreamSubscription? _channelSubscription;

  bool get isConnected => _isConnected;

  void setToken(JWTToken token) {
    if (_token == token && _isConnected) return;
    _token = token;
    _connect();
  }

  Future<void> _connect() async {
    if (_token == null || _channel != null) return;

    try {
      await _token!.updateToken();
      _cancelReconnectTimer();
      final uri = Uri.parse(webSocketUrl).replace(queryParameters: {"token": _token!.accessToken});

      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      
      _isConnected = true;
      _channelSubscription = _channel!.stream.listen(_onData, onError: _onError, onDone: _onDone, cancelOnError: true);
      _setConnection(true);
      _isReconnecting = false;
    } catch (e) {
      _onError(e);
    }
  }

  void _setConnection(bool value) {
    _isConnected = value;
    if (value) _flushMessageQueue();
    for (var listener in _listeners) {
      listener.connection?.call(value);
    }
  }

  void loadConversations() {
    _connect();
    _channel?.sink.add(jsonEncode({"type": "get_conversations"}));
  }

  void loadLast(int conversationId) {
    _connect();
    _channel?.sink.add(jsonEncode({
      "type": "get_messages",
      "data": {"conversation_id": conversationId, "last_message_date": DateTime.now().toUtc().toIso8601String()},
    }));
  }

  void loadBefore(Message message) {
    _connect();
    _channel?.sink.add(jsonEncode({
      "type": "get_messages",
      "data": {"conversation_id": message.conversationId, "last_message_date": message.createdAt.toIso8601String()},
    }));
  }

  void _onData(dynamic response) {
    if (response == null) return;
    try {
      final decoded = response is String ? jsonDecode(response) : Map<String, dynamic>.from(response);
      
      switch (decoded["type"]) {
        case "conversations":
          final convs = (decoded["data"] as List).map((o) => ConversationInfo.fromJson(o)).toList();
          for (var l in _listeners) {l.conversations?.call(convs);}
          break;
        case "new_message":
          final data = Map<String, dynamic>.from(decoded["data"]);
          final msgMap = Map<String, dynamic>.from(data["message"]);
          if (data["conversation"]?["id"] != null) msgMap["conversation_id"] = data["conversation"]["id"];
          final msg = Message.fromJson(msgMap);
          for (var l in _listeners) {l.newMessage?.call(msg);}
          break;
        case "messages":
          final messages = (decoded["data"] as List).map((m) => Message.fromJson(m)).toList();
          for (var l in _listeners) {l.loadMessages?.call(messages);}
          break;
        case "find_user_result":
          final users = (decoded["data"]["users"] as List).map((u) => UserInfo.fromJson(u)).toList();
          for (var l in _listeners) {l.onSearchResult?.call(decoded["data"]["search_string"], users);}
          break;
      }
    } catch (e) {
      _onError(e);
    }
  }

  void _onError(dynamic error) {
    _setConnection(false);
    for (var l in _listeners) {
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
      if (!_isConnected && _token != null) await _connect();
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isReconnecting = false;
  }

  void _flushMessageQueue() {
    while (_messagesQueue.isNotEmpty && _isConnected && _channel != null) {
      final msg = _messagesQueue.removeAt(0);
      _channel!.sink.add(jsonEncode({
        "type": "send_message",
        "data": {"conversation_id": msg.conversationId, "text": msg.text},
      }));
    }
  }

  void sendMessage(int conversationId, String text) {
    _messagesQueue.add((conversationId: conversationId, text: text));
    _flushMessageQueue();
  }

  void searchUsers(String query) {
    _connect();
    _channel?.sink.add(jsonEncode({"type": "search_user", "data": {"search_string": query}}));
  }

  void addListener(ChatListener listener) {
    _listeners.add(listener);
    listener.connection?.call(_isConnected);
  }

  void removeListener(ChatListener listener) => _listeners.remove(listener);

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
