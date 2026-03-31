import 'dart:convert';

import 'package:flutterapp/routes/all_routes.dart';
import 'package:http/http.dart' as http;

class JWTToken {
  String accessToken;
  String refreshToken;
  String tokenType;
  DateTime? _lastUpdate;

  JWTToken({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });

  factory JWTToken.fromJson(Map<String, dynamic> json) {
    return JWTToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
    };
  }

  factory JWTToken.fromRawJson(String str) =>
      JWTToken.fromJson(jsonDecode(str));

  String toRawJson() => jsonEncode(toJson());
  String toHeaderValue() {
    return "$tokenType $accessToken";
  }

  Future<bool> updateToken() async {
    print("$_lastUpdate, ${DateTime.now()}");
    if (_lastUpdate != null && _lastUpdate!.add(Duration(minutes: 15)).isAfter(DateTime.now())) {
      return true;
    }
    final res = await http.post(
      Uri.parse(refreshUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"refresh_token": refreshToken}),
    );
    print(res.body);
    if (res.statusCode == 200) {
      final token = JWTToken.fromRawJson(res.body);
      accessToken = token.accessToken;
      refreshToken = token.refreshToken;
      tokenType = token.tokenType;
      _lastUpdate = DateTime.now();
      return true;
    }
    return false;
  }
}
