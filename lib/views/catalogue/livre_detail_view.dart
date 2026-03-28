import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/emprunt_controller.dart';
import '../../controllers/livre_controller.dart';
import '../../models/livre.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_buttons.dart';
import '../admin/ajouter_livre_view.dart';
import '../auth/login_view.dart';

/// Fiche détaillée d'un livre avec actions (emprunter, réserver, wishlist)
class LivreDetailView extends StatelessWidget {
  final Livre livre;

  const LivreDetailView({super.key, required this.livre});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final statutColor = AppHelpers.couleurStatutLivre(livre.statut.name);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header avec couverture ──
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image de fond floue
                  livre.couvertureUrl.isNotEmpty
                      ? Image.network(
                          livre.couvertureUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(color: AppColors.primaryDark),
                  // Overlay gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.primaryDark.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  // Couverture centrée
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 40),
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: livre.couvertureUrl.isNotEmpty
                            ? Image.network(livre.couvertureUrl)
                            : Container(
                                height: 170,
                                color:
                                    AppColors.primary.withOpacity(0.3),
                                child: const Icon(
                                  Icons.menu_book,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Wishlist toggle
              if (auth.isAuthenticated)
                IconButton(
                  icon: Icon(
                    auth.membre!.wishlist.contains(livre.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: auth.membre!.wishlist.contains(livre.id)
                        ? Colors.red
                        : Colors.white,
                  ),
                  onPressed: () => _toggleWishlist(context, auth),
                  tooltip: 'Liste de souhaits',
                ),
              // Edit (admin)
              if (auth.estAdmin)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AjouterLivreView(livre: livre),
                    ),
                  ),
                  tooltip: 'Modifier',
                ),
              if (auth.estAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Supprimer',
                  onPressed: () => _supprimerLivre(context, livre),
                ),
            ],
          ),

          // ── Détails ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + Auteur
                  Text(livre.titre, style: AppTextStyles.headline1),
                  const SizedBox(height: 4),
                  Text(
                    'par ${livre.auteur}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tags d'info
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      // Statut
                      _InfoChip(
                        label: livre.statutLabel,
                        color: statutColor,
                        icon: livre.estDisponible
                            ? Icons.check_circle
                            : Icons.cancel,
                      ),
                      // Genre
                      if (livre.genre.isNotEmpty)
                        _InfoChip(
                          label: livre.genre,
                          color: AppColors.primary,
                          icon: Icons.category,
                        ),
                      // Année
                      if (livre.anneePublication > 0)
                        _InfoChip(
                          label: '${livre.anneePublication}',
                          color: AppColors.textSecondary,
                          icon: Icons.calendar_today,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Note et Notation
                  if (auth.isAuthenticated)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Donnez votre avis',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        _AvisForm(livre: livre, auth: auth),
                      ],
                    ),

                  // Affichage des avis existants
                  if (livre.nbAvis > 0) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < livre.noteMoyenne.round() ? Icons.star : Icons.star_border,
                          color: AppColors.accent, size: 18,
                        )),
                        const SizedBox(width: 8),
                        Text(
                          '${livre.noteMoyenne.toStringAsFixed(1)} / 5',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent),
                        ),
                        const SizedBox(width: 4),
                        Text('(${livre.nbAvis} avis)',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _AvisListe(livreId: livre.id),
                  ],

                  const Divider(height: 32),

                  // Résumé
                  if (livre.resume.isNotEmpty) ...[
                    const Text(
                      'Résumé',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      livre.resume,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const Divider(height: 32),
                  ],

                  // Informations détaillées
                  const Text(
                    'Informations',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Éditeur', valeur: livre.editeur),
                  _InfoRow(
                    label: 'ISBN',
                    valeur: livre.isbn.isEmpty ? 'Non renseigné' : livre.isbn,
                  ),
                  _InfoRow(
                    label: 'Ajouté le',
                    valeur: AppHelpers.formatDateLong(livre.dateAjout),
                  ),
                  _InfoRow(
                    label: 'Emprunts',
                    valeur: '${livre.nbEmpruntsTotal} fois',
                  ),

                  // Tags
                  if (livre.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: livre.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 11)),
                              backgroundColor:
                                  AppColors.accent.withOpacity(0.1),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Signalement livre endommagé
                  if (auth.isAuthenticated)
                    TextButton.icon(
                      onPressed: () async {
                        final descriptionCtrl = TextEditingController();
                        final confirme = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Signaler un livre endommagé'),
                            content: TextField(
                              controller: descriptionCtrl,
                              maxLines: 3,
                              decoration: AppInputDecoration.standard(
                                label: 'Décrivez le problème',
                                icon: Icons.report_problem_outlined,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                ),
                                child: const Text('Envoyer'),
                              ),
                            ],
                          ),
                        );
                        if (confirme == true && context.mounted) {
                          final desc = descriptionCtrl.text.trim();
                          if (desc.isEmpty) return;
                          final empruntCtrl =
                              context.read<EmpruntController>();
                          final ok = await empruntCtrl
                              .signalerLivreEndommage(
                            livreId: livre.id,
                            description: desc,
                          );
                          if (ok) {
                            AppHelpers.showSuccess(
                              context,
                              'Signalement envoyé à la bibliothèque.',
                            );
                          } else {
                            AppHelpers.showError(
                              context,
                              empruntCtrl.errorMessage ??
                                  AppConstants.erreurInconnu,
                            );
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.report_problem_outlined,
                        color: AppColors.error,
                      ),
                      label: const Text(
                        'Signaler un livre endommagé',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),

                  const SizedBox(height: 100), // Espace pour les boutons
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Boutons d'action ──
      bottomNavigationBar: auth.isAuthenticated
          ? _ActionsBar(livre: livre)
          : _VisitorBar(),
    );
  }

  Future<void> _toggleWishlist(
      BuildContext context, AuthController auth) async {
    final estDansWishlist = auth.membre!.wishlist.contains(livre.id);
    await auth.toggleWishlist(livre.id);
    if (context.mounted) {
      AppHelpers.showInfo(
        context,
        estDansWishlist
            ? 'Retiré de la wishlist'
            : 'Ajouté à la wishlist',
      );
    }
  }
}

