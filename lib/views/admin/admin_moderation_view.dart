import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Vue admin pour modérer les avis sur les livres et les messages du forum
class AdminModerationView extends StatefulWidget {
  const AdminModerationView({super.key});

  @override
  State<AdminModerationView> createState() => _AdminModerationViewState();
}

class _AdminModerationViewState extends State<AdminModerationView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modération'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'Avis'),
            Tab(text: 'Forum'),
            Tab(text: 'Signalements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _AvisModerationTab(),
          _ForumModerationTab(),
          _SignalementsTab(),
        ],
      ),
    );
  }
}

// ─── Onglet modération des avis ───────────────────────────────────────────────
class _AvisModerationTab extends StatefulWidget {
  const _AvisModerationTab();

  @override
  State<_AvisModerationTab> createState() => _AvisModerationTabState();
}

class _AvisModerationTabState extends State<_AvisModerationTab> {
  final _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _avis = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      // Récupère tous les livres qui ont des avis
      final snap = await _db
          .collection(AppConstants.colLivres)
          .where('nbAvis', isGreaterThan: 0)
          .get();

      final List<Map<String, dynamic>> tous = [];
      for (final doc in snap.docs) {
        final data = doc.data();
        final avis = List<Map<String, dynamic>>.from(data['avis'] ?? []);
        for (final a in avis) {
          tous.add({
            ...a,
            'livreId': doc.id,
            'livreTitre': data['titre'] ?? '',
          });
        }
      }
      _avis = tous;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _supprimerAvis(String livreId, String membreId) async {
    final ok = await AppHelpers.showConfirmDialog(
      context: context,
      titre: 'Supprimer l\'avis',
      message: 'Voulez-vous supprimer cet avis ?',
      confirmLabel: 'Supprimer',
      confirmColor: AppColors.error,
    );
    if (ok != true) return;

    final docRef = _db.collection(AppConstants.colLivres).doc(livreId);
    await _db.runTransaction((tx) async {
      final doc = await tx.get(docRef);
      final data = doc.data() as Map<String, dynamic>;
      final avis = List<Map<String, dynamic>>.from(data['avis'] ?? []);
      avis.removeWhere((a) => a['membreId'] == membreId);
      final avg = avis.isEmpty
          ? 0.0
          : avis.fold<double>(0, (s, a) => s + (a['note'] as num)) / avis.length;
      tx.update(docRef, {'avis': avis, 'noteMoyenne': avg, 'nbAvis': avis.length});
    });

    AppHelpers.showSuccess(context, 'Avis supprimé.');
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_avis.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 64, color: AppColors.divider),
            SizedBox(height: 16),
            Text('Aucun avis à modérer',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        itemCount: _avis.length,
        itemBuilder: (_, i) {
          final a = _avis[i];
          final note = (a['note'] as num?)?.toDouble() ?? 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('${note.toInt()}★',
                      style: const TextStyle(
                          color: AppColors.accent, fontWeight: FontWeight.bold)),
                ),
              ),
              title: Text(a['livreTitre'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Par ${a['membreNom'] ?? ''}',
                      style: const TextStyle(fontSize: 12)),
                  if ((a['commentaire'] ?? '').isNotEmpty)
                    Text(a['commentaire'],
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 20),
                onPressed: () =>
                    _supprimerAvis(a['livreId'], a['membreId'] ?? ''),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Onglet modération du forum ───────────────────────────────────────────────
class _ForumModerationTab extends StatefulWidget {
  const _ForumModerationTab();

  @override
  State<_ForumModerationTab> createState() => _ForumModerationTabState();
}

class _ForumModerationTabState extends State<_ForumModerationTab> {
  final _db = FirebaseFirestore.instance;

  Future<void> _supprimerMessage(String id) async {
    final ok = await AppHelpers.showConfirmDialog(
      context: context,
      titre: 'Supprimer le message',
      message: 'Voulez-vous supprimer ce message du forum ?',
      confirmLabel: 'Supprimer',
      confirmColor: AppColors.error,
    );
    if (ok != true) return;
    await _db.collection(AppConstants.colForum).doc(id).delete();
    AppHelpers.showSuccess(context, 'Message supprimé.');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection(AppConstants.colForum)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_outlined, size: 64, color: AppColors.divider),
                SizedBox(height: 16),
                Text('Aucun message dans le forum',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    (data['expediteurNom'] ?? '?')[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
                title: Text(data['expediteurNom'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['contenu'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12)),
                    Text('Forum : ${data['forumGenre'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
                  onPressed: () => _supprimerMessage(docs[i].id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Onglet signalements livres endommagés ────────────────────────────────────
class _SignalementsTab extends StatefulWidget {
  const _SignalementsTab();

  @override
  State<_SignalementsTab> createState() => _SignalementsTabState();
}

class _SignalementsTabState extends State<_SignalementsTab> {
  final _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _signalements = [];
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
          .collection(AppConstants.colLivres)
          .where('signalementDommage', isNull: false)
          .get();
      _signalements = snap.docs
          .where((d) => (d.data()['signalementDommage'] ?? '').toString().isNotEmpty)
          .map((d) => {'id': d.id, ...d.data()})
          .toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _marquerTraite(String livreId) async {
    final ok = await AppHelpers.showConfirmDialog(
      context: context,
      titre: 'Marquer comme traité',
      message: 'Supprimer ce signalement ?',
      confirmLabel: 'Confirmer',
    );
    if (ok != true) return;
    await _db.collection(AppConstants.colLivres).doc(livreId).update({
      'signalementDommage': FieldValue.delete(),
      'dateSignalement': FieldValue.delete(),
    });
    AppHelpers.showSuccess(context, 'Signalement traité.');
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_signalements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
            SizedBox(height: 16),
            Text('Aucun signalement en attente',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        itemCount: _signalements.length,
        itemBuilder: (_, i) {
          final s = _signalements[i];
          final dateSignalement = s['dateSignalement'] != null
              ? AppHelpers.formatDateHeure((s['dateSignalement'] as Timestamp).toDate())
              : '';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.report_problem_outlined, color: AppColors.error),
              ),
              title: Text(s['titre'] ?? 'Livre inconnu',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['signalementDommage'] ?? '',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  if (dateSignalement.isNotEmpty)
                    Text('Signalé le $dateSignalement',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              isThreeLine: true,
              trailing: TextButton(
                onPressed: () => _marquerTraite(s['id']),
                child: const Text('Traité', style: TextStyle(color: AppColors.success, fontSize: 12)),
              ),
            ),
          );
        },
      ),
    );
  }
}
