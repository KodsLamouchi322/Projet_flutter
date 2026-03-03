import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/livre_controller.dart';
import '../../models/livre.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/livre_card.dart';
import '../catalogue/livre_detail_view.dart';
import '../admin/admin_dashboard_view.dart';

/// Écran d'accueil — Recommandations + Nouveautés
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
    final livreCtrl = context.watch<LivreController>();
    final membre = auth.membre;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar personnalisée ──
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primaryLight],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(AppSizes.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  Colors.white.withOpacity(0.2),
                              child: Text(
                                membre != null
                                    ? AppHelpers.getInitiales(
                                        membre.nom, membre.prenom)
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bonjour, ${membre?.prenom ?? 'Visiteur'} !',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    auth.estAdmin
                                        ? '👑 Administrateur'
                                        : membre != null
                                            ? '📚 Membre actif'
                                            : 'Bienvenue !',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Bouton admin
                            if (auth.estAdmin)
                              IconButton(
                                icon: const Icon(
                                  Icons.admin_panel_settings,
                                  color: AppColors.accent,
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminDashboardView(),
                                  ),
                                ),
                                tooltip: 'Dashboard Admin',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Contenu ──
          SliverToBoxAdapter(
            child: livreCtrl.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats rapides (pour membres)
                      if (membre != null)
                        _StatsRapides(membre: membre),

                      // Nouveautés
                      _SectionLivres(
                        titre: '🆕 Nouveautés',
                        sousTitre: 'Ajoutés récemment',
                        livres: livreCtrl.nouveautes,
                        onTap: (l) => _voirDetail(context, l),
                      ),

                      // Populaires
                      _SectionLivres(
                        titre: '🔥 Les plus empruntés',
                        sousTitre: 'Appréciés par la communauté',
                        livres: livreCtrl.populaires,
                        onTap: (l) => _voirDetail(context, l),
                      ),

                      // Disponibles maintenant
                      _SectionLivres(
                        titre: '✅ Disponibles maintenant',
                        sousTitre:
                            '${livreCtrl.livresDisponibles.length} livres disponibles',
                        livres: livreCtrl.livresDisponibles.take(10).toList(),
                        onTap: (l) => _voirDetail(context, l),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _voirDetail(BuildContext context, Livre livre) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LivreDetailView(livre: livre)),
    );
  }
}

// ── Stats rapides membres ──────────────────────────────────────────────────────
class _StatsRapides extends StatelessWidget {
  final membre;
  const _StatsRapides({required this.membre});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSizes.paddingMedium),
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icone: Icons.book,
            valeur: '${membre.nbEmpruntsEnCours}',
            label: 'En cours',
          ),
          _divider(),
          _StatItem(
            icone: Icons.history,
            valeur: '${membre.nbEmpruntsTotal}',
            label: 'Total',
          ),
          _divider(),
          _StatItem(
            icone: Icons.favorite,
            valeur: '${membre.wishlist.length}',
            label: 'Wishlist',
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: Colors.white30,
      );
}

class _StatItem extends StatelessWidget {
  final IconData icone;
  final String valeur;
  final String label;
  const _StatItem(
      {required this.icone, required this.valeur, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icone, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          valeur,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

// ── Section livres horizontale ────────────────────────────────────────────────
class _SectionLivres extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final List<Livre> livres;
  final Function(Livre) onTap;

  const _SectionLivres({
    required this.titre,
    required this.sousTitre,
    required this.livres,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (livres.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingMedium,
            AppSizes.paddingMedium,
            AppSizes.paddingMedium,
            4,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre, style: AppTextStyles.headline2),
                    Text(sousTitre,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: AppSizes.livreCardHeight + 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: 8,
            ),
            itemCount: livres.length,
            itemBuilder: (ctx, i) => LivreCard(
              livre: livres[i],
              onTap: () => onTap(livres[i]),
            ),
          ),
        ),
      ],
    );
  }
}
