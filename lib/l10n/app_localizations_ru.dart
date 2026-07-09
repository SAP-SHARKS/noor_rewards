// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get youSuffix => '(вы)';

  @override
  String get userFallback => 'Пользователь';

  @override
  String get youHaveDone => 'Вы выполнили!';

  @override
  String get playAllBtn => 'Воспроизвести всё';

  @override
  String get playBtn => 'Воспроизвести';

  @override
  String get readBtn => 'Читать';

  @override
  String get readOnce => 'Прочитать один раз';

  @override
  String readNTimes(int count) {
    return 'Прочитать $count раз';
  }

  @override
  String seedsEarnedToday(int count) {
    return 'Получено +$count Сабик Сидс сегодня!';
  }

  @override
  String get catDailyRemembrance => 'ЕЖЕДНЕВНЫЙ ЗИКР';

  @override
  String get catNightlyRemembrance => 'НОЧНОЙ ЗИКР';

  @override
  String get catYourSelection => 'ВАШ ВЫБОР';

  @override
  String get catContinuousRemembrance => 'ПОСТОЯННЫЙ ЗИКР';

  @override
  String get bannerDailyRemembrance => 'Ежедневный зикр\nприносит душе покой.';

  @override
  String get bannerMorningAdhkar => 'Утренний зикр\nприносит покой и свет.';

  @override
  String get bannerEveningAdhkar =>
      'Вечерний зикр\nприносит спокойствие и защиту.';

  @override
  String get bannerYourSelection =>
      'Ваши любимые слова зикра,\nчтобы держать их близко к сердцу.';

  @override
  String get bannerContinuousRemembrance =>
      'Поминайте Аллаха\nчасто, чтобы преуспеть.';

  @override
  String get frequentlyReadByCommunity => 'Часто читают';

  @override
  String get viewFullLeaderboard => 'Смотреть полный рейтинг';

  @override
  String get skip => 'Пропустить';

  @override
  String get continue_ => 'Продолжить';

  @override
  String get beginYourJourney => 'Начните свой путь';

  @override
  String get enterTheGarden => 'Войти в Сад';

  @override
  String get bySigningUp => 'Регистрируясь, вы соглашаетесь с Политикой';

  @override
  String get lightOfMercy => 'СВЕТ МИЛОСТИ';

  @override
  String get noorRewards => 'Sabiq Rewards';

  @override
  String get startYourJourney => 'Начните свой путь';

  @override
  String get trackSpiritualGrowth =>
      'Следите за своим духовным ростом, присоединяйтесь к общине и получайте награды.';

  @override
  String get continueWithGoogle => 'Продолжить с Google';

  @override
  String get continueWithQuran => 'Продолжить с Quran.com';

  @override
  String get onboarding1Title => 'Мир\nВам';

  @override
  String get onboarding1Subtitle =>
      'Добро пожаловать в Sabiq Rewards, где каждое доброе дело приближает вас к милости Аллаха.';

  @override
  String get onboarding2Title => 'Две награды.\nОдно действие.';

  @override
  String get onboarding2Subtitle =>
      'Каждое прочитанное слово приносит вам Саваб. Ваши Сабик Сидс финансируют реальные проекты.';

  @override
  String get onboarding3Title => 'Поминайте\nАллаха';

  @override
  String get onboarding3Subtitle =>
      'Сердце, поминающее Аллаха, находит покой. Отслеживайте свой ежедневный зикр.';

  @override
  String get onboarding4Title => 'Размышляйте\nкаждый день';

  @override
  String get onboarding4Subtitle =>
      'Коран — это руководство. Откройте для себя аяты, дуа и размышления для вашего пути.';

  @override
  String get onboarding5Title => 'Отдавайте\nи получайте';

  @override
  String get onboarding5Subtitle =>
      'Садака гасит грехи, как вода гасит огонь. Получайте награду за каждое доброе дело.';

  @override
  String welcomeUser(String name) {
    return 'Добро пожаловать, $name 🌙';
  }

  @override
  String get gatesOfNoor =>
      'Врата света открыты.\nВаш духовный путь начинается сегодня.';

  @override
  String get earnNoorPoints => 'ПОЛУЧИТЬ Сабик Сидс';

  @override
  String get yourProgress => 'ВАШ ПРОГРЕСС';

  @override
  String get yourTotalNoorPoints => 'ВСЕГО Сабик Сидс';

  @override
  String get achievements => 'Достижения';

  @override
  String get today => 'Сегодня';

  @override
  String get thisWeek => 'На этой неделе';

  @override
  String get thisMonth => 'В этом месяце';

  @override
  String get streaks => 'СЕРИИ';

  @override
  String get noorPoints => 'Сабик Сидс';

  @override
  String get readQuran => 'Читать Коран';

  @override
  String get inviteFriends => 'Пригласить друзей';

  @override
  String get communityImpact => 'Влияние на общину';

  @override
  String get completedProjects => 'Завершенные проекты';

  @override
  String get yourContribution => 'Ваш вклад';

  @override
  String get yourReferralCode => 'ВАШ РЕФЕРАЛЬНЫЙ КОД';

  @override
  String get copyLink => 'Копировать ссылку';

  @override
  String get shareVia => 'ПОДЕЛИТЬСЯ ЧЕРЕЗ';

  @override
  String get friendGets => 'Друг получает';

  @override
  String get youGet => 'Вы получаете';

  @override
  String get goal => 'Цель';

  @override
  String get needed => 'Нужно';

  @override
  String get instant => 'Мгновенно';

  @override
  String get viewCampaign => 'Смотреть кампанию';

  @override
  String get close => 'Закрыть';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get loading => 'Загрузка...';

  @override
  String get error => 'Ошибка';

  @override
  String get retry => 'Повторить';

  @override
  String get signOut => 'Выйти';

  @override
  String get profile => 'Профиль';

  @override
  String get settings => 'Настройки';

  @override
  String get level => 'Уровень';

  @override
  String get rank => 'Ранг';

  @override
  String get dailyDhikr => 'Ежедневный зикр';

  @override
  String get morning => 'Утро';

  @override
  String get evening => 'Вечер';

  @override
  String get completed => 'Завершено';

  @override
  String get shareMore => 'Поделиться еще';

  @override
  String get noData => 'Пока нет данных';

  @override
  String get callYou => 'Как к вам\nобращаться?';

  @override
  String get personaliseJourney => 'Настройте свой духовный путь, указав имя';

  @override
  String get whereFrom => 'Откуда\nвы?';

  @override
  String get joinMuslims => 'Присоединяйтесь к мусульманам со всего мира';

  @override
  String get whatBringsYou => 'Что привело\nвас сюда?';

  @override
  String get chooseGoals => 'Выберите духовные цели (можно несколько)';

  @override
  String get navHome => 'Главная';

  @override
  String get navJourney => 'Путь';

  @override
  String get navAkhirah => 'Ахират';

  @override
  String get navProfile => 'Профиль';

  @override
  String get communityLeaderboard => 'Рейтинг общины';

  @override
  String get topContributors => 'Топ спонсоров по Сидс за все время';

  @override
  String get myProfile => 'Мой профиль';

  @override
  String get startStreak => 'Начните серию сегодня!';

  @override
  String get alreadySealed => 'Уже выполнено сегодня';

  @override
  String get sealTheDay => 'Завершить день';

  @override
  String get alhamdulillah => 'Альхамдулиллях!';

  @override
  String get levelSeeker => 'Ищущий';

  @override
  String get levelBeliever => 'Верующий';

  @override
  String get levelDevoted => 'Преданный';

  @override
  String get levelChampion => 'Чемпион';

  @override
  String get levelLegend => 'Легенда';

  @override
  String get next => 'Далее';

  @override
  String get day => 'день';

  @override
  String get days => 'дней';

  @override
  String get quran => 'Коран';

  @override
  String get zikr => 'Зикр';

  @override
  String get dailyLogin => 'Ежедневный вход';

  @override
  String get todaysProgress => 'Прогресс сегодня';

  @override
  String get versesToday => 'аятов сегодня';

  @override
  String get resumeReading => 'Продолжить чтение';

  @override
  String get continueReading => 'Продолжить чтение';

  @override
  String get chooseWhereToStart => 'Выберите, откуда начать';

  @override
  String get startReadingFrom => 'Начать чтение с';

  @override
  String get yourLibrary => 'Ваша библиотека';

  @override
  String get browse => 'Просмотр';

  @override
  String get listen => 'Слушать';

  @override
  String get tafsir => 'Тафсир';

  @override
  String get wordByWord => 'Слово за словом';

  @override
  String get mushaf => 'Мусхаф';

  @override
  String get otherCategories => 'Другие категории';

  @override
  String get noCategoriesAvailable => 'Нет доступных категорий';

  @override
  String get nextPts => 'Далее';

  @override
  String get prev => 'Пред';

  @override
  String get reciteMore => 'ЧИТАЙТЕ БОЛЬШЕ.';

  @override
  String get helpRealLives => 'ПОМОГАЙТЕ РЕАЛЬНЫМ ЖИЗНЯМ.';

  @override
  String get yourNoorPointsFundProjects =>
      'Ваши Сабик Сидс финансируют эти проекты';

  @override
  String get youBothEarnPoints => 'Вы оба получаете по 500 Сабик Сидс!';

  @override
  String get reward => 'Награда';

  @override
  String get haveInviteCode => 'Есть код приглашения?';

  @override
  String get enterCode => 'Введите код…';

  @override
  String get apply => 'Применить';

  @override
  String get plantGoodDeeds => 'ПОСАДИТЬ ДОБРОЕ ДЕЛО';

  @override
  String get youDonated => 'Вы пожертвовали';

  @override
  String get seeDetailsForMore => 'Детали о других проектах →';

  @override
  String get pts => 'Сидс';

  @override
  String get funded => 'профинансировано';

  @override
  String bySponsor(String sponsor) {
    return 'От: $sponsor';
  }

  @override
  String get viewCampaignDonate => 'Смотреть кампанию и пожертвовать';

  @override
  String get supportThisCause => 'Поддержать кампанию';

  @override
  String get availableBalance => 'Доступный баланс:';

  @override
  String get donationAmount => 'Сумма пожертвования';

  @override
  String get points => 'Сидс';

  @override
  String get donateEarnReward => 'Пожертвуйте и получите награду';

  @override
  String get max => 'МАКС';

  @override
  String get leaderboard => 'Рейтинг';

  @override
  String get loadingDots => 'Загрузка…';

  @override
  String yourRank(String rank) {
    return 'Ваш ранг: #$rank';
  }

  @override
  String get outOf => 'Из';

  @override
  String get believers => 'верующие';

  @override
  String get topTenContributors => 'Топ-10 спонсоров';

  @override
  String get ourCauses => 'Наши кампании';

  @override
  String get donatePointsToSupport =>
      'Жертвуйте свои Сабик Сидс на поддержку реальных проектов';

  @override
  String get noActiveProjects => 'Сейчас нет активных проектов';

  @override
  String get checkBackSoon => 'Загляните позже, иншаАллах';

  @override
  String get messageCopied =>
      'Сообщение скопировано, отправьте его в WhatsApp!';

  @override
  String get lvl => 'Ур';

  @override
  String get journey => 'Путешествие';

  @override
  String get tabStreaks => 'Серии';

  @override
  String get tabProgress => 'Прогресс';

  @override
  String get tabBadges => 'Значки';

  @override
  String get tabChallenges => 'Испытания';

  @override
  String get allTime => 'За все время';

  @override
  String ptsToLevel(String pts, String level) {
    return '$pts Сидс до уровня $level';
  }

  @override
  String dayStreak(String count) {
    return 'Серия $count дн.';
  }

  @override
  String get actions => 'действий';

  @override
  String get action => 'действие';

  @override
  String get breakdown => 'Детали';

  @override
  String get activityLog => 'Журнал активности';

  @override
  String get showLess => 'Показать меньше';

  @override
  String get seeMore => 'Показать больше';

  @override
  String get more => 'еще';

  @override
  String noActivity(String period) {
    return 'Нет активности $period';
  }

  @override
  String get startEarningPts => 'Начните получать Сидс, читая Коран и зикр.';

  @override
  String get howToEarnPts => 'Как получить Сидс';

  @override
  String get readOneAyah => 'Прочитать 1 аят';

  @override
  String get completeOneJuz => 'Завершить 1 Джуз';

  @override
  String get validateAndSupport => 'Подтвердить и поддержать';

  @override
  String get levelTiers => 'Ступени уровня';

  @override
  String get basicFeatures => 'Базовые функции';

  @override
  String get customProfileThemes => 'Свои темы профиля';

  @override
  String get leaderboardBadge => 'Значок в рейтинге';

  @override
  String get exclusiveVotingRights => 'Эксклюзивные права голоса';

  @override
  String get hallOfFameListing => 'Список в Зале Славы';

  @override
  String unlocks(String feature) {
    return 'Открывает: $feature';
  }

  @override
  String get now => 'СЕЙЧАС';

  @override
  String get trophyVault => 'Зал трофеев';

  @override
  String badgesCollected(String earned, String total) {
    return 'Собрано значков: $earned / $total';
  }

  @override
  String percentComplete(String pct) {
    return 'Завершено: $pct%';
  }

  @override
  String toUnlock(String count) {
    return 'осталось $count';
  }

  @override
  String get earned => 'ПОЛУЧЕНО';

  @override
  String get locked => 'ЗАКРЫТО';

  @override
  String get seasonalEvents => 'Сезонные события';

  @override
  String get weeklyChallenges => 'Еженедельные испытания';

  @override
  String get specialEvents => 'Специальные события';

  @override
  String get noActiveChallenges => 'Сейчас нет активных испытаний';

  @override
  String get checkBackChallenges =>
      'Скоро появятся события Рамадана и Зуль-хиджа!';

  @override
  String get ramadanChallenge => 'Испытание Рамадана';

  @override
  String get ramadanChallengeDesc =>
      'Множитель Сидс 3× • Особые значки • Цель: колодцы от общины';

  @override
  String get comingSoonStayConsistent => 'Скоро появится, будьте постоянны!';

  @override
  String get done => 'Готово!';

  @override
  String ptsBoost(String multiplier) {
    return 'Буст Сидс $multiplier×';
  }

  @override
  String ends(String date) {
    return 'Заканчивается $date';
  }

  @override
  String get loadingStreaks => 'Загрузка серий…';

  @override
  String get centurion => 'Сотник, МашаАллах!';

  @override
  String get currentBestStreak => 'Текущая лучшая серия';

  @override
  String get last7Days => 'ПОСЛЕДНИЕ 7 ДНЕЙ';

  @override
  String get nextMilestone => 'СЛЕД. ЭТАП';

  @override
  String get allMilestones => 'ВСЕ ЭТАПЫ';

  @override
  String moreDaysToGo(String count) {
    return 'Осталось $count дней, так держать!';
  }

  @override
  String dayStreakLabel(String count) {
    return 'Серия $count дн.';
  }

  @override
  String best(String count) {
    return 'Лучшие $count';
  }

  @override
  String get dhikarAndDua => 'Зикр и Дуа';

  @override
  String get listenTafsir => 'Слушать Тафсир';

  @override
  String get challenge => 'Испытание';

  @override
  String get readListenTafsir => 'Слушать и читать тафсир';

  @override
  String get deepUnderstanding => 'Глубокое понимание Священного Корана';

  @override
  String get earnPointsTafsir =>
      'Получайте Сидс за каждые 10 мин прослушивания Тафсира';

  @override
  String get featuredSurahs => 'Избранные суры';

  @override
  String get browseAll114 => 'Посмотреть все 114 сур';

  @override
  String verses(String count) {
    return '$count аятов';
  }

  @override
  String ayahN(String n) {
    return 'Аят $n';
  }

  @override
  String get readTafsir => 'Читать Тафсир';

  @override
  String get translation => 'Перевод';

  @override
  String get loadingTafsir => 'Загрузка тафсира...';

  @override
  String get tafsirNotAvailable => 'Для этого аята тафсир недоступен.';

  @override
  String get arabicScripture => 'Арабский текст';

  @override
  String get urduScripture => 'Урду (шрифт)';

  @override
  String get englishCommentary => 'Английский тафсир';

  @override
  String get previous => 'Предыдущая';

  @override
  String get nextAyah => 'След. аят';

  @override
  String get readingSettings => 'Настройки чтения';

  @override
  String get tafsirSource => 'ИСТОЧНИК ТАФСИРА';

  @override
  String get reciter => 'ЧТЕЦ';

  @override
  String get display => 'ОТОБРАЖЕНИЕ';

  @override
  String get showArabicText => 'Показывать арабский текст';

  @override
  String get darkMode => 'Темная тема';

  @override
  String get fontSize => 'РАЗМЕР ШРИФТА';

  @override
  String get arabic => 'Арабский';

  @override
  String get urdu => 'Урду';

  @override
  String get english => 'Английский';

  @override
  String get selectSurah => 'Выберите суру';

  @override
  String get audioNotLoaded =>
      'Аудио еще не загружено. Пожалуйста, подождите...';

  @override
  String playbackError(String message) {
    return 'Ошибка воспроизведения: $message';
  }

  @override
  String get audioUnavailable => 'Аудио недоступно, проверьте интернет.';

  @override
  String get signInToSaveFavourites => 'Войдите, чтобы сохранять закладки';

  @override
  String get addedToFavourites => 'Добавлено в избранное';

  @override
  String get removedFromFavourites => 'Удалено из избранного';

  @override
  String get appearance => 'ВНЕШНИЙ ВИД';

  @override
  String get appearanceLabel => 'Внешний вид';

  @override
  String get freezeIllustration => 'Остановить анимацию';

  @override
  String get comfortableNightReading => 'Комфортное ночное чтение';

  @override
  String get focusMode => 'Режим фокуса (На весь экран)';

  @override
  String get focusModeDesc => 'Скрыть панель приложения и навигацию';

  @override
  String get textSize => 'Размер текста';

  @override
  String get small => 'Мелкий';

  @override
  String get large => 'Крупный';

  @override
  String get themeColour => 'Цвет темы';

  @override
  String get quranScript => 'ШРИФТ КОРАНА';

  @override
  String get quranScriptLabel => 'Шрифт Корана';

  @override
  String get readingLayout => 'ОТОБРАЖЕНИЕ ПРИ ЧТЕНИИ';

  @override
  String get showTranslation => 'Показывать перевод';

  @override
  String get displayMeaningBelow => 'Показывать перевод под каждым аятом';

  @override
  String get showDailyProgress => 'Показывать дневной прогресс';

  @override
  String get progressBarAyahCount => 'Прогресс-бар и счетчик аятов';

  @override
  String get showPointsBanner => 'Показывать баннер с Сидс';

  @override
  String get noorPointsNotificationStrip => 'Лента уведомлений +Сабик Сидс';

  @override
  String get showSurahHeader => 'Показывать заголовок суры';

  @override
  String get surahNameBanner => 'Баннер с названием суры сверху';

  @override
  String get audioPlayback => 'АУДИО И ВОСПРОИЗВЕДЕНИЕ';

  @override
  String get autoAdvance => 'Автопрокрутка';

  @override
  String get moveToNextVerse => 'Перейти к следующему аяту по окончании аудио';

  @override
  String get repeatCurrentVerse => 'Повторять текущий аят';

  @override
  String get loopAyahAudio => 'Повторять аудио этого аята';

  @override
  String get notificationsAlerts => 'УВЕДОМЛЕНИЯ И ОПОВЕЩЕНИЯ';

  @override
  String get dailyReadingReminder => 'Напоминание о чтении';

  @override
  String get pushReminderReadQuran =>
      'Push-напоминание читать Коран каждый день';

  @override
  String get milestoneSoundAlerts => 'Звуковые уведомления этапов';

  @override
  String get chimeAtMilestones => 'Звук при достижении 10, 25, 50 аятов';

  @override
  String get advanced => 'ПРОДВИНУТЫЕ';

  @override
  String get wordByWordMode => 'Режим «Слово за словом»';

  @override
  String get showWordMeaning => 'Показывать перевод под каждым арабским словом';

  @override
  String get translationLanguage => 'Язык перевода';

  @override
  String translationsAvailable(String count) {
    return 'Доступно переводов: $count';
  }

  @override
  String get reciterLabel => 'Чтец:';

  @override
  String get playing => 'Воспроизведение';

  @override
  String get favourite => 'Избранное';

  @override
  String get bookmark => 'Закладка';

  @override
  String ayahsRead(String count) {
    return 'Прочитано аятов: $count';
  }

  @override
  String get goalAyahs => 'Цель: 50 аятов/день';

  @override
  String get nextPage => 'След. страница';

  @override
  String get exit => 'Выход';

  @override
  String get mushafSettings => 'Настройки Мусхафа';

  @override
  String get readingMode => 'РЕЖИМ ЧТЕНИЯ';

  @override
  String get scroll => 'Прокрутка';

  @override
  String get pageFlip => 'Листание';

  @override
  String get translationLabel => 'ПЕРЕВОД';

  @override
  String get off => 'Выкл.';

  @override
  String get splitView => 'Две колонки';

  @override
  String get script => 'ШРИФТ';

  @override
  String get actionsLabel => 'ДЕЙСТВИЯ';

  @override
  String get pageBookmarked => 'Страница в закладках!';

  @override
  String get loadingQuran => 'Загрузка Корана…';

  @override
  String get earnPointsPerVerse =>
      'Получите +10 Сабик Сидс за каждый прочитанный аят';

  @override
  String get chooseSurah => 'Выберите суру';

  @override
  String get chooseVerse => 'Выберите аят';

  @override
  String surahHasVerses(String surah, String count) {
    return 'В суре $surah $count аятов';
  }

  @override
  String get favourites => 'Избранное';

  @override
  String get bookmarks => 'Закладки';

  @override
  String saved(String count) {
    return 'Сохранено: $count';
  }

  @override
  String noSavedYet(String title) {
    return 'Пока нет сохраненных $title';
  }

  @override
  String get tapToSaveVerses =>
      'Нажмите на сердечко/закладку при чтении, чтобы сохранить аят.';

  @override
  String get randomVerse => 'Случайный аят';

  @override
  String get sunnahFriday => 'Сунна пятницы';

  @override
  String get resume => 'Продолжить';

  @override
  String get loadingWordTranslations => 'Загрузка переводов слов…';

  @override
  String get wordDataUnavailable =>
      'Данные слова недоступны. Проверьте подключение.';

  @override
  String get duaAzkarSettings => 'Настройки Дуа и Азкар';

  @override
  String get showTransliteration => 'Показывать транслитерацию';

  @override
  String get showIllustration => 'Показать иллюстрацию';

  @override
  String get hideIllustrationArea => 'Скрыть область с иллюстрациями';

  @override
  String get arabicFontStyle => 'Стиль арабского шрифта';

  @override
  String get dailyAzkarComplete => 'Ежедневный зикр завершен!';

  @override
  String get dailyAzkarBonusMsg =>
      'МашаАллах! Вы прочитали ежедневный зикр и получили бонус +50 Сабик Сидс.';

  @override
  String get awesome => 'Отлично';

  @override
  String get betweenSubhSunrise => 'Между рассветом и восходом';

  @override
  String get betweenAsrMaghrib => 'Между Аср и Магриб';

  @override
  String get beforeSleeping => 'Перед сном';

  @override
  String get uponWakingUp => 'При пробуждении';

  @override
  String get afterEachPrayer => 'После каждой молитвы';

  @override
  String get anytimeEspeciallyAfterPrayer =>
      'В любое время, особенно после молитвы';

  @override
  String get anytimeMorningEvening => 'В любое время, утром и вечером';

  @override
  String get duringTheNight => 'В течение ночи';

  @override
  String get anytime => 'В любое время';

  @override
  String get asPerSunnah => 'По Сунне';

  @override
  String get whenEatingDrinking => 'При еде или питье';

  @override
  String get enteringLeavingHome => 'При входе / выходе из дома';

  @override
  String get beforeAfterWudu => 'До или после омовения';

  @override
  String get whenGettingDressed => 'При одевании';

  @override
  String get uponBadDream => 'При плохом сне';

  @override
  String get forUmmahAnytime => 'Для Уммы, в любое время';

  @override
  String get all => 'Все';

  @override
  String get general => 'Общее';

  @override
  String get startNow => 'Начать сейчас';

  @override
  String get markAsDone => 'Отметить как выполненное';

  @override
  String get enterCustomCount => 'Введите свое количество';

  @override
  String get resetToDefault => 'По умолчанию';

  @override
  String get noAzkarFound => 'Здесь нет азкаров.';

  @override
  String get reference => 'Справка';

  @override
  String get benefit => 'Польза';

  @override
  String continueAdhkar(String category) {
    return 'Продолжайте зикр из категории $category с того места, где остановились.';
  }

  @override
  String get set => 'набор';

  @override
  String get sets => 'наб.';

  @override
  String get duasOfUmmah => 'Дуа Уммы';

  @override
  String get beforeSleepCat => 'Перед сном';

  @override
  String get tahajjud => 'Тахаджуд';

  @override
  String get salah => 'Намаз';

  @override
  String get salawat => 'Салават';

  @override
  String get sunnahDuas => 'Дуа из Сунны';

  @override
  String get quranicDuas => 'Дуа из Корана';

  @override
  String get istighfar => 'Истигфар';

  @override
  String get dhikarAllTimes => 'Зикр в любое время';

  @override
  String get namesOfAllah => 'Имена Аллаха';

  @override
  String get nightmares => 'Кошмары';

  @override
  String get wakingUp => 'Пробуждение';

  @override
  String get clothes => 'Одежда';

  @override
  String get wudu => 'Омовение';

  @override
  String get foodAndDrink => 'Еда и напитки';

  @override
  String get home => 'Главная';

  @override
  String get istikharah => 'Истихара';

  @override
  String get adaanAndMasjid => 'Азан и мечеть';

  @override
  String get diffAndHappy => 'Разные и счастливые';

  @override
  String get imanProtect => 'Защита Имана';

  @override
  String get travel => 'Путешествие';

  @override
  String get shopping => 'Покупки';

  @override
  String get marriage => 'Брак';

  @override
  String get social => 'Социальное';

  @override
  String get nature => 'Природа';

  @override
  String get death => 'Смерть';

  @override
  String get gatherings => 'Собрания';

  @override
  String get hajjAndUmrah => 'Хадж и Умра';

  @override
  String get dailyEssentials => 'На каждый день';

  @override
  String get akhirahBalance => 'Баланс Ахирата';

  @override
  String get priceless => 'Бесценно';

  @override
  String get beyondWorldCanHold => 'Больше, чем вмещает этот мир';

  @override
  String deedsToday(String count) {
    return '+$count дел сегодня';
  }

  @override
  String deedsThisWeek(String count) {
    return '+$count на этой неделе';
  }

  @override
  String bestDayStreak(String count) {
    return 'Лучшая: $count дн.';
  }

  @override
  String get donateMoreEarn => 'Жертвуйте больше и получайте';

  @override
  String get yourHoldings => 'Ваши активы';

  @override
  String get seeAll => 'Смотреть все →';

  @override
  String get hasanaatEarned => 'Получено хасанатов';

  @override
  String get recordedInBookOfDeeds => 'Записано в вашу Книгу деяний';

  @override
  String get treesInJannah => 'Деревья в Раю';

  @override
  String get fromTasbih => 'От Субханаллах и Тасбих';

  @override
  String get sinsForgiven => 'Грехи прощены';

  @override
  String get likeTheFoamOfSea => 'Подобно пене морской';

  @override
  String get palacesBuilt => 'Дворцов построено';

  @override
  String get surahIkhlasAndSunnahs => 'Сура Аль-Ихляс и Сунна';

  @override
  String get treasuresOfJannah => 'Сокровища Рая';

  @override
  String get slavesFreedom => 'Рабы освобождены';

  @override
  String get equivalentReward => 'Получена эквивалентная награда';

  @override
  String get sadaqahGiven => 'Дана садака';

  @override
  String get pointsDonatedToCommunity => 'Сидс пожертвовано';

  @override
  String get allTimeLabel => 'За все время';

  @override
  String get worshipActivity => 'Поклонение';

  @override
  String get timeSpentInRemembrance => 'Время за поминанием Аллаха';

  @override
  String get noorPointsSummary => 'Сводка Сабик Сидс';

  @override
  String get totalPoints => 'Всего Сидс';

  @override
  String get title => 'Название';

  @override
  String get everyDeedRecorded => 'Каждое дело записано. Продолжайте!';

  @override
  String yourAvailable(String pts) {
    return 'Доступно: $pts Сидс';
  }

  @override
  String jazakAllahDonated(String pts) {
    return 'ДжазакАллах! Пожертвовано $pts Сидс';
  }

  @override
  String get insufficientPoints => 'Недостаточно Сидс';

  @override
  String donatePoints(String pts) {
    return 'Пожертвовать $pts Сидс';
  }

  @override
  String get everyRecitationCanChange => 'Каждое чтение может\nизменить жизнь';

  @override
  String get fullyFunded => 'Полностью профинансировано ✓';

  @override
  String get noPointsAvailable => 'Нет доступных Сидс';

  @override
  String get communityProgress => 'Прогресс общины';

  @override
  String myContribution(String pts) {
    return 'Мой вклад: $pts очков';
  }

  @override
  String get ptsRaised => 'очков собрано';

  @override
  String ofGoal(String goal) {
    return 'из $goal очков';
  }

  @override
  String get daysLeft => 'дн. осталось';

  @override
  String get lastDay => 'Последний день!';

  @override
  String get deadline => 'крайний срок';

  @override
  String get campaignStory => 'История кампании';

  @override
  String updates(String count) {
    return 'Обновления ($count)';
  }

  @override
  String get campaign => 'Кампания';

  @override
  String get noStoryYet => 'История еще не добавлена.';

  @override
  String get checkAdminPanel =>
      'Проверьте панель админа, чтобы добавить историю.';

  @override
  String get noUpdatesYet => 'Обновлений пока нет.';

  @override
  String get checkBackForNews => 'Загляните позже за новостями.';

  @override
  String get yesterday => 'Вчера';

  @override
  String daysAgo(String count) {
    return '$count дн. назад';
  }

  @override
  String get shareCampaign => 'Поделиться';

  @override
  String get spreadTheWord =>
      'Расскажите другим и помогите этой кампании достичь цели.';

  @override
  String get shareViaWhatsApp => 'Поделиться в WhatsApp';

  @override
  String get moreSharingOptions => 'Другие варианты поделиться…';

  @override
  String get slideToAdjust => 'Потяните для настройки';

  @override
  String get balance => 'Баланс';

  @override
  String get loadingYourReport => 'Загрузка вашего отчета…';

  @override
  String get profileUpdated => 'Профиль обновлен ✓';

  @override
  String get couldNotSave => 'Не удалось сохранить, попробуйте еще раз';

  @override
  String get photoUpdated => 'Фото обновлено ✓';

  @override
  String get couldNotUploadPhoto =>
      'Не удалось загрузить фото, попробуйте еще раз';

  @override
  String get changeProfilePhoto => 'Изменить фото';

  @override
  String get takeAPhoto => 'Сделать фото';

  @override
  String get chooseFromLibrary => 'Выбрать из библиотеки';

  @override
  String get removePhoto => 'Удалить фото';

  @override
  String get photoRemoved => 'Фото удалено';

  @override
  String get couldNotRemovePhoto => 'Не удалось удалить фото';

  @override
  String get signOutQuestion => 'Выйти из аккаунта?';

  @override
  String get progressSafelyStored =>
      'Ваш прогресс сохранен. Вы можете войти в любое время.';

  @override
  String get accountInformation => 'Информация аккаунта';

  @override
  String get preferences => 'Настройки';

  @override
  String get helpAndSupport => 'Помощь и поддержка';

  @override
  String get profilePhoto => 'Фото профиля';

  @override
  String get tapEditToChange => 'Нажмите «Изменить», чтобы поменять фото';

  @override
  String get tapEditToAdd => 'Нажмите «Изменить», чтобы добавить фото';

  @override
  String get edit => 'Изменить';

  @override
  String get displayName => 'Отображаемое имя';

  @override
  String get yourName => 'Ваше имя';

  @override
  String get email => 'Email';

  @override
  String get country => 'Страна';

  @override
  String get countryHint => 'напр. Россия, Казахстан...';

  @override
  String get notifications => 'Уведомления';

  @override
  String get notifOnDesc => 'Награды, этапы серий, пожертвования и другое';

  @override
  String get notifOffDesc => 'Отключено, новые оповещения не будут добавлены';

  @override
  String get viewNotificationsInbox => 'Открыть входящие уведомления';

  @override
  String nNew(String n) {
    return '$n новых';
  }

  @override
  String get helpCenter => 'Справочный центр';

  @override
  String get reportABug => 'Сообщить об ошибке';

  @override
  String get aboutNoorRewards => 'О Sabiq Rewards';

  @override
  String get builtWithLove => 'С любовью для Уммы';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get howWeProtectData => 'Как мы защищаем ваши данные';

  @override
  String get bugReportBody => 'Нашли ошибку? Напишите нам, и мы все исправим.';

  @override
  String get aboutBody =>
      'Создано с любовью для мусульманской Уммы.\nПолучайте Сабик Сидс, развивая исламские привычки.\nЖертвуйте Сидс на реальные проекты общины.';

  @override
  String get howToEarnQuestion => 'Как получить Сабик Сидс?';

  @override
  String get howToEarnAnswer =>
      'Завершайте чтение Корана, наборы Зикра и заходите каждый день.';

  @override
  String get whatIsValidateQuestion => 'Что значит Подтвердить монеты?';

  @override
  String get whatIsValidateAnswer =>
      'Нажимайте кнопку «Завершить день» на главном экране раз в день, чтобы сохранить свои монеты.';

  @override
  String get howStreaksWorkQuestion => 'Как работают серии?';

  @override
  String get howStreaksWorkAnswer =>
      'Выполняйте ежедневные действия подряд, чтобы создать серию.';

  @override
  String get canDonatQuestion => 'Можно ли пожертвовать мои Сабик Сидс?';

  @override
  String get canDonateAnswer =>
      'Да! Перейдите во вкладку Ахират, чтобы пожертвовать Сидс.';

  @override
  String get coinsSealedMashaAllah => 'Монеты сохранены!';

  @override
  String get rewardedForConsistency =>
      'Вы получили награду за\nваше постоянство сегодня!';

  @override
  String get validationPoints => 'Баллы подтверждения';

  @override
  String streakBonus(String days, String type, String points) {
    return 'Бонус за серию';
  }

  @override
  String get totalEarned => 'Всего получено';

  @override
  String get openQuran => 'Открыть Коран';

  @override
  String get duaAndAzkaar => 'Дуа и азкар';

  @override
  String get shareWithFriends => 'Поделиться с друзьями';

  @override
  String get earnMoreNoor => 'Получить больше Сидс';

  @override
  String get dontDisturb => 'Не беспокоить';

  @override
  String get maybeLater => 'Возможно, позже';

  @override
  String get read5QuranPages => 'Прочитайте 5 страниц Корана';

  @override
  String get completeNowBonus => 'Завершите сейчас → получите бонус +50 Сидс';

  @override
  String get completeADhikrSet => 'Завершите набор зикра';

  @override
  String get finishAzkaarBonus => 'Завершите азкар → получите бонус +30 Сидс';

  @override
  String get inviteAFriend => 'Пригласить друга';

  @override
  String get shareNoorBonus => 'Поделитесь Сабик → получите +100 Сидс';

  @override
  String get multiplyYour => 'УМНОЖЬТЕ СВОИ';

  @override
  String get noorPointsBang => 'Сабик Сидс!';

  @override
  String get keepMomentum =>
      'Продолжайте ваш духовный рост\nи смотрите, как растут ваши Сидс';

  @override
  String get openQuranNow => 'Открыть Коран сейчас';

  @override
  String get startAzkaarNow => 'Начать азкар';

  @override
  String get goodDeed => 'Доброе дело';

  @override
  String get earnSawabWithRead => 'Получайте саваб\nс каждым чтением';

  @override
  String get realImpact => 'Реальное влияние';

  @override
  String get coinsFundCauses => 'Сидс финансируют\nблагие дела';

  @override
  String get unexpectedGoogleError =>
      'Непредвиденная ошибка при входе через Google';

  @override
  String get authSuccessQuran => 'Авторизация через Quran.com прошла успешно!';

  @override
  String get authError => 'Ошибка авторизации';

  @override
  String get ok => 'ОК';

  @override
  String get verified => 'Проверено';

  @override
  String get connectedAccount => 'Подключенный аккаунт';

  @override
  String get active => 'Активно';

  @override
  String noorPlusPoints(String pts) {
    return '+$pts Сабик Сидс';
  }

  @override
  String get yourGarden => 'ВАШ САД';

  @override
  String get noorPointsBloomed => 'Сабик Сидс расцвели';

  @override
  String get growingStreakTitle => 'РАСТУЩАЯ СЕРИЯ';

  @override
  String get daySingular => 'день';

  @override
  String get daysPlural => 'дней';

  @override
  String get keepGrowing => 'продолжайте расти';

  @override
  String get progressLabel => 'Прогресс';

  @override
  String get weekTab => 'Неделя';

  @override
  String get monthTab => 'Месяц';

  @override
  String get todayTab => 'Сегодня';

  @override
  String ofTabGoal(String goal, String tab) {
    return 'из цели $goal $tab';
  }

  @override
  String get todaysPlots => 'Участки сегодня';

  @override
  String setsTodayCount(String count) {
    return 'наб. сегодня: $count';
  }

  @override
  String get earnPerFriend => 'Получите +500 за друга';

  @override
  String lastAchievement(String name) {
    return 'Последнее: $name';
  }

  @override
  String outOfBelievers(String count) {
    return 'Из $count верующих';
  }

  @override
  String yourRankNum(String rank) {
    return 'Ваш ранг: #$rank';
  }

  @override
  String get youIndicator => '(вы)';

  @override
  String get greetingPrefix => 'Ассаляму алейкум,';

  @override
  String get fundProjectsText => 'Ваши Сабик Сидс финансируют эти проекты';

  @override
  String activeCount(String count) {
    return 'Активно: $count';
  }

  @override
  String get seeDetailsForMoreProjects => 'Детали о других проектах →';

  @override
  String get notificationsSubtitle => 'Следите за наградами и этапами';

  @override
  String get markAllAsRead => 'Отметить все как прочитанные';

  @override
  String get clearAll => 'Очистить все';

  @override
  String get notificationsOn => 'Уведомления вкл.';

  @override
  String get notificationsOff => 'Уведомления выкл.';

  @override
  String get allCaughtUp => 'Все выполнено';

  @override
  String get whenYouEarnRewards =>
      'Здесь будут появляться ваши\nнаграды, серии и значки.';

  @override
  String get justNow => 'Только что';

  @override
  String mAgo(String delta) {
    return '$delta мин. назад';
  }

  @override
  String hAgo(String delta) {
    return '$delta ч. назад';
  }

  @override
  String dAgo(String delta) {
    return '$delta дн. назад';
  }

  @override
  String get newBadgeUnlocked => 'Получен новый значок';

  @override
  String get daySealed => 'День завершен';

  @override
  String get dailyLoginBonus => 'Бонус за вход';

  @override
  String get oneWeek => 'Одна неделя';

  @override
  String get twoWeeks => 'Две недели';

  @override
  String badgeEarnedDesc(String badge) {
    return 'Вы получили значок «$badge».';
  }

  @override
  String pointsForSealing(String points) {
    return '+$points Сабик Сидс за завершение дня.';
  }

  @override
  String welcomeBack(String points) {
    return '+$points Сабик Сидс · с возвращением!';
  }

  @override
  String get onbV2Skip => 'Пропустить';

  @override
  String get onbV2Next => 'Далее';

  @override
  String get onbV2_1_TitleA => 'Ваше чтение Корана';

  @override
  String get onbV2_1_TitleB => 'кормит голодных.';

  @override
  String get onbV2_1_Sub => 'Настоящая еда. Реальные люди. Реальное влияние.';

  @override
  String get onbV2_1_Cta => 'Как это работает?';

  @override
  String get onbV2_2_Title => 'Вот как.';

  @override
  String get onbV2_2_Body =>
      'Читайте Коран или зикр → получайте Сабик Сидс → финансируйте реальные дела.';

  @override
  String get onbV2_3_TitleA => 'Коран вознаграждает вас';

  @override
  String get onbV2_3_TitleB => 'дважды.';

  @override
  String get onbV2_3_Sub =>
      'Один раз — милостью Аллаха. Второй раз — Сидс, которые кормят нуждающихся.';

  @override
  String get onbV2_3_BannerLabel => 'получено сегодня';

  @override
  String get onbV2_4_TitleA => 'Смотрите, как ваше';

  @override
  String get onbV2_4_TitleB => 'поклонение оживает.';

  @override
  String get onbV2_4_Sub =>
      'Читайте утренний и вечерний зикр и смотрите, как растет ваша награда, хадис за хадисом.';

  @override
  String get onbV2_5_TitleA => 'Ваше чтение';

  @override
  String get onbV2_5_TitleB => 'доходит сюда.';

  @override
  String get onbV2_5_Sub =>
      'Каждый полученный вами Сид становится едой, водой и надеждой.';

  @override
  String get onbV2_6_TitleA => 'Но откуда';

  @override
  String get onbV2_6_TitleB => 'берутся';

  @override
  String get onbV2_6_TitleC => 'деньги?';

  @override
  String get onbV2_6_Sub =>
      'Щедрые спонсоры финансируют проекты. Ваши Сидс направляют их пожертвования и увеличивают их награду с каждым читателем.';

  @override
  String get onbV2_6_Donor => 'Спонсор';

  @override
  String get onbV2_6_DonorSub => 'Финансирует';

  @override
  String get onbV2_6_You => 'Вы';

  @override
  String get onbV2_6_YouSub => 'Направляете помощь';

  @override
  String get onbV2_6_Charity => 'Благотворительность';

  @override
  String get onbV2_6_CharitySub => 'Доставляет помощь';

  @override
  String get onbV2_6_TrustBadge => '100% передается проверенным партнерам';

  @override
  String get onbV2_7_TitleA => 'Каждое дело';

  @override
  String get onbV2_7_TitleB => 'имеет вес.';

  @override
  String get onbV2_7_Sub =>
      'Следите за тем, как растет ваш счет для Ахирата: деревья, дворцы, освобожденные души — согласно достоверным хадисам.';

  @override
  String get onbV2_8_TitleA => 'Давайте начнем с';

  @override
  String get onbV2_8_TitleB => 'вашего имени.';

  @override
  String get onbV2_8_Sub => 'Чтобы Сабик стал для вас своим.';

  @override
  String get onbV2_8_Placeholder => 'Ваше имя';

  @override
  String get onbV2_8_Cta => 'Продолжить';

  @override
  String get onbV2_9_TitleA => 'Какое направление';

  @override
  String get onbV2_9_TitleB => 'вам ближе?';

  @override
  String get onbV2_9_Sub =>
      'Ваши Сидс поддерживают все направления, это просто помогает нам понять, что важно для нашей общины.';

  @override
  String get onbV2_9_Cta => 'Начать';

  @override
  String get onbV2_9_Orphans => 'Сироты';

  @override
  String get onbV2_9_OrphansSub => 'Помощь и забота о детях, потерявших всё';

  @override
  String get onbV2_9_Water => 'Колодцы';

  @override
  String get onbV2_9_WaterSub => 'Чистая вода для нуждающихся';

  @override
  String get onbV2_9_War => 'Зоны конфликтов';

  @override
  String get onbV2_9_WarSub => 'Помощь там, где она нужнее всего';

  @override
  String get onbV2_9_Disaster => 'Стихийные бедствия';

  @override
  String get onbV2_9_DisasterSub => 'Быстрое реагирование при кризисах';

  @override
  String get onbV2_3step_Title => 'Три простых шага.';

  @override
  String get onbV2_3step_Sub =>
      'Каждый аят, каждый зикр превращается в реальную помощь.';

  @override
  String get onbV2_3step_S1Label => 'Шаг 1';

  @override
  String get onbV2_3step_S1Text => 'Читайте Коран';

  @override
  String get onbV2_3step_S2Label => 'Шаг 2';

  @override
  String get onbV2_3step_S2Text => 'Получите Сидс';

  @override
  String get onbV2_3step_S3Label => 'Шаг 3';

  @override
  String get onbV2_3step_S3Text => 'Помогите сиротам';

  @override
  String get languageLabel => 'Язык';

  @override
  String get systemDefault => 'Системный';

  @override
  String get yourStreaksTitle => 'ВАШИ СЕРИИ';

  @override
  String get streakLoading => 'Загрузка серий…';

  @override
  String get startStreakToday => 'Начните серию сегодня!';

  @override
  String get centurionMashaAllah => 'Сотник, МашаАллах!';

  @override
  String get qfConflictTitle => 'Аккаунт уже существует';

  @override
  String get qfConflictExplanation =>
      'Этот email уже зарегистрирован в Sabiq Rewards с другим способом входа (Email или Google).\n\nЧтобы сохранить ваш прогресс, серии и Сабик Сидс, войдите первоначальным способом.';

  @override
  String get qfConflictStep1 => 'Вернитесь на экран входа';

  @override
  String qfConflictStep2(String email) {
    return 'Войдите по Email или Google, используя\n$email';
  }

  @override
  String get qfConflictStep3 => 'Весь ваш прогресс будет там';

  @override
  String get qfConflictBackButton => 'Назад ко входу';

  @override
  String get sponsorAnOrphan => 'Спонсировать сироту';

  @override
  String get noOrphansListed => 'Пока нет подопечных детей';

  @override
  String get checkBackForOrphans =>
      'Загляните позже, возможности появляются регулярно.';

  @override
  String get orphanVerseTranslation =>
      '«Посему не притесняй сироту!» Коран 93:9';

  @override
  String get orphanCardOpen => 'Открыть';

  @override
  String get doneLabel => 'Готово';

  @override
  String get aReminderLabel => 'НАПОМИНАНИЕ';

  @override
  String get yourAkhirahBalance => 'ВАШ БАЛАНС АХИРАТА';

  @override
  String get seedsCollectedSinceJoined => 'Сидс собрано с момента регистрации';

  @override
  String get todayLabel => 'СЕГОДНЯ';

  @override
  String plusSeedsToday(String count) {
    return '+$count сегодня';
  }

  @override
  String get azkaarPerDay => 'азкар в день';

  @override
  String get viewFullStats => 'Смотреть полную статистику';

  @override
  String get fatherLabel => 'Отец';

  @override
  String get motherLabel => 'Мать';

  @override
  String get siblingsLabel => 'Братья/сестры';

  @override
  String get familySection => 'Семья';

  @override
  String get educationSection => 'Образование';

  @override
  String get gradeLabel => 'Степень';

  @override
  String get schoolLabel => 'Школа';

  @override
  String get theirStorySection => 'Их история';

  @override
  String get yourBalanceLabel => 'Ваш баланс:';

  @override
  String sponsorCta(String name) {
    return 'Спонсировать $name';
  }

  @override
  String get notEnoughSeeds => 'Недостаточно Сидс';

  @override
  String get bookmarkSyncDialogTitle => 'Синхронизация с Quran.com';

  @override
  String get closeLabel => 'Закрыть';

  @override
  String get searchHint => 'Поиск…';

  @override
  String get enterCodeHint => 'Введите код…';

  @override
  String get searchSurahHint => 'Поиск суры...';

  @override
  String get customLabel => 'Свой вариант';

  @override
  String get seedsSuffix => 'Сидс';

  @override
  String get settingsTooltip => 'Настройки';

  @override
  String get retryLabel => 'Повторить';

  @override
  String get authErrorTitle => 'Ошибка авторизации';

  @override
  String sealWithinHours(int hours) {
    return 'Завершить в течение $hours ч';
  }

  @override
  String sealWithinMinutes(int minutes) {
    return 'Завершить в течение $minutes м';
  }

  @override
  String get sealNow => 'Завершить сейчас';

  @override
  String get goalLabel => 'Цель';

  @override
  String contributorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count участников',
      one: '1 участник',
    );
    return '$_temp0';
  }

  @override
  String dayStreakCount(int streak) {
    return 'Серия $streak дн. 🔥';
  }

  @override
  String seedsPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Сидс ожидают',
      one: '1 Сид ожидает',
    );
    return '$_temp0';
  }

  @override
  String get sealToSave => 'Завершите для сохранения';

  @override
  String get top10Contributors => 'Топ-10 спонсоров';

  @override
  String get copyLabel => 'Копировать';

  @override
  String get copiedLabel => 'Скопировано!';

  @override
  String get whatsappLabel => 'WhatsApp';

  @override
  String get youBothEarnSeeds => 'Вы оба получаете по 500 Сабик Сидс!';

  @override
  String jazakAllahPlusSeeds(int seeds) {
    return 'ДжазакАллах! +$seeds Сидс';
  }

  @override
  String get jazakAllahDaySealed => 'ДжазакАллах! День завершен';

  @override
  String get pointsGoals => 'ЦЕЛИ';

  @override
  String get editLabel => 'Изменить';

  @override
  String get dailyGoal => 'Цель на день';

  @override
  String get weeklyGoal => 'Цель на неделю';

  @override
  String get monthlyGoal => 'Цель на месяц';

  @override
  String setTargetSeeds(int defaultVal) {
    return 'Установите цель по Сидс (по умолчанию: $defaultVal)';
  }

  @override
  String get noInternetTitle => 'Нет интернета';

  @override
  String get connectingTitle => 'Подключение...';

  @override
  String get somethingWentWrongTitle => 'Что-то пошло не так';

  @override
  String get noInternetSubtitle =>
      'Для этого нужен интернет.\nПроверьте Wi-Fi или сотовую связь.';

  @override
  String get connectingSubtitle =>
      'Получение ваших данных...\nПожалуйста, подождите';

  @override
  String get errorSubtitle =>
      'Произошла непредвиденная ошибка.\nНажмите, чтобы повторить.';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String get everyRecitationCanChangeLife =>
      'Каждое чтение может\nизменить жизнь';

  @override
  String get givenLabel => 'ОТДАНО';

  @override
  String get goalUpper => 'ЦЕЛЬ';

  @override
  String get aboutThisCause => 'Об этой кампании';

  @override
  String myContributionSeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Мой вклад: $count Сидс',
      one: 'Мой вклад: 1 Сид',
    );
    return '$_temp0';
  }

  @override
  String jazakAllahKhayranDonated(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: 'Джазак Аллах Хайран! Пожертвовано: $amount Сидс.',
      one: 'Джазак Аллах Хайран! 1 Сид пожертвован.',
    );
    return '$_temp0';
  }

  @override
  String get coinsSealedTitle => 'Монеты сохранены! МашаАллах';

  @override
  String get seedsSealedSafe => 'Ваши Сидс сохранены\nдля Ахирата.';

  @override
  String get validationSeedsLabel => 'Сидс за подтверждение';

  @override
  String get streakBonusLabel => 'Бонус за серию';

  @override
  String get totalEarnedLabel => 'Всего получено';

  @override
  String get alhamdulillahCta => 'Альхамдулиллях! 🤲';

  @override
  String get openQuranCta => 'Открыть Коран';

  @override
  String get duaAzkaarCta => 'Дуа и азкар';

  @override
  String get shareWithFriendsCta => 'Поделиться с друзьями';

  @override
  String get earnMoreSeedsCta => 'Получить больше Сидс';

  @override
  String levelTitleFormat(int level, String title) {
    return 'Ур. $level · $title';
  }

  @override
  String get akhirahBalanceUpper => 'БАЛАНС АХИРАТА';

  @override
  String bestDayStreakBadge(int streak) {
    return 'Лучшая: $streak дн.';
  }

  @override
  String get deedsLabel => 'ДЕЛА';

  @override
  String get treesLabel => 'ДЕРЕВЬЯ';

  @override
  String get forgivenLabel => 'ПРОЩЕН';

  @override
  String get navCause => 'Кампания';

  @override
  String get realChildrenSubtitle => 'Реальные дети, их истории и жизни';

  @override
  String get seeAllAction => 'Смотреть все';

  @override
  String get activeCampaigns => 'Активные кампании';

  @override
  String get poolSeedsImpact => 'Объединяйте Сидс для большего влияния';

  @override
  String get featuredSponsorChild => 'Избранное · Спонсировать ребенка';

  @override
  String meetOrphanAge(String name, int age) {
    return 'Познакомьтесь с $name, возраст: $age';
  }

  @override
  String sponsorNameArrow(String name) {
    return 'Спонсировать $name →';
  }

  @override
  String get featuredCampaign => 'Избранная кампания';

  @override
  String get yourGiving => 'Ваши пожертвования';

  @override
  String get havenNotGivenYet =>
      'Вы еще не жертвовали. Выберите кого-нибудь выше, чтобы начать свой путь.';

  @override
  String get seedsDonatedLabel => 'Сидс пожертвовано';

  @override
  String orphanCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сирот',
      one: 'Сирота',
    );
    return '$_temp0';
  }

  @override
  String projectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Проектов',
      one: 'Проект',
    );
    return '$_temp0';
  }

  @override
  String get couldntLoadJourney => 'Не удалось загрузить ваше Путешествие';

  @override
  String get checkConnectionRetry => 'Проверьте подключение и повторите.';

  @override
  String actionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count действий',
      one: '1 действие',
    );
    return '$_temp0';
  }

  @override
  String get showLessAction => 'Свернуть ←';

  @override
  String get hadithReference => 'Ссылка на хадис';

  @override
  String get howYouEarnedThis => 'Как вы это заработали';

  @override
  String seedsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Сидс',
      one: '1 Сид',
    );
    return '$_temp0';
  }

  @override
  String get seedsUnit => 'Сидс';

  @override
  String get topContribByLifetimeSeeds => 'Топ спонсоров по Сидс за все время';

  @override
  String get romanisedPronunciation => 'Транслитерация под каждым словом';

  @override
  String get displayLabel => 'ОТОБРАЖЕНИЕ';

  @override
  String get arabicLanguageLabel => 'Арабский';

  @override
  String get urduLanguageLabel => 'Урду';

  @override
  String get englishLanguageLabel => 'Английский';

  @override
  String get earnPerVerseRead =>
      'Получите +10 Сабик Сидс за каждый прочитанный аят';

  @override
  String get surahPickerLabel => 'Сура';

  @override
  String versesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аятов',
      one: '1 аят',
    );
    return '$_temp0';
  }

  @override
  String get startFromVerse => 'Начать с аята';

  @override
  String verseN(int n) {
    return 'Аят $n';
  }

  @override
  String ofN(int n) {
    return 'из $n';
  }

  @override
  String surahHasNVerses(String name, int count) {
    return 'В суре $name $count аятов';
  }

  @override
  String noXYet(String label) {
    return 'Пока нет $label';
  }

  @override
  String get tapHeartToSave =>
      'Нажмите на сердечко/закладку при чтении, чтобы сохранить аят.';

  @override
  String surahVerseRow(int surah, int ayah) {
    return 'Сура $surah • Аят $ayah';
  }

  @override
  String get hasanatFromQuran => 'Хасанаты от Корана';

  @override
  String tenPerLetterSubtitle(int count) {
    return '10 за букву, $count за аят';
  }

  @override
  String get fromSubhanAllahTasbih => 'От Субханаллах и Тасбих';

  @override
  String get likeFoamOfSea => 'Подобно пене морской';

  @override
  String get fromSurahIkhlasRecitation => 'От чтения суры Аль-Ихляс';

  @override
  String get laHawlaSubtitle => 'Ля хавля ва ля куввата';

  @override
  String get equivalentRewardEarned => 'Получена эквивалентная награда';

  @override
  String get gatesOfParadise => 'Врата Рая';

  @override
  String get afterPerfectWudu => 'После идеального омовения';

  @override
  String get blessingsFromAllah => 'Милость от Аллаха';

  @override
  String get salawatTenReturned => 'Салават × 10 возвращено';

  @override
  String get timesProtected => 'Раз защищены';

  @override
  String get refugeInvokedFromHarm => 'Испрошена защита от зла';

  @override
  String get quranCompletions => 'Завершения Корана';

  @override
  String get viaSurahIkhlas => 'Через суру Аль-Ихляс ×3';

  @override
  String get bonusHasanaat => 'Бонусные хасанаты';

  @override
  String get marketplaceDua => 'Дуа при входе на рынок';

  @override
  String get seedsDonatedToCommunity => 'Сидс пожертвовано';

  @override
  String get yourMonth => 'Ваш месяц';

  @override
  String get ayahsReadLabel => 'Прочитано аятов';

  @override
  String get dhikrCount => 'Счетчик зикра';

  @override
  String get quranTime => 'Время Корана';

  @override
  String get dhikrTime => 'Время зикра';

  @override
  String get activeDays => 'Активные дни';

  @override
  String get treesShortLabel => 'Деревья';

  @override
  String get palacesShortLabel => 'Дворцы';

  @override
  String get freedShortLabel => 'Освобождены';

  @override
  String get blessingsShortLabel => 'Милость';

  @override
  String get dailyWordPrefix => 'Ежедневный ';

  @override
  String get essentialsWord => 'Основное';

  @override
  String get seedsExpiringNotificationTitle => 'Сидс сгорят в полночь!';

  @override
  String seedsExpiringNotificationBody(int pending) {
    return 'У вас $pending несобранных Сидс. Завершите день сейчас, иначе они сгорят!';
  }

  @override
  String get okButton => 'ОК';

  @override
  String get signUpTitle => 'Регистрация';

  @override
  String get signInTitle => 'Войти';

  @override
  String get emailFieldLabel => 'Email';

  @override
  String get passwordFieldLabel => 'Пароль';

  @override
  String get enterEmailValidator => 'Пожалуйста, введите ваш email';

  @override
  String get enterPasswordValidator => 'Пожалуйста, введите ваш пароль';

  @override
  String get passwordTooShortValidator =>
      'Пароль должен содержать не менее 6 символов';

  @override
  String get signUpSuccessMessage =>
      'Регистрация успешна! Проверьте email для подтверждения.';

  @override
  String get unexpectedAuthError => 'Произошла непредвиденная ошибка';

  @override
  String get sawabLabel => 'Саваб';

  @override
  String get impactLabel => 'Влияние';

  @override
  String get goodDeedTitle => 'Доброе дело';

  @override
  String get goodDeedSubtitle => 'Получайте саваб\nс каждым чтением';

  @override
  String get realImpactTitle => 'Реальное влияние';

  @override
  String get realImpactSubtitle => 'Монеты финансируют\nблагие дела';

  @override
  String plusDeedsTodayBadge(String count) {
    return 'Дел сегодня: +$count';
  }

  @override
  String equivalentChange(String count) {
    return 'Эквивалент $count';
  }

  @override
  String receivedChange(String count) {
    return 'Получено: $count';
  }

  @override
  String readAyahsPlusTimeToday(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Прочитано $count аятов плюс $time чтения Корана сегодня',
      one: 'Прочитан 1 аят плюс $time чтения Корана сегодня',
    );
    return '$_temp0';
  }

  @override
  String readAyahsToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Прочитано $count аятов сегодня',
      one: 'Прочитан 1 аят сегодня',
    );
    return '$_temp0';
  }

  @override
  String spentTimeReadingQuranToday(String time) {
    return '$time за чтением Корана сегодня';
  }

  @override
  String get everyDeedRecordedKeepGoing =>
      '🌙 Каждое дело записано. Продолжайте!';

  @override
  String viewAllDonors(int count) {
    return 'Смотреть всех $count спонсоров';
  }

  @override
  String nextMilestoneInfo(String label, int days) {
    return 'Далее: $label ($days дн.)';
  }

  @override
  String bestN(int n) {
    return 'Лучшие $n';
  }

  @override
  String get streakMilestoneWarmingUp => 'Разминка';

  @override
  String get streakMilestoneOneWeek => 'Одна неделя';

  @override
  String get streakMilestoneTwoWeeks => 'Две недели';

  @override
  String get streakMilestoneOneMonth => 'Один месяц';

  @override
  String get streakMilestoneTwoMonths => 'Два месяца';

  @override
  String get streakMilestoneCenturion => 'Сотник';

  @override
  String get firstTrackedWeek => 'Ваша первая записанная неделя — продолжайте!';

  @override
  String get rightOnSevenDayPace => 'Точно по вашему графику за 7 дней';

  @override
  String aboveSevenDayAvg(int pct) {
    return 'На $pct% выше вашего среднего за 7 дней';
  }

  @override
  String belowSevenDayAvg(int pct) {
    return 'На $pct% ниже вашего среднего за 7 дней';
  }

  @override
  String get sponsoredBy => 'Спонсор:';

  @override
  String currentOverDays(int current, int days) {
    return '$current / $days дней';
  }

  @override
  String daysWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'дней',
      one: 'день',
    );
    return '$_temp0';
  }

  @override
  String get dayAbbrMon => 'Пн';

  @override
  String get dayAbbrTue => 'Вт';

  @override
  String get dayAbbrWed => 'Ср';

  @override
  String get dayAbbrThu => 'Чт';

  @override
  String get dayAbbrFri => 'Пт';

  @override
  String get dayAbbrSat => 'Сб';

  @override
  String get dayAbbrSun => 'Вс';

  @override
  String get favoritesCategory => 'Избранное';

  @override
  String get sleepingCategory => 'Сон';

  @override
  String get dailyWord => 'Ежедневный';

  @override
  String get dailyDuasCategory => 'Ежедневные дуа';

  @override
  String get ruquiyaCategory => 'Рукия';

  @override
  String get duasBeforeSleep => 'Дуа перед сном';

  @override
  String get duasAfterSalah => 'Дуа после намаза';

  @override
  String get rabbana40Duas => '40 дуа Раббана';

  @override
  String get thisWorld => 'Этот мир';

  @override
  String get dunyaArabic => 'Дунья';

  @override
  String get hereafter => 'Ахират';

  @override
  String get akhirahArabic => 'Ахират';

  @override
  String get bookOfCompletePrayer => 'Книга совершенной молитвы';

  @override
  String get propheticDuas => 'Дуа Пророков';

  @override
  String get morningEveningRemembrance => 'Утренний и вечерний зикр';

  @override
  String get furtherDuas => 'Дополнительные дуа';

  @override
  String get closingSalawat => 'Завершающий зикр и салават';

  @override
  String get hajjAndUmrahCategory => 'Дуа для Хаджа и Умры';

  @override
  String get azkarSingular => 'азкар';

  @override
  String get azkarPlural => 'азкаров';

  @override
  String get hourSingular => 'час';

  @override
  String get hourPlural => 'часов';

  @override
  String get minuteSingular => 'минута';

  @override
  String get minutePlural => 'минут';

  @override
  String get secondSingular => 'секунда';

  @override
  String get secondPlural => 'секунд';

  @override
  String seedsThisSession(String count) {
    return '+$count Сидс за сеанс';
  }

  @override
  String sevenDayAvgAzkaar(String count) {
    return 'Среднее за 7 дн: $count азкар/день';
  }

  @override
  String holdingChangeAyahs(String count) {
    return '$count аятов';
  }

  @override
  String holdingChangePlanted(String count) {
    return '$count посажено';
  }

  @override
  String holdingChangeCycles(String count) {
    return '$count циклов';
  }

  @override
  String holdingChangeBuilt(String count) {
    return '$count построено';
  }

  @override
  String holdingChangeEarned(String count) {
    return '$count получено';
  }

  @override
  String holdingChangeOpened(String count) {
    return '$count открыто';
  }

  @override
  String holdingChangeInvocations(String count) {
    return '$count дуа';
  }

  @override
  String holdingChangeRecitations(String count) {
    return '$count чтений';
  }

  @override
  String bookmarksOnQuranCom(String count) {
    return 'Закладок на Quran.com: $count';
  }

  @override
  String bookmarksInThisApp(String count) {
    return 'Закладок здесь: $count';
  }

  @override
  String streakSeedsBonus(String count) {
    return '+$count Сидс';
  }

  @override
  String plusSeedsThisWeek(String count) {
    return '+$count на этой неделе';
  }

  @override
  String unitDuas(String count) {
    return '$count дуа';
  }

  @override
  String unitAdhkar(String count) {
    return '$count азкар';
  }

  @override
  String get moreCollections => 'Другие коллекции';

  @override
  String get donateAndEarnReward => 'Пожертвуйте и получите награду';

  @override
  String donateAmountSeeds(String amount) {
    return 'Пожертвовать $amount Сидс';
  }

  @override
  String get readMore => 'Читать далее';

  @override
  String get beFirstToContribute => 'Сделайте пожертвование первым.';

  @override
  String get showFewer => 'Показать меньше ↑';

  @override
  String viewAllN(String n) {
    return 'Смотреть все $n →';
  }

  @override
  String liveReadersNow(String count) {
    return 'Сейчас онлайн: $count';
  }

  @override
  String communityReadingToday(String count) {
    return 'Сегодня прочитали $count (община)';
  }

  @override
  String communityHasanatToday(String count) {
    return '+$count хасанатов общины сегодня';
  }

  @override
  String get peopleReadingNow => 'читают прямо сейчас';

  @override
  String get readToday => 'прочитано сегодня';

  @override
  String get communityHasanat => 'хасанаты общины';

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
    return 'Наборов сегодня: $_dhikrToday';
  }

  @override
  String dashboardScreen_last(String arg1) {
    return 'Последний: $arg1';
  }

  @override
  String get dashboardScreen_earnPerFriend => 'Получите +500 за друга';

  @override
  String get dashboardScreen_invalidReferralCode_59fb25 =>
      'Неверный реферальный код.';

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
      'Благослови каждое чувство, каждую часть тела, каждое дело';

  @override
  String get dhikrScreen_keepTheHeartFirm_9c4efb =>
      'Укрепи сердце после прямого пути';

  @override
  String get dhikrScreen_faithAnsweredWithForgiveness_3f30c4 =>
      'Вера вознаграждается прощением и спасением от Огня';

  @override
  String get dhikrScreen_inscribedWithTheWitnesses_e2612d =>
      'Записано вместе со свидетелями истины';

  @override
  String get dhikrScreen_allahIsTheBest_4f2bf7 =>
      'Аллах — лучший судья между истиной и ложью';

  @override
  String get dhikrScreen_neverTrialForThe_5eb10a =>
      'Никогда не станет испытанием для неверующих';

  @override
  String get dhikrScreen_refugeFromEveryEvil_6d2534 =>
      'Защита от любого постигающего зла';

  @override
  String get dhikrScreen_guaranteedJannahIfYou_48d274 =>
      'Рай гарантирован, если вы умрете в эту ночь';

  @override
  String get dhikrScreen_reciteAtDawnDusk_f17fb8 =>
      'Читайте 3 раза утром и вечером, этого будет достаточно';

  @override
  String get dhikrScreen_nothingShallHarmYou_8c5c6c =>
      'С Его именем ничто не причинит вам вреда';

  @override
  String get dhikrScreen_guaranteedJannahIfYou_0ffafe =>
      'Рай гарантирован, если вы умрете сегодня';

  @override
  String get dhikrScreen_guardedInYourDeen_4a0b4a =>
      'Защищен в религии, мирской жизни, Ахирате и со всех сторон';

  @override
  String get dhikrScreen_guardMeFromAll => 'Защити меня со всех шести сторон';

  @override
  String dhikrScreen_35c165(String arg1) {
    return '$arg1  ';
  }

  @override
  String get dhikrScreen_sinsWashedAway => 'Грехи смыты';

  @override
  String get dhikrScreen_slavesFreed => 'Рабы освобождены';

  @override
  String get dhikrScreen_weHaveBelievedForgive_e958e6 =>
      'Мы уверовали — прости нас, Ты лучший из милосердных';

  @override
  String get dhikrScreen_mashaallahRewardSecured =>
      'МашаАллах! Награда получена';

  @override
  String dhikrScreen_a5cfd1(String count) {
    return '×$count';
  }

  @override
  String get dhikrScreen_completeToWatchYour =>
      'Завершите, чтобы увидеть, как расцветет ваш сад';

  @override
  String impactReportScreen_200447(String arg1) {
    return '+$arg1';
  }

  @override
  String get impactReportScreen_deedsTODAY => 'ДЕЛА СЕГОДНЯ';

  @override
  String impactReportScreen_634027(String arg1) {
    return '+$arg1';
  }

  @override
  String get impactReportScreen_thisWEEK => 'НА ЭТОЙ НЕДЕЛЕ';

  @override
  String get impactReportScreen_hasanaatEarned => 'Получено хасанатов';

  @override
  String impactReportScreen_hasanat_e68a30(String arg1) {
    return '  → Хасанаты: $arg1\\n\\n';
  }

  @override
  String get impactReportScreen_hasanatFromQuran => 'Хасанаты от Корана';

  @override
  String get impactReportScreen_treesInJannah => 'Деревья в Раю';

  @override
  String get impactReportScreen_sinsForgiven => 'Грехи прощены';

  @override
  String get impactReportScreen_palacesBuilt => 'Дворцов построено';

  @override
  String get impactReportScreen_treasuresOfJannah => 'Сокровища Рая';

  @override
  String get impactReportScreen_slavesFreed => 'Рабы освобождены';

  @override
  String impactReportScreen_totalRecitations_262e54(String arg1) {
    return 'Всего чтений: $arg1\\n';
  }

  @override
  String get impactReportScreen_gatesOfParadiseOpened => 'Врата Рая открыты';

  @override
  String get impactReportScreen_blessingsFromAllah => 'Милость от Аллаха';

  @override
  String get impactReportScreen_timesProtected => 'Раз защищены';

  @override
  String get impactReportScreen_quranCompletions => 'Завершения Корана';

  @override
  String get impactReportScreen_bonusMillionHasanaat =>
      'Бонус: Миллион хасанатов';

  @override
  String get impactReportScreen_sadaqahGiven => 'Дана садака';

  @override
  String impactReportScreen_564740(String _monthActiveDays) {
    return '$_monthActiveDays';
  }

  @override
  String impactReportScreen_3dc421(String arg1) {
    return '$arg1 ч. ';
  }

  @override
  String impactReportScreen_08990a(String arg1) {
    return '${arg1}m';
  }

  @override
  String impactReportScreen_ago_c25b44(String arg1) {
    return '$arg1 ч. назад';
  }

  @override
  String impactReportScreen_ago_e160e3(String arg1) {
    return '$arg1 нед. назад';
  }

  @override
  String impactReportScreen_ago_65f0ec(String arg1) {
    return '$arg1 г. назад';
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
    return '+$arg1 Сидс';
  }

  @override
  String levelScreen_seeds_a20530(String arg1) {
    return '+$arg1 Сидс';
  }

  @override
  String levelScreen_seeds_a49180(String arg1) {
    return '+$arg1 Сидс ✓';
  }

  @override
  String levelScreen_seeds_a22be5(String arg1) {
    return '+$arg1 Сидс';
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
    return '+$arg1 Сидс';
  }

  @override
  String get phase1Screens_inTheNameOf =>
      'Во имя Аллаха, Милостивого, Милосердного...';

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
    return '$arg1 ч. назад';
  }

  @override
  String orphanDetailScreen_ago_e160e3(String arg1) {
    return '$arg1 нед. назад';
  }

  @override
  String orphanDetailScreen_ago_65f0ec(String arg1) {
    return '$arg1 г. назад';
  }

  @override
  String get profileSettingsScreen_sabiqRewards => 'Sabiq Rewards • v1.0';

  @override
  String profileSettingsScreen_seeds_59ba7c(String arg1) {
    return '$arg1 Сидс';
  }

  @override
  String profileSettingsScreen_seeds_2bc978(String arg1) {
    return '$arg1 Сидс';
  }

  @override
  String get profileSetupScreen_ahmadFatimaYusuf => 'Ахмад, Фатима, Юсуф...';

  @override
  String get profileSetupScreen_pakistanEgyptMalaysia =>
      'Россия, Казахстан, Турция...';

  @override
  String projectDetailScreen_4c2b09(String arg1, String arg2, String arg3) {
    return '$arg1 $arg2 $arg3';
  }

  @override
  String projectDetailScreen_seeds_801ec7(String arg1) {
    return '$arg1 Сидс';
  }

  @override
  String projectDetailScreen_e4e562(String arg1) {
    return '$arg1%';
  }

  @override
  String projectDetailScreen_ago_c25b44(String arg1) {
    return '$arg1 ч. назад';
  }

  @override
  String projectDetailScreen_ago_e160e3(String arg1) {
    return '$arg1 нед. назад';
  }

  @override
  String projectDetailScreen_ago_65f0ec(String arg1) {
    return '$arg1 г. назад';
  }

  @override
  String get quranHubScreen_loadingQuran => 'Загрузка Корана…';

  @override
  String quranHubScreen_saved_edce53(String arg1) {
    return '$arg1 сохранено';
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
      'Данные слова недоступны. Проверьте подключение.';

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
      'Подключено к Quran.com (синхронизация закладок отложена)';

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
      'Вы должны войти в систему, чтобы стать спонсором.';

  @override
  String get liveNotificationService_sealYourSeedsBefore_be2183 =>
      'Сохраните ваши Сидс до полуночи!';

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
    return '+$arg1 Сидс';
  }

  @override
  String get motivationalPopup_readQuranPages => 'Прочитайте 5 страниц Корана';

  @override
  String get motivationalPopup_completeDhikrSet => 'Завершите набор зикра';

  @override
  String get motivationalPopup_inviteFriend => 'Пригласить друга';

  @override
  String notificationsSheet_ago(String arg1) {
    return '$arg1 мин. назад';
  }

  @override
  String notificationsSheet_ago_5d4e7f(String arg1) {
    return '$arg1 ч. назад';
  }

  @override
  String notificationsSheet_ago_67b1d9(String arg1) {
    return '$arg1 дн. назад';
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
      '«Субханаллахи ва би-хамдихи» 100 раз в день стирает грехи, даже если их как пены морской.';

  @override
  String get akhirahBalanceScreen_sayLaIlahaIllallah_27fc5f =>
      'Сказать Ля иляха илляллах 100 раз равно освобождению 10 рабов. (Бухари)';

  @override
  String get akhirahBalanceScreen_lightOnTheTongue_ea6114 =>
      'Легки на языке, тяжелы на весах: Субханаллахи ва би-хамдихи, Субханаллахиль-азым.';

  @override
  String get akhirahBalanceScreen_theDhikrOfAllah_a23f17 =>
      'Зикр Аллаха на весах тяжелее золота. Продолжайте.';

  @override
  String get akhirahBalanceScreen_yourTongueShouldStay_34816c =>
      '«Пусть твой язык всегда будет влажным от поминания Аллаха». — Он все еще влажный?';

  @override
  String get akhirahBalanceScreen_astaghfirullahTheProphetSaid_7625ff =>
      'Астагфируллах — Пророк ﷺ говорил это 100 раз в день, будучи безгрешным. А вы?';

  @override
  String get akhirahBalanceScreen_whenYouRememberAllah_60f406 =>
      'Если вы поминаете Аллаха про себя, Он вспоминает вас в лучшем собрании.';

  @override
  String get akhirahBalanceScreen_reciteAyatAlKursi_d0751f =>
      'Читайте Аят аль-Курси после намаза — ничто не отдалит вас от Рая, кроме смерти.';

  @override
  String get akhirahBalanceScreen_oneAlhamdulillahFillsThe_4794bb =>
      'Альхамдулиллях заполняет весы. Субханаллах заполняет то, что между небом и землей.';

  @override
  String get akhirahBalanceScreen_theRemembranceOfAllah_c99fe8 =>
      '«Поминание Аллаха — самое важное». — Сура Аль-Анкабут 29:45';

  @override
  String get akhirahBalanceScreen_rememberMeWillRemember_1aca04 =>
      '«Поминайте Меня — и Я буду помнить вас». — Сура Аль-Бакара 2:152.';

  @override
  String get akhirahBalanceScreen_inTheRemembranceOf_20b541 =>
      '«Разве не поминанием Аллаха утешаются сердца?» — Сура Ар-Раад 13:28';

  @override
  String get akhirahBalanceScreen_fiveMinutesOfDhikr_e12766 =>
      '5 минут зикра формируют следующие 24 часа для вашего сердца.';

  @override
  String get akhirahBalanceScreen_streakIsnAboutToday_9157d8 =>
      'Серия — это не про сегодня, а про то, кем вы станете через 30 дней.';

  @override
  String get akhirahBalanceScreen_smallDropsFillAn_1accce =>
      'Капли наполняют океан. Ваш зикр наполняет нечто гораздо большее.';

  @override
  String get akhirahBalanceScreen_noOneSeesThe_0182c7 =>
      'Никто не видит зикр в вашем сердце — кроме каждого ангела, записывающего ваши дела.';

  @override
  String get akhirahBalanceScreen_theBiggestWinsAre_1b8fb6 =>
      'Большие победы строятся на малых привычках. Не прерывайте цепь.';

  @override
  String get akhirahBalanceScreen_youCameBackToday_a020b1 =>
      'Вы вернулись сегодня. Это уже поклонение. Останетесь еще на минуту?';

  @override
  String get akhirahBalanceScreen_tomorrowPeaceIsBuilt_a72bd8 =>
      'Мир завтрашнего дня строится на зикре сегодня. Посадите еще одно семя.';

  @override
  String get akhirahBalanceScreen_areYouDoneAllah_06ca1d =>
      'Закончили? Дверь Аллаха всегда открыта — даже если вы закрыли свою.';

  @override
  String get akhirahBalanceScreen_dhikrIsTheLanguage_b1b983 =>
      'Зикр — это язык сердца. Говорило ли ваше сердце с Господом сегодня?';

  @override
  String get akhirahBalanceScreen_everySubhanallahIsSadaqah_16b797 =>
      'Каждый Субханаллах — садака. Сколько вы дадите перед сном?';

  @override
  String get akhirahBalanceScreen_heartThatForgetsDhikr_3a6173 =>
      'Сердце, забывающее зикр, ржавеет. Поминающее сердце остается светлым.';

  @override
  String get akhirahBalanceScreen_haveYouFortifiedYourself_17ccac =>
      'Защитили ли вы себя сегодня утренними и вечерними азкарами?';

  @override
  String dashboardScreen_sponsor_d48549(String name, String arg1) {
    return 'Спонсировать $name, $arg1';
  }

  @override
  String dashboardScreen_606140_606140(String arg1, String _lastAyah) {
    return '$arg1 · $_lastAyah';
  }

  @override
  String get dashboardScreen_joinMeOnSabiq_755fb5 =>
      'Присоединяйтесь ко мне в Sabiq Rewards, получайте Сидс за Коран, Зикр и добрые дела!\\n\\n';

  @override
  String dashboardScreen_useMyCodeAnd_7d13b3(String arg1) {
    return 'Используйте мой код *$arg1*, и мы оба получим по 500 Сабик Сидс!\\n\\n';
  }

  @override
  String get dashboardScreen_messageCopiedShareOr_7b977e =>
      'Скопируйте сообщение, поделитесь или вставьте в WhatsApp!';

  @override
  String get dashboardScreen_sabiqSeedsRewardedTo_c209d6 =>
      'Вы оба получили по 500 Сабик Сидс!';

  @override
  String get dashboardScreen_youHaveAlreadyUsed_f7c387 =>
      'Вы уже использовали реферальный код.';

  @override
  String get dashboardScreen_youCannotUseYour_b7dbfe =>
      'Вы не можете использовать свой код.';

  @override
  String get dashboardScreen_anErrorOccurredPlease_8ee486 =>
      'Произошла ошибка. Пожалуйста, попробуйте снова.';

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
      '🤲 Смотреть кампанию и пожертвовать';

  @override
  String dashboardScreen_d13a42_d13a42(
    String _myPoints,
    String unit,
    String arg1,
  ) {
    return '$_myPoints $unit • $arg1';
  }

  @override
  String get dashboardScreen_beTheFirstOn_63de17 => 'Будьте первым в рейтинге';

  @override
  String get dashboardScreen_readAnAyahOr_9c7ab7 =>
      'Прочтите аят или зикр, чтобы занять первое место';

  @override
  String dashboardScreen_lvl_ac180d(String level, String arg1) {
    return 'Уровень $level · $arg1';
  }

  @override
  String dhikrScreen_default_8bd36b(String recommendedCount) {
    return 'По умолчанию: $recommendedCount';
  }

  @override
  String get dhikrScreen_pinTheIllustrationAt_5ec641 =>
      'Закрепить иллюстрацию сверху во время прокрутки текста';

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
      '«Тот, кто сделал добро весом в мельчайшую частицу, увидит его».';

  @override
  String get impactReportScreen_theHomeOfThe_4602d2 =>
      '«А ведь Последняя обитель — это настоящая жизнь! Если бы они только знали это». — 29:64';

  @override
  String get impactReportScreen_raceTowardsForgivenessFrom_94d614 =>
      '«Стремитесь к прощению вашего Господа и Раю...» — Сура Аль-Хадид 57:21';

  @override
  String get impactReportScreen_andWhatIsThe_7eec52 =>
      '«А земная жизнь — всего лишь наслаждение обольщением». — Сура Али Имран 3:185';

  @override
  String get impactReportScreen_indeedWithHardshipComes_ea97fa =>
      '«Воистину, за каждой тягостью наступает облегчение». — Сура Аш-Шарх 94:6';

  @override
  String get impactReportScreen_singleGoodDeedIn_c126b4 =>
      '«Одно доброе дело в Рамадан равно 70 в любой другой месяц».';

  @override
  String get impactReportScreen_theProphetSaidCharity_c154f4 =>
      'Пророк ﷺ сказал: садака не уменьшает богатства — она приумножает его. (Муслим)';

  @override
  String get impactReportScreen_smilingAtYourBrother_8f55e4 =>
      '«Улыбка брату — это садака». (Тирмизи)';

  @override
  String get impactReportScreen_theMostBelovedDeeds_f11906 =>
      '«Самые любимые дела для Аллаха — постоянные, даже если они малы». (Бухари)';

  @override
  String get impactReportScreen_inJannahIsWhat_ff6d55 =>
      '«В Раю есть то, чего не видел глаз, о чем не слышало ухо...» (Бухари)';

  @override
  String get impactReportScreen_twoRakatsAtFajr_c8b238 =>
      'Два ракаата сунны фаджра лучше этого мира и всего, что в нем. (Муслим)';

  @override
  String get impactReportScreen_everyStepTowardSalah_62962f =>
      'Каждый шаг к намазу стирает грех и возвышает степень. (Муслим)';

  @override
  String get impactReportScreen_everySeedYouDonate_618d1f =>
      'Каждый ваш Сид сажает дерево для кого-то другого';

  @override
  String get impactReportScreen_takeWealthWithYou_784e85 =>
      'Вы не можете забрать богатство. Только добрые дела, на которые оно было потрачено.';

  @override
  String get impactReportScreen_theAngelsRecordNothing_e03c03 =>
      'Ангелы записывают все. Один Субханаллах может быть тяжелее горы.';

  @override
  String get impactReportScreen_sadaqahIsTomorrow_794857 =>
      'Садака сегодня — это награда завтра.';

  @override
  String get impactReportScreen_heartThatGivesIs_4b6000 =>
      'Дающее сердце Аллах наполняет. Не оставляйте его пустым.';

  @override
  String get impactReportScreen_theReceiptWhatDid_d1c41b =>
      'Вот ваша запись. Что вы приготовили для себя?';

  @override
  String get impactReportScreen_imagineYourScaleOn_094d07 =>
      'Представьте свои весы в Судный день. Что вы добавляете туда сегодня?';

  @override
  String get impactReportScreen_theWorldIsBorrowed_2eeb50 =>
      'Мир временный. Ахират вечен. Вкладывайте с умом.';

  @override
  String get impactReportScreen_youBuryTheBody_bb5233 =>
      'Вы хороните тело — но не дела. Отправьте их вперед, пока можете.';

  @override
  String get impactReportScreen_righteousChildWhoPrays_7bcef4 =>
      'Праведный ребенок, милостыня или знания — три вечные инвестиции. (Муслим)';

  @override
  String get impactReportScreen_youWillMeetAllah_c19524 =>
      'Вы встретите Аллаха со своими делами. Сделайте сегодняшний день значимым.';

  @override
  String get impactReportScreen_noDeedIsToo_c04d50 =>
      'Ни одно дело не слишком мало для Того, кто считает атомы.';

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
      'Тот, кто совершит доброе дело, получит воздаяние, в десять раз большее.';

  @override
  String get impactReportScreen_whoeverReadsLetterFrom_36d74f =>
      'Тому, кто прочтет хотя бы одну букву из Корана, запишется одно доброе дело, а за каждое доброе дело воздается десятикратно.';

  @override
  String get impactReportScreen_twoHadithGrowThis_c8d4a2 =>
      'Два хадиса вместе приумножают это число:\\n\\n';

  @override
  String impactReportScreen_dhikrRecitedLifetime_669e2a(String arg1) {
    return '  Прочитано зикра (за все время): $arg1\\n';
  }

  @override
  String impactReportScreen_hasanat_64c7b6(String arg1) {
    return '  → Хасанаты: $arg1\\n\\n';
  }

  @override
  String impactReportScreen_ayahsReadLifetime_75eef6(String arg1) {
    return '  Прочитано аятов (за все время): $arg1\\n';
  }

  @override
  String impactReportScreen_totalHasanaat_c43112(String arg1) {
    return 'Всего хасанатов: $arg1';
  }

  @override
  String get impactReportScreen_whoeverSaysSubhanAllahiWa_4b6459 =>
      'Кто говорит Субханаллахи ва би-хамдихи 100 раз в день, его грехи прощаются...';

  @override
  String get impactReportScreen_subhanallahiWaBihamdihi_992976 =>
      'Субханаллахи ва би-хамдихи';

  @override
  String impactReportScreen_totalRecitations_5ed733(String arg1) {
    return 'Всего чтений: $arg1\\n';
  }

  @override
  String impactReportScreen_dividedByForgivenessCycles_4e175d(String arg1) {
    return 'Разделено на 100 → циклы прощения: $arg1';
  }

  @override
  String impactReportScreen_dividedByPalaces_6f066c(String arg1) {
    return 'Разделено на 10 → дворцы: $arg1';
  }

  @override
  String get impactReportScreen_laIlahaIllallahuWahdahu_895dde =>
      'Ля иляха илляллах вахдаху ля шарика лях...';

  @override
  String impactReportScreen_setsOfSetsSlaves_b43b31(String arg1, String arg2) {
    return 'Наборы по 10 → $arg1 наб. × 4 раба = $arg2';
  }

  @override
  String impactReportScreen_totalSalawatSent_cfe45e(String arg1) {
    return 'Всего салаватов: $arg1\\n';
  }

  @override
  String impactReportScreen_multipliedByBlessingsReceived_52810f(String arg1) {
    return 'Умножено на 10 → получено $arg1 благ';
  }

  @override
  String get impactReportScreen_protectionFromEvil_37b53a => 'Защита от зла';

  @override
  String get impactReportScreen_goodHealthProtection_058808 =>
      'Крепкое здоровье и защита';

  @override
  String impactReportScreen_totalInvocations_1fd02b(String arg1) {
    return 'Всего дуа: $arg1';
  }

  @override
  String impactReportScreen_dividedByQuranCompletions_b9a013(String arg1) {
    return 'Разделено на 3 → $arg1 завершений Корана';
  }

  @override
  String impactReportScreen_564740_564740(String _monthActiveDays) {
    return '$_monthActiveDays';
  }

  @override
  String impactReportScreen_3dc421_3dc421(String arg1) {
    return '$arg1 ч. ';
  }

  @override
  String impactReportScreen_08990a_08990a(String arg1) {
    return '${arg1}m';
  }

  @override
  String impactReportScreen_ago_71107c(String arg1) {
    return '$arg1 мес. назад';
  }

  @override
  String impactReportScreen_moAgo_325a71(String arg1) {
    return '$arg1 мес. назад';
  }

  @override
  String impactReportScreen_failed_190558(String e) {
    return 'Ошибка: $e';
  }

  @override
  String impactReportScreen_funded_add009(String arg1) {
    return 'Профинансировано на $arg1%';
  }

  @override
  String get impactReportScreen_yourLifetimeImpact_8bfdcd =>
      'Ваше влияние за все время';

  @override
  String get impactReportScreen_startYourImpactJourney_1ae8c4 =>
      'Начните свой путь благодеяний';

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
    return '+$arg1 Сидс';
  }

  @override
  String get levelScreen_laIlahaIllallah_e8c26b => 'Ля иляха илляллах x100';

  @override
  String levelScreen_seedsBoost_464454(String arg1) {
    return 'Буст Сидс ×$arg1';
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
    return '$current / $arg1 дн.';
  }

  @override
  String levelScreen_dayStreak_df2abf(String arg1) {
    return 'Серия $arg1 дн.';
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
  String get quranMini_inTheNameOf_46925d =>
      'Во имя Аллаха, Милостивого, Милосердного.';

  @override
  String get quranMini_allPraiseBelongsTo_2d51df =>
      'Хвала Аллаху, Господу миров.';

  @override
  String orphansGridScreen_36cd3b_36cd3b(String arg1, String arg2) {
    return '$arg1 · $arg2';
  }

  @override
  String orphanDetailScreen_years_debb46(String arg1) {
    return '$arg1 лет';
  }

  @override
  String orphanDetailScreen_ofSeeds_2a29fc(String arg1, String arg2) {
    return '$arg1 из $arg2 Сидс';
  }

  @override
  String orphanDetailScreen_through_2cdb72(String arg1) {
    return 'Через $arg1';
  }

  @override
  String get orphanDetailScreen_andTheyGiveFood_7ddcff =>
      'Они дают пищу беднякам, сиротам и пленникам, несмотря на любовь к ней.';

  @override
  String orphanDetailScreen_ago_71107c(String arg1) {
    return '$arg1 мес. назад';
  }

  @override
  String orphanDetailScreen_moAgo_325a71(String arg1) {
    return '$arg1 мес. назад';
  }

  @override
  String orphanDetailScreen_seeds_30d8dc(String _availablePoints) {
    return '$_availablePoints Сидс';
  }

  @override
  String orphanDetailScreen_sponsor_b34bcf(String arg1) {
    return 'Спонсировать $arg1';
  }

  @override
  String orphanDetailScreen_jazakallahKhayranSeedsSponsored_316bec(
    String amount,
  ) {
    return 'Джазак Аллах Хайран! Спонсировано $amount Сидс.';
  }

  @override
  String orphanDetailScreen_chooseHowManySeeds_b69aa2(String arg1) {
    return 'Выберите, сколько Сидс пожертвовать. Минимум $arg1.';
  }

  @override
  String orphanDetailScreen_yourBalanceSeeds_f8045b(String arg1) {
    return 'Ваш баланс: $arg1 Сидс';
  }

  @override
  String get profileSettingsScreen_nameCannotBeEmpty_c737ab =>
      'Имя не может быть пустым';

  @override
  String get profileSettingsScreen_signedInWithGoogle_17e053 =>
      'Вход через Google';

  @override
  String get profileSettingsScreen_signedInWithQuran_2e1ffc =>
      'Вход через Quran.com';

  @override
  String get profileSettingsScreen_signedInWithEmail_dd881f => 'Вход по Email';

  @override
  String profileSettingsScreen_seeds_53d666(String arg1) {
    return '$arg1 Сидс';
  }

  @override
  String get profileSettingsScreen_guidesFAQsAndHow_b990d6 =>
      'Руководства, ЧаВо и инструкции';

  @override
  String get profileSettingsScreen_somethingNotWorkingTell_07f659 =>
      'Что-то не работает? Напишите нам';

  @override
  String projectDetailScreen_organisedBy_8b317a(String sponsor) {
    return 'Организатор: $sponsor\\n\\n';
  }

  @override
  String get projectDetailScreen_fundedSoFarEvery_dab3fd =>
      'Уже профинансировано, каждый Сид важен!\\n\\n';

  @override
  String get projectDetailScreen_openSabiqRewardsApp_cdda14 =>
      'Откройте Sabiq Rewards, чтобы пожертвовать Сидс и получить награду.\\n';

  @override
  String get projectDetailScreen_sabiqrewardsSadaqahIslamicCharity_663ba5 =>
      '#SabiqRewards #Садака #Благотворительность';

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
      'Пожертвуйте для оказания срочной помощи палестинцам, сталкивающимся с нехваткой еды, воды и медикаментов...';

  @override
  String projectDetailScreen_seeds_47387f(String arg1) {
    return '$arg1 Сидс';
  }

  @override
  String projectDetailScreen_e4e562_e4e562(String arg1) {
    return '$arg1%';
  }

  @override
  String projectDetailScreen_ago_71107c(String arg1) {
    return '$arg1 мес. назад';
  }

  @override
  String projectDetailScreen_moAgo_325a71(String arg1) {
    return '$arg1 мес. назад';
  }

  @override
  String quranHubScreen_saved_9c28a3(String arg1) {
    return '$arg1 сохранено';
  }

  @override
  String get quranScreen_couldNotLoadAyah_62f120 =>
      'Не удалось загрузить аят. Пожалуйста, повторите.';

  @override
  String get quranScreen_noConnectionCachedData_e5a215 =>
      'Нет соединения. Могут быть доступны кэшированные данные.';

  @override
  String quranScreen_ayahs_c98642(String arg1) {
    return 'Аятов: $arg1';
  }

  @override
  String get quranScreen_couldNotRemoveBookmark_699a82 =>
      'Не удалось удалить закладку, пожалуйста, повторите';

  @override
  String quranScreen_removedBookmark_d7a16a(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'Закладка удалена: $_surahName $_surah:$_ayah';
  }

  @override
  String get quranScreen_couldNotSaveBookmark_976448 =>
      'Не удалось сохранить закладку, пожалуйста, повторите';

  @override
  String quranScreen_bookmarked_2c6203(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'В закладках: $_surahName $_surah:$_ayah';
  }

  @override
  String quranScreen_tafsir_391c0d(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'Тафсир · $_surahName $_surah:$_ayah';
  }

  @override
  String get quranScreen_addedToFavourites_b3cce0 => '♥️ Добавлено в избранное';

  @override
  String quranScreen_pt_9e58e8(String arg1) {
    return '$arg1 оч.';
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
    return 'Прочитано аятов: $_ayahsToday';
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
      'Непредвиденная ошибка при входе через Google';

  @override
  String get startJourneyScreen_connectedToQuranCom_c0c631 =>
      'Подключено к Quran.com';

  @override
  String tafsirScreen_verses_fed624(String arg1) {
    return 'Аятов: $arg1';
  }

  @override
  String tafsirScreen_ayahOf_63c42b(String _ayah, String _surahLen) {
    return 'Аят $_ayah из $_surahLen';
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
      'Вы должны войти в систему, чтобы сделать пожертвование.';

  @override
  String get donationService_donationCouldNotBe_074195 =>
      'Не удалось обработать пожертвование в данный момент.';

  @override
  String get donationService_anUnexpectedNetworkError_914b7a =>
      'Произошла непредвиденная ошибка сети.';

  @override
  String get donationService_sponsorshipReceived_671201 =>
      'Спонсорство получено 💝';

  @override
  String donationService_youSponsoredSeedsJazak_7711e1(String amount) {
    return 'Вы спонсировали $amount Сидс · джазак Аллах хайр.';
  }

  @override
  String get donationService_sponsorshipCouldNotBe_55003e =>
      'Не удалось обработать спонсорство в данный момент.';

  @override
  String get streakService_warmingUp_b1687b => 'Разминка';

  @override
  String get streakService_oneWeek_4f98dc => 'Одна неделя';

  @override
  String get streakService_twoWeeks_9a2d93 => 'Две недели';

  @override
  String get streakService_oneMonth_35eb01 => 'Один месяц';

  @override
  String get streakService_twoMonths_84d275 => 'Два месяца';

  @override
  String get streakService_theCenturion_f1de7f => 'Сотник';

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
    return '$title • Уровень $level';
  }

  @override
  String get xpService_newBadgeUnlocked_2c8d0e => 'Открыт новый значок 🏆';

  @override
  String get xpService_dailyLoginBonus_d011fa => 'Бонус за ежедневный вход';

  @override
  String xpService_seedsWelcomeBack_47888a(String arg1) {
    return '+$arg1 Сидс · с возвращением!';
  }

  @override
  String get xpService_daySealed_037a56 => 'День завершен 🌙';

  @override
  String xpService_sabiqSeedsConfirmedBonus_702902(
    String flushed,
    String bonus,
  ) {
    return '+$flushed Сабик Сидс подтверждено! (бонус $bonus за завершение)';
  }

  @override
  String xpService_sabiqSeedsConfirmed_34969c(String flushed) {
    return '+$flushed Сабик Сидс подтверждено!';
  }

  @override
  String get dhikrExitCelebration_everyBreathCounts_45b3df =>
      'Каждый вдох имеет значение.';

  @override
  String get impactAnimation_yourRewardHasBeen_e3d106 =>
      'Ваша награда была записана.';

  @override
  String get motivationalPopup_verilyWithHardshipComes_f23637 =>
      'Воистину, за тягостью наступает облегчение.\\nКаждое испытание — это дверь к большему благу.';

  @override
  String get motivationalPopup_quranAlInshirah_d81f8a => 'Коран • Аш-Шарх 94:6';

  @override
  String get motivationalPopup_quranAlAnkabut_8e938e =>
      'Коран • Аль-Анкабут 29:45';

  @override
  String get motivationalPopup_quranAlBaqarah_8bb10e =>
      'Коран • Аль-Бакара 2:152';

  @override
  String get motivationalPopup_quranAnNahl_74d608 => 'Коран • Ан-Нахль 16:18';

  @override
  String get motivationalPopup_makeYourTimePrecious_049aae =>
      'Цените свое время.\\nПоделитесь благом с другом сегодня,\\nкаждое доброе дело — это садака.';

  @override
  String get motivationalPopup_guideOthersToGood_6105c4 =>
      'Указавшему на благое полагается такая же награда.';

  @override
  String get motivationalPopup_theBestOfPeople_1f6906 =>
      'Лучшие из людей — самые полезные для других.';

  @override
  String get motivationalPopup_verilyInTheRemembrance_16476d =>
      'Воистину, поминанием Аллаха\\nутешаются сердца.';

  @override
  String get motivationalPopup_remindYourselfTimeIs_38ae33 =>
      'Помните, время — это самая ценная садака.';

  @override
  String get motivationalPopup_yourTimeIsYour_be6731 =>
      'Ваше время — ваш самый\\nценный актив. Вкладывайте его с умом\\nв то, что останется навсегда.';

  @override
  String get motivationalPopup_quranAlAnfal_b10486 => 'Коран • Аль-Анфаль 8:28';

  @override
  String get motivationalPopup_takeAdvantageOfFive_e573fd =>
      'Используй пять вещей прежде других пяти.';

  @override
  String motivationalPopup_seeds_3a9c69(String arg1) {
    return '+$arg1 Сидс';
  }

  @override
  String get motivationalPopup_completeNowEarnSeeds_16ea6e =>
      'Завершите сейчас → получите бонус +50 Сидс';

  @override
  String get motivationalPopup_finishYourAzkaarEarn_e264fa =>
      'Завершите азкар → получите бонус +30 Сидс';

  @override
  String get motivationalPopup_shareSabiqWithSomeone_c60dcc =>
      'Поделитесь Сабик → получите +100 Сидс';

  @override
  String get motivationalPopup_keepYourSpiritualMomentum_0f172c =>
      'Продолжайте ваш духовный рост\\nи смотрите, как растут ваши Сидс ✨';

  @override
  String get projectMediaCarousel_couldNotLoadVideo_deb8dd =>
      'Не удалось загрузить видео';

  @override
  String get quranExitCelebration_beautifulRecitation_9d2655 =>
      'Прекрасное чтение.';

  @override
  String get quranExitCelebration_everyMomentCounts_fddb4c =>
      'Каждое мгновение важно.';

  @override
  String sealCoinAnimation_e16fa4_e16fa4(String arg1) {
    return '+$arg1 ';
  }

  @override
  String impactReportScreen_totalHasanatFromQuran(String n) {
    return 'Всего хасанатов от Корана: $n';
  }

  @override
  String impactReportScreen_totalTreesPlanted(String n) {
    return 'Всего посажено деревьев: $n';
  }

  @override
  String impactReportScreen_totalTreasures(String n) {
    return 'Всего сокровищ: $n';
  }

  @override
  String impactReportScreen_multipliedByGates(String n) {
    return 'Умножено на 8 врат → открыты $n раз';
  }

  @override
  String impactReportScreen_bonusHasanaat(String n) {
    return 'Бонусные хасанаты: $n';
  }

  @override
  String impactReportScreen_totalDonatedSeeds(String n, String seeds) {
    return 'Всего пожертвовано: $n Сидс';
  }

  @override
  String get dashboardScreen_dashboardLoadFailed =>
      'Не удалось загрузить панель. Попробуйте еще раз.';

  @override
  String get zikrLabel => 'Зикр';

  @override
  String get quranLabel => 'Коран';

  @override
  String streakService_dayStreakBody(String days, String type, String bonus) {
    return 'Серия $type $days дн. · бонус +$bonus Сидс разблокирован';
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
  String get donationService_donationReceivedTitle =>
      'Пожертвование получено 💝';

  @override
  String donationService_youDonatedSeeds(String amount) {
    return 'Вы пожертвовали $amount Сидс · джазак Аллах хайр.';
  }

  @override
  String streakService_60a570_60a570(Object arg1, Object localLabel) {
    return '$arg1 $localLabel';
  }

  @override
  String xpService_badgeEarnedBody(String name) {
    return 'Вы получили значок «$name».';
  }

  @override
  String get localReminderScheduler_channelName => 'Уведомления Sabiq Rewards';

  @override
  String get localReminderScheduler_morningTitle => 'Утренний зикр';

  @override
  String get localReminderScheduler_morningBody =>
      'Начните день под защитой Аллаха — прочитайте утренний зикр.';

  @override
  String get localReminderScheduler_astaghfirTitle => 'Время для истигфара';

  @override
  String get localReminderScheduler_astaghfirBody =>
      '«Астагфируллах» очищает сердце и открывает двери удела. Сделайте паузу на минуту.';

  @override
  String get localReminderScheduler_eveningTitle => 'Вечерний зикр';

  @override
  String get localReminderScheduler_eveningBody =>
      'Защитите себя на ночь — прочитайте вечерний зикр.';

  @override
  String get localReminderScheduler_sleepTitle => 'Время отдыха';

  @override
  String get localReminderScheduler_sleepBody =>
      'Завершите день зикром перед сном — Аят аль-Курси, 3 последние суры и дуа перед сном.';

  @override
  String get localReminderScheduler_kahfAmTitle =>
      'Сегодня пятница — прочитайте суру Аль-Кахф';

  @override
  String get localReminderScheduler_kahfBody =>
      'Тот, кто читает суру Аль-Кахф в пятницу, будет освещен светом между двумя пятницами.';

  @override
  String get localReminderScheduler_salawatTitle => 'Салават в пятницу';

  @override
  String get localReminderScheduler_salawatBody =>
      'Больше читайте салават Пророку ﷺ сегодня — деяния пятницы предстают перед ним.';

  @override
  String get localReminderScheduler_kahfPmTitle =>
      'Не забудьте прочитать суру Аль-Кахф';

  @override
  String get localReminderScheduler_kahfPmBody =>
      'Пару часов до Магриба — завершите суру Аль-Кахф, если еще не читали.';

  @override
  String get liveNotificationService_validateChannelDesc =>
      'Напоминания о сохранении Сидс до полуночи.';

  @override
  String get liveNotificationService_validateTicker =>
      'Сохраните ваши Сидс до полуночи';

  @override
  String get liveNotificationService_validateTitle =>
      'Сохраните ваши Сидс до полуночи!';

  @override
  String liveNotificationService_validateBody(String n) {
    return 'У вас $n несобранных Сидс. Нажмите «Завершить день» до полуночи, иначе они сгорят.';
  }

  @override
  String liveNotificationService_ayatRead(String n) {
    return 'Сегодня прочитано аятов: $n 📖';
  }

  @override
  String liveNotificationService_readQuranTime(String time) {
    return '$time за чтением Корана сегодня ⏱️';
  }

  @override
  String get liveNotificationService_nothingRead =>
      'Сегодня Коран не читался 📖';

  @override
  String liveNotificationService_dhikrCompleted(String n) {
    return 'Зикров завершено сегодня: $n 📿';
  }

  @override
  String liveNotificationService_tickerBusy(String ayah, String dhikr) {
    return 'Аятов: $ayah · Зикров сегодня: $dhikr';
  }

  @override
  String get liveNotificationService_tickerIdle =>
      'Продолжайте читать Коран и делать зикр!';

  @override
  String get liveNotificationService_channelDesc =>
      'Прогресс Корана и зикра сегодня';

  @override
  String get liveNotificationService_seedsToday => 'Ваши Сидс сегодня ✨';

  @override
  String get liveNotificationService_summary => 'Нажмите, чтобы открыть Сабик';

  @override
  String get quranApiService_notConnected => 'Не подключено к Quran.com';

  @override
  String get quranApiService_notSignedIn => 'Вы не вошли в Noor';

  @override
  String quranApiService_syncFailedPush(String n) {
    return 'Синхронизация не удалась, $n закладок не отправлено на Quran.com (проверьте токен / endpoint).';
  }

  @override
  String get quranApiService_alreadyInSync => 'Закладки уже синхронизированы';

  @override
  String quranApiService_syncedBookmarks(String total, String up, String down) {
    return 'Синхронизировано $total закладок (отпр: $up, получ: $down)';
  }

  @override
  String quranApiService_syncFailedPartial(String n) {
    return ', $n с ошибкой';
  }

  @override
  String quranApiService_syncFailedGeneric(String error) {
    return 'Ошибка синхронизации: $error';
  }

  @override
  String get authScreen_dontHaveAnAccountSignUp =>
      'Нет аккаунта? Зарегистрироваться';

  @override
  String get dhikrExitCelebration_keepItUp => 'Так держать!';

  @override
  String get unknownError => 'Неизвестная ошибка';

  @override
  String get celebrationStatSeeds => 'Сидс';

  @override
  String get celebrationStatSeedsEarned => 'ПОЛУЧЕНО Сидс';

  @override
  String get celebrationStatAyahs => 'АЯТЫ';

  @override
  String get celebrationStatTime => 'ВРЕМЯ';

  @override
  String get celebrationStatStreak => 'СЕРИЯ';

  @override
  String get celebrationStreakStartToday => 'Начать сегодня';

  @override
  String celebrationDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дней',
      one: '1 день',
    );
    return '$_temp0';
  }
}
