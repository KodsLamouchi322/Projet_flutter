import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Neighborhood Library'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get navCatalog;

  /// No description provided for @navLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get navLoans;

  /// No description provided for @navEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navClubs.
  ///
  /// In en, this message translates to:
  /// **'Clubs'**
  String get navClubs;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @homeWelcomeGuest.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get homeWelcomeGuest;

  /// No description provided for @homeWelcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String homeWelcomeUser(String name);

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to read today?'**
  String get homeSubtitle;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a book, author…'**
  String get homeSearchHint;

  /// No description provided for @sectionForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get sectionForYou;

  /// No description provided for @sectionForYouSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Based on your loans, wishlist and favorite genres'**
  String get sectionForYouSubtitle;

  /// No description provided for @sectionNew.
  ///
  /// In en, this message translates to:
  /// **'New arrivals'**
  String get sectionNew;

  /// No description provided for @sectionPopular.
  ///
  /// In en, this message translates to:
  /// **'Most borrowed'**
  String get sectionPopular;

  /// No description provided for @sectionGenres.
  ///
  /// In en, this message translates to:
  /// **'Browse by genre'**
  String get sectionGenres;

  /// No description provided for @sectionClubs.
  ///
  /// In en, this message translates to:
  /// **'Reading clubs'**
  String get sectionClubs;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @offlineCatalogBanner.
  ///
  /// In en, this message translates to:
  /// **'Showing cached catalog (offline or network issue). Data may be outdated.'**
  String get offlineCatalogBanner;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @clubsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading clubs'**
  String get clubsTitle;

  /// No description provided for @clubsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a club'**
  String get clubsCreate;

  /// No description provided for @clubsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reading club yet'**
  String get clubsEmpty;

  /// No description provided for @clubsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Start a group around a book from the catalog.'**
  String get clubsEmptyHint;

  /// No description provided for @clubsMembers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 member} other{{count} members}}'**
  String clubsMembers(int count);

  /// No description provided for @clubTabChat.
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get clubTabChat;

  /// No description provided for @clubTabAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get clubTabAbout;

  /// No description provided for @clubJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get clubJoin;

  /// No description provided for @clubLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get clubLeave;

  /// No description provided for @clubMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts on the book…'**
  String get clubMessageHint;

  /// No description provided for @clubJoinToChat.
  ///
  /// In en, this message translates to:
  /// **'Join to take part in the discussion'**
  String get clubJoinToChat;

  /// No description provided for @adminClubsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clubs (admin)'**
  String get adminClubsTitle;

  /// No description provided for @adminDeleteClub.
  ///
  /// In en, this message translates to:
  /// **'Delete club'**
  String get adminDeleteClub;

  /// No description provided for @exportPdfReport.
  ///
  /// In en, this message translates to:
  /// **'Export stats (PDF)'**
  String get exportPdfReport;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'You are not connected'**
  String get notConnected;

  /// No description provided for @loginToAccess.
  ///
  /// In en, this message translates to:
  /// **'Log in to access'**
  String get loginToAccess;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to log out?'**
  String get logoutConfirm;

  /// No description provided for @accountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Account suspended'**
  String get accountSuspended;

  /// No description provided for @accountSuspendedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended.\nContact the library.'**
  String get accountSuspendedMessage;

  /// No description provided for @catalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalogTitle;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @newBooks.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newBooks;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @tryOtherKeywords.
  ///
  /// In en, this message translates to:
  /// **'Try other keywords'**
  String get tryOtherKeywords;

  /// No description provided for @emptyCatalog.
  ///
  /// In en, this message translates to:
  /// **'Empty catalog'**
  String get emptyCatalog;

  /// No description provided for @comeBackLater.
  ///
  /// In en, this message translates to:
  /// **'Come back later'**
  String get comeBackLater;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @messagingTitle.
  ///
  /// In en, this message translates to:
  /// **'Messaging'**
  String get messagingTitle;

  /// No description provided for @privateMessages.
  ///
  /// In en, this message translates to:
  /// **'Private messages'**
  String get privateMessages;

  /// No description provided for @forum.
  ///
  /// In en, this message translates to:
  /// **'Forum'**
  String get forum;

  /// No description provided for @loginToChat.
  ///
  /// In en, this message translates to:
  /// **'Log in to chat'**
  String get loginToChat;

  /// No description provided for @noConversation.
  ///
  /// In en, this message translates to:
  /// **'No conversation'**
  String get noConversation;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get startConversation;

  /// No description provided for @newConversation.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get newConversation;

  /// No description provided for @noMemberFound.
  ///
  /// In en, this message translates to:
  /// **'No other member found.'**
  String get noMemberFound;

  /// No description provided for @noMessageInForum.
  ///
  /// In en, this message translates to:
  /// **'No message in this forum'**
  String get noMessageInForum;

  /// No description provided for @startConversationNow.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation!'**
  String get startConversationNow;

  /// No description provided for @writeMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get writeMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @myWishlist.
  ///
  /// In en, this message translates to:
  /// **'My wishlist'**
  String get myWishlist;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @favoriteGenres.
  ///
  /// In en, this message translates to:
  /// **'Favorite genres'**
  String get favoriteGenres;

  /// No description provided for @noGenreSelected.
  ///
  /// In en, this message translates to:
  /// **'No genre selected'**
  String get noGenreSelected;

  /// No description provided for @loansTitle.
  ///
  /// In en, this message translates to:
  /// **'My loans'**
  String get loansTitle;

  /// No description provided for @currentLoans.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentLoans;

  /// No description provided for @loanHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get loanHistory;

  /// No description provided for @noCurrentLoan.
  ///
  /// In en, this message translates to:
  /// **'No current loan'**
  String get noCurrentLoan;

  /// No description provided for @borrowBookFromCatalog.
  ///
  /// In en, this message translates to:
  /// **'Borrow a book from the catalog'**
  String get borrowBookFromCatalog;

  /// No description provided for @noLoanHistory.
  ///
  /// In en, this message translates to:
  /// **'No loan history'**
  String get noLoanHistory;

  /// No description provided for @borrowedOn.
  ///
  /// In en, this message translates to:
  /// **'Borrowed on {date}'**
  String borrowedOn(String date);

  /// No description provided for @returnBy.
  ///
  /// In en, this message translates to:
  /// **'Return by {date}'**
  String returnBy(String date);

  /// No description provided for @returned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returned;

  /// No description provided for @extend.
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get extend;

  /// No description provided for @extensionNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Extension not allowed'**
  String get extensionNotAllowed;

  /// No description provided for @waitingAdminConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for admin confirmation'**
  String get waitingAdminConfirmation;

  /// No description provided for @eventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// No description provided for @upcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingEvents;

  /// No description provided for @pastEvents.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get pastEvents;

  /// No description provided for @noUpcomingEvent.
  ///
  /// In en, this message translates to:
  /// **'No upcoming event'**
  String get noUpcomingEvent;

  /// No description provided for @noPastEvent.
  ///
  /// In en, this message translates to:
  /// **'No past event'**
  String get noPastEvent;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 participant} other{{count} participants}}'**
  String participants(int count);

  /// No description provided for @participate.
  ///
  /// In en, this message translates to:
  /// **'Participate'**
  String get participate;

  /// No description provided for @cancelParticipation.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelParticipation;

  /// No description provided for @eventDetails.
  ///
  /// In en, this message translates to:
  /// **'Event details'**
  String get eventDetails;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get dateAndTime;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @organizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get organizer;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get adminTitle;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @moderation.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get moderation;

  /// No description provided for @manageBooks.
  ///
  /// In en, this message translates to:
  /// **'Manage books'**
  String get manageBooks;

  /// No description provided for @manageLoans.
  ///
  /// In en, this message translates to:
  /// **'Manage loans'**
  String get manageLoans;

  /// No description provided for @manageEvents.
  ///
  /// In en, this message translates to:
  /// **'Manage events'**
  String get manageEvents;

  /// No description provided for @manageMembers.
  ///
  /// In en, this message translates to:
  /// **'Manage members'**
  String get manageMembers;

  /// No description provided for @totalBooks.
  ///
  /// In en, this message translates to:
  /// **'Total books'**
  String get totalBooks;

  /// No description provided for @totalMembers.
  ///
  /// In en, this message translates to:
  /// **'Total members'**
  String get totalMembers;

  /// No description provided for @activeLoans.
  ///
  /// In en, this message translates to:
  /// **'Active loans'**
  String get activeLoans;

  /// No description provided for @overdueLoans.
  ///
  /// In en, this message translates to:
  /// **'Overdue loans'**
  String get overdueLoans;

  /// No description provided for @bookTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get bookTitle;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @isbn.
  ///
  /// In en, this message translates to:
  /// **'ISBN'**
  String get isbn;

  /// No description provided for @genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genre;

  /// No description provided for @publicationYear.
  ///
  /// In en, this message translates to:
  /// **'Publication year'**
  String get publicationYear;

  /// No description provided for @copies.
  ///
  /// In en, this message translates to:
  /// **'Copies'**
  String get copies;

  /// No description provided for @addBook.
  ///
  /// In en, this message translates to:
  /// **'Add book'**
  String get addBook;

  /// No description provided for @scanIsbn.
  ///
  /// In en, this message translates to:
  /// **'Scan ISBN'**
  String get scanIsbn;

  /// No description provided for @searchByIsbn.
  ///
  /// In en, this message translates to:
  /// **'Search by ISBN'**
  String get searchByIsbn;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account?'**
  String get noAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
