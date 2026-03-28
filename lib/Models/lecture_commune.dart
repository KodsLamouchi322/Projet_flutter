import 'package:cloud_firestore/cloud_firestore.dart';

/// Lecture commune organisée par un club
class LectureCommune {
  final String id;
  final String clubId;
  final String livreId;
  final String livreTitre;
  final String livreAuteur;
  final String livreCouverture;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String statut; // 'en_cours', 'terminee', 'planifiee'
  final List<String> participantsIds;
  final Map<String, int> progressionParMembre; // membreId -> pourcentage
  final int nbChapitres;
  final Map<String, DateTime> discussionsParChapitre; // chapitre -> date discussion

  LectureCommune({
    required this.id,
    required this.clubId,
    required this.livreId,
    required this.livreTitre,
    required this.livreAuteur,
    this.livreCouverture = '',
    required this.dateDebut,
    required this.dateFin,
    this.statut = 'planifiee',
    this.participantsIds = const [],
    this.progressionParMembre = const {},
    this.nbChapitres = 0,
    this.discussionsParChapitre = const {},
  });

  int get nbParticipants => participantsIds.length;
  bool estParticipant(String uid) => participantsIds.contains(uid);
  int getProgression(String uid) => progressionParMembre[uid] ?? 0;

  factory LectureCommune.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LectureCommune(
      id: doc.id,
      clubId: d['clubId'] ?? '',
      livreId: d['livreId'] ?? '',
      livreTitre: d['livreTitre'] ?? '',
      livreAuteur: d['livreAuteur'] ?? '',
      livreCouverture: d['livreCouverture'] ?? '',
      dateDebut: (d['dateDebut'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateFin: (d['dateFin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statut: d['statut'] ?? 'planifiee',
      participantsIds: List<String>.from(d['participantsIds'] ?? []),
      progressionParMembre: Map<String, int>.from(d['progressionParMembre'] ?? {}),
      nbChapitres: d['nbChapitres'] ?? 0,
      discussionsParChapitre: (d['discussionsParChapitre'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as Timestamp).toDate())) ??
          {},
    );
  }

  Map<String, dynamic> toFirestore() => {
        'clubId': clubId,
        'livreId': livreId,
        'livreTitre': livreTitre,
        'livreAuteur': livreAuteur,
        'livreCouverture': livreCouverture,
        'dateDebut': Timestamp.fromDate(dateDebut),
        'dateFin': Timestamp.fromDate(dateFin),
        'statut': statut,
        'participantsIds': participantsIds,
        'progressionParMembre': progressionParMembre,
        'nbChapitres': nbChapitres,
        'discussionsParChapitre': discussionsParChapitre
            .map((k, v) => MapEntry(k, Timestamp.fromDate(v))),
      };
}
