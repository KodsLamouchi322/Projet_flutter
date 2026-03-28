import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/emprunt_controller.dart';
import '../../models/reservation.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/emprunt_item.dart';
import '../../widgets/status_badge.dart';
import '../auth/login_view.dart';
import '../catalogue/catalogue_view.dart';
import 'scan_emprunt_view.dart';
import '../../services/pdf_service.dart';

/// Écran complet des emprunts et réservations du membre
class EmpruntsView extends StatefulWidget {
  const EmpruntsView({super.key});

  @override
  State<EmpruntsView> createState() => _EmpruntsViewState();
}

class _EmpruntsViewState extends State<EmpruntsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Charger les emprunts / réservations du membre connecté
    Future.microtask(() {
      final auth = context.read<AuthController>();
      final empruntCtrl = context.read<EmpruntController>();
      if (auth.membre != null) {
        final uid = auth.membre!.uid;
        empruntCtrl.chargerEmpruntsMembre(uid);
        empruntCtrl.chargerReservationsMembre(uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empruntCtrl = context.watch<EmpruntController>();
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Emprunts'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Bouton scan retour rapide
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scanner un retour',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ScanEmpruntView(modeRetour: true))),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'En cours'),
            Tab(text: 'Historique'),
            Tab(text: 'Réservations'),
          ],
        ),
      ),
      backgroundColor: AppColors.background,
      body: auth.membre == null
          ? _buildNotConnected()
          : TabBarView(
              controller: _tabController,
              children: [
                _EmpruntsEnCoursTab(controller: empruntCtrl),
                _HistoriqueTab(controller: empruntCtrl),
                _ReservationsTab(controller: empruntCtrl),
              ],
            ),
    );
  }

  Widget _buildNotConnected() {
    return EmptyStateWidget(
      icon: Icons.lock_outline,
      title: 'Connectez-vous pour voir vos emprunts',
      subtitle: 'Accédez à l\'historique complet, aux réservations et aux rappels de retard.',
      action: AppPrimaryButton(
        label: 'Se connecter',
        gradient: AppColors.gradientAccent,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginView())),
      ),
    );
  }
}

// ─── Onglet : Emprunts en cours ────────────────────────────────────────────────

class _EmpruntsEnCoursTab extends StatelessWidget {
  final EmpruntController controller;

  const _EmpruntsEnCoursTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.empruntsActifs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.empruntsActifs.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.book_outlined,
        title: 'Aucun emprunt en cours',
        subtitle: 'Empruntez un livre depuis le catalogue pour le voir apparaître ici.',
        action: AppPrimaryButton(
          label: 'Explorer le catalogue',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogueView())),
          icon: Icons.menu_book_rounded,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: controller.empruntsActifs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final emprunt = controller.empruntsActifs[index];
        final auth = context.read<AuthController>();
        final empruntCtrl = context.read<EmpruntController>();
        return EmpruntItem(
          emprunt: emprunt,
          onProlonger: () async {
            // Dialog durée de prolongation personnalisable
            int dureeChoisie = AppConstants.dureeProlongationJours;
            final duree = await showDialog<int>(
              context: context,
              builder: (_) => _DureeProlongationDialog(dureeDefaut: AppConstants.dureeProlongationJours),
            );
            if (duree == null) return;
            dureeChoisie = duree;

            final ok = await empruntCtrl.prolongerEmprunt(
              empruntId: emprunt.id,
              membreId: auth.membre!.uid,
              dureeJours: dureeChoisie,
            );
            if (context.mounted) {
              ok
                  ? AppHelpers.showSuccess(context, 'Emprunt prolongé de $dureeChoisie jours.')
                  : AppHelpers.showError(context, empruntCtrl.errorMessage ?? AppConstants.erreurInconnu);
            }
          },
          onRetourner: () async {
            final confirme = await AppHelpers.showConfirmDialog(
              context: context,
              titre: 'Retourner le livre',
              message: 'Confirmez-vous le retour de ce livre ?',
              confirmLabel: 'Retourner',
              confirmColor: AppColors.success,
            );
            if (confirme != true) return;
            final ok = await empruntCtrl.retournerLivre(
              empruntId: emprunt.id,
              livreId: emprunt.livreId,
              membreId: auth.membre!.uid,
            );
            if (context.mounted) {
              ok
                  ? AppHelpers.showSuccess(context, 'Retour enregistré. Merci !')
                  : AppHelpers.showError(context, empruntCtrl.errorMessage ?? AppConstants.erreurInconnu);
            }
          },
        );
      },
    );
  }
}

// ─── Onglet : Historique des emprunts ─────────────────────────────────────────

class _HistoriqueTab extends StatelessWidget {
  final EmpruntController controller;

