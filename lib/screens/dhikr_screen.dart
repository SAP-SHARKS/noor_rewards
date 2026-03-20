import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../services/xp_service.dart';
import '../services/streak_service.dart';
import '../services/live_notification_service.dart';
import '../widgets/noor_icons.dart';

// ── Arabic font options (shared with Quran screen) ────────────────────────────
typedef _ArabicFont = ({String name, String arabicPreview, TextStyle Function(double size, Color color, double height, FontWeight weight) style});

final List<_ArabicFont> _kArabicFonts = [
  (
    name: 'Uthmani',
    arabicPreview: 'بِسْمِ ٱللَّهِ',
    style: (size, color, height, weight) =>
        GoogleFonts.amiri(fontSize: size, color: color, height: height, fontWeight: weight),
  ),
  (
    name: 'Indo pak',
    arabicPreview: 'بِسۡمِ اللهِ',
    style: (size, color, height, weight) =>
        GoogleFonts.notoNaskhArabic(fontSize: size, color: color, height: height, fontWeight: weight),
  ),
  (
    name: 'Madina',
    arabicPreview: 'بِسْمِ ٱللَّهِ',
    style: (size, color, height, weight) =>
        GoogleFonts.scheherazadeNew(fontSize: size, color: color, height: height, fontWeight: weight),
  ),
];

// ── Models ────────────────────────────────────────────────────────────────────
class _Azkar {
  final String id;
  final String arabic;
  final String transliteration;
  final String translation;
  final int    recommendedCount;
  final String category;
  final String reward;
  final String reference;

  const _Azkar({
    required this.id, required this.arabic, required this.transliteration,
    required this.translation, required this.recommendedCount,
    required this.category, required this.reward, required this.reference,
  });

  factory _Azkar.fromJson(Map<String, dynamic> j) => _Azkar(
    id:               j['id'] as String? ?? '',
    arabic:           j['arabic'] as String? ?? '',
    transliteration:  j['transliteration'] as String? ?? '',
    translation:      j['translation'] as String? ?? '',
    recommendedCount: j['recommended_count'] as int? ?? 1,
    category:         j['category_id'] as String? ?? j['category']?.toString() ?? 'general',
    reward:           j['reward'] as String? ?? '',
    reference:        j['reference'] as String? ?? '',
  );
}

class _Category {
  final String id;
  final String label;
  final IconData icon;
  const _Category(this.id, this.label, this.icon);
}

class _DhikrSettings {
  double arabicFontSize = 32.0;
  double translationFontSize = 14.0;
  bool darkMode = false;
  int arabicFontIdx = 0;  // index into _kArabicFonts
}

