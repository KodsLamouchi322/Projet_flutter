import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../firebase_options.dart';
import 'local_notification_service.dart';

/// Service de notifications push via Firebase Cloud Messaging
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await Permission.notification.request();
      }
      await _fcm.requestPermission(alert: true, badge: true, sound: true);

      await _pousserTokenFirestore();

      _fcm.onTokenRefresh.listen((t) async {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          try {
            await FirebaseFirestore.instance
                .collection('membres')
                .doc(uid)
                .update({'fcmToken': t});
          } catch (e) {
            debugPrint('FCM token refresh save: $e');
          }
        }
      });

      FirebaseMessaging.onMessage.listen((msg) async {
        final title = msg.notification?.title ?? 'BiblioX';
        final body = msg.notification?.body ?? '';
        await LocalNotificationService().afficherNotification(
          titre: title,
          corps: body.isNotEmpty ? body : 'Nouvelle notification',
          channel: LocalNotificationService.channelFcm,
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
    } catch (e) {
      debugPrint('FCM init error (non-fatal): $e');
    }
  }

  Future<void> _pousserTokenFirestore() async {
    final token = await _fcm.getToken();
    if (token == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('membres')
            .doc(uid)
            .update({'fcmToken': token});
      } catch (e) {
        debugPrint('FCM token Firestore: $e');
      }
    }
  }

  /// À appeler après connexion (token + uid disponibles)
  Future<void> synchroniserTokenSiConnecte() async {
    await _pousserTokenFirestore();
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('Erreur token FCM: $e');
      return null;
    }
  }

  Future<void> abonnerTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  Future<void> desabonnerTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  void _handleNotificationClick(RemoteMessage message) {
    debugPrint('Notification cliquée: ${message.data}');
  }

  static const String topicEvenements = 'evenements';
  static const String topicNouveautes = 'nouveautes';
  static const String topicAnnonces = 'annonces';
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Message en arrière-plan: ${message.messageId}');
}
