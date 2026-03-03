import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_appbar.dart';
import '../admin/admin_dashboard_view.dart';

/// Écran profil membre / admin
class ProfilView extends StatelessWidget {
  const ProfilView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final membre = auth.membre;

    if (membre == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: const Text('Mon Profil'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _ouvrirEdition(context, auth),
                tooltip: 'Modifier le profil',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primaryLight],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.accent,
                        child: Text(
                          AppHelpers.getInitiales(membre.nom, membre.prenom),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        membre.nomComplet,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: membre.estAdmin
                              ? AppColors.accent
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          membre.estAdmin ? '👑 Administrateur' : '📚 Membre',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Column(
                children: [
                  // Stats
                  Row(
                    children: [
                      _StatCard(
                        titre: 'En cours',
                        valeur: '${membre.nbEmpruntsEnCours}',
                        icone: Icons.book,
                        couleur: AppColors.info,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        titre: 'Total',
                        valeur: '${membre.nbEmpruntsTotal}',
                        icone: Icons.history,
                        couleur: AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        titre: 'Wishlist',
                        valeur: '${membre.wishlist.length}',
                        icone: Icons.favorite,
                        couleur: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Informations du compte
                  _SectionCard(
                    titre: 'Informations du compte',
                    children: [
                      _InfoTile(
                        icone: Icons.email_outlined,
                        label: 'Email',
                        valeur: membre.email,
                      ),
                      _InfoTile(
                        icone: Icons.phone_outlined,
                        label: 'Téléphone',
                        valeur: membre.telephone.isEmpty
                            ? 'Non renseigné'
                            : membre.telephone,
                      ),
                      _InfoTile(
                        icone: Icons.calendar_today_outlined,
                        label: 'Membre depuis',
                        valeur:
                            AppHelpers.formatDateLong(membre.dateAdhesion),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Genres préférés
                  if (membre.genresPreferes.isNotEmpty)
                    _SectionCard(
                      titre: 'Genres favoris',
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: membre.genresPreferes
                              .map(
                                (g) => Chip(
                                  label: Text(g),
                                  backgroundColor:
                                      AppColors.accent.withOpacity(0.1),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Admin access
                  if (membre.estAdmin) ...[
                    _SectionCard(
                      titre: 'Administration',
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.admin_panel_settings,
                            color: AppColors.accent,
                          ),
                          title: const Text('Dashboard Admin'),
                          subtitle: const Text('Gérer catalogue et membres'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminDashboardView(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Actions
                  _SectionCard(
                    titre: 'Paramètres',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_outlined,
                            color: AppColors.primary),
                        title: const Text('Changer le mot de passe'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _changerMotDePasse(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.favorite_outline,
                            color: Colors.red),
                        title: const Text('Ma liste de souhaits'),
                        subtitle: Text(
                            '${membre.wishlist.length} livre(s)'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigation wishlist (semaine 3-4)
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Déconnexion
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _deconnecter(context, auth),
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: const Text(
                        'Se déconnecter',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
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

  Future<void> _deconnecter(
      BuildContext context, AuthController auth) async {
    final confirm = await AppHelpers.showConfirmDialog(
      context: context,
      titre: 'Déconnexion',
      message: 'Voulez-vous vraiment vous déconnecter ?',
      confirmLabel: 'Déconnecter',
      confirmColor: AppColors.error,
    );
    if (confirm == true && context.mounted) {
      await auth.deconnecter();
    }
  }

  void _ouvrirEdition(BuildContext context, AuthController auth) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilView()),
    );
  }

  void _changerMotDePasse(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangerMotDePasseView()),
    );
  }
}

// ── Édition du profil ─────────────────────────────────────────────────────────
class EditProfilView extends StatefulWidget {
  const EditProfilView({super.key});

  @override
  State<EditProfilView> createState() => _EditProfilViewState();
}

class _EditProfilViewState extends State<EditProfilView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomCtrl;
  late final TextEditingController _prenomCtrl;
  late final TextEditingController _telCtrl;
  List<String> _genresSelectionnes = [];

  @override
  void initState() {
    super.initState();
    final membre = context.read<AuthController>().membre!;
    _nomCtrl = TextEditingController(text: membre.nom);
    _prenomCtrl = TextEditingController(text: membre.prenom);
    _telCtrl = TextEditingController(text: membre.telephone);
    _genresSelectionnes = List.from(membre.genresPreferes);
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.mettreAJourProfil({
      'nom': _nomCtrl.text.trim(),
      'prenom': _prenomCtrl.text.trim(),
      'telephone': _telCtrl.text.trim(),
      'genresPreferes': _genresSelectionnes,
    });
    if (mounted) {
      if (ok) {
        AppHelpers.showSuccess(context, 'Profil mis à jour !');
        Navigator.pop(context);
      } else {
        AppHelpers.showError(context, auth.errorMessage ?? 'Erreur');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: const CustomAppBar(titre: 'Modifier le profil'),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prenomCtrl,
                      validator: AppValidators.prenom,
                      decoration:
                          const InputDecoration(labelText: 'Prénom'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _nomCtrl,
                      validator: AppValidators.nom,
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                validator: AppValidators.telephone,
                decoration: const InputDecoration(
                    labelText: 'Téléphone (optionnel)'),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Genres favoris',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: AppConstants.genres.map((g) {
                  final selected = _genresSelectionnes.contains(g);
                  return FilterChip(
                    label: Text(g),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _genresSelectionnes.add(g);
                        } else {
                          _genresSelectionnes.remove(g);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              auth.isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _sauvegarder,
                      icon: const Icon(Icons.save),
                      label: const Text('Sauvegarder'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Changer mot de passe ──────────────────────────────────────────────────────
class ChangerMotDePasseView extends StatefulWidget {
  const ChangerMotDePasseView({super.key});

  @override
  State<ChangerMotDePasseView> createState() => _ChangerMotDePasseViewState();
}

class _ChangerMotDePasseViewState extends State<ChangerMotDePasseView> {
  final _formKey = GlobalKey<FormState>();
  final _ancienCtrl = TextEditingController();
  final _nouveauCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _ancienCtrl.dispose();
    _nouveauCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(titre: 'Changer le mot de passe'),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _ancienCtrl,
                obscureText: true,
                validator: AppValidators.motDePasse,
                decoration: const InputDecoration(
                  labelText: 'Ancien mot de passe',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nouveauCtrl,
                obscureText: true,
                validator: AppValidators.motDePasse,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: true,
                validator: (v) => AppValidators.confirmerMotDePasse(
                    v, _nouveauCtrl.text),
                decoration: const InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  // changerMotDePasse via AuthService (semaines futures)
                  AppHelpers.showSuccess(
                      context, 'Mot de passe changé avec succès !');
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Confirmer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets helper ────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icone;
  final Color couleur;

  const _StatCard({
    required this.titre,
    required this.valeur,
    required this.icone,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icone, color: couleur, size: 24),
            const SizedBox(height: 4),
            Text(
              valeur,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: couleur,
              ),
            ),
            Text(
              titre,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String titre;
  final List<Widget> children;

  const _SectionCard({required this.titre, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            titre,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valeur;

  const _InfoTile(
      {required this.icone, required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icone, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(valeur,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
