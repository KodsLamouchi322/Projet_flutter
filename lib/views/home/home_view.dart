import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/emprunt_controller.dart';
import '../../controllers/livre_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/livre.dart';
import '../../services/recommandation_service.dart';
import '../../services/scan_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_logo.dart';
import '../catalogue/catalogue_view.dart';
import '../catalogue/livre_detail_view.dart';
import '../clubs/clubs_view.dart';
import '../emprunts/emprunts_view.dart';
import '../evenements/evenements_view.dart';
import '../profil/profil_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  late final AnimationController _heroAnim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      context.read<LivreController>().initStream(
        membreConnecte: auth.isAuthenticated,
      );
      if (auth.membre != null) {
        context.read<EmpruntController>().chargerEmpruntsMembre(auth.membre!.uid);
      }
    });
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthController>();
    final membre = auth.membre;
    final l10n   = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar hero ──
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: AnimatedBuilder(
                animation: _heroAnim,
                builder: (_, __) {
                  final v = _heroAnim.value;
                  return Container(
                    decoration: const BoxDecoration(gradient: AppColors.gradientHero),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          top: -70 + (v * 40),
                          right: -30,
                          child: _HeroGlow(size: 170, opacity: 0.18),
                        ),
                        Positioned(
                          bottom: -80 + (v * 30),
                          left: -45,
                          child: _HeroGlow(size: 190, opacity: 0.13),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  AppLogoCompact(size: 60),
                                  const SizedBox(width: 10),
                                  RichText(
                                    text: const TextSpan(children: [
                                      TextSpan(text: 'Biblio',
                                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                                      TextSpan(text: 'X',
                                          style: TextStyle(color: AppColors.accentLight, fontSize: 20, fontWeight: FontWeight.w800)),
                                    ]),
                                  ),
                                  const Spacer(),
                                  _IconBtn(Icons.person_outline_rounded, () =>
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilView()))),
                                ]),
                                const Spacer(),
                                Text(
                                  membre != null ? 'Bonjour, ${membre.prenom} 👋' : 'Bonjour 👋',
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.homeSubtitle,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 13),
                                ),
                                const SizedBox(height: 14),
                                _QuickActionsRow(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barre recherche
                  _SearchBar(),
                  const SizedBox(height: 16),

                  // Annonces
                  const _AnnoncesSection(),

                  // Stats membre
                  if (membre != null) ...[
                    const SizedBox(height: 16),
                    _StatsRow(membre: membre),
                  ],

                  // Recommandations (historique + genres + wishlist)
                  if (membre != null) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(
                      title: l10n.sectionForYou,
                      icon: Icons.auto_awesome_rounded,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        l10n.sectionForYouSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const _RecommandationsIaSection(),
                  ],

                  // Nouveautés
                  const SizedBox(height: 24),
                  _SectionHeader(title: l10n.sectionNew, icon: Icons.new_releases_rounded, color: AppColors.primaryLight),
                  const SizedBox(height: 12),
                  _NouveautesSection(),

                  // Populaires
                  const SizedBox(height: 24),
                  _SectionHeader(title: l10n.sectionPopular, icon: Icons.trending_up_rounded, color: AppColors.accentDark),
                  const SizedBox(height: 12),
                  _PopulairesSection(),

                  // Genres
                  const SizedBox(height: 24),
                  _SectionHeader(title: l10n.sectionGenres, icon: Icons.grid_view_rounded, color: AppColors.primary),
                  const SizedBox(height: 12),
                  _GenresGrid(),

                  // Clubs de lecture
                  const SizedBox(height: 24),
                  _SectionHeader(title: l10n.sectionClubs, icon: Icons.groups_rounded, color: AppColors.accentDark,
                      onMoreRoute: const ClubsView()),
                  const SizedBox(height: 12),
                  _ClubsTeaser(),
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

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _HeroGlow extends StatelessWidget {
  final double size;
  final double opacity;
  const _HeroGlow({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickActionChip(
            icon: Icons.library_add_rounded,
            label: 'Emprunter',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CatalogueView()),
            ),
          ),
          _QuickActionChip(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scanner ISBN',
            onTap: () async {
              final isbn = await ScanService.scanner(context, titre: 'Scanner ISBN');
              if (!context.mounted || isbn == null || isbn.isEmpty) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ISBN scanné : $isbn')),
              );
            },
          ),
          _QuickActionChip(
            icon: Icons.bookmark_rounded,
            label: 'Mes réservations',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmpruntsView()),
            ),
          ),
          _QuickActionChip(
            icon: Icons.event_rounded,
            label: 'Événements',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EvenementsView()),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppColors.gradientAccent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Barre de recherche ───────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogueView())),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)),
          boxShadow: AppUI.softShadow,
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 10),
          Text(l10n.homeSearchHint,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
          const Spacer(),
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentLight]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 16),
          ),
        ]),
      ),
    );
  }
}

