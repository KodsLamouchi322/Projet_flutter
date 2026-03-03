import 'package:cloud_firestore/cloud_firestore.dart';

enum StatutReservation { enAttente, confirmee, annulee, expiree }

class Reservation {
  final String id;
  final String membreId;
  final String livreId;
  final String livreTitre;
  final String livreAuteur;
  final String livreCouverture;
  final DateTime dateReservation;
  final DateTime dateExpiration;
  final StatutReservation statut;
  final int positionFile; // Position dans la file d'attente

  Reservation({
    required this.id,
    required this.membreId,
    required this.livreId,
    required this.livreTitre,
    required this.livreAuteur,
    this.livreCouverture = '',
    required this.dateReservation,
    required this.dateExpiration,
    this.statut = StatutReservation.enAttente,
    this.positionFile = 1,
  });

  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reservation(
      id: doc.id,
      membreId: data['membreId'] ?? '',
      livreId: data['livreId'] ?? '',
      livreTitre: data['livreTitre'] ?? '',
      livreAuteur: data['livreAuteur'] ?? '',
      livreCouverture: data['livreCouverture'] ?? '',
      dateReservation: (data['dateReservation'] as Timestamp).toDate(),
      dateExpiration: (data['dateExpiration'] as Timestamp).toDate(),
      statut: StatutReservation.values.firstWhere(
        (e) => e.name == (data['statut'] ?? 'enAttente'),
        orElse: () => StatutReservation.enAttente,
      ),
      positionFile: data['positionFile'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'membreId': membreId,
      'livreId': livreId,
      'livreTitre': livreTitre,
      'livreAuteur': livreAuteur,
      'livreCouverture': livreCouverture,
      'dateReservation': Timestamp.fromDate(dateReservation),
      'dateExpiration': Timestamp.fromDate(dateExpiration),
      'statut': statut.name,
      'positionFile': positionFile,
    };
  }
}