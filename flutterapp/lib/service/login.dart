import 'package:flutterapp/routes/all_routes.dart' show authUrl;
import 'package:flutterapp/model/jwttoken.dart';
import 'package:http/http.dart' as http;

Future<JWTToken> login(String email, String password, String? fcmToken) async {
  final res = await http.post(
    Uri.parse(authUrl).replace(queryParameters: {"fcm_token": fcmToken}),
    body: {"username": email, "password": password},
  );

  if (res.statusCode == 200) {
    return JWTToken.fromRawJson(res.body);
  } else {
    throw Exception('Ошибка входа: ${res.statusCode} ${res.body}');
  }
}
