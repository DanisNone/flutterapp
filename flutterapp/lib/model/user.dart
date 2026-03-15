import 'dart:convert';

enum UserRole { user, admin }

class User {
  final int id;
  final String email;
  final String username;
  final String fullName;
  final String? bio;
  final String? avatarUrl;
  final UserRole role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    this.bio,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
  });

  // Factory constructor для создания из JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: _parseUserRole(json['role'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  factory User.fromRawJson(String json) {
    return User.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  // Метод для конвертации в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'role': role.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Вспомогательный метод для парсинга роли
  static UserRole _parseUserRole(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  // Метод для создания копии с изменениями
  User copyWith({
    int? id,
    String? email,
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
    UserRole? role,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserResponse(id: $id, email: $email, username: $username, fullName: $fullName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.username == username &&
        other.fullName == fullName &&
        other.bio == bio &&
        other.avatarUrl == avatarUrl &&
        other.role == role &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      username,
      fullName,
      bio,
      avatarUrl,
      role,
      createdAt,
    );
  }
}
