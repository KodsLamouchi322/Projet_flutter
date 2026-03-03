import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/livre_controller.dart';
import '../../models/livre.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_appbar.dart';

/// Formulaire d'ajout / modification d'un livre (Admin)
class AjouterLivreView extends StatefulWidget {
  final Livre? livre; // null = ajout, non-null = modification

  const AjouterLivreView({super.key, this.livre});

  @override
  State<AjouterLivreView> createState() => _AjouterLivreViewState();
}

class _AjouterLivreViewState extends State<AjouterLivreView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titreCtrl;
  late final TextEditingController _auteurCtrl;
  late final TextEditingController _isbnCtrl;
  late final TextEditingController _resumeCtrl;
  late final TextEditingController _editeurCtrl;
  late final TextEditingController _anneeCtrl;
  late final TextEditingController _couvertureCtrl;
  late final TextEditingController _tagsCtrl;
  String _genreSelectionne = '';
  StatutLivre _statut = StatutLivre.disponible;

  bool get _estModification => widget.livre != null;

  @override
  void initState() {
    super.initState();
    final l = widget.livre;
    _titreCtrl = TextEditingController(text: l?.titre ?? '');
    _auteurCtrl = TextEditingController(text: l?.auteur ?? '');
    _isbnCtrl = TextEditingController(text: l?.isbn ?? '');
    _resumeCtrl = TextEditingController(text: l?.resume ?? '');
    _editeurCtrl = TextEditingController(text: l?.editeur ?? '');
    _anneeCtrl = TextEditingController(
        text: l != null && l.anneePublication > 0
            ? '${l.anneePublication}'
            : '');
    _couvertureCtrl = TextEditingController(text: l?.couvertureUrl ?? '');
    _tagsCtrl = TextEditingController(
        text: l?.tags.join(', ') ?? '');
    _genreSelectionne = l?.genre ?? '';
    _statut = l?.statut ?? StatutLivre.disponible;
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _auteurCtrl.dispose();
    _isbnCtrl.dispose();
    _resumeCtrl.dispose();
    _editeurCtrl.dispose();
    _anneeCtrl.dispose();
    _couvertureCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    final livreCtrl = context.read<LivreController>();

    // Parser les tags
    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final data = {
      'titre': _titreCtrl.text.trim(),
      'auteur': _auteurCtrl.text.trim(),
      'isbn': _isbnCtrl.text.trim(),
      'genre': _genreSelectionne,
      'resume': _resumeCtrl.text.trim(),
      'editeur': _editeurCtrl.text.trim(),
      'anneePublication':
          int.tryParse(_anneeCtrl.text.trim()) ?? 0,
      'couvertureUrl': _couvertureCtrl.text.trim(),
      'tags': tags,
      'statut': _statut.name,
    };

    bool ok;
    if (_estModification) {
      ok = await livreCtrl.modifierLivre(widget.livre!.id, data);
    } else {
      final nouveauLivre = Livre(
        id: '',
        titre: data['titre'] as String,
        auteur: data['auteur'] as String,
        isbn: data['isbn'] as String,
        genre: data['genre'] as String,
        resume: data['resume'] as String,
        editeur: data['editeur'] as String,
        anneePublication: data['anneePublication'] as int,
        couvertureUrl: data['couvertureUrl'] as String,
        tags: data['tags'] as List<String>,
        statut: _statut,
        dateAjout: DateTime.now(),
      );
      ok = await livreCtrl.ajouterLivre(nouveauLivre);
    }

    if (mounted) {
      if (ok) {
        AppHelpers.showSuccess(
          context,
          _estModification
              ? 'Livre modifié avec succès !'
              : 'Livre ajouté au catalogue !',
        );
        Navigator.pop(context);
      } else {
        AppHelpers.showError(
          context,
          livreCtrl.errorMessage ?? 'Erreur',
        );
      }
    }
  }

  Future<void> _supprimer() async {
    if (!_estModification) return;

    final confirm = await AppHelpers.showConfirmDialog(
      context: context,
      titre: 'Supprimer le livre',
      message:
          'Voulez-vous vraiment supprimer "${widget.livre!.titre}" ?',
      confirmLabel: 'Supprimer',
      confirmColor: AppColors.error,
    );

    if (confirm == true && mounted) {
      final ok = await context
          .read<LivreController>()
          .supprimerLivre(widget.livre!.id);
      if (ok && mounted) {
        AppHelpers.showSuccess(context, 'Livre supprimé.');
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final livreCtrl = context.watch<LivreController>();

    return Scaffold(
      appBar: CustomAppBar(
        titre: _estModification ? 'Modifier le livre' : 'Ajouter un livre',
        actions: _estModification
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _supprimer,
                  tooltip: 'Supprimer',
                ),
              ]
            : null,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Infos principales ──
              _SectionLabel(label: 'Informations principales'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _titreCtrl,
                validator: (v) =>
                    AppValidators.required(v, label: 'Le titre'),
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _auteurCtrl,
                validator: (v) =>
                    AppValidators.required(v, label: 'L\'auteur'),
                decoration: const InputDecoration(
                  labelText: 'Auteur *',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _isbnCtrl,
                      validator: AppValidators.isbn,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ISBN',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _anneeCtrl,
                      validator: AppValidators.annee,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Année',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _editeurCtrl,
                decoration: const InputDecoration(
                  labelText: 'Éditeur',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 24),

              // ── Genre ──
              _SectionLabel(label: 'Genre littéraire *'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: AppConstants.genres.map((g) {
                  final selected = g == _genreSelectionne;
                  return ChoiceChip(
                    label: Text(g),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _genreSelectionne = g),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Résumé ──
              _SectionLabel(label: 'Résumé'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _resumeCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Description du livre...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // ── Médias ──
              _SectionLabel(label: 'Image de couverture'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _couvertureCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL de la couverture',
                  prefixIcon: Icon(Icons.image_outlined),
                  hintText: 'https://...',
                ),
              ),
              // Prévisualisation
              if (_couvertureCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadiusSmall),
                  child: Image.network(
                    _couvertureCtrl.text,
                    height: 120,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // ── Tags ──
              _SectionLabel(label: 'Tags (séparés par des virgules)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tagsCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ex: aventure, famille, humour',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 24),

              // ── Statut ──
              _SectionLabel(label: 'Statut du livre'),
              const SizedBox(height: 8),
              DropdownButtonFormField<StatutLivre>(
                value: _statut,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.info_outline),
                ),
                items: StatutLivre.values.map((s) {
                  final labels = {
                    StatutLivre.disponible: '✅ Disponible',
                    StatutLivre.emprunte: '📖 Emprunté',
                    StatutLivre.reserve: '🔖 Réservé',
                    StatutLivre.endommage: '⚠️ Endommagé',
                  };
                  return DropdownMenuItem(
                    value: s,
                    child: Text(labels[s] ?? s.name),
                  );
                }).toList(),
                onChanged: (v) =>
                    setState(() => _statut = v ?? StatutLivre.disponible),
              ),
              const SizedBox(height: 32),

              // ── Bouton ──
              livreCtrl.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _sauvegarder,
                      icon: Icon(
                          _estModification ? Icons.save : Icons.add),
                      label: Text(
                        _estModification
                            ? 'Sauvegarder les modifications'
                            : 'Ajouter au catalogue',
                      ),
                    ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
