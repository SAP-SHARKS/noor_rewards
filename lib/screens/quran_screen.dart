import 'dart:async';
import 'dart:convert';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/xp_service.dart';
import '../services/streak_service.dart';
import '../services/live_notification_service.dart';
import '../services/quran_api_service.dart';   // Quran Foundation authenticated API


// ── Palette ────────────────────────────────────────────────────────────────────
const _kBg    = Color(0xFFEDF7F4); // Light mint (gradient start)
const _kWhite = Color(0xFFFFFFFF);
const _kText  = Color(0xFF1C1C1E);
const _kSub   = Color(0xFF8E8E93);
const _kTeal  = Color(0xFF2BAE99);
const _kGold  = Color(0xFFFFAA00);

// Screen-level gradient for the Quran reading background
// Deep teal-mint top → cool sky-blue mid → soft pearl bottom
// More contrast = noticeably visible gradient on the screen
const _kBgGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFC8EDE6), // rich teal-mint
    Color(0xFFD6EEF7), // cool sky blue
    Color(0xFFEFF8F4), // soft pale green-white
  ],
  stops: [0.0, 0.5, 1.0],
);

// ── All 114 surah lengths (1-indexed, index 0 is unused) ──────────────────────
// 115 entries: index 0 = unused, indices 1-114 = surah ayah counts
const _surahLengths = [
  0,   // padding
  7,  286, 200, 176, 120, 165, 206,  75, 129, 109,  // 1-10
 123, 111,  43,  52,  99, 128, 111, 110,  98, 135,  // 11-20
 112,  78, 118,  64,  77, 227,  93,  88,  69,  60,  // 21-30
  34,  30,  73,  54,  45,  83, 182,  88,  75,  85,  // 31-40
  54,  53,  89,  59,  37,  35,  38,  29,  18,  45,  // 41-50
  60,  49,  62,  55,  78,  96,  29,  22,  24,  13,  // 51-60
  14,  11,  11,  18,  12,  12,  30,  52,  52,  44,  // 61-70
  28,  28,  20,  56,  40,  31,  50,  40,  46,  42,  // 71-80
  29,  19,  36,  25,  22,  17,  19,  26,  30,  20,  // 81-90
  15,  21,  11,   8,   8,  19,   5,   8,   8,  11,  // 91-100 (96=Al-Alaq=19, 97=Al-Qadr=5)
  11,   8,   3,   9,   5,   4,   7,   3,   6,   3,  // 101-110
   5,   4,   5,   6,                                  // 111-114 (An-Nas=6)
];

// ── Translation options ─────────────────────────────────────────────────────────
// All from api.alquran.cloud — fetched on-demand, cached 7 days in Hive.
// (editionId, displayName, author, isRTL)
typedef _TransDef = ({String id, String name, String author, bool rtl});

const List<_TransDef> _translations = [
  // ── English ────────────────────────────────────────────────────────────────────
  (id:'en.sahih',       name:'English — Sahih Intl.',    author:'Saheeh International',            rtl:false),
  (id:'en.pickthall',   name:'English — Pickthall',      author:'Mohammad Marmaduke Pickthall',    rtl:false),
  (id:'en.asad',        name:'English — The Message',    author:'Muhammad Asad',                   rtl:false),
  (id:'en.hilali',      name:'English — Muhsin Khan',    author:'Muhsin Khan & Hilali',            rtl:false),
  // ── Urdu ───────────────────────────────────────────────────────────────────────
  (id:'ur.jalandhry',   name:'اردو — جالندھری',           author:'Fateh Muhammad Jalandhry',        rtl:true),
  (id:'ur.kanzuliman',  name:'اردو — کنز الایمان',        author:'Imam Ahmad Raza Khan',            rtl:true),
  (id:'ur.ahmedali',    name:'اردو — احمد علی',           author:'Shah Ahmed Ali',                  rtl:true),
  (id:'ur.maududi',     name:'اردو — تفہیم القرآن',       author:'Maulana Sayyid Abul Ala Maududi', rtl:true),
  // ── French ─────────────────────────────────────────────────────────────────────
  (id:'fr.hamidullah',  name:'Français — Hamidullah',    author:'Muhammad Hamidullah',             rtl:false),
  // ── Turkish ────────────────────────────────────────────────────────────────────
  (id:'tr.diyanet',     name:'Türkçe — Diyanet',         author:'Diyanet İşleri',                  rtl:false),
  (id:'tr.ates',        name:'Türkçe — Süleyman Ateş',   author:'Süleyman Ateş',                   rtl:false),
  // ── Indonesian ─────────────────────────────────────────────────────────────────
  (id:'id.indonesian',  name:'Bahasa — Indonesian',      author:'Ministry of Religious Affairs',   rtl:false),
  // ── Bengali ────────────────────────────────────────────────────────────────────
  (id:'bn.bengali',     name:'বাংলা — Muhiuddin Khan',  author:'Muhiuddin Khan',                  rtl:false),
  // ── German ─────────────────────────────────────────────────────────────────────
  (id:'de.aburida',     name:'Deutsch — Abu Rida',       author:'Abu Rida Muhammad ibn Ahmad',     rtl:false),
  // ── Spanish ────────────────────────────────────────────────────────────────────
  (id:'es.asad',        name:'Español — Asad',           author:'Muhammad Asad',                   rtl:false),
];


typedef _QuranScript = ({String name, String apiSlug, String arabicPreview, TextStyle Function(double size, Color color, double? height, FontWeight weight) style});

final List<_QuranScript> _kQuranScripts = [
  (
    name: 'Uthmani (Madinah)',
    apiSlug: 'uthmani',
    arabicPreview: 'بِسْمِ ٱللَّهِ',
    style: (size, color, height, weight) =>
        GoogleFonts.amiri(fontSize: size + 4, color: color, height: height, fontWeight: weight),
  ),
  (
    name: 'IndoPak',
    apiSlug: 'indopak',
    arabicPreview: 'بِسۡمِ اللهِ',
    style: (size, color, height, weight) =>
        TextStyle(fontFamily: 'AlQalamQuran', fontSize: size + 6, color: color, height: height, fontWeight: weight),
  ),
];

// ── Reciter options ──────────────────────────────────────────────────────────
const _reciters = [
  ('ar.alafasy',      'Mishary',   '🎙️', '128'),
  ('ar.mahermuaiqly', 'Maher',     '🎙️', '128'),
  ('ar.abdulsamad',   'Al-Samad',  '🎙️', '64'),
];

