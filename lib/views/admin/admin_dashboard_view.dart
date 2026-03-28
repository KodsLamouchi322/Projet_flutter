import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/livre_controller.dart';
import '../../models/livre.dart';
import '../../l10n/app_localizations.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_logo.dart';
import 'ajouter_livre_view.dart';
import 'admin_evenements_view.dart';
import 'admin_membres_view.dart';
import 'admin_emprunts_view.dart';
import 'admin_reservations_view.dart';
import 'admin_moderation_view.dart';
import 'admin_annonces_view.dart';
import 'admin_clubs_view.dart';

/// Tableau de bord administrateur
class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final _service = FirestoreService();
  Map<String, int> _stats = {};
  bool _loading = true;
  int _empruntsEnRetard = 0;
  int _reservationsEnAttente = 0;
  int _retoursEnAttente = 0;
  int _prolongationsEnAttente = 0;

  @override
  void initState() {
    super.initState();
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    setState(() => _loading = true);
    try {
      _stats = await _service.getStatsGenerales();
      final statsEmprunts = await _service.getStatsEmprunts();
      _empruntsEnRetard = statsEmprunts['enRetard'] ?? 0;
      _reservationsEnAttente = statsEmprunts['reservations'] ?? 0;
      _retoursEnAttente = statsEmprunts['retoursEnAttente'] ?? 0;
      _prolongationsEnAttente = statsEmprunts['prolongationsEnAttente'] ?? 0;
    } catch (e) {
      // ignoré
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportPdfRapport(BuildContext context) async {
    try {
      final top = await _service.getLivresPopulaires(limit: 12);
      final topMaps = top
          .map((l) => {
                'titre': l.titre,
                'auteur': l.auteur,
                'nbEmpruntsTotal': l.nbEmpruntsTotal,
              })
          .toList();
      if (!context.mounted) return;
      await PdfService.genererRapportAdmin(
        context: context,
        stats: _stats,
        topLivres: topMaps,
        periode: 30,
      );
    } catch (e) {
      if (context.mounted) {
        AppHelpers.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    // Sécurité : seulement les admins
    if (!auth.estAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Accès refusé')),
        body: const Center(
          child: Text('Vous n\'avez pas accès à cette section.'),
        ),
      );
    }

    final statsCards = [
      _StatAdminCard(
        titre: 'Total livres',
        valeur: '${_stats['totalLivres'] ?? 0}',
        icone: Icons.menu_book_rounded,
        gradient: AppColors.gradientPrimary,
      ),
      _StatAdminCard(
        titre: 'Disponibles',
        valeur: '${_stats['livresDisponibles'] ?? 0}',
        icone: Icons.check_circle_rounded,
        gradient: AppColors.gradientAccent,
      ),
      _StatAdminCard(
        titre: 'Membres',
        valeur: '${_stats['totalMembres'] ?? 0}',
        icone: Icons.people_rounded,
        gradient: AppColors.gradientPrimary,
      ),
      _StatAdminCard(
        titre: 'Emprunts actifs',
        valeur: '${_stats['empruntsEnCours'] ?? 0}',
        icone: Icons.bookmark_rounded,
        gradient: AppColors.gradientAccent,
      ),
    ];

    final actions = <_AdminActionItem>[
      _AdminActionItem(
        title: 'Ajouter Livre',
        subtitle: 'Créer une nouvelle fiche',
        icon: Icons.add_circle_rounded,
        gradient: AppColors.gradientPrimary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AjouterLivreView()),
        ),
      ),
      _AdminActionItem(
        title: 'Ajouter Annonce',
        subtitle: 'Informer les membres',
        icon: Icons.campaign_rounded,
        gradient: AppColors.gradientAccent,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminAnnoncesView()),
        ),
      ),
      _AdminActionItem(
        title: 'Gérer Emprunts',
        subtitle: 'Valider retours et prêts',
        icon: Icons.library_books_rounded,
        gradient: AppColors.gradientWarm,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminEmpruntsView()),
        ),
      ),
      _AdminActionItem(
        title: 'Gérer Membres',
        subtitle: 'Activer et suspendre',
        icon: Icons.people_rounded,
        gradient: AppColors.gradientPrimary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminMembresView()),
        ),
      ),
      _AdminActionItem(
        title: 'Événements',
        subtitle: 'Calendrier et inscriptions',
        icon: Icons.event_rounded,
        gradient: AppColors.gradientAccent,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminEvenementsView()),
        ),
      ),
      _AdminActionItem(
        title: 'Clubs',
        subtitle: 'Piloter les clubs',
        icon: Icons.groups_rounded,
        gradient: AppColors.gradientPrimary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminClubsView()),
        ),
      ),
      _AdminActionItem(
        title: 'Modération',
        subtitle: 'Avis et messages',
        icon: Icons.shield_rounded,
        gradient: AppColors.gradientWarm,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminModerationView()),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _chargerStats,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppColors.gradientHero),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                      child: Row(
                        children: [
                          AppLogoCompact(size: 58),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bonjour, ${auth.membre?.prenom ?? 'Admin'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.gradientAccent,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text(
                                    'Administrateur',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  tooltip: 'Exporter PDF',
                  onPressed: () => _exportPdfRapport(context),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Actualiser',
                  onPressed: _chargerStats,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_loading &&
                        (_empruntsEnRetard > 0 ||
                            _reservationsEnAttente > 0 ||
                            _retoursEnAttente > 0 ||
                            _prolongationsEnAttente > 0)) ...[
                      const _SectionTitle(titre: 'Alertes'),
                      const SizedBox(height: 8),
                      if (_empruntsEnRetard > 0)
                        _AlertCard(
                          message: '$_empruntsEnRetard emprunt(s) en retard',
                          couleur: AppColors.accentDark,
                          icone: Icons.warning_amber_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminEmpruntsView(
                                mode: AdminEmpruntsMode.enRetard,
                              ),
                            ),
                          ),
                        ),
                      if (_retoursEnAttente > 0)
                        _AlertCard(
                          message: '$_retoursEnAttente retour(s) à confirmer',
                          couleur: AppColors.primary,
                          icone: Icons.assignment_turned_in_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminEmpruntsView(
                                mode: AdminEmpruntsMode.retoursEnAttente,
                              ),
                            ),
                          ),
                        ),
                      if (_reservationsEnAttente > 0)
                        _ReservationsEnAttenteAlert(),
                      if (_prolongationsEnAttente > 0)
                        _AlertCard(
                          message: '$_prolongationsEnAttente demande(s) de prolongation',
                          couleur: AppColors.warning,
                          icone: Icons.update_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminEmpruntsView(
                                mode: AdminEmpruntsMode.prolongationsEnAttente,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],

                    const _SectionTitle(titre: 'Statistiques'),
                    const SizedBox(height: 12),
                    _loading
                        ? const _StatsShimmerGrid()
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: statsCards.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.06,
                            ),
                            itemBuilder: (_, i) => statsCards[i],
                          ),
                    const SizedBox(height: 24),

                    const _SectionTitle(titre: 'Actions rapides'),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: actions.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 100,
                      ),
                      itemBuilder: (_, i) => _AdminActionCard(item: actions[i]),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final String message;
  final Color couleur;
  final IconData icone;
  final VoidCallback onTap;

  const _AlertCard({
    required this.message,
    required this.couleur,
    required this.icone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: couleur.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icone, color: couleur, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: TextStyle(color: couleur, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: couleur),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String titre;
  const _SectionTitle({required this.titre});

  @override
  Widget build(BuildContext context) {
    return Text(
      titre,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ReservationsEnAttenteAlert extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colReservations)
          .where('statut', isEqualTo: 'enAttente')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final count = snap.data!.docs.length;
        if (count <= 0) return const SizedBox.shrink();
        return _AlertCard(
          message: '$count réservation(s) en attente',
          couleur: AppColors.accent,
          icone: Icons.bookmark_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminReservationsView()),
          ),
        );
      },
    );
  }
}

