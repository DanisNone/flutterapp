import 'dart:convert';

import 'package:flutterapp/model/conversation_info.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/routes/all_routes.dart';
import 'package:http/http.dart' as http;




Future<(int, bool)> getOrCreateDialog(User user, int otherUserId, JWTToken token) async {
  await token.updateToken();
  final response = await http.get(
    Uri.parse('$getOrCreateDialogUrl/$otherUserId'),
    headers: {
      "Authorization": token.toHeaderValue()
    }
  );
  final Map<String, dynamic> data = json.decode(response.body);
  if (response.statusCode == 200) {
    return (data["id"] as int, data["already_exists"] as bool);
  }
  throw Exception('Failed to create dialog: ${response.statusCode}; ${data["detail"]}');
}