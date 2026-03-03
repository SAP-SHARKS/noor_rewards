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

// ── Palette ────────────────────────────────────────────────────────────────────
const _kBg    = Color(0xFFF7F3EE);
const _kWhite = Color(0xFFFFFFFF);
const _kText  = Color(0xFF1C1C1E);
const _kSub   = Color(0xFF8E8E93);
const _kTeal  = Color(0xFF2BAE99);
const _kTealL = Color(0xFFC8ECE8);
const _kGold  = Color(0xFFFFAA00);

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
  // ── Urdu ───────────────────────────────────────────────────────────────────────
  (id:'ur.jalandhry',   name:'اردو — جالندھری',           author:'Fateh Muhammad Jalandhry',        rtl:true),
  (id:'ur.kanzuliman',  name:'اردو — کنز الایمان',        author:'Imam Ahmad Raza Khan',            rtl:true),
  (id:'ur.ahmedali',    name:'اردو — احمد علی',           author:'Shah Ahmed Ali',                  rtl:true),
  (id:'ur.maududi',     name:'اردو — تفہیم القرآن',       author:'Maulana Sayyid Abul Ala Maududi', rtl:true),
  // ── French ─────────────────────────────────────────────────────────────────────
  (id:'fr.hamidullah',  name:'Français — Hamidullah',    author:'Muhammad Hamidullah',             rtl:false),
];


// ── Reciter options ────────────────────────────────────────────────────────────
const _reciters = [
  ('ar.alafasy',      'Mishary',          '🎙️'),
  ('ar.mahermuaiqly', 'Maher',            '🎙️'),
  ('ar.abdulsamad',   'Al-Samad',         '🎙️'),
];

class QuranScreen extends StatefulWidget {
  final int initialSurah;
  final int initialAyah;
  const QuranScreen({super.key, this.initialSurah = 2, this.initialAyah = 1});
  @override State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
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
  double _translationFontSize = 15.0;  // 12-22
  bool   _showTranslation   = false;   // show/hide translation block
  bool   _showProgressCard  = true;    // show/hide daily progress card
  bool   _showPointsBanner  = true;    // show/hide +points banner
  bool   _showSurahBanner   = false;   // show/hide surah header banner
  bool   _fullScreenMode    = false;   // hide appbar+nav for focus
  // Reading aids
  bool   _wordByWord        = false;   // word-by-word mode
  List<Map<String, dynamic>> _wbwWords = [];  // [{arabic, translation}]
  bool   _wbwLoading        = false;
  // Full-page Mushaf mode
  bool   _fullPageMode      = false;   // full mushaf page mode
  int    _currentPage       = 1;       // Quran page (1–604)
  List<Map<String, dynamic>> _pageAyahs = []; // [{surah, ayah, arabic}]
  bool   _pageLoading       = false;
  Timer? _pageTimer;                   // counts seconds on current page
  int    _pageSeconds       = 0;       // seconds spent reading this page
  int    _pageXpEarned      = 0;       // XP earned this session (full-page)
  bool   _autoAdvance       = false;   // advance ayah when audio ends
  bool   _repeatAyah        = false;   // repeat current ayah audio
  // Notifications + alerts
  bool   _dailyReminder     = true;    // daily reading reminder on
  bool   _soundAlerts       = true;    // sound alert on milestone
  // Theme accent (index into _kThemeAccents)
  int    _themeIdx          = 0;

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
  void dispose() {
    _hintTimer?.cancel();
    _hintOverlay?.remove();
    _pageTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _cache = await Hive.openBox('quran_cache');
    await Future.wait([_loadProgress(), _loadBookmarks(), _loadFavourites()]);
    await _fetchAyah(_surah, _ayah);
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
          _surah = row['current_surah'] ?? 2;
          _ayah  = row['current_ayah']  ?? 1;
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
    final cacheKey = '$surah:$ayah:$_translationEdition:${_reciters[_reciterIdx].$1}';

    // Check Hive cache (7-day TTL)
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      final cachedAt = DateTime.tryParse(cached['ts'] ?? '');
      if (cachedAt != null && DateTime.now().difference(cachedAt).inDays < 7) {
        setState(() {
          _arabic      = cached['arabic'] ?? '';
          _translation = cached['trans']  ?? '';
          _audioUrl    = cached['audio'];
          _surahName   = cached['surahName'] ?? '';
          _loading     = false;
        });
        // Also refresh WBW if mode is on
        if (_wordByWord) _fetchWordByWord(surah, ayah);
        return;
      }
    }

