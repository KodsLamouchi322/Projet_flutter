import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/evenement_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/evenement.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_buttons.dart';

class EvenementDetailView extends StatefulWidget {
  final Evenement evenement;
  const EvenementDetailView({super.key, required this.evenement});
  @override
  State<EvenementDetailView> createState() => _EvenementDetailViewState();
}

class _EvenementDetailViewState extends State<EvenementDetailView> {
  @override
  Widget build(BuildContext context) {
    final ev   = widget.evenement;
    final auth = context.watch<AuthController>();
    final uid  = auth.membre?.uid ?? '';
    final ctrl = context.read<EvenementController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
            actions: [
              if (auth.estAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  onPressed: () => _ouvrirCompteRendu(context, ev),
                  tooltip: 'Compte-rendu',
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ev.imageUrl != null && ev.imageUrl!.isNotEmpty
                  ? Stack(fit: StackFit.expand, children: [
                      Image.network(ev.imageUrl!, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppColors.primaryDark.withValues(alpha: 0.8)],
                          ),
                        ),
                      ),
                    ])
                  : Container(
                      decoration: const BoxDecoration(gradient: AppColors.gradientHero),
                      child: Center(
                        child: Icon(Icons.event_rounded, size: 80,
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Catégorie + statut
                Row(children: [
                  AppUI.badge(ev.categorie, AppColors.accent),
                  const SizedBox(width: 8),
                  AppUI.badge(
                    ev.statut == StatutEvenement.aVenir ? 'À venir'
                        : ev.statut == StatutEvenement.enCours ? 'En cours' : 'Terminé',
                    ev.statut == StatutEvenement.aVenir ? AppColors.primary
                        : ev.statut == StatutEvenement.enCours ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ]),
                const SizedBox(height: 12),
                Text(ev.titre,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),

                // Infos
                _InfoCard(children: [
                  _InfoRow(Icons.calendar_today_rounded, 'Début', AppHelpers.formatDateHeure(ev.dateDebut)),
                  _InfoRow(Icons.event_available_rounded, 'Fin', AppHelpers.formatDateHeure(ev.dateFin)),
                  _InfoRow(Icons.location_on_rounded, 'Lieu', ev.lieu),
                  _InfoRow(Icons.people_rounded, 'Participants',
                      '${ev.participantsIds.length} / ${ev.capaciteMax}'),
                ]),
                const SizedBox(height: 16),

                // Barre capacité
                Row(children: [
                  const Text('Capacité', style: TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(
                    ev.estComplet ? 'Complet' : '${ev.placesRestantes} places restantes',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: ev.estComplet ? AppColors.error : AppColors.success,
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ev.capaciteMax > 0
                        ? ev.participantsIds.length / ev.capaciteMax : 0,
                    backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ev.estComplet ? AppColors.error : AppColors.accent),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                const Text('Description',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(ev.description,
                    style: TextStyle(
                      fontSize: 14, height: 1.6,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),

                // Photos de l'événement
                if (ev.photosUrls.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Photos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  _PhotosGrid(urls: ev.photosUrls),
                ],

                // Compte-rendu
                if (ev.compteRendu != null && ev.compteRendu!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _CompteRenduSection(evenement: ev),
                ],

                // Bouton admin — ajouter photo
                if (auth.estAdmin) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _ajouterPhoto(context, ev),
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: const Text('Ajouter une photo'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Bouton inscription
                if (auth.isAuthenticated)
                  _BoutonInscription(evenement: ev, uid: uid, ctrl: ctrl),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _ajouterPhoto(BuildContext context, Evenement ev) async {
    final storage = StorageService();
    final file = await storage.choisirImageGalerie();
    if (file == null || !context.mounted) return;
    final url = await storage.uploadImageEvenement(evenementId: ev.id, image: file);
    if (url != null && context.mounted) {
      await context.read<EvenementController>().ajouterPhoto(evenementId: ev.id, photoUrl: url);
      AppHelpers.showSuccess(context, 'Photo ajoutée.');
    }
  }

  void _ouvrirCompteRendu(BuildContext context, Evenement ev) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _CompteRenduFormView(evenement: ev),
    ));
  }
}

// ─── Bouton inscription ───────────────────────────────────────────────────────
class _BoutonInscription extends StatefulWidget {
  final Evenement evenement;
  final String uid;
  final EvenementController ctrl;
  const _BoutonInscription({required this.evenement, required this.uid, required this.ctrl});
  @override
  State<_BoutonInscription> createState() => _BoutonInscriptionState();
}

class _BoutonInscriptionState extends State<_BoutonInscription> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final estInscrit = widget.evenement.estParticipant(widget.uid);
    return Container(
      decoration: BoxDecoration(
        gradient: estInscrit ? null : (widget.evenement.estComplet ? null : AppColors.gradientAccent),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: ElevatedButton.icon(
        onPressed: (widget.evenement.estComplet && !estInscrit) || _loading ? null : () async {
          setState(() => _loading = true);
          bool ok;
          if (estInscrit) {
            ok = await widget.ctrl.seDesinscrire(evenementId: widget.evenement.id, membreId: widget.uid);
          } else {
            ok = await widget.ctrl.sInscrire(evenementId: widget.evenement.id, membreId: widget.uid);
          }
          setState(() => _loading = false);
          if (mounted && ok) {
            AppHelpers.showSuccess(context, estInscrit ? 'Désinscription effectuée.' : 'Inscription confirmée ! Rappels planifiés.');
            Navigator.pop(context);
          }
        },
        icon: _loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(estInscrit ? Icons.cancel_rounded : Icons.event_available_rounded),
        label: Text(estInscrit ? 'Se désinscrire'
            : widget.evenement.estComplet ? 'Complet' : 'S\'inscrire'),
        style: ElevatedButton.styleFrom(
          backgroundColor: estInscrit ? AppColors.error : Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
        ),
      ),
    );
  }
}

// ─── Grille photos ────────────────────────────────────────────────────────────
class _PhotosGrid extends StatelessWidget {
  final List<String> urls;
  const _PhotosGrid({required this.urls});

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6,
    ),
    itemCount: urls.length,
    itemBuilder: (_, i) => GestureDetector(
      onTap: () => _voirPhoto(context, urls, i),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(urls[i], fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.primarySoft,
              child: const Icon(Icons.broken_image_rounded, color: AppColors.primary),
            )),
      ),
    ),
  );

  void _voirPhoto(BuildContext context, List<String> urls, int index) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _PhotoViewer(urls: urls, initialIndex: index),
    ));
  }
}

