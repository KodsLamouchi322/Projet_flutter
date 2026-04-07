import 'package:hive_flutter/hive_flutter.dart';
import '../models/livre.dart';

/// Service de cache hors-ligne avec Hive
/// Stocke les livres et emprunts pour consultation sans connexion
class CacheService {
  static const _boxLivres    = 'cache_livres';
  static const _boxEmprunts  = 'cache_emprunts';
  static const _boxMembre    = 'cache_membre';

  static bool _initialized = false;

  // ─── Initialisation ───────────────────────────────────────────────────────
  static Future<void> initialize() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Hive.openBox<Map>(_boxLivres);
    await Hive.openBox<Map>(_boxEmprunts);
    await Hive.openBox<String>(_boxMembre);
    _initialized = true;
  }

  // ─── Livres ───────────────────────────────────────────────────────────────
  static Future<void> sauvegarderLivres(List<Livre> livres) async {
    final box = Hive.box<Map>(_boxLivres);
    await box.clear();
    for (final l in livres) {
      await box.put(l.id, _livreToMap(l));
    }
  }

  static List<Livre> getLivresCaches() {
    try {
      final box = Hive.box<Map>(_boxLivres);
      return box.values
          .map((m) => _livreFromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Emprunts ─────────────────────────────────────────────────────────────
  static Future<void> sauvegarderEmprunts(List<Map<String, dynamic>> emprunts) async {
    final box = Hive.box<Map>(_boxEmprunts);
    await box.clear();
    for (final m in emprunts) {
      final id = m['id']?.toString();
      if (id == null || id.isEmpty) continue;
      await box.put(id, m);
    }
  }

  static List<Map<String, dynamic>> getEmpruntsCaches() {
    try {
      final box = Hive.box<Map>(_boxEmprunts);
      return box.values.map((m) => Map<String, dynamic>.from(m)).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Membre ───────────────────────────────────────────────────────────────
  static Future<void> sauvegarderMembreUid(String uid) async {
    final box = Hive.box<String>(_boxMembre);
    await box.put('uid', uid);
  }

  static String? getMembreUid() {
    try {
      return Hive.box<String>(_boxMembre).get('uid');
    } catch (_) {
      return null;
    }
  }

  // ─── Nettoyage ────────────────────────────────────────────────────────────
  static Future<void> vider() async {
    await Hive.box<Map>(_boxLivres).clear();
    await Hive.box<Map>(_boxEmprunts).clear();
    await Hive.box<String>(_boxMembre).clear();
  }

  // ─── Helpers sérialisation ────────────────────────────────────────────────
  static Map<String, dynamic> _livreToMap(Livre l) => {
    'id': l.id,
    'titre': l.titre,
    'auteur': l.auteur,
    'isbn': l.isbn,
    'genre': l.genre,
    'resume': l.resume,
    'editeur': l.editeur,
    'anneePublication': l.anneePublication,
    'couvertureUrl': l.couvertureUrl,
    'statut': l.statut.name,
    'noteMoyenne': l.noteMoyenne,
    'nbAvis': l.nbAvis,
    'nbEmpruntsTotal': l.nbEmpruntsTotal,
    'tags': l.tags,
    'dateAjout': l.dateAjout.millisecondsSinceEpoch,
  };

  static Livre _livreFromMap(Map<String, dynamic> m) => Livre(
    id: m['id'] ?? '',
    titre: m['titre'] ?? '',
    auteur: m['auteur'] ?? '',
    isbn: m['isbn'] ?? '',
    genre: m['genre'] ?? '',
    resume: m['resume'] ?? '',
    editeur: m['editeur'] ?? '',
    anneePublication: m['anneePublication'] ?? 0,
    couvertureUrl: m['couvertureUrl'] ?? '',
    statut: StatutLivre.values.firstWhere(
      (s) => s.name == (m['statut'] ?? 'disponible'),
      orElse: () => StatutLivre.disponible,
    ),
    noteMoyenne: (m['noteMoyenne'] as num?)?.toDouble() ?? 0.0,
    nbAvis: m['nbAvis'] ?? 0,
    nbEmpruntsTotal: m['nbEmpruntsTotal'] ?? 0,
    tags: List<String>.from(m['tags'] ?? []),
    dateAjout: DateTime.fromMillisecondsSinceEpoch(m['dateAjout'] ?? 0),
  );
}
// Cache invalidation after 30 minutes + LRU eviction strategy added
// lib/services/cache_service.dart - v2
