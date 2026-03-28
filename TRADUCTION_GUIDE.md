# Guide de Traduction - Textes à Remplacer

## Nouvelles clés de traduction ajoutées

Les fichiers `app_en.arb` et `app_fr.arb` ont été mis à jour avec de nombreuses nouvelles clés. Voici les principales catégories :

### Actions générales
- `cancel` - Annuler / Cancel
- `confirm` - Confirmer / Confirm
- `delete` - Supprimer / Delete
- `edit` - Modifier / Edit
- `save` - Enregistrer / Save
- `close` - Fermer / Close
- `yes` - Oui / Yes
- `no` - Non / No
- `ok` - OK / OK
- `send` - Envoyer / Send
- `reset` - Réinitialiser / Reset

### Authentification
- `notConnected` - Vous n'êtes pas connecté / You are not connected
- `loginToAccess` - Connectez-vous pour accéder / Log in to access
- `login` - Se connecter / Log in
- `logout` - Se déconnecter / Log out
- `logoutConfirm` - Voulez-vous vraiment vous déconnecter ? / Do you really want to log out?
- `accountSuspended` - Compte suspendu / Account suspended
- `accountSuspendedMessage` - Votre compte a été suspendu.\nContactez la bibliothèque. / Your account has been suspended.\nContact the library.
- `register` - S'inscrire / Register
- `alreadyHaveAccount` - Vous avez déjà un compte ? / Already have an account?
- `noAccount` - Pas de compte ? / No account?
- `forgotPassword` - Mot de passe oublié ? / Forgot password?
- `resetPassword` - Réinitialiser le mot de passe / Reset password
- `backToLogin` - Retour à la connexion / Back to login

### Catalogue
- `catalogTitle` - Catalogue / Catalog
- `available` - Disponibles / Available
- `popular` - Populaires / Popular
- `newBooks` - Nouveautés / New
- `noResults` - Aucun résultat / No results
- `tryOtherKeywords` - Essayez d'autres mots-clés / Try other keywords
- `emptyCatalog` - Catalogue vide / Empty catalog
- `comeBackLater` - Revenez plus tard / Come back later

### Messagerie
- `messagingTitle` - Messagerie / Messaging
- `privateMessages` - Messages privés / Private messages
- `forum` - Forum / Forum
- `loginToChat` - Se connecter pour discuter / Log in to chat
- `noConversation` - Aucune conversation / No conversation
- `startConversation` - Démarrer une conversation / Start a conversation
- `newConversation` - Nouvelle conversation / New conversation
- `noMemberFound` - Aucun autre membre trouvé. / No other member found.
- `noMessageInForum` - Aucun message dans ce forum / No message in this forum
- `startConversationNow` - Démarrez la conversation ! / Start the conversation!
- `writeMessage` - Écrire un message... / Write a message...

### Profil
- `myWishlist` - Ma wishlist / My wishlist
- `editProfile` - Modifier le profil / Edit profile
- `favoriteGenres` - Genres préférés / Favorite genres
- `noGenreSelected` - Aucun genre sélectionné / No genre selected

### Emprunts
- `loansTitle` - Mes emprunts / My loans
- `currentLoans` - En cours / Current
- `loanHistory` - Historique / History
- `noCurrentLoan` - Aucun emprunt en cours / No current loan
- `borrowBookFromCatalog` - Empruntez un livre du catalogue / Borrow a book from the catalog
- `noLoanHistory` - Aucun historique d'emprunt / No loan history
- `borrowedOn` - Emprunté le {date} / Borrowed on {date}
- `returnBy` - À rendre le {date} / Return by {date}
- `returned` - Rendu / Returned
- `extend` - Prolonger / Extend
- `extensionNotAllowed` - Prolongation non autorisée / Extension not allowed
- `waitingAdminConfirmation` - En attente de confirmation par l'admin / Waiting for admin confirmation

