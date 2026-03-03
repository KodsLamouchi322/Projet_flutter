import 'package:cloud_firestore/cloud_firestore.dart';

enum StatutEvenement { aVenir, enCours, termine, annule }

class Evenement {
  final String id;
  final String titre;
  final String description;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String lieu;
  final int capaciteMax;
  final List<String> participantsIds;
  final String organisateurId;
  final String? imageUrl;
  final String categorie;
  final bool estPublic;
  final DateTime createdAt;

  Evenement({
    required this.id,
    required this.titre,
    required this.description,
    required this.dateDebut,
    required this.dateFin,
    required this.lieu,
    required this.capaciteMax,
    required this.participantsIds,
    required this.organisateurId,
    this.imageUrl,
    required this.categorie,
    required this.estPublic,
    required this.createdAt,
  });

  // Calculer le statut depuis les dates
  StatutEvenement get statut {
    final now = DateTime.now();
    if (dateDebut.isAfter(now)) return StatutEvenement.aVenir;
    if (dateFin.isAfter(now)) return StatutEvenement.enCours;
    return StatutEvenement.termine;
  }

  int get placesRestantes => capaciteMax - participantsIds.length;
  bool get estComplet => participantsIds.length >= capaciteMax;
  bool get aDesPlaces => placesRestantes > 0;

  bool estParticipant(String uid) => participantsIds.contains(uid);

  factory Evenement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Evenement(
      id: doc.id,
      titre: data['titre'] ?? '',
      description: data['description'] ?? '',
      dateDebut: (data['dateDebut'] as Timestamp).toDate(),
      dateFin: (data['dateFin'] as Timestamp).toDate(),
      lieu: data['lieu'] ?? '',
      capaciteMax: data['capaciteMax'] ?? 0,
      participantsIds: List<String>.from(data['participantsIds'] ?? []),
      organisateurId: data['organisateurId'] ?? '',
      imageUrl: data['imageUrl'],
      categorie: data['categorie'] ?? 'Autre',
      estPublic: data['estPublic'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titre': titre,
      'description': description,
      'dateDebut': Timestamp.fromDate(dateDebut),
      'dateFin': Timestamp.fromDate(dateFin),
      'lieu': lieu,
      'capaciteMax': capaciteMax,
      'participantsIds': participantsIds,
      'organisateurId': organisateurId,
      'imageUrl': imageUrl,
      'categorie': categorie,
      'estPublic': estPublic,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Evenement copyWith({
    String? id,
    String? titre,
    String? description,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? lieu,
    int? capaciteMax,
    List<String>? participantsIds,
    String? organisateurId,
    String? imageUrl,
    String? categorie,
    bool? estPublic,
    DateTime? createdAt,
  }) {
    return Evenement(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      lieu: lieu ?? this.lieu,
      capaciteMax: capaciteMax ?? this.capaciteMax,
      participantsIds: participantsIds ?? this.participantsIds,
      organisateurId: organisateurId ?? this.organisateurId,
      imageUrl: imageUrl ?? this.imageUrl,
      categorie: categorie ?? this.categorie,
      estPublic: estPublic ?? this.estPublic,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const List<String> categories = [
    'Club de lecture',
    'Atelier écriture',
    'Conférence',
    'Exposition',
    'Jeunesse',
    'Cinéma',
    'Musique',
    'Autre',
  ];
}
