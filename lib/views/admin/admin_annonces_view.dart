import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state_widget.dart';

/// Vue admin pour publier et gérer les annonces importantes
class AdminAnnoncesView extends StatefulWidget {
  const AdminAnnoncesView({super.key});

  @override
  State<AdminAnnoncesView> createState() => _AdminAnnoncesViewState();
}

class _AdminAnnoncesViewState extends State<AdminAnnoncesView> {
  final _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _annonces = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final snap = await _db
          .collection('annonces')
          .get();
      _annonces = snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList()
        ..sort((a, b) {
          final at = a['createdAt'];
          final bt = b['createdAt'];
          if (at == null) return 1;
          if (bt == null) return -1;
          return (bt as Timestamp).compareTo(at as Timestamp);
        });
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _publierAnnonce() async {
    final titreCtrl = TextEditingController();
    final contenuCtrl = TextEditingController();
    String type = 'info';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Nouvelle annonce'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titreCtrl,
                  decoration: AppInputDecoration.standard(
                    label: 'Titre *',
                    icon: Icons.title,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contenuCtrl,
                  maxLines: 3,
                  decoration: AppInputDecoration.standard(
                    label: 'Contenu *',
                    icon: Icons.notes_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: AppInputDecoration.standard(
                    label: 'Type',
                    icon: Icons.category_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'info', child: Text('ℹ️ Information')),
                    DropdownMenuItem(value: 'warning', child: Text('⚠️ Avertissement')),
                    DropdownMenuItem(value: 'success', child: Text('✅ Bonne nouvelle')),
                  ],
                  onChanged: (v) => setS(() => type = v ?? 'info'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Publier')),
          ],
        ),
      ),
    );

    if (ok != true) return;
    if (titreCtrl.text.trim().isEmpty || contenuCtrl.text.trim().isEmpty) {
      AppHelpers.showError(context, 'Titre et contenu requis.');
      return;
    }

    final auth = context.read<AuthController>();
    await _db.collection('annonces').add({
      'titre': titreCtrl.text.trim(),
      'contenu': contenuCtrl.text.trim(),
      'type': type,
      'auteurId': auth.membre?.uid ?? '',
      'auteurNom': auth.membre?.nomComplet ?? 'Admin',
      'createdAt': FieldValue.serverTimestamp(),
      'active': true,
    });

    AppHelpers.showSuccess(context, 'Annonce publiée.');
    _charger();
  }

  Future<void> _supprimerAnnonce(String id) async {
    final ok = await AppHelpers.showConfirmDialog(
      context: context,
      titre: 'Supprimer l\'annonce',
      message: 'Voulez-vous supprimer cette annonce ?',
      confirmLabel: 'Supprimer',
      confirmColor: AppColors.error,
    );
    if (ok != true) return;
    await _db.collection('annonces').doc(id).delete();
    AppHelpers.showSuccess(context, 'Annonce supprimée.');
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Annonces importantes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _publierAnnonce,
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF1A1A1A), // Texte noir foncé
        icon: const Icon(Icons.campaign, color: Color(0xFF1A1A1A)),
        label: const Text('Nouvelle annonce',
            style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _annonces.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.campaign_outlined,
                  title: 'Aucune annonce publiée',
                  subtitle: 'Publiez une annonce importante pour informer les membres.',
                )
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    itemCount: _annonces.length,
                    itemBuilder: (_, i) {
                      final a = _annonces[i];
                      final type = a['type'] ?? 'info';
                      final color = type == 'warning'
                          ? AppColors.warning
                          : type == 'success'
                              ? AppColors.success
                              : AppColors.info;
                      final icon = type == 'warning'
                          ? Icons.warning_amber
                          : type == 'success'
                              ? Icons.check_circle_outline
                              : Icons.info_outline;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          title: Text(a['titre'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a['contenu'] ?? '',
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 2),
                              Text('Par ${a['auteurNom'] ?? 'Admin'}',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error, size: 20),
                            onPressed: () => _supprimerAnnonce(a['id']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
