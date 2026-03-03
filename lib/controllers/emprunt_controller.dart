import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emprunt.dart';
import '../models/reservation.dart';
import '../models/livre.dart';
import '../utils/constants.dart';

/// Controller gérant les emprunts et retours de livres
class EmpruntController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Emprunt> _empruntsActifs = [];
  List<Emprunt> _historique = [];
  List<Reservation> _reservations = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ──────────────────────────────────────────────────────────────
  List<Emprunt> get empruntsActifs => _empruntsActifs;
  List<Emprunt> get historique => _historique;
  List<Reservation> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get nbEmpruntsEnCours => _empruntsActifs.length;
  int get nbReservationsEnAttente =>
      _reservations.where((r) => r.statut == StatutReservation.enAttente).length;

  // ─── Charger les emprunts d'un membre ─────────────────────────────────────
  Future<void> chargerEmpruntsMemebres(String membreId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Emprunts actifs
      final snapshotActifs = await _db
          .collection(AppConstants.colEmprunts)
          .where('membreId', isEqualTo: membreId)
          .where('statut', whereIn: ['enCours', 'enRetard'])
          .orderBy('dateEmprunt', descending: true)
          .get();
      _empruntsActifs =
          snapshotActifs.docs.map((d) => Emprunt.fromFirestore(d)).toList();

      // Historique (retournés)
      final snapshotHisto = await _db
          .collection(AppConstants.colEmprunts)
          .where('membreId', isEqualTo: membreId)
          .where('statut', isEqualTo: 'retourne')
          .orderBy('dateEmprunt', descending: true)
          .limit(20)
          .get();
      _historique =
          snapshotHisto.docs.map((d) => Emprunt.fromFirestore(d)).toList();

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── Charger les réservations d'un membre ─────────────────────────────────
  Future<void> chargerReservationsMembre(String membreId) async {
    try {
      final snapshot = await _db
          .collection(AppConstants.colReservations)
          .where('membreId', isEqualTo: membreId)
          .orderBy('dateReservation', descending: true)
          .get();
      _reservations =
          snapshot.docs.map((d) => Reservation.fromFirestore(d)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ─── Emprunter un livre ────────────────────────────────────────────────────
  Future<bool> emprunterLivre({
    required String livreId,
    required String membreId,
    required String membreNom,
    required String livreTitre,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final dateEmprunt = DateTime.now();
      final dateRetourPrevue = dateEmprunt
          .add(const Duration(days: AppConstants.dureeEmpruntJours));

      // Créer l'emprunt
      await _db.collection(AppConstants.colEmprunts).add({
        'livreId': livreId,
        'membreId': membreId,
        'membreNom': membreNom,
        'livreTitre': livreTitre,
        'dateEmprunt': Timestamp.fromDate(dateEmprunt),
        'dateRetourPrevue': Timestamp.fromDate(dateRetourPrevue),
        'dateRetourEffective': null,
        'statut': 'enCours',
        'prolongations': 0,
      });

      // Mettre le livre comme indisponible
      await _db.collection(AppConstants.colLivres).doc(livreId).update({
        'estDisponible': false,
        'emprunteurId': membreId,
      });

      await chargerEmpruntsMemebres(membreId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Retourner un livre ────────────────────────────────────────────────────
  Future<bool> retournerLivre({
    required String empruntId,
    required String livreId,
    required String membreId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.collection(AppConstants.colEmprunts).doc(empruntId).update({
        'dateRetourEffective': Timestamp.fromDate(DateTime.now()),
        'statut': 'retourne',
      });

      await _db.collection(AppConstants.colLivres).doc(livreId).update({
        'estDisponible': true,
        'emprunteurId': null,
      });

      await chargerEmpruntsMemebres(membreId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
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
      final emprunt = _empruntsActifs.firstWhere((e) => e.id == empruntId);
      if (emprunt.prolongations >= 2) {
        _errorMessage = 'Maximum 2 prolongations autorisées.';
        notifyListeners();
        return false;
      }

      final nouvelleDateRetour = emprunt.dateRetourPrevue
          .add(const Duration(days: 7));

      await _db.collection(AppConstants.colEmprunts).doc(empruntId).update({
        'dateRetourPrevue': Timestamp.fromDate(nouvelleDateRetour),
        'prolongations': emprunt.prolongations + 1,
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
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Vérifier si déjà réservé par ce membre
      final existing = await _db
          .collection(AppConstants.colReservations)
          .where('livreId', isEqualTo: livreId)
          .where('membreId', isEqualTo: membreId)
          .where('statut', isEqualTo: 'enAttente')
          .get();

      if (existing.docs.isNotEmpty) {
        _errorMessage = 'Vous avez déjà réservé ce livre.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Compter la position dans la file
      final fileAttente = await _db
          .collection(AppConstants.colReservations)
          .where('livreId', isEqualTo: livreId)
          .where('statut', isEqualTo: 'enAttente')
          .get();

      await _db.collection(AppConstants.colReservations).add({
        'livreId': livreId,
        'membreId': membreId,
        'membreNom': membreNom,
        'livreTitre': livreTitre,
        'dateReservation': Timestamp.fromDate(DateTime.now()),
        'dateExpiration': Timestamp.fromDate(
          DateTime.now().add(
            const Duration(days: AppConstants.dureeReservationJours),
          ),
        ),
        'statut': 'enAttente',
        'positionFile': fileAttente.docs.length + 1,
      });

      await chargerReservationsMembre(membreId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
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

  // ─── Admin: tous les emprunts ─────────────────────────────────────────────
  Future<List<Emprunt>> getTousEmpruntsActifs() async {
    final snapshot = await _db
        .collection(AppConstants.colEmprunts)
        .where('statut', whereIn: ['enCours', 'enRetard'])
        .orderBy('dateRetourPrevue')
        .get();
    return snapshot.docs.map((d) => Emprunt.fromFirestore(d)).toList();
  }

  // ─── Signaler un livre endommagé ──────────────────────────────────────────
  Future<bool> signalerLivreEndommage({
    required String livreId,
    required String description,
  }) async {
    try {
      await _db.collection(AppConstants.colLivres).doc(livreId).update({
        'signalementDommage': description,
        'dateSignalement': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
