import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/membre.dart';
import '../../controllers/auth_controller.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/status_badge.dart';

/// Gestion simple des membres : liste + activation/suspension.
class AdminMembresView extends StatefulWidget {
  const AdminMembresView({super.key});

  @override
  State<AdminMembresView> createState() => _AdminMembresViewState();
}

class _AdminMembresViewState extends State<AdminMembresView> {
  final _service = FirestoreService();
  List<Membre> _membres = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _membres = await _service.getTousMembres();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.estAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Membres'),
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
        title: const Text('Gestion des membres'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _membres.isEmpty
                    ? const _EmptyMembres()
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.all(AppSizes.paddingMedium),
                        itemCount: _membres.length,
                        itemBuilder: (_, i) => _MembreTile(
                          membre: _membres[i],
                          onChanged: (updated) {
                            setState(() {
                              _membres[i] = updated;
                            });
                          },
                        ),
                      ),
      ),
    );
  }
}

class _MembreTile extends StatelessWidget {
  final Membre membre;
  final ValueChanged<Membre> onChanged;

  const _MembreTile({required this.membre, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final actif = membre.statut == StatutMembre.actif;
    final roleLabel = membre.estAdmin ? 'Admin' : 'Membre';
    final roleColor = membre.estAdmin ? AppColors.info : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            AppHelpers.getInitiales(membre.nom, membre.prenom),
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          membre.nomComplet,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              membre.email,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                StatusBadge(label: roleLabel, color: roleColor),
                const SizedBox(width: 8),
                StatusBadge(
                  label: actif ? 'Actif' : 'Suspendu',
                  color: actif ? AppColors.success : AppColors.error,
                ),
              ],
            ),
            if (membre.genresPreferes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: membre.genresPreferes.map((g) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(g, style: const TextStyle(fontSize: 10, color: AppColors.accentDark)),
                )).toList(),
              ),
            ],
          ],
        ),
        trailing: Switch(
          value: actif,
          activeColor: AppColors.success,
          onChanged: (value) async {
            final nouveauStatut =
                value ? StatutMembre.actif.name : StatutMembre.suspendu.name;
            try {
              await FirestoreService()
                  .changerStatutMembre(membre.uid, nouveauStatut);
              final updated = membre.copyWith(
                statut:
                    value ? StatutMembre.actif : StatutMembre.suspendu,
              );
              onChanged(updated);
            } catch (e) {
              if (context.mounted) {
                AppHelpers.showError(
                  context,
                  'Impossible de modifier le statut.',
                );
              }
            }
          },
        ),
      ),
    );
  }
}

class _EmptyMembres extends StatelessWidget {
  const _EmptyMembres();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.people_outline,
      title: 'Aucun membre trouvé',
      subtitle: 'Les membres de la bibliothèque apparaîtront dans cette liste.',
    );
  }
}

