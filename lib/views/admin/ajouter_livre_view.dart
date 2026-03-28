import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../controllers/livre_controller.dart';
import '../../models/livre.dart';
import '../../services/isbn_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/isbn_scan_helper.dart';
import '../../utils/validators.dart';
import '../../widgets/app_buttons.dart';
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
  late final TextEditingController _couvertureCtrl;
  late final TextEditingController _tagsCtrl;
  String _genreSelectionne = '';
  StatutLivre _statut = StatutLivre.disponible;
  int _anneeSelectionnee = DateTime.now().year;
  bool _chargementIsbn = false;

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
    _anneeSelectionnee = (l != null && l.anneePublication > 0)
        ? l.anneePublication
        : DateTime.now().year;
    _couvertureCtrl = TextEditingController(text: l?.couvertureUrl ?? '');
    _tagsCtrl = TextEditingController(text: l?.tags.join(', ') ?? '');
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
    _couvertureCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  /// Ouvre le scanner de code-barres et remplit automatiquement les champs
  Future<void> _scannerIsbn() async {
    final isbn = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _IsbnScannerView()),
    );
    if (isbn == null || isbn.isEmpty) return;

    setState(() {
      _isbnCtrl.text = isbn;
      _chargementIsbn = true;
    });

    AppHelpers.showInfo(context, 'Recherche des informations du livre...');

    final info = await IsbnService.rechercherParIsbn(isbn);

    if (!mounted) return;
    setState(() => _chargementIsbn = false);

    if (info == null) {
      AppHelpers.showError(context, 'Aucune information trouvée pour cet ISBN. Remplissez manuellement.');
      return;
    }

    // Remplissage automatique
    setState(() {
      if (info.titre.isNotEmpty) _titreCtrl.text = info.titre;
      if (info.auteur.isNotEmpty) _auteurCtrl.text = info.auteur;
      if (info.editeur.isNotEmpty) _editeurCtrl.text = info.editeur;
      if (info.annee > 0) _anneeSelectionnee = info.annee;
      if (info.couvertureUrl.isNotEmpty) _couvertureCtrl.text = info.couvertureUrl;
      if (info.resume.isNotEmpty) _resumeCtrl.text = info.resume;
    });

    AppHelpers.showSuccess(context, 'Informations récupérées automatiquement !');
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
      'anneePublication': _anneeSelectionnee,
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
        anneePublication: _anneeSelectionnee,
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
                decoration: AppInputDecoration.standard(
                  label: 'Titre *',
                  icon: Icons.title,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _auteurCtrl,
                validator: (v) =>
                    AppValidators.required(v, label: 'L\'auteur'),
                decoration: AppInputDecoration.standard(
                  label: 'Auteur *',
                  icon: Icons.person_outlined,
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
                      decoration: AppInputDecoration.standard(
                        label: 'ISBN',
                        icon: Icons.tag,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bouton scan ISBN avec remplissage automatique
                  _chargementIsbn
                      ? const SizedBox(
                          width: 44, height: 44,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          onPressed: _scannerIsbn,
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          tooltip: 'Scanner ISBN (remplissage auto)',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _anneeSelectionnee,
                      decoration: AppInputDecoration.standard(
                        label: 'Année',
                        icon: Icons.calendar_today,
                      ),
                      items: List.generate(
                        DateTime.now().year - 1799,
                        (i) => DateTime.now().year - i,
                      ).map((a) => DropdownMenuItem(value: a, child: Text('$a'))).toList(),
                      onChanged: (v) => setState(() => _anneeSelectionnee = v ?? DateTime.now().year),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _editeurCtrl,
                decoration: AppInputDecoration.standard(
                  label: 'Éditeur',
                  icon: Icons.business,
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
                decoration: AppInputDecoration.standard(
                  label: 'Résumé',
                  icon: Icons.subject_rounded,
                ).copyWith(
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
                decoration: AppInputDecoration.standard(
                  label: 'URL de la couverture',
                  icon: Icons.image_outlined,
                ).copyWith(
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
                decoration: AppInputDecoration.standard(
                  label: 'Tags',
                  icon: Icons.label_outline,
                ).copyWith(hintText: 'Ex: aventure, famille, humour'),
              ),
              const SizedBox(height: 24),

              // ── Statut ──
              _SectionLabel(label: 'Statut du livre'),
              const SizedBox(height: 8),
              DropdownButtonFormField<StatutLivre>(
                value: _statut,
                decoration: AppInputDecoration.standard(
                  label: 'Statut',
                  icon: Icons.info_outline,
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
                  : AppPrimaryButton(
                    label: _estModification
                      ? 'Sauvegarder les modifications'
                      : 'Ajouter au catalogue',
                    icon: _estModification ? Icons.save : Icons.add,
                      onPressed: _sauvegarder,
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

/// Vue scanner ISBN avec caméra
class _IsbnScannerView extends StatefulWidget {
  const _IsbnScannerView();
  @override
  State<_IsbnScannerView> createState() => _IsbnScannerViewState();
}

class _IsbnScannerViewState extends State<_IsbnScannerView> {
  late final MobileScannerController _ctrl = MobileScannerController(
    formats: kFormatsScanLivre,
    detectionSpeed: DetectionSpeed.unrestricted,
    facing: CameraFacing.back,
  );
  bool _scanned = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _traiterCapture(BarcodeCapture capture) {
    if (_scanned) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null || raw.isEmpty) continue;
      final isbn = IsbnScanHelper.extraireIsbn(raw);
      if (isbn != null) {
        _scanned = true;
        Navigator.pop(context, isbn);
        return;
      }
    }
    if (capture.barcodes.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun ISBN détecté. Essayez le code-barres EAN-13 ou un QR contenant l’ISBN.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner ISBN'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _ctrl.toggleTorch(),
          ),
        ],
      ),
      body: Stack(children: [
        MobileScanner(
          controller: _ctrl,
          onDetect: _traiterCapture,
        ),
        // Viseur
        Center(
          child: Container(
            width: 280, height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accentLight, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          bottom: 40, left: 0, right: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Code-barres EAN-13 ou QR (URL Open Library, etc.) — tenez le téléphone stable',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ]),
    );
  }
}


/// Vue scanner ISBN avec caméra