class QuranScreen extends StatefulWidget {
  final int initialSurah;
  final int initialAyah;
  const QuranScreen({super.key, this.initialSurah = 2, this.initialAyah = 1});
  @override State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> with WidgetsBindingObserver {
  // ── Position ─────────────────────────────────────────────────────────────────
  int _surah = 2, _ayah = 1;

  // ── Loaded data ───────────────────────────────────────────────────────────────
  String _arabic = '', _translation = '', _surahName = 'Al-Baqarah';
  String? _audioUrl;

  // ── Settings ──────────────────────────────────────────────────────────────────
  String _translationEdition = 'en.sahih';
  int _reciterIdx = 0;

  // ── Reader Settings ───────────────────────────────────────────────────
  // Display
  bool   _darkMode          = false;   // dark reading mode
  double _arabicFontSize    = 28.0;    // 20-44
  double _mushafFontSize    = 32.0;    // 16-48 (for full page mode)
  double _translationFontSize = 15.0;  // 12-22
  int    _quranScriptIdx     = 0;       // index into _kQuranScripts
  bool   _showTranslation   = false;   // show/hide translation block
  bool   _showProgressCard  = true;    // show/hide daily progress card
  bool   _showPointsBanner  = true;    // show/hide +points banner
  bool   _showSurahBanner   = false;   // show/hide surah header banner
  bool   _fullScreenMode    = false;   // hide appbar+nav for focus
  // Reading aids
  bool   _wordByWord        = false;   // word-by-word mode
  List<Map<String, dynamic>> _wbwWords = [];  // [{arabic, translation}]
  bool   _wbwLoading        = false;
  int?   _wbwPrefetchedSurah;              // surah whose bulk WBW is cached
  // Full-page Mushaf — PageView-based (one Quran page per PageView page)
  bool   _fullPageMode      = false;
  int    _currentPage       = 1;         // current Quran page (1–604)
  Key    _feedCenterKey     = UniqueKey();
  int    _feedJumpPage      = 1;
  Timer? _pageTimer;
  int    _pageSeconds       = 0;
  int    _pageXpEarned      = 0;
  bool   _timerShouldRun    = false;
  // Cache: page# → list of ayahs  (fetched once per page, held in memory)
  final Map<int, List<Map<String, dynamic>>> _loadedPages    = {};
  final Set<int>                              _loadingPages   = {};
  // Keep scroll controller for backward compat (unused in PageView path)
  ScrollController? _fullPageScrollController;
  bool   _autoAdvance       = false;   // advance ayah when audio ends
  bool   _repeatAyah        = false;   // repeat current ayah audio
  // Notifications + alerts
  bool   _dailyReminder     = true;    // daily reading reminder on
  bool   _soundAlerts       = true;    // sound alert on milestone
  // Theme accent (index into _kThemeAccents)
  int    _themeIdx          = 0;
  // Mushaf immersive overlay (tap-to-show controls)
  bool   _showMushafControls = true;
  Timer? _controlsHideTimer;

  // ── Stats ─────────────────────────────────────────────────────────────────────
  int _ayahsToday = 0, _pointsToday = 0;

  // ── Bookmarks (stored as "surah:ayah" strings) ────────────────────────────────
  final Set<String> _bookmarks  = {};
  final Set<String> _favourites = {};

  // ── UI state ──────────────────────────────────────────────────────────────────
  bool _loading = true;
  final bool _saving = false;

  // ── Inline tafsir (bottom-sheet) ──────────────────────────────────────────────
  static const _qTafsirEditions = [
    (id:'en-tafisr-ibn-kathir',     name:'Ibn Kathir (EN)',  emoji:'🕌', src:'cdn',   slug:'en-tafisr-ibn-kathir',     rtl:false),
    (id:'en-tafsir-maarif-ul-quran',name:'Maarif ul Quran',  emoji:'📚', src:'cdn',   slug:'en-tafsir-maarif-ul-quran', rtl:false),
    (id:'ur-tafseer-ibn-e-kaseer',  name:'ابن کثیر (اردو)', emoji:'📖', src:'cdn',   slug:'ur-tafseer-ibn-e-kaseer',   rtl:true),
    (id:'ur-tafsir-bayan-ul-quran', name:'بیان القرآن',     emoji:'🎓', src:'cdn',   slug:'ur-tafsir-bayan-ul-quran',  rtl:true),
  ];
  int    _tafsirEditionIdx = 0;
  String _tafsirText       = '';
  bool   _tafsirLoading    = false;
  bool   _showAudioPlayer  = false;  // hidden until user taps Listen

  // ── Feature-discovery hint tooltip ───────────────────────────────────────────
  static const _kHints = [
    (icon: '🌙', text: 'Want Dark mode?'),
    (icon: '🔡', text: 'Adjust font size'),
    (icon: '🌍', text: 'Change translation'),
    (icon: '⛶',  text: 'Try full screen!'),
    (icon: '🎨', text: 'Change colour theme'),
    (icon: '🔤', text: 'Arabic font size'),
  ];
  bool          _showHint    = false;  // for tune-button glow only
  int           _hintIdx     = 0;
  Timer?        _hintTimer;
  OverlayEntry? _hintOverlay;


  // ── Audio ─────────────────────────────────────────────────────────────────────
  final _player = AudioPlayer();
  Duration _pos = Duration.zero, _dur = Duration.zero;
  bool _isPlaying = false, _audioLoading = false;

  // ── Cache ─────────────────────────────────────────────────────────────────────
  late Box _cache;

  final _sb = Supabase.instance.client;

  // ── Theme accent ──────────────────────────────────────────────────────────────
  static const _kThemeAccents = [
    (Color(0xFF2BAE99), 'Teal',   '🌊'),
    (Color(0xFF6C63FF), 'Indigo', '🔮'),
    (Color(0xFFE67E22), 'Amber',  '🔥'),
    (Color(0xFFE91E63), 'Rose',   '🌸'),
    (Color(0xFF2196F3), 'Blue',   '💧'),
  ];
  Color get _accent => _kThemeAccents[_themeIdx.clamp(0, _kThemeAccents.length - 1)].$1;

  // ─────────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _surah = widget.initialSurah;
    _ayah  = widget.initialAyah;
    _init();
    // Configure audio session so other apps yield to us
    AudioSession.instance.then((session) {
      session.configure(const AudioSessionConfiguration.music());
    });
    _player.playerStateStream.listen((s) {
      if (mounted) setState(() => _isPlaying = s.playing);
      // Auto-advance: when playback completes, move to next ayah
      if (s.processingState == ProcessingState.completed && _autoAdvance && mounted) {
        _nextAyah(fromAutoPlay: true);
      }
    });
    _player.positionStream.listen((p) {
      if (mounted) setState(() => _pos = p);
    });
    _player.durationStream.listen((d) {
      if (d != null && mounted) setState(() => _dur = d);
    });

    // Show feature-discovery hint once per page visit (via Overlay so it overlaps AppBar)
    _hintIdx = DateTime.now().millisecond % _kHints.length;
    _hintTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() => _showHint = true);
      _insertHintOverlay();
      _hintTimer = Timer(const Duration(milliseconds: 1700), () {
        if (mounted) setState(() => _showHint = false);
        _hintOverlay?.remove();
        _hintOverlay = null;
      });
    });
  }

  void _insertHintOverlay() {
    _hintOverlay?.remove();
    final statusH = MediaQuery.of(context).padding.top;
    final hint    = _kHints[_hintIdx];
    final isDark  = _darkMode;
    final accent  = _accent;

    _hintOverlay = OverlayEntry(
      builder: (_) => Positioned(
        // Sit inside the AppBar, just to the left of the action icons
        top: statusH + 10,
        right: 52,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: accent.withValues(alpha: 0.30),
                      blurRadius: 18, offset: const Offset(0, 4),
                      spreadRadius: 1),
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6),
                ],
                border: Border.all(color: accent.withValues(alpha: 0.22)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(hint.icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(hint.text,
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : _kText)),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 12, color: accent),
              ]),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_hintOverlay!);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_fullPageMode) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Stop the physical timer but DO NOT touch _timerShouldRun.
      // _timerShouldRun is user intent — only explicit play/pause changes it.
      // If we wrote it here, any intermediate paused event (e.g. lock screen
      // transition on some Android versions) would destroy the intent.
      if (_pageTimer != null) {
        _stopPageTimer();
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed) {
      // Screen is back. Restart physical timer if user wanted it running.
      // _timerShouldRun was never cleared by paused, so it reliably holds
      // whatever the user last chose — even through multiple lock/unlock cycles.
      if (_timerShouldRun && _pageTimer == null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _fullPageMode && _timerShouldRun && _pageTimer == null) {
            _resumePageTimer();
          }
        });
      }
    }
    // `inactive` intentionally ignored.
  }

  @override
  void dispose() {
    // Persist position locally (instant) + remotely (fire-and-forget)
    _syncReadingPosition();
    _savePagePosition();
    WidgetsBinding.instance.removeObserver(this);
    _hintTimer?.cancel();
    _hintOverlay?.remove();
    _pageTimer?.cancel();
    _controlsHideTimer?.cancel();
    _fullPageScrollController?.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _cache = await Hive.openBox('quran_cache');
    // Restore persisted reading mode
    _fullPageMode = _cache.get('pref_mushaf_mode', defaultValue: false) as bool;
    _wordByWord   = _cache.get('pref_wbw_mode', defaultValue: false) as bool;
    await Future.wait([_loadProgress(), _loadBookmarks(), _loadFavourites()]);
    await _fetchAyah(_surah, _ayah);
    // If user was in Mushaf mode last time, re-enter at the exact saved page
    if (_fullPageMode) {
      // Restore from local Hive cache (instant, no network dependency)
      final savedPage  = _cache.get('pref_mushaf_page', defaultValue: _currentPage) as int;
      final savedSurah = _cache.get('pref_mushaf_surah', defaultValue: _surah) as int;
      final savedAyah  = _cache.get('pref_mushaf_ayah', defaultValue: _ayah) as int;
      final page = savedPage.clamp(1, 604);
      setState(() {
        _currentPage = page;
        _surah = savedSurah;
        _ayah = savedAyah;
        _showMushafControls = true;
      });
      _enterFullPageScrollMode(page);
      _startPageTimer();
      _controlsHideTimer?.cancel();
      _controlsHideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showMushafControls = false);
      });
    }
    // Prefetch entire surah's word-by-word data in background so WBW toggle is instant
    _prefetchSurahWbw(_surah);
    // If WBW was active, fetch words for current ayah
    if (_wordByWord) _fetchWordByWord(_surah, _ayah);
  }

  // ── Load last read position + today's stats ───────────────────────────────────
  Future<void> _loadProgress() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _sb.from('quran_progress').upsert({'user_id': uid}, onConflict: 'user_id');
      final row = await _sb.from('quran_progress').select().eq('user_id', uid).single();
      final today = _todayStr();
      setState(() {
        // Only override to saved position if user didn't request a specific start
        if (widget.initialSurah == 2 && widget.initialAyah == 1) {
          _surah        = row['current_surah'] ?? 2;
          _ayah         = row['current_ayah']  ?? 1;
          _currentPage  = row['current_page']  ?? 1;
        }
        if ((row['last_read_date'] ?? '') == today) {
          _ayahsToday  = row['ayahs_read_today'] ?? 0;
          _pointsToday = _ayahsToday * XpReward.ayahRead;
        }
      });
    } catch (_) {}
  }

  // ── Load all bookmarks for this user ─────────────────────────────────────────
  Future<void> _loadBookmarks() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final rows = await _sb.from('quran_bookmarks')
          .select('surah, ayah').eq('user_id', uid);
      setState(() {
        _bookmarks.addAll(rows.map((r) => '${r['surah']}:${r['ayah']}'));
      });
    } catch (_) {}
  }

  // ── Load favourites for this user ─────────────────────────────────────────────
  Future<void> _loadFavourites() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final rows = await _sb.from('quran_bookmarks')
          .select('surah, ayah').eq('user_id', uid).eq('is_favourite', true);
      setState(() {
        _favourites.addAll(rows.map((r) => '${r['surah']}:${r['ayah']}'));
      });
    } catch (_) {}
  }

  // ── Fetch ayah from cache or API ─────────────────────────────────────────────
  Future<void> _fetchAyah(int surah, int ayah) async {
    if (mounted) setState(() => _loading = true);
    final recEdition = _reciters[_reciterIdx].$1;
    final scriptSlug = _kQuranScripts[_quranScriptIdx].apiSlug;
    final cacheKey   = '$surah:$ayah:$_translationEdition:$recEdition:$scriptSlug';

    // ── 1. Hive cache hit (7-day TTL) — skip entry if translation is empty ──
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      final cachedAt = DateTime.tryParse(cached['ts'] ?? '');
      final transOk  = (cached['trans'] as String? ?? '').isNotEmpty;
      // A valid cache hit must: (a) be fresh AND (b) have a translation.
      // If trans is empty it means it was cached before the API fallback was
      // added; treat it as a miss so we re-fetch the correct text.
      if (cachedAt != null &&
          DateTime.now().difference(cachedAt).inDays < 7 &&
          transOk) {
        setState(() {
          _arabic      = _QuranScreenState._stripQuranicAnnotations(cached['arabic'] ?? '');
          _translation = cached['trans']  ?? '';
          _audioUrl    = cached['audio'];
          _surahName   = cached['surahName'] ?? '';
          _loading     = false;
        });
        _fetchWordByWord(surah, ayah);
        return;
      }
    }

    // ── Fetch from network (cache miss) ──────────────────────────────────────
    try {
      // Calculate global verse ID for this surah (1-indexed, cumulative)
      int startVerseId = 1;
      for (int i = 1; i < surah; i++) { startVerseId += _surahLengths[i]; }

      // Fetch Arabic Script (Uthmani, Indopak, etc.) from Quran.com API
      final arabicMap = await QuranApiService.instance.surahScript(surah: surah, scriptSlug: scriptSlug);

      // Translation: Supabase DB is primary for en.sahih (fastest).
      // All other editions go through QuranApiService, which tries the
      // authenticated Quran Foundation API first (so alquran.cloud is only
      // used as a last fallback for unsupported editions).
      final Map<int, String> transMap = {};

      if (_translationEdition == 'en.sahih') {
        // Fast Supabase path for the default edition
        final transList = await _sb.from('quran_translations')
            .select('verse_id, text')
            .gte('verse_id', startVerseId)
            .lte('verse_id', startVerseId + _surahLengths[surah] - 1)
            .eq('edition', 'en.sahih');
        for (final item in transList) {
          transMap[item['verse_id'] as int] = item['text'] as String? ?? '';
        }
      } else {
        // Authenticated Quran Foundation API (alquran.cloud is only used as
        // an internal fallback inside QuranApiService for unknown editions)
        final fetched = await QuranApiService.instance.surahTranslation(
          surah:       surah,
          edition:     _translationEdition,
          surahLength: _surahLengths[surah],
          startVerseId: startVerseId,
        );
        transMap.addAll(fetched);
      }

      final sName  = _surahNames[surah - 1];
      final nowStr = DateTime.now().toIso8601String();
      final recBitrate = _reciters[_reciterIdx].$4;
      for (int a = 1; a <= _surahLengths[surah]; a++) {
        final vId  = startVerseId + a - 1;
        final cKey = '$surah:$a:$_translationEdition:$recEdition:$scriptSlug';
        await _cache.put(cKey, {
          'arabic'   : arabicMap[a] ?? '',
          'trans'    : transMap[vId] ?? '',
          'audio'    : 'https://cdn.islamic.network/quran/audio/$recBitrate/$recEdition/$vId.mp3',
          'surahName': sName,
          'ts'       : nowStr,
        });
      }

      // Display the current ayah
      final fresh = _cache.get(cacheKey);
      if (fresh != null && fresh['arabic'].toString().isNotEmpty) {
        if (mounted) {
          setState(() {
            _arabic      = _QuranScreenState._stripQuranicAnnotations(fresh['arabic']);
            _translation = fresh['trans'];
            _audioUrl    = fresh['audio'];
            _surahName   = fresh['surahName'];
            _loading     = false;
          });
        }
        _fetchWordByWord(surah, ayah);
      } else {
        if (mounted) setState(() { _loading = false; _arabic = 'Could not load ayah. Please retry.'; });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _arabic = 'No connection. Cached data may be available.'; });
    }
  }

  // ── Navigate to next ayah ────────────────────────────────────────────────────
  Future<void> _nextAyah({bool fromAutoPlay = false}) async {
    await _player.stop();

    final maxAyah   = _surahLengths[_surah];
    final nextAyah  = _ayah < maxAyah ? _ayah + 1 : 1;
    final nextSurah = _ayah < maxAyah ? _surah : (_surah < 114 ? _surah + 1 : 1);

    bool earnRewards = !fromAutoPlay && !_autoAdvance && !_repeatAyah;

    final surahChanged = nextSurah != _surah;
    setState(() {
      // Sync _currentPage when crossing a surah boundary so Mushaf stays aligned
      if (surahChanged) {
        _currentPage = _kSurahStartPage[nextSurah.clamp(1, 114)];
      }
      _surah = nextSurah; _ayah = nextAyah; _wbwWords = [];
      if (earnRewards) {
        _ayahsToday++; _pointsToday += XpReward.ayahRead;
      }
    });
    // Prefetch new surah's WBW data when crossing surah boundary
    if (surahChanged) _prefetchSurahWbw(nextSurah);

    // Keep all modes in sync
    _syncReadingPosition();

    // Run XP and progress saving in background (don't block UI)
    _saveReadingProgress(nextSurah, nextAyah, earnRewards: earnRewards);

    // Fetch ayah (will pull instantly from cache if same surah)
    _fetchAyah(nextSurah, nextAyah);
  }

  Future<void> _saveReadingProgress(int s, int a, {bool earnRewards = true}) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      if (earnRewards) {
        await _sb.rpc('earn_quran_points', params: {'p_surah': s, 'p_ayah': a});
        // Award XP for reading one ayah
        await XpService.instance.earnXp(XpReward.ayahRead);
        // Update live notification counter
        NoorLiveNotificationService.instance.recordAyah();
        // Record quran streak (idempotent — only counts once per day)
        StreakService.instance.recordActivity(StreakType.quran);
        // Award first-read badge on the very first ayah
        if (_ayahsToday == 1) {
          await XpService.instance.awardBadge('first_quran');
        }
      }
      final today = _todayStr();
      await _sb.from('quran_progress').update({
        'current_surah': s, 'current_ayah': a,
        'current_page': _currentPage,
        'ayahs_read_today': _ayahsToday,
        'last_read_date': today, 'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', uid);
    } catch (_) {}
  }

  /// Sync all reading position caches so Mushaf, Verse, and WBW modes stay aligned.
  void _syncReadingPosition() {
    _cache.put('pref_mushaf_surah', _surah);
    _cache.put('pref_mushaf_ayah', _ayah);
    _cache.put('pref_mushaf_page', _currentPage);
  }

  // Lightweight save: page + surah + ayah position (no XP/streaks) — called on mushaf nav
  Future<void> _savePagePosition() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _sb.from('quran_progress').update({
        'current_surah': _surah,
        'current_ayah' : _ayah,
        'current_page' : _currentPage,
        'updated_at'   : DateTime.now().toIso8601String(),
      }).eq('user_id', uid);
    } catch (_) {}
  }

  // ── Navigate to previous ayah ─────────────────────────────────────────────────
  Future<void> _prevAyah() async {
    await _player.stop();
    int prevAyah = _ayah - 1, prevSurah = _surah;
    if (prevAyah < 1) {
      prevSurah = _surah > 1 ? _surah - 1 : 114;
      prevAyah  = _surahLengths[prevSurah]; // last ayah of prev surah
    }
    setState(() {
      // Sync _currentPage when crossing a surah boundary
      if (prevSurah != _surah) {
        _currentPage = _kSurahStartPage[prevSurah.clamp(1, 114)];
      }
      _surah = prevSurah; _ayah = prevAyah; _wbwWords = [];
    });
    _syncReadingPosition();
    _fetchAyah(prevSurah, prevAyah);
  }

  // ── Fetch word-by-word data ───────────────────────────────────────────────────
  Future<void> _fetchWordByWord(int surah, int ayah) async {
    if (_wordByWord) setState(() { _wbwLoading = true; _wbwWords = []; });

    // 1. Check per-ayah cache first (instant)
    final wbwCacheKey = 'wbw_${surah}_$ayah';
    final cachedWbw = _cache.get(wbwCacheKey);
    if (cachedWbw != null) {
      final cachedAt = DateTime.tryParse((cachedWbw as Map)['ts'] ?? '');
      if (cachedAt != null && DateTime.now().difference(cachedAt).inDays < 30) {
        final words = (cachedWbw['words'] as List)
            .map((w) => Map<String, dynamic>.from(w as Map))
            .toList();
        if (mounted) setState(() { _wbwWords = words; _wbwLoading = false; });
        // Trigger bulk prefetch in background if not done for this surah
        if (_wbwPrefetchedSurah != surah) _prefetchSurahWbw(surah);
        return;
      }
    }

    // 2. Bulk-fetch entire surah (caches every ayah at once)
    if (_wbwPrefetchedSurah != surah) {
      try {
        final allWords = await QuranApiService.instance.wordsBySurah(surah);
        if (allWords.isNotEmpty) {
          final ts = DateTime.now().toIso8601String();
          for (final entry in allWords.entries) {
            await _cache.put('wbw_${surah}_${entry.key}', {
              'words': entry.value,
              'ts': ts,
            });
          }
          _wbwPrefetchedSurah = surah;
          if (allWords.containsKey(ayah) && mounted) {
            setState(() { _wbwWords = allWords[ayah]!; _wbwLoading = false; });
            return;
          }
        }
      } catch (_) {
        // Fall through to single-ayah fetch
      }
    }

    // 3. Fallback: single-ayah fetch
    try {
      final words = await QuranApiService.instance.wordsByKey('$surah:$ayah');
      if (words.isNotEmpty) {
        await _cache.put(wbwCacheKey, {
          'words': words,
          'ts': DateTime.now().toIso8601String(),
        });
        if (mounted) setState(() { _wbwWords = words; _wbwLoading = false; });
      } else {
        if (mounted) setState(() => _wbwLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _wbwLoading = false);
    }
  }

  /// Background bulk prefetch — caches all ayahs for the surah silently
  Future<void> _prefetchSurahWbw(int surah) async {
    try {
      final allWords = await QuranApiService.instance.wordsBySurah(surah);
      if (allWords.isEmpty) return;
      final ts = DateTime.now().toIso8601String();
      for (final entry in allWords.entries) {
        await _cache.put('wbw_${surah}_${entry.key}', {
          'words': entry.value,
          'ts': ts,
        });
      }
      _wbwPrefetchedSurah = surah;
    } catch (_) {}
  }

  // ── Surah → first page lookup (Hafs Uthmani) — offline fallback ──────────────
  static const _kSurahStartPage = <int>[
    0,  // 0 unused (1-indexed)
    1,2,50,77,106,128,151,177,187,208,       // 1-10
    221,235,249,255,262,267,282,293,305,312, // 11-20
    322,332,342,350,359,367,377,385,396,404, // 21-30
    411,415,418,428,434,440,446,453,458,467, // 31-40
    477,483,489,496,499,502,507,511,515,518, // 41-50
    520,523,526,528,531,534,537,542,545,549, // 51-60
    551,553,554,556,558,560,562,564,566,568, // 61-70
    570,572,574,575,577,578,580,582,583,585, // 71-80
    586,587,587,589,590,591,591,592,593,594, // 81-90
    595,595,596,596,597,597,598,598,599,599, // 91-100
    600,600,601,601,601,602,602,602,603,603, // 101-110
    603,604,604,604,                         // 111-114
  ];

  /// Reverse lookup: given a Quran page number, return the surah whose
  /// start page is ≤ that page (i.e. the surah a user is currently reading).
  static int _resolveSurahForPage(int page) {
    int surah = 1;
    for (int s = 1; s <= 114; s++) {
      if (_kSurahStartPage[s] <= page) {
        surah = s;
      } else {
        break;
      }
    }
    return surah;
  }

  // Resolves the Quran page number for the current _surah:_ayah.

  // 1. Checks Hive cache (30-day TTL)
  // 2. Fetches from api.quran.com
  // 3. Falls back to surah start-page table
  Future<int> _resolvePageForCurrentAyah() async {
    final cacheKey = 'pagenum_${_surah}_$_ayah';
    final cached = _cache.get(cacheKey);
    if (cached is int) return cached;

    try {
      final url = 'https://api.quran.com/api/v4/verses/by_key/$_surah:$_ayah'
          '?fields=page_number';
      final res = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final js = jsonDecode(res.body);
        final page = (js['verse']?['page_number'] as num?)?.toInt() ?? 1;
        await _cache.put(cacheKey, page);
        return page;
      }
    } catch (_) {}
    // Offline fallback: use surah start page
    return _kSurahStartPage[_surah.clamp(1, 114)];
  }

  // ── Full-page Mushaf: fetch all ayahs for a page ─────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchPageAyahs(int page) async {
    if (page < 1 || page > 604) return [];
    final cacheKey = 'fullpage_$page';
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      final cachedAt = DateTime.tryParse((cached as Map)['ts'] ?? '');
      if (cachedAt != null && DateTime.now().difference(cachedAt).inDays < 30) {
        return (cached['ayahs'] as List)
            .map((a) => Map<String, dynamic>.from(a as Map))
            .toList();
      }
    }
    try {
      // Authenticated Quran Foundation API (token from .env)
      final ayahs = await QuranApiService.instance.versesByPage(page);
      if (ayahs.isNotEmpty) {
        await _cache.put(cacheKey, {
          'ayahs': ayahs,
          'ts': DateTime.now().toIso8601String(),
        });
        return ayahs;
      }
    } catch (_) {}
    return [];
  }

  // ── Load a page into _loadedPages for continuous scroll ──
  Future<void> _loadPageForScroll(int page) async {
    if (_loadingPages.contains(page) || _loadedPages.containsKey(page)) return;
    if (page < 1 || page > 604) return;
    _loadingPages.add(page);
    final ayahs = await _fetchPageAyahs(page);
    _loadingPages.remove(page);
    if (mounted) setState(() => _loadedPages[page] = ayahs);
  }

  // ── Fetch a single page (used by timer-bar prev/next arrows) ──
  Future<void> _fetchFullPage(int page) async {
    if (page < 1 || page > 604) return;
    // Clear only the target page so it re-fetches; keep neighboring pages loaded
    _loadedPages.remove(page);
    _loadingPages.remove(page);
    await _loadPageForScroll(page);
    // Pre-load neighbors
    _loadPageForScroll(page + 1);
    if (page > 1) _loadPageForScroll(page - 1);
  }

  // ── Enter Mushaf in Continuous Feed mode ──────
  Future<void> _enterFullPageScrollMode(int startPage) async {
    _fullPageScrollController?.dispose();
    _loadedPages.clear();
    _loadingPages.clear();

    _currentPage = startPage;
    _feedJumpPage = startPage;
    _feedCenterKey = UniqueKey(); // Resets CustomScrollView to center on this newly opened page

    _fullPageScrollController = ScrollController();
    _fullPageScrollController!.addListener(_onMushafScroll);

    // Pre-load this page FIRST (await so it's ready before build), then neighbors
    await _loadPageForScroll(startPage);
    _loadPageForScroll(startPage + 1);
    if (startPage > 1) _loadPageForScroll(startPage - 1);

    if (_timerShouldRun) _startPageTimer();
  }

  // Scroll listener - tracks scroll activity to keep the XP timer alive,
  // and allows fetching further pages as they lazily build.
  DateTime _lastMushafSave = DateTime(2000);
  void _onMushafScroll() {
    _syncReadingPosition();
    // Throttle Supabase save to once per 3 seconds
    final now = DateTime.now();
    if (now.difference(_lastMushafSave).inSeconds >= 3) {
      _lastMushafSave = now;
      _savePagePosition();
    }
  }


  // ── Full-page timer: 1 XP per 30 seconds ─────────────────────────────────────
  // Fresh start — resets seconds (use when entering full-page or navigating pages)
  // Sets _timerShouldRun = true (user intent: timer should run).
  void _startPageTimer() {
    _timerShouldRun = true;
    _pageTimer?.cancel();
    _pageSeconds = 0;
    _pageXpEarned = 0;
    _pageTimer = _makePageTimer();
  }

  // Resume — continues from current _pageSeconds (use after pause/screen-unlock)
  // Sets _timerShouldRun = true.
  void _resumePageTimer() {
    _timerShouldRun = true;
    _pageTimer?.cancel();
    _pageTimer = _makePageTimer();
    if (mounted) setState(() {});
  }

  Timer _makePageTimer() {
    return Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _pageSeconds++);
      // Award 1 XP every 30 seconds of reading
      if (_pageSeconds % 30 == 0) {
        _pageXpEarned++;
        _pointsToday += 1;
        XpService.instance.earnXp(1);
      }
    });
  }

  void _stopPageTimer() {
    _pageTimer?.cancel();
    _pageTimer = null;
  }

  String get _pageTimerLabel {
    final m = (_pageSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_pageSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Jump to specific surah ────────────────────────────────────────────────────
  void _showSurahPicker() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.7, maxChildSize: 0.92,
        builder: (_, ctrl) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.all(20),
            child: Text('Select Surah', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: _kText))),
          Expanded(child: ListView.builder(
            controller: ctrl, itemCount: 114,
            itemBuilder: (_, i) {
              final n = i + 1;
              final isCurrent = n == _surah;
              return ListTile(
                onTap: () {
                  Navigator.pop(context);
                  setState(() { _surah = n; _ayah = 1; });
                  _fetchAyah(n, 1);
                  // Sync _currentPage so Mushaf opens at the correct page
                  _currentPage = _kSurahStartPage[n.clamp(1, 114)];
                  _syncReadingPosition();
                  _savePagePosition();
                },
                leading: Container(width: 36, height: 36,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: isCurrent ? _kTeal : const Color(0xFFF0FBF9)),
                  child: Center(child: Text('$n', style: GoogleFonts.outfit(fontSize: 13,
                      fontWeight: FontWeight.w700, color: isCurrent ? Colors.white : _kTeal)))),
                title: Text(_surahNames[i],
                    style: GoogleFonts.outfit(fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent ? _kTeal : _kText)),
                subtitle: Text('${_surahLengths[n]} ayahs',
                    style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
                trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: _kTeal) : null,
              );
            },
          )),
        ]),
      ),
    );
  }

  // ── Toggle bookmark ───────────────────────────────────────────────────────────
  Future<void> _toggleBookmark() async {
    final key = '$_surah:_ayah';
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;

    if (_bookmarks.contains(key)) {
      setState(() => _bookmarks.remove(key));
      try {
        await _sb.from('quran_bookmarks')
            .delete().eq('user_id', uid).eq('surah', _surah).eq('ayah', _ayah);
      } catch (_) { setState(() => _bookmarks.add(key)); }
    } else {
      setState(() => _bookmarks.add(key));
      try {
        await _sb.from('quran_bookmarks').insert({
          'user_id': uid, 'surah': _surah, 'ayah': _ayah, 'surah_name': _surahName,
        });
        if (mounted) _showSnack('Bookmarked $_surahName $_surah:$_ayah');
      } catch (_) { setState(() => _bookmarks.remove(key)); }
    }
  }

  // ── Inline Tafsir ────────────────────────────────────────────────────────────
  Future<void> _fetchTafsirText({required int editionIdx, void Function()? onDone}) async {
    final def = _qTafsirEditions[editionIdx];
    final cacheKey = 'qtafsir_${_surah}_${_ayah}_${def.id}';
    final cached = _cache.get(cacheKey) as String?;
    if (cached != null) {
      if (mounted) setState(() { _tafsirText = cached; _tafsirLoading = false; });
      if (onDone != null) onDone();
      return;
    }
    try {
      final cdnUrl = 'https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main'
          '/tafsir/${def.slug}/$_surah.json';
      final res = await http.get(Uri.parse(cdnUrl)).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final js = jsonDecode(res.body);
        final ayahs = js['ayahs'] as List?;
        
        // Cache the ENTIRE SURAH tafsirs to make adjacent ayahs instant
        if (ayahs != null) {
          for (var a in ayahs) {
            String cKey = 'qtafsir_${_surah}_${a["ayah"]}_${def.id}';
            await _cache.put(cKey, a["text"] ?? '');
          }
        }
        
        final match = ayahs?.firstWhere((a) => a['ayah'] == _ayah, orElse: () => null);
        final text = (match?['text'] as String?) ?? '';
        
        if (mounted) setState(() { _tafsirText = text; _tafsirLoading = false; });
      } else {
        if (mounted) setState(() { _tafsirText = ''; _tafsirLoading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _tafsirText = ''; _tafsirLoading = false; });
    }
    if (onDone != null) onDone();
  }

  void _openTafsirSheet() {
    // Reset and start loading for current ayah
    setState(() { _tafsirLoading = true; _tafsirText = ''; });
    
    void Function(void Function())? sheetSetState;
    _fetchTafsirText(editionIdx: _tafsirEditionIdx, onDone: () {
      if (sheetSetState != null) sheetSetState!((){});
    });

    final isDark  = _darkMode;
    final sheetBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final lblC    = isDark ? Colors.white : _kText;
    final subC    = isDark ? const Color(0xFF6E6E73) : _kSub;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          sheetSetState = setSt;
          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            builder: (_, sc) {
              final bottomPad = MediaQuery.of(ctx).padding.bottom;
            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                ),
                // Header row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(children: [
                    Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: _accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.menu_book_rounded, color: _accent, size: 20)),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Tafsir · $_surahName $_surah:$_ayah',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: lblC))),
                    IconButton(icon: Icon(Icons.close_rounded, color: subC, size: 22),
                        onPressed: () => Navigator.pop(ctx)),
                  ]),
                ),
                // Source dropdown
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _accent.withValues(alpha: 0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _tafsirEditionIdx,
                        isExpanded: true,
                        dropdownColor: sheetBg,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: _accent),
                        items: List.generate(_qTafsirEditions.length, (i) {
                          final e = _qTafsirEditions[i];
                          return DropdownMenuItem<int>(
                            value: i,
                            child: Row(children: [
                              Text(e.emoji, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded( // Added Expanded for overflow protection
                                child: Text(e.name,
                                    maxLines: 1, // Added maxLines
                                    overflow: TextOverflow.ellipsis, // Added overflow
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: lblC)),
                              ),
                            ]),
                          );
                        }),
                        onChanged: (i) {
                          if (i == null) return;
                          setSt(() { _tafsirEditionIdx = i; _tafsirLoading = true; _tafsirText = ''; });
                          setState(() { _tafsirEditionIdx = i; _tafsirLoading = true; _tafsirText = ''; });
                          _fetchTafsirText(editionIdx: i, onDone: () {
                            setSt((){});
                          });
                        },
                      ),
                    ),
                  ),
                ),
                Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
                // Tafsir body
                Expanded(child: ValueListenableBuilder<Box>(
                  valueListenable: _cache.listenable(),
                  builder: (_, __, ___) => ListView(
                    controller: sc,
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomPad),
                    children: [
                      if (_tafsirLoading)
                        Center(child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
                        ))
                      else if (_tafsirText.isEmpty)
                        Center(child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(children: [
                            const Text('📖', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 12),
                            Text('Tafsir not available for this ayah.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(fontSize: 14, color: subC)),
                          ]),
                        ))
                      else ...[
                        () {
                          final def = _qTafsirEditions[_tafsirEditionIdx];
                          return Directionality(
                            textDirection: def.rtl ? TextDirection.rtl : TextDirection.ltr,
                            child: Text(
                              _tafsirText,
                              textAlign: def.rtl ? TextAlign.right : TextAlign.left,
                              style: def.rtl
                                  ? GoogleFonts.amiri(fontSize: 18, color: lblC, height: 2.0)
                                  : GoogleFonts.outfit(fontSize: 15, color: lblC, height: 1.75),
                            ),
                          );
                        }(),
                      ],
                    ],
                  ),
                )),
              ]),
            );
          },
        );
        },
      ),
    );
  }

  // ── Audio playback ────────────────────────────────────────────────────────────

  Future<void> _togglePlay() async {
    if (_audioUrl == null || _audioUrl!.isEmpty) {
      _showSnack('Audio URL not loaded yet. Please wait...');
      return;
    }
    if (_isPlaying) {
      await _player.pause();
      return;
    }
    setState(() => _audioLoading = true);
    try {
      await _player.stop();
      await _player.setUrl(_audioUrl!);
      setState(() => _audioLoading = false);
      await _player.play();
    } on PlayerException catch (e) {
      if (mounted) {
        setState(() => _audioLoading = false);
        _showSnack('Playback error: ${e.message ?? "Unknown error"}');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _audioLoading = false);
        _showSnack('Audio unavailable — check internet connection.');
      }
    }
  }

  Future<void> _loadAudioForReciter() async {
    await _player.stop();
    setState(() { _pos = Duration.zero; _dur = Duration.zero; _isPlaying = false; });
    await _fetchAyah(_surah, _ayah);
  }


  String _todayStr() => DateTime.now().toIso8601String().split('T')[0];

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      backgroundColor: _kTeal, duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }




  bool get _isBookmarked  => _bookmarks.contains('$_surah:_ayah');
  bool get _isFavourited  => _favourites.contains('$_surah:_ayah');

  // ── Toggle favourite ──────────────────────────────────────────────────────────
  Future<void> _toggleFavourite() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) { _showSnack('Sign in to save favourites'); return; }
    final key = '$_surah:_ayah';
    final adding = !_isFavourited;
    setState(() {
      if (adding) {
        _favourites.add(key);
      } else {
        _favourites.remove(key);
      }
    });
    try {
      if (adding) {
        // Upsert bookmark with is_favourite = true
        await _sb.from('quran_bookmarks').upsert({
          'user_id': uid, 'surah': _surah, 'ayah': _ayah, 'is_favourite': true,
        }, onConflict: 'user_id,surah,ayah');
        // Also ensure it's in the bookmarks set
        setState(() => _bookmarks.add(key));
      } else {
        await _sb.from('quran_bookmarks').update({'is_favourite': false})
            .eq('user_id', uid).eq('surah', _surah).eq('ayah', _ayah);
      }
    } catch (_) {
      setState(() {
        if (adding) {
          _favourites.remove(key);
        } else {
          _favourites.add(key);
        }
      });
    }
    _showSnack(adding ? '♥️ Added to Favourites' : 'Removed from Favourites');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) {
          Widget sHead(String label, IconData icon) => Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
            child: Row(children: [
              Container(width: 32, height: 32,
                decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 17, color: _accent),
              ),
              const SizedBox(width: 10),
              Text(label, style: GoogleFonts.outfit(
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: const Color(0xFF8E8E93),
                  letterSpacing: 0.8)),
            ]),
          );
          Widget sTile(String t, String s, IconData ic, bool val,
              ValueChanged<bool> cb) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                    color: _darkMode
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF7F3EE),
                    borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  value: val,
                  onChanged: (v) { cb(v); setSt(() {}); setState(() {}); },
                  title: Text(t, style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: _darkMode
                          ? Colors.white
                          : const Color(0xFF1C1C1E))),
                  subtitle: Text(s, style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF8E8E93))),
                  secondary: Container(width: 38, height: 38,
                    decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(ic, size: 20, color: _accent),
                  ),
                  activeThumbColor: _accent,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            );
          }
          final bgC = _darkMode
              ? const Color(0xFF1C1C1E)
              : Colors.white;
          final lblC = _darkMode
              ? Colors.white
              : const Color(0xFF1C1C1E);
          return DraggableScrollableSheet(
            initialChildSize: 0.88,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, ctrl) => Container(
              decoration: BoxDecoration(
                  color: bgC,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28))),
              child: Column(children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Container(width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(12)),
                      child: Icon(Icons.tune_rounded,
                          color: _accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text('Reading Settings',
                        style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: lblC)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Done',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: _accent)),
                    ),
                  ]),
                ),
                const SizedBox(height: 4),
                Expanded(child: ListView(
                  controller: ctrl,
                  padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [
                    // ═ APPEARANCE
                    sHead('APPEARANCE', Icons.palette_rounded),
                    sTile('Dark Mode',
                        'Comfortable night-time reading',
                        Icons.dark_mode_rounded,
                        _darkMode, (v) => _darkMode = v),
                    sTile('Focus Mode (Full Screen)',
                        'Hide app bar & nav for distraction-free reading',
                        Icons.fullscreen_rounded,
                        _fullScreenMode,
                        (v) => _fullScreenMode = v),
                    // Arabic font slider
                    Padding(padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                            color: _darkMode
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFF7F3EE),
                            borderRadius:
                                BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                          Row(children: [
                            Container(width: 38, height: 38,
                              decoration: BoxDecoration(
                                  color: _accent.withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(10)),
                              child: Icon(
                                  Icons.text_fields_rounded,
                                  size: 20, color: _accent),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                              Text('Text Size',
                                  style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: lblC)),
                              Text('${_arabicFontSize.toInt()} pt',
                                  style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: const Color(
                                          0xFF8E8E93))),
                            ]),
                          ]),
                          Slider(
                            value: _arabicFontSize,
                            min: 20, max: 44, divisions: 12,
                            activeColor: _accent,
                            inactiveColor:
                                _accent.withValues(alpha: 0.2),
                            onChanged: (v) {
                              setSt(() {
                                _arabicFontSize = v;
                                _translationFontSize = 12.0 + (v - 20.0) * (10.0 / 24.0);
                              });
                              setState(() {});
                            },
                          ),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                            Text('Small',
                                style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: const Color(
                                        0xFF8E8E93))),
                            Text('Large',
                                style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: const Color(
                                        0xFF8E8E93))),
                          ]),
                        ]),
                      ),
                    ),

                    // Theme colour picker
                    Padding(padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                            color: _darkMode
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFF7F3EE),
                            borderRadius:
                                BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                          Row(children: [
                            Container(width: 38, height: 38,
                              decoration: BoxDecoration(
                                  color: _accent.withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(10)),
                              child: Icon(
                                  Icons.color_lens_rounded,
                                  size: 20, color: _accent),
                            ),
                            const SizedBox(width: 12),
                            Text('Theme Colour',
                                style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: lblC)),
                          ]),
                          const SizedBox(height: 14),
                          Wrap(spacing: 10, runSpacing: 10,
                            children: List.generate(
                                _kThemeAccents.length, (i) {
                              final sel = i == _themeIdx;
                              return GestureDetector(
                                onTap: () {
                                  setSt(() => _themeIdx = i);
                                  setState(() {});
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 150),
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color:
                                        _kThemeAccents[i].$1,
                                    shape: BoxShape.circle,
                                    border: sel
                                        ? Border.all(
                                            color: Colors.white,
                                            width: 3)
                                        : null,
                                    boxShadow: sel
                                        ? [
                                          BoxShadow(
                                            color: _kThemeAccents[
                                                        i]
                                                    .$1
                                                    .withValues(
                                                        alpha: 0.5),
                                            blurRadius: 12,
                                          )
                                        ]
                                        : null,
                                  ),
                                  child: sel
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 20)
                                      : null,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_kThemeAccents[_themeIdx].$3}  ${_kThemeAccents[_themeIdx].$2}',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF8E8E93)),
                          ),
                        ]),
                      ),
                    ),

                    // ═ QURAN SCRIPT
                    sHead('QURAN SCRIPT', Icons.draw_rounded),
                    Padding(padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                            color: _darkMode
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFF7F3EE),
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(width: 38, height: 38,
                                decoration: BoxDecoration(
                                    color: _accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.draw_rounded,
                                    size: 20, color: _accent),
                              ),
                              const SizedBox(width: 12),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Quran Script',
                                    style: GoogleFonts.outfit(
                                        fontSize: 14, fontWeight: FontWeight.w700, color: lblC)),
                                Text(_kQuranScripts[_quranScriptIdx].name,
                                    style: GoogleFonts.outfit(
                                        fontSize: 11, color: const Color(0xFF8E8E93))),
                              ]),
                            ]),
                            const SizedBox(height: 16),
                            ...List.generate(_kQuranScripts.length, (i) {
                              final scriptObj = _kQuranScripts[i];
                              final sel  = i == _quranScriptIdx;
                              return GestureDetector(
                                onTap: () {
                                  setSt(() => _quranScriptIdx = i);
                                  setState(() => _quranScriptIdx = i);
                                  _fetchAyah(_surah, _ayah); // Refetch to get new script
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? _accent.withValues(alpha: 0.12)
                                        : (_darkMode
                                            ? const Color(0xFF1C1C1E)
                                            : Colors.white),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: sel ? _accent : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(scriptObj.name,
                                              style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: sel ? _accent : const Color(0xFF8E8E93))),
                                          const SizedBox(height: 4),
                                          Text(scriptObj.arabicPreview,
                                              textDirection: TextDirection.rtl,
                                              style: scriptObj.style(22, lblC, 1.6, FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                    if (sel)
                                      Container(
                                        width: 24, height: 24,
                                        decoration: BoxDecoration(
                                          color: _accent, shape: BoxShape.circle),
                                        child: const Icon(Icons.check_rounded,
                                            color: Colors.white, size: 15),
                                      ),
                                  ]),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    // ═ READING LAYOUT
                    sHead('READING LAYOUT',
                        Icons.view_agenda_rounded),
                    sTile('Show Translation',
                        'Display meaning below each verse',
                        Icons.translate_rounded,
                        _showTranslation,
                        (v) => _showTranslation = v),
                    sTile('Show Daily Progress',
                        'Progress bar & ayah count card',
                        Icons.bar_chart_rounded,
                        _showProgressCard,
                        (v) => _showProgressCard = v),
                    sTile('Show Points Banner',
                        '+Noor Points notification strip',
                        Icons.nights_stay_rounded,
                        _showPointsBanner,
                        (v) => _showPointsBanner = v),
                    sTile('Show Surah Header',
                        'Surah name banner at top of page',
                        Icons.menu_book_rounded,
                        _showSurahBanner,
                        (v) => _showSurahBanner = v),

                    // ═ AUDIO & PLAYBACK
                    sHead('AUDIO & PLAYBACK',
                        Icons.headphones_rounded),
                    sTile('Auto-Advance',
                        'Move to next verse when audio ends',
                        Icons.skip_next_rounded,
                        _autoAdvance,
                        (v) => _autoAdvance = v),
                    sTile('Repeat Current Verse',
                        'Loop this ayah audio on repeat',
                        Icons.repeat_one_rounded,
                        _repeatAyah, (v) {
                          _repeatAyah = v;
                          _player.setLoopMode(
                              v ? LoopMode.one : LoopMode.off);
                        }),

                    // ═ NOTIFICATIONS
                    sHead('NOTIFICATIONS & ALERTS',
                        Icons.notifications_rounded),
                    sTile('Daily Reading Reminder',
                        'Push reminder to read Quran each day',
                        Icons.alarm_rounded,
                        _dailyReminder,
                        (v) => _dailyReminder = v),
                    sTile('Milestone Sound Alerts',
                        'Chime when you reach 10, 25, 50 ayahs',
                        Icons.music_note_rounded,
                        _soundAlerts,
                        (v) => _soundAlerts = v),

                    // ═ ADVANCED
                    sHead('ADVANCED', Icons.settings_rounded),
                    sTile('Word-by-Word Mode',
                        'Show each Arabic word with its English meaning',
                        Icons.translate_rounded,
                        _wordByWord, (v) {
                          _wordByWord = v;
                          if (v && _wbwWords.isEmpty) {
                            _fetchWordByWord(_surah, _ayah);
                          } else if (!v) {
                            setState(() => _wbwWords = []);
                          }
                        }),

                    // Translation language picker
                    Padding(padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                            color: _darkMode
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFF7F3EE),
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(width: 38, height: 38,
                                decoration: BoxDecoration(
                                    color: _accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.language_rounded,
                                    size: 20, color: _accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Translation Language',
                                      style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: lblC)),
                                  Text('${_translations.length} translations available',
                                      style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: const Color(0xFF8E8E93))),
                                ],
                              )),
                            ]),
                            const SizedBox(height: 14),
                            ...List.generate(_translations.length, (i) {
                              final t = _translations[i];
                              final sel = t.id == _translationEdition;
                              // Language flag emoji
                              final String flag;
                              if (t.id.startsWith('en.')) { flag = '🇬🇧'; }
                              else if (t.id.startsWith('ur.')) { flag = '🇵🇰'; }
                              else if (t.id.startsWith('fr.')) { flag = '🇫🇷'; }
                              else if (t.id.startsWith('tr.')) { flag = '🇹🇷'; }
                              else if (t.id.startsWith('id.')) { flag = '🇮🇩'; }
                              else if (t.id.startsWith('bn.')) { flag = '🇧🇩'; }
                              else if (t.id.startsWith('de.')) { flag = '🇩🇪'; }
                              else if (t.id.startsWith('es.')) { flag = '🇪🇸'; }
                              else { flag = '🌐'; }
                              return GestureDetector(
                                onTap: () async {
                                  final newEdition = t.id;
                                  setSt(() => _translationEdition = newEdition);
                                  setState(() => _translationEdition = newEdition);
                                  for (int a = 1; a <= _surahLengths[_surah]; a++) {
                                    final ck = '$_surah:$a:$newEdition:${_reciters[_reciterIdx].$1}';
                                    await _cache.delete(ck);
                                  }
                                  await _fetchAyah(_surah, _ayah);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? _accent.withValues(alpha: 0.12)
                                        : (_darkMode
                                            ? const Color(0xFF1C1C1E)
                                            : Colors.white),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: sel
                                          ? _accent
                                          : (_darkMode
                                              ? Colors.white12
                                              : Colors.grey.shade200),
                                      width: sel ? 1.5 : 1,
                                    ),
                                    boxShadow: sel ? [
                                      BoxShadow(
                                        color: _accent.withValues(alpha: 0.12),
                                        blurRadius: 8, spreadRadius: 0,
                                      )
                                    ] : [],
                                  ),
                                  child: Row(children: [
                                    // Flag bubble
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? _accent.withValues(alpha: 0.15)
                                            : (_darkMode
                                                ? Colors.white.withValues(alpha: 0.06)
                                                : Colors.grey.shade100),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(flag, style: const TextStyle(fontSize: 18)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textDirection: t.rtl
                                                ? TextDirection.rtl
                                                : TextDirection.ltr,
                                            style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: sel
                                                    ? _accent
                                                    : (_darkMode
                                                        ? Colors.white
                                                        : const Color(0xFF1C1C1E)))),
                                        Text(t.author,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                                fontSize: 10,
                                                color: const Color(0xFF8E8E93))),
                                      ],
                                    )),
                                    if (sel)
                                      Container(
                                        width: 22, height: 22,
                                        decoration: BoxDecoration(
                                            color: _accent, shape: BoxShape.circle),
                                        child: const Icon(Icons.check_rounded,
                                            color: Colors.white, size: 13),
                                      ),
                                  ]),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                )),
              ]),
            ),
          );
        },
      ),
    );
  }



  String _fmtDur(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildAudioPlayer() {
    final bool hasAudio = _audioUrl != null && !_loading;
    final sliderVal = _dur.inMilliseconds > 0
        ? _pos.inMilliseconds.toDouble().clamp(0.0, _dur.inMilliseconds.toDouble())
        : 0.0;
    final sliderMax = _dur.inMilliseconds > 0 ? _dur.inMilliseconds.toDouble() : 1.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: _darkMode ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Row 1: Reciter chips ─────────────────────
        Row(children: [
          const Text('🎧', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text('Reciter:', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: _darkMode ? Colors.grey.shade400 : const Color(0xFF8E8E93))),
          const SizedBox(width: 6),
          Expanded(child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: List.generate(_reciters.length, (i) {
              final sel = i == _reciterIdx;
              return GestureDetector(
                onTap: () async {
                  if (_reciterIdx == i) return;
                  setState(() => _reciterIdx = i);
                  await _loadAudioForReciter();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: i < _reciters.length - 1 ? 6 : 0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel ? _accent : (_darkMode ? Colors.white10 : const Color(0xFFF7F3EE)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? _accent : (_darkMode ? Colors.white24 : Colors.grey.shade200)),
                  ),
                  child: Text(_reciters[i].$2,
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : (_darkMode ? Colors.grey.shade300 : const Color(0xFF8E8E93)))),
                ),
              );
            })),
          )),
        ]),
        // ── Row 2: Seek slider ────────────────────────────────────────
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: hasAudio ? _accent : Colors.grey.shade300,
            inactiveTrackColor: hasAudio ? _accent.withValues(alpha: 0.3) : Colors.grey.shade200,
            thumbColor: hasAudio ? _accent : Colors.grey.shade400,
            overlayColor: _accent.withValues(alpha: 0.2),
            disabledActiveTrackColor: Colors.grey.shade300,
          ),
          child: Slider(
            value: sliderVal, min: 0, max: sliderMax,
            onChanged: hasAudio ? (v) => _player.seek(Duration(milliseconds: v.toInt())) : null,
          ),
        ),
        // ── Row 3: Controls ──────────────────────────────────────
        Row(children: [
          IconButton(
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            icon: Icon(Icons.skip_previous_rounded, size: 26, color: hasAudio ? _accent : Colors.grey.shade300),
            onPressed: hasAudio ? () => _prevAyah() : null,
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: hasAudio ? _togglePlay : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: !hasAudio
                    ? (_darkMode ? Colors.white12 : Colors.grey.shade200)
                    : _isPlaying ? const Color(0xFF1FA882) : _accent,
                boxShadow: hasAudio ? [BoxShadow(color: _accent.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))] : null,
              ),
              child: _audioLoading
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
                  : Icon(
                      !hasAudio ? Icons.hourglass_top_rounded
                          : _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: hasAudio ? Colors.white : Colors.grey.shade400, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            icon: Icon(Icons.skip_next_rounded, size: 26, color: hasAudio ? _accent : Colors.grey.shade300),
            onPressed: hasAudio ? () => _nextAyah() : null,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _darkMode ? Colors.black26 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _darkMode ? Colors.white12 : Colors.grey.shade200),
            ),
            child: Text(
              hasAudio ? '${_fmtDur(_pos)} / ${_fmtDur(_dur)}' : 'Loading...',
              style: GoogleFonts.outfit(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: _darkMode ? Colors.grey.shade300 : const Color(0xFF8E8E93),
                  fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── build() ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Full mushaf mode takes over the entire screen
    if (_fullPageMode) return _buildMushafPage();

    final bg     = _darkMode ? const Color(0xFF000000) : _kBg;
    final cardBg = _darkMode ? const Color(0xFF1C1C1E) : _kWhite;
    final barBg  = _darkMode ? const Color(0xFF1C1C1E) : _kWhite;
    final txt    = _darkMode ? Colors.white            : _kText;
    final sub    = _darkMode ? const Color(0xFF8E8E93) : _kSub;

    return Scaffold(
      backgroundColor: _darkMode ? const Color(0xFF000000) : Colors.transparent,
      appBar: _fullScreenMode ? null : AppBar(
        backgroundColor: barBg,
        surfaceTintColor: barBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: txt, size: 20),
          onPressed: () => Navigator.pop(context, _pointsToday),
        ),
        title: Text('Read Quran',
            style: GoogleFonts.outfit(
                fontSize: 20, fontWeight: FontWeight.w800, color: txt)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isFavourited
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(_isFavourited),
                color: _isFavourited ? Colors.red : sub, size: 24),
            ),
            onPressed: _toggleFavourite, tooltip: 'Favourite',
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                key: ValueKey(_isBookmarked),
                color: _isBookmarked ? _kGold : sub, size: 24),
            ),
            onPressed: _toggleBookmark, tooltip: 'Bookmark',
          ),
          // Tune button — glows when hint is showing
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: _showHint
                  ? [BoxShadow(color: _accent.withValues(alpha: 0.55), blurRadius: 14, spreadRadius: 2)]
                  : [],
            ),
            child: IconButton(
              icon: Icon(Icons.tune_rounded,
                  color: _showHint ? _accent : sub, size: 24),
              onPressed: _openSettings, tooltip: 'Reading Settings',
            ),
          ),
        ],
      ),
      body: _darkMode
          ? _buildBody(bg, cardBg, barBg, txt, sub)
          : DecoratedBox(
              decoration: const BoxDecoration(gradient: _kBgGradient),
              child: _buildBody(bg, cardBg, barBg, txt, sub),
            ),
    );
  }

  Widget _buildBody(Color bg, Color cardBg, Color barBg, Color txt, Color sub) {
    return Stack(children: [
      Column(children: [

        Expanded(child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -300) {
              _nextAyah();
            } else if (details.primaryVelocity! > 300) {
              _prevAyah();
            }
          },
            child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 16, 20,
                _fullScreenMode ? 80 : 0),
            child: Column(children: [
              // Points banner
              if (_showPointsBanner && _pointsToday > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Text('🌟', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text('+_pointsToday Noor Points earned today!',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _accent)),
                  ]),
                ),
                const SizedBox(height: 16),
              ],
              // Surah banner
              if (_showSurahBanner) ...[
                GestureDetector(
                  onTap: _showSurahPicker,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [
                            _accent.withValues(alpha: 0.85),
                            _accent
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: _accent.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: Row(children: [
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('$_surahName • Surah _surah',
                            style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                            'Ayah _ayah of '
                            '${_surahLengths[_surah]}  •  Tap to change',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.white
                                    .withValues(alpha: 0.8))),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(mainAxisSize: MainAxisSize.min,
                            children: [
                          const Icon(Icons.menu_book_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 5),
                          Text('Browse',
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(width: 4),
                          const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white, size: 18),
                        ]),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              // Ayah card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16)
                  ],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // ── Action pills row ─────────────────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                    if (!_fullPageMode) ...[
                      // 📖 Read Tafsir
                      _PillButton(
                        icon: Icons.menu_book_rounded,
                        label: 'Tafsir',
                        active: false,
                        activeColor: _accent,
                        darkMode: _darkMode,
                        onTap: _openTafsirSheet,
                      ),
                      // 🎧 Listen
                      _PillButton(
                        icon: _showAudioPlayer && _isPlaying
                            ? Icons.pause_circle_rounded
                            : Icons.headphones_rounded,
                        label: _showAudioPlayer ? 'Playing' : 'Listen',
                        active: _showAudioPlayer,
                        activeColor: const Color(0xFFE67E22),
                        darkMode: _darkMode,
                        onTap: () {
                          setState(() => _showAudioPlayer = !_showAudioPlayer);
                          if (_showAudioPlayer && !_isPlaying) _togglePlay();
                        },
                      ),
                    ],
                    // 📖 Full Page Mushaf — always visible
                    _PillButton(
                      icon: Icons.menu_book_outlined,
                      label: 'Mushaf',
                      active: false,
                      activeColor: const Color(0xFF4CAF50),
                      darkMode: _darkMode,
                      onTap: () async {
                        final page = await _resolvePageForCurrentAyah();
                        await _player.stop();
                        setState(() {
                          _showAudioPlayer = false;
                          _wordByWord      = false;
                          _wbwWords        = [];
                          _fullPageMode    = true;
                          _currentPage     = page;
                          _showMushafControls = true;
                        });
                        _cache.put('pref_mushaf_mode', true);
                        _cache.put('pref_wbw_mode', false);
                        _syncReadingPosition();
                        _enterFullPageScrollMode(page);
                        _startPageTimer();
                        // Auto-hide overlay after 4 s
                        _controlsHideTimer?.cancel();
                        _controlsHideTimer = Timer(const Duration(seconds: 4), () {
                          if (mounted) setState(() => _showMushafControls = false);
                        });
                      },
                    ),
                    if (!_fullPageMode)
                      // 🔤 Word by Word
                      _PillButton(
                        icon: Icons.translate_rounded,
                        label: 'Word by Word',
                        active: _wordByWord,
                        activeColor: _accent,
                        darkMode: _darkMode,
                        onTap: () {
                          setState(() {
                            _wordByWord = !_wordByWord;
                            if (_wordByWord) {
                              _fullPageMode = false;
                              _stopPageTimer();
                            }
                          });
                          _cache.put('pref_wbw_mode', _wordByWord);
                          _cache.put('pref_mushaf_mode', false);
                          if (_wordByWord && _wbwWords.isEmpty) {
                            _fetchWordByWord(_surah, _ayah);
                          }
                        },
                      ),
                  ]),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: _darkMode ? Colors.white12 : Colors.grey.shade100),
                  const SizedBox(height: 20),
                  if (_loading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                          color: _kTeal, strokeWidth: 2),
                    ))
                  else if (_wordByWord) ...[ 
                    // ── Word-by-Word Mode ────────────────────────────────────
                    if (_wbwLoading)
                      Center(child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(children: [
                          CircularProgressIndicator(color: _accent, strokeWidth: 2),
                          const SizedBox(height: 12),
                          Text('Loading word translations...',
                              style: GoogleFonts.outfit(fontSize: 12, color: sub)),
                        ]),
                      ))
                    else if (_wbwWords.isEmpty)
                      Center(child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(children: [
                          Icon(Icons.wifi_off_rounded, color: sub, size: 36),
                          const SizedBox(height: 8),
                          Text('Word data unavailable. Check your connection.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontSize: 13, color: sub)),
                        ]),
                      ))
                    else
                      _buildWordByWordGrid(txt, sub),
                  ] else ...[ 
                    // ── Full Verse Mode ──────────────────────────────────────
                    if (_ayah == 1 && _surah > 1 && _surah != 9) ...[
                      _buildMushafBismillah(txt, _accent, _quranScriptIdx == 1),
                      const SizedBox(height: 16),
                    ],
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: _ayah == 1 && _surah > 1 && _surah != 9
                                  ? '${_QuranScreenState._stripBismillahPrefix(_arabic)} '
                                  : '$_arabic ',
                              style: _kQuranScripts[_quranScriptIdx].style(
                                  _arabicFontSize, txt, 2.2, FontWeight.w700),
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _accent, width: 1.5),
                                  color: _accent.withValues(alpha: 0.08),
                                ),
                                child: Center(
                                  child: Text(
                                    '$_ayah',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: _accent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    if (_showTranslation) ...[
                      const SizedBox(height: 20),
                      // ── Clean Translation Block ──────────
                      (() {
                        final def = _translations.firstWhere(
                          (t) => t.id == _translationEdition,
                          orElse: () => _translations.first,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
                          child: Text(
                            _translation,
                            textAlign: def.rtl ? TextAlign.right : TextAlign.left,
                            textDirection: def.rtl
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            style: def.rtl
                                ? GoogleFonts.amiri(
                                    fontSize: _translationFontSize + 3,
                                    color: _darkMode
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : const Color(0xFF2C2C2E),
                                    height: 2.0,
                                    fontWeight: FontWeight.w500,
                                  )
                                : GoogleFonts.outfit(
                                    fontSize: _translationFontSize,
                                    color: _darkMode
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : const Color(0xFF2C2C2E),
                                    height: 1.85,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.1,
                                  ),
                          ),
                        );
                      })(),
                    ],
                  ],
                ]),
              ),
              // Progress card
              if (_showProgressCard) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10)
                    ],
                  ),
                  child: Column(children: [
                    Row(children: [
                      Text("Today's Progress",
                          style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: txt)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text('+_pointsToday pts',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _accent)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text('$_ayahsToday ayahs read',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: sub)),
                      const Spacer(),
                      Text(
                          '${((_ayahsToday / 50) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _accent)),
                    ]),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (_ayahsToday / 50).clamp(0, 1),
                        minHeight: 8,
                        backgroundColor:
                            _accent.withValues(alpha: 0.15),
                        valueColor:
                            AlwaysStoppedAnimation(_accent),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Goal: 50 ayahs/day',
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: sub)),
                  ]),
                ),
              ],
              const SizedBox(height: 16),
            ]),
          ))),
          // Audio player
          if (!_fullScreenMode)
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: _showAudioPlayer
                  ? _buildAudioPlayer()
                  : const SizedBox.shrink(),
            ),
          // Nav row
          if (!_fullScreenMode)
            _buildInlineNavRow(barBg: barBg, txt: txt),
        ]),
        // Floating controls in full-screen mode
        if (_fullScreenMode)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(children: [
                _fsFab(
                  icon: Icons.fullscreen_exit_rounded,
                  onTap: () =>
                      setState(() => _fullScreenMode = false),
                ),
                const Spacer(),
                // ── Back: previous page OR previous ayah ──────────────────
                _fsFab(
                  icon: Icons.arrow_back_ios_rounded,
                  onTap: _fullPageMode
                      ? (_currentPage > 1
                          ? () {
                              setState(() { _currentPage--; _pageSeconds = 0; });
                              _fetchFullPage(_currentPage);
                            }
                          : () {})
                      : _prevAyah,
                ),
                const SizedBox(width: 10),
                // ── Next: page (no points) OR ayah (+10 pts) ──────────────
                GestureDetector(
                  onTap: _fullPageMode
                      ? (_currentPage < 604
                          ? () {
                              setState(() { _currentPage++; _pageSeconds = 0; });
                              _fetchFullPage(_currentPage);
                            }
                          : null)
                      : _nextAyah,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 13),
                    decoration: BoxDecoration(
                        // Dimmed when full-page and on last page
                        color: (_fullPageMode && _currentPage >= 604)
                            ? _accent.withValues(alpha: 0.4)
                            : _accent,
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        // Full-page mode → no points label
                        _fullPageMode ? 'Next Page' : '+10 pts',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ]),
                  ),
                ),
                const Spacer(),
                _fsFab(
                  icon: Icons.tune_rounded,
                  onTap: _openSettings,
                ),
              ]),
            )),
          ),
      ]);
  }


  Widget _fsFab({required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────────
  // MUSHAF IMMERSIVE MODE
  // ─────────────────────────────────────────────────────────────────────────────

  void _toggleMushafControls() {
    _controlsHideTimer?.cancel();
    if (!mounted) return;
    setState(() => _showMushafControls = !_showMushafControls);
    if (_showMushafControls) {
      _controlsHideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showMushafControls = false);
      });
    }
  }
  // ── Word-by-Word grid ──────────────────────────────────────────────────────
  Widget _buildWordByWordGrid(Color txt, Color sub) {
    return LayoutBuilder(builder: (ctx, constraints) {
      // 3 cards per row, uniform width, RTL order
      const cols = 3;
      const hGap = 8.0;
      final cardW = (constraints.maxWidth - hGap * (cols - 1)) / cols;

      // Build rows of 3 right-to-left
      final rows = <Widget>[];
      for (int i = 0; i < _wbwWords.length; i += cols) {
        final rowWords = _wbwWords.sublist(i, (i + cols).clamp(0, _wbwWords.length));
        // RTL: words go right→left, so reverse the row
        final rowWidgets = rowWords.reversed.map((w) {
          final isIndopak = _kQuranScripts[_quranScriptIdx].apiSlug == 'indopak';
          final arStr = isIndopak ? (w['arabic_indopak'] ?? w['arabic']) : w['arabic'];
          return SizedBox(
            width: cardW,
            child: _WbwWordChip(
              arabic: _QuranScreenState._stripQuranicAnnotations(arStr?.toString() ?? ''),
              transliteration: w['transliteration'] as String? ?? '',
              translation: w['translation'] as String? ?? '',
              arabicFontSize: _arabicFontSize * 0.95,
              quranScriptIdx: _quranScriptIdx,
              accentColor: _accent,
            txtColor: txt,
            subColor: sub,
            darkMode: _darkMode,
          ),
        );
        }).toList();

        // Pad last row if not full
        while (rowWidgets.length < cols) {
          rowWidgets.insert(0, SizedBox(width: cardW));
        }

        rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: rowWidgets
              .expand((w) => [w, if (w != rowWidgets.last) const SizedBox(width: hGap)])
              .toList(),
        ));
        rows.add(const SizedBox(height: 8));
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
    });
  }

  // ── Bottom navigation row (Prev / Play-Pause / Next) ──────────────────────
  Widget _buildInlineNavRow({required Color barBg, required Color txt}) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      color: barBg,
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPad),
      child: Row(children: [
        // Prev
        Expanded(child: ElevatedButton.icon(
          onPressed: _saving ? null : _prevAyah,
          icon: _saving
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.arrow_back_ios_rounded, size: 14, color: Colors.white),
          label: Text('Prev',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700,
                  color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _darkMode ? const Color(0xFF3A3A3C) : const Color(0xFF636366),
            disabledBackgroundColor: (_darkMode ? const Color(0xFF3A3A3C) : const Color(0xFF636366)).withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        )),
        const SizedBox(width: 10),
        // Next +10 pts
        Expanded(flex: 2, child: ElevatedButton.icon(
          onPressed: _saving ? null : _nextAyah,
          icon: _saving
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
          label: Text('Next +10 pts',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700,
                  color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            disabledBackgroundColor: _accent.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        )),
      ]),
    );
  }


  void _exitMushafMode() {
    _controlsHideTimer?.cancel();
    _timerShouldRun = false;
    _stopPageTimer();

    // ── Sync position back to normal-mode state ─────────────────────────────
    // Derive exact surah + ayah from loaded page data so verse mode resumes
    // at the precise ayah the user was reading, not just the start of surah.
    int syncedSurah = _resolveSurahForPage(_currentPage);
    int syncedAyah = 1;
    final pageAyahs = _loadedPages[_currentPage];
    if (pageAyahs != null && pageAyahs.isNotEmpty) {
      // Use the first ayah on the visible page
      syncedSurah = pageAyahs.first['surah'] as int? ?? syncedSurah;
      syncedAyah  = pageAyahs.first['ayah'] as int? ?? 1;
    }

    _fullPageScrollController?.dispose();
    _fullPageScrollController = null;

    setState(() {
      _fullPageMode = false;
      _loadedPages.clear();
      _surah     = syncedSurah;
      _ayah      = syncedAyah;
      _surahName = _surahNames[syncedSurah - 1];
    });
    _cache.put('pref_mushaf_mode', false);
    _syncReadingPosition();
    _fetchAyah(syncedSurah, syncedAyah);     // re-fetch for normal ayah card
    _savePagePosition();
  }



  Widget _buildMushafPage() {
    final isDark  = _darkMode;
    // Very soft greenish/parchment background — perfectly matching the Quran Majeed aesthetic
    final pageBg  = isDark ? const Color(0xFF0F0B06) : Colors.white;
    final textClr = isDark ? const Color(0xFFE8D5A8) : const Color(0xFF0A0A0A);
    final goldClr = isDark ? const Color(0xFFD4A843) : const Color(0xFF8B6914);
    final overlayBg = isDark
        ? Colors.black.withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.95);

    return Scaffold(
      backgroundColor: pageBg,
      body: GestureDetector(
        // Single tap: toggle the overlay controls
        behavior: HitTestBehavior.opaque,
        onTap: _toggleMushafControls,
        child: Stack(children: [
          // ── Continuous Feed (like Quran Majeed) ──
          // Beautiful native infinite scroll feed using CustomScrollView
          // This allows users to read with ANY font size without breaking page flow or needing nested scroll hacks
          CustomScrollView(
            center: _feedCenterKey,
            controller: _fullPageScrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Scroll UP: previous pages
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pageNum = _feedJumpPage - 1 - index;
                    if (pageNum < 1) return null; // We reached page 1
                    return _buildMushafPageView(pageNum, textClr, goldClr, pageBg);
                  },
                ),
              ),
              // Scroll DOWN: current and next pages
              SliverList(
                key: _feedCenterKey,
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pageNum = _feedJumpPage + index;
                    if (pageNum > 604) return null; // Max Quran pages 604
                    return _buildMushafPageView(pageNum, textClr, goldClr, pageBg);
                  },
                ),
              ),
            ],
          ),
          // ── Overlay: fades in/out on tap ──────────────────────────────────
          AnimatedOpacity(
            opacity: _showMushafControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !_showMushafControls,
              child: _buildMushafOverlay(overlayBg, goldClr, textClr),
            ),
          ),
        ]),
      ),
    );
  }

  // One slide in the PageView — content fitted to fill the visible screen exactly
  // (like Quran Majeed: no inner scrolling, the whole page is always visible).
  Widget _buildMushafPageView(int pageNum, Color textClr, Color goldClr, Color pageBg) {
    if (!_loadedPages.containsKey(pageNum) && !_loadingPages.contains(pageNum)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPageForScroll(pageNum));
    }
    final ayahs = _loadedPages[pageNum];

    // Loading state — minimal, centred
    if (ayahs == null) {
      return ColoredBox(
        color: pageBg,
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 28, height: 28,
              child: CircularProgressIndicator(color: goldClr, strokeWidth: 1.8)),
          const SizedBox(height: 14),
          Text('Loading page $pageNum…',
              style: GoogleFonts.lora(fontSize: 12,
                  color: textClr.withValues(alpha: 0.45))),
        ])),
      );
    }

    // Return purely responsive box mapping. Scroll dimensions are now infinitely controlled by the outer CustomScrollView.
    return Builder(
      builder: (ctx) {
        // Update _currentPage only when this page is actually visible on screen
        // (not just pre-rendered in the buffer), using its position relative to viewport
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final ro = ctx.findRenderObject() as RenderBox?;
          if (ro == null || !ro.hasSize) return;
          final viewport = _fullPageScrollController;
          if (viewport == null || !viewport.hasClients) return;
          final offset = ro.localToGlobal(Offset.zero).dy;
          final screenH = MediaQuery.of(context).size.height;
          // Consider this page "visible" if its top half is within the screen
          if (offset < screenH * 0.5 && offset + ro.size.height > screenH * 0.3) {
            if (_currentPage != pageNum) {
              setState(() {
                _currentPage = pageNum;
                final surahForPage = _resolveSurahForPage(pageNum);
                _surahName = _surahNames[surahForPage - 1];
              });
            }
          }
        });

        return ColoredBox(
          color: pageBg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 30.0),
            child: _buildMushafPageBlock(pageNum, ayahs, textClr, goldClr, pageBg),
          ),
        );
      }
    );
  }

  // Builds the page content block.
  // We use native text reflowing so the user's Font Size choice actually works.
  Widget _buildMushafPageBlock(int pageNum, List<Map<String, dynamic>> ayahs,
      Color textClr, Color goldClr, Color pageBg) {
    if (ayahs.isEmpty) {
      return Center(child: SizedBox(width: 24, height: 24,
          child: CircularProgressIndicator(
              color: goldClr.withValues(alpha: 0.5), strokeWidth: 1.8)));
    }

    final isIndoPak = _kQuranScripts[_quranScriptIdx].apiSlug == 'indopak';

    // ── Group consecutive ayahs by surah ─────────────────────────────────────
    final List<Widget> blocks = [];
    String? lastSurah;
    final Map<int, String> bismillahAction = {};
    final List<Map<String, dynamic>> currentGroup = [];

    void flushGroup() {
      if (currentGroup.isEmpty) return;
      blocks.add(_buildMushafTextBlock(currentGroup, textClr, goldClr, isIndoPak));
      currentGroup.clear();
    }

    for (final ayah in ayahs) {
      final surahNum = ayah['surah'] as int;
      final ayahNum  = ayah['ayah'] as int;
      final surahKey = '$surahNum';
      if (lastSurah != surahKey) {
        flushGroup();
        lastSurah = surahKey;
        if (ayahNum == 1 && surahNum >= 1) {
          if (surahNum > 1) blocks.add(const SizedBox(height: 10));
          blocks.add(_buildMushafSurahBanner(surahNum, goldClr, textClr, isIndoPak));
          if (surahNum == 1) {
            blocks.add(_buildMushafBismillah(textClr, goldClr, isIndoPak));
            bismillahAction[surahNum] = 'skip';
          } else if (surahNum != 9) {
            blocks.add(_buildMushafBismillah(textClr, goldClr, isIndoPak));
            bismillahAction[surahNum] = 'strip';
          }
          blocks.add(const SizedBox(height: 4));
        }
      }
      final action = bismillahAction[surahNum];
      final rawText = (isIndoPak ? (ayah['arabic_indopak'] ?? ayah['arabic']) : ayah['arabic']) as String? ?? '';
      
      if (ayahNum == 1 && action == 'skip') {
        continue;
      } else if (ayahNum == 1 && action == 'strip') {
        final stripped = _stripBismillahPrefix(rawText);
        currentGroup.add({...ayah, 'arabic_display': stripped});
      } else {
        currentGroup.add({...ayah, 'arabic_display': rawText});
      }
    }
    flushGroup();

    // ── Page number footer — small centred ornament like a printed Quran ────
    blocks.add(const SizedBox(height: 16));
    blocks.add(Center(
      child: Text(
        '— $pageNum —',
        style: GoogleFonts.lora(
            fontSize: 10, color: goldClr.withValues(alpha: 0.55),
            fontStyle: FontStyle.italic),
      ),
    ));
    blocks.add(const SizedBox(height: 16));

    // NO nested scrolling! Render natively so it forms part of the unified scrolling feed
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: blocks,
    );
  }

  /// Single justified RTL block for a surah-group of ayahs.
  /// Uses a fixed generous font size — the FittedBox parent will scale
  /// the entire page down to fit, so we don't need to calculate per-block.
  Widget _buildMushafTextBlock(
      List<Map<String, dynamic>> ayahs, Color textClr, Color goldClr, bool isIndoPak) {
    // Tunable base font size to fit ~15 lines beautifully into the logical width
    final double fontSize = _mushafFontSize;
    const double lh       = 1.95;   // Safe line height for Scheherazade New (avoids cropping glyphs)

    // Build one large span: each ayah separated by the end-of-ayah circle ۝
    final spans = <InlineSpan>[];
    for (int i = 0; i < ayahs.length; i++) {
      final a = ayahs[i];
      final text = _stripQuranicAnnotations(a['arabic_display'] as String? ?? '');
      final ayahNum = a['ayah'] as int? ?? (i + 1);
      // Convert to Arabic digits so the U+06DD character natively encloses them
      final numStr = ayahNum.toString().split('').map((e) => '٠١٢٣٤٥٦٧٨٩'[int.parse(e)]).join('');

      spans.add(TextSpan(text: text));
      // Use a WidgetSpan with a Stack to forcefully center the digits inside the ornament.
      spans.add(const TextSpan(text: ' '));
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text('\u06DD', style: _kQuranScripts[_quranScriptIdx].style(fontSize * 1.5, goldClr.withValues(alpha: 0.75), 1.0, FontWeight.w400)),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(numStr, style: _kQuranScripts[_quranScriptIdx].style(fontSize * 0.55, textClr, 1.0, FontWeight.w400)),
            ),
          ],
        ),
      ));
      spans.add(const TextSpan(text: ' '));
    }

    final textStyle = _kQuranScripts[_quranScriptIdx].style(fontSize, textClr, lh, FontWeight.w400);

    return Text.rich(
      TextSpan(style: textStyle, children: spans),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    );
  }

  /// Strips Quranic annotation characters that render as visible ornament
  /// glyphs in Scheherazade New (waqf signs, tajweed marks, rub el-hizb, etc).
  /// Standard harakat (diacritics ً ٌ ٍ َ ُ ِ ّ ْ) are fully preserved.
  ///
  /// Stripped ranges:
  ///   U+06D6–U+06DC  waqf / pause marks (ۖ ۗ ۘ ۙ ۚ ۛ ۜ)
  ///   U+06DD         Arabic End of Ayah ornament (۝)
  ///   U+06DE         Arabic Start of Rub El Hizb (۞)
  ///   U+06DF–U+06E4  tajweed marks (۟ ۠ ۡ ۢ ۣ ۤ)
  ///   U+06E7–U+06E8  small high Meem / Noon (ۧ ۨ)
  ///   U+06EA–U+06ED  combining stop marks (۪ ۫ ۬ ۭ)
  static String _stripQuranicAnnotations(String s) =>
      s.replaceAll(RegExp(r'[\u0615-\u061A\u06D6-\u06DE\u06DF-\u06E4\u06E7-\u06E8\u06EA-\u06ED\u08D4-\u08FE\u200B\uE000-\uF8FF]'), '');



  Widget _buildMushafSurahBanner(int surahNum, Color goldClr, Color textClr, bool isIndoPak) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: goldClr.withValues(alpha: 0.55), width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(alignment: Alignment.center, children: [
        // Corner ornaments
        for (final pos in [Alignment.topLeft, Alignment.topRight,
            Alignment.bottomLeft, Alignment.bottomRight])
          Positioned(
            top:    pos == Alignment.topLeft    || pos == Alignment.topRight    ? 4 : null,
            bottom: pos == Alignment.bottomLeft || pos == Alignment.bottomRight ? 4 : null,
            left:   pos == Alignment.topLeft    || pos == Alignment.bottomLeft  ? 6 : null,
            right:  pos == Alignment.topRight   || pos == Alignment.bottomRight ? 6 : null,
            child: Text('❋', style: TextStyle(fontSize: 9, color: goldClr.withValues(alpha: 0.5))),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'سُورَةُ ${_surahNamesArabic[surahNum - 1]}',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: _kQuranScripts[_quranScriptIdx].style(18.0, goldClr, null, FontWeight.w700).copyWith(letterSpacing: 1.5),
          ),
        ),
      ]),
    );
  }

  static String _stripBismillahPrefix(String s) {
    // Normalise: remove leading BOM / ZWNBSP that the DB may prepend
    var text = s.replaceAll('\uFEFF', '').trimLeft();
    
    // Quick fast-path for exact Uthmani (Quran Majeed) style matches
    const basmalaUthmani = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
    final exactVariations = [
      basmalaUthmani,
      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ',
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
      'بِسمِ اللَّهِ الرَّحمٰنِ الرَّحيمِ',
      'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
    ];
    for (final v in exactVariations) {
      if (text.startsWith(v)) {
        return text.substring(v.length).trimLeft();
      }
    }

    // Advanced dynamic Regex matching (catches all forms of diacritics / tatweels)
    // opt matches ANY combination of diacritics including Dagger Alifs and Tatweel extenders
    const opt = r'[\u064B-\u065F\u0670\u06DF-\u06E8\u0600-\u060F\u0610-\u061A\u0640]*';
    const sp = r'[\s]*'; 
    final basmalaRegex = RegExp(
        '^'
        'ب$optس$optم$opt$sp'
        '[اٱإ]$optل$optل$optه$opt$sp'
        '[اٱإ]$optل$optر$optح$optم$optن$opt$sp'
        '[اٱإ]$optل$optر$optح$opt[يی]$optم$opt$sp'
    );

    final match = basmalaRegex.firstMatch(text);
    if (match != null) {
      return text.substring(match.end).trimLeft();
    }
    
    return text;
  }

  Widget _buildMushafBismillah(Color textClr, Color goldClr, bool isIndoPak) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          // Subtle gold-tinted panel — like Quran Majeed's Bismillah banner
          color: goldClr.withValues(alpha: 0.07),
          border: Border.symmetric(
            horizontal: BorderSide(color: goldClr.withValues(alpha: 0.35), width: 0.8),
          ),
        ),
        // Ensures the Bismillah never overflows the screen horizontally on big font sizes
        child: FittedBox(
          fit: BoxFit.scaleDown,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Left ornament
          Text('﴾', style: _kQuranScripts[_quranScriptIdx].style(
              _arabicFontSize * 0.8,
              goldClr.withValues(alpha: 0.6), null, FontWeight.normal)),
          const SizedBox(width: 10),
          // Bismillah text — centered, gold, slightly larger than body
          Text(
            isIndoPak ? 'بِسۡمِ اللهِ الرَّحۡمٰنِ الرَّحِيۡمِ' : 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: _kQuranScripts[_quranScriptIdx].style(
                _arabicFontSize * 0.96,
                goldClr,
                1.8, FontWeight.w700),
          ),
          const SizedBox(width: 10),
          // Right ornament
          Text('﴿', style: _kQuranScripts[_quranScriptIdx].style(
              _arabicFontSize * 0.8,
              goldClr.withValues(alpha: 0.6), null, FontWeight.normal)),
        ]),
        ),
      ),
    );
  }


  Widget _buildMushafOverlay(Color overlayBg, Color goldClr, Color textClr) {
    final pad = MediaQuery.of(context).padding;
    return Column(children: [
      // ── Top bar: gradient fade — Exit · Surah · Juz · XP ─────────────────
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [overlayBg, overlayBg.withValues(alpha: 0)],
          ),
        ),
        padding: EdgeInsets.fromLTRB(14, pad.top + 4, 14, 30),
        child: Row(children: [
          // Exit button
          GestureDetector(
            onTap: _exitMushafMode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: goldClr.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: goldClr.withValues(alpha: 0.35)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.arrow_back_ios_rounded, color: goldClr, size: 13),
                const SizedBox(width: 4),
                Text('Exit', style: GoogleFonts.lora(
                    fontSize: 13, fontWeight: FontWeight.w600, color: goldClr)),
              ]),
            ),
          ),
          const Spacer(),
          // Centred surah + juz label
          Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(_surahName,
                style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w700,
                    color: textClr)),
            const SizedBox(height: 1),
            Text('Page $_currentPage  ·  Juz ${_juzForPage(_currentPage)}',
                style: GoogleFonts.lora(fontSize: 12,
                    color: goldClr)),
          ]),
          // XP badge + Settings button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_pageXpEarned > 0)
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: goldClr.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('+$_pageXpEarned XP',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 11,
                            fontWeight: FontWeight.w700, color: goldClr))),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openMushafSettings,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: goldClr.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: goldClr.withValues(alpha: 0.35)),
                  ),
                  child: Icon(Icons.tune_rounded, color: goldClr, size: 16),
                ),
              ),
            ],
          ),
        ]),
      ),
      // Simple spacer — navigation is swipe-only (no tap buttons)
      const Spacer()
