import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutterapp/model/jwttoken.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveJWTToken(JWTToken token) async {
    await _storage.write(key: 'accessToken', value: token.accessToken);
    await _storage.write(key: 'refreshToken', value: token.refreshToken);
    await _storage.write(key: 'tokenType', value: token.tokenType);
  }

  Future<JWTToken?> getJWTToken() async {
    String? accessToken = await _storage.read(key: 'accessToken');
    String? refreshToken = await _storage.read(key: 'refreshToken');
    String? tokenType = await _storage.read(key: 'tokenType');
    if (accessToken == null || tokenType == null || refreshToken == null) return null;
    return JWTToken(accessToken: accessToken, refreshToken: refreshToken, tokenType: tokenType);
  }

  Future<void> deleteJWTToken() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'tokenType');
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}