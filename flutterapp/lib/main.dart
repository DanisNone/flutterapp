import 'package:flutter/material.dart';
import 'package:flutterapp/screens/auth/login_screen.dart';
import 'package:flutterapp/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const GradientBackground(child: LoginScreen()),
    );
  }
}
