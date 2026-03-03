import 'dart:convert';

import 'package:flutterapp/model/ConversationInfo.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/model/message.dart';
import 'package:flutterapp/model/user.dart';
import 'package:flutterapp/routes/all_routes.dart';
import 'package:http/http.dart' as http;




Future<List<ConversationInfo>> getAllUserConversations(User user, JWTToken token) async {
  final response = await http.get(
    Uri.parse('$getConversationsUrl/${user.id}'),
    headers: {
      "Authorization": token.toHeaderValue()
    }
  );
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((c) => ConversationInfo.fromJson(c)).toList();
  }
  throw Exception('Failed to load conversations: ${response.statusCode}');
}

Future<(int, bool)> getOrCreateDialog(User user, int otherUserId, JWTToken token) async {
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

Future<List<Message>> getConversationMessages(
  int conversationId,
  JWTToken token,
) async {
  final response = await http.get(
  Uri.parse('$getAllMessageUrl/$conversationId'),
    headers: {
      "Authorization": token.toHeaderValue()
    }
  );
  final body = jsonDecode(response.body);
  if (response.statusCode == 200) {
    final List<dynamic> data = body;
    return data.map((m) => Message.fromJson(m)).toList();
  }
  throw Exception('Failed to load messages: ${response.statusCode}; ${body["detail"]}');
}