// lib/models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { emprunt, reservation, evenement, message, rappel }

class NotificationModel {
  final String id;
  final String membreId;
  final String titre;
  final String corps;
  final NotificationType type;
  final bool lu;
  final DateTime creeLe;
  final String? lienId;

  NotificationModel({
    required this.id,
    required this.membreId,
    required this.titre,
    required this.corps,
    required this.type,
    this.lu = false,
    required this.creeLe,
    this.lienId,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      membreId: data['membreId'] ?? '',
      titre: data['titre'] ?? '',
      corps: data['corps'] ?? '',
      type: NotificationType.values.firstWhere(
          (e) => e.name == data['type'], orElse: () => NotificationType.rappel),
      lu: data['lu'] ?? false,
      creeLe: (data['creeLe'] as Timestamp).toDate(),
      lienId: data['lienId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'membreId': membreId,
    'titre': titre,
    'corps': corps,
    'type': type.name,
    'lu': lu,
    'creeLe': Timestamp.fromDate(creeLe),
    'lienId': lienId,
  };
}
