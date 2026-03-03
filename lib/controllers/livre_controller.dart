import 'package:flutter/material.dart';
import '../models/livre.dart';
import '../services/firestore_service.dart';

enum LivreStatus { initial, loading, loaded, error }

/// Controller catalogue livres (Provider / MVC)
class LivreController extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  LivreStatus _status = LivreStatus.initial;
  List<Livre> _livres = [];
  List<Livre> _resultatsRecherche = [];
  String _genreSelectionne = '';
  String _rechercheQuery = '';
  String? _errorMessage;
  bool _rechercheActive = false;

  // ─── Getters ──────────────────────────────────────────────────────────────
  LivreStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == LivreStatus.loading;
  String get genreSelectionne => _genreSelectionne;
  bool get rechercheActive => _rechercheActive;

  List<Livre> get livres {
    if (_rechercheActive) return _resultatsRecherche;
    if (_genreSelectionne.isNotEmpty) {
      return _livres.where((l) => l.genre == _genreSelectionne).toList();
    }
    return _livres;
  }

  List<Livre> get livresDisponibles =>
      _livres.where((l) => l.estDisponible).toList();

  List<Livre> get nouveautes {
    final sorted = List<Livre>.from(_livres)
      ..sort((a, b) => b.dateAjout.compareTo(a.dateAjout));
    return sorted.take(10).toList();
  }

  List<Livre> get populaires {
    final sorted = List<Livre>.from(_livres)
      ..sort((a, b) => b.nbEmpruntsTotal.compareTo(a.nbEmpruntsTotal));
    return sorted.take(10).toList();
  }

  // ─── Init stream ──────────────────────────────────────────────────────────
  void initStream({bool membreConnecte = true}) {
    _status = LivreStatus.loading;
    notifyListeners();

    final stream = membreConnecte
        ? _service.livresStream()
        : _service.livresDisponiblesStream();

    stream.listen(
      (livres) {
        _livres = livres;
        _status = LivreStatus.loaded;
        notifyListeners();
      },
      onError: (e) {
        _status = LivreStatus.error;
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  // ─── Recherche ────────────────────────────────────────────────────────────
  Future<void> rechercher(String query) async {
    _rechercheQuery = query;
    if (query.trim().isEmpty) {
      _rechercheActive = false;
      _resultatsRecherche = [];
      notifyListeners();
      return;
    }

    _rechercheActive = true;
    _status = LivreStatus.loading;
    notifyListeners();

    try {
      _resultatsRecherche = await _service.rechercherLivres(query);
      _status = LivreStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = LivreStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void annulerRecherche() {
    _rechercheActive = false;
    _rechercheQuery = '';
    _resultatsRecherche = [];
    notifyListeners();
  }

  // ─── Filtre par genre ─────────────────────────────────────────────────────
  void filtrerParGenre(String genre) {
    _genreSelectionne = _genreSelectionne == genre ? '' : genre;
    notifyListeners();
  }

  void reinitialiserFiltres() {
    _genreSelectionne = '';
    notifyListeners();
  }

  // ─── CRUD Livres (Admin) ──────────────────────────────────────────────────
  Future<bool> ajouterLivre(Livre livre) async {
    try {
      await _service.ajouterLivre(livre);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> modifierLivre(String id, Map<String, dynamic> data) async {
    try {
      await _service.modifierLivre(id, data);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> supprimerLivre(String id) async {
    try {
      await _service.supprimerLivre(id);
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
