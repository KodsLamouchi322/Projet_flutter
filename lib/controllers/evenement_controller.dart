import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evenement.dart';
import '../services/local_notification_service.dart';
import '../utils/constants.dart';

/// Controller pour la gestion des événements culturels
class EvenementController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Evenement> _evenements = [];
  List<Evenement> _mesEvenements = [];
  Evenement? _evenementSelectionne;
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ──────────────────────────────────────────────────────────────
  List<Evenement> get evenements => _evenements;
  List<Evenement> get mesEvenements => _mesEvenements;
  List<Evenement> get evenementsAVenir =>
      _evenements.where((e) => e.statut == StatutEvenement.aVenir).toList();
  Evenement? get evenementSelectionne => _evenementSelectionne;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Charger tous les événements ──────────────────────────────────────────
  Future<void> chargerEvenements() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _db
          .collection(AppConstants.colEvenements)
          .where('dateDebut',
              isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(days: 1)),
              ))
          .orderBy('dateDebut')
          .get();
      _evenements =
          snapshot.docs.map((d) => Evenement.fromFirestore(d)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── Charger tous les événements (admin) ──────────────────────────────────
  Future<void> chargerTousEvenements() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _db
          .collection(AppConstants.colEvenements)
          .orderBy('dateDebut', descending: true)
          .get();
      _evenements =
          snapshot.docs.map((d) => Evenement.fromFirestore(d)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── Charger mes événements (inscriptions) ────────────────────────────────
  Future<void> chargerMesEvenements(String membreId) async {
    try {
      // Sans orderBy pour éviter l'index composite — tri en mémoire
      final snapshot = await _db
          .collection(AppConstants.colEvenements)
          .where('participantsIds', arrayContains: membreId)
          .get();
      _mesEvenements = snapshot.docs
          .map((d) => Evenement.fromFirestore(d))
          .toList()
        ..sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ─── S'inscrire à un événement ────────────────────────────────────────────
  Future<bool> sInscrire({
    required String evenementId,
    required String membreId,
  }) async {
    try {
      final docRef = _db.collection(AppConstants.colEvenements).doc(evenementId);
      await _db.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final evenement = Evenement.fromFirestore(doc);

        if (evenement.estComplet) {
          throw Exception('L\'événement est complet.');
        }
        if (evenement.estParticipant(membreId)) {
          throw Exception('Vous êtes déjà inscrit.');
        }

        final newParticipants = [...evenement.participantsIds, membreId];
        transaction.update(docRef, {'participantsIds': newParticipants});
      });

      await chargerEvenements();
      // Planifier rappels locaux 24h et 1h avant
      final ev = _evenements.firstWhere((e) => e.id == evenementId,
          orElse: () => _evenements.isNotEmpty ? _evenements.first : throw Exception(''));
      LocalNotificationService().planifierRappelEvenement(
        evenementId: evenementId,
        titre: ev.titre,
        dateDebut: ev.dateDebut,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Se désinscrire d'un événement ───────────────────────────────────────
  Future<bool> seDesinscrire({
    required String evenementId,
    required String membreId,
  }) async {
    try {
      final docRef = _db.collection(AppConstants.colEvenements).doc(evenementId);
      await _db.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final evenement = Evenement.fromFirestore(doc);
        final newParticipants = evenement.participantsIds
            .where((id) => id != membreId)
            .toList();
        transaction.update(docRef, {'participantsIds': newParticipants});
      });

      await chargerEvenements();
      LocalNotificationService().annulerRappelEvenement(evenementId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Créer un événement (admin) ────────────────────────────────────────────
  Future<bool> creerEvenement(Evenement evenement) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.collection(AppConstants.colEvenements).add(
            evenement.toFirestore(),
          );
      await chargerTousEvenements();
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

  // ─── Modifier un événement (admin) ────────────────────────────────────────
  Future<bool> modifierEvenement(Evenement evenement) async {
    try {
      await _db
          .collection(AppConstants.colEvenements)
          .doc(evenement.id)
          .update(evenement.toFirestore());
      await chargerTousEvenements();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Supprimer un événement (admin) ──────────────────────────────────────
  Future<bool> supprimerEvenement(String evenementId) async {
    try {
      await _db
          .collection(AppConstants.colEvenements)
          .doc(evenementId)
          .delete();
      _evenements.removeWhere((e) => e.id == evenementId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void selectionnerEvenement(Evenement? evenement) {
    _evenementSelectionne = evenement;
    notifyListeners();
  }

  // ─── Publier un compte-rendu (admin) ──────────────────────────────────────
  Future<bool> publierCompteRendu({
    required String evenementId,
    required String compteRendu,
    List<String> photosUrls = const [],
  }) async {
    try {
      await _db.collection(AppConstants.colEvenements).doc(evenementId).update({
        'compteRendu': compteRendu,
        'photosCompteRendu': photosUrls,
      });
      await chargerTousEvenements();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Ajouter une photo à l'événement ─────────────────────────────────────
  Future<bool> ajouterPhoto({
    required String evenementId,
    required String photoUrl,
  }) async {
    try {
      await _db.collection(AppConstants.colEvenements).doc(evenementId).update({
        'photosUrls': FieldValue.arrayUnion([photoUrl]),
      });
      await chargerTousEvenements();
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
