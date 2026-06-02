import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> cryptolensFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();
  await CryptoFirebaseMessagingService.showRemoteMessage(message);
}

class CryptoFirebaseMessagingService {
  CryptoFirebaseMessagingService._();

  static const _channelId = 'price_alerts';
  static const _channelName = 'Price alerts';
  static const _prefsName = 'fcm';
  static const _tokenKey = 'token';

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _localNotificationsReady = false;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    await _initializeLocalNotifications();

    FirebaseMessaging.onBackgroundMessage(
      cryptolensFirebaseMessagingBackgroundHandler,
    );

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _saveToken();
    _messaging.onTokenRefresh.listen(
      (token) => unawaited(_persistToken(token)),
    );
    FirebaseMessaging.onMessage.listen(
      (message) => unawaited(showRemoteMessage(message)),
    );
  }

  static Future<String?> currentToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefsName.$_tokenKey');
  }

  static Future<void> showRemoteMessage(RemoteMessage message) async {
    await _initializeLocalNotifications();
    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'CryptoLens alert';
    final body =
        message.notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString();
    if (body == null || body.trim().isEmpty) return;
    await showNotification(
      title: title,
      body: body,
      notificationId: DateTime.now().millisecondsSinceEpoch.remainder(
        1000000000,
      ),
    );
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    int? notificationId,
  }) async {
    await _initializeLocalNotifications();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'CryptoLens price alert notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _notifications.show(
      notificationId ??
          DateTime.now().millisecondsSinceEpoch.remainder(1000000000),
      title,
      body,
      details,
    );
  }

  static Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsReady) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _notifications.initialize(initSettings);
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'CryptoLens price alert notifications',
            importance: Importance.high,
          ),
        );
    _localNotificationsReady = true;
  }

  static Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) await _persistToken(token);
    } catch (error, stackTrace) {
      debugPrint('FCM token unavailable: $error\n$stackTrace');
    }
  }

  static Future<void> _persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsName.$_tokenKey', token);
  }
}
