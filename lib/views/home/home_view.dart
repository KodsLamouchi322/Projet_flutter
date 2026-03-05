import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/livre_controller.dart';
import '../../models/livre.dart';
import '../../utils/constants.dart';
import '../catalogue/livre_detail_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      context.read<LivreController>().initStream(
            membreConnecte: auth.isAuthenticated,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final membre = auth.membre;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // AppBar personnalisée
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_library,
                                color: Colors.white, size: 28),
                            const SizedBox(width: 10),
                            const Text(
                              'Bibliothèque',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined,
                                  color: Colors.white),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          membre != null
                              ? 'Bonjour, ${membre.prenom} 👋'
                              : 'Bienvenue !',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Que souhaitez-vous lire aujourd\'hui ?',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barre de recherche rapide
                  _SearchBar(),
                  const SizedBox(height: 24),

                  // Statistiques rapides
                  if (membre != null) ...[
                    _StatsRow(membre: membre),
                    const SizedBox(height: 24),
                  ],

                  // Nouveautés
                  _SectionHeader(
                    title: 'Nouveautés',
                    icon: Icons.new_releases_outlined,
                    color: AppColors.accent,
                    onMore: () {},
                  ),
                  const SizedBox(height: 12),
                  _NouveautesSection(),
                  const SizedBox(height: 24),

                  // Populaires
                  _SectionHeader(
                    title: 'Les plus empruntés',
                    icon: Icons.trending_up,
                    color: AppColors.primary,
                    onMore: () {},
                  ),
                  const SizedBox(height: 12),
                  _PopulairesSection(),
                  const SizedBox(height: 24),

                  // Genres
                  _SectionHeader(
                    title: 'Parcourir par genre',
                    icon: Icons.category_outlined,
                    color: AppColors.primaryLight,
                    onMore: null,
                  ),
                  const SizedBox(height: 12),
                  _GenresGrid(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Barre de recherche ───────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Naviguer vers catalogue avec focus recherche
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(
              'Rechercher un livre, auteur...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats du membre ──────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final dynamic membre;
  const _StatsRow({required this.membre});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          value: '${membre.nbEmpruntsEnCours}',
          label: 'En cours',
          icon: Icons.book_outlined,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          value: '${membre.wishlist?.length ?? 0}',
          label: 'Wishlist',
          icon: Icons.favorite_outline,
          color: AppColors.accent,
        ),
        const SizedBox(width: 12),
        _StatCard(
          value: '${membre.nbEmpruntsTotal}',
          label: 'Total lus',
          icon: Icons.auto_stories_outlined,
          color: AppColors.accentDark,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── En-tête de section ───────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onMore;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (onMore != null)
          TextButton(
            onPressed: onMore,
            child: const Text(
              'Voir tout',
              style: TextStyle(color: AppColors.accent, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

// ─── Nouveautés (liste horizontale) ──────────────────────────────────────────
class _NouveautesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LivreController>(
      builder: (_, ctrl, __) {
        if (ctrl.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final livres = ctrl.livres.take(8).toList();
        if (livres.isEmpty) {
          return _EmptyState(message: 'Aucun livre disponible');
        }
        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: livres.length,
            itemBuilder: (_, i) => _LivreMiniCard(livre: livres[i]),
          ),
        );
      },
    );
  }
}

class _PopulairesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LivreController>(
      builder: (_, ctrl, __) {
        final livres = ctrl.livres
            .where((l) => l.nbEmpruntsTotal > 0)
            .toList()
          ..sort((a, b) => b.nbEmpruntsTotal.compareTo(a.nbEmpruntsTotal));
        final top = livres.take(5).toList();
        if (top.isEmpty) return const SizedBox();
        return Column(
          children: top
              .asMap()
              .entries
              .map((e) => _LivreRankItem(livre: e.value, rank: e.key + 1))
              .toList(),
        );
      },
    );
  }
}

// ─── Carte mini livre ─────────────────────────────────────────────────────────
class _LivreMiniCard extends StatelessWidget {
  final Livre livre;
  const _LivreMiniCard({required this.livre});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LivreDetailView(livre: livre)),
      ),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Couverture
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primaryLight.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: livre.couvertureUrl.isNotEmpty
                  ? Image.network(
                      livre.couvertureUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderCover(),
                    )
                  : _placeholderCover(),
            ),
            const SizedBox(height: 8),
            Text(
              livre.titre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              livre.auteur,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            // Statut disponibilité
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: livre.estDisponible
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                livre.estDisponible ? 'Disponible' : 'Emprunté',
                style: TextStyle(
                  fontSize: 10,
                  color: livre.estDisponible
                      ? AppColors.success
                      : AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderCover() {
    return Container(
      color: AppColors.primary.withOpacity(0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book, size: 40, color: AppColors.primary),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              livre.titre,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: const TextStyle(fontSize: 10, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Classement populaires ────────────────────────────────────────────────────
class _LivreRankItem extends StatelessWidget {
  final Livre livre;
  final int rank;
  const _LivreRankItem({required this.livre, required this.rank});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LivreDetailView(livre: livre)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            )
          ],
        ),
        child: Row(
          children: [
            // Rang
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? AppColors.accent
                    : AppColors.divider,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rank <= 3
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Couverture mini
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 40,
                height: 54,
                color: AppColors.primary.withOpacity(0.1),
                child: livre.couvertureUrl.isNotEmpty
                    ? Image.network(livre.couvertureUrl, fit: BoxFit.cover)
                    : const Icon(Icons.menu_book,
                        color: AppColors.primary, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(livre.titre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(livre.auteur,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  Row(children: [
                    const Icon(Icons.star, color: AppColors.accent, size: 14),
                    const SizedBox(width: 2),
                    Text(livre.noteMoyenne.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12)),
                  ]),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── Grille genres ────────────────────────────────────────────────────────────
class _GenresGrid extends StatelessWidget {
  final List<Map<String, dynamic>> _genres = const [
    {'label': 'Roman', 'icon': Icons.auto_stories, 'color': Color(0xFF3498DB)},
    {'label': 'Policier', 'icon': Icons.search, 'color': Color(0xFF2C3E50)},
    {'label': 'Sci-Fi', 'icon': Icons.rocket_launch, 'color': Color(0xFF9B59B6)},
    {'label': 'Fantasy', 'icon': Icons.auto_fix_high, 'color': Color(0xFF1ABC9C)},
    {'label': 'Jeunesse', 'icon': Icons.child_care, 'color': Color(0xFFE67E22)},
    {'label': 'Histoire', 'icon': Icons.history_edu, 'color': Color(0xFFC0392B)},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: _genres.length,
      itemBuilder: (_, i) {
        final g = _genres[i];
        return GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              color: (g['color'] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (g['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(g['icon'] as IconData,
                    color: g['color'] as Color, size: 28),
                const SizedBox(height: 6),
                Text(
                  g['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: g['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(message,
            style: const TextStyle(color: AppColors.textSecondary)),
      );
}
