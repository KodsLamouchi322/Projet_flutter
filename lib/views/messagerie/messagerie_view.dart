import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../controllers/message_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/membre.dart';
import '../../models/message.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../auth/login_view.dart';
import 'conversation_view.dart';

class MessagerieView extends StatefulWidget {
  final bool embeddedInCommunity;
  const MessagerieView({super.key, this.embeddedInCommunity = false});

  @override
  State<MessagerieView> createState() => _MessagerieViewState();
}

class _MessagerieViewState extends State<MessagerieView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final l10n = AppLocalizations.of(context)!;
    final tabs = TabBar(
      controller: _tabCtrl,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: AppColors.accentLight,
      dividerColor: Colors.transparent,
      tabs: [
        Tab(text: l10n.privateMessages),
        Tab(text: l10n.forum),
      ],
    );

    final content = TabBarView(
      controller: _tabCtrl,
      children: [
        _ConversationsTab(showScaffold: !widget.embeddedInCommunity),
        const _ForumTab(),
      ],
    );

    if (auth.membre == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(l10n.messagingTitle), backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble_outline, size: 60, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(l10n.notConnected, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginView())),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                child: Text(l10n.loginToChat),
              ),
            ],
          ),
        ),
      );
    }

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
        title: Text(l10n.messagingTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: tabs,
      ),
      body: content,
    );
  }
}

// ─── Onglet conversations privées ─────────────────────────────────────────────
class _ConversationsTab extends StatelessWidget {
  final bool showScaffold;
  const _ConversationsTab({this.showScaffold = true});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final uid = auth.membre?.uid ?? '';
    final ctrl = context.read<MessageController>();
    final l10n = AppLocalizations.of(context)!;

