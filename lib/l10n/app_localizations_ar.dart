// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get youSuffix => '(أنت)';

  @override
  String get userFallback => 'مستخدم';

  @override
  String get youHaveDone => 'لقد انتهيت!';

  @override
  String get playAllBtn => 'العب الكل';

  @override
  String get playBtn => 'يلعب';

  @override
  String get readBtn => 'يقرأ';

  @override
  String get readOnce => 'اقرأ مرة واحدة';

  @override
  String readNTimes(int count) {
    return 'اقرأ $count مرات';
  }

  @override
  String seedsEarnedToday(int count) {
    return '+$count بذور سابق التي حصلت عليها اليوم!';
  }

  @override
  String get catDailyRemembrance => 'التذكر اليومي';

  @override
  String get catNightlyRemembrance => 'أذكار الليل';

  @override
  String get catYourSelection => 'اختيارك';

  @override
  String get catContinuousRemembrance => 'ذكرى مستمرة';

  @override
  String get bannerDailyRemembrance => 'أذكار يومية\nيجلب السلام للروح.';

  @override
  String get bannerMorningAdhkar =>
      'أذكار الصباح\nيجلب السلام للروح والنور للطريق.';

  @override
  String get bannerEveningAdhkar => 'أذكار المساء\nيجلب الهدوء والحماية ليلا.';

  @override
  String get bannerYourSelection =>
      'كلماتك الحبيبة\nمن الأذكار أن تبقى قريبة من قلبك.';

  @override
  String get bannerContinuousRemembrance => 'اذكروا الله\nكثيرًا، لعلك تنجح.';

  @override
  String get frequentlyReadByCommunity => 'اقرأ بشكل متكرر';

  @override
  String get viewFullLeaderboard => 'عرض المتصدرين الكاملة';

  @override
  String get skip => 'تخطى';

  @override
  String get continue_ => 'التالي';

  @override
  String get beginYourJourney => 'ابدأ رحلتك';

  @override
  String get enterTheGarden => 'ادخل الجنة';

  @override
  String get bySigningUp =>
      'بالتسجيل، أنت توافق على شروط الخدمة وسياسة الخصوصية';

  @override
  String get lightOfMercy => 'Sabiq Seeds الرحمة';

  @override
  String get noorRewards => 'مكافآت سابق';

  @override
  String get startYourJourney => 'ابدأ رحلتك';

  @override
  String get trackSpiritualGrowth =>
      'تتبع نموك الروحي، انضم إلى المجتمع، واحصل على مكافآت حصرية عن كل عمل صالح.';

  @override
  String get continueWithGoogle => 'المتابعة مع Google';

  @override
  String get continueWithQuran => 'المتابعة مع Quran.com';

  @override
  String get onboarding1Title => 'السلام\nعليكم';

  @override
  String get onboarding1Subtitle =>
      'مرحبًا بك في Sabiq Seeds ريواردز, حيث كل عمل صالح يقربك من رحمة الله وSabiq Seedsه.';

  @override
  String get onboarding2Title => 'مكافأتان\nعمل واحد';

  @override
  String get onboarding2Subtitle =>
      'كل كلمة تقرأها تكسبك ثوابًا, Sabiq Seedsًا في آخرتك.\nعملاتك تمول قضايا حقيقية تغير حياة حقيقية.';

  @override
  String get onboarding3Title => 'اذكر الله\nدائمًا';

  @override
  String get onboarding3Subtitle =>
      'قلب يذكر الله يجد السلام في كل نفَس. تتبع ذكرك اليومي ودع كل حبة تُحتسب.';

  @override
  String get onboarding4Title => 'تأمل\nوانمُ يوميًا';

  @override
  String get onboarding4Subtitle =>
      'القرآن هدى للناس جميعًا. افتح الآيات والأدعية اليومية والتأملات المصممة لرحلتك.';

  @override
  String get onboarding5Title => 'تصدق\nواكسب البركات';

  @override
  String get onboarding5Subtitle =>
      'الصدقة تطفئ الخطيئة كما يطفئ الماء النار. اكسب ثوابًا على كل عمل خيري ولطف.';

  @override
  String welcomeUser(String name) {
    return 'مرحبًا، $name 🌙';
  }

  @override
  String get gatesOfNoor => 'أبواب النور مفتوحة.\nرحلتك الروحية تبدأ اليوم.';

  @override
  String get earnNoorPoints => 'اكسب البذور';

  @override
  String get yourProgress => 'تقدمك';

  @override
  String get yourTotalNoorPoints => 'إجمالي بذورك';

  @override
  String get achievements => 'الإنجازات';

  @override
  String get today => 'اليوم';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get streaks => 'السلاسل';

  @override
  String get noorPoints => 'بذور';

  @override
  String get readQuran => 'اقرأ القرآن';

  @override
  String get inviteFriends => 'دعوة الأصدقاء';

  @override
  String get communityImpact => 'أثر المجتمع';

  @override
  String get completedProjects => 'المشاريع المكتملة';

  @override
  String get yourContribution => 'مساهمتك';

  @override
  String get yourReferralCode => 'رمز الإحالة';

  @override
  String get copyLink => 'نسخ الرابط';

  @override
  String get shareVia => 'مشاركة عبر';

  @override
  String get friendGets => 'يحصل الصديق';

  @override
  String get youGet => 'تحصل أنت';

  @override
  String get goal => 'الهدف';

  @override
  String get needed => 'مطلوب';

  @override
  String get instant => 'فوري';

  @override
  String get viewCampaign => 'عرض الحملة';

  @override
  String get close => 'إغلاق';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get loading => 'جار التحميل...';

  @override
  String get error => 'خطأ';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get level => 'المستوى';

  @override
  String get rank => 'الرتبة';

  @override
  String get dailyDhikr => 'الذكر اليومي';

  @override
  String get morning => 'الصباح';

  @override
  String get evening => 'المساء';

  @override
  String get completed => 'مكتمل';

  @override
  String get shareMore => 'مشاركة المزيد';

  @override
  String get noData => 'لا توجد بيانات بعد';

  @override
  String get callYou => 'ماذا ينبغي أن\\nنناديك؟';

  @override
  String get personaliseJourney => 'قم بتخصيص رحلتك الروحية باسمك';

  @override
  String get whereFrom => 'من أين\\nأنت؟';

  @override
  String get joinMuslims =>
      'انضم إلى المسلمين من جميع أنحاء العالم في هذه الرحلة';

  @override
  String get whatBringsYou => 'ما الذي\\nأتى بك إلى هنا؟';

  @override
  String get chooseGoals => 'اختر أهدافك الروحية, يمكنك اختيار أكثر من هدف';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navJourney => 'الرحلة';

  @override
  String get navAkhirah => 'الآخرة';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get communityLeaderboard => 'لوحة صدارة المجتمع';

  @override
  String get topContributors => 'أعلى المساهمين بالبذور التراكمية';

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get startStreak => 'ابدأ سلسلتك اليوم!';

  @override
  String get alreadySealed => 'تم الختم اليوم بالفعل';

  @override
  String get sealTheDay => 'اختم اليوم';

  @override
  String get alhamdulillah => 'الحمد لله!';

  @override
  String get levelSeeker => 'طالب';

  @override
  String get levelBeliever => 'مؤمن';

  @override
  String get levelDevoted => 'مخلص';

  @override
  String get levelChampion => 'بطل';

  @override
  String get levelLegend => 'أسطورة';

  @override
  String get next => 'التالي';

  @override
  String get day => 'يوم';

  @override
  String get days => 'أيام';

  @override
  String get quran => 'القرآن';

  @override
  String get zikr => 'الذكر';

  @override
  String get dailyLogin => 'الدخول اليومي';

  @override
  String get todaysProgress => 'تقدم اليوم';

  @override
  String get versesToday => 'آيات اليوم';

  @override
  String get resumeReading => 'استئناف القراءة';

  @override
  String get continueReading => 'مواصلة القراءة';

  @override
  String get chooseWhereToStart => 'اختر من أين تبدأ';

  @override
  String get startReadingFrom => 'ابدأ القراءة من';

  @override
  String get yourLibrary => 'مكتبتك';

  @override
  String get browse => 'تصفح';

  @override
  String get listen => 'استمع';

  @override
  String get tafsir => 'تفسير';

  @override
  String get wordByWord => 'كلمة بكلمة';

  @override
  String get mushaf => 'مصحف';

  @override
  String get otherCategories => 'فئات أخرى';

  @override
  String get noCategoriesAvailable => 'لا توجد فئات';

  @override
  String get nextPts => 'التالي';

  @override
  String get prev => 'السابق';

  @override
  String get reciteMore => 'اقرأ المزيد.';

  @override
  String get helpRealLives => 'ساعد أرواحاً حقيقية.';

  @override
  String get yourNoorPointsFundProjects => 'بذورك تموّل هذه المشاريع';

  @override
  String get youBothEarnPoints => 'تكسبان كلاكما 500 بذرة!';

  @override
  String get reward => 'المكافأة';

  @override
  String get haveInviteCode => 'هل لديك رمز دعوة؟';

  @override
  String get enterCode => 'أدخل الرمز…';

  @override
  String get apply => 'تطبيق';

  @override
  String get plantGoodDeeds => 'ازرع أعمالاً صالحة';

  @override
  String get youDonated => 'لقد تبرعت';

  @override
  String get seeDetailsForMore => 'شاهد التفاصيل لمزيد من المشاريع ←';

  @override
  String get pts => 'بذور';

  @override
  String get funded => 'ممول';

  @override
  String bySponsor(String sponsor) {
    return 'بواسطة $sponsor';
  }

  @override
  String get viewCampaignDonate => 'عرض الحملة والتبرع';

  @override
  String get supportThisCause => 'ادعم هذه القضية';

  @override
  String get availableBalance => 'الرصيد المتاح:';

  @override
  String get donationAmount => 'مبلغ التبرع';

  @override
  String get points => 'بذور';

  @override
  String get donateEarnReward => 'تبرع واكسب مكافأة';

  @override
  String get max => 'الأقصى';

  @override
  String get leaderboard => 'لوحة الصدارة';

  @override
  String get loadingDots => 'جار التحميل…';

  @override
  String yourRank(String rank) {
    return 'ترتيبك: #$rank';
  }

  @override
  String get outOf => 'من أصل';

  @override
  String get believers => 'مؤمنين';

  @override
  String get topTenContributors => 'أفضل 10 مساهمين';

  @override
  String get ourCauses => 'قضايانا';

  @override
  String get donatePointsToSupport => 'تبرّع ببذورك لدعم مشاريع حقيقية';

  @override
  String get noActiveProjects => 'لا توجد مشاريع نشطة حاليًا';

  @override
  String get checkBackSoon => 'تحقق لاحقًا إن شاء الله';

  @override
  String get messageCopied => 'تم نسخ الرسالة, شاركها أو الصقها في واتساب!';

  @override
  String get lvl => 'مستوى';

  @override
  String get journey => 'الرحلة';

  @override
  String get tabStreaks => 'السلاسل';

  @override
  String get tabProgress => 'التقدم';

  @override
  String get tabBadges => 'الشارات';

  @override
  String get tabChallenges => 'التحديات';

  @override
  String get allTime => 'كل الأوقات';

  @override
  String ptsToLevel(String pts, String level) {
    return '$pts بذرة للوصول للمستوى $level';
  }

  @override
  String dayStreak(String count) {
    return 'سلسلة $count يوم';
  }

  @override
  String get actions => 'إجراءات';

  @override
  String get action => 'إجراء';

  @override
  String get breakdown => 'التفصيل';

  @override
  String get activityLog => 'سجل النشاط';

  @override
  String get showLess => 'عرض أقل';

  @override
  String get seeMore => 'عرض المزيد';

  @override
  String get more => 'المزيد';

  @override
  String noActivity(String period) {
    return 'لا يوجد نشاط $period';
  }

  @override
  String get startEarningPts =>
      'ابدأ بكسب البذور، اقرأ القرآن، اذكر الله وادعُ.';

  @override
  String get howToEarnPts => 'كيفية كسب البذور';

  @override
  String get readOneAyah => 'اقرأ آية واحدة';

  @override
  String get completeOneJuz => 'أكمل جزءًا واحدًا';

  @override
  String get validateAndSupport => 'صادق وادعم';

  @override
  String get levelTiers => 'مستويات الرتب';

  @override
  String get basicFeatures => 'ميزات أساسية';

  @override
  String get customProfileThemes => 'سمات ملف شخصي مخصصة';

  @override
  String get leaderboardBadge => 'شارة لوحة الصدارة';

  @override
  String get exclusiveVotingRights => 'حقوق تصويت حصرية';

  @override
  String get hallOfFameListing => 'الإدراج في قاعة الشهرة';

  @override
  String unlocks(String feature) {
    return 'يفتح: $feature';
  }

  @override
  String get now => 'الآن';

  @override
  String get trophyVault => 'خزنة الجوائز';

  @override
  String badgesCollected(String earned, String total) {
    return '$earned / $total شارة مجمّعة';
  }

  @override
  String percentComplete(String pct) {
    return '$pct% مكتمل';
  }

  @override
  String toUnlock(String count) {
    return '$count للفتح';
  }

  @override
  String get earned => 'مكتسبة';

  @override
  String get locked => 'مقفلة';

  @override
  String get seasonalEvents => 'أحداث موسمية';

  @override
  String get weeklyChallenges => 'تحديات أسبوعية';

  @override
  String get specialEvents => 'أحداث خاصة';

  @override
  String get noActiveChallenges => 'لا توجد تحديات نشطة حاليًا';

  @override
  String get checkBackChallenges => 'تحقق لاحقًا, أحداث رمضان وذو الحجة قادمة!';

  @override
  String get ramadanChallenge => 'تحدي رمضان';

  @override
  String get ramadanChallengeDesc =>
      'مضاعفة النقاط 3× • شارات خاصة • هدف آبار المجتمع';

  @override
  String get comingSoonStayConsistent => 'قريبًا, حافظ على الاستمرارية!';

  @override
  String get done => 'تم!';

  @override
  String ptsBoost(String multiplier) {
    return '$multiplier× مضاعفة البذور';
  }

  @override
  String ends(String date) {
    return 'ينتهي $date';
  }

  @override
  String get loadingStreaks => 'جار تحميل السلاسل…';

  @override
  String get centurion => 'المئوي, ما شاء الله!';

  @override
  String get currentBestStreak => 'أفضل سلسلة حالية';

  @override
  String get last7Days => 'آخر ٧ أيام';

  @override
  String get nextMilestone => 'الإنجاز التالي';

  @override
  String get allMilestones => 'جميع الإنجازات';

  @override
  String moreDaysToGo(String count) {
    return 'تبقى $count يوم، استمر!';
  }

  @override
  String dayStreakLabel(String count) {
    return 'سلسلة $count يوم';
  }

  @override
  String best(String count) {
    return 'أفضل $count';
  }

  @override
  String get dhikarAndDua => 'ذكر ودعاء';

  @override
  String get listenTafsir => 'استمع للتفسير';

  @override
  String get challenge => 'تحدي';

  @override
  String get readListenTafsir => 'اقرأ واستمع للتفسير';

  @override
  String get deepUnderstanding => 'فهم عميق للقرآن الكريم';

  @override
  String get earnPointsTafsir =>
      'اكسب بذورًا عن كل 10 دقائق من الاستماع للتفسير';

  @override
  String get featuredSurahs => 'سور مميزة';

  @override
  String get browseAll114 => 'تصفح جميع السور الـ 114';

  @override
  String verses(String count) {
    return '$count آية';
  }

  @override
  String ayahN(String n) {
    return 'آية $n';
  }

  @override
  String get readTafsir => 'اقرأ التفسير';

  @override
  String get translation => 'الترجمة';

  @override
  String get loadingTafsir => 'جار تحميل التفسير...';

  @override
  String get tafsirNotAvailable => 'التفسير غير متاح لهذه الآية.';

  @override
  String get arabicScripture => 'النص العربي';

  @override
  String get urduScripture => 'النص الأردي';

  @override
  String get englishCommentary => 'الشرح الإنجليزي';

  @override
  String get previous => 'السابق';

  @override
  String get nextAyah => 'الآية التالية';

  @override
  String get readingSettings => 'إعدادات القراءة';

  @override
  String get tafsirSource => 'مصدر التفسير';

  @override
  String get reciter => 'القارئ';

  @override
  String get display => 'العرض';

  @override
  String get showArabicText => 'إظهار النص العربي';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get fontSize => 'حجم الخط';

  @override
  String get arabic => 'العربية';

  @override
  String get urdu => 'الأردية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get selectSurah => 'اختر السورة';

  @override
  String get audioNotLoaded => 'لم يتم تحميل الصوت بعد. يرجى الانتظار...';

  @override
  String playbackError(String message) {
    return 'خطأ في التشغيل: $message';
  }

  @override
  String get audioUnavailable => 'الصوت غير متاح, تحقق من اتصال الإنترنت.';

  @override
  String get signInToSaveFavourites => 'سجل الدخول لحفظ المفضلة';

  @override
  String get addedToFavourites => 'أُضيف إلى المفضلة';

  @override
  String get removedFromFavourites => 'أُزيل من المفضلة';

  @override
  String get appearance => 'المظهر';

  @override
  String get appearanceLabel => 'مظهر';

  @override
  String get freezeIllustration => 'تجميد التوضيح';

  @override
  String get comfortableNightReading => 'قراءة مريحة في الليل';

  @override
  String get focusMode => 'وضع التركيز (شاشة كاملة)';

  @override
  String get focusModeDesc => 'إخفاء شريط التطبيق والتنقل لقراءة بلا تشتيت';

  @override
  String get textSize => 'حجم النص';

  @override
  String get small => 'صغير';

  @override
  String get large => 'كبير';

  @override
  String get themeColour => 'لون السمة';

  @override
  String get quranScript => 'خط القرآن';

  @override
  String get quranScriptLabel => 'خط القرآن';

  @override
  String get readingLayout => 'تخطيط القراءة';

  @override
  String get showTranslation => 'إظهار الترجمة';

  @override
  String get displayMeaningBelow => 'عرض المعنى أسفل كل آية';

  @override
  String get showDailyProgress => 'إظهار التقدم اليومي';

  @override
  String get progressBarAyahCount => 'شريط التقدم وعدد الآيات';

  @override
  String get showPointsBanner => 'إظهار شريط البذور';

  @override
  String get noorPointsNotificationStrip => '+شريط إشعار البذور';

  @override
  String get showSurahHeader => 'إظهار عنوان السورة';

  @override
  String get surahNameBanner => 'شريط اسم السورة في أعلى الصفحة';

  @override
  String get audioPlayback => 'الصوت والتشغيل';

  @override
  String get autoAdvance => 'التقدم التلقائي';

  @override
  String get moveToNextVerse => 'الانتقال للآية التالية عند انتهاء الصوت';

  @override
  String get repeatCurrentVerse => 'تكرار الآية الحالية';

  @override
  String get loopAyahAudio => 'تكرار صوت هذه الآية باستمرار';

  @override
  String get notificationsAlerts => 'الإشعارات والتنبيهات';

  @override
  String get dailyReadingReminder => 'تذكير القراءة اليومية';

  @override
  String get pushReminderReadQuran => 'تذكير يومي بقراءة القرآن';

  @override
  String get milestoneSoundAlerts => 'تنبيهات صوتية للمعالم';

  @override
  String get chimeAtMilestones => 'رنين عند الوصول إلى 10 أو 25 أو 50 آية';

  @override
  String get advanced => 'متقدم';

  @override
  String get wordByWordMode => 'وضع كلمة بكلمة';

  @override
  String get showWordMeaning => 'إظهار معنى كل كلمة عربية بالإنجليزية';

  @override
  String get translationLanguage => 'لغة الترجمة';

  @override
  String translationsAvailable(String count) {
    return '$count ترجمة متاحة';
  }

  @override
  String get reciterLabel => 'القارئ:';

  @override
  String get playing => 'قيد التشغيل';

  @override
  String get favourite => 'المفضلة';

  @override
  String get bookmark => 'إشارة مرجعية';

  @override
  String ayahsRead(String count) {
    return '$count آية مقروءة';
  }

  @override
  String get goalAyahs => 'الهدف: 50 آية/يوم';

  @override
  String get nextPage => 'الصفحة التالية';

  @override
  String get exit => 'خروج';

  @override
  String get mushafSettings => 'إعدادات المصحف';

  @override
  String get readingMode => 'وضع القراءة';

  @override
  String get scroll => 'تمرير';

  @override
  String get pageFlip => 'تقليب الصفحات';

  @override
  String get translationLabel => 'الترجمة';

  @override
  String get off => 'إيقاف';

  @override
  String get splitView => 'عرض مقسم';

  @override
  String get script => 'الخط';

  @override
  String get actionsLabel => 'الإجراءات';

  @override
  String get pageBookmarked => 'تم حفظ الصفحة!';

  @override
  String get loadingQuran => 'جار تحميل القرآن…';

  @override
  String get earnPointsPerVerse => 'اكسب +10 بذور لكل آية تقرأها';

  @override
  String get chooseSurah => 'اختر السورة';

  @override
  String get chooseVerse => 'اختر الآية';

  @override
  String surahHasVerses(String surah, String count) {
    return 'سورة $surah بها $count آية';
  }

  @override
  String get favourites => 'المفضلة';

  @override
  String get bookmarks => 'الإشارات المرجعية';

  @override
  String saved(String count) {
    return '$count محفوظ';
  }

  @override
  String noSavedYet(String title) {
    return 'لا يوجد $title بعد';
  }

  @override
  String get tapToSaveVerses =>
      'اضغط على أيقونة القلب/الإشارة المرجعية أثناء القراءة لحفظ الآيات.';

  @override
  String get randomVerse => 'آية عشوائية';

  @override
  String get sunnahFriday => 'سنة الجمعة';

  @override
  String get resume => 'استئناف';

  @override
  String get loadingWordTranslations => 'جارٍ تحميل ترجمات الكلمات…';

  @override
  String get wordDataUnavailable => 'بيانات الكلمات غير متاحة. تحقق من اتصالك.';

  @override
  String get duaAzkarSettings => 'إعدادات الدعاء والأذكار';

  @override
  String get showTransliteration => 'إظهار النطق';

  @override
  String get showIllustration => 'إظهار الرسم التوضيحي';

  @override
  String get hideIllustrationArea => 'إخفاء منطقة الرسم الفني';

  @override
  String get arabicFontStyle => 'نمط الخط العربي';

  @override
  String get dailyAzkarComplete => 'اكتملت أذكار اليوم!';

  @override
  String get dailyAzkarBonusMsg =>
      'ما شاء الله! لقد تابعت أذكارك اليومية وكسبت +50 نقطة Sabiq Seeds إضافية.';

  @override
  String get awesome => 'رائع';

  @override
  String get betweenSubhSunrise => 'بين الصبح والشروق';

  @override
  String get betweenAsrMaghrib => 'بين العصر والمغرب';

  @override
  String get beforeSleeping => 'قبل النوم';

  @override
  String get uponWakingUp => 'عند الاستيقاظ';

  @override
  String get afterEachPrayer => 'بعد كل صلاة';

  @override
  String get anytimeEspeciallyAfterPrayer => 'في أي وقت, خاصة بعد الصلاة';

  @override
  String get anytimeMorningEvening => 'في أي وقت, صباحًا ومساءً';

  @override
  String get duringTheNight => 'أثناء الليل';

  @override
  String get anytime => 'في أي وقت';

  @override
  String get asPerSunnah => 'حسب السنة';

  @override
  String get whenEatingDrinking => 'عند الأكل أو الشرب';

  @override
  String get enteringLeavingHome => 'عند دخول / مغادرة المنزل';

  @override
  String get beforeAfterWudu => 'قبل أو بعد الوضوء';

  @override
  String get whenGettingDressed => 'عند ارتداء الملابس';

  @override
  String get uponBadDream => 'عند رؤية حلم سيء';

  @override
  String get forUmmahAnytime => 'للأمة, في أي وقت';

  @override
  String get all => 'الكل';

  @override
  String get general => 'عام';

  @override
  String get startNow => 'ابدأ الآن';

  @override
  String get markAsDone => 'تم الإنجاز';

  @override
  String get enterCustomCount => 'أدخل عددًا مخصصًا';

  @override
  String get resetToDefault => 'إعادة التعيين';

  @override
  String get noAzkarFound => 'لا توجد أذكار هنا.';

  @override
  String get reference => 'المرجع';

  @override
  String get benefit => 'الفائدة';

  @override
  String continueAdhkar(String category) {
    return 'أكمل أذكار $category من حيث توقفت.';
  }

  @override
  String get set => 'مجموعة';

  @override
  String get sets => 'مجموعات';

  @override
  String get duasOfUmmah => 'أدعية الأمة';

  @override
  String get beforeSleepCat => 'قبل النوم';

  @override
  String get tahajjud => 'التهجد';

  @override
  String get salah => 'الصلاة';

  @override
  String get salawat => 'الصلوات';

  @override
  String get sunnahDuas => 'أدعية السنة';

  @override
  String get quranicDuas => 'الأدعية القرآنية';

  @override
  String get istighfar => 'الاستغفار';

  @override
  String get dhikarAllTimes => 'ذكر لكل الأوقات';

  @override
  String get namesOfAllah => 'أسماء الله الحسنى';

  @override
  String get nightmares => 'الكوابيس';

  @override
  String get wakingUp => 'الاستيقاظ';

  @override
  String get clothes => 'الملابس';

  @override
  String get wudu => 'الوضوء';

  @override
  String get foodAndDrink => 'الطعام والشراب';

  @override
  String get home => 'المنزل';

  @override
  String get istikharah => 'الاستخارة';

  @override
  String get adaanAndMasjid => 'الأذان والمسجد';

  @override
  String get diffAndHappy => 'الشدة والفرح';

  @override
  String get imanProtect => 'حماية الإيمان';

  @override
  String get travel => 'السفر';

  @override
  String get shopping => 'التسوق';

  @override
  String get marriage => 'الزواج';

  @override
  String get social => 'اجتماعي';

  @override
  String get nature => 'الطبيعة';

  @override
  String get death => 'الوفاة';

  @override
  String get gatherings => 'المجالس';

  @override
  String get hajjAndUmrah => 'الحج والعمرة';

  @override
  String get dailyEssentials => 'الأساسيات اليومية';

  @override
  String get akhirahBalance => 'رصيد الآخرة';

  @override
  String get priceless => 'لا يقدر بثمن';

  @override
  String get beyondWorldCanHold => 'أكثر مما يسع الدنيا';

  @override
  String deedsToday(String count) {
    return '+$count عمل اليوم';
  }

  @override
  String deedsThisWeek(String count) {
    return '+$count هذا الأسبوع';
  }

  @override
  String bestDayStreak(String count) {
    return 'الأفضل: سلسلة $count يوم';
  }

  @override
  String get donateMoreEarn => 'تبرع أكثر واكسب';

  @override
  String get yourHoldings => 'ممتلكاتك';

  @override
  String get seeAll => 'عرض الكل ←';

  @override
  String get hasanaatEarned => 'حسنات مكتسبة';

  @override
  String get recordedInBookOfDeeds => 'مسجّل في كتاب أعمالك';

  @override
  String get treesInJannah => 'أشجار في الجنة';

  @override
  String get fromTasbih => 'من سبحان الله والتسبيح';

  @override
  String get sinsForgiven => 'ذنوب مغفورة';

  @override
  String get likeTheFoamOfSea => 'كزبد البحر';

  @override
  String get palacesBuilt => 'قصور بُنيت';

  @override
  String get surahIkhlasAndSunnahs => 'سورة الإخلاص والسنن';

  @override
  String get treasuresOfJannah => 'كنوز الجنة';

  @override
  String get slavesFreedom => 'رقاب أُعتقت';

  @override
  String get equivalentReward => 'ثواب مكافئ مكتسب';

  @override
  String get sadaqahGiven => 'صدقات مقدمة';

  @override
  String get pointsDonatedToCommunity => 'البذور المتبرع بها للمجتمع';

  @override
  String get allTimeLabel => 'كل الأوقات';

  @override
  String get worshipActivity => 'نشاط العبادة';

  @override
  String get timeSpentInRemembrance => 'وقت مقضي في الذكر';

  @override
  String get noorPointsSummary => 'ملخص البذور';

  @override
  String get totalPoints => 'إجمالي البذور';

  @override
  String get title => 'العنوان';

  @override
  String get everyDeedRecorded => 'كل عمل مسجل. واصل!';

  @override
  String yourAvailable(String pts) {
    return 'المتاح لديك: $pts بذرة';
  }

  @override
  String jazakAllahDonated(String pts) {
    return 'جزاك الله! تم التبرع بـ $pts بذرة';
  }

  @override
  String get insufficientPoints => 'بذور غير كافية';

  @override
  String donatePoints(String pts) {
    return 'تبرّع بـ $pts بذرة';
  }

  @override
  String get everyRecitationCanChange => 'كل تلاوة يمكن أن\nتغير حياة';

  @override
  String get fullyFunded => 'ممول بالكامل ✓';

  @override
  String get noPointsAvailable => 'لا توجد بذور متاحة';

  @override
  String get communityProgress => 'تقدم المجتمع';

  @override
  String myContribution(String pts) {
    return 'مساهمتي: $pts نقطة';
  }

  @override
  String get ptsRaised => 'نقاط تم جمعها';

  @override
  String ofGoal(String goal) {
    return 'من هدف $goal نقطة';
  }

  @override
  String get daysLeft => 'أيام متبقية';

  @override
  String get lastDay => 'اليوم الأخير!';

  @override
  String get deadline => 'الموعد النهائي';

  @override
  String get campaignStory => 'قصة الحملة';

  @override
  String updates(String count) {
    return 'التحديثات ($count)';
  }

  @override
  String get campaign => 'الحملة';

  @override
  String get noStoryYet => 'لم تُضف قصة بعد.';

  @override
  String get checkAdminPanel => 'تحقق من لوحة الإدارة لإضافة قصة الحملة.';

  @override
  String get noUpdatesYet => 'لا توجد تحديثات بعد.';

  @override
  String get checkBackForNews => 'تحقق لاحقًا لأخبار الحملة.';

  @override
  String get yesterday => 'أمس';

  @override
  String daysAgo(String count) {
    return 'منذ $count أيام';
  }

  @override
  String get shareCampaign => 'مشاركة الحملة';

  @override
  String get spreadTheWord => 'انشر الكلمة وساعد هذه القضية في الوصول لهدفها.';

  @override
  String get shareViaWhatsApp => 'مشاركة عبر واتساب';

  @override
  String get moreSharingOptions => 'خيارات مشاركة أخرى…';

  @override
  String get slideToAdjust => 'مرر للتعديل';

  @override
  String get balance => 'الرصيد';

  @override
  String get loadingYourReport => 'جار تحميل تقريرك…';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي ✓';

  @override
  String get couldNotSave => 'تعذر الحفظ, يرجى المحاولة مرة أخرى';

  @override
  String get photoUpdated => 'تم تحديث الصورة ✓';

  @override
  String get couldNotUploadPhoto => 'تعذر رفع الصورة, يرجى المحاولة مرة أخرى';

  @override
  String get changeProfilePhoto => 'تغيير صورة الملف الشخصي';

  @override
  String get takeAPhoto => 'التقط صورة';

  @override
  String get chooseFromLibrary => 'اختر من المكتبة';

  @override
  String get removePhoto => 'إزالة الصورة';

  @override
  String get photoRemoved => 'تم إزالة الصورة';

  @override
  String get couldNotRemovePhoto => 'تعذر إزالة الصورة';

  @override
  String get signOutQuestion => 'تسجيل الخروج؟';

  @override
  String get progressSafelyStored =>
      'تقدمك محفوظ بأمان. يمكنك تسجيل الدخول مرة أخرى في أي وقت.';

  @override
  String get accountInformation => 'معلومات الحساب';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get helpAndSupport => 'المساعدة والدعم';

  @override
  String get profilePhoto => 'صورة الملف الشخصي';

  @override
  String get tapEditToChange => 'اضغط تعديل لتغيير صورتك';

  @override
  String get tapEditToAdd => 'اضغط تعديل لإضافة صورة';

  @override
  String get edit => 'تعديل';

  @override
  String get displayName => 'الاسم المعروض';

  @override
  String get yourName => 'اسمك';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get country => 'البلد';

  @override
  String get countryHint => 'مثال: باكستان، بريطانيا…';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get notifOnDesc => 'المكافآت، معالم السلسلة، التبرعات والمزيد';

  @override
  String get notifOffDesc => 'مغلقة, لن تُضاف تنبيهات جديدة';

  @override
  String get viewNotificationsInbox => 'عرض صندوق الإشعارات';

  @override
  String nNew(String n) {
    return '$n جديد';
  }

  @override
  String get helpCenter => 'مركز المساعدة';

  @override
  String get reportABug => 'الإبلاغ عن خلل';

  @override
  String get aboutNoorRewards => 'حول Sabiq Rewards';

  @override
  String get builtWithLove => 'صُنع بحب للأمة';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get howWeProtectData => 'كيف نحمي بياناتك';

  @override
  String get bugReportBody =>
      'وجدت خللًا؟ يرجى مراسلتنا وسنصلحه في أقرب وقت ممكن.';

  @override
  String get aboutBody =>
      'صُمم بحب لأمة المسلمين حول العالم.\nاكسب البذور ببناء العادات الإسلامية.\nتبرّع بالبذور لدعم مشاريع مجتمعية حقيقية.';

  @override
  String get howToEarnQuestion => 'كيف تكسب البذور؟';

  @override
  String get howToEarnAnswer =>
      'أكمل قراءة القرآن وجلسات الذكر وسجّل دخولك يوميًا لكسب البذور.';

  @override
  String get whatIsValidateQuestion => 'ما هو تصديق العملات؟';

  @override
  String get whatIsValidateAnswer =>
      'اضغط زر التصديق في الصفحة الرئيسية مرة واحدة يوميًا لختم عملاتك.';

  @override
  String get howStreaksWorkQuestion => 'كيف تعمل السلاسل؟';

  @override
  String get howStreaksWorkAnswer =>
      'أكمل أنشطتك اليومية بشكل متتالٍ لبناء سلسلتك.';

  @override
  String get canDonatQuestion => 'هل يمكنني التبرع ببذوري؟';

  @override
  String get canDonateAnswer =>
      'نعم! اذهب إلى تبويب الآخرة للتبرع ببذورك لمشاريع المجتمع الفعّالة.';

  @override
  String get coinsSealedMashaAllah => 'تم ختم العملات!';

  @override
  String get rewardedForConsistency => 'لقد كوفئت\nعلى ثباتك اليوم!';

  @override
  String get validationPoints => 'نقاط التصديق';

  @override
  String streakBonus(String days, String type, String points) {
    return 'مكافأة السلسلة';
  }

  @override
  String get totalEarned => 'إجمالي المكتسب';

  @override
  String get openQuran => 'افتح القرآن';

  @override
  String get duaAndAzkaar => 'الدعاء والأذكار';

  @override
  String get shareWithFriends => 'شارك مع الأصدقاء';

  @override
  String get earnMoreNoor => 'اكسب المزيد من البذور';

  @override
  String get dontDisturb => 'عدم الإزعاج';

  @override
  String get maybeLater => 'ربما لاحقًا';

  @override
  String get read5QuranPages => 'اقرأ 5 صفحات من القرآن';

  @override
  String get completeNowBonus => 'أكمل الآن ← اكسب +50 بذرة مكافأة';

  @override
  String get completeADhikrSet => 'أكمل مجموعة ذكر';

  @override
  String get finishAzkaarBonus => 'أكمل أذكارك ← اكسب +30 بذرة مكافأة';

  @override
  String get inviteAFriend => 'ادعُ صديقًا';

  @override
  String get shareNoorBonus => 'شارك Sabiq مع شخص ← اكسب +100 بذرة';

  @override
  String get multiplyYour => 'ضاعِف';

  @override
  String get noorPointsBang => 'بذورك!';

  @override
  String get keepMomentum => 'حافظ على زخمك الروحي\nوشاهد بذورك تنمو';

  @override
  String get openQuranNow => 'افتح القرآن الآن';

  @override
  String get startAzkaarNow => 'ابدأ الأذكار الآن';

  @override
  String get goodDeed => 'عمل صالح';

  @override
  String get earnSawabWithRead => 'اكسب الثواب\nمع كل قراءة';

  @override
  String get realImpact => 'أثر حقيقي';

  @override
  String get coinsFundCauses => 'البذور تموّل\nالقضايا النبيلة';

  @override
  String get unexpectedGoogleError =>
      'خطأ غير متوقع أثناء تسجيل الدخول بـ Google';

  @override
  String get authSuccessQuran => 'تمت المصادقة مع Quran.com بنجاح!';

  @override
  String get authError => 'خطأ في المصادقة';

  @override
  String get ok => 'حسنًا';

  @override
  String get verified => 'مُوثق';

  @override
  String get connectedAccount => 'حساب متصل';

  @override
  String get active => 'نشط';

  @override
  String noorPlusPoints(String pts) {
    return '+$pts بذور سابق';
  }

  @override
  String get yourGarden => 'حديقتك';

  @override
  String get noorPointsBloomed => 'أزهرت بذور سابق';

  @override
  String get growingStreakTitle => 'سلسلة النمو';

  @override
  String get daySingular => 'يوم';

  @override
  String get daysPlural => 'أيام';

  @override
  String get keepGrowing => 'استمر في النمو';

  @override
  String get progressLabel => 'التقدم';

  @override
  String get weekTab => 'أسبوع';

  @override
  String get monthTab => 'شهر';

  @override
  String get todayTab => 'اليوم';

  @override
  String ofTabGoal(String goal, String tab) {
    return 'من $goal هدف $tab';
  }

  @override
  String get todaysPlots => 'مساحات اليوم';

  @override
  String setsTodayCount(String count) {
    return 'مجموعات اليوم $count';
  }

  @override
  String get earnPerFriend => 'اكسب +500 لكل صديق';

  @override
  String lastAchievement(String name) {
    return 'الأخير: $name';
  }

  @override
  String outOfBelievers(String count) {
    return 'من $count المؤمنين';
  }

  @override
  String yourRankNum(String rank) {
    return 'تصنيفك: #$rank';
  }

  @override
  String get youIndicator => '(أنت)';

  @override
  String get greetingPrefix => 'السلام عليكم،';

  @override
  String get fundProjectsText => 'نقاط Sabiq Seeds الخاصة بك تمول هذه المشاريع';

  @override
  String activeCount(String count) {
    return '$count نشط';
  }

  @override
  String get seeDetailsForMoreProjects => 'انظر التفاصيل لمزيد من المشاريع →';

  @override
  String get notificationsSubtitle => 'البقاء على رأس المكافآت والمعالم';

  @override
  String get markAllAsRead => 'وضع علامة على الكل كمقروءة';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get notificationsOn => 'الإخطارات على';

  @override
  String get notificationsOff => 'الإخطارات معطلة';

  @override
  String get allCaughtUp => 'جميع المحاصرين';

  @override
  String get whenYouEarnRewards =>
      'عندما تربح مكافآت، أو تحقق سلسلة، أو تفتح شارة،\nسوف تظهر هنا.';

  @override
  String get justNow => 'الآن';

  @override
  String mAgo(String delta) {
    return 'منذ $deltaد';
  }

  @override
  String hAgo(String delta) {
    return 'منذ $deltaس';
  }

  @override
  String dAgo(String delta) {
    return 'منذ $deltaي';
  }

  @override
  String get newBadgeUnlocked => 'تم فتح شارة جديدة';

  @override
  String get daySealed => 'يوم مختوم';

  @override
  String get dailyLoginBonus => 'مكافأة تسجيل الدخول اليومية';

  @override
  String get oneWeek => 'أسبوع واحد';

  @override
  String get twoWeeks => 'اسبوعين';

  @override
  String badgeEarnedDesc(String badge) {
    return 'لقد حصلت على الشارة \"$badge\".';
  }

  @override
  String pointsForSealing(String points) {
    return '+$points بذور سابق للختم اليوم.';
  }

  @override
  String welcomeBack(String points) {
    return '+$points بذور سابق · أهلاً بكم من جديد!';
  }

  @override
  String get onbV2Skip => 'يتخطى';

  @override
  String get onbV2Next => 'التالي';

  @override
  String get onbV2_1_TitleA => 'قراءتك للقرآن';

  @override
  String get onbV2_1_TitleB => 'يطعم الجائع.';

  @override
  String get onbV2_1_Sub => 'وجبات حقيقية. أناس حقيقيون. تأثير حقيقي.';

  @override
  String get onbV2_1_Cta => 'كيف يعمل هذا؟';

  @override
  String get onbV2_2_Title => 'وإليك كيف.';

  @override
  String get onbV2_2_Body =>
      'اقرأ القرآن أو أذكر الذكر ← اكسب بذور سابق ← قم بتمويل الأسباب الحقيقية.';

  @override
  String get onbV2_3_TitleA => 'القرآن يكافئك';

  @override
  String get onbV2_3_TitleB => 'مرتين.';

  @override
  String get onbV2_3_Sub =>
      'مرة واحدة على بركة الله. مرة واحدة مع البذور التي تطعم المحتاجين.';

  @override
  String get onbV2_3_BannerLabel => 'حصل اليوم';

  @override
  String get onbV2_4_TitleA => 'انظر عبادتك';

  @override
  String get onbV2_4_TitleB => 'تعال إلى الحياة.';

  @override
  String get onbV2_4_Sub =>
      'تلاوة أذكار الصباح والمساء، وشاهد أجرك يتكشف، الحديث بالحديث.';

  @override
  String get onbV2_5_TitleA => 'قراءتك تصل';

  @override
  String get onbV2_5_TitleB => 'هنا.';

  @override
  String get onbV2_5_Sub =>
      'كل بذرة تكسبها تصبح طعامًا حقيقيًا، وماءً حقيقيًا، وأملًا حقيقيًا.';

  @override
  String get onbV2_6_TitleA => 'ولكن أين';

  @override
  String get onbV2_6_TitleB => 'مال';

  @override
  String get onbV2_6_TitleC => 'تأتي من؟';

  @override
  String get onbV2_6_Sub =>
      'الجهات المانحة السخية تمول الأسباب. بذورك توجه أين تذهب هديتهم، وتنمو مكافأتهم مع كل قارئ.';

  @override
  String get onbV2_6_Donor => 'الجهة المانحة';

  @override
  String get onbV2_6_DonorSub => 'يمول القضية';

  @override
  String get onbV2_6_You => 'أنت';

  @override
  String get onbV2_6_YouSub => 'توجيه الهدية';

  @override
  String get onbV2_6_Charity => 'صدقة';

  @override
  String get onbV2_6_CharitySub => 'يسلم المساعدات';

  @override
  String get onbV2_6_TrustBadge =>
      'يتم صرف 100% إلى الشركاء الذين تم التحقق منهم';

  @override
  String get onbV2_7_TitleA => 'كل عمل هو';

  @override
  String get onbV2_7_TitleB => 'عد.';

  @override
  String get onbV2_7_Sub =>
      'انظر حساب الآخرة الذي تبنيه، الأشجار، القصور، النفوس المحررة، المتجذرة في الأحاديث الصحيحة.';

  @override
  String get onbV2_8_TitleA => 'لنبدأ مع الخاص بك';

  @override
  String get onbV2_8_TitleB => 'اسم.';

  @override
  String get onbV2_8_Sub => 'لذا فإن سابق يشعر وكأنه ملكك.';

  @override
  String get onbV2_8_Placeholder => 'اسمك';

  @override
  String get onbV2_8_Cta => 'يكمل';

  @override
  String get onbV2_9_TitleA => 'السبب الذي يحركك';

  @override
  String get onbV2_9_TitleB => 'معظم؟';

  @override
  String get onbV2_9_Sub =>
      'تدعم بذورك جميع القضايا، وهذا يساعدنا فقط على فهم ما يهم مجتمعنا.';

  @override
  String get onbV2_9_Cta => 'يبدأ';

  @override
  String get onbV2_9_Orphans => 'الأيتام';

  @override
  String get onbV2_9_OrphansSub => 'إطعام ورعاية الأطفال الذين فقدوا كل شيء';

  @override
  String get onbV2_9_Water => 'آبار المياه';

  @override
  String get onbV2_9_WaterSub => 'المياه النظيفة للقرى المحتاجة';

  @override
  String get onbV2_9_War => 'المناطق المتأثرة بالحرب';

  @override
  String get onbV2_9_WarSub => 'الإغاثة حيث تشتد الحاجة إليها';

  @override
  String get onbV2_9_Disaster => 'الكوارث الطبيعية';

  @override
  String get onbV2_9_DisasterSub => 'الاستجابة السريعة عند حدوث الأزمات';

  @override
  String get onbV2_3step_Title => 'ثلاث خطوات بسيطة.';

  @override
  String get onbV2_3step_Sub => 'كل آية وكل ذكر يصبح عونًا حقيقيًا.';

  @override
  String get onbV2_3step_S1Label => 'الخطوة 1';

  @override
  String get onbV2_3step_S1Text => 'قراءة القرآن';

  @override
  String get onbV2_3step_S2Label => 'الخطوة 2';

  @override
  String get onbV2_3step_S2Text => 'كسب البذور';

  @override
  String get onbV2_3step_S3Label => 'الخطوة 3';

  @override
  String get onbV2_3step_S3Text => 'إطعام الأيتام';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get systemDefault => 'لغة النظام الافتراضية';

  @override
  String get yourStreaksTitle => 'سلاسلك اليومية';

  @override
  String get streakLoading => 'جارٍ تحميل السلاسل…';

  @override
  String get startStreakToday => 'ابدأ سلسلتك اليوم!';

  @override
  String get centurionMashaAllah => 'مئوي، ما شاء الله!';

  @override
  String get qfConflictTitle => 'الحساب موجود بالفعل';

  @override
  String get qfConflictExplanation =>
      'هذا البريد الإلكتروني مسجل بالفعل في Sabiq Rewards باستخدام طريقة تسجيل دخول مختلفة (بريد إلكتروني أو Google).\n\nلحماية تقدمك الحالي وسلاسلك وSabiq Seeds، يرجى تسجيل الدخول باستخدام طريقتك الأصلية.';

  @override
  String get qfConflictStep1 => 'عد إلى شاشة تسجيل الدخول';

  @override
  String qfConflictStep2(String email) {
    return 'سجّل الدخول ببريد إلكتروني أو Google باستخدام\n$email';
  }

  @override
  String get qfConflictStep3 => 'كل تقدمك سيكون هناك';

  @override
  String get qfConflictBackButton => 'العودة إلى تسجيل الدخول';

  @override
  String get sponsorAnOrphan => 'كفّل يتيمًا';

  @override
  String get noOrphansListed => 'لا توجد أيتام مدرجون بعد';

  @override
  String get checkBackForOrphans =>
      'تحقق قريبًا، تُضاف فرص كفالة جديدة بانتظام.';

  @override
  String get orphanVerseTranslation => '«وأمّا اليتيم فلا تقهر»، القرآن ٩٣:٩';

  @override
  String get orphanCardOpen => 'مفتوح';

  @override
  String get doneLabel => 'تم';

  @override
  String get aReminderLabel => 'تذكير';

  @override
  String get yourAkhirahBalance => 'رصيد آخرتك';

  @override
  String get seedsCollectedSinceJoined => 'بذور مجموعة منذ انضمامك';

  @override
  String get todayLabel => 'اليوم';

  @override
  String plusSeedsToday(String count) {
    return '+$count اليوم';
  }

  @override
  String get azkaarPerDay => 'أذكار في اليوم';

  @override
  String get viewFullStats => 'عرض الإحصائيات الكاملة';

  @override
  String get fatherLabel => 'الأب';

  @override
  String get motherLabel => 'الأم';

  @override
  String get siblingsLabel => 'الإخوة';

  @override
  String get familySection => 'العائلة';

  @override
  String get educationSection => 'التعليم';

  @override
  String get gradeLabel => 'الصف';

  @override
  String get schoolLabel => 'المدرسة';

  @override
  String get theirStorySection => 'قصته';

  @override
  String get yourBalanceLabel => 'رصيدك:';

  @override
  String sponsorCta(String name) {
    return 'كفّل $name';
  }

  @override
  String get notEnoughSeeds => 'بذور غير كافية';

  @override
  String get bookmarkSyncDialogTitle => 'مزامنة إشارات Quran.com';

  @override
  String get closeLabel => 'إغلاق';

  @override
  String get searchHint => 'بحث…';

  @override
  String get enterCodeHint => 'أدخل الرمز…';

  @override
  String get searchSurahHint => 'ابحث عن سورة...';

  @override
  String get customLabel => 'مخصص';

  @override
  String get seedsSuffix => 'بذور';

  @override
  String get settingsTooltip => 'الإعدادات';

  @override
  String get retryLabel => 'إعادة المحاولة';

  @override
  String get authErrorTitle => 'خطأ في المصادقة';

  @override
  String sealWithinHours(int hours) {
    return 'اختم خلال $hours ساعة';
  }

  @override
  String sealWithinMinutes(int minutes) {
    return 'اختم خلال $minutes دقيقة';
  }

  @override
  String get sealNow => 'اختم الآن';

  @override
  String get goalLabel => 'الهدف';

  @override
  String contributorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مساهمون',
      one: 'مساهم واحد',
    );
    return '$_temp0';
  }

  @override
  String dayStreakCount(int streak) {
    return 'سلسلة $streak يوم 🔥';
  }

  @override
  String seedsPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بذور معلقة',
      one: 'بذرة واحدة معلقة',
    );
    return '$_temp0';
  }

  @override
  String get sealToSave => 'اختم للحفظ';

  @override
  String get top10Contributors => 'أعلى ١٠ مساهمين';

  @override
  String get copyLabel => 'نسخ';

  @override
  String get copiedLabel => 'تم النسخ!';

  @override
  String get whatsappLabel => 'واتساب';

  @override
  String get youBothEarnSeeds => 'كلاكما يكسب ٥٠٠ بذور!';

  @override
  String jazakAllahPlusSeeds(int seeds) {
    return 'جزاك الله!  +$seeds بذور';
  }

  @override
  String get jazakAllahDaySealed => 'جزاك الله!  تم ختم اليوم';

  @override
  String get pointsGoals => 'أهداف النقاط';

  @override
  String get editLabel => 'تعديل';

  @override
  String get dailyGoal => 'الهدف اليومي';

  @override
  String get weeklyGoal => 'الهدف الأسبوعي';

  @override
  String get monthlyGoal => 'الهدف الشهري';

  @override
  String setTargetSeeds(int defaultVal) {
    return 'حدد هدفك من البذور (افتراضي: $defaultVal)';
  }

  @override
  String get noInternetTitle => 'لا يوجد اتصال بالإنترنت';

  @override
  String get connectingTitle => 'جارٍ الاتصال…';

  @override
  String get somethingWentWrongTitle => 'حدث خطأ ما';

  @override
  String get noInternetSubtitle =>
      'هذه الميزة تتطلب الإنترنت.\nتحقق من Wi-Fi أو بيانات الجوال.';

  @override
  String get connectingSubtitle => 'جارٍ جلب بياناتك…\nانتظر لحظة';

  @override
  String get errorSubtitle => 'حدث خطأ غير متوقع.\nاضغط إعادة المحاولة.';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get everyRecitationCanChangeLife => 'كل تلاوة\nيمكن أن تغير حياة';

  @override
  String get givenLabel => 'تم التبرع';

  @override
  String get goalUpper => 'الهدف';

  @override
  String get aboutThisCause => 'عن هذه القضية';

  @override
  String myContributionSeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مساهمتي: $count بذور',
      one: 'مساهمتي: بذرة واحدة',
    );
    return '$_temp0';
  }

  @override
  String jazakAllahKhayranDonated(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: 'جزاك الله خيراً! تم التبرع بـ $amount بذور.',
      one: 'جزاك الله خيراً! تم التبرع ببذرة واحدة.',
    );
    return '$_temp0';
  }

  @override
  String get coinsSealedTitle => 'تم ختم النقاط! ما شاء الله';

  @override
  String get seedsSealedSafe => 'بذورك مختومة وآمنة\nللآخرة.';

  @override
  String get validationSeedsLabel => 'بذور التحقق';

  @override
  String get streakBonusLabel => 'مكافأة السلسلة';

  @override
  String get totalEarnedLabel => 'إجمالي المكتسب';

  @override
  String get alhamdulillahCta => 'الحمد لله! 🤲';

  @override
  String get openQuranCta => 'افتح القرآن';

  @override
  String get duaAzkaarCta => 'الأدعية والأذكار';

  @override
  String get shareWithFriendsCta => 'شارك مع الأصدقاء';

  @override
  String get earnMoreSeedsCta => 'اكسب المزيد من البذور';

  @override
  String levelTitleFormat(int level, String title) {
    return 'المستوى $level · $title';
  }

  @override
  String get akhirahBalanceUpper => 'رصيد الآخرة';

  @override
  String bestDayStreakBadge(int streak) {
    return 'الأفضل: سلسلة $streak يوم';
  }

  @override
  String get deedsLabel => 'أعمال';

  @override
  String get treesLabel => 'أشجار';

  @override
  String get forgivenLabel => 'مغفور';

  @override
  String get navCause => 'العطاء';

  @override
  String get realChildrenSubtitle => 'أطفال حقيقيون، قصصهم، حياتهم';

  @override
  String get seeAllAction => 'عرض الكل';

  @override
  String get activeCampaigns => 'الحملات النشطة';

  @override
  String get poolSeedsImpact => 'اجمع البذور من أجل أثر دائم';

  @override
  String get featuredSponsorChild => 'مميز · كفّل طفلاً';

  @override
  String meetOrphanAge(String name, int age) {
    return 'تعرّف على $name، $age';
  }

  @override
  String sponsorNameArrow(String name) {
    return 'كفّل $name ←';
  }

  @override
  String get featuredCampaign => 'حملة مميزة';

  @override
  String get yourGiving => 'عطاؤك';

  @override
  String get havenNotGivenYet =>
      'لم تتبرع بعد. اختر شخصاً أعلاه لتبدأ رحلة عطائك.';

  @override
  String get seedsDonatedLabel => 'بذور متبرَّع بها';

  @override
  String orphanCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أيتام',
      one: 'يتيم',
    );
    return '$_temp0';
  }

  @override
  String projectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مشاريع',
      one: 'مشروع',
    );
    return '$_temp0';
  }

  @override
  String get couldntLoadJourney => 'تعذّر تحميل رحلتك';

  @override
  String get checkConnectionRetry => 'تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String actionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إجراءات',
      one: 'إجراء واحد',
    );
    return '$_temp0';
  }

  @override
  String get showLessAction => 'عرض أقل ←';

  @override
  String get hadithReference => 'مرجع الحديث';

  @override
  String get howYouEarnedThis => 'كيف اكتسبت هذا';

  @override
  String seedsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بذور',
      one: 'بذرة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get seedsUnit => 'بذور';

  @override
  String get topContribByLifetimeSeeds => 'أعلى المساهمين حسب البذور التراكمية';

  @override
  String get romanisedPronunciation => 'النطق بالحروف اللاتينية تحت كل كلمة';

  @override
  String get displayLabel => 'العرض';

  @override
  String get arabicLanguageLabel => 'العربية';

  @override
  String get urduLanguageLabel => 'الأردية';

  @override
  String get englishLanguageLabel => 'الإنجليزية';

  @override
  String get earnPerVerseRead => 'اكسب +١٠ بذور عن كل آية تقرأها';

  @override
  String get surahPickerLabel => 'السورة';

  @override
  String versesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count آيات',
      one: 'آية واحدة',
    );
    return '$_temp0';
  }

  @override
  String get startFromVerse => 'ابدأ من الآية';

  @override
  String verseN(int n) {
    return 'الآية $n';
  }

  @override
  String ofN(int n) {
    return 'من $n';
  }

  @override
  String surahHasNVerses(String name, int count) {
    return 'سورة $name تحتوي على $count آية';
  }

  @override
  String noXYet(String label) {
    return 'لا توجد $label بعد';
  }

  @override
  String get tapHeartToSave =>
      'اضغط على أيقونة القلب أو الإشارة أثناء القراءة لحفظ الآيات.';

  @override
  String surahVerseRow(int surah, int ayah) {
    return 'سورة $surah  •  الآية $ayah';
  }

  @override
  String get hasanatFromQuran => 'حسنات من القرآن';

  @override
  String tenPerLetterSubtitle(int count) {
    return '١٠ لكل حرف، $count لكل آية';
  }

  @override
  String get fromSubhanAllahTasbih => 'من سبحان الله والتسبيح';

  @override
  String get likeFoamOfSea => 'كزَبَد البحر';

  @override
  String get fromSurahIkhlasRecitation => 'من تلاوة سورة الإخلاص';

  @override
  String get laHawlaSubtitle => 'لا حول ولا قوة';

  @override
  String get equivalentRewardEarned => 'مكافأة معادلة مكتسبة';

  @override
  String get gatesOfParadise => 'أبواب الجنة';

  @override
  String get afterPerfectWudu => 'بعد الوضوء التام';

  @override
  String get blessingsFromAllah => 'بركات من الله';

  @override
  String get salawatTenReturned => 'صلوات × ١٠ مردودة';

  @override
  String get timesProtected => 'مرات الحماية';

  @override
  String get refugeInvokedFromHarm => 'استعاذة من الأذى';

  @override
  String get quranCompletions => 'ختمات القرآن';

  @override
  String get viaSurahIkhlas => 'عبر سورة الإخلاص ×٣';

  @override
  String get bonusHasanaat => 'حسنات إضافية';

  @override
  String get marketplaceDua => 'دعاء السوق';

  @override
  String get seedsDonatedToCommunity => 'بذور متبرَّع بها للمجتمع';

  @override
  String get yourMonth => 'شهرك';

  @override
  String get ayahsReadLabel => 'آيات مقروءة';

  @override
  String get dhikrCount => 'عدد الذكر';

  @override
  String get quranTime => 'وقت القرآن';

  @override
  String get dhikrTime => 'وقت الذكر';

  @override
  String get activeDays => 'الأيام النشطة';

  @override
  String get treesShortLabel => 'أشجار';

  @override
  String get palacesShortLabel => 'قصور';

  @override
  String get freedShortLabel => 'محرَّرون';

  @override
  String get blessingsShortLabel => 'بركات';

  @override
  String get dailyWordPrefix => 'اليومية ';

  @override
  String get essentialsWord => 'الأساسيات';

  @override
  String get seedsExpiringNotificationTitle =>
      'بذور ستنتهي صلاحيتها عند منتصف الليل!';

  @override
  String seedsExpiringNotificationBody(int pending) {
    return 'لديك $pending بذور معلقة. اختم اليوم الآن وإلا ستنتهي صلاحيتها!';
  }

  @override
  String get okButton => 'موافق';

  @override
  String get signUpTitle => 'إنشاء حساب';

  @override
  String get signInTitle => 'تسجيل الدخول';

  @override
  String get emailFieldLabel => 'البريد الإلكتروني';

  @override
  String get passwordFieldLabel => 'كلمة المرور';

  @override
  String get enterEmailValidator => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get enterPasswordValidator => 'يرجى إدخال كلمة المرور';

  @override
  String get passwordTooShortValidator =>
      'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';

  @override
  String get signUpSuccessMessage =>
      'تم إنشاء الحساب بنجاح! يرجى التحقق من بريدك الإلكتروني للتأكيد.';

  @override
  String get unexpectedAuthError => 'حدث خطأ غير متوقع';

  @override
  String get sawabLabel => 'ثواب';

  @override
  String get impactLabel => 'أثر';

  @override
  String get goodDeedTitle => 'عمل صالح';

  @override
  String get goodDeedSubtitle => 'اكسب ثواباً\nمع كل قراءة';

  @override
  String get realImpactTitle => 'أثر حقيقي';

  @override
  String get realImpactSubtitle => 'العملات تموّل\nقضايا نبيلة';

  @override
  String plusDeedsTodayBadge(String count) {
    return '+$count حسنة اليوم';
  }

  @override
  String equivalentChange(String count) {
    return '$count ما يعادل';
  }

  @override
  String receivedChange(String count) {
    return '$count مستلمة';
  }

  @override
  String readAyahsPlusTimeToday(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قرأت $count آيات و$time من تلاوة القرآن اليوم',
      one: 'قرأت آية واحدة و$time من تلاوة القرآن اليوم',
    );
    return '$_temp0';
  }

  @override
  String readAyahsToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قرأت $count آيات اليوم',
      one: 'قرأت آية واحدة اليوم',
    );
    return '$_temp0';
  }

  @override
  String spentTimeReadingQuranToday(String time) {
    return 'قضيت $time في تلاوة القرآن اليوم';
  }

  @override
  String get everyDeedRecordedKeepGoing => '🌙  كل عمل مسجَّل. واصل المسير!';

  @override
  String viewAllDonors(int count) {
    return 'عرض كل $count متبرعين';
  }

  @override
  String nextMilestoneInfo(String label, int days) {
    return 'التالي: $label ($days يوم)';
  }

  @override
  String bestN(int n) {
    return 'الأفضل $n';
  }

  @override
  String get streakMilestoneWarmingUp => 'بداية النشاط';

  @override
  String get streakMilestoneOneWeek => 'أسبوع واحد';

  @override
  String get streakMilestoneTwoWeeks => 'أسبوعان';

  @override
  String get streakMilestoneOneMonth => 'شهر واحد';

  @override
  String get streakMilestoneTwoMonths => 'شهران';

  @override
  String get streakMilestoneCenturion => 'المئوي';

  @override
  String get firstTrackedWeek => 'أول أسبوع مسجّل لك — واصل المسير!';

  @override
  String get rightOnSevenDayPace => 'تسير على نفس وتيرة أسبوعك';

  @override
  String aboveSevenDayAvg(int pct) {
    return '$pct٪ فوق متوسط أسبوعك';
  }

  @override
  String belowSevenDayAvg(int pct) {
    return '$pct٪ تحت متوسط أسبوعك';
  }

  @override
  String get sponsoredBy => 'كفله';

  @override
  String currentOverDays(int current, int days) {
    return '$current / $days يوم';
  }

  @override
  String daysWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أيام',
      one: 'يوم',
    );
    return '$_temp0';
  }

  @override
  String get dayAbbrMon => 'إث';

  @override
  String get dayAbbrTue => 'ث';

  @override
  String get dayAbbrWed => 'أر';

  @override
  String get dayAbbrThu => 'خ';

  @override
  String get dayAbbrFri => 'ج';

  @override
  String get dayAbbrSat => 'س';

  @override
  String get dayAbbrSun => 'أح';

  @override
  String get favoritesCategory => 'المفضلة';

  @override
  String get sleepingCategory => 'النوم';

  @override
  String get dailyWord => 'يومي';

  @override
  String get dailyDuasCategory => 'أدعية يومية';

  @override
  String get ruquiyaCategory => 'الرقية';

  @override
  String get duasBeforeSleep => 'أدعية قبل النوم';

  @override
  String get duasAfterSalah => 'أدعية بعد الصلاة';

  @override
  String get rabbana40Duas => '٤٠ دعاء ربّنا';

  @override
  String get thisWorld => 'الدنيا';

  @override
  String get dunyaArabic => 'دنيا';

  @override
  String get hereafter => 'الآخرة';

  @override
  String get akhirahArabic => 'الآخرة';

  @override
  String get bookOfCompletePrayer => 'كتاب الدعاء الكامل';

  @override
  String get propheticDuas => 'الأدعية النبوية';

  @override
  String get morningEveningRemembrance => 'أذكار الصباح والمساء';

  @override
  String get furtherDuas => 'أدعية إضافية';

  @override
  String get closingSalawat => 'أذكار الختام والصلوات';

  @override
  String get hajjAndUmrahCategory => 'أدعية الحج والعمرة';

  @override
  String get azkarSingular => 'ذكر';

  @override
  String get azkarPlural => 'أذكار';

  @override
  String get hourSingular => 'ساعة';

  @override
  String get hourPlural => 'ساعات';

  @override
  String get minuteSingular => 'دقيقة';

  @override
  String get minutePlural => 'دقائق';

  @override
  String get secondSingular => 'ثانية';

  @override
  String get secondPlural => 'ثوان';

  @override
  String seedsThisSession(String count) {
    return '+$count بذرة في هذه الجلسة';
  }

  @override
  String sevenDayAvgAzkaar(String count) {
    return 'متوسط 7 أيام: $count أذكار/يوم';
  }

  @override
  String holdingChangeAyahs(String count) {
    return '$count آية';
  }

  @override
  String holdingChangePlanted(String count) {
    return '$count مزروعة';
  }

  @override
  String holdingChangeCycles(String count) {
    return '$count دورة';
  }

  @override
  String holdingChangeBuilt(String count) {
    return '$count مبنية';
  }

  @override
  String holdingChangeEarned(String count) {
    return '$count مكتسبة';
  }

  @override
  String holdingChangeOpened(String count) {
    return '$count مفتوحة';
  }

  @override
  String holdingChangeInvocations(String count) {
    return '$count استعاذة';
  }

  @override
  String holdingChangeRecitations(String count) {
    return '$count تلاوة';
  }

  @override
  String bookmarksOnQuranCom(String count) {
    return 'العلامات على Quran.com: $count';
  }

  @override
  String bookmarksInThisApp(String count) {
    return 'العلامات في هذا التطبيق: $count';
  }

  @override
  String streakSeedsBonus(String count) {
    return '+$count بذور';
  }

  @override
  String plusSeedsThisWeek(String count) {
    return '+$count هذا الأسبوع';
  }

  @override
  String unitDuas(String count) {
    return '$count دعاء';
  }

  @override
  String unitAdhkar(String count) {
    return '$count ذكر';
  }

  @override
  String get moreCollections => 'المزيد من المجموعات';

  @override
  String get donateAndEarnReward => 'تبرّع واكسب الثواب';

  @override
  String donateAmountSeeds(String amount) {
    return 'تبرّع بـ $amount بذرة';
  }

  @override
  String get readMore => 'اقرأ المزيد';

  @override
  String get beFirstToContribute => 'كن أول من يساهم.';

  @override
  String get showFewer => 'عرض أقل ↑';

  @override
  String viewAllN(String n) {
    return 'عرض الكل $n ←';
  }

  @override
  String liveReadersNow(String count) {
    return '$count متصلون الآن';
  }

  @override
  String communityReadingToday(String count) {
    return '$count قرأوا اليوم (المجتمع)';
  }

  @override
  String communityHasanatToday(String count) {
    return '+$count حسنة للمجتمع اليوم';
  }

  @override
  String get peopleReadingNow => 'يقرأون الآن';

  @override
  String get readToday => 'قرأوا اليوم';

  @override
  String get communityHasanat => 'حسنات المجتمع';

  @override
  String orphan_be2bf7(String firstName, String lastInitial) {
    return '$firstName $lastInitial.';
  }

  @override
  String dashboardScreen_606140(String arg1, String _lastAyah) {
    return '$arg1 · $_lastAyah';
  }

  @override
  String dashboardScreen_setsToday(String _dhikrToday) {
    return '$_dhikrToday مجموعات اليوم';
  }

  @override
  String dashboardScreen_last(String arg1) {
    return 'الأخير: $arg1';
  }

  @override
  String get dashboardScreen_earnPerFriend => 'اربح +500 لكل صديق';

  @override
  String get dashboardScreen_invalidReferralCode_59fb25 =>
      'رمز الإحالة غير صالح.';

  @override
  String dashboardScreen_52b02c(String pts) {
    return '$pts';
  }

  @override
  String dashboardScreen_e4e562(String arg1) {
    return '$arg1%';
  }

  @override
  String dashboardScreen_d13a42(String _myPoints, String unit, String arg1) {
    return '$_myPoints $unit • $arg1';
  }

  @override
  String dhikrScreen_d08433(String arg1, String arg2) {
    return '$arg1 / $arg2';
  }

  @override
  String dhikrScreen_9a4c42(String bismillah, String arg1, String rest) {
    return '$bismillah ﴿$arg1﴾\\n$rest';
  }

  @override
  String dhikrScreen_86f857(String matched) {
    return '\\u2060$matched';
  }

  @override
  String dhikrScreen_49900d(String hasanaat) {
    return '+$hasanaat';
  }

  @override
  String dhikrScreen_3856c1(String rawRef, String bottomRef) {
    return '$rawRef | $bottomRef';
  }

  @override
  String get dhikrScreen_blessEverySenseEvery_b81b9b =>
      'بارك كل حاسة، وكل عضو، وكل عمل';

  @override
  String get dhikrScreen_keepTheHeartFirm_9c4efb => 'ثبت القلب بعد الهدى';

  @override
  String get dhikrScreen_faithAnsweredWithForgiveness_3f30c4 =>
      'أجاب الإيمان بالمغفرة من النار';

  @override
  String get dhikrScreen_inscribedWithTheWitnesses_e2612d =>
      'مكتوب مع شهود الحق';

  @override
  String get dhikrScreen_allahIsTheBest_4f2bf7 => 'والله أحكم بين الصدق والكذب';

  @override
  String get dhikrScreen_neverTrialForThe_5eb10a => 'أبدا فتنة للكافرين';

  @override
  String get dhikrScreen_refugeFromEveryEvil_6d2534 => 'أعوذ بك من كل شر يمسك';

  @override
  String get dhikrScreen_guaranteedJannahIfYou_48d274 =>
      'وتضمن لك الجنة إذا مت هذه الليلة';

  @override
  String get dhikrScreen_reciteAtDawnDusk_f17fb8 =>
      'وقل ثلاث مرات عند الفجر والمغرب تكفيك من جميع النواحي';

  @override
  String get dhikrScreen_nothingShallHarmYou_8c5c6c => 'لن يضرك شيء باسمه';

  @override
  String get dhikrScreen_guaranteedJannahIfYou_0ffafe =>
      'وتضمن لك الجنة إذا مت اليوم';

  @override
  String get dhikrScreen_guardedInYourDeen_4a0b4a =>
      'تحفظ في دينك · الدنيا · الآخرة، ومن الجهات الستة';

  @override
  String get dhikrScreen_guardMeFromAll => 'احرسني من جميع الجهات الستة';

  @override
  String dhikrScreen_35c165(String arg1) {
    return '$arg1';
  }

  @override
  String get dhikrScreen_sinsWashedAway => 'غسلت الخطايا';

  @override
  String get dhikrScreen_slavesFreed => 'العبيد المحررين';

  @override
  String get dhikrScreen_weHaveBelievedForgive_e958e6 =>
      'لقد آمنا فاغفر لنا وأنت خير الراحمين';

  @override
  String get dhikrScreen_mashaallahRewardSecured =>
      'ما شاء الله! المكافأة مضمونة';

  @override
  String dhikrScreen_a5cfd1(String count) {
    return '×$count';
  }

  @override
  String get dhikrScreen_completeToWatchYour =>
      'اكتمل لمشاهدة حديقتك تزدهر بالأعلى';

  @override
  String impactReportScreen_200447(String arg1) {
    return '+$arg1';
  }

  @override
  String get impactReportScreen_deedsTODAY => 'الأفعال اليوم';

  @override
  String impactReportScreen_634027(String arg1) {
    return '+$arg1';
  }

  @override
  String get impactReportScreen_thisWEEK => 'هذا الاسبوع';

  @override
  String get impactReportScreen_hasanaatEarned => 'حسنات مكتسبة';

  @override
  String impactReportScreen_hasanat_e68a30(String arg1) {
    return '→ حسنات: $arg1\\n\\n';
  }

  @override
  String get impactReportScreen_hasanatFromQuran => 'حسنات من القرآن';

  @override
  String get impactReportScreen_treesInJannah => 'أشجار في الجنة';

  @override
  String get impactReportScreen_sinsForgiven => 'مغفورة الذنوب';

  @override
  String get impactReportScreen_palacesBuilt => 'بنيت القصور';

  @override
  String get impactReportScreen_treasuresOfJannah => 'كنوز الجنة';

  @override
  String get impactReportScreen_slavesFreed => 'العبيد المحررين';

  @override
  String impactReportScreen_totalRecitations_262e54(String arg1) {
    return 'مجموع التلاوات: $arg1\\n';
  }

  @override
  String get impactReportScreen_gatesOfParadiseOpened => 'فتحت أبواب الجنة';

  @override
  String get impactReportScreen_blessingsFromAllah => 'بركات من الله';

  @override
  String get impactReportScreen_timesProtected => 'الأوقات المحمية';

  @override
  String get impactReportScreen_quranCompletions => 'ختمات القرآن';

  @override
  String get impactReportScreen_bonusMillionHasanaat => 'مكافأة مليون حسنات';

  @override
  String get impactReportScreen_sadaqahGiven => 'صدقة معطى';

  @override
  String impactReportScreen_564740(String _monthActiveDays) {
    return '$_monthActiveDays';
  }

  @override
  String impactReportScreen_3dc421(String arg1) {
    return '${arg1}h';
  }

  @override
  String impactReportScreen_08990a(String arg1) {
    return '$arg1م';
  }

  @override
  String impactReportScreen_ago_c25b44(String arg1) {
    return '${arg1}h منذ';
  }

  @override
  String impactReportScreen_ago_e160e3(String arg1) {
    return '${arg1}w منذ';
  }

  @override
  String impactReportScreen_ago_65f0ec(String arg1) {
    return '${arg1}y منذ';
  }

  @override
  String impactReportScreen_bd3721(String _myOrphansSponsoredCount) {
    return '$_myOrphansSponsoredCount';
  }

  @override
  String impactReportScreen_b3d969(String _myProjectsSupportedCount) {
    return '$_myProjectsSupportedCount';
  }

  @override
  String levelScreen_seeds_59c6a1(String arg1) {
    return '+$arg1 البذور';
  }

  @override
  String levelScreen_seeds_a20530(String arg1) {
    return '+$arg1 البذور';
  }

  @override
  String levelScreen_seeds_a49180(String arg1) {
    return '+$arg1 بذور ✓';
  }

  @override
  String levelScreen_seeds_a22be5(String arg1) {
    return '+$arg1 البذور';
  }

  @override
  String levelScreen_cf765f(
    String arg1,
    String arg2,
    String arg3,
    String arg4,
    String arg5,
  ) {
    return '$arg1:$arg2 $arg3/$arg4/$arg5';
  }

  @override
  String levelScreen_seeds_990893(String arg1) {
    return '+$arg1 البذور';
  }

  @override
  String get phase1Screens_inTheNameOf => 'بسم الله الرحمن…';

  @override
  String onboardingComponents_355c50(String first) {
    return '$first';
  }

  @override
  String onboardingComponents_b236c9(String trailing) {
    return '$trailing';
  }

  @override
  String orphansGridScreen_36cd3b(String arg1, String arg2) {
    return '$arg1 · $arg2';
  }

  @override
  String orphanDetailScreen_ago_c25b44(String arg1) {
    return '${arg1}h منذ';
  }

  @override
  String orphanDetailScreen_ago_e160e3(String arg1) {
    return '${arg1}w منذ';
  }

  @override
  String orphanDetailScreen_ago_65f0ec(String arg1) {
    return '${arg1}y منذ';
  }

  @override
  String get profileSettingsScreen_sabiqRewards => 'مكافآت سابق • v1.0';

  @override
  String profileSettingsScreen_seeds_59ba7c(String arg1) {
    return '$arg1 بذور';
  }

  @override
  String profileSettingsScreen_seeds_2bc978(String arg1) {
    return '$arg1 بذور';
  }

  @override
  String get profileSetupScreen_ahmadFatimaYusuf => 'أحمد، فاطمة، يوسف...';

  @override
  String get profileSetupScreen_pakistanEgyptMalaysia =>
      'باكستان، مصر، ماليزيا...';

  @override
  String projectDetailScreen_4c2b09(String arg1, String arg2, String arg3) {
    return '$arg1 $arg2 $arg3';
  }

  @override
  String projectDetailScreen_seeds_801ec7(String arg1) {
    return '$arg1 بذور';
  }

  @override
  String projectDetailScreen_e4e562(String arg1) {
    return '$arg1%';
  }

  @override
  String projectDetailScreen_ago_c25b44(String arg1) {
    return '${arg1}h منذ';
  }

  @override
  String projectDetailScreen_ago_e160e3(String arg1) {
    return '${arg1}w منذ';
  }

  @override
  String projectDetailScreen_ago_65f0ec(String arg1) {
    return '${arg1}y منذ';
  }

  @override
  String get quranHubScreen_loadingQuran => 'جاري تحميل القرآن...';

  @override
  String quranHubScreen_saved_edce53(String arg1) {
    return 'تم حفظ $arg1';
  }

  @override
  String quranScreen_003843(String arg1, String arg2) {
    return '$arg1 $arg2';
  }

  @override
  String quranScreen_3502e8(String arg1, String arg2) {
    return '$arg1 / $arg2';
  }

  @override
  String quranScreen_dcacc4(String _ayah, String arg1) {
    return '$_ayah / $arg1';
  }

  @override
  String get quranScreen_wordDataUnavailableCheck =>
      'بيانات الكلمة غير متوفرة. تحقق من اتصالك.';

  @override
  String quranScreen_6d1f9d(String arg1) {
    return '$arg1';
  }

  @override
  String quranScreen_ce2af3(String arg1) {
    return '$arg1%';
  }

  @override
  String quranScreen_6e8ac8(String text) {
    return '$text';
  }

  @override
  String get startJourneyScreen_connectedToQuranCom_0ac4de =>
      'متصل بـ Quran.com (تم تأجيل مزامنة الإشارات المرجعية)';

  @override
  String tafsirScreen_4815bb(
    String _surahName,
    String _ayah,
    String _surahLen,
  ) {
    return '$_surahName $_ayah/$_surahLen';
  }

  @override
  String get donationService_youMustBeLogged_edc4b5 =>
      'يجب عليك تسجيل الدخول للراعي.';

  @override
  String get liveNotificationService_sealYourSeedsBefore_be2183 =>
      'ختم البذور الخاصة بك قبل منتصف الليل!';

  @override
  String streakService_1fc043(String arg1, String arg2) {
    return '$arg1 $arg2';
  }

  @override
  String trackingService_c7528c(String arg1, String arg2) {
    return '$arg1 $arg2';
  }

  @override
  String motivationalPopup_seeds_b14996(String arg1) {
    return '+$arg1 البذور';
  }

  @override
  String get motivationalPopup_readQuranPages => 'قراءة 5 صفحات القرآن';

  @override
  String get motivationalPopup_completeDhikrSet => 'أكمل مجموعة الأذكار';

  @override
  String get motivationalPopup_inviteFriend => 'قم بدعوة صديق';

  @override
  String notificationsSheet_ago(String arg1) {
    return '$arg1م مضت';
  }

  @override
  String notificationsSheet_ago_5d4e7f(String arg1) {
    return '${arg1}h منذ';
  }

  @override
  String notificationsSheet_ago_67b1d9(String arg1) {
    return '${arg1}d منذ';
  }

  @override
  String sealCoinAnimation_e16fa4(String arg1) {
    return '+$arg1';
  }

  @override
  String orphan_be2bf7_be2bf7(String firstName, String lastInitial) {
    return '$firstName $lastInitial.';
  }

  @override
  String get akhirahBalanceScreen_subhanallahiWaBiHamdihi_b246c2 =>
      '\"\"سبحان الله وبحمده\"\" في اليوم 100 مرة تمحو الخطايا مثل زبد البحر. (البخاري)';

  @override
  String get akhirahBalanceScreen_sayLaIlahaIllallah_27fc5f =>
      'وقول لا إله إلا الله 100 مرة تعدل عتق 10 عبيد و100 حسنة. (البخاري)';

  @override
  String get akhirahBalanceScreen_lightOnTheTongue_ea6114 =>
      'خفيف على اللسان، ثقيل في الميزان: سبحان الله وبحمده، سبحان الله العظيم. (البخاري 6406) .';

  @override
  String get akhirahBalanceScreen_theDhikrOfAllah_a23f17 =>
      'فإن ذكر الله أثقل في الميزان من ذهب مثله. يستمر في التقدم.';

  @override
  String get akhirahBalanceScreen_yourTongueShouldStay_34816c =>
      '«وينبغي أن يظل لسانك رطبًا بذكر الله». - هل لا تزال رطبة؟';

  @override
  String get akhirahBalanceScreen_astaghfirullahTheProphetSaid_7625ff =>
      'استغفر الله — قالها النبي ﷺ في اليوم 100 مرة، ولم يكن له ذنب. كم لديك؟';

  @override
  String get akhirahBalanceScreen_whenYouRememberAllah_60f406 =>
      'وإذا ذكرتم الله خفية ذكركم في ملأ أكبر.';

  @override
  String get akhirahBalanceScreen_reciteAyatAlKursi_d0751f =>
      'اقرأ آية الكرسي بعد كل صلاة، فلا يمنعك من الجنة إلا الموت.';

  @override
  String get akhirahBalanceScreen_oneAlhamdulillahFillsThe_4794bb =>
      'الحمدلله يملأ الميزان . سبحان الله ملء ما بين السماء والأرض.';

  @override
  String get akhirahBalanceScreen_theRemembranceOfAllah_c99fe8 =>
      '«ذكر الله أكبر من كل شيء». — سورة العنكبوت 29:45';

  @override
  String get akhirahBalanceScreen_rememberMeWillRemember_1aca04 =>
      '\" فاذكروني أذكركم \". - سورة البقرة 2: 152. سوف تفعل؟';

  @override
  String get akhirahBalanceScreen_inTheRemembranceOf_20b541 =>
      '«بذكر الله تطمئن القلوب». — سورة الرعد 13:28';

  @override
  String get akhirahBalanceScreen_fiveMinutesOfDhikr_e12766 =>
      'خمس دقائق من الذكر تشكل الآن الـ 24 ساعة القادمة من قلبك.';

  @override
  String get akhirahBalanceScreen_streakIsnAboutToday_9157d8 =>
      'لا يتعلق الخط باليوم، بل يتعلق بما ستصبح عليه خلال 30 يومًا.';

  @override
  String get akhirahBalanceScreen_smallDropsFillAn_1accce =>
      'قطرات صغيرة تملأ المحيط. أذكارك اليومية تملأ شيئًا أكبر بكثير.';

  @override
  String get akhirahBalanceScreen_noOneSeesThe_0182c7 =>
      'لا أحد يرى الذكر في قلبك، ولكن كل ملاك يكتب سجلك يفعل ذلك.';

  @override
  String get akhirahBalanceScreen_theBiggestWinsAre_1b8fb6 =>
      'أعظم المكاسب تبنى من أصغر العادات اليومية. لا تكسر السلسلة.';

  @override
  String get akhirahBalanceScreen_youCameBackToday_a020b1 =>
      'لقد عدت اليوم. هذه عبادة بالفعل. البقاء دقيقة واحدة أخرى؟';

  @override
  String get akhirahBalanceScreen_tomorrowPeaceIsBuilt_a72bd8 =>
      'فسلام الغد مبني على ذكرى اليوم. زرع بذرة أخرى.';

  @override
  String get akhirahBalanceScreen_areYouDoneAllah_06ca1d =>
      'هل انتهيت؟ باب الله مفتوح دائما، حتى بعد أن تغلقه.';

  @override
  String get akhirahBalanceScreen_dhikrIsTheLanguage_b1b983 =>
      'الذكر هو لغة القلب. هل كلمت ربها اليوم؟';

  @override
  String get akhirahBalanceScreen_everySubhanallahIsSadaqah_16b797 =>
      'وكل سبحان الله صدقة. كم ستعطي قبل النوم؟';

  @override
  String get akhirahBalanceScreen_heartThatForgetsDhikr_3a6173 =>
      'القلب الذي ينسى الذكر يبدأ بالصدأ. القلب الذي يتذكر يبقى مشتعلا.';

  @override
  String get akhirahBalanceScreen_haveYouFortifiedYourself_17ccac =>
      'هل حصنت نفسك بأذكار الصباح والمساء اليوم؟';

  @override
  String dashboardScreen_sponsor_d48549(String name, String arg1) {
    return 'الراعي $name، $arg1';
  }

  @override
  String dashboardScreen_606140_606140(String arg1, String _lastAyah) {
    return '$arg1 · $_lastAyah';
  }

  @override
  String get dashboardScreen_joinMeOnSabiq_755fb5 =>
      'انضم إلي في برنامج Sabiq Rewards واحصل على بذور القرآن والذكر والأعمال الصالحة يوميًا!\\n\\n';

  @override
  String dashboardScreen_useMyCodeAnd_7d13b3(String arg1) {
    return 'استخدم الرمز الخاص بي *$arg1* وسنحصل على 500 بذرة سابق!\\n\\n';
  }

  @override
  String get dashboardScreen_messageCopiedShareOr_7b977e =>
      'تم نسخ الرسالة أو مشاركتها أو لصقها في WhatsApp!';

  @override
  String get dashboardScreen_sabiqSeedsRewardedTo_c209d6 =>
      '500 بذرة سابق مكافأة لكما!';

  @override
  String get dashboardScreen_youHaveAlreadyUsed_f7c387 =>
      'لقد استخدمت بالفعل رمز الإحالة.';

  @override
  String get dashboardScreen_youCannotUseYour_b7dbfe =>
      'لا يمكنك استخدام الكود الخاص بك.';

  @override
  String get dashboardScreen_anErrorOccurredPlease_8ee486 =>
      'حدث خطأ. يرجى المحاولة مرة أخرى.';

  @override
  String dashboardScreen_52b02c_52b02c(String pts) {
    return '$pts';
  }

  @override
  String dashboardScreen_e4e562_e4e562(String arg1) {
    return '$arg1%';
  }

  @override
  String get dashboardScreen_viewCampaignDonate_450be4 =>
      '🤲 شاهد الحملة وتبرع';

  @override
  String dashboardScreen_d13a42_d13a42(
    String _myPoints,
    String unit,
    String arg1,
  ) {
    return '$_myPoints $unit • $arg1';
  }

  @override
  String get dashboardScreen_beTheFirstOn_63de17 => 'كن الأول على اللوح';

  @override
  String get dashboardScreen_readAnAyahOr_9c7ab7 =>
      'اقرأ آية أو ذكر لتحصل على المركز الأول';

  @override
  String dashboardScreen_lvl_ac180d(String level, String arg1) {
    return 'المستوى $level · $arg1';
  }

  @override
  String dhikrScreen_default_8bd36b(String recommendedCount) {
    return 'الافتراضي: $recommendedCount';
  }

  @override
  String get dhikrScreen_pinTheIllustrationAt_5ec641 =>
      'قم بتثبيت الرسم التوضيحي في الأعلى أثناء تمرير النص العربي أسفله';

  @override
  String dhikrScreen_d08433_d08433(String arg1, String arg2) {
    return '$arg1 / $arg2';
  }

  @override
  String dhikrScreen_9a4c42_9a4c42(String bismillah, String arg1, String rest) {
    return '$bismillah ﴿$arg1﴾\\n$rest';
  }

  @override
  String dhikrScreen_86f857_86f857(String matched) {
    return '\\u2060$matched';
  }

  @override
  String dhikrScreen_49900d_49900d(String hasanaat) {
    return '+$hasanaat';
  }

  @override
  String dhikrScreen_3856c1_3856c1(String rawRef, String bottomRef) {
    return '$rawRef | $bottomRef';
  }

  @override
  String dhikrScreen_35c165_35c165(String arg1) {
    return '$arg1';
  }

  @override
  String dhikrScreen_a5cfd1_a5cfd1(String count) {
    return '×$count';
  }

  @override
  String get impactReportScreen_whoeverDoesAnAtom_9013b0 => '«من عمل ذرة';

  @override
  String get impactReportScreen_theHomeOfThe_4602d2 =>
      '«إن الدار الآخرة تلك هي الحياة الأبدية لو كانوا يعلمون». — سورة العنكبوت 29:64';

  @override
  String get impactReportScreen_raceTowardsForgivenessFrom_94d614 =>
      '«سارعوا إلى مغفرة من ربكم وجنة عرضها السماوات والأرض». — سورة الحديد 57:21';

  @override
  String get impactReportScreen_andWhatIsThe_7eec52 =>
      '\"وما الحياة الدنيا إلا لعب الغرور؟\" - سورة علي عمران 3: 185';

  @override
  String get impactReportScreen_indeedWithHardshipComes_ea97fa =>
      '«إن مع العسر يسرا». — سورة الشرح 94:6';

  @override
  String get impactReportScreen_singleGoodDeedIn_c126b4 =>
      '«الحسنة في رمضان تعدل سبعين حسنة فيما سواه». كومة بينما الباب مفتوح.';

  @override
  String get impactReportScreen_theProphetSaidCharity_c154f4 =>
      'قال النبي ✍: ما نقصت الصدقة من مال إلا نبته. (مسلم)';

  @override
  String get impactReportScreen_smilingAtYourBrother_8f55e4 =>
      '«تبسمك في وجه أخيك صدقة». يمكنك الربح حتى عندما تكون جيوبك فارغة. (الترمذي)';

  @override
  String get impactReportScreen_theMostBelovedDeeds_f11906 =>
      '«أحب الأعمال إلى الله أدومها وإن قل». (البخاري)';

  @override
  String get impactReportScreen_inJannahIsWhat_ff6d55 =>
      '\"في الجنة ما لا عين رأت، ولا أذن سمعت، ولا خطر على قلب بشر.\" (البخاري)';

  @override
  String get impactReportScreen_twoRakatsAtFajr_c8b238 =>
      'وركعتان الفجر خير من الدنيا وما فيها. (مسلم)';

  @override
  String get impactReportScreen_everyStepTowardSalah_62962f =>
      'وكل خطوة إلى الصلاة تمحو خطيئة وترفع درجة. (مسلم)';

  @override
  String get impactReportScreen_everySeedYouDonate_618d1f =>
      'كل بذرة تتبرع بها تزرع شجرة في شخص آخر\\';

  @override
  String get impactReportScreen_takeWealthWithYou_784e85 =>
      'لا تأخذ الثروة معك. فقط الأفعال التي اشتراها.';

  @override
  String get impactReportScreen_theAngelsRecordNothing_e03c03 =>
      'الملائكة لا يسجلون شيئًا صغيرًا جدًا. سبحان الله قد يفوق جبلاً.';

  @override
  String get impactReportScreen_sadaqahIsTomorrow_794857 => 'صدقة غدا\\';

  @override
  String get impactReportScreen_heartThatGivesIs_4b6000 =>
      'القلب الذي يعطي هو قلب يبقيه الله ممتلئا. اِتَّشَح\\';

  @override
  String get impactReportScreen_theReceiptWhatDid_d1c41b =>
      'هو الإيصال. ماذا أرسلت قدما؟';

  @override
  String get impactReportScreen_imagineYourScaleOn_094d07 =>
      'تخيل ميزانك في يوم القيامة. ما الوزن الذي تضيفه اليوم؟';

  @override
  String get impactReportScreen_theWorldIsBorrowed_2eeb50 =>
      'العالم مستعار. الآخرة مملوكة. استثمر وفقًا لذلك.';

  @override
  String get impactReportScreen_youBuryTheBody_bb5233 =>
      'أنت تدفن الجسد، ولكن ليس الأفعال. أرسلهم للأمام بينما تستطيع.';

  @override
  String get impactReportScreen_righteousChildWhoPrays_7bcef4 =>
      'ولد صالح يدعو لك، أو صدقة تجري، أو علم ينتفع - ثلاث استثمارات خالدة. (مسلم)';

  @override
  String get impactReportScreen_youWillMeetAllah_c19524 =>
      'ستقابل الله بسجلك. تأكد اليوم\\';

  @override
  String get impactReportScreen_noDeedIsToo_c04d50 =>
      'لا يستصغر عملاً من يعد الذرات.';

  @override
  String impactReportScreen_200447_200447(String arg1) {
    return '+$arg1';
  }

  @override
  String impactReportScreen_634027_634027(String arg1) {
    return '+$arg1';
  }

  @override
  String get impactReportScreen_whoeverDoesGoodDeed_89c2bf =>
      'من عمل الحسنة فله عشر أمثالها.';

  @override
  String get impactReportScreen_whoeverReadsLetterFrom_36d74f =>
      'من قرأ حرفاً من كتاب الله فله حسنة، والحسنة بعشر أمثالها.';

  @override
  String get impactReportScreen_twoHadithGrowThis_c8d4a2 =>
      'حديثان يزيدان هذا العدد جنباً إلى جنب:\\n\\n';

  @override
  String impactReportScreen_dhikrRecitedLifetime_669e2a(String arg1) {
    return 'الأذكار المرتلة (مدى الحياة): $arg1\\n';
  }

  @override
  String impactReportScreen_hasanat_64c7b6(String arg1) {
    return '→ حسنات: $arg1\\n\\n';
  }

  @override
  String impactReportScreen_ayahsReadLifetime_75eef6(String arg1) {
    return 'قراءة الآيات (العمر): $arg1\\n';
  }

  @override
  String impactReportScreen_totalHasanaat_c43112(String arg1) {
    return 'مجموع الحسنات: $arg1';
  }

  @override
  String get impactReportScreen_whoeverSaysSubhanAllahiWa_4b6459 =>
      'من قال سبحان الله وبحمده في يوم 100 مرة غفرت ذنوبه ولو كانت مثل زبد البحر.';

  @override
  String get impactReportScreen_subhanallahiWaBihamdihi_992976 =>
      'سبحان الله وبحمده';

  @override
  String impactReportScreen_totalRecitations_5ed733(String arg1) {
    return 'مجموع التلاوات: $arg1\\n';
  }

  @override
  String impactReportScreen_dividedByForgivenessCycles_4e175d(String arg1) {
    return 'مقسومًا على 100 ← دورات الغفران: $arg1';
  }

  @override
  String impactReportScreen_dividedByPalaces_6f066c(String arg1) {
    return 'مقسمة على 10 → القصور: $arg1';
  }

  @override
  String get impactReportScreen_laIlahaIllallahuWahdahu_895dde =>
      'لا إله إلا الله وحده لا شريك له...';

  @override
  String impactReportScreen_setsOfSetsSlaves_b43b31(String arg1, String arg2) {
    return 'مجموعات من 10 → $arg1 مجموعات × 4 عبيد = $arg2';
  }

  @override
  String impactReportScreen_totalSalawatSent_cfe45e(String arg1) {
    return 'إجمالي الصلوات المرسلة: $arg1\\n';
  }

  @override
  String impactReportScreen_multipliedByBlessingsReceived_52810f(String arg1) {
    return 'مضروبة في 10 → $arg1 النعم المستلمة';
  }

  @override
  String get impactReportScreen_protectionFromEvil_37b53a => 'الحماية من الشر';

  @override
  String get impactReportScreen_goodHealthProtection_058808 =>
      'صحة جيدة وحماية';

  @override
  String impactReportScreen_totalInvocations_1fd02b(String arg1) {
    return 'إجمالي الدعوات: $arg1';
  }

  @override
  String impactReportScreen_dividedByQuranCompletions_b9a013(String arg1) {
    return 'مقسمة على 3 → $arg1 ختمات القرآن';
  }

  @override
  String impactReportScreen_564740_564740(String _monthActiveDays) {
    return '$_monthActiveDays';
  }

  @override
  String impactReportScreen_3dc421_3dc421(String arg1) {
    return '${arg1}h';
  }

  @override
  String impactReportScreen_08990a_08990a(String arg1) {
    return '$arg1م';
  }

  @override
  String impactReportScreen_ago_71107c(String arg1) {
    return '$arg1م مضت';
  }

  @override
  String impactReportScreen_moAgo_325a71(String arg1) {
    return '$arg1 منذ شهر';
  }

  @override
  String impactReportScreen_failed_190558(String e) {
    return 'فشل: $e';
  }

  @override
  String impactReportScreen_funded_add009(String arg1) {
    return '$arg1% ممولة';
  }

  @override
  String get impactReportScreen_yourLifetimeImpact_8bfdcd => 'تأثير حياتك';

  @override
  String get impactReportScreen_startYourImpactJourney_1ae8c4 =>
      'ابدأ رحلة التأثير الخاصة بك';

  @override
  String impactReportScreen_bd3721_bd3721(String _myOrphansSponsoredCount) {
    return '$_myOrphansSponsoredCount';
  }

  @override
  String impactReportScreen_b3d969_b3d969(String _myProjectsSupportedCount) {
    return '$_myProjectsSupportedCount';
  }

  @override
  String levelScreen_seeds_fff97b(String arg1) {
    return '+$arg1 البذور';
  }

  @override
  String get levelScreen_laIlahaIllallah_e8c26b => 'لا إله إلا الله x100';

  @override
  String levelScreen_seedsBoost_464454(String arg1) {
    return '$arg1× تعزيز البذور';
  }

  @override
  String levelScreen_cf765f_cf765f(
    String arg1,
    String arg2,
    String arg3,
    String arg4,
    String arg5,
  ) {
    return '$arg1:$arg2 $arg3/$arg4/$arg5';
  }

  @override
  String levelScreen_days_100e10(String current, String arg1) {
    return '$current / $arg1 أيام';
  }

  @override
  String levelScreen_dayStreak_df2abf(String arg1) {
    return '$arg1 خط يوم';
  }

  @override
  String onboardingComponents_355c50_355c50(String first) {
    return '$first';
  }

  @override
  String onboardingComponents_b236c9_b236c9(String trailing) {
    return '$trailing';
  }

  @override
  String get quranMini_inTheNameOf_46925d => 'بسم الله الرحمن الرحيم.';

  @override
  String get quranMini_allPraiseBelongsTo_2d51df => 'والحمد لله رب العالمين.';

  @override
  String orphansGridScreen_36cd3b_36cd3b(String arg1, String arg2) {
    return '$arg1 · $arg2';
  }

  @override
  String orphanDetailScreen_years_debb46(String arg1) {
    return '$arg1 سنة';
  }

  @override
  String orphanDetailScreen_ofSeeds_2a29fc(String arg1, String arg2) {
    return '$arg1 من $arg2 البذور';
  }

  @override
  String orphanDetailScreen_through_2cdb72(String arg1) {
    return 'من خلال $arg1';
  }

  @override
  String get orphanDetailScreen_andTheyGiveFood_7ddcff =>
      'ويطعمون الطعام على حبهم له مسكينا ويتيما وأسيرا.';

  @override
  String orphanDetailScreen_ago_71107c(String arg1) {
    return '$arg1م مضت';
  }

  @override
  String orphanDetailScreen_moAgo_325a71(String arg1) {
    return '$arg1 منذ شهر';
  }

  @override
  String orphanDetailScreen_seeds_30d8dc(String _availablePoints) {
    return '$_availablePoints بذور';
  }

  @override
  String orphanDetailScreen_sponsor_b34bcf(String arg1) {
    return 'الراعي $arg1';
  }

  @override
  String orphanDetailScreen_jazakallahKhayranSeedsSponsored_316bec(
    String amount,
  ) {
    return 'جزاك الله خيران! $amount البذور برعاية.';
  }

  @override
  String orphanDetailScreen_chooseHowManySeeds_b69aa2(String arg1) {
    return 'اختر عدد البذور التي تريد تقديمها. الحد الأدنى $arg1.';
  }

  @override
  String orphanDetailScreen_yourBalanceSeeds_f8045b(String arg1) {
    return 'رصيدك: $arg1 بذور';
  }

  @override
  String get profileSettingsScreen_nameCannotBeEmpty_c737ab =>
      'لا يمكن أن يكون الاسم فارغًا';

  @override
  String get profileSettingsScreen_signedInWithGoogle_17e053 =>
      'تم تسجيل الدخول باستخدام جوجل';

  @override
  String get profileSettingsScreen_signedInWithQuran_2e1ffc =>
      'تم التسجيل في موقع القرآن الكريم';

  @override
  String get profileSettingsScreen_signedInWithEmail_dd881f =>
      'تم تسجيل الدخول باستخدام البريد الإلكتروني';

  @override
  String profileSettingsScreen_seeds_53d666(String arg1) {
    return '$arg1 بذور';
  }

  @override
  String get profileSettingsScreen_guidesFAQsAndHow_b990d6 =>
      'الأدلة والأسئلة الشائعة والكيفية';

  @override
  String get profileSettingsScreen_somethingNotWorkingTell_07f659 =>
      'شيء لا يعمل؟ أخبرنا';

  @override
  String projectDetailScreen_organisedBy_8b317a(String sponsor) {
    return 'تم التنظيم بواسطة $sponsor\\n\\n';
  }

  @override
  String get projectDetailScreen_fundedSoFarEvery_dab3fd =>
      'تم تمويل كل بذرة حتى الآن!\\n\\n';

  @override
  String get projectDetailScreen_openSabiqRewardsApp_cdda14 =>
      'افتح تطبيق Sabiq Rewards للتبرع ببذورك والحصول على المكافأة.\\n';

  @override
  String get projectDetailScreen_sabiqrewardsSadaqahIslamicCharity_663ba5 =>
      '#مكافآت سابق #صدقة #الجمعية الخيرية الإسلامية';

  @override
  String projectDetailScreen_4c2b09_4c2b09(
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg1 $arg2 $arg3';
  }

  @override
  String get projectDetailScreen_donateToProvideUrgent_246035 =>
      'تبرع لتقديم مساعدات عاجلة ومنقذة للحياة للفلسطينيين الذين يعانون من نقص حاد في الغذاء والمياه والإمدادات الطبية...';

  @override
  String projectDetailScreen_seeds_47387f(String arg1) {
    return '$arg1 بذور';
  }

  @override
  String projectDetailScreen_e4e562_e4e562(String arg1) {
    return '$arg1%';
  }

  @override
  String projectDetailScreen_ago_71107c(String arg1) {
    return '$arg1م مضت';
  }

  @override
  String projectDetailScreen_moAgo_325a71(String arg1) {
    return '$arg1 منذ شهر';
  }

  @override
  String quranHubScreen_saved_9c28a3(String arg1) {
    return 'تم حفظ $arg1';
  }

  @override
  String get quranScreen_couldNotLoadAyah_62f120 =>
      'تعذر تحميل الآية. يرجى إعادة المحاولة.';

  @override
  String get quranScreen_noConnectionCachedData_e5a215 =>
      'لا يوجد اتصال. قد تكون البيانات المخزنة مؤقتًا متاحة.';

  @override
  String quranScreen_ayahs_c98642(String arg1) {
    return '$arg1 الآيات';
  }

  @override
  String get quranScreen_couldNotRemoveBookmark_699a82 =>
      'تعذرت إزالة الإشارة المرجعية، يرجى إعادة المحاولة';

  @override
  String quranScreen_removedBookmark_d7a16a(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'تمت إزالة الإشارة المرجعية $_surahName $_surah:$_ayah';
  }

  @override
  String get quranScreen_couldNotSaveBookmark_976448 =>
      'تعذر حفظ الإشارة المرجعية، يرجى إعادة المحاولة';

  @override
  String quranScreen_bookmarked_2c6203(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'تم وضع إشارة مرجعية $_surahName $_surah:$_ayah';
  }

  @override
  String quranScreen_tafsir_391c0d(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'التفسير · $_surahName $_surah:$_ayah';
  }

  @override
  String get quranScreen_addedToFavourites_b3cce0 => '♥ تم الإضافة إلى المفضلة';

  @override
  String quranScreen_pt_9e58e8(String arg1) {
    return '$arg1 نقطة';
  }

  @override
  String quranScreen_003843_003843(String arg1, String arg2) {
    return '$arg1 $arg2';
  }

  @override
  String quranScreen_3502e8_3502e8(String arg1, String arg2) {
    return '$arg1 / $arg2';
  }

  @override
  String quranScreen_dcacc4_dcacc4(String _ayah, String arg1) {
    return '$_ayah / $arg1';
  }

  @override
  String quranScreen_6d1f9d_6d1f9d(String arg1) {
    return '$arg1';
  }

  @override
  String quranScreen_ayahsRead_862866(String _ayahsToday) {
    return '$_ayahsToday آيات مقروءة';
  }

  @override
  String quranScreen_ce2af3_ce2af3(String arg1) {
    return '$arg1%';
  }

  @override
  String quranScreen_6e8ac8_6e8ac8(String text) {
    return '$text';
  }

  @override
  String get startJourneyScreen_unexpectedErrorDuringGoogle_86c1a5 =>
      'حدث خطأ غير متوقع أثناء تسجيل الدخول إلى Google';

  @override
  String get startJourneyScreen_connectedToQuranCom_c0c631 =>
      'متصل بموقع القرآن الكريم';

  @override
  String tafsirScreen_verses_fed624(String arg1) {
    return '$arg1 الآيات';
  }

  @override
  String tafsirScreen_ayahOf_63c42b(String _ayah, String _surahLen) {
    return 'آية $_ayah من $_surahLen';
  }

  @override
  String tafsirScreen_4815bb_4815bb(
    String _surahName,
    String _ayah,
    String _surahLen,
  ) {
    return '$_surahName $_ayah/$_surahLen';
  }

  @override
  String get donationService_youMustBeLogged_6813cf =>
      'يجب عليك تسجيل الدخول للتبرع.';

  @override
  String get donationService_donationCouldNotBe_074195 =>
      'لا يمكن معالجة التبرع في هذا الوقت.';

  @override
  String get donationService_anUnexpectedNetworkError_914b7a =>
      'حدث خطأ غير متوقع في الشبكة.';

  @override
  String get donationService_sponsorshipReceived_671201 =>
      'تم الحصول على الرعاية 💝';

  @override
  String donationService_youSponsoredSeedsJazak_7711e1(String amount) {
    return 'لقد قمت برعاية $amount بذور · جزاك الله خيرا.';
  }

  @override
  String get donationService_sponsorshipCouldNotBe_55003e =>
      'لا يمكن معالجة الرعاية في هذا الوقت.';

  @override
  String get streakService_warmingUp_b1687b => 'الاحماء';

  @override
  String get streakService_oneWeek_4f98dc => 'أسبوع واحد';

  @override
  String get streakService_twoWeeks_9a2d93 => 'اسبوعين';

  @override
  String get streakService_oneMonth_35eb01 => 'شهر واحد';

  @override
  String get streakService_twoMonths_84d275 => 'شهرين';

  @override
  String get streakService_theCenturion_f1de7f => 'قائد المئة';

  @override
  String streakService_1fc043_1fc043(String arg1, String arg2) {
    return '$arg1 $arg2';
  }

  @override
  String trackingService_c7528c_c7528c(String arg1, String arg2) {
    return '$arg1 $arg2';
  }

  @override
  String xpService_level_226f81(String title, String level) {
    return '$title • المستوى $level';
  }

  @override
  String get xpService_newBadgeUnlocked_2c8d0e => 'تم فتح شارة جديدة 🏆';

  @override
  String get xpService_dailyLoginBonus_d011fa => 'مكافأة تسجيل الدخول اليومية';

  @override
  String xpService_seedsWelcomeBack_47888a(String arg1) {
    return '+$arg1 البذور · أهلاً بعودتك!';
  }

  @override
  String get xpService_daySealed_037a56 => 'اليوم مختوم 🌙';

  @override
  String xpService_sabiqSeedsConfirmedBonus_702902(
    String flushed,
    String bonus,
  ) {
    return '+$flushed بذور سابق مؤكدة! ($bonus مكافأة للختم)';
  }

  @override
  String xpService_sabiqSeedsConfirmed_34969c(String flushed) {
    return '+$flushed بذور سابق مؤكدة!';
  }

  @override
  String get dhikrExitCelebration_everyBreathCounts_45b3df => 'كل نفس مهم.';

  @override
  String get impactAnimation_yourRewardHasBeen_e3d106 =>
      'لقد تم تسجيل مكافأتك.';

  @override
  String get motivationalPopup_verilyWithHardshipComes_f23637 =>
      'إن مع العسر يسرا.\\nوكل فتنة باب إلى ما هو أعظم.';

  @override
  String get motivationalPopup_quranAlInshirah_d81f8a =>
      'القرآن • الانشراح 94:6';

  @override
  String get motivationalPopup_quranAlAnkabut_8e938e =>
      'القرآن • العنكبوت 29:45';

  @override
  String get motivationalPopup_quranAlBaqarah_8bb10e => 'القرآن • البقرة 2:152';

  @override
  String get motivationalPopup_quranAnNahl_74d608 => 'القرآن • النحل 16:18';

  @override
  String get motivationalPopup_makeYourTimePrecious_049aae =>
      'اجعل وقتك ثميناً.\\nشارك الخير مع صديق اليوم،\\nكل عمل صالح تشاركه صدقة.';

  @override
  String get motivationalPopup_guideOthersToGood_6105c4 =>
      'أرشد غيرك إلى الخير، تنال أجره.';

  @override
  String get motivationalPopup_theBestOfPeople_1f6906 =>
      'خير الناس من أنفعهم للآخرين.';

  @override
  String get motivationalPopup_verilyInTheRemembrance_16476d =>
      'ألا بذكر الله تطمئن القلوب.';

  @override
  String get motivationalPopup_remindYourselfTimeIs_38ae33 =>
      'ذكّر نفسك أن الوقت هو أغلى صدقة.';

  @override
  String get motivationalPopup_yourTimeIsYour_be6731 =>
      'وقتك هو أثمن\\nأصولك. استثمرها بحكمة\\nفي ما يدوم إلى الأبد.';

  @override
  String get motivationalPopup_quranAlAnfal_b10486 => 'القرآن • الأنفال 8:28';

  @override
  String get motivationalPopup_takeAdvantageOfFive_e573fd =>
      'اغتنم خمسا قبل خمس.';

  @override
  String motivationalPopup_seeds_3a9c69(String arg1) {
    return '+$arg1 البذور';
  }

  @override
  String get motivationalPopup_completeNowEarnSeeds_16ea6e =>
      'أكمل الآن → اربح +50 بذرة إضافية';

  @override
  String get motivationalPopup_finishYourAzkaarEarn_e264fa =>
      'أنهي الأذكار ← اربح +30 بذرة إضافية';

  @override
  String get motivationalPopup_shareSabiqWithSomeone_c60dcc =>
      'شارك سابق مع شخص ما ← اربح +100 بذرة';

  @override
  String get motivationalPopup_keepYourSpiritualMomentum_0f172c =>
      'حافظ على استمرار زخمك الروحي\\nوشاهد بذورك تنمو ✨';

  @override
  String get projectMediaCarousel_couldNotLoadVideo_deb8dd =>
      'تعذر تحميل الفيديو';

  @override
  String get quranExitCelebration_beautifulRecitation_9d2655 => 'تلاوة جميلة.';

  @override
  String get quranExitCelebration_everyMomentCounts_fddb4c =>
      'كل لحظة لها أهميتها.';

  @override
  String sealCoinAnimation_e16fa4_e16fa4(String arg1) {
    return '+$arg1';
  }

  @override
  String impactReportScreen_totalHasanatFromQuran(String n) {
    return 'مجموع الحسنات من القرآن : $n';
  }

  @override
  String impactReportScreen_totalTreesPlanted(String n) {
    return 'إجمالي الأشجار المزروعة: $n';
  }

  @override
  String impactReportScreen_totalTreasures(String n) {
    return 'إجمالي الكنوز: $n';
  }

  @override
  String impactReportScreen_multipliedByGates(String n) {
    return 'مضروبة في 8 بوابات → فتحات $n';
  }

  @override
  String impactReportScreen_bonusHasanaat(String n) {
    return 'حسنات إضافية: $n';
  }

  @override
  String impactReportScreen_totalDonatedSeeds(String n, String seeds) {
    return 'إجمالي التبرعات: $n $seeds';
  }

  @override
  String get dashboardScreen_dashboardLoadFailed =>
      'تعذر تحميل لوحة البيانات الخاصة بك. يرجى المحاولة مرة أخرى.';

  @override
  String get zikrLabel => 'ذكر';

  @override
  String get quranLabel => 'القرآن';

  @override
  String streakService_dayStreakBody(String days, String type, String bonus) {
    return '$days-يوم $type خط · +$bonus بذور إضافية تم فتحها';
  }

  @override
  String streakService_milestoneTitle(String emoji, String label) {
    return '$emoji $label';
  }

  @override
  String streakService_60a570(Object arg1, Object localLabel) {
    return '$arg1 $localLabel';
  }

  @override
  String get donationService_donationReceivedTitle => 'تم وصول التبرع 💝';

  @override
  String donationService_youDonatedSeeds(String amount) {
    return 'لقد تبرعت ببذور $amount · جزاك الله خيرا.';
  }

  @override
  String streakService_60a570_60a570(Object arg1, Object localLabel) {
    return '$arg1 $localLabel';
  }

  @override
  String xpService_badgeEarnedBody(String name) {
    return 'لقد حصلت على الشارة \"$name\".';
  }

  @override
  String get localReminderScheduler_channelName => 'إشعارات مكافآت سابق';

  @override
  String get localReminderScheduler_morningTitle => 'أذكار الصباح';

  @override
  String get localReminderScheduler_morningBody =>
      'ابدأ يومك في ذمة الله بقراءة أذكار الصباح.';

  @override
  String get localReminderScheduler_astaghfirTitle => 'لحظة للإستغفار';

  @override
  String get localReminderScheduler_astaghfirBody =>
      '\"استغفار الله\" يصقل القلب ويفتح أبواب الرزق. توقف لمدة دقيقة واحدة.';

  @override
  String get localReminderScheduler_eveningTitle => 'أذكار المساء';

  @override
  String get localReminderScheduler_eveningBody =>
      'احفظ نفسك ليلاً بقراءة أذكار المساء.';

  @override
  String get localReminderScheduler_sleepTitle => 'الوقت لتهدئة';

  @override
  String get localReminderScheduler_sleepBody =>
      'اختم يومك بأذكار النوم - آية الكرسي، والقول الثلاثة، وأدعية النوم.';

  @override
  String get localReminderScheduler_kahfAmTitle =>
      'إنه يوم الجمعة - إقرأ سورة الكهف';

  @override
  String get localReminderScheduler_kahfBody =>
      'من قرأ سورة الكهف في يوم الجمعة أضاء له من النور ما بين الجمعتين.';

  @override
  String get localReminderScheduler_salawatTitle => 'صلوات يوم الجمعة';

  @override
  String get localReminderScheduler_salawatBody =>
      'صلوا على النبي ﷺ اليوم أكثروا من الصلاة عليه، فإن أعمال يوم الجمعة تعرض عليه.';

  @override
  String get localReminderScheduler_kahfPmTitle => 'لا تفوتوا سورة الكهف اليوم';

  @override
  String get localReminderScheduler_kahfPmBody =>
      'ساعات قليلة تفصلنا عن المغرب – أكمل سورة الكهف إذا لم تكن قد أكملت ذلك بعد.';

  @override
  String get liveNotificationService_validateChannelDesc =>
      'تذكيرات لإغلاق بذورك المعلقة قبل منتصف الليل.';

  @override
  String get liveNotificationService_validateTicker =>
      'ختم البذور الخاصة بك قبل منتصف الليل';

  @override
  String get liveNotificationService_validateTitle =>
      'ختم البذور الخاصة بك قبل منتصف الليل!';

  @override
  String liveNotificationService_validateBody(String n) {
    return 'لديك $n بذور معلقة. اضغط على ختم اليوم قبل منتصف الليل أو تنتهي صلاحيته.';
  }

  @override
  String liveNotificationService_ayatRead(String n) {
    return '$n آيات إقرأها اليوم 📖';
  }

  @override
  String liveNotificationService_readQuranTime(String time) {
    return '$time إقرأ القرآن اليوم ⏱️';
  }

  @override
  String get liveNotificationService_nothingRead =>
      'لا شيء يقرأ من القرآن اليوم 📖';

  @override
  String liveNotificationService_dhikrCompleted(String n) {
    return '$n تم الانتهاء من الأذكار اليوم 📿';
  }

  @override
  String liveNotificationService_tickerBusy(String ayah, String dhikr) {
    return '$ayah آيات · $dhikr أذكار اليوم';
  }

  @override
  String get liveNotificationService_tickerIdle =>
      'استمر في القراءة والقيام بالذكر!';

  @override
  String get liveNotificationService_channelDesc =>
      'يعيش اليوم تقدم القرآن والذكر';

  @override
  String get liveNotificationService_seedsToday => 'بذورك اليوم ✨';

  @override
  String get liveNotificationService_summary => 'انقر لفتح سابق';

  @override
  String get quranApiService_notConnected => 'غير متصل بموقع القرآن الكريم';

  @override
  String get quranApiService_notSignedIn => 'لم يتم تسجيل الدخول إلى نور';

  @override
  String quranApiService_syncFailedPush(String n) {
    return 'فشلت المزامنة، تعذر دفع الإشارة (الإشارات) المرجعية $n إلى موقع Quran.com (التحقق من الرمز المميز / نقطة النهاية).';
  }

  @override
  String get quranApiService_alreadyInSync =>
      'الإشارات المرجعية متزامنة بالفعل';

  @override
  String quranApiService_syncedBookmarks(String total, String up, String down) {
    return 'الإشارات المرجعية $total المتزامنة ($up لأعلى، $down لأسفل)';
  }

  @override
  String quranApiService_syncFailedPartial(String n) {
    return '، $n فشل';
  }

  @override
  String quranApiService_syncFailedGeneric(String error) {
    return 'فشلت المزامنة: $error';
  }

  @override
  String get authScreen_dontHaveAnAccountSignUp => 'ليس لديك حساب؟ اشتراك';

  @override
  String get dhikrExitCelebration_keepItUp => 'استمر!';

  @override
  String get unknownError => 'خطأ غير معروف';

  @override
  String get celebrationStatSeeds => 'بذور';

  @override
  String get celebrationStatSeedsEarned => 'البذور المكتسبة';

  @override
  String get celebrationStatAyahs => 'آيات';

  @override
  String get celebrationStatTime => 'وقت';

  @override
  String get celebrationStatStreak => 'أثَر';

  @override
  String get celebrationStreakStartToday => 'ابدأ اليوم';

  @override
  String celebrationDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }
}
