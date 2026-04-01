// lib/services/push_notification_handler.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationHandler {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onBackgroundMessage(_handleBackground);
  }

  static Future<void> _handleForeground(RemoteMessage message) async {
    final data = message.notification;
    if (data == null) return;
    await _localNotif.show(
      data.hashCode,
      data.title,
      data.body,
      const NotificationDetails(
        android: AndroidNotificationDetails('main_channel', 'Notifications',
            importance: Importance.high, priority: Priority.high),
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackground(RemoteMessage message) async {
    print('Background message: \');
  }

  static Future<String?> getToken() => _messaging.getToken();
}
