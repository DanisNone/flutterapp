import 'dart:convert';

class UserInfo {
  final int id;
  final String username;
  final String? avatarUrl;

  UserInfo({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['user_id'] as int,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  factory UserInfo.fromRawJson(String json) {
    return UserInfo.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  // Метод для конвертации в JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'username': username,
      'avatar_url': avatarUrl,
    };
  }

  UserInfo copyWith({
    int? id,
    String? username,
    String? fullName,
    String? avatarUrl,
  }) {
    return UserInfo(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