    final content = Stack(
      children: [
        StreamBuilder<List<Conversation>>(
        stream: ctrl.streamConversations(uid),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final conversations = snap.data ?? [];
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 60, color: AppColors.divider),
                  const SizedBox(height: 16),
                  Text(l10n.noConversation,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _afficherSelecteurMembre(context),
                    child: Text(l10n.startConversation),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 86),
            itemCount: conversations.length,
            itemBuilder: (_, i) {
              final conv = conversations[i];
              return _ConversationTile(conversation: conv, myUid: uid);
            },
          );
        },
      ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: AppColors.accent,
            onPressed: () => _afficherSelecteurMembre(context),
            child: const Icon(Icons.message, color: Colors.white),
          ),
        ),
      ],
    );

    if (showScaffold) {
      return Scaffold(backgroundColor: Colors.transparent, body: content);
    }
    return content;
  }

  Future<void> _afficherSelecteurMembre(BuildContext context) async {
    final auth = context.read<AuthController>();
    final membreActuel = auth.membre;
    final l10n = AppLocalizations.of(context)!;
    if (membreActuel == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newConversation,
            style: const TextStyle(color: AppColors.primary)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<Membre>>(
            future: _chargerMembres(membreActuel.uid),
            builder: (contextDialog, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                      const SizedBox(height: 8),
                      Text('${l10n.error}: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: AppColors.error)),
                    ],
                  ),
                );
              }
              final membres = snapshot.data ?? [];
              if (membres.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 48, color: AppColors.divider),
                      const SizedBox(height: 12),
                      Text(l10n.noMemberFound,
                          style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: membres.length,
                itemBuilder: (_, i) {
                  final m = membres[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(
                        m.nomComplet.isNotEmpty ? m.nomComplet[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                    title: Text(m.nomComplet),
                    subtitle: Text(m.email, style: const TextStyle(fontSize: 11)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final ctrl = context.read<MessageController>();
                      final convId = await ctrl.getOuCreerConversation(
                        membreId1: membreActuel.uid,
                        nom1: membreActuel.nomComplet,
                        membreId2: m.uid,
                        nom2: m.nomComplet,
                      );
                      if (convId != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConversationView(
                              conversationId: convId,
                              autreNom: m.nomComplet,
                              participantsIds: [membreActuel.uid, m.uid],
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  /// Charge les membres directement depuis Firestore
  Future<List<Membre>> _chargerMembres(String monUid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('membres')
          .get();
      return snap.docs
          .map((d) => Membre.fromFirestore(d))
          .where((m) => m.uid != monUid && m.statut != StatutMembre.suspendu)
          .toList()
        ..sort((a, b) => a.nomComplet.compareTo(b.nomComplet));
    } catch (e) {
      throw Exception('Impossible de charger les membres: $e');
    }
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String myUid;
  const _ConversationTile(
      {required this.conversation, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final autreNom = conversation.getNomAutre(myUid);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.22),
        ),
        boxShadow: AppUI.softShadow,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Text(
            autreNom.isNotEmpty ? autreNom[0].toUpperCase() : '?',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(autreNom,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          conversation.dernierMessage ?? 'Aucun message',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: conversation.getMessageNonLus(myUid) > 0
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientAccent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${conversation.getMessageNonLus(myUid)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              )
            : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationView(
              conversationId: conversation.id,
              autreNom: autreNom,
              participantsIds: conversation.participantsIds,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Onglet Forum ─────────────────────────────────────────────────────────────
class _ForumTab extends StatefulWidget {
  const _ForumTab();

  @override
  State<_ForumTab> createState() => _ForumTabState();
}

class _ForumTabState extends State<_ForumTab> {
  String _genreSelectionne = AppConstants.genres.first;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<MessageController>();
    final auth = context.read<AuthController>();
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Sélecteur de genre
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: AppConstants.genres.length,
            itemBuilder: (_, i) {
              final genre = AppConstants.genres[i];
              final selected = genre == _genreSelectionne;
              return GestureDetector(
                onTap: () => setState(() => _genreSelectionne = genre),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      genre,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Messages du forum
        Expanded(
          child: StreamBuilder<List<Message>>(
            stream: ctrl.streamForumGenre(_genreSelectionne),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = snap.data!;
              if (messages.isEmpty) {
                return Center(
                  child: Text(l10n.noMessageInForum,
                      style: const TextStyle(color: AppColors.textSecondary)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (_, i) => _ForumMessageTile(
                  message: messages[i],
                  myUid: auth.membre?.uid ?? '',
                ),
              );
            },
          ),
        ),
        // Champ de saisie
        _ForumInputField(
          genre: _genreSelectionne,
          onSend: (text) {
            final auth2 = context.read<AuthController>();
            ctrl.posterMessageForum(
              expediteurId: auth2.membre?.uid ?? '',
              expediteurNom:
                  '${auth2.membre?.prenom} ${auth2.membre?.nom}',
              genre: _genreSelectionne,
              contenu: text,
            );
          },
        ),
      ],
    );
  }
}

class _ForumMessageTile extends StatelessWidget {
  final Message message;
  final String myUid;
  const _ForumMessageTile({required this.message, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final isMe = message.expediteurId == myUid;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.gradientPrimary : null,
          color: isMe ? null : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe
              ? null
              : Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
          boxShadow: AppUI.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.expediteurNom,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              message.contenu,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForumInputField extends StatefulWidget {
  final String genre;
  final void Function(String) onSend;
  const _ForumInputField({required this.genre, required this.onSend});

  @override
  State<_ForumInputField> createState() => _ForumInputFieldState();
}

class _ForumInputFieldState extends State<_ForumInputField> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: AppInputDecoration.standard(
                label: 'Forum ${widget.genre}',
                icon: Icons.forum_outlined,
              ).copyWith(
                hintText: 'Écrire dans le forum ${widget.genre}...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
          GestureDetector(
            onTap: () {
              if (_ctrl.text.trim().isNotEmpty) {
                widget.onSend(_ctrl.text.trim());
                _ctrl.clear();
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
