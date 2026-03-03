import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_appbar.dart';
import 'ajouter_livre_view.dart';

/// Tableau de bord administrateur
class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final _service = FirestoreService();
  Map<String, int> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    setState(() => _loading = true);
    try {
      _stats = await _service.getStatsGenerales();
    } catch (e) {
      // Erreur ignorée silencieusement
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    // Sécurité : seulement les admins
    if (!auth.estAdmin) {
      return Scaffold(
        appBar: const CustomAppBar(titre: 'Accès refusé'),
        body: const Center(
          child: Text('Vous n\'avez pas accès à cette section.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargerStats,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _chargerStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Accueil admin ──
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadius),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings,
                        color: AppColors.accent, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, ${auth.membre?.prenom ?? 'Admin'} !',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Tableau de bord administrateur',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Statistiques ──
              const _SectionTitle(titre: '📊 Statistiques en temps réel'),
              const SizedBox(height: 12),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _StatAdminCard(
                          titre: 'Total livres',
                          valeur: '${_stats['totalLivres'] ?? 0}',
                          icone: Icons.menu_book,
                          couleur: AppColors.primary,
                        ),
                        _StatAdminCard(
                          titre: 'Disponibles',
                          valeur: '${_stats['livresDisponibles'] ?? 0}',
                          icone: Icons.check_circle_outline,
                          couleur: AppColors.success,
                        ),
                        _StatAdminCard(
                          titre: 'Membres',
                          valeur: '${_stats['totalMembres'] ?? 0}',
                          icone: Icons.people_outline,
                          couleur: AppColors.info,
                        ),
                        _StatAdminCard(
                          titre: 'Emprunts actifs',
                          valeur: '${_stats['empruntsEnCours'] ?? 0}',
                          icone: Icons.bookmark_outline,
                          couleur: AppColors.warning,
                        ),
                      ],
                    ),
              const SizedBox(height: 24),

              // ── Actions rapides ──
              const _SectionTitle(titre: '⚡ Actions rapides'),
              const SizedBox(height: 12),
              _ActionCard(
                titre: 'Ajouter un livre',
                description: 'Enrichir le catalogue',
                icone: Icons.add_box,
                couleur: AppColors.success,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AjouterLivreView()),
                ),
              ),
              _ActionCard(
                titre: 'Gérer les membres',
                description: 'Valider inscriptions, suspensions',
                icone: Icons.manage_accounts,
                couleur: AppColors.info,
                onTap: () {
                  // Semaine 5-6
                  _showComingSoon(context, 'Gestion des membres');
                },
              ),
              _ActionCard(
                titre: 'Valider les emprunts',
                description: 'Confirmer retours et prêts',
                icone: Icons.check_circle,
                couleur: AppColors.primary,
                onTap: () {
                  _showComingSoon(context, 'Validation des emprunts');
                },
              ),
              _ActionCard(
                titre: 'Organiser un événement',
                description: 'Calendrier et inscriptions',
                icone: Icons.event,
                couleur: AppColors.accent,
                onTap: () {
                  _showComingSoon(context, 'Gestion des événements');
                },
              ),

              const SizedBox(height: 24),

              // Fonctionnalités à venir
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadius),
                  border: Border.all(
                      color: AppColors.accent.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text(
                          'Semaines 5-6 : Espace admin complet',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Modération avis & messages\n'
                      '• Statistiques avancées\n'
                      '• Import/Export catalogue\n'
                      '• Rapports automatiques',
                      style:
                          TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bientôt disponible'),
        content: Text(
            '$feature sera disponible en semaine 5-6.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String titre;
  const _SectionTitle({required this.titre});

  @override
  Widget build(BuildContext context) {
    return Text(
      titre,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _StatAdminCard extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icone;
  final Color couleur;

  const _StatAdminCard({
    required this.titre,
    required this.valeur,
    required this.icone,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, color: couleur, size: 28),
          const SizedBox(height: 6),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: couleur,
            ),
          ),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String titre;
  final String description;
  final IconData icone;
  final Color couleur;
  final VoidCallback onTap;

  const _ActionCard({
    required this.titre,
    required this.description,
    required this.icone,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: couleur.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icone, color: couleur),
        ),
        title: Text(
          titre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 14, color: couleur),
      ),
    );
  }
}