,
      // ── Bottom bar: progress + page counter + timer ───────────────────────
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
            colors: [overlayBg, overlayBg.withValues(alpha: 0)],
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 30, 20, pad.bottom + 8),
        child: Column(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (_currentPage / 604).clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: goldClr.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(goldClr.withValues(alpha: 0.70)),
            ),
          ),
          const SizedBox(height: 7),
          Row(children: [
            Text('$_currentPage / 604',
                style: GoogleFonts.lora(fontSize: 12,
                    fontWeight: FontWeight.w600, color: textClr)),
            const Spacer(),
            Icon(Icons.timer_outlined, color: goldClr, size: 14),
            const SizedBox(width: 4),
            Text(_pageTimerLabel,
                style: GoogleFonts.lora(fontSize: 12,
                    fontWeight: FontWeight.w600, color: textClr)),
          ]),
        ]),
      ),
    ]);
  }

  void _openMushafSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _darkMode ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Mushaf Settings', 
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: _darkMode ? Colors.white : Colors.black)),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: Icon(Icons.bookmark_border_rounded, color: _accent),
                      title: Text('Bookmark Page', style: GoogleFonts.outfit(color: _darkMode ? Colors.white : Colors.black)),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Page bookmarked!')));
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.share_rounded, color: _accent),
                      title: Text('Share Page', style: GoogleFonts.outfit(color: _darkMode ? Colors.white : Colors.black)),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing coming soon...')));
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.format_size_rounded, color: _accent),
                      title: Text('Font Size', style: GoogleFonts.outfit(color: _darkMode ? Colors.white : Colors.black)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: _accent),
                            onPressed: () {
                              setModalState(() {
                                _mushafFontSize = (_mushafFontSize - 2).clamp(16.0, 48.0);
                              });
                              setState(() {}); 
                            },
                          ),
                          Text('${_mushafFontSize.toInt()}', style: GoogleFonts.outfit(fontSize: 16, color: _darkMode ? Colors.white : Colors.black)),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, color: _accent),
                            onPressed: () {
                              setModalState(() {
                                _mushafFontSize = (_mushafFontSize + 2).clamp(16.0, 48.0);
                              });
                              setState(() {}); 
                            },
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.palette_outlined, color: _accent),
                      title: Text('Customise', style: GoogleFonts.outfit(color: _darkMode ? Colors.white : Colors.black)),
                      subtitle: Text('Save custom page settings', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customise settings coming soon!')));
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  // Juz number (1–30) for a given Quran page (1–604).
  static int _juzForPage(int page) {
    const juzStart = [
       1, 22, 42, 62, 82,102,121,142,162,182,
     201,222,242,262,282,302,322,342,362,382,
     402,422,442,462,482,502,522,542,562,582,
    ];
    for (int i = juzStart.length - 1; i >= 0; i--) {
      if (page >= juzStart[i]) return i + 1;
    }
    return 1;
  }
} // end _QuranScreenState



