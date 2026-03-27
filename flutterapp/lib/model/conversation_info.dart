import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/model/user_info.dart';

enum ChatType {
  group, dialog, saved
}


class ConversationInfo {
  final int id;
  final List<UserInfo> usersInfo;
  DateTime lastUpdate;
  String? lastMessage;
  ChatType chatType;
  String? name;
  String? avatarUrl;

  ConversationInfo({
    required this.id,
    required this.usersInfo,
    required this.lastUpdate,
    required this.lastMessage,
    required this.chatType,
    required this.name,
    required this.avatarUrl
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
      chatType: ChatType.values.byName(json['chat_type']),
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?
    );
  }

  UserInfo? userInfoById(int userId) {
    for (final user in usersInfo) {
      if (user.id == userId) return user;
    }
    return null;
  }

  List<UserInfo> otherUsers(int currentUserId) {
    return usersInfo.where((u) => u.id != currentUserId).toList();
  }

  int readByOthersCount(Message message, int currentUserId) {
    final messageId = message.id;
    if (messageId == null) return 0;

    return otherUsers(currentUserId)
        .where((u) => u.lastMessageReadId >= messageId)
        .length;
  }

  bool isReadByOthers(Message message, int currentUserId) {
    return readByOthersCount(message, currentUserId) > 0;
  }

  List<UserInfo> readByUsers(Message message, int currentUserId) {
    final messageId = message.id;
    if (messageId == null) return <UserInfo>[];

    return usersInfo
        .where((u) => u.id != currentUserId && u.lastMessageReadId >= messageId)
        .toList();
  }

  String getName(int currentUserId) {
    const String error = 'Internel Error';
    switch (chatType) {
      case ChatType.saved:
        return "Избранное";
      case ChatType.dialog:
        if (usersInfo.length != 2) return error;
        if (usersInfo[0].id == currentUserId) return usersInfo[1].username;
        return usersInfo[0].username;
      case ChatType.group:
        return name ?? error;
    }
  }

  String? getAvatarUrl(int currentUserId) {
    switch (chatType) {
      case ChatType.saved: return usersInfo[0].avatarUrl;
      case ChatType.dialog:
        if (usersInfo[0].id == currentUserId)return usersInfo[1].avatarUrl;
        return usersInfo[0].avatarUrl;
      case ChatType.group: return avatarUrl;
    }
  }
}