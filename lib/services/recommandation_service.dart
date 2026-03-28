import '../models/livre.dart';

/// Service de recommandations basé sur l'historique d'emprunt
/// Algorithme simple mais efficace : scoring par genre + popularité + nouveauté
class RecommandationService {

  /// Génère une liste de livres recommandés pour un membre
  /// basée sur ses genres préférés et son historique d'emprunt
  static List<Livre> recommander({
    required List<Livre> tousLesLivres,
    required List<String> genresPreferes,
    required List<String> livresDejaEmpruntes, // IDs des livres déjà lus
    required List<String> wishlist,            // IDs en wishlist
    int limite = 10,
  }) {
    // Exclure les livres déjà empruntés et non disponibles
    final candidats = tousLesLivres.where((l) =>
      !livresDejaEmpruntes.contains(l.id) &&
      l.estDisponible
    ).toList();

    if (candidats.isEmpty) return [];

    // Calculer un score pour chaque livre
    final scores = <String, double>{};

    for (final livre in candidats) {
      double score = 0;

      // +40 si genre préféré
      if (genresPreferes.contains(livre.genre)) score += 40;

      // +20 si dans la wishlist
      if (wishlist.contains(livre.id)) score += 20;

      // +0 à +20 selon popularité (normalisé sur max 100 emprunts)
      final popularite = (livre.nbEmpruntsTotal / 100).clamp(0.0, 1.0);
      score += popularite * 20;

      // +0 à +15 selon note moyenne
      if (livre.nbAvis > 0) {
        score += (livre.noteMoyenne / 5) * 15;
      }

      // +0 à +5 selon nouveauté (livres ajoutés dans les 90 derniers jours)
      final joursDepuisAjout = DateTime.now().difference(livre.dateAjout).inDays;
      if (joursDepuisAjout <= 90) {
        score += (1 - joursDepuisAjout / 90) * 5;
      }

      scores[livre.id] = score;
    }

    // Trier par score décroissant
    candidats.sort((a, b) =>
      (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0)
    );

    return candidats.take(limite).toList();
  }

  /// Recommandations basées uniquement sur les genres similaires
  /// (pour les nouveaux membres sans historique)
  static List<Livre> recommanderParGenre({
    required List<Livre> tousLesLivres,
    required String genre,
    required List<String> exclure,
    int limite = 6,
  }) {
    final list = tousLesLivres
        .where((l) =>
            l.genre == genre &&
            l.estDisponible &&
            !exclure.contains(l.id))
        .toList();
    list.sort((a, b) => b.nbEmpruntsTotal.compareTo(a.nbEmpruntsTotal));
    return list.take(limite).toList();
  }

  /// "Les membres qui ont lu X ont aussi aimé..."
  static List<Livre> recommanderSimilaires({
    required List<Livre> tousLesLivres,
    required Livre livre,
    required List<String> exclure,
    int limite = 4,
  }) {
    final list = tousLesLivres
        .where((l) =>
            l.id != livre.id &&
            l.genre == livre.genre &&
            l.estDisponible &&
            !exclure.contains(l.id))
        .toList();
    list.sort((a, b) {
      if (a.auteur == livre.auteur && b.auteur != livre.auteur) return -1;
      if (b.auteur == livre.auteur && a.auteur != livre.auteur) return 1;
      return b.noteMoyenne.compareTo(a.noteMoyenne);
    });
    return list.take(limite).toList();
  }
}
