import 'package:cloud_firestore/cloud_firestore.dart';

enum TypeMessage { texte, image, systeme }

class Message {
  final String id;
  final String expediteurId;
  final String expediteurNom;
  final String? destinataireId; // null = message forum
  final String? conversationId;
  final String? forumGenre; // genre littéraire pour forum
  final String contenu;
  final TypeMessage type;
  final DateTime createdAt;
  final bool estLu;
  final String? imageUrl;

  Message({
    required this.id,
    required this.expediteurId,
    required this.expediteurNom,
    this.destinataireId,
    this.conversationId,
    this.forumGenre,
    required this.contenu,
    required this.type,
    required this.createdAt,
    required this.estLu,
    this.imageUrl,
  });

  bool get estMessageForum => forumGenre != null;
  bool get estMessagePrive => destinataireId != null;

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      expediteurId: data['expediteurId'] ?? '',
      expediteurNom: data['expediteurNom'] ?? '',
      destinataireId: data['destinataireId'],
      conversationId: data['conversationId'],
      forumGenre: data['forumGenre'],
      contenu: data['contenu'] ?? '',
      type: TypeMessage.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'texte'),
        orElse: () => TypeMessage.texte,
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      estLu: data['estLu'] ?? false,
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'expediteurId': expediteurId,
      'expediteurNom': expediteurNom,
      'destinataireId': destinataireId,
      'conversationId': conversationId,
      'forumGenre': forumGenre,
      'contenu': contenu,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'estLu': estLu,
      'imageUrl': imageUrl,
    };
  }
}

/// Conversation entre deux membres
class Conversation {
  final String id;
  final List<String> participantsIds;
  final Map<String, String> participantsNoms;
  final String? dernierMessage;
  final DateTime? dernierMessageAt;
  final int messageNonLus;

  Conversation({
    required this.id,
    required this.participantsIds,
    required this.participantsNoms,
    this.dernierMessage,
    this.dernierMessageAt,
    required this.messageNonLus,
  });

  String getNomAutre(String monUid) {
    final autreId = participantsIds.firstWhere(
      (id) => id != monUid,
      orElse: () => '',
    );
    return participantsNoms[autreId] ?? 'Inconnu';
  }

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      participantsIds: List<String>.from(data['participantsIds'] ?? []),
      participantsNoms: Map<String, String>.from(data['participantsNoms'] ?? {}),
      dernierMessage: data['dernierMessage'],
      dernierMessageAt: data['dernierMessageAt'] != null
          ? (data['dernierMessageAt'] as Timestamp).toDate()
          : null,
      messageNonLus: data['messageNonLus'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participantsIds': participantsIds,
      'participantsNoms': participantsNoms,
      'dernierMessage': dernierMessage,
      'dernierMessageAt': dernierMessageAt != null
          ? Timestamp.fromDate(dernierMessageAt!)
          : null,
      'messageNonLus': messageNonLus,
    };
  }
}