class _StatAdminCard extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icone;
  final LinearGradient gradient;

  const _StatAdminCard({
    required this.titre,
    required this.valeur,
    required this.icone,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppUI.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 2,
            right: 2,
            child: Icon(icone, color: Colors.white.withValues(alpha: 0.45), size: 24),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valeur,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                titre,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsShimmerGrid extends StatelessWidget {
  const _StatsShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.06,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.primary.withValues(alpha: 0.18),
        highlightColor: AppColors.accentLight.withValues(alpha: 0.18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _AdminActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _AdminActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}

class _AdminActionCard extends StatelessWidget {
  final _AdminActionItem item;
  const _AdminActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: item.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppUI.cardShadow,
          ),
          child: Stack(
            children: [
              Positioned(
                top: -4,
                right: -2,
                child: Icon(
                  item.icon,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, color: Colors.white, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFFFF9E6), // Couleur crème/jaune clair
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vue catalogue complet pour l'admin — liste tous les livres avec édition/suppression
class _AdminCatalogueView extends StatefulWidget {
  const _AdminCatalogueView();

  @override
  State<_AdminCatalogueView> createState() => _AdminCatalogueViewState();
}

class _AdminCatalogueViewState extends State<_AdminCatalogueView> {
  final _searchCtrl = TextEditingController();
  List<Livre> _livres = [];
  List<Livre> _filtres = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final snap = await FirestoreService().rechercherLivres('');
      // rechercherLivres('') retourne tout
      _livres = context.read<LivreController>().livres;
      if (_livres.isEmpty) {
        // fallback direct Firestore
        _livres = snap;
      }
      _filtres = List.from(_livres);
    } catch (_) {
      _livres = context.read<LivreController>().livres;
      _filtres = List.from(_livres);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _filtrer(String q) {
    final query = q.toLowerCase();
    setState(() {
      _filtres = _livres
          .where((l) =>
              l.titre.toLowerCase().contains(query) ||
              l.auteur.toLowerCase().contains(query) ||
              l.genre.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Utilise le stream du LivreController
    final livreCtrl = context.watch<LivreController>();
    final source = _searchCtrl.text.isEmpty ? livreCtrl.livres : _filtres;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Catalogue complet'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AjouterLivreView())),
            tooltip: 'Ajouter un livre',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filtrer,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white60),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white60),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filtrer('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
      ),
      body: livreCtrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : source.isEmpty
              ? const Center(
                  child: Text('Aucun livre trouvé',
                      style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  itemCount: source.length,
                  itemBuilder: (_, i) {
                    final livre = source[i];
                    return _LivreAdminTile(livre: livre);
                  },
                ),
    );
  }
}

class _LivreAdminTile extends StatelessWidget {
  final Livre livre;
  const _LivreAdminTile({required this.livre});

  @override
  Widget build(BuildContext context) {
    final statutColor = AppHelpers.couleurStatutLivre(livre.statut.name);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: livre.couvertureUrl.isNotEmpty
              ? Image.network(livre.couvertureUrl,
                  width: 40, height: 56, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
              : _placeholder(),
        ),
        title: Text(livre.titre,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(livre.auteur,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(livre.statutLabel,
                    style: TextStyle(fontSize: 10, color: statutColor, fontWeight: FontWeight.w600)),
              ),
              if (livre.genre.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(livre.genre,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ]),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AjouterLivreView(livre: livre))),
              tooltip: 'Modifier',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              onPressed: () async {
                final ok = await AppHelpers.showConfirmDialog(
                  context: context,
                  titre: 'Supprimer le livre',
                  message: 'Supprimer "${livre.titre}" définitivement ?',
                  confirmLabel: 'Supprimer',
                  confirmColor: AppColors.error,
                );
                if (ok == true && context.mounted) {
                  await context.read<LivreController>().supprimerLivre(livre.id);
                  AppHelpers.showSuccess(context, 'Livre supprimé.');
                }
              },
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 40, height: 56,
        color: AppColors.primary.withOpacity(0.1),
        child: const Icon(Icons.menu_book, size: 20, color: AppColors.primary),
      );
}
