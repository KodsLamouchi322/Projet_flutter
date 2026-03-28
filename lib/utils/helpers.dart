import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

/// Fonctions utilitaires partagées dans l'application
class AppHelpers {
  // ─── Formatage dates ───────────────────────────────────────────────────────
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  static String formatDateLong(DateTime date) {
    return DateFormat('d MMMM yyyy', 'fr_FR').format(date);
  }

  static String formatDateHeure(DateTime date) {
    return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(date);
  }

  static String formatDateRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    if (diff.inDays < 30) return 'Il y a ${(diff.inDays / 7).round()} semaine(s)';
    return formatDate(date);
  }

  // ─── Calcul date retour ───────────────────────────────────────────────────
  static DateTime calculerDateRetour({DateTime? dateDebut, int dureeJours = AppConstants.dureeEmpruntJours}) {
    final debut = dateDebut ?? DateTime.now();
    return debut.add(Duration(days: dureeJours));
  }

  // ─── Couleurs statut ─────────────────────────────────────────────────────
  static Color couleurStatutLivre(String statut) {
    switch (statut) {
      case 'disponible':
        return AppColors.success;
      case 'emprunte':
        return AppColors.error;
      case 'reserve':
        return AppColors.warning;
      case 'endommage':
        return Colors.grey;
      default:
        return AppColors.textSecondary;
    }
  }

  static Color couleurStatutEmprunt(String statut) {
    switch (statut) {
      case 'enCours':
        return AppColors.info;
      case 'retourne':
        return AppColors.success;
      case 'enRetard':
        return AppColors.error;
      case 'prolonge':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  // ─── SnackBar helpers ─────────────────────────────────────────────────────
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
        ),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
        ),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
        ),
      ),
    );
  }

  // ─── Dialog de confirmation ───────────────────────────────────────────────
  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String titre,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    Color confirmColor = AppColors.primary,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titre),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  // ─── Gestion des erreurs Firebase ─────────────────────────────────────────
  static String traiterErreurFirebase(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte associé à cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email.';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'weak-password':
        return 'Mot de passe trop faible (minimum 6 caractères).';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion.';
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'sign_in_failed':
      case 'sign_in_canceled':
        return 'Connexion Google annulée.';
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec cet email via une autre méthode.';
      default:
        if (code.contains('network') || code.contains('Network')) {
          return AppConstants.erreurReseau;
        }
        if (code.contains('cancelled') || code.contains('canceled')) {
          return 'Connexion annulée.';
        }
        return AppConstants.erreurInconnu;
    }
  }

  // ─── Initiales du nom ─────────────────────────────────────────────────────
  static String getInitiales(String nom, String prenom) {
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    return '$p$n';
  }
}