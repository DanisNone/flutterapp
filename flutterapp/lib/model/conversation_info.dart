import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/model/user_info.dart';

class ConversationInfo {
  final int id;
  final List<UserInfo> usersInfo;
  DateTime lastUpdate;
  String? lastMessage;
  bool isDialog;

  ConversationInfo({
    required this.id,
    required this.usersInfo,
    required this.lastUpdate,
    required this.lastMessage,
    required this.isDialog,
  });

  factory ConversationInfo.fromJson(Map<String, dynamic> json) {
    List<UserInfo> usersInfo = (json['users'] as List)
        .map((x) => UserInfo.fromJson(x as Map<String, dynamic>))
        .toList();
    return ConversationInfo(
      id: json['id'] as int,
      usersInfo: usersInfo,
      lastUpdate: DateTime.parse(json['last_update']),
      lastMessage: json['last_message'] as String?,
      isDialog: json['is_dialog'] as bool,
    );
  }

  String getName(int currentUserId) {
    if (!isDialog || usersInfo.length != 2) {
      return 'Беседа #$id';
    }
    if (usersInfo[0].id == currentUserId) {
      return usersInfo[1].username;
    }
    return usersInfo[0].username;
  }

  String? getAvatarUrl(int currentUserId) {
    if (!isDialog || usersInfo.length != 2) return null;

    if (usersInfo[0].id == currentUserId) return usersInfo[1].avatarUrl;
    return usersInfo[0].avatarUrl;
  }
}
