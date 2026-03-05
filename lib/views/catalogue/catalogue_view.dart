import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/livre_controller.dart';
import '../../models/livre.dart';
import '../../utils/constants.dart';
import '../../widgets/livre_card.dart';
import '../admin/ajouter_livre_view.dart';
import 'livre_detail_view.dart';

/// Écran catalogue — liste, recherche, filtres par genre
class CatalogueView extends StatefulWidget {
  const CatalogueView({super.key});

  @override
  State<CatalogueView> createState() => _CatalogueViewState();
}

class _CatalogueViewState extends State<CatalogueView> {
  final _searchCtrl = TextEditingController();
  bool _viewGrid = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final livreCtrl = context.watch<LivreController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Catalogue'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_viewGrid ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _viewGrid = !_viewGrid),
            tooltip: _viewGrid ? 'Vue liste' : 'Vue grille',
          ),
          if (auth.estAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AjouterLivreView()),
              ),
              tooltip: 'Ajouter un livre',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _BarreRecherche(
            controller: _searchCtrl,
            onChanged: (q) => livreCtrl.rechercher(q),
            onClear: () {
              _searchCtrl.clear();
              livreCtrl.annulerRecherche();
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Filtres genres ──
          _FiltresGenres(
            genreSelectionne: livreCtrl.genreSelectionne,
            onSelect: livreCtrl.filtrerParGenre,
          ),

          // ── Filtres avancés (disponibilité, tri) ──
          _FiltresAvances(
            seulementDisponibles: livreCtrl.filtreDisponiblesSeulement,
            tri: livreCtrl.tri,
            onToggleDisponibles: livreCtrl.basculerDisponiblesSeulement,
            onChangeTri: livreCtrl.changerTri,
          ),

          // ── Résultats ──
          Expanded(
            child: livreCtrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : livreCtrl.livres.isEmpty
                    ? _EmptyState(
                        recherche: livreCtrl.rechercheActive,
                        onReset: () {
                          _searchCtrl.clear();
                          livreCtrl.annulerRecherche();
                          livreCtrl.reinitialiserFiltres();
                        },
                      )
                    : _viewGrid
                        ? _GrilleVue(
                            livres: livreCtrl.livres,
                            onTap: (l) => _voirDetail(context, l),
                          )
                        : _ListeVue(
                            livres: livreCtrl.livres,
                            onTap: (l) => _voirDetail(context, l),
                          ),
          ),
        ],
      ),
    );
  }

  void _voirDetail(BuildContext context, Livre livre) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LivreDetailView(livre: livre)),
    );
  }
}

// ── Barre de recherche ────────────────────────────────────────────────────────
class _BarreRecherche extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _BarreRecherche({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Titre, auteur, genre, ISBN...',
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: const Icon(Icons.search, color: Colors.white60),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white60),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ── Filtres genres ────────────────────────────────────────────────────────────
class _FiltresGenres extends StatelessWidget {
  final String genreSelectionne;
  final ValueChanged<String> onSelect;

  const _FiltresGenres({
    required this.genreSelectionne,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: AppConstants.genres.length,
        itemBuilder: (ctx, i) {
          final genre = AppConstants.genres[i];
          final selected = genre == genreSelectionne;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(genre),
              selected: selected,
              onSelected: (_) => onSelect(genre),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontSize: 12,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        },
      ),
    );
  }
}

// ── Filtres avancés (disponibilité, tri) ─────────────────────────────────────

class _FiltresAvances extends StatelessWidget {
  final bool seulementDisponibles;
  final LivreTri tri;
  final VoidCallback onToggleDisponibles;
  final ValueChanged<LivreTri> onChangeTri;

  const _FiltresAvances({
    required this.seulementDisponibles,
    required this.tri,
    required this.onToggleDisponibles,
    required this.onChangeTri,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Row(
        children: [
          // Disponibilité
          FilterChip(
            label: const Text(
              'Disponibles seulement',
              style: TextStyle(fontSize: 12),
            ),
            selected: seulementDisponibles,
            onSelected: (_) => onToggleDisponibles(),
            backgroundColor: Colors.white,
            selectedColor: AppColors.success.withOpacity(0.15),
            checkmarkColor: AppColors.success,
            labelStyle: TextStyle(
              color: seulementDisponibles
                  ? AppColors.success
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          const Spacer(),
          // Tri par popularité
          ChoiceChip(
            label: const Text('Populaires', style: TextStyle(fontSize: 12)),
            selected: tri == LivreTri.popularite,
            onSelected: (_) => onChangeTri(LivreTri.popularite),
            selectedColor: AppColors.accent.withOpacity(0.2),
            labelStyle: TextStyle(
              color: tri == LivreTri.popularite
                  ? AppColors.accentDark
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          // Tri par nouveauté
          ChoiceChip(
            label: const Text('Nouveautés', style: TextStyle(fontSize: 12)),
            selected: tri == LivreTri.nouveaute,
            onSelected: (_) => onChangeTri(LivreTri.nouveaute),
            selectedColor: AppColors.primaryLight.withOpacity(0.15),
            labelStyle: TextStyle(
              color: tri == LivreTri.nouveaute
                  ? AppColors.primaryDark
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vue liste ─────────────────────────────────────────────────────────────────
class _ListeVue extends StatelessWidget {
  final List<Livre> livres;
  final Function(Livre) onTap;

  const _ListeVue({required this.livres, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: livres.length,
      itemBuilder: (ctx, i) => LivreListTile(
        livre: livres[i],
        onTap: () => onTap(livres[i]),
      ),
    );
  }
}

// ── Vue grille ────────────────────────────────────────────────────────────────
class _GrilleVue extends StatelessWidget {
  final List<Livre> livres;
  final Function(Livre) onTap;

  const _GrilleVue({required this.livres, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: livres.length,
      itemBuilder: (ctx, i) => LivreCard(
        livre: livres[i],
        onTap: () => onTap(livres[i]),
      ),
    );
  }
}

// ── État vide ─────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool recherche;
  final VoidCallback onReset;

  const _EmptyState({required this.recherche, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            recherche ? Icons.search_off : Icons.library_books_outlined,
            size: 72,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            recherche
                ? 'Aucun résultat trouvé'
                : 'Le catalogue est vide',
            style: AppTextStyles.headline2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recherche
                ? 'Essayez avec d\'autres mots-clés'
                : 'Revenez plus tard',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (recherche) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              label: const Text('Réinitialiser'),
            ),
          ]
        ],
      ),
    );
  }
}
