import 'package:flutter/material.dart';

class VoteLivreView extends StatefulWidget {
  final String clubId;
  const VoteLivreView({Key? key, required this.clubId}) : super(key: key);

  @override
  State<VoteLivreView> createState() => _VoteLivreViewState();
}

class _VoteLivreViewState extends State<VoteLivreView> {
  String? selectedLivreId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voter pour un Livre'), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Propositions du mois', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildVoteItem('Le Petit Prince', 'Antoine de Saint-Exupery', 8),
            _buildVoteItem('L Alchimiste', 'Paulo Coelho', 5),
            _buildVoteItem('1984', 'George Orwell', 12),
            const Spacer(),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.all(16)),
                onPressed: selectedLivreId != null ? () {} : null,
                child: const Text('Confirmer mon vote', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteItem(String titre, String auteur, int votes) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<String>(
        value: titre,
        groupValue: selectedLivreId,
        onChanged: (v) => setState(() => selectedLivreId = v),
        title: Text(titre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('\ - \ votes'),
        activeColor: Colors.orange,
      ),
    );
  }
}