IconData _parseIcon(String name) {
  switch (name) {
    case 'auto_awesome_rounded': return Icons.nights_stay_rounded;
    case 'wb_sunny_rounded':     return Icons.wb_sunny_rounded;
    case 'nights_stay_rounded':  return Icons.nights_stay_rounded;
    case 'mosque_rounded':       return Icons.mosque_rounded;
    case 'bedtime_rounded':      return Icons.bedtime_rounded;
    case 'shield_rounded':       return Icons.shield_rounded;
    default:                     return Icons.bookmark_rounded;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class DhikrScreen extends StatefulWidget {
  final String initialCategory;
  const DhikrScreen({super.key, this.initialCategory = 'general'});
  @override State<DhikrScreen> createState() => _DhikrScreenState();
}

class _DhikrScreenState extends State<DhikrScreen> {
  // ── State ─────────────────────────────────────────────────────────────────
  List<_Azkar> _allAzkar = [];
  List<_Azkar> _filtered = [];
  List<_Category> _categories = [];
  late String _selectedCat;
  
  final Map<String, int> _counts = {};
  List<String> _favorites = [];
  int _pointsToday = 0;
  int _setsCompleted = 0;
  bool _loading = true;

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
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _selectedCat = widget.initialCategory;
    _initData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await _loadPrefs();
    await _loadDBData();
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
      _settings.translationFontSize = prefs.getDouble('dhikr_tr_size') ?? 14.0;
      _settings.darkMode = prefs.getBool('dhikr_dark_mode') ?? false;
      int loadFontIdx = prefs.getInt('dhikr_ar_font') ?? 0;
      if (loadFontIdx >= _kArabicFonts.length) loadFontIdx = 0;
      _settings.arabicFontIdx = loadFontIdx;
      _isFirstTime = prefs.getBool('dhikr_first_time') ?? true;
      _favorites = prefs.getStringList('dhikr_favorites') ?? [];
    });
    if (_isFirstTime) {
      await prefs.setBool('dhikr_first_time', false);
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('dhikr_ar_size', _settings.arabicFontSize);
    await prefs.setDouble('dhikr_tr_size', _settings.translationFontSize);
    await prefs.setBool('dhikr_dark_mode', _settings.darkMode);
    await prefs.setInt('dhikr_ar_font', _settings.arabicFontIdx);
  }

  // ── Load Supabase Data ─────────────────────────────────────────────────────
  Future<void> _loadDBData() async {
    try {
      final catRes = await _supabase.from('azkar_categories').select().order('sort_order');
      final fetchedCats = (catRes as List).map((c) => _Category(
        c['id'] as String, c['label'] as String, _parseIcon(c['icon_name'] as String)
      )).toList();
      
      final itemsRes = await _supabase.from('azkar_items').select().order('sort_order');
      final fetchedItems = (itemsRes as List).map((i) => _Azkar.fromJson(i)).toList();

      if (fetchedCats.isNotEmpty && fetchedItems.isNotEmpty) {
        _categories = fetchedCats;
        _categories.insert(0, const _Category('all', 'All', Icons.apps_rounded));
        _categories.insert(1, const _Category('favorites', 'Favorites', Icons.favorite_rounded));
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
          _categories = const [
            _Category('all', 'All', Icons.apps_rounded),
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
    final raw  = await rootBundle.loadString('assets/data/azkar.json');
    final list = (jsonDecode(raw) as List)
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
        _filtered = _allAzkar.where((a) => a.category == _selectedCat).toList();
      }
    });
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
    final text = '${azkar.arabic}\n\n${azkar.transliteration}\n\n"${azkar.translation}"\n\n— Shared via Noor App';
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
    return justCompleted;
  }

  // Shows all queued pending completions as one aggregate "MashAllah" notification.
  // Called by _DhikrDetailScreen when the user pops back after a short session.
  void _showPendingCompletions() {
    if (_pendingCompletions.isEmpty || !mounted) return;
    final count = _pendingCompletions.length;
    final totalXp = _pendingCompletions.fold<int>(
        0, (sum, c) => sum + XpReward.dhikrXp(c.id));
    // Drain the queue
    _pendingCompletions.clear();
    // Small delay so the navigation animation completes first
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final isDark = _settings.darkMode;
      final kText = isDark ? Colors.white : const Color(0xFF1C1C1E);
      final kSub  = isDark ? Colors.grey.shade400 : const Color(0xFF8E8E93);
      final kBg   = isDark ? const Color(0xFF1E1E1E) : Colors.white;
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: kBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              NoorIcon.party(size: 56),
              const SizedBox(height: 16),
              Text('Masha\'Allah!',
                  style: GoogleFonts.outfit(
                      fontSize: 26, fontWeight: FontWeight.w800, color: kText)),
              const SizedBox(height: 8),
              Text(
                count == 1
                    ? 'You completed 1 Azkar set\n+20 Noor Points • +$totalXp XP'
                    : 'You completed $count Azkar sets\n+${count * 20} Noor Points • +$totalXp XP',
                style: GoogleFonts.outfit(fontSize: 14, color: kSub),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('Alhamdulillah ♥',
                    style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              )),
            ]),
          ),
        ),
      );
    });
  }

  void _reset(String id) {
    setState(() { _counts[id] = 0; });
  }

  Future<void> _completeDhikr(String dhikrId, int target) async {
    try {
      await XpService.instance.earnDhikrXp(dhikrId);
      // Update live notification counter
      NoorLiveNotificationService.instance.recordDhikr();
      // Record dhikr streak (idempotent — safe to call multiple times)
      StreakService.instance.recordActivity(StreakType.dhikr);
      if (_setsCompleted == 0) await XpService.instance.awardBadge('first_dhikr');
      if (_setsCompleted + 1 >= 7) await XpService.instance.awardBadge('night_warrior');

      final isDailyGoal = await XpService.instance.claimDailyDhikrGoal();
      if (isDailyGoal && mounted) {
        _confettiController.play();
        _showDailyGoalModal();
      }
      // If already claimed today, just proceed silently — no error shown

      setState(() {
        _pointsToday += 20;
        if (isDailyGoal) _pointsToday += 50;
        _setsCompleted += 1;
        _counts[dhikrId] = 0;
      });
    } catch (_) {
      // Silent — never show raw DB errors to user
    }
  }

  void _showCompleteDialog(String dhikrId, int target, {int pagesCount = 1}) {
    final xpEarned = XpReward.dhikrXp(dhikrId);
    final isDark = _settings.darkMode;
    final kText = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final kSub = isDark ? Colors.grey.shade400 : const Color(0xFF8E8E93);
    final kBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final String bodyText = pagesCount > 1
        ? 'You completed $pagesCount Azkar sets\n+${pagesCount * 20} Noor Points • +${xpEarned * pagesCount} XP'
        : '$target counts complete • +20 Noor Points • +$xpEarned XP';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: kBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            NoorIcon.party(size: 56),
            const SizedBox(height: 16),
            Text('Masha\'Allah!',
                style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: kText)),
            const SizedBox(height: 8),
            Text(bodyText,
                style: GoogleFonts.outfit(fontSize: 14, color: kSub),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              // Rewards already claimed — just dismiss
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('Alhamdulillah ♥',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            )),
          ]),
        ),
      ),

    );
  }

  void _showSettingsSheet([BuildContext? sheetContext, VoidCallback? onUpdate]) {
    showModalBottomSheet(
      context: sheetContext ?? context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = _settings.darkMode;
          final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final txtColor = isDark ? Colors.white : const Color(0xFF1C1C1E);

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollCtrl) => Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // ── Drag handle ──────────────────────────────────────────────
                  const SizedBox(height: 10),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 6),
                  // ── Title row ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: Text('Dua & Azkar Settings',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                                fontSize: 20, fontWeight: FontWeight.w800,
                                color: txtColor))),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: txtColor),
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
                        Text('Appearance',
                            style: GoogleFonts.outfit(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: const Color(0xFF0D9488))),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Dark Mode',
                              style: GoogleFonts.outfit(fontSize: 16, color: txtColor)),
                          activeTrackColor: const Color(0xFF0D9488),
                          value: _settings.darkMode,
                          onChanged: (val) {
                            setModalState(() => _settings.darkMode = val);
                            setState(() => _settings.darkMode = val);
                            onUpdate?.call();
                            _savePrefs();
                          },
                        ),
                        const Divider(),

                        // Text Sizes
                        const SizedBox(height: 10),
                        Text('Arabic Text Size',
                            style: GoogleFonts.outfit(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: const Color(0xFF0D9488))),
                        Slider(
                          value: _settings.arabicFontSize,
                          min: 20.0,
                          max: 56.0,
                          activeColor: const Color(0xFF0D9488),
                          onChanged: (val) {
                            setModalState(() => _settings.arabicFontSize = val);
                            setState(() => _settings.arabicFontSize = val);
                            onUpdate?.call();
                            _savePrefs();
                          },
                        ),

                        Text('Translation Text Size',
                            style: GoogleFonts.outfit(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: const Color(0xFF0D9488))),
                        Slider(
                          value: _settings.translationFontSize,
                          min: 12.0,
                          max: 24.0,
                          activeColor: const Color(0xFF0D9488),
                          onChanged: (val) {
                            setModalState(() => _settings.translationFontSize = val);
                            setState(() => _settings.translationFontSize = val);
                            onUpdate?.call();
                            _savePrefs();
                          },
                        ),

                        // ── Arabic Font Style Picker ───────────────────────────
                        const Divider(),
                        const SizedBox(height: 10),
                        Text('Arabic Font Style',
                            style: GoogleFonts.outfit(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: const Color(0xFF0D9488))),
                        const SizedBox(height: 12),
                        ...List.generate(_kArabicFonts.length, (i) {
                          final font = _kArabicFonts[i];
                          final sel  = i == _settings.arabicFontIdx;
                          const accent = Color(0xFF0D9488);
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => _settings.arabicFontIdx = i);
                              setState(() => _settings.arabicFontIdx = i);
                              onUpdate?.call();
                              _savePrefs();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: sel
                                    ? accent.withValues(alpha: 0.10)
                                    : (isDark
                                        ? const Color(0xFF2C2C2E)
                                        : const Color(0xFFF3F4F6)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: sel ? accent : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(font.name,
                                          style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: sel
                                                  ? accent
                                                  : const Color(0xFF8E8E93))),
                                      const SizedBox(height: 4),
                                      Text(font.arabicPreview,
                                          textDirection: TextDirection.rtl,
                                          style: font.style(
                                              22, txtColor, 1.6, FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                if (sel)
                                  Container(
                                    width: 24, height: 24,
                                    decoration: const BoxDecoration(
                                        color: Color(0xFF0D9488),
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 15),
                                  ),
                              ]),
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
        }
      )
    );
  }

  void _showDailyGoalModal() {
    final isDark = _settings.darkMode;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE0F2FE)),
                child: Center(child: NoorIcon.trophy(size: 40)),
              ),
              const SizedBox(height: 20),
              Text('Daily Azkar Complete!', 
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1C1C1E))),
              const SizedBox(height: 12),
              Text('Masha\'Allah! You tracked your daily Azkar and earned a bonus +50 Noor Points.', 
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 15, color: isDark ? Colors.grey.shade400 : const Color(0xFF8E8E93))),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Awesome', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0F9F4),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))),
      );
    }

    final isDark = _settings.darkMode;
    final kText  = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final kWhite = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final kSub   = isDark ? Colors.grey.shade400 : const Color(0xFF8E8E93);
    final kPrimary  = const Color(0xFF0D9488);

    // ── Gradient background: rich amber-gold → warm sage green (diagonal)
    // Richer, deeper version — warm and spiritual feel for Dua & Azkaar
    const bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFEAB0), // rich warm golden-amber
        Color(0xFFD4EDDA), // soft sage green
        Color(0xFFEAF6F0), // pale mint-white
      ],
      stops: [0.0, 0.55, 1.0],
    );

    final scaffold = Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.transparent,
      appBar: AppBar(
        backgroundColor: kWhite,
        surfaceTintColor: kWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: kText, size: 20),
          onPressed: () => Navigator.pop(context, _pointsToday),
        ),
        title: Text('Dua & Azkar',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
        centerTitle: true,
      ),
      body: Stack(children: [
        SafeArea(child: Column(children: [

        // Points banner removed — shown inside the meter

        // ── Category tabs ───────────────────────────────────────────────────
        const SizedBox(height: 14),
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
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCat = cat.id;
                  _applyFilter();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? kPrimary : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? kPrimary : (isDark ? const Color(0xFF3A3A3C) : Colors.grey.shade200)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(cat.icon, size: 13, color: sel ? Colors.white : kSub),
                    const SizedBox(width: 5),
                    Text(cat.label,
                        style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : kSub)),
                  ]),
                ),
              );
            },
          ),
        ),

        // ── Beautiful Master List ───────────────────────────────────────────
        const SizedBox(height: 14),
        Expanded(
          child: _filtered.isEmpty 
          ? Center(child: Text('No Azkar found here.', style: GoogleFonts.outfit(color: kSub)))
          : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            itemCount: _filtered.length,
            itemBuilder: (context, index) {
              final azkar = _filtered[index];
              final count = _counts[azkar.id] ?? 0;
              final tapTarget = azkar.recommendedCount;
              final isComplete = count >= tapTarget;

              String titleText = (azkar.transliteration.isNotEmpty && azkar.transliteration.trim() != '') 
                  ? azkar.transliteration 
                  : azkar.translation;
              titleText = titleText.replaceAll('\n', ' ').trim();

              return GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => _DhikrDetailScreen(
                    azkars: _filtered,
                    initialIndex: index,
                    counts: _counts,
                    favorites: _favorites,
                    settings: _settings,
                    parentState: this,
                  )));
                  // After returning from the detail screen, show any
                  // completions that were queued during the session.
                  _showPendingCompletions();
                  setState((){}); // Refresh counts on the index list when they return
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14), // Margin replaces separator padding
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                    boxShadow: [
                       BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isComplete ? const Color(0xFF2BAE7C) : const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: isComplete 
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                            : Text('${index + 1}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titleText, 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: kText)
                            ),
                            const SizedBox(height: 4),
                            Text(azkar.reference.replaceAll('Hisnul Muslim, Chapter: ', '').replaceAll('Hisnul Muslim, ', '').trim(), 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 13, color: kSub)
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isComplete ? const Color(0xFFE8F8F0) : const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${azkar.recommendedCount}x', 
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800, 
                            color: isComplete ? const Color(0xFF2BAE7C) : const Color(0xFFD97706)
                          )
                        ),
                      ),
                    ]
                  )
                ),
              );
            },
          ),
        ),
      ])),
      Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [Color(0xFF0D9488), Color(0xFFF59E0B), Color(0xFFEC4899), Color(0xFF38BDF8)],
        ),
      ),
    ]));
    // ── Navigator.pop returns _pointsToday so parent can refresh ──
    if (isDark) return scaffold;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: bgGradient),
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

  const _DhikrDetailScreen({
     required this.azkars, required this.initialIndex,
     required this.counts, required this.favorites,
     required this.settings, required this.parentState,
  });

  @override
  State<_DhikrDetailScreen> createState() => _DhikrDetailScreenState();
}

