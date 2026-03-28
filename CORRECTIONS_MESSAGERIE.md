# Corrections Messagerie - Messages Non Lus

## Problème identifié

Quand un utilisateur envoie un message, le badge (1) s'affiche pour lui-même, ce qui est illogique. Le compteur de messages non lus devrait s'afficher uniquement pour le destinataire, pas pour l'expéditeur.

## Cause du problème

L'ancien système utilisait un seul compteur `messageNonLus` pour toute la conversation. Quand un message était envoyé, ce compteur était incrémenté sans distinction entre l'expéditeur et le destinataire.

```dart
// ANCIEN CODE (incorrect)
'messageNonLus': FieldValue.increment(1)  // Incrémente pour tout le monde
```

## Solution implémentée

### 1. Modification du modèle Conversation

Changement de `messageNonLus` (int) vers `messageNonLusParMembre` (Map<String, int>) :

```dart
// NOUVEAU
final Map<String, int> messageNonLusParMembre; // Non lus par participant
final String? dernierMessageExpId; // ID de l'expéditeur du dernier message

int getMessageNonLus(String membreId) {
  return messageNonLusParMembre[membreId] ?? 0;
}
```

### 2. Migration automatique

Le code gère automatiquement l'ancien format pour la compatibilité :

```dart
// Si ancien format (messageNonLus simple), convertir en Map
if (data['messageNonLusParMembre'] != null) {
  nonLusMap = Map<String, int>.from(data['messageNonLusParMembre']);
} else if (data['messageNonLus'] != null) {
  // Ancien format: attribuer tous les non-lus au premier participant
  final participants = List<String>.from(data['participantsIds'] ?? []);
  if (participants.isNotEmpty) {
    nonLusMap[participants[0]] = data['messageNonLus'] as int;
  }
}
```

### 3. Envoi de message corrigé

Maintenant, seuls les autres participants (pas l'expéditeur) voient le compteur augmenter :

```dart
// Incrémenter le compteur pour chaque participant sauf l'expéditeur
for (String participantId in participantsIds) {
  if (participantId != expediteurId) {
    updateData['messageNonLusParMembre.$participantId'] = FieldValue.increment(1);
  }
}
```

### 4. Marquer comme lu

Mise à jour pour réinitialiser uniquement le compteur du membre concerné :

```dart
await _db
    .collection(AppConstants.colConversations)
    .doc(conversationId)
    .update({'messageNonLusParMembre.$membreId': 0});
```

### 5. Affichage du badge

Le badge affiche maintenant le nombre de messages non lus spécifique à l'utilisateur :

```dart
trailing: conversation.getMessageNonLus(myUid) > 0
    ? Container(
        // Badge avec le nombre de non-lus pour cet utilisateur
        child: Text('${conversation.getMessageNonLus(myUid)}'),
      )
    : null,
```

## Fichiers modifiés

1. `lib/models/message.dart` - Modèle Conversation mis à jour
2. `lib/controllers/message_controller.dart` - Logique d'envoi et de marquage
3. `lib/views/messagerie/messagerie_view.dart` - Affichage du badge
4. `lib/views/messagerie/conversation_view.dart` - Passage des participants

## Résultat

✅ L'expéditeur ne voit plus le badge (1) après avoir envoyé un message
✅ Seul le destinataire voit le badge avec le nombre de messages non lus
✅ Chaque participant a son propre compteur de messages non lus
✅ Migration automatique depuis l'ancien format

---

# Notifications de Messages Reçus

## Fonctionnalité ajoutée

Les membres reçoivent maintenant des notifications push locales quand ils reçoivent un nouveau message privé.

## Implémentation

### 1. Service de notifications de messages

Nouveau service `MessageNotificationService` qui :
- Écoute en temps réel tous les messages des conversations de l'utilisateur
- Détecte les nouveaux messages reçus (pas envoyés)
- Affiche une notification locale avec le nom de l'expéditeur et le contenu
- Ne notifie pas si l'utilisateur est déjà dans la conversation

```dart
// Écouter les nouveaux messages
MessageNotificationService().startListening(userId);

// Arrêter l'écoute
MessageNotificationService().stopListening();

// Indiquer qu'on est dans une conversation (pour ne pas notifier)
MessageNotificationService().setCurrentConversation(conversationId);
```

### 2. Canal de notification dédié

Ajout d'un canal Android spécifique pour les messages :

```dart
static const String _channelMessages = 'messages_prives';

AndroidNotificationChannel(
  _channelMessages, 
  'Messages privés',
  description: 'Notifications de nouveaux messages',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
)
```

### 3. Méthode de notification de message

```dart
Future<void> afficherNotificationMessage({
  required String expediteurNom,
  required String contenu,
  String? conversationId,
}) async {
  await _plugin.show(
    id,
    '💬 $expediteurNom',
    contenu,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _channelMessages, 
        'Messages privés',
        styleInformation: BigTextStyleInformation(contenu),
      ),
    ),
  );
}
```

### 4. Intégration avec l'authentification

Le service démarre automatiquement quand l'utilisateur se connecte et s'arrête à la déconnexion :

```dart
// Dans AuthController._initAuthState()
if (membre != null) {
  MessageNotificationService().startListening(membre.uid);
} else {
  MessageNotificationService().stopListening();
}
```

### 5. Gestion de la conversation active

Quand l'utilisateur ouvre une conversation, les notifications sont désactivées pour cette conversation :

```dart
// Dans ConversationView.initState()
MessageNotificationService().setCurrentConversation(widget.conversationId);

// Dans ConversationView.dispose()
MessageNotificationService().setCurrentConversation(null);
```

## Fichiers ajoutés/modifiés

1. `lib/services/message_notification_service.dart` - Nouveau service
2. `lib/services/local_notification_service.dart` - Ajout canal et méthode
3. `lib/controllers/auth_controller.dart` - Démarrage/arrêt du service
4. `lib/views/messagerie/conversation_view.dart` - Gestion conversation active

## Comportement

✅ Notification affichée quand un nouveau message est reçu
✅ Pas de notification pour ses propres messages
✅ Pas de notification si on est dans la conversation
✅ Notification avec nom de l'expéditeur et contenu du message
✅ Son et vibration activés
✅ Style BigText pour afficher le message complet
✅ Démarrage automatique à la connexion
✅ Arrêt automatique à la déconnexion

## Test

1. Connectez-vous avec l'utilisateur A sur un appareil
2. Connectez-vous avec l'utilisateur B sur un autre appareil
3. Envoyez un message de B vers A
4. Vérifiez que A reçoit une notification avec "💬 [Nom de B]" et le contenu
5. Ouvrez la conversation sur A
6. Envoyez un autre message de B vers A
7. Vérifiez que A ne reçoit PAS de notification (car dans la conversation)
8. Fermez la conversation sur A
9. Envoyez un nouveau message de B vers A
10. Vérifiez que A reçoit à nouveau une notification

