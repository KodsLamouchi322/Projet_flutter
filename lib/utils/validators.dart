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
    if (value.length < 6) {
      return 'Minimum 6 caractères';
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
}