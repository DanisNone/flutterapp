import 'dart:convert';

import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/model/user_info.dart';
import 'package:flutterapp/routes/all_routes.dart';
import 'package:flutterapp/service/jwttoken_manager.dart';
import 'package:http/http.dart' as http;

class PagedUserInfoPage {
  final List<UserInfo> users;
  final String? nextCursor;
  final bool hasMore;
  final int? totalCount;

  const PagedUserInfoPage({
    required this.users,
    required this.nextCursor,
    required this.hasMore,
    required this.totalCount,
  });
}

Future<(int, bool)> getOrCreateDialog(String otherUsername) async {
  JWTToken token = await JWTTokenManager().getJWTToken(update: true);
  final response = await http.get(
    Uri.parse(getOrCreateDialogUrl(otherUsername)),
    headers: {"Authorization": token.toHeaderValue()},
  );
  final Map<String, dynamic> data = json.decode(response.body);
  if (response.statusCode == 200) {
    return (data["id"] as int, data["already_exists"] as bool);
  }
  throw Exception(
    'Failed to create dialog: ${response.statusCode}; ${data["detail"]}',
  );
}

Future<(int, bool)> getOrCreateSaved() async {
  JWTToken token = await JWTTokenManager().getJWTToken(update: true);
  final response = await http.get(
    Uri.parse(getOrCreateSavedUrl),
    headers: {"Authorization": token.toHeaderValue()},
  );
  final Map<String, dynamic> data = json.decode(response.body);
  if (response.statusCode == 200) {
    return (data["id"] as int, data["already_exists"] as bool);
  }
  throw Exception(
    'Failed to create saved: ${response.statusCode}; ${data["detail"]}',
  );
}

Future<User> getMe() async {
  JWTToken token = await JWTTokenManager().getJWTToken(update: true);
  final res = await http.get(
    Uri.parse(meUrl),
    headers: {"Authorization": token.toHeaderValue()},
  );

  if (res.statusCode == 200) {
    return User.fromRawJson(res.body);
  } else {
    throw Exception('Ошибка входа: ${res.statusCode} ${res.body}');
  }
}

