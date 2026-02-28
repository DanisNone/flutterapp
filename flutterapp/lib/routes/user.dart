import 'dart:convert';

import 'package:http/http.dart' as http;
import 'all_routes.dart' as routes;


Future<void> fetchUser(int userId) async {
  try {
    final response = await http.get(
      Uri.parse(routes.users + userId.toString())
    );
    if (response.statusCode == 200) {
      print("Response data: ${response.body}");

    final List<dynamic> data = jsonDecode(response.body);

    } else {
      // Ошибка сервера
      print('Error: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (e) { 
    print("Exception: $e");
  }
}