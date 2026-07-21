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
  String get youHaveDone => 'لقد أنجزت!';

  @override
  String get playAllBtn => 'تشغيل الكل';

  @override
  String get playBtn => 'تشغيل';

  @override
  String get readBtn => 'اقرأ';

  @override
  String get readOnce => 'اقرأ مرة واحدة';

  @override
  String readNTimes(int count) {
    return 'اقرأ $count مرات';
  }

  @override
  String seedsEarnedToday(int count) {
    return '+$count سابق سيدز كسبتها اليوم!';
  }

  @override
  String get catDailyRemembrance => 'الذكر اليومي';

  @override
  String get catNightlyRemembrance => 'الذكر الليلي';

  @override
  String get catYourSelection => 'اختيارك';

  @override
  String get catContinuousRemembrance => 'الذكر المستمر';

  @override
  String get bannerDailyRemembrance => 'الذكر اليومي\nيجلب السكينة للروح.';

  @override
  String get bannerMorningAdhkar =>
      'أذكار الصباح\nتجلب السكينة للروح والنور لطريقك.';

  @override
  String get bannerEveningAdhkar =>
      'أذكار المساء\nتجلب الطمأنينة والحفظ ليلتك.';

  @override
  String get bannerYourSelection =>
      'كلمات الذكر الأحب إليك\nلتبقيها قريبة من قلبك.';

  @override
  String get bannerContinuousRemembrance => 'اذكروا الله\nكثيراً لعلكم تفلحون.';

  @override
  String get frequentlyReadByCommunity => 'تُقرأ بكثرة';

  @override
  String get viewFullLeaderboard => 'عرض لوحة الصدارة كاملة';

  @override
  String get skip => 'تخطي';

  @override
  String get continue_ => 'متابعة';

  @override
  String get beginYourJourney => 'ابدأ رحلتك';

  @override
  String get enterTheGarden => 'ادخل البستان';

  @override
  String get bySigningUp => 'بتسجيلك، توافق على الشروط والخصوصية';

  @override
  String get lightOfMercy => 'نور الرحمة';

  @override
  String get noorRewards => 'Sabiq Rewards';

  @override
  String get startYourJourney => 'ابدأ رحلتك';

  @override
  String get trackSpiritualGrowth =>
      'تتبع نموك الروحي، وانضم للمجتمع، وافتح مكافآت حصرية لكل عمل صالح.';

  @override
  String get continueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get continueWithQuran => 'المتابعة باستخدام Quran.com';

  @override
  String get onboarding1Title => 'السلام\nعليكم';

  @override
  String get onboarding1Subtitle =>
      'مرحباً بك في Sabiq Rewards، حيث كل عمل صالح يقربك إلى رحمة الله ونوره.';

  @override
  String get onboarding2Title => 'أجران.\nلعمل واحد.';

  @override
  String get onboarding2Subtitle =>
      'كل كلمة تقرأها تكسبك ثواباً ونوراً في آخرتك.\nالـ سابق سيدز الخاصة بك تمول مشاريع تُغيّر حياة حقيقية.';

  @override
  String get onboarding3Title => 'اذكر\nالله دائماً';

  @override
  String get onboarding3Subtitle =>
      'القلب الذي يذكر الله يجد السلام مع كل نفس. تتبع أذكارك اليومية واجعل لكل تسبيحة أثراً.';

  @override
  String get onboarding4Title => 'تأمل و\nتزود يومياً';

  @override
  String get onboarding4Subtitle =>
      'القرآن هدى للناس. اكتشف آيات، وأدعية، وتأملات يومية تناسب رحلتك.';

  @override
  String get onboarding5Title => 'أعطِ و\nاكتسب الحسنات';

  @override
  String get onboarding5Subtitle =>
      'الصدقة تطفئ الخطيئة كما يطفئ الماء النار. اكسب الأجر مع كل عمل خيري وإحسان.';

  @override
  String welcomeUser(String name) {
    return 'مرحباً، $name 🌙';
  }

  @override
  String get gatesOfNoor => 'أبواب النور مفتوحة.\nرحلتك الروحية تبدأ اليوم.';

  @override
  String get earnNoorPoints => 'اكسب سابق سيدز';

  @override
  String get yourProgress => 'تقدمك';

  @override
  String get yourTotalNoorPoints => 'إجمالي سابق سيدز';

  @override
  String get achievements => 'الإنجازات';

  @override
  String get today => 'اليوم';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get streaks => 'الاستمرارية';

  @override
  String get noorPoints => 'سابق سيدز';

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
  String get yourReferralCode => 'كود الدعوة الخاص بك';

  @override
  String get copyLink => 'نسخ الرابط';

  @override
  String get shareVia => 'مشاركة عبر';

  @override
  String get friendGets => 'يحصل الصديق على';

  @override
  String get youGet => 'أنت تحصل على';

  @override
  String get goal => 'الهدف';

  @override
  String get needed => 'المطلوب';

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
  String get loading => 'جاري التحميل...';

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
  String get callYou => 'بماذا نناديك؟';

  @override
  String get personaliseJourney => 'أضف طابعاً شخصياً لرحلتك بكتابة اسمك';

  @override
  String get whereFrom => 'من أين\nأنت؟';

  @override
  String get joinMuslims => 'انضم للمسلمين من جميع أنحاء العالم في هذه الرحلة';

  @override
  String get whatBringsYou => 'ما الذي\nأتى بك إلى هنا؟';

  @override
  String get chooseGoals => 'اختر أهدافك الروحية، يمكنك اختيار أكثر من واحد';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navJourney => 'الرحلة';

  @override
  String get navAkhirah => 'الآخرة';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get communityLeaderboard => 'لوحة الصدارة للمجتمع';

  @override
  String get topContributors => 'أفضل المساهمين بـ سيدز طوال الوقت';

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get startStreak => 'ابدأ استمراريتك اليوم!';

  @override
  String get alreadySealed => 'مكتمل لليوم';

  @override
  String get sealTheDay => 'احفظ اليوم';

  @override
  String get alhamdulillah => 'الحمد لله!';

  @override
  String get levelSeeker => 'باحث';

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
  String get resumeReading => 'مواصلة القراءة';

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
  String get listen => 'استماع';

  @override
  String get tafsir => 'تفسير';

  @override
  String get wordByWord => 'كلمة بكلمة';

  @override
  String get mushaf => 'المصحف';

  @override
  String get otherCategories => 'فئات أخرى';

  @override
  String get noCategoriesAvailable => 'لا توجد فئات متاحة';

  @override
  String get nextPts => 'التالي';

  @override
  String get prev => 'السابق';

  @override
  String get reciteMore => 'اقرأ المزيد.';

  @override
  String get helpRealLives => 'ساعد حيوات حقيقية.';

  @override
  String get yourNoorPointsFundProjects =>
      'الـ سابق سيدز الخاصة بك تمول هذه المشاريع';

  @override
  String get youBothEarnPoints => 'كلاكما يربح 500 سابق سيدز!';

  @override
  String get reward => 'المكافأة';

  @override
  String get haveInviteCode => 'هل لديك كود دعوة؟';

  @override
  String get enterCode => 'أدخل الكود...';

  @override
  String get apply => 'تطبيق';

  @override
  String get plantGoodDeeds => 'ازرع الأعمال الصالحة';

  @override
  String get youDonated => 'لقد تبرعت';

  @override
  String get seeDetailsForMore => 'شاهد التفاصيل للمزيد من المشاريع ←';

  @override
  String get pts => 'سيدز';

  @override
  String get funded => 'مُمول';

  @override
  String bySponsor(String sponsor) {
    return 'بواسطة $sponsor';
  }

  @override
  String get viewCampaignDonate => 'عرض الحملة والتبرع';

  @override
  String get supportThisCause => 'ادعم هذه الحملة';

  @override
  String get availableBalance => 'الرصيد المتاح:';

  @override
  String get donationAmount => 'مبلغ التبرع';

  @override
  String get points => 'سيدز';

  @override
  String get donateEarnReward => 'تبرع واكسب الأجر';

  @override
  String get max => 'الحد الأقصى';

  @override
  String get leaderboard => 'لوحة الصدارة';

  @override
  String get loadingDots => 'جاري التحميل...';

  @override
  String yourRank(String rank) {
    return 'رتبتك: #$rank';
  }

  @override
  String get outOf => 'من أصل';

  @override
  String get believers => 'المؤمنون';

  @override
  String get topTenContributors => 'أفضل 10 مساهمين';

  @override
  String get ourCauses => 'مشاريعنا';

  @override
  String get donatePointsToSupport =>
      'تبرع بـ سابق سيدز لدعم مشاريع في العالم الحقيقي';

  @override
  String get noActiveProjects => 'لا توجد مشاريع نشطة حالياً';

  @override
  String get checkBackSoon => 'عُد قريباً إن شاء الله';

  @override
  String get messageCopied => 'تم نسخ الرسالة، شاركها أو ألصقها في واتساب!';

  @override
  String get lvl => 'مستوى';

  @override
  String get journey => 'الرحلة';

  @override
  String get tabStreaks => 'الاستمرارية';

  @override
  String get tabProgress => 'التقدم';

  @override
  String get tabBadges => 'الشارات';

  @override
  String get tabChallenges => 'التحديات';

  @override
  String get allTime => 'كل الوقت';

  @override
  String ptsToLevel(String pts, String level) {
    return '$pts سيدز للوصول للمستوى $level';
  }

  @override
  String dayStreak(String count) {
    return 'استمرارية $count أيام';
  }

  @override
  String get actions => 'أعمال';

  @override
  String get action => 'عمل';

  @override
  String get breakdown => 'التفاصيل';

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
  String get startEarningPts => 'ابدأ بكسب الـ سيدز، اقرأ القرآن، واذكر الله.';

  @override
  String get howToEarnPts => 'كيف تكسب سيدز';

  @override
  String get readOneAyah => 'اقرأ آية واحدة';

  @override
  String get completeOneJuz => 'أكمل جزءاً واحداً';

  @override
  String get validateAndSupport => 'احفظ وادعم';

  @override
  String get levelTiers => 'درجات المستويات';

  @override
  String get basicFeatures => 'الميزات الأساسية';

  @override
  String get customProfileThemes => 'سمات ملف شخصي مخصصة';

  @override
  String get leaderboardBadge => 'شارة لوحة الصدارة';

  @override
  String get exclusiveVotingRights => 'حقوق تصويت حصرية';

  @override
  String get hallOfFameListing => 'قائمة لوحة الشرف';

  @override
  String unlocks(String feature) {
    return 'يفتح: $feature';
  }

  @override
  String get now => 'الآن';

  @override
  String get trophyVault => 'خزينة الجوائز';

  @override
  String badgesCollected(String earned, String total) {
    return 'جُمعت $earned / $total شارة';
  }

  @override
  String percentComplete(String pct) {
    return 'اكتمل $pct%';
  }

  @override
  String toUnlock(String count) {
    return 'متبقي $count للفتح';
  }

  @override
  String get earned => 'المكتسبة';

  @override
  String get locked => 'مُقفل';

  @override
  String get seasonalEvents => 'الفعاليات الموسمية';

  @override
  String get weeklyChallenges => 'تحديات أسبوعية';

  @override
  String get specialEvents => 'فعاليات خاصة';

  @override
  String get noActiveChallenges => 'لا توجد تحديات نشطة حالياً';

  @override
  String get checkBackChallenges =>
      'عُد قريباً، فعاليات رمضان وذي الحجة قادمة!';

  @override
  String get ramadanChallenge => 'تحدي رمضان';

  @override
  String get ramadanChallengeDesc =>
      'مضاعفة الـ سيدز ×3 • شارات خاصة • هدف آبار المجتمع';

  @override
  String get comingSoonStayConsistent => 'قريباً، حافظ على استمراريتك!';

  @override
  String get done => 'تم!';

  @override
  String ptsBoost(String multiplier) {
    return 'مضاعفة سيدز ×$multiplier';
  }

  @override
  String ends(String date) {
    return 'ينتهي في $date';
  }

  @override
  String get loadingStreaks => 'جاري تحميل الاستمرارية...';

  @override
  String get centurion => 'المئوية، ما شاء الله!';

  @override
  String get currentBestStreak => 'أفضل سلسلة استمرارية حالية';

  @override
  String get last7Days => 'آخر 7 أيام';

  @override
  String get nextMilestone => 'الإنجاز القادم';

  @override
  String get allMilestones => 'كل الإنجازات';

  @override
  String moreDaysToGo(String count) {
    return 'بقي $count أيام، استمر!';
  }

  @override
  String dayStreakLabel(String count) {
    return 'استمرارية $count أيام';
  }

  @override
  String best(String count) {
    return 'أفضل $count';
  }

  @override
  String get dhikarAndDua => 'الذكر والدعاء';

  @override
  String get listenTafsir => 'استماع للتفسير';

  @override
  String get challenge => 'تحدي';

  @override
  String get readListenTafsir => 'اقرأ واستمع للتفسير';

  @override
  String get deepUnderstanding => 'فهم عميق للقرآن الكريم';

  @override
  String get earnPointsTafsir => 'اكسب سيدز لكل 10 دقائق من استماع التفسير';

  @override
  String get featuredSurahs => 'سور مميزة';

  @override
  String get browseAll114 => 'تصفح 114 سورة';

  @override
  String verses(String count) {
    return '$count آيات';
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
  String get loadingTafsir => 'جاري تحميل التفسير...';

  @override
  String get tafsirNotAvailable => 'التفسير غير متوفر لهذه الآية.';

  @override
  String get arabicScripture => 'النص العربي';

  @override
  String get urduScripture => 'النص الأردي';

  @override
  String get englishCommentary => 'التفسير بالإنجليزية';

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
  String get audioUnavailable => 'الصوت غير متوفر، تحقق من الاتصال بالإنترنت.';

  @override
  String get signInToSaveFavourites => 'سجل الدخول لحفظ المفضلة';

  @override
  String get addedToFavourites => 'أُضيف إلى المفضلة';

  @override
  String get removedFromFavourites => 'أُزيل من المفضلة';

  @override
  String get appearance => 'المظهر';

  @override
  String get appearanceLabel => 'المظهر';

  @override
  String get freezeIllustration => 'تجميد الرسمة';

  @override
  String get comfortableNightReading => 'قراءة ليلية مريحة';

  @override
  String get focusMode => 'وضع التركيز (ملء الشاشة)';

  @override
  String get focusModeDesc =>
      'إخفاء الشريط العلوي والتنقل لقراءة خالية من التشتت';

  @override
  String get textSize => 'حجم النص';

  @override
  String get small => 'صغير';

  @override
  String get large => 'كبير';

  @override
  String get themeColour => 'لون السمة';

  @override
  String get quranScript => 'رسم المصحف';

  @override
  String get quranScriptLabel => 'رسم المصحف';

  @override
  String get readingLayout => 'تخطيط القراءة';

  @override
  String get showTranslation => 'إظهار الترجمة';

  @override
  String get displayMeaningBelow => 'عرض المعنى أسفل كل آية';

  @override
  String get showDailyProgress => 'إظهار التقدم اليومي';

  @override
  String get progressBarAyahCount => 'شريط التقدم وعداد الآيات';

  @override
  String get showPointsBanner => 'إظهار لافتة الـ سيدز';

  @override
  String get noorPointsNotificationStrip => 'شريط إشعارات +سابق سيدز';

  @override
  String get showSurahHeader => 'إظهار ترويسة السورة';

  @override
  String get surahNameBanner => 'لافتة اسم السورة أعلى الصفحة';

  @override
  String get audioPlayback => 'الصوت والتشغيل';

  @override
  String get autoAdvance => 'انتقال تلقائي';

  @override
  String get moveToNextVerse => 'الانتقال للآية التالية عند انتهاء الصوت';

  @override
  String get repeatCurrentVerse => 'تكرار الآية الحالية';

  @override
  String get loopAyahAudio => 'تكرار صوت هذه الآية';

  @override
  String get notificationsAlerts => 'الإشعارات والتنبيهات';

  @override
  String get dailyReadingReminder => 'تذكير القراءة اليومية';

  @override
  String get pushReminderReadQuran => 'إرسال إشعار تذكير بقراءة القرآن يومياً';

  @override
  String get milestoneSoundAlerts => 'تنبيهات صوتية للإنجازات';

  @override
  String get chimeAtMilestones => 'أصدر صوتاً عند الوصول إلى 10، 25، 50 آية';

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
    return '$count ترجمات متاحة';
  }

  @override
  String get reciterLabel => 'القارئ:';

  @override
  String get playing => 'جاري التشغيل';

  @override
  String get favourite => 'مفضل';

  @override
  String get bookmark => 'إشارة مرجعية';

  @override
  String ayahsRead(String count) {
    return 'قُرأت $count آية';
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
  String get splitView => 'عرض منقسم';

  @override
  String get script => 'الرسم';

  @override
  String get actionsLabel => 'الأعمال';

  @override
  String get pageBookmarked => 'تم حفظ الصفحة!';

  @override
  String get loadingQuran => 'جاري تحميل القرآن...';

  @override
  String get earnPointsPerVerse => 'اكسب +10 سابق سيدز لكل آية تقرؤها';

  @override
  String get chooseSurah => 'اختر السورة';

  @override
  String get chooseVerse => 'اختر الآية';

  @override
  String surahHasVerses(String surah, String count) {
    return '$surah بها $count آيات';
  }

  @override
  String get favourites => 'المفضلة';

  @override
  String get bookmarks => 'الإشارات المرجعية';

  @override
  String saved(String count) {
    return 'تم حفظ $count';
  }

  @override
  String noSavedYet(String title) {
    return 'لم يتم حفظ $title بعد';
  }

  @override
  String get tapToSaveVerses =>
      'انقر على أيقونة القلب/الإشارة أثناء القراءة لحفظ الآيات.';

  @override
  String get randomVerse => 'آية عشوائية';

  @override
  String get sunnahFriday => 'سنن الجمعة';

  @override
  String get resume => 'متابعة';

  @override
  String get loadingWordTranslations => 'جاري تحميل ترجمة الكلمات...';

  @override
  String get wordDataUnavailable =>
      'بيانات الكلمات غير متوفرة. تحقق من الاتصال بالإنترنت.';

  @override
  String get duaAzkarSettings => 'إعدادات الدعاء والأذكار';

  @override
  String get showTransliteration => 'إظهار النطق';

  @override
  String get showIllustration => 'إظهار الرسمة';

  @override
  String get hideIllustrationArea => 'إخفاء منطقة الرسوم الفنية';

  @override
  String get arabicFontStyle => 'نمط الخط العربي';

  @override
  String get dailyAzkarComplete => 'اكتملت الأذكار اليومية!';

  @override
  String get dailyAzkarBonusMsg =>
      'ما شاء الله! تتبعت أذكارك اليومية وكسبت +50 سابق سيدز كمنحة.';

  @override
  String get awesome => 'رائع';

  @override
  String get betweenSubhSunrise => 'بين الفجر وشروق الشمس';

  @override
  String get betweenAsrMaghrib => 'بين العصر والمغرب';

  @override
  String get beforeSleeping => 'قبل النوم';

  @override
  String get uponWakingUp => 'عند الاستيقاظ';

  @override
  String get afterEachPrayer => 'بعد كل صلاة';

  @override
  String get anytimeEspeciallyAfterPrayer => 'في أي وقت، خاصة بعد الصلاة';

  @override
  String get anytimeMorningEvening => 'في أي وقت، صباحاً ومساءً';

  @override
  String get duringTheNight => 'أثناء الليل';

  @override
  String get anytime => 'في أي وقت';

  @override
  String get asPerSunnah => 'حسب السنة';

  @override
  String get whenEatingDrinking => 'عند الأكل أو الشرب';

  @override
  String get enteringLeavingHome => 'عند الدخول / الخروج من المنزل';

  @override
  String get beforeAfterWudu => 'قبل أو بعد الوضوء';

  @override
  String get whenGettingDressed => 'عند ارتداء الملابس';

  @override
  String get uponBadDream => 'عند رؤية كابوس';

  @override
  String get forUmmahAnytime => 'للأمة، في أي وقت';

  @override
  String get all => 'الكل';

  @override
  String get general => 'عام';

  @override
  String get startNow => 'ابدأ الآن';

  @override
  String get markAsDone => 'تحديد كمكتمل';

  @override
  String get enterCustomCount => 'أدخل عدداً مخصصاً';

  @override
  String get resetToDefault => 'إعادة للوضع الافتراضي';

  @override
  String get noAzkarFound => 'لم يتم العثور على أذكار هنا.';

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
  String get salawat => 'الصلاة على النبي';

  @override
  String get sunnahDuas => 'الأدعية السنية';

  @override
  String get quranicDuas => 'الأدعية القرآنية';

  @override
  String get istighfar => 'استغفار';

  @override
  String get dhikarAllTimes => 'أذكار كل وقت';

  @override
  String get namesOfAllah => 'أسماء الله الحسنى';

  @override
  String get nightmares => 'الكوابيس';

  @override
  String get wakingUp => 'الاستيقاظ';

  @override
  String get clothes => 'ملابس';

  @override
  String get wudu => 'الوضوء';

  @override
  String get foodAndDrink => 'الطعام والشراب';

  @override
  String get home => 'الرئيسية';

  @override
  String get istikharah => 'استخارة';

  @override
  String get adaanAndMasjid => 'الأذان والمسجد';

  @override
  String get diffAndHappy => 'مختلف وسعيد';

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
  String get death => 'الموت';

  @override
  String get gatherings => 'المجالس';

  @override
  String get hajjAndUmrah => 'الحج والعمرة';

  @override
  String get dailyEssentials => 'الأساسيات اليومية';

  @override
  String get akhirahBalance => 'رصيد الآخرة';

  @override
  String get priceless => 'لا يُقدر بثمن';

  @override
  String get beyondWorldCanHold => 'أعظم مما تتسع له الدنيا';

  @override
  String deedsToday(String count) {
    return '+$count أعمال اليوم';
  }

  @override
  String deedsThisWeek(String count) {
    return '+$count هذا الأسبوع';
  }

  @override
  String bestDayStreak(String count) {
    return 'الأفضل: $count يوم متتالي';
  }

  @override
  String get donateMoreEarn => 'تبرع أكثر واكسب';

  @override
  String get yourHoldings => 'أرصدتك';

  @override
  String get seeAll => 'عرض الكل ←';

  @override
  String get hasanaatEarned => 'الحسنات المكتسبة';

  @override
  String get recordedInBookOfDeeds => 'سُجلت في صحيفة أعمالك';

  @override
  String get treesInJannah => 'أشجار في الجنة';

  @override
  String get fromTasbih => 'من سبحان الله والتسبيح';

  @override
  String get sinsForgiven => 'الذنوب المغفورة';

  @override
  String get likeTheFoamOfSea => 'مثل زبد البحر';

  @override
  String get palacesBuilt => 'القصور المبنية';

  @override
  String get surahIkhlasAndSunnahs => 'سورة الإخلاص والسنن';

  @override
  String get treasuresOfJannah => 'كنوز الجنة';

  @override
  String get slavesFreedom => 'الرقاب المُعتقة';

  @override
  String get equivalentReward => 'تم كسب ثواب معادل';

  @override
  String get sadaqahGiven => 'الصدقات المعطاة';

  @override
  String get pointsDonatedToCommunity => 'الـ سيدز المتبرع بها للمجتمع';

  @override
  String get allTimeLabel => 'كل الوقت';

  @override
  String get worshipActivity => 'نشاط العبادة';

  @override
  String get timeSpentInRemembrance => 'الوقت المقضي في الذكر';

  @override
  String get noorPointsSummary => 'ملخص سابق سيدز';

  @override
  String get totalPoints => 'إجمالي الـ سيدز';

  @override
  String get title => 'العنوان';

  @override
  String get everyDeedRecorded => 'كل عمل مسجل. استمر!';

  @override
  String yourAvailable(String pts) {
    return 'المتاح لديك: $pts سيدز';
  }

  @override
  String jazakAllahDonated(String pts) {
    return 'جزاك الله خيراً! تبرعت بـ $pts سيدز';
  }

  @override
  String get insufficientPoints => 'رصيد سيدز غير كافٍ';

  @override
  String donatePoints(String pts) {
    return 'تبرع بـ $pts سيدز';
  }

  @override
  String get everyRecitationCanChange => 'كل تلاوة يمكنها\nتغيير حياة';

  @override
  String get fullyFunded => 'ممول بالكامل ✓';

  @override
  String get noPointsAvailable => 'لا تتوفر سيدز';

  @override
  String get communityProgress => 'تقدم المجتمع';

  @override
  String myContribution(String pts) {
    return 'مساهمتي: $pts نقطة';
  }

  @override
  String get ptsRaised => 'نقطة تم جمعها';

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
  String get noStoryYet => 'لم يتم إضافة قصة بعد.';

  @override
  String get checkAdminPanel => 'تحقق من لوحة الإدارة لإضافة قصة الحملة.';

  @override
  String get noUpdatesYet => 'لا توجد تحديثات بعد.';

  @override
  String get checkBackForNews => 'عُد قريباً لأخبار الحملة.';

  @override
  String get yesterday => 'أمس';

  @override
  String daysAgo(String count) {
    return 'منذ $count أيام';
  }

  @override
  String get shareCampaign => 'مشاركة الحملة';

  @override
  String get spreadTheWord => 'انشر الخبر وساعد هذه الحملة على الوصول لهدفها.';

  @override
  String get shareViaWhatsApp => 'مشاركة عبر واتساب';

  @override
  String get moreSharingOptions => 'خيارات مشاركة إضافية...';

  @override
  String get slideToAdjust => 'اسحب للضبط';

  @override
  String get balance => 'الرصيد';

  @override
  String get loadingYourReport => 'جاري تحميل تقريرك...';

  @override
  String get profileUpdated => 'تم تحديث الملف ✓';

  @override
  String get couldNotSave => 'تعذر الحفظ، يرجى المحاولة مرة أخرى';

  @override
  String get photoUpdated => 'تم تحديث الصورة ✓';

  @override
  String get couldNotUploadPhoto => 'تعذر رفع الصورة، يرجى المحاولة مرة أخرى';

  @override
  String get changeProfilePhoto => 'تغيير صورة الملف';

  @override
  String get takeAPhoto => 'التقاط صورة';

  @override
  String get chooseFromLibrary => 'اختر من المكتبة';

  @override
  String get removePhoto => 'إزالة الصورة';

  @override
  String get photoRemoved => 'تمت إزالة الصورة';

  @override
  String get couldNotRemovePhoto => 'تعذر إزالة الصورة';

  @override
  String get signOutQuestion => 'هل تريد تسجيل الخروج؟';

  @override
  String get progressSafelyStored =>
      'تقدمك محفوظ بأمان. يمكنك تسجيل الدخول في أي وقت.';

  @override
  String get accountInformation => 'معلومات الحساب';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get helpAndSupport => 'المساعدة والدعم';

  @override
  String get profilePhoto => 'صورة الملف الشخصي';

  @override
  String get tapEditToChange => 'انقر على تعديل لتغيير صورتك';

  @override
  String get tapEditToAdd => 'انقر على تعديل لإضافة صورة';

  @override
  String get edit => 'تعديل';

  @override
  String get displayName => 'اسم العرض';

  @override
  String get yourName => 'اسمك';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get country => 'البلد';

  @override
  String get countryHint => 'مثال: السعودية، مصر...';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get notifOnDesc => 'المكافآت، إنجازات الاستمرارية، التبرعات والمزيد';

  @override
  String get notifOffDesc => 'مغلق، لن يتم إضافة تنبيهات جديدة';

  @override
  String get viewNotificationsInbox => 'عرض صندوق الإشعارات';

  @override
  String nNew(String n) {
    return '$n جديد';
  }

  @override
  String get helpCenter => 'مركز المساعدة';

  @override
  String get reportABug => 'الإبلاغ عن خطأ';

  @override
  String get aboutNoorRewards => 'عن Sabiq Rewards';

  @override
  String get builtWithLove => 'صُنع بحب للأمة';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get howWeProtectData => 'كيف نحمي بياناتك';

  @override
  String get bugReportBody => 'وجدت خطأ؟ يرجى مراسلتنا وسنصلحه في أقرب وقت.';

  @override
  String get aboutBody =>
      'صُنع بحب للأمة الإسلامية.\nاربح سابق سيدز ببناء عادات إسلامية.\nتبرع بـ سيدز لدعم مشاريع مجتمعية حقيقية.';

  @override
  String get howToEarnQuestion => 'كيف تكسب سابق سيدز؟';

  @override
  String get howToEarnAnswer =>
      'أكمل قراءة القرآن ومجموعات الذكر والدخول اليومي لكسب سيدز.';

  @override
  String get whatIsValidateQuestion => 'ما هو حفظ العملات؟';

  @override
  String get whatIsValidateAnswer =>
      'اضغط على زر حفظ اليوم في الصفحة الرئيسية مرة واحدة يومياً لحفظ عملاتك.';

  @override
  String get howStreaksWorkQuestion => 'كيف تعمل الاستمرارية (Streaks)؟';

  @override
  String get howStreaksWorkAnswer =>
      'أكمل أنشطتك اليومية بشكل متتابع لبناء استمراريتك.';

  @override
  String get canDonatQuestion => 'هل يمكنني التبرع بـ سابق سيدز؟';

  @override
  String get canDonateAnswer =>
      'نعم! زر قسم الآخرة للتبرع بـ سيدز لمشاريع مجتمعية.';

  @override
  String get coinsSealedMashaAllah => 'تم حفظ العملات!';

  @override
  String get rewardedForConsistency => 'لقد كوفئت على\nاستمراريتك اليوم!';

  @override
  String get validationPoints => 'نقاط الحفظ';

  @override
  String streakBonus(String days, String type, String points) {
    return 'منحة الاستمرارية';
  }

  @override
  String get totalEarned => 'إجمالي المكتسب';

  @override
  String get openQuran => 'فتح القرآن';

  @override
  String get duaAndAzkaar => 'الدعاء والأذكار';

  @override
  String get shareWithFriends => 'مشاركة مع الأصدقاء';

  @override
  String get earnMoreNoor => 'اكسب المزيد من سيدز';

  @override
  String get dontDisturb => 'عدم الإزعاج';

  @override
  String get maybeLater => 'ربما لاحقاً';

  @override
  String get read5QuranPages => 'اقرأ 5 صفحات من القرآن';

  @override
  String get completeNowBonus => 'أكمل الآن → اكسب +50 سيدز كمنحة';

  @override
  String get completeADhikrSet => 'أكمل مجموعة أذكار';

  @override
  String get finishAzkaarBonus => 'أنهِ أذكارك → اكسب +30 سيدز كمنحة';

  @override
  String get inviteAFriend => 'ادعُ صديقاً';

  @override
  String get shareNoorBonus => 'شارك سابق مع شخص ما → اكسب +100 سيدز';

  @override
  String get multiplyYour => 'ضاعف';

  @override
  String get noorPointsBang => 'سابق سيدز!';

  @override
  String get keepMomentum =>
      'حافظ على نشاطك الروحي\nوشاهد الـ سيدز الخاصة بك تنمو';

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
  String get coinsFundCauses => 'الـ سيدز تدعم\nمشاريع خيرية';

  @override
  String get unexpectedGoogleError =>
      'خطأ غير متوقع أثناء تسجيل الدخول بـ Google';

  @override
  String get authSuccessQuran => 'تمت المصادقة مع Quran.com بنجاح!';

  @override
  String get authError => 'خطأ في المصادقة';

  @override
  String get ok => 'حسناً';

  @override
  String get verified => 'مُوثق';

  @override
  String get connectedAccount => 'الحساب المتصل';

  @override
  String get active => 'نشط';

  @override
  String noorPlusPoints(String pts) {
    return '+$pts سابق سيدز';
  }

  @override
  String get yourGarden => 'بستانك';

  @override
  String get noorPointsBloomed => 'ازدهرت الـ سابق سيدز';

  @override
  String get growingStreakTitle => 'استمرارية متنامية';

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
  String get monthTab => 'الشهر';

  @override
  String get todayTab => 'اليوم';

  @override
  String ofTabGoal(String goal, String tab) {
    return 'من هدف $goal $tab';
  }

  @override
  String get todaysPlots => 'مزارع اليوم';

  @override
  String setsTodayCount(String count) {
    return 'مجموعات اليوم $count';
  }

  @override
  String get earnPerFriend => 'اكسب +500 لكل صديق';

  @override
  String lastAchievement(String name) {
    return 'الآخير: $name';
  }

  @override
  String outOfBelievers(String count) {
    return 'من بين $count مؤمنين';
  }

  @override
  String yourRankNum(String rank) {
    return 'رتبتك: #$rank';
  }

  @override
  String get youIndicator => '(أنت)';

  @override
  String get greetingPrefix => 'السلام عليكم،';

  @override
  String get fundProjectsText => 'الـ سابق سيدز الخاصة بك تمول هذه المشاريع';

  @override
  String activeCount(String count) {
    return '$count نشط';
  }

  @override
  String get seeDetailsForMoreProjects => 'شاهد التفاصيل للمزيد من المشاريع ←';

  @override
  String get notificationsSubtitle => 'ابق على اطلاع بالمكافآت والإنجازات';

  @override
  String get markAllAsRead => 'تحديد الكل كمقروء';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get notificationsOn => 'الإشعارات مفعلة';

  @override
  String get notificationsOff => 'الإشعارات مغلقة';

  @override
  String get allCaughtUp => 'أنت على اطلاع تام';

  @override
  String get whenYouEarnRewards =>
      'عندما تكسب مكافآت، أو تحقق استمرارية، أو تفتح شارة،\nستظهر هنا.';

  @override
  String get justNow => 'الآن';

  @override
  String mAgo(String delta) {
    return 'منذ $delta دقيقة';
  }

  @override
  String hAgo(String delta) {
    return 'منذ $delta ساعة';
  }

  @override
  String dAgo(String delta) {
    return 'منذ $delta يوم';
  }

  @override
  String get newBadgeUnlocked => 'تم فتح شارة جديدة';

  @override
  String get daySealed => 'اكتمل اليوم';

  @override
  String get dailyLoginBonus => 'منحة الدخول اليومي';

  @override
  String get oneWeek => 'أسبوع واحد';

  @override
  String get twoWeeks => 'أسبوعان';

  @override
  String badgeEarnedDesc(String badge) {
    return 'لقد ربحت شارة \"$badge\".';
  }

  @override
  String pointsForSealing(String points) {
    return '+$points سابق سيدز لإكمال مهام اليوم.';
  }

  @override
  String welcomeBack(String points) {
    return '+$points سابق سيدز · أهلاً بعودتك!';
  }

  @override
  String get onbV2Skip => 'تخطي';

  @override
  String get onbV2Next => 'التالي';

  @override
  String get onbV2_1_TitleA => 'قراءتك للقرآن';

  @override
  String get onbV2_1_TitleB => 'تطعم الجائعين.';

  @override
  String get onbV2_1_Sub => 'وجبات حقيقية. أناس حقيقيون. أثر حقيقي.';

  @override
  String get onbV2_1_Cta => 'كيف يعمل ذلك؟';

  @override
  String get onbV2_2_Title => 'إليك الطريقة.';

  @override
  String get onbV2_2_Body =>
      'اقرأ القرآن أو اذكر الله → اكسب سابق سيدز → تبرع لمشاريع حقيقية.';

  @override
  String get onbV2_3_TitleA => 'القرآن يكافئك';

  @override
  String get onbV2_3_TitleB => 'مرتين.';

  @override
  String get onbV2_3_Sub =>
      'مرة ببركة الله. ومرة بالـ سيدز التي تطعم المحتاجين.';

  @override
  String get onbV2_3_BannerLabel => 'كُسب اليوم';

  @override
  String get onbV2_4_TitleA => 'شاهد عبادتك';

  @override
  String get onbV2_4_TitleB => 'تصبح حقيقة.';

  @override
  String get onbV2_4_Sub =>
      'اقرأ أذكار الصباح والمساء، وشاهد أجرك ينمو حديثاً بعد حديث.';

  @override
  String get onbV2_5_TitleA => 'قراءتك تصل';

  @override
  String get onbV2_5_TitleB => 'إلى هنا.';

  @override
  String get onbV2_5_Sub => 'كل سيد تكسبها تصبح طعاماً وماءً وأملاً حقيقياً.';

  @override
  String get onbV2_6_TitleA => 'لكن من أين يأتي';

  @override
  String get onbV2_6_TitleB => 'المال';

  @override
  String get onbV2_6_TitleC => '؟';

  @override
  String get onbV2_6_Sub =>
      'المتبرعون الأسخياء يمولون المشاريع. الـ سيدز الخاصة بك توجه أموالهم إلى حيث يجب أن تذهب، وتزيد من أجرهم مع كل قارئ.';

  @override
  String get onbV2_6_Donor => 'المتبرع';

  @override
  String get onbV2_6_DonorSub => 'يمول الحملة';

  @override
  String get onbV2_6_You => 'أنت';

  @override
  String get onbV2_6_YouSub => 'توجه العطاء';

  @override
  String get onbV2_6_Charity => 'الجمعية الخيرية';

  @override
  String get onbV2_6_CharitySub => 'توصيل المساعدات';

  @override
  String get onbV2_6_TrustBadge => 'تُصرف 100% لشركاء موثوقين';

  @override
  String get onbV2_7_TitleA => 'كل عمل';

  @override
  String get onbV2_7_TitleB => 'محسوب.';

  @override
  String get onbV2_7_Sub =>
      'شاهد حساب آخرتك الذي تبنيه: أشجار، قصور، ورقاب مُعتقة، موثقة بالأحاديث الصحيحة.';

  @override
  String get onbV2_8_TitleA => 'لنبأ باسمك';

  @override
  String get onbV2_8_TitleB => 'أولاً.';

  @override
  String get onbV2_8_Sub => 'ليصبح سابق أقرب إليك.';

  @override
  String get onbV2_8_Placeholder => 'اسمك';

  @override
  String get onbV2_8_Cta => 'متابعة';

  @override
  String get onbV2_9_TitleA => 'أي قضايا الخير تلامس';

  @override
  String get onbV2_9_TitleB => 'قلبك؟';

  @override
  String get onbV2_9_Sub =>
      'تدعم الـ سيدز الخاصة بك كافة الحملات، هذا فقط يساعدنا على فهم ما يهم مجتمعنا.';

  @override
  String get onbV2_9_Cta => 'ابدأ';

  @override
  String get onbV2_9_Orphans => 'الأيتام';

  @override
  String get onbV2_9_OrphansSub => 'إطعام ورعاية الأطفال الذين فقدوا كل شيء';

  @override
  String get onbV2_9_Water => 'آبار المياه';

  @override
  String get onbV2_9_WaterSub => 'مياه نظيفة للقرى المحتاجة';

  @override
  String get onbV2_9_War => 'مناطق النزاعات';

  @override
  String get onbV2_9_WarSub => 'إغاثة أينما دعت الحاجة';

  @override
  String get onbV2_9_Disaster => 'الكوارث الطبيعية';

  @override
  String get onbV2_9_DisasterSub => 'استجابة سريعة عند وقوع الأزمات';

  @override
  String get onbV2_3step_Title => 'ثلاث خطوات بسيطة.';

  @override
  String get onbV2_3step_Sub => 'كل آية وكل ذكر يصبح عوناً حقيقياً.';

  @override
  String get onbV2_3step_S1Label => 'الخطوة 1';

  @override
  String get onbV2_3step_S1Text => 'اقرأ القرآن';

  @override
  String get onbV2_3step_S2Label => 'الخطوة 2';

  @override
  String get onbV2_3step_S2Text => 'اكسب سيدز';

  @override
  String get onbV2_3step_S3Label => 'الخطوة 3';

  @override
  String get onbV2_3step_S3Text => 'أطعم الأيتام';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get systemDefault => 'الافتراضي للنظام';

  @override
  String get yourStreaksTitle => 'استمراريتك';

  @override
  String get streakLoading => 'جاري تحميل الاستمرارية...';

  @override
  String get startStreakToday => 'ابدأ استمراريتك اليوم!';

  @override
  String get centurionMashaAllah => 'المئوية، ما شاء الله!';

  @override
  String get qfConflictTitle => 'الحساب موجود مسبقاً';

  @override
  String get qfConflictExplanation =>
      'هذا البريد مسجل مسبقاً في Sabiq Rewards بطريقة دخول أخرى (البريد أو Google).\n\nلحماية تقدمك واستمراريتك ورصيد الـ سيدز، يرجى تسجيل الدخول بطريقتك الأصلية.';

  @override
  String get qfConflictStep1 => 'العودة لشاشة تسجيل الدخول';

  @override
  String qfConflictStep2(String email) {
    return 'سجل الدخول بالبريد أو Google باستخدام\n$email';
  }

  @override
  String get qfConflictStep3 => 'ستجد كل تقدمك محفوظاً';

  @override
  String get qfConflictBackButton => 'العودة لتسجيل الدخول';

  @override
  String get sponsorAnOrphan => 'كفالة يتيم';

  @override
  String get noOrphansListed => 'لم يتم إدراج أيتام بعد';

  @override
  String get checkBackForOrphans => 'عُد قريباً، تضاف فرص كفالة جديدة بانتظام.';

  @override
  String get orphanVerseTranslation => 'فأما اليتيم فلا تقهر.';

  @override
  String get orphanCardOpen => 'فتح';

  @override
  String get doneLabel => 'تم';

  @override
  String get aReminderLabel => 'تذكير';

  @override
  String get yourAkhirahBalance => 'رصيد آخرتك';

  @override
  String get seedsCollectedSinceJoined => 'الـ سيدز المجمعة منذ انضمامك';

  @override
  String get todayLabel => 'اليوم';

  @override
  String plusSeedsToday(String count) {
    return '+$count اليوم';
  }

  @override
  String get azkaarPerDay => 'أذكار في اليوم';

  @override
  String get viewFullStats => 'عرض الإحصائيات كاملة';

  @override
  String get fatherLabel => 'الأب';

  @override
  String get motherLabel => 'الأم';

  @override
  String get siblingsLabel => 'الإخوة';

  @override
  String get familySection => 'الأسرة';

  @override
  String get educationSection => 'التعليم';

  @override
  String get gradeLabel => 'الدرجة';

  @override
  String get schoolLabel => 'مدرسة';

  @override
  String get theirStorySection => 'قصتهم';

  @override
  String get yourBalanceLabel => 'رصيدك:';

  @override
  String sponsorCta(String name) {
    return 'اكفل $name';
  }

  @override
  String get notEnoughSeeds => 'الـ سيدز غير كافية';

  @override
  String get bookmarkSyncDialogTitle => 'مزامنة إشارات Quran.com';

  @override
  String get closeLabel => 'إغلاق';

  @override
  String get searchHint => 'بحث...';

  @override
  String get enterCodeHint => 'أدخل الكود...';

  @override
  String get searchSurahHint => 'ابحث عن سورة...';

  @override
  String get customLabel => 'مخصص';

  @override
  String get seedsSuffix => 'سيدز';

  @override
  String get settingsTooltip => 'الإعدادات';

  @override
  String get retryLabel => 'إعادة المحاولة';

  @override
  String get authErrorTitle => 'خطأ في المصادقة';

  @override
  String sealWithinHours(int hours) {
    return 'احفظ خلال $hours ساعة';
  }

  @override
  String sealWithinMinutes(int minutes) {
    return 'احفظ خلال $minutes دقيقة';
  }

  @override
  String get sealNow => 'احفظ الآن';

  @override
  String get goalLabel => 'الهدف';

  @override
  String contributorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مساهمين',
      one: 'مساهم 1',
    );
    return '$_temp0';
  }

  @override
  String dayStreakCount(int streak) {
    return 'استمرارية $streak يوم 🔥';
  }

  @override
  String seedsPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سيدز معلقة',
      one: 'سيد 1 معلق',
    );
    return '$_temp0';
  }

  @override
  String get sealToSave => 'احفظ لتأمين الرصيد';

  @override
  String get top10Contributors => 'أفضل 10 مساهمين';

  @override
  String get copyLabel => 'نسخ';

  @override
  String get copiedLabel => 'تم النسخ!';

  @override
  String get whatsappLabel => 'واتساب';

  @override
  String get youBothEarnSeeds => 'كلاكما يربح 500 سابق سيدز!';

  @override
  String jazakAllahPlusSeeds(int seeds) {
    return 'جزاك الله خيراً! +$seeds سيدز';
  }

  @override
  String get jazakAllahDaySealed => 'جزاك الله خيراً! اكتمل اليوم';

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
    return 'حدد هدف الـ سيدز (الافتراضي: $defaultVal)';
  }

  @override
  String get noInternetTitle => 'لا يوجد اتصال بالإنترنت';

  @override
  String get connectingTitle => 'جاري الاتصال...';

  @override
  String get somethingWentWrongTitle => 'حدث خطأ ما';

  @override
  String get noInternetSubtitle =>
      'تحتاج هذه الميزة للإنترنت.\nتحقق من اتصالك بالشبكة.';

  @override
  String get connectingSubtitle => 'جلب بياناتك...\nيرجى الانتظار قليلاً';

  @override
  String get errorSubtitle => 'حدث خطأ غير متوقع.\nانقر للمحاولة مرة أخرى.';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get everyRecitationCanChangeLife => 'كل تلاوة يمكنها\nتغيير حياة';

  @override
  String get givenLabel => 'المُعطى';

  @override
  String get goalUpper => 'الهدف';

  @override
  String get aboutThisCause => 'عن هذه الحملة';

  @override
  String myContributionSeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مساهمتي: $count سيدز',
      one: 'مساهمتي: 1 سيد',
    );
    return '$_temp0';
  }

  @override
  String jazakAllahKhayranDonated(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: 'جزاك الله خيراً! تم التبرع بـ $amount سيدز.',
      one: 'جزاك الله خيراً! تم التبرع بـ 1 سيد.',
    );
    return '$_temp0';
  }

  @override
  String get coinsSealedTitle => 'تم حفظ العملات! ما شاء الله';

  @override
  String get seedsSealedSafe => 'الـ سيدز الخاصة بك محفوظة بأمان\nللآخرة.';

  @override
  String get validationSeedsLabel => 'سيدز الحفظ';

  @override
  String get streakBonusLabel => 'منحة الاستمرارية';

  @override
  String get totalEarnedLabel => 'إجمالي المكتسب';

  @override
  String get alhamdulillahCta => 'الحمد لله! 🤲';

  @override
  String get openQuranCta => 'فتح القرآن';

  @override
  String get duaAzkaarCta => 'الدعاء والأذكار';

  @override
  String get shareWithFriendsCta => 'مشاركة مع الأصدقاء';

  @override
  String get earnMoreSeedsCta => 'اكسب المزيد من سيدز';

  @override
  String levelTitleFormat(int level, String title) {
    return 'المستوى $level · $title';
  }

  @override
  String get akhirahBalanceUpper => 'رصيد الآخرة';

  @override
  String bestDayStreakBadge(int streak) {
    return 'الأفضل: $streak يوم متتالي';
  }

  @override
  String get deedsLabel => 'الأعمال';

  @override
  String get treesLabel => 'الأشجار';

  @override
  String get forgivenLabel => 'مغفور له';

  @override
  String get navCause => 'الحملة';

  @override
  String get realChildrenSubtitle => 'أطفال حقيقيون، قصصهم وحياتهم';

  @override
  String get seeAllAction => 'عرض الكل';

  @override
  String get activeCampaigns => 'الحملات النشطة';

  @override
  String get poolSeedsImpact => 'اجمع الـ سيدز لأثر يدوم';

  @override
  String get featuredSponsorChild => 'مميز · اكفل طفلاً';

  @override
  String meetOrphanAge(String name, int age) {
    return 'تعرف على $name، العمر $age';
  }

  @override
  String sponsorNameArrow(String name) {
    return 'اكفل $name ←';
  }

  @override
  String get featuredCampaign => 'حملة مميزة';

  @override
  String get yourGiving => 'عطاؤك';

  @override
  String get havenNotGivenYet =>
      'لم تتبرع بعد. اختر شخصاً أعلاه لتبدأ رحلة أثرك.';

  @override
  String get seedsDonatedLabel => 'الـ سيدز المتبرع بها';

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
      other: '$count مشاريع',
      one: 'مشروع 1',
    );
    return '$_temp0';
  }

  @override
  String get couldntLoadJourney => 'تعذر تحميل رحلتك';

  @override
  String get checkConnectionRetry => 'تأكد من الاتصال وحاول مجدداً.';

  @override
  String actionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أعمال',
      one: 'عمل 1',
    );
    return '$_temp0';
  }

  @override
  String get showLessAction => 'عرض أقل ←';

  @override
  String get hadithReference => 'مرجع الحديث';

  @override
  String get howYouEarnedThis => 'كيف كسبت هذا';

  @override
  String seedsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سيدز',
      one: 'سيد 1',
    );
    return '$_temp0';
  }

  @override
  String get seedsUnit => 'سيدز';

  @override
  String get topContribByLifetimeSeeds => 'أفضل المساهمين بـ سيدز طوال الوقت';

  @override
  String get romanisedPronunciation => 'نطق بحروف لاتينية تحت كل كلمة';

  @override
  String get displayLabel => 'العرض';

  @override
  String get arabicLanguageLabel => 'العربية';

  @override
  String get urduLanguageLabel => 'الأردية';

  @override
  String get englishLanguageLabel => 'الإنجليزية';

  @override
  String get earnPerVerseRead => 'اكسب +10 سابق سيدز لكل آية تقرؤها';

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
    return '$name بها $count آيات';
  }

  @override
  String noXYet(String label) {
    return 'لا يوجد $label بعد';
  }

  @override
  String get tapHeartToSave =>
      'انقر على أيقونة القلب/الإشارة أثناء القراءة لحفظ الآيات.';

  @override
  String surahVerseRow(int surah, int ayah) {
    return 'سورة $surah • آية $ayah';
  }

  @override
  String get hasanatFromQuran => 'حسنات من القرآن';

  @override
  String tenPerLetterSubtitle(int count) {
    return '10 لكل حرف، $count لكل آية';
  }

  @override
  String get fromSubhanAllahTasbih => 'من سبحان الله والتسبيح';

  @override
  String get likeFoamOfSea => 'مثل زبد البحر';

  @override
  String get fromSurahIkhlasRecitation => 'من تلاوة سورة الإخلاص';

  @override
  String get laHawlaSubtitle => 'لا حول ولا قوة إلا بالله';

  @override
  String get equivalentRewardEarned => 'تم كسب ثواب معادل';

  @override
  String get gatesOfParadise => 'أبواب الجنة';

  @override
  String get afterPerfectWudu => 'بعد إسباغ الوضوء';

  @override
  String get blessingsFromAllah => 'نعم من الله';

  @override
  String get salawatTenReturned => 'كُتب لك 10 صلوات';

  @override
  String get timesProtected => 'مرات الحماية';

  @override
  String get refugeInvokedFromHarm => 'تمت الاستعاذة من الأذى';

  @override
  String get quranCompletions => 'ختمات القرآن';

  @override
  String get viaSurahIkhlas => 'بفضل سورة الإخلاص ×3';

  @override
  String get bonusHasanaat => 'حسنات إضافية';

  @override
  String get marketplaceDua => 'دعاء دخول السوق';

  @override
  String get seedsDonatedToCommunity => 'الـ سيدز المتبرع بها للمجتمع';

  @override
  String get yourMonth => 'شهرك';

  @override
  String get ayahsReadLabel => 'الآيات المقروءة';

  @override
  String get dhikrCount => 'عدد الأذكار';

  @override
  String get quranTime => 'وقت القرآن';

  @override
  String get dhikrTime => 'وقت الذكر';

  @override
  String get activeDays => 'أيام النشاط';

  @override
  String get treesShortLabel => 'الأشجار';

  @override
  String get palacesShortLabel => 'القصور';

  @override
  String get freedShortLabel => 'مُعتق';

  @override
  String get blessingsShortLabel => 'النعم';

  @override
  String get dailyWordPrefix => 'يومي ';

  @override
  String get essentialsWord => 'الأساسيات';

  @override
  String get seedsExpiringNotificationTitle =>
      'الـ سيدز ستنتهي صلاحيتها في منتصف الليل!';

  @override
  String seedsExpiringNotificationBody(int pending) {
    return 'لديك $pending سيدز معلقة. احفظ اليوم الآن وإلا ستنتهي صلاحيتها!';
  }

  @override
  String get okButton => 'حسناً';

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
      'تم التسجيل بنجاح! يرجى التحقق من بريدك لتأكيد الحساب.';

  @override
  String get unexpectedAuthError => 'حدث خطأ غير متوقع';

  @override
  String get sawabLabel => 'الثواب';

  @override
  String get impactLabel => 'الأثر';

  @override
  String get goodDeedTitle => 'عمل صالح';

  @override
  String get goodDeedSubtitle => 'اكسب الثواب\nمع كل قراءة';

  @override
  String get realImpactTitle => 'أثر حقيقي';

  @override
  String get realImpactSubtitle => 'العملات تمول\nمشاريع خيرية';

  @override
  String plusDeedsTodayBadge(String count) {
    return '+$count أعمال اليوم';
  }

  @override
  String equivalentChange(String count) {
    return 'ما يعادل $count';
  }

  @override
  String receivedChange(String count) {
    return 'تم استلام $count';
  }

  @override
  String readAyahsPlusTimeToday(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قُرأت $count آيات و $time من قراءة القرآن اليوم',
      one: 'قُرأت آية واحدة و $time من قراءة القرآن اليوم',
    );
    return '$_temp0';
  }

  @override
  String readAyahsToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قُرأت $count آيات اليوم',
      one: 'قُرأت آية واحدة اليوم',
    );
    return '$_temp0';
  }

  @override
  String spentTimeReadingQuranToday(String time) {
    return 'قضيت $time في قراءة القرآن اليوم';
  }

  @override
  String get everyDeedRecordedKeepGoing => '🌙 كل عمل مسجل. استمر!';

  @override
  String viewAllDonors(int count) {
    return 'عرض جميع المتبرعين الـ $count';
  }

  @override
  String nextMilestoneInfo(String label, int days) {
    return 'القادم: $label ($days أيام)';
  }

  @override
  String bestN(int n) {
    return 'أفضل $n';
  }

  @override
  String get streakMilestoneWarmingUp => 'إحماء';

  @override
  String get streakMilestoneOneWeek => 'أسبوع واحد';

  @override
  String get streakMilestoneTwoWeeks => 'أسبوعان';

  @override
  String get streakMilestoneOneMonth => 'شهر واحد';

  @override
  String get streakMilestoneTwoMonths => 'شهران';

  @override
  String get streakMilestoneCenturion => 'المئوية';

  @override
  String get firstTrackedWeek => 'أول أسبوع لك مسجل — استمر!';

  @override
  String get rightOnSevenDayPace => 'أنت تسير على متوسطك لـ 7 أيام';

  @override
  String aboveSevenDayAvg(int pct) {
    return 'أعلى بنسبة $pct% من متوسطك لـ 7 أيام';
  }

  @override
  String belowSevenDayAvg(int pct) {
    return 'أقل بنسبة $pct% من متوسطك لـ 7 أيام';
  }

  @override
  String get sponsoredBy => 'برعاية';

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
  String get dayAbbrMon => 'ن';

  @override
  String get dayAbbrTue => 'ث';

  @override
  String get dayAbbrWed => 'ع';

  @override
  String get dayAbbrThu => 'خ';

  @override
  String get dayAbbrFri => 'ج';

  @override
  String get dayAbbrSat => 'س';

  @override
  String get dayAbbrSun => 'ح';

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
  String get duasAfterSalah => 'أدعية ما بعد الصلاة';

  @override
  String get rabbana40Duas => '40 دعاء من أدعية ربنا';

  @override
  String get thisWorld => 'هذه الدنيا';

  @override
  String get dunyaArabic => 'الدنيا';

  @override
  String get hereafter => 'الآخرة';

  @override
  String get akhirahArabic => 'الآخرة';

  @override
  String get bookOfCompletePrayer => 'كتاب الصلاة الكاملة';

  @override
  String get propheticDuas => 'الأدعية النبوية';

  @override
  String get morningEveningRemembrance => 'أذكار الصباح والمساء';

  @override
  String get furtherDuas => 'أدعية إضافية';

  @override
  String get closingSalawat => 'أذكار الختام والصلاة على النبي';

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
  String get secondPlural => 'ثوانٍ';

  @override
  String seedsThisSession(String count) {
    return '+$count سيدز في هذه الجلسة';
  }

  @override
  String sevenDayAvgAzkaar(String count) {
    return 'متوسط 7 أيام: $count ذكر/يوم';
  }

  @override
  String holdingChangeAyahs(String count) {
    return '$count آيات';
  }

  @override
  String holdingChangePlanted(String count) {
    return 'زُرع $count';
  }

  @override
  String holdingChangeCycles(String count) {
    return '$count دورات';
  }

  @override
  String holdingChangeBuilt(String count) {
    return 'بُني $count';
  }

  @override
  String holdingChangeEarned(String count) {
    return 'اُكتسب $count';
  }

  @override
  String holdingChangeOpened(String count) {
    return 'فُتح $count';
  }

  @override
  String holdingChangeInvocations(String count) {
    return '$count أدعية';
  }

  @override
  String holdingChangeRecitations(String count) {
    return '$count تلاوات';
  }

  @override
  String bookmarksOnQuranCom(String count) {
    return 'الإشارات في Quran.com:  $count';
  }

  @override
  String bookmarksInThisApp(String count) {
    return 'الإشارات في التطبيق:   $count';
  }

  @override
  String streakSeedsBonus(String count) {
    return '+$count سيدز';
  }

  @override
  String plusSeedsThisWeek(String count) {
    return '+$count هذا الأسبوع';
  }

  @override
  String unitDuas(String count) {
    return '$count أدعية';
  }

  @override
  String unitAdhkar(String count) {
    return '$count أذكار';
  }

  @override
  String get moreCollections => 'مجموعات أخرى';

  @override
  String get donateAndEarnReward => 'تبرع واكسب الأجر';

  @override
  String donateAmountSeeds(String amount) {
    return 'تبرع بـ $amount سيدز';
  }

  @override
  String get readMore => 'اقرأ المزيد';

  @override
  String get beFirstToContribute => 'كن أول المساهمين.';

  @override
  String get showFewer => 'عرض أقل ↑';

  @override
  String viewAllN(String n) {
    return 'عرض الكل $n ←';
  }

  @override
  String liveReadersNow(String count) {
    return '$count متصل الآن';
  }

  @override
  String communityReadingToday(String count) {
    return 'قُرئ $count اليوم (بواسطة المجتمع)';
  }

  @override
  String communityHasanatToday(String count) {
    return '+$count حسنات مجتمعية اليوم';
  }

  @override
  String get peopleReadingNow => 'يقرؤون الآن';

  @override
  String get readToday => 'قُرئ اليوم';

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
  String dashboardScreen_setsToday(String _dhikrToday, Object count) {
    return '$_dhikrToday مجموعات اليوم';
  }

  @override
  String dashboardScreen_last(String arg1) {
    return 'الأخير: $arg1';
  }

  @override
  String get dashboardScreen_earnPerFriend => 'اكسب +500 لكل صديق';

  @override
  String get dashboardScreen_invalidReferralCode_59fb25 =>
      'كود الدعوة غير صالح.';

  @override
  String dashboardScreen_52b02c(String pts) {
    return '$pts ';
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
      'بارك في كل حاسة، وكل طرف، وكل عمل';

  @override
  String get dhikrScreen_keepTheHeartFirm_9c4efb => 'ثبت القلب بعد الهداية';

  @override
  String get dhikrScreen_faithAnsweredWithForgiveness_3f30c4 =>
      'الإيمان يُقابل بالمغفرة من النار';

  @override
  String get dhikrScreen_inscribedWithTheWitnesses_e2612d =>
      'كُتبت مع شهداء الحق';

  @override
  String get dhikrScreen_allahIsTheBest_4f2bf7 =>
      'الله خير الحاكمين بين الحق والباطل';

  @override
  String get dhikrScreen_neverTrialForThe_5eb10a => 'لا فتنة للكافرين أبداً';

  @override
  String get dhikrScreen_refugeFromEveryEvil_6d2534 =>
      'استعاذة من كل شر يحيق بك';

  @override
  String get dhikrScreen_guaranteedJannahIfYou_48d274 =>
      'الجنة مضمونة، إن مت هذه الليلة';

  @override
  String get dhikrScreen_reciteAtDawnDusk_f17fb8 =>
      'اقرأها 3 مرات في الصباح والمساء، تكفيك من كل شيء';

  @override
  String get dhikrScreen_nothingShallHarmYou_8c5c6c => 'لن يضرك شيء باسمه';

  @override
  String get dhikrScreen_guaranteedJannahIfYou_0ffafe =>
      'الجنة مضمونة إن مت اليوم';

  @override
  String get dhikrScreen_guardedInYourDeen_4a0b4a =>
      'محفوظ في دينك ودنياك وآخرتك، ومن الجهات الست';

  @override
  String get dhikrScreen_guardMeFromAll => 'احفظني من الجهات الست كلها';

  @override
  String dhikrScreen_35c165(String arg1) {
    return '$arg1  ';
  }

  @override
  String get dhikrScreen_sinsWashedAway => 'مُحيت الذنوب';

  @override
  String get dhikrScreen_slavesFreed => 'عُتقت الرقاب';

  @override
  String get dhikrScreen_weHaveBelievedForgive_e958e6 =>
      'آمنا فاغفر لنا وأنت خير الراحمين';

  @override
  String get dhikrScreen_mashaallahRewardSecured =>
      'ما شاء الله! تم تأمين الأجر';

  @override
  String dhikrScreen_a5cfd1(String count) {
    return '×$count';
  }

  @override
  String get dhikrScreen_completeToWatchYour =>
      'أكمل لتشاهد حديقتك تزدهر في الأعلى';

  @override
  String impactReportScreen_200447(String arg1) {
    return '+$arg1';
  }

  @override
  String get impactReportScreen_deedsTODAY => 'أعمال اليوم';

  @override
  String impactReportScreen_634027(String arg1) {
    return '+$arg1';
  }

  @override
  String get impactReportScreen_thisWEEK => 'هذا الأسبوع';

  @override
  String get impactReportScreen_hasanaatEarned => 'الحسنات المكتسبة';

  @override
  String impactReportScreen_hasanat_e68a30(String arg1) {
    return '  → الحسنات: $arg1\\n\\n';
  }

  @override
  String get impactReportScreen_hasanatFromQuran => 'حسنات من القرآن';

  @override
  String get impactReportScreen_treesInJannah => 'أشجار في الجنة';

  @override
  String get impactReportScreen_sinsForgiven => 'الذنوب المغفورة';

  @override
  String get impactReportScreen_palacesBuilt => 'القصور المبنية';

  @override
  String get impactReportScreen_treasuresOfJannah => 'كنوز الجنة';

  @override
  String get impactReportScreen_slavesFreed => 'الرقاب المُعتقة';

  @override
  String impactReportScreen_totalRecitations_262e54(String arg1) {
    return 'إجمالي التلاوات: $arg1\\n';
  }

  @override
  String get impactReportScreen_gatesOfParadiseOpened => 'أبواب الجنة الفُتحت';

  @override
  String get impactReportScreen_blessingsFromAllah => 'بركات من الله';

  @override
  String get impactReportScreen_timesProtected => 'مرات الحماية';

  @override
  String get impactReportScreen_quranCompletions => 'ختمات القرآن';

  @override
  String get impactReportScreen_bonusMillionHasanaat => 'مليون حسنة إضافية';

  @override
  String get impactReportScreen_sadaqahGiven => 'الصدقات المعطاة';

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
  String impactReportScreen_ago_c25b44(String arg1) {
    return 'منذ $arg1 ساعة';
  }

  @override
  String impactReportScreen_ago_e160e3(String arg1) {
    return 'منذ $arg1 أسبوع';
  }

  @override
  String impactReportScreen_ago_65f0ec(String arg1) {
    return 'منذ $arg1 سنة';
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
    return '+$arg1 سيدز';
  }

  @override
  String levelScreen_seeds_a20530(String arg1) {
    return '+$arg1 سيدز';
  }

  @override
  String levelScreen_seeds_a49180(String arg1) {
    return '+$arg1 سيدز ✓';
  }

  @override
  String levelScreen_seeds_a22be5(String arg1) {
    return '+$arg1 سيدز';
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
  String levelScreen_seeds_990893(String arg1) {
    return '+$arg1 سيدز';
  }

  @override
  String get phase1Screens_inTheNameOf => 'بسم الله الرحمن الرحيم...';

  @override
  String onboardingComponents_355c50(String first) {
    return '$first ';
  }

  @override
  String onboardingComponents_b236c9(String trailing) {
    return ' $trailing';
  }

  @override
  String orphansGridScreen_36cd3b(String arg1, String arg2) {
    return '$arg1 · $arg2';
  }

  @override
  String orphanDetailScreen_ago_c25b44(String arg1) {
    return 'منذ $arg1 ساعة';
  }

  @override
  String orphanDetailScreen_ago_e160e3(String arg1) {
    return 'منذ $arg1 أسبوع';
  }

  @override
  String orphanDetailScreen_ago_65f0ec(String arg1) {
    return 'منذ $arg1 سنة';
  }

  @override
  String get profileSettingsScreen_sabiqRewards =>
      'Sabiq Rewards • الإصدار 1.0';

  @override
  String profileSettingsScreen_seeds_59ba7c(String arg1) {
    return '$arg1 سيدز';
  }

  @override
  String profileSettingsScreen_seeds_2bc978(String arg1) {
    return '$arg1 سيدز';
  }

  @override
  String get profileSetupScreen_ahmadFatimaYusuf => 'أحمد، فاطمة، يوسف...';

  @override
  String get profileSetupScreen_pakistanEgyptMalaysia =>
      'السعودية، مصر، الإمارات...';

  @override
  String projectDetailScreen_4c2b09(String arg1, String arg2, String arg3) {
    return '$arg1 $arg2 $arg3';
  }

  @override
  String projectDetailScreen_seeds_801ec7(String arg1) {
    return '$arg1 سيدز';
  }

  @override
  String projectDetailScreen_e4e562(String arg1) {
    return '$arg1%';
  }

  @override
  String projectDetailScreen_ago_c25b44(String arg1) {
    return 'منذ $arg1 ساعة';
  }

  @override
  String projectDetailScreen_ago_e160e3(String arg1) {
    return 'منذ $arg1 أسبوع';
  }

  @override
  String projectDetailScreen_ago_65f0ec(String arg1) {
    return 'منذ $arg1 سنة';
  }

  @override
  String get quranHubScreen_loadingQuran => 'جاري تحميل القرآن...';

  @override
  String quranHubScreen_saved_edce53(String arg1) {
    return 'تم حفظ $arg1';
  }

  @override
  String quranScreen_003843(String arg1, String arg2) {
    return '$arg1  $arg2';
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
      'بيانات الكلمات غير متوفرة. تحقق من الاتصال بالإنترنت.';

  @override
  String quranScreen_6d1f9d(String arg1) {
    return '$arg1 ';
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
  String get startJourneyScreen_connectedToQuranCom_0ac4de =>
      'متصل بـ Quran.com (تم تأجيل مزامنة الإشارات)';

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
      'يجب تسجيل الدخول للكفالة.';

  @override
  String get liveNotificationService_sealYourSeedsBefore_be2183 =>
      'احفظ الـ سيدز قبل منتصف الليل!';

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
    return '+$arg1 سيدز';
  }

  @override
  String get motivationalPopup_readQuranPages => 'اقرأ 5 صفحات من القرآن';

  @override
  String get motivationalPopup_completeDhikrSet => 'أكمل مجموعة أذكار';

  @override
  String get motivationalPopup_inviteFriend => 'ادعُ صديقاً';

  @override
  String notificationsSheet_ago(String arg1) {
    return 'منذ $arg1 دقيقة';
  }

  @override
  String notificationsSheet_ago_5d4e7f(String arg1) {
    return 'منذ $arg1 ساعة';
  }

  @override
  String notificationsSheet_ago_67b1d9(String arg1) {
    return 'منذ $arg1 يوم';
  }

  @override
  String sealCoinAnimation_e16fa4(String arg1) {
    return '+$arg1 ';
  }

  @override
  String orphan_be2bf7_be2bf7(String firstName, String lastInitial) {
    return '$firstName $lastInitial.';
  }

  @override
  String get akhirahBalanceScreen_subhanallahiWaBiHamdihi_b246c2 =>
      '\"سبحان الله وبحمده\" — من قالها 100 مرة حطت خطاياه وإن كانت مثل زبد البحر. (البخاري)';

  @override
  String get akhirahBalanceScreen_sayLaIlahaIllallah_27fc5f =>
      'قل لا إله إلا الله 100 مرة — تعدل عتق 10 رقاب و 100 حسنة. (البخاري)';

  @override
  String get akhirahBalanceScreen_lightOnTheTongue_ea6114 =>
      'كلمتان خفيفتان على اللسان، ثقيلتان في الميزان: سبحان الله وبحمده، سبحان الله العظيم. (البخاري 6406)';

  @override
  String get akhirahBalanceScreen_theDhikrOfAllah_a23f17 =>
      'ذكر الله أثقل في الميزان من الذهب. استمر.';

  @override
  String get akhirahBalanceScreen_yourTongueShouldStay_34816c =>
      '\"لا يزال لسانك رطباً من ذكر الله.\" — هل لا يزال رطباً؟';

  @override
  String get akhirahBalanceScreen_astaghfirullahTheProphetSaid_7625ff =>
      'أستغفر الله — قالها النبي ﷺ 100 مرة في اليوم وهو معصوم. فكم مرة قلتها أنت؟';

  @override
  String get akhirahBalanceScreen_whenYouRememberAllah_60f406 =>
      'إذا ذكرت الله في نفسك، ذكرك في ملأ خير منهم.';

  @override
  String get akhirahBalanceScreen_reciteAyatAlKursi_d0751f =>
      'اقرأ آية الكرسي دبر كل صلاة — ليس بينك وبين الجنة إلا الموت.';

  @override
  String get akhirahBalanceScreen_oneAlhamdulillahFillsThe_4794bb =>
      'الحمد لله تملأ الميزان. وسبحان الله تملأ ما بين السماء والأرض.';

  @override
  String get akhirahBalanceScreen_theRemembranceOfAllah_c99fe8 =>
      '\"ولذكر الله أكبر.\" — سورة العنكبوت 29:45';

  @override
  String get akhirahBalanceScreen_rememberMeWillRemember_1aca04 =>
      '\"فاذكروني أذكركم.\" — سورة البقرة 2:152. فهل ستذكره؟';

  @override
  String get akhirahBalanceScreen_inTheRemembranceOf_20b541 =>
      '\"ألا بذكر الله تطمئن القلوب.\" — سورة الرعد 13:28';

  @override
  String get akhirahBalanceScreen_fiveMinutesOfDhikr_e12766 =>
      'خمس دقائق من الذكر الآن تشكل الـ 24 ساعة القادمة من قلبك.';

  @override
  String get akhirahBalanceScreen_streakIsnAboutToday_9157d8 =>
      'الاستمرارية ليست لليوم — بل لمن ستصبح بعد 30 يوماً.';

  @override
  String get akhirahBalanceScreen_smallDropsFillAn_1accce =>
      'قطرات صغيرة تملأ محيطاً. ذكرك اليومي يملأ شيئاً أعظم بكثير.';

  @override
  String get akhirahBalanceScreen_noOneSeesThe_0182c7 =>
      'لا أحد يرى ذكر قلبك — سوى الملائكة التي تكتب صحيفتك.';

  @override
  String get akhirahBalanceScreen_theBiggestWinsAre_1b8fb6 =>
      'أكبر الانتصارات تُبنى من أصغر العادات اليومية. لا تكسر السلسلة.';

  @override
  String get akhirahBalanceScreen_youCameBackToday_a020b1 =>
      'لقد عدت اليوم. هذه بحد ذاتها عبادة. هل تبقى دقيقة أخرى؟';

  @override
  String get akhirahBalanceScreen_tomorrowPeaceIsBuilt_a72bd8 =>
      'سلام الغد يُبنى بذكر اليوم. ازرع بذرة أخرى.';

  @override
  String get akhirahBalanceScreen_areYouDoneAllah_06ca1d =>
      'هل انتهيت؟ باب الله مفتوح دائماً — حتى بعد أن تغلقه.';

  @override
  String get akhirahBalanceScreen_dhikrIsTheLanguage_b1b983 =>
      'الذكر لغة القلب. فهل تحدث قلبك إلى ربه اليوم؟';

  @override
  String get akhirahBalanceScreen_everySubhanallahIsSadaqah_16b797 =>
      'كل سبحان الله صدقة. فكم صدقة ستقدم قبل نومك؟';

  @override
  String get akhirahBalanceScreen_heartThatForgetsDhikr_3a6173 =>
      'القلب الذي ينسى الذكر يصدأ. والقلب الذاكر يبقى مضيئاً.';

  @override
  String get akhirahBalanceScreen_haveYouFortifiedYourself_17ccac =>
      'هل حصنت نفسك بأذكار الصباح والمساء اليوم؟';

  @override
  String dashboardScreen_sponsor_d48549(String name, String arg1) {
    return 'اكفل $name، $arg1';
  }

  @override
  String dashboardScreen_606140_606140(String arg1, String _lastAyah) {
    return '$arg1 · $_lastAyah';
  }

  @override
  String get dashboardScreen_joinMeOnSabiq_755fb5 =>
      'انضم إلي على Sabiq Rewards، واكسب سيدز لقراءة القرآن والذكر والأعمال الصالحة يومياً!\\n\\n';

  @override
  String dashboardScreen_useMyCodeAnd_7d13b3(String arg1) {
    return 'استخدم كودي *$arg1* وسنحصل كلانا على 500 سابق سيدز!\\n\\n';
  }

  @override
  String get dashboardScreen_messageCopiedShareOr_7b977e =>
      'تم نسخ الرسالة أو مشاركتها أو لصقها في WhatsApp!';

  @override
  String get dashboardScreen_sabiqSeedsRewardedTo_c209d6 =>
      'تم منح 500 سابق سيدز لكليكما!';

  @override
  String get dashboardScreen_youHaveAlreadyUsed_f7c387 =>
      'لقد استخدمت كود دعوة مسبقاً.';

  @override
  String get dashboardScreen_youCannotUseYour_b7dbfe =>
      'لا يمكنك استخدام الكود الخاص بك.';

  @override
  String get dashboardScreen_anErrorOccurredPlease_8ee486 =>
      'حدث خطأ. يرجى المحاولة مرة أخرى.';

  @override
  String dashboardScreen_52b02c_52b02c(String pts) {
    return '$pts ';
  }

  @override
  String dashboardScreen_e4e562_e4e562(String arg1) {
    return '$arg1%';
  }

  @override
  String get dashboardScreen_viewCampaignDonate_450be4 =>
      '🤲 عرض الحملة والتبرع';

  @override
  String dashboardScreen_d13a42_d13a42(
    String _myPoints,
    String unit,
    String arg1,
  ) {
    return '$_myPoints $unit • $arg1';
  }

  @override
  String get dashboardScreen_beTheFirstOn_63de17 => 'كن الأول في لوحة الصدارة';

  @override
  String get dashboardScreen_readAnAyahOr_9c7ab7 =>
      'اقرأ آية أو ذكراً لتحتل المركز الأول';

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
      'ثبت الرسمة بالأعلى بينما يمر النص العربي أسفلها';

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
    return '$arg1  ';
  }

  @override
  String dhikrScreen_a5cfd1_a5cfd1(String count) {
    return '×$count';
  }

  @override
  String get impactReportScreen_whoeverDoesAnAtom_9013b0 =>
      '\"فمن يعمل مثقال ذرة خيراً يره.\"';

  @override
  String get impactReportScreen_theHomeOfThe_4602d2 =>
      '\"وإن الدار الآخرة لهي الحيوان لو كانوا يعلمون\" — سورة العنكبوت 29:64';

  @override
  String get impactReportScreen_raceTowardsForgivenessFrom_94d614 =>
      '\"سابقوا إلى مغفرة من ربكم وجنة عرضها كعرض السماء والأرض\" — سورة الحديد 57:21';

  @override
  String get impactReportScreen_andWhatIsThe_7eec52 =>
      '\"وما الحياة الدنيا إلا متاع الغرور\" — سورة آل عمران 3:185';

  @override
  String get impactReportScreen_indeedWithHardshipComes_ea97fa =>
      '\"إن مع العسر يسراً\" — سورة الشرح 94:6';

  @override
  String get impactReportScreen_singleGoodDeedIn_c126b4 =>
      '\"الحسنة في رمضان تعدل 70 فيما سواه.\" اجمع الحسنات والباب مفتوح.';

  @override
  String get impactReportScreen_theProphetSaidCharity_c154f4 =>
      'قال النبي ﷺ: ما نقصت صدقة من مال — بل تزيده. (مسلم)';

  @override
  String get impactReportScreen_smilingAtYourBrother_8f55e4 =>
      '\"تبسمك في وجه أخيك لك صدقة.\" يمكنك أن تكسب حتى لو كانت جيوبك فارغة. (الترمذي)';

  @override
  String get impactReportScreen_theMostBelovedDeeds_f11906 =>
      '\"أحب الأعمال إلى الله أدومها وإن قل.\" (البخاري)';

  @override
  String get impactReportScreen_inJannahIsWhat_ff6d55 =>
      '\"في الجنة ما لا عين رأت، ولا أذن سمعت، ولا خطر على قلب بشر.\" (البخاري)';

  @override
  String get impactReportScreen_twoRakatsAtFajr_c8b238 =>
      'ركعتا الفجر خير من الدنيا وما فيها. (مسلم)';

  @override
  String get impactReportScreen_everyStepTowardSalah_62962f =>
      'كل خطوة إلى الصلاة تمحو خطيئة وترفع درجة. (مسلم)';

  @override
  String get impactReportScreen_everySeedYouDonate_618d1f =>
      'كل بذرة تتبرع بها تزرع شجرة لشخص آخر';

  @override
  String get impactReportScreen_takeWealthWithYou_784e85 =>
      'لا يمكنك أخذ مالك معك، بل ما جنيته من حسنات به.';

  @override
  String get impactReportScreen_theAngelsRecordNothing_e03c03 =>
      'لا تترك الملائكة شيئاً صغيراً. سبحان الله واحدة قد تزن جبلاً.';

  @override
  String get impactReportScreen_sadaqahIsTomorrow_794857 =>
      'صدقة اليوم هي أجر الغد.';

  @override
  String get impactReportScreen_heartThatGivesIs_4b6000 =>
      'القلب المعطاء هو قلب يملأه الله. لا تتركه فارغاً.';

  @override
  String get impactReportScreen_theReceiptWhatDid_d1c41b =>
      'ها هي صحيفتك. ماذا قدمت لحياتك؟';

  @override
  String get impactReportScreen_imagineYourScaleOn_094d07 =>
      'تخيل ميزانك يوم القيامة. ما الوزن الذي تضيفه اليوم؟';

  @override
  String get impactReportScreen_theWorldIsBorrowed_2eeb50 =>
      'الدنيا مستعارة. والآخرة هي الملك. فاستثمر وفقاً لذلك.';

  @override
  String get impactReportScreen_youBuryTheBody_bb5233 =>
      'أنت تدفن الجسد — لا الأعمال. قدم أعمالك الصالحة ما دمت تستطيع.';

  @override
  String get impactReportScreen_righteousChildWhoPrays_7bcef4 =>
      'ولد صالح يدعو له، أو صدقة جارية، أو علم ينتفع به — ثلاث استثمارات أبدية. (مسلم)';

  @override
  String get impactReportScreen_youWillMeetAllah_c19524 =>
      'ستلقى الله بصحيفتك. اجعل يومك هذا ذا قيمة.';

  @override
  String get impactReportScreen_noDeedIsToo_c04d50 =>
      'لا توجد حسنة صغيرة عند من يحصي الذرات.';

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
      'من جاء بالحسنة فله عشر أمثالها.';

  @override
  String get impactReportScreen_whoeverReadsLetterFrom_36d74f =>
      'من قرأ حرفاً من كتاب الله فله به حسنة، والحسنة بعشر أمثالها.';

  @override
  String get impactReportScreen_twoHadithGrowThis_c8d4a2 =>
      'حديثان ينميان هذا الرقم جنباً إلى جنب:\\n\\n';

  @override
  String impactReportScreen_dhikrRecitedLifetime_669e2a(String arg1) {
    return '  الذكر المقروء (طوال الوقت): $arg1\\n';
  }

  @override
  String impactReportScreen_hasanat_64c7b6(String arg1) {
    return '  → الحسنات: $arg1\\n\\n';
  }

  @override
  String impactReportScreen_ayahsReadLifetime_75eef6(String arg1) {
    return '  الآيات المقروءة (طوال الوقت): $arg1\\n';
  }

  @override
  String impactReportScreen_totalHasanaat_c43112(String arg1) {
    return 'إجمالي الحسنات: $arg1';
  }

  @override
  String get impactReportScreen_whoeverSaysSubhanAllahiWa_4b6459 =>
      'من قال سبحان الله وبحمده في يوم مائة مرة حُطت خطاياه وإن كانت مثل زبد البحر.';

  @override
  String get impactReportScreen_subhanallahiWaBihamdihi_992976 =>
      'سبحان الله وبحمده';

  @override
  String impactReportScreen_totalRecitations_5ed733(String arg1) {
    return 'إجمالي التلاوات: $arg1\\n';
  }

  @override
  String impactReportScreen_dividedByForgivenessCycles_4e175d(String arg1) {
    return 'مقسوم على 100 → دورات استغفار: $arg1';
  }

  @override
  String impactReportScreen_dividedByPalaces_6f066c(String arg1) {
    return 'مقسوم على 10 → قصور: $arg1';
  }

  @override
  String get impactReportScreen_laIlahaIllallahuWahdahu_895dde =>
      'لا إله إلا الله وحده لا شريك له...';

  @override
  String impactReportScreen_setsOfSetsSlaves_b43b31(String arg1, String arg2) {
    return 'مجموعات من 10 → $arg1 مجموعة × 4 رقاب = $arg2';
  }

  @override
  String impactReportScreen_totalSalawatSent_cfe45e(String arg1) {
    return 'إجمالي الصلوات على النبي: $arg1\\n';
  }

  @override
  String impactReportScreen_multipliedByBlessingsReceived_52810f(String arg1) {
    return 'مضروب في 10 → $arg1 بركات تم نيلها';
  }

  @override
  String get impactReportScreen_protectionFromEvil_37b53a => 'الحماية من الشر';

  @override
  String get impactReportScreen_goodHealthProtection_058808 =>
      'الصحة الجيدة والحماية';

  @override
  String impactReportScreen_totalInvocations_1fd02b(String arg1) {
    return 'إجمالي الأدعية: $arg1';
  }

  @override
  String impactReportScreen_dividedByQuranCompletions_b9a013(String arg1) {
    return 'مقسوم على 3 → $arg1 ختمات للقرآن';
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
    return 'منذ $arg1 شهر';
  }

  @override
  String impactReportScreen_moAgo_325a71(String arg1) {
    return 'منذ $arg1 شهر';
  }

  @override
  String impactReportScreen_failed_190558(String e) {
    return 'فشل: $e';
  }

  @override
  String impactReportScreen_funded_add009(String arg1) {
    return 'مُمول بنسبة $arg1%';
  }

  @override
  String get impactReportScreen_yourLifetimeImpact_8bfdcd => 'أثرك طوال الوقت';

  @override
  String get impactReportScreen_startYourImpactJourney_1ae8c4 =>
      'ابدأ رحلة أثرك';

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
    return '+$arg1 سيدز';
  }

  @override
  String get levelScreen_laIlahaIllallah_e8c26b => 'لا إله إلا الله ×100';

  @override
  String levelScreen_seedsBoost_464454(String arg1) {
    return 'مضاعفة سيدز ×$arg1';
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
  String levelScreen_days_100e10(String current, String arg1) {
    return '$current / $arg1 أيام';
  }

  @override
  String levelScreen_dayStreak_df2abf(String arg1) {
    return 'استمرارية $arg1 يوم';
  }

  @override
  String onboardingComponents_355c50_355c50(String first) {
    return '$first ';
  }

  @override
  String onboardingComponents_b236c9_b236c9(String trailing) {
    return ' $trailing';
  }

  @override
  String get quranMini_inTheNameOf_46925d => 'بسم الله الرحمن الرحيم.';

  @override
  String get quranMini_allPraiseBelongsTo_2d51df => 'الحمد لله رب العالمين.';

  @override
  String orphansGridScreen_36cd3b_36cd3b(String arg1, String arg2) {
    return '$arg1 · $arg2';
  }

  @override
  String orphanDetailScreen_years_debb46(String arg1) {
    return '$arg1 سنوات';
  }

  @override
  String orphanDetailScreen_ofSeeds_2a29fc(String arg1, String arg2) {
    return '$arg1 من $arg2 سيدز';
  }

  @override
  String orphanDetailScreen_through_2cdb72(String arg1) {
    return 'بواسطة $arg1';
  }

  @override
  String get orphanDetailScreen_andTheyGiveFood_7ddcff =>
      'ويطعمون الطعام على حبه مسكيناً ويتيماً وأسيراً.';

  @override
  String orphanDetailScreen_ago_71107c(String arg1) {
    return 'منذ $arg1 شهر';
  }

  @override
  String orphanDetailScreen_moAgo_325a71(String arg1) {
    return 'منذ $arg1 شهر';
  }

  @override
  String orphanDetailScreen_seeds_30d8dc(String _availablePoints) {
    return '$_availablePoints سيدز';
  }

  @override
  String orphanDetailScreen_sponsor_b34bcf(String arg1) {
    return 'اكفل $arg1';
  }

  @override
  String orphanDetailScreen_jazakallahKhayranSeedsSponsored_316bec(
    String amount,
  ) {
    return 'جزاك الله خيراً! تمت كفالة $amount سيدز.';
  }

  @override
  String orphanDetailScreen_chooseHowManySeeds_b69aa2(String arg1) {
    return 'اختر كم تريد أن تعطي من الـ سيدز. الحد الأدنى $arg1.';
  }

  @override
  String orphanDetailScreen_yourBalanceSeeds_f8045b(String arg1) {
    return 'رصيدك: $arg1 سيدز';
  }

  @override
  String get profileSettingsScreen_nameCannotBeEmpty_c737ab =>
      'لا يمكن أن يكون الاسم فارغاً';

  @override
  String get profileSettingsScreen_signedInWithGoogle_17e053 =>
      'مسجل بـ Google';

  @override
  String get profileSettingsScreen_signedInWithQuran_2e1ffc =>
      'مسجل بـ Quran.com';

  @override
  String get profileSettingsScreen_signedInWithEmail_dd881f =>
      'مسجل بالبريد الإلكتروني';

  @override
  String profileSettingsScreen_seeds_53d666(String arg1) {
    return '$arg1 سيدز';
  }

  @override
  String get profileSettingsScreen_guidesFAQsAndHow_b990d6 =>
      'أدلة، أسئلة شائعة وطرق الاستخدام';

  @override
  String get profileSettingsScreen_somethingNotWorkingTell_07f659 =>
      'هل تواجه مشكلة؟ أخبرنا';

  @override
  String projectDetailScreen_organisedBy_8b317a(String sponsor) {
    return 'تنظيم $sponsor\\n\\n';
  }

  @override
  String get projectDetailScreen_fundedSoFarEvery_dab3fd =>
      'مُمول حتى الآن، كل سيد يُحدث فرقاً!\\n\\n';

  @override
  String get projectDetailScreen_openSabiqRewardsApp_cdda14 =>
      'افتح تطبيق Sabiq Rewards لتتبرع بـ سيدز وتكسب الأجر.\\n';

  @override
  String get projectDetailScreen_sabiqrewardsSadaqahIslamicCharity_663ba5 =>
      '#SabiqRewards #صدقة #عمل_خيري';

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
      'تبرع لتوفير مساعدات عاجلة ومنقذة لحياة الفلسطينيين الذين يواجهون نقصاً حاداً في الغذاء والمياه والإمدادات الطبية...';

  @override
  String projectDetailScreen_seeds_47387f(String arg1) {
    return '$arg1 سيدز';
  }

  @override
  String projectDetailScreen_e4e562_e4e562(String arg1) {
    return '$arg1%';
  }

  @override
  String projectDetailScreen_ago_71107c(String arg1) {
    return 'منذ $arg1 شهر';
  }

  @override
  String projectDetailScreen_moAgo_325a71(String arg1) {
    return 'منذ $arg1 شهر';
  }

  @override
  String quranHubScreen_saved_9c28a3(String arg1) {
    return 'تم حفظ $arg1';
  }

  @override
  String get quranScreen_couldNotLoadAyah_62f120 =>
      'تعذر تحميل الآية. يرجى المحاولة مرة أخرى.';

  @override
  String get quranScreen_noConnectionCachedData_e5a215 =>
      'لا يوجد اتصال. قد تتوفر بيانات مخبأة.';

  @override
  String quranScreen_ayahs_c98642(String arg1) {
    return '$arg1 آيات';
  }

  @override
  String get quranScreen_couldNotRemoveBookmark_699a82 =>
      'تعذر إزالة الإشارة المرجعية، يرجى المحاولة مرة أخرى';

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
      'تعذر حفظ الإشارة المرجعية، يرجى المحاولة مرة أخرى';

  @override
  String quranScreen_bookmarked_2c6203(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'تم حفظ $_surahName $_surah:$_ayah';
  }

  @override
  String quranScreen_tafsir_391c0d(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'تفسير · $_surahName $_surah:$_ayah';
  }

  @override
  String get quranScreen_addedToFavourites_b3cce0 => '♥️ أُضيف إلى المفضلة';

  @override
  String quranScreen_pt_9e58e8(String arg1) {
    return '$arg1 نقطة';
  }

  @override
  String quranScreen_003843_003843(String arg1, String arg2) {
    return '$arg1  $arg2';
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
    return '$arg1 ';
  }

  @override
  String quranScreen_ayahsRead_862866(String _ayahsToday) {
    return 'قُرأت $_ayahsToday آية';
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
  String get startJourneyScreen_unexpectedErrorDuringGoogle_86c1a5 =>
      'خطأ غير متوقع أثناء تسجيل الدخول بـ Google';

  @override
  String get startJourneyScreen_connectedToQuranCom_c0c631 =>
      'متصل بـ Quran.com';

  @override
  String tafsirScreen_verses_fed624(String arg1) {
    return '$arg1 آيات';
  }

  @override
  String tafsirScreen_ayahOf_63c42b(String _ayah, String _surahLen) {
    return 'الآية $_ayah من $_surahLen';
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
      'يجب تسجيل الدخول للتبرع.';

  @override
  String get donationService_donationCouldNotBe_074195 =>
      'تعذر معالجة التبرع في الوقت الحالي.';

  @override
  String get donationService_anUnexpectedNetworkError_914b7a =>
      'حدث خطأ غير متوقع في الشبكة.';

  @override
  String get donationService_sponsorshipReceived_671201 =>
      'تم استلام الكفالة 💝';

  @override
  String donationService_youSponsoredSeedsJazak_7711e1(String amount) {
    return 'لقد كفلت بـ $amount سيدز · جزاك الله خيراً.';
  }

  @override
  String get donationService_sponsorshipCouldNotBe_55003e =>
      'تعذر معالجة الكفالة في الوقت الحالي.';

  @override
  String get streakService_warmingUp_b1687b => 'إحماء';

  @override
  String get streakService_oneWeek_4f98dc => 'أسبوع واحد';

  @override
  String get streakService_twoWeeks_9a2d93 => 'أسبوعان';

  @override
  String get streakService_oneMonth_35eb01 => 'شهر واحد';

  @override
  String get streakService_twoMonths_84d275 => 'شهران';

  @override
  String get streakService_theCenturion_f1de7f => 'المئوية';

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
  String get xpService_dailyLoginBonus_d011fa => 'منحة الدخول اليومي';

  @override
  String xpService_seedsWelcomeBack_47888a(String arg1) {
    return '+$arg1 سيدز · أهلاً بعودتك!';
  }

  @override
  String get xpService_daySealed_037a56 => 'اكتمل اليوم 🌙';

  @override
  String xpService_sabiqSeedsConfirmedBonus_702902(
    String flushed,
    String bonus,
  ) {
    return 'تم تأكيد +$flushed سابق سيدز! (منحة $bonus للحفظ)';
  }

  @override
  String xpService_sabiqSeedsConfirmed_34969c(String flushed) {
    return 'تم تأكيد +$flushed سابق سيدز!';
  }

  @override
  String get dhikrExitCelebration_everyBreathCounts_45b3df =>
      'كل نفس له قيمته.';

  @override
  String get impactAnimation_yourRewardHasBeen_e3d106 => 'تم تسجيل أجرك.';

  @override
  String get motivationalPopup_verilyWithHardshipComes_f23637 =>
      'إن مع العسر يسراً.\\nكل محنة هي باب لشيء أعظم.';

  @override
  String get motivationalPopup_quranAlInshirah_d81f8a => 'القرآن • الشرح 94:6';

  @override
  String get motivationalPopup_quranAlAnkabut_8e938e =>
      'القرآن • العنكبوت 29:45';

  @override
  String get motivationalPopup_quranAlBaqarah_8bb10e => 'القرآن • البقرة 2:152';

  @override
  String get motivationalPopup_quranAnNahl_74d608 => 'القرآن • النحل 16:18';

  @override
  String get motivationalPopup_makeYourTimePrecious_049aae =>
      'اجعل وقتك ثميناً.\\nشارك الخير مع صديق اليوم،\\nفكل معروف صدقة.';

  @override
  String get motivationalPopup_guideOthersToGood_6105c4 =>
      'الدال على الخير كفاعله.';

  @override
  String get motivationalPopup_theBestOfPeople_1f6906 =>
      'خير الناس أنفعهم للناس.';

  @override
  String get motivationalPopup_verilyInTheRemembrance_16476d =>
      'ألا بذكر الله\\nتطمئن القلوب.';

  @override
  String get motivationalPopup_remindYourselfTimeIs_38ae33 =>
      'ذكّر نفسك، الوقت هو أثمن صدقة.';

  @override
  String get motivationalPopup_yourTimeIsYour_be6731 =>
      'وقتك هو أثمن\\nما تملك. فاستثمره بحكمة\\nفيما يبقى للأبد.';

  @override
  String get motivationalPopup_quranAlAnfal_b10486 => 'القرآن • الأنفال 8:28';

  @override
  String get motivationalPopup_takeAdvantageOfFive_e573fd =>
      'اغتنم خمساً قبل خمس.';

  @override
  String motivationalPopup_seeds_3a9c69(String arg1) {
    return '+$arg1 سيدز';
  }

  @override
  String get motivationalPopup_completeNowEarnSeeds_16ea6e =>
      'أكمل الآن → اكسب +50 سيدز كمنحة';

  @override
  String get motivationalPopup_finishYourAzkaarEarn_e264fa =>
      'أنهِ أذكارك → اكسب +30 سيدز كمنحة';

  @override
  String get motivationalPopup_shareSabiqWithSomeone_c60dcc =>
      'شارك سابق مع شخص ما → اكسب +100 سيدز';

  @override
  String get motivationalPopup_keepYourSpiritualMomentum_0f172c =>
      'حافظ على نشاطك الروحي\\nوشاهد الـ سيدز الخاصة بك تنمو ✨';

  @override
  String get projectMediaCarousel_couldNotLoadVideo_deb8dd =>
      'تعذر تحميل الفيديو';

  @override
  String get quranExitCelebration_beautifulRecitation_9d2655 => 'تلاوة خاشعة.';

  @override
  String get quranExitCelebration_everyMomentCounts_fddb4c =>
      'كل لحظة لها قيمتها.';

  @override
  String sealCoinAnimation_e16fa4_e16fa4(String arg1) {
    return '+$arg1 ';
  }

  @override
  String impactReportScreen_totalHasanatFromQuran(String n) {
    return 'إجمالي حسنات القرآن: $n';
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
    return 'مضروب في 8 أبواب → $n مرات فُتحت';
  }

  @override
  String impactReportScreen_bonusHasanaat(String n) {
    return 'حسنات إضافية: $n';
  }

  @override
  String impactReportScreen_totalDonatedSeeds(String n, String seeds) {
    return 'إجمالي التبرعات: $n سيدز';
  }

  @override
  String get dashboardScreen_dashboardLoadFailed =>
      'تعذر تحميل لوحة المعلومات الخاصة بك. يرجى المحاولة مرة أخرى.';

  @override
  String get zikrLabel => 'الذكر';

  @override
  String get quranLabel => 'القرآن';

  @override
  String streakService_dayStreakBody(String days, String type, String bonus) {
    return 'استمرارية $type لمدة $days أيام · فتحت +$bonus سيدز منحة';
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
  String get donationService_donationReceivedTitle => 'تم استلام التبرع 💝';

  @override
  String donationService_youDonatedSeeds(String amount) {
    return 'لقد تبرعت بـ $amount سيدز · جزاك الله خيراً.';
  }

  @override
  String streakService_60a570_60a570(Object arg1, Object localLabel) {
    return '$arg1 $localLabel';
  }

  @override
  String xpService_badgeEarnedBody(String name) {
    return 'لقد ربحت شارة \"$name\".';
  }

  @override
  String get localReminderScheduler_channelName => 'إشعارات Sabiq Rewards';

  @override
  String get localReminderScheduler_morningTitle => 'أذكار الصباح';

  @override
  String get localReminderScheduler_morningBody =>
      'ابدأ يومك بحفظ الله — اقرأ أذكار الصباح.';

  @override
  String get localReminderScheduler_astaghfirTitle => 'لحظة للاستغفار';

  @override
  String get localReminderScheduler_astaghfirBody =>
      '\"أستغفر الله\" تجلو القلب وتفتح أبواب الرزق. توقف لدقيقة.';

  @override
  String get localReminderScheduler_eveningTitle => 'أذكار المساء';

  @override
  String get localReminderScheduler_eveningBody =>
      'حصن نفسك لليلة — اقرأ أذكار المساء.';

  @override
  String get localReminderScheduler_sleepTitle => 'وقت الراحة';

  @override
  String get localReminderScheduler_sleepBody =>
      'أنهِ يومك بأذكار النوم — آية الكرسي، المعوذات، وأدعية النوم.';

  @override
  String get localReminderScheduler_kahfAmTitle =>
      'إنه يوم الجمعة — اقرأ سورة الكهف';

  @override
  String get localReminderScheduler_kahfBody =>
      'من قرأ سورة الكهف يوم الجمعة، أضاء له من النور ما بين الجمعتين.';

  @override
  String get localReminderScheduler_salawatTitle =>
      'الصلاة على النبي يوم الجمعة';

  @override
  String get localReminderScheduler_salawatBody =>
      'أكثر من الصلاة على النبي ﷺ اليوم — تُعرض عليه أعمال يوم الجمعة.';

  @override
  String get localReminderScheduler_kahfPmTitle => 'لا تفوت سورة الكهف اليوم';

  @override
  String get localReminderScheduler_kahfPmBody =>
      'ساعات قليلة للمغرب — أنهِ سورة الكهف إن لم تفعل بعد.';

  @override
  String get liveNotificationService_validateChannelDesc =>
      'تذكيرات لحفظ الـ سيدز المعلقة قبل منتصف الليل.';

  @override
  String get liveNotificationService_validateTicker =>
      'احفظ الـ سيدز قبل منتصف الليل';

  @override
  String get liveNotificationService_validateTitle =>
      'احفظ الـ سيدز قبل منتصف الليل!';

  @override
  String liveNotificationService_validateBody(String n) {
    return 'لديك $n سيدز معلقة. انقر لحفظ اليوم قبل منتصف الليل وإلا ستنتهي صلاحيتها.';
  }

  @override
  String liveNotificationService_ayatRead(String n) {
    return 'قُرأت $n آيات اليوم 📖';
  }

  @override
  String liveNotificationService_readQuranTime(String time) {
    return '$time قضيتها في قراءة القرآن اليوم ⏱️';
  }

  @override
  String get liveNotificationService_nothingRead =>
      'لم يُقرأ شيء من القرآن اليوم 📖';

  @override
  String liveNotificationService_dhikrCompleted(String n) {
    return 'اكتمل $n ذكر اليوم 📿';
  }

  @override
  String liveNotificationService_tickerBusy(String ayah, String dhikr) {
    return '$ayah آيات · $dhikr أذكار اليوم';
  }

  @override
  String get liveNotificationService_tickerIdle => 'استمر في القراءة والذكر!';

  @override
  String get liveNotificationService_channelDesc =>
      'متابعة مباشرة لتقدم القرآن والذكر اليوم';

  @override
  String get liveNotificationService_seedsToday => 'رصيد الـ سيدز اليوم ✨';

  @override
  String get liveNotificationService_summary => 'انقر لفتح سابق';

  @override
  String get quranApiService_notConnected => 'غير متصل بـ Quran.com';

  @override
  String get quranApiService_notSignedIn => 'لم تقم بتسجيل الدخول إلى نور';

  @override
  String quranApiService_syncFailedPush(String n) {
    return 'فشلت المزامنة، تعذر رفع $n إشارة إلى Quran.com (تحقق من الرمز / الرابط).';
  }

  @override
  String get quranApiService_alreadyInSync =>
      'الإشارات المرجعية متزامنة بالفعل';

  @override
  String quranApiService_syncedBookmarks(String total, String up, String down) {
    return 'تمت مزامنة $total إشارة ($up رُفعت، $down حُملت)';
  }

  @override
  String quranApiService_syncFailedPartial(String n) {
    return '، فشلت مزامنة $n';
  }

  @override
  String quranApiService_syncFailedGeneric(String error) {
    return 'فشلت المزامنة: $error';
  }

  @override
  String get authScreen_dontHaveAnAccountSignUp => 'ليس لديك حساب؟ سجل الآن';

  @override
  String get dhikrExitCelebration_keepItUp => 'استمر على هذا المنوال!';

  @override
  String get unknownError => 'خطأ غير معروف';

  @override
  String get celebrationStatSeeds => 'سيدز';

  @override
  String get celebrationStatSeedsEarned => 'سيدز المكتسبة';

  @override
  String get celebrationStatAyahs => 'الآيات';

  @override
  String get celebrationStatTime => 'الوقت';

  @override
  String get celebrationStatStreak => 'الاستمرارية';

  @override
  String get celebrationStreakStartToday => 'ابدأ اليوم';

  @override
  String celebrationDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أيام',
      one: 'يوم 1',
    );
    return '$_temp0';
  }

  @override
  String get orphanGirl => 'بنت';

  @override
  String get orphanBoy => 'ولد';

  @override
  String orphanSiblings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إخوة وأخوات',
      one: 'أخ أو أخت واحدة',
    );
    return '$_temp0';
  }

  @override
  String get profileSelectCountry => 'اختر الدولة';
}