  const _HistoriqueTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.historique.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.historique.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.history,
        title: 'Aucun emprunt passé',
        subtitle: 'Vos anciens emprunts apparaîtront ici une fois les livres retournés.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: controller.historique.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final emprunt = controller.historique[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: AppUI.cardDecoration(context),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
            title: Text(emprunt.livreTitre,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(
              'Emprunté le ${AppHelpers.formatDate(emprunt.dateEmprunt)}\n'
              'Retourné le ${AppHelpers.formatDate(emprunt.dateRetourEffective ?? emprunt.dateRetourPrevue)}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accent),
              tooltip: 'Exporter en PDF',
              onPressed: () {
                final auth = context.read<AuthController>();
                PdfService.genererRecuEmprunt(
                  context: context,
                  emprunt: emprunt,
                  membreNom: auth.membre?.nomComplet ?? '',
                  membreEmail: auth.membre?.email ?? '',
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ─── Onglet : Réservations ─────────────────────────────────────────────────────

class _ReservationsTab extends StatelessWidget {
  final EmpruntController controller;

  const _ReservationsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.reservations.isEmpty &&
        !controller.isLoading) {
      return const EmptyStateWidget(
        icon: Icons.bookmark_add_outlined,
        title: 'Aucune réservation',
        subtitle: 'Réservez un livre déjà emprunté pour être notifié dès qu’il sera disponible.',
      );
    }

    if (controller.isLoading && controller.reservations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: controller.reservations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = controller.reservations[index];
        return _ReservationCard(reservation: r);
      },
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;

  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final empruntCtrl = context.read<EmpruntController>();
    final isActive =
        reservation.statut == StatutReservation.enAttente;

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bookmark_add,
                    color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.livreTitre,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Position dans la file : ${reservation.positionFile}',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Réservé le ${AppHelpers.formatDate(reservation.dateReservation)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(
                  label: _reservationLabel(reservation),
                  color: _reservationColor(reservation),
                ),
                if (isActive)
                  TextButton(
                    onPressed: () async {
                      final confirme = await AppHelpers.showConfirmDialog(
                        context: context,
                        titre: 'Annuler la réservation',
                        message:
                            'Souhaitez-vous annuler cette réservation ?',
                        confirmLabel: 'Annuler',
                        confirmColor: AppColors.error,
                      );
                      if (confirme != true) return;

                      final ok = await empruntCtrl.annulerReservation(
                        reservationId: reservation.id,
                        membreId: auth.membre!.uid,
                      );
                      if (context.mounted) {
                        if (ok) {
                          AppHelpers.showSuccess(
                            context,
                            'Réservation annulée.',
                          );
                        } else {
                          AppHelpers.showError(
                            context,
                            empruntCtrl.errorMessage ??
                                AppConstants.erreurInconnu,
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Annuler'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _reservationColor(Reservation r) {
    switch (r.statut) {
      case StatutReservation.enAttente:
        return AppColors.info;
      case StatutReservation.confirmee:
        return AppColors.success;
      case StatutReservation.annulee:
        return AppColors.textSecondary;
      case StatutReservation.expiree:
        return AppColors.error;
    }
  }

  String _reservationLabel(Reservation r) {
    switch (r.statut) {
      case StatutReservation.enAttente:
        return 'En attente';
      case StatutReservation.confirmee:
        return 'Confirmée';
      case StatutReservation.annulee:
        return 'Annulée';
      case StatutReservation.expiree:
        return 'Expirée';
    }
  }
}

// ─── Dialog durée de prolongation ────────────────────────────────────────────
class _DureeProlongationDialog extends StatefulWidget {
  final int dureeDefaut;
  const _DureeProlongationDialog({required this.dureeDefaut});

  @override
  State<_DureeProlongationDialog> createState() => _DureeProlongationDialogState();
}

class _DureeProlongationDialogState extends State<_DureeProlongationDialog> {
  late int _duree;

  @override
  void initState() {
    super.initState();
    _duree = widget.dureeDefaut;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Prolonger l\'emprunt'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('De combien de jours souhaitez-vous prolonger ?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _duree > 1 ? () => setState(() => _duree--) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.primary,
              ),
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$_duree j', textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              IconButton(
                onPressed: _duree < 30 ? () => setState(() => _duree++) : null,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [3, 7, 14, 21].map((d) => ActionChip(
              label: Text('$d j'),
              onPressed: () => setState(() => _duree = d),
              backgroundColor: _duree == d ? AppColors.primary : null,
              labelStyle: TextStyle(color: _duree == d ? Colors.white : null, fontSize: 12),
            )).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _duree),
          child: const Text('Prolonger'),
        ),
      ],
    );
  }
}
