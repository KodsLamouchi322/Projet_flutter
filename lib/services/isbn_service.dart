import 'dart:convert';
import 'package:http/http.dart' as http;

/// Infos d'un livre récupérées via ISBN
class LivreIsbnInfo {
  final String titre;
  final String auteur;
  final String editeur;
  final int annee;
  final String couvertureUrl;
  final String resume;
  final String isbn;

  const LivreIsbnInfo({
    required this.titre,
    required this.auteur,
    required this.editeur,
    required this.annee,
    required this.couvertureUrl,
    required this.resume,
    required this.isbn,
  });
}

/// Service de récupération automatique des infos livre par ISBN
/// Utilise l'API Open Library (gratuite, sans clé)
class IsbnService {
  static const _baseUrl = 'https://openlibrary.org';

  /// Récupère les infos d'un livre à partir de son ISBN
  static Future<LivreIsbnInfo?> rechercherParIsbn(String isbn) async {
    final clean = isbn.replaceAll(RegExp(r'[\s\-]'), '');
    if (clean.isEmpty) return null;

    try {
      // Open Library Books API
      final url = Uri.parse('$_baseUrl/api/books?bibkeys=ISBN:$clean&format=json&jscmd=data');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final bookKey = 'ISBN:$clean';
      if (!data.containsKey(bookKey)) return null;

      final book = data[bookKey] as Map<String, dynamic>;

      // Titre
      final titre = book['title'] as String? ?? '';

      // Auteur(s)
      final auteurs = book['authors'] as List<dynamic>?;
      final auteur = auteurs != null && auteurs.isNotEmpty
          ? (auteurs.first as Map<String, dynamic>)['name'] as String? ?? ''
          : '';

      // Éditeur
      final publishers = book['publishers'] as List<dynamic>?;
      final editeur = publishers != null && publishers.isNotEmpty
          ? (publishers.first as Map<String, dynamic>)['name'] as String? ?? ''
          : '';

      // Année
      final publishDate = book['publish_date'] as String? ?? '';
      final anneeMatch = RegExp(r'\d{4}').firstMatch(publishDate);
      final annee = anneeMatch != null ? int.tryParse(anneeMatch.group(0)!) ?? 0 : 0;

      // Couverture
      final covers = book['cover'] as Map<String, dynamic>?;
      final couvertureUrl = covers?['large'] as String?
          ?? covers?['medium'] as String?
          ?? covers?['small'] as String?
          ?? '';

      // Résumé (via endpoint séparé si disponible)
      String resume = '';
      final excerpts = book['excerpts'] as List<dynamic>?;
      if (excerpts != null && excerpts.isNotEmpty) {
        resume = (excerpts.first as Map<String, dynamic>)['text'] as String? ?? '';
      }

      return LivreIsbnInfo(
        titre: titre,
        auteur: auteur,
        editeur: editeur,
        annee: annee,
        couvertureUrl: couvertureUrl,
        resume: resume,
        isbn: clean,
      );
    } catch (e) {
      return null;
    }
  }
}
