import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/livre.dart';
import '../models/membre.dart';
import '../models/emprunt.dart';
import '../models/reservation.dart';
import '../models/evenement.dart';
import '../utils/constants.dart';

/// Service centralisé pour toutes les opérations Firestore
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ══════════════════════════════════════════════════════════════════
  // LIVRES
  // ══════════════════════════════════════════════════════════════════

  /// Stream de tous les livres disponibles
  Stream<List<Livre>> streamLivres({
    String? genre,
    bool? disponible,
    String? recherche,
  }) {
    Query query = _db.collection(AppConstants.colLivres);
    if (genre != null && genre.isNotEmpty) {
      query = query.where('genre', isEqualTo: genre);
    }
    if (disponible != null) {
      query = query.where('estDisponible', isEqualTo: disponible);
    }
    return query
        .orderBy('titre')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Livre.fromFirestore(d)).toList());
  }

  /// Alias utilisé par LivreController - tous les livres
  Stream<List<Livre>> livresStream() {
    return _db
        .collection(AppConstants.colLivres)
        .orderBy('titre')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Livre.fromFirestore(d)).toList());
  }

  /// Alias utilisé par LivreController - livres disponibles uniquement
  Stream<List<Livre>> livresDisponiblesStream() {
    return _db
        .collection(AppConstants.colLivres)
        .where('statut', isEqualTo: 'disponible')
        .orderBy('titre')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Livre.fromFirestore(d)).toList());
  }

  /// Récupérer un livre par ID
  Future<Livre?> getLivre(String livreId) async {
    final doc =
        await _db.collection(AppConstants.colLivres).doc(livreId).get();
    if (!doc.exists) return null;
    return Livre.fromFirestore(doc);
  }

  /// Ajouter un livre
  Future<String> ajouterLivre(Livre livre) async {
    final docRef = await _db
        .collection(AppConstants.colLivres)
        .add(livre.toFirestore());
    return docRef.id;
  }

  /// Modifier un livre
  Future<void> modifierLivre(String livreId, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.colLivres).doc(livreId).update(data);
  }

  /// Supprimer un livre
  Future<void> supprimerLivre(String livreId) async {
    await _db.collection(AppConstants.colLivres).doc(livreId).delete();
  }

  /// Recherche textuelle (titre, auteur, ISBN)
  Future<List<Livre>> rechercherLivres(String query) async {
    final queryLower = query.toLowerCase();
    final snapshot =
        await _db.collection(AppConstants.colLivres).get();
    return snapshot.docs
        .map((d) => Livre.fromFirestore(d))
        .where((l) =>
            l.titre.toLowerCase().contains(queryLower) ||
            l.auteur.toLowerCase().contains(queryLower) ||
            l.isbn.contains(query) ||
            l.genre.toLowerCase().contains(queryLower))
        .toList();
  }

  /// Livres les plus empruntés (top)
  Future<List<Livre>> getLivresPopulaires({int limit = 10}) async {
    final snap = await _db
        .collection(AppConstants.colLivres)
        .orderBy('nbEmprunts', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => Livre.fromFirestore(d)).toList();
  }

  /// Dernières nouveautés
  Future<List<Livre>> getNouveautes({int limit = 10}) async {
    final snap = await _db
        .collection(AppConstants.colLivres)
        .orderBy('dateAjout', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => Livre.fromFirestore(d)).toList();
  }

  /// Ajouter un avis sur un livre
  Future<void> ajouterAvis({
    required String livreId,
    required String membreId,
    required String membreNom,
    required double note,
    required String commentaire,
  }) async {
    final docRef = _db.collection(AppConstants.colLivres).doc(livreId);
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      final data = doc.data() as Map<String, dynamic>;
      final List<Map<String, dynamic>> avis =
          List<Map<String, dynamic>>.from(data['avis'] ?? []);

      // Supprimer l'ancien avis du même membre si existant
      avis.removeWhere((a) => a['membreId'] == membreId);
      avis.add({
        'membreId': membreId,
        'membreNom': membreNom,
        'note': note,
        'commentaire': commentaire,
        'date': Timestamp.fromDate(DateTime.now()),
      });

      // Recalculer la note moyenne
      final avgNote =
          avis.fold<double>(0, (s, a) => s + (a['note'] as num)) /
              avis.length;

      transaction.update(docRef, {
        'avis': avis,
        'noteMoyenne': avgNote,
        'nbAvis': avis.length,
      });
    });
  }

  // ══════════════════════════════════════════════════════════════════
  // MEMBRES
  // ══════════════════════════════════════════════════════════════════

  /// Récupérer un membre
  Future<Membre?> getMembre(String uid) async {
    final doc = await _db.collection(AppConstants.colMembres).doc(uid).get();
    if (!doc.exists) return null;
    return Membre.fromFirestore(doc);
  }

  /// Stream d'un membre (temps réel)
  Stream<Membre?> streamMembre(String uid) {
    return _db
        .collection(AppConstants.colMembres)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? Membre.fromFirestore(doc) : null);
  }

  /// Tous les membres (admin)
  Future<List<Membre>> getTousMembres() async {
    final snap = await _db
        .collection(AppConstants.colMembres)
        .orderBy('nom')
        .get();
    return snap.docs.map((d) => Membre.fromFirestore(d)).toList();
  }

  /// Mettre à jour le profil d'un membre
  Future<void> mettreAJourMembre(String uid, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.colMembres).doc(uid).update(data);
  }

  /// Ajouter/retirer un livre de la wishlist
  Future<void> toggleWishlist({
    required String membreId,
    required String livreId,
  }) async {
    final docRef = _db.collection(AppConstants.colMembres).doc(membreId);
    final doc = await docRef.get();
    final wishlist = List<String>.from(doc.data()?['wishlist'] ?? []);

    if (wishlist.contains(livreId)) {
      wishlist.remove(livreId);
    } else {
      wishlist.add(livreId);
    }
    await docRef.update({'wishlist': wishlist});
  }

  /// Suspendre/Activer un membre (admin)
  Future<void> changerStatutMembre(String uid, String statut) async {
    await _db
        .collection(AppConstants.colMembres)
        .doc(uid)
        .update({'statut': statut});
  }

  // ══════════════════════════════════════════════════════════════════
  // EMPRUNTS
  // ══════════════════════════════════════════════════════════════════

  /// Stream des emprunts actifs d'un membre
  Stream<List<Emprunt>> streamEmpruntsActifs(String membreId) {
    return _db
        .collection(AppConstants.colEmprunts)
        .where('membreId', isEqualTo: membreId)
        .where('statut', whereIn: ['enCours', 'enRetard'])
        .orderBy('dateRetourPrevue')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Emprunt.fromFirestore(d)).toList());
  }

  /// Emprunts en retard (admin)
  Future<List<Emprunt>> getEmpruntsEnRetard() async {
    final snap = await _db
        .collection(AppConstants.colEmprunts)
        .where('statut', isEqualTo: 'enRetard')
        .get();
    return snap.docs.map((d) => Emprunt.fromFirestore(d)).toList();
  }

  /// Statistiques d'emprunts (admin)
  Future<Map<String, int>> getStatsEmprunts() async {
    final actifs = await _db
        .collection(AppConstants.colEmprunts)
        .where('statut', isEqualTo: 'enCours')
        .count()
        .get();

    final retard = await _db
        .collection(AppConstants.colEmprunts)
        .where('statut', isEqualTo: 'enRetard')
        .count()
        .get();

    final reservations = await _db
        .collection(AppConstants.colReservations)
        .where('statut', isEqualTo: 'enAttente')
        .count()
        .get();

    return {
      'actifs': actifs.count ?? 0,
      'enRetard': retard.count ?? 0,
      'reservations': reservations.count ?? 0,
    };
  }

  // ══════════════════════════════════════════════════════════════════
  // RÉSERVATIONS
  // ══════════════════════════════════════════════════════════════════

  /// Stream des réservations d'un membre
  Stream<List<Reservation>> streamReservations(String membreId) {
    return _db
        .collection(AppConstants.colReservations)
        .where('membreId', isEqualTo: membreId)
        .where('statut', isEqualTo: 'enAttente')
        .orderBy('dateReservation')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Reservation.fromFirestore(d)).toList());
  }

  // ══════════════════════════════════════════════════════════════════
  // ÉVÉNEMENTS
  // ══════════════════════════════════════════════════════════════════

  /// Stream des événements à venir
  Stream<List<Evenement>> streamEvenementsAVenir() {
    return _db
        .collection(AppConstants.colEvenements)
        .where('dateDebut',
            isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('dateDebut')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Evenement.fromFirestore(d)).toList());
  }

  // ══════════════════════════════════════════════════════════════════
  // MÉTRIQUES ADMIN
  // ══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getMetriquesAdmin() async {
    final livres = await _db
        .collection(AppConstants.colLivres)
        .count()
        .get();
    final membres = await _db
        .collection(AppConstants.colMembres)
        .count()
        .get();

    final stats = await getStatsEmprunts();

    return {
      'totalLivres': livres.count ?? 0,
      'totalMembres': membres.count ?? 0,
      'empruntsActifs': stats['actifs'] ?? 0,
      'empruntsEnRetard': stats['enRetard'] ?? 0,
      'reservationsEnAttente': stats['reservations'] ?? 0,
    };
  }

  /// Alias attendu par AdminDashboardView
  Future<Map<String, int>> getStatsGenerales() async {
    final livres = await _db.collection(AppConstants.colLivres).count().get();
    final membres = await _db.collection(AppConstants.colMembres).count().get();
    final stats = await getStatsEmprunts();
    return {
      'totalLivres': livres.count ?? 0,
      'livresDisponibles': 0,
      'totalMembres': membres.count ?? 0,
      'empruntsEnCours': stats['actifs'] ?? 0,
    };
  }
}
