import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/membre.dart';
import '../../utils/constants.dart';
import '../../widgets/app_buttons.dart';

/// Édition simple du profil : nom, prénom, téléphone, genres préférés.
class ProfilEditView extends StatefulWidget {
  final Membre membre;
  final bool focusGenres;

  const ProfilEditView({
    super.key,
    required this.membre,
    this.focusGenres = false,
  });

  @override
  State<ProfilEditView> createState() => _ProfilEditViewState();
}

class _ProfilEditViewState extends State<ProfilEditView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _prenomCtrl;
  late TextEditingController _nomCtrl;
  late TextEditingController _telCtrl;
  late List<String> _genresPreferes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prenomCtrl = TextEditingController(text: widget.membre.prenom);
    _nomCtrl = TextEditingController(text: widget.membre.nom);
    _telCtrl = TextEditingController(text: widget.membre.telephone);
    _genresPreferes = List<String>.from(widget.membre.genresPreferes);
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.editProfile),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _prenomCtrl,
                decoration: AppInputDecoration.standard(
                  label: 'Prénom',
                  icon: Icons.person_outline_rounded,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nomCtrl,
                decoration: AppInputDecoration.standard(
                  label: 'Nom',
                  icon: Icons.badge_outlined,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telCtrl,
                decoration: AppInputDecoration.standard(
                  label: 'Téléphone (optionnel)',
                  icon: Icons.phone_outlined,
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              const Text(
                'Genres préférés',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: AppConstants.genres.map((g) {
                  final selected = _genresPreferes.contains(g);
                  return FilterChip(
                    label: Text(g),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        if (selected) {
                          _genresPreferes.remove(g);
                        } else {
                          _genresPreferes.add(g);
                        }
                      });
                    },
                    selectedColor: AppColors.accent.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.accentDark
                          : AppColors.textPrimary,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppPrimaryButton(
                  label: _saving ? 'Enregistrement...' : 'Enregistrer',
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final auth = context.read<AuthController>();
    final ok = await auth.mettreAJourProfil({
      'prenom': _prenomCtrl.text.trim(),
      'nom': _nomCtrl.text.trim(),
      'telephone': _telCtrl.text.trim(),
      'genresPreferes': _genresPreferes,
    });

    setState(() => _saving = false);

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
    }
  }
}