    // ── Supabase call (Fetch Entire Surah) ───────────────────────────────────
    try {
      final recEdition = _reciters[_reciterIdx].$1;
      
      // Calculate global verse ID range for the entire surah
      int startVerseId = 1;
      for (int i = 1; i < surah; i++) {
        startVerseId += _surahLengths[i];
      }
      int endVerseId = startVerseId + _surahLengths[surah] - 1;

      // Fetch all Arabic verses for this surah
      final arabicList = await _sb.from('quran_verses')
          .select('ayah, text_uthmani')
          .eq('surah', surah);

      // Fetch all Translations for this surah
      final transList = await _sb.from('quran_translations')
          .select('verse_id, text')
          .gte('verse_id', startVerseId)
          .lte('verse_id', endVerseId)
          .eq('edition', _translationEdition);

      // Create maps for quick lookup
      final arabicMap = {for (var item in arabicList) item['ayah'] as int: item['text_uthmani'] as String};
      final transMap = {for (var item in transList) item['verse_id'] as int: item['text'] as String};

      final sName = _surahNames[surah];
      final nowStr = DateTime.now().toIso8601String();

      // Pre-cache all verses in the surah
      for (int a = 1; a <= _surahLengths[surah]; a++) {
        int vId = startVerseId + a - 1;
        String aText = arabicMap[a] ?? '';
        String tText = transMap[vId] ?? '';
        String audio = 'https://cdn.islamic.network/quran/audio/128/$recEdition/$vId.mp3';

        String cKey = '$surah:$a:$_translationEdition:$recEdition';
        await _cache.put(cKey, {
          'arabic': aText, 'trans': tText, 'audio': audio,
          'surahName': sName, 'ts': nowStr,
        });
      }

      // Read current ayah from the newly populated cache
      final newCached = _cache.get(cacheKey);
      if (newCached != null && newCached['arabic'].toString().isNotEmpty) {
        if (mounted) {
          setState(() {
          _arabic = newCached['arabic'];
          _translation = newCached['trans'];
          _audioUrl = newCached['audio'];
          _surahName = newCached['surahName'];
          _loading = false;
        });
        }
        if (_wordByWord) _fetchWordByWord(surah, ayah);
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

    setState(() {
      _surah = nextSurah; _ayah = nextAyah; _wbwWords = [];
      if (earnRewards) {
        _ayahsToday++; _pointsToday += XpReward.ayahRead;
      }
    });

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
        // Award first-read badge on the very first ayah
        if (_ayahsToday == 1) { // 1 because already incremented in setState
          await XpService.instance.awardBadge('first_quran');
        }
      }
      final today = _todayStr();
      await _sb.from('quran_progress').update({
        'current_surah': s, 'current_ayah': a,
        'ayahs_read_today': _ayahsToday,
        'last_read_date': today, 'updated_at': DateTime.now().toIso8601String(),
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
    setState(() { _surah = prevSurah; _ayah = prevAyah; _wbwWords = []; });
    _fetchAyah(prevSurah, prevAyah);
  }

  // ── Fetch word-by-word data ───────────────────────────────────────────────────
  Future<void> _fetchWordByWord(int surah, int ayah) async {
    setState(() { _wbwLoading = true; _wbwWords = []; });
    final wbwCacheKey = 'wbw_${surah}_$ayah';
    final cachedWbw = _cache.get(wbwCacheKey);
    if (cachedWbw != null) {
      final cachedAt = DateTime.tryParse((cachedWbw as Map)['ts'] ?? '');
      if (cachedAt != null && DateTime.now().difference(cachedAt).inDays < 30) {
        final words = (cachedWbw['words'] as List)
            .map((w) => Map<String, dynamic>.from(w as Map))
            .toList();
        if (mounted) setState(() { _wbwWords = words; _wbwLoading = false; });
        return;
      }
    }
    try {
      final url = 'https://api.quran.com/api/v4/verses/by_key/$surah:$ayah'
          '?words=true&word_fields=text_uthmani,text_indopak&word_translation_language=en';
      final res = await http.get(Uri.parse(url),
          headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final js = jsonDecode(res.body);
        final verse = js['verse'];
        final rawWords = verse?['words'] as List? ?? [];
        final words = rawWords
            .where((w) => w['char_type_name'] != 'end')
            .map<Map<String, dynamic>>((w) => {
              'arabic': w['text_uthmani'] ?? w['text'] ?? '',
              'translation': w['translation']?['text'] ?? '',
            }).toList();
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

  // ── Full-page Mushaf: fetch all ayahs for a page ─────────────────────────────
  Future<void> _fetchFullPage(int page) async {
    if (mounted) setState(() { _pageLoading = true; _pageAyahs = []; });

    final cacheKey = 'fullpage_$page';
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      final cachedAt = DateTime.tryParse((cached as Map)['ts'] ?? '');
      if (cachedAt != null && DateTime.now().difference(cachedAt).inDays < 30) {
        final ayahs = (cached['ayahs'] as List)
            .map((a) => Map<String, dynamic>.from(a as Map))
            .toList();
        if (mounted) setState(() { _pageAyahs = ayahs; _pageLoading = false; });
        return;
      }
    }

    try {
      final url = 'https://api.quran.com/api/v4/verses/by_page/$page'
          '?words=false&fields=text_uthmani,verse_key,page_number&per_page=50';
      final res = await http.get(Uri.parse(url),
          headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final js = jsonDecode(res.body);
        final verses = js['verses'] as List? ?? [];
        final ayahs = verses.map<Map<String, dynamic>>((v) {
          final key = (v['verse_key'] as String).split(':');
          return {
            'surah': int.tryParse(key[0]) ?? 1,
            'ayah': int.tryParse(key[1]) ?? 1,
            'arabic': v['text_uthmani'] ?? '',
          };
        }).toList();
        await _cache.put(cacheKey, {
          'ayahs': ayahs,
          'ts': DateTime.now().toIso8601String(),
        });
        if (mounted) setState(() { _pageAyahs = ayahs; _pageLoading = false; });
      } else {
        if (mounted) setState(() => _pageLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _pageLoading = false);
    }
  }

  // ── Full-page timer: 1 XP per 30 seconds ─────────────────────────────────────
  void _startPageTimer() {
    _pageTimer?.cancel();
    _pageSeconds = 0;
    _pageXpEarned = 0;
    _pageTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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
                onTap: () { Navigator.pop(context); setState(() { _surah = n; _ayah = 1; }); _fetchAyah(n, 1); },
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
    final key = '$_surah:$_ayah';
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
    // Always stop → setUrl → play (most reliable pattern across devices)
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
    await _fetchAyah(_surah, _ayah); // re-fetch gets new audio URL for new reciter
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

  String _fmtDur(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _isBookmarked  => _bookmarks.contains('$_surah:$_ayah');
  bool get _isFavourited  => _favourites.contains('$_surah:$_ayah');

  // ── Toggle favourite ──────────────────────────────────────────────────────────
  Future<void> _toggleFavourite() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) { _showSnack('Sign in to save favourites'); return; }
    final key = '$_surah:$_ayah';
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
                              Text('Arabic Font Size',
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
                              setSt(
                                  () => _arabicFontSize = v);
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
                    // Translation font slider
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
                                  Icons.format_size_rounded,
                                  size: 20, color: _accent),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                              Text('Translation Font Size',
                                  style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: lblC)),
                              Text(
                                  '${_translationFontSize.toInt()} pt',
                                  style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color:
                                          const Color(0xFF8E8E93))),
                            ]),
                          ]),
                          Slider(
                            value: _translationFontSize,
                            min: 12, max: 22, divisions: 10,
                            activeColor: _accent,
                            inactiveColor:
                                _accent.withValues(alpha: 0.2),
                            onChanged: (v) {
                              setSt(() =>
                                  _translationFontSize = v);
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
                                    color:
                                        const Color(0xFF8E8E93))),
                            Text('Large',
                                style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color:
                                        const Color(0xFF8E8E93))),
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
                        Icons.stars_rounded,
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
                                  Icons.language_rounded,
                                  size: 20, color: _accent),
                            ),
                            const SizedBox(width: 12),
                            Text('Translation Language',
                                style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: lblC)),
                          ]),
                          const SizedBox(height: 12),
                          ...List.generate(_translations.length, (i) {
                            final sel = _translations[i].id == _translationEdition;
                            return GestureDetector(
                              onTap: () async {
                                setSt(() => _translationEdition = _translations[i].id);
                                setState(() => _translationEdition = _translations[i].id);
                                await _fetchAyah(_surah, _ayah);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                    color: sel
                                        ? _accent.withValues(alpha: 0.12)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: sel
                                            ? _accent
                                            : Colors.grey.shade300)),
                                child: Row(children: [
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_translations[i].name,
                                          maxLines: 1, // Added maxLines
                                          overflow: TextOverflow.ellipsis, // Added overflow
                                          style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: sel
                                                  ? _accent
                                                  : const Color(0xFF1C1C1E))),
                                      Text(_translations[i].author,
                                          maxLines: 1, // Added maxLines
                                          overflow: TextOverflow.ellipsis, // Added overflow
                                          style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              color: const Color(0xFF8E8E93))),
                                    ],
                                  )),
                                  if (sel)
                                    Icon(Icons.check_circle_rounded,
                                        color: _accent, size: 18),
                                ]),
                              ),
                            );
                          }),
                        ]),
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

  // ── build() ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bg     = _darkMode ? const Color(0xFF000000) : _kBg;
    final cardBg = _darkMode ? const Color(0xFF1C1C1E) : _kWhite;
    final barBg  = _darkMode ? const Color(0xFF1C1C1E) : _kWhite;
    final txt    = _darkMode ? Colors.white            : _kText;
    final sub    = _darkMode ? const Color(0xFF8E8E93) : _kSub;

    return Scaffold(
      backgroundColor: bg,
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
      body: Stack(children: [
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
                    Text('+$_pointsToday Noor Points earned today!',
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
                        Text('$_surahName • Surah $_surah',
                            style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                            'Ayah $_ayah of '
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
                    // 📖 Read Tafsir
                    _PillButton(
                      icon: Icons.menu_book_rounded,
                      label: 'Tafsir',
                      active: false,          // opens sheet — never stays active
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
                    // 🗒️ Full Page
                    _PillButton(
                      icon: Icons.menu_book_outlined,
                      label: _fullPageMode ? 'Page $_currentPage' : 'Full Page',
                      active: _fullPageMode,
                      activeColor: const Color(0xFF4CAF50),
                      darkMode: _darkMode,
                      onTap: () {
                        setState(() {
                          _fullPageMode = !_fullPageMode;
                          // Disable incompatible modes
                          if (_fullPageMode) {
                            _wordByWord = false;
                            _wbwWords = [];
                          }
                        });
                        if (_fullPageMode) {
                          _fetchFullPage(_currentPage);
                          _startPageTimer();
                        } else {
                          _stopPageTimer();
                        }
                      },
                    ),
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
                  else if (_fullPageMode) ...[
                    // ── Full Page Mushaf Mode ──────────────────────────────────
                    _buildFullPageMushaf(txt, sub, cardBg),
                  ] else if (_wordByWord) ...[ 
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
                          Text('Word data unavailable.\nCheck your connection.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontSize: 13, color: sub)),
                        ]),
                      ))
                    else
                      _buildWordByWordView(txt, sub),
                  ] else ...[ 
                    // ── Full Verse Mode ──────────────────────────────────────
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        _arabic,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.amiri(
                            fontSize: _arabicFontSize,
                            height: 2.1,
                            color: txt,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_showTranslation) ...[
                      const SizedBox(height: 20),
                      Divider(height: 1,
                          color: _darkMode
                              ? Colors.white12
                              : Colors.grey.shade100),
                      const SizedBox(height: 16),
                      // RTL-aware translation rendering
                      (() {
                        final def = _translations.firstWhere(
                          (t) => t.id == _translationEdition,
                          orElse: () => _translations.first,
                        );
                        return Text(
                          _translation,
                          textAlign: def.rtl ? TextAlign.right : TextAlign.left,
                          textDirection: def.rtl ? TextDirection.rtl : TextDirection.ltr,
                          style: def.rtl
                              ? GoogleFonts.amiri(
                                  fontSize: _translationFontSize + 2,
                                  color: sub,
                                  height: 1.9)
                              : GoogleFonts.outfit(
                                  fontSize: _translationFontSize,
                                  color: sub,
                                  height: 1.75),
                        );
                      })(),
                    ],
                  ],
                ]),
              ),
              // ── Full Page Timer Bar ──────────────────────────────────────────────
              if (_fullPageMode) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: _darkMode ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
                    border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 38, height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0x1F4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.timer_rounded, color: Color(0xFF4CAF50), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Page Reading · Page $_currentPage',
                          style: GoogleFonts.outfit(fontSize: 11, color: sub, fontWeight: FontWeight.w500)),
                      Text(_pageTimerLabel,
                          style: GoogleFonts.outfit(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: const Color(0xFF4CAF50), letterSpacing: 1.5)),
                    ]),
                    const Spacer(),
                    if (_pageXpEarned > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('+$_pageXpEarned XP',
                            style: GoogleFonts.outfit(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: const Color(0xFF4CAF50))),
                      ),
                    GestureDetector(
                      onTap: () {
                        if (_pageTimer != null) {
                          _stopPageTimer();
                          setState(() {});
                        } else {
                          _startPageTimer();
                        }
                      },
                      child: Container(
                        width: 38, height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0x1F4CAF50),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _pageTimer != null ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: const Color(0xFF4CAF50), size: 22),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _currentPage > 1 ? () {
                        setState(() { _currentPage--; _pageSeconds = 0; });
                        _fetchFullPage(_currentPage);
                      } : null,
                      child: Icon(Icons.chevron_left_rounded,
                          color: _currentPage > 1 ? txt : Colors.grey.shade400, size: 28),
                    ),
                    GestureDetector(
                      onTap: _currentPage < 604 ? () {
                        setState(() { _currentPage++; _pageSeconds = 0; });
                        _fetchFullPage(_currentPage);
                      } : null,
                      child: Icon(Icons.chevron_right_rounded,
                          color: _currentPage < 604 ? txt : Colors.grey.shade400, size: 28),
                    ),
                  ]),
                ),
              ],
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
                        child: Text('+$_pointsToday pts',
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
          // Audio player — shown only when user taps Listen
          if (!_fullScreenMode)
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: _showAudioPlayer
                  ? _buildAudioPlayer()
                  : const SizedBox.shrink(),
            ),
          if (!_fullScreenMode)
            _buildNavRow(barBg: barBg, txt: txt),
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
                _fsFab(
                  icon: Icons.arrow_back_ios_rounded,
                  onTap: _prevAyah,
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _nextAyah,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 13),
                    decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text('+10 pts',
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
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
      ]),
    );
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

  // ── Full-Page Mushaf View ─────────────────────────────────────────────────────
  Widget _buildFullPageMushaf(Color txtColor, Color subColor, Color cardBg) {
    if (_pageLoading) {
      return Center(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(children: [
          CircularProgressIndicator(color: const Color(0xFF4CAF50), strokeWidth: 2),
          const SizedBox(height: 14),
          Text('Loading page $_currentPage...',
              style: GoogleFonts.outfit(fontSize: 13, color: subColor)),
        ]),
      ));
    }

    if (_pageAyahs.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(children: [
          Icon(Icons.wifi_off_rounded, color: subColor, size: 40),
          const SizedBox(height: 10),
          Text('Page unavailable.\nCheck your connection.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13, color: subColor)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _fetchFullPage(_currentPage),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
              ),
              child: Text('Retry', style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF4CAF50))),
            ),
          ),
        ]),
      ));
    }

    // Detect surah changes within the page for bismillah breaks
    String? lastSurah;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // ── Page header ──
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            border: Border.all(color: _accent.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '— صفحة $_currentPage —',
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(fontSize: 14, color: _accent, fontWeight: FontWeight.w600),
          ),
        ),
      ),

      // ── Continuous RTL text with ayah markers ──
      Directionality(
        textDirection: TextDirection.rtl,
        child: Wrap(
          alignment: WrapAlignment.start,
          runSpacing: 0,
          children: _pageAyahs.expand<Widget>((ayah) {
            final surahNum = ayah['surah'] as int;
            final ayahNum  = ayah['ayah'] as int;
            final arabic   = ayah['arabic'] as String;
            final surahKey = '$surahNum';
            final widgets  = <Widget>[];

            // Surah name header when surah changes within the page
            if (lastSurah != surahKey) {
              lastSurah = surahKey;
              if (ayahNum == 1 && surahNum > 1) {
                widgets.add(SizedBox(width: double.infinity,
                  child: Column(children: [
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _surahNames[surahNum - 1],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(fontSize: 16, fontWeight: FontWeight.w700, color: _accent),
                      ),
                    ),
                    // Bismillah (except Surah 9)
                    if (surahNum != 9)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.amiri(fontSize: 18, color: txtColor, fontWeight: FontWeight.w700, height: 2.0),
                        ),
                      ),
                    const SizedBox(height: 4),
                  ]),
                ));
              }
            }

            // Ayah text + end marker inline
            widgets.add(
              RichText(
                textDirection: TextDirection.rtl,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: arabic,
                      style: GoogleFonts.amiri(
                        fontSize: _arabicFontSize * 0.78,
                        height: 2.0,
                        color: txtColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    // Ayah number circle (Unicode circle with number)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _accent.withValues(alpha: 0.5)),
                          color: _accent.withValues(alpha: 0.06),
                        ),
                        child: Center(
                          child: Text(
                            '$ayahNum',
                            style: GoogleFonts.outfit(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: _accent, height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
            return widgets;
          }).toList(),
        ),
      ),
    ]);
  }

  // ── Word-by-Word View ─────────────────────────────────────────────────────────
  Widget _buildWordByWordView(Color txtColor, Color subColor) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 2,      // horizontal gap between chips
        runSpacing: 8,   // vertical gap between rows
        children: _wbwWords.map((wordData) {
          final arabic = wordData['arabic'] as String? ?? '';
          final translation = wordData['translation'] as String? ?? '';
          return _WbwWordChip(
            arabic: arabic,
            translation: translation,
            arabicFontSize: _arabicFontSize,
            accentColor: _accent,
            txtColor: txtColor,
            subColor: subColor,
            darkMode: _darkMode,
          );
        }).toList(),
      ),
    );
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
        color: _kWhite, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Row 1: Reciter chips in horizontally scrollable row ───────────────
        Row(children: [
          const Text('🎙️', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text('Reciter:', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: _kSub)),
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
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel ? _kTeal : _kBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? _kTeal : Colors.grey.shade200),
                  ),
                  child: Text(_reciters[i].$2,
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : _kSub)),
                ),
              );
            })),
          )),
        ]),

        // ── Row 2: Seek slider ──────────────────────────────────────────
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: hasAudio ? _kTeal : Colors.grey.shade300,
            inactiveTrackColor: hasAudio ? _kTealL : Colors.grey.shade200,
            thumbColor: hasAudio ? _kTeal : Colors.grey.shade400,
            overlayColor: _kTeal.withValues(alpha: 0.2),
            disabledActiveTrackColor: Colors.grey.shade300,
          ),
          child: Slider(
            value: sliderVal, min: 0, max: sliderMax,
            onChanged: hasAudio ? (v) => _player.seek(Duration(milliseconds: v.toInt())) : null,
          ),
        ),

        // ── Row 3: Controls + timer on same row ───────────────────────────
        Row(children: [
          IconButton(
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            icon: Icon(Icons.skip_previous_rounded, size: 26,
                color: hasAudio ? _kTeal : Colors.grey.shade300),
            onPressed: hasAudio ? _prevAyah : null,
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
                    ? Colors.grey.shade200
                    : _isPlaying ? const Color(0xFF1FA882) : _kTeal,
                boxShadow: hasAudio ? [BoxShadow(
                    color: _kTeal.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))] : null,
              ),
              child: _audioLoading
                  ? const Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
                  : Icon(
                      !hasAudio ? Icons.hourglass_top_rounded
                          : _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: hasAudio ? Colors.white : Colors.grey.shade400, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            icon: Icon(Icons.skip_next_rounded, size: 26,
                color: hasAudio ? _kTeal : Colors.grey.shade300),
            onPressed: hasAudio ? _nextAyah : null,
          ),
          const Spacer(),
          Text(
            hasAudio ? '${_fmtDur(_pos)} / ${_fmtDur(_dur)}' : 'Loading audio...',
            style: GoogleFonts.outfit(fontSize: 11, color: _kSub),
          ),
        ]),
      ]),
    );
  }

  Widget _buildNavRow({required Color barBg, required Color txt}) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      color: barBg,
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPad),
      child: Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: _saving ? null : _prevAyah,
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
          label: Text('Previous',
              style: GoogleFonts.outfit(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(
                color: _darkMode
                    ? Colors.white24
                    : Colors.grey.shade300),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            foregroundColor: txt,
          ),
        )),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton.icon(
          onPressed: _saving ? null : _nextAyah,
          icon: _saving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.white),
          label: Text('Next +10 pts',
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            disabledBackgroundColor: _accent.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        )),
      ]),
    );
  }
}

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
class _WbwWordChip extends StatefulWidget {
  final String arabic;
  final String translation;
  final double arabicFontSize;
  final Color accentColor;
  final Color txtColor;
  final Color subColor;
  final bool darkMode;

  const _WbwWordChip({
    required this.arabic,
    required this.translation,
    required this.arabicFontSize,
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
  bool _highlighted = false;
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goldUnderline = widget.accentColor.withValues(alpha: 0.75);
    final highlightBg = widget.accentColor.withValues(alpha: 0.10);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _highlighted = true);
        _ctrl.forward();
      },
      onTapUp: (_) {
        setState(() => _highlighted = false);
        _ctrl.reverse();
      },
      onTapCancel: () {
        setState(() => _highlighted = false);
        _ctrl.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
          decoration: BoxDecoration(
            color: _highlighted ? highlightBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: _highlighted
                ? Border.all(color: widget.accentColor.withValues(alpha: 0.3))
                : null,
          ),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Arabic word — naturally sized
                Text(
                  widget.arabic,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.amiri(
                    fontSize: widget.arabicFontSize * 0.80,
                    fontWeight: FontWeight.w700,
                    color: widget.txtColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 3),
                // Gold underline — stretches to match the column's intrinsic width
                Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: goldUnderline,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 3),
                // English translation — centered, same width as Arabic
                Text(
                  widget.translation,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: widget.subColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
