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

  /// No description provided for @youSuffix.
  ///
  /// In en, this message translates to:
  /// **'(you)'**
  String get youSuffix;

  /// No description provided for @userFallback.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userFallback;

  /// No description provided for @youHaveDone.
  ///
  /// In en, this message translates to:
  /// **'You\'ve Done!'**
  String get youHaveDone;

  /// No description provided for @playAllBtn.
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get playAllBtn;

  /// No description provided for @playBtn.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playBtn;

  /// No description provided for @readBtn.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get readBtn;

  /// No description provided for @readOnce.
  ///
  /// In en, this message translates to:
  /// **'Read once'**
  String get readOnce;

  /// No description provided for @readNTimes.
  ///
  /// In en, this message translates to:
  /// **'Read {count} times'**
  String readNTimes(int count);

  /// No description provided for @seedsEarnedToday.
  ///
  /// In en, this message translates to:
  /// **'+{count} Sabiq Seeds earned today!'**
  String seedsEarnedToday(int count);

  /// No description provided for @catDailyRemembrance.
  ///
  /// In en, this message translates to:
  /// **'DAILY REMEMBRANCE'**
  String get catDailyRemembrance;

  /// No description provided for @catNightlyRemembrance.
  ///
  /// In en, this message translates to:
  /// **'NIGHTLY REMEMBRANCE'**
  String get catNightlyRemembrance;

  /// No description provided for @catYourSelection.
  ///
  /// In en, this message translates to:
  /// **'YOUR SELECTION'**
  String get catYourSelection;

  /// No description provided for @catContinuousRemembrance.
  ///
  /// In en, this message translates to:
  /// **'CONTINUOUS REMEMBRANCE'**
  String get catContinuousRemembrance;

  /// No description provided for @bannerDailyRemembrance.
  ///
  /// In en, this message translates to:
  /// **'Daily Remembrance\nbrings peace to the soul.'**
  String get bannerDailyRemembrance;

  /// No description provided for @bannerMorningAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Morning Adhkar\nbrings peace to the soul and light to the path.'**
  String get bannerMorningAdhkar;

  /// No description provided for @bannerEveningAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Evening Adhkar\nbrings tranquility and protection for the night.'**
  String get bannerEveningAdhkar;

  /// No description provided for @bannerYourSelection.
  ///
  /// In en, this message translates to:
  /// **'Your beloved words\nof remembrance to keep close to your heart.'**
  String get bannerYourSelection;

  /// No description provided for @bannerContinuousRemembrance.
  ///
  /// In en, this message translates to:
  /// **'Remember Allah\nmuch, that you may be successful.'**
  String get bannerContinuousRemembrance;

  /// No description provided for @frequentlyReadByCommunity.
  ///
  /// In en, this message translates to:
  /// **'Frequently read'**
  String get frequentlyReadByCommunity;

  /// No description provided for @viewFullLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'View full leaderboard'**
  String get viewFullLeaderboard;

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
  /// **'Sabiq Rewards'**
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
  /// **'Welcome to Sabiq Rewards, where every good deed is a step closer to Allah\'s mercy and light.'**
  String get onboarding1Subtitle;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Two Rewards.\nOne Action.'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Every word you read earns you Sawab, a light in your Akhirah.\nYour Sabiq Seeds fund real causes that change real lives.'**
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
  /// **'The gates of light are open.\nYour spiritual journey begins today.'**
  String get gatesOfNoor;

  /// No description provided for @earnNoorPoints.
  ///
  /// In en, this message translates to:
  /// **'EARN SABIQ SEEDS'**
  String get earnNoorPoints;

  /// No description provided for @yourProgress.
  ///
  /// In en, this message translates to:
  /// **'YOUR PROGRESS'**
  String get yourProgress;

  /// No description provided for @yourTotalNoorPoints.
  ///
  /// In en, this message translates to:
  /// **'YOUR TOTAL SABIQ SEEDS'**
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
  /// **'Sabiq Seeds'**
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
  /// **'Choose your spiritual goals, you can select multiple'**
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
  /// **'Top contributors by lifetime Seeds'**
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

  /// No description provided for @reciteMore.
  ///
  /// In en, this message translates to:
  /// **'RECITE MORE.'**
  String get reciteMore;

  /// No description provided for @helpRealLives.
  ///
  /// In en, this message translates to:
  /// **'HELP REAL LIVES.'**
  String get helpRealLives;

  /// No description provided for @yourNoorPointsFundProjects.
  ///
  /// In en, this message translates to:
  /// **'Your Sabiq Seeds fund these projects'**
  String get yourNoorPointsFundProjects;

  /// No description provided for @youBothEarnPoints.
  ///
  /// In en, this message translates to:
  /// **'You both earn 500 Sabiq Seeds!'**
  String get youBothEarnPoints;

  /// No description provided for @reward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get reward;

  /// No description provided for @haveInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Have an invite code?'**
  String get haveInviteCode;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter code…'**
  String get enterCode;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @plantGoodDeeds.
  ///
  /// In en, this message translates to:
  /// **'PLANT GOOD DEEDS'**
  String get plantGoodDeeds;

  /// No description provided for @youDonated.
  ///
  /// In en, this message translates to:
  /// **'You donated'**
  String get youDonated;

  /// No description provided for @seeDetailsForMore.
  ///
  /// In en, this message translates to:
  /// **'See Details for more Projects →'**
  String get seeDetailsForMore;

  /// No description provided for @pts.
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get pts;

  /// No description provided for @funded.
  ///
  /// In en, this message translates to:
  /// **'funded'**
  String get funded;

  /// No description provided for @bySponsor.
  ///
  /// In en, this message translates to:
  /// **'By {sponsor}'**
  String bySponsor(String sponsor);

  /// No description provided for @viewCampaignDonate.
  ///
  /// In en, this message translates to:
  /// **'View Campaign & Donate'**
  String get viewCampaignDonate;

  /// No description provided for @supportThisCause.
  ///
  /// In en, this message translates to:
  /// **'Support this Cause'**
  String get supportThisCause;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance:'**
  String get availableBalance;

  /// No description provided for @donationAmount.
  ///
  /// In en, this message translates to:
  /// **'Donation Amount'**
  String get donationAmount;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get points;

  /// No description provided for @donateEarnReward.
  ///
  /// In en, this message translates to:
  /// **'Donate & Earn Reward'**
  String get donateEarnReward;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'MAX'**
  String get max;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @loadingDots.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingDots;

  /// No description provided for @yourRank.
  ///
  /// In en, this message translates to:
  /// **'Your Rank: #{rank}'**
  String yourRank(String rank);

  /// No description provided for @outOf.
  ///
  /// In en, this message translates to:
  /// **'Out of'**
  String get outOf;

  /// No description provided for @believers.
  ///
  /// In en, this message translates to:
  /// **'believers'**
  String get believers;

  /// No description provided for @topTenContributors.
  ///
  /// In en, this message translates to:
  /// **'Top 10 Contributors'**
  String get topTenContributors;

  /// No description provided for @ourCauses.
  ///
  /// In en, this message translates to:
  /// **'Our Causes'**
  String get ourCauses;

  /// No description provided for @donatePointsToSupport.
  ///
  /// In en, this message translates to:
  /// **'Donate your Sabiq Seeds to support real-world projects'**
  String get donatePointsToSupport;

  /// No description provided for @noActiveProjects.
  ///
  /// In en, this message translates to:
  /// **'No active projects right now'**
  String get noActiveProjects;

  /// No description provided for @checkBackSoon.
  ///
  /// In en, this message translates to:
  /// **'Check back soon insha\'Allah'**
  String get checkBackSoon;

  /// No description provided for @messageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied, share or paste in WhatsApp!'**
  String get messageCopied;

  /// No description provided for @lvl.
  ///
  /// In en, this message translates to:
  /// **'Lvl'**
  String get lvl;

  /// No description provided for @journey.
  ///
  /// In en, this message translates to:
  /// **'Journey'**
  String get journey;

  /// No description provided for @tabStreaks.
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get tabStreaks;

  /// No description provided for @tabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get tabProgress;

  /// No description provided for @tabBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get tabBadges;

  /// No description provided for @tabChallenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get tabChallenges;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @ptsToLevel.
  ///
  /// In en, this message translates to:
  /// **'{pts} Seeds to Level {level}'**
  String ptsToLevel(String pts, String level);

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String dayStreak(String count);

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'actions'**
  String get actions;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'action'**
  String get action;

  /// No description provided for @breakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get breakdown;

  /// No description provided for @activityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity Log'**
  String get activityLog;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See More'**
  String get seeMore;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'more'**
  String get more;

  /// No description provided for @noActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity {period}'**
  String noActivity(String period);

  /// No description provided for @startEarningPts.
  ///
  /// In en, this message translates to:
  /// **'Start earning Seeds, read Quran, do Dhikr & Dua.'**
  String get startEarningPts;

  /// No description provided for @howToEarnPts.
  ///
  /// In en, this message translates to:
  /// **'How to Earn Seeds'**
  String get howToEarnPts;

  /// No description provided for @readOneAyah.
  ///
  /// In en, this message translates to:
  /// **'Read 1 Ayah'**
  String get readOneAyah;

  /// No description provided for @completeOneJuz.
  ///
  /// In en, this message translates to:
  /// **'Complete 1 Juz'**
  String get completeOneJuz;

  /// No description provided for @validateAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Validate & Support'**
  String get validateAndSupport;

  /// No description provided for @levelTiers.
  ///
  /// In en, this message translates to:
  /// **'Level Tiers'**
  String get levelTiers;

  /// No description provided for @basicFeatures.
  ///
  /// In en, this message translates to:
  /// **'Basic features'**
  String get basicFeatures;

  /// No description provided for @customProfileThemes.
  ///
  /// In en, this message translates to:
  /// **'Custom profile themes'**
  String get customProfileThemes;

  /// No description provided for @leaderboardBadge.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard badge'**
  String get leaderboardBadge;

  /// No description provided for @exclusiveVotingRights.
  ///
  /// In en, this message translates to:
  /// **'Exclusive voting rights'**
  String get exclusiveVotingRights;

  /// No description provided for @hallOfFameListing.
  ///
  /// In en, this message translates to:
  /// **'Hall of Fame listing'**
  String get hallOfFameListing;

  /// No description provided for @unlocks.
  ///
  /// In en, this message translates to:
  /// **'Unlocks: {feature}'**
  String unlocks(String feature);

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get now;

  /// No description provided for @trophyVault.
  ///
  /// In en, this message translates to:
  /// **'Trophy Vault'**
  String get trophyVault;

  /// No description provided for @badgesCollected.
  ///
  /// In en, this message translates to:
  /// **'{earned} / {total} badges collected'**
  String badgesCollected(String earned, String total);

  /// No description provided for @percentComplete.
  ///
  /// In en, this message translates to:
  /// **'{pct}% Complete'**
  String percentComplete(String pct);

  /// No description provided for @toUnlock.
  ///
  /// In en, this message translates to:
  /// **'{count} to unlock'**
  String toUnlock(String count);

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'EARNED'**
  String get earned;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'LOCKED'**
  String get locked;

  /// No description provided for @seasonalEvents.
  ///
  /// In en, this message translates to:
  /// **'Seasonal Events'**
  String get seasonalEvents;

  /// No description provided for @weeklyChallenges.
  ///
  /// In en, this message translates to:
  /// **'Weekly Challenges'**
  String get weeklyChallenges;

  /// No description provided for @specialEvents.
  ///
  /// In en, this message translates to:
  /// **'Special Events'**
  String get specialEvents;

  /// No description provided for @noActiveChallenges.
  ///
  /// In en, this message translates to:
  /// **'No active challenges right now'**
  String get noActiveChallenges;

  /// No description provided for @checkBackChallenges.
  ///
  /// In en, this message translates to:
  /// **'Check back soon, Ramadan & Dhul-Hijjah events are coming!'**
  String get checkBackChallenges;

  /// No description provided for @ramadanChallenge.
  ///
  /// In en, this message translates to:
  /// **'Ramadan Challenge'**
  String get ramadanChallenge;

  /// No description provided for @ramadanChallengeDesc.
  ///
  /// In en, this message translates to:
  /// **'3× Seeds multiplier • Special badges • Community wells goal'**
  String get ramadanChallengeDesc;

  /// No description provided for @comingSoonStayConsistent.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon, Stay Consistent!'**
  String get comingSoonStayConsistent;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done!'**
  String get done;

  /// No description provided for @ptsBoost.
  ///
  /// In en, this message translates to:
  /// **'{multiplier}× Seeds Boost'**
  String ptsBoost(String multiplier);

  /// No description provided for @ends.
  ///
  /// In en, this message translates to:
  /// **'Ends {date}'**
  String ends(String date);

  /// No description provided for @loadingStreaks.
  ///
  /// In en, this message translates to:
  /// **'Loading streaks…'**
  String get loadingStreaks;

  /// No description provided for @centurion.
  ///
  /// In en, this message translates to:
  /// **'Centurion, Masha\'Allah!'**
  String get centurion;

  /// No description provided for @currentBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Current best streak'**
  String get currentBestStreak;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'LAST 7 DAYS'**
  String get last7Days;

  /// No description provided for @nextMilestone.
  ///
  /// In en, this message translates to:
  /// **'NEXT MILESTONE'**
  String get nextMilestone;

  /// No description provided for @allMilestones.
  ///
  /// In en, this message translates to:
  /// **'ALL MILESTONES'**
  String get allMilestones;

  /// No description provided for @moreDaysToGo.
  ///
  /// In en, this message translates to:
  /// **'{count} more days to go, keep it up!'**
  String moreDaysToGo(String count);

  /// No description provided for @dayStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String dayStreakLabel(String count);

  /// No description provided for @best.
  ///
  /// In en, this message translates to:
  /// **'Best {count}'**
  String best(String count);

  /// No description provided for @dhikarAndDua.
  ///
  /// In en, this message translates to:
  /// **'Dhikar & Dua'**
  String get dhikarAndDua;

  /// No description provided for @listenTafsir.
  ///
  /// In en, this message translates to:
  /// **'Listen Tafsir'**
  String get listenTafsir;

  /// No description provided for @challenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get challenge;

  /// No description provided for @readListenTafsir.
  ///
  /// In en, this message translates to:
  /// **'Read & Listen Tafsir'**
  String get readListenTafsir;

  /// No description provided for @deepUnderstanding.
  ///
  /// In en, this message translates to:
  /// **'Deep understanding of the Holy Quran'**
  String get deepUnderstanding;

  /// No description provided for @earnPointsTafsir.
  ///
  /// In en, this message translates to:
  /// **'Earn Seeds for every 10 min of Tafsir listening'**
  String get earnPointsTafsir;

  /// No description provided for @featuredSurahs.
  ///
  /// In en, this message translates to:
  /// **'Featured Surahs'**
  String get featuredSurahs;

  /// No description provided for @browseAll114.
  ///
  /// In en, this message translates to:
  /// **'Browse All 114 Surahs'**
  String get browseAll114;

  /// No description provided for @verses.
  ///
  /// In en, this message translates to:
  /// **'{count} verses'**
  String verses(String count);

  /// No description provided for @ayahN.
  ///
  /// In en, this message translates to:
  /// **'Ayah {n}'**
  String ayahN(String n);

  /// No description provided for @readTafsir.
  ///
  /// In en, this message translates to:
  /// **'Read Tafsir'**
  String get readTafsir;

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @loadingTafsir.
  ///
  /// In en, this message translates to:
  /// **'Loading tafsir...'**
  String get loadingTafsir;

  /// No description provided for @tafsirNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Tafsir not available for this ayah.'**
  String get tafsirNotAvailable;

  /// No description provided for @arabicScripture.
  ///
  /// In en, this message translates to:
  /// **'Arabic Scripture'**
  String get arabicScripture;

  /// No description provided for @urduScripture.
  ///
  /// In en, this message translates to:
  /// **'Urdu Scripture'**
  String get urduScripture;

  /// No description provided for @englishCommentary.
  ///
  /// In en, this message translates to:
  /// **'English Commentary'**
  String get englishCommentary;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @nextAyah.
  ///
  /// In en, this message translates to:
  /// **'Next Ayah'**
  String get nextAyah;

  /// No description provided for @readingSettings.
  ///
  /// In en, this message translates to:
  /// **'Reading Settings'**
  String get readingSettings;

  /// No description provided for @tafsirSource.
  ///
  /// In en, this message translates to:
  /// **'TAFSIR SOURCE'**
  String get tafsirSource;

  /// No description provided for @reciter.
  ///
  /// In en, this message translates to:
  /// **'RECITER'**
  String get reciter;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'DISPLAY'**
  String get display;

  /// No description provided for @showArabicText.
  ///
  /// In en, this message translates to:
  /// **'Show Arabic Text'**
  String get showArabicText;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'FONT SIZE'**
  String get fontSize;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @urdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get urdu;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @selectSurah.
  ///
  /// In en, this message translates to:
  /// **'Select Surah'**
  String get selectSurah;

  /// No description provided for @audioNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Audio URL not loaded yet. Please wait...'**
  String get audioNotLoaded;

  /// No description provided for @playbackError.
  ///
  /// In en, this message translates to:
  /// **'Playback error: {message}'**
  String playbackError(String message);

  /// No description provided for @audioUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Audio unavailable, check internet connection.'**
  String get audioUnavailable;

  /// No description provided for @signInToSaveFavourites.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save favourites'**
  String get signInToSaveFavourites;

  /// No description provided for @addedToFavourites.
  ///
  /// In en, this message translates to:
  /// **'Added to Favourites'**
  String get addedToFavourites;

  /// No description provided for @removedFromFavourites.
  ///
  /// In en, this message translates to:
  /// **'Removed from Favourites'**
  String get removedFromFavourites;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get appearance;

  /// No description provided for @comfortableNightReading.
  ///
  /// In en, this message translates to:
  /// **'Comfortable night-time reading'**
  String get comfortableNightReading;

  /// No description provided for @focusMode.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode (Full Screen)'**
  String get focusMode;

  /// No description provided for @focusModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Hide app bar & nav for distraction-free reading'**
  String get focusModeDesc;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get textSize;

  /// No description provided for @small.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get small;

  /// No description provided for @large.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get large;

  /// No description provided for @themeColour.
  ///
  /// In en, this message translates to:
  /// **'Theme Colour'**
  String get themeColour;

  /// No description provided for @quranScript.
  ///
  /// In en, this message translates to:
  /// **'QURAN SCRIPT'**
  String get quranScript;

  /// No description provided for @quranScriptLabel.
  ///
  /// In en, this message translates to:
  /// **'Quran Script'**
  String get quranScriptLabel;

  /// No description provided for @readingLayout.
  ///
  /// In en, this message translates to:
  /// **'READING LAYOUT'**
  String get readingLayout;

  /// No description provided for @showTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show Translation'**
  String get showTranslation;

  /// No description provided for @displayMeaningBelow.
  ///
  /// In en, this message translates to:
  /// **'Display meaning below each verse'**
  String get displayMeaningBelow;

  /// No description provided for @showDailyProgress.
  ///
  /// In en, this message translates to:
  /// **'Show Daily Progress'**
  String get showDailyProgress;

  /// No description provided for @progressBarAyahCount.
  ///
  /// In en, this message translates to:
  /// **'Progress bar & ayah count card'**
  String get progressBarAyahCount;

  /// No description provided for @showPointsBanner.
  ///
  /// In en, this message translates to:
  /// **'Show Seeds Banner'**
  String get showPointsBanner;

  /// No description provided for @noorPointsNotificationStrip.
  ///
  /// In en, this message translates to:
  /// **'+Sabiq Seeds notification strip'**
  String get noorPointsNotificationStrip;

  /// No description provided for @showSurahHeader.
  ///
  /// In en, this message translates to:
  /// **'Show Surah Header'**
  String get showSurahHeader;

  /// No description provided for @surahNameBanner.
  ///
  /// In en, this message translates to:
  /// **'Surah name banner at top of page'**
  String get surahNameBanner;

  /// No description provided for @audioPlayback.
  ///
  /// In en, this message translates to:
  /// **'AUDIO & PLAYBACK'**
  String get audioPlayback;

  /// No description provided for @autoAdvance.
  ///
  /// In en, this message translates to:
  /// **'Auto-Advance'**
  String get autoAdvance;

  /// No description provided for @moveToNextVerse.
  ///
  /// In en, this message translates to:
  /// **'Move to next verse when audio ends'**
  String get moveToNextVerse;

  /// No description provided for @repeatCurrentVerse.
  ///
  /// In en, this message translates to:
  /// **'Repeat Current Verse'**
  String get repeatCurrentVerse;

  /// No description provided for @loopAyahAudio.
  ///
  /// In en, this message translates to:
  /// **'Loop this ayah audio on repeat'**
  String get loopAyahAudio;

  /// No description provided for @notificationsAlerts.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS & ALERTS'**
  String get notificationsAlerts;

  /// No description provided for @dailyReadingReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reading Reminder'**
  String get dailyReadingReminder;

  /// No description provided for @pushReminderReadQuran.
  ///
  /// In en, this message translates to:
  /// **'Push reminder to read Quran each day'**
  String get pushReminderReadQuran;

  /// No description provided for @milestoneSoundAlerts.
  ///
  /// In en, this message translates to:
  /// **'Milestone Sound Alerts'**
  String get milestoneSoundAlerts;

  /// No description provided for @chimeAtMilestones.
  ///
  /// In en, this message translates to:
  /// **'Chime when you reach 10, 25, 50 ayahs'**
  String get chimeAtMilestones;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'ADVANCED'**
  String get advanced;

  /// No description provided for @wordByWordMode.
  ///
  /// In en, this message translates to:
  /// **'Word-by-Word Mode'**
  String get wordByWordMode;

  /// No description provided for @showWordMeaning.
  ///
  /// In en, this message translates to:
  /// **'Show each Arabic word with its English meaning'**
  String get showWordMeaning;

  /// No description provided for @translationLanguage.
  ///
  /// In en, this message translates to:
  /// **'Translation Language'**
  String get translationLanguage;

  /// No description provided for @translationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} translations available'**
  String translationsAvailable(String count);

  /// No description provided for @reciterLabel.
  ///
  /// In en, this message translates to:
  /// **'Reciter:'**
  String get reciterLabel;

  /// No description provided for @playing.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get playing;

  /// No description provided for @favourite.
  ///
  /// In en, this message translates to:
  /// **'Favourite'**
  String get favourite;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// No description provided for @ayahsRead.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs read'**
  String ayahsRead(String count);

  /// No description provided for @goalAyahs.
  ///
  /// In en, this message translates to:
  /// **'Goal: 50 ayahs/day'**
  String get goalAyahs;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next Page'**
  String get nextPage;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @mushafSettings.
  ///
  /// In en, this message translates to:
  /// **'Mushaf Settings'**
  String get mushafSettings;

  /// No description provided for @readingMode.
  ///
  /// In en, this message translates to:
  /// **'READING MODE'**
  String get readingMode;

  /// No description provided for @scroll.
  ///
  /// In en, this message translates to:
  /// **'Scroll'**
  String get scroll;

  /// No description provided for @pageFlip.
  ///
  /// In en, this message translates to:
  /// **'Page Flip'**
  String get pageFlip;

  /// No description provided for @translationLabel.
  ///
  /// In en, this message translates to:
  /// **'TRANSLATION'**
  String get translationLabel;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @splitView.
  ///
  /// In en, this message translates to:
  /// **'Split View'**
  String get splitView;

  /// No description provided for @script.
  ///
  /// In en, this message translates to:
  /// **'SCRIPT'**
  String get script;

  /// No description provided for @actionsLabel.
  ///
  /// In en, this message translates to:
  /// **'ACTIONS'**
  String get actionsLabel;

  /// No description provided for @pageBookmarked.
  ///
  /// In en, this message translates to:
  /// **'Page bookmarked!'**
  String get pageBookmarked;

  /// No description provided for @loadingQuran.
  ///
  /// In en, this message translates to:
  /// **'Loading Quran…'**
  String get loadingQuran;

  /// No description provided for @earnPointsPerVerse.
  ///
  /// In en, this message translates to:
  /// **'Earn +10 Sabiq Seeds per verse read'**
  String get earnPointsPerVerse;

  /// No description provided for @chooseSurah.
  ///
  /// In en, this message translates to:
  /// **'Choose Surah'**
  String get chooseSurah;

  /// No description provided for @chooseVerse.
  ///
  /// In en, this message translates to:
  /// **'Choose Verse'**
  String get chooseVerse;

  /// No description provided for @surahHasVerses.
  ///
  /// In en, this message translates to:
  /// **'{surah} has {count} verses'**
  String surahHasVerses(String surah, String count);

  /// No description provided for @favourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favourites;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String saved(String count);

  /// No description provided for @noSavedYet.
  ///
  /// In en, this message translates to:
  /// **'No {title} yet'**
  String noSavedYet(String title);

  /// No description provided for @tapToSaveVerses.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart/bookmark icon while reading to save verses.'**
  String get tapToSaveVerses;

  /// No description provided for @randomVerse.
  ///
  /// In en, this message translates to:
  /// **'Random Verse'**
  String get randomVerse;

  /// No description provided for @sunnahFriday.
  ///
  /// In en, this message translates to:
  /// **'Sunnah Friday'**
  String get sunnahFriday;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @loadingWordTranslations.
  ///
  /// In en, this message translates to:
  /// **'Loading word translations…'**
  String get loadingWordTranslations;

  /// No description provided for @wordDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Word data unavailable. Check your connection.'**
  String get wordDataUnavailable;

  /// No description provided for @duaAzkarSettings.
  ///
  /// In en, this message translates to:
  /// **'Dua & Azkar Settings'**
  String get duaAzkarSettings;

  /// No description provided for @showTransliteration.
  ///
  /// In en, this message translates to:
  /// **'Show Transliteration'**
  String get showTransliteration;

  /// No description provided for @showIllustration.
  ///
  /// In en, this message translates to:
  /// **'Show Illustration'**
  String get showIllustration;

  /// No description provided for @hideIllustrationArea.
  ///
  /// In en, this message translates to:
  /// **'Hide the visual artwork area'**
  String get hideIllustrationArea;

  /// No description provided for @arabicFontStyle.
  ///
  /// In en, this message translates to:
  /// **'Arabic Font Style'**
  String get arabicFontStyle;

  /// No description provided for @dailyAzkarComplete.
  ///
  /// In en, this message translates to:
  /// **'Daily Azkar Complete!'**
  String get dailyAzkarComplete;

  /// No description provided for @dailyAzkarBonusMsg.
  ///
  /// In en, this message translates to:
  /// **'Masha\'Allah! You tracked your daily Azkar and earned a bonus +50 Sabiq Seeds.'**
  String get dailyAzkarBonusMsg;

  /// No description provided for @awesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome'**
  String get awesome;

  /// No description provided for @betweenSubhSunrise.
  ///
  /// In en, this message translates to:
  /// **'Between Subh-e-Sadiq to Sunrise'**
  String get betweenSubhSunrise;

  /// No description provided for @betweenAsrMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Between Asr and Maghrib'**
  String get betweenAsrMaghrib;

  /// No description provided for @beforeSleeping.
  ///
  /// In en, this message translates to:
  /// **'Before Sleeping'**
  String get beforeSleeping;

  /// No description provided for @uponWakingUp.
  ///
  /// In en, this message translates to:
  /// **'Upon Waking Up'**
  String get uponWakingUp;

  /// No description provided for @afterEachPrayer.
  ///
  /// In en, this message translates to:
  /// **'After Each Prayer'**
  String get afterEachPrayer;

  /// No description provided for @anytimeEspeciallyAfterPrayer.
  ///
  /// In en, this message translates to:
  /// **'Anytime, Especially After Prayer'**
  String get anytimeEspeciallyAfterPrayer;

  /// No description provided for @anytimeMorningEvening.
  ///
  /// In en, this message translates to:
  /// **'Anytime, Morning & Evening'**
  String get anytimeMorningEvening;

  /// No description provided for @duringTheNight.
  ///
  /// In en, this message translates to:
  /// **'During the Night'**
  String get duringTheNight;

  /// No description provided for @anytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get anytime;

  /// No description provided for @asPerSunnah.
  ///
  /// In en, this message translates to:
  /// **'As per Sunnah'**
  String get asPerSunnah;

  /// No description provided for @whenEatingDrinking.
  ///
  /// In en, this message translates to:
  /// **'When Eating or Drinking'**
  String get whenEatingDrinking;

  /// No description provided for @enteringLeavingHome.
  ///
  /// In en, this message translates to:
  /// **'Upon Entering / Leaving Home'**
  String get enteringLeavingHome;

  /// No description provided for @beforeAfterWudu.
  ///
  /// In en, this message translates to:
  /// **'Before or After Wudu'**
  String get beforeAfterWudu;

  /// No description provided for @whenGettingDressed.
  ///
  /// In en, this message translates to:
  /// **'When Getting Dressed'**
  String get whenGettingDressed;

  /// No description provided for @uponBadDream.
  ///
  /// In en, this message translates to:
  /// **'Upon Having a Bad Dream'**
  String get uponBadDream;

  /// No description provided for @forUmmahAnytime.
  ///
  /// In en, this message translates to:
  /// **'For the Ummah, Anytime'**
  String get forUmmahAnytime;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get startNow;

  /// No description provided for @markAsDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as Done'**
  String get markAsDone;

  /// No description provided for @enterCustomCount.
  ///
  /// In en, this message translates to:
  /// **'Enter custom count'**
  String get enterCustomCount;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefault;

  /// No description provided for @noAzkarFound.
  ///
  /// In en, this message translates to:
  /// **'No Azkar found here.'**
  String get noAzkarFound;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @benefit.
  ///
  /// In en, this message translates to:
  /// **'Benefit'**
  String get benefit;

  /// No description provided for @continueAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Continue your {category} Adhkar from where you left off.'**
  String continueAdhkar(String category);

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'set'**
  String get set;

  /// No description provided for @sets.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get sets;

  /// No description provided for @duasOfUmmah.
  ///
  /// In en, this message translates to:
  /// **'Duas of Ummah'**
  String get duasOfUmmah;

  /// No description provided for @beforeSleepCat.
  ///
  /// In en, this message translates to:
  /// **'Before Sleep'**
  String get beforeSleepCat;

  /// No description provided for @tahajjud.
  ///
  /// In en, this message translates to:
  /// **'Tahajjud'**
  String get tahajjud;

  /// No description provided for @salah.
  ///
  /// In en, this message translates to:
  /// **'Salah'**
  String get salah;

  /// No description provided for @salawat.
  ///
  /// In en, this message translates to:
  /// **'Salawat'**
  String get salawat;

  /// No description provided for @sunnahDuas.
  ///
  /// In en, this message translates to:
  /// **'Sunnah Duas'**
  String get sunnahDuas;

  /// No description provided for @quranicDuas.
  ///
  /// In en, this message translates to:
  /// **'Quranic Supplications'**
  String get quranicDuas;

  /// No description provided for @istighfar.
  ///
  /// In en, this message translates to:
  /// **'Istighfar'**
  String get istighfar;

  /// No description provided for @dhikarAllTimes.
  ///
  /// In en, this message translates to:
  /// **'Dhikar All Times'**
  String get dhikarAllTimes;

  /// No description provided for @namesOfAllah.
  ///
  /// In en, this message translates to:
  /// **'Names of Allah'**
  String get namesOfAllah;

  /// No description provided for @nightmares.
  ///
  /// In en, this message translates to:
  /// **'Nightmares'**
  String get nightmares;

  /// No description provided for @wakingUp.
  ///
  /// In en, this message translates to:
  /// **'Waking up'**
  String get wakingUp;

  /// No description provided for @clothes.
  ///
  /// In en, this message translates to:
  /// **'Clothes'**
  String get clothes;

  /// No description provided for @wudu.
  ///
  /// In en, this message translates to:
  /// **'Wudu'**
  String get wudu;

  /// No description provided for @foodAndDrink.
  ///
  /// In en, this message translates to:
  /// **'Food & Drink'**
  String get foodAndDrink;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @istikharah.
  ///
  /// In en, this message translates to:
  /// **'Istikharah'**
  String get istikharah;

  /// No description provided for @adaanAndMasjid.
  ///
  /// In en, this message translates to:
  /// **'Adaan & Masjid'**
  String get adaanAndMasjid;

  /// No description provided for @diffAndHappy.
  ///
  /// In en, this message translates to:
  /// **'Diff & Happy'**
  String get diffAndHappy;

  /// No description provided for @imanProtect.
  ///
  /// In en, this message translates to:
  /// **'Iman Protect'**
  String get imanProtect;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// No description provided for @shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shopping;

  /// No description provided for @marriage.
  ///
  /// In en, this message translates to:
  /// **'Marriage'**
  String get marriage;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @nature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get nature;

  /// No description provided for @death.
  ///
  /// In en, this message translates to:
  /// **'Death'**
  String get death;

  /// No description provided for @gatherings.
  ///
  /// In en, this message translates to:
  /// **'Gatherings'**
  String get gatherings;

  /// No description provided for @hajjAndUmrah.
  ///
  /// In en, this message translates to:
  /// **'Hajj & Umrah'**
  String get hajjAndUmrah;

  /// No description provided for @dailyEssentials.
  ///
  /// In en, this message translates to:
  /// **'Daily Essentials'**
  String get dailyEssentials;

  /// No description provided for @akhirahBalance.
  ///
  /// In en, this message translates to:
  /// **'Akhirah Balance'**
  String get akhirahBalance;

  /// No description provided for @priceless.
  ///
  /// In en, this message translates to:
  /// **'Priceless'**
  String get priceless;

  /// No description provided for @beyondWorldCanHold.
  ///
  /// In en, this message translates to:
  /// **'Beyond what the world can hold'**
  String get beyondWorldCanHold;

  /// No description provided for @deedsToday.
  ///
  /// In en, this message translates to:
  /// **'+{count} deeds today'**
  String deedsToday(String count);

  /// No description provided for @deedsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'+{count} this week'**
  String deedsThisWeek(String count);

  /// No description provided for @bestDayStreak.
  ///
  /// In en, this message translates to:
  /// **'Best: {count} day streak'**
  String bestDayStreak(String count);

  /// No description provided for @donateMoreEarn.
  ///
  /// In en, this message translates to:
  /// **'Donate More & Earn'**
  String get donateMoreEarn;

  /// No description provided for @yourHoldings.
  ///
  /// In en, this message translates to:
  /// **'Your Holdings'**
  String get yourHoldings;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All →'**
  String get seeAll;

  /// No description provided for @hasanaatEarned.
  ///
  /// In en, this message translates to:
  /// **'Hasanaat Earned'**
  String get hasanaatEarned;

  /// No description provided for @recordedInBookOfDeeds.
  ///
  /// In en, this message translates to:
  /// **'Recorded in your Book of Deeds'**
  String get recordedInBookOfDeeds;

  /// No description provided for @treesInJannah.
  ///
  /// In en, this message translates to:
  /// **'Trees in Jannah'**
  String get treesInJannah;

  /// No description provided for @fromTasbih.
  ///
  /// In en, this message translates to:
  /// **'From SubhanAllah & Tasbih'**
  String get fromTasbih;

  /// No description provided for @sinsForgiven.
  ///
  /// In en, this message translates to:
  /// **'Sins Forgiven'**
  String get sinsForgiven;

  /// No description provided for @likeTheFoamOfSea.
  ///
  /// In en, this message translates to:
  /// **'Like the foam of the sea'**
  String get likeTheFoamOfSea;

  /// No description provided for @palacesBuilt.
  ///
  /// In en, this message translates to:
  /// **'Palaces Built'**
  String get palacesBuilt;

  /// No description provided for @surahIkhlasAndSunnahs.
  ///
  /// In en, this message translates to:
  /// **'Surah Ikhlas & Sunnahs'**
  String get surahIkhlasAndSunnahs;

  /// No description provided for @treasuresOfJannah.
  ///
  /// In en, this message translates to:
  /// **'Treasures of Jannah'**
  String get treasuresOfJannah;

  /// No description provided for @slavesFreedom.
  ///
  /// In en, this message translates to:
  /// **'Slaves Freed'**
  String get slavesFreedom;

  /// No description provided for @equivalentReward.
  ///
  /// In en, this message translates to:
  /// **'Equivalent reward earned'**
  String get equivalentReward;

  /// No description provided for @sadaqahGiven.
  ///
  /// In en, this message translates to:
  /// **'Sadaqah Given'**
  String get sadaqahGiven;

  /// No description provided for @pointsDonatedToCommunity.
  ///
  /// In en, this message translates to:
  /// **'Seeds donated to community'**
  String get pointsDonatedToCommunity;

  /// No description provided for @allTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTimeLabel;

  /// No description provided for @worshipActivity.
  ///
  /// In en, this message translates to:
  /// **'Worship Activity'**
  String get worshipActivity;

  /// No description provided for @timeSpentInRemembrance.
  ///
  /// In en, this message translates to:
  /// **'Time spent in remembrance'**
  String get timeSpentInRemembrance;

  /// No description provided for @noorPointsSummary.
  ///
  /// In en, this message translates to:
  /// **'Sabiq Seeds Summary'**
  String get noorPointsSummary;

  /// No description provided for @totalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total Seeds'**
  String get totalPoints;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @everyDeedRecorded.
  ///
  /// In en, this message translates to:
  /// **'Every deed is recorded. Keep going!'**
  String get everyDeedRecorded;

  /// No description provided for @yourAvailable.
  ///
  /// In en, this message translates to:
  /// **'Your available: {pts} Seeds'**
  String yourAvailable(String pts);

  /// No description provided for @jazakAllahDonated.
  ///
  /// In en, this message translates to:
  /// **'JazakAllah! {pts} Seeds donated'**
  String jazakAllahDonated(String pts);

  /// No description provided for @insufficientPoints.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Seeds'**
  String get insufficientPoints;

  /// No description provided for @donatePoints.
  ///
  /// In en, this message translates to:
  /// **'Donate {pts} Seeds'**
  String donatePoints(String pts);

  /// No description provided for @everyRecitationCanChange.
  ///
  /// In en, this message translates to:
  /// **'Every Recitation Can\nChange a Life'**
  String get everyRecitationCanChange;

  /// No description provided for @fullyFunded.
  ///
  /// In en, this message translates to:
  /// **'Fully Funded ✓'**
  String get fullyFunded;

  /// No description provided for @noPointsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Seeds Available'**
  String get noPointsAvailable;

  /// No description provided for @communityProgress.
  ///
  /// In en, this message translates to:
  /// **'Community Progress'**
  String get communityProgress;

  /// No description provided for @myContribution.
  ///
  /// In en, this message translates to:
  /// **'My contribution: {pts} pts'**
  String myContribution(String pts);

  /// No description provided for @ptsRaised.
  ///
  /// In en, this message translates to:
  /// **'pts raised'**
  String get ptsRaised;

  /// No description provided for @ofGoal.
  ///
  /// In en, this message translates to:
  /// **'of {goal} pts goal'**
  String ofGoal(String goal);

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'days left'**
  String get daysLeft;

  /// No description provided for @lastDay.
  ///
  /// In en, this message translates to:
  /// **'Last day!'**
  String get lastDay;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'deadline'**
  String get deadline;

  /// No description provided for @campaignStory.
  ///
  /// In en, this message translates to:
  /// **'Campaign Story'**
  String get campaignStory;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates ({count})'**
  String updates(String count);

  /// No description provided for @campaign.
  ///
  /// In en, this message translates to:
  /// **'Campaign'**
  String get campaign;

  /// No description provided for @noStoryYet.
  ///
  /// In en, this message translates to:
  /// **'No story added yet.'**
  String get noStoryYet;

  /// No description provided for @checkAdminPanel.
  ///
  /// In en, this message translates to:
  /// **'Check the admin panel to add a campaign story.'**
  String get checkAdminPanel;

  /// No description provided for @noUpdatesYet.
  ///
  /// In en, this message translates to:
  /// **'No updates yet.'**
  String get noUpdatesYet;

  /// No description provided for @checkBackForNews.
  ///
  /// In en, this message translates to:
  /// **'Check back soon for campaign news.'**
  String get checkBackForNews;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(String count);

  /// No description provided for @shareCampaign.
  ///
  /// In en, this message translates to:
  /// **'Share Campaign'**
  String get shareCampaign;

  /// No description provided for @spreadTheWord.
  ///
  /// In en, this message translates to:
  /// **'Spread the word and help this cause reach its goal.'**
  String get spreadTheWord;

  /// No description provided for @shareViaWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share via WhatsApp'**
  String get shareViaWhatsApp;

  /// No description provided for @moreSharingOptions.
  ///
  /// In en, this message translates to:
  /// **'More sharing options…'**
  String get moreSharingOptions;

  /// No description provided for @slideToAdjust.
  ///
  /// In en, this message translates to:
  /// **'Slide to adjust'**
  String get slideToAdjust;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @loadingYourReport.
  ///
  /// In en, this message translates to:
  /// **'Loading your report…'**
  String get loadingYourReport;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated ✓'**
  String get profileUpdated;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save, please try again'**
  String get couldNotSave;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated ✓'**
  String get photoUpdated;

  /// No description provided for @couldNotUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not upload photo, please try again'**
  String get couldNotUploadPhoto;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get changeProfilePhoto;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takeAPhoto;

  /// No description provided for @chooseFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from Library'**
  String get chooseFromLibrary;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @photoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Photo removed'**
  String get photoRemoved;

  /// No description provided for @couldNotRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not remove photo'**
  String get couldNotRemovePhoto;

  /// No description provided for @signOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sign Out?'**
  String get signOutQuestion;

  /// No description provided for @progressSafelyStored.
  ///
  /// In en, this message translates to:
  /// **'Your progress is safely stored. You can sign back in anytime.'**
  String get progressSafelyStored;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhoto;

  /// No description provided for @tapEditToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap Edit to change your photo'**
  String get tapEditToChange;

  /// No description provided for @tapEditToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap Edit to add a photo'**
  String get tapEditToAdd;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @countryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pakistan, UK…'**
  String get countryHint;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notifOnDesc.
  ///
  /// In en, this message translates to:
  /// **'Rewards, streak milestones, donations & more'**
  String get notifOnDesc;

  /// No description provided for @notifOffDesc.
  ///
  /// In en, this message translates to:
  /// **'Turned off, no new alerts will be added'**
  String get notifOffDesc;

  /// No description provided for @viewNotificationsInbox.
  ///
  /// In en, this message translates to:
  /// **'View notifications inbox'**
  String get viewNotificationsInbox;

  /// No description provided for @nNew.
  ///
  /// In en, this message translates to:
  /// **'{n} new'**
  String nNew(String n);

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @reportABug.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get reportABug;

  /// No description provided for @aboutNoorRewards.
  ///
  /// In en, this message translates to:
  /// **'About Sabiq Rewards'**
  String get aboutNoorRewards;

  /// No description provided for @builtWithLove.
  ///
  /// In en, this message translates to:
  /// **'Built with love for the Ummah'**
  String get builtWithLove;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @howWeProtectData.
  ///
  /// In en, this message translates to:
  /// **'How we protect your data'**
  String get howWeProtectData;

  /// No description provided for @bugReportBody.
  ///
  /// In en, this message translates to:
  /// **'Found something wrong? Please email us and we\'ll fix it as soon as possible.'**
  String get bugReportBody;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Built with love for the global Muslim Ummah.\nEarn Sabiq Seeds by building Islamic habits.\nDonate Seeds to support real community projects.'**
  String get aboutBody;

  /// No description provided for @howToEarnQuestion.
  ///
  /// In en, this message translates to:
  /// **'How to earn Sabiq Seeds?'**
  String get howToEarnQuestion;

  /// No description provided for @howToEarnAnswer.
  ///
  /// In en, this message translates to:
  /// **'Complete Quran reading, Dhikr sets, and daily login to earn Seeds.'**
  String get howToEarnAnswer;

  /// No description provided for @whatIsValidateQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is Validate Coins?'**
  String get whatIsValidateQuestion;

  /// No description provided for @whatIsValidateAnswer.
  ///
  /// In en, this message translates to:
  /// **'Press the Validate button on the home page once per day to seal your coins.'**
  String get whatIsValidateAnswer;

  /// No description provided for @howStreaksWorkQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do streaks work?'**
  String get howStreaksWorkQuestion;

  /// No description provided for @howStreaksWorkAnswer.
  ///
  /// In en, this message translates to:
  /// **'Complete your daily activities consecutively to build your streak.'**
  String get howStreaksWorkAnswer;

  /// No description provided for @canDonatQuestion.
  ///
  /// In en, this message translates to:
  /// **'Can I donate my Sabiq Seeds?'**
  String get canDonatQuestion;

  /// No description provided for @canDonateAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes! Visit the Akhirah tab to donate your Seeds to active community projects.'**
  String get canDonateAnswer;

  /// No description provided for @coinsSealedMashaAllah.
  ///
  /// In en, this message translates to:
  /// **'Coins Sealed!'**
  String get coinsSealedMashaAllah;

  /// No description provided for @rewardedForConsistency.
  ///
  /// In en, this message translates to:
  /// **'You have been rewarded for\nyour consistency today!'**
  String get rewardedForConsistency;

  /// No description provided for @validationPoints.
  ///
  /// In en, this message translates to:
  /// **'Validation Points'**
  String get validationPoints;

  /// No description provided for @streakBonus.
  ///
  /// In en, this message translates to:
  /// **'Streak Bonus'**
  String streakBonus(String days, String type, String points);

  /// No description provided for @totalEarned.
  ///
  /// In en, this message translates to:
  /// **'Total Earned'**
  String get totalEarned;

  /// No description provided for @openQuran.
  ///
  /// In en, this message translates to:
  /// **'Open Quran'**
  String get openQuran;

  /// No description provided for @duaAndAzkaar.
  ///
  /// In en, this message translates to:
  /// **'Dua & Azkaar'**
  String get duaAndAzkaar;

  /// No description provided for @shareWithFriends.
  ///
  /// In en, this message translates to:
  /// **'Share with Friends'**
  String get shareWithFriends;

  /// No description provided for @earnMoreNoor.
  ///
  /// In en, this message translates to:
  /// **'Earn More Seeds'**
  String get earnMoreNoor;

  /// No description provided for @dontDisturb.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Disturb'**
  String get dontDisturb;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater;

  /// No description provided for @read5QuranPages.
  ///
  /// In en, this message translates to:
  /// **'Read 5 Quran Pages'**
  String get read5QuranPages;

  /// No description provided for @completeNowBonus.
  ///
  /// In en, this message translates to:
  /// **'Complete now → earn +50 Seeds bonus'**
  String get completeNowBonus;

  /// No description provided for @completeADhikrSet.
  ///
  /// In en, this message translates to:
  /// **'Complete a Dhikr Set'**
  String get completeADhikrSet;

  /// No description provided for @finishAzkaarBonus.
  ///
  /// In en, this message translates to:
  /// **'Finish your Azkaar → earn +30 Seeds bonus'**
  String get finishAzkaarBonus;

  /// No description provided for @inviteAFriend.
  ///
  /// In en, this message translates to:
  /// **'Invite a Friend'**
  String get inviteAFriend;

  /// No description provided for @shareNoorBonus.
  ///
  /// In en, this message translates to:
  /// **'Share Sabiq with someone → earn +100 Seeds'**
  String get shareNoorBonus;

  /// No description provided for @multiplyYour.
  ///
  /// In en, this message translates to:
  /// **'MULTIPLY YOUR'**
  String get multiplyYour;

  /// No description provided for @noorPointsBang.
  ///
  /// In en, this message translates to:
  /// **'SABIQ SEEDS!'**
  String get noorPointsBang;

  /// No description provided for @keepMomentum.
  ///
  /// In en, this message translates to:
  /// **'Keep your spiritual momentum going\nand watch your Seeds grow'**
  String get keepMomentum;

  /// No description provided for @openQuranNow.
  ///
  /// In en, this message translates to:
  /// **'Open Quran Now'**
  String get openQuranNow;

  /// No description provided for @startAzkaarNow.
  ///
  /// In en, this message translates to:
  /// **'Start Azkaar Now'**
  String get startAzkaarNow;

  /// No description provided for @goodDeed.
  ///
  /// In en, this message translates to:
  /// **'Good Deed'**
  String get goodDeed;

  /// No description provided for @earnSawabWithRead.
  ///
  /// In en, this message translates to:
  /// **'Earn Sawab\nwith every read'**
  String get earnSawabWithRead;

  /// No description provided for @realImpact.
  ///
  /// In en, this message translates to:
  /// **'Real Impact'**
  String get realImpact;

  /// No description provided for @coinsFundCauses.
  ///
  /// In en, this message translates to:
  /// **'Seeds fund\nnoble causes'**
  String get coinsFundCauses;

  /// No description provided for @unexpectedGoogleError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error during Google Sign In'**
  String get unexpectedGoogleError;

  /// No description provided for @authSuccessQuran.
  ///
  /// In en, this message translates to:
  /// **'Successfully authenticated with Quran.com!'**
  String get authSuccessQuran;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Auth Error'**
  String get authError;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @connectedAccount.
  ///
  /// In en, this message translates to:
  /// **'Connected Account'**
  String get connectedAccount;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @noorPlusPoints.
  ///
  /// In en, this message translates to:
  /// **'+{pts} Sabiq Seeds'**
  String noorPlusPoints(String pts);

  /// No description provided for @yourGarden.
  ///
  /// In en, this message translates to:
  /// **'YOUR GARDEN'**
  String get yourGarden;

  /// No description provided for @noorPointsBloomed.
  ///
  /// In en, this message translates to:
  /// **'Sabiq Seeds bloomed'**
  String get noorPointsBloomed;

  /// No description provided for @growingStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'GROWING STREAK'**
  String get growingStreakTitle;

  /// No description provided for @daySingular.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get daySingular;

  /// No description provided for @daysPlural.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysPlural;

  /// No description provided for @keepGrowing.
  ///
  /// In en, this message translates to:
  /// **'keep growing'**
  String get keepGrowing;

  /// No description provided for @progressLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressLabel;

  /// No description provided for @weekTab.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get weekTab;

  /// No description provided for @monthTab.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthTab;

  /// No description provided for @todayTab.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTab;

  /// No description provided for @ofTabGoal.
  ///
  /// In en, this message translates to:
  /// **'of {goal} {tab} goal'**
  String ofTabGoal(String goal, String tab);

  /// No description provided for @todaysPlots.
  ///
  /// In en, this message translates to:
  /// **'Today\'s plots'**
  String get todaysPlots;

  /// No description provided for @setsTodayCount.
  ///
  /// In en, this message translates to:
  /// **'sets today {count}'**
  String setsTodayCount(String count);

  /// No description provided for @earnPerFriend.
  ///
  /// In en, this message translates to:
  /// **'Earn +500 per friend'**
  String get earnPerFriend;

  /// No description provided for @lastAchievement.
  ///
  /// In en, this message translates to:
  /// **'Last: {name}'**
  String lastAchievement(String name);

  /// No description provided for @outOfBelievers.
  ///
  /// In en, this message translates to:
  /// **'Out of {count} believers'**
  String outOfBelievers(String count);

  /// No description provided for @yourRankNum.
  ///
  /// In en, this message translates to:
  /// **'Your Rank: #{rank}'**
  String yourRankNum(String rank);

  /// No description provided for @youIndicator.
  ///
  /// In en, this message translates to:
  /// **'(you)'**
  String get youIndicator;

  /// No description provided for @greetingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum,'**
  String get greetingPrefix;

  /// No description provided for @fundProjectsText.
  ///
  /// In en, this message translates to:
  /// **'Your Sabiq Seeds fund these projects'**
  String get fundProjectsText;

  /// No description provided for @activeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String activeCount(String count);

  /// No description provided for @seeDetailsForMoreProjects.
  ///
  /// In en, this message translates to:
  /// **'See Details for more Projects →'**
  String get seeDetailsForMoreProjects;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on top of rewards & milestones'**
  String get notificationsSubtitle;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @notificationsOn.
  ///
  /// In en, this message translates to:
  /// **'Notifications on'**
  String get notificationsOn;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications off'**
  String get notificationsOff;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get allCaughtUp;

  /// No description provided for @whenYouEarnRewards.
  ///
  /// In en, this message translates to:
  /// **'When you earn rewards, hit a streak, or unlock a badge,\nit\'ll show up here.'**
  String get whenYouEarnRewards;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @mAgo.
  ///
  /// In en, this message translates to:
  /// **'{delta}m ago'**
  String mAgo(String delta);

  /// No description provided for @hAgo.
  ///
  /// In en, this message translates to:
  /// **'{delta}h ago'**
  String hAgo(String delta);

  /// No description provided for @dAgo.
  ///
  /// In en, this message translates to:
  /// **'{delta}d ago'**
  String dAgo(String delta);

  /// No description provided for @newBadgeUnlocked.
  ///
  /// In en, this message translates to:
  /// **'New badge unlocked'**
  String get newBadgeUnlocked;

  /// No description provided for @daySealed.
  ///
  /// In en, this message translates to:
  /// **'Day sealed'**
  String get daySealed;

  /// No description provided for @dailyLoginBonus.
  ///
  /// In en, this message translates to:
  /// **'Daily login bonus'**
  String get dailyLoginBonus;

  /// No description provided for @oneWeek.
  ///
  /// In en, this message translates to:
  /// **'One Week'**
  String get oneWeek;

  /// No description provided for @twoWeeks.
  ///
  /// In en, this message translates to:
  /// **'Two Weeks'**
  String get twoWeeks;

  /// No description provided for @badgeEarnedDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'ve earned the \"{badge}\" badge.'**
  String badgeEarnedDesc(String badge);

  /// No description provided for @pointsForSealing.
  ///
  /// In en, this message translates to:
  /// **'+{points} Sabiq Seeds for sealing today.'**
  String pointsForSealing(String points);

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'+{points} Sabiq Seeds · welcome back!'**
  String welcomeBack(String points);

  /// No description provided for @onbV2Skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbV2Skip;

  /// No description provided for @onbV2Next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onbV2Next;

  /// No description provided for @onbV2_1_TitleA.
  ///
  /// In en, this message translates to:
  /// **'Your Quran reading'**
  String get onbV2_1_TitleA;

  /// No description provided for @onbV2_1_TitleB.
  ///
  /// In en, this message translates to:
  /// **'feeds the hungry.'**
  String get onbV2_1_TitleB;

  /// No description provided for @onbV2_1_Sub.
  ///
  /// In en, this message translates to:
  /// **'Real meals. Real people. Real impact.'**
  String get onbV2_1_Sub;

  /// No description provided for @onbV2_1_Cta.
  ///
  /// In en, this message translates to:
  /// **'How does that work?'**
  String get onbV2_1_Cta;

  /// No description provided for @onbV2_2_Title.
  ///
  /// In en, this message translates to:
  /// **'Here\'s how.'**
  String get onbV2_2_Title;

  /// No description provided for @onbV2_2_Body.
  ///
  /// In en, this message translates to:
  /// **'Read Quran or recite dhikr → earn Sabiq Seeds → fund real causes.'**
  String get onbV2_2_Body;

  /// No description provided for @onbV2_3_TitleA.
  ///
  /// In en, this message translates to:
  /// **'The Quran rewards you'**
  String get onbV2_3_TitleA;

  /// No description provided for @onbV2_3_TitleB.
  ///
  /// In en, this message translates to:
  /// **'twice.'**
  String get onbV2_3_TitleB;

  /// No description provided for @onbV2_3_Sub.
  ///
  /// In en, this message translates to:
  /// **'Once with Allah\'s blessing. Once with Seeds that feed the needy.'**
  String get onbV2_3_Sub;

  /// No description provided for @onbV2_3_BannerLabel.
  ///
  /// In en, this message translates to:
  /// **'earned today'**
  String get onbV2_3_BannerLabel;

  /// No description provided for @onbV2_4_TitleA.
  ///
  /// In en, this message translates to:
  /// **'See your worship'**
  String get onbV2_4_TitleA;

  /// No description provided for @onbV2_4_TitleB.
  ///
  /// In en, this message translates to:
  /// **'come to life.'**
  String get onbV2_4_TitleB;

  /// No description provided for @onbV2_4_Sub.
  ///
  /// In en, this message translates to:
  /// **'Recite morning and evening dhikr, and watch your reward unfold, hadith by hadith.'**
  String get onbV2_4_Sub;

  /// No description provided for @onbV2_5_TitleA.
  ///
  /// In en, this message translates to:
  /// **'Your reading reaches'**
  String get onbV2_5_TitleA;

  /// No description provided for @onbV2_5_TitleB.
  ///
  /// In en, this message translates to:
  /// **'here.'**
  String get onbV2_5_TitleB;

  /// No description provided for @onbV2_5_Sub.
  ///
  /// In en, this message translates to:
  /// **'Every Seed you earn becomes real food, real water, real hope.'**
  String get onbV2_5_Sub;

  /// No description provided for @onbV2_6_TitleA.
  ///
  /// In en, this message translates to:
  /// **'But where does the'**
  String get onbV2_6_TitleA;

  /// No description provided for @onbV2_6_TitleB.
  ///
  /// In en, this message translates to:
  /// **'money'**
  String get onbV2_6_TitleB;

  /// No description provided for @onbV2_6_TitleC.
  ///
  /// In en, this message translates to:
  /// **'come from?'**
  String get onbV2_6_TitleC;

  /// No description provided for @onbV2_6_Sub.
  ///
  /// In en, this message translates to:
  /// **'Generous donors fund the causes. Your Seeds direct where their gift goes, and grow their reward with every reader.'**
  String get onbV2_6_Sub;

  /// No description provided for @onbV2_6_Donor.
  ///
  /// In en, this message translates to:
  /// **'Donor'**
  String get onbV2_6_Donor;

  /// No description provided for @onbV2_6_DonorSub.
  ///
  /// In en, this message translates to:
  /// **'Funds the cause'**
  String get onbV2_6_DonorSub;

  /// No description provided for @onbV2_6_You.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get onbV2_6_You;

  /// No description provided for @onbV2_6_YouSub.
  ///
  /// In en, this message translates to:
  /// **'Direct the gift'**
  String get onbV2_6_YouSub;

  /// No description provided for @onbV2_6_Charity.
  ///
  /// In en, this message translates to:
  /// **'Charity'**
  String get onbV2_6_Charity;

  /// No description provided for @onbV2_6_CharitySub.
  ///
  /// In en, this message translates to:
  /// **'Delivers aid'**
  String get onbV2_6_CharitySub;

  /// No description provided for @onbV2_6_TrustBadge.
  ///
  /// In en, this message translates to:
  /// **'100% disbursed to verified partners'**
  String get onbV2_6_TrustBadge;

  /// No description provided for @onbV2_7_TitleA.
  ///
  /// In en, this message translates to:
  /// **'Every deed is'**
  String get onbV2_7_TitleA;

  /// No description provided for @onbV2_7_TitleB.
  ///
  /// In en, this message translates to:
  /// **'counted.'**
  String get onbV2_7_TitleB;

  /// No description provided for @onbV2_7_Sub.
  ///
  /// In en, this message translates to:
  /// **'See the akhirah account you\'re building, trees, palaces, freed souls, rooted in authentic hadith.'**
  String get onbV2_7_Sub;

  /// No description provided for @onbV2_8_TitleA.
  ///
  /// In en, this message translates to:
  /// **'Let\'s begin with your'**
  String get onbV2_8_TitleA;

  /// No description provided for @onbV2_8_TitleB.
  ///
  /// In en, this message translates to:
  /// **'name.'**
  String get onbV2_8_TitleB;

  /// No description provided for @onbV2_8_Sub.
  ///
  /// In en, this message translates to:
  /// **'So Sabiq feels like yours.'**
  String get onbV2_8_Sub;

  /// No description provided for @onbV2_8_Placeholder.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get onbV2_8_Placeholder;

  /// No description provided for @onbV2_8_Cta.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onbV2_8_Cta;

  /// No description provided for @onbV2_9_TitleA.
  ///
  /// In en, this message translates to:
  /// **'Which cause moves you'**
  String get onbV2_9_TitleA;

  /// No description provided for @onbV2_9_TitleB.
  ///
  /// In en, this message translates to:
  /// **'most?'**
  String get onbV2_9_TitleB;

  /// No description provided for @onbV2_9_Sub.
  ///
  /// In en, this message translates to:
  /// **'Your Seeds support all causes, this just helps us understand what matters to our community.'**
  String get onbV2_9_Sub;

  /// No description provided for @onbV2_9_Cta.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get onbV2_9_Cta;

  /// No description provided for @onbV2_9_Orphans.
  ///
  /// In en, this message translates to:
  /// **'Orphans'**
  String get onbV2_9_Orphans;

  /// No description provided for @onbV2_9_OrphansSub.
  ///
  /// In en, this message translates to:
  /// **'Feed and care for children who\'ve lost everything'**
  String get onbV2_9_OrphansSub;

  /// No description provided for @onbV2_9_Water.
  ///
  /// In en, this message translates to:
  /// **'Water Wells'**
  String get onbV2_9_Water;

  /// No description provided for @onbV2_9_WaterSub.
  ///
  /// In en, this message translates to:
  /// **'Clean water for villages in need'**
  String get onbV2_9_WaterSub;

  /// No description provided for @onbV2_9_War.
  ///
  /// In en, this message translates to:
  /// **'War-Impacted Areas'**
  String get onbV2_9_War;

  /// No description provided for @onbV2_9_WarSub.
  ///
  /// In en, this message translates to:
  /// **'Relief where it\'s needed most'**
  String get onbV2_9_WarSub;

  /// No description provided for @onbV2_9_Disaster.
  ///
  /// In en, this message translates to:
  /// **'Natural Disasters'**
  String get onbV2_9_Disaster;

  /// No description provided for @onbV2_9_DisasterSub.
  ///
  /// In en, this message translates to:
  /// **'Rapid response when crisis strikes'**
  String get onbV2_9_DisasterSub;

  /// No description provided for @onbV2_3step_Title.
  ///
  /// In en, this message translates to:
  /// **'Three simple steps.'**
  String get onbV2_3step_Title;

  /// No description provided for @onbV2_3step_Sub.
  ///
  /// In en, this message translates to:
  /// **'Every verse, every dhikr becomes real aid.'**
  String get onbV2_3step_Sub;

  /// No description provided for @onbV2_3step_S1Label.
  ///
  /// In en, this message translates to:
  /// **'Step 1'**
  String get onbV2_3step_S1Label;

  /// No description provided for @onbV2_3step_S1Text.
  ///
  /// In en, this message translates to:
  /// **'Read Quran'**
  String get onbV2_3step_S1Text;

  /// No description provided for @onbV2_3step_S2Label.
  ///
  /// In en, this message translates to:
  /// **'Step 2'**
  String get onbV2_3step_S2Label;

  /// No description provided for @onbV2_3step_S2Text.
  ///
  /// In en, this message translates to:
  /// **'Earn Seeds'**
  String get onbV2_3step_S2Text;

  /// No description provided for @onbV2_3step_S3Label.
  ///
  /// In en, this message translates to:
  /// **'Step 3'**
  String get onbV2_3step_S3Label;

  /// No description provided for @onbV2_3step_S3Text.
  ///
  /// In en, this message translates to:
  /// **'Feed Orphans'**
  String get onbV2_3step_S3Text;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @yourStreaksTitle.
  ///
  /// In en, this message translates to:
  /// **'YOUR STREAKS'**
  String get yourStreaksTitle;

  /// No description provided for @streakLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading streaks…'**
  String get streakLoading;

  /// No description provided for @startStreakToday.
  ///
  /// In en, this message translates to:
  /// **'Start your streak today!'**
  String get startStreakToday;

  /// No description provided for @centurionMashaAllah.
  ///
  /// In en, this message translates to:
  /// **'Centurion, Masha\'Allah!'**
  String get centurionMashaAllah;

  /// No description provided for @qfConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Already Exists'**
  String get qfConflictTitle;

  /// No description provided for @qfConflictExplanation.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered with Sabiq Rewards using a different sign-in method (Email or Google).\n\nTo protect your existing progress, streaks, and Sabiq Seeds, please sign in using your original method.'**
  String get qfConflictExplanation;

  /// No description provided for @qfConflictStep1.
  ///
  /// In en, this message translates to:
  /// **'Go back to the login screen'**
  String get qfConflictStep1;

  /// No description provided for @qfConflictStep2.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email or Google using\n{email}'**
  String qfConflictStep2(String email);

  /// No description provided for @qfConflictStep3.
  ///
  /// In en, this message translates to:
  /// **'All your progress will be right there'**
  String get qfConflictStep3;

  /// No description provided for @qfConflictBackButton.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get qfConflictBackButton;

  /// No description provided for @sponsorAnOrphan.
  ///
  /// In en, this message translates to:
  /// **'Sponsor an Orphan'**
  String get sponsorAnOrphan;

  /// No description provided for @noOrphansListed.
  ///
  /// In en, this message translates to:
  /// **'No orphans listed yet'**
  String get noOrphansListed;

  /// No description provided for @checkBackForOrphans.
  ///
  /// In en, this message translates to:
  /// **'Check back soon, new sponsorship opportunities are added regularly.'**
  String get checkBackForOrphans;

  /// No description provided for @orphanVerseTranslation.
  ///
  /// In en, this message translates to:
  /// **'\"And as for the orphan, do not oppress him.\", Qur\'an 93:9'**
  String get orphanVerseTranslation;

  /// No description provided for @orphanCardOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get orphanCardOpen;

  /// No description provided for @doneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneLabel;

  /// No description provided for @aReminderLabel.
  ///
  /// In en, this message translates to:
  /// **'A REMINDER'**
  String get aReminderLabel;

  /// No description provided for @yourAkhirahBalance.
  ///
  /// In en, this message translates to:
  /// **'YOUR AKHIRAH BALANCE'**
  String get yourAkhirahBalance;

  /// No description provided for @seedsCollectedSinceJoined.
  ///
  /// In en, this message translates to:
  /// **'Seeds collected since you joined'**
  String get seedsCollectedSinceJoined;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get todayLabel;

  /// No description provided for @azkaarPerDay.
  ///
  /// In en, this message translates to:
  /// **'azkaar per day'**
  String get azkaarPerDay;

  /// No description provided for @viewFullStats.
  ///
  /// In en, this message translates to:
  /// **'View full stats'**
  String get viewFullStats;

  /// No description provided for @fatherLabel.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get fatherLabel;

  /// No description provided for @motherLabel.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get motherLabel;

  /// No description provided for @siblingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Siblings'**
  String get siblingsLabel;

  /// No description provided for @familySection.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familySection;

  /// No description provided for @educationSection.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get educationSection;

  /// No description provided for @gradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get gradeLabel;

  /// No description provided for @schoolLabel.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get schoolLabel;

  /// No description provided for @theirStorySection.
  ///
  /// In en, this message translates to:
  /// **'Their story'**
  String get theirStorySection;

  /// No description provided for @yourBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Your balance:'**
  String get yourBalanceLabel;

  /// No description provided for @sponsorCta.
  ///
  /// In en, this message translates to:
  /// **'Sponsor {name}'**
  String sponsorCta(String name);

  /// No description provided for @notEnoughSeeds.
  ///
  /// In en, this message translates to:
  /// **'Not enough Seeds'**
  String get notEnoughSeeds;

  /// No description provided for @bookmarkSyncDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran.com Bookmark Sync'**
  String get bookmarkSyncDialogTitle;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get searchHint;

  /// No description provided for @enterCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter code…'**
  String get enterCodeHint;

  /// No description provided for @searchSurahHint.
  ///
  /// In en, this message translates to:
  /// **'Search Surah...'**
  String get searchSurahHint;

  /// No description provided for @customLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customLabel;

  /// No description provided for @seedsSuffix.
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get seedsSuffix;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @retryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLabel;

  /// No description provided for @authErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Auth Error'**
  String get authErrorTitle;

  /// No description provided for @sealWithinHours.
  ///
  /// In en, this message translates to:
  /// **'Seal within {hours}h'**
  String sealWithinHours(int hours);

  /// No description provided for @sealWithinMinutes.
  ///
  /// In en, this message translates to:
  /// **'Seal within {minutes}m'**
  String sealWithinMinutes(int minutes);

  /// No description provided for @sealNow.
  ///
  /// In en, this message translates to:
  /// **'Seal now'**
  String get sealNow;

  /// No description provided for @goalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalLabel;

  /// No description provided for @contributorCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 contributor} other{{count} contributors}}'**
  String contributorCount(int count);

  /// No description provided for @dayStreakCount.
  ///
  /// In en, this message translates to:
  /// **'{streak} Day Streak 🔥'**
  String dayStreakCount(int streak);

  /// No description provided for @seedsPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Seed pending} other{{count} Seeds pending}}'**
  String seedsPendingCount(int count);

  /// No description provided for @sealToSave.
  ///
  /// In en, this message translates to:
  /// **'Seal to save'**
  String get sealToSave;

  /// No description provided for @top10Contributors.
  ///
  /// In en, this message translates to:
  /// **'Top 10 Contributors'**
  String get top10Contributors;

  /// No description provided for @copyLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyLabel;

  /// No description provided for @copiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copiedLabel;

  /// No description provided for @whatsappLabel.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsappLabel;

  /// No description provided for @youBothEarnSeeds.
  ///
  /// In en, this message translates to:
  /// **'You both earn 500 Sabiq Seeds!'**
  String get youBothEarnSeeds;

  /// No description provided for @jazakAllahPlusSeeds.
  ///
  /// In en, this message translates to:
  /// **'JazakAllah!  +{seeds} Seeds'**
  String jazakAllahPlusSeeds(int seeds);

  /// No description provided for @jazakAllahDaySealed.
  ///
  /// In en, this message translates to:
  /// **'JazakAllah!  Day sealed'**
  String get jazakAllahDaySealed;

  /// No description provided for @pointsGoals.
  ///
  /// In en, this message translates to:
  /// **'POINTS GOALS'**
  String get pointsGoals;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLabel;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get dailyGoal;

  /// No description provided for @weeklyGoal.
  ///
  /// In en, this message translates to:
  /// **'Weekly Goal'**
  String get weeklyGoal;

  /// No description provided for @monthlyGoal.
  ///
  /// In en, this message translates to:
  /// **'Monthly Goal'**
  String get monthlyGoal;

  /// No description provided for @setTargetSeeds.
  ///
  /// In en, this message translates to:
  /// **'Set your target Seeds (default: {defaultVal})'**
  String setTargetSeeds(int defaultVal);

  /// No description provided for @noInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetTitle;

  /// No description provided for @connectingTitle.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connectingTitle;

  /// No description provided for @somethingWentWrongTitle.
  ///
  /// In en, this message translates to:
  /// **'Something Went Wrong'**
  String get somethingWentWrongTitle;

  /// No description provided for @noInternetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This feature needs internet.\nCheck your Wi-Fi or mobile data.'**
  String get noInternetSubtitle;

  /// No description provided for @connectingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fetching your data…\nHanging on for a moment'**
  String get connectingSubtitle;

  /// No description provided for @errorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.\nTap retry to try again.'**
  String get errorSubtitle;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @everyRecitationCanChangeLife.
  ///
  /// In en, this message translates to:
  /// **'Every Recitation Can\nChange a Life'**
  String get everyRecitationCanChangeLife;

  /// No description provided for @givenLabel.
  ///
  /// In en, this message translates to:
  /// **'GIVEN'**
  String get givenLabel;

  /// No description provided for @goalUpper.
  ///
  /// In en, this message translates to:
  /// **'GOAL'**
  String get goalUpper;

  /// No description provided for @aboutThisCause.
  ///
  /// In en, this message translates to:
  /// **'About this Cause'**
  String get aboutThisCause;

  /// No description provided for @myContributionSeeds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{My contribution: 1 Seed} other{My contribution: {count} Seeds}}'**
  String myContributionSeeds(int count);

  /// No description provided for @jazakAllahKhayranDonated.
  ///
  /// In en, this message translates to:
  /// **'{amount, plural, =1{JazakAllah Khayran! 1 Seed donated.} other{JazakAllah Khayran! {amount} Seeds donated.}}'**
  String jazakAllahKhayranDonated(int amount);

  /// No description provided for @coinsSealedTitle.
  ///
  /// In en, this message translates to:
  /// **'Coins Sealed! ماشاء الله'**
  String get coinsSealedTitle;

  /// No description provided for @seedsSealedSafe.
  ///
  /// In en, this message translates to:
  /// **'Your Seeds are sealed and safe\nfor the Akhirah.'**
  String get seedsSealedSafe;

  /// No description provided for @validationSeedsLabel.
  ///
  /// In en, this message translates to:
  /// **'Validation Seeds'**
  String get validationSeedsLabel;

  /// No description provided for @streakBonusLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak Bonus'**
  String get streakBonusLabel;

  /// No description provided for @totalEarnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Earned'**
  String get totalEarnedLabel;

  /// No description provided for @alhamdulillahCta.
  ///
  /// In en, this message translates to:
  /// **'Alhamdulillah! 🤲'**
  String get alhamdulillahCta;

  /// No description provided for @openQuranCta.
  ///
  /// In en, this message translates to:
  /// **'Open Quran'**
  String get openQuranCta;

  /// No description provided for @duaAzkaarCta.
  ///
  /// In en, this message translates to:
  /// **'Dua & Azkaar'**
  String get duaAzkaarCta;

  /// No description provided for @shareWithFriendsCta.
  ///
  /// In en, this message translates to:
  /// **'Share with Friends'**
  String get shareWithFriendsCta;

  /// No description provided for @earnMoreSeedsCta.
  ///
  /// In en, this message translates to:
  /// **'Earn More Seeds'**
  String get earnMoreSeedsCta;

  /// No description provided for @levelTitleFormat.
  ///
  /// In en, this message translates to:
  /// **'Lvl {level} · {title}'**
  String levelTitleFormat(int level, String title);

  /// No description provided for @akhirahBalanceUpper.
  ///
  /// In en, this message translates to:
  /// **'AKHIRAH BALANCE'**
  String get akhirahBalanceUpper;

  /// No description provided for @bestDayStreakBadge.
  ///
  /// In en, this message translates to:
  /// **'Best: {streak} day streak'**
  String bestDayStreakBadge(int streak);

  /// No description provided for @deedsLabel.
  ///
  /// In en, this message translates to:
  /// **'DEEDS'**
  String get deedsLabel;

  /// No description provided for @treesLabel.
  ///
  /// In en, this message translates to:
  /// **'TREES'**
  String get treesLabel;

  /// No description provided for @forgivenLabel.
  ///
  /// In en, this message translates to:
  /// **'FORGIVEN'**
  String get forgivenLabel;

  /// No description provided for @navCause.
  ///
  /// In en, this message translates to:
  /// **'Cause'**
  String get navCause;

  /// No description provided for @realChildrenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real children, their stories, their lives'**
  String get realChildrenSubtitle;

  /// No description provided for @seeAllAction.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAllAction;

  /// No description provided for @activeCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Active Campaigns'**
  String get activeCampaigns;

  /// No description provided for @poolSeedsImpact.
  ///
  /// In en, this message translates to:
  /// **'Pool your Seeds toward lasting impact'**
  String get poolSeedsImpact;

  /// No description provided for @featuredSponsorChild.
  ///
  /// In en, this message translates to:
  /// **'Featured · Sponsor a child'**
  String get featuredSponsorChild;

  /// No description provided for @meetOrphanAge.
  ///
  /// In en, this message translates to:
  /// **'Meet {name}, {age}'**
  String meetOrphanAge(String name, int age);

  /// No description provided for @sponsorNameArrow.
  ///
  /// In en, this message translates to:
  /// **'Sponsor {name} →'**
  String sponsorNameArrow(String name);

  /// No description provided for @featuredCampaign.
  ///
  /// In en, this message translates to:
  /// **'Featured Campaign'**
  String get featuredCampaign;

  /// No description provided for @yourGiving.
  ///
  /// In en, this message translates to:
  /// **'Your Giving'**
  String get yourGiving;

  /// No description provided for @havenNotGivenYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t given yet. Pick someone above to begin your journey of impact.'**
  String get havenNotGivenYet;

  /// No description provided for @seedsDonatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Seeds donated'**
  String get seedsDonatedLabel;

  /// No description provided for @orphanCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Orphan} other{Orphans}}'**
  String orphanCount(int count);

  /// No description provided for @projectCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Project} other{Projects}}'**
  String projectCount(int count);

  /// No description provided for @couldntLoadJourney.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your Journey'**
  String get couldntLoadJourney;

  /// No description provided for @checkConnectionRetry.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkConnectionRetry;

  /// No description provided for @actionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 action} other{{count} actions}}'**
  String actionsCount(int count);

  /// No description provided for @showLessAction.
  ///
  /// In en, this message translates to:
  /// **'Show Less ←'**
  String get showLessAction;

  /// No description provided for @hadithReference.
  ///
  /// In en, this message translates to:
  /// **'Hadith Reference'**
  String get hadithReference;

  /// No description provided for @howYouEarnedThis.
  ///
  /// In en, this message translates to:
  /// **'How you earned this'**
  String get howYouEarnedThis;

  /// No description provided for @seedsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Seed} other{{count} Seeds}}'**
  String seedsCount(int count);

  /// No description provided for @seedsUnit.
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get seedsUnit;

  /// No description provided for @topContribByLifetimeSeeds.
  ///
  /// In en, this message translates to:
  /// **'Top contributors by lifetime Seeds'**
  String get topContribByLifetimeSeeds;

  /// No description provided for @romanisedPronunciation.
  ///
  /// In en, this message translates to:
  /// **'Romanised pronunciation under each word'**
  String get romanisedPronunciation;

  /// No description provided for @displayLabel.
  ///
  /// In en, this message translates to:
  /// **'DISPLAY'**
  String get displayLabel;

  /// No description provided for @arabicLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabicLanguageLabel;

  /// No description provided for @urduLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get urduLanguageLabel;

  /// No description provided for @englishLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguageLabel;

  /// No description provided for @earnPerVerseRead.
  ///
  /// In en, this message translates to:
  /// **'Earn +10 Sabiq Seeds per verse read'**
  String get earnPerVerseRead;

  /// No description provided for @surahPickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get surahPickerLabel;

  /// No description provided for @versesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 verse} other{{count} verses}}'**
  String versesCount(int count);

  /// No description provided for @startFromVerse.
  ///
  /// In en, this message translates to:
  /// **'Start from Verse'**
  String get startFromVerse;

  /// No description provided for @verseN.
  ///
  /// In en, this message translates to:
  /// **'Verse {n}'**
  String verseN(int n);

  /// No description provided for @ofN.
  ///
  /// In en, this message translates to:
  /// **'of {n}'**
  String ofN(int n);

  /// No description provided for @surahHasNVerses.
  ///
  /// In en, this message translates to:
  /// **'{name} has {count} verses'**
  String surahHasNVerses(String name, int count);

  /// No description provided for @noXYet.
  ///
  /// In en, this message translates to:
  /// **'No {label} yet'**
  String noXYet(String label);

  /// No description provided for @tapHeartToSave.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart/bookmark icon while reading to save verses.'**
  String get tapHeartToSave;

  /// No description provided for @surahVerseRow.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah}  •  Verse {ayah}'**
  String surahVerseRow(int surah, int ayah);

  /// No description provided for @hasanatFromQuran.
  ///
  /// In en, this message translates to:
  /// **'Hasanat from Quran'**
  String get hasanatFromQuran;

  /// No description provided for @tenPerLetterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'10 per letter, {count} per ayah'**
  String tenPerLetterSubtitle(int count);

  /// No description provided for @fromSubhanAllahTasbih.
  ///
  /// In en, this message translates to:
  /// **'From SubhanAllah & Tasbih'**
  String get fromSubhanAllahTasbih;

  /// No description provided for @likeFoamOfSea.
  ///
  /// In en, this message translates to:
  /// **'Like the foam of the sea'**
  String get likeFoamOfSea;

  /// No description provided for @fromSurahIkhlasRecitation.
  ///
  /// In en, this message translates to:
  /// **'From Surah Ikhlas recitation'**
  String get fromSurahIkhlasRecitation;

  /// No description provided for @laHawlaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'La Hawla Wa La Quwwata'**
  String get laHawlaSubtitle;

  /// No description provided for @equivalentRewardEarned.
  ///
  /// In en, this message translates to:
  /// **'Equivalent reward earned'**
  String get equivalentRewardEarned;

  /// No description provided for @gatesOfParadise.
  ///
  /// In en, this message translates to:
  /// **'Gates of Paradise'**
  String get gatesOfParadise;

  /// No description provided for @afterPerfectWudu.
  ///
  /// In en, this message translates to:
  /// **'After perfect wudu'**
  String get afterPerfectWudu;

  /// No description provided for @blessingsFromAllah.
  ///
  /// In en, this message translates to:
  /// **'Blessings from Allah'**
  String get blessingsFromAllah;

  /// No description provided for @salawatTenReturned.
  ///
  /// In en, this message translates to:
  /// **'Salawat × 10 returned'**
  String get salawatTenReturned;

  /// No description provided for @timesProtected.
  ///
  /// In en, this message translates to:
  /// **'Times Protected'**
  String get timesProtected;

  /// No description provided for @refugeInvokedFromHarm.
  ///
  /// In en, this message translates to:
  /// **'Refuge invoked from harm'**
  String get refugeInvokedFromHarm;

  /// No description provided for @quranCompletions.
  ///
  /// In en, this message translates to:
  /// **'Quran Completions'**
  String get quranCompletions;

  /// No description provided for @viaSurahIkhlas.
  ///
  /// In en, this message translates to:
  /// **'Via Surah Al-Ikhlas ×3'**
  String get viaSurahIkhlas;

  /// No description provided for @bonusHasanaat.
  ///
  /// In en, this message translates to:
  /// **'Bonus Hasanaat'**
  String get bonusHasanaat;

  /// No description provided for @marketplaceDua.
  ///
  /// In en, this message translates to:
  /// **'Marketplace du\'a'**
  String get marketplaceDua;

  /// No description provided for @seedsDonatedToCommunity.
  ///
  /// In en, this message translates to:
  /// **'Seeds donated to community'**
  String get seedsDonatedToCommunity;

  /// No description provided for @yourMonth.
  ///
  /// In en, this message translates to:
  /// **'Your Month'**
  String get yourMonth;

  /// No description provided for @ayahsReadLabel.
  ///
  /// In en, this message translates to:
  /// **'Ayahs Read'**
  String get ayahsReadLabel;

  /// No description provided for @dhikrCount.
  ///
  /// In en, this message translates to:
  /// **'Dhikr Count'**
  String get dhikrCount;

  /// No description provided for @quranTime.
  ///
  /// In en, this message translates to:
  /// **'Quran Time'**
  String get quranTime;

  /// No description provided for @dhikrTime.
  ///
  /// In en, this message translates to:
  /// **'Dhikr Time'**
  String get dhikrTime;

  /// No description provided for @activeDays.
  ///
  /// In en, this message translates to:
  /// **'Active Days'**
  String get activeDays;

  /// No description provided for @treesShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Trees'**
  String get treesShortLabel;

  /// No description provided for @palacesShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Palaces'**
  String get palacesShortLabel;

  /// No description provided for @freedShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Freed'**
  String get freedShortLabel;

  /// No description provided for @blessingsShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Blessings'**
  String get blessingsShortLabel;

  /// No description provided for @dailyWordPrefix.
  ///
  /// In en, this message translates to:
  /// **'Daily '**
  String get dailyWordPrefix;

  /// No description provided for @essentialsWord.
  ///
  /// In en, this message translates to:
  /// **'Essentials'**
  String get essentialsWord;

  /// No description provided for @seedsExpiringNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Seeds expiring at midnight!'**
  String get seedsExpiringNotificationTitle;

  /// No description provided for @seedsExpiringNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'You have {pending} Seeds pending. Seal the Day now or they expire!'**
  String seedsExpiringNotificationBody(int pending);

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpTitle;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInTitle;

  /// No description provided for @emailFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailFieldLabel;

  /// No description provided for @passwordFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordFieldLabel;

  /// No description provided for @enterEmailValidator.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterEmailValidator;

  /// No description provided for @enterPasswordValidator.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPasswordValidator;

  /// No description provided for @passwordTooShortValidator.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShortValidator;

  /// No description provided for @signUpSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign up successful! Please check your email for confirmation.'**
  String get signUpSuccessMessage;

  /// No description provided for @unexpectedAuthError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedAuthError;

  /// No description provided for @sawabLabel.
  ///
  /// In en, this message translates to:
  /// **'Sawab'**
  String get sawabLabel;

  /// No description provided for @impactLabel.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get impactLabel;

  /// No description provided for @goodDeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Good Deed'**
  String get goodDeedTitle;

  /// No description provided for @goodDeedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Earn Sawab\nwith every read'**
  String get goodDeedSubtitle;

  /// No description provided for @realImpactTitle.
  ///
  /// In en, this message translates to:
  /// **'Real Impact'**
  String get realImpactTitle;

  /// No description provided for @realImpactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Coins fund\nnoble causes'**
  String get realImpactSubtitle;

  /// No description provided for @plusDeedsTodayBadge.
  ///
  /// In en, this message translates to:
  /// **'+{count} deeds today'**
  String plusDeedsTodayBadge(String count);

  /// No description provided for @equivalentChange.
  ///
  /// In en, this message translates to:
  /// **'{count} equivalent'**
  String equivalentChange(String count);

  /// No description provided for @receivedChange.
  ///
  /// In en, this message translates to:
  /// **'{count} received'**
  String receivedChange(String count);

  /// No description provided for @readAyahsPlusTimeToday.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Read 1 ayah plus {time} reading Quran today} other{Read {count} ayahs plus {time} reading Quran today}}'**
  String readAyahsPlusTimeToday(int count, String time);

  /// No description provided for @readAyahsToday.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Read 1 ayah today} other{Read {count} ayahs today}}'**
  String readAyahsToday(int count);

  /// No description provided for @spentTimeReadingQuranToday.
  ///
  /// In en, this message translates to:
  /// **'Spent {time} reading Quran today'**
  String spentTimeReadingQuranToday(String time);

  /// No description provided for @everyDeedRecordedKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'🌙  Every deed is recorded. Keep going!'**
  String get everyDeedRecordedKeepGoing;

  /// No description provided for @viewAllDonors.
  ///
  /// In en, this message translates to:
  /// **'View all {count} donors'**
  String viewAllDonors(int count);

  /// No description provided for @nextMilestoneInfo.
  ///
  /// In en, this message translates to:
  /// **'Next: {label} ({days} days)'**
  String nextMilestoneInfo(String label, int days);

  /// No description provided for @bestN.
  ///
  /// In en, this message translates to:
  /// **'Best {n}'**
  String bestN(int n);

  /// No description provided for @streakMilestoneWarmingUp.
  ///
  /// In en, this message translates to:
  /// **'Warming Up'**
  String get streakMilestoneWarmingUp;

  /// No description provided for @streakMilestoneOneWeek.
  ///
  /// In en, this message translates to:
  /// **'One Week'**
  String get streakMilestoneOneWeek;

  /// No description provided for @streakMilestoneTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'Two Weeks'**
  String get streakMilestoneTwoWeeks;

  /// No description provided for @streakMilestoneOneMonth.
  ///
  /// In en, this message translates to:
  /// **'One Month'**
  String get streakMilestoneOneMonth;

  /// No description provided for @streakMilestoneTwoMonths.
  ///
  /// In en, this message translates to:
  /// **'Two Months'**
  String get streakMilestoneTwoMonths;

  /// No description provided for @streakMilestoneCenturion.
  ///
  /// In en, this message translates to:
  /// **'The Centurion'**
  String get streakMilestoneCenturion;

  /// No description provided for @firstTrackedWeek.
  ///
  /// In en, this message translates to:
  /// **'Your first tracked week — keep going!'**
  String get firstTrackedWeek;

  /// No description provided for @rightOnSevenDayPace.
  ///
  /// In en, this message translates to:
  /// **'Right on your 7-day pace'**
  String get rightOnSevenDayPace;

  /// No description provided for @aboveSevenDayAvg.
  ///
  /// In en, this message translates to:
  /// **'{pct}% above your 7-day average'**
  String aboveSevenDayAvg(int pct);

  /// No description provided for @belowSevenDayAvg.
  ///
  /// In en, this message translates to:
  /// **'{pct}% below your 7-day average'**
  String belowSevenDayAvg(int pct);

  /// No description provided for @sponsoredBy.
  ///
  /// In en, this message translates to:
  /// **'Sponsored by'**
  String get sponsoredBy;

  /// No description provided for @currentOverDays.
  ///
  /// In en, this message translates to:
  /// **'{current} / {days} days'**
  String currentOverDays(int current, int days);

  /// No description provided for @daysWord.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String daysWord(int count);

  /// No description provided for @dayAbbrMon.
  ///
  /// In en, this message translates to:
  /// **'Mo'**
  String get dayAbbrMon;

  /// No description provided for @dayAbbrTue.
  ///
  /// In en, this message translates to:
  /// **'Tu'**
  String get dayAbbrTue;

  /// No description provided for @dayAbbrWed.
  ///
  /// In en, this message translates to:
  /// **'We'**
  String get dayAbbrWed;

  /// No description provided for @dayAbbrThu.
  ///
  /// In en, this message translates to:
  /// **'Th'**
  String get dayAbbrThu;

  /// No description provided for @dayAbbrFri.
  ///
  /// In en, this message translates to:
  /// **'Fr'**
  String get dayAbbrFri;

  /// No description provided for @dayAbbrSat.
  ///
  /// In en, this message translates to:
  /// **'Sa'**
  String get dayAbbrSat;

  /// No description provided for @dayAbbrSun.
  ///
  /// In en, this message translates to:
  /// **'Su'**
  String get dayAbbrSun;

  /// No description provided for @favoritesCategory.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesCategory;

  /// No description provided for @sleepingCategory.
  ///
  /// In en, this message translates to:
  /// **'Sleeping'**
  String get sleepingCategory;

  /// No description provided for @dailyWord.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyWord;

  /// No description provided for @dailyDuasCategory.
  ///
  /// In en, this message translates to:
  /// **'Daily Duas'**
  String get dailyDuasCategory;

  /// No description provided for @ruquiyaCategory.
  ///
  /// In en, this message translates to:
  /// **'Ruqya'**
  String get ruquiyaCategory;

  /// No description provided for @duasBeforeSleep.
  ///
  /// In en, this message translates to:
  /// **'Duas before Sleep'**
  String get duasBeforeSleep;

  /// No description provided for @duasAfterSalah.
  ///
  /// In en, this message translates to:
  /// **'Duas after Salah'**
  String get duasAfterSalah;

  /// No description provided for @rabbana40Duas.
  ///
  /// In en, this message translates to:
  /// **'40 Rabbana Duas'**
  String get rabbana40Duas;

  /// No description provided for @thisWorld.
  ///
  /// In en, this message translates to:
  /// **'This World'**
  String get thisWorld;

  /// No description provided for @dunyaArabic.
  ///
  /// In en, this message translates to:
  /// **'Dunya'**
  String get dunyaArabic;

  /// No description provided for @hereafter.
  ///
  /// In en, this message translates to:
  /// **'Hereafter'**
  String get hereafter;

  /// No description provided for @akhirahArabic.
  ///
  /// In en, this message translates to:
  /// **'Akhirah'**
  String get akhirahArabic;

  /// No description provided for @bookOfCompletePrayer.
  ///
  /// In en, this message translates to:
  /// **'The Book of Complete Prayer'**
  String get bookOfCompletePrayer;

  /// No description provided for @propheticDuas.
  ///
  /// In en, this message translates to:
  /// **'Prophetic Supplications'**
  String get propheticDuas;

  /// No description provided for @morningEveningRemembrance.
  ///
  /// In en, this message translates to:
  /// **'Morning & Evening Remembrance'**
  String get morningEveningRemembrance;

  /// No description provided for @furtherDuas.
  ///
  /// In en, this message translates to:
  /// **'Further Supplications'**
  String get furtherDuas;

  /// No description provided for @closingSalawat.
  ///
  /// In en, this message translates to:
  /// **'Closing Remembrance & Salawat'**
  String get closingSalawat;

  /// No description provided for @hajjAndUmrahCategory.
  ///
  /// In en, this message translates to:
  /// **'Hajj & Umrah Supplications'**
  String get hajjAndUmrahCategory;

  /// No description provided for @azkarSingular.
  ///
  /// In en, this message translates to:
  /// **'azkar'**
  String get azkarSingular;

  /// No description provided for @azkarPlural.
  ///
  /// In en, this message translates to:
  /// **'azkaar'**
  String get azkarPlural;

  /// No description provided for @hourSingular.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hourSingular;

  /// No description provided for @hourPlural.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hourPlural;

  /// No description provided for @minuteSingular.
  ///
  /// In en, this message translates to:
  /// **'minute'**
  String get minuteSingular;

  /// No description provided for @minutePlural.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutePlural;

  /// No description provided for @secondSingular.
  ///
  /// In en, this message translates to:
  /// **'second'**
  String get secondSingular;

  /// No description provided for @secondPlural.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get secondPlural;

  /// No description provided for @seedsThisSession.
  ///
  /// In en, this message translates to:
  /// **'+{count} seeds this session'**
  String seedsThisSession(String count);

  /// No description provided for @sevenDayAvgAzkaar.
  ///
  /// In en, this message translates to:
  /// **'7-day avg: {count} azkaar/day'**
  String sevenDayAvgAzkaar(String count);

  /// No description provided for @holdingChangeAyahs.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs'**
  String holdingChangeAyahs(String count);

  /// No description provided for @holdingChangePlanted.
  ///
  /// In en, this message translates to:
  /// **'{count} planted'**
  String holdingChangePlanted(String count);

  /// No description provided for @holdingChangeCycles.
  ///
  /// In en, this message translates to:
  /// **'{count} cycles'**
  String holdingChangeCycles(String count);

  /// No description provided for @holdingChangeBuilt.
  ///
  /// In en, this message translates to:
  /// **'{count} built'**
  String holdingChangeBuilt(String count);

  /// No description provided for @holdingChangeEarned.
  ///
  /// In en, this message translates to:
  /// **'{count} earned'**
  String holdingChangeEarned(String count);

  /// No description provided for @holdingChangeOpened.
  ///
  /// In en, this message translates to:
  /// **'{count} opened'**
  String holdingChangeOpened(String count);

  /// No description provided for @holdingChangeInvocations.
  ///
  /// In en, this message translates to:
  /// **'{count} invocations'**
  String holdingChangeInvocations(String count);

  /// No description provided for @holdingChangeRecitations.
  ///
  /// In en, this message translates to:
  /// **'{count} recitations'**
  String holdingChangeRecitations(String count);

  /// No description provided for @bookmarksOnQuranCom.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks on Quran.com:  {count}'**
  String bookmarksOnQuranCom(String count);

  /// No description provided for @bookmarksInThisApp.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks in this app:   {count}'**
  String bookmarksInThisApp(String count);

  /// No description provided for @streakSeedsBonus.
  ///
  /// In en, this message translates to:
  /// **'+{count} Seeds'**
  String streakSeedsBonus(String count);

  /// No description provided for @plusSeedsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'+{count} this week'**
  String plusSeedsThisWeek(String count);

  /// No description provided for @unitDuas.
  ///
  /// In en, this message translates to:
  /// **'{count} duas'**
  String unitDuas(String count);

  /// No description provided for @unitAdhkar.
  ///
  /// In en, this message translates to:
  /// **'{count} adhkar'**
  String unitAdhkar(String count);

  /// No description provided for @moreCollections.
  ///
  /// In en, this message translates to:
  /// **'More Collections'**
  String get moreCollections;

  /// No description provided for @donateAndEarnReward.
  ///
  /// In en, this message translates to:
  /// **'Donate & Earn Reward'**
  String get donateAndEarnReward;

  /// No description provided for @donateAmountSeeds.
  ///
  /// In en, this message translates to:
  /// **'Donate {amount} Seeds'**
  String donateAmountSeeds(String amount);

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @beFirstToContribute.
  ///
  /// In en, this message translates to:
  /// **'Be the first to contribute.'**
  String get beFirstToContribute;

  /// No description provided for @showFewer.
  ///
  /// In en, this message translates to:
  /// **'Show fewer ↑'**
  String get showFewer;

  /// No description provided for @viewAllN.
  ///
  /// In en, this message translates to:
  /// **'View all {n} →'**
  String viewAllN(String n);

  /// No description provided for @liveReadersNow.
  ///
  /// In en, this message translates to:
  /// **'{count} online now'**
  String liveReadersNow(String count);

  /// No description provided for @communityReadingToday.
  ///
  /// In en, this message translates to:
  /// **'{count} read today (community)'**
  String communityReadingToday(String count);

  /// No description provided for @communityHasanatToday.
  ///
  /// In en, this message translates to:
  /// **'+{count} community hasanat today'**
  String communityHasanatToday(String count);

  /// No description provided for @peopleReadingNow.
  ///
  /// In en, this message translates to:
  /// **'reading right now'**
  String get peopleReadingNow;

  /// No description provided for @readToday.
  ///
  /// In en, this message translates to:
  /// **'read today'**
  String get readToday;

  /// No description provided for @communityHasanat.
  ///
  /// In en, this message translates to:
  /// **'community hasanat'**
  String get communityHasanat;

  /// No description provided for @authScreen_pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get authScreen_pleaseEnterYourEmail;

  /// No description provided for @authScreen_pleaseEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get authScreen_pleaseEnterYourPassword;

  /// No description provided for @authScreen_passwordMustBeAt.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authScreen_passwordMustBeAt;

  /// No description provided for @authScreen_alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get authScreen_alreadyHaveAnAccount;

  /// No description provided for @authScreen_haveAnAccountSign.
  ///
  /// In en, this message translates to:
  /// **'t have an account? Sign Up'**
  String get authScreen_haveAnAccountSign;

  /// No description provided for @qfAuthService_qfemailconflictexceptionAlreadyHasAn.
  ///
  /// In en, this message translates to:
  /// **'QfEmailConflictException: {email} already has an account'**
  String qfAuthService_qfemailconflictexceptionAlreadyHasAn(String email);

  /// No description provided for @qfAuthService_openidOfflineAccessUser.
  ///
  /// In en, this message translates to:
  /// **'openid offline_access user bookmark collection reading_session'**
  String get qfAuthService_openidOfflineAccessUser;

  /// No description provided for @qfAuthService_tokenExchangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Token exchange failed ({arg1}): {arg2}'**
  String qfAuthService_tokenExchangeFailed(String arg1, String arg2);

  /// No description provided for @qfAuthService_errorNullResponse.
  ///
  /// In en, this message translates to:
  /// **'ERROR: Null response'**
  String get qfAuthService_errorNullResponse;

  /// No description provided for @orphan_be2bf7.
  ///
  /// In en, this message translates to:
  /// **'{firstName} {lastInitial}.'**
  String orphan_be2bf7(String firstName, String lastInitial);

  /// No description provided for @akhirahBalanceScreen_subhanallahiWaBiHamdihi.
  ///
  /// In en, this message translates to:
  /// **'“Subhanallahi wa bi-hamdihi” — said 100 times a day wipes sins, even like the foam of the sea. (Bukhari)'**
  String get akhirahBalanceScreen_subhanallahiWaBiHamdihi;

  /// No description provided for @akhirahBalanceScreen_sayLaIlahaIllallah.
  ///
  /// In en, this message translates to:
  /// **'Say La ilaha illallah 100 times — equals freeing 10 slaves and 100 hasanat. (Bukhari)'**
  String get akhirahBalanceScreen_sayLaIlahaIllallah;

  /// No description provided for @akhirahBalanceScreen_lightOnTheTongue.
  ///
  /// In en, this message translates to:
  /// **'Light on the tongue, heavy on the scales: Subhanallahi wa bi-hamdihi, Subhanallahil-azim. (Bukhari 6406)'**
  String get akhirahBalanceScreen_lightOnTheTongue;

  /// No description provided for @akhirahBalanceScreen_theDhikrOfAllah.
  ///
  /// In en, this message translates to:
  /// **'The dhikr of Allah is heavier on the scales than gold of equal weight. Keep going.'**
  String get akhirahBalanceScreen_theDhikrOfAllah;

  /// No description provided for @akhirahBalanceScreen_yourTongueShouldStay.
  ///
  /// In en, this message translates to:
  /// **'“Your tongue should stay moist with the remembrance of Allah.” — Is it still moist?'**
  String get akhirahBalanceScreen_yourTongueShouldStay;

  /// No description provided for @akhirahBalanceScreen_astaghfirullahTheProphetSaid.
  ///
  /// In en, this message translates to:
  /// **'Astaghfirullah — the Prophet ✍ said it 100 times a day, and he had no sin. How many have you?'**
  String get akhirahBalanceScreen_astaghfirullahTheProphetSaid;

  /// No description provided for @akhirahBalanceScreen_whenYouRememberAllah.
  ///
  /// In en, this message translates to:
  /// **'When you remember Allah quietly, He remembers you in an assembly far greater.'**
  String get akhirahBalanceScreen_whenYouRememberAllah;

  /// No description provided for @akhirahBalanceScreen_reciteAyatAlKursi.
  ///
  /// In en, this message translates to:
  /// **'Recite Ayat al-Kursi after every salah — nothing keeps you from Jannah but death.'**
  String get akhirahBalanceScreen_reciteAyatAlKursi;

  /// No description provided for @akhirahBalanceScreen_oneAlhamdulillahFillsThe.
  ///
  /// In en, this message translates to:
  /// **'One Alhamdulillah fills the scale. One Subhanallah fills what is between heaven and earth.'**
  String get akhirahBalanceScreen_oneAlhamdulillahFillsThe;

  /// No description provided for @akhirahBalanceScreen_theRemembranceOfAllah.
  ///
  /// In en, this message translates to:
  /// **'“The remembrance of Allah is greater than everything else.” — Surah Al-Ankabut 29:45'**
  String get akhirahBalanceScreen_theRemembranceOfAllah;

  /// No description provided for @akhirahBalanceScreen_rememberMeWillRemember.
  ///
  /// In en, this message translates to:
  /// **'“Remember Me — I will remember you.” — Surah Al-Baqarah 2:152. Will you?'**
  String get akhirahBalanceScreen_rememberMeWillRemember;

  /// No description provided for @akhirahBalanceScreen_inTheRemembranceOf.
  ///
  /// In en, this message translates to:
  /// **'“In the remembrance of Allah, hearts find rest.” — Surah Ar-Ra’d 13:28'**
  String get akhirahBalanceScreen_inTheRemembranceOf;

  /// No description provided for @akhirahBalanceScreen_fiveMinutesOfDhikr.
  ///
  /// In en, this message translates to:
  /// **'Five minutes of dhikr now shapes the next 24 hours of your heart.'**
  String get akhirahBalanceScreen_fiveMinutesOfDhikr;

  /// No description provided for @akhirahBalanceScreen_streakIsnAboutToday.
  ///
  /// In en, this message translates to:
  /// **'A streak isn’t about today — it’s about who you become in 30 days.'**
  String get akhirahBalanceScreen_streakIsnAboutToday;

  /// No description provided for @akhirahBalanceScreen_smallDropsFillAn.
  ///
  /// In en, this message translates to:
  /// **'Small drops fill an ocean. Your daily dhikr is filling something far bigger.'**
  String get akhirahBalanceScreen_smallDropsFillAn;

  /// No description provided for @akhirahBalanceScreen_noOneSeesThe.
  ///
  /// In en, this message translates to:
  /// **'No one sees the dhikr in your heart — but every angel writing your record does.'**
  String get akhirahBalanceScreen_noOneSeesThe;

  /// No description provided for @akhirahBalanceScreen_theBiggestWinsAre.
  ///
  /// In en, this message translates to:
  /// **'The biggest wins are built from the smallest daily habits. Don’t break the chain.'**
  String get akhirahBalanceScreen_theBiggestWinsAre;

  /// No description provided for @akhirahBalanceScreen_youCameBackToday.
  ///
  /// In en, this message translates to:
  /// **'You came back today. That’s already worship. Stay one more minute?'**
  String get akhirahBalanceScreen_youCameBackToday;

  /// No description provided for @akhirahBalanceScreen_tomorrowPeaceIsBuilt.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow’s peace is built on today’s remembrance. Plant one more seed.'**
  String get akhirahBalanceScreen_tomorrowPeaceIsBuilt;

  /// No description provided for @akhirahBalanceScreen_areYouDoneAllah.
  ///
  /// In en, this message translates to:
  /// **'Are you done? Allah’s door is always open — even after you’ve closed it.'**
  String get akhirahBalanceScreen_areYouDoneAllah;

  /// No description provided for @akhirahBalanceScreen_dhikrIsTheLanguage.
  ///
  /// In en, this message translates to:
  /// **'Dhikr is the language of the heart. Has yours spoken to its Lord today?'**
  String get akhirahBalanceScreen_dhikrIsTheLanguage;

  /// No description provided for @akhirahBalanceScreen_everySubhanallahIsSadaqah.
  ///
  /// In en, this message translates to:
  /// **'Every Subhanallah is a sadaqah. How many will you give before sleep?'**
  String get akhirahBalanceScreen_everySubhanallahIsSadaqah;

  /// No description provided for @akhirahBalanceScreen_heartThatForgetsDhikr.
  ///
  /// In en, this message translates to:
  /// **'A heart that forgets dhikr begins to rust. A heart that remembers stays alight.'**
  String get akhirahBalanceScreen_heartThatForgetsDhikr;

  /// No description provided for @akhirahBalanceScreen_haveYouFortifiedYourself.
  ///
  /// In en, this message translates to:
  /// **'Have you fortified yourself with the morning and evening adhkar today?'**
  String get akhirahBalanceScreen_haveYouFortifiedYourself;

  /// No description provided for @akhirahBalanceScreen_thisSession.
  ///
  /// In en, this message translates to:
  /// **'This session: +{arg1}'**
  String akhirahBalanceScreen_thisSession(String arg1);

  /// No description provided for @akhirahBalanceScreen_seedsThisSession.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} seeds this session'**
  String akhirahBalanceScreen_seedsThisSession(String arg1);

  /// No description provided for @akhirahBalanceScreen_dayAvgAzkaarDay.
  ///
  /// In en, this message translates to:
  /// **'7-day avg: {arg1} azkaar/day'**
  String akhirahBalanceScreen_dayAvgAzkaarDay(String arg1);

  /// No description provided for @dashboardScreen_profileReturnedZeroRows.
  ///
  /// In en, this message translates to:
  /// **'Profile returned zero rows for {uid}'**
  String dashboardScreen_profileReturnedZeroRows(String uid);

  /// No description provided for @dashboardScreen_dashboardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Load Error: {e}'**
  String dashboardScreen_dashboardLoadError(String e);

  /// No description provided for @dashboardScreen_invalidReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid referral code'**
  String get dashboardScreen_invalidReferralCode;

  /// No description provided for @dashboardScreen_cannotReferYourself.
  ///
  /// In en, this message translates to:
  /// **'Cannot refer yourself'**
  String get dashboardScreen_cannotReferYourself;

  /// No description provided for @dashboardScreen_sponsor.
  ///
  /// In en, this message translates to:
  /// **'Sponsor {name}, {arg1}'**
  String dashboardScreen_sponsor(String name, String arg1);

  /// No description provided for @dashboardScreen_dashboardDoesn.
  ///
  /// In en, this message translates to:
  /// **': 0, // dashboard doesn'**
  String get dashboardScreen_dashboardDoesn;

  /// No description provided for @dashboardScreen_today.
  ///
  /// In en, this message translates to:
  /// **'{arg1} · {_lastAyah}  · +{_ayahsToday} today'**
  String dashboardScreen_today(
    String arg1,
    String _lastAyah,
    String _ayahsToday,
  );

  /// No description provided for @dashboardScreen_606140.
  ///
  /// In en, this message translates to:
  /// **'{arg1} · {_lastAyah}'**
  String dashboardScreen_606140(String arg1, String _lastAyah);

  /// No description provided for @dashboardScreen_setsToday.
  ///
  /// In en, this message translates to:
  /// **'{_dhikrToday} sets today'**
  String dashboardScreen_setsToday(String _dhikrToday);

  /// No description provided for @dashboardScreen_dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{arg1}-day streak'**
  String dashboardScreen_dayStreak(String arg1);

  /// No description provided for @dashboardScreen_last.
  ///
  /// In en, this message translates to:
  /// **'Last: {arg1}'**
  String dashboardScreen_last(String arg1);

  /// No description provided for @dashboardScreen_earnPerFriend.
  ///
  /// In en, this message translates to:
  /// **'Earn +500 per friend'**
  String get dashboardScreen_earnPerFriend;

  /// No description provided for @dashboardScreen_yourSabiqSeedsFund.
  ///
  /// In en, this message translates to:
  /// **'Your Sabiq Seeds fund these projects'**
  String get dashboardScreen_yourSabiqSeedsFund;

  /// No description provided for @dashboardScreen_active.
  ///
  /// In en, this message translates to:
  /// **'{arg1} active'**
  String dashboardScreen_active(String arg1);

  /// No description provided for @dashboardScreen_joinMeOnSabiq.
  ///
  /// In en, this message translates to:
  /// **'Join me on Sabiq Rewards, earn Seeds for daily Quran, Dhikr & good deeds!\\n\\n'**
  String get dashboardScreen_joinMeOnSabiq;

  /// No description provided for @dashboardScreen_useMyCodeAnd.
  ///
  /// In en, this message translates to:
  /// **'Use my code *{arg1}* and we both get 500 Sabiq Seeds!\\n\\n'**
  String dashboardScreen_useMyCodeAnd(String arg1);

  /// No description provided for @dashboardScreen_messageCopiedShareOr.
  ///
  /// In en, this message translates to:
  /// **'Message copied, share or paste in WhatsApp!'**
  String get dashboardScreen_messageCopiedShareOr;

  /// No description provided for @dashboardScreen_sabiqSeedsRewardedTo.
  ///
  /// In en, this message translates to:
  /// **'500 Sabiq Seeds rewarded to you both!'**
  String get dashboardScreen_sabiqSeedsRewardedTo;

  /// No description provided for @dashboardScreen_youHaveAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'You have already used a referral code.'**
  String get dashboardScreen_youHaveAlreadyUsed;

  /// No description provided for @dashboardScreen_invalidReferralCode_59fb25.
  ///
  /// In en, this message translates to:
  /// **'Invalid referral code.'**
  String get dashboardScreen_invalidReferralCode_59fb25;

  /// No description provided for @dashboardScreen_youCannotUseYour.
  ///
  /// In en, this message translates to:
  /// **'You cannot use your own code.'**
  String get dashboardScreen_youCannotUseYour;

  /// No description provided for @dashboardScreen_anErrorOccurredPlease.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get dashboardScreen_anErrorOccurredPlease;

  /// No description provided for @dashboardScreen_52b02c.
  ///
  /// In en, this message translates to:
  /// **'{pts} '**
  String dashboardScreen_52b02c(String pts);

  /// No description provided for @dashboardScreen_e4e562.
  ///
  /// In en, this message translates to:
  /// **'{arg1}%'**
  String dashboardScreen_e4e562(String arg1);

  /// No description provided for @dashboardScreen_seeDetailsForMore.
  ///
  /// In en, this message translates to:
  /// **'See Details for more Projects →'**
  String get dashboardScreen_seeDetailsForMore;

  /// No description provided for @dashboardScreen_yourTOTALSABIQSEEDS.
  ///
  /// In en, this message translates to:
  /// **'YOUR TOTAL SABIQ SEEDS'**
  String get dashboardScreen_yourTOTALSABIQSEEDS;

  /// No description provided for @dashboardScreen_viewCampaignDonate.
  ///
  /// In en, this message translates to:
  /// **'🤲  View Campaign & Donate'**
  String get dashboardScreen_viewCampaignDonate;

  /// No description provided for @dashboardScreen_yourRank.
  ///
  /// In en, this message translates to:
  /// **'Your Rank: {rankText}'**
  String dashboardScreen_yourRank(String rankText);

  /// No description provided for @dashboardScreen_d13a42.
  ///
  /// In en, this message translates to:
  /// **'{_myPoints} {unit} • {arg1}'**
  String dashboardScreen_d13a42(String _myPoints, String unit, String arg1);

  /// No description provided for @dashboardScreen_beTheFirstOn.
  ///
  /// In en, this message translates to:
  /// **'Be the first on the board'**
  String get dashboardScreen_beTheFirstOn;

  /// No description provided for @dashboardScreen_readAnAyahOr.
  ///
  /// In en, this message translates to:
  /// **'Read an ayah or dhikr to claim the top spot'**
  String get dashboardScreen_readAnAyahOr;

  /// No description provided for @dashboardScreen_lvl.
  ///
  /// In en, this message translates to:
  /// **'Lvl {level} · {arg1}'**
  String dashboardScreen_lvl(String level, String arg1);

  /// No description provided for @dashboardScreen_sealWithin.
  ///
  /// In en, this message translates to:
  /// **'Seal within {arg1}h'**
  String dashboardScreen_sealWithin(String arg1);

  /// No description provided for @dashboardScreen_jazakallahDaySealed.
  ///
  /// In en, this message translates to:
  /// **'JazakAllah!  Day sealed'**
  String get dashboardScreen_jazakallahDaySealed;

  /// No description provided for @dashboardScreen_ofGoal.
  ///
  /// In en, this message translates to:
  /// **'of {arg1} {arg2} goal'**
  String dashboardScreen_ofGoal(String arg1, String arg2);

  /// No description provided for @dhikrHubScreen_propheticSupplications.
  ///
  /// In en, this message translates to:
  /// **'Prophetic Supplications'**
  String get dhikrHubScreen_propheticSupplications;

  /// No description provided for @dhikrHubScreen_morningEveningRemembrance.
  ///
  /// In en, this message translates to:
  /// **'Morning & Evening Remembrance'**
  String get dhikrHubScreen_morningEveningRemembrance;

  /// No description provided for @dhikrHubScreen_furtherSupplications.
  ///
  /// In en, this message translates to:
  /// **'Further Supplications'**
  String get dhikrHubScreen_furtherSupplications;

  /// No description provided for @dhikrHubScreen_closingRemembranceSalawat.
  ///
  /// In en, this message translates to:
  /// **'Closing Remembrance & Salawat'**
  String get dhikrHubScreen_closingRemembranceSalawat;

  /// No description provided for @dhikrHubScreen_hajjUmrahSupplications.
  ///
  /// In en, this message translates to:
  /// **'Hajj & Umrah Supplications'**
  String get dhikrHubScreen_hajjUmrahSupplications;

  /// No description provided for @dhikrHubScreen_falseHiddenAdd.
  ///
  /// In en, this message translates to:
  /// **'] == false) hidden.add(r['**
  String get dhikrHubScreen_falseHiddenAdd;

  /// No description provided for @dhikrScreen_indoPak.
  ///
  /// In en, this message translates to:
  /// **'Indo pak'**
  String get dhikrScreen_indoPak;

  /// No description provided for @dhikrScreen_default.
  ///
  /// In en, this message translates to:
  /// **'Default: {recommendedCount}'**
  String dhikrScreen_default(String recommendedCount);

  /// No description provided for @dhikrScreen_duaAzkarSettings.
  ///
  /// In en, this message translates to:
  /// **'Dua & Azkar Settings'**
  String get dhikrScreen_duaAzkarSettings;

  /// No description provided for @dhikrScreen_hideTheVisualArtwork.
  ///
  /// In en, this message translates to:
  /// **'Hide the visual artwork area'**
  String get dhikrScreen_hideTheVisualArtwork;

  /// No description provided for @dhikrScreen_pinTheIllustrationAt.
  ///
  /// In en, this message translates to:
  /// **'Pin the illustration at the top while the Arabic text scrolls beneath it'**
  String get dhikrScreen_pinTheIllustrationAt;

  /// No description provided for @dhikrScreen_readTimes.
  ///
  /// In en, this message translates to:
  /// **'Read {readCount} times'**
  String dhikrScreen_readTimes(String readCount);

  /// No description provided for @dhikrScreen_d08433.
  ///
  /// In en, this message translates to:
  /// **'{arg1} / {arg2}'**
  String dhikrScreen_d08433(String arg1, String arg2);

  /// No description provided for @dhikrScreen_alBaqarahAmanaAr.
  ///
  /// In en, this message translates to:
  /// **'Al-Baqarah 285 (Amana ar-Rasool)'**
  String get dhikrScreen_alBaqarahAmanaAr;

  /// No description provided for @dhikrScreen_alBaqarahAlifLam.
  ///
  /// In en, this message translates to:
  /// **'Al-Baqarah 1-5 (Alif Lam Mim)'**
  String get dhikrScreen_alBaqarahAlifLam;

  /// No description provided for @dhikrScreen_alBaqarahLaIkraha.
  ///
  /// In en, this message translates to:
  /// **'Al-Baqarah 256 (La Ikraha)'**
  String get dhikrScreen_alBaqarahLaIkraha;

  /// No description provided for @dhikrScreen_alBaqarahAllahuWaliyy.
  ///
  /// In en, this message translates to:
  /// **'Al-Baqarah 257 (Allahu Waliyy)'**
  String get dhikrScreen_alBaqarahAllahuWaliyy;

  /// No description provided for @dhikrScreen_salawatIbrahimiyyaDurood.
  ///
  /// In en, this message translates to:
  /// **'Salawat Ibrahimiyya (Durood)'**
  String get dhikrScreen_salawatIbrahimiyyaDurood;

  /// No description provided for @dhikrScreen_9a4c42.
  ///
  /// In en, this message translates to:
  /// **'{bismillah} ﴿{arg1}﴾\\n{rest}'**
  String dhikrScreen_9a4c42(String bismillah, String arg1, String rest);

  /// No description provided for @dhikrScreen_86f857.
  ///
  /// In en, this message translates to:
  /// **'\\u2060{matched}'**
  String dhikrScreen_86f857(String matched);

  /// No description provided for @dhikrScreen_49900d.
  ///
  /// In en, this message translates to:
  /// **'+{hasanaat}'**
  String dhikrScreen_49900d(String hasanaat);

  /// No description provided for @dhikrScreen_hisnulMuslimChapter.
  ///
  /// In en, this message translates to:
  /// **'Hisnul Muslim, Chapter: '**
  String get dhikrScreen_hisnulMuslimChapter;

  /// No description provided for @dhikrScreen_3856c1.
  ///
  /// In en, this message translates to:
  /// **'{rawRef} | {bottomRef}'**
  String dhikrScreen_3856c1(String rawRef, String bottomRef);

  /// No description provided for @dhikrScreen_bestOfBothWorlds.
  ///
  /// In en, this message translates to:
  /// **'Best of both worlds, refuge from the Fire'**
  String get dhikrScreen_bestOfBothWorlds;

  /// No description provided for @dhikrScreen_patienceAndSteadfastnessIn.
  ///
  /// In en, this message translates to:
  /// **'Patience and steadfastness in every trial'**
  String get dhikrScreen_patienceAndSteadfastnessIn;

  /// No description provided for @dhikrScreen_allahBurdensNoSoul.
  ///
  /// In en, this message translates to:
  /// **'Allah burdens no soul beyond its capacity'**
  String get dhikrScreen_allahBurdensNoSoul;

  /// No description provided for @dhikrScreen_keepTheHeartFirm.
  ///
  /// In en, this message translates to:
  /// **'Keep the heart firm upon guidance'**
  String get dhikrScreen_keepTheHeartFirm;

  /// No description provided for @dhikrScreen_faithAnsweredWithForgiveness.
  ///
  /// In en, this message translates to:
  /// **'Faith answered with forgiveness from Hell'**
  String get dhikrScreen_faithAnsweredWithForgiveness;

  /// No description provided for @dhikrScreen_allSovereigntyInAllah.
  ///
  /// In en, this message translates to:
  /// **'All sovereignty in Allah\\'**
  String get dhikrScreen_allSovereigntyInAllah;

  /// No description provided for @dhikrScreen_allahHearsEveryCall.
  ///
  /// In en, this message translates to:
  /// **'Allah hears every call for righteous offspring'**
  String get dhikrScreen_allahHearsEveryCall;

  /// No description provided for @dhikrScreen_countedWithTheWitnesses.
  ///
  /// In en, this message translates to:
  /// **'Counted with the witnesses of truth'**
  String get dhikrScreen_countedWithTheWitnesses;

  /// No description provided for @dhikrScreen_forgivenessFirmFeetAnd.
  ///
  /// In en, this message translates to:
  /// **'Forgiveness, firm feet, and victory'**
  String get dhikrScreen_forgivenessFirmFeetAnd;

  /// No description provided for @dhikrScreen_theDuaOfThose.
  ///
  /// In en, this message translates to:
  /// **'The dua of those who reflect'**
  String get dhikrScreen_theDuaOfThose;

  /// No description provided for @dhikrScreen_inscribedWithTheWitnesses.
  ///
  /// In en, this message translates to:
  /// **'Inscribed with the witnesses of revelation'**
  String get dhikrScreen_inscribedWithTheWitnesses;

  /// No description provided for @dhikrScreen_theDuaAllahAccepted.
  ///
  /// In en, this message translates to:
  /// **'The dua Allah accepted from Adam ﷺ'**
  String get dhikrScreen_theDuaAllahAccepted;

  /// No description provided for @dhikrScreen_spareUsTheCompany.
  ///
  /// In en, this message translates to:
  /// **'Spare us the company of wrongdoers'**
  String get dhikrScreen_spareUsTheCompany;

  /// No description provided for @dhikrScreen_neverTrialForThe.
  ///
  /// In en, this message translates to:
  /// **'Never a trial for the oppressors'**
  String get dhikrScreen_neverTrialForThe;

  /// No description provided for @dhikrScreen_refugeFromAskingWithout.
  ///
  /// In en, this message translates to:
  /// **'Refuge from asking without knowledge'**
  String get dhikrScreen_refugeFromAskingWithout;

  /// No description provided for @dhikrScreen_prayerForSafetyAnd.
  ///
  /// In en, this message translates to:
  /// **'s prayer for safety and faith'**
  String get dhikrScreen_prayerForSafetyAnd;

  /// No description provided for @dhikrScreen_steadfastInPrayerMe.
  ///
  /// In en, this message translates to:
  /// **'Steadfast in prayer, me and my children'**
  String get dhikrScreen_steadfastInPrayerMe;

  /// No description provided for @dhikrScreen_mercyForMeMy.
  ///
  /// In en, this message translates to:
  /// **'Mercy for me, my parents, the believers'**
  String get dhikrScreen_mercyForMeMy;

  /// No description provided for @dhikrScreen_prayerForParents.
  ///
  /// In en, this message translates to:
  /// **'s prayer for parents'**
  String get dhikrScreen_prayerForParents;

  /// No description provided for @dhikrScreen_entryOfTruthExit.
  ///
  /// In en, this message translates to:
  /// **'Entry of truth, exit of truth'**
  String get dhikrScreen_entryOfTruthExit;

  /// No description provided for @dhikrScreen_prayerOfTheYouth.
  ///
  /// In en, this message translates to:
  /// **'Prayer of the youth of the cave'**
  String get dhikrScreen_prayerOfTheYouth;

  /// No description provided for @dhikrScreen_askAllahForMore.
  ///
  /// In en, this message translates to:
  /// **'Ask Allah for more — of knowledge'**
  String get dhikrScreen_askAllahForMore;

  /// No description provided for @dhikrScreen_allahAnswersAndSaves.
  ///
  /// In en, this message translates to:
  /// **'Allah answers and saves from every distress'**
  String get dhikrScreen_allahAnswersAndSaves;

  /// No description provided for @dhikrScreen_allahIsTheBest.
  ///
  /// In en, this message translates to:
  /// **'Allah is the best of inheritors'**
  String get dhikrScreen_allahIsTheBest;

  /// No description provided for @dhikrScreen_blessedLandingWhereverYou.
  ///
  /// In en, this message translates to:
  /// **'A blessed landing wherever you stop'**
  String get dhikrScreen_blessedLandingWhereverYou;

  /// No description provided for @dhikrScreen_refugeFromTheWhispers.
  ///
  /// In en, this message translates to:
  /// **'Refuge from the whispers of devils'**
  String get dhikrScreen_refugeFromTheWhispers;

  /// No description provided for @dhikrScreen_mercyFromTheBest.
  ///
  /// In en, this message translates to:
  /// **'Mercy from the Best of the Merciful'**
  String get dhikrScreen_mercyFromTheBest;

  /// No description provided for @dhikrScreen_pardonAndMercyFrom.
  ///
  /// In en, this message translates to:
  /// **'Pardon and mercy from the Most Merciful'**
  String get dhikrScreen_pardonAndMercyFrom;

  /// No description provided for @dhikrScreen_piousSpousesAndRighteous.
  ///
  /// In en, this message translates to:
  /// **'Pious spouses and righteous offspring'**
  String get dhikrScreen_piousSpousesAndRighteous;

  /// No description provided for @dhikrScreen_prayerForThoseWho.
  ///
  /// In en, this message translates to:
  /// **' prayer for those who repent'**
  String get dhikrScreen_prayerForThoseWho;

  /// No description provided for @dhikrScreen_gratitudeForParentsRighteousness.
  ///
  /// In en, this message translates to:
  /// **'Gratitude for parents, righteousness in offspring'**
  String get dhikrScreen_gratitudeForParentsRighteousness;

  /// No description provided for @dhikrScreen_pleaGiftOfIshaq.
  ///
  /// In en, this message translates to:
  /// **'s plea — gift of Ishaq ﷺ'**
  String get dhikrScreen_pleaGiftOfIshaq;

  /// No description provided for @dhikrScreen_loveForTheBelievers.
  ///
  /// In en, this message translates to:
  /// **'Love for the believers before us'**
  String get dhikrScreen_loveForTheBelievers;

  /// No description provided for @dhikrScreen_pureTawakkulOnYou.
  ///
  /// In en, this message translates to:
  /// **'s pure tawakkul — On You we rely'**
  String get dhikrScreen_pureTawakkulOnYou;

  /// No description provided for @dhikrScreen_forgivenessForEveryBelieving.
  ///
  /// In en, this message translates to:
  /// **'Forgiveness for every believing home'**
  String get dhikrScreen_forgivenessForEveryBelieving;

  /// No description provided for @dhikrScreen_tasbeehByTheWeight.
  ///
  /// In en, this message translates to:
  /// **'Tasbeeh by the weight of Allah\\'**
  String get dhikrScreen_tasbeehByTheWeight;

  /// No description provided for @dhikrScreen_tasbeehByTheNumber.
  ///
  /// In en, this message translates to:
  /// **'Tasbeeh by the number of all that He made'**
  String get dhikrScreen_tasbeehByTheNumber;

  /// No description provided for @dhikrScreen_tasbeehThatFillsAll.
  ///
  /// In en, this message translates to:
  /// **'Tasbeeh that fills all that Allah created'**
  String get dhikrScreen_tasbeehThatFillsAll;

  /// No description provided for @dhikrScreen_paradiseSoughtTheFire.
  ///
  /// In en, this message translates to:
  /// **'Paradise sought — the Fire\\'**
  String get dhikrScreen_paradiseSoughtTheFire;

  /// No description provided for @dhikrScreen_cryToTheOne.
  ///
  /// In en, this message translates to:
  /// **'Cry to the One who hears, sees, and knows'**
  String get dhikrScreen_cryToTheOne;

  /// No description provided for @dhikrScreen_nameOnTheCorner.
  ///
  /// In en, this message translates to:
  /// **'s name on the corner of the Kaaba'**
  String get dhikrScreen_nameOnTheCorner;

  /// No description provided for @dhikrScreen_theDuaBetweenYemen.
  ///
  /// In en, this message translates to:
  /// **'The dua between Yemen Corner and Black Stone'**
  String get dhikrScreen_theDuaBetweenYemen;

  /// No description provided for @dhikrScreen_prayAtTheStation.
  ///
  /// In en, this message translates to:
  /// **'Pray at the station of Ibrahim ﷺ'**
  String get dhikrScreen_prayAtTheStation;

  /// No description provided for @dhikrScreen_tawheedDeclaredAtopSafa.
  ///
  /// In en, this message translates to:
  /// **'Tawheed declared atop Safa and Marwah'**
  String get dhikrScreen_tawheedDeclaredAtopSafa;

  /// No description provided for @dhikrScreen_reaffirmTheOnenessOf.
  ///
  /// In en, this message translates to:
  /// **'Reaffirm the Oneness of Allah'**
  String get dhikrScreen_reaffirmTheOnenessOf;

  /// No description provided for @dhikrScreen_magnifyAllahAtEvery.
  ///
  /// In en, this message translates to:
  /// **'Magnify Allah at every threshold of Hajj'**
  String get dhikrScreen_magnifyAllahAtEvery;

  /// No description provided for @dhikrScreen_magnifyAllahOnThe.
  ///
  /// In en, this message translates to:
  /// **'Magnify Allah on the day of sacrifice'**
  String get dhikrScreen_magnifyAllahOnThe;

  /// No description provided for @dhikrScreen_knowledgeProvisionHealingSought.
  ///
  /// In en, this message translates to:
  /// **'Knowledge, provision, healing — sought in Makkah'**
  String get dhikrScreen_knowledgeProvisionHealingSought;

  /// No description provided for @dhikrScreen_theDuaMostRepeated.
  ///
  /// In en, this message translates to:
  /// **'The dua most repeated by the Prophet ﷺ'**
  String get dhikrScreen_theDuaMostRepeated;

  /// No description provided for @dhikrScreen_refugeFromEveryTrial.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every trial of life and death'**
  String get dhikrScreen_refugeFromEveryTrial;

  /// No description provided for @dhikrScreen_refugeFromEveryWeakness.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every weakness of body and soul'**
  String get dhikrScreen_refugeFromEveryWeakness;

  /// No description provided for @dhikrScreen_refugeFromSevereTrial.
  ///
  /// In en, this message translates to:
  /// **'Refuge from severe trial and enemy\\'**
  String get dhikrScreen_refugeFromSevereTrial;

  /// No description provided for @dhikrScreen_religionSetRightWorld.
  ///
  /// In en, this message translates to:
  /// **'Religion set right, world and Akhirah made best'**
  String get dhikrScreen_religionSetRightWorld;

  /// No description provided for @dhikrScreen_guidancePietyVirtueSelf.
  ///
  /// In en, this message translates to:
  /// **'Guidance, piety, virtue, self-sufficiency'**
  String get dhikrScreen_guidancePietyVirtueSelf;

  /// No description provided for @dhikrScreen_refugeFromWeaknessWealth.
  ///
  /// In en, this message translates to:
  /// **'Refuge from weakness — wealth of piety within'**
  String get dhikrScreen_refugeFromWeaknessWealth;

  /// No description provided for @dhikrScreen_theGuiderOfHearts.
  ///
  /// In en, this message translates to:
  /// **'The Guider of hearts — turn ours to obedience'**
  String get dhikrScreen_theGuiderOfHearts;

  /// No description provided for @dhikrScreen_turnerOfHeartsMake.
  ///
  /// In en, this message translates to:
  /// **'Turner of hearts — make mine firm on the deen'**
  String get dhikrScreen_turnerOfHeartsMake;

  /// No description provided for @dhikrScreen_wellBeingInBoth.
  ///
  /// In en, this message translates to:
  /// **'Well-being in both worlds'**
  String get dhikrScreen_wellBeingInBoth;

  /// No description provided for @dhikrScreen_rewardsSaveFromDisgrace.
  ///
  /// In en, this message translates to:
  /// **'Rewards, save from disgrace and grave\\'**
  String get dhikrScreen_rewardsSaveFromDisgrace;

  /// No description provided for @dhikrScreen_mindForGoodVictory.
  ///
  /// In en, this message translates to:
  /// **'Mind for good, victory for good'**
  String get dhikrScreen_mindForGoodVictory;

  /// No description provided for @dhikrScreen_refugeFromEvilOf.
  ///
  /// In en, this message translates to:
  /// **'Refuge from evil of every sense and limb'**
  String get dhikrScreen_refugeFromEvilOf;

  /// No description provided for @dhikrScreen_theForgiverWhoLoves.
  ///
  /// In en, this message translates to:
  /// **'The Forgiver who loves the repentant'**
  String get dhikrScreen_theForgiverWhoLoves;

  /// No description provided for @dhikrScreen_takeMeBeforeYou.
  ///
  /// In en, this message translates to:
  /// **'Take me before You take me astray'**
  String get dhikrScreen_takeMeBeforeYou;

  /// No description provided for @dhikrScreen_everyGoodAndRefuge.
  ///
  /// In en, this message translates to:
  /// **'Every good — and refuge from every evil'**
  String get dhikrScreen_everyGoodAndRefuge;

  /// No description provided for @dhikrScreen_standingSittingLyingGuarded.
  ///
  /// In en, this message translates to:
  /// **'Standing, sitting, lying — guarded in Islam'**
  String get dhikrScreen_standingSittingLyingGuarded;

  /// No description provided for @dhikrScreen_refugeFromCowardiceMiserliness.
  ///
  /// In en, this message translates to:
  /// **'Refuge from cowardice, miserliness, fitnah'**
  String get dhikrScreen_refugeFromCowardiceMiserliness;

  /// No description provided for @dhikrScreen_forgivenessForJestAnd.
  ///
  /// In en, this message translates to:
  /// **'Forgiveness for jest and serious, known and unknown'**
  String get dhikrScreen_forgivenessForJestAnd;

  /// No description provided for @dhikrScreen_forgiveMeWithForgiveness.
  ///
  /// In en, this message translates to:
  /// **'Forgive me with a forgiveness from You'**
  String get dhikrScreen_forgiveMeWithForgiveness;

  /// No description provided for @dhikrScreen_submissionBeliefRepentanceFull.
  ///
  /// In en, this message translates to:
  /// **'Submission, belief, repentance, full trust'**
  String get dhikrScreen_submissionBeliefRepentanceFull;

  /// No description provided for @dhikrScreen_mercyForgivenessParadiseSaved.
  ///
  /// In en, this message translates to:
  /// **'Mercy, forgiveness, Paradise — saved from the Fire'**
  String get dhikrScreen_mercyForgivenessParadiseSaved;

  /// No description provided for @dhikrScreen_refugeFromEvilSeen.
  ///
  /// In en, this message translates to:
  /// **'Refuge from evil seen and unseen'**
  String get dhikrScreen_refugeFromEvilSeen;

  /// No description provided for @dhikrScreen_provisionThatLastsTill.
  ///
  /// In en, this message translates to:
  /// **'Provision that lasts till life\\'**
  String get dhikrScreen_provisionThatLastsTill;

  /// No description provided for @dhikrScreen_sinsForgivenHomeSpacious.
  ///
  /// In en, this message translates to:
  /// **'Sins forgiven, home spacious, provision blessed'**
  String get dhikrScreen_sinsForgivenHomeSpacious;

  /// No description provided for @dhikrScreen_favorAndMercyNone.
  ///
  /// In en, this message translates to:
  /// **'Favor and mercy — none possesses them but You'**
  String get dhikrScreen_favorAndMercyNone;

  /// No description provided for @dhikrScreen_refugeFromDrowningBurning.
  ///
  /// In en, this message translates to:
  /// **'Refuge from drowning, burning, sudden death'**
  String get dhikrScreen_refugeFromDrowningBurning;

  /// No description provided for @dhikrScreen_refugeFromHypocrisyShowiness.
  ///
  /// In en, this message translates to:
  /// **'Refuge from hypocrisy, showiness, rebellion'**
  String get dhikrScreen_refugeFromHypocrisyShowiness;

  /// No description provided for @dhikrScreen_refugeFromPovertyScarcity.
  ///
  /// In en, this message translates to:
  /// **'Refuge from poverty, scarcity, oppression'**
  String get dhikrScreen_refugeFromPovertyScarcity;

  /// No description provided for @dhikrScreen_refugeFromHeartThat.
  ///
  /// In en, this message translates to:
  /// **'Refuge from a heart that won\\'**
  String get dhikrScreen_refugeFromHeartThat;

  /// No description provided for @dhikrScreen_payMyDebtEnrich.
  ///
  /// In en, this message translates to:
  /// **'Pay my debt, enrich me from poverty'**
  String get dhikrScreen_payMyDebtEnrich;

  /// No description provided for @dhikrScreen_allahCalledByHis.
  ///
  /// In en, this message translates to:
  /// **'Allah called by His most beautiful names'**
  String get dhikrScreen_allahCalledByHis;

  /// No description provided for @dhikrScreen_theAccepterOfRepentance.
  ///
  /// In en, this message translates to:
  /// **'The Accepter of repentance always accepts'**
  String get dhikrScreen_theAccepterOfRepentance;

  /// No description provided for @dhikrScreen_anEasyReckoningOn.
  ///
  /// In en, this message translates to:
  /// **'An easy reckoning on the Day'**
  String get dhikrScreen_anEasyReckoningOn;

  /// No description provided for @dhikrScreen_remembranceGratitudeAndThe.
  ///
  /// In en, this message translates to:
  /// **'Remembrance, gratitude, and the best worship'**
  String get dhikrScreen_remembranceGratitudeAndThe;

  /// No description provided for @dhikrScreen_eternalBlissWithThe.
  ///
  /// In en, this message translates to:
  /// **'Eternal bliss with the Prophet ﷺ in Firdaws'**
  String get dhikrScreen_eternalBlissWithThe;

  /// No description provided for @dhikrScreen_forgiveSinsKnownHidden.
  ///
  /// In en, this message translates to:
  /// **'Forgive sins — known, hidden, intended, mistaken'**
  String get dhikrScreen_forgiveSinsKnownHidden;

  /// No description provided for @dhikrScreen_refugeFromBeingCrushed.
  ///
  /// In en, this message translates to:
  /// **'Refuge from being crushed by debt and enemy'**
  String get dhikrScreen_refugeFromBeingCrushed;

  /// No description provided for @dhikrScreen_askForParadiseRefuge.
  ///
  /// In en, this message translates to:
  /// **'Ask for Paradise, refuge from the Fire'**
  String get dhikrScreen_askForParadiseRefuge;

  /// No description provided for @dhikrScreen_forgiveGuideProvideProtect.
  ///
  /// In en, this message translates to:
  /// **'Forgive, guide, provide, protect'**
  String get dhikrScreen_forgiveGuideProvideProtect;

  /// No description provided for @dhikrScreen_sensesMadeBeneficialAnd.
  ///
  /// In en, this message translates to:
  /// **'Senses made beneficial — and lasting'**
  String get dhikrScreen_sensesMadeBeneficialAnd;

  /// No description provided for @dhikrScreen_theMostBeneficentThe.
  ///
  /// In en, this message translates to:
  /// **'The Most Beneficent, the Originator of all'**
  String get dhikrScreen_theMostBeneficentThe;

  /// No description provided for @dhikrScreen_allahTruthOwnerOf.
  ///
  /// In en, this message translates to:
  /// **'Allah — Truth, Owner of all dominion'**
  String get dhikrScreen_allahTruthOwnerOf;

  /// No description provided for @dhikrScreen_submissionWithFullSincerity.
  ///
  /// In en, this message translates to:
  /// **'Submission with full sincerity'**
  String get dhikrScreen_submissionWithFullSincerity;

  /// No description provided for @dhikrScreen_amongTheGuidedThe.
  ///
  /// In en, this message translates to:
  /// **'Among the guided, the healthy, the chosen'**
  String get dhikrScreen_amongTheGuidedThe;

  /// No description provided for @dhikrScreen_whatTheProphetAsked.
  ///
  /// In en, this message translates to:
  /// **'What the Prophet ﷺ asked — I ask too'**
  String get dhikrScreen_whatTheProphetAsked;

  /// No description provided for @dhikrScreen_sayyidAlIstighfarThe.
  ///
  /// In en, this message translates to:
  /// **'Sayyid al-Istighfar — the master of all repentance'**
  String get dhikrScreen_sayyidAlIstighfarThe;

  /// No description provided for @dhikrScreen_refugeFromEveryEvil.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every evil that comes by night'**
  String get dhikrScreen_refugeFromEveryEvil;

  /// No description provided for @dhikrScreen_blessEverySenseEvery.
  ///
  /// In en, this message translates to:
  /// **'Bless every sense, every limb'**
  String get dhikrScreen_blessEverySenseEvery;

  /// No description provided for @dhikrScreen_smallAndGreatFirst.
  ///
  /// In en, this message translates to:
  /// **'Small and great, first and last, open and secret'**
  String get dhikrScreen_smallAndGreatFirst;

  /// No description provided for @dhikrScreen_noneWithholdsWhatYou.
  ///
  /// In en, this message translates to:
  /// **'None withholds what You give, none gives what You hold'**
  String get dhikrScreen_noneWithholdsWhatYou;

  /// No description provided for @dhikrScreen_forgiveGuideProvideElevate.
  ///
  /// In en, this message translates to:
  /// **'Forgive, guide, provide, elevate'**
  String get dhikrScreen_forgiveGuideProvideElevate;

  /// No description provided for @dhikrScreen_increaseFavorBeKind.
  ///
  /// In en, this message translates to:
  /// **'Increase favor, be kind, never displeased'**
  String get dhikrScreen_increaseFavorBeKind;

  /// No description provided for @dhikrScreen_beautifyOurCharacterAs.
  ///
  /// In en, this message translates to:
  /// **'Beautify our character as You beautified our creation'**
  String get dhikrScreen_beautifyOurCharacterAs;

  /// No description provided for @dhikrScreen_firmInBeliefGuided.
  ///
  /// In en, this message translates to:
  /// **'Firm in belief — guided and guiding'**
  String get dhikrScreen_firmInBeliefGuided;

  /// No description provided for @dhikrScreen_wisdomAndWithIt.
  ///
  /// In en, this message translates to:
  /// **'Wisdom — and with it, multitudes of good'**
  String get dhikrScreen_wisdomAndWithIt;

  /// No description provided for @dhikrScreen_nameShieldsFromEvery.
  ///
  /// In en, this message translates to:
  /// **'s name shields from every harm'**
  String get dhikrScreen_nameShieldsFromEvery;

  /// No description provided for @dhikrScreen_mightAgainstEveryShaytan.
  ///
  /// In en, this message translates to:
  /// **'s might against every Shaytan'**
  String get dhikrScreen_mightAgainstEveryShaytan;

  /// No description provided for @dhikrScreen_dayBlessedFromBeginning.
  ///
  /// In en, this message translates to:
  /// **'A day blessed from beginning to end'**
  String get dhikrScreen_dayBlessedFromBeginning;

  /// No description provided for @dhikrScreen_witnessNoneDeservesWorship.
  ///
  /// In en, this message translates to:
  /// **'Witness — none deserves worship but You'**
  String get dhikrScreen_witnessNoneDeservesWorship;

  /// No description provided for @dhikrScreen_refugeFromHumiliatingOld.
  ///
  /// In en, this message translates to:
  /// **'Refuge from a humiliating old age'**
  String get dhikrScreen_refugeFromHumiliatingOld;

  /// No description provided for @dhikrScreen_guidedToTheBest.
  ///
  /// In en, this message translates to:
  /// **'Guided to the best, saved from the worst'**
  String get dhikrScreen_guidedToTheBest;

  /// No description provided for @dhikrScreen_faithSetRightHome.
  ///
  /// In en, this message translates to:
  /// **'Faith set right, home wide, provision blessed'**
  String get dhikrScreen_faithSetRightHome;

  /// No description provided for @dhikrScreen_refugeFromEveryInner.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every inner and outer disease'**
  String get dhikrScreen_refugeFromEveryInner;

  /// No description provided for @dhikrScreen_refugeFromEveryKind.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every kind of bad end'**
  String get dhikrScreen_refugeFromEveryKind;

  /// No description provided for @dhikrScreen_steadfastGratefulRightlyGuided.
  ///
  /// In en, this message translates to:
  /// **'Steadfast, grateful, rightly-guided heart'**
  String get dhikrScreen_steadfastGratefulRightlyGuided;

  /// No description provided for @dhikrScreen_theLoveOfAllah.
  ///
  /// In en, this message translates to:
  /// **'The love of Allah, His angels, His prophets'**
  String get dhikrScreen_theLoveOfAllah;

  /// No description provided for @dhikrScreen_loveOfAllahAbove.
  ///
  /// In en, this message translates to:
  /// **'Love of Allah above love of self'**
  String get dhikrScreen_loveOfAllahAbove;

  /// No description provided for @dhikrScreen_bestDeedsLastBest.
  ///
  /// In en, this message translates to:
  /// **'Best deeds last — best day is meeting You'**
  String get dhikrScreen_bestDeedsLastBest;

  /// No description provided for @dhikrScreen_pureLifeAndPeaceful.
  ///
  /// In en, this message translates to:
  /// **'A pure life and a peaceful return'**
  String get dhikrScreen_pureLifeAndPeaceful;

  /// No description provided for @dhikrScreen_patientGratefulSmallIn.
  ///
  /// In en, this message translates to:
  /// **'Patient, grateful — small in own eyes'**
  String get dhikrScreen_patientGratefulSmallIn;

  /// No description provided for @dhikrScreen_theBestRequestAnd.
  ///
  /// In en, this message translates to:
  /// **'The best request and the best reward'**
  String get dhikrScreen_theBestRequestAnd;

  /// No description provided for @dhikrScreen_theHighestLevelOf.
  ///
  /// In en, this message translates to:
  /// **'The highest level of Paradise'**
  String get dhikrScreen_theHighestLevelOf;

  /// No description provided for @dhikrScreen_firdawsTheBestOf.
  ///
  /// In en, this message translates to:
  /// **'Firdaws — the best of all that\\'**
  String get dhikrScreen_firdawsTheBestOf;

  /// No description provided for @dhikrScreen_mentionRaisedSinsErased.
  ///
  /// In en, this message translates to:
  /// **'Mention raised, sins erased, heart purified'**
  String get dhikrScreen_mentionRaisedSinsErased;

  /// No description provided for @dhikrScreen_blessEverySenseEvery_b81b9b.
  ///
  /// In en, this message translates to:
  /// **'Bless every sense, every limb, every deed'**
  String get dhikrScreen_blessEverySenseEvery_b81b9b;

  /// No description provided for @dhikrScreen_mercyPleasureParadiseSaved.
  ///
  /// In en, this message translates to:
  /// **'Mercy, pleasure, Paradise — saved from Fire'**
  String get dhikrScreen_mercyPleasureParadiseSaved;

  /// No description provided for @dhikrScreen_noSinUncoveredNo.
  ///
  /// In en, this message translates to:
  /// **'No sin uncovered, no debt unpaid'**
  String get dhikrScreen_noSinUncoveredNo;

  /// No description provided for @dhikrScreen_mercyThatGuidesSets.
  ///
  /// In en, this message translates to:
  /// **'Mercy that guides, sets right, purifies'**
  String get dhikrScreen_mercyThatGuidesSets;

  /// No description provided for @dhikrScreen_trueBeliefCertainKnowledge.
  ///
  /// In en, this message translates to:
  /// **'True belief, certain knowledge, Allah\\'**
  String get dhikrScreen_trueBeliefCertainKnowledge;

  /// No description provided for @dhikrScreen_withTheProphetsThe.
  ///
  /// In en, this message translates to:
  /// **'With the Prophets, the martyrs, the truthful'**
  String get dhikrScreen_withTheProphetsThe;

  /// No description provided for @dhikrScreen_everyNeedEntrustedTo.
  ///
  /// In en, this message translates to:
  /// **'Every need entrusted to the Judge of all needs'**
  String get dhikrScreen_everyNeedEntrustedTo;

  /// No description provided for @dhikrScreen_bestOfWhatAllah.
  ///
  /// In en, this message translates to:
  /// **'Best of what Allah promised His servants'**
  String get dhikrScreen_bestOfWhatAllah;

  /// No description provided for @dhikrScreen_safetyOnTheDay.
  ///
  /// In en, this message translates to:
  /// **'Safety on the Day, Paradise on the Eternal Day'**
  String get dhikrScreen_safetyOnTheDay;

  /// No description provided for @dhikrScreen_glorifyTheOneOf.
  ///
  /// In en, this message translates to:
  /// **'Glorify the One of unmatched honor and knowledge'**
  String get dhikrScreen_glorifyTheOneOf;

  /// No description provided for @dhikrScreen_pardonPlentySecurityIn.
  ///
  /// In en, this message translates to:
  /// **'Pardon, plenty, security in deen and dunya'**
  String get dhikrScreen_pardonPlentySecurityIn;

  /// No description provided for @dhikrScreen_healthFaithEthicsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Health, faith, ethics, success, mercy'**
  String get dhikrScreen_healthFaithEthicsSuccess;

  /// No description provided for @dhikrScreen_healthPurityEthicsAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Health, purity, ethics, acceptance'**
  String get dhikrScreen_healthPurityEthicsAcceptance;

  /// No description provided for @dhikrScreen_guidedSecureVictorious.
  ///
  /// In en, this message translates to:
  /// **'Guided, secure, victorious'**
  String get dhikrScreen_guidedSecureVictorious;

  /// No description provided for @dhikrScreen_refugeFromEveryCreature.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every creature in Allah\\'**
  String get dhikrScreen_refugeFromEveryCreature;

  /// No description provided for @dhikrScreen_theOneWhoAnswers.
  ///
  /// In en, this message translates to:
  /// **'The One who answers the compelled and broken'**
  String get dhikrScreen_theOneWhoAnswers;

  /// No description provided for @dhikrScreen_morningReachedByAllah.
  ///
  /// In en, this message translates to:
  /// **'Morning reached by Allah\\'**
  String get dhikrScreen_morningReachedByAllah;

  /// No description provided for @dhikrScreen_refugeSoughtByMusa.
  ///
  /// In en, this message translates to:
  /// **'Refuge sought by Musa, Isa, Ibrahim'**
  String get dhikrScreen_refugeSoughtByMusa;

  /// No description provided for @dhikrScreen_allTheGoodPower.
  ///
  /// In en, this message translates to:
  /// **'All the good — power, mercy, blessings'**
  String get dhikrScreen_allTheGoodPower;

  /// No description provided for @dhikrScreen_allPraiseAndDominion.
  ///
  /// In en, this message translates to:
  /// **'All praise and dominion belong to You'**
  String get dhikrScreen_allPraiseAndDominion;

  /// No description provided for @dhikrScreen_pastPardonedFutureProtected.
  ///
  /// In en, this message translates to:
  /// **'Past pardoned, future protected'**
  String get dhikrScreen_pastPardonedFutureProtected;

  /// No description provided for @dhikrScreen_takeMyForelockTo.
  ///
  /// In en, this message translates to:
  /// **'Take my forelock to goodness'**
  String get dhikrScreen_takeMyForelockTo;

  /// No description provided for @dhikrScreen_strengthForWeaknessDignity.
  ///
  /// In en, this message translates to:
  /// **'Strength for weakness, dignity for shame'**
  String get dhikrScreen_strengthForWeaknessDignity;

  /// No description provided for @dhikrScreen_justiceForThoseWho.
  ///
  /// In en, this message translates to:
  /// **'Justice for those who block the truth'**
  String get dhikrScreen_justiceForThoseWho;

  /// No description provided for @dhikrScreen_refugeFromEveryFatal.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every fatal calamity'**
  String get dhikrScreen_refugeFromEveryFatal;

  /// No description provided for @dhikrScreen_refugeFromEveryBad.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every bad end and trial'**
  String get dhikrScreen_refugeFromEveryBad;

  /// No description provided for @dhikrScreen_turnBackEveryEvil.
  ///
  /// In en, this message translates to:
  /// **'Turn back every evil intention to its source'**
  String get dhikrScreen_turnBackEveryEvil;

  /// No description provided for @dhikrScreen_justiceAndRefugeAgainst.
  ///
  /// In en, this message translates to:
  /// **'Justice and refuge against their evils'**
  String get dhikrScreen_justiceAndRefugeAgainst;

  /// No description provided for @dhikrScreen_forgivenessForMeMy.
  ///
  /// In en, this message translates to:
  /// **'Forgiveness for me, my parents, all believers'**
  String get dhikrScreen_forgivenessForMeMy;

  /// No description provided for @dhikrScreen_purifyHeartDeedsTongue.
  ///
  /// In en, this message translates to:
  /// **'Purify heart, deeds, tongue, eyes'**
  String get dhikrScreen_purifyHeartDeedsTongue;

  /// No description provided for @dhikrScreen_selfContentWithAllah.
  ///
  /// In en, this message translates to:
  /// **'A self content with Allah\\'**
  String get dhikrScreen_selfContentWithAllah;

  /// No description provided for @dhikrScreen_youKnowMySecret.
  ///
  /// In en, this message translates to:
  /// **'You know my secret and my need'**
  String get dhikrScreen_youKnowMySecret;

  /// No description provided for @dhikrScreen_certaintyNothingHarmsWhat.
  ///
  /// In en, this message translates to:
  /// **'Certainty: nothing harms what\\'**
  String get dhikrScreen_certaintyNothingHarmsWhat;

  /// No description provided for @dhikrScreen_beliefLightAndLawful.
  ///
  /// In en, this message translates to:
  /// **'Belief, light, and lawful provision'**
  String get dhikrScreen_beliefLightAndLawful;

  /// No description provided for @dhikrScreen_totalLoveAndTotal.
  ///
  /// In en, this message translates to:
  /// **'Total love and total struggle for Allah'**
  String get dhikrScreen_totalLoveAndTotal;

  /// No description provided for @dhikrScreen_makeWhatYouWithheld.
  ///
  /// In en, this message translates to:
  /// **'Make what You withheld a strength in obedience'**
  String get dhikrScreen_makeWhatYouWithheld;

  /// No description provided for @dhikrScreen_praiseTheOwnerOf.
  ///
  /// In en, this message translates to:
  /// **'Praise the Owner of every beautiful name'**
  String get dhikrScreen_praiseTheOwnerOf;

  /// No description provided for @dhikrScreen_allahKnowsTheHearts.
  ///
  /// In en, this message translates to:
  /// **'Allah knows the hearts, the heavens, and beyond'**
  String get dhikrScreen_allahKnowsTheHearts;

  /// No description provided for @dhikrScreen_hopeBuiltOnAllah.
  ///
  /// In en, this message translates to:
  /// **'Hope built on Allah\\'**
  String get dhikrScreen_hopeBuiltOnAllah;

  /// No description provided for @dhikrScreen_belovedToTheBelievers.
  ///
  /// In en, this message translates to:
  /// **'Beloved to the believers, free from the wicked'**
  String get dhikrScreen_belovedToTheBelievers;

  /// No description provided for @dhikrScreen_mightPowerAndMajesty.
  ///
  /// In en, this message translates to:
  /// **'s might, power, and majesty'**
  String get dhikrScreen_mightPowerAndMajesty;

  /// No description provided for @dhikrScreen_gratefulPatientHelpfulTo.
  ///
  /// In en, this message translates to:
  /// **'Grateful, patient, helpful to Allah\\'**
  String get dhikrScreen_gratefulPatientHelpfulTo;

  /// No description provided for @dhikrScreen_withholdYourGoodFor.
  ///
  /// In en, this message translates to:
  /// **'t withhold Your good for my evil'**
  String get dhikrScreen_withholdYourGoodFor;

  /// No description provided for @dhikrScreen_settledLifeAmpleProvision.
  ///
  /// In en, this message translates to:
  /// **'A settled life, ample provision, righteous deeds'**
  String get dhikrScreen_settledLifeAmpleProvision;

  /// No description provided for @dhikrScreen_wealthInNeedingYou.
  ///
  /// In en, this message translates to:
  /// **'Wealth in needing You — never free of You'**
  String get dhikrScreen_wealthInNeedingYou;

  /// No description provided for @dhikrScreen_defectsCoveredFearsCalmed.
  ///
  /// In en, this message translates to:
  /// **'Defects covered, fears calmed, anguish lifted'**
  String get dhikrScreen_defectsCoveredFearsCalmed;

  /// No description provided for @dhikrScreen_openTheGatesOf.
  ///
  /// In en, this message translates to:
  /// **'Open the gates of mercy and generosity'**
  String get dhikrScreen_openTheGatesOf;

  /// No description provided for @dhikrScreen_holdUsInYour.
  ///
  /// In en, this message translates to:
  /// **'Hold us in Your safety — never abandon us'**
  String get dhikrScreen_holdUsInYour;

  /// No description provided for @dhikrScreen_withinYourSecurityYour.
  ///
  /// In en, this message translates to:
  /// **'Within Your security, Your goodness'**
  String get dhikrScreen_withinYourSecurityYour;

  /// No description provided for @dhikrScreen_everySinEveryDistress.
  ///
  /// In en, this message translates to:
  /// **'Every sin, every distress, every side'**
  String get dhikrScreen_everySinEveryDistress;

  /// No description provided for @dhikrScreen_helpInDeathIn.
  ///
  /// In en, this message translates to:
  /// **'Help in death, in the grave, on the Bridge'**
  String get dhikrScreen_helpInDeathIn;

  /// No description provided for @dhikrScreen_beautifiedLifeBlessedGifts.
  ///
  /// In en, this message translates to:
  /// **'Beautified life, blessed gifts, kept favors'**
  String get dhikrScreen_beautifiedLifeBlessedGifts;

  /// No description provided for @dhikrScreen_firmFootingBlessedEnd.
  ///
  /// In en, this message translates to:
  /// **'Firm footing, blessed end, kept covenant'**
  String get dhikrScreen_firmFootingBlessedEnd;

  /// No description provided for @dhikrScreen_hopesFulfilledEnemiesRepelled.
  ///
  /// In en, this message translates to:
  /// **'Hopes fulfilled, enemies repelled, affairs set right'**
  String get dhikrScreen_hopesFulfilledEnemiesRepelled;

  /// No description provided for @dhikrScreen_guidedToTheUpright.
  ///
  /// In en, this message translates to:
  /// **'Guided to the upright, protected from the self'**
  String get dhikrScreen_guidedToTheUpright;

  /// No description provided for @dhikrScreen_lightAndForgivenessFrom.
  ///
  /// In en, this message translates to:
  /// **'Light and forgiveness from the Owner of the Throne'**
  String get dhikrScreen_lightAndForgivenessFrom;

  /// No description provided for @dhikrScreen_forgivenessForWhatRepented.
  ///
  /// In en, this message translates to:
  /// **'Forgiveness for what I repented and returned to'**
  String get dhikrScreen_forgivenessForWhatRepented;

  /// No description provided for @dhikrScreen_understandingThatDrawsNear.
  ///
  /// In en, this message translates to:
  /// **'Understanding that draws near to Allah'**
  String get dhikrScreen_understandingThatDrawsNear;

  /// No description provided for @dhikrScreen_soulsDwellingInThe.
  ///
  /// In en, this message translates to:
  /// **'Souls dwelling in the heights of piety'**
  String get dhikrScreen_soulsDwellingInThe;

  /// No description provided for @dhikrScreen_crossTheBridgeOf.
  ///
  /// In en, this message translates to:
  /// **'Cross the bridge of desire by patience'**
  String get dhikrScreen_crossTheBridgeOf;

  /// No description provided for @dhikrScreen_followThePathOf.
  ///
  /// In en, this message translates to:
  /// **'Follow the path of sincerity and certainty'**
  String get dhikrScreen_followThePathOf;

  /// No description provided for @dhikrScreen_helpAgainstTheSoul.
  ///
  /// In en, this message translates to:
  /// **'Help against the soul and against Shaytan'**
  String get dhikrScreen_helpAgainstTheSoul;

  /// No description provided for @dhikrScreen_fearHappinessVictorySecurity.
  ///
  /// In en, this message translates to:
  /// **'Fear, happiness, victory, security'**
  String get dhikrScreen_fearHappinessVictorySecurity;

  /// No description provided for @dhikrScreen_entrustFamilyWealthChildren.
  ///
  /// In en, this message translates to:
  /// **'Entrust family, wealth, children — all to Allah'**
  String get dhikrScreen_entrustFamilyWealthChildren;

  /// No description provided for @dhikrScreen_faithGuardedFaithPreserved.
  ///
  /// In en, this message translates to:
  /// **'Faith guarded, faith preserved'**
  String get dhikrScreen_faithGuardedFaithPreserved;

  /// No description provided for @dhikrScreen_wellBeingTillThe.
  ///
  /// In en, this message translates to:
  /// **'Well-being till the end — sealed with forgiveness'**
  String get dhikrScreen_wellBeingTillThe;

  /// No description provided for @dhikrScreen_whatProtectsMeFrom.
  ///
  /// In en, this message translates to:
  /// **'What protects me from this world\\'**
  String get dhikrScreen_whatProtectsMeFrom;

  /// No description provided for @dhikrScreen_mercyOnEverySoul.
  ///
  /// In en, this message translates to:
  /// **'Mercy on every soul\\'**
  String get dhikrScreen_mercyOnEverySoul;

  /// No description provided for @dhikrScreen_burdenUsAsThose.
  ///
  /// In en, this message translates to:
  /// **'t burden us as those before were burdened'**
  String get dhikrScreen_burdenUsAsThose;

  /// No description provided for @dhikrScreen_mercyPardonForgivenessVictory.
  ///
  /// In en, this message translates to:
  /// **'Mercy, pardon, forgiveness, victory'**
  String get dhikrScreen_mercyPardonForgivenessVictory;

  /// No description provided for @dhikrScreen_keepTheHeartFirm_9c4efb.
  ///
  /// In en, this message translates to:
  /// **'Keep the heart firm after guidance'**
  String get dhikrScreen_keepTheHeartFirm_9c4efb;

  /// No description provided for @dhikrScreen_allahNeverFailsHis.
  ///
  /// In en, this message translates to:
  /// **'Allah never fails His promise'**
  String get dhikrScreen_allahNeverFailsHis;

  /// No description provided for @dhikrScreen_faithAnsweredWithForgiveness_3f30c4.
  ///
  /// In en, this message translates to:
  /// **'Faith answered with forgiveness from Fire'**
  String get dhikrScreen_faithAnsweredWithForgiveness_3f30c4;

  /// No description provided for @dhikrScreen_recordUsWithThe.
  ///
  /// In en, this message translates to:
  /// **'Record us with the witnesses of truth'**
  String get dhikrScreen_recordUsWithThe;

  /// No description provided for @dhikrScreen_forgivenessFirmnessAndVictory.
  ///
  /// In en, this message translates to:
  /// **'Forgiveness, firmness, and victory'**
  String get dhikrScreen_forgivenessFirmnessAndVictory;

  /// No description provided for @dhikrScreen_creationHasPurposeRefuge.
  ///
  /// In en, this message translates to:
  /// **'Creation has purpose — refuge from the Fire'**
  String get dhikrScreen_creationHasPurposeRefuge;

  /// No description provided for @dhikrScreen_refugeFromTheDisgrace.
  ///
  /// In en, this message translates to:
  /// **'Refuge from the disgrace of the Fire'**
  String get dhikrScreen_refugeFromTheDisgrace;

  /// No description provided for @dhikrScreen_heardBelievedAskingForgiveness.
  ///
  /// In en, this message translates to:
  /// **'Heard, believed, asking forgiveness'**
  String get dhikrScreen_heardBelievedAskingForgiveness;

  /// No description provided for @dhikrScreen_sinsForgivenDeathAmong.
  ///
  /// In en, this message translates to:
  /// **'Sins forgiven — death among the righteous'**
  String get dhikrScreen_sinsForgivenDeathAmong;

  /// No description provided for @dhikrScreen_promisedRewardNeverDisgraced.
  ///
  /// In en, this message translates to:
  /// **'Promised reward — never disgraced on Resurrection'**
  String get dhikrScreen_promisedRewardNeverDisgraced;

  /// No description provided for @dhikrScreen_inscribedWithTheWitnesses_e2612d.
  ///
  /// In en, this message translates to:
  /// **'Inscribed with the witnesses of truth'**
  String get dhikrScreen_inscribedWithTheWitnesses_e2612d;

  /// No description provided for @dhikrScreen_provisionAndSignsFrom.
  ///
  /// In en, this message translates to:
  /// **'Provision and signs from the heavens'**
  String get dhikrScreen_provisionAndSignsFrom;

  /// No description provided for @dhikrScreen_duaTheDuaOf.
  ///
  /// In en, this message translates to:
  /// **'s dua — the dua of every repentant'**
  String get dhikrScreen_duaTheDuaOf;

  /// No description provided for @dhikrScreen_spareUsFromThe.
  ///
  /// In en, this message translates to:
  /// **'Spare us from the company of wrongdoers'**
  String get dhikrScreen_spareUsFromThe;

  /// No description provided for @dhikrScreen_allahIsTheBest_4f2bf7.
  ///
  /// In en, this message translates to:
  /// **'Allah is the best judge between truth and lie'**
  String get dhikrScreen_allahIsTheBest_4f2bf7;

  /// No description provided for @dhikrScreen_patienceTillTheEnd.
  ///
  /// In en, this message translates to:
  /// **'Patience till the end, death upon submission'**
  String get dhikrScreen_patienceTillTheEnd;

  /// No description provided for @dhikrScreen_neverTrialForThe_5eb10a.
  ///
  /// In en, this message translates to:
  /// **'Never a trial for the disbelievers'**
  String get dhikrScreen_neverTrialForThe_5eb10a;

  /// No description provided for @dhikrScreen_hiddenInEveryChest.
  ///
  /// In en, this message translates to:
  /// **'s hidden in every chest'**
  String get dhikrScreen_hiddenInEveryChest;

  /// No description provided for @dhikrScreen_prayerForPrayerAccepted.
  ///
  /// In en, this message translates to:
  /// **'s prayer for prayer accepted'**
  String get dhikrScreen_prayerForPrayerAccepted;

  /// No description provided for @dhikrScreen_mercyGrantedGuidancePrepared.
  ///
  /// In en, this message translates to:
  /// **'Mercy granted, guidance prepared'**
  String get dhikrScreen_mercyGrantedGuidancePrepared;

  /// No description provided for @dhikrScreen_duaBeforePharaoh.
  ///
  /// In en, this message translates to:
  /// **'s dua before Pharaoh'**
  String get dhikrScreen_duaBeforePharaoh;

  /// No description provided for @dhikrScreen_refugeFromClingingEvil.
  ///
  /// In en, this message translates to:
  /// **'Refuge from a clinging, evil punishment'**
  String get dhikrScreen_refugeFromClingingEvil;

  /// No description provided for @dhikrScreen_piousSpousesRighteousChildren.
  ///
  /// In en, this message translates to:
  /// **'Pious spouses, righteous children, leadership'**
  String get dhikrScreen_piousSpousesRighteousChildren;

  /// No description provided for @dhikrScreen_allahIsEverThankful.
  ///
  /// In en, this message translates to:
  /// **'Allah is ever-thankful for every effort'**
  String get dhikrScreen_allahIsEverThankful;

  /// No description provided for @dhikrScreen_mercyEncompassingEveryRepentant.
  ///
  /// In en, this message translates to:
  /// **'Mercy encompassing every repentant soul'**
  String get dhikrScreen_mercyEncompassingEveryRepentant;

  /// No description provided for @dhikrScreen_mercyOnThatDay.
  ///
  /// In en, this message translates to:
  /// **'Mercy on that Day — the great success'**
  String get dhikrScreen_mercyOnThatDay;

  /// No description provided for @dhikrScreen_loveAndForgivenessFor.
  ///
  /// In en, this message translates to:
  /// **'Love and forgiveness for earlier believers'**
  String get dhikrScreen_loveAndForgivenessFor;

  /// No description provided for @dhikrScreen_kindnessAndMercyUpon.
  ///
  /// In en, this message translates to:
  /// **'Kindness and mercy upon Allah\\'**
  String get dhikrScreen_kindnessAndMercyUpon;

  /// No description provided for @dhikrScreen_pureTawakkulToYou.
  ///
  /// In en, this message translates to:
  /// **'s pure tawakkul — to You we return'**
  String get dhikrScreen_pureTawakkulToYou;

  /// No description provided for @dhikrScreen_neverFitnahForThose.
  ///
  /// In en, this message translates to:
  /// **'Never a fitnah for those who disbelieve'**
  String get dhikrScreen_neverFitnahForThose;

  /// No description provided for @dhikrScreen_completeTheLightForgive.
  ///
  /// In en, this message translates to:
  /// **'Complete the light — forgive us'**
  String get dhikrScreen_completeTheLightForgive;

  /// No description provided for @dhikrScreen_strongerThanServantThe.
  ///
  /// In en, this message translates to:
  /// **'Stronger than a servant — the night\\'**
  String get dhikrScreen_strongerThanServantThe;

  /// No description provided for @dhikrScreen_refugeFromEveryVisible.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every visible evil before sleep'**
  String get dhikrScreen_refugeFromEveryVisible;

  /// No description provided for @dhikrScreen_refugeFromEveryWhisper.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every whisper before sleep'**
  String get dhikrScreen_refugeFromEveryWhisper;

  /// No description provided for @dhikrScreen_guardedByAnAngel.
  ///
  /// In en, this message translates to:
  /// **'Guarded by an angel until morning'**
  String get dhikrScreen_guardedByAnAngel;

  /// No description provided for @dhikrScreen_twoVersesThatSuffice.
  ///
  /// In en, this message translates to:
  /// **'Two verses that suffice for the whole night'**
  String get dhikrScreen_twoVersesThatSuffice;

  /// No description provided for @dhikrScreen_pureTawheedDeclaredBefore.
  ///
  /// In en, this message translates to:
  /// **'Pure tawheed declared before sleep'**
  String get dhikrScreen_pureTawheedDeclaredBefore;

  /// No description provided for @dhikrScreen_sleepIsSmallDeath.
  ///
  /// In en, this message translates to:
  /// **'Sleep is a small death — entrusted to Allah'**
  String get dhikrScreen_sleepIsSmallDeath;

  /// No description provided for @dhikrScreen_whoeverDiesThatNight.
  ///
  /// In en, this message translates to:
  /// **'Whoever dies that night dies on fitrah'**
  String get dhikrScreen_whoeverDiesThatNight;

  /// No description provided for @dhikrScreen_guardTheSoulThat.
  ///
  /// In en, this message translates to:
  /// **'Guard the soul that returns, or have mercy'**
  String get dhikrScreen_guardTheSoulThat;

  /// No description provided for @dhikrScreen_refugeFromThePunishment.
  ///
  /// In en, this message translates to:
  /// **'Refuge from the punishment of that Day'**
  String get dhikrScreen_refugeFromThePunishment;

  /// No description provided for @dhikrScreen_gratitudeForShelterFood.
  ///
  /// In en, this message translates to:
  /// **'Gratitude for shelter, food, and care'**
  String get dhikrScreen_gratitudeForShelterFood;

  /// No description provided for @dhikrScreen_handOverTheSoul.
  ///
  /// In en, this message translates to:
  /// **'Hand over the soul before sleep'**
  String get dhikrScreen_handOverTheSoul;

  /// No description provided for @dhikrScreen_refugeFromEveryEvil_6d2534.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every evil that grasps'**
  String get dhikrScreen_refugeFromEveryEvil_6d2534;

  /// No description provided for @dhikrScreen_joinTheHighestAssembly.
  ///
  /// In en, this message translates to:
  /// **'Join the highest assembly while you sleep'**
  String get dhikrScreen_joinTheHighestAssembly;

  /// No description provided for @dhikrScreen_gratitudeBeforeClosingThe.
  ///
  /// In en, this message translates to:
  /// **'Gratitude before closing the eyes'**
  String get dhikrScreen_gratitudeBeforeClosingThe;

  /// No description provided for @dhikrScreen_surahAsSajdahRecited.
  ///
  /// In en, this message translates to:
  /// **'Surah As-Sajdah recited before sleep'**
  String get dhikrScreen_surahAsSajdahRecited;

  /// No description provided for @dhikrScreen_refugeFromEvilBefore.
  ///
  /// In en, this message translates to:
  /// **'Refuge from evil before entering the toilet'**
  String get dhikrScreen_refugeFromEvilBefore;

  /// No description provided for @dhikrScreen_seekForgivenessAsYou.
  ///
  /// In en, this message translates to:
  /// **'Seek forgiveness as you leave'**
  String get dhikrScreen_seekForgivenessAsYou;

  /// No description provided for @dhikrScreen_bismillahEveryBiteBegins.
  ///
  /// In en, this message translates to:
  /// **'Bismillah — every bite begins with Allah'**
  String get dhikrScreen_bismillahEveryBiteBegins;

  /// No description provided for @dhikrScreen_catchUpTheName.
  ///
  /// In en, this message translates to:
  /// **'Catch up the name — Allah at start and end'**
  String get dhikrScreen_catchUpTheName;

  /// No description provided for @dhikrScreen_threeSunnahDuasTo.
  ///
  /// In en, this message translates to:
  /// **'Three Sunnah duas to thank Allah after eating'**
  String get dhikrScreen_threeSunnahDuasTo;

  /// No description provided for @dhikrScreen_beginWithAllahThe.
  ///
  /// In en, this message translates to:
  /// **'Begin with Allah, the Most Merciful, before drinking'**
  String get dhikrScreen_beginWithAllahThe;

  /// No description provided for @dhikrScreen_openTheEightDoors.
  ///
  /// In en, this message translates to:
  /// **'Open the eight doors of Paradise after wudu'**
  String get dhikrScreen_openTheEightDoors;

  /// No description provided for @dhikrScreen_openTheDoorsOf.
  ///
  /// In en, this message translates to:
  /// **'Open the doors of Allah\\'**
  String get dhikrScreen_openTheDoorsOf;

  /// No description provided for @dhikrScreen_bountyAsYouLeave.
  ///
  /// In en, this message translates to:
  /// **'s bounty as you leave the masjid'**
  String get dhikrScreen_bountyAsYouLeave;

  /// No description provided for @dhikrScreen_mayAllahGuideYou.
  ///
  /// In en, this message translates to:
  /// **'May Allah guide you and rectify your state'**
  String get dhikrScreen_mayAllahGuideYou;

  /// No description provided for @dhikrScreen_askAllahLordOf.
  ///
  /// In en, this message translates to:
  /// **'Ask Allah, Lord of the Throne, to grant healing'**
  String get dhikrScreen_askAllahLordOf;

  /// No description provided for @dhikrScreen_allahIsTheOnly.
  ///
  /// In en, this message translates to:
  /// **'Allah is the only One who cures'**
  String get dhikrScreen_allahIsTheOnly;

  /// No description provided for @dhikrScreen_shieldChildrenWithAllah.
  ///
  /// In en, this message translates to:
  /// **'Shield children with Allah\\'**
  String get dhikrScreen_shieldChildrenWithAllah;

  /// No description provided for @dhikrScreen_anicPrayerForOne.
  ///
  /// In en, this message translates to:
  /// **'anic prayer for one\\'**
  String get dhikrScreen_anicPrayerForOne;

  /// No description provided for @dhikrScreen_twoPhrasesBelovedTo.
  ///
  /// In en, this message translates to:
  /// **'Two phrases beloved to the Most Merciful'**
  String get dhikrScreen_twoPhrasesBelovedTo;

  /// No description provided for @dhikrScreen_allahLovesToPardon.
  ///
  /// In en, this message translates to:
  /// **'Allah loves to pardon — so ask'**
  String get dhikrScreen_allahLovesToPardon;

  /// No description provided for @dhikrScreen_treasureFromBeneathThe.
  ///
  /// In en, this message translates to:
  /// **'A treasure from beneath the Throne'**
  String get dhikrScreen_treasureFromBeneathThe;

  /// No description provided for @dhikrScreen_theFourPhrasesDearest.
  ///
  /// In en, this message translates to:
  /// **'The four phrases dearest to Allah'**
  String get dhikrScreen_theFourPhrasesDearest;

  /// No description provided for @dhikrScreen_theDuaThatReleases.
  ///
  /// In en, this message translates to:
  /// **'The dua that releases from every distress'**
  String get dhikrScreen_theDuaThatReleases;

  /// No description provided for @dhikrScreen_protectionForHomeAnd.
  ///
  /// In en, this message translates to:
  /// **'s protection for home and offspring'**
  String get dhikrScreen_protectionForHomeAnd;

  /// No description provided for @dhikrScreen_theCompleteDhikrOf.
  ///
  /// In en, this message translates to:
  /// **'The complete dhikr of Tawheed'**
  String get dhikrScreen_theCompleteDhikrOf;

  /// No description provided for @dhikrScreen_trialPurifiedByAllah.
  ///
  /// In en, this message translates to:
  /// **'Trial purified by Allah\\'**
  String get dhikrScreen_trialPurifiedByAllah;

  /// No description provided for @dhikrScreen_guidanceBeforeAnyChoice.
  ///
  /// In en, this message translates to:
  /// **'s guidance before any choice'**
  String get dhikrScreen_guidanceBeforeAnyChoice;

  /// No description provided for @dhikrScreen_completeRuqyaSequenceFatihah.
  ///
  /// In en, this message translates to:
  /// **'Complete ruqya sequence — Fatihah and refuge'**
  String get dhikrScreen_completeRuqyaSequenceFatihah;

  /// No description provided for @dhikrScreen_sinsForgivenEvenIf.
  ///
  /// In en, this message translates to:
  /// **'Sins forgiven, even if like the foam of the sea'**
  String get dhikrScreen_sinsForgivenEvenIf;

  /// No description provided for @dhikrScreen_freedHasanatSinsErased.
  ///
  /// In en, this message translates to:
  /// **'10 freed · 100 hasanat · 100 sins erased · Shaytan repelled'**
  String get dhikrScreen_freedHasanatSinsErased;

  /// No description provided for @dhikrScreen_blessingsDescendFromAllah.
  ///
  /// In en, this message translates to:
  /// **'10 blessings descend from Allah upon you'**
  String get dhikrScreen_blessingsDescendFromAllah;

  /// No description provided for @dhikrScreen_askAllahToBless.
  ///
  /// In en, this message translates to:
  /// **'Ask Allah to bless and beautify your day'**
  String get dhikrScreen_askAllahToBless;

  /// No description provided for @dhikrScreen_guaranteedJannahIfYou.
  ///
  /// In en, this message translates to:
  /// **'Guaranteed Jannah, if you die this day'**
  String get dhikrScreen_guaranteedJannahIfYou;

  /// No description provided for @dhikrScreen_guaranteedJannahIfYou_48d274.
  ///
  /// In en, this message translates to:
  /// **'Guaranteed Jannah, if you die this night'**
  String get dhikrScreen_guaranteedJannahIfYou_48d274;

  /// No description provided for @dhikrScreen_yourLifeEntrustedTo.
  ///
  /// In en, this message translates to:
  /// **'Your life entrusted to the Ever-Living'**
  String get dhikrScreen_yourLifeEntrustedTo;

  /// No description provided for @dhikrScreen_allEvilInHis.
  ///
  /// In en, this message translates to:
  /// **'All evil in His creation repelled from you'**
  String get dhikrScreen_allEvilInHis;

  /// No description provided for @dhikrScreen_nothingShallHarmYou.
  ///
  /// In en, this message translates to:
  /// **'Nothing shall harm you, by perfect words'**
  String get dhikrScreen_nothingShallHarmYou;

  /// No description provided for @dhikrScreen_shieldYourselfFromMinor.
  ///
  /// In en, this message translates to:
  /// **'Shield yourself from minor and major shirk, morning & evening'**
  String get dhikrScreen_shieldYourselfFromMinor;

  /// No description provided for @dhikrScreen_completeProtectionInThe.
  ///
  /// In en, this message translates to:
  /// **'Complete protection in the name of Allah'**
  String get dhikrScreen_completeProtectionInThe;

  /// No description provided for @dhikrScreen_weightierThanAllVoluntary.
  ///
  /// In en, this message translates to:
  /// **'Weightier than all voluntary prayers, from dawn till dusk'**
  String get dhikrScreen_weightierThanAllVoluntary;

  /// No description provided for @dhikrScreen_reciteMorningEveningEarn.
  ///
  /// In en, this message translates to:
  /// **'Recite morning & evening, earn the pleasure & blessing of Allah on the Day of Judgment'**
  String get dhikrScreen_reciteMorningEveningEarn;

  /// No description provided for @dhikrScreen_yourRewardAwaitsDirectly.
  ///
  /// In en, this message translates to:
  /// **'Your reward awaits directly with Allah when you meet Him'**
  String get dhikrScreen_yourRewardAwaitsDirectly;

  /// No description provided for @dhikrScreen_reciteMorningEveningTo.
  ///
  /// In en, this message translates to:
  /// **'Recite morning & evening to fulfill your obligation of gratitude to Allah'**
  String get dhikrScreen_reciteMorningEveningTo;

  /// No description provided for @dhikrScreen_theProphetTaughtThis.
  ///
  /// In en, this message translates to:
  /// **'The Prophet taught this dua for morning and evening, do not miss it'**
  String get dhikrScreen_theProphetTaughtThis;

  /// No description provided for @dhikrScreen_dominionAtTheStart.
  ///
  /// In en, this message translates to:
  /// **'s dominion at the start of your morning, all kingdom belongs to Him'**
  String get dhikrScreen_dominionAtTheStart;

  /// No description provided for @dhikrScreen_asEveningFallsThe.
  ///
  /// In en, this message translates to:
  /// **'As evening falls, the entire kingdom belongs to Allah alone'**
  String get dhikrScreen_asEveningFallsThe;

  /// No description provided for @dhikrScreen_endYourEveningUpon.
  ///
  /// In en, this message translates to:
  /// **'End your evening upon the pure fitrah, as the Prophet (ﷺ) taught'**
  String get dhikrScreen_endYourEveningUpon;

  /// No description provided for @dhikrScreen_satanWillNotEnter.
  ///
  /// In en, this message translates to:
  /// **'Satan will not enter the home of one who recites this'**
  String get dhikrScreen_satanWillNotEnter;

  /// No description provided for @dhikrScreen_readingLastVersesOf.
  ///
  /// In en, this message translates to:
  /// **'Reading last 2 verses of al-Baqarah will suffice you'**
  String get dhikrScreen_readingLastVersesOf;

  /// No description provided for @dhikrScreen_everyDuaInThis.
  ///
  /// In en, this message translates to:
  /// **'Every dua in this verse - Allah said: I have done so'**
  String get dhikrScreen_everyDuaInThis;

  /// No description provided for @dhikrScreen_guardedByAllahUntil.
  ///
  /// In en, this message translates to:
  /// **'Guarded by Allah until morning comes'**
  String get dhikrScreen_guardedByAllahUntil;

  /// No description provided for @dhikrScreen_recitingEqualsReadingThe.
  ///
  /// In en, this message translates to:
  /// **'Reciting 3x equals reading the entire Quran, Bukhari & Muslim'**
  String get dhikrScreen_recitingEqualsReadingThe;

  /// No description provided for @dhikrScreen_reciteAtDawnDusk.
  ///
  /// In en, this message translates to:
  /// **'Recite 3x at dawn & dusk, suffice you against all harm'**
  String get dhikrScreen_reciteAtDawnDusk;

  /// No description provided for @dhikrScreen_reciteAtDawnDusk_f17fb8.
  ///
  /// In en, this message translates to:
  /// **'Recite 3x at dawn & dusk, it will suffice you in all respects'**
  String get dhikrScreen_reciteAtDawnDusk_f17fb8;

  /// No description provided for @dhikrScreen_refugeFromTheWhisperer.
  ///
  /// In en, this message translates to:
  /// **'Refuge from the whisperer, in the Lord of Mankind'**
  String get dhikrScreen_refugeFromTheWhisperer;

  /// No description provided for @dhikrScreen_reciteMorningEveningYour.
  ///
  /// In en, this message translates to:
  /// **'Recite 3x morning & evening, your gratitude to Allah is fulfilled'**
  String get dhikrScreen_reciteMorningEveningYour;

  /// No description provided for @dhikrScreen_sufficientAgainstEveryHarm.
  ///
  /// In en, this message translates to:
  /// **'Sufficient against every harm recited 3 times'**
  String get dhikrScreen_sufficientAgainstEveryHarm;

  /// No description provided for @dhikrScreen_doorsOfAllahMercy.
  ///
  /// In en, this message translates to:
  /// **'Doors of Allah mercy open wide for you'**
  String get dhikrScreen_doorsOfAllahMercy;

  /// No description provided for @dhikrScreen_worryAndSorrowLifted.
  ///
  /// In en, this message translates to:
  /// **'Worry and sorrow lifted by the will of Allah'**
  String get dhikrScreen_worryAndSorrowLifted;

  /// No description provided for @dhikrScreen_guardedInYourDeen.
  ///
  /// In en, this message translates to:
  /// **'Guarded in your deen dunya and akhirah'**
  String get dhikrScreen_guardedInYourDeen;

  /// No description provided for @dhikrScreen_evilRepelledFromEvery.
  ///
  /// In en, this message translates to:
  /// **'Evil repelled from every direction'**
  String get dhikrScreen_evilRepelledFromEvery;

  /// No description provided for @dhikrScreen_heartHeldByThe.
  ///
  /// In en, this message translates to:
  /// **'Heart held by the Ever Living Ever Sustaining'**
  String get dhikrScreen_heartHeldByThe;

  /// No description provided for @dhikrScreen_fulfilledYourObligationOf.
  ///
  /// In en, this message translates to:
  /// **'Fulfilled your obligation of giving thanks'**
  String get dhikrScreen_fulfilledYourObligationOf;

  /// No description provided for @dhikrScreen_recitingTheLastVerses.
  ///
  /// In en, this message translates to:
  /// **'Reciting the last 2 verses of Al-Baqarah at night suffices you'**
  String get dhikrScreen_recitingTheLastVerses;

  /// No description provided for @dhikrScreen_gratitudeThatMultipliesYour.
  ///
  /// In en, this message translates to:
  /// **'Gratitude that multiplies your blessings'**
  String get dhikrScreen_gratitudeThatMultipliesYour;

  /// No description provided for @dhikrScreen_startPureOnThe.
  ///
  /// In en, this message translates to:
  /// **'Start pure on the fitrah of Islam'**
  String get dhikrScreen_startPureOnThe;

  /// No description provided for @dhikrScreen_praiseThatRipplesThrough.
  ///
  /// In en, this message translates to:
  /// **'Praise that ripples through all creation'**
  String get dhikrScreen_praiseThatRipplesThrough;

  /// No description provided for @dhikrScreen_guidedToEveryGood.
  ///
  /// In en, this message translates to:
  /// **'Guided to every good this day'**
  String get dhikrScreen_guidedToEveryGood;

  /// No description provided for @dhikrScreen_nothingShallHarmYou_8c5c6c.
  ///
  /// In en, this message translates to:
  /// **'Nothing shall harm you by His name'**
  String get dhikrScreen_nothingShallHarmYou_8c5c6c;

  /// No description provided for @dhikrScreen_allahWillFreeHim.
  ///
  /// In en, this message translates to:
  /// **'Allah will free him from the Fire who reads this 4 times'**
  String get dhikrScreen_allahWillFreeHim;

  /// No description provided for @dhikrScreen_guaranteedJannahIfYou_0ffafe.
  ///
  /// In en, this message translates to:
  /// **'Guaranteed Jannah if you die today'**
  String get dhikrScreen_guaranteedJannahIfYou_0ffafe;

  /// No description provided for @dhikrScreen_wellbeingOfBodyHearing.
  ///
  /// In en, this message translates to:
  /// **'Wellbeing of body hearing and sight'**
  String get dhikrScreen_wellbeingOfBodyHearing;

  /// No description provided for @dhikrScreen_guidedByTheHand.
  ///
  /// In en, this message translates to:
  /// **'Guided by the hand of Allah'**
  String get dhikrScreen_guidedByTheHand;

  /// No description provided for @dhikrScreen_wordsHeavierThanThe.
  ///
  /// In en, this message translates to:
  /// **'Words heavier than the heavens and earth'**
  String get dhikrScreen_wordsHeavierThanThe;

  /// No description provided for @dhikrScreen_beginYourDayIn.
  ///
  /// In en, this message translates to:
  /// **'Begin your day in surrender to Allah'**
  String get dhikrScreen_beginYourDayIn;

  /// No description provided for @dhikrScreen_theyAreEnoughFor.
  ///
  /// In en, this message translates to:
  /// **'They are enough for you - recite before sleep'**
  String get dhikrScreen_theyAreEnoughFor;

  /// No description provided for @dhikrScreen_guardedInYourDeen_4a0b4a.
  ///
  /// In en, this message translates to:
  /// **'Guarded in your Deen · Dunya · Akhirah, and from all six sides'**
  String get dhikrScreen_guardedInYourDeen_4a0b4a;

  /// No description provided for @dhikrScreen_wellBeing.
  ///
  /// In en, this message translates to:
  /// **'Well-being'**
  String get dhikrScreen_wellBeing;

  /// No description provided for @dhikrScreen_fulfilled.
  ///
  /// In en, this message translates to:
  /// **'Fulfilled.'**
  String get dhikrScreen_fulfilled;

  /// No description provided for @dhikrScreen_wellBeingInFaith.
  ///
  /// In en, this message translates to:
  /// **'Well-being in Faith · Family · Wealth'**
  String get dhikrScreen_wellBeingInFaith;

  /// No description provided for @dhikrScreen_concealMyFaultsCalm.
  ///
  /// In en, this message translates to:
  /// **'Conceal my faults · Calm my fears'**
  String get dhikrScreen_concealMyFaultsCalm;

  /// No description provided for @dhikrScreen_guardMeFromAll.
  ///
  /// In en, this message translates to:
  /// **'Guard me from all six sides'**
  String get dhikrScreen_guardMeFromAll;

  /// No description provided for @dhikrScreen_protectionFromEvilEye.
  ///
  /// In en, this message translates to:
  /// **'Protection from Evil Eye'**
  String get dhikrScreen_protectionFromEvilEye;

  /// No description provided for @dhikrScreen_doNotLeaveMe.
  ///
  /// In en, this message translates to:
  /// **'Do not leave me to myself\\neven for the blink of an eye'**
  String get dhikrScreen_doNotLeaveMe;

  /// No description provided for @dhikrScreen_35c165.
  ///
  /// In en, this message translates to:
  /// **'{arg1}  '**
  String dhikrScreen_35c165(String arg1);

  /// No description provided for @dhikrScreen_allahWillSufficeYou.
  ///
  /// In en, this message translates to:
  /// **'Allah will suffice you'**
  String get dhikrScreen_allahWillSufficeYou;

  /// No description provided for @dhikrScreen_againstWhateverConcernsYou.
  ///
  /// In en, this message translates to:
  /// **'against whatever concerns you'**
  String get dhikrScreen_againstWhateverConcernsYou;

  /// No description provided for @dhikrScreen_sinsWashedAway.
  ///
  /// In en, this message translates to:
  /// **'Sins Washed Away'**
  String get dhikrScreen_sinsWashedAway;

  /// No description provided for @dhikrScreen_slavesFreed.
  ///
  /// In en, this message translates to:
  /// **'Slaves Freed'**
  String get dhikrScreen_slavesFreed;

  /// No description provided for @dhikrScreen_doNotBurdenUs.
  ///
  /// In en, this message translates to:
  /// **'Do not burden us beyond what we can bear, pardon us and have mercy'**
  String get dhikrScreen_doNotBurdenUs;

  /// No description provided for @dhikrScreen_weHaveBelievedForgive.
  ///
  /// In en, this message translates to:
  /// **'We have believed — forgive our sins and protect us from the Fire'**
  String get dhikrScreen_weHaveBelievedForgive;

  /// No description provided for @dhikrScreen_ownerOfSovereigntyIn.
  ///
  /// In en, this message translates to:
  /// **'O Owner of Sovereignty — in Your Hand is all good, You are Most Capable'**
  String get dhikrScreen_ownerOfSovereigntyIn;

  /// No description provided for @dhikrScreen_forgiveOurSinsAnd.
  ///
  /// In en, this message translates to:
  /// **'Forgive our sins and excess, make us firm and grant us victory'**
  String get dhikrScreen_forgiveOurSinsAnd;

  /// No description provided for @dhikrScreen_youCreatedNotIn.
  ///
  /// In en, this message translates to:
  /// **'You created not in vain — protect us from the punishment of the Fire'**
  String get dhikrScreen_youCreatedNotIn;

  /// No description provided for @dhikrScreen_weHaveWrongedOurselves.
  ///
  /// In en, this message translates to:
  /// **'We have wronged ourselves — without Your mercy we are lost'**
  String get dhikrScreen_weHaveWrongedOurselves;

  /// No description provided for @dhikrScreen_ourLordDoNot.
  ///
  /// In en, this message translates to:
  /// **'Our Lord, do not place us with the wrongdoing people'**
  String get dhikrScreen_ourLordDoNot;

  /// No description provided for @dhikrScreen_doNotMakeUs.
  ///
  /// In en, this message translates to:
  /// **'Do not make us a trial for the oppressors'**
  String get dhikrScreen_doNotMakeUs;

  /// No description provided for @dhikrScreen_makeMeSteadfastIn.
  ///
  /// In en, this message translates to:
  /// **'Make me steadfast in prayer — and my descendants too'**
  String get dhikrScreen_makeMeSteadfastIn;

  /// No description provided for @dhikrScreen_forgiveMeMyParents.
  ///
  /// In en, this message translates to:
  /// **'Forgive me, my parents, and the believers on the Day of Reckoning'**
  String get dhikrScreen_forgiveMeMyParents;

  /// No description provided for @dhikrScreen_bringMeInBy.
  ///
  /// In en, this message translates to:
  /// **'Bring me in by an entrance of truth and out by an exit of truth'**
  String get dhikrScreen_bringMeInBy;

  /// No description provided for @dhikrScreen_myLordIncreaseMe.
  ///
  /// In en, this message translates to:
  /// **'My Lord, increase me in knowledge'**
  String get dhikrScreen_myLordIncreaseMe;

  /// No description provided for @dhikrScreen_seekRefugeInYou.
  ///
  /// In en, this message translates to:
  /// **'I seek refuge in You from the whispers of devils'**
  String get dhikrScreen_seekRefugeInYou;

  /// No description provided for @dhikrScreen_weHaveBelievedForgive_e958e6.
  ///
  /// In en, this message translates to:
  /// **'We have believed — forgive us, You are the Best of the Merciful'**
  String get dhikrScreen_weHaveBelievedForgive_e958e6;

  /// No description provided for @dhikrScreen_forgiveAndHaveMercy.
  ///
  /// In en, this message translates to:
  /// **'Forgive and have mercy — You are the Best of the Merciful'**
  String get dhikrScreen_forgiveAndHaveMercy;

  /// No description provided for @dhikrScreen_enableMeToBe.
  ///
  /// In en, this message translates to:
  /// **'Enable me to be grateful for Your favour on me and my parents'**
  String get dhikrScreen_enableMeToBe;

  /// No description provided for @dhikrScreen_myLordHaveWronged.
  ///
  /// In en, this message translates to:
  /// **'My Lord, I have wronged myself — so forgive me'**
  String get dhikrScreen_myLordHaveWronged;

  /// No description provided for @dhikrScreen_myLordWillNever.
  ///
  /// In en, this message translates to:
  /// **'My Lord, I will never be a supporter of the criminals'**
  String get dhikrScreen_myLordWillNever;

  /// No description provided for @dhikrScreen_myLordSaveMe.
  ///
  /// In en, this message translates to:
  /// **'My Lord, save me from the wrongdoing people'**
  String get dhikrScreen_myLordSaveMe;

  /// No description provided for @dhikrScreen_myLordAmIn.
  ///
  /// In en, this message translates to:
  /// **'My Lord, I am in need of any good You send down to me'**
  String get dhikrScreen_myLordAmIn;

  /// No description provided for @dhikrScreen_myLordHelpMe.
  ///
  /// In en, this message translates to:
  /// **'My Lord, help me against the corrupting people'**
  String get dhikrScreen_myLordHelpMe;

  /// No description provided for @dhikrScreen_ourLordAvertFrom.
  ///
  /// In en, this message translates to:
  /// **'Our Lord, avert from us the punishment of Hell'**
  String get dhikrScreen_ourLordAvertFrom;

  /// No description provided for @dhikrScreen_ourLordYouEncompass.
  ///
  /// In en, this message translates to:
  /// **'Our Lord, You encompass all things in mercy and knowledge'**
  String get dhikrScreen_ourLordYouEncompass;

  /// No description provided for @dhikrScreen_enableMeToThank.
  ///
  /// In en, this message translates to:
  /// **'Enable me to thank You and make my offspring righteous'**
  String get dhikrScreen_enableMeToThank;

  /// No description provided for @dhikrScreen_myLordGrantMe.
  ///
  /// In en, this message translates to:
  /// **'My Lord, grant me of the righteous'**
  String get dhikrScreen_myLordGrantMe;

  /// No description provided for @dhikrScreen_forgiveUsAndOur.
  ///
  /// In en, this message translates to:
  /// **'Forgive us and our brothers who came before us in faith'**
  String get dhikrScreen_forgiveUsAndOur;

  /// No description provided for @dhikrScreen_uponYouWeRely.
  ///
  /// In en, this message translates to:
  /// **'Upon You we rely, to You we turn, and to You is the destination'**
  String get dhikrScreen_uponYouWeRely;

  /// No description provided for @dhikrScreen_pauseRememberAllah.
  ///
  /// In en, this message translates to:
  /// **'Pause. Remember Allah.'**
  String get dhikrScreen_pauseRememberAllah;

  /// No description provided for @dhikrScreen_mashaallahRewardSecured.
  ///
  /// In en, this message translates to:
  /// **'MashaAllah! Reward Secured'**
  String get dhikrScreen_mashaallahRewardSecured;

  /// No description provided for @dhikrScreen_satanCannot.
  ///
  /// In en, this message translates to:
  /// **'Satan cannot'**
  String get dhikrScreen_satanCannot;

  /// No description provided for @dhikrScreen_enterTheHome.
  ///
  /// In en, this message translates to:
  /// **'enter the home'**
  String get dhikrScreen_enterTheHome;

  /// No description provided for @dhikrScreen_whoeverRecites.
  ///
  /// In en, this message translates to:
  /// **'Whoever recites'**
  String get dhikrScreen_whoeverRecites;

  /// No description provided for @dhikrScreen_theLastTwoVerses.
  ///
  /// In en, this message translates to:
  /// **'the last two verses'**
  String get dhikrScreen_theLastTwoVerses;

  /// No description provided for @dhikrScreen_ofSurahAlBaqarah.
  ///
  /// In en, this message translates to:
  /// **'of Surah Al-Baqarah'**
  String get dhikrScreen_ofSurahAlBaqarah;

  /// No description provided for @dhikrScreen_atNight.
  ///
  /// In en, this message translates to:
  /// **'at night --'**
  String get dhikrScreen_atNight;

  /// No description provided for @dhikrScreen_theyWillBe.
  ///
  /// In en, this message translates to:
  /// **'they will be'**
  String get dhikrScreen_theyWillBe;

  /// No description provided for @dhikrScreen_enoughForHim.
  ///
  /// In en, this message translates to:
  /// **'enough for him'**
  String get dhikrScreen_enoughForHim;

  /// No description provided for @dhikrScreen_weHaveEnteredThe.
  ///
  /// In en, this message translates to:
  /// **'We have entered the evening'**
  String get dhikrScreen_weHaveEnteredThe;

  /// No description provided for @dhikrScreen_theKingdomBelongsTo.
  ///
  /// In en, this message translates to:
  /// **'The Kingdom belongs to Allah'**
  String get dhikrScreen_theKingdomBelongsTo;

  /// No description provided for @dhikrScreen_noneWorthyOfWorship.
  ///
  /// In en, this message translates to:
  /// **'None worthy of worship but Allah alone'**
  String get dhikrScreen_noneWorthyOfWorship;

  /// No description provided for @dhikrScreen_allPraiseHeIs.
  ///
  /// In en, this message translates to:
  /// **'All praise · He is All-Powerful over everything'**
  String get dhikrScreen_allPraiseHeIs;

  /// No description provided for @dhikrScreen_weAskForThe.
  ///
  /// In en, this message translates to:
  /// **'We ask for the good of this night'**
  String get dhikrScreen_weAskForThe;

  /// No description provided for @dhikrScreen_saySeekRefuge.
  ///
  /// In en, this message translates to:
  /// **'Say: I seek refuge'**
  String get dhikrScreen_saySeekRefuge;

  /// No description provided for @dhikrScreen_inTheLordOf.
  ///
  /// In en, this message translates to:
  /// **'in the Lord of Mankind'**
  String get dhikrScreen_inTheLordOf;

  /// No description provided for @dhikrScreen_theKingOfMankind.
  ///
  /// In en, this message translates to:
  /// **'the King of Mankind'**
  String get dhikrScreen_theKingOfMankind;

  /// No description provided for @dhikrScreen_theGodOfMankind.
  ///
  /// In en, this message translates to:
  /// **'the God of Mankind ,'**
  String get dhikrScreen_theGodOfMankind;

  /// No description provided for @dhikrScreen_heRetreatsWhenYou.
  ///
  /// In en, this message translates to:
  /// **'He retreats when you remember Allah.'**
  String get dhikrScreen_heRetreatsWhenYou;

  /// No description provided for @dhikrScreen_seekRefugeInThe.
  ///
  /// In en, this message translates to:
  /// **'Seek refuge in the Lord of Daybreak'**
  String get dhikrScreen_seekRefugeInThe;

  /// No description provided for @dhikrScreen_sufficedInAllRespects.
  ///
  /// In en, this message translates to:
  /// **'Sufficed in all respects.'**
  String get dhikrScreen_sufficedInAllRespects;

  /// No description provided for @dhikrScreen_allahDoesNotBurden.
  ///
  /// In en, this message translates to:
  /// **'Allah does not burden'**
  String get dhikrScreen_allahDoesNotBurden;

  /// No description provided for @dhikrScreen_soul.
  ///
  /// In en, this message translates to:
  /// **'a soul'**
  String get dhikrScreen_soul;

  /// No description provided for @dhikrScreen_a5cfd1.
  ///
  /// In en, this message translates to:
  /// **'×{count}'**
  String dhikrScreen_a5cfd1(String count);

  /// No description provided for @dhikrScreen_equalsTheWholeQuran.
  ///
  /// In en, this message translates to:
  /// **'Equals the whole Quran × 3'**
  String get dhikrScreen_equalsTheWholeQuran;

  /// No description provided for @dhikrScreen_completeToWatchYour.
  ///
  /// In en, this message translates to:
  /// **'Complete to watch your garden bloom above'**
  String get dhikrScreen_completeToWatchYour;

  /// No description provided for @impactReportScreen_whoeverDoesAnAtom.
  ///
  /// In en, this message translates to:
  /// **'“Whoever does an atom\\'**
  String get impactReportScreen_whoeverDoesAnAtom;

  /// No description provided for @impactReportScreen_theHomeOfThe.
  ///
  /// In en, this message translates to:
  /// **'“The home of the Hereafter — that is the eternal life, if only they knew.” — Surah Al-Ankabut 29:64'**
  String get impactReportScreen_theHomeOfThe;

  /// No description provided for @impactReportScreen_raceTowardsForgivenessFrom.
  ///
  /// In en, this message translates to:
  /// **'“Race towards forgiveness from your Lord and a Garden as wide as the heavens and the earth.” — Surah Al-Hadid 57:21'**
  String get impactReportScreen_raceTowardsForgivenessFrom;

  /// No description provided for @impactReportScreen_andWhatIsThe.
  ///
  /// In en, this message translates to:
  /// **'“And what is the life of this world except amusement of delusion?” — Surah Ali Imran 3:185'**
  String get impactReportScreen_andWhatIsThe;

  /// No description provided for @impactReportScreen_indeedWithHardshipComes.
  ///
  /// In en, this message translates to:
  /// **'“Indeed, with hardship comes ease.” — Surah Ash-Sharh 94:6'**
  String get impactReportScreen_indeedWithHardshipComes;

  /// No description provided for @impactReportScreen_singleGoodDeedIn.
  ///
  /// In en, this message translates to:
  /// **'“A single good deed in Ramadan equals 70 in any other month.” Stack while the door is open.'**
  String get impactReportScreen_singleGoodDeedIn;

  /// No description provided for @impactReportScreen_theProphetSaidCharity.
  ///
  /// In en, this message translates to:
  /// **'The Prophet ✍ said: charity does not decrease wealth — it grows it. (Muslim)'**
  String get impactReportScreen_theProphetSaidCharity;

  /// No description provided for @impactReportScreen_smilingAtYourBrother.
  ///
  /// In en, this message translates to:
  /// **'“Smiling at your brother is sadaqah.” You can earn even when your pockets are empty. (Tirmidhi)'**
  String get impactReportScreen_smilingAtYourBrother;

  /// No description provided for @impactReportScreen_theMostBelovedDeeds.
  ///
  /// In en, this message translates to:
  /// **'“The most beloved deeds to Allah are the most consistent, even if small.” (Bukhari)'**
  String get impactReportScreen_theMostBelovedDeeds;

  /// No description provided for @impactReportScreen_inJannahIsWhat.
  ///
  /// In en, this message translates to:
  /// **'“In Jannah is what no eye has seen, no ear has heard, and no heart has imagined.” (Bukhari)'**
  String get impactReportScreen_inJannahIsWhat;

  /// No description provided for @impactReportScreen_twoRakatsAtFajr.
  ///
  /// In en, this message translates to:
  /// **'Two rakats at Fajr are better than the world and everything in it. (Muslim)'**
  String get impactReportScreen_twoRakatsAtFajr;

  /// No description provided for @impactReportScreen_everyStepTowardSalah.
  ///
  /// In en, this message translates to:
  /// **'Every step toward salah erases a sin and raises a rank. (Muslim)'**
  String get impactReportScreen_everyStepTowardSalah;

  /// No description provided for @impactReportScreen_everySeedYouDonate.
  ///
  /// In en, this message translates to:
  /// **'Every seed you donate plants a tree in someone else\\'**
  String get impactReportScreen_everySeedYouDonate;

  /// No description provided for @impactReportScreen_takeWealthWithYou.
  ///
  /// In en, this message translates to:
  /// **'t take wealth with you. Only the deeds it bought.'**
  String get impactReportScreen_takeWealthWithYou;

  /// No description provided for @impactReportScreen_theAngelsRecordNothing.
  ///
  /// In en, this message translates to:
  /// **'The angels record nothing too small. One Subhanallah may outweigh a mountain.'**
  String get impactReportScreen_theAngelsRecordNothing;

  /// No description provided for @impactReportScreen_sadaqahIsTomorrow.
  ///
  /// In en, this message translates to:
  /// **'s sadaqah is tomorrow\\'**
  String get impactReportScreen_sadaqahIsTomorrow;

  /// No description provided for @impactReportScreen_heartThatGivesIs.
  ///
  /// In en, this message translates to:
  /// **'A heart that gives is a heart Allah keeps full. Don\\'**
  String get impactReportScreen_heartThatGivesIs;

  /// No description provided for @impactReportScreen_theReceiptWhatDid.
  ///
  /// In en, this message translates to:
  /// **'s the receipt. What did you send ahead?'**
  String get impactReportScreen_theReceiptWhatDid;

  /// No description provided for @impactReportScreen_imagineYourScaleOn.
  ///
  /// In en, this message translates to:
  /// **'Imagine your scale on Yawm al-Qiyamah. What weight are you adding today?'**
  String get impactReportScreen_imagineYourScaleOn;

  /// No description provided for @impactReportScreen_theWorldIsBorrowed.
  ///
  /// In en, this message translates to:
  /// **'The world is borrowed. The Akhirah is owned. Invest accordingly.'**
  String get impactReportScreen_theWorldIsBorrowed;

  /// No description provided for @impactReportScreen_youBuryTheBody.
  ///
  /// In en, this message translates to:
  /// **'You bury the body — but not the deeds. Send them ahead while you can.'**
  String get impactReportScreen_youBuryTheBody;

  /// No description provided for @impactReportScreen_righteousChildWhoPrays.
  ///
  /// In en, this message translates to:
  /// **'A righteous child who prays for you, a charity that flows, or knowledge that benefits — three eternal investments. (Muslim)'**
  String get impactReportScreen_righteousChildWhoPrays;

  /// No description provided for @impactReportScreen_youWillMeetAllah.
  ///
  /// In en, this message translates to:
  /// **'You will meet Allah with your record. Make sure today\\'**
  String get impactReportScreen_youWillMeetAllah;

  /// No description provided for @impactReportScreen_noDeedIsToo.
  ///
  /// In en, this message translates to:
  /// **'No deed is too small for the One who counts atoms.'**
  String get impactReportScreen_noDeedIsToo;

  /// No description provided for @impactReportScreen_lvl.
  ///
  /// In en, this message translates to:
  /// **'Lvl {_level} · {arg1}'**
  String impactReportScreen_lvl(String _level, String arg1);

  /// No description provided for @impactReportScreen_200447.
  ///
  /// In en, this message translates to:
  /// **'+{arg1}'**
  String impactReportScreen_200447(String arg1);

  /// No description provided for @impactReportScreen_deedsTODAY.
  ///
  /// In en, this message translates to:
  /// **'DEEDS TODAY'**
  String get impactReportScreen_deedsTODAY;

  /// No description provided for @impactReportScreen_634027.
  ///
  /// In en, this message translates to:
  /// **'+{arg1}'**
  String impactReportScreen_634027(String arg1);

  /// No description provided for @impactReportScreen_thisWEEK.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK'**
  String get impactReportScreen_thisWEEK;

  /// No description provided for @impactReportScreen_hasanaatEarned.
  ///
  /// In en, this message translates to:
  /// **'Hasanaat Earned'**
  String get impactReportScreen_hasanaatEarned;

  /// No description provided for @impactReportScreen_whoeverDoesGoodDeed.
  ///
  /// In en, this message translates to:
  /// **'Whoever does a good deed shall have ten times the like thereof.'**
  String get impactReportScreen_whoeverDoesGoodDeed;

  /// No description provided for @impactReportScreen_whoeverReadsLetterFrom.
  ///
  /// In en, this message translates to:
  /// **'Whoever reads a letter from the Book of Allah, he will have one hasanah, and a hasanah is multiplied by ten.'**
  String get impactReportScreen_whoeverReadsLetterFrom;

  /// No description provided for @impactReportScreen_twoHadithGrowThis.
  ///
  /// In en, this message translates to:
  /// **'Two hadith grow this number side by side:\\n\\n'**
  String get impactReportScreen_twoHadithGrowThis;

  /// No description provided for @impactReportScreen_dhikrRecitedLifetime.
  ///
  /// In en, this message translates to:
  /// **'  Dhikr recited (lifetime): {arg1}\\n'**
  String impactReportScreen_dhikrRecitedLifetime(String arg1);

  /// No description provided for @impactReportScreen_hasanat.
  ///
  /// In en, this message translates to:
  /// **'  → Hasanat: {arg1}\\n\\n'**
  String impactReportScreen_hasanat(String arg1);

  /// No description provided for @impactReportScreen_ayahsReadLifetime.
  ///
  /// In en, this message translates to:
  /// **'  Ayahs read (lifetime): {arg1}\\n'**
  String impactReportScreen_ayahsReadLifetime(String arg1);

  /// No description provided for @impactReportScreen_hasanat_e68a30.
  ///
  /// In en, this message translates to:
  /// **'  → Hasanat: {arg1}\\n\\n'**
  String impactReportScreen_hasanat_e68a30(String arg1);

  /// No description provided for @impactReportScreen_totalHasanaat.
  ///
  /// In en, this message translates to:
  /// **'Total hasanaat: {arg1}'**
  String impactReportScreen_totalHasanaat(String arg1);

  /// No description provided for @impactReportScreen_ayahs.
  ///
  /// In en, this message translates to:
  /// **'{arg1} ayahs'**
  String impactReportScreen_ayahs(String arg1);

  /// No description provided for @impactReportScreen_hasanatFromQuran.
  ///
  /// In en, this message translates to:
  /// **'Hasanat from Quran'**
  String get impactReportScreen_hasanatFromQuran;

  /// No description provided for @impactReportScreen_planted.
  ///
  /// In en, this message translates to:
  /// **'{arg1} planted'**
  String impactReportScreen_planted(String arg1);

  /// No description provided for @impactReportScreen_treesInJannah.
  ///
  /// In en, this message translates to:
  /// **'Trees in Jannah'**
  String get impactReportScreen_treesInJannah;

  /// No description provided for @impactReportScreen_cycles.
  ///
  /// In en, this message translates to:
  /// **'{arg1} cycles'**
  String impactReportScreen_cycles(String arg1);

  /// No description provided for @impactReportScreen_sinsForgiven.
  ///
  /// In en, this message translates to:
  /// **'Sins Forgiven'**
  String get impactReportScreen_sinsForgiven;

  /// No description provided for @impactReportScreen_whoeverSaysSubhanAllahiWa.
  ///
  /// In en, this message translates to:
  /// **'Whoever says SubhanAllahi wa bihamdihi 100 times a day, his sins are forgiven even if they were like the foam of the sea.'**
  String get impactReportScreen_whoeverSaysSubhanAllahiWa;

  /// No description provided for @impactReportScreen_subhanallahiWaBihamdihi.
  ///
  /// In en, this message translates to:
  /// **'SubhanAllahi wa bihamdihi'**
  String get impactReportScreen_subhanallahiWaBihamdihi;

  /// No description provided for @impactReportScreen_totalRecitations.
  ///
  /// In en, this message translates to:
  /// **'Total recitations: {arg1}\\n'**
  String impactReportScreen_totalRecitations(String arg1);

  /// No description provided for @impactReportScreen_dividedByForgivenessCycles.
  ///
  /// In en, this message translates to:
  /// **'Divided by 100 → forgiveness cycles: {arg1}'**
  String impactReportScreen_dividedByForgivenessCycles(String arg1);

  /// No description provided for @impactReportScreen_built.
  ///
  /// In en, this message translates to:
  /// **'{arg1} built'**
  String impactReportScreen_built(String arg1);

  /// No description provided for @impactReportScreen_palacesBuilt.
  ///
  /// In en, this message translates to:
  /// **'Palaces Built'**
  String get impactReportScreen_palacesBuilt;

  /// No description provided for @impactReportScreen_dividedByPalaces.
  ///
  /// In en, this message translates to:
  /// **'Divided by 10 → palaces: {arg1}'**
  String impactReportScreen_dividedByPalaces(String arg1);

  /// No description provided for @impactReportScreen_earned.
  ///
  /// In en, this message translates to:
  /// **'{arg1} earned'**
  String impactReportScreen_earned(String arg1);

  /// No description provided for @impactReportScreen_treasuresOfJannah.
  ///
  /// In en, this message translates to:
  /// **'Treasures of Jannah'**
  String get impactReportScreen_treasuresOfJannah;

  /// No description provided for @impactReportScreen_equivalent.
  ///
  /// In en, this message translates to:
  /// **'{arg1} equivalent'**
  String impactReportScreen_equivalent(String arg1);

  /// No description provided for @impactReportScreen_slavesFreed.
  ///
  /// In en, this message translates to:
  /// **'Slaves Freed'**
  String get impactReportScreen_slavesFreed;

  /// No description provided for @impactReportScreen_laIlahaIllallahuWahdahu.
  ///
  /// In en, this message translates to:
  /// **'La ilaha illallahu wahdahu la sharika lahu...'**
  String get impactReportScreen_laIlahaIllallahuWahdahu;

  /// No description provided for @impactReportScreen_totalRecitations_262e54.
  ///
  /// In en, this message translates to:
  /// **'Total recitations: {arg1}\\n'**
  String impactReportScreen_totalRecitations_262e54(String arg1);

  /// No description provided for @impactReportScreen_setsOfSetsSlaves.
  ///
  /// In en, this message translates to:
  /// **'Sets of 10 → {arg1} sets × 4 slaves = {arg2}'**
  String impactReportScreen_setsOfSetsSlaves(String arg1, String arg2);

  /// No description provided for @impactReportScreen_opened.
  ///
  /// In en, this message translates to:
  /// **'{arg1} opened'**
  String impactReportScreen_opened(String arg1);

  /// No description provided for @impactReportScreen_gatesOfParadiseOpened.
  ///
  /// In en, this message translates to:
  /// **'Gates of Paradise Opened'**
  String get impactReportScreen_gatesOfParadiseOpened;

  /// No description provided for @impactReportScreen_received.
  ///
  /// In en, this message translates to:
  /// **'{arg1} received'**
  String impactReportScreen_received(String arg1);

  /// No description provided for @impactReportScreen_blessingsFromAllah.
  ///
  /// In en, this message translates to:
  /// **'Blessings from Allah'**
  String get impactReportScreen_blessingsFromAllah;

  /// No description provided for @impactReportScreen_totalSalawatSent.
  ///
  /// In en, this message translates to:
  /// **'Total salawat sent: {arg1}\\n'**
  String impactReportScreen_totalSalawatSent(String arg1);

  /// No description provided for @impactReportScreen_multipliedByBlessingsReceived.
  ///
  /// In en, this message translates to:
  /// **'Multiplied by 10 → {arg1} blessings received'**
  String impactReportScreen_multipliedByBlessingsReceived(String arg1);

  /// No description provided for @impactReportScreen_invocations.
  ///
  /// In en, this message translates to:
  /// **'{arg1} invocations'**
  String impactReportScreen_invocations(String arg1);

  /// No description provided for @impactReportScreen_timesProtected.
  ///
  /// In en, this message translates to:
  /// **'Times Protected'**
  String get impactReportScreen_timesProtected;

  /// No description provided for @impactReportScreen_protectionFromEvil.
  ///
  /// In en, this message translates to:
  /// **'Protection from evil'**
  String get impactReportScreen_protectionFromEvil;

  /// No description provided for @impactReportScreen_goodHealthProtection.
  ///
  /// In en, this message translates to:
  /// **'Good health & protection'**
  String get impactReportScreen_goodHealthProtection;

  /// No description provided for @impactReportScreen_totalInvocations.
  ///
  /// In en, this message translates to:
  /// **'Total invocations: {arg1}'**
  String impactReportScreen_totalInvocations(String arg1);

  /// No description provided for @impactReportScreen_equivalent_d7e6f6.
  ///
  /// In en, this message translates to:
  /// **'{arg1} equivalent'**
  String impactReportScreen_equivalent_d7e6f6(String arg1);

  /// No description provided for @impactReportScreen_quranCompletions.
  ///
  /// In en, this message translates to:
  /// **'Quran Completions'**
  String get impactReportScreen_quranCompletions;

  /// No description provided for @impactReportScreen_dividedByQuranCompletions.
  ///
  /// In en, this message translates to:
  /// **'Divided by 3 → {arg1} Quran completions'**
  String impactReportScreen_dividedByQuranCompletions(String arg1);

  /// No description provided for @impactReportScreen_recitations.
  ///
  /// In en, this message translates to:
  /// **'{arg1} recitations'**
  String impactReportScreen_recitations(String arg1);

  /// No description provided for @impactReportScreen_bonusMillionHasanaat.
  ///
  /// In en, this message translates to:
  /// **'Bonus Million Hasanaat'**
  String get impactReportScreen_bonusMillionHasanaat;

  /// No description provided for @impactReportScreen_sadaqahGiven.
  ///
  /// In en, this message translates to:
  /// **'Sadaqah Given'**
  String get impactReportScreen_sadaqahGiven;

  /// No description provided for @impactReportScreen_564740.
  ///
  /// In en, this message translates to:
  /// **'{_monthActiveDays}'**
  String impactReportScreen_564740(String _monthActiveDays);

  /// No description provided for @impactReportScreen_3dc421.
  ///
  /// In en, this message translates to:
  /// **'{arg1}h '**
  String impactReportScreen_3dc421(String arg1);

  /// No description provided for @impactReportScreen_08990a.
  ///
  /// In en, this message translates to:
  /// **'{arg1}m'**
  String impactReportScreen_08990a(String arg1);

  /// No description provided for @impactReportScreen_ago.
  ///
  /// In en, this message translates to:
  /// **'{arg1}m ago'**
  String impactReportScreen_ago(String arg1);

  /// No description provided for @impactReportScreen_ago_c25b44.
  ///
  /// In en, this message translates to:
  /// **'{arg1}h ago'**
  String impactReportScreen_ago_c25b44(String arg1);

  /// No description provided for @impactReportScreen_ago_e160e3.
  ///
  /// In en, this message translates to:
  /// **'{arg1}w ago'**
  String impactReportScreen_ago_e160e3(String arg1);

  /// No description provided for @impactReportScreen_moAgo.
  ///
  /// In en, this message translates to:
  /// **'{arg1}mo ago'**
  String impactReportScreen_moAgo(String arg1);

  /// No description provided for @impactReportScreen_ago_65f0ec.
  ///
  /// In en, this message translates to:
  /// **'{arg1}y ago'**
  String impactReportScreen_ago_65f0ec(String arg1);

  /// No description provided for @impactReportScreen_viewAllDonors.
  ///
  /// In en, this message translates to:
  /// **'View all {arg1} donors'**
  String impactReportScreen_viewAllDonors(String arg1);

  /// No description provided for @impactReportScreen_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {e}'**
  String impactReportScreen_failed(String e);

  /// No description provided for @impactReportScreen_meet.
  ///
  /// In en, this message translates to:
  /// **'Meet {arg1}, {arg2}'**
  String impactReportScreen_meet(String arg1, String arg2);

  /// No description provided for @impactReportScreen_sponsor.
  ///
  /// In en, this message translates to:
  /// **'Sponsor {arg1} →'**
  String impactReportScreen_sponsor(String arg1);

  /// No description provided for @impactReportScreen_funded.
  ///
  /// In en, this message translates to:
  /// **'{arg1}% funded'**
  String impactReportScreen_funded(String arg1);

  /// No description provided for @impactReportScreen_yourLifetimeImpact.
  ///
  /// In en, this message translates to:
  /// **'Your lifetime impact'**
  String get impactReportScreen_yourLifetimeImpact;

  /// No description provided for @impactReportScreen_startYourImpactJourney.
  ///
  /// In en, this message translates to:
  /// **'Start your impact journey'**
  String get impactReportScreen_startYourImpactJourney;

  /// No description provided for @impactReportScreen_bd3721.
  ///
  /// In en, this message translates to:
  /// **'{_myOrphansSponsoredCount}'**
  String impactReportScreen_bd3721(String _myOrphansSponsoredCount);

  /// No description provided for @impactReportScreen_b3d969.
  ///
  /// In en, this message translates to:
  /// **'{_myProjectsSupportedCount}'**
  String impactReportScreen_b3d969(String _myProjectsSupportedCount);

  /// No description provided for @levelScreen_customProfileThemes.
  ///
  /// In en, this message translates to:
  /// **'Custom profile themes'**
  String get levelScreen_customProfileThemes;

  /// No description provided for @levelScreen_exclusiveVotingRights.
  ///
  /// In en, this message translates to:
  /// **'Exclusive voting rights'**
  String get levelScreen_exclusiveVotingRights;

  /// No description provided for @levelScreen_hallOfFameListing.
  ///
  /// In en, this message translates to:
  /// **'Hall of Fame listing'**
  String get levelScreen_hallOfFameListing;

  /// No description provided for @levelScreen_seeds.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} Seeds'**
  String levelScreen_seeds(String arg1);

  /// No description provided for @levelScreen_laIlahaIllallah.
  ///
  /// In en, this message translates to:
  /// **'La ilaha illallah x100'**
  String get levelScreen_laIlahaIllallah;

  /// No description provided for @levelScreen_seeds_59c6a1.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} Seeds'**
  String levelScreen_seeds_59c6a1(String arg1);

  /// No description provided for @levelScreen_seeds_a20530.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} Seeds'**
  String levelScreen_seeds_a20530(String arg1);

  /// No description provided for @levelScreen_unlocks.
  ///
  /// In en, this message translates to:
  /// **'Unlocks: {arg1}'**
  String levelScreen_unlocks(String arg1);

  /// No description provided for @levelScreen_seeds_a49180.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} Seeds ✓'**
  String levelScreen_seeds_a49180(String arg1);

  /// No description provided for @levelScreen_seeds_a22be5.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} Seeds'**
  String levelScreen_seeds_a22be5(String arg1);

  /// No description provided for @levelScreen_seedsBoost.
  ///
  /// In en, this message translates to:
  /// **'{arg1}× Seeds Boost'**
  String levelScreen_seedsBoost(String arg1);

  /// No description provided for @levelScreen_cf765f.
  ///
  /// In en, this message translates to:
  /// **'{arg1}:{arg2}  {arg3}/{arg4}/{arg5}'**
  String levelScreen_cf765f(
    String arg1,
    String arg2,
    String arg3,
    String arg4,
    String arg5,
  );

  /// No description provided for @levelScreen_nextDays.
  ///
  /// In en, this message translates to:
  /// **'Next: {arg1} ({arg2} days)'**
  String levelScreen_nextDays(String arg1, String arg2);

  /// No description provided for @levelScreen_seeds_990893.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} Seeds'**
  String levelScreen_seeds_990893(String arg1);

  /// No description provided for @levelScreen_days.
  ///
  /// In en, this message translates to:
  /// **'{current} / {arg1} days'**
  String levelScreen_days(String current, String arg1);

  /// No description provided for @levelScreen_dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{arg1} day streak'**
  String levelScreen_dayStreak(String arg1);

  /// No description provided for @phase1Screens_inTheNameOf.
  ///
  /// In en, this message translates to:
  /// **'In the name of Allah, the Most Gracious…'**
  String get phase1Screens_inTheNameOf;

  /// No description provided for @phase1Screens_quranReadingNimage.
  ///
  /// In en, this message translates to:
  /// **'Quran reading\\nimage'**
  String get phase1Screens_quranReadingNimage;

  /// No description provided for @phase1Screens_orphansNimage.
  ///
  /// In en, this message translates to:
  /// **'Orphans\\nimage'**
  String get phase1Screens_orphansNimage;

  /// No description provided for @onboardingComponents_355c50.
  ///
  /// In en, this message translates to:
  /// **'{first} '**
  String onboardingComponents_355c50(String first);

  /// No description provided for @onboardingComponents_b236c9.
  ///
  /// In en, this message translates to:
  /// **' {trailing}'**
  String onboardingComponents_b236c9(String trailing);

  /// No description provided for @quranMini_inTheNameOf.
  ///
  /// In en, this message translates to:
  /// **'In the name of Allah, the Most Gracious, the Most Merciful.'**
  String get quranMini_inTheNameOf;

  /// No description provided for @quranMini_allPraiseBelongsTo.
  ///
  /// In en, this message translates to:
  /// **'All praise belongs to Allah, Lord of all the worlds.'**
  String get quranMini_allPraiseBelongsTo;

  /// No description provided for @orphansGridScreen_36cd3b.
  ///
  /// In en, this message translates to:
  /// **'{arg1} · {arg2}'**
  String orphansGridScreen_36cd3b(String arg1, String arg2);

  /// No description provided for @orphanDetailScreen_years.
  ///
  /// In en, this message translates to:
  /// **'{arg1} years'**
  String orphanDetailScreen_years(String arg1);

  /// No description provided for @orphanDetailScreen_ofSeeds.
  ///
  /// In en, this message translates to:
  /// **'{arg1} of {arg2} Seeds'**
  String orphanDetailScreen_ofSeeds(String arg1, String arg2);

  /// No description provided for @orphanDetailScreen_through.
  ///
  /// In en, this message translates to:
  /// **'Through {arg1}'**
  String orphanDetailScreen_through(String arg1);

  /// No description provided for @orphanDetailScreen_andTheyGiveFood.
  ///
  /// In en, this message translates to:
  /// **'And they give food, despite their love for it, to the needy, the orphan, and the captive.'**
  String get orphanDetailScreen_andTheyGiveFood;

  /// No description provided for @orphanDetailScreen_ago.
  ///
  /// In en, this message translates to:
  /// **'{arg1}m ago'**
  String orphanDetailScreen_ago(String arg1);

  /// No description provided for @orphanDetailScreen_ago_c25b44.
  ///
  /// In en, this message translates to:
  /// **'{arg1}h ago'**
  String orphanDetailScreen_ago_c25b44(String arg1);

  /// No description provided for @orphanDetailScreen_ago_e160e3.
  ///
  /// In en, this message translates to:
  /// **'{arg1}w ago'**
  String orphanDetailScreen_ago_e160e3(String arg1);

  /// No description provided for @orphanDetailScreen_moAgo.
  ///
  /// In en, this message translates to:
  /// **'{arg1}mo ago'**
  String orphanDetailScreen_moAgo(String arg1);

  /// No description provided for @orphanDetailScreen_ago_65f0ec.
  ///
  /// In en, this message translates to:
  /// **'{arg1}y ago'**
  String orphanDetailScreen_ago_65f0ec(String arg1);

  /// No description provided for @orphanDetailScreen_seeds.
  ///
  /// In en, this message translates to:
  /// **'{_availablePoints} Seeds'**
  String orphanDetailScreen_seeds(String _availablePoints);

  /// No description provided for @orphanDetailScreen_sponsor.
  ///
  /// In en, this message translates to:
  /// **'Sponsor {arg1}'**
  String orphanDetailScreen_sponsor(String arg1);

  /// No description provided for @orphanDetailScreen_jazakallahKhayranSeedsSponsored.
  ///
  /// In en, this message translates to:
  /// **'JazakAllah Khayran! {amount} Seeds sponsored.'**
  String orphanDetailScreen_jazakallahKhayranSeedsSponsored(String amount);

  /// No description provided for @orphanDetailScreen_chooseHowManySeeds.
  ///
  /// In en, this message translates to:
  /// **'Choose how many Seeds to give. Minimum {arg1}.'**
  String orphanDetailScreen_chooseHowManySeeds(String arg1);

  /// No description provided for @orphanDetailScreen_yourBalanceSeeds.
  ///
  /// In en, this message translates to:
  /// **'Your balance: {arg1} Seeds'**
  String orphanDetailScreen_yourBalanceSeeds(String arg1);

  /// No description provided for @profileSettingsScreen_nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get profileSettingsScreen_nameCannotBeEmpty;

  /// No description provided for @profileSettingsScreen_sabiqRewards.
  ///
  /// In en, this message translates to:
  /// **'Sabiq Rewards • v1.0'**
  String get profileSettingsScreen_sabiqRewards;

  /// No description provided for @profileSettingsScreen_bosniaAndHerzegovina.
  ///
  /// In en, this message translates to:
  /// **'Bosnia and Herzegovina'**
  String get profileSettingsScreen_bosniaAndHerzegovina;

  /// No description provided for @profileSettingsScreen_centralAfricanRepublic.
  ///
  /// In en, this message translates to:
  /// **'Central African Republic'**
  String get profileSettingsScreen_centralAfricanRepublic;

  /// No description provided for @profileSettingsScreen_unitedArabEmirates.
  ///
  /// In en, this message translates to:
  /// **'United Arab Emirates'**
  String get profileSettingsScreen_unitedArabEmirates;

  /// No description provided for @profileSettingsScreen_signedInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google'**
  String get profileSettingsScreen_signedInWithGoogle;

  /// No description provided for @profileSettingsScreen_signedInWithQuran.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Quran.com'**
  String get profileSettingsScreen_signedInWithQuran;

  /// No description provided for @profileSettingsScreen_signedInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Email'**
  String get profileSettingsScreen_signedInWithEmail;

  /// No description provided for @profileSettingsScreen_seeds.
  ///
  /// In en, this message translates to:
  /// **'{arg1} Seeds'**
  String profileSettingsScreen_seeds(String arg1);

  /// No description provided for @profileSettingsScreen_seeds_59ba7c.
  ///
  /// In en, this message translates to:
  /// **'{arg1} Seeds'**
  String profileSettingsScreen_seeds_59ba7c(String arg1);

  /// No description provided for @profileSettingsScreen_seeds_2bc978.
  ///
  /// In en, this message translates to:
  /// **'{arg1} Seeds'**
  String profileSettingsScreen_seeds_2bc978(String arg1);

  /// No description provided for @profileSettingsScreen_guidesFAQsAndHow.
  ///
  /// In en, this message translates to:
  /// **'Guides, FAQs and how-tos'**
  String get profileSettingsScreen_guidesFAQsAndHow;

  /// No description provided for @profileSettingsScreen_somethingNotWorkingTell.
  ///
  /// In en, this message translates to:
  /// **'Something not working? Tell us'**
  String get profileSettingsScreen_somethingNotWorkingTell;

  /// No description provided for @profileSetupScreen_ahmadFatimaYusuf.
  ///
  /// In en, this message translates to:
  /// **'Ahmad, Fatima, Yusuf…'**
  String get profileSetupScreen_ahmadFatimaYusuf;

  /// No description provided for @profileSetupScreen_pakistanEgyptMalaysia.
  ///
  /// In en, this message translates to:
  /// **'Pakistan, Egypt, Malaysia…'**
  String get profileSetupScreen_pakistanEgyptMalaysia;

  /// No description provided for @projectDetailScreen_organisedBy.
  ///
  /// In en, this message translates to:
  /// **'Organised by {sponsor}\\n\\n'**
  String projectDetailScreen_organisedBy(String sponsor);

  /// No description provided for @projectDetailScreen_fundedSoFarEvery.
  ///
  /// In en, this message translates to:
  /// **'Funded so far, every Seed counts!\\n\\n'**
  String get projectDetailScreen_fundedSoFarEvery;

  /// No description provided for @projectDetailScreen_openSabiqRewardsApp.
  ///
  /// In en, this message translates to:
  /// **'Open Sabiq Rewards app to donate your Seeds and earn reward.\\n'**
  String get projectDetailScreen_openSabiqRewardsApp;

  /// No description provided for @projectDetailScreen_sabiqrewardsSadaqahIslamicCharity.
  ///
  /// In en, this message translates to:
  /// **'#SabiqRewards #Sadaqah #IslamicCharity'**
  String get projectDetailScreen_sabiqrewardsSadaqahIslamicCharity;

  /// No description provided for @projectDetailScreen_4c2b09.
  ///
  /// In en, this message translates to:
  /// **'{arg1} {arg2} {arg3}'**
  String projectDetailScreen_4c2b09(String arg1, String arg2, String arg3);

  /// No description provided for @projectDetailScreen_donateToProvideUrgent.
  ///
  /// In en, this message translates to:
  /// **'Donate to provide urgent, life-saving aid to Palestinians facing critical shortages of food, water, and medical supplies...'**
  String get projectDetailScreen_donateToProvideUrgent;

  /// No description provided for @projectDetailScreen_seeds.
  ///
  /// In en, this message translates to:
  /// **'{arg1} Seeds'**
  String projectDetailScreen_seeds(String arg1);

  /// No description provided for @projectDetailScreen_seeds_801ec7.
  ///
  /// In en, this message translates to:
  /// **'{arg1} Seeds'**
  String projectDetailScreen_seeds_801ec7(String arg1);

  /// No description provided for @projectDetailScreen_e4e562.
  ///
  /// In en, this message translates to:
  /// **'{arg1}%'**
  String projectDetailScreen_e4e562(String arg1);

  /// No description provided for @projectDetailScreen_ago.
  ///
  /// In en, this message translates to:
  /// **'{arg1}m ago'**
  String projectDetailScreen_ago(String arg1);

  /// No description provided for @projectDetailScreen_ago_c25b44.
  ///
  /// In en, this message translates to:
  /// **'{arg1}h ago'**
  String projectDetailScreen_ago_c25b44(String arg1);

  /// No description provided for @projectDetailScreen_ago_e160e3.
  ///
  /// In en, this message translates to:
  /// **'{arg1}w ago'**
  String projectDetailScreen_ago_e160e3(String arg1);

  /// No description provided for @projectDetailScreen_moAgo.
  ///
  /// In en, this message translates to:
  /// **'{arg1}mo ago'**
  String projectDetailScreen_moAgo(String arg1);

  /// No description provided for @projectDetailScreen_ago_65f0ec.
  ///
  /// In en, this message translates to:
  /// **'{arg1}y ago'**
  String projectDetailScreen_ago_65f0ec(String arg1);

  /// No description provided for @projectDetailScreen_viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all {arg1} →'**
  String projectDetailScreen_viewAll(String arg1);

  /// No description provided for @quranHubScreen_saved.
  ///
  /// In en, this message translates to:
  /// **'{arg1} saved'**
  String quranHubScreen_saved(String arg1);

  /// No description provided for @quranHubScreen_tapTheHeartBookmark.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart/bookmark icon while reading to save verses.'**
  String get quranHubScreen_tapTheHeartBookmark;

  /// No description provided for @quranHubScreen_surahVerse.
  ///
  /// In en, this message translates to:
  /// **'Surah {s}  •  Verse {a}'**
  String quranHubScreen_surahVerse(String s, String a);

  /// No description provided for @quranHubScreen_loadingQuran.
  ///
  /// In en, this message translates to:
  /// **'Loading Quran…'**
  String get quranHubScreen_loadingQuran;

  /// No description provided for @quranHubScreen_verses.
  ///
  /// In en, this message translates to:
  /// **'{arg1} verses'**
  String quranHubScreen_verses(String arg1);

  /// No description provided for @quranHubScreen_of.
  ///
  /// In en, this message translates to:
  /// **'of {arg1}'**
  String quranHubScreen_of(String arg1);

  /// No description provided for @quranHubScreen_saved_edce53.
  ///
  /// In en, this message translates to:
  /// **'{arg1} saved'**
  String quranHubScreen_saved_edce53(String arg1);

  /// No description provided for @quranScreen_englishSahihIntl.
  ///
  /// In en, this message translates to:
  /// **'English, Sahih Intl.'**
  String get quranScreen_englishSahihIntl;

  /// No description provided for @quranScreen_saheehInternational.
  ///
  /// In en, this message translates to:
  /// **'Saheeh International'**
  String get quranScreen_saheehInternational;

  /// No description provided for @quranScreen_englishPickthall.
  ///
  /// In en, this message translates to:
  /// **'English, Pickthall'**
  String get quranScreen_englishPickthall;

  /// No description provided for @quranScreen_mohammadMarmadukePickthall.
  ///
  /// In en, this message translates to:
  /// **'Mohammad Marmaduke Pickthall'**
  String get quranScreen_mohammadMarmadukePickthall;

  /// No description provided for @quranScreen_englishTheMessage.
  ///
  /// In en, this message translates to:
  /// **'English, The Message'**
  String get quranScreen_englishTheMessage;

  /// No description provided for @quranScreen_englishMuhsinKhan.
  ///
  /// In en, this message translates to:
  /// **'English, Muhsin Khan'**
  String get quranScreen_englishMuhsinKhan;

  /// No description provided for @quranScreen_muhsinKhanHilali.
  ///
  /// In en, this message translates to:
  /// **'Muhsin Khan & Hilali'**
  String get quranScreen_muhsinKhanHilali;

  /// No description provided for @quranScreen_fatehMuhammadJalandhry.
  ///
  /// In en, this message translates to:
  /// **'Fateh Muhammad Jalandhry'**
  String get quranScreen_fatehMuhammadJalandhry;

  /// No description provided for @quranScreen_imamAhmadRazaKhan.
  ///
  /// In en, this message translates to:
  /// **'Imam Ahmad Raza Khan'**
  String get quranScreen_imamAhmadRazaKhan;

  /// No description provided for @quranScreen_maulanaSayyidAbulAla.
  ///
  /// In en, this message translates to:
  /// **'Maulana Sayyid Abul Ala Maududi'**
  String get quranScreen_maulanaSayyidAbulAla;

  /// No description provided for @quranScreen_franAisHamidullah.
  ///
  /// In en, this message translates to:
  /// **'Français, Hamidullah'**
  String get quranScreen_franAisHamidullah;

  /// No description provided for @quranScreen_rkDiyanet.
  ///
  /// In en, this message translates to:
  /// **'Türkçe, Diyanet'**
  String get quranScreen_rkDiyanet;

  /// No description provided for @quranScreen_rkLeymanAte.
  ///
  /// In en, this message translates to:
  /// **'Türkçe, Süleyman Ateş'**
  String get quranScreen_rkLeymanAte;

  /// No description provided for @quranScreen_bahasaIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa, Indonesian'**
  String get quranScreen_bahasaIndonesian;

  /// No description provided for @quranScreen_ministryOfReligiousAffairs.
  ///
  /// In en, this message translates to:
  /// **'Ministry of Religious Affairs'**
  String get quranScreen_ministryOfReligiousAffairs;

  /// No description provided for @quranScreen_muhiuddinKhan.
  ///
  /// In en, this message translates to:
  /// **'বাংলা, Muhiuddin Khan'**
  String get quranScreen_muhiuddinKhan;

  /// No description provided for @quranScreen_deutschAbuRida.
  ///
  /// In en, this message translates to:
  /// **'Deutsch, Abu Rida'**
  String get quranScreen_deutschAbuRida;

  /// No description provided for @quranScreen_abuRidaMuhammadIbn.
  ///
  /// In en, this message translates to:
  /// **'Abu Rida Muhammad ibn Ahmad'**
  String get quranScreen_abuRidaMuhammadIbn;

  /// No description provided for @quranScreen_espaOlAsad.
  ///
  /// In en, this message translates to:
  /// **'Español, Asad'**
  String get quranScreen_espaOlAsad;

  /// No description provided for @quranScreen_uthmaniMadinah.
  ///
  /// In en, this message translates to:
  /// **'Uthmani (Madinah)'**
  String get quranScreen_uthmaniMadinah;

  /// No description provided for @quranScreen_alJalalaynEN.
  ///
  /// In en, this message translates to:
  /// **'Al-Jalalayn (EN)'**
  String get quranScreen_alJalalaynEN;

  /// No description provided for @quranScreen_couldNotLoadAyah.
  ///
  /// In en, this message translates to:
  /// **'Could not load ayah. Please retry.'**
  String get quranScreen_couldNotLoadAyah;

  /// No description provided for @quranScreen_noConnectionCachedData.
  ///
  /// In en, this message translates to:
  /// **'No connection. Cached data may be available.'**
  String get quranScreen_noConnectionCachedData;

  /// No description provided for @quranScreen_ayahs.
  ///
  /// In en, this message translates to:
  /// **'{arg1} ayahs'**
  String quranScreen_ayahs(String arg1);

  /// No description provided for @quranScreen_couldNotRemoveBookmark.
  ///
  /// In en, this message translates to:
  /// **'Could not remove bookmark, please retry'**
  String get quranScreen_couldNotRemoveBookmark;

  /// No description provided for @quranScreen_removedBookmark.
  ///
  /// In en, this message translates to:
  /// **'Removed bookmark {_surahName} {_surah}:{_ayah}'**
  String quranScreen_removedBookmark(
    String _surahName,
    String _surah,
    String _ayah,
  );

  /// No description provided for @quranScreen_couldNotSaveBookmark.
  ///
  /// In en, this message translates to:
  /// **'Could not save bookmark, please retry'**
  String get quranScreen_couldNotSaveBookmark;

  /// No description provided for @quranScreen_bookmarked.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked {_surahName} {_surah}:{_ayah}'**
  String quranScreen_bookmarked(String _surahName, String _surah, String _ayah);

  /// No description provided for @quranScreen_trimmedContains.
  ///
  /// In en, this message translates to:
  /// **') && !trimmed.contains('**
  String get quranScreen_trimmedContains;

  /// No description provided for @quranScreen_tafsir.
  ///
  /// In en, this message translates to:
  /// **'Tafsir · {_surahName} {_surah}:{_ayah}'**
  String quranScreen_tafsir(String _surahName, String _surah, String _ayah);

  /// No description provided for @quranScreen_addedToFavourites.
  ///
  /// In en, this message translates to:
  /// **'♥️ Added to Favourites'**
  String get quranScreen_addedToFavourites;

  /// No description provided for @quranScreen_comfortableNightTimeReading.
  ///
  /// In en, this message translates to:
  /// **'Comfortable night-time reading'**
  String get quranScreen_comfortableNightTimeReading;

  /// No description provided for @quranScreen_pt.
  ///
  /// In en, this message translates to:
  /// **'{arg1} pt'**
  String quranScreen_pt(String arg1);

  /// No description provided for @quranScreen_003843.
  ///
  /// In en, this message translates to:
  /// **'{arg1}  {arg2}'**
  String quranScreen_003843(String arg1, String arg2);

  /// No description provided for @quranScreen_displayMeaningBelowEach.
  ///
  /// In en, this message translates to:
  /// **'Display meaning below each verse'**
  String get quranScreen_displayMeaningBelowEach;

  /// No description provided for @quranScreen_showTransliteration.
  ///
  /// In en, this message translates to:
  /// **'Show Transliteration'**
  String get quranScreen_showTransliteration;

  /// No description provided for @quranScreen_romanisedPronunciationUnderEach.
  ///
  /// In en, this message translates to:
  /// **'Romanised pronunciation under each word'**
  String get quranScreen_romanisedPronunciationUnderEach;

  /// No description provided for @quranScreen_progressBarAyahCount.
  ///
  /// In en, this message translates to:
  /// **'Progress bar & ayah count card'**
  String get quranScreen_progressBarAyahCount;

  /// No description provided for @quranScreen_moveToNextVerse.
  ///
  /// In en, this message translates to:
  /// **'Move to next verse when audio ends'**
  String get quranScreen_moveToNextVerse;

  /// No description provided for @quranScreen_repeatCurrentVerse.
  ///
  /// In en, this message translates to:
  /// **'Repeat Current Verse'**
  String get quranScreen_repeatCurrentVerse;

  /// No description provided for @quranScreen_notificationsALERTS.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS & ALERTS'**
  String get quranScreen_notificationsALERTS;

  /// No description provided for @quranScreen_milestoneSoundAlerts.
  ///
  /// In en, this message translates to:
  /// **'Milestone Sound Alerts'**
  String get quranScreen_milestoneSoundAlerts;

  /// No description provided for @quranScreen_chimeWhenYouReach.
  ///
  /// In en, this message translates to:
  /// **'Chime when you reach 10, 25, 50 ayahs'**
  String get quranScreen_chimeWhenYouReach;

  /// No description provided for @quranScreen_showEachArabicWord.
  ///
  /// In en, this message translates to:
  /// **'Show each Arabic word with its English meaning'**
  String get quranScreen_showEachArabicWord;

  /// No description provided for @quranScreen_translationLanguage.
  ///
  /// In en, this message translates to:
  /// **'Translation Language'**
  String get quranScreen_translationLanguage;

  /// No description provided for @quranScreen_translationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{arg1} translations available'**
  String quranScreen_translationsAvailable(String arg1);

  /// No description provided for @quranScreen_3502e8.
  ///
  /// In en, this message translates to:
  /// **'{arg1} / {arg2}'**
  String quranScreen_3502e8(String arg1, String arg2);

  /// No description provided for @quranScreen_sabiqSeedsEarnedToday.
  ///
  /// In en, this message translates to:
  /// **'+{_pointsToday} Sabiq Seeds earned today!'**
  String quranScreen_sabiqSeedsEarnedToday(String _pointsToday);

  /// No description provided for @quranScreen_dcacc4.
  ///
  /// In en, this message translates to:
  /// **'{_ayah} / {arg1}'**
  String quranScreen_dcacc4(String _ayah, String arg1);

  /// No description provided for @quranScreen_wordDataUnavailableCheck.
  ///
  /// In en, this message translates to:
  /// **'Word data unavailable. Check your connection.'**
  String get quranScreen_wordDataUnavailableCheck;

  /// No description provided for @quranScreen_6d1f9d.
  ///
  /// In en, this message translates to:
  /// **'{arg1} '**
  String quranScreen_6d1f9d(String arg1);

  /// No description provided for @quranScreen_ayahsRead.
  ///
  /// In en, this message translates to:
  /// **'{_ayahsToday} ayahs read'**
  String quranScreen_ayahsRead(String _ayahsToday);

  /// No description provided for @quranScreen_ce2af3.
  ///
  /// In en, this message translates to:
  /// **'{arg1}%'**
  String quranScreen_ce2af3(String arg1);

  /// No description provided for @quranScreen_6e8ac8.
  ///
  /// In en, this message translates to:
  /// **'{text} '**
  String quranScreen_6e8ac8(String text);

  /// No description provided for @quranScreen_pageJuz.
  ///
  /// In en, this message translates to:
  /// **'Page {_currentPage}  ·  Juz {arg1}'**
  String quranScreen_pageJuz(String _currentPage, String arg1);

  /// No description provided for @startJourneyScreen_unexpectedErrorDuringGoogle.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error during Google Sign In'**
  String get startJourneyScreen_unexpectedErrorDuringGoogle;

  /// No description provided for @startJourneyScreen_connectedToQuranCom.
  ///
  /// In en, this message translates to:
  /// **'Connected to Quran.com'**
  String get startJourneyScreen_connectedToQuranCom;

  /// No description provided for @startJourneyScreen_connectedToQuranCom_0ac4de.
  ///
  /// In en, this message translates to:
  /// **'Connected to Quran.com (bookmark sync deferred)'**
  String get startJourneyScreen_connectedToQuranCom_0ac4de;

  /// No description provided for @streakScreen_nextDays.
  ///
  /// In en, this message translates to:
  /// **'Next: {arg1} ({arg2} days)'**
  String streakScreen_nextDays(String arg1, String arg2);

  /// No description provided for @streakScreen_seeds.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} Seeds'**
  String streakScreen_seeds(String arg1);

  /// No description provided for @streakScreen_days.
  ///
  /// In en, this message translates to:
  /// **'{current} / {arg1} days'**
  String streakScreen_days(String current, String arg1);

  /// No description provided for @streakScreen_dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{arg1} day streak'**
  String streakScreen_dayStreak(String arg1);

  /// No description provided for @tafsirHubScreen_earnSeedsForEvery.
  ///
  /// In en, this message translates to:
  /// **'Earn Seeds for every 10 min of Tafsir listening'**
  String get tafsirHubScreen_earnSeedsForEvery;

  /// No description provided for @tafsirScreen_alJalalaynEN.
  ///
  /// In en, this message translates to:
  /// **'Al-Jalalayn (EN)'**
  String get tafsirScreen_alJalalaynEN;

  /// No description provided for @tafsirScreen_verses.
  ///
  /// In en, this message translates to:
  /// **'{arg1} verses'**
  String tafsirScreen_verses(String arg1);

  /// No description provided for @tafsirScreen_trimmedContains.
  ///
  /// In en, this message translates to:
  /// **') && !trimmed.contains('**
  String get tafsirScreen_trimmedContains;

  /// No description provided for @tafsirScreen_ayahOf.
  ///
  /// In en, this message translates to:
  /// **'Ayah {_ayah} of {_surahLen}'**
  String tafsirScreen_ayahOf(String _ayah, String _surahLen);

  /// No description provided for @tafsirScreen_4815bb.
  ///
  /// In en, this message translates to:
  /// **'{_surahName} {_ayah}/{_surahLen}'**
  String tafsirScreen_4815bb(String _surahName, String _ayah, String _surahLen);

  /// No description provided for @tafsirScreen_tafsirNotAvailableFor.
  ///
  /// In en, this message translates to:
  /// **'Tafsir not available for this ayah.'**
  String get tafsirScreen_tafsirNotAvailableFor;

  /// No description provided for @donationService_youMustBeLogged.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to donate.'**
  String get donationService_youMustBeLogged;

  /// No description provided for @donationService_donationCouldNotBe.
  ///
  /// In en, this message translates to:
  /// **'Donation could not be processed at this time.'**
  String get donationService_donationCouldNotBe;

  /// No description provided for @donationService_anUnexpectedNetworkError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected network error occurred.'**
  String get donationService_anUnexpectedNetworkError;

  /// No description provided for @donationService_youMustBeLogged_edc4b5.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to sponsor.'**
  String get donationService_youMustBeLogged_edc4b5;

  /// No description provided for @donationService_sponsorshipReceived.
  ///
  /// In en, this message translates to:
  /// **'Sponsorship received 💝'**
  String get donationService_sponsorshipReceived;

  /// No description provided for @donationService_youSponsoredSeedsJazak.
  ///
  /// In en, this message translates to:
  /// **'You sponsored {amount} Seeds · jazak Allah khair.'**
  String donationService_youSponsoredSeedsJazak(String amount);

  /// No description provided for @donationService_sponsorshipCouldNotBe.
  ///
  /// In en, this message translates to:
  /// **'Sponsorship could not be processed at this time.'**
  String get donationService_sponsorshipCouldNotBe;

  /// No description provided for @liveNotificationService_remindersToSealYour.
  ///
  /// In en, this message translates to:
  /// **'Reminders to seal your pending Seeds before midnight.'**
  String get liveNotificationService_remindersToSealYour;

  /// No description provided for @liveNotificationService_sealYourSeedsBefore.
  ///
  /// In en, this message translates to:
  /// **'Seal your Seeds before midnight'**
  String get liveNotificationService_sealYourSeedsBefore;

  /// No description provided for @liveNotificationService_sealYourSeedsBefore_be2183.
  ///
  /// In en, this message translates to:
  /// **'Seal your Seeds before midnight!'**
  String get liveNotificationService_sealYourSeedsBefore_be2183;

  /// No description provided for @liveNotificationService_youHavePendingSeeds.
  ///
  /// In en, this message translates to:
  /// **'You have {pendingSeeds} pending Seeds. Tap Seal the Day before midnight or they expire.'**
  String liveNotificationService_youHavePendingSeeds(String pendingSeeds);

  /// No description provided for @liveNotificationService_ayatReadToday.
  ///
  /// In en, this message translates to:
  /// **'{_ayahCount} Ayat Read today 📖'**
  String liveNotificationService_ayatReadToday(String _ayahCount);

  /// No description provided for @liveNotificationService_readQuranToday.
  ///
  /// In en, this message translates to:
  /// **'{arg1} Read Quran today ⏱️'**
  String liveNotificationService_readQuranToday(String arg1);

  /// No description provided for @liveNotificationService_nothingReadFromQuran.
  ///
  /// In en, this message translates to:
  /// **'Nothing Read from Quran today 📖'**
  String get liveNotificationService_nothingReadFromQuran;

  /// No description provided for @liveNotificationService_dhikrCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'{_dhikrCount} Dhikr completed today 📿'**
  String liveNotificationService_dhikrCompletedToday(String _dhikrCount);

  /// No description provided for @liveNotificationService_ayatDhikrToday.
  ///
  /// In en, this message translates to:
  /// **'{_ayahCount} ayat · {_dhikrCount} dhikr today'**
  String liveNotificationService_ayatDhikrToday(
    String _ayahCount,
    String _dhikrCount,
  );

  /// No description provided for @liveNotificationService_keepReadingAndDoing.
  ///
  /// In en, this message translates to:
  /// **'Keep reading and doing Dhikr!'**
  String get liveNotificationService_keepReadingAndDoing;

  /// No description provided for @liveNotificationService_yourSeedsToday.
  ///
  /// In en, this message translates to:
  /// **'Your Seeds Today ✨'**
  String get liveNotificationService_yourSeedsToday;

  /// No description provided for @localReminderScheduler_sabiqRewardsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Sabiq Rewards Notifications'**
  String get localReminderScheduler_sabiqRewardsNotifications;

  /// No description provided for @localReminderScheduler_it.
  ///
  /// In en, this message translates to:
  /// **'It\\'**
  String get localReminderScheduler_it;

  /// No description provided for @localReminderScheduler_fridayReadSurahAl.
  ///
  /// In en, this message translates to:
  /// **'s Friday — read Surah Al-Kahf'**
  String get localReminderScheduler_fridayReadSurahAl;

  /// No description provided for @localReminderScheduler_whoeverRecitesSurahAl.
  ///
  /// In en, this message translates to:
  /// **'Whoever recites Surah Al-Kahf on Friday, light shines for them between the two Fridays.'**
  String get localReminderScheduler_whoeverRecitesSurahAl;

  /// No description provided for @localReminderScheduler_don.
  ///
  /// In en, this message translates to:
  /// **'Don\\'**
  String get localReminderScheduler_don;

  /// No description provided for @localReminderScheduler_missSurahAlKahf.
  ///
  /// In en, this message translates to:
  /// **'t miss Surah Al-Kahf today'**
  String get localReminderScheduler_missSurahAlKahf;

  /// No description provided for @localReminderScheduler_fewHoursToMaghrib.
  ///
  /// In en, this message translates to:
  /// **'A few hours to Maghrib — finish Surah Al-Kahf if you haven\\'**
  String get localReminderScheduler_fewHoursToMaghrib;

  /// No description provided for @quranApiService_notConnectedToQuran.
  ///
  /// In en, this message translates to:
  /// **'Not connected to Quran.com'**
  String get quranApiService_notConnectedToQuran;

  /// No description provided for @quranApiService_syncFailedBookmarkCould.
  ///
  /// In en, this message translates to:
  /// **'Sync failed, {failed} bookmark(s) could not be pushed to Quran.com (check token / endpoint).'**
  String quranApiService_syncFailedBookmarkCould(String failed);

  /// No description provided for @quranApiService_bookmarksAlreadyInSync.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks already in sync'**
  String get quranApiService_bookmarksAlreadyInSync;

  /// No description provided for @quranApiService_syncedBookmarksUpDown.
  ///
  /// In en, this message translates to:
  /// **'Synced {total} bookmarks ({uploaded} up, {downloaded} down)'**
  String quranApiService_syncedBookmarksUpDown(
    String total,
    String uploaded,
    String downloaded,
  );

  /// No description provided for @quranApiService_syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {e}'**
  String quranApiService_syncFailed(String e);

  /// No description provided for @streakService_warmingUp.
  ///
  /// In en, this message translates to:
  /// **'Warming Up'**
  String get streakService_warmingUp;

  /// No description provided for @streakService_oneWeek.
  ///
  /// In en, this message translates to:
  /// **'One Week'**
  String get streakService_oneWeek;

  /// No description provided for @streakService_twoWeeks.
  ///
  /// In en, this message translates to:
  /// **'Two Weeks'**
  String get streakService_twoWeeks;

  /// No description provided for @streakService_oneMonth.
  ///
  /// In en, this message translates to:
  /// **'One Month'**
  String get streakService_oneMonth;

  /// No description provided for @streakService_twoMonths.
  ///
  /// In en, this message translates to:
  /// **'Two Months'**
  String get streakService_twoMonths;

  /// No description provided for @streakService_theCenturion.
  ///
  /// In en, this message translates to:
  /// **'The Centurion'**
  String get streakService_theCenturion;

  /// No description provided for @streakService_1fc043.
  ///
  /// In en, this message translates to:
  /// **'{arg1} {arg2}'**
  String streakService_1fc043(String arg1, String arg2);

  /// No description provided for @streakService_dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{arg1}-day {arg2} streak · '**
  String streakService_dayStreak(String arg1, String arg2);

  /// No description provided for @streakService_bonusSeedsUnlocked.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} bonus Seeds unlocked'**
  String streakService_bonusSeedsUnlocked(String arg1);

  /// No description provided for @trackingService_c7528c.
  ///
  /// In en, this message translates to:
  /// **'{arg1} {arg2}'**
  String trackingService_c7528c(String arg1, String arg2);

  /// No description provided for @xpService_level.
  ///
  /// In en, this message translates to:
  /// **'{title} • Level {level}'**
  String xpService_level(String title, String level);

  /// No description provided for @xpService_newBadgeUnlocked.
  ///
  /// In en, this message translates to:
  /// **'New badge unlocked 🏆'**
  String get xpService_newBadgeUnlocked;

  /// No description provided for @xpService_you.
  ///
  /// In en, this message translates to:
  /// **'You\\'**
  String get xpService_you;

  /// No description provided for @xpService_dailyLoginBonus.
  ///
  /// In en, this message translates to:
  /// **'Daily login bonus'**
  String get xpService_dailyLoginBonus;

  /// No description provided for @xpService_seedsWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} Seeds · welcome back!'**
  String xpService_seedsWelcomeBack(String arg1);

  /// No description provided for @xpService_daySealed.
  ///
  /// In en, this message translates to:
  /// **'Day sealed 🌙'**
  String get xpService_daySealed;

  /// No description provided for @xpService_sabiqSeedsConfirmedBonus.
  ///
  /// In en, this message translates to:
  /// **'+{flushed} Sabiq Seeds confirmed! ({bonus} bonus for sealing)'**
  String xpService_sabiqSeedsConfirmedBonus(String flushed, String bonus);

  /// No description provided for @xpService_sabiqSeedsConfirmed.
  ///
  /// In en, this message translates to:
  /// **'+{flushed} Sabiq Seeds confirmed!'**
  String xpService_sabiqSeedsConfirmed(String flushed);

  /// No description provided for @dhikrExitCelebration_everyBreathCounts.
  ///
  /// In en, this message translates to:
  /// **'Every breath counts.'**
  String get dhikrExitCelebration_everyBreathCounts;

  /// No description provided for @impactAnimation_yourRewardHasBeen.
  ///
  /// In en, this message translates to:
  /// **'Your reward has been recorded.'**
  String get impactAnimation_yourRewardHasBeen;

  /// No description provided for @motivationalPopup_verilyWithHardshipComes.
  ///
  /// In en, this message translates to:
  /// **'Verily, with hardship comes ease.\\nEvery trial is a door to something greater.'**
  String get motivationalPopup_verilyWithHardshipComes;

  /// No description provided for @motivationalPopup_quranAlInshirah.
  ///
  /// In en, this message translates to:
  /// **'Quran • Al-Inshirah 94:6'**
  String get motivationalPopup_quranAlInshirah;

  /// No description provided for @motivationalPopup_quranAlAnkabut.
  ///
  /// In en, this message translates to:
  /// **'Quran • Al-Ankabut 29:45'**
  String get motivationalPopup_quranAlAnkabut;

  /// No description provided for @motivationalPopup_quranAlBaqarah.
  ///
  /// In en, this message translates to:
  /// **'Quran • Al-Baqarah 2:152'**
  String get motivationalPopup_quranAlBaqarah;

  /// No description provided for @motivationalPopup_quranAnNahl.
  ///
  /// In en, this message translates to:
  /// **'Quran • An-Nahl 16:18'**
  String get motivationalPopup_quranAnNahl;

  /// No description provided for @motivationalPopup_makeYourTimePrecious.
  ///
  /// In en, this message translates to:
  /// **'Make your time precious.\\nShare goodness with a friend today ,\\nevery good deed shared is a sadaqah.'**
  String get motivationalPopup_makeYourTimePrecious;

  /// No description provided for @motivationalPopup_guideOthersToGood.
  ///
  /// In en, this message translates to:
  /// **'Guide others to good, and you get its reward.'**
  String get motivationalPopup_guideOthersToGood;

  /// No description provided for @motivationalPopup_theBestOfPeople.
  ///
  /// In en, this message translates to:
  /// **'The best of people are those most beneficial to others.'**
  String get motivationalPopup_theBestOfPeople;

  /// No description provided for @motivationalPopup_verilyInTheRemembrance.
  ///
  /// In en, this message translates to:
  /// **'Verily, in the remembrance of Allah\\ndo hearts find rest.'**
  String get motivationalPopup_verilyInTheRemembrance;

  /// No description provided for @motivationalPopup_remindYourselfTimeIs.
  ///
  /// In en, this message translates to:
  /// **'Remind yourself, time is the most precious sadaqah.'**
  String get motivationalPopup_remindYourselfTimeIs;

  /// No description provided for @motivationalPopup_yourTimeIsYour.
  ///
  /// In en, this message translates to:
  /// **'Your time is your most\\nprecious asset. Invest it wisely\\nin what endures forever.'**
  String get motivationalPopup_yourTimeIsYour;

  /// No description provided for @motivationalPopup_quranAlAnfal.
  ///
  /// In en, this message translates to:
  /// **'Quran • Al-Anfal 8:28'**
  String get motivationalPopup_quranAlAnfal;

  /// No description provided for @motivationalPopup_takeAdvantageOfFive.
  ///
  /// In en, this message translates to:
  /// **'Take advantage of five before five.'**
  String get motivationalPopup_takeAdvantageOfFive;

  /// No description provided for @motivationalPopup_youHaveBeenRewarded.
  ///
  /// In en, this message translates to:
  /// **'You have been rewarded for\\nyour consistency today!'**
  String get motivationalPopup_youHaveBeenRewarded;

  /// No description provided for @motivationalPopup_seeds.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} Seeds'**
  String motivationalPopup_seeds(String arg1);

  /// No description provided for @motivationalPopup_seeds_b14996.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} Seeds'**
  String motivationalPopup_seeds_b14996(String arg1);

  /// No description provided for @motivationalPopup_readQuranPages.
  ///
  /// In en, this message translates to:
  /// **'Read 5 Quran Pages'**
  String get motivationalPopup_readQuranPages;

  /// No description provided for @motivationalPopup_completeNowEarnSeeds.
  ///
  /// In en, this message translates to:
  /// **'Complete now → earn +50 Seeds bonus'**
  String get motivationalPopup_completeNowEarnSeeds;

  /// No description provided for @motivationalPopup_completeDhikrSet.
  ///
  /// In en, this message translates to:
  /// **'Complete a Dhikr Set'**
  String get motivationalPopup_completeDhikrSet;

  /// No description provided for @motivationalPopup_finishYourAzkaarEarn.
  ///
  /// In en, this message translates to:
  /// **'Finish your Azkaar → earn +30 Seeds bonus'**
  String get motivationalPopup_finishYourAzkaarEarn;

  /// No description provided for @motivationalPopup_inviteFriend.
  ///
  /// In en, this message translates to:
  /// **'Invite a Friend'**
  String get motivationalPopup_inviteFriend;

  /// No description provided for @motivationalPopup_shareSabiqWithSomeone.
  ///
  /// In en, this message translates to:
  /// **'Share Sabiq with someone → earn +100 Seeds'**
  String get motivationalPopup_shareSabiqWithSomeone;

  /// No description provided for @motivationalPopup_keepYourSpiritualMomentum.
  ///
  /// In en, this message translates to:
  /// **'Keep your spiritual momentum going\\nand watch your Seeds grow ✨'**
  String get motivationalPopup_keepYourSpiritualMomentum;

  /// No description provided for @noorOffline_somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get noorOffline_somethingWentWrong;

  /// No description provided for @notificationsSheet_stayOnTopOf.
  ///
  /// In en, this message translates to:
  /// **'Stay on top of rewards & milestones'**
  String get notificationsSheet_stayOnTopOf;

  /// No description provided for @notificationsSheet_llBeNotifiedAbout.
  ///
  /// In en, this message translates to:
  /// **'ll be notified about rewards, streaks & milestones.'**
  String get notificationsSheet_llBeNotifiedAbout;

  /// No description provided for @notificationsSheet_inboxKeepsExistingItems.
  ///
  /// In en, this message translates to:
  /// **'Inbox keeps existing items but no new ones will arrive.'**
  String get notificationsSheet_inboxKeepsExistingItems;

  /// No description provided for @notificationsSheet_sabiqSeedsForSealing.
  ///
  /// In en, this message translates to:
  /// **'Sabiq Seeds for sealing today'**
  String get notificationsSheet_sabiqSeedsForSealing;

  /// No description provided for @notificationsSheet_ago.
  ///
  /// In en, this message translates to:
  /// **'{arg1}m ago'**
  String notificationsSheet_ago(String arg1);

  /// No description provided for @notificationsSheet_ago_5d4e7f.
  ///
  /// In en, this message translates to:
  /// **'{arg1}h ago'**
  String notificationsSheet_ago_5d4e7f(String arg1);

  /// No description provided for @notificationsSheet_ago_67b1d9.
  ///
  /// In en, this message translates to:
  /// **'{arg1}d ago'**
  String notificationsSheet_ago_67b1d9(String arg1);

  /// No description provided for @projectMediaCarousel_couldNotLoadVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not load video'**
  String get projectMediaCarousel_couldNotLoadVideo;

  /// No description provided for @quranExitCelebration_beautifulRecitation.
  ///
  /// In en, this message translates to:
  /// **'Beautiful recitation.'**
  String get quranExitCelebration_beautifulRecitation;

  /// No description provided for @quranExitCelebration_everyMomentCounts.
  ///
  /// In en, this message translates to:
  /// **'Every moment counts.'**
  String get quranExitCelebration_everyMomentCounts;

  /// No description provided for @sealCoinAnimation_e16fa4.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} '**
  String sealCoinAnimation_e16fa4(String arg1);

  /// No description provided for @authScreen_pleaseEnterYourEmail_d36dc6.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get authScreen_pleaseEnterYourEmail_d36dc6;

  /// No description provided for @authScreen_pleaseEnterYourPassword_0f8b9b.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get authScreen_pleaseEnterYourPassword_0f8b9b;

  /// No description provided for @authScreen_passwordMustBeAt_c936ae.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authScreen_passwordMustBeAt_c936ae;

  /// No description provided for @authScreen_alreadyHaveAnAccount_07e598.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get authScreen_alreadyHaveAnAccount_07e598;

  /// No description provided for @authScreen_haveAnAccountSign_ae2883.
  ///
  /// In en, this message translates to:
  /// **'t have an account? Sign Up'**
  String get authScreen_haveAnAccountSign_ae2883;

  /// No description provided for @qfAuthService_qfemailconflictexceptionAlreadyHasAn_e1592c.
  ///
  /// In en, this message translates to:
  /// **'QfEmailConflictException: {email} already has an account'**
  String qfAuthService_qfemailconflictexceptionAlreadyHasAn_e1592c(
    String email,
  );

  /// No description provided for @qfAuthService_openidOfflineAccessUser_fc4bcc.
  ///
  /// In en, this message translates to:
  /// **'openid offline_access user bookmark collection reading_session'**
  String get qfAuthService_openidOfflineAccessUser_fc4bcc;

  /// No description provided for @qfAuthService_tokenExchangeFailed_89d8a0.
  ///
  /// In en, this message translates to:
  /// **'Token exchange failed ({arg1}): {arg2}'**
  String qfAuthService_tokenExchangeFailed_89d8a0(String arg1, String arg2);

  /// No description provided for @qfAuthService_errorNullResponse_bd81c7.
  ///
  /// In en, this message translates to:
  /// **'ERROR: Null response'**
  String get qfAuthService_errorNullResponse_bd81c7;

  /// No description provided for @orphan_be2bf7_be2bf7.
  ///
  /// In en, this message translates to:
  /// **'{firstName} {lastInitial}.'**
  String orphan_be2bf7_be2bf7(String firstName, String lastInitial);

  /// No description provided for @akhirahBalanceScreen_subhanallahiWaBiHamdihi_b246c2.
  ///
  /// In en, this message translates to:
  /// **'“Subhanallahi wa bi-hamdihi” — said 100 times a day wipes sins, even like the foam of the sea. (Bukhari)'**
  String get akhirahBalanceScreen_subhanallahiWaBiHamdihi_b246c2;

  /// No description provided for @akhirahBalanceScreen_sayLaIlahaIllallah_27fc5f.
  ///
  /// In en, this message translates to:
  /// **'Say La ilaha illallah 100 times — equals freeing 10 slaves and 100 hasanat. (Bukhari)'**
  String get akhirahBalanceScreen_sayLaIlahaIllallah_27fc5f;

  /// No description provided for @akhirahBalanceScreen_lightOnTheTongue_ea6114.
  ///
  /// In en, this message translates to:
  /// **'Light on the tongue, heavy on the scales: Subhanallahi wa bi-hamdihi, Subhanallahil-azim. (Bukhari 6406)'**
  String get akhirahBalanceScreen_lightOnTheTongue_ea6114;

  /// No description provided for @akhirahBalanceScreen_theDhikrOfAllah_a23f17.
  ///
  /// In en, this message translates to:
  /// **'The dhikr of Allah is heavier on the scales than gold of equal weight. Keep going.'**
  String get akhirahBalanceScreen_theDhikrOfAllah_a23f17;

  /// No description provided for @akhirahBalanceScreen_yourTongueShouldStay_34816c.
  ///
  /// In en, this message translates to:
  /// **'“Your tongue should stay moist with the remembrance of Allah.” — Is it still moist?'**
  String get akhirahBalanceScreen_yourTongueShouldStay_34816c;

  /// No description provided for @akhirahBalanceScreen_astaghfirullahTheProphetSaid_7625ff.
  ///
  /// In en, this message translates to:
  /// **'Astaghfirullah — the Prophet ✍ said it 100 times a day, and he had no sin. How many have you?'**
  String get akhirahBalanceScreen_astaghfirullahTheProphetSaid_7625ff;

  /// No description provided for @akhirahBalanceScreen_whenYouRememberAllah_60f406.
  ///
  /// In en, this message translates to:
  /// **'When you remember Allah quietly, He remembers you in an assembly far greater.'**
  String get akhirahBalanceScreen_whenYouRememberAllah_60f406;

  /// No description provided for @akhirahBalanceScreen_reciteAyatAlKursi_d0751f.
  ///
  /// In en, this message translates to:
  /// **'Recite Ayat al-Kursi after every salah — nothing keeps you from Jannah but death.'**
  String get akhirahBalanceScreen_reciteAyatAlKursi_d0751f;

  /// No description provided for @akhirahBalanceScreen_oneAlhamdulillahFillsThe_4794bb.
  ///
  /// In en, this message translates to:
  /// **'One Alhamdulillah fills the scale. One Subhanallah fills what is between heaven and earth.'**
  String get akhirahBalanceScreen_oneAlhamdulillahFillsThe_4794bb;

  /// No description provided for @akhirahBalanceScreen_theRemembranceOfAllah_c99fe8.
  ///
  /// In en, this message translates to:
  /// **'“The remembrance of Allah is greater than everything else.” — Surah Al-Ankabut 29:45'**
  String get akhirahBalanceScreen_theRemembranceOfAllah_c99fe8;

  /// No description provided for @akhirahBalanceScreen_rememberMeWillRemember_1aca04.
  ///
  /// In en, this message translates to:
  /// **'“Remember Me — I will remember you.” — Surah Al-Baqarah 2:152. Will you?'**
  String get akhirahBalanceScreen_rememberMeWillRemember_1aca04;

  /// No description provided for @akhirahBalanceScreen_inTheRemembranceOf_20b541.
  ///
  /// In en, this message translates to:
  /// **'“In the remembrance of Allah, hearts find rest.” — Surah Ar-Ra’d 13:28'**
  String get akhirahBalanceScreen_inTheRemembranceOf_20b541;

  /// No description provided for @akhirahBalanceScreen_fiveMinutesOfDhikr_e12766.
  ///
  /// In en, this message translates to:
  /// **'Five minutes of dhikr now shapes the next 24 hours of your heart.'**
  String get akhirahBalanceScreen_fiveMinutesOfDhikr_e12766;

  /// No description provided for @akhirahBalanceScreen_streakIsnAboutToday_9157d8.
  ///
  /// In en, this message translates to:
  /// **'A streak isn’t about today — it’s about who you become in 30 days.'**
  String get akhirahBalanceScreen_streakIsnAboutToday_9157d8;

  /// No description provided for @akhirahBalanceScreen_smallDropsFillAn_1accce.
  ///
  /// In en, this message translates to:
  /// **'Small drops fill an ocean. Your daily dhikr is filling something far bigger.'**
  String get akhirahBalanceScreen_smallDropsFillAn_1accce;

  /// No description provided for @akhirahBalanceScreen_noOneSeesThe_0182c7.
  ///
  /// In en, this message translates to:
  /// **'No one sees the dhikr in your heart — but every angel writing your record does.'**
  String get akhirahBalanceScreen_noOneSeesThe_0182c7;

  /// No description provided for @akhirahBalanceScreen_theBiggestWinsAre_1b8fb6.
  ///
  /// In en, this message translates to:
  /// **'The biggest wins are built from the smallest daily habits. Don’t break the chain.'**
  String get akhirahBalanceScreen_theBiggestWinsAre_1b8fb6;

  /// No description provided for @akhirahBalanceScreen_youCameBackToday_a020b1.
  ///
  /// In en, this message translates to:
  /// **'You came back today. That’s already worship. Stay one more minute?'**
  String get akhirahBalanceScreen_youCameBackToday_a020b1;

  /// No description provided for @akhirahBalanceScreen_tomorrowPeaceIsBuilt_a72bd8.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow’s peace is built on today’s remembrance. Plant one more seed.'**
  String get akhirahBalanceScreen_tomorrowPeaceIsBuilt_a72bd8;

  /// No description provided for @akhirahBalanceScreen_areYouDoneAllah_06ca1d.
  ///
  /// In en, this message translates to:
  /// **'Are you done? Allah’s door is always open — even after you’ve closed it.'**
  String get akhirahBalanceScreen_areYouDoneAllah_06ca1d;

  /// No description provided for @akhirahBalanceScreen_dhikrIsTheLanguage_b1b983.
  ///
  /// In en, this message translates to:
  /// **'Dhikr is the language of the heart. Has yours spoken to its Lord today?'**
  String get akhirahBalanceScreen_dhikrIsTheLanguage_b1b983;

  /// No description provided for @akhirahBalanceScreen_everySubhanallahIsSadaqah_16b797.
  ///
  /// In en, this message translates to:
  /// **'Every Subhanallah is a sadaqah. How many will you give before sleep?'**
  String get akhirahBalanceScreen_everySubhanallahIsSadaqah_16b797;

  /// No description provided for @akhirahBalanceScreen_heartThatForgetsDhikr_3a6173.
  ///
  /// In en, this message translates to:
  /// **'A heart that forgets dhikr begins to rust. A heart that remembers stays alight.'**
  String get akhirahBalanceScreen_heartThatForgetsDhikr_3a6173;

  /// No description provided for @akhirahBalanceScreen_haveYouFortifiedYourself_17ccac.
  ///
  /// In en, this message translates to:
  /// **'Have you fortified yourself with the morning and evening adhkar today?'**
  String get akhirahBalanceScreen_haveYouFortifiedYourself_17ccac;

  /// No description provided for @akhirahBalanceScreen_thisSession_702ffc.
  ///
  /// In en, this message translates to:
  /// **'This session: +{arg1}'**
  String akhirahBalanceScreen_thisSession_702ffc(String arg1);

  /// No description provided for @akhirahBalanceScreen_seedsThisSession_cd9411.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} seeds this session'**
  String akhirahBalanceScreen_seedsThisSession_cd9411(String arg1);

  /// No description provided for @akhirahBalanceScreen_dayAvgAzkaarDay_c8f1b6.
  ///
  /// In en, this message translates to:
  /// **'7-day avg: {arg1} azkaar/day'**
  String akhirahBalanceScreen_dayAvgAzkaarDay_c8f1b6(String arg1);

  /// No description provided for @dashboardScreen_profileReturnedZeroRows_3ccedb.
  ///
  /// In en, this message translates to:
  /// **'Profile returned zero rows for {uid}'**
  String dashboardScreen_profileReturnedZeroRows_3ccedb(String uid);

  /// No description provided for @dashboardScreen_dashboardLoadError_6168de.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Load Error: {e}'**
  String dashboardScreen_dashboardLoadError_6168de(String e);

  /// No description provided for @dashboardScreen_invalidReferralCode_bb3b10.
  ///
  /// In en, this message translates to:
  /// **'Invalid referral code'**
  String get dashboardScreen_invalidReferralCode_bb3b10;

  /// No description provided for @dashboardScreen_cannotReferYourself_d836b8.
  ///
  /// In en, this message translates to:
  /// **'Cannot refer yourself'**
  String get dashboardScreen_cannotReferYourself_d836b8;

  /// No description provided for @dashboardScreen_sponsor_d48549.
  ///
  /// In en, this message translates to:
  /// **'Sponsor {name}, {arg1}'**
  String dashboardScreen_sponsor_d48549(String name, String arg1);

  /// No description provided for @dashboardScreen_dashboardDoesn_b8feb4.
  ///
  /// In en, this message translates to:
  /// **': 0, // dashboard doesn'**
  String get dashboardScreen_dashboardDoesn_b8feb4;

  /// No description provided for @dashboardScreen_today_261fbb.
  ///
  /// In en, this message translates to:
  /// **'{arg1} · {_lastAyah}  · +{_ayahsToday} today'**
  String dashboardScreen_today_261fbb(
    String arg1,
    String _lastAyah,
    String _ayahsToday,
  );

  /// No description provided for @dashboardScreen_606140_606140.
  ///
  /// In en, this message translates to:
  /// **'{arg1} · {_lastAyah}'**
  String dashboardScreen_606140_606140(String arg1, String _lastAyah);

  /// No description provided for @dashboardScreen_dayStreak_2934ca.
  ///
  /// In en, this message translates to:
  /// **'{arg1}-day streak'**
  String dashboardScreen_dayStreak_2934ca(String arg1);

  /// No description provided for @dashboardScreen_yourSabiqSeedsFund_3e8748.
  ///
  /// In en, this message translates to:
  /// **'Your Sabiq Seeds fund these projects'**
  String get dashboardScreen_yourSabiqSeedsFund_3e8748;

  /// No description provided for @dashboardScreen_active_2d214a.
  ///
  /// In en, this message translates to:
  /// **'{arg1} active'**
  String dashboardScreen_active_2d214a(String arg1);

  /// No description provided for @dashboardScreen_joinMeOnSabiq_755fb5.
  ///
  /// In en, this message translates to:
  /// **'Join me on Sabiq Rewards, earn Seeds for daily Quran, Dhikr & good deeds!\\n\\n'**
  String get dashboardScreen_joinMeOnSabiq_755fb5;

  /// No description provided for @dashboardScreen_useMyCodeAnd_7d13b3.
  ///
  /// In en, this message translates to:
  /// **'Use my code *{arg1}* and we both get 500 Sabiq Seeds!\\n\\n'**
  String dashboardScreen_useMyCodeAnd_7d13b3(String arg1);

  /// No description provided for @dashboardScreen_messageCopiedShareOr_7b977e.
  ///
  /// In en, this message translates to:
  /// **'Message copied, share or paste in WhatsApp!'**
  String get dashboardScreen_messageCopiedShareOr_7b977e;

  /// No description provided for @dashboardScreen_sabiqSeedsRewardedTo_c209d6.
  ///
  /// In en, this message translates to:
  /// **'500 Sabiq Seeds rewarded to you both!'**
  String get dashboardScreen_sabiqSeedsRewardedTo_c209d6;

  /// No description provided for @dashboardScreen_youHaveAlreadyUsed_f7c387.
  ///
  /// In en, this message translates to:
  /// **'You have already used a referral code.'**
  String get dashboardScreen_youHaveAlreadyUsed_f7c387;

  /// No description provided for @dashboardScreen_youCannotUseYour_b7dbfe.
  ///
  /// In en, this message translates to:
  /// **'You cannot use your own code.'**
  String get dashboardScreen_youCannotUseYour_b7dbfe;

  /// No description provided for @dashboardScreen_anErrorOccurredPlease_8ee486.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get dashboardScreen_anErrorOccurredPlease_8ee486;

  /// No description provided for @dashboardScreen_52b02c_52b02c.
  ///
  /// In en, this message translates to:
  /// **'{pts} '**
  String dashboardScreen_52b02c_52b02c(String pts);

  /// No description provided for @dashboardScreen_e4e562_e4e562.
  ///
  /// In en, this message translates to:
  /// **'{arg1}%'**
  String dashboardScreen_e4e562_e4e562(String arg1);

  /// No description provided for @dashboardScreen_seeDetailsForMore_54551e.
  ///
  /// In en, this message translates to:
  /// **'See Details for more Projects →'**
  String get dashboardScreen_seeDetailsForMore_54551e;

  /// No description provided for @dashboardScreen_yourTOTALSABIQSEEDS_f1d60a.
  ///
  /// In en, this message translates to:
  /// **'YOUR TOTAL SABIQ SEEDS'**
  String get dashboardScreen_yourTOTALSABIQSEEDS_f1d60a;

  /// No description provided for @dashboardScreen_viewCampaignDonate_450be4.
  ///
  /// In en, this message translates to:
  /// **'🤲  View Campaign & Donate'**
  String get dashboardScreen_viewCampaignDonate_450be4;

  /// No description provided for @dashboardScreen_yourRank_67be90.
  ///
  /// In en, this message translates to:
  /// **'Your Rank: {rankText}'**
  String dashboardScreen_yourRank_67be90(String rankText);

  /// No description provided for @dashboardScreen_d13a42_d13a42.
  ///
  /// In en, this message translates to:
  /// **'{_myPoints} {unit} • {arg1}'**
  String dashboardScreen_d13a42_d13a42(
    String _myPoints,
    String unit,
    String arg1,
  );

  /// No description provided for @dashboardScreen_beTheFirstOn_63de17.
  ///
  /// In en, this message translates to:
  /// **'Be the first on the board'**
  String get dashboardScreen_beTheFirstOn_63de17;

  /// No description provided for @dashboardScreen_readAnAyahOr_9c7ab7.
  ///
  /// In en, this message translates to:
  /// **'Read an ayah or dhikr to claim the top spot'**
  String get dashboardScreen_readAnAyahOr_9c7ab7;

  /// No description provided for @dashboardScreen_lvl_ac180d.
  ///
  /// In en, this message translates to:
  /// **'Lvl {level} · {arg1}'**
  String dashboardScreen_lvl_ac180d(String level, String arg1);

  /// No description provided for @dashboardScreen_sealWithin_381d5d.
  ///
  /// In en, this message translates to:
  /// **'Seal within {arg1}h'**
  String dashboardScreen_sealWithin_381d5d(String arg1);

  /// No description provided for @dashboardScreen_jazakallahDaySealed_70a34b.
  ///
  /// In en, this message translates to:
  /// **'JazakAllah!  Day sealed'**
  String get dashboardScreen_jazakallahDaySealed_70a34b;

  /// No description provided for @dashboardScreen_ofGoal_9660ee.
  ///
  /// In en, this message translates to:
  /// **'of {arg1} {arg2} goal'**
  String dashboardScreen_ofGoal_9660ee(String arg1, String arg2);

  /// No description provided for @dhikrHubScreen_propheticSupplications_907064.
  ///
  /// In en, this message translates to:
  /// **'Prophetic Supplications'**
  String get dhikrHubScreen_propheticSupplications_907064;

  /// No description provided for @dhikrHubScreen_morningEveningRemembrance_ec6bc2.
  ///
  /// In en, this message translates to:
  /// **'Morning & Evening Remembrance'**
  String get dhikrHubScreen_morningEveningRemembrance_ec6bc2;

  /// No description provided for @dhikrHubScreen_furtherSupplications_f72602.
  ///
  /// In en, this message translates to:
  /// **'Further Supplications'**
  String get dhikrHubScreen_furtherSupplications_f72602;

  /// No description provided for @dhikrHubScreen_closingRemembranceSalawat_5204e8.
  ///
  /// In en, this message translates to:
  /// **'Closing Remembrance & Salawat'**
  String get dhikrHubScreen_closingRemembranceSalawat_5204e8;

  /// No description provided for @dhikrHubScreen_hajjUmrahSupplications_f4d1b9.
  ///
  /// In en, this message translates to:
  /// **'Hajj & Umrah Supplications'**
  String get dhikrHubScreen_hajjUmrahSupplications_f4d1b9;

  /// No description provided for @dhikrHubScreen_falseHiddenAdd_c45662.
  ///
  /// In en, this message translates to:
  /// **'] == false) hidden.add(r['**
  String get dhikrHubScreen_falseHiddenAdd_c45662;

  /// No description provided for @dhikrScreen_indoPak_fd8751.
  ///
  /// In en, this message translates to:
  /// **'Indo pak'**
  String get dhikrScreen_indoPak_fd8751;

  /// No description provided for @dhikrScreen_default_8bd36b.
  ///
  /// In en, this message translates to:
  /// **'Default: {recommendedCount}'**
  String dhikrScreen_default_8bd36b(String recommendedCount);

  /// No description provided for @dhikrScreen_duaAzkarSettings_71de01.
  ///
  /// In en, this message translates to:
  /// **'Dua & Azkar Settings'**
  String get dhikrScreen_duaAzkarSettings_71de01;

  /// No description provided for @dhikrScreen_hideTheVisualArtwork_28b4d2.
  ///
  /// In en, this message translates to:
  /// **'Hide the visual artwork area'**
  String get dhikrScreen_hideTheVisualArtwork_28b4d2;

  /// No description provided for @dhikrScreen_pinTheIllustrationAt_5ec641.
  ///
  /// In en, this message translates to:
  /// **'Pin the illustration at the top while the Arabic text scrolls beneath it'**
  String get dhikrScreen_pinTheIllustrationAt_5ec641;

  /// No description provided for @dhikrScreen_readTimes_537f51.
  ///
  /// In en, this message translates to:
  /// **'Read {readCount} times'**
  String dhikrScreen_readTimes_537f51(String readCount);

  /// No description provided for @dhikrScreen_d08433_d08433.
  ///
  /// In en, this message translates to:
  /// **'{arg1} / {arg2}'**
  String dhikrScreen_d08433_d08433(String arg1, String arg2);

  /// No description provided for @dhikrScreen_alBaqarahAmanaAr_e9d62e.
  ///
  /// In en, this message translates to:
  /// **'Al-Baqarah 285 (Amana ar-Rasool)'**
  String get dhikrScreen_alBaqarahAmanaAr_e9d62e;

  /// No description provided for @dhikrScreen_alBaqarahAlifLam_71ad0e.
  ///
  /// In en, this message translates to:
  /// **'Al-Baqarah 1-5 (Alif Lam Mim)'**
  String get dhikrScreen_alBaqarahAlifLam_71ad0e;

  /// No description provided for @dhikrScreen_alBaqarahLaIkraha_e837fb.
  ///
  /// In en, this message translates to:
  /// **'Al-Baqarah 256 (La Ikraha)'**
  String get dhikrScreen_alBaqarahLaIkraha_e837fb;

  /// No description provided for @dhikrScreen_alBaqarahAllahuWaliyy_c2a18b.
  ///
  /// In en, this message translates to:
  /// **'Al-Baqarah 257 (Allahu Waliyy)'**
  String get dhikrScreen_alBaqarahAllahuWaliyy_c2a18b;

  /// No description provided for @dhikrScreen_salawatIbrahimiyyaDurood_171c60.
  ///
  /// In en, this message translates to:
  /// **'Salawat Ibrahimiyya (Durood)'**
  String get dhikrScreen_salawatIbrahimiyyaDurood_171c60;

  /// No description provided for @dhikrScreen_9a4c42_9a4c42.
  ///
  /// In en, this message translates to:
  /// **'{bismillah} ﴿{arg1}﴾\\n{rest}'**
  String dhikrScreen_9a4c42_9a4c42(String bismillah, String arg1, String rest);

  /// No description provided for @dhikrScreen_86f857_86f857.
  ///
  /// In en, this message translates to:
  /// **'\\u2060{matched}'**
  String dhikrScreen_86f857_86f857(String matched);

  /// No description provided for @dhikrScreen_49900d_49900d.
  ///
  /// In en, this message translates to:
  /// **'+{hasanaat}'**
  String dhikrScreen_49900d_49900d(String hasanaat);

  /// No description provided for @dhikrScreen_hisnulMuslimChapter_8745dc.
  ///
  /// In en, this message translates to:
  /// **'Hisnul Muslim, Chapter: '**
  String get dhikrScreen_hisnulMuslimChapter_8745dc;

  /// No description provided for @dhikrScreen_3856c1_3856c1.
  ///
  /// In en, this message translates to:
  /// **'{rawRef} | {bottomRef}'**
  String dhikrScreen_3856c1_3856c1(String rawRef, String bottomRef);

  /// No description provided for @dhikrScreen_bestOfBothWorlds_e1cc22.
  ///
  /// In en, this message translates to:
  /// **'Best of both worlds, refuge from the Fire'**
  String get dhikrScreen_bestOfBothWorlds_e1cc22;

  /// No description provided for @dhikrScreen_patienceAndSteadfastnessIn_114391.
  ///
  /// In en, this message translates to:
  /// **'Patience and steadfastness in every trial'**
  String get dhikrScreen_patienceAndSteadfastnessIn_114391;

  /// No description provided for @dhikrScreen_allahBurdensNoSoul_c8bf72.
  ///
  /// In en, this message translates to:
  /// **'Allah burdens no soul beyond its capacity'**
  String get dhikrScreen_allahBurdensNoSoul_c8bf72;

  /// No description provided for @dhikrScreen_keepTheHeartFirm_7729fe.
  ///
  /// In en, this message translates to:
  /// **'Keep the heart firm upon guidance'**
  String get dhikrScreen_keepTheHeartFirm_7729fe;

  /// No description provided for @dhikrScreen_faithAnsweredWithForgiveness_e8c93c.
  ///
  /// In en, this message translates to:
  /// **'Faith answered with forgiveness from Hell'**
  String get dhikrScreen_faithAnsweredWithForgiveness_e8c93c;

  /// No description provided for @dhikrScreen_allSovereigntyInAllah_a9e0b3.
  ///
  /// In en, this message translates to:
  /// **'All sovereignty in Allah\\'**
  String get dhikrScreen_allSovereigntyInAllah_a9e0b3;

  /// No description provided for @dhikrScreen_allahHearsEveryCall_bf9969.
  ///
  /// In en, this message translates to:
  /// **'Allah hears every call for righteous offspring'**
  String get dhikrScreen_allahHearsEveryCall_bf9969;

  /// No description provided for @dhikrScreen_countedWithTheWitnesses_99a05a.
  ///
  /// In en, this message translates to:
  /// **'Counted with the witnesses of truth'**
  String get dhikrScreen_countedWithTheWitnesses_99a05a;

  /// No description provided for @dhikrScreen_forgivenessFirmFeetAnd_28f209.
  ///
  /// In en, this message translates to:
  /// **'Forgiveness, firm feet, and victory'**
  String get dhikrScreen_forgivenessFirmFeetAnd_28f209;

  /// No description provided for @dhikrScreen_theDuaOfThose_0ee764.
  ///
  /// In en, this message translates to:
  /// **'The dua of those who reflect'**
  String get dhikrScreen_theDuaOfThose_0ee764;

  /// No description provided for @dhikrScreen_inscribedWithTheWitnesses_2257ce.
  ///
  /// In en, this message translates to:
  /// **'Inscribed with the witnesses of revelation'**
  String get dhikrScreen_inscribedWithTheWitnesses_2257ce;

  /// No description provided for @dhikrScreen_theDuaAllahAccepted_7e207c.
  ///
  /// In en, this message translates to:
  /// **'The dua Allah accepted from Adam ﷺ'**
  String get dhikrScreen_theDuaAllahAccepted_7e207c;

  /// No description provided for @dhikrScreen_spareUsTheCompany_c290d3.
  ///
  /// In en, this message translates to:
  /// **'Spare us the company of wrongdoers'**
  String get dhikrScreen_spareUsTheCompany_c290d3;

  /// No description provided for @dhikrScreen_neverTrialForThe_292b26.
  ///
  /// In en, this message translates to:
  /// **'Never a trial for the oppressors'**
  String get dhikrScreen_neverTrialForThe_292b26;

  /// No description provided for @dhikrScreen_refugeFromAskingWithout_0e04a4.
  ///
  /// In en, this message translates to:
  /// **'Refuge from asking without knowledge'**
  String get dhikrScreen_refugeFromAskingWithout_0e04a4;

  /// No description provided for @dhikrScreen_prayerForSafetyAnd_5f4e34.
  ///
  /// In en, this message translates to:
  /// **'s prayer for safety and faith'**
  String get dhikrScreen_prayerForSafetyAnd_5f4e34;

  /// No description provided for @dhikrScreen_steadfastInPrayerMe_8ce7b5.
  ///
  /// In en, this message translates to:
  /// **'Steadfast in prayer, me and my children'**
  String get dhikrScreen_steadfastInPrayerMe_8ce7b5;

  /// No description provided for @dhikrScreen_mercyForMeMy_3edb52.
  ///
  /// In en, this message translates to:
  /// **'Mercy for me, my parents, the believers'**
  String get dhikrScreen_mercyForMeMy_3edb52;

  /// No description provided for @dhikrScreen_prayerForParents_ae7e5c.
  ///
  /// In en, this message translates to:
  /// **'s prayer for parents'**
  String get dhikrScreen_prayerForParents_ae7e5c;

  /// No description provided for @dhikrScreen_entryOfTruthExit_88c367.
  ///
  /// In en, this message translates to:
  /// **'Entry of truth, exit of truth'**
  String get dhikrScreen_entryOfTruthExit_88c367;

  /// No description provided for @dhikrScreen_prayerOfTheYouth_1bf835.
  ///
  /// In en, this message translates to:
  /// **'Prayer of the youth of the cave'**
  String get dhikrScreen_prayerOfTheYouth_1bf835;

  /// No description provided for @dhikrScreen_askAllahForMore_07c189.
  ///
  /// In en, this message translates to:
  /// **'Ask Allah for more — of knowledge'**
  String get dhikrScreen_askAllahForMore_07c189;

  /// No description provided for @dhikrScreen_allahAnswersAndSaves_c337ab.
  ///
  /// In en, this message translates to:
  /// **'Allah answers and saves from every distress'**
  String get dhikrScreen_allahAnswersAndSaves_c337ab;

  /// No description provided for @dhikrScreen_allahIsTheBest_1adf97.
  ///
  /// In en, this message translates to:
  /// **'Allah is the best of inheritors'**
  String get dhikrScreen_allahIsTheBest_1adf97;

  /// No description provided for @dhikrScreen_blessedLandingWhereverYou_273aaf.
  ///
  /// In en, this message translates to:
  /// **'A blessed landing wherever you stop'**
  String get dhikrScreen_blessedLandingWhereverYou_273aaf;

  /// No description provided for @dhikrScreen_refugeFromTheWhispers_7ff5fd.
  ///
  /// In en, this message translates to:
  /// **'Refuge from the whispers of devils'**
  String get dhikrScreen_refugeFromTheWhispers_7ff5fd;

  /// No description provided for @dhikrScreen_mercyFromTheBest_b394bb.
  ///
  /// In en, this message translates to:
  /// **'Mercy from the Best of the Merciful'**
  String get dhikrScreen_mercyFromTheBest_b394bb;

  /// No description provided for @dhikrScreen_pardonAndMercyFrom_5d9eb1.
  ///
  /// In en, this message translates to:
  /// **'Pardon and mercy from the Most Merciful'**
  String get dhikrScreen_pardonAndMercyFrom_5d9eb1;

  /// No description provided for @dhikrScreen_piousSpousesAndRighteous_e9918c.
  ///
  /// In en, this message translates to:
  /// **'Pious spouses and righteous offspring'**
  String get dhikrScreen_piousSpousesAndRighteous_e9918c;

  /// No description provided for @dhikrScreen_prayerForThoseWho_1ccfb5.
  ///
  /// In en, this message translates to:
  /// **' prayer for those who repent'**
  String get dhikrScreen_prayerForThoseWho_1ccfb5;

  /// No description provided for @dhikrScreen_gratitudeForParentsRighteousness_966d90.
  ///
  /// In en, this message translates to:
  /// **'Gratitude for parents, righteousness in offspring'**
  String get dhikrScreen_gratitudeForParentsRighteousness_966d90;

  /// No description provided for @dhikrScreen_pleaGiftOfIshaq_5568af.
  ///
  /// In en, this message translates to:
  /// **'s plea — gift of Ishaq ﷺ'**
  String get dhikrScreen_pleaGiftOfIshaq_5568af;

  /// No description provided for @dhikrScreen_loveForTheBelievers_d0cae3.
  ///
  /// In en, this message translates to:
  /// **'Love for the believers before us'**
  String get dhikrScreen_loveForTheBelievers_d0cae3;

  /// No description provided for @dhikrScreen_pureTawakkulOnYou_02bc03.
  ///
  /// In en, this message translates to:
  /// **'s pure tawakkul — On You we rely'**
  String get dhikrScreen_pureTawakkulOnYou_02bc03;

  /// No description provided for @dhikrScreen_forgivenessForEveryBelieving_e256a1.
  ///
  /// In en, this message translates to:
  /// **'Forgiveness for every believing home'**
  String get dhikrScreen_forgivenessForEveryBelieving_e256a1;

  /// No description provided for @dhikrScreen_tasbeehByTheWeight_27484a.
  ///
  /// In en, this message translates to:
  /// **'Tasbeeh by the weight of Allah\\'**
  String get dhikrScreen_tasbeehByTheWeight_27484a;

  /// No description provided for @dhikrScreen_tasbeehByTheNumber_224c3f.
  ///
  /// In en, this message translates to:
  /// **'Tasbeeh by the number of all that He made'**
  String get dhikrScreen_tasbeehByTheNumber_224c3f;

  /// No description provided for @dhikrScreen_tasbeehThatFillsAll_4b1a52.
  ///
  /// In en, this message translates to:
  /// **'Tasbeeh that fills all that Allah created'**
  String get dhikrScreen_tasbeehThatFillsAll_4b1a52;

  /// No description provided for @dhikrScreen_paradiseSoughtTheFire_5740e3.
  ///
  /// In en, this message translates to:
  /// **'Paradise sought — the Fire\\'**
  String get dhikrScreen_paradiseSoughtTheFire_5740e3;

  /// No description provided for @dhikrScreen_cryToTheOne_30f419.
  ///
  /// In en, this message translates to:
  /// **'Cry to the One who hears, sees, and knows'**
  String get dhikrScreen_cryToTheOne_30f419;

  /// No description provided for @dhikrScreen_nameOnTheCorner_b6afeb.
  ///
  /// In en, this message translates to:
  /// **'s name on the corner of the Kaaba'**
  String get dhikrScreen_nameOnTheCorner_b6afeb;

  /// No description provided for @dhikrScreen_theDuaBetweenYemen_0bea3e.
  ///
  /// In en, this message translates to:
  /// **'The dua between Yemen Corner and Black Stone'**
  String get dhikrScreen_theDuaBetweenYemen_0bea3e;

  /// No description provided for @dhikrScreen_prayAtTheStation_178d24.
  ///
  /// In en, this message translates to:
  /// **'Pray at the station of Ibrahim ﷺ'**
  String get dhikrScreen_prayAtTheStation_178d24;

  /// No description provided for @dhikrScreen_tawheedDeclaredAtopSafa_828769.
  ///
  /// In en, this message translates to:
  /// **'Tawheed declared atop Safa and Marwah'**
  String get dhikrScreen_tawheedDeclaredAtopSafa_828769;

  /// No description provided for @dhikrScreen_reaffirmTheOnenessOf_8589ea.
  ///
  /// In en, this message translates to:
  /// **'Reaffirm the Oneness of Allah'**
  String get dhikrScreen_reaffirmTheOnenessOf_8589ea;

  /// No description provided for @dhikrScreen_magnifyAllahAtEvery_448549.
  ///
  /// In en, this message translates to:
  /// **'Magnify Allah at every threshold of Hajj'**
  String get dhikrScreen_magnifyAllahAtEvery_448549;

  /// No description provided for @dhikrScreen_magnifyAllahOnThe_0fbc83.
  ///
  /// In en, this message translates to:
  /// **'Magnify Allah on the day of sacrifice'**
  String get dhikrScreen_magnifyAllahOnThe_0fbc83;

  /// No description provided for @dhikrScreen_knowledgeProvisionHealingSought_9733f3.
  ///
  /// In en, this message translates to:
  /// **'Knowledge, provision, healing — sought in Makkah'**
  String get dhikrScreen_knowledgeProvisionHealingSought_9733f3;

  /// No description provided for @dhikrScreen_theDuaMostRepeated_a9da8d.
  ///
  /// In en, this message translates to:
  /// **'The dua most repeated by the Prophet ﷺ'**
  String get dhikrScreen_theDuaMostRepeated_a9da8d;

  /// No description provided for @dhikrScreen_refugeFromEveryTrial_8ca1b1.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every trial of life and death'**
  String get dhikrScreen_refugeFromEveryTrial_8ca1b1;

  /// No description provided for @dhikrScreen_refugeFromEveryWeakness_b1a834.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every weakness of body and soul'**
  String get dhikrScreen_refugeFromEveryWeakness_b1a834;

  /// No description provided for @dhikrScreen_refugeFromSevereTrial_0029f0.
  ///
  /// In en, this message translates to:
  /// **'Refuge from severe trial and enemy\\'**
  String get dhikrScreen_refugeFromSevereTrial_0029f0;

  /// No description provided for @dhikrScreen_religionSetRightWorld_3b0102.
  ///
  /// In en, this message translates to:
  /// **'Religion set right, world and Akhirah made best'**
  String get dhikrScreen_religionSetRightWorld_3b0102;

  /// No description provided for @dhikrScreen_guidancePietyVirtueSelf_cc439a.
  ///
  /// In en, this message translates to:
  /// **'Guidance, piety, virtue, self-sufficiency'**
  String get dhikrScreen_guidancePietyVirtueSelf_cc439a;

  /// No description provided for @dhikrScreen_refugeFromWeaknessWealth_d879f5.
  ///
  /// In en, this message translates to:
  /// **'Refuge from weakness — wealth of piety within'**
  String get dhikrScreen_refugeFromWeaknessWealth_d879f5;

  /// No description provided for @dhikrScreen_theGuiderOfHearts_1f40d9.
  ///
  /// In en, this message translates to:
  /// **'The Guider of hearts — turn ours to obedience'**
  String get dhikrScreen_theGuiderOfHearts_1f40d9;

  /// No description provided for @dhikrScreen_turnerOfHeartsMake_eba687.
  ///
  /// In en, this message translates to:
  /// **'Turner of hearts — make mine firm on the deen'**
  String get dhikrScreen_turnerOfHeartsMake_eba687;

  /// No description provided for @dhikrScreen_wellBeingInBoth_442958.
  ///
  /// In en, this message translates to:
  /// **'Well-being in both worlds'**
  String get dhikrScreen_wellBeingInBoth_442958;

  /// No description provided for @dhikrScreen_rewardsSaveFromDisgrace_8b71bb.
  ///
  /// In en, this message translates to:
  /// **'Rewards, save from disgrace and grave\\'**
  String get dhikrScreen_rewardsSaveFromDisgrace_8b71bb;

  /// No description provided for @dhikrScreen_mindForGoodVictory_582759.
  ///
  /// In en, this message translates to:
  /// **'Mind for good, victory for good'**
  String get dhikrScreen_mindForGoodVictory_582759;

  /// No description provided for @dhikrScreen_refugeFromEvilOf_0c8916.
  ///
  /// In en, this message translates to:
  /// **'Refuge from evil of every sense and limb'**
  String get dhikrScreen_refugeFromEvilOf_0c8916;

  /// No description provided for @dhikrScreen_theForgiverWhoLoves_e5d83f.
  ///
  /// In en, this message translates to:
  /// **'The Forgiver who loves the repentant'**
  String get dhikrScreen_theForgiverWhoLoves_e5d83f;

  /// No description provided for @dhikrScreen_takeMeBeforeYou_28ef55.
  ///
  /// In en, this message translates to:
  /// **'Take me before You take me astray'**
  String get dhikrScreen_takeMeBeforeYou_28ef55;

  /// No description provided for @dhikrScreen_everyGoodAndRefuge_4205e2.
  ///
  /// In en, this message translates to:
  /// **'Every good — and refuge from every evil'**
  String get dhikrScreen_everyGoodAndRefuge_4205e2;

  /// No description provided for @dhikrScreen_standingSittingLyingGuarded_254177.
  ///
  /// In en, this message translates to:
  /// **'Standing, sitting, lying — guarded in Islam'**
  String get dhikrScreen_standingSittingLyingGuarded_254177;

  /// No description provided for @dhikrScreen_refugeFromCowardiceMiserliness_9b59bd.
  ///
  /// In en, this message translates to:
  /// **'Refuge from cowardice, miserliness, fitnah'**
  String get dhikrScreen_refugeFromCowardiceMiserliness_9b59bd;

  /// No description provided for @dhikrScreen_forgivenessForJestAnd_e683b5.
  ///
  /// In en, this message translates to:
  /// **'Forgiveness for jest and serious, known and unknown'**
  String get dhikrScreen_forgivenessForJestAnd_e683b5;

  /// No description provided for @dhikrScreen_forgiveMeWithForgiveness_894a1a.
  ///
  /// In en, this message translates to:
  /// **'Forgive me with a forgiveness from You'**
  String get dhikrScreen_forgiveMeWithForgiveness_894a1a;

  /// No description provided for @dhikrScreen_submissionBeliefRepentanceFull_7338d6.
  ///
  /// In en, this message translates to:
  /// **'Submission, belief, repentance, full trust'**
  String get dhikrScreen_submissionBeliefRepentanceFull_7338d6;

  /// No description provided for @dhikrScreen_mercyForgivenessParadiseSaved_0d9edd.
  ///
  /// In en, this message translates to:
  /// **'Mercy, forgiveness, Paradise — saved from the Fire'**
  String get dhikrScreen_mercyForgivenessParadiseSaved_0d9edd;

  /// No description provided for @dhikrScreen_refugeFromEvilSeen_140ec4.
  ///
  /// In en, this message translates to:
  /// **'Refuge from evil seen and unseen'**
  String get dhikrScreen_refugeFromEvilSeen_140ec4;

  /// No description provided for @dhikrScreen_provisionThatLastsTill_dcef82.
  ///
  /// In en, this message translates to:
  /// **'Provision that lasts till life\\'**
  String get dhikrScreen_provisionThatLastsTill_dcef82;

  /// No description provided for @dhikrScreen_sinsForgivenHomeSpacious_2ac37c.
  ///
  /// In en, this message translates to:
  /// **'Sins forgiven, home spacious, provision blessed'**
  String get dhikrScreen_sinsForgivenHomeSpacious_2ac37c;

  /// No description provided for @dhikrScreen_favorAndMercyNone_f665cf.
  ///
  /// In en, this message translates to:
  /// **'Favor and mercy — none possesses them but You'**
  String get dhikrScreen_favorAndMercyNone_f665cf;

  /// No description provided for @dhikrScreen_refugeFromDrowningBurning_402b3e.
  ///
  /// In en, this message translates to:
  /// **'Refuge from drowning, burning, sudden death'**
  String get dhikrScreen_refugeFromDrowningBurning_402b3e;

  /// No description provided for @dhikrScreen_refugeFromHypocrisyShowiness_d863c2.
  ///
  /// In en, this message translates to:
  /// **'Refuge from hypocrisy, showiness, rebellion'**
  String get dhikrScreen_refugeFromHypocrisyShowiness_d863c2;

  /// No description provided for @dhikrScreen_refugeFromPovertyScarcity_03ef3d.
  ///
  /// In en, this message translates to:
  /// **'Refuge from poverty, scarcity, oppression'**
  String get dhikrScreen_refugeFromPovertyScarcity_03ef3d;

  /// No description provided for @dhikrScreen_refugeFromHeartThat_21f7ab.
  ///
  /// In en, this message translates to:
  /// **'Refuge from a heart that won\\'**
  String get dhikrScreen_refugeFromHeartThat_21f7ab;

  /// No description provided for @dhikrScreen_payMyDebtEnrich_f5affc.
  ///
  /// In en, this message translates to:
  /// **'Pay my debt, enrich me from poverty'**
  String get dhikrScreen_payMyDebtEnrich_f5affc;

  /// No description provided for @dhikrScreen_allahCalledByHis_c11af9.
  ///
  /// In en, this message translates to:
  /// **'Allah called by His most beautiful names'**
  String get dhikrScreen_allahCalledByHis_c11af9;

  /// No description provided for @dhikrScreen_theAccepterOfRepentance_4f2d60.
  ///
  /// In en, this message translates to:
  /// **'The Accepter of repentance always accepts'**
  String get dhikrScreen_theAccepterOfRepentance_4f2d60;

  /// No description provided for @dhikrScreen_anEasyReckoningOn_11b060.
  ///
  /// In en, this message translates to:
  /// **'An easy reckoning on the Day'**
  String get dhikrScreen_anEasyReckoningOn_11b060;

  /// No description provided for @dhikrScreen_remembranceGratitudeAndThe_d7ee7b.
  ///
  /// In en, this message translates to:
  /// **'Remembrance, gratitude, and the best worship'**
  String get dhikrScreen_remembranceGratitudeAndThe_d7ee7b;

  /// No description provided for @dhikrScreen_eternalBlissWithThe_dc255b.
  ///
  /// In en, this message translates to:
  /// **'Eternal bliss with the Prophet ﷺ in Firdaws'**
  String get dhikrScreen_eternalBlissWithThe_dc255b;

  /// No description provided for @dhikrScreen_forgiveSinsKnownHidden_ceda62.
  ///
  /// In en, this message translates to:
  /// **'Forgive sins — known, hidden, intended, mistaken'**
  String get dhikrScreen_forgiveSinsKnownHidden_ceda62;

  /// No description provided for @dhikrScreen_refugeFromBeingCrushed_4ba6ac.
  ///
  /// In en, this message translates to:
  /// **'Refuge from being crushed by debt and enemy'**
  String get dhikrScreen_refugeFromBeingCrushed_4ba6ac;

  /// No description provided for @dhikrScreen_askForParadiseRefuge_4bf2eb.
  ///
  /// In en, this message translates to:
  /// **'Ask for Paradise, refuge from the Fire'**
  String get dhikrScreen_askForParadiseRefuge_4bf2eb;

  /// No description provided for @dhikrScreen_forgiveGuideProvideProtect_e93013.
  ///
  /// In en, this message translates to:
  /// **'Forgive, guide, provide, protect'**
  String get dhikrScreen_forgiveGuideProvideProtect_e93013;

  /// No description provided for @dhikrScreen_sensesMadeBeneficialAnd_4da09c.
  ///
  /// In en, this message translates to:
  /// **'Senses made beneficial — and lasting'**
  String get dhikrScreen_sensesMadeBeneficialAnd_4da09c;

  /// No description provided for @dhikrScreen_theMostBeneficentThe_65d7a6.
  ///
  /// In en, this message translates to:
  /// **'The Most Beneficent, the Originator of all'**
  String get dhikrScreen_theMostBeneficentThe_65d7a6;

  /// No description provided for @dhikrScreen_allahTruthOwnerOf_d4bede.
  ///
  /// In en, this message translates to:
  /// **'Allah — Truth, Owner of all dominion'**
  String get dhikrScreen_allahTruthOwnerOf_d4bede;

  /// No description provided for @dhikrScreen_submissionWithFullSincerity_cbd7b6.
  ///
  /// In en, this message translates to:
  /// **'Submission with full sincerity'**
  String get dhikrScreen_submissionWithFullSincerity_cbd7b6;

  /// No description provided for @dhikrScreen_amongTheGuidedThe_e4d9d0.
  ///
  /// In en, this message translates to:
  /// **'Among the guided, the healthy, the chosen'**
  String get dhikrScreen_amongTheGuidedThe_e4d9d0;

  /// No description provided for @dhikrScreen_whatTheProphetAsked_e3a810.
  ///
  /// In en, this message translates to:
  /// **'What the Prophet ﷺ asked — I ask too'**
  String get dhikrScreen_whatTheProphetAsked_e3a810;

  /// No description provided for @dhikrScreen_sayyidAlIstighfarThe_51076a.
  ///
  /// In en, this message translates to:
  /// **'Sayyid al-Istighfar — the master of all repentance'**
  String get dhikrScreen_sayyidAlIstighfarThe_51076a;

  /// No description provided for @dhikrScreen_refugeFromEveryEvil_ea8dab.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every evil that comes by night'**
  String get dhikrScreen_refugeFromEveryEvil_ea8dab;

  /// No description provided for @dhikrScreen_blessEverySenseEvery_e7779d.
  ///
  /// In en, this message translates to:
  /// **'Bless every sense, every limb'**
  String get dhikrScreen_blessEverySenseEvery_e7779d;

  /// No description provided for @dhikrScreen_smallAndGreatFirst_dbcc00.
  ///
  /// In en, this message translates to:
  /// **'Small and great, first and last, open and secret'**
  String get dhikrScreen_smallAndGreatFirst_dbcc00;

  /// No description provided for @dhikrScreen_noneWithholdsWhatYou_c4dca7.
  ///
  /// In en, this message translates to:
  /// **'None withholds what You give, none gives what You hold'**
  String get dhikrScreen_noneWithholdsWhatYou_c4dca7;

  /// No description provided for @dhikrScreen_forgiveGuideProvideElevate_55fa36.
  ///
  /// In en, this message translates to:
  /// **'Forgive, guide, provide, elevate'**
  String get dhikrScreen_forgiveGuideProvideElevate_55fa36;

  /// No description provided for @dhikrScreen_increaseFavorBeKind_5fbc5c.
  ///
  /// In en, this message translates to:
  /// **'Increase favor, be kind, never displeased'**
  String get dhikrScreen_increaseFavorBeKind_5fbc5c;

  /// No description provided for @dhikrScreen_beautifyOurCharacterAs_cc5d8c.
  ///
  /// In en, this message translates to:
  /// **'Beautify our character as You beautified our creation'**
  String get dhikrScreen_beautifyOurCharacterAs_cc5d8c;

  /// No description provided for @dhikrScreen_firmInBeliefGuided_73f8af.
  ///
  /// In en, this message translates to:
  /// **'Firm in belief — guided and guiding'**
  String get dhikrScreen_firmInBeliefGuided_73f8af;

  /// No description provided for @dhikrScreen_wisdomAndWithIt_e8e5bd.
  ///
  /// In en, this message translates to:
  /// **'Wisdom — and with it, multitudes of good'**
  String get dhikrScreen_wisdomAndWithIt_e8e5bd;

  /// No description provided for @dhikrScreen_nameShieldsFromEvery_59e06f.
  ///
  /// In en, this message translates to:
  /// **'s name shields from every harm'**
  String get dhikrScreen_nameShieldsFromEvery_59e06f;

  /// No description provided for @dhikrScreen_mightAgainstEveryShaytan_73b152.
  ///
  /// In en, this message translates to:
  /// **'s might against every Shaytan'**
  String get dhikrScreen_mightAgainstEveryShaytan_73b152;

  /// No description provided for @dhikrScreen_dayBlessedFromBeginning_c6d87d.
  ///
  /// In en, this message translates to:
  /// **'A day blessed from beginning to end'**
  String get dhikrScreen_dayBlessedFromBeginning_c6d87d;

  /// No description provided for @dhikrScreen_witnessNoneDeservesWorship_385aa9.
  ///
  /// In en, this message translates to:
  /// **'Witness — none deserves worship but You'**
  String get dhikrScreen_witnessNoneDeservesWorship_385aa9;

  /// No description provided for @dhikrScreen_refugeFromHumiliatingOld_46a3f0.
  ///
  /// In en, this message translates to:
  /// **'Refuge from a humiliating old age'**
  String get dhikrScreen_refugeFromHumiliatingOld_46a3f0;

  /// No description provided for @dhikrScreen_guidedToTheBest_03e8d2.
  ///
  /// In en, this message translates to:
  /// **'Guided to the best, saved from the worst'**
  String get dhikrScreen_guidedToTheBest_03e8d2;

  /// No description provided for @dhikrScreen_faithSetRightHome_08f8e1.
  ///
  /// In en, this message translates to:
  /// **'Faith set right, home wide, provision blessed'**
  String get dhikrScreen_faithSetRightHome_08f8e1;

  /// No description provided for @dhikrScreen_refugeFromEveryInner_dc67c7.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every inner and outer disease'**
  String get dhikrScreen_refugeFromEveryInner_dc67c7;

  /// No description provided for @dhikrScreen_refugeFromEveryKind_dfbe62.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every kind of bad end'**
  String get dhikrScreen_refugeFromEveryKind_dfbe62;

  /// No description provided for @dhikrScreen_steadfastGratefulRightlyGuided_45b393.
  ///
  /// In en, this message translates to:
  /// **'Steadfast, grateful, rightly-guided heart'**
  String get dhikrScreen_steadfastGratefulRightlyGuided_45b393;

  /// No description provided for @dhikrScreen_theLoveOfAllah_3bf08a.
  ///
  /// In en, this message translates to:
  /// **'The love of Allah, His angels, His prophets'**
  String get dhikrScreen_theLoveOfAllah_3bf08a;

  /// No description provided for @dhikrScreen_loveOfAllahAbove_4c81b3.
  ///
  /// In en, this message translates to:
  /// **'Love of Allah above love of self'**
  String get dhikrScreen_loveOfAllahAbove_4c81b3;

  /// No description provided for @dhikrScreen_bestDeedsLastBest_2ff65e.
  ///
  /// In en, this message translates to:
  /// **'Best deeds last — best day is meeting You'**
  String get dhikrScreen_bestDeedsLastBest_2ff65e;

  /// No description provided for @dhikrScreen_pureLifeAndPeaceful_a7eb0f.
  ///
  /// In en, this message translates to:
  /// **'A pure life and a peaceful return'**
  String get dhikrScreen_pureLifeAndPeaceful_a7eb0f;

  /// No description provided for @dhikrScreen_patientGratefulSmallIn_059385.
  ///
  /// In en, this message translates to:
  /// **'Patient, grateful — small in own eyes'**
  String get dhikrScreen_patientGratefulSmallIn_059385;

  /// No description provided for @dhikrScreen_theBestRequestAnd_cd3f6f.
  ///
  /// In en, this message translates to:
  /// **'The best request and the best reward'**
  String get dhikrScreen_theBestRequestAnd_cd3f6f;

  /// No description provided for @dhikrScreen_theHighestLevelOf_221efa.
  ///
  /// In en, this message translates to:
  /// **'The highest level of Paradise'**
  String get dhikrScreen_theHighestLevelOf_221efa;

  /// No description provided for @dhikrScreen_firdawsTheBestOf_01be47.
  ///
  /// In en, this message translates to:
  /// **'Firdaws — the best of all that\\'**
  String get dhikrScreen_firdawsTheBestOf_01be47;

  /// No description provided for @dhikrScreen_mentionRaisedSinsErased_c6e2f3.
  ///
  /// In en, this message translates to:
  /// **'Mention raised, sins erased, heart purified'**
  String get dhikrScreen_mentionRaisedSinsErased_c6e2f3;

  /// No description provided for @dhikrScreen_mercyPleasureParadiseSaved_8b4a98.
  ///
  /// In en, this message translates to:
  /// **'Mercy, pleasure, Paradise — saved from Fire'**
  String get dhikrScreen_mercyPleasureParadiseSaved_8b4a98;

  /// No description provided for @dhikrScreen_noSinUncoveredNo_efd903.
  ///
  /// In en, this message translates to:
  /// **'No sin uncovered, no debt unpaid'**
  String get dhikrScreen_noSinUncoveredNo_efd903;

  /// No description provided for @dhikrScreen_mercyThatGuidesSets_89b7cf.
  ///
  /// In en, this message translates to:
  /// **'Mercy that guides, sets right, purifies'**
  String get dhikrScreen_mercyThatGuidesSets_89b7cf;

  /// No description provided for @dhikrScreen_trueBeliefCertainKnowledge_d27506.
  ///
  /// In en, this message translates to:
  /// **'True belief, certain knowledge, Allah\\'**
  String get dhikrScreen_trueBeliefCertainKnowledge_d27506;

  /// No description provided for @dhikrScreen_withTheProphetsThe_b2123f.
  ///
  /// In en, this message translates to:
  /// **'With the Prophets, the martyrs, the truthful'**
  String get dhikrScreen_withTheProphetsThe_b2123f;

  /// No description provided for @dhikrScreen_everyNeedEntrustedTo_8b33b6.
  ///
  /// In en, this message translates to:
  /// **'Every need entrusted to the Judge of all needs'**
  String get dhikrScreen_everyNeedEntrustedTo_8b33b6;

  /// No description provided for @dhikrScreen_bestOfWhatAllah_70d237.
  ///
  /// In en, this message translates to:
  /// **'Best of what Allah promised His servants'**
  String get dhikrScreen_bestOfWhatAllah_70d237;

  /// No description provided for @dhikrScreen_safetyOnTheDay_89cb9f.
  ///
  /// In en, this message translates to:
  /// **'Safety on the Day, Paradise on the Eternal Day'**
  String get dhikrScreen_safetyOnTheDay_89cb9f;

  /// No description provided for @dhikrScreen_glorifyTheOneOf_de3669.
  ///
  /// In en, this message translates to:
  /// **'Glorify the One of unmatched honor and knowledge'**
  String get dhikrScreen_glorifyTheOneOf_de3669;

  /// No description provided for @dhikrScreen_pardonPlentySecurityIn_d6b56a.
  ///
  /// In en, this message translates to:
  /// **'Pardon, plenty, security in deen and dunya'**
  String get dhikrScreen_pardonPlentySecurityIn_d6b56a;

  /// No description provided for @dhikrScreen_healthFaithEthicsSuccess_000fef.
  ///
  /// In en, this message translates to:
  /// **'Health, faith, ethics, success, mercy'**
  String get dhikrScreen_healthFaithEthicsSuccess_000fef;

  /// No description provided for @dhikrScreen_healthPurityEthicsAcceptance_b6929c.
  ///
  /// In en, this message translates to:
  /// **'Health, purity, ethics, acceptance'**
  String get dhikrScreen_healthPurityEthicsAcceptance_b6929c;

  /// No description provided for @dhikrScreen_guidedSecureVictorious_b56e05.
  ///
  /// In en, this message translates to:
  /// **'Guided, secure, victorious'**
  String get dhikrScreen_guidedSecureVictorious_b56e05;

  /// No description provided for @dhikrScreen_refugeFromEveryCreature_cbe2de.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every creature in Allah\\'**
  String get dhikrScreen_refugeFromEveryCreature_cbe2de;

  /// No description provided for @dhikrScreen_theOneWhoAnswers_f2e37f.
  ///
  /// In en, this message translates to:
  /// **'The One who answers the compelled and broken'**
  String get dhikrScreen_theOneWhoAnswers_f2e37f;

  /// No description provided for @dhikrScreen_morningReachedByAllah_b03f32.
  ///
  /// In en, this message translates to:
  /// **'Morning reached by Allah\\'**
  String get dhikrScreen_morningReachedByAllah_b03f32;

  /// No description provided for @dhikrScreen_refugeSoughtByMusa_176ee5.
  ///
  /// In en, this message translates to:
  /// **'Refuge sought by Musa, Isa, Ibrahim'**
  String get dhikrScreen_refugeSoughtByMusa_176ee5;

  /// No description provided for @dhikrScreen_allTheGoodPower_418dc3.
  ///
  /// In en, this message translates to:
  /// **'All the good — power, mercy, blessings'**
  String get dhikrScreen_allTheGoodPower_418dc3;

  /// No description provided for @dhikrScreen_allPraiseAndDominion_27662b.
  ///
  /// In en, this message translates to:
  /// **'All praise and dominion belong to You'**
  String get dhikrScreen_allPraiseAndDominion_27662b;

  /// No description provided for @dhikrScreen_pastPardonedFutureProtected_a8bfa1.
  ///
  /// In en, this message translates to:
  /// **'Past pardoned, future protected'**
  String get dhikrScreen_pastPardonedFutureProtected_a8bfa1;

  /// No description provided for @dhikrScreen_takeMyForelockTo_a44b8f.
  ///
  /// In en, this message translates to:
  /// **'Take my forelock to goodness'**
  String get dhikrScreen_takeMyForelockTo_a44b8f;

  /// No description provided for @dhikrScreen_strengthForWeaknessDignity_dce155.
  ///
  /// In en, this message translates to:
  /// **'Strength for weakness, dignity for shame'**
  String get dhikrScreen_strengthForWeaknessDignity_dce155;

  /// No description provided for @dhikrScreen_justiceForThoseWho_4e52f3.
  ///
  /// In en, this message translates to:
  /// **'Justice for those who block the truth'**
  String get dhikrScreen_justiceForThoseWho_4e52f3;

  /// No description provided for @dhikrScreen_refugeFromEveryFatal_b155a7.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every fatal calamity'**
  String get dhikrScreen_refugeFromEveryFatal_b155a7;

  /// No description provided for @dhikrScreen_refugeFromEveryBad_a9e27f.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every bad end and trial'**
  String get dhikrScreen_refugeFromEveryBad_a9e27f;

  /// No description provided for @dhikrScreen_turnBackEveryEvil_66e6fa.
  ///
  /// In en, this message translates to:
  /// **'Turn back every evil intention to its source'**
  String get dhikrScreen_turnBackEveryEvil_66e6fa;

  /// No description provided for @dhikrScreen_justiceAndRefugeAgainst_e4e734.
  ///
  /// In en, this message translates to:
  /// **'Justice and refuge against their evils'**
  String get dhikrScreen_justiceAndRefugeAgainst_e4e734;

  /// No description provided for @dhikrScreen_forgivenessForMeMy_27b932.
  ///
  /// In en, this message translates to:
  /// **'Forgiveness for me, my parents, all believers'**
  String get dhikrScreen_forgivenessForMeMy_27b932;

  /// No description provided for @dhikrScreen_purifyHeartDeedsTongue_10837e.
  ///
  /// In en, this message translates to:
  /// **'Purify heart, deeds, tongue, eyes'**
  String get dhikrScreen_purifyHeartDeedsTongue_10837e;

  /// No description provided for @dhikrScreen_selfContentWithAllah_68c73a.
  ///
  /// In en, this message translates to:
  /// **'A self content with Allah\\'**
  String get dhikrScreen_selfContentWithAllah_68c73a;

  /// No description provided for @dhikrScreen_youKnowMySecret_2b63c7.
  ///
  /// In en, this message translates to:
  /// **'You know my secret and my need'**
  String get dhikrScreen_youKnowMySecret_2b63c7;

  /// No description provided for @dhikrScreen_certaintyNothingHarmsWhat_e513d7.
  ///
  /// In en, this message translates to:
  /// **'Certainty: nothing harms what\\'**
  String get dhikrScreen_certaintyNothingHarmsWhat_e513d7;

  /// No description provided for @dhikrScreen_beliefLightAndLawful_e69a59.
  ///
  /// In en, this message translates to:
  /// **'Belief, light, and lawful provision'**
  String get dhikrScreen_beliefLightAndLawful_e69a59;

  /// No description provided for @dhikrScreen_totalLoveAndTotal_3d137e.
  ///
  /// In en, this message translates to:
  /// **'Total love and total struggle for Allah'**
  String get dhikrScreen_totalLoveAndTotal_3d137e;

  /// No description provided for @dhikrScreen_makeWhatYouWithheld_14be7d.
  ///
  /// In en, this message translates to:
  /// **'Make what You withheld a strength in obedience'**
  String get dhikrScreen_makeWhatYouWithheld_14be7d;

  /// No description provided for @dhikrScreen_praiseTheOwnerOf_244f8b.
  ///
  /// In en, this message translates to:
  /// **'Praise the Owner of every beautiful name'**
  String get dhikrScreen_praiseTheOwnerOf_244f8b;

  /// No description provided for @dhikrScreen_allahKnowsTheHearts_d6010c.
  ///
  /// In en, this message translates to:
  /// **'Allah knows the hearts, the heavens, and beyond'**
  String get dhikrScreen_allahKnowsTheHearts_d6010c;

  /// No description provided for @dhikrScreen_hopeBuiltOnAllah_217ad7.
  ///
  /// In en, this message translates to:
  /// **'Hope built on Allah\\'**
  String get dhikrScreen_hopeBuiltOnAllah_217ad7;

  /// No description provided for @dhikrScreen_belovedToTheBelievers_b1f5a3.
  ///
  /// In en, this message translates to:
  /// **'Beloved to the believers, free from the wicked'**
  String get dhikrScreen_belovedToTheBelievers_b1f5a3;

  /// No description provided for @dhikrScreen_mightPowerAndMajesty_91ca0a.
  ///
  /// In en, this message translates to:
  /// **'s might, power, and majesty'**
  String get dhikrScreen_mightPowerAndMajesty_91ca0a;

  /// No description provided for @dhikrScreen_gratefulPatientHelpfulTo_3710c6.
  ///
  /// In en, this message translates to:
  /// **'Grateful, patient, helpful to Allah\\'**
  String get dhikrScreen_gratefulPatientHelpfulTo_3710c6;

  /// No description provided for @dhikrScreen_withholdYourGoodFor_0d39a1.
  ///
  /// In en, this message translates to:
  /// **'t withhold Your good for my evil'**
  String get dhikrScreen_withholdYourGoodFor_0d39a1;

  /// No description provided for @dhikrScreen_settledLifeAmpleProvision_77b32b.
  ///
  /// In en, this message translates to:
  /// **'A settled life, ample provision, righteous deeds'**
  String get dhikrScreen_settledLifeAmpleProvision_77b32b;

  /// No description provided for @dhikrScreen_wealthInNeedingYou_547729.
  ///
  /// In en, this message translates to:
  /// **'Wealth in needing You — never free of You'**
  String get dhikrScreen_wealthInNeedingYou_547729;

  /// No description provided for @dhikrScreen_defectsCoveredFearsCalmed_a85797.
  ///
  /// In en, this message translates to:
  /// **'Defects covered, fears calmed, anguish lifted'**
  String get dhikrScreen_defectsCoveredFearsCalmed_a85797;

  /// No description provided for @dhikrScreen_openTheGatesOf_402eac.
  ///
  /// In en, this message translates to:
  /// **'Open the gates of mercy and generosity'**
  String get dhikrScreen_openTheGatesOf_402eac;

  /// No description provided for @dhikrScreen_holdUsInYour_b82607.
  ///
  /// In en, this message translates to:
  /// **'Hold us in Your safety — never abandon us'**
  String get dhikrScreen_holdUsInYour_b82607;

  /// No description provided for @dhikrScreen_withinYourSecurityYour_f72b6e.
  ///
  /// In en, this message translates to:
  /// **'Within Your security, Your goodness'**
  String get dhikrScreen_withinYourSecurityYour_f72b6e;

  /// No description provided for @dhikrScreen_everySinEveryDistress_eab128.
  ///
  /// In en, this message translates to:
  /// **'Every sin, every distress, every side'**
  String get dhikrScreen_everySinEveryDistress_eab128;

  /// No description provided for @dhikrScreen_helpInDeathIn_342d0b.
  ///
  /// In en, this message translates to:
  /// **'Help in death, in the grave, on the Bridge'**
  String get dhikrScreen_helpInDeathIn_342d0b;

  /// No description provided for @dhikrScreen_beautifiedLifeBlessedGifts_7f2384.
  ///
  /// In en, this message translates to:
  /// **'Beautified life, blessed gifts, kept favors'**
  String get dhikrScreen_beautifiedLifeBlessedGifts_7f2384;

  /// No description provided for @dhikrScreen_firmFootingBlessedEnd_c78f99.
  ///
  /// In en, this message translates to:
  /// **'Firm footing, blessed end, kept covenant'**
  String get dhikrScreen_firmFootingBlessedEnd_c78f99;

  /// No description provided for @dhikrScreen_hopesFulfilledEnemiesRepelled_afd008.
  ///
  /// In en, this message translates to:
  /// **'Hopes fulfilled, enemies repelled, affairs set right'**
  String get dhikrScreen_hopesFulfilledEnemiesRepelled_afd008;

  /// No description provided for @dhikrScreen_guidedToTheUpright_9e1527.
  ///
  /// In en, this message translates to:
  /// **'Guided to the upright, protected from the self'**
  String get dhikrScreen_guidedToTheUpright_9e1527;

  /// No description provided for @dhikrScreen_lightAndForgivenessFrom_3923eb.
  ///
  /// In en, this message translates to:
  /// **'Light and forgiveness from the Owner of the Throne'**
  String get dhikrScreen_lightAndForgivenessFrom_3923eb;

  /// No description provided for @dhikrScreen_forgivenessForWhatRepented_6a44f8.
  ///
  /// In en, this message translates to:
  /// **'Forgiveness for what I repented and returned to'**
  String get dhikrScreen_forgivenessForWhatRepented_6a44f8;

  /// No description provided for @dhikrScreen_understandingThatDrawsNear_e1455e.
  ///
  /// In en, this message translates to:
  /// **'Understanding that draws near to Allah'**
  String get dhikrScreen_understandingThatDrawsNear_e1455e;

  /// No description provided for @dhikrScreen_soulsDwellingInThe_1bd11b.
  ///
  /// In en, this message translates to:
  /// **'Souls dwelling in the heights of piety'**
  String get dhikrScreen_soulsDwellingInThe_1bd11b;

  /// No description provided for @dhikrScreen_crossTheBridgeOf_4f4ff3.
  ///
  /// In en, this message translates to:
  /// **'Cross the bridge of desire by patience'**
  String get dhikrScreen_crossTheBridgeOf_4f4ff3;

  /// No description provided for @dhikrScreen_followThePathOf_934775.
  ///
  /// In en, this message translates to:
  /// **'Follow the path of sincerity and certainty'**
  String get dhikrScreen_followThePathOf_934775;

  /// No description provided for @dhikrScreen_helpAgainstTheSoul_44a7db.
  ///
  /// In en, this message translates to:
  /// **'Help against the soul and against Shaytan'**
  String get dhikrScreen_helpAgainstTheSoul_44a7db;

  /// No description provided for @dhikrScreen_fearHappinessVictorySecurity_9017c9.
  ///
  /// In en, this message translates to:
  /// **'Fear, happiness, victory, security'**
  String get dhikrScreen_fearHappinessVictorySecurity_9017c9;

  /// No description provided for @dhikrScreen_entrustFamilyWealthChildren_1da596.
  ///
  /// In en, this message translates to:
  /// **'Entrust family, wealth, children — all to Allah'**
  String get dhikrScreen_entrustFamilyWealthChildren_1da596;

  /// No description provided for @dhikrScreen_faithGuardedFaithPreserved_88eecb.
  ///
  /// In en, this message translates to:
  /// **'Faith guarded, faith preserved'**
  String get dhikrScreen_faithGuardedFaithPreserved_88eecb;

  /// No description provided for @dhikrScreen_wellBeingTillThe_ee180d.
  ///
  /// In en, this message translates to:
  /// **'Well-being till the end — sealed with forgiveness'**
  String get dhikrScreen_wellBeingTillThe_ee180d;

  /// No description provided for @dhikrScreen_whatProtectsMeFrom_052090.
  ///
  /// In en, this message translates to:
  /// **'What protects me from this world\\'**
  String get dhikrScreen_whatProtectsMeFrom_052090;

  /// No description provided for @dhikrScreen_mercyOnEverySoul_a9a197.
  ///
  /// In en, this message translates to:
  /// **'Mercy on every soul\\'**
  String get dhikrScreen_mercyOnEverySoul_a9a197;

  /// No description provided for @dhikrScreen_burdenUsAsThose_78b517.
  ///
  /// In en, this message translates to:
  /// **'t burden us as those before were burdened'**
  String get dhikrScreen_burdenUsAsThose_78b517;

  /// No description provided for @dhikrScreen_mercyPardonForgivenessVictory_300143.
  ///
  /// In en, this message translates to:
  /// **'Mercy, pardon, forgiveness, victory'**
  String get dhikrScreen_mercyPardonForgivenessVictory_300143;

  /// No description provided for @dhikrScreen_allahNeverFailsHis_c2265a.
  ///
  /// In en, this message translates to:
  /// **'Allah never fails His promise'**
  String get dhikrScreen_allahNeverFailsHis_c2265a;

  /// No description provided for @dhikrScreen_recordUsWithThe_b93190.
  ///
  /// In en, this message translates to:
  /// **'Record us with the witnesses of truth'**
  String get dhikrScreen_recordUsWithThe_b93190;

  /// No description provided for @dhikrScreen_forgivenessFirmnessAndVictory_a8b674.
  ///
  /// In en, this message translates to:
  /// **'Forgiveness, firmness, and victory'**
  String get dhikrScreen_forgivenessFirmnessAndVictory_a8b674;

  /// No description provided for @dhikrScreen_creationHasPurposeRefuge_ce2eee.
  ///
  /// In en, this message translates to:
  /// **'Creation has purpose — refuge from the Fire'**
  String get dhikrScreen_creationHasPurposeRefuge_ce2eee;

  /// No description provided for @dhikrScreen_refugeFromTheDisgrace_605b1b.
  ///
  /// In en, this message translates to:
  /// **'Refuge from the disgrace of the Fire'**
  String get dhikrScreen_refugeFromTheDisgrace_605b1b;

  /// No description provided for @dhikrScreen_heardBelievedAskingForgiveness_d5387f.
  ///
  /// In en, this message translates to:
  /// **'Heard, believed, asking forgiveness'**
  String get dhikrScreen_heardBelievedAskingForgiveness_d5387f;

  /// No description provided for @dhikrScreen_sinsForgivenDeathAmong_bd82ed.
  ///
  /// In en, this message translates to:
  /// **'Sins forgiven — death among the righteous'**
  String get dhikrScreen_sinsForgivenDeathAmong_bd82ed;

  /// No description provided for @dhikrScreen_promisedRewardNeverDisgraced_490396.
  ///
  /// In en, this message translates to:
  /// **'Promised reward — never disgraced on Resurrection'**
  String get dhikrScreen_promisedRewardNeverDisgraced_490396;

  /// No description provided for @dhikrScreen_provisionAndSignsFrom_81db14.
  ///
  /// In en, this message translates to:
  /// **'Provision and signs from the heavens'**
  String get dhikrScreen_provisionAndSignsFrom_81db14;

  /// No description provided for @dhikrScreen_duaTheDuaOf_4b9d01.
  ///
  /// In en, this message translates to:
  /// **'s dua — the dua of every repentant'**
  String get dhikrScreen_duaTheDuaOf_4b9d01;

  /// No description provided for @dhikrScreen_spareUsFromThe_79732a.
  ///
  /// In en, this message translates to:
  /// **'Spare us from the company of wrongdoers'**
  String get dhikrScreen_spareUsFromThe_79732a;

  /// No description provided for @dhikrScreen_patienceTillTheEnd_a8a4c4.
  ///
  /// In en, this message translates to:
  /// **'Patience till the end, death upon submission'**
  String get dhikrScreen_patienceTillTheEnd_a8a4c4;

  /// No description provided for @dhikrScreen_hiddenInEveryChest_ce7671.
  ///
  /// In en, this message translates to:
  /// **'s hidden in every chest'**
  String get dhikrScreen_hiddenInEveryChest_ce7671;

  /// No description provided for @dhikrScreen_prayerForPrayerAccepted_e68fa6.
  ///
  /// In en, this message translates to:
  /// **'s prayer for prayer accepted'**
  String get dhikrScreen_prayerForPrayerAccepted_e68fa6;

  /// No description provided for @dhikrScreen_mercyGrantedGuidancePrepared_5c6f63.
  ///
  /// In en, this message translates to:
  /// **'Mercy granted, guidance prepared'**
  String get dhikrScreen_mercyGrantedGuidancePrepared_5c6f63;

  /// No description provided for @dhikrScreen_duaBeforePharaoh_2d90cd.
  ///
  /// In en, this message translates to:
  /// **'s dua before Pharaoh'**
  String get dhikrScreen_duaBeforePharaoh_2d90cd;

  /// No description provided for @dhikrScreen_refugeFromClingingEvil_b1e6e4.
  ///
  /// In en, this message translates to:
  /// **'Refuge from a clinging, evil punishment'**
  String get dhikrScreen_refugeFromClingingEvil_b1e6e4;

  /// No description provided for @dhikrScreen_piousSpousesRighteousChildren_64225f.
  ///
  /// In en, this message translates to:
  /// **'Pious spouses, righteous children, leadership'**
  String get dhikrScreen_piousSpousesRighteousChildren_64225f;

  /// No description provided for @dhikrScreen_allahIsEverThankful_464c97.
  ///
  /// In en, this message translates to:
  /// **'Allah is ever-thankful for every effort'**
  String get dhikrScreen_allahIsEverThankful_464c97;

  /// No description provided for @dhikrScreen_mercyEncompassingEveryRepentant_fb0759.
  ///
  /// In en, this message translates to:
  /// **'Mercy encompassing every repentant soul'**
  String get dhikrScreen_mercyEncompassingEveryRepentant_fb0759;

  /// No description provided for @dhikrScreen_mercyOnThatDay_a1b18b.
  ///
  /// In en, this message translates to:
  /// **'Mercy on that Day — the great success'**
  String get dhikrScreen_mercyOnThatDay_a1b18b;

  /// No description provided for @dhikrScreen_loveAndForgivenessFor_660a56.
  ///
  /// In en, this message translates to:
  /// **'Love and forgiveness for earlier believers'**
  String get dhikrScreen_loveAndForgivenessFor_660a56;

  /// No description provided for @dhikrScreen_kindnessAndMercyUpon_1c62c8.
  ///
  /// In en, this message translates to:
  /// **'Kindness and mercy upon Allah\\'**
  String get dhikrScreen_kindnessAndMercyUpon_1c62c8;

  /// No description provided for @dhikrScreen_pureTawakkulToYou_389089.
  ///
  /// In en, this message translates to:
  /// **'s pure tawakkul — to You we return'**
  String get dhikrScreen_pureTawakkulToYou_389089;

  /// No description provided for @dhikrScreen_neverFitnahForThose_dc1363.
  ///
  /// In en, this message translates to:
  /// **'Never a fitnah for those who disbelieve'**
  String get dhikrScreen_neverFitnahForThose_dc1363;

  /// No description provided for @dhikrScreen_completeTheLightForgive_fd7380.
  ///
  /// In en, this message translates to:
  /// **'Complete the light — forgive us'**
  String get dhikrScreen_completeTheLightForgive_fd7380;

  /// No description provided for @dhikrScreen_strongerThanServantThe_4cc56e.
  ///
  /// In en, this message translates to:
  /// **'Stronger than a servant — the night\\'**
  String get dhikrScreen_strongerThanServantThe_4cc56e;

  /// No description provided for @dhikrScreen_refugeFromEveryVisible_b81e69.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every visible evil before sleep'**
  String get dhikrScreen_refugeFromEveryVisible_b81e69;

  /// No description provided for @dhikrScreen_refugeFromEveryWhisper_b030ed.
  ///
  /// In en, this message translates to:
  /// **'Refuge from every whisper before sleep'**
  String get dhikrScreen_refugeFromEveryWhisper_b030ed;

  /// No description provided for @dhikrScreen_guardedByAnAngel_65d1c1.
  ///
  /// In en, this message translates to:
  /// **'Guarded by an angel until morning'**
  String get dhikrScreen_guardedByAnAngel_65d1c1;

  /// No description provided for @dhikrScreen_twoVersesThatSuffice_1941c5.
  ///
  /// In en, this message translates to:
  /// **'Two verses that suffice for the whole night'**
  String get dhikrScreen_twoVersesThatSuffice_1941c5;

  /// No description provided for @dhikrScreen_pureTawheedDeclaredBefore_50673a.
  ///
  /// In en, this message translates to:
  /// **'Pure tawheed declared before sleep'**
  String get dhikrScreen_pureTawheedDeclaredBefore_50673a;

  /// No description provided for @dhikrScreen_sleepIsSmallDeath_b4b84d.
  ///
  /// In en, this message translates to:
  /// **'Sleep is a small death — entrusted to Allah'**
  String get dhikrScreen_sleepIsSmallDeath_b4b84d;

  /// No description provided for @dhikrScreen_whoeverDiesThatNight_75dda7.
  ///
  /// In en, this message translates to:
  /// **'Whoever dies that night dies on fitrah'**
  String get dhikrScreen_whoeverDiesThatNight_75dda7;

  /// No description provided for @dhikrScreen_guardTheSoulThat_a0850e.
  ///
  /// In en, this message translates to:
  /// **'Guard the soul that returns, or have mercy'**
  String get dhikrScreen_guardTheSoulThat_a0850e;

  /// No description provided for @dhikrScreen_refugeFromThePunishment_18162a.
  ///
  /// In en, this message translates to:
  /// **'Refuge from the punishment of that Day'**
  String get dhikrScreen_refugeFromThePunishment_18162a;

  /// No description provided for @dhikrScreen_gratitudeForShelterFood_1f5e94.
  ///
  /// In en, this message translates to:
  /// **'Gratitude for shelter, food, and care'**
  String get dhikrScreen_gratitudeForShelterFood_1f5e94;

  /// No description provided for @dhikrScreen_handOverTheSoul_fda192.
  ///
  /// In en, this message translates to:
  /// **'Hand over the soul before sleep'**
  String get dhikrScreen_handOverTheSoul_fda192;

  /// No description provided for @dhikrScreen_joinTheHighestAssembly_68e2d3.
  ///
  /// In en, this message translates to:
  /// **'Join the highest assembly while you sleep'**
  String get dhikrScreen_joinTheHighestAssembly_68e2d3;

  /// No description provided for @dhikrScreen_gratitudeBeforeClosingThe_20f3db.
  ///
  /// In en, this message translates to:
  /// **'Gratitude before closing the eyes'**
  String get dhikrScreen_gratitudeBeforeClosingThe_20f3db;

  /// No description provided for @dhikrScreen_surahAsSajdahRecited_a4beaa.
  ///
  /// In en, this message translates to:
  /// **'Surah As-Sajdah recited before sleep'**
  String get dhikrScreen_surahAsSajdahRecited_a4beaa;

  /// No description provided for @dhikrScreen_refugeFromEvilBefore_a5d312.
  ///
  /// In en, this message translates to:
  /// **'Refuge from evil before entering the toilet'**
  String get dhikrScreen_refugeFromEvilBefore_a5d312;

  /// No description provided for @dhikrScreen_seekForgivenessAsYou_f14da9.
  ///
  /// In en, this message translates to:
  /// **'Seek forgiveness as you leave'**
  String get dhikrScreen_seekForgivenessAsYou_f14da9;

  /// No description provided for @dhikrScreen_bismillahEveryBiteBegins_8a678d.
  ///
  /// In en, this message translates to:
  /// **'Bismillah — every bite begins with Allah'**
  String get dhikrScreen_bismillahEveryBiteBegins_8a678d;

  /// No description provided for @dhikrScreen_catchUpTheName_e6d0d6.
  ///
  /// In en, this message translates to:
  /// **'Catch up the name — Allah at start and end'**
  String get dhikrScreen_catchUpTheName_e6d0d6;

  /// No description provided for @dhikrScreen_threeSunnahDuasTo_a56769.
  ///
  /// In en, this message translates to:
  /// **'Three Sunnah duas to thank Allah after eating'**
  String get dhikrScreen_threeSunnahDuasTo_a56769;

  /// No description provided for @dhikrScreen_beginWithAllahThe_a64af2.
  ///
  /// In en, this message translates to:
  /// **'Begin with Allah, the Most Merciful, before drinking'**
  String get dhikrScreen_beginWithAllahThe_a64af2;

  /// No description provided for @dhikrScreen_openTheEightDoors_011a50.
  ///
  /// In en, this message translates to:
  /// **'Open the eight doors of Paradise after wudu'**
  String get dhikrScreen_openTheEightDoors_011a50;

  /// No description provided for @dhikrScreen_openTheDoorsOf_15e084.
  ///
  /// In en, this message translates to:
  /// **'Open the doors of Allah\\'**
  String get dhikrScreen_openTheDoorsOf_15e084;

  /// No description provided for @dhikrScreen_bountyAsYouLeave_a06fc6.
  ///
  /// In en, this message translates to:
  /// **'s bounty as you leave the masjid'**
  String get dhikrScreen_bountyAsYouLeave_a06fc6;

  /// No description provided for @dhikrScreen_mayAllahGuideYou_af987e.
  ///
  /// In en, this message translates to:
  /// **'May Allah guide you and rectify your state'**
  String get dhikrScreen_mayAllahGuideYou_af987e;

  /// No description provided for @dhikrScreen_askAllahLordOf_4a3eb0.
  ///
  /// In en, this message translates to:
  /// **'Ask Allah, Lord of the Throne, to grant healing'**
  String get dhikrScreen_askAllahLordOf_4a3eb0;

  /// No description provided for @dhikrScreen_allahIsTheOnly_9750c1.
  ///
  /// In en, this message translates to:
  /// **'Allah is the only One who cures'**
  String get dhikrScreen_allahIsTheOnly_9750c1;

  /// No description provided for @dhikrScreen_shieldChildrenWithAllah_858245.
  ///
  /// In en, this message translates to:
  /// **'Shield children with Allah\\'**
  String get dhikrScreen_shieldChildrenWithAllah_858245;

  /// No description provided for @dhikrScreen_anicPrayerForOne_e18aca.
  ///
  /// In en, this message translates to:
  /// **'anic prayer for one\\'**
  String get dhikrScreen_anicPrayerForOne_e18aca;

  /// No description provided for @dhikrScreen_twoPhrasesBelovedTo_5d16a7.
  ///
  /// In en, this message translates to:
  /// **'Two phrases beloved to the Most Merciful'**
  String get dhikrScreen_twoPhrasesBelovedTo_5d16a7;

  /// No description provided for @dhikrScreen_allahLovesToPardon_a64d0a.
  ///
  /// In en, this message translates to:
  /// **'Allah loves to pardon — so ask'**
  String get dhikrScreen_allahLovesToPardon_a64d0a;

  /// No description provided for @dhikrScreen_treasureFromBeneathThe_87d578.
  ///
  /// In en, this message translates to:
  /// **'A treasure from beneath the Throne'**
  String get dhikrScreen_treasureFromBeneathThe_87d578;

  /// No description provided for @dhikrScreen_theFourPhrasesDearest_680ef8.
  ///
  /// In en, this message translates to:
  /// **'The four phrases dearest to Allah'**
  String get dhikrScreen_theFourPhrasesDearest_680ef8;

  /// No description provided for @dhikrScreen_theDuaThatReleases_ddc7eb.
  ///
  /// In en, this message translates to:
  /// **'The dua that releases from every distress'**
  String get dhikrScreen_theDuaThatReleases_ddc7eb;

  /// No description provided for @dhikrScreen_protectionForHomeAnd_0c4973.
  ///
  /// In en, this message translates to:
  /// **'s protection for home and offspring'**
  String get dhikrScreen_protectionForHomeAnd_0c4973;

  /// No description provided for @dhikrScreen_theCompleteDhikrOf_31b993.
  ///
  /// In en, this message translates to:
  /// **'The complete dhikr of Tawheed'**
  String get dhikrScreen_theCompleteDhikrOf_31b993;

  /// No description provided for @dhikrScreen_trialPurifiedByAllah_39fb26.
  ///
  /// In en, this message translates to:
  /// **'Trial purified by Allah\\'**
  String get dhikrScreen_trialPurifiedByAllah_39fb26;

  /// No description provided for @dhikrScreen_guidanceBeforeAnyChoice_50eb02.
  ///
  /// In en, this message translates to:
  /// **'s guidance before any choice'**
  String get dhikrScreen_guidanceBeforeAnyChoice_50eb02;

  /// No description provided for @dhikrScreen_completeRuqyaSequenceFatihah_5ced40.
  ///
  /// In en, this message translates to:
  /// **'Complete ruqya sequence — Fatihah and refuge'**
  String get dhikrScreen_completeRuqyaSequenceFatihah_5ced40;

  /// No description provided for @dhikrScreen_sinsForgivenEvenIf_cd9a85.
  ///
  /// In en, this message translates to:
  /// **'Sins forgiven, even if like the foam of the sea'**
  String get dhikrScreen_sinsForgivenEvenIf_cd9a85;

  /// No description provided for @dhikrScreen_freedHasanatSinsErased_54ebbb.
  ///
  /// In en, this message translates to:
  /// **'10 freed · 100 hasanat · 100 sins erased · Shaytan repelled'**
  String get dhikrScreen_freedHasanatSinsErased_54ebbb;

  /// No description provided for @dhikrScreen_blessingsDescendFromAllah_41e8f6.
  ///
  /// In en, this message translates to:
  /// **'10 blessings descend from Allah upon you'**
  String get dhikrScreen_blessingsDescendFromAllah_41e8f6;

  /// No description provided for @dhikrScreen_askAllahToBless_3470fe.
  ///
  /// In en, this message translates to:
  /// **'Ask Allah to bless and beautify your day'**
  String get dhikrScreen_askAllahToBless_3470fe;

  /// No description provided for @dhikrScreen_guaranteedJannahIfYou_6f7054.
  ///
  /// In en, this message translates to:
  /// **'Guaranteed Jannah, if you die this day'**
  String get dhikrScreen_guaranteedJannahIfYou_6f7054;

  /// No description provided for @dhikrScreen_yourLifeEntrustedTo_77feba.
  ///
  /// In en, this message translates to:
  /// **'Your life entrusted to the Ever-Living'**
  String get dhikrScreen_yourLifeEntrustedTo_77feba;

  /// No description provided for @dhikrScreen_allEvilInHis_f02365.
  ///
  /// In en, this message translates to:
  /// **'All evil in His creation repelled from you'**
  String get dhikrScreen_allEvilInHis_f02365;

  /// No description provided for @dhikrScreen_nothingShallHarmYou_cbc2fc.
  ///
  /// In en, this message translates to:
  /// **'Nothing shall harm you, by perfect words'**
  String get dhikrScreen_nothingShallHarmYou_cbc2fc;

  /// No description provided for @dhikrScreen_shieldYourselfFromMinor_2a73ed.
  ///
  /// In en, this message translates to:
  /// **'Shield yourself from minor and major shirk, morning & evening'**
  String get dhikrScreen_shieldYourselfFromMinor_2a73ed;

  /// No description provided for @dhikrScreen_completeProtectionInThe_620c30.
  ///
  /// In en, this message translates to:
  /// **'Complete protection in the name of Allah'**
  String get dhikrScreen_completeProtectionInThe_620c30;

  /// No description provided for @dhikrScreen_weightierThanAllVoluntary_7af10a.
  ///
  /// In en, this message translates to:
  /// **'Weightier than all voluntary prayers, from dawn till dusk'**
  String get dhikrScreen_weightierThanAllVoluntary_7af10a;

  /// No description provided for @dhikrScreen_reciteMorningEveningEarn_77aa68.
  ///
  /// In en, this message translates to:
  /// **'Recite morning & evening, earn the pleasure & blessing of Allah on the Day of Judgment'**
  String get dhikrScreen_reciteMorningEveningEarn_77aa68;

  /// No description provided for @dhikrScreen_yourRewardAwaitsDirectly_1827f4.
  ///
  /// In en, this message translates to:
  /// **'Your reward awaits directly with Allah when you meet Him'**
  String get dhikrScreen_yourRewardAwaitsDirectly_1827f4;

  /// No description provided for @dhikrScreen_reciteMorningEveningTo_1843f8.
  ///
  /// In en, this message translates to:
  /// **'Recite morning & evening to fulfill your obligation of gratitude to Allah'**
  String get dhikrScreen_reciteMorningEveningTo_1843f8;

  /// No description provided for @dhikrScreen_theProphetTaughtThis_50fab2.
  ///
  /// In en, this message translates to:
  /// **'The Prophet taught this dua for morning and evening, do not miss it'**
  String get dhikrScreen_theProphetTaughtThis_50fab2;

  /// No description provided for @dhikrScreen_dominionAtTheStart_690ca9.
  ///
  /// In en, this message translates to:
  /// **'s dominion at the start of your morning, all kingdom belongs to Him'**
  String get dhikrScreen_dominionAtTheStart_690ca9;

  /// No description provided for @dhikrScreen_asEveningFallsThe_934b7e.
  ///
  /// In en, this message translates to:
  /// **'As evening falls, the entire kingdom belongs to Allah alone'**
  String get dhikrScreen_asEveningFallsThe_934b7e;

  /// No description provided for @dhikrScreen_endYourEveningUpon_ada386.
  ///
  /// In en, this message translates to:
  /// **'End your evening upon the pure fitrah, as the Prophet (ﷺ) taught'**
  String get dhikrScreen_endYourEveningUpon_ada386;

  /// No description provided for @dhikrScreen_satanWillNotEnter_446a1c.
  ///
  /// In en, this message translates to:
  /// **'Satan will not enter the home of one who recites this'**
  String get dhikrScreen_satanWillNotEnter_446a1c;

  /// No description provided for @dhikrScreen_readingLastVersesOf_99a432.
  ///
  /// In en, this message translates to:
  /// **'Reading last 2 verses of al-Baqarah will suffice you'**
  String get dhikrScreen_readingLastVersesOf_99a432;

  /// No description provided for @dhikrScreen_everyDuaInThis_f790b4.
  ///
  /// In en, this message translates to:
  /// **'Every dua in this verse - Allah said: I have done so'**
  String get dhikrScreen_everyDuaInThis_f790b4;

  /// No description provided for @dhikrScreen_guardedByAllahUntil_f4d276.
  ///
  /// In en, this message translates to:
  /// **'Guarded by Allah until morning comes'**
  String get dhikrScreen_guardedByAllahUntil_f4d276;

  /// No description provided for @dhikrScreen_recitingEqualsReadingThe_e0a62a.
  ///
  /// In en, this message translates to:
  /// **'Reciting 3x equals reading the entire Quran, Bukhari & Muslim'**
  String get dhikrScreen_recitingEqualsReadingThe_e0a62a;

  /// No description provided for @dhikrScreen_reciteAtDawnDusk_4173a8.
  ///
  /// In en, this message translates to:
  /// **'Recite 3x at dawn & dusk, suffice you against all harm'**
  String get dhikrScreen_reciteAtDawnDusk_4173a8;

  /// No description provided for @dhikrScreen_refugeFromTheWhisperer_bdd280.
  ///
  /// In en, this message translates to:
  /// **'Refuge from the whisperer, in the Lord of Mankind'**
  String get dhikrScreen_refugeFromTheWhisperer_bdd280;

  /// No description provided for @dhikrScreen_reciteMorningEveningYour_c464cb.
  ///
  /// In en, this message translates to:
  /// **'Recite 3x morning & evening, your gratitude to Allah is fulfilled'**
  String get dhikrScreen_reciteMorningEveningYour_c464cb;

  /// No description provided for @dhikrScreen_sufficientAgainstEveryHarm_0a3206.
  ///
  /// In en, this message translates to:
  /// **'Sufficient against every harm recited 3 times'**
  String get dhikrScreen_sufficientAgainstEveryHarm_0a3206;

  /// No description provided for @dhikrScreen_doorsOfAllahMercy_937263.
  ///
  /// In en, this message translates to:
  /// **'Doors of Allah mercy open wide for you'**
  String get dhikrScreen_doorsOfAllahMercy_937263;

  /// No description provided for @dhikrScreen_worryAndSorrowLifted_fd1f04.
  ///
  /// In en, this message translates to:
  /// **'Worry and sorrow lifted by the will of Allah'**
  String get dhikrScreen_worryAndSorrowLifted_fd1f04;

  /// No description provided for @dhikrScreen_guardedInYourDeen_bb9b33.
  ///
  /// In en, this message translates to:
  /// **'Guarded in your deen dunya and akhirah'**
  String get dhikrScreen_guardedInYourDeen_bb9b33;

  /// No description provided for @dhikrScreen_evilRepelledFromEvery_3f1588.
  ///
  /// In en, this message translates to:
  /// **'Evil repelled from every direction'**
  String get dhikrScreen_evilRepelledFromEvery_3f1588;

  /// No description provided for @dhikrScreen_heartHeldByThe_0f7007.
  ///
  /// In en, this message translates to:
  /// **'Heart held by the Ever Living Ever Sustaining'**
  String get dhikrScreen_heartHeldByThe_0f7007;

  /// No description provided for @dhikrScreen_fulfilledYourObligationOf_44ddfc.
  ///
  /// In en, this message translates to:
  /// **'Fulfilled your obligation of giving thanks'**
  String get dhikrScreen_fulfilledYourObligationOf_44ddfc;

  /// No description provided for @dhikrScreen_recitingTheLastVerses_3d260d.
  ///
  /// In en, this message translates to:
  /// **'Reciting the last 2 verses of Al-Baqarah at night suffices you'**
  String get dhikrScreen_recitingTheLastVerses_3d260d;

  /// No description provided for @dhikrScreen_gratitudeThatMultipliesYour_24c5dd.
  ///
  /// In en, this message translates to:
  /// **'Gratitude that multiplies your blessings'**
  String get dhikrScreen_gratitudeThatMultipliesYour_24c5dd;

  /// No description provided for @dhikrScreen_startPureOnThe_a0198e.
  ///
  /// In en, this message translates to:
  /// **'Start pure on the fitrah of Islam'**
  String get dhikrScreen_startPureOnThe_a0198e;

  /// No description provided for @dhikrScreen_praiseThatRipplesThrough_cef105.
  ///
  /// In en, this message translates to:
  /// **'Praise that ripples through all creation'**
  String get dhikrScreen_praiseThatRipplesThrough_cef105;

  /// No description provided for @dhikrScreen_guidedToEveryGood_e5e914.
  ///
  /// In en, this message translates to:
  /// **'Guided to every good this day'**
  String get dhikrScreen_guidedToEveryGood_e5e914;

  /// No description provided for @dhikrScreen_allahWillFreeHim_20396f.
  ///
  /// In en, this message translates to:
  /// **'Allah will free him from the Fire who reads this 4 times'**
  String get dhikrScreen_allahWillFreeHim_20396f;

  /// No description provided for @dhikrScreen_wellbeingOfBodyHearing_f9d3af.
  ///
  /// In en, this message translates to:
  /// **'Wellbeing of body hearing and sight'**
  String get dhikrScreen_wellbeingOfBodyHearing_f9d3af;

  /// No description provided for @dhikrScreen_guidedByTheHand_da5d5b.
  ///
  /// In en, this message translates to:
  /// **'Guided by the hand of Allah'**
  String get dhikrScreen_guidedByTheHand_da5d5b;

  /// No description provided for @dhikrScreen_wordsHeavierThanThe_6a9c4f.
  ///
  /// In en, this message translates to:
  /// **'Words heavier than the heavens and earth'**
  String get dhikrScreen_wordsHeavierThanThe_6a9c4f;

  /// No description provided for @dhikrScreen_beginYourDayIn_530c07.
  ///
  /// In en, this message translates to:
  /// **'Begin your day in surrender to Allah'**
  String get dhikrScreen_beginYourDayIn_530c07;

  /// No description provided for @dhikrScreen_theyAreEnoughFor_14acc6.
  ///
  /// In en, this message translates to:
  /// **'They are enough for you - recite before sleep'**
  String get dhikrScreen_theyAreEnoughFor_14acc6;

  /// No description provided for @dhikrScreen_wellBeing_85c1f4.
  ///
  /// In en, this message translates to:
  /// **'Well-being'**
  String get dhikrScreen_wellBeing_85c1f4;

  /// No description provided for @dhikrScreen_fulfilled_7d487f.
  ///
  /// In en, this message translates to:
  /// **'Fulfilled.'**
  String get dhikrScreen_fulfilled_7d487f;

  /// No description provided for @dhikrScreen_wellBeingInFaith_e70162.
  ///
  /// In en, this message translates to:
  /// **'Well-being in Faith · Family · Wealth'**
  String get dhikrScreen_wellBeingInFaith_e70162;

  /// No description provided for @dhikrScreen_concealMyFaultsCalm_0252f3.
  ///
  /// In en, this message translates to:
  /// **'Conceal my faults · Calm my fears'**
  String get dhikrScreen_concealMyFaultsCalm_0252f3;

  /// No description provided for @dhikrScreen_protectionFromEvilEye_3b6074.
  ///
  /// In en, this message translates to:
  /// **'Protection from Evil Eye'**
  String get dhikrScreen_protectionFromEvilEye_3b6074;

  /// No description provided for @dhikrScreen_doNotLeaveMe_1e2414.
  ///
  /// In en, this message translates to:
  /// **'Do not leave me to myself\\neven for the blink of an eye'**
  String get dhikrScreen_doNotLeaveMe_1e2414;

  /// No description provided for @dhikrScreen_35c165_35c165.
  ///
  /// In en, this message translates to:
  /// **'{arg1}  '**
  String dhikrScreen_35c165_35c165(String arg1);

  /// No description provided for @dhikrScreen_allahWillSufficeYou_f177b2.
  ///
  /// In en, this message translates to:
  /// **'Allah will suffice you'**
  String get dhikrScreen_allahWillSufficeYou_f177b2;

  /// No description provided for @dhikrScreen_againstWhateverConcernsYou_176991.
  ///
  /// In en, this message translates to:
  /// **'against whatever concerns you'**
  String get dhikrScreen_againstWhateverConcernsYou_176991;

  /// No description provided for @dhikrScreen_doNotBurdenUs_4401b2.
  ///
  /// In en, this message translates to:
  /// **'Do not burden us beyond what we can bear, pardon us and have mercy'**
  String get dhikrScreen_doNotBurdenUs_4401b2;

  /// No description provided for @dhikrScreen_weHaveBelievedForgive_d34c4a.
  ///
  /// In en, this message translates to:
  /// **'We have believed — forgive our sins and protect us from the Fire'**
  String get dhikrScreen_weHaveBelievedForgive_d34c4a;

  /// No description provided for @dhikrScreen_ownerOfSovereigntyIn_b0948c.
  ///
  /// In en, this message translates to:
  /// **'O Owner of Sovereignty — in Your Hand is all good, You are Most Capable'**
  String get dhikrScreen_ownerOfSovereigntyIn_b0948c;

  /// No description provided for @dhikrScreen_forgiveOurSinsAnd_692ad8.
  ///
  /// In en, this message translates to:
  /// **'Forgive our sins and excess, make us firm and grant us victory'**
  String get dhikrScreen_forgiveOurSinsAnd_692ad8;

  /// No description provided for @dhikrScreen_youCreatedNotIn_d24f50.
  ///
  /// In en, this message translates to:
  /// **'You created not in vain — protect us from the punishment of the Fire'**
  String get dhikrScreen_youCreatedNotIn_d24f50;

  /// No description provided for @dhikrScreen_weHaveWrongedOurselves_24ab82.
  ///
  /// In en, this message translates to:
  /// **'We have wronged ourselves — without Your mercy we are lost'**
  String get dhikrScreen_weHaveWrongedOurselves_24ab82;

  /// No description provided for @dhikrScreen_ourLordDoNot_ca9f87.
  ///
  /// In en, this message translates to:
  /// **'Our Lord, do not place us with the wrongdoing people'**
  String get dhikrScreen_ourLordDoNot_ca9f87;

  /// No description provided for @dhikrScreen_doNotMakeUs_d5b5d2.
  ///
  /// In en, this message translates to:
  /// **'Do not make us a trial for the oppressors'**
  String get dhikrScreen_doNotMakeUs_d5b5d2;

  /// No description provided for @dhikrScreen_makeMeSteadfastIn_cc7dfe.
  ///
  /// In en, this message translates to:
  /// **'Make me steadfast in prayer — and my descendants too'**
  String get dhikrScreen_makeMeSteadfastIn_cc7dfe;

  /// No description provided for @dhikrScreen_forgiveMeMyParents_1a319b.
  ///
  /// In en, this message translates to:
  /// **'Forgive me, my parents, and the believers on the Day of Reckoning'**
  String get dhikrScreen_forgiveMeMyParents_1a319b;

  /// No description provided for @dhikrScreen_bringMeInBy_62c19a.
  ///
  /// In en, this message translates to:
  /// **'Bring me in by an entrance of truth and out by an exit of truth'**
  String get dhikrScreen_bringMeInBy_62c19a;

  /// No description provided for @dhikrScreen_myLordIncreaseMe_2fec5a.
  ///
  /// In en, this message translates to:
  /// **'My Lord, increase me in knowledge'**
  String get dhikrScreen_myLordIncreaseMe_2fec5a;

  /// No description provided for @dhikrScreen_seekRefugeInYou_3a2efd.
  ///
  /// In en, this message translates to:
  /// **'I seek refuge in You from the whispers of devils'**
  String get dhikrScreen_seekRefugeInYou_3a2efd;

  /// No description provided for @dhikrScreen_forgiveAndHaveMercy_58f2df.
  ///
  /// In en, this message translates to:
  /// **'Forgive and have mercy — You are the Best of the Merciful'**
  String get dhikrScreen_forgiveAndHaveMercy_58f2df;

  /// No description provided for @dhikrScreen_enableMeToBe_e78eb3.
  ///
  /// In en, this message translates to:
  /// **'Enable me to be grateful for Your favour on me and my parents'**
  String get dhikrScreen_enableMeToBe_e78eb3;

  /// No description provided for @dhikrScreen_myLordHaveWronged_e6421b.
  ///
  /// In en, this message translates to:
  /// **'My Lord, I have wronged myself — so forgive me'**
  String get dhikrScreen_myLordHaveWronged_e6421b;

  /// No description provided for @dhikrScreen_myLordWillNever_d4a663.
  ///
  /// In en, this message translates to:
  /// **'My Lord, I will never be a supporter of the criminals'**
  String get dhikrScreen_myLordWillNever_d4a663;

  /// No description provided for @dhikrScreen_myLordSaveMe_ea6c67.
  ///
  /// In en, this message translates to:
  /// **'My Lord, save me from the wrongdoing people'**
  String get dhikrScreen_myLordSaveMe_ea6c67;

  /// No description provided for @dhikrScreen_myLordAmIn_0acb2a.
  ///
  /// In en, this message translates to:
  /// **'My Lord, I am in need of any good You send down to me'**
  String get dhikrScreen_myLordAmIn_0acb2a;

  /// No description provided for @dhikrScreen_myLordHelpMe_80f8c7.
  ///
  /// In en, this message translates to:
  /// **'My Lord, help me against the corrupting people'**
  String get dhikrScreen_myLordHelpMe_80f8c7;

  /// No description provided for @dhikrScreen_ourLordAvertFrom_bc7354.
  ///
  /// In en, this message translates to:
  /// **'Our Lord, avert from us the punishment of Hell'**
  String get dhikrScreen_ourLordAvertFrom_bc7354;

  /// No description provided for @dhikrScreen_ourLordYouEncompass_7e0f2a.
  ///
  /// In en, this message translates to:
  /// **'Our Lord, You encompass all things in mercy and knowledge'**
  String get dhikrScreen_ourLordYouEncompass_7e0f2a;

  /// No description provided for @dhikrScreen_enableMeToThank_d1f4df.
  ///
  /// In en, this message translates to:
  /// **'Enable me to thank You and make my offspring righteous'**
  String get dhikrScreen_enableMeToThank_d1f4df;

  /// No description provided for @dhikrScreen_myLordGrantMe_ef9ff1.
  ///
  /// In en, this message translates to:
  /// **'My Lord, grant me of the righteous'**
  String get dhikrScreen_myLordGrantMe_ef9ff1;

  /// No description provided for @dhikrScreen_forgiveUsAndOur_60d1fd.
  ///
  /// In en, this message translates to:
  /// **'Forgive us and our brothers who came before us in faith'**
  String get dhikrScreen_forgiveUsAndOur_60d1fd;

  /// No description provided for @dhikrScreen_uponYouWeRely_0c8229.
  ///
  /// In en, this message translates to:
  /// **'Upon You we rely, to You we turn, and to You is the destination'**
  String get dhikrScreen_uponYouWeRely_0c8229;

  /// No description provided for @dhikrScreen_pauseRememberAllah_1ddb4d.
  ///
  /// In en, this message translates to:
  /// **'Pause. Remember Allah.'**
  String get dhikrScreen_pauseRememberAllah_1ddb4d;

  /// No description provided for @dhikrScreen_mashaallahRewardSecured_f51254.
  ///
  /// In en, this message translates to:
  /// **'MashaAllah! Reward Secured'**
  String get dhikrScreen_mashaallahRewardSecured_f51254;

  /// No description provided for @dhikrScreen_satanCannot_1c96dd.
  ///
  /// In en, this message translates to:
  /// **'Satan cannot'**
  String get dhikrScreen_satanCannot_1c96dd;

  /// No description provided for @dhikrScreen_enterTheHome_3086d7.
  ///
  /// In en, this message translates to:
  /// **'enter the home'**
  String get dhikrScreen_enterTheHome_3086d7;

  /// No description provided for @dhikrScreen_whoeverRecites_ee68bc.
  ///
  /// In en, this message translates to:
  /// **'Whoever recites'**
  String get dhikrScreen_whoeverRecites_ee68bc;

  /// No description provided for @dhikrScreen_theLastTwoVerses_a865c4.
  ///
  /// In en, this message translates to:
  /// **'the last two verses'**
  String get dhikrScreen_theLastTwoVerses_a865c4;

  /// No description provided for @dhikrScreen_ofSurahAlBaqarah_302bf4.
  ///
  /// In en, this message translates to:
  /// **'of Surah Al-Baqarah'**
  String get dhikrScreen_ofSurahAlBaqarah_302bf4;

  /// No description provided for @dhikrScreen_atNight_f3945a.
  ///
  /// In en, this message translates to:
  /// **'at night --'**
  String get dhikrScreen_atNight_f3945a;

  /// No description provided for @dhikrScreen_theyWillBe_019495.
  ///
  /// In en, this message translates to:
  /// **'they will be'**
  String get dhikrScreen_theyWillBe_019495;

  /// No description provided for @dhikrScreen_enoughForHim_6e37aa.
  ///
  /// In en, this message translates to:
  /// **'enough for him'**
  String get dhikrScreen_enoughForHim_6e37aa;

  /// No description provided for @dhikrScreen_weHaveEnteredThe_f5ed3a.
  ///
  /// In en, this message translates to:
  /// **'We have entered the evening'**
  String get dhikrScreen_weHaveEnteredThe_f5ed3a;

  /// No description provided for @dhikrScreen_theKingdomBelongsTo_2f7681.
  ///
  /// In en, this message translates to:
  /// **'The Kingdom belongs to Allah'**
  String get dhikrScreen_theKingdomBelongsTo_2f7681;

  /// No description provided for @dhikrScreen_noneWorthyOfWorship_f1c87f.
  ///
  /// In en, this message translates to:
  /// **'None worthy of worship but Allah alone'**
  String get dhikrScreen_noneWorthyOfWorship_f1c87f;

  /// No description provided for @dhikrScreen_allPraiseHeIs_c3ece6.
  ///
  /// In en, this message translates to:
  /// **'All praise · He is All-Powerful over everything'**
  String get dhikrScreen_allPraiseHeIs_c3ece6;

  /// No description provided for @dhikrScreen_weAskForThe_21b846.
  ///
  /// In en, this message translates to:
  /// **'We ask for the good of this night'**
  String get dhikrScreen_weAskForThe_21b846;

  /// No description provided for @dhikrScreen_saySeekRefuge_84c616.
  ///
  /// In en, this message translates to:
  /// **'Say: I seek refuge'**
  String get dhikrScreen_saySeekRefuge_84c616;

  /// No description provided for @dhikrScreen_inTheLordOf_39c875.
  ///
  /// In en, this message translates to:
  /// **'in the Lord of Mankind'**
  String get dhikrScreen_inTheLordOf_39c875;

  /// No description provided for @dhikrScreen_theKingOfMankind_d99354.
  ///
  /// In en, this message translates to:
  /// **'the King of Mankind'**
  String get dhikrScreen_theKingOfMankind_d99354;

  /// No description provided for @dhikrScreen_theGodOfMankind_e5231c.
  ///
  /// In en, this message translates to:
  /// **'the God of Mankind ,'**
  String get dhikrScreen_theGodOfMankind_e5231c;

  /// No description provided for @dhikrScreen_heRetreatsWhenYou_1fea37.
  ///
  /// In en, this message translates to:
  /// **'He retreats when you remember Allah.'**
  String get dhikrScreen_heRetreatsWhenYou_1fea37;

  /// No description provided for @dhikrScreen_seekRefugeInThe_96a762.
  ///
  /// In en, this message translates to:
  /// **'Seek refuge in the Lord of Daybreak'**
  String get dhikrScreen_seekRefugeInThe_96a762;

  /// No description provided for @dhikrScreen_sufficedInAllRespects_57c52b.
  ///
  /// In en, this message translates to:
  /// **'Sufficed in all respects.'**
  String get dhikrScreen_sufficedInAllRespects_57c52b;

  /// No description provided for @dhikrScreen_allahDoesNotBurden_63f3eb.
  ///
  /// In en, this message translates to:
  /// **'Allah does not burden'**
  String get dhikrScreen_allahDoesNotBurden_63f3eb;

  /// No description provided for @dhikrScreen_soul_b7f1ee.
  ///
  /// In en, this message translates to:
  /// **'a soul'**
  String get dhikrScreen_soul_b7f1ee;

  /// No description provided for @dhikrScreen_a5cfd1_a5cfd1.
  ///
  /// In en, this message translates to:
  /// **'×{count}'**
  String dhikrScreen_a5cfd1_a5cfd1(String count);

  /// No description provided for @dhikrScreen_equalsTheWholeQuran_a2b879.
  ///
  /// In en, this message translates to:
  /// **'Equals the whole Quran × 3'**
  String get dhikrScreen_equalsTheWholeQuran_a2b879;

  /// No description provided for @impactReportScreen_whoeverDoesAnAtom_9013b0.
  ///
  /// In en, this message translates to:
  /// **'“Whoever does an atom\\'**
  String get impactReportScreen_whoeverDoesAnAtom_9013b0;

  /// No description provided for @impactReportScreen_theHomeOfThe_4602d2.
  ///
  /// In en, this message translates to:
  /// **'“The home of the Hereafter — that is the eternal life, if only they knew.” — Surah Al-Ankabut 29:64'**
  String get impactReportScreen_theHomeOfThe_4602d2;

  /// No description provided for @impactReportScreen_raceTowardsForgivenessFrom_94d614.
  ///
  /// In en, this message translates to:
  /// **'“Race towards forgiveness from your Lord and a Garden as wide as the heavens and the earth.” — Surah Al-Hadid 57:21'**
  String get impactReportScreen_raceTowardsForgivenessFrom_94d614;

  /// No description provided for @impactReportScreen_andWhatIsThe_7eec52.
  ///
  /// In en, this message translates to:
  /// **'“And what is the life of this world except amusement of delusion?” — Surah Ali Imran 3:185'**
  String get impactReportScreen_andWhatIsThe_7eec52;

  /// No description provided for @impactReportScreen_indeedWithHardshipComes_ea97fa.
  ///
  /// In en, this message translates to:
  /// **'“Indeed, with hardship comes ease.” — Surah Ash-Sharh 94:6'**
  String get impactReportScreen_indeedWithHardshipComes_ea97fa;

  /// No description provided for @impactReportScreen_singleGoodDeedIn_c126b4.
  ///
  /// In en, this message translates to:
  /// **'“A single good deed in Ramadan equals 70 in any other month.” Stack while the door is open.'**
  String get impactReportScreen_singleGoodDeedIn_c126b4;

  /// No description provided for @impactReportScreen_theProphetSaidCharity_c154f4.
  ///
  /// In en, this message translates to:
  /// **'The Prophet ✍ said: charity does not decrease wealth — it grows it. (Muslim)'**
  String get impactReportScreen_theProphetSaidCharity_c154f4;

  /// No description provided for @impactReportScreen_smilingAtYourBrother_8f55e4.
  ///
  /// In en, this message translates to:
  /// **'“Smiling at your brother is sadaqah.” You can earn even when your pockets are empty. (Tirmidhi)'**
  String get impactReportScreen_smilingAtYourBrother_8f55e4;

  /// No description provided for @impactReportScreen_theMostBelovedDeeds_f11906.
  ///
  /// In en, this message translates to:
  /// **'“The most beloved deeds to Allah are the most consistent, even if small.” (Bukhari)'**
  String get impactReportScreen_theMostBelovedDeeds_f11906;

  /// No description provided for @impactReportScreen_inJannahIsWhat_ff6d55.
  ///
  /// In en, this message translates to:
  /// **'“In Jannah is what no eye has seen, no ear has heard, and no heart has imagined.” (Bukhari)'**
  String get impactReportScreen_inJannahIsWhat_ff6d55;

  /// No description provided for @impactReportScreen_twoRakatsAtFajr_c8b238.
  ///
  /// In en, this message translates to:
  /// **'Two rakats at Fajr are better than the world and everything in it. (Muslim)'**
  String get impactReportScreen_twoRakatsAtFajr_c8b238;

  /// No description provided for @impactReportScreen_everyStepTowardSalah_62962f.
  ///
  /// In en, this message translates to:
  /// **'Every step toward salah erases a sin and raises a rank. (Muslim)'**
  String get impactReportScreen_everyStepTowardSalah_62962f;

  /// No description provided for @impactReportScreen_everySeedYouDonate_618d1f.
  ///
  /// In en, this message translates to:
  /// **'Every seed you donate plants a tree in someone else\\'**
  String get impactReportScreen_everySeedYouDonate_618d1f;

  /// No description provided for @impactReportScreen_takeWealthWithYou_784e85.
  ///
  /// In en, this message translates to:
  /// **'t take wealth with you. Only the deeds it bought.'**
  String get impactReportScreen_takeWealthWithYou_784e85;

  /// No description provided for @impactReportScreen_theAngelsRecordNothing_e03c03.
  ///
  /// In en, this message translates to:
  /// **'The angels record nothing too small. One Subhanallah may outweigh a mountain.'**
  String get impactReportScreen_theAngelsRecordNothing_e03c03;

  /// No description provided for @impactReportScreen_sadaqahIsTomorrow_794857.
  ///
  /// In en, this message translates to:
  /// **'s sadaqah is tomorrow\\'**
  String get impactReportScreen_sadaqahIsTomorrow_794857;

  /// No description provided for @impactReportScreen_heartThatGivesIs_4b6000.
  ///
  /// In en, this message translates to:
  /// **'A heart that gives is a heart Allah keeps full. Don\\'**
  String get impactReportScreen_heartThatGivesIs_4b6000;

  /// No description provided for @impactReportScreen_theReceiptWhatDid_d1c41b.
  ///
  /// In en, this message translates to:
  /// **'s the receipt. What did you send ahead?'**
  String get impactReportScreen_theReceiptWhatDid_d1c41b;

  /// No description provided for @impactReportScreen_imagineYourScaleOn_094d07.
  ///
  /// In en, this message translates to:
  /// **'Imagine your scale on Yawm al-Qiyamah. What weight are you adding today?'**
  String get impactReportScreen_imagineYourScaleOn_094d07;

  /// No description provided for @impactReportScreen_theWorldIsBorrowed_2eeb50.
  ///
  /// In en, this message translates to:
  /// **'The world is borrowed. The Akhirah is owned. Invest accordingly.'**
  String get impactReportScreen_theWorldIsBorrowed_2eeb50;

  /// No description provided for @impactReportScreen_youBuryTheBody_bb5233.
  ///
  /// In en, this message translates to:
  /// **'You bury the body — but not the deeds. Send them ahead while you can.'**
  String get impactReportScreen_youBuryTheBody_bb5233;

  /// No description provided for @impactReportScreen_righteousChildWhoPrays_7bcef4.
  ///
  /// In en, this message translates to:
  /// **'A righteous child who prays for you, a charity that flows, or knowledge that benefits — three eternal investments. (Muslim)'**
  String get impactReportScreen_righteousChildWhoPrays_7bcef4;

  /// No description provided for @impactReportScreen_youWillMeetAllah_c19524.
  ///
  /// In en, this message translates to:
  /// **'You will meet Allah with your record. Make sure today\\'**
  String get impactReportScreen_youWillMeetAllah_c19524;

  /// No description provided for @impactReportScreen_noDeedIsToo_c04d50.
  ///
  /// In en, this message translates to:
  /// **'No deed is too small for the One who counts atoms.'**
  String get impactReportScreen_noDeedIsToo_c04d50;

  /// No description provided for @impactReportScreen_lvl_987904.
  ///
  /// In en, this message translates to:
  /// **'Lvl {_level} · {arg1}'**
  String impactReportScreen_lvl_987904(String _level, String arg1);

  /// No description provided for @impactReportScreen_200447_200447.
  ///
  /// In en, this message translates to:
  /// **'+{arg1}'**
  String impactReportScreen_200447_200447(String arg1);

  /// No description provided for @impactReportScreen_634027_634027.
  ///
  /// In en, this message translates to:
  /// **'+{arg1}'**
  String impactReportScreen_634027_634027(String arg1);

  /// No description provided for @impactReportScreen_whoeverDoesGoodDeed_89c2bf.
  ///
  /// In en, this message translates to:
  /// **'Whoever does a good deed shall have ten times the like thereof.'**
  String get impactReportScreen_whoeverDoesGoodDeed_89c2bf;

  /// No description provided for @impactReportScreen_whoeverReadsLetterFrom_36d74f.
  ///
  /// In en, this message translates to:
  /// **'Whoever reads a letter from the Book of Allah, he will have one hasanah, and a hasanah is multiplied by ten.'**
  String get impactReportScreen_whoeverReadsLetterFrom_36d74f;

  /// No description provided for @impactReportScreen_twoHadithGrowThis_c8d4a2.
  ///
  /// In en, this message translates to:
  /// **'Two hadith grow this number side by side:\\n\\n'**
  String get impactReportScreen_twoHadithGrowThis_c8d4a2;

  /// No description provided for @impactReportScreen_dhikrRecitedLifetime_669e2a.
  ///
  /// In en, this message translates to:
  /// **'  Dhikr recited (lifetime): {arg1}\\n'**
  String impactReportScreen_dhikrRecitedLifetime_669e2a(String arg1);

  /// No description provided for @impactReportScreen_hasanat_64c7b6.
  ///
  /// In en, this message translates to:
  /// **'  → Hasanat: {arg1}\\n\\n'**
  String impactReportScreen_hasanat_64c7b6(String arg1);

  /// No description provided for @impactReportScreen_ayahsReadLifetime_75eef6.
  ///
  /// In en, this message translates to:
  /// **'  Ayahs read (lifetime): {arg1}\\n'**
  String impactReportScreen_ayahsReadLifetime_75eef6(String arg1);

  /// No description provided for @impactReportScreen_totalHasanaat_c43112.
  ///
  /// In en, this message translates to:
  /// **'Total hasanaat: {arg1}'**
  String impactReportScreen_totalHasanaat_c43112(String arg1);

  /// No description provided for @impactReportScreen_ayahs_6a500c.
  ///
  /// In en, this message translates to:
  /// **'{arg1} ayahs'**
  String impactReportScreen_ayahs_6a500c(String arg1);

  /// No description provided for @impactReportScreen_planted_90ec47.
  ///
  /// In en, this message translates to:
  /// **'{arg1} planted'**
  String impactReportScreen_planted_90ec47(String arg1);

  /// No description provided for @impactReportScreen_cycles_f6649b.
  ///
  /// In en, this message translates to:
  /// **'{arg1} cycles'**
  String impactReportScreen_cycles_f6649b(String arg1);

  /// No description provided for @impactReportScreen_whoeverSaysSubhanAllahiWa_4b6459.
  ///
  /// In en, this message translates to:
  /// **'Whoever says SubhanAllahi wa bihamdihi 100 times a day, his sins are forgiven even if they were like the foam of the sea.'**
  String get impactReportScreen_whoeverSaysSubhanAllahiWa_4b6459;

  /// No description provided for @impactReportScreen_subhanallahiWaBihamdihi_992976.
  ///
  /// In en, this message translates to:
  /// **'SubhanAllahi wa bihamdihi'**
  String get impactReportScreen_subhanallahiWaBihamdihi_992976;

  /// No description provided for @impactReportScreen_totalRecitations_5ed733.
  ///
  /// In en, this message translates to:
  /// **'Total recitations: {arg1}\\n'**
  String impactReportScreen_totalRecitations_5ed733(String arg1);

  /// No description provided for @impactReportScreen_dividedByForgivenessCycles_4e175d.
  ///
  /// In en, this message translates to:
  /// **'Divided by 100 → forgiveness cycles: {arg1}'**
  String impactReportScreen_dividedByForgivenessCycles_4e175d(String arg1);

  /// No description provided for @impactReportScreen_built_d62c2d.
  ///
  /// In en, this message translates to:
  /// **'{arg1} built'**
  String impactReportScreen_built_d62c2d(String arg1);

  /// No description provided for @impactReportScreen_dividedByPalaces_6f066c.
  ///
  /// In en, this message translates to:
  /// **'Divided by 10 → palaces: {arg1}'**
  String impactReportScreen_dividedByPalaces_6f066c(String arg1);

  /// No description provided for @impactReportScreen_earned_abd189.
  ///
  /// In en, this message translates to:
  /// **'{arg1} earned'**
  String impactReportScreen_earned_abd189(String arg1);

  /// No description provided for @impactReportScreen_equivalent_cb7bb5.
  ///
  /// In en, this message translates to:
  /// **'{arg1} equivalent'**
  String impactReportScreen_equivalent_cb7bb5(String arg1);

  /// No description provided for @impactReportScreen_laIlahaIllallahuWahdahu_895dde.
  ///
  /// In en, this message translates to:
  /// **'La ilaha illallahu wahdahu la sharika lahu...'**
  String get impactReportScreen_laIlahaIllallahuWahdahu_895dde;

  /// No description provided for @impactReportScreen_setsOfSetsSlaves_b43b31.
  ///
  /// In en, this message translates to:
  /// **'Sets of 10 → {arg1} sets × 4 slaves = {arg2}'**
  String impactReportScreen_setsOfSetsSlaves_b43b31(String arg1, String arg2);

  /// No description provided for @impactReportScreen_opened_1bf8da.
  ///
  /// In en, this message translates to:
  /// **'{arg1} opened'**
  String impactReportScreen_opened_1bf8da(String arg1);

  /// No description provided for @impactReportScreen_received_a526e3.
  ///
  /// In en, this message translates to:
  /// **'{arg1} received'**
  String impactReportScreen_received_a526e3(String arg1);

  /// No description provided for @impactReportScreen_totalSalawatSent_cfe45e.
  ///
  /// In en, this message translates to:
  /// **'Total salawat sent: {arg1}\\n'**
  String impactReportScreen_totalSalawatSent_cfe45e(String arg1);

  /// No description provided for @impactReportScreen_multipliedByBlessingsReceived_52810f.
  ///
  /// In en, this message translates to:
  /// **'Multiplied by 10 → {arg1} blessings received'**
  String impactReportScreen_multipliedByBlessingsReceived_52810f(String arg1);

  /// No description provided for @impactReportScreen_invocations_d80c33.
  ///
  /// In en, this message translates to:
  /// **'{arg1} invocations'**
  String impactReportScreen_invocations_d80c33(String arg1);

  /// No description provided for @impactReportScreen_protectionFromEvil_37b53a.
  ///
  /// In en, this message translates to:
  /// **'Protection from evil'**
  String get impactReportScreen_protectionFromEvil_37b53a;

  /// No description provided for @impactReportScreen_goodHealthProtection_058808.
  ///
  /// In en, this message translates to:
  /// **'Good health & protection'**
  String get impactReportScreen_goodHealthProtection_058808;

  /// No description provided for @impactReportScreen_totalInvocations_1fd02b.
  ///
  /// In en, this message translates to:
  /// **'Total invocations: {arg1}'**
  String impactReportScreen_totalInvocations_1fd02b(String arg1);

  /// No description provided for @impactReportScreen_dividedByQuranCompletions_b9a013.
  ///
  /// In en, this message translates to:
  /// **'Divided by 3 → {arg1} Quran completions'**
  String impactReportScreen_dividedByQuranCompletions_b9a013(String arg1);

  /// No description provided for @impactReportScreen_recitations_3cb9ec.
  ///
  /// In en, this message translates to:
  /// **'{arg1} recitations'**
  String impactReportScreen_recitations_3cb9ec(String arg1);

  /// No description provided for @impactReportScreen_564740_564740.
  ///
  /// In en, this message translates to:
  /// **'{_monthActiveDays}'**
  String impactReportScreen_564740_564740(String _monthActiveDays);

  /// No description provided for @impactReportScreen_3dc421_3dc421.
  ///
  /// In en, this message translates to:
  /// **'{arg1}h '**
  String impactReportScreen_3dc421_3dc421(String arg1);

  /// No description provided for @impactReportScreen_08990a_08990a.
  ///
  /// In en, this message translates to:
  /// **'{arg1}m'**
  String impactReportScreen_08990a_08990a(String arg1);

  /// No description provided for @impactReportScreen_ago_71107c.
  ///
  /// In en, this message translates to:
  /// **'{arg1}m ago'**
  String impactReportScreen_ago_71107c(String arg1);

  /// No description provided for @impactReportScreen_moAgo_325a71.
  ///
  /// In en, this message translates to:
  /// **'{arg1}mo ago'**
  String impactReportScreen_moAgo_325a71(String arg1);

  /// No description provided for @impactReportScreen_viewAllDonors_e72932.
  ///
  /// In en, this message translates to:
  /// **'View all {arg1} donors'**
  String impactReportScreen_viewAllDonors_e72932(String arg1);

  /// No description provided for @impactReportScreen_failed_190558.
  ///
  /// In en, this message translates to:
  /// **'Failed: {e}'**
  String impactReportScreen_failed_190558(String e);

  /// No description provided for @impactReportScreen_meet_82797d.
  ///
  /// In en, this message translates to:
  /// **'Meet {arg1}, {arg2}'**
  String impactReportScreen_meet_82797d(String arg1, String arg2);

  /// No description provided for @impactReportScreen_sponsor_a47417.
  ///
  /// In en, this message translates to:
  /// **'Sponsor {arg1} →'**
  String impactReportScreen_sponsor_a47417(String arg1);

  /// No description provided for @impactReportScreen_funded_add009.
  ///
  /// In en, this message translates to:
  /// **'{arg1}% funded'**
  String impactReportScreen_funded_add009(String arg1);

  /// No description provided for @impactReportScreen_yourLifetimeImpact_8bfdcd.
  ///
  /// In en, this message translates to:
  /// **'Your lifetime impact'**
  String get impactReportScreen_yourLifetimeImpact_8bfdcd;

  /// No description provided for @impactReportScreen_startYourImpactJourney_1ae8c4.
  ///
  /// In en, this message translates to:
  /// **'Start your impact journey'**
  String get impactReportScreen_startYourImpactJourney_1ae8c4;

  /// No description provided for @impactReportScreen_bd3721_bd3721.
  ///
  /// In en, this message translates to:
  /// **'{_myOrphansSponsoredCount}'**
  String impactReportScreen_bd3721_bd3721(String _myOrphansSponsoredCount);

  /// No description provided for @impactReportScreen_b3d969_b3d969.
  ///
  /// In en, this message translates to:
  /// **'{_myProjectsSupportedCount}'**
  String impactReportScreen_b3d969_b3d969(String _myProjectsSupportedCount);

  /// No description provided for @levelScreen_customProfileThemes_cec15c.
  ///
  /// In en, this message translates to:
  /// **'Custom profile themes'**
  String get levelScreen_customProfileThemes_cec15c;

  /// No description provided for @levelScreen_exclusiveVotingRights_684759.
  ///
  /// In en, this message translates to:
  /// **'Exclusive voting rights'**
  String get levelScreen_exclusiveVotingRights_684759;

  /// No description provided for @levelScreen_hallOfFameListing_eb6ad1.
  ///
  /// In en, this message translates to:
  /// **'Hall of Fame listing'**
  String get levelScreen_hallOfFameListing_eb6ad1;

  /// No description provided for @levelScreen_seeds_fff97b.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} Seeds'**
  String levelScreen_seeds_fff97b(String arg1);

  /// No description provided for @levelScreen_laIlahaIllallah_e8c26b.
  ///
  /// In en, this message translates to:
  /// **'La ilaha illallah x100'**
  String get levelScreen_laIlahaIllallah_e8c26b;

  /// No description provided for @levelScreen_unlocks_6f2513.
  ///
  /// In en, this message translates to:
  /// **'Unlocks: {arg1}'**
  String levelScreen_unlocks_6f2513(String arg1);

  /// No description provided for @levelScreen_seedsBoost_464454.
  ///
  /// In en, this message translates to:
  /// **'{arg1}× Seeds Boost'**
  String levelScreen_seedsBoost_464454(String arg1);

  /// No description provided for @levelScreen_cf765f_cf765f.
  ///
  /// In en, this message translates to:
  /// **'{arg1}:{arg2}  {arg3}/{arg4}/{arg5}'**
  String levelScreen_cf765f_cf765f(
    String arg1,
    String arg2,
    String arg3,
    String arg4,
    String arg5,
  );

  /// No description provided for @levelScreen_nextDays_212b86.
  ///
  /// In en, this message translates to:
  /// **'Next: {arg1} ({arg2} days)'**
  String levelScreen_nextDays_212b86(String arg1, String arg2);

  /// No description provided for @levelScreen_days_100e10.
  ///
  /// In en, this message translates to:
  /// **'{current} / {arg1} days'**
  String levelScreen_days_100e10(String current, String arg1);

  /// No description provided for @levelScreen_dayStreak_df2abf.
  ///
  /// In en, this message translates to:
  /// **'{arg1} day streak'**
  String levelScreen_dayStreak_df2abf(String arg1);

  /// No description provided for @phase1Screens_quranReadingNimage_5ebac0.
  ///
  /// In en, this message translates to:
  /// **'Quran reading\\nimage'**
  String get phase1Screens_quranReadingNimage_5ebac0;

  /// No description provided for @phase1Screens_orphansNimage_24d12a.
  ///
  /// In en, this message translates to:
  /// **'Orphans\\nimage'**
  String get phase1Screens_orphansNimage_24d12a;

  /// No description provided for @onboardingComponents_355c50_355c50.
  ///
  /// In en, this message translates to:
  /// **'{first} '**
  String onboardingComponents_355c50_355c50(String first);

  /// No description provided for @onboardingComponents_b236c9_b236c9.
  ///
  /// In en, this message translates to:
  /// **' {trailing}'**
  String onboardingComponents_b236c9_b236c9(String trailing);

  /// No description provided for @quranMini_inTheNameOf_46925d.
  ///
  /// In en, this message translates to:
  /// **'In the name of Allah, the Most Gracious, the Most Merciful.'**
  String get quranMini_inTheNameOf_46925d;

  /// No description provided for @quranMini_allPraiseBelongsTo_2d51df.
  ///
  /// In en, this message translates to:
  /// **'All praise belongs to Allah, Lord of all the worlds.'**
  String get quranMini_allPraiseBelongsTo_2d51df;

  /// No description provided for @orphansGridScreen_36cd3b_36cd3b.
  ///
  /// In en, this message translates to:
  /// **'{arg1} · {arg2}'**
  String orphansGridScreen_36cd3b_36cd3b(String arg1, String arg2);

  /// No description provided for @orphanDetailScreen_years_debb46.
  ///
  /// In en, this message translates to:
  /// **'{arg1} years'**
  String orphanDetailScreen_years_debb46(String arg1);

  /// No description provided for @orphanDetailScreen_ofSeeds_2a29fc.
  ///
  /// In en, this message translates to:
  /// **'{arg1} of {arg2} Seeds'**
  String orphanDetailScreen_ofSeeds_2a29fc(String arg1, String arg2);

  /// No description provided for @orphanDetailScreen_through_2cdb72.
  ///
  /// In en, this message translates to:
  /// **'Through {arg1}'**
  String orphanDetailScreen_through_2cdb72(String arg1);

  /// No description provided for @orphanDetailScreen_andTheyGiveFood_7ddcff.
  ///
  /// In en, this message translates to:
  /// **'And they give food, despite their love for it, to the needy, the orphan, and the captive.'**
  String get orphanDetailScreen_andTheyGiveFood_7ddcff;

  /// No description provided for @orphanDetailScreen_ago_71107c.
  ///
  /// In en, this message translates to:
  /// **'{arg1}m ago'**
  String orphanDetailScreen_ago_71107c(String arg1);

  /// No description provided for @orphanDetailScreen_moAgo_325a71.
  ///
  /// In en, this message translates to:
  /// **'{arg1}mo ago'**
  String orphanDetailScreen_moAgo_325a71(String arg1);

  /// No description provided for @orphanDetailScreen_seeds_30d8dc.
  ///
  /// In en, this message translates to:
  /// **'{_availablePoints} Seeds'**
  String orphanDetailScreen_seeds_30d8dc(String _availablePoints);

  /// No description provided for @orphanDetailScreen_sponsor_b34bcf.
  ///
  /// In en, this message translates to:
  /// **'Sponsor {arg1}'**
  String orphanDetailScreen_sponsor_b34bcf(String arg1);

  /// No description provided for @orphanDetailScreen_jazakallahKhayranSeedsSponsored_316bec.
  ///
  /// In en, this message translates to:
  /// **'JazakAllah Khayran! {amount} Seeds sponsored.'**
  String orphanDetailScreen_jazakallahKhayranSeedsSponsored_316bec(
    String amount,
  );

  /// No description provided for @orphanDetailScreen_chooseHowManySeeds_b69aa2.
  ///
  /// In en, this message translates to:
  /// **'Choose how many Seeds to give. Minimum {arg1}.'**
  String orphanDetailScreen_chooseHowManySeeds_b69aa2(String arg1);

  /// No description provided for @orphanDetailScreen_yourBalanceSeeds_f8045b.
  ///
  /// In en, this message translates to:
  /// **'Your balance: {arg1} Seeds'**
  String orphanDetailScreen_yourBalanceSeeds_f8045b(String arg1);

  /// No description provided for @profileSettingsScreen_nameCannotBeEmpty_c737ab.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get profileSettingsScreen_nameCannotBeEmpty_c737ab;

  /// No description provided for @profileSettingsScreen_bosniaAndHerzegovina_a428ef.
  ///
  /// In en, this message translates to:
  /// **'Bosnia and Herzegovina'**
  String get profileSettingsScreen_bosniaAndHerzegovina_a428ef;

  /// No description provided for @profileSettingsScreen_centralAfricanRepublic_0fde6c.
  ///
  /// In en, this message translates to:
  /// **'Central African Republic'**
  String get profileSettingsScreen_centralAfricanRepublic_0fde6c;

  /// No description provided for @profileSettingsScreen_unitedArabEmirates_d8e2d8.
  ///
  /// In en, this message translates to:
  /// **'United Arab Emirates'**
  String get profileSettingsScreen_unitedArabEmirates_d8e2d8;

  /// No description provided for @profileSettingsScreen_signedInWithGoogle_17e053.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google'**
  String get profileSettingsScreen_signedInWithGoogle_17e053;

  /// No description provided for @profileSettingsScreen_signedInWithQuran_2e1ffc.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Quran.com'**
  String get profileSettingsScreen_signedInWithQuran_2e1ffc;

  /// No description provided for @profileSettingsScreen_signedInWithEmail_dd881f.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Email'**
  String get profileSettingsScreen_signedInWithEmail_dd881f;

  /// No description provided for @profileSettingsScreen_seeds_53d666.
  ///
  /// In en, this message translates to:
  /// **'{arg1} Seeds'**
  String profileSettingsScreen_seeds_53d666(String arg1);

  /// No description provided for @profileSettingsScreen_guidesFAQsAndHow_b990d6.
  ///
  /// In en, this message translates to:
  /// **'Guides, FAQs and how-tos'**
  String get profileSettingsScreen_guidesFAQsAndHow_b990d6;

  /// No description provided for @profileSettingsScreen_somethingNotWorkingTell_07f659.
  ///
  /// In en, this message translates to:
  /// **'Something not working? Tell us'**
  String get profileSettingsScreen_somethingNotWorkingTell_07f659;

  /// No description provided for @projectDetailScreen_organisedBy_8b317a.
  ///
  /// In en, this message translates to:
  /// **'Organised by {sponsor}\\n\\n'**
  String projectDetailScreen_organisedBy_8b317a(String sponsor);

  /// No description provided for @projectDetailScreen_fundedSoFarEvery_dab3fd.
  ///
  /// In en, this message translates to:
  /// **'Funded so far, every Seed counts!\\n\\n'**
  String get projectDetailScreen_fundedSoFarEvery_dab3fd;

  /// No description provided for @projectDetailScreen_openSabiqRewardsApp_cdda14.
  ///
  /// In en, this message translates to:
  /// **'Open Sabiq Rewards app to donate your Seeds and earn reward.\\n'**
  String get projectDetailScreen_openSabiqRewardsApp_cdda14;

  /// No description provided for @projectDetailScreen_sabiqrewardsSadaqahIslamicCharity_663ba5.
  ///
  /// In en, this message translates to:
  /// **'#SabiqRewards #Sadaqah #IslamicCharity'**
  String get projectDetailScreen_sabiqrewardsSadaqahIslamicCharity_663ba5;

  /// No description provided for @projectDetailScreen_4c2b09_4c2b09.
  ///
  /// In en, this message translates to:
  /// **'{arg1} {arg2} {arg3}'**
  String projectDetailScreen_4c2b09_4c2b09(
    String arg1,
    String arg2,
    String arg3,
  );

  /// No description provided for @projectDetailScreen_donateToProvideUrgent_246035.
  ///
  /// In en, this message translates to:
  /// **'Donate to provide urgent, life-saving aid to Palestinians facing critical shortages of food, water, and medical supplies...'**
  String get projectDetailScreen_donateToProvideUrgent_246035;

  /// No description provided for @projectDetailScreen_seeds_47387f.
  ///
  /// In en, this message translates to:
  /// **'{arg1} Seeds'**
  String projectDetailScreen_seeds_47387f(String arg1);

  /// No description provided for @projectDetailScreen_e4e562_e4e562.
  ///
  /// In en, this message translates to:
  /// **'{arg1}%'**
  String projectDetailScreen_e4e562_e4e562(String arg1);

  /// No description provided for @projectDetailScreen_ago_71107c.
  ///
  /// In en, this message translates to:
  /// **'{arg1}m ago'**
  String projectDetailScreen_ago_71107c(String arg1);

  /// No description provided for @projectDetailScreen_moAgo_325a71.
  ///
  /// In en, this message translates to:
  /// **'{arg1}mo ago'**
  String projectDetailScreen_moAgo_325a71(String arg1);

  /// No description provided for @projectDetailScreen_viewAll_3d2c48.
  ///
  /// In en, this message translates to:
  /// **'View all {arg1} →'**
  String projectDetailScreen_viewAll_3d2c48(String arg1);

  /// No description provided for @quranHubScreen_saved_9c28a3.
  ///
  /// In en, this message translates to:
  /// **'{arg1} saved'**
  String quranHubScreen_saved_9c28a3(String arg1);

  /// No description provided for @quranHubScreen_tapTheHeartBookmark_c62da1.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart/bookmark icon while reading to save verses.'**
  String get quranHubScreen_tapTheHeartBookmark_c62da1;

  /// No description provided for @quranHubScreen_surahVerse_2c65ec.
  ///
  /// In en, this message translates to:
  /// **'Surah {s}  •  Verse {a}'**
  String quranHubScreen_surahVerse_2c65ec(String s, String a);

  /// No description provided for @quranHubScreen_verses_f97238.
  ///
  /// In en, this message translates to:
  /// **'{arg1} verses'**
  String quranHubScreen_verses_f97238(String arg1);

  /// No description provided for @quranHubScreen_of_0420fc.
  ///
  /// In en, this message translates to:
  /// **'of {arg1}'**
  String quranHubScreen_of_0420fc(String arg1);

  /// No description provided for @quranScreen_englishSahihIntl_da5e9e.
  ///
  /// In en, this message translates to:
  /// **'English, Sahih Intl.'**
  String get quranScreen_englishSahihIntl_da5e9e;

  /// No description provided for @quranScreen_saheehInternational_fd1d5c.
  ///
  /// In en, this message translates to:
  /// **'Saheeh International'**
  String get quranScreen_saheehInternational_fd1d5c;

  /// No description provided for @quranScreen_englishPickthall_a0d265.
  ///
  /// In en, this message translates to:
  /// **'English, Pickthall'**
  String get quranScreen_englishPickthall_a0d265;

  /// No description provided for @quranScreen_mohammadMarmadukePickthall_554557.
  ///
  /// In en, this message translates to:
  /// **'Mohammad Marmaduke Pickthall'**
  String get quranScreen_mohammadMarmadukePickthall_554557;

  /// No description provided for @quranScreen_englishTheMessage_24a984.
  ///
  /// In en, this message translates to:
  /// **'English, The Message'**
  String get quranScreen_englishTheMessage_24a984;

  /// No description provided for @quranScreen_englishMuhsinKhan_a5402b.
  ///
  /// In en, this message translates to:
  /// **'English, Muhsin Khan'**
  String get quranScreen_englishMuhsinKhan_a5402b;

  /// No description provided for @quranScreen_muhsinKhanHilali_471c43.
  ///
  /// In en, this message translates to:
  /// **'Muhsin Khan & Hilali'**
  String get quranScreen_muhsinKhanHilali_471c43;

  /// No description provided for @quranScreen_fatehMuhammadJalandhry_262387.
  ///
  /// In en, this message translates to:
  /// **'Fateh Muhammad Jalandhry'**
  String get quranScreen_fatehMuhammadJalandhry_262387;

  /// No description provided for @quranScreen_imamAhmadRazaKhan_225277.
  ///
  /// In en, this message translates to:
  /// **'Imam Ahmad Raza Khan'**
  String get quranScreen_imamAhmadRazaKhan_225277;

  /// No description provided for @quranScreen_maulanaSayyidAbulAla_75d35f.
  ///
  /// In en, this message translates to:
  /// **'Maulana Sayyid Abul Ala Maududi'**
  String get quranScreen_maulanaSayyidAbulAla_75d35f;

  /// No description provided for @quranScreen_franAisHamidullah_2ca2c2.
  ///
  /// In en, this message translates to:
  /// **'Français, Hamidullah'**
  String get quranScreen_franAisHamidullah_2ca2c2;

  /// No description provided for @quranScreen_rkDiyanet_431130.
  ///
  /// In en, this message translates to:
  /// **'Türkçe, Diyanet'**
  String get quranScreen_rkDiyanet_431130;

  /// No description provided for @quranScreen_rkLeymanAte_7aa8e1.
  ///
  /// In en, this message translates to:
  /// **'Türkçe, Süleyman Ateş'**
  String get quranScreen_rkLeymanAte_7aa8e1;

  /// No description provided for @quranScreen_bahasaIndonesian_2a26f0.
  ///
  /// In en, this message translates to:
  /// **'Bahasa, Indonesian'**
  String get quranScreen_bahasaIndonesian_2a26f0;

  /// No description provided for @quranScreen_ministryOfReligiousAffairs_e30db8.
  ///
  /// In en, this message translates to:
  /// **'Ministry of Religious Affairs'**
  String get quranScreen_ministryOfReligiousAffairs_e30db8;

  /// No description provided for @quranScreen_muhiuddinKhan_df9bfe.
  ///
  /// In en, this message translates to:
  /// **'বাংলা, Muhiuddin Khan'**
  String get quranScreen_muhiuddinKhan_df9bfe;

  /// No description provided for @quranScreen_deutschAbuRida_9acffd.
  ///
  /// In en, this message translates to:
  /// **'Deutsch, Abu Rida'**
  String get quranScreen_deutschAbuRida_9acffd;

  /// No description provided for @quranScreen_abuRidaMuhammadIbn_3a40b3.
  ///
  /// In en, this message translates to:
  /// **'Abu Rida Muhammad ibn Ahmad'**
  String get quranScreen_abuRidaMuhammadIbn_3a40b3;

  /// No description provided for @quranScreen_espaOlAsad_1c1933.
  ///
  /// In en, this message translates to:
  /// **'Español, Asad'**
  String get quranScreen_espaOlAsad_1c1933;

  /// No description provided for @quranScreen_uthmaniMadinah_e1f10e.
  ///
  /// In en, this message translates to:
  /// **'Uthmani (Madinah)'**
  String get quranScreen_uthmaniMadinah_e1f10e;

  /// No description provided for @quranScreen_alJalalaynEN_af0584.
  ///
  /// In en, this message translates to:
  /// **'Al-Jalalayn (EN)'**
  String get quranScreen_alJalalaynEN_af0584;

  /// No description provided for @quranScreen_couldNotLoadAyah_62f120.
  ///
  /// In en, this message translates to:
  /// **'Could not load ayah. Please retry.'**
  String get quranScreen_couldNotLoadAyah_62f120;

  /// No description provided for @quranScreen_noConnectionCachedData_e5a215.
  ///
  /// In en, this message translates to:
  /// **'No connection. Cached data may be available.'**
  String get quranScreen_noConnectionCachedData_e5a215;

  /// No description provided for @quranScreen_ayahs_c98642.
  ///
  /// In en, this message translates to:
  /// **'{arg1} ayahs'**
  String quranScreen_ayahs_c98642(String arg1);

  /// No description provided for @quranScreen_couldNotRemoveBookmark_699a82.
  ///
  /// In en, this message translates to:
  /// **'Could not remove bookmark, please retry'**
  String get quranScreen_couldNotRemoveBookmark_699a82;

  /// No description provided for @quranScreen_removedBookmark_d7a16a.
  ///
  /// In en, this message translates to:
  /// **'Removed bookmark {_surahName} {_surah}:{_ayah}'**
  String quranScreen_removedBookmark_d7a16a(
    String _surahName,
    String _surah,
    String _ayah,
  );

  /// No description provided for @quranScreen_couldNotSaveBookmark_976448.
  ///
  /// In en, this message translates to:
  /// **'Could not save bookmark, please retry'**
  String get quranScreen_couldNotSaveBookmark_976448;

  /// No description provided for @quranScreen_bookmarked_2c6203.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked {_surahName} {_surah}:{_ayah}'**
  String quranScreen_bookmarked_2c6203(
    String _surahName,
    String _surah,
    String _ayah,
  );

  /// No description provided for @quranScreen_trimmedContains_039f31.
  ///
  /// In en, this message translates to:
  /// **') && !trimmed.contains('**
  String get quranScreen_trimmedContains_039f31;

  /// No description provided for @quranScreen_tafsir_391c0d.
  ///
  /// In en, this message translates to:
  /// **'Tafsir · {_surahName} {_surah}:{_ayah}'**
  String quranScreen_tafsir_391c0d(
    String _surahName,
    String _surah,
    String _ayah,
  );

  /// No description provided for @quranScreen_addedToFavourites_b3cce0.
  ///
  /// In en, this message translates to:
  /// **'♥️ Added to Favourites'**
  String get quranScreen_addedToFavourites_b3cce0;

  /// No description provided for @quranScreen_comfortableNightTimeReading_da3df2.
  ///
  /// In en, this message translates to:
  /// **'Comfortable night-time reading'**
  String get quranScreen_comfortableNightTimeReading_da3df2;

  /// No description provided for @quranScreen_pt_9e58e8.
  ///
  /// In en, this message translates to:
  /// **'{arg1} pt'**
  String quranScreen_pt_9e58e8(String arg1);

  /// No description provided for @quranScreen_003843_003843.
  ///
  /// In en, this message translates to:
  /// **'{arg1}  {arg2}'**
  String quranScreen_003843_003843(String arg1, String arg2);

  /// No description provided for @quranScreen_displayMeaningBelowEach_a26f31.
  ///
  /// In en, this message translates to:
  /// **'Display meaning below each verse'**
  String get quranScreen_displayMeaningBelowEach_a26f31;

  /// No description provided for @quranScreen_showTransliteration_e04abd.
  ///
  /// In en, this message translates to:
  /// **'Show Transliteration'**
  String get quranScreen_showTransliteration_e04abd;

  /// No description provided for @quranScreen_romanisedPronunciationUnderEach_2c0136.
  ///
  /// In en, this message translates to:
  /// **'Romanised pronunciation under each word'**
  String get quranScreen_romanisedPronunciationUnderEach_2c0136;

  /// No description provided for @quranScreen_progressBarAyahCount_3cd24d.
  ///
  /// In en, this message translates to:
  /// **'Progress bar & ayah count card'**
  String get quranScreen_progressBarAyahCount_3cd24d;

  /// No description provided for @quranScreen_moveToNextVerse_ea29fd.
  ///
  /// In en, this message translates to:
  /// **'Move to next verse when audio ends'**
  String get quranScreen_moveToNextVerse_ea29fd;

  /// No description provided for @quranScreen_repeatCurrentVerse_552669.
  ///
  /// In en, this message translates to:
  /// **'Repeat Current Verse'**
  String get quranScreen_repeatCurrentVerse_552669;

  /// No description provided for @quranScreen_notificationsALERTS_fbea75.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS & ALERTS'**
  String get quranScreen_notificationsALERTS_fbea75;

  /// No description provided for @quranScreen_milestoneSoundAlerts_03cdc3.
  ///
  /// In en, this message translates to:
  /// **'Milestone Sound Alerts'**
  String get quranScreen_milestoneSoundAlerts_03cdc3;

  /// No description provided for @quranScreen_chimeWhenYouReach_dd60c0.
  ///
  /// In en, this message translates to:
  /// **'Chime when you reach 10, 25, 50 ayahs'**
  String get quranScreen_chimeWhenYouReach_dd60c0;

  /// No description provided for @quranScreen_showEachArabicWord_64532d.
  ///
  /// In en, this message translates to:
  /// **'Show each Arabic word with its English meaning'**
  String get quranScreen_showEachArabicWord_64532d;

  /// No description provided for @quranScreen_translationLanguage_d8c9b3.
  ///
  /// In en, this message translates to:
  /// **'Translation Language'**
  String get quranScreen_translationLanguage_d8c9b3;

  /// No description provided for @quranScreen_translationsAvailable_55c648.
  ///
  /// In en, this message translates to:
  /// **'{arg1} translations available'**
  String quranScreen_translationsAvailable_55c648(String arg1);

  /// No description provided for @quranScreen_3502e8_3502e8.
  ///
  /// In en, this message translates to:
  /// **'{arg1} / {arg2}'**
  String quranScreen_3502e8_3502e8(String arg1, String arg2);

  /// No description provided for @quranScreen_sabiqSeedsEarnedToday_13ddb3.
  ///
  /// In en, this message translates to:
  /// **'+{_pointsToday} Sabiq Seeds earned today!'**
  String quranScreen_sabiqSeedsEarnedToday_13ddb3(String _pointsToday);

  /// No description provided for @quranScreen_dcacc4_dcacc4.
  ///
  /// In en, this message translates to:
  /// **'{_ayah} / {arg1}'**
  String quranScreen_dcacc4_dcacc4(String _ayah, String arg1);

  /// No description provided for @quranScreen_6d1f9d_6d1f9d.
  ///
  /// In en, this message translates to:
  /// **'{arg1} '**
  String quranScreen_6d1f9d_6d1f9d(String arg1);

  /// No description provided for @quranScreen_ayahsRead_862866.
  ///
  /// In en, this message translates to:
  /// **'{_ayahsToday} ayahs read'**
  String quranScreen_ayahsRead_862866(String _ayahsToday);

  /// No description provided for @quranScreen_ce2af3_ce2af3.
  ///
  /// In en, this message translates to:
  /// **'{arg1}%'**
  String quranScreen_ce2af3_ce2af3(String arg1);

  /// No description provided for @quranScreen_6e8ac8_6e8ac8.
  ///
  /// In en, this message translates to:
  /// **'{text} '**
  String quranScreen_6e8ac8_6e8ac8(String text);

  /// No description provided for @quranScreen_pageJuz_6ac28a.
  ///
  /// In en, this message translates to:
  /// **'Page {_currentPage}  ·  Juz {arg1}'**
  String quranScreen_pageJuz_6ac28a(String _currentPage, String arg1);

  /// No description provided for @startJourneyScreen_unexpectedErrorDuringGoogle_86c1a5.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error during Google Sign In'**
  String get startJourneyScreen_unexpectedErrorDuringGoogle_86c1a5;

  /// No description provided for @startJourneyScreen_connectedToQuranCom_c0c631.
  ///
  /// In en, this message translates to:
  /// **'Connected to Quran.com'**
  String get startJourneyScreen_connectedToQuranCom_c0c631;

  /// No description provided for @streakScreen_nextDays_212b86.
  ///
  /// In en, this message translates to:
  /// **'Next: {arg1} ({arg2} days)'**
  String streakScreen_nextDays_212b86(String arg1, String arg2);

  /// No description provided for @streakScreen_seeds_990893.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} Seeds'**
  String streakScreen_seeds_990893(String arg1);

  /// No description provided for @streakScreen_days_100e10.
  ///
  /// In en, this message translates to:
  /// **'{current} / {arg1} days'**
  String streakScreen_days_100e10(String current, String arg1);

  /// No description provided for @streakScreen_dayStreak_df2abf.
  ///
  /// In en, this message translates to:
  /// **'{arg1} day streak'**
  String streakScreen_dayStreak_df2abf(String arg1);

  /// No description provided for @tafsirHubScreen_earnSeedsForEvery_ffb3d5.
  ///
  /// In en, this message translates to:
  /// **'Earn Seeds for every 10 min of Tafsir listening'**
  String get tafsirHubScreen_earnSeedsForEvery_ffb3d5;

  /// No description provided for @tafsirScreen_alJalalaynEN_af0584.
  ///
  /// In en, this message translates to:
  /// **'Al-Jalalayn (EN)'**
  String get tafsirScreen_alJalalaynEN_af0584;

  /// No description provided for @tafsirScreen_verses_fed624.
  ///
  /// In en, this message translates to:
  /// **'{arg1} verses'**
  String tafsirScreen_verses_fed624(String arg1);

  /// No description provided for @tafsirScreen_trimmedContains_039f31.
  ///
  /// In en, this message translates to:
  /// **') && !trimmed.contains('**
  String get tafsirScreen_trimmedContains_039f31;

  /// No description provided for @tafsirScreen_ayahOf_63c42b.
  ///
  /// In en, this message translates to:
  /// **'Ayah {_ayah} of {_surahLen}'**
  String tafsirScreen_ayahOf_63c42b(String _ayah, String _surahLen);

  /// No description provided for @tafsirScreen_4815bb_4815bb.
  ///
  /// In en, this message translates to:
  /// **'{_surahName} {_ayah}/{_surahLen}'**
  String tafsirScreen_4815bb_4815bb(
    String _surahName,
    String _ayah,
    String _surahLen,
  );

  /// No description provided for @tafsirScreen_tafsirNotAvailableFor_0fce81.
  ///
  /// In en, this message translates to:
  /// **'Tafsir not available for this ayah.'**
  String get tafsirScreen_tafsirNotAvailableFor_0fce81;

  /// No description provided for @donationService_youMustBeLogged_6813cf.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to donate.'**
  String get donationService_youMustBeLogged_6813cf;

  /// No description provided for @donationService_donationCouldNotBe_074195.
  ///
  /// In en, this message translates to:
  /// **'Donation could not be processed at this time.'**
  String get donationService_donationCouldNotBe_074195;

  /// No description provided for @donationService_anUnexpectedNetworkError_914b7a.
  ///
  /// In en, this message translates to:
  /// **'An unexpected network error occurred.'**
  String get donationService_anUnexpectedNetworkError_914b7a;

  /// No description provided for @donationService_sponsorshipReceived_671201.
  ///
  /// In en, this message translates to:
  /// **'Sponsorship received 💝'**
  String get donationService_sponsorshipReceived_671201;

  /// No description provided for @donationService_youSponsoredSeedsJazak_7711e1.
  ///
  /// In en, this message translates to:
  /// **'You sponsored {amount} Seeds · jazak Allah khair.'**
  String donationService_youSponsoredSeedsJazak_7711e1(String amount);

  /// No description provided for @donationService_sponsorshipCouldNotBe_55003e.
  ///
  /// In en, this message translates to:
  /// **'Sponsorship could not be processed at this time.'**
  String get donationService_sponsorshipCouldNotBe_55003e;

  /// No description provided for @liveNotificationService_remindersToSealYour_782a67.
  ///
  /// In en, this message translates to:
  /// **'Reminders to seal your pending Seeds before midnight.'**
  String get liveNotificationService_remindersToSealYour_782a67;

  /// No description provided for @liveNotificationService_sealYourSeedsBefore_62a726.
  ///
  /// In en, this message translates to:
  /// **'Seal your Seeds before midnight'**
  String get liveNotificationService_sealYourSeedsBefore_62a726;

  /// No description provided for @liveNotificationService_youHavePendingSeeds_dd762f.
  ///
  /// In en, this message translates to:
  /// **'You have {pendingSeeds} pending Seeds. Tap Seal the Day before midnight or they expire.'**
  String liveNotificationService_youHavePendingSeeds_dd762f(
    String pendingSeeds,
  );

  /// No description provided for @liveNotificationService_ayatReadToday_b5a4e8.
  ///
  /// In en, this message translates to:
  /// **'{_ayahCount} Ayat Read today 📖'**
  String liveNotificationService_ayatReadToday_b5a4e8(String _ayahCount);

  /// No description provided for @liveNotificationService_readQuranToday_703122.
  ///
  /// In en, this message translates to:
  /// **'{arg1} Read Quran today ⏱️'**
  String liveNotificationService_readQuranToday_703122(String arg1);

  /// No description provided for @liveNotificationService_nothingReadFromQuran_b1c2eb.
  ///
  /// In en, this message translates to:
  /// **'Nothing Read from Quran today 📖'**
  String get liveNotificationService_nothingReadFromQuran_b1c2eb;

  /// No description provided for @liveNotificationService_dhikrCompletedToday_835583.
  ///
  /// In en, this message translates to:
  /// **'{_dhikrCount} Dhikr completed today 📿'**
  String liveNotificationService_dhikrCompletedToday_835583(String _dhikrCount);

  /// No description provided for @liveNotificationService_ayatDhikrToday_548e91.
  ///
  /// In en, this message translates to:
  /// **'{_ayahCount} ayat · {_dhikrCount} dhikr today'**
  String liveNotificationService_ayatDhikrToday_548e91(
    String _ayahCount,
    String _dhikrCount,
  );

  /// No description provided for @liveNotificationService_keepReadingAndDoing_cdc7b2.
  ///
  /// In en, this message translates to:
  /// **'Keep reading and doing Dhikr!'**
  String get liveNotificationService_keepReadingAndDoing_cdc7b2;

  /// No description provided for @liveNotificationService_yourSeedsToday_8649c6.
  ///
  /// In en, this message translates to:
  /// **'Your Seeds Today ✨'**
  String get liveNotificationService_yourSeedsToday_8649c6;

  /// No description provided for @localReminderScheduler_sabiqRewardsNotifications_96d36c.
  ///
  /// In en, this message translates to:
  /// **'Sabiq Rewards Notifications'**
  String get localReminderScheduler_sabiqRewardsNotifications_96d36c;

  /// No description provided for @localReminderScheduler_it_0c8340.
  ///
  /// In en, this message translates to:
  /// **'It\\'**
  String get localReminderScheduler_it_0c8340;

  /// No description provided for @localReminderScheduler_fridayReadSurahAl_077436.
  ///
  /// In en, this message translates to:
  /// **'s Friday — read Surah Al-Kahf'**
  String get localReminderScheduler_fridayReadSurahAl_077436;

  /// No description provided for @localReminderScheduler_whoeverRecitesSurahAl_15b9a5.
  ///
  /// In en, this message translates to:
  /// **'Whoever recites Surah Al-Kahf on Friday, light shines for them between the two Fridays.'**
  String get localReminderScheduler_whoeverRecitesSurahAl_15b9a5;

  /// No description provided for @localReminderScheduler_don_b4d354.
  ///
  /// In en, this message translates to:
  /// **'Don\\'**
  String get localReminderScheduler_don_b4d354;

  /// No description provided for @localReminderScheduler_missSurahAlKahf_634857.
  ///
  /// In en, this message translates to:
  /// **'t miss Surah Al-Kahf today'**
  String get localReminderScheduler_missSurahAlKahf_634857;

  /// No description provided for @localReminderScheduler_fewHoursToMaghrib_d99fd2.
  ///
  /// In en, this message translates to:
  /// **'A few hours to Maghrib — finish Surah Al-Kahf if you haven\\'**
  String get localReminderScheduler_fewHoursToMaghrib_d99fd2;

  /// No description provided for @quranApiService_notConnectedToQuran_9f4f89.
  ///
  /// In en, this message translates to:
  /// **'Not connected to Quran.com'**
  String get quranApiService_notConnectedToQuran_9f4f89;

  /// No description provided for @quranApiService_syncFailedBookmarkCould_3393f7.
  ///
  /// In en, this message translates to:
  /// **'Sync failed, {failed} bookmark(s) could not be pushed to Quran.com (check token / endpoint).'**
  String quranApiService_syncFailedBookmarkCould_3393f7(String failed);

  /// No description provided for @quranApiService_bookmarksAlreadyInSync_fad9e1.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks already in sync'**
  String get quranApiService_bookmarksAlreadyInSync_fad9e1;

  /// No description provided for @quranApiService_syncedBookmarksUpDown_dd2f96.
  ///
  /// In en, this message translates to:
  /// **'Synced {total} bookmarks ({uploaded} up, {downloaded} down)'**
  String quranApiService_syncedBookmarksUpDown_dd2f96(
    String total,
    String uploaded,
    String downloaded,
  );

  /// No description provided for @quranApiService_syncFailed_ae7629.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {e}'**
  String quranApiService_syncFailed_ae7629(String e);

  /// No description provided for @streakService_warmingUp_b1687b.
  ///
  /// In en, this message translates to:
  /// **'Warming Up'**
  String get streakService_warmingUp_b1687b;

  /// No description provided for @streakService_oneWeek_4f98dc.
  ///
  /// In en, this message translates to:
  /// **'One Week'**
  String get streakService_oneWeek_4f98dc;

  /// No description provided for @streakService_twoWeeks_9a2d93.
  ///
  /// In en, this message translates to:
  /// **'Two Weeks'**
  String get streakService_twoWeeks_9a2d93;

  /// No description provided for @streakService_oneMonth_35eb01.
  ///
  /// In en, this message translates to:
  /// **'One Month'**
  String get streakService_oneMonth_35eb01;

  /// No description provided for @streakService_twoMonths_84d275.
  ///
  /// In en, this message translates to:
  /// **'Two Months'**
  String get streakService_twoMonths_84d275;

  /// No description provided for @streakService_theCenturion_f1de7f.
  ///
  /// In en, this message translates to:
  /// **'The Centurion'**
  String get streakService_theCenturion_f1de7f;

  /// No description provided for @streakService_1fc043_1fc043.
  ///
  /// In en, this message translates to:
  /// **'{arg1} {arg2}'**
  String streakService_1fc043_1fc043(String arg1, String arg2);

  /// No description provided for @streakService_dayStreak_9ee8a3.
  ///
  /// In en, this message translates to:
  /// **'{arg1}-day {arg2} streak · '**
  String streakService_dayStreak_9ee8a3(String arg1, String arg2);

  /// No description provided for @streakService_bonusSeedsUnlocked_bcdda5.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} bonus Seeds unlocked'**
  String streakService_bonusSeedsUnlocked_bcdda5(String arg1);

  /// No description provided for @trackingService_c7528c_c7528c.
  ///
  /// In en, this message translates to:
  /// **'{arg1} {arg2}'**
  String trackingService_c7528c_c7528c(String arg1, String arg2);

  /// No description provided for @xpService_level_226f81.
  ///
  /// In en, this message translates to:
  /// **'{title} • Level {level}'**
  String xpService_level_226f81(String title, String level);

  /// No description provided for @xpService_newBadgeUnlocked_2c8d0e.
  ///
  /// In en, this message translates to:
  /// **'New badge unlocked 🏆'**
  String get xpService_newBadgeUnlocked_2c8d0e;

  /// No description provided for @xpService_you_79d09a.
  ///
  /// In en, this message translates to:
  /// **'You\\'**
  String get xpService_you_79d09a;

  /// No description provided for @xpService_dailyLoginBonus_d011fa.
  ///
  /// In en, this message translates to:
  /// **'Daily login bonus'**
  String get xpService_dailyLoginBonus_d011fa;

  /// No description provided for @xpService_seedsWelcomeBack_47888a.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} Seeds · welcome back!'**
  String xpService_seedsWelcomeBack_47888a(String arg1);

  /// No description provided for @xpService_daySealed_037a56.
  ///
  /// In en, this message translates to:
  /// **'Day sealed 🌙'**
  String get xpService_daySealed_037a56;

  /// No description provided for @xpService_sabiqSeedsConfirmedBonus_702902.
  ///
  /// In en, this message translates to:
  /// **'+{flushed} Sabiq Seeds confirmed! ({bonus} bonus for sealing)'**
  String xpService_sabiqSeedsConfirmedBonus_702902(
    String flushed,
    String bonus,
  );

  /// No description provided for @xpService_sabiqSeedsConfirmed_34969c.
  ///
  /// In en, this message translates to:
  /// **'+{flushed} Sabiq Seeds confirmed!'**
  String xpService_sabiqSeedsConfirmed_34969c(String flushed);

  /// No description provided for @dhikrExitCelebration_everyBreathCounts_45b3df.
  ///
  /// In en, this message translates to:
  /// **'Every breath counts.'**
  String get dhikrExitCelebration_everyBreathCounts_45b3df;

  /// No description provided for @impactAnimation_yourRewardHasBeen_e3d106.
  ///
  /// In en, this message translates to:
  /// **'Your reward has been recorded.'**
  String get impactAnimation_yourRewardHasBeen_e3d106;

  /// No description provided for @motivationalPopup_verilyWithHardshipComes_f23637.
  ///
  /// In en, this message translates to:
  /// **'Verily, with hardship comes ease.\\nEvery trial is a door to something greater.'**
  String get motivationalPopup_verilyWithHardshipComes_f23637;

  /// No description provided for @motivationalPopup_quranAlInshirah_d81f8a.
  ///
  /// In en, this message translates to:
  /// **'Quran • Al-Inshirah 94:6'**
  String get motivationalPopup_quranAlInshirah_d81f8a;

  /// No description provided for @motivationalPopup_quranAlAnkabut_8e938e.
  ///
  /// In en, this message translates to:
  /// **'Quran • Al-Ankabut 29:45'**
  String get motivationalPopup_quranAlAnkabut_8e938e;

  /// No description provided for @motivationalPopup_quranAlBaqarah_8bb10e.
  ///
  /// In en, this message translates to:
  /// **'Quran • Al-Baqarah 2:152'**
  String get motivationalPopup_quranAlBaqarah_8bb10e;

  /// No description provided for @motivationalPopup_quranAnNahl_74d608.
  ///
  /// In en, this message translates to:
  /// **'Quran • An-Nahl 16:18'**
  String get motivationalPopup_quranAnNahl_74d608;

  /// No description provided for @motivationalPopup_makeYourTimePrecious_049aae.
  ///
  /// In en, this message translates to:
  /// **'Make your time precious.\\nShare goodness with a friend today ,\\nevery good deed shared is a sadaqah.'**
  String get motivationalPopup_makeYourTimePrecious_049aae;

  /// No description provided for @motivationalPopup_guideOthersToGood_6105c4.
  ///
  /// In en, this message translates to:
  /// **'Guide others to good, and you get its reward.'**
  String get motivationalPopup_guideOthersToGood_6105c4;

  /// No description provided for @motivationalPopup_theBestOfPeople_1f6906.
  ///
  /// In en, this message translates to:
  /// **'The best of people are those most beneficial to others.'**
  String get motivationalPopup_theBestOfPeople_1f6906;

  /// No description provided for @motivationalPopup_verilyInTheRemembrance_16476d.
  ///
  /// In en, this message translates to:
  /// **'Verily, in the remembrance of Allah\\ndo hearts find rest.'**
  String get motivationalPopup_verilyInTheRemembrance_16476d;

  /// No description provided for @motivationalPopup_remindYourselfTimeIs_38ae33.
  ///
  /// In en, this message translates to:
  /// **'Remind yourself, time is the most precious sadaqah.'**
  String get motivationalPopup_remindYourselfTimeIs_38ae33;

  /// No description provided for @motivationalPopup_yourTimeIsYour_be6731.
  ///
  /// In en, this message translates to:
  /// **'Your time is your most\\nprecious asset. Invest it wisely\\nin what endures forever.'**
  String get motivationalPopup_yourTimeIsYour_be6731;

  /// No description provided for @motivationalPopup_quranAlAnfal_b10486.
  ///
  /// In en, this message translates to:
  /// **'Quran • Al-Anfal 8:28'**
  String get motivationalPopup_quranAlAnfal_b10486;

  /// No description provided for @motivationalPopup_takeAdvantageOfFive_e573fd.
  ///
  /// In en, this message translates to:
  /// **'Take advantage of five before five.'**
  String get motivationalPopup_takeAdvantageOfFive_e573fd;

  /// No description provided for @motivationalPopup_youHaveBeenRewarded_9bde33.
  ///
  /// In en, this message translates to:
  /// **'You have been rewarded for\\nyour consistency today!'**
  String get motivationalPopup_youHaveBeenRewarded_9bde33;

  /// No description provided for @motivationalPopup_seeds_3a9c69.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} Seeds'**
  String motivationalPopup_seeds_3a9c69(String arg1);

  /// No description provided for @motivationalPopup_completeNowEarnSeeds_16ea6e.
  ///
  /// In en, this message translates to:
  /// **'Complete now → earn +50 Seeds bonus'**
  String get motivationalPopup_completeNowEarnSeeds_16ea6e;

  /// No description provided for @motivationalPopup_finishYourAzkaarEarn_e264fa.
  ///
  /// In en, this message translates to:
  /// **'Finish your Azkaar → earn +30 Seeds bonus'**
  String get motivationalPopup_finishYourAzkaarEarn_e264fa;

  /// No description provided for @motivationalPopup_shareSabiqWithSomeone_c60dcc.
  ///
  /// In en, this message translates to:
  /// **'Share Sabiq with someone → earn +100 Seeds'**
  String get motivationalPopup_shareSabiqWithSomeone_c60dcc;

  /// No description provided for @motivationalPopup_keepYourSpiritualMomentum_0f172c.
  ///
  /// In en, this message translates to:
  /// **'Keep your spiritual momentum going\\nand watch your Seeds grow ✨'**
  String get motivationalPopup_keepYourSpiritualMomentum_0f172c;

  /// No description provided for @noorOffline_somethingWentWrong_76fc46.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get noorOffline_somethingWentWrong_76fc46;

  /// No description provided for @notificationsSheet_stayOnTopOf_811366.
  ///
  /// In en, this message translates to:
  /// **'Stay on top of rewards & milestones'**
  String get notificationsSheet_stayOnTopOf_811366;

  /// No description provided for @notificationsSheet_llBeNotifiedAbout_9e7a1b.
  ///
  /// In en, this message translates to:
  /// **'ll be notified about rewards, streaks & milestones.'**
  String get notificationsSheet_llBeNotifiedAbout_9e7a1b;

  /// No description provided for @notificationsSheet_inboxKeepsExistingItems_611668.
  ///
  /// In en, this message translates to:
  /// **'Inbox keeps existing items but no new ones will arrive.'**
  String get notificationsSheet_inboxKeepsExistingItems_611668;

  /// No description provided for @notificationsSheet_sabiqSeedsForSealing_001312.
  ///
  /// In en, this message translates to:
  /// **'Sabiq Seeds for sealing today'**
  String get notificationsSheet_sabiqSeedsForSealing_001312;

  /// No description provided for @projectMediaCarousel_couldNotLoadVideo_deb8dd.
  ///
  /// In en, this message translates to:
  /// **'Could not load video'**
  String get projectMediaCarousel_couldNotLoadVideo_deb8dd;

  /// No description provided for @quranExitCelebration_beautifulRecitation_9d2655.
  ///
  /// In en, this message translates to:
  /// **'Beautiful recitation.'**
  String get quranExitCelebration_beautifulRecitation_9d2655;

  /// No description provided for @quranExitCelebration_everyMomentCounts_fddb4c.
  ///
  /// In en, this message translates to:
  /// **'Every moment counts.'**
  String get quranExitCelebration_everyMomentCounts_fddb4c;

  /// No description provided for @sealCoinAnimation_e16fa4_e16fa4.
  ///
  /// In en, this message translates to:
  /// **'+{arg1} '**
  String sealCoinAnimation_e16fa4_e16fa4(String arg1);
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
