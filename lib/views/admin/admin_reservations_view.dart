import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state_widget.dart';

class AdminReservationsView extends StatelessWidget {
  const AdminReservationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.estAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Réservations'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Accès réservé aux administrateurs.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Réservations en attente'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colReservations)
            .where('statut', isEqualTo: 'enAttente')
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erreur: ${snap.error}'));
          }

          final docs = (snap.data?.docs ?? []).toList()
            ..sort((a, b) {
              final ad = (a.data() as Map<String, dynamic>)['dateReservation'];
              final bd = (b.data() as Map<String, dynamic>)['dateReservation'];
              if (ad == null && bd == null) return 0;
              if (ad == null) return 1;
              if (bd == null) return -1;
              return (ad as Timestamp).compareTo(bd as Timestamp);
            });

          if (docs.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.bookmark_outline_rounded,
              title: 'Aucune réservation en attente',
              subtitle: 'Les réservations actives apparaîtront ici.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            itemCount: docs.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              if (i == 0) {
                return _ReservationsHeader(count: docs.length);
              }

              final d = docs[i - 1].data() as Map<String, dynamic>;
              final position = d['positionFile'] ?? '-';
              final titre = (d['livreTitre'] ?? '').toString().trim();
              final auteur = (d['livreAuteur'] ?? '').toString().trim();
              final membre = (d['membreNom'] ?? '').toString().trim();
              final dateRes = d['dateReservation'];
              final titreAffiche = titre.isEmpty ? 'Livre non renseigné' : titre;
              final membreAffiche = membre.isEmpty ? 'Membre inconnu' : membre;
              final auteurAffiche = auteur.isEmpty ? '' : auteur;
              final dateTxt = dateRes is Timestamp
                  ? '${dateRes.toDate().day.toString().padLeft(2, '0')}/${dateRes.toDate().month.toString().padLeft(2, '0')}/${dateRes.toDate().year}'
                  : '';

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bookmark_rounded,
                              color: AppColors.accentDark,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              titreAffiche,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _Pill(label: 'Position $position'),
                        ],
                      ),
                      if (auteurAffiche.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Auteur: $auteurAffiche',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'Membre: $membreAffiche',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (dateTxt.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Réservé le: $dateTxt',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReservationsHeader extends StatelessWidget {
  final int count;
  const _ReservationsHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppColors.gradientAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.bookmark_added_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            '$count réservation(s) en attente',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}
