import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutterapp/screens/auth/login_screen.dart';
import 'package:flutterapp/screens/auth/register_screen.dart';
import 'package:flutterapp/screens/websocket_screen.dart';
import 'package:flutterapp/service/jwttoken.dart';
import 'package:flutterapp/service/secure_storage.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthScreen(),
      // home: RegisterScreen(),
      // home: WebSocketScreen(),
    );
  }
} 