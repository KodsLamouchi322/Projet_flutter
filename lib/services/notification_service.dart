import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Service de notifications push via Firebase Cloud Messaging
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ─── Initialisation ───────────────────────────────────────────────────────
  Future<void> initialiser() async {
    // Demander les permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Notifications autorisées');
    }

    // Écouter les messages foreground
    FirebaseMessaging.onMessage.listen(_handleMessage);

    // Écouter les clics sur notifications en background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
  }

  // ─── Récupérer le token FCM ───────────────────────────────────────────────
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Erreur token FCM: $e');
      return null;
    }
  }

  // ─── S'abonner à un topic ─────────────────────────────────────────────────
  Future<void> abonnerTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> desabonnerTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  // ─── Handlers ────────────────────────────────────────────────────────────
  void _handleMessage(RemoteMessage message) {
    debugPrint('Message reçu: ${message.notification?.title}');
    // Ici on peut afficher une notification locale
  }

  void _handleNotificationClick(RemoteMessage message) {
    debugPrint('Notification cliquée: ${message.data}');
    // Naviguer vers la page correspondante
  }

  // ─── Topics prédéfinis ───────────────────────────────────────────────────
  static const String topicEvenements = 'evenements';
  static const String topicNouveautes = 'nouveautes';
  static const String topicAnnonces = 'annonces';
}

/// Handler background (top-level function requise par FCM)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Message en arrière-plan: ${message.messageId}');
}
