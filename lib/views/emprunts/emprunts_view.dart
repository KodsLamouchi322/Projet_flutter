import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/emprunt_controller.dart';
import '../../models/emprunt.dart';
import '../../models/reservation.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

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
        empruntCtrl.chargerEmpruntsMemebres(uid);
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline,
                size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Connectez-vous pour voir vos emprunts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Accédez à l’historique complet, aux réservations\net aux rappels de retard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
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
      return _EmptyState(
        icon: Icons.book_outlined,
        title: 'Aucun emprunt en cours',
        message:
            'Empruntez un livre depuis le catalogue pour le voir apparaître ici.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: controller.empruntsActifs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final emprunt = controller.empruntsActifs[index];
        return _EmpruntActifCard(emprunt: emprunt);
      },
    );
  }
}

class _EmpruntActifCard extends StatelessWidget {
  final Emprunt emprunt;

  const _EmpruntActifCard({required this.emprunt});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final empruntCtrl = context.read<EmpruntController>();
    final color =
        AppHelpers.couleurStatutEmprunt(emprunt.statut.name);
    final joursRestants = emprunt.joursRestants;

    String sousTitre;
    if (emprunt.estEnRetard) {
      sousTitre = 'En retard depuis le '
          '${AppHelpers.formatDate(emprunt.dateRetourPrevue)}';
    } else if (joursRestants >= 0) {
      sousTitre = 'À rendre avant le '
          '${AppHelpers.formatDate(emprunt.dateRetourPrevue)}';
    } else {
      sousTitre = 'À rendre très rapidement';
    }

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusSmall),
                  ),
                  child: const Icon(Icons.menu_book,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emprunt.livreTitre,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emprunt.livreAuteur,
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _labelStatut(emprunt),
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            sousTitre,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirme = await AppHelpers.showConfirmDialog(
                        context: context,
                        titre: 'Prolonger l\'emprunt',
                        message:
                            'Souhaitez-vous prolonger cet emprunt de 7 jours ?',
                        confirmLabel: 'Prolonger',
                      );
                      if (confirme != true) return;

                      final ok = await empruntCtrl.prolongerEmprunt(
                        empruntId: emprunt.id,
                        membreId: auth.membre!.uid,
                      );
                      if (context.mounted) {
                        if (ok) {
                          AppHelpers.showSuccess(
                            context,
                            'Emprunt prolongé avec succès.',
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
                    icon: const Icon(Icons.schedule),
                    label: const Text('Prolonger'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirme = await AppHelpers.showConfirmDialog(
                        context: context,
                        titre: 'Retourner le livre',
                        message:
                            'Confirmez-vous le retour de ce livre en bibliothèque ?',
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
                        if (ok) {
                          AppHelpers.showSuccess(
                            context,
                            'Retour enregistré. Merci !',
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
                    icon: const Icon(Icons.undo),
                    label: const Text('Retourner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _labelStatut(Emprunt e) {
    switch (e.statut) {
      case StatutEmprunt.enCours:
        return 'En cours';
      case StatutEmprunt.retourne:
        return 'Retourné';
      case StatutEmprunt.enRetard:
        return 'En retard';
      case StatutEmprunt.prolonge:
        return 'Prolongé';
    }
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
      return _EmptyState(
        icon: Icons.history,
        title: 'Aucun emprunt passé',
        message:
            'Vos anciens emprunts apparaîtront ici une fois les livres retournés.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: controller.historique.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final emprunt = controller.historique[index];
        return ListTile(
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
          ),
          leading: const Icon(Icons.menu_book_outlined,
              color: AppColors.primary),
          title: Text(
            emprunt.livreTitre,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Emprunté le ${AppHelpers.formatDate(emprunt.dateEmprunt)}\n'
            'Retourné le ${AppHelpers.formatDate(emprunt.dateRetourEffective ?? emprunt.dateRetourPrevue)}',
          ),
          isThreeLine: true,
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
      return _EmptyState(
        icon: Icons.bookmark_add_outlined,
        title: 'Aucune réservation',
        message:
            'Réservez un livre déjà emprunté pour être notifié dès qu’il sera disponible.',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _reservationColor(reservation)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _reservationLabel(reservation),
                    style: TextStyle(
                      color: _reservationColor(reservation),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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

// ─── Widget d'état vide réutilisable ──────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headline2,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
