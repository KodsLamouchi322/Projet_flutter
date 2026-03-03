import 'package:cloud_firestore/cloud_firestore.dart';

enum StatutLivre { disponible, emprunte, reserve, endommage }

class Livre {
  final String id;
  final String titre;
  final String auteur;
  final String isbn;
  final String genre;
  final String resume;
  final String couvertureUrl;
  final int anneePublication;
  final String editeur;
  final StatutLivre statut;
  final double noteMoyenne;
  final int nbAvis;
  final List<String> tags;
  final DateTime dateAjout;
  final int nbEmpruntsTotal;

  Livre({
    required this.id,
    required this.titre,
    required this.auteur,
    this.isbn = '',
    this.genre = '',
    this.resume = '',
    this.couvertureUrl = '',
    this.anneePublication = 0,
    this.editeur = '',
    this.statut = StatutLivre.disponible,
    this.noteMoyenne = 0.0,
    this.nbAvis = 0,
    this.tags = const [],
    required this.dateAjout,
    this.nbEmpruntsTotal = 0,
  });

  bool get estDisponible => statut == StatutLivre.disponible;

  String get statutLabel {
    switch (statut) {
      case StatutLivre.disponible:
        return 'Disponible';
      case StatutLivre.emprunte:
        return 'Emprunté';
      case StatutLivre.reserve:
        return 'Réservé';
      case StatutLivre.endommage:
        return 'Endommagé';
    }
  }

  factory Livre.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Livre(
      id: doc.id,
      titre: data['titre'] ?? '',
      auteur: data['auteur'] ?? '',
      isbn: data['isbn'] ?? '',
      genre: data['genre'] ?? '',
      resume: data['resume'] ?? '',
      couvertureUrl: data['couvertureUrl'] ?? '',
      anneePublication: data['anneePublication'] ?? 0,
      editeur: data['editeur'] ?? '',
      statut: StatutLivre.values.firstWhere(
        (e) => e.name == (data['statut'] ?? 'disponible'),
        orElse: () => StatutLivre.disponible,
      ),
      noteMoyenne: (data['noteMoyenne'] ?? 0.0).toDouble(),
      nbAvis: data['nbAvis'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      dateAjout:
          (data['dateAjout'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nbEmpruntsTotal: data['nbEmpruntsTotal'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titre': titre,
      'auteur': auteur,
      'isbn': isbn,
      'genre': genre,
      'resume': resume,
      'couvertureUrl': couvertureUrl,
      'anneePublication': anneePublication,
      'editeur': editeur,
      'statut': statut.name,
      'noteMoyenne': noteMoyenne,
      'nbAvis': nbAvis,
      'tags': tags,
      'dateAjout': Timestamp.fromDate(dateAjout),
      'nbEmpruntsTotal': nbEmpruntsTotal,
    };
  }

  Livre copyWith({
    String? titre,
    String? auteur,
    String? isbn,
    String? genre,
    String? resume,
    String? couvertureUrl,
    int? anneePublication,
    String? editeur,
    StatutLivre? statut,
    double? noteMoyenne,
    int? nbAvis,
    List<String>? tags,
    int? nbEmpruntsTotal,
  }) {
    return Livre(
      id: id,
      titre: titre ?? this.titre,
      auteur: auteur ?? this.auteur,
      isbn: isbn ?? this.isbn,
      genre: genre ?? this.genre,
      resume: resume ?? this.resume,
      couvertureUrl: couvertureUrl ?? this.couvertureUrl,
      anneePublication: anneePublication ?? this.anneePublication,
      editeur: editeur ?? this.editeur,
      statut: statut ?? this.statut,
      noteMoyenne: noteMoyenne ?? this.noteMoyenne,
      nbAvis: nbAvis ?? this.nbAvis,
      tags: tags ?? this.tags,
      dateAjout: dateAjout,
      nbEmpruntsTotal: nbEmpruntsTotal ?? this.nbEmpruntsTotal,
    );
  }
}