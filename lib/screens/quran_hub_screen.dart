import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../l10n/app_localizations.dart';
import '../widgets/quran_engagement_strip.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'quran_screen.dart';
import '../widgets/noor_offline.dart';
import '../services/settings_service.dart';
import '../services/quran_api_service.dart';
import '../models/app_config.dart';
import '../theme/y4_theme.dart';

// ── Palette (reads from admin-controlled AppConfig) ─────────────────────────
AppConfig get _qhcfg => SettingsService.instance.config;
Color get _kBg => _qhcfg.dashBg;
const _kWhite = Color(0xFFFFFFFF);
Color get _kText => _qhcfg.dashText;
Color get _kSub =>
    _qhcfg.dashBg.computeLuminance() > 0.5
        ? const Color(0xFF8E8E93)
        : const Color(0xFF9CA3AF);
Color get _kTeal => _qhcfg.dashTeal;
Color get _kTealL => _qhcfg.dashTeal.withValues(alpha: 0.25);
Color get _kGold => _qhcfg.quranGold;

// ── Surah names (1-indexed, index 0 unused) ───────────────────────────────────
// Arabic-script surah names — surfaced in Urdu locale (most Urdu Islamic
// apps use Arabic script for surah names, not Latin transliteration). Index 0
// padded to keep 1-indexed lookups identical to `_surahNames` below.
const _surahNamesUr = [
  '',
  'الفاتحہ', 'البقرہ', 'آل عمران', 'النساء', 'المائدہ',
  'الانعام', 'الاعراف', 'الانفال', 'التوبہ', 'یونس',
  'ھود', 'یوسف', 'الرعد', 'ابراہیم', 'الحجر',
  'النحل', 'الاسراء', 'الکہف', 'مریم', 'طٰہ',
  'الانبیاء', 'الحج', 'المؤمنون', 'النور', 'الفرقان',
  'الشعراء', 'النمل', 'القصص', 'العنکبوت', 'الروم',
  'لقمان', 'السجدہ', 'الاحزاب', 'سبا', 'فاطر',
  'یسٓ', 'الصافات', 'صٓ', 'الزمر', 'غافر',
  'فصلت', 'الشوریٰ', 'الزخرف', 'الدخان', 'الجاثیہ',
  'الاحقاف', 'محمد', 'الفتح', 'الحجرات', 'قٓ',
  'الذاریات', 'الطور', 'النجم', 'القمر', 'الرحمٰن',
  'الواقعہ', 'الحدید', 'المجادلہ', 'الحشر', 'الممتحنہ',
  'الصف', 'الجمعہ', 'المنافقون', 'التغابن', 'الطلاق',
  'التحریم', 'الملک', 'القلم', 'الحاقہ', 'المعارج',
  'نوح', 'الجن', 'المزمل', 'المدثر', 'القیامہ',
  'الانسان', 'المرسلات', 'النبا', 'النازعات', 'عبس',
  'التکویر', 'الانفطار', 'المطففین', 'الانشقاق', 'البروج',
  'الطارق', 'الاعلیٰ', 'الغاشیہ', 'الفجر', 'البلد',
  'الشمس', 'اللیل', 'الضحیٰ', 'الشرح', 'التین',
  'العلق', 'القدر', 'البینہ', 'الزلزلہ', 'العادیات',
  'القارعہ', 'التکاثر', 'العصر', 'الھمزہ', 'الفیل',
  'قریش', 'الماعون', 'الکوثر', 'الکافرون', 'النصر',
  'اللھب', 'الاخلاص', 'الفلق', 'الناس',
];

