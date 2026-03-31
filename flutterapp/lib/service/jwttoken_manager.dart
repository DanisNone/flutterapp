import 'dart:convert';

import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/routes/all_routes.dart';
import 'package:flutterapp/service/secure_storage.dart';
import 'package:http/http.dart' as http;

class JWTTokenManager {
  JWTToken? token;
  DateTime? _lastUpdate;

  JWTTokenManager._internal();

  static final JWTTokenManager _instance = JWTTokenManager._internal();

  factory JWTTokenManager() {
    return _instance;
  }

  Future<void> saveJWTToken(JWTToken token) async {
    _lastUpdate = DateTime.now();
    return SecureStorageService().saveJWTToken(token);
  }

  Future<JWTToken> getJWTToken({bool update = false}) async {
    token ??= await SecureStorageService().getJWTToken();
    if (update) {
      await updateToken();
    }
    if (token == null) {
      throw Exception("token is not exists");
    }
    return token!;
  }

  Future<bool> updateToken() async {
    if (token == null) {
      return false;
    }

    if (_lastUpdate != null && _lastUpdate!.add(Duration(minutes: 15)).isAfter(DateTime.now())) {
      return true;
    }

    final res = await http.post(
      Uri.parse(refreshUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"refresh_token": token!.refreshToken}),
    );  
    if (res.statusCode == 200) {
      token = JWTToken.fromRawJson(res.body);
      _lastUpdate = DateTime.now();
      await SecureStorageService().saveJWTToken(token!);
      return true;
    }
    return false;
  }

  Future<void> deleteJWTToken() async {
    return SecureStorageService().deleteJWTToken();
  }
}
