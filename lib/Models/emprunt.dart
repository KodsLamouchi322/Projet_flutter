import 'package:cloud_firestore/cloud_firestore.dart';

enum StatutEmprunt { enCours, retourne, enRetard, prolonge, enAttenteRetour }

class Emprunt {
  final String id;
  final String membreId;
  final String membreNom;
  final String livreId;
  final String livreTitre;
  final String livreAuteur;
  final String livreCouverture;
  final DateTime dateEmprunt;
  final DateTime dateRetourPrevue;
  final DateTime? dateRetourEffective;
  final StatutEmprunt statut;
  final int prolongations;
  final String? notes;
  final bool prolongationAutorisee; // Admin doit autoriser avant que le membre puisse prolonger

  Emprunt({
    required this.id,
    required this.membreId,
    this.membreNom = '',
    required this.livreId,
    required this.livreTitre,
    required this.livreAuteur,
    this.livreCouverture = '',
    required this.dateEmprunt,
    required this.dateRetourPrevue,
    this.dateRetourEffective,
    this.statut = StatutEmprunt.enCours,
    this.prolongations = 0,
    this.notes,
    this.prolongationAutorisee = false,
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
      membreNom: data['membreNom'] ?? '',
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
      prolongations: data['prolongations'] ?? 0,
      notes: data['notes'],
      prolongationAutorisee: data['prolongationAutorisee'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'membreId': membreId,
      'membreNom': membreNom,
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
      'prolongations': prolongations,
      'notes': notes,
      'prolongationAutorisee': prolongationAutorisee,
    };
  }

  Emprunt copyWith({
    String? id,
    String? membreId,
    String? membreNom,
    String? livreId,
    String? livreTitre,
    String? livreAuteur,
    String? livreCouverture,
    DateTime? dateEmprunt,
    DateTime? dateRetourPrevue,
    DateTime? dateRetourEffective,
    StatutEmprunt? statut,
    int? prolongations,
    String? notes,
    bool? prolongationAutorisee,
  }) {
    return Emprunt(
      id: id ?? this.id,
      membreId: membreId ?? this.membreId,
      membreNom: membreNom ?? this.membreNom,
      livreId: livreId ?? this.livreId,
      livreTitre: livreTitre ?? this.livreTitre,
      livreAuteur: livreAuteur ?? this.livreAuteur,
      livreCouverture: livreCouverture ?? this.livreCouverture,
      dateEmprunt: dateEmprunt ?? this.dateEmprunt,
      dateRetourPrevue: dateRetourPrevue ?? this.dateRetourPrevue,
      dateRetourEffective: dateRetourEffective ?? this.dateRetourEffective,
      statut: statut ?? this.statut,
      prolongations: prolongations ?? this.prolongations,
      notes: notes ?? this.notes,
      prolongationAutorisee: prolongationAutorisee ?? this.prolongationAutorisee,
    );
  }
}// Fix: null safety improvements - updated return types and null checks
// lib/models/emprunt.dart - v2
