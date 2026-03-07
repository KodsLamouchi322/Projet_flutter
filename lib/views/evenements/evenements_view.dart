import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/evenement_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/evenement.dart';
import '../../utils/constants.dart';
import '../auth/login_view.dart';
import 'evenement_detail_view.dart';

class EvenementsView extends StatefulWidget {
  const EvenementsView({super.key});

  @override
  State<EvenementsView> createState() => _EvenementsViewState();
}

class _EvenementsViewState extends State<EvenementsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvenementController>().chargerEvenements();
    });
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
        title: const Text('Événements'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'À venir'),
            Tab(text: 'Mes inscriptions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _EvenementsAVenirTab(),
          _MesEvenementsTab(),
        ],
      ),
    );
  }
}

class _EvenementsAVenirTab extends StatelessWidget {
  const _EvenementsAVenirTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<EvenementController>(
      builder: (_, ctrl, __) {
        if (ctrl.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.evenements.isEmpty) {
          return _Empty();
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.evenements.length,
          itemBuilder: (_, i) =>
              _EvenementCard(evenement: ctrl.evenements[i]),
        );
      },
    );
  }
}

class _MesEvenementsTab extends StatefulWidget {
  const _MesEvenementsTab();

  @override
  State<_MesEvenementsTab> createState() => _MesEvenementsTabState();
}

class _MesEvenementsTabState extends State<_MesEvenementsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthController>().membre?.uid;
      if (uid != null) {
        context.read<EvenementController>().chargerMesEvenements(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthController>().membre == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 60, color: AppColors.divider),
            const SizedBox(height: 16),
            const Text('Vous n\'êtes pas connecté', style: TextStyle(fontSize: 18, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginView())),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      );
    }
    return Consumer<EvenementController>(
      builder: (_, ctrl, __) {
        if (ctrl.mesEvenements.isEmpty) {
          return const _Empty(message: 'Aucune inscription');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.mesEvenements.length,
          itemBuilder: (_, i) =>
              _EvenementCard(evenement: ctrl.mesEvenements[i]),
        );
      },
    );
  }
}

class _EvenementCard extends StatelessWidget {
  final Evenement evenement;
  const _EvenementCard({required this.evenement});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final uid = auth.membre?.uid ?? '';
    final estInscrit = evenement.estParticipant(uid);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => EvenementDetailView(evenement: evenement)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bannière couleur
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: _categorieColor(evenement.categorie),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _categorieColor(evenement.categorie)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          evenement.categorie,
                          style: TextStyle(
                            fontSize: 11,
                            color: _categorieColor(evenement.categorie),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (estInscrit)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '✓ Inscrit',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.success),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    evenement.titre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(Icons.calendar_today_outlined,
                      _formatDate(evenement.dateDebut)),
                  const SizedBox(height: 4),
                  _InfoRow(Icons.location_on_outlined, evenement.lieu),
                  const SizedBox(height: 4),
                  _InfoRow(
                    Icons.people_outline,
                    '${evenement.participantsIds.length}/${evenement.capaciteMax} participants',
                  ),
                  const SizedBox(height: 12),
                  // Barre de remplissage
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: evenement.capaciteMax > 0
                          ? evenement.participantsIds.length /
                              evenement.capaciteMax
                          : 0,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        evenement.estComplet
                            ? AppColors.error
                            : AppColors.success,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          evenement.estComplet
                              ? 'Complet'
                              : '${evenement.placesRestantes} places restantes',
                          style: TextStyle(
                            fontSize: 12,
                            color: evenement.estComplet
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categorieColor(String cat) {
    switch (cat) {
      case 'Club de lecture':
        return AppColors.primary;
      case 'Atelier écriture':
        return AppColors.accent;
      case 'Conférence':
        return AppColors.accentDark;
      case 'Jeunesse':
        return const Color(0xFF27AE60);
      default:
        return AppColors.primaryLight;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} à ${d.hour}h${d.minute.toString().padLeft(2, '0')}';
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      );
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty({this.message = 'Aucun événement à venir'});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 60, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(message,
                style:
                    const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
}
