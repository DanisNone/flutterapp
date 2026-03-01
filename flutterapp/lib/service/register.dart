import 'dart:convert';
import 'package:flutterapp/routes/all_routes.dart' show registerUrl;
import 'package:flutterapp/service/jwttoken.dart';
import 'package:http/http.dart' as http;

Future<JWTToken> register(String email, String username, String fullName, String password, String confirmPassword) async {
  if (password != confirmPassword) {
    throw Exception('Пароли не совпадают');
  }
  
  if (password.length < 6) {
    throw Exception('Пароль должен содержать минимум 6 символов');
  }

  try {
    final res = await http.post(
      Uri.parse(registerUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "email": email,
        "username": username,
        "full_name": fullName,
        "password": password,
        "confirm_password": confirmPassword,
      }),
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200 || res.statusCode == 201) {
      return JWTToken.fromRawJson(res.body);
    } else {
      try {
        final errorData = jsonDecode(res.body);
        throw Exception('Ошибка регистрации: ${errorData['message'] ?? res.body}');
      } catch (e) {
        throw Exception('Ошибка регистрации: ${res.statusCode}');
      }
    }
  } catch (e) {
    if (e.toString().contains('Timeout')) {
      throw Exception('Превышено время ожидания ответа от сервера');
    }
    rethrow;
  }
}