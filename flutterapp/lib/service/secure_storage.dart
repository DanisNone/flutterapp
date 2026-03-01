import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutterapp/service/jwttoken.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveJWTToken(JWTToken token) async {
    await _storage.write(key: 'accessToken', value: token.accessToken);
    await _storage.write(key: 'tokenType', value: token.tokenType);
  }

  Future<JWTToken?> getJWTToken() async {
    String? accessToken = await _storage.read(key: 'accessToken');
    String? tokenType = await _storage.read(key: 'tokenType');
    if (accessToken == null || tokenType == null) return null;
    return JWTToken(accessToken: accessToken, tokenType: tokenType);
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}