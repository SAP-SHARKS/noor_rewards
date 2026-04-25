import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ur.dart';

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
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
    Locale('id'),
    Locale('ms'),
    Locale('ru'),
    Locale('tr'),
    Locale('ur'),
  ];

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @continue_.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// No description provided for @beginYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Begin Your Journey'**
  String get beginYourJourney;

  /// No description provided for @enterTheGarden.
  ///
  /// In en, this message translates to:
  /// **'Enter the Garden'**
  String get enterTheGarden;

  /// No description provided for @bySigningUp.
  ///
  /// In en, this message translates to:
  /// **'By signing up, you agree to our Terms & Privacy Policy'**
  String get bySigningUp;

  /// No description provided for @lightOfMercy.
  ///
  /// In en, this message translates to:
  /// **'LIGHT OF MERCY'**
  String get lightOfMercy;

  /// No description provided for @noorRewards.
  ///
  /// In en, this message translates to:
  /// **'Noor Rewards'**
  String get noorRewards;

  /// No description provided for @startYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Start Your Journey'**
  String get startYourJourney;

  /// No description provided for @trackSpiritualGrowth.
  ///
  /// In en, this message translates to:
  /// **'Track your spiritual growth, join the community, and unlock exclusive rewards for every good deed.'**
  String get trackSpiritualGrowth;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithQuran.
  ///
  /// In en, this message translates to:
  /// **'Continue with Quran.com'**
  String get continueWithQuran;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Peace Be\nUpon You'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Noor Rewards — where every good deed is a step closer to Allah\'s mercy and light.'**
  String get onboarding1Subtitle;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Two Rewards.\nOne Action.'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Every word you read earns you Sawab — a light in your Akhirah.\nYour Noor Coins fund real causes that change real lives.'**
  String get onboarding2Subtitle;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Remember\nAllah Always'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'A heart that remembers Allah finds peace in every breath. Track your daily zikr and let every bead count.'**
  String get onboarding3Subtitle;

  /// No description provided for @onboarding4Title.
  ///
  /// In en, this message translates to:
  /// **'Reflect &\nGrow Daily'**
  String get onboarding4Title;

  /// No description provided for @onboarding4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'The Quran is a guide for all of mankind. Unlock verses, daily duas, and reflections tailored for your journey.'**
  String get onboarding4Subtitle;

  /// No description provided for @onboarding5Title.
  ///
  /// In en, this message translates to:
  /// **'Give &\nEarn Blessings'**
  String get onboarding5Title;

  /// No description provided for @onboarding5Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sadaqah extinguishes sin as water extinguishes fire. Earn rewards for every act of charity and kindness.'**
  String get onboarding5Subtitle;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name} 🌙'**
  String welcomeUser(String name);

  /// No description provided for @gatesOfNoor.
  ///
  /// In en, this message translates to:
  /// **'The gates of Noor are open.\nYour spiritual journey begins today.'**
  String get gatesOfNoor;

  /// No description provided for @earnNoorPoints.
  ///
  /// In en, this message translates to:
  /// **'EARN NOOR POINTS'**
  String get earnNoorPoints;

  /// No description provided for @yourProgress.
  ///
  /// In en, this message translates to:
  /// **'YOUR PROGRESS'**
  String get yourProgress;

  /// No description provided for @yourTotalNoorPoints.
  ///
  /// In en, this message translates to:
  /// **'YOUR TOTAL NOOR POINTS'**
  String get yourTotalNoorPoints;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @streaks.
  ///
  /// In en, this message translates to:
  /// **'STREAKS'**
  String get streaks;

  /// No description provided for @noorPoints.
  ///
  /// In en, this message translates to:
  /// **'Noor Points'**
  String get noorPoints;

  /// No description provided for @readQuran.
  ///
  /// In en, this message translates to:
  /// **'Read Quran'**
  String get readQuran;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// No description provided for @communityImpact.
  ///
  /// In en, this message translates to:
  /// **'Community Impact'**
  String get communityImpact;

  /// No description provided for @completedProjects.
  ///
  /// In en, this message translates to:
  /// **'Completed Projects'**
  String get completedProjects;

  /// No description provided for @yourContribution.
  ///
  /// In en, this message translates to:
  /// **'Your Contribution'**
  String get yourContribution;

  /// No description provided for @yourReferralCode.
  ///
  /// In en, this message translates to:
  /// **'YOUR REFERRAL CODE'**
  String get yourReferralCode;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @shareVia.
  ///
  /// In en, this message translates to:
  /// **'SHARE VIA'**
  String get shareVia;

  /// No description provided for @friendGets.
  ///
  /// In en, this message translates to:
  /// **'Friend gets'**
  String get friendGets;

  /// No description provided for @youGet.
  ///
  /// In en, this message translates to:
  /// **'You get'**
  String get youGet;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// No description provided for @needed.
  ///
  /// In en, this message translates to:
  /// **'Needed'**
  String get needed;

  /// No description provided for @instant.
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get instant;

  /// No description provided for @viewCampaign.
  ///
  /// In en, this message translates to:
  /// **'View Campaign'**
  String get viewCampaign;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank;

  /// No description provided for @dailyDhikr.
  ///
  /// In en, this message translates to:
  /// **'Daily Dhikr'**
  String get dailyDhikr;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @shareMore.
  ///
  /// In en, this message translates to:
  /// **'Share More'**
  String get shareMore;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noData;

  /// No description provided for @callYou.
  ///
  /// In en, this message translates to:
  /// **'What should we\\ncall you?'**
  String get callYou;

  /// No description provided for @personaliseJourney.
  ///
  /// In en, this message translates to:
  /// **'Personalise your spiritual journey with your name'**
  String get personaliseJourney;

  /// No description provided for @whereFrom.
  ///
  /// In en, this message translates to:
  /// **'Where are\\nyou from?'**
  String get whereFrom;

  /// No description provided for @joinMuslims.
  ///
  /// In en, this message translates to:
  /// **'Join Muslims from around the world on this journey'**
  String get joinMuslims;

  /// No description provided for @whatBringsYou.
  ///
  /// In en, this message translates to:
  /// **'What brings\\nyou here?'**
  String get whatBringsYou;

  /// No description provided for @chooseGoals.
  ///
  /// In en, this message translates to:
  /// **'Choose your spiritual goals — you can select multiple'**
  String get chooseGoals;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navJourney.
  ///
  /// In en, this message translates to:
  /// **'Journey'**
  String get navJourney;

  /// No description provided for @navAkhirah.
  ///
  /// In en, this message translates to:
  /// **'Akhirah'**
  String get navAkhirah;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @communityLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Community Leaderboard'**
  String get communityLeaderboard;

  /// No description provided for @topContributors.
  ///
  /// In en, this message translates to:
  /// **'Top contributors by lifetime pts'**
  String get topContributors;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @startStreak.
  ///
  /// In en, this message translates to:
  /// **'Start your streak today!'**
  String get startStreak;

  /// No description provided for @alreadySealed.
  ///
  /// In en, this message translates to:
  /// **'Already sealed today'**
  String get alreadySealed;

  /// No description provided for @sealTheDay.
  ///
  /// In en, this message translates to:
  /// **'Seal the Day'**
  String get sealTheDay;

  /// No description provided for @alhamdulillah.
  ///
  /// In en, this message translates to:
  /// **'Alhamdulillah!'**
  String get alhamdulillah;

  /// No description provided for @levelSeeker.
  ///
  /// In en, this message translates to:
  /// **'Seeker'**
  String get levelSeeker;

  /// No description provided for @levelBeliever.
  ///
  /// In en, this message translates to:
  /// **'Believer'**
  String get levelBeliever;

  /// No description provided for @levelDevoted.
  ///
  /// In en, this message translates to:
  /// **'Devoted'**
  String get levelDevoted;

  /// No description provided for @levelChampion.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get levelChampion;

  /// No description provided for @levelLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get levelLegend;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @quran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quran;

  /// No description provided for @zikr.
  ///
  /// In en, this message translates to:
  /// **'Zikr'**
  String get zikr;

  /// No description provided for @dailyLogin.
  ///
  /// In en, this message translates to:
  /// **'Daily Login'**
  String get dailyLogin;

  /// No description provided for @todaysProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todaysProgress;

  /// No description provided for @versesToday.
  ///
  /// In en, this message translates to:
  /// **'verses today'**
  String get versesToday;

  /// No description provided for @resumeReading.
  ///
  /// In en, this message translates to:
  /// **'Resume Reading'**
  String get resumeReading;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get continueReading;

  /// No description provided for @chooseWhereToStart.
  ///
  /// In en, this message translates to:
  /// **'Choose Where to Start'**
  String get chooseWhereToStart;

  /// No description provided for @startReadingFrom.
  ///
  /// In en, this message translates to:
  /// **'Start Reading from'**
  String get startReadingFrom;

  /// No description provided for @yourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Your Library'**
  String get yourLibrary;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @tafsir.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get tafsir;

  /// No description provided for @wordByWord.
  ///
  /// In en, this message translates to:
  /// **'Word by Word'**
  String get wordByWord;

  /// No description provided for @mushaf.
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
  String get mushaf;

  /// No description provided for @otherCategories.
  ///
  /// In en, this message translates to:
  /// **'Other Categories'**
  String get otherCategories;

  /// No description provided for @noCategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get noCategoriesAvailable;

  /// No description provided for @nextPts.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextPts;

  /// No description provided for @prev.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get prev;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'en',
    'fr',
    'id',
    'ms',
    'ru',
    'tr',
    'ur',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'id':
      return AppLocalizationsId();
    case 'ms':
      return AppLocalizationsMs();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
