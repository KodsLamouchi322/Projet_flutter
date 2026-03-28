import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/livre_controller.dart';
import '../../models/livre.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/livre_card.dart';
import '../admin/ajouter_livre_view.dart';
import 'livre_detail_view.dart';

class CatalogueView extends StatefulWidget {
  const CatalogueView({super.key});
  @override
  State<CatalogueView> createState() => _CatalogueViewState();
}

class _CatalogueViewState extends State<CatalogueView> {
  final _searchCtrl = TextEditingController();
  bool _viewGrid = false;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthController>();
    final livreCtrl = context.watch<LivreController>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Catalogue', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_viewGrid ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _viewGrid = !_viewGrid),
          ),
          if (auth.estAdmin)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AjouterLivreView())),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: _SearchBar(
            controller: _searchCtrl,
            onChanged: livreCtrl.rechercher,
            onClear: () { _searchCtrl.clear(); livreCtrl.annulerRecherche(); },
          ),
        ),
      ),
      body: Column(children: [
        if (livreCtrl.donneesDepuisCache)
          Material(
            color: AppColors.warningLight,
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.cloud_off_rounded, color: AppColors.accentDark),
              title: Text(
                l10n.offlineCatalogBanner,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        // Filtres genres
        _GenreChips(
          selected: livreCtrl.genreSelectionne,
          onSelect: livreCtrl.filtrerParGenre,
        ),
        // Filtres avancés
        _AdvancedFilters(
          seulementDisponibles: livreCtrl.filtreDisponiblesSeulement,
          tri: livreCtrl.tri,
          onToggle: livreCtrl.basculerDisponiblesSeulement,
          onTri: livreCtrl.changerTri,
        ),
        // Résultats
        Expanded(
          child: livreCtrl.isLoading
              ? const Center(child: CircularProgressIndicator())
              : livreCtrl.livres.isEmpty
                  ? _Empty(
                      recherche: livreCtrl.rechercheActive,
                      onReset: () {
                        _searchCtrl.clear();
                        livreCtrl.annulerRecherche();
                        livreCtrl.reinitialiserFiltres();
                      },
                    )
                  : _viewGrid
                      ? _GridView(livres: livreCtrl.livres,
                          onTap: (l) => _detail(context, l))
                      : _ListView(livres: livreCtrl.livres,
                          onTap: (l) => _detail(context, l)),
        ),
      ]),
    );
  }

  void _detail(BuildContext context, Livre l) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => LivreDetailView(livre: l)));
}

// ─── Barre recherche ──────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBar({required this.controller, required this.onChanged, required this.onClear});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
    child: TextField(
      controller: controller, onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Titre, auteur, genre, ISBN...',
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear_rounded, color: Colors.white54), onPressed: onClear)
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    ),
  );
}

// ─── Chips genres ─────────────────────────────────────────────────────────────
class _GenreChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _GenreChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: AppConstants.genres.length,
        itemBuilder: (_, i) {
          final genre = AppConstants.genres[i];
          final sel = genre == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(genre),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  gradient: sel ? AppColors.gradientCard : null,
                  color: sel ? null : (isDark ? AppColors.surfaceVariantDark : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? Colors.transparent
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  ),
                  boxShadow: sel ? AppUI.cardShadow : null,
                ),
                child: Text(genre,
                    style: TextStyle(
                      fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Filtres avancés ──────────────────────────────────────────────────────────
class _AdvancedFilters extends StatelessWidget {
  final bool seulementDisponibles;
  final LivreTri tri;
  final VoidCallback onToggle;
  final ValueChanged<LivreTri> onTri;
  const _AdvancedFilters({required this.seulementDisponibles, required this.tri,
      required this.onToggle, required this.onTri});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(children: [
        _Chip(
          label: 'Disponibles',
          selected: seulementDisponibles,
          color: AppColors.success,
          onTap: onToggle,
        ),
        const SizedBox(width: 8),
        _Chip(
          label: 'Populaires',
          selected: tri == LivreTri.popularite,
          color: AppColors.accent,
          onTap: () => onTri(LivreTri.popularite),
        ),
        const SizedBox(width: 8),
        _Chip(
          label: 'Nouveautés',
          selected: tri == LivreTri.nouveaute,
          color: AppColors.primary,
          onTap: () => onTri(LivreTri.nouveaute),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? color.withValues(alpha: 0.4)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
          )),
    ),
  );
}

// ─── Vues ─────────────────────────────────────────────────────────────────────
class _ListView extends StatelessWidget {
  final List<Livre> livres;
  final Function(Livre) onTap;
  const _ListView({required this.livres, required this.onTap});

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: livres.length,
    itemBuilder: (_, i) => LivreListTile(livre: livres[i], onTap: () => onTap(livres[i])),
  );
}

class _GridView extends StatelessWidget {
  final List<Livre> livres;
  final Function(Livre) onTap;
  const _GridView({required this.livres, required this.onTap});

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3, childAspectRatio: 0.52,
      crossAxisSpacing: 12, mainAxisSpacing: 12,
    ),
    itemCount: livres.length,
    itemBuilder: (_, i) => LivreCard(livre: livres[i], onTap: () => onTap(livres[i])),
  );
}

// ─── État vide ────────────────────────────────────────────────────────────────
class _Empty extends StatelessWidget {
  final bool recherche;
  final VoidCallback onReset;
  const _Empty({required this.recherche, required this.onReset});

  @override
  Widget build(BuildContext context) => EmptyStateWidget(
        icon: recherche ? Icons.search_off_rounded : Icons.library_books_outlined,
        title: recherche ? 'Aucun résultat' : 'Catalogue vide',
        subtitle: recherche ? 'Essayez d\'autres mots-clés' : 'Revenez plus tard',
        action: recherche
            ? AppSecondaryButton(
                label: 'Réinitialiser',
                icon: Icons.refresh_rounded,
                onPressed: onReset,
              )
            : null,
      );
}
