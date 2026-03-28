import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/club_controller.dart';
import '../../controllers/livre_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/livre.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_buttons.dart';

/// Formulaire création de club — partagé (membre / admin). Web : [Dialog] opaque.
Future<void> openCreerClubFlow(BuildContext context) async {
  final rootCtx = context;
  final messenger = ScaffoldMessenger.maybeOf(rootCtx);
  final l10n = AppLocalizations.of(rootCtx)!;
  final auth = Provider.of<AuthController>(rootCtx, listen: false);
  final clubCtrl = Provider.of<ClubController>(rootCtx, listen: false);
  if (!auth.estAdmin) {
    AppHelpers.showError(rootCtx, 'Seul un administrateur peut créer un club.');
    return;
  }
  final nomCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  Livre? livreChoisi;

  Future<void> pickLivre(StateSetter setModal, BuildContext sheetCtx) async {
    final picked = await showModalBottomSheet<Livre>(
      context: sheetCtx,
      isScrollControlled: true,
      backgroundColor: Theme.of(sheetCtx).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) {
        final h = MediaQuery.sizeOf(c).height * 0.88;
        return SizedBox(
          height: h,
          child: const PickLivreForClubSheet(),
        );
      },
    );
    if (picked != null) setModal(() => livreChoisi = picked);
  }

  Widget formulaire(StateSetter setModal, BuildContext sheetCtx, AuthController authCtrl, ClubController clubController) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.viewInsetsOf(sheetCtx).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!kIsWeb)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Text(l10n.clubsCreate, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'Choisissez un livre du catalogue pour animer le club.',
            style: TextStyle(fontSize: 13, color: Theme.of(sheetCtx).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nomCtrl,
            decoration: AppInputDecoration.standard(
              label: 'Nom du club *',
              icon: Icons.groups_rounded,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descCtrl,
            maxLines: 3,
            decoration: AppInputDecoration.standard(
              label: 'Description *',
              icon: Icons.notes_rounded,
            ).copyWith(alignLabelWithHint: true),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
            tileColor: Theme.of(sheetCtx).colorScheme.surfaceContainerHighest,
            title: const Text('Livre du catalogue *', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              livreChoisi == null
                  ? 'Appuyer pour choisir'
                  : '${livreChoisi!.titre} — ${livreChoisi!.auteur}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => pickLivre(setModal, sheetCtx),
          ),
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: 'Créer',
            gradient: AppColors.gradientCard,
            onPressed: () async {
              if (nomCtrl.text.trim().isEmpty || livreChoisi == null) {
                AppHelpers.showError(sheetCtx, 'Nom et livre du catalogue requis.');
                return;
              }
              final membre = authCtrl.membre;
              if (membre == null) {
                AppHelpers.showError(sheetCtx, 'Connectez-vous pour créer un club.');
                return;
              }
              final ok = await clubController.creerClub(
                nom: nomCtrl.text.trim(),
                description: descCtrl.text.trim(),
                livreId: livreChoisi!.id,
                livreTitre: livreChoisi!.titre,
                livreAuteur: livreChoisi!.auteur,
                createurId: membre.uid,
                createurNom: membre.nomComplet,
                livreCouverture: livreChoisi!.couvertureUrl,
              );
              if (ok && sheetCtx.mounted) {
                Navigator.of(sheetCtx).pop();
                if (authCtrl.estAdmin) {
                  await clubController.chargerTousLesClubsAdmin();
                }
                messenger?.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(child: Text('Club créé !')),
                      ],
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  try {
    if (kIsWeb) {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctxDialog) {
          final maxH = MediaQuery.sizeOf(ctxDialog).height * 0.92;
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 520, maxHeight: maxH),
              child: Material(
                color: Theme.of(ctxDialog).colorScheme.surface,
                child: StatefulBuilder(
                  builder: (ctxDialog, setModal) => formulaire(setModal, ctxDialog, auth, clubCtrl),
                ),
              ),
            ),
          );
        },
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModal) => formulaire(setModal, ctx, auth, clubCtrl),
          );
        },
      );
    }
  } finally {
    nomCtrl.dispose();
    descCtrl.dispose();
  }
}

/// Liste de livres pour rattacher un club au catalogue.
class PickLivreForClubSheet extends StatefulWidget {
  const PickLivreForClubSheet({super.key});

  @override
  State<PickLivreForClubSheet> createState() => _PickLivreForClubSheetState();
}

class _PickLivreForClubSheetState extends State<PickLivreForClubSheet> {
  final _q = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final livreCtrl = context.watch<LivreController>();
    final livres = livreCtrl.livres;
    final filtered = livres
        .where((l) {
          if (_filter.isEmpty) return true;
          final q = _filter.toLowerCase();
          return l.titre.toLowerCase().contains(q) || l.auteur.toLowerCase().contains(q);
        })
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _q,
                  decoration: AppInputDecoration.standard(
                    label: 'Recherche',
                    icon: Icons.search_rounded,
                  ).copyWith(hintText: 'Filtrer par titre ou auteur...'),
                  onChanged: (v) => setState(() => _filter = v.trim()),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Fermer',
              ),
            ],
          ),
        ),
        Expanded(
          child: livreCtrl.isLoading && livres.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Aucun livre chargé. Ouvrez l’onglet Catalogue puis revenez ici.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final l = filtered[i];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 40,
                              height: 56,
                              child: l.couvertureUrl.isNotEmpty
                                  ? Image.network(l.couvertureUrl, fit: BoxFit.cover)
                                  : Container(
                                      color: AppColors.primarySoft,
                                      child: const Icon(Icons.menu_book_rounded, size: 20),
                                    ),
                            ),
                          ),
                          title: Text(l.titre, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(l.auteur),
                          onTap: () => Navigator.pop(context, l),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
