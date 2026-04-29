import 'dart:async';
import 'dart:convert';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/settings_service.dart';
import '../models/app_config.dart';
import '../widgets/noor_offline.dart';

AppConfig get _tscfg => SettingsService.instance.config;

// ── Palette ────────────────────────────────────────────────────────────────────
Color get _kBg    => _tscfg.dashBg;
const _kWhite = Color(0xFFFFFFFF);
Color get _kText  => _tscfg.dashText;
Color get _kSub   => _tscfg.dashBg.computeLuminance() > 0.5
    ? const Color(0xFF8E8E93) : const Color(0xFF9CA3AF);
const _kGreen = Color(0xFF4A9B5F);
const _kGreenL= Color(0xFFCCE5CC);
const _kGold  = Color(0xFFFFAA00);

// ── Surah lengths (1-indexed) ─────────────────────────────────────────────────
const _tSurahLengths = [
  0,
  7,  286, 200, 176, 120, 165, 206,  75, 129, 109,
 123, 111,  43,  52,  99, 128, 111, 110,  98, 135,
 112,  78, 118,  64,  77, 227,  93,  88,  69,  60,
  34,  30,  73,  54,  45,  83, 182,  88,  75,  85,
  54,  53,  89,  59,  37,  35,  38,  29,  18,  45,
  60,  49,  62,  55,  78,  96,  29,  22,  24,  13,
  14,  11,  11,  18,  12,  12,  30,  52,  52,  44,
  28,  28,  20,  56,  40,  31,  50,  40,  46,  42,
  29,  19,  36,  25,  22,  17,  19,  26,  30,  20,
  15,  21,  11,   8,   8,  19,   5,   8,   8,  11,
  11,   8,   3,   9,   5,   4,   7,   3,   6,   3,
   5,   4,   5,   6,
];

const _tSurahNames = [
  '',
  'Al-Fatihah','Al-Baqarah','Ali Imran','An-Nisa','Al-Maidah',
  'Al-Anam','Al-Araf','Al-Anfal','At-Tawbah','Yunus',
  'Hud','Yusuf','Ar-Ra\'d','Ibrahim','Al-Hijr',
  'An-Nahl','Al-Isra','Al-Kahf','Maryam','Ta-Ha',
  'Al-Anbiya','Al-Hajj','Al-Muminun','An-Nur','Al-Furqan',
  'Ash-Shu\'ara','An-Naml','Al-Qasas','Al-Ankabut','Ar-Rum',
  'Luqman','As-Sajdah','Al-Ahzab','Saba','Fatir',
  'Ya-Sin','As-Saffat','Sad','Az-Zumar','Ghafir',
  'Fussilat','Ash-Shura','Az-Zukhruf','Ad-Dukhan','Al-Jathiyah',
  'Al-Ahqaf','Muhammad','Al-Fath','Al-Hujurat','Qaf',
  'Adh-Dhariyat','At-Tur','An-Najm','Al-Qamar','Ar-Rahman',
  'Al-Waqi\'ah','Al-Hadid','Al-Mujadila','Al-Hashr','Al-Mumtahanah',
  'As-Saf','Al-Jumuah','Al-Munafiqun','At-Taghabun','At-Talaq',
  'At-Tahrim','Al-Mulk','Al-Qalam','Al-Haqqah','Al-Ma\'arij',
  'Nuh','Al-Jinn','Al-Muzzammil','Al-Muddaththir','Al-Qiyamah',
  'Al-Insan','Al-Mursalat','An-Naba','An-Naziat','Abasa',
  'At-Takwir','Al-Infitar','Al-Mutaffifin','Al-Inshiqaq','Al-Buruj',
  'At-Tariq','Al-Ala','Al-Ghashiyah','Al-Fajr','Al-Balad',
  'Ash-Shams','Al-Layl','Ad-Duha','Ash-Sharh','At-Tin',
  'Al-Alaq','Al-Qadr','Al-Bayyinah','Az-Zalzalah','Al-Adiyat',
  'Al-Qari\'ah','At-Takathur','Al-Asr','Al-Humazah','Al-Fil',
  'Quraysh','Al-Ma\'un','Al-Kawthar','Al-Kafirun','An-Nasr',
  'Al-Masad','Al-Ikhlas','Al-Falaq','An-Nas',
];

