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

  Message copyWith({
    String? id,
    String? expediteurId,
    String? expediteurNom,
    String? destinataireId,
    String? conversationId,
    String? forumGenre,
    String? contenu,
    TypeMessage? type,
    DateTime? createdAt,
    bool? estLu,
    String? imageUrl,
  }) {
    return Message(
      id: id ?? this.id,
      expediteurId: expediteurId ?? this.expediteurId,
      expediteurNom: expediteurNom ?? this.expediteurNom,
      destinataireId: destinataireId ?? this.destinataireId,
      conversationId: conversationId ?? this.conversationId,
      forumGenre: forumGenre ?? this.forumGenre,
      contenu: contenu ?? this.contenu,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      estLu: estLu ?? this.estLu,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

/// Conversation entre deux membres
class Conversation {
  final String id;
  final List<String> participantsIds;
  final Map<String, String> participantsNoms;
  final String? dernierMessage;
  final DateTime? dernierMessageAt;
  final String? dernierMessageExpId; // ID de l'expéditeur du dernier message
  final Map<String, int> messageNonLusParMembre; // Non lus par participant

  Conversation({
    required this.id,
    required this.participantsIds,
    required this.participantsNoms,
    this.dernierMessage,
    this.dernierMessageAt,
    this.dernierMessageExpId,
    required this.messageNonLusParMembre,
  });

  String getNomAutre(String monUid) {
    final autreId = participantsIds.firstWhere(
      (id) => id != monUid,
      orElse: () => '',
    );
    return participantsNoms[autreId] ?? 'Inconnu';
  }

  int getMessageNonLus(String membreId) {
    return messageNonLusParMembre[membreId] ?? 0;
  }

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Migration: si ancien format (messageNonLus simple), convertir en Map
    Map<String, int> nonLusMap = {};
    if (data['messageNonLusParMembre'] != null) {
      nonLusMap = Map<String, int>.from(data['messageNonLusParMembre']);
    } else if (data['messageNonLus'] != null) {
      // Ancien format: attribuer tous les non-lus au premier participant
      final participants = List<String>.from(data['participantsIds'] ?? []);
      if (participants.isNotEmpty) {
        nonLusMap[participants[0]] = data['messageNonLus'] as int;
      }
    }
    
    return Conversation(
      id: doc.id,
      participantsIds: List<String>.from(data['participantsIds'] ?? []),
      participantsNoms: Map<String, String>.from(data['participantsNoms'] ?? {}),
      dernierMessage: data['dernierMessage'],
      dernierMessageAt: data['dernierMessageAt'] != null
          ? (data['dernierMessageAt'] as Timestamp).toDate()
          : null,
      dernierMessageExpId: data['dernierMessageExpId'],
      messageNonLusParMembre: nonLusMap,
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
      'dernierMessageExpId': dernierMessageExpId,
      'messageNonLusParMembre': messageNonLusParMembre,
    };
  }

  Conversation copyWith({
    String? id,
    List<String>? participantsIds,
    Map<String, String>? participantsNoms,
    String? dernierMessage,
    DateTime? dernierMessageAt,
    String? dernierMessageExpId,
    Map<String, int>? messageNonLusParMembre,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantsIds: participantsIds ?? this.participantsIds,
      participantsNoms: participantsNoms ?? this.participantsNoms,
      dernierMessage: dernierMessage ?? this.dernierMessage,
      dernierMessageAt: dernierMessageAt ?? this.dernierMessageAt,
      dernierMessageExpId: dernierMessageExpId ?? this.dernierMessageExpId,
      messageNonLusParMembre: messageNonLusParMembre ?? this.messageNonLusParMembre,
    );
  }
}