Future<List<UserInfo>> searchUsers(
  String query, {
  int limit = 20,
}) async {
  final token = await JWTTokenManager().getJWTToken(update: true);
  final uri = Uri.parse(searchUsersUrl).replace(
    queryParameters: {
      'q': query,
      'limit': limit.toString(),
    },
  );
  final res = await http.get(
    uri,
    headers: {"Authorization": token.toHeaderValue()},
  );

  if (res.statusCode == 200) {
    final decoded = jsonDecode(res.body);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((json) => UserInfo.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    if (decoded is Map<String, dynamic> && decoded['users'] is List) {
      return (decoded['users'] as List)
          .whereType<Map>()
          .map((json) => UserInfo.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return const <UserInfo>[];
  } else {
    throw Exception('Ошибка поиска: ${res.statusCode} ${res.body}');
  }
}

Future<JWTToken> register(
  String email,
  String username,
  String fullName,
  String password,
  String confirmPassword,
  String? fcmToken,
) async {
  if (password != confirmPassword) {
    throw Exception('Пароли не совпадают');
  }

  if (password.length < 8) {
    throw Exception('Пароль должен содержать минимум 8 символов');
  }

  try {
    final res = await http
        .post(
          Uri.parse(registerUrl)
              .replace(queryParameters: {"fcm_token": fcmToken}),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "email": email,
            "username": username,
            "full_name": fullName,
            "password": password,
            "confirm_password": confirmPassword
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200 || res.statusCode == 201) {
      JWTToken token = JWTToken.fromRawJson(res.body);
      await JWTTokenManager().saveJWTToken(token);
      return token;
    } else {
      dynamic errorData;
      try {
        errorData = jsonDecode(res.body);
      } catch (e) {
        throw Exception('Ошибка регистрации: ${res.statusCode};');
      }
      throw Exception('Ошибка регистрации: ${errorData['detail'] ?? res.body}');
    }
  } catch (e) {
    if (e.toString().contains('Timeout')) {
      throw Exception('Превышено время ожидания ответа от сервера');
    }
    rethrow;
  }
}

Future<JWTToken> login(String email, String password, String? fcmToken) async {
  final res = await http.post(
    Uri.parse(authUrl).replace(queryParameters: {"fcm_token": fcmToken}),
    body: {"username": email, "password": password},
  );

  if (res.statusCode == 200) {
    JWTToken token = JWTToken.fromRawJson(res.body);
    await JWTTokenManager().saveJWTToken(token);
    return token;
  } else {
    throw Exception('Ошибка входа: ${res.statusCode} ${res.body}');
  }
}

Future<void> followUser(int followingId) async {
  final token = await JWTTokenManager().getJWTToken(update: true);
  final response = await http.post(
    Uri.parse(followUrl),
    headers: {
      "Authorization": token.toHeaderValue(),
      "Content-Type": "application/json",
    },
    body: jsonEncode({"following_id": followingId}),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    return;
  }

  String? detail;
  if (response.body.isNotEmpty) {
    try {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic> && data['detail'] != null) {
        detail = data['detail'].toString();
      }
    } catch (_) {
      // Fall through to a generic error below.
    }
  }

  throw Exception(detail ?? 'Ошибка подписки: ${response.statusCode}');
}

Future<void> unfollowUser(int userId) async {
  final token = await JWTTokenManager().getJWTToken(update: true);
  final response = await http.delete(
    Uri.parse(unfollowUrl),
    headers: {
      "Authorization": token.toHeaderValue(),
      "Content-Type": "application/json",
    },
    body: jsonEncode({"following_id": userId})
  );

  if (response.statusCode == 200 || response.statusCode == 204) {
    return;
  }

  String? detail;
  if (response.body.isNotEmpty) {
    try {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic> && data['detail'] != null) {
        detail = data['detail'].toString();
      }
    } catch (_) {
      // Fall through to a generic error below.
    }
  }

  throw Exception(detail ?? 'Ошибка отписки: ${response.statusCode}');
}

Future<PagedUserInfoPage> getFollowersPage({
  int limit = 50,
  String? cursor,
  String? q,
}) async {
  return _loadPagedRelations(
    limit: limit,
    cursor: cursor,
    q: q,
    url: Uri.parse(meFollowersUrl)
  );
}

Future<PagedUserInfoPage> getFollowingPage({
  int limit = 50,
  String? cursor,
  String? q,
}) async {
  return _loadPagedRelations(
    limit: limit,
    cursor: cursor,
    q: q,
    url: Uri.parse(meFollowingsUrl)
  );
}

Future<PagedUserInfoPage> _loadPagedRelations({
  required int limit,
  required String? cursor,
  required String? q,
  required Uri url
}) async {
  final token = await JWTTokenManager().getJWTToken(update: true);
  final normalizedQuery = q?.trim();
  final parameters = <String, String>{
    'limit': limit.toString(),
    if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    if (normalizedQuery != null && normalizedQuery.isNotEmpty) 'q': normalizedQuery,
  };

  final newStyleUri = url.replace(queryParameters: parameters);
  final response = await http.get(
    newStyleUri,
    headers: {"Authorization": token.toHeaderValue()},
  );

  if (response.statusCode == 200) {
    return _parsePagedUsersResponse(response.body, fallbackLimit: limit, cursor: cursor);
  }
  throw Exception('Ошибка получения списка: ${response.statusCode} ${response.body}');
}

PagedUserInfoPage _parsePagedUsersResponse(
  String body, {
  required int fallbackLimit,
  required String? cursor,
}) {
  final cursorOffset = int.tryParse(cursor ?? '') ?? 0;
  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) {
    final rawUsers = decoded['users'];
    final users = rawUsers is List
        ? rawUsers
            .whereType<Map>()
            .map((json) => UserInfo.fromJson(Map<String, dynamic>.from(json)))
            .toList()
        : <UserInfo>[];

    final page = decoded['page'];
    final pageMap = page is Map<String, dynamic>
        ? page
        : page is Map
            ? Map<String, dynamic>.from(page)
            : <String, dynamic>{};

    final nextCursorFromApi = pageMap['next_cursor']?.toString();
    final hasMore = pageMap['has_more'] as bool? ??
        users.length >= fallbackLimit;
    final fallbackNextCursor = hasMore ? (cursorOffset + users.length).toString() : null;
    final totalCount = pageMap['total_count'] as int?;

    return PagedUserInfoPage(
      users: users,
      nextCursor: nextCursorFromApi ?? fallbackNextCursor,
      hasMore: hasMore,
      totalCount: totalCount,
    );
  }

  if (decoded is List) {
    final users = decoded
        .whereType<Map>()
        .map((json) => UserInfo.fromJson(Map<String, dynamic>.from(json)))
        .toList();
    final hasMore = users.length >= fallbackLimit;
    final nextCursor = hasMore ? (cursorOffset + users.length).toString() : null;
    return PagedUserInfoPage(
      users: users,
      nextCursor: nextCursor,
      hasMore: hasMore,
      totalCount: null,
    );
  }

  return const PagedUserInfoPage(
    users: <UserInfo>[],
    nextCursor: null,
    hasMore: false,
    totalCount: null,
  );
}

Future<List<UserInfo>> getFollowers({int limit = 50, int offset = 0}) async {
  final page = await getFollowersPage(limit: limit, cursor: offset.toString());
  return page.users;
}

Future<List<UserInfo>> getFollowing({int limit = 50, int offset = 0}) async {
  final page = await getFollowingPage(limit: limit, cursor: offset.toString());
  return page.users;
}
