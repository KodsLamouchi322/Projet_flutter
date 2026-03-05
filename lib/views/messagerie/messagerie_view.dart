import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/message_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/message.dart';
import '../../utils/constants.dart';
import 'conversation_view.dart';

class MessagerieView extends StatefulWidget {
  const MessagerieView({super.key});

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthController>().membre?.uid;
      if (uid != null) {
        context.read<MessageController>().chargerConversations(uid);
      }
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
        title: const Text('Messagerie'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'Messages privés'),
            Tab(text: 'Forum'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _ConversationsTab(),
          _ForumTab(),
        ],
      ),
    );
  }
}

// ─── Onglet conversations privées ─────────────────────────────────────────────
class _ConversationsTab extends StatelessWidget {
  const _ConversationsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageController>(
      builder: (_, ctrl, __) {
        if (ctrl.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline,
                    size: 60, color: AppColors.divider),
                const SizedBox(height: 16),
                const Text('Aucune conversation',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text('Démarrer une conversation'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: ctrl.conversations.length,
          itemBuilder: (_, i) {
            final conv = ctrl.conversations[i];
            final auth = context.read<AuthController>();
            final uid = auth.membre?.uid ?? '';
            return _ConversationTile(conversation: conv, myUid: uid);
          },
        );
      },
    );
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.15),
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
        trailing: conversation.messageNonLus > 0
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${conversation.messageNonLus}',
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
                return const Center(
                  child: Text('Aucun message dans ce forum',
                      style: TextStyle(color: AppColors.textSecondary)),
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
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
            )
          ],
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Écrire dans le forum ${widget.genre}...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
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
