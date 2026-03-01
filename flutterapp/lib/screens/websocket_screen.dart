import "dart:convert";

import "package:flutter/material.dart";
import "package:web_socket_channel/web_socket_channel.dart";

class WebSocketScreen extends StatefulWidget {
  final String jwtToken; // Получаем токен извне
  
  const WebSocketScreen({super.key, required this.jwtToken});

  @override
  _WebSocketScreenState createState() => _WebSocketScreenState();
}

class _WebSocketScreenState extends State<WebSocketScreen> {
  final TextEditingController _controller = TextEditingController();
  late WebSocketChannel _channel;
  final List<String> _messages = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    // Добавляем токен в query параметры
    final uri = Uri.parse('ws://127.0.0.1:8000/api/v1/ws/').replace(
      queryParameters: {
        'token': widget.jwtToken,
      },
    );
    
    _channel = WebSocketChannel.connect(uri);
    _isConnected = true;
    
    _channel.stream.listen(
      (message) {
        setState(() {
          _messages.insert(0, 'Получено: $message');
        });
      },
      onError: (error) {
        setState(() {
          _messages.insert(0, 'Ошибка: $error');
        });
      },
      onDone: () {
        setState(() {
          _isConnected = false;
          _messages.insert(0, 'Соединение закрыто');
        });
      },
    );
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && _isConnected) {
      // Можно отправлять сообщения в формате JSON с токеном
      final message = {
        'text': _controller.text,
        'token': widget.jwtToken, // Или отправлять токен с каждым сообщением
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _channel.sink.add(jsonEncode(message)); // Не забудьте импортировать dart:convert
      
      setState(() {
        _messages.insert(0, 'Отправлено: ${_controller.text}');
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Demo'),
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.link : Icons.link_off),
            onPressed: _isConnected ? _disconnect : _reconnect,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Введите сообщение',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_messages[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _disconnect() {
    _channel.sink.close();
  }

  void _reconnect() {
    _connect();
  }

  @override
  void dispose() {
    _channel.sink.close();
    _controller.dispose();
    super.dispose();
  }
}