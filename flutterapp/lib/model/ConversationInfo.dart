class ConversationInfo {
  final int id;
  final List<(int, String)>? userfInfo;

  ConversationInfo({required this.id, required this.userfInfo});

  factory ConversationInfo.fromJson(Map<String, dynamic> json) {
    if (json['users_info'] == null) {
      return ConversationInfo(id: json['id'] as int, userfInfo: null);
    }
    return ConversationInfo(
      id: json['id'] as int,
      userfInfo: (json['users_info'] as List)
          .map<(int, String)>((e) {
            final list = e as List;
            return (list[0] as int, list[1] as String);
          })
          .toList(),
    );
  }
}