// ── Barre d'actions membre ────────────────────────────────────────────────────
class _ActionsBar extends StatefulWidget {
  final Livre livre;
  const _ActionsBar({required this.livre});

  @override
  State<_ActionsBar> createState() => _ActionsBarState();
}

class _ActionsBarState extends State<_ActionsBar> {
  int _positionFile = 0;
  bool _dejaReserve = false;
  bool _dejaEmprunte = false;
  bool _assignationAutoDeclenchee = false;
  bool _assignationAutoEnCours = false;

  @override
  void initState() {
    super.initState();
    _chargerInfosFile();
  }

  Future<void> _chargerInfosFile() async {
    final auth = context.read<AuthController>();
    final uid = auth.membre?.uid ?? '';
    if (uid.isEmpty) return;

    final db = FirebaseFirestore.instance;

    // Vérifier si déjà emprunté
    final empSnap = await db
        .collection(AppConstants.colEmprunts)
        .where('livreId', isEqualTo: widget.livre.id)
        .where('membreId', isEqualTo: uid)
        .where('statut', whereIn: ['enCours', 'prolonge', 'enAttenteRetour'])
        .get();

    // Vérifier position dans la file
    final resSnap = await db
        .collection(AppConstants.colReservations)
        .where('livreId', isEqualTo: widget.livre.id)
        .where('statut', isEqualTo: 'enAttente')
        .get();

    final maRes = resSnap.docs.where((d) =>
        (d.data()['membreId'] as String?) == uid).toList();

    if (mounted) {
      setState(() {
        _dejaEmprunte = empSnap.docs.isNotEmpty;
        _dejaReserve = maRes.isNotEmpty;
        _positionFile = maRes.isNotEmpty
            ? (maRes.first.data()['positionFile'] as int? ?? 0)
            : resSnap.docs.length + 1;
      });
    }

    if (widget.livre.estDisponible && maRes.isNotEmpty && empSnap.docs.isEmpty) {
      await _assignerReservationAutomatiquement();
    }
  }

  Future<void> _assignerReservationAutomatiquement() async {
    if (_assignationAutoDeclenchee || !mounted) return;
    final auth = context.read<AuthController>();
    final membre = auth.membre;
    if (membre == null) return;

    _assignationAutoDeclenchee = true;
    setState(() => _assignationAutoEnCours = true);

    final empruntCtrl = context.read<EmpruntController>();
    final ok = await empruntCtrl.emprunterLivre(
      livreId: widget.livre.id,
      membreId: membre.uid,
      membreNom: membre.nomComplet,
      livreTitre: widget.livre.titre,
      livreAuteur: widget.livre.auteur,
      livreCouverture: widget.livre.couvertureUrl,
    );

    if (!mounted) return;

    setState(() {
      _assignationAutoEnCours = false;
      if (ok) {
        _dejaReserve = false;
        _dejaEmprunte = true;
      } else {
        _assignationAutoDeclenchee = false;
      }
    });

    if (ok) {
      AppHelpers.showSuccess(context, 'Ce livre vous a été assigné automatiquement');
    } else {
      AppHelpers.showError(context, empruntCtrl.errorMessage ?? AppConstants.erreurInconnu);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final empruntCtrl = context.read<EmpruntController>();
    final livre = widget.livre;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: AppUI.softShadow,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Déjà emprunté par ce membre
            if (_dejaEmprunte)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Row(children: [
                  Icon(Icons.bookmark_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text('Vous avez déjà ce livre en cours d\'emprunt',
                      style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              )

            // Déjà réservé — afficher position
            else if (_dejaReserve)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.hourglass_top_rounded, color: AppColors.accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    livre.estDisponible
                        ? (_assignationAutoEnCours
                            ? 'Ce livre vous a été assigné automatiquement (traitement en cours...)'
                            : 'Ce livre vous a été assigné automatiquement')
                        : 'Vous êtes en position $_positionFile dans la file d\'attente',
                    style: const TextStyle(color: AppColors.accentDark, fontSize: 13, fontWeight: FontWeight.w600),
                  )),
                ]),
              )

