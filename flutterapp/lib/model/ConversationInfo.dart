import 'package:flutterapp/model/message.dart';

class ConversationInfo {
  final int id;
  final List<(int, String)>? usersInfo;
  final DateTime lastUpdate;
  final String? lastMessage;

  const ConversationInfo({required this.id, required this.usersInfo, required this.lastUpdate, required this.lastMessage});

  factory ConversationInfo.fromJson(Map<String, dynamic> json) {
    List<(int, String)>? usersInfo;
    if (json['users_info'] != null) {
      usersInfo = (json['users_info'] as List)
          .map<(int, String)>((e) {
            final list = e as List;
            return (list[0] as int, list[1] as String);
          })
          .toList();
    }
    return ConversationInfo(
      id: json['id'] as int,
      usersInfo: usersInfo,
      lastUpdate: DateTime.parse(json['last_update']),
      lastMessage: json['last_message'] as String?
    );
  }
}