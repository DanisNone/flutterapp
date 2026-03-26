class UserInfo {
  final int id;
  final String username;
  final String? avatarUrl;
  final String? fullName;
  final String? bio;
  int lastMessageReadId;

  UserInfo({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.fullName,
    required this.bio,
    required this.lastMessageReadId,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      fullName: json['full_name'] as String?,
      bio: json['bio'] as String?,
      lastMessageReadId: json['last_message_read_id'] as int? ?? -1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatar_url': avatarUrl,
    'full_name': fullName,
    'bio': bio,
    'last_message_read_id': lastMessageReadId
  };
}