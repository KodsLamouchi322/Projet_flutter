import 'package:cloud_firestore/cloud_firestore.dart';

/// Vote pour choisir le prochain livre à lire en commun
class VoteLivre {
  final String id;
  final String clubId;
  final String livreId;
  final String livreTitre;
  final String livreAuteur;
  final String livreCouverture;
  final String proposePar;
  final String proposeParNom;
  final DateTime dateProposition;
  final List<String> votantsIds;

  VoteLivre({
    required this.id,
    required this.clubId,
    required this.livreId,
    required this.livreTitre,
    required this.livreAuteur,
    this.livreCouverture = '',
    required this.proposePar,
    required this.proposeParNom,
    required this.dateProposition,
    this.votantsIds = const [],
  });

  int get nbVotes => votantsIds.length;
  bool aVote(String uid) => votantsIds.contains(uid);

  factory VoteLivre.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VoteLivre(
      id: doc.id,
      clubId: d['clubId'] ?? '',
      livreId: d['livreId'] ?? '',
      livreTitre: d['livreTitre'] ?? '',
      livreAuteur: d['livreAuteur'] ?? '',
      livreCouverture: d['livreCouverture'] ?? '',
      proposePar: d['proposePar'] ?? '',
      proposeParNom: d['proposeParNom'] ?? '',
      dateProposition: (d['dateProposition'] as Timestamp?)?.toDate() ?? DateTime.now(),
      votantsIds: List<String>.from(d['votantsIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'clubId': clubId,
        'livreId': livreId,
        'livreTitre': livreTitre,
        'livreAuteur': livreAuteur,
        'livreCouverture': livreCouverture,
        'proposePar': proposePar,
        'proposeParNom': proposeParNom,
        'dateProposition': Timestamp.fromDate(dateProposition),
        'votantsIds': votantsIds,
      };
}
