import 'package:flutter/material.dart';
import 'dart:async';
import '../models/membre.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/message_notification_service.dart';
import '../utils/helpers.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Controller d'authentification (Provider / MVC)
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  Membre? _membre;
  String? _errorMessage;
  StreamSubscription<Membre?>? _membreSubscription;

  // ─── Getters ──────────────────────────────────────────────────────────────
  AuthStatus get status => _status;
  Membre? get membre => _membre;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && (_membre?.estActif ?? false);
  bool get estAdmin => _membre?.estAdmin ?? false;

  // ─── Initialisation ───────────────────────────────────────────────────────
  AuthController() {
    _initAuthState();
  }

  void _initAuthState() {
    _authService.authStateChanges.listen((user) {
      // Annuler l'ancien stream membre si existant
      _membreSubscription?.cancel();

      if (user != null) {
        // Écouter le profil membre en temps réel
        _membreSubscription = _authService.membreStream(user.uid).listen(
          (membre) {
            if (membre != null) {
              _membre = membre;
              // Si suspendu, on garde authenticated mais estActif = false
              _status = AuthStatus.authenticated;
              NotificationService().synchroniserTokenSiConnecte();
              
              // Démarrer l'écoute des notifications de messages
              MessageNotificationService().startListening(membre.uid);
            } else {
              _membre = null;
              _status = AuthStatus.unauthenticated;
              MessageNotificationService().stopListening();
            }
            notifyListeners();
          },
          onError: (_) {
            _status = AuthStatus.unauthenticated;
            MessageNotificationService().stopListening();
            notifyListeners();
          },
        );
      } else {
        _membreSubscription = null;
        _membre = null;
        _status = AuthStatus.unauthenticated;
        MessageNotificationService().stopListening();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _membreSubscription?.cancel();
    super.dispose();
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

  // ─── Connexion avec Google ────────────────────────────────────────────────
  Future<bool> connecterAvecGoogle() async {
    _setLoading();
    try {
      _membre = await _authService.connecterAvecGoogle();
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (code) {
      final codeStr = code.toString();
      if (codeStr == 'user-cancelled') {
        // L'utilisateur a annulé — pas une vraie erreur
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
      } else {
        _status = AuthStatus.error;
        _errorMessage = AppHelpers.traiterErreurFirebase(codeStr);
      }
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
    MessageNotificationService().stopListening();
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

  // ─── Wishlist ─────────────────────────────────────────────────────────────
  Future<bool> toggleWishlist(String livreId) async {
    if (_membre == null) return false;
    final wl = List<String>.from(_membre!.wishlist);
    if (wl.contains(livreId)) {
      wl.remove(livreId);
    } else {
      wl.add(livreId);
    }
    return mettreAJourProfil({'wishlist': wl});
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