// ── All 114 surah names ───────────────────────────────────────────────────────
const _surahNames = [
  'Al-Fatiha','Al-Baqarah','Ali \'Imran','An-Nisa','Al-Ma\'idah',
  'Al-An\'am','Al-A\'raf','Al-Anfal','At-Tawbah','Yunus',
  'Hud','Yusuf','Ar-Ra\'d','Ibrahim','Al-Hijr',
  'An-Nahl','Al-Isra','Al-Kahf','Maryam','Ta-Ha',
  'Al-Anbiya','Al-Hajj','Al-Mu\'minun','An-Nur','Al-Furqan',
  'Ash-Shu\'ara','An-Naml','Al-Qasas','Al-\'Ankabut','Ar-Rum',
  'Luqman','As-Sajdah','Al-Ahzab','Saba','Fatir',
  'Ya-Sin','As-Saffat','Sad','Az-Zumar','Ghafir',
  'Fussilat','Ash-Shura','Az-Zukhruf','Ad-Dukhan','Al-Jathiyah',
  'Al-Ahqaf','Muhammad','Al-Fath','Al-Hujurat','Qaf',
  'Adh-Dhariyat','At-Tur','An-Najm','Al-Qamar','Ar-Rahman',
  'Al-Waqi\'ah','Al-Hadid','Al-Mujadila','Al-Hashr','Al-Mumtahanah',
  'As-Saf','Al-Jumu\'ah','Al-Munafiqun','At-Taghabun','At-Talaq',
  'At-Tahrim','Al-Mulk','Al-Qalam','Al-Haqqah','Al-Ma\'arij',
  'Nuh','Al-Jinn','Al-Muzzammil','Al-Muddaththir','Al-Qiyamah',
  'Al-Insan','Al-Mursalat','An-Naba','An-Nazi\'at','Abasa',
  'At-Takwir','Al-Infitar','Al-Mutaffifin','Al-Inshiqaq','Al-Buruj',
  'At-Tariq','Al-A\'la','Al-Ghashiyah','Al-Fajr','Al-Balad',
  'Ash-Shams','Al-Layl','Ad-Duha','Ash-Sharh','At-Tin',
  'Al-\'Alaq','Al-Qadr','Al-Bayyinah','Az-Zalzalah','Al-\'Adiyat',
  'Al-Qari\'ah','At-Takathur','Al-\'Asr','Al-Humazah','Al-Fil',
  'Quraysh','Al-Ma\'un','Al-Kawthar','Al-Kafirun','An-Nasr',
  'Al-Masad','Al-Ikhlas','Al-Falaq','An-Nas',
];

