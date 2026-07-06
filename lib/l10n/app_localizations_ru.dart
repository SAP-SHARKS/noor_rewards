// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get youSuffix => '(ты)';

  @override
  String get userFallback => 'Пользователь';

  @override
  String get youHaveDone => 'Вы сделали!';

  @override
  String get playAllBtn => 'Воспроизвести все';

  @override
  String get playBtn => 'Играть';

  @override
  String get readBtn => 'Читать';

  @override
  String get readOnce => 'Прочтите один раз';

  @override
  String readNTimes(int count) {
    return 'Прочтите $count раз';
  }

  @override
  String seedsEarnedToday(int count) {
    return '+$count Сабик Сидс заработан сегодня!';
  }

  @override
  String get catDailyRemembrance => 'ЕЖЕДНЕВНАЯ ПАМЯТЬ';

  @override
  String get catNightlyRemembrance => 'НОЧНЫЕ ВОСПОМИНАНИЯ';

  @override
  String get catYourSelection => 'ВАШ ВЫБОР';

  @override
  String get catContinuousRemembrance => 'НЕПРЕРЫВНАЯ ПАМЯТЬ';

  @override
  String get bannerDailyRemembrance =>
      'Ежедневное воспоминание\nприносит покой душе.';

  @override
  String get bannerMorningAdhkar =>
      'Утренний Адкар\nприносит мир душе и свет на путь.';

  @override
  String get bannerEveningAdhkar =>
      'Вечерний Азкар\nприносит спокойствие и защиту на ночь.';

  @override
  String get bannerYourSelection =>
      'Твои любимые слова\nвоспоминаний, которые следует держать близко к сердцу.';

  @override
  String get bannerContinuousRemembrance =>
      'Помни Аллаха\nмного, чтобы ты мог добиться успеха.';

  @override
  String get frequentlyReadByCommunity => 'Часто читаю';

  @override
  String get viewFullLeaderboard => 'Посмотреть полную таблицу лидеров';

  @override
  String get skip => 'Пропустить';

  @override
  String get continue_ => 'Далее';

  @override
  String get beginYourJourney => 'Начать путь';

  @override
  String get enterTheGarden => 'Войти в сад';

  @override
  String get bySigningUp =>
      'Регистрируясь, вы соглашаетесь с нашими Условиями и Политикой конфиденциальности';

  @override
  String get lightOfMercy => 'СВЕТ МИЛОСЕРДИЯ';

  @override
  String get noorRewards => 'Награды Сабика';

  @override
  String get startYourJourney => 'Начать путь';

  @override
  String get trackSpiritualGrowth =>
      'Отслеживайте духовный рост, присоединяйтесь к сообществу и получайте эксклюзивные награды за каждое доброе дело.';

  @override
  String get continueWithGoogle => 'Продолжить с Google';

  @override
  String get continueWithQuran => 'Продолжить с Quran.com';

  @override
  String get onboarding1Title => 'Мир вам';

  @override
  String get onboarding1Subtitle =>
      'Добро пожаловать в Sabiq Rewards, где каждое доброе дело приближает вас к милости и свету Аллаха.';

  @override
  String get onboarding2Title => 'Две награды.\nОдно деяние.';

  @override
  String get onboarding2Subtitle =>
      'Каждое прочитанное слово приносит вам Саваб, свет в вашей Ахира.\nВаши Sabiq Seeds Coin финансируют реальные дела, меняющие реальные жизни.';

  @override
  String get onboarding3Title => 'Всегда\nпомните Аллаха';

  @override
  String get onboarding3Subtitle =>
      'Сердце, помнящее Аллаха, обретает мир в каждом дыхании. Отслеживайте ежедневный зикр и позвольте каждой молитве быть учтённой.';

  @override
  String get onboarding4Title => 'Размышляй &\nРасти каждый день';

  @override
  String get onboarding4Subtitle =>
      'Коран, руководство для всего человечества. Открывайте аяты, ежедневные дуа и размышления, созданные для вашего пути.';

  @override
  String get onboarding5Title => 'Давай &\nПолучай благословение';

  @override
  String get onboarding5Subtitle =>
      'Садака гасит грех, как вода гасит огонь. Зарабатывайте награды за каждый акт милосердия и доброты.';

  @override
  String welcomeUser(String name) {
    return 'Добро пожаловать, $name 🌙';
  }

  @override
  String get gatesOfNoor =>
      'Врата света открыты.\nВаш духовный путь начинается сегодня.';

  @override
  String get earnNoorPoints => 'ЗАРАБАТЫВАЙТЕ СЕМЕНА';

  @override
  String get yourProgress => 'ВАШ ПРОГРЕСС';

  @override
  String get yourTotalNoorPoints => 'ВАШИ ВСЕ СЕМЕНА';

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
  String get noorPoints => 'Семена';

  @override
  String get readQuran => 'Читать Коран';

  @override
  String get inviteFriends => 'Пригласить друзей';

  @override
  String get communityImpact => 'Влияние сообщества';

  @override
  String get completedProjects => 'Завершённые проекты';

  @override
  String get yourContribution => 'Ваш вклад';

  @override
  String get yourReferralCode => 'ВАШ РЕФЕРАЛЬНЫЙ КОД';

  @override
  String get copyLink => 'Скопировать ссылку';

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
  String get viewCampaign => 'Просмотр кампании';

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
  String get shareMore => 'Поделиться ещё';

  @override
  String get noData => 'Данных пока нет';

  @override
  String get callYou => 'Как вас\\nназывать?';

  @override
  String get personaliseJourney =>
      'Персонализируйте свой духовный путь с помощью имени';

  @override
  String get whereFrom => 'Откуда\\nвы?';

  @override
  String get joinMuslims =>
      'Присоединяйтесь к мусульманам со всего мира в этом пути';

  @override
  String get whatBringsYou => 'Что привело\\nвас сюда?';

  @override
  String get chooseGoals =>
      'Выберите свои духовные цели, можно выбрать несколько';

  @override
  String get navHome => 'Главная';

  @override
  String get navJourney => 'Путь';

  @override
  String get navAkhirah => 'Ахира';

  @override
  String get navProfile => 'Профиль';

  @override
  String get communityLeaderboard => 'Таблица лидеров сообщества';

  @override
  String get topContributors => 'Лучшие участники по общим Семенам';

  @override
  String get myProfile => 'Мой профиль';

  @override
  String get startStreak => 'Начните свою серию сегодня!';

  @override
  String get alreadySealed => 'Уже подтверждено сегодня';

  @override
  String get sealTheDay => 'Подтвердить день';

  @override
  String get alhamdulillah => 'Альхамдулиллях!';

  @override
  String get levelSeeker => 'Искатель';

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
  String get todaysProgress => 'Прогресс за сегодня';

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
  String get browse => 'Обзор';

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
  String get prev => 'Назад';

  @override
  String get reciteMore => 'ЧИТАЙТЕ БОЛЬШЕ.';

  @override
  String get helpRealLives => 'ПОМОГИТЕ РЕАЛЬНЫМ ЖИЗНЯМ.';

  @override
  String get yourNoorPointsFundProjects =>
      'Ваши Семена финансируют эти проекты';

  @override
  String get youBothEarnPoints => 'Вы оба получаете 500 Семян!';

  @override
  String get reward => 'Награда';

  @override
  String get haveInviteCode => 'Есть код приглашения?';

  @override
  String get enterCode => 'Введите код…';

  @override
  String get apply => 'Применить';

  @override
  String get plantGoodDeeds => 'ЗАВОДИТЕ ДОБРЫЕ ДЕЛА';

  @override
  String get youDonated => 'Вы пожертвовали';

  @override
  String get seeDetailsForMore => 'Подробнее о проектах →';

  @override
  String get pts => 'Семена';

  @override
  String get funded => 'собрано';

  @override
  String bySponsor(String sponsor) {
    return 'От $sponsor';
  }

  @override
  String get viewCampaignDonate => 'Просмотр кампании и пожертвование';

  @override
  String get supportThisCause => 'Поддержать это дело';

  @override
  String get availableBalance => 'Доступный баланс:';

  @override
  String get donationAmount => 'Сумма пожертвования';

  @override
  String get points => 'Семена';

  @override
  String get donateEarnReward => 'Пожертвовать и получить награду';

  @override
  String get max => 'МАКС';

  @override
  String get leaderboard => 'Таблица лидеров';

  @override
  String get loadingDots => 'Загрузка…';

  @override
  String yourRank(String rank) {
    return 'Ваш ранг: #$rank';
  }

  @override
  String get outOf => 'Из';

  @override
  String get believers => 'верующих';

  @override
  String get topTenContributors => 'Топ-10 участников';

  @override
  String get ourCauses => 'Наши дела';

  @override
  String get donatePointsToSupport =>
      'Пожертвуйте Семена для поддержки реальных проектов';

  @override
  String get noActiveProjects => 'Сейчас нет активных проектов';

  @override
  String get checkBackSoon => 'Заходите позже, ин ша Аллах';

  @override
  String get messageCopied =>
      'Сообщение скопировано, поделитесь или вставьте в WhatsApp!';

  @override
  String get lvl => 'Ур.';

  @override
  String get journey => 'Путь';

  @override
  String get tabStreaks => 'Серии';

  @override
  String get tabProgress => 'Прогресс';

  @override
  String get tabBadges => 'Значки';

  @override
  String get tabChallenges => 'Испытания';

  @override
  String get allTime => 'За всё время';

  @override
  String ptsToLevel(String pts, String level) {
    return '$pts Семян до Уровня $level';
  }

  @override
  String dayStreak(String count) {
    return 'Серия $count дн.';
  }

  @override
  String get actions => 'действия';

  @override
  String get action => 'действие';

  @override
  String get breakdown => 'Разбивка';

  @override
  String get activityLog => 'Журнал активности';

  @override
  String get showLess => 'Свернуть';

  @override
  String get seeMore => 'Ещё';

  @override
  String get more => 'ещё';

  @override
  String noActivity(String period) {
    return 'Нет активности $period';
  }

  @override
  String get startEarningPts =>
      'Начните зарабатывать Семена: читайте Коран, делайте Зикр и Дуа.';

  @override
  String get howToEarnPts => 'Как заработать семена';

  @override
  String get readOneAyah => 'Прочитать 1 аят';

  @override
  String get completeOneJuz => 'Завершить 1 джуз';

  @override
  String get validateAndSupport => 'Подтвердить и поддержать';

  @override
  String get levelTiers => 'Уровни';

  @override
  String get basicFeatures => 'Базовые функции';

  @override
  String get customProfileThemes => 'Пользовательские темы профиля';

  @override
  String get leaderboardBadge => 'Значок таблицы лидеров';

  @override
  String get exclusiveVotingRights => 'Эксклюзивное право голоса';

  @override
  String get hallOfFameListing => 'Зал славы';

  @override
  String unlocks(String feature) {
    return 'Открывает: $feature';
  }

  @override
  String get now => 'СЕЙЧАС';

  @override
  String get trophyVault => 'Хранилище наград';

  @override
  String badgesCollected(String earned, String total) {
    return '$earned / $total значков собрано';
  }

  @override
  String percentComplete(String pct) {
    return '$pct% завершено';
  }

  @override
  String toUnlock(String count) {
    return '$count до открытия';
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
  String get specialEvents => 'Особые события';

  @override
  String get noActiveChallenges => 'Сейчас нет активных испытаний';

  @override
  String get checkBackChallenges =>
      'Заходите позже, скоро события Рамадана и Зуль-Хиджа!';

  @override
  String get ramadanChallenge => 'Испытание Рамадана';

  @override
  String get ramadanChallengeDesc =>
      '3× множитель очков • Особые значки • Цель: колодцы для общины';

  @override
  String get comingSoonStayConsistent => 'Скоро, будьте последовательны!';

  @override
  String get done => 'Готово!';

  @override
  String ptsBoost(String multiplier) {
    return 'Бонус Семян $multiplier×';
  }

  @override
  String ends(String date) {
    return 'Заканчивается $date';
  }

  @override
  String get loadingStreaks => 'Загрузка серий…';

  @override
  String get centurion => 'Центурион, Маша Аллах!';

  @override
  String get currentBestStreak => 'Лучшая текущая серия';

  @override
  String get last7Days => 'ПОСЛЕДНИЕ 7 ДНЕЙ';

  @override
  String get nextMilestone => 'СЛЕДУЮЩАЯ ВЕХА';

  @override
  String get allMilestones => 'ВСЕ ВЕХИ';

  @override
  String moreDaysToGo(String count) {
    return 'Осталось $count дн., продолжайте!';
  }

  @override
  String dayStreakLabel(String count) {
    return 'Серия $count дн.';
  }

  @override
  String best(String count) {
    return 'Лучшая $count';
  }

  @override
  String get dhikarAndDua => 'Зикр и дуа';

  @override
  String get listenTafsir => 'Слушать тафсир';

  @override
  String get challenge => 'Испытание';

  @override
  String get readListenTafsir => 'Читать и слушать тафсир';

  @override
  String get deepUnderstanding => 'Глубокое понимание Священного Корана';

  @override
  String get earnPointsTafsir =>
      'Получайте Семена за каждые 10 минут прослушивания Тафсира';

  @override
  String get featuredSurahs => 'Избранные суры';

  @override
  String get browseAll114 => 'Все 114 сур';

  @override
  String verses(String count) {
    return '$count аятов';
  }

  @override
  String ayahN(String n) {
    return 'Аят $n';
  }

  @override
  String get readTafsir => 'Читать тафсир';

  @override
  String get translation => 'Перевод';

  @override
  String get loadingTafsir => 'Загрузка тафсира...';

  @override
  String get tafsirNotAvailable => 'Тафсир недоступен для этого аята.';

  @override
  String get arabicScripture => 'Арабский текст';

  @override
  String get urduScripture => 'Текст на урду';

  @override
  String get englishCommentary => 'Комментарий на английском';

  @override
  String get previous => 'Предыдущий';

  @override
  String get nextAyah => 'Следующий аят';

  @override
  String get readingSettings => 'Настройки чтения';

  @override
  String get tafsirSource => 'ИСТОЧНИК ТАФСИРА';

  @override
  String get reciter => 'ЧТЕЦ';

  @override
  String get display => 'ОТОБРАЖЕНИЕ';

  @override
  String get showArabicText => 'Показать арабский текст';

  @override
  String get darkMode => 'Тёмный режим';

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
      'Аудио ещё не загружено. Пожалуйста, подождите...';

  @override
  String playbackError(String message) {
    return 'Ошибка воспроизведения: $message';
  }

  @override
  String get audioUnavailable =>
      'Аудио недоступно, проверьте подключение к интернету.';

  @override
  String get signInToSaveFavourites => 'Войдите, чтобы сохранить избранное';

  @override
  String get addedToFavourites => 'Добавлено в избранное';

  @override
  String get removedFromFavourites => 'Удалено из избранного';

  @override
  String get appearance => 'ВНЕШНИЙ ВИД';

  @override
  String get appearanceLabel => 'Появление';

  @override
  String get freezeIllustration => 'Заморозить иллюстрацию';

  @override
  String get comfortableNightReading => 'Удобное чтение в ночное время';

  @override
  String get focusMode => 'Режим фокуса (на весь экран)';

  @override
  String get focusModeDesc => 'Скрыть панели для чтения без отвлечений';

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
  String get readingLayout => 'МАКЕТ ЧТЕНИЯ';

  @override
  String get showTranslation => 'Показать перевод';

  @override
  String get displayMeaningBelow => 'Отображать значение под каждым аятом';

  @override
  String get showDailyProgress => 'Показать ежедневный прогресс';

  @override
  String get progressBarAyahCount => 'Прогресс-бар и счётчик аятов';

  @override
  String get showPointsBanner => 'Показать баннер Семян';

  @override
  String get noorPointsNotificationStrip => '+ Полоса уведомлений Семян';

  @override
  String get showSurahHeader => 'Показать заголовок суры';

  @override
  String get surahNameBanner => 'Баннер с названием суры вверху страницы';

  @override
  String get audioPlayback => 'АУДИО И ВОСПРОИЗВЕДЕНИЕ';

  @override
  String get autoAdvance => 'Автопереход';

  @override
  String get moveToNextVerse =>
      'Переходить к следующему аяту после окончания аудио';

  @override
  String get repeatCurrentVerse => 'Повторять текущий аят';

  @override
  String get loopAyahAudio => 'Зациклить воспроизведение аудио этого аята';

  @override
  String get notificationsAlerts => 'УВЕДОМЛЕНИЯ И ОПОВЕЩЕНИЯ';

  @override
  String get dailyReadingReminder => 'Ежедневное напоминание о чтении';

  @override
  String get pushReminderReadQuran => 'Напоминание читать Коран каждый день';

  @override
  String get milestoneSoundAlerts => 'Звуковые оповещения о достижениях';

  @override
  String get chimeAtMilestones => 'Сигнал при достижении 10, 25, 50 аятов';

  @override
  String get advanced => 'ДОПОЛНИТЕЛЬНО';

  @override
  String get wordByWordMode => 'Пословный режим';

  @override
  String get showWordMeaning =>
      'Показывать значение каждого арабского слова на английском';

  @override
  String get translationLanguage => 'Язык перевода';

  @override
  String translationsAvailable(String count) {
    return '$count переводов доступно';
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
    return '$count аятов прочитано';
  }

  @override
  String get goalAyahs => 'Цель: 50 аятов/день';

  @override
  String get nextPage => 'Следующая страница';

  @override
  String get exit => 'Выход';

  @override
  String get mushafSettings => 'Настройки мусхафа';

  @override
  String get readingMode => 'РЕЖИМ ЧТЕНИЯ';

  @override
  String get scroll => 'Прокрутка';

  @override
  String get pageFlip => 'Перелистывание';

  @override
  String get translationLabel => 'ПЕРЕВОД';

  @override
  String get off => 'Выкл.';

  @override
  String get splitView => 'Раздельный вид';

  @override
  String get script => 'ШРИФТ';

  @override
  String get actionsLabel => 'ДЕЙСТВИЯ';

  @override
  String get pageBookmarked => 'Страница добавлена в закладки!';

  @override
  String get loadingQuran => 'Загрузка Корана…';

  @override
  String get earnPointsPerVerse =>
      'Получайте +10 Семян за каждый прочитанный аят';

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
    return '$count сохранено';
  }

  @override
  String noSavedYet(String title) {
    return 'Нет сохранённых $title';
  }

  @override
  String get tapToSaveVerses =>
      'Нажмите на иконку сердца/закладки при чтении, чтобы сохранить аяты.';

  @override
  String get randomVerse => 'Случайный аят';

  @override
  String get sunnahFriday => 'Пятничная сунна';

  @override
  String get resume => 'Продолжить';

  @override
  String get loadingWordTranslations => 'Загрузка пословных переводов…';

  @override
  String get wordDataUnavailable =>
      'Данные слов недоступны. Проверьте подключение.';

  @override
  String get duaAzkarSettings => 'Настройки дуа и азкаров';

  @override
  String get showTransliteration => 'Показать транслитерацию';

  @override
  String get showIllustration => 'Показать иллюстрацию';

  @override
  String get hideIllustrationArea => 'Скрыть область иллюстрации';

  @override
  String get arabicFontStyle => 'Стиль арабского шрифта';

  @override
  String get dailyAzkarComplete => 'Ежедневные азкары завершены!';

  @override
  String get dailyAzkarBonusMsg =>
      'Маша Аллах! Вы выполнили ежедневные азкары и заработали бонус +50 Sabiq Seeds.';

  @override
  String get awesome => 'Отлично';

  @override
  String get betweenSubhSunrise => 'Между Субх-и-Садик и восходом';

  @override
  String get betweenAsrMaghrib => 'Между Асром и Магрибом';

  @override
  String get beforeSleeping => 'Перед сном';

  @override
  String get uponWakingUp => 'При пробуждении';

  @override
  String get afterEachPrayer => 'После каждого намаза';

  @override
  String get anytimeEspeciallyAfterPrayer =>
      'В любое время, особенно после намаза';

  @override
  String get anytimeMorningEvening => 'В любое время, утром и вечером';

  @override
  String get duringTheNight => 'В ночное время';

  @override
  String get anytime => 'В любое время';

  @override
  String get asPerSunnah => 'Согласно Сунне';

  @override
  String get whenEatingDrinking => 'При приёме пищи или питья';

  @override
  String get enteringLeavingHome => 'При входе / выходе из дома';

  @override
  String get beforeAfterWudu => 'До или после вуду';

  @override
  String get whenGettingDressed => 'При одевании';

  @override
  String get uponBadDream => 'При плохом сне';

  @override
  String get forUmmahAnytime => 'За Умму, в любое время';

  @override
  String get all => 'Все';

  @override
  String get general => 'Общее';

  @override
  String get startNow => 'Начать сейчас';

  @override
  String get markAsDone => 'Отметить как выполненное';

  @override
  String get enterCustomCount => 'Введите свой счёт';

  @override
  String get resetToDefault => 'Сбросить по умолчанию';

  @override
  String get noAzkarFound => 'Азкары не найдены.';

  @override
  String get reference => 'Источник';

  @override
  String get benefit => 'Польза';

  @override
  String continueAdhkar(String category) {
    return 'Продолжите $category азкары с того места, где остановились.';
  }

  @override
  String get set => 'подход';

  @override
  String get sets => 'подходов';

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
  String get quranicDuas => 'Коранические дуа';

  @override
  String get istighfar => 'Истигфар';

  @override
  String get dhikarAllTimes => 'Зикр на все времена';

  @override
  String get namesOfAllah => 'Имена Аллаха';

  @override
  String get nightmares => 'Кошмары';

  @override
  String get wakingUp => 'Пробуждение';

  @override
  String get clothes => 'Одежда';

  @override
  String get wudu => 'Вуду';

  @override
  String get foodAndDrink => 'Еда и питьё';

  @override
  String get home => 'Дом';

  @override
  String get istikharah => 'Истихара';

  @override
  String get adaanAndMasjid => 'Азан и мечеть';

  @override
  String get diffAndHappy => 'Трудности и радость';

  @override
  String get imanProtect => 'Защита имана';

  @override
  String get travel => 'Путешествие';

  @override
  String get shopping => 'Покупки';

  @override
  String get marriage => 'Брак';

  @override
  String get social => 'Общество';

  @override
  String get nature => 'Природа';

  @override
  String get death => 'Смерть';

  @override
  String get gatherings => 'Собрания';

  @override
  String get hajjAndUmrah => 'Хадж и Умра';

  @override
  String get dailyEssentials => 'Ежедневное важное';

  @override
  String get akhirahBalance => 'Баланс Ахира';

  @override
  String get priceless => 'Бесценно';

  @override
  String get beyondWorldCanHold => 'Больше, чем может вместить этот мир';

  @override
  String deedsToday(String count) {
    return '+$count деяний сегодня';
  }

  @override
  String deedsThisWeek(String count) {
    return '+$count за эту неделю';
  }

  @override
  String bestDayStreak(String count) {
    return 'Лучшая: серия $count дн.';
  }

  @override
  String get donateMoreEarn => 'Пожертвуйте больше и заработайте';

  @override
  String get yourHoldings => 'Ваши накопления';

  @override
  String get seeAll => 'Все →';

  @override
  String get hasanaatEarned => 'Заработанные хасанаты';

  @override
  String get recordedInBookOfDeeds => 'Записано в вашу Книгу Деяний';

  @override
  String get treesInJannah => 'Деревья в Джаннате';

  @override
  String get fromTasbih => 'От СубханАллах и тасбиха';

  @override
  String get sinsForgiven => 'Прощённые грехи';

  @override
  String get likeTheFoamOfSea => 'Подобно пене морской';

  @override
  String get palacesBuilt => 'Построенные дворцы';

  @override
  String get surahIkhlasAndSunnahs => 'Сура Ихлас и Сунны';

  @override
  String get treasuresOfJannah => 'Сокровища Джанната';

  @override
  String get slavesFreedom => 'Освобождённые рабы';

  @override
  String get equivalentReward => 'Эквивалентная награда получена';

  @override
  String get sadaqahGiven => 'Садака отдана';

  @override
  String get pointsDonatedToCommunity => 'Семена пожертвованы сообществу';

  @override
  String get allTimeLabel => 'За всё время';

  @override
  String get worshipActivity => 'Активность поклонения';

  @override
  String get timeSpentInRemembrance => 'Время, проведённое в поминании';

  @override
  String get noorPointsSummary => 'Сводка семян';

  @override
  String get totalPoints => 'Всего семян';

  @override
  String get title => 'Название';

  @override
  String get everyDeedRecorded => 'Каждое деяние записано. Продолжайте!';

  @override
  String yourAvailable(String pts) {
    return 'Доступно: $pts Семян';
  }

  @override
  String jazakAllahDonated(String pts) {
    return 'ДжазакАллах! $pts Семян пожертвовано';
  }

  @override
  String get insufficientPoints => 'Недостаточно Семян';

  @override
  String donatePoints(String pts) {
    return 'Пожертвовать $pts Семян';
  }

  @override
  String get everyRecitationCanChange => 'Каждое чтение может\nизменить жизнь';

  @override
  String get fullyFunded => 'Полностью собрано ✓';

  @override
  String get noPointsAvailable => 'Нет доступных Семян';

  @override
  String get communityProgress => 'Прогресс сообщества';

  @override
  String myContribution(String pts) {
    return 'Мой вклад: $pts баллов';
  }

  @override
  String get ptsRaised => 'очков собрано';

  @override
  String ofGoal(String goal) {
    return 'из $goal очк. цели';
  }

  @override
  String get daysLeft => 'дней осталось';

  @override
  String get lastDay => 'Последний день!';

  @override
  String get deadline => 'срок';

  @override
  String get campaignStory => 'История кампании';

  @override
  String updates(String count) {
    return 'Обновления ($count)';
  }

  @override
  String get campaign => 'Кампания';

  @override
  String get noStoryYet => 'История ещё не добавлена.';

  @override
  String get checkAdminPanel =>
      'Проверьте панель администратора, чтобы добавить историю кампании.';

  @override
  String get noUpdatesYet => 'Обновлений пока нет.';

  @override
  String get checkBackForNews => 'Заходите позже за новостями кампании.';

  @override
  String get yesterday => 'Вчера';

  @override
  String daysAgo(String count) {
    return '$count дн. назад';
  }

  @override
  String get shareCampaign => 'Поделиться кампанией';

  @override
  String get spreadTheWord =>
      'Расскажите другим и помогите этому делу достичь цели.';

  @override
  String get shareViaWhatsApp => 'Поделиться через WhatsApp';

  @override
  String get moreSharingOptions => 'Другие способы поделиться…';

  @override
  String get slideToAdjust => 'Сдвиньте для настройки';

  @override
  String get balance => 'Баланс';

  @override
  String get loadingYourReport => 'Загрузка вашего отчёта…';

  @override
  String get profileUpdated => 'Профиль обновлён ✓';

  @override
  String get couldNotSave => 'Не удалось сохранить, попробуйте ещё раз';

  @override
  String get photoUpdated => 'Фото обновлено ✓';

  @override
  String get couldNotUploadPhoto =>
      'Не удалось загрузить фото, попробуйте ещё раз';

  @override
  String get changeProfilePhoto => 'Изменить фото профиля';

  @override
  String get takeAPhoto => 'Сделать фото';

  @override
  String get chooseFromLibrary => 'Выбрать из галереи';

  @override
  String get removePhoto => 'Удалить фото';

  @override
  String get photoRemoved => 'Фото удалено';

  @override
  String get couldNotRemovePhoto => 'Не удалось удалить фото';

  @override
  String get signOutQuestion => 'Выйти?';

  @override
  String get progressSafelyStored =>
      'Ваш прогресс надёжно сохранён. Вы можете войти снова в любое время.';

  @override
  String get accountInformation => 'Информация об аккаунте';

  @override
  String get preferences => 'Предпочтения';

  @override
  String get helpAndSupport => 'Помощь и поддержка';

  @override
  String get profilePhoto => 'Фото профиля';

  @override
  String get tapEditToChange => 'Нажмите «Изменить», чтобы сменить фото';

  @override
  String get tapEditToAdd => 'Нажмите «Изменить», чтобы добавить фото';

  @override
  String get edit => 'Изменить';

  @override
  String get displayName => 'Отображаемое имя';

  @override
  String get yourName => 'Ваше имя';

  @override
  String get email => 'Эл. почта';

  @override
  String get country => 'Страна';

  @override
  String get countryHint => 'напр. Россия, Казахстан…';

  @override
  String get notifications => 'Уведомления';

  @override
  String get notifOnDesc => 'Награды, серии, пожертвования и прочее';

  @override
  String get notifOffDesc => 'Отключены, новых оповещений не будет';

  @override
  String get viewNotificationsInbox => 'Просмотреть уведомления';

  @override
  String nNew(String n) {
    return '$n новых';
  }

  @override
  String get helpCenter => 'Центр помощи';

  @override
  String get reportABug => 'Сообщить об ошибке';

  @override
  String get aboutNoorRewards => 'О Sabiq Rewards';

  @override
  String get builtWithLove => 'Создано с любовью для Уммы';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get howWeProtectData => 'Как мы защищаем ваши данные';

  @override
  String get bugReportBody =>
      'Нашли ошибку? Напишите нам, и мы исправим её как можно скорее.';

  @override
  String get aboutBody =>
      'Создано с любовью для мировой мусульманской уммы.\nПолучайте Семена, развивая исламские привычки.\nЖертвуйте Семена для поддержки реальных проектов сообщества.';

  @override
  String get howToEarnQuestion => 'Как заработать Семена?';

  @override
  String get howToEarnAnswer =>
      'Завершайте чтение Корана, сеты Зикра и ежедневный вход, чтобы получать Семена.';

  @override
  String get whatIsValidateQuestion => 'Что такое «Подтвердить монеты»?';

  @override
  String get whatIsValidateAnswer =>
      'Нажмите кнопку «Подтвердить» на главной странице раз в день, чтобы закрепить свои монеты.';

  @override
  String get howStreaksWorkQuestion => 'Как работают серии?';

  @override
  String get howStreaksWorkAnswer =>
      'Выполняйте ежедневные задания подряд, чтобы наращивать серию.';

  @override
  String get canDonatQuestion => 'Могу ли я пожертвовать свои Семена?';

  @override
  String get canDonateAnswer =>
      'Да! Откройте вкладку Ахира, чтобы пожертвовать Семена активным проектам сообщества.';

  @override
  String get coinsSealedMashaAllah => 'Монеты подтверждены!';

  @override
  String get rewardedForConsistency =>
      'Вы получили награду\nза постоянство сегодня!';

  @override
  String get validationPoints => 'Очки за подтверждение';

  @override
  String streakBonus(String days, String type, String points) {
    return 'Бонус за серию';
  }

  @override
  String get totalEarned => 'Всего заработано';

  @override
  String get openQuran => 'Открыть Коран';

  @override
  String get duaAndAzkaar => 'Дуа и азкары';

  @override
  String get shareWithFriends => 'Поделиться с друзьями';

  @override
  String get earnMoreNoor => 'Получить больше Семян';

  @override
  String get dontDisturb => 'Не беспокоить';

  @override
  String get maybeLater => 'Позже';

  @override
  String get read5QuranPages => 'Прочитать 5 страниц Корана';

  @override
  String get completeNowBonus => 'Завершите сейчас → бонус +50 Семян';

  @override
  String get completeADhikrSet => 'Завершить подход зикра';

  @override
  String get finishAzkaarBonus => 'Завершите Азкары → бонус +30 Семян';

  @override
  String get inviteAFriend => 'Пригласить друга';

  @override
  String get shareNoorBonus => 'Поделитесь Sabiq → получите +100 Семян';

  @override
  String get multiplyYour => 'УМНОЖЬТЕ ВАШИ';

  @override
  String get noorPointsBang => 'СЕМЕНА!';

  @override
  String get keepMomentum =>
      'Сохраняйте духовный импульс\nи смотрите, как растут ваши Семена';

  @override
  String get openQuranNow => 'Открыть Коран сейчас';

  @override
  String get startAzkaarNow => 'Начать азкары сейчас';

  @override
  String get goodDeed => 'Доброе дело';

  @override
  String get earnSawabWithRead => 'Получайте Саваб\nс каждым чтением';

  @override
  String get realImpact => 'Реальное влияние';

  @override
  String get coinsFundCauses => 'Семена финансируют\nблагородные дела';

  @override
  String get unexpectedGoogleError =>
      'Непредвиденная ошибка при входе через Google';

  @override
  String get authSuccessQuran => 'Успешная аутентификация через Quran.com!';

  @override
  String get authError => 'Ошибка аутентификации';

  @override
  String get ok => 'ОК';

  @override
  String get verified => 'Подтверждено';

  @override
  String get connectedAccount => 'Связанный аккаунт';

  @override
  String get active => 'Активно';

  @override
  String noorPlusPoints(String pts) {
    return '+$pts Сабик Семена';
  }

  @override
  String get yourGarden => 'ВАШ САД';

  @override
  String get noorPointsBloomed => 'Семена Сабика зацвели.';

  @override
  String get growingStreakTitle => 'СТРЕМИТЕЛЬНЫЙ РОСТ';

  @override
  String get daySingular => 'день';

  @override
  String get daysPlural => 'дни';

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
    return 'цели $goal $tab';
  }

  @override
  String get todaysPlots => 'Сегодняшние сюжеты';

  @override
  String setsTodayCount(String count) {
    return 'устанавливает сегодня $count';
  }

  @override
  String get earnPerFriend => 'Зарабатывайте +500 за друга';

  @override
  String lastAchievement(String name) {
    return 'Последний: $name';
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
  String get youIndicator => '(ты)';

  @override
  String get greetingPrefix => 'Ассаламу алейкум,';

  @override
  String get fundProjectsText => 'Ваши Sabiq Seeds финансируют эти проекты';

  @override
  String activeCount(String count) {
    return '$count активен';
  }

  @override
  String get seeDetailsForMoreProjects => 'Подробнее о других проектах →';

  @override
  String get notificationsSubtitle => 'Будьте в курсе наград и этапов';

  @override
  String get markAllAsRead => 'Отметить все как прочитанное';

  @override
  String get clearAll => 'Очистить все';

  @override
  String get notificationsOn => 'Уведомления включены';

  @override
  String get notificationsOff => 'Уведомления отключены';

  @override
  String get allCaughtUp => 'Все догнали';

  @override
  String get whenYouEarnRewards =>
      'Когда вы зарабатываете награды, достигаете серии результатов или открываете значок,\nоно появится здесь.';

  @override
  String get justNow => 'Прямо сейчас';

  @override
  String mAgo(String delta) {
    return '$delta мин назад';
  }

  @override
  String hAgo(String delta) {
    return '$delta ч назад';
  }

  @override
  String dAgo(String delta) {
    return '$delta дн назад';
  }

  @override
  String get newBadgeUnlocked => 'Новый значок разблокирован';

  @override
  String get daySealed => 'День запечатан';

  @override
  String get dailyLoginBonus => 'Ежедневный бонус за вход';

  @override
  String get oneWeek => 'Одна неделя';

  @override
  String get twoWeeks => 'Две недели';

  @override
  String badgeEarnedDesc(String badge) {
    return 'Вы заслужили значок «$badge».';
  }

  @override
  String pointsForSealing(String points) {
    return '+$points Семена Сабика для запечатывания сегодня.';
  }

  @override
  String welcomeBack(String points) {
    return '+$points Sabiq Seeds · с возвращением!';
  }

  @override
  String get onbV2Skip => 'Пропускать';

  @override
  String get onbV2Next => 'Следующий';

  @override
  String get onbV2_1_TitleA => 'Ваше чтение Корана';

  @override
  String get onbV2_1_TitleB => 'кормит голодных.';

  @override
  String get onbV2_1_Sub =>
      'Настоящая еда. Настоящие люди. Настоящее воздействие.';

  @override
  String get onbV2_1_Cta => 'Как это работает?';

  @override
  String get onbV2_2_Title => 'Вот как.';

  @override
  String get onbV2_2_Body =>
      'Читайте Коран или читайте зикр → зарабатывайте семена сабика → финансируйте реальные дела.';

  @override
  String get onbV2_3_TitleA => 'Коран вознаграждает вас';

  @override
  String get onbV2_3_TitleB => 'дважды.';

  @override
  String get onbV2_3_Sub =>
      'Однажды с благословения Аллаха. Однажды с Семенами, которые кормят нуждающихся.';

  @override
  String get onbV2_3_BannerLabel => 'заработал сегодня';

  @override
  String get onbV2_4_TitleA => 'Увидеть свое поклонение';

  @override
  String get onbV2_4_TitleB => 'ожить.';

  @override
  String get onbV2_4_Sub =>
      'Читайте утренний и вечерний зикр и наблюдайте, как ваша награда разворачивается, хадис за хадисом.';

  @override
  String get onbV2_5_TitleA => 'Ваше чтение достигает';

  @override
  String get onbV2_5_TitleB => 'здесь.';

  @override
  String get onbV2_5_Sub =>
      'Каждое заработанное вами Семя становится настоящей пищей, настоящей водой, настоящей надеждой.';

  @override
  String get onbV2_6_TitleA => 'Но откуда';

  @override
  String get onbV2_6_TitleB => 'деньги';

  @override
  String get onbV2_6_TitleC => 'откуда?';

  @override
  String get onbV2_6_Sub =>
      'Щедрые доноры финансируют эти дела. Ваши семена направляют туда, куда направляется их дар, и увеличивают вознаграждение с каждым читателем.';

  @override
  String get onbV2_6_Donor => 'Донор';

  @override
  String get onbV2_6_DonorSub => 'Финансирует дело';

  @override
  String get onbV2_6_You => 'Ты';

  @override
  String get onbV2_6_YouSub => 'Направьте подарок';

  @override
  String get onbV2_6_Charity => 'Благотворительность';

  @override
  String get onbV2_6_CharitySub => 'Оказывает помощь';

  @override
  String get onbV2_6_TrustBadge => '100% выплата проверенным партнерам';

  @override
  String get onbV2_7_TitleA => 'Каждый поступок';

  @override
  String get onbV2_7_TitleB => 'посчитал.';

  @override
  String get onbV2_7_Sub =>
      'Посмотрите отчет ахира, который вы строите, деревья, дворцы, освобожденные души, основанные на достоверных хадисах.';

  @override
  String get onbV2_8_TitleA => 'Начнем с вашего';

  @override
  String get onbV2_8_TitleB => 'имя.';

  @override
  String get onbV2_8_Sub => 'Так что Сабик чувствует себя твоим.';

  @override
  String get onbV2_8_Placeholder => 'Ваше имя';

  @override
  String get onbV2_8_Cta => 'Продолжать';

  @override
  String get onbV2_9_TitleA => 'Какая причина движет тобой';

  @override
  String get onbV2_9_TitleB => 'большинство?';

  @override
  String get onbV2_9_Sub =>
      'Ваши семена поддерживают все начинания, это просто помогает нам понять, что важно для нашего сообщества.';

  @override
  String get onbV2_9_Cta => 'Начинать';

  @override
  String get onbV2_9_Orphans => 'Сироты';

  @override
  String get onbV2_9_OrphansSub =>
      'Накормите и позаботьтесь о детях, потерявших все';

  @override
  String get onbV2_9_Water => 'Водяные колодцы';

  @override
  String get onbV2_9_WaterSub => 'Чистая вода для нуждающихся деревень';

  @override
  String get onbV2_9_War => 'Районы, пострадавшие от войны';

  @override
  String get onbV2_9_WarSub => 'Помощь там, где она нужна больше всего';

  @override
  String get onbV2_9_Disaster => 'Стихийные бедствия';

  @override
  String get onbV2_9_DisasterSub => 'Быстрое реагирование в случае кризиса';

  @override
  String get onbV2_3step_Title => 'Три простых шага.';

  @override
  String get onbV2_3step_Sub =>
      'Каждый стих, каждый зикр становится настоящей помощью.';

  @override
  String get onbV2_3step_S1Label => 'Шаг 1';

  @override
  String get onbV2_3step_S1Text => 'Читайте Коран';

  @override
  String get onbV2_3step_S2Label => 'Шаг 2';

  @override
  String get onbV2_3step_S2Text => 'Зарабатывайте семена';

  @override
  String get onbV2_3step_S3Label => 'Шаг 3';

  @override
  String get onbV2_3step_S3Text => 'Кормить сирот';

  @override
  String get languageLabel => 'Язык';

  @override
  String get systemDefault => 'Системный по умолчанию';

  @override
  String get yourStreaksTitle => 'ВАШИ СЕРИИ';

  @override
  String get streakLoading => 'Загрузка серий…';

  @override
  String get startStreakToday => 'Начните свою серию сегодня!';

  @override
  String get centurionMashaAllah => 'Сенчури, Masha\'Allah!';

  @override
  String get qfConflictTitle => 'Аккаунт уже существует';

  @override
  String get qfConflictExplanation =>
      'Этот email уже зарегистрирован в Sabiq Rewards с использованием другого способа входа (Email или Google).\n\nЧтобы сохранить ваш текущий прогресс, серии и Sabiq Seeds, пожалуйста, войдите своим оригинальным способом.';

  @override
  String get qfConflictStep1 => 'Вернуться к экрану входа';

  @override
  String qfConflictStep2(String email) {
    return 'Войдите через Email или Google используя\n$email';
  }

  @override
  String get qfConflictStep3 => 'Весь ваш прогресс будет там';

  @override
  String get qfConflictBackButton => 'Назад к входу';

  @override
  String get sponsorAnOrphan => 'Поддержать сироту';

  @override
  String get noOrphansListed => 'Сироты пока не добавлены';

  @override
  String get checkBackForOrphans =>
      'Загляните позже — новые возможности поддержки добавляются регулярно.';

  @override
  String get orphanVerseTranslation => '\"А сироту не притесняй.\", Коран 93:9';

  @override
  String get orphanCardOpen => 'Открыто';

  @override
  String get doneLabel => 'Готово';

  @override
  String get aReminderLabel => 'НАПОМИНАНИЕ';

  @override
  String get yourAkhirahBalance => 'ВАШ БАЛАНС АХИРАТА';

  @override
  String get seedsCollectedSinceJoined => 'Семян собрано с момента регистрации';

  @override
  String get todayLabel => 'СЕГОДНЯ';

  @override
  String plusSeedsToday(String count) {
    return '+$count сегодня';
  }

  @override
  String get azkaarPerDay => 'азкаар в день';

  @override
  String get viewFullStats => 'Полная статистика';

  @override
  String get fatherLabel => 'Отец';

  @override
  String get motherLabel => 'Мать';

  @override
  String get siblingsLabel => 'Братья и сёстры';

  @override
  String get familySection => 'Семья';

  @override
  String get educationSection => 'Образование';

  @override
  String get gradeLabel => 'Класс';

  @override
  String get schoolLabel => 'Школа';

  @override
  String get theirStorySection => 'Их история';

  @override
  String get yourBalanceLabel => 'Ваш баланс:';

  @override
  String sponsorCta(String name) {
    return 'Поддержать $name';
  }

  @override
  String get notEnoughSeeds => 'Недостаточно Семян';

  @override
  String get bookmarkSyncDialogTitle => 'Синхронизация закладок Quran.com';

  @override
  String get closeLabel => 'Закрыть';

  @override
  String get searchHint => 'Поиск…';

  @override
  String get enterCodeHint => 'Введите код…';

  @override
  String get searchSurahHint => 'Поиск суры...';

  @override
  String get customLabel => 'Своё';

  @override
  String get seedsSuffix => 'Семена';

  @override
  String get settingsTooltip => 'Настройки';

  @override
  String get retryLabel => 'Повторить';

  @override
  String get authErrorTitle => 'Ошибка аутентификации';

  @override
  String sealWithinHours(int hours) {
    return 'Запечатать через $hours ч';
  }

  @override
  String sealWithinMinutes(int minutes) {
    return 'Запечатать через $minutes мин';
  }

  @override
  String get sealNow => 'Запечатать сейчас';

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
      other: '$count Семян ожидают',
      one: '1 Семя ожидает',
    );
    return '$_temp0';
  }

  @override
  String get sealToSave => 'Запечатать, чтобы сохранить';

  @override
  String get top10Contributors => 'Топ-10 участников';

  @override
  String get copyLabel => 'Копировать';

  @override
  String get copiedLabel => 'Скопировано!';

  @override
  String get whatsappLabel => 'WhatsApp';

  @override
  String get youBothEarnSeeds => 'Вы оба получаете 500 Семян!';

  @override
  String jazakAllahPlusSeeds(int seeds) {
    return 'JazakAllah!  +$seeds Семян';
  }

  @override
  String get jazakAllahDaySealed => 'JazakAllah!  День запечатан';

  @override
  String get pointsGoals => 'ЦЕЛИ ОЧКОВ';

  @override
  String get editLabel => 'Изменить';

  @override
  String get dailyGoal => 'Дневная цель';

  @override
  String get weeklyGoal => 'Недельная цель';

  @override
  String get monthlyGoal => 'Месячная цель';

  @override
  String setTargetSeeds(int defaultVal) {
    return 'Установите целевые Семена (по умолчанию: $defaultVal)';
  }

  @override
  String get noInternetTitle => 'Нет интернет-соединения';

  @override
  String get connectingTitle => 'Подключение…';

  @override
  String get somethingWentWrongTitle => 'Что-то пошло не так';

  @override
  String get noInternetSubtitle =>
      'Этой функции нужен интернет.\nПроверьте Wi-Fi или мобильные данные.';

  @override
  String get connectingSubtitle => 'Загрузка ваших данных…\nПодождите немного';

  @override
  String get errorSubtitle =>
      'Произошла непредвиденная ошибка.\nНажмите повтор.';

  @override
  String get tryAgain => 'Повторить';

  @override
  String get everyRecitationCanChangeLife =>
      'Каждое чтение может\nизменить жизнь';

  @override
  String get givenLabel => 'ПОЖЕРТВОВАНО';

  @override
  String get goalUpper => 'ЦЕЛЬ';

  @override
  String get aboutThisCause => 'Об этой цели';

  @override
  String myContributionSeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Мой вклад: $count Семян',
      one: 'Мой вклад: 1 Семя',
    );
    return '$_temp0';
  }

  @override
  String jazakAllahKhayranDonated(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: 'JazakAllah Khayran! Пожертвовано $amount Семян.',
      one: 'JazakAllah Khayran! Пожертвовано 1 Семя.',
    );
    return '$_temp0';
  }

  @override
  String get coinsSealedTitle => 'Монеты запечатаны! ماشاء الله';

  @override
  String get seedsSealedSafe =>
      'Ваши Семена запечатаны и сохранены\nдля Ахирата.';

  @override
  String get validationSeedsLabel => 'Семена валидации';

  @override
  String get streakBonusLabel => 'Бонус серии';

  @override
  String get totalEarnedLabel => 'Всего получено';

  @override
  String get alhamdulillahCta => 'Альхамдулиллах! 🤲';

  @override
  String get openQuranCta => 'Открыть Коран';

  @override
  String get duaAzkaarCta => 'Дуа и Азкар';

  @override
  String get shareWithFriendsCta => 'Поделиться с друзьями';

  @override
  String get earnMoreSeedsCta => 'Заработать больше Семян';

  @override
  String levelTitleFormat(int level, String title) {
    return 'Ур. $level · $title';
  }

  @override
  String get akhirahBalanceUpper => 'БАЛАНС АХИРАТА';

  @override
  String bestDayStreakBadge(int streak) {
    return 'Лучшее: серия $streak дн.';
  }

  @override
  String get deedsLabel => 'ДЕЛА';

  @override
  String get treesLabel => 'ДЕРЕВЬЯ';

  @override
  String get forgivenLabel => 'ПРОЩЕНО';

  @override
  String get navCause => 'Цель';

  @override
  String get realChildrenSubtitle => 'Реальные дети, их истории и жизни';

  @override
  String get seeAllAction => 'Все';

  @override
  String get activeCampaigns => 'Активные кампании';

  @override
  String get poolSeedsImpact =>
      'Объедините свои Семена для долгосрочного эффекта';

  @override
  String get featuredSponsorChild => 'Рекомендуем · Поддержи ребёнка';

  @override
  String meetOrphanAge(String name, int age) {
    return 'Познакомьтесь с $name, $age лет';
  }

  @override
  String sponsorNameArrow(String name) {
    return 'Поддержать $name →';
  }

  @override
  String get featuredCampaign => 'Рекомендуемая кампания';

  @override
  String get yourGiving => 'Ваши пожертвования';

  @override
  String get havenNotGivenYet =>
      'Вы ещё не делали пожертвований. Выберите кого-то выше, чтобы начать свой путь.';

  @override
  String get seedsDonatedLabel => 'Семян пожертвовано';

  @override
  String orphanCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сироты',
      one: 'Сирота',
    );
    return '$_temp0';
  }

  @override
  String projectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Проекты',
      one: 'Проект',
    );
    return '$_temp0';
  }

  @override
  String get couldntLoadJourney => 'Не удалось загрузить ваш Путь';

  @override
  String get checkConnectionRetry =>
      'Проверьте соединение и повторите попытку.';

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
  String get hadithReference => 'Хадис-источник';

  @override
  String get howYouEarnedThis => 'Как вы это заработали';

  @override
  String seedsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Семян',
      one: '1 Семя',
    );
    return '$_temp0';
  }

  @override
  String get seedsUnit => 'Семена';

  @override
  String get topContribByLifetimeSeeds =>
      'Лучшие участники по Семенам за всё время';

  @override
  String get romanisedPronunciation =>
      'Латинская транскрипция под каждым словом';

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
      'Получайте +10 Семян за каждый прочитанный аят';

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
    return 'Сура $name содержит $count аятов';
  }

  @override
  String noXYet(String label) {
    return 'Нет $label пока';
  }

  @override
  String get tapHeartToSave =>
      'Нажмите на иконку сердца/закладки при чтении, чтобы сохранить аяты.';

  @override
  String surahVerseRow(int surah, int ayah) {
    return 'Сура $surah  •  Аят $ayah';
  }

  @override
  String get hasanatFromQuran => 'Хасанат из Корана';

  @override
  String tenPerLetterSubtitle(int count) {
    return '10 за букву, $count за аят';
  }

  @override
  String get fromSubhanAllahTasbih => 'От СубханАллах и тасбиха';

  @override
  String get likeFoamOfSea => 'Как морская пена';

  @override
  String get fromSurahIkhlasRecitation => 'От чтения суры Ихлас';

  @override
  String get laHawlaSubtitle => 'Ля Хавля Ва Ля Куввата';

  @override
  String get equivalentRewardEarned => 'Эквивалентная награда получена';

  @override
  String get gatesOfParadise => 'Врата Рая';

  @override
  String get afterPerfectWudu => 'После идеального вуду';

  @override
  String get blessingsFromAllah => 'Благословения от Аллаха';

  @override
  String get salawatTenReturned => 'Салават × 10 возвращён';

  @override
  String get timesProtected => 'Раз защищён';

  @override
  String get refugeInvokedFromHarm => 'Прибежище призвано от вреда';

  @override
  String get quranCompletions => 'Хатм Корана';

  @override
  String get viaSurahIkhlas => 'Через суру аль-Ихлас ×3';

  @override
  String get bonusHasanaat => 'Бонус Хасанат';

  @override
  String get marketplaceDua => 'Дуа рынка';

  @override
  String get seedsDonatedToCommunity => 'Семена пожертвованы сообществу';

  @override
  String get yourMonth => 'Ваш Месяц';

  @override
  String get ayahsReadLabel => 'Прочитано аятов';

  @override
  String get dhikrCount => 'Количество зикра';

  @override
  String get quranTime => 'Время Корана';

  @override
  String get dhikrTime => 'Время Зикра';

  @override
  String get activeDays => 'Активные дни';

  @override
  String get treesShortLabel => 'Деревья';

  @override
  String get palacesShortLabel => 'Дворцы';

  @override
  String get freedShortLabel => 'Освобождены';

  @override
  String get blessingsShortLabel => 'Благословения';

  @override
  String get dailyWordPrefix => 'Ежедневные ';

  @override
  String get essentialsWord => 'Основы';

  @override
  String get seedsExpiringNotificationTitle => 'Семена истекают в полночь!';

  @override
  String seedsExpiringNotificationBody(int pending) {
    return 'У вас $pending Семян ожидают. Запечатайте День сейчас или они истекут!';
  }

  @override
  String get okButton => 'ОК';

  @override
  String get signUpTitle => 'Регистрация';

  @override
  String get signInTitle => 'Вход';

  @override
  String get emailFieldLabel => 'Электронная почта';

  @override
  String get passwordFieldLabel => 'Пароль';

  @override
  String get enterEmailValidator => 'Пожалуйста, введите ваш email';

  @override
  String get enterPasswordValidator => 'Пожалуйста, введите ваш пароль';

  @override
  String get passwordTooShortValidator =>
      'Пароль должен содержать минимум 6 символов';

  @override
  String get signUpSuccessMessage =>
      'Регистрация успешна! Пожалуйста, проверьте вашу почту для подтверждения.';

  @override
  String get unexpectedAuthError => 'Произошла непредвиденная ошибка';

  @override
  String get sawabLabel => 'Саваб';

  @override
  String get impactLabel => 'Влияние';

  @override
  String get goodDeedTitle => 'Доброе Дело';

  @override
  String get goodDeedSubtitle => 'Зарабатывайте Саваб\nс каждым чтением';

  @override
  String get realImpactTitle => 'Реальное Влияние';

  @override
  String get realImpactSubtitle => 'Монеты финансируют\nблагородные дела';

  @override
  String plusDeedsTodayBadge(String count) {
    return '+$count деяний сегодня';
  }

  @override
  String equivalentChange(String count) {
    return '$count эквивалент';
  }

  @override
  String receivedChange(String count) {
    return '$count получено';
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
    return 'Потрачено $time на чтение Корана сегодня';
  }

  @override
  String get everyDeedRecordedKeepGoing =>
      '🌙  Каждое деяние записано. Продолжайте!';

  @override
  String viewAllDonors(int count) {
    return 'Показать всех $count жертвователей';
  }

  @override
  String nextMilestoneInfo(String label, int days) {
    return 'Далее: $label ($days дней)';
  }

  @override
  String bestN(int n) {
    return 'Лучший $n';
  }

  @override
  String get streakMilestoneWarmingUp => 'Разогрев';

  @override
  String get streakMilestoneOneWeek => 'Одна Неделя';

  @override
  String get streakMilestoneTwoWeeks => 'Две Недели';

  @override
  String get streakMilestoneOneMonth => 'Один Месяц';

  @override
  String get streakMilestoneTwoMonths => 'Два Месяца';

  @override
  String get streakMilestoneCenturion => 'Центурион';

  @override
  String get firstTrackedWeek =>
      'Ваша первая отслеженная неделя — продолжайте!';

  @override
  String get rightOnSevenDayPace => 'Точно по вашему 7-дневному темпу';

  @override
  String aboveSevenDayAvg(int pct) {
    return 'На $pct% выше вашего 7-дневного среднего';
  }

  @override
  String belowSevenDayAvg(int pct) {
    return 'На $pct% ниже вашего 7-дневного среднего';
  }

  @override
  String get sponsoredBy => 'Спонсировано';

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
  String get dailyDuasCategory => 'Ежедневные Дуа';

  @override
  String get ruquiyaCategory => 'Рукыя';

  @override
  String get duasBeforeSleep => 'Дуа перед сном';

  @override
  String get duasAfterSalah => 'Дуа после Салята';

  @override
  String get rabbana40Duas => '40 Дуа Раббана';

  @override
  String get thisWorld => 'Этот мир';

  @override
  String get dunyaArabic => 'Дуня';

  @override
  String get hereafter => 'Ахира';

  @override
  String get akhirahArabic => 'Ахира';

  @override
  String get bookOfCompletePrayer => 'Книга полной молитвы';

  @override
  String get propheticDuas => 'Пророческие дуа';

  @override
  String get morningEveningRemembrance => 'Утренние и вечерние азкары';

  @override
  String get furtherDuas => 'Дополнительные дуа';

  @override
  String get closingSalawat => 'Заключительные азкары и салават';

  @override
  String get hajjAndUmrahCategory => 'Дуа Хаджа и Умры';

  @override
  String get azkarSingular => 'зикр';

  @override
  String get azkarPlural => 'зикры';

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
    return '+$count семян за сессию';
  }

  @override
  String sevenDayAvgAzkaar(String count) {
    return 'ср. за 7 дн.: $count зикров/день';
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
    return '$count заработано';
  }

  @override
  String holdingChangeOpened(String count) {
    return '$count открыто';
  }

  @override
  String holdingChangeInvocations(String count) {
    return '$count призываний';
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
    return 'Закладок в приложении: $count';
  }

  @override
  String streakSeedsBonus(String count) {
    return '+$count семян';
  }

  @override
  String plusSeedsThisWeek(String count) {
    return '+$count за неделю';
  }

  @override
  String unitDuas(String count) {
    return '$count дуа';
  }

  @override
  String unitAdhkar(String count) {
    return '$count зикров';
  }

  @override
  String get moreCollections => 'Больше коллекций';

  @override
  String get donateAndEarnReward => 'Пожертвуйте и получите награду';

  @override
  String donateAmountSeeds(String amount) {
    return 'Пожертвовать $amount Семян';
  }

  @override
  String get readMore => 'Читать дальше';

  @override
  String get beFirstToContribute => 'Станьте первым, кто внесёт вклад.';

  @override
  String get showFewer => 'Свернуть ↑';

  @override
  String viewAllN(String n) {
    return 'Все $n →';
  }

  @override
  String liveReadersNow(String count) {
    return '$count онлайн';
  }

  @override
  String communityReadingToday(String count) {
    return '$count прочитали сегодня (сообщество)';
  }

  @override
  String communityHasanatToday(String count) {
    return '+$count хасанат сообщества сегодня';
  }

  @override
  String get peopleReadingNow => 'читают прямо сейчас';

  @override
  String get readToday => 'прочитали сегодня';

  @override
  String get communityHasanat => 'хасанат сообщества';

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
    return '$_dhikrToday устанавливается сегодня';
  }

  @override
  String dashboardScreen_last(String arg1) {
    return 'Последний: $arg1';
  }

  @override
  String get dashboardScreen_earnPerFriend => 'Зарабатывайте +500 за друга';

  @override
  String get dashboardScreen_invalidReferralCode_59fb25 =>
      'Неверный реферальный код.';

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
      'Благослови каждое чувство, каждый член, каждый поступок';

  @override
  String get dhikrScreen_keepTheHeartFirm_9c4efb =>
      'Сохраняйте сердце твердым после руководства';

  @override
  String get dhikrScreen_faithAnsweredWithForgiveness_3f30c4 =>
      'Вера ответила прощением от Огня';

  @override
  String get dhikrScreen_inscribedWithTheWitnesses_e2612d =>
      'Написано свидетелями истины';

  @override
  String get dhikrScreen_allahIsTheBest_4f2bf7 =>
      'Аллах лучший судья между истиной и ложью';

  @override
  String get dhikrScreen_neverTrialForThe_5eb10a =>
      'Никогда не испытание для неверующих';

  @override
  String get dhikrScreen_refugeFromEveryEvil_6d2534 =>
      'Убежище от всякого зла, которое захватывает';

  @override
  String get dhikrScreen_guaranteedJannahIfYou_48d274 =>
      'Гарантированная Джанна, если ты умрешь этой ночью.';

  @override
  String get dhikrScreen_reciteAtDawnDusk_f17fb8 =>
      'Прочтите 3 раза на рассвете и в сумерках, этого вам будет достаточно во всех отношениях.';

  @override
  String get dhikrScreen_nothingShallHarmYou_8c5c6c =>
      'Ничто не причинит тебе вреда от Его имени';

  @override
  String get dhikrScreen_guaranteedJannahIfYou_0ffafe =>
      'Гарантированная Джанна, если ты умрешь сегодня.';

  @override
  String get dhikrScreen_guardedInYourDeen_4a0b4a =>
      'Охраняемый в твоей Дин · Дунья · Ахира, и со всех шести сторон';

  @override
  String get dhikrScreen_guardMeFromAll => 'Охрани меня со всех шести сторон';

  @override
  String dhikrScreen_35c165(String arg1) {
    return '$arg1';
  }

  @override
  String get dhikrScreen_sinsWashedAway => 'Грехи смыты';

  @override
  String get dhikrScreen_slavesFreed => 'Рабы освобождены';

  @override
  String get dhikrScreen_weHaveBelievedForgive_e958e6 =>
      'Мы поверили — прости нас, Ты — лучший из милосердных';

  @override
  String get dhikrScreen_mashaallahRewardSecured =>
      'МашаАллах! Награда обеспечена';

  @override
  String dhikrScreen_a5cfd1(String count) {
    return '×$count';
  }

  @override
  String get dhikrScreen_completeToWatchYour =>
      'Завершите, чтобы увидеть, как цветет ваш сад выше.';

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
  String get impactReportScreen_hasanaatEarned => 'Хасанаат Заработано';

  @override
  String impactReportScreen_hasanat_e68a30(String arg1) {
    return '→ Хасанат: $arg1\\n\\n';
  }

  @override
  String get impactReportScreen_hasanatFromQuran => 'Хасанат из Корана';

  @override
  String get impactReportScreen_treesInJannah => 'Деревья в Джанне';

  @override
  String get impactReportScreen_sinsForgiven => 'Грехи прощены';

  @override
  String get impactReportScreen_palacesBuilt => 'Дворцы построены';

  @override
  String get impactReportScreen_treasuresOfJannah => 'Сокровища Джанна';

  @override
  String get impactReportScreen_slavesFreed => 'Рабы освобождены';

  @override
  String impactReportScreen_totalRecitations_262e54(String arg1) {
    return 'Всего чтений: $arg1\\n';
  }

  @override
  String get impactReportScreen_gatesOfParadiseOpened => 'Врата рая открыты';

  @override
  String get impactReportScreen_blessingsFromAllah => 'Благословения от Аллаха';

  @override
  String get impactReportScreen_timesProtected => 'Время защищено';

  @override
  String get impactReportScreen_quranCompletions => 'Завершения Корана';

  @override
  String get impactReportScreen_bonusMillionHasanaat => 'Бонус Миллион Хасанат';

  @override
  String get impactReportScreen_sadaqahGiven => 'Садака дана';

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
    return '${arg1}m';
  }

  @override
  String impactReportScreen_ago_c25b44(String arg1) {
    return '$arg1ч назад';
  }

  @override
  String impactReportScreen_ago_e160e3(String arg1) {
    return '${arg1}w назад';
  }

  @override
  String impactReportScreen_ago_65f0ec(String arg1) {
    return '$arg1г назад';
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
    return '+$arg1 Семена';
  }

  @override
  String levelScreen_seeds_a20530(String arg1) {
    return '+$arg1 Семена';
  }

  @override
  String levelScreen_seeds_a49180(String arg1) {
    return '+$arg1 Семена ✓';
  }

  @override
  String levelScreen_seeds_a22be5(String arg1) {
    return '+$arg1 Семена';
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
    return '+$arg1 Семена';
  }

  @override
  String get phase1Screens_inTheNameOf => 'Во имя Аллаха Милостивого…';

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
    return '$arg1ч назад';
  }

  @override
  String orphanDetailScreen_ago_e160e3(String arg1) {
    return '${arg1}w назад';
  }

  @override
  String orphanDetailScreen_ago_65f0ec(String arg1) {
    return '$arg1г назад';
  }

  @override
  String get profileSettingsScreen_sabiqRewards => 'Награды Сабика • v1.0';

  @override
  String profileSettingsScreen_seeds_59ba7c(String arg1) {
    return '$arg1 Семена';
  }

  @override
  String profileSettingsScreen_seeds_2bc978(String arg1) {
    return '$arg1 Семена';
  }

  @override
  String get profileSetupScreen_ahmadFatimaYusuf => 'Ахмад, Фатима, Юсуф…';

  @override
  String get profileSetupScreen_pakistanEgyptMalaysia =>
      'Пакистан, Египет, Малайзия…';

  @override
  String projectDetailScreen_4c2b09(String arg1, String arg2, String arg3) {
    return '$arg1 $arg2 $arg3';
  }

  @override
  String projectDetailScreen_seeds_801ec7(String arg1) {
    return '$arg1 Семена';
  }

  @override
  String projectDetailScreen_e4e562(String arg1) {
    return '$arg1%';
  }

  @override
  String projectDetailScreen_ago_c25b44(String arg1) {
    return '$arg1ч назад';
  }

  @override
  String projectDetailScreen_ago_e160e3(String arg1) {
    return '${arg1}w назад';
  }

  @override
  String projectDetailScreen_ago_65f0ec(String arg1) {
    return '$arg1г назад';
  }

  @override
  String get quranHubScreen_loadingQuran => 'Загрузка Корана…';

  @override
  String quranHubScreen_saved_edce53(String arg1) {
    return '$arg1 сохранено';
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
      'Данные Word недоступны. Проверьте свое соединение.';

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
      'Вы должны войти в систему, чтобы спонсировать.';

  @override
  String get liveNotificationService_sealYourSeedsBefore_be2183 =>
      'Запечатайте свои семена до полуночи!';

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
    return '+$arg1 Семена';
  }

  @override
  String get motivationalPopup_readQuranPages => 'Прочтите 5 страниц Корана.';

  @override
  String get motivationalPopup_completeDhikrSet => 'Завершите набор зикра';

  @override
  String get motivationalPopup_inviteFriend => 'Пригласить друга';

  @override
  String notificationsSheet_ago(String arg1) {
    return '$arg1 мин назад';
  }

  @override
  String notificationsSheet_ago_5d4e7f(String arg1) {
    return '$arg1ч назад';
  }

  @override
  String notificationsSheet_ago_67b1d9(String arg1) {
    return '$arg1дня назад';
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
      '«Субханаллахи ва би-хамдихи» — произнесенное 100 раз в день смывает грехи, словно морская пена. (Бухари)';

  @override
  String get akhirahBalanceScreen_sayLaIlahaIllallah_27fc5f =>
      'Скажите «Ля иляха илляЛлах» 100 раз — это равносильно освобождению 10 рабов и 100 хасаната. (Бухари)';

  @override
  String get akhirahBalanceScreen_lightOnTheTongue_ea6114 =>
      'Легкое на языке, тяжелое на весах: Субханаллахи ва би-хамдихи, Субханаллахиль-азим. (Бухари 6406)';

  @override
  String get akhirahBalanceScreen_theDhikrOfAllah_a23f17 =>
      'Зикр Аллаха тяжелее на весах, чем золото равного веса. Продолжать идти.';

  @override
  String get akhirahBalanceScreen_yourTongueShouldStay_34816c =>
      '«Ваш язык должен оставаться влажным от поминания Аллаха». — Он все еще влажный?';

  @override
  String get akhirahBalanceScreen_astaghfirullahTheProphetSaid_7625ff =>
      'Астагфируллах — Пророк ﷺ повторял это 100 раз в день, и на нем не было греха. Сколько у тебя?';

  @override
  String get akhirahBalanceScreen_whenYouRememberAllah_60f406 =>
      'Когда вы тихо вспоминаете Аллаха, Он вспоминает вас в гораздо большем собрании.';

  @override
  String get akhirahBalanceScreen_reciteAyatAlKursi_d0751f =>
      'Читай Аят аль-Курси после каждого намаза — ничто не удержит тебя от рая, кроме смерти.';

  @override
  String get akhirahBalanceScreen_oneAlhamdulillahFillsThe_4794bb =>
      'Один Альхамдулиллах заполняет чашу весов. Одна Субханалла заполняет то, что находится между небом и землей.';

  @override
  String get akhirahBalanceScreen_theRemembranceOfAllah_c99fe8 =>
      '«Память Аллаха превыше всего остального». - Сура Аль-Анкабут 29:45';

  @override
  String get akhirahBalanceScreen_rememberMeWillRemember_1aca04 =>
      '«Помни меня — я буду помнить тебя». - Сура Аль-Бакара 2:152. Вы будете?';

  @override
  String get akhirahBalanceScreen_inTheRemembranceOf_20b541 =>
      '«В поминании Аллаха сердца обретают покой». - Сура Ар-Раад 13:28';

  @override
  String get akhirahBalanceScreen_fiveMinutesOfDhikr_e12766 =>
      'Пять минут зикра теперь формируют следующие 24 часа вашего сердца.';

  @override
  String get akhirahBalanceScreen_streakIsnAboutToday_9157d8 =>
      'Успех не в сегодняшнем дне, а в том, кем вы станете через 30 дней.';

  @override
  String get akhirahBalanceScreen_smallDropsFillAn_1accce =>
      'Маленькие капли наполняют океан. Ваш ежедневный зикр наполняет нечто гораздо большее.';

  @override
  String get akhirahBalanceScreen_noOneSeesThe_0182c7 =>
      'Никто не видит зикр в вашем сердце, но каждый ангел, записывающий ваши записи, видит.';

  @override
  String get akhirahBalanceScreen_theBiggestWinsAre_1b8fb6 =>
      'Самые большие победы складываются из самых маленьких ежедневных привычек. Не разрывайте цепочку.';

  @override
  String get akhirahBalanceScreen_youCameBackToday_a020b1 =>
      'Ты вернулся сегодня. Это уже поклонение. Остаться еще на минутку?';

  @override
  String get akhirahBalanceScreen_tomorrowPeaceIsBuilt_a72bd8 =>
      'Завтрашний мир строится на сегодняшних воспоминаниях. Посадите еще одно семечко.';

  @override
  String get akhirahBalanceScreen_areYouDoneAllah_06ca1d =>
      'Вы закончили? Дверь Аллаха всегда открыта — даже после того, как вы ее закрыли.';

  @override
  String get akhirahBalanceScreen_dhikrIsTheLanguage_b1b983 =>
      'Зикр – это язык сердца. Говорил ли твой сегодня со своим Господом?';

  @override
  String get akhirahBalanceScreen_everySubhanallahIsSadaqah_16b797 =>
      'Каждая Субханалла – это садака. Сколько вы дадите перед сном?';

  @override
  String get akhirahBalanceScreen_heartThatForgetsDhikr_3a6173 =>
      'Сердце, которое забывает о зикре, начинает ржаветь. Сердце, которое помнит, горит.';

  @override
  String get akhirahBalanceScreen_haveYouFortifiedYourself_17ccac =>
      'Подкрепились ли вы сегодня утренним и вечерним азкаром?';

  @override
  String dashboardScreen_sponsor_d48549(String name, String arg1) {
    return 'Спонсор $name, $arg1';
  }

  @override
  String dashboardScreen_606140_606140(String arg1, String _lastAyah) {
    return '$arg1 · $_lastAyah';
  }

  @override
  String get dashboardScreen_joinMeOnSabiq_755fb5 =>
      'Присоединяйтесь ко мне в Sabiq Rewards и зарабатывайте семена для ежедневного Корана, зикра и добрых дел!\\n\\n';

  @override
  String dashboardScreen_useMyCodeAnd_7d13b3(String arg1) {
    return 'Используйте мой код *$arg1*, и мы оба получим 500 семян Сабика!\\n\\n';
  }

  @override
  String get dashboardScreen_messageCopiedShareOr_7b977e =>
      'Скопируйте сообщение, поделитесь или вставьте в WhatsApp!';

  @override
  String get dashboardScreen_sabiqSeedsRewardedTo_c209d6 =>
      'Вы оба получили 500 семян Сабика!';

  @override
  String get dashboardScreen_youHaveAlreadyUsed_f7c387 =>
      'Вы уже использовали реферальный код.';

  @override
  String get dashboardScreen_youCannotUseYour_b7dbfe =>
      'Вы не можете использовать свой собственный код.';

  @override
  String get dashboardScreen_anErrorOccurredPlease_8ee486 =>
      'Произошла ошибка. Пожалуйста, попробуйте еще раз.';

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
      '🤲 Посмотреть кампанию и сделать пожертвование';

  @override
  String dashboardScreen_d13a42_d13a42(
    String _myPoints,
    String unit,
    String arg1,
  ) {
    return '$_myPoints $unit • $arg1';
  }

  @override
  String get dashboardScreen_beTheFirstOn_63de17 => 'Будь первым на доске';

  @override
  String get dashboardScreen_readAnAyahOr_9c7ab7 =>
      'Прочтите аят или зикр, чтобы занять первое место.';

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
      'Закрепите иллюстрацию вверху, пока текст на арабском языке прокручивается под ней.';

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
  String get impactReportScreen_whoeverDoesAnAtom_9013b0 =>
      '«Кто делает атом\\';

  @override
  String get impactReportScreen_theHomeOfThe_4602d2 =>
      '«Дом будущей жизни — это вечная жизнь, если бы они только знали». - Сура Аль-Анкабут 29:64';

  @override
  String get impactReportScreen_raceTowardsForgivenessFrom_94d614 =>
      '«Спешите к прощению от вашего Господа и к саду, который широк, как небо и земля». - Сура Аль-Хадид 57:21';

  @override
  String get impactReportScreen_andWhatIsThe_7eec52 =>
      '«А что такое жизнь этого мира, кроме развлечения заблуждения?» - Сура Али Имран 3:185';

  @override
  String get impactReportScreen_indeedWithHardshipComes_ea97fa =>
      '«Воистину, за трудностями приходит облегчение». - Сура Аш-Шарх 94:6';

  @override
  String get impactReportScreen_singleGoodDeedIn_c126b4 =>
      '«Один добрый поступок в Рамадан равен 70 в любой другой месяц». Складывайте, пока дверь открыта.';

  @override
  String get impactReportScreen_theProphetSaidCharity_c154f4 =>
      'Пророк ✍ сказал: благотворительность не уменьшает богатство, а приумножает его. (мусульманин)';

  @override
  String get impactReportScreen_smilingAtYourBrother_8f55e4 =>
      '«Улыбка брату – это садака». Вы можете зарабатывать, даже когда ваши карманы пусты. (Тирмизи)';

  @override
  String get impactReportScreen_theMostBelovedDeeds_f11906 =>
      '«Самые любимые дела перед Аллахом – самые последовательные, даже если они и малы». (Бухари)';

  @override
  String get impactReportScreen_inJannahIsWhat_ff6d55 =>
      '«В Рая есть то, чего не видел ни один глаз, не слышало ни одно ухо и не представляло ни одно сердце». (Бухари)';

  @override
  String get impactReportScreen_twoRakatsAtFajr_c8b238 =>
      'Два раката на Фаджр лучше мира и всего, что в нем. (мусульманин)';

  @override
  String get impactReportScreen_everyStepTowardSalah_62962f =>
      'Каждый шаг к намазу стирает грех и повышает ранг. (мусульманин)';

  @override
  String get impactReportScreen_everySeedYouDonate_618d1f =>
      'Каждое пожертвованное вами семя сажает дерево в ком-то другом\\';

  @override
  String get impactReportScreen_takeWealthWithYou_784e85 =>
      'Я не беру с собой богатство. Только дела, которые он купил.';

  @override
  String get impactReportScreen_theAngelsRecordNothing_e03c03 =>
      'Ангелы не записывают ничего особенного. Один Субханаллах может перевесить гору.';

  @override
  String get impactReportScreen_sadaqahIsTomorrow_794857 => 'садака завтра\\';

  @override
  String get impactReportScreen_heartThatGivesIs_4b6000 =>
      'Сердце, которое дает, – это сердце, которое Аллах наполняет. Дон\\';

  @override
  String get impactReportScreen_theReceiptWhatDid_d1c41b =>
      'Это квитанция. Что ты послал вперед?';

  @override
  String get impactReportScreen_imagineYourScaleOn_094d07 =>
      'Представьте себе свой масштаб на Яум аль-Кияме. Какой вес вы прибавляете сегодня?';

  @override
  String get impactReportScreen_theWorldIsBorrowed_2eeb50 =>
      'Мир взят взаймы. Ахира находится в собственности. Инвестируйте соответственно.';

  @override
  String get impactReportScreen_youBuryTheBody_bb5233 =>
      'Вы хороните тело — но не дела. Отправляйте их вперед, пока можете.';

  @override
  String get impactReportScreen_righteousChildWhoPrays_7bcef4 =>
      'Праведный ребенок, который молится за вас, текущая благотворительность или знания, приносящие пользу — три вечных инвестиции. (мусульманин)';

  @override
  String get impactReportScreen_youWillMeetAllah_c19524 =>
      'Вы встретите Аллаха со своим рекордом. Убедитесь сегодня\\';

  @override
  String get impactReportScreen_noDeedIsToo_c04d50 =>
      'Никакое дело не является слишком малым для Того, кто считает атомы.';

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
      'Кто сделает доброе дело, тому будет в десять раз больше.';

  @override
  String get impactReportScreen_whoeverReadsLetterFrom_36d74f =>
      'Кто прочитает письмо из Книги Аллаха, тому будет одна хасана, а хасана умножается на десять.';

  @override
  String get impactReportScreen_twoHadithGrowThis_c8d4a2 =>
      'Два хадиса увеличивают это число рядом:\\n\\n';

  @override
  String impactReportScreen_dhikrRecitedLifetime_669e2a(String arg1) {
    return 'Читаемый Зикр (пожизненно): $arg1\\n';
  }

  @override
  String impactReportScreen_hasanat_64c7b6(String arg1) {
    return '→ Хасанат: $arg1\\n\\n';
  }

  @override
  String impactReportScreen_ayahsReadLifetime_75eef6(String arg1) {
    return 'Читаемые аяты (пожизненно): $arg1\\n';
  }

  @override
  String impactReportScreen_totalHasanaat_c43112(String arg1) {
    return 'Всего хасанат: $arg1';
  }

  @override
  String get impactReportScreen_whoeverSaysSubhanAllahiWa_4b6459 =>
      'Кто произнесет «СубханАллахи ва бихамдихи» 100 раз в день, тому будут прощены грехи, даже если они были подобны морской пене.';

  @override
  String get impactReportScreen_subhanallahiWaBihamdihi_992976 =>
      'СубханАллахи ва бихамдихи';

  @override
  String impactReportScreen_totalRecitations_5ed733(String arg1) {
    return 'Всего чтений: $arg1\\n';
  }

  @override
  String impactReportScreen_dividedByForgivenessCycles_4e175d(String arg1) {
    return 'Разделить на 100 → циклы прощения: $arg1';
  }

  @override
  String impactReportScreen_dividedByPalaces_6f066c(String arg1) {
    return 'Разделено на 10 → дворцы: $arg1';
  }

  @override
  String get impactReportScreen_laIlahaIllallahuWahdahu_895dde =>
      'Ля иляха илляЛлаху вахдаху ля шарика лаху...';

  @override
  String impactReportScreen_setsOfSetsSlaves_b43b31(String arg1, String arg2) {
    return 'Наборы по 10 → наборы $arg1 × 4 ведомых = $arg2';
  }

  @override
  String impactReportScreen_totalSalawatSent_cfe45e(String arg1) {
    return 'Всего отправлено салаватов: $arg1\\n';
  }

  @override
  String impactReportScreen_multipliedByBlessingsReceived_52810f(String arg1) {
    return 'Умножено на 10 → получено $arg1 благословений';
  }

  @override
  String get impactReportScreen_protectionFromEvil_37b53a => 'Защита от зла';

  @override
  String get impactReportScreen_goodHealthProtection_058808 =>
      'Крепкое здоровье и защита';

  @override
  String impactReportScreen_totalInvocations_1fd02b(String arg1) {
    return 'Всего вызовов: $arg1';
  }

  @override
  String impactReportScreen_dividedByQuranCompletions_b9a013(String arg1) {
    return 'Разделить на 3 → $arg1 Завершения Корана';
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
    return '${arg1}m';
  }

  @override
  String impactReportScreen_ago_71107c(String arg1) {
    return '$arg1 мин назад';
  }

  @override
  String impactReportScreen_moAgo_325a71(String arg1) {
    return '$arg1мес назад';
  }

  @override
  String impactReportScreen_failed_190558(String e) {
    return 'Не удалось: $e';
  }

  @override
  String impactReportScreen_funded_add009(String arg1) {
    return '$arg1% профинансировано';
  }

  @override
  String get impactReportScreen_yourLifetimeImpact_8bfdcd =>
      'Ваше влияние на всю жизнь';

  @override
  String get impactReportScreen_startYourImpactJourney_1ae8c4 =>
      'Начните свой путь воздействия';

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
    return '+$arg1 Семена';
  }

  @override
  String get levelScreen_laIlahaIllallah_e8c26b => 'Ля иляха илляЛлах х100';

  @override
  String levelScreen_seedsBoost_464454(String arg1) {
    return '$arg1× Усиление семян';
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
    return '$current / $arg1 дней';
  }

  @override
  String levelScreen_dayStreak_df2abf(String arg1) {
    return '$arg1 дневная серия';
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
  String get quranMini_inTheNameOf_46925d =>
      'Во имя Аллаха, Милостивого, Милосердного.';

  @override
  String get quranMini_allPraiseBelongsTo_2d51df =>
      'Вся хвала принадлежит Аллаху, Господу всех миров.';

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
    return '$arg1 из $arg2 семян';
  }

  @override
  String orphanDetailScreen_through_2cdb72(String arg1) {
    return 'Через $arg1';
  }

  @override
  String get orphanDetailScreen_andTheyGiveFood_7ddcff =>
      'И пищу они дают, несмотря на свою любовь к ней, нуждающемуся, сироте и пленнику.';

  @override
  String orphanDetailScreen_ago_71107c(String arg1) {
    return '$arg1 мин назад';
  }

  @override
  String orphanDetailScreen_moAgo_325a71(String arg1) {
    return '$arg1мес назад';
  }

  @override
  String orphanDetailScreen_seeds_30d8dc(String _availablePoints) {
    return '$_availablePoints Семена';
  }

  @override
  String orphanDetailScreen_sponsor_b34bcf(String arg1) {
    return 'Спонсор $arg1';
  }

  @override
  String orphanDetailScreen_jazakallahKhayranSeedsSponsored_316bec(
    String amount,
  ) {
    return 'ДжазакаЛлах Хайран! $amount Семена спонсируются.';
  }

  @override
  String orphanDetailScreen_chooseHowManySeeds_b69aa2(String arg1) {
    return 'Выберите, сколько семян дать. Минимум $arg1.';
  }

  @override
  String orphanDetailScreen_yourBalanceSeeds_f8045b(String arg1) {
    return 'Ваш баланс: $arg1 Сиды';
  }

  @override
  String get profileSettingsScreen_nameCannotBeEmpty_c737ab =>
      'Имя не может быть пустым';

  @override
  String get profileSettingsScreen_signedInWithGoogle_17e053 =>
      'Вошёл через Google';

  @override
  String get profileSettingsScreen_signedInWithQuran_2e1ffc =>
      'Авторизован через Quran.com.';

  @override
  String get profileSettingsScreen_signedInWithEmail_dd881f =>
      'Вошёл с помощью электронной почты';

  @override
  String profileSettingsScreen_seeds_53d666(String arg1) {
    return '$arg1 Семена';
  }

  @override
  String get profileSettingsScreen_guidesFAQsAndHow_b990d6 =>
      'Руководства, часто задаваемые вопросы и инструкции';

  @override
  String get profileSettingsScreen_somethingNotWorkingTell_07f659 =>
      'Что-то не работает? Расскажите нам';

  @override
  String projectDetailScreen_organisedBy_8b317a(String sponsor) {
    return 'Организатор: $sponsor\\n\\n';
  }

  @override
  String get projectDetailScreen_fundedSoFarEvery_dab3fd =>
      'На данный момент получено финансирование, каждое семя имеет значение!\\n\\n';

  @override
  String get projectDetailScreen_openSabiqRewardsApp_cdda14 =>
      'Откройте приложение Sabiq Rewards, чтобы пожертвовать свои семена и получить вознаграждение.\\n';

  @override
  String get projectDetailScreen_sabiqrewardsSadaqahIslamicCharity_663ba5 =>
      '#SabiqRewards #Садака #ИсламскаяБлаготворительность';

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
      'Сделайте пожертвование для оказания срочной, жизненно важной помощи палестинцам, испытывающим острую нехватку еды, воды и медикаментов...';

  @override
  String projectDetailScreen_seeds_47387f(String arg1) {
    return '$arg1 Семена';
  }

  @override
  String projectDetailScreen_e4e562_e4e562(String arg1) {
    return '$arg1%';
  }

  @override
  String projectDetailScreen_ago_71107c(String arg1) {
    return '$arg1 мин назад';
  }

  @override
  String projectDetailScreen_moAgo_325a71(String arg1) {
    return '$arg1мес назад';
  }

  @override
  String quranHubScreen_saved_9c28a3(String arg1) {
    return '$arg1 сохранено';
  }

  @override
  String get quranScreen_couldNotLoadAyah_62f120 =>
      'Не удалось загрузить аю. Пожалуйста, повторите попытку.';

  @override
  String get quranScreen_noConnectionCachedData_e5a215 =>
      'Нет связи. Кэшированные данные могут быть доступны.';

  @override
  String quranScreen_ayahs_c98642(String arg1) {
    return '$arg1 аяс';
  }

  @override
  String get quranScreen_couldNotRemoveBookmark_699a82 =>
      'Не удалось удалить закладку, повторите попытку.';

  @override
  String quranScreen_removedBookmark_d7a16a(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'Удалена закладка $_surahName $_surah:$_ayah';
  }

  @override
  String get quranScreen_couldNotSaveBookmark_976448 =>
      'Не удалось сохранить закладку, повторите попытку.';

  @override
  String quranScreen_bookmarked_2c6203(
    String _surahName,
    String _surah,
    String _ayah,
  ) {
    return 'В закладках $_surahName $_surah:$_ayah';
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
  String get quranScreen_addedToFavourites_b3cce0 => '♥️Добавлено в избранное';

  @override
  String quranScreen_pt_9e58e8(String arg1) {
    return '$arg1 точка';
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
    return '$_ayahsToday аяты читаю';
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
      'Неожиданная ошибка при входе в Google';

  @override
  String get startJourneyScreen_connectedToQuranCom_c0c631 =>
      'Подключено к Quran.com';

  @override
  String tafsirScreen_verses_fed624(String arg1) {
    return '$arg1 стихи';
  }

  @override
  String tafsirScreen_ayahOf_63c42b(String _ayah, String _surahLen) {
    return 'Ая $_ayah из $_surahLen';
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
      'В настоящее время пожертвование не может быть обработано.';

  @override
  String get donationService_anUnexpectedNetworkError_914b7a =>
      'Произошла непредвиденная сетевая ошибка.';

  @override
  String get donationService_sponsorshipReceived_671201 =>
      'Спонсорство получено 💝';

  @override
  String donationService_youSponsoredSeedsJazak_7711e1(String amount) {
    return 'Вы спонсировали семена $amount · Джазак Аллах хайр.';
  }

  @override
  String get donationService_sponsorshipCouldNotBe_55003e =>
      'В настоящее время не удалось обработать спонсорство.';

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
  String get streakService_theCenturion_f1de7f => 'Центурион';

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
  String get xpService_newBadgeUnlocked_2c8d0e =>
      'Новый значок разблокирован 🏆';

  @override
  String get xpService_dailyLoginBonus_d011fa => 'Ежедневный бонус за вход';

  @override
  String xpService_seedsWelcomeBack_47888a(String arg1) {
    return '+$arg1 Семена · с возвращением!';
  }

  @override
  String get xpService_daySealed_037a56 => 'День запечатан 🌙';

  @override
  String xpService_sabiqSeedsConfirmedBonus_702902(
    String flushed,
    String bonus,
  ) {
    return '+$flushed Sabiq Seeds подтверждено! (бонус $bonus за запечатывание)';
  }

  @override
  String xpService_sabiqSeedsConfirmed_34969c(String flushed) {
    return '+$flushed Sabiq Seeds подтверждено!';
  }

  @override
  String get dhikrExitCelebration_everyBreathCounts_45b3df =>
      'Каждый вздох имеет значение.';

  @override
  String get impactAnimation_yourRewardHasBeen_e3d106 =>
      'Ваша награда записана.';

  @override
  String get motivationalPopup_verilyWithHardshipComes_f23637 =>
      'Воистину, за трудностями приходит облегчение.\\nКаждое испытание — это дверь к чему-то большему.';

  @override
  String get motivationalPopup_quranAlInshirah_d81f8a =>
      'Коран • Аль-Иншира 94:6';

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
      'Цените свое время.\\nПоделитесь добром с другом сегодня,\\nлюбое доброе дело, которым вы поделились, не является садакой.';

  @override
  String get motivationalPopup_guideOthersToGood_6105c4 =>
      'Направляйте других к добру, и вы получите за это награду.';

  @override
  String get motivationalPopup_theBestOfPeople_1f6906 =>
      'Лучшие из людей – это те, кто наиболее полезен другим.';

  @override
  String get motivationalPopup_verilyInTheRemembrance_16476d =>
      'Воистину, в поминании Аллаха сердца обретают покой.';

  @override
  String get motivationalPopup_remindYourselfTimeIs_38ae33 =>
      'Напоминайте себе, что время – самая ценная садака.';

  @override
  String get motivationalPopup_yourTimeIsYour_be6731 =>
      'Ваше время — ваш самый\\nценный актив. Инвестируйте с умом\\в то, что останется навсегда.';

  @override
  String get motivationalPopup_quranAlAnfal_b10486 => 'Коран • Аль-Анфаль 8:28';

  @override
  String get motivationalPopup_takeAdvantageOfFive_e573fd =>
      'Воспользуйтесь преимуществом «пять до пяти».';

  @override
  String motivationalPopup_seeds_3a9c69(String arg1) {
    return '+$arg1 Семена';
  }

  @override
  String get motivationalPopup_completeNowEarnSeeds_16ea6e =>
      'Завершите сейчас → получите бонус +50 семян.';

  @override
  String get motivationalPopup_finishYourAzkaarEarn_e264fa =>
      'Завершите свой Азкаар → получите бонус +30 семян.';

  @override
  String get motivationalPopup_shareSabiqWithSomeone_c60dcc =>
      'Поделитесь Сабиком с кем-нибудь → заработайте +100 семян.';

  @override
  String get motivationalPopup_keepYourSpiritualMomentum_0f172c =>
      'Продолжайте свой духовный импульс\\n и наблюдайте, как растут ваши Семена ✨';

  @override
  String get projectMediaCarousel_couldNotLoadVideo_deb8dd =>
      'Не удалось загрузить видео';

  @override
  String get quranExitCelebration_beautifulRecitation_9d2655 =>
      'Красивое декламирование.';

  @override
  String get quranExitCelebration_everyMomentCounts_fddb4c =>
      'Каждый момент имеет значение.';

  @override
  String sealCoinAnimation_e16fa4_e16fa4(String arg1) {
    return '+$arg1';
  }

  @override
  String impactReportScreen_totalHasanatFromQuran(String n) {
    return 'Всего хасанат из Корана: $n';
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
    return 'Умножается на 8 ворот → $n проемов';
  }

  @override
  String impactReportScreen_bonusHasanaat(String n) {
    return 'Бонусный хасанат: $n';
  }

  @override
  String impactReportScreen_totalDonatedSeeds(String n, String seeds) {
    return 'Всего пожертвовано: $n $seeds';
  }

  @override
  String get dashboardScreen_dashboardLoadFailed =>
      'Не удалось загрузить панель управления. Пожалуйста, попробуйте еще раз.';

  @override
  String get zikrLabel => 'Зикр';

  @override
  String get quranLabel => 'Коран';

  @override
  String streakService_dayStreakBody(String days, String type, String bonus) {
    return '$days-день, серия $type · Разблокированы бонусные семена +$bonus';
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
    return 'Вы пожертвовали $amount Семена · Джазак Аллах хайр.';
  }

  @override
  String streakService_60a570_60a570(Object arg1, Object localLabel) {
    return '$arg1 $localLabel';
  }

  @override
  String xpService_badgeEarnedBody(String name) {
    return 'Вы заслужили значок «$name».';
  }

  @override
  String get localReminderScheduler_channelName =>
      'Уведомления о вознаграждениях Сабика';

  @override
  String get localReminderScheduler_morningTitle => 'Утренний Азкар';

  @override
  String get localReminderScheduler_morningBody =>
      'Начните свой день под защитой Аллаха — прочтите утренний азкар.';

  @override
  String get localReminderScheduler_astaghfirTitle => 'Момент для истигфара';

  @override
  String get localReminderScheduler_astaghfirBody =>
      '«Астагфируллах» полирует сердце и открывает двери пропитания. Пауза на одну минуту.';

  @override
  String get localReminderScheduler_eveningTitle => 'Вечерний Азкар';

  @override
  String get localReminderScheduler_eveningBody =>
      'Защитите себя на ночь — прочтите вечерний азкар.';

  @override
  String get localReminderScheduler_sleepTitle => 'Время успокоиться';

  @override
  String get localReminderScheduler_sleepBody =>
      'Завершите день азкаром сна — Аятуль Курси, тремя Кулами и дуа перед сном.';

  @override
  String get localReminderScheduler_kahfAmTitle =>
      'Сегодня пятница — прочтите суру Аль-Кахф.';

  @override
  String get localReminderScheduler_kahfBody =>
      'Кто читает суру «Аль-Кахф» в пятницу, тому свет сияет между двумя пятницами.';

  @override
  String get localReminderScheduler_salawatTitle => 'Салават в пятницу';

  @override
  String get localReminderScheduler_salawatBody =>
      'Прочтите сегодня салават Пророку ﷺ щедро — ему будут показаны деяния пятницы.';

  @override
  String get localReminderScheduler_kahfPmTitle =>
      'Не пропустите суру Аль-Кахф сегодня';

  @override
  String get localReminderScheduler_kahfPmBody =>
      'Несколько часов до Магриба — прочтите суру Аль-Кахф, если вы еще этого не сделали.';

  @override
  String get liveNotificationService_validateChannelDesc =>
      'Напоминания о том, что нужно запечатать ожидающие семена до полуночи.';

  @override
  String get liveNotificationService_validateTicker =>
      'Запечатайте свои семена до полуночи';

  @override
  String get liveNotificationService_validateTitle =>
      'Запечатайте свои семена до полуночи!';

  @override
  String liveNotificationService_validateBody(String n) {
    return 'У вас есть $n, ожидающие раздачи. Нажмите «Запечатать день» до полуночи, иначе срок их действия истечет.';
  }

  @override
  String liveNotificationService_ayatRead(String n) {
    return '$n Аят Прочтите сегодня 📖';
  }

  @override
  String liveNotificationService_readQuranTime(String time) {
    return '$time Прочтите Коран сегодня ⏱️';
  }

  @override
  String get liveNotificationService_nothingRead =>
      'Сегодня ничего не читали из Корана 📖';

  @override
  String liveNotificationService_dhikrCompleted(String n) {
    return '$n Зикр сегодня завершен 📿';
  }

  @override
  String liveNotificationService_tickerBusy(String ayah, String dhikr) {
    return '$ayah аят · $dhikr зикр сегодня';
  }

  @override
  String get liveNotificationService_tickerIdle =>
      'Продолжайте читать и делать Зикр!';

  @override
  String get liveNotificationService_channelDesc =>
      'Живите сегодняшним прогрессом в Коране и Зикре';

  @override
  String get liveNotificationService_seedsToday => 'Ваши семена сегодня ✨';

  @override
  String get liveNotificationService_summary => 'Нажмите, чтобы открыть Сабик';

  @override
  String get quranApiService_notConnected => 'Не подключен к Quran.com';

  @override
  String get quranApiService_notSignedIn => 'Не авторизован в Noor';

  @override
  String quranApiService_syncFailedPush(String n) {
    return 'Не удалось синхронизировать, закладки $n не удалось отправить на Quran.com (проверьте токен/конечную точку).';
  }

  @override
  String get quranApiService_alreadyInSync => 'Закладки уже синхронизированы';

  @override
  String quranApiService_syncedBookmarks(String total, String up, String down) {
    return 'Синхронизированные закладки $total ($up вверх, $down вниз)';
  }

  @override
  String quranApiService_syncFailedPartial(String n) {
    return ', $n не удалось';
  }

  @override
  String quranApiService_syncFailedGeneric(String error) {
    return 'Синхронизация не удалась: $error';
  }

  @override
  String get authScreen_dontHaveAnAccountSignUp =>
      'У вас нет учетной записи? Зарегистрироваться';

  @override
  String get dhikrExitCelebration_keepItUp => 'Так держать!';

  @override
  String get unknownError => 'Неизвестная ошибка';

  @override
  String get celebrationStatSeeds => 'СЕМЕНА';

  @override
  String get celebrationStatSeedsEarned => 'ЗАРАБОТАНЫ СЕМЕНА';

  @override
  String get celebrationStatAyahs => 'АЯХС';

  @override
  String get celebrationStatTime => 'ВРЕМЯ';

  @override
  String get celebrationStatStreak => 'СТРИК';

  @override
  String get celebrationStreakStartToday => 'Начни сегодня';

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
