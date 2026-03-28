import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/livre_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state_widget.dart';
import '../catalogue/livre_detail_view.dart';

/// Affiche les livres de la wishlist du membre.
class WishlistView extends StatelessWidget {
  const WishlistView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final membre = auth.membre;
    final livreCtrl = context.watch<LivreController>();
    final l10n = AppLocalizations.of(context)!;

    if (membre == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.myWishlist),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(l10n.loginToAccess),
        ),
      );
    }

    final wishlistIds = membre.wishlist;
    final livres = livreCtrl.livres
        .where((l) => wishlistIds.contains(l.id))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.myWishlist),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: livres.isEmpty
          ? const _EmptyWishlist()
          : ListView.separated(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              itemCount: livres.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final livre = livres[i];
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusSmall),
                  ),
                  leading: Icon(Icons.menu_book,
                      color: AppColors.primaryDark),
                  title: Text(
                    livre.titre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    livre.auteur,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LivreDetailView(livre: livre),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _EmptyWishlist extends StatelessWidget {
  const _EmptyWishlist();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.favorite_border,
      title: 'Votre wishlist est vide',
      subtitle: 'Ajoutez des livres favoris depuis le catalogue pour les retrouver ici.',
    );
  }
}

