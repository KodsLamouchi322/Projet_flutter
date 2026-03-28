import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/club_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/club_lecture.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../clubs/club_detail_view.dart';
import '../clubs/creer_club_flow.dart';

/// Liste et modération des clubs (admin)
class AdminClubsView extends StatefulWidget {
  const AdminClubsView({super.key});

  @override
  State<AdminClubsView> createState() => _AdminClubsViewState();
}

class _AdminClubsViewState extends State<AdminClubsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClubController>().chargerTousLesClubsAdmin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final ctrl = context.watch<ClubController>();
    final l10n = AppLocalizations.of(context)!;

    if (!auth.estAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.adminClubsTitle)),
        body: const Center(child: Text('Accès refusé')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.adminClubsTitle),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.clubsCreate,
            onPressed: () => openCreerClubFlow(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ctrl.chargerTousLesClubsAdmin(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openCreerClubFlow(context),
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF1A1A1A), // Texte noir foncé
        icon: const Icon(Icons.add_rounded, color: Color(0xFF1A1A1A)),
        label: Text(l10n.clubsCreate, style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w800)),
      ),
      body: ctrl.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ctrl.clubs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.groups_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.35)),
                        const SizedBox(height: 12),
                        Text(l10n.clubsEmpty, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => openCreerClubFlow(context),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(l10n.clubsCreate),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: ctrl.chargerTousLesClubsAdmin,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: ctrl.clubs.length,
                    itemBuilder: (_, i) {
                      final club = ctrl.clubs[i];
                      return _AdminClubTile(club: club);
                    },
                  ),
                ),
    );
  }
}

class _AdminClubTile extends StatelessWidget {
  final ClubLecture club;
  const _AdminClubTile({required this.club});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.gradientAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.menu_book_rounded, color: Colors.white),
        ),
        title: Text(club.nom, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(club.livreTitre, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              l10n.clubsMembers(club.nbMembres),
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          onPressed: () async {
            final ok = await AppHelpers.showConfirmDialog(
              context: context,
              titre: l10n.adminDeleteClub,
              message: 'Supprimer « ${club.nom} » et toute la discussion ?',
              confirmLabel: l10n.adminDeleteClub,
              confirmColor: AppColors.error,
            );
            if (ok == true && context.mounted) {
              final done = await context.read<ClubController>().supprimerClub(club.id);
              if (context.mounted) {
                if (done) {
                  AppHelpers.showSuccess(context, 'Club supprimé.');
                } else {
                  AppHelpers.showError(context, context.read<ClubController>().errorMessage ?? 'Erreur');
                }
              }
            }
          },
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClubDetailView(club: club, fromAdminPanel: true)),
        ),
      ),
    );
  }
}