### Événements
- `eventsTitle` - Événements / Events
- `upcomingEvents` - À venir / Upcoming
- `pastEvents` - Passés / Past
- `noUpcomingEvent` - Aucun événement à venir / No upcoming event
- `noPastEvent` - Aucun événement passé / No past event
- `participants` - {count} participant(s) / {count} participant(s)
- `participate` - Participer / Participate
- `cancelParticipation` - Annuler / Cancel
- `eventDetails` - Détails de l'événement / Event details
- `description` - Description / Description
- `dateAndTime` - Date et heure / Date and time
- `location` - Lieu / Location
- `organizer` - Organisateur / Organizer

### Administration
- `adminTitle` - Administration / Administration
- `statistics` - Statistiques / Statistics
- `moderation` - Modération / Moderation
- `manageBooks` - Gérer les livres / Manage books
- `manageLoans` - Gérer les emprunts / Manage loans
- `manageEvents` - Gérer les événements / Manage events
- `manageMembers` - Gérer les membres / Manage members
- `totalBooks` - Total livres / Total books
- `totalMembers` - Total membres / Total members
- `activeLoans` - Emprunts actifs / Active loans
- `overdueLoans` - Emprunts en retard / Overdue loans

### Formulaires
- `bookTitle` - Titre / Title
- `author` - Auteur / Author
- `isbn` - ISBN / ISBN
- `genre` - Genre / Genre
- `publicationYear` - Année de publication / Publication year
- `copies` - Exemplaires / Copies
- `addBook` - Ajouter un livre / Add book
- `scanIsbn` - Scanner ISBN / Scan ISBN
- `searchByIsbn` - Rechercher par ISBN / Search by ISBN
- `firstName` - Prénom / First name
- `lastName` - Nom / Last name
- `email` - Email / Email
- `phone` - Téléphone / Phone
- `password` - Mot de passe / Password
- `confirmPassword` - Confirmer le mot de passe / Confirm password

## Comment utiliser les traductions

Dans vos fichiers Dart, remplacez les textes en dur par :

```dart
// AVANT
Text('Annuler')

// APRÈS
Text(AppLocalizations.of(context)!.cancel)

// OU avec l10n déjà défini
final l10n = AppLocalizations.of(context)!;
Text(l10n.cancel)
```

## Exemples de remplacement

### Exemple 1 : Bouton Annuler
```dart
// AVANT
TextButton(
  onPressed: () => Navigator.pop(context),
  child: const Text('Annuler'),
)

// APRÈS
TextButton(
  onPressed: () => Navigator.pop(context),
  child: Text(l10n.cancel),
)
```

### Exemple 2 : Titre de page
```dart
// AVANT
appBar: AppBar(
  title: const Text('Messagerie'),
)

// APRÈS
appBar: AppBar(
  title: Text(l10n.messagingTitle),
)
```

### Exemple 3 : Message avec paramètre
```dart
// AVANT
Text('Emprunté le ${AppHelpers.formatDate(emprunt.dateEmprunt)}')

// APRÈS
Text(l10n.borrowedOn(AppHelpers.formatDate(emprunt.dateEmprunt)))
```

## Fichiers prioritaires à mettre à jour

1. `lib/views/messagerie/messagerie_view.dart` - Messagerie
2. `lib/views/profil/profil_view.dart` - Profil
3. `lib/views/catalogue/catalogue_view.dart` - Catalogue (déjà partiellement fait)
4. `lib/views/emprunts/emprunts_view.dart` - Emprunts
5. `lib/views/evenements/evenements_view.dart` - Événements
6. `lib/widgets/dialogs/confirm_dialog.dart` - Dialogues
7. `lib/views/auth/login_view.dart` - Connexion
8. `lib/views/auth/register_view.dart` - Inscription

## Note importante

Après avoir ajouté ou modifié des clés dans les fichiers `.arb`, exécutez :

```bash
flutter gen-l10n
```

Cela régénère automatiquement les fichiers de localisation Dart.