// ── Surah names in Arabic (for mushaf banner headers) ────────────────────────
const _surahNamesArabic = [
  'الْفَاتِحَة','الْبَقَرَة','آلِ عِمْرَان','النِّسَاء','الْمَائِدَة',
  'الْأَنْعَام','الْأَعْرَاف','الْأَنْفَال','التَّوْبَة','يُونُس',
  'هُود','يُوسُف','الرَّعْد','إِبْرَاهِيم','الْحِجْر',
  'النَّحْل','الْإِسْرَاء','الْكَهْف','مَرْيَم','طه',
  'الْأَنْبِيَاء','الْحَجّ','الْمُؤْمِنُون','النُّور','الْفُرْقَان',
  'الشُّعَرَاء','النَّمْل','الْقَصَص','الْعَنْكَبُوت','الرُّوم',
  'لُقْمَان','السَّجْدَة','الْأَحْزَاب','سَبَأ','فَاطِر',
  'يس','الصَّافَّات','ص','الزُّمَر','غَافِر',
  'فُصِّلَت','الشُّورَى','الزُّخْرُف','الدُّخَان','الْجَاثِيَة',
  'الْأَحْقَاف','مُحَمَّد','الْفَتْح','الْحُجُرَات','ق',
  'الذَّارِيَات','الطُّور','النَّجْم','الْقَمَر','الرَّحْمَن',
  'الْوَاقِعَة','الْحَدِيد','الْمُجَادَلَة','الْحَشْر','الْمُمْتَحَنَة',
  'الصَّفّ','الْجُمُعَة','الْمُنَافِقُون','التَّغَابُن','الطَّلَاق',
  'التَّحْرِيم','الْمُلْك','الْقَلَم','الْحَاقَّة','الْمَعَارِج',
  'نُوح','الْجِنّ','الْمُزَّمِّل','الْمُدَّثِّر','الْقِيَامَة',
  'الْإِنْسَان','الْمُرْسَلَات','النَّبَأ','النَّازِعَات','عَبَس',
  'التَّكْوِير','الْإِنفِطَار','الْمُطَفِّفِين','الِانشِقَاق','الْبُرُوج',
  'الطَّارِق','الْأَعْلَى','الْغَاشِيَة','الْفَجْر','الْبَلَد',
  'الشَّمْس','اللَّيْل','الضُّحَى','الشَّرْح','التِّين',
  'الْعَلَق','الْقَدْر','الْبَيِّنَة','الزَّلْزَلَة','الْعَادِيَات',
  'الْقَارِعَة','التَّكَاثُر','الْعَصْر','الْهُمَزَة','الْفِيل',
  'قُرَيْش','الْمَاعُون','الْكَوْثَر','الْكَافِرُون','النَّصْر',
  'الْمَسَد','الْإِخْلَاص','الْفَلَق','النَّاس',
];



