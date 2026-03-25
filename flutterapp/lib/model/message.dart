import 'dart:convert';

class Message {
  final int? id;
  final String text;
  final int senderId;
  final DateTime createdAt;
  final int conversationId;
  final String? clientKey;

  const Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.createdAt,
    required this.conversationId,
    this.clientKey,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: _asInt(json['id']),
      text: json['text']?.toString() ?? '',
      senderId: _asInt(json['sender_id']),
      createdAt: DateTime.parse(json['created_at'].toString()).toUtc(),
      conversationId: _asInt(json['conversation_id']),
      clientKey: json['client_key']?.toString() ??
          json['client_message_id']?.toString(),
    );
  }

  factory Message.fromRawJson(String json) {
    return Message.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Message copyWith({
    int? id,
    String? text,
    int? senderId,
    DateTime? createdAt,
    int? conversationId,
    String? clientKey,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      createdAt: createdAt ?? this.createdAt,
      conversationId: conversationId ?? this.conversationId,
      clientKey: clientKey ?? this.clientKey,
    );
  }

  bool get isPending => id == null;

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.parse(value);
    throw FormatException('Expected int-compatible value, got $value');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        ((id != null &&
                other.id != null &&
                id == other.id) ||
            (id == null &&
                other.id == null &&
                clientKey != null &&
                other.clientKey != null &&
                clientKey == other.clientKey) ||
            (id == null &&
                other.id == null &&
                clientKey == null &&
                other.clientKey == null &&
                conversationId == other.conversationId &&
                senderId == other.senderId &&
                text == other.text &&
                createdAt.toUtc().microsecondsSinceEpoch ==
                    other.createdAt.toUtc().microsecondsSinceEpoch));
  }

  @override
  int get hashCode {
    if (id != null) return Object.hash('id', id);
    if (clientKey != null) return Object.hash('clientKey', clientKey);
    return Object.hash(
      conversationId,
      senderId,
      text,
      createdAt.toUtc().microsecondsSinceEpoch,
    );
  }
}