import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/evenement_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/evenement.dart';
import '../../utils/constants.dart';

class EvenementDetailView extends StatelessWidget {
  final Evenement evenement;
  const EvenementDetailView({super.key, required this.evenement});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final uid = auth.membre?.uid ?? '';
    final estInscrit = evenement.estParticipant(uid);
    final ctrl = context.read<EvenementController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // AppBar avec image ou gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chevron_left, color: AppColors.primary),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.event,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Catégorie
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      evenement.categorie,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    evenement.titre,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Infos
                  _InfoCard(children: [
                    _InfoRow(Icons.calendar_today, 'Date de début',
                        _formatDate(evenement.dateDebut)),
                    _InfoRow(Icons.event_available, 'Date de fin',
                        _formatDate(evenement.dateFin)),
                    _InfoRow(Icons.location_on, 'Lieu', evenement.lieu),
                    _InfoRow(
                      Icons.people,
                      'Participants',
                      '${evenement.participantsIds.length} / ${evenement.capaciteMax}',
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Barre de capacité
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Capacité',
                              style:
                                  TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(
                            '${evenement.placesRestantes} places restantes',
                            style: TextStyle(
                              fontSize: 12,
                              color: evenement.estComplet
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: evenement.capaciteMax > 0
                              ? evenement.participantsIds.length /
                                  evenement.capaciteMax
                              : 0,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            evenement.estComplet
                                ? AppColors.error
                                : AppColors.accent,
                          ),
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text('Description',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    evenement.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bouton inscription
                  if (auth.isAuthenticated)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: evenement.estComplet && !estInscrit
                            ? null
                            : () async {
                                bool ok;
                                if (estInscrit) {
                                  ok = await ctrl.seDesinscrire(
                                      evenementId: evenement.id,
                                      membreId: uid);
                                } else {
                                  ok = await ctrl.sInscrire(
                                      evenementId: evenement.id,
                                      membreId: uid);
                                }
                                if (mounted && ok) Navigator.pop(context);
                              },
                        icon: Icon(estInscrit
                            ? Icons.cancel_outlined
                            : Icons.event_available),
                        label: Text(estInscrit
                            ? 'Se désinscrire'
                            : evenement.estComplet
                                ? 'Complet'
                                : 'S\'inscrire'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: estInscrit
                              ? AppColors.error
                              : AppColors.accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get mounted => true;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} à ${d.hour}h${d.minute.toString().padLeft(2, '0')}';
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            )
          ],
        ),
        child: Column(
          children: children
              .asMap()
              .entries
              .map((e) => Column(children: [
                    e.value,
                    if (e.key < children.length - 1)
                      const Divider(height: 16, color: AppColors.divider),
                  ]))
              .toList(),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      );
}
