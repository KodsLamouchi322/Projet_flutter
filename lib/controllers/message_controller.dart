import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

/// Controller pour la messagerie interne
class MessageController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Conversation> _conversations = [];
  List<Message> _messagesConversation = [];
  List<Message> _messagesForum = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _conversationActive;

  // ─── Getters ──────────────────────────────────────────────────────────────
  List<Conversation> get conversations => _conversations;
  List<Message> get messagesConversation => _messagesConversation;
  List<Message> get messagesForum => _messagesForum;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalNonLus =>
      _conversations.fold(0, (sum, c) => sum + c.messageNonLus);

  // ─── Charger les conversations du membre ──────────────────────────────────
  Future<void> chargerConversations(String membreId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _db
          .collection('conversations')
          .where('participantsIds', arrayContains: membreId)
          .orderBy('dernierMessageAt', descending: true)
          .get();
      _conversations =
          snapshot.docs.map((d) => Conversation.fromFirestore(d)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── Charger les messages d'une conversation ──────────────────────────────
  Stream<List<Message>> streamMessages(String conversationId) {
    _conversationActive = conversationId;
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Message.fromFirestore(d)).toList());
  }

  // ─── Envoyer un message privé ─────────────────────────────────────────────
  Future<bool> envoyerMessage({
    required String conversationId,
    required String expediteurId,
    required String expediteurNom,
    required String contenu,
  }) async {
    try {
      final message = {
        'expediteurId': expediteurId,
        'expediteurNom': expediteurNom,
        'contenu': contenu,
        'type': 'texte',
        'createdAt': FieldValue.serverTimestamp(),
        'estLu': false,
      };

      await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(message);

      // Mettre à jour la conversation
      await _db
          .collection('conversations')
          .doc(conversationId)
          .update({
        'dernierMessage': contenu,
        'dernierMessageAt': FieldValue.serverTimestamp(),
        'messageNonLus': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Créer ou récupérer une conversation ─────────────────────────────────
  Future<String?> getOuCreerConversation({
    required String membreId1,
    required String nom1,
    required String membreId2,
    required String nom2,
  }) async {
    try {
      // Chercher conversation existante
      final existing = await _db
          .collection('conversations')
          .where('participantsIds', arrayContains: membreId1)
          .get();

      for (final doc in existing.docs) {
        final participants =
            List<String>.from(doc.data()['participantsIds'] ?? []);
        if (participants.contains(membreId2)) {
          return doc.id;
        }
      }

      // Créer nouvelle conversation
      final docRef = await _db.collection('conversations').add({
        'participantsIds': [membreId1, membreId2],
        'participantsNoms': {
          membreId1: nom1,
          membreId2: nom2,
        },
        'dernierMessage': null,
        'dernierMessageAt': null,
        'messageNonLus': 0,
      });

      return docRef.id;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ─── Messages du forum (par genre littéraire) ─────────────────────────────
  Stream<List<Message>> streamForumGenre(String genre) {
    return _db
        .collection('forum')
        .where('forumGenre', isEqualTo: genre)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Message.fromFirestore(d)).toList());
  }

  Future<bool> posterMessageForum({
    required String expediteurId,
    required String expediteurNom,
    required String genre,
    required String contenu,
  }) async {
    try {
      await _db.collection('forum').add({
        'expediteurId': expediteurId,
        'expediteurNom': expediteurNom,
        'forumGenre': genre,
        'contenu': contenu,
        'type': 'texte',
        'createdAt': FieldValue.serverTimestamp(),
        'estLu': true,
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Marquer comme lu ────────────────────────────────────────────────────
  Future<void> marquerCommeLu(String conversationId, String membreId) async {
    try {
      await _db
          .collection('conversations')
          .doc(conversationId)
          .update({'messageNonLus': 0});
      await chargerConversations(membreId);
    } catch (e) {
      // Ignorer silencieusement
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