// Latin-script English transliteration — used for en/fr/id/ms/ru/tr fallback
// and as the canonical search key (search filter on this list to allow
// typing "fatihah" / "baqara" etc.).
const _surahNames = [
  '',
  'Al-Fatihah',
  'Al-Baqarah',
  'Ali \'Imran',
  'An-Nisa\'',
  'Al-Ma\'idah',
  'Al-An\'am',
  'Al-A\'raf',
  'Al-Anfal',
  'At-Tawbah',
  'Yunus',
  'Hud',
  'Yusuf',
  'Ar-Ra\'d',
  'Ibrahim',
  'Al-Hijr',
  'An-Nahl',
  'Al-Isra\'',
  'Al-Kahf',
  'Maryam',
  'Ta-Ha',
  'Al-Anbiya\'',
  'Al-Hajj',
  'Al-Mu\'minun',
  'An-Nur',
  'Al-Furqan',
  'Ash-Shu\'ara\'',
  'An-Naml',
  'Al-Qasas',
  'Al-\'Ankabut',
  'Ar-Rum',
  'Luqman',
  'As-Sajdah',
  'Al-Ahzab',
  'Saba\'',
  'Fatir',
  'Ya-Sin',
  'As-Saffat',
  'Sad',
  'Az-Zumar',
  'Ghafir',
  'Fussilat',
  'Ash-Shura',
  'Az-Zukhruf',
  'Ad-Dukhan',
  'Al-Jathiyah',
  'Al-Ahqaf',
  'Muhammad',
  'Al-Fath',
  'Al-Hujurat',
  'Qaf',
  'Ad-Dhariyat',
  'At-Tur',
  'An-Najm',
  'Al-Qamar',
  'Ar-Rahman',
  'Al-Waqi\'ah',
  'Al-Hadid',
  'Al-Mujadila',
  'Al-Hashr',
  'Al-Mumtahanah',
  'As-Saf',
  'Al-Jumu\'ah',
  'Al-Munafiqun',
  'At-Taghabun',
  'At-Talaq',
  'At-Tahrim',
  'Al-Mulk',
  'Al-Qalam',
  'Al-Haqqah',
  'Al-Ma\'arij',
  'Nuh',
  'Al-Jinn',
  'Al-Muzzammil',
  'Al-Muddathir',
  'Al-Qiyamah',
  'Al-Insan',
  'Al-Mursalat',
  'An-Naba\'',
  'An-Naz\'iat',
  'Abasa',
  'At-Takwir',
  'Al-Infitar',
  'Al-Mutaffifin',
  'Al-Inshiqaq',
  'Al-Buruj',
  'At-Tariq',
  'Al-A\'la',
  'Al-Ghashiyah',
  'Al-Fajr',
  'Al-Balad',
  'Ash-Shams',
  'Al-Layl',
  'Ad-Duha',
  'Ash-Sharh',
  'At-Tin',
  'Al-\'Alaq',
  'Al-Qadr',
  'Al-Bayyinah',
  'Az-Zalzalah',
  'Al-\'Adiyat',
  'Al-Qari\'ah',
  'At-Takathur',
  'Al-\'Asr',
  'Al-Humazah',
  'Al-Fil',
  'Quraysh',
  'Al-Ma\'un',
  'Al-Kawthar',
  'Al-Kafirun',
  'An-Nasr',
  'Al-Masad',
  'Al-Ikhlas',
  'Al-Falaq',
  'An-Nas',
];

const _surahLengths = [
  0,
  7,
  286,
  200,
  176,
  120,
  165,
  206,
  75,
  129,
  109,
  123,
  111,
  43,
  52,
  99,
  128,
  111,
  110,
  98,
  135,
  112,
  78,
  118,
  64,
  77,
  227,
  93,
  88,
  69,
  60,
  34,
  30,
  73,
  54,
  45,
  83,
  182,
  88,
  75,
  85,
  54,
  53,
  89,
  59,
  37,
  35,
  38,
  29,
  18,
  45,
  60,
  49,
  62,
  55,
  78,
  96,
  29,
  22,
  24,
  13,
  14,
  11,
  11,
  18,
  12,
  12,
  30,
  52,
  52,
  44,
  28,
  28,
  20,
  56,
  40,
  31,
  50,
  40,
  46,
  42,
  29,
  19,
  36,
  25,
  22,
  17,
  19,
  26,
  30,
  20,
  15,
  21,
  11,
  8,
  8,
  19,
  5,
  8,
  8,
  11,
  11,
  8,
  3,
  9,
  5,
  4,
  7,
  3,
  6,
  3,
  5,
  4,
  5,
  6,
];

// ─────────────────────────────────────────────────────────────────────────────
class QuranHubScreen extends StatefulWidget {
  const QuranHubScreen({super.key});
  @override
  State<QuranHubScreen> createState() => _QuranHubScreenState();
}

