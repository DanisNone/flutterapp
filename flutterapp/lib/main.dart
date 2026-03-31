import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/firebase_options.dart';
import 'package:flutterapp/service/chat_manager.dart';
import 'package:flutterapp/service/chat_repository.dart';
import 'package:flutterapp/service/follower_service.dart';
import 'package:flutterapp/service/notification_service.dart';
import 'package:flutterapp/theme/app_theme.dart';
import 'package:flutterapp/screens/auth/login_screen.dart';
import 'package:flutterapp/service/theme_service.dart';
import 'package:provider/provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Фоновое сообщение: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<ChatManager>(
          create: (_) => ChatManager(),
        ),
        ChangeNotifierProxyProvider<ChatManager, ChatRepository>(
          create: (context) => ChatRepository(context.read<ChatManager>()),
          update: (context, transport, previous) {
            final repository = previous ?? ChatRepository(transport);
            repository.attachTransport(transport);
            return repository;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(
          create: (_) => NotificationService()..init(),
        ),
        ChangeNotifierProvider(create: (_) => FollowerService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, NotificationService>(
      builder: (context, themeService, notificationService, child) {
        return MaterialApp(
          title: 'Flutter Chat',
          debugShowCheckedModeBanner: false,
          themeMode: themeService.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const GradientBackground(
            child: LoginScreen(),
          ),
        );
      },
    );
  }
}