            // Livre disponible → Emprunter
            else if (livre.estDisponible)
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradientAccent,
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                  boxShadow: AppUI.cardShadow,
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (auth.membre == null) return;
                    final duree = await showDialog<int>(
                      context: context,
                      builder: (_) => _DureeEmpruntDialog(dureeDefaut: AppConstants.dureeEmpruntJours),
                    );
                    if (duree == null || !context.mounted) return;
                    final ok = await empruntCtrl.emprunterLivre(
                      livreId: livre.id,
                      membreId: auth.membre!.uid,
                      membreNom: auth.membre!.nomComplet,
                      livreTitre: livre.titre,
                      livreAuteur: livre.auteur,
                      livreCouverture: livre.couvertureUrl,
                      dureeJours: duree,
                    );
                    if (context.mounted) {
                      if (ok) {
                        AppHelpers.showSuccess(context, 'Emprunt enregistré pour $duree jours. Bonne lecture !');
                        setState(() => _dejaEmprunte = true);
                      } else {
                        AppHelpers.showError(context, empruntCtrl.errorMessage ?? AppConstants.erreurInconnu);
                      }
                    }
                  },
                  icon: const Icon(Icons.library_add_rounded),
                  label: const Text('Emprunter ce livre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
                  ),
                ),
              )

            // Livre non disponible → Réserver + info file
            else
              Column(
                children: [
                  // Info file d'attente
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.people_outline_rounded,
                          size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        _positionFile > 1
                            ? '${_positionFile - 1} personne(s) en attente — vous seriez n°$_positionFile'
                            : 'Aucune attente — vous seriez le premier',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ]),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientCard,
                      borderRadius: BorderRadius.circular(AppSizes.radius),
                      boxShadow: AppUI.cardShadow,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (auth.membre == null) return;
                        final confirme = await AppHelpers.showConfirmDialog(
                          context: context,
                          titre: 'Réserver ce livre',
                          message: _positionFile > 1
                              ? 'Vous serez en position $_positionFile dans la file d\'attente.\nVous serez notifié dès que le livre sera disponible.'
                              : 'Vous serez le premier dans la file d\'attente.\nVous serez notifié dès que le livre sera disponible.',
                          confirmLabel: 'Réserver',
                        );
                        if (confirme != true || !context.mounted) return;
                        final ok = await empruntCtrl.reserverLivre(
                          livreId: livre.id,
                          membreId: auth.membre!.uid,
                          membreNom: auth.membre!.nomComplet,
                          livreTitre: livre.titre,
                          livreAuteur: livre.auteur,
                        );
                        if (context.mounted) {
                          if (ok) {
                            AppHelpers.showSuccess(context,
                                'Réservation confirmée. Vous êtes en position $_positionFile.');
                            setState(() { _dejaReserve = true; });
                          } else {
                            AppHelpers.showError(context, empruntCtrl.errorMessage ?? AppConstants.erreurInconnu);
                          }
                        }
                      },
                      icon: const Icon(Icons.bookmark_add_rounded),
                      label: const Text('Réserver ma place'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _VisitorBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginView())),
          icon: const Icon(Icons.login),
          label: const Text('Connectez-vous pour emprunter'),
        ),
      ),
    );
  }
}

// ── Formulaire d'avis avec note + commentaire ─────────────────────────────────
class _AvisForm extends StatefulWidget {
  final Livre livre;
  final AuthController auth;
  const _AvisForm({required this.livre, required this.auth});

  @override
  State<_AvisForm> createState() => _AvisFormState();
}

