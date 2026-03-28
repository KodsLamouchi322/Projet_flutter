// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Neighborhood Library';

  @override
  String get navHome => 'Home';

  @override
  String get navCatalog => 'Catalog';

  @override
  String get navLoans => 'Loans';

  @override
  String get navEvents => 'Events';

  @override
  String get navMessages => 'Messages';

  @override
  String get navClubs => 'Clubs';

  @override
  String get navAdmin => 'Admin';

  @override
  String get homeWelcomeGuest => 'Welcome!';

  @override
  String homeWelcomeUser(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeSubtitle => 'What would you like to read today?';

  @override
  String get homeSearchHint => 'Search a book, author…';

  @override
  String get sectionForYou => 'Recommended for you';

  @override
  String get sectionForYouSubtitle =>
      'Based on your loans, wishlist and favorite genres';

  @override
  String get sectionNew => 'New arrivals';

  @override
  String get sectionPopular => 'Most borrowed';

  @override
  String get sectionGenres => 'Browse by genre';

  @override
  String get sectionClubs => 'Reading clubs';

  @override
  String get seeAll => 'See all';

  @override
  String get offlineCatalogBanner =>
      'Showing cached catalog (offline or network issue). Data may be outdated.';

  @override
  String get language => 'Language';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get clubsTitle => 'Reading clubs';

  @override
  String get clubsCreate => 'Create a club';

  @override
  String get clubsEmpty => 'No reading club yet';

  @override
  String get clubsEmptyHint => 'Start a group around a book from the catalog.';

  @override
  String clubsMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get clubTabChat => 'Discussion';

  @override
  String get clubTabAbout => 'About';

  @override
  String get clubJoin => 'Join';

  @override
  String get clubLeave => 'Leave';

  @override
  String get clubMessageHint => 'Share your thoughts on the book…';

  @override
  String get clubJoinToChat => 'Join to take part in the discussion';

  @override
  String get adminClubsTitle => 'Clubs (admin)';

  @override
  String get adminDeleteClub => 'Delete club';

  @override
  String get exportPdfReport => 'Export stats (PDF)';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get loading => 'Loading...';

  @override
  String get notConnected => 'You are not connected';

  @override
  String get loginToAccess => 'Log in to access';

  @override
  String get login => 'Log in';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirm => 'Do you really want to log out?';

  @override
  String get accountSuspended => 'Account suspended';

  @override
  String get accountSuspendedMessage =>
      'Your account has been suspended.\nContact the library.';

  @override
  String get catalogTitle => 'Catalog';

  @override
  String get available => 'Available';

  @override
  String get popular => 'Popular';

  @override
  String get newBooks => 'New';

  @override
  String get noResults => 'No results';

  @override
  String get tryOtherKeywords => 'Try other keywords';

  @override
  String get emptyCatalog => 'Empty catalog';

  @override
  String get comeBackLater => 'Come back later';

  @override
  String get reset => 'Reset';

  @override
  String get messagingTitle => 'Messaging';

  @override
  String get privateMessages => 'Private messages';

  @override
  String get forum => 'Forum';

  @override
  String get loginToChat => 'Log in to chat';

  @override
  String get noConversation => 'No conversation';

  @override
  String get startConversation => 'Start a conversation';

  @override
  String get newConversation => 'New conversation';

  @override
  String get noMemberFound => 'No other member found.';

  @override
  String get noMessageInForum => 'No message in this forum';

  @override
  String get startConversationNow => 'Start the conversation!';

  @override
  String get writeMessage => 'Write a message...';

  @override
  String get send => 'Send';

  @override
  String get myWishlist => 'My wishlist';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get favoriteGenres => 'Favorite genres';

  @override
  String get noGenreSelected => 'No genre selected';

  @override
  String get loansTitle => 'My loans';

  @override
  String get currentLoans => 'Current';

  @override
  String get loanHistory => 'History';

  @override
  String get noCurrentLoan => 'No current loan';

  @override
  String get borrowBookFromCatalog => 'Borrow a book from the catalog';

  @override
  String get noLoanHistory => 'No loan history';

  @override
  String borrowedOn(String date) {
    return 'Borrowed on $date';
  }

  @override
  String returnBy(String date) {
    return 'Return by $date';
  }

  @override
  String get returned => 'Returned';

  @override
  String get extend => 'Extend';

  @override
  String get extensionNotAllowed => 'Extension not allowed';

  @override
  String get waitingAdminConfirmation => 'Waiting for admin confirmation';

  @override
  String get eventsTitle => 'Events';

  @override
  String get upcomingEvents => 'Upcoming';

  @override
  String get pastEvents => 'Past';

  @override
  String get noUpcomingEvent => 'No upcoming event';

  @override
  String get noPastEvent => 'No past event';

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
  String get participate => 'Participate';

  @override
  String get cancelParticipation => 'Cancel';

  @override
  String get eventDetails => 'Event details';

  @override
  String get description => 'Description';

  @override
  String get dateAndTime => 'Date and time';

  @override
  String get location => 'Location';

  @override
  String get organizer => 'Organizer';

  @override
  String get adminTitle => 'Administration';

  @override
  String get statistics => 'Statistics';

  @override
  String get moderation => 'Moderation';

  @override
  String get manageBooks => 'Manage books';

  @override
  String get manageLoans => 'Manage loans';

  @override
  String get manageEvents => 'Manage events';

  @override
  String get manageMembers => 'Manage members';

  @override
  String get totalBooks => 'Total books';

  @override
  String get totalMembers => 'Total members';

  @override
  String get activeLoans => 'Active loans';

  @override
  String get overdueLoans => 'Overdue loans';

  @override
  String get bookTitle => 'Title';

  @override
  String get author => 'Author';

  @override
  String get isbn => 'ISBN';

  @override
  String get genre => 'Genre';

  @override
  String get publicationYear => 'Publication year';

  @override
  String get copies => 'Copies';

  @override
  String get addBook => 'Add book';

  @override
  String get scanIsbn => 'Scan ISBN';

  @override
  String get searchByIsbn => 'Search by ISBN';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get register => 'Register';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get noAccount => 'No account?';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get backToLogin => 'Back to login';
}
