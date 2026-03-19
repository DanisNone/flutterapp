class UserInfo {
  final int id;
  final String username;
  final String? avatarUrl;
  final String? fullName;
  final String? bio;

  UserInfo({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.fullName,
    this.bio,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      fullName: json['full_name'] as String?,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatar_url': avatarUrl,
    'full_name': fullName,
    'bio': bio,
  };
}