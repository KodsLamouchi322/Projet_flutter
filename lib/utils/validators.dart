/// Validateurs de formulaires pour toute l'application
class AppValidators {
  // ─── Email ─────────────────────────────────────────────────────────────────
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'email est obligatoire';
    }
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Entrez un email valide';
    }
    return null;
  }

  // ─── Mot de passe ──────────────────────────────────────────────────────────
  static String? motDePasse(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est obligatoire';
    }
    if (value.length < 8) {
      return 'Minimum 8 caractères requis';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Au moins une lettre majuscule requise';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Au moins une lettre minuscule requise';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Au moins un chiffre requis';
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value)) {
      return 'Au moins un caractère spécial requis (!@#\$%...)';
    }
    return null;
  }

  static String? confirmerMotDePasse(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Confirmez votre mot de passe';
    }
    if (value != original) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  // ─── Champs texte ─────────────────────────────────────────────────────────
  static String? required(String? value, {String label = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label est obligatoire';
    }
    return null;
  }

  static String? nom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom est obligatoire';
    }
    if (value.trim().length < 2) {
      return 'Minimum 2 caractères';
    }
    return null;
  }

  static String? prenom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le prénom est obligatoire';
    }
    if (value.trim().length < 2) {
      return 'Minimum 2 caractères';
    }
    return null;
  }

  // ─── Téléphone ─────────────────────────────────────────────────────────────
  static String? telephone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // optionnel
    }
    final regex = RegExp(r'^\+?[\d\s\-]{8,15}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  // ─── ISBN ──────────────────────────────────────────────────────────────────
  static String? isbn(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // optionnel
    }
    final clean = value.replaceAll('-', '').replaceAll(' ', '');
    if (clean.length != 10 && clean.length != 13) {
      return 'ISBN doit avoir 10 ou 13 chiffres';
    }
    return null;
  }

  // ─── Année ─────────────────────────────────────────────────────────────────
  static String? annee(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // optionnel
    }
    final annee = int.tryParse(value.trim());
    if (annee == null) {
      return 'Entrez une année valide';
    }
    final now = DateTime.now().year;
    if (annee < 1000 || annee > now + 1) {
      return 'Année entre 1000 et $now';
    }
    return null;
  }
}// lib/utils/validators.dart - UPDATED v2
// Added ISBN-13 checksum validation and phone validation

class IsbnValidator {
  static bool validateIsbn13Checksum(String isbn) {
    if (isbn.length != 13) return false;
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      int digit = int.parse(isbn[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    int checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(isbn[12]);
  }

  static bool validateIsbn10(String isbn) {
    if (isbn.length != 10) return false;
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += (i + 1) * int.parse(isbn[i]);
    }
    return sum % 11 == int.parse(isbn[9]);
  }
}
