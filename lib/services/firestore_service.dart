import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/livre.dart';
import '../utils/constants.dart';

/// Service Firestore pour la gestion du catalogue
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────────────────────
  // LIVRES
  // ─────────────────────────────────────────────────────────────────────────

  CollectionReference get _livresRef =>
      _db.collection(AppConstants.colLivres);

  /// Stream de tous les livres (catalogue complet)
  Stream<List<Livre>> livresStream() {
    return _livresRef
        .orderBy('dateAjout', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Livre.fromFirestore(d)).toList());
  }

  /// Stream des livres disponibles uniquement (pour visiteurs)
  Stream<List<Livre>> livresDisponiblesStream() {
    return _livresRef
        .where('statut', isEqualTo: 'disponible')
        .orderBy('dateAjout', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Livre.fromFirestore(d)).toList());
  }

  /// Récupérer un livre par ID
  Future<Livre?> getLivre(String id) async {
    final doc = await _livresRef.doc(id).get();
    if (!doc.exists) return null;
    return Livre.fromFirestore(doc);
  }

  /// Ajouter un livre (admin)
  Future<String> ajouterLivre(Livre livre) async {
    final data = livre.toFirestore();
    final doc = await _livresRef.add(data);
    return doc.id;
  }

  /// Modifier un livre (admin)
  Future<void> modifierLivre(String id, Map<String, dynamic> data) async {
    await _livresRef.doc(id).update(data);
  }

  /// Supprimer un livre (admin)
  Future<void> supprimerLivre(String id) async {
    await _livresRef.doc(id).delete();
  }

  /// Changer le statut d'un livre
  Future<void> changerStatutLivre(String id, StatutLivre statut) async {
    await _livresRef.doc(id).update({'statut': statut.name});
  }

  /// Recherche dans le catalogue (titre, auteur, isbn)
  Future<List<Livre>> rechercherLivres(String query) async {
    final queryLower = query.toLowerCase().trim();

    // Firestore ne supporte pas LIKE, on filtre côté client
    final snap = await _livresRef.get();
    return snap.docs
        .map((d) => Livre.fromFirestore(d))
        .where((l) =>
            l.titre.toLowerCase().contains(queryLower) ||
            l.auteur.toLowerCase().contains(queryLower) ||
            l.isbn.toLowerCase().contains(queryLower) ||
            l.genre.toLowerCase().contains(queryLower))
        .toList();
  }

  /// Filtrer par genre
  Stream<List<Livre>> livresParGenreStream(String genre) {
    return _livresRef
        .where('genre', isEqualTo: genre)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Livre.fromFirestore(d)).toList());
  }

  /// Livres les plus empruntés (populaires)
  Stream<List<Livre>> livresPopulairesStream({int limit = 10}) {
    return _livresRef
        .orderBy('nbEmpruntsTotal', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Livre.fromFirestore(d)).toList());
  }

  /// Nouveautés
  Stream<List<Livre>> nouveautesStream({int limit = 10}) {
    return _livresRef
        .orderBy('dateAjout', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Livre.fromFirestore(d)).toList());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MEMBRES
  // ─────────────────────────────────────────────────────────────────────────

  CollectionReference get _membresRef =>
      _db.collection(AppConstants.colMembres);

  /// Tous les membres (admin)
  Stream<List<Map<String, dynamic>>> membresStream() {
    return _membresRef.snapshots().map(
          (snap) => snap.docs
              .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
              .toList(),
        );
  }

  /// Mettre à jour la wishlist d'un membre
  Future<void> toggleWishlist(String uid, String livreId) async {
    final doc = await _membresRef.doc(uid).get();
    final data = doc.data() as Map<String, dynamic>;
    final wishlist = List<String>.from(data['wishlist'] ?? []);

    if (wishlist.contains(livreId)) {
      wishlist.remove(livreId);
    } else {
      wishlist.add(livreId);
    }

    await _membresRef.doc(uid).update({'wishlist': wishlist});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATISTIQUES ADMIN
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, int>> getStatsGenerales() async {
    final livres = await _livresRef.get();
    final membres = await _membresRef.get();
    final emprunts = await _db.collection(AppConstants.colEmprunts).get();

    final livresDisponibles = livres.docs
        .where((d) =>
            (d.data() as Map<String, dynamic>)['statut'] == 'disponible')
        .length;

    final empruntsEnCours = emprunts.docs
        .where((d) =>
            (d.data() as Map<String, dynamic>)['statut'] == 'enCours')
        .length;

    return {
      'totalLivres': livres.size,
      'livresDisponibles': livresDisponibles,
      'totalMembres': membres.size,
      'empruntsEnCours': empruntsEnCours,
    };
  }
}