// ─── Annonces ─────────────────────────────────────────────────────────────────
class _AnnoncesSection extends StatelessWidget {
  const _AnnoncesSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('annonces')
          .where('active', isEqualTo: true).snapshots(),
      builder: (_, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox();
        final docs = snap.data!.docs.toList()
          ..sort((a, b) {
            final at = (a.data() as Map)['createdAt'];
            final bt = (b.data() as Map)['createdAt'];
            if (at == null) return 1;
            if (bt == null) return -1;
            return (bt as Timestamp).compareTo(at as Timestamp);
          });
        return Column(
          children: docs.take(2).map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['type'] ?? 'info';
            final (color, icon) = switch (type) {
              'warning' => (AppColors.warning, Icons.warning_amber_rounded),
              'success' => (AppColors.success, Icons.check_circle_outline_rounded),
              _ => (AppColors.primary, Icons.campaign_rounded),
            };
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radius),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['titre'] ?? '',
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                    if ((data['contenu'] ?? '').isNotEmpty)
                      Text(data['contenu'],
                          style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12)),
                  ],
                )),
              ]),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Stats membre ─────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final dynamic membre;
  const _StatsRow({required this.membre});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StatCard(value: '${membre.nbEmpruntsEnCours}', label: 'En cours',
          gradient: AppColors.gradientCard),
      const SizedBox(width: 10),
      _StatCard(value: '${membre.wishlist?.length ?? 0}', label: 'Wishlist',
          gradient: AppColors.gradientAccent),
      const SizedBox(width: 10),
      _StatCard(value: '${membre.nbEmpruntsTotal}', label: 'Total lus',
          gradient: AppColors.gradientWarm),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final LinearGradient gradient;
  const _StatCard({required this.value, required this.label, required this.gradient});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        boxShadow: AppUI.cardShadow,
      ),
      child: Column(children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

// ─── En-tête section ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget? onMoreRoute;
  const _SectionHeader({required this.title, required this.icon, required this.color, this.onMoreRoute});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(children: [
    Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    ),
    const SizedBox(width: 10),
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
    const Spacer(),
    GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => onMoreRoute ?? const CatalogueView(),
      )),
      child: Text(l10n.seeAll, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    ),
  ]);
  }
}

// ─── Recommandations (score historique / genres / wishlist) ───────────────────
class _RecommandationsIaSection extends StatelessWidget {
  const _RecommandationsIaSection();

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthController, LivreController, EmpruntController>(
      builder: (_, auth, livreCtrl, empCtrl, __) {
        final membre = auth.membre;
        if (membre == null) return const SizedBox.shrink();

        final lus = empCtrl.historique.map((e) => e.livreId).toList();
        final rec = RecommandationService.recommander(
          tousLesLivres: livreCtrl.livres,
          genresPreferes: membre.genresPreferes,
          livresDejaEmpruntes: lus,
          wishlist: membre.wishlist,
          limite: 12,
        );

        if (rec.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Empruntez quelques livres pour affiner vos suggestions.',
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          );
        }

        return SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: rec.length,
            itemBuilder: (_, i) => _LivreMiniCard(livre: rec[i]),
          ),
        );
      },
    );
  }
}

// ─── Nouveautés ───────────────────────────────────────────────────────────────
class _NouveautesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LivreController>(builder: (_, ctrl, __) {
      if (ctrl.isLoading) return const Center(child: CircularProgressIndicator());
      final livres = ctrl.livres.take(8).toList();
      if (livres.isEmpty) return const SizedBox();
      return SizedBox(
        height: 210,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: livres.length,
          itemBuilder: (_, i) => _LivreMiniCard(livre: livres[i]),
        ),
      );
    });
  }
}

// ─── Populaires ───────────────────────────────────────────────────────────────
class _PopulairesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LivreController>(builder: (_, ctrl, __) {
      final top = ctrl.livres.where((l) => l.nbEmpruntsTotal > 0).toList()
        ..sort((a, b) => b.nbEmpruntsTotal.compareTo(a.nbEmpruntsTotal));
      if (top.isEmpty) return const SizedBox();
      return Column(
        children: top.take(5).toList().asMap().entries
            .map((e) => _LivreRankItem(livre: e.value, rank: e.key + 1))
            .toList(),
      );
    });
  }
}

