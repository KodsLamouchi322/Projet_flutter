import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/message_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/message.dart';
import '../../services/message_notification_service.dart';
import '../../utils/constants.dart';

class ConversationView extends StatefulWidget {
  final String conversationId;
  final String autreNom;
  final List<String> participantsIds;

  const ConversationView({
    super.key,
    required this.conversationId,
    required this.autreNom,
    required this.participantsIds,
  });

  @override
  State<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthController>().membre?.uid ?? '';
    context
        .read<MessageController>()
        .marquerCommeLu(widget.conversationId, uid);
    
    // Indiquer qu'on est dans cette conversation (pour ne pas notifier)
    MessageNotificationService().setCurrentConversation(widget.conversationId);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    
    // Indiquer qu'on n'est plus dans une conversation
    MessageNotificationService().setCurrentConversation(null);
    
    super.dispose();
  }

  void _envoyerMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthController>();
    context.read<MessageController>().envoyerMessage(
          conversationId: widget.conversationId,
          expediteurId: auth.membre?.uid ?? '',
          expediteurNom:
              '${auth.membre?.prenom} ${auth.membre?.nom}',
          contenu: text,
          participantsIds: widget.participantsIds,
        );
    _msgCtrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final uid = auth.membre?.uid ?? '';
    final ctrl = context.read<MessageController>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accent.withOpacity(0.3),
              child: Text(
                widget.autreNom.isNotEmpty
                    ? widget.autreNom[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Text(widget.autreNom,
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: ctrl.streamMessages(widget.conversationId),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final messages = snap.data!;
                if (messages.isEmpty) {
                  return Center(
                    child: Text(l10n.startConversationNow,
                        style: const TextStyle(
                            color: AppColors.textSecondary)),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) =>
                      _BubbleMessage(msg: messages[i], myUid: uid),
                );
              },
            ),
          ),

          // Champ de saisie
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _envoyerMessage(),
                    decoration: AppInputDecoration.standard(
                      label: 'Message',
                      icon: Icons.chat_bubble_outline_rounded,
                    ).copyWith(
                      hintText: 'Écrire un message...',
                      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
                  onTap: _envoyerMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleMessage extends StatelessWidget {
  final Message msg;
  final String myUid;
  const _BubbleMessage({required this.msg, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final isMe = msg.expediteurId == myUid;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
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
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
            )
          ],
        ),
        child: Text(
          msg.contenu,
          style: TextStyle(
            fontSize: 14,
            color: isMe ? Colors.white : AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