class _DhikrDetailScreenState extends State<_DhikrDetailScreen> {
  late PageController _pageController;

  bool _showToolbar = false;
  Timer? _hideTimer;

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
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void _toggleToolbar() {
    setState(() {
      _showToolbar = !_showToolbar;
    });
    _hideTimer?.cancel();
    if (_showToolbar) {
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() { _showToolbar = false; });
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _tryComplete(_Azkar azkar, int tapTarget, {bool isSwipe = false}) {
    final current = widget.parentState._counts[azkar.id] ?? 0;
    if (current >= tapTarget) return;

    final justCompleted = widget.parentState._tap(azkar.id, tapTarget);
    if (mounted) setState(() {});

    if (justCompleted) {
      _pagesCompletedInSession++;
      widget.parentState._completeDhikr(azkar.id, tapTarget);

      final secondsElapsed = DateTime.now().difference(_sessionStart).inSeconds;
      final enoughTime = secondsElapsed >= _kMinSecondsForImmediatePopup;
      final enoughPages = _pagesCompletedInSession >= _kMinPagesForImmediatePopup;

      if (enoughTime && enoughPages) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          widget.parentState._showCompleteDialog(
              azkar.id, tapTarget,
              pagesCount: _pagesCompletedInSession);
          _pagesCompletedInSession = 0;
          _sessionStart = DateTime.now();
        });
      } else {
        widget.parentState._pendingCompletions
            .add((id: azkar.id, target: tapTarget));
      }

