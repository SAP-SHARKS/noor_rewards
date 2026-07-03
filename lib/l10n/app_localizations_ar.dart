// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get youSuffix => '(you)';

  @override
  String get userFallback => 'User';

  @override
  String get youHaveDone => 'You\'ve Done!';

  @override
  String get playAllBtn => 'Play All';

  @override
  String get playBtn => 'Play';

  @override
  String get readBtn => 'Read';

  @override
  String get readOnce => 'Read once';

  @override
  String readNTimes(int count) {
    return 'Read $count times';
  }

  @override
  String seedsEarnedToday(int count) {
    return '+$count Sabiq Seeds earned today!';
  }

  @override
  String get catDailyRemembrance => 'DAILY REMEMBRANCE';

  @override
  String get catNightlyRemembrance => 'NIGHTLY REMEMBRANCE';

  @override
  String get catYourSelection => 'YOUR SELECTION';

  @override
  String get catContinuousRemembrance => 'CONTINUOUS REMEMBRANCE';

  @override
  String get bannerDailyRemembrance =>
      'Daily Remembrance\nbrings peace to the soul.';

  @override
  String get bannerMorningAdhkar =>
      'Morning Adhkar\nbrings peace to the soul and light to the path.';

  @override
  String get bannerEveningAdhkar =>
      'Evening Adhkar\nbrings tranquility and protection for the night.';

  @override
  String get bannerYourSelection =>
      'Your beloved words\nof remembrance to keep close to your heart.';

  @override
  String get bannerContinuousRemembrance =>
      'Remember Allah\nmuch, that you may be successful.';

  @override
  String get frequentlyReadByCommunity => 'Frequently read';

  @override
  String get viewFullLeaderboard => 'View full leaderboard';

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
  String get noorRewards => 'Sabiq Rewards';

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
    return '+$pts Sabiq Seeds';
  }

  @override
  String get yourGarden => 'حديقتك';

  @override
  String get noorPointsBloomed => 'Sabiq Seeds bloomed';

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
  String get notificationsSubtitle => 'Stay on top of rewards & milestones';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get clearAll => 'Clear all';

  @override
  String get notificationsOn => 'Notifications on';

  @override
  String get notificationsOff => 'Notifications off';

  @override
  String get allCaughtUp => 'All caught up';

  @override
  String get whenYouEarnRewards =>
      'When you earn rewards, hit a streak, or unlock a badge,\nit\'ll show up here.';

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
  String get newBadgeUnlocked => 'New badge unlocked';

  @override
  String get daySealed => 'Day sealed';

  @override
  String get dailyLoginBonus => 'Daily login bonus';

  @override
  String get oneWeek => 'One Week';

  @override
  String get twoWeeks => 'Two Weeks';

  @override
  String badgeEarnedDesc(String badge) {
    return 'You\'ve earned the \"$badge\" badge.';
  }

  @override
  String pointsForSealing(String points) {
    return '+$points Sabiq Seeds for sealing today.';
  }

  @override
  String welcomeBack(String points) {
    return '+$points Sabiq Seeds · welcome back!';
  }

  @override
  String get onbV2Skip => 'Skip';

  @override
  String get onbV2Next => 'Next';

  @override
  String get onbV2_1_TitleA => 'Your Quran reading';

  @override
  String get onbV2_1_TitleB => 'feeds the hungry.';

  @override
  String get onbV2_1_Sub => 'Real meals. Real people. Real impact.';

  @override
  String get onbV2_1_Cta => 'How does that work?';

  @override
  String get onbV2_2_Title => 'Here\'s how.';

  @override
  String get onbV2_2_Body =>
      'Read Quran or recite dhikr → earn Sabiq Seeds → fund real causes.';

  @override
  String get onbV2_3_TitleA => 'The Quran rewards you';

  @override
  String get onbV2_3_TitleB => 'twice.';

  @override
  String get onbV2_3_Sub =>
      'Once with Allah\'s blessing. Once with Seeds that feed the needy.';

  @override
  String get onbV2_3_BannerLabel => 'earned today';

  @override
  String get onbV2_4_TitleA => 'See your worship';

  @override
  String get onbV2_4_TitleB => 'come to life.';

  @override
  String get onbV2_4_Sub =>
      'Recite morning and evening dhikr, and watch your reward unfold, hadith by hadith.';

  @override
  String get onbV2_5_TitleA => 'Your reading reaches';

  @override
  String get onbV2_5_TitleB => 'here.';

  @override
  String get onbV2_5_Sub =>
      'Every Seed you earn becomes real food, real water, real hope.';

  @override
  String get onbV2_6_TitleA => 'But where does the';

  @override
  String get onbV2_6_TitleB => 'money';

  @override
  String get onbV2_6_TitleC => 'come from?';

  @override
  String get onbV2_6_Sub =>
      'Generous donors fund the causes. Your Seeds direct where their gift goes, and grow their reward with every reader.';

  @override
  String get onbV2_6_Donor => 'Donor';

  @override
  String get onbV2_6_DonorSub => 'Funds the cause';

  @override
  String get onbV2_6_You => 'You';

  @override
  String get onbV2_6_YouSub => 'Direct the gift';

  @override
  String get onbV2_6_Charity => 'Charity';

  @override
  String get onbV2_6_CharitySub => 'Delivers aid';

  @override
  String get onbV2_6_TrustBadge => '100% disbursed to verified partners';

  @override
  String get onbV2_7_TitleA => 'Every deed is';

  @override
  String get onbV2_7_TitleB => 'counted.';

  @override
  String get onbV2_7_Sub =>
      'See the akhirah account you\'re building, trees, palaces, freed souls, rooted in authentic hadith.';

  @override
  String get onbV2_8_TitleA => 'Let\'s begin with your';

  @override
  String get onbV2_8_TitleB => 'name.';

  @override
  String get onbV2_8_Sub => 'So Sabiq feels like yours.';

  @override
  String get onbV2_8_Placeholder => 'Your name';

  @override
  String get onbV2_8_Cta => 'Continue';

  @override
  String get onbV2_9_TitleA => 'Which cause moves you';

  @override
  String get onbV2_9_TitleB => 'most?';

  @override
  String get onbV2_9_Sub =>
      'Your Seeds support all causes, this just helps us understand what matters to our community.';

  @override
  String get onbV2_9_Cta => 'Begin';

  @override
  String get onbV2_9_Orphans => 'Orphans';

  @override
  String get onbV2_9_OrphansSub =>
      'Feed and care for children who\'ve lost everything';

  @override
  String get onbV2_9_Water => 'Water Wells';

  @override
  String get onbV2_9_WaterSub => 'Clean water for villages in need';

  @override
  String get onbV2_9_War => 'War-Impacted Areas';

  @override
  String get onbV2_9_WarSub => 'Relief where it\'s needed most';

  @override
  String get onbV2_9_Disaster => 'Natural Disasters';

  @override
  String get onbV2_9_DisasterSub => 'Rapid response when crisis strikes';

  @override
  String get onbV2_3step_Title => 'Three simple steps.';

  @override
  String get onbV2_3step_Sub => 'Every verse, every dhikr becomes real aid.';

  @override
  String get onbV2_3step_S1Label => 'Step 1';

  @override
  String get onbV2_3step_S1Text => 'Read Quran';

  @override
  String get onbV2_3step_S2Label => 'Step 2';

  @override
  String get onbV2_3step_S2Text => 'Earn Seeds';

  @override
  String get onbV2_3step_S3Label => 'Step 3';

  @override
  String get onbV2_3step_S3Text => 'Feed Orphans';

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
  String get dunyaArabic => 'Dunya';

  @override
  String get hereafter => 'الآخرة';

  @override
  String get akhirahArabic => 'Akhirah';

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
  String get authScreen_pleaseEnterYourEmail => 'Please enter your email';

  @override
  String get authScreen_pleaseEnterYourPassword => 'Please enter your password';

  @override
  String get authScreen_passwordMustBeAt =>
      'Password must be at least 6 characters';

  @override
  String get authScreen_alreadyHaveAnAccount =>
      'Already have an account? Sign In';

  @override
  String get authScreen_haveAnAccountSign => 't have an account? Sign Up';

  @override
  String qfAuthService_qfemailconflictexceptionAlreadyHasAn(String email) {
    return 'QfEmailConflictException: $email already has an account';
  }

  @override
  String get qfAuthService_openidOfflineAccessUser =>
      'openid offline_access user bookmark collection reading_session';

  @override
  String qfAuthService_tokenExchangeFailed(String arg1, String arg2) {
    return 'Token exchange failed ($arg1): $arg2';
  }

  @override
  String get qfAuthService_errorNullResponse => 'ERROR: Null response';

  @override
  String orphan_be2bf7(String firstName, String lastInitial) {
    return '$firstName $lastInitial.';
  }

  @override
  String get akhirahBalanceScreen_subhanallahiWaBiHamdihi =>
      '“Subhanallahi wa bi-hamdihi” — said 100 times a day wipes sins, even like the foam of the sea. (Bukhari)';

  @override
  String get akhirahBalanceScreen_sayLaIlahaIllallah =>
      'Say La ilaha illallah 100 times — equals freeing 10 slaves and 100 hasanat. (Bukhari)';

  @override
  String get akhirahBalanceScreen_lightOnTheTongue =>
      'Light on the tongue, heavy on the scales: Subhanallahi wa bi-hamdihi, Subhanallahil-azim. (Bukhari 6406)';

  @override
  String get akhirahBalanceScreen_theDhikrOfAllah =>
      'The dhikr of Allah is heavier on the scales than gold of equal weight. Keep going.';

  @override
  String get akhirahBalanceScreen_yourTongueShouldStay =>
      '“Your tongue should stay moist with the remembrance of Allah.” — Is it still moist?';

  @override
  String get akhirahBalanceScreen_astaghfirullahTheProphetSaid =>
      'Astaghfirullah — the Prophet ✍ said it 100 times a day, and he had no sin. How many have you?';

  @override
  String get akhirahBalanceScreen_whenYouRememberAllah =>
      'When you remember Allah quietly, He remembers you in an assembly far greater.';

  @override
  String get akhirahBalanceScreen_reciteAyatAlKursi =>
      'Recite Ayat al-Kursi after every salah — nothing keeps you from Jannah but death.';

  @override
  String get akhirahBalanceScreen_oneAlhamdulillahFillsThe =>
      'One Alhamdulillah fills the scale. One Subhanallah fills what is between heaven and earth.';

  @override
  String get akhirahBalanceScreen_theRemembranceOfAllah =>
      '“The remembrance of Allah is greater than everything else.” — Surah Al-Ankabut 29:45';

  @override
  String get akhirahBalanceScreen_rememberMeWillRemember =>
      '“Remember Me — I will remember you.” — Surah Al-Baqarah 2:152. Will you?';

  @override
  String get akhirahBalanceScreen_inTheRemembranceOf =>
      '“In the remembrance of Allah, hearts find rest.” — Surah Ar-Ra’d 13:28';

  @override
  String get akhirahBalanceScreen_fiveMinutesOfDhikr =>
      'Five minutes of dhikr now shapes the next 24 hours of your heart.';

  @override
  String get akhirahBalanceScreen_streakIsnAboutToday =>
      'A streak isn’t about today — it’s about who you become in 30 days.';

  @override
  String get akhirahBalanceScreen_smallDropsFillAn =>
      'Small drops fill an ocean. Your daily dhikr is filling something far bigger.';

  @override
  String get akhirahBalanceScreen_noOneSeesThe =>
      'No one sees the dhikr in your heart — but every angel writing your record does.';

  @override
  String get akhirahBalanceScreen_theBiggestWinsAre =>
      'The biggest wins are built from the smallest daily habits. Don’t break the chain.';

  @override
  String get akhirahBalanceScreen_youCameBackToday =>
      'You came back today. That’s already worship. Stay one more minute?';

  @override
  String get akhirahBalanceScreen_tomorrowPeaceIsBuilt =>
      'Tomorrow’s peace is built on today’s remembrance. Plant one more seed.';

  @override
  String get akhirahBalanceScreen_areYouDoneAllah =>
      'Are you done? Allah’s door is always open — even after you’ve closed it.';

  @override
  String get akhirahBalanceScreen_dhikrIsTheLanguage =>
      'Dhikr is the language of the heart. Has yours spoken to its Lord today?';

  @override
  String get akhirahBalanceScreen_everySubhanallahIsSadaqah =>
      'Every Subhanallah is a sadaqah. How many will you give before sleep?';

  @override
  String get akhirahBalanceScreen_heartThatForgetsDhikr =>
      'A heart that forgets dhikr begins to rust. A heart that remembers stays alight.';

  @override
  String get akhirahBalanceScreen_haveYouFortifiedYourself =>
      'Have you fortified yourself with the morning and evening adhkar today?';

  @override
  String akhirahBalanceScreen_thisSession(String arg1) {
    return 'This session: +$arg1';
  }

  @override
  String akhirahBalanceScreen_seedsThisSession(String arg1) {
    return '+$arg1 seeds this session';
  }

  @override
  String akhirahBalanceScreen_dayAvgAzkaarDay(String arg1) {
    return '7-day avg: $arg1 azkaar/day';
  }

  @override
  String dashboardScreen_profileReturnedZeroRows(String uid) {
    return 'Profile returned zero rows for $uid';
  }

  @override
  String dashboardScreen_dashboardLoadError(String e) {
    return 'Dashboard Load Error: $e';
  }

  @override
  String get dashboardScreen_invalidReferralCode => 'Invalid referral code';

  @override
  String get dashboardScreen_cannotReferYourself => 'Cannot refer yourself';

  @override
  String dashboardScreen_sponsor(String name, String arg1) {
    return 'Sponsor $name, $arg1';
  }

  @override
  String get dashboardScreen_dashboardDoesn => ': 0, // dashboard doesn';

  @override
  String dashboardScreen_today(
    String arg1,
    String _lastAyah,
    String _ayahsToday,
  ) {
    return '$arg1 · $_lastAyah  · +$_ayahsToday today';
  }

  @override
  String dashboardScreen_606140(String arg1, String _lastAyah) {
    return '$arg1 · $_lastAyah';
  }

  @override
  String dashboardScreen_setsToday(String _dhikrToday) {
    return '$_dhikrToday sets today';
  }

  @override
  String dashboardScreen_dayStreak(String arg1) {
    return '$arg1-day streak';
  }

  @override
  String dashboardScreen_last(String arg1) {
    return 'Last: $arg1';
  }

  @override
  String get dashboardScreen_earnPerFriend => 'Earn +500 per friend';

  @override
  String get dashboardScreen_yourSabiqSeedsFund =>
      'Your Sabiq Seeds fund these projects';

  @override
  String dashboardScreen_active(String arg1) {
    return '$arg1 active';
  }

  @override
  String get dashboardScreen_joinMeOnSabiq =>
      'Join me on Sabiq Rewards, earn Seeds for daily Quran, Dhikr & good deeds!\\n\\n';

  @override
  String dashboardScreen_useMyCodeAnd(String arg1) {
    return 'Use my code *$arg1* and we both get 500 Sabiq Seeds!\\n\\n';
  }

  @override
  String get dashboardScreen_messageCopiedShareOr =>
      'Message copied, share or paste in WhatsApp!';

  @override
  String get dashboardScreen_sabiqSeedsRewardedTo =>
      '500 Sabiq Seeds rewarded to you both!';

  @override
  String get dashboardScreen_youHaveAlreadyUsed =>
      'You have already used a referral code.';

  @override
  String get dashboardScreen_invalidReferralCode_59fb25 =>
      'Invalid referral code.';

  @override
  String get dashboardScreen_youCannotUseYour =>
      'You cannot use your own code.';

  @override
  String get dashboardScreen_anErrorOccurredPlease =>
      'An error occurred. Please try again.';

  @override
  String dashboardScreen_52b02c(String pts) {
    return '$pts ';
  }

  @override
  String dashboardScreen_e4e562(String arg1) {
    return '$arg1%';
  }

  @override
  String get dashboardScreen_seeDetailsForMore =>
      'See Details for more Projects →';

  @override
  String get dashboardScreen_yourTOTALSABIQSEEDS => 'YOUR TOTAL SABIQ SEEDS';

  @override
  String get dashboardScreen_viewCampaignDonate => '🤲  View Campaign & Donate';

  @override
  String dashboardScreen_yourRank(String rankText) {
    return 'Your Rank: $rankText';
  }

  @override
  String dashboardScreen_d13a42(String _myPoints, String unit, String arg1) {
    return '$_myPoints $unit • $arg1';
  }

  @override
  String get dashboardScreen_beTheFirstOn => 'Be the first on the board';

  @override
  String get dashboardScreen_readAnAyahOr =>
      'Read an ayah or dhikr to claim the top spot';

  @override
  String dashboardScreen_lvl(String level, String arg1) {
    return 'Lvl $level · $arg1';
  }

  @override
  String dashboardScreen_sealWithin(String arg1) {
    return 'Seal within ${arg1}h';
  }

  @override
  String get dashboardScreen_jazakallahDaySealed => 'JazakAllah!  Day sealed';

  @override
  String dashboardScreen_ofGoal(String arg1, String arg2) {
    return 'of $arg1 $arg2 goal';
  }

  @override
  String get dhikrHubScreen_propheticSupplications => 'Prophetic Supplications';

  @override
  String get dhikrHubScreen_morningEveningRemembrance =>
      'Morning & Evening Remembrance';

  @override
  String get dhikrHubScreen_furtherSupplications => 'Further Supplications';

  @override
  String get dhikrHubScreen_closingRemembranceSalawat =>
      'Closing Remembrance & Salawat';

  @override
  String get dhikrHubScreen_hajjUmrahSupplications =>
      'Hajj & Umrah Supplications';

  @override
  String get dhikrHubScreen_falseHiddenAdd => '] == false) hidden.add(r[';

  @override
  String get dhikrScreen_indoPak => 'Indo pak';

  @override
  String dhikrScreen_default(String recommendedCount) {
    return 'Default: $recommendedCount';
  }

  @override
  String get dhikrScreen_duaAzkarSettings => 'Dua & Azkar Settings';

  @override
  String get dhikrScreen_hideTheVisualArtwork => 'Hide the visual artwork area';

  @override
  String get dhikrScreen_pinTheIllustrationAt =>
      'Pin the illustration at the top while the Arabic text scrolls beneath it';

  @override
  String dhikrScreen_readTimes(String readCount) {
    return 'Read $readCount times';
  }

  @override
  String dhikrScreen_d08433(String arg1, String arg2) {
    return '$arg1 / $arg2';
  }

  @override
  String get dhikrScreen_alBaqarahAmanaAr => 'Al-Baqarah 285 (Amana ar-Rasool)';

  @override
  String get dhikrScreen_alBaqarahAlifLam => 'Al-Baqarah 1-5 (Alif Lam Mim)';

  @override
  String get dhikrScreen_alBaqarahLaIkraha => 'Al-Baqarah 256 (La Ikraha)';

  @override
  String get dhikrScreen_alBaqarahAllahuWaliyy =>
      'Al-Baqarah 257 (Allahu Waliyy)';

  @override
  String get dhikrScreen_salawatIbrahimiyyaDurood =>
      'Salawat Ibrahimiyya (Durood)';

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
  String get dhikrScreen_hisnulMuslimChapter => 'Hisnul Muslim, Chapter: ';

  @override
  String dhikrScreen_3856c1(String rawRef, String bottomRef) {
    return '$rawRef | $bottomRef';
  }

  @override
  String get dhikrScreen_bestOfBothWorlds =>
      'Best of both worlds, refuge from the Fire';

  @override
  String get dhikrScreen_patienceAndSteadfastnessIn =>
      'Patience and steadfastness in every trial';

  @override
  String get dhikrScreen_allahBurdensNoSoul =>
      'Allah burdens no soul beyond its capacity';

  @override
  String get dhikrScreen_keepTheHeartFirm =>
      'Keep the heart firm upon guidance';

  @override
  String get dhikrScreen_faithAnsweredWithForgiveness =>
      'Faith answered with forgiveness from Hell';

  @override
  String get dhikrScreen_allSovereigntyInAllah => 'All sovereignty in Allah\\';

  @override
  String get dhikrScreen_allahHearsEveryCall =>
      'Allah hears every call for righteous offspring';

  @override
  String get dhikrScreen_countedWithTheWitnesses =>
      'Counted with the witnesses of truth';

  @override
  String get dhikrScreen_forgivenessFirmFeetAnd =>
      'Forgiveness, firm feet, and victory';

  @override
  String get dhikrScreen_theDuaOfThose => 'The dua of those who reflect';

  @override
  String get dhikrScreen_inscribedWithTheWitnesses =>
      'Inscribed with the witnesses of revelation';

  @override
  String get dhikrScreen_theDuaAllahAccepted =>
      'The dua Allah accepted from Adam ﷺ';

  @override
  String get dhikrScreen_spareUsTheCompany =>
      'Spare us the company of wrongdoers';

  @override
  String get dhikrScreen_neverTrialForThe => 'Never a trial for the oppressors';

  @override
  String get dhikrScreen_refugeFromAskingWithout =>
      'Refuge from asking without knowledge';

  @override
  String get dhikrScreen_prayerForSafetyAnd => 's prayer for safety and faith';

  @override
  String get dhikrScreen_steadfastInPrayerMe =>
      'Steadfast in prayer, me and my children';

  @override
  String get dhikrScreen_mercyForMeMy =>
      'Mercy for me, my parents, the believers';

  @override
  String get dhikrScreen_prayerForParents => 's prayer for parents';

  @override
  String get dhikrScreen_entryOfTruthExit => 'Entry of truth, exit of truth';

  @override
  String get dhikrScreen_prayerOfTheYouth => 'Prayer of the youth of the cave';

  @override
  String get dhikrScreen_askAllahForMore => 'Ask Allah for more — of knowledge';

  @override
  String get dhikrScreen_allahAnswersAndSaves =>
      'Allah answers and saves from every distress';

  @override
  String get dhikrScreen_allahIsTheBest => 'Allah is the best of inheritors';

  @override
  String get dhikrScreen_blessedLandingWhereverYou =>
      'A blessed landing wherever you stop';

  @override
  String get dhikrScreen_refugeFromTheWhispers =>
      'Refuge from the whispers of devils';

  @override
  String get dhikrScreen_mercyFromTheBest =>
      'Mercy from the Best of the Merciful';

  @override
  String get dhikrScreen_pardonAndMercyFrom =>
      'Pardon and mercy from the Most Merciful';

  @override
  String get dhikrScreen_piousSpousesAndRighteous =>
      'Pious spouses and righteous offspring';

  @override
  String get dhikrScreen_prayerForThoseWho => ' prayer for those who repent';

  @override
  String get dhikrScreen_gratitudeForParentsRighteousness =>
      'Gratitude for parents, righteousness in offspring';

  @override
  String get dhikrScreen_pleaGiftOfIshaq => 's plea — gift of Ishaq ﷺ';

  @override
  String get dhikrScreen_loveForTheBelievers =>
      'Love for the believers before us';

  @override
  String get dhikrScreen_pureTawakkulOnYou =>
      's pure tawakkul — On You we rely';

  @override
  String get dhikrScreen_forgivenessForEveryBelieving =>
      'Forgiveness for every believing home';

  @override
  String get dhikrScreen_tasbeehByTheWeight =>
      'Tasbeeh by the weight of Allah\\';

  @override
  String get dhikrScreen_tasbeehByTheNumber =>
      'Tasbeeh by the number of all that He made';

  @override
  String get dhikrScreen_tasbeehThatFillsAll =>
      'Tasbeeh that fills all that Allah created';

  @override
  String get dhikrScreen_paradiseSoughtTheFire =>
      'Paradise sought — the Fire\\';

  @override
  String get dhikrScreen_cryToTheOne =>
      'Cry to the One who hears, sees, and knows';

  @override
  String get dhikrScreen_nameOnTheCorner => 's name on the corner of the Kaaba';

  @override
  String get dhikrScreen_theDuaBetweenYemen =>
      'The dua between Yemen Corner and Black Stone';

  @override
  String get dhikrScreen_prayAtTheStation => 'Pray at the station of Ibrahim ﷺ';

  @override
  String get dhikrScreen_tawheedDeclaredAtopSafa =>
      'Tawheed declared atop Safa and Marwah';

  @override
  String get dhikrScreen_reaffirmTheOnenessOf =>
      'Reaffirm the Oneness of Allah';

  @override
  String get dhikrScreen_magnifyAllahAtEvery =>
      'Magnify Allah at every threshold of Hajj';

  @override
  String get dhikrScreen_magnifyAllahOnThe =>
      'Magnify Allah on the day of sacrifice';

  @override
  String get dhikrScreen_knowledgeProvisionHealingSought =>
      'Knowledge, provision, healing — sought in Makkah';

  @override
  String get dhikrScreen_theDuaMostRepeated =>
      'The dua most repeated by the Prophet ﷺ';

  @override
  String get dhikrScreen_refugeFromEveryTrial =>
      'Refuge from every trial of life and death';

  @override
  String get dhikrScreen_refugeFromEveryWeakness =>
      'Refuge from every weakness of body and soul';

  @override
  String get dhikrScreen_refugeFromSevereTrial =>
      'Refuge from severe trial and enemy\\';

  @override
  String get dhikrScreen_religionSetRightWorld =>
      'Religion set right, world and Akhirah made best';

  @override
  String get dhikrScreen_guidancePietyVirtueSelf =>
      'Guidance, piety, virtue, self-sufficiency';

  @override
  String get dhikrScreen_refugeFromWeaknessWealth =>
      'Refuge from weakness — wealth of piety within';

  @override
  String get dhikrScreen_theGuiderOfHearts =>
      'The Guider of hearts — turn ours to obedience';

  @override
  String get dhikrScreen_turnerOfHeartsMake =>
      'Turner of hearts — make mine firm on the deen';

  @override
  String get dhikrScreen_wellBeingInBoth => 'Well-being in both worlds';

  @override
  String get dhikrScreen_rewardsSaveFromDisgrace =>
      'Rewards, save from disgrace and grave\\';

  @override
  String get dhikrScreen_mindForGoodVictory =>
      'Mind for good, victory for good';

  @override
  String get dhikrScreen_refugeFromEvilOf =>
      'Refuge from evil of every sense and limb';

  @override
  String get dhikrScreen_theForgiverWhoLoves =>
      'The Forgiver who loves the repentant';

  @override
  String get dhikrScreen_takeMeBeforeYou => 'Take me before You take me astray';

  @override
  String get dhikrScreen_everyGoodAndRefuge =>
      'Every good — and refuge from every evil';

  @override
  String get dhikrScreen_standingSittingLyingGuarded =>
      'Standing, sitting, lying — guarded in Islam';

  @override
  String get dhikrScreen_refugeFromCowardiceMiserliness =>
      'Refuge from cowardice, miserliness, fitnah';

  @override
  String get dhikrScreen_forgivenessForJestAnd =>
      'Forgiveness for jest and serious, known and unknown';

  @override
  String get dhikrScreen_forgiveMeWithForgiveness =>
      'Forgive me with a forgiveness from You';

  @override
  String get dhikrScreen_submissionBeliefRepentanceFull =>
      'Submission, belief, repentance, full trust';

  @override
  String get dhikrScreen_mercyForgivenessParadiseSaved =>
      'Mercy, forgiveness, Paradise — saved from the Fire';

  @override
  String get dhikrScreen_refugeFromEvilSeen =>
      'Refuge from evil seen and unseen';

  @override
  String get dhikrScreen_provisionThatLastsTill =>
      'Provision that lasts till life\\';

  @override
  String get dhikrScreen_sinsForgivenHomeSpacious =>
      'Sins forgiven, home spacious, provision blessed';

  @override
  String get dhikrScreen_favorAndMercyNone =>
      'Favor and mercy — none possesses them but You';

  @override
  String get dhikrScreen_refugeFromDrowningBurning =>
      'Refuge from drowning, burning, sudden death';

  @override
  String get dhikrScreen_refugeFromHypocrisyShowiness =>
      'Refuge from hypocrisy, showiness, rebellion';

  @override
  String get dhikrScreen_refugeFromPovertyScarcity =>
      'Refuge from poverty, scarcity, oppression';

  @override
  String get dhikrScreen_refugeFromHeartThat =>
      'Refuge from a heart that won\\';

  @override
  String get dhikrScreen_payMyDebtEnrich =>
      'Pay my debt, enrich me from poverty';

  @override
  String get dhikrScreen_allahCalledByHis =>
      'Allah called by His most beautiful names';

  @override
  String get dhikrScreen_theAccepterOfRepentance =>
      'The Accepter of repentance always accepts';

  @override
  String get dhikrScreen_anEasyReckoningOn => 'An easy reckoning on the Day';

  @override
  String get dhikrScreen_remembranceGratitudeAndThe =>
      'Remembrance, gratitude, and the best worship';

  @override
  String get dhikrScreen_eternalBlissWithThe =>
      'Eternal bliss with the Prophet ﷺ in Firdaws';

  @override
  String get dhikrScreen_forgiveSinsKnownHidden =>
      'Forgive sins — known, hidden, intended, mistaken';

  @override
  String get dhikrScreen_refugeFromBeingCrushed =>
      'Refuge from being crushed by debt and enemy';

  @override
  String get dhikrScreen_askForParadiseRefuge =>
      'Ask for Paradise, refuge from the Fire';

  @override
  String get dhikrScreen_forgiveGuideProvideProtect =>
      'Forgive, guide, provide, protect';

  @override
  String get dhikrScreen_sensesMadeBeneficialAnd =>
      'Senses made beneficial — and lasting';

  @override
  String get dhikrScreen_theMostBeneficentThe =>
      'The Most Beneficent, the Originator of all';

  @override
  String get dhikrScreen_allahTruthOwnerOf =>
      'Allah — Truth, Owner of all dominion';

  @override
  String get dhikrScreen_submissionWithFullSincerity =>
      'Submission with full sincerity';

  @override
  String get dhikrScreen_amongTheGuidedThe =>
      'Among the guided, the healthy, the chosen';

  @override
  String get dhikrScreen_whatTheProphetAsked =>
      'What the Prophet ﷺ asked — I ask too';

  @override
  String get dhikrScreen_sayyidAlIstighfarThe =>
      'Sayyid al-Istighfar — the master of all repentance';

  @override
  String get dhikrScreen_refugeFromEveryEvil =>
      'Refuge from every evil that comes by night';

  @override
  String get dhikrScreen_blessEverySenseEvery =>
      'Bless every sense, every limb';

  @override
  String get dhikrScreen_smallAndGreatFirst =>
      'Small and great, first and last, open and secret';

  @override
  String get dhikrScreen_noneWithholdsWhatYou =>
      'None withholds what You give, none gives what You hold';

  @override
  String get dhikrScreen_forgiveGuideProvideElevate =>
      'Forgive, guide, provide, elevate';

  @override
  String get dhikrScreen_increaseFavorBeKind =>
      'Increase favor, be kind, never displeased';

  @override
  String get dhikrScreen_beautifyOurCharacterAs =>
      'Beautify our character as You beautified our creation';

  @override
  String get dhikrScreen_firmInBeliefGuided =>
      'Firm in belief — guided and guiding';

  @override
  String get dhikrScreen_wisdomAndWithIt =>
      'Wisdom — and with it, multitudes of good';

  @override
  String get dhikrScreen_nameShieldsFromEvery =>
      's name shields from every harm';

  @override
  String get dhikrScreen_mightAgainstEveryShaytan =>
      's might against every Shaytan';

  @override
  String get dhikrScreen_dayBlessedFromBeginning =>
      'A day blessed from beginning to end';

  @override
  String get dhikrScreen_witnessNoneDeservesWorship =>
      'Witness — none deserves worship but You';

  @override
  String get dhikrScreen_refugeFromHumiliatingOld =>
      'Refuge from a humiliating old age';

  @override
  String get dhikrScreen_guidedToTheBest =>
      'Guided to the best, saved from the worst';

  @override
  String get dhikrScreen_faithSetRightHome =>
      'Faith set right, home wide, provision blessed';

  @override
  String get dhikrScreen_refugeFromEveryInner =>
      'Refuge from every inner and outer disease';

  @override
  String get dhikrScreen_refugeFromEveryKind =>
      'Refuge from every kind of bad end';

  @override
  String get dhikrScreen_steadfastGratefulRightlyGuided =>
      'Steadfast, grateful, rightly-guided heart';

  @override
  String get dhikrScreen_theLoveOfAllah =>
      'The love of Allah, His angels, His prophets';

  @override
  String get dhikrScreen_loveOfAllahAbove => 'Love of Allah above love of self';

  @override
  String get dhikrScreen_bestDeedsLastBest =>
      'Best deeds last — best day is meeting You';

  @override
  String get dhikrScreen_pureLifeAndPeaceful =>
      'A pure life and a peaceful return';

  @override
  String get dhikrScreen_patientGratefulSmallIn =>
      'Patient, grateful — small in own eyes';

  @override
  String get dhikrScreen_theBestRequestAnd =>
      'The best request and the best reward';

  @override
  String get dhikrScreen_theHighestLevelOf => 'The highest level of Paradise';

  @override
  String get dhikrScreen_firdawsTheBestOf => 'Firdaws — the best of all that\\';

  @override
  String get dhikrScreen_mentionRaisedSinsErased =>
      'Mention raised, sins erased, heart purified';

  @override
  String get dhikrScreen_blessEverySenseEvery_b81b9b =>
      'Bless every sense, every limb, every deed';

  @override
  String get dhikrScreen_mercyPleasureParadiseSaved =>
      'Mercy, pleasure, Paradise — saved from Fire';

  @override
  String get dhikrScreen_noSinUncoveredNo => 'No sin uncovered, no debt unpaid';

  @override
  String get dhikrScreen_mercyThatGuidesSets =>
      'Mercy that guides, sets right, purifies';

  @override
  String get dhikrScreen_trueBeliefCertainKnowledge =>
      'True belief, certain knowledge, Allah\\';

  @override
  String get dhikrScreen_withTheProphetsThe =>
      'With the Prophets, the martyrs, the truthful';

  @override
  String get dhikrScreen_everyNeedEntrustedTo =>
      'Every need entrusted to the Judge of all needs';

  @override
  String get dhikrScreen_bestOfWhatAllah =>
      'Best of what Allah promised His servants';

  @override
  String get dhikrScreen_safetyOnTheDay =>
      'Safety on the Day, Paradise on the Eternal Day';

  @override
  String get dhikrScreen_glorifyTheOneOf =>
      'Glorify the One of unmatched honor and knowledge';

  @override
  String get dhikrScreen_pardonPlentySecurityIn =>
      'Pardon, plenty, security in deen and dunya';

  @override
  String get dhikrScreen_healthFaithEthicsSuccess =>
      'Health, faith, ethics, success, mercy';

  @override
  String get dhikrScreen_healthPurityEthicsAcceptance =>
      'Health, purity, ethics, acceptance';

  @override
  String get dhikrScreen_guidedSecureVictorious => 'Guided, secure, victorious';

  @override
  String get dhikrScreen_refugeFromEveryCreature =>
      'Refuge from every creature in Allah\\';

  @override
  String get dhikrScreen_theOneWhoAnswers =>
      'The One who answers the compelled and broken';

  @override
  String get dhikrScreen_morningReachedByAllah => 'Morning reached by Allah\\';

  @override
  String get dhikrScreen_refugeSoughtByMusa =>
      'Refuge sought by Musa, Isa, Ibrahim';

  @override
  String get dhikrScreen_allTheGoodPower =>
      'All the good — power, mercy, blessings';

  @override
  String get dhikrScreen_allPraiseAndDominion =>
      'All praise and dominion belong to You';

  @override
  String get dhikrScreen_pastPardonedFutureProtected =>
      'Past pardoned, future protected';

  @override
  String get dhikrScreen_takeMyForelockTo => 'Take my forelock to goodness';

  @override
  String get dhikrScreen_strengthForWeaknessDignity =>
      'Strength for weakness, dignity for shame';

  @override
  String get dhikrScreen_justiceForThoseWho =>
      'Justice for those who block the truth';

  @override
  String get dhikrScreen_refugeFromEveryFatal =>
      'Refuge from every fatal calamity';

  @override
  String get dhikrScreen_refugeFromEveryBad =>
      'Refuge from every bad end and trial';

  @override
  String get dhikrScreen_turnBackEveryEvil =>
      'Turn back every evil intention to its source';

  @override
  String get dhikrScreen_justiceAndRefugeAgainst =>
      'Justice and refuge against their evils';

  @override
  String get dhikrScreen_forgivenessForMeMy =>
      'Forgiveness for me, my parents, all believers';

  @override
  String get dhikrScreen_purifyHeartDeedsTongue =>
      'Purify heart, deeds, tongue, eyes';

  @override
  String get dhikrScreen_selfContentWithAllah => 'A self content with Allah\\';

  @override
  String get dhikrScreen_youKnowMySecret => 'You know my secret and my need';

  @override
  String get dhikrScreen_certaintyNothingHarmsWhat =>
      'Certainty: nothing harms what\\';

  @override
  String get dhikrScreen_beliefLightAndLawful =>
      'Belief, light, and lawful provision';

  @override
  String get dhikrScreen_totalLoveAndTotal =>
      'Total love and total struggle for Allah';

  @override
  String get dhikrScreen_makeWhatYouWithheld =>
      'Make what You withheld a strength in obedience';

  @override
  String get dhikrScreen_praiseTheOwnerOf =>
      'Praise the Owner of every beautiful name';

  @override
  String get dhikrScreen_allahKnowsTheHearts =>
      'Allah knows the hearts, the heavens, and beyond';

  @override
  String get dhikrScreen_hopeBuiltOnAllah => 'Hope built on Allah\\';

  @override
  String get dhikrScreen_belovedToTheBelievers =>
      'Beloved to the believers, free from the wicked';

  @override
  String get dhikrScreen_mightPowerAndMajesty => 's might, power, and majesty';

  @override
  String get dhikrScreen_gratefulPatientHelpfulTo =>
      'Grateful, patient, helpful to Allah\\';

  @override
  String get dhikrScreen_withholdYourGoodFor =>
      't withhold Your good for my evil';

  @override
  String get dhikrScreen_settledLifeAmpleProvision =>
      'A settled life, ample provision, righteous deeds';

  @override
  String get dhikrScreen_wealthInNeedingYou =>
      'Wealth in needing You — never free of You';

  @override
  String get dhikrScreen_defectsCoveredFearsCalmed =>
      'Defects covered, fears calmed, anguish lifted';

  @override
  String get dhikrScreen_openTheGatesOf =>
      'Open the gates of mercy and generosity';

  @override
  String get dhikrScreen_holdUsInYour =>
      'Hold us in Your safety — never abandon us';

  @override
  String get dhikrScreen_withinYourSecurityYour =>
      'Within Your security, Your goodness';

  @override
  String get dhikrScreen_everySinEveryDistress =>
      'Every sin, every distress, every side';

  @override
  String get dhikrScreen_helpInDeathIn =>
      'Help in death, in the grave, on the Bridge';

  @override
  String get dhikrScreen_beautifiedLifeBlessedGifts =>
      'Beautified life, blessed gifts, kept favors';

  @override
  String get dhikrScreen_firmFootingBlessedEnd =>
      'Firm footing, blessed end, kept covenant';

  @override
  String get dhikrScreen_hopesFulfilledEnemiesRepelled =>
      'Hopes fulfilled, enemies repelled, affairs set right';

  @override
  String get dhikrScreen_guidedToTheUpright =>
      'Guided to the upright, protected from the self';

  @override
  String get dhikrScreen_lightAndForgivenessFrom =>
      'Light and forgiveness from the Owner of the Throne';

  @override
  String get dhikrScreen_forgivenessForWhatRepented =>
      'Forgiveness for what I repented and returned to';

  @override
  String get dhikrScreen_understandingThatDrawsNear =>
      'Understanding that draws near to Allah';

  @override
  String get dhikrScreen_soulsDwellingInThe =>
      'Souls dwelling in the heights of piety';

  @override
  String get dhikrScreen_crossTheBridgeOf =>
      'Cross the bridge of desire by patience';

  @override
  String get dhikrScreen_followThePathOf =>
      'Follow the path of sincerity and certainty';

  @override
  String get dhikrScreen_helpAgainstTheSoul =>
      'Help against the soul and against Shaytan';

  @override
  String get dhikrScreen_fearHappinessVictorySecurity =>
      'Fear, happiness, victory, security';

  @override
  String get dhikrScreen_entrustFamilyWealthChildren =>
      'Entrust family, wealth, children — all to Allah';

  @override
  String get dhikrScreen_faithGuardedFaithPreserved =>
      'Faith guarded, faith preserved';

  @override
  String get dhikrScreen_wellBeingTillThe =>
      'Well-being till the end — sealed with forgiveness';

  @override
  String get dhikrScreen_whatProtectsMeFrom =>
      'What protects me from this world\\';

  @override
  String get dhikrScreen_mercyOnEverySoul => 'Mercy on every soul\\';

  @override
  String get dhikrScreen_burdenUsAsThose =>
      't burden us as those before were burdened';

  @override
  String get dhikrScreen_mercyPardonForgivenessVictory =>
      'Mercy, pardon, forgiveness, victory';

  @override
  String get dhikrScreen_keepTheHeartFirm_9c4efb =>
      'Keep the heart firm after guidance';

  @override
  String get dhikrScreen_allahNeverFailsHis => 'Allah never fails His promise';

  @override
  String get dhikrScreen_faithAnsweredWithForgiveness_3f30c4 =>
      'Faith answered with forgiveness from Fire';

  @override
  String get dhikrScreen_recordUsWithThe =>
      'Record us with the witnesses of truth';

  @override
  String get dhikrScreen_forgivenessFirmnessAndVictory =>
      'Forgiveness, firmness, and victory';

  @override
  String get dhikrScreen_creationHasPurposeRefuge =>
      'Creation has purpose — refuge from the Fire';

  @override
  String get dhikrScreen_refugeFromTheDisgrace =>
      'Refuge from the disgrace of the Fire';

  @override
  String get dhikrScreen_heardBelievedAskingForgiveness =>
      'Heard, believed, asking forgiveness';

  @override
  String get dhikrScreen_sinsForgivenDeathAmong =>
      'Sins forgiven — death among the righteous';

  @override
  String get dhikrScreen_promisedRewardNeverDisgraced =>
      'Promised reward — never disgraced on Resurrection';

  @override
  String get dhikrScreen_inscribedWithTheWitnesses_e2612d =>
      'Inscribed with the witnesses of truth';

  @override
  String get dhikrScreen_provisionAndSignsFrom =>
      'Provision and signs from the heavens';

  @override
  String get dhikrScreen_duaTheDuaOf => 's dua — the dua of every repentant';

  @override
  String get dhikrScreen_spareUsFromThe =>
      'Spare us from the company of wrongdoers';

  @override
  String get dhikrScreen_allahIsTheBest_4f2bf7 =>
      'Allah is the best judge between truth and lie';

  @override
  String get dhikrScreen_patienceTillTheEnd =>
      'Patience till the end, death upon submission';

  @override
  String get dhikrScreen_neverTrialForThe_5eb10a =>
      'Never a trial for the disbelievers';

  @override
  String get dhikrScreen_hiddenInEveryChest => 's hidden in every chest';

  @override
  String get dhikrScreen_prayerForPrayerAccepted =>
      's prayer for prayer accepted';

  @override
  String get dhikrScreen_mercyGrantedGuidancePrepared =>
      'Mercy granted, guidance prepared';

  @override
  String get dhikrScreen_duaBeforePharaoh => 's dua before Pharaoh';

  @override
  String get dhikrScreen_refugeFromClingingEvil =>
      'Refuge from a clinging, evil punishment';

  @override
  String get dhikrScreen_piousSpousesRighteousChildren =>
      'Pious spouses, righteous children, leadership';

  @override
  String get dhikrScreen_allahIsEverThankful =>
      'Allah is ever-thankful for every effort';

  @override
  String get dhikrScreen_mercyEncompassingEveryRepentant =>
      'Mercy encompassing every repentant soul';

  @override
  String get dhikrScreen_mercyOnThatDay =>
      'Mercy on that Day — the great success';

  @override
  String get dhikrScreen_loveAndForgivenessFor =>
      'Love and forgiveness for earlier believers';

  @override
  String get dhikrScreen_kindnessAndMercyUpon =>
      'Kindness and mercy upon Allah\\';

  @override
  String get dhikrScreen_pureTawakkulToYou =>
      's pure tawakkul — to You we return';

  @override
  String get dhikrScreen_neverFitnahForThose =>
      'Never a fitnah for those who disbelieve';

  @override
  String get dhikrScreen_completeTheLightForgive =>
      'Complete the light — forgive us';

  @override
  String get dhikrScreen_strongerThanServantThe =>
      'Stronger than a servant — the night\\';

  @override
  String get dhikrScreen_refugeFromEveryVisible =>
      'Refuge from every visible evil before sleep';

  @override
  String get dhikrScreen_refugeFromEveryWhisper =>
      'Refuge from every whisper before sleep';

  @override
  String get dhikrScreen_guardedByAnAngel =>
      'Guarded by an angel until morning';

  @override
  String get dhikrScreen_twoVersesThatSuffice =>
      'Two verses that suffice for the whole night';

  @override
  String get dhikrScreen_pureTawheedDeclaredBefore =>
      'Pure tawheed declared before sleep';

  @override
  String get dhikrScreen_sleepIsSmallDeath =>
      'Sleep is a small death — entrusted to Allah';

  @override
  String get dhikrScreen_whoeverDiesThatNight =>
      'Whoever dies that night dies on fitrah';

  @override
  String get dhikrScreen_guardTheSoulThat =>
      'Guard the soul that returns, or have mercy';

  @override
  String get dhikrScreen_refugeFromThePunishment =>
      'Refuge from the punishment of that Day';

  @override
  String get dhikrScreen_gratitudeForShelterFood =>
      'Gratitude for shelter, food, and care';

  @override
  String get dhikrScreen_handOverTheSoul => 'Hand over the soul before sleep';

  @override
  String get dhikrScreen_refugeFromEveryEvil_6d2534 =>
      'Refuge from every evil that grasps';

  @override
  String get dhikrScreen_joinTheHighestAssembly =>
      'Join the highest assembly while you sleep';

  @override
  String get dhikrScreen_gratitudeBeforeClosingThe =>
      'Gratitude before closing the eyes';

  @override
  String get dhikrScreen_surahAsSajdahRecited =>
      'Surah As-Sajdah recited before sleep';

  @override
  String get dhikrScreen_refugeFromEvilBefore =>
      'Refuge from evil before entering the toilet';

  @override
  String get dhikrScreen_seekForgivenessAsYou =>
      'Seek forgiveness as you leave';

  @override
  String get dhikrScreen_bismillahEveryBiteBegins =>
      'Bismillah — every bite begins with Allah';

  @override
  String get dhikrScreen_catchUpTheName =>
      'Catch up the name — Allah at start and end';

  @override
  String get dhikrScreen_threeSunnahDuasTo =>
      'Three Sunnah duas to thank Allah after eating';

  @override
  String get dhikrScreen_beginWithAllahThe =>
      'Begin with Allah, the Most Merciful, before drinking';

  @override
  String get dhikrScreen_openTheEightDoors =>
      'Open the eight doors of Paradise after wudu';

  @override
  String get dhikrScreen_openTheDoorsOf => 'Open the doors of Allah\\';

  @override
  String get dhikrScreen_bountyAsYouLeave => 's bounty as you leave the masjid';

  @override
  String get dhikrScreen_mayAllahGuideYou =>
      'May Allah guide you and rectify your state';

  @override
  String get dhikrScreen_askAllahLordOf =>
      'Ask Allah, Lord of the Throne, to grant healing';

  @override
  String get dhikrScreen_allahIsTheOnly => 'Allah is the only One who cures';

  @override
  String get dhikrScreen_shieldChildrenWithAllah =>
      'Shield children with Allah\\';

  @override
  String get dhikrScreen_anicPrayerForOne => 'anic prayer for one\\';

  @override
  String get dhikrScreen_twoPhrasesBelovedTo =>
      'Two phrases beloved to the Most Merciful';

  @override
  String get dhikrScreen_allahLovesToPardon => 'Allah loves to pardon — so ask';

  @override
  String get dhikrScreen_treasureFromBeneathThe =>
      'A treasure from beneath the Throne';

  @override
  String get dhikrScreen_theFourPhrasesDearest =>
      'The four phrases dearest to Allah';

  @override
  String get dhikrScreen_theDuaThatReleases =>
      'The dua that releases from every distress';

  @override
  String get dhikrScreen_protectionForHomeAnd =>
      's protection for home and offspring';

  @override
  String get dhikrScreen_theCompleteDhikrOf => 'The complete dhikr of Tawheed';

  @override
  String get dhikrScreen_trialPurifiedByAllah => 'Trial purified by Allah\\';

  @override
  String get dhikrScreen_guidanceBeforeAnyChoice =>
      's guidance before any choice';

  @override
  String get dhikrScreen_completeRuqyaSequenceFatihah =>
      'Complete ruqya sequence — Fatihah and refuge';

  @override
  String get dhikrScreen_sinsForgivenEvenIf =>
      'Sins forgiven, even if like the foam of the sea';

  @override
  String get dhikrScreen_freedHasanatSinsErased =>
      '10 freed · 100 hasanat · 100 sins erased · Shaytan repelled';

  @override
  String get dhikrScreen_blessingsDescendFromAllah =>
      '10 blessings descend from Allah upon you';

  @override
  String get dhikrScreen_askAllahToBless =>
      'Ask Allah to bless and beautify your day';

  @override
  String get dhikrScreen_guaranteedJannahIfYou =>
      'Guaranteed Jannah, if you die this day';

  @override
  String get dhikrScreen_guaranteedJannahIfYou_48d274 =>
      'Guaranteed Jannah, if you die this night';

  @override
  String get dhikrScreen_yourLifeEntrustedTo =>
      'Your life entrusted to the Ever-Living';

  @override
  String get dhikrScreen_allEvilInHis =>
      'All evil in His creation repelled from you';

  @override
  String get dhikrScreen_nothingShallHarmYou =>
      'Nothing shall harm you, by perfect words';

  @override
  String get dhikrScreen_shieldYourselfFromMinor =>
      'Shield yourself from minor and major shirk, morning & evening';

  @override
  String get dhikrScreen_completeProtectionInThe =>
      'Complete protection in the name of Allah';

  @override
  String get dhikrScreen_weightierThanAllVoluntary =>
      'Weightier than all voluntary prayers, from dawn till dusk';

  @override
  String get dhikrScreen_reciteMorningEveningEarn =>
      'Recite morning & evening, earn the pleasure & blessing of Allah on the Day of Judgment';

  @override
  String get dhikrScreen_yourRewardAwaitsDirectly =>
      'Your reward awaits directly with Allah when you meet Him';

  @override
  String get dhikrScreen_reciteMorningEveningTo =>
      'Recite morning & evening to fulfill your obligation of gratitude to Allah';

  @override
  String get dhikrScreen_theProphetTaughtThis =>
      'The Prophet taught this dua for morning and evening, do not miss it';

  @override
  String get dhikrScreen_dominionAtTheStart =>
      's dominion at the start of your morning, all kingdom belongs to Him';

  @override
  String get dhikrScreen_asEveningFallsThe =>
      'As evening falls, the entire kingdom belongs to Allah alone';

  @override
  String get dhikrScreen_endYourEveningUpon =>
      'End your evening upon the pure fitrah, as the Prophet (ﷺ) taught';

  @override
  String get dhikrScreen_satanWillNotEnter =>
      'Satan will not enter the home of one who recites this';

  @override
  String get dhikrScreen_readingLastVersesOf =>
      'Reading last 2 verses of al-Baqarah will suffice you';

  @override
  String get dhikrScreen_everyDuaInThis =>
      'Every dua in this verse - Allah said: I have done so';

  @override
  String get dhikrScreen_guardedByAllahUntil =>
      'Guarded by Allah until morning comes';

  @override
  String get dhikrScreen_recitingEqualsReadingThe =>
      'Reciting 3x equals reading the entire Quran, Bukhari & Muslim';

  @override
  String get dhikrScreen_reciteAtDawnDusk =>
      'Recite 3x at dawn & dusk, suffice you against all harm';

  @override
  String get dhikrScreen_reciteAtDawnDusk_f17fb8 =>
      'Recite 3x at dawn & dusk, it will suffice you in all respects';

  @override
  String get dhikrScreen_refugeFromTheWhisperer =>
      'Refuge from the whisperer, in the Lord of Mankind';

  @override
  String get dhikrScreen_reciteMorningEveningYour =>
      'Recite 3x morning & evening, your gratitude to Allah is fulfilled';

  @override
  String get dhikrScreen_sufficientAgainstEveryHarm =>
      'Sufficient against every harm recited 3 times';

  @override
  String get dhikrScreen_doorsOfAllahMercy =>
      'Doors of Allah mercy open wide for you';

  @override
  String get dhikrScreen_worryAndSorrowLifted =>
      'Worry and sorrow lifted by the will of Allah';

  @override
  String get dhikrScreen_guardedInYourDeen =>
      'Guarded in your deen dunya and akhirah';

  @override
  String get dhikrScreen_evilRepelledFromEvery =>
      'Evil repelled from every direction';

  @override
  String get dhikrScreen_heartHeldByThe =>
      'Heart held by the Ever Living Ever Sustaining';

  @override
  String get dhikrScreen_fulfilledYourObligationOf =>
      'Fulfilled your obligation of giving thanks';

  @override
  String get dhikrScreen_recitingTheLastVerses =>
      'Reciting the last 2 verses of Al-Baqarah at night suffices you';

  @override
  String get dhikrScreen_gratitudeThatMultipliesYour =>
      'Gratitude that multiplies your blessings';

  @override
  String get dhikrScreen_startPureOnThe => 'Start pure on the fitrah of Islam';

  @override
  String get dhikrScreen_praiseThatRipplesThrough =>
      'Praise that ripples through all creation';

  @override
  String get dhikrScreen_guidedToEveryGood => 'Guided to every good this day';

  @override
  String get dhikrScreen_nothingShallHarmYou_8c5c6c =>
      'Nothing shall harm you by His name';

  @override
  String get dhikrScreen_allahWillFreeHim =>
      'Allah will free him from the Fire who reads this 4 times';

  @override
  String get dhikrScreen_guaranteedJannahIfYou_0ffafe =>
      'Guaranteed Jannah if you die today';

  @override
  String get dhikrScreen_wellbeingOfBodyHearing =>
      'Wellbeing of body hearing and sight';

  @override
  String get dhikrScreen_guidedByTheHand => 'Guided by the hand of Allah';

  @override
  String get dhikrScreen_wordsHeavierThanThe =>
      'Words heavier than the heavens and earth';

  @override
  String get dhikrScreen_beginYourDayIn =>
      'Begin your day in surrender to Allah';

  @override
  String get dhikrScreen_theyAreEnoughFor =>
      'They are enough for you - recite before sleep';

  @override
  String get dhikrScreen_guardedInYourDeen_4a0b4a =>
      'Guarded in your Deen · Dunya · Akhirah, and from all six sides';

  @override
  String get dhikrScreen_wellBeing => 'Well-being';

  @override
  String get dhikrScreen_fulfilled => 'Fulfilled.';

  @override
  String get dhikrScreen_wellBeingInFaith =>
      'Well-being in Faith · Family · Wealth';

  @override
  String get dhikrScreen_concealMyFaultsCalm =>
      'Conceal my faults · Calm my fears';

  @override
  String get dhikrScreen_guardMeFromAll => 'Guard me from all six sides';

  @override
  String get dhikrScreen_protectionFromEvilEye => 'Protection from Evil Eye';

  @override
  String get dhikrScreen_doNotLeaveMe =>
      'Do not leave me to myself\\neven for the blink of an eye';

  @override
  String dhikrScreen_35c165(String arg1) {
    return '$arg1  ';
  }

  @override
  String get dhikrScreen_allahWillSufficeYou => 'Allah will suffice you';

  @override
  String get dhikrScreen_againstWhateverConcernsYou =>
      'against whatever concerns you';

  @override
  String get dhikrScreen_sinsWashedAway => 'Sins Washed Away';

  @override
  String get dhikrScreen_slavesFreed => 'Slaves Freed';

  @override
  String get dhikrScreen_doNotBurdenUs =>
      'Do not burden us beyond what we can bear, pardon us and have mercy';

  @override
  String get dhikrScreen_weHaveBelievedForgive =>
      'We have believed — forgive our sins and protect us from the Fire';

  @override
  String get dhikrScreen_ownerOfSovereigntyIn =>
      'O Owner of Sovereignty — in Your Hand is all good, You are Most Capable';

  @override
  String get dhikrScreen_forgiveOurSinsAnd =>
      'Forgive our sins and excess, make us firm and grant us victory';

  @override
  String get dhikrScreen_youCreatedNotIn =>
      'You created not in vain — protect us from the punishment of the Fire';

  @override
  String get dhikrScreen_weHaveWrongedOurselves =>
      'We have wronged ourselves — without Your mercy we are lost';

  @override
  String get dhikrScreen_ourLordDoNot =>
      'Our Lord, do not place us with the wrongdoing people';

  @override
  String get dhikrScreen_doNotMakeUs =>
      'Do not make us a trial for the oppressors';

  @override
  String get dhikrScreen_makeMeSteadfastIn =>
      'Make me steadfast in prayer — and my descendants too';

  @override
  String get dhikrScreen_forgiveMeMyParents =>
      'Forgive me, my parents, and the believers on the Day of Reckoning';

  @override
  String get dhikrScreen_bringMeInBy =>
      'Bring me in by an entrance of truth and out by an exit of truth';

  @override
  String get dhikrScreen_myLordIncreaseMe =>
      'My Lord, increase me in knowledge';

  @override
  String get dhikrScreen_seekRefugeInYou =>
      'I seek refuge in You from the whispers of devils';

  @override
  String get dhikrScreen_weHaveBelievedForgive_e958e6 =>
      'We have believed — forgive us, You are the Best of the Merciful';

  @override
  String get dhikrScreen_forgiveAndHaveMercy =>
      'Forgive and have mercy — You are the Best of the Merciful';

  @override
  String get dhikrScreen_enableMeToBe =>
      'Enable me to be grateful for Your favour on me and my parents';

  @override
  String get dhikrScreen_myLordHaveWronged =>
      'My Lord, I have wronged myself — so forgive me';

  @override
  String get dhikrScreen_myLordWillNever =>
      'My Lord, I will never be a supporter of the criminals';

  @override
  String get dhikrScreen_myLordSaveMe =>
      'My Lord, save me from the wrongdoing people';

  @override
  String get dhikrScreen_myLordAmIn =>
      'My Lord, I am in need of any good You send down to me';

  @override
  String get dhikrScreen_myLordHelpMe =>
      'My Lord, help me against the corrupting people';

  @override
  String get dhikrScreen_ourLordAvertFrom =>
      'Our Lord, avert from us the punishment of Hell';

  @override
  String get dhikrScreen_ourLordYouEncompass =>
      'Our Lord, You encompass all things in mercy and knowledge';

  @override
  String get dhikrScreen_enableMeToThank =>
      'Enable me to thank You and make my offspring righteous';

  @override
  String get dhikrScreen_myLordGrantMe => 'My Lord, grant me of the righteous';

  @override
  String get dhikrScreen_forgiveUsAndOur =>
      'Forgive us and our brothers who came before us in faith';

  @override
  String get dhikrScreen_uponYouWeRely =>
      'Upon You we rely, to You we turn, and to You is the destination';

  @override
  String get dhikrScreen_pauseRememberAllah => 'Pause. Remember Allah.';

  @override
  String get dhikrScreen_mashaallahRewardSecured =>
      'MashaAllah! Reward Secured';

  @override
  String get dhikrScreen_satanCannot => 'Satan cannot';

  @override
  String get dhikrScreen_enterTheHome => 'enter the home';

  @override
  String get dhikrScreen_whoeverRecites => 'Whoever recites';

  @override
  String get dhikrScreen_theLastTwoVerses => 'the last two verses';

  @override
  String get dhikrScreen_ofSurahAlBaqarah => 'of Surah Al-Baqarah';

  @override
  String get dhikrScreen_atNight => 'at night --';

  @override
  String get dhikrScreen_theyWillBe => 'they will be';

  @override
  String get dhikrScreen_enoughForHim => 'enough for him';

  @override
  String get dhikrScreen_weHaveEnteredThe => 'We have entered the evening';

  @override
  String get dhikrScreen_theKingdomBelongsTo => 'The Kingdom belongs to Allah';

  @override
  String get dhikrScreen_noneWorthyOfWorship =>
      'None worthy of worship but Allah alone';

  @override
  String get dhikrScreen_allPraiseHeIs =>
      'All praise · He is All-Powerful over everything';

  @override
  String get dhikrScreen_weAskForThe => 'We ask for the good of this night';

  @override
  String get dhikrScreen_saySeekRefuge => 'Say: I seek refuge';

  @override
  String get dhikrScreen_inTheLordOf => 'in the Lord of Mankind';

  @override
  String get dhikrScreen_theKingOfMankind => 'the King of Mankind';

  @override
  String get dhikrScreen_theGodOfMankind => 'the God of Mankind ,';

  @override
  String get dhikrScreen_heRetreatsWhenYou =>
      'He retreats when you remember Allah.';

  @override
  String get dhikrScreen_seekRefugeInThe =>
      'Seek refuge in the Lord of Daybreak';

  @override
  String get dhikrScreen_sufficedInAllRespects => 'Sufficed in all respects.';

  @override
  String get dhikrScreen_allahDoesNotBurden => 'Allah does not burden';

  @override
  String get dhikrScreen_soul => 'a soul';

  @override
  String dhikrScreen_a5cfd1(String count) {
    return '×$count';
  }

  @override
  String get dhikrScreen_equalsTheWholeQuran => 'Equals the whole Quran × 3';

  @override
  String get dhikrScreen_completeToWatchYour =>
      'Complete to watch your garden bloom above';

  @override
  String get impactReportScreen_whoeverDoesAnAtom => '“Whoever does an atom\\';

  @override
  String get impactReportScreen_theHomeOfThe =>
      '“The home of the Hereafter — that is the eternal life, if only they knew.” — Surah Al-Ankabut 29:64';

  @override
  String get impactReportScreen_raceTowardsForgivenessFrom =>
      '“Race towards forgiveness from your Lord and a Garden as wide as the heavens and the earth.” — Surah Al-Hadid 57:21';

  @override
  String get impactReportScreen_andWhatIsThe =>
      '“And what is the life of this world except amusement of delusion?” — Surah Ali Imran 3:185';

  @override
  String get impactReportScreen_indeedWithHardshipComes =>
      '“Indeed, with hardship comes ease.” — Surah Ash-Sharh 94:6';

  @override
  String get impactReportScreen_singleGoodDeedIn =>
      '“A single good deed in Ramadan equals 70 in any other month.” Stack while the door is open.';

  @override
  String get impactReportScreen_theProphetSaidCharity =>
      'The Prophet ✍ said: charity does not decrease wealth — it grows it. (Muslim)';

  @override
  String get impactReportScreen_smilingAtYourBrother =>
      '“Smiling at your brother is sadaqah.” You can earn even when your pockets are empty. (Tirmidhi)';

  @override
  String get impactReportScreen_theMostBelovedDeeds =>
      '“The most beloved deeds to Allah are the most consistent, even if small.” (Bukhari)';

  @override
  String get impactReportScreen_inJannahIsWhat =>
      '“In Jannah is what no eye has seen, no ear has heard, and no heart has imagined.” (Bukhari)';

  @override
  String get impactReportScreen_twoRakatsAtFajr =>
      'Two rakats at Fajr are better than the world and everything in it. (Muslim)';

  @override
  String get impactReportScreen_everyStepTowardSalah =>
      'Every step toward salah erases a sin and raises a rank. (Muslim)';

  @override
  String get impactReportScreen_everySeedYouDonate =>
      'Every seed you donate plants a tree in someone else\\';

  @override
  String get impactReportScreen_takeWealthWithYou =>
      't take wealth with you. Only the deeds it bought.';

  @override
  String get impactReportScreen_theAngelsRecordNothing =>
      'The angels record nothing too small. One Subhanallah may outweigh a mountain.';

  @override
  String get impactReportScreen_sadaqahIsTomorrow => 's sadaqah is tomorrow\\';

  @override
  String get impactReportScreen_heartThatGivesIs =>
      'A heart that gives is a heart Allah keeps full. Don\\';

  @override
  String get impactReportScreen_theReceiptWhatDid =>
      's the receipt. What did you send ahead?';

  @override
  String get impactReportScreen_imagineYourScaleOn =>
      'Imagine your scale on Yawm al-Qiyamah. What weight are you adding today?';

  @override
  String get impactReportScreen_theWorldIsBorrowed =>
      'The world is borrowed. The Akhirah is owned. Invest accordingly.';

  @override
  String get impactReportScreen_youBuryTheBody =>
      'You bury the body — but not the deeds. Send them ahead while you can.';

  @override
  String get impactReportScreen_righteousChildWhoPrays =>
      'A righteous child who prays for you, a charity that flows, or knowledge that benefits — three eternal investments. (Muslim)';

  @override
  String get impactReportScreen_youWillMeetAllah =>
      'You will meet Allah with your record. Make sure today\\';

  @override
  String get impactReportScreen_noDeedIsToo =>
      'No deed is too small for the One who counts atoms.';

  @override
  String impactReportScreen_lvl(String _level, String arg1) {
    return 'Lvl $_level · $arg1';
  }

  @override
  String impactReportScreen_200447(String arg1) {
    return '+$arg1';
  }

  @override
  String get impactReportScreen_deedsTODAY => 'DEEDS TODAY';

  @override
  String impactReportScreen_634027(String arg1) {
    return '+$arg1';
  }

  @override
  String get impactReportScreen_thisWEEK => 'THIS WEEK';

  @override
  String get impactReportScreen_hasanaatEarned => 'Hasanaat Earned';

  @override
  String get impactReportScreen_whoeverDoesGoodDeed =>
      'Whoever does a good deed shall have ten times the like thereof.';

  @override
  String get impactReportScreen_whoeverReadsLetterFrom =>
      'Whoever reads a letter from the Book of Allah, he will have one hasanah, and a hasanah is multiplied by ten.';

  @override
  String get impactReportScreen_twoHadithGrowThis =>
      'Two hadith grow this number side by side:\\n\\n';

  @override
  String impactReportScreen_dhikrRecitedLifetime(String arg1) {
    return '  Dhikr recited (lifetime): $arg1\\n';
  }

  @override
  String impactReportScreen_hasanat(String arg1) {
    return '  → Hasanat: $arg1\\n\\n';
  }

  @override
  String impactReportScreen_ayahsReadLifetime(String arg1) {
    return '  Ayahs read (lifetime): $arg1\\n';
  }

  @override
  String impactReportScreen_hasanat_e68a30(String arg1) {
    return '  → Hasanat: $arg1\\n\\n';
  }

  @override
  String impactReportScreen_totalHasanaat(String arg1) {
    return 'Total hasanaat: $arg1';
  }

  @override
  String impactReportScreen_ayahs(String arg1) {
    return '$arg1 ayahs';
  }

  @override
  String get impactReportScreen_hasanatFromQuran => 'Hasanat from Quran';

  @override
  String impactReportScreen_planted(String arg1) {
    return '$arg1 planted';
  }

  @override
  String get impactReportScreen_treesInJannah => 'Trees in Jannah';

  @override
  String impactReportScreen_cycles(String arg1) {
    return '$arg1 cycles';
  }

  @override
  String get impactReportScreen_sinsForgiven => 'Sins Forgiven';

  @override
  String get impactReportScreen_whoeverSaysSubhanAllahiWa =>
      'Whoever says SubhanAllahi wa bihamdihi 100 times a day, his sins are forgiven even if they were like the foam of the sea.';

  @override
  String get impactReportScreen_subhanallahiWaBihamdihi =>
      'SubhanAllahi wa bihamdihi';

  @override
  String impactReportScreen_totalRecitations(String arg1) {
    return 'Total recitations: $arg1\\n';
  }

  @override
  String impactReportScreen_dividedByForgivenessCycles(String arg1) {
    return 'Divided by 100 → forgiveness cycles: $arg1';
  }

  @override
  String impactReportScreen_built(String arg1) {
    return '$arg1 built';
  }

  @override
  String get impactReportScreen_palacesBuilt => 'Palaces Built';

  @override
  String impactReportScreen_dividedByPalaces(String arg1) {
    return 'Divided by 10 → palaces: $arg1';
  }

  @override
  String impactReportScreen_earned(String arg1) {
    return '$arg1 earned';
  }

  @override
  String get impactReportScreen_treasuresOfJannah => 'Treasures of Jannah';

  @override
  String impactReportScreen_equivalent(String arg1) {
    return '$arg1 equivalent';
  }

  @override
  String get impactReportScreen_slavesFreed => 'Slaves Freed';

  @override
  String get impactReportScreen_laIlahaIllallahuWahdahu =>
      'La ilaha illallahu wahdahu la sharika lahu...';

  @override
  String impactReportScreen_totalRecitations_262e54(String arg1) {
    return 'Total recitations: $arg1\\n';
  }

  @override
  String impactReportScreen_setsOfSetsSlaves(String arg1, String arg2) {
    return 'Sets of 10 → $arg1 sets × 4 slaves = $arg2';
  }

  @override
  String impactReportScreen_opened(String arg1) {
    return '$arg1 opened';
  }

  @override
  String get impactReportScreen_gatesOfParadiseOpened =>
      'Gates of Paradise Opened';

  @override
  String impactReportScreen_received(String arg1) {
    return '$arg1 received';
  }

  @override
  String get impactReportScreen_blessingsFromAllah => 'Blessings from Allah';

  @override
  String impactReportScreen_totalSalawatSent(String arg1) {
    return 'Total salawat sent: $arg1\\n';
  }

  @override
  String impactReportScreen_multipliedByBlessingsReceived(String arg1) {
    return 'Multiplied by 10 → $arg1 blessings received';
  }

  @override
  String impactReportScreen_invocations(String arg1) {
    return '$arg1 invocations';
  }

  @override
  String get impactReportScreen_timesProtected => 'Times Protected';

  @override
  String get impactReportScreen_protectionFromEvil => 'Protection from evil';

  @override
  String get impactReportScreen_goodHealthProtection =>
      'Good health & protection';

  @override
  String impactReportScreen_totalInvocations(String arg1) {
    return 'Total invocations: $arg1';
  }

  @override
  String impactReportScreen_equivalent_d7e6f6(String arg1) {
    return '$arg1 equivalent';
  }

  @override
  String get impactReportScreen_quranCompletions => 'Quran Completions';

  @override
  String impactReportScreen_dividedByQuranCompletions(String arg1) {
    return 'Divided by 3 → $arg1 Quran completions';
  }

  @override
  String impactReportScreen_recitations(String arg1) {
    return '$arg1 recitations';
  }

  @override
  String get impactReportScreen_bonusMillionHasanaat =>
      'Bonus Million Hasanaat';

  @override
  String get impactReportScreen_sadaqahGiven => 'Sadaqah Given';

  @override
  String impactReportScreen_564740(String _monthActiveDays) {
    return '$_monthActiveDays';
  }

  @override
  String impactReportScreen_3dc421(String arg1) {
    return '${arg1}h ';
  }

  @override
  String impactReportScreen_08990a(String arg1) {
    return '${arg1}m';
  }

  @override
  String impactReportScreen_ago(String arg1) {
    return '${arg1}m ago';
  }

  @override
  String impactReportScreen_ago_c25b44(String arg1) {
    return '${arg1}h ago';
  }

  @override
  String impactReportScreen_ago_e160e3(String arg1) {
    return '${arg1}w ago';
  }

  @override
  String impactReportScreen_moAgo(String arg1) {
    return '${arg1}mo ago';
  }

  @override
  String impactReportScreen_ago_65f0ec(String arg1) {
    return '${arg1}y ago';
  }

  @override
  String impactReportScreen_viewAllDonors(String arg1) {
    return 'View all $arg1 donors';
  }

  @override
  String impactReportScreen_failed(String e) {
    return 'Failed: $e';
  }

  @override
  String impactReportScreen_meet(String arg1, String arg2) {
    return 'Meet $arg1, $arg2';
  }

  @override
  String impactReportScreen_sponsor(String arg1) {
    return 'Sponsor $arg1 →';
  }

  @override
  String impactReportScreen_funded(String arg1) {
    return '$arg1% funded';
  }

  @override
  String get impactReportScreen_yourLifetimeImpact => 'Your lifetime impact';

  @override
  String get impactReportScreen_startYourImpactJourney =>
      'Start your impact journey';

  @override
  String impactReportScreen_bd3721(String _myOrphansSponsoredCount) {
    return '$_myOrphansSponsoredCount';
  }

  @override
  String impactReportScreen_b3d969(String _myProjectsSupportedCount) {
    return '$_myProjectsSupportedCount';
  }

  @override
  String get levelScreen_customProfileThemes => 'Custom profile themes';

  @override
  String get levelScreen_exclusiveVotingRights => 'Exclusive voting rights';

  @override
  String get levelScreen_hallOfFameListing => 'Hall of Fame listing';

  @override
  String levelScreen_seeds(String arg1) {
    return '+$arg1 Seeds';
  }

  @override
  String get levelScreen_laIlahaIllallah => 'La ilaha illallah x100';

  @override
  String levelScreen_seeds_59c6a1(String arg1) {
    return '+$arg1 Seeds';
  }

  @override
  String levelScreen_seeds_a20530(String arg1) {
    return '+$arg1 Seeds';
  }

  @override
  String levelScreen_unlocks(String arg1) {
    return 'Unlocks: $arg1';
  }

  @override
  String levelScreen_seeds_a49180(String arg1) {
    return '+$arg1 Seeds ✓';
  }

  @override
  String levelScreen_seeds_a22be5(String arg1) {
    return '+$arg1 Seeds';
  }

  @override
  String levelScreen_seedsBoost(String arg1) {
    return '$arg1× Seeds Boost';
  }

  @override
  String levelScreen_cf765f(
    String arg1,
    String arg2,
    String arg3,
    String arg4,
    String arg5,
  ) {
    return '$arg1:$arg2  $arg3/$arg4/$arg5';
  }

  @override
  String levelScreen_nextDays(String arg1, String arg2) {
    return 'Next: $arg1 ($arg2 days)';
  }

  @override
  String levelScreen_seeds_990893(String arg1) {
    return '+$arg1 Seeds';
  }

  @override
  String levelScreen_days(String current, String arg1) {
    return '$current / $arg1 days';
  }

  @override
  String levelScreen_dayStreak(String arg1) {
    return '$arg1 day streak';
  }

  @override
  String get phase1Screens_inTheNameOf =>
      'In the name of Allah, the Most Gracious…';

  @override
  String get phase1Screens_quranReadingNimage => 'Quran reading\\nimage';

  @override
  String get phase1Screens_orphansNimage => 'Orphans\\nimage';

  @override
  String onboardingComponents_355c50(String first) {
    return '$first ';
  }

  @override
  String onboardingComponents_b236c9(String trailing) {
    return ' $trailing';
  }

  @override
  String get quranMini_inTheNameOf =>
      'In the name of Allah, the Most Gracious, the Most Merciful.';

  @override
  String get quranMini_allPraiseBelongsTo =>
      'All praise belongs to Allah, Lord of all the worlds.';

  @override
  String orphansGridScreen_36cd3b(String arg1, String arg2) {
    return '$arg1 · $arg2';
  }

  @override
  String orphanDetailScreen_years(String arg1) {
    return '$arg1 years';
  }

  @override
  String orphanDetailScreen_ofSeeds(String arg1, String arg2) {
    return '$arg1 of $arg2 Seeds';
  }

  @override
  String orphanDetailScreen_through(String arg1) {
    return 'Through $arg1';
  }

  @override
  String get orphanDetailScreen_andTheyGiveFood =>
      'And they give food, despite their love for it, to the needy, the orphan, and the captive.';

  @override
  String orphanDetailScreen_ago(String arg1) {
    return '${arg1}m ago';
  }

  @override
  String orphanDetailScreen_ago_c25b44(String arg1) {
    return '${arg1}h ago';
  }

  @override
  String orphanDetailScreen_ago_e160e3(String arg1) {
    return '${arg1}w ago';
  }

  @override
  String orphanDetailScreen_moAgo(String arg1) {
    return '${arg1}mo ago';
  }

  @override
  String orphanDetailScreen_ago_65f0ec(String arg1) {
    return '${arg1}y ago';
  }

  @override
  String orphanDetailScreen_seeds(String _availablePoints) {
    return '$_availablePoints Seeds';
  }

  @override
  String orphanDetailScreen_sponsor(String arg1) {
    return 'Sponsor $arg1';
  }

  @override
  String orphanDetailScreen_jazakallahKhayranSeedsSponsored(String amount) {
    return 'JazakAllah Khayran! $amount Seeds sponsored.';
  }

  @override
  String orphanDetailScreen_chooseHowManySeeds(String arg1) {
    return 'Choose how many Seeds to give. Minimum $arg1.';
  }

  @override
  String orphanDetailScreen_yourBalanceSeeds(String arg1) {
    return 'Your balance: $arg1 Seeds';
  }

  @override
  String get profileSettingsScreen_nameCannotBeEmpty => 'Name cannot be empty';

  @override
  String get profileSettingsScreen_sabiqRewards => 'Sabiq Rewards • v1.0';

  @override
  String get profileSettingsScreen_bosniaAndHerzegovina =>
      'Bosnia and Herzegovina';

  @override
  String get profileSettingsScreen_centralAfricanRepublic =>
      'Central African Republic';

  @override
  String get profileSettingsScreen_unitedArabEmirates => 'United Arab Emirates';

  @override
  String get profileSettingsScreen_signedInWithGoogle =>
      'Signed in with Google';

  @override
  String get profileSettingsScreen_signedInWithQuran =>
      'Signed in with Quran.com';

  @override
  String get profileSettingsScreen_signedInWithEmail => 'Signed in with Email';

  @override
  String profileSettingsScreen_seeds(String arg1) {
    return '$arg1 Seeds';
  }

  @override
  String profileSettingsScreen_seeds_59ba7c(String arg1) {
    return '$arg1 Seeds';
  }

  @override
  String profileSettingsScreen_seeds_2bc978(String arg1) {
    return '$arg1 Seeds';
  }

  @override
  String get profileSettingsScreen_guidesFAQsAndHow =>
      'Guides, FAQs and how-tos';

  @override
  String get profileSettingsScreen_somethingNotWorkingTell =>
      'Something not working? Tell us';

  @override
  String get profileSetupScreen_ahmadFatimaYusuf => 'Ahmad, Fatima, Yusuf…';

  @override
  String get profileSetupScreen_pakistanEgyptMalaysia =>
      'Pakistan, Egypt, Malaysia…';

  @override
  String projectDetailScreen_organisedBy(String sponsor) {
    return 'Organised by $sponsor\\n\\n';
  }

  @override
  String get projectDetailScreen_fundedSoFarEvery =>
      'Funded so far, every Seed counts!\\n\\n';

  @override
  String get projectDetailScreen_openSabiqRewardsApp =>
      'Open Sabiq Rewards app to donate your Seeds and earn reward.\\n';

  @override
  String get projectDetailScreen_sabiqrewardsSadaqahIslamicCharity =>
      '#SabiqRewards #Sadaqah #IslamicCharity';

  @override
  String projectDetailScreen_4c2b09(String arg1, String arg2, String arg3) {
    return '$arg1 $arg2 $arg3';
  }

  @override
  String get projectDetailScreen_donateToProvideUrgent =>
      'Donate to provide urgent, life-saving aid to Palestinians facing critical shortages of food, water, and medical supplies...';

  @override
  String projectDetailScreen_seeds(String arg1) {
    return '$arg1 Seeds';
  }

  @override
  String projectDetailScreen_seeds_801ec7(String arg1) {
    return '$arg1 Seeds';
  }

  @override
  String projectDetailScreen_e4e562(String arg1) {
    return '$arg1%';
  }

  @override
  String projectDetailScreen_ago(String arg1) {
    return '${arg1}m ago';
  }

  @override
  String projectDetailScreen_ago_c25b44(String arg1) {
    return '${arg1}h ago';
  }

  @override
  String projectDetailScreen_ago_e160e3(String arg1) {
    return '${arg1}w ago';
  }

  @override
  String projectDetailScreen_moAgo(String arg1) {
    return '${arg1}mo ago';
  }

  @override
  String projectDetailScreen_ago_65f0ec(String arg1) {
    return '${arg1}y ago';
  }

  @override
  String projectDetailScreen_viewAll(String arg1) {
    return 'View all $arg1 →';
  }

  @override
  String quranHubScreen_saved(String arg1) {
    return '$arg1 saved';
  }

  @override
  String get quranHubScreen_tapTheHeartBookmark =>
      'Tap the heart/bookmark icon while reading to save verses.';

  @override
  String quranHubScreen_surahVerse(String s, String a) {
    return 'Surah $s  •  Verse $a';
  }

  @override
  String get quranHubScreen_loadingQuran => 'Loading Quran…';

  @override
  String quranHubScreen_verses(String arg1) {
    return '$arg1 verses';
  }

  @override
  String quranHubScreen_of(String arg1) {
    return 'of $arg1';
  }

  @override
  String quranHubScreen_saved_edce53(String arg1) {
    return '$arg1 saved';
  }

  @override
  String get quranScreen_englishSahihIntl => 'English, Sahih Intl.';

  @override
  String get quranScreen_saheehInternational => 'Saheeh International';

  @override
  String get quranScreen_englishPickthall => 'English, Pickthall';

  @override
  String get quranScreen_mohammadMarmadukePickthall =>
      'Mohammad Marmaduke Pickthall';

  @override
  String get quranScreen_englishTheMessage => 'English, The Message';

  @override
  String get quranScreen_englishMuhsinKhan => 'English, Muhsin Khan';

  @override
  String get quranScreen_muhsinKhanHilali => 'Muhsin Khan & Hilali';

  @override
  String get quranScreen_fatehMuhammadJalandhry => 'Fateh Muhammad Jalandhry';

  @override
  String get quranScreen_imamAhmadRazaKhan => 'Imam Ahmad Raza Khan';

  @override
  String get quranScreen_maulanaSayyidAbulAla =>
      'Maulana Sayyid Abul Ala Maududi';

  @override
  String get quranScreen_franAisHamidullah => 'Français, Hamidullah';

  @override
  String get quranScreen_rkDiyanet => 'Türkçe, Diyanet';

  @override
  String get quranScreen_rkLeymanAte => 'Türkçe, Süleyman Ateş';

  @override
  String get quranScreen_bahasaIndonesian => 'Bahasa, Indonesian';

  @override
  String get quranScreen_ministryOfReligiousAffairs =>
      'Ministry of Religious Affairs';

  @override
  String get quranScreen_muhiuddinKhan => 'বাংলা, Muhiuddin Khan';

  @override
  String get quranScreen_deutschAbuRida => 'Deutsch, Abu Rida';

  @override
  String get quranScreen_abuRidaMuhammadIbn => 'Abu Rida Muhammad ibn Ahmad';

  @override
  String get quranScreen_espaOlAsad => 'Español, Asad';

  @override
  String get quranScreen_uthmaniMadinah => 'Uthmani (Madinah)';

  @override
  String get quranScreen_alJalalaynEN => 'Al-Jalalayn (EN)';

  @override
  String get quranScreen_couldNotLoadAyah =>
      'Could not load ayah. Please retry.';

  @override
  String get quranScreen_noConnectionCachedData =>
      'No connection. Cached data may be available.';

  @override
  String quranScreen_ayahs(String arg1) {
    return '$arg1 ayahs';
  }

  @override
  String get quranScreen_couldNotRemoveBookmark =>
      'Could not remove bookmark, please retry';

  @override
  String quranScreen_removedBookmark(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'Removed bookmark $_surahName $_surah:$_ayah';
  }

  @override
  String get quranScreen_couldNotSaveBookmark =>
      'Could not save bookmark, please retry';

  @override
  String quranScreen_bookmarked(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'Bookmarked $_surahName $_surah:$_ayah';
  }

  @override
  String get quranScreen_trimmedContains => ') && !trimmed.contains(';

  @override
  String quranScreen_tafsir(String _surahName, String _surah, String _ayah) {
    return 'Tafsir · $_surahName $_surah:$_ayah';
  }

  @override
  String get quranScreen_addedToFavourites => '♥️ Added to Favourites';

  @override
  String get quranScreen_comfortableNightTimeReading =>
      'Comfortable night-time reading';

  @override
  String quranScreen_pt(String arg1) {
    return '$arg1 pt';
  }

  @override
  String quranScreen_003843(String arg1, String arg2) {
    return '$arg1  $arg2';
  }

  @override
  String get quranScreen_displayMeaningBelowEach =>
      'Display meaning below each verse';

  @override
  String get quranScreen_showTransliteration => 'Show Transliteration';

  @override
  String get quranScreen_romanisedPronunciationUnderEach =>
      'Romanised pronunciation under each word';

  @override
  String get quranScreen_progressBarAyahCount =>
      'Progress bar & ayah count card';

  @override
  String get quranScreen_moveToNextVerse =>
      'Move to next verse when audio ends';

  @override
  String get quranScreen_repeatCurrentVerse => 'Repeat Current Verse';

  @override
  String get quranScreen_notificationsALERTS => 'NOTIFICATIONS & ALERTS';

  @override
  String get quranScreen_milestoneSoundAlerts => 'Milestone Sound Alerts';

  @override
  String get quranScreen_chimeWhenYouReach =>
      'Chime when you reach 10, 25, 50 ayahs';

  @override
  String get quranScreen_showEachArabicWord =>
      'Show each Arabic word with its English meaning';

  @override
  String get quranScreen_translationLanguage => 'Translation Language';

  @override
  String quranScreen_translationsAvailable(String arg1) {
    return '$arg1 translations available';
  }

  @override
  String quranScreen_3502e8(String arg1, String arg2) {
    return '$arg1 / $arg2';
  }

  @override
  String quranScreen_sabiqSeedsEarnedToday(String _pointsToday) {
    return '+$_pointsToday Sabiq Seeds earned today!';
  }

  @override
  String quranScreen_dcacc4(String _ayah, String arg1) {
    return '$_ayah / $arg1';
  }

  @override
  String get quranScreen_wordDataUnavailableCheck =>
      'Word data unavailable. Check your connection.';

  @override
  String quranScreen_6d1f9d(String arg1) {
    return '$arg1 ';
  }

  @override
  String quranScreen_ayahsRead(String _ayahsToday) {
    return '$_ayahsToday ayahs read';
  }

  @override
  String quranScreen_ce2af3(String arg1) {
    return '$arg1%';
  }

  @override
  String quranScreen_6e8ac8(String text) {
    return '$text ';
  }

  @override
  String quranScreen_pageJuz(String _currentPage, String arg1) {
    return 'Page $_currentPage  ·  Juz $arg1';
  }

  @override
  String get startJourneyScreen_unexpectedErrorDuringGoogle =>
      'Unexpected error during Google Sign In';

  @override
  String get startJourneyScreen_connectedToQuranCom => 'Connected to Quran.com';

  @override
  String get startJourneyScreen_connectedToQuranCom_0ac4de =>
      'Connected to Quran.com (bookmark sync deferred)';

  @override
  String streakScreen_nextDays(String arg1, String arg2) {
    return 'Next: $arg1 ($arg2 days)';
  }

  @override
  String streakScreen_seeds(String arg1) {
    return '+$arg1 Seeds';
  }

  @override
  String streakScreen_days(String current, String arg1) {
    return '$current / $arg1 days';
  }

  @override
  String streakScreen_dayStreak(String arg1) {
    return '$arg1 day streak';
  }

  @override
  String get tafsirHubScreen_earnSeedsForEvery =>
      'Earn Seeds for every 10 min of Tafsir listening';

  @override
  String get tafsirScreen_alJalalaynEN => 'Al-Jalalayn (EN)';

  @override
  String tafsirScreen_verses(String arg1) {
    return '$arg1 verses';
  }

  @override
  String get tafsirScreen_trimmedContains => ') && !trimmed.contains(';

  @override
  String tafsirScreen_ayahOf(String _ayah, String _surahLen) {
    return 'Ayah $_ayah of $_surahLen';
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
      'Tafsir not available for this ayah.';

  @override
  String get donationService_youMustBeLogged =>
      'You must be logged in to donate.';

  @override
  String get donationService_donationCouldNotBe =>
      'Donation could not be processed at this time.';

  @override
  String get donationService_anUnexpectedNetworkError =>
      'An unexpected network error occurred.';

  @override
  String get donationService_youMustBeLogged_edc4b5 =>
      'You must be logged in to sponsor.';

  @override
  String get donationService_sponsorshipReceived => 'Sponsorship received 💝';

  @override
  String donationService_youSponsoredSeedsJazak(String amount) {
    return 'You sponsored $amount Seeds · jazak Allah khair.';
  }

  @override
  String get donationService_sponsorshipCouldNotBe =>
      'Sponsorship could not be processed at this time.';

  @override
  String get liveNotificationService_remindersToSealYour =>
      'Reminders to seal your pending Seeds before midnight.';

  @override
  String get liveNotificationService_sealYourSeedsBefore =>
      'Seal your Seeds before midnight';

  @override
  String get liveNotificationService_sealYourSeedsBefore_be2183 =>
      'Seal your Seeds before midnight!';

  @override
  String liveNotificationService_youHavePendingSeeds(String pendingSeeds) {
    return 'You have $pendingSeeds pending Seeds. Tap Seal the Day before midnight or they expire.';
  }

  @override
  String liveNotificationService_ayatReadToday(String _ayahCount) {
    return '$_ayahCount Ayat Read today 📖';
  }

  @override
  String liveNotificationService_readQuranToday(String arg1) {
    return '$arg1 Read Quran today ⏱️';
  }

  @override
  String get liveNotificationService_nothingReadFromQuran =>
      'Nothing Read from Quran today 📖';

  @override
  String liveNotificationService_dhikrCompletedToday(String _dhikrCount) {
    return '$_dhikrCount Dhikr completed today 📿';
  }

  @override
  String liveNotificationService_ayatDhikrToday(
    String _ayahCount,
    String _dhikrCount,
  ) {
    return '$_ayahCount ayat · $_dhikrCount dhikr today';
  }

  @override
  String get liveNotificationService_keepReadingAndDoing =>
      'Keep reading and doing Dhikr!';

  @override
  String get liveNotificationService_yourSeedsToday => 'Your Seeds Today ✨';

  @override
  String get localReminderScheduler_sabiqRewardsNotifications =>
      'Sabiq Rewards Notifications';

  @override
  String get localReminderScheduler_it => 'It\\';

  @override
  String get localReminderScheduler_fridayReadSurahAl =>
      's Friday — read Surah Al-Kahf';

  @override
  String get localReminderScheduler_whoeverRecitesSurahAl =>
      'Whoever recites Surah Al-Kahf on Friday, light shines for them between the two Fridays.';

  @override
  String get localReminderScheduler_don => 'Don\\';

  @override
  String get localReminderScheduler_missSurahAlKahf =>
      't miss Surah Al-Kahf today';

  @override
  String get localReminderScheduler_fewHoursToMaghrib =>
      'A few hours to Maghrib — finish Surah Al-Kahf if you haven\\';

  @override
  String get quranApiService_notConnectedToQuran =>
      'Not connected to Quran.com';

  @override
  String quranApiService_syncFailedBookmarkCould(String failed) {
    return 'Sync failed, $failed bookmark(s) could not be pushed to Quran.com (check token / endpoint).';
  }

  @override
  String get quranApiService_bookmarksAlreadyInSync =>
      'Bookmarks already in sync';

  @override
  String quranApiService_syncedBookmarksUpDown(
    String total,
    String uploaded,
    String downloaded,
  ) {
    return 'Synced $total bookmarks ($uploaded up, $downloaded down)';
  }

  @override
  String quranApiService_syncFailed(String e) {
    return 'Sync failed: $e';
  }

  @override
  String get streakService_warmingUp => 'Warming Up';

  @override
  String get streakService_oneWeek => 'One Week';

  @override
  String get streakService_twoWeeks => 'Two Weeks';

  @override
  String get streakService_oneMonth => 'One Month';

  @override
  String get streakService_twoMonths => 'Two Months';

  @override
  String get streakService_theCenturion => 'The Centurion';

  @override
  String streakService_1fc043(String arg1, String arg2) {
    return '$arg1 $arg2';
  }

  @override
  String streakService_dayStreak(String arg1, String arg2) {
    return '$arg1-day $arg2 streak · ';
  }

  @override
  String streakService_bonusSeedsUnlocked(String arg1) {
    return '+$arg1 bonus Seeds unlocked';
  }

  @override
  String trackingService_c7528c(String arg1, String arg2) {
    return '$arg1 $arg2';
  }

  @override
  String xpService_level(String title, String level) {
    return '$title • Level $level';
  }

  @override
  String get xpService_newBadgeUnlocked => 'New badge unlocked 🏆';

  @override
  String get xpService_you => 'You\\';

  @override
  String get xpService_dailyLoginBonus => 'Daily login bonus';

  @override
  String xpService_seedsWelcomeBack(String arg1) {
    return '+$arg1 Seeds · welcome back!';
  }

  @override
  String get xpService_daySealed => 'Day sealed 🌙';

  @override
  String xpService_sabiqSeedsConfirmedBonus(String flushed, String bonus) {
    return '+$flushed Sabiq Seeds confirmed! ($bonus bonus for sealing)';
  }

  @override
  String xpService_sabiqSeedsConfirmed(String flushed) {
    return '+$flushed Sabiq Seeds confirmed!';
  }

  @override
  String get dhikrExitCelebration_everyBreathCounts => 'Every breath counts.';

  @override
  String get impactAnimation_yourRewardHasBeen =>
      'Your reward has been recorded.';

  @override
  String get motivationalPopup_verilyWithHardshipComes =>
      'Verily, with hardship comes ease.\\nEvery trial is a door to something greater.';

  @override
  String get motivationalPopup_quranAlInshirah => 'Quran • Al-Inshirah 94:6';

  @override
  String get motivationalPopup_quranAlAnkabut => 'Quran • Al-Ankabut 29:45';

  @override
  String get motivationalPopup_quranAlBaqarah => 'Quran • Al-Baqarah 2:152';

  @override
  String get motivationalPopup_quranAnNahl => 'Quran • An-Nahl 16:18';

  @override
  String get motivationalPopup_makeYourTimePrecious =>
      'Make your time precious.\\nShare goodness with a friend today ,\\nevery good deed shared is a sadaqah.';

  @override
  String get motivationalPopup_guideOthersToGood =>
      'Guide others to good, and you get its reward.';

  @override
  String get motivationalPopup_theBestOfPeople =>
      'The best of people are those most beneficial to others.';

  @override
  String get motivationalPopup_verilyInTheRemembrance =>
      'Verily, in the remembrance of Allah\\ndo hearts find rest.';

  @override
  String get motivationalPopup_remindYourselfTimeIs =>
      'Remind yourself, time is the most precious sadaqah.';

  @override
  String get motivationalPopup_yourTimeIsYour =>
      'Your time is your most\\nprecious asset. Invest it wisely\\nin what endures forever.';

  @override
  String get motivationalPopup_quranAlAnfal => 'Quran • Al-Anfal 8:28';

  @override
  String get motivationalPopup_takeAdvantageOfFive =>
      'Take advantage of five before five.';

  @override
  String get motivationalPopup_youHaveBeenRewarded =>
      'You have been rewarded for\\nyour consistency today!';

  @override
  String motivationalPopup_seeds(String arg1) {
    return '+$arg1 Seeds';
  }

  @override
  String motivationalPopup_seeds_b14996(String arg1) {
    return '+$arg1 Seeds';
  }

  @override
  String get motivationalPopup_readQuranPages => 'Read 5 Quran Pages';

  @override
  String get motivationalPopup_completeNowEarnSeeds =>
      'Complete now → earn +50 Seeds bonus';

  @override
  String get motivationalPopup_completeDhikrSet => 'Complete a Dhikr Set';

  @override
  String get motivationalPopup_finishYourAzkaarEarn =>
      'Finish your Azkaar → earn +30 Seeds bonus';

  @override
  String get motivationalPopup_inviteFriend => 'Invite a Friend';

  @override
  String get motivationalPopup_shareSabiqWithSomeone =>
      'Share Sabiq with someone → earn +100 Seeds';

  @override
  String get motivationalPopup_keepYourSpiritualMomentum =>
      'Keep your spiritual momentum going\\nand watch your Seeds grow ✨';

  @override
  String get noorOffline_somethingWentWrong => 'Something went wrong';

  @override
  String get notificationsSheet_stayOnTopOf =>
      'Stay on top of rewards & milestones';

  @override
  String get notificationsSheet_llBeNotifiedAbout =>
      'll be notified about rewards, streaks & milestones.';

  @override
  String get notificationsSheet_inboxKeepsExistingItems =>
      'Inbox keeps existing items but no new ones will arrive.';

  @override
  String get notificationsSheet_sabiqSeedsForSealing =>
      'Sabiq Seeds for sealing today';

  @override
  String notificationsSheet_ago(String arg1) {
    return '${arg1}m ago';
  }

  @override
  String notificationsSheet_ago_5d4e7f(String arg1) {
    return '${arg1}h ago';
  }

  @override
  String notificationsSheet_ago_67b1d9(String arg1) {
    return '${arg1}d ago';
  }

  @override
  String get projectMediaCarousel_couldNotLoadVideo => 'Could not load video';

  @override
  String get quranExitCelebration_beautifulRecitation =>
      'Beautiful recitation.';

  @override
  String get quranExitCelebration_everyMomentCounts => 'Every moment counts.';

  @override
  String sealCoinAnimation_e16fa4(String arg1) {
    return '+$arg1 ';
  }

  @override
  String get authScreen_pleaseEnterYourEmail_d36dc6 =>
      'Please enter your email';

  @override
  String get authScreen_pleaseEnterYourPassword_0f8b9b =>
      'Please enter your password';

  @override
  String get authScreen_passwordMustBeAt_c936ae =>
      'Password must be at least 6 characters';

  @override
  String get authScreen_alreadyHaveAnAccount_07e598 =>
      'Already have an account? Sign In';

  @override
  String get authScreen_haveAnAccountSign_ae2883 =>
      't have an account? Sign Up';

  @override
  String qfAuthService_qfemailconflictexceptionAlreadyHasAn_e1592c(
    String email,
  ) {
    return 'QfEmailConflictException: $email already has an account';
  }

  @override
  String get qfAuthService_openidOfflineAccessUser_fc4bcc =>
      'openid offline_access user bookmark collection reading_session';

  @override
  String qfAuthService_tokenExchangeFailed_89d8a0(String arg1, String arg2) {
    return 'Token exchange failed ($arg1): $arg2';
  }

  @override
  String get qfAuthService_errorNullResponse_bd81c7 => 'ERROR: Null response';

  @override
  String orphan_be2bf7_be2bf7(String firstName, String lastInitial) {
    return '$firstName $lastInitial.';
  }

  @override
  String get akhirahBalanceScreen_subhanallahiWaBiHamdihi_b246c2 =>
      '“Subhanallahi wa bi-hamdihi” — said 100 times a day wipes sins, even like the foam of the sea. (Bukhari)';

  @override
  String get akhirahBalanceScreen_sayLaIlahaIllallah_27fc5f =>
      'Say La ilaha illallah 100 times — equals freeing 10 slaves and 100 hasanat. (Bukhari)';

  @override
  String get akhirahBalanceScreen_lightOnTheTongue_ea6114 =>
      'Light on the tongue, heavy on the scales: Subhanallahi wa bi-hamdihi, Subhanallahil-azim. (Bukhari 6406)';

  @override
  String get akhirahBalanceScreen_theDhikrOfAllah_a23f17 =>
      'The dhikr of Allah is heavier on the scales than gold of equal weight. Keep going.';

  @override
  String get akhirahBalanceScreen_yourTongueShouldStay_34816c =>
      '“Your tongue should stay moist with the remembrance of Allah.” — Is it still moist?';

  @override
  String get akhirahBalanceScreen_astaghfirullahTheProphetSaid_7625ff =>
      'Astaghfirullah — the Prophet ✍ said it 100 times a day, and he had no sin. How many have you?';

  @override
  String get akhirahBalanceScreen_whenYouRememberAllah_60f406 =>
      'When you remember Allah quietly, He remembers you in an assembly far greater.';

  @override
  String get akhirahBalanceScreen_reciteAyatAlKursi_d0751f =>
      'Recite Ayat al-Kursi after every salah — nothing keeps you from Jannah but death.';

  @override
  String get akhirahBalanceScreen_oneAlhamdulillahFillsThe_4794bb =>
      'One Alhamdulillah fills the scale. One Subhanallah fills what is between heaven and earth.';

  @override
  String get akhirahBalanceScreen_theRemembranceOfAllah_c99fe8 =>
      '“The remembrance of Allah is greater than everything else.” — Surah Al-Ankabut 29:45';

  @override
  String get akhirahBalanceScreen_rememberMeWillRemember_1aca04 =>
      '“Remember Me — I will remember you.” — Surah Al-Baqarah 2:152. Will you?';

  @override
  String get akhirahBalanceScreen_inTheRemembranceOf_20b541 =>
      '“In the remembrance of Allah, hearts find rest.” — Surah Ar-Ra’d 13:28';

  @override
  String get akhirahBalanceScreen_fiveMinutesOfDhikr_e12766 =>
      'Five minutes of dhikr now shapes the next 24 hours of your heart.';

  @override
  String get akhirahBalanceScreen_streakIsnAboutToday_9157d8 =>
      'A streak isn’t about today — it’s about who you become in 30 days.';

  @override
  String get akhirahBalanceScreen_smallDropsFillAn_1accce =>
      'Small drops fill an ocean. Your daily dhikr is filling something far bigger.';

  @override
  String get akhirahBalanceScreen_noOneSeesThe_0182c7 =>
      'No one sees the dhikr in your heart — but every angel writing your record does.';

  @override
  String get akhirahBalanceScreen_theBiggestWinsAre_1b8fb6 =>
      'The biggest wins are built from the smallest daily habits. Don’t break the chain.';

  @override
  String get akhirahBalanceScreen_youCameBackToday_a020b1 =>
      'You came back today. That’s already worship. Stay one more minute?';

  @override
  String get akhirahBalanceScreen_tomorrowPeaceIsBuilt_a72bd8 =>
      'Tomorrow’s peace is built on today’s remembrance. Plant one more seed.';

  @override
  String get akhirahBalanceScreen_areYouDoneAllah_06ca1d =>
      'Are you done? Allah’s door is always open — even after you’ve closed it.';

  @override
  String get akhirahBalanceScreen_dhikrIsTheLanguage_b1b983 =>
      'Dhikr is the language of the heart. Has yours spoken to its Lord today?';

  @override
  String get akhirahBalanceScreen_everySubhanallahIsSadaqah_16b797 =>
      'Every Subhanallah is a sadaqah. How many will you give before sleep?';

  @override
  String get akhirahBalanceScreen_heartThatForgetsDhikr_3a6173 =>
      'A heart that forgets dhikr begins to rust. A heart that remembers stays alight.';

  @override
  String get akhirahBalanceScreen_haveYouFortifiedYourself_17ccac =>
      'Have you fortified yourself with the morning and evening adhkar today?';

  @override
  String akhirahBalanceScreen_thisSession_702ffc(String arg1) {
    return 'This session: +$arg1';
  }

  @override
  String akhirahBalanceScreen_seedsThisSession_cd9411(String arg1) {
    return '+$arg1 seeds this session';
  }

  @override
  String akhirahBalanceScreen_dayAvgAzkaarDay_c8f1b6(String arg1) {
    return '7-day avg: $arg1 azkaar/day';
  }

  @override
  String dashboardScreen_profileReturnedZeroRows_3ccedb(String uid) {
    return 'Profile returned zero rows for $uid';
  }

  @override
  String dashboardScreen_dashboardLoadError_6168de(String e) {
    return 'Dashboard Load Error: $e';
  }

  @override
  String get dashboardScreen_invalidReferralCode_bb3b10 =>
      'Invalid referral code';

  @override
  String get dashboardScreen_cannotReferYourself_d836b8 =>
      'Cannot refer yourself';

  @override
  String dashboardScreen_sponsor_d48549(String name, String arg1) {
    return 'Sponsor $name, $arg1';
  }

  @override
  String get dashboardScreen_dashboardDoesn_b8feb4 => ': 0, // dashboard doesn';

  @override
  String dashboardScreen_today_261fbb(
    String arg1,
    String _lastAyah,
    String _ayahsToday,
  ) {
    return '$arg1 · $_lastAyah  · +$_ayahsToday today';
  }

  @override
  String dashboardScreen_606140_606140(String arg1, String _lastAyah) {
    return '$arg1 · $_lastAyah';
  }

  @override
  String dashboardScreen_dayStreak_2934ca(String arg1) {
    return '$arg1-day streak';
  }

  @override
  String get dashboardScreen_yourSabiqSeedsFund_3e8748 =>
      'Your Sabiq Seeds fund these projects';

  @override
  String dashboardScreen_active_2d214a(String arg1) {
    return '$arg1 active';
  }

  @override
  String get dashboardScreen_joinMeOnSabiq_755fb5 =>
      'Join me on Sabiq Rewards, earn Seeds for daily Quran, Dhikr & good deeds!\\n\\n';

  @override
  String dashboardScreen_useMyCodeAnd_7d13b3(String arg1) {
    return 'Use my code *$arg1* and we both get 500 Sabiq Seeds!\\n\\n';
  }

  @override
  String get dashboardScreen_messageCopiedShareOr_7b977e =>
      'Message copied, share or paste in WhatsApp!';

  @override
  String get dashboardScreen_sabiqSeedsRewardedTo_c209d6 =>
      '500 Sabiq Seeds rewarded to you both!';

  @override
  String get dashboardScreen_youHaveAlreadyUsed_f7c387 =>
      'You have already used a referral code.';

  @override
  String get dashboardScreen_youCannotUseYour_b7dbfe =>
      'You cannot use your own code.';

  @override
  String get dashboardScreen_anErrorOccurredPlease_8ee486 =>
      'An error occurred. Please try again.';

  @override
  String dashboardScreen_52b02c_52b02c(String pts) {
    return '$pts ';
  }

  @override
  String dashboardScreen_e4e562_e4e562(String arg1) {
    return '$arg1%';
  }

  @override
  String get dashboardScreen_seeDetailsForMore_54551e =>
      'See Details for more Projects →';

  @override
  String get dashboardScreen_yourTOTALSABIQSEEDS_f1d60a =>
      'YOUR TOTAL SABIQ SEEDS';

  @override
  String get dashboardScreen_viewCampaignDonate_450be4 =>
      '🤲  View Campaign & Donate';

  @override
  String dashboardScreen_yourRank_67be90(String rankText) {
    return 'Your Rank: $rankText';
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
  String get dashboardScreen_beTheFirstOn_63de17 => 'Be the first on the board';

  @override
  String get dashboardScreen_readAnAyahOr_9c7ab7 =>
      'Read an ayah or dhikr to claim the top spot';

  @override
  String dashboardScreen_lvl_ac180d(String level, String arg1) {
    return 'Lvl $level · $arg1';
  }

  @override
  String dashboardScreen_sealWithin_381d5d(String arg1) {
    return 'Seal within ${arg1}h';
  }

  @override
  String get dashboardScreen_jazakallahDaySealed_70a34b =>
      'JazakAllah!  Day sealed';

  @override
  String dashboardScreen_ofGoal_9660ee(String arg1, String arg2) {
    return 'of $arg1 $arg2 goal';
  }

  @override
  String get dhikrHubScreen_propheticSupplications_907064 =>
      'Prophetic Supplications';

  @override
  String get dhikrHubScreen_morningEveningRemembrance_ec6bc2 =>
      'Morning & Evening Remembrance';

  @override
  String get dhikrHubScreen_furtherSupplications_f72602 =>
      'Further Supplications';

  @override
  String get dhikrHubScreen_closingRemembranceSalawat_5204e8 =>
      'Closing Remembrance & Salawat';

  @override
  String get dhikrHubScreen_hajjUmrahSupplications_f4d1b9 =>
      'Hajj & Umrah Supplications';

  @override
  String get dhikrHubScreen_falseHiddenAdd_c45662 =>
      '] == false) hidden.add(r[';

  @override
  String get dhikrScreen_indoPak_fd8751 => 'Indo pak';

  @override
  String dhikrScreen_default_8bd36b(String recommendedCount) {
    return 'Default: $recommendedCount';
  }

  @override
  String get dhikrScreen_duaAzkarSettings_71de01 => 'Dua & Azkar Settings';

  @override
  String get dhikrScreen_hideTheVisualArtwork_28b4d2 =>
      'Hide the visual artwork area';

  @override
  String get dhikrScreen_pinTheIllustrationAt_5ec641 =>
      'Pin the illustration at the top while the Arabic text scrolls beneath it';

  @override
  String dhikrScreen_readTimes_537f51(String readCount) {
    return 'Read $readCount times';
  }

  @override
  String dhikrScreen_d08433_d08433(String arg1, String arg2) {
    return '$arg1 / $arg2';
  }

  @override
  String get dhikrScreen_alBaqarahAmanaAr_e9d62e =>
      'Al-Baqarah 285 (Amana ar-Rasool)';

  @override
  String get dhikrScreen_alBaqarahAlifLam_71ad0e =>
      'Al-Baqarah 1-5 (Alif Lam Mim)';

  @override
  String get dhikrScreen_alBaqarahLaIkraha_e837fb =>
      'Al-Baqarah 256 (La Ikraha)';

  @override
  String get dhikrScreen_alBaqarahAllahuWaliyy_c2a18b =>
      'Al-Baqarah 257 (Allahu Waliyy)';

  @override
  String get dhikrScreen_salawatIbrahimiyyaDurood_171c60 =>
      'Salawat Ibrahimiyya (Durood)';

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
  String get dhikrScreen_hisnulMuslimChapter_8745dc =>
      'Hisnul Muslim, Chapter: ';

  @override
  String dhikrScreen_3856c1_3856c1(String rawRef, String bottomRef) {
    return '$rawRef | $bottomRef';
  }

  @override
  String get dhikrScreen_bestOfBothWorlds_e1cc22 =>
      'Best of both worlds, refuge from the Fire';

  @override
  String get dhikrScreen_patienceAndSteadfastnessIn_114391 =>
      'Patience and steadfastness in every trial';

  @override
  String get dhikrScreen_allahBurdensNoSoul_c8bf72 =>
      'Allah burdens no soul beyond its capacity';

  @override
  String get dhikrScreen_keepTheHeartFirm_7729fe =>
      'Keep the heart firm upon guidance';

  @override
  String get dhikrScreen_faithAnsweredWithForgiveness_e8c93c =>
      'Faith answered with forgiveness from Hell';

  @override
  String get dhikrScreen_allSovereigntyInAllah_a9e0b3 =>
      'All sovereignty in Allah\\';

  @override
  String get dhikrScreen_allahHearsEveryCall_bf9969 =>
      'Allah hears every call for righteous offspring';

  @override
  String get dhikrScreen_countedWithTheWitnesses_99a05a =>
      'Counted with the witnesses of truth';

  @override
  String get dhikrScreen_forgivenessFirmFeetAnd_28f209 =>
      'Forgiveness, firm feet, and victory';

  @override
  String get dhikrScreen_theDuaOfThose_0ee764 => 'The dua of those who reflect';

  @override
  String get dhikrScreen_inscribedWithTheWitnesses_2257ce =>
      'Inscribed with the witnesses of revelation';

  @override
  String get dhikrScreen_theDuaAllahAccepted_7e207c =>
      'The dua Allah accepted from Adam ﷺ';

  @override
  String get dhikrScreen_spareUsTheCompany_c290d3 =>
      'Spare us the company of wrongdoers';

  @override
  String get dhikrScreen_neverTrialForThe_292b26 =>
      'Never a trial for the oppressors';

  @override
  String get dhikrScreen_refugeFromAskingWithout_0e04a4 =>
      'Refuge from asking without knowledge';

  @override
  String get dhikrScreen_prayerForSafetyAnd_5f4e34 =>
      's prayer for safety and faith';

  @override
  String get dhikrScreen_steadfastInPrayerMe_8ce7b5 =>
      'Steadfast in prayer, me and my children';

  @override
  String get dhikrScreen_mercyForMeMy_3edb52 =>
      'Mercy for me, my parents, the believers';

  @override
  String get dhikrScreen_prayerForParents_ae7e5c => 's prayer for parents';

  @override
  String get dhikrScreen_entryOfTruthExit_88c367 =>
      'Entry of truth, exit of truth';

  @override
  String get dhikrScreen_prayerOfTheYouth_1bf835 =>
      'Prayer of the youth of the cave';

  @override
  String get dhikrScreen_askAllahForMore_07c189 =>
      'Ask Allah for more — of knowledge';

  @override
  String get dhikrScreen_allahAnswersAndSaves_c337ab =>
      'Allah answers and saves from every distress';

  @override
  String get dhikrScreen_allahIsTheBest_1adf97 =>
      'Allah is the best of inheritors';

  @override
  String get dhikrScreen_blessedLandingWhereverYou_273aaf =>
      'A blessed landing wherever you stop';

  @override
  String get dhikrScreen_refugeFromTheWhispers_7ff5fd =>
      'Refuge from the whispers of devils';

  @override
  String get dhikrScreen_mercyFromTheBest_b394bb =>
      'Mercy from the Best of the Merciful';

  @override
  String get dhikrScreen_pardonAndMercyFrom_5d9eb1 =>
      'Pardon and mercy from the Most Merciful';

  @override
  String get dhikrScreen_piousSpousesAndRighteous_e9918c =>
      'Pious spouses and righteous offspring';

  @override
  String get dhikrScreen_prayerForThoseWho_1ccfb5 =>
      ' prayer for those who repent';

  @override
  String get dhikrScreen_gratitudeForParentsRighteousness_966d90 =>
      'Gratitude for parents, righteousness in offspring';

  @override
  String get dhikrScreen_pleaGiftOfIshaq_5568af => 's plea — gift of Ishaq ﷺ';

  @override
  String get dhikrScreen_loveForTheBelievers_d0cae3 =>
      'Love for the believers before us';

  @override
  String get dhikrScreen_pureTawakkulOnYou_02bc03 =>
      's pure tawakkul — On You we rely';

  @override
  String get dhikrScreen_forgivenessForEveryBelieving_e256a1 =>
      'Forgiveness for every believing home';

  @override
  String get dhikrScreen_tasbeehByTheWeight_27484a =>
      'Tasbeeh by the weight of Allah\\';

  @override
  String get dhikrScreen_tasbeehByTheNumber_224c3f =>
      'Tasbeeh by the number of all that He made';

  @override
  String get dhikrScreen_tasbeehThatFillsAll_4b1a52 =>
      'Tasbeeh that fills all that Allah created';

  @override
  String get dhikrScreen_paradiseSoughtTheFire_5740e3 =>
      'Paradise sought — the Fire\\';

  @override
  String get dhikrScreen_cryToTheOne_30f419 =>
      'Cry to the One who hears, sees, and knows';

  @override
  String get dhikrScreen_nameOnTheCorner_b6afeb =>
      's name on the corner of the Kaaba';

  @override
  String get dhikrScreen_theDuaBetweenYemen_0bea3e =>
      'The dua between Yemen Corner and Black Stone';

  @override
  String get dhikrScreen_prayAtTheStation_178d24 =>
      'Pray at the station of Ibrahim ﷺ';

  @override
  String get dhikrScreen_tawheedDeclaredAtopSafa_828769 =>
      'Tawheed declared atop Safa and Marwah';

  @override
  String get dhikrScreen_reaffirmTheOnenessOf_8589ea =>
      'Reaffirm the Oneness of Allah';

  @override
  String get dhikrScreen_magnifyAllahAtEvery_448549 =>
      'Magnify Allah at every threshold of Hajj';

  @override
  String get dhikrScreen_magnifyAllahOnThe_0fbc83 =>
      'Magnify Allah on the day of sacrifice';

  @override
  String get dhikrScreen_knowledgeProvisionHealingSought_9733f3 =>
      'Knowledge, provision, healing — sought in Makkah';

  @override
  String get dhikrScreen_theDuaMostRepeated_a9da8d =>
      'The dua most repeated by the Prophet ﷺ';

  @override
  String get dhikrScreen_refugeFromEveryTrial_8ca1b1 =>
      'Refuge from every trial of life and death';

  @override
  String get dhikrScreen_refugeFromEveryWeakness_b1a834 =>
      'Refuge from every weakness of body and soul';

  @override
  String get dhikrScreen_refugeFromSevereTrial_0029f0 =>
      'Refuge from severe trial and enemy\\';

  @override
  String get dhikrScreen_religionSetRightWorld_3b0102 =>
      'Religion set right, world and Akhirah made best';

  @override
  String get dhikrScreen_guidancePietyVirtueSelf_cc439a =>
      'Guidance, piety, virtue, self-sufficiency';

  @override
  String get dhikrScreen_refugeFromWeaknessWealth_d879f5 =>
      'Refuge from weakness — wealth of piety within';

  @override
  String get dhikrScreen_theGuiderOfHearts_1f40d9 =>
      'The Guider of hearts — turn ours to obedience';

  @override
  String get dhikrScreen_turnerOfHeartsMake_eba687 =>
      'Turner of hearts — make mine firm on the deen';

  @override
  String get dhikrScreen_wellBeingInBoth_442958 => 'Well-being in both worlds';

  @override
  String get dhikrScreen_rewardsSaveFromDisgrace_8b71bb =>
      'Rewards, save from disgrace and grave\\';

  @override
  String get dhikrScreen_mindForGoodVictory_582759 =>
      'Mind for good, victory for good';

  @override
  String get dhikrScreen_refugeFromEvilOf_0c8916 =>
      'Refuge from evil of every sense and limb';

  @override
  String get dhikrScreen_theForgiverWhoLoves_e5d83f =>
      'The Forgiver who loves the repentant';

  @override
  String get dhikrScreen_takeMeBeforeYou_28ef55 =>
      'Take me before You take me astray';

  @override
  String get dhikrScreen_everyGoodAndRefuge_4205e2 =>
      'Every good — and refuge from every evil';

  @override
  String get dhikrScreen_standingSittingLyingGuarded_254177 =>
      'Standing, sitting, lying — guarded in Islam';

  @override
  String get dhikrScreen_refugeFromCowardiceMiserliness_9b59bd =>
      'Refuge from cowardice, miserliness, fitnah';

  @override
  String get dhikrScreen_forgivenessForJestAnd_e683b5 =>
      'Forgiveness for jest and serious, known and unknown';

  @override
  String get dhikrScreen_forgiveMeWithForgiveness_894a1a =>
      'Forgive me with a forgiveness from You';

  @override
  String get dhikrScreen_submissionBeliefRepentanceFull_7338d6 =>
      'Submission, belief, repentance, full trust';

  @override
  String get dhikrScreen_mercyForgivenessParadiseSaved_0d9edd =>
      'Mercy, forgiveness, Paradise — saved from the Fire';

  @override
  String get dhikrScreen_refugeFromEvilSeen_140ec4 =>
      'Refuge from evil seen and unseen';

  @override
  String get dhikrScreen_provisionThatLastsTill_dcef82 =>
      'Provision that lasts till life\\';

  @override
  String get dhikrScreen_sinsForgivenHomeSpacious_2ac37c =>
      'Sins forgiven, home spacious, provision blessed';

  @override
  String get dhikrScreen_favorAndMercyNone_f665cf =>
      'Favor and mercy — none possesses them but You';

  @override
  String get dhikrScreen_refugeFromDrowningBurning_402b3e =>
      'Refuge from drowning, burning, sudden death';

  @override
  String get dhikrScreen_refugeFromHypocrisyShowiness_d863c2 =>
      'Refuge from hypocrisy, showiness, rebellion';

  @override
  String get dhikrScreen_refugeFromPovertyScarcity_03ef3d =>
      'Refuge from poverty, scarcity, oppression';

  @override
  String get dhikrScreen_refugeFromHeartThat_21f7ab =>
      'Refuge from a heart that won\\';

  @override
  String get dhikrScreen_payMyDebtEnrich_f5affc =>
      'Pay my debt, enrich me from poverty';

  @override
  String get dhikrScreen_allahCalledByHis_c11af9 =>
      'Allah called by His most beautiful names';

  @override
  String get dhikrScreen_theAccepterOfRepentance_4f2d60 =>
      'The Accepter of repentance always accepts';

  @override
  String get dhikrScreen_anEasyReckoningOn_11b060 =>
      'An easy reckoning on the Day';

  @override
  String get dhikrScreen_remembranceGratitudeAndThe_d7ee7b =>
      'Remembrance, gratitude, and the best worship';

  @override
  String get dhikrScreen_eternalBlissWithThe_dc255b =>
      'Eternal bliss with the Prophet ﷺ in Firdaws';

  @override
  String get dhikrScreen_forgiveSinsKnownHidden_ceda62 =>
      'Forgive sins — known, hidden, intended, mistaken';

  @override
  String get dhikrScreen_refugeFromBeingCrushed_4ba6ac =>
      'Refuge from being crushed by debt and enemy';

  @override
  String get dhikrScreen_askForParadiseRefuge_4bf2eb =>
      'Ask for Paradise, refuge from the Fire';

  @override
  String get dhikrScreen_forgiveGuideProvideProtect_e93013 =>
      'Forgive, guide, provide, protect';

  @override
  String get dhikrScreen_sensesMadeBeneficialAnd_4da09c =>
      'Senses made beneficial — and lasting';

  @override
  String get dhikrScreen_theMostBeneficentThe_65d7a6 =>
      'The Most Beneficent, the Originator of all';

  @override
  String get dhikrScreen_allahTruthOwnerOf_d4bede =>
      'Allah — Truth, Owner of all dominion';

  @override
  String get dhikrScreen_submissionWithFullSincerity_cbd7b6 =>
      'Submission with full sincerity';

  @override
  String get dhikrScreen_amongTheGuidedThe_e4d9d0 =>
      'Among the guided, the healthy, the chosen';

  @override
  String get dhikrScreen_whatTheProphetAsked_e3a810 =>
      'What the Prophet ﷺ asked — I ask too';

  @override
  String get dhikrScreen_sayyidAlIstighfarThe_51076a =>
      'Sayyid al-Istighfar — the master of all repentance';

  @override
  String get dhikrScreen_refugeFromEveryEvil_ea8dab =>
      'Refuge from every evil that comes by night';

  @override
  String get dhikrScreen_blessEverySenseEvery_e7779d =>
      'Bless every sense, every limb';

  @override
  String get dhikrScreen_smallAndGreatFirst_dbcc00 =>
      'Small and great, first and last, open and secret';

  @override
  String get dhikrScreen_noneWithholdsWhatYou_c4dca7 =>
      'None withholds what You give, none gives what You hold';

  @override
  String get dhikrScreen_forgiveGuideProvideElevate_55fa36 =>
      'Forgive, guide, provide, elevate';

  @override
  String get dhikrScreen_increaseFavorBeKind_5fbc5c =>
      'Increase favor, be kind, never displeased';

  @override
  String get dhikrScreen_beautifyOurCharacterAs_cc5d8c =>
      'Beautify our character as You beautified our creation';

  @override
  String get dhikrScreen_firmInBeliefGuided_73f8af =>
      'Firm in belief — guided and guiding';

  @override
  String get dhikrScreen_wisdomAndWithIt_e8e5bd =>
      'Wisdom — and with it, multitudes of good';

  @override
  String get dhikrScreen_nameShieldsFromEvery_59e06f =>
      's name shields from every harm';

  @override
  String get dhikrScreen_mightAgainstEveryShaytan_73b152 =>
      's might against every Shaytan';

  @override
  String get dhikrScreen_dayBlessedFromBeginning_c6d87d =>
      'A day blessed from beginning to end';

  @override
  String get dhikrScreen_witnessNoneDeservesWorship_385aa9 =>
      'Witness — none deserves worship but You';

  @override
  String get dhikrScreen_refugeFromHumiliatingOld_46a3f0 =>
      'Refuge from a humiliating old age';

  @override
  String get dhikrScreen_guidedToTheBest_03e8d2 =>
      'Guided to the best, saved from the worst';

  @override
  String get dhikrScreen_faithSetRightHome_08f8e1 =>
      'Faith set right, home wide, provision blessed';

  @override
  String get dhikrScreen_refugeFromEveryInner_dc67c7 =>
      'Refuge from every inner and outer disease';

  @override
  String get dhikrScreen_refugeFromEveryKind_dfbe62 =>
      'Refuge from every kind of bad end';

  @override
  String get dhikrScreen_steadfastGratefulRightlyGuided_45b393 =>
      'Steadfast, grateful, rightly-guided heart';

  @override
  String get dhikrScreen_theLoveOfAllah_3bf08a =>
      'The love of Allah, His angels, His prophets';

  @override
  String get dhikrScreen_loveOfAllahAbove_4c81b3 =>
      'Love of Allah above love of self';

  @override
  String get dhikrScreen_bestDeedsLastBest_2ff65e =>
      'Best deeds last — best day is meeting You';

  @override
  String get dhikrScreen_pureLifeAndPeaceful_a7eb0f =>
      'A pure life and a peaceful return';

  @override
  String get dhikrScreen_patientGratefulSmallIn_059385 =>
      'Patient, grateful — small in own eyes';

  @override
  String get dhikrScreen_theBestRequestAnd_cd3f6f =>
      'The best request and the best reward';

  @override
  String get dhikrScreen_theHighestLevelOf_221efa =>
      'The highest level of Paradise';

  @override
  String get dhikrScreen_firdawsTheBestOf_01be47 =>
      'Firdaws — the best of all that\\';

  @override
  String get dhikrScreen_mentionRaisedSinsErased_c6e2f3 =>
      'Mention raised, sins erased, heart purified';

  @override
  String get dhikrScreen_mercyPleasureParadiseSaved_8b4a98 =>
      'Mercy, pleasure, Paradise — saved from Fire';

  @override
  String get dhikrScreen_noSinUncoveredNo_efd903 =>
      'No sin uncovered, no debt unpaid';

  @override
  String get dhikrScreen_mercyThatGuidesSets_89b7cf =>
      'Mercy that guides, sets right, purifies';

  @override
  String get dhikrScreen_trueBeliefCertainKnowledge_d27506 =>
      'True belief, certain knowledge, Allah\\';

  @override
  String get dhikrScreen_withTheProphetsThe_b2123f =>
      'With the Prophets, the martyrs, the truthful';

  @override
  String get dhikrScreen_everyNeedEntrustedTo_8b33b6 =>
      'Every need entrusted to the Judge of all needs';

  @override
  String get dhikrScreen_bestOfWhatAllah_70d237 =>
      'Best of what Allah promised His servants';

  @override
  String get dhikrScreen_safetyOnTheDay_89cb9f =>
      'Safety on the Day, Paradise on the Eternal Day';

  @override
  String get dhikrScreen_glorifyTheOneOf_de3669 =>
      'Glorify the One of unmatched honor and knowledge';

  @override
  String get dhikrScreen_pardonPlentySecurityIn_d6b56a =>
      'Pardon, plenty, security in deen and dunya';

  @override
  String get dhikrScreen_healthFaithEthicsSuccess_000fef =>
      'Health, faith, ethics, success, mercy';

  @override
  String get dhikrScreen_healthPurityEthicsAcceptance_b6929c =>
      'Health, purity, ethics, acceptance';

  @override
  String get dhikrScreen_guidedSecureVictorious_b56e05 =>
      'Guided, secure, victorious';

  @override
  String get dhikrScreen_refugeFromEveryCreature_cbe2de =>
      'Refuge from every creature in Allah\\';

  @override
  String get dhikrScreen_theOneWhoAnswers_f2e37f =>
      'The One who answers the compelled and broken';

  @override
  String get dhikrScreen_morningReachedByAllah_b03f32 =>
      'Morning reached by Allah\\';

  @override
  String get dhikrScreen_refugeSoughtByMusa_176ee5 =>
      'Refuge sought by Musa, Isa, Ibrahim';

  @override
  String get dhikrScreen_allTheGoodPower_418dc3 =>
      'All the good — power, mercy, blessings';

  @override
  String get dhikrScreen_allPraiseAndDominion_27662b =>
      'All praise and dominion belong to You';

  @override
  String get dhikrScreen_pastPardonedFutureProtected_a8bfa1 =>
      'Past pardoned, future protected';

  @override
  String get dhikrScreen_takeMyForelockTo_a44b8f =>
      'Take my forelock to goodness';

  @override
  String get dhikrScreen_strengthForWeaknessDignity_dce155 =>
      'Strength for weakness, dignity for shame';

  @override
  String get dhikrScreen_justiceForThoseWho_4e52f3 =>
      'Justice for those who block the truth';

  @override
  String get dhikrScreen_refugeFromEveryFatal_b155a7 =>
      'Refuge from every fatal calamity';

  @override
  String get dhikrScreen_refugeFromEveryBad_a9e27f =>
      'Refuge from every bad end and trial';

  @override
  String get dhikrScreen_turnBackEveryEvil_66e6fa =>
      'Turn back every evil intention to its source';

  @override
  String get dhikrScreen_justiceAndRefugeAgainst_e4e734 =>
      'Justice and refuge against their evils';

  @override
  String get dhikrScreen_forgivenessForMeMy_27b932 =>
      'Forgiveness for me, my parents, all believers';

  @override
  String get dhikrScreen_purifyHeartDeedsTongue_10837e =>
      'Purify heart, deeds, tongue, eyes';

  @override
  String get dhikrScreen_selfContentWithAllah_68c73a =>
      'A self content with Allah\\';

  @override
  String get dhikrScreen_youKnowMySecret_2b63c7 =>
      'You know my secret and my need';

  @override
  String get dhikrScreen_certaintyNothingHarmsWhat_e513d7 =>
      'Certainty: nothing harms what\\';

  @override
  String get dhikrScreen_beliefLightAndLawful_e69a59 =>
      'Belief, light, and lawful provision';

  @override
  String get dhikrScreen_totalLoveAndTotal_3d137e =>
      'Total love and total struggle for Allah';

  @override
  String get dhikrScreen_makeWhatYouWithheld_14be7d =>
      'Make what You withheld a strength in obedience';

  @override
  String get dhikrScreen_praiseTheOwnerOf_244f8b =>
      'Praise the Owner of every beautiful name';

  @override
  String get dhikrScreen_allahKnowsTheHearts_d6010c =>
      'Allah knows the hearts, the heavens, and beyond';

  @override
  String get dhikrScreen_hopeBuiltOnAllah_217ad7 => 'Hope built on Allah\\';

  @override
  String get dhikrScreen_belovedToTheBelievers_b1f5a3 =>
      'Beloved to the believers, free from the wicked';

  @override
  String get dhikrScreen_mightPowerAndMajesty_91ca0a =>
      's might, power, and majesty';

  @override
  String get dhikrScreen_gratefulPatientHelpfulTo_3710c6 =>
      'Grateful, patient, helpful to Allah\\';

  @override
  String get dhikrScreen_withholdYourGoodFor_0d39a1 =>
      't withhold Your good for my evil';

  @override
  String get dhikrScreen_settledLifeAmpleProvision_77b32b =>
      'A settled life, ample provision, righteous deeds';

  @override
  String get dhikrScreen_wealthInNeedingYou_547729 =>
      'Wealth in needing You — never free of You';

  @override
  String get dhikrScreen_defectsCoveredFearsCalmed_a85797 =>
      'Defects covered, fears calmed, anguish lifted';

  @override
  String get dhikrScreen_openTheGatesOf_402eac =>
      'Open the gates of mercy and generosity';

  @override
  String get dhikrScreen_holdUsInYour_b82607 =>
      'Hold us in Your safety — never abandon us';

  @override
  String get dhikrScreen_withinYourSecurityYour_f72b6e =>
      'Within Your security, Your goodness';

  @override
  String get dhikrScreen_everySinEveryDistress_eab128 =>
      'Every sin, every distress, every side';

  @override
  String get dhikrScreen_helpInDeathIn_342d0b =>
      'Help in death, in the grave, on the Bridge';

  @override
  String get dhikrScreen_beautifiedLifeBlessedGifts_7f2384 =>
      'Beautified life, blessed gifts, kept favors';

  @override
  String get dhikrScreen_firmFootingBlessedEnd_c78f99 =>
      'Firm footing, blessed end, kept covenant';

  @override
  String get dhikrScreen_hopesFulfilledEnemiesRepelled_afd008 =>
      'Hopes fulfilled, enemies repelled, affairs set right';

  @override
  String get dhikrScreen_guidedToTheUpright_9e1527 =>
      'Guided to the upright, protected from the self';

  @override
  String get dhikrScreen_lightAndForgivenessFrom_3923eb =>
      'Light and forgiveness from the Owner of the Throne';

  @override
  String get dhikrScreen_forgivenessForWhatRepented_6a44f8 =>
      'Forgiveness for what I repented and returned to';

  @override
  String get dhikrScreen_understandingThatDrawsNear_e1455e =>
      'Understanding that draws near to Allah';

  @override
  String get dhikrScreen_soulsDwellingInThe_1bd11b =>
      'Souls dwelling in the heights of piety';

  @override
  String get dhikrScreen_crossTheBridgeOf_4f4ff3 =>
      'Cross the bridge of desire by patience';

  @override
  String get dhikrScreen_followThePathOf_934775 =>
      'Follow the path of sincerity and certainty';

  @override
  String get dhikrScreen_helpAgainstTheSoul_44a7db =>
      'Help against the soul and against Shaytan';

  @override
  String get dhikrScreen_fearHappinessVictorySecurity_9017c9 =>
      'Fear, happiness, victory, security';

  @override
  String get dhikrScreen_entrustFamilyWealthChildren_1da596 =>
      'Entrust family, wealth, children — all to Allah';

  @override
  String get dhikrScreen_faithGuardedFaithPreserved_88eecb =>
      'Faith guarded, faith preserved';

  @override
  String get dhikrScreen_wellBeingTillThe_ee180d =>
      'Well-being till the end — sealed with forgiveness';

  @override
  String get dhikrScreen_whatProtectsMeFrom_052090 =>
      'What protects me from this world\\';

  @override
  String get dhikrScreen_mercyOnEverySoul_a9a197 => 'Mercy on every soul\\';

  @override
  String get dhikrScreen_burdenUsAsThose_78b517 =>
      't burden us as those before were burdened';

  @override
  String get dhikrScreen_mercyPardonForgivenessVictory_300143 =>
      'Mercy, pardon, forgiveness, victory';

  @override
  String get dhikrScreen_allahNeverFailsHis_c2265a =>
      'Allah never fails His promise';

  @override
  String get dhikrScreen_recordUsWithThe_b93190 =>
      'Record us with the witnesses of truth';

  @override
  String get dhikrScreen_forgivenessFirmnessAndVictory_a8b674 =>
      'Forgiveness, firmness, and victory';

  @override
  String get dhikrScreen_creationHasPurposeRefuge_ce2eee =>
      'Creation has purpose — refuge from the Fire';

  @override
  String get dhikrScreen_refugeFromTheDisgrace_605b1b =>
      'Refuge from the disgrace of the Fire';

  @override
  String get dhikrScreen_heardBelievedAskingForgiveness_d5387f =>
      'Heard, believed, asking forgiveness';

  @override
  String get dhikrScreen_sinsForgivenDeathAmong_bd82ed =>
      'Sins forgiven — death among the righteous';

  @override
  String get dhikrScreen_promisedRewardNeverDisgraced_490396 =>
      'Promised reward — never disgraced on Resurrection';

  @override
  String get dhikrScreen_provisionAndSignsFrom_81db14 =>
      'Provision and signs from the heavens';

  @override
  String get dhikrScreen_duaTheDuaOf_4b9d01 =>
      's dua — the dua of every repentant';

  @override
  String get dhikrScreen_spareUsFromThe_79732a =>
      'Spare us from the company of wrongdoers';

  @override
  String get dhikrScreen_patienceTillTheEnd_a8a4c4 =>
      'Patience till the end, death upon submission';

  @override
  String get dhikrScreen_hiddenInEveryChest_ce7671 => 's hidden in every chest';

  @override
  String get dhikrScreen_prayerForPrayerAccepted_e68fa6 =>
      's prayer for prayer accepted';

  @override
  String get dhikrScreen_mercyGrantedGuidancePrepared_5c6f63 =>
      'Mercy granted, guidance prepared';

  @override
  String get dhikrScreen_duaBeforePharaoh_2d90cd => 's dua before Pharaoh';

  @override
  String get dhikrScreen_refugeFromClingingEvil_b1e6e4 =>
      'Refuge from a clinging, evil punishment';

  @override
  String get dhikrScreen_piousSpousesRighteousChildren_64225f =>
      'Pious spouses, righteous children, leadership';

  @override
  String get dhikrScreen_allahIsEverThankful_464c97 =>
      'Allah is ever-thankful for every effort';

  @override
  String get dhikrScreen_mercyEncompassingEveryRepentant_fb0759 =>
      'Mercy encompassing every repentant soul';

  @override
  String get dhikrScreen_mercyOnThatDay_a1b18b =>
      'Mercy on that Day — the great success';

  @override
  String get dhikrScreen_loveAndForgivenessFor_660a56 =>
      'Love and forgiveness for earlier believers';

  @override
  String get dhikrScreen_kindnessAndMercyUpon_1c62c8 =>
      'Kindness and mercy upon Allah\\';

  @override
  String get dhikrScreen_pureTawakkulToYou_389089 =>
      's pure tawakkul — to You we return';

  @override
  String get dhikrScreen_neverFitnahForThose_dc1363 =>
      'Never a fitnah for those who disbelieve';

  @override
  String get dhikrScreen_completeTheLightForgive_fd7380 =>
      'Complete the light — forgive us';

  @override
  String get dhikrScreen_strongerThanServantThe_4cc56e =>
      'Stronger than a servant — the night\\';

  @override
  String get dhikrScreen_refugeFromEveryVisible_b81e69 =>
      'Refuge from every visible evil before sleep';

  @override
  String get dhikrScreen_refugeFromEveryWhisper_b030ed =>
      'Refuge from every whisper before sleep';

  @override
  String get dhikrScreen_guardedByAnAngel_65d1c1 =>
      'Guarded by an angel until morning';

  @override
  String get dhikrScreen_twoVersesThatSuffice_1941c5 =>
      'Two verses that suffice for the whole night';

  @override
  String get dhikrScreen_pureTawheedDeclaredBefore_50673a =>
      'Pure tawheed declared before sleep';

  @override
  String get dhikrScreen_sleepIsSmallDeath_b4b84d =>
      'Sleep is a small death — entrusted to Allah';

  @override
  String get dhikrScreen_whoeverDiesThatNight_75dda7 =>
      'Whoever dies that night dies on fitrah';

  @override
  String get dhikrScreen_guardTheSoulThat_a0850e =>
      'Guard the soul that returns, or have mercy';

  @override
  String get dhikrScreen_refugeFromThePunishment_18162a =>
      'Refuge from the punishment of that Day';

  @override
  String get dhikrScreen_gratitudeForShelterFood_1f5e94 =>
      'Gratitude for shelter, food, and care';

  @override
  String get dhikrScreen_handOverTheSoul_fda192 =>
      'Hand over the soul before sleep';

  @override
  String get dhikrScreen_joinTheHighestAssembly_68e2d3 =>
      'Join the highest assembly while you sleep';

  @override
  String get dhikrScreen_gratitudeBeforeClosingThe_20f3db =>
      'Gratitude before closing the eyes';

  @override
  String get dhikrScreen_surahAsSajdahRecited_a4beaa =>
      'Surah As-Sajdah recited before sleep';

  @override
  String get dhikrScreen_refugeFromEvilBefore_a5d312 =>
      'Refuge from evil before entering the toilet';

  @override
  String get dhikrScreen_seekForgivenessAsYou_f14da9 =>
      'Seek forgiveness as you leave';

  @override
  String get dhikrScreen_bismillahEveryBiteBegins_8a678d =>
      'Bismillah — every bite begins with Allah';

  @override
  String get dhikrScreen_catchUpTheName_e6d0d6 =>
      'Catch up the name — Allah at start and end';

  @override
  String get dhikrScreen_threeSunnahDuasTo_a56769 =>
      'Three Sunnah duas to thank Allah after eating';

  @override
  String get dhikrScreen_beginWithAllahThe_a64af2 =>
      'Begin with Allah, the Most Merciful, before drinking';

  @override
  String get dhikrScreen_openTheEightDoors_011a50 =>
      'Open the eight doors of Paradise after wudu';

  @override
  String get dhikrScreen_openTheDoorsOf_15e084 => 'Open the doors of Allah\\';

  @override
  String get dhikrScreen_bountyAsYouLeave_a06fc6 =>
      's bounty as you leave the masjid';

  @override
  String get dhikrScreen_mayAllahGuideYou_af987e =>
      'May Allah guide you and rectify your state';

  @override
  String get dhikrScreen_askAllahLordOf_4a3eb0 =>
      'Ask Allah, Lord of the Throne, to grant healing';

  @override
  String get dhikrScreen_allahIsTheOnly_9750c1 =>
      'Allah is the only One who cures';

  @override
  String get dhikrScreen_shieldChildrenWithAllah_858245 =>
      'Shield children with Allah\\';

  @override
  String get dhikrScreen_anicPrayerForOne_e18aca => 'anic prayer for one\\';

  @override
  String get dhikrScreen_twoPhrasesBelovedTo_5d16a7 =>
      'Two phrases beloved to the Most Merciful';

  @override
  String get dhikrScreen_allahLovesToPardon_a64d0a =>
      'Allah loves to pardon — so ask';

  @override
  String get dhikrScreen_treasureFromBeneathThe_87d578 =>
      'A treasure from beneath the Throne';

  @override
  String get dhikrScreen_theFourPhrasesDearest_680ef8 =>
      'The four phrases dearest to Allah';

  @override
  String get dhikrScreen_theDuaThatReleases_ddc7eb =>
      'The dua that releases from every distress';

  @override
  String get dhikrScreen_protectionForHomeAnd_0c4973 =>
      's protection for home and offspring';

  @override
  String get dhikrScreen_theCompleteDhikrOf_31b993 =>
      'The complete dhikr of Tawheed';

  @override
  String get dhikrScreen_trialPurifiedByAllah_39fb26 =>
      'Trial purified by Allah\\';

  @override
  String get dhikrScreen_guidanceBeforeAnyChoice_50eb02 =>
      's guidance before any choice';

  @override
  String get dhikrScreen_completeRuqyaSequenceFatihah_5ced40 =>
      'Complete ruqya sequence — Fatihah and refuge';

  @override
  String get dhikrScreen_sinsForgivenEvenIf_cd9a85 =>
      'Sins forgiven, even if like the foam of the sea';

  @override
  String get dhikrScreen_freedHasanatSinsErased_54ebbb =>
      '10 freed · 100 hasanat · 100 sins erased · Shaytan repelled';

  @override
  String get dhikrScreen_blessingsDescendFromAllah_41e8f6 =>
      '10 blessings descend from Allah upon you';

  @override
  String get dhikrScreen_askAllahToBless_3470fe =>
      'Ask Allah to bless and beautify your day';

  @override
  String get dhikrScreen_guaranteedJannahIfYou_6f7054 =>
      'Guaranteed Jannah, if you die this day';

  @override
  String get dhikrScreen_yourLifeEntrustedTo_77feba =>
      'Your life entrusted to the Ever-Living';

  @override
  String get dhikrScreen_allEvilInHis_f02365 =>
      'All evil in His creation repelled from you';

  @override
  String get dhikrScreen_nothingShallHarmYou_cbc2fc =>
      'Nothing shall harm you, by perfect words';

  @override
  String get dhikrScreen_shieldYourselfFromMinor_2a73ed =>
      'Shield yourself from minor and major shirk, morning & evening';

  @override
  String get dhikrScreen_completeProtectionInThe_620c30 =>
      'Complete protection in the name of Allah';

  @override
  String get dhikrScreen_weightierThanAllVoluntary_7af10a =>
      'Weightier than all voluntary prayers, from dawn till dusk';

  @override
  String get dhikrScreen_reciteMorningEveningEarn_77aa68 =>
      'Recite morning & evening, earn the pleasure & blessing of Allah on the Day of Judgment';

  @override
  String get dhikrScreen_yourRewardAwaitsDirectly_1827f4 =>
      'Your reward awaits directly with Allah when you meet Him';

  @override
  String get dhikrScreen_reciteMorningEveningTo_1843f8 =>
      'Recite morning & evening to fulfill your obligation of gratitude to Allah';

  @override
  String get dhikrScreen_theProphetTaughtThis_50fab2 =>
      'The Prophet taught this dua for morning and evening, do not miss it';

  @override
  String get dhikrScreen_dominionAtTheStart_690ca9 =>
      's dominion at the start of your morning, all kingdom belongs to Him';

  @override
  String get dhikrScreen_asEveningFallsThe_934b7e =>
      'As evening falls, the entire kingdom belongs to Allah alone';

  @override
  String get dhikrScreen_endYourEveningUpon_ada386 =>
      'End your evening upon the pure fitrah, as the Prophet (ﷺ) taught';

  @override
  String get dhikrScreen_satanWillNotEnter_446a1c =>
      'Satan will not enter the home of one who recites this';

  @override
  String get dhikrScreen_readingLastVersesOf_99a432 =>
      'Reading last 2 verses of al-Baqarah will suffice you';

  @override
  String get dhikrScreen_everyDuaInThis_f790b4 =>
      'Every dua in this verse - Allah said: I have done so';

  @override
  String get dhikrScreen_guardedByAllahUntil_f4d276 =>
      'Guarded by Allah until morning comes';

  @override
  String get dhikrScreen_recitingEqualsReadingThe_e0a62a =>
      'Reciting 3x equals reading the entire Quran, Bukhari & Muslim';

  @override
  String get dhikrScreen_reciteAtDawnDusk_4173a8 =>
      'Recite 3x at dawn & dusk, suffice you against all harm';

  @override
  String get dhikrScreen_refugeFromTheWhisperer_bdd280 =>
      'Refuge from the whisperer, in the Lord of Mankind';

  @override
  String get dhikrScreen_reciteMorningEveningYour_c464cb =>
      'Recite 3x morning & evening, your gratitude to Allah is fulfilled';

  @override
  String get dhikrScreen_sufficientAgainstEveryHarm_0a3206 =>
      'Sufficient against every harm recited 3 times';

  @override
  String get dhikrScreen_doorsOfAllahMercy_937263 =>
      'Doors of Allah mercy open wide for you';

  @override
  String get dhikrScreen_worryAndSorrowLifted_fd1f04 =>
      'Worry and sorrow lifted by the will of Allah';

  @override
  String get dhikrScreen_guardedInYourDeen_bb9b33 =>
      'Guarded in your deen dunya and akhirah';

  @override
  String get dhikrScreen_evilRepelledFromEvery_3f1588 =>
      'Evil repelled from every direction';

  @override
  String get dhikrScreen_heartHeldByThe_0f7007 =>
      'Heart held by the Ever Living Ever Sustaining';

  @override
  String get dhikrScreen_fulfilledYourObligationOf_44ddfc =>
      'Fulfilled your obligation of giving thanks';

  @override
  String get dhikrScreen_recitingTheLastVerses_3d260d =>
      'Reciting the last 2 verses of Al-Baqarah at night suffices you';

  @override
  String get dhikrScreen_gratitudeThatMultipliesYour_24c5dd =>
      'Gratitude that multiplies your blessings';

  @override
  String get dhikrScreen_startPureOnThe_a0198e =>
      'Start pure on the fitrah of Islam';

  @override
  String get dhikrScreen_praiseThatRipplesThrough_cef105 =>
      'Praise that ripples through all creation';

  @override
  String get dhikrScreen_guidedToEveryGood_e5e914 =>
      'Guided to every good this day';

  @override
  String get dhikrScreen_allahWillFreeHim_20396f =>
      'Allah will free him from the Fire who reads this 4 times';

  @override
  String get dhikrScreen_wellbeingOfBodyHearing_f9d3af =>
      'Wellbeing of body hearing and sight';

  @override
  String get dhikrScreen_guidedByTheHand_da5d5b =>
      'Guided by the hand of Allah';

  @override
  String get dhikrScreen_wordsHeavierThanThe_6a9c4f =>
      'Words heavier than the heavens and earth';

  @override
  String get dhikrScreen_beginYourDayIn_530c07 =>
      'Begin your day in surrender to Allah';

  @override
  String get dhikrScreen_theyAreEnoughFor_14acc6 =>
      'They are enough for you - recite before sleep';

  @override
  String get dhikrScreen_wellBeing_85c1f4 => 'Well-being';

  @override
  String get dhikrScreen_fulfilled_7d487f => 'Fulfilled.';

  @override
  String get dhikrScreen_wellBeingInFaith_e70162 =>
      'Well-being in Faith · Family · Wealth';

  @override
  String get dhikrScreen_concealMyFaultsCalm_0252f3 =>
      'Conceal my faults · Calm my fears';

  @override
  String get dhikrScreen_protectionFromEvilEye_3b6074 =>
      'Protection from Evil Eye';

  @override
  String get dhikrScreen_doNotLeaveMe_1e2414 =>
      'Do not leave me to myself\\neven for the blink of an eye';

  @override
  String dhikrScreen_35c165_35c165(String arg1) {
    return '$arg1  ';
  }

  @override
  String get dhikrScreen_allahWillSufficeYou_f177b2 => 'Allah will suffice you';

  @override
  String get dhikrScreen_againstWhateverConcernsYou_176991 =>
      'against whatever concerns you';

  @override
  String get dhikrScreen_doNotBurdenUs_4401b2 =>
      'Do not burden us beyond what we can bear, pardon us and have mercy';

  @override
  String get dhikrScreen_weHaveBelievedForgive_d34c4a =>
      'We have believed — forgive our sins and protect us from the Fire';

  @override
  String get dhikrScreen_ownerOfSovereigntyIn_b0948c =>
      'O Owner of Sovereignty — in Your Hand is all good, You are Most Capable';

  @override
  String get dhikrScreen_forgiveOurSinsAnd_692ad8 =>
      'Forgive our sins and excess, make us firm and grant us victory';

  @override
  String get dhikrScreen_youCreatedNotIn_d24f50 =>
      'You created not in vain — protect us from the punishment of the Fire';

  @override
  String get dhikrScreen_weHaveWrongedOurselves_24ab82 =>
      'We have wronged ourselves — without Your mercy we are lost';

  @override
  String get dhikrScreen_ourLordDoNot_ca9f87 =>
      'Our Lord, do not place us with the wrongdoing people';

  @override
  String get dhikrScreen_doNotMakeUs_d5b5d2 =>
      'Do not make us a trial for the oppressors';

  @override
  String get dhikrScreen_makeMeSteadfastIn_cc7dfe =>
      'Make me steadfast in prayer — and my descendants too';

  @override
  String get dhikrScreen_forgiveMeMyParents_1a319b =>
      'Forgive me, my parents, and the believers on the Day of Reckoning';

  @override
  String get dhikrScreen_bringMeInBy_62c19a =>
      'Bring me in by an entrance of truth and out by an exit of truth';

  @override
  String get dhikrScreen_myLordIncreaseMe_2fec5a =>
      'My Lord, increase me in knowledge';

  @override
  String get dhikrScreen_seekRefugeInYou_3a2efd =>
      'I seek refuge in You from the whispers of devils';

  @override
  String get dhikrScreen_forgiveAndHaveMercy_58f2df =>
      'Forgive and have mercy — You are the Best of the Merciful';

  @override
  String get dhikrScreen_enableMeToBe_e78eb3 =>
      'Enable me to be grateful for Your favour on me and my parents';

  @override
  String get dhikrScreen_myLordHaveWronged_e6421b =>
      'My Lord, I have wronged myself — so forgive me';

  @override
  String get dhikrScreen_myLordWillNever_d4a663 =>
      'My Lord, I will never be a supporter of the criminals';

  @override
  String get dhikrScreen_myLordSaveMe_ea6c67 =>
      'My Lord, save me from the wrongdoing people';

  @override
  String get dhikrScreen_myLordAmIn_0acb2a =>
      'My Lord, I am in need of any good You send down to me';

  @override
  String get dhikrScreen_myLordHelpMe_80f8c7 =>
      'My Lord, help me against the corrupting people';

  @override
  String get dhikrScreen_ourLordAvertFrom_bc7354 =>
      'Our Lord, avert from us the punishment of Hell';

  @override
  String get dhikrScreen_ourLordYouEncompass_7e0f2a =>
      'Our Lord, You encompass all things in mercy and knowledge';

  @override
  String get dhikrScreen_enableMeToThank_d1f4df =>
      'Enable me to thank You and make my offspring righteous';

  @override
  String get dhikrScreen_myLordGrantMe_ef9ff1 =>
      'My Lord, grant me of the righteous';

  @override
  String get dhikrScreen_forgiveUsAndOur_60d1fd =>
      'Forgive us and our brothers who came before us in faith';

  @override
  String get dhikrScreen_uponYouWeRely_0c8229 =>
      'Upon You we rely, to You we turn, and to You is the destination';

  @override
  String get dhikrScreen_pauseRememberAllah_1ddb4d => 'Pause. Remember Allah.';

  @override
  String get dhikrScreen_mashaallahRewardSecured_f51254 =>
      'MashaAllah! Reward Secured';

  @override
  String get dhikrScreen_satanCannot_1c96dd => 'Satan cannot';

  @override
  String get dhikrScreen_enterTheHome_3086d7 => 'enter the home';

  @override
  String get dhikrScreen_whoeverRecites_ee68bc => 'Whoever recites';

  @override
  String get dhikrScreen_theLastTwoVerses_a865c4 => 'the last two verses';

  @override
  String get dhikrScreen_ofSurahAlBaqarah_302bf4 => 'of Surah Al-Baqarah';

  @override
  String get dhikrScreen_atNight_f3945a => 'at night --';

  @override
  String get dhikrScreen_theyWillBe_019495 => 'they will be';

  @override
  String get dhikrScreen_enoughForHim_6e37aa => 'enough for him';

  @override
  String get dhikrScreen_weHaveEnteredThe_f5ed3a =>
      'We have entered the evening';

  @override
  String get dhikrScreen_theKingdomBelongsTo_2f7681 =>
      'The Kingdom belongs to Allah';

  @override
  String get dhikrScreen_noneWorthyOfWorship_f1c87f =>
      'None worthy of worship but Allah alone';

  @override
  String get dhikrScreen_allPraiseHeIs_c3ece6 =>
      'All praise · He is All-Powerful over everything';

  @override
  String get dhikrScreen_weAskForThe_21b846 =>
      'We ask for the good of this night';

  @override
  String get dhikrScreen_saySeekRefuge_84c616 => 'Say: I seek refuge';

  @override
  String get dhikrScreen_inTheLordOf_39c875 => 'in the Lord of Mankind';

  @override
  String get dhikrScreen_theKingOfMankind_d99354 => 'the King of Mankind';

  @override
  String get dhikrScreen_theGodOfMankind_e5231c => 'the God of Mankind ,';

  @override
  String get dhikrScreen_heRetreatsWhenYou_1fea37 =>
      'He retreats when you remember Allah.';

  @override
  String get dhikrScreen_seekRefugeInThe_96a762 =>
      'Seek refuge in the Lord of Daybreak';

  @override
  String get dhikrScreen_sufficedInAllRespects_57c52b =>
      'Sufficed in all respects.';

  @override
  String get dhikrScreen_allahDoesNotBurden_63f3eb => 'Allah does not burden';

  @override
  String get dhikrScreen_soul_b7f1ee => 'a soul';

  @override
  String dhikrScreen_a5cfd1_a5cfd1(String count) {
    return '×$count';
  }

  @override
  String get dhikrScreen_equalsTheWholeQuran_a2b879 =>
      'Equals the whole Quran × 3';

  @override
  String get impactReportScreen_whoeverDoesAnAtom_9013b0 =>
      '“Whoever does an atom\\';

  @override
  String get impactReportScreen_theHomeOfThe_4602d2 =>
      '“The home of the Hereafter — that is the eternal life, if only they knew.” — Surah Al-Ankabut 29:64';

  @override
  String get impactReportScreen_raceTowardsForgivenessFrom_94d614 =>
      '“Race towards forgiveness from your Lord and a Garden as wide as the heavens and the earth.” — Surah Al-Hadid 57:21';

  @override
  String get impactReportScreen_andWhatIsThe_7eec52 =>
      '“And what is the life of this world except amusement of delusion?” — Surah Ali Imran 3:185';

  @override
  String get impactReportScreen_indeedWithHardshipComes_ea97fa =>
      '“Indeed, with hardship comes ease.” — Surah Ash-Sharh 94:6';

  @override
  String get impactReportScreen_singleGoodDeedIn_c126b4 =>
      '“A single good deed in Ramadan equals 70 in any other month.” Stack while the door is open.';

  @override
  String get impactReportScreen_theProphetSaidCharity_c154f4 =>
      'The Prophet ✍ said: charity does not decrease wealth — it grows it. (Muslim)';

  @override
  String get impactReportScreen_smilingAtYourBrother_8f55e4 =>
      '“Smiling at your brother is sadaqah.” You can earn even when your pockets are empty. (Tirmidhi)';

  @override
  String get impactReportScreen_theMostBelovedDeeds_f11906 =>
      '“The most beloved deeds to Allah are the most consistent, even if small.” (Bukhari)';

  @override
  String get impactReportScreen_inJannahIsWhat_ff6d55 =>
      '“In Jannah is what no eye has seen, no ear has heard, and no heart has imagined.” (Bukhari)';

  @override
  String get impactReportScreen_twoRakatsAtFajr_c8b238 =>
      'Two rakats at Fajr are better than the world and everything in it. (Muslim)';

  @override
  String get impactReportScreen_everyStepTowardSalah_62962f =>
      'Every step toward salah erases a sin and raises a rank. (Muslim)';

  @override
  String get impactReportScreen_everySeedYouDonate_618d1f =>
      'Every seed you donate plants a tree in someone else\\';

  @override
  String get impactReportScreen_takeWealthWithYou_784e85 =>
      't take wealth with you. Only the deeds it bought.';

  @override
  String get impactReportScreen_theAngelsRecordNothing_e03c03 =>
      'The angels record nothing too small. One Subhanallah may outweigh a mountain.';

  @override
  String get impactReportScreen_sadaqahIsTomorrow_794857 =>
      's sadaqah is tomorrow\\';

  @override
  String get impactReportScreen_heartThatGivesIs_4b6000 =>
      'A heart that gives is a heart Allah keeps full. Don\\';

  @override
  String get impactReportScreen_theReceiptWhatDid_d1c41b =>
      's the receipt. What did you send ahead?';

  @override
  String get impactReportScreen_imagineYourScaleOn_094d07 =>
      'Imagine your scale on Yawm al-Qiyamah. What weight are you adding today?';

  @override
  String get impactReportScreen_theWorldIsBorrowed_2eeb50 =>
      'The world is borrowed. The Akhirah is owned. Invest accordingly.';

  @override
  String get impactReportScreen_youBuryTheBody_bb5233 =>
      'You bury the body — but not the deeds. Send them ahead while you can.';

  @override
  String get impactReportScreen_righteousChildWhoPrays_7bcef4 =>
      'A righteous child who prays for you, a charity that flows, or knowledge that benefits — three eternal investments. (Muslim)';

  @override
  String get impactReportScreen_youWillMeetAllah_c19524 =>
      'You will meet Allah with your record. Make sure today\\';

  @override
  String get impactReportScreen_noDeedIsToo_c04d50 =>
      'No deed is too small for the One who counts atoms.';

  @override
  String impactReportScreen_lvl_987904(String _level, String arg1) {
    return 'Lvl $_level · $arg1';
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
      'Whoever does a good deed shall have ten times the like thereof.';

  @override
  String get impactReportScreen_whoeverReadsLetterFrom_36d74f =>
      'Whoever reads a letter from the Book of Allah, he will have one hasanah, and a hasanah is multiplied by ten.';

  @override
  String get impactReportScreen_twoHadithGrowThis_c8d4a2 =>
      'Two hadith grow this number side by side:\\n\\n';

  @override
  String impactReportScreen_dhikrRecitedLifetime_669e2a(String arg1) {
    return '  Dhikr recited (lifetime): $arg1\\n';
  }

  @override
  String impactReportScreen_hasanat_64c7b6(String arg1) {
    return '  → Hasanat: $arg1\\n\\n';
  }

  @override
  String impactReportScreen_ayahsReadLifetime_75eef6(String arg1) {
    return '  Ayahs read (lifetime): $arg1\\n';
  }

  @override
  String impactReportScreen_totalHasanaat_c43112(String arg1) {
    return 'Total hasanaat: $arg1';
  }

  @override
  String impactReportScreen_ayahs_6a500c(String arg1) {
    return '$arg1 ayahs';
  }

  @override
  String impactReportScreen_planted_90ec47(String arg1) {
    return '$arg1 planted';
  }

  @override
  String impactReportScreen_cycles_f6649b(String arg1) {
    return '$arg1 cycles';
  }

  @override
  String get impactReportScreen_whoeverSaysSubhanAllahiWa_4b6459 =>
      'Whoever says SubhanAllahi wa bihamdihi 100 times a day, his sins are forgiven even if they were like the foam of the sea.';

  @override
  String get impactReportScreen_subhanallahiWaBihamdihi_992976 =>
      'SubhanAllahi wa bihamdihi';

  @override
  String impactReportScreen_totalRecitations_5ed733(String arg1) {
    return 'Total recitations: $arg1\\n';
  }

  @override
  String impactReportScreen_dividedByForgivenessCycles_4e175d(String arg1) {
    return 'Divided by 100 → forgiveness cycles: $arg1';
  }

  @override
  String impactReportScreen_built_d62c2d(String arg1) {
    return '$arg1 built';
  }

  @override
  String impactReportScreen_dividedByPalaces_6f066c(String arg1) {
    return 'Divided by 10 → palaces: $arg1';
  }

  @override
  String impactReportScreen_earned_abd189(String arg1) {
    return '$arg1 earned';
  }

  @override
  String impactReportScreen_equivalent_cb7bb5(String arg1) {
    return '$arg1 equivalent';
  }

  @override
  String get impactReportScreen_laIlahaIllallahuWahdahu_895dde =>
      'La ilaha illallahu wahdahu la sharika lahu...';

  @override
  String impactReportScreen_setsOfSetsSlaves_b43b31(String arg1, String arg2) {
    return 'Sets of 10 → $arg1 sets × 4 slaves = $arg2';
  }

  @override
  String impactReportScreen_opened_1bf8da(String arg1) {
    return '$arg1 opened';
  }

  @override
  String impactReportScreen_received_a526e3(String arg1) {
    return '$arg1 received';
  }

  @override
  String impactReportScreen_totalSalawatSent_cfe45e(String arg1) {
    return 'Total salawat sent: $arg1\\n';
  }

  @override
  String impactReportScreen_multipliedByBlessingsReceived_52810f(String arg1) {
    return 'Multiplied by 10 → $arg1 blessings received';
  }

  @override
  String impactReportScreen_invocations_d80c33(String arg1) {
    return '$arg1 invocations';
  }

  @override
  String get impactReportScreen_protectionFromEvil_37b53a =>
      'Protection from evil';

  @override
  String get impactReportScreen_goodHealthProtection_058808 =>
      'Good health & protection';

  @override
  String impactReportScreen_totalInvocations_1fd02b(String arg1) {
    return 'Total invocations: $arg1';
  }

  @override
  String impactReportScreen_dividedByQuranCompletions_b9a013(String arg1) {
    return 'Divided by 3 → $arg1 Quran completions';
  }

  @override
  String impactReportScreen_recitations_3cb9ec(String arg1) {
    return '$arg1 recitations';
  }

  @override
  String impactReportScreen_564740_564740(String _monthActiveDays) {
    return '$_monthActiveDays';
  }

  @override
  String impactReportScreen_3dc421_3dc421(String arg1) {
    return '${arg1}h ';
  }

  @override
  String impactReportScreen_08990a_08990a(String arg1) {
    return '${arg1}m';
  }

  @override
  String impactReportScreen_ago_71107c(String arg1) {
    return '${arg1}m ago';
  }

  @override
  String impactReportScreen_moAgo_325a71(String arg1) {
    return '${arg1}mo ago';
  }

  @override
  String impactReportScreen_viewAllDonors_e72932(String arg1) {
    return 'View all $arg1 donors';
  }

  @override
  String impactReportScreen_failed_190558(String e) {
    return 'Failed: $e';
  }

  @override
  String impactReportScreen_meet_82797d(String arg1, String arg2) {
    return 'Meet $arg1, $arg2';
  }

  @override
  String impactReportScreen_sponsor_a47417(String arg1) {
    return 'Sponsor $arg1 →';
  }

  @override
  String impactReportScreen_funded_add009(String arg1) {
    return '$arg1% funded';
  }

  @override
  String get impactReportScreen_yourLifetimeImpact_8bfdcd =>
      'Your lifetime impact';

  @override
  String get impactReportScreen_startYourImpactJourney_1ae8c4 =>
      'Start your impact journey';

  @override
  String impactReportScreen_bd3721_bd3721(String _myOrphansSponsoredCount) {
    return '$_myOrphansSponsoredCount';
  }

  @override
  String impactReportScreen_b3d969_b3d969(String _myProjectsSupportedCount) {
    return '$_myProjectsSupportedCount';
  }

  @override
  String get levelScreen_customProfileThemes_cec15c => 'Custom profile themes';

  @override
  String get levelScreen_exclusiveVotingRights_684759 =>
      'Exclusive voting rights';

  @override
  String get levelScreen_hallOfFameListing_eb6ad1 => 'Hall of Fame listing';

  @override
  String levelScreen_seeds_fff97b(String arg1) {
    return '+$arg1 Seeds';
  }

  @override
  String get levelScreen_laIlahaIllallah_e8c26b => 'La ilaha illallah x100';

  @override
  String levelScreen_unlocks_6f2513(String arg1) {
    return 'Unlocks: $arg1';
  }

  @override
  String levelScreen_seedsBoost_464454(String arg1) {
    return '$arg1× Seeds Boost';
  }

  @override
  String levelScreen_cf765f_cf765f(
    String arg1,
    String arg2,
    String arg3,
    String arg4,
    String arg5,
  ) {
    return '$arg1:$arg2  $arg3/$arg4/$arg5';
  }

  @override
  String levelScreen_nextDays_212b86(String arg1, String arg2) {
    return 'Next: $arg1 ($arg2 days)';
  }

  @override
  String levelScreen_days_100e10(String current, String arg1) {
    return '$current / $arg1 days';
  }

  @override
  String levelScreen_dayStreak_df2abf(String arg1) {
    return '$arg1 day streak';
  }

  @override
  String get phase1Screens_quranReadingNimage_5ebac0 => 'Quran reading\\nimage';

  @override
  String get phase1Screens_orphansNimage_24d12a => 'Orphans\\nimage';

  @override
  String onboardingComponents_355c50_355c50(String first) {
    return '$first ';
  }

  @override
  String onboardingComponents_b236c9_b236c9(String trailing) {
    return ' $trailing';
  }

  @override
  String get quranMini_inTheNameOf_46925d =>
      'In the name of Allah, the Most Gracious, the Most Merciful.';

  @override
  String get quranMini_allPraiseBelongsTo_2d51df =>
      'All praise belongs to Allah, Lord of all the worlds.';

  @override
  String orphansGridScreen_36cd3b_36cd3b(String arg1, String arg2) {
    return '$arg1 · $arg2';
  }

  @override
  String orphanDetailScreen_years_debb46(String arg1) {
    return '$arg1 years';
  }

  @override
  String orphanDetailScreen_ofSeeds_2a29fc(String arg1, String arg2) {
    return '$arg1 of $arg2 Seeds';
  }

  @override
  String orphanDetailScreen_through_2cdb72(String arg1) {
    return 'Through $arg1';
  }

  @override
  String get orphanDetailScreen_andTheyGiveFood_7ddcff =>
      'And they give food, despite their love for it, to the needy, the orphan, and the captive.';

  @override
  String orphanDetailScreen_ago_71107c(String arg1) {
    return '${arg1}m ago';
  }

  @override
  String orphanDetailScreen_moAgo_325a71(String arg1) {
    return '${arg1}mo ago';
  }

  @override
  String orphanDetailScreen_seeds_30d8dc(String _availablePoints) {
    return '$_availablePoints Seeds';
  }

  @override
  String orphanDetailScreen_sponsor_b34bcf(String arg1) {
    return 'Sponsor $arg1';
  }

  @override
  String orphanDetailScreen_jazakallahKhayranSeedsSponsored_316bec(
    String amount,
  ) {
    return 'JazakAllah Khayran! $amount Seeds sponsored.';
  }

  @override
  String orphanDetailScreen_chooseHowManySeeds_b69aa2(String arg1) {
    return 'Choose how many Seeds to give. Minimum $arg1.';
  }

  @override
  String orphanDetailScreen_yourBalanceSeeds_f8045b(String arg1) {
    return 'Your balance: $arg1 Seeds';
  }

  @override
  String get profileSettingsScreen_nameCannotBeEmpty_c737ab =>
      'Name cannot be empty';

  @override
  String get profileSettingsScreen_bosniaAndHerzegovina_a428ef =>
      'Bosnia and Herzegovina';

  @override
  String get profileSettingsScreen_centralAfricanRepublic_0fde6c =>
      'Central African Republic';

  @override
  String get profileSettingsScreen_unitedArabEmirates_d8e2d8 =>
      'United Arab Emirates';

  @override
  String get profileSettingsScreen_signedInWithGoogle_17e053 =>
      'Signed in with Google';

  @override
  String get profileSettingsScreen_signedInWithQuran_2e1ffc =>
      'Signed in with Quran.com';

  @override
  String get profileSettingsScreen_signedInWithEmail_dd881f =>
      'Signed in with Email';

  @override
  String profileSettingsScreen_seeds_53d666(String arg1) {
    return '$arg1 Seeds';
  }

  @override
  String get profileSettingsScreen_guidesFAQsAndHow_b990d6 =>
      'Guides, FAQs and how-tos';

  @override
  String get profileSettingsScreen_somethingNotWorkingTell_07f659 =>
      'Something not working? Tell us';

  @override
  String projectDetailScreen_organisedBy_8b317a(String sponsor) {
    return 'Organised by $sponsor\\n\\n';
  }

  @override
  String get projectDetailScreen_fundedSoFarEvery_dab3fd =>
      'Funded so far, every Seed counts!\\n\\n';

  @override
  String get projectDetailScreen_openSabiqRewardsApp_cdda14 =>
      'Open Sabiq Rewards app to donate your Seeds and earn reward.\\n';

  @override
  String get projectDetailScreen_sabiqrewardsSadaqahIslamicCharity_663ba5 =>
      '#SabiqRewards #Sadaqah #IslamicCharity';

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
      'Donate to provide urgent, life-saving aid to Palestinians facing critical shortages of food, water, and medical supplies...';

  @override
  String projectDetailScreen_seeds_47387f(String arg1) {
    return '$arg1 Seeds';
  }

  @override
  String projectDetailScreen_e4e562_e4e562(String arg1) {
    return '$arg1%';
  }

  @override
  String projectDetailScreen_ago_71107c(String arg1) {
    return '${arg1}m ago';
  }

  @override
  String projectDetailScreen_moAgo_325a71(String arg1) {
    return '${arg1}mo ago';
  }

  @override
  String projectDetailScreen_viewAll_3d2c48(String arg1) {
    return 'View all $arg1 →';
  }

  @override
  String quranHubScreen_saved_9c28a3(String arg1) {
    return '$arg1 saved';
  }

  @override
  String get quranHubScreen_tapTheHeartBookmark_c62da1 =>
      'Tap the heart/bookmark icon while reading to save verses.';

  @override
  String quranHubScreen_surahVerse_2c65ec(String s, String a) {
    return 'Surah $s  •  Verse $a';
  }

  @override
  String quranHubScreen_verses_f97238(String arg1) {
    return '$arg1 verses';
  }

  @override
  String quranHubScreen_of_0420fc(String arg1) {
    return 'of $arg1';
  }

  @override
  String get quranScreen_englishSahihIntl_da5e9e => 'English, Sahih Intl.';

  @override
  String get quranScreen_saheehInternational_fd1d5c => 'Saheeh International';

  @override
  String get quranScreen_englishPickthall_a0d265 => 'English, Pickthall';

  @override
  String get quranScreen_mohammadMarmadukePickthall_554557 =>
      'Mohammad Marmaduke Pickthall';

  @override
  String get quranScreen_englishTheMessage_24a984 => 'English, The Message';

  @override
  String get quranScreen_englishMuhsinKhan_a5402b => 'English, Muhsin Khan';

  @override
  String get quranScreen_muhsinKhanHilali_471c43 => 'Muhsin Khan & Hilali';

  @override
  String get quranScreen_fatehMuhammadJalandhry_262387 =>
      'Fateh Muhammad Jalandhry';

  @override
  String get quranScreen_imamAhmadRazaKhan_225277 => 'Imam Ahmad Raza Khan';

  @override
  String get quranScreen_maulanaSayyidAbulAla_75d35f =>
      'Maulana Sayyid Abul Ala Maududi';

  @override
  String get quranScreen_franAisHamidullah_2ca2c2 => 'Français, Hamidullah';

  @override
  String get quranScreen_rkDiyanet_431130 => 'Türkçe, Diyanet';

  @override
  String get quranScreen_rkLeymanAte_7aa8e1 => 'Türkçe, Süleyman Ateş';

  @override
  String get quranScreen_bahasaIndonesian_2a26f0 => 'Bahasa, Indonesian';

  @override
  String get quranScreen_ministryOfReligiousAffairs_e30db8 =>
      'Ministry of Religious Affairs';

  @override
  String get quranScreen_muhiuddinKhan_df9bfe => 'বাংলা, Muhiuddin Khan';

  @override
  String get quranScreen_deutschAbuRida_9acffd => 'Deutsch, Abu Rida';

  @override
  String get quranScreen_abuRidaMuhammadIbn_3a40b3 =>
      'Abu Rida Muhammad ibn Ahmad';

  @override
  String get quranScreen_espaOlAsad_1c1933 => 'Español, Asad';

  @override
  String get quranScreen_uthmaniMadinah_e1f10e => 'Uthmani (Madinah)';

  @override
  String get quranScreen_alJalalaynEN_af0584 => 'Al-Jalalayn (EN)';

  @override
  String get quranScreen_couldNotLoadAyah_62f120 =>
      'Could not load ayah. Please retry.';

  @override
  String get quranScreen_noConnectionCachedData_e5a215 =>
      'No connection. Cached data may be available.';

  @override
  String quranScreen_ayahs_c98642(String arg1) {
    return '$arg1 ayahs';
  }

  @override
  String get quranScreen_couldNotRemoveBookmark_699a82 =>
      'Could not remove bookmark, please retry';

  @override
  String quranScreen_removedBookmark_d7a16a(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'Removed bookmark $_surahName $_surah:$_ayah';
  }

  @override
  String get quranScreen_couldNotSaveBookmark_976448 =>
      'Could not save bookmark, please retry';

  @override
  String quranScreen_bookmarked_2c6203(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'Bookmarked $_surahName $_surah:$_ayah';
  }

  @override
  String get quranScreen_trimmedContains_039f31 => ') && !trimmed.contains(';

  @override
  String quranScreen_tafsir_391c0d(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'Tafsir · $_surahName $_surah:$_ayah';
  }

  @override
  String get quranScreen_addedToFavourites_b3cce0 => '♥️ Added to Favourites';

  @override
  String get quranScreen_comfortableNightTimeReading_da3df2 =>
      'Comfortable night-time reading';

  @override
  String quranScreen_pt_9e58e8(String arg1) {
    return '$arg1 pt';
  }

  @override
  String quranScreen_003843_003843(String arg1, String arg2) {
    return '$arg1  $arg2';
  }

  @override
  String get quranScreen_displayMeaningBelowEach_a26f31 =>
      'Display meaning below each verse';

  @override
  String get quranScreen_showTransliteration_e04abd => 'Show Transliteration';

  @override
  String get quranScreen_romanisedPronunciationUnderEach_2c0136 =>
      'Romanised pronunciation under each word';

  @override
  String get quranScreen_progressBarAyahCount_3cd24d =>
      'Progress bar & ayah count card';

  @override
  String get quranScreen_moveToNextVerse_ea29fd =>
      'Move to next verse when audio ends';

  @override
  String get quranScreen_repeatCurrentVerse_552669 => 'Repeat Current Verse';

  @override
  String get quranScreen_notificationsALERTS_fbea75 => 'NOTIFICATIONS & ALERTS';

  @override
  String get quranScreen_milestoneSoundAlerts_03cdc3 =>
      'Milestone Sound Alerts';

  @override
  String get quranScreen_chimeWhenYouReach_dd60c0 =>
      'Chime when you reach 10, 25, 50 ayahs';

  @override
  String get quranScreen_showEachArabicWord_64532d =>
      'Show each Arabic word with its English meaning';

  @override
  String get quranScreen_translationLanguage_d8c9b3 => 'Translation Language';

  @override
  String quranScreen_translationsAvailable_55c648(String arg1) {
    return '$arg1 translations available';
  }

  @override
  String quranScreen_3502e8_3502e8(String arg1, String arg2) {
    return '$arg1 / $arg2';
  }

  @override
  String quranScreen_sabiqSeedsEarnedToday_13ddb3(String _pointsToday) {
    return '+$_pointsToday Sabiq Seeds earned today!';
  }

  @override
  String quranScreen_dcacc4_dcacc4(String _ayah, String arg1) {
    return '$_ayah / $arg1';
  }

  @override
  String quranScreen_6d1f9d_6d1f9d(String arg1) {
    return '$arg1 ';
  }

  @override
  String quranScreen_ayahsRead_862866(String _ayahsToday) {
    return '$_ayahsToday ayahs read';
  }

  @override
  String quranScreen_ce2af3_ce2af3(String arg1) {
    return '$arg1%';
  }

  @override
  String quranScreen_6e8ac8_6e8ac8(String text) {
    return '$text ';
  }

  @override
  String quranScreen_pageJuz_6ac28a(String _currentPage, String arg1) {
    return 'Page $_currentPage  ·  Juz $arg1';
  }

  @override
  String get startJourneyScreen_unexpectedErrorDuringGoogle_86c1a5 =>
      'Unexpected error during Google Sign In';

  @override
  String get startJourneyScreen_connectedToQuranCom_c0c631 =>
      'Connected to Quran.com';

  @override
  String streakScreen_nextDays_212b86(String arg1, String arg2) {
    return 'Next: $arg1 ($arg2 days)';
  }

  @override
  String streakScreen_seeds_990893(String arg1) {
    return '+$arg1 Seeds';
  }

  @override
  String streakScreen_days_100e10(String current, String arg1) {
    return '$current / $arg1 days';
  }

  @override
  String streakScreen_dayStreak_df2abf(String arg1) {
    return '$arg1 day streak';
  }

  @override
  String get tafsirHubScreen_earnSeedsForEvery_ffb3d5 =>
      'Earn Seeds for every 10 min of Tafsir listening';

  @override
  String get tafsirScreen_alJalalaynEN_af0584 => 'Al-Jalalayn (EN)';

  @override
  String tafsirScreen_verses_fed624(String arg1) {
    return '$arg1 verses';
  }

  @override
  String get tafsirScreen_trimmedContains_039f31 => ') && !trimmed.contains(';

  @override
  String tafsirScreen_ayahOf_63c42b(String _ayah, String _surahLen) {
    return 'Ayah $_ayah of $_surahLen';
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
      'Tafsir not available for this ayah.';

  @override
  String get donationService_youMustBeLogged_6813cf =>
      'You must be logged in to donate.';

  @override
  String get donationService_donationCouldNotBe_074195 =>
      'Donation could not be processed at this time.';

  @override
  String get donationService_anUnexpectedNetworkError_914b7a =>
      'An unexpected network error occurred.';

  @override
  String get donationService_sponsorshipReceived_671201 =>
      'Sponsorship received 💝';

  @override
  String donationService_youSponsoredSeedsJazak_7711e1(String amount) {
    return 'You sponsored $amount Seeds · jazak Allah khair.';
  }

  @override
  String get donationService_sponsorshipCouldNotBe_55003e =>
      'Sponsorship could not be processed at this time.';

  @override
  String get liveNotificationService_remindersToSealYour_782a67 =>
      'Reminders to seal your pending Seeds before midnight.';

  @override
  String get liveNotificationService_sealYourSeedsBefore_62a726 =>
      'Seal your Seeds before midnight';

  @override
  String liveNotificationService_youHavePendingSeeds_dd762f(
    String pendingSeeds,
  ) {
    return 'You have $pendingSeeds pending Seeds. Tap Seal the Day before midnight or they expire.';
  }

  @override
  String liveNotificationService_ayatReadToday_b5a4e8(String _ayahCount) {
    return '$_ayahCount Ayat Read today 📖';
  }

  @override
  String liveNotificationService_readQuranToday_703122(String arg1) {
    return '$arg1 Read Quran today ⏱️';
  }

  @override
  String get liveNotificationService_nothingReadFromQuran_b1c2eb =>
      'Nothing Read from Quran today 📖';

  @override
  String liveNotificationService_dhikrCompletedToday_835583(
    String _dhikrCount,
  ) {
    return '$_dhikrCount Dhikr completed today 📿';
  }

  @override
  String liveNotificationService_ayatDhikrToday_548e91(
    String _ayahCount,
    String _dhikrCount,
  ) {
    return '$_ayahCount ayat · $_dhikrCount dhikr today';
  }

  @override
  String get liveNotificationService_keepReadingAndDoing_cdc7b2 =>
      'Keep reading and doing Dhikr!';

  @override
  String get liveNotificationService_yourSeedsToday_8649c6 =>
      'Your Seeds Today ✨';

  @override
  String get localReminderScheduler_sabiqRewardsNotifications_96d36c =>
      'Sabiq Rewards Notifications';

  @override
  String get localReminderScheduler_it_0c8340 => 'It\\';

  @override
  String get localReminderScheduler_fridayReadSurahAl_077436 =>
      's Friday — read Surah Al-Kahf';

  @override
  String get localReminderScheduler_whoeverRecitesSurahAl_15b9a5 =>
      'Whoever recites Surah Al-Kahf on Friday, light shines for them between the two Fridays.';

  @override
  String get localReminderScheduler_don_b4d354 => 'Don\\';

  @override
  String get localReminderScheduler_missSurahAlKahf_634857 =>
      't miss Surah Al-Kahf today';

  @override
  String get localReminderScheduler_fewHoursToMaghrib_d99fd2 =>
      'A few hours to Maghrib — finish Surah Al-Kahf if you haven\\';

  @override
  String get quranApiService_notConnectedToQuran_9f4f89 =>
      'Not connected to Quran.com';

  @override
  String quranApiService_syncFailedBookmarkCould_3393f7(String failed) {
    return 'Sync failed, $failed bookmark(s) could not be pushed to Quran.com (check token / endpoint).';
  }

  @override
  String get quranApiService_bookmarksAlreadyInSync_fad9e1 =>
      'Bookmarks already in sync';

  @override
  String quranApiService_syncedBookmarksUpDown_dd2f96(
    String total,
    String uploaded,
    String downloaded,
  ) {
    return 'Synced $total bookmarks ($uploaded up, $downloaded down)';
  }

  @override
  String quranApiService_syncFailed_ae7629(String e) {
    return 'Sync failed: $e';
  }

  @override
  String get streakService_warmingUp_b1687b => 'Warming Up';

  @override
  String get streakService_oneWeek_4f98dc => 'One Week';

  @override
  String get streakService_twoWeeks_9a2d93 => 'Two Weeks';

  @override
  String get streakService_oneMonth_35eb01 => 'One Month';

  @override
  String get streakService_twoMonths_84d275 => 'Two Months';

  @override
  String get streakService_theCenturion_f1de7f => 'The Centurion';

  @override
  String streakService_1fc043_1fc043(String arg1, String arg2) {
    return '$arg1 $arg2';
  }

  @override
  String streakService_dayStreak_9ee8a3(String arg1, String arg2) {
    return '$arg1-day $arg2 streak · ';
  }

  @override
  String streakService_bonusSeedsUnlocked_bcdda5(String arg1) {
    return '+$arg1 bonus Seeds unlocked';
  }

  @override
  String trackingService_c7528c_c7528c(String arg1, String arg2) {
    return '$arg1 $arg2';
  }

  @override
  String xpService_level_226f81(String title, String level) {
    return '$title • Level $level';
  }

  @override
  String get xpService_newBadgeUnlocked_2c8d0e => 'New badge unlocked 🏆';

  @override
  String get xpService_you_79d09a => 'You\\';

  @override
  String get xpService_dailyLoginBonus_d011fa => 'Daily login bonus';

  @override
  String xpService_seedsWelcomeBack_47888a(String arg1) {
    return '+$arg1 Seeds · welcome back!';
  }

  @override
  String get xpService_daySealed_037a56 => 'Day sealed 🌙';

  @override
  String xpService_sabiqSeedsConfirmedBonus_702902(
    String flushed,
    String bonus,
  ) {
    return '+$flushed Sabiq Seeds confirmed! ($bonus bonus for sealing)';
  }

  @override
  String xpService_sabiqSeedsConfirmed_34969c(String flushed) {
    return '+$flushed Sabiq Seeds confirmed!';
  }

  @override
  String get dhikrExitCelebration_everyBreathCounts_45b3df =>
      'Every breath counts.';

  @override
  String get impactAnimation_yourRewardHasBeen_e3d106 =>
      'Your reward has been recorded.';

  @override
  String get motivationalPopup_verilyWithHardshipComes_f23637 =>
      'Verily, with hardship comes ease.\\nEvery trial is a door to something greater.';

  @override
  String get motivationalPopup_quranAlInshirah_d81f8a =>
      'Quran • Al-Inshirah 94:6';

  @override
  String get motivationalPopup_quranAlAnkabut_8e938e =>
      'Quran • Al-Ankabut 29:45';

  @override
  String get motivationalPopup_quranAlBaqarah_8bb10e =>
      'Quran • Al-Baqarah 2:152';

  @override
  String get motivationalPopup_quranAnNahl_74d608 => 'Quran • An-Nahl 16:18';

  @override
  String get motivationalPopup_makeYourTimePrecious_049aae =>
      'Make your time precious.\\nShare goodness with a friend today ,\\nevery good deed shared is a sadaqah.';

  @override
  String get motivationalPopup_guideOthersToGood_6105c4 =>
      'Guide others to good, and you get its reward.';

  @override
  String get motivationalPopup_theBestOfPeople_1f6906 =>
      'The best of people are those most beneficial to others.';

  @override
  String get motivationalPopup_verilyInTheRemembrance_16476d =>
      'Verily, in the remembrance of Allah\\ndo hearts find rest.';

  @override
  String get motivationalPopup_remindYourselfTimeIs_38ae33 =>
      'Remind yourself, time is the most precious sadaqah.';

  @override
  String get motivationalPopup_yourTimeIsYour_be6731 =>
      'Your time is your most\\nprecious asset. Invest it wisely\\nin what endures forever.';

  @override
  String get motivationalPopup_quranAlAnfal_b10486 => 'Quran • Al-Anfal 8:28';

  @override
  String get motivationalPopup_takeAdvantageOfFive_e573fd =>
      'Take advantage of five before five.';

  @override
  String get motivationalPopup_youHaveBeenRewarded_9bde33 =>
      'You have been rewarded for\\nyour consistency today!';

  @override
  String motivationalPopup_seeds_3a9c69(String arg1) {
    return '+$arg1 Seeds';
  }

  @override
  String get motivationalPopup_completeNowEarnSeeds_16ea6e =>
      'Complete now → earn +50 Seeds bonus';

  @override
  String get motivationalPopup_finishYourAzkaarEarn_e264fa =>
      'Finish your Azkaar → earn +30 Seeds bonus';

  @override
  String get motivationalPopup_shareSabiqWithSomeone_c60dcc =>
      'Share Sabiq with someone → earn +100 Seeds';

  @override
  String get motivationalPopup_keepYourSpiritualMomentum_0f172c =>
      'Keep your spiritual momentum going\\nand watch your Seeds grow ✨';

  @override
  String get noorOffline_somethingWentWrong_76fc46 => 'Something went wrong';

  @override
  String get notificationsSheet_stayOnTopOf_811366 =>
      'Stay on top of rewards & milestones';

  @override
  String get notificationsSheet_llBeNotifiedAbout_9e7a1b =>
      'll be notified about rewards, streaks & milestones.';

  @override
  String get notificationsSheet_inboxKeepsExistingItems_611668 =>
      'Inbox keeps existing items but no new ones will arrive.';

  @override
  String get notificationsSheet_sabiqSeedsForSealing_001312 =>
      'Sabiq Seeds for sealing today';

  @override
  String get projectMediaCarousel_couldNotLoadVideo_deb8dd =>
      'Could not load video';

  @override
  String get quranExitCelebration_beautifulRecitation_9d2655 =>
      'Beautiful recitation.';

  @override
  String get quranExitCelebration_everyMomentCounts_fddb4c =>
      'Every moment counts.';

  @override
  String sealCoinAnimation_e16fa4_e16fa4(String arg1) {
    return '+$arg1 ';
  }

  @override
  String impactReportScreen_totalHasanatFromQuran(String n) {
    return 'Total hasanat from Quran: $n';
  }

  @override
  String impactReportScreen_totalTreesPlanted(String n) {
    return 'Total trees planted: $n';
  }

  @override
  String impactReportScreen_totalTreasures(String n) {
    return 'Total treasures: $n';
  }

  @override
  String impactReportScreen_multipliedByGates(String n) {
    return 'Multiplied by 8 gates → $n openings';
  }

  @override
  String impactReportScreen_bonusHasanaat(String n) {
    return 'Bonus hasanaat: $n';
  }

  @override
  String impactReportScreen_totalDonatedSeeds(String n, String seeds) {
    return 'Total donated: $n $seeds';
  }

  @override
  String get dashboardScreen_dashboardLoadFailed =>
      'Couldn\'t load your dashboard. Please try again.';

  @override
  String get zikrLabel => 'Zikr';

  @override
  String get quranLabel => 'Quran';

  @override
  String streakService_dayStreakBody(String days, String type, String bonus) {
    return '$days-day $type streak · +$bonus bonus Seeds unlocked';
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
    return '$arg1-day $arg2 streak · ';
  }

  @override
  String get donationService_donationReceivedTitle => 'Donation received 💝';

  @override
  String donationService_youDonatedSeeds(String amount) {
    return 'You donated $amount Seeds · jazak Allah khair.';
  }

  @override
  String streakService_60a570_60a570(Object arg1, Object localLabel) {
    return '$arg1 $localLabel';
  }

  @override
  String xpService_badgeEarnedBody(String name) {
    return 'You\'ve earned the \"$name\" badge.';
  }

  @override
  String get localReminderScheduler_channelName =>
      'Sabiq Rewards Notifications';

  @override
  String get localReminderScheduler_morningTitle => 'Morning Azkar';

  @override
  String get localReminderScheduler_morningBody =>
      'Start your day under Allah\'s protection — recite the morning adhkar.';

  @override
  String get localReminderScheduler_astaghfirTitle => 'A moment for istighfar';

  @override
  String get localReminderScheduler_astaghfirBody =>
      '\"Astaghfirullah\" polishes the heart and opens doors of provision. Pause for one minute.';

  @override
  String get localReminderScheduler_eveningTitle => 'Evening Azkar';

  @override
  String get localReminderScheduler_eveningBody =>
      'Protect yourself for the night — recite the evening adhkar.';

  @override
  String get localReminderScheduler_sleepTitle => 'Time to wind down';

  @override
  String get localReminderScheduler_sleepBody =>
      'End the day with sleep adhkar — Ayatul Kursi, the 3 Quls, and the bedtime du\'as.';

  @override
  String get localReminderScheduler_kahfAmTitle =>
      'It\'s Friday — read Surah Al-Kahf';

  @override
  String get localReminderScheduler_kahfBody =>
      'Whoever recites Surah Al-Kahf on Friday, light shines for them between the two Fridays.';

  @override
  String get localReminderScheduler_salawatTitle => 'Salawat on Friday';

  @override
  String get localReminderScheduler_salawatBody =>
      'Recite salawat upon the Prophet ﷺ generously today — the deeds of Friday are shown to him.';

  @override
  String get localReminderScheduler_kahfPmTitle =>
      'Don\'t miss Surah Al-Kahf today';

  @override
  String get localReminderScheduler_kahfPmBody =>
      'A few hours to Maghrib — finish Surah Al-Kahf if you haven\'t yet.';

  @override
  String get liveNotificationService_validateChannelDesc =>
      'Reminders to seal your pending Seeds before midnight.';

  @override
  String get liveNotificationService_validateTicker =>
      'Seal your Seeds before midnight';

  @override
  String get liveNotificationService_validateTitle =>
      'Seal your Seeds before midnight!';

  @override
  String liveNotificationService_validateBody(String n) {
    return 'You have $n pending Seeds. Tap Seal the Day before midnight or they expire.';
  }

  @override
  String liveNotificationService_ayatRead(String n) {
    return '$n Ayat Read today 📖';
  }

  @override
  String liveNotificationService_readQuranTime(String time) {
    return '$time Read Quran today ⏱️';
  }

  @override
  String get liveNotificationService_nothingRead =>
      'Nothing Read from Quran today 📖';

  @override
  String liveNotificationService_dhikrCompleted(String n) {
    return '$n Dhikr completed today 📿';
  }

  @override
  String liveNotificationService_tickerBusy(String ayah, String dhikr) {
    return '$ayah ayat · $dhikr dhikr today';
  }

  @override
  String get liveNotificationService_tickerIdle =>
      'Keep reading and doing Dhikr!';

  @override
  String get liveNotificationService_channelDesc =>
      'Live today\'s Quran and Dhikr progress';

  @override
  String get liveNotificationService_seedsToday => 'Your Seeds Today ✨';

  @override
  String get liveNotificationService_summary => 'Tap to open Sabiq';
}