// ── Pill Button Widget ────────────────────────────────────────────────────────
class _PillButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final bool darkMode;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.darkMode,
    required this.onTap,
  });

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inactBg = widget.darkMode ? Colors.white10 : Colors.grey.shade100;
    final inactBorder = widget.darkMode ? Colors.white24 : Colors.grey.shade300;
    final inactFg = widget.darkMode ? Colors.white54 : Colors.grey.shade600;

    final bgColor = widget.active
        ? widget.activeColor.withValues(alpha: 0.14)
        : inactBg;
    final borderColor = widget.active
        ? widget.activeColor.withValues(alpha: 0.50)
        : inactBorder;
    final fgColor = widget.active ? widget.activeColor : inactFg;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, color: fgColor, size: 15),
            const SizedBox(width: 6),
            Text(widget.label,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fgColor)),
          ]),
        ),
      ),
    );
  }
}

// ── Word-by-Word Chip Widget ──────────────────────────────────────────────────
/// A premium card for each Quranic word in the WbW grid.
/// Always-visible border card (like Quran Majeed) with:
///   • Large Arabic word (Scheherazade New / user font)
///   • Thin gold divider
///   • Italic transliteration in muted gold (if available)
///   • English translation in sub-color
class _WbwWordChip extends StatefulWidget {
  final String arabic;
  final String transliteration;
  final String translation;
  final double arabicFontSize;
  final int    quranScriptIdx;
  final Color accentColor;
  final Color txtColor;
  final Color subColor;
  final bool darkMode;

