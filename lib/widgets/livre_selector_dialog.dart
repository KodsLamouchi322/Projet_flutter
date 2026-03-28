import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/livre.dart';
import '../utils/constants.dart';

/// Dialog pour sélectionner un livre du catalogue
class LivreSelectorDialog extends StatefulWidget {
  const LivreSelectorDialog({super.key});

  @override
  State<LivreSelectorDialog> createState() => _LivreSelectorDialogState();
}

class _LivreSelectorDialogState extends State<LivreSelectorDialog> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Sélectionner un livre',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Liste des livres
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('livres')
                    .where('disponible', isEqualTo: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var livres = snap.data!.docs
                      .map((d) => Livre.fromFirestore(d))
                      .where((l) =>
                          _searchQuery.isEmpty ||
                          l.titre.toLowerCase().contains(_searchQuery) ||
                          l.auteur.toLowerCase().contains(_searchQuery))
                      .toList();

                  if (livres.isEmpty) {
                    return const Center(
                      child: Text('Aucun livre disponible'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: livres.length,
                    itemBuilder: (context, i) {
                      final livre = livres[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: livre.couvertureUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    livre.couvertureUrl,
                                    width: 40,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.book),
                                  ),
                                )
                              : const Icon(Icons.book),
                          title: Text(
                            livre.titre,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(livre.auteur),
                          onTap: () => Navigator.pop(context, livre),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