class _AvisFormState extends State<_AvisForm> {
  double _note = 0;
  final _commentaireCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _commentaireCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RatingBar.builder(
          initialRating: _note,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          itemSize: 28,
          itemPadding: const EdgeInsets.symmetric(horizontal: 2),
          itemBuilder: (_, __) => const Icon(Icons.star, color: AppColors.accent),
          onRatingUpdate: (r) => setState(() => _note = r),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentaireCtrl,
          maxLines: 2,
          decoration: AppInputDecoration.standard(
            label: 'Commentaire (optionnel)',
            icon: Icons.comment_outlined,
          ).copyWith(
            hintText: 'Votre commentaire (optionnel)...',
            hintStyle: const TextStyle(fontSize: 13),
            fillColor: AppColors.background,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: AppPrimaryButton(
            onPressed: _note == 0 || _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    await FirestoreService().ajouterAvis(
                      livreId: widget.livre.id,
                      membreId: widget.auth.membre!.uid,
                      membreNom: widget.auth.membre!.nomComplet,
                      note: _note,
                      commentaire: _commentaireCtrl.text.trim(),
                    );
                    setState(() {
                      _saving = false;
                      _note = 0;
                      _commentaireCtrl.clear();
                    });
                    if (context.mounted) {
                      AppHelpers.showSuccess(context, 'Merci pour votre avis !');
                    }
                  },
            label: _saving ? 'Publication...' : 'Publier mon avis',
            gradient: AppColors.gradientAccent,
          ),
        ),
      ],
    );
  }
}

// ── Liste des avis existants ──────────────────────────────────────────────────
class _AvisListe extends StatelessWidget {
  final String livreId;
  const _AvisListe({required this.livreId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colLivres)
          .doc(livreId)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();
        final data = snap.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox();
        final avis = List<Map<String, dynamic>>.from(data['avis'] ?? []);
        if (avis.isEmpty) return const SizedBox();

        // Trier par date décroissante
        avis.sort((a, b) {
          final at = (a['date'] as Timestamp?)?.toDate() ?? DateTime(0);
          final bt = (b['date'] as Timestamp?)?.toDate() ?? DateTime(0);
          return bt.compareTo(at);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Avis des membres',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ...avis.take(5).map((a) {
              final note = (a['note'] as num?)?.toInt() ?? 0;
              final commentaire = a['commentaire'] ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < note ? Icons.star : Icons.star_border,
                          color: AppColors.accent, size: 14,
                        )),
                        const SizedBox(width: 8),
                        Text(a['membreNom'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                    if (commentaire.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(commentaire,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Dialog sélection durée emprunt ───────────────────────────────────────────
class _DureeEmpruntDialog extends StatefulWidget {
  final int dureeDefaut;
  const _DureeEmpruntDialog({required this.dureeDefaut});

  @override
  State<_DureeEmpruntDialog> createState() => _DureeEmpruntDialogState();
}

class _DureeEmpruntDialogState extends State<_DureeEmpruntDialog> {
  late int _duree;

  @override
  void initState() {
    super.initState();
    _duree = widget.dureeDefaut;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Durée d\'emprunt'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Combien de jours souhaitez-vous garder ce livre ?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _duree > 1 ? () => setState(() => _duree--) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.primary,
              ),
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$_duree j', textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              IconButton(
                onPressed: _duree < 30 ? () => setState(() => _duree++) : null,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [7, 14, 21, 30].map((d) => ActionChip(
              label: Text('$d j'),
              onPressed: () => setState(() => _duree = d),
              backgroundColor: _duree == d ? AppColors.primary : null,
              labelStyle: TextStyle(color: _duree == d ? Colors.white : null, fontSize: 12),
            )).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _duree),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}

// ── Widgets utilitaires ───────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _InfoChip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _supprimerLivre(BuildContext context, Livre livre) async {
  final auth = context.read<AuthController>();
  if (!auth.estAdmin) {
    AppHelpers.showError(context, 'Action réservée aux administrateurs.');
    return;
  }

  final confirm = await AppHelpers.showConfirmDialog(
    context: context,
    titre: 'Supprimer le livre',
    message: 'Voulez-vous supprimer "${livre.titre}" ? Cette action est définitive.',
    confirmLabel: 'Supprimer',
    confirmColor: AppColors.error,
  );

  if (confirm != true || !context.mounted) return;

  final ok = await context.read<LivreController>().supprimerLivre(livre.id);
  if (!context.mounted) return;

  if (ok) {
    AppHelpers.showSuccess(context, 'Livre supprimé.');
    Navigator.pop(context);
  } else {
    final msg = context.read<LivreController>().errorMessage ?? AppConstants.erreurInconnu;
    AppHelpers.showError(context, msg);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String valeur;

  const _InfoRow({required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    if (valeur.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valeur,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
