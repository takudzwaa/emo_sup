import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nd.dart';
import 'app_localizations_sn.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('nd'),
    Locale('sn'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Emo Sup'**
  String get appTitle;

  /// No description provided for @welcomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Someone to talk to — privately'**
  String get welcomeHeadline;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'A confidential space with trained listeners. No public profiles, no real names required.'**
  String get welcomeBody;

  /// No description provided for @welcomeTrustChip.
  ///
  /// In en, this message translates to:
  /// **'Private & confidential'**
  String get welcomeTrustChip;

  /// No description provided for @getStartedAnonymously.
  ///
  /// In en, this message translates to:
  /// **'Get started anonymously'**
  String get getStartedAnonymously;

  /// No description provided for @needUrgentHelp.
  ///
  /// In en, this message translates to:
  /// **'Need urgent help?'**
  String get needUrgentHelp;

  /// No description provided for @notTherapyDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Not therapy. Not an emergency service.'**
  String get notTherapyDisclaimer;

  /// No description provided for @safetyAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Safety & Privacy'**
  String get safetyAndPrivacy;

  /// No description provided for @privateConversation.
  ///
  /// In en, this message translates to:
  /// **'Private conversation'**
  String get privateConversation;

  /// No description provided for @talkToSomeone.
  ///
  /// In en, this message translates to:
  /// **'Talk to Someone'**
  String get talkToSomeone;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @crisisResources.
  ///
  /// In en, this message translates to:
  /// **'Crisis resources'**
  String get crisisResources;

  /// No description provided for @reportAndBlock.
  ///
  /// In en, this message translates to:
  /// **'Report & block'**
  String get reportAndBlock;

  /// No description provided for @deleteMyData.
  ///
  /// In en, this message translates to:
  /// **'Delete my data'**
  String get deleteMyData;

  /// No description provided for @signInPrivately.
  ///
  /// In en, this message translates to:
  /// **'Sign in privately'**
  String get signInPrivately;

  /// No description provided for @listenerDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Listener dashboard'**
  String get listenerDashboardTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageShona.
  ///
  /// In en, this message translates to:
  /// **'Shona'**
  String get languageShona;

  /// No description provided for @languageNdebele.
  ///
  /// In en, this message translates to:
  /// **'Ndebele'**
  String get languageNdebele;

  /// No description provided for @bookASession.
  ///
  /// In en, this message translates to:
  /// **'Book a session'**
  String get bookASession;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Try again later'**
  String get tryAgainLater;

  /// No description provided for @matchingPaused.
  ///
  /// In en, this message translates to:
  /// **'Matching is paused'**
  String get matchingPaused;

  /// No description provided for @noListenersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No listeners available right now'**
  String get noListenersAvailable;

  /// No description provided for @freeChatsUsed.
  ///
  /// In en, this message translates to:
  /// **'Free chats used for this week'**
  String get freeChatsUsed;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get confirmBooking;

  /// No description provided for @chooseATime.
  ///
  /// In en, this message translates to:
  /// **'Choose a time'**
  String get chooseATime;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @away.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get away;

  /// No description provided for @activeChats.
  ///
  /// In en, this message translates to:
  /// **'Active chats'**
  String get activeChats;

  /// No description provided for @upcomingBookings.
  ///
  /// In en, this message translates to:
  /// **'Upcoming bookings'**
  String get upcomingBookings;

  /// No description provided for @openChat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get openChat;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitReport;

  /// No description provided for @blockListener.
  ///
  /// In en, this message translates to:
  /// **'Block this listener'**
  String get blockListener;

  /// No description provided for @discreetMode.
  ///
  /// In en, this message translates to:
  /// **'Discreet mode'**
  String get discreetMode;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLock;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @volunteerPilot.
  ///
  /// In en, this message translates to:
  /// **'Volunteer pilot — no earnings shown.'**
  String get volunteerPilot;
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
      <String>['en', 'nd', 'sn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nd':
      return AppLocalizationsNd();
    case 'sn':
      return AppLocalizationsSn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
