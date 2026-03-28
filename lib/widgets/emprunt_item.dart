import 'package:flutter/material.dart';
import '../models/emprunt.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'app_buttons.dart';
import 'status_badge.dart';

class EmpruntItem extends StatelessWidget {
  final Emprunt emprunt;
  final VoidCallback? onProlonger;
  final VoidCallback? onRetourner;
  final bool showActions;

  const EmpruntItem({
    super.key, required this.emprunt,
    this.onProlonger, this.onRetourner, this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final isRetard = emprunt.estEnRetard;
    final joursRestants = emprunt.joursRestants;

    final barColor = _statusColor(emprunt.statut, isRetard);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppUI.cardDecoration(context),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Barre colorée latérale
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Couverture
                      Container(
                        width: 48, height: 66,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: AppColors.primarySoft,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: emprunt.livreCouverture.isNotEmpty
                            ? Image.network(emprunt.livreCouverture, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 24))
                            : const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emprunt.livreTitre,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(emprunt.livreAuteur,
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 6),
                          StatusBadge(label: _labelStatut(emprunt.statut), color: barColor),
                        ],
                      )),
                    ]),
                    const SizedBox(height: 10),

                    // Dates
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(Icons.calendar_today_outlined, size: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('Emprunté le ${AppHelpers.formatDate(emprunt.dateEmprunt)}',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const Spacer(),
                        Icon(
                          isRetard ? Icons.warning_amber_rounded : Icons.event_available_rounded,
                          size: 13,
                          color: isRetard ? AppColors.error : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isRetard ? 'En retard !'
                              : joursRestants >= 0 ? '$joursRestants j restants'
                              : 'À rendre',
                          style: TextStyle(
                            fontSize: 11,
                            color: isRetard ? AppColors.error : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: isRetard ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ]),
                    ),

                    // Actions
                    if (showActions && (onProlonger != null || onRetourner != null)) ...[
                      const SizedBox(height: 10),
                      if (emprunt.statut == StatutEmprunt.enAttenteRetour)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.infoLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: const Row(children: [
                            Icon(Icons.hourglass_top_rounded, size: 15, color: AppColors.primary),
                            SizedBox(width: 8),
                            Expanded(child: Text('En attente de confirmation par l\'admin',
                                style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500))),
                          ]),
                        )
                      else
                        Row(children: [
                          if (onProlonger != null)
                            Expanded(
                              child: emprunt.prolongationAutorisee
                                  ? AppSecondaryButton(
                                      onPressed: onProlonger,
                                      icon: Icons.schedule_rounded,
                                      label: 'Prolonger',
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Icon(Icons.lock_outline_rounded, size: 14,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 6),
                                        Text('Prolongation non autorisée',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            )),
                                      ]),
                                    ),
                            ),
                          if (onProlonger != null && onRetourner != null) const SizedBox(width: 8),
                          if (onRetourner != null)
                            Expanded(
                              child: AppDestructiveButton(
                                onPressed: onRetourner,
                                icon: Icons.undo_rounded,
                                label: 'Retourner',
                              ),
                            ),
                        ]),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelStatut(StatutEmprunt s) => switch (s) {
    StatutEmprunt.enCours          => 'En cours',
    StatutEmprunt.retourne         => 'Retourné',
    StatutEmprunt.enRetard         => 'En retard',
    StatutEmprunt.prolonge         => 'Prolongé',
    StatutEmprunt.enAttenteRetour  => 'Retour en attente',
  };

  Color _statusColor(StatutEmprunt s, bool isRetard) {
    if (isRetard || s == StatutEmprunt.enRetard) return AppColors.error;
    if (s == StatutEmprunt.enCours || s == StatutEmprunt.prolonge || s == StatutEmprunt.enAttenteRetour) {
      return AppColors.primary;
    }
    return AppColors.accent;
  }
}
