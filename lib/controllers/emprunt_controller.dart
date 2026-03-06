import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/emprunt.dart';
import '../models/reservation.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

enum EmpruntStatus { initial, loading, loaded, error }

/// Controller gérant les emprunts et retours de livres
class EmpruntController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  EmpruntStatus _status = EmpruntStatus.initial;
  List<Emprunt> _empruntsActifs = [];
  List<Emprunt> _historique = [];
  List<Reservation> _reservations = [];
  String? _errorMessage;

  // ─── Getters ──────────────────────────────────────────────────────────────
  EmpruntStatus get status => _status;
  bool get isLoading => _status == EmpruntStatus.loading;
  String? get errorMessage => _errorMessage;
  List<Emprunt> get empruntsActifs => _empruntsActifs;
  List<Emprunt> get historique => _historique;
  List<Reservation> get reservations => _reservations;

  // ─── Charger emprunts du membre ───────────────────────────────────────────
  Future<void> chargerEmpruntsMemebres(String membreId) async {
    _status = EmpruntStatus.loading;
    notifyListeners();
    try {
      // Emprunts actifs
      final actifSnap = await _db
          .collection(AppConstants.colEmprunts)
          .where('membreId', isEqualTo: membreId)
          .where('statut', whereIn: ['enCours', 'enRetard', 'prolonge'])
          .orderBy('dateRetourPrevue')
          .get();
      _empruntsActifs =
          actifSnap.docs.map((d) => Emprunt.fromFirestore(d)).toList();

      // Historique
      final histSnap = await _db
          .collection(AppConstants.colEmprunts)
          .where('membreId', isEqualTo: membreId)
          .where('statut', isEqualTo: 'retourne')
          .orderBy('dateRetourEffective', descending: true)
          .get();
      _historique =
          histSnap.docs.map((d) => Emprunt.fromFirestore(d)).toList();

      _status = EmpruntStatus.loaded;
    } catch (e) {
      _status = EmpruntStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // ─── Charger réservations du membre ──────────────────────────────────────
  Future<void> chargerReservationsMembre(String membreId) async {
    try {
      final snap = await _db
          .collection(AppConstants.colReservations)
          .where('membreId', isEqualTo: membreId)
          .orderBy('dateReservation', descending: true)
          .get();
      _reservations =
          snap.docs.map((d) => Reservation.fromFirestore(d)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ─── Emprunter un livre ───────────────────────────────────────────────────
  Future<bool> emprunterLivre({
    required String livreId,
    required String membreId,
    required String membreNom,
    required String livreTitre,
    String livreAuteur = '',
    String livreCouverture = '',
  }) async {
    try {
      final dateEmprunt = DateTime.now();
      final dateRetour = AppHelpers.calculerDateRetour();

      // Vérifier disponibilité
      final livreDoc =
          await _db.collection(AppConstants.colLivres).doc(livreId).get();
      final statut = (livreDoc.data() as Map<String, dynamic>)['statut'] ?? '';
      if (statut != 'disponible') {
        _errorMessage = 'Ce livre n\'est plus disponible.';
        notifyListeners();
        return false;
      }

      // Créer l'emprunt
      await _db.collection(AppConstants.colEmprunts).add({
        'membreId': membreId,
        'membreNom': membreNom,
        'livreId': livreId,
        'livreTitre': livreTitre,
        'livreAuteur': livreAuteur,
        'livreCouverture': livreCouverture,
        'dateEmprunt': Timestamp.fromDate(dateEmprunt),
        'dateRetourPrevue': Timestamp.fromDate(dateRetour),
        'dateRetourEffective': null,
        'statut': 'enCours',
        'prolongations': 0,
        'notes': null,
      });

      // Marquer le livre comme emprunté
      await _db.collection(AppConstants.colLivres).doc(livreId).update({
        'statut': 'emprunte',
        'nbEmpruntsTotal': FieldValue.increment(1),
      });

      // Incrémenter le compteur du membre
      await _db.collection(AppConstants.colMembres).doc(membreId).update({
        'nbEmpruntsEnCours': FieldValue.increment(1),
        'nbEmpruntsTotal': FieldValue.increment(1),
      });

      await chargerEmpruntsMemebres(membreId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Retourner un livre ───────────────────────────────────────────────────
  Future<bool> retournerLivre({
    required String empruntId,
    required String livreId,
    required String membreId,
  }) async {
    try {
      // Mettre à jour l'emprunt
      await _db.collection(AppConstants.colEmprunts).doc(empruntId).update({
        'statut': 'retourne',
        'dateRetourEffective': Timestamp.fromDate(DateTime.now()),
      });

      // Rendre le livre disponible
      await _db.collection(AppConstants.colLivres).doc(livreId).update({
        'statut': 'disponible',
      });

      // Décrémenter le compteur
      await _db.collection(AppConstants.colMembres).doc(membreId).update({
        'nbEmpruntsEnCours': FieldValue.increment(-1),
      });

      await chargerEmpruntsMemebres(membreId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Prolonger un emprunt ─────────────────────────────────────────────────
  Future<bool> prolongerEmprunt({
    required String empruntId,
    required String membreId,
  }) async {
    try {
      final doc = await _db
          .collection(AppConstants.colEmprunts)
          .doc(empruntId)
          .get();
      final data = doc.data() as Map<String, dynamic>;
      final prolongations = (data['prolongations'] ?? 0) as int;

      if (prolongations >= AppConstants.maxProlongations) {
        _errorMessage =
            'Nombre maximum de prolongations atteint (${AppConstants.maxProlongations}).';
        notifyListeners();
        return false;
      }

      final dateActuelle =
          (data['dateRetourPrevue'] as Timestamp).toDate();
      final nouvelleDate = dateActuelle
          .add(const Duration(days: AppConstants.dureeProlongationJours));

      await _db.collection(AppConstants.colEmprunts).doc(empruntId).update({
        'dateRetourPrevue': Timestamp.fromDate(nouvelleDate),
        'prolongations': FieldValue.increment(1),
        'statut': 'prolonge',
      });

      await chargerEmpruntsMemebres(membreId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Réserver un livre ────────────────────────────────────────────────────
  Future<bool> reserverLivre({
    required String livreId,
    required String membreId,
    required String membreNom,
    required String livreTitre,
    String livreAuteur = '',
  }) async {
    try {
      // Compter les réservations existantes pour ce livre
      final existingSnap = await _db
          .collection(AppConstants.colReservations)
          .where('livreId', isEqualTo: livreId)
          .where('statut', isEqualTo: 'enAttente')
          .get();

      final position = existingSnap.docs.length + 1;
      final dateReservation = DateTime.now();
      final dateExpiration =
          dateReservation.add(const Duration(days: 30));

      await _db.collection(AppConstants.colReservations).add({
        'membreId': membreId,
        'membreNom': membreNom,
        'livreId': livreId,
        'livreTitre': livreTitre,
        'livreAuteur': livreAuteur,
        'livreCouverture': '',
        'dateReservation': Timestamp.fromDate(dateReservation),
        'dateExpiration': Timestamp.fromDate(dateExpiration),
        'statut': 'enAttente',
        'positionFile': position,
      });

      await chargerReservationsMembre(membreId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Annuler une réservation ──────────────────────────────────────────────
  Future<bool> annulerReservation({
    required String reservationId,
    required String membreId,
  }) async {
    try {
      await _db
          .collection(AppConstants.colReservations)
          .doc(reservationId)
          .update({'statut': 'annulee'});
      await chargerReservationsMembre(membreId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Admin : tous les emprunts actifs ────────────────────────────────────
  Future<List<Emprunt>> getTousEmpruntsActifs() async {
    final snap = await _db
        .collection(AppConstants.colEmprunts)
        .where('statut', whereIn: ['enCours', 'enRetard'])
        .orderBy('dateRetourPrevue')
        .get();
    return snap.docs.map((d) => Emprunt.fromFirestore(d)).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
