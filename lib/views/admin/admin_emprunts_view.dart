import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/emprunt_controller.dart';
import '../../models/emprunt.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/emprunt_item.dart';
import '../../widgets/empty_state_widget.dart';

/// Vue admin pour surveiller et valider les emprunts (retours).
enum AdminEmpruntsMode {
  all,
  enRetard,
  retoursEnAttente,
  prolongationsEnAttente,
}

class AdminEmpruntsView extends StatefulWidget {
  final AdminEmpruntsMode mode;
  const AdminEmpruntsView({
    super.key,
    this.mode = AdminEmpruntsMode.all,
  });

  @override
  State<AdminEmpruntsView> createState() => _AdminEmpruntsViewState();
}

class _AdminEmpruntsViewState extends State<AdminEmpruntsView> {
  List<Emprunt> _emprunts = [];
  bool _loading = true;
  String? _error;

  List<Emprunt> _listeAffichee() {
    if (widget.mode == AdminEmpruntsMode.enRetard) {
      return _emprunts.where((e) => e.statut == StatutEmprunt.enRetard).toList();
    }
    if (widget.mode == AdminEmpruntsMode.retoursEnAttente) {
      return _emprunts
          .where((e) => e.statut == StatutEmprunt.enAttenteRetour)
          .toList();
    }
    if (widget.mode == AdminEmpruntsMode.prolongationsEnAttente) {
      return _emprunts
          .where((e) =>
              e.statut != StatutEmprunt.enAttenteRetour &&
              !e.prolongationAutorisee &&
              e.prolongations < AppConstants.maxProlongations)
          .toList();
    }
    return _emprunts;
  }

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ctrl = context.read<EmpruntController>();
      _emprunts = await ctrl.getTousEmpruntsActifs();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.estAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Emprunts'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Accès réservé aux administrateurs.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.mode == AdminEmpruntsMode.enRetard
              ? 'Emprunts en retard'
              : widget.mode == AdminEmpruntsMode.retoursEnAttente
              ? 'Retours à confirmer'
              : widget.mode == AdminEmpruntsMode.prolongationsEnAttente
                  ? 'Demandes de prolongation'
                  : 'Validation des emprunts',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _listeAffichee().isEmpty
                    ? _EmptyEmprunts(mode: widget.mode)
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSizes.paddingMedium),
                        itemCount: _listeAffichee().length,
                        itemBuilder: (_, i) {
                          final emprunt = _listeAffichee()[i];
                          final ctrl = context.read<EmpruntController>();
                          final estDemandeRetour = emprunt.statut == StatutEmprunt.enAttenteRetour;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (estDemandeRetour)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4, left: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.notification_important, size: 14, color: AppColors.warning),
                                      SizedBox(width: 4),
                                      Text('Demande de retour à confirmer',
                                          style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              EmpruntItem(
                                emprunt: emprunt,
                                showActions: false,
                              ),
                              // Bouton autoriser/refuser prolongation
                              if (!estDemandeRetour && emprunt.prolongations < AppConstants.maxProlongations)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
                                  child: Row(children: [
                                    Expanded(
                                      child: emprunt.prolongationAutorisee
                                          ? AppDestructiveButton(
                                              onPressed: () async {
                                                final ok = await ctrl.autoriserProlongation(
                                                  empruntId: emprunt.id,
                                                  autoriser: false,
                                                );
                                                if (ok && context.mounted) {
                                                  AppHelpers.showInfo(context, 'Prolongation refusée.');
                                                  _charger();
                                                }
                                              },
                                              icon: Icons.lock_outline_rounded,
                                              label: 'Refuser prolongation',
                                            )
                                          : AppPrimaryButton(
                                              onPressed: () async {
                                                final ok = await ctrl.autoriserProlongation(
                                                  empruntId: emprunt.id,
                                                  autoriser: true,
                                                );
                                                if (ok && context.mounted) {
                                                  AppHelpers.showSuccess(context, 'Prolongation autorisée pour ${emprunt.livreTitre}.');
                                                  _charger();
                                                }
                                              },
                                              icon: Icons.check_circle_outline_rounded,
                                              label: 'Autoriser prolongation',
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                                              ),
                                            ),
                                    ),
                                  ]),
                                ),
                              if (estDemandeRetour)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                                  child: AppPrimaryButton(
                                    onPressed: () async {
                                      final confirme = await AppHelpers.showConfirmDialog(
                                        context: context,
                                        titre: 'Confirmer le retour',
                                        message: 'Confirmez-vous la réception physique de "${emprunt.livreTitre}" ?',
                                        confirmLabel: 'Confirmer réception',
                                        confirmColor: AppColors.success,
                                      );
                                      if (confirme != true) return;
                                      final ok = await ctrl.retournerLivreAdmin(
                                        empruntId: emprunt.id,
                                        livreId: emprunt.livreId,
                                        membreId: emprunt.membreId,
                                      );
                                      if (context.mounted) {
                                        if (ok) {
                                          // Vérifier si une réservation a été traitée
                                          AppHelpers.showSuccess(context,
                                              'Retour confirmé. File d\'attente vérifiée automatiquement.');
                                          setState(() => _emprunts.removeAt(i));
                                        } else {
                                          AppHelpers.showError(context, ctrl.errorMessage ?? AppConstants.erreurInconnu);
                                        }
                                      }
                                    },
                                    icon: Icons.check_circle,
                                    label: 'Confirmer la réception',
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
      ),
    );
  }
}

class _EmptyEmprunts extends StatelessWidget {
  final AdminEmpruntsMode mode;
  const _EmptyEmprunts({required this.mode});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: mode == AdminEmpruntsMode.enRetard
          ? Icons.warning_amber_rounded
          : mode == AdminEmpruntsMode.retoursEnAttente
          ? Icons.assignment_turned_in_outlined
          : mode == AdminEmpruntsMode.prolongationsEnAttente
              ? Icons.update_rounded
              : Icons.book_outlined,
      title: mode == AdminEmpruntsMode.enRetard
          ? 'Aucun emprunt en retard'
          : mode == AdminEmpruntsMode.retoursEnAttente
          ? 'Aucun retour en attente'
          : mode == AdminEmpruntsMode.prolongationsEnAttente
              ? 'Aucune demande de prolongation'
              : 'Aucun emprunt en cours',
      subtitle: mode == AdminEmpruntsMode.enRetard
          ? 'Les retards de retour apparaîtront ici.'
          : mode == AdminEmpruntsMode.retoursEnAttente
          ? 'Les demandes de retour à confirmer apparaîtront ici.'
          : mode == AdminEmpruntsMode.prolongationsEnAttente
              ? 'Les emprunts à autoriser en prolongation apparaîtront ici.'
              : 'Les emprunts actifs des membres apparaîtront ici.',
    );
  }
}

