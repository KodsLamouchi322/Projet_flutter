import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/club_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/club_lecture.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state_widget.dart';
import 'club_detail_view.dart';
import 'creer_club_flow.dart';

class ClubsView extends StatefulWidget {
  final bool embeddedInCommunity;
  const ClubsView({super.key, this.embeddedInCommunity = false});

  const ClubsView.embedded({super.key}) : embeddedInCommunity = true;

  const ClubsView.standalone({super.key}) : embeddedInCommunity = false;

  @override
  State<ClubsView> createState() => _ClubsViewState();
}

class _ClubsViewState extends State<ClubsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClubController>().chargerClubs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final ctrl = context.watch<ClubController>();
    final l10n = AppLocalizations.of(context)!;

    // Afficher l'erreur si présente
    if (ctrl.errorMessage != null && ctrl.errorMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ctrl.errorMessage!),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () => ctrl.clearError(),
              ),
            ),
          );
          ctrl.clearError();
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: ctrl.chargerClubs,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          if (!widget.embeddedInCommunity)
            SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 12, end: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.clubsTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                    'Rejoignez un groupe de lecture',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.gradientHero),
              ),
            ),
          )
          else
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppUI.softShadow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.clubsTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Rejoignez un groupe de lecture',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (ctrl.isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (ctrl.clubs.isEmpty)
            SliverFillRemaining(child: _EmptyClubs())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ClubCard(club: ctrl.clubs[i]),
                  ),
                  childCount: ctrl.clubs.length,
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  final ClubLecture club;
  const _ClubCard({required this.club});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final uid = auth.membre?.uid ?? '';
    final estMembre = club.estMembre(uid);
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClubDetailView(club: club)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surface,
            border: const Border.fromBorderSide(
              BorderSide(color: AppColors.divider, width: 0.5),
            ),
            boxShadow: AppUI.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 5,
                decoration: const BoxDecoration(
                  gradient: AppColors.gradientAccent,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPrimary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                club.nom,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, height: 1.2),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                club.livreTitre,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                club.livreAuteur,
                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        if (estMembre) AppUI.badge('Membre', AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      club.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, height: 1.35, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.people_alt_outlined, size: 16, color: AppColors.accentDark),
                        const SizedBox(width: 6),
                        Text(
                          l10n.clubsMembers(club.nbMembres),
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary.withValues(alpha: 0.5)),
                      ],
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

class _EmptyClubs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyStateWidget(
      icon: Icons.groups_rounded,
      title: l10n.clubsEmpty,
      subtitle: l10n.clubsEmptyHint,
    );
  }
}
