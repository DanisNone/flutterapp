import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutterapp/screens/auth/login_screen.dart';
import 'package:flutterapp/screens/conversations_screen.dart';
import 'package:flutterapp/model/jwttoken.dart';
import 'package:flutterapp/service/secure_storage.dart';

void main() async {
  JWTToken? token = await SecureStorageService().getJWTToken();
  runApp(MyApp(token: token));
}

class MyApp extends StatelessWidget {
  final JWTToken? token;
  const MyApp({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: token != null ? ConversationsScreen(token: token!) : AuthScreen(),
    );
  }
} 