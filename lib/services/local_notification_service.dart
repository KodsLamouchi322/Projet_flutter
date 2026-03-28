import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Service de notifications locales — rappels emprunts & événements
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ─── IDs de canaux ────────────────────────────────────────────────────────
  static const String _channelEmprunts  = 'emprunts_rappels';
  static const String _channelEvenements = 'evenements_rappels';
  static const String _channelMessages = 'messages_prives';
  static const String channelFcm = 'fcm_push';

  // ─── Initialisation ───────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      tz_data.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Europe/Paris'));
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );

      // Créer les canaux Android
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelEmprunts, 'Rappels d\'emprunts',
            description: 'Rappels pour les livres à rendre',
            importance: Importance.high,
          ));
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelEvenements, 'Rappels d\'événements',
            description: 'Rappels pour les événements à venir',
            importance: Importance.high,
          ));
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelMessages, 'Messages privés',
            description: 'Notifications de nouveaux messages',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ));
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            channelFcm, 'Notifications BiblioX',
            description: 'Annonces et alertes (Firebase)',
            importance: Importance.high,
          ));

      _initialized = true;
    } catch (e) {
      debugPrint('LocalNotification init error: $e');
    }
  }

  // ─── Rappel emprunt — J-3 avant la date de retour ────────────────────────
  Future<void> planifierRappelEmprunt({
    required String empruntId,
    required String livreTitre,
    required DateTime dateRetour,
  }) async {
    if (!_initialized || kIsWeb) return;
    try {
      final rappelDate = dateRetour.subtract(const Duration(days: 3));
      if (rappelDate.isBefore(DateTime.now())) return;

      final id = empruntId.hashCode.abs() % 100000;
      await _plugin.zonedSchedule(
        id,
        '📚 Rappel de retour',
        'Le livre "$livreTitre" est à rendre dans 3 jours',
        tz.TZDateTime.from(rappelDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelEmprunts, 'Rappels d\'emprunts',
            importance: Importance.high, priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Rappel J-1
      final rappelVeille = dateRetour.subtract(const Duration(days: 1));
      if (rappelVeille.isAfter(DateTime.now())) {
        await _plugin.zonedSchedule(
          id + 1,
          '⚠️ Retour demain !',
          'Le livre "$livreTitre" doit être rendu demain',
          tz.TZDateTime.from(rappelVeille, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelEmprunts, 'Rappels d\'emprunts',
              importance: Importance.max, priority: Priority.max,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('Erreur planification rappel emprunt: $e');
    }
  }

  // ─── Rappel événement — 24h avant ────────────────────────────────────────
  Future<void> planifierRappelEvenement({
    required String evenementId,
    required String titre,
    required DateTime dateDebut,
  }) async {
    if (!_initialized || kIsWeb) return;
    try {
      final rappel24h = dateDebut.subtract(const Duration(hours: 24));
      final rappel1h  = dateDebut.subtract(const Duration(hours: 1));
      final id = evenementId.hashCode.abs() % 100000 + 200000;

      if (rappel24h.isAfter(DateTime.now())) {
        await _plugin.zonedSchedule(
          id,
          '📅 Événement demain',
          '"$titre" commence demain. N\'oubliez pas !',
          tz.TZDateTime.from(rappel24h, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelEvenements, 'Rappels d\'événements',
              importance: Importance.high, priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      if (rappel1h.isAfter(DateTime.now())) {
        await _plugin.zonedSchedule(
          id + 1,
          '🔔 Dans 1 heure !',
          '"$titre" commence dans 1 heure',
          tz.TZDateTime.from(rappel1h, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelEvenements, 'Rappels d\'événements',
              importance: Importance.max, priority: Priority.max,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('Erreur planification rappel événement: $e');
    }
  }

  // ─── Annuler un rappel ────────────────────────────────────────────────────
  Future<void> annulerRappelEmprunt(String empruntId) async {
    if (!_initialized || kIsWeb) return;
    final id = empruntId.hashCode.abs() % 100000;
    await _plugin.cancel(id);
    await _plugin.cancel(id + 1);
  }

  Future<void> annulerRappelEvenement(String evenementId) async {
    if (!_initialized || kIsWeb) return;
    final id = evenementId.hashCode.abs() % 100000 + 200000;
    await _plugin.cancel(id);
    await _plugin.cancel(id + 1);
  }

  // ─── Notification immédiate (test / confirmation) ─────────────────────────
  Future<void> afficherNotification({
    required String titre,
    required String corps,
    String channel = _channelEmprunts,
  }) async {
    if (!_initialized || kIsWeb) return;
    final label = channel == channelFcm ? 'Notifications BiblioX' : channel;
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      titre, corps,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel, label,
          importance: Importance.high, priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  // ─── Notification de nouveau message ─────────────────────────────────────
  Future<void> afficherNotificationMessage({
    required String expediteurNom,
    required String contenu,
    String? conversationId,
  }) async {
    if (!_initialized || kIsWeb) return;
    try {
      final id = conversationId?.hashCode.abs() ?? DateTime.now().millisecondsSinceEpoch;
      await _plugin.show(
        id % 100000 + 300000, // Offset pour éviter les conflits avec autres notifs
        '💬 $expediteurNom',
        contenu.length > 100 ? '${contenu.substring(0, 100)}...' : contenu,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelMessages, 'Messages privés',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(contenu),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Erreur notification message: $e');
    }
  }
}
