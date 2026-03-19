import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/firebase_options.dart';

import 'package:flutterapp/theme/app_theme.dart';
import 'package:flutterapp/screens/auth/login_screen.dart';


// 1. Обработчик фоновых сообщений
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Обработка фонового сообщения: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Инициализация Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  // 3. Фоновый обработчик
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    setupPushNotifications();
  }

  Future<void> setupPushNotifications() async {
    // 4. Разрешения
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('Нет разрешения на уведомления');
      return;
    }

    // 5. Токен
    String? token = await _messaging.getToken();
    debugPrint('FCM Token: $token');
    // TODO: отправь на сервер

    // 6. Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground: ${message.notification?.title}');
    });

    // 7. Нажатие из фона
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Открыто из уведомления (background)');
      // TODO: навигация
    });

    // 8. Запуск из killed state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('Открыто из уведомления (killed)');
      // TODO: навигация
    }
  }

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