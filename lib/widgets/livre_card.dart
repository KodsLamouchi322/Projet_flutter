import 'package:flutter/material.dart';
import '../models/livre.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Carte d'un livre pour la liste du catalogue
class LivreCard extends StatelessWidget {
  final Livre livre;
  final VoidCallback? onTap;
  final bool showStatut;

  const LivreCard({
    super.key,
    required this.livre,
    this.onTap,
    this.showStatut = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSizes.livreCardWidth,
        margin: const EdgeInsets.only(right: AppSizes.paddingSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Couverture ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadiusSmall),
                  child: livre.couvertureUrl.isNotEmpty
                      ? Image.network(
                          livre.couvertureUrl,
                          height: AppSizes.couvertureHeight,
                          width: AppSizes.livreCardWidth,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                if (showStatut)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _StatutBadge(statut: livre.statut),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // ── Titre ──
            Text(
              livre.titre,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // ── Auteur ──
            Text(
              livre.auteur,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // ── Note ──
            if (livre.nbAvis > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, size: 12, color: AppColors.accent),
                  const SizedBox(width: 2),
                  Text(
                    livre.noteMoyenne.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: AppSizes.couvertureHeight,
      width: AppSizes.livreCardWidth,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
      ),
      child: const Icon(
        Icons.menu_book,
        size: 48,
        color: AppColors.primary,
      ),
    );
  }
}

/// Badge de statut du livre
class _StatutBadge extends StatelessWidget {
  final StatutLivre statut;

  const _StatutBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    final color = AppHelpers.couleurStatutLivre(statut.name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        statut == StatutLivre.disponible ? '✓' : '✗',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─── Version liste (horizontale complète) ─────────────────────────────────────
class LivreListTile extends StatelessWidget {
  final Livre livre;
  final VoidCallback? onTap;

  const LivreListTile({super.key, required this.livre, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statutColor = AppHelpers.couleurStatutLivre(livre.statut.name);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: AppSizes.paddingSmall / 2,
      ),
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
          child: livre.couvertureUrl.isNotEmpty
              ? Image.network(
                  livre.couvertureUrl,
                  width: 50,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _miniPlaceholder(),
                )
              : _miniPlaceholder(),
        ),
        title: Text(
          livre.titre,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              livre.auteur,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (livre.genre.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      livre.genre,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    livre.statutLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: statutColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _miniPlaceholder() {
    return Container(
      width: 50,
      height: 70,
      color: AppColors.primary.withOpacity(0.1),
      child: const Icon(Icons.menu_book, size: 24, color: AppColors.primary),
    );
  }
}
