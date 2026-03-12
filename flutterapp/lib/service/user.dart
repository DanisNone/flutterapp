import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/routes/all_routes.dart' show meUrl;
import 'package:flutterapp/model/jwttoken.dart';
import 'package:http/http.dart' as http;


Future<User> getUser(JWTToken token) async {
  await token.updateToken();
  final res = await http.get(
    Uri.parse(meUrl),
    headers: {
      "Authorization": token.toHeaderValue(),
    }
  );

  if (res.statusCode == 200) {
    return User.fromRawJson(res.body);
  } else {
    throw Exception('Ошибка входа: ${res.statusCode} ${res.body}');
  }
}