// ── Tafsir sources ───────────────────────────────────────────────────────────
// Two sources:
//  'cloud'  → api.alquran.cloud/v1/ayah/{ref}/editions/quran-simple,en.sahih,{id}
//  'cdn'    → cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir/{slug}/{surah}.json
//
// (id, displayName, emoji, source, slug-for-cdn, isRTL)
typedef _TafsirDef = ({String id, String name, String emoji, String src, String slug, bool rtl});

const List<_TafsirDef> _tafsirEditions = [
  // ── English ──────────────────────────────────────────────────────────────────
  (id:'en-tafisr-ibn-kathir',    name:'Ibn Kathir (EN)',   emoji:'🕌', src:'cdn',   slug:'en-tafisr-ibn-kathir',    rtl:false),
  (id:'en-tafsir-maarif-ul-quran',name:"Maarif ul Quran", emoji:'📚', src:'cdn',   slug:'en-tafsir-maarif-ul-quran', rtl:false),
  // ── Urdu ─────────────────────────────────────────────────────────────────────
  (id:'ur-tafseer-ibn-e-kaseer', name:'ابن کثیر (اردو)',  emoji:'📖', src:'cdn',   slug:'ur-tafseer-ibn-e-kaseer',   rtl:true),
  (id:'ur-tafsir-bayan-ul-quran',name:'بیان القرآن',      emoji:'🎓', src:'cdn',   slug:'ur-tafsir-bayan-ul-quran',  rtl:true),
  // ── Arabic (classical) ───────────────────────────────────────────────────────
  (id:'ar.muyassar',             name:'المیسَّر',          emoji:'🌙', src:'cloud', slug:'',                          rtl:true),
  (id:'ar.jalalayn',             name:'الجلالین',          emoji:'📜', src:'cloud', slug:'',                          rtl:true),
  (id:'ar.qurtubi',              name:'القرطبی',           emoji:'🏛️', src:'cloud', slug:'',                          rtl:true),
];

// ── Reciters for audio ────────────────────────────────────────────────────────
const _tReciters = [
  ('ar.alafasy',      'Mishary'),
  ('ar.mahermuaiqly', 'Maher'),
  ('ar.abdulsamad',   'Al-Samad'),
];

// ─────────────────────────────────────────────────────────────────────────────
class TafsirScreen extends StatefulWidget {
  final int initialSurah;
  final int initialAyah;
  const TafsirScreen({super.key, this.initialSurah = 1, this.initialAyah = 1});
  @override
  State<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends State<TafsirScreen> {
  // ── Position ────────────────────────────────────────────────────────────────
  late int _surah;
  late int _ayah;

  // ── Content ─────────────────────────────────────────────────────────────────
  String _arabic        = '';
  String _translation   = '';
  String _tafsirText    = '';
  bool   _loading       = true;

  // ── Settings ─────────────────────────────────────────────────────────────────
  int    _tafsirIdx   = -1;   // which tafsir edition
  int    _reciterIdx  = 0;   // which audio reciter
  double _fontSize    = 22;
  bool   _darkMode    = false;
  bool   _showArabic  = true;

  // ── Points ───────────────────────────────────────────────────────────────────
  // (Tafsir is read-only; no XP is awarded for reading or listening)

  // ── Audio ────────────────────────────────────────────────────────────────────
  final _player = AudioPlayer();
  String?   _audioUrl;
  Duration  _pos = Duration.zero;
  Duration  _dur = Duration.zero;
  bool      _isPlaying = false;

  // ── Supabase / cache ─────────────────────────────────────────────────────────
  final _sb    = Supabase.instance.client;
  Box?  _cache;

  String get _surahName => _tSurahNames[_surah];
  int    get _surahLen  => _tSurahLengths[_surah];

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _surah = widget.initialSurah;
    _ayah  = widget.initialAyah;
    _initAudio();
    _initData();
  }

  Future<void> _initData() async {
    await _initCache();
    _loadAyah();
  }

