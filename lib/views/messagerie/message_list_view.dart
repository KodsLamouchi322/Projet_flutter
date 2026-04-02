import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../widgets/chat_bubble.dart';

class MessageListView extends StatelessWidget {
  final List<Message> messages;
  final String currentUserId;

  const MessageListView({Key? key, required this.messages, required this.currentUserId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return ChatBubble(
          message: msg,
          isMe: msg.expediteurId == currentUserId,
        );
      },
    );
  }
}
