import 'package:cloud_firestore/cloud_firestore.dart';

class ClubLecture {
  final String id;
  final String nom;
  final String description;
  final String livreId;
  final String livreTitre;
  final String livreAuteur;
  final String livreCouverture;
  final String createurId;
  final String createurNom;
  final List<String> membresIds;
  final DateTime dateCreation;
  final DateTime? dateLecture; // Date prévue de discussion
  final bool estPublic;

  ClubLecture({
    required this.id,
    required this.nom,
    required this.description,
    required this.livreId,
    required this.livreTitre,
    required this.livreAuteur,
    this.livreCouverture = '',
    required this.createurId,
    required this.createurNom,
    required this.membresIds,
    required this.dateCreation,
    this.dateLecture,
    this.estPublic = true,
  });

  int get nbMembres => membresIds.length;
  bool estMembre(String uid) => membresIds.contains(uid);

  factory ClubLecture.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ClubLecture(
      id: doc.id,
      nom: d['nom'] ?? '',
      description: d['description'] ?? '',
      livreId: d['livreId'] ?? '',
      livreTitre: d['livreTitre'] ?? '',
      livreAuteur: d['livreAuteur'] ?? '',
      livreCouverture: d['livreCouverture'] ?? '',
      createurId: d['createurId'] ?? '',
      createurNom: d['createurNom'] ?? '',
      membresIds: List<String>.from(d['membresIds'] ?? []),
      dateCreation: (d['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateLecture: (d['dateLecture'] as Timestamp?)?.toDate(),
      estPublic: d['estPublic'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'nom': nom,
    'description': description,
    'livreId': livreId,
    'livreTitre': livreTitre,
    'livreAuteur': livreAuteur,
    'livreCouverture': livreCouverture,
    'createurId': createurId,
    'createurNom': createurNom,
    'membresIds': membresIds,
    'dateCreation': Timestamp.fromDate(dateCreation),
    'dateLecture': dateLecture != null ? Timestamp.fromDate(dateLecture!) : null,
    'estPublic': estPublic,
  };
}