  Future<void> _initCache() async {
    _cache = await Hive.openBox('tafsir_cache');
    if (_cache?.get('pref_tafsir_idx') == null && mounted) {
      final lang = Localizations.localeOf(context).languageCode;
      if (lang == 'ur') _tafsirIdx = 2; // Urdu Ibn Kathir
      else if (lang == 'ar') _tafsirIdx = 4; // Arabic Muyassar
      else _tafsirIdx = 0; // English Ibn Kathir
    } else {
      _tafsirIdx = _cache?.get('pref_tafsir_idx', defaultValue: 0) as int;
    }
  }

  Future<void> _initAudio() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    _player.positionStream.listen((p) {
      if (mounted) setState(() => _pos = p);
    });
    _player.durationStream.listen((d) {
      if (mounted) setState(() => _dur = d ?? Duration.zero);
    });
    _player.playerStateStream.listen((s) {
      final playing = s.processingState != ProcessingState.completed &&
          s.playing;
      if (mounted) setState(() => _isPlaying = playing);
    });

  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }


  // ── Data loading ─────────────────────────────────────────────────────────────
  Future<void> _loadAyah() async {
    setState(() => _loading = true);

    final def = _tafsirEditions[_tafsirIdx];
    final cacheKey = 'tafsir2_${_surah}_${_ayah}_${def.id}';

    String arabic = '', translation = '', tafsir = '', audioUrl = '';

    // ── Cache hit ────────────────────────────────────────────────────────────
    final cached = _cache?.get(cacheKey);
    if (cached != null) {
      final m = cached as Map;
      arabic      = m['arabic']      ?? '';
      translation = m['translation'] ?? '';
      tafsir      = m['tafsir']      ?? '';
      audioUrl    = m['audio']       ?? '';
    } else {
      try {
      // ── Fetch Arabic + English translation for the entire Surah ──────────────
        int startVerseId = 1;
        for (int i = 1; i < _surah; i++) {
          startVerseId += _tSurahLengths[i];
        }
        int endVerseId = startVerseId + _tSurahLengths[_surah] - 1;

        final arabicList = await _sb.from('quran_verses')
            .select('ayah, text_uthmani')
            .eq('surah', _surah);

        final transList = await _sb.from('quran_translations')
            .select('verse_id, text')
            .gte('verse_id', startVerseId)
            .lte('verse_id', endVerseId)
            .eq('edition', 'en.sahih');

        final arabicMap = {for (var item in arabicList) item['ayah'] as int: item['text_uthmani'] as String};
        final transMap = {for (var item in transList) item['verse_id'] as int: item['text'] as String};

        // ── Fetch tafsir text for the entire Surah (if CDN) ──────────────────────
      Map<int, String> tafsirMap = {};
      if (def.src == 'cdn') {
        // spa5k/tafsir_api: one JSON per surah, indexed by ayah
        final cdnUrl = 'https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir/${def.slug}/$_surah.json';
        final tRes = await http.get(Uri.parse(cdnUrl)).timeout(const Duration(seconds: 15));
        if (tRes.statusCode == 200) {
          final ayahs = jsonDecode(tRes.body)['ayahs'] as List?;
          if (ayahs != null) {
            for (var a in ayahs) {
              tafsirMap[a['ayah'] as int] = a['text'] as String;
            }
          }
        }
      } else {
        // alquran.cloud tafsir edition (API returns entire surah)
        final tUrl = 'https://api.alquran.cloud/v1/surah/$_surah/${def.id}';
        final tRes = await http.get(Uri.parse(tUrl)).timeout(const Duration(seconds: 15));
        if (tRes.statusCode == 200) {
          final ayahs = jsonDecode(tRes.body)['data']['ayahs'] as List?;
          if (ayahs != null) {
            for (var a in ayahs) {
              tafsirMap[a['numberInSurah'] as int] = a['text'] as String;
            }
          }
        }
      }

      final reciter = _tReciters[_reciterIdx].$1;

      // ── Pre-cache all verses in the Surah ────────────────────────────────────
      for (int a = 1; a <= _tSurahLengths[_surah]; a++) {
        int vId = startVerseId + a - 1;
        String aText = arabicMap[a] ?? '';
        String tText = transMap[vId] ?? '';
        String audio = 'https://cdn.islamic.network/quran/audio/128/$reciter/$vId.mp3';
        
        String tfsr = tafsirMap[a] ?? '';
        String cKey = 'tafsir2_${_surah}_${a}_${def.id}';
        await _cache?.put(cKey, {
          'arabic': aText, 'translation': tText,
          'tafsir': tfsr, 'audio': audio,
        });
        
        if (a == _ayah) {
          arabic = aText;
          translation = tText;
          tafsir = tfsr;
          audioUrl = audio;
        }
      }
    } catch (_) {}
    }

    // Stop old player
    await _player.stop();

    if (mounted) {
      setState(() {
        _arabic      = arabic;
        _translation = translation;
        _tafsirText  = tafsir;
        _audioUrl    = audioUrl.isNotEmpty ? audioUrl : null;
        _pos         = Duration.zero;
        _dur         = Duration.zero;
        _loading     = false;
      });
    }

    // Pre-load audio
    if (audioUrl.isNotEmpty) {
      try {
        await _player.setUrl(audioUrl);
      } catch (_) {}
    }

    // Save progress to Supabase
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _sb.from('user_progress').upsert({
        'user_id':       uid,
        'last_surah':    _surah,
        'last_ayah':     _ayah,
        'activity_type': 'tafsir',
      }, onConflict: 'user_id,activity_type');
    } catch (_) {}
  }

  // ── Audio controls ────────────────────────────────────────────────────────────
  Future<void> _togglePlay() async {
    if (_audioUrl == null) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }


  // ── Navigation ────────────────────────────────────────────────────────────────

  void _prevAyah() {
    if (_ayah > 1) {
      setState(() => _ayah--);
    } else if (_surah > 1) {
      setState(() {
        _surah--;
        _ayah = _tSurahLengths[_surah];
      });
    }
    _loadAyah();
  }

  void _nextAyah() {
    if (_ayah < _surahLen) {
      setState(() => _ayah++);
    } else if (_surah < 114) {
      setState(() { _surah++; _ayah = 1; });
    }
    _loadAyah();
  }

  // ── Settings sheet ────────────────────────────────────────────────────────────
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SettingsSheet(
        darkMode:    _darkMode,
        fontSize:    _fontSize,
        showArabic:  _showArabic,
        tafsirIdx:   _tafsirIdx,
        reciterIdx:  _reciterIdx,
        onDarkMode:  (v) => setState(() => _darkMode   = v),
        onFontSize:  (v) => setState(() => _fontSize   = v),
        onArabic:    (v) => setState(() => _showArabic = v),
        onTafsir:    (i) { setState(() => _tafsirIdx  = i); _cache?.put('pref_tafsir_idx', i); _loadAyah(); },
        onReciter:   (i) { setState(() => _reciterIdx = i); _loadAyah(); },
      ),
    );
  }

  // ── Surah picker ──────────────────────────────────────────────────────────────
  void _showSurahPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final bg = _darkMode ? const Color(0xFF1C1C1E) : _kWhite;
        final tx = _darkMode ? Colors.white : _kText;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          builder: (_, sc) => Container(
            decoration: BoxDecoration(color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: ListView.builder(
              controller: sc,
              itemCount: 114,
              itemBuilder: (_, i) {
                final s = i + 1;
                final sel = s == _surah;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: sel ? _kGreen : _kGreenL,
                    child: Text('$s',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : _kGreen, fontSize: 12)),
                  ),
                  title: Text(_tSurahNames[s],
                      style: GoogleFonts.outfit(
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: tx)),
                  subtitle: Text('${_tSurahLengths[s]} verses',
                      style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
                  onTap: () {
                    setState(() { _surah = s; _ayah = 1; });
                    Navigator.pop(context);
                    _loadAyah();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ── Rich tafsir formatter (Quranly-style) ──────────────────────────────────
  // Detects: Arabic Quranic verses, section headings, verse references,
  // parenthetical translations, and inline Arabic to format like Quranly.

  // Matches 3+ consecutive Arabic characters (including diacritics)
  static final _arabicRunRe = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]'
    r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\s]*'
    r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]'
  );
  // Matches parenthetical text like (And We delay it only...)
  static final _parenRe = RegExp(r'\(([^)]+)\)');
  // Matches verse references like (11:104) or (2:255)
  static final _verseRefRe = RegExp(r'^\(\d+:\d+(?:-\d+)?\)$');

  bool _isArabicLine(String line) {
    final arabicChars = line.runes.where((c) =>
        (c >= 0x0600 && c <= 0x06FF) || (c >= 0x0750 && c <= 0x077F) ||
        (c >= 0xFB50 && c <= 0xFDFF) || (c >= 0xFE70 && c <= 0xFEFF)).length;
    return arabicChars > line.runes.length * 0.35;
  }

  bool _isHeading(String line) {
    final t = line.trim();
    if (t.length > 120 || t.length < 4) return false;
    if (t.startsWith('(') || t.startsWith('"') || t.startsWith('`')) return false;
    // Must start with uppercase letter
    final firstLetter = t.codeUnitAt(0);
    if (firstLetter < 65 || (firstLetter > 90 && firstLetter < 97) || firstLetter > 122) return false;
    if (t[0] != t[0].toUpperCase()) return false;
    // Headings don't end with . or , (but can end with : or nothing)
    if (t.endsWith('.') || t.endsWith(',') || t.endsWith(')')) return false;
    final words = t.split(RegExp(r'\s+')).length;
    return words <= 16;
  }

  Widget _buildFormattedTafsir(String text, Color txt, Color sub) {
    // Remove all parentheses — Arabic gets its own block, translations are italic
    text = text.replaceAll('(', '').replaceAll(')', '');
    final lines = text.split('\n');
    final widgets = <Widget>[];
    final buffer = StringBuffer();
    // Track if next line after Arabic is a verse reference
    bool lastWasArabic = false;

    void addEngBlock(String s) {
      if (s.trim().isEmpty) return;
      final spans = <InlineSpan>[];
      _addEnglishSpans(spans, s, txt, sub);
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text.rich(TextSpan(children: spans),
          style: GoogleFonts.notoSerif(fontSize: _fontSize - 2, color: txt, height: 1.85)),
      ));
    }

    void addArabBlock(String s) {
      widgets.add(Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: txt.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(s.trim(),
          textAlign: TextAlign.center, textDirection: TextDirection.rtl,
          style: GoogleFonts.scheherazadeNew(
            fontSize: _fontSize + 6, color: txt, height: 2.0, fontWeight: FontWeight.w700)),
      ));
    }

    void flushBuffer() {
      if (buffer.isEmpty) return;
      final content = buffer.toString().trim();
      buffer.clear();
      if (content.isEmpty) return;

      int last = 0;
      for (final m in _arabicRunRe.allMatches(content)) {
        final arabicText = m.group(0)!;
        if (arabicText.replaceAll(RegExp(r'\s'), '').length >= 5) {
          if (m.start > last) addEngBlock(content.substring(last, m.start));
          addArabBlock(arabicText);
          last = m.end;
        }
      }
      if (last < content.length) {
        addEngBlock(content.substring(last));
      } else if (last == 0) {
        addEngBlock(content);
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        flushBuffer();
        lastWasArabic = false;
        continue;
      }

      // Verse reference after Arabic block — e.g. (11:104)
      if (lastWasArabic && _verseRefRe.hasMatch(line)) {
        lastWasArabic = false;
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Center(child: Text(line,
            style: GoogleFonts.outfit(
              fontSize: _fontSize - 4,
              fontStyle: FontStyle.italic,
              color: sub,
              height: 1.4,
            ),
          )),
        ));
        continue;
      }

      // Pure Arabic line — centered Quranic verse with ornamental brackets
      if (_isArabicLine(line)) {
        flushBuffer();
        lastWasArabic = true;
        widgets.add(Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 14),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: txt.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(line,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.scheherazadeNew(
              fontSize: _fontSize + 6,
              color: txt,
              height: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ));

        // Check if the next non-empty line is a parenthetical translation
        final nextIdx = lines.indexWhere((l) => l.trim().isNotEmpty, i + 1);
        if (nextIdx != -1) {
          final nextLine = lines[nextIdx].trim();
          if (nextLine.startsWith('(') && nextLine.endsWith(')')) {
            widgets.add(Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Center(child: Text(nextLine,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: _fontSize - 1,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF7C3AED),
                  height: 1.6,
                ),
              )),
            ));
            // Skip that line in the main loop
            for (int j = i + 1; j <= nextIdx; j++) {
              lines[j] = '';
            }
          }
        }
        continue;
      }
      lastWasArabic = false;

      // Section heading — bold, spaced
      if (_isHeading(line)) {
        flushBuffer();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Text(line,
            style: GoogleFonts.outfit(
              fontSize: _fontSize,
              fontWeight: FontWeight.w800,
              color: txt,
              height: 1.35,
            ),
          ),
        ));
        continue;
      }

      // Regular text — accumulate
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(line);
    }
    flushBuffer();

    if (widgets.isEmpty) {
      return Text(text, style: GoogleFonts.outfit(
        fontSize: _fontSize - 2, color: txt, height: 1.8));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  void _addEnglishSpans(List<InlineSpan> spans, String text, Color txt, Color sub) {
    int last = 0;
    for (final m in _parenRe.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      // Check if it's a verse reference like (11:104)
      final inner = m.group(1) ?? '';
      if (RegExp(r'^\d+:\d+').hasMatch(inner)) {
        // Verse reference — smaller, italic
        spans.add(TextSpan(
          text: m.group(0),
          style: GoogleFonts.outfit(
            fontSize: _fontSize - 4,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF7C3AED),
          ),
        ));
      } else {
        // Translation in parentheses — italic, muted
        spans.add(TextSpan(
          text: m.group(0),
          style: GoogleFonts.outfit(
            fontSize: _fontSize - 2,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF7C3AED),
            height: 1.8,
          ),
        ));
      }
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bg     = _darkMode ? const Color(0xFF000000) : _kBg;
    final cardBg = _darkMode ? const Color(0xFF1C1C1E) : _kWhite;
    final txt    = _darkMode ? Colors.white : _kText;
    final sub    = _darkMode ? const Color(0xFF8E8E93) : _kSub;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        surfaceTintColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: txt, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Read Tafsir',
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.w800, color: txt)),
        centerTitle: true,

        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, color: sub, size: 24),
            onPressed: _openSettings, tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(children: [
        // ── Surah selector bar ─────────────────────────────────────────────
        GestureDetector(
          onTap: _showSurahPicker,
          child: Container(
            color: cardBg,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(children: [
              Icon(Icons.auto_stories_rounded, color: _kGreen, size: 18),
              const SizedBox(width: 8),
              Text('$_surahName • Surah $_surah',
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _kGreen)),
              const Spacer(),
              Text('Ayah $_ayah of $_surahLen',
                  style: GoogleFonts.outfit(fontSize: 12, color: sub)),
              const SizedBox(width: 6),
              Icon(Icons.expand_more_rounded, color: sub, size: 18),
            ]),
          ),
        ),
        const Divider(height: 1),

        // ── Main scrollable content ────────────────────────────────────────
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [

            // ── Arabic ayah card ─────────────────────────────────────────

            if (_showArabic) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [
                        _kGreen.withValues(alpha: 0.85),
                        _kGreen,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                      color: _kGreen.withValues(alpha: 0.3),
                      blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: _loading
                    ? const Center(child: NoorInlineLoader())
                    : Text(_arabic,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                            fontSize: _fontSize + 4,
                            color: Colors.white, height: 2.0)),
              ),
              const SizedBox(height: 16),
            ],

            // ── Translation ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 3, height: 20,
                      decoration: BoxDecoration(
                          color: _kGreen,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text('Translation',
                      style: GoogleFonts.outfit(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: _kGreen, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 10),
                _loading
                    ? const LinearProgressIndicator()
                    : Text(_translation,
                        style: GoogleFonts.outfit(
                            fontSize: _fontSize - 4,
                            color: txt, height: 1.6)),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Tafsir text ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _kGreen.withValues(alpha: 0.15)),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  Row(children: [
                    Container(width: 3, height: 20,
                        decoration: BoxDecoration(
                            color: _kGold,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text('Tafsir · ${_tafsirEditions[_tafsirIdx].name}',
                        style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: _kGold, letterSpacing: 0.5)),
                  ]),
                ]),
                const SizedBox(height: 10),
                _loading
                    ? Column(children: [
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Text('Loading tafsir...',
                            style: GoogleFonts.outfit(fontSize: 13, color: sub)),
                      ])
                    : _tafsirText.isEmpty
                        ? Text('Tafsir not available for this ayah.',
                            style: GoogleFonts.outfit(
                                fontSize: _fontSize - 4, color: sub, height: 1.7))
                        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: _kGold.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                _tafsirEditions[_tafsirIdx].rtl
                                    ? (_tafsirEditions[_tafsirIdx].id.startsWith('ar') ? 'Arabic Scripture' : 'Urdu Scripture')
                                    : 'English Commentary',
                                style: GoogleFonts.outfit(
                                    fontSize: 10, fontWeight: FontWeight.w600,
                                    color: _kGold)),
                            ),
                            const SizedBox(height: 14),
                            _tafsirEditions[_tafsirIdx].rtl
                                ? Text(_tafsirText,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: GoogleFonts.amiri(
                                        fontSize: _fontSize, color: txt, height: 1.9))
                                : _buildFormattedTafsir(_tafsirText, txt, sub),
                          ]),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Audio player ──────────────────────────────────────────────
            _buildAudioPlayer(cardBg, txt, sub),
            const SizedBox(height: 16),

            // ── Nav buttons ───────────────────────────────────────────────
            _buildNavRow(),
            const SizedBox(height: 20),
          ]),
        )),
      ]),
    );
  }


  Widget _buildAudioPlayer(Color cardBg, Color txt, Color sub) {
    final sliderVal = _dur.inMilliseconds > 0
        ? (_pos.inMilliseconds / _dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    String fmt(Duration d) =>
        '${d.inMinutes.toString().padLeft(2,'0')}:'
        '${(d.inSeconds % 60).toString().padLeft(2,'0')}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)]),
      child: Column(children: [
        // Reciter tabs
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (int i = 0; i < _tReciters.length; i++) ...[
            GestureDetector(
              onTap: () { setState(() => _reciterIdx = i); _loadAyah(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: i == _reciterIdx ? _kGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(_tReciters[i].$2,
                    style: GoogleFonts.outfit(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: i == _reciterIdx ? Colors.white : sub)),
              ),
            ),
            if (i < _tReciters.length - 1) const SizedBox(width: 4),
          ],
        ]),
        const SizedBox(height: 12),
        // Seek slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _kGreen,
            inactiveTrackColor: _kGreen.withValues(alpha: 0.2),
            thumbColor: _kGreen,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackHeight: 3,
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: sliderVal,
            onChanged: _audioUrl == null ? null : (v) async {
              final pos = Duration(
                  milliseconds: (v * _dur.inMilliseconds).round());
              await _player.seek(pos);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fmt(_pos),
                  style: GoogleFonts.outfit(fontSize: 11, color: sub)),
              Text(fmt(_dur),
                  style: GoogleFonts.outfit(fontSize: 11, color: sub)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Play button
        GestureDetector(
          onTap: _audioUrl == null ? null : _togglePlay,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: _audioUrl == null
                  ? _kGreen.withValues(alpha: 0.3)
                  : _kGreen,
              shape: BoxShape.circle,
              boxShadow: _audioUrl != null ? [BoxShadow(
                  color: _kGreen.withValues(alpha: 0.4),
                  blurRadius: 16, offset: const Offset(0, 6))] : null,
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white, size: 28),
          ),
        ),
      ]),
    );
  }

  Widget _buildNavRow() {
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: (_surah == 1 && _ayah == 1) ? null : _prevAyah,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
              color: _kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.chevron_left_rounded, color: _kGreen, size: 22),
            Text('Previous',
                style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _kGreen)),
          ]),
        ),
      )),
      const SizedBox(width: 12),
      Expanded(child: GestureDetector(
        onTap: (_surah == 114 && _ayah == _surahLen) ? null : _nextAyah,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF3A8050), _kGreen]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: _kGreen.withValues(alpha: 0.35),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Next Ayah',
                style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white, size: 22),
          ]),
        ),
      )),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsSheet extends StatefulWidget {
  final bool   darkMode, showArabic;
  final double fontSize;
  final int    tafsirIdx, reciterIdx;
  final ValueChanged<bool>   onDarkMode, onArabic;
  final ValueChanged<double> onFontSize;
  final ValueChanged<int>    onTafsir, onReciter;

  const _SettingsSheet({
    required this.darkMode, required this.showArabic,
    required this.fontSize, required this.tafsirIdx,
    required this.reciterIdx, required this.onDarkMode,
    required this.onArabic, required this.onFontSize,
    required this.onTafsir, required this.onReciter,
  });

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late bool   _dark;
  late bool   _arabic;
  late double _fs;
  late int    _ti;
  late int    _ri;

  @override
  void initState() {
    super.initState();
    _dark   = widget.darkMode;
    _arabic = widget.showArabic;
    _fs     = widget.fontSize;
    _ti     = widget.tafsirIdx;
    _ri     = widget.reciterIdx;
  }

  @override
  Widget build(BuildContext context) {
    final bg  = _dark ? const Color(0xFF1C1C1E) : _kWhite;
    final lbl = _dark ? Colors.white : _kText;
    final sub = _dark ? const Color(0xFF8E8E93) : _kSub;

    Widget sHead(String t, IconData ic) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(children: [
        Icon(ic, size: 16, color: _kGreen),
        const SizedBox(width: 8),
        Text(t, style: GoogleFonts.outfit(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: _kSub, letterSpacing: 1.2)),
      ]),
    );

    Widget sw(String label, bool val, ValueChanged<bool> cb) => Row(
      children: [
        Expanded(
          child: Text(label, style: GoogleFonts.outfit(fontSize: 14, color: lbl)),
        ),
        Switch(value: val, onChanged: cb,
            activeThumbColor: _kGreen, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ]);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      builder: (_, sc) {
        final safePad = MediaQuery.of(context).padding.bottom;
        return Container(
        decoration: BoxDecoration(color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + safePad),
        child: ListView(controller: sc, children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: sub.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Reading Settings', style: GoogleFonts.outfit(
              fontSize: 18, fontWeight: FontWeight.w800, color: lbl)),

          sHead('TAFSIR SOURCE', Icons.menu_book_rounded),
          for (int i = 0; i < _tafsirEditions.length; i++)
            GestureDetector(
              onTap: () { setState(() => _ti = i); widget.onTafsir(i); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: i == _ti ? _kGreen.withValues(alpha: 0.12) : Colors.transparent,
                  border: Border.all(
                      color: i == _ti ? _kGreen : sub.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_tafsirEditions[i].name,
                        style: GoogleFonts.outfit(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: i == _ti ? _kGreen : lbl)),
                    Text(_tafsirEditions[i].rtl
                            ? (_tafsirEditions[i].id.startsWith('ar') ? 'Arabic' : 'Urdu')
                            : 'English',
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: sub)),
                  ])),
                  if (i == _ti)
                    const Icon(Icons.check_circle_rounded, color: _kGreen, size: 20),
                ]),
              ),
            ),

          sHead('RECITER', Icons.mic_rounded),
          Row(children: [
            for (int i = 0; i < _tReciters.length; i++) ...[
              GestureDetector(
                onTap: () { setState(() => _ri = i); widget.onReciter(i); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: i == _ri ? _kGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: i == _ri ? _kGreen : sub.withValues(alpha: 0.4))),
                  child: Text(_tReciters[i].$2,
                      style: GoogleFonts.outfit(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: i == _ri ? Colors.white : sub)),
                ),
              ),
              if (i < _tReciters.length - 1) const SizedBox(width: 8),
            ],
          ]),

          sHead('DISPLAY', Icons.text_fields_rounded),
          sw('Show Arabic Text', _arabic, (v) {
            setState(() => _arabic = v); widget.onArabic(v);
          }),
          const SizedBox(height: 8),
          sw('Dark Mode', _dark, (v) {
            setState(() => _dark = v); widget.onDarkMode(v);
          }),

          sHead('FONT SIZE', Icons.format_size_rounded),
          Row(children: [
            Text('A', style: GoogleFonts.outfit(fontSize: 14, color: sub)),
            Expanded(child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _kGreen,
                inactiveTrackColor: _kGreen.withValues(alpha: 0.2),
                thumbColor: _kGreen,
              ),
              child: Slider(
                value: _fs, min: 16, max: 32,
                onChanged: (v) { setState(() => _fs = v); widget.onFontSize(v); }),
            )),
            Text('A', style: GoogleFonts.outfit(fontSize: 22, color: sub)),
          ]),
        ]),
      );  // end Container
      },  // end builder
    );  // end DraggableScrollableSheet
  }
}
