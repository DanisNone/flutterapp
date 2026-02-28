import 'package:flutter/material.dart';
import 'package:flutterapp/service/jwttoken.dart';

class HomeScreen extends StatelessWidget {
  final JWTToken token;

  const HomeScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Главная страница'),
      ),
      body: Center(
        child: Text(
          'Добро пожаловать!\nВаш токен: ${token.accessToken}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}