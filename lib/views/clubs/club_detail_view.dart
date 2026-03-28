import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/club_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/club_lecture.dart';
import '../../models/livre.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/livre_selector_dialog.dart';

class ClubDetailView extends StatefulWidget {
  final ClubLecture club;
  final bool fromAdminPanel;

  const ClubDetailView({
    super.key,
    required this.club,
    this.fromAdminPanel = false,
  });

  @override
  State<ClubDetailView> createState() => _ClubDetailViewState();
}

class _ClubDetailViewState extends State<ClubDetailView> with SingleTickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  late TabController _tabs;
  // Stream du club pour mise à jour temps réel du nombre de membres
  late Stream<DocumentSnapshot> _clubStream;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _tabs.addListener(() {
      setState(() {
        _currentTabIndex = _tabs.index;
      });
    });
    _clubStream = FirebaseFirestore.instance
        .collection('clubs_lecture')
        .doc(widget.club.id)
        .snapshots();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _apresActionMembre(bool ok, String messageSucces) {
    if (!mounted) return;
    if (ok) {
      if (messageSucces.isNotEmpty) AppHelpers.showSuccess(context, messageSucces);
      // Ne pas fermer la page, laisser l'utilisateur voir le changement
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final ctrl = context.watch<ClubController>();
    final uid = auth.membre?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: _clubStream,
      builder: (context, snap) {
        // Utiliser les données temps réel si disponibles, sinon fallback sur widget.club
        ClubLecture club = widget.club;
        if (snap.hasData && snap.data!.exists) {
          try {
            club = ClubLecture.fromFirestore(snap.data!);
          } catch (_) {}
        }

        final estMembre = club.estMembre(uid);
        final estCreateur = club.createurId == uid;

        return _buildScaffold(context, l10n, auth, ctrl, club, uid, estMembre, estCreateur);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, dynamic l10n, AuthController auth,
      ClubController ctrl, ClubLecture club, String uid, bool estMembre, bool estCreateur) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(club.nom, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accentLight,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Discussion', icon: Icon(Icons.chat_rounded, size: 16)),
            Tab(text: 'Lectures', icon: Icon(Icons.menu_book_rounded, size: 16)),
            Tab(text: 'Votes', icon: Icon(Icons.how_to_vote_rounded, size: 16)),
            Tab(text: 'Défis', icon: Icon(Icons.emoji_events_rounded, size: 16)),
            Tab(text: 'Bibliothèque', icon: Icon(Icons.library_books_rounded, size: 16)),
          ],
        ),
        actions: [
          if (auth.isAuthenticated)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton(
                onPressed: (estMembre && estCreateur)
                    ? null
                    : () async {
                  bool ok;
                  if (estMembre) {
                    ok = await ctrl.quitter(club.id, uid);
                    if (widget.fromAdminPanel) {
                      if (ok && mounted) {
                        AppHelpers.showInfo(context, 'Vous avez quitté le club.');
                        await ctrl.chargerTousLesClubsAdmin();
                      } else if (!ok && mounted) {
                        AppHelpers.showError(context, ctrl.errorMessage ?? 'Erreur lors de la sortie du club.');
                      }
                    } else {
                      if (!ok && mounted) {
                        AppHelpers.showError(context, ctrl.errorMessage ?? 'Erreur lors de la sortie du club.');
                      } else {
                        _apresActionMembre(ok, '');
                      }
                    }
                  } else {
                    ok = await ctrl.rejoindre(club.id, uid);
                    if (widget.fromAdminPanel) {
                      if (ok && mounted) {
                        AppHelpers.showSuccess(context, l10n.clubJoin);
                        await ctrl.chargerTousLesClubsAdmin();
                      } else if (!ok && mounted) {
                        AppHelpers.showError(context, ctrl.errorMessage ?? 'Erreur lors de l\'adhésion au club.');
                      }
                    } else {
                      if (!ok && mounted) {
                        AppHelpers.showError(context, ctrl.errorMessage ?? 'Erreur lors de l\'adhésion au club.');
                      } else {
                        _apresActionMembre(ok, l10n.clubJoin);
                      }
                    }
                  }
                },
                child: Text(
                  (estMembre && estCreateur)
                      ? 'Créateur'
                      : (estMembre ? l10n.clubLeave : l10n.clubJoin),
                  style: TextStyle(
                    color: (estMembre && estCreateur)
                        ? Colors.white54
                        : (estMembre ? AppColors.accentLight : Colors.white),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _DiscussionTab(
            club: club,
            uid: uid,
            estMembre: estMembre,
            auth: auth,
            msgCtrl: _msgCtrl,
            fromAdminPanel: widget.fromAdminPanel,
          ),
          _LecturesCommunesTab(club: club, uid: uid, estMembre: estMembre),
          _VotesTab(club: club, uid: uid, estMembre: estMembre),
          _DefisTab(club: club, uid: uid, estMembre: estMembre),
          _BibliothequeTab(club: club, uid: uid, estMembre: estMembre),
        ],
      ),
      floatingActionButton: estMembre && _currentTabIndex > 0
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context, club, uid, auth.membre!.nomComplet),
              icon: const Icon(Icons.add_rounded),
              label: Text(_getFabLabel()),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  String _getFabLabel() {
    switch (_currentTabIndex) {
      case 1:
        return 'Nouvelle lecture';
      case 2:
        return 'Proposer un livre';
      case 3:
        return 'Créer un défi';
      case 4:
        return 'Ajouter un livre';
      default:
        return 'Ajouter';
    }
  }

  void _showCreateDialog(BuildContext context, ClubLecture club, String uid, String userName) {
    switch (_currentTabIndex) {
      case 1:
        _showCreateLectureDialog(context, club, uid);
        break;
      case 2:
        _showProposeVoteDialog(context, club, uid, userName);
        break;
      case 3:
        _showCreateDefiDialog(context, club);
        break;
      case 4:
        _showAddLivreDialog(context, club, uid, userName);
        break;
    }
  }

  void _showCreateLectureDialog(BuildContext context, ClubLecture club, String uid) async {
    final livre = await showDialog<Livre>(
      context: context,
      builder: (context) => const LivreSelectorDialog(),
    );

    if (livre == null || !context.mounted) return;

    final dateDebut = DateTime.now();
    final dateFin = dateDebut.add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => _CreateLectureDialog(
        club: club,
        livre: livre,
        dateDebut: dateDebut,
        dateFin: dateFin,
      ),
    );
  }

  void _showProposeVoteDialog(BuildContext context, ClubLecture club, String uid, String userName) async {
    final livre = await showDialog<Livre>(
      context: context,
      builder: (context) => const LivreSelectorDialog(),
    );

    if (livre == null || !context.mounted) return;

    final ctrl = context.read<ClubController>();
    final success = await ctrl.proposerLivrePourVote(
      clubId: club.id,
      livreId: livre.id,
      livreTitre: livre.titre,
      livreAuteur: livre.auteur,
      livreCouverture: livre.couvertureUrl,
      proposePar: uid,
      proposeParNom: userName,
    );

    if (!context.mounted) return;

    if (success) {
      AppHelpers.showSuccess(context, 'Livre proposé avec succès!');
    } else {
      AppHelpers.showError(context, ctrl.errorMessage ?? 'Erreur lors de la proposition');
    }
  }

  void _showCreateDefiDialog(BuildContext context, ClubLecture club) {
    showDialog(
      context: context,
      builder: (context) => _CreateDefiDialog(club: club),
    );
  }

  void _showAddLivreDialog(BuildContext context, ClubLecture club, String uid, String userName) async {
    final livre = await showDialog<Livre>(
      context: context,
      builder: (context) => const LivreSelectorDialog(),
    );

    if (livre == null || !context.mounted) return;

    final ctrl = context.read<ClubController>();
    final success = await ctrl.ajouterLivreBibliotheque(
      clubId: club.id,
      livreId: livre.id,
      livreTitre: livre.titre,
      livreAuteur: livre.auteur,
      livreCouverture: livre.couvertureUrl,
      ajoutePar: uid,
      ajouteParNom: userName,
      tags: ['recommandé'],
    );

    if (!context.mounted) return;

    if (success) {
      AppHelpers.showSuccess(context, 'Livre ajouté à la bibliothèque!');
    } else {
      AppHelpers.showError(context, ctrl.errorMessage ?? 'Erreur lors de l\'ajout');
    }
  }
}

