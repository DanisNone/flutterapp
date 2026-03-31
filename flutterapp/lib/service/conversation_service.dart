import 'dart:convert';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/routes/all_routes.dart';
import 'package:flutterapp/service/jwttoken_manager.dart';
import 'package:http/http.dart' as http;

class ConversationService {
  static Future<int> createConversation({
    required String name,
    required List<String> usernames,
  }) async {
    JWTToken token = await JWTTokenManager().getJWTToken(update: true);
    
    final response = await http.post(
      Uri.parse(createConversationUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token.toHeaderValue(),
      },
      body: jsonEncode({
        'name': name,
        'other_usernames': usernames,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'] as int;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to create conversation');
    }
  }

  static Future<void> addUserToConversation(
    int conversationId,
    int userId,
  ) async {
    // JWTToken token = await JWTTokenManager().getJWTToken(update: true);
    throw Exception("not implemented");
    /*
    final response = await http.post(
      Uri.parse(addUserToConversationUrl(conversationId, userId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token.toHeaderValue(),
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to add user');
    }*/
  }

  static Future<void> removeUserFromConversation(
    int conversationId,
    int userId,
  ) async {
    // JWTToken token = await JWTTokenManager().getJWTToken(update: true);
    throw Exception("not implemented");
    /*
    final response = await http.delete(
      Uri.parse(removeUserFromConversationUrl(conversationId, userId)),
      headers: {
        'Authorization': token.toHeaderValue(),
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to remove user');
    }*/
  }
}