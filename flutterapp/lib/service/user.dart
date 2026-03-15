import 'dart:convert';

import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/routes/all_routes.dart' show meUrl, searchUsersUrl;
import 'package:flutterapp/model/jwttoken.dart';
import 'package:http/http.dart' as http;

Future<User> getUser(JWTToken token) async {
  await token.updateToken();
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

Future<List<User>> searchUsers(JWTToken token, String query, {int limit = 20}) async {
  await token.updateToken();
  final uri = Uri.parse(searchUsersUrl).replace(
    queryParameters: {
      "q": query,
      "limit": limit.toString()
    }
  );
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