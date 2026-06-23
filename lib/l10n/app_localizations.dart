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
  /// **'{count} reading now'**
  String liveReadersNow(String count);

  /// No description provided for @communityReadingToday.
  ///
  /// In en, this message translates to:
  /// **'{count} reading today'**
  String communityReadingToday(String count);

  /// No description provided for @communityHasanatToday.
  ///
  /// In en, this message translates to:
  /// **'+{count} hasanat today'**
  String communityHasanatToday(String count);
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
