import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../utils/constants.dart';

/// Controller pour la messagerie interne
class MessageController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Conversation> _conversations = [];
  final List<Message> _messagesConversation = [];
  final List<Message> _messagesForum = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ──────────────────────────────────────────────────────────────
  List<Conversation> get conversations => _conversations;
  List<Message> get messagesConversation => _messagesConversation;
  List<Message> get messagesForum => _messagesForum;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalNonLus =>
      _conversations.fold(0, (sum, c) {
        // Récupérer l'ID du membre connecté depuis le contexte si disponible
        // Pour l'instant, on retourne 0 car on ne peut pas accéder au contexte ici
        // Cette méthode sera appelée depuis la vue avec le membreId
        return sum;
      });

  int getTotalNonLusPourMembre(String membreId) =>
      _conversations.fold(0, (sum, c) => sum + c.getMessageNonLus(membreId));

  // ─── Stream temps réel des conversations ─────────────────────────────────
  Stream<List<Conversation>> streamConversations(String membreId) {
    return _db
        .collection(AppConstants.colConversations)
        .where('participantsIds', arrayContains: membreId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Conversation.fromFirestore(d))
          .toList()
        ..sort((a, b) {
          final at = a.dernierMessageAt;
          final bt = b.dernierMessageAt;
          if (at == null && bt == null) return 0;
          if (at == null) return 1;
          if (bt == null) return -1;
          return bt.compareTo(at);
        });
      return list;
    });
  }

  // ─── Charger les conversations du membre (one-shot) ───────────────────────
  Future<void> chargerConversations(String membreId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _db
          .collection(AppConstants.colConversations)
          .where('participantsIds', arrayContains: membreId)
          .get();
      _conversations = snapshot.docs
          .map((d) => Conversation.fromFirestore(d))
          .toList()
        ..sort((a, b) {
          final at = a.dernierMessageAt;
          final bt = b.dernierMessageAt;
          if (at == null && bt == null) return 0;
          if (at == null) return 1;
          if (bt == null) return -1;
          return bt.compareTo(at);
        });
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── Charger les messages d'une conversation ──────────────────────────────
  Stream<List<Message>> streamMessages(String conversationId) {
    return _db
        .collection(AppConstants.colConversations)
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
    required List<String> participantsIds,
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
          .collection(AppConstants.colConversations)
          .doc(conversationId)
          .collection('messages')
          .add(message);

      // Incrémenter les non-lus UNIQUEMENT pour les autres participants (pas l'expéditeur)
      Map<String, dynamic> updateData = {
        'dernierMessage': contenu,
        'dernierMessageAt': FieldValue.serverTimestamp(),
        'dernierMessageExpId': expediteurId,
      };

      // Incrémenter le compteur pour chaque participant sauf l'expéditeur
      for (String participantId in participantsIds) {
        if (participantId != expediteurId) {
          updateData['messageNonLusParMembre.$participantId'] = FieldValue.increment(1);
        }
      }

      await _db
          .collection(AppConstants.colConversations)
          .doc(conversationId)
          .update(updateData);

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
      final existing = await _db
          .collection(AppConstants.colConversations)
          .where('participantsIds', arrayContains: membreId1)
          .get();

      for (final doc in existing.docs) {
        final participants =
            List<String>.from(doc.data()['participantsIds'] ?? []);
        if (participants.contains(membreId2)) {
          return doc.id;
        }
      }

      final docRef = await _db.collection(AppConstants.colConversations).add({
        'participantsIds': [membreId1, membreId2],
        'participantsNoms': {membreId1: nom1, membreId2: nom2},
        'dernierMessage': null,
        'dernierMessageAt': null,
        'dernierMessageExpId': null,
        'messageNonLusParMembre': {membreId1: 0, membreId2: 0},
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
        .collection(AppConstants.colForum)
        .where('forumGenre', isEqualTo: genre)
        .limit(50)
        .snapshots()
        .map((snap) {
      final msgs = snap.docs.map((d) => Message.fromFirestore(d)).toList();
      msgs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return msgs;
    });
  }

  Future<bool> posterMessageForum({
    required String expediteurId,
    required String expediteurNom,
    required String genre,
    required String contenu,
  }) async {
    try {
      await _db.collection(AppConstants.colForum).add({
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
          .collection(AppConstants.colConversations)
          .doc(conversationId)
          .update({'messageNonLusParMembre.$membreId': 0});
      await chargerConversations(membreId);
    } catch (_) {}
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
