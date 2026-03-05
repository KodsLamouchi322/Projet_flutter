import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/emprunt_controller.dart';
import '../../controllers/livre_controller.dart';
import '../../models/livre.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Fiche détaillée d'un livre avec actions (emprunter, réserver, wishlist)
class LivreDetailView extends StatelessWidget {
  final Livre livre;

  const LivreDetailView({super.key, required this.livre});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final statutColor = AppHelpers.couleurStatutLivre(livre.statut.name);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header avec couverture ──
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image de fond floue
                  livre.couvertureUrl.isNotEmpty
                      ? Image.network(
                          livre.couvertureUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(color: AppColors.primaryDark),
                  // Overlay gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.primaryDark.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  // Couverture centrée
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 40),
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: livre.couvertureUrl.isNotEmpty
                            ? Image.network(livre.couvertureUrl)
                            : Container(
                                height: 170,
                                color:
                                    AppColors.primary.withOpacity(0.3),
                                child: const Icon(
                                  Icons.menu_book,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Wishlist toggle
              if (auth.isAuthenticated)
                IconButton(
                  icon: Icon(
                    auth.membre!.wishlist.contains(livre.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: auth.membre!.wishlist.contains(livre.id)
                        ? Colors.red
                        : Colors.white,
                  ),
                  onPressed: () => _toggleWishlist(context, auth),
                  tooltip: 'Liste de souhaits',
                ),
              // Edit (admin)
              if (auth.estAdmin)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Navigation vers édition (semaines 5-6)
                  },
                ),
            ],
          ),

          // ── Détails ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + Auteur
                  Text(livre.titre, style: AppTextStyles.headline1),
                  const SizedBox(height: 4),
                  Text(
                    'par ${livre.auteur}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tags d'info
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      // Statut
                      _InfoChip(
                        label: livre.statutLabel,
                        color: statutColor,
                        icon: livre.estDisponible
                            ? Icons.check_circle
                            : Icons.cancel,
                      ),
                      // Genre
                      if (livre.genre.isNotEmpty)
                        _InfoChip(
                          label: livre.genre,
                          color: AppColors.primary,
                          icon: Icons.category,
                        ),
                      // Année
                      if (livre.anneePublication > 0)
                        _InfoChip(
                          label: '${livre.anneePublication}',
                          color: AppColors.textSecondary,
                          icon: Icons.calendar_today,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Note
                  if (livre.nbAvis > 0)
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < livre.noteMoyenne.round()
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${livre.noteMoyenne.toStringAsFixed(1)} / 5',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${livre.nbAvis} avis)',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                  const Divider(height: 32),

                  // Résumé
                  if (livre.resume.isNotEmpty) ...[
                    const Text(
                      'Résumé',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      livre.resume,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const Divider(height: 32),
                  ],

                  // Informations détaillées
                  const Text(
                    'Informations',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Éditeur', valeur: livre.editeur),
                  _InfoRow(
                    label: 'ISBN',
                    valeur: livre.isbn.isEmpty ? 'Non renseigné' : livre.isbn,
                  ),
                  _InfoRow(
                    label: 'Ajouté le',
                    valeur: AppHelpers.formatDateLong(livre.dateAjout),
                  ),
                  _InfoRow(
                    label: 'Emprunts',
                    valeur: '${livre.nbEmpruntsTotal} fois',
                  ),

                  // Tags
                  if (livre.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: livre.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 11)),
                              backgroundColor:
                                  AppColors.accent.withOpacity(0.1),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 100), // Espace pour les boutons
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Boutons d'action ──
      bottomNavigationBar: auth.isAuthenticated
          ? _ActionsBar(livre: livre)
          : _VisitorBar(),
    );
  }

  Future<void> _toggleWishlist(
      BuildContext context, AuthController auth) async {
    await FirestoreService()
        .toggleWishlist(membreId: auth.membre!.uid, livreId: livre.id);
    // Recharger le membre
    await auth.mettreAJourProfil({});
    if (context.mounted) {
      AppHelpers.showInfo(
        context,
        auth.membre!.wishlist.contains(livre.id)
            ? 'Retiré de la wishlist'
            : 'Ajouté à la wishlist',
      );
    }
  }
}

// ── Barre d'actions membre ────────────────────────────────────────────────────
class _ActionsBar extends StatelessWidget {
  final Livre livre;
  const _ActionsBar({required this.livre});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final empruntCtrl = context.read<EmpruntController>();

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: livre.estDisponible
            ? ElevatedButton.icon(
                onPressed: () async {
                  if (auth.membre == null) return;
                  final confirme = await AppHelpers.showConfirmDialog(
                    context: context,
                    titre: 'Emprunter ce livre',
                    message:
                        'Confirmez-vous l\'emprunt de \"${livre.titre}\" ?',
                    confirmLabel: 'Emprunter',
                    confirmColor: AppColors.success,
                  );
                  if (confirme != true) return;

                  final ok = await empruntCtrl.emprunterLivre(
                    livreId: livre.id,
                    membreId: auth.membre!.uid,
                    membreNom: auth.membre!.nomComplet,
                    livreTitre: livre.titre,
                  );
                  if (context.mounted) {
                    if (ok) {
                      AppHelpers.showSuccess(
                        context,
                        'Emprunt enregistré. Bonne lecture !',
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
                icon: const Icon(Icons.library_add),
                label: const Text('Emprunter ce livre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (auth.membre == null) return;
                        final confirme = await AppHelpers.showConfirmDialog(
                          context: context,
                          titre: 'Réserver ce livre',
                          message:
                              'Ce livre est actuellement emprunté.\nSouhaitez-vous le réserver ?',
                          confirmLabel: 'Réserver',
                        );
                        if (confirme != true) return;

                        final ok = await empruntCtrl.reserverLivre(
                          livreId: livre.id,
                          membreId: auth.membre!.uid,
                          membreNom: auth.membre!.nomComplet,
                          livreTitre: livre.titre,
                        );
                        if (context.mounted) {
                          if (ok) {
                            AppHelpers.showSuccess(
                              context,
                              'Réservation enregistrée. Vous serez dans la file d\'attente.',
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
                      icon: const Icon(Icons.bookmark_add),
                      label: const Text('Réserver'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.notifications),
                      label: const Text('M\'alerter'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _VisitorBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          icon: const Icon(Icons.login),
          label: const Text('Connectez-vous pour emprunter'),
        ),
      ),
    );
  }
}

// ── Widgets utilitaires ───────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _InfoChip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String valeur;

  const _InfoRow({required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    if (valeur.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valeur,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
