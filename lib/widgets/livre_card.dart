import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../models/livre.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'status_badge.dart';

class LivreCard extends StatelessWidget {
  final Livre livre;
  final VoidCallback? onTap;
  final bool showStatut;

  const LivreCard({super.key, required this.livre, this.onTap, this.showStatut = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: AppUI.cardDecoration(context),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: livre.couvertureUrl.isNotEmpty
                    ? Image.network(livre.couvertureUrl,
                        height: AppSizes.couvertureHeight, width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Consumer<AuthController>(builder: (ctx, auth, _) {
                  if (!auth.isAuthenticated) return const SizedBox();
                  final inWl = auth.membre!.wishlist.contains(livre.id);
                  return GestureDetector(
                    onTap: () => auth.toggleWishlist(livre.id),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        inWl ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 14,
                        color: inWl ? AppColors.accentDark : AppColors.textSecondary,
                      ),
                    ),
                  );
                }),
              ),
              if (showStatut)
                Positioned(
                  top: 8,
                  right: 8,
                  child: StatusBadge(
                    label: livre.statutLabel,
                    color: _statusColor(livre.statut.name),
                  ),
                ),
            ]),
            const SizedBox(height: 10),
            Text(livre.titre,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(livre.auteur,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (livre.nbAvis > 0) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded, size: 13, color: AppColors.accent),
                const SizedBox(width: 3),
                Text(livre.noteMoyenne.toStringAsFixed(1),
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'disponible':
        return AppColors.success;
      case 'emprunte':
        return AppColors.primary;
      case 'reserve':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _placeholder() => Container(
    height: AppSizes.couvertureHeight, width: double.infinity,
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(AppSizes.radius),
    ),
    child: const Icon(Icons.menu_book_rounded, size: 40, color: AppColors.primary),
  );
}

class LivreListTile extends StatelessWidget {
  final Livre livre;
  final VoidCallback? onTap;
  const LivreListTile({super.key, required this.livre, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statutColor = AppHelpers.couleurStatutLivre(livre.statut.name);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: AppUI.cardDecoration(context),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: livre.couvertureUrl.isNotEmpty
              ? Image.network(livre.couvertureUrl, width: 44, height: 60, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _mini())
              : _mini(),
        ),
        title: Text(livre.titre,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(livre.auteur,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 5),
          Row(children: [
            if (livre.genre.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(livre.genre,
                    style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
            ],
            StatusBadge(label: livre.statutLabel, color: statutColor),
          ]),
        ]),
        trailing: Icon(Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        isThreeLine: true,
      ),
    );
  }

  Widget _mini() => Container(
    width: 44, height: 60,
    color: AppColors.primarySoft,
    child: const Icon(Icons.menu_book_rounded, size: 22, color: AppColors.primary),
  );
}
