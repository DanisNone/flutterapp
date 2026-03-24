import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _token;
  String? get token => _token;

  Future<void> init() async {
    await _initLocalNotifications();

    await _requestPermission();
    await _initToken();
    _listenTokenRefresh();

    _setupInteractedMessages();
    _setupForegroundHandler();
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await _localNotifications.initialize(settings: settings);
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission();

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('Нет разрешения');
    }
  }

  Future<void> _initToken() async {
    _token = await _messaging.getToken();
    debugPrint('Token: $_token');
  }

  void _listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _token = newToken;
      notifyListeners();
    });
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message');

      _showLocalNotification(message);
    });
  }

  Future<void> _setupInteractedMessages() async {
    // killed state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    debugPrint('Navigate with data: $data');

    // пример:
    // if (data['type'] == 'chat') {
    //   navigatorKey.currentState?.pushNamed('/chat', arguments: data);
    // }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
    );
  }
}