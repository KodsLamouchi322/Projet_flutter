import 'package:cloud_firestore/cloud_firestore.dart';

/// Livre dans la bibliothèque partagée d'un club
class LivreClub {
  final String id;
  final String clubId;
  final String livreId;
  final String livreTitre;
  final String livreAuteur;
  final String livreCouverture;
  final String ajoutePar;
  final String ajouteParNom;
  final DateTime dateAjout;
  final double noteClub; // Note moyenne du club
  final int nbNotations;
  final List<String> tags; // ex: 'recommandé', 'coup_de_coeur', 'à_lire'
  final String? commentaireClub; // Commentaire collectif

  LivreClub({
    required this.id,
    required this.clubId,
    required this.livreId,
    required this.livreTitre,
    required this.livreAuteur,
    this.livreCouverture = '',
    required this.ajoutePar,
    required this.ajouteParNom,
    required this.dateAjout,
    this.noteClub = 0.0,
    this.nbNotations = 0,
    this.tags = const [],
    this.commentaireClub,
  });

  bool aTag(String tag) => tags.contains(tag);

  factory LivreClub.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LivreClub(
      id: doc.id,
      clubId: d['clubId'] ?? '',
      livreId: d['livreId'] ?? '',
      livreTitre: d['livreTitre'] ?? '',
      livreAuteur: d['livreAuteur'] ?? '',
      livreCouverture: d['livreCouverture'] ?? '',
      ajoutePar: d['ajoutePar'] ?? '',
      ajouteParNom: d['ajouteParNom'] ?? '',
      dateAjout: (d['dateAjout'] as Timestamp?)?.toDate() ?? DateTime.now(),
      noteClub: (d['noteClub'] ?? 0.0).toDouble(),
      nbNotations: d['nbNotations'] ?? 0,
      tags: List<String>.from(d['tags'] ?? []),
      commentaireClub: d['commentaireClub'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'clubId': clubId,
        'livreId': livreId,
        'livreTitre': livreTitre,
        'livreAuteur': livreAuteur,
        'livreCouverture': livreCouverture,
        'ajoutePar': ajoutePar,
        'ajouteParNom': ajouteParNom,
        'dateAjout': Timestamp.fromDate(dateAjout),
        'noteClub': noteClub,
        'nbNotations': nbNotations,
        'tags': tags,
        'commentaireClub': commentaireClub,
      };
}