      if (!isSwipe) {
        final currentGlobalIndex = widget.azkars.indexOf(azkar);
        final nextIndex = currentGlobalIndex + 1;
        if (nextIndex > 0 && nextIndex < widget.azkars.length) {
          Future.delayed(const Duration(milliseconds: 700), () {
            if (!mounted) return;
            _pageController.animateToPage(
              nextIndex,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOut,
            );
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
      final isDark = widget.settings.darkMode;
      final kText  = isDark ? Colors.white : const Color(0xFF1C1C1E);
      final kWhite = isDark ? const Color(0xFF1E1E1E) : Colors.white;

      // Same rich amber-gold → sage green gradient for reading consistency
      const bgGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFEAB0), // rich warm golden-amber
          Color(0xFFD4EDDA), // soft sage green
          Color(0xFFEAF6F0), // pale mint-white
        ],
        stops: [0.0, 0.55, 1.0],
      );

      final inner = PopScope(
        onPopInvokedWithResult: (didPop, _) {},
        child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.transparent,
        appBar: AppBar(
          backgroundColor: kWhite,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: kText, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: AnimatedBuilder(
            animation: _pageController,
            builder: (context, _) {
              int currentIndex = _pageController.positions.isNotEmpty ? _pageController.page?.round() ?? widget.initialIndex : widget.initialIndex;
              final catId = widget.azkars[currentIndex].category;
              final catObj = widget.parentState._categories.cast<_Category?>().firstWhere((c) => c?.id == catId, orElse: () => null);
              final String catLabel = catObj?.label ?? 'Dhikr & Dua';
              return Text(catLabel, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: kText));
            }
          ),
          centerTitle: true,
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _toggleToolbar(),
          child: PageView.builder(
            controller: _pageController,
          onPageChanged: (nextIndex) {
            final prevAzkar = widget.azkars[_currentIndex];
            if (prevAzkar.recommendedCount == 1) {
              _tryComplete(prevAzkar, prevAzkar.recommendedCount, isSwipe: true);
            }
            if (mounted) setState(() { _currentIndex = nextIndex; });
          },
          itemCount: widget.azkars.length,
          itemBuilder: (context, index) {
            final azkar = widget.azkars[index];
            final count = widget.counts[azkar.id] ?? 0;
            final tapTarget = azkar.recommendedCount;
            final isComplete = count >= tapTarget;

            return Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 0, bottom: 120),
                    child: _AzkarCard(
                      azkar: azkar,
                      currentCount: count,
                      isComplete: isComplete,
                      isFavorite: widget.favorites.contains(azkar.id),
                      settings: widget.settings,
                      pointsToday: widget.parentState._pointsToday,
                      onReset: () {
                          widget.parentState._reset(azkar.id);
                          setState((){});
                      },
                      onFavorite: () {
                          widget.parentState._toggleFavorite(azkar.id);
                          setState((){});
                      },
                      onShare: () => widget.parentState._shareAzkar(azkar),
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 90,
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E).withValues(alpha: 0.92)
                                : Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
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
                                color: isDark ? const Color(0xFF7EB8F0) : const Color(0xFF4A90D9),
                                isDark: isDark,
                                onTap: () {
                                  widget.parentState._showSettingsSheet(context, () {
                                    if (mounted) setState(() {});
                                  });
                                },
                              ),
                              _toolbarDivider(isDark),
                              _ToolbarBtn(
                                icon: widget.favorites.contains(azkar.id)
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_outline_rounded,
                                color: const Color(0xFFE11D48),
                                filled: widget.favorites.contains(azkar.id),
                                isDark: isDark,
                                onTap: () {
                                  widget.parentState._toggleFavorite(azkar.id);
                                  setState(() {});
                                },
                              ),
                              _toolbarDivider(isDark),
                              _ToolbarBtn(
                                icon: Icons.share_rounded,
                                color: isDark ? const Color(0xFFE8B74A) : const Color(0xFFD4960A),
                                isDark: isDark,
                                onTap: () => widget.parentState._shareAzkar(azkar),
                              ),
                              _toolbarDivider(isDark),
                              _ToolbarBtn(
                                icon: Icons.refresh_rounded,
                                color: const Color(0xFF0D9488),
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
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: Center(
                    child: GestureDetector(
                      onTap: isComplete ? null : () => _tryComplete(azkar, tapTarget, isSwipe: false),
                      child: _DhikrCounterButton(
                        count: count,
                        target: tapTarget,
                        isComplete: isComplete,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        ),
      ));
      if (isDark) return inner;
      return DecoratedBox(
        decoration: const BoxDecoration(gradient: bgGradient),
        child: inner,
      );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arabic text cleaner — strips brackets, parentheses, and Quranic waqf/
// annotation characters that sometimes appear in source data.
// ─────────────────────────────────────────────────────────────────────────────
String _cleanArabic(String s) {
  // Remove footnote markers like [1], (2)
  s = s.replaceAll(RegExp(r'\[\d+\]'), '');
  s = s.replaceAll(RegExp(r'\(\d+\)'), '');
  // Remove leftover bracket characters (so things like ((text)) keep the text)
  s = s.replaceAll(RegExp(r'[\[\]\(\)\{\}«»﴿﴾]'), '');
  // Remove Quranic waqf/tajweed marks (same ranges as Quran screen stripper)
  s = s.replaceAll(RegExp(r'[\u06D6-\u06DE\u06DF-\u06E4\u06E7-\u06E8\u06EA-\u06ED]'), '');
  // Remove Arabic end-of-ayah ornament ۝ if it crept in
  s = s.replaceAll('\u06DD', '');
  // Collapse extra whitespace
  return s.replaceAll(RegExp(r'  +'), ' ').trim();
}

// ─────────────────────────────────────────────────────────────────────────────
// Beautiful Display Card for Azkaar
// ─────────────────────────────────────────────────────────────────────────────
class _AzkarCard extends StatelessWidget {
  final _Azkar azkar;
  final int currentCount;
  final bool isComplete;
  final bool isFavorite;
  final _DhikrSettings settings;
  final int pointsToday;
  final VoidCallback onReset;
  final VoidCallback onFavorite;
  final VoidCallback onShare;

  const _AzkarCard({
    required this.azkar,
    required this.currentCount,
    required this.isComplete,
    required this.isFavorite,
    required this.settings,
    this.pointsToday = 0,
    required this.onReset,
    required this.onFavorite,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = settings.darkMode;
    final kCardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final kText  = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final kSub   = isDark ? Colors.grey.shade400 : const Color(0xFF8E8E93);
    final kPrimary  = const Color(0xFF0D9488);
    final kBeneBg = isDark ? const Color(0xFF2A2416) : const Color(0xFFEAF6F0);
    final kBeneTxt = isDark ? const Color(0xFFEADBBE) : const Color(0xFF1E4031);

    String rawRef = azkar.reference.replaceAll('Hisnul Muslim, Chapter: ', '').replaceAll('Hisnul Muslim, ', '').trim();
    String bottomRef = '';
    
    // Parse references at the end, either in brackets/parenthesis OR matching a known Hadith/Quran keyword
    void extractReference(String source, Function(String newSource, String extractedRef) onExtract) {
      if (source.isEmpty) return;
      
      // 1. Check for brackets or parentheses at the end
      final bracketMatch = RegExp(r'(\(|\[)([^\[\(\)\]]+)(\)|\])\s*$').firstMatch(source);
      if (bracketMatch != null) {
        final ref = bracketMatch.group(2)?.trim() ?? '';
        final cleanSource = source.substring(0, bracketMatch.start).replaceAll(RegExp(r'[-—\.,\s]+$'), '').trim();
        onExtract(cleanSource, ref);
        return;
      }
      
      // 2. Check for known Hadith keywords
      final keywordMatch = RegExp(r'(?:[-—\.,\s]+|^)((?:Sahih\s)?(?:Muslim|Bukhari|Abu Dawud|Tirmidhi|Ibn Majah|Nasai|Ahmad|Quran|Surah).*)$', caseSensitive: false).firstMatch(source);
      if (keywordMatch != null) {
        final ref = keywordMatch.group(1)?.trim() ?? '';
        final cleanSource = source.substring(0, keywordMatch.start).replaceAll(RegExp(r'[-—\.,\s]+$'), '').trim();
        onExtract(cleanSource, ref);
        return;
      }
    }

    extractReference(rawRef, (clean, ref) {
      rawRef = clean;
      bottomRef = ref;
    });

    String cleanReward = azkar.reward.trim();
    extractReference(cleanReward, (clean, ref) {
      cleanReward = clean;
      if (bottomRef.isEmpty) bottomRef = ref;
    });

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20, 
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Noor Tree Animation ──
            _NoorTree(
              progress: azkar.recommendedCount == 0
                  ? 0.0
                  : (currentCount / azkar.recommendedCount).clamp(0.0, 1.0),
              isComplete: isComplete,
              tapCount: currentCount,
              pointsToday: pointsToday,
            ),
            
            const SizedBox(height: 32),

            // ── Context / Chapter Subtitle ──
            if (rawRef.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rawRef,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kSub,
                      ),
                    ),
                  ),
                ),
              ),

            // ── Main Text Content ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    _cleanArabic(azkar.arabic),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: _kArabicFonts[settings.arabicFontIdx.clamp(0, _kArabicFonts.length - 1)]
                        .style(settings.arabicFontSize, kText, 1.8, FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    azkar.transliteration,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: settings.translationFontSize, 
                      fontWeight: FontWeight.w600, 
                      color: kPrimary, 
                      fontStyle: FontStyle.italic
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    azkar.translation,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: settings.translationFontSize, 
                      color: kSub
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Highly Visible Benefit Box ──
            if (cleanReward.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kBeneBg, 
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NoorIcon.sparkles(size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hadith & Virtue', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: kPrimary)),
                          const SizedBox(height: 4),
                          Text(cleanReward, style: GoogleFonts.outfit(fontSize: 13, color: kBeneTxt, height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ── Display Reference at the Bottom ──
            if (bottomRef.isNotEmpty || (azkar.reference.isNotEmpty && rawRef.isEmpty))
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  bottomRef.isNotEmpty ? bottomRef : azkar.reference,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimary),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 🌳 Noor Tree (شجرة النور) — Islamic growth animation
// =============================================================================
class _NoorTree extends StatefulWidget {
  final double progress;   // 0.0 → 1.0
  final bool isComplete;
  final int tapCount;      // triggers particle burst on change
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

  final List<_Particle> _particles = List.generate(20, (i) => _Particle(seed: i));
  final List<_ShootingStar> _shootingStars = List.generate(3, (i) => _ShootingStar(seed: i));

  @override
  void initState() {
    super.initState();

    _swayCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))
      ..repeat(reverse: true);
    _sway = Tween<double>(begin: -1.0, end: 1.0)
        .animate(CurvedAnimation(parent: _swayCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))
      ..repeat(reverse: true);

    _pCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.87, end: 1.13)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _punchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.95).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _shootCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
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
      for (final p in _particles) { p.reset(); }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
      for (final s in _shootingStars) { s.reset(); }
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
      animation: Listenable.merge([_swayCtrl, _growCtrl, _starCtrl, _pCtrl, _pulseCtrl, _punchCtrl, _shockCtrl, _shootCtrl]),
      builder: (_, __) => SizedBox(
        height: 190,
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
    Color(0xFF1BDE9A), Color(0xFF2EC4A9), Color(0xFF26C97A),
    Color(0xFF3ACF58), Color(0xFFD4AF37), Color(0xFFFFD97D),
    Color(0xFF00FFCC), Color(0xFFF5C842),
  ];

  _Particle({required int seed}) { reset(seed: seed); }

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

  _ShootingStar({required int seed}) { reset(seed: seed); }

  void reset({int? seed}) {
    final r = seed != null ? math.Random(seed * 7919) : _rng;
    startX = 0.1 + r.nextDouble() * 0.8;
    startY = 0.02 + r.nextDouble() * 0.18;
    angle = 0.3 + r.nextDouble() * 0.5; // downward-right angle
    length = 0.08 + r.nextDouble() * 0.12;
    speed = 0.6 + r.nextDouble() * 0.4;
  }
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

    // 1. Night-sky gradient background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF051F1C), Color(0xFF093630), Color(0xFF0E4A3C)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars
    const starPos = [
      (0.08, 0.06), (0.18, 0.14), (0.32, 0.04), (0.55, 0.09),
      (0.71, 0.05), (0.84, 0.15), (0.92, 0.07), (0.45, 0.18),
      (0.63, 0.22), (0.25, 0.20), (0.77, 0.18), (0.12, 0.27),
      (0.90, 0.25), (0.38, 0.29), (0.59, 0.33),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      sp.color = Colors.white.withValues(alpha: 0.25 + 0.65 * tw);
      canvas.drawCircle(
        Offset(starPos[i].$1 * w, starPos[i].$2 * h), 1.1 + tw * 1.2, sp);
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
          Offset(tailX, tailY), Offset(sx, sy),
          Paint()
            ..shader = LinearGradient(
              colors: [
                Colors.transparent,
                const Color(0xFFD4AF37).withValues(alpha: sa),
              ],
            ).createShader(Rect.fromPoints(Offset(tailX, tailY), Offset(sx, sy)))
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
        // Head glow
        canvas.drawCircle(Offset(sx, sy), 2.5,
          Paint()..color = Colors.white.withValues(alpha: sa * 0.8));
      }
    }

    // 3. Crescent moon (fades in with progress)
    final moonA = progress.clamp(0.05, 1.0);
    const moonX = 0.83;
    const moonY = 0.13;
    const moonR = 13.0;
    canvas.drawCircle(
      Offset(moonX * w, moonY * h), moonR,
      Paint()..color = const Color(0xFFD4AF37).withValues(alpha: moonA * 0.85));
    canvas.drawCircle(
      Offset(moonX * w + moonR * 0.55, moonY * h - moonR * 0.1), moonR * 0.9,
      Paint()..color = const Color(0xFF051F1C).withValues(alpha: moonA * 0.92));
    canvas.drawCircle(
      Offset(moonX * w, moonY * h), moonR + 6,
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: moonA * 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // 4. Ground shadow glow — intensifies on punch
    final groundY = h * 0.82;
    final groundGlow = 0.07 + (punchScale > 1.0 ? (punchScale - 1.0) * 1.5 : 0.0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, groundY + 14), width: w * 0.7, height: 20),
      Paint()
        ..color = Color.fromRGBO(27, 222, 154, groundGlow.clamp(0.0, 0.35))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
    canvas.drawLine(
      Offset(cx - w * 0.28, groundY), Offset(cx + w * 0.28, groundY),
      Paint()..color = const Color(0xFF1BDE9A).withValues(alpha: 0.18)..strokeWidth = 0.7);

    // Apply punch scale transform for the tree (trunk + leaves)
    canvas.save();
    final treeCenterY = groundY - (groundY - h * 0.28) * progress * 0.5;
    canvas.translate(cx, treeCenterY);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -treeCenterY);

    // 5. Trunk
    if (progress > 0.02) {
      final trunkH = (groundY - h * 0.28) * progress.clamp(0.0, 1.0);
      final trunkTop = Offset(cx + sway * 2, groundY - trunkH);
      final trunkBot = Offset(cx, groundY);
      final tp = Paint()
        ..color = const Color(0xFF7A4F2A)
        ..strokeWidth = 7.5 * (0.5 + progress * 0.5)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(trunkBot, trunkTop, tp);
      if (progress > 0.2) _drawBranches(canvas, trunkBot, trunkTop, sway, progress, tp);
    }

    // 6. Leaf orbs
    if (progress > 0.05) {
      final trunkH = (groundY - h * 0.28) * progress;
      final treeTop = Offset(cx + sway * 2, groundY - trunkH);
      const leafDefs = [
        (0.0,   0.0,  28.0, 0.10, Color(0xFF2EC4A9)),
        (-0.5,  0.18, 22.0, 0.20, Color(0xFF1BDE9A)),
        (0.5,   0.22, 22.0, 0.25, Color(0xFF26C97A)),
        (-0.7,  0.38, 18.0, 0.36, Color(0xFF3ACF58)),
        (0.75,  0.40, 18.0, 0.42, Color(0xFFD4AF37)),
        (0.0,   0.48, 16.0, 0.50, Color(0xFF2EC4A9)),
        (-0.35, 0.10, 16.0, 0.60, Color(0xFF26C97A)),
        (0.40,  0.12, 15.0, 0.66, Color(0xFFD4AF37)),
        (-0.8,  0.28, 14.0, 0.72, Color(0xFF1BDE9A)),
        (0.85,  0.32, 13.0, 0.78, Color(0xFF3ACF58)),
        (0.0,  -0.08, 20.0, 0.85, Color(0xFFFFD97D)),
        (-0.2,  0.55, 12.0, 0.92, Color(0xFF2EC4A9)),
        (0.25,  0.56, 12.0, 0.96, Color(0xFF26C97A)),
      ];
      final halfW = w * 0.27;
      for (final (rx, ry, r, minP, col) in leafDefs) {
        if (progress < minP) continue;
        final leafA = ((progress - minP) / 0.08).clamp(0.0, 1.0);
        final leafPos = Offset(
          treeTop.dx + rx * halfW,
          treeTop.dy + ry * trunkH * 0.55,
        );
        final leafR = r * (0.7 + progress * 0.3) * (isComplete ? pulse : 1.0);
        // Glow
        canvas.drawCircle(leafPos, leafR + 8,
          Paint()
            ..color = col.withValues(alpha: leafA * 0.14)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
        // Orb fill
        canvas.drawCircle(leafPos, leafR,
          Paint()
            ..shader = RadialGradient(colors: [
              Colors.white.withValues(alpha: leafA * 0.45),
              col.withValues(alpha: leafA * 0.88),
              col.withValues(alpha: leafA * 0.38),
            ], stops: const [0.0, 0.42, 1.0])
            .createShader(Rect.fromCircle(center: leafPos, radius: leafR)));
        // Highlight
        canvas.drawCircle(
          Offset(leafPos.dx - leafR * 0.28, leafPos.dy - leafR * 0.28),
          leafR * 0.20,
          Paint()..color = Colors.white.withValues(alpha: leafA * 0.55));
      }

      // 6b. Golden crown glow on completion
      if (isComplete) {
        final crownY = treeTop.dy - 8;
        canvas.drawCircle(
          Offset(cx + sway * 2, crownY), 32 * pulse,
          Paint()
            ..color = const Color(0xFFD4AF37).withValues(alpha: 0.12 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
        canvas.drawCircle(
          Offset(cx + sway * 2, crownY), 18 * pulse,
          Paint()
            ..color = const Color(0xFFFFD97D).withValues(alpha: 0.18 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      }
    }

    canvas.restore(); // end punch scale

    // 7. Shockwave ring on tap — expands from tree center
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.42;
      final ringR = maxR * shockPhase;
      final ringA = (1.0 - shockPhase) * 0.45;
      canvas.drawCircle(
        Offset(cx, treeCenterY), ringR,
        Paint()
          ..color = const Color(0xFF1BDE9A).withValues(alpha: ringA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - shockPhase));
      // Inner softer ring
      canvas.drawCircle(
        Offset(cx, treeCenterY), ringR * 0.7,
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: ringA * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * (1.0 - shockPhase));
    }

    // 8. Floating noor particles — with trails
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final py = p.startY * h - t * h * 0.55;
        final px = cx + p.x * w * 0.36 + math.sin(t * math.pi * 3) * p.drift;
        final a = (1.0 - t) * 0.9;
        final pSize = p.size * (1.0 - t * 0.4);

        // Trail (3 fading dots behind)
        for (int trail = 1; trail <= 3; trail++) {
          final tOff = trail * 0.04;
          final tT = (t - tOff).clamp(0.0, 1.0);
          if (tT <= 0) continue;
          final tpy = p.startY * h - tT * h * 0.55;
          final tpx = cx + p.x * w * 0.36 + math.sin(tT * math.pi * 3) * p.drift;
          canvas.drawCircle(Offset(tpx, tpy), pSize * (0.6 - trail * 0.12),
            Paint()..color = p.color.withValues(alpha: a * (0.3 - trail * 0.08)));
        }

        // Main particle with glow
        canvas.drawCircle(Offset(px, py), pSize + 3,
          Paint()
            ..color = p.color.withValues(alpha: a * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawCircle(Offset(px, py), pSize,
          Paint()..color = p.color.withValues(alpha: a));
        // Bright core
        canvas.drawCircle(Offset(px, py), pSize * 0.35,
          Paint()..color = Colors.white.withValues(alpha: a * 0.7));
      }
    }

    // 9. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'ماشاء الله' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: isComplete ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.82),
          fontSize: isComplete ? 13 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.86));

    // 10. Noor points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(
          text: badgeLabel,
          style: const TextStyle(
            color: Color(0xFF00FFCC),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: [
              Shadow(color: Color(0xFF00FFCC), blurRadius: 6),
              Shadow(color: Color(0xFF00FFCC), blurRadius: 14),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp3.width + 10;
      final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2;
      final badgeY = h * 0.86 + tp2.height + 4;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(0xFF00FFCC).withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(0xFF00FFCC).withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  void _drawBranches(Canvas canvas, Offset bot, Offset top,
      double sway, double progress, Paint basePaint) {
    final vec = top - bot;
    final len = vec.distance;
    final nx = -vec.dy / len;
    final ny = vec.dx / len;
    final anchor = bot + vec * 0.60;
    final bLen = len * 0.34 * progress;
    final bp = Paint()
      ..color = const Color(0xFF7A4F2A)
      ..strokeWidth = basePaint.strokeWidth * 0.52
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(anchor,
      anchor + Offset(-nx * bLen + vec.dx / len * bLen * 0.42 + sway * 2.5,
                      -ny * bLen + vec.dy / len * bLen * 0.42), bp);
    canvas.drawLine(anchor,
      anchor + Offset(nx * bLen + vec.dx / len * bLen * 0.42 + sway * 2.5,
                      ny * bLen + vec.dy / len * bLen * 0.42), bp);

    if (progress > 0.60) {
      final ta = bot + vec * 0.82;
      final sl = bLen * 0.52;
      final sp2 = Paint()
        ..color = const Color(0xFF7A4F2A)
        ..strokeWidth = bp.strokeWidth * 0.58
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(ta, ta + Offset(-sl * 0.7 + sway * 2, -sl * 0.7), sp2);
      canvas.drawLine(ta, ta + Offset( sl * 0.7 + sway * 2, -sl * 0.7), sp2);
    }
  }

  @override
  bool shouldRepaint(_NoorTreePainter o) =>
    o.progress != progress || o.sway != sway || o.starPhase != starPhase ||
    o.particlePhase != particlePhase || o.isComplete != isComplete ||
    o.pulse != pulse || o.pointsToday != pointsToday ||
    o.punchScale != punchScale || o.shockPhase != shockPhase ||
    o.shootPhase != shootPhase;
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar button & divider for the floating action bar
// ─────────────────────────────────────────────────────────────────────────────
Widget _toolbarDivider(bool isDark) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8),
  child: Container(
    height: 1,
    width: 28,
    color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.06),
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
    const size = 82.0;
    const stroke = 4.5;
    const teal = Color(0xFF0D9488);
    const green = Color(0xFF2BAE7C);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: isComplete ? 160 : size,
      height: isComplete ? 52 : size,
      decoration: BoxDecoration(
        color: isComplete
            ? green
            : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
        borderRadius: BorderRadius.circular(isComplete ? 28 : size / 2),
        border: isComplete
            ? null
            : Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
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
      child: isComplete
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Completed',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring
                SizedBox(
                  width: size - 12,
                  height: size - 12,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: stroke,
                    strokeCap: StrokeCap.round,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : teal.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(teal),
                  ),
                ),
                // Count text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : teal,
                        height: 1.1,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: teal.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'of $target',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF8E8E93),
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