// ─── Carte mini livre ─────────────────────────────────────────────────────────
class _LivreMiniCard extends StatelessWidget {
  final Livre livre;
  const _LivreMiniCard({required this.livre});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LivreDetailView(livre: livre))),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                  color: AppColors.primarySoft,
                  boxShadow: AppUI.softShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: livre.couvertureUrl.isNotEmpty
                    ? Image.network(livre.couvertureUrl, fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              // Badge disponible
              Positioned(
                top: 6, left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: livre.estDisponible ? AppColors.success : AppColors.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    livre.estDisponible ? 'Dispo' : 'Emprunté',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              // Wishlist
              Positioned(
                top: 6, right: 6,
                child: Consumer<AuthController>(builder: (ctx, auth, _) {
                  if (!auth.isAuthenticated) return const SizedBox();
                  final inWl = auth.membre!.wishlist.contains(livre.id);
                  return GestureDetector(
                    onTap: () => auth.toggleWishlist(livre.id),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(inWl ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 14, color: inWl ? Colors.red : AppColors.textSecondary),
                    ),
                  );
                }),
              ),
            ]),
            const SizedBox(height: 7),
            Text(livre.titre, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            Text(livre.auteur, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.primarySoft,
    child: const Center(child: Icon(Icons.menu_book_rounded, size: 36, color: AppColors.primary)),
  );
}

// ─── Classement ───────────────────────────────────────────────────────────────
class _LivreRankItem extends StatelessWidget {
  final Livre livre;
  final int rank;
  const _LivreRankItem({required this.livre, required this.rank});

  @override
  Widget build(BuildContext context) {
    final rankGradients = [
      AppColors.gradientAccent,
      const LinearGradient(colors: [Color(0xFF78909C), Color(0xFF90A4AE)]),
      AppColors.gradientWarm,
    ];
    final grad = rank <= 3 ? rankGradients[rank - 1] : null;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LivreDetailView(livre: livre))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: AppUI.cardDecoration(context),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: grad,
              color: grad == null ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text('$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: grad != null ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                ))),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 38, height: 52,
              color: AppColors.primarySoft,
              child: livre.couvertureUrl.isNotEmpty
                  ? Image.network(livre.couvertureUrl, fit: BoxFit.cover)
                  : const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(livre.titre, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(livre.auteur,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
              if (livre.nbAvis > 0) Row(children: [
                const Icon(Icons.star_rounded, color: AppColors.accent, size: 13),
                const SizedBox(width: 2),
                Text(livre.noteMoyenne.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ],
          )),
          Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ]),
      ),
    );
  }
}

// ─── Grille genres ────────────────────────────────────────────────────────────
class _GenresGrid extends StatelessWidget {
  static const _genres = [
    {'label': 'Roman',    'icon': Icons.auto_stories_rounded,  'gradient': AppColors.gradientCard},
    {'label': 'Policier', 'icon': Icons.search_rounded,        'gradient': AppColors.gradientWarm},
    {'label': 'Sci-Fi',   'icon': Icons.rocket_launch_rounded, 'gradient': AppColors.gradientAccent},
    {'label': 'Fantasy',  'icon': Icons.auto_fix_high_rounded, 'gradient': AppColors.gradientPrimary},
    {'label': 'Jeunesse', 'icon': Icons.child_care_rounded,    'gradient': AppColors.gradientAccent},
    {'label': 'Histoire', 'icon': Icons.history_edu_rounded,   'gradient': AppColors.gradientCard},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.15,
      ),
      itemCount: _genres.length,
      itemBuilder: (_, i) {
        final g = _genres[i];
        return GestureDetector(
          onTap: () {
            context.read<LivreController>().filtrerParGenre(g['label'] as String);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogueView()));
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: g['gradient'] as LinearGradient,
              borderRadius: BorderRadius.circular(AppSizes.radius),
              boxShadow: AppUI.cardShadow,
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(g['icon'] as IconData, color: Colors.white, size: 26),
              const SizedBox(height: 6),
              Text(g['label'] as String,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        );
      },
    );
  }
}

// ─── Aperçu clubs de lecture ──────────────────────────────────────────────────
class _ClubsTeaser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClubsView())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.gradientCard,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          boxShadow: AppUI.cardShadow,
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.sectionClubs,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            Text(l10n.clubsEmptyHint,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, height: 1.4)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
        ]),
      ),
    );
  }
}
