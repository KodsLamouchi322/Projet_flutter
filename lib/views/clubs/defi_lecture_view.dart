import 'package:flutter/material.dart';
import '../../models/defi_lecture.dart';

class DefiLectureView extends StatefulWidget {
  final String clubId;
  const DefiLectureView({Key? key, required this.clubId}) : super(key: key);

  @override
  State<DefiLectureView> createState() => _DefiLectureViewState();
}

class _DefiLectureViewState extends State<DefiLectureView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Defis de Lecture'), backgroundColor: Colors.orange),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Defis en cours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.orange),
              title: const Text('Lire 5 livres ce mois'),
              subtitle: const Text('3/5 completes'),
              trailing: const Text('60%', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Decouvrir un nouveau genre'),
              subtitle: const Text('Non commence'),
              trailing: const Text('0%', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau defi'),
        onPressed: () {},
      ),
    );
  }
}