// ─── Visionneuse photos ───────────────────────────────────────────────────────
class _PhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _PhotoViewer({required this.urls, required this.initialIndex});
  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text('${_current + 1} / ${widget.urls.length}'),
    ),
    body: PageView.builder(
      controller: _ctrl,
      itemCount: widget.urls.length,
      onPageChanged: (i) => setState(() => _current = i),
      itemBuilder: (_, i) => InteractiveViewer(
        child: Center(
          child: Image.network(widget.urls[i], fit: BoxFit.contain),
        ),
      ),
    ),
  );
}

// ─── Section compte-rendu ─────────────────────────────────────────────────────
class _CompteRenduSection extends StatelessWidget {
  final Evenement evenement;
  const _CompteRenduSection({required this.evenement});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.primarySoft, AppColors.accentSoft],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(AppSizes.radius),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: AppColors.gradientCard,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.article_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        const Text('Compte-rendu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 12),
      Text(evenement.compteRendu!,
          style: TextStyle(fontSize: 14, height: 1.6,
              color: Theme.of(context).colorScheme.onSurface)),
      if (evenement.photosCompteRendu.isNotEmpty) ...[
        const SizedBox(height: 12),
        _PhotosGrid(urls: evenement.photosCompteRendu),
      ],
    ]),
  );
}

// ─── Formulaire compte-rendu (admin) ─────────────────────────────────────────
class _CompteRenduFormView extends StatefulWidget {
  final Evenement evenement;
  const _CompteRenduFormView({required this.evenement});
  @override
  State<_CompteRenduFormView> createState() => _CompteRenduFormViewState();
}

class _CompteRenduFormViewState extends State<_CompteRenduFormView> {
  late TextEditingController _ctrl;
  final List<String> _photos = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.evenement.compteRendu ?? '');
    _photos.addAll(widget.evenement.photosCompteRendu);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Compte-rendu'),
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.evenement.titre,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _ctrl,
          maxLines: 8,
          decoration: AppInputDecoration.standard(
            label: 'Rédigez le compte-rendu...',
            icon: Icons.edit_note_rounded,
          ).copyWith(alignLabelWithHint: true),
        ),
        const SizedBox(height: 16),

        // Photos compte-rendu
        if (_photos.isNotEmpty) ...[
          const Text('Photos', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _PhotosGrid(urls: _photos),
          const SizedBox(height: 12),
        ],

        AppSecondaryButton(
          onPressed: _ajouterPhoto,
          icon: Icons.add_photo_alternate_rounded,
          label: 'Ajouter une photo',
        ),
        const SizedBox(height: 24),

        AppPrimaryButton(
          onPressed: _saving ? null : _publier,
          icon: Icons.publish_rounded,
          label: _saving ? 'Publication...' : 'Publier le compte-rendu',
          gradient: AppColors.gradientCard,
        ),
      ]),
    ),
  );

  Future<void> _ajouterPhoto() async {
    final storage = StorageService();
    final file = await storage.choisirImageGalerie();
    if (file == null) return;
    final url = await storage.uploadImageEvenement(
        evenementId: widget.evenement.id, image: file);
    if (url != null) setState(() => _photos.add(url));
  }

  Future<void> _publier() async {
    if (_ctrl.text.trim().isEmpty) {
      AppHelpers.showError(context, 'Le compte-rendu ne peut pas être vide.');
      return;
    }
    setState(() => _saving = true);
    final ok = await context.read<EvenementController>().publierCompteRendu(
      evenementId: widget.evenement.id,
      compteRendu: _ctrl.text.trim(),
      photosUrls: _photos,
    );
    setState(() => _saving = false);
    if (mounted) {
      if (ok) {
        AppHelpers.showSuccess(context, 'Compte-rendu publié.');
        Navigator.pop(context);
      } else {
        AppHelpers.showError(context, 'Erreur lors de la publication.');
      }
    }
  }
}

// ─── Widgets utilitaires ──────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: AppUI.cardDecoration(context),
    child: Column(
      children: children.asMap().entries.map((e) => Column(children: [
        e.value,
        if (e.key < children.length - 1)
          Divider(height: 16, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
      ])).toList(),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.accent, size: 18),
    ),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    ])),
  ]);
}
