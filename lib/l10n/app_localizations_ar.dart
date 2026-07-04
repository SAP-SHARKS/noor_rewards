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
  String get authScreen_pleaseEnterYourEmail =>
      'الرجاء إدخال البريد الإلكتروني الخاص بك';

  @override
  String get authScreen_pleaseEnterYourPassword =>
      'الرجاء إدخال كلمة المرور الخاصة بك';

  @override
  String get authScreen_passwordMustBeAt =>
      'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';

  @override
  String get authScreen_alreadyHaveAnAccount =>
      'هل لديك حساب بالفعل؟ تسجيل الدخول';

  @override
  String get authScreen_haveAnAccountSign => 'ليس لديك حساب؟ اشتراك';

  @override
  String qfAuthService_qfemailconflictexceptionAlreadyHasAn(String email) {
    return 'QfEmailConflictException: $email لديه حساب بالفعل';
  }

  @override
  String get qfAuthService_openidOfflineAccessUser =>
      'openid دون اتصال_الوصول إلى مجموعة الإشارات المرجعية للمستخدم read_session';

  @override
  String qfAuthService_tokenExchangeFailed(String arg1, String arg2) {
    return 'فشل تبادل الرمز المميز ($arg1): $arg2';
  }

  @override
  String get qfAuthService_errorNullResponse => 'خطأ: استجابة فارغة';

  @override
  String orphan_be2bf7(String firstName, String lastInitial) {
    return '$firstName $lastInitial.';
  }

  @override
  String get akhirahBalanceScreen_subhanallahiWaBiHamdihi =>
      '\"\"سبحان الله وبحمده\"\" في اليوم 100 مرة تمحو الخطايا مثل زبد البحر. (البخاري)';

  @override
  String get akhirahBalanceScreen_sayLaIlahaIllallah =>
      'وقول لا إله إلا الله 100 مرة تعدل عتق 10 عبيد و100 حسنة. (البخاري)';

  @override
  String get akhirahBalanceScreen_lightOnTheTongue =>
      'خفيف على اللسان، ثقيل في الميزان: سبحان الله وبحمده، سبحان الله العظيم. (البخاري 6406) .';

  @override
  String get akhirahBalanceScreen_theDhikrOfAllah =>
      'فإن ذكر الله أثقل في الميزان من ذهب مثله. يستمر في التقدم.';

  @override
  String get akhirahBalanceScreen_yourTongueShouldStay =>
      '«وينبغي أن يظل لسانك رطبًا بذكر الله». - هل لا تزال رطبة؟';

  @override
  String get akhirahBalanceScreen_astaghfirullahTheProphetSaid =>
      'استغفر الله — قالها النبي ✍ في اليوم 100 مرة، ولم يكن له ذنب. كم لديك؟';

  @override
  String get akhirahBalanceScreen_whenYouRememberAllah =>
      'وإذا ذكرتم الله خفية ذكركم في ملأ أكبر.';

  @override
  String get akhirahBalanceScreen_reciteAyatAlKursi =>
      'اقرأ آية الكرسي بعد كل صلاة، فلا يمنعك من الجنة إلا الموت.';

  @override
  String get akhirahBalanceScreen_oneAlhamdulillahFillsThe =>
      'الحمدلله يملأ الميزان . سبحان الله ملء ما بين السماء والأرض.';

  @override
  String get akhirahBalanceScreen_theRemembranceOfAllah =>
      '«ذكر الله أكبر من كل شيء». — سورة العنكبوت 29:45';

  @override
  String get akhirahBalanceScreen_rememberMeWillRemember =>
      '\" فاذكروني أذكركم \". - سورة البقرة 2: 152. سوف تفعل؟';

  @override
  String get akhirahBalanceScreen_inTheRemembranceOf =>
      '«بذكر الله تطمئن القلوب». — سورة الرعد 13:28';

  @override
  String get akhirahBalanceScreen_fiveMinutesOfDhikr =>
      'خمس دقائق من الذكر تشكل الآن الـ 24 ساعة القادمة من قلبك.';

  @override
  String get akhirahBalanceScreen_streakIsnAboutToday =>
      'لا يتعلق الخط باليوم، بل يتعلق بما ستصبح عليه خلال 30 يومًا.';

  @override
  String get akhirahBalanceScreen_smallDropsFillAn =>
      'قطرات صغيرة تملأ المحيط. أذكارك اليومية تملأ شيئًا أكبر بكثير.';

  @override
  String get akhirahBalanceScreen_noOneSeesThe =>
      'لا أحد يرى الذكر في قلبك، ولكن كل ملاك يكتب سجلك يفعل ذلك.';

  @override
  String get akhirahBalanceScreen_theBiggestWinsAre =>
      'أعظم المكاسب تبنى من أصغر العادات اليومية. لا تكسر السلسلة.';

  @override
  String get akhirahBalanceScreen_youCameBackToday =>
      'لقد عدت اليوم. هذه عبادة بالفعل. البقاء دقيقة واحدة أخرى؟';

  @override
  String get akhirahBalanceScreen_tomorrowPeaceIsBuilt =>
      'فسلام الغد مبني على ذكرى اليوم. زرع بذرة أخرى.';

  @override
  String get akhirahBalanceScreen_areYouDoneAllah =>
      'هل انتهيت؟ باب الله مفتوح دائما، حتى بعد أن تغلقه.';

  @override
  String get akhirahBalanceScreen_dhikrIsTheLanguage =>
      'الذكر هو لغة القلب. هل كلمت ربها اليوم؟';

  @override
  String get akhirahBalanceScreen_everySubhanallahIsSadaqah =>
      'وكل سبحان الله صدقة. كم ستعطي قبل النوم؟';

  @override
  String get akhirahBalanceScreen_heartThatForgetsDhikr =>
      'القلب الذي ينسى الذكر يبدأ بالصدأ. القلب الذي يتذكر يبقى مشتعلا.';

  @override
  String get akhirahBalanceScreen_haveYouFortifiedYourself =>
      'هل حصنت نفسك بأذكار الصباح والمساء اليوم؟';

  @override
  String akhirahBalanceScreen_thisSession(String arg1) {
    return 'هذه الجلسة: +$arg1';
  }

  @override
  String akhirahBalanceScreen_seedsThisSession(String arg1) {
    return '+$arg1 بذور هذه الجلسة';
  }

  @override
  String akhirahBalanceScreen_dayAvgAzkaarDay(String arg1) {
    return 'متوسط ​​7 أيام: $arg1 أذكار/يوم';
  }

  @override
  String dashboardScreen_profileReturnedZeroRows(String uid) {
    return 'لم يُرجع الملف الشخصي أي صفوف لـ $uid';
  }

  @override
  String dashboardScreen_dashboardLoadError(String e) {
    return 'خطأ في تحميل لوحة المعلومات: $e';
  }

  @override
  String get dashboardScreen_invalidReferralCode => 'رمز الإحالة غير صالح';

  @override
  String get dashboardScreen_cannotReferYourself => 'لا يمكن الرجوع نفسك';

  @override
  String dashboardScreen_sponsor(String name, String arg1) {
    return 'الراعي $name، $arg1';
  }

  @override
  String get dashboardScreen_dashboardDoesn => ': 0، // لوحة القيادة لا';

  @override
  String dashboardScreen_today(
    String arg1,
    String _lastAyah,
    String _ayahsToday,
  ) {
    return '$arg1 · $_lastAyah · +$_ayahsToday اليوم';
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
  String dashboardScreen_dayStreak(String arg1) {
    return '$arg1-خط يوم';
  }

  @override
  String dashboardScreen_last(String arg1) {
    return 'الأخير: $arg1';
  }

  @override
  String get dashboardScreen_earnPerFriend => 'اربح +500 لكل صديق';

  @override
  String get dashboardScreen_yourSabiqSeedsFund =>
      'تقوم شركة Sabiq Seeds الخاصة بكم بتمويل هذه المشاريع';

  @override
  String dashboardScreen_active(String arg1) {
    return '$arg1 نشط';
  }

  @override
  String get dashboardScreen_joinMeOnSabiq =>
      'انضم إلي في برنامج Sabiq Rewards واحصل على بذور القرآن والذكر والأعمال الصالحة يوميًا!\\n\\n';

  @override
  String dashboardScreen_useMyCodeAnd(String arg1) {
    return 'استخدم الرمز الخاص بي *$arg1* وسنحصل على 500 بذرة سابق!\\n\\n';
  }

  @override
  String get dashboardScreen_messageCopiedShareOr =>
      'تم نسخ الرسالة أو مشاركتها أو لصقها في WhatsApp!';

  @override
  String get dashboardScreen_sabiqSeedsRewardedTo =>
      '500 بذرة سابق مكافأة لكما!';

  @override
  String get dashboardScreen_youHaveAlreadyUsed =>
      'لقد استخدمت بالفعل رمز الإحالة.';

  @override
  String get dashboardScreen_invalidReferralCode_59fb25 =>
      'رمز الإحالة غير صالح.';

  @override
  String get dashboardScreen_youCannotUseYour =>
      'لا يمكنك استخدام الكود الخاص بك.';

  @override
  String get dashboardScreen_anErrorOccurredPlease =>
      'حدث خطأ. يرجى المحاولة مرة أخرى.';

  @override
  String dashboardScreen_52b02c(String pts) {
    return '$pts';
  }

  @override
  String dashboardScreen_e4e562(String arg1) {
    return '$arg1%';
  }

  @override
  String get dashboardScreen_seeDetailsForMore =>
      'انظر التفاصيل لمزيد من المشاريع →';

  @override
  String get dashboardScreen_yourTOTALSABIQSEEDS => 'مجموع بذور سابق الخاصة بك';

  @override
  String get dashboardScreen_viewCampaignDonate => '🤲 شاهد الحملة وتبرع';

  @override
  String dashboardScreen_yourRank(String rankText) {
    return 'رتبتك: $rankText';
  }

  @override
  String dashboardScreen_d13a42(String _myPoints, String unit, String arg1) {
    return '$_myPoints $unit • $arg1';
  }

  @override
  String get dashboardScreen_beTheFirstOn => 'كن الأول على اللوح';

  @override
  String get dashboardScreen_readAnAyahOr =>
      'اقرأ آية أو ذكر لتحصل على المركز الأول';

  @override
  String dashboardScreen_lvl(String level, String arg1) {
    return 'المستوى $level · $arg1';
  }

  @override
  String dashboardScreen_sealWithin(String arg1) {
    return 'الختم داخل ${arg1}h';
  }

  @override
  String get dashboardScreen_jazakallahDaySealed => 'جزاك الله!  يوم مختوم';

  @override
  String dashboardScreen_ofGoal(String arg1, String arg2) {
    return 'من $arg1 $arg2 هدف';
  }

  @override
  String get dhikrHubScreen_propheticSupplications => 'أدعية نبوية';

  @override
  String get dhikrHubScreen_morningEveningRemembrance => 'أذكار الصباح والمساء';

  @override
  String get dhikrHubScreen_furtherSupplications => 'مزيد من الأدعية';

  @override
  String get dhikrHubScreen_closingRemembranceSalawat => 'أذكار الختام والصلاة';

  @override
  String get dhikrHubScreen_hajjUmrahSupplications => 'أدعية الحج والعمرة';

  @override
  String get dhikrHubScreen_falseHiddenAdd => '] == خطأ) Hidden.add(r[';

  @override
  String get dhikrScreen_indoPak => 'إندو باك';

  @override
  String dhikrScreen_default(String recommendedCount) {
    return 'الافتراضي: $recommendedCount';
  }

  @override
  String get dhikrScreen_duaAzkarSettings => 'إعدادات الدعاء والأذكار';

  @override
  String get dhikrScreen_hideTheVisualArtwork =>
      'إخفاء منطقة العمل الفني المرئي';

  @override
  String get dhikrScreen_pinTheIllustrationAt =>
      'قم بتثبيت الرسم التوضيحي في الأعلى أثناء تمرير النص العربي أسفله';

  @override
  String dhikrScreen_readTimes(String readCount) {
    return 'اقرأ $readCount مرات';
  }

  @override
  String dhikrScreen_d08433(String arg1, String arg2) {
    return '$arg1 / $arg2';
  }

  @override
  String get dhikrScreen_alBaqarahAmanaAr => 'سورة البقرة 285 (أمانة الرسول)';

  @override
  String get dhikrScreen_alBaqarahAlifLam => 'سورة البقرة 1-5 (ألف لم ميم)';

  @override
  String get dhikrScreen_alBaqarahLaIkraha => 'البقرة 256 (لا إكراها)';

  @override
  String get dhikrScreen_alBaqarahAllahuWaliyy => 'سورة البقرة 257 (الله وليه)';

  @override
  String get dhikrScreen_salawatIbrahimiyyaDurood =>
      'الصلاة الإبراهيمية (الدرود)';

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
  String get dhikrScreen_hisnulMuslimChapter => 'حصن مسلم، باب:';

  @override
  String dhikrScreen_3856c1(String rawRef, String bottomRef) {
    return '$rawRef | $bottomRef';
  }

  @override
  String get dhikrScreen_bestOfBothWorlds => 'وخير الدارين العتق من النار';

  @override
  String get dhikrScreen_patienceAndSteadfastnessIn =>
      'الصبر والثبات في كل تجربة';

  @override
  String get dhikrScreen_allahBurdensNoSoul => 'ولا يكلف الله نفسا إلا وسعها';

  @override
  String get dhikrScreen_keepTheHeartFirm => 'ثبت القلب على الهدى';

  @override
  String get dhikrScreen_faithAnsweredWithForgiveness =>
      'أجاب الإيمان بالمغفرة من الجحيم';

  @override
  String get dhikrScreen_allSovereigntyInAllah => 'الملك كله في الله\\';

  @override
  String get dhikrScreen_allahHearsEveryCall =>
      'إن الله سميع لكل دعوة بالذرية الصالحة';

  @override
  String get dhikrScreen_countedWithTheWitnesses => 'محسوبا مع شهود الحق';

  @override
  String get dhikrScreen_forgivenessFirmFeetAnd =>
      'المغفرة والأقدام الثابتة والنصر';

  @override
  String get dhikrScreen_theDuaOfThose => 'دعاء الذين يتفكرون';

  @override
  String get dhikrScreen_inscribedWithTheWitnesses => 'مكتوب مع شهود الوحي';

  @override
  String get dhikrScreen_theDuaAllahAccepted => 'الدعاء المقبول من آدم ﷺ';

  @override
  String get dhikrScreen_spareUsTheCompany => 'وارزقنا صحبة الظالمين';

  @override
  String get dhikrScreen_neverTrialForThe => 'أبدا محاكمة للظالمين';

  @override
  String get dhikrScreen_refugeFromAskingWithout =>
      'أعوذ بالله من السؤال بغير علم';

  @override
  String get dhikrScreen_prayerForSafetyAnd => 'صلاة من أجل السلامة والإيمان';

  @override
  String get dhikrScreen_steadfastInPrayerMe => 'أقم الصلاة أنا وأولادي';

  @override
  String get dhikrScreen_mercyForMeMy => 'رحمة لي ولوالدي وللمؤمنين';

  @override
  String get dhikrScreen_prayerForParents => 'دعاء للوالدين';

  @override
  String get dhikrScreen_entryOfTruthExit => 'دخول الحقيقة، خروج الحقيقة';

  @override
  String get dhikrScreen_prayerOfTheYouth => 'دعاء شباب الكهف';

  @override
  String get dhikrScreen_askAllahForMore => 'اسأل الله المزيد من العلم';

  @override
  String get dhikrScreen_allahAnswersAndSaves => 'الله يجيب وينجي من كل ضيق';

  @override
  String get dhikrScreen_allahIsTheBest => 'والله خير الوارثين';

  @override
  String get dhikrScreen_blessedLandingWhereverYou => 'هبوط مبارك أينما توقفت';

  @override
  String get dhikrScreen_refugeFromTheWhispers => 'الاستعاذة من وساوس الشياطين';

  @override
  String get dhikrScreen_mercyFromTheBest => 'رحمة من خير الراحمين';

  @override
  String get dhikrScreen_pardonAndMercyFrom => 'عفواً ورحمة من الرحمن';

  @override
  String get dhikrScreen_piousSpousesAndRighteous =>
      'وأزواج صالحين وذرية صالحة';

  @override
  String get dhikrScreen_prayerForThoseWho => 'صلاة لمن تاب';

  @override
  String get dhikrScreen_gratitudeForParentsRighteousness =>
      'شكر الوالدين، والبر في النسل';

  @override
  String get dhikrScreen_pleaGiftOfIshaq => 'نداء - هدية إسحاق ﷺ';

  @override
  String get dhikrScreen_loveForTheBelievers => 'محبة المؤمنين الذين سبقونا';

  @override
  String get dhikrScreen_pureTawakkulOnYou => 'التوكل الخالص – عليك توكلنا';

  @override
  String get dhikrScreen_forgivenessForEveryBelieving => 'المغفرة لكل بيت مؤمن';

  @override
  String get dhikrScreen_tasbeehByTheWeight => 'التسبيح بثقل الله\\';

  @override
  String get dhikrScreen_tasbeehByTheNumber => 'التسبيح بعدد كل ما صنع';

  @override
  String get dhikrScreen_tasbeehThatFillsAll => 'التسبيح ملء كل ما خلق الله';

  @override
  String get dhikrScreen_paradiseSoughtTheFire => 'الجنة المطلوبة – النار\\';

  @override
  String get dhikrScreen_cryToTheOne => 'ابكي على من يسمع ويرى ويعلم';

  @override
  String get dhikrScreen_nameOnTheCorner => 'إسمه على زاوية الكعبة';

  @override
  String get dhikrScreen_theDuaBetweenYemen =>
      'الدعاء بين الركن اليماني والحجر الأسود';

  @override
  String get dhikrScreen_prayAtTheStation => 'الصلاة في مقام إبراهيم ﷺ';

  @override
  String get dhikrScreen_tawheedDeclaredAtopSafa =>
      'وأعلن التوحيد على الصفا والمروة';

  @override
  String get dhikrScreen_reaffirmTheOnenessOf => 'التأكيد على وحدانية الله';

  @override
  String get dhikrScreen_magnifyAllahAtEvery => 'سبحوا الله عند كل عتبة حج';

  @override
  String get dhikrScreen_magnifyAllahOnThe => 'سبحوا الله يوم النحر';

  @override
  String get dhikrScreen_knowledgeProvisionHealingSought =>
      'العلم والرزق والشفاء مطلوب في مكة';

  @override
  String get dhikrScreen_theDuaMostRepeated =>
      'أكثر دعاء ردده النبي صلى الله عليه وسلم';

  @override
  String get dhikrScreen_refugeFromEveryTrial => 'اهرب من كل تجربة حياة أو موت';

  @override
  String get dhikrScreen_refugeFromEveryWeakness =>
      'اعوذ بالله من كل ضعف في الجسد والروح';

  @override
  String get dhikrScreen_refugeFromSevereTrial =>
      'اعوذ بالله من شدة البلاء والعدو\\';

  @override
  String get dhikrScreen_religionSetRightWorld =>
      'أصلح الدين، وأصلح الدنيا والآخرة';

  @override
  String get dhikrScreen_guidancePietyVirtueSelf =>
      'الهداية والتقوى والفضيلة والاكتفاء بالنفس';

  @override
  String get dhikrScreen_refugeFromWeaknessWealth =>
      'اهرب من الضعف – ثروة التقوى في داخلك';

  @override
  String get dhikrScreen_theGuiderOfHearts => 'مرشد القلوب – حولنا إلى الطاعة';

  @override
  String get dhikrScreen_turnerOfHeartsMake => 'مقلب القلوب ثبتني على الدين';

  @override
  String get dhikrScreen_wellBeingInBoth => 'العافية في كلا العالمين';

  @override
  String get dhikrScreen_rewardsSaveFromDisgrace =>
      'الأجر والثواب من الخزي والقبر\\';

  @override
  String get dhikrScreen_mindForGoodVictory => 'العقل للخير، النصر للخير';

  @override
  String get dhikrScreen_refugeFromEvilOf => 'التعوذ من شر كل حس و جوارح';

  @override
  String get dhikrScreen_theForgiverWhoLoves => 'الغفور الذي يحب التائبين';

  @override
  String get dhikrScreen_takeMeBeforeYou => 'خذني قبل أن تضلني';

  @override
  String get dhikrScreen_everyGoodAndRefuge => 'من كل خير - و التعوذ من كل شر';

  @override
  String get dhikrScreen_standingSittingLyingGuarded =>
      'الوقوف والجلوس والكذب - حراسة في الإسلام';

  @override
  String get dhikrScreen_refugeFromCowardiceMiserliness =>
      'أعوذ بالله من الجبن والبخل والفتنة';

  @override
  String get dhikrScreen_forgivenessForJestAnd =>
      'العفو عن الهزل والجد، المعروف والمجهول';

  @override
  String get dhikrScreen_forgiveMeWithForgiveness => 'اغفر لي مغفرة من عندك';

  @override
  String get dhikrScreen_submissionBeliefRepentanceFull =>
      'التسليم، الإيمان، التوبة، الثقة الكاملة';

  @override
  String get dhikrScreen_mercyForgivenessParadiseSaved =>
      'الرحمة والمغفرة والجنة والنجاة من النار';

  @override
  String get dhikrScreen_refugeFromEvilSeen =>
      'أعوذ بالله من الشر ما يرى وما لا يرى';

  @override
  String get dhikrScreen_provisionThatLastsTill => 'رزق يدوم مدى الحياة\\';

  @override
  String get dhikrScreen_sinsForgivenHomeSpacious =>
      'الذنوب مغفورة، والدار فسيحة، والرزق مبارك';

  @override
  String get dhikrScreen_favorAndMercyNone =>
      'الفضل والرحمة لا يملكهما إلا أنت';

  @override
  String get dhikrScreen_refugeFromDrowningBurning =>
      'نجاة من الغرق والحرق والموت المفاجئ';

  @override
  String get dhikrScreen_refugeFromHypocrisyShowiness =>
      'اعوذ بالله من النفاق والتباهي والتمرد';

  @override
  String get dhikrScreen_refugeFromPovertyScarcity =>
      'اعوذ بالله من الفقر والقلة والقهر';

  @override
  String get dhikrScreen_refugeFromHeartThat => 'ملجأ من قلب فاز\\';

  @override
  String get dhikrScreen_payMyDebtEnrich => 'ادفع ديني وأغنيني من الفقر';

  @override
  String get dhikrScreen_allahCalledByHis => 'ودعا الله بأسمائه الحسنى';

  @override
  String get dhikrScreen_theAccepterOfRepentance => 'وقابل التوبة يقبل دائما';

  @override
  String get dhikrScreen_anEasyReckoningOn => 'الحساب اليسير يوم القيامة';

  @override
  String get dhikrScreen_remembranceGratitudeAndThe =>
      'والذكر والشكر وأفضل العبادة';

  @override
  String get dhikrScreen_eternalBlissWithThe =>
      'النعيم الدائم مع النبي صلى الله عليه وسلم في الفردوس';

  @override
  String get dhikrScreen_forgiveSinsKnownHidden =>
      'اغفر الذنوب ما علم منها وما خفي منها والمقصود منها والخطأ';

  @override
  String get dhikrScreen_refugeFromBeingCrushed =>
      'ملجأ من التعرض للسحق من قبل الديون والأعداء';

  @override
  String get dhikrScreen_askForParadiseRefuge => 'اطلب الجنة، والتعوذ من النار';

  @override
  String get dhikrScreen_forgiveGuideProvideProtect => 'يغفر، يرشد، يوفر، يحمي';

  @override
  String get dhikrScreen_sensesMadeBeneficialAnd =>
      'أصبحت الحواس مفيدة - ودائمة';

  @override
  String get dhikrScreen_theMostBeneficentThe => 'الرحمن، المنشئ للجميع';

  @override
  String get dhikrScreen_allahTruthOwnerOf => 'الله - الحق، مالك كل سلطان';

  @override
  String get dhikrScreen_submissionWithFullSincerity => 'التقديم بكل إخلاص';

  @override
  String get dhikrScreen_amongTheGuidedThe => 'من المهتدين الأصحاء المختارين';

  @override
  String get dhikrScreen_whatTheProphetAsked =>
      'ما سأله النبي صلى الله عليه وسلم - أنا أسأل أيضا';

  @override
  String get dhikrScreen_sayyidAlIstighfarThe =>
      'السيد الاستغفار – سيد التوبة كلها';

  @override
  String get dhikrScreen_refugeFromEveryEvil => 'تعوذ من كل شر يأتي بالليل';

  @override
  String get dhikrScreen_blessEverySenseEvery => 'بارك كل حاسة، وكل طرف';

  @override
  String get dhikrScreen_smallAndGreatFirst =>
      'الصغير والكبير، الأول والأخير، العلني والسري';

  @override
  String get dhikrScreen_noneWithholdsWhatYou =>
      'لا مانع لما أعطيت، ولا معطي لما أعطيت';

  @override
  String get dhikrScreen_forgiveGuideProvideElevate => 'يغفر، يهدي، يرزق، يرفع';

  @override
  String get dhikrScreen_increaseFavorBeKind =>
      'أكثر المعروف، وكن لطيفًا، ولا تسخط أبدًا';

  @override
  String get dhikrScreen_beautifyOurCharacterAs => 'وزين خلقنا كما حسنت خلقنا';

  @override
  String get dhikrScreen_firmInBeliefGuided =>
      'ثابتون على الإيمان – هادون ومرشدون';

  @override
  String get dhikrScreen_wisdomAndWithIt => 'الحكمة - ومعها الكثير من الخير';

  @override
  String get dhikrScreen_nameShieldsFromEvery => 'واسمه تحصين من كل مكروه';

  @override
  String get dhikrScreen_mightAgainstEveryShaytan => 'قوتها على كل شيطان';

  @override
  String get dhikrScreen_dayBlessedFromBeginning =>
      'يوم مبارك من أوله إلى آخره';

  @override
  String get dhikrScreen_witnessNoneDeservesWorship =>
      'إشهد - لا أحد يستحق العبادة إلا أنت';

  @override
  String get dhikrScreen_refugeFromHumiliatingOld =>
      'أعوذ بالله من الشيخوخة المهينة';

  @override
  String get dhikrScreen_guidedToTheBest => 'يرشد إلى الأفضل، ويحفظ من الأسوأ';

  @override
  String get dhikrScreen_faithSetRightHome =>
      'الإيمان ثابت، البيت واسع، الرزق مبارك';

  @override
  String get dhikrScreen_refugeFromEveryInner =>
      'اعوذ بك من كل داء باطني وظاهري';

  @override
  String get dhikrScreen_refugeFromEveryKind => 'اعوذ بالله من كل سوء خاتمة';

  @override
  String get dhikrScreen_steadfastGratefulRightlyGuided =>
      'قلبًا ثابتًا شاكرًا مسترشدًا';

  @override
  String get dhikrScreen_theLoveOfAllah => 'محبة الله وملائكته وأنبيائه';

  @override
  String get dhikrScreen_loveOfAllahAbove => 'حب الله فوق حب النفس';

  @override
  String get dhikrScreen_bestDeedsLastBest =>
      'وخير الأعمال تدوم – وخير يوم لقائك';

  @override
  String get dhikrScreen_pureLifeAndPeaceful => 'حياة نقية وعودة سلمية';

  @override
  String get dhikrScreen_patientGratefulSmallIn =>
      'صبور، ممتن، صغير في أعين نفسه';

  @override
  String get dhikrScreen_theBestRequestAnd => 'خير الطلب وخير الجزاء';

  @override
  String get dhikrScreen_theHighestLevelOf => 'أعلى درجات الجنة';

  @override
  String get dhikrScreen_firdawsTheBestOf => 'الفردوس — أفضل ذلك كله\\';

  @override
  String get dhikrScreen_mentionRaisedSinsErased =>
      'يُرفع الذكر، وتُمحى الذنوب، ويُطهر القلب';

  @override
  String get dhikrScreen_blessEverySenseEvery_b81b9b =>
      'بارك كل حاسة، وكل عضو، وكل عمل';

  @override
  String get dhikrScreen_mercyPleasureParadiseSaved =>
      'الرحمة والرضوان والجنة والنجاة من النار';

  @override
  String get dhikrScreen_noSinUncoveredNo =>
      'لا خطيئة مكشوفة، ولا دين غير مدفوع';

  @override
  String get dhikrScreen_mercyThatGuidesSets =>
      'الرحمة التي ترشد، وتصلح، وتطهر';

  @override
  String get dhikrScreen_trueBeliefCertainKnowledge =>
      'الإيمان الحق، العلم اليقين، الله\\';

  @override
  String get dhikrScreen_withTheProphetsThe => 'مع النبيين والشهداء والصديقين';

  @override
  String get dhikrScreen_everyNeedEntrustedTo =>
      'وكل حاجة موكولة إلى قاضي جميع الحاجات';

  @override
  String get dhikrScreen_bestOfWhatAllah => 'أفضل ما وعد الله عباده';

  @override
  String get dhikrScreen_safetyOnTheDay => 'السلامة يوم، والجنة يوم الخلود';

  @override
  String get dhikrScreen_glorifyTheOneOf =>
      'تمجيد ذو الشرف والعلم الذي لا مثيل له';

  @override
  String get dhikrScreen_pardonPlentySecurityIn =>
      'العفو، الكثير، الأمن في الدين والدنيا';

  @override
  String get dhikrScreen_healthFaithEthicsSuccess =>
      'الصحة، الإيمان، الأخلاق، النجاح، الرحمة';

  @override
  String get dhikrScreen_healthPurityEthicsAcceptance =>
      'الصحة، الطهارة، الأخلاق، القبول';

  @override
  String get dhikrScreen_guidedSecureVictorious => 'مهتدين، آمنين، منتصرين';

  @override
  String get dhikrScreen_refugeFromEveryCreature => 'أعوذ بالله من كل مخلوق\\';

  @override
  String get dhikrScreen_theOneWhoAnswers => 'هو الذي يجيب المضطر والمكسور';

  @override
  String get dhikrScreen_morningReachedByAllah => 'صباح بلغه الله\\';

  @override
  String get dhikrScreen_refugeSoughtByMusa => 'طلب اللجوء موسى وعيسى وإبراهيم';

  @override
  String get dhikrScreen_allTheGoodPower => 'كل الخير – القوة، الرحمة، البركات';

  @override
  String get dhikrScreen_allPraiseAndDominion => 'لك كل الحمد والسيادة';

  @override
  String get dhikrScreen_pastPardonedFutureProtected =>
      'الماضي عفواً، والمستقبل محمي';

  @override
  String get dhikrScreen_takeMyForelockTo => 'خذ بناصيتي إلى الخير';

  @override
  String get dhikrScreen_strengthForWeaknessDignity =>
      'القوة مقابل الضعف، والكرامة مقابل العار';

  @override
  String get dhikrScreen_justiceForThoseWho => 'العدالة لمن يحجب الحقيقة';

  @override
  String get dhikrScreen_refugeFromEveryFatal => 'اعوذ بالله من كل مصيبة قاتلة';

  @override
  String get dhikrScreen_refugeFromEveryBad =>
      'اعوذ بالله من كل سوء خاتمة وتجربة';

  @override
  String get dhikrScreen_turnBackEveryEvil => 'رد كل نية سيئة إلى مصدرها';

  @override
  String get dhikrScreen_justiceAndRefugeAgainst => 'العدل والنجاة من شرورهم';

  @override
  String get dhikrScreen_forgivenessForMeMy =>
      'اغفر لي ولوالدي ولجميع المؤمنين';

  @override
  String get dhikrScreen_purifyHeartDeedsTongue =>
      'طهارة القلب، والعمل، واللسان، والعين';

  @override
  String get dhikrScreen_selfContentWithAllah => 'الرضا عن الله\\';

  @override
  String get dhikrScreen_youKnowMySecret => 'أنت تعرف سرّي وحاجتي';

  @override
  String get dhikrScreen_certaintyNothingHarmsWhat => 'اليقين: لا شيء يضر ما\\';

  @override
  String get dhikrScreen_beliefLightAndLawful => 'الإيمان والنور والرزق الحلال';

  @override
  String get dhikrScreen_totalLoveAndTotal =>
      'الحب الكامل والنضال الكامل في سبيل الله';

  @override
  String get dhikrScreen_makeWhatYouWithheld => 'واجعل ما منعت قوة في الطاعة';

  @override
  String get dhikrScreen_praiseTheOwnerOf => 'سبحان صاحب كل إسم جميل';

  @override
  String get dhikrScreen_allahKnowsTheHearts =>
      'الله يعلم القلوب والسماء وما وراءها';

  @override
  String get dhikrScreen_hopeBuiltOnAllah => 'الأمل مبني على الله\\';

  @override
  String get dhikrScreen_belovedToTheBelievers =>
      'حبيب للمؤمنين، بريء من الأشرار';

  @override
  String get dhikrScreen_mightPowerAndMajesty => 'القوة والقوة والعظمة';

  @override
  String get dhikrScreen_gratefulPatientHelpfulTo =>
      'شاكراً صابراً مستعيناً بالله\\';

  @override
  String get dhikrScreen_withholdYourGoodFor => 'لا تمنع خيرك من أجل شري';

  @override
  String get dhikrScreen_settledLifeAmpleProvision =>
      'حياة مستقرة، ورزق واسع، وعمل صالح';

  @override
  String get dhikrScreen_wealthInNeedingYou =>
      'الثروة في الحاجة إليك - لا تتحرر منك أبدًا';

  @override
  String get dhikrScreen_defectsCoveredFearsCalmed =>
      'غطت العيوب، وهدأت المخاوف، وزال الكرب';

  @override
  String get dhikrScreen_openTheGatesOf => 'افتحوا أبواب الرحمة والكرم';

  @override
  String get dhikrScreen_holdUsInYour => 'احفظنا في أمانك – لا تتخلى عنا أبدًا';

  @override
  String get dhikrScreen_withinYourSecurityYour => 'في أمانك، صلاحك';

  @override
  String get dhikrScreen_everySinEveryDistress => 'كل خطيئة، كل ضيق، كل جانب';

  @override
  String get dhikrScreen_helpInDeathIn =>
      'استعانة بالموت، في القبر، على الصراط';

  @override
  String get dhikrScreen_beautifiedLifeBlessedGifts =>
      'حياة جميلة، عطايا مباركة، حفظة نعم';

  @override
  String get dhikrScreen_firmFootingBlessedEnd =>
      'قدم ثابتة، نهاية مباركة، حفظ العهد';

  @override
  String get dhikrScreen_hopesFulfilledEnemiesRepelled =>
      'تتحقق الآمال، ويصد الأعداء، وتصلح الأمور';

  @override
  String get dhikrScreen_guidedToTheUpright =>
      'هدى إلى المستقيمين، معصومين من النفس';

  @override
  String get dhikrScreen_lightAndForgivenessFrom => 'نور ومغفرة من ذي العرش';

  @override
  String get dhikrScreen_forgivenessForWhatRepented =>
      'المغفرة لما تبت ورجعت إليه';

  @override
  String get dhikrScreen_understandingThatDrawsNear => 'فهم يتقرب إلى الله';

  @override
  String get dhikrScreen_soulsDwellingInThe => 'نفوس ساكنة في أعالي التقوى';

  @override
  String get dhikrScreen_crossTheBridgeOf => 'اعبر جسر الرغبة بالصبر';

  @override
  String get dhikrScreen_followThePathOf => 'اتبع طريق الصدق واليقين';

  @override
  String get dhikrScreen_helpAgainstTheSoul => 'عون على النفس وضد الشيطان';

  @override
  String get dhikrScreen_fearHappinessVictorySecurity =>
      'الخوف، السعادة، النصر، الأمان';

  @override
  String get dhikrScreen_entrustFamilyWealthChildren =>
      'استودع الأسرة والثروة والأولاد - كل ذلك لله';

  @override
  String get dhikrScreen_faithGuardedFaithPreserved =>
      'الإيمان مصون، الإيمان محفوظ';

  @override
  String get dhikrScreen_wellBeingTillThe =>
      'العافية حتى النهاية - مختومة بالمغفرة';

  @override
  String get dhikrScreen_whatProtectsMeFrom => 'ما يحميني من هذا العالم\\';

  @override
  String get dhikrScreen_mercyOnEverySoul => 'رحمة لكل نفس\\';

  @override
  String get dhikrScreen_burdenUsAsThose =>
      'لا تثقل علينا كما ثقل الذين من قبل';

  @override
  String get dhikrScreen_mercyPardonForgivenessVictory =>
      'الرحمة، العفو، المغفرة، النصر';

  @override
  String get dhikrScreen_keepTheHeartFirm_9c4efb => 'ثبت القلب بعد الهدى';

  @override
  String get dhikrScreen_allahNeverFailsHis => 'إن الله لا يخلف وعده أبدا';

  @override
  String get dhikrScreen_faithAnsweredWithForgiveness_3f30c4 =>
      'أجاب الإيمان بالمغفرة من النار';

  @override
  String get dhikrScreen_recordUsWithThe => 'سجلنا مع شهود الحق';

  @override
  String get dhikrScreen_forgivenessFirmnessAndVictory => 'العفو والحزم والنصر';

  @override
  String get dhikrScreen_creationHasPurposeRefuge =>
      'الخلق له غرض - النجاة من النار';

  @override
  String get dhikrScreen_refugeFromTheDisgrace => 'التعوذ من خزي النار';

  @override
  String get dhikrScreen_heardBelievedAskingForgiveness =>
      'سمعت، صدقت، الاستغفار';

  @override
  String get dhikrScreen_sinsForgivenDeathAmong =>
      'مغفورة الخطايا - الموت بين الأبرار';

  @override
  String get dhikrScreen_promisedRewardNeverDisgraced =>
      'ووعد بالأجر فلا يخزى يوم القيامة';

  @override
  String get dhikrScreen_inscribedWithTheWitnesses_e2612d =>
      'مكتوب مع شهود الحق';

  @override
  String get dhikrScreen_provisionAndSignsFrom => 'رزق وآيات من السماء';

  @override
  String get dhikrScreen_duaTheDuaOf => 'دعاء - دعاء كل تائب';

  @override
  String get dhikrScreen_spareUsFromThe => 'نجنا من صحبة الظالمين';

  @override
  String get dhikrScreen_allahIsTheBest_4f2bf7 => 'والله أحكم بين الصدق والكذب';

  @override
  String get dhikrScreen_patienceTillTheEnd =>
      'الصبر حتى النهاية، والموت عند التسليم';

  @override
  String get dhikrScreen_neverTrialForThe_5eb10a => 'أبدا فتنة للكافرين';

  @override
  String get dhikrScreen_hiddenInEveryChest => 'مخبأة في كل صدر';

  @override
  String get dhikrScreen_prayerForPrayerAccepted => 'صلاة مقبولة الصلاة';

  @override
  String get dhikrScreen_mercyGrantedGuidancePrepared =>
      'الرحمة منحت، والتوجيه معد';

  @override
  String get dhikrScreen_duaBeforePharaoh => 'الدعاء أمام فرعون';

  @override
  String get dhikrScreen_refugeFromClingingEvil =>
      'اعوذ بالله من العذاب الخبيث';

  @override
  String get dhikrScreen_piousSpousesRighteousChildren =>
      'أزواج صالحون، أولاد صالحون، قيادة';

  @override
  String get dhikrScreen_allahIsEverThankful => 'والله الشكر دائمًا على كل جهد';

  @override
  String get dhikrScreen_mercyEncompassingEveryRepentant =>
      'الرحمة تشمل كل نفس تائبة';

  @override
  String get dhikrScreen_mercyOnThatDay => 'الرحمة يومئذ – الفوز العظيم';

  @override
  String get dhikrScreen_loveAndForgivenessFor =>
      'المحبة والغفران للمؤمنين السابقين';

  @override
  String get dhikrScreen_kindnessAndMercyUpon => 'اللطف والرحمة من الله\\';

  @override
  String get dhikrScreen_pureTawakkulToYou => 'التوكل الخالص - إليك راجعون';

  @override
  String get dhikrScreen_neverFitnahForThose => 'لا تكون فتنة للذين كفروا';

  @override
  String get dhikrScreen_completeTheLightForgive => 'أكمل النور – اغفر لنا';

  @override
  String get dhikrScreen_strongerThanServantThe => 'أقوى من خادم – الليل\\';

  @override
  String get dhikrScreen_refugeFromEveryVisible =>
      'التعوذ من كل شر ظاهرة قبل النوم';

  @override
  String get dhikrScreen_refugeFromEveryWhisper =>
      'اعوذ بك من كل همسة قبل النوم';

  @override
  String get dhikrScreen_guardedByAnAngel => 'يحرسه ملاك حتى الصباح';

  @override
  String get dhikrScreen_twoVersesThatSuffice => 'آيتان تكفيان ليلة كاملة';

  @override
  String get dhikrScreen_pureTawheedDeclaredBefore =>
      'أعلن التوحيد الخالص قبل النوم';

  @override
  String get dhikrScreen_sleepIsSmallDeath => 'النوم موت صغير في ذمة الله';

  @override
  String get dhikrScreen_whoeverDiesThatNight =>
      'ومن مات تلك الليلة مات على الفطرة';

  @override
  String get dhikrScreen_guardTheSoulThat => 'احفظ النفس التي تعود، أو ارحم';

  @override
  String get dhikrScreen_refugeFromThePunishment => 'نجاة من عذاب ذلك اليوم';

  @override
  String get dhikrScreen_gratitudeForShelterFood =>
      'الامتنان للمأوى والغذاء والرعاية';

  @override
  String get dhikrScreen_handOverTheSoul => 'تسليم الروح قبل النوم';

  @override
  String get dhikrScreen_refugeFromEveryEvil_6d2534 => 'أعوذ بك من كل شر يمسك';

  @override
  String get dhikrScreen_joinTheHighestAssembly =>
      'انضم إلى المجلس الأعلى أثناء نومك';

  @override
  String get dhikrScreen_gratitudeBeforeClosingThe => 'الشكر قبل أن تغمض عينيك';

  @override
  String get dhikrScreen_surahAsSajdahRecited => 'قراءة سورة السجدة قبل النوم';

  @override
  String get dhikrScreen_refugeFromEvilBefore =>
      'الاستعاذة من الشر قبل دخول الخلاء';

  @override
  String get dhikrScreen_seekForgivenessAsYou => 'استغفر وأنت تغادر';

  @override
  String get dhikrScreen_bismillahEveryBiteBegins =>
      'بسم الله - كل لقمة تبدأ بالله';

  @override
  String get dhikrScreen_catchUpTheName =>
      'اللحاق بالاسم – الله في البداية والنهاية';

  @override
  String get dhikrScreen_threeSunnahDuasTo => 'ثلاث أدعية لشكر الله بعد الأكل';

  @override
  String get dhikrScreen_beginWithAllahThe => 'ابدأ بالله الرحمن قبل الشرب';

  @override
  String get dhikrScreen_openTheEightDoors =>
      'افتح أبواب الجنة الثمانية بعد الوضوء';

  @override
  String get dhikrScreen_openTheDoorsOf => 'افتحوا أبواب الله\\';

  @override
  String get dhikrScreen_bountyAsYouLeave => 'فضله عند خروجك من المسجد';

  @override
  String get dhikrScreen_mayAllahGuideYou => 'الله يوفقك ويصلح حالك';

  @override
  String get dhikrScreen_askAllahLordOf => 'اسأل الله رب العرش أن يشفيه';

  @override
  String get dhikrScreen_allahIsTheOnly => 'الله وحده هو الذي يشفي';

  @override
  String get dhikrScreen_shieldChildrenWithAllah => 'حماية الأطفال مع الله\\';

  @override
  String get dhikrScreen_anicPrayerForOne => 'صلاة أنيك لأحد\\';

  @override
  String get dhikrScreen_twoPhrasesBelovedTo => 'كلمتان حبيبتان إلى الرحمن';

  @override
  String get dhikrScreen_allahLovesToPardon => 'إن الله يحب العفو فاسألوا';

  @override
  String get dhikrScreen_treasureFromBeneathThe => 'كنز من تحت العرش';

  @override
  String get dhikrScreen_theFourPhrasesDearest =>
      'العبارات الأربع أحب إلى الله';

  @override
  String get dhikrScreen_theDuaThatReleases => 'الدعاء الذي يفرج من كل ضيق';

  @override
  String get dhikrScreen_protectionForHomeAnd => 'حماية للبيت والذرية';

  @override
  String get dhikrScreen_theCompleteDhikrOf => 'اذكار التوحيد كاملة';

  @override
  String get dhikrScreen_trialPurifiedByAllah => 'محاكمة مطهرة من الله\\';

  @override
  String get dhikrScreen_guidanceBeforeAnyChoice => 'التوجيه قبل أي خيار';

  @override
  String get dhikrScreen_completeRuqyaSequenceFatihah =>
      'تسلسل الرقية كاملة – الفاتحة والمعوذتين';

  @override
  String get dhikrScreen_sinsForgivenEvenIf => 'تغفر الذنوب ولو مثل زبد البحر';

  @override
  String get dhikrScreen_freedHasanatSinsErased =>
      '10 محرومة · 100 حسنة · تمحى 100 خطيئة · طرد الشيطان';

  @override
  String get dhikrScreen_blessingsDescendFromAllah =>
      '10 بركات تنزل من الله عليك';

  @override
  String get dhikrScreen_askAllahToBless => 'اسأل الله أن يبارك يومك ويجمله';

  @override
  String get dhikrScreen_guaranteedJannahIfYou =>
      'وتضمن لك الجنة إذا مت في هذا اليوم';

  @override
  String get dhikrScreen_guaranteedJannahIfYou_48d274 =>
      'وتضمن لك الجنة إذا مت هذه الليلة';

  @override
  String get dhikrScreen_yourLifeEntrustedTo => 'حياتك مؤتمنة على الحي الدائم';

  @override
  String get dhikrScreen_allEvilInHis => 'يدفع عنك كل سوء في خلقه';

  @override
  String get dhikrScreen_nothingShallHarmYou => 'لن يضرك شيء بالكلمات المثالية';

  @override
  String get dhikrScreen_shieldYourselfFromMinor =>
      'احفظ نفسك من الشرك الأصغر والأكبر صباحاً ومساءً';

  @override
  String get dhikrScreen_completeProtectionInThe => 'الحماية الكاملة بسم الله';

  @override
  String get dhikrScreen_weightierThanAllVoluntary =>
      'أثقل من جميع صلاة التطوع من الفجر إلى المغرب';

  @override
  String get dhikrScreen_reciteMorningEveningEarn =>
      'أقرأها في الصباح والمساء تنال رضوان الله وبركاته يوم القيامة';

  @override
  String get dhikrScreen_yourRewardAwaitsDirectly =>
      'أجرك ينتظرك مباشرة عند الله عندما تقابله';

  @override
  String get dhikrScreen_reciteMorningEveningTo =>
      'أقرأ في الصباح والمساء لأداء واجب الشكر لله';

  @override
  String get dhikrScreen_theProphetTaughtThis =>
      'وقد علم النبي هذا الدعاء في الصباح والمساء فلا تفوته';

  @override
  String get dhikrScreen_dominionAtTheStart =>
      'الملك في أول صباحك، له الملك كله';

  @override
  String get dhikrScreen_asEveningFallsThe =>
      'ومع حلول المساء، يصبح الملك كله لله وحده';

  @override
  String get dhikrScreen_endYourEveningUpon =>
      'اختم أمسيتك على الفطرة الطاهرة كما علم النبي صلى الله عليه وسلم';

  @override
  String get dhikrScreen_satanWillNotEnter => 'لا يدخل الشيطان بيت من قرأ هذا';

  @override
  String get dhikrScreen_readingLastVersesOf =>
      'تكفيك قراءة آخر آيتين من سورة البقرة';

  @override
  String get dhikrScreen_everyDuaInThis =>
      'كل دعاء في هذه الآية - قال الله: قد فعلت';

  @override
  String get dhikrScreen_guardedByAllahUntil => 'في حراسة الله حتى يأتي الصباح';

  @override
  String get dhikrScreen_recitingEqualsReadingThe =>
      'القراءة 3x تعدل قراءة القرآن كاملا والبخاري ومسلم';

  @override
  String get dhikrScreen_reciteAtDawnDusk =>
      'وقل ثلاث مرات عند الفجر والمغرب تكفيك من كل سوء';

  @override
  String get dhikrScreen_reciteAtDawnDusk_f17fb8 =>
      'وقل ثلاث مرات عند الفجر والمغرب تكفيك من جميع النواحي';

  @override
  String get dhikrScreen_refugeFromTheWhisperer =>
      'اعوذ بالله من الوسواس برب الناس';

  @override
  String get dhikrScreen_reciteMorningEveningYour =>
      'وقل 3 مرات صباحا ومساءا يتم شكرك لله';

  @override
  String get dhikrScreen_sufficientAgainstEveryHarm =>
      'تكفي من كل ضرر تلاوة 3 مرات';

  @override
  String get dhikrScreen_doorsOfAllahMercy => 'أبواب رحمة الله مفتوحة لكم';

  @override
  String get dhikrScreen_worryAndSorrowLifted => 'يرفع الهم والحزن بإذن الله';

  @override
  String get dhikrScreen_guardedInYourDeen => 'تحرس في دينك الدنيا والآخرة';

  @override
  String get dhikrScreen_evilRepelledFromEvery => 'طارد الشر من كل جانب';

  @override
  String get dhikrScreen_heartHeldByThe =>
      'القلب الذي يحمله الحي الدائم الدائم';

  @override
  String get dhikrScreen_fulfilledYourObligationOf => 'أوفيت بواجب الشكر';

  @override
  String get dhikrScreen_recitingTheLastVerses =>
      'تكفيك قراءة آخر آيتين من سورة البقرة في الليل';

  @override
  String get dhikrScreen_gratitudeThatMultipliesYour => 'الشكر الذي يضاعف نعمك';

  @override
  String get dhikrScreen_startPureOnThe => 'ابدأوا خالصين على فطرة الإسلام';

  @override
  String get dhikrScreen_praiseThatRipplesThrough =>
      'التسبيح الذي يسري في كل الخليقة';

  @override
  String get dhikrScreen_guidedToEveryGood => 'هدى إلى كل خير في هذا اليوم';

  @override
  String get dhikrScreen_nothingShallHarmYou_8c5c6c => 'لن يضرك شيء باسمه';

  @override
  String get dhikrScreen_allahWillFreeHim =>
      'أعتقه الله من النار من قرأها 4 مرات';

  @override
  String get dhikrScreen_guaranteedJannahIfYou_0ffafe =>
      'وتضمن لك الجنة إذا مت اليوم';

  @override
  String get dhikrScreen_wellbeingOfBodyHearing =>
      'سلامة الجسم من السمع والبصر';

  @override
  String get dhikrScreen_guidedByTheHand => 'الهداية بيد الله';

  @override
  String get dhikrScreen_wordsHeavierThanThe => 'كلام أثقل من السماء والأرض';

  @override
  String get dhikrScreen_beginYourDayIn => 'ابدأ يومك بالاستسلام لله';

  @override
  String get dhikrScreen_theyAreEnoughFor => 'تكفيك - أقرأ قبل النوم';

  @override
  String get dhikrScreen_guardedInYourDeen_4a0b4a =>
      'تحفظ في دينك · الدنيا · الآخرة، ومن الجهات الستة';

  @override
  String get dhikrScreen_wellBeing => 'الرفاهية';

  @override
  String get dhikrScreen_fulfilled => 'تم الوفاء به.';

  @override
  String get dhikrScreen_wellBeingInFaith =>
      'الرفاهية في الإيمان · الأسرة · الثروة';

  @override
  String get dhikrScreen_concealMyFaultsCalm => 'أخفي عيوبي · هدئ مخاوفي';

  @override
  String get dhikrScreen_guardMeFromAll => 'احرسني من جميع الجهات الستة';

  @override
  String get dhikrScreen_protectionFromEvilEye => 'الحماية من العين الشريرة';

  @override
  String get dhikrScreen_doNotLeaveMe => 'فلا تكلني إلى نفسي طرفة عين';

  @override
  String dhikrScreen_35c165(String arg1) {
    return '$arg1';
  }

  @override
  String get dhikrScreen_allahWillSufficeYou => 'الله يكفيك';

  @override
  String get dhikrScreen_againstWhateverConcernsYou => 'ضد كل ما يقلقك';

  @override
  String get dhikrScreen_sinsWashedAway => 'غسلت الخطايا';

  @override
  String get dhikrScreen_slavesFreed => 'العبيد المحررين';

  @override
  String get dhikrScreen_doNotBurdenUs =>
      'ولا تحملنا ما لا طاقة لنا به واعف عنا وارحمنا';

  @override
  String get dhikrScreen_weHaveBelievedForgive =>
      'لقد آمنا فاغفر لنا ذنوبنا وقنا من النار';

  @override
  String get dhikrScreen_ownerOfSovereigntyIn =>
      'يا مالك الملك بيدك الخير إنك أنت القادر';

  @override
  String get dhikrScreen_forgiveOurSinsAnd =>
      'واغفر ذنوبنا وإسرافنا وثبتنا وانصرنا';

  @override
  String get dhikrScreen_youCreatedNotIn => 'ما خلقت عبثا فقنا عذاب النار';

  @override
  String get dhikrScreen_weHaveWrongedOurselves =>
      'لقد ظلمنا أنفسنا فمن دون رحمتك ضللنا';

  @override
  String get dhikrScreen_ourLordDoNot => 'ربنا لا تجعلنا مع القوم الظالمين';

  @override
  String get dhikrScreen_doNotMakeUs => 'ولا تجعلنا فتنة للظالمين';

  @override
  String get dhikrScreen_makeMeSteadfastIn => 'وأثبتني على الصلاة وذريتي أيضًا';

  @override
  String get dhikrScreen_forgiveMeMyParents =>
      'اغفر لي ولوالدي وللمؤمنين يوم الحساب';

  @override
  String get dhikrScreen_bringMeInBy =>
      'أدخلني من مدخل الحق وأخرجني من مخرج الحق';

  @override
  String get dhikrScreen_myLordIncreaseMe => 'ربي زدني علما';

  @override
  String get dhikrScreen_seekRefugeInYou => 'وأعوذ بك من همزات الشياطين';

  @override
  String get dhikrScreen_weHaveBelievedForgive_e958e6 =>
      'لقد آمنا فاغفر لنا وأنت خير الراحمين';

  @override
  String get dhikrScreen_forgiveAndHaveMercy => 'اغفر وارحم وأنت خير الراحمين';

  @override
  String get dhikrScreen_enableMeToBe => 'أوزعني أن أشكر نعمتك علي وعلى والدي';

  @override
  String get dhikrScreen_myLordHaveWronged => 'ربي إني ظلمت نفسي فاغفر لي';

  @override
  String get dhikrScreen_myLordWillNever => 'ربي لا أكون ظهيراً للمجرمين';

  @override
  String get dhikrScreen_myLordSaveMe => 'ربي نجني من القوم الظالمين';

  @override
  String get dhikrScreen_myLordAmIn => 'ربي إني محتاج إلى أي خير تنزله إلي';

  @override
  String get dhikrScreen_myLordHelpMe => 'ربي انصرني على القوم المفسدين';

  @override
  String get dhikrScreen_ourLordAvertFrom => 'ربنا اصرف عنا عذاب الجحيم';

  @override
  String get dhikrScreen_ourLordYouEncompass => 'ربنا وسعت كل شيء رحمة وعلما';

  @override
  String get dhikrScreen_enableMeToThank => 'أوزعني أن أشكرك وأصلح لي ذريتي';

  @override
  String get dhikrScreen_myLordGrantMe => 'ربي هب لي من الصالحين';

  @override
  String get dhikrScreen_forgiveUsAndOur =>
      'اغفر لنا ولإخواننا الذين سبقونا بالإيمان';

  @override
  String get dhikrScreen_uponYouWeRely =>
      'عليك توكلنا، وإليك أنبنا، وإليك المصير';

  @override
  String get dhikrScreen_pauseRememberAllah => 'يوقف. اذكروا الله .';

  @override
  String get dhikrScreen_mashaallahRewardSecured =>
      'ما شاء الله! المكافأة مضمونة';

  @override
  String get dhikrScreen_satanCannot => 'الشيطان لا يستطيع';

  @override
  String get dhikrScreen_enterTheHome => 'أدخل المنزل';

  @override
  String get dhikrScreen_whoeverRecites => 'من يقرأ';

  @override
  String get dhikrScreen_theLastTwoVerses => 'الآيتين الأخيرتين';

  @override
  String get dhikrScreen_ofSurahAlBaqarah => 'من سورة البقرة';

  @override
  String get dhikrScreen_atNight => 'في الليل --';

  @override
  String get dhikrScreen_theyWillBe => 'سيكونون كذلك';

  @override
  String get dhikrScreen_enoughForHim => 'يكفي له';

  @override
  String get dhikrScreen_weHaveEnteredThe => 'لقد دخلنا المساء';

  @override
  String get dhikrScreen_theKingdomBelongsTo => 'الملك لله';

  @override
  String get dhikrScreen_noneWorthyOfWorship =>
      'لا أحد يستحق العبادة إلا الله وحده';

  @override
  String get dhikrScreen_allPraiseHeIs => 'الحمد · إنه على كل شيء قدير';

  @override
  String get dhikrScreen_weAskForThe => 'نسألك خير هذه الليلة';

  @override
  String get dhikrScreen_saySeekRefuge => 'قل : أعوذ';

  @override
  String get dhikrScreen_inTheLordOf => 'في رب البشر';

  @override
  String get dhikrScreen_theKingOfMankind => 'ملك البشرية';

  @override
  String get dhikrScreen_theGodOfMankind => 'إله البشرية،';

  @override
  String get dhikrScreen_heRetreatsWhenYou => 'يتراجع عندما تذكر الله.';

  @override
  String get dhikrScreen_seekRefugeInThe => 'اعوذ برب الفلق';

  @override
  String get dhikrScreen_sufficedInAllRespects => 'يكفي من جميع النواحي.';

  @override
  String get dhikrScreen_allahDoesNotBurden => 'الله لا يثقل';

  @override
  String get dhikrScreen_soul => 'روح';

  @override
  String dhikrScreen_a5cfd1(String count) {
    return '×$count';
  }

  @override
  String get dhikrScreen_equalsTheWholeQuran => 'يساوي القرآن كله × 3';

  @override
  String get dhikrScreen_completeToWatchYour =>
      'اكتمل لمشاهدة حديقتك تزدهر بالأعلى';

  @override
  String get impactReportScreen_whoeverDoesAnAtom => '«من عمل ذرة';

  @override
  String get impactReportScreen_theHomeOfThe =>
      '«إن الدار الآخرة تلك هي الحياة الأبدية لو كانوا يعلمون». — سورة العنكبوت 29:64';

  @override
  String get impactReportScreen_raceTowardsForgivenessFrom =>
      '«سارعوا إلى مغفرة من ربكم وجنة عرضها السماوات والأرض». — سورة الحديد 57:21';

  @override
  String get impactReportScreen_andWhatIsThe =>
      '\"وما الحياة الدنيا إلا لعب الغرور؟\" - سورة علي عمران 3: 185';

  @override
  String get impactReportScreen_indeedWithHardshipComes =>
      '«إن مع العسر يسرا». — سورة الشرح 94:6';

  @override
  String get impactReportScreen_singleGoodDeedIn =>
      '«الحسنة في رمضان تعدل سبعين حسنة فيما سواه». كومة بينما الباب مفتوح.';

  @override
  String get impactReportScreen_theProphetSaidCharity =>
      'قال النبي ✍: ما نقصت الصدقة من مال إلا نبته. (مسلم)';

  @override
  String get impactReportScreen_smilingAtYourBrother =>
      '«تبسمك في وجه أخيك صدقة». يمكنك الربح حتى عندما تكون جيوبك فارغة. (الترمذي)';

  @override
  String get impactReportScreen_theMostBelovedDeeds =>
      '«أحب الأعمال إلى الله أدومها وإن قل». (البخاري)';

  @override
  String get impactReportScreen_inJannahIsWhat =>
      '\"في الجنة ما لا عين رأت، ولا أذن سمعت، ولا خطر على قلب بشر.\" (البخاري)';

  @override
  String get impactReportScreen_twoRakatsAtFajr =>
      'وركعتان الفجر خير من الدنيا وما فيها. (مسلم)';

  @override
  String get impactReportScreen_everyStepTowardSalah =>
      'وكل خطوة إلى الصلاة تمحو خطيئة وترفع درجة. (مسلم)';

  @override
  String get impactReportScreen_everySeedYouDonate =>
      'كل بذرة تتبرع بها تزرع شجرة في شخص آخر\\';

  @override
  String get impactReportScreen_takeWealthWithYou =>
      'لا تأخذ الثروة معك. فقط الأفعال التي اشتراها.';

  @override
  String get impactReportScreen_theAngelsRecordNothing =>
      'الملائكة لا يسجلون شيئًا صغيرًا جدًا. سبحان الله قد يفوق جبلاً.';

  @override
  String get impactReportScreen_sadaqahIsTomorrow => 'صدقة غدا\\';

  @override
  String get impactReportScreen_heartThatGivesIs =>
      'القلب الذي يعطي هو قلب يبقيه الله ممتلئا. اِتَّشَح\\';

  @override
  String get impactReportScreen_theReceiptWhatDid =>
      'هو الإيصال. ماذا أرسلت قدما؟';

  @override
  String get impactReportScreen_imagineYourScaleOn =>
      'تخيل ميزانك في يوم القيامة. ما الوزن الذي تضيفه اليوم؟';

  @override
  String get impactReportScreen_theWorldIsBorrowed =>
      'العالم مستعار. الآخرة مملوكة. استثمر وفقًا لذلك.';

  @override
  String get impactReportScreen_youBuryTheBody =>
      'أنت تدفن الجسد، ولكن ليس الأفعال. أرسلهم للأمام بينما تستطيع.';

  @override
  String get impactReportScreen_righteousChildWhoPrays =>
      'ولد صالح يدعو لك، أو صدقة تجري، أو علم ينتفع - ثلاث استثمارات خالدة. (مسلم)';

  @override
  String get impactReportScreen_youWillMeetAllah =>
      'ستقابل الله بسجلك. تأكد اليوم\\';

  @override
  String get impactReportScreen_noDeedIsToo => 'لا يستصغر عملاً من يعد الذرات.';

  @override
  String impactReportScreen_lvl(String _level, String arg1) {
    return 'المستوى $_level · $arg1';
  }

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
  String get impactReportScreen_whoeverDoesGoodDeed =>
      'من عمل الحسنة فله عشر أمثالها.';

  @override
  String get impactReportScreen_whoeverReadsLetterFrom =>
      'من قرأ حرفاً من كتاب الله فله حسنة، والحسنة بعشر أمثالها.';

  @override
  String get impactReportScreen_twoHadithGrowThis =>
      'حديثان يزيدان هذا العدد جنباً إلى جنب:\\n\\n';

  @override
  String impactReportScreen_dhikrRecitedLifetime(String arg1) {
    return 'الأذكار المرتلة (مدى الحياة): $arg1\\n';
  }

  @override
  String impactReportScreen_hasanat(String arg1) {
    return '→ حسنات: $arg1\\n\\n';
  }

  @override
  String impactReportScreen_ayahsReadLifetime(String arg1) {
    return 'قراءة الآيات (العمر): $arg1\\n';
  }

  @override
  String impactReportScreen_hasanat_e68a30(String arg1) {
    return '→ حسنات: $arg1\\n\\n';
  }

  @override
  String impactReportScreen_totalHasanaat(String arg1) {
    return 'مجموع الحسنات: $arg1';
  }

  @override
  String impactReportScreen_ayahs(String arg1) {
    return '$arg1 الآيات';
  }

  @override
  String get impactReportScreen_hasanatFromQuran => 'حسنات من القرآن';

  @override
  String impactReportScreen_planted(String arg1) {
    return '$arg1 مزروعة';
  }

  @override
  String get impactReportScreen_treesInJannah => 'أشجار في الجنة';

  @override
  String impactReportScreen_cycles(String arg1) {
    return '$arg1 دورات';
  }

  @override
  String get impactReportScreen_sinsForgiven => 'مغفورة الذنوب';

  @override
  String get impactReportScreen_whoeverSaysSubhanAllahiWa =>
      'من قال سبحان الله وبحمده في يوم 100 مرة غفرت ذنوبه ولو كانت مثل زبد البحر.';

  @override
  String get impactReportScreen_subhanallahiWaBihamdihi => 'سبحان الله وبحمده';

  @override
  String impactReportScreen_totalRecitations(String arg1) {
    return 'مجموع التلاوات: $arg1\\n';
  }

  @override
  String impactReportScreen_dividedByForgivenessCycles(String arg1) {
    return 'مقسومًا على 100 ← دورات الغفران: $arg1';
  }

  @override
  String impactReportScreen_built(String arg1) {
    return '$arg1 بنيت';
  }

  @override
  String get impactReportScreen_palacesBuilt => 'بنيت القصور';

  @override
  String impactReportScreen_dividedByPalaces(String arg1) {
    return 'مقسمة على 10 → القصور: $arg1';
  }

  @override
  String impactReportScreen_earned(String arg1) {
    return '$arg1 حصل';
  }

  @override
  String get impactReportScreen_treasuresOfJannah => 'كنوز الجنة';

  @override
  String impactReportScreen_equivalent(String arg1) {
    return '$arg1 يعادل';
  }

  @override
  String get impactReportScreen_slavesFreed => 'العبيد المحررين';

  @override
  String get impactReportScreen_laIlahaIllallahuWahdahu =>
      'لا إله إلا الله وحده لا شريك له...';

  @override
  String impactReportScreen_totalRecitations_262e54(String arg1) {
    return 'مجموع التلاوات: $arg1\\n';
  }

  @override
  String impactReportScreen_setsOfSetsSlaves(String arg1, String arg2) {
    return 'مجموعات من 10 → $arg1 مجموعات × 4 عبيد = $arg2';
  }

  @override
  String impactReportScreen_opened(String arg1) {
    return '$arg1 مفتوح';
  }

  @override
  String get impactReportScreen_gatesOfParadiseOpened => 'فتحت أبواب الجنة';

  @override
  String impactReportScreen_received(String arg1) {
    return 'تم استلام $arg1';
  }

  @override
  String get impactReportScreen_blessingsFromAllah => 'بركات من الله';

  @override
  String impactReportScreen_totalSalawatSent(String arg1) {
    return 'إجمالي الصلوات المرسلة: $arg1\\n';
  }

  @override
  String impactReportScreen_multipliedByBlessingsReceived(String arg1) {
    return 'مضروبة في 10 → $arg1 النعم المستلمة';
  }

  @override
  String impactReportScreen_invocations(String arg1) {
    return '$arg1 الدعوات';
  }

  @override
  String get impactReportScreen_timesProtected => 'الأوقات المحمية';

  @override
  String get impactReportScreen_protectionFromEvil => 'الحماية من الشر';

  @override
  String get impactReportScreen_goodHealthProtection => 'صحة جيدة وحماية';

  @override
  String impactReportScreen_totalInvocations(String arg1) {
    return 'إجمالي الدعوات: $arg1';
  }

  @override
  String impactReportScreen_equivalent_d7e6f6(String arg1) {
    return '$arg1 يعادل';
  }

  @override
  String get impactReportScreen_quranCompletions => 'ختمات القرآن';

  @override
  String impactReportScreen_dividedByQuranCompletions(String arg1) {
    return 'مقسمة على 3 → $arg1 ختمات القرآن';
  }

  @override
  String impactReportScreen_recitations(String arg1) {
    return '$arg1 تلاوات';
  }

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
  String impactReportScreen_ago(String arg1) {
    return '$arg1م مضت';
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
  String impactReportScreen_moAgo(String arg1) {
    return '$arg1 منذ شهر';
  }

  @override
  String impactReportScreen_ago_65f0ec(String arg1) {
    return '${arg1}y منذ';
  }

  @override
  String impactReportScreen_viewAllDonors(String arg1) {
    return 'عرض جميع الجهات المانحة $arg1';
  }

  @override
  String impactReportScreen_failed(String e) {
    return 'فشل: $e';
  }

  @override
  String impactReportScreen_meet(String arg1, String arg2) {
    return 'تعرف على $arg1، $arg2';
  }

  @override
  String impactReportScreen_sponsor(String arg1) {
    return 'الراعي $arg1 →';
  }

  @override
  String impactReportScreen_funded(String arg1) {
    return '$arg1% ممولة';
  }

  @override
  String get impactReportScreen_yourLifetimeImpact => 'تأثير حياتك';

  @override
  String get impactReportScreen_startYourImpactJourney =>
      'ابدأ رحلة التأثير الخاصة بك';

  @override
  String impactReportScreen_bd3721(String _myOrphansSponsoredCount) {
    return '$_myOrphansSponsoredCount';
  }

  @override
  String impactReportScreen_b3d969(String _myProjectsSupportedCount) {
    return '$_myProjectsSupportedCount';
  }

  @override
  String get levelScreen_customProfileThemes => 'موضوعات الملف الشخصي المخصصة';

  @override
  String get levelScreen_exclusiveVotingRights => 'حقوق التصويت الحصرية';

  @override
  String get levelScreen_hallOfFameListing => 'قائمة قاعة المشاهير';

  @override
  String levelScreen_seeds(String arg1) {
    return '+$arg1 البذور';
  }

  @override
  String get levelScreen_laIlahaIllallah => 'لا إله إلا الله x100';

  @override
  String levelScreen_seeds_59c6a1(String arg1) {
    return '+$arg1 البذور';
  }

  @override
  String levelScreen_seeds_a20530(String arg1) {
    return '+$arg1 البذور';
  }

  @override
  String levelScreen_unlocks(String arg1) {
    return 'يفتح: $arg1';
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
  String levelScreen_seedsBoost(String arg1) {
    return '$arg1× تعزيز البذور';
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
  String levelScreen_nextDays(String arg1, String arg2) {
    return 'التالي: $arg1 ($arg2 أيام)';
  }

  @override
  String levelScreen_seeds_990893(String arg1) {
    return '+$arg1 البذور';
  }

  @override
  String levelScreen_days(String current, String arg1) {
    return '$current / $arg1 أيام';
  }

  @override
  String levelScreen_dayStreak(String arg1) {
    return '$arg1 خط يوم';
  }

  @override
  String get phase1Screens_inTheNameOf => 'بسم الله الرحمن…';

  @override
  String get phase1Screens_quranReadingNimage => 'قراءة القرآن\\nصورة';

  @override
  String get phase1Screens_orphansNimage => 'الصورة اليتيمة\\n';

  @override
  String onboardingComponents_355c50(String first) {
    return '$first';
  }

  @override
  String onboardingComponents_b236c9(String trailing) {
    return '$trailing';
  }

  @override
  String get quranMini_inTheNameOf => 'بسم الله الرحمن الرحيم.';

  @override
  String get quranMini_allPraiseBelongsTo => 'والحمد لله رب العالمين.';

  @override
  String orphansGridScreen_36cd3b(String arg1, String arg2) {
    return '$arg1 · $arg2';
  }

  @override
  String orphanDetailScreen_years(String arg1) {
    return '$arg1 سنة';
  }

  @override
  String orphanDetailScreen_ofSeeds(String arg1, String arg2) {
    return '$arg1 من $arg2 البذور';
  }

  @override
  String orphanDetailScreen_through(String arg1) {
    return 'من خلال $arg1';
  }

  @override
  String get orphanDetailScreen_andTheyGiveFood =>
      'ويطعمون الطعام على حبهم له مسكينا ويتيما وأسيرا.';

  @override
  String orphanDetailScreen_ago(String arg1) {
    return '$arg1م مضت';
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
  String orphanDetailScreen_moAgo(String arg1) {
    return '$arg1 منذ شهر';
  }

  @override
  String orphanDetailScreen_ago_65f0ec(String arg1) {
    return '${arg1}y منذ';
  }

  @override
  String orphanDetailScreen_seeds(String _availablePoints) {
    return '$_availablePoints بذور';
  }

  @override
  String orphanDetailScreen_sponsor(String arg1) {
    return 'الراعي $arg1';
  }

  @override
  String orphanDetailScreen_jazakallahKhayranSeedsSponsored(String amount) {
    return 'جزاك الله خيران! $amount البذور برعاية.';
  }

  @override
  String orphanDetailScreen_chooseHowManySeeds(String arg1) {
    return 'اختر عدد البذور التي تريد تقديمها. الحد الأدنى $arg1.';
  }

  @override
  String orphanDetailScreen_yourBalanceSeeds(String arg1) {
    return 'رصيدك: $arg1 بذور';
  }

  @override
  String get profileSettingsScreen_nameCannotBeEmpty =>
      'لا يمكن أن يكون الاسم فارغًا';

  @override
  String get profileSettingsScreen_sabiqRewards => 'مكافآت سابق • v1.0';

  @override
  String get profileSettingsScreen_bosniaAndHerzegovina => 'البوسنة والهرسك';

  @override
  String get profileSettingsScreen_centralAfricanRepublic =>
      'جمهورية أفريقيا الوسطى';

  @override
  String get profileSettingsScreen_unitedArabEmirates =>
      'الإمارات العربية المتحدة';

  @override
  String get profileSettingsScreen_signedInWithGoogle =>
      'تم تسجيل الدخول باستخدام جوجل';

  @override
  String get profileSettingsScreen_signedInWithQuran =>
      'تم التسجيل في موقع القرآن الكريم';

  @override
  String get profileSettingsScreen_signedInWithEmail =>
      'تم تسجيل الدخول باستخدام البريد الإلكتروني';

  @override
  String profileSettingsScreen_seeds(String arg1) {
    return '$arg1 بذور';
  }

  @override
  String profileSettingsScreen_seeds_59ba7c(String arg1) {
    return '$arg1 بذور';
  }

  @override
  String profileSettingsScreen_seeds_2bc978(String arg1) {
    return '$arg1 بذور';
  }

  @override
  String get profileSettingsScreen_guidesFAQsAndHow =>
      'الأدلة والأسئلة الشائعة والكيفية';

  @override
  String get profileSettingsScreen_somethingNotWorkingTell =>
      'شيء لا يعمل؟ أخبرنا';

  @override
  String get profileSetupScreen_ahmadFatimaYusuf => 'أحمد، فاطمة، يوسف...';

  @override
  String get profileSetupScreen_pakistanEgyptMalaysia =>
      'باكستان، مصر، ماليزيا...';

  @override
  String projectDetailScreen_organisedBy(String sponsor) {
    return 'تم التنظيم بواسطة $sponsor\\n\\n';
  }

  @override
  String get projectDetailScreen_fundedSoFarEvery =>
      'تم تمويل كل بذرة حتى الآن!\\n\\n';

  @override
  String get projectDetailScreen_openSabiqRewardsApp =>
      'افتح تطبيق Sabiq Rewards للتبرع ببذورك والحصول على المكافأة.\\n';

  @override
  String get projectDetailScreen_sabiqrewardsSadaqahIslamicCharity =>
      '#مكافآت سابق #صدقة #الجمعية الخيرية الإسلامية';

  @override
  String projectDetailScreen_4c2b09(String arg1, String arg2, String arg3) {
    return '$arg1 $arg2 $arg3';
  }

  @override
  String get projectDetailScreen_donateToProvideUrgent =>
      'تبرع لتقديم مساعدات عاجلة ومنقذة للحياة للفلسطينيين الذين يعانون من نقص حاد في الغذاء والمياه والإمدادات الطبية...';

  @override
  String projectDetailScreen_seeds(String arg1) {
    return '$arg1 بذور';
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
  String projectDetailScreen_ago(String arg1) {
    return '$arg1م مضت';
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
  String projectDetailScreen_moAgo(String arg1) {
    return '$arg1 منذ شهر';
  }

  @override
  String projectDetailScreen_ago_65f0ec(String arg1) {
    return '${arg1}y منذ';
  }

  @override
  String projectDetailScreen_viewAll(String arg1) {
    return 'عرض الكل $arg1 →';
  }

  @override
  String quranHubScreen_saved(String arg1) {
    return 'تم حفظ $arg1';
  }

  @override
  String get quranHubScreen_tapTheHeartBookmark =>
      'اضغط على أيقونة القلب/الإشارة المرجعية أثناء القراءة لحفظ الآيات.';

  @override
  String quranHubScreen_surahVerse(String s, String a) {
    return 'سورة __ص0__ • الآية __ص1__';
  }

  @override
  String get quranHubScreen_loadingQuran => 'جاري تحميل القرآن...';

  @override
  String quranHubScreen_verses(String arg1) {
    return '$arg1 الآيات';
  }

  @override
  String quranHubScreen_of(String arg1) {
    return 'من $arg1';
  }

  @override
  String quranHubScreen_saved_edce53(String arg1) {
    return 'تم حفظ $arg1';
  }

  @override
  String get quranScreen_englishSahihIntl => 'الإنجليزية، صحيح الدولي.';

  @override
  String get quranScreen_saheehInternational => 'صحيح الدولية';

  @override
  String get quranScreen_englishPickthall => 'الإنجليزية، بيكثال';

  @override
  String get quranScreen_mohammadMarmadukePickthall => 'محمد مارمادوك بيكثال';

  @override
  String get quranScreen_englishTheMessage => 'الإنجليزية، الرسالة';

  @override
  String get quranScreen_englishMuhsinKhan => 'الإنجليزية، محسن خان';

  @override
  String get quranScreen_muhsinKhanHilali => 'محسن خان وهلالي';

  @override
  String get quranScreen_fatehMuhammadJalandhry => 'فاتح محمد جلندري';

  @override
  String get quranScreen_imamAhmadRazaKhan => 'الإمام أحمد رضا خان';

  @override
  String get quranScreen_maulanaSayyidAbulAla =>
      'مولانا السيد أبو العلاء المودودي';

  @override
  String get quranScreen_franAisHamidullah => 'فرانسيس، حميد الله';

  @override
  String get quranScreen_rkDiyanet => 'التركية، ديانت';

  @override
  String get quranScreen_rkLeymanAte => 'تركسي، سليمان اتيش';

  @override
  String get quranScreen_bahasaIndonesian => 'البهاسا، الإندونيسية';

  @override
  String get quranScreen_ministryOfReligiousAffairs => 'وزارة الشؤون الدينية';

  @override
  String get quranScreen_muhiuddinKhan => 'تمام، محي الدين خان';

  @override
  String get quranScreen_deutschAbuRida => 'دويتش، أبو ريدة';

  @override
  String get quranScreen_abuRidaMuhammadIbn => 'أبو رضا محمد بن أحمد';

  @override
  String get quranScreen_espaOlAsad => 'اسبانيول، اسد';

  @override
  String get quranScreen_uthmaniMadinah => 'العثماني (المدينة المنورة)';

  @override
  String get quranScreen_alJalalaynEN => 'الجلالين (EN)';

  @override
  String get quranScreen_couldNotLoadAyah =>
      'تعذر تحميل الآية. يرجى إعادة المحاولة.';

  @override
  String get quranScreen_noConnectionCachedData =>
      'لا يوجد اتصال. قد تكون البيانات المخزنة مؤقتًا متاحة.';

  @override
  String quranScreen_ayahs(String arg1) {
    return '$arg1 الآيات';
  }

  @override
  String get quranScreen_couldNotRemoveBookmark =>
      'تعذرت إزالة الإشارة المرجعية، يرجى إعادة المحاولة';

  @override
  String quranScreen_removedBookmark(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'تمت إزالة الإشارة المرجعية $_surahName $_surah:$_ayah';
  }

  @override
  String get quranScreen_couldNotSaveBookmark =>
      'تعذر حفظ الإشارة المرجعية، يرجى إعادة المحاولة';

  @override
  String quranScreen_bookmarked(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'تم وضع إشارة مرجعية $_surahName $_surah:$_ayah';
  }

  @override
  String get quranScreen_trimmedContains => ') && !مشذّب.يحتوي على(';

  @override
  String quranScreen_tafsir(String _surahName, String _surah, String _ayah) {
    return 'التفسير · $_surahName $_surah:$_ayah';
  }

  @override
  String get quranScreen_addedToFavourites => '♥ تم الإضافة إلى المفضلة';

  @override
  String get quranScreen_comfortableNightTimeReading => 'قراءة مريحة ليلا';

  @override
  String quranScreen_pt(String arg1) {
    return '$arg1 نقطة';
  }

  @override
  String quranScreen_003843(String arg1, String arg2) {
    return '$arg1 $arg2';
  }

  @override
  String get quranScreen_displayMeaningBelowEach => 'عرض المعنى تحت كل آية';

  @override
  String get quranScreen_showTransliteration => 'إظهار الترجمة الصوتية';

  @override
  String get quranScreen_romanisedPronunciationUnderEach =>
      'النطق بالحروف اللاتينية تحت كل كلمة';

  @override
  String get quranScreen_progressBarAyahCount =>
      'شريط التقدم وبطاقة عدد الآيات';

  @override
  String get quranScreen_moveToNextVerse =>
      'الانتقال إلى الآية التالية عندما ينتهي الصوت';

  @override
  String get quranScreen_repeatCurrentVerse => 'كرر الآية الحالية';

  @override
  String get quranScreen_notificationsALERTS => 'الإخطارات والتنبيهات';

  @override
  String get quranScreen_milestoneSoundAlerts => 'تنبيهات صوتية مهمة';

  @override
  String get quranScreen_chimeWhenYouReach =>
      'رنين عندما تصل إلى 10، 25، 50 آية';

  @override
  String get quranScreen_showEachArabicWord =>
      'إظهار كل كلمة عربية بمعناها الإنجليزي';

  @override
  String get quranScreen_translationLanguage => 'لغة الترجمة';

  @override
  String quranScreen_translationsAvailable(String arg1) {
    return '$arg1 الترجمات المتاحة';
  }

  @override
  String quranScreen_3502e8(String arg1, String arg2) {
    return '$arg1 / $arg2';
  }

  @override
  String quranScreen_sabiqSeedsEarnedToday(String _pointsToday) {
    return '+$_pointsToday بذور سابق التي حصلت عليها اليوم!';
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
  String quranScreen_ayahsRead(String _ayahsToday) {
    return '$_ayahsToday آيات مقروءة';
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
  String quranScreen_pageJuz(String _currentPage, String arg1) {
    return 'الصفحة $_currentPage · الجزء $arg1';
  }

  @override
  String get startJourneyScreen_unexpectedErrorDuringGoogle =>
      'حدث خطأ غير متوقع أثناء تسجيل الدخول إلى Google';

  @override
  String get startJourneyScreen_connectedToQuranCom =>
      'متصل بموقع القرآن الكريم';

  @override
  String get startJourneyScreen_connectedToQuranCom_0ac4de =>
      'متصل بـ Quran.com (تم تأجيل مزامنة الإشارات المرجعية)';

  @override
  String streakScreen_nextDays(String arg1, String arg2) {
    return 'التالي: $arg1 ($arg2 أيام)';
  }

  @override
  String streakScreen_seeds(String arg1) {
    return '+$arg1 البذور';
  }

  @override
  String streakScreen_days(String current, String arg1) {
    return '$current / $arg1 أيام';
  }

  @override
  String streakScreen_dayStreak(String arg1) {
    return '$arg1 خط يوم';
  }

  @override
  String get tafsirHubScreen_earnSeedsForEvery =>
      'اربح بذورًا مقابل كل 10 دقائق من استماع التفسير';

  @override
  String get tafsirScreen_alJalalaynEN => 'الجلالين (EN)';

  @override
  String tafsirScreen_verses(String arg1) {
    return '$arg1 الآيات';
  }

  @override
  String get tafsirScreen_trimmedContains => ') && !مشذّب.يحتوي على(';

  @override
  String tafsirScreen_ayahOf(String _ayah, String _surahLen) {
    return 'آية $_ayah من $_surahLen';
  }

  @override
  String tafsirScreen_4815bb(
    String _surahName,
    String _ayah,
    String _surahLen,
  ) {
    return '$_surahName $_ayah/$_surahLen';
  }

  @override
  String get tafsirScreen_tafsirNotAvailableFor =>
      'التفسير غير متوفر لهذه الآية.';

  @override
  String get donationService_youMustBeLogged => 'يجب عليك تسجيل الدخول للتبرع.';

  @override
  String get donationService_donationCouldNotBe =>
      'لا يمكن معالجة التبرع في هذا الوقت.';

  @override
  String get donationService_anUnexpectedNetworkError =>
      'حدث خطأ غير متوقع في الشبكة.';

  @override
  String get donationService_youMustBeLogged_edc4b5 =>
      'يجب عليك تسجيل الدخول للراعي.';

  @override
  String get donationService_sponsorshipReceived => 'تم الحصول على الرعاية 💝';

  @override
  String donationService_youSponsoredSeedsJazak(String amount) {
    return 'لقد قمت برعاية $amount بذور · جزاك الله خيرا.';
  }

  @override
  String get donationService_sponsorshipCouldNotBe =>
      'لا يمكن معالجة الرعاية في هذا الوقت.';

  @override
  String get liveNotificationService_remindersToSealYour =>
      'تذكيرات لإغلاق بذورك المعلقة قبل منتصف الليل.';

  @override
  String get liveNotificationService_sealYourSeedsBefore =>
      'ختم البذور الخاصة بك قبل منتصف الليل';

  @override
  String get liveNotificationService_sealYourSeedsBefore_be2183 =>
      'ختم البذور الخاصة بك قبل منتصف الليل!';

  @override
  String liveNotificationService_youHavePendingSeeds(String pendingSeeds) {
    return 'لديك $pendingSeeds بذور معلقة. اضغط على ختم اليوم قبل منتصف الليل أو تنتهي صلاحيته.';
  }

  @override
  String liveNotificationService_ayatReadToday(String _ayahCount) {
    return '$_ayahCount آيات إقرأها اليوم 📖';
  }

  @override
  String liveNotificationService_readQuranToday(String arg1) {
    return '$arg1 إقرأ القرآن اليوم ⏱️';
  }

  @override
  String get liveNotificationService_nothingReadFromQuran =>
      'لا شيء يقرأ من القرآن اليوم 📖';

  @override
  String liveNotificationService_dhikrCompletedToday(String _dhikrCount) {
    return '$_dhikrCount تم الانتهاء من الأذكار اليوم 📿';
  }

  @override
  String liveNotificationService_ayatDhikrToday(
    String _ayahCount,
    String _dhikrCount,
  ) {
    return '$_ayahCount آيات · $_dhikrCount أذكار اليوم';
  }

  @override
  String get liveNotificationService_keepReadingAndDoing =>
      'استمر في القراءة والقيام بالذكر!';

  @override
  String get liveNotificationService_yourSeedsToday => 'بذورك اليوم ✨';

  @override
  String get localReminderScheduler_sabiqRewardsNotifications =>
      'إشعارات مكافآت سابق';

  @override
  String get localReminderScheduler_it => 'هو - هي\\';

  @override
  String get localReminderScheduler_fridayReadSurahAl =>
      'يوم الجمعة - قراءة سورة الكهف';

  @override
  String get localReminderScheduler_whoeverRecitesSurahAl =>
      'من قرأ سورة الكهف في يوم الجمعة أضاء له من النور ما بين الجمعتين.';

  @override
  String get localReminderScheduler_don => 'اِتَّشَح\\';

  @override
  String get localReminderScheduler_missSurahAlKahf =>
      'لا تفوت سورة الكهف اليوم';

  @override
  String get localReminderScheduler_fewHoursToMaghrib =>
      'ساعات قليلة تفصلنا عن المغرب – أكمل سورة الكهف إذا لم تكن قد وصلت';

  @override
  String get quranApiService_notConnectedToQuran =>
      'غير متصل بموقع القرآن الكريم';

  @override
  String quranApiService_syncFailedBookmarkCould(String failed) {
    return 'فشلت المزامنة، تعذر دفع الإشارة (الإشارات) المرجعية $failed إلى موقع Quran.com (التحقق من الرمز المميز / نقطة النهاية).';
  }

  @override
  String get quranApiService_bookmarksAlreadyInSync =>
      'الإشارات المرجعية متزامنة بالفعل';

  @override
  String quranApiService_syncedBookmarksUpDown(
    String total,
    String uploaded,
    String downloaded,
  ) {
    return 'الإشارات المرجعية $total المتزامنة ($uploaded لأعلى، $downloaded لأسفل)';
  }

  @override
  String quranApiService_syncFailed(String e) {
    return 'فشلت المزامنة: $e';
  }

  @override
  String get streakService_warmingUp => 'الاحماء';

  @override
  String get streakService_oneWeek => 'أسبوع واحد';

  @override
  String get streakService_twoWeeks => 'اسبوعين';

  @override
  String get streakService_oneMonth => 'شهر واحد';

  @override
  String get streakService_twoMonths => 'شهرين';

  @override
  String get streakService_theCenturion => 'قائد المئة';

  @override
  String streakService_1fc043(String arg1, String arg2) {
    return '$arg1 $arg2';
  }

  @override
  String streakService_dayStreak(String arg1, String arg2) {
    return '$arg1-يوم $arg2 خط ·';
  }

  @override
  String streakService_bonusSeedsUnlocked(String arg1) {
    return '+$arg1 تم فتح البذور الإضافية';
  }

  @override
  String trackingService_c7528c(String arg1, String arg2) {
    return '$arg1 $arg2';
  }

  @override
  String xpService_level(String title, String level) {
    return '$title • المستوى $level';
  }

  @override
  String get xpService_newBadgeUnlocked => 'تم فتح شارة جديدة 🏆';

  @override
  String get xpService_you => 'أنت\\';

  @override
  String get xpService_dailyLoginBonus => 'مكافأة تسجيل الدخول اليومية';

  @override
  String xpService_seedsWelcomeBack(String arg1) {
    return '+$arg1 البذور · أهلاً بعودتك!';
  }

  @override
  String get xpService_daySealed => 'اليوم مختوم 🌙';

  @override
  String xpService_sabiqSeedsConfirmedBonus(String flushed, String bonus) {
    return '+$flushed بذور سابق مؤكدة! ($bonus مكافأة للختم)';
  }

  @override
  String xpService_sabiqSeedsConfirmed(String flushed) {
    return '+$flushed بذور سابق مؤكدة!';
  }

  @override
  String get dhikrExitCelebration_everyBreathCounts => 'كل نفس مهم.';

  @override
  String get impactAnimation_yourRewardHasBeen => 'لقد تم تسجيل مكافأتك.';

  @override
  String get motivationalPopup_verilyWithHardshipComes =>
      'إن مع العسر يسرا.\\nوكل فتنة باب إلى ما هو أعظم.';

  @override
  String get motivationalPopup_quranAlInshirah => 'القرآن • الانشراح 94:6';

  @override
  String get motivationalPopup_quranAlAnkabut => 'القرآن • العنكبوت 29:45';

  @override
  String get motivationalPopup_quranAlBaqarah => 'القرآن • البقرة 2:152';

  @override
  String get motivationalPopup_quranAnNahl => 'القرآن • النحل 16:18';

  @override
  String get motivationalPopup_makeYourTimePrecious =>
      'اجعل وقتك ثميناً.\\nشارك الخير مع صديق اليوم،\\nكل عمل صالح تشاركه صدقة.';

  @override
  String get motivationalPopup_guideOthersToGood =>
      'أرشد غيرك إلى الخير، تنال أجره.';

  @override
  String get motivationalPopup_theBestOfPeople =>
      'خير الناس من أنفعهم للآخرين.';

  @override
  String get motivationalPopup_verilyInTheRemembrance =>
      'ألا بذكر الله تطمئن القلوب.';

  @override
  String get motivationalPopup_remindYourselfTimeIs =>
      'ذكّر نفسك أن الوقت هو أغلى صدقة.';

  @override
  String get motivationalPopup_yourTimeIsYour =>
      'وقتك هو أثمن\\nأصولك. استثمرها بحكمة\\nفي ما يدوم إلى الأبد.';

  @override
  String get motivationalPopup_quranAlAnfal => 'القرآن • الأنفال 8:28';

  @override
  String get motivationalPopup_takeAdvantageOfFive => 'اغتنم خمسا قبل خمس.';

  @override
  String get motivationalPopup_youHaveBeenRewarded =>
      'لقد تمت مكافأتك على\\nثباتك اليوم!';

  @override
  String motivationalPopup_seeds(String arg1) {
    return '+$arg1 البذور';
  }

  @override
  String motivationalPopup_seeds_b14996(String arg1) {
    return '+$arg1 البذور';
  }

  @override
  String get motivationalPopup_readQuranPages => 'قراءة 5 صفحات القرآن';

  @override
  String get motivationalPopup_completeNowEarnSeeds =>
      'أكمل الآن → اربح +50 بذرة إضافية';

  @override
  String get motivationalPopup_completeDhikrSet => 'أكمل مجموعة الأذكار';

  @override
  String get motivationalPopup_finishYourAzkaarEarn =>
      'أنهي الأذكار ← اربح +30 بذرة إضافية';

  @override
  String get motivationalPopup_inviteFriend => 'قم بدعوة صديق';

  @override
  String get motivationalPopup_shareSabiqWithSomeone =>
      'شارك سابق مع شخص ما ← اربح +100 بذرة';

  @override
  String get motivationalPopup_keepYourSpiritualMomentum =>
      'حافظ على استمرار زخمك الروحي\\nوشاهد بذورك تنمو ✨';

  @override
  String get noorOffline_somethingWentWrong => 'حدث خطأ ما';

  @override
  String get notificationsSheet_stayOnTopOf =>
      'البقاء على رأس المكافآت والمعالم';

  @override
  String get notificationsSheet_llBeNotifiedAbout =>
      'سيتم إعلامك بشأن المكافآت والخطوط والمعالم.';

  @override
  String get notificationsSheet_inboxKeepsExistingItems =>
      'يحتفظ Inbox بالعناصر الموجودة ولكن لن تصل عناصر جديدة.';

  @override
  String get notificationsSheet_sabiqSeedsForSealing => 'بذور سابق لختم اليوم';

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
  String get projectMediaCarousel_couldNotLoadVideo => 'تعذر تحميل الفيديو';

  @override
  String get quranExitCelebration_beautifulRecitation => 'تلاوة جميلة.';

  @override
  String get quranExitCelebration_everyMomentCounts => 'كل لحظة لها أهميتها.';

  @override
  String sealCoinAnimation_e16fa4(String arg1) {
    return '+$arg1';
  }

  @override
  String get authScreen_pleaseEnterYourEmail_d36dc6 =>
      'الرجاء إدخال البريد الإلكتروني الخاص بك';

  @override
  String get authScreen_pleaseEnterYourPassword_0f8b9b =>
      'الرجاء إدخال كلمة المرور الخاصة بك';

  @override
  String get authScreen_passwordMustBeAt_c936ae =>
      'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';

  @override
  String get authScreen_alreadyHaveAnAccount_07e598 =>
      'هل لديك حساب بالفعل؟ تسجيل الدخول';

  @override
  String get authScreen_haveAnAccountSign_ae2883 => 'ليس لديك حساب؟ اشتراك';

  @override
  String qfAuthService_qfemailconflictexceptionAlreadyHasAn_e1592c(
    String email,
  ) {
    return 'QfEmailConflictException: $email لديه حساب بالفعل';
  }

  @override
  String get qfAuthService_openidOfflineAccessUser_fc4bcc =>
      'openid دون اتصال_الوصول إلى مجموعة الإشارات المرجعية للمستخدم read_session';

  @override
  String qfAuthService_tokenExchangeFailed_89d8a0(String arg1, String arg2) {
    return 'فشل تبادل الرمز المميز ($arg1): $arg2';
  }

  @override
  String get qfAuthService_errorNullResponse_bd81c7 => 'خطأ: استجابة فارغة';

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
      'استغفر الله — قالها النبي ✍ في اليوم 100 مرة، ولم يكن له ذنب. كم لديك؟';

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
  String akhirahBalanceScreen_thisSession_702ffc(String arg1) {
    return 'هذه الجلسة: +$arg1';
  }

  @override
  String akhirahBalanceScreen_seedsThisSession_cd9411(String arg1) {
    return '+$arg1 بذور هذه الجلسة';
  }

  @override
  String akhirahBalanceScreen_dayAvgAzkaarDay_c8f1b6(String arg1) {
    return 'متوسط ​​7 أيام: $arg1 أذكار/يوم';
  }

  @override
  String dashboardScreen_profileReturnedZeroRows_3ccedb(String uid) {
    return 'لم يُرجع الملف الشخصي أي صفوف لـ $uid';
  }

  @override
  String dashboardScreen_dashboardLoadError_6168de(String e) {
    return 'خطأ في تحميل لوحة المعلومات: $e';
  }

  @override
  String get dashboardScreen_invalidReferralCode_bb3b10 =>
      'رمز الإحالة غير صالح';

  @override
  String get dashboardScreen_cannotReferYourself_d836b8 =>
      'لا يمكن الرجوع نفسك';

  @override
  String dashboardScreen_sponsor_d48549(String name, String arg1) {
    return 'الراعي $name، $arg1';
  }

  @override
  String get dashboardScreen_dashboardDoesn_b8feb4 => ': 0، // لوحة القيادة لا';

  @override
  String dashboardScreen_today_261fbb(
    String arg1,
    String _lastAyah,
    String _ayahsToday,
  ) {
    return '$arg1 · $_lastAyah · +$_ayahsToday اليوم';
  }

  @override
  String dashboardScreen_606140_606140(String arg1, String _lastAyah) {
    return '$arg1 · $_lastAyah';
  }

  @override
  String dashboardScreen_dayStreak_2934ca(String arg1) {
    return '$arg1-خط يوم';
  }

  @override
  String get dashboardScreen_yourSabiqSeedsFund_3e8748 =>
      'تقوم شركة Sabiq Seeds الخاصة بكم بتمويل هذه المشاريع';

  @override
  String dashboardScreen_active_2d214a(String arg1) {
    return '$arg1 نشط';
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
  String get dashboardScreen_seeDetailsForMore_54551e =>
      'انظر التفاصيل لمزيد من المشاريع →';

  @override
  String get dashboardScreen_yourTOTALSABIQSEEDS_f1d60a =>
      'مجموع بذور سابق الخاصة بك';

  @override
  String get dashboardScreen_viewCampaignDonate_450be4 =>
      '🤲 شاهد الحملة وتبرع';

  @override
  String dashboardScreen_yourRank_67be90(String rankText) {
    return 'رتبتك: $rankText';
  }

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
  String dashboardScreen_sealWithin_381d5d(String arg1) {
    return 'الختم داخل ${arg1}h';
  }

  @override
  String get dashboardScreen_jazakallahDaySealed_70a34b =>
      'جزاك الله!  يوم مختوم';

  @override
  String dashboardScreen_ofGoal_9660ee(String arg1, String arg2) {
    return 'من $arg1 $arg2 هدف';
  }

  @override
  String get dhikrHubScreen_propheticSupplications_907064 => 'أدعية نبوية';

  @override
  String get dhikrHubScreen_morningEveningRemembrance_ec6bc2 =>
      'أذكار الصباح والمساء';

  @override
  String get dhikrHubScreen_furtherSupplications_f72602 => 'مزيد من الأدعية';

  @override
  String get dhikrHubScreen_closingRemembranceSalawat_5204e8 =>
      'أذكار الختام والصلاة';

  @override
  String get dhikrHubScreen_hajjUmrahSupplications_f4d1b9 =>
      'أدعية الحج والعمرة';

  @override
  String get dhikrHubScreen_falseHiddenAdd_c45662 => '] == خطأ) Hidden.add(r[';

  @override
  String get dhikrScreen_indoPak_fd8751 => 'إندو باك';

  @override
  String dhikrScreen_default_8bd36b(String recommendedCount) {
    return 'الافتراضي: $recommendedCount';
  }

  @override
  String get dhikrScreen_duaAzkarSettings_71de01 => 'إعدادات الدعاء والأذكار';

  @override
  String get dhikrScreen_hideTheVisualArtwork_28b4d2 =>
      'إخفاء منطقة العمل الفني المرئي';

  @override
  String get dhikrScreen_pinTheIllustrationAt_5ec641 =>
      'قم بتثبيت الرسم التوضيحي في الأعلى أثناء تمرير النص العربي أسفله';

  @override
  String dhikrScreen_readTimes_537f51(String readCount) {
    return 'اقرأ $readCount مرات';
  }

  @override
  String dhikrScreen_d08433_d08433(String arg1, String arg2) {
    return '$arg1 / $arg2';
  }

  @override
  String get dhikrScreen_alBaqarahAmanaAr_e9d62e =>
      'سورة البقرة 285 (أمانة الرسول)';

  @override
  String get dhikrScreen_alBaqarahAlifLam_71ad0e =>
      'سورة البقرة 1-5 (ألف لم ميم)';

  @override
  String get dhikrScreen_alBaqarahLaIkraha_e837fb => 'البقرة 256 (لا إكراها)';

  @override
  String get dhikrScreen_alBaqarahAllahuWaliyy_c2a18b =>
      'سورة البقرة 257 (الله وليه)';

  @override
  String get dhikrScreen_salawatIbrahimiyyaDurood_171c60 =>
      'الصلاة الإبراهيمية (الدرود)';

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
  String get dhikrScreen_hisnulMuslimChapter_8745dc => 'حصن مسلم، باب:';

  @override
  String dhikrScreen_3856c1_3856c1(String rawRef, String bottomRef) {
    return '$rawRef | $bottomRef';
  }

  @override
  String get dhikrScreen_bestOfBothWorlds_e1cc22 =>
      'وخير الدارين العتق من النار';

  @override
  String get dhikrScreen_patienceAndSteadfastnessIn_114391 =>
      'الصبر والثبات في كل تجربة';

  @override
  String get dhikrScreen_allahBurdensNoSoul_c8bf72 =>
      'ولا يكلف الله نفسا إلا وسعها';

  @override
  String get dhikrScreen_keepTheHeartFirm_7729fe => 'ثبت القلب على الهدى';

  @override
  String get dhikrScreen_faithAnsweredWithForgiveness_e8c93c =>
      'أجاب الإيمان بالمغفرة من الجحيم';

  @override
  String get dhikrScreen_allSovereigntyInAllah_a9e0b3 => 'الملك كله في الله\\';

  @override
  String get dhikrScreen_allahHearsEveryCall_bf9969 =>
      'إن الله سميع لكل دعوة بالذرية الصالحة';

  @override
  String get dhikrScreen_countedWithTheWitnesses_99a05a =>
      'محسوبا مع شهود الحق';

  @override
  String get dhikrScreen_forgivenessFirmFeetAnd_28f209 =>
      'المغفرة والأقدام الثابتة والنصر';

  @override
  String get dhikrScreen_theDuaOfThose_0ee764 => 'دعاء الذين يتفكرون';

  @override
  String get dhikrScreen_inscribedWithTheWitnesses_2257ce =>
      'مكتوب مع شهود الوحي';

  @override
  String get dhikrScreen_theDuaAllahAccepted_7e207c =>
      'الدعاء المقبول من آدم ﷺ';

  @override
  String get dhikrScreen_spareUsTheCompany_c290d3 => 'وارزقنا صحبة الظالمين';

  @override
  String get dhikrScreen_neverTrialForThe_292b26 => 'أبدا محاكمة للظالمين';

  @override
  String get dhikrScreen_refugeFromAskingWithout_0e04a4 =>
      'أعوذ بالله من السؤال بغير علم';

  @override
  String get dhikrScreen_prayerForSafetyAnd_5f4e34 =>
      'صلاة من أجل السلامة والإيمان';

  @override
  String get dhikrScreen_steadfastInPrayerMe_8ce7b5 => 'أقم الصلاة أنا وأولادي';

  @override
  String get dhikrScreen_mercyForMeMy_3edb52 => 'رحمة لي ولوالدي وللمؤمنين';

  @override
  String get dhikrScreen_prayerForParents_ae7e5c => 'دعاء للوالدين';

  @override
  String get dhikrScreen_entryOfTruthExit_88c367 =>
      'دخول الحقيقة، خروج الحقيقة';

  @override
  String get dhikrScreen_prayerOfTheYouth_1bf835 => 'دعاء شباب الكهف';

  @override
  String get dhikrScreen_askAllahForMore_07c189 => 'اسأل الله المزيد من العلم';

  @override
  String get dhikrScreen_allahAnswersAndSaves_c337ab =>
      'الله يجيب وينجي من كل ضيق';

  @override
  String get dhikrScreen_allahIsTheBest_1adf97 => 'والله خير الوارثين';

  @override
  String get dhikrScreen_blessedLandingWhereverYou_273aaf =>
      'هبوط مبارك أينما توقفت';

  @override
  String get dhikrScreen_refugeFromTheWhispers_7ff5fd =>
      'الاستعاذة من وساوس الشياطين';

  @override
  String get dhikrScreen_mercyFromTheBest_b394bb => 'رحمة من خير الراحمين';

  @override
  String get dhikrScreen_pardonAndMercyFrom_5d9eb1 => 'عفواً ورحمة من الرحمن';

  @override
  String get dhikrScreen_piousSpousesAndRighteous_e9918c =>
      'وأزواج صالحين وذرية صالحة';

  @override
  String get dhikrScreen_prayerForThoseWho_1ccfb5 => 'صلاة لمن تاب';

  @override
  String get dhikrScreen_gratitudeForParentsRighteousness_966d90 =>
      'شكر الوالدين، والبر في النسل';

  @override
  String get dhikrScreen_pleaGiftOfIshaq_5568af => 'نداء - هدية إسحاق ﷺ';

  @override
  String get dhikrScreen_loveForTheBelievers_d0cae3 =>
      'محبة المؤمنين الذين سبقونا';

  @override
  String get dhikrScreen_pureTawakkulOnYou_02bc03 =>
      'التوكل الخالص – عليك توكلنا';

  @override
  String get dhikrScreen_forgivenessForEveryBelieving_e256a1 =>
      'المغفرة لكل بيت مؤمن';

  @override
  String get dhikrScreen_tasbeehByTheWeight_27484a => 'التسبيح بثقل الله\\';

  @override
  String get dhikrScreen_tasbeehByTheNumber_224c3f => 'التسبيح بعدد كل ما صنع';

  @override
  String get dhikrScreen_tasbeehThatFillsAll_4b1a52 =>
      'التسبيح ملء كل ما خلق الله';

  @override
  String get dhikrScreen_paradiseSoughtTheFire_5740e3 =>
      'الجنة المطلوبة – النار\\';

  @override
  String get dhikrScreen_cryToTheOne_30f419 => 'ابكي على من يسمع ويرى ويعلم';

  @override
  String get dhikrScreen_nameOnTheCorner_b6afeb => 'إسمه على زاوية الكعبة';

  @override
  String get dhikrScreen_theDuaBetweenYemen_0bea3e =>
      'الدعاء بين الركن اليماني والحجر الأسود';

  @override
  String get dhikrScreen_prayAtTheStation_178d24 => 'الصلاة في مقام إبراهيم ﷺ';

  @override
  String get dhikrScreen_tawheedDeclaredAtopSafa_828769 =>
      'وأعلن التوحيد على الصفا والمروة';

  @override
  String get dhikrScreen_reaffirmTheOnenessOf_8589ea =>
      'التأكيد على وحدانية الله';

  @override
  String get dhikrScreen_magnifyAllahAtEvery_448549 =>
      'سبحوا الله عند كل عتبة حج';

  @override
  String get dhikrScreen_magnifyAllahOnThe_0fbc83 => 'سبحوا الله يوم النحر';

  @override
  String get dhikrScreen_knowledgeProvisionHealingSought_9733f3 =>
      'العلم والرزق والشفاء مطلوب في مكة';

  @override
  String get dhikrScreen_theDuaMostRepeated_a9da8d =>
      'أكثر دعاء ردده النبي صلى الله عليه وسلم';

  @override
  String get dhikrScreen_refugeFromEveryTrial_8ca1b1 =>
      'اهرب من كل تجربة حياة أو موت';

  @override
  String get dhikrScreen_refugeFromEveryWeakness_b1a834 =>
      'اعوذ بالله من كل ضعف في الجسد والروح';

  @override
  String get dhikrScreen_refugeFromSevereTrial_0029f0 =>
      'اعوذ بالله من شدة البلاء والعدو\\';

  @override
  String get dhikrScreen_religionSetRightWorld_3b0102 =>
      'أصلح الدين، وأصلح الدنيا والآخرة';

  @override
  String get dhikrScreen_guidancePietyVirtueSelf_cc439a =>
      'الهداية والتقوى والفضيلة والاكتفاء بالنفس';

  @override
  String get dhikrScreen_refugeFromWeaknessWealth_d879f5 =>
      'اهرب من الضعف – ثروة التقوى في داخلك';

  @override
  String get dhikrScreen_theGuiderOfHearts_1f40d9 =>
      'مرشد القلوب – حولنا إلى الطاعة';

  @override
  String get dhikrScreen_turnerOfHeartsMake_eba687 =>
      'مقلب القلوب ثبتني على الدين';

  @override
  String get dhikrScreen_wellBeingInBoth_442958 => 'العافية في كلا العالمين';

  @override
  String get dhikrScreen_rewardsSaveFromDisgrace_8b71bb =>
      'الأجر والثواب من الخزي والقبر\\';

  @override
  String get dhikrScreen_mindForGoodVictory_582759 =>
      'العقل للخير، النصر للخير';

  @override
  String get dhikrScreen_refugeFromEvilOf_0c8916 =>
      'التعوذ من شر كل حس و جوارح';

  @override
  String get dhikrScreen_theForgiverWhoLoves_e5d83f =>
      'الغفور الذي يحب التائبين';

  @override
  String get dhikrScreen_takeMeBeforeYou_28ef55 => 'خذني قبل أن تضلني';

  @override
  String get dhikrScreen_everyGoodAndRefuge_4205e2 =>
      'من كل خير - و التعوذ من كل شر';

  @override
  String get dhikrScreen_standingSittingLyingGuarded_254177 =>
      'الوقوف والجلوس والكذب - حراسة في الإسلام';

  @override
  String get dhikrScreen_refugeFromCowardiceMiserliness_9b59bd =>
      'أعوذ بالله من الجبن والبخل والفتنة';

  @override
  String get dhikrScreen_forgivenessForJestAnd_e683b5 =>
      'العفو عن الهزل والجد، المعروف والمجهول';

  @override
  String get dhikrScreen_forgiveMeWithForgiveness_894a1a =>
      'اغفر لي مغفرة من عندك';

  @override
  String get dhikrScreen_submissionBeliefRepentanceFull_7338d6 =>
      'التسليم، الإيمان، التوبة، الثقة الكاملة';

  @override
  String get dhikrScreen_mercyForgivenessParadiseSaved_0d9edd =>
      'الرحمة والمغفرة والجنة والنجاة من النار';

  @override
  String get dhikrScreen_refugeFromEvilSeen_140ec4 =>
      'أعوذ بالله من الشر ما يرى وما لا يرى';

  @override
  String get dhikrScreen_provisionThatLastsTill_dcef82 =>
      'رزق يدوم مدى الحياة\\';

  @override
  String get dhikrScreen_sinsForgivenHomeSpacious_2ac37c =>
      'الذنوب مغفورة، والدار فسيحة، والرزق مبارك';

  @override
  String get dhikrScreen_favorAndMercyNone_f665cf =>
      'الفضل والرحمة لا يملكهما إلا أنت';

  @override
  String get dhikrScreen_refugeFromDrowningBurning_402b3e =>
      'نجاة من الغرق والحرق والموت المفاجئ';

  @override
  String get dhikrScreen_refugeFromHypocrisyShowiness_d863c2 =>
      'اعوذ بالله من النفاق والتباهي والتمرد';

  @override
  String get dhikrScreen_refugeFromPovertyScarcity_03ef3d =>
      'اعوذ بالله من الفقر والقلة والقهر';

  @override
  String get dhikrScreen_refugeFromHeartThat_21f7ab => 'ملجأ من قلب فاز\\';

  @override
  String get dhikrScreen_payMyDebtEnrich_f5affc => 'ادفع ديني وأغنيني من الفقر';

  @override
  String get dhikrScreen_allahCalledByHis_c11af9 => 'ودعا الله بأسمائه الحسنى';

  @override
  String get dhikrScreen_theAccepterOfRepentance_4f2d60 =>
      'وقابل التوبة يقبل دائما';

  @override
  String get dhikrScreen_anEasyReckoningOn_11b060 =>
      'الحساب اليسير يوم القيامة';

  @override
  String get dhikrScreen_remembranceGratitudeAndThe_d7ee7b =>
      'والذكر والشكر وأفضل العبادة';

  @override
  String get dhikrScreen_eternalBlissWithThe_dc255b =>
      'النعيم الدائم مع النبي صلى الله عليه وسلم في الفردوس';

  @override
  String get dhikrScreen_forgiveSinsKnownHidden_ceda62 =>
      'اغفر الذنوب ما علم منها وما خفي منها والمقصود منها والخطأ';

  @override
  String get dhikrScreen_refugeFromBeingCrushed_4ba6ac =>
      'ملجأ من التعرض للسحق من قبل الديون والأعداء';

  @override
  String get dhikrScreen_askForParadiseRefuge_4bf2eb =>
      'اطلب الجنة، والتعوذ من النار';

  @override
  String get dhikrScreen_forgiveGuideProvideProtect_e93013 =>
      'يغفر، يرشد، يوفر، يحمي';

  @override
  String get dhikrScreen_sensesMadeBeneficialAnd_4da09c =>
      'أصبحت الحواس مفيدة - ودائمة';

  @override
  String get dhikrScreen_theMostBeneficentThe_65d7a6 => 'الرحمن، المنشئ للجميع';

  @override
  String get dhikrScreen_allahTruthOwnerOf_d4bede =>
      'الله - الحق، مالك كل سلطان';

  @override
  String get dhikrScreen_submissionWithFullSincerity_cbd7b6 =>
      'التقديم بكل إخلاص';

  @override
  String get dhikrScreen_amongTheGuidedThe_e4d9d0 =>
      'من المهتدين الأصحاء المختارين';

  @override
  String get dhikrScreen_whatTheProphetAsked_e3a810 =>
      'ما سأله النبي صلى الله عليه وسلم - أنا أسأل أيضا';

  @override
  String get dhikrScreen_sayyidAlIstighfarThe_51076a =>
      'السيد الاستغفار – سيد التوبة كلها';

  @override
  String get dhikrScreen_refugeFromEveryEvil_ea8dab =>
      'تعوذ من كل شر يأتي بالليل';

  @override
  String get dhikrScreen_blessEverySenseEvery_e7779d => 'بارك كل حاسة، وكل طرف';

  @override
  String get dhikrScreen_smallAndGreatFirst_dbcc00 =>
      'الصغير والكبير، الأول والأخير، العلني والسري';

  @override
  String get dhikrScreen_noneWithholdsWhatYou_c4dca7 =>
      'لا مانع لما أعطيت، ولا معطي لما أعطيت';

  @override
  String get dhikrScreen_forgiveGuideProvideElevate_55fa36 =>
      'يغفر، يهدي، يرزق، يرفع';

  @override
  String get dhikrScreen_increaseFavorBeKind_5fbc5c =>
      'أكثر المعروف، وكن لطيفًا، ولا تسخط أبدًا';

  @override
  String get dhikrScreen_beautifyOurCharacterAs_cc5d8c =>
      'وزين خلقنا كما حسنت خلقنا';

  @override
  String get dhikrScreen_firmInBeliefGuided_73f8af =>
      'ثابتون على الإيمان – هادون ومرشدون';

  @override
  String get dhikrScreen_wisdomAndWithIt_e8e5bd =>
      'الحكمة - ومعها الكثير من الخير';

  @override
  String get dhikrScreen_nameShieldsFromEvery_59e06f =>
      'واسمه تحصين من كل مكروه';

  @override
  String get dhikrScreen_mightAgainstEveryShaytan_73b152 =>
      'قوتها على كل شيطان';

  @override
  String get dhikrScreen_dayBlessedFromBeginning_c6d87d =>
      'يوم مبارك من أوله إلى آخره';

  @override
  String get dhikrScreen_witnessNoneDeservesWorship_385aa9 =>
      'إشهد - لا أحد يستحق العبادة إلا أنت';

  @override
  String get dhikrScreen_refugeFromHumiliatingOld_46a3f0 =>
      'أعوذ بالله من الشيخوخة المهينة';

  @override
  String get dhikrScreen_guidedToTheBest_03e8d2 =>
      'يرشد إلى الأفضل، ويحفظ من الأسوأ';

  @override
  String get dhikrScreen_faithSetRightHome_08f8e1 =>
      'الإيمان ثابت، البيت واسع، الرزق مبارك';

  @override
  String get dhikrScreen_refugeFromEveryInner_dc67c7 =>
      'اعوذ بك من كل داء باطني وظاهري';

  @override
  String get dhikrScreen_refugeFromEveryKind_dfbe62 =>
      'اعوذ بالله من كل سوء خاتمة';

  @override
  String get dhikrScreen_steadfastGratefulRightlyGuided_45b393 =>
      'قلبًا ثابتًا شاكرًا مسترشدًا';

  @override
  String get dhikrScreen_theLoveOfAllah_3bf08a => 'محبة الله وملائكته وأنبيائه';

  @override
  String get dhikrScreen_loveOfAllahAbove_4c81b3 => 'حب الله فوق حب النفس';

  @override
  String get dhikrScreen_bestDeedsLastBest_2ff65e =>
      'وخير الأعمال تدوم – وخير يوم لقائك';

  @override
  String get dhikrScreen_pureLifeAndPeaceful_a7eb0f => 'حياة نقية وعودة سلمية';

  @override
  String get dhikrScreen_patientGratefulSmallIn_059385 =>
      'صبور، ممتن، صغير في أعين نفسه';

  @override
  String get dhikrScreen_theBestRequestAnd_cd3f6f => 'خير الطلب وخير الجزاء';

  @override
  String get dhikrScreen_theHighestLevelOf_221efa => 'أعلى درجات الجنة';

  @override
  String get dhikrScreen_firdawsTheBestOf_01be47 => 'الفردوس — أفضل ذلك كله\\';

  @override
  String get dhikrScreen_mentionRaisedSinsErased_c6e2f3 =>
      'يُرفع الذكر، وتُمحى الذنوب، ويُطهر القلب';

  @override
  String get dhikrScreen_mercyPleasureParadiseSaved_8b4a98 =>
      'الرحمة والرضوان والجنة والنجاة من النار';

  @override
  String get dhikrScreen_noSinUncoveredNo_efd903 =>
      'لا خطيئة مكشوفة، ولا دين غير مدفوع';

  @override
  String get dhikrScreen_mercyThatGuidesSets_89b7cf =>
      'الرحمة التي ترشد، وتصلح، وتطهر';

  @override
  String get dhikrScreen_trueBeliefCertainKnowledge_d27506 =>
      'الإيمان الحق، العلم اليقين، الله\\';

  @override
  String get dhikrScreen_withTheProphetsThe_b2123f =>
      'مع النبيين والشهداء والصديقين';

  @override
  String get dhikrScreen_everyNeedEntrustedTo_8b33b6 =>
      'وكل حاجة موكولة إلى قاضي جميع الحاجات';

  @override
  String get dhikrScreen_bestOfWhatAllah_70d237 => 'أفضل ما وعد الله عباده';

  @override
  String get dhikrScreen_safetyOnTheDay_89cb9f =>
      'السلامة يوم، والجنة يوم الخلود';

  @override
  String get dhikrScreen_glorifyTheOneOf_de3669 =>
      'تمجيد ذو الشرف والعلم الذي لا مثيل له';

  @override
  String get dhikrScreen_pardonPlentySecurityIn_d6b56a =>
      'العفو، الكثير، الأمن في الدين والدنيا';

  @override
  String get dhikrScreen_healthFaithEthicsSuccess_000fef =>
      'الصحة، الإيمان، الأخلاق، النجاح، الرحمة';

  @override
  String get dhikrScreen_healthPurityEthicsAcceptance_b6929c =>
      'الصحة، الطهارة، الأخلاق، القبول';

  @override
  String get dhikrScreen_guidedSecureVictorious_b56e05 =>
      'مهتدين، آمنين، منتصرين';

  @override
  String get dhikrScreen_refugeFromEveryCreature_cbe2de =>
      'أعوذ بالله من كل مخلوق\\';

  @override
  String get dhikrScreen_theOneWhoAnswers_f2e37f =>
      'هو الذي يجيب المضطر والمكسور';

  @override
  String get dhikrScreen_morningReachedByAllah_b03f32 => 'صباح بلغه الله\\';

  @override
  String get dhikrScreen_refugeSoughtByMusa_176ee5 =>
      'طلب اللجوء موسى وعيسى وإبراهيم';

  @override
  String get dhikrScreen_allTheGoodPower_418dc3 =>
      'كل الخير – القوة، الرحمة، البركات';

  @override
  String get dhikrScreen_allPraiseAndDominion_27662b => 'لك كل الحمد والسيادة';

  @override
  String get dhikrScreen_pastPardonedFutureProtected_a8bfa1 =>
      'الماضي عفواً، والمستقبل محمي';

  @override
  String get dhikrScreen_takeMyForelockTo_a44b8f => 'خذ بناصيتي إلى الخير';

  @override
  String get dhikrScreen_strengthForWeaknessDignity_dce155 =>
      'القوة مقابل الضعف، والكرامة مقابل العار';

  @override
  String get dhikrScreen_justiceForThoseWho_4e52f3 =>
      'العدالة لمن يحجب الحقيقة';

  @override
  String get dhikrScreen_refugeFromEveryFatal_b155a7 =>
      'اعوذ بالله من كل مصيبة قاتلة';

  @override
  String get dhikrScreen_refugeFromEveryBad_a9e27f =>
      'اعوذ بالله من كل سوء خاتمة وتجربة';

  @override
  String get dhikrScreen_turnBackEveryEvil_66e6fa =>
      'رد كل نية سيئة إلى مصدرها';

  @override
  String get dhikrScreen_justiceAndRefugeAgainst_e4e734 =>
      'العدل والنجاة من شرورهم';

  @override
  String get dhikrScreen_forgivenessForMeMy_27b932 =>
      'اغفر لي ولوالدي ولجميع المؤمنين';

  @override
  String get dhikrScreen_purifyHeartDeedsTongue_10837e =>
      'طهارة القلب، والعمل، واللسان، والعين';

  @override
  String get dhikrScreen_selfContentWithAllah_68c73a => 'الرضا عن الله\\';

  @override
  String get dhikrScreen_youKnowMySecret_2b63c7 => 'أنت تعرف سرّي وحاجتي';

  @override
  String get dhikrScreen_certaintyNothingHarmsWhat_e513d7 =>
      'اليقين: لا شيء يضر ما\\';

  @override
  String get dhikrScreen_beliefLightAndLawful_e69a59 =>
      'الإيمان والنور والرزق الحلال';

  @override
  String get dhikrScreen_totalLoveAndTotal_3d137e =>
      'الحب الكامل والنضال الكامل في سبيل الله';

  @override
  String get dhikrScreen_makeWhatYouWithheld_14be7d =>
      'واجعل ما منعت قوة في الطاعة';

  @override
  String get dhikrScreen_praiseTheOwnerOf_244f8b => 'سبحان صاحب كل إسم جميل';

  @override
  String get dhikrScreen_allahKnowsTheHearts_d6010c =>
      'الله يعلم القلوب والسماء وما وراءها';

  @override
  String get dhikrScreen_hopeBuiltOnAllah_217ad7 => 'الأمل مبني على الله\\';

  @override
  String get dhikrScreen_belovedToTheBelievers_b1f5a3 =>
      'حبيب للمؤمنين، بريء من الأشرار';

  @override
  String get dhikrScreen_mightPowerAndMajesty_91ca0a => 'القوة والقوة والعظمة';

  @override
  String get dhikrScreen_gratefulPatientHelpfulTo_3710c6 =>
      'شاكراً صابراً مستعيناً بالله\\';

  @override
  String get dhikrScreen_withholdYourGoodFor_0d39a1 =>
      'لا تمنع خيرك من أجل شري';

  @override
  String get dhikrScreen_settledLifeAmpleProvision_77b32b =>
      'حياة مستقرة، ورزق واسع، وعمل صالح';

  @override
  String get dhikrScreen_wealthInNeedingYou_547729 =>
      'الثروة في الحاجة إليك - لا تتحرر منك أبدًا';

  @override
  String get dhikrScreen_defectsCoveredFearsCalmed_a85797 =>
      'غطت العيوب، وهدأت المخاوف، وزال الكرب';

  @override
  String get dhikrScreen_openTheGatesOf_402eac => 'افتحوا أبواب الرحمة والكرم';

  @override
  String get dhikrScreen_holdUsInYour_b82607 =>
      'احفظنا في أمانك – لا تتخلى عنا أبدًا';

  @override
  String get dhikrScreen_withinYourSecurityYour_f72b6e => 'في أمانك، صلاحك';

  @override
  String get dhikrScreen_everySinEveryDistress_eab128 =>
      'كل خطيئة، كل ضيق، كل جانب';

  @override
  String get dhikrScreen_helpInDeathIn_342d0b =>
      'استعانة بالموت، في القبر، على الصراط';

  @override
  String get dhikrScreen_beautifiedLifeBlessedGifts_7f2384 =>
      'حياة جميلة، عطايا مباركة، حفظة نعم';

  @override
  String get dhikrScreen_firmFootingBlessedEnd_c78f99 =>
      'قدم ثابتة، نهاية مباركة، حفظ العهد';

  @override
  String get dhikrScreen_hopesFulfilledEnemiesRepelled_afd008 =>
      'تتحقق الآمال، ويصد الأعداء، وتصلح الأمور';

  @override
  String get dhikrScreen_guidedToTheUpright_9e1527 =>
      'هدى إلى المستقيمين، معصومين من النفس';

  @override
  String get dhikrScreen_lightAndForgivenessFrom_3923eb =>
      'نور ومغفرة من ذي العرش';

  @override
  String get dhikrScreen_forgivenessForWhatRepented_6a44f8 =>
      'المغفرة لما تبت ورجعت إليه';

  @override
  String get dhikrScreen_understandingThatDrawsNear_e1455e =>
      'فهم يتقرب إلى الله';

  @override
  String get dhikrScreen_soulsDwellingInThe_1bd11b =>
      'نفوس ساكنة في أعالي التقوى';

  @override
  String get dhikrScreen_crossTheBridgeOf_4f4ff3 => 'اعبر جسر الرغبة بالصبر';

  @override
  String get dhikrScreen_followThePathOf_934775 => 'اتبع طريق الصدق واليقين';

  @override
  String get dhikrScreen_helpAgainstTheSoul_44a7db =>
      'عون على النفس وضد الشيطان';

  @override
  String get dhikrScreen_fearHappinessVictorySecurity_9017c9 =>
      'الخوف، السعادة، النصر، الأمان';

  @override
  String get dhikrScreen_entrustFamilyWealthChildren_1da596 =>
      'استودع الأسرة والثروة والأولاد - كل ذلك لله';

  @override
  String get dhikrScreen_faithGuardedFaithPreserved_88eecb =>
      'الإيمان مصون، الإيمان محفوظ';

  @override
  String get dhikrScreen_wellBeingTillThe_ee180d =>
      'العافية حتى النهاية - مختومة بالمغفرة';

  @override
  String get dhikrScreen_whatProtectsMeFrom_052090 =>
      'ما يحميني من هذا العالم\\';

  @override
  String get dhikrScreen_mercyOnEverySoul_a9a197 => 'رحمة لكل نفس\\';

  @override
  String get dhikrScreen_burdenUsAsThose_78b517 =>
      'لا تثقل علينا كما ثقل الذين من قبل';

  @override
  String get dhikrScreen_mercyPardonForgivenessVictory_300143 =>
      'الرحمة، العفو، المغفرة، النصر';

  @override
  String get dhikrScreen_allahNeverFailsHis_c2265a =>
      'إن الله لا يخلف وعده أبدا';

  @override
  String get dhikrScreen_recordUsWithThe_b93190 => 'سجلنا مع شهود الحق';

  @override
  String get dhikrScreen_forgivenessFirmnessAndVictory_a8b674 =>
      'العفو والحزم والنصر';

  @override
  String get dhikrScreen_creationHasPurposeRefuge_ce2eee =>
      'الخلق له غرض - النجاة من النار';

  @override
  String get dhikrScreen_refugeFromTheDisgrace_605b1b => 'التعوذ من خزي النار';

  @override
  String get dhikrScreen_heardBelievedAskingForgiveness_d5387f =>
      'سمعت، صدقت، الاستغفار';

  @override
  String get dhikrScreen_sinsForgivenDeathAmong_bd82ed =>
      'مغفورة الخطايا - الموت بين الأبرار';

  @override
  String get dhikrScreen_promisedRewardNeverDisgraced_490396 =>
      'ووعد بالأجر فلا يخزى يوم القيامة';

  @override
  String get dhikrScreen_provisionAndSignsFrom_81db14 => 'رزق وآيات من السماء';

  @override
  String get dhikrScreen_duaTheDuaOf_4b9d01 => 'دعاء - دعاء كل تائب';

  @override
  String get dhikrScreen_spareUsFromThe_79732a => 'نجنا من صحبة الظالمين';

  @override
  String get dhikrScreen_patienceTillTheEnd_a8a4c4 =>
      'الصبر حتى النهاية، والموت عند التسليم';

  @override
  String get dhikrScreen_hiddenInEveryChest_ce7671 => 'مخبأة في كل صدر';

  @override
  String get dhikrScreen_prayerForPrayerAccepted_e68fa6 => 'صلاة مقبولة الصلاة';

  @override
  String get dhikrScreen_mercyGrantedGuidancePrepared_5c6f63 =>
      'الرحمة منحت، والتوجيه معد';

  @override
  String get dhikrScreen_duaBeforePharaoh_2d90cd => 'الدعاء أمام فرعون';

  @override
  String get dhikrScreen_refugeFromClingingEvil_b1e6e4 =>
      'اعوذ بالله من العذاب الخبيث';

  @override
  String get dhikrScreen_piousSpousesRighteousChildren_64225f =>
      'أزواج صالحون، أولاد صالحون، قيادة';

  @override
  String get dhikrScreen_allahIsEverThankful_464c97 =>
      'والله الشكر دائمًا على كل جهد';

  @override
  String get dhikrScreen_mercyEncompassingEveryRepentant_fb0759 =>
      'الرحمة تشمل كل نفس تائبة';

  @override
  String get dhikrScreen_mercyOnThatDay_a1b18b => 'الرحمة يومئذ – الفوز العظيم';

  @override
  String get dhikrScreen_loveAndForgivenessFor_660a56 =>
      'المحبة والغفران للمؤمنين السابقين';

  @override
  String get dhikrScreen_kindnessAndMercyUpon_1c62c8 =>
      'اللطف والرحمة من الله\\';

  @override
  String get dhikrScreen_pureTawakkulToYou_389089 =>
      'التوكل الخالص - إليك راجعون';

  @override
  String get dhikrScreen_neverFitnahForThose_dc1363 =>
      'لا تكون فتنة للذين كفروا';

  @override
  String get dhikrScreen_completeTheLightForgive_fd7380 =>
      'أكمل النور – اغفر لنا';

  @override
  String get dhikrScreen_strongerThanServantThe_4cc56e =>
      'أقوى من خادم – الليل\\';

  @override
  String get dhikrScreen_refugeFromEveryVisible_b81e69 =>
      'التعوذ من كل شر ظاهرة قبل النوم';

  @override
  String get dhikrScreen_refugeFromEveryWhisper_b030ed =>
      'اعوذ بك من كل همسة قبل النوم';

  @override
  String get dhikrScreen_guardedByAnAngel_65d1c1 => 'يحرسه ملاك حتى الصباح';

  @override
  String get dhikrScreen_twoVersesThatSuffice_1941c5 =>
      'آيتان تكفيان ليلة كاملة';

  @override
  String get dhikrScreen_pureTawheedDeclaredBefore_50673a =>
      'أعلن التوحيد الخالص قبل النوم';

  @override
  String get dhikrScreen_sleepIsSmallDeath_b4b84d =>
      'النوم موت صغير في ذمة الله';

  @override
  String get dhikrScreen_whoeverDiesThatNight_75dda7 =>
      'ومن مات تلك الليلة مات على الفطرة';

  @override
  String get dhikrScreen_guardTheSoulThat_a0850e =>
      'احفظ النفس التي تعود، أو ارحم';

  @override
  String get dhikrScreen_refugeFromThePunishment_18162a =>
      'نجاة من عذاب ذلك اليوم';

  @override
  String get dhikrScreen_gratitudeForShelterFood_1f5e94 =>
      'الامتنان للمأوى والغذاء والرعاية';

  @override
  String get dhikrScreen_handOverTheSoul_fda192 => 'تسليم الروح قبل النوم';

  @override
  String get dhikrScreen_joinTheHighestAssembly_68e2d3 =>
      'انضم إلى المجلس الأعلى أثناء نومك';

  @override
  String get dhikrScreen_gratitudeBeforeClosingThe_20f3db =>
      'الشكر قبل أن تغمض عينيك';

  @override
  String get dhikrScreen_surahAsSajdahRecited_a4beaa =>
      'قراءة سورة السجدة قبل النوم';

  @override
  String get dhikrScreen_refugeFromEvilBefore_a5d312 =>
      'الاستعاذة من الشر قبل دخول الخلاء';

  @override
  String get dhikrScreen_seekForgivenessAsYou_f14da9 => 'استغفر وأنت تغادر';

  @override
  String get dhikrScreen_bismillahEveryBiteBegins_8a678d =>
      'بسم الله - كل لقمة تبدأ بالله';

  @override
  String get dhikrScreen_catchUpTheName_e6d0d6 =>
      'اللحاق بالاسم – الله في البداية والنهاية';

  @override
  String get dhikrScreen_threeSunnahDuasTo_a56769 =>
      'ثلاث أدعية لشكر الله بعد الأكل';

  @override
  String get dhikrScreen_beginWithAllahThe_a64af2 =>
      'ابدأ بالله الرحمن قبل الشرب';

  @override
  String get dhikrScreen_openTheEightDoors_011a50 =>
      'افتح أبواب الجنة الثمانية بعد الوضوء';

  @override
  String get dhikrScreen_openTheDoorsOf_15e084 => 'افتحوا أبواب الله\\';

  @override
  String get dhikrScreen_bountyAsYouLeave_a06fc6 => 'فضله عند خروجك من المسجد';

  @override
  String get dhikrScreen_mayAllahGuideYou_af987e => 'الله يوفقك ويصلح حالك';

  @override
  String get dhikrScreen_askAllahLordOf_4a3eb0 => 'اسأل الله رب العرش أن يشفيه';

  @override
  String get dhikrScreen_allahIsTheOnly_9750c1 => 'الله وحده هو الذي يشفي';

  @override
  String get dhikrScreen_shieldChildrenWithAllah_858245 =>
      'حماية الأطفال مع الله\\';

  @override
  String get dhikrScreen_anicPrayerForOne_e18aca => 'صلاة أنيك لأحد\\';

  @override
  String get dhikrScreen_twoPhrasesBelovedTo_5d16a7 =>
      'كلمتان حبيبتان إلى الرحمن';

  @override
  String get dhikrScreen_allahLovesToPardon_a64d0a =>
      'إن الله يحب العفو فاسألوا';

  @override
  String get dhikrScreen_treasureFromBeneathThe_87d578 => 'كنز من تحت العرش';

  @override
  String get dhikrScreen_theFourPhrasesDearest_680ef8 =>
      'العبارات الأربع أحب إلى الله';

  @override
  String get dhikrScreen_theDuaThatReleases_ddc7eb =>
      'الدعاء الذي يفرج من كل ضيق';

  @override
  String get dhikrScreen_protectionForHomeAnd_0c4973 => 'حماية للبيت والذرية';

  @override
  String get dhikrScreen_theCompleteDhikrOf_31b993 => 'اذكار التوحيد كاملة';

  @override
  String get dhikrScreen_trialPurifiedByAllah_39fb26 =>
      'محاكمة مطهرة من الله\\';

  @override
  String get dhikrScreen_guidanceBeforeAnyChoice_50eb02 =>
      'التوجيه قبل أي خيار';

  @override
  String get dhikrScreen_completeRuqyaSequenceFatihah_5ced40 =>
      'تسلسل الرقية كاملة – الفاتحة والمعوذتين';

  @override
  String get dhikrScreen_sinsForgivenEvenIf_cd9a85 =>
      'تغفر الذنوب ولو مثل زبد البحر';

  @override
  String get dhikrScreen_freedHasanatSinsErased_54ebbb =>
      '10 محرومة · 100 حسنة · تمحى 100 خطيئة · طرد الشيطان';

  @override
  String get dhikrScreen_blessingsDescendFromAllah_41e8f6 =>
      '10 بركات تنزل من الله عليك';

  @override
  String get dhikrScreen_askAllahToBless_3470fe =>
      'اسأل الله أن يبارك يومك ويجمله';

  @override
  String get dhikrScreen_guaranteedJannahIfYou_6f7054 =>
      'وتضمن لك الجنة إذا مت في هذا اليوم';

  @override
  String get dhikrScreen_yourLifeEntrustedTo_77feba =>
      'حياتك مؤتمنة على الحي الدائم';

  @override
  String get dhikrScreen_allEvilInHis_f02365 => 'يدفع عنك كل سوء في خلقه';

  @override
  String get dhikrScreen_nothingShallHarmYou_cbc2fc =>
      'لن يضرك شيء بالكلمات المثالية';

  @override
  String get dhikrScreen_shieldYourselfFromMinor_2a73ed =>
      'احفظ نفسك من الشرك الأصغر والأكبر صباحاً ومساءً';

  @override
  String get dhikrScreen_completeProtectionInThe_620c30 =>
      'الحماية الكاملة بسم الله';

  @override
  String get dhikrScreen_weightierThanAllVoluntary_7af10a =>
      'أثقل من جميع صلاة التطوع من الفجر إلى المغرب';

  @override
  String get dhikrScreen_reciteMorningEveningEarn_77aa68 =>
      'أقرأها في الصباح والمساء تنال رضوان الله وبركاته يوم القيامة';

  @override
  String get dhikrScreen_yourRewardAwaitsDirectly_1827f4 =>
      'أجرك ينتظرك مباشرة عند الله عندما تقابله';

  @override
  String get dhikrScreen_reciteMorningEveningTo_1843f8 =>
      'أقرأ في الصباح والمساء لأداء واجب الشكر لله';

  @override
  String get dhikrScreen_theProphetTaughtThis_50fab2 =>
      'وقد علم النبي هذا الدعاء في الصباح والمساء فلا تفوته';

  @override
  String get dhikrScreen_dominionAtTheStart_690ca9 =>
      'الملك في أول صباحك، له الملك كله';

  @override
  String get dhikrScreen_asEveningFallsThe_934b7e =>
      'ومع حلول المساء، يصبح الملك كله لله وحده';

  @override
  String get dhikrScreen_endYourEveningUpon_ada386 =>
      'اختم أمسيتك على الفطرة الطاهرة كما علم النبي صلى الله عليه وسلم';

  @override
  String get dhikrScreen_satanWillNotEnter_446a1c =>
      'لا يدخل الشيطان بيت من قرأ هذا';

  @override
  String get dhikrScreen_readingLastVersesOf_99a432 =>
      'تكفيك قراءة آخر آيتين من سورة البقرة';

  @override
  String get dhikrScreen_everyDuaInThis_f790b4 =>
      'كل دعاء في هذه الآية - قال الله: قد فعلت';

  @override
  String get dhikrScreen_guardedByAllahUntil_f4d276 =>
      'في حراسة الله حتى يأتي الصباح';

  @override
  String get dhikrScreen_recitingEqualsReadingThe_e0a62a =>
      'القراءة 3x تعدل قراءة القرآن كاملا والبخاري ومسلم';

  @override
  String get dhikrScreen_reciteAtDawnDusk_4173a8 =>
      'وقل ثلاث مرات عند الفجر والمغرب تكفيك من كل سوء';

  @override
  String get dhikrScreen_refugeFromTheWhisperer_bdd280 =>
      'اعوذ بالله من الوسواس برب الناس';

  @override
  String get dhikrScreen_reciteMorningEveningYour_c464cb =>
      'وقل 3 مرات صباحا ومساءا يتم شكرك لله';

  @override
  String get dhikrScreen_sufficientAgainstEveryHarm_0a3206 =>
      'تكفي من كل ضرر تلاوة 3 مرات';

  @override
  String get dhikrScreen_doorsOfAllahMercy_937263 =>
      'أبواب رحمة الله مفتوحة لكم';

  @override
  String get dhikrScreen_worryAndSorrowLifted_fd1f04 =>
      'يرفع الهم والحزن بإذن الله';

  @override
  String get dhikrScreen_guardedInYourDeen_bb9b33 =>
      'تحرس في دينك الدنيا والآخرة';

  @override
  String get dhikrScreen_evilRepelledFromEvery_3f1588 => 'طارد الشر من كل جانب';

  @override
  String get dhikrScreen_heartHeldByThe_0f7007 =>
      'القلب الذي يحمله الحي الدائم الدائم';

  @override
  String get dhikrScreen_fulfilledYourObligationOf_44ddfc =>
      'أوفيت بواجب الشكر';

  @override
  String get dhikrScreen_recitingTheLastVerses_3d260d =>
      'تكفيك قراءة آخر آيتين من سورة البقرة في الليل';

  @override
  String get dhikrScreen_gratitudeThatMultipliesYour_24c5dd =>
      'الشكر الذي يضاعف نعمك';

  @override
  String get dhikrScreen_startPureOnThe_a0198e =>
      'ابدأوا خالصين على فطرة الإسلام';

  @override
  String get dhikrScreen_praiseThatRipplesThrough_cef105 =>
      'التسبيح الذي يسري في كل الخليقة';

  @override
  String get dhikrScreen_guidedToEveryGood_e5e914 =>
      'هدى إلى كل خير في هذا اليوم';

  @override
  String get dhikrScreen_allahWillFreeHim_20396f =>
      'أعتقه الله من النار من قرأها 4 مرات';

  @override
  String get dhikrScreen_wellbeingOfBodyHearing_f9d3af =>
      'سلامة الجسم من السمع والبصر';

  @override
  String get dhikrScreen_guidedByTheHand_da5d5b => 'الهداية بيد الله';

  @override
  String get dhikrScreen_wordsHeavierThanThe_6a9c4f =>
      'كلام أثقل من السماء والأرض';

  @override
  String get dhikrScreen_beginYourDayIn_530c07 => 'ابدأ يومك بالاستسلام لله';

  @override
  String get dhikrScreen_theyAreEnoughFor_14acc6 => 'تكفيك - أقرأ قبل النوم';

  @override
  String get dhikrScreen_wellBeing_85c1f4 => 'الرفاهية';

  @override
  String get dhikrScreen_fulfilled_7d487f => 'تم الوفاء به.';

  @override
  String get dhikrScreen_wellBeingInFaith_e70162 =>
      'الرفاهية في الإيمان · الأسرة · الثروة';

  @override
  String get dhikrScreen_concealMyFaultsCalm_0252f3 =>
      'أخفي عيوبي · هدئ مخاوفي';

  @override
  String get dhikrScreen_protectionFromEvilEye_3b6074 =>
      'الحماية من العين الشريرة';

  @override
  String get dhikrScreen_doNotLeaveMe_1e2414 => 'فلا تكلني إلى نفسي طرفة عين';

  @override
  String dhikrScreen_35c165_35c165(String arg1) {
    return '$arg1';
  }

  @override
  String get dhikrScreen_allahWillSufficeYou_f177b2 => 'الله يكفيك';

  @override
  String get dhikrScreen_againstWhateverConcernsYou_176991 => 'ضد كل ما يقلقك';

  @override
  String get dhikrScreen_doNotBurdenUs_4401b2 =>
      'ولا تحملنا ما لا طاقة لنا به واعف عنا وارحمنا';

  @override
  String get dhikrScreen_weHaveBelievedForgive_d34c4a =>
      'لقد آمنا فاغفر لنا ذنوبنا وقنا من النار';

  @override
  String get dhikrScreen_ownerOfSovereigntyIn_b0948c =>
      'يا مالك الملك بيدك الخير إنك أنت القادر';

  @override
  String get dhikrScreen_forgiveOurSinsAnd_692ad8 =>
      'واغفر ذنوبنا وإسرافنا وثبتنا وانصرنا';

  @override
  String get dhikrScreen_youCreatedNotIn_d24f50 =>
      'ما خلقت عبثا فقنا عذاب النار';

  @override
  String get dhikrScreen_weHaveWrongedOurselves_24ab82 =>
      'لقد ظلمنا أنفسنا فمن دون رحمتك ضللنا';

  @override
  String get dhikrScreen_ourLordDoNot_ca9f87 =>
      'ربنا لا تجعلنا مع القوم الظالمين';

  @override
  String get dhikrScreen_doNotMakeUs_d5b5d2 => 'ولا تجعلنا فتنة للظالمين';

  @override
  String get dhikrScreen_makeMeSteadfastIn_cc7dfe =>
      'وأثبتني على الصلاة وذريتي أيضًا';

  @override
  String get dhikrScreen_forgiveMeMyParents_1a319b =>
      'اغفر لي ولوالدي وللمؤمنين يوم الحساب';

  @override
  String get dhikrScreen_bringMeInBy_62c19a =>
      'أدخلني من مدخل الحق وأخرجني من مخرج الحق';

  @override
  String get dhikrScreen_myLordIncreaseMe_2fec5a => 'ربي زدني علما';

  @override
  String get dhikrScreen_seekRefugeInYou_3a2efd => 'وأعوذ بك من همزات الشياطين';

  @override
  String get dhikrScreen_forgiveAndHaveMercy_58f2df =>
      'اغفر وارحم وأنت خير الراحمين';

  @override
  String get dhikrScreen_enableMeToBe_e78eb3 =>
      'أوزعني أن أشكر نعمتك علي وعلى والدي';

  @override
  String get dhikrScreen_myLordHaveWronged_e6421b =>
      'ربي إني ظلمت نفسي فاغفر لي';

  @override
  String get dhikrScreen_myLordWillNever_d4a663 =>
      'ربي لا أكون ظهيراً للمجرمين';

  @override
  String get dhikrScreen_myLordSaveMe_ea6c67 => 'ربي نجني من القوم الظالمين';

  @override
  String get dhikrScreen_myLordAmIn_0acb2a =>
      'ربي إني محتاج إلى أي خير تنزله إلي';

  @override
  String get dhikrScreen_myLordHelpMe_80f8c7 => 'ربي انصرني على القوم المفسدين';

  @override
  String get dhikrScreen_ourLordAvertFrom_bc7354 => 'ربنا اصرف عنا عذاب الجحيم';

  @override
  String get dhikrScreen_ourLordYouEncompass_7e0f2a =>
      'ربنا وسعت كل شيء رحمة وعلما';

  @override
  String get dhikrScreen_enableMeToThank_d1f4df =>
      'أوزعني أن أشكرك وأصلح لي ذريتي';

  @override
  String get dhikrScreen_myLordGrantMe_ef9ff1 => 'ربي هب لي من الصالحين';

  @override
  String get dhikrScreen_forgiveUsAndOur_60d1fd =>
      'اغفر لنا ولإخواننا الذين سبقونا بالإيمان';

  @override
  String get dhikrScreen_uponYouWeRely_0c8229 =>
      'عليك توكلنا، وإليك أنبنا، وإليك المصير';

  @override
  String get dhikrScreen_pauseRememberAllah_1ddb4d => 'يوقف. اذكروا الله .';

  @override
  String get dhikrScreen_mashaallahRewardSecured_f51254 =>
      'ما شاء الله! المكافأة مضمونة';

  @override
  String get dhikrScreen_satanCannot_1c96dd => 'الشيطان لا يستطيع';

  @override
  String get dhikrScreen_enterTheHome_3086d7 => 'أدخل المنزل';

  @override
  String get dhikrScreen_whoeverRecites_ee68bc => 'من يقرأ';

  @override
  String get dhikrScreen_theLastTwoVerses_a865c4 => 'الآيتين الأخيرتين';

  @override
  String get dhikrScreen_ofSurahAlBaqarah_302bf4 => 'من سورة البقرة';

  @override
  String get dhikrScreen_atNight_f3945a => 'في الليل --';

  @override
  String get dhikrScreen_theyWillBe_019495 => 'سيكونون كذلك';

  @override
  String get dhikrScreen_enoughForHim_6e37aa => 'يكفي له';

  @override
  String get dhikrScreen_weHaveEnteredThe_f5ed3a => 'لقد دخلنا المساء';

  @override
  String get dhikrScreen_theKingdomBelongsTo_2f7681 => 'الملك لله';

  @override
  String get dhikrScreen_noneWorthyOfWorship_f1c87f =>
      'لا أحد يستحق العبادة إلا الله وحده';

  @override
  String get dhikrScreen_allPraiseHeIs_c3ece6 => 'الحمد · إنه على كل شيء قدير';

  @override
  String get dhikrScreen_weAskForThe_21b846 => 'نسألك خير هذه الليلة';

  @override
  String get dhikrScreen_saySeekRefuge_84c616 => 'قل : أعوذ';

  @override
  String get dhikrScreen_inTheLordOf_39c875 => 'في رب البشر';

  @override
  String get dhikrScreen_theKingOfMankind_d99354 => 'ملك البشرية';

  @override
  String get dhikrScreen_theGodOfMankind_e5231c => 'إله البشرية،';

  @override
  String get dhikrScreen_heRetreatsWhenYou_1fea37 => 'يتراجع عندما تذكر الله.';

  @override
  String get dhikrScreen_seekRefugeInThe_96a762 => 'اعوذ برب الفلق';

  @override
  String get dhikrScreen_sufficedInAllRespects_57c52b =>
      'يكفي من جميع النواحي.';

  @override
  String get dhikrScreen_allahDoesNotBurden_63f3eb => 'الله لا يثقل';

  @override
  String get dhikrScreen_soul_b7f1ee => 'روح';

  @override
  String dhikrScreen_a5cfd1_a5cfd1(String count) {
    return '×$count';
  }

  @override
  String get dhikrScreen_equalsTheWholeQuran_a2b879 => 'يساوي القرآن كله × 3';

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
  String impactReportScreen_lvl_987904(String _level, String arg1) {
    return 'المستوى $_level · $arg1';
  }

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
  String impactReportScreen_ayahs_6a500c(String arg1) {
    return '$arg1 الآيات';
  }

  @override
  String impactReportScreen_planted_90ec47(String arg1) {
    return '$arg1 مزروعة';
  }

  @override
  String impactReportScreen_cycles_f6649b(String arg1) {
    return '$arg1 دورات';
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
  String impactReportScreen_built_d62c2d(String arg1) {
    return '$arg1 بنيت';
  }

  @override
  String impactReportScreen_dividedByPalaces_6f066c(String arg1) {
    return 'مقسمة على 10 → القصور: $arg1';
  }

  @override
  String impactReportScreen_earned_abd189(String arg1) {
    return '$arg1 حصل';
  }

  @override
  String impactReportScreen_equivalent_cb7bb5(String arg1) {
    return '$arg1 يعادل';
  }

  @override
  String get impactReportScreen_laIlahaIllallahuWahdahu_895dde =>
      'لا إله إلا الله وحده لا شريك له...';

  @override
  String impactReportScreen_setsOfSetsSlaves_b43b31(String arg1, String arg2) {
    return 'مجموعات من 10 → $arg1 مجموعات × 4 عبيد = $arg2';
  }

  @override
  String impactReportScreen_opened_1bf8da(String arg1) {
    return '$arg1 مفتوح';
  }

  @override
  String impactReportScreen_received_a526e3(String arg1) {
    return 'تم استلام $arg1';
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
  String impactReportScreen_invocations_d80c33(String arg1) {
    return '$arg1 الدعوات';
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
  String impactReportScreen_recitations_3cb9ec(String arg1) {
    return '$arg1 تلاوات';
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
  String impactReportScreen_viewAllDonors_e72932(String arg1) {
    return 'عرض جميع الجهات المانحة $arg1';
  }

  @override
  String impactReportScreen_failed_190558(String e) {
    return 'فشل: $e';
  }

  @override
  String impactReportScreen_meet_82797d(String arg1, String arg2) {
    return 'تعرف على $arg1، $arg2';
  }

  @override
  String impactReportScreen_sponsor_a47417(String arg1) {
    return 'الراعي $arg1 →';
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
  String get levelScreen_customProfileThemes_cec15c =>
      'موضوعات الملف الشخصي المخصصة';

  @override
  String get levelScreen_exclusiveVotingRights_684759 => 'حقوق التصويت الحصرية';

  @override
  String get levelScreen_hallOfFameListing_eb6ad1 => 'قائمة قاعة المشاهير';

  @override
  String levelScreen_seeds_fff97b(String arg1) {
    return '+$arg1 البذور';
  }

  @override
  String get levelScreen_laIlahaIllallah_e8c26b => 'لا إله إلا الله x100';

  @override
  String levelScreen_unlocks_6f2513(String arg1) {
    return 'يفتح: $arg1';
  }

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
  String levelScreen_nextDays_212b86(String arg1, String arg2) {
    return 'التالي: $arg1 ($arg2 أيام)';
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
  String get phase1Screens_quranReadingNimage_5ebac0 => 'قراءة القرآن\\nصورة';

  @override
  String get phase1Screens_orphansNimage_24d12a => 'الصورة اليتيمة\\n';

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
  String get profileSettingsScreen_bosniaAndHerzegovina_a428ef =>
      'البوسنة والهرسك';

  @override
  String get profileSettingsScreen_centralAfricanRepublic_0fde6c =>
      'جمهورية أفريقيا الوسطى';

  @override
  String get profileSettingsScreen_unitedArabEmirates_d8e2d8 =>
      'الإمارات العربية المتحدة';

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
  String projectDetailScreen_viewAll_3d2c48(String arg1) {
    return 'عرض الكل $arg1 →';
  }

  @override
  String quranHubScreen_saved_9c28a3(String arg1) {
    return 'تم حفظ $arg1';
  }

  @override
  String get quranHubScreen_tapTheHeartBookmark_c62da1 =>
      'اضغط على أيقونة القلب/الإشارة المرجعية أثناء القراءة لحفظ الآيات.';

  @override
  String quranHubScreen_surahVerse_2c65ec(String s, String a) {
    return 'سورة __ص0__ • الآية __ص1__';
  }

  @override
  String quranHubScreen_verses_f97238(String arg1) {
    return '$arg1 الآيات';
  }

  @override
  String quranHubScreen_of_0420fc(String arg1) {
    return 'من $arg1';
  }

  @override
  String get quranScreen_englishSahihIntl_da5e9e => 'الإنجليزية، صحيح الدولي.';

  @override
  String get quranScreen_saheehInternational_fd1d5c => 'صحيح الدولية';

  @override
  String get quranScreen_englishPickthall_a0d265 => 'الإنجليزية، بيكثال';

  @override
  String get quranScreen_mohammadMarmadukePickthall_554557 =>
      'محمد مارمادوك بيكثال';

  @override
  String get quranScreen_englishTheMessage_24a984 => 'الإنجليزية، الرسالة';

  @override
  String get quranScreen_englishMuhsinKhan_a5402b => 'الإنجليزية، محسن خان';

  @override
  String get quranScreen_muhsinKhanHilali_471c43 => 'محسن خان وهلالي';

  @override
  String get quranScreen_fatehMuhammadJalandhry_262387 => 'فاتح محمد جلندري';

  @override
  String get quranScreen_imamAhmadRazaKhan_225277 => 'الإمام أحمد رضا خان';

  @override
  String get quranScreen_maulanaSayyidAbulAla_75d35f =>
      'مولانا السيد أبو العلاء المودودي';

  @override
  String get quranScreen_franAisHamidullah_2ca2c2 => 'فرانسيس، حميد الله';

  @override
  String get quranScreen_rkDiyanet_431130 => 'التركية، ديانت';

  @override
  String get quranScreen_rkLeymanAte_7aa8e1 => 'تركسي، سليمان اتيش';

  @override
  String get quranScreen_bahasaIndonesian_2a26f0 => 'البهاسا، الإندونيسية';

  @override
  String get quranScreen_ministryOfReligiousAffairs_e30db8 =>
      'وزارة الشؤون الدينية';

  @override
  String get quranScreen_muhiuddinKhan_df9bfe => 'تمام، محي الدين خان';

  @override
  String get quranScreen_deutschAbuRida_9acffd => 'دويتش، أبو ريدة';

  @override
  String get quranScreen_abuRidaMuhammadIbn_3a40b3 => 'أبو رضا محمد بن أحمد';

  @override
  String get quranScreen_espaOlAsad_1c1933 => 'اسبانيول، اسد';

  @override
  String get quranScreen_uthmaniMadinah_e1f10e => 'العثماني (المدينة المنورة)';

  @override
  String get quranScreen_alJalalaynEN_af0584 => 'الجلالين (EN)';

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
  String get quranScreen_trimmedContains_039f31 => ') && !مشذّب.يحتوي على(';

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
  String get quranScreen_comfortableNightTimeReading_da3df2 =>
      'قراءة مريحة ليلا';

  @override
  String quranScreen_pt_9e58e8(String arg1) {
    return '$arg1 نقطة';
  }

  @override
  String quranScreen_003843_003843(String arg1, String arg2) {
    return '$arg1 $arg2';
  }

  @override
  String get quranScreen_displayMeaningBelowEach_a26f31 =>
      'عرض المعنى تحت كل آية';

  @override
  String get quranScreen_showTransliteration_e04abd => 'إظهار الترجمة الصوتية';

  @override
  String get quranScreen_romanisedPronunciationUnderEach_2c0136 =>
      'النطق بالحروف اللاتينية تحت كل كلمة';

  @override
  String get quranScreen_progressBarAyahCount_3cd24d =>
      'شريط التقدم وبطاقة عدد الآيات';

  @override
  String get quranScreen_moveToNextVerse_ea29fd =>
      'الانتقال إلى الآية التالية عندما ينتهي الصوت';

  @override
  String get quranScreen_repeatCurrentVerse_552669 => 'كرر الآية الحالية';

  @override
  String get quranScreen_notificationsALERTS_fbea75 => 'الإخطارات والتنبيهات';

  @override
  String get quranScreen_milestoneSoundAlerts_03cdc3 => 'تنبيهات صوتية مهمة';

  @override
  String get quranScreen_chimeWhenYouReach_dd60c0 =>
      'رنين عندما تصل إلى 10، 25، 50 آية';

  @override
  String get quranScreen_showEachArabicWord_64532d =>
      'إظهار كل كلمة عربية بمعناها الإنجليزي';

  @override
  String get quranScreen_translationLanguage_d8c9b3 => 'لغة الترجمة';

  @override
  String quranScreen_translationsAvailable_55c648(String arg1) {
    return '$arg1 الترجمات المتاحة';
  }

  @override
  String quranScreen_3502e8_3502e8(String arg1, String arg2) {
    return '$arg1 / $arg2';
  }

  @override
  String quranScreen_sabiqSeedsEarnedToday_13ddb3(String _pointsToday) {
    return '+$_pointsToday بذور سابق التي حصلت عليها اليوم!';
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
  String quranScreen_pageJuz_6ac28a(String _currentPage, String arg1) {
    return 'الصفحة $_currentPage · الجزء $arg1';
  }

  @override
  String get startJourneyScreen_unexpectedErrorDuringGoogle_86c1a5 =>
      'حدث خطأ غير متوقع أثناء تسجيل الدخول إلى Google';

  @override
  String get startJourneyScreen_connectedToQuranCom_c0c631 =>
      'متصل بموقع القرآن الكريم';

  @override
  String streakScreen_nextDays_212b86(String arg1, String arg2) {
    return 'التالي: $arg1 ($arg2 أيام)';
  }

  @override
  String streakScreen_seeds_990893(String arg1) {
    return '+$arg1 البذور';
  }

  @override
  String streakScreen_days_100e10(String current, String arg1) {
    return '$current / $arg1 أيام';
  }

  @override
  String streakScreen_dayStreak_df2abf(String arg1) {
    return '$arg1 خط يوم';
  }

  @override
  String get tafsirHubScreen_earnSeedsForEvery_ffb3d5 =>
      'اربح بذورًا مقابل كل 10 دقائق من استماع التفسير';

  @override
  String get tafsirScreen_alJalalaynEN_af0584 => 'الجلالين (EN)';

  @override
  String tafsirScreen_verses_fed624(String arg1) {
    return '$arg1 الآيات';
  }

  @override
  String get tafsirScreen_trimmedContains_039f31 => ') && !مشذّب.يحتوي على(';

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
  String get tafsirScreen_tafsirNotAvailableFor_0fce81 =>
      'التفسير غير متوفر لهذه الآية.';

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
  String get liveNotificationService_remindersToSealYour_782a67 =>
      'تذكيرات لإغلاق بذورك المعلقة قبل منتصف الليل.';

  @override
  String get liveNotificationService_sealYourSeedsBefore_62a726 =>
      'ختم البذور الخاصة بك قبل منتصف الليل';

  @override
  String liveNotificationService_youHavePendingSeeds_dd762f(
    String pendingSeeds,
  ) {
    return 'لديك $pendingSeeds بذور معلقة. اضغط على ختم اليوم قبل منتصف الليل أو تنتهي صلاحيته.';
  }

  @override
  String liveNotificationService_ayatReadToday_b5a4e8(String _ayahCount) {
    return '$_ayahCount آيات إقرأها اليوم 📖';
  }

  @override
  String liveNotificationService_readQuranToday_703122(String arg1) {
    return '$arg1 إقرأ القرآن اليوم ⏱️';
  }

  @override
  String get liveNotificationService_nothingReadFromQuran_b1c2eb =>
      'لا شيء يقرأ من القرآن اليوم 📖';

  @override
  String liveNotificationService_dhikrCompletedToday_835583(
    String _dhikrCount,
  ) {
    return '$_dhikrCount تم الانتهاء من الأذكار اليوم 📿';
  }

  @override
  String liveNotificationService_ayatDhikrToday_548e91(
    String _ayahCount,
    String _dhikrCount,
  ) {
    return '$_ayahCount آيات · $_dhikrCount أذكار اليوم';
  }

  @override
  String get liveNotificationService_keepReadingAndDoing_cdc7b2 =>
      'استمر في القراءة والقيام بالذكر!';

  @override
  String get liveNotificationService_yourSeedsToday_8649c6 => 'بذورك اليوم ✨';

  @override
  String get localReminderScheduler_sabiqRewardsNotifications_96d36c =>
      'إشعارات مكافآت سابق';

  @override
  String get localReminderScheduler_it_0c8340 => 'هو - هي\\';

  @override
  String get localReminderScheduler_fridayReadSurahAl_077436 =>
      'يوم الجمعة - قراءة سورة الكهف';

  @override
  String get localReminderScheduler_whoeverRecitesSurahAl_15b9a5 =>
      'من قرأ سورة الكهف في يوم الجمعة أضاء له من النور ما بين الجمعتين.';

  @override
  String get localReminderScheduler_don_b4d354 => 'اِتَّشَح\\';

  @override
  String get localReminderScheduler_missSurahAlKahf_634857 =>
      'لا تفوت سورة الكهف اليوم';

  @override
  String get localReminderScheduler_fewHoursToMaghrib_d99fd2 =>
      'ساعات قليلة تفصلنا عن المغرب – أكمل سورة الكهف إذا لم تكن قد وصلت';

  @override
  String get quranApiService_notConnectedToQuran_9f4f89 =>
      'غير متصل بموقع القرآن الكريم';

  @override
  String quranApiService_syncFailedBookmarkCould_3393f7(String failed) {
    return 'فشلت المزامنة، تعذر دفع الإشارة (الإشارات) المرجعية $failed إلى موقع Quran.com (التحقق من الرمز المميز / نقطة النهاية).';
  }

  @override
  String get quranApiService_bookmarksAlreadyInSync_fad9e1 =>
      'الإشارات المرجعية متزامنة بالفعل';

  @override
  String quranApiService_syncedBookmarksUpDown_dd2f96(
    String total,
    String uploaded,
    String downloaded,
  ) {
    return 'الإشارات المرجعية $total المتزامنة ($uploaded لأعلى، $downloaded لأسفل)';
  }

  @override
  String quranApiService_syncFailed_ae7629(String e) {
    return 'فشلت المزامنة: $e';
  }

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
  String streakService_dayStreak_9ee8a3(String arg1, String arg2) {
    return '$arg1-يوم $arg2 خط ·';
  }

  @override
  String streakService_bonusSeedsUnlocked_bcdda5(String arg1) {
    return '+$arg1 تم فتح البذور الإضافية';
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
  String get xpService_you_79d09a => 'أنت\\';

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
  String get motivationalPopup_youHaveBeenRewarded_9bde33 =>
      'لقد تمت مكافأتك على\\nثباتك اليوم!';

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
  String get noorOffline_somethingWentWrong_76fc46 => 'حدث خطأ ما';

  @override
  String get notificationsSheet_stayOnTopOf_811366 =>
      'البقاء على رأس المكافآت والمعالم';

  @override
  String get notificationsSheet_llBeNotifiedAbout_9e7a1b =>
      'سيتم إعلامك بشأن المكافآت والخطوط والمعالم.';

  @override
  String get notificationsSheet_inboxKeepsExistingItems_611668 =>
      'يحتفظ Inbox بالعناصر الموجودة ولكن لن تصل عناصر جديدة.';

  @override
  String get notificationsSheet_sabiqSeedsForSealing_001312 =>
      'بذور سابق لختم اليوم';

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
  String streakService_dayStreak_b49b65(Object arg1, Object arg2) {
    return '$arg1-يوم $arg2 خط ·';
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
