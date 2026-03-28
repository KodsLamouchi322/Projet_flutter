import 'package:cloud_firestore/cloud_firestore.dart';

/// Défi de lecture mensuel pour un club
class DefiLecture {
  final String id;
  final String clubId;
  final String titre;
  final String description;
  final String type; // 'nombre_livres', 'genre', 'pages', 'auteur'
  final int objectif; // ex: 3 livres, 500 pages
  final String? genreCible; // si type = 'genre'
  final DateTime dateDebut;
  final DateTime dateFin;
  final Map<String, int> progressionParMembre; // membreId -> progression
  final List<String> participantsIds;

  DefiLecture({
    required this.id,
    required this.clubId,
    required this.titre,
    required this.description,
    required this.type,
    required this.objectif,
    this.genreCible,
    required this.dateDebut,
    required this.dateFin,
    this.progressionParMembre = const {},
    this.participantsIds = const [],
  });

  int get nbParticipants => participantsIds.length;
  bool estParticipant(String uid) => participantsIds.contains(uid);
  int getProgression(String uid) => progressionParMembre[uid] ?? 0;
  bool estTermine() => DateTime.now().isAfter(dateFin);
  bool estEnCours() =>
      DateTime.now().isAfter(dateDebut) && DateTime.now().isBefore(dateFin);

  double getPourcentageProgression(String uid) {
    final prog = getProgression(uid);
    return objectif > 0 ? (prog / objectif * 100).clamp(0, 100) : 0;
  }

  factory DefiLecture.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DefiLecture(
      id: doc.id,
      clubId: d['clubId'] ?? '',
      titre: d['titre'] ?? '',
      description: d['description'] ?? '',
      type: d['type'] ?? 'nombre_livres',
      objectif: d['objectif'] ?? 0,
      genreCible: d['genreCible'],
      dateDebut: (d['dateDebut'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateFin: (d['dateFin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      progressionParMembre:
          Map<String, int>.from(d['progressionParMembre'] ?? {}),
      participantsIds: List<String>.from(d['participantsIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'clubId': clubId,
        'titre': titre,
        'description': description,
        'type': type,
        'objectif': objectif,
        'genreCible': genreCible,
        'dateDebut': Timestamp.fromDate(dateDebut),
        'dateFin': Timestamp.fromDate(dateFin),
        'progressionParMembre': progressionParMembre,
        'participantsIds': participantsIds,
      };
}
