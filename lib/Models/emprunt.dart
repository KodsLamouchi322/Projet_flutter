import 'package:cloud_firestore/cloud_firestore.dart';

enum StatutEmprunt { enCours, retourne, enRetard, prolonge }

class Emprunt {
  final String id;
  final String membreId;
  final String livreId;
  final String livreTitre;
  final String livreAuteur;
  final String livreCouverture;
  final DateTime dateEmprunt;
  final DateTime dateRetourPrevue;
  final DateTime? dateRetourEffective;
  final StatutEmprunt statut;
  final bool prolongationDemandee;
  final String? notes;

  Emprunt({
    required this.id,
    required this.membreId,
    required this.livreId,
    required this.livreTitre,
    required this.livreAuteur,
    this.livreCouverture = '',
    required this.dateEmprunt,
    required this.dateRetourPrevue,
    this.dateRetourEffective,
    this.statut = StatutEmprunt.enCours,
    this.prolongationDemandee = false,
    this.notes,
  });

  bool get estEnRetard =>
      statut == StatutEmprunt.enCours &&
      DateTime.now().isAfter(dateRetourPrevue);

  int get joursRestants =>
      dateRetourPrevue.difference(DateTime.now()).inDays;

  factory Emprunt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Emprunt(
      id: doc.id,
      membreId: data['membreId'] ?? '',
      livreId: data['livreId'] ?? '',
      livreTitre: data['livreTitre'] ?? '',
      livreAuteur: data['livreAuteur'] ?? '',
      livreCouverture: data['livreCouverture'] ?? '',
      dateEmprunt: (data['dateEmprunt'] as Timestamp).toDate(),
      dateRetourPrevue: (data['dateRetourPrevue'] as Timestamp).toDate(),
      dateRetourEffective:
          (data['dateRetourEffective'] as Timestamp?)?.toDate(),
      statut: StatutEmprunt.values.firstWhere(
        (e) => e.name == (data['statut'] ?? 'enCours'),
        orElse: () => StatutEmprunt.enCours,
      ),
      prolongationDemandee: data['prolongationDemandee'] ?? false,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'membreId': membreId,
      'livreId': livreId,
      'livreTitre': livreTitre,
      'livreAuteur': livreAuteur,
      'livreCouverture': livreCouverture,
      'dateEmprunt': Timestamp.fromDate(dateEmprunt),
      'dateRetourPrevue': Timestamp.fromDate(dateRetourPrevue),
      'dateRetourEffective': dateRetourEffective != null
          ? Timestamp.fromDate(dateRetourEffective!)
          : null,
      'statut': statut.name,
      'prolongationDemandee': prolongationDemandee,
      'notes': notes,
    };
  }
}