import 'dart:convert';

class Message {
  int? id;
  final String text;
  final int senderId;
  DateTime createdAt;
  final int conversationId;

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.createdAt,
    required this.conversationId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      text: json['text'] as String,
      senderId: json['sender_id'] as int,
      createdAt: DateTime.parse(json['created_at']),
      conversationId: json['conversation_id'] as int,
    );
  }
  factory Message.fromRawJson(String json) {
    return Message.fromJson(jsonDecode(json));
  }
}
