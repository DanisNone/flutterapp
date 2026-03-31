import 'dart:convert';

import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/model/user_info.dart';
import 'package:flutterapp/routes/all_routes.dart';
import 'package:flutterapp/service/jwttoken_manager.dart';
import 'package:http/http.dart' as http;

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

Future<List<User>> searchUsers(
  String query, {
  int limit = 20,
}) async {
  JWTToken? token = await JWTTokenManager().getJWTToken(update: true);
  final uri = Uri.parse(
    searchUsersUrl,
  ).replace(queryParameters: {"q": query, "limit": limit.toString()});
  final res = await http.get(
    uri,
    headers: {"Authorization": token.toHeaderValue()},
  );

  if (res.statusCode == 200) {
    final List<dynamic> data = jsonDecode(res.body);
    return data.map((json) => User.fromJson(json)).toList();
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
  String? fcmToken
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
          Uri.parse(registerUrl).replace(queryParameters: {"fcm_token": fcmToken}),
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
  JWTToken token = await JWTTokenManager().getJWTToken(update: true);
  final response = await http.post(
    Uri.parse(followUrl),
    headers: {
      "Authorization": token.toHeaderValue(),
      "Content-Type": "application/json",
    },
    body: jsonEncode({"following_id": followingId}),
  );
  await getFollowing();

  if (response.statusCode == 200 || response.statusCode == 201) {
    return;
  } else if (response.statusCode == 400) {
    final Map<String, dynamic> data = json.decode(response.body);
    throw Exception(data['detail'] ?? 'Ошибка подписки');
  } else {
    throw Exception('Ошибка подписки: ${response.statusCode}');
  }
}

Future<List<UserInfo>> getFollowers({int limit = 50, int offset = 0}) async {
  JWTToken token = await JWTTokenManager().getJWTToken(update: true);
  final response = await http.get(
    Uri.parse(getFollowersUrl(limit, offset)),
    headers: {"Authorization": token.toHeaderValue()},
  );
  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    return (data["users"] as List).map((e) => UserInfo.fromJson(e)).toList();
  } else {
    throw Exception('Ошибка получения списка подписчиков: ${response.statusCode}');
  }
}

Future<List<UserInfo>> getFollowing({int limit = 50, int offset = 0}) async {
  JWTToken token = await JWTTokenManager().getJWTToken(update: true);
  final response = await http.get(
    Uri.parse(getFollowingUrl(limit, offset)),
    headers: {"Authorization": token.toHeaderValue()},
  );
  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    return (data["users"] as List).map((e) => UserInfo.fromJson(e)).toList();
  } else {
    throw Exception('Ошибка получения списка подписчиков: ${response.statusCode}');
  }
}
