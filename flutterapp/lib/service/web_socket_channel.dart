import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  late WebSocketChannel _channel;
  
  void connect(String url) {
    _channel = IOWebSocketChannel.connect(url);
    
    // Подписка на входящие сообщения
    _channel.stream.listen(
      (message) {
        print('Получено сообщение: $message');
      },
      onError: (error) {
        print('Ошибка: $error');
      },
      onDone: () {
        print('Соединение закрыто');
      },
    );
  }
  
  void sendMessage(String message) {
    _channel.sink.add(message);
  }
  
  void disconnect() {
    _channel.sink.close();
  }
}