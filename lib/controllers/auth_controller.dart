import 'package:flutter/material.dart';
import '../models/membre.dart';
import '../services/auth_service.dart';
import '../utils/helpers.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Controller d'authentification (Provider / MVC)
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  Membre? _membre;
  String? _errorMessage;

  // ─── Getters ──────────────────────────────────────────────────────────────
  AuthStatus get status => _status;
  Membre? get membre => _membre;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get estAdmin => _membre?.estAdmin ?? false;

  // ─── Initialisation ───────────────────────────────────────────────────────
  AuthController() {
    _initAuthState();
  }

  void _initAuthState() {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        final membre = await _authService.getMembre(user.uid);
        if (membre != null) {
          _membre = membre;
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _membre = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  // ─── Connexion ────────────────────────────────────────────────────────────
  Future<bool> connecter({
    required String email,
    required String motDePasse,
  }) async {
    _setLoading();
    try {
      _membre = await _authService.connecter(
        email: email,
        motDePasse: motDePasse,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (code) {
      _status = AuthStatus.error;
      _errorMessage = AppHelpers.traiterErreurFirebase(code.toString());
      notifyListeners();
      return false;
    }
  }

  // ─── Inscription ──────────────────────────────────────────────────────────
  Future<bool> inscrire({
    required String email,
    required String motDePasse,
    required String nom,
    required String prenom,
    String telephone = '',
  }) async {
    _setLoading();
    try {
      _membre = await _authService.inscrire(
        email: email,
        motDePasse: motDePasse,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (code) {
      _status = AuthStatus.error;
      _errorMessage = AppHelpers.traiterErreurFirebase(code.toString());
      notifyListeners();
      return false;
    }
  }

  // ─── Déconnexion ──────────────────────────────────────────────────────────
  Future<void> deconnecter() async {
    await _authService.deconnecter();
    _membre = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ─── Mot de passe oublié ──────────────────────────────────────────────────
  Future<bool> reinitialiserMotDePasse(String email) async {
    _setLoading();
    try {
      await _authService.reinitialiserMotDePasse(email);
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (code) {
      _status = AuthStatus.error;
      _errorMessage = AppHelpers.traiterErreurFirebase(code.toString());
      notifyListeners();
      return false;
    }
  }

  // ─── Mise à jour du profil ────────────────────────────────────────────────
  Future<bool> mettreAJourProfil(Map<String, dynamic> data) async {
    if (_membre == null) return false;
    _setLoading();
    try {
      await _authService.mettreAJourProfil(uid: _membre!.uid, data: data);
      // Recharger le membre
      final updated = await _authService.getMembre(_membre!.uid);
      _membre = updated;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = AppHelpers.traiterErreurFirebase(e.toString());
      notifyListeners();
      return false;
    }
  }

  // ─── Privé ────────────────────────────────────────────────────────────────
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
