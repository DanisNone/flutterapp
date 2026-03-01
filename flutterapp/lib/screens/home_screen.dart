import 'package:flutter/material.dart';
import 'package:flutterapp/service/secure_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String accessToken = "Загрузка...";

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await SecureStorageService().getJWTToken();
    setState(() {
      accessToken =
          token == null ? "Токен не найден" : token.accessToken;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная страница'),
      ),
      body: Center(
        child: Text(
          'Добро пожаловать!\nВаш токен: $accessToken',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}