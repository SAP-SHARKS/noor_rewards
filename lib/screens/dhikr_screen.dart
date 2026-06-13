import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:just_audio/just_audio.dart';
import '../services/xp_service.dart';
import '../services/streak_service.dart';
import '../services/live_notification_service.dart';
import '../services/settings_service.dart';
import '../widgets/noor_icons.dart';
import '../widgets/sabiq_coin.dart';
import '../widgets/noor_offline.dart';
import '../widgets/dhikr_exit_celebration.dart';
import '../theme/y4_theme.dart';
import '../services/stats_service.dart';
import 'akhirah_balance_screen.dart';
import 'quran_screen.dart';

// ── Arabic font options (shared with Quran screen) ────────────────────────────
typedef _ArabicFont =
    ({
      String name,
      String arabicPreview,
      TextStyle Function(
        double size,
        Color color,
        double height,
        FontWeight weight,
      )
      style,
    });

final List<_ArabicFont> _kArabicFonts = [
  (
    name: 'Uthmani',
    arabicPreview: 'بِسْمِ ٱللَّهِ',
    style:
        (size, color, height, weight) => GoogleFonts.scheherazadeNew(
          fontSize: size,
          color: color,
          height: height,
          fontWeight: weight,
        ),
  ),
  (
    name: 'Indo pak',
    arabicPreview: 'بِسۡمِ اللهِ',
    style:
        (size, color, height, weight) => TextStyle(
          fontFamily: 'AlQalamQuran',
          fontFamilyFallback: const ['ScheherazadeNew', 'Noto Naskh Arabic'],
          fontSize: size + 6,
          color: color,
          height: height,
          fontWeight: FontWeight.normal,
        ),
  ),
  (
    name: 'Madina',
    arabicPreview: 'بِسْمِ ٱللَّهِ',
    style:
        (size, color, height, weight) => GoogleFonts.notoNaskhArabic(
          fontSize: size,
          color: color,
          height: height,
          fontWeight: weight,
        ),
  ),
];

// ── Models ────────────────────────────────────────────────────────────────────
class _Phrase {
  final String arabic;
  final String transliteration;
  final String translation;
  final int count;
  const _Phrase({
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.count,
  });
  factory _Phrase.fromJson(Map<String, dynamic> j) => _Phrase(
        arabic: j['arabic'] as String? ?? '',
        transliteration: j['transliteration'] as String? ?? '',
        translation: j['translation'] as String? ?? '',
        count: (j['count'] as num?)?.toInt() ?? 1,
      );
}

class _PhraseSlice {
  final _Phrase phrase;
  final int index; // 0-based phrase index
  final int countInPhrase; // taps completed within this phrase
  const _PhraseSlice(this.phrase, this.index, this.countInPhrase);
}

class _Azkar {
  final String id;
  final String arabic;
  final String transliteration;
  final String translation;
  final int recommendedCount;
  final String category;
  final String reward;
  final String reference;
  final String hadithFull;
  final String? audioUrl; // For online MP3 playback
  final int sortOrder;
  /// Human-readable name pulled from `azkar_items.title` (e.g. "Ayatul Kursi",
  /// "Surah Al-Mulk", "Dua Qunoot", "Prior to Sleeping 1"). Used as the
  /// primary line in the list view so users can recognize the azkar by name
  /// rather than by its opening transliteration (which is often "Bismillah
  /// hir Rahmaan ir Raheem..." — identical for many surahs).
  final String title;
  /// Optional segmented-counter structure. Non-null for compound dhikr
  /// (e.g. Tasbih Fatima 33+33+34). Each phrase is its own count, but
  /// the overall counter still goes 0..sum(phrase.count).
  final List<_Phrase>? phrases;
  /// Optional Quran chapter number (1-114). When non-null, the card renders
  /// an "Open in Quran Reader" button that deep-links into QuranScreen for
  /// rows where the actual content is a full Surah (e.g. Sleep #19/#20).
  final int? quranSurah;

  const _Azkar({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.recommendedCount,
    required this.category,
    required this.reward,
    required this.reference,
    this.hadithFull = '',
    this.audioUrl,
    this.sortOrder = 0,
    this.title = '',
    this.phrases,
    this.quranSurah,
  });

  factory _Azkar.fromJson(Map<String, dynamic> j) => _Azkar(
    id: j['id'] as String? ?? '',
    arabic: j['arabic'] as String? ?? '',
    transliteration: j['transliteration'] as String? ?? '',
    translation: j['translation'] as String? ?? '',
    recommendedCount: j['recommended_count'] as int? ?? 1,
    category:
        j['category_id'] as String? ?? j['category']?.toString() ?? 'general',
    reward: j['reward'] as String? ?? '',
    reference: j['reference'] as String? ?? '',
    hadithFull: j['hadith_full'] as String? ?? '',
    audioUrl: j['audio_url'] as String?,
    sortOrder: j['sort_order'] as int? ?? 0,
    title: (j['title'] as String?)?.trim() ?? '',
    phrases: (j['phrases'] as List?)
        ?.map((e) => _Phrase.fromJson(e as Map<String, dynamic>))
        .toList(),
    quranSurah: (j['quran_surah'] as num?)?.toInt(),
  );

  /// Returns which phrase is active for [tapCount] taps. Null when this
  /// azkar isn't segmented.
  _PhraseSlice? phraseAt(int tapCount) {
    final ps = phrases;
    if (ps == null || ps.isEmpty) return null;
    int remaining = tapCount.clamp(0, 1 << 30);
    for (int i = 0; i < ps.length; i++) {
      final p = ps[i];
      if (remaining < p.count) {
        return _PhraseSlice(p, i, remaining);
      }
      remaining -= p.count;
    }
    // Tap count is past the last segment — pin to final phrase, full count.
    return _PhraseSlice(ps.last, ps.length - 1, ps.last.count);
  }
}

class _Category {
  final String id;
  final String label;
  final IconData icon;
  const _Category(this.id, this.label, this.icon);
}

// Translates a category by its stable id (favorites / morning / evening / etc.).
// Falls back to the original English label so unmapped admin-added categories
// still render.
String _localCategoryName(BuildContext context, String id, String label) {
  final l = AppLocalizations.of(context);
  if (l == null) return label;
  switch (id) {
    case 'favorites':
      return l.favoritesCategory;
    case 'general':
      return l.dhikarAllTimes;
    case 'morning':
      return l.morning;
    case 'evening':
      return l.evening;
    case 'sleeping':
      return l.sleepingCategory;
    case 'ummah':
      return l.duasOfUmmah;
    case 'duas_before_sleep':
      return l.duasBeforeSleep;
    case 'tahajjud':
      return l.tahajjud;
    case 'duas_after_salah':
      return l.duasAfterSalah;
    case 'salawat':
      return l.salawat;
    case 'sunnah':
      return l.sunnahDuas;
    case 'rabbana_40':
      return l.rabbana40Duas;
    case 'istighfar':
      return l.istighfar;
    case 'daily_duas':
      return l.dailyDuasCategory;
    case 'ruquiya':
      return l.ruquiyaCategory;
    case 'asmaul_husna':
      return l.namesOfAllah;
    case 'nightmares':
      return l.nightmares;
    case 'waking_up':
      return l.wakingUp;
    case 'clothes':
      return l.clothes;
    case 'wudu':
      return l.wudu;
    case 'food_drink':
      return l.foodAndDrink;
    case 'home':
      return l.home;
    case 'istikharah':
      return l.istikharah;
    case 'masjid':
      return l.adaanAndMasjid;
    case 'difficulty':
      return l.diffAndHappy;
    case 'iman_protection':
      return l.imanProtect;
    case 'travel':
      return l.travel;
    case 'shopping':
      return l.shopping;
    case 'family':
      return l.marriage;
    case 'social':
      return l.social;
    case 'nature':
      return l.nature;
    case 'death':
      return l.death;
    case 'gatherings':
      return l.gatherings;
    case 'hajj':
      return l.hajjAndUmrah;
    default:
      return label;
  }
}

class _DhikrSettings {
  double arabicFontSize = 32.0;
  double translationFontSize = 17.0;
  bool darkMode = false;
  int arabicFontIdx = 0; // index into _kArabicFonts
  bool showTranslation = true;
  bool showTransliteration = false;
  bool showIllustration = true; // show/hide the illustration area
  // When true, the illustration pins to the top while Arabic + transliteration
  // + translation scroll beneath it. Lets the user keep the visual focus
  // anchored (good for tapping/finishing zikar) without losing access to the
  // text below. Independent of showIllustration: this only matters when the
  // illustration is shown at all.
  bool freeIllustration = false;
}

IconData _parseIcon(String name) {
  switch (name) {
    case 'auto_awesome_rounded':
      return Icons.nights_stay_rounded;
    case 'wb_sunny_rounded':
      return Icons.wb_sunny_rounded;
    case 'nights_stay_rounded':
      return Icons.nights_stay_rounded;
    case 'mosque_rounded':
      return Icons.mosque_rounded;
    case 'bedtime_rounded':
      return Icons.bedtime_rounded;
    case 'shield_rounded':
      return Icons.shield_rounded;
    default:
      return Icons.bookmark_rounded;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class DhikrScreen extends StatefulWidget {
  final String initialCategory;
  const DhikrScreen({super.key, this.initialCategory = 'general'});
  @override
  State<DhikrScreen> createState() => _DhikrScreenState();
}

class _DhikrScreenState extends State<DhikrScreen> {
  // ── State ─────────────────────────────────────────────────────────────────
  List<_Azkar> _allAzkar = [];
  List<_Azkar> _filtered = [];
  List<_Category> _categories = [];
  late String _selectedCat;

  // ── Tag-based categorization (many-to-many from azkar_item_categories) ──
  // azkar_id → list of category_ids. Empty for any azkar that wasn't tagged
  // in the new junction table; for those we fall back to a.category.
  final Map<String, List<String>> _categoriesByAzkar = {};
  // ── Animation pool per azkar (from azkar_item_animations) ───────────────
  // azkar_id → list of animation `key`s. Empty means fall back to the
  // hard-coded _pickIllustration mapping. The screen picks today's
  // animation as pool[dayOfYear % pool.length] for deterministic rotation.
  final Map<String, List<String>> _animationsByAzkar = {};

  final Map<String, int> _counts = {};
  final Map<String, int> _customTargets = {};
  final Set<String> _completedIds = {}; // persists across count resets
  List<String> _favorites = [];
  int _pointsToday = 0;
  int _setsCompleted = 0;
  bool _loading = true;
  // When the user landed on this category screen — used to compute how
  // many seconds they spent here so the hub can sum across categories
  // and surface a "Time spent today" stat on the Akhirah summary.
  final DateTime _sessionStartTs = DateTime.now();

  // ── Progress persistence helpers ──────────────────────────────────────────
  // Key: dhikr_progress_{category}_{YYYY-MM-DD}
  // Separate key per category so morning/evening never overlap.
  // Auto-expires at midnight — next day the key doesn't exist and we start fresh.
  String _progressKey(String cat) {
    final today = DateTime.now();
    final d =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return 'dhikr_progress_${cat}_$d';
  }

  /// Persist current counts + completedIds to disk.
  /// Call fire-and-forget (no await) so the UI never blocks.
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _progressKey(_selectedCat);
      final data = jsonEncode({
        'counts': _counts,
        'completed': _completedIds.toList(),
      });
      await prefs.setString(key, data);
    } catch (_) {} // never crash on save failure
  }

  /// Load today's progress for [cat]. Clears stale keys from previous days.
  Future<void> _loadProgress(SharedPreferences prefs, String cat) async {
    final key = _progressKey(cat);
    final raw = prefs.getString(key);
    if (raw == null) return; // no data today — fresh session
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final counts = (data['counts'] as Map<String, dynamic>?) ?? {};
      final completed = (data['completed'] as List<dynamic>?) ?? [];
      for (final e in counts.entries) {
        _counts[e.key] = (e.value as num).toInt();
      }
      for (final id in completed) {
        _completedIds.add(id as String);
      }
    } catch (_) {
      // Corrupted data — silently discard
      await prefs.remove(key);
    }
  }

  final _supabase = Supabase.instance.client;

  // Settings
  final _DhikrSettings _settings = _DhikrSettings();
  bool _isFirstTime = false;
  late ConfettiController _confettiController;

  // ── Smart notification queue ────────────────────────────────────────
  // Completions queued during a short session (< 4 pages or < 60s).
  // Shown as one aggregate dialog when the user returns to the list.
  final List<({String id, int target})> _pendingCompletions = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _selectedCat = widget.initialCategory;
    _initData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    // Check for incomplete session and schedule a nudge notification
    _scheduleResumeNotificationIfNeeded();
    super.dispose();
  }

  /// Schedules a local notification 30 min from now if the user left mid-session.
  /// "Mid-session" = at least one azkar tapped but the set is not 100% complete.
  void _scheduleResumeNotificationIfNeeded() {
    // Only nudge for meaningful categories
    if (_selectedCat == 'all' || _selectedCat == 'favorites') return;
    // Has the user tapped anything?
    final anyTapped = _counts.values.any((c) => c > 0);
    if (!anyTapped) return;
    // Is there still something left to do?
    final allDone = _filtered.every((a) {
      final target = _getTarget(a.id, a.recommendedCount);
      final count = _counts[a.id] ?? 0;
      return count >= target || _completedIds.contains(a.id);
    });
    if (allDone) return; // nothing to remind about
    // Schedule the nudge
    _scheduleResumeNotification(_selectedCat);
  }

  static Future<void> _scheduleResumeNotification(String category) async {
    // Store the incomplete-session flag so we can show an in-app nudge on next open.
    // A separate FCM reminder is handled server-side via pg_cron (existing pipeline).
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dhikr_incomplete_cat', category);
      await prefs.setString(
        'dhikr_incomplete_ts',
        DateTime.now().toIso8601String(),
      );
    } catch (_) {}
  }

  /// Show in-app nudge if the user had an incomplete session last time.
  Future<void> _checkAndShowResumeNudge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final incompleteCat = prefs.getString('dhikr_incomplete_cat');
      if (incompleteCat == null || !mounted) return;
      // Clear the flag immediately so it only shows once
      await prefs.remove('dhikr_incomplete_cat');
      await prefs.remove('dhikr_incomplete_ts');
      // Only nudge if the same category they left is what they opened now
      if (incompleteCat != _selectedCat) return;
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      final catLabel =
          incompleteCat == 'morning'
              ? (l?.morning ?? 'Morning')
              : incompleteCat == 'evening'
              ? (l?.evening ?? 'Evening')
              : incompleteCat == 'sleeping'
              ? (l?.sleepingCategory ?? 'Sleeping')
              : (l?.dailyWord ?? 'Daily');
      // Small delay so the list finishes loading first
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🌟', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Continue your $catLabel Adhkar from where you left off.',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFFC83D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {}
  }

  Future<void> _initData() async {
    await _loadPrefs();
    await _loadDBData();
    // Show resume nudge if user left an incomplete session last time
    _checkAndShowResumeNudge();
    if (_isFirstTime && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSettingsSheet();
      });
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _settings.arabicFontSize = prefs.getDouble('dhikr_ar_size') ?? 32.0;
      _settings.translationFontSize = prefs.getDouble('dhikr_tr_size') ?? 17.0;
      _settings.darkMode = prefs.getBool('dhikr_dark_mode') ?? false;
      _settings.showTranslation =
          prefs.getBool('dhikr_show_translation_v2') ?? true;
      _settings.showTransliteration =
          prefs.getBool('dhikr_show_transliteration') ?? false;
      _settings.showIllustration =
          prefs.getBool('dhikr_show_illustration') ?? true;
      _settings.freeIllustration =
          prefs.getBool('dhikr_free_illustration') ?? false;
      int loadFontIdx = prefs.getInt('dhikr_ar_font') ?? 0;
      if (loadFontIdx >= _kArabicFonts.length) loadFontIdx = 0;
      _settings.arabicFontIdx = loadFontIdx;
      _isFirstTime = prefs.getBool('dhikr_first_time') ?? true;
      _favorites = prefs.getStringList('dhikr_favorites') ?? [];
      // Load custom targets
      final targetKeys = prefs.getStringList('dhikr_custom_target_keys') ?? [];
      for (final key in targetKeys) {
        final val = prefs.getInt('dhikr_target_$key');
        if (val != null) _customTargets[key] = val;
      }
    });
    // Restore today's tapping progress (separate per category, resets each new day)
    await _loadProgress(prefs, _selectedCat);
    if (_isFirstTime) {
      await prefs.setBool('dhikr_first_time', false);
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('dhikr_ar_size', _settings.arabicFontSize);
    await prefs.setDouble('dhikr_tr_size', _settings.translationFontSize);
    await prefs.setBool('dhikr_dark_mode', _settings.darkMode);
    await prefs.setBool('dhikr_show_translation_v2', _settings.showTranslation);
    await prefs.setBool(
      'dhikr_show_transliteration',
      _settings.showTransliteration,
    );
    await prefs.setBool('dhikr_show_illustration', _settings.showIllustration);
    await prefs.setBool(
      'dhikr_free_illustration',
      _settings.freeIllustration,
    );
    await prefs.setInt('dhikr_ar_font', _settings.arabicFontIdx);
  }

  /// Returns custom target if set, otherwise the recommended count.
  int _getTarget(String id, int recommendedCount) {
    return _customTargets[id] ?? recommendedCount;
  }

  Future<void> _saveCustomTarget(String id, int target) async {
    setState(() {
      _customTargets[id] = target;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'dhikr_custom_target_keys',
      _customTargets.keys.toList(),
    );
    await prefs.setInt('dhikr_target_$id', target);
  }

  Future<void> _clearCustomTarget(String id) async {
    setState(() {
      _customTargets.remove(id);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'dhikr_custom_target_keys',
      _customTargets.keys.toList(),
    );
    await prefs.remove('dhikr_target_$id');
  }

  void _showTargetPicker(
    BuildContext context,
    String azkarId,
    int recommendedCount,
  ) {
    final isDark = _settings.darkMode;
    final currentTarget = _getTarget(azkarId, recommendedCount);
    final controller = TextEditingController(text: currentTarget.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Set Your Target',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark
                            ? Colors.white
                            : SettingsService.instance.config.dashText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Default: $recommendedCount',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color:
                        isDark ? Colors.grey.shade400 : const Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 20),
                // Quick presets
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: () {
                    final presets =
                        <int>{recommendedCount, 3, 7, 10, 33, 100}.toList()
                          ..sort();
                    return presets.map<Widget>((v) {
                      final isSelected = controller.text == v.toString();
                      return GestureDetector(
                        onTap: () {
                          controller.text = v.toString();
                          (ctx as Element).markNeedsBuild();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? const Color(
                                      0xFFFFC83D,
                                    ).withValues(alpha: 0.15)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : const Color(0xFFF2F2F7)),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                isSelected
                                    ? Border.all(
                                      color: const Color(0xFFFFC83D),
                                      width: 1.5,
                                    )
                                    : null,
                          ),
                          child: Text(
                            '$v×',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected
                                      ? const Color(0xFFFFC83D)
                                      : (isDark
                                          ? Colors.white70
                                          : SettingsService
                                              .instance
                                              .config
                                              .dashText),
                            ),
                          ),
                        ),
                      );
                    }).toList();
                  }(),
                ),
                const SizedBox(height: 16),
                // Custom input
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark
                            ? Colors.white
                            : SettingsService.instance.config.dashText,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        AppLocalizations.of(context)?.enterCustomCount ??
                        'Enter custom count',
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 15,
                      color:
                          isDark
                              ? Colors.grey.shade600
                              : const Color(0xFFAEAEB2),
                    ),
                    filled: true,
                    fillColor:
                        isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Buttons row
                Row(
                  children: [
                    // Reset to default
                    if (_customTargets.containsKey(azkarId))
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            _clearCustomTarget(azkarId);
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            AppLocalizations.of(context)?.resetToDefault ??
                                'Reset to default',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE11D48),
                            ),
                          ),
                        ),
                      ),
                    if (_customTargets.containsKey(azkarId))
                      const SizedBox(width: 8),
                    // Save
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final val = int.tryParse(controller.text);
                          if (val != null && val > 0) {
                            if (val == recommendedCount) {
                              _clearCustomTarget(azkarId);
                            } else {
                              _saveCustomTarget(azkarId, val);
                            }
                          }
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC83D),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Load Supabase Data ─────────────────────────────────────────────────────
  Future<void> _loadDBData() async {
    try {
      // 4 independent SELECTs in parallel — categories, items, the new
      // tag-junction, and the animation-pool junction. Network round-trips
      // happen concurrently so total load = max of the four.
      final results = await Future.wait<List<dynamic>>([
        _supabase
            .from('azkar_categories')
            .select()
            .order('sort_order')
            .then<List<dynamic>>((v) => v as List)
            .catchError((_) => const <dynamic>[]),
        _supabase
            .from('azkar_items')
            .select()
            .order('sort_order')
            .then<List<dynamic>>((v) => v as List)
            .catchError((_) => const <dynamic>[]),
        // azkar_item_categories — many-to-many tags
        _supabase
            .from('azkar_item_categories')
            .select('azkar_id, category_id')
            .then<List<dynamic>>((v) => v as List)
            .catchError((_) => const <dynamic>[]),
        // azkar_item_animations joined with key for direct switch use
        _supabase
            .from('azkar_item_animations')
            .select('azkar_id, sort_order, azkar_animations(key, is_active)')
            .order('sort_order')
            .then<List<dynamic>>((v) => v as List)
            .catchError((_) => const <dynamic>[]),
      ]);

      // Build category-tags map
      _categoriesByAzkar.clear();
      for (final row in results[2]) {
        final aid = row['azkar_id'] as String?;
        final cid = row['category_id'] as String?;
        if (aid == null || cid == null) continue;
        (_categoriesByAzkar[aid] ??= <String>[]).add(cid);
      }

      // Build animation-pool map (preserves sort order)
      _animationsByAzkar.clear();
      for (final row in results[3]) {
        final aid = row['azkar_id'] as String?;
        final anim = row['azkar_animations'] as Map<String, dynamic>?;
        if (aid == null || anim == null) continue;
        if (anim['is_active'] == false) continue;
        final key = anim['key'] as String?;
        if (key == null) continue;
        (_animationsByAzkar[aid] ??= <String>[]).add(key);
      }

      final fetchedCats = results[0]
          .where((c) => c['is_visible'] != false)
          .map(
            (c) => _Category(
              c['id'] as String,
              c['label'] as String,
              _parseIcon(c['icon_name'] as String),
            ),
          )
          .toList();

      final fetchedItems =
          results[1].map((i) => _Azkar.fromJson(i)).toList();

      if (fetchedCats.isNotEmpty && fetchedItems.isNotEmpty) {
        _categories = fetchedCats;
        // "All" tab intentionally omitted — it would surface duplicates
        // because Morning and Evening overlap heavily. Users browse by
        // specific category (Morning / Evening / etc.) or by Favorites.
        _categories.insert(
          0,
          const _Category('favorites', 'Favorites', Icons.favorite_rounded),
        );
        _allAzkar = fetchedItems;
      } else {
        await _loadLocalFallback();
      }
    } catch (e) {
      debugPrint('Supabase Azkar fetch error: $e');
      await _loadLocalFallback();
    }

    if (mounted) {
      setState(() {
        if (_categories.isEmpty) {
          // "All" intentionally omitted — duplicates morning + evening.
          _categories = const [
            _Category('favorites', 'Favorites', Icons.favorite_rounded),
            _Category('general', 'General', Icons.nights_stay_rounded),
            _Category('morning', 'Morning', Icons.wb_sunny_rounded),
            _Category('evening', 'Evening', Icons.nights_stay_rounded),
          ];
        }
        _applyFilter();
        _loading = false;
      });
    }
  }

  Future<void> _loadLocalFallback() async {
    final raw = await rootBundle.loadString('assets/data/azkar.json');
    final list =
        (jsonDecode(raw) as List)
            .map((e) => _Azkar.fromJson(e as Map<String, dynamic>))
            .toList();
    _allAzkar = list;
  }

  void _applyFilter() {
    setState(() {
      if (_selectedCat == 'all') {
        _filtered = List.from(_allAzkar);
      } else if (_selectedCat == 'favorites') {
        _filtered = _allAzkar.where((a) => _favorites.contains(a.id)).toList();
      } else {
        // Prefer the many-to-many tag junction (an azkar can be tagged
        // with multiple categories). Falls back to the legacy single
        // `a.category` column when the junction is empty for this azkar.
        _filtered = _allAzkar.where((a) {
          final tags = _categoriesByAzkar[a.id];
          if (tags != null && tags.isNotEmpty) {
            return tags.contains(_selectedCat);
          }
          return a.category == _selectedCat;
        }).toList();
      }
      _filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    });
  }

  /// Returns the animation `key` that should drive today's illustration for
  /// this azkar. Picks deterministically from the pool by day-of-year so
  /// users see the same animation all day but a different one each day.
  /// Returns null if the azkar has no DB-mapped animations (caller falls
  /// back to the hardcoded `_pickIllustration`).
  String? _todayAnimationKeyFor(String azkarId) {
    final pool = _animationsByAzkar[azkarId];
    if (pool == null || pool.isEmpty) return null;
    final now = DateTime.now();
    final dayOfYear = int.parse(
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}',
    );
    return pool[dayOfYear % pool.length];
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _toggleFavorite(String id) async {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
      if (_selectedCat == 'favorites') {
        _applyFilter();
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dhikr_favorites', _favorites);
  }

  void _shareAzkar(_Azkar azkar) {
    HapticFeedback.lightImpact();
    final text =
        '${azkar.arabic}\n\n${azkar.transliteration}\n\n"${azkar.translation}"\n\n, Shared via Sabiq Rewards';
    // ignore: deprecated_member_use
    Share.share(text);
  }

  // ── _tap (does NOT show dialog — detail screen owns that logic) ──────────────
  // Returns true if the tap caused the azkar to complete.
  bool _tap(String id, int target) {
    HapticFeedback.lightImpact();
    bool justCompleted = false;
    setState(() {
      final current = _counts[id] ?? 0;
      if (current < target) {
        _counts[id] = current + 1;
        if (_counts[id] == target) {
          justCompleted = true;
        }
      }
    });
    // Persist after every tap — fire and forget
    _saveProgress();
    return justCompleted;
  }

  // Shows all queued pending completions as one aggregate "MashAllah" notification.
  // Called by _DhikrDetailScreen when the user pops back after a short session.
  void _showPendingCompletions() {
    if (_pendingCompletions.isEmpty || !mounted) return;
    final count = _pendingCompletions.length;
    final totalPts = _pendingCompletions.fold<int>(
      0,
      (sum, c) => sum + PointReward.dhikr,
    );
    // Drain the queue
    _pendingCompletions.clear();
    // Small delay so the navigation animation completes first
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _showCelebrationDialog(
        context: context,
        isDark: _settings.darkMode,
        setsCount: count,
        pts: totalPts,
      );
    });
  }

  void _reset(String id) {
    setState(() {
      _counts[id] = 0;
    });
  }

  // ── Exit handler ──────────────────────────────────────────────────────────
  // When the user exits this single-category screen, pop silently with the
  // session stats. The Dhikr Hub above us accumulates stats across multiple
  // category visits and fires the Alhamdulillah celebration + Akhirah
  // Balance summary only when the user finally exits the hub (i.e. truly
  // leaves Dua & Zikar), so jumping between categories no longer triggers
  // a premature "you're done" moment.
  bool _isExiting = false;
  Future<void> _handleExitDhikr() async {
    if (_isExiting) return;
    _isExiting = true;
    if (!mounted) return;
    final elapsed =
        DateTime.now().difference(_sessionStartTs).inSeconds.clamp(0, 1 << 30);
    Navigator.pop(context, <String, int>{
      'points': _pointsToday,
      'sets': _setsCompleted,
      'seconds': elapsed,
    });
  }

  Future<void> _completeDhikr(String dhikrId, int target) async {
    try {
      final coins = SettingsService.instance.config.coinsPerDhikr;
      await Supabase.instance.client.rpc(
        'earn_dhikr_points',
        params: {'p_type': dhikrId, 'p_count': target, 'p_coins': coins},
      );

      // Single points path — coins are the points
      await XpService.instance.earnPoints(coins);
      // Update live notification counter
      NoorLiveNotificationService.instance.recordDhikr();
      // Record dhikr streak (idempotent — safe to call multiple times)
      StreakService.instance.recordActivity(StreakType.dhikr);
      // Record stats for monthly tracking
      StatsService.instance.recordDhikrActivity(count: target);
      // Record per-phrase lifetime count so Akhirah holdings
      // (Treasures of Jannah, Slaves Freed, etc.) can be derived
      // from the actual phrases recited.
      StatsService.instance.recordDhikrPhrase(dhikrId, count: target);
      if (_setsCompleted == 0)
        await XpService.instance.awardBadge('first_dhikr');
      if (_setsCompleted + 1 >= 7)
        await XpService.instance.awardBadge('night_warrior');

      final isDailyGoal = await XpService.instance.claimDailyDhikrGoal();
      if (isDailyGoal && mounted) {
        _confettiController.play();
        _showDailyGoalModal();
      }
      // If already claimed today, just proceed silently — no error shown

      setState(() {
        _pointsToday += coins;
        if (isDailyGoal) _pointsToday += 50;
        _setsCompleted += 1;
        _completedIds.add(dhikrId);
        _counts[dhikrId] = 0;
      });
      // Persist the updated completion state
      _saveProgress();
    } catch (_) {
      // Silent — never show raw DB errors to user
    }
  }

  void _showCompleteDialog(String dhikrId, int target, {int pagesCount = 1}) {
    final ptsEarned = PointReward.dhikr * pagesCount;
    _showCelebrationDialog(
      context: context,
      isDark: _settings.darkMode,
      setsCount: pagesCount,
      pts: ptsEarned,
      countsLabel: pagesCount == 1 ? '$target counts' : null,
    );
  }

  /// Premium celebration dialog shared by all completion flows
  static void _showCelebrationDialog({
    required BuildContext context,
    required bool isDark,
    required int setsCount,
    required int pts,
    String? countsLabel,
  }) {
    final kText =
        isDark ? Colors.white : SettingsService.instance.config.dashText;
    final kBg = isDark ? const Color(0xFF1A1A1E) : Colors.white;
    final kTeal = const Color(0xFFFFC83D);
    const kGold = Color(0xFFD4AF37);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 36),
            child: Container(
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: kTeal.withValues(alpha: isDark ? 0.15 : 0.10),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Top accent bar ──
                  Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 60),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [kTeal, kGold, kTeal]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Icon cluster ──
                        SizedBox(
                          height: 64,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Soft glow behind
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      kTeal.withValues(alpha: 0.12),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              NoorIcon.party(size: 48),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Title ──
                        Text(
                          'مَاشَاءَ الله',
                          style: GoogleFonts.amiri(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: kText,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Stats row ──
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : const Color(0xFFF7F7F8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Sets / counts
                              _statChip(
                                icon: Icons.check_circle_rounded,
                                value:
                                    countsLabel ??
                                    '$setsCount ${setsCount == 1 ? "set" : "sets"}',
                                color: kTeal,
                                isDark: isDark,
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color:
                                    isDark
                                        ? Colors.white12
                                        : const Color(0xFFE5E7EB),
                              ),
                              // Seeds earned
                              _statChip(
                                icon: Icons.auto_awesome_rounded,
                                iconWidget: const SabiqCoin(size: 18),
                                value: '+$pts',
                                label: AppLocalizations.of(context)?.seedsUnit ?? 'Seeds',
                                color: kGold,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ── CTA Button ──
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'الحَمْدُ لله',
                              style: GoogleFonts.amiri(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  static Widget _statChip({
    required IconData icon,
    required String value,
    String? label,
    required Color color,
    required bool isDark,
    Widget? iconWidget,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget ?? Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color:
                isDark
                    ? Colors.white
                    : SettingsService.instance.config.dashText,
          ),
        ),
        if (label != null)
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF),
            ),
          ),
      ],
    );
  }

  void _showSettingsSheet([
    BuildContext? sheetContext,
    VoidCallback? onUpdate,
  ]) {
    showModalBottomSheet(
      context: sheetContext ?? context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setModalState) {
              final isDark = _settings.darkMode;
              final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
              final txtColor =
                  isDark
                      ? Colors.white
                      : SettingsService.instance.config.dashText;

              return DraggableScrollableSheet(
                initialChildSize: 0.75,
                minChildSize: 0.4,
                maxChildSize: 0.95,
                expand: false,
                builder:
                    (_, scrollCtrl) => Container(
                      decoration: BoxDecoration(
                        color: sheetBg,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          // ── Drag handle ──────────────────────────────────────────────
                          const SizedBox(height: 10),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // ── Title row ───────────────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.duaAzkarSettings ??
                                        'Dua & Azkar Settings',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: txtColor,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: txtColor,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                          // ── Scrollable content ───────────────────────────────────────
                          Expanded(
                            child: ListView(
                              controller: scrollCtrl,
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                              children: [
                                // Appearance
                                Text(
                                  'Appearance',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFFC83D),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Dark Mode',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      color: txtColor,
                                    ),
                                  ),
                                  activeColor: Colors.white,
                                  activeTrackColor: const Color(0xFFFFC83D),
                                  value: _settings.darkMode,
                                  onChanged: (val) {
                                    setModalState(
                                      () => _settings.darkMode = val,
                                    );
                                    setState(() => _settings.darkMode = val);
                                    onUpdate?.call();
                                    _savePrefs();
                                  },
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Show Translation',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      color: txtColor,
                                    ),
                                  ),
                                  activeColor: Colors.white,
                                  activeTrackColor: const Color(0xFFFFC83D),
                                  value: _settings.showTranslation,
                                  onChanged: (val) {
                                    setModalState(
                                      () => _settings.showTranslation = val,
                                    );
                                    setState(
                                      () => _settings.showTranslation = val,
                                    );
                                    onUpdate?.call();
                                    _savePrefs();
                                  },
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.showTransliteration ??
                                        'Show Transliteration',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      color: txtColor,
                                    ),
                                  ),
                                  activeColor: Colors.white,
                                  activeTrackColor: const Color(0xFFFFC83D),
                                  value: _settings.showTransliteration,
                                  onChanged: (val) {
                                    setModalState(
                                      () => _settings.showTransliteration = val,
                                    );
                                    setState(
                                      () => _settings.showTransliteration = val,
                                    );
                                    onUpdate?.call();
                                    _savePrefs();
                                  },
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.showIllustration ??
                                        'Show Illustration',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      color: txtColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.hideIllustrationArea ??
                                        'Hide the visual artwork area',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: txtColor.withValues(alpha: 0.55),
                                    ),
                                  ),
                                  activeColor: Colors.white,
                                  activeTrackColor: const Color(0xFFFFC83D),
                                  value: _settings.showIllustration,
                                  onChanged: (val) {
                                    setModalState(
                                      () => _settings.showIllustration = val,
                                    );
                                    setState(
                                      () => _settings.showIllustration = val,
                                    );
                                    onUpdate?.call();
                                    _savePrefs();
                                  },
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Freeze Illustration',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      color: txtColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Pin the illustration at the top while the Arabic text scrolls beneath it',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: txtColor.withValues(alpha: 0.55),
                                    ),
                                  ),
                                  activeColor: Colors.white,
                                  activeTrackColor: const Color(0xFFFFC83D),
                                  value: _settings.freeIllustration,
                                  onChanged: _settings.showIllustration
                                      ? (val) {
                                          setModalState(
                                            () => _settings.freeIllustration =
                                                val,
                                          );
                                          setState(
                                            () => _settings.freeIllustration =
                                                val,
                                          );
                                          onUpdate?.call();
                                          _savePrefs();
                                        }
                                      : null,
                                ),
                                const Divider(),

                                // Text Sizes
                                const SizedBox(height: 10),
                                Text(
                                  'Text Size',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFFC83D),
                                  ),
                                ),
                                Slider(
                                  value: _settings.arabicFontSize,
                                  min: 20.0,
                                  max: 56.0,
                                  activeColor: const Color(0xFFFFC83D),
                                  onChanged: (val) {
                                    final translationSize =
                                        16.0 + (val - 20.0) * (12.0 / 36.0);
                                    setModalState(() {
                                      _settings.arabicFontSize = val;
                                      _settings.translationFontSize =
                                          translationSize;
                                    });
                                    setState(() {
                                      _settings.arabicFontSize = val;
                                      _settings.translationFontSize =
                                          translationSize;
                                    });
                                    onUpdate?.call();
                                    _savePrefs();
                                  },
                                ),

                                // ── Arabic Font Style Picker ───────────────────────────
                                const Divider(),
                                const SizedBox(height: 10),
                                Text(
                                  AppLocalizations.of(
                                        context,
                                      )?.arabicFontStyle ??
                                      'Arabic Font Style',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFFC83D),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...List.generate(_kArabicFonts.length, (i) {
                                  final font = _kArabicFonts[i];
                                  final sel = i == _settings.arabicFontIdx;
                                  final accent = const Color(0xFFFFC83D);
                                  return GestureDetector(
                                    onTap: () {
                                      setModalState(
                                        () => _settings.arabicFontIdx = i,
                                      );
                                      setState(
                                        () => _settings.arabicFontIdx = i,
                                      );
                                      onUpdate?.call();
                                      _savePrefs();
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            sel
                                                ? accent.withValues(alpha: 0.10)
                                                : (isDark
                                                    ? const Color(0xFF2C2C2E)
                                                    : const Color(0xFFF3F4F6)),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              sel ? accent : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  font.name,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        sel
                                                            ? accent
                                                            : const Color(
                                                              0xFF8E8E93,
                                                            ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  font.arabicPreview,
                                                  style: font.style(
                                                    22,
                                                    txtColor,
                                                    1.6,
                                                    FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (sel)
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFC83D),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 15,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              );
            },
          ),
    );
  }

  void _showDailyGoalModal() {
    final isDark = _settings.darkMode;
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC83D).withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE0F2FE),
                    ),
                    child: Center(child: NoorIcon.trophy(size: 40)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)?.dailyAzkarComplete ??
                        'Daily Azkar Complete!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color:
                          isDark
                              ? Colors.white
                              : SettingsService.instance.config.dashText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)?.dailyAzkarBonusMsg ??
                        'Masha\'Allah! You tracked your daily Azkar and earned a bonus +50 Sabiq Seeds.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color:
                          isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC83D),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.awesome ?? 'Awesome',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // ── Category timing label ─────────────────────────────────────────────────
  static String _categoryTiming(BuildContext context, String catId) {
    switch (catId) {
      case 'morning':
        return AppLocalizations.of(context)?.betweenSubhSunrise ??
            'Between Subh-e-Sadiq to Sunrise';
      case 'evening':
        return AppLocalizations.of(context)?.betweenAsrMaghrib ??
            'Between Asr and Maghrib';
      case 'sleeping':
        return AppLocalizations.of(context)?.beforeSleeping ??
            'Before Sleeping';
      case 'waking_up':
        return AppLocalizations.of(context)?.uponWakingUp ?? 'Upon Waking Up';
      case 'post_prayer':
        return AppLocalizations.of(context)?.afterEachPrayer ??
            'After Each Prayer';
      case 'salawat':
        return AppLocalizations.of(context)?.anytimeEspeciallyAfterPrayer ??
            'Anytime, Especially After Prayer';
      case 'istighfar':
        return AppLocalizations.of(context)?.anytimeMorningEvening ??
            'Anytime, Morning & Evening';
      case 'tahajjud':
        return AppLocalizations.of(context)?.duringTheNight ??
            'During the Night';
      case 'quranic':
        return AppLocalizations.of(context)?.anytime ?? 'Anytime';
      case 'sunnah':
        return AppLocalizations.of(context)?.asPerSunnah ?? 'As per Sunnah';
      case 'food_drink':
        return AppLocalizations.of(context)?.whenEatingDrinking ??
            'When Eating or Drinking';
      case 'home':
        return AppLocalizations.of(context)?.enteringLeavingHome ??
            'Upon Entering / Leaving Home';
      case 'wudu':
        return AppLocalizations.of(context)?.beforeAfterWudu ??
            'Before or After Wudu';
      case 'clothes':
        return AppLocalizations.of(context)?.whenGettingDressed ??
            'When Getting Dressed';
      case 'nightmares':
        return AppLocalizations.of(context)?.uponBadDream ??
            'Upon Having a Bad Dream';
      case 'ummah':
        return AppLocalizations.of(context)?.forUmmahAnytime ??
            'For the Ummah, Anytime';
      case 'general':
        return AppLocalizations.of(context)?.anytime ?? 'Anytime';
      default:
        return AppLocalizations.of(context)?.anytime ?? 'Anytime';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF4D2),
        body: const Center(child: NoorInlineLoader()),
      );
    }

    final isDark = _settings.darkMode;
    final kText =
        isDark ? Colors.white : SettingsService.instance.config.dashText;
    final kWhite = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final kBg =
        isDark
            ? const Color(0xFF121212)
            : const Color(0xFFF7F8F9); // Lighter background
    final kSub = isDark ? Colors.grey.shade400 : const Color(0xFF8E8E93);

    // UI Constants — Y4 honey wash banner (matches dashboard hero feel)
    final bannerBg =
        isDark ? const Color(0xFF3D4A1A) : const Color(0xFFFFE89A); // butter
    final bannerBtn =
        isDark
            ? const Color(0xFFFFC83D)
            : const Color(0xFFFFC83D); // honey-deep
    final bannerTxt = isDark ? const Color(0xFF2A2410) : Colors.white;

    final chipInactiveBg =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEEEEEE);
    final chipInactiveTxt = isDark ? Colors.white70 : const Color(0xFF4A4A4A);

    // Category color map — each category gets a distinct accent
    Color catColor(String catId) => switch (catId) {
      'all' => const Color(0xFF6366F1), // indigo
      'favorites' => const Color(0xFFEF4444), // red
      'general' => const Color(0xFFFFC83D), // emerald
      'morning' => const Color(0xFFF59E0B), // amber
      'evening' => const Color(0xFF6366F1), // indigo
      'sleeping' => const Color(0xFF8B5CF6), // violet
      'waking_up' => const Color(0xFFF97316), // orange
      'post_prayer' => const Color(0xFF0EA5E9), // sky blue
      'salawat' => const Color(0xFFFFC83D), // emerald
      'istighfar' => const Color(0xFF8B5CF6), // violet
      'tahajjud' => const Color(0xFF3B82F6), // blue
      'sunnah' => const Color(0xFF14B8A6), // teal
      'quranic' => const Color(0xFFD4AF37), // gold
      'ummah' => const Color(0xFFEC4899), // pink
      'nightmares' => const Color(0xFF6366F1), // indigo
      'clothes' => const Color(0xFF14B8A6), // teal
      'wudu' => const Color(0xFF0EA5E9), // sky blue
      'food_drink' => const Color(0xFFF97316), // orange
      'home' => const Color(0xFFFFC83D), // emerald
      _ => const Color(0xFFFFC83D), // default teal
    };

    // Banner Text Setup
    String bannerTitle = "Daily Remembrance\nbrings peace to the soul.";
    String catLabel = "DAILY REMEMBRANCE";
    IconData waterMark = Icons.spa_rounded;

    if (_selectedCat == 'morning') {
      catLabel = "DAILY REMEMBRANCE";
      bannerTitle =
          "Morning Adhkar\nbrings peace to the soul and light to the path.";
      waterMark = Icons.wb_sunny_rounded;
    } else if (_selectedCat == 'evening') {
      catLabel = "NIGHTLY REMEMBRANCE";
      bannerTitle =
          "Evening Adhkar\nbrings tranquility and protection for the night.";
      waterMark = Icons.nights_stay_rounded;
    } else if (_selectedCat == 'favorites') {
      catLabel = "YOUR SELECTION";
      bannerTitle =
          "Your beloved words\nof remembrance to keep close to your heart.";
      waterMark = Icons.favorite_rounded;
    } else {
      catLabel = "CONTINUOUS REMEMBRANCE";
      bannerTitle = "Remember Allah\nmuch, that you may be successful.";
      waterMark = Icons.grid_view_rounded;
    }

    final scaffold = Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: kText, size: 20),
          onPressed: _handleExitDhikr,
        ),
        title: Text(
          'Dua & Azkar',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: kText,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ── Top Banner ──────────────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: bannerBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: bannerBg.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Watermark icon — honey-deep on light banner, white on dark banner
                      Positioned(
                        right: -30,
                        bottom: -20,
                        child: Icon(
                          waterMark,
                          size: 120,
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : const Color(
                                    0xFFFFC83D,
                                  ).withValues(alpha: 0.18),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            catLabel,
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                              color:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : const Color(0xFF766B47),
                            ),
                          ), // Y4.inkSoft on butter
                          const SizedBox(height: 8),
                          Text(
                            bannerTitle,
                            style: GoogleFonts.lora(
                              fontSize: 18,
                              height: 1.4,
                              color:
                                  isDark
                                      ? Colors.white
                                      : const Color(0xFF2A2410), // Y4.ink
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  if (_filtered.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => _DhikrDetailScreen(
                                              azkars: _filtered,
                                              initialIndex: 0,
                                              counts: _counts,
                                              favorites: _favorites,
                                              settings: _settings,
                                              parentState: this,
                                            ),
                                      ),
                                    ).then((_) {
                                      setState(() {});
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: bannerBtn,
                                  foregroundColor: bannerTxt,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 0,
                                  ),
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)?.startNow ??
                                      'Start Now',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Filter to only azkar that have audio
                                  final withAudio = _filtered
                                      .where((a) =>
                                          a.audioUrl != null &&
                                          a.audioUrl!.isNotEmpty)
                                      .toList();
                                  if (withAudio.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => _DhikrDetailScreen(
                                              azkars: withAudio,
                                              initialIndex: 0,
                                              counts: _counts,
                                              favorites: _favorites,
                                              settings: _settings,
                                              parentState: this,
                                              autoPlayAll: true,
                                            ),
                                      ),
                                    ).then((_) {
                                      setState(() {});
                                    });
                                  }
                                },
                                icon: const Icon(
                                  Icons.play_circle_filled_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  'Play All',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isDark
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : const Color(0xFF2A2410),
                                  foregroundColor:
                                      isDark ? Colors.white : Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 0,
                                  ),
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Category tabs ───────────────────────────────────────────────────
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final sel = cat.id == _selectedCat;
                      final catAccent = catColor(cat.id);
                      return GestureDetector(
                        onTap: () async {
                          setState(() {
                            _selectedCat = cat.id;
                            _applyFilter();
                          });
                          // Load this category's today-progress from disk
                          final prefs = await SharedPreferences.getInstance();
                          if (mounted) await _loadProgress(prefs, cat.id);
                          if (mounted) setState(() {});
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 0,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                sel
                                    ? (isDark
                                        ? catAccent.withValues(alpha: 0.25)
                                        : catAccent)
                                    : chipInactiveBg,
                            borderRadius: BorderRadius.circular(20),
                            border:
                                sel
                                    ? Border.all(
                                      color: catAccent.withValues(
                                        alpha: isDark ? 0.5 : 0.0,
                                      ),
                                      width: 1,
                                    )
                                    : null,
                          ),
                          child: Text(
                            _localCategoryName(context, cat.id, cat.label),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight:
                                  sel ? FontWeight.w600 : FontWeight.w500,
                              color:
                                  sel
                                      ? (isDark ? catAccent : Colors.white)
                                      : chipInactiveTxt,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Beautiful Master List ───────────────────────────────────────────
                const SizedBox(height: 14),
                Expanded(
                  child:
                      _filtered.isEmpty
                          ? Center(
                            child: Text(
                              AppLocalizations.of(context)?.noAzkarFound ??
                                  'No Azkar found here.',
                              style: GoogleFonts.outfit(color: kSub),
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                            itemCount: 1,
                            itemBuilder: (context, _) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: kWhite,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      if (!isDark)
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                    ],
                                  ),
                                  child: Column(
                                    children: List.generate(_filtered.length, (
                                      index,
                                    ) {
                                      final azkar = _filtered[index];
                                      final count = _counts[azkar.id] ?? 0;
                                      final tapTarget = _getTarget(
                                        azkar.id,
                                        azkar.recommendedCount,
                                      );
                                      final isComplete =
                                          count >= tapTarget ||
                                          _completedIds.contains(azkar.id);
                                      final accent = catColor(azkar.category);

                                      String titleText =
                                          (azkar.transliteration.isNotEmpty &&
                                                  azkar.transliteration
                                                          .trim() !=
                                                      '')
                                              ? azkar.transliteration
                                              : azkar.translation;
                                      titleText =
                                          titleText
                                              .replaceAll('\n', ' ')
                                              .trim();

                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => _DhikrDetailScreen(
                                                        azkars: _filtered,
                                                        initialIndex: index,
                                                        counts: _counts,
                                                        favorites: _favorites,
                                                        settings: _settings,
                                                        parentState: this,
                                                      ),
                                                ),
                                              );
                                              setState(() {});
                                            },
                                            behavior: HitTestBehavior.opaque,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 14,
                                                  ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  // Index badge
                                                  Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          isComplete
                                                              ? accent
                                                              : accent.withValues(
                                                                alpha:
                                                                    isDark
                                                                        ? 0.15
                                                                        : 0.10,
                                                              ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child:
                                                        isComplete
                                                            ? Icon(
                                                              Icons
                                                                  .check_rounded,
                                                              color:
                                                                  Colors.white,
                                                              size: 18,
                                                            )
                                                            : Text(
                                                              '${index + 1}',
                                                              style: GoogleFonts.outfit(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                fontSize: 14,
                                                                color: accent
                                                                    .withValues(
                                                                      alpha:
                                                                          isDark
                                                                              ? 0.90
                                                                              : 0.80,
                                                                    ),
                                                              ),
                                                            ),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  // Text column: first line = transliteration snippet, second = reference/timing
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        // ── Line 1 (bold): the azkar's name ──
                                                        // Resolution order:
                                                        //   1) DB title ONLY if it looks like a real
                                                        //      dua/surah name ("Surah Al-Mulk",
                                                        //      "Ayatul Kursi"). For Daily Duas the
                                                        //      title is a context label ("Upon Going
                                                        //      to Sleep") which the user doesn't want
                                                        //      shown here — they expect the dua's
                                                        //      actual text instead.
                                                        //   2) Code-level recognizer for well-known
                                                        //      surahs / duas — covers Morning/Evening
                                                        //      whose title isn't backfilled yet.
                                                        //   3) Bismillah-stripped transliteration
                                                        //      so the actual dua text shows.
                                                        Text(
                                                          () {
                                                            if (_titleIsRealName(azkar.title)) {
                                                              return azkar.title;
                                                            }
                                                            final wellKnown =
                                                                _wellKnownAzkarName(
                                                                  azkar,
                                                                );
                                                            if (wellKnown.isNotEmpty) {
                                                              return wellKnown;
                                                            }
                                                            final src =
                                                                _stripBismillahPrefix(
                                                                  titleText,
                                                                );
                                                            return src.length >
                                                                    35
                                                                ? '${src.substring(0, 35).trimRight()}..'
                                                                : src;
                                                          }(),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          style: GoogleFonts.outfit(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 15,
                                                            height: 1.3,
                                                            color:
                                                                isComplete
                                                                    ? (isDark
                                                                        ? Colors
                                                                            .white54
                                                                        : kSub)
                                                                    : kText,
                                                          ),
                                                        ),
                                                        // ── Line 2 (light): benefit / reward snippet ──
                                                        const SizedBox(
                                                          height: 3,
                                                        ),
                                                        Text(
                                                          () {
                                                            // Source priority for the subtitle:
                                                            //   1) hadith_full — the full narration
                                                            //      ("Narrated by Ali (RA)...") which is
                                                            //      what the user expects to see as the
                                                            //      benefit line. Lives on Morning/Evening
                                                            //      rows whose `reward` field is just a
                                                            //      short surah name like "Surah Al-Ikhlas".
                                                            //   2) reward — the benefit text used by the
                                                            //      6 newer screenshot-imported categories
                                                            //      (Sleep, Salah, etc.). Their reward
                                                            //      IS the proper narration.
                                                            //   3) translation — last-resort fallback so
                                                            //      the line is never blank.
                                                            String raw = azkar.hadithFull.trim();
                                                            if (raw.isEmpty) raw = azkar.reward.trim();
                                                            if (raw.isEmpty) raw = azkar.translation.trim();
                                                            raw = raw.replaceAll('\n', ' ');
                                                            // Remove bracketed refs like (Sahih Muslim 123)
                                                            raw = raw.replaceAll(RegExp(r'\([^)]*(?:Muslim|Bukhari|Tirmidhi|Dawud|Majah|Nasai|Ahmad|Quran)[^)]*\)', caseSensitive: false), '');
                                                            // Remove pipe-separated refs (only when the
                                                            // string is short — hadith narrations
                                                            // sometimes legitimately contain "|" inside
                                                            // long sentences and we don't want to truncate
                                                            // them at the first occurrence).
                                                            if (raw.length < 80 && raw.contains('|')) {
                                                              raw = raw.split('|').first;
                                                            }
                                                            raw = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
                                                            return raw;
                                                          }(),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          style: GoogleFonts.outfit(
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontSize: 12,
                                                            color:
                                                                isComplete
                                                                    ? const Color(
                                                                      0xFFFFC83D,
                                                                    )
                                                                    : (isDark
                                                                        ? Colors
                                                                            .white38
                                                                        : const Color(
                                                                          0xFF9CA3AF,
                                                                        )),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.chevron_right_rounded,
                                                    size: 18,
                                                    color:
                                                        isDark
                                                            ? Colors.white24
                                                            : Colors.black12,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Divider — only between items, not after the last
                                          if (index < _filtered.length - 1)
                                            Divider(
                                              height: 1,
                                              thickness: 0.5,
                                              indent: 66,
                                              endIndent: 16,
                                              color:
                                                  isDark
                                                      ? Colors.white10
                                                      : Colors.black.withValues(
                                                        alpha: 0.06,
                                                      ),
                                            ),
                                        ],
                                      );
                                    }),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [
                const Color(0xFFFFC83D),
                Color(0xFFF59E0B),
                Color(0xFFEC4899),
                Color(0xFF38BDF8),
              ],
            ),
          ),
        ],
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleExitDhikr();
      },
      child: scaffold,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swipable Full Screen Detail Page
// ─────────────────────────────────────────────────────────────────────────────
class _DhikrDetailScreen extends StatefulWidget {
  final List<_Azkar> azkars;
  final int initialIndex;
  final Map<String, int> counts;
  final List<String> favorites;
  final _DhikrSettings settings;
  final _DhikrScreenState parentState;
  final bool autoPlayAll;

  const _DhikrDetailScreen({
    required this.azkars,
    required this.initialIndex,
    required this.counts,
    required this.favorites,
    required this.settings,
    required this.parentState,
    this.autoPlayAll = false,
  });

  @override
  State<_DhikrDetailScreen> createState() => _DhikrDetailScreenState();
}

// Snappy PageView snap. Stock Flutter PageScrollPhysics rounds to the
// nearest page at the 50% drag boundary AND only treats a release as a
// "flick" above ~50 px/s, so a small slow swipe gets categorised as
// "not enough intent" and bounces back — making it feel like you have
// to drag halfway across the screen to advance an azkar.
//
// Strategy:
//   * Any non-trivial release velocity (>5 px/s, ~1/10th of Flutter's
//     default) commits the page in the direction of that velocity:
//     forward velocity → ceil to next page, backward → floor to prev.
//     This is direction-of-intent based, not threshold based, so even
//     a 5% drag with a gentle release flicks to the next azkar.
//   * A truly zero-velocity release (finger held still at lift-off)
//     still rounds to the nearest page at 50%. This is the safe
//     fallback that prevents accidental commits when the user is just
//     resting a finger on screen.
class _SnappyPagePhysics extends PageScrollPhysics {
  const _SnappyPagePhysics({super.parent});

  @override
  _SnappyPagePhysics applyTo(ScrollPhysics? ancestor) =>
      _SnappyPagePhysics(parent: buildParent(ancestor));

  // px/s. Anything above this counts as "deliberate flick". Default
  // Flutter tolerance is ~50; we use ~5 so even leisurely swipes commit.
  static const double _kFlickThreshold = 5.0;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final viewport = position.viewportDimension;
    if (viewport <= 0) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final currentPage = position.pixels / viewport;

    double targetPage;
    if (velocity > _kFlickThreshold) {
      // Any forward intent → commit to next page (even from 5% drag).
      targetPage = currentPage.ceilToDouble();
    } else if (velocity < -_kFlickThreshold) {
      // Any backward intent → commit to previous page.
      targetPage = currentPage.floorToDouble();
    } else {
      // Truly idle release — round at 50%, standard behaviour.
      targetPage = currentPage.roundToDouble();
    }

    // Guard against ceil/floor producing the same page when currentPage
    // is already exactly on a page boundary (no drag at all).
    if ((targetPage - currentPage).abs() < 1e-6) {
      return null;
    }

    final target = targetPage * viewport;
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}

class _DhikrDetailScreenState extends State<_DhikrDetailScreen> {
  late PageController _pageController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyLoadedAudio;
  late bool _playAllMode;
  StreamSubscription<PlayerState>? _playerSub;
  bool _isAdvancing = false; // guard against double-skip

  // ── Playback speed ────────────────────────────────────────────────────
  // Cycled via the speed button in the player bar. Persisted to prefs so
  // it survives screen pops. Always re-applied after every setUrl() so a
  // mid-play speed change carries to the next rep / next track too.
  static const List<double> _kSpeedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  double _audioSpeed = 1.0;

  // ── Single-track repeat session ────────────────────────────────────────
  // When the user taps play on one azkar, we play the audio
  // `_singleRepeatTarget` times back-to-back — matching the azkar's
  // recommended count (or the user's custom target). The session is
  // bound to a token so tapping play on a different azkar (or pausing)
  // cleanly cancels any in-flight sequence.
  String? _singleRepeatUrl;
  int _singleRepeatTarget = 0;
  int _singleRepeatDone = 0;
  int _singleRepeatToken = 0;

  // ── Play-All repeat status (for the player subtitle) ─────────────────
  // 1-indexed current rep + total reps for the currently playing azkar.
  // Shown subtly next to "X of Y" in the play bar.
  int _playAllRep = 0;
  int _playAllRepTotal = 0;

  bool _showToolbar = false;
  Timer? _hideTimer;

  // Pending auto-advance to the next dhikr after a completion. Held as a
  // cancellable Timer so a manual swipe can kill it instantly — otherwise
  // the queued animateToPage fights the user's drag and the swipe stutters.
  Timer? _autoAdvanceTimer;

  // ── Draggable counter position ──
  Offset? _counterOffset; // null = default bottom-center
  bool _isDragging = false;

  // ── First-time hint: explains that completing a dhikr animates the
  // illustration above. Shown once per install via SharedPreferences flag.
  static const String _kHintSeenKey = 'dhikr_detail_hint_v1_shown';
  bool _showFirstTimeHint = false;
  Timer? _hintAutoDismissTimer;

  // ── Session tracking for smart notification logic ────────────────────
  late DateTime _sessionStart;
  // Number of azkar pages completed in THIS session visit
  int _pagesCompletedInSession = 0;
  // Min pages threshold before we show mid-session popup
  static const int _kMinPagesForImmediatePopup = 4;
  // Min time (seconds) before we show mid-session popup
  static const int _kMinSecondsForImmediatePopup = 60;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
    _playAllMode = widget.autoPlayAll;
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    StatsService.instance.enterScreen('dhikr');
    _playerSub = _audioPlayer.playerStateStream.listen((state) {
      // Repaint play / pause icons. Repeat sequencing is handled
      // explicitly in `_toggleAudio` and `_runPlayAllLoop`.
      if (mounted) setState(() {});
    });
    _loadAudioSpeedPref();
    // Start sequential play-all loop
    if (_playAllMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runPlayAllLoop());
    }
    _maybeShowFirstTimeHint();
  }

  Future<void> _maybeShowFirstTimeHint() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kHintSeenKey) ?? false) return;
    // Let the page settle in before fading the hint in.
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _showFirstTimeHint = true);
    _hintAutoDismissTimer?.cancel();
    _hintAutoDismissTimer = Timer(const Duration(seconds: 6), _dismissHint);
  }

  void _dismissHint() {
    _hintAutoDismissTimer?.cancel();
    _hintAutoDismissTimer = null;
    if (!_showFirstTimeHint) return;
    if (mounted) setState(() => _showFirstTimeHint = false);
    SharedPreferences.getInstance().then(
      (p) => p.setBool(_kHintSeenKey, true),
    );
  }

  // ── Speed: load saved preference + cycle on tap ────────────────────────
  static const String _kAudioSpeedKey = 'dhikr_audio_speed';

  Future<void> _loadAudioSpeedPref() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getDouble(_kAudioSpeedKey);
      if (v != null && _kSpeedOptions.contains(v)) {
        if (mounted) setState(() => _audioSpeed = v);
        // Apply to player even if nothing is playing yet — survives the
        // next setUrl on first play.
        try { await _audioPlayer.setSpeed(v); } catch (_) {}
      }
    } catch (_) {}
  }

  void _cycleAudioSpeed() {
    final i = _kSpeedOptions.indexOf(_audioSpeed);
    final next = _kSpeedOptions[(i + 1) % _kSpeedOptions.length];
    setState(() => _audioSpeed = next);
    // Apply to the active player immediately so a user can change speed
    // mid-recitation and hear it on the next frame.
    try { _audioPlayer.setSpeed(next); } catch (_) {}
    SharedPreferences.getInstance().then(
      (p) => p.setDouble(_kAudioSpeedKey, next),
    );
  }

  String _formatSpeed(double s) {
    // Drop trailing ".0" for cleaner labels: 1× / 1.25× / 1.5× / 2×
    if (s == s.roundToDouble()) return '${s.toInt()}×';
    return '${s.toString()}×';
  }

  void _toggleToolbar() {
    if (_showFirstTimeHint) _dismissHint();
    setState(() {
      _showToolbar = !_showToolbar;
    });
    _hideTimer?.cancel();
    if (_showToolbar) {
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted)
          setState(() {
            _showToolbar = false;
          });
      });
    }
  }

  @override
  void dispose() {
    StatsService.instance.exitScreen();
    _playerSub?.cancel();
    _audioPlayer.dispose();
    _hideTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    _hintAutoDismissTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Pressed from a per-azkar play button (the prominent top-right CTA and
  // the floating-toolbar play). Behaves like Play All: plays this azkar
  // first, then auto-advances through the rest of the list. If the user
  // taps while this same azkar is playing, treat as pause.
  Future<void> _playFromHereAsPlayAll(_Azkar azkar) async {
    final url = azkar.audioUrl;
    if (url == null || url.isEmpty) return;

    // Pause if this azkar is currently playing.
    if (_audioPlayer.playing && _currentlyLoadedAudio == url) {
      try { await _audioPlayer.pause(); } catch (_) {}
      if (mounted) setState(() {});
      return;
    }
    // Resume if we're already in play-all but paused on this track.
    if (_playAllMode && !_audioPlayer.playing &&
        _currentlyLoadedAudio == url) {
      try { unawaited(_audioPlayer.play()); } catch (_) {}
      if (mounted) setState(() {});
      return;
    }

    // Cancel any in-flight single-repeat sequence, then start play-all
    // from the current index. _runPlayAllLoop reads _currentIndex.
    _singleRepeatToken++;
    try { await _audioPlayer.stop(); } catch (_) {}
    if (mounted) {
      setState(() {
        _singleRepeatUrl = null;
        _singleRepeatTarget = 0;
        _singleRepeatDone = 0;
        _playAllMode = true;
      });
    } else {
      _singleRepeatUrl = null;
      _singleRepeatTarget = 0;
      _singleRepeatDone = 0;
      _playAllMode = true;
    }
    _runPlayAllLoop();
  }

  Future<void> _toggleAudio(_Azkar azkar) async {
    final url = azkar.audioUrl;
    if (url == null || url.isEmpty) return;

    // Play-all is driven by `_runPlayAllLoop`. From this button we must
    // only pause/resume the shared player — starting our own single-track
    // session here would race the loop on the same `_audioPlayer` and
    // either deadlock or crash.
    //
    // IMPORTANT: just_audio's `play()` Future does NOT resolve when
    // playback starts — it resolves when playback STOPS (end/pause/stop).
    // Awaiting it here would hang the button until the track ends. Fire
    // it without await; the play-all loop's own awaited play() and its
    // playerState.firstWhere() take care of state transitions.
    if (_playAllMode) {
      try {
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
        } else {
          unawaited(_audioPlayer.play());
        }
      } catch (e) {
        debugPrint('Audio Error (play-all toggle): $e');
      }
      if (mounted) setState(() {});
      return;
    }

    // If this azkar is currently playing, treat the tap as a pause.
    // We DON'T bump the token — the in-flight repeat loop should stay
    // alive (parked in its poll) and resume naturally when the user taps
    // play again, so the user continues from the same rep instead of
    // restarting at rep 0.
    if (_audioPlayer.playing && _currentlyLoadedAudio == url) {
      try {
        await _audioPlayer.pause();
      } catch (e) {
        debugPrint('Audio Error (pause): $e');
      }
      if (mounted) setState(() {});
      return;
    }

    // Mid-session pause on this same azkar → resume the player. The
    // in-flight repeat loop is still polling; it sees the resume and
    // continues at the same rep until the track completes naturally.
    if (!_audioPlayer.playing &&
        _currentlyLoadedAudio == url &&
        _singleRepeatUrl == url &&
        _singleRepeatTarget > 0) {
      try {
        unawaited(_audioPlayer.play());
      } catch (e) {
        debugPrint('Audio Error (resume): $e');
      }
      if (mounted) setState(() {});
      return;
    }

    final target = widget.parentState
        ._getTarget(azkar.id, azkar.recommendedCount)
        .clamp(1, 9999);

    // Start a fresh repeat session (new azkar, or after Stop / completion).
    _singleRepeatToken++;
    final myToken = _singleRepeatToken;
    if (mounted) {
      setState(() {
        _singleRepeatUrl = url;
        _singleRepeatTarget = target;
        _singleRepeatDone = 0;
      });
    } else {
      _singleRepeatUrl = url;
      _singleRepeatTarget = target;
      _singleRepeatDone = 0;
    }

    try {
      for (var rep = 0; rep < target; rep++) {
        if (!mounted || _singleRepeatToken != myToken) return;
        if (mounted) setState(() => _singleRepeatDone = rep);
        // Re-arm the source on every repeat. `seek(0) + play()` is
        // unreliable after `completed` in just_audio 0.10, but
        // stop→setUrl→play always starts a fresh track.
        await _audioPlayer.stop();
        await _audioPlayer.setUrl(url);
        try { await _audioPlayer.setSpeed(_audioSpeed); } catch (_) {}
        _currentlyLoadedAudio = url;

        // Fire-and-forget play(); poll processingState for completion.
        // Same robust pattern as the play-all loop — avoids the
        // double-play() hang and treats pause/resume transparently
        // (we just keep polling while paused, the user can resume at
        // any time and the rep continues from where it left off).
        unawaited(_audioPlayer.play());

        while (true) {
          if (!mounted || _singleRepeatToken != myToken) return;
          final ps = _audioPlayer.processingState;
          if (ps == ProcessingState.completed) break; // rep finished
          if (ps == ProcessingState.idle) return; // user hit Stop
          await Future.delayed(const Duration(milliseconds: 120));
        }
      }
      // Reached the prescribed count cleanly.
      if (_singleRepeatToken == myToken && mounted) {
        setState(() {
          _singleRepeatUrl = null;
          _singleRepeatTarget = 0;
          _singleRepeatDone = 0;
        });
      }
    } catch (e) {
      debugPrint('Audio Error: $e');
    }
  }

  /// Sequential play-all loop — plays each azkar one by one.
  /// Respects user swipes by always reading _currentIndex.
  Future<void> _runPlayAllLoop() async {
    while (_playAllMode && mounted) {
      final i = _currentIndex;
      if (i >= widget.azkars.length) break;

      final azkar = widget.azkars[i];
      final url = azkar.audioUrl;

      // Find the NEXT audio-bearing azkar at or after `i` (lets us
      // hop over tracks that have no URL without cascading rapid-page
      // animations — previously we animateToPage'd one card at a time,
      // which looked like uncontrolled swiping when several in a row
      // had no audio).
      int firstPlayableFrom(int start) {
        for (int k = start; k < widget.azkars.length; k++) {
          final u = widget.azkars[k].audioUrl;
          if (u != null && u.isNotEmpty) return k;
        }
        return -1;
      }

      if (url == null || url.isEmpty) {
        final next = firstPlayableFrom(i + 1);
        if (next == -1) break; // nothing left to play
        _isAdvancing = true;
        await _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        await Future.delayed(const Duration(milliseconds: 300));
        _isAdvancing = false;
        continue;
      }

      // Track whether THIS track ever produced playable audio. If
      // setUrl/play fails for any reason (network, codec, just_audio
      // chokes on the host), we treat the track as audio-less rather
      // than billing the user as "playing" and silently advancing.
      bool playbackHappened = false;
      try {
        // Play this azkar's audio its prescribed number of times — e.g. if
        // the hadith specifies 3 recitations, the audio plays 3 times
        // before we move on to the next track.
        final target = widget.parentState
            ._getTarget(azkar.id, azkar.recommendedCount)
            .clamp(1, 9999);
        if (mounted) {
          setState(() {
            _playAllRepTotal = target;
            _playAllRep = 0;
          });
        }
        var interrupted = false;
        for (var rep = 0; rep < target && !interrupted; rep++) {
          if (!mounted || !_playAllMode || _currentIndex != i) break;
          if (mounted) setState(() => _playAllRep = rep + 1);
          // Fresh load each rep — `seek(0) + play()` after a `completed`
          // state is unreliable in just_audio 0.10, but stop→setUrl→play
          // always starts a fresh playback.
          await _audioPlayer.stop();
          try {
            await _audioPlayer.setUrl(url);
          } catch (e) {
            debugPrint("Play All setUrl error at index $i ($url): $e");
            interrupted = true;
            break;
          }
          try { await _audioPlayer.setSpeed(_audioSpeed); } catch (_) {}
          _currentlyLoadedAudio = url;

          // Fire-and-forget play(). just_audio.play() resolves on
          // pause/end — NOT on start — and calling it twice on the same
          // session never resolves the second future (the source of the
          // pause→resume hang we used to have). Instead we poll the
          // processingState: completed = rep done, idle = stopped.
          // Pause/resume is handled transparently — we just keep polling
          // until the track actually finishes.
          unawaited(_audioPlayer.play());

          while (true) {
            if (!mounted) {
              interrupted = true;
              break;
            }
            if (!_playAllMode || _currentIndex != i) {
              // Mode flipped off or user swiped — stop the player so the
              // next rep / next track starts cleanly.
              try {
                await _audioPlayer.stop();
              } catch (_) {}
              interrupted = true;
              break;
            }
            final ps = _audioPlayer.processingState;
            if (_audioPlayer.playing) playbackHappened = true;
            if (ps == ProcessingState.completed) {
              break; // rep finished naturally
            }
            if (ps == ProcessingState.idle) {
              // User hit stop. Bail out of this azkar entirely.
              interrupted = true;
              break;
            }
            // ProcessingState is loading/buffering/ready (playing or paused).
            // Poll — pause/resume requires no special handling here.
            await Future.delayed(const Duration(milliseconds: 120));
          }
        }
      } catch (e) {
        debugPrint("Play All Audio Error at index $i: $e");
      }

      if (!mounted || !_playAllMode) break;

      // If user swiped during playback, continue from wherever they are now
      if (_currentIndex != i) continue;

      // If setUrl threw (or some other transient error) and playback
      // never actually started, stop the loop here instead of racing
      // through every subsequent track silently. The user can manually
      // swipe past the broken track and tap Play All again to resume.
      if (!playbackHappened) {
        debugPrint(
          'Play All: stopping — track $i (${azkar.id}) failed to start.',
        );
        break;
      }

      // Advance to next playable track in one animation (instead of
      // animating through audio-less ones one-by-one).
      final next = firstPlayableFrom(i + 1);
      if (next == -1) break;

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || !_playAllMode) break;

      _isAdvancing = true;
      await _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      await Future.delayed(const Duration(milliseconds: 300));
      _isAdvancing = false;
    }

    // Done — end play-all mode
    if (mounted) {
      setState(() {
        _playAllMode = false;
        _playAllRep = 0;
        _playAllRepTotal = 0;
      });
    }
  }

  // Throttle so rapid-tap completions don't stack toasts.
  DateTime _lastToastAt = DateTime.fromMillisecondsSinceEpoch(0);
  void _showRewardSecuredToast() {
    final now = DateTime.now();
    if (now.difference(_lastToastAt).inMilliseconds < 600) return;
    _lastToastAt = now;
    final overlay = Overlay.of(context, rootOverlay: true);
    HapticFeedback.mediumImpact();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _RewardSecuredToast(
        onDone: () {
          entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }

  void _tryComplete(_Azkar azkar, int tapTarget, {bool isSwipe = false}) {
    if (!isSwipe && _showFirstTimeHint) _dismissHint();
    final current = widget.parentState._counts[azkar.id] ?? 0;
    if (current >= tapTarget) return;

    final justCompleted = widget.parentState._tap(azkar.id, tapTarget);
    if (mounted) setState(() {});

    if (justCompleted) {
      _pagesCompletedInSession++;
      widget.parentState._completeDhikr(azkar.id, tapTarget);
      _showRewardSecuredToast();

      if (!isSwipe) {
        final currentGlobalIndex = widget.azkars.indexOf(azkar);
        final nextIndex = currentGlobalIndex + 1;
        if (nextIndex > 0 && nextIndex < widget.azkars.length) {
          // How long to hold the completed dhikr before auto-advancing is
          // admin-controlled (dhikr_advance_delay_seconds). 0 keeps the
          // snappy ~120ms advance — long enough for the completion
          // setState to paint one frame; a positive value holds that many
          // seconds so the user can dwell on the finished dhikr. Either
          // way the _currentIndex guard means a manual swipe cancels the
          // pending auto-advance instantly.
          // The auto-advance delay can be turned off per azkar *type*:
          // single-read azkar (counter target of 1) vs multi-count azkar
          // (a dhikr counter, e.g. x33). Each type has its own toggle on
          // the admin Feature Flags page. A type with its delay off always
          // uses the snappy ~120 ms advance, ignoring the global
          // dhikr_advance_delay_seconds value.
          final cfg = SettingsService.instance.config;
          final isMultiCount = tapTarget > 1;
          final delayEnabled = isMultiCount
              ? cfg.dhikrDelayMultiCount
              : cfg.dhikrDelaySingleRead;
          final holdSeconds =
              delayEnabled ? cfg.dhikrAdvanceDelaySeconds : 0;
          final delay = holdSeconds > 0
              ? Duration(seconds: holdSeconds)
              : const Duration(milliseconds: 120);
          _autoAdvanceTimer?.cancel();
          _autoAdvanceTimer = Timer(delay, () {
            if (!mounted) return;
            if (_currentIndex != currentGlobalIndex) return; // user already moved
            _pageController.animateToPage(
              nextIndex,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
            );
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.settings.darkMode;

    // Safe index — clamp to valid range
    final safeIndex = _currentIndex.clamp(0, widget.azkars.length - 1);
    final appBarColor = _illustrationTopColor(
      widget.azkars[safeIndex].id,
      isDark,
    );

    return PopScope(
      child: Scaffold(
        backgroundColor:
            isDark
                ? const Color(0xFF1A1A1A)
                : _scaffoldBgForCategory(widget.azkars[safeIndex].category),
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          toolbarHeight: 72,
          flexibleSpace: Builder(
            builder: (context) {
              int ci = safeIndex;
              try {
                if (_pageController.hasClients &&
                    _pageController.page != null) {
                  ci = _pageController.page!.round().clamp(
                    0,
                    widget.azkars.length - 1,
                  );
                }
              } catch (_) {}
              // For Morning/Evening, hold the whole AppBar on Y4 honey wash
              // so there's no visible seam between the header and the
              // cream body card. For other categories, keep the original
              // cream-to-white sweep (their body is white).
              final azkarHere = widget.azkars[ci];
              final isAkhirahHere = azkarHere.category == 'morning' ||
                  azkarHere.category == 'evening';
              final List<Color> gradColors = isAkhirahHere
                  ? [Y4.bg, Y4.bg, Y4.bg]
                  : [Y4.cream, Colors.white, Colors.white];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradColors.last.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              );
            },
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white.withValues(alpha: 0.90) : Y4.ink,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Builder(
            builder: (context) {
              int ci = safeIndex;
              try {
                if (_pageController.hasClients &&
                    _pageController.page != null) {
                  ci = _pageController.page!.round().clamp(
                    0,
                    widget.azkars.length - 1,
                  );
                }
              } catch (_) {}
              final azkar = widget.azkars[ci];
              final catId = azkar.category;
              final catObj = widget.parentState._categories
                  .cast<_Category?>()
                  .firstWhere((c) => c?.id == catId, orElse: () => null);
              final String catLabel = catObj?.label ?? 'Dhikr & Dua';
              final isMorning = catId == 'morning';
              final readCount = widget.parentState._getTarget(
                azkar.id,
                azkar.recommendedCount,
              );
              final String readLabel =
                  readCount == 1 ? 'Read once' : 'Read $readCount times';
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    catLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Y4.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFFFF4D2)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${ci + 1} / ${widget.azkars.length}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Y4.ink,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.20)
                              : Y4.ink.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.35)
                                : Y4.ink.withValues(alpha: 0.20),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          readLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Y4.ink,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          centerTitle: true,
          actions: [
            // Quick "Play >" entry point on the top-right of the dhikr
            // detail screen. Routes through the same _toggleAudio() that
            // the right-hand toolbar's play button uses, so pause/resume
            // and the bottom play bar work identically.
            Builder(
              builder: (context) {
                int ci = safeIndex;
                try {
                  if (_pageController.hasClients &&
                      _pageController.page != null) {
                    ci = _pageController.page!.round().clamp(
                      0,
                      widget.azkars.length - 1,
                    );
                  }
                } catch (_) {}
                final azkar = widget.azkars[ci];
                final hasAudio =
                    azkar.audioUrl != null && azkar.audioUrl!.isNotEmpty;
                if (!hasAudio) return const SizedBox.shrink();
                final isThisPlaying = _audioPlayer.playing &&
                    _currentlyLoadedAudio == azkar.audioUrl;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(99),
                      onTap: () => _playFromHereAsPlayAll(azkar),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Y4.honey, Y4.honeyDeep],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                              color: Y4.honeyDeep.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isThisPlaying ? 'Pause' : 'Play',
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                isThisPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(10),
            child: Container(
              color: appBarColor,
              child: _AzkarProgressLine(
                azkars: widget.azkars,
                counts: widget.counts,
                currentIndex: safeIndex,
                parentState: widget.parentState,
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _toggleToolbar(),
          child: NotificationListener<ScrollStartNotification>(
            // The instant the user starts dragging the page, kill any
            // pending auto-advance so the queued animateToPage can't fight
            // the manual swipe (that collision is what made it stutter).
            onNotification: (n) {
              if (n.dragDetails != null) _autoAdvanceTimer?.cancel();
              return false;
            },
            child: PageView.builder(
            controller: _pageController,
            // Snappier page-snap: small flicks (~15% drag with any release
            // velocity) commit to the next azkar instead of bouncing back.
            // See _SnappyPagePhysics above for the math.
            // ClampingScrollPhysics stops the swipe hard at the last
            // page so the user doesn't see the blank overscroll area
            // past the final card. Snappy page snap still applies.
            physics: const _SnappyPagePhysics(
              parent: ClampingScrollPhysics(),
            ),
            allowImplicitScrolling: true,
            onPageChanged: (nextIndex) {
              // Only stop audio if user manually swiped (not auto-advancing)
              if (!_isAdvancing) {
                if (_audioPlayer.playing) _audioPlayer.stop();
                _currentlyLoadedAudio = null; // force reload on next play
              }
              if (mounted) {
                setState(() {
                  _currentIndex = nextIndex;
                });
              }
            },
            itemCount: widget.azkars.length,
            itemBuilder: (context, index) {
              final azkar = widget.azkars[index];
              final count = widget.counts[azkar.id] ?? 0;
              final tapTarget = widget.parentState._getTarget(
                azkar.id,
                azkar.recommendedCount,
              );
              final isComplete = count >= tapTarget;

              // Free-Illustration mode: keep the illustration pinned at the
              // top of this page while the Arabic + transliteration +
              // translation scroll independently beneath it. Only kicks in
              // when the illustration is shown at all.
              final pinIllustration = widget.settings.freeIllustration &&
                  widget.settings.showIllustration;
              final animationKey =
                  widget.parentState._todayAnimationKeyFor(azkar.id);

              final azkarCard = _AzkarCard(
                azkar: azkar,
                currentCount: count,
                targetCount: tapTarget,
                isComplete: isComplete,
                isFavorite: widget.favorites.contains(azkar.id),
                settings: widget.settings,
                pointsToday: widget.parentState._pointsToday,
                // Pull today's animation key from the parent's
                // azkar_item_animations pool. Null falls back to
                // the hardcoded _pickIllustration mapping inside
                // _buildIllustration.
                animationKeyOverride: animationKey,
                forceHideIllustration: pinIllustration,
                onReset: () {
                  widget.parentState._reset(azkar.id);
                  setState(() {});
                },
                onFavorite: () {
                  widget.parentState._toggleFavorite(azkar.id);
                  setState(() {});
                },
                onShare: () => widget.parentState._shareAzkar(azkar),
              );

              return Stack(
                children: [
                  Positioned.fill(
                    child: pinIllustration
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _PinnedIllustration(
                                azkar: azkar,
                                currentCount: count,
                                targetCount: tapTarget,
                                isComplete: isComplete,
                                pointsToday:
                                    widget.parentState._pointsToday,
                                animationKeyOverride: animationKey,
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.only(
                                    bottom: 140 +
                                        MediaQuery.of(context).padding.bottom,
                                  ),
                                  child: azkarCard,
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            padding: EdgeInsets.only(
                              top: 0,
                              bottom:
                                  140 + MediaQuery.of(context).padding.bottom,
                            ),
                            child: azkarCard,
                          ),
                  ),
                  // (progress shown in AppBar bottom line)
                  Positioned(
                    right: 14,
                    bottom: 90 + MediaQuery.of(context).padding.bottom,
                    child: AnimatedSlide(
                      offset: _showToolbar ? Offset.zero : const Offset(0.6, 0),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: _showToolbar ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 220),
                        child: IgnorePointer(
                          ignoring: !_showToolbar,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? const Color(
                                        0xFF1E1E1E,
                                      ).withValues(alpha: 0.92)
                                      : Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color:
                                    isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.06),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.35 : 0.10,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ToolbarBtn(
                                  icon: Icons.tune_rounded,
                                  color:
                                      isDark
                                          ? const Color(0xFF7EB8F0)
                                          : const Color(0xFF4A90D9),
                                  isDark: isDark,
                                  onTap: () {
                                    widget.parentState._showSettingsSheet(
                                      context,
                                      () {
                                        if (mounted) setState(() {});
                                      },
                                    );
                                  },
                                ),
                                _toolbarDivider(isDark),
                                if (azkar.audioUrl != null &&
                                    azkar.audioUrl!.isNotEmpty) ...[
                                  _ToolbarBtn(
                                    icon:
                                        _audioPlayer.playing &&
                                                _currentlyLoadedAudio ==
                                                    azkar.audioUrl
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                    color: const Color(0xFFFFC83D),
                                    isDark: isDark,
                                    onTap: () => _playFromHereAsPlayAll(azkar),
                                  ),
                                  _toolbarDivider(isDark),
                                ],
                                _ToolbarBtn(
                                  icon:
                                      widget.favorites.contains(azkar.id)
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_outline_rounded,
                                  color: const Color(0xFFE11D48),
                                  filled: widget.favorites.contains(azkar.id),
                                  isDark: isDark,
                                  onTap: () {
                                    widget.parentState._toggleFavorite(
                                      azkar.id,
                                    );
                                    setState(() {});
                                  },
                                ),
                                _toolbarDivider(isDark),
                                _ToolbarBtn(
                                  icon: Icons.share_rounded,
                                  color:
                                      isDark
                                          ? const Color(0xFFE8B74A)
                                          : const Color(0xFFD4960A),
                                  isDark: isDark,
                                  onTap:
                                      () =>
                                          widget.parentState._shareAzkar(azkar),
                                ),
                                _toolbarDivider(isDark),
                                _ToolbarBtn(
                                  icon:
                                      widget.parentState._customTargets
                                              .containsKey(azkar.id)
                                          ? Icons.flag_rounded
                                          : Icons.flag_outlined,
                                  color: const Color(0xFF7C3AED),
                                  filled: widget.parentState._customTargets
                                      .containsKey(azkar.id),
                                  isDark: isDark,
                                  onTap: () {
                                    widget.parentState._showTargetPicker(
                                      context,
                                      azkar.id,
                                      azkar.recommendedCount,
                                    );
                                  },
                                ),
                                _toolbarDivider(isDark),
                                _ToolbarBtn(
                                  icon: Icons.refresh_rounded,
                                  color: const Color(0xFFFFC83D),
                                  isDark: isDark,
                                  onTap: () {
                                    widget.parentState._reset(azkar.id);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ── "Mark as Done" button for read-once azkaar ──
                  if (tapTarget <= 1)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: 32 + MediaQuery.of(context).padding.bottom,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            switchInCurve: Curves.easeOutCubic,
                            child:
                                isComplete
                                    ? Container(
                                      key: const ValueKey('done'),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFFD966),
                                            Color(0xFFFFC83D),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            "You've Done!",
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : Material(
                                      key: const ValueKey('mark'),
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(30),
                                        onTap:
                                            () => _tryComplete(
                                              azkar,
                                              tapTarget,
                                              isSwipe: false,
                                            ),
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFFFFC83D),
                                                const Color(0xFFFFC83D),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 32,
                                              vertical: 16,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.check_rounded,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  AppLocalizations.of(
                                                        context,
                                                      )?.markAsDone ??
                                                      'Mark as Done',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ),
                  // ── Draggable counter button ──
                  if (tapTarget > 1)
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        final screenW = constraints.maxWidth;
                        final screenH = constraints.maxHeight;
                        final safeBottom =
                            MediaQuery.of(context).padding.bottom;
                        final btnWidth = isComplete ? 190.0 : 110.0;
                        final defaultX = screenW / 2 - btnWidth / 2;
                        final defaultY = screenH - 130 - safeBottom;
                        final dx =
                            isComplete
                                ? (screenW / 2 - btnWidth / 2)
                                : (_counterOffset?.dx ?? defaultX);
                        final dy = _counterOffset?.dy ?? defaultY;

                        return Stack(
                          children: [
                            Positioned(
                              left: dx.clamp(0.0, screenW - btnWidth),
                              top: dy.clamp(60.0, screenH - 70),
                              child: GestureDetector(
                                onTap:
                                    isComplete
                                        ? null
                                        : () => _tryComplete(
                                          azkar,
                                          tapTarget,
                                          isSwipe: false,
                                        ),
                                onPanStart:
                                    (_) => setState(() => _isDragging = true),
                                onPanEnd:
                                    (_) => setState(() => _isDragging = false),
                                onPanCancel:
                                    () => setState(() => _isDragging = false),
                                onPanUpdate: (details) {
                                  setState(() {
                                    _isDragging = true;
                                    final cur =
                                        _counterOffset ??
                                        Offset(defaultX, defaultY);
                                    _counterOffset = Offset(
                                      (cur.dx + details.delta.dx).clamp(
                                        0.0,
                                        screenW - 110,
                                      ),
                                      (cur.dy + details.delta.dy).clamp(
                                        60.0,
                                        screenH - 70,
                                      ),
                                    );
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow:
                                        _isDragging
                                            ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFFFC83D,
                                                ).withValues(alpha: 0.6),
                                                blurRadius: 28,
                                                spreadRadius: 8,
                                              ),
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFFFC83D,
                                                ).withValues(alpha: 0.3),
                                                blurRadius: 50,
                                                spreadRadius: 14,
                                              ),
                                            ]
                                            : [],
                                  ),
                                  child: AnimatedScale(
                                    scale: _isDragging ? 1.12 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: _DhikrCounterButton(
                                      count: count,
                                      target: tapTarget,
                                      isComplete: isComplete,
                                      isDark: isDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              );
            },
            ),
          ),
        ),
            if (_showFirstTimeHint)
              Positioned(
                left: 0,
                right: 0,
                bottom: 110 + MediaQuery.of(context).padding.bottom,
                child: Center(
                  child: _FirstTimeHintBubble(
                    isDark: isDark,
                    onTap: _dismissHint,
                  ),
                ),
              ),
          ],
        ),
        // ── Play-All control bar ──────────────────────────────────────────
        // Surface the bar only once the user has actually triggered
        // playback — either the Play-All sequence is running, or a single
        // track is loaded via the per-azkar play CTA. Keeps the screen
        // clean before audio is in use.
        bottomNavigationBar: _playAllMode || _currentlyLoadedAudio != null
            ? _buildPlayBar(isDark)
            : null,
      ),
    );
  }

  /// Minimal driving-friendly bottom bar — one big toggle button + speed.
  ///
  /// Button label flips:
  ///   ▶ Play All   when no track is playing (start / resume Play All)
  ///   ⏸ Pause       when a track is playing
  ///
  /// The Next / Stop / track-info widgets are gone — the user navigates by
  /// swiping the PageView (handled in onPageChanged, which lets the
  /// Play-All loop continue from the swiped-to index), and "stops" by
  /// pausing or backing out of the screen.
  Widget _buildPlayBar(bool isDark) {
    final isPlaying = _audioPlayer.playing;
    final barBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFC83D);
    final btnBg = isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFF2A2410);
    final speedBg = isDark ? const Color(0xFF2A2410) : Colors.white;
    final speedFg = isDark ? Colors.white : Y4.ink;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: barBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Big Play All / Pause toggle ─────────────────────────────────
          Expanded(
            child: Material(
              color: btnBg,
              borderRadius: BorderRadius.circular(32),
              child: InkWell(
                borderRadius: BorderRadius.circular(32),
                onTap: () async {
                  if (isPlaying) {
                    try {
                      await _audioPlayer.pause();
                    } catch (_) {}
                    if (mounted) setState(() {});
                  } else {
                    final cur = widget.azkars[_currentIndex.clamp(
                      0,
                      widget.azkars.length - 1,
                    )];
                    // Resumes the parked Play-All loop if the same track is
                    // paused; otherwise starts a fresh Play-All from here.
                    await _playFromHereAsPlayAll(cur);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isPlaying ? 'Pause' : 'Play All',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ── Speed pill: 1× → 1.25× → 1.5× → 2× → 1× ────────────────────
          Material(
            color: speedBg,
            borderRadius: BorderRadius.circular(32),
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: _cycleAudioSpeed,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                child: Text(
                  _formatSpeed(_audioSpeed),
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: speedFg,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ── Close button: stops audio and dismisses the bar entirely ───
          Material(
            color: speedBg,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () async {
                try {
                  await _audioPlayer.stop();
                } catch (_) {}
                if (!mounted) return;
                setState(() {
                  _playAllMode = false;
                  _currentlyLoadedAudio = null;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(
                  Icons.close_rounded,
                  color: speedFg,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _playBarBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = widget.settings.darkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFFFFC83D) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Y4.ink, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arabic text cleaner — strips brackets, parentheses, and Quranic waqf/
// annotation characters that sometimes appear in source data.
// ─────────────────────────────────────────────────────────────────────────────
/// Ayah info for Quranic passages: start ayah number, total ayah count,
/// and whether Bismillah counts as ayah 1 (only true for Al-Fatiha).
typedef _AyahInfo = ({int start, int count, bool bismillahIsAyah});

/// Scaffold bg color matching bottom gradient for each category.
/// Morning/Evening live on the Y4 honey wash so the AppBar, illustration
/// surround, and body card all read as one continuous warm surface.
Color _scaffoldBgForCategory(String cat) =>
    (cat == 'morning' || cat == 'evening') ? Y4.bg : Colors.white;

/// True when the DB `azkar_items.title` value is a recognizable dua/surah
/// NAME (e.g. "Surah Al-Mulk", "Ayatul Kursi", "Dua Qunoot") rather than a
/// situational context LABEL (e.g. "Upon Going to Sleep", "When Sneezing",
/// "Before the Meals"). The list view uses real names directly but falls
/// through to the dua's transliteration when the title is just a context
/// label — otherwise Daily Duas rows would all read as their trigger
/// situation instead of the dua text the user actually wants to recognize.
bool _titleIsRealName(String title) {
  if (title.isEmpty) return false;
  final t = title.trimLeft().toLowerCase();
  // Allow-list of opening patterns that always indicate a real name.
  const realNamePrefixes = <String>[
    'surah ', 'surah al', 'sūrah ',
    'ayatul', 'ayat al', 'ayat ul', 'ayat-ul', 'ayat-al',
    'al baqarah ', 'al-baqarah ',
    'al fatihah', 'al-fatihah', 'al fateh', 'al-fateh',
    'al ikhlas', 'al-ikhlas',
    'al falaq', 'al-falaq',
    'an nas', 'an-nas', 'al nas', 'al-nas',
    'al kafirun', 'al-kafirun', 'al-kaafiroon',
    'al mulk', 'al-mulk',
    'as sajdah', 'as-sajdah', 'as sajda', 'as-sajda',
    'dua qunoot', "du'a qunoot", 'dua qunut',
    'salatul ', 'salat al ', 'salaat ',
    'sayyid al-istighfar', 'sayyid al istighfar', 'sayyidul istighfar',
    'tasbih', // "Tasbih Fatima", "Tasbih (33...)"
    'salawat', 'durood', 'durud',
    'hasbunallah', "hasbunallahu",
    'the greatest name', 'greatest name of allah',
    'names of allah', 'asmaul husna', 'asma-ul husna',
    'la hawla', 'laa hawla',
    'astaghfirullah', // when used as a standalone name
    'la ilaha illa', 'laa ilaaha illa',
  ];
  for (final prefix in realNamePrefixes) {
    if (t.startsWith(prefix)) return true;
  }
  return false;
}

/// Strip the universal "Bismillah ir Rahmaan ir Raheem" opening from a
/// transliteration so the list view shows the dua's distinctive content
/// rather than the identical opening every Quranic recitation shares.
/// Matches "Bismill..." up to the first period (the Bismillah variants
/// "Bismillaahir Rahmaanir Raheem.", "Bismillah hir Rahman nir Raheem.",
/// etc. all end with a period before the actual content begins).
String _stripBismillahPrefix(String s) {
  if (s.length < 12) return s;
  if (!s.trimLeft().toLowerCase().startsWith('bismill')) return s;
  final dotIdx = s.indexOf('.');
  // Sanity-cap at 50 chars — a real Bismillah opener is < 40 chars; if the
  // first period is far past that, we're inside actual content and should
  // leave the string alone.
  if (dotIdx == -1 || dotIdx > 50) return s;
  final stripped = s.substring(dotIdx + 1).trim();
  // If the entire input was the Bismillah opener (nothing after the
  // period), keep the original — better to show "Bismillahi..." than
  // an empty title row. Hits duas whose actual text IS a Bismillah
  // variant, e.g. daily_dua_008 "Bismillahi fee awwalihi wa aakhirih."
  if (stripped.isEmpty) return s;
  return stripped;
}

/// Normalize a transliteration so the same Quranic dua matches whether it
/// was imported with academic diacritics ("Allāhu lā ilāha illā Huwa-l-Ḥayyu-
/// l-Qayyūm"), double-vowel "long-vowel" English style ("Qul a'oodhu bi
/// Rabbin-Naas"), or single-vowel anglicization ("Qul a'udhu bi Rabbin-nas").
///
/// After normalization all three of those collapse to the same string:
///   "allahu la ilaha illa huwa-l-hayyu-l-qayyum"
///   "qul a'udhu bi rabbin-nas"
///
/// Then the recognizer can use a single canonical spelling per pattern.
String _normalizeTranslit(String s) {
  // Lowercase, then collapse Arabic-transliteration diacritics to ASCII.
  String r = s.toLowerCase();
  const diacritics = <String, String>{
    'ā': 'a', 'ä': 'a', 'â': 'a',
    'ī': 'i', 'ï': 'i', 'î': 'i',
    'ū': 'u', 'ü': 'u', 'û': 'u',
    'ē': 'e', 'ë': 'e', 'ê': 'e',
    'ō': 'o', 'ö': 'o', 'ô': 'o',
    'ḥ': 'h', 'ḩ': 'h',
    'ḍ': 'd',
    'ṣ': 's',
    'ṭ': 't',
    'ẓ': 'z', 'ż': 'z',
    'ʿ': "'", 'ʾ': "'", 'ʼ': "'", 'ʹ': "'", 'ʻ': "'",
  };
  diacritics.forEach((from, to) {
    r = r.replaceAll(from, to);
  });
  // Collapse doubled vowels (Naas → Nas, Qayyoom → Qayyom, aboo'u → abo'u,
  // a'oodhu → a'odhu). Quranic transliteration variants pile up here.
  r = r.replaceAllMapped(
    RegExp(r'([aeiou])\1+'),
    (m) => m.group(1)!,
  );
  return r;
}

/// Recognize common surahs and well-known azkar by their TRANSLITERATION so
/// the list view can show familiar names ("Surah Al-Fatihah", "Ayatul Kursi")
/// even when the DB `title` column hasn't been backfilled. Patterns are
/// expressed in the NORMALIZED form (see [_normalizeTranslit]) so spelling
/// variants ("naas/nas", "qayyoom/qayyum", "Aʿūdhu/A'oodhu/A'udhu") all
/// collapse to a single string we can compare against once.
///
/// Returns empty string when no well-known pattern matches — caller then
/// falls back to the Bismillah-stripped transliteration snippet.
String _wellKnownAzkarName(_Azkar azkar) {
  final raw = azkar.transliteration;
  if (raw.isEmpty) return '';
  // Strip the Bismillah opener first (it's identical for every Quranic dua
  // and would otherwise let the recognizer match on the wrong surah). Then
  // normalize so spelling variants line up.
  final body = _normalizeTranslit(_stripBismillahPrefix(raw));
  if (body.isEmpty) return '';

  // The normalizer only collapses VOWELS — double consonants ("ll", "bb",
  // "yy", etc.) survive. Patterns below use the same double-consonant
  // forms the underlying data has after lowercase+diacritic-strip+dedup.

  // ── The Quran (highest-priority — these are the names users recognize) ──
  // Surah Al-Fatihah — "Al-hamdu lillahi Rabbil-'alamin..."
  if (body.startsWith('al-hamdu lillahi rabbil') ||
      body.startsWith('alhamdu lillahi rabbil') ||
      body.startsWith('alhamdulillahi rabbil')) {
    return 'Surah Al-Fatihah';
  }
  // Surah Al-Ikhlas — "Qul Huwallahu Ahad. Allahus-Samad..."
  if (body.startsWith('qul huwallahu ahad') ||
      body.startsWith('qul huwa allahu ahad') ||
      body.contains('allahus-samad') ||
      body.contains('allahu samad')) {
    return 'Surah Al-Ikhlas';
  }
  // Surah Al-Falaq — "Qul a'udhu bi Rabbil-falaq..."
  if (body.contains('falaq') && body.contains("qul a'udhu")) {
    return 'Surah Al-Falaq';
  }
  // Surah An-Nas — "Qul a'udhu bi Rabbin-nas. Malikin-nas. Ilahin-nas..."
  if (body.contains("qul a'udhu") &&
      (body.contains('rabbin-nas') ||
       body.contains('malikin-nas') ||
       body.contains('ilahin-nas'))) {
    return 'Surah An-Nas';
  }
  // Surah Al-Kafirun — "Qul ya ayyuhal-kafirun..."
  if (body.contains('ayyuhal') && body.contains('kafir')) {
    return 'Surah Al-Kafirun';
  }
  // Surah Al-Mulk — "Tabarakalladhi biyadihil-mulk..."
  if (body.contains('tabarakal-ladhi') ||
      body.contains('tabarakalladhi') ||
      body.contains('tabaraka-l-ladhi')) {
    return 'Surah Al-Mulk';
  }
  // Surah As-Sajdah — "Alif Lam Mim. Tanzilu-l-kitabi..." (distinct from
  // Al-Baqarah 1-5 by the "tanzil" cue right after the muqattaat).
  if (body.startsWith('alif') && body.contains('tanzil')) {
    return 'Surah As-Sajdah';
  }
  // Ayatul Kursi — "Allahu la ilaha illa Huwa-l-Hayyu-l-Qayyum..."
  if (body.contains('qayyum') &&
      (body.contains('hayyu') ||
       body.contains('ilaha illa huwa'))) {
    return 'Ayatul Kursi';
  }
  // Al-Baqarah 285 — "Amanar-Rasulu bima unzila ilaihi..."
  if (body.startsWith('amanar-rasulu') ||
      body.startsWith('amana ar-rasulu') ||
      body.startsWith('amanar rasulu')) {
    return 'Al-Baqarah 285 (Amana ar-Rasool)';
  }
  // Al-Baqarah 286 — "La yukallifullahu nafsan illa wus'aha..."
  if (body.startsWith('la yukallif')) {
    return 'Al-Baqarah 286';
  }
  // First 5 verses of Al-Baqarah — "Alif Lam Mim. Dhalikal-kitabu..."
  if ((body.startsWith('alif-lam-mim') ||
       body.startsWith('alif lam mim')) &&
      body.contains('dhalikal')) {
    return 'Al-Baqarah 1-5 (Alif Lam Mim)';
  }
  // Al-Baqarah 256 — "La ikraha fid-din..."
  if (body.startsWith('la ikraha fid-din') ||
      body.startsWith('la ikraha fi-d-din')) {
    return 'Al-Baqarah 256 (La Ikraha)';
  }
  // Al-Baqarah 257 — "Allahu waliyyul-ladhina amanu..."
  if (body.startsWith('allahu waliyyul') ||
      body.startsWith('allahu waliyy ul-ladhina')) {
    return 'Al-Baqarah 257 (Allahu Waliyy)';
  }
  // Al-Baqarah 284 — "Lillahi ma fis-samawati..."
  if (body.startsWith('lillahi ma fis-samawati') ||
      body.startsWith('lillahi maa fis-samaawaati')) {
    return 'Al-Baqarah 284';
  }

  // ── Famous duas ────────────────────────────────────────────────────────
  // Sayyid al-Istighfar — "Allahumma anta Rabbi... abu'u laka bi-ni'matika..."
  if (body.contains('anta rabbi') &&
      (body.contains("abu'u") || body.contains("abo'u"))) {
    return 'Sayyid al-Istighfar';
  }
  // Hasbunallahu wa ni'mal Wakeel.
  if (body.contains('hasbunallah') &&
      (body.contains('wakil') || body.contains('wakeel'))) {
    return "Hasbunallahu wa ni'mal Wakeel";
  }
  // Salawat Ibrahimiyya — "Allahumma salli 'ala Muhammad... Ibrahim..."
  if (body.contains("salli 'ala muhammad") &&
      (body.contains('ibrahim') || body.contains('ibraheem'))) {
    return 'Salawat Ibrahimiyya (Durood)';
  }

  return '';
}

/// Timing info shown at top of azkar detail screen
// _kTimingInfo removed and replaced with _categoryTiming calls.

const Map<String, _AyahInfo> _kQuranAyahInfo = {
  // ── Al-Fatiha (Bismillah IS ayah 1) ──
  'morning_1': (start: 1, count: 7, bismillahIsAyah: true),
  'evening_1': (start: 1, count: 7, bismillahIsAyah: true),
  // ── Al-Baqarah 2:1-5 ──
  'morning_2': (start: 1, count: 5, bismillahIsAyah: false),
  'evening_2': (start: 1, count: 5, bismillahIsAyah: false),
  // ── Single ayahs (commas are clause separators, number at end only) ──
  'morning_3': (start: 255, count: 1, bismillahIsAyah: false),
  'evening_3': (start: 255, count: 1, bismillahIsAyah: false),
  'morning_4': (start: 256, count: 1, bismillahIsAyah: false),
  'evening_4': (start: 256, count: 1, bismillahIsAyah: false),
  'morning_5': (start: 257, count: 1, bismillahIsAyah: false),
  'evening_5': (start: 257, count: 1, bismillahIsAyah: false),
  'morning_6': (start: 284, count: 1, bismillahIsAyah: false),
  'evening_6': (start: 284, count: 1, bismillahIsAyah: false),
  'morning_7': (start: 285, count: 1, bismillahIsAyah: false),
  'evening_7': (start: 285, count: 1, bismillahIsAyah: false),
  'morning_8': (start: 286, count: 1, bismillahIsAyah: false),
  'evening_8': (start: 286, count: 1, bismillahIsAyah: false),
  // ── Multi-ayah surahs (Bismillah is NOT numbered) ──
  'morning_9': (start: 1, count: 4, bismillahIsAyah: false), // Al-Ikhlas
  'evening_9': (start: 1, count: 4, bismillahIsAyah: false),
  'morning_10': (start: 1, count: 5, bismillahIsAyah: false), // Al-Falaq
  'evening_10': (start: 1, count: 5, bismillahIsAyah: false),
  'morning_11': (start: 1, count: 6, bismillahIsAyah: false), // An-Nas
  'evening_11': (start: 1, count: 6, bismillahIsAyah: false),
};

String _toArabicNum(int n) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((d) => digits[int.parse(d)]).join();
}

String _cleanArabic(String s, {String azkarId = ''}) {
  // Remove footnote markers like [1], (2)
  s = s.replaceAll(RegExp(r'\[\d+\]'), '');
  s = s.replaceAll(RegExp(r'\(\d+\)'), '');
  // Remove leftover bracket characters
  s = s.replaceAll(RegExp(r'[\[\]\(\)\{\}«»]'), '');
  // Normalize any existing ﴿N﴾ markers back to commas (code will re-add correctly)
  s = s.replaceAll(RegExp(r'﴿[٠-٩]+﴾'), '،');
  // Remove Quranic waqf/tajweed marks
  s = s.replaceAll(
    RegExp(
      r'[\u0615-\u061A\u06D6-\u06DC\u06DE-\u06E4\u06E7-\u06E8\u06EA-\u06ED\u08D4-\u08FE\u200B\uE000-\uF8FF]',
    ),
    '',
  );
  // Normalize: convert any existing ۝ back to ، so comma-based logic works uniformly
  s = s.replaceAll('\u06DD', '،');

  final info = _kQuranAyahInfo[azkarId];
  if (info != null && info.count > 1) {
    // ── Multi-ayah Quranic passage: number each ayah ──
    int ayahNum = info.start;

    // Handle Bismillah line: keep on same line with its ayah number
    final nlIdx = s.indexOf('\n');
    if (nlIdx > 0 && info.bismillahIsAyah) {
      // Al-Fatiha: Bismillah IS ayah 1 — marker on same line, then linebreak
      final bismillah = s.substring(0, nlIdx).trim();
      final rest = s.substring(nlIdx).replaceAll(RegExp(r'^\n+'), '');
      s = '$bismillah ﴿${_toArabicNum(ayahNum)}﴾\n$rest';
      ayahNum++;
    } else if (nlIdx > 0) {
      // Other surahs: Bismillah is NOT an ayah — collapse newlines
      final bismillah = s.substring(0, nlIdx).trim();
      final rest = s.substring(nlIdx).replaceAll(RegExp(r'^\n+'), '');
      s = '$bismillah\n$rest';
    }

    // Each ، marks the END of an ayah — place ﴿N﴾ where the comma is
    s = s.replaceAllMapped(RegExp(r'\s*،\s*'), (m) {
      final marker = ' ﴿${_toArabicNum(ayahNum)}﴾ ';
      ayahNum++;
      return marker;
    });
    // Final ayah number at the very end
    s = '${s.trim()} ﴿${_toArabicNum(ayahNum)}﴾';
  } else if (info != null && info.count == 1) {
    // ── Single Quranic ayah: remove commas entirely, ayah number at end ──
    s = s.replaceAll(RegExp(r'\n+'), ' ');
    s = s.replaceAll(RegExp(r'\s*،\s*'), ' ');
    s = '${s.trim()} ﴿${_toArabicNum(info.start)}﴾';
  } else {
    // ── Dua / non-Quranic text: remove commas ──
    s = s.replaceAll(RegExp(r'\s*،\s*'), ' ');
  }

  // Collapse extra whitespace
  return s.replaceAll(RegExp(r'  +'), ' ').trim();
}

/// Patterns that should be highlighted in a distinct color (Bismillah & Isti'adhah).
final _kHighlightPatterns = RegExp(
  r'أَعُوْذُ بِاللّٰهِ مِنَ الشَّيْطَانِ الرَّجِيْمِ[.۝]*'
  r'|أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ[.۝]*'
  r'|أَعُوذُ بِاللَّهِ السَّمِيعِ الْعَلِيمِ مِنَ الشَّيْطَانِ الرَّجِيمِ[.۝]*'
  r'|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ[.۝]*'
  r'|بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ[.۝]*'
  r'|بِسْمِ اللَّهِ الرَّحْمٰنِ الرَّحِيمِ[.۝]*',
);

/// Returns a contextual section label based on the azkar content.
String _sectionLabel(BuildContext context, _Azkar azkar) {
  return AppLocalizations.of(context)?.benefit ?? 'Benefit';
}

/// Builds a RichText widget with Bismillah/Isti'adhah in a distinct color.
Widget _buildStyledArabic(
  String raw,
  TextStyle baseStyle,
  Color highlightColor, {
  String azkarId = '',
  String fontName = '',
}) {
  String cleaned = _cleanArabic(raw, azkarId: azkarId);
  // Force ayah markers ﴿N﴾ to render in Uthmani font (scheherazadeNew) so all
  // font selections show the same ornamental separator with proper numbers.
  final markerStyle = GoogleFonts.scheherazadeNew(
    fontSize: baseStyle.fontSize,
    color: baseStyle.color,
    height: baseStyle.height,
    fontWeight: baseStyle.fontWeight,
  );
  // Tight-height newline to reduce excessive gap from the large line-height
  final tightNewline = baseStyle.copyWith(
    fontSize: (baseStyle.fontSize ?? 32) * 0.4,
    height: 1.0,
  );

  // Splits a text span into pieces, switching style on every ﴿N﴾ marker
  // and rendering '\n' with tightNewline style for reduced vertical gap.
  List<TextSpan> splitMarkers(String text, TextStyle style) {
    final result = <TextSpan>[];
    final re = RegExp(r'﴿[٠-٩]+﴾|\n');
    int last = 0;
    for (final m in re.allMatches(text)) {
      final matched = m.group(0)!;
      if (m.start > last) {
        final chunk = text.substring(last, m.start);
        // Append word joiner before markers so text can't break away from them
        result.add(
          TextSpan(
            text: matched != '\n' ? '$chunk\u2060' : chunk,
            style: style,
          ),
        );
      }
      if (matched == '\n') {
        result.add(TextSpan(text: '\n', style: tightNewline));
      } else {
        // Prefix with word joiner (\u2060) to prevent line-break before marker
        result.add(
          TextSpan(
            text: '\u2060$matched',
            style: markerStyle.copyWith(color: style.color),
          ),
        );
      }
      last = m.end;
    }
    if (last < text.length) {
      result.add(TextSpan(text: text.substring(last), style: style));
    }
    return result;
  }

  final spans = <TextSpan>[];
  int lastEnd = 0;

  final matches = _kHighlightPatterns.allMatches(cleaned).toList();

  for (int i = 0; i < matches.length; i++) {
    final m = matches[i];

    if (m.start > lastEnd) {
      String beforeText = cleaned.substring(lastEnd, m.start).trimRight();
      if (beforeText.isNotEmpty) {
        spans.addAll(splitMarkers('$beforeText\n', baseStyle));
      }
    }

    String highlightedText = m.group(0)!.trim();
    final afterMatch = cleaned.substring(m.end);
    final afterTrimmed = afterMatch.trimLeft();
    final startsWithMarker = afterTrimmed.startsWith('﴿');
    String suffix = (afterTrimmed.isNotEmpty && !startsWithMarker) ? '\n' : '';

    spans.addAll(
      splitMarkers(
        '$highlightedText$suffix',
        baseStyle.copyWith(color: highlightColor, height: 1.3),
      ),
    );
    lastEnd = m.end;
  }

  if (lastEnd < cleaned.length) {
    String remainder = cleaned.substring(lastEnd).trimLeft();
    if (remainder.isNotEmpty) {
      spans.addAll(splitMarkers(remainder, baseStyle));
    }
  }

  // If no matches were found, just use the raw text
  if (spans.isEmpty) {
    spans.addAll(splitMarkers(cleaned, baseStyle));
  }

  // Split spans by newline boundaries into separate Text.rich blocks so we
  // can control inter-line gap precisely (instead of being stuck with the
  // global line-height for newlines).
  final blocks = <List<TextSpan>>[[]];
  for (final span in spans) {
    final text = span.text ?? '';
    if (text.contains('\n')) {
      final parts = text.split('\n');
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) {
          blocks.last.add(TextSpan(text: parts[i], style: span.style));
        }
        if (i < parts.length - 1) {
          blocks.add([]);
        }
      }
    } else {
      blocks.last.add(span);
    }
  }
  Widget buildBlock(List<TextSpan> blockSpans) {
    final textString = blockSpans.map((s) => s.text ?? '').join();
    // Identify header blocks like Bismillah or Isti'adhah which should ideally not wrap
    final isHeader =
        textString.length < 80 &&
        (textString.contains('بِسْمِ') ||
            textString.contains('أَعُوذُ') ||
            textString.contains('أَعُوْذُ'));

    Widget textWidget = Text.rich(
      TextSpan(style: baseStyle, children: blockSpans),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    );

    // Removed the FittedBox-scaleDown wrap that previously fired on any
    // text starting with بِسْمِ or أَعُوذُ — it shrank the whole Arabic
    // block to fit width even when natural wrap would render at the
    // user's chosen font size. Letting it wrap normally keeps font size
    // consistent across all azkar.
    return textWidget;
  }

  final nonEmptyBlocks = blocks.where((b) => b.isNotEmpty).toList();
  if (nonEmptyBlocks.length == 1) {
    return buildBlock(nonEmptyBlocks.first);
  }

  // Multi-block: render each as its own Text.rich with a small gap between
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      for (int i = 0; i < nonEmptyBlocks.length; i++) ...[
        buildBlock(nonEmptyBlocks[i]),
        if (i < nonEmptyBlocks.length - 1) const SizedBox(height: 2),
      ],
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Expand "Quran 2:286" → "Surah Al Baqarah 2:286", etc.
// ─────────────────────────────────────────────────────────────────────────────
String _expandQuranRef(String ref) {
  const surahs = {
    1: 'Al Fatihah',
    2: 'Al Baqarah',
    3: 'Ali Imran',
    4: 'An Nisa',
    5: 'Al Maidah',
    6: 'Al Anam',
    7: 'Al Araf',
    8: 'Al Anfal',
    9: 'At Tawbah',
    10: 'Yunus',
    11: 'Hud',
    12: 'Yusuf',
    13: 'Ar Rad',
    14: 'Ibrahim',
    15: 'Al Hijr',
    16: 'An Nahl',
    17: 'Al Isra',
    18: 'Al Kahf',
    19: 'Maryam',
    20: 'Ta Ha',
    21: 'Al Anbiya',
    22: 'Al Hajj',
    23: 'Al Muminun',
    24: 'An Nur',
    25: 'Al Furqan',
    26: 'Ash Shuara',
    27: 'An Naml',
    28: 'Al Qasas',
    29: 'Al Ankabut',
    30: 'Ar Rum',
    31: 'Luqman',
    32: 'As Sajdah',
    33: 'Al Ahzab',
    34: 'Saba',
    35: 'Fatir',
    36: 'Ya Sin',
    37: 'As Saffat',
    38: 'Sad',
    39: 'Az Zumar',
    40: 'Ghafir',
    41: 'Fussilat',
    42: 'Ash Shura',
    43: 'Az Zukhruf',
    44: 'Ad Dukhan',
    45: 'Al Jathiyah',
    46: 'Al Ahqaf',
    47: 'Muhammad',
    48: 'Al Fath',
    49: 'Al Hujurat',
    50: 'Qaf',
    51: 'Adh Dhariyat',
    52: 'At Tur',
    53: 'An Najm',
    54: 'Al Qamar',
    55: 'Ar Rahman',
    56: 'Al Waqiah',
    57: 'Al Hadid',
    58: 'Al Mujadila',
    59: 'Al Hashr',
    60: 'Al Mumtahanah',
    61: 'As Saf',
    62: 'Al Jumuah',
    63: 'Al Munafiqun',
    64: 'At Taghabun',
    65: 'At Talaq',
    66: 'At Tahrim',
    67: 'Al Mulk',
    68: 'Al Qalam',
    69: 'Al Haqqah',
    70: 'Al Maarij',
    71: 'Nuh',
    72: 'Al Jinn',
    73: 'Al Muzzammil',
    74: 'Al Muddathir',
    75: 'Al Qiyamah',
    76: 'Al Insan',
    77: 'Al Mursalat',
    78: 'An Naba',
    79: 'An Naziat',
    80: 'Abasa',
    81: 'At Takwir',
    82: 'Al Infitar',
    83: 'Al Mutaffifin',
    84: 'Al Inshiqaq',
    85: 'Al Buruj',
    86: 'At Tariq',
    87: 'Al Ala',
    88: 'Al Ghashiyah',
    89: 'Al Fajr',
    90: 'Al Balad',
    91: 'Ash Shams',
    92: 'Al Layl',
    93: 'Ad Duha',
    94: 'Ash Sharh',
    95: 'At Tin',
    96: 'Al Alaq',
    97: 'Al Qadr',
    98: 'Al Bayyinah',
    99: 'Az Zalzalah',
    100: 'Al Adiyat',
    101: 'Al Qariah',
    102: 'At Takathur',
    103: 'Al Asr',
    104: 'Al Humazah',
    105: 'Al Fil',
    106: 'Quraysh',
    107: 'Al Maun',
    108: 'Al Kawthar',
    109: 'Al Kafirun',
    110: 'An Nasr',
    111: 'Al Masad',
    112: 'Al Ikhlas',
    113: 'Al Falaq',
    114: 'An Nas',
  };
  return ref.replaceAllMapped(
    RegExp(r'Quran\s+(\d+)((?::\d[\d\-]*)?)', caseSensitive: false),
    (m) {
      final num = int.tryParse(m.group(1)!) ?? 0;
      final name = surahs[num];
      if (name == null) return m.group(0)!;
      return 'Surah $name ${m.group(1)}${m.group(2)}';
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Rich hadith text — 3 semantic highlight categories
// ─────────────────────────────────────────────────────────────────────────────
Widget _buildRichHadithText(
  String text,
  TextStyle base,
  bool isDark,
  Color accent,
) {
  // ══════════════════════════════════════════════════════════════════════════
  // CATEGORY 1 — Quantitative Gains
  // Specific counts of rewards earned OR sins removed/forgiven.
  // e.g. "one hundred good deeds", "ten sins deducted", "all his sins forgiven"
  // ══════════════════════════════════════════════════════════════════════════
  final quantRx = RegExp(
    // number-word or digit followed by a reward/sin noun
    r'\b(?:one\s+hundred|thirty[-\s]?three|thirty[-\s]?four|ten|seventy|seven|'
    r'thousand|a\s+million|\d{1,4})'
    r'\s+(?:(?:good\s+)?deeds?|sins?|blessings?|times?\s+(?:a\s+day|per\s+day)?|slaves?)\b'
    // sins forgiven/erased (with or without a number)
    r'|\b(?:all|his|her|their|previous|past|minor|major)\s+sins?\s+'
    r'(?:will\s+be\s+)?(?:forgiven|erased|wiped(?:\s+(?:out|away))?|removed|expiated|pardoned)\b'
    // "one hundred times a day" — action phrase
    r'|\bone\s+hundred\s+times?\s+a\s+day(?:\s+will\s+\w+)?\b',
    caseSensitive: false,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // CATEGORY 2 — Protection & Status
  // Active spiritual results: becoming shielded, freed, fulfilling a duty,
  // being saved, guarded, or elevated in status.
  // e.g. "a shield from Satan", "freed from the Fire", "fulfilled his obligation"
  // ══════════════════════════════════════════════════════════════════════════
  final protectRx = RegExp(
    r'\ba\s+shield\s+(?:for\s+(?:him|her|them)\s+)?(?:from|against)\s+\w+'
    r'|\bprotect(?:ed|ion)\s+(?:from|against)\b'
    r'|\bguard(?:ed)?\s+(?:from|against)\b'
    r'|\bno\s+harm\s+(?:will\s+)?(?:befall|come\s+(?:to|near)|touch)\s+(?:him|her|them)\b'
    r'|\bnoth(?:ing|ing)\s+will\s+(?:harm|hurt|touch)\s+(?:him|her|them)\b'
    r'|\bfulfill(?:ed|s)?\s+(?:his|her|the)\s+(?:duty|obligation|right|dhikr|remembrance)\b'
    r'|\bunder\s+the\s+(?:shade|shadow|protection)\s+of\b'
    r'|\bfreed?\s+from\s+the\s+(?:Fire|Hellfire|Hell)\b'
    r'|\benter(?:s|ed)?\s+(?:Paradise|Jannah)\b'
    r'|\bmy\s+intercession\s+will\s+reach\s+him\s+on\s+the\s+Day\s+of\s+Judg(?:e)?ment\b'
    r'|\bintercession\b'
    r'|\bDay\s+of\s+Judg(?:e)?ment\b'
    r'|\bDay\s+of\s+Resurrection\b'
    r'|\bsaved?\s+from\s+the\s+(?:Fire|punishment|torment|Hell)\b'
    r'|\bcounted\s+among\s+those\b'
    r'|\bshade\s+of\s+(?:the\s+)?(?:Throne|His\s+Throne|Allah)\b'
    r'|\bwritten\s+in\s+(?:his|her)?\s*(?:accounts?|record)\b'
    r'|\bdeducted\s+from\s+(?:his|her)?\s*(?:accounts?|record)\b',
    caseSensitive: false,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // CATEGORY 3 — Weight & Comparison
  // Superlative outcomes: this deed outweighs others, is equivalent to,
  // or is described as the best deed possible.
  // e.g. "better than the world and what it contains", "heavier on the scales"
  // ══════════════════════════════════════════════════════════════════════════
  final weightRx = RegExp(
    r'\bbetter\s+than\s+(?:the\s+world|all|what\s+the\s+sun|X)\b'
    r'|\bheavier\s+(?:on\s+the\s+(?:scales?|balance)|in\s+weight)\b'
    r'|\bequivalent\s+to\b'
    r'|\bthe\s+same\s+reward\s+as(?:\s+given\s+for)?\b'
    r'|\boutweigh(?:s|ed)?\b'
    r'|\bmanumitting(?:\s+\w+){0,2}\s+slaves?\b'
    r'|\bNobody\s+will\s+be\s+able\s+to\s+do\s+a\s+better\s+deed\b'
    r'|\bno\s+(?:deed|act|prayer|action)\s+(?:is|can\s+be)\s+(?:better|greater)\b'
    r'|\bgreater\s+(?:reward|in\s+weight)\s+than\b'
    r'|\bworth\s+(?:more\s+than|as\s+much\s+as)\b'
    r'|\bsurpass(?:es|ed)?\b',
    caseSensitive: false,
  );

  final allMatches = <({int start, int end, String type})>[];
  for (final m in quantRx.allMatches(text))
    allMatches.add((start: m.start, end: m.end, type: 'quant'));
  for (final m in protectRx.allMatches(text))
    allMatches.add((start: m.start, end: m.end, type: 'protect'));
  for (final m in weightRx.allMatches(text))
    allMatches.add((start: m.start, end: m.end, type: 'weight'));
  allMatches.sort((a, b) => a.start.compareTo(b.start));

  // Remove overlaps — keep earlier (higher-priority) match
  final filtered = <({int start, int end, String type})>[];
  for (final m in allMatches) {
    if (filtered.isEmpty || m.start >= filtered.last.end) filtered.add(m);
  }

  if (filtered.isEmpty) return Text(text, style: base);

  final spans = <InlineSpan>[];
  int pos = 0;

  for (final m in filtered) {
    if (m.start > pos)
      spans.add(TextSpan(text: text.substring(pos, m.start), style: base));
    final seg = text.substring(m.start, m.end);

    switch (m.type) {
      case 'quant':
        // 🟡 Amber/gold pill — quantitative: counts of deeds, sins, rewards
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFD4AF37,
                ).withValues(alpha: isDark ? 0.22 : 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                seg,
                style: base.copyWith(
                  color:
                      isDark
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF8B5D00),
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ),
        );

      case 'protect':
        // 🟢 Teal pill — protection & status: spiritual outcomes
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                seg,
                style: base.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ),
        );

      default: // weight
        // 🔵 Bold italic — weight & comparison: superlatives, equivalences
        spans.add(
          TextSpan(
            text: seg,
            style: base.copyWith(
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
    }
    pos = m.end;
  }

  if (pos < text.length)
    spans.add(TextSpan(text: text.substring(pos), style: base));

  return RichText(text: TextSpan(style: base, children: spans));
}

// ─────────────────────────────────────────────────────────────────────────────
// Beautiful Display Card for Azkaar
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// Reward Counters — floating overlay showing hasanaat, sins, slaves
// ─────────────────────────────────────────────────────────────────────────────
class _RewardCounters extends StatelessWidget {
  final int tapCount;
  final int pointsToday;

  const _RewardCounters({required this.tapCount, required this.pointsToday});

  @override
  Widget build(BuildContext context) {
    // Hadith-based rewards per tap:
    // - Hasanaat: 10 per good deed (Sahih Muslim 131)
    // - Sins removed: 1 per dhikr rep (SubhanAllahi wa bihamdihi — Bukhari 6405)
    // - Slaves freed: 1 per 10 reps of La ilaha illallah (Bukhari 6403)
    final hasanaat = tapCount * 10;
    final sinsRemoved = tapCount;
    final slavesFreed = tapCount ~/ 10;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Reward pills on the left
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _rewardPill(
              icon: Icons.star_rounded,
              value: '+$hasanaat',
              color: const Color(0xFFD4AF37),
            ),
            const SizedBox(width: 6),
            _rewardPill(
              icon: Icons.remove_circle_outline_rounded,
              value: '-$sinsRemoved',
              color: const Color(0xFF2BAE99),
            ),
            if (slavesFreed > 0) ...[
              const SizedBox(width: 6),
              _rewardPill(
                icon: Icons.broken_image_outlined,
                value: '$slavesFreed',
                color: const Color(0xFF9B59B6),
              ),
            ],
          ],
        ),
        // Points badge on the right
        if (pointsToday > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SabiqCoin(size: 18),
                const SizedBox(width: 4),
                Text(
                  '+$pointsToday ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF92620A),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _rewardPill({
    required IconData icon,
    required String value,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _AzkarCard extends StatelessWidget {
  final _Azkar azkar;
  final int currentCount;
  final int targetCount;
  final bool isComplete;
  final bool isFavorite;
  final _DhikrSettings settings;
  final int pointsToday;
  /// Today's animation `key` picked from the DB pool — null = fall back
  /// to the hardcoded ID-based mapping inside `_buildIllustration`.
  final String? animationKeyOverride;
  final VoidCallback onReset;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  /// When true, suppress the illustration block inside this card — the
  /// caller is rendering it as a sticky header above this card instead
  /// (Free-Illustration mode).
  final bool forceHideIllustration;

  const _AzkarCard({
    required this.azkar,
    required this.currentCount,
    required this.targetCount,
    required this.isComplete,
    required this.isFavorite,
    required this.settings,
    this.pointsToday = 0,
    this.animationKeyOverride,
    required this.onReset,
    required this.onFavorite,
    required this.onShare,
    this.forceHideIllustration = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = settings.darkMode;
    // Card body color:
    //   Morning/Evening → Y4 honey wash (matches the AppBar gradient and the
    //     in-banner text-illustration cream so the screen reads as ONE warm
    //     surface end-to-end). Reverting an earlier "force white" pass that
    //     made evening_16-style cards show a visible white stripe across the
    //     illustration band.
    //   All other categories → pure white. They don't have a cream AppBar
    //     to match, and the honey wash looked off for azkar without a 260px
    //     illustration covering the top.
    final isAkhirahCat =
        azkar.category == 'morning' || azkar.category == 'evening';
    final kCardBg = isDark
        ? const Color(0xFF1E1E1E)
        : (isAkhirahCat ? Y4.bg : Colors.white);
    final kText =
        isDark ? Colors.white : SettingsService.instance.config.dashText;
    final kSub = isDark ? Colors.grey.shade400 : const Color(0xFF8E8E93);
    final kPrimary = const Color(0xFFFFC83D);

    String rawRef =
        azkar.reference
            .replaceAll('Hisnul Muslim, Chapter: ', '')
            .replaceAll('Hisnul Muslim, ', '')
            .trim();
    String bottomRef = '';

    // Parse references at the end, either in brackets/parenthesis OR matching a known Hadith/Quran keyword
    void extractReference(
      String source,
      Function(String newSource, String extractedRef) onExtract,
    ) {
      if (source.isEmpty) return;

      // 1. Check for brackets or parentheses at the end
      final bracketMatch = RegExp(
        r'(\(|\[)([^\[\(\)\]]+)(\)|\])\s*$',
      ).firstMatch(source);
      if (bracketMatch != null) {
        final ref = bracketMatch.group(2)?.trim() ?? '';
        final cleanSource =
            source
                .substring(0, bracketMatch.start)
                .replaceAll(RegExp(r'[-,\.,\|\s]+$'), '')
                .trim();
        onExtract(cleanSource, ref);
        return;
      }

      // 2. Check for known Hadith keywords — REQUIRES a digit after the
      // collection name (e.g. "Sahih Muslim 591", "Abu Dawud 5074") so the
      // matcher doesn't mis-fire on English nouns like "Muslim" or "Quran"
      // when they appear mid-narration (which was clipping benefit text at
      // "…as a Muslim);" and similar).
      final keywordMatch = RegExp(
        r'(?:[-,\.,\s]+|^)((?:Sahih\s)?(?:Muslim|Bukhari|Abu Dawud|Tirmidhi|Ibn Majah|Nasai|Ahmad|Quran|Surah)\s+\d.*)$',
        caseSensitive: false,
      ).firstMatch(source);
      if (keywordMatch != null) {
        final ref = keywordMatch.group(1)?.trim() ?? '';
        final cleanSource =
            source
                .substring(0, keywordMatch.start)
                .replaceAll(RegExp(r'[-,\.,\|\s]+$'), '')
                .trim();
        onExtract(cleanSource, ref);
        return;
      }
    }

    extractReference(rawRef, (clean, ref) {
      rawRef = clean.replaceAll(RegExp(r'^\||\|$'), '').trim();
      bottomRef = ref;
    });

    String cleanReward = azkar.reward.trim();
    extractReference(cleanReward, (clean, ref) {
      cleanReward =
          clean
              .replaceAll(RegExp(r'^\|'), '')
              .replaceAll(RegExp(r'\|$'), '')
              .trim();
      if (bottomRef.isEmpty) bottomRef = ref;
    });
    // Strip pipe-separated reference (e.g. "Knower of the Unseen | At-Tirmidhi 3392")
    if (cleanReward.contains('|')) {
      final pipeParts = cleanReward.split('|');
      cleanReward = pipeParts.first.trim();
      final pipedRef = pipeParts.skip(1).join(' ').trim();
      if (bottomRef.isEmpty && pipedRef.isNotEmpty) bottomRef = pipedRef;
    }
    // Hide the Benefit section entirely when its body is just a "no
    // specific virtue / no specific condition" disclaimer (e.g. the
    // 40 Rabbana Duas all carry this note). Telling the user "this
    // dhikr has no special reward" is the opposite of motivating, so
    // we drop both the reward AND the hadith-full text if either is
    // the disclaimer, so the header conditional further down also
    // sees them as empty and the whole "Benefit" block disappears.
    bool _isPlaceholderBenefit(String s) {
      if (s.trim().isEmpty) return true;
      final patterns = [
        // direct disclaimer phrasing
        RegExp(r'no\s+specific\s+(virtue|condition|reward|merit|fadl|narration)',
            caseSensitive: false),
        // the literal anchor on the Rabbana set
        RegExp(r'(40|forty)\s+rabbana', caseSensitive: false),
        // common opening phrase used by the import
        RegExp(r'there\s+is\s+no\s+specific', caseSensitive: false),
        RegExp(r'^\s*note\s*:\s*there\s+is\s+no', caseSensitive: false),
      ];
      for (final p in patterns) {
        if (p.hasMatch(s)) return true;
      }
      return false;
    }
    if (_isPlaceholderBenefit(cleanReward)) {
      cleanReward = '';
    }
    String cleanHadithFull = azkar.hadithFull;
    if (_isPlaceholderBenefit(cleanHadithFull)) {
      cleanHadithFull = '';
    }

    // Resolve illustration up-front so we can both render it AND skip the
    // 260px container entirely when this azkar has nothing mapped (avoids
    // an empty/blank illustration block for the new screenshot-imported
    // categories that don't yet have animations tagged in admin).
    final illustrationKey =
        animationKeyOverride ?? _pickIllustration(azkar.id);
    final hasIllustration = illustrationKey != 'none';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Illustration + pts badge overlaid at bottom-right ──
        if (settings.showIllustration && hasIllustration && !forceHideIllustration)
          SizedBox(
            height: 260,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                _buildIllustration(
                  azkarId: azkar.id,
                  progress:
                      targetCount == 0
                          ? 0.0
                          : (currentCount / targetCount).clamp(0.0, 1.0),
                  isComplete: isComplete,
                  tapCount: currentCount,
                  pointsToday: pointsToday,
                  animationKeyOverride: animationKeyOverride,
                ),
                if (pointsToday > 0)
                  Positioned(
                    bottom: 10,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SabiqCoin(size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '+$pointsToday ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF92620A),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // ── Motivational tagline capsule — bold, eye-catching pill ──
        Builder(
          builder: (ctx) {
            final tagline = _pickTagline(azkar.id);
            if (tagline.isEmpty) return const SizedBox.shrink();
            final tagColor = _pickTaglineColor(azkar.id, isDark);
            return Container(
              width: double.infinity,
              color: kCardBg,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    // SOLID fill in the illustration's accent color so the
                    // tagline pops off the cream/dark background — light
                    // alpha pills were getting overlooked.
                    color: tagColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: tagColor.withValues(alpha: 0.40),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.30 : 0.10,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    tagline,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // ── Card section with smooth top transition ──
        Container(
          decoration: BoxDecoration(color: kCardBg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // ── Main Text Content ──
              // For segmented (compound) dhikr, swap arabic/translit/translation
              // with the current phrase so the user always sees what they're
                // reciting *right now*. The overall counter still drives
                // completion (sum of phrase counts), but the display follows
                // whichever phrase the current tap count falls into.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Builder(builder: (_) {
                  final slice = azkar.phraseAt(currentCount);
                  final displayArabic = slice?.phrase.arabic ?? azkar.arabic;
                  final displayTranslit =
                      slice?.phrase.transliteration ?? azkar.transliteration;
                  final displayTranslation =
                      slice?.phrase.translation ?? azkar.translation;
                  return Column(
                  children: [
                    if (slice != null) ...[
                      // "Phrase 2 of 3 · 12/33" badge so the user knows
                      // which segment they're on and how many taps remain.
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: kPrimary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: kPrimary.withValues(alpha: 0.35),
                              width: 1),
                        ),
                        child: Text(
                          'Phrase ${slice.index + 1} of ${azkar.phrases!.length}  ·  ${slice.countInPhrase}/${slice.phrase.count}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        // Key on phrase index so AnimatedSwitcher fires only
                        // on phrase boundary crossings, not every tap.
                        key: ValueKey<int>(slice?.index ?? -1),
                        child: _buildStyledArabic(
                          displayArabic,
                          _kArabicFonts[settings.arabicFontIdx.clamp(
                                0,
                                _kArabicFonts.length - 1,
                              )]
                              .style(
                                settings.arabicFontSize,
                                kText,
                                2.2,
                                FontWeight.w700,
                              ),
                          isDark
                              ? const Color(0xFFFFC83D)
                              : const Color(0xFFFFC83D),
                          azkarId: azkar.id,
                          fontName:
                              _kArabicFonts[settings.arabicFontIdx.clamp(
                                    0,
                                    _kArabicFonts.length - 1,
                                  )]
                                  .name,
                        ),
                      ),
                    ),
                    if (settings.showTransliteration) ...[
                      const SizedBox(height: 14),
                      Text(
                        displayTranslit,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: settings.translationFontSize,
                          fontWeight: FontWeight.w600,
                          color: kPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (settings.showTranslation) ...[
                      const SizedBox(height: 6),
                      Text(
                        displayTranslation,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: settings.translationFontSize,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.88)
                                  : SettingsService.instance.config.dashText,
                          height: 1.65,
                        ),
                      ),
                    ],
                    // "Open in Quran Reader" button for full-Surah azkar
                    // (Sleep #19/#20). Deep-links to the existing QuranScreen
                    // so we don't have to hand-paste 30 verses of Qur'an.
                    if (azkar.quranSurah != null) ...[
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QuranScreen(
                                initialSurah: azkar.quranSurah!,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.menu_book_rounded, size: 20),
                        label: Text(
                          'Open Surah ${azkar.quranSurah} in Reader',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ],
                );
                }),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),

        // ══════════════════════════════════════════════════════════════════
        // Unified bottom section — Benefit, Hadith, Reference
        // ══════════════════════════════════════════════════════════════════
        if (cleanReward.isNotEmpty ||
            cleanHadithFull.isNotEmpty ||
            rawRef.isNotEmpty ||
            bottomRef.isNotEmpty)
          Builder(
            builder: (context) {
              // Match kCardBg above: cream for Morning/Evening, white for the
              // rest. Keeps the bottom Benefit/Hadith section on one surface
              // with the body above it instead of introducing a colour seam.
              final List<Color> sectionGrad =
                  isDark
                      ? [const Color(0xFF1A1A1A), const Color(0xFF1E1E1E)]
                      : (isAkhirahCat ? [Y4.bg, Y4.bg] : [Colors.white, Colors.white]);
              final textColor =
                  isDark ? Colors.white.withValues(alpha: 0.85) : kText;
              final subColor =
                  isDark
                      ? Colors.white.withValues(alpha: 0.55)
                      : kSub.withValues(alpha: 0.90);
              final labelColor =
                  isDark ? const Color(0xFF5EADDB) : const Color(0xFFFFC83D);
              final dividerColor =
                  isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08);

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: sectionGrad,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section label ──
                    // Mirror the body-render gates exactly: only show the
                    // "Benefit" header when at least one body block below
                    // will actually render. The hadith body is skipped for
                    // morning_4/5 + evening_4/5 (reward already covers it),
                    // so when those rows have an empty reward we'd
                    // otherwise show an empty header.
                    Builder(builder: (_) {
                      final hadithBodyRenders =
                          cleanHadithFull.isNotEmpty &&
                          azkar.id != 'morning_4' &&
                          azkar.id != 'morning_5' &&
                          azkar.id != 'evening_4' &&
                          azkar.id != 'evening_5';
                      if (cleanReward.isEmpty && !hadithBodyRenders) {
                        return const SizedBox.shrink();
                      }
                      return Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 15,
                            color: labelColor.withValues(alpha: 0.70),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _sectionLabel(context, azkar),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: labelColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      );
                    }),

                    // ── Benefit/Reward text ──
                    if (cleanReward.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Builder(builder: (_) {
                        // Highlight key phrases
                        const highlights = [
                          'Day of Judgment',
                          'Day of Resurrection',
                          'Jannah',
                          'Paradise',
                          'Hellfire',
                          'forgiven',
                          'protection',
                        ];
                        String? match;
                        for (final h in highlights) {
                          if (cleanReward.contains(h)) { match = h; break; }
                        }
                        if (match != null) {
                          final idx = cleanReward.indexOf(match);
                          final before = cleanReward.substring(0, idx);
                          final after = cleanReward.substring(idx + match.length);
                          return RichText(
                            text: TextSpan(
                              style: GoogleFonts.lora(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(text: before),
                                TextSpan(
                                  text: match,
                                  style: GoogleFonts.lora(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: labelColor,
                                    height: 1.5,
                                  ),
                                ),
                                TextSpan(text: after),
                              ],
                            ),
                          );
                        }
                        return Text(
                          cleanReward,
                          style: GoogleFonts.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            height: 1.5,
                          ),
                        );
                      }),
                    ],

                    // ── Hadith text (skip for azkar where reward already covers it) ──
                    if (cleanHadithFull.isNotEmpty &&
                        azkar.id != 'morning_4' && azkar.id != 'morning_5' &&
                        azkar.id != 'evening_4' && azkar.id != 'evening_5') ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Container(height: 0.5, color: dividerColor),
                      ),
                      ...() {
                        final parts =
                            cleanHadithFull
                                .split('\n\n')
                                .where((p) => p.trim().isNotEmpty)
                                .toList();
                        final widgets = <Widget>[];
                        for (int i = 0; i < parts.length; i++) {
                          widgets.add(
                            _buildRichHadithText(
                              parts[i].trim(),
                              GoogleFonts.outfit(
                                fontSize: 15.5,
                                color: textColor,
                                height: 1.7,
                              ),
                              isDark,
                              labelColor,
                            ),
                          );
                          if (i < parts.length - 1) {
                            widgets.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Container(
                                  height: 0.5,
                                  color: dividerColor,
                                ),
                              ),
                            );
                          }
                        }
                        return widgets;
                      }(),
                    ],

                    // ── Reference ──
                    // Pre-compute the actual reference parts (filtered to
                    // those containing a digit). If the list is empty,
                    // we skip the whole section — including the heading
                    // — so azkar without citations don't show an empty
                    // "Reference" header.
                    Builder(builder: (_) {
                      final refParts = <String>[];
                      final combined = rawRef.isNotEmpty
                          ? (bottomRef.isNotEmpty
                              ? '$rawRef | $bottomRef'
                              : rawRef)
                          : (bottomRef.isNotEmpty
                              ? bottomRef
                              : azkar.reference);
                      for (final part in combined.split('|')) {
                        final t = part.trim();
                        if (t.isNotEmpty && t.contains(RegExp(r'\d'))) {
                          refParts.add(_expandQuranRef(t));
                        }
                      }
                      if (refParts.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(height: 0.5, color: dividerColor),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.link_rounded,
                                size: 13,
                                color: labelColor.withValues(alpha: 0.70),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppLocalizations.of(context)?.reference ??
                                    'Reference',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: labelColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...refParts.map(
                            (p) => Text(
                              p,
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                color: subColor,
                                fontWeight: FontWeight.w500,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Maps azkar ID → illustration name. Supports both new IDs (morning_1..33,
/// evening_1..32) and old IDs (morning_lwa_*, evening_lwa_*, general, etc.).
String _pickIllustration(String rawId) {
  final id = rawId.toLowerCase().replaceFirst('evening_fixed_', 'evening_lwa_');

  // ── New morning/evening IDs (by content) ──
  // Al-Fateha & opening of Baqarah — dua scene
  if (id == 'morning_1') return 'benefit_morning_1';
  if (id == 'evening_1') return 'benefit_evening_1';
  if (id == 'morning_2' || id == 'evening_2') return 'baqarah_shield';
  // Ayat al-Kursi
  if (id == 'morning_3' || id == 'evening_3') return 'shield';
  if (id == 'morning_4' || id == 'evening_4') return 'dua_scene';
  if (id == 'morning_5' || id == 'evening_5') return 'dua_scene';
  if (id == 'morning_6' || id == 'evening_6') return 'night_peace';
  // Last verses of Baqarah — protection from evils (text card; replaced
  // the previous "two red evil eyes" illustration which felt too intense).
  if (id == 'morning_7' || id == 'evening_7') return 'benefit_text_7';
  if (id == 'morning_8' || id == 'evening_8') return 'baqarah_burden';
  // Ikhlas, Falaq, Nas
  if (id == 'morning_9' || id == 'evening_9') return 'quran_complete';
  if (id == 'morning_10' || id == 'evening_10') return 'falaq_shield';
  if (id == 'morning_11' || id == 'evening_11') return 'dua_hands';
  // Sovereignty (morning) & Fitrah (morning) — sunrise scene
  if (id == 'morning_12' || id == 'morning_13') return 'dawn';
  // Sovereignty & Fitrah (evening) — nighttime scene
  if (id == 'evening_13') return 'night_peace';
  // Sovereignty evening — text-based dominion declaration
  if (id == 'evening_12') return 'evening_sovereignty';
  // By Your Leave
  if (id == 'morning_14' || id == 'evening_14') return 'cycle';
  // Gratitude
  if (id == 'morning_16' || id == 'evening_16') return 'benefit_text_16';
  // Gratitude fulfilled — tree + overlay text
  if (id == 'morning_15' || id == 'evening_15') return 'cycle';
  // Raditu billahi — door of divine pleasure opening
  if (id == 'morning_18' || id == 'evening_18') return 'noor_door';
  // Well-being / Afiyah — 6 direction protection
  if (id == 'morning_19' || id == 'evening_19') return 'afiyah_guard';
  // SubhanAllah 'adada khalqihi — cosmic weight
  if (id == 'morning_20' || id == 'evening_20') return 'heavy_scales';
  // Divine Praise — reward awaits with Allah (morning_17 = evening_17)
  if (id == 'morning_17' || id == 'evening_17') return 'benefit_text_17';
  // Bismillah protection — invincible name
  if (id == 'morning_21' || id == 'evening_21') return 'invincible';
  // Refuge from shirk — shield/protection
  if (id == 'morning_22' || id == 'evening_22') return 'shield';
  // Perfect words — invincible name
  if (id == 'morning_23' || id == 'evening_23') return 'invincible';
  // Knower of unseen — repelling light
  // Knower of the Unseen — text card (replaced "two red eyes" repelling).
  if (id == 'morning_24' || id == 'evening_24') return 'benefit_text_24';
  // Ya Hayyu Ya Qayyum — cradled heart
  if (id == 'morning_25' || id == 'evening_25') return 'blinking_eyes';
  // Sayyid al-Istighfar — heart purification
  if (id == 'morning_26' || id == 'evening_26') return 'doors';
  // Freed from Hellfire — freedom flame
  if (id == 'morning_27' || id == 'evening_27') return 'flame';
  // Health body/hearing/sight — three vessels
  if (id == 'morning_28' || id == 'evening_28') return 'vessels';
  // Hasbiyallahu — seven pillars
  if (id == 'morning_29' || id == 'evening_29') return 'pillars';
  // Bless your day (morning only #30)
  if (id == 'morning_30') return 'blessings';
  // La ilaha illallah 100x — unparalleled scales
  if (id == 'morning_31' || id == 'evening_30') return 'scales';
  // SubhanAllah wa bihamdihi 100x — ocean of forgiveness
  if (id == 'morning_32' || id == 'evening_31') return 'ocean';
  // Durood Ibrahim (evening #32) — intercession
  if (id == 'evening_32' || id == 'morning_33') return 'salawat_intercession';

  // ── Old IDs (morning_lwa_*, evening_lwa_*, general categories) ──
  if (id == 'morning_lwa_1' ||
      id == 'evening_lwa_1' ||
      id.contains('ayat_kursi') ||
      id.contains('ayat-kursi') ||
      id.contains('ayatul_kursi') ||
      id.contains('ayatul-kursi')) {
    return 'shield';
  }
  if (id == 'morning_lwa_2' ||
      id == 'evening_lwa_2' ||
      id.contains('three_quls') ||
      id.contains('3_quls')) {
    return 'three_quls';
  }
  if (id == 'morning_lwa_3' ||
      id == 'evening_lwa_3' ||
      id.contains('sayyid_istighfar') ||
      id.contains('sayyid-istighfar')) {
    return 'doors';
  }
  if (id == 'morning_lwa_4' ||
      id == 'evening_lwa_4' ||
      id.contains('anxiety') ||
      id.contains('hamm_hazan')) {
    return 'chains';
  }
  if (id == 'morning_lwa_5' ||
      id == 'evening_lwa_5' ||
      id.contains('dua_afiyah') ||
      id.contains('wellbeing')) {
    return 'six_wards';
  }
  if (id == 'morning_lwa_6' ||
      id == 'evening_lwa_6' ||
      id.contains('four_evils') ||
      id.contains('4_evils')) {
    return 'repelling';
  }
  if (id == 'morning_lwa_7' ||
      id == 'evening_lwa_7' ||
      id.contains('entrust') ||
      id.contains('ya_hayyu')) {
    return 'heart';
  }
  if (id == 'morning_lwa_8' ||
      id == 'evening_lwa_8' ||
      id.contains('shukr') ||
      id.contains('gratitude') ||
      id.contains('nimat')) {
    return 'vessel';
  }
  if (id == 'morning_lwa_9' ||
      id == 'evening_lwa_9' ||
      id.contains('fitrah') ||
      id.contains('tawhid')) {
    return 'dawn';
  }
  if (id == 'morning_lwa_10' ||
      id == 'evening_lwa_10' ||
      id.contains('praise_morning') ||
      id.contains('uthni')) {
    return 'ripples';
  }
  if (id == 'morning_lwa_11' ||
      id == 'evening_lwa_11' ||
      id.contains('good_day') ||
      id.contains('khayr_yawm')) {
    return 'path';
  }
  if (id == 'morning_lwa_12' ||
      id == 'evening_lwa_12' ||
      id.contains('bless_day') ||
      id.contains('bless_evening') ||
      id.contains('fath') ||
      id.contains('barakah_yawm')) {
    return 'blessings';
  }
  if (id == 'morning_lwa_13' ||
      id == 'evening_lwa_13' ||
      id.contains('freed_hellfire') ||
      id.contains('ush_hidu')) {
    return 'flame';
  }
  if (id == 'morning_lwa_14' ||
      id == 'evening_lwa_14' ||
      id.contains('bika_asbahna') ||
      id.contains('nushur')) {
    return 'cycle';
  }
  if (id == 'morning_lwa_15' ||
      id == 'evening_lwa_15' ||
      id.contains('afini_badani') ||
      id.contains('good_health')) {
    return 'vessels';
  }
  if (id == 'morning_lwa_16' ||
      id == 'evening_lwa_16' ||
      id.contains('hasbiyallah') ||
      id.contains('arsh_azeem')) {
    return 'pillars';
  }
  if (id == 'morning_lwa_17' ||
      id == 'evening_lwa_17' ||
      id.contains('raditu_billah') ||
      id.contains('pleased_allah')) {
    return 'hand';
  }
  if (id == 'morning_lwa_18' ||
      id == 'evening_lwa_18' ||
      id.contains('la_yadurru') ||
      id.contains('bismillah_protect')) {
    return 'invincible';
  }
  if (id == 'morning_lwa_19' ||
      id == 'evening_lwa_19' ||
      id.contains('subhanallahi_wabihamdih') ||
      id.contains('subhanallahi_wa_bihamdih')) {
    return 'ocean';
  }
  if (id == 'morning_lwa_20' ||
      id == 'evening_lwa_20' ||
      id == 'la_ilaha_illallah' ||
      id == 'post_prayer_la_ilaha' ||
      id.contains('unparalleled_reward')) {
    return 'scales';
  }
  if (id == 'morning_lwa_21' ||
      id == 'evening_lwa_21' ||
      id == 'subhanallah' ||
      id == 'alhamdulillah' ||
      id == 'allahu_akbar' ||
      id == 'post_prayer_subhanallah' ||
      id == 'post_prayer_alhamdulillah' ||
      id == 'post_prayer_allahu_akbar' ||
      id.contains('sleeping_tasbih')) {
    return 'glory';
  }
  if (id == 'morning_lwa_22' ||
      id == 'evening_lwa_22' ||
      id == 'salawat_ibrahimiyya' ||
      id == 'salawat_simple' ||
      id == 'salawat_friday' ||
      id.contains('salawat')) {
    return 'salawat';
  }
  if (id == 'evening_lwa_23' || id.contains('kalimat_taammat'))
    return 'invincible';
  if (id == 'morning_lwa_23' ||
      id == 'astaghfirullah' ||
      id == 'istighfar_extended' ||
      id.contains('astaghfiru') ||
      id.contains('istighfar') ||
      id.contains('forgive')) {
    return 'doors';
  }
  if (id == 'morning_lwa_24' ||
      id == 'evening_lwa_24' ||
      id.contains('adada_khalqih') ||
      id.contains('cosmic_weight')) {
    return 'cosmic';
  }

  return 'none'; // No illustration for unmapped azkar
}

/// Returns the top gradient color of each illustration to fill behind the app bar.
Color _illustrationTopColor(String azkarId, bool isDark) {
  if (isDark) return const Color(0xFF121212);
  // Morning/Evening: Y4 honey wash so the AppBar matches the cream
  //   Scaffold + body card behind it (continuous warm surface, with the
  //   white illustration banner sitting as a distinct card on top).
  // Other categories: white to match their white Scaffold + body card.
  final isAkhirah =
      azkarId.startsWith('morning_') || azkarId.startsWith('evening_');
  return isAkhirah ? Y4.bg : Colors.white;
}

// =============================================================================
// Illustration picker — returns the right visual for each Azkar
// =============================================================================
Widget _buildIllustration({
  required String azkarId,
  required double progress,
  required bool isComplete,
  required int tapCount,
  int pointsToday = 0,
  String? animationKeyOverride,
}) {
  // If the screen passed an explicit key (looked up from the new DB
  // azkar_item_animations junction), use it. Otherwise fall back to the
  // hardcoded ID-to-key map for legacy data not yet tagged in admin.
  final ill = animationKeyOverride ?? _pickIllustration(azkarId);
  Widget w(
    Widget Function({
      required double progress,
      required bool isComplete,
      required int tapCount,
      required int pointsToday,
    })
    ctor,
  ) => ctor(
    progress: progress,
    isComplete: isComplete,
    tapCount: tapCount,
    pointsToday: pointsToday,
  );

  return switch (ill) {
    'dua_scene' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Begin your day in surrender to Allah, nothing else matters more',
        subtitle: 'Daily Devotion',
        completedSubtitle: 'May Allah accept your devotion',
        accentColor: const Color(0xFF14B8A6),
      ),
    ),
    'benefit_morning_1' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Allah responds to every verse you recite, "This is for My servant, and My servant shall have what he has asked for"',
        subtitle: 'Sahih Muslim 395',
        completedSubtitle: 'Allah has answered your call',
        accentColor: const Color(0xFFD4A843),
      ),
    ),
    'benefit_evening_1' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Allah responds to every verse you recite, "This is for My servant, and My servant shall have what he has asked for"',
        subtitle: 'Sahih Muslim 395',
        completedSubtitle: 'Allah has answered your call',
        accentColor: const Color(0xFF6366F1),
      ),
    ),
    'shield' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _ProtectionShield(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'quran_complete' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _QuranComplete(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'dawn_dusk' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _DawnDusk(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'falaq_shield' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _AlFalaqShield(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'dua_hands' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _DuaHands(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'three_quls' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _ThreeQuls(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'gates' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _GatesOfJannah(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'chains' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BreakingChains(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'afiyah_guard' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _AfiyahGuard(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'six_wards' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _SixWards(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'repelling' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _RepellingLight(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'blinking_eyes' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BlinkingEyes(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'heart' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _CradledHeart(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'benefit_text_16' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText:
            'You have fulfilled your obligation of giving thanks for the entire day or night',
        subtitle: 'Abu Dawud 5073',
        completedSubtitle: 'May Allah make you among the grateful',
        accentColor: const Color(0xFF14B8A6),
      ),
    ),
    'vessel' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _OverflowingVessel(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'dawn' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _RisingDawn(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'ripples' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _PraiseRipples(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'path' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _GlowingPath(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'blessings' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _FiveBlessings(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'flame' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _FreedomFlame(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'cycle' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _CycleOfReturn(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'vessels' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _ThreeVessels(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'pillars' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _SevenPillars(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'noor_door' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _NoorDoor(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'hand' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _GuidingHand(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'invincible' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _InvincibleName(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'ocean' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _OceanOfForgiveness(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'scales' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _UnparalleledScales(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'glory' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _SunriseGlory(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'salawat' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText:
            '10 blessings descend upon you from Allah for every single Salawat',
        subtitle: 'Prophet Muhammad \uFDFA',
        completedSubtitle: 'May Allah accept your Salawat',
        accentColor: const Color(0xFFEC4899),
      ),
    ),
    'salawat_intercession' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'My intercession will reach him on the Day of Judgment',
        highlightPhrase: 'Day of Judgment',
        subtitle: 'At-Tabarani, Sahih Al-Jaami 6357',
        completedSubtitle: 'May you receive his \uFDFA intercession',
        accentColor: const Color(0xFFEC4899),
      ),
    ),
    'benefit_text_17' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText:
            'Angels couldn\'t record its reward, Allah says He will reward it Himself',
        subtitle: 'Ibn Majah 3801',
        completedSubtitle: 'May Allah reward you beyond measure',
        accentColor: const Color(0xFF6B4EE6),
      ),
    ),
    'benefit_text_7' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText:
            'Whoever recites the last two verses of Al-Baqarah at night, they will suffice him',
        highlightPhrase: 'suffice him',
        subtitle: 'Sahih al-Bukhari 4008',
        completedSubtitle: 'Protected by the closing verses of Al-Baqarah',
        accentColor: const Color(0xFF7A8C3A), // Y4.primary sage
      ),
    ),
    'benefit_text_24' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText:
            'Seek refuge in Allah from the evil within yourself and from every creature',
        highlightPhrase: 'every creature',
        subtitle: 'Sunan At-Tirmidhi 3392',
        completedSubtitle: 'Sheltered by the Knower of the Unseen',
        accentColor: const Color(0xFF4D5C20), // Y4.primaryDeep — deeper sage
      ),
    ),
    // ── Duas before Sleep — text-based benefit illustrations ──────────────
    // Sourced from each azkar's hadith reward text. Repeated `night_peace`
    // across every sleep dua was visually monotonous; these surface the
    // unique benefit of each recitation instead.
    'benefit_sleep_kafirun' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'A declaration of freedom from shirk — your faith made firm as you sleep',
        highlightPhrase: 'freedom from shirk',
        subtitle: 'Sunan Abi Dawud 5055',
        completedSubtitle: 'Sleep declared upon tawhid',
        accentColor: const Color(0xFF6366F1), // indigo
      ),
    ),
    'benefit_sleep_submit' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'If you die before waking, you will die upon Islam',
        highlightPhrase: 'die upon Islam',
        subtitle: 'Sahih al-Bukhari 6311',
        completedSubtitle: 'Surrendered fully to your Lord',
        accentColor: const Color(0xFF7C3AED), // violet
      ),
    ),
    'benefit_sleep_soul' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Your soul guarded as Allah guards His righteous servants',
        highlightPhrase: 'righteous servants',
        subtitle: 'Sahih al-Bukhari 6320',
        completedSubtitle: 'Entrusted to His care',
        accentColor: const Color(0xFF0D9488), // deep teal
      ),
    ),
    'benefit_sleep_refuge' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Refuge from His punishment on the Day He raises His servants',
        highlightPhrase: 'Refuge from His punishment',
        subtitle: 'Sunan Abi Dawud 5045',
        completedSubtitle: 'Sheltered from the Last Day',
        accentColor: const Color(0xFF475569), // slate
      ),
    ),
    'benefit_sleep_provision' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Praise the One who feeds, gives drink, and shelters when none other could',
        highlightPhrase: 'feeds, gives drink, and shelters',
        subtitle: 'Sahih Muslim 2715',
        completedSubtitle: 'Sufficed by His provision',
        accentColor: const Color(0xFF0D9488), // teal
      ),
    ),
    'benefit_sleep_entrust' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Your soul entrusted to its Creator — safety asked of Him alone',
        highlightPhrase: 'entrusted to its Creator',
        subtitle: 'Sahih Muslim 2712',
        completedSubtitle: 'Safe in His hand',
        accentColor: const Color(0xFF6366F1), // indigo
      ),
    ),
    'benefit_sleep_debt' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Debt settled and poverty repelled by the First and the Last',
        highlightPhrase: 'Debt settled',
        subtitle: 'Sahih Muslim 2713a',
        completedSubtitle: 'Wealth of the soul granted',
        accentColor: const Color(0xFF7A8C3A), // sage
      ),
    ),
    'benefit_sleep_sins' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Debt and sin lifted by His perfect words — His army never defeated',
        highlightPhrase: 'Debt and sin lifted',
        subtitle: 'Sunan Abi Dawud 5052',
        completedSubtitle: 'Carried by His undefeated army',
        accentColor: const Color(0xFF475569), // slate
      ),
    ),
    'benefit_sleep_assembly' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Sins forgiven, shaytan suppressed, raised to the highest assembly',
        highlightPhrase: 'the highest assembly',
        subtitle: 'Sunan Abi Dawud 5054',
        completedSubtitle: 'Among the noblest ranks',
        accentColor: const Color(0xFF7C3AED), // violet
      ),
    ),
    'benefit_sleep_shelter' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Sufficed, sheltered, and refuge granted from the Fire',
        highlightPhrase: 'refuge granted from the Fire',
        subtitle: 'Sunan Abi Dawud 5058',
        completedSubtitle: 'Safe from the Fire by His mercy',
        accentColor: const Color(0xFFD89A1E), // honey deep
      ),
    ),
    'benefit_sleep_sajda' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Recited every night by the Messenger ﷺ before he slept',
        highlightPhrase: 'every night',
        subtitle: 'Jami` at-Tirmidhi 2892',
        completedSubtitle: 'You followed His nightly sunnah',
        accentColor: const Color(0xFF3B82F6), // soft blue
      ),
    ),
    'benefit_sleep_mulk' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'A Surah that intercedes for its reciter until they are forgiven',
        highlightPhrase: 'intercedes',
        subtitle: 'Sunan Abi Dawud 1400',
        completedSubtitle: 'Surat al-Mulk now stands for you',
        accentColor: const Color(0xFF6366F1), // indigo
      ),
    ),
    // ── Duas after Salah — text-based benefit illustrations ───────────────
    'benefit_salah_peace' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'You are As-Salam, and from You is As-Salam',
        highlightPhrase: 'As-Salam',
        subtitle: 'Sahih Muslim 591',
        completedSubtitle: 'Greeted by the source of all peace',
        accentColor: const Color(0xFF0D9488), // deep teal
      ),
    ),
    'benefit_salah_help' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Help me remember You, thank You, and worship You in the best of manners',
        highlightPhrase: 'remember You, thank You',
        subtitle: 'Sunan Abi Dawud 1522',
        completedSubtitle: 'His help asked, His help granted',
        accentColor: const Color(0xFF7A8C3A), // sage
      ),
    ),
    'benefit_salah_knowledge' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Knowledge that benefits, sustenance that is good, deeds that are accepted',
        highlightPhrase: 'Knowledge that benefits',
        subtitle: 'Sunan Ibn Majah 925',
        completedSubtitle: 'Asked of Him after the dawn',
        accentColor: const Color(0xFFD89A1E), // honey deep
      ),
    ),
    // ── Rabbana 40 — text-based benefit cards for duas without a strong
    // Morning/Evening thematic match. Each summarises the dua's context
    // from the data in `azkar_items.reward` and cites the Qur'an verse.
    'benefit_rabbana_001' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Asking Allah to accept the good you have done — as Ibrahim asked after building the Kaaba',
        highlightPhrase: 'accept the good',
        subtitle: 'Surah Al-Baqarah 2:127',
        completedSubtitle: 'The dua of the builders of His House',
        accentColor: const Color(0xFF7A8C3A),
      ),
    ),
    'benefit_rabbana_002' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Affirm your Islam and ask for the success of the entire Muslim Ummah',
        highlightPhrase: 'entire Muslim Ummah',
        subtitle: 'Surah Al-Baqarah 2:128',
        completedSubtitle: 'Standing with the Ummah of Muhammad ﷺ',
        accentColor: const Color(0xFFD89A1E),
      ),
    ),
    'benefit_rabbana_006' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Asking Allah for trials we can bear — not to be tested beyond our capacity',
        highlightPhrase: 'trials we can bear',
        subtitle: 'Surah Al-Baqarah 2:286',
        completedSubtitle: 'His mercy does not burden a soul beyond what it can carry',
        accentColor: const Color(0xFF6366F1),
      ),
    ),
    'benefit_rabbana_008' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Asking Allah\'s mercy and to be made among the rightly guided',
        highlightPhrase: 'rightly guided',
        subtitle: 'Surah Aali Imran 3:8',
        completedSubtitle: 'Guidance is the greatest of His gifts',
        accentColor: const Color(0xFF0D9488),
      ),
    ),
    'benefit_rabbana_009' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Affirming your belief in the Day Allah will gather all mankind',
        highlightPhrase: 'gather all mankind',
        subtitle: 'Surah Aali Imran 3:9',
        completedSubtitle: 'His promise will not fail',
        accentColor: const Color(0xFF475569),
      ),
    ),
    'benefit_rabbana_011' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Asking to be written among the witnesses to the truth',
        highlightPhrase: 'witnesses to the truth',
        subtitle: 'Surah Aali Imran 3:53',
        completedSubtitle: 'Among those who upheld His message',
        accentColor: const Color(0xFF7C3AED),
      ),
    ),
    'benefit_rabbana_014' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Reflect on where you are going — knowing the fate of the wrongdoers',
        highlightPhrase: 'fate of the wrongdoers',
        subtitle: 'Surah Aali Imran 3:191',
        completedSubtitle: 'Awakened by reflection on the Hereafter',
        accentColor: const Color(0xFFE8A84A),
      ),
    ),
    'benefit_rabbana_015' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'We heard the caller and we believed — affirming submission to His message',
        highlightPhrase: 'we believed',
        subtitle: 'Surah Aali Imran 3:193',
        completedSubtitle: 'Answered His call with surrender',
        accentColor: const Color(0xFF7A8C3A),
      ),
    ),
    'benefit_rabbana_017' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Asking not to be disgraced on the Day Allah fulfils His promise',
        highlightPhrase: 'not to be disgraced',
        subtitle: 'Surah Aali Imran 3:194',
        completedSubtitle: 'Walking with honour toward His promise',
        accentColor: const Color(0xFFD89A1E),
      ),
    ),
    'benefit_rabbana_018' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Verbally affirming your belief in the message of Muhammad ﷺ',
        highlightPhrase: 'message of Muhammad',
        subtitle: 'Surah Al-Maidah 5:83',
        completedSubtitle: 'Witness to His truth',
        accentColor: const Color(0xFF0D9488),
      ),
    ),
    'benefit_rabbana_022' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'The dua of those who refuse to return to falsehood after Allah saves them',
        highlightPhrase: 'refuse to return to falsehood',
        subtitle: 'Surah Al-A\'raf 7:89',
        completedSubtitle: 'Standing firm in His path',
        accentColor: const Color(0xFF6366F1),
      ),
    ),
    'benefit_rabbana_026' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Make me and my descendants among those who establish prayer — Ibrahim\'s dua',
        highlightPhrase: 'establish prayer',
        subtitle: 'Surah Ibrahim 14:40',
        completedSubtitle: 'His dua extended through your generations',
        accentColor: const Color(0xFF7A8C3A),
      ),
    ),
    'benefit_rabbana_028' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'The dua of the young men who fled to the Cave seeking His mercy and guidance',
        highlightPhrase: 'mercy and guidance',
        subtitle: 'Surah Al-Kahf 18:10',
        completedSubtitle: 'Refuge of the righteous when the world is dark',
        accentColor: const Color(0xFF0D9488),
      ),
    ),
    'benefit_rabbana_029' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Allah said: "Fear not, I am with you, I hear and I see" — the dua before facing Firawn',
        highlightPhrase: 'I am with you',
        subtitle: 'Surah Taha 20:46',
        completedSubtitle: 'Standing in faith despite fear',
        accentColor: const Color(0xFF7C3AED),
      ),
    ),
    'benefit_rabbana_030' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Calling upon Allah by His attribute Ar-Rahim — the Most Merciful',
        highlightPhrase: 'Most Merciful',
        subtitle: 'Surah Al-Mu\'minun 23:109',
        completedSubtitle: 'Embraced by His infinite mercy',
        accentColor: const Color(0xFF0D9488),
      ),
    ),
    'benefit_rabbana_032' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Granting coolness of the eyes through righteous spouses and children — to be a leader for the godfearing',
        highlightPhrase: 'coolness of the eyes',
        subtitle: 'Surah Al-Furqan 25:74',
        completedSubtitle: 'Your family the light of your soul',
        accentColor: const Color(0xFFE8A84A),
      ),
    ),
    'benefit_rabbana_033' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'The praise of the believers in the Garden of Eden — He is Forgiving, Appreciative',
        highlightPhrase: 'Forgiving, Appreciative',
        subtitle: 'Surah Fatir 35:34',
        completedSubtitle: 'Praise befitting eternal gardens',
        accentColor: const Color(0xFF7A8C3A),
      ),
    ),
    'benefit_rabbana_035' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Uniting believers with their righteous descendants in Jannah, by His mercy',
        highlightPhrase: 'righteous descendants',
        subtitle: 'Surah Ghafir 40:8',
        completedSubtitle: 'Family reunited under His mercy',
        accentColor: const Color(0xFFD89A1E),
      ),
    ),
    'benefit_rabbana_036' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Asking Allah to remove resentment from our hearts toward our fellow believers',
        highlightPhrase: 'remove resentment',
        subtitle: 'Surah Al-Hashr 59:10',
        completedSubtitle: 'Heart cleansed of envy',
        accentColor: const Color(0xFF6366F1),
      ),
    ),
    'benefit_rabbana_037' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Praising Allah by His attributes — the Compassionate, the Merciful',
        highlightPhrase: 'the Compassionate, the Merciful',
        subtitle: 'Surah Al-Hashr 59:10',
        completedSubtitle: 'Calling Him by His most beautiful names',
        accentColor: const Color(0xFF0D9488),
      ),
    ),
    'benefit_rabbana_039' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Ibrahim\'s dua: make the believers victorious, do not make us objects of torment',
        highlightPhrase: 'victorious',
        subtitle: 'Surah Al-Mumtahanah 60:5',
        completedSubtitle: 'Standing on the side of His truth',
        accentColor: const Color(0xFFE8A84A),
      ),
    ),
    'benefit_rabbana_040' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Perfect our light on the Day of Judgment and forgive us — we will walk by Your light',
        highlightPhrase: 'Perfect our light',
        subtitle: 'Surah At-Tahrim 66:8',
        completedSubtitle: 'Light illuminating from your right hand',
        accentColor: const Color(0xFFD89A1E),
      ),
    ),
    // ── Daily Duas — text-based benefit cards for duas without a strong
    // Morning/Evening thematic match. Each summarises the dua's hadith.
    'benefit_daily_004' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Ask Allah for the best entry and exit — with His name and trust upon Him',
        highlightPhrase: 'best entry and exit',
        subtitle: 'Sunan Abi Dawud 5096',
        completedSubtitle: 'Home entered with His blessing',
        accentColor: const Color(0xFF7A8C3A),
      ),
    ),
    'benefit_daily_005' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'I seek refuge in You from male and female evil jinn',
        highlightPhrase: 'I seek refuge',
        subtitle: 'Sahih al-Bukhari 6322',
        completedSubtitle: 'Sheltered from the unseen',
        accentColor: const Color(0xFF475569),
      ),
    ),
    'benefit_daily_007' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Bismillah at the start of your meal keeps Shaytan from sharing it',
        highlightPhrase: 'keeps Shaytan from sharing',
        subtitle: 'Sunan Ibn Majah 3264',
        completedSubtitle: 'Meal sanctified by His name',
        accentColor: const Color(0xFFD89A1E),
      ),
    ),
    'benefit_daily_008' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'If you forgot Bismillah at the start, say it any time — it covers both ends',
        highlightPhrase: 'covers both ends',
        subtitle: 'Jami at-Tirmidhi 1858',
        completedSubtitle: 'Forgetfulness atoned by His name',
        accentColor: const Color(0xFFE8A84A),
      ),
    ),
    'benefit_daily_009' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Praise Allah after eating — your past sins are forgiven',
        highlightPhrase: 'past sins are forgiven',
        subtitle: 'Jami at-Tirmidhi 3458',
        completedSubtitle: 'Sins washed by gratitude',
        accentColor: const Color(0xFF0D9488),
      ),
    ),
    'benefit_daily_013' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'O Allah, I ask You of Your bounty — as you step out of His house',
        highlightPhrase: 'Your bounty',
        subtitle: 'Sahih Muslim 713',
        completedSubtitle: 'Stepped out with hope of His bounty',
        accentColor: const Color(0xFFD89A1E),
      ),
    ),
    'benefit_daily_014' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Whoever responds to the mu\'adhin word by word with sincerity will enter Paradise',
        highlightPhrase: 'enter Paradise',
        subtitle: 'Sahih Muslim 385',
        completedSubtitle: 'The caller answered',
        accentColor: const Color(0xFF7A8C3A),
      ),
    ),
    'benefit_daily_016' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Guide me among those You have guided, protect me, and guard me from the evil You decreed',
        highlightPhrase: 'guard me from the evil You decreed',
        subtitle: 'Sunan Abi Dawud 1425',
        completedSubtitle: 'Guided and protected by Your decree',
        accentColor: const Color(0xFF6366F1),
      ),
    ),
    'benefit_daily_018' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Peace upon you, people of the abodes — asking well-being for them and for us',
        highlightPhrase: 'well-being',
        subtitle: 'Sahih Muslim 974',
        completedSubtitle: 'Greeted those who preceded us',
        accentColor: const Color(0xFF475569),
      ),
    ),
    'benefit_daily_019' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Glory to Him who has made this subservient to us — and to our Lord we return',
        highlightPhrase: 'to our Lord we return',
        subtitle: 'Sahih Muslim 1342',
        completedSubtitle: 'Journey under His care',
        accentColor: const Color(0xFF0D9488),
      ),
    ),
    'benefit_daily_020' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'We return, repentant, worshipping our Lord, and praising Him',
        highlightPhrase: 'repentant',
        subtitle: 'Sahih al-Bukhari 1797',
        completedSubtitle: 'Returned to Him in praise',
        accentColor: const Color(0xFF7A8C3A),
      ),
    ),
    'benefit_daily_021' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Allah loves sneezing — say Alhamdulillah, and your brothers must answer with mercy',
        highlightPhrase: 'Allah loves sneezing',
        subtitle: 'Sahih al-Bukhari 6224',
        completedSubtitle: 'Praise that earns His love',
        accentColor: const Color(0xFFD89A1E),
      ),
    ),
    'benefit_daily_022' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'When you hear your brother praise Allah after sneezing, say Yarhamukallah — May Allah have mercy on you',
        highlightPhrase: 'Yarhamukallah',
        subtitle: 'Sahih al-Bukhari 6225',
        completedSubtitle: 'Mercy asked for your brother',
        accentColor: const Color(0xFF0D9488),
      ),
    ),
    'benefit_daily_023' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Reply with Yahdikumullah — May Allah guide you and set right your affairs',
        highlightPhrase: 'Yahdikumullah',
        subtitle: 'Sunan Abi Dawud 5031',
        completedSubtitle: 'Guidance prayed in return',
        accentColor: const Color(0xFF6366F1),
      ),
    ),
    'benefit_daily_027' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Pray for forgiveness for your parents — they will be raised in rank by your du\'a',
        highlightPhrase: 'raised in rank',
        subtitle: 'Sunan Ibn Majah 3660',
        completedSubtitle: 'Your parents lifted by your du\'a',
        accentColor: const Color(0xFF7A8C3A),
      ),
    ),
    'benefit_daily_035' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Allah has been asked by His Greatest Name — when asked thereby, He answers',
        highlightPhrase: 'Greatest Name',
        subtitle: 'Sunan Ibn Majah 3856',
        completedSubtitle: 'Called upon by His Greatest Name',
        accentColor: const Color(0xFFD89A1E),
      ),
    ),
    'benefit_daily_036' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Thirst is gone, the veins are moistened, and the reward is sure — if Allah wills',
        highlightPhrase: 'reward is sure',
        subtitle: 'Sunan Abi Dawud 2357',
        completedSubtitle: 'Reward of fasting secured',
        accentColor: const Color(0xFFE8A84A),
      ),
    ),
    'benefit_daily_041' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Bismillah, O Allah, keep Shaytan far from us — the child is protected from him',
        highlightPhrase: 'child is protected',
        subtitle: 'Sahih al-Bukhari 5165',
        completedSubtitle: 'Lineage safeguarded from harm',
        accentColor: const Color(0xFF0D9488),
      ),
    ),
    'benefit_daily_044' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Ask Allah\'s guidance before any decision — He chooses what is best for you in dunya and akhirah',
        highlightPhrase: 'He chooses what is best',
        subtitle: 'Sahih al-Bukhari 1162',
        completedSubtitle: 'Decision entrusted to His wisdom',
        accentColor: const Color(0xFF6366F1),
      ),
    ),
    'benefit_daily_034' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Allah is Sufficient for us, and He is the Best Disposer of affairs — said by Ibrahim in the fire and by Muhammad ﷺ before battle',
        highlightPhrase: 'Allah is Sufficient',
        subtitle: 'Surah Aali Imran 3:173',
        completedSubtitle: 'Affairs entrusted to the Best Disposer',
        accentColor: const Color(0xFF7A8C3A),
      ),
    ),
    'benefit_daily_039' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Ask Allah to make the difficult easy — nothing is easy except what He has made so',
        highlightPhrase: 'make the difficult easy',
        subtitle: 'Sahih Ibn Hibban 2427',
        completedSubtitle: 'Ease found in His will',
        accentColor: const Color(0xFF6366F1),
      ),
    ),
    'benefit_daily_040' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Seek refuge from worry, grief, weakness, laziness, cowardice, miserliness, debt, and being overpowered',
        highlightPhrase: 'Seek refuge',
        subtitle: 'Sahih al-Bukhari 6369',
        completedSubtitle: 'Refuge granted from every burden',
        accentColor: const Color(0xFF475569),
      ),
    ),
    // ── Remembrance of Allah — text cards for dhikrs without strong M/E match
    'benefit_dhikr_030' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Say it — it is a treasure from the treasures of Paradise',
        highlightPhrase: 'treasure of Paradise',
        subtitle: 'Sahih al-Bukhari 4205',
        completedSubtitle: 'A treasure deposited for you in Jannah',
        accentColor: const Color(0xFFD89A1E),
      ),
    ),
    'benefit_dhikr_032' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'The dua of Dhun-Nun in the belly of the whale — no Muslim calls upon Allah with it except that Allah responds',
        highlightPhrase: 'Allah responds',
        subtitle: 'Jami at-Tirmidhi 3505',
        completedSubtitle: 'His response promised by His Messenger ﷺ',
        accentColor: const Color(0xFF0D9488),
      ),
    ),
    'benefit_salah_freed_slaves' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BenefitTextIllustration(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
        benefitText: 'Equal to freeing four slaves — 10 good deeds written, 10 sins erased, 10 ranks raised, security all day',
        highlightPhrase: 'freeing four slaves',
        subtitle: 'Jami at-Tirmidhi 3474',
        completedSubtitle: 'Freed, raised, and shielded for the day',
        accentColor: const Color(0xFFE8A84A),
      ),
    ),
    'doors' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _DoorsOfMercy(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'heavy_scales' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _HeavyScales(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'cosmic' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _CosmicWeight(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'baqarah_shield' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BaqarahShield(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'baqarah_close' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BaqarahClose(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'night_peace' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _NightPeace(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'evening_sovereignty' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _EveningSovereignty(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'gratitude_tree' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _GratitudeTree(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'baqarah_burden' => w(
      ({
        required progress,
        required isComplete,
        required tapCount,
        required pointsToday,
      }) => _BaqarahBurden(
        progress: progress,
        isComplete: isComplete,
        tapCount: tapCount,
        pointsToday: pointsToday,
      ),
    ),
    'none' => const SizedBox.shrink(),
    _ => const SizedBox.shrink(),
  };
}

// =============================================================================
// Motivational tagline — short punchy benefit line shown inside illustration
// =============================================================================
String _pickTagline(String id) {
  // ── Specific numeric IDs first (most precise) ──
  if (id == 'morning_32' || id == 'evening_31')
    return 'Sins forgiven, even if like the foam of the sea';
  if (id == 'morning_31' || id == 'evening_30')
    return '10 freed · 100 hasanat · 100 sins erased · Shaytan repelled';
  if (id == 'morning_33' || id == 'evening_32')
    return '10 blessings descend from Allah upon you';
  if (id == 'morning_30') return 'Ask Allah to bless and beautify your day';
  if (id == 'morning_29' || id == 'evening_29')
    return 'Allah is sufficient for you in every affair';
  if (id == 'morning_28' || id == 'evening_28')
    return "Wellbeing of body, hearing & sight, granted";
  if (id == 'morning_27' || id == 'evening_27')
    return 'Allah will free him from the Fire who reads this 4 times';
  if (id == 'morning_26') return 'Guaranteed Jannah, if you die this day';
  if (id == 'evening_26') return 'Guaranteed Jannah, if you die this night';
  if (id == 'morning_25' || id == 'evening_25')
    return 'Your life entrusted to the Ever-Living';
  if (id == 'morning_24' || id == 'evening_24')
    return 'All evil in His creation repelled from you';
  if (id == 'morning_23' || id == 'evening_23')
    return 'Nothing shall harm you, by perfect words';
  if (id == 'morning_22' || id == 'evening_22')
    return 'Shield yourself from minor and major shirk, morning & evening';
  if (id == 'morning_21' || id == 'evening_21')
    return 'Complete protection in the name of Allah';
  if (id == 'morning_20' || id == 'evening_20')
    return 'Weightier than all voluntary prayers, from dawn till dusk';
  if (id == 'morning_18' || id == 'evening_18')
    return 'Recite morning & evening, earn the pleasure & blessing of Allah on the Day of Judgment';
  if (id == 'morning_17' || id == 'evening_17')
    return 'Your reward awaits directly with Allah when you meet Him';
  if (id == 'morning_15' || id == 'evening_15')
    return 'Recite morning & evening to fulfill your obligation of gratitude to Allah';
  if (id == 'morning_14' || id == 'evening_14')
    return 'The Prophet taught this dua for morning and evening, do not miss it';
  if (id == 'morning_12')
    return 'Declare Allah\'s dominion at the start of your morning, all kingdom belongs to Him';
  if (id == 'evening_12')
    return 'As evening falls, the entire kingdom belongs to Allah alone';
  if (id == 'evening_13')
    return 'End your evening upon the pure fitrah, as the Prophet (ﷺ) taught';
  if (id == 'morning_2' || id == 'evening_2')
    return 'Satan will not enter the home of one who recites this';
  if (id == 'morning_4' ||
      id == 'morning_5' ||
      id == 'evening_4' ||
      id == 'evening_5')
    return '';
  if (id == 'morning_6' || id == 'evening_6')
    return 'Reading last 2 verses of al-Baqarah will suffice you';
  if (id == 'morning_8' || id == 'evening_8')
    return 'Every dua in this verse - Allah said: I have done so';

  // ── Illustration-key based fallback ──
  final ill = _pickIllustration(id);
  return switch (ill) {
    'shield' => 'Guarded by Allah until morning comes',
    'quran_complete' =>
      'Reciting 3x equals reading the entire Quran, Bukhari & Muslim',
    'dawn_dusk' => 'Recite 3x at dawn & dusk, suffice you against all harm',
    'falaq_shield' =>
      'Recite 3x at dawn & dusk, it will suffice you in all respects',
    'dua_hands' => 'Refuge from the whisperer, in the Lord of Mankind',
    'gratitude_tree' =>
      'Recite 3x morning & evening, your gratitude to Allah is fulfilled',
    'three_quls' => 'Sufficient against every harm recited 3 times',
    'gates' => 'Doors of Allah mercy open wide for you',
    'chains' => 'Worry and sorrow lifted by the will of Allah',
    'six_wards' => 'Guarded in your deen dunya and akhirah',
    'repelling' => 'Evil repelled from every direction',
    'heart' => 'Heart held by the Ever Living Ever Sustaining',
    'benefit_text_16' => 'Fulfilled your obligation of giving thanks',
    'benefit_text_7' =>
      'Reciting the last 2 verses of Al-Baqarah at night suffices you',
    'benefit_text_24' => 'All evil in His creation repelled from you',
    'vessel' => 'Gratitude that multiplies your blessings',
    'dawn' => 'Start pure on the fitrah of Islam',
    'ripples' => 'Praise that ripples through all creation',
    'path' => 'Guided to every good this day',
    'invincible' => 'Nothing shall harm you by His name',
    'flame' => 'Allah will free him from the Fire who reads this 4 times',
    'doors' => 'Guaranteed Jannah if you die today',
    'vessels' => 'Wellbeing of body hearing and sight',
    'pillars' => 'Allah is sufficient in every affair',
    'blessings' => 'Seeking Allah blessing for a beautiful day',
    'scales' => 'Ten freed 100 hasanat Shaytan repelled',
    'ocean' => 'Sins forgiven even if like the foam of the sea',
    'salawat' => 'Ten blessings from Allah upon you',
    'glory' => 'Glorified and praised in morning light',
    'cycle' => 'Return to Allah He is Ever Forgiving',
    'hand' => 'Guided by the hand of Allah',
    'cosmic' => 'Words heavier than the heavens and earth',
    'dua_scene' => 'Begin your day in surrender to Allah',
    'baqarah_shield' => 'Satan will not enter the home of one who recites this',
    'baqarah_close' => 'They are enough for you - recite before sleep',
    'night_peace' => 'Reading last 2 verses of al-Baqarah will suffice you',
    'baqarah_burden' => 'Every dua in this verse - Allah said: I have done so',
    'afiyah_guard' =>
      'Guarded in your Deen · Dunya · Akhirah, and from all six sides',
    'noor_door' =>
      'Recite morning & evening, earn the pleasure of Allah on the Day of Judgment',
    'evening_sovereignty' =>
      'As evening falls, the entire kingdom belongs to Allah alone',
    _ => '',
  };
}

/// Per-illustration tagline color — distinct for each category, always readable.
Color _pickTaglineColor(String id, bool isDark) {
  // Same emerald/mint as the dashboard Seal-the-Day button so the
  // tagline pill reads as part of the same "accomplishment" visual
  // language. (Was a muddy brown-gold, then briefly honey-yellow.)
  return const Color(0xFF4A9B8E);
}

/// Arabic calligraphy text style used inside illustration canvases.
TextStyle _illusArabic(
  double size,
  Color color, {
  FontWeight weight = FontWeight.w700,
}) => GoogleFonts.amiri(
  fontSize: size,
  color: color,
  fontWeight: weight,
  height: 1.4,
);

/// Small Arabic tag style for phase/reward markers inside illustrations.
TextStyle _illusTag(double size, Color color) => GoogleFonts.amiri(
  fontSize: size,
  color: color,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

// =============================================================================
// 🤲 Dua Scene — person praying with tree, mountains, sun
// =============================================================================
class _DuaScene extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _DuaScene({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_DuaScene> createState() => _DuaSceneState();
}

class _DuaSceneState extends State<_DuaScene> with TickerProviderStateMixin {
  late AnimationController _growCtrl;
  late Animation<double> _grow;
  double _prevProgress = 0.0;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _punchCtrl;
  late Animation<double> _punch;
  late AnimationController _shockCtrl;
  late Animation<double> _shock;
  late AnimationController _pCtrl;
  late Animation<double> _pAnim;
  int _prevTap = 0;
  final List<_Particle> _particles = List.generate(
    15,
    (i) => _Particle(seed: i + 500),
  );

  @override
  void initState() {
    super.initState();
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.05,
          end: 0.98,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.98,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
  }

  @override
  void didUpdateWidget(_DuaScene old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _growCtrl.dispose();
    _pulseCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _pCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _growCtrl,
        _pulseCtrl,
        _punchCtrl,
        _shockCtrl,
        _pCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _DuaScenePainter(
                progress: _grow.value,
                pulse: _pulse.value,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                particlePhase: _pAnim.value,
                particles: _particles,
              ),
            ),
          ),
    );
  }
}

class _DuaScenePainter extends CustomPainter {
  final double progress;
  final double pulse;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double particlePhase;
  final List<_Particle> particles;

  const _DuaScenePainter({
    required this.progress,
    required this.pulse,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.particlePhase = 0.0,
    this.particles = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ── 1. Warm sky gradient ──
    final warmth = progress * 0.3;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(
              (255 - warmth * 10).round(),
              (248 - warmth * 5).round(),
              (225 + warmth * 10).round(),
              1.0,
            ),
            Color.fromRGBO(
              (245 - warmth * 8).round(),
              (240 - warmth * 5).round(),
              (215 + warmth * 12).round(),
              1.0,
            ),
            Color.fromRGBO(
              (230 + warmth * 15).round(),
              (225 + warmth * 10).round(),
              (200 + warmth * 20).round(),
              1.0,
            ),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    final groundY = h * 0.72;

    // ── 2. Sun ──
    final sunCy = h * 0.18;
    final sunR = 22 + progress * 8;
    final sunAlpha = 0.40 + progress * 0.40;
    // Corona
    canvas.drawCircle(
      Offset(cx, sunCy),
      sunR + 18,
      Paint()
        ..color = Color.fromRGBO(255, 220, 100, sunAlpha * 0.12 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    // Sun disc
    canvas.drawCircle(
      Offset(cx, sunCy),
      sunR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(255, 255, 240, sunAlpha),
            Color.fromRGBO(255, 230, 150, sunAlpha * 0.9),
            Color.fromRGBO(255, 200, 80, sunAlpha * 0.6),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, sunCy), radius: sunR),
        ),
    );
    // Bright core
    canvas.drawCircle(
      Offset(cx, sunCy),
      sunR * 0.4,
      Paint()..color = Colors.white.withValues(alpha: sunAlpha * 0.65),
    );
    // Sun rays
    if (progress > 0.1) {
      final rayA = progress * 0.15;
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi * 2 / 8;
        final sx = cx + math.cos(angle) * (sunR + 4);
        final sy = sunCy + math.sin(angle) * (sunR + 4);
        final ex = cx + math.cos(angle) * (sunR + 20 + progress * 12);
        final ey = sunCy + math.sin(angle) * (sunR + 20 + progress * 12);
        canvas.drawLine(
          Offset(sx, sy),
          Offset(ex, ey),
          Paint()
            ..color = Color.fromRGBO(255, 220, 120, rayA)
            ..strokeWidth = i.isEven ? 2.0 : 1.2
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // ── 3. Mountains ──
    final mtColor1 =
        Color.lerp(const Color(0xFFB8C5D0), const Color(0xFFA8C0A8), progress)!;
    final mtColor2 =
        Color.lerp(const Color(0xFFC5CDD5), const Color(0xFFB5CCB5), progress)!;

    // Back mountain (larger, lighter)
    final mt1 =
        Path()
          ..moveTo(0, groundY)
          ..lineTo(w * 0.10, groundY)
          ..quadraticBezierTo(w * 0.20, groundY - 55, w * 0.35, groundY - 70)
          ..quadraticBezierTo(w * 0.42, groundY - 75, w * 0.50, groundY - 60)
          ..quadraticBezierTo(w * 0.58, groundY - 50, w * 0.65, groundY)
          ..close();
    canvas.drawPath(mt1, Paint()..color = mtColor2.withValues(alpha: 0.70));

    // Front mountain (smaller, darker)
    final mt2 =
        Path()
          ..moveTo(w * 0.35, groundY)
          ..quadraticBezierTo(w * 0.50, groundY - 45, w * 0.62, groundY - 55)
          ..quadraticBezierTo(w * 0.70, groundY - 60, w * 0.78, groundY - 45)
          ..quadraticBezierTo(w * 0.88, groundY - 25, w, groundY)
          ..close();
    canvas.drawPath(mt2, Paint()..color = mtColor1.withValues(alpha: 0.75));

    // ── 4. Ground ──
    final groundPath =
        Path()
          ..moveTo(0, groundY)
          ..quadraticBezierTo(w * 0.25, groundY - 3, w * 0.5, groundY)
          ..quadraticBezierTo(w * 0.75, groundY + 3, w, groundY)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();
    final groundColor =
        Color.lerp(const Color(0xFFD5C8B0), const Color(0xFFC8D8B8), progress)!;
    canvas.drawPath(
      groundPath,
      Paint()..color = groundColor.withValues(alpha: 0.55),
    );

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, groundY);
    // punch scale removed
    canvas.translate(-cx, -groundY);

    // ── 5. Tree (right side) ──
    _drawTree(canvas, cx + w * 0.22, groundY, progress);

    // ── 6. Person sitting in dua (center-left) ──
    _drawDuaPerson(canvas, cx - w * 0.08, groundY, progress);

    canvas.restore();

    // ── 7. Shockwave ──
    // tap-effect removed — smooth calm

    // ── 8. Particles ──
    // tap-effect removed — smooth calm

    // ── 9. Progress label ──
    // progress % label removed

    // ── 10. Points badge ──
  }

  /// Tree with trunk, branches, and leaf canopy — taller than the person
  void _drawTree(Canvas canvas, double tx, double groundY, double progress) {
    final trunkAlpha = 0.60 + progress * 0.30;
    final trunkColor = Color.fromRGBO(110, 78, 45, trunkAlpha);
    final leafColor =
        isComplete
            ? Color.fromRGBO(70, 150, 55, 0.70 + progress * 0.20)
            : Color.fromRGBO(55, 130, 70, 0.55 + progress * 0.30);

    // Trunk — tall (80px max, much taller than the ~50px person)
    final trunkW = 7.0;
    final trunkH = 80.0 * (0.4 + progress * 0.6);
    final trunkTop = groundY - trunkH;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tx - trunkW / 2, trunkTop, trunkW, trunkH),
        const Radius.circular(3),
      ),
      Paint()..color = trunkColor,
    );

    // Branches — thicker and longer
    if (progress > 0.2) {
      final branchA = ((progress - 0.2) / 0.8).clamp(0.0, 1.0);
      final bp =
          Paint()
            ..color = trunkColor.withValues(alpha: trunkAlpha * branchA)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(tx, trunkTop + trunkH * 0.25),
        Offset(tx - 22 * branchA, trunkTop + trunkH * 0.08),
        bp,
      );
      canvas.drawLine(
        Offset(tx, trunkTop + trunkH * 0.35),
        Offset(tx + 24 * branchA, trunkTop + trunkH * 0.12),
        bp,
      );
      canvas.drawLine(
        Offset(tx, trunkTop + trunkH * 0.48),
        Offset(tx - 18 * branchA, trunkTop + trunkH * 0.30),
        bp,
      );
      canvas.drawLine(
        Offset(tx, trunkTop + trunkH * 0.58),
        Offset(tx + 16 * branchA, trunkTop + trunkH * 0.40),
        bp,
      );
    }

    // Leaf canopy — bigger, lush overlapping ovals
    if (progress > 0.15) {
      final canopyA = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
      final lp =
          Paint()..color = leafColor.withValues(alpha: canopyA * leafColor.a);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tx, trunkTop - 8),
          width: 50 * canopyA,
          height: 38 * canopyA,
        ),
        lp,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tx - 16, trunkTop + 4),
          width: 35 * canopyA,
          height: 28 * canopyA,
        ),
        lp,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tx + 14, trunkTop + 2),
          width: 38 * canopyA,
          height: 26 * canopyA,
        ),
        lp,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tx - 8, trunkTop - 16),
          width: 30 * canopyA,
          height: 22 * canopyA,
        ),
        lp,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tx + 8, trunkTop - 14),
          width: 28 * canopyA,
          height: 20 * canopyA,
        ),
        lp,
      );

      // Highlight
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tx - 5, trunkTop - 12),
          width: 16 * canopyA,
          height: 12 * canopyA,
        ),
        Paint()..color = Colors.white.withValues(alpha: canopyA * 0.12),
      );
    }
  }

  /// Person kneeling in side-profile dua pose (facing right, like reference)
  void _drawDuaPerson(
    Canvas canvas,
    double px,
    double groundY,
    double progress,
  ) {
    final alpha = 0.70 + progress * 0.25;
    // Thobe/garment: teal-green like reference
    final garmentColor =
        isComplete
            ? Color.fromRGBO(60, 130, 70, alpha)
            : Color.fromRGBO(55, 125, 100, alpha);
    // Skin tone
    final skinColor = Color.fromRGBO(220, 190, 160, alpha);
    final skinFill = Paint()..color = skinColor;
    final garmentFill = Paint()..color = garmentColor;
    final glowColor =
        isComplete ? const Color(0xFFD4AF37) : const Color(0xFF4A90D9);

    final baseY = groundY - 2;

    // Subtle glow behind person
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(px + 5, baseY - 28),
        width: 55,
        height: 60,
      ),
      Paint()
        ..color = glowColor.withValues(alpha: alpha * 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // ── Prayer mat (thin dark rectangle) ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(px + 2, baseY + 1),
          width: 50,
          height: 4,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = Color.fromRGBO(80, 65, 50, alpha * 0.50),
    );

    // ── Kneeling lower body (longer thighs, side view) ──
    final kneeY = baseY - 2;
    // Thighs are longer — hip sits higher, knees extend further forward
    final lowerPath =
        Path()
          ..moveTo(px - 8, kneeY) // back of seated area
          ..quadraticBezierTo(
            px - 14,
            kneeY - 14,
            px - 2,
            kneeY - 14,
          ) // smooth round hip
          ..lineTo(px + 12, kneeY - 14) // across thigh
          ..quadraticBezierTo(
            px + 22,
            kneeY - 12,
            px + 22,
            kneeY - 4,
          ) // smooth round knee
          ..quadraticBezierTo(px + 20, kneeY + 2, px + 12, kneeY + 2) // shin
          ..lineTo(px - 6, kneeY + 2) // across bottom
          ..quadraticBezierTo(px - 10, kneeY + 1, px - 10, kneeY)
          ..close();
    canvas.drawPath(lowerPath, garmentFill);

    // ── Torso (shorter abdomen — side profile) ──
    final torsoTop = baseY - 42;
    final hipY = kneeY - 14;
    final torsoPath =
        Path()
          ..moveTo(px - 5, hipY) // back hip
          ..quadraticBezierTo(
            px - 6,
            torsoTop + 10,
            px - 3,
            torsoTop + 2,
          ) // back curves up (shorter)
          ..quadraticBezierTo(
            px,
            torsoTop - 2,
            px + 6,
            torsoTop,
          ) // shoulder top
          ..quadraticBezierTo(
            px + 12,
            torsoTop + 2,
            px + 14,
            torsoTop + 7,
          ) // front shoulder
          ..lineTo(px + 11, hipY) // front waist
          ..close();
    canvas.drawPath(torsoPath, garmentFill);

    // ── Neck ──
    final neckX = px + 5;
    final neckTop = torsoTop - 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(neckX - 2.5, neckTop, 5, 6),
        const Radius.circular(2),
      ),
      skinFill,
    );

    // ── Head (side profile — slightly tilted forward) ──
    final headCx = neckX + 2;
    final headCy = neckTop - 7;
    const headR = 8.0;
    canvas.drawCircle(Offset(headCx, headCy), headR, skinFill);

    // Hair/cap (dark arc on top-back of head)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(headCx - 1, headCy), radius: headR),
      math.pi * 0.8,
      math.pi * 1.0,
      false,
      Paint()
        ..color = Color.fromRGBO(50, 40, 30, alpha * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // ── Arms — both raised together in front of face (dua, with gap from face) ──
    final shoulderX = px + 12;
    final shoulderY = torsoTop + 6;
    final handX = headCx + 18;
    final handY = headCy + 3;

    final armPaint =
        Paint()
          ..color = skinColor
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    // Upper arm from shoulder forward
    final armPath =
        Path()
          ..moveTo(shoulderX, shoulderY)
          ..quadraticBezierTo(
            shoulderX + 8,
            shoulderY - 6,
            handX - 2,
            handY + 8,
          )
          ..quadraticBezierTo(handX, handY + 4, handX, handY);
    canvas.drawPath(armPath, armPaint);

    // Second arm slightly behind (partially visible)
    final arm2Path =
        Path()
          ..moveTo(shoulderX - 2, shoulderY + 2)
          ..quadraticBezierTo(
            shoulderX + 5,
            shoulderY - 4,
            handX - 3,
            handY + 9,
          )
          ..quadraticBezierTo(handX - 1, handY + 5, handX - 1, handY + 1);
    canvas.drawPath(
      arm2Path,
      Paint()
        ..color = skinColor.withValues(alpha: alpha * 0.75)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Hands together (palms pressed in dua)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(handX, handY + 1), width: 6, height: 9),
      skinFill,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(handX - 1.5, handY + 1),
        width: 5,
        height: 8,
      ),
      Paint()..color = skinColor.withValues(alpha: alpha * 0.80),
    );

    // ── Dua noor (light rising from hands) ──
    if (progress > 0.15) {
      final noorA = ((progress - 0.15) / 0.85).clamp(0.0, 1.0) * 0.25;
      // Small v-shaped lines above hands (like birds/breath in reference)
      for (int i = 0; i < 3; i++) {
        final ny = handY - 10 - i * 8;
        final nSize = 4.0 + i * 1.5;
        final na = noorA * (1.0 - i * 0.25) * pulse;
        canvas.drawLine(
          Offset(handX - nSize, ny + 3),
          Offset(handX, ny),
          Paint()
            ..color = glowColor.withValues(alpha: na)
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          Offset(handX + nSize, ny + 3),
          Offset(handX, ny),
          Paint()
            ..color = glowColor.withValues(alpha: na)
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DuaScenePainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.particlePhase != particlePhase;
}

// =============================================================================
// 🌳 Noor Tree (شجرة النور) — Islamic growth animation
// =============================================================================
// =============================================================================
// Gratitude Tree — "Ni'mah, 'Afiyah, Sitr" dua (morning_15/evening_15)
// Tree grows as gratitude is fulfilled. Text overlay from benefit.
// "Recite 3x morning & evening → obligation of gratitude fulfilled." (Ibn al-Sunni)
// =============================================================================
class _GratitudeTree extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _GratitudeTree({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_GratitudeTree> createState() => _GratitudeTreeState();
}

class _GratitudeTreeState extends State<_GratitudeTree>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _fade = Tween<double>(
      begin: 0.70,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.progress;

    // Text lines revealed progressively
    final lines = [
      (text: 'Blessings', threshold: 0.00, big: false),
      (text: 'Well-being', threshold: 0.18, big: false),
      (text: 'Concealment', threshold: 0.36, big: false),
      (text: 'Gratitude', threshold: 0.55, big: true),
      (text: 'Fulfilled.', threshold: 0.72, big: true),
    ];

    return AnimatedBuilder(
      animation: _fadeCtrl,
      builder:
          (context, _) => SizedBox(
            height: 290,
            child: Stack(
              children: [
                // Full tree behind
                Positioned.fill(
                  child: _NoorTree(
                    progress: widget.progress,
                    isComplete: widget.isComplete,
                    tapCount: widget.tapCount,
                    pointsToday: widget.pointsToday,
                  ),
                ),
                // Text overlay — top portion with frosted background
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors:
                            isDark
                                ? [
                                  const Color(
                                    0xFF0A1A0D,
                                  ).withValues(alpha: 0.88),
                                  const Color(
                                    0xFF0A1A0D,
                                  ).withValues(alpha: 0.0),
                                ]
                                : [
                                  const Color(
                                    0xFFF0FDF4,
                                  ).withValues(alpha: 0.90),
                                  const Color(
                                    0xFFF0FDF4,
                                  ).withValues(alpha: 0.0),
                                ],
                      ),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (int i = 0; i < lines.length; i++)
                          _buildChip(lines[i], p, isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildChip(
    ({String text, double threshold, bool big}) line,
    double p,
    bool isDark,
  ) {
    final visible = p >= line.threshold;
    final chipA =
        visible ? (((p - line.threshold) / 0.25).clamp(0.0, 1.0)) : 0.0;

    final accent = isDark ? const Color(0xFFFFC83D) : const Color(0xFFFFC83D);
    final textCol =
        line.big
            ? Color.lerp(accent.withValues(alpha: 0.35), accent, chipA)!
            : (isDark ? Colors.white : const Color(0xFF1E4028)).withValues(
              alpha: chipA * 0.82,
            );

    return AnimatedOpacity(
      opacity: chipA.clamp(0.0, 1.0),
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: line.big ? 10 : 8,
          vertical: line.big ? 5 : 4,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: chipA * (line.big ? 0.14 : 0.08)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withValues(alpha: chipA * (line.big ? 0.50 : 0.22)),
            width: 0.9,
          ),
        ),
        child: Text(
          line.text,
          style: GoogleFonts.outfit(
            fontSize: line.big ? 13.5 * _fade.value : 11.5,
            fontWeight: line.big ? FontWeight.w800 : FontWeight.w600,
            color: textCol,
            letterSpacing: line.big ? 0.5 : 0.2,
          ),
        ),
      ),
    );
  }
}

class _NoorTree extends StatefulWidget {
  final double progress; // 0.0 → 1.0
  final bool isComplete;
  final int tapCount; // triggers particle burst on change
  final int pointsToday;

  const _NoorTree({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_NoorTree> createState() => _NoorTreeState();
}

class _NoorTreeState extends State<_NoorTree> with TickerProviderStateMixin {
  late AnimationController _swayCtrl;
  late Animation<double> _sway;
  late AnimationController _growCtrl;
  late Animation<double> _grow;
  double _prevProgress = 0.0;
  late AnimationController _starCtrl;
  late AnimationController _pCtrl;
  late Animation<double> _pAnim;
  int _prevTap = 0;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // Tap-punch: quick scale bump on each tap
  late AnimationController _punchCtrl;
  late Animation<double> _punch;

  // Shockwave ring that expands outward on tap
  late AnimationController _shockCtrl;
  late Animation<double> _shock;

  // Shooting star streaks on tap
  late AnimationController _shootCtrl;
  late Animation<double> _shootAnim;

  final List<_Particle> _particles = List.generate(
    20,
    (i) => _Particle(seed: i),
  );
  final List<_ShootingStar> _shootingStars = List.generate(
    3,
    (i) => _ShootingStar(seed: i),
  );

  @override
  void initState() {
    super.initState();

    _swayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: true);
    _sway = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _swayCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.94,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.05,
          end: 0.98,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.98,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _shootCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _shootAnim = CurvedAnimation(parent: _shootCtrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(_NoorTree old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
      for (final s in _shootingStars) {
        s.reset();
      }
      _shootCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _swayCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _pulseCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _shootCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _swayCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _pulseCtrl,
        _punchCtrl,
        _shockCtrl,
        _shootCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _NoorTreePainter(
                progress: _grow.value,
                sway: _sway.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pulse: _pulse.value,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                shootPhase: _shootAnim.value,
                shootingStars: _shootingStars,
              ),
            ),
          ),
    );
  }
}

class _Particle {
  late double x;
  late double startY;
  late double size;
  late double speed;
  late Color color;
  late double drift; // horizontal wave amplitude
  static final _rng = math.Random();

  // Golden vs teal palette for richer variety
  static const _palette = [
    Color(0xFF1BDE9A),
    Color(0xFF2EC4A9),
    Color(0xFF26C97A),
    Color(0xFF3ACF58),
    Color(0xFFD4AF37),
    Color(0xFFFFD97D),
    Color(0xFF00FFCC),
    Color(0xFFF5C842),
  ];

  _Particle({required int seed}) {
    reset(seed: seed);
  }

  void reset({int? seed}) {
    final r = seed != null ? math.Random(seed * 1337) : _rng;
    x = (r.nextDouble() - 0.5) * 1.8;
    startY = 0.50 + r.nextDouble() * 0.30;
    size = 2.0 + r.nextDouble() * 4.0;
    speed = 0.35 + r.nextDouble() * 0.65;
    drift = 8.0 + r.nextDouble() * 14.0;
    color = _palette[r.nextInt(_palette.length)];
  }
}

class _ShootingStar {
  late double startX, startY, angle, length, speed;
  static final _rng = math.Random();

  _ShootingStar({required int seed}) {
    reset(seed: seed);
  }

  void reset({int? seed}) {
    final r = seed != null ? math.Random(seed * 7919) : _rng;
    startX = 0.1 + r.nextDouble() * 0.8;
    startY = 0.02 + r.nextDouble() * 0.18;
    angle = 0.3 + r.nextDouble() * 0.5; // downward-right angle
    length = 0.08 + r.nextDouble() * 0.12;
    speed = 0.6 + r.nextDouble() * 0.4;
  }
}

/// Shared light background for all illustration painters.
void _paintLightBg(Canvas canvas, double w, double h, {double progress = 0}) {
  final warmth = progress * 0.08;
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w, h),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromRGBO(
            (240 - warmth * 15).round(),
            (245 - warmth * 10).round(),
            (242 - warmth * 8).round(),
            1.0,
          ),
          Color.fromRGBO(
            (235 - warmth * 20).round(),
            (240 - warmth * 12).round(),
            (238 - warmth * 10).round(),
            1.0,
          ),
          Color.fromRGBO(
            (228 - warmth * 25).round(),
            (234 - warmth * 15).round(),
            (230 - warmth * 12).round(),
            1.0,
          ),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h)),
  );
}

class _NoorTreePainter extends CustomPainter {
  final double progress;
  final double sway;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final double pulse;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double shootPhase;
  final List<_ShootingStar> shootingStars;

  const _NoorTreePainter({
    required this.progress,
    required this.sway,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    required this.pulse,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.shootPhase = 1.0,
    this.shootingStars = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 1. Softer gradient — lighter tones to reduce eye strain
    _paintLightBg(canvas, w, h, progress: progress);

    // 2. Stars
    const starPos = [
      (0.08, 0.06),
      (0.18, 0.14),
      (0.32, 0.04),
      (0.55, 0.09),
      (0.71, 0.05),
      (0.84, 0.15),
      (0.92, 0.07),
      (0.45, 0.18),
      (0.63, 0.22),
      (0.25, 0.20),
      (0.77, 0.18),
      (0.12, 0.27),
      (0.90, 0.25),
      (0.38, 0.29),
      (0.59, 0.33),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      sp.color = Colors.white.withValues(alpha: 0.15 + 0.35 * tw);
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h),
        1.1 + tw * 1.2,
        sp,
      );
    }

    // 2b. Shooting stars on tap
    if (shootPhase > 0 && shootPhase < 1) {
      for (final s in shootingStars) {
        final t = (shootPhase / s.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final sx = s.startX * w + t * s.length * w * math.cos(s.angle);
        final sy = s.startY * h + t * s.length * h * math.sin(s.angle);
        final tailLen = s.length * w * 0.5 * (1.0 - t);
        final tailX = sx - tailLen * math.cos(s.angle);
        final tailY = sy - tailLen * math.sin(s.angle);
        final sa = (1.0 - t) * 0.9;
        canvas.drawLine(
          Offset(tailX, tailY),
          Offset(sx, sy),
          Paint()
            ..shader = LinearGradient(
              colors: [
                Colors.transparent,
                const Color(0xFFD4AF37).withValues(alpha: sa),
              ],
            ).createShader(
              Rect.fromPoints(Offset(tailX, tailY), Offset(sx, sy)),
            )
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
        // Head glow
        canvas.drawCircle(
          Offset(sx, sy),
          2.5,
          Paint()..color = Colors.white.withValues(alpha: sa * 0.8),
        );
      }
    }

    // 3. Crescent moon (proper path — no dark masking circle)
    final moonA = progress.clamp(0.05, 1.0);
    const moonX = 0.83;
    const moonY = 0.13;
    const moonR = 13.0;
    final mCx = moonX * w;
    final mCy = moonY * h;
    // Glow behind crescent
    canvas.drawCircle(
      Offset(mCx, mCy),
      moonR + 6,
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: moonA * 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Crescent via path difference (outer circle minus inner offset circle)
    final outerPath =
        Path()
          ..addOval(Rect.fromCircle(center: Offset(mCx, mCy), radius: moonR));
    final innerPath =
        Path()..addOval(
          Rect.fromCircle(
            center: Offset(mCx + moonR * 0.55, mCy - moonR * 0.1),
            radius: moonR * 0.9,
          ),
        );
    final crescentPath = Path.combine(
      PathOperation.difference,
      outerPath,
      innerPath,
    );
    canvas.drawPath(
      crescentPath,
      Paint()..color = const Color(0xFFD4AF37).withValues(alpha: moonA * 0.85),
    );

    // 4. Ground — soft grass-like glow
    final groundY = h * 0.82;
    final groundGlow =
        0.10 +
        progress * 0.08 +
        (punchScale > 1.0 ? (punchScale - 1.0) * 1.5 : 0.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, groundY + 10),
        width: w * 0.75,
        height: 24,
      ),
      Paint()
        ..color = Color.fromRGBO(52, 211, 153, groundGlow.clamp(0.0, 0.30))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    // Ground line
    canvas.drawLine(
      Offset(cx - w * 0.32, groundY),
      Offset(cx + w * 0.32, groundY),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFFFFC83D).withValues(alpha: 0.25),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(cx - w * 0.32, groundY, w * 0.64, 1))
        ..strokeWidth = 0.8,
    );

    // Apply punch scale transform for the tree (trunk + leaves)
    canvas.save();
    final pTree = 0.20 + progress * 0.80;
    final treeCenterY = groundY - (groundY - h * 0.28) * pTree * 0.5;
    canvas.translate(cx, treeCenterY);
    // punch scale removed
    canvas.translate(-cx, -treeCenterY);

    // 5. Trunk — tapered with gradient
    if (pTree > 0.02) {
      final trunkH = (groundY - h * 0.28) * pTree.clamp(0.0, 1.0);
      final trunkTop = Offset(cx + sway * 2, groundY - trunkH);
      final trunkBot = Offset(cx, groundY);
      final trunkW = 7.5 * (0.5 + pTree * 0.5);

      // Tapered trunk path (wider at base, thinner at top)
      final trunkPath =
          Path()
            ..moveTo(trunkBot.dx - trunkW * 0.5, trunkBot.dy)
            ..quadraticBezierTo(
              cx - trunkW * 0.3 + sway,
              groundY - trunkH * 0.5,
              trunkTop.dx - trunkW * 0.18,
              trunkTop.dy,
            )
            ..lineTo(trunkTop.dx + trunkW * 0.18, trunkTop.dy)
            ..quadraticBezierTo(
              cx + trunkW * 0.3 + sway,
              groundY - trunkH * 0.5,
              trunkBot.dx + trunkW * 0.5,
              trunkBot.dy,
            )
            ..close();
      canvas.drawPath(
        trunkPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [const Color(0xFF5C3A1E), const Color(0xFF8B6341)],
          ).createShader(
            Rect.fromLTWH(
              trunkBot.dx - trunkW,
              trunkTop.dy,
              trunkW * 2,
              trunkH,
            ),
          ),
      );

      // Bark texture lines
      if (pTree > 0.15) {
        final barkPaint =
            Paint()
              ..color = const Color(0xFF4A2E14).withValues(alpha: 0.25)
              ..strokeWidth = 0.6;
        for (int i = 0; i < 4; i++) {
          final by = groundY - trunkH * (0.15 + i * 0.22);
          canvas.drawLine(
            Offset(cx - trunkW * 0.15 + sway * (by / groundY), by),
            Offset(
              cx + trunkW * 0.05 + sway * (by / groundY),
              by - trunkH * 0.06,
            ),
            barkPaint,
          );
        }
      }

      // Branches that reach toward leaf positions
      if (pTree > 0.15) {
        _drawBranches(
          canvas,
          trunkBot,
          trunkTop,
          sway,
          pTree,
          Paint()
            ..color = const Color(0xFF6B4A2A)
            ..strokeWidth = trunkW * 0.35
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // 6. Leaf orbs — vibrant and diverse
    if (pTree > 0.05) {
      final trunkH = (groundY - h * 0.28) * pTree;
      final treeTop = Offset(cx + sway * 2, groundY - trunkH);

      // (rx, ry, radius, minProgress, color)
      // Positioned to align with branch endpoints
      const leafDefs = [
        // Crown top cluster
        (0.0, -0.05, 24.0, 0.10, Color(0xFFFFC83D)), // emerald
        (-0.15, 0.06, 18.0, 0.15, Color(0xFFFFC83D)), // mint
        (0.18, 0.04, 17.0, 0.18, Color(0xFFFBBF24)), // amber
        // Left branch cluster
        (-0.45, 0.16, 20.0, 0.22, Color(0xFF818CF8)), // indigo
        (-0.62, 0.28, 16.0, 0.30, Color(0xFFA78BFA)), // violet
        (-0.38, 0.32, 14.0, 0.35, Color(0xFFFFC83D)), // teal
        // Right branch cluster
        (0.48, 0.18, 19.0, 0.25, Color(0xFFF472B6)), // pink
        (0.65, 0.30, 15.0, 0.32, Color(0xFFFB923C)), // orange
        (0.42, 0.34, 13.0, 0.38, Color(0xFFFFC83D)), // emerald
        // Lower left sub-branch
        (-0.72, 0.42, 14.0, 0.45, Color(0xFF38BDF8)), // sky blue
        (-0.50, 0.48, 12.0, 0.52, Color(0xFFA78BFA)), // violet
        // Lower right sub-branch
        (0.75, 0.44, 13.0, 0.50, Color(0xFFFBBF24)), // amber
        (0.55, 0.50, 11.0, 0.55, Color(0xFFF472B6)), // pink
        // Mid fills
        (0.0, 0.30, 15.0, 0.60, Color(0xFFFFC83D)), // mint
        (-0.22, 0.20, 13.0, 0.65, Color(0xFFFFC83D)), // emerald
        (0.25, 0.22, 12.0, 0.70, Color(0xFF38BDF8)), // sky blue
        // Top crown extras
        (0.0, -0.12, 16.0, 0.80, Color(0xFFFFD97D)), // gold
        (-0.10, 0.50, 10.0, 0.88, Color(0xFFFFC83D)), // teal
        (0.12, 0.52, 10.0, 0.94, Color(0xFFFB923C)), // orange
      ];
      final halfW = w * 0.28;
      for (final (rx, ry, r, minP, col) in leafDefs) {
        if (pTree < minP) continue;
        final leafA = ((pTree - minP) / 0.10).clamp(0.0, 1.0);
        final leafPos = Offset(
          treeTop.dx + rx * halfW,
          treeTop.dy + ry * trunkH * 0.55,
        );
        final leafR = r * (0.65 + pTree * 0.35) * (isComplete ? pulse : 1.0);
        // Soft glow
        canvas.drawCircle(
          leafPos,
          leafR + 10,
          Paint()
            ..color = col.withValues(alpha: leafA * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
        // Orb fill with vibrant gradient
        canvas.drawCircle(
          leafPos,
          leafR,
          Paint()
            ..shader = RadialGradient(
              colors: [
                Colors.white.withValues(alpha: leafA * 0.50),
                col.withValues(alpha: leafA * 0.92),
                col.withValues(alpha: leafA * 0.30),
              ],
              stops: const [0.0, 0.45, 1.0],
            ).createShader(Rect.fromCircle(center: leafPos, radius: leafR)),
        );
        // Highlight dot
        canvas.drawCircle(
          Offset(leafPos.dx - leafR * 0.25, leafPos.dy - leafR * 0.25),
          leafR * 0.22,
          Paint()..color = Colors.white.withValues(alpha: leafA * 0.60),
        );
      }

      // 6b. Golden crown glow on completion
      if (isComplete) {
        final crownY = treeTop.dy - 10;
        canvas.drawCircle(
          Offset(cx + sway * 2, crownY),
          36 * pulse,
          Paint()
            ..color = const Color(0xFFD4AF37).withValues(alpha: 0.14 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
        );
        canvas.drawCircle(
          Offset(cx + sway * 2, crownY),
          20 * pulse,
          Paint()
            ..color = const Color(0xFFFFD97D).withValues(alpha: 0.22 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );
      }
    }

    // 6c. Small colorful plants growing beside the tree
    if (progress > 0.08) {
      // (xOffset from center, height, bloom radius, minProgress, stemColor, bloomColor)
      const plants = [
        // Left side
        (
          -0.30,
          18.0,
          4.5,
          0.08,
          Color(0xFF4ADE80),
          Color(0xFFF472B6),
        ), // green stem, pink bloom
        (
          -0.22,
          12.0,
          3.5,
          0.20,
          Color(0xFFFFC83D),
          Color(0xFFFBBF24),
        ), // emerald stem, amber bloom
        (
          -0.38,
          15.0,
          4.0,
          0.35,
          Color(0xFF2DD4BF),
          Color(0xFF818CF8),
        ), // teal stem, indigo bloom
        (
          -0.18,
          10.0,
          3.0,
          0.55,
          Color(0xFF4ADE80),
          Color(0xFFFF6B6B),
        ), // green stem, coral bloom
        (
          -0.30,
          18.0,
          4.5,
          0.08,
          Color(0xFFFFC83D),
          Color(0xFFF472B6),
        ), // green stem, pink bloom
        // Right side
        (
          0.28,
          16.0,
          4.2,
          0.12,
          Color(0xFFFFC83D),
          Color(0xFFFBBF24),
        ), // emerald stem, amber bloom
        (
          0.20,
          11.0,
          3.3,
          0.28,
          Color(0xFF4ADE80),
          Color(0xFFA78BFA),
        ), // green stem, violet bloom
        (
          0.36,
          14.0,
          3.8,
          0.42,
          Color(0xFF2DD4BF),
          Color(0xFFF472B6),
        ), // teal stem, pink bloom
        (
          0.16,
          9.0,
          2.8,
          0.62,
          Color(0xFFFFC83D),
          Color(0xFF38BDF8),
        ), // emerald stem, sky bloom
        (
          0.28,
          16.0,
          4.2,
          0.12,
          Color(0xFFFFC83D),
          Color(0xFFFBBF24),
        ), // emerald stem, amber bloom
      ];

      for (final (xOff, maxH, bloomR, minP, stemCol, bloomCol) in plants) {
        if (progress < minP) continue;
        final plantProg = ((progress - minP) / 0.18).clamp(0.0, 1.0);
        final px = cx + xOff * w;
        final plantH = maxH * plantProg;
        final stemTop = groundY - plantH;

        // Stem — thin curved line
        final stemPath =
            Path()
              ..moveTo(px, groundY)
              ..quadraticBezierTo(
                px + sway * 0.5 + xOff * 3,
                groundY - plantH * 0.6,
                px + sway * 0.8,
                stemTop,
              );
        canvas.drawPath(
          stemPath,
          Paint()
            ..color = stemCol.withValues(alpha: plantProg * 0.70)
            ..strokeWidth = 1.3
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );

        // Small leaf on stem (appears at 40% of plant's growth)
        if (plantProg > 0.4) {
          final leafProg = ((plantProg - 0.4) / 0.3).clamp(0.0, 1.0);
          final leafY = groundY - plantH * 0.5;
          final leafX = px + sway * 0.3;
          final leafSize = 3.0 * leafProg;
          final leafPath =
              Path()
                ..moveTo(leafX, leafY)
                ..quadraticBezierTo(
                  leafX + leafSize * (xOff > 0 ? 1.5 : -1.5),
                  leafY - leafSize,
                  leafX + leafSize * (xOff > 0 ? 0.5 : -0.5),
                  leafY + leafSize * 0.3,
                );
          canvas.drawPath(
            leafPath,
            Paint()
              ..color = stemCol.withValues(alpha: leafProg * 0.55)
              ..style = PaintingStyle.fill,
          );
        }

        // Bloom/flower at top (appears at 60% of plant's growth)
        if (plantProg > 0.6) {
          final bloomProg = ((plantProg - 0.6) / 0.4).clamp(0.0, 1.0);
          final bx = px + sway * 0.8;
          final by = stemTop;
          final br = bloomR * bloomProg * (isComplete ? pulse : 1.0);

          // Glow
          canvas.drawCircle(
            Offset(bx, by),
            br + 4,
            Paint()
              ..color = bloomCol.withValues(alpha: bloomProg * 0.10)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
          // Bloom
          canvas.drawCircle(
            Offset(bx, by),
            br,
            Paint()
              ..shader = RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: bloomProg * 0.50),
                  bloomCol.withValues(alpha: bloomProg * 0.80),
                ],
              ).createShader(
                Rect.fromCircle(center: Offset(bx, by), radius: br),
              ),
          );
          // Bright center
          canvas.drawCircle(
            Offset(bx, by),
            br * 0.30,
            Paint()..color = Colors.white.withValues(alpha: bloomProg * 0.45),
          );
        }
      }
    }

    canvas.restore(); // end punch scale

    // 7. Shockwave ring on tap — expands from tree center
    // tap-effect removed — smooth calm

    // 8. Floating noor particles — with trails
    // tap-effect removed — smooth calm

    // 9. Progress label
    // progress % label removed

    // 10. Noor points badge
  }

  void _drawBranches(
    Canvas canvas,
    Offset bot,
    Offset top,
    double sway,
    double progress,
    Paint basePaint,
  ) {
    final trunkH = bot.dy - top.dy;
    final cx = bot.dx;

    // Branch definitions: (trunkFraction, leftReach, upReach, minProgress, thickness)
    // Each branch reaches toward where the leaf clusters are
    const branches = [
      // Main left branch (toward left leaf cluster at rx=-0.45...-0.62)
      (0.55, -0.55, 0.30, 0.20, 0.50),
      // Main right branch (toward right cluster at rx=0.48...0.65)
      (0.55, 0.58, 0.28, 0.22, 0.48),
      // Lower left sub-branch (toward rx=-0.72)
      (0.38, -0.70, 0.18, 0.40, 0.35),
      // Lower right sub-branch (toward rx=0.75)
      (0.38, 0.72, 0.16, 0.42, 0.33),
      // Upper left twig
      (0.72, -0.32, 0.22, 0.55, 0.25),
      // Upper right twig
      (0.72, 0.35, 0.20, 0.58, 0.24),
    ];

    final halfW = (bot.dx - top.dx).abs() + basePaint.strokeWidth * 8;

    for (final (frac, reach, upR, minP, thick) in branches) {
      if (progress < minP) continue;
      final branchAlpha = ((progress - minP) / 0.15).clamp(0.0, 1.0);
      final anchorY = bot.dy - trunkH * frac;
      final anchorX = cx + sway * (1.0 - frac) * 2;
      final endX = anchorX + reach * halfW + sway * 1.5;
      final endY = anchorY - upR * trunkH;

      // Curved branch using quadratic bezier
      final ctrlX = anchorX + reach * halfW * 0.4;
      final ctrlY = anchorY - upR * trunkH * 0.2;

      final branchPath =
          Path()
            ..moveTo(anchorX, anchorY)
            ..quadraticBezierTo(ctrlX, ctrlY, endX, endY);

      canvas.drawPath(
        branchPath,
        Paint()
          ..color = Color.fromRGBO(107, 74, 42, branchAlpha * 0.75)
          ..strokeWidth = basePaint.strokeWidth * thick
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_NoorTreePainter o) =>
      o.progress != progress ||
      o.sway != sway ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pulse != pulse ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.shootPhase != shootPhase;
}

// =============================================================================
// 🛡️ Protection Shield (درع الحماية) — Ayat al-Kursi illustration
// =============================================================================
class _ProtectionShield extends StatefulWidget {
  final double progress; // 0.0 → 1.0
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _ProtectionShield({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_ProtectionShield> createState() => _ProtectionShieldState();
}

class _ProtectionShieldState extends State<_ProtectionShield>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _growCtrl;
  late Animation<double> _grow;
  double _prevProgress = 0.0;
  late AnimationController _starCtrl;
  late AnimationController _pCtrl;
  late Animation<double> _pAnim;
  int _prevTap = 0;
  late AnimationController _punchCtrl;
  late Animation<double> _punch;
  late AnimationController _shockCtrl;
  late Animation<double> _shock;
  late AnimationController _rotateCtrl;

  final List<_Particle> _particles = List.generate(
    20,
    (i) => _Particle(seed: i + 100),
  );

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);

    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat();
  }

  @override
  void didUpdateWidget(_ProtectionShield old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _rotateCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _ProtectionShieldPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                rotatePhase: _rotateCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _ProtectionShieldPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double rotatePhase;

  const _ProtectionShieldPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.rotatePhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.48;

    // 1. Night-sky gradient background (deeper blue-purple for protection theme)
    _paintLightBg(canvas, w, h, progress: progress);

    // 2. Stars
    const starPos = [
      (0.08, 0.06),
      (0.18, 0.14),
      (0.32, 0.04),
      (0.55, 0.09),
      (0.71, 0.05),
      (0.84, 0.15),
      (0.92, 0.07),
      (0.45, 0.18),
      (0.63, 0.22),
      (0.25, 0.20),
      (0.77, 0.18),
      (0.12, 0.27),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      sp.color = Colors.white.withValues(alpha: 0.20 + 0.55 * tw);
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h),
        1.0 + tw * 1.0,
        sp,
      );
    }

    // 3. Ground line
    final groundY = h * 0.82;
    canvas.drawLine(
      Offset(cx - w * 0.30, groundY),
      Offset(cx + w * 0.30, groundY),
      Paint()
        ..color = const Color(0xFF4A90D9).withValues(alpha: 0.15)
        ..strokeWidth = 0.7,
    );

    // Apply punch scale
    canvas.save();
    // punch scale removed — smooth calm tap

    // 4. Person silhouette (praying figure)
    _drawPerson(canvas, cx, groundY);

    // 5. Shield in front of person
    if (progress > 0.02) {
      _drawShieldDome(canvas, cx, cy, w, h, groundY);
    }

    canvas.restore(); // end punch scale

    // 7. Shockwave ring on tap
    // tap-effect removed — smooth calm

    // 8. Floating particles
    // tap-effect removed — smooth calm

    // 9. Progress label
    // progress % label removed

    // 10. Noor points badge
  }

  /// Standing person — clean, simple silhouette facing forward
  void _drawPerson(Canvas canvas, double cx, double groundY) {
    final baseAlpha = isComplete ? 0.90 : 0.75;
    final personColor =
        isComplete
            ? Color.fromRGBO(190, 155, 30, baseAlpha)
            : Color.fromRGBO(75, 130, 190, baseAlpha);
    final glowColor =
        isComplete
            ? const Color(0xFFD4AF37).withValues(alpha: 0.16)
            : const Color(0xFF4A90D9).withValues(alpha: 0.12);

    final fill = Paint()..color = personColor;

    final baseY = groundY - 3;
    const headR = 7.5;
    final headCy = baseY - 62;

    // ── Glow behind ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY - 32), width: 40, height: 68),
      Paint()
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // ── Head ──
    canvas.drawCircle(Offset(cx, headCy), headR, fill);

    // ── Neck ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, headCy + headR + 2.5),
          width: 5,
          height: 5,
        ),
        const Radius.circular(2),
      ),
      fill,
    );

    // ── Body (long thobe — single smooth shape from shoulders to feet) ──
    final shoulderY = headCy + headR + 5;
    final hemY = baseY - 1;

    final robePath =
        Path()
          ..moveTo(cx, shoulderY - 2) // neckline center
          ..quadraticBezierTo(
            cx - 14,
            shoulderY,
            cx - 13,
            shoulderY + 6,
          ) // left shoulder
          ..quadraticBezierTo(
            cx - 12,
            (shoulderY + hemY) * 0.45,
            cx - 10,
            hemY * 0.65 + shoulderY * 0.35,
          ) // left waist
          ..quadraticBezierTo(
            cx - 11,
            hemY - 8,
            cx - 14,
            hemY,
          ) // left hem flare
          ..lineTo(cx + 14, hemY) // across bottom
          ..quadraticBezierTo(
            cx + 11,
            hemY - 8,
            cx + 10,
            hemY * 0.65 + shoulderY * 0.35,
          ) // right waist
          ..quadraticBezierTo(
            cx + 12,
            (shoulderY + hemY) * 0.45,
            cx + 13,
            shoulderY + 6,
          ) // right shoulder
          ..quadraticBezierTo(
            cx + 14,
            shoulderY,
            cx,
            shoulderY - 2,
          ) // back to neckline
          ..close();
    canvas.drawPath(robePath, fill);

    // Center fold line
    canvas.drawLine(
      Offset(cx, shoulderY + 4),
      Offset(cx, hemY - 3),
      Paint()
        ..color = Colors.white.withValues(alpha: baseAlpha * 0.10)
        ..strokeWidth = 0.6,
    );

    // ── Arms at sides (simple straight lines, relaxed) ──
    final armPaint =
        Paint()
          ..color = personColor
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(cx - 13, shoulderY + 5),
      Offset(cx - 12, shoulderY + 28),
      armPaint,
    );
    canvas.drawLine(
      Offset(cx + 13, shoulderY + 5),
      Offset(cx + 12, shoulderY + 28),
      armPaint,
    );

    // ── Feet (small) ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 6, hemY + 2), width: 8, height: 3),
      fill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 6, hemY + 2), width: 8, height: 3),
      fill,
    );
  }

  /// Large shield shape positioned in front of the person
  void _drawShieldDome(
    Canvas canvas,
    double cx,
    double cy,
    double w,
    double h,
    double groundY,
  ) {
    final personCy = groundY - 34;
    final baseColor =
        isComplete ? const Color(0xFFD4AF37) : const Color(0xFF4A90D9);
    final appear = progress.clamp(0.0, 1.0);

    // Shield dimensions — covers most of the person
    final shieldW = w * 0.22 * appear;
    final shieldH = (groundY - personCy + 20) * 0.85 * appear;
    final shieldCy = personCy + 2;

    // Glow behind shield
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, shieldCy),
        width: shieldW * 2.5,
        height: shieldH * 1.6,
      ),
      Paint()
        ..color = baseColor.withValues(alpha: appear * 0.08 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // Shield shape — pointed top, wide middle, pointed bottom
    final shieldPath =
        Path()
          ..moveTo(cx, shieldCy - shieldH * 0.52) // top point
          ..quadraticBezierTo(
            cx + shieldW * 1.1,
            shieldCy - shieldH * 0.30,
            cx + shieldW,
            shieldCy,
          ) // right top curve
          ..quadraticBezierTo(
            cx + shieldW * 0.9,
            shieldCy + shieldH * 0.30,
            cx,
            shieldCy + shieldH * 0.52,
          ) // right bottom to point
          ..quadraticBezierTo(
            cx - shieldW * 0.9,
            shieldCy + shieldH * 0.30,
            cx - shieldW,
            shieldCy,
          ) // left bottom curve
          ..quadraticBezierTo(
            cx - shieldW * 1.1,
            shieldCy - shieldH * 0.30,
            cx,
            shieldCy - shieldH * 0.52,
          ) // left top back to top
          ..close();

    // Shield fill — gradient
    final fillAlpha = appear * (isComplete ? 0.35 : 0.20);
    canvas.drawPath(
      shieldPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            baseColor.withValues(alpha: fillAlpha * 1.2),
            baseColor.withValues(alpha: fillAlpha * 0.6),
            baseColor.withValues(alpha: fillAlpha * 0.3),
          ],
        ).createShader(
          Rect.fromCenter(
            center: Offset(cx, shieldCy),
            width: shieldW * 2,
            height: shieldH,
          ),
        ),
    );

    // Shield border — thick and prominent
    final borderAlpha = appear * (isComplete ? 0.80 : 0.60);
    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = baseColor.withValues(alpha: borderAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isComplete ? 3.5 : 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Inner shield decoration — smaller shield outline inside
    if (appear > 0.4) {
      final innerA = ((appear - 0.4) / 0.6).clamp(0.0, 1.0);
      final iw = shieldW * 0.65;
      final ih = shieldH * 0.65;
      final innerPath =
          Path()
            ..moveTo(cx, shieldCy - ih * 0.52)
            ..quadraticBezierTo(
              cx + iw * 1.1,
              shieldCy - ih * 0.30,
              cx + iw,
              shieldCy,
            )
            ..quadraticBezierTo(
              cx + iw * 0.9,
              shieldCy + ih * 0.30,
              cx,
              shieldCy + ih * 0.52,
            )
            ..quadraticBezierTo(
              cx - iw * 0.9,
              shieldCy + ih * 0.30,
              cx - iw,
              shieldCy,
            )
            ..quadraticBezierTo(
              cx - iw * 1.1,
              shieldCy - ih * 0.30,
              cx,
              shieldCy - ih * 0.52,
            )
            ..close();
      canvas.drawPath(
        innerPath,
        Paint()
          ..color = baseColor.withValues(alpha: innerA * borderAlpha * 0.40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // Center emblem — small circle with dot
    if (appear > 0.3) {
      final emblemA = ((appear - 0.3) / 0.7).clamp(0.0, 1.0) * borderAlpha;
      canvas.drawCircle(
        Offset(cx, shieldCy),
        6,
        Paint()
          ..color = baseColor.withValues(alpha: emblemA * 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        Offset(cx, shieldCy),
        2.5,
        Paint()..color = baseColor.withValues(alpha: emblemA * 0.50),
      );
    }

    // Completion glow
    if (isComplete) {
      final haloAlpha = 0.12 * pulse;
      canvas.drawPath(
        shieldPath,
        Paint()
          ..color = baseColor.withValues(alpha: haloAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  /// Small orbiting dot markers around the shields
  void _drawOrbitingMarkers(Canvas canvas, double cx, double cy, double w) {
    final orbitRx = w * 0.36;
    final orbitRy = w * 0.18;
    final centerY = cy + (190 * 0.82 - 30 - cy);
    final markerCount = ((progress - 0.3) / 0.7 * 6).ceil().clamp(0, 6);

    for (int i = 0; i < markerCount; i++) {
      final baseAngle = rotatePhase * math.pi * 2 + i * (math.pi * 2 / 6);
      final mx = cx + math.cos(baseAngle) * orbitRx;
      final my = centerY + math.sin(baseAngle) * orbitRy;
      final mAlpha = isComplete ? 0.75 : 0.50;

      canvas.drawCircle(
        Offset(mx, my),
        5.0,
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: mAlpha * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        Offset(mx, my),
        2.5,
        Paint()..color = const Color(0xFFD4AF37).withValues(alpha: mAlpha),
      );
    }
  }

  @override
  bool shouldRepaint(_ProtectionShieldPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.rotatePhase != rotatePhase;
}

// =============================================================================
// 🛡️🛡️🛡️ Three Quls (المعوذات) — 3 layered barriers illustration
// =============================================================================
class _ThreeQuls extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _ThreeQuls({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_ThreeQuls> createState() => _ThreeQulsState();
}

class _ThreeQulsState extends State<_ThreeQuls> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _growCtrl;
  late Animation<double> _grow;
  double _prevProgress = 0.0;
  late AnimationController _starCtrl;
  late AnimationController _pCtrl;
  late Animation<double> _pAnim;
  int _prevTap = 0;
  late AnimationController _punchCtrl;
  late Animation<double> _punch;
  late AnimationController _shockCtrl;
  late Animation<double> _shock;
  late AnimationController _shimmerCtrl;

  final List<_Particle> _particles = List.generate(
    18,
    (i) => _Particle(seed: i + 200),
  );

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);

    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void didUpdateWidget(_ThreeQuls old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _shimmerCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _ThreeQulsPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                shimmerPhase: _shimmerCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _ThreeQulsPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double shimmerPhase;

  // Three barrier colors — each represents a Surah
  // Ikhlas (inner, white-gold) → Falaq (middle, teal) → Nas (outer, violet)
  static const _layerColors = [
    Color(0xFFD4AF37), // Ikhlas — golden sincerity
    Color(0xFF2EC4A9), // Falaq — teal dawn light
    Color(0xFF8B5CF6), // Nas — violet divine refuge
  ];

  const _ThreeQulsPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.shimmerPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.45;

    // 1. Deep night-sky background (purple-tinted for Quls theme)
    _paintLightBg(canvas, w, h, progress: progress);

    // 2. Stars
    const starPos = [
      (0.10, 0.07),
      (0.22, 0.15),
      (0.38, 0.05),
      (0.52, 0.10),
      (0.68, 0.06),
      (0.82, 0.14),
      (0.90, 0.08),
      (0.42, 0.20),
      (0.60, 0.24),
      (0.28, 0.22),
      (0.75, 0.19),
      (0.15, 0.28),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      sp.color = Colors.white.withValues(alpha: 0.18 + 0.50 * tw);
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h),
        0.9 + tw * 1.0,
        sp,
      );
    }

    // Apply punch scale
    canvas.save();
    // punch scale removed — smooth calm tap

    // 3. Central book/Quran symbol
    _drawQuranSymbol(canvas, cx, cy);

    // 4. Three concentric barrier layers
    _drawBarrierLayers(canvas, cx, cy, w);

    canvas.restore();

    // 5. Shockwave on tap
    // tap-effect removed — smooth calm

    // 6. Floating particles
    // tap-effect removed — smooth calm

    // 7. Progress label
    // progress % label removed

    // 8. Points badge
  }

  /// Central Quran/book icon
  void _drawQuranSymbol(Canvas canvas, double cx, double cy) {
    final bookAlpha = isComplete ? 0.85 : 0.65;
    final bookColor =
        isComplete
            ? Color.fromRGBO(212, 175, 55, bookAlpha)
            : Color.fromRGBO(200, 200, 220, bookAlpha);
    final glowAlpha = isComplete ? 0.15 : 0.08;

    // Glow behind book
    canvas.drawCircle(
      Offset(cx, cy),
      38,
      Paint()
        ..color = (isComplete
                ? const Color(0xFFD4AF37)
                : const Color(0xFF8B5CF6))
            .withValues(alpha: glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // Open book shape — two pages (scaled up ~1.8x)
    final bookPaint =
        Paint()
          ..color = bookColor
          ..style = PaintingStyle.fill;

    // Left page
    final leftPage =
        Path()
          ..moveTo(cx - 2, cy - 18)
          ..quadraticBezierTo(cx - 25, cy - 22, cx - 28, cy - 10)
          ..lineTo(cx - 27, cy + 14)
          ..quadraticBezierTo(cx - 23, cy + 18, cx - 2, cy + 16)
          ..close();
    canvas.drawPath(leftPage, bookPaint);

    // Right page
    final rightPage =
        Path()
          ..moveTo(cx + 2, cy - 18)
          ..quadraticBezierTo(cx + 25, cy - 22, cx + 28, cy - 10)
          ..lineTo(cx + 27, cy + 14)
          ..quadraticBezierTo(cx + 23, cy + 18, cx + 2, cy + 16)
          ..close();
    canvas.drawPath(rightPage, bookPaint);

    // Spine
    canvas.drawLine(
      Offset(cx, cy - 20),
      Offset(cx, cy + 17),
      Paint()
        ..color = bookColor
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Page lines (subtle text lines)
    final linePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: bookAlpha * 0.40)
          ..strokeWidth = 0.7;
    for (int i = 0; i < 5; i++) {
      final ly = cy - 10 + i * 5.0;
      canvas.drawLine(Offset(cx - 22, ly), Offset(cx - 5, ly), linePaint);
      canvas.drawLine(Offset(cx + 5, ly), Offset(cx + 22, ly), linePaint);
    }

    // Small highlight on top-left corner of book
    canvas.drawCircle(
      Offset(cx - 8, cy - 8),
      2.5,
      Paint()..color = Colors.white.withValues(alpha: bookAlpha * 0.25),
    );
  }

  /// Three concentric barrier rings
  void _drawBarrierLayers(Canvas canvas, double cx, double cy, double w) {
    // Each layer appears at a different progress threshold
    // Layer 0 (Ikhlas/inner): 0% → 33%
    // Layer 1 (Falaq/middle): 33% → 66%
    // Layer 2 (Nas/outer): 66% → 100%
    const layerRadii = [52.0, 72.0, 92.0];
    const layerThresholds = [0.0, 0.33, 0.66];

    for (int i = 0; i < 3; i++) {
      final threshold = layerThresholds[i];
      if (progress <= threshold) continue;

      final layerProgress = ((progress - threshold) / 0.33).clamp(0.0, 1.0);
      final color = _layerColors[i];
      final radius = layerRadii[i] * (0.6 + layerProgress * 0.4);

      // How much of the ring to draw (sweeps from 0 to half circle dome)
      final sweep = math.pi * layerProgress;

      // Outer glow
      final glowA = layerProgress * (isComplete ? 0.14 : 0.08) * pulse;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius + 8),
        math.pi,
        sweep,
        false,
        Paint()
          ..color = color.withValues(alpha: glowA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );

      // Main arc — starts from left, sweeps clockwise forming a dome
      final startAngle = math.pi;
      final arcAlpha = layerProgress * (isComplete ? 0.80 : 0.60);

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = color.withValues(alpha: arcAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isComplete ? 2.8 : 2.0
          ..strokeCap = StrokeCap.round,
      );

      // Dashed secondary arc (slightly inside, gives depth)
      if (layerProgress > 0.4) {
        final innerR = radius - 4;
        final dashAlpha = (layerProgress - 0.4) / 0.6 * 0.25;
        final dashCount = (layerProgress * 8).ceil();
        final dashSweep = sweep / (dashCount * 2);
        for (int d = 0; d < dashCount; d++) {
          final dAngle = startAngle + d * dashSweep * 2;
          canvas.drawArc(
            Rect.fromCircle(center: Offset(cx, cy), radius: innerR),
            dAngle,
            dashSweep,
            false,
            Paint()
              ..color = color.withValues(alpha: dashAlpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0
              ..strokeCap = StrokeCap.round,
          );
        }
      }

      // Leading bright dot at the sweep tip
      if (layerProgress < 1.0 && layerProgress > 0.05) {
        final tipAngle = startAngle + sweep;
        final tipX = cx + math.cos(tipAngle) * radius;
        final tipY = cy + math.sin(tipAngle) * radius;
        canvas.drawCircle(
          Offset(tipX, tipY),
          3.5,
          Paint()
            ..color = color.withValues(alpha: 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(tipX, tipY),
          2.0,
          Paint()..color = color.withValues(alpha: arcAlpha * 1.2),
        );
      }

      // Completion: small Surah label dots at 3 positions
      if (isComplete) {
        final dotAngle = -math.pi / 2 + i * (math.pi * 2 / 3);
        final dx = cx + math.cos(dotAngle) * radius;
        final dy = cy + math.sin(dotAngle) * radius;
        canvas.drawCircle(
          Offset(dx, dy),
          4.0 * pulse,
          Paint()
            ..color = color.withValues(alpha: 0.30)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        canvas.drawCircle(
          Offset(dx, dy),
          2.5,
          Paint()..color = color.withValues(alpha: 0.70),
        );
      }
    }

    // Completion: connecting radial lines between layers
    if (isComplete) {
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3 + shimmerPhase * math.pi * 0.2;
        final innerX = cx + math.cos(angle) * layerRadii[0] * 0.9;
        final innerY = cy + math.sin(angle) * layerRadii[0] * 0.9;
        final outerX = cx + math.cos(angle) * layerRadii[2] * 1.05;
        final outerY = cy + math.sin(angle) * layerRadii[2] * 1.05;
        canvas.drawLine(
          Offset(innerX, innerY),
          Offset(outerX, outerY),
          Paint()
            ..shader = LinearGradient(
              colors: [
                const Color(0xFFD4AF37).withValues(alpha: 0.08 * pulse),
                const Color(0xFF8B5CF6).withValues(alpha: 0.15 * pulse),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromPoints(Offset(innerX, innerY), Offset(outerX, outerY)),
            )
            ..strokeWidth = 1.0
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ThreeQulsPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.shimmerPhase != shimmerPhase;
}

// =============================================================================
// 🚪 Gates of Jannah (أبواب الجنة) — Sayyid al-Istighfar illustration
// =============================================================================
class _GatesOfJannah extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _GatesOfJannah({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_GatesOfJannah> createState() => _GatesOfJannahState();
}

class _GatesOfJannahState extends State<_GatesOfJannah>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _growCtrl;
  late Animation<double> _grow;
  double _prevProgress = 0.0;
  late AnimationController _starCtrl;
  late AnimationController _pCtrl;
  late Animation<double> _pAnim;
  int _prevTap = 0;
  late AnimationController _punchCtrl;
  late Animation<double> _punch;
  late AnimationController _shockCtrl;
  late Animation<double> _shock;
  late AnimationController _rayCtrl;

  final List<_Particle> _particles = List.generate(
    18,
    (i) => _Particle(seed: i + 300),
  );

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);

    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _rayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void didUpdateWidget(_GatesOfJannah old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _rayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _rayCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _GatesOfJannahPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                rayPhase: _rayCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _GatesOfJannahPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double rayPhase;

  const _GatesOfJannahPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.rayPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 1. Background — warm dark gradient (paradise hues)
    _paintLightBg(canvas, w, h, progress: progress);

    // 2. Stars
    const starPos = [
      (0.09, 0.07),
      (0.20, 0.16),
      (0.35, 0.05),
      (0.50, 0.11),
      (0.65, 0.06),
      (0.80, 0.14),
      (0.91, 0.08),
      (0.40, 0.21),
      (0.58, 0.25),
      (0.26, 0.23),
      (0.73, 0.20),
      (0.14, 0.29),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      sp.color = Colors.white.withValues(alpha: 0.15 + 0.45 * tw);
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h),
        0.9 + tw * 0.9,
        sp,
      );
    }

    // Ground line
    final groundY = h * 0.80;
    canvas.drawLine(
      Offset(cx - w * 0.35, groundY),
      Offset(cx + w * 0.35, groundY),
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.12)
        ..strokeWidth = 0.7,
    );

    // Apply punch scale
    canvas.save();
    final gateCy = groundY - 50;
    canvas.translate(cx, gateCy);
    // punch scale removed
    canvas.translate(-cx, -gateCy);

    // 3. Light behind gates (grows with progress)
    _drawInnerLight(canvas, cx, groundY, w, h);

    // 4. Gate structure
    _drawGates(canvas, cx, groundY, w);

    // 5. Arch above gates
    _drawArch(canvas, cx, groundY, w);

    canvas.restore();

    // 6. Shockwave on tap
    // tap-effect removed — smooth calm

    // 7. Floating particles — rise upward through the gate opening
    // tap-effect removed — smooth calm

    // 8. Progress label
    // progress % label removed

    // 9. Points badge
  }

  /// Warm paradise light that shines through the gap between the gates
  void _drawInnerLight(
    Canvas canvas,
    double cx,
    double groundY,
    double w,
    double h,
  ) {
    if (progress <= 0.05) return;

    // Gap width grows with progress (gates opening)
    final gapWidth = w * 0.22 * progress;
    final lightAlpha = progress * (isComplete ? 0.55 : 0.35) * pulse;

    // Vertical light beam through gap
    final beamRect = Rect.fromCenter(
      center: Offset(cx, groundY - 45),
      width: gapWidth,
      height: 80,
    );
    canvas.drawRect(
      beamRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(255, 248, 220, lightAlpha * 1.2),
            Color.fromRGBO(212, 175, 55, lightAlpha),
            Colors.transparent,
          ],
        ).createShader(beamRect),
    );

    // Radial glow at center
    canvas.drawCircle(
      Offset(cx, groundY - 45),
      gapWidth * 1.5,
      Paint()
        ..color = Color.fromRGBO(255, 248, 220, lightAlpha * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // Light rays fanning upward from the gap (on completion)
    if (progress > 0.5) {
      final rayAlpha =
          ((progress - 0.5) / 0.5) * (isComplete ? 0.25 : 0.10) * pulse;
      for (int i = 0; i < 7; i++) {
        final angle =
            -math.pi / 2 +
            (i - 3) * 0.15 +
            math.sin(rayPhase * math.pi * 2 + i) * 0.03;
        final rayLen = 50 + (isComplete ? 25.0 : 0.0);
        final startX = cx;
        final startY = groundY - 65;
        final endX = startX + math.cos(angle) * rayLen;
        final endY = startY + math.sin(angle) * rayLen;
        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          Paint()
            ..shader = LinearGradient(
              colors: [
                Color.fromRGBO(255, 248, 220, rayAlpha),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromPoints(Offset(startX, startY), Offset(endX, endY)),
            )
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  /// Two gate doors that open outward with progress
  void _drawGates(Canvas canvas, double cx, double groundY, double w) {
    final gateH = 85.0;
    final gateW = 28.0;
    final gateTop = groundY - gateH;

    // Opening angle: 0 (closed) → progress-based swing outward
    final openAmount = progress * gateW * 0.9;

    final gateColor =
        isComplete
            ? const Color(0xFFD4AF37).withValues(alpha: 0.92)
            : Color.lerp(
              const Color(0xFFC5A044),
              const Color(0xFFD4AF37),
              progress,
            )!.withValues(alpha: 0.85);
    final gateEdge =
        isComplete
            ? const Color(0xFFB8962E).withValues(alpha: 0.80)
            : const Color(0xFFA08030).withValues(alpha: 0.65);
    final decorColor =
        isComplete
            ? const Color(0xFFE8C860).withValues(alpha: 0.70)
            : const Color(0xFFBFA050).withValues(alpha: 0.50);

    // Left gate door
    final leftX = cx - 2 - openAmount;
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(leftX - gateW, gateTop, gateW, gateH),
      const Radius.circular(2),
    );
    canvas.drawRRect(leftRect, Paint()..color = gateColor);
    canvas.drawRRect(
      leftRect,
      Paint()
        ..color = gateEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Left door decorative panels (2 rectangles)
    for (int i = 0; i < 2; i++) {
      final panelY = gateTop + 8 + i * (gateH * 0.44);
      final panelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(leftX - gateW + 4, panelY, gateW - 8, gateH * 0.34),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(
        panelRect,
        Paint()
          ..color = decorColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // Left door handle
    canvas.drawCircle(
      Offset(leftX - 4, groundY - gateH * 0.45),
      2.0,
      Paint()..color = decorColor,
    );

    // Right gate door (mirror)
    final rightX = cx + 2 + openAmount;
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rightX, gateTop, gateW, gateH),
      const Radius.circular(2),
    );
    canvas.drawRRect(rightRect, Paint()..color = gateColor);
    canvas.drawRRect(
      rightRect,
      Paint()
        ..color = gateEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Right door decorative panels
    for (int i = 0; i < 2; i++) {
      final panelY = gateTop + 8 + i * (gateH * 0.44);
      final panelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(rightX + 4, panelY, gateW - 8, gateH * 0.34),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(
        panelRect,
        Paint()
          ..color = decorColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // Right door handle
    canvas.drawCircle(
      Offset(rightX + 4, groundY - gateH * 0.45),
      2.0,
      Paint()..color = decorColor,
    );

    // Gate pillars (fixed, don't move)
    final pillarColor =
        isComplete
            ? const Color(0xFFD4AF37).withValues(alpha: 0.85)
            : const Color(0xFFB89830).withValues(alpha: 0.75);
    // Left pillar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - gateW - openAmount - 6, gateTop - 4, 5, gateH + 4),
        const Radius.circular(1.5),
      ),
      Paint()..color = pillarColor,
    );
    // Right pillar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + gateW + openAmount + 1, gateTop - 4, 5, gateH + 4),
        const Radius.circular(1.5),
      ),
      Paint()..color = pillarColor,
    );

    // Pillar caps (small decorative tops)
    final capColor =
        isComplete
            ? const Color(0xFFFFD97D).withValues(alpha: 0.80)
            : const Color(0xFFD4AF37).withValues(alpha: 0.70);
    canvas.drawCircle(
      Offset(cx - gateW - openAmount - 3.5, gateTop - 6),
      3.5,
      Paint()..color = capColor,
    );
    canvas.drawCircle(
      Offset(cx + gateW + openAmount + 3.5, gateTop - 6),
      3.5,
      Paint()..color = capColor,
    );
  }

  /// Pointed arch above the gates
  void _drawArch(Canvas canvas, double cx, double groundY, double w) {
    if (progress < 0.15) return;

    final archAlpha = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
    final gateH = 85.0;
    final gateW = 28.0;
    final openAmount = progress * gateW * 0.9;
    final archTop = groundY - gateH - 22;
    final archLeft = cx - gateW - openAmount - 8;
    final archRight = cx + gateW + openAmount + 8;
    final archMidY = groundY - gateH - 4;

    final archColor =
        isComplete
            ? Color.fromRGBO(212, 175, 55, archAlpha * 0.85)
            : Color.fromRGBO(196, 160, 50, archAlpha * 0.75);

    // Pointed Islamic arch shape
    final archPath =
        Path()
          ..moveTo(archLeft, archMidY)
          ..quadraticBezierTo(archLeft, archTop + 8, cx, archTop)
          ..quadraticBezierTo(archRight, archTop + 8, archRight, archMidY);

    canvas.drawPath(
      archPath,
      Paint()
        ..color = archColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // Inner arch (smaller, more subtle)
    if (progress > 0.4) {
      final innerAlpha = ((progress - 0.4) / 0.6).clamp(0.0, 1.0) * 0.30;
      final inset = 5.0;
      final innerPath =
          Path()
            ..moveTo(archLeft + inset, archMidY)
            ..quadraticBezierTo(archLeft + inset, archTop + 12, cx, archTop + 6)
            ..quadraticBezierTo(
              archRight - inset,
              archTop + 12,
              archRight - inset,
              archMidY,
            );

      canvas.drawPath(
        innerPath,
        Paint()
          ..color =
              isComplete
                  ? Color.fromRGBO(255, 217, 125, innerAlpha)
                  : Color.fromRGBO(184, 151, 106, innerAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // Keystone at arch peak
    if (progress > 0.6) {
      final kAlpha = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
      final kColor =
          isComplete
              ? Color.fromRGBO(212, 175, 55, kAlpha * 0.65 * pulse)
              : Color.fromRGBO(184, 151, 106, kAlpha * 0.40);

      // Diamond keystone
      final kPath =
          Path()
            ..moveTo(cx, archTop - 3)
            ..lineTo(cx + 5, archTop + 3)
            ..lineTo(cx, archTop + 9)
            ..lineTo(cx - 5, archTop + 3)
            ..close();
      canvas.drawPath(kPath, Paint()..color = kColor);

      // Glow around keystone on completion
      if (isComplete) {
        canvas.drawCircle(
          Offset(cx, archTop + 3),
          10 * pulse,
          Paint()
            ..color = const Color(0xFFD4AF37).withValues(alpha: 0.10 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GatesOfJannahPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.rayPhase != rayPhase;
}

// =============================================================================
// ⛓️ Breaking Chains (كسر القيود) — Protection from anxiety/laziness/debt
// =============================================================================
class _BreakingChains extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _BreakingChains({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_BreakingChains> createState() => _BreakingChainsState();
}

class _BreakingChainsState extends State<_BreakingChains>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _growCtrl;
  late Animation<double> _grow;
  double _prevProgress = 0.0;
  late AnimationController _starCtrl;
  late AnimationController _pCtrl;
  late Animation<double> _pAnim;
  int _prevTap = 0;
  late AnimationController _punchCtrl;
  late Animation<double> _punch;
  late AnimationController _shockCtrl;
  late Animation<double> _shock;
  late AnimationController _floatCtrl;

  final List<_Particle> _particles = List.generate(
    16,
    (i) => _Particle(seed: i + 400),
  );

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);

    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_BreakingChains old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _floatCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _BreakingChainsPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                floatPhase: _floatCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _BreakingChainsPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double floatPhase;

  // 4 pairs: anxiety/grief, inability/laziness, cowardice/miserliness, debt/oppression
  static const _chainColors = [
    Color(0xFF6B7280), // steel grey
    Color(0xFF78716C), // warm grey
    Color(0xFF71717A), // zinc
    Color(0xFF64748B), // slate
  ];

  const _BreakingChainsPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.floatPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.44;

    // 1. Background — dark steel/charcoal (oppressive → freeing)
    final bgBrightness = progress * 0.15;
    _paintLightBg(canvas, w, h, progress: progress);

    // 2. Stars (more visible as chains break)
    const starPos = [
      (0.10, 0.08),
      (0.22, 0.16),
      (0.38, 0.06),
      (0.52, 0.12),
      (0.68, 0.07),
      (0.82, 0.15),
      (0.90, 0.09),
      (0.42, 0.22),
      (0.58, 0.26),
      (0.28, 0.24),
      (0.75, 0.21),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      final starAlpha = (0.08 + progress * 0.35 + 0.45 * tw * progress);
      sp.color = Colors.white.withValues(alpha: starAlpha.clamp(0.0, 0.8));
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h),
        0.8 + tw * 1.0,
        sp,
      );
    }

    // Apply punch scale
    canvas.save();
    // punch scale removed — smooth calm tap

    // 3. Central light (person freed — grows as chains break)
    _drawFreedomLight(canvas, cx, cy, w);

    // 4. Four chains arranged around center
    _drawChains(canvas, cx, cy, w, h);

    canvas.restore();

    // 5. Shockwave on tap
    // tap-effect removed — smooth calm

    // 6. Floating sparks on tap
    // tap-effect removed — smooth calm

    // 7. Progress label
    // progress % label removed

    // 8. Points badge
  }

  /// Central light that grows as chains break — representing freedom
  void _drawFreedomLight(Canvas canvas, double cx, double cy, double w) {
    if (progress < 0.05) return;

    final lightR = 12 + progress * 25;
    final alpha = progress * (isComplete ? 0.30 : 0.15) * pulse;

    // Outer glow
    canvas.drawCircle(
      Offset(cx, cy),
      lightR + 15,
      Paint()
        ..color = Color.fromRGBO(16, 185, 129, alpha * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // Inner glow
    canvas.drawCircle(
      Offset(cx, cy),
      lightR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(255, 255, 255, alpha * 0.8),
            Color.fromRGBO(16, 185, 129, alpha * 0.6),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: lightR)),
    );

    // On completion: golden core
    if (isComplete) {
      canvas.drawCircle(
        Offset(cx, cy),
        8 * pulse,
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: 0.35 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        4,
        Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.50),
      );
    }
  }

  /// Four chains arranged around the center — each breaks at its progress threshold
  void _drawChains(Canvas canvas, double cx, double cy, double w, double h) {
    // 4 chains positioned at top, right, bottom, left
    final positions = [
      (cx, cy - 50, 0.0, -1.0), // top — vertical up
      (cx + 55, cy, 1.0, 0.0), // right — horizontal
      (cx, cy + 45, 0.0, 1.0), // bottom — vertical down
      (cx - 55, cy, -1.0, 0.0), // left — horizontal
    ];

    for (int i = 0; i < 4; i++) {
      final (startX, startY, dirX, dirY) = positions[i];
      final breakThreshold = (i + 1) * 0.25; // breaks at 25%, 50%, 75%, 100%
      final isBroken = progress >= breakThreshold;
      final chainProgress = ((progress - i * 0.25) / 0.25).clamp(0.0, 1.0);

      _drawSingleChain(
        canvas,
        startX,
        startY,
        dirX,
        dirY,
        i,
        isBroken,
        chainProgress,
        cx,
        cy,
      );
    }
  }

  void _drawSingleChain(
    Canvas canvas,
    double startX,
    double startY,
    double dirX,
    double dirY,
    int index,
    bool isBroken,
    double chainProgress,
    double cx,
    double cy,
  ) {
    final color = _chainColors[index];
    final linkCount = 4;
    final linkLen = 8.0;
    final linkW = 5.0;

    if (isBroken) {
      // Chain is broken — links fall away
      final fallT = chainProgress.clamp(0.0, 1.0);

      for (int j = 0; j < linkCount; j++) {
        final dist = j * (linkLen + 2);
        // Each link falls with slight delay
        final linkFall = ((fallT - j * 0.08)).clamp(0.0, 1.0);

        // Falling offset — drops down and outward
        final fallX =
            startX +
            dirX * dist +
            dirX * linkFall * 12 +
            math.sin(floatPhase * math.pi * 2 + j) * linkFall * 3;
        final fallY =
            startY + dirY * dist + linkFall * 25 + linkFall * linkFall * 15;
        final fallAlpha = (1.0 - linkFall) * 0.50;

        if (fallAlpha < 0.02) continue;

        // Rotation of falling link
        final rot = linkFall * (0.5 + j * 0.3);

        canvas.save();
        canvas.translate(fallX, fallY);
        canvas.rotate(rot);

        // Chain link — rounded rectangle outline
        final linkRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: linkW, height: linkLen),
          const Radius.circular(2.5),
        );
        canvas.drawRRect(
          linkRect,
          Paint()
            ..color = color.withValues(alpha: fallAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        canvas.restore();
      }

      // Break spark at the connection point
      if (chainProgress < 0.6) {
        final sparkA = (1.0 - chainProgress / 0.6) * 0.60;
        canvas.drawCircle(
          Offset(startX, startY),
          5 * (1.0 - chainProgress * 0.5),
          Paint()
            ..color = const Color(0xFFFFC83D).withValues(alpha: sparkA)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(startX, startY),
          2.5,
          Paint()..color = Colors.white.withValues(alpha: sparkA * 0.8),
        );
      }
    } else {
      // Chain is intact — draw taut links connecting to center
      final chainAlpha =
          0.55 - progress * 0.15; // fade slightly as overall progress grows

      for (int j = 0; j < linkCount; j++) {
        final dist = j * (linkLen + 2);
        final lx = startX + dirX * dist;
        final ly = startY + dirY * dist;

        // Subtle strain vibration as progress approaches break point
        final strainProg = ((progress - index * 0.25) / 0.25).clamp(0.0, 1.0);
        final shake =
            strainProg > 0.5
                ? math.sin(floatPhase * math.pi * 8 + j * 2) * strainProg * 2
                : 0.0;

        final shakeX = dirY != 0 ? shake : 0.0; // shake perpendicular to chain
        final shakeY = dirX != 0 ? shake : 0.0;

        // Chain link
        canvas.save();
        canvas.translate(lx + shakeX, ly + shakeY);

        // Rotate links to align with chain direction
        if (dirX != 0) {
          canvas.rotate(math.pi / 2);
        }

        final linkRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: linkW, height: linkLen),
          const Radius.circular(2.5),
        );
        canvas.drawRRect(
          linkRect,
          Paint()
            ..color = color.withValues(alpha: chainAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );

        canvas.restore();
      }

      // Connection dot to center
      canvas.drawCircle(
        Offset(startX, startY),
        2.5,
        Paint()..color = color.withValues(alpha: chainAlpha * 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_BreakingChainsPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.floatPhase != floatPhase;
}

// =============================================================================
// 🛡️ Afiyah Guard (morning_19 / evening_19) — text-based illustration
// "Well-being in this world & the Hereafter" — Abu Dawud 5074
// Deep teal shield · phrases cascade in · six-directions badge on completion
// =============================================================================
class _AfiyahGuard extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _AfiyahGuard({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_AfiyahGuard> createState() => _AfiyahGuardState();
}

class _AfiyahGuardState extends State<_AfiyahGuard>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl,
      _growCtrl,
      _pCtrl,
      _punchCtrl,
      _shockCtrl,
      _revealCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _growCtrl.animateTo(widget.progress);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _revealCtrl.forward();
    });
  }

  @override
  void didUpdateWidget(_AfiyahGuard old) {
    super.didUpdateWidget(old);
    _growCtrl.animateTo(widget.progress);
    if (widget.tapCount > old.tapCount) {
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _revealCtrl,
        _shockCtrl,
      ]),
      builder: (context, _) {
        final pulse = _pulseCtrl.value;
        final reveal = _revealCtrl.value;
        final shock = _shockCtrl.value;

        const teal = Color(0xFF00BFA5);
        const gold = Color(0xFFD4AF37);
        const body = Color(0xFFB2DFDB);

        Widget heroCard(
          String line1,
          String line2,
          Color accent,
          double threshold,
        ) {
          final t = ((reveal - threshold) / 0.35).clamp(0.0, 1.0);
          return Opacity(
            opacity: t,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accent.withValues(alpha: 0.40),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    line1,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    line2,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      color: accent.withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        Widget subLine(String text, double threshold) {
          final t = ((reveal - threshold) / 0.30).clamp(0.0, 1.0);
          return Opacity(
            opacity: t,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                color: body,
                letterSpacing: 0.1,
              ),
            ),
          );
        }

        Widget dirBadge() {
          final t = ((reveal - 0.62) / 0.35).clamp(0.0, 1.0);
          const dirs = ['Front', 'Back', 'Right', 'Left', 'Above', 'Below'];
          return Opacity(
            opacity: t,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 5,
              runSpacing: 4,
              children:
                  dirs
                      .map(
                        (d) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: teal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: teal.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            d,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: teal.withValues(alpha: 0.90),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          );
        }

        return ClipRect(
          child: SizedBox(
            height: 260,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Dark teal background
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D2B2B),
                        Color(0xFF0A3333),
                        Color(0xFF0D2020),
                      ],
                    ),
                  ),
                ),
                // Pulse ring — smaller so it doesn't clip the top
                Center(
                  child: Container(
                    width: 130 + pulse * 10,
                    height: 130 + pulse * 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(
                          0xFF00BFA5,
                        ).withValues(alpha: 0.05 + pulse * 0.04),
                        width: 22,
                      ),
                    ),
                  ),
                ),
                // Tap shock ring
                if (shock > 0)
                  Center(
                    child: Container(
                      width: shock * 220,
                      height: shock * 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: teal.withValues(alpha: (1 - shock) * 0.35),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                // Text content — wider padding makes it appear narrower
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Two hero cards side-by-side: Dunya | Akhirah
                      Row(
                        children: [
                          Expanded(
                            child: heroCard(
                              AppLocalizations.of(context)?.thisWorld ??
                                  'This World',
                              AppLocalizations.of(context)?.dunyaArabic ??
                                  'Dunya',
                              teal,
                              0.00,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: heroCard(
                              AppLocalizations.of(context)?.hereafter ??
                                  'Hereafter',
                              AppLocalizations.of(context)?.akhirahArabic ??
                                  'Akhirah',
                              gold,
                              0.18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      subLine('Well-being in Faith · Family · Wealth', 0.32),
                      const SizedBox(height: 4),
                      subLine('Conceal my faults · Calm my fears', 0.50),
                      const SizedBox(height: 6),
                      dirBadge(),
                      const SizedBox(height: 4),
                      Opacity(
                        opacity: ((reveal - 0.82) / 0.22).clamp(0.0, 1.0),
                        child: Text(
                          'Guard me from all six sides',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: teal.withValues(alpha: 0.60),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// 🏰 Six Wards (حصن العافية) — Protection from 6 directions
// =============================================================================
class _SixWards extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _SixWards({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_SixWards> createState() => _SixWardsState();
}

class _SixWardsState extends State<_SixWards> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _growCtrl;
  late Animation<double> _grow;
  double _prevProgress = 0.0;
  late AnimationController _starCtrl;
  late AnimationController _pCtrl;
  late Animation<double> _pAnim;
  int _prevTap = 0;
  late AnimationController _punchCtrl;
  late Animation<double> _punch;
  late AnimationController _shockCtrl;
  late Animation<double> _shock;
  late AnimationController _glowCtrl;

  final List<_Particle> _particles = List.generate(
    18,
    (i) => _Particle(seed: i + 500),
  );

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void didUpdateWidget(_SixWards old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _glowCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _SixWardsPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                glowPhase: _glowCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _SixWardsPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double glowPhase;

  // 6 directions this dua covers: front, behind, right, left, above, below
  // Each ward gets a distinct color
  static const _wardColors = [
    Color(0xFF2EC4A9), // front — teal
    Color(0xFF4A90D9), // behind — blue
    Color(0xFFF59E0B), // right — amber
    Color(0xFF8B5CF6), // left — violet
    Color(0xFFD4AF37), // above — gold
    Color(0xFFFFC83D), // below — emerald
  ];

  static const _wardLabels = ['أمام', 'خلف', 'يمين', 'شمال', 'فوق', 'تحت'];

  const _SixWardsPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.glowPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.42;

    // 1. Background — deep teal-dark (wellbeing/healing theme)
    _paintLightBg(canvas, w, h, progress: progress);

    // 2. Stars
    const starPos = [
      (0.09, 0.06),
      (0.21, 0.15),
      (0.36, 0.05),
      (0.53, 0.10),
      (0.67, 0.06),
      (0.81, 0.14),
      (0.91, 0.08),
      (0.43, 0.20),
      (0.60, 0.24),
      (0.27, 0.22),
      (0.74, 0.19),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      sp.color = Colors.white.withValues(alpha: 0.18 + 0.50 * tw);
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h),
        0.9 + tw * 1.0,
        sp,
      );
    }

    // Apply punch scale
    canvas.save();
    // punch scale removed — smooth calm tap

    // 3. Central person silhouette (small, subtle)
    _drawPerson(canvas, cx, cy);

    // 4. Six directional ward panels (hexagonal arrangement)
    _drawWards(canvas, cx, cy, w);

    // 5. Connecting lines from center to each ward
    if (progress > 0.1) {
      _drawConnections(canvas, cx, cy, w);
    }

    canvas.restore();

    // 6. Shockwave on tap
    // tap-effect removed — smooth calm

    // 7. Particles — rise outward in 6 directions
    // tap-effect removed — smooth calm

    // 8. Progress label
    // progress % label removed
    // 9. Points badge
  }

  void _drawPerson(Canvas canvas, double cx, double cy) {
    final alpha = isComplete ? 0.75 : 0.55;
    final color =
        isComplete
            ? Color.fromRGBO(212, 175, 55, alpha)
            : Color.fromRGBO(46, 196, 169, alpha);

    // Glow
    canvas.drawCircle(
      Offset(cx, cy),
      16,
      Paint()
        ..color = color.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Head
    canvas.drawCircle(Offset(cx, cy - 10), 4.5, Paint()..color = color);
    // Body
    canvas.drawLine(
      Offset(cx, cy - 6),
      Offset(cx, cy + 8),
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    // Arms out (receiving protection)
    canvas.drawLine(
      Offset(cx, cy - 2),
      Offset(cx - 10, cy + 2),
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(cx, cy - 2),
      Offset(cx + 10, cy + 2),
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawWards(Canvas canvas, double cx, double cy, double w) {
    final wardR = w * 0.30; // distance from center to ward

    for (int i = 0; i < 6; i++) {
      final threshold = (i + 1) / 6.0;
      if (progress < threshold - 1.0 / 6.0) continue;

      final wardProgress = ((progress - (i / 6.0)) * 6.0).clamp(0.0, 1.0);
      final angle = i * math.pi / 3 - math.pi / 2; // start from top
      final wx = cx + math.cos(angle) * wardR;
      final wy = cy + math.sin(angle) * wardR * 0.55; // flatten vertically
      final color = _wardColors[i];

      // Ward panel — small hexagonal shield
      final panelSize = 14.0 * wardProgress * (isComplete ? pulse : 1.0);

      // Outer glow
      final glowA = wardProgress * (isComplete ? 0.20 : 0.10);
      canvas.drawCircle(
        Offset(wx, wy),
        panelSize + 10,
        Paint()
          ..color = color.withValues(alpha: glowA)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Hexagonal ward shape
      final hexPath = Path();
      for (int v = 0; v < 6; v++) {
        final ha = v * math.pi / 3 - math.pi / 6 + glowPhase * math.pi * 0.1;
        final hx = wx + math.cos(ha) * panelSize;
        final hy = wy + math.sin(ha) * panelSize;
        if (v == 0) {
          hexPath.moveTo(hx, hy);
        } else {
          hexPath.lineTo(hx, hy);
        }
      }
      hexPath.close();

      // Fill
      final fillA = wardProgress * (isComplete ? 0.30 : 0.15);
      canvas.drawPath(hexPath, Paint()..color = color.withValues(alpha: fillA));

      // Border
      final borderA = wardProgress * (isComplete ? 0.80 : 0.60);
      canvas.drawPath(
        hexPath,
        Paint()
          ..color = color.withValues(alpha: borderA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isComplete ? 2.0 : 1.5
          ..strokeJoin = StrokeJoin.round,
      );

      // Inner bright dot
      canvas.drawCircle(
        Offset(wx, wy),
        2.5 * wardProgress,
        Paint()..color = color.withValues(alpha: wardProgress * 0.60),
      );
      canvas.drawCircle(
        Offset(wx, wy),
        1.2 * wardProgress,
        Paint()..color = Colors.white.withValues(alpha: wardProgress * 0.45),
      );

      // Direction label removed
    }
  }

  void _drawConnections(Canvas canvas, double cx, double cy, double w) {
    final wardR = w * 0.30;

    for (int i = 0; i < 6; i++) {
      final threshold = (i + 1) / 6.0;
      if (progress < threshold - 1.0 / 6.0 + 0.05) continue;

      final connProgress = ((progress - (i / 6.0) - 0.05) * 6.0).clamp(
        0.0,
        1.0,
      );
      final angle = i * math.pi / 3 - math.pi / 2;
      final wx = cx + math.cos(angle) * wardR * connProgress;
      final wy = cy + math.sin(angle) * wardR * 0.55 * connProgress;
      final color = _wardColors[i];

      final lineAlpha = connProgress * (isComplete ? 0.30 : 0.18);
      canvas.drawLine(
        Offset(cx, cy),
        Offset(wx, wy),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: lineAlpha * 0.5),
              color.withValues(alpha: lineAlpha),
            ],
          ).createShader(Rect.fromPoints(Offset(cx, cy), Offset(wx, wy)))
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );

      // Traveling dot along the connection line
      if (connProgress > 0.3 && connProgress < 1.0) {
        final dotT = ((glowPhase * 2 + i * 0.15) % 1.0);
        final dx = cx + (wx - cx) * dotT;
        final dy = cy + (wy - cy) * dotT;
        canvas.drawCircle(
          Offset(dx, dy),
          1.8,
          Paint()..color = color.withValues(alpha: 0.50),
        );
      }
    }

    // On completion: connecting hex ring between all wards
    if (isComplete) {
      for (int i = 0; i < 6; i++) {
        final a1 = i * math.pi / 3 - math.pi / 2;
        final a2 = ((i + 1) % 6) * math.pi / 3 - math.pi / 2;
        final x1 = cx + math.cos(a1) * wardR;
        final y1 = cy + math.sin(a1) * wardR * 0.55;
        final x2 = cx + math.cos(a2) * wardR;
        final y2 = cy + math.sin(a2) * wardR * 0.55;

        canvas.drawLine(
          Offset(x1, y1),
          Offset(x2, y2),
          Paint()
            ..color = const Color(0xFFD4AF37).withValues(alpha: 0.15 * pulse)
            ..strokeWidth = 1.0
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SixWardsPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.glowPhase != glowPhase;
}

// =============================================================================
// 💡 Repelling Light (نور الحماية) — Protection from 4 evils
// =============================================================================
class _RepellingLight extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _RepellingLight({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_RepellingLight> createState() => _RepellingLightState();
}

class _RepellingLightState extends State<_RepellingLight>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _growCtrl;
  late Animation<double> _grow;
  double _prevProgress = 0.0;
  late AnimationController _starCtrl;
  late AnimationController _pCtrl;
  late Animation<double> _pAnim;
  int _prevTap = 0;
  late AnimationController _punchCtrl;
  late Animation<double> _punch;
  late AnimationController _shockCtrl;
  late Animation<double> _shock;
  late AnimationController _driftCtrl;

  final List<_Particle> _particles = List.generate(
    16,
    (i) => _Particle(seed: i + 600),
  );

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _driftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void didUpdateWidget(_RepellingLight old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _driftCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _driftCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _RepellingLightPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                driftPhase: _driftCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _RepellingLightPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double driftPhase;

  // 4 evils: self, shaytan, shirk, harming others
  static const _shadowColors = [
    Color(0xFF3B0764), // self — deep purple
    Color(0xFF7F1D1D), // shaytan — blood red
    Color(0xFF1C1C1C), // shirk — near black
    Color(0xFF0C1E3A), // harming others — deep navy
  ];

  const _RepellingLightPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.driftPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.43;

    // 1. Background — very dark purple/black (ominous → purified)
    final purify = progress * 0.20;
    _paintLightBg(canvas, w, h, progress: progress);

    // 2. Stars — more visible as evils are repelled
    const starPos = [
      (0.10, 0.07),
      (0.23, 0.16),
      (0.37, 0.05),
      (0.54, 0.11),
      (0.68, 0.07),
      (0.82, 0.15),
      (0.92, 0.09),
      (0.44, 0.21),
      (0.61, 0.25),
      (0.29, 0.23),
      (0.76, 0.20),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      final starA = (0.06 + progress * 0.40 + 0.40 * tw * progress);
      sp.color = Colors.white.withValues(alpha: starA.clamp(0.0, 0.75));
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h),
        0.8 + tw * 1.0,
        sp,
      );
    }

    // Apply punch scale
    canvas.save();
    // punch scale removed — smooth calm tap

    // 3. Four shadow entities being pushed back
    _drawShadows(canvas, cx, cy, w, h);

    // 4. Central divine light (grows as shadows retreat)
    _drawCentralLight(canvas, cx, cy, w);

    canvas.restore();

    // 5. Shockwave on tap
    // tap-effect removed — smooth calm

    // 6. Particles — light sparks pushing outward
    // tap-effect removed — smooth calm

    // 7a. "Evil Eye" fire-style title
    if (progress > 0.03) {
      final titleAlpha = (progress / 0.25).clamp(0.0, 1.0);
      final titlePainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Evil ',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                foreground:
                    Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFFFF6B00), Color(0xFFFF2200)],
                      ).createShader(const Rect.fromLTWH(0, 0, 80, 28))
                      ..maskFilter = const MaskFilter.blur(
                        BlurStyle.solid,
                        0.5,
                      ),
                letterSpacing: 2.5,
              ),
            ),
            TextSpan(
              text: 'Eye',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                foreground:
                    Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFFFF2200), Color(0xFF8B0000)],
                      ).createShader(const Rect.fromLTWH(0, 0, 60, 28))
                      ..maskFilter = const MaskFilter.blur(
                        BlurStyle.solid,
                        0.5,
                      ),
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w);

      // Fire glow behind title
      final glowPaint =
          Paint()
            ..color = const Color(
              0xFFFF4400,
            ).withValues(alpha: titleAlpha * 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx, h * 0.82),
          width: titlePainter.width + 40,
          height: 34,
        ),
        glowPaint,
      );

      // Draw title with alpha
      canvas.save();
      canvas.translate((w - titlePainter.width) / 2, h * 0.79);
      final titleAlphaPaint =
          Paint()..color = Colors.white.withValues(alpha: titleAlpha);
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, titlePainter.width, 30),
        titleAlphaPaint,
      );
      titlePainter.paint(canvas, Offset.zero);
      canvas.restore();
      canvas.restore();
    }

    // 7b. Protection label — always fully visible (was gated on progress > 0.05
    // with a 0..30% progress fade, leaving the label hidden until well into
    // counting).
    {
      final tp = TextPainter(
        text: TextSpan(
          text: 'Protection from Evil Eye',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFCA5A5).withValues(alpha: 0.80),
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w);
      tp.paint(canvas, Offset((w - tp.width) / 2, h - 24));
    }
    // 8. Points badge
  }

  /// 4 shadow forms at the corners, pushed further back as progress grows
  void _drawShadows(Canvas canvas, double cx, double cy, double w, double h) {
    // Evil eyes that crack and shatter with progress
    final evilAlpha = (1.0 - progress * 1.1).clamp(0.0, 0.90);
    if (evilAlpha < 0.01 && !isComplete) return;

    final eyeY = cy - 15;
    final eyeSpacing = w * 0.20;
    final eyeW = w * 0.11 * (1.0 - progress * 0.3); // eyes shrink slightly
    final eyeH = eyeW * 0.45;

    // Subtle tremble as being destroyed
    final shake =
        progress > 0.3
            ? math.sin(driftPhase * math.pi * 8) * progress * 3
            : 0.0;

    for (int side = 0; side < 2; side++) {
      final ex = side == 0 ? cx - eyeSpacing + shake : cx + eyeSpacing + shake;
      final mirror = side == 0 ? 1.0 : -1.0;

      // Thick smoky aura behind each eye
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ex, eyeY),
          width: eyeW * 3.5,
          height: eyeH * 3.5,
        ),
        Paint()
          ..color = const Color(0xFF8B0000).withValues(alpha: evilAlpha * 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );

      // Eye shape — elegant, smooth almond
      final eyePath =
          Path()
            ..moveTo(ex - eyeW * 1.1, eyeY)
            ..quadraticBezierTo(ex, eyeY - eyeH * 1.3, ex + eyeW * 1.1, eyeY)
            ..quadraticBezierTo(ex, eyeY + eyeH * 1.3, ex - eyeW * 1.1, eyeY)
            ..close();

      // Deep blood-red sclera — evil eye ball
      canvas.drawPath(
        eyePath,
        Paint()..color = Color.fromRGBO(160, 10, 10, evilAlpha * 0.96),
      );

      // Outer rim - red eyelid
      canvas.drawPath(
        eyePath,
        Paint()
          ..color = Color.fromRGBO(180, 10, 10, evilAlpha * 1.0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );

      // Iris ring — dark red around black pupil
      canvas.drawCircle(
        Offset(ex, eyeY),
        eyeW * 0.38,
        Paint()..color = Color.fromRGBO(90, 5, 5, evilAlpha * 0.90),
      );

      // Black pupil core
      canvas.drawCircle(
        Offset(ex, eyeY),
        eyeW * 0.28,
        Paint()..color = Color.fromRGBO(0, 0, 0, evilAlpha * 1.0),
      );

      // White catch-light (top-right of pupil, like a real eye)
      canvas.drawCircle(
        Offset(ex + eyeW * 0.10, eyeY - eyeW * 0.12),
        eyeW * 0.07,
        Paint()..color = Colors.white.withValues(alpha: evilAlpha * 0.90),
      );

      // Tiny secondary glint (bottom-left, for depth)
      canvas.drawCircle(
        Offset(ex - eyeW * 0.08, eyeY + eyeW * 0.09),
        eyeW * 0.035,
        Paint()..color = Colors.white.withValues(alpha: evilAlpha * 0.40),
      );

      // ── Crack lines (appear as progress > 0.2, get more severe) ──
      if (progress > 0.2) {
        final crackIntensity = ((progress - 0.2) / 0.8).clamp(0.0, 1.0);
        final crackPaint =
            Paint()
              ..color = Color.fromRGBO(255, 200, 100, crackIntensity * 0.80)
              ..strokeWidth = 1.2 + crackIntensity * 1.0
              ..strokeCap = StrokeCap.round;

        // Crack from center outward — more cracks as progress grows
        final crackCount = (crackIntensity * 6).ceil().clamp(0, 6);
        final rng = math.Random(side * 7 + 42);
        for (int c = 0; c < crackCount; c++) {
          final startAngle = rng.nextDouble() * math.pi * 2;
          final startR = eyeW * 0.3;
          final endR = eyeW * (0.6 + rng.nextDouble() * 0.7);
          final sx = ex + eyeW * 0.1 + math.cos(startAngle) * startR;
          final sy = eyeY + math.sin(startAngle) * startR * 0.6;
          final endX = ex + eyeW * 0.1 + math.cos(startAngle) * endR;
          final endY = eyeY + math.sin(startAngle) * endR * 0.6;
          // Jagged midpoint
          final mx = (sx + endX) / 2 + (rng.nextDouble() - 0.5) * 6;
          final my = (sy + endY) / 2 + (rng.nextDouble() - 0.5) * 4;
          canvas.drawLine(Offset(sx, sy), Offset(mx, my), crackPaint);
          canvas.drawLine(Offset(mx, my), Offset(endX, endY), crackPaint);
        }
      }

      // ── Shattering fragments (progress > 0.6) ──
      if (progress > 0.6) {
        final shatterT = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
        final fragRng = math.Random(side * 13 + 99);
        for (int f = 0; f < 8; f++) {
          final angle = fragRng.nextDouble() * math.pi * 2;
          final dist = shatterT * (20 + fragRng.nextDouble() * 25);
          final fx = ex + math.cos(angle) * dist;
          final fy = eyeY + math.sin(angle) * dist * 0.6;
          final fragA = evilAlpha * (1.0 - shatterT) * 0.60;
          final fragSize = 2.0 + fragRng.nextDouble() * 3.0;
          if (fragA < 0.02) continue;

          // Dark red fragment
          canvas.drawCircle(
            Offset(fx, fy),
            fragSize * (1.0 - shatterT * 0.5),
            Paint()..color = Color.fromRGBO(150, 20, 20, fragA),
          );
          // Bright edge on fragment
          canvas.drawCircle(
            Offset(fx, fy),
            fragSize * 0.3 * (1.0 - shatterT),
            Paint()..color = Color.fromRGBO(255, 200, 100, fragA * 0.5),
          );
        }
      }
    }
  }

  /// Central divine light that grows as shadows retreat
  void _drawCentralLight(Canvas canvas, double cx, double cy, double w) {
    final lightR = 14 + progress * 35;
    final alpha = progress * (isComplete ? 0.55 : 0.35) * pulse;

    // Outer warm glow
    canvas.drawCircle(
      Offset(cx, cy),
      lightR + 20,
      Paint()
        ..color = Color.fromRGBO(255, 217, 125, alpha * 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // Mid glow
    canvas.drawCircle(
      Offset(cx, cy),
      lightR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(255, 255, 255, alpha * 0.90),
            Color.fromRGBO(212, 175, 55, alpha * 0.60),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: lightR)),
    );

    // Bright core
    canvas.drawCircle(
      Offset(cx, cy),
      5 * pulse,
      Paint()..color = Colors.white.withValues(alpha: alpha * 1.2),
    );

    // Light rays radiating outward on completion
    if (isComplete) {
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4 + driftPhase * math.pi * 0.08;
        final rayLen = lightR + 20 * pulse;
        final sx = cx + math.cos(angle) * 8;
        final sy = cy + math.sin(angle) * 8;
        final ex = cx + math.cos(angle) * rayLen;
        final ey = cy + math.sin(angle) * rayLen;
        canvas.drawLine(
          Offset(sx, sy),
          Offset(ex, ey),
          Paint()
            ..shader = LinearGradient(
              colors: [
                Color.fromRGBO(255, 217, 125, 0.25 * pulse),
                Colors.transparent,
              ],
            ).createShader(Rect.fromPoints(Offset(sx, sy), Offset(ex, ey)))
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RepellingLightPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.driftPhase != driftPhase;
}

// =============================================================================
// 👁️ Blinking Eyes — "Do not leave me to myself even for the blink of an eye"
// morning_25 / evening_25 — Ya Hayyu Ya Qayyum supplication
// =============================================================================
class _BlinkingEyes extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _BlinkingEyes({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_BlinkingEyes> createState() => _BlinkingEyesState();
}

class _BlinkingEyesState extends State<_BlinkingEyes>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _blinkCtrl, _shockCtrl;
  late Animation<double> _blinkAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Blink: mostly open, quick close every ~3.5 s
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
    // blinkAnim = 0 → eye OPEN, 1 → eye FULLY CLOSED
    // We stay near 0 for 85% of the cycle then spike to 1 and back
    _blinkAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 75), // open
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 8,
      ), // closing
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 4), // closed
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 13,
      ), // opening
    ]).animate(_blinkCtrl);

    _growCtrl.animateTo(widget.progress);
  }

  @override
  void didUpdateWidget(_BlinkingEyes old) {
    super.didUpdateWidget(old);
    _growCtrl.animateTo(widget.progress);
    if (widget.tapCount > old.tapCount) _shockCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _blinkCtrl.dispose();
    _shockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _blinkAnim,
        _shockCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 260,
            child: CustomPaint(
              size: const Size(double.infinity, 260),
              painter: _BlinkingEyesPainter(
                pulse: _pulseCtrl.value,
                grow: _growCtrl.value,
                blink: _blinkAnim.value,
                shock: _shockCtrl.value,
                complete: widget.isComplete,
              ),
            ),
          ),
    );
  }
}

class _BlinkingEyesPainter extends CustomPainter {
  final double pulse, grow, blink, shock;
  final bool complete;

  const _BlinkingEyesPainter({
    required this.pulse,
    required this.grow,
    required this.blink,
    required this.shock,
    required this.complete,
  });

  static const _quote =
      'Do not leave me to myself\neven for the blink of an eye';

  // Cute, round cartoon eye — simple, cheerful, clean.

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));

    // ── Soft background ───────────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFF8F0), Color(0xFFEFF6FF), Color(0xFFF5F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Floating 4-pointed sparkle stars
    final starPts = [
      Offset(w * 0.10, h * 0.09),
      Offset(w * 0.84, h * 0.08),
      Offset(w * 0.05, h * 0.60),
      Offset(w * 0.93, h * 0.58),
      Offset(w * 0.48, h * 0.05),
      Offset(w * 0.22, h * 0.76),
      Offset(w * 0.76, h * 0.75),
    ];
    for (int i = 0; i < starPts.length; i++) {
      final b = math.sin((pulse + i * 0.40) * math.pi) * 0.5 + 0.5;
      _drawStar(
        canvas,
        starPts[i],
        3.0 + b * 3.0,
        const Color(0xFFFFD700).withValues(alpha: 0.35 + b * 0.45),
      );
    }

    // ── Eye geometry ──────────────────────────────────────────────────────────
    final eyeCenter = Offset(cx, h * 0.37);
    // Gentle breathing scale with pulse
    final breathe = 1.0 + pulse * 0.025;
    final eyeR = h * 0.235 * breathe; // outer circle
    final irisR = eyeR * 0.62; // iris
    final pupilR = irisR * 0.47; // pupil

    // ── Soft outer glow ───────────────────────────────────────────────────────
    canvas.drawCircle(
      eyeCenter,
      eyeR + 12 + pulse * 5,
      Paint()
        ..color = const Color(
          0xFFBFDBFE,
        ).withValues(alpha: 0.14 + grow * 0.10 + pulse * 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // ── Sclera (white eye circle) ─────────────────────────────────────────────
    canvas.drawCircle(
      eyeCenter,
      eyeR,
      Paint()..color = const Color(0xFFFFFEF0),
    );

    // ── Iris ──────────────────────────────────────────────────────────────────
    canvas.drawCircle(
      eyeCenter,
      irisR,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0xFFFCD34D), // bright amber centre
            Color(0xFFD97706),
            Color(0xFF92400E), // deep outer ring
          ],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(Rect.fromCircle(center: eyeCenter, radius: irisR)),
    );

    // Gold rim grows with progress
    canvas.drawCircle(
      eyeCenter,
      irisR,
      Paint()
        ..color = const Color(
          0xFFFFD700,
        ).withValues(alpha: 0.15 + grow * 0.30 + pulse * 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Inner iris shimmer
    if (grow > 0.05) {
      canvas.drawCircle(
        eyeCenter,
        irisR * 0.82,
        Paint()
          ..color = const Color(
            0xFFFDE68A,
          ).withValues(alpha: grow * (0.18 + pulse * 0.10))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // ── Pupil ─────────────────────────────────────────────────────────────────
    canvas.drawCircle(
      eyeCenter,
      pupilR,
      Paint()..color = const Color(0xFF0D0D0D),
    );

    // ── Catchlights (big cartoony white ovals) ────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: eyeCenter.translate(-pupilR * 0.32, -pupilR * 0.42),
        width: pupilR * 1.05,
        height: pupilR * 1.35,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
    canvas.drawCircle(
      eyeCenter.translate(pupilR * 0.44, pupilR * 0.36),
      pupilR * 0.30,
      Paint()..color = Colors.white.withValues(alpha: 0.50),
    );

    // ── Eye outline (thick cartoony border) ───────────────────────────────────
    canvas.drawCircle(
      eyeCenter,
      eyeR,
      Paint()
        ..color = const Color(0xFF1A0D05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );

    // ── Blink: warm eyelid sweeps down from the top ───────────────────────────
    if (blink > 0.01) {
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: eyeCenter, radius: eyeR + 1)),
      );
      final lidBottom = eyeCenter.dy - eyeR + (eyeR * 2 + 5) * blink;
      // Skin-tone fill
      canvas.drawRect(
        Rect.fromLTRB(
          eyeCenter.dx - eyeR - 5,
          eyeCenter.dy - eyeR - 5,
          eyeCenter.dx + eyeR + 5,
          lidBottom,
        ),
        Paint()..color = const Color(0xFFFFD4A8),
      );
      // Lid edge (the lash line)
      canvas.drawLine(
        Offset(eyeCenter.dx - eyeR * 0.88, lidBottom),
        Offset(eyeCenter.dx + eyeR * 0.88, lidBottom),
        Paint()
          ..color = const Color(0xFF1A0D05)
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }

    // ── Cartoon upper eyelashes (5 bold curved strokes from top arc) ──────────
    final openFrac = (1.0 - blink).clamp(0.0, 1.0);
    if (openFrac > 0.12) {
      const lashCt = 5;
      for (int i = 0; i < lashCt; i++) {
        final t = i / (lashCt - 1);
        // Span top arc: from ~-150° to ~-30°
        final eyeAngle = -math.pi * 0.835 + t * math.pi * 0.670;
        final bx = eyeCenter.dx + eyeR * math.cos(eyeAngle);
        final by = eyeCenter.dy + eyeR * math.sin(eyeAngle);
        // Length: longer at edges, shorter in middle (cartoon look)
        final lLen = (14.0 + (0.5 - (t - 0.5).abs()) * -6.0) * openFrac;
        // Direction: radially outward with a slight left/right tilt
        final lashAngle = eyeAngle + (t - 0.5) * 0.45;
        canvas.drawLine(
          Offset(bx, by),
          Offset(
            bx + lLen * math.cos(lashAngle),
            by + lLen * math.sin(lashAngle),
          ),
          Paint()
            ..color = const Color(0xFF1A0D05).withValues(alpha: openFrac * 0.95)
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // ── Shockwave ─────────────────────────────────────────────────────────────
    if (shock > 0) {
      canvas.drawCircle(
        eyeCenter,
        eyeR + shock * 65,
        Paint()
          ..color = const Color(
            0xFF93C5FD,
          ).withValues(alpha: (1 - shock) * 0.40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // ── Completion: gold shimmer + side stars ─────────────────────────────────
    if (complete) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..color = const Color(
            0xFFFFD700,
          ).withValues(alpha: 0.05 + pulse * 0.04),
      );
      _drawStar(
        canvas,
        eyeCenter.translate(-eyeR * 1.55, -eyeR * 0.25),
        10 + pulse * 4,
        const Color(0xFFFFD700).withValues(alpha: 0.65 + pulse * 0.30),
      );
      _drawStar(
        canvas,
        eyeCenter.translate(eyeR * 1.55, -eyeR * 0.25),
        10 + pulse * 4,
        const Color(0xFFFFD700).withValues(alpha: 0.65 + pulse * 0.30),
      );
    }

    // ── Quote ─────────────────────────────────────────────────────────────────
    final qAlpha = (0.60 + grow * 0.40 + pulse * 0.04).clamp(0.0, 1.0);
    final tp = TextPainter(
      text: TextSpan(
        text: _quote,
        style: TextStyle(
          color: const Color(0xFF1E3A5F).withValues(alpha: qAlpha),
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          height: 1.55,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w * 0.80);
    tp.paint(canvas, Offset(cx - tp.width / 2, h * 0.77 - tp.height / 2));

    canvas.restore();
  }

  // 4-pointed cartoon star
  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    const pts = 4;
    for (int i = 0; i < pts * 2; i++) {
      final a = i * math.pi / pts - math.pi / 2;
      final r = i.isEven ? radius : radius * 0.38;
      final pt = Offset(
        center.dx + r * math.cos(a),
        center.dy + r * math.sin(a),
      );
      if (i == 0)
        path.moveTo(pt.dx, pt.dy);
      else
        path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BlinkingEyesPainter o) =>
      o.pulse != pulse ||
      o.grow != grow ||
      o.blink != blink ||
      o.shock != shock ||
      o.complete != complete;
}

// =============================================================================
class _CradledHeart extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _CradledHeart({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_CradledHeart> createState() => _CradledHeartState();
}

class _CradledHeartState extends State<_CradledHeart>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _growCtrl;
  late Animation<double> _grow;
  double _prevProgress = 0.0;
  late AnimationController _starCtrl;
  late AnimationController _pCtrl;
  late Animation<double> _pAnim;
  int _prevTap = 0;
  late AnimationController _punchCtrl;
  late Animation<double> _punch;
  late AnimationController _shockCtrl;
  late Animation<double> _shock;
  late AnimationController _floatCtrl;

  final List<_Particle> _particles = List.generate(
    16,
    (i) => _Particle(seed: i + 700),
  );

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_CradledHeart old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _floatCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _CradledHeartPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                floatPhase: _floatCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _CradledHeartPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double floatPhase;

  const _CradledHeartPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.floatPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.42;

    // 1. Background — deep warm purple (mercy/trust theme)
    _paintLightBg(canvas, w, h, progress: progress);

    // 2. Stars
    const starPos = [
      (0.10, 0.07),
      (0.22, 0.15),
      (0.37, 0.05),
      (0.53, 0.10),
      (0.67, 0.06),
      (0.82, 0.14),
      (0.92, 0.08),
      (0.44, 0.21),
      (0.61, 0.25),
      (0.28, 0.23),
      (0.76, 0.19),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      sp.color = Colors.white.withValues(alpha: 0.18 + 0.50 * tw);
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h),
        0.9 + tw * 1.0,
        sp,
      );
    }

    // Gentle float offset for the heart
    final floatY = math.sin(floatPhase * math.pi) * 4;

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, cy + floatY);
    // punch scale removed
    canvas.translate(-cx, -(cy + floatY));

    // 3. Cupping hands of light (appear from sides)
    _drawHands(canvas, cx, cy + floatY, w);

    // 4. Heart at center
    _drawHeart(canvas, cx, cy + floatY);

    // 5. Mercy glow surrounding
    _drawMercyGlow(canvas, cx, cy + floatY, w);

    canvas.restore();

    // 6. Shockwave on tap
    // tap-effect removed — smooth calm

    // 7. Particles — gentle upward sparkles
    // tap-effect removed — smooth calm

    // 8. Progress label
    // progress % label removed
    // 9. Points badge
  }

  /// Two cupping hands of light that close around the heart
  /// Two crescents of light that cup around the heart — abstract divine mercy
  void _drawHands(Canvas canvas, double cx, double cy, double w) {
    if (progress < 0.05) return;

    final alpha = progress * (isComplete ? 0.80 : 0.60);
    final color =
        isComplete ? const Color(0xFFD4AF37) : const Color(0xFFE879F9);

    // Shelter dome arcs — 3 concentric semicircles over the heart
    final baseR = w * 0.20;
    final shelterCy = cy + 10; // base of the dome sits below center

    for (int layer = 0; layer < 3; layer++) {
      final appear = ((progress - layer * 0.15) / 0.4).clamp(0.0, 1.0);
      if (appear <= 0) continue;

      final r = baseR + layer * (w * 0.06);
      final layerAlpha = alpha * (0.65 - layer * 0.12) * appear;
      final strokeW = (3.0 - layer * 0.6) * (isComplete ? 1.1 : 1.0);

      // Glow behind arc (cupping upwards)
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, shelterCy),
          width: r * 2,
          height: r * 1.8,
        ),
        0,
        math.pi * appear,
        false,
        Paint()
          ..color = color.withValues(alpha: layerAlpha * 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW + 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Main shelter arc — semicircle opening upward (U-shape cradle)
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, shelterCy),
          width: r * 2,
          height: r * 1.8,
        ),
        0,
        math.pi * appear,
        false,
        Paint()
          ..color = color.withValues(alpha: layerAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }

    // Ground line connecting the dome feet
    if (progress > 0.3) {
      final groundAlpha =
          ((progress - 0.3) / 0.7).clamp(0.0, 1.0) * alpha * 0.25;
      final groundW = baseR * 2 + (w * 0.12) * 2;
      canvas.drawLine(
        Offset(cx - groundW / 2, shelterCy),
        Offset(cx + groundW / 2, shelterCy),
        Paint()
          ..color = color.withValues(alpha: groundAlpha)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Heart shape at center that grows with progress
  void _drawHeart(Canvas canvas, double cx, double cy) {
    final heartScale = (0.4 + progress * 0.6) * (isComplete ? pulse : 1.0);
    final heartAlpha = (0.2 + progress * 0.6).clamp(0.0, 0.80);

    // Heart glow
    canvas.drawCircle(
      Offset(cx, cy),
      22 * heartScale,
      Paint()
        ..color =
            isComplete
                ? Color.fromRGBO(212, 175, 55, heartAlpha * 0.15)
                : Color.fromRGBO(232, 121, 249, heartAlpha * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Heart shape path
    canvas.save();
    canvas.translate(cx, cy - 2 * heartScale);

    final s = 12.0 * heartScale;
    final heartPath =
        Path()
          ..moveTo(0, s * 0.9)
          ..cubicTo(-s * 0.7, s * 0.4, -s * 1.3, -s * 0.2, -s * 0.7, -s * 0.7)
          ..cubicTo(-s * 0.3, -s * 1.0, 0, -s * 0.7, 0, -s * 0.3)
          ..cubicTo(0, -s * 0.7, s * 0.3, -s * 1.0, s * 0.7, -s * 0.7)
          ..cubicTo(s * 1.3, -s * 0.2, s * 0.7, s * 0.4, 0, s * 0.9)
          ..close();

    // Filled heart with gradient
    canvas.drawPath(
      heartPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.3),
          colors: [
            Colors.white.withValues(alpha: heartAlpha * 0.50),
            isComplete
                ? Color.fromRGBO(212, 175, 55, heartAlpha)
                : Color.fromRGBO(232, 121, 249, heartAlpha),
            isComplete
                ? Color.fromRGBO(180, 140, 30, heartAlpha * 0.6)
                : Color.fromRGBO(192, 80, 210, heartAlpha * 0.6),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: s * 1.2)),
    );

    // Heart outline (subtle)
    canvas.drawPath(
      heartPath,
      Paint()
        ..color = Colors.white.withValues(alpha: heartAlpha * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    canvas.restore();
  }

  /// Soft mercy aura around the whole scene
  void _drawMercyGlow(Canvas canvas, double cx, double cy, double w) {
    if (progress < 0.2) return;

    final auraProgress = ((progress - 0.2) / 0.8).clamp(0.0, 1.0);
    final auraR = 45 + auraProgress * 25;
    final auraAlpha = auraProgress * (isComplete ? 0.12 : 0.06) * pulse;

    // Soft circular aura
    canvas.drawCircle(
      Offset(cx, cy),
      auraR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            isComplete
                ? Color.fromRGBO(212, 175, 55, auraAlpha * 1.5)
                : Color.fromRGBO(232, 121, 249, auraAlpha * 1.2),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: auraR)),
    );

    // Orbiting mercy dots
    if (progress > 0.5) {
      final dotCount = ((progress - 0.5) / 0.5 * 5).ceil().clamp(0, 5);
      for (int i = 0; i < dotCount; i++) {
        final angle = floatPhase * math.pi * 2 + i * (math.pi * 2 / 5);
        final orbitR = auraR * 0.75;
        final dx = cx + math.cos(angle) * orbitR;
        final dy = cy + math.sin(angle) * orbitR * 0.5;
        final dotAlpha = isComplete ? 0.60 : 0.40;

        canvas.drawCircle(
          Offset(dx, dy),
          3.5,
          Paint()
            ..color = const Color(0xFFE879F9).withValues(alpha: dotAlpha * 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(dx, dy),
          2.0,
          Paint()..color = const Color(0xFFE879F9).withValues(alpha: dotAlpha),
        );
      }
    }

    // Completion: gentle light rays upward from heart
    if (isComplete) {
      for (int i = 0; i < 6; i++) {
        final angle = -math.pi / 2 + (i - 2.5) * 0.25;
        final rayLen = 35.0 * pulse;
        final sx = cx + math.cos(angle) * 15;
        final sy = cy + math.sin(angle) * 15;
        final ex = cx + math.cos(angle) * (15 + rayLen);
        final ey = cy + math.sin(angle) * (15 + rayLen);
        canvas.drawLine(
          Offset(sx, sy),
          Offset(ex, ey),
          Paint()
            ..shader = LinearGradient(
              colors: [
                Color.fromRGBO(232, 121, 249, 0.20 * pulse),
                Colors.transparent,
              ],
            ).createShader(Rect.fromPoints(Offset(sx, sy), Offset(ex, ey)))
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CradledHeartPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.floatPhase != floatPhase;
}

// =============================================================================
// 🏺 Overflowing Vessel (إناء الشكر) — Gratitude / blessings from Allah
// =============================================================================
class _OverflowingVessel extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _OverflowingVessel({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_OverflowingVessel> createState() => _OverflowingVesselState();
}

class _OverflowingVesselState extends State<_OverflowingVessel>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _growCtrl;
  late Animation<double> _grow;
  double _prevProgress = 0.0;
  late AnimationController _starCtrl;
  late AnimationController _pCtrl;
  late Animation<double> _pAnim;
  int _prevTap = 0;
  late AnimationController _punchCtrl;
  late Animation<double> _punch;
  late AnimationController _shockCtrl;
  late Animation<double> _shock;
  late AnimationController _flowCtrl;

  final List<_Particle> _particles = List.generate(
    18,
    (i) => _Particle(seed: i + 800),
  );

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _flowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void didUpdateWidget(_OverflowingVessel old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _flowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _flowCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _OverflowingVesselPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                flowPhase: _flowCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _OverflowingVesselPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double flowPhase;

  // Blessing orb colors (diverse ni'mah)
  static const _blessingColors = [
    Color(0xFFD4AF37), // gold
    Color(0xFFFFC83D), // emerald
    Color(0xFF38BDF8), // sky
    Color(0xFFFBBF24), // amber
    Color(0xFFA78BFA), // violet
    Color(0xFFF472B6), // pink
    Color(0xFFFFC83D), // teal
    Color(0xFFFF9F43), // orange
  ];

  const _OverflowingVesselPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.flowPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final vesselCy = h * 0.52;

    // 1. Background — deep earthy green-gold (gratitude/growth)
    _paintLightBg(canvas, w, h, progress: progress);

    // 2. Stars
    const starPos = [
      (0.10, 0.06),
      (0.23, 0.14),
      (0.38, 0.04),
      (0.54, 0.10),
      (0.68, 0.06),
      (0.83, 0.13),
      (0.92, 0.08),
      (0.45, 0.20),
      (0.62, 0.23),
      (0.28, 0.21),
      (0.76, 0.18),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      sp.color = Colors.white.withValues(alpha: 0.18 + 0.48 * tw);
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h),
        0.9 + tw * 1.0,
        sp,
      );
    }

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, vesselCy);
    // punch scale removed
    canvas.translate(-cx, -vesselCy);

    // 3. Vessel shape
    _drawVessel(canvas, cx, vesselCy, w);

    // 4. Blessing fill level inside vessel
    _drawFillLevel(canvas, cx, vesselCy, w);

    // 5. Overflowing orbs (blessings spilling out when near full)
    _drawOverflow(canvas, cx, vesselCy, w);

    // 6. Light beam from above (Allah's blessings descending)
    _drawDescendingLight(canvas, cx, vesselCy, w, h);

    canvas.restore();

    // 7. Shockwave
    // tap-effect removed — smooth calm

    // 8. Tap particles
    // tap-effect removed — smooth calm

    // 9. Progress label
    // progress % label removed
    // 10. Points badge
  }

  /// Ornate vessel / bowl shape
  void _drawVessel(Canvas canvas, double cx, double cy, double w) {
    final vesselW = 52.0;
    final vesselH = 38.0;
    final rimY = cy - vesselH * 0.35;
    final baseY = cy + vesselH * 0.65;

    final vesselColor =
        isComplete
            ? const Color(0xFFD4AF37).withValues(alpha: 0.75)
            : const Color(0xFF8B7355).withValues(alpha: 0.65);
    final rimColor =
        isComplete
            ? const Color(0xFFFFD97D).withValues(alpha: 0.80)
            : const Color(0xFFB8976A).withValues(alpha: 0.60);

    // Vessel body — curved trapezoid
    final vesselPath =
        Path()
          ..moveTo(cx - vesselW * 0.5, rimY)
          ..quadraticBezierTo(
            cx - vesselW * 0.55,
            cy + vesselH * 0.2,
            cx - vesselW * 0.25,
            baseY,
          )
          ..lineTo(cx + vesselW * 0.25, baseY)
          ..quadraticBezierTo(
            cx + vesselW * 0.55,
            cy + vesselH * 0.2,
            cx + vesselW * 0.5,
            rimY,
          )
          ..close();

    canvas.drawPath(vesselPath, Paint()..color = vesselColor);
    canvas.drawPath(
      vesselPath,
      Paint()
        ..color = rimColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Rim — wider ellipse at top
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, rimY), width: vesselW + 6, height: 8),
      Paint()..color = rimColor,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, rimY), width: vesselW + 6, height: 8),
      Paint()
        ..color = rimColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Base pedestal
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY + 2),
        width: vesselW * 0.45,
        height: 5,
      ),
      Paint()..color = vesselColor,
    );

    // Decorative band on vessel
    final bandY = cy + 4;
    canvas.drawLine(
      Offset(cx - vesselW * 0.40, bandY),
      Offset(cx + vesselW * 0.40, bandY),
      Paint()
        ..color = rimColor.withValues(alpha: 0.30)
        ..strokeWidth = 0.8,
    );
  }

  /// Fill level inside the vessel — rises with progress
  void _drawFillLevel(Canvas canvas, double cx, double cy, double w) {
    if (progress < 0.03) return;

    final vesselW = 52.0;
    final vesselH = 38.0;
    final rimY = cy - vesselH * 0.35;
    final baseY = cy + vesselH * 0.65;
    final fillHeight = (baseY - rimY) * progress;
    final fillTop = baseY - fillHeight;

    // Width at fill level (narrower at bottom, wider at top)
    final fillWidthFrac = 0.25 + (progress * 0.25);
    final fillHalfW = vesselW * fillWidthFrac;

    // Animated wave on surface
    final waveAmp = 2.0 * (isComplete ? pulse : 1.0);
    final wavePath = Path()..moveTo(cx - fillHalfW, fillTop);
    for (double x = -fillHalfW; x <= fillHalfW; x += 2) {
      final wy =
          fillTop +
          math.sin((x / fillHalfW) * math.pi * 2 + flowPhase * math.pi * 2) *
              waveAmp;
      wavePath.lineTo(cx + x, wy);
    }
    wavePath
      ..lineTo(cx + fillHalfW, baseY)
      ..lineTo(cx - fillHalfW, baseY)
      ..close();

    // Golden liquid fill
    final fillAlpha = (0.20 + progress * 0.40).clamp(0.0, 0.60);
    canvas.drawPath(
      wavePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(255, 217, 125, fillAlpha * 0.8),
            Color.fromRGBO(212, 175, 55, fillAlpha),
            Color.fromRGBO(180, 140, 30, fillAlpha * 0.7),
          ],
        ).createShader(
          Rect.fromLTWH(cx - fillHalfW, fillTop, fillHalfW * 2, fillHeight),
        ),
    );

    // Surface shimmer
    canvas.drawLine(
      Offset(cx - fillHalfW * 0.6, fillTop + waveAmp * 0.5),
      Offset(cx + fillHalfW * 0.3, fillTop - waveAmp * 0.3),
      Paint()
        ..color = Colors.white.withValues(alpha: fillAlpha * 0.30)
        ..strokeWidth = 0.8,
    );

    // Small blessing orbs floating in the liquid
    final orbCount = (progress * 5).ceil().clamp(0, 5);
    for (int i = 0; i < orbCount; i++) {
      final orbPhase = (flowPhase + i * 0.2) % 1.0;
      final ox =
          cx + math.sin(orbPhase * math.pi * 2 + i * 1.3) * fillHalfW * 0.5;
      final oy = fillTop + (baseY - fillTop) * (0.2 + i * 0.15);
      final oc = _blessingColors[i % _blessingColors.length];

      canvas.drawCircle(
        Offset(ox, oy),
        3.0,
        Paint()..color = oc.withValues(alpha: 0.30),
      );
      canvas.drawCircle(
        Offset(ox, oy),
        1.5,
        Paint()..color = oc.withValues(alpha: 0.55),
      );
    }
  }

  /// Blessing orbs overflowing from the vessel rim (when progress > 70%)
  void _drawOverflow(Canvas canvas, double cx, double cy, double w) {
    if (progress < 0.7) return;

    final overflowProg = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
    final vesselH = 38.0;
    final rimY = cy - vesselH * 0.35;

    // Orbs rising from the rim
    final orbCount = (overflowProg * 6).ceil().clamp(0, 6);
    for (int i = 0; i < orbCount; i++) {
      final t = ((flowPhase + i * 0.16) % 1.0);
      final spreadX = math.sin(t * math.pi * 2 + i * 1.1) * 30;
      final riseY = rimY - t * 40 * overflowProg;
      final orbAlpha = (1.0 - t) * overflowProg * 0.65;
      final orbR = 3.5 * (1.0 - t * 0.4) * (isComplete ? pulse : 1.0);
      final oc = _blessingColors[i % _blessingColors.length];

      // Glow
      canvas.drawCircle(
        Offset(cx + spreadX, riseY),
        orbR + 4,
        Paint()
          ..color = oc.withValues(alpha: orbAlpha * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      // Orb
      canvas.drawCircle(
        Offset(cx + spreadX, riseY),
        orbR,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: orbAlpha * 0.6),
              oc.withValues(alpha: orbAlpha),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(cx + spreadX, riseY), radius: orbR),
          ),
      );
    }
  }

  /// Soft descending light from above into the vessel
  void _drawDescendingLight(
    Canvas canvas,
    double cx,
    double cy,
    double w,
    double h,
  ) {
    if (progress < 0.1) return;

    final lightAlpha = progress * (isComplete ? 0.18 : 0.08) * pulse;
    final vesselH = 38.0;
    final rimY = cy - vesselH * 0.35;

    // Cone of light narrowing toward the vessel
    final beamPath =
        Path()
          ..moveTo(cx - 35, h * 0.05)
          ..lineTo(cx + 35, h * 0.05)
          ..lineTo(cx + 15, rimY)
          ..lineTo(cx - 15, rimY)
          ..close();

    canvas.drawPath(
      beamPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(255, 248, 220, lightAlpha * 0.6),
            Color.fromRGBO(212, 175, 55, lightAlpha),
            Color.fromRGBO(212, 175, 55, lightAlpha * 1.5),
          ],
        ).createShader(Rect.fromLTWH(cx - 35, h * 0.05, 70, rimY - h * 0.05)),
    );

    // Descending blessing dots within the beam
    if (progress > 0.3) {
      final dotCount = ((progress - 0.3) / 0.7 * 4).ceil().clamp(0, 4);
      for (int i = 0; i < dotCount; i++) {
        final t = (flowPhase + i * 0.25) % 1.0;
        final dy = h * 0.08 + t * (rimY - h * 0.08);
        final dx = cx + math.sin(t * math.pi * 4 + i) * (15 * (1 - t) + 5);
        final dotA = (0.5 - (t - 0.5).abs()) * 0.80;
        final dc = _blessingColors[(i * 2) % _blessingColors.length];

        canvas.drawCircle(
          Offset(dx, dy),
          2.5,
          Paint()..color = dc.withValues(alpha: dotA),
        );
        canvas.drawCircle(
          Offset(dx, dy),
          1.2,
          Paint()..color = Colors.white.withValues(alpha: dotA * 0.5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_OverflowingVesselPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.flowPhase != flowPhase;
}

// =============================================================================
// 🌅 Rising Dawn (فجر التوحيد) — Renewing Tawhid / Fitrah
// =============================================================================
class _RisingDawn extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _RisingDawn({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_RisingDawn> createState() => _RisingDawnState();
}

class _RisingDawnState extends State<_RisingDawn>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl,
      _growCtrl,
      _starCtrl,
      _pCtrl,
      _punchCtrl,
      _shockCtrl,
      _rayCtrl;
  late Animation<double> _pulse, _grow, _pAnim, _punch, _shock;
  double _prevProgress = 0.0;
  int _prevTap = 0;
  final List<_Particle> _particles = List.generate(
    16,
    (i) => _Particle(seed: i + 900),
  );

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _rayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
  }

  @override
  void didUpdateWidget(_RisingDawn old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _rayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _rayCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _RisingDawnPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                rayPhase: _rayCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _RisingDawnPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double rayPhase;

  const _RisingDawnPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.rayPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final horizonY = h * 0.62;

    // 1. Sky gradient — warm sunrise palette (golden-yellow top, amber-orange bottom)
    final dawn = progress;
    final skyTop =
        Color.lerp(const Color(0xFFFFF8E1), const Color(0xFFFFF3C4), dawn)!;
    final skyMid =
        Color.lerp(const Color(0xFFFFECB3), const Color(0xFFFFD54F), dawn)!;
    final skyBot =
        Color.lerp(const Color(0xFFFFCC80), const Color(0xFFFB8C00), dawn)!;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, skyMid, skyBot],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars — fade out as dawn brightens
    const starPos = [
      (0.08, 0.06),
      (0.20, 0.14),
      (0.35, 0.04),
      (0.52, 0.09),
      (0.68, 0.05),
      (0.83, 0.13),
      (0.92, 0.07),
      (0.44, 0.18),
      (0.62, 0.22),
      (0.27, 0.20),
      (0.76, 0.17),
      (0.15, 0.26),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      final starA = ((1.0 - progress * 0.85) * (0.25 + 0.55 * tw)).clamp(
        0.0,
        0.75,
      );
      if (starA < 0.02) continue;
      sp.color = Colors.white.withValues(alpha: starA);
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h),
        1.0 + tw * 1.0,
        sp,
      );
    }

    // 3. Horizon ground — dark silhouette landscape
    final groundPath =
        Path()
          ..moveTo(0, horizonY)
          ..quadraticBezierTo(w * 0.15, horizonY - 6, w * 0.25, horizonY)
          ..quadraticBezierTo(w * 0.35, horizonY + 4, w * 0.45, horizonY - 2)
          ..quadraticBezierTo(w * 0.55, horizonY - 8, w * 0.65, horizonY)
          ..quadraticBezierTo(w * 0.75, horizonY + 5, w * 0.85, horizonY - 3)
          ..quadraticBezierTo(w * 0.95, horizonY + 2, w, horizonY)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();

    canvas.drawPath(
      groundPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFFE6A050), const Color(0xFFF5B041), dawn)!,
            Color.lerp(const Color(0xFFD4813A), const Color(0xFFEB984E), dawn)!,
          ],
        ).createShader(Rect.fromLTWH(0, horizonY, w, h - horizonY)),
    );

    // Small mosque silhouette on horizon
    _drawMosqueSilhouette(canvas, cx, horizonY, dawn);

    // Trees on the hills
    _drawHillTrees(canvas, w, horizonY, dawn);

    // Apply punch scale around sun position
    canvas.save();
    final sunCy = horizonY - progress * horizonY * 0.45;
    canvas.translate(cx, sunCy);
    // punch scale removed
    canvas.translate(-cx, -sunCy);

    // 4. Sun rising from horizon
    _drawSun(canvas, cx, sunCy, horizonY, w);

    // 5. Sun rays
    _drawRays(canvas, cx, sunCy, w);

    canvas.restore();

    // 6. Horizon glow
    if (progress > 0.05) {
      final glowA = progress * (isComplete ? 0.30 : 0.15);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, horizonY),
          width: w * 0.9,
          height: 40 * progress,
        ),
        Paint()
          ..color = Color.fromRGBO(255, 180, 50, glowA)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
      );
    }

    // 7. Shockwave
    // tap-effect removed — smooth calm

    // 8. Particles — golden sparks rising
    // tap-effect removed — smooth calm

    // 9. Label
    // progress % label removed
    // 10. Points badge
  }

  /// Sun disc rising from the horizon
  void _drawSun(
    Canvas canvas,
    double cx,
    double sunCy,
    double horizonY,
    double w,
  ) {
    final sunR = 28 + progress * 12;
    final sunAlpha = (0.30 + progress * 0.60).clamp(0.0, 0.90);

    // Outer corona (wide warm glow)
    canvas.drawCircle(
      Offset(cx, sunCy),
      sunR + 28,
      Paint()
        ..color = Color.fromRGBO(255, 220, 100, sunAlpha * 0.12 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );

    // Mid corona
    canvas.drawCircle(
      Offset(cx, sunCy),
      sunR + 12,
      Paint()
        ..color = Color.fromRGBO(255, 200, 80, sunAlpha * 0.20 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Sun disc — mostly white/cream like reference image
    canvas.drawCircle(
      Offset(cx, sunCy),
      sunR * (isComplete ? pulse : 1.0),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(255, 255, 245, sunAlpha),
            Color.fromRGBO(255, 245, 210, sunAlpha),
            Color.fromRGBO(255, 220, 130, sunAlpha * 0.8),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, sunCy), radius: sunR),
        ),
    );

    // Bright white core
    canvas.drawCircle(
      Offset(cx, sunCy),
      sunR * 0.45,
      Paint()..color = Colors.white.withValues(alpha: sunAlpha * 0.80),
    );
  }

  /// Light rays radiating from the sun
  void _drawRays(Canvas canvas, double cx, double sunCy, double w) {
    if (progress < 0.15) return;

    final rayProgress = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
    final rayCount = 12;
    final baseLen = 30 + rayProgress * 40;

    for (int i = 0; i < rayCount; i++) {
      final angle = i * math.pi * 2 / rayCount + rayPhase * math.pi * 0.04;
      // Alternate long and short rays
      final rayLen =
          baseLen * (i.isEven ? 1.0 : 0.6) * (isComplete ? pulse : 1.0);
      final rayAlpha = rayProgress * (isComplete ? 0.28 : 0.14);

      final sx = cx + math.cos(angle) * 22;
      final sy = sunCy + math.sin(angle) * 22;
      final ex = cx + math.cos(angle) * (22 + rayLen);
      final ey = sunCy + math.sin(angle) * (22 + rayLen);

      canvas.drawLine(
        Offset(sx, sy),
        Offset(ex, ey),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Color.fromRGBO(255, 220, 100, rayAlpha),
              Colors.transparent,
            ],
          ).createShader(Rect.fromPoints(Offset(sx, sy), Offset(ex, ey)))
          ..strokeWidth = i.isEven ? 2.0 : 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Small mosque silhouette on the horizon
  void _drawMosqueSilhouette(
    Canvas canvas,
    double cx,
    double horizonY,
    double dawn,
  ) {
    final silColor = Color.lerp(
      const Color(0xFFCC7A30),
      const Color(0xFFE8A040),
      dawn,
    )!.withValues(alpha: 0.70);

    // Main dome
    final domeW = 24.0;
    final domeH = 16.0;
    final domeX = cx - 5;
    final domeBase = horizonY - 1;

    final domePath =
        Path()
          ..moveTo(domeX - domeW / 2, domeBase)
          ..quadraticBezierTo(
            domeX - domeW / 2,
            domeBase - domeH,
            domeX,
            domeBase - domeH - 4,
          )
          ..quadraticBezierTo(
            domeX + domeW / 2,
            domeBase - domeH,
            domeX + domeW / 2,
            domeBase,
          )
          ..close();
    canvas.drawPath(domePath, Paint()..color = silColor);

    // Left minaret
    final mLeftX = domeX - domeW / 2 - 5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(mLeftX - 2, domeBase - domeH - 8, 4, domeH + 8),
        const Radius.circular(1),
      ),
      Paint()..color = silColor,
    );
    // Minaret cap
    canvas.drawCircle(
      Offset(mLeftX, domeBase - domeH - 9),
      2.5,
      Paint()..color = silColor,
    );

    // Right minaret
    final mRightX = domeX + domeW / 2 + 5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(mRightX - 2, domeBase - domeH - 6, 4, domeH + 6),
        const Radius.circular(1),
      ),
      Paint()..color = silColor,
    );
    canvas.drawCircle(
      Offset(mRightX, domeBase - domeH - 7),
      2.5,
      Paint()..color = silColor,
    );

    // Crescent on top of dome
    final crescentY = domeBase - domeH - 6;
    canvas.drawCircle(
      Offset(domeX, crescentY),
      2.8,
      Paint()
        ..color =
            isComplete
                ? const Color(0xFFFFD97D).withValues(alpha: 0.60)
                : silColor,
    );
    canvas.drawCircle(
      Offset(domeX + 1.2, crescentY - 0.5),
      2.2,
      Paint()
        ..color = Color.fromRGBO(
          (6 + dawn * 15).round(),
          (10 + dawn * 20).round(),
          (4 + dawn * 10).round(),
          0.90,
        ),
    );
  }

  /// Brownish trees scattered on the hills
  void _drawHillTrees(Canvas canvas, double w, double horizonY, double dawn) {
    final treeColor =
        Color.lerp(const Color(0xFFA06830), const Color(0xFFBB8040), dawn)!;
    final leafColor =
        Color.lerp(const Color(0xFF8B6530), const Color(0xFFA07838), dawn)!;

    // Tree positions: (x fraction, height, trunk width)
    const trees = [
      (0.08, 22.0, 3.0),
      (0.18, 18.0, 2.5),
      (0.28, 25.0, 3.5),
      (0.72, 20.0, 3.0),
      (0.82, 26.0, 3.5),
      (0.92, 16.0, 2.5),
    ];

    for (final (xf, th, tw) in trees) {
      final tx = w * xf;
      final baseY = horizonY + 2;
      final trunkTop = baseY - th;

      // Trunk
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(tx - tw / 2, trunkTop, tw, th),
          const Radius.circular(1),
        ),
        Paint()..color = treeColor.withValues(alpha: 0.65),
      );

      // Canopy — small oval on top
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tx, trunkTop - 4),
          width: th * 0.7,
          height: th * 0.55,
        ),
        Paint()..color = leafColor.withValues(alpha: 0.60),
      );
    }
  }

  @override
  bool shouldRepaint(_RisingDawnPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.rayPhase != rayPhase;
}

// =============================================================================
// ✨ Praise Ripples (موجات الحمد) — Morning praise & shahada
// =============================================================================
class _PraiseRipples extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _PraiseRipples({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_PraiseRipples> createState() => _PraiseRipplesState();
}

class _PraiseRipplesState extends State<_PraiseRipples>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl,
      _growCtrl,
      _starCtrl,
      _pCtrl,
      _punchCtrl,
      _shockCtrl,
      _rippleCtrl;
  late Animation<double> _pulse, _grow, _pAnim, _punch, _shock;
  double _prevProgress = 0.0;
  int _prevTap = 0;
  final List<_Particle> _particles = List.generate(
    16,
    (i) => _Particle(seed: i + 1000),
  );

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void didUpdateWidget(_PraiseRipples old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _rippleCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _PraiseRipplesPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                ripplePhase: _rippleCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _PraiseRipplesPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double ripplePhase;

  const _PraiseRipplesPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.ripplePhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.42;

    // 1. Background — deep navy blue (serene praise)
    _paintLightBg(canvas, w, h, progress: progress);

    // 2. Stars
    const starPos = [
      (0.09, 0.07),
      (0.22, 0.15),
      (0.37, 0.05),
      (0.54, 0.11),
      (0.68, 0.06),
      (0.83, 0.14),
      (0.92, 0.08),
      (0.45, 0.21),
      (0.62, 0.25),
      (0.28, 0.23),
      (0.76, 0.19),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      sp.color = Colors.white.withValues(alpha: 0.20 + 0.50 * tw);
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h),
        0.9 + tw * 1.0,
        sp,
      );
    }

    // Apply punch
    canvas.save();
    // punch scale removed — smooth calm tap

    // 3. Expanding praise ripple rings (continuous)
    _drawPraiseRipples(canvas, cx, cy, w);

    // 4. Central crescent and star
    _drawCrescentStar(canvas, cx, cy);

    canvas.restore();

    // 5. Shockwave
    // tap-effect removed — smooth calm

    // 6. Particles
    // tap-effect removed — smooth calm

    // 7. Label
    // progress % label removed
  }

  /// Concentric ripple rings expanding outward — representing hamd radiating
  void _drawPraiseRipples(Canvas canvas, double cx, double cy, double w) {
    // Number of visible rings grows with progress (up to 5)
    final ringCount = (progress * 5).ceil().clamp(0, 5);
    final maxR = w * 0.38;

    for (int i = 0; i < ringCount; i++) {
      // Each ring continuously expands from center outward
      final ringPhase = (ripplePhase + i * 0.20) % 1.0;
      final ringR = maxR * ringPhase;
      final ringFade = 1.0 - ringPhase; // fades as it expands

      // Ring alpha also based on how "established" this ring slot is
      final slotProgress = ((progress - i / 5.0) * 5.0).clamp(0.0, 1.0);
      final alpha = ringFade * slotProgress * (isComplete ? 0.55 : 0.38);

      if (alpha < 0.02) continue;

      // Alternate gold and sky-blue rings
      final ringColor =
          i.isEven
              ? Color.fromRGBO(212, 175, 55, alpha)
              : Color.fromRGBO(56, 189, 248, alpha * 0.7);

      canvas.drawCircle(
        Offset(cx, cy),
        ringR,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = (2.5 * ringFade).clamp(0.5, 2.5),
      );

      // Dotted accents on each ring (4 dots evenly spaced)
      if (ringPhase > 0.2 && ringPhase < 0.8) {
        for (int d = 0; d < 4; d++) {
          final dotAngle = d * math.pi / 2 + i * 0.4;
          final dx = cx + math.cos(dotAngle) * ringR;
          final dy = cy + math.sin(dotAngle) * ringR;
          canvas.drawCircle(
            Offset(dx, dy),
            1.8 * ringFade,
            Paint()
              ..color = ringColor.withValues(
                alpha: (alpha * 1.5).clamp(0.0, 0.50),
              ),
          );
        }
      }
    }
  }

  /// Central crescent and star — Islamic symbol of faith
  void _drawCrescentStar(Canvas canvas, double cx, double cy) {
    final scale = (0.5 + progress * 0.5) * (isComplete ? pulse : 1.0);
    final alpha = (0.25 + progress * 0.55).clamp(0.0, 0.80);

    final color =
        isComplete
            ? Color.fromRGBO(212, 175, 55, alpha)
            : Color.fromRGBO(255, 255, 255, alpha);

    // Central glow
    canvas.drawCircle(
      Offset(cx, cy),
      28 * scale,
      Paint()
        ..color = (isComplete
                ? const Color(0xFFD4AF37)
                : const Color(0xFF38BDF8))
            .withValues(alpha: alpha * 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Crescent moon
    final moonR = 16.0 * scale;
    canvas.drawCircle(Offset(cx - 2, cy), moonR, Paint()..color = color);
    // Cutout to form crescent
    canvas.drawCircle(
      Offset(cx + moonR * 0.45, cy - moonR * 0.1),
      moonR * 0.82,
      Paint()
        ..color = const Color(
          0xFF0C1A30,
        ).withValues(alpha: alpha > 0.5 ? 0.92 : 0.85),
    );

    // Five-pointed star next to crescent
    final starCx = cx + 14 * scale;
    final starCy = cy - 8 * scale;
    final starR = 5.0 * scale;

    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      // Outer point
      final outerAngle = -math.pi / 2 + i * (math.pi * 2 / 5);
      final ox = starCx + math.cos(outerAngle) * starR;
      final oy = starCy + math.sin(outerAngle) * starR;
      // Inner point
      final innerAngle = outerAngle + math.pi / 5;
      final ix = starCx + math.cos(innerAngle) * starR * 0.4;
      final iy = starCy + math.sin(innerAngle) * starR * 0.4;

      if (i == 0) {
        starPath.moveTo(ox, oy);
      } else {
        starPath.lineTo(ox, oy);
      }
      starPath.lineTo(ix, iy);
    }
    starPath.close();

    canvas.drawPath(starPath, Paint()..color = color);

    // Small glow around star
    canvas.drawCircle(
      Offset(starCx, starCy),
      starR + 3,
      Paint()
        ..color = color.withValues(alpha: alpha * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(_PraiseRipplesPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.ripplePhase != ripplePhase;
}

// =============================================================================
// ✨ Five Blessings (خمس بركات) — Ask Allah to bless your day
// Dua asks for: فتح (victory), نصر (help), نور (light), بركة (barakah), هدى (guidance)
// =============================================================================
// =============================================================================
// 🌅 Blessed Day Scenery — mountains, trees, birds, home, golden sky
// morning_30: Allahumma inni as'aluka khayr hadha-l-yawm
// =============================================================================
class _FiveBlessings extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _FiveBlessings({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_FiveBlessings> createState() => _FiveBlessingsState();
}

class _FiveBlessingsState extends State<_FiveBlessings>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl,
      _growCtrl,
      _starCtrl,
      _birdCtrl,
      _glowCtrl;
  late Animation<double> _pulse, _grow;
  double _prevProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _birdCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_FiveBlessings old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _birdCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _birdCtrl,
        _glowCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 260,
            child: CustomPaint(
              painter: _FiveBlessingsPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                birdPhase: _birdCtrl.value,
                glowPhase: _glowCtrl.value,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
              ),
            ),
          ),
    );
  }
}

class _FiveBlessingsPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double birdPhase;
  final double glowPhase;
  final bool isComplete;
  final int pointsToday;

  const _FiveBlessingsPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.birdPhase,
    required this.glowPhase,
    required this.isComplete,
    this.pointsToday = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // ── Sky gradient — warm sunrise to clear blue ──
    final skyTop =
        Color.lerp(const Color(0xFFFFD580), const Color(0xFF87CEEB), progress)!;
    final skyMid =
        Color.lerp(const Color(0xFFFF9F43), const Color(0xFF4FC3F7), progress)!;
    final skyBot =
        Color.lerp(const Color(0xFFFF7846), const Color(0xFF81D4FA), progress)!;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, skyMid, skyBot],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // ── Sun / soft glow ──
    final sunX = w * 0.72;
    final sunY = h * (0.22 - progress * 0.08);
    final sunR = 28.0 + pulse * 4;
    final sunAlpha = 0.3 + progress * 0.5;
    // outer halo
    canvas.drawCircle(
      Offset(sunX, sunY),
      sunR + 18,
      Paint()
        ..color = const Color(
          0xFFFFD580,
        ).withValues(alpha: sunAlpha * 0.35 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(
      Offset(sunX, sunY),
      sunR + 8,
      Paint()
        ..color = const Color(0xFFFFA726).withValues(alpha: sunAlpha * 0.55),
    );
    canvas.drawCircle(
      Offset(sunX, sunY),
      sunR,
      Paint()..color = const Color(0xFFFFE066).withValues(alpha: sunAlpha),
    );

    // ── Distant mountains (back layer) ──
    final mtn1 =
        Paint()
          ..color = Color.lerp(
            const Color(0xFFB0C4DE),
            const Color(0xFF7986CB),
            progress,
          )!.withValues(alpha: 0.60 + progress * 0.20);
    _drawMountain(canvas, Offset(w * 0.05, h * 0.62), w * 0.38, h * 0.28, mtn1);
    _drawMountain(canvas, Offset(w * 0.35, h * 0.60), w * 0.32, h * 0.32, mtn1);
    _drawMountain(canvas, Offset(w * 0.62, h * 0.61), w * 0.42, h * 0.26, mtn1);

    // Mountain snow caps
    if (progress > 0.2) {
      final snowA = ((progress - 0.2) / 0.8).clamp(0.0, 0.9);
      final snowPaint =
          Paint()..color = Colors.white.withValues(alpha: snowA * 0.75);
      _drawMountainCap(canvas, Offset(w * 0.24, h * 0.34), w * 0.12, snowPaint);
      _drawMountainCap(canvas, Offset(w * 0.51, h * 0.28), w * 0.10, snowPaint);
    }

    // ── Green valley / ground ──
    final groundColor =
        Color.lerp(const Color(0xFF8D9A5E), const Color(0xFF4CAF50), progress)!;
    final groundPath =
        Path()
          ..moveTo(0, h * 0.70)
          ..quadraticBezierTo(w * 0.25, h * 0.66, w * 0.5, h * 0.68)
          ..quadraticBezierTo(w * 0.75, h * 0.70, w, h * 0.67)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();
    canvas.drawPath(groundPath, Paint()..color = groundColor);

    // ── Pine trees — appear progressively ──
    final treeCount = (progress * 5).ceil().clamp(0, 5);
    final treePositions = [
      (w * 0.08, h * 0.73, 0.85),
      (w * 0.20, h * 0.70, 1.0),
      (w * 0.78, h * 0.72, 0.90),
      (w * 0.87, h * 0.70, 1.05),
      (w * 0.50, h * 0.71, 0.75),
    ];
    final treeColor =
        Color.lerp(const Color(0xFF2E7D32), const Color(0xFF1B5E20), 0.5)!;
    for (int i = 0; i < treeCount; i++) {
      final (tx, ty, tScale) = treePositions[i];
      final tAlpha = ((progress * 5 - i)).clamp(0.0, 1.0);
      _drawPineTree(
        canvas,
        Offset(tx, ty),
        h * 0.22 * tScale,
        treeColor.withValues(alpha: tAlpha),
      );
    }

    // ── Cozy home — appears after 40% ──
    if (progress > 0.35) {
      final homeAlpha = ((progress - 0.35) / 0.65).clamp(0.0, 1.0);
      _drawHome(
        canvas,
        Offset(w * 0.42, h * 0.73),
        w * 0.18,
        homeAlpha,
        isComplete,
      );
    }

    // ── Path / road leading to the home ──
    if (progress > 0.45) {
      final pathAlpha = ((progress - 0.45) / 0.55).clamp(0.0, 0.60);
      final roadPaint =
          Paint()
            ..color = const Color(0xFFD4A96A).withValues(alpha: pathAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round;
      final road =
          Path()
            ..moveTo(w * 0.5, h)
            ..quadraticBezierTo(w * 0.5, h * 0.85, w * 0.5, h * 0.75);
      canvas.drawPath(road, roadPaint);
    }

    // ── Birds flying — wispy V shapes ──
    if (progress > 0.25) {
      final birdAlpha = ((progress - 0.25) / 0.75).clamp(0.0, 0.85);
      _drawFlyingBirds(canvas, w, h, birdPhase, birdAlpha, isComplete);
    }

    // ── Completion rays from sun ──
    if (isComplete) {
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        final rayLen = (20 + glowPhase * 14) * pulse;
        canvas.drawLine(
          Offset(
            sunX + math.cos(angle) * (sunR + 4),
            sunY + math.sin(angle) * (sunR + 4),
          ),
          Offset(
            sunX + math.cos(angle) * (sunR + rayLen),
            sunY + math.sin(angle) * rayLen,
          ),
          Paint()
            ..color = const Color(
              0xFFFFD700,
            ).withValues(alpha: 0.55 * glowPhase)
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
      }
      // Soft golden ground shimmer
      canvas.drawRect(
        Rect.fromLTWH(0, h * 0.66, w, h * 0.34),
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.08 * glowPhase)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  void _drawMountain(
    Canvas canvas,
    Offset tip,
    double width,
    double mtnH,
    Paint paint,
  ) {
    final path =
        Path()
          ..moveTo(tip.dx - width / 2, tip.dy + mtnH)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(tip.dx + width / 2, tip.dy + mtnH)
          ..close();
    canvas.drawPath(path, paint);
  }

  void _drawMountainCap(Canvas canvas, Offset tip, double capW, Paint paint) {
    final path =
        Path()
          ..moveTo(tip.dx - capW / 2, tip.dy + capW * 0.5)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(tip.dx + capW / 2, tip.dy + capW * 0.5)
          ..close();
    canvas.drawPath(path, paint);
  }

  void _drawPineTree(Canvas canvas, Offset base, double height, Color color) {
    final trunk = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(base.dx, base.dy - height * 0.08),
          width: height * 0.10,
          height: height * 0.18,
        ),
        const Radius.circular(2),
      ),
      trunk,
    );
    // Three tiers of pine foliage
    final tiers = [
      (0.0, 1.0, 0.55), // bottom tier
      (0.28, 0.80, 0.45), // middle tier
      (0.54, 0.55, 0.32), // top tier
    ];
    for (final (yFrac, widthFrac, heightFrac) in tiers) {
      final ty = base.dy - height * yFrac;
      final tw = height * widthFrac;
      final th = height * heightFrac;
      final path =
          Path()
            ..moveTo(base.dx - tw / 2, ty)
            ..lineTo(base.dx, ty - th)
            ..lineTo(base.dx + tw / 2, ty)
            ..close();
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  void _drawHome(
    Canvas canvas,
    Offset pos,
    double size,
    double alpha,
    bool complete,
  ) {
    // Wall
    final wallColor =
        Color.lerp(
          const Color(0xFFF5E6C8),
          complete ? const Color(0xFFFFF9E3) : const Color(0xFFF5E6C8),
          alpha,
        )!;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(pos.dx, pos.dy - size * 0.30),
        width: size,
        height: size * 0.60,
      ),
      Paint()..color = wallColor.withValues(alpha: alpha),
    );
    // Roof
    final roofPath =
        Path()
          ..moveTo(pos.dx - size * 0.60, pos.dy - size * 0.57)
          ..lineTo(pos.dx, pos.dy - size)
          ..lineTo(pos.dx + size * 0.60, pos.dy - size * 0.57)
          ..close();
    canvas.drawPath(
      roofPath,
      Paint()..color = const Color(0xFFB35C2E).withValues(alpha: alpha),
    );
    // Door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          pos.dx - size * 0.10,
          pos.dy - size * 0.38,
          size * 0.20,
          size * 0.38,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF6D4C41).withValues(alpha: alpha),
    );
    // Window
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(pos.dx - size * 0.27, pos.dy - size * 0.40),
        width: size * 0.18,
        height: size * 0.16,
      ),
      Paint()
        ..color =
            complete
                ? const Color(0xFFFFE57F).withValues(alpha: alpha * 0.9)
                : const Color(0xFF90CAF9).withValues(alpha: alpha * 0.8),
    );
    // Chimney smoke (gentle)
    final smokeX = pos.dx + size * 0.30;
    final smokeY = pos.dy - size * 0.92;
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(smokeX + math.sin(i * 0.9) * 3, smokeY - i * 8.0),
        4.0 + i * 2.5,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha * (0.25 - i * 0.07)),
      );
    }
  }

  void _drawFlyingBirds(
    Canvas canvas,
    double w,
    double h,
    double phase,
    double alpha,
    bool complete,
  ) {
    // Birds drift across the sky in a loose flock
    final birdPaint =
        Paint()
          ..color = const Color(0xFF37474F).withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;

    final birdPositions = [
      (0.15, 0.18, 0.90, 1.0), // x_frac, y_frac, x_speed, size
      (0.30, 0.14, 1.0, 0.85),
      (0.40, 0.20, 0.95, 0.75),
      (0.18, 0.22, 0.88, 0.70),
      (0.08, 0.16, 1.05, 0.80),
    ];
    for (final (xBase, yBase, speed, sz) in birdPositions) {
      final bx = ((xBase + phase * speed) % 1.1) * w - w * 0.05;
      final by =
          h * yBase + math.sin(phase * math.pi * 2 * speed + xBase * 5) * 5;
      _drawBirdV(canvas, Offset(bx, by), sz * 8, birdPaint);
    }
  }

  void _drawBirdV(Canvas canvas, Offset center, double span, Paint paint) {
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx - span / 2, center.dy),
        width: span,
        height: span * 0.4,
      ),
      math.pi,
      math.pi,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx + span / 2, center.dy),
        width: span,
        height: span * 0.4,
      ),
      math.pi,
      math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_FiveBlessingsPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.birdPhase != birdPhase ||
      o.glowPhase != glowPhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday;
}

// =============================================================================
// 🛤️ Glowing Path (طريق النور) — Ask Allah for a good day
// =============================================================================
class _GlowingPath extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _GlowingPath({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_GlowingPath> createState() => _GlowingPathState();
}

class _GlowingPathState extends State<_GlowingPath>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl,
      _growCtrl,
      _starCtrl,
      _pCtrl,
      _punchCtrl,
      _shockCtrl,
      _walkCtrl;
  late Animation<double> _pulse, _grow, _pAnim, _punch, _shock;
  double _prevProgress = 0.0;
  int _prevTap = 0;
  final List<_Particle> _particles = List.generate(
    16,
    (i) => _Particle(seed: i + 1100),
  );

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _walkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
  }

  @override
  void didUpdateWidget(_GlowingPath old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _walkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _walkCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _GlowingPathPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                walkPhase: _walkCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _GlowingPathPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double walkPhase;

  const _GlowingPathPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.walkPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 1. Background — dark to warm gradient (journey forward)
    final warmth = progress * 0.25;
    _paintLightBg(canvas, w, h, progress: progress);

    // 2. Stars
    const starPos = [
      (0.09, 0.06),
      (0.22, 0.14),
      (0.37, 0.04),
      (0.54, 0.10),
      (0.68, 0.06),
      (0.83, 0.13),
      (0.92, 0.07),
      (0.45, 0.19),
      (0.62, 0.23),
      (0.28, 0.21),
      (0.76, 0.17),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      sp.color = Colors.white.withValues(alpha: 0.18 + 0.45 * tw);
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h),
        0.9 + tw * 1.0,
        sp,
      );
    }

    // Apply punch
    canvas.save();
    final pathCy = h * 0.50;
    canvas.translate(cx, pathCy);
    // punch scale removed
    canvas.translate(-cx, -pathCy);

    // 3. Perspective path receding into distance
    _drawPath(canvas, cx, w, h);

    // 4. Destination light at vanishing point
    _drawDestinationLight(canvas, cx, h);

    // 5. Milestone markers along the path
    _drawMilestones(canvas, cx, w, h);

    // 6. Walking figure
    _drawWalker(canvas, cx, w, h);

    canvas.restore();

    // 7. Shockwave
    // tap-effect removed — smooth calm

    // 8. Particles — trail sparkles
    // tap-effect removed — smooth calm

    // 9. Label
    // progress % label removed
  }

  /// Perspective path with edges converging toward vanishing point
  void _drawPath(Canvas canvas, double cx, double w, double h) {
    final vanishY = h * 0.22;
    final baseY = h * 0.78;
    final pathLit = progress; // how much of the path is illuminated

    // Path edges (converging lines)
    final baseHalfW = w * 0.30;
    final topHalfW = w * 0.03;

    // Left edge
    final leftPath =
        Path()
          ..moveTo(cx - baseHalfW, baseY)
          ..lineTo(cx - topHalfW, vanishY);
    // Right edge
    final rightPath =
        Path()
          ..moveTo(cx + baseHalfW, baseY)
          ..lineTo(cx + topHalfW, vanishY);

    final edgeAlpha = 0.15 + progress * 0.20;
    final edgePaint =
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: edgeAlpha)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
    canvas.drawPath(leftPath, edgePaint);
    canvas.drawPath(rightPath, edgePaint);

    // Illuminated path surface (fills from bottom toward vanishing point)
    final litY = baseY - (baseY - vanishY) * pathLit;
    final litHalfW = baseHalfW - (baseHalfW - topHalfW) * pathLit;

    final surfacePath =
        Path()
          ..moveTo(cx - baseHalfW, baseY)
          ..lineTo(cx - litHalfW, litY)
          ..lineTo(cx + litHalfW, litY)
          ..lineTo(cx + baseHalfW, baseY)
          ..close();

    final surfaceAlpha = (0.04 + progress * 0.10).clamp(0.0, 0.14);
    canvas.drawPath(
      surfacePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color.fromRGBO(212, 175, 55, surfaceAlpha),
            Color.fromRGBO(52, 211, 153, surfaceAlpha * 0.6),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromLTWH(
            cx - baseHalfW,
            vanishY,
            baseHalfW * 2,
            baseY - vanishY,
          ),
        ),
    );

    // Center dashed line
    final dashCount = (progress * 8).ceil().clamp(0, 8);
    for (int i = 0; i < dashCount; i++) {
      final t = i / 8.0;
      final dy = baseY - (baseY - vanishY) * t;
      final nextT = (i + 0.4) / 8.0;
      final nextDy = baseY - (baseY - vanishY) * nextT;
      final dashAlpha = (1.0 - t) * (0.15 + progress * 0.20);

      canvas.drawLine(
        Offset(cx, dy),
        Offset(cx, nextDy),
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, dashAlpha)
          ..strokeWidth = 1.5 * (1.0 - t * 0.6)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Bright light at the vanishing point — the goodness of the day
  void _drawDestinationLight(Canvas canvas, double cx, double h) {
    if (progress < 0.1) return;

    final vanishY = h * 0.22;
    final lightAlpha =
        ((progress - 0.1) / 0.9) * (isComplete ? 0.60 : 0.38) * pulse;
    final lightR = 15 + progress * 20;

    // Outer glow
    canvas.drawCircle(
      Offset(cx, vanishY),
      lightR + 20,
      Paint()
        ..color = Color.fromRGBO(212, 175, 55, lightAlpha * 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // Mid glow
    canvas.drawCircle(
      Offset(cx, vanishY),
      lightR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(255, 255, 240, lightAlpha * 1.2),
            Color.fromRGBO(212, 175, 55, lightAlpha * 0.8),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, vanishY), radius: lightR),
        ),
    );

    // Core
    canvas.drawCircle(
      Offset(cx, vanishY),
      4 * pulse,
      Paint()..color = Colors.white.withValues(alpha: lightAlpha * 1.5),
    );

    // Upward rays on completion
    if (isComplete) {
      for (int i = 0; i < 5; i++) {
        final angle = -math.pi / 2 + (i - 2) * 0.25;
        final rayLen = 30.0 * pulse;
        final sx = cx + math.cos(angle) * 10;
        final sy = vanishY + math.sin(angle) * 10;
        final ex = cx + math.cos(angle) * (10 + rayLen);
        final ey = vanishY + math.sin(angle) * (10 + rayLen);
        canvas.drawLine(
          Offset(sx, sy),
          Offset(ex, ey),
          Paint()
            ..shader = LinearGradient(
              colors: [
                Color.fromRGBO(255, 220, 100, 0.25 * pulse),
                Colors.transparent,
              ],
            ).createShader(Rect.fromPoints(Offset(sx, sy), Offset(ex, ey)))
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  /// Small glowing milestone dots along the path
  void _drawMilestones(Canvas canvas, double cx, double w, double h) {
    final vanishY = h * 0.22;
    final baseY = h * 0.78;
    // 5 milestones: victory, help, light, barakah, guidance
    const milestoneColors = [
      Color(0xFFD4AF37), // victory (fath)
      Color(0xFFFFC83D), // help (nasr)
      Color(0xFF38BDF8), // light (noor)
      Color(0xFFFBBF24), // barakah
      Color(0xFFA78BFA), // guidance (huda)
    ];

    for (int i = 0; i < 5; i++) {
      final threshold = (i + 1) * 0.20;
      if (progress < threshold - 0.15) continue;

      final mProgress = ((progress - (threshold - 0.15)) / 0.15).clamp(
        0.0,
        1.0,
      );
      final t = (i + 1) / 6.0; // position along path (0=bottom, 1=vanish)
      final my = baseY - (baseY - vanishY) * t;
      // Alternate left and right of center line
      final side = i.isEven ? -1.0 : 1.0;
      final pathHalfW = (w * 0.30) - ((w * 0.30) - (w * 0.03)) * t;
      final mx = cx + side * pathHalfW * 0.5;
      final mColor = milestoneColors[i];
      final mR = 4.0 * mProgress * (isComplete ? pulse : 1.0);

      // Glow
      canvas.drawCircle(
        Offset(mx, my),
        mR + 5,
        Paint()
          ..color = mColor.withValues(alpha: mProgress * 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      // Dot
      canvas.drawCircle(
        Offset(mx, my),
        mR,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: mProgress * 0.50),
              mColor.withValues(alpha: mProgress * 0.70),
            ],
          ).createShader(Rect.fromCircle(center: Offset(mx, my), radius: mR)),
      );
    }
  }

  /// Luminous traveler silhouette walking along the path
  void _drawWalker(Canvas canvas, double cx, double w, double h) {
    final vanishY = h * 0.22;
    final baseY = h * 0.78;

    // Walker position along the path follows progress
    final walkerT = progress * 0.65; // doesn't reach vanishing point
    final walkerY = baseY - (baseY - vanishY) * walkerT;
    final perspScale = 1.0 - walkerT * 0.6; // shrink with perspective

    final walkerAlpha = (0.45 + progress * 0.40).clamp(0.0, 0.85);
    final baseColor =
        isComplete ? const Color(0xFFD4AF37) : const Color(0xFFCDD5E0);
    final glowColor =
        isComplete ? const Color(0xFFD4AF37) : const Color(0xFF38BDF8);

    // Subtle bob — smooth gentle rise/fall
    final bob = math.sin(walkPhase * math.pi * 2) * 1.0 * perspScale;
    // Slight body sway for natural motion
    final sway = math.sin(walkPhase * math.pi * 2) * 0.8 * perspScale;

    final s = perspScale; // shorthand

    // -- Outer aura glow around entire figure --
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, walkerY - 4 * s + bob),
        width: 36 * s,
        height: 52 * s,
      ),
      Paint()
        ..color = glowColor.withValues(alpha: walkerAlpha * 0.10)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 * s),
    );

    // -- Body silhouette: a tapered oval shape (like a person in a flowing garment) --
    final bodyPath = Path();
    final topY = walkerY - 24 * s + bob; // top of head area
    final shoulderY = walkerY - 10 * s + bob; // shoulder level
    final waistY = walkerY + 4 * s + bob; // waist
    final bottomY = walkerY + 20 * s + bob; // bottom of garment

    // Draw a smooth silhouette shape — narrow at top (head), wider at shoulders,
    // tapers at waist, flows out slightly at bottom like a robe
    bodyPath.moveTo(cx + sway, topY); // top center
    // Right side
    bodyPath.cubicTo(
      cx + 7.5 * s + sway,
      topY + 3 * s, // head curves out
      cx + 11 * s + sway,
      shoulderY, // shoulder width
      cx + 9.5 * s + sway,
      waistY, // tapers at waist
    );
    bodyPath.cubicTo(
      cx + 10 * s + sway,
      waistY + 6 * s, // flows out
      cx + 12 * s + sway,
      bottomY - 3 * s, // garment bottom
      cx + 7 * s + sway,
      bottomY, // bottom right
    );
    // Bottom curve
    bodyPath.quadraticBezierTo(
      cx + sway,
      bottomY + 2.5 * s,
      cx - 7 * s + sway,
      bottomY,
    );
    // Left side (mirror)
    bodyPath.cubicTo(
      cx - 12 * s + sway,
      bottomY - 3 * s,
      cx - 10 * s + sway,
      waistY + 6 * s,
      cx - 9.5 * s + sway,
      waistY,
    );
    bodyPath.cubicTo(
      cx - 11 * s + sway,
      shoulderY,
      cx - 7.5 * s + sway,
      topY + 3 * s,
      cx + sway,
      topY,
    );
    bodyPath.close();

    // Fill with gradient — lit from above like noor is coming from the path ahead
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            baseColor.withValues(alpha: walkerAlpha * 0.9),
            baseColor.withValues(alpha: walkerAlpha * 0.5),
            baseColor.withValues(alpha: walkerAlpha * 0.25),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTRB(cx - 13 * s, topY, cx + 13 * s, bottomY)),
    );

    // -- Inner light core (a soft glow at chest level) --
    canvas.drawCircle(
      Offset(cx + sway, shoulderY + 5 * s),
      6 * s * pulse,
      Paint()
        ..color = glowColor.withValues(alpha: walkerAlpha * 0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (6 * s).toDouble()),
    );

    // -- Head: soft luminous circle --
    canvas.drawCircle(
      Offset(cx + sway, topY + 1.5 * s),
      3.8 * s,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: walkerAlpha * 0.6),
            baseColor.withValues(alpha: walkerAlpha * 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: Offset(cx + sway, topY + 1.5 * s),
            radius: 3.8 * s,
          ),
        ),
    );

    // -- Ground glow underneath feet --
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + sway, bottomY + 2 * s),
        width: 14 * s,
        height: 4 * s,
      ),
      Paint()
        ..color = glowColor.withValues(alpha: walkerAlpha * 0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (5 * s).toDouble()),
    );

    // -- Faint trailing light particles behind the walker --
    if (progress > 0.05) {
      for (int i = 0; i < 3; i++) {
        final trailT = (walkPhase + i * 0.33) % 1.0;
        final trailAlpha = (1.0 - trailT) * walkerAlpha * 0.25;
        final trailY = bottomY + trailT * 10 * s;
        final trailX = cx + sway + math.sin(trailT * math.pi * 3 + i) * 3 * s;
        canvas.drawCircle(
          Offset(trailX, trailY),
          (1.5 - trailT * 0.8) * s,
          Paint()..color = glowColor.withValues(alpha: trailAlpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GlowingPathPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.walkPhase != walkPhase;
}

// =============================================================================
// 🔥 Freedom Flame (عتق من النار) — Get yourself freed from Hellfire
// =============================================================================
// =============================================================================
// 🔥 Freedom from Fire — Allah frees from Hellfire who reads this 4 times
// morning_27 / evening_27
// =============================================================================
class _FreedomFlame extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _FreedomFlame({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_FreedomFlame> createState() => _FreedomFlameState();
}

class _FreedomFlameState extends State<_FreedomFlame>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl,
      _growCtrl,
      _flameCtrl,
      _walkCtrl,
      _shieldCtrl;
  late Animation<double> _pulse, _grow, _flame, _walk, _shield;
  double _prevProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.94,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    // Flame flicker — fast loop
    _flameCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _flame = CurvedAnimation(parent: _flameCtrl, curve: Curves.easeInOut);

    // Person walks rightward as progress grows
    _walkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _walk = CurvedAnimation(parent: _walkCtrl, curve: Curves.easeOutCubic);
    _walkCtrl.value = widget.progress;

    // Shield/safe-zone glow
    _shieldCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _shield = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _shieldCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_FreedomFlame old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _walkCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _flameCtrl.dispose();
    _walkCtrl.dispose();
    _shieldCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _flameCtrl,
        _walkCtrl,
        _shieldCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 260,
            child: CustomPaint(
              painter: _FreedomFlamePainter(
                progress: _grow.value,
                pulse: _pulse.value,
                flamePhase: _flame.value,
                walkPhase: _walk.value,
                shieldGlow: _shield.value,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
              ),
            ),
          ),
    );
  }
}

class _FreedomFlamePainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double flamePhase;
  final double walkPhase;
  final double shieldGlow;
  final bool isComplete;
  final int pointsToday;

  const _FreedomFlamePainter({
    required this.progress,
    required this.pulse,
    required this.flamePhase,
    required this.walkPhase,
    required this.shieldGlow,
    required this.isComplete,
    this.pointsToday = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundY = h * 0.78;

    // ── Background: deep dark with warm left / cool right split ──
    _paintBackground(canvas, w, h, progress);

    // ── Ground line ──
    canvas.drawLine(
      Offset(0, groundY),
      Offset(w, groundY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1.0,
    );

    // ── LEFT: Hellfire ──
    _drawFire(canvas, w, h, groundY);

    // ── Divider: thin glowing barrier that grows with progress ──
    _drawBarrier(canvas, w, h, groundY);

    // ── RIGHT: Safe zone + person ──
    _drawSafeZone(canvas, w, h, groundY);

    // ── Person walking away from fire ──
    _drawPerson(canvas, w, h, groundY);
  }

  void _paintBackground(Canvas canvas, double w, double h, double prog) {
    // Left half — fiery dark red-orange
    final leftPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Color(0xFF7C0000),
              Color(0xFFB91C1C),
              Color(0xFF450A0A),
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, w * 0.48, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.48, h), leftPaint);

    // Right half — deep safe night
    final rightPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Color(0xFF1E3A5F),
              Color(0xFF0F2942),
              Color(0xFF0A1929),
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(Rect.fromLTWH(w * 0.48, 0, w * 0.52, h));
    canvas.drawRect(Rect.fromLTWH(w * 0.48, 0, w * 0.52, h), rightPaint);

    // Ember glow bleeding from left into right — reduces as progress grows
    final bleedAlpha = (0.35 - prog * 0.28).clamp(0.0, 0.35);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFEF4444).withValues(alpha: bleedAlpha),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  void _drawFire(Canvas canvas, double w, double h, double groundY) {
    const fireX = 0.22; // fire center at 22% width
    final fx = w * fireX;
    final fBaseY = groundY;

    // Draw 3 flame layers — large, medium, small
    _drawFlameLayer(
      canvas,
      fx,
      fBaseY,
      width: 70,
      height: 90,
      color: const Color(0xFFFF6B00),
      phase: flamePhase,
      seed: 0,
    );
    _drawFlameLayer(
      canvas,
      fx - 10,
      fBaseY,
      width: 44,
      height: 70,
      color: const Color(0xFFFF9F1C),
      phase: flamePhase,
      seed: 1,
    );
    _drawFlameLayer(
      canvas,
      fx + 12,
      fBaseY,
      width: 36,
      height: 60,
      color: const Color(0xFFFFCC02),
      phase: flamePhase,
      seed: 2,
    );
    // Inner white-hot core
    _drawFlameLayer(
      canvas,
      fx,
      fBaseY,
      width: 22,
      height: 40,
      color: Colors.white.withValues(alpha: 0.70),
      phase: flamePhase,
      seed: 3,
    );

    // Ember sparks floating up from fire
    for (int i = 0; i < 8; i++) {
      final ex = fx + (i % 3 - 1) * 18.0;
      final ey =
          fBaseY -
          60 -
          (i * 19.0) % 75 +
          math.sin(flamePhase * math.pi * 2 + i * 0.9) * 12;
      final ea = (0.55 - (i * 0.07)).clamp(0.0, 0.8) * flamePhase;
      final er = 1.2 + (i % 3) * 0.6;
      canvas.drawCircle(
        Offset(ex, ey),
        er,
        Paint()..color = const Color(0xFFFF9F1C).withValues(alpha: ea),
      );
    }
  }

  void _drawFlameLayer(
    Canvas canvas,
    double cx,
    double baseY, {
    required double width,
    required double height,
    required Color color,
    required double phase,
    required int seed,
  }) {
    final sway = math.sin(phase * math.pi * 2 + seed * 1.1) * 6;
    final tip = baseY - height + math.sin(phase * math.pi * 2 + seed * 0.7) * 8;
    final path =
        Path()
          ..moveTo(cx - width / 2, baseY)
          ..quadraticBezierTo(
            cx - width * 0.3 + sway,
            baseY - height * 0.45,
            cx + sway * 0.5,
            tip,
          )
          ..quadraticBezierTo(
            cx + width * 0.3 + sway,
            baseY - height * 0.45,
            cx + width / 2,
            baseY,
          )
          ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawBarrier(Canvas canvas, double w, double h, double groundY) {
    final barrierX = w * 0.50;
    final barrierH =
        groundY * (0.35 + progress * 0.55); // grows taller with progress
    final barrierAlpha = (0.20 + progress * 0.55).clamp(0.0, 0.85);

    // Glow behind barrier
    canvas.drawRect(
      Rect.fromLTWH(barrierX - 8, groundY - barrierH, 16, barrierH),
      Paint()
        ..color = const Color(0xFF60A5FA).withValues(alpha: barrierAlpha * 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Barrier line
    canvas.drawLine(
      Offset(barrierX, groundY),
      Offset(barrierX, groundY - barrierH),
      Paint()
        ..color = const Color(0xFF93C5FD).withValues(alpha: barrierAlpha)
        ..strokeWidth = 2.0,
    );
  }

  void _drawSafeZone(Canvas canvas, double w, double h, double groundY) {
    final safeAlpha = (0.08 + progress * 0.18).clamp(0.0, 0.28) * shieldGlow;

    // Soft safe-zone glow on right side
    canvas.drawRect(
      Rect.fromLTWH(w * 0.52, 0, w * 0.48, h),
      Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: safeAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // Stars in the safe night sky
    const stars = [
      (0.62, 0.08),
      (0.72, 0.05),
      (0.82, 0.12),
      (0.90, 0.07),
      (0.68, 0.17),
      (0.78, 0.22),
      (0.88, 0.18),
      (0.96, 0.13),
    ];
    for (int i = 0; i < stars.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(shieldGlow * math.pi * 2 + i * 0.8);
      final a = (0.12 + 0.28 * tw * progress).clamp(0.0, 0.55);
      canvas.drawCircle(
        Offset(stars[i].$1 * w, stars[i].$2 * h),
        0.8 + tw * 0.6,
        Paint()..color = Colors.white.withValues(alpha: a),
      );
    }

    // Crescent moon (completion symbol)
    if (progress > 0.5) {
      final moonA = ((progress - 0.5) * 2).clamp(0.0, 1.0) * 0.85;
      final moonX = w * 0.88;
      final moonY = h * 0.18;
      canvas.drawCircle(
        Offset(moonX, moonY),
        10,
        Paint()..color = Colors.white.withValues(alpha: moonA * 0.90),
      );
      canvas.drawCircle(
        Offset(moonX + 6, moonY - 2),
        8,
        Paint()..color = const Color(0xFF0F2942).withValues(alpha: moonA),
      );
    }
  }

  void _drawPerson(Canvas canvas, double w, double h, double groundY) {
    // Person starts near the fire (left) and walks right as progress increases
    final startX = w * 0.36;
    final endX = w * 0.70;
    final personX = startX + (endX - startX) * walkPhase;
    final personY = groundY - 2;

    final skin = const Color(0xFFD4A574);
    final robe = Colors.white.withValues(alpha: 0.92);
    final walkBob = math.sin(walkPhase * math.pi * 6) * 1.5; // walking bob

    // Shadow on ground
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(personX, personY + 2),
        width: 16,
        height: 5,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );

    // Head
    canvas.drawCircle(
      Offset(personX, personY - 40 + walkBob),
      7.5,
      Paint()..color = skin,
    );

    // Body (robe)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(personX, personY - 22 + walkBob),
          width: 13,
          height: 20,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = robe,
    );

    // Arms (raised slightly in relief/thankfulness)
    final armLift = (walkPhase * 20 - 6).clamp(-8.0, 4.0);
    canvas.drawLine(
      Offset(personX - 6, personY - 27 + walkBob),
      Offset(personX - 13, personY - 20 + walkBob + armLift),
      Paint()
        ..color = skin
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(personX + 6, personY - 27 + walkBob),
      Offset(personX + 13, personY - 20 + walkBob + armLift),
      Paint()
        ..color = skin
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // Legs (walking animation)
    final legSwing = math.sin(walkPhase * math.pi * 8) * 4;
    canvas.drawLine(
      Offset(personX - 2, personY - 12 + walkBob),
      Offset(personX - 4 - legSwing, personY),
      Paint()
        ..color = robe
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(personX + 2, personY - 12 + walkBob),
      Offset(personX + 4 + legSwing, personY),
      Paint()
        ..color = robe
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );

    // Heat shimmer behind person when close to fire (early in progress)
    if (walkPhase < 0.4) {
      final heatA = (0.4 - walkPhase) * 0.35;
      canvas.drawCircle(
        Offset(personX, personY - 25),
        20,
        Paint()
          ..color = const Color(0xFFFF6B00).withValues(alpha: heatA)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(_FreedomFlamePainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.flamePhase != flamePhase ||
      o.walkPhase != walkPhase ||
      o.shieldGlow != shieldGlow ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday;
}

// =============================================================================
// 🌅 Cycle of Return (دورة الرجوع) — By You we live, die, and return
// =============================================================================
class _CycleOfReturn extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _CycleOfReturn({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_CycleOfReturn> createState() => _CycleOfReturnState();
}

class _CycleOfReturnState extends State<_CycleOfReturn>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _growCtrl;
  late Animation<double> _grow;
  double _prevProgress = 0.0;
  late AnimationController _starCtrl;
  late AnimationController _pCtrl;
  late Animation<double> _pAnim;
  int _prevTap = 0;
  late AnimationController _punchCtrl;
  late Animation<double> _punch;
  late AnimationController _shockCtrl;
  late Animation<double> _shock;
  late AnimationController _orbitCtrl;

  final List<_Particle> _particles = List.generate(
    16,
    (i) => _Particle(seed: i + 1400),
  );

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();
  }

  @override
  void didUpdateWidget(_CycleOfReturn old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _orbitCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _CycleOfReturnPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                orbitPhase: _orbitCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _CycleOfReturnPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double orbitPhase;

  // Journey phases: dawn → life → dusk → resurrection
  static const _phaseColors = [
    Color(0xFFF59E0B), // dawn — amber sunrise
    Color(0xFFFFC83D), // life — emerald vitality
    Color(0xFF6366F1), // dusk — indigo twilight
    Color(0xFFD4AF37), // nushur — golden resurrection
  ];

  static const _phaseLabels = ['صُبْح', 'حَيَاة', 'مَسَاء', 'نُشُور'];

  const _CycleOfReturnPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.orbitPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final halfW = w / 2;
    final horizonY = h * 0.62;

    // ── LEFT HALF: Morning (warm sunrise) ──
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, halfW, h));
    // Sky gradient — warm golden-yellow
    canvas.drawRect(
      Rect.fromLTWH(0, 0, halfW, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFF8E1),
            Color.lerp(
              const Color(0xFFFFECB3),
              const Color(0xFFFFD54F),
              progress,
            )!,
            Color.lerp(
              const Color(0xFFFFCC80),
              const Color(0xFFFB8C00),
              progress,
            )!,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, halfW, h)),
    );

    // Morning sun
    final sunR = 18 + progress * 8;
    final sunCy = horizonY - progress * horizonY * 0.30;
    canvas.drawCircle(
      Offset(halfW * 0.5, sunCy),
      sunR + 12,
      Paint()
        ..color = Color.fromRGBO(255, 220, 100, 0.12 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawCircle(
      Offset(halfW * 0.5, sunCy),
      sunR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.85),
            const Color(0xFFFFE082).withValues(alpha: 0.75),
            const Color(0xFFFFB74D).withValues(alpha: 0.50),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(halfW * 0.5, sunCy), radius: sunR),
        ),
    );
    // Sun rays
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi * 2 / 6;
      final sx = halfW * 0.5 + math.cos(angle) * (sunR + 3);
      final sy = sunCy + math.sin(angle) * (sunR + 3);
      final ex = halfW * 0.5 + math.cos(angle) * (sunR + 14 + progress * 8);
      final ey = sunCy + math.sin(angle) * (sunR + 14 + progress * 8);
      canvas.drawLine(
        Offset(sx, sy),
        Offset(ex, ey),
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.25 * progress)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Morning hills
    final hillPath =
        Path()
          ..moveTo(0, horizonY)
          ..quadraticBezierTo(
            halfW * 0.25,
            horizonY - 20,
            halfW * 0.5,
            horizonY - 15,
          )
          ..quadraticBezierTo(halfW * 0.75, horizonY - 8, halfW, horizonY)
          ..lineTo(halfW, h)
          ..lineTo(0, h)
          ..close();
    canvas.drawPath(
      hillPath,
      Paint()
        ..color =
            Color.lerp(
              const Color(0xFFE6A050),
              const Color(0xFFF5B041),
              progress,
            )!,
    );

    canvas.restore();

    // ── RIGHT HALF: Evening (cool night) ──
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(halfW, 0, halfW, h));
    // Sky gradient — deep blue-indigo
    canvas.drawRect(
      Rect.fromLTWH(halfW, 0, halfW, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1A3E),
            Color.lerp(
              const Color(0xFF1E2952),
              const Color(0xFF2C3E6B),
              progress,
            )!,
            Color.lerp(
              const Color(0xFF2A3555),
              const Color(0xFF3B4F7A),
              progress,
            )!,
          ],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(Rect.fromLTWH(halfW, 0, halfW, h)),
    );

    // Stars on night side
    const nightStars = [
      (0.55, 0.08),
      (0.62, 0.18),
      (0.70, 0.06),
      (0.78, 0.14),
      (0.85, 0.10),
      (0.92, 0.20),
      (0.58, 0.25),
      (0.75, 0.22),
    ];
    for (int i = 0; i < nightStars.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      canvas.drawCircle(
        Offset(nightStars[i].$1 * w, nightStars[i].$2 * h),
        0.8 + tw * 1.0,
        Paint()..color = Colors.white.withValues(alpha: 0.25 + 0.45 * tw),
      );
    }

    // Crescent moon
    final moonCx = halfW + halfW * 0.5;
    final moonCy = horizonY * 0.35;
    final moonR = 16.0;
    final outerMoon =
        Path()..addOval(
          Rect.fromCircle(center: Offset(moonCx, moonCy), radius: moonR),
        );
    final innerMoon =
        Path()..addOval(
          Rect.fromCircle(
            center: Offset(moonCx + moonR * 0.5, moonCy - moonR * 0.1),
            radius: moonR * 0.85,
          ),
        );
    final crescentPath = Path.combine(
      PathOperation.difference,
      outerMoon,
      innerMoon,
    );
    canvas.drawCircle(
      Offset(moonCx, moonCy),
      moonR + 6,
      Paint()
        ..color = const Color(0xFFE8D98A).withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      crescentPath,
      Paint()..color = const Color(0xFFE8D98A).withValues(alpha: 0.80),
    );

    // Evening hills
    final eHillPath =
        Path()
          ..moveTo(halfW, horizonY)
          ..quadraticBezierTo(
            halfW + halfW * 0.3,
            horizonY - 18,
            halfW + halfW * 0.6,
            horizonY - 12,
          )
          ..quadraticBezierTo(halfW + halfW * 0.85, horizonY - 5, w, horizonY)
          ..lineTo(w, h)
          ..lineTo(halfW, h)
          ..close();
    canvas.drawPath(
      eHillPath,
      Paint()..color = const Color(0xFF1E2845).withValues(alpha: 0.85),
    );

    canvas.restore();

    // ── Center divider — soft gradient blend ──
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, h / 2), width: 2, height: h * 0.65),
      Paint()..color = Colors.white.withValues(alpha: 0.20),
    );

    // ── Progress label ──
    // progress % label removed

    // ── Points badge ──
  }

  @override
  bool shouldRepaint(_CycleOfReturnPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.orbitPhase != orbitPhase;
}

// =============================================================================
// 💚 Body Hearing Sight — Allah's gift of wellbeing (morning_28 / evening_28)
// =============================================================================
class _ThreeVessels extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _ThreeVessels({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_ThreeVessels> createState() => _ThreeVesselsState();
}

class _ThreeVesselsState extends State<_ThreeVessels>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _glowCtrl;
  late Animation<double> _pulse, _grow, _glow;
  double _prevProgress = 0.0;

  static const _rows = [
    (label: 'Wellbeing', sub: 'in your body', hex: 0xFF0D8A6A, isGood: true),
    (label: 'Wellbeing', sub: 'in your hearing', hex: 0xFF1565C0, isGood: true),
    (label: 'Wellbeing', sub: 'in your sight', hex: 0xFF6A1B9A, isGood: true),
    (
      label: 'Protection',
      sub: 'from disbelief and poverty',
      hex: 0xFFC84B31,
      isGood: false,
    ),
    (
      label: 'Protection',
      sub: 'from the punishment of the grave',
      hex: 0xFF8B4513,
      isGood: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_ThreeVessels old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _glowCtrl]),
      builder: (_, __) {
        final progress = _grow.value;
        return SizedBox(
          height: 260,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors:
                        isDark
                            ? [const Color(0xFF1A2030), const Color(0xFF1A2828)]
                            : [
                              const Color(0xFFF5F9FF),
                              const Color(0xFFEDF8F3),
                            ],
                  ),
                ),
              ),
              CustomPaint(painter: _VesselDotPainter(isDark: isDark)),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i < _rows.length; i++)
                      _buildRow(
                        rowIdx: i,
                        total: _rows.length,
                        progress: progress,
                        isDark: isDark,
                      ),
                  ],
                ),
              ),
              if (widget.isComplete)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(
                            0xFF26C485,
                          ).withValues(alpha: _glow.value * 0.85),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow({
    required int rowIdx,
    required int total,
    required double progress,
    required bool isDark,
  }) {
    final row = _rows[rowIdx];
    final accent = Color(row.hex);
    // All rows fully visible from frame 1 (was 0.18..1.0 reveal as user
    // counted, leaving the vessel labels ghosted before completion).
    const double rowP = 1.0;
    return AnimatedOpacity(
      opacity: rowP,
      duration: const Duration(milliseconds: 350),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.11 : 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.35 : 0.22),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: rowP * (isDark ? 0.9 : 0.75)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${row.label}  ',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: accent.withValues(
                          alpha: rowP * (isDark ? 1.0 : 0.9),
                        ),
                      ),
                    ),
                    TextSpan(
                      text: row.sub,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark
                                ? Colors.white70.withValues(alpha: rowP)
                                : const Color(
                                  0xFF2D3748,
                                ).withValues(alpha: rowP * 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VesselDotPainter extends CustomPainter {
  final bool isDark;
  const _VesselDotPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = (isDark ? Colors.white : const Color(0xFF0D6B52))
              .withValues(alpha: isDark ? 0.04 : 0.05);
    const spacing = 22.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_VesselDotPainter o) => o.isDark != isDark;
}

// =============================================================================
// 📜 Seven Times Promise — Allah suffices in this world & Hereafter
// Hasbiyallahu (morning_29 / evening_29)
// =============================================================================
class _SevenPillars extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _SevenPillars({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_SevenPillars> createState() => _SevenPillarsState();
}

class _SevenPillarsState extends State<_SevenPillars>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _glowCtrl, _fadeCtrl;
  late Animation<double> _pulse, _grow, _glow, _fade;
  double _prevProgress = 0.0;

  // The benefit split into meaningful lines
  static const _lines = [
    'Allah will suffice you',
    'against whatever concerns you',
    'in the matters of',
    'this world',
    'and the Hereafter',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
  }

  @override
  void didUpdateWidget(_SevenPillars old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _glowCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _glowCtrl,
        _fadeCtrl,
      ]),
      builder: (_, __) {
        final progress = _grow.value;
        final totalLines = _lines.length;

        return SizedBox(
          height: 260,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background — deep indigo to teal gradient ──
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        isDark
                            ? [const Color(0xFF1A2E3A), const Color(0xFF1E3D30)]
                            : [
                              const Color(0xFFF0F7FF),
                              const Color(0xFFE8F5F0),
                            ],
                  ),
                ),
              ),

              // ── Soft radial glow in center ──
              Center(
                child: Container(
                  width: 220 * _pulse.value,
                  height: 220 * _pulse.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(
                          0xFFD4AF37,
                        ).withValues(alpha: 0.12 * _glow.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Lines revealed progressively ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < totalLines; i++) ...[
                      _buildLine(
                        context,
                        text: _lines[i],
                        lineIndex: i,
                        totalLines: totalLines,
                        progress: progress,
                        isComplete: widget.isComplete,
                        isDark: isDark,
                      ),
                      if (i < totalLines - 1) const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),

              // ── Completion shimmer at bottom ──
              if (widget.isComplete)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(
                            0xFFD4AF37,
                          ).withValues(alpha: _glow.value * 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLine(
    BuildContext context, {
    required String text,
    required int lineIndex,
    required int totalLines,
    required double progress,
    required bool isComplete,
    bool isDark = false,
  }) {
    // Lines used to fade in one-by-one as the user counted, leaving the
    // pillars illustration mostly blank before completion. Render every
    // line fully visible from frame 1; only the completion state still
    // shifts colour to gold to celebrate.

    // Style varies: two lines big + bold, rest smaller
    final isBig = lineIndex == 0 || lineIndex == totalLines - 1;
    final isHighlight = lineIndex == 3; // "this world AND the Hereafter" lines

    final Color textColor;
    final double fontSize;

    if (isHighlight || isComplete) {
      textColor = isDark ? const Color(0xFFFFD700) : const Color(0xFF2A2410);
      fontSize = isBig ? 20 : 17;
    } else if (lineIndex == 0) {
      textColor = isDark ? Colors.white : const Color(0xFF0C3547);
      fontSize = 22;
    } else {
      textColor = (isDark ? Colors.white : const Color(0xFF2A2410))
          .withValues(alpha: 0.85);
      fontSize = isBig ? 19 : 15;
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: fontSize * (lineIndex == 0 ? _pulse.value : 1.0),
        fontWeight:
            lineIndex == 0 || isComplete ? FontWeight.w800 : FontWeight.w600,
        color: textColor,
        letterSpacing: lineIndex == 0 ? 0.5 : 0.2,
        height: 1.3,
      ),
    );
  }
}

// =============================================================================
// 🚪 Noor Door — Raditu Billahi (morning_18 / evening_18)
// "I am pleased with Allah as my Lord" — Ahmad 18967
// Double golden doors swing open; divine Noor floods the frame
// Completion: doors fully open + gold flash + label مَرْضَاةُ اللّٰهِ
// =============================================================================
class _NoorDoor extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _NoorDoor({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_NoorDoor> createState() => _NoorDoorState();
}

class _NoorDoorState extends State<_NoorDoor> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl,
      _growCtrl,
      _starCtrl,
      _pCtrl,
      _punchCtrl,
      _shockCtrl,
      _doorCtrl;
  late Animation<double> _pulse, _grow, _door;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _doorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addListener(() => setState(() {}));

    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOut);
    _door = CurvedAnimation(parent: _doorCtrl, curve: Curves.easeInOut);

    _growCtrl.animateTo(widget.progress);
    // Begin opening doors with slight delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _doorCtrl.animateTo(widget.progress.clamp(0.15, 1.0));
    });
  }

  @override
  void didUpdateWidget(_NoorDoor old) {
    super.didUpdateWidget(old);
    _growCtrl.animateTo(widget.progress);
    _doorCtrl.animateTo((widget.progress).clamp(0.15, 1.0));
    if (widget.tapCount > old.tapCount) {
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _doorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _doorCtrl,
        _pCtrl,
        _shockCtrl,
      ]),
      builder: (context, _) {
        return SizedBox(
          height: 260,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _NoorDoorPainter(
                  pulse: _pulse.value,
                  grow: _grow.value,
                  star: _starCtrl.value,
                  door: _door.value,
                  shock: _shockCtrl.value,
                  p: _pCtrl.value,
                  complete: widget.isComplete,
                ),
              ),
              if (widget.isComplete)
                Align(
                  alignment: const Alignment(0, 0.90),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Pleasure of Allah',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: const Color(0xFFD4AF37),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NoorDoorPainter extends CustomPainter {
  final double pulse, grow, star, door, shock, p;
  final bool complete;
  const _NoorDoorPainter({
    required this.pulse,
    required this.grow,
    required this.star,
    required this.door,
    required this.shock,
    required this.p,
    required this.complete,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ── Background: warm cream/gold gradient ──────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFFFF8E7), const Color(0xFFFFF3CC)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // ── Noor burst (central light rays) ───────────────────────────────────────
    final noorAlpha = (0.25 + door * 0.55 + pulse * 0.08).clamp(0.0, 1.0);
    final rayPaint =
        Paint()
          ..color = const Color(0xFFFFE680).withValues(alpha: noorAlpha * 0.6)
          ..style = PaintingStyle.fill;

    // Draw 16 rays from center
    const rayCount = 16;
    final rayMaxLen = h * 0.80;
    final rayPath = Path();
    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 3.14159265 * 2;
      final halfAngle = 3.14159265 / rayCount * 0.45;
      final rayLen = rayMaxLen * (0.7 + (i % 3) * 0.1);
      rayPath.moveTo(cx, h * 0.46);
      rayPath.lineTo(
        cx +
            rayLen *
                1.1 *
                (i % 2 == 0 ? 1 : 0.85) *
                math.cos(angle - halfAngle),
        h * 0.46 + rayLen * math.sin(angle - halfAngle),
      );
      rayPath.lineTo(
        cx + rayLen * math.cos(angle + halfAngle),
        h * 0.46 + rayLen * math.sin(angle + halfAngle),
      );
      rayPath.close();
    }
    canvas.drawPath(rayPath, rayPaint);

    // Inner glow circle
    canvas.drawCircle(
      Offset(cx, h * 0.46),
      42 + pulse * 14 + door * 26,
      Paint()
        ..color = Colors.white.withValues(
          alpha: (0.5 + door * 0.35).clamp(0.0, 1.0),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // ── Floor line ────────────────────────────────────────────────────────────
    final floorY = h * 0.82;
    canvas.drawRect(
      Rect.fromLTWH(0, floorY, w, h - floorY),
      Paint()..color = const Color(0xFFF5E6C0),
    );

    // ── Clip all drawing to canvas bounds ────────────────────────────────────
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));

    // ── Arch: narrower + segmental (shallow) arc ───────────────────────────
    // archW = 52% of width → less wide look
    // Radius > archW/2 → flattens the arc so peak stays within canvas
    final archW = w * 0.52;
    final archLeft = cx - archW / 2;
    final archRight = cx + archW / 2;
    final springY = h * 0.20; // where vertical sides meet the arc
    final arcRadius = w * 0.37; // larger than archW/2 → shallow segmental arc

    final archPaint =
        Paint()
          ..color = const Color(0xFFB8860B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round;

    final archPath =
        Path()
          ..moveTo(archLeft, floorY)
          ..lineTo(archLeft, springY)
          ..arcToPoint(
            Offset(archRight, springY),
            radius: Radius.circular(arcRadius),
            largeArc: false,
          )
          ..lineTo(archRight, floorY);
    canvas.drawPath(archPath, archPaint);

    // Keystone ornament — sits at estimated arc peak
    // For a segmental arc: peak drop = radius - sqrt(radius²-(archW/2)²)
    final peakDrop =
        arcRadius -
        math.sqrt(arcRadius * arcRadius - (archW / 2) * (archW / 2));
    final keystoneY = springY - peakDrop;
    canvas.drawCircle(
      Offset(cx, keystoneY + 4),
      9,
      Paint()..color = const Color(0xFFD4AF37),
    );
    canvas.drawCircle(
      Offset(cx, keystoneY + 4),
      5.5,
      Paint()..color = const Color(0xFFFFE680),
    );

    canvas.restore();

    // ── Doors (swing open on progress) ────────────────────────────────────────
    // door = 0 → fully closed, door = 1 → fully open
    // Left door: rotates from closed (angle 0) to open (angle ~-75°)
    // Right door: mirrors
    final maxAngle = 1.20; // radians ≈ 69°
    final doorAngle = door * maxAngle;

    final doorH = floorY - springY;
    final doorW = archW / 2 - 4;

    // Door colours
    final doorLight = const Color(0xFFE8BE50); // face colour
    final doorDark = const Color(0xFFB8860B); // edge / shadow
    final doorEdge = const Color(0xFF8B6914); // deep edge
    final panelColor = const Color(0xFFD4A820).withValues(alpha: 0.55);

    void drawDoor(Canvas c, bool isLeft) {
      // Perspective: left door swings left, right door swings right
      // We shrink width by cos(angle) to fake 3-D
      final cosA = math.cos(doorAngle).clamp(0.0, 1.0);
      final sign = isLeft ? -1.0 : 1.0;
      final hinge = isLeft ? archLeft + 4 : archRight - 4;
      final visibleW = doorW * cosA; // apparent width shrinks as door opens

      // Door face rect
      final faceRect =
          isLeft
              ? Rect.fromLTWH(hinge, springY, visibleW, doorH)
              : Rect.fromLTWH(hinge - visibleW, springY, visibleW, doorH);

      // Door fill — gold gradient
      c.drawRect(
        faceRect,
        Paint()
          ..shader = LinearGradient(
            begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
            colors: [doorDark, doorLight, doorDark.withValues(alpha: 0.85)],
          ).createShader(faceRect),
      );

      // Panel inset (decorative rectangle)
      if (visibleW > 12) {
        final px = isLeft ? hinge + visibleW * 0.12 : hinge - visibleW * 0.88;
        final topPanel = Rect.fromLTWH(
          px,
          springY + doorH * 0.06,
          visibleW * 0.76,
          doorH * 0.32,
        );
        final botPanel = Rect.fromLTWH(
          px,
          springY + doorH * 0.06 + doorH * 0.38,
          visibleW * 0.76,
          doorH * 0.34,
        );
        final rr = RRect.fromRectAndRadius(topPanel, const Radius.circular(4));
        final rr2 = RRect.fromRectAndRadius(botPanel, const Radius.circular(4));
        c.drawRRect(rr, Paint()..color = panelColor);
        c.drawRRect(rr2, Paint()..color = panelColor);
        // Panel border
        final pBorder =
            Paint()
              ..color = doorDark.withValues(alpha: 0.4)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2;
        c.drawRRect(rr, pBorder);
        c.drawRRect(rr2, pBorder);
      }

      // Handle (knob)
      if (visibleW > 10) {
        final knobX =
            isLeft ? hinge + visibleW * 0.78 : hinge - visibleW * 0.78;
        final knobY = springY + doorH * 0.52;
        c.drawCircle(Offset(knobX, knobY), 5.5, Paint()..color = doorEdge);
        c.drawCircle(
          Offset(knobX, knobY),
          3.5,
          Paint()..color = const Color(0xFFFFE999),
        );
      }

      // Edge shadow to give depth
      final edgeX = isLeft ? hinge + visibleW : hinge - visibleW;
      c.drawLine(
        Offset(edgeX, springY),
        Offset(edgeX, floorY),
        Paint()
          ..color = doorEdge.withValues(alpha: 0.6)
          ..strokeWidth = 3,
      );
    }

    drawDoor(canvas, true); // left door
    drawDoor(canvas, false); // right door

    // ── Floating Noor particles ────────────────────────────────────────────────
    if (door > 0.12) {
      final rng = [0.48, 0.52, 0.45, 0.56, 0.50, 0.42, 0.58];
      final rngy = [0.28, 0.45, 0.60, 0.35, 0.50, 0.40, 0.55];
      final particlePaint = Paint();
      for (int i = 0; i < rng.length; i++) {
        final flicker = (star + i * 0.23) % 1.0;
        final alpha = (door * (0.3 + flicker * 0.5)).clamp(0.0, 0.8);
        particlePaint.color = const Color(0xFFFFE680).withValues(alpha: alpha);
        final radius = 2.5 + (i % 3) * 1.8;
        canvas.drawCircle(
          Offset(w * rng[i], h * rngy[i]),
          radius,
          particlePaint
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }

    // ── Tap shockwave ─────────────────────────────────────────────────────────
    if (shock > 0) {
      canvas.drawCircle(
        Offset(cx, h * 0.38),
        shock * w * 0.45,
        Paint()
          ..color = const Color(
            0xFFD4AF37,
          ).withValues(alpha: (1 - shock) * 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // ── Completion gold wash ──────────────────────────────────────────────────
    if (complete) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: 0.07)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
    }
  }

  @override
  bool shouldRepaint(_NoorDoorPainter old) =>
      old.pulse != pulse ||
      old.grow != grow ||
      old.star != star ||
      old.door != door ||
      old.shock != shock ||
      old.p != p ||
      old.complete != complete;
}

// =============================================================================
// 🤝 Guiding Hand (يد الشفاعة) — Prophet holds your hand into Jannah
// =============================================================================
class _GuidingHand extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _GuidingHand({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_GuidingHand> createState() => _GuidingHandState();
}

class _GuidingHandState extends State<_GuidingHand>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _growCtrl;
  late Animation<double> _grow;
  double _prevProgress = 0.0;
  late AnimationController _starCtrl;
  late AnimationController _pCtrl;
  late Animation<double> _pAnim;
  int _prevTap = 0;
  late AnimationController _punchCtrl;
  late Animation<double> _punch;
  late AnimationController _shockCtrl;
  late Animation<double> _shock;
  late AnimationController _glowCtrl;

  final List<_Particle> _particles = List.generate(
    16,
    (i) => _Particle(seed: i + 1700),
  );

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_GuidingHand old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _glowCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _GuidingHandPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                glowPhase: _glowCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _GuidingHandPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double glowPhase;

  static const _handColor = Color(0xFFFFC83D); // emerald — prophetic noor
  static const _pathColor = Color(0xFFFFC83D); // light emerald — path of light
  static const _gateColor = Color(0xFFD4AF37); // golden — gates of Jannah

  const _GuidingHandPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.glowPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.44;

    // 1. Background — warm garden-like tones
    final warmth = progress * 0.15;
    _paintLightBg(canvas, w, h, progress: progress);

    // 2. Stars
    const starPos = [
      (0.10, 0.06),
      (0.22, 0.15),
      (0.40, 0.05),
      (0.55, 0.11),
      (0.70, 0.07),
      (0.85, 0.14),
      (0.93, 0.06),
      (0.32, 0.21),
      (0.65, 0.20),
      (0.18, 0.22),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.9);
      final starAlpha = (0.08 + progress * 0.30 + 0.30 * tw * progress).clamp(
        0.0,
        0.6,
      );
      sp.color = Colors.white.withValues(alpha: starAlpha);
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h),
        0.7 + tw * 0.8,
        sp,
      );
    }

    // Apply punch scale
    canvas.save();
    // punch scale removed — smooth calm tap

    // 3. Gateway arch (centered)
    _drawHand(canvas, cx, cy + 5, w);

    canvas.restore();

    // 6. Shockwave on tap
    // tap-effect removed — smooth calm

    // 7. Tap particles
    // tap-effect removed — smooth calm

    // 8. Progress label
    // progress % label removed

    // 9. Points badge
  }

  /// Luminous hand reaching down — prophetic guidance
  void _drawHand(Canvas canvas, double cx, double cy, double w) {
    // Gateway/arch motif — golden arch with doors opening
    final alpha = 0.30 + progress * 0.55;
    final gateY = cy + 10;
    final gateH = 60.0;
    final gateW = 20.0;
    final openAmt = progress * gateW * 0.8;
    final gateTop = gateY - gateH;

    final doorColor = _handColor.withValues(alpha: alpha * 0.85);
    final edgeColor =
        isComplete
            ? _gateColor.withValues(alpha: alpha * 0.70)
            : _handColor.withValues(alpha: alpha * 0.55);
    final panelColor =
        isComplete
            ? _gateColor.withValues(alpha: alpha * 0.50)
            : _handColor.withValues(alpha: alpha * 0.35);

    // Arch above gates
    final archLeft = cx - gateW - openAmt - 6;
    final archRight = cx + gateW + openAmt + 6;
    final archTop = gateTop - 18;
    final archPath =
        Path()
          ..moveTo(archLeft, gateTop)
          ..quadraticBezierTo(archLeft, archTop + 6, cx, archTop)
          ..quadraticBezierTo(archRight, archTop + 6, archRight, gateTop);
    canvas.drawPath(
      archPath,
      Paint()
        ..color = edgeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    // Circle ornament on top of arch
    canvas.drawCircle(Offset(cx, archTop - 2), 5, Paint()..color = edgeColor);
    canvas.drawCircle(
      Offset(cx, archTop - 2),
      3,
      Paint()..color = Colors.white.withValues(alpha: alpha * 0.4),
    );

    // Left door
    final leftX = cx - 2 - openAmt;
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(leftX - gateW, gateTop, gateW, gateH),
      const Radius.circular(2),
    );
    canvas.drawRRect(leftRect, Paint()..color = doorColor);
    canvas.drawRRect(
      leftRect,
      Paint()
        ..color = edgeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // Panels
    for (int i = 0; i < 2; i++) {
      final py = gateTop + 6 + i * (gateH * 0.44);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(leftX - gateW + 3, py, gateW - 6, gateH * 0.34),
          const Radius.circular(1.5),
        ),
        Paint()
          ..color = panelColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
    canvas.drawCircle(
      Offset(leftX - 4, gateY - gateH * 0.45),
      2,
      Paint()..color = panelColor,
    );

    // Right door
    final rightX = cx + 2 + openAmt;
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rightX, gateTop, gateW, gateH),
      const Radius.circular(2),
    );
    canvas.drawRRect(rightRect, Paint()..color = doorColor);
    canvas.drawRRect(
      rightRect,
      Paint()
        ..color = edgeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    for (int i = 0; i < 2; i++) {
      final py = gateTop + 6 + i * (gateH * 0.44);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rightX + 3, py, gateW - 6, gateH * 0.34),
          const Radius.circular(1.5),
        ),
        Paint()
          ..color = panelColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
    canvas.drawCircle(
      Offset(rightX + 4, gateY - gateH * 0.45),
      2,
      Paint()..color = panelColor,
    );

    // Light behind open gates
    if (progress > 0.1) {
      final lightA = progress * (isComplete ? 0.25 : 0.12) * pulse;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx, gateY - gateH * 0.4),
          width: openAmt * 1.8,
          height: gateH * 0.8,
        ),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: lightA * 1.5),
              _gateColor.withValues(alpha: lightA),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTRB(0, gateTop, w, gateY)),
      );
    }

    // Noor emanating from center of gates
    if (progress > 0.3) {
      final noorAlpha = ((progress - 0.3) / 0.7).clamp(0.0, 1.0) * 0.20 * pulse;
      canvas.drawCircle(
        Offset(cx, gateY - gateH * 0.4),
        10,
        Paint()
          ..color = Colors.white.withValues(alpha: noorAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  /// Path of light connecting hand to gates
  void _drawPath(Canvas canvas, double cx, double cy, double w, double h) {
    if (progress < 0.05) return;

    final handY = cy - 30 - 30 + progress * 25; // match hand position
    final gateY = cy + 45;

    // Flowing dots along the path
    final pathLen = gateY - handY;
    final dotCount = 12;
    for (int i = 0; i < dotCount; i++) {
      final baseT = i / dotCount;
      // Only show dots up to current progress
      if (baseT > progress) break;

      // Animate flow — dots drift downward
      final flowOffset = (glowPhase + i * 0.08) % 1.0;
      final dotT = (baseT + flowOffset * 0.08).clamp(0.0, 1.0);
      final dotY = handY + dotT * pathLen;
      final dotX =
          cx + math.sin(dotT * math.pi * 3 + glowPhase * math.pi * 2) * 3;

      final dotAlpha =
          (0.15 + progress * 0.30) *
          (1.0 - (dotT - 0.5).abs() * 1.2).clamp(0.2, 1.0);

      canvas.drawCircle(
        Offset(dotX, dotY),
        1.8,
        Paint()..color = _pathColor.withValues(alpha: dotAlpha),
      );
      canvas.drawCircle(
        Offset(dotX, dotY),
        4,
        Paint()
          ..color = _pathColor.withValues(alpha: dotAlpha * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // Central beam connecting hand to gates
    final beamAlpha = progress * 0.08;
    canvas.drawLine(
      Offset(cx, handY + 15),
      Offset(cx, gateY - 10),
      Paint()
        ..color = _pathColor.withValues(alpha: beamAlpha)
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  /// Jannah gates — ornate double doors
  void _drawGates(Canvas canvas, double cx, double cy, double w) {
    final gateW = 35.0;
    final gateH = 45.0;
    final gateAlpha = 0.10 + progress * 0.45;

    // Gate opening — doors part as progress grows
    final openAmount = progress * 8;

    // Left door
    final leftDoor = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        cx - gateW / 2 - openAmount,
        cy - gateH / 2,
        gateW / 2 - 1,
        gateH,
      ),
      const Radius.circular(2),
    );
    // Right door
    final rightDoor = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx + 1 + openAmount, cy - gateH / 2, gateW / 2 - 1, gateH),
      const Radius.circular(2),
    );

    // Gate glow — warm golden light behind (visible as doors open)
    if (progress > 0.2) {
      final glowAlpha = ((progress - 0.2) / 0.8).clamp(0.0, 1.0) * 0.20 * pulse;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: openAmount * 2 + 4,
          height: gateH - 4,
        ),
        Paint()
          ..color = _gateColor.withValues(alpha: glowAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Door fill
    canvas.drawRRect(
      leftDoor,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _gateColor.withValues(alpha: gateAlpha * 0.20),
            _gateColor.withValues(alpha: gateAlpha * 0.35),
          ],
        ).createShader(leftDoor.outerRect),
    );
    canvas.drawRRect(
      rightDoor,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _gateColor.withValues(alpha: gateAlpha * 0.35),
            _gateColor.withValues(alpha: gateAlpha * 0.20),
          ],
        ).createShader(rightDoor.outerRect),
    );

    // Door outlines
    canvas.drawRRect(
      leftDoor,
      Paint()
        ..color = _gateColor.withValues(alpha: gateAlpha * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    canvas.drawRRect(
      rightDoor,
      Paint()
        ..color = _gateColor.withValues(alpha: gateAlpha * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Arch above gates
    final archPath =
        Path()
          ..moveTo(cx - gateW / 2 - openAmount - 2, cy - gateH / 2)
          ..quadraticBezierTo(
            cx,
            cy - gateH / 2 - 15 * pulse,
            cx + gateW / 2 + openAmount + 2,
            cy - gateH / 2,
          );

    canvas.drawPath(
      archPath,
      Paint()
        ..color = _gateColor.withValues(alpha: gateAlpha * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Door handles — small circles
    canvas.drawCircle(
      Offset(cx - 2 - openAmount, cy),
      1.5,
      Paint()..color = _gateColor.withValues(alpha: gateAlpha * 0.6),
    );
    canvas.drawCircle(
      Offset(cx + 2 + openAmount, cy),
      1.5,
      Paint()..color = _gateColor.withValues(alpha: gateAlpha * 0.6),
    );

    // Garden light flooding through on completion
    if (isComplete) {
      final floodAlpha = 0.15 * pulse;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: openAmount * 2 + 8,
          height: gateH,
        ),
        Paint()
          ..shader = RadialGradient(
            colors: [
              _gateColor.withValues(alpha: floodAlpha),
              _handColor.withValues(alpha: floodAlpha * 0.5),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: gateH * 0.6),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_GuidingHandPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.glowPhase != glowPhase;
}

// =============================================================================
// 🛡️ Invincible Name (الاسم الحصين) — Nothing can harm by Allah's Name
// =============================================================================
// =============================================================================
// 🦂 Protected from All Evil — Scorpion & Threats repelled by Allah's name
// morning_23 / evening_23 — "Nothing shall harm you by perfect words"
// =============================================================================
class _InvincibleName extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _InvincibleName({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_InvincibleName> createState() => _InvincibleNameState();
}

class _InvincibleNameState extends State<_InvincibleName>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl,
      _growCtrl,
      _starCtrl,
      _threatCtrl,
      _shieldCtrl;
  late Animation<double> _pulse, _grow, _threat, _shield;
  double _prevProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.94,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Threats creep toward man (loop, slow)
    _threatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _threat = CurvedAnimation(parent: _threatCtrl, curve: Curves.easeInOut);

    // Shield pulse glow
    _shieldCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _shield = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _shieldCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_InvincibleName old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _threatCtrl.dispose();
    _shieldCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _threatCtrl,
        _shieldCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 260,
            child: CustomPaint(
              painter: _InvincibleNamePainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                threatPhase: _threat.value,
                shieldGlow: _shield.value,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
              ),
            ),
          ),
    );
  }
}

class _InvincibleNamePainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double threatPhase;
  final double shieldGlow;
  final bool isComplete;
  final int pointsToday;

  const _InvincibleNamePainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.threatPhase,
    required this.shieldGlow,
    required this.isComplete,
    this.pointsToday = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Background: deep night sky ──
    final bgPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF0D1B2A), const Color(0xFF1A2A3E)],
          ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // ── Subtle ground line ──
    final groundY = h * 0.78;
    canvas.drawLine(
      Offset(0, groundY),
      Offset(w, groundY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1.0,
    );

    // ── Background stars ──
    _drawStars(canvas, w, h);

    // ── Man in center ──
    final manX = w * 0.50;
    final manY = groundY - 2;
    _drawMan(canvas, manX, manY);

    // ── Shield around man ──
    _drawShield(canvas, manX, manY - 22);

    // ── Scorpion approaching from the left ──
    _drawScorpion(canvas, manX, manY, w, h, groundY);

    // ── Eye threat from top-right ──
    _drawEvilEye(canvas, w, h);

    // ── Snake approaching from bottom-right ──
    _drawSnake(canvas, manX, groundY, w);

    // ── Repelled sparks when progress > 0 ──
    if (progress > 0.1) {
      _drawRepelledSparks(canvas, manX, manY - 22, w);
    }

    // ── Completion: full bright shield ──
    if (isComplete) {
      _drawCompletionGlow(canvas, manX, manY - 22);
    }
  }

  void _drawStars(Canvas canvas, double w, double h) {
    const positions = [
      (0.08, 0.08),
      (0.18, 0.04),
      (0.32, 0.10),
      (0.55, 0.05),
      (0.70, 0.12),
      (0.85, 0.06),
      (0.92, 0.15),
      (0.42, 0.16),
      (0.62, 0.20),
      (0.15, 0.18),
    ];
    for (int i = 0; i < positions.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      final a = (0.15 + 0.35 * tw).clamp(0.0, 0.6);
      canvas.drawCircle(
        Offset(positions[i].$1 * w, positions[i].$2 * h),
        0.8 + tw * 0.7,
        Paint()..color = Colors.white.withValues(alpha: a),
      );
    }
  }

  /// Simple stick-figure man
  void _drawMan(Canvas canvas, double cx, double baseY) {
    final skin = const Color(0xFFD4A574);
    final robe = Colors.white.withValues(alpha: 0.90);
    final p = Paint()..color = skin;

    // Head
    canvas.drawCircle(Offset(cx, baseY - 42), 8.0, p);

    // Body (robe — filled rounded rect)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, baseY - 22), width: 14, height: 22),
        const Radius.circular(4),
      ),
      Paint()..color = robe,
    );

    // Arms out slightly
    canvas.drawLine(
      Offset(cx - 7, baseY - 28),
      Offset(cx - 14, baseY - 20),
      Paint()
        ..color = skin
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(cx + 7, baseY - 28),
      Offset(cx + 14, baseY - 20),
      Paint()
        ..color = skin
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Legs
    canvas.drawLine(
      Offset(cx - 3, baseY - 11),
      Offset(cx - 5, baseY),
      Paint()
        ..color = robe
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(cx + 3, baseY - 11),
      Offset(cx + 5, baseY),
      Paint()
        ..color = robe
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Dome shield around the man
  void _drawShield(Canvas canvas, double cx, double cy) {
    final shieldR = 36.0 + 4.0 * (pulse - 1.0);
    final shieldProgress = progress.clamp(0.0, 1.0);
    final shieldAlpha = (0.12 + shieldProgress * 0.22) * shieldGlow;

    // Outer glow ring
    canvas.drawCircle(
      Offset(cx, cy),
      shieldR + 8,
      Paint()
        ..color = const Color(0xFF60A5FA).withValues(alpha: shieldAlpha * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Shield dome fill
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: shieldR * 2,
        height: shieldR * 2,
      ),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: shieldAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Bottom flat line of dome
    canvas.drawLine(
      Offset(cx - shieldR, cy),
      Offset(cx + shieldR, cy),
      Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: shieldAlpha * 0.7)
        ..strokeWidth = 1.5,
    );

    // Inner fill (subtle)
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: shieldR * 2,
        height: shieldR * 2,
      ),
      math.pi,
      math.pi,
      true,
      Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: shieldAlpha * 0.08),
    );

    // Cross-hatch lines (shield texture — 2 arcs)
    if (shieldProgress > 0.3) {
      final lineA = (shieldProgress - 0.3) / 0.7 * shieldAlpha * 0.4;
      for (final dx in [-shieldR * 0.4, 0.0, shieldR * 0.4]) {
        canvas.drawLine(
          Offset(cx + dx, cy),
          Offset(cx + dx, cy - shieldR * 0.9),
          Paint()
            ..color = const Color(0xFF3B82F6).withValues(alpha: lineA)
            ..strokeWidth = 0.8,
        );
      }
    }
  }

  /// Scorpion approaching from the left
  void _drawScorpion(
    Canvas canvas,
    double manX,
    double manY,
    double w,
    double h,
    double groundY,
  ) {
    // Scorpion position: starts off-screen left, approaches but stops at shield edge
    final shieldEdge = manX - 38.0;
    final startX = manX - w * 0.48;
    // Oscillates: creeps forward with threatPhase, but never reaches shield
    final rawX =
        startX + (shieldEdge - startX - 20) * (0.4 + 0.6 * threatPhase);
    final scX = rawX; // scorpion center X
    final scY = groundY - 6;

    final c = const Color(0xFFE74C3C); // red scorpion

    // ── Body (elongated oval) ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(scX, scY), width: 20, height: 10),
      Paint()..color = c.withValues(alpha: 0.90),
    );

    // ── Head ──
    canvas.drawCircle(
      Offset(scX + 11, scY),
      5.0,
      Paint()..color = c.withValues(alpha: 0.85),
    );

    // ── Pincers (two lines from head) ──
    canvas.drawLine(
      Offset(scX + 14, scY - 2),
      Offset(scX + 20, scY - 6),
      Paint()
        ..color = c.withValues(alpha: 0.80)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(scX + 14, scY + 2),
      Offset(scX + 20, scY + 4),
      Paint()
        ..color = c.withValues(alpha: 0.80)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // ── 6 legs (3 each side) ──
    for (int i = 0; i < 3; i++) {
      final lx = scX - 6.0 + i * 5.0;
      canvas.drawLine(
        Offset(lx, scY - 4),
        Offset(lx - 3, scY - 11),
        Paint()
          ..color = c.withValues(alpha: 0.65)
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(lx, scY + 4),
        Offset(lx - 3, scY + 11),
        Paint()
          ..color = c.withValues(alpha: 0.65)
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── Tail curving upward with stinger ──
    final tailPath =
        Path()
          ..moveTo(scX - 8, scY)
          ..quadraticBezierTo(scX - 18, scY - 16, scX - 14, scY - 24);
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = c.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    // Stinger tip
    canvas.drawCircle(
      Offset(scX - 14, scY - 26),
      3.5,
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.95),
    );

    // Label
    _drawLabel(
      canvas,
      'scorpion',
      Offset(scX - 10, scY + 16),
      c.withValues(alpha: 0.55),
    );
  }

  /// Evil eye threat from top-right
  void _drawEvilEye(Canvas canvas, double w, double h) {
    final eyeX = w * 0.80;
    final eyeY = h * 0.24 + math.sin(threatPhase * math.pi) * 8;
    final c = const Color(0xFF8B5CF6); // purple

    // Eye white
    canvas.drawOval(
      Rect.fromCenter(center: Offset(eyeX, eyeY), width: 28, height: 14),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    // Iris
    canvas.drawCircle(
      Offset(eyeX, eyeY),
      5.5,
      Paint()..color = c.withValues(alpha: 0.75),
    );
    // Pupil
    canvas.drawCircle(
      Offset(eyeX, eyeY),
      2.5,
      Paint()..color = Colors.black.withValues(alpha: 0.60),
    );
    // Angry brow
    canvas.drawLine(
      Offset(eyeX - 12, eyeY - 10),
      Offset(eyeX + 12, eyeY - 8),
      Paint()
        ..color = c.withValues(alpha: 0.55)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
    // Glow
    canvas.drawCircle(
      Offset(eyeX, eyeY),
      18,
      Paint()
        ..color = c.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    _drawLabel(
      canvas,
      'evil eye',
      Offset(eyeX - 14, eyeY + 12),
      c.withValues(alpha: 0.50),
    );
  }

  /// Snake creeping from bottom-right
  void _drawSnake(Canvas canvas, double manX, double groundY, double w) {
    final shieldEdge = manX + 40.0;
    final startX = manX + w * 0.42;
    final snakeX =
        startX - (startX - shieldEdge - 18) * (0.35 + 0.65 * threatPhase);
    final snakeY = groundY - 4;
    final c = const Color(0xFFFFC83D); // green snake

    // Snake body — S-curve path
    final bodyPath =
        Path()
          ..moveTo(snakeX + 22, snakeY)
          ..cubicTo(
            snakeX + 10,
            snakeY - 14,
            snakeX - 5,
            snakeY + 10,
            snakeX,
            snakeY,
          );
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = c.withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round,
    );
    // Head
    canvas.drawOval(
      Rect.fromCenter(center: Offset(snakeX - 2, snakeY), width: 12, height: 8),
      Paint()..color = c.withValues(alpha: 0.90),
    );
    // Eye
    canvas.drawCircle(
      Offset(snakeX - 6, snakeY - 2),
      1.5,
      Paint()..color = Colors.red.withValues(alpha: 0.80),
    );
    // Forked tongue
    canvas.drawLine(
      Offset(snakeX - 9, snakeY),
      Offset(snakeX - 14, snakeY - 3),
      Paint()
        ..color = Colors.red.withValues(alpha: 0.75)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(snakeX - 9, snakeY),
      Offset(snakeX - 14, snakeY + 3),
      Paint()
        ..color = Colors.red.withValues(alpha: 0.75)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    _drawLabel(
      canvas,
      'snake',
      Offset(snakeX - 6, snakeY + 12),
      c.withValues(alpha: 0.50),
    );
  }

  /// Small impact sparks at shield edge when threats approach
  void _drawRepelledSparks(Canvas canvas, double cx, double cy, double w) {
    // Left side (scorpion side)
    final leftEdge = cx - 38.0;
    for (int i = 0; i < 4; i++) {
      final angle = math.pi + (i - 1.5) * 0.35;
      final dist = 40.0 + 4 * math.sin(starPhase * math.pi * 3 + i * 1.1);
      final sx = cx + math.cos(angle) * dist;
      final sy = cy + math.sin(angle) * dist;
      final sparkProgress =
          (0.5 + 0.5 * math.sin(starPhase * math.pi * 4 + i * 0.8));
      canvas.drawCircle(
        Offset(sx, sy),
        1.8 + sparkProgress,
        Paint()
          ..color = const Color(
            0xFF60A5FA,
          ).withValues(alpha: sparkProgress * progress * 0.65),
      );
    }

    // Right side (snake side)
    for (int i = 0; i < 3; i++) {
      final angle = (i - 1.0) * 0.4;
      final dist = 40.0 + 3 * math.sin(starPhase * math.pi * 2 + i * 1.3);
      final sx = cx + math.cos(angle) * dist;
      final sy = cy + math.sin(angle) * dist;
      final sparkProgress =
          (0.5 + 0.5 * math.sin(starPhase * math.pi * 3 + i * 1.2));
      canvas.drawCircle(
        Offset(sx, sy),
        1.5 + sparkProgress,
        Paint()
          ..color = const Color(
            0xFF60A5FA,
          ).withValues(alpha: sparkProgress * progress * 0.55),
      );
    }
  }

  void _drawCompletionGlow(Canvas canvas, double cx, double cy) {
    canvas.drawCircle(
      Offset(cx, cy),
      55,
      Paint()
        ..color = const Color(0xFF60A5FA).withValues(alpha: 0.18 * shieldGlow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(_InvincibleNamePainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.threatPhase != threatPhase ||
      o.shieldGlow != shieldGlow ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday;
}

// =============================================================================
// 🌊 Ocean of Forgiveness (بحر المغفرة) — Sins forgiven like foam of the sea
// =============================================================================
class _OceanOfForgiveness extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _OceanOfForgiveness({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_OceanOfForgiveness> createState() => _OceanOfForgivenessState();
}

class _OceanOfForgivenessState extends State<_OceanOfForgiveness>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _growCtrl;
  late Animation<double> _grow;
  double _prevProgress = 0.0;
  late AnimationController _starCtrl;
  late AnimationController _pCtrl;
  late Animation<double> _pAnim;
  int _prevTap = 0;
  late AnimationController _punchCtrl;
  late Animation<double> _punch;
  late AnimationController _shockCtrl;
  late Animation<double> _shock;
  late AnimationController _waveCtrl;

  final List<_Particle> _particles = List.generate(
    18,
    (i) => _Particle(seed: i + 1900),
  );

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
  }

  @override
  void didUpdateWidget(_OceanOfForgiveness old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _waveCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _OceanOfForgivenessPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                wavePhase: _waveCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _OceanOfForgivenessPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double wavePhase;

  static const _oceanColor = Color(0xFF0EA5E9); // sky blue — ocean
  static const _foamColor = Color(0xFFB0B8C8); // darker blue-grey — foam (sins)
  static const _clearColor = Color(0xFF06B6D4); // cyan — purified water

  const _OceanOfForgivenessPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.wavePhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.44;

    // 1. Background — deep ocean dark
    final depth = progress * 0.10;
    _paintLightBg(canvas, w, h, progress: progress);

    // 2. Stars (above ocean horizon)
    const starPos = [
      (0.10, 0.06),
      (0.25, 0.10),
      (0.42, 0.04),
      (0.58, 0.08),
      (0.74, 0.05),
      (0.88, 0.11),
      (0.34, 0.14),
      (0.66, 0.12),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      final starAlpha = (0.15 + 0.35 * tw).clamp(0.0, 0.5);
      sp.color = Colors.white.withValues(alpha: starAlpha);
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h),
        0.7 + tw * 0.8,
        sp,
      );
    }

    // Apply punch scale
    canvas.save();
    // punch scale removed — smooth calm tap

    // 3. Ocean waves
    _drawOcean(canvas, cx, cy, w, h);

    // 4. Foam particles (sins) dissolving into light
    _drawFoam(canvas, cx, cy, w, h);

    // 5. Central radiance (SubhanAllah core)
    _drawCore(canvas, cx, cy - 15);

    canvas.restore();

    // 6. Shockwave on tap
    // tap-effect removed — smooth calm

    // 7. Tap particles — rising from ocean
    // tap-effect removed — smooth calm

    // 8. Progress label
    // progress % label removed

    // 9. Points badge
  }

  /// Ocean waves — multiple sine layers with depth
  void _drawOcean(Canvas canvas, double cx, double cy, double w, double h) {
    final horizonY = cy + 10;

    // 3 wave layers at different depths
    for (int layer = 0; layer < 3; layer++) {
      final layerY = horizonY + layer * 18;
      final amplitude = 5.0 + layer * 2;
      final frequency = 2.0 + layer * 0.5;
      final phaseShift = wavePhase * math.pi * 2 + layer * 1.2;
      final layerAlpha = (0.12 + layer * 0.06) * (1.0 + progress * 0.3);

      // Water color transitions from murky to crystal clear with progress
      final waterColor =
          Color.lerp(
            _oceanColor.withValues(alpha: layerAlpha),
            _clearColor.withValues(alpha: layerAlpha * 1.3),
            progress,
          )!;

      final wavePath = Path()..moveTo(0, layerY);
      for (double x = 0; x <= w; x += 3) {
        final y =
            layerY +
            math.sin(x / w * math.pi * frequency + phaseShift) * amplitude;
        wavePath.lineTo(x, y);
      }
      wavePath.lineTo(w, h);
      wavePath.lineTo(0, h);
      wavePath.close();

      canvas.drawPath(wavePath, Paint()..color = waterColor);
    }

    // Wave crest highlights
    for (int c = 0; c < 5; c++) {
      final crestX = (wavePhase + c * 0.2) % 1.0 * w;
      final crestY = horizonY + math.sin(wavePhase * math.pi * 2 + c * 1.8) * 5;
      final crestAlpha = 0.15 * pulse;
      canvas.drawCircle(
        Offset(crestX, crestY),
        2,
        Paint()
          ..color = Colors.white.withValues(alpha: crestAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  /// Foam particles representing sins — only fully dissolve at 100% completion
  void _drawFoam(Canvas canvas, double cx, double cy, double w, double h) {
    final horizonY = cy + 10;
    final foamCount = 25;
    // Foam stays mostly intact until near completion:
    // 0-80% progress → all 25 foam blobs remain
    // 80-100% progress → foam starts dissolving
    // 100% → all foam gone
    final dissolveProgress = ((progress - 0.8) / 0.2).clamp(0.0, 1.0);
    final remainingFoam = ((1.0 - dissolveProgress) * foamCount).round();

    for (int i = 0; i < foamCount; i++) {
      final rng = math.Random(i * 997);
      final fx = w * 0.08 + rng.nextDouble() * w * 0.84;
      final baseY = horizonY + rng.nextDouble() * 45 + 5;
      final blobSize = 3.0 + rng.nextDouble() * 4.0;

      if (i >= remainingFoam) {
        // Foam dissolved — rises as white light (sin forgiven)
        final riseT = ((dissolveProgress - i / foamCount) * foamCount).clamp(0.0, 1.0);
        if (riseT < 0.01 || riseT > 0.95) continue;

        final riseY = baseY - riseT * 60;
        final riseAlpha = (1.0 - riseT) * 0.55;
        final shrink = blobSize * (1.0 - riseT * 0.7);
        // White sparkle rising
        canvas.drawCircle(
          Offset(fx, riseY),
          shrink + 3,
          Paint()
            ..color = Colors.white.withValues(alpha: riseAlpha * 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(fx, riseY),
          shrink,
          Paint()..color = Colors.white.withValues(alpha: riseAlpha),
        );
      } else {
        // Foam still on water — dark blobs (sins) bobbing
        final bobY = baseY + math.sin(wavePhase * math.pi * 2 + i * 0.8) * 4;
        final bobX = fx + math.sin(wavePhase * math.pi * 2 + i * 1.5) * 3;
        final foamAlpha =
            0.72 + math.sin(wavePhase * math.pi * 2 + i * 1.3) * 0.08;

        // Dark smudge (sin)
        canvas.drawCircle(
          Offset(bobX, bobY),
          blobSize + 2,
          Paint()
            ..color = const Color(
              0xFF2D3748,
            ).withValues(alpha: foamAlpha * 0.55)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawCircle(
          Offset(bobX, bobY),
          blobSize,
          Paint()..color = _foamColor.withValues(alpha: foamAlpha),
        );
        // White foam highlight on top
        canvas.drawCircle(
          Offset(bobX - 1, bobY - 1),
          blobSize * 0.35,
          Paint()..color = Colors.white.withValues(alpha: foamAlpha * 0.4),
        );
      }
    }
  }

  /// Central SubhanAllah radiance above the ocean
  void _drawCore(Canvas canvas, double cx, double cy) {
    final coreAlpha = 0.15 + progress * 0.45;

    // Reflection on water below
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + 50),
        width: 30 + progress * 20,
        height: 6,
      ),
      Paint()
        ..color = _clearColor.withValues(alpha: coreAlpha * 0.10 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // On completion — expanded purity aura
    if (isComplete) {
      for (int i = 0; i < 3; i++) {
        final auraR = 15.0 + i * 12;
        final auraA = (0.08 - i * 0.02) * pulse;
        canvas.drawCircle(
          Offset(cx, cy),
          auraR,
          Paint()
            ..color = _clearColor.withValues(alpha: auraA)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0 + i * 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_OceanOfForgivenessPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.wavePhase != wavePhase;
}

// =============================================================================
// ⚖️ Unparalleled Scales (ميزان لا يُضاهى) — 10 slaves, 100 hasanat, shield
// =============================================================================
// Freed Slaves Illustration — La ilaha illallah 100x
// =============================================================================
class _UnparalleledScales extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _UnparalleledScales({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });

  @override
  State<_UnparalleledScales> createState() => _UnparalleledScalesState();
}

class _UnparalleledScalesState extends State<_UnparalleledScales>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _growCtrl;
  late Animation<double> _grow;
  double _prevProgress = 0.0;
  late AnimationController _starCtrl;
  late AnimationController _pCtrl;
  late Animation<double> _pAnim;
  int _prevTap = 0;
  late AnimationController _punchCtrl;
  late Animation<double> _punch;
  late AnimationController _shockCtrl;
  late Animation<double> _shock;
  late AnimationController _rainCtrl;

  final List<_Particle> _particles = List.generate(
    16,
    (i) => _Particle(seed: i + 2000),
  );

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat(reverse: true);

    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _rainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void didUpdateWidget(_UnparalleledScales old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _rainCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _rainCtrl,
      ]),
      builder: (_, __) {
        final taps = widget.tapCount;
        // Rewards scale proportionally: reach max only at 100 taps (full completion)
        final hasanaat = (taps * 100 ~/ 100).clamp(0, 100);   // +1 per tap, max 100
        final sinsRemoved = (taps * 100 ~/ 100).clamp(0, 100); // +1 per tap, max 100
        final slavesFreed = (taps * 10 ~/ 100).clamp(0, 10);   // +1 per 10 taps, max 10

        return SizedBox(
          height: 290,
          child: Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ScalesBigCounter(
                    icon: Icons.auto_awesome_rounded,
                    value: hasanaat,
                    maxValue: 100,
                    label: 'Hasanaat',
                    prefix: '+',
                    color: const Color(0xFFD4AF37),
                  ),
                  const SizedBox(height: 20),
                  _ScalesBigCounter(
                    icon: Icons.water_drop_outlined,
                    value: sinsRemoved,
                    maxValue: 100,
                    label: 'Sins Washed Away',
                    prefix: '-',
                    color: const Color(0xFF2BAE99),
                  ),
                  const SizedBox(height: 20),
                  _ScalesBigCounter(
                    icon: Icons.diversity_1_rounded,
                    value: slavesFreed,
                    maxValue: 10,
                    label: 'Slaves Freed',
                    prefix: '',
                    color: const Color(0xFF9B59B6),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScalesBigCounter extends StatelessWidget {
  final IconData icon;
  final int value;
  final int maxValue;
  final String label;
  final String prefix;
  final Color color;

  const _ScalesBigCounter({
    required this.icon,
    required this.value,
    required this.maxValue,
    required this.label,
    required this.prefix,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, maxValue);
    return SizedBox(
      width: 180,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$prefix$clamped',
                  style: GoogleFonts.rajdhani(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.0,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Y4.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnparalleledScalesPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double rainPhase;

  const _UnparalleledScalesPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.rainPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Desert sky gradient — warm amber top to hazy cream horizon ──
    final skyPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.40, 0.72, 1.0],
            colors: const [
              Color(0xFFB45309), // deep amber at top
              Color(0xFFD97706), // golden mid-sky
              Color(0xFFFDE68A), // pale yellow near horizon
              Color(0xFFFFF8E7), // hazy cream at ground level
            ],
          ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // ── Distant sun glow (upper-right) ──
    canvas.drawCircle(
      Offset(w * 0.82, h * 0.20),
      24,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    canvas.drawCircle(
      Offset(w * 0.82, h * 0.20),
      10,
      Paint()..color = Colors.white.withValues(alpha: 0.60),
    );

    // ── Sandy dune at bottom ──
    final groundY = h * 0.75;
    final dunePath =
        Path()
          ..moveTo(0, groundY + 5)
          ..quadraticBezierTo(w * 0.20, groundY - 12, w * 0.38, groundY + 3)
          ..quadraticBezierTo(w * 0.58, groundY + 16, w * 0.74, groundY + 4)
          ..quadraticBezierTo(w * 0.90, groundY - 9, w, groundY + 7)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();
    canvas.drawPath(
      dunePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFD4922A), Color(0xFFA8711A)],
        ).createShader(Rect.fromLTWH(0, groundY - 12, w, h - groundY + 12)),
    );

    // ── Heat shimmer (subtle shimmer dots above dune) ──
    for (int i = 0; i < 7; i++) {
      final sx = w * (0.08 + i * 0.13);
      final sy = groundY - 5 + math.sin(starPhase * math.pi * 2 + i * 1.2) * 5;
      final sa = (0.05 + 0.07 * math.sin(starPhase * math.pi * 3 + i).abs());
      canvas.drawCircle(
        Offset(sx, sy),
        1.8,
        Paint()..color = Colors.white.withValues(alpha: sa),
      );
    }

    // Main cage scene
    _drawCage(canvas, w, h);
  }

  void _drawCage(Canvas canvas, double w, double h) {
    // Cage nudged left so freed figures have room on the right
    final cx = w * 0.35;
    final cy = h * 0.63; // grounded on desert surface

    const cageW = 114.0; // wider cage to fit 4 figures comfortably
    const cageH = 92.0;
    final topY = cy - cageH / 2;
    final botY = cy + cageH / 2;
    final leftX = cx - cageW / 2;
    final rightX = cx + cageW / 2;

    // Door swings open rightward as progress increases (starts opening at 40%)
    final doorOpen = ((progress - 0.35) / 0.65).clamp(0.0, 1.0);
    final doorAngle = doorOpen * math.pi * 0.48; // ~86 degrees max

    final cagePaint =
        Paint()
          ..color = const Color(0xFF6B7280).withValues(alpha: 0.82)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

    // Top arc (dome of birdcage)
    final arcRect = Rect.fromLTRB(leftX, topY - 10, rightX, topY + 50);
    canvas.drawArc(arcRect, math.pi, math.pi, false, cagePaint);

    // Bottom floor
    canvas.drawLine(Offset(leftX, botY), Offset(rightX, botY), cagePaint);

    // Left wall    // Left wall (solid)
    canvas.drawLine(Offset(leftX, topY + 22), Offset(leftX, botY), cagePaint);

    // Vertical bars inside cage (skip left/right walls, skip rightmost for door)
    const numBars = 7;
    for (int i = 1; i < numBars - 1; i++) {
      final bx = leftX + cageW * i / (numBars - 1);
      if (bx >= rightX - 4) continue; // leave room for door
      canvas.drawLine(
        Offset(bx, topY + 22),
        Offset(bx, botY),
        Paint()
          ..color = const Color(0xFF6B7280).withValues(alpha: 0.38)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );
    }

    // Horizontal ring mid-cage
    canvas.drawLine(
      Offset(leftX, cy + 2),
      Offset(rightX - 2, cy + 2),
      Paint()
        ..color = const Color(0xFF6B7280).withValues(alpha: 0.25)
        ..strokeWidth = 1.1,
    );

    // Door on right side — amber, swings outward rightward
    final doorHingeX = rightX;
    final doorHingeY = topY + 24;
    final doorLen = botY - doorHingeY - 2;

    canvas.save();
    canvas.translate(doorHingeX, doorHingeY);
    canvas.rotate(-doorAngle);
    canvas.drawLine(
      Offset.zero,
      Offset(0, doorLen),
      Paint()
        ..color = const Color(0xFFD97706).withValues(alpha: 0.90)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
    // Door handle
    canvas.drawCircle(
      Offset(5, doorLen * 0.5),
      2.5,
      Paint()..color = const Color(0xFFD97706).withValues(alpha: 0.75),
    );
    canvas.restore();

    // ── All figures green ──
    const green = Color(0xFFFFC83D);

    // ── 6 positions in a 2-column x 3-row grid inside cage ──
    final col0 = cx - 20.0; // left column
    final col1 = cx + 12.0; // right column
    final row0 = cy - 22.0; // top row
    final row1 = cy - 2.0; // middle row
    final row2 = cy + 18.0; // bottom row

    // ── Figures 0,1,2 always remain inside ──
    _drawPrisoner(canvas, Offset(col0, row0), green, starPhase, idx: 0);
    _drawPrisoner(canvas, Offset(col1, row0), green, starPhase, idx: 1);
    _drawPrisoner(canvas, Offset(col0, row1), green, starPhase, idx: 2);

    // ── Figure 3 exits at progress >= 0.33 ──
    if (progress < 0.33) {
      _drawPrisoner(canvas, Offset(col1, row1), green, starPhase, idx: 3);
    } else {
      final sp3 = ((progress - 0.33) / 0.67).clamp(0.0, 1.0);
      _drawFreeingFigure(
        canvas,
        sp: sp3,
        color: green,
        startX: rightX + 6,
        startY: row1,
        targetX: w * 0.78,
        targetY: cy - 18,
        pulse: pulse,
      );
    }

    // ── Figure 4 exits at progress >= 0.66 ──
    if (progress < 0.66) {
      _drawPrisoner(canvas, Offset(col0, row2), green, starPhase, idx: 4);
    } else {
      final sp4 = ((progress - 0.66) / 0.34).clamp(0.0, 1.0);
      _drawFreeingFigure(
        canvas,
        sp: sp4,
        color: green,
        startX: rightX + 6,
        startY: row2,
        targetX: w * 0.84,
        targetY: cy - 4,
        pulse: pulse,
      );
    }

    // ── Figure 5 exits at completion ──
    if (!isComplete) {
      _drawPrisoner(canvas, Offset(col1, row2), green, starPhase, idx: 5);
    } else {
      _drawFreeingFigure(
        canvas,
        sp: 1.0,
        color: green,
        startX: rightX + 6,
        startY: row2,
        targetX: w * 0.90,
        targetY: cy + 8,
        pulse: pulse,
      );
    }
  }

  void _drawPrisoner(
    Canvas canvas,
    Offset pos,
    Color color,
    double starPhase, {
    required int idx,
  }) {
    final a = 0.72 + 0.18 * math.sin(starPhase * math.pi * 2 + idx * 1.2).abs();
    // Head
    canvas.drawCircle(
      Offset(pos.dx, pos.dy - 7),
      4.5,
      Paint()..color = color.withValues(alpha: a),
    );
    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pos.dx, pos.dy + 3),
          width: 7,
          height: 11,
        ),
        const Radius.circular(2.5),
      ),
      Paint()..color = color.withValues(alpha: a * 0.80),
    );
    // Chains at ankles
    canvas.drawLine(
      Offset(pos.dx - 5, pos.dy + 8),
      Offset(pos.dx + 5, pos.dy + 8),
      Paint()
        ..color = const Color(0xFF6B7280).withValues(alpha: 0.70)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawFreeingFigure(
    Canvas canvas, {
    required double sp,
    required Color color,
    required double startX,
    required double startY,
    required double targetX,
    required double targetY,
    required double pulse,
  }) {
    final posX = startX + (targetX - startX) * sp;
    final posY =
        startY + (targetY - startY) * sp + math.sin(sp * math.pi) * -14;
    final alpha = (0.80 + 0.20 * pulse).clamp(0.0, 1.0);

    // Freedom glow
    canvas.drawCircle(
      Offset(posX, posY),
      18,
      Paint()
        ..color = color.withValues(alpha: sp * 0.11)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Head
    canvas.drawCircle(
      Offset(posX, posY - 9),
      5.0,
      Paint()..color = color.withValues(alpha: alpha),
    );
    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(posX, posY + 3), width: 8, height: 13),
        const Radius.circular(3),
      ),
      Paint()..color = color.withValues(alpha: alpha * 0.80),
    );
    // Arms in walking/raised gesture
    final armSwing = math.sin(sp * math.pi * 5) * 5;
    canvas.drawLine(
      Offset(posX - 4, posY - 1),
      Offset(posX - 9, posY - 7 + armSwing),
      Paint()
        ..color = color.withValues(alpha: alpha * 0.72)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(posX + 4, posY - 1),
      Offset(posX + 9, posY - 7 - armSwing),
      Paint()
        ..color = color.withValues(alpha: alpha * 0.72)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // Broken chain flash just after exit
    if (sp < 0.28) {
      final breakA = (1.0 - sp / 0.28) * 0.80;
      canvas.drawLine(
        Offset(posX - 7, posY + 8),
        Offset(posX - 2, posY + 6),
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: breakA)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(posX + 2, posY + 6),
        Offset(posX + 7, posY + 8),
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: breakA)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos,
    Color color,
    double size,
    FontWeight weight,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(_UnparalleledScalesPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.rainPhase != rainPhase;
}

// =============================================================================
// ☀️ Sunrise Glory (مجد الشروق) — Tasbih, Tahmid, Takbir
// =============================================================================
class _SunriseGlory extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _SunriseGlory({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_SunriseGlory> createState() => _SunriseGloryState();
}

class _SunriseGloryState extends State<_SunriseGlory>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl,
      _growCtrl,
      _starCtrl,
      _pCtrl,
      _punchCtrl,
      _shockCtrl,
      _rayCtrl;
  late Animation<double> _pulse, _grow, _pAnim, _punch, _shock;
  double _prevProgress = 0.0;
  int _prevTap = 0;
  final List<_Particle> _particles = List.generate(
    16,
    (i) => _Particle(seed: i + 2100),
  );

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _rayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void didUpdateWidget(_SunriseGlory old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _rayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _rayCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _SunriseGloryPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                rayPhase: _rayCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _SunriseGloryPainter extends CustomPainter {
  final double progress,
      pulse,
      starPhase,
      particlePhase,
      punchScale,
      shockPhase,
      rayPhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;

  static const _ringColors = [
    Color(0xFFF59E0B),
    Color(0xFFFFC83D),
    Color(0xFFEF4444),
  ]; // SubhanAllah amber, Alhamdulillah emerald, Allahu Akbar ruby
  static const _ringLabels = ['سُبْحَان الله', 'الحَمْدُ لله', 'الله أَكْبَر'];

  const _SunriseGloryPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.rayPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w / 2, cy = h * 0.42;

    // Background — warm dawn
    final warmth = progress * 0.18;
    _paintLightBg(canvas, w, h, progress: progress);

    // Stars fade as sun rises
    const starPos = [
      (0.10, 0.06),
      (0.25, 0.14),
      (0.42, 0.05),
      (0.58, 0.10),
      (0.74, 0.07),
      (0.88, 0.13),
      (0.35, 0.20),
      (0.65, 0.18),
    ];
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      final a = ((1.0 - progress * 0.8) * 0.35 * tw).clamp(0.0, 0.5);
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h),
        0.7 + tw * 0.8,
        Paint()..color = Colors.white.withValues(alpha: a),
      );
    }

    // Horizon line
    final horizonY = cy + 30;
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(w, horizonY),
      Paint()
        ..color = const Color(
          0xFFF59E0B,
        ).withValues(alpha: 0.08 + progress * 0.12)
        ..strokeWidth = 1.0,
    );

    // punch scale removed — smooth calm tap

    // Sun — grows and brightens with progress (stays in safe zone)
    final sunR = 14 + progress * 18;
    final sunY = cy + 2 - progress * 8; // gentle rise, stays well within bounds

    // Sun glow
    canvas.drawCircle(
      Offset(cx, sunY),
      sunR + 15,
      Paint()
        ..color = const Color(0xFFF59E0B).withValues(alpha: 0.08 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Sun body
    canvas.drawCircle(
      Offset(cx, sunY),
      sunR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.70),
            const Color(0xFFF59E0B).withValues(alpha: 0.50),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, sunY), radius: sunR)),
    );

    // 3 concentric rings — SubhanAllah, Alhamdulillah, Allahu Akbar
    for (int i = 0; i < 3; i++) {
      final ringProgress = ((progress - i / 3.0) * 3.0).clamp(0.0, 1.0);
      if (ringProgress < 0.01) continue;
      final ringR = (sunR + 10 + i * 14) * ringProgress; // tighter rings
      final ringAlpha = (0.15 + ringProgress * 0.25) * pulse;
      final color = _ringColors[i];

      canvas.drawCircle(
        Offset(cx, sunY),
        ringR,
        Paint()
          ..color = color.withValues(alpha: ringAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // Orbiting dot
      final dotAngle = rayPhase * math.pi * 2 + i * 2.1;
      canvas.drawCircle(
        Offset(
          cx + math.cos(dotAngle) * ringR,
          sunY + math.sin(dotAngle) * ringR,
        ),
        2,
        Paint()..color = color.withValues(alpha: ringAlpha * 2),
      );
    }

    // Labels — positioned below the rings in a horizontal row, not on the rings
    if (progress > 0.3) {
      final labelY = sunY + (sunR + 10 + 2 * 14) + 12; // below outermost ring
      for (int i = 0; i < 3; i++) {
        final ringProgress = ((progress - i / 3.0) * 3.0).clamp(0.0, 1.0);
        if (ringProgress < 0.5) continue;
        final labelAlpha = ((ringProgress - 0.5) * 2).clamp(0.0, 0.6);
        final color = _ringColors[i];
      }
    }

    // Rays below horizon (reflection)
    if (progress > 0.3) {
      final rayAlpha = ((progress - 0.3) / 0.7).clamp(0.0, 1.0) * 0.06;
      for (int r = 0; r < 5; r++) {
        final rayAngle = math.pi * 0.3 + r * math.pi * 0.1;
        final rayLen = 30 + progress * 20;
        canvas.drawLine(
          Offset(cx, horizonY),
          Offset(
            cx + math.cos(rayAngle) * rayLen,
            horizonY + math.sin(rayAngle) * rayLen * 0.5,
          ),
          Paint()
            ..color = const Color(0xFFF59E0B).withValues(alpha: rayAlpha)
            ..strokeWidth = 1.0
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Shockwave
    // tap-effect removed — smooth calm

    // Particles
    // tap-effect removed — smooth calm

    // Label
    // progress % label removed
  }

  @override
  bool shouldRepaint(_SunriseGloryPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.rayPhase != rayPhase;
}

// =============================================================================
// Floral Ornament Painter — decorative flower/leaf motif for text illustrations
// =============================================================================
class _FloralOrnamentPainter extends CustomPainter {
  final Color color;
  final bool isComplete;
  _FloralOrnamentPainter({required this.color, required this.isComplete});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;

    // Draw 6 petals as curved leaf shapes
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final tipX = cx + r * math.cos(angle);
      final tipY = cy + r * math.sin(angle);
      final cp1x = cx + r * 0.7 * math.cos(angle - 0.45);
      final cp1y = cy + r * 0.7 * math.sin(angle - 0.45);
      final cp2x = cx + r * 0.7 * math.cos(angle + 0.45);
      final cp2y = cy + r * 0.7 * math.sin(angle + 0.45);

      final path =
          Path()
            ..moveTo(cx, cy)
            ..quadraticBezierTo(cp1x, cp1y, tipX, tipY)
            ..quadraticBezierTo(cp2x, cp2y, cx, cy);
      canvas.drawPath(path, paint);
    }

    // Center dot or checkmark
    if (isComplete) {
      final checkPaint =
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round;
      final path =
          Path()
            ..moveTo(cx - 5, cy)
            ..lineTo(cx - 1, cy + 4)
            ..lineTo(cx + 6, cy - 4);
      canvas.drawPath(path, checkPaint);
    } else {
      canvas.drawCircle(Offset(cx, cy), 2.5, Paint()..color = color);
    }

    // Outer ring of small dots between petals
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + math.pi / 6;
      final dx = cx + r * 0.65 * math.cos(angle);
      final dy = cy + r * 0.65 * math.sin(angle);
      canvas.drawCircle(
        Offset(dx, dy),
        1.3,
        Paint()..color = color.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FloralOrnamentPainter old) =>
      old.color != color || old.isComplete != isComplete;
}

// =============================================================================
// Text-based Benefit Illustration — shows reward text with animated styling
// =============================================================================
class _BenefitTextIllustration extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  final String benefitText;
  final String? highlightPhrase;
  final String subtitle;
  final String completedSubtitle;
  final Color accentColor;
  const _BenefitTextIllustration({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    required this.pointsToday,
    required this.benefitText,
    this.highlightPhrase,
    this.subtitle = '',
    this.completedSubtitle = '',
    required this.accentColor,
  });
  @override
  State<_BenefitTextIllustration> createState() =>
      _BenefitTextIllustrationState();
}

class _BenefitTextIllustrationState extends State<_BenefitTextIllustration>
    with SingleTickerProviderStateMixin {
  // One-shot completion celebration: drives a soft glow halo and a quick
  // sparkle ring around the text card the moment `isComplete` flips true.
  // Plays once (~900 ms), zero entrance delay — the text itself is always
  // fully visible from frame 1 so users never see a blurred/hidden state.
  late AnimationController _celebrate;

  @override
  void initState() {
    super.initState();
    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      value: widget.isComplete ? 1.0 : 0.0,
    );
    if (widget.isComplete) _celebrate.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _BenefitTextIllustration old) {
    super.didUpdateWidget(old);
    if (!old.isComplete && widget.isComplete) {
      _celebrate.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _celebrate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Illustration banner must always read as a distinct surface from the
    // surrounding page — otherwise the text floats on the cream body with
    // no visual frame and stops feeling like an "illustration zone." Use
    // pure white in light mode (clear contrast against the Akhirah cream
    // Y4.bg body) plus a soft bottom shadow further down to lift it off
    // the page like a deliberate card.
    final bg =
        isDark ? SettingsService.instance.config.dashText : Colors.white;
    final textColor =
        isDark ? Colors.white : SettingsService.instance.config.dashText;
    final accent =
        widget.isComplete ? const Color(0xFFFFC83D) : widget.accentColor;

    return Container(
      decoration: BoxDecoration(color: bg),
      child: Center(
        child: AnimatedBuilder(
          animation: _celebrate,
          builder: (context, _) {
            final glow = Curves.easeOut.transform(_celebrate.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                // Sparkle ring — appears at completion only, fades out fast.
                if (widget.isComplete)
                  IgnorePointer(
                    child: SizedBox(
                      width: 320,
                      height: 220,
                      child: CustomPaint(
                        painter: _SparkleRingPainter(
                          progress: glow,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Decorative top line — pulses honey on completion.
                      Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: widget.isComplete
                              ? [
                                  BoxShadow(
                                    color: accent.withValues(
                                      alpha: 0.55 * (1 - glow),
                                    ),
                                    blurRadius: 14 * (1 - glow * 0.6),
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Floral ornament
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CustomPaint(
                          painter: _FloralOrnamentPainter(
                            color: accent,
                            isComplete: widget.isComplete,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Benefit text — always rendered at full opacity. On
                      // completion, a soft text-shadow glow blooms then
                      // settles, no swap delay.
                      if (widget.isComplete ||
                          widget.highlightPhrase == null ||
                          !widget.benefitText
                              .contains(widget.highlightPhrase!))
                        Text(
                          widget.isComplete
                              ? 'MashaAllah! Reward Secured'
                              : widget.benefitText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lora(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            height: 1.35,
                            letterSpacing: -0.3,
                            shadows: widget.isComplete
                                ? [
                                    Shadow(
                                      color: accent.withValues(
                                        alpha: 0.65 * (1 - glow * 0.7),
                                      ),
                                      blurRadius: 18 * (1 - glow * 0.5),
                                    ),
                                  ]
                                : null,
                          ),
                        )
                      else
                        Builder(builder: (_) {
                          final phrase = widget.highlightPhrase!;
                          final idx = widget.benefitText.indexOf(phrase);
                          final before = widget.benefitText.substring(0, idx);
                          final after =
                              widget.benefitText.substring(idx + phrase.length);
                          final baseStyle = GoogleFonts.lora(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            height: 1.35,
                            letterSpacing: -0.3,
                          );
                          return RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: baseStyle,
                              children: [
                                TextSpan(text: before),
                                TextSpan(
                                  text: phrase,
                                  style: baseStyle.copyWith(
                                    color: accent,
                                    fontSize: 20,
                                  ),
                                ),
                                TextSpan(text: after),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        widget.isComplete
                            ? widget.completedSubtitle
                            : widget.subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Decorative bottom line
                      Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: widget.isComplete
                              ? [
                                  BoxShadow(
                                    color: accent.withValues(
                                      alpha: 0.55 * (1 - glow),
                                    ),
                                    blurRadius: 14 * (1 - glow * 0.6),
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Quick sparkle ring drawn around the benefit text on completion.
// 10 tiny dots expand outward from the center and fade in ~900 ms.
// Painted once per completion — no continuous animation cost.
class _SparkleRingPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  _SparkleRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseR = (size.shortestSide / 2) * 0.55;
    final r = baseR + 32 * progress;
    final alpha = (1 - progress).clamp(0.0, 1.0);
    final paint = Paint()..color = color.withValues(alpha: alpha);
    const count = 10;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * 3.14159;
      final px = cx + r * 1.4 * math.cos(angle);
      final py = cy + r * 0.95 * math.sin(angle);
      final dotR = (3 - 1.5 * progress).clamp(0.5, 3.0);
      canvas.drawCircle(Offset(px, py), dotR.toDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleRingPainter old) =>
      old.progress != progress || old.color != color;
}

// =============================================================================
// Ten Salawat (old CustomPaint version — kept for reference)
// =============================================================================
class _TenSalawat extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _TenSalawat({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_TenSalawat> createState() => _TenSalawatState();
}

class _TenSalawatState extends State<_TenSalawat>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl,
      _growCtrl,
      _starCtrl,
      _pCtrl,
      _punchCtrl,
      _shockCtrl,
      _orbitCtrl;
  late Animation<double> _pulse, _grow, _pAnim, _punch, _shock;
  double _prevProgress = 0.0;
  int _prevTap = 0;
  final List<_Particle> _particles = List.generate(
    16,
    (i) => _Particle(seed: i + 2200),
  );

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat(reverse: true);
    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
  }

  @override
  void didUpdateWidget(_TenSalawat old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _orbitCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _TenSalawatPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                orbitPhase: _orbitCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _TenSalawatPainter extends CustomPainter {
  final double progress,
      pulse,
      starPhase,
      particlePhase,
      punchScale,
      shockPhase,
      orbitPhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  static const _crescentColor = Color(0xFFFFC83D);
  static const _domeColor = Color(0xFFD4AF37);
  static const _beamColor = Color(0xFFFFC83D);

  const _TenSalawatPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.orbitPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w / 2, cy = h * 0.42;

    // Background — serene green-tinted night
    final depth = progress * 0.12;
    _paintLightBg(canvas, w, h, progress: progress);

    // Stars
    const starPos = [
      (0.08, 0.06),
      (0.22, 0.14),
      (0.40, 0.04),
      (0.56, 0.12),
      (0.72, 0.07),
      (0.88, 0.15),
      (0.32, 0.20),
      (0.64, 0.18),
      (0.16, 0.22),
      (0.78, 0.10),
    ];
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h),
        0.7 + tw * 0.8,
        Paint()
          ..color = Colors.white.withValues(
            alpha: (0.10 + progress * 0.25 + 0.30 * tw * progress).clamp(
              0.0,
              0.6,
            ),
          ),
      );
    }

    // punch scale removed — smooth calm tap

    // Central dome silhouette (Madinah)
    final domeY = cy + 5;
    final domeW = 30.0, domeH = 22.0;
    final domePath =
        Path()
          ..moveTo(cx - domeW, domeY)
          ..quadraticBezierTo(
            cx - domeW,
            domeY - domeH,
            cx,
            domeY - domeH - 8 * pulse,
          )
          ..quadraticBezierTo(cx + domeW, domeY - domeH, cx + domeW, domeY)
          ..close();
    canvas.drawPath(
      domePath,
      Paint()..color = _domeColor.withValues(alpha: 0.12 + progress * 0.20),
    );
    canvas.drawPath(
      domePath,
      Paint()
        ..color = _domeColor.withValues(alpha: 0.25 + progress * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Dome glow
    canvas.drawCircle(
      Offset(cx, domeY - 10),
      20,
      Paint()
        ..color = _domeColor.withValues(alpha: 0.06 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // 10 crescents in a ring around the dome
    final ringR = w * 0.28;
    final litCount = (progress * 10).ceil().clamp(0, 10);
    for (int i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + (i / 10) * math.pi * 2;
      final mx = cx + math.cos(angle) * ringR;
      final my = cy - 5 + math.sin(angle) * ringR * 0.65;
      final isLit = i < litCount;
      final cAlpha = isLit ? (0.45 + 0.15 * pulse) : 0.10;

      // Crescent — two overlapping circles
      canvas.drawCircle(
        Offset(mx, my),
        5,
        Paint()..color = _crescentColor.withValues(alpha: cAlpha),
      );
      canvas.drawCircle(
        Offset(mx + 2, my - 1),
        4,
        Paint()
          ..color = Color.fromRGBO(
            (10 + (depth * 15).round()).clamp(0, 255),
            (18 + (depth * 30).round()).clamp(0, 255),
            (16 + (depth * 20).round()).clamp(0, 255),
            1.0,
          ),
      ); // carve crescent shape

      if (isLit) {
        canvas.drawCircle(
          Offset(mx, my),
          9,
          Paint()
            ..color = _crescentColor.withValues(alpha: 0.08 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
    }

    // Intercession beam on completion
    if (isComplete) {
      canvas.drawLine(
        Offset(cx, cy - 30 - domeH),
        Offset(cx, 0),
        Paint()
          ..color = _beamColor.withValues(alpha: 0.12 * pulse)
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Shockwave
    // tap-effect removed — smooth calm

    // Particles
    // tap-effect removed — smooth calm

    // Label
    // progress % label removed
  }

  @override
  bool shouldRepaint(_TenSalawatPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.orbitPhase != orbitPhase;
}

// =============================================================================
// 🚪 Doors of Mercy (أبواب الرحمة) — Seek forgiveness 100x
// =============================================================================
class _DoorsOfMercy extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _DoorsOfMercy({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_DoorsOfMercy> createState() => _DoorsOfMercyState();
}

class _DoorsOfMercyState extends State<_DoorsOfMercy>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl,
      _growCtrl,
      _starCtrl,
      _pCtrl,
      _punchCtrl,
      _shockCtrl,
      _glowCtrl;
  late Animation<double> _pulse, _grow, _pAnim, _punch, _shock;
  double _prevProgress = 0.0;
  int _prevTap = 0;
  final List<_Particle> _particles = List.generate(
    16,
    (i) => _Particle(seed: i + 2300),
  );

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_DoorsOfMercy old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _glowCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _DoorsOfMercyPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                glowPhase: _glowCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _DoorsOfMercyPainter extends CustomPainter {
  final double progress,
      pulse,
      starPhase,
      particlePhase,
      punchScale,
      shockPhase,
      glowPhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  static const _heartColor = Color(0xFFF06292); // vibrant pink like reference
  static const _heartDark = Color(0xFFE91E63); // deeper pink-red
  static const _spotColor = Color(0xFF7B4055); // dark sin spots
  static const _mercyColor = Color(0xFFD4AF37);

  const _DoorsOfMercyPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.glowPhase = 0.0,
  });

  // Spots (sins) on the heart — deterministic positions
  static const _spotPositions = [
    (-0.12, -0.05, 7.0),
    (0.10, 0.08, 5.5),
    (-0.06, 0.15, 7.5),
    (0.15, -0.08, 5.0),
    (-0.18, 0.10, 6.0),
    (0.04, -0.12, 6.5),
    (0.18, 0.16, 5.2),
    (-0.14, -0.15, 5.8),
    (0.08, 0.22, 4.5),
    (-0.04, 0.04, 7.2),
    (0.12, -0.02, 6.2),
    (-0.10, 0.20, 5.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w / 2, cy = h * 0.44;

    // Background — soft warm cream
    _paintLightBg(canvas, w, h, progress: progress);

    // punch scale removed — smooth calm tap

    // Big heart shape
    final heartR = w * 0.30;
    final heartCy = cy + heartR * 0.1;

    // Soft glow behind heart
    canvas.drawCircle(
      Offset(cx, heartCy),
      heartR * 1.3,
      Paint()
        ..color = _heartColor.withValues(alpha: 0.08 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // Heart path — proper shape with two bumps at top and pointed bottom
    final heartPath = Path();
    final r = heartR;
    // Start at bottom tip
    heartPath.moveTo(cx, heartCy + r * 0.9);
    // Bottom-right to right bump
    heartPath.cubicTo(
      cx + r * 0.4,
      heartCy + r * 0.4,
      cx + r * 1.1,
      heartCy + r * 0.1,
      cx + r * 1.0,
      heartCy - r * 0.3,
    );
    // Right bump top arc
    heartPath.cubicTo(
      cx + r * 0.9,
      heartCy - r * 0.7,
      cx + r * 0.35,
      heartCy - r * 0.8,
      cx,
      heartCy - r * 0.4,
    );
    // Left bump top arc
    heartPath.cubicTo(
      cx - r * 0.35,
      heartCy - r * 0.8,
      cx - r * 0.9,
      heartCy - r * 0.7,
      cx - r * 1.0,
      heartCy - r * 0.3,
    );
    // Left bump to bottom tip
    heartPath.cubicTo(
      cx - r * 1.1,
      heartCy + r * 0.1,
      cx - r * 0.4,
      heartCy + r * 0.4,
      cx,
      heartCy + r * 0.9,
    );
    heartPath.close();

    // Heart fill — gradient from light pink to deeper pink
    canvas.drawPath(
      heartPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isComplete ? const Color(0xFFF06292) : _heartColor,
            isComplete ? const Color(0xFFEC407A) : _heartDark,
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, heartCy), radius: heartR),
        ),
    );

    // Highlight on upper-left bump (soft light reflection like reference)
    canvas.drawCircle(
      Offset(cx - heartR * 0.45, heartCy - heartR * 0.45),
      heartR * 0.20,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    // Curved highlight stroke on left bump
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx - heartR * 0.45, heartCy - heartR * 0.30),
        width: heartR * 0.5,
        height: heartR * 0.6,
      ),
      math.pi * 1.1,
      math.pi * 0.5,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Dark spots (sins) that fade with progress
    final spotsRemaining = ((_spotPositions.length) * (1.0 - progress)).round();
    for (int i = 0; i < _spotPositions.length; i++) {
      final (sx, sy, sr) = _spotPositions[i];
      final spotX = cx + sx * heartR;
      final spotY = heartCy + sy * heartR;

      if (i < spotsRemaining) {
        // Spot still present — dark blotch
        final bobble = math.sin(glowPhase * math.pi * 2 + i * 0.9) * 0.5;
        canvas.drawCircle(
          Offset(spotX, spotY),
          sr + bobble + 3,
          Paint()
            ..color = _spotColor.withValues(alpha: 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(spotX, spotY),
          sr + bobble,
          Paint()..color = _spotColor.withValues(alpha: 0.65),
        );
      } else {
        // Spot cleared — light sparkle fading out
        final clearT = ((progress - i / _spotPositions.length) *
                _spotPositions.length)
            .clamp(0.0, 1.0);
        if (clearT < 0.01 || clearT > 0.90) continue;
        final fadeAlpha = (1.0 - clearT) * 0.60;
        canvas.drawCircle(
          Offset(spotX, spotY),
          sr * (1.0 - clearT * 0.5) + 3,
          Paint()
            ..color = Colors.white.withValues(alpha: fadeAlpha * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(spotX, spotY),
          sr * (1.0 - clearT * 0.6),
          Paint()..color = Colors.white.withValues(alpha: fadeAlpha),
        );
      }
    }

    // Completion glow — heart glows warm
    if (isComplete) {
      canvas.drawPath(
        heartPath,
        Paint()
          ..color = const Color(0xFFFF8A80).withValues(alpha: 0.08 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Shockwave
    // tap-effect removed — smooth calm

    // Particles
    // tap-effect removed — smooth calm

    // Label
    // progress % label removed
  }

  @override
  bool shouldRepaint(_DoorsOfMercyPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.glowPhase != glowPhase;
}

// =============================================================================
// ⚖️ Heavy Scales — dhikr outweighs all other morning/evening dhikr
// morning_20 / evening_20 — "SubhanAllah 'adada khalqihi" etc.
// Balance beam tilts progressively LEFT as progress grows
// =============================================================================
class _HeavyScales extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _HeavyScales({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_HeavyScales> createState() => _HeavyScalesState();
}

class _HeavyScalesState extends State<_HeavyScales>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl,
      _growCtrl,
      _starCtrl,
      _pCtrl,
      _punchCtrl,
      _shockCtrl,
      _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _growCtrl.animateTo(widget.progress);
  }

  @override
  void didUpdateWidget(_HeavyScales old) {
    super.didUpdateWidget(old);
    _growCtrl.animateTo(widget.progress, curve: Curves.easeOut);
    if (widget.tapCount > old.tapCount) {
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
      // Small bounce on each tap
      _bounceCtrl.forward(from: 0).then((_) => _bounceCtrl.reverse());
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _bounceCtrl,
        _shockCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 260,
            child: CustomPaint(
              size: const Size(double.infinity, 260),
              painter: _HeavyScalesPainter(
                pulse: _pulseCtrl.value,
                grow: _growCtrl.value,
                star: _starCtrl.value,
                bounce: _bounceCtrl.value,
                shock: _shockCtrl.value,
                complete: widget.isComplete,
              ),
            ),
          ),
    );
  }
}

class _HeavyScalesPainter extends CustomPainter {
  final double pulse, grow, star, bounce, shock;
  final bool complete;

  const _HeavyScalesPainter({
    required this.pulse,
    required this.grow,
    required this.star,
    required this.bounce,
    required this.shock,
    required this.complete,
  });

  // Max tilt of the scale beam (radians) at full progress
  static const _maxTilt = 0.30; // ~17°

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));

    // ── Background: light blue-gray ───────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF0F4F8), Color(0xFFE8EEF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Ground strip
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.86, w, h * 0.14),
      Paint()..color = const Color(0xFFDFE8EF),
    );

    // ── Tilt angle driven by progress (with tiny bounce on tap) ──────────────
    final bounceDelta = math.sin(bounce * math.pi) * 0.04;
    final tilt = grow * _maxTilt + bounceDelta;

    // ── Scale geometry ────────────────────────────────────────────────────────
    // Post
    const postCx = 0.0; // offset from cx
    final pivotY = h * 0.28;
    const beamArm = 0.0; // defined below per-canvas-width
    final armLen = w * 0.38;
    const stringLen = 55.0;
    const panR = 38.0;

    // Pivot point (top of post)
    final pivot = Offset(cx + postCx, pivotY);

    // Beam endpoints (rotated by tilt — left goes down, right goes up)
    final leftEnd = Offset(
      pivot.dx - armLen * math.cos(tilt),
      pivot.dy + armLen * math.sin(tilt),
    );
    final rightEnd = Offset(
      pivot.dx + armLen * math.cos(tilt),
      pivot.dy - armLen * math.sin(tilt),
    );

    // Pan centers (below beam ends via hanging strings)
    final leftPan = Offset(leftEnd.dx, leftEnd.dy + stringLen);
    final rightPan = Offset(rightEnd.dx, rightEnd.dy + stringLen);

    // ── Glow around heavy (left) pan ─────────────────────────────────────────
    if (grow > 0.05) {
      canvas.drawCircle(
        leftPan,
        panR + 14 + pulse * 6,
        Paint()
          ..color = const Color(
            0xFFFFD700,
          ).withValues(alpha: grow * (0.12 + pulse * 0.08))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
      // Light rays from heavy pan
      _drawRays(canvas, leftPan, panR + 8 + pulse * 4, grow, pulse);
    }

    // ── Hanging strings ───────────────────────────────────────────────────────
    final stringPaint =
        Paint()
          ..color = const Color(0xFFB8860B)
          ..strokeWidth = 1.6;
    // Left strings: V-shape from beam end → outer rim of pan
    canvas.drawLine(leftEnd, leftPan.translate(-panR * 0.62, 0), stringPaint);
    canvas.drawLine(leftEnd, leftPan.translate(panR * 0.62, 0), stringPaint);
    // Right strings
    canvas.drawLine(rightEnd, rightPan.translate(-panR * 0.62, 0), stringPaint);
    canvas.drawLine(rightEnd, rightPan.translate(panR * 0.62, 0), stringPaint);

    // ── Scale post + base ─────────────────────────────────────────────────────
    // Post
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, (pivotY + h * 0.86) / 2),
          width: 12,
          height: h * 0.86 - pivotY,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF2D3B55),
    );
    // Base
    final basePath =
        Path()
          ..moveTo(cx - 38, h * 0.86)
          ..lineTo(cx + 38, h * 0.86)
          ..lineTo(cx + 28, h * 0.96)
          ..lineTo(cx - 28, h * 0.96)
          ..close();
    canvas.drawPath(basePath, Paint()..color = const Color(0xFF2D3B55));
    // Base top strip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.86), width: 80, height: 10),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF3D4F68),
    );

    // ── Beam ──────────────────────────────────────────────────────────────────
    canvas.drawLine(
      leftEnd,
      rightEnd,
      Paint()
        ..color = const Color(0xFFB8860B)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    // Gold highlight on beam
    canvas.drawLine(
      leftEnd,
      rightEnd,
      Paint()
        ..color = const Color(0xFFFFE57F).withValues(alpha: 0.6)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // ── Pivot golden circle ───────────────────────────────────────────────────
    canvas.drawCircle(pivot, 14, Paint()..color = const Color(0xFFB8860B));
    canvas.drawCircle(pivot, 10, Paint()..color = const Color(0xFFFFD700));
    canvas.drawCircle(pivot, 6, Paint()..color = const Color(0xFFFFEE88));

    // ── Left pan (heavy — goes down) ──────────────────────────────────────────
    _drawPan(canvas, leftPan, panR, true);
    // Draw gifts inside left pan (progress-driven count)
    final giftCount = (grow * 3).ceil().clamp(0, 3);
    _drawGifts(canvas, leftPan, panR, giftCount, pulse);

    // ── Right pan (light — goes up) ───────────────────────────────────────────
    _drawPan(canvas, rightPan, panR, false);
    // "All other dhikr" label inside right pan
    _drawPanLabel(canvas, rightPan, panR);

    // ── Twinkling sparkles around heavy pan ─────────────────────────────────
    if (grow > 0.3) {
      final sparkPositions = [
        leftPan.translate(-panR - 18, -10),
        leftPan.translate(-panR - 28, 16),
        leftPan.translate(-panR - 12, 26),
        leftPan.translate(-panR - 36, -4),
      ];
      for (int i = 0; i < sparkPositions.length; i++) {
        final t = (math.sin((star + i * 0.4) * math.pi) * 0.5 + 0.5) * grow;
        _drawSparkle(
          canvas,
          sparkPositions[i],
          4 + t * 3,
          const Color(0xFFFFD700).withValues(alpha: 0.3 + t * 0.6),
        );
      }
    }

    // ── Shockwave ─────────────────────────────────────────────────────────────
    if (shock > 0) {
      canvas.drawCircle(
        leftPan,
        panR + shock * 60,
        Paint()
          ..color = const Color(
            0xFFFFD700,
          ).withValues(alpha: (1 - shock) * 0.40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // ── Completion shimmer ────────────────────────────────────────────────────
    if (complete) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..color = const Color(
            0xFFFFD700,
          ).withValues(alpha: 0.05 + pulse * 0.04),
      );
    }

    canvas.restore();
  }

  // ── Golden pan (arc/bowl shape) ────────────────────────────────────────────
  void _drawPan(Canvas canvas, Offset center, double r, bool isHeavy) {
    final panColor =
        isHeavy ? const Color(0xFFD4AF37) : const Color(0xFFC8A028);

    // Pan shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, 3),
        width: r * 2.2,
        height: r * 0.55,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Pan arc (half-circle cup clipped to bottom half)
    final panPath =
        Path()..addArc(
          Rect.fromCenter(center: center, width: r * 2.0, height: r * 2.0),
          0,
          math.pi,
        );
    canvas.drawPath(
      panPath,
      Paint()
        ..color =
            isHeavy
                ? const Color(0xFFFAF0D0).withValues(alpha: 0.95)
                : const Color(0xFFF5EAC8).withValues(alpha: 0.90)
        ..style = PaintingStyle.fill,
    );
    // Pan rim
    canvas.drawPath(
      panPath,
      Paint()
        ..color = panColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    // Bottom line of pan
    canvas.drawLine(
      center.translate(-r, 0),
      center.translate(r, 0),
      Paint()
        ..color = panColor
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── Colourful gift boxes inside left pan ──────────────────────────────────
  void _drawGifts(
    Canvas canvas,
    Offset panCenter,
    double panR,
    int count,
    double pulse,
  ) {
    if (count == 0) return;

    // Gift positions inside the pan (arranged side-by-side)
    final positions = [
      panCenter.translate(0, -panR * 0.35),
      panCenter.translate(-panR * 0.44, -panR * 0.28),
      panCenter.translate(panR * 0.44, -panR * 0.28),
    ];

    const giftColors = [
      Color(0xFFFFCC44), // gold
      Color(0xFFFFC83D), // teal
      Color(0xFFA78BFA), // violet
    ];
    const ribbonColors = [
      Color(0xFFFF6B6B),
      Color(0xFFFF6B6B),
      Color(0xFFFFCC44),
    ];

    for (int i = 0; i < count && i < positions.length; i++) {
      _drawGiftBox(canvas, positions[i], 12.0, giftColors[i], ribbonColors[i]);
    }
  }

  void _drawGiftBox(
    Canvas canvas,
    Offset center,
    double s,
    Color boxColor,
    Color ribbonColor,
  ) {
    final boxRect = Rect.fromCenter(
      center: center,
      width: s * 1.8,
      height: s * 1.6,
    );

    // Box body
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(3)),
      Paint()..color = boxColor,
    );
    // Box outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(3)),
      Paint()
        ..color = boxColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // Lid strip (top 30% of box)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          boxRect.left,
          boxRect.top,
          boxRect.width,
          boxRect.height * 0.32,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = ribbonColor.withValues(alpha: 0.85),
    );
    // Ribbon vertical
    canvas.drawRect(
      Rect.fromCenter(center: center, width: s * 0.28, height: s * 1.6),
      Paint()..color = ribbonColor.withValues(alpha: 0.85),
    );
    // Bow (two small circles)
    canvas.drawCircle(
      center.translate(-s * 0.22, -s * 0.60),
      s * 0.22,
      Paint()..color = ribbonColor,
    );
    canvas.drawCircle(
      center.translate(s * 0.22, -s * 0.60),
      s * 0.22,
      Paint()..color = ribbonColor,
    );
  }

  // ── "All other dhikr" text inside right pan ───────────────────────────────
  void _drawPanLabel(Canvas canvas, Offset center, double r) {
    final tp = TextPainter(
      text: const TextSpan(
        text: 'All other\ndhikr',
        style: TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 8,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: r * 1.1);
    // Position at vertical centre of the pan bowl (rim + r*0.5)
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy + r * 0.40 - tp.height / 2),
    );
  }

  // ── Light rays from heavy pan ──────────────────────────────────────────────
  void _drawRays(
    Canvas canvas,
    Offset center,
    double len,
    double grow,
    double pulse,
  ) {
    const rayAngles = [
      -2.35, -2.55, -2.75, -2.95, -3.14, // left arc rays
    ];
    final rayPaint =
        Paint()
          ..color = const Color(
            0xFFFFD700,
          ).withValues(alpha: grow * (0.15 + pulse * 0.10))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
    for (final a in rayAngles) {
      canvas.drawLine(
        Offset(center.dx + 30 * math.cos(a), center.dy + 30 * math.sin(a)),
        Offset(center.dx + len * math.cos(a), center.dy + len * math.sin(a)),
        rayPaint,
      );
    }
  }

  // ── 4-pointed sparkle ─────────────────────────────────────────────────────
  void _drawSparkle(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2 - math.pi / 4;
      path.moveTo(c.dx, c.dy);
      path.lineTo(c.dx + r * math.cos(a - 0.2), c.dy + r * math.sin(a - 0.2));
      path.lineTo(c.dx + r * 2.1 * math.cos(a), c.dy + r * 2.1 * math.sin(a));
      path.lineTo(c.dx + r * math.cos(a + 0.2), c.dy + r * math.sin(a + 0.2));
      path.close();
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_HeavyScalesPainter o) =>
      o.pulse != pulse ||
      o.grow != grow ||
      o.star != star ||
      o.bounce != bounce ||
      o.shock != shock ||
      o.complete != complete;
}

// =============================================================================
// 🌌 Cosmic Weight (الوزن الكوني) — 4 phrases that outweigh all dhikr
// =============================================================================
class _CosmicWeight extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _CosmicWeight({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_CosmicWeight> createState() => _CosmicWeightState();
}

class _CosmicWeightState extends State<_CosmicWeight>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl,
      _growCtrl,
      _starCtrl,
      _pCtrl,
      _punchCtrl,
      _shockCtrl,
      _cosmicCtrl;
  late Animation<double> _pulse, _grow, _pAnim, _punch, _shock;
  double _prevProgress = 0.0;
  int _prevTap = 0;
  final List<_Particle> _particles = List.generate(
    18,
    (i) => _Particle(seed: i + 2400),
  );

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _punch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _cosmicCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
  }

  @override
  void didUpdateWidget(_CosmicWeight old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) {
        p.reset();
      }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _cosmicCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _cosmicCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 290,
            child: CustomPaint(
              painter: _CosmicWeightPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                starPhase: _starCtrl.value,
                particlePhase: _pAnim.value,
                particles: _particles,
                isComplete: widget.isComplete,
                pointsToday: widget.pointsToday,
                punchScale: _punch.value,
                shockPhase: _shock.value,
                cosmicPhase: _cosmicCtrl.value,
              ),
            ),
          ),
    );
  }
}

class _CosmicWeightPainter extends CustomPainter {
  final double progress,
      pulse,
      starPhase,
      particlePhase,
      punchScale,
      shockPhase,
      cosmicPhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;

  static const _phraseColors = [
    Color(0xFFD4AF37),
    Color(0xFFFFC83D),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
  ]; // عدد خلقه, رضا نفسه, زنة عرشه, مداد كلماته
  static const _phraseLabels = [
    'عَدَد خَلْقِه',
    'رِضَا نَفْسِه',
    'زِنَة عَرْشِه',
    'مِدَاد كَلِمَاتِه',
  ];

  const _CosmicWeightPainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.cosmicPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w / 2, cy = h * 0.38;

    // Background
    _paintLightBg(canvas, w, h, progress: progress);

    // punch scale removed — smooth calm tap

    // ── Scale structure — thick, bright, prominent ──
    final beamY = cy;
    final tilt = progress * 14;
    final beamLen = w * 0.34;

    // Central pillar
    canvas.drawLine(
      Offset(cx, beamY - 42),
      Offset(cx, beamY + 10),
      Paint()
        ..color = const Color(0xFF8B7355).withValues(alpha: 0.80)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round,
    );

    // Fulcrum triangle
    final fulPath =
        Path()
          ..moveTo(cx, beamY - 45)
          ..lineTo(cx - 10, beamY - 32)
          ..lineTo(cx + 10, beamY - 32)
          ..close();
    canvas.drawPath(
      fulPath,
      Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.85),
    );
    canvas.drawPath(
      fulPath,
      Paint()
        ..color = const Color(0xFFB8962E).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Beam — thick and gold
    final leftBeamY = beamY - 30 + tilt;
    final rightBeamY = beamY - 30 - tilt;
    canvas.drawLine(
      Offset(cx - beamLen, leftBeamY),
      Offset(cx + beamLen, rightBeamY),
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.80)
        ..strokeWidth = 3.5,
    );

    // ── Left pan chains (heavy side — phrases) ──
    final leftPanX = cx - beamLen;
    final leftPanY = leftBeamY + 30;
    canvas.drawLine(
      Offset(leftPanX - 18, leftPanY - 2),
      Offset(leftPanX, leftBeamY + 2),
      Paint()
        ..color = const Color(0xFF8B7355).withValues(alpha: 0.70)
        ..strokeWidth = 2.0,
    );
    canvas.drawLine(
      Offset(leftPanX + 18, leftPanY - 2),
      Offset(leftPanX, leftBeamY + 2),
      Paint()
        ..color = const Color(0xFF8B7355).withValues(alpha: 0.70)
        ..strokeWidth = 2.0,
    );

    // Left pan dish — curved, thick
    final leftPanPath =
        Path()
          ..moveTo(leftPanX - 22, leftPanY)
          ..quadraticBezierTo(leftPanX, leftPanY + 14, leftPanX + 22, leftPanY);
    canvas.drawPath(
      leftPanPath,
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    // ── 4 phrase circles inside left pan (transparent circles with text) ──
    for (int i = 0; i < 4; i++) {
      final phraseThreshold = (i + 1) * 0.25;
      final reached = progress >= phraseThreshold;
      final phraseA =
          reached
              ? 0.75
              : ((progress / phraseThreshold).clamp(0.0, 1.0) * 0.25);
      if (phraseA < 0.03) continue;

      final color = _phraseColors[i];
      // 2x2 grid inside the pan area
      final col = i % 2;
      final row = i ~/ 2;
      final ox = leftPanX - 10 + col * 20;
      final oy = leftPanY + 18 + row * 22;
      final orbR = 10.0;

      // Transparent circle with border
      canvas.drawCircle(
        Offset(ox, oy),
        orbR,
        Paint()..color = color.withValues(alpha: phraseA * 0.15),
      );
      canvas.drawCircle(
        Offset(ox, oy),
        orbR,
        Paint()
          ..color = color.withValues(alpha: phraseA * 0.70)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );

      // Label inside circle — removed
    }

    // ── Right pan chains (light side — empty) ──
    final rightPanX = cx + beamLen;
    final rightPanY = rightBeamY + 30;
    canvas.drawLine(
      Offset(rightPanX - 18, rightPanY - 2),
      Offset(rightPanX, rightBeamY + 2),
      Paint()
        ..color = const Color(0xFF8B7355).withValues(alpha: 0.70)
        ..strokeWidth = 2.0,
    );
    canvas.drawLine(
      Offset(rightPanX + 18, rightPanY - 2),
      Offset(rightPanX, rightBeamY + 2),
      Paint()
        ..color = const Color(0xFF8B7355).withValues(alpha: 0.70)
        ..strokeWidth = 2.0,
    );

    // Right pan dish
    final rightPanPath =
        Path()
          ..moveTo(rightPanX - 22, rightPanY)
          ..quadraticBezierTo(
            rightPanX,
            rightPanY + 10,
            rightPanX + 22,
            rightPanY,
          );
    canvas.drawPath(
      rightPanPath,
      Paint()
        ..color = const Color(0xFF9CA3AF).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Shockwave
    // tap-effect removed — smooth calm

    // Particles
    // tap-effect removed — smooth calm

    // Label
    // progress % label removed
  }

  @override
  bool shouldRepaint(_CosmicWeightPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.starPhase != starPhase ||
      o.particlePhase != particlePhase ||
      o.isComplete != isComplete ||
      o.pointsToday != pointsToday ||
      o.punchScale != punchScale ||
      o.shockPhase != shockPhase ||
      o.cosmicPhase != cosmicPhase;
}

// =============================================================================
// Shield — Baqarah Opening: Satan repelled from home (morning_2/evening_2)
// =============================================================================
class _BaqarahShield extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _BaqarahShield({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_BaqarahShield> createState() => _BaqarahShieldState();
}

class _BaqarahShieldState extends State<_BaqarahShield>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _glowCtrl, _shimCtrl;
  late Animation<double> _pulse, _grow, _glow;
  double _prevProgress = 0.0;

  static const _lines = [
    (text: 'Satan cannot', accent: false),
    (text: 'enter the home', accent: false),
    (text: 'or come near', accent: false),
    (text: 'his family', accent: false),
    (text: 'who recites this', accent: true),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _shimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void didUpdateWidget(_BaqarahShield old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _glowCtrl.dispose();
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _glowCtrl,
        _shimCtrl,
      ]),
      builder: (_, __) {
        final progress = _grow.value;
        return SizedBox(
          height: 260,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        isDark
                            ? [
                              const Color(0xFF1A2030),
                              const Color(0xFF1E2840),
                              const Color(0xFF181C30),
                            ]
                            : [
                              const Color(0xFFF0F6FF),
                              const Color(0xFFEBF2FF),
                              const Color(0xFFF5F0FF),
                            ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 210 * _pulse.value,
                  height: 210 * _pulse.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(
                          0xFF6366F1,
                        ).withValues(alpha: 0.06 * _glow.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              CustomPaint(painter: _ShieldStarPainter(phase: _shimCtrl.value)),
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 44,
                    height: 36,
                    child: CustomPaint(
                      painter: _HouseIconPainter(
                        fill: (isDark
                                ? const Color(0xFF818CF8)
                                : const Color(0xFF4338CA))
                            .withValues(
                              alpha: (0.18 + progress * 0.55).clamp(0.0, 1.0),
                            ),
                        stroke: (isDark
                                ? const Color(0xFF818CF8)
                                : const Color(0xFF4338CA))
                            .withValues(
                              alpha: (0.40 + progress * 0.55).clamp(0.0, 1.0),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 76,
                  left: 24,
                  right: 24,
                  bottom: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < _lines.length; i++) ...[
                      _buildLine(i, progress, isDark),
                      if (i < _lines.length - 1) const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
              if (widget.isComplete)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(
                            0xFF6366F1,
                          ).withValues(alpha: _glow.value * 0.70),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLine(int i, double progress, bool isDark) {
    final seg = _lines[i];
    final total = _lines.length;
    // Text always fully visible from frame 1.
    const double opacity = 1.0;
    final isLast = i == total - 1;
    Color color;
    double fontSize;
    FontWeight weight;
    if (isLast || seg.accent) {
      color = isDark ? const Color(0xFF818CF8) : const Color(0xFF3730A3);
      fontSize = 19;
      weight = FontWeight.w800;
    } else if (i == 0) {
      color = isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA);
      fontSize = 18;
      weight = FontWeight.w700;
    } else {
      color = (isDark ? Colors.white : const Color(0xFF1E293B)).withValues(
        alpha: isDark ? 0.85 : 0.80,
      );
      fontSize = 16;
      weight = FontWeight.w500;
    }
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 420),
      child: Text(
        seg.text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: fontSize * (isLast ? _pulse.value : 1.0),
          fontWeight: weight,
          color: color,
          letterSpacing: isLast ? 0.8 : 0.2,
          height: 1.4,
        ),
      ),
    );
  }
}

class _HouseIconPainter extends CustomPainter {
  final Color fill, stroke;
  const _HouseIconPainter({required this.fill, required this.stroke});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final roof =
        Path()
          ..moveTo(w / 2, 0)
          ..lineTo(w, h * 0.45)
          ..lineTo(0, h * 0.45)
          ..close();
    canvas.drawPath(roof, Paint()..color = fill);
    canvas.drawPath(
      roof,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
    final walls = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.43, w * 0.70, h * 0.57),
      const Radius.circular(2),
    );
    canvas.drawRRect(walls, Paint()..color = fill);
    canvas.drawRRect(
      walls,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.38, h * 0.62, w * 0.24, h * 0.38),
        const Radius.circular(2),
      ),
      Paint()..color = stroke.withValues(alpha: stroke.a * 0.6),
    );
  }

  @override
  bool shouldRepaint(_HouseIconPainter o) =>
      o.fill != fill || o.stroke != stroke;
}

class _ShieldStarPainter extends CustomPainter {
  final double phase;
  const _ShieldStarPainter({required this.phase});
  static const _pts = [
    (0.10, 0.10, 0.9),
    (0.90, 0.08, 1.1),
    (0.30, 0.85, 1.0),
    (0.75, 0.80, 0.8),
    (0.55, 0.12, 1.2),
    (0.18, 0.50, 0.9),
    (0.82, 0.45, 1.0),
    (0.45, 0.70, 1.1),
    (0.65, 0.58, 0.8),
    (0.25, 0.30, 1.0),
    (0.85, 0.25, 0.9),
    (0.50, 0.95, 1.2),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (int i = 0; i < _pts.length; i++) {
      final (rx, ry, r) = _pts[i];
      final tw = (math.sin((phase + i * 0.19) * math.pi * 2) * 0.5 + 0.5);
      p.color = const Color(0xFF38BDF8).withValues(alpha: tw * 0.22);
      canvas.drawCircle(Offset(rx * size.width, ry * size.height), r, p);
    }
  }

  @override
  bool shouldRepaint(_ShieldStarPainter o) => o.phase != phase;
}

// =============================================================================
// Book — Baqarah closing verses: enough for you (morning_4&5/evening_4&5)
// =============================================================================
class _BaqarahClose extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _BaqarahClose({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_BaqarahClose> createState() => _BaqarahCloseState();
}

class _BaqarahCloseState extends State<_BaqarahClose>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _glowCtrl, _shimCtrl;
  late Animation<double> _pulse, _grow, _glow;
  double _prevProgress = 0.0;

  static const _segments = [
    (text: 'Whoever recites', big: false, gold: false),
    (text: 'the last two verses', big: false, gold: false),
    (text: 'of Surah Al-Baqarah', big: false, gold: false),
    (text: 'at night --', big: false, gold: false),
    (text: 'they will be', big: false, gold: false),
    (text: 'enough for him', big: true, gold: true),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 0.25,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _shimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void didUpdateWidget(_BaqarahClose old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _glowCtrl.dispose();
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _glowCtrl,
        _shimCtrl,
      ]),
      builder: (_, __) {
        final progress = _grow.value;
        return SizedBox(
          height: 260,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        isDark
                            ? [
                              const Color(0xFF1A2030),
                              const Color(0xFF1E2840),
                              const Color(0xFF181C30),
                            ]
                            : [
                              const Color(0xFFFAF5EB),
                              const Color(0xFFF0EAF8),
                              const Color(0xFFEBF3FA),
                            ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 190 * _pulse.value,
                  height: 190 * _pulse.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(
                          0xFF6366F1,
                        ).withValues(alpha: 0.07 * _glow.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              CustomPaint(
                painter: _BaqarahClosePainter(phase: _shimCtrl.value),
              ),
              Positioned(
                top: 18,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 48,
                    height: 32,
                    child: CustomPaint(
                      painter: _BookIconPainter(
                        color: (isDark
                                ? const Color(0xFF818CF8)
                                : const Color(0xFF4338CA))
                            .withValues(
                              alpha: (0.30 + progress * 0.65).clamp(0.0, 1.0),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 72,
                  left: 22,
                  right: 22,
                  bottom: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < _segments.length; i++) ...[
                      _buildSegment(i, progress, isDark),
                      if (i < _segments.length - 1) const SizedBox(height: 3),
                    ],
                  ],
                ),
              ),
              if (widget.isComplete)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(
                            0xFF6366F1,
                          ).withValues(alpha: _glow.value * 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegment(int i, double progress, bool isDark) {
    final seg = _segments[i];
    // Text always fully visible from frame 1.
    const double opacity = 1.0;
    Color color;
    double fontSize;
    FontWeight weight;
    if (seg.gold) {
      color = isDark ? const Color(0xFF818CF8) : const Color(0xFF3730A3);
      fontSize = 24.0 * _pulse.value;
      weight = FontWeight.w900;
    } else if (i == 0) {
      color = isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA);
      fontSize = 17;
      weight = FontWeight.w700;
    } else {
      color = (isDark ? Colors.white : const Color(0xFF334155)).withValues(
        alpha: isDark ? 0.80 : 0.75,
      );
      fontSize = seg.big ? 17 : 15;
      weight = FontWeight.w500;
    }
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 440),
      child: Text(
        seg.text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          letterSpacing: seg.gold ? 1.0 : 0.2,
          height: 1.4,
        ),
      ),
    );
  }
}

class _BookIconPainter extends CustomPainter {
  final Color color;
  const _BookIconPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
    final left =
        Path()
          ..moveTo(w / 2, h * 0.1)
          ..quadraticBezierTo(w * 0.1, h * 0.1, w * 0.05, h * 0.5)
          ..quadraticBezierTo(w * 0.08, h * 0.9, w / 2, h * 0.95)
          ..close();
    canvas.drawPath(
      left,
      Paint()..color = color.withValues(alpha: color.a * 0.25),
    );
    canvas.drawPath(left, p);
    final right =
        Path()
          ..moveTo(w / 2, h * 0.1)
          ..quadraticBezierTo(w * 0.9, h * 0.1, w * 0.95, h * 0.5)
          ..quadraticBezierTo(w * 0.92, h * 0.9, w / 2, h * 0.95)
          ..close();
    canvas.drawPath(
      right,
      Paint()..color = color.withValues(alpha: color.a * 0.25),
    );
    canvas.drawPath(right, p);
    canvas.drawLine(Offset(w / 2, h * 0.08), Offset(w / 2, h * 0.96), p);
    for (int i = 0; i < 3; i++) {
      final y = h * (0.3 + i * 0.18);
      canvas.drawLine(
        Offset(w * 0.15, y),
        Offset(w * 0.44, y),
        Paint()
          ..color = color.withValues(alpha: color.a * 0.45)
          ..strokeWidth = 1.2,
      );
      canvas.drawLine(
        Offset(w * 0.56, y),
        Offset(w * 0.85, y),
        Paint()
          ..color = color.withValues(alpha: color.a * 0.45)
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(_BookIconPainter o) => o.color != color;
}

class _BaqarahClosePainter extends CustomPainter {
  final double phase;
  const _BaqarahClosePainter({required this.phase});
  static const _pts = [
    (0.08, 0.08, 1.0),
    (0.92, 0.06, 0.8),
    (0.20, 0.88, 1.1),
    (0.78, 0.82, 0.9),
    (0.50, 0.10, 1.2),
    (0.14, 0.45, 0.8),
    (0.86, 0.42, 1.0),
    (0.42, 0.75, 0.9),
    (0.62, 0.60, 1.1),
    (0.30, 0.22, 0.8),
    (0.70, 0.20, 1.0),
    (0.55, 0.92, 0.9),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (int i = 0; i < _pts.length; i++) {
      final (rx, ry, r) = _pts[i];
      final tw = (math.sin((phase + i * 0.21) * math.pi * 2) * 0.5 + 0.5);
      p.color = const Color(0xFF6366F1).withValues(alpha: tw * 0.10);
      canvas.drawCircle(Offset(rx * size.width, ry * size.height), r, p);
    }
  }

  @override
  bool shouldRepaint(_BaqarahClosePainter o) => o.phase != phase;
}

// =============================================================================
// Moon — Night Peace: peaceful sleep, room with night window (morning_6/evening_6)
// =============================================================================
class _NightPeace extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _NightPeace({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_NightPeace> createState() => _NightPeaceState();
}

class _NightPeaceState extends State<_NightPeace>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _glowCtrl, _shimCtrl;
  late Animation<double> _pulse, _grow, _glow;
  double _prevProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _shimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void didUpdateWidget(_NightPeace old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _glowCtrl.dispose();
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _glowCtrl,
        _shimCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 260,
            child: CustomPaint(
              painter: _NightPeacePainter(
                progress: _grow.value,
                pulse: _pulse.value,
                glowPhase: _glow.value,
                starPhase: _shimCtrl.value,
                isComplete: widget.isComplete,
              ),
            ),
          ),
    );
  }
}

class _NightPeacePainter extends CustomPainter {
  final double progress, pulse, glowPhase, starPhase;
  final bool isComplete;
  const _NightPeacePainter({
    required this.progress,
    required this.pulse,
    required this.glowPhase,
    required this.starPhase,
    required this.isComplete,
  });

  static const _skinTone = Color(0xFFD4956A);
  static const _bedBase = Color(0xFF6B4E2B);
  static const _mattress = Color(0xFFF0E6D3);
  static const _blanket = Color(0xFF4A7C8E);
  static const _pillow = Color(0xFFE8D5B7);
  static const _nightSky = Color(0xFF0B192E);
  static const _moonClr = Color(0xFFFFF3C4);
  static const _starClr = Color(0xFFE8D9B0);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Illustration always fully painted from frame 1 (was 0.18..1.0 fade
    // on tap progress, leaving the night scene + text labels ghosted
    // before completion).
    const double alpha = 1.0;

    // Background wall
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1008),
            const Color(0xFF2C1F0F),
            const Color(0xFF3D2B16),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Floor
    final floorY = h * 0.72;
    canvas.drawRect(
      Rect.fromLTWH(0, floorY, w, h - floorY),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF8B6F47).withValues(alpha: 0.55),
            const Color(0xFF8B6F47).withValues(alpha: 0.35),
          ],
        ).createShader(Rect.fromLTWH(0, floorY, w, h - floorY)),
    );

    _drawWindow(canvas, w, h, alpha);
    _drawBed(canvas, w, h, alpha);

    if (isComplete) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, 3),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFFFFF3C4).withValues(alpha: glowPhase * 0.7),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(0, 0, w, 3)),
      );
    }
  }

  void _drawWindow(Canvas canvas, double w, double h, double alpha) {
    final winL = w * 0.06, winT = h * 0.08, winW = w * 0.30, winH = h * 0.50;
    final winR = winL + winW, winB = winT + winH;
    final skyRect = Rect.fromLTWH(winL, winT, winW, winH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(skyRect, const Radius.circular(4)),
      Paint()..color = _nightSky.withValues(alpha: alpha),
    );
    final moonX = winL + winW * 0.72, moonY = winT + winH * 0.18;
    final moonR = winW * 0.12 * pulse;
    canvas.drawCircle(
      Offset(moonX, moonY),
      moonR,
      Paint()..color = _moonClr.withValues(alpha: alpha * 0.90),
    );
    canvas.drawCircle(
      Offset(moonX + moonR * 0.35, moonY - moonR * 0.05),
      moonR * 0.82,
      Paint()..color = _nightSky.withValues(alpha: alpha * 0.85),
    );
    final starData = [
      (0.20, 0.15, 1.0),
      (0.45, 0.10, 0.8),
      (0.15, 0.35, 0.9),
      (0.60, 0.28, 0.7),
      (0.35, 0.50, 0.8),
      (0.75, 0.45, 1.0),
      (0.28, 0.70, 0.7),
      (0.55, 0.65, 0.9),
      (0.10, 0.60, 0.8),
    ];
    final sp = Paint();
    for (int i = 0; i < starData.length; i++) {
      final (rx, ry, r) = starData[i];
      final twinkle =
          (math.sin((starPhase + i * 0.22) * math.pi * 2) * 0.5 + 0.5);
      sp.color = _starClr.withValues(alpha: twinkle * alpha * 0.75);
      canvas.drawCircle(Offset(winL + rx * winW, winT + ry * winH), r, sp);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(skyRect, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFF5A4A3A).withValues(alpha: 0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0,
    );
    final cp =
        Paint()
          ..color = const Color(0xFF5A4A3A).withValues(alpha: 0.85)
          ..strokeWidth = 3.0;
    canvas.drawLine(
      Offset((winL + winR) / 2, winT),
      Offset((winL + winR) / 2, winB),
      cp,
    );
    canvas.drawLine(
      Offset(winL, winT + winH * 0.5),
      Offset(winR, winT + winH * 0.5),
      cp,
    );
  }

  void _drawBed(Canvas canvas, double w, double h, double alpha) {
    final bL = w * 0.40, bW = w * 0.54, bT = h * 0.32, bH = h * 0.52;
    final bR = bL + bW, bB = bT + bH;
    final hbH = bH * 0.18;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bL - 4, bT, bW + 8, hbH + 6),
        const Radius.circular(10),
      ),
      Paint()..color = _bedBase.withValues(alpha: alpha * 0.92),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bL - 6, bT + hbH, 12, bH - hbH),
        const Radius.circular(4),
      ),
      Paint()..color = _bedBase.withValues(alpha: alpha * 0.80),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bR - 6, bT + hbH, 12, bH - hbH),
        const Radius.circular(4),
      ),
      Paint()..color = _bedBase.withValues(alpha: alpha * 0.80),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bL - 4, bB - 14, bW + 8, 14),
        const Radius.circular(6),
      ),
      Paint()..color = _bedBase.withValues(alpha: alpha * 0.85),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bL + 4, bT + hbH + 2, bW - 8, bH - hbH - 14),
        const Radius.circular(4),
      ),
      Paint()..color = _mattress.withValues(alpha: alpha * 0.88),
    );
    _drawSleepingPerson(canvas, bL, bT, bW, bH, hbH, alpha);
  }

  void _drawSleepingPerson(
    Canvas canvas,
    double bL,
    double bT,
    double bW,
    double bH,
    double hbH,
    double alpha,
  ) {
    final cx = bL + bW / 2;
    final pillowT = bT + hbH + 6;
    final headR = bW * 0.095;
    final headCy = pillowT + headR * 1.1;
    // Pillow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, headCy + headR * 0.3),
          width: headR * 3.4,
          height: headR * 1.2,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = _pillow.withValues(alpha: alpha * 0.90),
    );
    // Blanket
    final blanketTop = headCy + headR * 0.55;
    final blanketBot = bT + bH - 14;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bL + 4, blanketTop, bW - 8, blanketBot - blanketTop),
        const Radius.circular(6),
      ),
      Paint()..color = _blanket.withValues(alpha: alpha * 0.90),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bL + 4, blanketTop, bW - 8, headR * 0.5),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF5A8FA0).withValues(alpha: alpha * 0.70),
    );
    // Head glow
    canvas.drawCircle(
      Offset(cx, headCy),
      headR * 1.35,
      Paint()
        ..color = _skinTone.withValues(alpha: alpha * 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      Offset(cx, headCy),
      headR,
      Paint()..color = _skinTone.withValues(alpha: alpha * 0.95),
    );
    // Hair
    final hairPath =
        Path()
          ..moveTo(cx - headR * 0.95, headCy - headR * 0.05)
          ..quadraticBezierTo(
            cx - headR * 0.80,
            headCy - headR * 1.45,
            cx,
            headCy - headR * 1.50,
          )
          ..quadraticBezierTo(
            cx + headR * 0.80,
            headCy - headR * 1.45,
            cx + headR * 0.95,
            headCy - headR * 0.05,
          )
          ..quadraticBezierTo(
            cx + headR * 0.60,
            headCy - headR * 0.15,
            cx,
            headCy - headR * 0.10,
          )
          ..quadraticBezierTo(
            cx - headR * 0.60,
            headCy - headR * 0.15,
            cx - headR * 0.95,
            headCy - headR * 0.05,
          )
          ..close();
    canvas.drawPath(
      hairPath,
      Paint()..color = const Color(0xFF2C1A0E).withValues(alpha: alpha * 0.92),
    );
    // Closed eyes
    final eyeY = headCy - headR * 0.12;
    final eyeOff = headR * 0.32;
    final eyePaint =
        Paint()
          ..color = const Color(0xFF3D2B16).withValues(alpha: alpha * 0.90)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(cx - eyeOff - headR * 0.22, eyeY)
        ..quadraticBezierTo(
          cx - eyeOff,
          eyeY + headR * 0.20,
          cx - eyeOff + headR * 0.22,
          eyeY,
        ),
      eyePaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + eyeOff - headR * 0.22, eyeY)
        ..quadraticBezierTo(
          cx + eyeOff,
          eyeY + headR * 0.20,
          cx + eyeOff + headR * 0.22,
          eyeY,
        ),
      eyePaint,
    );
    // Nose & smile
    canvas.drawCircle(
      Offset(cx, headCy + headR * 0.15),
      headR * 0.07,
      Paint()..color = const Color(0xFFC07A50).withValues(alpha: alpha * 0.55),
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx - headR * 0.22, headCy + headR * 0.38)
        ..quadraticBezierTo(
          cx,
          headCy + headR * 0.58,
          cx + headR * 0.22,
          headCy + headR * 0.38,
        ),
      Paint()
        ..color = const Color(0xFF7B4A2D).withValues(alpha: alpha * 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    // Zzz
    if (progress > 0.25) {
      final zAlpha = ((progress - 0.25) / 0.75 * 0.60).clamp(0.0, 0.60);
      final drift = (starPhase % 1.0) * headR * 1.0;
      final zData = [
        (cx + headR * 0.55, headCy - headR * 1.8 - drift, 8.5 * pulse),
        (cx + headR * 0.80, headCy - headR * 2.8 - drift * 0.85, 6.5 * pulse),
        (cx + headR * 1.0, headCy - headR * 3.7 - drift * 0.70, 4.8 * pulse),
      ];
      for (int i = 0; i < zData.length; i++) {
        final (zx, zy, zSize) = zData[i];
        final tp = TextPainter(
          text: TextSpan(
            text: 'z',
            style: TextStyle(
              color: const Color(
                0xFF818CF8,
              ).withValues(alpha: zAlpha * (1.0 - i * 0.30)),
              fontSize: zSize,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(zx, zy));
      }
    }
  }

  @override
  bool shouldRepaint(_NightPeacePainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.glowPhase != glowPhase ||
      o.starPhase != starPhase ||
      o.isComplete != isComplete;
}

// =============================================================================
// An-Nas Refuge — Surah An-Nas, 3x at dawn & dusk (morning_11/evening_11)
// =============================================================================
// Evening Sovereignty (evening_12) — text-based night illustration
// "Amsaina wa amsal-mulku lillah" — We entered the evening, dominion is Allah's
// Deep navy night sky · crescent moon · key phrases revealed progressively
// =============================================================================
class _EveningSovereignty extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _EveningSovereignty({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_EveningSovereignty> createState() => _EveningSovereigntyState();
}

class _EveningSovereigntyState extends State<_EveningSovereignty>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl,
      _growCtrl,
      _starCtrl,
      _pCtrl,
      _punchCtrl,
      _shockCtrl,
      _revealCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _growCtrl.animateTo(widget.progress);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _revealCtrl.forward();
    });
  }

  @override
  void didUpdateWidget(_EveningSovereignty old) {
    super.didUpdateWidget(old);
    _growCtrl.animateTo(widget.progress);
    if (widget.tapCount > old.tapCount) {
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _revealCtrl,
      ]),
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final pulse = _pulseCtrl.value;
        final star = _starCtrl.value;
        final reveal = _revealCtrl.value;
        final p = _growCtrl.value;

        // 5 key English phrases revealed progressively
        final segments = [
          (en: 'We have entered the evening', big: false),
          (en: 'The Kingdom belongs to Allah', big: true),
          (en: 'None worthy of worship but Allah alone', big: false),
          (en: 'All praise · He is All-Powerful over everything', big: false),
          (en: 'We ask for the good of this night', big: false),
        ];

        return SizedBox(
          height: 260,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background painter — night sky + crescent + stars
              CustomPaint(
                painter: _EveningSovereigntyPainter(
                  pulse: pulse,
                  star: star,
                  p: p,
                ),
              ),
              // Text segments — English only, compact
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < segments.length; i++) ...[
                      _buildLine(segments[i], reveal, i, segments.length, isDark),
                      if (i < segments.length - 1) const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLine(
    ({String en, bool big}) seg,
    double reveal,
    int idx,
    int total,
    bool isDark,
  ) {
    final segReveal = ((reveal - (idx / total) * 0.55) / 0.45).clamp(0.0, 1.0);
    final accent = isDark ? const Color(0xFFD4AF37) : const Color(0xFF2A2410);
    final bodyColor = isDark ? const Color(0xFFB8C8D8) : const Color(0xFF1E293B);

    return AnimatedOpacity(
      opacity: segReveal.clamp(0.0, 1.0),
      duration: const Duration(milliseconds: 400),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: seg.big ? 14 : 8,
          vertical: seg.big ? 8 : 4,
        ),
        decoration:
            seg.big
                ? BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                    width: 1,
                  ),
                )
                : null,
        child: Text(
          seg.en,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: seg.big ? 15 : 12.5,
            fontWeight: seg.big ? FontWeight.w700 : FontWeight.w400,
            color: seg.big ? accent : bodyColor,
            letterSpacing: seg.big ? 0.3 : 0.1,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _EveningSovereigntyPainter extends CustomPainter {
  final double pulse, star, p;
  const _EveningSovereigntyPainter({
    required this.pulse,
    required this.star,
    required this.p,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dark navy gradient background
    final bgPaint =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF060C16), Color(0xFF0C1624), Color(0xFF0F1E34)],
          ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Crescent moon — top right
    final mx = w * 0.83;
    final my = h * 0.20;
    final mr = 26.0;
    final moonAlpha = (0.55 + pulse * 0.25).clamp(0.0, 1.0);
    // outer disc
    canvas.drawCircle(
      Offset(mx, my),
      mr,
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: moonAlpha * 0.90),
    );
    // crescent cutout
    canvas.drawCircle(
      Offset(mx + mr * 0.44, my - mr * 0.08),
      mr * 0.80,
      Paint()..color = const Color(0xFF060C16),
    );
    // soft glow around moon
    canvas.drawCircle(
      Offset(mx, my),
      mr * 2.0,
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: pulse * 0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Stars — scattered
    final starPos = [
      (0.06, 0.08),
      (0.20, 0.05),
      (0.36, 0.09),
      (0.52, 0.03),
      (0.66, 0.13),
      (0.13, 0.22),
      (0.42, 0.18),
      (0.70, 0.28),
      (0.92, 0.08),
      (0.04, 0.35),
      (0.28, 0.30),
      (0.58, 0.26),
      (0.87, 0.38),
      (0.10, 0.45),
      (0.48, 0.42),
      (0.76, 0.15),
      (0.33, 0.42),
    ];
    final sp = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < starPos.length; i++) {
      final (sx, sy) = starPos[i];
      final flicker = (star + i * 0.17) % 1.0;
      sp.color = Colors.white.withValues(
        alpha: (0.25 + flicker * 0.45).clamp(0.0, 1.0) * 0.75,
      );
      canvas.drawCircle(Offset(w * sx, h * sy), 1.2 + (i % 3) * 0.5, sp);
    }

    // Horizon glow — bottom warm edge
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.62, w, h * 0.38),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFF1C2D4A).withValues(alpha: 0.55),
            const Color(0xFF1C2D4A).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.62, w, h * 0.38)),
    );

    // Completion gold wash
    if (p >= 1.0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      );
    }
  }

  @override
  bool shouldRepaint(_EveningSovereigntyPainter old) =>
      old.pulse != pulse || old.star != star || old.p != p;
}

// =============================================================================
// "It will suffice you in all respects." — Abu Dawud 5082
// Refuge from: inner whispers, fear, and the whispering devil
// Theme: warm amber/cream — surrender, refuge, divine protection
// =============================================================================
class _DuaHands extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _DuaHands({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_DuaHands> createState() => _DuaHandsState();
}

class _DuaHandsState extends State<_DuaHands> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _glowCtrl, _shimCtrl;
  late Animation<double> _pulse, _grow, _glow;
  double _prevProgress = 0.0;

  // Structured around the 3 types of refuge sought in Surah An-Nas
  static const _segments = [
    (text: 'Say: I seek refuge', color: 0),
    (text: 'in the Lord of Mankind', color: 0),
    (text: 'the King of Mankind', color: 1),
    (text: 'the God of Mankind ,', color: 1),
    (text: 'from the whispering devil', color: 1),
    (text: 'He retreats when you remember Allah.', color: 2),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 0.28,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _shimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void didUpdateWidget(_DuaHands old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _glowCtrl.dispose();
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _glowCtrl,
        _shimCtrl,
      ]),
      builder: (_, __) {
        final progress = _grow.value;
        return SizedBox(
          height: 260,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors:
                        isDark
                            ? [
                              const Color(0xFF120A00),
                              const Color(0xFF1C1000),
                              const Color(0xFF120A00),
                            ]
                            : [
                              const Color(0xFFFFFBF0),
                              const Color(0xFFFFF6E0),
                              const Color(0xFFFEEFCA),
                            ],
                  ),
                ),
              ),
              // Radial glow
              Center(
                child: Container(
                  width: 180 * _pulse.value,
                  height: 180 * _pulse.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(
                          0xFFFFBF00,
                        ).withValues(alpha: 0.07 * _glow.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Dot specks
              CustomPaint(
                painter: _NasDotPainter(phase: _shimCtrl.value, isDark: isDark),
              ),
              // Emoji icon — 🤲 dua hands, monochrome tinted. Always full
              // opacity; previously it ghosted to 15% before the user tapped.
              Positioned(
                top: 14,
                left: 0,
                right: 0,
                child: Center(
                  child: Opacity(
                    opacity: 0.92,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        isDark
                            ? const Color(0xFFFFD060)
                            : const Color(0xFF92400E),
                        BlendMode.srcIn,
                      ),
                      child: const Text(
                        '\u{1F932}',
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                ),
              ),
              // Text segments
              Padding(
                padding: const EdgeInsets.only(
                  top: 58,
                  left: 20,
                  right: 20,
                  bottom: 14,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < _segments.length; i++) ...[
                      _buildSegment(i, progress, isDark),
                      if (i < _segments.length - 1)
                        SizedBox(height: i == 1 ? 8 : 2),
                    ],
                  ],
                ),
              ),
              // Completion bar
              if (widget.isComplete)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(
                            0xFFFFBF00,
                          ).withValues(alpha: _glow.value * 0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegment(int i, double progress, bool isDark) {
    final seg = _segments[i];
    // Text is always fully visible from frame 1 — no progress-tied fade.
    // (Previously each segment revealed itself only as the user counted,
    // which left the card looking blank with ghost text before completion.)
    const double opacity = 1.0;

    Color color;
    double fontSize;
    FontWeight weight;

    if (seg.color == 2) {
      color = isDark ? const Color(0xFFFFD060) : const Color(0xFF78350F);
      fontSize = 16.0 * _pulse.value;
      weight = FontWeight.w800;
    } else if (seg.color == 1) {
      color = (isDark ? const Color(0xFFFFD060) : const Color(0xFF92400E))
          .withValues(alpha: 0.80);
      fontSize = 13.5;
      weight = FontWeight.w500;
    } else {
      color = (isDark ? Colors.white : const Color(0xFF1C1107)).withValues(
        alpha: isDark ? 0.88 : 0.80,
      );
      fontSize = 15.5;
      weight = FontWeight.w700;
    }

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 440),
      child: Text(
        seg.text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          letterSpacing: 0.15,
          height: 1.45,
        ),
      ),
    );
  }
}

// Warm amber dot/star speckle background
class _NasDotPainter extends CustomPainter {
  final double phase;
  final bool isDark;
  const _NasDotPainter({required this.phase, required this.isDark});
  static const _pts = [
    (0.08, 0.08, 1.0),
    (0.92, 0.07, 0.9),
    (0.18, 0.90, 0.8),
    (0.82, 0.88, 1.0),
    (0.50, 0.06, 0.9),
    (0.12, 0.50, 0.8),
    (0.88, 0.48, 0.9),
    (0.38, 0.82, 1.0),
    (0.65, 0.68, 0.8),
    (0.26, 0.24, 1.0),
    (0.74, 0.20, 0.9),
    (0.50, 0.94, 0.8),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (int i = 0; i < _pts.length; i++) {
      final (rx, ry, r) = _pts[i];
      final t = (math.sin((phase + i * 0.26) * math.pi * 2) * 0.5 + 0.5);
      p.color = (isDark ? const Color(0xFFFFD060) : const Color(0xFFE88B20))
          .withValues(alpha: t * 0.14);
      canvas.drawCircle(Offset(rx * size.width, ry * size.height), r, p);
    }
  }

  @override
  bool shouldRepaint(_NasDotPainter o) =>
      o.phase != phase || o.isDark != isDark;
}

// =============================================================================
// Al-Falaq Shield — Surah Al-Falaq, 3x at dawn & dusk (morning_10/evening_10)
// "It will suffice you in all respects." — Abu Dawud 5082
// 4 evils repelled: creation, darkness, blowers in knots, envy
// Theme: deep indigo/violet (night protection)
// =============================================================================
class _AlFalaqShield extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _AlFalaqShield({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_AlFalaqShield> createState() => _AlFalaqShieldState();
}

class _AlFalaqShieldState extends State<_AlFalaqShield>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _glowCtrl, _shimCtrl;
  late Animation<double> _pulse, _grow, _glow;
  double _prevProgress = 0.0;

  // Each line reveals progressively — 4 evils + the core declaration
  static const _segments = [
    (text: 'Seek refuge in the Lord of Daybreak', color: 0),
    (text: 'from evil of what He created', color: 1),
    (text: 'from darkness when it settles', color: 1),
    (text: 'from blowers in knots', color: 1),
    (text: 'from envy when it strikes ,', color: 1),
    (text: 'Sufficed in all respects.', color: 2),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 0.25,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _shimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void didUpdateWidget(_AlFalaqShield old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _glowCtrl.dispose();
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _glowCtrl,
        _shimCtrl,
      ]),
      builder: (_, __) {
        final progress = _grow.value;
        return SizedBox(
          height: 260,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Deep indigo/violet background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors:
                        isDark
                            ? [
                              const Color(0xFF0D0B1E),
                              const Color(0xFF130E2A),
                              const Color(0xFF0A0816),
                            ]
                            : [
                              const Color(0xFFF5F3FF),
                              const Color(0xFFEDE9FE),
                              const Color(0xFFF0EBFF),
                            ],
                  ),
                ),
              ),
              // Soft radial glow — violet
              Center(
                child: Container(
                  width: 220 * _pulse.value,
                  height: 220 * _pulse.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(
                          0xFF7C3AED,
                        ).withValues(alpha: 0.07 * _glow.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Star specks
              CustomPaint(
                painter: _FalaqDotPainter(
                  phase: _shimCtrl.value,
                  isDark: isDark,
                ),
              ),
              // Moon crescent icon
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CustomPaint(
                      painter: _CrescentIconPainter(
                        color: (isDark
                                ? const Color(0xFFA78BFA)
                                : const Color(0xFF4C1D95))
                            .withValues(
                              alpha: (0.20 + progress * 0.75).clamp(0.0, 1.0),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              // Text segments
              Padding(
                padding: const EdgeInsets.only(
                  top: 62,
                  left: 20,
                  right: 20,
                  bottom: 14,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < _segments.length; i++) ...[
                      _buildSegment(i, progress, isDark),
                      if (i < _segments.length - 1)
                        SizedBox(height: i == 0 ? 8 : 2),
                    ],
                  ],
                ),
              ),
              // Completion bar
              if (widget.isComplete)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(
                            0xFF7C3AED,
                          ).withValues(alpha: _glow.value * 0.70),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegment(int i, double progress, bool isDark) {
    final seg = _segments[i];
    // Text always fully visible from frame 1.
    const double opacity = 1.0;

    Color color;
    double fontSize;
    FontWeight weight;

    if (seg.color == 2) {
      // Final declaration — large, glowing violet
      color = isDark ? const Color(0xFFA78BFA) : const Color(0xFF4C1D95);
      fontSize = 20.0 * _pulse.value;
      weight = FontWeight.w900;
    } else if (seg.color == 1) {
      // The 4 evils — softer, muted
      color = (isDark ? const Color(0xFFDDD6FE) : const Color(0xFF6D28D9))
          .withValues(alpha: 0.85);
      fontSize = 13.5;
      weight = FontWeight.w500;
    } else {
      // Opening declaration — white/dark, prominent
      color = (isDark ? Colors.white : const Color(0xFF1E1B4B)).withValues(
        alpha: isDark ? 0.90 : 0.80,
      );
      fontSize = 15.5;
      weight = FontWeight.w700;
    }

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 440),
      child: Text(
        seg.text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          letterSpacing: 0.15,
          height: 1.45,
        ),
      ),
    );
  }
}

// Crescent moon icon for Al-Falaq (night / daybreak)
class _CrescentIconPainter extends CustomPainter {
  final Color color;
  const _CrescentIconPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path();
    // Outer circle
    path.addOval(
      Rect.fromCircle(center: Offset(w * 0.50, h * 0.50), radius: w * 0.45),
    );
    // Subtract shifted circle to create crescent
    final erasePath = Path();
    erasePath.addOval(
      Rect.fromCircle(center: Offset(w * 0.65, h * 0.42), radius: w * 0.40),
    );
    final crescent = Path.combine(PathOperation.difference, path, erasePath);
    canvas.drawPath(
      crescent,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_CrescentIconPainter o) => o.color != color;
}

// Dot painter for Al-Falaq — cool violet/indigo dots
class _FalaqDotPainter extends CustomPainter {
  final double phase;
  final bool isDark;
  const _FalaqDotPainter({required this.phase, required this.isDark});
  static const _pts = [
    (0.07, 0.07, 1.0),
    (0.93, 0.06, 0.9),
    (0.20, 0.90, 0.8),
    (0.80, 0.88, 1.0),
    (0.50, 0.08, 0.9),
    (0.12, 0.52, 0.8),
    (0.88, 0.50, 1.0),
    (0.38, 0.80, 0.9),
    (0.67, 0.65, 0.8),
    (0.25, 0.28, 1.0),
    (0.75, 0.20, 0.9),
    (0.52, 0.94, 0.8),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (int i = 0; i < _pts.length; i++) {
      final (rx, ry, r) = _pts[i];
      final twink = (math.sin((phase + i * 0.25) * math.pi * 2) * 0.5 + 0.5);
      p.color = (isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED))
          .withValues(alpha: twink * 0.18);
      canvas.drawCircle(Offset(rx * size.width, ry * size.height), r, p);
    }
  }

  @override
  bool shouldRepaint(_FalaqDotPainter o) =>
      o.phase != phase || o.isDark != isDark;
}

// =============================================================================
// Burden â€” 2:286: Allah does not burden a soul beyond capacity (morning_8/evening_8)
// Every dua in this verse â€” Allah answered: "I have done so"
// =============================================================================
class _BaqarahBurden extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _BaqarahBurden({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_BaqarahBurden> createState() => _BaqarahBurdenState();
}

class _BaqarahBurdenState extends State<_BaqarahBurden>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _glowCtrl, _shimCtrl;
  late Animation<double> _pulse, _grow, _glow;
  double _prevProgress = 0.0;

  // Text segments â€” structured around the verse's message
  static const _segments = [
    (text: 'Allah does not burden', big: false, color: 0),
    (text: 'a soul', big: false, color: 0),
    (text: 'beyond what it can bear', big: false, color: 0),
    (text: 'Every dua in this verse:', big: false, color: 1),
    (text: 'Allah answered:', big: false, color: 1),
    (text: '"I have done so."', big: true, color: 2),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 0.25,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _shimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
  }

  @override
  void didUpdateWidget(_BaqarahBurden old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _glowCtrl.dispose();
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _glowCtrl,
        _shimCtrl,
      ]),
      builder: (_, __) {
        final progress = _grow.value;
        return SizedBox(
          height: 260,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        isDark
                            ? [
                              const Color(0xFF0F1F14),
                              const Color(0xFF142B1C),
                              const Color(0xFF0D1A10),
                            ]
                            : [
                              const Color(0xFFF0FDF4),
                              const Color(0xFFECFDF5),
                              const Color(0xFFF7FEF9),
                            ],
                  ),
                ),
              ),
              // Soft radial glow
              Center(
                child: Container(
                  width: 200 * _pulse.value,
                  height: 200 * _pulse.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(
                          0xFFFFC83D,
                        ).withValues(alpha: 0.06 * _glow.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Star specks
              CustomPaint(
                painter: _BurdenDotPainter(
                  phase: _shimCtrl.value,
                  isDark: isDark,
                ),
              ),
              // Icon â€” gentle scale/balance or open hands
              Positioned(
                top: 18,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 44,
                    height: 32,
                    child: CustomPaint(
                      painter: _ScaleIconPainter(
                        color: (isDark
                                ? const Color(0xFFFFC83D)
                                : const Color(0xFFFFC83D))
                            .withValues(
                              alpha: (0.20 + progress * 0.75).clamp(0.0, 1.0),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              // Text
              Padding(
                padding: const EdgeInsets.only(
                  top: 70,
                  left: 22,
                  right: 22,
                  bottom: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < _segments.length; i++) ...[
                      _buildSegment(i, progress, isDark),
                      if (i < _segments.length - 1)
                        SizedBox(height: i == 2 ? 10 : 3),
                    ],
                  ],
                ),
              ),
              // Completion bar
              if (widget.isComplete)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(
                            0xFFFFC83D,
                          ).withValues(alpha: _glow.value * 0.70),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegment(int i, double progress, bool isDark) {
    final seg = _segments[i];
    // Text always fully visible from frame 1.
    const double opacity = 1.0;

    Color color;
    double fontSize;
    FontWeight weight;
    double? letterSpacing;

    if (seg.color == 2) {
      // "I have done so" — green accent, larger, pulsing
      color = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
      fontSize = 22.0 * _pulse.value;
      weight = FontWeight.w900;
      letterSpacing = 0.8;
    } else if (seg.color == 1) {
      // Transition text — muted green/teal
      color = (isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534))
          .withValues(alpha: 0.88);
      fontSize = 15;
      weight = FontWeight.w600;
      letterSpacing = 0.3;
    } else {
      // Body text
      color = (isDark ? Colors.white : const Color(0xFF1E293B)).withValues(
        alpha: isDark ? 0.80 : 0.75,
      );
      fontSize = seg.big ? 17 : 15.5;
      weight = FontWeight.w500;
      letterSpacing = 0.1;
    }

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 440),
      child: Text(
        seg.text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          letterSpacing: letterSpacing ?? 0.1,
          height: 1.45,
        ),
      ),
    );
  }
}

// Simple scale/balance icon â€” two pans hanging from a bar
class _ScaleIconPainter extends CustomPainter {
  final Color color;
  const _ScaleIconPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
    // Horizontal bar
    canvas.drawLine(Offset(w * 0.10, h * 0.35), Offset(w * 0.90, h * 0.35), p);
    // Centre pivot
    canvas.drawLine(Offset(w * 0.50, h * 0.35), Offset(w * 0.50, h * 0.08), p);
    canvas.drawCircle(Offset(w * 0.50, h * 0.08), 3.0, Paint()..color = color);
    // Left arm strings + pan
    canvas.drawLine(Offset(w * 0.18, h * 0.35), Offset(w * 0.10, h * 0.75), p);
    canvas.drawLine(Offset(w * 0.10, h * 0.85), Offset(w * 0.28, h * 0.85), p);
    canvas.drawLine(
      Offset(w * 0.10, h * 0.75),
      Offset(w * 0.10, h * 0.85),
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(w * 0.28, h * 0.75),
      Offset(w * 0.28, h * 0.85),
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(Offset(w * 0.28, h * 0.35), Offset(w * 0.28, h * 0.75), p);
    // Right arm strings + pan
    canvas.drawLine(Offset(w * 0.72, h * 0.35), Offset(w * 0.72, h * 0.75), p);
    canvas.drawLine(
      Offset(w * 0.72, h * 0.75),
      Offset(w * 0.72, h * 0.85),
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(w * 0.90, h * 0.75),
      Offset(w * 0.90, h * 0.85),
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(Offset(w * 0.72, h * 0.85), Offset(w * 0.90, h * 0.85), p);
    canvas.drawLine(Offset(w * 0.82, h * 0.35), Offset(w * 0.90, h * 0.75), p);
  }

  @override
  bool shouldRepaint(_ScaleIconPainter o) => o.color != color;
}

class _BurdenDotPainter extends CustomPainter {
  final double phase;
  final bool isDark;
  const _BurdenDotPainter({required this.phase, required this.isDark});
  static const _pts = [
    (0.08, 0.08, 0.9),
    (0.92, 0.07, 1.0),
    (0.22, 0.88, 0.8),
    (0.78, 0.85, 1.1),
    (0.50, 0.10, 1.0),
    (0.15, 0.50, 0.8),
    (0.85, 0.48, 0.9),
    (0.40, 0.78, 1.0),
    (0.65, 0.62, 0.8),
    (0.28, 0.25, 1.1),
    (0.72, 0.22, 0.9),
    (0.55, 0.93, 1.0),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (int i = 0; i < _pts.length; i++) {
      final (rx, ry, r) = _pts[i];
      final tw = (math.sin((phase + i * 0.22) * math.pi * 2) * 0.5 + 0.5);
      p.color = const Color(0xFFFFC83D).withValues(alpha: tw * 0.10);
      canvas.drawCircle(Offset(rx * size.width, ry * size.height), r, p);
    }
  }

  @override
  bool shouldRepaint(_BurdenDotPainter o) => o.phase != phase;
}

// =============================================================================
// Dawn & Dusk â€” Surah Al-Ikhlas 3x recited at dawn and dusk (morning_9/evening_9)
// Split screen: left half = dawn (warm sunrise), right half = dusk (cool twilight)
// =============================================================================
// =============================================================================
// Quran Complete — Surah Al-Ikhlas (morning_9 / evening_9)
// Text-based animation: open Quran book + animated ×3 counter + stars.
// Virtue: reciting Al-Ikhlas 3× = reading the whole Quran (Bukhari & Muslim)
// =============================================================================
class _QuranComplete extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _QuranComplete({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_QuranComplete> createState() => _QuranCompleteState();
}

class _QuranCompleteState extends State<_QuranComplete>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl,
      _growCtrl,
      _starCtrl,
      _pCtrl,
      _punchCtrl,
      _shockCtrl,
      _countCtrl;
  late Animation<double> _pulse, _grow, _star, _punch, _shock;
  double _prevProgress = 0.0;
  int _tapSnapshot = 0;
  final _rng = math.Random(42);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _pCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _countCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOut);
    _star = CurvedAnimation(parent: _starCtrl, curve: Curves.easeInOut);
    _punch = CurvedAnimation(parent: _punchCtrl, curve: Curves.easeOutBack);
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _growCtrl.animateTo(widget.progress);
  }

  @override
  void didUpdateWidget(_QuranComplete old) {
    super.didUpdateWidget(old);
    if ((widget.progress - _prevProgress).abs() > 0.001) {
      _growCtrl.animateTo(
        widget.progress,
        duration: const Duration(milliseconds: 400),
      );
      _prevProgress = widget.progress;
    }
    if (widget.tapCount != _tapSnapshot) {
      _tapSnapshot = widget.tapCount;
      _pCtrl
        ..reset()
        ..forward();
      _punchCtrl
        ..reset()
        ..forward();
      _shockCtrl
        ..reset()
        ..forward();
      _countCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _starCtrl.dispose();
    _pCtrl.dispose();
    _punchCtrl.dispose();
    _shockCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _starCtrl,
        _pCtrl,
        _punchCtrl,
        _shockCtrl,
        _countCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 260,
            child: CustomPaint(
              painter: _QuranCompletePainter(
                progress: _grow.value,
                pulse: _pulse.value,
                star: _star.value,
                particles: _pCtrl.value,
                punch: _punch.value,
                shock: _shock.value,
                countPhase: _countCtrl.value,
                tapCount: widget.tapCount,
                isComplete: widget.isComplete,
                rng: _rng,
              ),
            ),
          ),
    );
  }
}

class _QuranCompletePainter extends CustomPainter {
  final double progress, pulse, star, particles, punch, shock, countPhase;
  final int tapCount;
  final bool isComplete;
  final math.Random rng;
  const _QuranCompletePainter({
    required this.progress,
    required this.pulse,
    required this.star,
    required this.particles,
    required this.punch,
    required this.shock,
    required this.countPhase,
    required this.tapCount,
    required this.isComplete,
    required this.rng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;

    // Background — deep indigo → dark teal
    final bgPaint =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C2E), Color(0xFF0A2A2A), Color(0xFF0D4F3F)],
          ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Progress ring
    final arcRadius = 66.0 + 5.0 * pulse;
    final trackPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(cx, cy - 12), arcRadius, trackPaint);
    if (progress > 0.01) {
      final arcPaint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round
            ..shader = SweepGradient(
              startAngle: -math.pi / 2,
              endAngle: -math.pi / 2 + 2 * math.pi * progress,
              colors: const [Color(0xFFFFC83D), Color(0xFFFFC83D)],
            ).createShader(
              Rect.fromCircle(center: Offset(cx, cy - 12), radius: arcRadius),
            );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy - 12), radius: arcRadius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    }

    // Glow behind book
    canvas.drawCircle(
      Offset(cx, cy - 12),
      (45.0 + 18.0 * pulse) * (0.5 + 0.5 * progress),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28)
        ..color = const Color(
          0xFFFFC83D,
        ).withValues(alpha: 0.16 + 0.12 * pulse),
    );

    // Open Quran book
    final punchScale = 1.0 + 0.10 * (1.0 - punch) * punch * 4;
    canvas.save();
    canvas.translate(cx, cy - 12);
    canvas.scale(punchScale);

    const bW = 58.0, bH = 48.0;
    final bTop = -bH / 2;

    // Left page
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(-bW / 2, bTop, bW / 2 - 1.5, bH),
        topLeft: const Radius.circular(4),
        bottomLeft: const Radius.circular(4),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFC83D).withValues(alpha: 0.88),
            const Color(0xFFFFC83D).withValues(alpha: 0.88),
          ],
        ).createShader(Rect.fromLTWH(-bW / 2, bTop, bW / 2, bH)),
    );

    // Right page
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(1.5, bTop, bW / 2 - 1.5, bH),
        topRight: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF14B8A6).withValues(alpha: 0.88),
            const Color(0xFF0D9488).withValues(alpha: 0.88),
          ],
        ).createShader(Rect.fromLTWH(1.5, bTop, bW / 2, bH)),
    );

    // Spine
    canvas.drawRect(
      Rect.fromLTWH(-1.5, bTop, 3, bH),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );

    // Page lines
    final linePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.22)
          ..strokeWidth = 0.8;
    for (int i = 1; i <= 4; i++) {
      final ly = bTop + bH / 5 * i;
      canvas.drawLine(Offset(-bW / 2 + 4, ly), Offset(-3, ly), linePaint);
      canvas.drawLine(Offset(3, ly), Offset(bW / 2 - 4, ly), linePaint);
    }
    canvas.restore();

    // Shock ring on tap
    if (shock > 0.001) {
      canvas.drawCircle(
        Offset(cx, cy - 12),
        arcRadius * 0.7 + arcRadius * 0.7 * shock,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - shock)
          ..color = const Color(
            0xFFFFC83D,
          ).withValues(alpha: (1 - shock) * 0.55),
      );
    }

    // ×N counter badge (top-right of ring)
    final count = tapCount.clamp(0, 99);
    final countAlpha =
        (countPhase > 0.0
            ? 1.0 - (countPhase - 0.5).clamp(0.0, 0.5) * 2
            : 0.85);
    final countScale = 1.0 + 0.28 * math.sin(countPhase * math.pi);
    canvas.save();
    canvas.translate(cx + arcRadius * 0.74, cy - 12 - arcRadius * 0.74);
    canvas.scale(countScale);
    final cTp = TextPainter(
      text: TextSpan(
        text: '×$count',
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFFFC83D).withValues(alpha: countAlpha),
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    cTp.paint(canvas, Offset(-cTp.width / 2, -cTp.height / 2));
    canvas.restore();

    // "×3 = reading the whole Quran" label
    if (progress > 0.05) {
      final eqA = ((progress - 0.05) / 0.3).clamp(0.0, 1.0);
      final eqTp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '×3  ',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFFC83D).withValues(alpha: eqA),
              ),
            ),
            TextSpan(
              text: '= reading the whole Quran',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: eqA * 0.78),
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w - 40);
      eqTp.paint(canvas, Offset((w - eqTp.width) / 2, cy + arcRadius + 6));
    }

    // Completion glow + Arabic label
    if (isComplete) {
      canvas.drawCircle(
        Offset(cx, cy - 12),
        arcRadius + 18,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
          ..color = const Color(0xFFFFC83D).withValues(alpha: 0.32),
      );
    }
  }

  @override
  bool shouldRepaint(_QuranCompletePainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.star != star ||
      o.particles != particles ||
      o.punch != punch ||
      o.shock != shock ||
      o.countPhase != countPhase ||
      o.tapCount != tapCount ||
      o.isComplete != isComplete;
}

class _DawnDusk extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;
  const _DawnDusk({
    required this.progress,
    required this.isComplete,
    required this.tapCount,
    this.pointsToday = 0,
  });
  @override
  State<_DawnDusk> createState() => _DawnDuskState();
}

class _DawnDuskState extends State<_DawnDusk> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _glowCtrl, _shimCtrl;
  late Animation<double> _pulse, _grow, _glow;
  double _prevProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _shimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void didUpdateWidget(_DawnDusk old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _growCtrl.dispose();
    _glowCtrl.dispose();
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _growCtrl,
        _glowCtrl,
        _shimCtrl,
      ]),
      builder:
          (_, __) => SizedBox(
            height: 260,
            child: CustomPaint(
              painter: _DawnDuskPainter(
                progress: _grow.value,
                pulse: _pulse.value,
                glowPhase: _glow.value,
                starPhase: _shimCtrl.value,
                isComplete: widget.isComplete,
              ),
            ),
          ),
    );
  }
}

class _DawnDuskPainter extends CustomPainter {
  final double progress, pulse, glowPhase, starPhase;
  final bool isComplete;
  const _DawnDuskPainter({
    required this.progress,
    required this.pulse,
    required this.glowPhase,
    required this.starPhase,
    required this.isComplete,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final mid = w / 2;
    // Illustration always fully painted from frame 1 (was 0.18..1.0 fade
    // on tap progress, leaving the dawn/dusk artwork + labels ghosted
    // before completion).
    const double alpha = 1.0;

    // â”€â”€ LEFT HALF: DAWN â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final dawnRect = Rect.fromLTWH(0, 0, mid, h);
    canvas.save();
    canvas.clipRect(dawnRect);

    // Dawn sky gradient
    canvas.drawRect(
      dawnRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F172A), // deep navy at top
            const Color(0xFF1E3A5F), // navy-blue
            const Color(0xFF7E3517), // rust horizon
            const Color(0xFFD4621A), // orange sunrise
            const Color(0xFFFBBF85), // warm amber ground
          ],
          stops: const [0.0, 0.25, 0.55, 0.78, 1.0],
        ).createShader(dawnRect),
    );

    // Dawn sun â€” rising, lower-left
    final sunX = mid * 0.62;
    final sunY = h * 0.65;
    final sunR = 18.0 * pulse;
    // Glow
    canvas.drawCircle(
      Offset(sunX, sunY),
      sunR * 2.8,
      Paint()
        ..color = const Color(
          0xFFFF8C00,
        ).withValues(alpha: alpha * 0.20 * glowPhase)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawCircle(
      Offset(sunX, sunY),
      sunR * 1.7,
      Paint()
        ..color = const Color(0xFFFFBF00).withValues(alpha: alpha * 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Sun disc
    canvas.drawCircle(
      Offset(sunX, sunY),
      sunR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF0A0).withValues(alpha: alpha),
            const Color(0xFFFF8C00).withValues(alpha: alpha),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(sunX, sunY), radius: sunR),
        ),
    );

    // Dawn horizon glow line
    final hY = h * 0.72;
    canvas.drawRect(
      Rect.fromLTWH(0, hY - 1, mid, 3),
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFFF8C00).withValues(alpha: alpha * 0.0),
            const Color(0xFFFF8C00).withValues(alpha: alpha * 0.60),
            const Color(0xFFFF8C00).withValues(alpha: alpha * 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, hY - 1, mid, 3)),
    );

    // Dawn label
    _drawLabel(
      canvas,
      'DAWN',
      mid * 0.50,
      h * 0.14,
      const Color(0xFFFFE9B8),
      alpha * 0.90,
      13.0,
    );

    // "3x" badge

    canvas.restore();

    // â”€â”€ CENTRE DIVIDER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    canvas.drawRect(
      Rect.fromLTWH(mid - 1, 0, 2, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFBF00).withValues(alpha: alpha * 0.0),
            const Color(0xFFFFBF00).withValues(alpha: alpha * 0.55),
            const Color(0xFF818CF8).withValues(alpha: alpha * 0.50),
            const Color(0xFF818CF8).withValues(alpha: alpha * 0.0),
          ],
        ).createShader(Rect.fromLTWH(mid - 1, 0, 2, h)),
    );

    // â”€â”€ RIGHT HALF: DUSK â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final duskRect = Rect.fromLTWH(mid, 0, mid, h);
    canvas.save();
    canvas.clipRect(duskRect);

    // Dusk sky gradient
    canvas.drawRect(
      duskRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0F1E), // near-black
            const Color(0xFF12063A), // deep violet
            const Color(0xFF3B1F6E), // purple
            const Color(0xFF8B2FC9), // violet horizon
            const Color(0xFFD78ADB), // mauve ground
          ],
          stops: const [0.0, 0.22, 0.50, 0.72, 1.0],
        ).createShader(duskRect),
    );

    // Stars (dusk side) â€” more stars visible
    final starData = [
      (0.15, 0.08, 1.3),
      (0.42, 0.05, 1.0),
      (0.65, 0.12, 0.8),
      (0.28, 0.22, 0.9),
      (0.80, 0.08, 1.1),
      (0.55, 0.28, 0.7),
      (0.08, 0.35, 0.8),
      (0.90, 0.30, 1.0),
      (0.35, 0.40, 0.9),
      (0.70, 0.42, 0.8),
      (0.18, 0.55, 0.7),
      (0.88, 0.50, 1.0),
    ];
    final sp = Paint();
    for (int i = 0; i < starData.length; i++) {
      final (rx, ry, r) = starData[i];
      final twink =
          (math.sin((starPhase + i * 0.23) * math.pi * 2) * 0.5 + 0.5);
      sp.color = Colors.white.withValues(alpha: twink * alpha * 0.80);
      canvas.drawCircle(Offset(mid + rx * mid, ry * h), r, sp);
    }

    // Crescent moon â€” dusk side
    final moonX = mid + mid * 0.60;
    final moonY = h * 0.28;
    final moonR = 15.0 * pulse;
    canvas.drawCircle(
      Offset(moonX, moonY),
      moonR,
      Paint()..color = const Color(0xFFE2E8F0).withValues(alpha: alpha * 0.92),
    );
    canvas.drawCircle(
      Offset(moonX + moonR * 0.40, moonY - moonR * 0.08),
      moonR * 0.82,
      Paint()..color = const Color(0xFF3B1F6E).withValues(alpha: alpha * 0.95),
    );

    // Dusk horizon glow
    canvas.drawRect(
      Rect.fromLTWH(mid, hY - 1, mid, 3),
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF8B2FC9).withValues(alpha: alpha * 0.0),
            const Color(0xFF8B2FC9).withValues(alpha: alpha * 0.55),
            const Color(0xFF8B2FC9).withValues(alpha: alpha * 0.0),
          ],
        ).createShader(Rect.fromLTWH(mid, hY - 1, mid, 3)),
    );

    // Dusk label
    _drawLabel(
      canvas,
      'DUSK',
      mid + mid * 0.50,
      h * 0.14,
      const Color(0xFFDDD6FE),
      alpha * 0.90,
      13.0,
    );

    // "3x" badge

    canvas.restore();

    // â”€â”€ CENTRE TEXT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // Al-Ikhlas key virtue — equals reading the whole Quran.
    // Always visible from frame 1 (was gated on progress > 0.10 with a
    // 0..40% progress fade).
    {
      final tp = TextPainter(
        text: TextSpan(
          text: 'Equals the whole Quran × 3',
          style: GoogleFonts.outfit(
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.85),
            letterSpacing: 0.8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w);
      tp.paint(canvas, Offset((w - tp.width) / 2, h - 22));
    }

    // Completion shimmer line
    if (isComplete) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, 3),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFFFFBF00).withValues(alpha: glowPhase * 0.65),
              const Color(0xFF818CF8).withValues(alpha: glowPhase * 0.65),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(0, 0, w, 3)),
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    double cx,
    double cy,
    Color color,
    double alpha,
    double fontSize,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: color.withValues(alpha: alpha),
          letterSpacing: 3.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_DawnDuskPainter o) =>
      o.progress != progress ||
      o.pulse != pulse ||
      o.glowPhase != glowPhase ||
      o.starPhase != starPhase ||
      o.isComplete != isComplete;
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar button & divider for the floating action bar
// ─────────────────────────────────────────────────────────────────────────────
Widget _toolbarDivider(bool isDark) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8),
  child: Container(
    height: 1,
    width: 28,
    color:
        isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.06),
  ),
);

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool filled;
  final bool isDark;
  final VoidCallback onTap;

  const _ToolbarBtn({
    required this.icon,
    required this.color,
    this.filled = false,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color.withValues(alpha: 0.14) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 21, color: color),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Azkar Progress Line — slim segmented bar in AppBar bottom
// ─────────────────────────────────────────────────────────────────────────────
class _AzkarProgressLine extends StatelessWidget {
  final List<_Azkar> azkars;
  final Map<String, int> counts;
  final int currentIndex;
  final _DhikrScreenState parentState;

  const _AzkarProgressLine({
    required this.azkars,
    required this.counts,
    required this.currentIndex,
    required this.parentState,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: CustomPaint(
        size: Size(MediaQuery.of(context).size.width, 10),
        painter: _ProgressLinePainter(
          total: azkars.length,
          currentIndex: currentIndex,
          completedFlags: List.generate(azkars.length, (i) {
            final a = azkars[i];
            // Check both: currently at target OR previously completed (count resets after completion)
            final c = counts[a.id] ?? 0;
            final t = parentState._getTarget(a.id, a.recommendedCount);
            return c >= t || parentState._completedIds.contains(a.id);
          }),
        ),
      ),
    );
  }
}

class _ProgressLinePainter extends CustomPainter {
  final int total;
  final int currentIndex;
  final List<bool> completedFlags;

  const _ProgressLinePainter({
    required this.total,
    required this.currentIndex,
    required this.completedFlags,
  });

  // Y4 honey theme — one color family for the whole bar.
  static const _doneColor    = Color(0xFFD89A1E); // Y4.honeyDeep
  static const _currentColor = Color(0xFFFFC83D); // Y4.honey (brighter)
  static const _pendingColor = Color(0xFFF4E5B0); // Y4.track (soft honey)

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final w = size.width;
    final h = size.height;
    final segW = w / total;
    const gap = 2.0;
    final radius = Radius.circular(h / 2); // pill-shaped segments

    for (int i = 0; i < total; i++) {
      final x = i * segW + gap / 2;
      final sW = segW - gap;
      if (sW <= 0) continue;

      final done = completedFlags[i];
      final isCurrent = i == currentIndex;

      final rect =
          RRect.fromRectAndRadius(Rect.fromLTWH(x, 0, sW, h), radius);

      Color fill;
      if (done) {
        fill = _doneColor;
      } else if (isCurrent) {
        fill = _currentColor;
      } else {
        fill = _pendingColor;
      }
      canvas.drawRRect(rect, Paint()..color = fill);

      // Subtle glow under the active segment so it stands out without
      // breaking the single-color theme.
      if (isCurrent && !done) {
        canvas.drawRRect(
          rect.inflate(2),
          Paint()
            ..color = _currentColor.withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        // Re-paint the segment on top of the blur for crisp edges.
        canvas.drawRRect(rect, Paint()..color = _currentColor);
      }
    }
  }

  @override
  bool shouldRepaint(_ProgressLinePainter o) =>
      o.total != total ||
      o.currentIndex != currentIndex ||
      !_listEquals(o.completedFlags, completedFlags);

  static bool _listEquals(List<bool> a, List<bool> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// First-time hint bubble — appears once per install on the dhikr detail screen
// to tell the user that completing a dhikr animates the illustration above.
// ─────────────────────────────────────────────────────────────────────────────
class _FirstTimeHintBubble extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _FirstTimeHintBubble({required this.isDark, required this.onTap});

  @override
  State<_FirstTimeHintBubble> createState() => _FirstTimeHintBubbleState();
}

class _FirstTimeHintBubbleState extends State<_FirstTimeHintBubble>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark
        ? const Color(0xFF2A2410) // warm dark = Y4.ink
        : Y4.cream;
    final textColor = widget.isDark ? Y4.cream : Y4.ink;
    final borderColor = Y4.honey;
    final sageAccent = Y4.primary;

    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.0).animate(
          CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutBack),
        ),
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            final scale = 1.0 + (_pulseCtrl.value * 0.035);
            return Transform.scale(scale: scale, child: child);
          },
          child: GestureDetector(
            onTap: widget.onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.fromLTRB(16, 11, 18, 11),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: borderColor, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: Y4.honeyDeep.withValues(alpha: 0.22),
                        blurRadius: 20,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Y4.ink.withValues(
                          alpha: widget.isDark ? 0.45 : 0.10,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sage leaf icon — ties to the "garden" of the illustration
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: sageAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.spa_rounded,
                          size: 15,
                          color: sageAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Complete to watch your garden bloom above',
                          textAlign: TextAlign.start,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            letterSpacing: 0.1,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Downward triangle pointing at the button below
                CustomPaint(
                  size: const Size(18, 9),
                  painter: _HintArrowPainter(
                    color: bg,
                    borderColor: borderColor,
                    borderWidth: 1.4,
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

class _HintArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double borderWidth;
  _HintArrowPainter({
    required this.color,
    required this.borderColor,
    this.borderWidth = 1.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    // Fill
    canvas.drawPath(path, Paint()..color = color);
    // Side strokes only (skip the top edge so it blends into the bubble)
    final stroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, 0), Offset(size.width / 2, size.height), stroke);
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width / 2, size.height),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _HintArrowPainter old) =>
      old.color != color || old.borderColor != borderColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// Dhikr Counter Button — circular progress ring with count display
// ─────────────────────────────────────────────────────────────────────────────
class _DhikrCounterButton extends StatelessWidget {
  final int count;
  final int target;
  final bool isComplete;
  final bool isDark;

  const _DhikrCounterButton({
    required this.count,
    required this.target,
    required this.isComplete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target == 0 ? 0.0 : (count / target).clamp(0.0, 1.0);
    final teal = const Color(0xFFFFC83D);
    final green = const Color(0xFFFFC83D);

    // Responsive sizing based on screen width
    final sw = MediaQuery.of(context).size.width;
    final size =
        sw < 360
            ? 100.0
            : sw < 400
            ? 110.0
            : 120.0;
    final stroke = sw < 360 ? 4.5 : 5.5;
    final countFontSize =
        sw < 360
            ? 28.0
            : sw < 400
            ? 32.0
            : 36.0;
    final labelFontSize = sw < 360 ? 11.0 : 12.5;
    final completedWidth = sw < 360 ? 170.0 : 190.0;
    final completedHeight = sw < 360 ? 58.0 : 64.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: isComplete ? completedWidth : size,
      height: isComplete ? completedHeight : size,
      decoration: BoxDecoration(
        color:
            isComplete
                ? green
                : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
        borderRadius: BorderRadius.circular(isComplete ? 28 : size / 2),
        border:
            isComplete
                ? null
                : Border.all(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                ),
        boxShadow: [
          BoxShadow(
            color: (isComplete ? green : teal).withValues(alpha: 0.25),
            blurRadius: isComplete ? 16 : 20,
            offset: const Offset(0, 6),
          ),
          if (!isComplete)
            BoxShadow(
              color: teal.withValues(alpha: 0.08),
              blurRadius: 40,
              spreadRadius: 4,
            ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child:
          isComplete
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: completedHeight * 0.38,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Completed',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
              : Stack(
                alignment: Alignment.center,
                children: [
                  // Progress ring
                  SizedBox(
                    width: size - 8,
                    height: size - 8,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: stroke,
                      strokeCap: StrokeCap.round,
                      backgroundColor:
                          isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : teal.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(teal),
                    ),
                  ),
                  // Count text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$count',
                        style: GoogleFonts.outfit(
                          fontSize: countFontSize,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : teal,
                          height: 1.1,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: teal.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'of $target',
                          style: GoogleFonts.outfit(
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? Colors.grey.shade400
                                    : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pinned Illustration (Free-Illustration mode)
//
// Renders the same 260px illustration block that _AzkarCard normally builds,
// but as a standalone widget the PageView itemBuilder can place at the top
// of a Column so it pins while the Arabic text scrolls beneath. Calls the
// shared top-level _buildIllustration so the artwork stays in sync with the
// non-pinned path.
// ─────────────────────────────────────────────────────────────────────────────
class _PinnedIllustration extends StatelessWidget {
  final _Azkar azkar;
  final int currentCount;
  final int targetCount;
  final bool isComplete;
  final int pointsToday;
  final String? animationKeyOverride;

  const _PinnedIllustration({
    required this.azkar,
    required this.currentCount,
    required this.targetCount,
    required this.isComplete,
    required this.pointsToday,
    this.animationKeyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final key = animationKeyOverride ?? _pickIllustration(azkar.id);
    if (key == 'none') return const SizedBox.shrink();
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          _buildIllustration(
            azkarId: azkar.id,
            progress: targetCount == 0
                ? 0.0
                : (currentCount / targetCount).clamp(0.0, 1.0),
            isComplete: isComplete,
            tapCount: currentCount,
            pointsToday: pointsToday,
            animationKeyOverride: animationKeyOverride,
          ),
          if (pointsToday > 0)
            Positioned(
              bottom: 10,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SabiqCoin(size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '+$pointsToday ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF92620A),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reward Secured Toast
//
// Floating "MashaAllah! Reward Secured" pill that pops in at the top of the
// screen when any zikar is marked done. Lives on the root Overlay so it
// persists across the auto-advance page swipe — the user always sees the
// completion acknowledgment regardless of how short the admin's
// advance-delay is set. Total visible time ~1.5 s, fully self-removing.
// ─────────────────────────────────────────────────────────────────────────────
class _RewardSecuredToast extends StatefulWidget {
  final VoidCallback onDone;
  const _RewardSecuredToast({required this.onDone});

  @override
  State<_RewardSecuredToast> createState() => _RewardSecuredToastState();
}

class _RewardSecuredToastState extends State<_RewardSecuredToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _outTimer;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slide = Tween<double>(begin: -28, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
    // Hold for 950 ms after entry completes, then play exit and remove.
    _outTimer = Timer(const Duration(milliseconds: 1100), _exit);
  }

  void _exit() async {
    if (_exiting || !mounted) return;
    _exiting = true;
    await _ctrl.reverse();
    if (!mounted) return;
    widget.onDone();
  }

  @override
  void dispose() {
    _outTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Positioned(
      top: media.padding.top + 14,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return Transform.translate(
              offset: Offset(0, _slide.value),
              child: Opacity(
                opacity: _fade.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Y4.honey, Y4.honeyDeep],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                              color: Y4.honeyDeep.withValues(alpha: 0.38),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'MashaAllah! Reward Secured',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
