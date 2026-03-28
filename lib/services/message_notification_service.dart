import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import 'local_notification_service.dart';

/// Service pour écouter les nouveaux messages et envoyer des notifications
class MessageNotificationService {
  static final MessageNotificationService _instance = MessageNotificationService._();
  factory MessageNotificationService() => _instance;
  MessageNotificationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalNotificationService _notifService = LocalNotificationService();
  
  final Map<String, StreamSubscription> _conversationListeners = {};
  String? _currentUserId;
  String? _currentConversationId; // Pour ne pas notifier si on est dans la conversation

  /// Démarrer l'écoute des messages pour un utilisateur
  Future<void> startListening(String userId) async {
    if (_currentUserId == userId) return; // Déjà en écoute
    
    stopListening(); // Arrêter l'écoute précédente
    _currentUserId = userId;

    try {
      // Récupérer toutes les conversations de l'utilisateur
      final conversationsSnap = await _db
          .collection(AppConstants.colConversations)
          .where('participantsIds', arrayContains: userId)
          .get();

      // Écouter les nouveaux messages dans chaque conversation
      for (final convDoc in conversationsSnap.docs) {
        _listenToConversation(convDoc.id, userId);
      }

      // Écouter les nouvelles conversations
      _listenToNewConversations(userId);
    } catch (e) {
      debugPrint('Erreur démarrage écoute messages: $e');
    }
  }

  /// Arrêter toutes les écoutes
  void stopListening() {
    for (final sub in _conversationListeners.values) {
      sub.cancel();
    }
    _conversationListeners.clear();
    _currentUserId = null;
  }

  /// Définir la conversation actuellement ouverte (pour ne pas notifier)
  void setCurrentConversation(String? conversationId) {
    _currentConversationId = conversationId;
  }

  /// Écouter les messages d'une conversation spécifique
  void _listenToConversation(String conversationId, String userId) {
    if (_conversationListeners.containsKey(conversationId)) return;

    // Timestamp de démarrage pour ne notifier que les nouveaux messages
    final startTime = DateTime.now();

    final subscription = _db
        .collection(AppConstants.colConversations)
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      final messageDoc = snapshot.docs.first;
      final data = messageDoc.data();
      
      final expediteurId = data['expediteurId'] as String?;
      final expediteurNom = data['expediteurNom'] as String?;
      final contenu = data['contenu'] as String?;
      final createdAt = data['createdAt'] as Timestamp?;

      // Ne pas notifier si :
      // - C'est notre propre message
      // - Le message est ancien (avant le démarrage de l'écoute)
      // - On est actuellement dans cette conversation
      if (expediteurId == userId) return;
      if (createdAt == null) return;
      if (createdAt.toDate().isBefore(startTime)) return;
      if (_currentConversationId == conversationId) return;

      // Afficher la notification
      if (expediteurNom != null && contenu != null) {
        _notifService.afficherNotificationMessage(
          expediteurNom: expediteurNom,
          contenu: contenu,
          conversationId: conversationId,
        );
      }
    });

    _conversationListeners[conversationId] = subscription;
  }

  /// Écouter les nouvelles conversations créées
  void _listenToNewConversations(String userId) {
    final startTime = DateTime.now();

    final subscription = _db
        .collection(AppConstants.colConversations)
        .where('participantsIds', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final convId = change.doc.id;
          
          // Vérifier si c'est vraiment une nouvelle conversation
          final data = change.doc.data();
          final dernierMessageAt = data?['dernierMessageAt'] as Timestamp?;
          
          if (dernierMessageAt != null && 
              dernierMessageAt.toDate().isAfter(startTime)) {
            // Nouvelle conversation avec un message, commencer à l'écouter
            _listenToConversation(convId, userId);
          }
        }
      }
    });

    _conversationListeners['_new_conversations_'] = subscription;
  }
}
