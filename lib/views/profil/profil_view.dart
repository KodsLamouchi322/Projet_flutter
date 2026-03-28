import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/emprunt_controller.dart';
import '../../controllers/locale_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/membre.dart';
import '../../utils/constants.dart';
import '../../widgets/app_logo.dart';
import '../auth/login_view.dart';
import '../emprunts/emprunts_view.dart';
import 'wishlist_view.dart';
import 'profil_edit_view.dart';

class ProfilView extends StatefulWidget {
  const ProfilView({super.key});
  @override
  State<ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<ProfilView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (auth.membre != null) {
        context.read<EmpruntController>().chargerEmpruntsMembre(auth.membre!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthController>();
    final membre = auth.membre;
    final l10n = AppLocalizations.of(context)!;

    if (membre == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.gradientHero),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const AppLogo(size: 120, showText: true),
                  const SizedBox(height: 40),
                  const Icon(Icons.person_outline_rounded, size: 64, color: Colors.white54),
                  const SizedBox(height: 16),
                  Text(l10n.notConnected,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(l10n.loginToAccess,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.accentDark, AppColors.accent]),
                      borderRadius: BorderRadius.circular(AppSizes.radius),
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginView())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
                      ),
                      child: Text(l10n.login, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.gradientHero),
                child: SafeArea(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(height: 16),
                    // Avatar
                    Container(
                      width: 84, height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.gradientAccent,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: AppUI.cardShadow,
                      ),
                      child: membre.photoUrl.isNotEmpty
                          ? ClipOval(child: Image.network(membre.photoUrl, fit: BoxFit.cover))
                          : Center(
                              child: Text(
                                '${membre.prenom.isNotEmpty ? membre.prenom[0] : ''}${membre.nom.isNotEmpty ? membre.nom[0] : ''}',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    Text('${membre.prenom} ${membre.nom}',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: membre.estAdmin
                            ? AppColors.accent.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: membre.estAdmin
                              ? AppColors.accent.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        membre.estAdmin ? '⭐ Administrateur' : '📚 Membre',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ProfilEditView(membre: membre))),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // Stats
                _StatsCard(membre: membre),
                const SizedBox(height: 16),
                const _LanguageCard(),
                const SizedBox(height: 16),
                // Menu
                _MenuCard(membre: membre),
                const SizedBox(height: 16),
                // Genres
                _GenresCard(membre: membre),
                const SizedBox(height: 16),
                // Déconnexion
                _LogoutButton(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats ────────────────────────────────────────────────────────────────────
class _StatsCard extends StatelessWidget {
  final Membre membre;
  const _StatsCard({required this.membre});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(children: [
      _Stat('${membre.nbEmpruntsEnCours}', l10n.currentLoans, AppColors.gradientCard),
      const SizedBox(width: 10),
      _Stat('${membre.nbEmpruntsTotal}', 'Total', AppColors.gradientAccent),
      const SizedBox(width: 10),
      _Stat(membre.statut == StatutMembre.actif ? 'Actif' : 'Suspendu',
          'Statut', AppColors.gradientWarm),
    ]);
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  final LinearGradient gradient;
  const _Stat(this.value, this.label, this.gradient);

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
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
      ]),
    ),
  );
}

// ─── Langue ───────────────────────────────────────────────────────────────────
class _LanguageCard extends StatelessWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loc = context.watch<LocaleController>();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: AppUI.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.language_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(l10n.language, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text(l10n.languageFrench),
                  selected: loc.locale.languageCode == 'fr',
                  onSelected: (_) =>
                      context.read<LocaleController>().setLocale(const Locale('fr', 'FR')),
                  selectedColor: AppColors.primarySoft,
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: loc.locale.languageCode == 'fr' ? AppColors.primaryDark : null,
                  ),
                ),
                FilterChip(
                  label: Text(l10n.languageEnglish),
                  selected: loc.locale.languageCode == 'en',
                  onSelected: (_) =>
                      context.read<LocaleController>().setLocale(const Locale('en', 'US')),
                  selectedColor: AppColors.accentSoft,
                  checkmarkColor: AppColors.accentDark,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: loc.locale.languageCode == 'en' ? AppColors.accentDark : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Menu ─────────────────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final Membre membre;
  const _MenuCard({required this.membre});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (Icons.bookmark_rounded, l10n.loansTitle, AppColors.primary,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmpruntsView()))),
      (Icons.favorite_rounded, l10n.myWishlist, AppColors.accentDark,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistView()))),
      (Icons.history_rounded, l10n.loanHistory, AppColors.primaryLight,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmpruntsView()))),
      (Icons.edit_rounded, l10n.editProfile, AppColors.accent,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilEditView(membre: membre)))),
    ];

    return Container(
      decoration: AppUI.cardDecoration(context),
      child: Column(
        children: items.asMap().entries.map((e) {
          final (icon, label, color, onTap) = e.value;
          final isLast = e.key == items.length - 1;
          return Column(children: [
            ListTile(
              onTap: onTap,
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            ),
            if (!isLast) Divider(height: 0, indent: 16, endIndent: 16,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
          ]);
        }).toList(),
      ),
    );
  }
}

// ─── Genres ───────────────────────────────────────────────────────────────────
class _GenresCard extends StatelessWidget {
  final Membre membre;
  const _GenresCard({required this.membre});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppUI.cardDecoration(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppColors.accentLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.star_rounded, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Text(l10n.favoriteGenres, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ProfilEditView(membre: membre, focusGenres: true))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(l10n.edit, style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
        if (membre.genresPreferes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: membre.genresPreferes.map((g) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryLight]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(g, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(l10n.noGenreSelected,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ]),
    );
  }
}

// ─── Déconnexion ──────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(l10n.logout),
              content: Text(l10n.logoutConfirm),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  child: Text(l10n.logout),
                ),
              ],
            ),
          );
          if (ok == true && context.mounted) {
            await context.read<AuthController>().deconnecter();
          }
        },
        icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
        label: Text(l10n.logout, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error, width: 1.5),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
        ),
      ),
    );
  }
}
