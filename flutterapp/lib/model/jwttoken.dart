import 'dart:convert';

class JWTToken {
  String accessToken;
  String refreshToken;
  String tokenType;

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
}
