import 'package:cloud_firestore/cloud_firestore.dart';

enum StatutMembre { actif, suspendu, enAttente }
enum RoleMembre { visiteur, membre, admin }

class Membre {
  final String uid;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final DateTime dateAdhesion;
  final List<String> genresPreferes;
  final int nbEmpruntsEnCours;
  final int nbEmpruntsTotal;
  final StatutMembre statut;
  final RoleMembre role;
  final String photoUrl;
  final List<String> wishlist;

  Membre({
    required this.uid,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone = '',
    required this.dateAdhesion,
    this.genresPreferes = const [],
    this.nbEmpruntsEnCours = 0,
    this.nbEmpruntsTotal = 0,
    this.statut = StatutMembre.actif,
    this.role = RoleMembre.membre,
    this.photoUrl = '',
    this.wishlist = const [],
  });

  bool get estAdmin => role == RoleMembre.admin;
  bool get estActif => statut == StatutMembre.actif;
  String get nomComplet => '$prenom $nom';

  factory Membre.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Membre(
      uid: doc.id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      telephone: data['telephone'] ?? '',
      dateAdhesion:
          (data['dateAdhesion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      genresPreferes: List<String>.from(data['genresPreferes'] ?? []),
      nbEmpruntsEnCours: data['nbEmpruntsEnCours'] ?? 0,
      nbEmpruntsTotal: data['nbEmpruntsTotal'] ?? 0,
      statut: StatutMembre.values.firstWhere(
        (e) => e.name == (data['statut'] ?? 'actif'),
        orElse: () => StatutMembre.actif,
      ),
      role: RoleMembre.values.firstWhere(
        (e) => e.name == (data['role'] ?? 'membre'),
        orElse: () => RoleMembre.membre,
      ),
      photoUrl: data['photoUrl'] ?? '',
      wishlist: List<String>.from(data['wishlist'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'dateAdhesion': Timestamp.fromDate(dateAdhesion),
      'genresPreferes': genresPreferes,
      'nbEmpruntsEnCours': nbEmpruntsEnCours,
      'nbEmpruntsTotal': nbEmpruntsTotal,
      'statut': statut.name,
      'role': role.name,
      'photoUrl': photoUrl,
      'wishlist': wishlist,
    };
  }

  Membre copyWith({
    String? nom,
    String? prenom,
    String? telephone,
    List<String>? genresPreferes,
    int? nbEmpruntsEnCours,
    int? nbEmpruntsTotal,
    StatutMembre? statut,
    RoleMembre? role,
    String? photoUrl,
    List<String>? wishlist,
  }) {
    return Membre(
      uid: uid,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email,
      telephone: telephone ?? this.telephone,
      dateAdhesion: dateAdhesion,
      genresPreferes: genresPreferes ?? this.genresPreferes,
      nbEmpruntsEnCours: nbEmpruntsEnCours ?? this.nbEmpruntsEnCours,
      nbEmpruntsTotal: nbEmpruntsTotal ?? this.nbEmpruntsTotal,
      statut: statut ?? this.statut,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      wishlist: wishlist ?? this.wishlist,
    );
  }
}