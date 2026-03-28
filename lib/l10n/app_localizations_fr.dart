// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Bibliothèque de quartier';

  @override
  String get navHome => 'Accueil';

  @override
  String get navCatalog => 'Catalogue';

  @override
  String get navLoans => 'Emprunts';

  @override
  String get navEvents => 'Événements';

  @override
  String get navMessages => 'Messages';

  @override
  String get navClubs => 'Clubs';

  @override
  String get navAdmin => 'Admin';

  @override
  String get homeWelcomeGuest => 'Bienvenue !';

  @override
  String homeWelcomeUser(String name) {
    return 'Bonjour, $name';
  }

  @override
  String get homeSubtitle => 'Que souhaitez-vous lire aujourd\'hui ?';

  @override
  String get homeSearchHint => 'Rechercher un livre, auteur…';

  @override
  String get sectionForYou => 'Recommandé pour vous';

  @override
  String get sectionForYouSubtitle =>
      'Selon vos emprunts, wishlist et genres préférés';

  @override
  String get sectionNew => 'Nouveautés';

  @override
  String get sectionPopular => 'Les plus empruntés';

  @override
  String get sectionGenres => 'Parcourir par genre';

  @override
  String get sectionClubs => 'Clubs de lecture';

  @override
  String get seeAll => 'Voir tout';

  @override
  String get offlineCatalogBanner =>
      'Catalogue en cache (hors ligne ou erreur réseau). Les données peuvent être anciennes.';

  @override
  String get language => 'Langue';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get clubsTitle => 'Clubs de lecture';

  @override
  String get clubsCreate => 'Créer un club';

  @override
  String get clubsEmpty => 'Aucun club de lecture';

  @override
  String get clubsEmptyHint =>
      'Lancez un groupe autour d\'un livre du catalogue.';

  @override
  String clubsMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String get clubTabChat => 'Discussion';

  @override
  String get clubTabAbout => 'À propos';

  @override
  String get clubJoin => 'Rejoindre';

  @override
  String get clubLeave => 'Quitter';

  @override
  String get clubMessageHint => 'Votre avis sur le livre…';

  @override
  String get clubJoinToChat => 'Rejoignez le club pour participer';

  @override
  String get adminClubsTitle => 'Clubs (admin)';

  @override
  String get adminDeleteClub => 'Supprimer le club';

  @override
  String get exportPdfReport => 'Exporter stats (PDF)';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get save => 'Enregistrer';

  @override
  String get close => 'Fermer';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String get loading => 'Chargement...';

  @override
  String get notConnected => 'Vous n\'êtes pas connecté';

  @override
  String get loginToAccess => 'Connectez-vous pour accéder';

  @override
  String get login => 'Se connecter';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get logoutConfirm => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get accountSuspended => 'Compte suspendu';

  @override
  String get accountSuspendedMessage =>
      'Votre compte a été suspendu.\nContactez la bibliothèque.';

  @override
  String get catalogTitle => 'Catalogue';

  @override
  String get available => 'Disponibles';

  @override
  String get popular => 'Populaires';

  @override
  String get newBooks => 'Nouveautés';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get tryOtherKeywords => 'Essayez d\'autres mots-clés';

  @override
  String get emptyCatalog => 'Catalogue vide';

  @override
  String get comeBackLater => 'Revenez plus tard';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get messagingTitle => 'Messagerie';

  @override
  String get privateMessages => 'Messages privés';

  @override
  String get forum => 'Forum';

  @override
  String get loginToChat => 'Se connecter pour discuter';

  @override
  String get noConversation => 'Aucune conversation';

  @override
  String get startConversation => 'Démarrer une conversation';

  @override
  String get newConversation => 'Nouvelle conversation';

  @override
  String get noMemberFound => 'Aucun autre membre trouvé.';

  @override
  String get noMessageInForum => 'Aucun message dans ce forum';

  @override
  String get startConversationNow => 'Démarrez la conversation !';

  @override
  String get writeMessage => 'Écrire un message...';

  @override
  String get send => 'Envoyer';

  @override
  String get myWishlist => 'Ma wishlist';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get favoriteGenres => 'Genres préférés';

  @override
  String get noGenreSelected => 'Aucun genre sélectionné';

  @override
  String get loansTitle => 'Mes emprunts';

  @override
  String get currentLoans => 'En cours';

  @override
  String get loanHistory => 'Historique';

  @override
  String get noCurrentLoan => 'Aucun emprunt en cours';

  @override
  String get borrowBookFromCatalog => 'Empruntez un livre du catalogue';

  @override
  String get noLoanHistory => 'Aucun historique d\'emprunt';

  @override
  String borrowedOn(String date) {
    return 'Emprunté le $date';
  }

  @override
  String returnBy(String date) {
    return 'À rendre le $date';
  }

  @override
  String get returned => 'Rendu';

  @override
  String get extend => 'Prolonger';

  @override
  String get extensionNotAllowed => 'Prolongation non autorisée';

  @override
  String get waitingAdminConfirmation =>
      'En attente de confirmation par l\'admin';

  @override
  String get eventsTitle => 'Événements';

  @override
  String get upcomingEvents => 'À venir';

  @override
  String get pastEvents => 'Passés';

  @override
  String get noUpcomingEvent => 'Aucun événement à venir';

  @override
  String get noPastEvent => 'Aucun événement passé';

  @override
  String participants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count participants',
      one: '1 participant',
    );
    return '$_temp0';
  }

  @override
  String get participate => 'Participer';

  @override
  String get cancelParticipation => 'Annuler';

  @override
  String get eventDetails => 'Détails de l\'événement';

  @override
  String get description => 'Description';

  @override
  String get dateAndTime => 'Date et heure';

  @override
  String get location => 'Lieu';

  @override
  String get organizer => 'Organisateur';

  @override
  String get adminTitle => 'Administration';

  @override
  String get statistics => 'Statistiques';

  @override
  String get moderation => 'Modération';

  @override
  String get manageBooks => 'Gérer les livres';

  @override
  String get manageLoans => 'Gérer les emprunts';

  @override
  String get manageEvents => 'Gérer les événements';

  @override
  String get manageMembers => 'Gérer les membres';

  @override
  String get totalBooks => 'Total livres';

  @override
  String get totalMembers => 'Total membres';

  @override
  String get activeLoans => 'Emprunts actifs';

  @override
  String get overdueLoans => 'Emprunts en retard';

  @override
  String get bookTitle => 'Titre';

  @override
  String get author => 'Auteur';

  @override
  String get isbn => 'ISBN';

  @override
  String get genre => 'Genre';

  @override
  String get publicationYear => 'Année de publication';

  @override
  String get copies => 'Exemplaires';

  @override
  String get addBook => 'Ajouter un livre';

  @override
  String get scanIsbn => 'Scanner ISBN';

  @override
  String get searchByIsbn => 'Rechercher par ISBN';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Téléphone';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get register => 'S\'inscrire';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String get noAccount => 'Pas de compte ?';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get backToLogin => 'Retour à la connexion';
}