class _DiscussionTab extends StatelessWidget {
  final ClubLecture club;
  final String uid;
  final bool estMembre;
  final AuthController auth;
  final TextEditingController msgCtrl;
  final bool fromAdminPanel;

  const _DiscussionTab({
    required this.club,
    required this.uid,
    required this.estMembre,
    required this.auth,
    required this.msgCtrl,
    required this.fromAdminPanel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = context.read<ClubController>();

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ctrl.streamMessages(club.id),
            builder: (_, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.forum_rounded, size: 40, color: AppColors.accentDark),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Première discussion',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Partagez vos impressions sur le livre du club.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final isMe = data['membreId'] == uid;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: isMe ? AppColors.gradientCard : null,
                              color: isMe ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(isMe ? 18 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 18),
                              ),
                              boxShadow: isMe ? AppUI.softShadow : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      data['membreNom'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.accentLight,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                Text(
                                  data['contenu'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.35,
                                    color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (estMembre)
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msgCtrl,
                    minLines: 1,
                    maxLines: 4,
                    decoration: AppInputDecoration.standard(
                      label: 'Message',
                      icon: Icons.chat_outlined,
                    ).copyWith(
                      hintText: l10n.clubMessageHint,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () async {
                      if (msgCtrl.text.trim().isEmpty) return;
                      await ctrl.envoyerMessage(
                        clubId: club.id,
                        membreId: uid,
                        membreNom: auth.membre!.nomComplet,
                        contenu: msgCtrl.text.trim(),
                      );
                      msgCtrl.clear();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (auth.isAuthenticated)
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(12, 10, 12, 12 + MediaQuery.of(context).padding.bottom),
            color: Theme.of(context).colorScheme.surface,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.accent.withValues(alpha: 0.12)],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radius),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.clubJoinToChat,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () async {
                        final ok = await ctrl.rejoindre(club.id, uid);
                        if (context.mounted) {
                          if (ok) {
                            AppHelpers.showSuccess(context, l10n.clubJoin);
                            if (fromAdminPanel) await ctrl.chargerTousLesClubsAdmin();
                          } else {
                            AppHelpers.showError(context, ctrl.errorMessage ?? 'Erreur lors de l\'adhésion au club.');
                          }
                        }
                      },
                      icon: const Icon(Icons.group_add_rounded),
                      label: Text(l10n.clubJoin),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LecturesCommunesTab extends StatelessWidget {
  final ClubLecture club;
  final String uid;
  final bool estMembre;

  const _LecturesCommunesTab({
    required this.club,
    required this.uid,
    required this.estMembre,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<ClubController>();

    return StreamBuilder<QuerySnapshot>(
      stream: ctrl.streamLecturesCommunes(club.id),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final lectures = snap.data!.docs;

        if (lectures.isEmpty) {
          return _EmptyState(
            icon: Icons.menu_book_rounded,
            title: 'Aucune lecture commune',
            subtitle: 'Organisez une lecture collective pour lire ensemble',
            actionLabel: estMembre ? 'Créer une lecture' : null,
            onAction: estMembre
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Créer une lecture commune'),
                        content: const Text(
                          'Fonctionnalité en cours de développement.\n\n'
                          'Bientôt disponible!',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                : null,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lectures.length,
          itemBuilder: (context, i) {
            final data = lectures[i].data() as Map<String, dynamic>;
            final lectureId = lectures[i].id;
            final titre = data['livreTitre'] ?? '';
            final auteur = data['livreAuteur'] ?? '';
            final statut = data['statut'] ?? 'planifiee';
            final participants = List<String>.from(data['participantsIds'] ?? []);
            final progression = (data['progressionParMembre'] as Map?)?.cast<String, int>() ?? {};
            final maProgression = progression[uid] ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statut == 'en_cours'
                                ? AppColors.success.withValues(alpha: 0.2)
                                : AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statut == 'en_cours' ? 'En cours' : statut == 'terminee' ? 'Terminée' : 'Planifiée',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statut == 'en_cours' ? AppColors.success : AppColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${participants.length} participants',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      titre,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      auteur,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    if (participants.contains(uid)) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: maProgression / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$maProgression%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _VotesTab extends StatelessWidget {
  final ClubLecture club;
  final String uid;
  final bool estMembre;

  const _VotesTab({
    required this.club,
    required this.uid,
    required this.estMembre,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<ClubController>();

    return StreamBuilder<QuerySnapshot>(
      stream: ctrl.streamVotesLivres(club.id),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final votes = snap.data!.docs;

        if (votes.isEmpty) {
          return _EmptyState(
            icon: Icons.how_to_vote_rounded,
            title: 'Aucun vote en cours',
            subtitle: 'Proposez un livre pour le prochain choix du club',
            actionLabel: estMembre ? 'Proposer un livre' : null,
            onAction: estMembre
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Proposer un livre'),
                        content: const Text(
                          'Fonctionnalité en cours de développement.\n\n'
                          'Bientôt disponible!',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                : null,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: votes.length,
          itemBuilder: (context, i) {
            final data = votes[i].data() as Map<String, dynamic>;
            final voteId = votes[i].id;
            final titre = data['livreTitre'] ?? '';
            final auteur = data['livreAuteur'] ?? '';
            final proposePar = data['proposeParNom'] ?? '';
            final votants = List<String>.from(data['votantsIds'] ?? []);
            final aVote = votants.contains(uid);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titre,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                auteur,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${votants.length}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.accent,
                                ),
                              ),
                              const Text(
                                'votes',
                                style: TextStyle(fontSize: 10, color: AppColors.accent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Proposé par $proposePar',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    if (estMembre) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (aVote) {
                              await ctrl.retirerVote(voteId, uid);
                            } else {
                              await ctrl.voterPourLivre(voteId, uid);
                            }
                          },
                          icon: Icon(aVote ? Icons.check_circle : Icons.how_to_vote_rounded),
                          label: Text(aVote ? 'Vous avez voté' : 'Voter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: aVote ? AppColors.success : AppColors.accent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DefisTab extends StatelessWidget {
  final ClubLecture club;
  final String uid;
  final bool estMembre;

  const _DefisTab({
    required this.club,
    required this.uid,
    required this.estMembre,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<ClubController>();

    return StreamBuilder<QuerySnapshot>(
      stream: ctrl.streamDefisLecture(club.id),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final defis = snap.data!.docs;

        if (defis.isEmpty) {
          return _EmptyState(
            icon: Icons.emoji_events_rounded,
            title: 'Aucun défi actif',
            subtitle: 'Créez un défi de lecture pour motiver les membres',
            actionLabel: estMembre ? 'Créer un défi' : null,
            onAction: estMembre
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Créer un défi'),
                        content: const Text(
                          'Fonctionnalité en cours de développement.\n\n'
                          'Bientôt disponible!',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                : null,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: defis.length,
          itemBuilder: (context, i) {
            final data = defis[i].data() as Map<String, dynamic>;
            final defiId = defis[i].id;
            final titre = data['titre'] ?? '';
            final description = data['description'] ?? '';
            final objectif = data['objectif'] ?? 0;
            final participants = List<String>.from(data['participantsIds'] ?? []);
            final progression = (data['progressionParMembre'] as Map?)?.cast<String, int>() ?? {};
            final maProgression = progression[uid] ?? 0;
            final pourcentage = objectif > 0 ? (maProgression / objectif * 100).clamp(0, 100) : 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            titre,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Objectif: $objectif',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '${participants.length} participants',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    if (participants.contains(uid)) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: pourcentage / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${pourcentage.toInt()}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Votre progression: $maProgression / $objectif',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ] else if (estMembre) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await ctrl.rejoindreDefi(defiId, uid);
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Rejoindre le défi'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BibliothequeTab extends StatelessWidget {
  final ClubLecture club;
  final String uid;
  final bool estMembre;

  const _BibliothequeTab({
    required this.club,
    required this.uid,
    required this.estMembre,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<ClubController>();

    return StreamBuilder<QuerySnapshot>(
      stream: ctrl.streamBibliothequeClub(club.id),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final livres = snap.data!.docs;

        if (livres.isEmpty) {
          return _EmptyState(
            icon: Icons.library_books_rounded,
            title: 'Bibliothèque vide',
            subtitle: 'Ajoutez des livres recommandés par le club',
            actionLabel: estMembre ? 'Ajouter un livre' : null,
            onAction: estMembre
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Ajouter à la bibliothèque'),
                        content: const Text(
                          'Fonctionnalité en cours de développement.\n\n'
                          'Bientôt disponible!',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                : null,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: livres.length,
          itemBuilder: (context, i) {
            final data = livres[i].data() as Map<String, dynamic>;
            final titre = data['livreTitre'] ?? '';
            final auteur = data['livreAuteur'] ?? '';
            final ajoutePar = data['ajouteParNom'] ?? '';
            final tags = List<String>.from(data['tags'] ?? []);
            final noteClub = (data['noteClub'] ?? 0.0).toDouble();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titre,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                auteur,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        if (noteClub > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  noteClub.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Ajouté par $ajoutePar',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.accentDark),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  final ClubLecture club;
  final bool estCreateur;

  const _AboutTab({required this.club, required this.estCreateur});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.gradientWarm,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            boxShadow: AppUI.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Livre du club', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                club.livreTitre,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
              ),
              Text(
                club.livreAuteur,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'À propos',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          club.description.isEmpty ? 'Pas de description.' : club.description,
          style: TextStyle(height: 1.45, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 20),
        _MetaRow(icon: Icons.person_outline_rounded, label: 'Créé par', value: club.createurNom),
        const SizedBox(height: 10),
        _MetaRow(
          icon: Icons.people_alt_outlined,
          label: 'Membres',
          value: '${club.nbMembres}',
        ),
        if (estCreateur) ...[
          const SizedBox(height: 16),
          AppUI.badge('Vous êtes l’organisateur', AppColors.accentDark),
        ],
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// DIALOGUES DE CRÉATION
// ═══════════════════════════════════════════════════════════════════════════

class _CreateLectureDialog extends StatefulWidget {
  final ClubLecture club;
  final Livre livre;
  final DateTime dateDebut;
  final DateTime dateFin;

  const _CreateLectureDialog({
    required this.club,
    required this.livre,
    required this.dateDebut,
    required this.dateFin,
  });

  @override
  State<_CreateLectureDialog> createState() => _CreateLectureDialogState();
}

class _CreateLectureDialogState extends State<_CreateLectureDialog> {
  final _nbChapitresCtrl = TextEditingController(text: '10');
  late DateTime _dateDebut;
  late DateTime _dateFin;

  @override
  void initState() {
    super.initState();
    _dateDebut = widget.dateDebut;
    _dateFin = widget.dateFin;
  }

  @override
  void dispose() {
    _nbChapitresCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer une lecture commune'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.livre.titre,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              widget.livre.auteur,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nbChapitresCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nombre de chapitres',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date de début'),
              subtitle: Text(AppHelpers.formatDate(_dateDebut)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateDebut,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _dateDebut = date);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date de fin'),
              subtitle: Text(AppHelpers.formatDate(_dateFin)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateFin,
                  firstDate: _dateDebut,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _dateFin = date);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () async {
            final ctrl = context.read<ClubController>();
            final success = await ctrl.creerLectureCommune(
              clubId: widget.club.id,
              livreId: widget.livre.id,
              livreTitre: widget.livre.titre,
              livreAuteur: widget.livre.auteur,
              livreCouverture: widget.livre.couvertureUrl,
              dateDebut: _dateDebut,
              dateFin: _dateFin,
              nbChapitres: int.tryParse(_nbChapitresCtrl.text) ?? 0,
            );

            if (!context.mounted) return;

            if (success) {
              Navigator.pop(context);
              AppHelpers.showSuccess(context, 'Lecture commune créée!');
            } else {
              AppHelpers.showError(context, ctrl.errorMessage ?? 'Erreur');
            }
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}

class _CreateDefiDialog extends StatefulWidget {
  final ClubLecture club;

  const _CreateDefiDialog({required this.club});

  @override
  State<_CreateDefiDialog> createState() => _CreateDefiDialogState();
}

class _CreateDefiDialogState extends State<_CreateDefiDialog> {
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _objectifCtrl = TextEditingController(text: '3');
  String _type = 'nombre_livres';
  late DateTime _dateDebut;
  late DateTime _dateFin;

  @override
  void initState() {
    super.initState();
    _dateDebut = DateTime.now();
    _dateFin = DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _objectifCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer un défi'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titreCtrl,
              decoration: const InputDecoration(
                labelText: 'Titre du défi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Type de défi',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'nombre_livres', child: Text('Nombre de livres')),
                DropdownMenuItem(value: 'pages', child: Text('Nombre de pages')),
                DropdownMenuItem(value: 'genre', child: Text('Genre spécifique')),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _objectifCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Objectif',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date de début'),
              subtitle: Text(AppHelpers.formatDate(_dateDebut)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateDebut,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _dateDebut = date);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date de fin'),
              subtitle: Text(AppHelpers.formatDate(_dateFin)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateFin,
                  firstDate: _dateDebut,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _dateFin = date);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () async {
            if (_titreCtrl.text.trim().isEmpty) {
              AppHelpers.showError(context, 'Veuillez entrer un titre');
              return;
            }

            final ctrl = context.read<ClubController>();
            final success = await ctrl.creerDefiLecture(
              clubId: widget.club.id,
              titre: _titreCtrl.text.trim(),
              description: _descCtrl.text.trim(),
              type: _type,
              objectif: int.tryParse(_objectifCtrl.text) ?? 3,
              dateDebut: _dateDebut,
              dateFin: _dateFin,
            );

            if (!context.mounted) return;

            if (success) {
              Navigator.pop(context);
              AppHelpers.showSuccess(context, 'Défi créé!');
            } else {
              AppHelpers.showError(context, ctrl.errorMessage ?? 'Erreur');
            }
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
