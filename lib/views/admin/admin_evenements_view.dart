import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/evenement.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/evenement_controller.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Gestion des événements côté administrateur :
/// - liste des événements
/// - création / modification / suppression
class AdminEvenementsView extends StatefulWidget {
  const AdminEvenementsView({super.key});

  @override
  State<AdminEvenementsView> createState() => _AdminEvenementsViewState();
}

class _AdminEvenementsViewState extends State<AdminEvenementsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvenementController>().chargerTousEvenements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.estAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Événements'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Accès réservé aux administrateurs.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestion des événements'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<EvenementController>(
        builder: (_, ctrl, __) {
          if (ctrl.isLoading && ctrl.evenements.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ctrl.evenements.isEmpty) {
            return const _EmptyAdminEvenements();
          }

          return RefreshIndicator(
            onRefresh: () => ctrl.chargerTousEvenements(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              itemCount: ctrl.evenements.length,
              itemBuilder: (_, i) {
                final e = ctrl.evenements[i];
                return _AdminEvenementTile(evenement: e);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const _EvenementFormView(),
            ),
          );
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add),
        label: const Text('Nouvel événement'),
      ),
    );
  }
}

class _AdminEvenementTile extends StatelessWidget {
  final Evenement evenement;

  const _AdminEvenementTile({required this.evenement});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<EvenementController>();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _EvenementFormView(evenement: evenement),
            ),
          );
        },
        title: Text(
          evenement.titre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(evenement.dateDebut),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '${evenement.participantsIds.length}/${evenement.capaciteMax} participants',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: () async {
            final confirme = await AppHelpers.showConfirmDialog(
              context: context,
              titre: 'Supprimer l\'événement',
              message:
                  'Voulez-vous vraiment supprimer \"${evenement.titre}\" ?',
              confirmLabel: 'Supprimer',
              confirmColor: AppColors.error,
            );
            if (confirme != true) return;

            final ok = await ctrl.supprimerEvenement(evenement.id);
            if (context.mounted) {
              if (ok) {
                AppHelpers.showSuccess(
                    context, 'Événement supprimé avec succès.');
              } else {
                AppHelpers.showError(
                  context,
                  ctrl.errorMessage ?? AppConstants.erreurInconnu,
                );
              }
            }
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} à ${d.hour}h${d.minute.toString().padLeft(2, '0')}';
}

class _EmptyAdminEvenements extends StatelessWidget {
  const _EmptyAdminEvenements();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy,
                size: 64, color: AppColors.divider),
            const SizedBox(height: 16),
            const Text(
              'Aucun événement pour le moment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez votre premier événement culturel pour la bibliothèque.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulaire de création / édition d'un événement
class _EvenementFormView extends StatefulWidget {
  final Evenement? evenement;

  const _EvenementFormView({this.evenement});

  @override
  State<_EvenementFormView> createState() => _EvenementFormViewState();
}

class _EvenementFormViewState extends State<_EvenementFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titreCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _lieuCtrl;
  late TextEditingController _capaciteCtrl;
  String _categorie = Evenement.categories.first;
  bool _estPublic = true;
  late DateTime _dateDebut;
  late DateTime _dateFin;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.evenement;
    _titreCtrl = TextEditingController(text: e?.titre ?? '');
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _lieuCtrl = TextEditingController(text: e?.lieu ?? '');
    _capaciteCtrl =
        TextEditingController(text: e != null ? '${e.capaciteMax}' : '');
    _categorie = e?.categorie ?? Evenement.categories.first;
    _estPublic = e?.estPublic ?? true;
    _dateDebut = e?.dateDebut ?? DateTime.now().add(const Duration(days: 1));
    _dateFin = e?.dateFin ?? _dateDebut.add(const Duration(hours: 2));
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descriptionCtrl.dispose();
    _lieuCtrl.dispose();
    _capaciteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estEdition = widget.evenement != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(estEdition ? 'Modifier l\'événement' : 'Nouvel événement'),
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
                controller: _titreCtrl,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Titre requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Description requise' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lieuCtrl,
                decoration: const InputDecoration(labelText: 'Lieu'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Lieu requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capaciteCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Capacité maximale'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Capacité requise';
                  final value = int.tryParse(v);
                  if (value == null || value <= 0) {
                    return 'Capacité invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'Date début',
                      date: _dateDebut,
                      onChanged: (d) =>
                          setState(() => _dateDebut = d ?? _dateDebut),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateButton(
                      label: 'Date fin',
                      date: _dateFin,
                      onChanged: (d) =>
                          setState(() => _dateFin = d ?? _dateFin),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categorie,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: Evenement.categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _categorie = v);
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _estPublic,
                onChanged: (v) => setState(() => _estPublic = v),
                title: const Text('Événement public'),
                subtitle: const Text(
                    'Si désactivé, visible seulement par les membres inscrits.'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : () => _save(context),
                  icon: Icon(estEdition ? Icons.save : Icons.check),
                  label: Text(estEdition ? 'Enregistrer' : 'Créer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateFin.isBefore(_dateDebut)) {
      AppHelpers.showError(
          context, 'La date de fin doit être après la date de début.');
      return;
    }

    setState(() => _saving = true);

    final ctrl = context.read<EvenementController>();
    final auth = context.read<AuthController>();
    final organisateurId = auth.membre?.uid ?? '';

    final capacite = int.parse(_capaciteCtrl.text);

    final now = DateTime.now();
    final existant = widget.evenement;

    final evenement = existant == null
        ? Evenement(
            id: '',
            titre: _titreCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            dateDebut: _dateDebut,
            dateFin: _dateFin,
            lieu: _lieuCtrl.text.trim(),
            capaciteMax: capacite,
            participantsIds: const [],
            organisateurId: organisateurId,
            imageUrl: null,
            categorie: _categorie,
            estPublic: _estPublic,
            createdAt: now,
          )
        : existant.copyWith(
            titre: _titreCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            dateDebut: _dateDebut,
            dateFin: _dateFin,
            lieu: _lieuCtrl.text.trim(),
            capaciteMax: capacite,
            categorie: _categorie,
            estPublic: _estPublic,
          );

    bool ok;
    if (existant == null) {
      ok = await ctrl.creerEvenement(evenement);
    } else {
      ok = await ctrl.modifierEvenement(evenement);
    }

    setState(() => _saving = false);

    if (!mounted) return;

    if (ok) {
      AppHelpers.showSuccess(
        context,
        existant == null
            ? 'Événement créé avec succès.'
            : 'Événement mis à jour.',
      );
      Navigator.pop(context);
    } else {
      AppHelpers.showError(
        context,
        ctrl.errorMessage ?? AppConstants.erreurInconnu,
      );
    }
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime?> onChanged;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (pickedDate == null) return;
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(date),
        );
        if (pickedTime == null) {
          onChanged(pickedDate);
        } else {
          onChanged(DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ));
        }
      },
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(
        '$label\n${_formatDate(date)}',
        textAlign: TextAlign.left,
        style: const TextStyle(fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
}

