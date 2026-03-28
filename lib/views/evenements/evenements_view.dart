import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/evenement_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/evenement.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/status_badge.dart';
import '../auth/login_view.dart';
import 'evenement_detail_view.dart';

class EvenementsView extends StatefulWidget {
  final bool embeddedInCommunity;
  const EvenementsView({super.key, this.embeddedInCommunity = false});

  @override
  State<EvenementsView> createState() => _EvenementsViewState();
}

class _EvenementsViewState extends State<EvenementsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
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
    final tabs = TabBar(
      controller: _tabCtrl,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: AppColors.accentLight,
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(text: 'À venir'),
        Tab(text: 'Calendrier'),
        Tab(text: 'Mes inscriptions'),
      ],
    );

    final content = TabBarView(
      controller: _tabCtrl,
      children: const [
        _EvenementsAVenirTab(),
        _CalendrierTab(),
        _MesEvenementsTab(),
      ],
    );

    if (widget.embeddedInCommunity) {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppUI.softShadow,
            ),
            child: tabs,
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Événements'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: tabs,
      ),
      body: content,
    );
  }
}

// ─── Onglet Calendrier ────────────────────────────────────────────────────────
class _CalendrierTab extends StatefulWidget {
  const _CalendrierTab();

  @override
  State<_CalendrierTab> createState() => _CalendrierTabState();
}

class _CalendrierTabState extends State<_CalendrierTab> {
  DateTime _moisAffiche = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Consumer<EvenementController>(
      builder: (_, ctrl, __) {
        final evenements = ctrl.evenements;
        return Column(
          children: [
            // Navigation mois
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => _moisAffiche =
                        DateTime(_moisAffiche.year, _moisAffiche.month - 1)),
                  ),
                  Expanded(
                    child: Text(
                      _nomMois(_moisAffiche),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() => _moisAffiche =
                        DateTime(_moisAffiche.year, _moisAffiche.month + 1)),
                  ),
                ],
              ),
            ),
            // Grille calendrier
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _buildGrilleCalendrier(evenements),
            ),
            const Divider(height: 1),
            // Liste des événements du mois
            Expanded(
              child: _buildListeMois(evenements),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGrilleCalendrier(List<Evenement> evenements) {
    final premier = DateTime(_moisAffiche.year, _moisAffiche.month, 1);
    final dernierJour = DateTime(_moisAffiche.year, _moisAffiche.month + 1, 0).day;
    // Lundi = 1, Dimanche = 7
    final debutSemaine = premier.weekday - 1;

    final joursAvecEvenements = <int>{};
    for (final e in evenements) {
      if (e.dateDebut.year == _moisAffiche.year &&
          e.dateDebut.month == _moisAffiche.month) {
        joursAvecEvenements.add(e.dateDebut.day);
      }
    }

    final cells = <Widget>[];
    // En-têtes jours
    for (final j in ['L', 'M', 'M', 'J', 'V', 'S', 'D']) {
      cells.add(Center(
        child: Text(j,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary)),
      ));
    }
    // Cases vides avant le 1er
    for (int i = 0; i < debutSemaine; i++) {
      cells.add(const SizedBox());
    }
    // Jours du mois
    for (int d = 1; d <= dernierJour; d++) {
      final aEvenement = joursAvecEvenements.contains(d);
      final estAujourdhui = DateTime.now().day == d &&
          DateTime.now().month == _moisAffiche.month &&
          DateTime.now().year == _moisAffiche.year;
      cells.add(Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: estAujourdhui
              ? AppColors.primary
              : aEvenement
                  ? AppColors.accent.withOpacity(0.15)
                  : null,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text('$d',
                  style: TextStyle(
                    fontSize: 12,
                    color: estAujourdhui ? Colors.white : AppColors.textPrimary,
                    fontWeight: estAujourdhui ? FontWeight.bold : FontWeight.normal,
                  )),
              if (aEvenement && !estAujourdhui)
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 4, height: 4,
                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: cells,
    );
  }

  Widget _buildListeMois(List<Evenement> evenements) {
    final duMois = evenements
        .where((e) =>
            e.dateDebut.year == _moisAffiche.year &&
            e.dateDebut.month == _moisAffiche.month)
        .toList()
      ..sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    if (duMois.isEmpty) {
      return const Center(
        child: Text('Aucun événement ce mois-ci',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: duMois.length,
      itemBuilder: (_, i) => _EvenementCard(evenement: duMois[i]),
    );
  }

  String _nomMois(DateTime d) {
    const mois = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${mois[d.month - 1]} ${d.year}';
  }
}

class _EvenementsAVenirTab extends StatelessWidget {  const _EvenementsAVenirTab();

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
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final uid = context.read<AuthController>().membre?.uid;
      if (uid != null) {
        context.read<EvenementController>().chargerMesEvenements(uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (auth.membre == null) {
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
        if (ctrl.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.mesEvenements.isEmpty) {
          return const _Empty(message: 'Aucune inscription pour le moment');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.mesEvenements.length,
          itemBuilder: (_, i) => _EvenementCard(evenement: ctrl.mesEvenements[i]),
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: const Border.fromBorderSide(
            BorderSide(color: AppColors.divider, width: 0.5),
          ),
          boxShadow: AppUI.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bannière couleur
            Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _categorieColor(evenement.categorie),
                    AppColors.accentLight,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusBadge(
                        label: evenement.categorie,
                        color: _categorieColor(evenement.categorie),
                      ),
                      const Spacer(),
                      if (estInscrit)
                        const StatusBadge(label: 'Inscrit', color: AppColors.primary),
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
                            ? AppColors.accentDark
                            : AppColors.primary,
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
                                ? AppColors.accentDark
                                : AppColors.primary,
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
        return AppColors.accent;
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
  Widget build(BuildContext context) => EmptyStateWidget(
        icon: Icons.event_busy,
        title: message,
        subtitle: 'Consultez les nouveautés de la communauté.',
      );
}
