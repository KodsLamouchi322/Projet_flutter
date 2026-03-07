import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/emprunt_controller.dart';
import '../../models/membre.dart';
import '../../utils/constants.dart';
import '../auth/login_view.dart';

class ProfilView extends StatefulWidget {
  const ProfilView({super.key});

  @override
  State<ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<ProfilView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (auth.membre != null) {
        context
            .read<EmpruntController>()
            .chargerEmpruntsMemebres(auth.membre!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final membre = auth.membre;
    if (membre == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil'), backgroundColor: AppColors.primary, foregroundColor: Colors.white, centerTitle: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 60, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('Vous n\'êtes pas connecté', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginView())),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                child: const Text('Se connecter ou Créer un compte'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: membre.photoUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(membre.photoUrl,
                                    fit: BoxFit.cover))
                            : const Icon(Icons.person,
                                size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${membre.prenom} ${membre.nom}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        membre.email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: membre.estAdmin
                              ? AppColors.accent
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          membre.estAdmin ? '⭐ Administrateur' : 'Membre',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stats
                  _StatsSection(membre: membre),
                  const SizedBox(height: 20),
                  // Menu options
                  _MenuSection(membre: membre),
                  const SizedBox(height: 20),
                  // Bouton déconnexion
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Déconnexion'),
                            content: const Text(
                                'Voulez-vous vraiment vous déconnecter ?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                ),
                                child: const Text('Déconnecter'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          await context.read<AuthController>().deconnecter();
                        }
                      },
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: const Text('Se déconnecter',
                          style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final Membre membre;
  const _StatsSection({required this.membre});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          _StatItem(
              value: '${membre.nbEmpruntsEnCours}',
              label: 'En cours',
              color: AppColors.primary),
          _divider(),
          _StatItem(
              value: '${membre.nbEmpruntsTotal}',
              label: 'Total lus',
              color: AppColors.accent),
          _divider(),
          _StatItem(
              value: membre.statut.name,
              label: 'Statut',
              color: AppColors.success),
        ],
      ),
    );
  }

  Widget _divider() => Container(
      height: 40, width: 1, color: AppColors.divider,
      margin: const EdgeInsets.symmetric(horizontal: 12));
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatItem(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ]),
      );
}

class _MenuSection extends StatelessWidget {
  final Membre membre;
  const _MenuSection({required this.membre});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(Icons.book_outlined, 'Mes emprunts', AppColors.primary, () {}),
      _MenuItem(Icons.bookmark_border, 'Ma wishlist', AppColors.accent, () {}),
      _MenuItem(Icons.history, 'Historique', AppColors.primaryLight, () {}),
      _MenuItem(Icons.edit_outlined, 'Modifier le profil', AppColors.accentDark, () {}),
      _MenuItem(Icons.star_border, 'Genres préférés', AppColors.accentLight, () {}),
      _MenuItem(Icons.settings_outlined, 'Paramètres', AppColors.textSecondary, () {}),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: items
            .asMap()
            .entries
            .map((e) => Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: e.value.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(e.value.icon,
                            color: e.value.color, size: 20),
                      ),
                      title: Text(e.value.label,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.textSecondary, size: 20),
                      onTap: e.value.onTap,
                    ),
                    if (e.key < items.length - 1)
                      const Divider(
                          height: 0,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.divider),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.color, this.onTap);
}
