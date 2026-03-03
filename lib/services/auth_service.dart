import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/membre.dart';
import '../utils/constants.dart';

/// Service d'authentification Firebase
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Utilisateur courant Firebase
  User? get currentUser => _auth.currentUser;

  // Stream de l'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Inscription ──────────────────────────────────────────────────────────
  Future<Membre> inscrire({
    required String email,
    required String motDePasse,
    required String nom,
    required String prenom,
    String telephone = '',
  }) async {
    try {
      // Créer l'utilisateur Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );

      final user = credential.user!;

      // Mettre à jour le display name
      await user.updateDisplayName('$prenom $nom');

      // Créer le profil membre dans Firestore
      final membre = Membre(
        uid: user.uid,
        nom: nom,
        prenom: prenom,
        email: email,
        telephone: telephone,
        dateAdhesion: DateTime.now(),
        role: RoleMembre.membre,
        statut: StatutMembre.actif,
      );

      await _firestore
          .collection(AppConstants.colMembres)
          .doc(user.uid)
          .set(membre.toFirestore());

      return membre;
    } on FirebaseAuthException catch (e) {
      throw e.code;
    }
  }

  // ─── Connexion ────────────────────────────────────────────────────────────
  Future<Membre> connecter({
    required String email,
    required String motDePasse,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );

      final membre = await getMembre(credential.user!.uid);
      if (membre == null) {
        throw 'user-not-found';
      }

      return membre;
    } on FirebaseAuthException catch (e) {
      throw e.code;
    }
  }

  // ─── Déconnexion ──────────────────────────────────────────────────────────
  Future<void> deconnecter() async {
    await _auth.signOut();
  }

  // ─── Mot de passe oublié ──────────────────────────────────────────────────
  Future<void> reinitialiserMotDePasse(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e.code;
    }
  }

  // ─── Récupérer profil membre ──────────────────────────────────────────────
  Future<Membre?> getMembre(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.colMembres)
          .doc(uid)
          .get();
      if (!doc.exists) return null;
      return Membre.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // ─── Stream du profil membre ──────────────────────────────────────────────
  Stream<Membre?> membreStream(String uid) {
    return _firestore
        .collection(AppConstants.colMembres)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? Membre.fromFirestore(doc) : null);
  }

  // ─── Mise à jour du profil ────────────────────────────────────────────────
  Future<void> mettreAJourProfil({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _firestore
        .collection(AppConstants.colMembres)
        .doc(uid)
        .update(data);
  }

  // ─── Changer mot de passe ─────────────────────────────────────────────────
  Future<void> changerMotDePasse({
    required String ancienMdp,
    required String nouveauMdp,
  }) async {
    try {
      final user = _auth.currentUser!;
      // Ré-authentification nécessaire
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: ancienMdp,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(nouveauMdp);
    } on FirebaseAuthException catch (e) {
      throw e.code;
    }
  }
}