  const _WbwWordChip({
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.arabicFontSize,
    required this.quranScriptIdx,
    required this.accentColor,
    required this.txtColor,
    required this.subColor,
    required this.darkMode,
  });

  @override
  State<_WbwWordChip> createState() => _WbwWordChipState();
}

class _WbwWordChipState extends State<_WbwWordChip>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlightBg = widget.accentColor.withValues(alpha: 0.10);
    final goldClr  = widget.accentColor;

    return GestureDetector(
      onTapDown:  (_) { setState(() => _pressed = true);  _ctrl.forward(); },
      onTapUp:    (_) { setState(() => _pressed = false); _ctrl.reverse(); },
      onTapCancel: () { setState(() => _pressed = false); _ctrl.reverse(); },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _pressed ? highlightBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Arabic word — FittedBox auto-shrinks tall diacritics to fit card width
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.arabic,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: _kQuranScripts[widget.quranScriptIdx].style(
                    widget.arabicFontSize,
                    widget.txtColor,
                    1.8,  // generous height so diacritics have room
                    FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              // Gold divider
              Container(
                height: 1.2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    goldClr.withValues(alpha: 0.0),
                    goldClr.withValues(alpha: 0.6),
                    goldClr.withValues(alpha: 0.0),
                  ]),
                ),
              ),
              const SizedBox(height: 4),
              // Transliteration (italic, gold-tinted) — only if non-empty
              if (widget.transliteration.isNotEmpty) ...[
                Text(
                  widget.transliteration,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lora(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: goldClr.withValues(alpha: 0.85),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
              ],
              // English translation
              Text(
                widget.translation,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: widget.subColor,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


