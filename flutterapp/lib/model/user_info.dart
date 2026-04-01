class UserInfo {
  final int id;
  final String username;
  final String? avatarUrl;
  final String? fullName;
  final String? bio;
  final bool? isFollowing;
  int lastMessageReadId;

  UserInfo({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.fullName,
    required this.bio,
    required this.lastMessageReadId,
    this.isFollowing,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      fullName: json['full_name'] as String?,
      bio: json['bio'] as String?,
      lastMessageReadId: json['last_message_read_id'] as int? ?? -1,
      isFollowing: json['is_following'] as bool?,
    );
  }

  UserInfo copyWith({
    int? id,
    String? username,
    String? avatarUrl,
    String? fullName,
    String? bio,
    int? lastMessageReadId,
    bool? isFollowing,
  }) {
    return UserInfo(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      lastMessageReadId: lastMessageReadId ?? this.lastMessageReadId,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatar_url': avatarUrl,
    'full_name': fullName,
    'bio': bio,
    'last_message_read_id': lastMessageReadId,
    if (isFollowing != null) 'is_following': isFollowing,
  };
}