class _QuranHubScreenState extends State<QuranHubScreen>
    with SingleTickerProviderStateMixin {
  final _sb = Supabase.instance.client;

  // Last-read / resume position
  int _lastSurah = 2, _lastAyah = 1;
  // Initialized to English form; replaced with locale-aware name in `_loadData`.
  String _lastSurahName = 'Al-Baqarah';

  // Selected position for starting
  int _selSurah = 1, _selAyah = 1;

  // Favourites & bookmarks counts
  int _bookmarkCount = 0, _favouriteCount = 0;

  // Bookmarked+Favourite ayah lists for the list views
  List<Map<String, dynamic>> _bookmarks = [];
  List<Map<String, dynamic>> _favourites = [];

  // Today progress
  int _ayahsToday = 0;

  // Header pill — user lifetime totals
  int _userSeeds = 0;
  int _userAyahs = 0;
  int _userReadSec = 0;

  bool _loading = true;

  // Returns the surah name localised to the active locale.
  // Search filter logic intentionally uses `_surahNames` (English) so users
  // can still type "fatihah"/"baqara" regardless of locale.
  String _localSurahName(int n) {
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == 'ur') return _surahNamesUr[n.clamp(1, 114)];
    return _surahNames[n.clamp(1, 114)];
  }

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      // ── 3 parallel reads (was 4 sequential round-trips) ─────────────────
      // The previous code did: upsert, select, bookmarks, favourites — all
      // strictly sequential. Combine upsert+select into one PostgREST call
      // (via .select().single()) and fire the three reads in parallel.
      final results = await Future.wait<dynamic>([
        // 0: ensure-row + read in one round-trip
        _sb
            .from('quran_progress')
            .upsert({'user_id': uid}, onConflict: 'user_id')
            .select()
            .single()
            .then<Map<String, dynamic>?>((v) => v)
            .catchError((_) => null),
        // 1: all bookmarks
        _sb
            .from('quran_bookmarks')
            .select('surah, ayah')
            .eq('user_id', uid)
            .order('created_at', ascending: false)
            .then<List<dynamic>>((v) => v as List)
            .catchError((_) => const <dynamic>[]),
        // 2: favourites only — kept separate so a missing `is_favourite`
        //    column on legacy schemas doesn't poison the bookmarks fetch
        _sb
            .from('quran_bookmarks')
            .select('surah, ayah')
            .eq('user_id', uid)
            .eq('is_favourite', true)
            .order('created_at', ascending: false)
            .then<List<dynamic>>((v) => v as List)
            .catchError((_) => const <dynamic>[]),
        // 3: lifetime totals for the header pill (Seeds + ayahs + read time)
        _sb
            .from('profiles')
            .select('total_xp, ayahs_read')
            .eq('id', uid)
            .maybeSingle()
            .then<Map<String, dynamic>?>((v) => v)
            .catchError((_) => null),
        // 4: lifetime quran_time_sec (Mushaf timer accumulator)
        _sb
            .from('user_analytics')
            .select('quran_time_sec')
            .eq('user_id', uid)
            .maybeSingle()
            .then<Map<String, dynamic>?>((v) => v)
            .catchError((_) => null),
      ]);

      final prog = results[0] as Map<String, dynamic>?;
      if (prog != null) {
        _lastSurah = prog['current_surah'] ?? 2;
        _lastAyah = prog['current_ayah'] ?? 1;
        _lastSurahName = _localSurahName(_lastSurah);
        _selSurah = _lastSurah;
        _selAyah = _lastAyah;

        final today = DateTime.now().toIso8601String().split('T')[0];
        if ((prog['last_read_date'] ?? '') == today) {
          _ayahsToday = prog['ayahs_read_today'] ?? 0;
        }
      }

      _bookmarks = List<Map<String, dynamic>>.from(results[1] as List);
      _bookmarkCount = _bookmarks.length;
      _favourites = List<Map<String, dynamic>>.from(results[2] as List);
      _favouriteCount = _favourites.length;

      final profile = results[3] as Map<String, dynamic>?;
      if (profile != null) {
        _userSeeds = (profile['total_xp'] as num?)?.toInt() ?? 0;
        _userAyahs = (profile['ayahs_read'] as num?)?.toInt() ?? 0;
      }
      final analytics = results[4] as Map<String, dynamic>?;
      if (analytics != null) {
        _userReadSec = (analytics['quran_time_sec'] as num?)?.toInt() ?? 0;
      }

      // QF bookmarks pulled in the background so a slow QF API can't stall
      // this screen — Supabase data is already canonical and shown above.
      // ignore: unawaited_futures
      _foldInQfBookmarksLater();
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      _fadeCtrl.forward();
    }
  }

  Future<void> _foldInQfBookmarksLater() async {
    try {
      if (!await QuranApiService.instance.isUserLoggedIn()) return;
      final qfBookmarks = await QuranApiService.instance.getBookmarks();
      if (!mounted) return;
      bool changed = false;
      for (final b in qfBookmarks) {
        final int s = b['chapterNumber'] ?? b['key'] ?? 1;
        final int a = b['verseNumber'] ?? 1;
        if (!_bookmarks
            .any((existing) => existing['surah'] == s && existing['ayah'] == a)) {
          _bookmarks.add({'surah': s, 'ayah': a});
          changed = true;
        }
      }
      if (changed && mounted) {
        setState(() => _bookmarkCount = _bookmarks.length);
      }
    } catch (_) {
      // Best-effort — Supabase is the source of truth for the UI.
    }
  }

  // ── Navigate into the reading screen ─────────────────────────────────────────
  Future<void> _startReading({int? surah, int? ayah}) async {
    HapticFeedback.mediumImpact();
    final s = surah ?? _selSurah;
    final a = ayah ?? _selAyah;
    final nav = Navigator.of(
      context,
      rootNavigator: true,
    ); // capture before async gap

    // Persist chosen position so Resume is immediately in sync
    final uid = _sb.auth.currentUser?.id;
    if (uid != null) {
      try {
        await _sb
            .from('quran_progress')
            .update({
              'current_surah': s,
              'current_ayah': a,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', uid);
      } catch (_) {}
    }

    // Update local resume card right away
    if (mounted) {
      setState(() {
        _lastSurah = s;
        _lastAyah = a;
        _lastSurahName = _localSurahName(s);
      });
    }

    final pts = await nav.push<int>(
      MaterialPageRoute(
        builder: (_) => QuranScreen(initialSurah: s, initialAyah: a),
      ),
    );
    if ((pts ?? 0) > 0 && mounted) _loadData();
  }

  // ── Surah picker sheet ────────────────────────────────────────────────────────
  void _pickSurah() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final filteredSurahs =
                List.generate(114, (i) => i + 1).where((n) {
                  if (searchQuery.isEmpty) return true;
                  final name = _surahNames[n].toLowerCase();
                  return name.contains(searchQuery.toLowerCase()) ||
                      n.toString() == searchQuery;
                }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder:
                  (_, ctrl) => Container(
                    decoration: const BoxDecoration(
                      color: _kWhite,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            AppLocalizations.of(context)?.chooseSurah ??
                                'Choose Surah',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _kText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              onChanged:
                                  (val) =>
                                      setStateSheet(() => searchQuery = val),
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                color: _kText,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    AppLocalizations.of(context)?.searchSurahHint ??
                                        'Search Surah...',
                                hintStyle: GoogleFonts.outfit(
                                  color: Colors.grey.shade500,
                                ),
                                border: InputBorder.none,
                                icon: Icon(
                                  Icons.search_rounded,
                                  color: Colors.grey.shade400,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            controller: ctrl,
                            itemCount: filteredSurahs.length,
                            itemBuilder: (_, i) {
                              final n = filteredSurahs[i];
                              final name = _localSurahName(n);
                              final len = _surahLengths[n];
                              final sel = n == _selSurah;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selSurah = n;
                                    _selAyah = 1;
                                  });
                                  Navigator.pop(context);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  color: sel
                                      ? Y4.honey.withValues(alpha: 0.10)
                                      : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: sel
                                              ? Y4.honeyDeep
                                              : Y4.honey.withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$n',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: sel
                                                  ? Colors.white
                                                  : Y4.honeyDeep,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: _kText,
                                              ),
                                            ),
                                            Text(
                                              AppLocalizations.of(context)
                                                      ?.versesCount(len) ??
                                                  '$len verses',
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: _kSub,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (sel)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: Y4.honeyDeep,
                                          size: 22,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
            );
          },
        );
      },
    );
  }

  // ── Verse / Ayah picker ───────────────────────────────────────────────────────
  void _pickAyah() {
    final maxAyah = _surahLengths[_selSurah];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder:
                (_, ctrl) => Container(
                  decoration: const BoxDecoration(
                    color: _kWhite,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          AppLocalizations.of(context)?.chooseVerse ??
                              'Choose Verse',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _kText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          AppLocalizations.of(context)?.surahHasNVerses(
                                _localSurahName(_selSurah),
                                maxAyah,
                              ) ??
                              '${_localSurahName(_selSurah)} has $maxAyah verses',
                          style: GoogleFonts.outfit(fontSize: 13, color: _kSub),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          controller: ctrl,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1,
                              ),
                          itemCount: maxAyah,
                          itemBuilder: (_, i) {
                            final n = i + 1;
                            final sel = n == _selAyah;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _selAyah = n);
                                Navigator.pop(context);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                decoration: BoxDecoration(
                                  color: sel ? Y4.honeyDeep : _kWhite,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: sel
                                        ? Y4.honeyDeep
                                        : Colors.grey.shade200,
                                  ),
                                  boxShadow: sel
                                      ? [
                                          BoxShadow(
                                            color: Y4.honeyDeep
                                                .withValues(alpha: 0.30),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '$n',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: sel ? Colors.white : _kText,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  // ── Bookmarks / Favourites list sheet ─────────────────────────────────────────
  void _showSavedList({required bool isFavourites}) {
    final list = isFavourites ? _favourites : _bookmarks;
    final title =
        isFavourites
            ? AppLocalizations.of(context)?.favourites ?? 'Favourites'
            : AppLocalizations.of(context)?.bookmarks ?? 'Bookmarks';
    final color = isFavourites ? Y4.honeyDeep : Y4.primary;
    final icon = isFavourites ? Icons.favorite_rounded : Icons.bookmark_rounded;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            builder:
                (_, ctrl) => Container(
                  decoration: const BoxDecoration(
                    color: _kWhite,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(icon, color: color, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _kText,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${list.length} saved',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: _kSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (list.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  size: 56,
                                  color: Colors.grey.shade200,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppLocalizations.of(context)?.noXYet(title) ??
                                      'No $title yet',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    color: _kSub,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppLocalizations.of(context)
                                          ?.tapHeartToSave ??
                                      'Tap the heart/bookmark icon while reading to save verses.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.grey.shade400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            controller: ctrl,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final item = list[i];
                              final s = item['surah'] as int? ?? 1;
                              final a = item['ayah'] as int? ?? 1;
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _startReading(surah: s, ayah: a);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            icon,
                                            color: color,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _surahNames[s.clamp(1, 114)],
                                              style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: _kText,
                                              ),
                                            ),
                                            Text(
                                              AppLocalizations.of(context)
                                                      ?.surahVerseRow(s, a) ??
                                                  'Surah $s  •  Verse $a',
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: _kSub,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: _kSub,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body:
          _loading
              ? Center(
                child: NoorInlineLoader(
                  height: double.infinity,
                  color: _kTeal,
                  label: 'Loading Quran…',
                ),
              )
              : FadeTransition(opacity: _fadeAnim, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final showStrip = _qhcfg.showQuranEngagement;
    return CustomScrollView(
      slivers: [
        // ── Sticky header ─ honey wash hero ────────────────────────────────
        // expandedHeight shrinks when the engagement strip is hidden so the
        // body content (Resume Reading) rides up instead of leaving a gap.
        SliverAppBar(
          expandedHeight: showStrip ? 192 : 110,
          pinned: true,
          toolbarHeight: 44,
          backgroundColor: _kBg,
          surfaceTintColor: _kBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Y4.ink,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            // Force LTR for the whole header so RTL locales (Urdu/Arabic)
            // don't flip icon rows or push SVGs out of position.
            background: Directionality(
              textDirection: TextDirection.ltr,
              child: Container(
              color: _kBg,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stylish wordmark in a soft cream-honey banner — keeps
                      // the warm header colour on just the title row.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Y4.cream,
                              Y4.honey.withValues(alpha: 0.40),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Y4.honey.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          'Al-Quran',
                          style: GoogleFonts.fraunces(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Y4.honeyDeep,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: _UserStatsPill(
                          seeds: _userSeeds,
                          ayahs: _userAyahs,
                          readSeconds: _userReadSec,
                        ),
                      ),
                      // Engagement strip — admin toggle. Hides the whole
                      // "reading right now / frequently read" card when
                      // app_config.show_quran_engagement = false.
                      if (SettingsService.instance.config.showQuranEngagement) ...[
                        const SizedBox(height: 6),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 28),
                          child: QuranEngagementStrip(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Continue reading card ─────────────────────────────────────────
                _SectionLabel(
                  label:
                      AppLocalizations.of(context)?.resumeReading ??
                      'Resume Reading',
                ),
                const SizedBox(height: 10),
                _ContinueCard(
                  surahName: _lastSurahName,
                  surah: _lastSurah,
                  ayah: _lastAyah,
                  onTap:
                      () => _startReading(surah: _lastSurah, ayah: _lastAyah),
                ),
                const SizedBox(height: 24),

                // ── Start new position ────────────────────────────────────────────
                _SectionLabel(
                  label:
                      AppLocalizations.of(context)?.chooseWhereToStart ??
                      'Choose Where to Start',
                ),
                const SizedBox(height: 10),

                // Surah selector row
                _PickerRow(
                  icon: Icons.menu_book_rounded,
                  iconColor: Y4.honeyDeep,
                  label: AppLocalizations.of(context)?.surahPickerLabel ?? 'Surah',
                  value: _localSurahName(_selSurah),
                  subtitle: AppLocalizations.of(context)
                          ?.versesCount(_surahLengths[_selSurah]) ??
                      '${_surahLengths[_selSurah]} verses',
                  onTap: _pickSurah,
                ),
                const SizedBox(height: 10),

                // Ayah selector row
                _PickerRow(
                  icon: Icons.format_list_numbered_rounded,
                  iconColor: Y4.honeyDeep,
                  label:
                      AppLocalizations.of(context)?.startFromVerse ??
                          'Start from Verse',
                  value: AppLocalizations.of(context)?.verseN(_selAyah) ??
                      'Verse $_selAyah',
                  subtitle: AppLocalizations.of(context)
                          ?.ofN(_surahLengths[_selSurah]) ??
                      'of ${_surahLengths[_selSurah]}',
                  onTap: _pickAyah,
                ),
                const SizedBox(height: 20),

                // ── Big start button ──────────────────────────────────────────────
                GestureDetector(
                  onTap: () => _startReading(),
                  child: Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Y4.butter, Y4.honey],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Y4.honeyDeep.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.auto_stories_rounded,
                            color: Y4.ink,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          // Flexible + ellipsis prevents overflow when the
                          // translation expands the label (e.g. ur/ru/de).
                          // The button is visually obvious from the icon, so
                          // a clipped tail is acceptable.
                          Flexible(
                            child: Text(
                              '${AppLocalizations.of(context)?.startReadingFrom ?? 'Start Reading from'} ${_localSurahName(_selSurah)} : $_selAyah',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Y4.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Saved / Favourites grid ───────────────────────────────────────
                _SectionLabel(
                  label:
                      AppLocalizations.of(context)?.yourLibrary ??
                      'Your Library',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _LibraryCard(
                        icon: Icons.favorite_rounded,
                        color: Y4.honeyDeep,
                        label:
                            AppLocalizations.of(context)?.favourites ??
                            'Favourites',
                        count: _favouriteCount,
                        onTap: () => _showSavedList(isFavourites: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LibraryCard(
                        icon: Icons.bookmark_rounded,
                        color: Y4.honeyDeep,
                        label:
                            AppLocalizations.of(context)?.bookmarks ??
                            'Bookmarks',
                        count: _bookmarkCount,
                        onTap: () => _showSavedList(isFavourites: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Quick access tiles ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _QuickTile(
                        icon: Icons.shuffle_rounded,
                        color: Y4.honeyDeep,
                        label:
                            AppLocalizations.of(context)?.randomVerse ??
                            'Random Verse',
                        onTap: () {
                          final s =
                              1 + (DateTime.now().millisecondsSinceEpoch % 114);
                          final a =
                              1 +
                              (DateTime.now().microsecond % _surahLengths[s]);
                          _startReading(
                            surah: s,
                            ayah: a.clamp(1, _surahLengths[s]),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickTile(
                        icon: Icons.water_drop_rounded,
                        color: Y4.honey,
                        label: _localSurahName(1),
                        onTap: () => _startReading(surah: 1, ayah: 1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickTile(
                        icon: Icons.nights_stay_rounded,
                        color: Y4.primary,
                        label: _localSurahName(18),
                        subtitle:
                            AppLocalizations.of(context)?.sunnahFriday ??
                            'Sunnah Friday',
                        onTap: () => _startReading(surah: 18, ayah: 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting Widgets
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Header stat pill — Seeds + ayahs read + reading time, separated by dividers.
// Replaces the old "Al Quran al Kareem" Arabic header.
// ─────────────────────────────────────────────────────────────────────────────
class _UserStatsPill extends StatelessWidget {
  final int seeds;
  final int ayahs;
  final int readSeconds;
  const _UserStatsPill({
    required this.seeds,
    required this.ayahs,
    required this.readSeconds,
  });

  String _fmt(int n) {
    if (n < 1000) return '$n';
    if (n < 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    if (n < 1000000) return '${(n / 1000).round()}k';
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }

  String _fmtTime(int sec) {
    if (sec <= 0) return '0:00';
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}';
    return '0:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Y4.honey.withValues(alpha: 0.55), width: 1.2),
        boxShadow: [
          // Soft warm halo
          BoxShadow(
            color: Y4.honey.withValues(alpha: 0.32),
            blurRadius: 14,
          ),
          // Subtle honey drop
          BoxShadow(
            color: Y4.honeyDeep.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Locked LTR so the cell order (Seeds → Quran → Timer) stays the
      // same in RTL locales like Urdu/Arabic, and the SVG icons sit on
      // the correct side of their numbers.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatCell(
              asset: 'assets/images/LOGO.svg',
              value: _fmt(seeds),
            ),
            _PillDivider(),
            _StatCell(
              asset: 'assets/icons/stat_quran.svg',
              value: _fmt(ayahs),
            ),
            _PillDivider(),
            _StatCell(
              asset: 'assets/icons/stat_timer.svg',
              value: _fmtTime(readSeconds),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String asset;
  final String value;
  const _StatCell({required this.asset, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(asset, width: 26, height: 26),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Y4.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      color: Y4.honey.withValues(alpha: 0.35),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: GoogleFonts.outfit(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF8E8E93),
    ),
  );
}

class _ContinueCard extends StatefulWidget {
  final String surahName;
  final int surah, ayah;
  final VoidCallback onTap;
  const _ContinueCard({
    required this.surahName,
    required this.surah,
    required this.ayah,
    required this.onTap,
  });
  @override
  State<_ContinueCard> createState() => _ContinueCardState();
}

class _ContinueCardState extends State<_ContinueCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            // Light honey gradient — matches dashboard hero
            gradient: const LinearGradient(
              colors: [Y4.butter, Y4.honey],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Y4.honeyDeep.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          // Locked LTR so the icon circle stays on the left of the surah
          // info in Urdu/Arabic RTL locales.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                // Book icon circle (white on honey)
                Container(
                  width: 52,
                  height: 52,
                decoration: BoxDecoration(
                  color: Y4.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Y4.ink.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/stat_quran.svg',
                    width: 36,
                    height: 36,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.surahName,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Y4.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Surah ${widget.surah}  •  Verse ${widget.ayah}  •  ${AppLocalizations.of(context)?.continueReading ?? 'Continue reading'}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Y4.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Y4.honeyDeep,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.resume ?? 'Resume',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
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

class _PickerRow extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value, subtitle;
  final VoidCallback onTap;
  const _PickerRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });
  @override
  State<_PickerRow> createState() => _PickerRowState();
}

class _PickerRowState extends State<_PickerRow> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _pressed ? Colors.grey.shade100 : _kWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Y4.butter, widget.iconColor.withValues(alpha: 0.30)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.iconColor.withValues(alpha: 0.40),
                ),
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: GoogleFonts.outfit(fontSize: 12, color: _kSub),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.value,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.subtitle,
                  style: GoogleFonts.outfit(fontSize: 11, color: _kSub),
                ),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right_rounded, color: _kSub, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final VoidCallback onTap;
  const _LibraryCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    required this.onTap,
  });
  @override
  State<_LibraryCard> createState() => _LibraryCardState();
}

class _LibraryCardState extends State<_LibraryCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color.withValues(alpha: 0.30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Y4.butter, widget.color.withValues(alpha: 0.30)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.40),
                  ),
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.count} saved',
                style: GoogleFonts.outfit(fontSize: 11, color: _kSub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTile extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  const _QuickTile({
    required this.icon,
    required this.color,
    required this.label,
    this.subtitle,
    required this.onTap,
  });
  @override
  State<_QuickTile> createState() => _QuickTileState();
}

class _QuickTileState extends State<_QuickTile> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.color, size: 26),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.subtitle!,
                  style: GoogleFonts.outfit(fontSize: 9, color: _kSub),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
