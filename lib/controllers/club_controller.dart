import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/club_lecture.dart';
import '../models/lecture_commune.dart';
import '../models/vote_livre.dart';
import '../models/defi_lecture.dart';
import '../models/livre_club.dart';

class ClubController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  static const _col = 'clubs_lecture';
  static const _colMessages = 'messages_club';

  List<ClubLecture> _clubs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ClubLecture> get clubs => _clubs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Charger tous les clubs publics ──────────────────────────────────────
  Future<void> chargerClubs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      debugPrint('🔵 Chargement des clubs publics...');
      final snap = await _db.collection(_col)
          .where('estPublic', isEqualTo: true)
          .orderBy('dateCreation', descending: true)
          .get();
      _clubs = snap.docs.map((d) => ClubLecture.fromFirestore(d)).toList();
      debugPrint('✅ ${_clubs.length} clubs chargés');
      for (var club in _clubs) {
        debugPrint('   - ${club.nom}: ${club.nbMembres} membres (${club.membresIds.join(", ")})');
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement clubs: $e');
      // Si l'index n'est pas prêt, essayer sans orderBy
      if (e.toString().contains('index') || e.toString().contains('FAILED_PRECONDITION')) {
        debugPrint('⚠️ Tentative de chargement sans orderBy (index en cours de création)...');
        try {
          final snap = await _db.collection(_col)
              .where('estPublic', isEqualTo: true)
              .get();
          _clubs = snap.docs.map((d) => ClubLecture.fromFirestore(d)).toList();
          // Trier localement
          _clubs.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
          debugPrint('✅ ${_clubs.length} clubs chargés (tri local)');
        } catch (e2) {
          _errorMessage = 'Erreur de chargement: ${e2.toString()}';
          debugPrint('❌ Erreur chargement clubs (fallback): $e2');
        }
      } else {
        _errorMessage = 'Erreur de chargement: ${e.toString()}';
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Admin : tous les clubs (publics ou non)
  Future<void> chargerTousLesClubsAdmin() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _db.collection(_col).get();
      _clubs = snap.docs.map((d) => ClubLecture.fromFirestore(d)).toList()
        ..sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> supprimerClub(String clubId) async {
    try {
      await _db.collection(_col).doc(clubId).delete();
      await chargerTousLesClubsAdmin();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Créer un club ────────────────────────────────────────────────────────
  Future<bool> creerClub({
    required String nom,
    required String description,
    required String livreId,
    required String livreTitre,
    required String livreAuteur,
    required String createurId,
    required String createurNom,
    String livreCouverture = '',
    DateTime? dateLecture,
  }) async {
    try {
      debugPrint('🔵 Création du club "$nom"...');
      final club = ClubLecture(
        id: '',
        nom: nom,
        description: description,
        livreId: livreId,
        livreTitre: livreTitre,
        livreAuteur: livreAuteur,
        livreCouverture: livreCouverture,
        createurId: createurId,
        createurNom: createurNom,
        membresIds: [createurId],
        dateCreation: DateTime.now(),
        dateLecture: dateLecture,
      );
      await _db.collection(_col).add(club.toFirestore());
      debugPrint('✅ Club "$nom" créé avec succès');
      await chargerClubs();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création: ${e.toString()}';
      debugPrint('❌ Erreur création club: $e');
      notifyListeners();
      return false;
    }
  }

  // ─── Rejoindre / quitter un club ─────────────────────────────────────────
  Future<bool> rejoindre(String clubId, String membreId) async {
    try {
      debugPrint('🔵 Tentative de rejoindre le club $clubId par membre $membreId');
      
      // Vérifier que le club existe
      final clubDoc = await _db.collection(_col).doc(clubId).get();
      if (!clubDoc.exists) {
        _errorMessage = 'Club introuvable.';
        notifyListeners();
        debugPrint('❌ Club $clubId introuvable');
        return false;
      }
      
      // Vérifier si déjà membre
      final data = clubDoc.data() as Map<String, dynamic>;
      final membresIds = List<String>.from(data['membresIds'] ?? []);
      if (membresIds.contains(membreId)) {
        debugPrint('⚠️ Membre $membreId déjà dans le club $clubId');
        return true; // Déjà membre, considéré comme succès
      }
      
      // Ajouter le membre
      await _db.collection(_col).doc(clubId).update({
        'membresIds': FieldValue.arrayUnion([membreId]),
      });
      
      debugPrint('✅ Membre $membreId ajouté au club $clubId');
      await chargerClubs();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'adhésion: ${e.toString()}';
      debugPrint('❌ Erreur rejoindre club: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> quitter(String clubId, String membreId) async {
    try {
      final clubRef = _db.collection(_col).doc(clubId);
      final clubSnap = await clubRef.get();
      if (!clubSnap.exists) {
        _errorMessage = 'Club introuvable.';
        notifyListeners();
        return false;
      }

      final clubData = clubSnap.data() ?? <String, dynamic>{};
      final createurId = (clubData['createurId'] ?? '').toString();
      if (membreId == createurId) {
        _errorMessage = 'Le créateur ne peut pas quitter son club. Supprimez-le ou transférez la propriété.';
        notifyListeners();
        return false;
      }

      await _db.collection(_col).doc(clubId).update({
        'membresIds': FieldValue.arrayRemove([membreId]),
      });
      await chargerClubs();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Messages du club (stream) ────────────────────────────────────────────
  Stream<QuerySnapshot> streamMessages(String clubId) {
    return _db
        .collection(_col)
        .doc(clubId)
        .collection(_colMessages)
        .orderBy('date', descending: false)
        .snapshots();
  }

  // ─── Envoyer un message ───────────────────────────────────────────────────
  Future<void> envoyerMessage({
    required String clubId,
    required String membreId,
    required String membreNom,
    required String contenu,
  }) async {
    await _db.collection(_col).doc(clubId).collection(_colMessages).add({
      'membreId': membreId,
      'membreNom': membreNom,
      'contenu': contenu,
      'date': FieldValue.serverTimestamp(),
    });
  }

  void clearError() { _errorMessage = null; notifyListeners(); }

  // ═══════════════════════════════════════════════════════════════════════════
  // LECTURES COMMUNES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream des lectures communes d'un club
  Stream<QuerySnapshot> streamLecturesCommunes(String clubId) {
    return _db
        .collection('lectures_communes')
        .where('clubId', isEqualTo: clubId)
        .snapshots();
  }

  /// Créer une lecture commune
  Future<bool> creerLectureCommune({
    required String clubId,
    required String livreId,
    required String livreTitre,
    required String livreAuteur,
    String livreCouverture = '',
    required DateTime dateDebut,
    required DateTime dateFin,
    int nbChapitres = 0,
  }) async {
    try {
      await _db.collection('lectures_communes').add({
        'clubId': clubId,
        'livreId': livreId,
        'livreTitre': livreTitre,
        'livreAuteur': livreAuteur,
        'livreCouverture': livreCouverture,
        'dateDebut': Timestamp.fromDate(dateDebut),
        'dateFin': Timestamp.fromDate(dateFin),
        'statut': 'planifiee',
        'participantsIds': [],
        'progressionParMembre': {},
        'nbChapitres': nbChapitres,
        'discussionsParChapitre': {},
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Rejoindre une lecture commune
  Future<bool> rejoindreLectureCommune(String lectureId, String membreId) async {
    try {
      await _db.collection('lectures_communes').doc(lectureId).update({
        'participantsIds': FieldValue.arrayUnion([membreId]),
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Mettre à jour la progression d'un membre
  Future<bool> mettreAJourProgression(
      String lectureId, String membreId, int pourcentage) async {
    try {
      await _db.collection('lectures_communes').doc(lectureId).update({
        'progressionParMembre.$membreId': pourcentage,
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VOTES POUR LIVRES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream des votes en cours pour un club
  Stream<QuerySnapshot> streamVotesLivres(String clubId) {
    return _db
        .collection('votes_livres')
        .where('clubId', isEqualTo: clubId)
        .snapshots();
  }

  /// Proposer un livre pour vote
  Future<bool> proposerLivrePourVote({
    required String clubId,
    required String livreId,
    required String livreTitre,
    required String livreAuteur,
    String livreCouverture = '',
    required String proposePar,
    required String proposeParNom,
  }) async {
    try {
      // Vérifier si le livre n'est pas déjà proposé
      final existing = await _db
          .collection('votes_livres')
          .where('clubId', isEqualTo: clubId)
          .where('livreId', isEqualTo: livreId)
          .get();

      if (existing.docs.isNotEmpty) {
        _errorMessage = 'Ce livre est déjà proposé pour ce club';
        notifyListeners();
        return false;
      }

      await _db.collection('votes_livres').add({
        'clubId': clubId,
        'livreId': livreId,
        'livreTitre': livreTitre,
        'livreAuteur': livreAuteur,
        'livreCouverture': livreCouverture,
        'proposePar': proposePar,
        'proposeParNom': proposeParNom,
        'dateProposition': FieldValue.serverTimestamp(),
        'votantsIds': [],
        'nbVotes': 0,
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Voter pour un livre
  Future<bool> voterPourLivre(String voteId, String membreId) async {
    try {
      await _db.collection('votes_livres').doc(voteId).update({
        'votantsIds': FieldValue.arrayUnion([membreId]),
        'nbVotes': FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Retirer son vote
  Future<bool> retirerVote(String voteId, String membreId) async {
    try {
      await _db.collection('votes_livres').doc(voteId).update({
        'votantsIds': FieldValue.arrayRemove([membreId]),
        'nbVotes': FieldValue.increment(-1),
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DÉFIS DE LECTURE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream des défis d'un club
  Stream<QuerySnapshot> streamDefisLecture(String clubId) {
    return _db
        .collection('defis_lecture')
        .where('clubId', isEqualTo: clubId)
        .snapshots();
  }

  /// Créer un défi de lecture
  Future<bool> creerDefiLecture({
    required String clubId,
    required String titre,
    required String description,
    required String type,
    required int objectif,
    String? genreCible,
    required DateTime dateDebut,
    required DateTime dateFin,
  }) async {
    try {
      await _db.collection('defis_lecture').add({
        'clubId': clubId,
        'titre': titre,
        'description': description,
        'type': type,
        'objectif': objectif,
        'genreCible': genreCible,
        'dateDebut': Timestamp.fromDate(dateDebut),
        'dateFin': Timestamp.fromDate(dateFin),
        'progressionParMembre': {},
        'participantsIds': [],
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Rejoindre un défi
  Future<bool> rejoindreDefi(String defiId, String membreId) async {
    try {
      await _db.collection('defis_lecture').doc(defiId).update({
        'participantsIds': FieldValue.arrayUnion([membreId]),
        'progressionParMembre.$membreId': 0,
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Mettre à jour la progression d'un défi
  Future<bool> mettreAJourProgressionDefi(
      String defiId, String membreId, int progression) async {
    try {
      await _db.collection('defis_lecture').doc(defiId).update({
        'progressionParMembre.$membreId': progression,
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BIBLIOTHÈQUE PARTAGÉE DU CLUB
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream de la bibliothèque d'un club
  Stream<QuerySnapshot> streamBibliothequeClub(String clubId) {
    return _db
        .collection('livres_club')
        .where('clubId', isEqualTo: clubId)
        .snapshots();
  }

  /// Ajouter un livre à la bibliothèque du club
  Future<bool> ajouterLivreBibliotheque({
    required String clubId,
    required String livreId,
    required String livreTitre,
    required String livreAuteur,
    String livreCouverture = '',
    required String ajoutePar,
    required String ajouteParNom,
    List<String> tags = const [],
  }) async {
    try {
      // Vérifier si le livre n'est pas déjà dans la bibliothèque
      final existing = await _db
          .collection('livres_club')
          .where('clubId', isEqualTo: clubId)
          .where('livreId', isEqualTo: livreId)
          .get();

      if (existing.docs.isNotEmpty) {
        _errorMessage = 'Ce livre est déjà dans la bibliothèque du club';
        notifyListeners();
        return false;
      }

      await _db.collection('livres_club').add({
        'clubId': clubId,
        'livreId': livreId,
        'livreTitre': livreTitre,
        'livreAuteur': livreAuteur,
        'livreCouverture': livreCouverture,
        'ajoutePar': ajoutePar,
        'ajouteParNom': ajouteParNom,
        'dateAjout': FieldValue.serverTimestamp(),
        'noteClub': 0.0,
        'nbNotations': 0,
        'tags': tags,
        'commentaireClub': null,
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Ajouter un tag à un livre
  Future<bool> ajouterTagLivre(String livreClubId, String tag) async {
    try {
      await _db.collection('livres_club').doc(livreClubId).update({
        'tags': FieldValue.arrayUnion([tag]),
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Mettre à jour le commentaire collectif
  Future<bool> mettreAJourCommentaireClub(
      String livreClubId, String commentaire) async {
    try {
      await _db.collection('livres_club').doc(livreClubId).update({
        'commentaireClub': commentaire,
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}