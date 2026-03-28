import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/emprunt.dart';
import '../models/reservation.dart';
import '../services/cache_service.dart';
import '../services/local_notification_service.dart';
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
  Future<void> chargerEmpruntsMembre(String membreId) async {
    _status = EmpruntStatus.loading;
    notifyListeners();
    try {
      final now = DateTime.now();

      // Emprunts actifs — tri en mémoire pour éviter l'index composite
      final actifSnap = await _db
          .collection(AppConstants.colEmprunts)
          .where('membreId', isEqualTo: membreId)
          .where('statut', whereIn: ['enCours', 'enRetard', 'prolonge', 'enAttenteRetour'])
          .get();

      final overdues = <DocumentReference>[];
      _empruntsActifs = actifSnap.docs.map((d) {
        final emprunt = Emprunt.fromFirestore(d);
        final doitPasserEnRetard =
            emprunt.statut == StatutEmprunt.enCours && now.isAfter(emprunt.dateRetourPrevue);

        if (doitPasserEnRetard) {
          overdues.add(d.reference);
          return emprunt.copyWith(statut: StatutEmprunt.enRetard);
        }
        return emprunt;
      }).toList()
        ..sort((a, b) => a.dateRetourPrevue.compareTo(b.dateRetourPrevue));

      if (overdues.isNotEmpty) {
        final batch = _db.batch();
        for (final ref in overdues) {
          batch.update(ref, {'statut': 'enRetard'});
        }
        await batch.commit();
      }

      // Historique — tri en mémoire pour éviter l'index composite
      final histSnap = await _db
          .collection(AppConstants.colEmprunts)
          .where('membreId', isEqualTo: membreId)
          .where('statut', isEqualTo: 'retourne')
          .get();
      _historique = histSnap.docs
          .map((d) => Emprunt.fromFirestore(d))
          .toList()
        ..sort((a, b) {
          final dateA = a.dateRetourEffective ?? a.dateRetourPrevue;
          final dateB = b.dateRetourEffective ?? b.dateRetourPrevue;
          return dateB.compareTo(dateA);
        });

      await CacheService.sauvegarderEmprunts([
        ..._empruntsActifs.map(_empruntPourHive),
        ..._historique.map(_empruntPourHive),
      ]);

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
          .get();
      _reservations = snap.docs
          .map((d) => Reservation.fromFirestore(d))
          .toList()
        ..sort((a, b) => b.dateReservation.compareTo(a.dateReservation));
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
    int dureeJours = AppConstants.dureeEmpruntJours,
  }) async {
    try {
      await _db.runTransaction((transaction) async {
        final livreRef  = _db.collection(AppConstants.colLivres).doc(livreId);
        final membreRef = _db.collection(AppConstants.colMembres).doc(membreId);
        final livreDoc  = await transaction.get(livreRef);
        final membreDoc = await transaction.get(membreRef);

        if (!livreDoc.exists) throw Exception('Livre introuvable');

        final membreData = membreDoc.data() as Map<String, dynamic>? ?? {};
        final membreStatut = membreData['statut'] ?? 'actif';
        if (membreStatut == 'suspendu') {
          throw Exception('Votre compte est suspendu. Contactez la bibliothèque.');
        }

        final livreStatut = (livreDoc.data() as Map<String, dynamic>)['statut'] ?? '';
        if (livreStatut != 'disponible') {
          throw Exception('Ce livre n\'est pas disponible actuellement.');
        }

        final nbEnCours = (membreData['nbEmpruntsEnCours'] ?? 0) as int;
        if (nbEnCours >= AppConstants.maxEmpruntsSimultanes) {
          throw Exception('Limite de ${AppConstants.maxEmpruntsSimultanes} emprunts simultanés atteinte.');
        }

        final dateEmprunt = DateTime.now();
        final dateRetour  = AppHelpers.calculerDateRetour(dureeJours: dureeJours);

        final empruntRef = _db.collection(AppConstants.colEmprunts).doc();
        transaction.set(empruntRef, {
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

        transaction.update(livreRef, {
          'statut': 'emprunte',
          'nbEmpruntsTotal': FieldValue.increment(1),
        });

        transaction.update(membreRef, {
          'nbEmpruntsEnCours': FieldValue.increment(1),
          'nbEmpruntsTotal': FieldValue.increment(1),
        });
      });

      // Annuler la réservation active du membre sur ce livre si elle existe
      await _annulerReservationSiExiste(livreId: livreId, membreId: membreId);

      await chargerEmpruntsMembre(membreId);
      LocalNotificationService().planifierRappelEmprunt(
        empruntId: '${membreId}_${livreId}_${DateTime.now().millisecondsSinceEpoch}',
        livreTitre: livreTitre,
        dateRetour: AppHelpers.calculerDateRetour(dureeJours: dureeJours),
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Annule silencieusement la réservation du membre sur ce livre (si elle existe)
  Future<void> _annulerReservationSiExiste({
    required String livreId,
    required String membreId,
  }) async {
    try {
      final snap = await _db
          .collection(AppConstants.colReservations)
          .where('livreId', isEqualTo: livreId)
          .where('membreId', isEqualTo: membreId)
          .where('statut', isEqualTo: 'enAttente')
          .get();
      for (final doc in snap.docs) {
        await doc.reference.update({'statut': 'annulee'});
      }
    } catch (_) {}
  }

  // ─── Membre : demander le retour (en attente confirmation admin) ─────────
  Future<bool> retournerLivre({
    required String empruntId,
    required String livreId,
    required String membreId,
  }) async {
    try {
      // Le membre signale qu'il a rapporté le livre — l'admin doit confirmer
      await _db.collection(AppConstants.colEmprunts).doc(empruntId).update({
        'statut': 'enAttenteRetour',
      });
      await chargerEmpruntsMembre(membreId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Prolonger un emprunt ─────────────────────────────────────────────────
  // Bloqué si une réservation active existe pour ce livre
  // Bloqué si l'admin n'a pas autorisé la prolongation
  Future<bool> prolongerEmprunt({
    required String empruntId,
    required String membreId,
    int dureeJours = AppConstants.dureeProlongationJours,
  }) async {
    try {
      final doc = await _db.collection(AppConstants.colEmprunts).doc(empruntId).get();
      final data = doc.data() as Map<String, dynamic>;
      final prolongations = (data['prolongations'] ?? 0) as int;
      final livreId = data['livreId'] as String;
      final prolongationAutorisee = (data['prolongationAutorisee'] ?? false) as bool;

      // Vérifier autorisation admin
      if (!prolongationAutorisee) {
        _errorMessage = 'La prolongation n\'est pas encore autorisée par l\'administrateur. Contactez la bibliothèque.';
        notifyListeners();
        return false;
      }

      if (prolongations >= AppConstants.maxProlongations) {
        _errorMessage = 'Nombre maximum de prolongations atteint (${AppConstants.maxProlongations}).';
        notifyListeners();
        return false;
      }

      // Bloquer si quelqu'un attend ce livre en réservation
      final fileSnap = await _db
          .collection(AppConstants.colReservations)
          .where('livreId', isEqualTo: livreId)
          .where('statut', isEqualTo: 'enAttente')
          .get();
      if (fileSnap.docs.isNotEmpty) {
        _errorMessage =
            '${fileSnap.docs.length} membre(s) attendent ce livre. La prolongation n\'est pas possible.';
        notifyListeners();
        return false;
      }

      final dateActuelle = (data['dateRetourPrevue'] as Timestamp).toDate();
      final nouvelleDate = dateActuelle.add(Duration(days: dureeJours));

      await _db.collection(AppConstants.colEmprunts).doc(empruntId).update({
        'dateRetourPrevue': Timestamp.fromDate(nouvelleDate),
        'prolongations': FieldValue.increment(1),
        'statut': 'prolonge',
        'prolongationAutorisee': false, // Réinitialiser après usage
      });

      await chargerEmpruntsMembre(membreId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ─── Admin : autoriser ou refuser une prolongation ────────────────────────
  Future<bool> autoriserProlongation({
    required String empruntId,
    required bool autoriser,
  }) async {
    try {
      await _db.collection(AppConstants.colEmprunts).doc(empruntId).update({
        'prolongationAutorisee': autoriser,
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Réserver un livre ────────────────────────────────────────────────────
  // Règle : on ne peut réserver que si le livre est emprunté/réservé (pas disponible)
  Future<bool> reserverLivre({
    required String livreId,
    required String membreId,
    required String membreNom,
    required String livreTitre,
    String livreAuteur = '',
  }) async {
    try {
      // Vérifier statut membre
      final membreDoc = await _db.collection(AppConstants.colMembres).doc(membreId).get();
      final membreStatut = (membreDoc.data() as Map<String, dynamic>?)?['statut'] ?? 'actif';
      if (membreStatut == 'suspendu') {
        _errorMessage = 'Votre compte est suspendu. Contactez la bibliothèque.';
        notifyListeners();
        return false;
      }

      // Vérifier que le livre n'est pas disponible (sinon emprunter directement)
      final livreDoc = await _db.collection(AppConstants.colLivres).doc(livreId).get();
      final livreStatut = (livreDoc.data() as Map<String, dynamic>?)?['statut'] ?? '';
      if (livreStatut == 'disponible') {
        _errorMessage = 'Ce livre est disponible, vous pouvez l\'emprunter directement.';
        notifyListeners();
        return false;
      }

      // Vérifier que le membre n'a pas déjà emprunté ce livre
      final dejaEmprunte = await _db
          .collection(AppConstants.colEmprunts)
          .where('livreId', isEqualTo: livreId)
          .where('membreId', isEqualTo: membreId)
          .where('statut', whereIn: ['enCours', 'prolonge', 'enAttenteRetour'])
          .get();
      if (dejaEmprunte.docs.isNotEmpty) {
        _errorMessage = 'Vous avez déjà ce livre en cours d\'emprunt.';
        notifyListeners();
        return false;
      }

      // Vérifier doublon réservation
      final dejaReserve = await _db
          .collection(AppConstants.colReservations)
          .where('livreId', isEqualTo: livreId)
          .where('membreId', isEqualTo: membreId)
          .where('statut', isEqualTo: 'enAttente')
          .get();
      if (dejaReserve.docs.isNotEmpty) {
        _errorMessage = 'Vous avez déjà une réservation en attente pour ce livre.';
        notifyListeners();
        return false;
      }

      // Calculer la position dans la file
      final fileSnap = await _db
          .collection(AppConstants.colReservations)
          .where('livreId', isEqualTo: livreId)
          .where('statut', isEqualTo: 'enAttente')
          .get();

      final position = fileSnap.docs.length + 1;
      final now = DateTime.now();

      await _db.collection(AppConstants.colReservations).add({
        'membreId': membreId,
        'membreNom': membreNom,
        'livreId': livreId,
        'livreTitre': livreTitre,
        'livreAuteur': livreAuteur,
        'livreCouverture': '',
        'dateReservation': Timestamp.fromDate(now),
        'dateExpiration': Timestamp.fromDate(now.add(const Duration(days: 30))),
        'statut': 'enAttente',
        'positionFile': position,
      });

      await _renumeroterFileReservations(livreId);

      // Mettre à jour le statut du livre en "reserve" si ce n'est pas déjà "emprunte"
      if (livreStatut != 'emprunte') {
        await _db.collection(AppConstants.colLivres).doc(livreId).update({
          'statut': 'reserve',
        });
      }

      await chargerReservationsMembre(membreId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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
      final reservationRef = _db
          .collection(AppConstants.colReservations)
          .doc(reservationId);

      final reservationSnap = await reservationRef.get();
      if (!reservationSnap.exists) {
        _errorMessage = 'Réservation introuvable.';
        notifyListeners();
        return false;
      }

      final reservationData = reservationSnap.data() ?? <String, dynamic>{};
      final livreId = (reservationData['livreId'] ?? '').toString();
      if (livreId.isEmpty) {
        _errorMessage = 'Livre lié à la réservation introuvable.';
        notifyListeners();
        return false;
      }

      await reservationRef.update({'statut': 'annulee'});

      final reservationsRestantes = await _db
          .collection(AppConstants.colReservations)
          .where('livreId', isEqualTo: livreId)
          .where('statut', isEqualTo: 'enAttente')
          .limit(1)
          .get();

      if (reservationsRestantes.docs.isEmpty) {
        final livreRef = _db.collection(AppConstants.colLivres).doc(livreId);
        final livreSnap = await livreRef.get();
        final livreStatut = (livreSnap.data()?['statut'] ?? '').toString();

        if (livreStatut == 'reserve') {
          await livreRef.update({'statut': 'disponible'});
        }
      }

      await _renumeroterFileReservations(livreId);
      await chargerReservationsMembre(membreId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
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

  // ─── Admin : retourner un livre + gérer la file d'attente ──────────────
  Future<bool> retournerLivreAdmin({
    required String empruntId,
    required String livreId,
    required String membreId,
  }) async {
    try {
      // 1. Marquer l'emprunt comme retourné
      await _db.collection(AppConstants.colEmprunts).doc(empruntId).update({
        'statut': 'retourne',
        'dateRetourEffective': Timestamp.fromDate(DateTime.now()),
      });

      // 2. Décrémenter le compteur du membre emprunteur sans passer sous 0
      try {
        final membreRef = _db.collection(AppConstants.colMembres).doc(membreId);
        await _db.runTransaction((tx) async {
          final membreSnap = await tx.get(membreRef);
          if (!membreSnap.exists) return;

          final data = membreSnap.data() ?? <String, dynamic>{};
          final current = (data['nbEmpruntsEnCours'] as num?)?.toInt() ?? 0;
          final next = current > 0 ? current - 1 : 0;

          tx.update(membreRef, {
            'nbEmpruntsEnCours': next,
          });
        });
      } catch (_) {}

      // 3. Mettre le livre disponible avant d'attribuer automatiquement
      await _db.collection(AppConstants.colLivres).doc(livreId).update({
        'statut': 'disponible',
      });

      // 4. Prendre la plus ancienne réservation en attente
      final prochaineReservation = await _db
          .collection(AppConstants.colReservations)
          .where('livreId', isEqualTo: livreId)
          .where('statut', isEqualTo: 'enAttente')
          .orderBy('dateReservation', descending: false)
          .limit(1)
          .get();

      if (prochaineReservation.docs.isEmpty) {
        return true;
      }

      final reservationData = prochaineReservation.docs.first.data();
      final prochainMembreId = reservationData['membreId'] as String? ?? '';
      if (prochainMembreId.isEmpty) {
        return true;
      }

      final prochainMembreNom = reservationData['membreNom'] as String? ?? '';
      final livreTitre = reservationData['livreTitre'] as String? ?? '';
      final livreAuteur = reservationData['livreAuteur'] as String? ?? '';
      final livreCouverture = reservationData['livreCouverture'] as String? ?? '';

      // 5. Emprunt automatique pour la réservation la plus ancienne
      final ok = await emprunterLivre(
        livreId: livreId,
        membreId: prochainMembreId,
        membreNom: prochainMembreNom,
        livreTitre: livreTitre,
        livreAuteur: livreAuteur,
        livreCouverture: livreCouverture,
      );

      // 6. Ajuster la file restante seulement si l'attribution auto a réussi
      if (ok) {
        await _renumeroterFileReservations(livreId);
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Admin : tous les emprunts actifs + en attente retour ───────────────
  Future<List<Emprunt>> getTousEmpruntsActifs() async {
    final now = DateTime.now();
    final snap = await _db
        .collection(AppConstants.colEmprunts)
        .where('statut', whereIn: ['enCours', 'enRetard', 'prolonge', 'enAttenteRetour'])
        .get();

    final overdues = <DocumentReference>[];
    final emprunts = snap.docs.map((d) {
      final emprunt = Emprunt.fromFirestore(d);
      final doitPasserEnRetard =
          emprunt.statut == StatutEmprunt.enCours && now.isAfter(emprunt.dateRetourPrevue);

      if (doitPasserEnRetard) {
        overdues.add(d.reference);
        return emprunt.copyWith(statut: StatutEmprunt.enRetard);
      }
      return emprunt;
    }).toList();

    if (overdues.isNotEmpty) {
      final batch = _db.batch();
      for (final ref in overdues) {
        batch.update(ref, {'statut': 'enRetard'});
      }
      await batch.commit();
    }

    return emprunts
      ..sort((a, b) {
        // Les demandes de retour en premier
        if (a.statut == StatutEmprunt.enAttenteRetour) return -1;
        if (b.statut == StatutEmprunt.enAttenteRetour) return 1;
        return a.dateRetourPrevue.compareTo(b.dateRetourPrevue);
      });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _renumeroterFileReservations(String livreId) async {
    try {
      final snap = await _db
          .collection(AppConstants.colReservations)
          .where('livreId', isEqualTo: livreId)
          .where('statut', isEqualTo: 'enAttente')
          .orderBy('dateReservation', descending: false)
          .get();
      if (snap.docs.isEmpty) return;

      final batch = _db.batch();
      for (int i = 0; i < snap.docs.length; i++) {
        batch.update(snap.docs[i].reference, {'positionFile': i + 1});
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Hive ne sérialise pas [Timestamp] Firestore : on stocke des epoch (ms).
  static Map<String, dynamic> _empruntPourHive(Emprunt e) => {
        'id': e.id,
        'membreId': e.membreId,
        'membreNom': e.membreNom,
        'livreId': e.livreId,
        'livreTitre': e.livreTitre,
        'livreAuteur': e.livreAuteur,
        'livreCouverture': e.livreCouverture,
        'dateEmprunt': e.dateEmprunt.millisecondsSinceEpoch,
        'dateRetourPrevue': e.dateRetourPrevue.millisecondsSinceEpoch,
        'dateRetourEffective': e.dateRetourEffective?.millisecondsSinceEpoch,
        'statut': e.statut.name,
        'prolongations': e.prolongations,
        'notes': e.notes,
        'prolongationAutorisee': e.prolongationAutorisee,
      };
}
