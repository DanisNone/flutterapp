import 'dart:convert';

class JWTToken {
  final String accessToken;
  final String tokenType;

  JWTToken({
    required this.accessToken,
    required this.tokenType,
  });

  factory JWTToken.fromJson(Map<String, dynamic> json) {
    return JWTToken(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
    };
  }

  factory JWTToken.fromRawJson(String str) =>
      JWTToken.fromJson(jsonDecode(str));

  String toRawJson() => jsonEncode(toJson());
  String toHeaderValue() {
    return "$tokenType $accessToken";
  }
}