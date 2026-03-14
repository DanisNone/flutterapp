class ConversationInfo {
  final int id;
  final List<(int, String)>? usersInfo;
  DateTime lastUpdate;
  String? lastMessage;

  ConversationInfo({
    required this.id,
    required this.usersInfo,
    required this.lastUpdate,
    required this.lastMessage,
  });

  factory ConversationInfo.fromJson(Map<String, dynamic> json) {
    List<(int, String)>? usersInfo;
    if (json['users'] != null) {
      usersInfo = (json['users'] as List).map<(int, String)>((e) {
        final list = e as List;
        return (list[0] as int, list[1] as String);
      }).toList();
    }
    return ConversationInfo(
      id: json['id'] as int,
      usersInfo: usersInfo,
      lastUpdate: DateTime.parse(json['last_update']),
      lastMessage: json['last_message'] as String?,
    );
  }

  String getName(int currentUserId) {
    if (usersInfo == null || usersInfo!.length != 2) {
        return 'Беседа #$id';
    }
    if (usersInfo![0].$1 == currentUserId) {
      return usersInfo![1].$2;
    }
    return usersInfo![0].$2;
  }
}
