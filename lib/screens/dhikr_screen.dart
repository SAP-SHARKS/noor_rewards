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
import 'package:just_audio/just_audio.dart';
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
  final String? audioUrl; // For online MP3 playback

  const _Azkar({
    required this.id, required this.arabic, required this.transliteration,
    required this.translation, required this.recommendedCount,
    required this.category, required this.reward, required this.reference,
    this.audioUrl,
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
    audioUrl:         j['audio_url'] as String?,
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
  final Map<String, int> _customTargets = {};
  final Set<String> _completedIds = {};   // persists across count resets
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
      // Load custom targets
      final targetKeys = prefs.getStringList('dhikr_custom_target_keys') ?? [];
      for (final key in targetKeys) {
        final val = prefs.getInt('dhikr_target_$key');
        if (val != null) _customTargets[key] = val;
      }
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

  /// Returns custom target if set, otherwise the recommended count.
  int _getTarget(String id, int recommendedCount) {
    return _customTargets[id] ?? recommendedCount;
  }

  Future<void> _saveCustomTarget(String id, int target) async {
    setState(() { _customTargets[id] = target; });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dhikr_custom_target_keys', _customTargets.keys.toList());
    await prefs.setInt('dhikr_target_$id', target);
  }

  Future<void> _clearCustomTarget(String id) async {
    setState(() { _customTargets.remove(id); });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dhikr_custom_target_keys', _customTargets.keys.toList());
    await prefs.remove('dhikr_target_$id');
  }

  void _showTargetPicker(BuildContext context, String azkarId, int recommendedCount) {
    final isDark = _settings.darkMode;
    final currentTarget = _getTarget(azkarId, recommendedCount);
    final controller = TextEditingController(text: currentTarget.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Set Your Target',
                  style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Default: $recommendedCount',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 20),
                // Quick presets
                Wrap(
                  spacing: 8, runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: () {
                    final presets = <int>{recommendedCount, 3, 7, 10, 33, 100}.toList()..sort();
                    return presets.map<Widget>((v) {
                      final isSelected = controller.text == v.toString();
                      return GestureDetector(
                        onTap: () {
                          controller.text = v.toString();
                          (ctx as Element).markNeedsBuild();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0D9488).withValues(alpha: 0.15)
                                : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF2F2F7)),
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(color: const Color(0xFF0D9488), width: 1.5)
                                : null,
                          ),
                          child: Text(
                            '$v×',
                            style: GoogleFonts.outfit(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF0D9488)
                                  : (isDark ? Colors.white70 : const Color(0xFF1C1C1E)),
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
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter custom count',
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 15, color: isDark ? Colors.grey.shade600 : const Color(0xFFAEAEB2),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            'Reset to default',
                            style: GoogleFonts.outfit(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: const Color(0xFFE11D48),
                            ),
                          ),
                        ),
                      ),
                    if (_customTargets.containsKey(azkarId)) const SizedBox(width: 8),
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
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Save', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700)),
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
      _showCelebrationDialog(
        context: context,
        isDark: _settings.darkMode,
        setsCount: count,
        noorPoints: count * 20,
        xp: totalXp,
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
        _completedIds.add(dhikrId);
        _counts[dhikrId] = 0;
      });
    } catch (_) {
      // Silent — never show raw DB errors to user
    }
  }

  void _showCompleteDialog(String dhikrId, int target, {int pagesCount = 1}) {
    final xpEarned = XpReward.dhikrXp(dhikrId);
    _showCelebrationDialog(
      context: context,
      isDark: _settings.darkMode,
      setsCount: pagesCount,
      noorPoints: pagesCount * 20,
      xp: xpEarned * pagesCount,
      countsLabel: pagesCount == 1 ? '$target counts' : null,
    );
  }

  /// Premium celebration dialog shared by all completion flows
  static void _showCelebrationDialog({
    required BuildContext context,
    required bool isDark,
    required int setsCount,
    required int noorPoints,
    required int xp,
    String? countsLabel,
  }) {
    final kText = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final kBg   = isDark ? const Color(0xFF1A1A1E) : Colors.white;
    const kTeal  = Color(0xFF0D9488);
    const kGold  = Color(0xFFD4AF37);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // ── Top accent bar ──
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 60),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kTeal, kGold, kTeal],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // ── Icon cluster ──
                SizedBox(
                  height: 64,
                  child: Stack(alignment: Alignment.center, children: [
                    // Soft glow behind
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [kTeal.withValues(alpha: 0.12), Colors.transparent],
                        ),
                      ),
                    ),
                    NoorIcon.party(size: 48),
                  ]),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
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
                        value: countsLabel ?? '$setsCount ${setsCount == 1 ? "set" : "sets"}',
                        color: kTeal,
                        isDark: isDark,
                      ),
                      Container(width: 1, height: 28, color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                      // Noor Points
                      _statChip(
                        icon: Icons.auto_awesome_rounded,
                        value: '+$noorPoints',
                        label: 'Noor',
                        color: kGold,
                        isDark: isDark,
                      ),
                      Container(width: 1, height: 28, color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                      // XP
                      _statChip(
                        icon: Icons.bolt_rounded,
                        value: '+$xp',
                        label: 'XP',
                        color: const Color(0xFF8B5CF6),
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
              ]),
            ),
          ]),
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
  }) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(height: 4),
      Text(
        value,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
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
    ]);
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
                        Text('Text Size',
                            style: GoogleFonts.outfit(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: const Color(0xFF0D9488))),
                        Slider(
                          value: _settings.arabicFontSize,
                          min: 20.0,
                          max: 56.0,
                          activeColor: const Color(0xFF0D9488),
                          onChanged: (val) {
                            final translationSize = 12.0 + (val - 20.0) * (12.0 / 36.0);
                            setModalState(() {
                              _settings.arabicFontSize = val;
                              _settings.translationFontSize = translationSize;
                            });
                            setState(() {
                              _settings.arabicFontSize = val;
                              _settings.translationFontSize = translationSize;
                            });
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
    final kBg    = isDark ? const Color(0xFF121212) : const Color(0xFFF7F8F9); // Lighter background
    final kSub   = isDark ? Colors.grey.shade400 : const Color(0xFF8E8E93);
    
    // UI Constants
    final bannerBg = isDark ? const Color(0xFF1F4130) : const Color(0xFF285E46);
    final bannerBtn = isDark ? const Color(0xFFE5B955) : const Color(0xFFFFD579);
    final bannerTxt = isDark ? const Color(0xFF2B2005) : const Color(0xFF3F2A00);
    
    final chipInactiveBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEEEEEE);
    final chipInactiveTxt = isDark ? Colors.white70 : const Color(0xFF4A4A4A);

    // Category color map — each category gets a distinct accent
    Color _catColor(String catId) => switch (catId) {
      'all'          => const Color(0xFF6366F1), // indigo
      'favorites'    => const Color(0xFFEF4444), // red
      'general'      => const Color(0xFF10B981), // emerald
      'morning'      => const Color(0xFFF59E0B), // amber
      'evening'      => const Color(0xFF6366F1), // indigo
      'sleeping'     => const Color(0xFF8B5CF6), // violet
      'waking_up'    => const Color(0xFFF97316), // orange
      'post_prayer'  => const Color(0xFF0EA5E9), // sky blue
      'salawat'      => const Color(0xFF10B981), // emerald
      'istighfar'    => const Color(0xFF8B5CF6), // violet
      'tahajjud'     => const Color(0xFF3B82F6), // blue
      'sunnah'       => const Color(0xFF14B8A6), // teal
      'quranic'      => const Color(0xFFD4AF37), // gold
      'ummah'        => const Color(0xFFEC4899), // pink
      'nightmares'   => const Color(0xFF6366F1), // indigo
      'clothes'      => const Color(0xFF14B8A6), // teal
      'wudu'         => const Color(0xFF0EA5E9), // sky blue
      'food_drink'   => const Color(0xFFF97316), // orange
      'home'         => const Color(0xFF10B981), // emerald
      _              => const Color(0xFF0D9488), // default teal
    };

    // Banner Text Setup
    String bannerTitle = "Daily Remembrance\nbrings peace to the soul.";
    String catLabel = "DAILY REMEMBRANCE";
    IconData waterMark = Icons.spa_rounded;
    
    if (_selectedCat == 'morning') {
      catLabel = "DAILY REMEMBRANCE";
      bannerTitle = "Morning Adhkar\nbrings peace to the soul and light to the path.";
      waterMark = Icons.wb_sunny_rounded;
    } else if (_selectedCat == 'evening') {
      catLabel = "NIGHTLY REMEMBRANCE";
      bannerTitle = "Evening Adhkar\nbrings tranquility and protection for the night.";
      waterMark = Icons.nights_stay_rounded;
    } else if (_selectedCat == 'favorites') {
      catLabel = "YOUR SELECTION";
      bannerTitle = "Your beloved words\nof remembrance to keep close to your heart.";
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
          onPressed: () => Navigator.pop(context, _pointsToday),
        ),
        title: Text('Dua & Azkar',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
        centerTitle: true,
      ),
      body: Stack(children: [
        SafeArea(child: Column(children: [

        // ── Top Banner ──────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bannerBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isDark) BoxShadow(color: bannerBg.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))
            ]
          ),
          child: Stack(
            children: [
              // Watermark icon
              Positioned(
                right: -30,
                bottom: -20,
                child: Icon(waterMark, size: 120, color: Colors.white.withValues(alpha: 0.10)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(catLabel, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2.0, color: Colors.white.withValues(alpha: 0.7))),
                  const SizedBox(height: 8),
                  Text(bannerTitle, style: GoogleFonts.lora(fontSize: 18, height: 1.4, color: Colors.white, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 18),
                  ElevatedButton(
                     onPressed: () {
                       if (_filtered.isNotEmpty) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => _DhikrDetailScreen(
                            azkars: _filtered,
                            initialIndex: 0,
                            counts: _counts,
                            favorites: _favorites,
                            settings: _settings,
                            parentState: this,
                          ))).then((_) {
                             _showPendingCompletions();
                             setState((){});
                          });
                       }
                     },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: bannerBtn,
                       foregroundColor: bannerTxt,
                       elevation: 0,
                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                       minimumSize: const Size(0, 36),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                     child: Text('Start Now', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
                  )
                ]
              ),
            ]
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
              final catAccent = _catColor(cat.id);
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCat = cat.id;
                  _applyFilter();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel
                        ? (isDark ? catAccent.withValues(alpha: 0.25) : catAccent)
                        : chipInactiveBg,
                    borderRadius: BorderRadius.circular(20),
                    border: sel ? Border.all(color: catAccent.withValues(alpha: isDark ? 0.5 : 0.0), width: 1) : null,
                  ),
                  child: Text(cat.label,
                    style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                      color: sel ? (isDark ? catAccent : Colors.white) : chipInactiveTxt)),
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
              final tapTarget = _getTarget(azkar.id, azkar.recommendedCount);
              final isComplete = count >= tapTarget || _completedIds.contains(azkar.id);

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
                  _showPendingCompletions();
                  setState((){});
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                    boxShadow: [
                      if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Index badge
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isComplete
                              ? _catColor(azkar.category)
                              : _catColor(azkar.category).withValues(alpha: isDark ? 0.15 : 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: isComplete
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                            : Text('${index + 1}', style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800, fontSize: 15,
                                color: isComplete
                                    ? Colors.white
                                    : _catColor(azkar.category).withValues(alpha: isDark ? 0.90 : 0.80))),
                      ),
                      const SizedBox(width: 16),
                      
                      // Text/Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleText, 
                              maxLines: 2, 
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lora(fontWeight: FontWeight.w700, fontSize: 16, height: 1.3, color: kText)
                            ),
                            const SizedBox(height: 6),
                            Text(
                              azkar.reference.replaceAll('Hisnul Muslim, Chapter: ', '').replaceAll('Hisnul Muslim, ', '').trim(), 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 12, color: kSub)
                            ),
                            const SizedBox(height: 12),
                            
                            // Bottom tag (e.g. MORNING ADHKAR)
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFF927237)),
                                const SizedBox(width: 4),
                                Text(
                                  (azkar.category.toUpperCase() + " ADHKAR").replaceAll("FAVORITES", "FAVORITE"), 
                                  style: GoogleFonts.outfit(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.w800, 
                                    letterSpacing: 0.8, 
                                    color: const Color(0xFF927237)
                                  )
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      
                      // Count/Target
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('${azkar.recommendedCount}x', 
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800, 
                            fontSize: 14,
                            color: isComplete ? const Color(0xFF2BAE7C) : const Color(0xFF1B4E3B)
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
    
    return scaffold;
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyLoadedAudio;

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
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() {});
    });
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
    _audioPlayer.dispose();
    _hideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(String url) async {
    try {
      if (_currentlyLoadedAudio != url) {
        _currentlyLoadedAudio = url;
        await _audioPlayer.setUrl(url);
      }
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
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
          backgroundColor: _illustrationTopColor(
            widget.azkars[_currentIndex].id, isDark),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white.withValues(alpha: 0.90), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: AnimatedBuilder(
            animation: _pageController,
            builder: (context, _) {
              int ci = _pageController.positions.isNotEmpty ? _pageController.page?.round() ?? widget.initialIndex : widget.initialIndex;
              final catId = widget.azkars[ci].category;
              final catObj = widget.parentState._categories.cast<_Category?>().firstWhere((c) => c?.id == catId, orElse: () => null);
              final String catLabel = catObj?.label ?? 'Dhikr & Dua';
              return Column(mainAxisSize: MainAxisSize.min, children: [
                Text(catLabel, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.90))),
                const SizedBox(height: 2),
                Text('${ci + 1} of ${widget.azkars.length}',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.50))),
              ]);
            }
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: _AzkarProgressLine(
              azkars: widget.azkars,
              counts: widget.counts,
              currentIndex: _currentIndex,
              parentState: widget.parentState,
            ),
          ),
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
            if (_audioPlayer.playing) {
              _audioPlayer.stop();
            }
            if (mounted) setState(() { _currentIndex = nextIndex; });
          },
          itemCount: widget.azkars.length,
          itemBuilder: (context, index) {
            final azkar = widget.azkars[index];
            final count = widget.counts[azkar.id] ?? 0;
            final tapTarget = widget.parentState._getTarget(azkar.id, azkar.recommendedCount);
            final isComplete = count >= tapTarget;

            return Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 0, bottom: 120),
                    child: _AzkarCard(
                      azkar: azkar,
                      currentCount: count,
                      targetCount: tapTarget,
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
                // (progress shown in AppBar bottom line)
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
                              if (azkar.audioUrl != null && azkar.audioUrl!.isNotEmpty) ...[
                                _ToolbarBtn(
                                  icon: _audioPlayer.playing && _currentlyLoadedAudio == azkar.audioUrl
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: const Color(0xFF10B981),
                                  isDark: isDark,
                                  onTap: () => _toggleAudio(azkar.audioUrl!),
                                ),
                                _toolbarDivider(isDark),
                              ],
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
                                icon: widget.parentState._customTargets.containsKey(azkar.id)
                                    ? Icons.flag_rounded
                                    : Icons.flag_outlined,
                                color: const Color(0xFF7C3AED),
                                filled: widget.parentState._customTargets.containsKey(azkar.id),
                                isDark: isDark,
                                onTap: () {
                                  widget.parentState._showTargetPicker(
                                    context, azkar.id, azkar.recommendedCount,
                                  );
                                },
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

/// Patterns that should be highlighted in a distinct color (Bismillah & Isti'adhah).
final _kHighlightPatterns = RegExp(
  r'أَعُوْذُ بِاللّٰهِ مِنَ الشَّيْطَانِ الرَّجِيْمِ[.۝]*'
  r'|أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ[.۝]*'
  r'|أَعُوذُ بِاللَّهِ السَّمِيعِ الْعَلِيمِ مِنَ الشَّيْطَانِ الرَّجِيمِ[.۝]*'
  r'|بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ[.۝]*'
  r'|بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ[.۝]*'
  r'|بِسْمِ اللَّهِ الرَّحْمٰنِ الرَّحِيمِ[.۝]*',
);

/// Builds a RichText widget with Bismillah/Isti'adhah in a distinct color.
Widget _buildStyledArabic(String raw, TextStyle baseStyle, Color highlightColor) {
  final cleaned = _cleanArabic(raw);
  final spans = <TextSpan>[];
  int lastEnd = 0;

  final matches = _kHighlightPatterns.allMatches(cleaned).toList();
  
  for (int i = 0; i < matches.length; i++) {
    final m = matches[i];
    
    if (m.start > lastEnd) {
      String beforeText = cleaned.substring(lastEnd, m.start).trimRight();
      if (beforeText.isNotEmpty) {
        spans.add(TextSpan(text: '$beforeText\n'));
      }
    }
    
    String highlightedText = m.group(0)!.trim();
    bool hasTextAfter = cleaned.substring(m.end).trimLeft().isNotEmpty;
    String suffix = hasTextAfter ? '\n' : '';
    
    spans.add(TextSpan(
      text: '$highlightedText$suffix',
      style: baseStyle.copyWith(color: highlightColor),
    ));
    lastEnd = m.end;
  }
  
  if (lastEnd < cleaned.length) {
    String remainder = cleaned.substring(lastEnd).trimLeft();
    if (remainder.isNotEmpty) {
      spans.add(TextSpan(text: remainder));
    }
  }

  // If no matches were found, just use the raw text
  if (spans.isEmpty) {
    spans.add(TextSpan(text: cleaned));
  }

  return Text.rich(
    TextSpan(style: baseStyle, children: spans),
    textAlign: TextAlign.center,
    textDirection: TextDirection.rtl,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Beautiful Display Card for Azkaar
// ─────────────────────────────────────────────────────────────────────────────
class _AzkarCard extends StatelessWidget {
  final _Azkar azkar;
  final int currentCount;
  final int targetCount;
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
    required this.targetCount,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Illustration section ──
        _buildIllustration(
                azkarId: azkar.id,
                progress: targetCount == 0
                    ? 0.0
                    : (currentCount / targetCount).clamp(0.0, 1.0),
                isComplete: isComplete,
                tapCount: currentCount,
                pointsToday: pointsToday,
              ),

        // ── Card section with smooth top transition ──
        Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

            const SizedBox(height: 20),

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
                  _buildStyledArabic(
                    azkar.arabic,
                    _kArabicFonts[settings.arabicFontIdx.clamp(0, _kArabicFonts.length - 1)]
                        .style(settings.arabicFontSize, kText, 1.8, FontWeight.w700),
                    isDark ? const Color(0xFF5EADDB) : const Color(0xFF1A7A5C),
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
      ],
    );
  }
}

/// Returns the top gradient color of each illustration to fill behind the app bar.
Color _illustrationTopColor(String azkarId, bool isDark) {
  if (isDark) return const Color(0xFF121212);
  // Normalize evening_fixed_X → evening_lwa_X so both data sources match
  final id = azkarId.toLowerCase().replaceFirst('evening_fixed_', 'evening_lwa_');
  // Match the top color of each illustration's background gradient
  if (id.contains('ayat_kursi') || id.contains('ayat-kursi') ||
      id.contains('ayatul_kursi') || id.contains('ayatul-kursi') ||
      id == 'morning_lwa_1' || id == 'evening_lwa_1') {
    return const Color(0xFF0A1628); // Protection Shield
  }
  if (id.contains('three_quls') || id.contains('3_quls') ||
      id == 'morning_lwa_2' || id == 'evening_lwa_2') {
    return const Color(0xFF0D0A1F); // Three Quls
  }
  if (id.contains('sayyid_istighfar') || id.contains('sayyid-istighfar') ||
      id == 'morning_lwa_3' || id == 'evening_lwa_3') {
    return const Color(0xFF1A0E2E); // Gates of Jannah
  }
  if (id == 'morning_lwa_4' || id == 'evening_lwa_4' ||
      id.contains('anxiety') || id.contains('hamm_hazan')) {
    return const Color(0xFF0A0C12); // Breaking Chains
  }
  if (id == 'morning_lwa_5' || id == 'evening_lwa_5' ||
      id.contains('dua_afiyah') || id.contains('wellbeing')) {
    return const Color(0xFF0A1A18); // Six Wards
  }
  if (id == 'morning_lwa_6' || id == 'evening_lwa_6' ||
      id.contains('four_evils') || id.contains('4_evils')) {
    return const Color(0xFF0F0A14); // Repelling Light
  }
  if (id == 'morning_lwa_7' || id == 'evening_lwa_7' ||
      id.contains('entrust') || id.contains('ya_hayyu')) {
    return const Color(0xFF120818); // Cradled Heart
  }
  if (id == 'morning_lwa_8' || id == 'evening_lwa_8' ||
      id.contains('shukr') || id.contains('gratitude') || id.contains('nimat')) {
    return const Color(0xFF0E1608); // Overflowing Vessel
  }
  if (id == 'morning_lwa_9' || id == 'evening_lwa_9' ||
      id.contains('fitrah') || id.contains('tawhid')) {
    return const Color(0xFF0A0A1A); // Rising Dawn
  }
  if (id == 'morning_lwa_10' || id == 'evening_lwa_10' ||
      id.contains('praise_morning') || id.contains('uthni')) {
    return const Color(0xFF08101E); // Praise Ripples
  }
  if (id == 'morning_lwa_11' || id == 'evening_lwa_11' ||
      id.contains('good_day') || id.contains('khayr_yawm')) {
    return const Color(0xFF0A0E18); // Glowing Path
  }
  if (id == 'morning_lwa_12' || id == 'evening_lwa_12' ||
      id.contains('bless_day') || id.contains('bless_evening') ||
      id.contains('fath') || id.contains('barakah_yawm')) {
    return const Color(0xFF0C0818); // Five Blessings
  }
  if (id == 'morning_lwa_13' || id == 'evening_lwa_13' ||
      id.contains('freed_hellfire') || id.contains('ush_hidu')) {
    return const Color(0xFF1A0A08); // Freedom Flame
  }
  if (id == 'morning_lwa_14' || id == 'evening_lwa_14' ||
      id.contains('bika_asbahna') || id.contains('nushur')) {
    return const Color(0xFF0A0E1A); // Cycle of Return
  }
  if (id == 'morning_lwa_15' || id == 'evening_lwa_15' ||
      id.contains('afini_badani') || id.contains('good_health')) {
    return const Color(0xFF081218); // Three Vessels
  }
  if (id == 'morning_lwa_16' || id == 'evening_lwa_16' ||
      id.contains('hasbiyallah') || id.contains('arsh_azeem')) {
    return const Color(0xFF0A0814); // Seven Pillars
  }
  if (id == 'morning_lwa_17' || id == 'evening_lwa_17' ||
      id.contains('raditu_billah') || id.contains('pleased_allah')) {
    return const Color(0xFF0C1008); // Guiding Hand
  }
  if (id == 'morning_lwa_18' || id == 'evening_lwa_18' ||
      id.contains('la_yadurru') || id.contains('bismillah_protect')) {
    return const Color(0xFF08101A); // Invincible Name
  }
  if (id == 'morning_lwa_19' || id == 'evening_lwa_19' ||
      id.contains('subhanallahi_wabihamdih') || id.contains('subhanallahi_wa_bihamdih')) {
    return const Color(0xFF061218); // Ocean of Forgiveness
  }
  if (id == 'morning_lwa_20' || id == 'evening_lwa_20' ||
      id == 'la_ilaha_illallah' || id == 'post_prayer_la_ilaha' ||
      id.contains('unparalleled_reward')) {
    return const Color(0xFF0C0A14); // Unparalleled Scales
  }
  if (id == 'morning_lwa_21' || id == 'evening_lwa_21' ||
      id == 'subhanallah' || id == 'alhamdulillah' || id == 'allahu_akbar' ||
      id == 'post_prayer_subhanallah' || id == 'post_prayer_alhamdulillah' ||
      id == 'post_prayer_allahu_akbar' ||
      id.contains('sleeping_tasbih')) {
    return const Color(0xFF14100A); // Sunrise Glory
  }
  if (id == 'morning_lwa_22' || id == 'evening_lwa_22' ||
      id == 'salawat_ibrahimiyya' || id == 'salawat_simple' ||
      id == 'salawat_friday' || id.contains('salawat')) {
    return const Color(0xFF0A1210); // Ten Salawat
  }
  if (id == 'evening_lwa_23' || id.contains('kalimat_taammat')) {
    return const Color(0xFF08101A); // Invincible Name (evening protection)
  }
  if (id == 'morning_lwa_23' ||
      id == 'astaghfirullah' || id == 'istighfar_extended' ||
      id.contains('astaghfiru')) {
    return const Color(0xFF0E0A18); // Doors of Mercy
  }
  if (id == 'morning_lwa_24' || id == 'evening_lwa_24' ||
      id.contains('adada_khalqih') || id.contains('cosmic_weight')) {
    return const Color(0xFF080A14); // Cosmic Weight
  }
  return const Color(0xFF081623); // Default Noor Tree
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
}) {
  // Normalize evening_fixed_X → evening_lwa_X so both data sources match
  final id = azkarId.toLowerCase().replaceFirst('evening_fixed_', 'evening_lwa_');
  // Ayat al-Kursi — protection shield (all variants)
  if (id.contains('ayat_kursi') || id.contains('ayat-kursi') ||
      id.contains('ayatul_kursi') || id.contains('ayatul-kursi') ||
      id == 'morning_lwa_1' || id == 'evening_lwa_1') {
    return _ProtectionShield(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // 3 Quls — three layered barriers
  if (id.contains('three_quls') || id.contains('3_quls') ||
      id == 'morning_lwa_2' || id == 'evening_lwa_2') {
    return _ThreeQuls(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Sayyid al-Istighfar — gates of Jannah
  if (id.contains('sayyid_istighfar') || id.contains('sayyid-istighfar') ||
      id == 'morning_lwa_3' || id == 'evening_lwa_3') {
    return _GatesOfJannah(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #4 — Protection from anxiety, laziness, debt etc (breaking chains)
  if (id == 'morning_lwa_4' || id == 'evening_lwa_4' ||
      id.contains('anxiety') || id.contains('hamm_hazan')) {
    return _BreakingChains(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #5 — Well-being / protection from 6 directions (fortress ward)
  if (id == 'morning_lwa_5' || id == 'evening_lwa_5' ||
      id.contains('dua_afiyah') || id.contains('wellbeing')) {
    return _SixWards(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #6 — Protect from 4 evils (repelling shadows)
  if (id == 'morning_lwa_6' || id == 'evening_lwa_6' ||
      id.contains('four_evils') || id.contains('4_evils')) {
    return _RepellingLight(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #7 — Entrust all matters to Allah (cradled heart)
  if (id == 'morning_lwa_7' || id == 'evening_lwa_7' ||
      id.contains('entrust') || id.contains('ya_hayyu')) {
    return _CradledHeart(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #8 — Thank Allah / gratitude (overflowing vessel)
  if (id == 'morning_lwa_8' || id == 'evening_lwa_8' ||
      id.contains('shukr') || id.contains('gratitude') || id.contains('nimat')) {
    return _OverflowingVessel(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #9 — Renewing Tawhid (rising dawn)
  if (id == 'morning_lwa_9' || id == 'evening_lwa_9' ||
      id.contains('fitrah') || id.contains('tawhid')) {
    return _RisingDawn(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #10 — Praising Allah (praise ripples)
  if (id == 'morning_lwa_10' || id == 'evening_lwa_10' ||
      id.contains('praise_morning') || id.contains('uthni')) {
    return _PraiseRipples(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #11 — Ask for a good day (glowing path)
  if (id == 'morning_lwa_11' || id == 'evening_lwa_11' ||
      id.contains('good_day') || id.contains('khayr_yawm')) {
    return _GlowingPath(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #12 — Ask Allah to bless your day (five blessings descending)
  if (id == 'morning_lwa_12' || id == 'evening_lwa_12' ||
      id.contains('bless_day') || id.contains('bless_evening') ||
      id.contains('fath') || id.contains('barakah_yawm')) {
    return _FiveBlessings(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #13 — Get freed from the Hellfire (freedom flame)
  if (id == 'morning_lwa_13' || id == 'evening_lwa_13' ||
      id.contains('freed_hellfire') || id.contains('ush_hidu')) {
    return _FreedomFlame(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #14 — Upon entering the morning (cycle of return)
  if (id == 'morning_lwa_14' || id == 'evening_lwa_14' ||
      id.contains('bika_asbahna') || id.contains('nushur')) {
    return _CycleOfReturn(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #15 — Good health in body, hearing, sight (three vessels)
  if (id == 'morning_lwa_15' || id == 'evening_lwa_15' ||
      id.contains('afini_badani') || id.contains('good_health')) {
    return _ThreeVessels(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #16 — Allah will suffice you (seven pillars)
  if (id == 'morning_lwa_16' || id == 'evening_lwa_16' ||
      id.contains('hasbiyallah') || id.contains('arsh_azeem')) {
    return _SevenPillars(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #17 — Prophet holds your hand into Jannah (guiding hand)
  if (id == 'morning_lwa_17' || id == 'evening_lwa_17' ||
      id.contains('raditu_billah') || id.contains('pleased_allah')) {
    return _GuidingHand(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #18 — Protect from all harm by Bismillah (invincible name)
  if (id == 'morning_lwa_18' || id == 'evening_lwa_18' ||
      id.contains('la_yadurru') || id.contains('bismillah_protect')) {
    return _InvincibleName(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #19 — Sins forgiven like foam of the sea (ocean of forgiveness)
  if (id == 'morning_lwa_19' || id == 'evening_lwa_19' ||
      id.contains('subhanallahi_wabihamdih') || id.contains('subhanallahi_wa_bihamdih')) {
    return _OceanOfForgiveness(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #20 — Unparalleled reward: 10 slaves, 100 hasanat, protection
  if (id == 'morning_lwa_20' || id == 'evening_lwa_20' ||
      id == 'la_ilaha_illallah' || id == 'post_prayer_la_ilaha' ||
      id.contains('unparalleled_reward')) {
    return _UnparalleledScales(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #21 — Tasbih, Tahmid, Takbir (sunrise glory)
  if (id == 'morning_lwa_21' || id == 'evening_lwa_21' ||
      id == 'subhanallah' || id == 'alhamdulillah' || id == 'allahu_akbar' ||
      id == 'post_prayer_subhanallah' || id == 'post_prayer_alhamdulillah' ||
      id == 'post_prayer_allahu_akbar' ||
      id.contains('sleeping_tasbih')) {
    return _SunriseGlory(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #22 — Salawat upon the Prophet (ten salawat)
  if (id == 'morning_lwa_22' || id == 'evening_lwa_22' ||
      id == 'salawat_ibrahimiyya' || id == 'salawat_simple' ||
      id == 'salawat_friday' || id.contains('salawat')) {
    return _TenSalawat(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Evening #23 — Protection from all evil (evening only — perfect words shield)
  if (id == 'evening_lwa_23' || id.contains('kalimat_taammat')) {
    return _InvincibleName(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #23 — Seek forgiveness 100x (doors of mercy)
  if (id == 'morning_lwa_23' ||
      id == 'astaghfirullah' || id == 'istighfar_extended' ||
      id.contains('astaghfiru')) {
    return _DoorsOfMercy(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Morning #24 — 4 phrases that outweigh all dhikr (cosmic weight)
  if (id == 'morning_lwa_24' || id == 'evening_lwa_24' ||
      id.contains('adada_khalqih') || id.contains('cosmic_weight')) {
    return _CosmicWeight(
      progress: progress,
      isComplete: isComplete,
      tapCount: tapCount,
      pointsToday: pointsToday,
    );
  }
  // Default: Noor Tree
  return _NoorTree(
    progress: progress,
    isComplete: isComplete,
    tapCount: tapCount,
    pointsToday: pointsToday,
  );
}

/// Arabic text style for illustration labels — uses Amiri for elegant rendering.
TextStyle _illusArabic(double size, Color color, {FontWeight weight = FontWeight.w700}) =>
    GoogleFonts.amiri(fontSize: size, color: color, fontWeight: weight, height: 1.4);

/// Small Arabic tag style for phase/reward markers inside illustrations.
TextStyle _illusTag(double size, Color color) =>
    GoogleFonts.amiri(fontSize: size, color: color, fontWeight: FontWeight.w700, height: 1.3);

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
        height: 260,
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

    // 1. Rich night-sky gradient — warms as tree grows
    final warmth = progress * 0.3;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO((8 + warmth * 20).round(), (22 + warmth * 15).round(), (35 + warmth * 10).round(), 1.0),
            Color.fromRGBO((12 + warmth * 25).round(), (38 + warmth * 20).round(), (48 + warmth * 15).round(), 1.0),
            Color.fromRGBO((16 + warmth * 30).round(), (52 + warmth * 25).round(), (42 + warmth * 20).round(), 1.0),
          ],
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
      Paint()..color = Color.fromRGBO((8 + warmth * 20).round(), (22 + warmth * 15).round(), (35 + warmth * 10).round(), moonA * 0.92));
    canvas.drawCircle(
      Offset(moonX * w, moonY * h), moonR + 6,
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: moonA * 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // 4. Ground — soft grass-like glow
    final groundY = h * 0.82;
    final groundGlow = 0.10 + progress * 0.08 + (punchScale > 1.0 ? (punchScale - 1.0) * 1.5 : 0.0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, groundY + 10), width: w * 0.75, height: 24),
      Paint()
        ..color = Color.fromRGBO(52, 211, 153, groundGlow.clamp(0.0, 0.30))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    // Ground line
    canvas.drawLine(
      Offset(cx - w * 0.32, groundY), Offset(cx + w * 0.32, groundY),
      Paint()
        ..shader = LinearGradient(colors: [
          Colors.transparent,
          const Color(0xFF34D399).withValues(alpha: 0.25),
          Colors.transparent,
        ]).createShader(Rect.fromLTWH(cx - w * 0.32, groundY, w * 0.64, 1))
        ..strokeWidth = 0.8);

    // Apply punch scale transform for the tree (trunk + leaves)
    canvas.save();
    final treeCenterY = groundY - (groundY - h * 0.28) * progress * 0.5;
    canvas.translate(cx, treeCenterY);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -treeCenterY);

    // 5. Trunk — tapered with gradient
    if (progress > 0.02) {
      final trunkH = (groundY - h * 0.28) * progress.clamp(0.0, 1.0);
      final trunkTop = Offset(cx + sway * 2, groundY - trunkH);
      final trunkBot = Offset(cx, groundY);
      final trunkW = 7.5 * (0.5 + progress * 0.5);

      // Tapered trunk path (wider at base, thinner at top)
      final trunkPath = Path()
        ..moveTo(trunkBot.dx - trunkW * 0.5, trunkBot.dy)
        ..quadraticBezierTo(
          cx - trunkW * 0.3 + sway, groundY - trunkH * 0.5,
          trunkTop.dx - trunkW * 0.18, trunkTop.dy)
        ..lineTo(trunkTop.dx + trunkW * 0.18, trunkTop.dy)
        ..quadraticBezierTo(
          cx + trunkW * 0.3 + sway, groundY - trunkH * 0.5,
          trunkBot.dx + trunkW * 0.5, trunkBot.dy)
        ..close();
      canvas.drawPath(trunkPath, Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [const Color(0xFF5C3A1E), const Color(0xFF8B6341)],
        ).createShader(Rect.fromLTWH(trunkBot.dx - trunkW, trunkTop.dy, trunkW * 2, trunkH)));

      // Bark texture lines
      if (progress > 0.15) {
        final barkPaint = Paint()
          ..color = const Color(0xFF4A2E14).withValues(alpha: 0.25)
          ..strokeWidth = 0.6;
        for (int i = 0; i < 4; i++) {
          final by = groundY - trunkH * (0.15 + i * 0.22);
          canvas.drawLine(
            Offset(cx - trunkW * 0.15 + sway * (by / groundY), by),
            Offset(cx + trunkW * 0.05 + sway * (by / groundY), by - trunkH * 0.06),
            barkPaint);
        }
      }

      // Branches that reach toward leaf positions
      if (progress > 0.15) {
        _drawBranches(canvas, trunkBot, trunkTop, sway, progress,
          Paint()..color = const Color(0xFF6B4A2A)..strokeWidth = trunkW * 0.35..strokeCap = StrokeCap.round);
      }
    }

    // 6. Leaf orbs — vibrant and diverse
    if (progress > 0.05) {
      final trunkH = (groundY - h * 0.28) * progress;
      final treeTop = Offset(cx + sway * 2, groundY - trunkH);

      // (rx, ry, radius, minProgress, color)
      // Positioned to align with branch endpoints
      const leafDefs = [
        // Crown top cluster
        (0.0,  -0.05, 24.0, 0.10, Color(0xFF34D399)),  // emerald
        (-0.15, 0.06, 18.0, 0.15, Color(0xFF6EE7B7)),  // mint
        (0.18,  0.04, 17.0, 0.18, Color(0xFFFBBF24)),  // amber
        // Left branch cluster
        (-0.45, 0.16, 20.0, 0.22, Color(0xFF818CF8)),  // indigo
        (-0.62, 0.28, 16.0, 0.30, Color(0xFFA78BFA)),  // violet
        (-0.38, 0.32, 14.0, 0.35, Color(0xFF2DD4BF)),  // teal
        // Right branch cluster
        (0.48,  0.18, 19.0, 0.25, Color(0xFFF472B6)),  // pink
        (0.65,  0.30, 15.0, 0.32, Color(0xFFFB923C)),  // orange
        (0.42,  0.34, 13.0, 0.38, Color(0xFF34D399)),  // emerald
        // Lower left sub-branch
        (-0.72, 0.42, 14.0, 0.45, Color(0xFF38BDF8)),  // sky blue
        (-0.50, 0.48, 12.0, 0.52, Color(0xFFA78BFA)),  // violet
        // Lower right sub-branch
        (0.75,  0.44, 13.0, 0.50, Color(0xFFFBBF24)),  // amber
        (0.55,  0.50, 11.0, 0.55, Color(0xFFF472B6)),  // pink
        // Mid fills
        (0.0,   0.30, 15.0, 0.60, Color(0xFF6EE7B7)),  // mint
        (-0.22, 0.20, 13.0, 0.65, Color(0xFF34D399)),  // emerald
        (0.25,  0.22, 12.0, 0.70, Color(0xFF38BDF8)),  // sky blue
        // Top crown extras
        (0.0,  -0.12, 16.0, 0.80, Color(0xFFFFD97D)),  // gold
        (-0.10, 0.50, 10.0, 0.88, Color(0xFF2DD4BF)),  // teal
        (0.12,  0.52, 10.0, 0.94, Color(0xFFFB923C)),  // orange
      ];
      final halfW = w * 0.28;
      for (final (rx, ry, r, minP, col) in leafDefs) {
        if (progress < minP) continue;
        final leafA = ((progress - minP) / 0.10).clamp(0.0, 1.0);
        final leafPos = Offset(
          treeTop.dx + rx * halfW,
          treeTop.dy + ry * trunkH * 0.55,
        );
        final leafR = r * (0.65 + progress * 0.35) * (isComplete ? pulse : 1.0);
        // Soft glow
        canvas.drawCircle(leafPos, leafR + 10,
          Paint()
            ..color = col.withValues(alpha: leafA * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        // Orb fill with vibrant gradient
        canvas.drawCircle(leafPos, leafR,
          Paint()
            ..shader = RadialGradient(colors: [
              Colors.white.withValues(alpha: leafA * 0.50),
              col.withValues(alpha: leafA * 0.92),
              col.withValues(alpha: leafA * 0.30),
            ], stops: const [0.0, 0.45, 1.0])
            .createShader(Rect.fromCircle(center: leafPos, radius: leafR)));
        // Highlight dot
        canvas.drawCircle(
          Offset(leafPos.dx - leafR * 0.25, leafPos.dy - leafR * 0.25),
          leafR * 0.22,
          Paint()..color = Colors.white.withValues(alpha: leafA * 0.60));
      }

      // 6b. Golden crown glow on completion
      if (isComplete) {
        final crownY = treeTop.dy - 10;
        canvas.drawCircle(
          Offset(cx + sway * 2, crownY), 36 * pulse,
          Paint()
            ..color = const Color(0xFFD4AF37).withValues(alpha: 0.14 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
        canvas.drawCircle(
          Offset(cx + sway * 2, crownY), 20 * pulse,
          Paint()
            ..color = const Color(0xFFFFD97D).withValues(alpha: 0.22 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      }
    }

    // 6c. Small colorful plants growing beside the tree
    if (progress > 0.08) {
      // (xOffset from center, height, bloom radius, minProgress, stemColor, bloomColor)
      const plants = [
        // Left side
        (-0.30, 18.0, 4.5, 0.08, Color(0xFF4ADE80), Color(0xFFF472B6)),  // green stem, pink bloom
        (-0.22, 12.0, 3.5, 0.20, Color(0xFF34D399), Color(0xFFFBBF24)),  // emerald stem, amber bloom
        (-0.38, 15.0, 4.0, 0.35, Color(0xFF2DD4BF), Color(0xFF818CF8)),  // teal stem, indigo bloom
        (-0.18, 10.0, 3.0, 0.55, Color(0xFF4ADE80), Color(0xFFFF6B6B)),  // green stem, coral bloom
        (-0.34, 8.0,  2.5, 0.72, Color(0xFF34D399), Color(0xFFFCD34D)),  // emerald stem, yellow bloom
        // Right side
        (0.28,  16.0, 4.2, 0.12, Color(0xFF34D399), Color(0xFFFBBF24)),  // emerald stem, amber bloom
        (0.20,  11.0, 3.3, 0.28, Color(0xFF4ADE80), Color(0xFFA78BFA)),  // green stem, violet bloom
        (0.36,  14.0, 3.8, 0.42, Color(0xFF2DD4BF), Color(0xFFF472B6)),  // teal stem, pink bloom
        (0.16,  9.0,  2.8, 0.62, Color(0xFF34D399), Color(0xFF38BDF8)),  // emerald stem, sky bloom
        (0.32,  7.0,  2.3, 0.78, Color(0xFF4ADE80), Color(0xFFFF9F43)),  // green stem, orange bloom
      ];

      for (final (xOff, maxH, bloomR, minP, stemCol, bloomCol) in plants) {
        if (progress < minP) continue;
        final plantProg = ((progress - minP) / 0.18).clamp(0.0, 1.0);
        final px = cx + xOff * w;
        final plantH = maxH * plantProg;
        final stemTop = groundY - plantH;

        // Stem — thin curved line
        final stemPath = Path()
          ..moveTo(px, groundY)
          ..quadraticBezierTo(
            px + sway * 0.5 + xOff * 3, groundY - plantH * 0.6,
            px + sway * 0.8, stemTop);
        canvas.drawPath(stemPath, Paint()
          ..color = stemCol.withValues(alpha: plantProg * 0.70)
          ..strokeWidth = 1.3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

        // Small leaf on stem (appears at 40% of plant's growth)
        if (plantProg > 0.4) {
          final leafProg = ((plantProg - 0.4) / 0.3).clamp(0.0, 1.0);
          final leafY = groundY - plantH * 0.5;
          final leafX = px + sway * 0.3;
          final leafSize = 3.0 * leafProg;
          final leafPath = Path()
            ..moveTo(leafX, leafY)
            ..quadraticBezierTo(leafX + leafSize * (xOff > 0 ? 1.5 : -1.5), leafY - leafSize, leafX + leafSize * (xOff > 0 ? 0.5 : -0.5), leafY + leafSize * 0.3);
          canvas.drawPath(leafPath, Paint()
            ..color = stemCol.withValues(alpha: leafProg * 0.55)
            ..style = PaintingStyle.fill);
        }

        // Bloom/flower at top (appears at 60% of plant's growth)
        if (plantProg > 0.6) {
          final bloomProg = ((plantProg - 0.6) / 0.4).clamp(0.0, 1.0);
          final bx = px + sway * 0.8;
          final by = stemTop;
          final br = bloomR * bloomProg * (isComplete ? pulse : 1.0);

          // Glow
          canvas.drawCircle(Offset(bx, by), br + 4,
            Paint()
              ..color = bloomCol.withValues(alpha: bloomProg * 0.10)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
          // Bloom
          canvas.drawCircle(Offset(bx, by), br,
            Paint()
              ..shader = RadialGradient(colors: [
                Colors.white.withValues(alpha: bloomProg * 0.50),
                bloomCol.withValues(alpha: bloomProg * 0.80),
              ]).createShader(Rect.fromCircle(center: Offset(bx, by), radius: br)));
          // Bright center
          canvas.drawCircle(Offset(bx, by), br * 0.30,
            Paint()..color = Colors.white.withValues(alpha: bloomProg * 0.45));
        }
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
        style: _illusArabic(isComplete ? 13 : 12, isComplete ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.82)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

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
      final badgeY = h * 0.88 + tp2.height + 6;
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

      final branchPath = Path()
        ..moveTo(anchorX, anchorY)
        ..quadraticBezierTo(ctrlX, ctrlY, endX, endY);

      canvas.drawPath(branchPath, Paint()
        ..color = Color.fromRGBO(107, 74, 42, branchAlpha * 0.75)
        ..strokeWidth = basePaint.strokeWidth * thick
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke);
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

// =============================================================================
// 🛡️ Protection Shield (درع الحماية) — Ayat al-Kursi illustration
// =============================================================================
class _ProtectionShield extends StatefulWidget {
  final double progress;   // 0.0 → 1.0
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

  final List<_Particle> _particles =
      List.generate(20, (i) => _Particle(seed: i + 100));

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1900))
      ..repeat(reverse: true);

    _pCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.10)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.10, end: 0.96)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 12000))
      ..repeat();
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
        _pulseCtrl, _growCtrl, _starCtrl, _pCtrl,
        _punchCtrl, _shockCtrl, _rotateCtrl,
      ]),
      builder: (_, __) => SizedBox(
        height: 260,
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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1628), Color(0xFF0F2744), Color(0xFF132D46)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars
    const starPos = [
      (0.08, 0.06), (0.18, 0.14), (0.32, 0.04), (0.55, 0.09),
      (0.71, 0.05), (0.84, 0.15), (0.92, 0.07), (0.45, 0.18),
      (0.63, 0.22), (0.25, 0.20), (0.77, 0.18), (0.12, 0.27),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      sp.color = Colors.white.withValues(alpha: 0.20 + 0.55 * tw);
      canvas.drawCircle(
          Offset(starPos[i].$1 * w, starPos[i].$2 * h), 1.0 + tw * 1.0, sp);
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
    canvas.translate(cx, cy);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -cy);

    // 4. Person silhouette (praying figure)
    _drawPerson(canvas, cx, groundY);

    // 5. Shield dome — builds from bottom arcs upward
    if (progress > 0.02) {
      _drawShieldDome(canvas, cx, cy, w, h, groundY);
    }

    // 6. Orbiting runes / ayah markers around shield
    if (progress > 0.3) {
      _drawOrbitingMarkers(canvas, cx, cy, w);
    }

    canvas.restore(); // end punch scale

    // 7. Shockwave ring on tap
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.44;
      final ringR = maxR * shockPhase;
      final ringA = (1.0 - shockPhase) * 0.40;
      canvas.drawCircle(
        Offset(cx, cy),
        ringR,
        Paint()
          ..color = Color.fromRGBO(74, 144, 217, ringA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - shockPhase),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        ringR * 0.7,
        Paint()
          ..color = Color.fromRGBO(212, 175, 55, ringA * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * (1.0 - shockPhase),
      );
    }

    // 8. Floating particles
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        // Particles rise outward from shield center
        final angle = p.x * math.pi;
        final dist = w * 0.15 + t * w * 0.25;
        final px = cx + math.cos(angle) * dist;
        final py = cy - t * h * 0.35 + math.sin(t * math.pi * 2) * 8;
        final a = (1.0 - t) * 0.85;
        final pSize = p.size * (1.0 - t * 0.3);

        // Trail
        for (int trail = 1; trail <= 2; trail++) {
          final tOff = trail * 0.05;
          final tT = (t - tOff).clamp(0.0, 1.0);
          if (tT <= 0) continue;
          final tDist = w * 0.15 + tT * w * 0.25;
          final tpx = cx + math.cos(angle) * tDist;
          final tpy = cy - tT * h * 0.35 + math.sin(tT * math.pi * 2) * 8;
          canvas.drawCircle(
            Offset(tpx, tpy),
            pSize * (0.5 - trail * 0.12),
            Paint()
              ..color = const Color(0xFF4A90D9)
                  .withValues(alpha: a * (0.25 - trail * 0.08)),
          );
        }

        // Main particle with glow
        canvas.drawCircle(
          Offset(px, py),
          pSize + 3,
          Paint()
            ..color = const Color(0xFF4A90D9).withValues(alpha: a * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        canvas.drawCircle(
          Offset(px, py),
          pSize,
          Paint()..color = const Color(0xFF4A90D9).withValues(alpha: a),
        );
        canvas.drawCircle(
          Offset(px, py),
          pSize * 0.35,
          Paint()..color = Colors.white.withValues(alpha: a * 0.7),
        );
      }
    }

    // 9. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'محفوظ بإذن الله' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(
        text: label,
        style: _illusArabic(12, isComplete
              ? const Color(0xFFD4AF37)
              : Colors.white.withValues(alpha: 0.82)),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 10. Noor points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(
          text: badgeLabel,
          style: const TextStyle(
            color: Color(0xFF4A90D9),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: [
              Shadow(color: Color(0xFF4A90D9), blurRadius: 6),
              Shadow(color: Color(0xFF4A90D9), blurRadius: 14),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp3.width + 10;
      final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2;
      final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(0xFF4A90D9).withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(0xFF4A90D9).withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  /// Praying person silhouette
  void _drawPerson(Canvas canvas, double cx, double groundY) {
    final baseAlpha = isComplete ? 0.70 : 0.50;
    final personColor = isComplete
        ? Color.fromRGBO(212, 175, 55, baseAlpha)
        : Color.fromRGBO(139, 184, 232, baseAlpha);
    final glowColor = isComplete
        ? const Color(0xFFD4AF37).withValues(alpha: 0.12)
        : const Color(0xFF4A90D9).withValues(alpha: 0.08);
    final highlightColor = isComplete
        ? const Color(0xFFFFD97D).withValues(alpha: 0.30)
        : const Color(0xFFB8D4F0).withValues(alpha: 0.20);

    final fill = Paint()..color = personColor;
    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Scale reference — person is ~55px tall
    final baseY = groundY - 3; // feet
    final headCy = baseY - 52;
    const headR = 5.5;

    // ── Full-body glow behind person ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY - 26), width: 36, height: 58),
      glowPaint,
    );

    // ── Head with subtle highlight ──
    canvas.drawCircle(Offset(cx, headCy), headR + 4, Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawCircle(Offset(cx, headCy), headR, fill);
    canvas.drawCircle(
      Offset(cx - 1.5, headCy - 1.5), headR * 0.30,
      Paint()..color = highlightColor);

    // ── Neck ──
    final neckTop = headCy + headR - 0.5;
    final neckBot = neckTop + 4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, (neckTop + neckBot) / 2), width: 4.5, height: neckBot - neckTop),
        const Radius.circular(2),
      ),
      fill,
    );

    // ── Shoulders & torso (thobe/robe shape) ──
    final shoulderY = neckBot;
    final waistY = baseY - 18;
    final hemY = baseY - 2;

    final robePath = Path()
      // Left shoulder out
      ..moveTo(cx - 12, shoulderY + 2)
      // Up to shoulder curve
      ..quadraticBezierTo(cx - 8, shoulderY - 1, cx - 3, shoulderY)
      // Across neckline
      ..lineTo(cx + 3, shoulderY)
      ..quadraticBezierTo(cx + 8, shoulderY - 1, cx + 12, shoulderY + 2)
      // Right side down to waist (slight taper)
      ..quadraticBezierTo(cx + 11, waistY - 4, cx + 10, waistY)
      // Robe flares out to hem
      ..quadraticBezierTo(cx + 11, (waistY + hemY) / 2, cx + 13, hemY)
      // Across bottom
      ..lineTo(cx - 13, hemY)
      // Left side up
      ..quadraticBezierTo(cx - 11, (waistY + hemY) / 2, cx - 10, waistY)
      ..quadraticBezierTo(cx - 11, waistY - 4, cx - 12, shoulderY + 2)
      ..close();

    canvas.drawPath(robePath, fill);
    // Subtle center fold line
    canvas.drawLine(
      Offset(cx, shoulderY + 3), Offset(cx, hemY - 2),
      Paint()
        ..color = highlightColor
        ..strokeWidth = 0.6,
    );

    // ── Arms raised in du'a ──
    final armPaint = Paint()
      ..color = personColor
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Left arm — shoulder → elbow → raised hand
    final lShoulderX = cx - 11;
    final lElbowX = cx - 18;
    final lElbowY = shoulderY + 10;
    final lHandX = cx - 15;
    final lHandY = headCy - 2;

    final leftArm = Path()
      ..moveTo(lShoulderX, shoulderY + 2)
      ..quadraticBezierTo(lElbowX - 2, lElbowY, lElbowX, lElbowY)
      ..quadraticBezierTo(lElbowX - 3, (lElbowY + lHandY) / 2, lHandX, lHandY);
    canvas.drawPath(leftArm, armPaint);

    // Right arm (mirror)
    final rShoulderX = cx + 11;
    final rElbowX = cx + 18;
    final rElbowY = shoulderY + 10;
    final rHandX = cx + 15;
    final rHandY = headCy - 2;

    final rightArm = Path()
      ..moveTo(rShoulderX, shoulderY + 2)
      ..quadraticBezierTo(rElbowX + 2, rElbowY, rElbowX, rElbowY)
      ..quadraticBezierTo(rElbowX + 3, (rElbowY + rHandY) / 2, rHandX, rHandY);
    canvas.drawPath(rightArm, armPaint);

    // ── Hands (small open palms facing up) ──
    final handFill = Paint()..color = personColor;
    // Left palm
    canvas.drawOval(
      Rect.fromCenter(center: Offset(lHandX, lHandY), width: 5.5, height: 4),
      handFill,
    );
    // Right palm
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rHandX, rHandY), width: 5.5, height: 4),
      handFill,
    );

    // ── Small light between hands (du'a noor) ──
    if (progress > 0.2) {
      final noorAlpha = ((progress - 0.2) / 0.8).clamp(0.0, 1.0) * 0.35;
      canvas.drawCircle(
        Offset(cx, lHandY - 1),
        3.0 + (isComplete ? pulse * 1.5 : 0),
        Paint()
          ..color = Color.fromRGBO(212, 175, 55, noorAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  /// Glowing protective dome that builds with progress
  void _drawShieldDome(
      Canvas canvas, double cx, double cy, double w, double h, double groundY) {
    final shieldR = w * 0.28 * progress.clamp(0.0, 1.0);
    final shieldCy = groundY - 30;

    // Number of arc segments that appear with progress (8 total)
    final segCount = (progress * 8).ceil().clamp(0, 8);

    // Outer glow
    final glowAlpha = progress * (isComplete ? 0.18 : 0.10) * pulse;
    canvas.drawCircle(
      Offset(cx, shieldCy),
      shieldR + 20,
      Paint()
        ..color = Color.fromRGBO(74, 144, 217, glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // Shield arc segments — each is a portion of the dome
    final segAngle = math.pi / 8; // each segment covers π/8 radians
    for (int i = 0; i < segCount; i++) {
      // Segments build from bottom-left and bottom-right, meeting at top
      final leftAngle = math.pi + i * segAngle;
      final rightAngle = 2 * math.pi - (i + 1) * segAngle;
      final segAlpha =
          ((progress - i / 8.0) * 8).clamp(0.0, 1.0) * (isComplete ? 0.75 : 0.50);

      final arcPaint = Paint()
        ..color = isComplete
            ? Color.fromRGBO(212, 175, 55, segAlpha)
            : Color.fromRGBO(74, 144, 217, segAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isComplete ? 3.0 : 2.2
        ..strokeCap = StrokeCap.round;

      // Left arc segment
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, shieldCy), radius: shieldR),
        leftAngle,
        segAngle,
        false,
        arcPaint,
      );
      // Right arc segment (mirrors)
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, shieldCy), radius: shieldR),
        rightAngle,
        segAngle,
        false,
        arcPaint,
      );
    }

    // Inner secondary dome (slightly smaller, softer)
    if (progress > 0.3) {
      final innerR = shieldR * 0.78;
      final innerAlpha = ((progress - 0.3) / 0.7).clamp(0.0, 1.0) * 0.25;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, shieldCy), radius: innerR),
        math.pi,
        math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = isComplete
              ? Color.fromRGBO(255, 217, 125, innerAlpha)
              : Color.fromRGBO(139, 184, 232, innerAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Completion: full filled dome with radial gradient
    if (isComplete) {
      final fillAlpha = 0.08 * pulse;
      canvas.drawCircle(
        Offset(cx, shieldCy),
        shieldR,
        Paint()
          ..shader = RadialGradient(colors: [
            Color.fromRGBO(212, 175, 55, fillAlpha * 2),
            Color.fromRGBO(74, 144, 217, fillAlpha),
            Colors.transparent,
          ], stops: const [
            0.0,
            0.6,
            1.0
          ]).createShader(
              Rect.fromCircle(center: Offset(cx, shieldCy), radius: shieldR)),
      );

      // Light rays from top of dome
      for (int i = 0; i < 5; i++) {
        final rayAngle = math.pi * 1.15 + (i * math.pi * 0.7 / 4);
        final rayLen = shieldR * (0.6 + 0.4 * pulse);
        final startX = cx + math.cos(rayAngle) * shieldR * 0.9;
        final startY = shieldCy + math.sin(rayAngle) * shieldR * 0.9;
        final endX = cx + math.cos(rayAngle) * (shieldR + rayLen);
        final endY = shieldCy + math.sin(rayAngle) * (shieldR + rayLen);
        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          Paint()
            ..shader = LinearGradient(
              colors: [
                const Color(0xFFD4AF37).withValues(alpha: 0.30 * pulse),
                Colors.transparent,
              ],
            ).createShader(Rect.fromPoints(
                Offset(startX, startY), Offset(endX, endY)))
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  /// Small orbiting dot markers around the shield
  void _drawOrbitingMarkers(Canvas canvas, double cx, double cy, double w) {
    final orbitR = w * 0.33;
    final shieldCy = cy + (190 * 0.82 - 30 - cy);
    final markerCount = ((progress - 0.3) / 0.7 * 6).ceil().clamp(0, 6);

    for (int i = 0; i < markerCount; i++) {
      final baseAngle = rotatePhase * math.pi * 2 + i * (math.pi * 2 / 6);
      final mx = cx + math.cos(baseAngle) * orbitR;
      final my = shieldCy + math.sin(baseAngle) * orbitR * 0.45;
      final mAlpha = isComplete ? 0.60 : 0.35;

      // Glow
      canvas.drawCircle(
        Offset(mx, my),
        5.0,
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: mAlpha * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Dot
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

  final List<_Particle> _particles =
      List.generate(18, (i) => _Particle(seed: i + 200));

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1900))
      ..repeat(reverse: true);

    _pCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.10)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.10, end: 0.96)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
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
        _pulseCtrl, _growCtrl, _starCtrl, _pCtrl,
        _punchCtrl, _shockCtrl, _shimmerCtrl,
      ]),
      builder: (_, __) => SizedBox(
        height: 260,
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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D0A1F), Color(0xFF15102E), Color(0xFF1A1340)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars
    const starPos = [
      (0.10, 0.07), (0.22, 0.15), (0.38, 0.05), (0.52, 0.10),
      (0.68, 0.06), (0.82, 0.14), (0.90, 0.08), (0.42, 0.20),
      (0.60, 0.24), (0.28, 0.22), (0.75, 0.19), (0.15, 0.28),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      sp.color = Colors.white.withValues(alpha: 0.18 + 0.50 * tw);
      canvas.drawCircle(
          Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.9 + tw * 1.0, sp);
    }

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -cy);

    // 3. Central book/Quran symbol
    _drawQuranSymbol(canvas, cx, cy);

    // 4. Three concentric barrier layers
    _drawBarrierLayers(canvas, cx, cy, w);

    canvas.restore();

    // 5. Shockwave on tap
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.44;
      final ringA = (1.0 - shockPhase) * 0.35;
      // Triple-colored shockwave
      for (int i = 0; i < 3; i++) {
        final delay = i * 0.08;
        final t = (shockPhase - delay).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final r = maxR * t;
        canvas.drawCircle(
          Offset(cx, cy), r,
          Paint()
            ..color = _layerColors[i].withValues(alpha: ringA * (1.0 - i * 0.2))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0 * (1.0 - t),
        );
      }
    }

    // 6. Floating particles
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final angle = p.x * math.pi * 2;
        final dist = 20 + t * w * 0.28;
        final px = cx + math.cos(angle) * dist;
        final py = cy + math.sin(angle) * dist * 0.6 - t * 20;
        final a = (1.0 - t) * 0.80;
        final pSize = p.size * (1.0 - t * 0.3);

        // Pick layer color based on particle index
        final layerIdx = (p.x.abs() * 3).floor().clamp(0, 2);
        final pColor = _layerColors[layerIdx];

        canvas.drawCircle(Offset(px, py), pSize + 2,
          Paint()
            ..color = pColor.withValues(alpha: a * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawCircle(
            Offset(px, py), pSize, Paint()..color = pColor.withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35,
            Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      }
    }

    // 7. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'كُفيت بإذن الله' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(
        text: label,
        style: _illusArabic(12, isComplete
              ? const Color(0xFFD4AF37)
              : Colors.white.withValues(alpha: 0.82)),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 8. Points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(
          text: badgeLabel,
          style: const TextStyle(
            color: Color(0xFF8B5CF6),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: [
              Shadow(color: Color(0xFF8B5CF6), blurRadius: 6),
              Shadow(color: Color(0xFF8B5CF6), blurRadius: 14),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp3.width + 10;
      final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2;
      final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, Paint()
        ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()
        ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  /// Central Quran/book icon
  void _drawQuranSymbol(Canvas canvas, double cx, double cy) {
    final bookAlpha = isComplete ? 0.70 : 0.45;
    final bookColor = isComplete
        ? Color.fromRGBO(212, 175, 55, bookAlpha)
        : Color.fromRGBO(200, 200, 220, bookAlpha);
    final glowAlpha = isComplete ? 0.15 : 0.08;

    // Glow behind book
    canvas.drawCircle(
      Offset(cx, cy), 22,
      Paint()
        ..color = (isComplete ? const Color(0xFFD4AF37) : const Color(0xFF8B5CF6))
            .withValues(alpha: glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Open book shape — two pages
    final bookPaint = Paint()
      ..color = bookColor
      ..style = PaintingStyle.fill;

    // Left page
    final leftPage = Path()
      ..moveTo(cx - 1, cy - 10)
      ..quadraticBezierTo(cx - 14, cy - 12, cx - 16, cy - 6)
      ..lineTo(cx - 15, cy + 8)
      ..quadraticBezierTo(cx - 13, cy + 10, cx - 1, cy + 9)
      ..close();
    canvas.drawPath(leftPage, bookPaint);

    // Right page
    final rightPage = Path()
      ..moveTo(cx + 1, cy - 10)
      ..quadraticBezierTo(cx + 14, cy - 12, cx + 16, cy - 6)
      ..lineTo(cx + 15, cy + 8)
      ..quadraticBezierTo(cx + 13, cy + 10, cx + 1, cy + 9)
      ..close();
    canvas.drawPath(rightPage, bookPaint);

    // Spine
    canvas.drawLine(
      Offset(cx, cy - 11), Offset(cx, cy + 10),
      Paint()
        ..color = bookColor
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Page lines (subtle text lines)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: bookAlpha * 0.35)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 4; i++) {
      final ly = cy - 5 + i * 3.5;
      canvas.drawLine(Offset(cx - 12, ly), Offset(cx - 3, ly), linePaint);
      canvas.drawLine(Offset(cx + 3, ly), Offset(cx + 12, ly), linePaint);
    }

    // Small highlight on top-left corner of book
    canvas.drawCircle(
      Offset(cx - 8, cy - 8), 2.5,
      Paint()..color = Colors.white.withValues(alpha: bookAlpha * 0.25),
    );
  }

  /// Three concentric barrier rings
  void _drawBarrierLayers(Canvas canvas, double cx, double cy, double w) {
    // Each layer appears at a different progress threshold
    // Layer 0 (Ikhlas/inner): 0% → 33%
    // Layer 1 (Falaq/middle): 33% → 66%
    // Layer 2 (Nas/outer): 66% → 100%
    const layerRadii = [38.0, 56.0, 74.0];
    const layerThresholds = [0.0, 0.33, 0.66];

    for (int i = 0; i < 3; i++) {
      final threshold = layerThresholds[i];
      if (progress <= threshold) continue;

      final layerProgress = ((progress - threshold) / 0.33).clamp(0.0, 1.0);
      final color = _layerColors[i];
      final radius = layerRadii[i] * (0.6 + layerProgress * 0.4);

      // How much of the ring to draw (sweeps from 0 to full circle)
      final sweep = math.pi * 2 * layerProgress;

      // Outer glow
      final glowA = layerProgress * (isComplete ? 0.14 : 0.08) * pulse;
      canvas.drawCircle(
        Offset(cx, cy), radius + 8,
        Paint()
          ..color = color.withValues(alpha: glowA)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );

      // Main arc — starts from top, sweeps clockwise
      final startAngle = -math.pi / 2 + (shimmerPhase * math.pi * 0.3 * (i % 2 == 0 ? 1 : -1));
      final arcAlpha = layerProgress * (isComplete ? 0.65 : 0.45);

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
          Offset(tipX, tipY), 3.5,
          Paint()
            ..color = color.withValues(alpha: 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(tipX, tipY), 2.0,
          Paint()..color = color.withValues(alpha: arcAlpha * 1.2),
        );
      }

      // Completion: small Surah label dots at 3 positions
      if (isComplete) {
        final dotAngle = -math.pi / 2 + i * (math.pi * 2 / 3);
        final dx = cx + math.cos(dotAngle) * radius;
        final dy = cy + math.sin(dotAngle) * radius;
        canvas.drawCircle(Offset(dx, dy), 4.0 * pulse,
          Paint()
            ..color = color.withValues(alpha: 0.30)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawCircle(Offset(dx, dy), 2.5,
          Paint()..color = color.withValues(alpha: 0.70));
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
          Offset(innerX, innerY), Offset(outerX, outerY),
          Paint()
            ..shader = LinearGradient(
              colors: [
                const Color(0xFFD4AF37).withValues(alpha: 0.08 * pulse),
                const Color(0xFF8B5CF6).withValues(alpha: 0.15 * pulse),
                Colors.transparent,
              ],
            ).createShader(Rect.fromPoints(
                Offset(innerX, innerY), Offset(outerX, outerY)))
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

  final List<_Particle> _particles =
      List.generate(18, (i) => _Particle(seed: i + 300));

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1900))
      ..repeat(reverse: true);

    _pCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.10)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.10, end: 0.96)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _rayCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat();
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
        _pulseCtrl, _growCtrl, _starCtrl, _pCtrl,
        _punchCtrl, _shockCtrl, _rayCtrl,
      ]),
      builder: (_, __) => SizedBox(
        height: 260,
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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0E2E), Color(0xFF1F1435), Color(0xFF251A3A)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars
    const starPos = [
      (0.09, 0.07), (0.20, 0.16), (0.35, 0.05), (0.50, 0.11),
      (0.65, 0.06), (0.80, 0.14), (0.91, 0.08), (0.40, 0.21),
      (0.58, 0.25), (0.26, 0.23), (0.73, 0.20), (0.14, 0.29),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      sp.color = Colors.white.withValues(alpha: 0.15 + 0.45 * tw);
      canvas.drawCircle(
          Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.9 + tw * 0.9, sp);
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
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -gateCy);

    // 3. Light behind gates (grows with progress)
    _drawInnerLight(canvas, cx, groundY, w, h);

    // 4. Gate structure
    _drawGates(canvas, cx, groundY, w);

    // 5. Arch above gates
    _drawArch(canvas, cx, groundY, w);

    canvas.restore();

    // 6. Shockwave on tap
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.42;
      final ringA = (1.0 - shockPhase) * 0.35;
      final r = maxR * shockPhase;
      canvas.drawCircle(
        Offset(cx, gateCy), r,
        Paint()
          ..color = Color.fromRGBO(212, 175, 55, ringA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - shockPhase),
      );
      canvas.drawCircle(
        Offset(cx, gateCy), r * 0.7,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, ringA * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * (1.0 - shockPhase),
      );
    }

    // 7. Floating particles — rise upward through the gate opening
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final px = cx + p.x * w * 0.15 + math.sin(t * math.pi * 2) * 6;
        final py = groundY - t * h * 0.65;
        final a = (1.0 - t) * 0.80;
        final pSize = p.size * (1.0 - t * 0.3);

        canvas.drawCircle(Offset(px, py), pSize + 2,
          Paint()
            ..color = const Color(0xFFD4AF37).withValues(alpha: a * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawCircle(
            Offset(px, py), pSize, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35,
            Paint()..color = Colors.white.withValues(alpha: a * 0.65));
      }
    }

    // 8. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'غُفر لك بإذن الله' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(
        text: label,
        style: _illusArabic(12, isComplete
              ? const Color(0xFFD4AF37)
              : Colors.white.withValues(alpha: 0.82)),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 9. Points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(
          text: badgeLabel,
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: [
              Shadow(color: Color(0xFFD4AF37), blurRadius: 6),
              Shadow(color: Color(0xFFD4AF37), blurRadius: 14),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp3.width + 10;
      final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2;
      final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  /// Warm paradise light that shines through the gap between the gates
  void _drawInnerLight(Canvas canvas, double cx, double groundY, double w, double h) {
    if (progress <= 0.05) return;

    // Gap width grows with progress (gates opening)
    final gapWidth = w * 0.22 * progress;
    final lightAlpha = progress * (isComplete ? 0.40 : 0.20) * pulse;

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
      Offset(cx, groundY - 45), gapWidth * 1.5,
      Paint()
        ..color = Color.fromRGBO(255, 248, 220, lightAlpha * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // Light rays fanning upward from the gap (on completion)
    if (progress > 0.5) {
      final rayAlpha = ((progress - 0.5) / 0.5) * (isComplete ? 0.25 : 0.10) * pulse;
      for (int i = 0; i < 7; i++) {
        final angle = -math.pi / 2 + (i - 3) * 0.15 + math.sin(rayPhase * math.pi * 2 + i) * 0.03;
        final rayLen = 50 + (isComplete ? 25.0 : 0.0);
        final startX = cx;
        final startY = groundY - 65;
        final endX = startX + math.cos(angle) * rayLen;
        final endY = startY + math.sin(angle) * rayLen;
        canvas.drawLine(
          Offset(startX, startY), Offset(endX, endY),
          Paint()
            ..shader = LinearGradient(
              colors: [
                Color.fromRGBO(255, 248, 220, rayAlpha),
                Colors.transparent,
              ],
            ).createShader(Rect.fromPoints(
                Offset(startX, startY), Offset(endX, endY)))
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  /// Two gate doors that open outward with progress
  void _drawGates(Canvas canvas, double cx, double groundY, double w) {
    final gateH = 65.0;
    final gateW = 22.0;
    final gateTop = groundY - gateH;

    // Opening angle: 0 (closed) → progress-based swing outward
    final openAmount = progress * gateW * 0.9;

    final gateColor = isComplete
        ? const Color(0xFFD4AF37).withValues(alpha: 0.70)
        : const Color(0xFF8B7355).withValues(alpha: 0.55 + progress * 0.20);
    final gateEdge = isComplete
        ? const Color(0xFFFFD97D).withValues(alpha: 0.50)
        : const Color(0xFFB8976A).withValues(alpha: 0.35);
    final decorColor = isComplete
        ? const Color(0xFFFFE8A0).withValues(alpha: 0.45)
        : const Color(0xFFB8976A).withValues(alpha: 0.25);

    // Left gate door
    final leftX = cx - 2 - openAmount;
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(leftX - gateW, gateTop, gateW, gateH),
      const Radius.circular(2),
    );
    canvas.drawRRect(leftRect, Paint()..color = gateColor);
    canvas.drawRRect(leftRect, Paint()
      ..color = gateEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);

    // Left door decorative panels (2 rectangles)
    for (int i = 0; i < 2; i++) {
      final panelY = gateTop + 8 + i * (gateH * 0.44);
      final panelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(leftX - gateW + 4, panelY, gateW - 8, gateH * 0.34),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(panelRect, Paint()
        ..color = decorColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8);
    }

    // Left door handle
    canvas.drawCircle(
      Offset(leftX - 4, groundY - gateH * 0.45),
      2.0, Paint()..color = decorColor);

    // Right gate door (mirror)
    final rightX = cx + 2 + openAmount;
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rightX, gateTop, gateW, gateH),
      const Radius.circular(2),
    );
    canvas.drawRRect(rightRect, Paint()..color = gateColor);
    canvas.drawRRect(rightRect, Paint()
      ..color = gateEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);

    // Right door decorative panels
    for (int i = 0; i < 2; i++) {
      final panelY = gateTop + 8 + i * (gateH * 0.44);
      final panelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(rightX + 4, panelY, gateW - 8, gateH * 0.34),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(panelRect, Paint()
        ..color = decorColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8);
    }

    // Right door handle
    canvas.drawCircle(
      Offset(rightX + 4, groundY - gateH * 0.45),
      2.0, Paint()..color = decorColor);

    // Gate pillars (fixed, don't move)
    final pillarColor = isComplete
        ? const Color(0xFFD4AF37).withValues(alpha: 0.55)
        : const Color(0xFF6B5B45).withValues(alpha: 0.50);
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
    final capColor = isComplete
        ? const Color(0xFFFFD97D).withValues(alpha: 0.50)
        : const Color(0xFF8B7355).withValues(alpha: 0.40);
    canvas.drawCircle(
      Offset(cx - gateW - openAmount - 3.5, gateTop - 6), 3.5,
      Paint()..color = capColor);
    canvas.drawCircle(
      Offset(cx + gateW + openAmount + 3.5, gateTop - 6), 3.5,
      Paint()..color = capColor);
  }

  /// Pointed arch above the gates
  void _drawArch(Canvas canvas, double cx, double groundY, double w) {
    if (progress < 0.15) return;

    final archAlpha = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
    final gateH = 65.0;
    final gateW = 22.0;
    final openAmount = progress * gateW * 0.9;
    final archTop = groundY - gateH - 22;
    final archLeft = cx - gateW - openAmount - 8;
    final archRight = cx + gateW + openAmount + 8;
    final archMidY = groundY - gateH - 4;

    final archColor = isComplete
        ? Color.fromRGBO(212, 175, 55, archAlpha * 0.60)
        : Color.fromRGBO(139, 115, 85, archAlpha * 0.45);

    // Pointed Islamic arch shape
    final archPath = Path()
      ..moveTo(archLeft, archMidY)
      ..quadraticBezierTo(archLeft, archTop + 8, cx, archTop)
      ..quadraticBezierTo(archRight, archTop + 8, archRight, archMidY);

    canvas.drawPath(archPath, Paint()
      ..color = archColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round);

    // Inner arch (smaller, more subtle)
    if (progress > 0.4) {
      final innerAlpha = ((progress - 0.4) / 0.6).clamp(0.0, 1.0) * 0.30;
      final inset = 5.0;
      final innerPath = Path()
        ..moveTo(archLeft + inset, archMidY)
        ..quadraticBezierTo(archLeft + inset, archTop + 12, cx, archTop + 6)
        ..quadraticBezierTo(archRight - inset, archTop + 12, archRight - inset, archMidY);

      canvas.drawPath(innerPath, Paint()
        ..color = isComplete
            ? Color.fromRGBO(255, 217, 125, innerAlpha)
            : Color.fromRGBO(184, 151, 106, innerAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
    }

    // Keystone at arch peak
    if (progress > 0.6) {
      final kAlpha = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
      final kColor = isComplete
          ? Color.fromRGBO(212, 175, 55, kAlpha * 0.65 * pulse)
          : Color.fromRGBO(184, 151, 106, kAlpha * 0.40);

      // Diamond keystone
      final kPath = Path()
        ..moveTo(cx, archTop - 3)
        ..lineTo(cx + 5, archTop + 3)
        ..lineTo(cx, archTop + 9)
        ..lineTo(cx - 5, archTop + 3)
        ..close();
      canvas.drawPath(kPath, Paint()..color = kColor);

      // Glow around keystone on completion
      if (isComplete) {
        canvas.drawCircle(
          Offset(cx, archTop + 3), 10 * pulse,
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

  final List<_Particle> _particles =
      List.generate(16, (i) => _Particle(seed: i + 400));

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1900))
      ..repeat(reverse: true);

    _pCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.10)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.10, end: 0.96)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3500))
      ..repeat(reverse: true);
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
        _pulseCtrl, _growCtrl, _starCtrl, _pCtrl,
        _punchCtrl, _shockCtrl, _floatCtrl,
      ]),
      builder: (_, __) => SizedBox(
        height: 260,
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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO((10 + bgBrightness * 40).round(), (12 + bgBrightness * 35).round(), (18 + bgBrightness * 30).round(), 1.0),
            Color.fromRGBO((15 + bgBrightness * 50).round(), (18 + bgBrightness * 45).round(), (25 + bgBrightness * 40).round(), 1.0),
            Color.fromRGBO((18 + bgBrightness * 60).round(), (22 + bgBrightness * 55).round(), (30 + bgBrightness * 50).round(), 1.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars (more visible as chains break)
    const starPos = [
      (0.10, 0.08), (0.22, 0.16), (0.38, 0.06), (0.52, 0.12),
      (0.68, 0.07), (0.82, 0.15), (0.90, 0.09), (0.42, 0.22),
      (0.58, 0.26), (0.28, 0.24), (0.75, 0.21),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      final starAlpha = (0.08 + progress * 0.35 + 0.45 * tw * progress);
      sp.color = Colors.white.withValues(alpha: starAlpha.clamp(0.0, 0.8));
      canvas.drawCircle(
          Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.8 + tw * 1.0, sp);
    }

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -cy);

    // 3. Central light (person freed — grows as chains break)
    _drawFreedomLight(canvas, cx, cy, w);

    // 4. Four chains arranged around center
    _drawChains(canvas, cx, cy, w, h);

    canvas.restore();

    // 5. Shockwave on tap
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.40;
      final ringA = (1.0 - shockPhase) * 0.35;
      final r = maxR * shockPhase;
      canvas.drawCircle(
        Offset(cx, cy), r,
        Paint()
          ..color = Color.fromRGBO(16, 185, 129, ringA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - shockPhase),
      );
    }

    // 6. Floating sparks on tap
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final angle = p.x * math.pi * 2;
        final dist = 15 + t * w * 0.30;
        final px = cx + math.cos(angle) * dist;
        final py = cy + math.sin(angle) * dist * 0.7 - t * 15;
        final a = (1.0 - t) * 0.75;
        final pSize = p.size * (1.0 - t * 0.3);

        // Spark color — bright teal/green (freedom)
        final sparkColor = isComplete
            ? const Color(0xFFD4AF37)
            : const Color(0xFF10B981);

        canvas.drawCircle(Offset(px, py), pSize + 2,
          Paint()
            ..color = sparkColor.withValues(alpha: a * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(
            Offset(px, py), pSize, Paint()..color = sparkColor.withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35,
            Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      }
    }

    // 7. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'حُررت بإذن الله' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(
        text: label,
        style: _illusArabic(12, isComplete
              ? const Color(0xFF10B981)
              : Colors.white.withValues(alpha: 0.82)),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 8. Points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(
          text: badgeLabel,
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: [
              Shadow(color: Color(0xFF10B981), blurRadius: 6),
              Shadow(color: Color(0xFF10B981), blurRadius: 14),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp3.width + 10;
      final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2;
      final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  /// Central light that grows as chains break — representing freedom
  void _drawFreedomLight(Canvas canvas, double cx, double cy, double w) {
    if (progress < 0.05) return;

    final lightR = 12 + progress * 25;
    final alpha = progress * (isComplete ? 0.30 : 0.15) * pulse;

    // Outer glow
    canvas.drawCircle(
      Offset(cx, cy), lightR + 15,
      Paint()
        ..color = Color.fromRGBO(16, 185, 129, alpha * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // Inner glow
    canvas.drawCircle(
      Offset(cx, cy), lightR,
      Paint()
        ..shader = RadialGradient(colors: [
          Color.fromRGBO(255, 255, 255, alpha * 0.8),
          Color.fromRGBO(16, 185, 129, alpha * 0.6),
          Colors.transparent,
        ], stops: const [0.0, 0.5, 1.0])
        .createShader(Rect.fromCircle(center: Offset(cx, cy), radius: lightR)),
    );

    // On completion: golden core
    if (isComplete) {
      canvas.drawCircle(
        Offset(cx, cy), 8 * pulse,
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: 0.35 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(cx, cy), 4,
        Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.50),
      );
    }
  }

  /// Four chains arranged around the center — each breaks at its progress threshold
  void _drawChains(Canvas canvas, double cx, double cy, double w, double h) {
    // 4 chains positioned at top, right, bottom, left
    final positions = [
      (cx, cy - 50, 0.0, -1.0),   // top — vertical up
      (cx + 55, cy, 1.0, 0.0),    // right — horizontal
      (cx, cy + 45, 0.0, 1.0),    // bottom — vertical down
      (cx - 55, cy, -1.0, 0.0),   // left — horizontal
    ];

    for (int i = 0; i < 4; i++) {
      final (startX, startY, dirX, dirY) = positions[i];
      final breakThreshold = (i + 1) * 0.25; // breaks at 25%, 50%, 75%, 100%
      final isBroken = progress >= breakThreshold;
      final chainProgress = ((progress - i * 0.25) / 0.25).clamp(0.0, 1.0);

      _drawSingleChain(
        canvas,
        startX, startY,
        dirX, dirY,
        i, isBroken, chainProgress,
        cx, cy,
      );
    }
  }

  void _drawSingleChain(
    Canvas canvas,
    double startX, double startY,
    double dirX, double dirY,
    int index, bool isBroken, double chainProgress,
    double cx, double cy,
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
        final fallX = startX + dirX * dist + dirX * linkFall * 12 + math.sin(floatPhase * math.pi * 2 + j) * linkFall * 3;
        final fallY = startY + dirY * dist + linkFall * 25 + linkFall * linkFall * 15;
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
        canvas.drawRRect(linkRect, Paint()
          ..color = color.withValues(alpha: fallAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

        canvas.restore();
      }

      // Break spark at the connection point
      if (chainProgress < 0.6) {
        final sparkA = (1.0 - chainProgress / 0.6) * 0.60;
        canvas.drawCircle(
          Offset(startX, startY), 5 * (1.0 - chainProgress * 0.5),
          Paint()
            ..color = const Color(0xFF10B981).withValues(alpha: sparkA)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(startX, startY), 2.5,
          Paint()..color = Colors.white.withValues(alpha: sparkA * 0.8),
        );
      }
    } else {
      // Chain is intact — draw taut links connecting to center
      final chainAlpha = 0.55 - progress * 0.15; // fade slightly as overall progress grows

      for (int j = 0; j < linkCount; j++) {
        final dist = j * (linkLen + 2);
        final lx = startX + dirX * dist;
        final ly = startY + dirY * dist;

        // Subtle strain vibration as progress approaches break point
        final strainProg = ((progress - index * 0.25) / 0.25).clamp(0.0, 1.0);
        final shake = strainProg > 0.5
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
        canvas.drawRRect(linkRect, Paint()
          ..color = color.withValues(alpha: chainAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);

        canvas.restore();
      }

      // Connection dot to center
      canvas.drawCircle(
        Offset(startX, startY), 2.5,
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

  final List<_Particle> _particles =
      List.generate(18, (i) => _Particle(seed: i + 500));

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1900))
      ..repeat(reverse: true);
    _pCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat();
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
      for (final p in _particles) { p.reset(); }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose();
    _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl, _growCtrl, _starCtrl, _pCtrl,
        _punchCtrl, _shockCtrl, _glowCtrl,
      ]),
      builder: (_, __) => SizedBox(
        height: 260,
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
    Color(0xFF10B981), // below — emerald
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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1A18), Color(0xFF0E2A25), Color(0xFF12362E)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars
    const starPos = [
      (0.09, 0.06), (0.21, 0.15), (0.36, 0.05), (0.53, 0.10),
      (0.67, 0.06), (0.81, 0.14), (0.91, 0.08), (0.43, 0.20),
      (0.60, 0.24), (0.27, 0.22), (0.74, 0.19),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      sp.color = Colors.white.withValues(alpha: 0.18 + 0.50 * tw);
      canvas.drawCircle(
          Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.9 + tw * 1.0, sp);
    }

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -cy);

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
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.42;
      final ringA = (1.0 - shockPhase) * 0.35;
      final r = maxR * shockPhase;
      canvas.drawCircle(Offset(cx, cy), r, Paint()
        ..color = Color.fromRGBO(46, 196, 169, ringA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - shockPhase));
    }

    // 7. Particles — rise outward in 6 directions
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final dirIdx = (p.x.abs() * 6).floor().clamp(0, 5);
        final angle = dirIdx * math.pi / 3 + math.pi / 6;
        final dist = 15 + t * w * 0.28;
        final px = cx + math.cos(angle) * dist + math.sin(t * math.pi * 2) * 4;
        final py = cy + math.sin(angle) * dist * 0.6 - t * 10;
        final a = (1.0 - t) * 0.75;
        final pSize = p.size * (1.0 - t * 0.3);
        final pColor = _wardColors[dirIdx];

        canvas.drawCircle(Offset(px, py), pSize + 2, Paint()
          ..color = pColor.withValues(alpha: a * 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(Offset(px, py), pSize, Paint()..color = pColor.withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35, Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      }
    }

    // 8. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'عافاك الله' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(text: label, style: _illusArabic(12, isComplete ? const Color(0xFF2EC4A9) : Colors.white.withValues(alpha: 0.82))),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 9. Points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(text: badgeLabel, style: const TextStyle(
          color: Color(0xFF2EC4A9), fontSize: 10, fontWeight: FontWeight.w800,
          letterSpacing: 0.5, shadows: [Shadow(color: Color(0xFF2EC4A9), blurRadius: 6)])),
        textDirection: TextDirection.ltr,
      )..layout();
      final badgeW = tp3.width + 10;
      final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2;
      final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH), const Radius.circular(6));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFF2EC4A9).withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFF2EC4A9).withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  void _drawPerson(Canvas canvas, double cx, double cy) {
    final alpha = isComplete ? 0.55 : 0.35;
    final color = isComplete
        ? Color.fromRGBO(212, 175, 55, alpha)
        : Color.fromRGBO(46, 196, 169, alpha);

    // Glow
    canvas.drawCircle(Offset(cx, cy), 16, Paint()
      ..color = color.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

    // Head
    canvas.drawCircle(Offset(cx, cy - 10), 4.5, Paint()..color = color);
    // Body
    canvas.drawLine(Offset(cx, cy - 6), Offset(cx, cy + 8), Paint()..color = color..strokeWidth = 2.5..strokeCap = StrokeCap.round);
    // Arms out (receiving protection)
    canvas.drawLine(Offset(cx, cy - 2), Offset(cx - 10, cy + 2), Paint()..color = color..strokeWidth = 2.0..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(cx, cy - 2), Offset(cx + 10, cy + 2), Paint()..color = color..strokeWidth = 2.0..strokeCap = StrokeCap.round);
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
      canvas.drawCircle(Offset(wx, wy), panelSize + 10, Paint()
        ..color = color.withValues(alpha: glowA)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

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
      canvas.drawPath(hexPath, Paint()
        ..color = color.withValues(alpha: fillA));

      // Border
      final borderA = wardProgress * (isComplete ? 0.65 : 0.45);
      canvas.drawPath(hexPath, Paint()
        ..color = color.withValues(alpha: borderA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isComplete ? 2.0 : 1.5
        ..strokeJoin = StrokeJoin.round);

      // Inner bright dot
      canvas.drawCircle(Offset(wx, wy), 2.5 * wardProgress, Paint()
        ..color = color.withValues(alpha: wardProgress * 0.60));
      canvas.drawCircle(Offset(wx, wy), 1.2 * wardProgress, Paint()
        ..color = Colors.white.withValues(alpha: wardProgress * 0.45));

      // Direction label (small Arabic text) on completion
      if (isComplete && wardProgress > 0.8) {
        final tp = TextPainter(
          text: TextSpan(text: _wardLabels[i], style: _illusTag(11, color.withValues(alpha: 0.55))),
          textDirection: TextDirection.rtl,
        )..layout();
        tp.paint(canvas, Offset(wx - tp.width / 2, wy + panelSize + 6));
      }
    }
  }

  void _drawConnections(Canvas canvas, double cx, double cy, double w) {
    final wardR = w * 0.30;

    for (int i = 0; i < 6; i++) {
      final threshold = (i + 1) / 6.0;
      if (progress < threshold - 1.0 / 6.0 + 0.05) continue;

      final connProgress = ((progress - (i / 6.0) - 0.05) * 6.0).clamp(0.0, 1.0);
      final angle = i * math.pi / 3 - math.pi / 2;
      final wx = cx + math.cos(angle) * wardR * connProgress;
      final wy = cy + math.sin(angle) * wardR * 0.55 * connProgress;
      final color = _wardColors[i];

      final lineAlpha = connProgress * (isComplete ? 0.30 : 0.18);
      canvas.drawLine(
        Offset(cx, cy), Offset(wx, wy),
        Paint()
          ..shader = LinearGradient(colors: [
            Colors.white.withValues(alpha: lineAlpha * 0.5),
            color.withValues(alpha: lineAlpha),
          ]).createShader(Rect.fromPoints(Offset(cx, cy), Offset(wx, wy)))
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );

      // Traveling dot along the connection line
      if (connProgress > 0.3 && connProgress < 1.0) {
        final dotT = ((glowPhase * 2 + i * 0.15) % 1.0);
        final dx = cx + (wx - cx) * dotT;
        final dy = cy + (wy - cy) * dotT;
        canvas.drawCircle(Offset(dx, dy), 1.8, Paint()
          ..color = color.withValues(alpha: 0.50));
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

        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: 0.15 * pulse)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(_SixWardsPainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.particlePhase != particlePhase ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
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

  final List<_Particle> _particles =
      List.generate(16, (i) => _Particle(seed: i + 600));

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1900))
      ..repeat(reverse: true);
    _pCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _driftCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat();
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
      for (final p in _particles) { p.reset(); }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose();
    _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose();
    _driftCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl, _growCtrl, _starCtrl, _pCtrl,
        _punchCtrl, _shockCtrl, _driftCtrl,
      ]),
      builder: (_, __) => SizedBox(
        height: 260,
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
    Color(0xFF6B21A8), // self — dark purple
    Color(0xFF991B1B), // shaytan — dark red
    Color(0xFF4A4A4A), // shirk — grey
    Color(0xFF1E3A5F), // harming others — dark blue
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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO((15 + purify * 15).round(), (10 + purify * 20).round(), (20 + purify * 25).round(), 1.0),
            Color.fromRGBO((18 + purify * 20).round(), (14 + purify * 25).round(), (28 + purify * 30).round(), 1.0),
            Color.fromRGBO((22 + purify * 25).round(), (18 + purify * 30).round(), (35 + purify * 35).round(), 1.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars — more visible as evils are repelled
    const starPos = [
      (0.10, 0.07), (0.23, 0.16), (0.37, 0.05), (0.54, 0.11),
      (0.68, 0.07), (0.82, 0.15), (0.92, 0.09), (0.44, 0.21),
      (0.61, 0.25), (0.29, 0.23), (0.76, 0.20),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      final starA = (0.06 + progress * 0.40 + 0.40 * tw * progress);
      sp.color = Colors.white.withValues(alpha: starA.clamp(0.0, 0.75));
      canvas.drawCircle(
          Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.8 + tw * 1.0, sp);
    }

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -cy);

    // 3. Four shadow entities being pushed back
    _drawShadows(canvas, cx, cy, w, h);

    // 4. Central divine light (grows as shadows retreat)
    _drawCentralLight(canvas, cx, cy, w);

    canvas.restore();

    // 5. Shockwave on tap
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.42;
      final ringA = (1.0 - shockPhase) * 0.40;
      final r = maxR * shockPhase;
      canvas.drawCircle(Offset(cx, cy), r, Paint()
        ..color = Color.fromRGBO(255, 255, 255, ringA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - shockPhase));
      canvas.drawCircle(Offset(cx, cy), r * 0.75, Paint()
        ..color = Color.fromRGBO(212, 175, 55, ringA * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * (1.0 - shockPhase));
    }

    // 6. Particles — light sparks pushing outward
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final angle = p.x * math.pi * 2;
        final dist = 20 + t * w * 0.30;
        final px = cx + math.cos(angle) * dist;
        final py = cy + math.sin(angle) * dist * 0.6 - t * 10;
        final a = (1.0 - t) * 0.80;
        final pSize = p.size * (1.0 - t * 0.3);

        canvas.drawCircle(Offset(px, py), pSize + 2, Paint()
          ..color = const Color(0xFFFFD97D).withValues(alpha: a * 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(Offset(px, py), pSize, Paint()
          ..color = const Color(0xFFFFD97D).withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35, Paint()
          ..color = Colors.white.withValues(alpha: a * 0.65));
      }
    }

    // 7. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'أعاذك الله' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(text: label, style: _illusArabic(12, isComplete ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.82))),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 8. Points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(text: badgeLabel, style: const TextStyle(
          color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w800,
          letterSpacing: 0.5, shadows: [Shadow(color: Color(0xFFD4AF37), blurRadius: 6)])),
        textDirection: TextDirection.ltr,
      )..layout();
      final badgeW = tp3.width + 10;
      final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2;
      final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH), const Radius.circular(6));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  /// 4 shadow forms at the corners, pushed further back as progress grows
  void _drawShadows(Canvas canvas, double cx, double cy, double w, double h) {
    // Shadow positions: 4 corners approaching center
    // As progress grows, they retreat further out and fade
    final basePositions = [
      (cx - w * 0.32, cy - 40.0), // top-left — evil of self
      (cx + w * 0.32, cy - 35.0), // top-right — shaytan
      (cx - w * 0.30, cy + 35.0), // bottom-left — shirk
      (cx + w * 0.30, cy + 30.0), // bottom-right — harming others
    ];

    for (int i = 0; i < 4; i++) {
      final (baseX, baseY) = basePositions[i];

      // Shadow retreats: starts close to center, moves outward with progress
      final retreatFactor = progress * 0.6;
      final dirX = (baseX - cx).sign;
      final dirY = (baseY - cy).sign;
      final sx = baseX + dirX * retreatFactor * w * 0.15;
      final sy = baseY + dirY * retreatFactor * 30;

      // Fade out as pushed away
      final shadowAlpha = (1.0 - progress * 0.9).clamp(0.05, 0.55);
      final color = _shadowColors[i];

      // Subtle drift animation
      final drift = math.sin(driftPhase * math.pi * 2 + i * 1.5) * 4;

      // Shadow blob — amorphous dark shape
      final blobR = 18.0 * (1.0 - progress * 0.4);

      // Outer smoky haze
      canvas.drawCircle(
        Offset(sx + drift, sy + drift * 0.5), blobR + 14,
        Paint()
          ..color = color.withValues(alpha: shadowAlpha * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );

      // Inner dark mass
      canvas.drawCircle(
        Offset(sx + drift, sy + drift * 0.5), blobR,
        Paint()
          ..color = color.withValues(alpha: shadowAlpha * 0.40)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Core — darkest point
      canvas.drawCircle(
        Offset(sx + drift, sy + drift * 0.5), blobR * 0.4,
        Paint()
          ..color = color.withValues(alpha: shadowAlpha * 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Two glowing "eyes" for menacing feel (fade as retreating)
      if (shadowAlpha > 0.15) {
        final eyeA = (shadowAlpha - 0.15) * 1.2;
        final eyeSpacing = 4.0;
        final eyeY = sy + drift * 0.5 - 1;
        canvas.drawCircle(
          Offset(sx + drift - eyeSpacing, eyeY), 1.5,
          Paint()..color = Color.fromRGBO(255, 80, 80, eyeA.clamp(0.0, 0.50)));
        canvas.drawCircle(
          Offset(sx + drift + eyeSpacing, eyeY), 1.5,
          Paint()..color = Color.fromRGBO(255, 80, 80, eyeA.clamp(0.0, 0.50)));
      }

      // Repelling light beam from center toward shadow
      if (progress > 0.1) {
        final beamA = progress * 0.12;
        canvas.drawLine(
          Offset(cx, cy),
          Offset(sx + drift, sy + drift * 0.5),
          Paint()
            ..shader = LinearGradient(colors: [
              const Color(0xFFFFD97D).withValues(alpha: beamA),
              Colors.transparent,
            ]).createShader(Rect.fromPoints(
                Offset(cx, cy), Offset(sx + drift, sy + drift * 0.5)))
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  /// Central divine light that grows as shadows retreat
  void _drawCentralLight(Canvas canvas, double cx, double cy, double w) {
    final lightR = 10 + progress * 30;
    final alpha = progress * (isComplete ? 0.35 : 0.18) * pulse;

    // Outer warm glow
    canvas.drawCircle(Offset(cx, cy), lightR + 20, Paint()
      ..color = Color.fromRGBO(255, 217, 125, alpha * 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));

    // Mid glow
    canvas.drawCircle(Offset(cx, cy), lightR, Paint()
      ..shader = RadialGradient(colors: [
        Color.fromRGBO(255, 255, 255, alpha * 0.90),
        Color.fromRGBO(212, 175, 55, alpha * 0.60),
        Colors.transparent,
      ], stops: const [0.0, 0.5, 1.0])
      .createShader(Rect.fromCircle(center: Offset(cx, cy), radius: lightR)));

    // Bright core
    canvas.drawCircle(Offset(cx, cy), 5 * pulse, Paint()
      ..color = Colors.white.withValues(alpha: alpha * 1.2));

    // Light rays radiating outward on completion
    if (isComplete) {
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4 + driftPhase * math.pi * 0.08;
        final rayLen = lightR + 20 * pulse;
        final sx = cx + math.cos(angle) * 8;
        final sy = cy + math.sin(angle) * 8;
        final ex = cx + math.cos(angle) * rayLen;
        final ey = cy + math.sin(angle) * rayLen;
        canvas.drawLine(Offset(sx, sy), Offset(ex, ey), Paint()
          ..shader = LinearGradient(colors: [
            Color.fromRGBO(255, 217, 125, 0.25 * pulse),
            Colors.transparent,
          ]).createShader(Rect.fromPoints(Offset(sx, sy), Offset(ex, ey)))
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(_RepellingLightPainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.particlePhase != particlePhase ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
      o.driftPhase != driftPhase;
}

// =============================================================================
// 💜 Cradled Heart (القلب المطمئن) — Entrust all matters to Allah
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

  final List<_Particle> _particles =
      List.generate(16, (i) => _Particle(seed: i + 700));

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1900))
      ..repeat(reverse: true);
    _pCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3600))
      ..repeat(reverse: true);
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
      for (final p in _particles) { p.reset(); }
      _pCtrl.forward(from: 0);
      _punchCtrl.forward(from: 0);
      _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose();
    _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl, _growCtrl, _starCtrl, _pCtrl,
        _punchCtrl, _shockCtrl, _floatCtrl,
      ]),
      builder: (_, __) => SizedBox(
        height: 260,
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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF120818), Color(0xFF1A1028), Color(0xFF201435)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars
    const starPos = [
      (0.10, 0.07), (0.22, 0.15), (0.37, 0.05), (0.53, 0.10),
      (0.67, 0.06), (0.82, 0.14), (0.92, 0.08), (0.44, 0.21),
      (0.61, 0.25), (0.28, 0.23), (0.76, 0.19),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      sp.color = Colors.white.withValues(alpha: 0.18 + 0.50 * tw);
      canvas.drawCircle(
          Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.9 + tw * 1.0, sp);
    }

    // Gentle float offset for the heart
    final floatY = math.sin(floatPhase * math.pi) * 4;

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, cy + floatY);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -(cy + floatY));

    // 3. Cupping hands of light (appear from sides)
    _drawHands(canvas, cx, cy + floatY, w);

    // 4. Heart at center
    _drawHeart(canvas, cx, cy + floatY);

    // 5. Mercy glow surrounding
    _drawMercyGlow(canvas, cx, cy + floatY, w);

    canvas.restore();

    // 6. Shockwave on tap
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.40;
      final ringA = (1.0 - shockPhase) * 0.35;
      final r = maxR * shockPhase;
      canvas.drawCircle(Offset(cx, cy + floatY), r, Paint()
        ..color = Color.fromRGBO(232, 121, 249, ringA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - shockPhase));
    }

    // 7. Particles — gentle upward sparkles
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final px = cx + p.x * w * 0.25 + math.sin(t * math.pi * 2) * 8;
        final py = cy - t * h * 0.40;
        final a = (1.0 - t) * 0.75;
        final pSize = p.size * (1.0 - t * 0.3);

        final pColor = Color.lerp(const Color(0xFFE879F9), const Color(0xFFD4AF37), t)!;

        canvas.drawCircle(Offset(px, py), pSize + 2, Paint()
          ..color = pColor.withValues(alpha: a * 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(Offset(px, py), pSize, Paint()..color = pColor.withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35, Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      }
    }

    // 8. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'توكلت على الله' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(text: label, style: _illusArabic(12, isComplete ? const Color(0xFFE879F9) : Colors.white.withValues(alpha: 0.82))),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 9. Points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(text: badgeLabel, style: const TextStyle(
          color: Color(0xFFE879F9), fontSize: 10, fontWeight: FontWeight.w800,
          letterSpacing: 0.5, shadows: [Shadow(color: Color(0xFFE879F9), blurRadius: 6)])),
        textDirection: TextDirection.ltr,
      )..layout();
      final badgeW = tp3.width + 10;
      final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2;
      final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH), const Radius.circular(6));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFE879F9).withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFE879F9).withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  /// Two cupping hands of light that close around the heart
  /// Two crescents of light that cup around the heart — abstract divine mercy
  void _drawHands(Canvas canvas, double cx, double cy, double w) {
    if (progress < 0.05) return;

    final alpha = progress * (isComplete ? 0.55 : 0.35);
    final color = isComplete
        ? const Color(0xFFD4AF37)
        : const Color(0xFFE879F9);

    // Crescents close inward with progress
    final openness = (1.0 - progress) * 28;
    final arcR = 38.0 + openness * 0.3;

    // ── Left crescent ──
    final lcx = cx - 22 - openness;

    // Outer glow arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(lcx, cy), radius: arcR + 8),
      math.pi * 0.65, math.pi * 0.7, false,
      Paint()
        ..color = color.withValues(alpha: alpha * 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Main arc (3 layered strokes for depth)
    for (int layer = 0; layer < 3; layer++) {
      final lr = arcR - layer * 5;
      final la = alpha * (0.55 - layer * 0.15);
      final lw = (2.8 - layer * 0.7) * (isComplete ? 1.1 : 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(lcx, cy), radius: lr),
        math.pi * 0.65, math.pi * 0.7, false,
        Paint()
          ..color = color.withValues(alpha: la)
          ..style = PaintingStyle.stroke
          ..strokeWidth = lw
          ..strokeCap = StrokeCap.round,
      );
    }

    // Tip dots at arc endpoints (top and bottom)
    for (final endAngle in [math.pi * 0.65, math.pi * 1.35]) {
      final tx = lcx + math.cos(endAngle) * arcR;
      final ty = cy + math.sin(endAngle) * arcR;
      canvas.drawCircle(Offset(tx, ty), 2.5, Paint()
        ..color = color.withValues(alpha: alpha * 0.50));
      canvas.drawCircle(Offset(tx, ty), 1.2, Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.40));
    }

    // ── Right crescent (mirrored) ──
    final rcx = cx + 22 + openness;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(rcx, cy), radius: arcR + 8),
      -math.pi * 0.35, -math.pi * 0.7, false,
      Paint()
        ..color = color.withValues(alpha: alpha * 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    for (int layer = 0; layer < 3; layer++) {
      final lr = arcR - layer * 5;
      final la = alpha * (0.55 - layer * 0.15);
      final lw = (2.8 - layer * 0.7) * (isComplete ? 1.1 : 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(rcx, cy), radius: lr),
        -math.pi * 0.35, -math.pi * 0.7, false,
        Paint()
          ..color = color.withValues(alpha: la)
          ..style = PaintingStyle.stroke
          ..strokeWidth = lw
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final endAngle in [-math.pi * 0.35, -math.pi * 1.05]) {
      final tx = rcx + math.cos(endAngle) * arcR;
      final ty = cy + math.sin(endAngle) * arcR;
      canvas.drawCircle(Offset(tx, ty), 2.5, Paint()
        ..color = color.withValues(alpha: alpha * 0.50));
      canvas.drawCircle(Offset(tx, ty), 1.2, Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.40));
    }

    // ── Connecting glow between crescents at bottom (cupping effect) ──
    if (progress > 0.4) {
      final connAlpha = ((progress - 0.4) / 0.6).clamp(0.0, 1.0) * alpha * 0.35;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, cy + 8), width: (lcx - rcx).abs() + arcR, height: 30),
        0, math.pi, false,
        Paint()
          ..color = color.withValues(alpha: connAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Heart shape at center that grows with progress
  void _drawHeart(Canvas canvas, double cx, double cy) {
    final heartScale = (0.4 + progress * 0.6) * (isComplete ? pulse : 1.0);
    final heartAlpha = (0.2 + progress * 0.6).clamp(0.0, 0.80);

    // Heart glow
    canvas.drawCircle(Offset(cx, cy), 22 * heartScale, Paint()
      ..color = isComplete
          ? Color.fromRGBO(212, 175, 55, heartAlpha * 0.15)
          : Color.fromRGBO(232, 121, 249, heartAlpha * 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));

    // Heart shape path
    canvas.save();
    canvas.translate(cx, cy - 2 * heartScale);

    final s = 12.0 * heartScale;
    final heartPath = Path()
      ..moveTo(0, s * 0.9)
      ..cubicTo(-s * 0.7, s * 0.4, -s * 1.3, -s * 0.2, -s * 0.7, -s * 0.7)
      ..cubicTo(-s * 0.3, -s * 1.0, 0, -s * 0.7, 0, -s * 0.3)
      ..cubicTo(0, -s * 0.7, s * 0.3, -s * 1.0, s * 0.7, -s * 0.7)
      ..cubicTo(s * 1.3, -s * 0.2, s * 0.7, s * 0.4, 0, s * 0.9)
      ..close();

    // Filled heart with gradient
    canvas.drawPath(heartPath, Paint()
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
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: s * 1.2)));

    // Heart outline (subtle)
    canvas.drawPath(heartPath, Paint()
      ..color = Colors.white.withValues(alpha: heartAlpha * 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);

    // Highlight on top-left of heart
    canvas.drawCircle(Offset(-s * 0.4, -s * 0.4), s * 0.2, Paint()
      ..color = Colors.white.withValues(alpha: heartAlpha * 0.35));

    canvas.restore();
  }

  /// Soft mercy aura around the whole scene
  void _drawMercyGlow(Canvas canvas, double cx, double cy, double w) {
    if (progress < 0.2) return;

    final auraProgress = ((progress - 0.2) / 0.8).clamp(0.0, 1.0);
    final auraR = 45 + auraProgress * 25;
    final auraAlpha = auraProgress * (isComplete ? 0.12 : 0.06) * pulse;

    // Soft circular aura
    canvas.drawCircle(Offset(cx, cy), auraR, Paint()
      ..shader = RadialGradient(colors: [
        isComplete
            ? Color.fromRGBO(212, 175, 55, auraAlpha * 1.5)
            : Color.fromRGBO(232, 121, 249, auraAlpha * 1.2),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: auraR)));

    // Orbiting mercy dots
    if (progress > 0.5) {
      final dotCount = ((progress - 0.5) / 0.5 * 5).ceil().clamp(0, 5);
      for (int i = 0; i < dotCount; i++) {
        final angle = floatPhase * math.pi * 2 + i * (math.pi * 2 / 5);
        final orbitR = auraR * 0.75;
        final dx = cx + math.cos(angle) * orbitR;
        final dy = cy + math.sin(angle) * orbitR * 0.5;
        final dotAlpha = isComplete ? 0.40 : 0.25;

        canvas.drawCircle(Offset(dx, dy), 3.5, Paint()
          ..color = const Color(0xFFE879F9).withValues(alpha: dotAlpha * 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawCircle(Offset(dx, dy), 2.0, Paint()
          ..color = const Color(0xFFE879F9).withValues(alpha: dotAlpha));
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
        canvas.drawLine(Offset(sx, sy), Offset(ex, ey), Paint()
          ..shader = LinearGradient(colors: [
            Color.fromRGBO(232, 121, 249, 0.20 * pulse),
            Colors.transparent,
          ]).createShader(Rect.fromPoints(Offset(sx, sy), Offset(ex, ey)))
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(_CradledHeartPainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.particlePhase != particlePhase ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
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

  final List<_Particle> _particles =
      List.generate(18, (i) => _Particle(seed: i + 800));

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))..repeat(reverse: true);
    _pCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _flowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
  }

  @override
  void didUpdateWidget(_OverflowingVessel old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) { _growCtrl.animateTo(widget.progress); _prevProgress = widget.progress; }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) { p.reset(); }
      _pCtrl.forward(from: 0); _punchCtrl.forward(from: 0); _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose();
    _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose(); _flowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _flowCtrl]),
      builder: (_, __) => SizedBox(
        height: 260,
        child: CustomPaint(
          painter: _OverflowingVesselPainter(
            progress: _grow.value, pulse: _pulse.value, starPhase: _starCtrl.value,
            particlePhase: _pAnim.value, particles: _particles, isComplete: widget.isComplete,
            pointsToday: widget.pointsToday, punchScale: _punch.value,
            shockPhase: _shock.value, flowPhase: _flowCtrl.value,
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
    Color(0xFF34D399), // emerald
    Color(0xFF38BDF8), // sky
    Color(0xFFFBBF24), // amber
    Color(0xFFA78BFA), // violet
    Color(0xFFF472B6), // pink
    Color(0xFF2DD4BF), // teal
    Color(0xFFFF9F43), // orange
  ];

  const _OverflowingVesselPainter({
    required this.progress, required this.pulse, required this.starPhase,
    required this.particlePhase, required this.particles, required this.isComplete,
    this.pointsToday = 0, this.punchScale = 1.0, this.shockPhase = 1.0, this.flowPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final vesselCy = h * 0.52;

    // 1. Background — deep earthy green-gold (gratitude/growth)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E1608), Color(0xFF162210), Color(0xFF1C2E14)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars
    const starPos = [
      (0.10, 0.06), (0.23, 0.14), (0.38, 0.04), (0.54, 0.10),
      (0.68, 0.06), (0.83, 0.13), (0.92, 0.08), (0.45, 0.20),
      (0.62, 0.23), (0.28, 0.21), (0.76, 0.18),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      sp.color = Colors.white.withValues(alpha: 0.18 + 0.48 * tw);
      canvas.drawCircle(Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.9 + tw * 1.0, sp);
    }

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, vesselCy);
    canvas.scale(punchScale, punchScale);
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
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.40;
      final ringA = (1.0 - shockPhase) * 0.35;
      canvas.drawCircle(Offset(cx, vesselCy), maxR * shockPhase, Paint()
        ..color = Color.fromRGBO(212, 175, 55, ringA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - shockPhase));
    }

    // 8. Tap particles
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final angle = p.x * math.pi * 2;
        final dist = 15 + t * w * 0.25;
        final px = cx + math.cos(angle) * dist;
        final py = vesselCy - 10 - t * h * 0.30;
        final a = (1.0 - t) * 0.75;
        final pSize = p.size * (1.0 - t * 0.3);
        final ci = ((p.x.abs() * 8).floor()).clamp(0, 7);
        final pColor = _blessingColors[ci];

        canvas.drawCircle(Offset(px, py), pSize + 2, Paint()..color = pColor.withValues(alpha: a * 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(Offset(px, py), pSize, Paint()..color = pColor.withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35, Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      }
    }

    // 9. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'الحمد لله' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(text: label, style: _illusArabic(12, isComplete ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.82))),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 10. Points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(text: badgeLabel, style: const TextStyle(
          color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w800,
          letterSpacing: 0.5, shadows: [Shadow(color: Color(0xFFD4AF37), blurRadius: 6)])),
        textDirection: TextDirection.ltr,
      )..layout();
      final badgeW = tp3.width + 10; final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2; final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH), const Radius.circular(6));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  /// Ornate vessel / bowl shape
  void _drawVessel(Canvas canvas, double cx, double cy, double w) {
    final vesselW = 52.0;
    final vesselH = 38.0;
    final rimY = cy - vesselH * 0.35;
    final baseY = cy + vesselH * 0.65;

    final vesselColor = isComplete
        ? const Color(0xFFD4AF37).withValues(alpha: 0.55)
        : const Color(0xFF8B7355).withValues(alpha: 0.45);
    final rimColor = isComplete
        ? const Color(0xFFFFD97D).withValues(alpha: 0.60)
        : const Color(0xFFB8976A).withValues(alpha: 0.40);

    // Vessel body — curved trapezoid
    final vesselPath = Path()
      ..moveTo(cx - vesselW * 0.5, rimY)
      ..quadraticBezierTo(cx - vesselW * 0.55, cy + vesselH * 0.2, cx - vesselW * 0.25, baseY)
      ..lineTo(cx + vesselW * 0.25, baseY)
      ..quadraticBezierTo(cx + vesselW * 0.55, cy + vesselH * 0.2, cx + vesselW * 0.5, rimY)
      ..close();

    canvas.drawPath(vesselPath, Paint()..color = vesselColor);
    canvas.drawPath(vesselPath, Paint()
      ..color = rimColor..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Rim — wider ellipse at top
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, rimY), width: vesselW + 6, height: 8),
      Paint()..color = rimColor);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, rimY), width: vesselW + 6, height: 8),
      Paint()..color = rimColor.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // Base pedestal
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY + 2), width: vesselW * 0.45, height: 5),
      Paint()..color = vesselColor);

    // Decorative band on vessel
    final bandY = cy + 4;
    canvas.drawLine(
      Offset(cx - vesselW * 0.40, bandY),
      Offset(cx + vesselW * 0.40, bandY),
      Paint()..color = rimColor.withValues(alpha: 0.30)..strokeWidth = 0.8);
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
      final wy = fillTop + math.sin((x / fillHalfW) * math.pi * 2 + flowPhase * math.pi * 2) * waveAmp;
      wavePath.lineTo(cx + x, wy);
    }
    wavePath
      ..lineTo(cx + fillHalfW, baseY)
      ..lineTo(cx - fillHalfW, baseY)
      ..close();

    // Golden liquid fill
    final fillAlpha = (0.20 + progress * 0.40).clamp(0.0, 0.60);
    canvas.drawPath(wavePath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromRGBO(255, 217, 125, fillAlpha * 0.8),
          Color.fromRGBO(212, 175, 55, fillAlpha),
          Color.fromRGBO(180, 140, 30, fillAlpha * 0.7),
        ],
      ).createShader(Rect.fromLTWH(cx - fillHalfW, fillTop, fillHalfW * 2, fillHeight)));

    // Surface shimmer
    canvas.drawLine(
      Offset(cx - fillHalfW * 0.6, fillTop + waveAmp * 0.5),
      Offset(cx + fillHalfW * 0.3, fillTop - waveAmp * 0.3),
      Paint()..color = Colors.white.withValues(alpha: fillAlpha * 0.30)..strokeWidth = 0.8);

    // Small blessing orbs floating in the liquid
    final orbCount = (progress * 5).ceil().clamp(0, 5);
    for (int i = 0; i < orbCount; i++) {
      final orbPhase = (flowPhase + i * 0.2) % 1.0;
      final ox = cx + math.sin(orbPhase * math.pi * 2 + i * 1.3) * fillHalfW * 0.5;
      final oy = fillTop + (baseY - fillTop) * (0.2 + i * 0.15);
      final oc = _blessingColors[i % _blessingColors.length];

      canvas.drawCircle(Offset(ox, oy), 3.0, Paint()..color = oc.withValues(alpha: 0.30));
      canvas.drawCircle(Offset(ox, oy), 1.5, Paint()..color = oc.withValues(alpha: 0.55));
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
      canvas.drawCircle(Offset(cx + spreadX, riseY), orbR + 4, Paint()
        ..color = oc.withValues(alpha: orbAlpha * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      // Orb
      canvas.drawCircle(Offset(cx + spreadX, riseY), orbR, Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: orbAlpha * 0.6),
          oc.withValues(alpha: orbAlpha),
        ]).createShader(Rect.fromCircle(center: Offset(cx + spreadX, riseY), radius: orbR)));
    }
  }

  /// Soft descending light from above into the vessel
  void _drawDescendingLight(Canvas canvas, double cx, double cy, double w, double h) {
    if (progress < 0.1) return;

    final lightAlpha = progress * (isComplete ? 0.18 : 0.08) * pulse;
    final vesselH = 38.0;
    final rimY = cy - vesselH * 0.35;

    // Cone of light narrowing toward the vessel
    final beamPath = Path()
      ..moveTo(cx - 35, h * 0.05)
      ..lineTo(cx + 35, h * 0.05)
      ..lineTo(cx + 15, rimY)
      ..lineTo(cx - 15, rimY)
      ..close();

    canvas.drawPath(beamPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromRGBO(255, 248, 220, lightAlpha * 0.6),
          Color.fromRGBO(212, 175, 55, lightAlpha),
          Color.fromRGBO(212, 175, 55, lightAlpha * 1.5),
        ],
      ).createShader(Rect.fromLTWH(cx - 35, h * 0.05, 70, rimY - h * 0.05)));

    // Descending blessing dots within the beam
    if (progress > 0.3) {
      final dotCount = ((progress - 0.3) / 0.7 * 4).ceil().clamp(0, 4);
      for (int i = 0; i < dotCount; i++) {
        final t = (flowPhase + i * 0.25) % 1.0;
        final dy = h * 0.08 + t * (rimY - h * 0.08);
        final dx = cx + math.sin(t * math.pi * 4 + i) * (15 * (1 - t) + 5);
        final dotA = (0.5 - (t - 0.5).abs()) * 0.80;
        final dc = _blessingColors[(i * 2) % _blessingColors.length];

        canvas.drawCircle(Offset(dx, dy), 2.5, Paint()..color = dc.withValues(alpha: dotA));
        canvas.drawCircle(Offset(dx, dy), 1.2, Paint()..color = Colors.white.withValues(alpha: dotA * 0.5));
      }
    }
  }

  @override
  bool shouldRepaint(_OverflowingVesselPainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.particlePhase != particlePhase ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
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
    required this.progress, required this.isComplete,
    required this.tapCount, this.pointsToday = 0,
  });

  @override
  State<_RisingDawn> createState() => _RisingDawnState();
}

class _RisingDawnState extends State<_RisingDawn> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _rayCtrl;
  late Animation<double> _pulse, _grow, _pAnim, _punch, _shock;
  double _prevProgress = 0.0;
  int _prevTap = 0;
  final List<_Particle> _particles = List.generate(16, (i) => _Particle(seed: i + 900));

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress; _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))..repeat(reverse: true);
    _pCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _rayCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))..repeat();
  }

  @override
  void didUpdateWidget(_RisingDawn old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) { _growCtrl.animateTo(widget.progress); _prevProgress = widget.progress; }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) { p.reset(); }
      _pCtrl.forward(from: 0); _punchCtrl.forward(from: 0); _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose();
    _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose(); _rayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _rayCtrl]),
      builder: (_, __) => SizedBox(
        height: 260,
        child: CustomPaint(
          painter: _RisingDawnPainter(
            progress: _grow.value, pulse: _pulse.value, starPhase: _starCtrl.value,
            particlePhase: _pAnim.value, particles: _particles, isComplete: widget.isComplete,
            pointsToday: widget.pointsToday, punchScale: _punch.value,
            shockPhase: _shock.value, rayPhase: _rayCtrl.value,
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
    required this.progress, required this.pulse, required this.starPhase,
    required this.particlePhase, required this.particles, required this.isComplete,
    this.pointsToday = 0, this.punchScale = 1.0, this.shockPhase = 1.0, this.rayPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final horizonY = h * 0.62;

    // 1. Sky gradient — transitions from night to dawn with progress
    final dawn = progress;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO((10 + dawn * 15).round(), (10 + dawn * 12).round(), (26 + dawn * 20).round(), 1.0),
            Color.fromRGBO((14 + dawn * 50).round(), (14 + dawn * 30).round(), (30 + dawn * 25).round(), 1.0),
            Color.fromRGBO((20 + dawn * 120).round(), (20 + dawn * 65).round(), (35 + dawn * 35).round(), 1.0),
            Color.fromRGBO((25 + dawn * 180).round().clamp(0, 255), (25 + dawn * 100).round().clamp(0, 255), (38 + dawn * 50).round().clamp(0, 255), 1.0),
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars — fade out as dawn brightens
    const starPos = [
      (0.08, 0.06), (0.20, 0.14), (0.35, 0.04), (0.52, 0.09),
      (0.68, 0.05), (0.83, 0.13), (0.92, 0.07), (0.44, 0.18),
      (0.62, 0.22), (0.27, 0.20), (0.76, 0.17), (0.15, 0.26),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      final starA = ((1.0 - progress * 0.85) * (0.25 + 0.55 * tw)).clamp(0.0, 0.75);
      if (starA < 0.02) continue;
      sp.color = Colors.white.withValues(alpha: starA);
      canvas.drawCircle(Offset(starPos[i].$1 * w, starPos[i].$2 * h), 1.0 + tw * 1.0, sp);
    }

    // 3. Horizon ground — dark silhouette landscape
    final groundPath = Path()
      ..moveTo(0, horizonY)
      ..quadraticBezierTo(w * 0.15, horizonY - 6, w * 0.25, horizonY)
      ..quadraticBezierTo(w * 0.35, horizonY + 4, w * 0.45, horizonY - 2)
      ..quadraticBezierTo(w * 0.55, horizonY - 8, w * 0.65, horizonY)
      ..quadraticBezierTo(w * 0.75, horizonY + 5, w * 0.85, horizonY - 3)
      ..quadraticBezierTo(w * 0.95, horizonY + 2, w, horizonY)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(groundPath, Paint()
      ..color = Color.fromRGBO((8 + dawn * 20).round(), (12 + dawn * 25).round(), (6 + dawn * 15).round(), 1.0));

    // Small mosque silhouette on horizon
    _drawMosqueSilhouette(canvas, cx, horizonY, dawn);

    // Apply punch scale around sun position
    canvas.save();
    final sunCy = horizonY - progress * horizonY * 0.45;
    canvas.translate(cx, sunCy);
    canvas.scale(punchScale, punchScale);
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
        Rect.fromCenter(center: Offset(cx, horizonY), width: w * 0.9, height: 40 * progress),
        Paint()
          ..color = Color.fromRGBO(255, 180, 50, glowA)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
      );
    }

    // 7. Shockwave
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.40;
      final ringA = (1.0 - shockPhase) * 0.35;
      canvas.drawCircle(Offset(cx, sunCy), maxR * shockPhase, Paint()
        ..color = Color.fromRGBO(255, 200, 60, ringA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - shockPhase));
    }

    // 8. Particles — golden sparks rising
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final px = cx + p.x * w * 0.30 + math.sin(t * math.pi * 2) * 6;
        final py = horizonY - t * h * 0.50;
        final a = (1.0 - t) * 0.75;
        final pSize = p.size * (1.0 - t * 0.3);
        final pColor = Color.lerp(const Color(0xFFFF9F43), const Color(0xFFFFD97D), t)!;

        canvas.drawCircle(Offset(px, py), pSize + 2, Paint()..color = pColor.withValues(alpha: a * 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(Offset(px, py), pSize, Paint()..color = pColor.withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35, Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      }
    }

    // 9. Label
    final pct = (progress * 100).round();
    final label = isComplete ? 'على فطرة الإسلام' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(text: label, style: _illusArabic(12, isComplete ? const Color(0xFFFFD97D) : Colors.white.withValues(alpha: 0.82))),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 10. Points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(text: badgeLabel, style: const TextStyle(
          color: Color(0xFFFFD97D), fontSize: 10, fontWeight: FontWeight.w800,
          letterSpacing: 0.5, shadows: [Shadow(color: Color(0xFFFFD97D), blurRadius: 6)])),
        textDirection: TextDirection.ltr,
      )..layout();
      final badgeW = tp3.width + 10; final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2; final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH), const Radius.circular(6));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFFFD97D).withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFFFD97D).withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  /// Sun disc rising from the horizon
  void _drawSun(Canvas canvas, double cx, double sunCy, double horizonY, double w) {
    final sunR = 18 + progress * 10;
    final sunAlpha = (0.15 + progress * 0.65).clamp(0.0, 0.80);

    // Outer corona
    canvas.drawCircle(Offset(cx, sunCy), sunR + 18, Paint()
      ..color = Color.fromRGBO(255, 200, 60, sunAlpha * 0.10 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));

    // Mid corona
    canvas.drawCircle(Offset(cx, sunCy), sunR + 8, Paint()
      ..color = Color.fromRGBO(255, 180, 50, sunAlpha * 0.18 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));

    // Sun disc with gradient
    canvas.drawCircle(Offset(cx, sunCy), sunR * (isComplete ? pulse : 1.0), Paint()
      ..shader = RadialGradient(colors: [
        Color.fromRGBO(255, 255, 230, sunAlpha),
        Color.fromRGBO(255, 210, 80, sunAlpha),
        Color.fromRGBO(255, 160, 40, sunAlpha * 0.7),
      ], stops: const [0.0, 0.5, 1.0])
      .createShader(Rect.fromCircle(center: Offset(cx, sunCy), radius: sunR)));

    // Bright core
    canvas.drawCircle(Offset(cx, sunCy), sunR * 0.35, Paint()
      ..color = Colors.white.withValues(alpha: sunAlpha * 0.70));
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
      final rayLen = baseLen * (i.isEven ? 1.0 : 0.6) * (isComplete ? pulse : 1.0);
      final rayAlpha = rayProgress * (isComplete ? 0.28 : 0.14);

      final sx = cx + math.cos(angle) * 22;
      final sy = sunCy + math.sin(angle) * 22;
      final ex = cx + math.cos(angle) * (22 + rayLen);
      final ey = sunCy + math.sin(angle) * (22 + rayLen);

      canvas.drawLine(Offset(sx, sy), Offset(ex, ey), Paint()
        ..shader = LinearGradient(colors: [
          Color.fromRGBO(255, 220, 100, rayAlpha),
          Colors.transparent,
        ]).createShader(Rect.fromPoints(Offset(sx, sy), Offset(ex, ey)))
        ..strokeWidth = i.isEven ? 2.0 : 1.2
        ..strokeCap = StrokeCap.round);
    }
  }

  /// Small mosque silhouette on the horizon
  void _drawMosqueSilhouette(Canvas canvas, double cx, double horizonY, double dawn) {
    final silColor = Color.fromRGBO(
      (6 + dawn * 15).round(), (10 + dawn * 20).round(), (4 + dawn * 10).round(), 0.85);

    // Main dome
    final domeW = 24.0;
    final domeH = 16.0;
    final domeX = cx - 5;
    final domeBase = horizonY - 1;

    final domePath = Path()
      ..moveTo(domeX - domeW / 2, domeBase)
      ..quadraticBezierTo(domeX - domeW / 2, domeBase - domeH, domeX, domeBase - domeH - 4)
      ..quadraticBezierTo(domeX + domeW / 2, domeBase - domeH, domeX + domeW / 2, domeBase)
      ..close();
    canvas.drawPath(domePath, Paint()..color = silColor);

    // Left minaret
    final mLeftX = domeX - domeW / 2 - 5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(mLeftX - 2, domeBase - domeH - 8, 4, domeH + 8), const Radius.circular(1)),
      Paint()..color = silColor);
    // Minaret cap
    canvas.drawCircle(Offset(mLeftX, domeBase - domeH - 9), 2.5, Paint()..color = silColor);

    // Right minaret
    final mRightX = domeX + domeW / 2 + 5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(mRightX - 2, domeBase - domeH - 6, 4, domeH + 6), const Radius.circular(1)),
      Paint()..color = silColor);
    canvas.drawCircle(Offset(mRightX, domeBase - domeH - 7), 2.5, Paint()..color = silColor);

    // Crescent on top of dome
    final crescentY = domeBase - domeH - 6;
    canvas.drawCircle(Offset(domeX, crescentY), 2.8, Paint()
      ..color = isComplete ? const Color(0xFFFFD97D).withValues(alpha: 0.60) : silColor);
    canvas.drawCircle(Offset(domeX + 1.2, crescentY - 0.5), 2.2, Paint()
      ..color = Color.fromRGBO(
        (6 + dawn * 15).round(), (10 + dawn * 20).round(), (4 + dawn * 10).round(), 0.90));
  }

  @override
  bool shouldRepaint(_RisingDawnPainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.particlePhase != particlePhase ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
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
    required this.progress, required this.isComplete,
    required this.tapCount, this.pointsToday = 0,
  });

  @override
  State<_PraiseRipples> createState() => _PraiseRipplesState();
}

class _PraiseRipplesState extends State<_PraiseRipples> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _rippleCtrl;
  late Animation<double> _pulse, _grow, _pAnim, _punch, _shock;
  double _prevProgress = 0.0;
  int _prevTap = 0;
  final List<_Particle> _particles = List.generate(16, (i) => _Particle(seed: i + 1000));

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress; _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))..repeat(reverse: true);
    _pCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
  }

  @override
  void didUpdateWidget(_PraiseRipples old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) { _growCtrl.animateTo(widget.progress); _prevProgress = widget.progress; }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) { p.reset(); }
      _pCtrl.forward(from: 0); _punchCtrl.forward(from: 0); _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose();
    _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose(); _rippleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _rippleCtrl]),
      builder: (_, __) => SizedBox(
        height: 260,
        child: CustomPaint(
          painter: _PraiseRipplesPainter(
            progress: _grow.value, pulse: _pulse.value, starPhase: _starCtrl.value,
            particlePhase: _pAnim.value, particles: _particles, isComplete: widget.isComplete,
            pointsToday: widget.pointsToday, punchScale: _punch.value,
            shockPhase: _shock.value, ripplePhase: _rippleCtrl.value,
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
    required this.progress, required this.pulse, required this.starPhase,
    required this.particlePhase, required this.particles, required this.isComplete,
    this.pointsToday = 0, this.punchScale = 1.0, this.shockPhase = 1.0, this.ripplePhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.42;

    // 1. Background — deep navy blue (serene praise)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF08101E), Color(0xFF0C1A30), Color(0xFF102440)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars
    const starPos = [
      (0.09, 0.07), (0.22, 0.15), (0.37, 0.05), (0.54, 0.11),
      (0.68, 0.06), (0.83, 0.14), (0.92, 0.08), (0.45, 0.21),
      (0.62, 0.25), (0.28, 0.23), (0.76, 0.19),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      sp.color = Colors.white.withValues(alpha: 0.20 + 0.50 * tw);
      canvas.drawCircle(Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.9 + tw * 1.0, sp);
    }

    // Apply punch
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -cy);

    // 3. Expanding praise ripple rings (continuous)
    _drawPraiseRipples(canvas, cx, cy, w);

    // 4. Central crescent and star
    _drawCrescentStar(canvas, cx, cy);

    canvas.restore();

    // 5. Shockwave
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.42;
      final ringA = (1.0 - shockPhase) * 0.35;
      canvas.drawCircle(Offset(cx, cy), maxR * shockPhase, Paint()
        ..color = Color.fromRGBO(212, 175, 55, ringA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - shockPhase));
    }

    // 6. Particles
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final angle = p.x * math.pi * 2;
        final dist = 18 + t * w * 0.28;
        final px = cx + math.cos(angle) * dist;
        final py = cy + math.sin(angle) * dist * 0.6 - t * 15;
        final a = (1.0 - t) * 0.75;
        final pSize = p.size * (1.0 - t * 0.3);
        final pColor = Color.lerp(const Color(0xFFD4AF37), const Color(0xFF38BDF8), (p.x.abs()))!;

        canvas.drawCircle(Offset(px, py), pSize + 2, Paint()..color = pColor.withValues(alpha: a * 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(Offset(px, py), pSize, Paint()..color = pColor.withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35, Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      }
    }

    // 7. Label
    final pct = (progress * 100).round();
    final label = isComplete ? 'الحمد لله' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(text: label, style: _illusArabic(12, isComplete ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.82))),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(text: badgeLabel, style: const TextStyle(
          color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w800,
          letterSpacing: 0.5, shadows: [Shadow(color: Color(0xFFD4AF37), blurRadius: 6)])),
        textDirection: TextDirection.ltr,
      )..layout();
      final badgeW = tp3.width + 10; final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2; final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH), const Radius.circular(6));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
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
      final alpha = ringFade * slotProgress * (isComplete ? 0.35 : 0.22);

      if (alpha < 0.02) continue;

      // Alternate gold and sky-blue rings
      final ringColor = i.isEven
          ? Color.fromRGBO(212, 175, 55, alpha)
          : Color.fromRGBO(56, 189, 248, alpha * 0.7);

      canvas.drawCircle(Offset(cx, cy), ringR, Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2.5 * ringFade).clamp(0.5, 2.5));

      // Dotted accents on each ring (4 dots evenly spaced)
      if (ringPhase > 0.2 && ringPhase < 0.8) {
        for (int d = 0; d < 4; d++) {
          final dotAngle = d * math.pi / 2 + i * 0.4;
          final dx = cx + math.cos(dotAngle) * ringR;
          final dy = cy + math.sin(dotAngle) * ringR;
          canvas.drawCircle(Offset(dx, dy), 1.8 * ringFade, Paint()
            ..color = ringColor.withValues(alpha: (alpha * 1.5).clamp(0.0, 0.50)));
        }
      }
    }
  }

  /// Central crescent and star — Islamic symbol of faith
  void _drawCrescentStar(Canvas canvas, double cx, double cy) {
    final scale = (0.5 + progress * 0.5) * (isComplete ? pulse : 1.0);
    final alpha = (0.25 + progress * 0.55).clamp(0.0, 0.80);

    final color = isComplete
        ? Color.fromRGBO(212, 175, 55, alpha)
        : Color.fromRGBO(255, 255, 255, alpha);

    // Central glow
    canvas.drawCircle(Offset(cx, cy), 28 * scale, Paint()
      ..color = (isComplete ? const Color(0xFFD4AF37) : const Color(0xFF38BDF8))
          .withValues(alpha: alpha * 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));

    // Crescent moon
    final moonR = 16.0 * scale;
    canvas.drawCircle(Offset(cx - 2, cy), moonR, Paint()..color = color);
    // Cutout to form crescent
    canvas.drawCircle(Offset(cx + moonR * 0.45, cy - moonR * 0.1), moonR * 0.82, Paint()
      ..color = const Color(0xFF0C1A30).withValues(alpha: alpha > 0.5 ? 0.92 : 0.85));

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
    canvas.drawCircle(Offset(starCx, starCy), starR + 3, Paint()
      ..color = color.withValues(alpha: alpha * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  @override
  bool shouldRepaint(_PraiseRipplesPainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.particlePhase != particlePhase ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
      o.ripplePhase != ripplePhase;
}

// =============================================================================
// ✨ Five Blessings (خمس بركات) — Ask Allah to bless your day
// Dua asks for: فتح (victory), نصر (help), نور (light), بركة (barakah), هدى (guidance)
// =============================================================================
class _FiveBlessings extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _FiveBlessings({
    required this.progress, required this.isComplete,
    required this.tapCount, this.pointsToday = 0,
  });

  @override
  State<_FiveBlessings> createState() => _FiveBlessingsState();
}

class _FiveBlessingsState extends State<_FiveBlessings> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _flowCtrl;
  late Animation<double> _pulse, _grow, _pAnim, _punch, _shock;
  double _prevProgress = 0.0;
  int _prevTap = 0;
  final List<_Particle> _particles = List.generate(18, (i) => _Particle(seed: i + 1200));

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress; _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _pCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _flowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat();
  }

  @override
  void didUpdateWidget(_FiveBlessings old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) { _growCtrl.animateTo(widget.progress); _prevProgress = widget.progress; }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) { p.reset(); }
      _pCtrl.forward(from: 0); _punchCtrl.forward(from: 0); _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose();
    _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose(); _flowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _flowCtrl]),
      builder: (_, __) => SizedBox(
        height: 260,
        child: CustomPaint(
          painter: _FiveBlessingsPainter(
            progress: _grow.value, pulse: _pulse.value, starPhase: _starCtrl.value,
            particlePhase: _pAnim.value, particles: _particles, isComplete: widget.isComplete,
            pointsToday: widget.pointsToday, punchScale: _punch.value,
            shockPhase: _shock.value, flowPhase: _flowCtrl.value,
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
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double flowPhase;

  const _FiveBlessingsPainter({
    required this.progress, required this.pulse, required this.starPhase,
    required this.particlePhase, required this.particles, required this.isComplete,
    this.pointsToday = 0, this.punchScale = 1.0, this.shockPhase = 1.0, this.flowPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 1. Background — deep celestial gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(12, 8, 24, 1.0),
            Color.fromRGBO(14, 12, 28, 1.0),
            Color.fromRGBO(10, 16, 24, 1.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars
    const starPos = [
      (0.08, 0.05), (0.20, 0.12), (0.35, 0.03), (0.52, 0.08),
      (0.67, 0.05), (0.80, 0.11), (0.93, 0.06), (0.42, 0.16),
      (0.15, 0.20), (0.72, 0.18), (0.88, 0.15),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      sp.color = Colors.white.withValues(alpha: 0.15 + 0.40 * tw);
      canvas.drawCircle(Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.8 + tw * 0.9, sp);
    }

    // Apply punch
    canvas.save();
    canvas.translate(cx, h * 0.50);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -h * 0.50);

    // The five blessings: فتح نصر نور بركة هدى
    // Positioned as descending streams from heaven to a receiving vessel/cupped hands
    const blessingColors = [
      Color(0xFFD4AF37), // فتح — victory (gold)
      Color(0xFF34D399), // نصر — help (emerald)
      Color(0xFF38BDF8), // نور — light (sky blue)
      Color(0xFFFBBF24), // بركة — barakah (warm amber)
      Color(0xFFA78BFA), // هدى — guidance (violet)
    ];
    const blessingLabels = ['فتح', 'نصر', 'نور', 'بركة', 'هدى'];

    // 3. Source: celestial opening at top center
    final sourceY = h * 0.06;
    final sourceAlpha = (progress * 1.5).clamp(0.0, 0.6);

    // Celestial opening glow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, sourceY), width: w * 0.5 * pulse, height: 14 * pulse),
      Paint()
        ..color = Colors.white.withValues(alpha: sourceAlpha * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, sourceY), width: w * 0.3, height: 6),
      Paint()
        ..shader = LinearGradient(colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: sourceAlpha * 0.3),
          Colors.white.withValues(alpha: sourceAlpha * 0.5),
          Colors.white.withValues(alpha: sourceAlpha * 0.3),
          Colors.transparent,
        ]).createShader(Rect.fromCenter(center: Offset(cx, sourceY), width: w * 0.3, height: 6)),
    );

    // 4. Receiving area — cupped hands / vessel at bottom
    final receiveY = h * 0.72;
    final receiveAlpha = (progress * 0.8).clamp(0.0, 0.35);

    // Cupped shape (two arcs forming a vessel)
    final vesselPath = Path();
    final vesselHalfW = w * 0.22;
    vesselPath.moveTo(cx - vesselHalfW, receiveY - 8);
    vesselPath.quadraticBezierTo(cx - vesselHalfW - 5, receiveY + 12, cx, receiveY + 20);
    vesselPath.quadraticBezierTo(cx + vesselHalfW + 5, receiveY + 12, cx + vesselHalfW, receiveY - 8);

    canvas.drawPath(vesselPath, Paint()
      ..color = Colors.white.withValues(alpha: receiveAlpha * 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round);

    // Warm glow inside vessel
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, receiveY + 8), width: vesselHalfW * 1.6, height: 20),
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: receiveAlpha * 0.08 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // 5. Five blessing streams descending from source to vessel
    for (int i = 0; i < 5; i++) {
      final threshold = (i + 1) * 0.18;
      if (progress < threshold - 0.12) continue;

      final blessingProgress = ((progress - (threshold - 0.12)) / 0.25).clamp(0.0, 1.0);
      final color = blessingColors[i];

      // Each stream has a slightly different horizontal position (fan out from source)
      final xSpread = (i - 2) * w * 0.08; // -2, -1, 0, 1, 2 spread
      final streamTopX = cx + xSpread * 0.3;
      final streamBotX = cx + xSpread;

      // Flowing animation offset
      final flowOffset = (flowPhase + i * 0.2) % 1.0;

      // Draw the stream as a series of dots flowing downward
      final streamLen = (receiveY - sourceY) * blessingProgress;
      for (int d = 0; d < 12; d++) {
        final dt = (d / 12.0 + flowOffset) % 1.0;
        final dy = sourceY + dt * streamLen;
        if (dy > receiveY) continue;
        final t = dt; // position along stream 0=top, 1=bottom
        final dx = streamTopX + (streamBotX - streamTopX) * t;
        final dotAlpha = blessingProgress * (0.15 + 0.35 * math.sin(dt * math.pi)) * (isComplete ? pulse : 1.0);
        final dotR = (1.2 + t * 1.5) * (isComplete ? pulse * 0.9 + 0.1 : 1.0);

        // Glow
        canvas.drawCircle(Offset(dx, dy), dotR + 3, Paint()
          ..color = color.withValues(alpha: dotAlpha * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        // Dot
        canvas.drawCircle(Offset(dx, dy), dotR, Paint()
          ..color = color.withValues(alpha: dotAlpha));
      }

      // Blessing orb — main orb that descends and settles
      final orbY = sourceY + streamLen * 0.85;
      final orbX = streamTopX + (streamBotX - streamTopX) * 0.85;
      final orbR = (5 + blessingProgress * 4) * (isComplete ? pulse : 1.0);
      final orbAlpha = blessingProgress * (isComplete ? 0.7 : 0.5);

      // Orb outer glow
      canvas.drawCircle(Offset(orbX, orbY), orbR + 8, Paint()
        ..color = color.withValues(alpha: orbAlpha * 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

      // Orb body
      canvas.drawCircle(Offset(orbX, orbY), orbR, Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: orbAlpha * 0.7),
          color.withValues(alpha: orbAlpha * 0.8),
          color.withValues(alpha: orbAlpha * 0.3),
          Colors.transparent,
        ], stops: const [0.0, 0.3, 0.7, 1.0])
        .createShader(Rect.fromCircle(center: Offset(orbX, orbY), radius: orbR)));

      // Label below orb when blessing is fully revealed
      if (blessingProgress > 0.7) {
        final labelAlpha = ((blessingProgress - 0.7) / 0.3) * (isComplete ? 0.8 : 0.55);
        final tp = TextPainter(
          text: TextSpan(text: blessingLabels[i], style: _illusTag(11, color.withValues(alpha: labelAlpha)).copyWith(
            shadows: [Shadow(color: color.withValues(alpha: labelAlpha * 0.4), blurRadius: 4)],
          )),
          textDirection: TextDirection.rtl,
        )..layout();
        tp.paint(canvas, Offset(orbX - tp.width / 2, orbY + orbR + 8));
      }
    }

    // 6. Connection rays from source when complete
    if (isComplete) {
      for (int i = 0; i < 7; i++) {
        final angle = -math.pi / 2 + (i - 3) * 0.22;
        final rayLen = 22.0 * pulse;
        final sx = cx + math.cos(angle) * 8;
        final sy = sourceY + math.sin(angle) * 4 + 4;
        final ex = cx + math.cos(angle) * (8 + rayLen);
        final ey = sourceY + math.sin(angle) * (4 + rayLen * 0.3) + 4;
        canvas.drawLine(Offset(sx, sy), Offset(ex, ey), Paint()
          ..shader = LinearGradient(colors: [
            Color.fromRGBO(255, 220, 120, 0.20 * pulse),
            Colors.transparent,
          ]).createShader(Rect.fromPoints(Offset(sx, sy), Offset(ex, ey)))
          ..strokeWidth = 1.2..strokeCap = StrokeCap.round);
      }
    }

    canvas.restore();

    // 7. Shockwave
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.35;
      final ringA = (1.0 - shockPhase) * 0.30;
      canvas.drawCircle(Offset(cx, h * 0.45), maxR * shockPhase, Paint()
        ..color = Color.fromRGBO(212, 175, 55, ringA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - shockPhase));
    }

    // 8. Particles — blessing sparkles
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final px = cx + p.x * w * 0.25;
        final py = h * 0.45 - t * h * 0.30;
        final a = (1.0 - t) * 0.65;
        final pSize = p.size * (1.0 - t * 0.3);
        final pColor = Color.lerp(const Color(0xFFD4AF37), const Color(0xFFA78BFA), t)!;

        canvas.drawCircle(Offset(px, py), pSize + 2, Paint()..color = pColor.withValues(alpha: a * 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(Offset(px, py), pSize, Paint()..color = pColor.withValues(alpha: a));
      }
    }

    // 9. Label
    final pct = (progress * 100).round();
    final label = isComplete ? 'بارك الله لك' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(text: label, style: _illusArabic(12, isComplete ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.82))),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(text: badgeLabel, style: const TextStyle(
          color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w800,
          letterSpacing: 0.5, shadows: [Shadow(color: Color(0xFFD4AF37), blurRadius: 6)])),
        textDirection: TextDirection.ltr,
      )..layout();
      final badgeW = tp3.width + 10; final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2; final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH), const Radius.circular(6));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  @override
  bool shouldRepaint(_FiveBlessingsPainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.particlePhase != particlePhase ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
      o.flowPhase != flowPhase;
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
    required this.progress, required this.isComplete,
    required this.tapCount, this.pointsToday = 0,
  });

  @override
  State<_GlowingPath> createState() => _GlowingPathState();
}

class _GlowingPathState extends State<_GlowingPath> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _walkCtrl;
  late Animation<double> _pulse, _grow, _pAnim, _punch, _shock;
  double _prevProgress = 0.0;
  int _prevTap = 0;
  final List<_Particle> _particles = List.generate(16, (i) => _Particle(seed: i + 1100));

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress; _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))..repeat(reverse: true);
    _pCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _walkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))..repeat();
  }

  @override
  void didUpdateWidget(_GlowingPath old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) { _growCtrl.animateTo(widget.progress); _prevProgress = widget.progress; }
    if (widget.tapCount != _prevTap) {
      _prevTap = widget.tapCount;
      for (final p in _particles) { p.reset(); }
      _pCtrl.forward(from: 0); _punchCtrl.forward(from: 0); _shockCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose();
    _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose(); _walkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _walkCtrl]),
      builder: (_, __) => SizedBox(
        height: 260,
        child: CustomPaint(
          painter: _GlowingPathPainter(
            progress: _grow.value, pulse: _pulse.value, starPhase: _starCtrl.value,
            particlePhase: _pAnim.value, particles: _particles, isComplete: widget.isComplete,
            pointsToday: widget.pointsToday, punchScale: _punch.value,
            shockPhase: _shock.value, walkPhase: _walkCtrl.value,
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
    required this.progress, required this.pulse, required this.starPhase,
    required this.particlePhase, required this.particles, required this.isComplete,
    this.pointsToday = 0, this.punchScale = 1.0, this.shockPhase = 1.0, this.walkPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 1. Background — dark to warm gradient (journey forward)
    final warmth = progress * 0.25;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO((10 + warmth * 30).round(), (14 + warmth * 20).round(), (24 + warmth * 15).round(), 1.0),
            Color.fromRGBO((12 + warmth * 40).round(), (18 + warmth * 28).round(), (30 + warmth * 20).round(), 1.0),
            Color.fromRGBO((15 + warmth * 50).round(), (22 + warmth * 35).round(), (28 + warmth * 25).round(), 1.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars
    const starPos = [
      (0.09, 0.06), (0.22, 0.14), (0.37, 0.04), (0.54, 0.10),
      (0.68, 0.06), (0.83, 0.13), (0.92, 0.07), (0.45, 0.19),
      (0.62, 0.23), (0.28, 0.21), (0.76, 0.17),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      sp.color = Colors.white.withValues(alpha: 0.18 + 0.45 * tw);
      canvas.drawCircle(Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.9 + tw * 1.0, sp);
    }

    // Apply punch
    canvas.save();
    final pathCy = h * 0.50;
    canvas.translate(cx, pathCy);
    canvas.scale(punchScale, punchScale);
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
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.38;
      final ringA = (1.0 - shockPhase) * 0.32;
      canvas.drawCircle(Offset(cx, h * 0.65), maxR * shockPhase, Paint()
        ..color = Color.fromRGBO(212, 175, 55, ringA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - shockPhase));
    }

    // 8. Particles — trail sparkles
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final px = cx + p.x * w * 0.20;
        final py = h * 0.65 - t * h * 0.40;
        final a = (1.0 - t) * 0.70;
        final pSize = p.size * (1.0 - t * 0.3);
        final pColor = Color.lerp(const Color(0xFFD4AF37), const Color(0xFF34D399), t)!;

        canvas.drawCircle(Offset(px, py), pSize + 2, Paint()..color = pColor.withValues(alpha: a * 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(Offset(px, py), pSize, Paint()..color = pColor.withValues(alpha: a));
      }
    }

    // 9. Label
    final pct = (progress * 100).round();
    final label = isComplete ? 'بارك الله يومك' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(text: label, style: _illusArabic(12, isComplete ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.82))),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(text: badgeLabel, style: const TextStyle(
          color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w800,
          letterSpacing: 0.5, shadows: [Shadow(color: Color(0xFFD4AF37), blurRadius: 6)])),
        textDirection: TextDirection.ltr,
      )..layout();
      final badgeW = tp3.width + 10; final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2; final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH), const Radius.circular(6));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
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
    final leftPath = Path()
      ..moveTo(cx - baseHalfW, baseY)
      ..lineTo(cx - topHalfW, vanishY);
    // Right edge
    final rightPath = Path()
      ..moveTo(cx + baseHalfW, baseY)
      ..lineTo(cx + topHalfW, vanishY);

    final edgeAlpha = 0.15 + progress * 0.20;
    final edgePaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: edgeAlpha)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(leftPath, edgePaint);
    canvas.drawPath(rightPath, edgePaint);

    // Illuminated path surface (fills from bottom toward vanishing point)
    final litY = baseY - (baseY - vanishY) * pathLit;
    final litHalfW = baseHalfW - (baseHalfW - topHalfW) * pathLit;

    final surfacePath = Path()
      ..moveTo(cx - baseHalfW, baseY)
      ..lineTo(cx - litHalfW, litY)
      ..lineTo(cx + litHalfW, litY)
      ..lineTo(cx + baseHalfW, baseY)
      ..close();

    final surfaceAlpha = (0.04 + progress * 0.10).clamp(0.0, 0.14);
    canvas.drawPath(surfacePath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color.fromRGBO(212, 175, 55, surfaceAlpha),
          Color.fromRGBO(52, 211, 153, surfaceAlpha * 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(cx - baseHalfW, vanishY, baseHalfW * 2, baseY - vanishY)));

    // Center dashed line
    final dashCount = (progress * 8).ceil().clamp(0, 8);
    for (int i = 0; i < dashCount; i++) {
      final t = i / 8.0;
      final dy = baseY - (baseY - vanishY) * t;
      final nextT = (i + 0.4) / 8.0;
      final nextDy = baseY - (baseY - vanishY) * nextT;
      final dashAlpha = (1.0 - t) * (0.15 + progress * 0.20);

      canvas.drawLine(
        Offset(cx, dy), Offset(cx, nextDy),
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
    final lightAlpha = ((progress - 0.1) / 0.9) * (isComplete ? 0.45 : 0.22) * pulse;
    final lightR = 15 + progress * 20;

    // Outer glow
    canvas.drawCircle(Offset(cx, vanishY), lightR + 20, Paint()
      ..color = Color.fromRGBO(212, 175, 55, lightAlpha * 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));

    // Mid glow
    canvas.drawCircle(Offset(cx, vanishY), lightR, Paint()
      ..shader = RadialGradient(colors: [
        Color.fromRGBO(255, 255, 240, lightAlpha * 1.2),
        Color.fromRGBO(212, 175, 55, lightAlpha * 0.8),
        Colors.transparent,
      ], stops: const [0.0, 0.45, 1.0])
      .createShader(Rect.fromCircle(center: Offset(cx, vanishY), radius: lightR)));

    // Core
    canvas.drawCircle(Offset(cx, vanishY), 4 * pulse, Paint()
      ..color = Colors.white.withValues(alpha: lightAlpha * 1.5));

    // Upward rays on completion
    if (isComplete) {
      for (int i = 0; i < 5; i++) {
        final angle = -math.pi / 2 + (i - 2) * 0.25;
        final rayLen = 30.0 * pulse;
        final sx = cx + math.cos(angle) * 10;
        final sy = vanishY + math.sin(angle) * 10;
        final ex = cx + math.cos(angle) * (10 + rayLen);
        final ey = vanishY + math.sin(angle) * (10 + rayLen);
        canvas.drawLine(Offset(sx, sy), Offset(ex, ey), Paint()
          ..shader = LinearGradient(colors: [
            Color.fromRGBO(255, 220, 100, 0.25 * pulse),
            Colors.transparent,
          ]).createShader(Rect.fromPoints(Offset(sx, sy), Offset(ex, ey)))
          ..strokeWidth = 1.5..strokeCap = StrokeCap.round);
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
      Color(0xFF34D399), // help (nasr)
      Color(0xFF38BDF8), // light (noor)
      Color(0xFFFBBF24), // barakah
      Color(0xFFA78BFA), // guidance (huda)
    ];

    for (int i = 0; i < 5; i++) {
      final threshold = (i + 1) * 0.20;
      if (progress < threshold - 0.15) continue;

      final mProgress = ((progress - (threshold - 0.15)) / 0.15).clamp(0.0, 1.0);
      final t = (i + 1) / 6.0; // position along path (0=bottom, 1=vanish)
      final my = baseY - (baseY - vanishY) * t;
      // Alternate left and right of center line
      final side = i.isEven ? -1.0 : 1.0;
      final pathHalfW = (w * 0.30) - ((w * 0.30) - (w * 0.03)) * t;
      final mx = cx + side * pathHalfW * 0.5;
      final mColor = milestoneColors[i];
      final mR = 4.0 * mProgress * (isComplete ? pulse : 1.0);

      // Glow
      canvas.drawCircle(Offset(mx, my), mR + 5, Paint()
        ..color = mColor.withValues(alpha: mProgress * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      // Dot
      canvas.drawCircle(Offset(mx, my), mR, Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: mProgress * 0.50),
          mColor.withValues(alpha: mProgress * 0.70),
        ]).createShader(Rect.fromCircle(center: Offset(mx, my), radius: mR)));
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

    final walkerAlpha = (0.30 + progress * 0.45).clamp(0.0, 0.75);
    final baseColor = isComplete
        ? const Color(0xFFD4AF37)
        : const Color(0xFFCDD5E0);
    final glowColor = isComplete
        ? const Color(0xFFD4AF37)
        : const Color(0xFF38BDF8);

    // Subtle bob — smooth gentle rise/fall
    final bob = math.sin(walkPhase * math.pi * 2) * 1.0 * perspScale;
    // Slight body sway for natural motion
    final sway = math.sin(walkPhase * math.pi * 2) * 0.8 * perspScale;

    final s = perspScale; // shorthand

    // -- Outer aura glow around entire figure --
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, walkerY - 2 * s + bob),
        width: 22 * s,
        height: 32 * s,
      ),
      Paint()
        ..color = glowColor.withValues(alpha: walkerAlpha * 0.08)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * s),
    );

    // -- Body silhouette: a tapered oval shape (like a person in a flowing garment) --
    final bodyPath = Path();
    final topY = walkerY - 14 * s + bob;     // top of head area
    final shoulderY = walkerY - 6 * s + bob;  // shoulder level
    final waistY = walkerY + 2 * s + bob;     // waist
    final bottomY = walkerY + 12 * s + bob;   // bottom of garment

    // Draw a smooth silhouette shape — narrow at top (head), wider at shoulders,
    // tapers at waist, flows out slightly at bottom like a robe
    bodyPath.moveTo(cx + sway, topY); // top center
    // Right side
    bodyPath.cubicTo(
      cx + 4.5 * s + sway, topY + 2 * s,        // head curves out
      cx + 6.5 * s + sway, shoulderY,             // shoulder width
      cx + 5.5 * s + sway, waistY,                // tapers at waist
    );
    bodyPath.cubicTo(
      cx + 6 * s + sway, waistY + 4 * s,          // flows out
      cx + 7 * s + sway, bottomY - 2 * s,         // garment bottom
      cx + 4 * s + sway, bottomY,                  // bottom right
    );
    // Bottom curve
    bodyPath.quadraticBezierTo(cx + sway, bottomY + 1.5 * s, cx - 4 * s + sway, bottomY);
    // Left side (mirror)
    bodyPath.cubicTo(
      cx - 7 * s + sway, bottomY - 2 * s,
      cx - 6 * s + sway, waistY + 4 * s,
      cx - 5.5 * s + sway, waistY,
    );
    bodyPath.cubicTo(
      cx - 6.5 * s + sway, shoulderY,
      cx - 4.5 * s + sway, topY + 2 * s,
      cx + sway, topY,
    );
    bodyPath.close();

    // Fill with gradient — lit from above like noor is coming from the path ahead
    canvas.drawPath(bodyPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          baseColor.withValues(alpha: walkerAlpha * 0.9),
          baseColor.withValues(alpha: walkerAlpha * 0.5),
          baseColor.withValues(alpha: walkerAlpha * 0.25),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTRB(cx - 8 * s, topY, cx + 8 * s, bottomY)));

    // -- Inner light core (a soft glow at chest level) --
    canvas.drawCircle(
      Offset(cx + sway, shoulderY + 3 * s),
      4 * s * pulse,
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
        ).createShader(Rect.fromCircle(center: Offset(cx + sway, topY + 1.5 * s), radius: 3.8 * s)),
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
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.particlePhase != particlePhase ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
      o.walkPhase != walkPhase;
}

// =============================================================================
// 🔥 Freedom Flame (عتق من النار) — Get yourself freed from Hellfire
// =============================================================================
class _FreedomFlame extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _FreedomFlame({
    required this.progress, required this.isComplete,
    required this.tapCount, this.pointsToday = 0,
  });

  @override
  State<_FreedomFlame> createState() => _FreedomFlameState();
}

class _FreedomFlameState extends State<_FreedomFlame>
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
  late AnimationController _flameCtrl;

  final List<_Particle> _particles =
      List.generate(18, (i) => _Particle(seed: i + 1300));

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2100))
      ..repeat(reverse: true);

    _pCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.10)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.10, end: 0.96)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _flameCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_FreedomFlame old) {
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
    _flameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl, _growCtrl, _starCtrl, _pCtrl,
        _punchCtrl, _shockCtrl, _flameCtrl,
      ]),
      builder: (_, __) => SizedBox(
        height: 260,
        child: CustomPaint(
          painter: _FreedomFlamePainter(
            progress: _grow.value,
            pulse: _pulse.value,
            starPhase: _starCtrl.value,
            particlePhase: _pAnim.value,
            particles: _particles,
            isComplete: widget.isComplete,
            pointsToday: widget.pointsToday,
            punchScale: _punch.value,
            shockPhase: _shock.value,
            flamePhase: _flameCtrl.value,
          ),
        ),
      ),
    );
  }
}

class _FreedomFlamePainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double flamePhase;

  // 4 flame layers — each extinguishes at 25% increments (4 reps)
  static const _flameColors = [
    Color(0xFFEF4444), // fierce red
    Color(0xFFF97316), // orange
    Color(0xFFF59E0B), // amber
    Color(0xFFDC2626), // deep red
  ];

  // Cool noor colors for the transformed state
  static const _coolColors = [
    Color(0xFF06B6D4), // cyan
    Color(0xFF3B82F6), // blue
    Color(0xFF8B5CF6), // violet
    Color(0xFF10B981), // emerald
  ];

  const _FreedomFlamePainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.flamePhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.44;

    // 1. Background — dark ember to cool serenity as progress grows
    final warmth = (1.0 - progress).clamp(0.0, 1.0);
    final coolness = progress;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(
              (26 * warmth + 8 * coolness).round(),
              (10 * warmth + 14 * coolness).round(),
              (8 * warmth + 22 * coolness).round(), 1.0),
            Color.fromRGBO(
              (30 * warmth + 10 * coolness).round(),
              (12 * warmth + 18 * coolness).round(),
              (10 * warmth + 28 * coolness).round(), 1.0),
            Color.fromRGBO(
              (22 * warmth + 8 * coolness).round(),
              (8 * warmth + 16 * coolness).round(),
              (6 * warmth + 24 * coolness).round(), 1.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars — become visible as flames recede
    const starPos = [
      (0.12, 0.08), (0.25, 0.18), (0.40, 0.05), (0.55, 0.14),
      (0.70, 0.09), (0.85, 0.17), (0.92, 0.07), (0.35, 0.24),
      (0.62, 0.22), (0.18, 0.21), (0.78, 0.26),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      final starAlpha = (progress * 0.5 * tw).clamp(0.0, 0.7);
      sp.color = Colors.white.withValues(alpha: starAlpha);
      canvas.drawCircle(
          Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.7 + tw * 0.9, sp);
    }

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -cy);

    // 3. Draw the 4 flame layers (outer ring of fire around center)
    _drawFlames(canvas, cx, cy, w, h);

    // 4. Central figure — silhouette of light (the person being freed)
    _drawFigure(canvas, cx, cy);

    canvas.restore();

    // 5. Shockwave on tap — cool blue instead of fire
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.40;
      final ringColor = isComplete
          ? const Color(0xFF06B6D4)
          : Color.lerp(const Color(0xFFF97316), const Color(0xFF06B6D4), progress)!;
      final ringA = (1.0 - shockPhase) * 0.40;
      final r = maxR * shockPhase;
      canvas.drawCircle(
        Offset(cx, cy), r,
        Paint()
          ..color = ringColor.withValues(alpha: ringA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - shockPhase),
      );
    }

    // 6. Tap particles — ember sparks transforming to cool light
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final angle = p.x * math.pi * 2;
        final dist = 15 + t * w * 0.30;
        final px = cx + math.cos(angle) * dist;
        final py = cy + math.sin(angle) * dist * 0.7 - t * 18;
        final a = (1.0 - t) * 0.75;
        final pSize = p.size * (1.0 - t * 0.3);

        final sparkColor = isComplete
            ? const Color(0xFF06B6D4)
            : Color.lerp(const Color(0xFFEF4444), const Color(0xFF06B6D4), progress)!;

        canvas.drawCircle(Offset(px, py), pSize + 2,
          Paint()
            ..color = sparkColor.withValues(alpha: a * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(
            Offset(px, py), pSize, Paint()..color = sparkColor.withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35,
            Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      }
    }

    // 7. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'أُعتقت بإذن الله' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(
        text: label,
        style: _illusArabic(12, isComplete
              ? const Color(0xFF06B6D4)
              : Colors.white.withValues(alpha: 0.82)),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 8. Points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(
          text: badgeLabel,
          style: const TextStyle(
            color: Color(0xFF06B6D4),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: [
              Shadow(color: Color(0xFF06B6D4), blurRadius: 6),
              Shadow(color: Color(0xFF06B6D4), blurRadius: 14),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp3.width + 10;
      final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2;
      final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, Paint()
        ..color = const Color(0xFF06B6D4).withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()
        ..color = const Color(0xFF06B6D4).withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  /// 4 flame layers surrounding the figure — each extinguishes at 25% intervals
  void _drawFlames(Canvas canvas, double cx, double cy, double w, double h) {
    // 4 flame arcs: top-right, bottom-right, bottom-left, top-left
    final flameAngles = [
      -math.pi * 0.25, // top-right
       math.pi * 0.25, // bottom-right
       math.pi * 0.75, // bottom-left
      -math.pi * 0.75, // top-left
    ];

    for (int i = 0; i < 4; i++) {
      final extinguishThreshold = (i + 1) * 0.25;
      final isExtinguished = progress >= extinguishThreshold;
      final layerProgress = ((progress - i * 0.25) / 0.25).clamp(0.0, 1.0);
      final baseAngle = flameAngles[i];

      if (isExtinguished) {
        // Flame extinguished → show cool noor residue fading in
        _drawCoolNoor(canvas, cx, cy, baseAngle, i, layerProgress);
      } else {
        // Flame still burning — flicker and sway
        _drawSingleFlame(canvas, cx, cy, baseAngle, i, layerProgress);
      }
    }
  }

  /// Draws a single burning flame arc
  void _drawSingleFlame(Canvas canvas, double cx, double cy,
      double baseAngle, int index, double strainProgress) {
    final baseR = 42.0;
    final flameColor = _flameColors[index];

    // Strain: flame flickers more intensely as it nears extinguishing
    final flickerIntensity = 1.0 + strainProgress * 2.0;
    final flicker = math.sin(flamePhase * math.pi * 2 * flickerIntensity + index * 1.5);
    final flicker2 = math.cos(flamePhase * math.pi * 3 + index * 2.1);

    // 3 tongues of flame per layer
    for (int t = 0; t < 3; t++) {
      final tongueAngle = baseAngle + (t - 1) * 0.28;
      final tongueLen = (18 + 8 * flicker + t * 3) * pulse;
      final tongueWidth = 6.0 + flicker2 * 2;

      final startX = cx + math.cos(tongueAngle) * baseR;
      final startY = cy + math.sin(tongueAngle) * baseR;
      final endX = cx + math.cos(tongueAngle) * (baseR + tongueLen);
      final endY = cy + math.sin(tongueAngle) * (baseR + tongueLen);
      final midX = (startX + endX) / 2 + math.sin(flamePhase * math.pi * 4 + t) * 4;
      final midY = (startY + endY) / 2 + math.cos(flamePhase * math.pi * 3 + t) * 3;

      // Flame glow
      final glowAlpha = (0.12 + strainProgress * 0.08) * pulse;
      canvas.drawCircle(
        Offset(midX, midY), tongueWidth + 6,
        Paint()
          ..color = flameColor.withValues(alpha: glowAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Flame body — path from base to tip
      final flamePath = Path()
        ..moveTo(startX - math.sin(tongueAngle) * tongueWidth * 0.4,
                 startY + math.cos(tongueAngle) * tongueWidth * 0.4)
        ..quadraticBezierTo(midX, midY,
                            endX, endY)
        ..quadraticBezierTo(midX + math.sin(tongueAngle) * tongueWidth * 0.3,
                            midY - math.cos(tongueAngle) * tongueWidth * 0.3,
                            startX + math.sin(tongueAngle) * tongueWidth * 0.4,
                            startY - math.cos(tongueAngle) * tongueWidth * 0.4)
        ..close();

      final flameAlpha = (0.45 - strainProgress * 0.15).clamp(0.15, 0.50);
      canvas.drawPath(flamePath, Paint()
        ..color = flameColor.withValues(alpha: flameAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

      // Bright core
      canvas.drawCircle(
        Offset(startX, startY), 2.5,
        Paint()
          ..color = const Color(0xFFFFE4B5).withValues(alpha: flameAlpha * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // Heat shimmer around flame area
    final shimmerAlpha = (0.06 + strainProgress * 0.04) * pulse;
    canvas.drawCircle(
      Offset(cx + math.cos(baseAngle) * (baseR + 10),
             cy + math.sin(baseAngle) * (baseR + 10)),
      20,
      Paint()
        ..color = flameColor.withValues(alpha: shimmerAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );
  }

  /// Cool noor light replacing an extinguished flame
  void _drawCoolNoor(Canvas canvas, double cx, double cy,
      double baseAngle, int index, double fadeIn) {
    final coolColor = _coolColors[index];
    final baseR = 42.0;

    // Noor orb appearing where flame was
    final orbX = cx + math.cos(baseAngle) * (baseR + 8);
    final orbY = cy + math.sin(baseAngle) * (baseR + 8);
    final orbR = 6 + fadeIn * 8;
    final orbAlpha = fadeIn * 0.35 * pulse;

    // Outer glow
    canvas.drawCircle(
      Offset(orbX, orbY), orbR + 10,
      Paint()
        ..color = coolColor.withValues(alpha: orbAlpha * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Orb body
    canvas.drawCircle(
      Offset(orbX, orbY), orbR,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: orbAlpha * 0.6),
          coolColor.withValues(alpha: orbAlpha),
          Colors.transparent,
        ], stops: const [0.0, 0.5, 1.0])
        .createShader(Rect.fromCircle(center: Offset(orbX, orbY), radius: orbR)),
    );

    // Small label — Arabic word for coolness/safety
    if (fadeIn > 0.5) {
      const labels = ['بَرْد', 'سَلَام', 'نُور', 'أَمَان'];
      final labelAlpha = ((fadeIn - 0.5) * 2).clamp(0.0, 0.7);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[index],
          style: _illusTag(11, coolColor.withValues(alpha: labelAlpha)),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(orbX - tp.width / 2, orbY + orbR + 8));
    }
  }

  /// Central figure — human silhouette of light (the person being freed)
  void _drawFigure(Canvas canvas, double cx, double cy) {
    // As progress grows, figure transitions from dim to radiant
    final figureAlpha = 0.15 + progress * 0.55;
    final figureColor = isComplete
        ? const Color(0xFF06B6D4)
        : Color.lerp(const Color(0xFF9CA3AF), const Color(0xFF06B6D4), progress)!;

    // Head
    final headR = 8.0 * pulse;
    canvas.drawCircle(
      Offset(cx, cy - 18), headR,
      Paint()
        ..color = figureColor.withValues(alpha: figureAlpha * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(cx, cy - 18), headR * 0.6,
      Paint()..color = figureColor.withValues(alpha: figureAlpha),
    );

    // Body — simple tapered form
    final bodyPath = Path()
      ..moveTo(cx - 6, cy - 10)
      ..lineTo(cx - 10, cy + 15)
      ..quadraticBezierTo(cx, cy + 20, cx + 10, cy + 15)
      ..lineTo(cx + 6, cy - 10)
      ..close();

    canvas.drawPath(bodyPath, Paint()
      ..color = figureColor.withValues(alpha: figureAlpha * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Arms raised upward on completion (celebration / du'a posture)
    if (progress > 0.5) {
      final armAlpha = ((progress - 0.5) * 2).clamp(0.0, 1.0) * figureAlpha;
      final armSpread = 12 + progress * 8;

      // Left arm
      canvas.drawLine(
        Offset(cx - 5, cy - 5),
        Offset(cx - armSpread, cy - 20 - progress * 8),
        Paint()
          ..color = figureColor.withValues(alpha: armAlpha * 0.7)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
      // Right arm
      canvas.drawLine(
        Offset(cx + 5, cy - 5),
        Offset(cx + armSpread, cy - 20 - progress * 8),
        Paint()
          ..color = figureColor.withValues(alpha: armAlpha * 0.7)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // Radiant aura on completion
    if (isComplete) {
      for (int i = 0; i < 3; i++) {
        final auraR = 25.0 + i * 12;
        final auraA = (0.10 - i * 0.03) * pulse;
        canvas.drawCircle(
          Offset(cx, cy), auraR,
          Paint()
            ..color = const Color(0xFF06B6D4).withValues(alpha: auraA)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 + i * 4),
        );
      }

      // Golden crown of freedom
      canvas.drawCircle(
        Offset(cx, cy - 28), 4 * pulse,
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: 0.40 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        Offset(cx, cy - 28), 2.0,
        Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(_FreedomFlamePainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.particlePhase != particlePhase ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
      o.flamePhase != flamePhase;
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
    required this.progress, required this.isComplete,
    required this.tapCount, this.pointsToday = 0,
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

  final List<_Particle> _particles =
      List.generate(16, (i) => _Particle(seed: i + 1400));

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);

    _pCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.10)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.10, end: 0.96)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _orbitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 8000))
      ..repeat();
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
        _pulseCtrl, _growCtrl, _starCtrl, _pCtrl,
        _punchCtrl, _shockCtrl, _orbitCtrl,
      ]),
      builder: (_, __) => SizedBox(
        height: 260,
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
    Color(0xFF10B981), // life — emerald vitality
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
    final cy = h * 0.42;

    // 1. Background — night sky transitioning to dawn warmth
    final warmth = progress * 0.2;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO((10 + warmth * 40).round(), (14 + warmth * 20).round(), (26 + warmth * 10).round(), 1.0),
            Color.fromRGBO((12 + warmth * 50).round(), (16 + warmth * 30).round(), (30 + warmth * 15).round(), 1.0),
            Color.fromRGBO((8 + warmth * 60).round(), (12 + warmth * 35).round(), (24 + warmth * 20).round(), 1.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars
    const starPos = [
      (0.08, 0.06), (0.20, 0.14), (0.35, 0.08), (0.50, 0.10),
      (0.65, 0.05), (0.80, 0.12), (0.92, 0.08), (0.45, 0.20),
      (0.72, 0.18), (0.15, 0.22),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.9);
      // Stars fade as dawn (progress) arrives
      final starAlpha = ((1.0 - progress * 0.6) * 0.35 * tw).clamp(0.0, 0.6);
      sp.color = Colors.white.withValues(alpha: starAlpha);
      canvas.drawCircle(
          Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.7 + tw * 0.8, sp);
    }

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -cy);

    // 3. The great arc — sunrise-to-sunset semicircle
    _drawArc(canvas, cx, cy, w);

    // 4. Orbiting soul — a luminous orb travelling the arc
    _drawSoul(canvas, cx, cy, w);

    // 5. Central axis — divine source (Allah's sovereignty)
    _drawCenter(canvas, cx, cy);

    canvas.restore();

    // 6. Shockwave on tap
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.38;
      final ringA = (1.0 - shockPhase) * 0.35;
      final r = maxR * shockPhase;
      final ringColor = Color.lerp(
        const Color(0xFFF59E0B), const Color(0xFFD4AF37), progress)!;
      canvas.drawCircle(
        Offset(cx, cy), r,
        Paint()
          ..color = ringColor.withValues(alpha: ringA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - shockPhase),
      );
    }

    // 7. Tap particles
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final angle = p.x * math.pi * 2;
        final dist = 15 + t * w * 0.28;
        final px = cx + math.cos(angle) * dist;
        final py = cy + math.sin(angle) * dist * 0.7 - t * 15;
        final a = (1.0 - t) * 0.70;
        final pSize = p.size * (1.0 - t * 0.3);

        final sparkColor = isComplete
            ? const Color(0xFFD4AF37)
            : Color.lerp(const Color(0xFFF59E0B), const Color(0xFF6366F1), progress)!;

        canvas.drawCircle(Offset(px, py), pSize + 2,
          Paint()
            ..color = sparkColor.withValues(alpha: a * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(
            Offset(px, py), pSize, Paint()..color = sparkColor.withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35,
            Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      }
    }

    // 8. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'وَإِلَيْكَ النُّشُور' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(
        text: label,
        style: _illusArabic(12, isComplete
              ? const Color(0xFFD4AF37)
              : Colors.white.withValues(alpha: 0.82)),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 9. Points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(
          text: badgeLabel,
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: [
              Shadow(color: Color(0xFFD4AF37), blurRadius: 6),
              Shadow(color: Color(0xFFD4AF37), blurRadius: 14),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp3.width + 10;
      final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2;
      final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  /// The great arc representing the journey: dawn → life → dusk → return
  void _drawArc(Canvas canvas, double cx, double cy, double w) {
    final arcR = w * 0.30;
    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: arcR);

    // Full arc track (faint)
    canvas.drawArc(
      arcRect, math.pi, math.pi, false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Progress arc — sweeps from left (dawn) to right (nushur)
    if (progress > 0.01) {
      final sweepAngle = math.pi * progress;
      canvas.drawArc(
        arcRect, math.pi, sweepAngle, false,
        Paint()
          ..shader = SweepGradient(
            center: Alignment.center,
            startAngle: math.pi,
            endAngle: math.pi * 2,
            colors: _phaseColors,
          ).createShader(arcRect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // 4 phase markers along the arc
    for (int i = 0; i < 4; i++) {
      final angle = math.pi + (i / 3) * math.pi; // spread across the semicircle
      final mx = cx + math.cos(angle) * arcR;
      final my = cy + math.sin(angle) * arcR;
      final phaseThreshold = (i + 1) * 0.25;
      final reached = progress >= phaseThreshold;
      final markerColor = reached ? _phaseColors[i] : Colors.white.withValues(alpha: 0.15);

      // Marker dot
      canvas.drawCircle(
        Offset(mx, my), reached ? 4.0 * pulse : 3.0,
        Paint()
          ..color = markerColor.withValues(alpha: reached ? 0.70 : 0.15),
      );
      if (reached) {
        canvas.drawCircle(
          Offset(mx, my), 7,
          Paint()
            ..color = markerColor.withValues(alpha: 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }

      // Phase label
      if (reached) {
        final labelAlpha = (progress - (i * 0.25)).clamp(0.0, 0.25) * 3;
        final tp = TextPainter(
          text: TextSpan(
            text: _phaseLabels[i],
            style: _illusTag(11, markerColor.withValues(alpha: labelAlpha.clamp(0.0, 0.7))),
          ),
          textDirection: TextDirection.rtl,
        )..layout();
        // Position label outside the arc
        final labelDist = arcR + 20;
        final lx = cx + math.cos(angle) * labelDist - tp.width / 2;
        final ly = cy + math.sin(angle) * labelDist - tp.height / 2;
        tp.paint(canvas, Offset(lx, ly));
      }
    }
  }

  /// Orbiting soul — a luminous orb travelling along the arc
  void _drawSoul(Canvas canvas, double cx, double cy, double w) {
    final arcR = w * 0.30;
    // Soul position along the arc based on progress
    final soulAngle = math.pi + math.pi * progress;
    final sx = cx + math.cos(soulAngle) * arcR;
    final sy = cy + math.sin(soulAngle) * arcR;

    // Determine soul color based on which phase it's in
    final phaseIdx = (progress * 3).floor().clamp(0, 3);
    final soulColor = isComplete
        ? const Color(0xFFD4AF37)
        : _phaseColors[phaseIdx];

    // Outer glow
    canvas.drawCircle(
      Offset(sx, sy), 12,
      Paint()
        ..color = soulColor.withValues(alpha: 0.15 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Soul body
    final soulR = 5.0 + progress * 2;
    canvas.drawCircle(
      Offset(sx, sy), soulR,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.85),
          soulColor.withValues(alpha: 0.60),
          Colors.transparent,
        ], stops: const [0.0, 0.5, 1.0])
        .createShader(Rect.fromCircle(center: Offset(sx, sy), radius: soulR)),
    );

    // Trail behind the soul
    if (progress > 0.05) {
      final trailLen = 0.15; // how far back the trail goes
      for (int i = 1; i <= 5; i++) {
        final trailProg = (progress - i * trailLen / 5).clamp(0.0, 1.0);
        final trailAngle = math.pi + math.pi * trailProg;
        final tx = cx + math.cos(trailAngle) * arcR;
        final ty = cy + math.sin(trailAngle) * arcR;
        final trailAlpha = (1.0 - i / 5) * 0.20;
        final trailR = soulR * (1.0 - i * 0.12);
        canvas.drawCircle(
          Offset(tx, ty), trailR,
          Paint()..color = soulColor.withValues(alpha: trailAlpha),
        );
      }
    }
  }

  /// Central source of divine sovereignty — "بِكَ" (by You)
  void _drawCenter(Canvas canvas, double cx, double cy) {
    final centerAlpha = 0.10 + progress * 0.40;
    final centerColor = isComplete
        ? const Color(0xFFD4AF37)
        : Color.lerp(const Color(0xFF6366F1), const Color(0xFFD4AF37), progress)!;

    // Radiating rings — sovereignty encompasses all
    for (int i = 0; i < 3; i++) {
      final ringR = 10.0 + i * 8;
      final ringA = (centerAlpha * (1.0 - i * 0.25)) * pulse;
      canvas.drawCircle(
        Offset(cx, cy), ringR,
        Paint()
          ..color = centerColor.withValues(alpha: ringA * 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // Core glow
    canvas.drawCircle(
      Offset(cx, cy), 10,
      Paint()
        ..color = centerColor.withValues(alpha: centerAlpha * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      Offset(cx, cy), 5,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: centerAlpha * 0.7),
          centerColor.withValues(alpha: centerAlpha * 0.5),
          Colors.transparent,
        ], stops: const [0.0, 0.5, 1.0])
        .createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 5)),
    );

    // "بِكَ" label at center on completion
    if (isComplete) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'بِكَ',
          style: _illusTag(10, const Color(0xFFD4AF37).withValues(alpha: 0.65 * pulse)).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy + 14));
    }
  }

  @override
  bool shouldRepaint(_CycleOfReturnPainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.particlePhase != particlePhase ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
      o.orbitPhase != orbitPhase;
}

// =============================================================================
// 🫁 Three Vessels (أوعية العافية) — Health in body, hearing, sight
// =============================================================================
class _ThreeVessels extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _ThreeVessels({
    required this.progress, required this.isComplete,
    required this.tapCount, this.pointsToday = 0,
  });

  @override
  State<_ThreeVessels> createState() => _ThreeVesselsState();
}

class _ThreeVesselsState extends State<_ThreeVessels>
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

  final List<_Particle> _particles =
      List.generate(16, (i) => _Particle(seed: i + 1500));

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);

    _pCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.10)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.10, end: 0.96)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _flowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_ThreeVessels old) {
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
        _pulseCtrl, _growCtrl, _starCtrl, _pCtrl,
        _punchCtrl, _shockCtrl, _flowCtrl,
      ]),
      builder: (_, __) => SizedBox(
        height: 260,
        child: CustomPaint(
          painter: _ThreeVesselsPainter(
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

class _ThreeVesselsPainter extends CustomPainter {
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

  // 3 vessels: body, hearing, sight — each fills at 33% intervals (3 reps)
  static const _vesselColors = [
    Color(0xFF10B981), // body — emerald vitality
    Color(0xFF3B82F6), // hearing — blue clarity
    Color(0xFF8B5CF6), // sight — violet perception
  ];

  static const _vesselLabels = ['بَدَن', 'سَمْع', 'بَصَر'];
  // Shield color for kufr/poverty/grave protection
  static const _shieldColor = Color(0xFFD4AF37);

  const _ThreeVesselsPainter({
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
    final cy = h * 0.42;

    // 1. Background — deep healing tones
    final warmth = progress * 0.15;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO((8 + warmth * 20).round(), (18 + warmth * 30).round(), (24 + warmth * 15).round(), 1.0),
            Color.fromRGBO((10 + warmth * 25).round(), (20 + warmth * 35).round(), (28 + warmth * 20).round(), 1.0),
            Color.fromRGBO((6 + warmth * 15).round(), (14 + warmth * 25).round(), (20 + warmth * 15).round(), 1.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars
    const starPos = [
      (0.10, 0.07), (0.24, 0.15), (0.42, 0.06), (0.56, 0.13),
      (0.72, 0.08), (0.88, 0.16), (0.94, 0.06), (0.30, 0.22),
      (0.64, 0.20), (0.16, 0.24),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      final starAlpha = (0.10 + progress * 0.25 + 0.30 * tw * progress).clamp(0.0, 0.6);
      sp.color = Colors.white.withValues(alpha: starAlpha);
      canvas.drawCircle(
          Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.7 + tw * 0.8, sp);
    }

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -cy);

    // 3. Three vessels arranged horizontally
    _drawVessels(canvas, cx, cy, w, h);

    // 4. Protection shield below vessels (kufr, poverty, grave)
    _drawShield(canvas, cx, cy + 55, w);

    canvas.restore();

    // 5. Shockwave on tap
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.38;
      final ringA = (1.0 - shockPhase) * 0.35;
      final r = maxR * shockPhase;
      final ringColor = Color.lerp(
        const Color(0xFF10B981), const Color(0xFF8B5CF6), progress)!;
      canvas.drawCircle(
        Offset(cx, cy), r,
        Paint()
          ..color = ringColor.withValues(alpha: ringA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - shockPhase),
      );
    }

    // 6. Tap particles
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final angle = p.x * math.pi * 2;
        final dist = 15 + t * w * 0.28;
        final px = cx + math.cos(angle) * dist;
        final py = cy + math.sin(angle) * dist * 0.7 - t * 15;
        final a = (1.0 - t) * 0.70;
        final pSize = p.size * (1.0 - t * 0.3);

        final sparkColor = isComplete
            ? _shieldColor
            : _vesselColors[(progress * 2).floor().clamp(0, 2)];

        canvas.drawCircle(Offset(px, py), pSize + 2,
          Paint()
            ..color = sparkColor.withValues(alpha: a * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(
            Offset(px, py), pSize, Paint()..color = sparkColor.withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35,
            Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      }
    }

    // 7. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'عَافَاك الله' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(
        text: label,
        style: _illusArabic(12, isComplete
              ? const Color(0xFF10B981)
              : Colors.white.withValues(alpha: 0.82)),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 8. Points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(
          text: badgeLabel,
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: [
              Shadow(color: Color(0xFF10B981), blurRadius: 6),
              Shadow(color: Color(0xFF10B981), blurRadius: 14),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp3.width + 10;
      final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2;
      final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  /// Three vessels — body, hearing, sight — each fills at 33% progress steps
  void _drawVessels(Canvas canvas, double cx, double cy, double w, double h) {
    final spacing = w * 0.25;
    final positions = [
      cx - spacing, // body (left)
      cx,           // hearing (center)
      cx + spacing, // sight (right)
    ];

    for (int i = 0; i < 3; i++) {
      final vx = positions[i];
      final vy = cy - 10;
      final fillThreshold = (i + 1) / 3.0;
      final isFilled = progress >= fillThreshold;
      final fillLevel = ((progress - i / 3.0) * 3.0).clamp(0.0, 1.0);
      final color = _vesselColors[i];

      // Vessel outline — cup/chalice shape
      final vesselW = 28.0;
      final vesselH = 36.0;
      final vesselPath = Path()
        ..moveTo(vx - vesselW / 2, vy - vesselH / 2)
        ..quadraticBezierTo(vx - vesselW / 2 - 4, vy + vesselH * 0.3,
                            vx - vesselW / 4, vy + vesselH / 2)
        ..lineTo(vx + vesselW / 4, vy + vesselH / 2)
        ..quadraticBezierTo(vx + vesselW / 2 + 4, vy + vesselH * 0.3,
                            vx + vesselW / 2, vy - vesselH / 2)
        ..close();

      // Vessel outline
      final outlineAlpha = 0.15 + fillLevel * 0.25;
      canvas.drawPath(vesselPath, Paint()
        ..color = color.withValues(alpha: outlineAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);

      // Fill level — noor rising inside the vessel
      if (fillLevel > 0.01) {
        final fillTop = vy + vesselH / 2 - vesselH * fillLevel;
        final fillRect = Rect.fromLTRB(
          vx - vesselW / 3, fillTop,
          vx + vesselW / 3, vy + vesselH / 2 - 2,
        );

        // Animated wave surface
        final waveY = fillTop + math.sin(flowPhase * math.pi * 2 + i * 1.5) * 2;

        final fillPath = Path()
          ..moveTo(fillRect.left, waveY)
          ..quadraticBezierTo(vx, waveY - 3 * math.sin(flowPhase * math.pi * 2 + i),
                              fillRect.right, waveY)
          ..lineTo(fillRect.right, fillRect.bottom)
          ..lineTo(fillRect.left, fillRect.bottom)
          ..close();

        canvas.save();
        canvas.clipPath(vesselPath);
        canvas.drawPath(fillPath, Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.25),
              color.withValues(alpha: 0.50),
            ],
          ).createShader(fillRect));
        canvas.restore();

        // Inner glow when filled
        if (isFilled) {
          canvas.drawCircle(
            Offset(vx, vy), 18,
            Paint()
              ..color = color.withValues(alpha: 0.12 * pulse)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
          );
        }
      }

      // Organ icon above vessel — simple symbolic shapes
      final iconY = vy - vesselH / 2 - 14;
      final iconAlpha = 0.25 + fillLevel * 0.50;

      if (i == 0) {
        // Body — simple figure silhouette
        canvas.drawCircle(Offset(vx, iconY - 4), 4,
          Paint()..color = color.withValues(alpha: iconAlpha));
        canvas.drawLine(Offset(vx, iconY), Offset(vx, iconY + 8),
          Paint()..color = color.withValues(alpha: iconAlpha)..strokeWidth = 1.5..strokeCap = StrokeCap.round);
      } else if (i == 1) {
        // Hearing — ear-like curve
        final earPath = Path()
          ..moveTo(vx + 3, iconY - 5)
          ..quadraticBezierTo(vx + 7, iconY, vx + 3, iconY + 5)
          ..quadraticBezierTo(vx, iconY + 2, vx + 1, iconY - 2);
        canvas.drawPath(earPath, Paint()
          ..color = color.withValues(alpha: iconAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round);
      } else {
        // Sight — eye shape
        final eyePath = Path()
          ..moveTo(vx - 6, iconY)
          ..quadraticBezierTo(vx, iconY - 5, vx + 6, iconY)
          ..quadraticBezierTo(vx, iconY + 5, vx - 6, iconY);
        canvas.drawPath(eyePath, Paint()
          ..color = color.withValues(alpha: iconAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3);
        canvas.drawCircle(Offset(vx, iconY), 2,
          Paint()..color = color.withValues(alpha: iconAlpha));
      }

      // Label below vessel
      if (fillLevel > 0.3) {
        final labelAlpha = ((fillLevel - 0.3) / 0.7).clamp(0.0, 0.7);
        final tp = TextPainter(
          text: TextSpan(
            text: _vesselLabels[i],
            style: _illusTag(11, color.withValues(alpha: labelAlpha)),
          ),
          textDirection: TextDirection.rtl,
        )..layout();
        tp.paint(canvas, Offset(vx - tp.width / 2, vy + vesselH / 2 + 6));
      }
    }
  }

  /// Protection shield below — represents protection from kufr, poverty, grave
  void _drawShield(Canvas canvas, double cx, double cy, double w) {
    // Shield only appears as progress grows
    if (progress < 0.15) return;

    final shieldAlpha = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
    final shieldR = 12 + shieldAlpha * 8;

    // Shield shape — pointed bottom, rounded top
    final shieldPath = Path()
      ..moveTo(cx, cy + shieldR + 4)  // bottom point
      ..quadraticBezierTo(cx - shieldR - 6, cy + 2, cx - shieldR, cy - shieldR * 0.3)
      ..quadraticBezierTo(cx - shieldR, cy - shieldR, cx, cy - shieldR - 2)
      ..quadraticBezierTo(cx + shieldR, cy - shieldR, cx + shieldR, cy - shieldR * 0.3)
      ..quadraticBezierTo(cx + shieldR + 6, cy + 2, cx, cy + shieldR + 4)
      ..close();

    // Shield glow
    canvas.drawCircle(
      Offset(cx, cy), shieldR + 8,
      Paint()
        ..color = _shieldColor.withValues(alpha: shieldAlpha * 0.08 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Shield fill
    canvas.drawPath(shieldPath, Paint()
      ..color = _shieldColor.withValues(alpha: shieldAlpha * 0.12));

    // Shield border
    canvas.drawPath(shieldPath, Paint()
      ..color = _shieldColor.withValues(alpha: shieldAlpha * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);

    // On completion: inner emblem
    if (isComplete) {
      canvas.drawCircle(
        Offset(cx, cy - 2), 4 * pulse,
        Paint()
          ..color = _shieldColor.withValues(alpha: 0.30 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
        Offset(cx, cy - 2), 2,
        Paint()..color = _shieldColor.withValues(alpha: 0.50),
      );
    }
  }

  @override
  bool shouldRepaint(_ThreeVesselsPainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.particlePhase != particlePhase ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
      o.flowPhase != flowPhase;
}

// =============================================================================
// 🏛️ Seven Pillars (سبع أعمدة) — Allah will suffice you in everything
// =============================================================================
class _SevenPillars extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _SevenPillars({
    required this.progress, required this.isComplete,
    required this.tapCount, this.pointsToday = 0,
  });

  @override
  State<_SevenPillars> createState() => _SevenPillarsState();
}

class _SevenPillarsState extends State<_SevenPillars>
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
  late AnimationController _shimmerCtrl;

  final List<_Particle> _particles =
      List.generate(16, (i) => _Particle(seed: i + 1600));

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2100))
      ..repeat(reverse: true);

    _pCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.10)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.10, end: 0.96)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3500))
      ..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_SevenPillars old) {
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
        _pulseCtrl, _growCtrl, _starCtrl, _pCtrl,
        _punchCtrl, _shockCtrl, _shimmerCtrl,
      ]),
      builder: (_, __) => SizedBox(
        height: 260,
        child: CustomPaint(
          painter: _SevenPillarsPainter(
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

class _SevenPillarsPainter extends CustomPainter {
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

  static const _pillarColor = Color(0xFF8B5CF6); // violet/purple — majesty
  static const _throneColor = Color(0xFFD4AF37); // golden — العرش العظيم
  static const _domeColor = Color(0xFF6366F1);   // indigo — dome of sufficiency

  const _SevenPillarsPainter({
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
    final cy = h * 0.44;

    // 1. Background — deep royal night
    final depth = progress * 0.12;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO((10 + depth * 30).round(), (8 + depth * 15).round(), (20 + depth * 25).round(), 1.0),
            Color.fromRGBO((14 + depth * 35).round(), (10 + depth * 20).round(), (26 + depth * 30).round(), 1.0),
            Color.fromRGBO((8 + depth * 20).round(), (6 + depth * 12).round(), (18 + depth * 22).round(), 1.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars
    const starPos = [
      (0.08, 0.06), (0.22, 0.14), (0.38, 0.04), (0.54, 0.12),
      (0.68, 0.07), (0.84, 0.15), (0.92, 0.05), (0.30, 0.20),
      (0.60, 0.22), (0.14, 0.18), (0.76, 0.19),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      final starAlpha = (0.10 + progress * 0.30 + 0.30 * tw * progress).clamp(0.0, 0.65);
      sp.color = Colors.white.withValues(alpha: starAlpha);
      canvas.drawCircle(
          Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.7 + tw * 0.9, sp);
    }

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -cy);

    // 3. Throne silhouette at center top
    _drawThrone(canvas, cx, cy - 30, w);

    // 4. Seven pillars arranged in semicircle below throne
    _drawPillars(canvas, cx, cy, w, h);

    // 5. Dome of sufficiency — appears on completion
    if (progress > 0.7) {
      _drawDome(canvas, cx, cy, w);
    }

    canvas.restore();

    // 6. Shockwave on tap
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.38;
      final ringA = (1.0 - shockPhase) * 0.35;
      final r = maxR * shockPhase;
      canvas.drawCircle(
        Offset(cx, cy), r,
        Paint()
          ..color = _pillarColor.withValues(alpha: ringA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - shockPhase),
      );
    }

    // 7. Tap particles
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final angle = p.x * math.pi * 2;
        final dist = 15 + t * w * 0.28;
        final px = cx + math.cos(angle) * dist;
        final py = cy + math.sin(angle) * dist * 0.7 - t * 15;
        final a = (1.0 - t) * 0.70;
        final pSize = p.size * (1.0 - t * 0.3);

        final sparkColor = isComplete ? _throneColor : _pillarColor;

        canvas.drawCircle(Offset(px, py), pSize + 2,
          Paint()
            ..color = sparkColor.withValues(alpha: a * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(
            Offset(px, py), pSize, Paint()..color = sparkColor.withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35,
            Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      }
    }

    // 8. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'حَسْبِيَ الله' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(
        text: label,
        style: _illusArabic(12, isComplete
              ? _throneColor
              : Colors.white.withValues(alpha: 0.82)),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 9. Points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(
          text: badgeLabel,
          style: const TextStyle(
            color: _throneColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: [
              Shadow(color: _throneColor, blurRadius: 6),
              Shadow(color: _throneColor, blurRadius: 14),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp3.width + 10;
      final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2;
      final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, Paint()
        ..color = _throneColor.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()
        ..color = _throneColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  /// Throne silhouette — العرش العظيم
  void _drawThrone(Canvas canvas, double cx, double cy, double w) {
    final throneAlpha = 0.08 + progress * 0.30;

    // Throne base — wide arc
    final throneW = 50.0;
    final throneH = 20.0;
    final thronePath = Path()
      ..moveTo(cx - throneW / 2, cy + throneH / 2)
      ..quadraticBezierTo(cx - throneW / 2 - 5, cy - throneH, cx - 8, cy - throneH - 5)
      ..quadraticBezierTo(cx, cy - throneH - 12 * pulse, cx + 8, cy - throneH - 5)
      ..quadraticBezierTo(cx + throneW / 2 + 5, cy - throneH, cx + throneW / 2, cy + throneH / 2)
      ..close();

    // Throne glow
    canvas.drawCircle(
      Offset(cx, cy - 5), 25,
      Paint()
        ..color = _throneColor.withValues(alpha: throneAlpha * 0.15 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );

    // Throne fill
    canvas.drawPath(thronePath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _throneColor.withValues(alpha: throneAlpha * 0.5),
          _throneColor.withValues(alpha: throneAlpha * 0.15),
        ],
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: throneW, height: throneH * 2)));

    // Throne outline
    canvas.drawPath(thronePath, Paint()
      ..color = _throneColor.withValues(alpha: throneAlpha * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);
  }

  /// Seven pillars of light — each rises at 1/7 progress intervals
  void _drawPillars(Canvas canvas, double cx, double cy, double w, double h) {
    final arcR = w * 0.32;
    final baseY = cy + 35; // pillars stand on this baseline

    for (int i = 0; i < 7; i++) {
      // Spread 7 pillars in a semicircle below the throne
      final angle = math.pi + (i / 6) * math.pi; // pi to 2pi (bottom semicircle)
      final px = cx + math.cos(angle) * arcR * 0.85;

      final riseThreshold = (i + 1) / 7.0;
      final isErected = progress >= riseThreshold;
      final pillarProgress = ((progress - i / 7.0) * 7.0).clamp(0.0, 1.0);

      // Pillar height — grows from 0 to full
      final maxH = 55.0;
      final pillarH = maxH * pillarProgress;
      final pillarW = 5.0;

      if (pillarProgress < 0.01) continue;

      final pillarTop = baseY - pillarH;
      final pillarAlpha = 0.20 + pillarProgress * 0.45;

      // Shimmer effect — light travels up the pillar
      final shimmerY = baseY - pillarH * ((shimmerPhase + i * 0.14) % 1.0);

      // Pillar glow
      canvas.drawRect(
        Rect.fromLTRB(px - pillarW, pillarTop, px + pillarW, baseY),
        Paint()
          ..color = _pillarColor.withValues(alpha: pillarAlpha * 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Pillar body — gradient from bottom to top
      canvas.drawRect(
        Rect.fromLTRB(px - pillarW / 2, pillarTop, px + pillarW / 2, baseY),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (isErected ? Colors.white : _pillarColor).withValues(alpha: pillarAlpha * 0.7),
              _pillarColor.withValues(alpha: pillarAlpha * 0.3),
            ],
          ).createShader(Rect.fromLTRB(px - pillarW / 2, pillarTop, px + pillarW / 2, baseY)),
      );

      // Shimmer dot travelling up
      if (isErected) {
        canvas.drawCircle(
          Offset(px, shimmerY), 3,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.30 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      // Pillar cap — bright tip
      canvas.drawCircle(
        Offset(px, pillarTop), 3.0 * (isErected ? pulse : 0.7),
        Paint()
          ..color = (isErected ? Colors.white : _pillarColor)
              .withValues(alpha: pillarAlpha * 0.6),
      );
      if (isErected) {
        canvas.drawCircle(
          Offset(px, pillarTop), 6,
          Paint()
            ..color = _pillarColor.withValues(alpha: 0.12 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }

      // Pillar base
      canvas.drawCircle(
        Offset(px, baseY), 2.5,
        Paint()..color = _pillarColor.withValues(alpha: pillarAlpha * 0.3),
      );
    }
  }

  /// Dome of sufficiency — كفاية — appears when most pillars are up
  void _drawDome(Canvas canvas, double cx, double cy, double w) {
    final domeProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
    final domeAlpha = domeProgress * 0.25 * pulse;
    final arcR = w * 0.32;
    final baseY = cy + 35;
    final domeTop = cy - 55;

    // Dome arc — connects all pillar tips
    final domePath = Path()
      ..moveTo(cx - arcR * 0.85, baseY)
      ..quadraticBezierTo(cx, domeTop * domeProgress + baseY * (1 - domeProgress),
                          cx + arcR * 0.85, baseY);

    canvas.drawPath(domePath, Paint()
      ..color = _domeColor.withValues(alpha: domeAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round);

    // Fill beneath dome — protective canopy
    final fillPath = Path()
      ..moveTo(cx - arcR * 0.85, baseY)
      ..quadraticBezierTo(cx, domeTop * domeProgress + baseY * (1 - domeProgress),
                          cx + arcR * 0.85, baseY)
      ..close();

    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _domeColor.withValues(alpha: domeAlpha * 0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTRB(cx - arcR, domeTop, cx + arcR, baseY)));

    // On completion — golden crown at dome apex
    if (isComplete) {
      final apexY = domeTop;
      canvas.drawCircle(
        Offset(cx, apexY), 5 * pulse,
        Paint()
          ..color = _throneColor.withValues(alpha: 0.30 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(cx, apexY), 2.5,
        Paint()..color = _throneColor.withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(_SevenPillarsPainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.particlePhase != particlePhase ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
      o.shimmerPhase != shimmerPhase;
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
    required this.progress, required this.isComplete,
    required this.tapCount, this.pointsToday = 0,
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

  final List<_Particle> _particles =
      List.generate(16, (i) => _Particle(seed: i + 1700));

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);

    _pCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.10)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.10, end: 0.96)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
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
        _pulseCtrl, _growCtrl, _starCtrl, _pCtrl,
        _punchCtrl, _shockCtrl, _glowCtrl,
      ]),
      builder: (_, __) => SizedBox(
        height: 260,
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

  static const _handColor = Color(0xFF10B981);   // emerald — prophetic noor
  static const _pathColor = Color(0xFF34D399);    // light emerald — path of light
  static const _gateColor = Color(0xFFD4AF37);    // golden — gates of Jannah

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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO((12 + warmth * 25).round(), (16 + warmth * 35).round(), (8 + warmth * 15).round(), 1.0),
            Color.fromRGBO((14 + warmth * 30).round(), (20 + warmth * 40).round(), (10 + warmth * 20).round(), 1.0),
            Color.fromRGBO((10 + warmth * 20).round(), (14 + warmth * 30).round(), (8 + warmth * 12).round(), 1.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars
    const starPos = [
      (0.10, 0.06), (0.22, 0.15), (0.40, 0.05), (0.55, 0.11),
      (0.70, 0.07), (0.85, 0.14), (0.93, 0.06), (0.32, 0.21),
      (0.65, 0.20), (0.18, 0.22),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.9);
      final starAlpha = (0.08 + progress * 0.30 + 0.30 * tw * progress).clamp(0.0, 0.6);
      sp.color = Colors.white.withValues(alpha: starAlpha);
      canvas.drawCircle(
          Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.7 + tw * 0.8, sp);
    }

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -cy);

    // 3. Jannah gates at the bottom
    _drawGates(canvas, cx, cy + 45, w);

    // 4. Path of light from hand to gates
    _drawPath(canvas, cx, cy, w, h);

    // 5. Guiding hand reaching down from above
    _drawHand(canvas, cx, cy - 30, w);

    canvas.restore();

    // 6. Shockwave on tap
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.38;
      final ringA = (1.0 - shockPhase) * 0.35;
      final r = maxR * shockPhase;
      canvas.drawCircle(
        Offset(cx, cy), r,
        Paint()
          ..color = _handColor.withValues(alpha: ringA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - shockPhase),
      );
    }

    // 7. Tap particles
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final angle = p.x * math.pi * 2;
        final dist = 15 + t * w * 0.28;
        final px = cx + math.cos(angle) * dist;
        final py = cy + math.sin(angle) * dist * 0.7 - t * 15;
        final a = (1.0 - t) * 0.70;
        final pSize = p.size * (1.0 - t * 0.3);

        final sparkColor = isComplete ? _gateColor : _handColor;

        canvas.drawCircle(Offset(px, py), pSize + 2,
          Paint()
            ..color = sparkColor.withValues(alpha: a * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(
            Offset(px, py), pSize, Paint()..color = sparkColor.withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35,
            Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      }
    }

    // 8. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'رَضِيتُ بِالله' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(
        text: label,
        style: _illusArabic(12, isComplete
              ? _gateColor
              : Colors.white.withValues(alpha: 0.82)),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 9. Points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(
          text: badgeLabel,
          style: const TextStyle(
            color: _handColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: [
              Shadow(color: _handColor, blurRadius: 6),
              Shadow(color: _handColor, blurRadius: 14),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp3.width + 10;
      final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2;
      final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, Paint()
        ..color = _handColor.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()
        ..color = _handColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  /// Luminous hand reaching down — prophetic guidance
  void _drawHand(Canvas canvas, double cx, double cy, double w) {
    // Hand descends as progress grows (comes closer)
    final handY = cy - 30 + progress * 25;
    final handAlpha = 0.15 + progress * 0.50;

    // Beam of light from above to hand
    final beamPath = Path()
      ..moveTo(cx - 8, 0)
      ..lineTo(cx + 8, 0)
      ..lineTo(cx + 3, handY - 5)
      ..lineTo(cx - 3, handY - 5)
      ..close();

    canvas.drawPath(beamPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _handColor.withValues(alpha: handAlpha * 0.05),
          _handColor.withValues(alpha: handAlpha * 0.20),
        ],
      ).createShader(Rect.fromLTRB(cx - 8, 0, cx + 8, handY)));

    // Hand glow
    canvas.drawCircle(
      Offset(cx, handY), 18,
      Paint()
        ..color = _handColor.withValues(alpha: handAlpha * 0.15 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Palm — open hand shape
    final palmW = 14.0 * pulse;
    final palmH = 10.0;

    // Palm body
    final palmPath = Path()
      ..moveTo(cx - palmW / 2, handY)
      ..quadraticBezierTo(cx - palmW / 2, handY - palmH, cx, handY - palmH - 2)
      ..quadraticBezierTo(cx + palmW / 2, handY - palmH, cx + palmW / 2, handY)
      ..quadraticBezierTo(cx, handY + 4, cx - palmW / 2, handY)
      ..close();

    canvas.drawPath(palmPath, Paint()
      ..color = _handColor.withValues(alpha: handAlpha * 0.5));
    canvas.drawPath(palmPath, Paint()
      ..color = Colors.white.withValues(alpha: handAlpha * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Fingers — 5 short lines extending upward
    for (int f = 0; f < 5; f++) {
      final fx = cx + (f - 2) * (palmW / 5);
      final fingerLen = 6.0 + (f == 2 ? 3 : (f == 1 || f == 3 ? 2 : 0));
      canvas.drawLine(
        Offset(fx, handY - palmH + 1),
        Offset(fx + (f - 2) * 0.8, handY - palmH - fingerLen),
        Paint()
          ..color = _handColor.withValues(alpha: handAlpha * 0.45)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }

    // Noor emanating from palm
    if (progress > 0.3) {
      final noorAlpha = ((progress - 0.3) / 0.7).clamp(0.0, 1.0) * 0.20 * pulse;
      canvas.drawCircle(
        Offset(cx, handY - 2), 8,
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
      final dotX = cx + math.sin(dotT * math.pi * 3 + glowPhase * math.pi * 2) * 3;

      final dotAlpha = (0.15 + progress * 0.30) * (1.0 - (dotT - 0.5).abs() * 1.2).clamp(0.2, 1.0);

      canvas.drawCircle(
        Offset(dotX, dotY), 1.8,
        Paint()..color = _pathColor.withValues(alpha: dotAlpha),
      );
      canvas.drawCircle(
        Offset(dotX, dotY), 4,
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
      Rect.fromLTWH(cx - gateW / 2 - openAmount, cy - gateH / 2, gateW / 2 - 1, gateH),
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
        Rect.fromCenter(center: Offset(cx, cy), width: openAmount * 2 + 4, height: gateH - 4),
        Paint()
          ..color = _gateColor.withValues(alpha: glowAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Door fill
    canvas.drawRRect(leftDoor, Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          _gateColor.withValues(alpha: gateAlpha * 0.20),
          _gateColor.withValues(alpha: gateAlpha * 0.35),
        ],
      ).createShader(leftDoor.outerRect));
    canvas.drawRRect(rightDoor, Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          _gateColor.withValues(alpha: gateAlpha * 0.35),
          _gateColor.withValues(alpha: gateAlpha * 0.20),
        ],
      ).createShader(rightDoor.outerRect));

    // Door outlines
    canvas.drawRRect(leftDoor, Paint()
      ..color = _gateColor.withValues(alpha: gateAlpha * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);
    canvas.drawRRect(rightDoor, Paint()
      ..color = _gateColor.withValues(alpha: gateAlpha * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);

    // Arch above gates
    final archPath = Path()
      ..moveTo(cx - gateW / 2 - openAmount - 2, cy - gateH / 2)
      ..quadraticBezierTo(cx, cy - gateH / 2 - 15 * pulse, cx + gateW / 2 + openAmount + 2, cy - gateH / 2);

    canvas.drawPath(archPath, Paint()
      ..color = _gateColor.withValues(alpha: gateAlpha * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round);

    // Door handles — small circles
    canvas.drawCircle(
      Offset(cx - 2 - openAmount, cy), 1.5,
      Paint()..color = _gateColor.withValues(alpha: gateAlpha * 0.6));
    canvas.drawCircle(
      Offset(cx + 2 + openAmount, cy), 1.5,
      Paint()..color = _gateColor.withValues(alpha: gateAlpha * 0.6));

    // Garden light flooding through on completion
    if (isComplete) {
      final floodAlpha = 0.15 * pulse;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, cy), width: openAmount * 2 + 8, height: gateH),
        Paint()
          ..shader = RadialGradient(
            colors: [
              _gateColor.withValues(alpha: floodAlpha),
              _handColor.withValues(alpha: floodAlpha * 0.5),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: gateH * 0.6)),
      );

      // جنة label
      final tp = TextPainter(
        text: TextSpan(
          text: 'جَنَّة',
          style: _illusTag(11, _gateColor.withValues(alpha: 0.55 * pulse)).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - 3));
    }
  }

  @override
  bool shouldRepaint(_GuidingHandPainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.particlePhase != particlePhase ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
      o.glowPhase != glowPhase;
}

// =============================================================================
// 🛡️ Invincible Name (الاسم الحصين) — Nothing can harm by Allah's Name
// =============================================================================
class _InvincibleName extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _InvincibleName({
    required this.progress, required this.isComplete,
    required this.tapCount, this.pointsToday = 0,
  });

  @override
  State<_InvincibleName> createState() => _InvincibleNameState();
}

class _InvincibleNameState extends State<_InvincibleName>
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
  late AnimationController _fieldCtrl;

  final List<_Particle> _particles =
      List.generate(16, (i) => _Particle(seed: i + 1800));

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2100))
      ..repeat(reverse: true);

    _pCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.10)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.10, end: 0.96)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _fieldCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat();
  }

  @override
  void didUpdateWidget(_InvincibleName old) {
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
    _fieldCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl, _growCtrl, _starCtrl, _pCtrl,
        _punchCtrl, _shockCtrl, _fieldCtrl,
      ]),
      builder: (_, __) => SizedBox(
        height: 260,
        child: CustomPaint(
          painter: _InvincibleNamePainter(
            progress: _grow.value,
            pulse: _pulse.value,
            starPhase: _starCtrl.value,
            particlePhase: _pAnim.value,
            particles: _particles,
            isComplete: widget.isComplete,
            pointsToday: widget.pointsToday,
            punchScale: _punch.value,
            shockPhase: _shock.value,
            fieldPhase: _fieldCtrl.value,
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
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;
  final double fieldPhase;

  static const _domeColor = Color(0xFF3B82F6);   // blue — divine protection
  static const _coreColor = Color(0xFFD4AF37);    // golden — Bismillah radiance
  static const _harmColor = Color(0xFF6B7280);    // grey — dissolving threats

  const _InvincibleNamePainter({
    required this.progress,
    required this.pulse,
    required this.starPhase,
    required this.particlePhase,
    required this.particles,
    required this.isComplete,
    this.pointsToday = 0,
    this.punchScale = 1.0,
    this.shockPhase = 1.0,
    this.fieldPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.44;

    // 1. Background — deep celestial blue
    final depth = progress * 0.12;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO((8 + depth * 20).round(), (16 + depth * 25).round(), (26 + depth * 30).round(), 1.0),
            Color.fromRGBO((10 + depth * 25).round(), (18 + depth * 30).round(), (30 + depth * 35).round(), 1.0),
            Color.fromRGBO((6 + depth * 15).round(), (12 + depth * 20).round(), (22 + depth * 25).round(), 1.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars
    const starPos = [
      (0.08, 0.07), (0.24, 0.16), (0.40, 0.05), (0.56, 0.13),
      (0.70, 0.08), (0.86, 0.15), (0.94, 0.06), (0.32, 0.22),
      (0.62, 0.20), (0.16, 0.24), (0.78, 0.21),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      final starAlpha = (0.10 + progress * 0.25 + 0.30 * tw * progress).clamp(0.0, 0.65);
      sp.color = Colors.white.withValues(alpha: starAlpha);
      canvas.drawCircle(
          Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.7 + tw * 0.9, sp);
    }

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -cy);

    // 3. Approaching threats that dissolve on the dome
    _drawThreats(canvas, cx, cy, w);

    // 4. Protection dome — 3 layers building with progress (3 reps)
    _drawDome(canvas, cx, cy, w);

    // 5. Central Bismillah core
    _drawCore(canvas, cx, cy);

    canvas.restore();

    // 6. Shockwave on tap
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.40;
      final ringA = (1.0 - shockPhase) * 0.40;
      final r = maxR * shockPhase;
      canvas.drawCircle(
        Offset(cx, cy), r,
        Paint()
          ..color = _domeColor.withValues(alpha: ringA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - shockPhase),
      );
    }

    // 7. Tap particles
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final angle = p.x * math.pi * 2;
        final dist = 15 + t * w * 0.30;
        final px = cx + math.cos(angle) * dist;
        final py = cy + math.sin(angle) * dist * 0.7 - t * 15;
        final a = (1.0 - t) * 0.70;
        final pSize = p.size * (1.0 - t * 0.3);

        final sparkColor = isComplete ? _coreColor : _domeColor;

        canvas.drawCircle(Offset(px, py), pSize + 2,
          Paint()
            ..color = sparkColor.withValues(alpha: a * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(
            Offset(px, py), pSize, Paint()..color = sparkColor.withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35,
            Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      }
    }

    // 8. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'لَا يَضُرُّ مَعَ اسْمِهِ شَيْء' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(
        text: label,
        style: _illusArabic(12, isComplete
              ? _domeColor
              : Colors.white.withValues(alpha: 0.82)),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 9. Points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(
          text: badgeLabel,
          style: const TextStyle(
            color: _domeColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: [
              Shadow(color: _domeColor, blurRadius: 6),
              Shadow(color: _domeColor, blurRadius: 14),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp3.width + 10;
      final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2;
      final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, Paint()
        ..color = _domeColor.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()
        ..color = _domeColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  /// 3 concentric dome layers — each at 33% progress (3 reps)
  void _drawDome(Canvas canvas, double cx, double cy, double w) {
    for (int i = 0; i < 3; i++) {
      final layerThreshold = (i + 1) / 3.0;
      final layerProgress = ((progress - i / 3.0) * 3.0).clamp(0.0, 1.0);
      if (layerProgress < 0.01) continue;

      final baseR = 30.0 + i * 22;
      final r = baseR * layerProgress;
      final alpha = (0.08 + layerProgress * 0.12) * pulse;
      final isActive = progress >= layerThreshold;

      // Dome ring
      canvas.drawCircle(
        Offset(cx, cy), r,
        Paint()
          ..color = _domeColor.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActive ? 2.0 : 1.2,
      );

      // Dome fill — very subtle
      canvas.drawCircle(
        Offset(cx, cy), r,
        Paint()
          ..color = _domeColor.withValues(alpha: alpha * 0.15),
      );

      // Rotating energy dots along each ring
      if (isActive) {
        final dotCount = 4 + i * 2;
        for (int d = 0; d < dotCount; d++) {
          final dotAngle = fieldPhase * math.pi * 2 + (d / dotCount) * math.pi * 2 + i * 0.5;
          final dx = cx + math.cos(dotAngle) * r;
          final dy = cy + math.sin(dotAngle) * r;
          canvas.drawCircle(
            Offset(dx, dy), 1.5,
            Paint()..color = _domeColor.withValues(alpha: alpha * 2.5),
          );
        }
      }
    }
  }

  /// Threats approaching and dissolving on the dome surface
  void _drawThreats(Canvas canvas, double cx, double cy, double w) {
    // 6 threats from different directions — arrows/shadows
    const threatAngles = [0.3, 1.1, 2.0, 3.3, 4.2, 5.4];

    for (int i = 0; i < threatAngles.length; i++) {
      final angle = threatAngles[i] + fieldPhase * 0.3;
      final outerR = w * 0.48;

      // Threat travels inward but dissolves at the dome boundary
      final domeR = 30.0 + (progress.clamp(0.0, 1.0) * 2).floor() * 22;
      final actualDomeR = domeR * progress.clamp(0.0, 1.0);

      // Threat position — orbiting and approaching
      final approachPhase = (fieldPhase + i * 0.16) % 1.0;
      final threatDist = outerR - (outerR - actualDomeR - 5) * approachPhase;
      final tx = cx + math.cos(angle) * threatDist;
      final ty = cy + math.sin(angle) * threatDist;

      // Dissolve when reaching dome
      final nearDome = (threatDist - actualDomeR).clamp(0.0, 30.0) / 30.0;
      final threatAlpha = nearDome * 0.25 * (1.0 - progress * 0.3);

      if (threatAlpha < 0.02) continue;

      // Threat shape — dark arrow/shard
      final shardLen = 6.0 * nearDome;
      final shardAngle = angle + math.pi; // points toward center
      final endX = tx + math.cos(shardAngle) * shardLen;
      final endY = ty + math.sin(shardAngle) * shardLen;

      canvas.drawLine(
        Offset(tx, ty), Offset(endX, endY),
        Paint()
          ..color = _harmColor.withValues(alpha: threatAlpha)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );

      // Dissolution spark when threat hits dome
      if (nearDome < 0.3 && progress > 0.1) {
        final sparkA = (1.0 - nearDome / 0.3) * 0.30 * progress;
        canvas.drawCircle(
          Offset(tx, ty), 3,
          Paint()
            ..color = _domeColor.withValues(alpha: sparkA)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
  }

  /// Central Bismillah radiance — golden core
  void _drawCore(Canvas canvas, double cx, double cy) {
    final coreAlpha = 0.15 + progress * 0.50;

    // Outer radiance
    canvas.drawCircle(
      Offset(cx, cy), 18,
      Paint()
        ..color = _coreColor.withValues(alpha: coreAlpha * 0.12 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Inner glow
    canvas.drawCircle(
      Offset(cx, cy), 10,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: coreAlpha * 0.6),
          _coreColor.withValues(alpha: coreAlpha * 0.4),
          Colors.transparent,
        ], stops: const [0.0, 0.5, 1.0])
        .createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 10)),
    );

    // Core dot
    canvas.drawCircle(
      Offset(cx, cy), 4 * pulse,
      Paint()..color = _coreColor.withValues(alpha: coreAlpha * 0.5),
    );

    // Radiating lines — 8 rays from center
    if (progress > 0.2) {
      final rayAlpha = ((progress - 0.2) / 0.8).clamp(0.0, 1.0) * 0.20 * pulse;
      for (int r = 0; r < 8; r++) {
        final rayAngle = r * math.pi / 4 + fieldPhase * 0.5;
        final innerR = 12.0;
        final outerR = 20.0 + progress * 8;
        canvas.drawLine(
          Offset(cx + math.cos(rayAngle) * innerR, cy + math.sin(rayAngle) * innerR),
          Offset(cx + math.cos(rayAngle) * outerR, cy + math.sin(rayAngle) * outerR),
          Paint()
            ..color = _coreColor.withValues(alpha: rayAlpha)
            ..strokeWidth = 1.0
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // On completion — pulsing invincibility aura
    if (isComplete) {
      for (int i = 0; i < 2; i++) {
        final auraR = 22.0 + i * 10;
        final auraA = (0.08 - i * 0.03) * pulse;
        canvas.drawCircle(
          Offset(cx, cy), auraR,
          Paint()
            ..color = _coreColor.withValues(alpha: auraA)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0 + i * 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_InvincibleNamePainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.particlePhase != particlePhase ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
      o.fieldPhase != fieldPhase;
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
    required this.progress, required this.isComplete,
    required this.tapCount, this.pointsToday = 0,
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

  final List<_Particle> _particles =
      List.generate(18, (i) => _Particle(seed: i + 1900));

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);

    _pCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.10)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.10, end: 0.96)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3500))
      ..repeat();
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
        _pulseCtrl, _growCtrl, _starCtrl, _pCtrl,
        _punchCtrl, _shockCtrl, _waveCtrl,
      ]),
      builder: (_, __) => SizedBox(
        height: 260,
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

  static const _oceanColor = Color(0xFF0EA5E9);  // sky blue — ocean
  static const _foamColor = Color(0xFFE5E7EB);   // pale grey — foam (sins)
  static const _clearColor = Color(0xFF06B6D4);   // cyan — purified water

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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO((6 + depth * 15).round(), (18 + depth * 30).round(), (24 + depth * 20).round(), 1.0),
            Color.fromRGBO((4 + depth * 10).round(), (14 + depth * 25).round(), (22 + depth * 18).round(), 1.0),
            Color.fromRGBO((3 + depth * 8).round(), (10 + depth * 20).round(), (18 + depth * 15).round(), 1.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars (above ocean horizon)
    const starPos = [
      (0.10, 0.06), (0.25, 0.10), (0.42, 0.04), (0.58, 0.08),
      (0.74, 0.05), (0.88, 0.11), (0.34, 0.14), (0.66, 0.12),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      final starAlpha = (0.15 + 0.35 * tw).clamp(0.0, 0.5);
      sp.color = Colors.white.withValues(alpha: starAlpha);
      canvas.drawCircle(
          Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.7 + tw * 0.8, sp);
    }

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -cy);

    // 3. Ocean waves
    _drawOcean(canvas, cx, cy, w, h);

    // 4. Foam particles (sins) dissolving into light
    _drawFoam(canvas, cx, cy, w, h);

    // 5. Central radiance (SubhanAllah core)
    _drawCore(canvas, cx, cy - 15);

    canvas.restore();

    // 6. Shockwave on tap
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.38;
      final ringA = (1.0 - shockPhase) * 0.35;
      final r = maxR * shockPhase;
      canvas.drawCircle(
        Offset(cx, cy), r,
        Paint()
          ..color = _oceanColor.withValues(alpha: ringA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - shockPhase),
      );
    }

    // 7. Tap particles — rising from ocean
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final angle = p.x * math.pi * 2;
        final dist = 15 + t * w * 0.28;
        final px = cx + math.cos(angle) * dist;
        final py = cy + math.sin(angle) * dist * 0.5 - t * 25;
        final a = (1.0 - t) * 0.70;
        final pSize = p.size * (1.0 - t * 0.3);

        final sparkColor = isComplete ? _clearColor : _oceanColor;

        canvas.drawCircle(Offset(px, py), pSize + 2,
          Paint()
            ..color = sparkColor.withValues(alpha: a * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(
            Offset(px, py), pSize, Paint()..color = sparkColor.withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35,
            Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      }
    }

    // 8. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'غُفِرَت بإذن الله' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(
        text: label,
        style: _illusArabic(12, isComplete
              ? _clearColor
              : Colors.white.withValues(alpha: 0.82)),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 9. Points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(
          text: badgeLabel,
          style: const TextStyle(
            color: _clearColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: [
              Shadow(color: _clearColor, blurRadius: 6),
              Shadow(color: _clearColor, blurRadius: 14),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp3.width + 10;
      final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2;
      final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, Paint()
        ..color = _clearColor.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()
        ..color = _clearColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
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
      final waterColor = Color.lerp(
        _oceanColor.withValues(alpha: layerAlpha),
        _clearColor.withValues(alpha: layerAlpha * 1.3),
        progress,
      )!;

      final wavePath = Path()..moveTo(0, layerY);
      for (double x = 0; x <= w; x += 3) {
        final y = layerY + math.sin(x / w * math.pi * frequency + phaseShift) * amplitude;
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
        Offset(crestX, crestY), 2,
        Paint()
          ..color = Colors.white.withValues(alpha: crestAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  /// Foam particles representing sins — dissolve as progress increases
  void _drawFoam(Canvas canvas, double cx, double cy, double w, double h) {
    final horizonY = cy + 10;
    final foamCount = 20;
    final remainingFoam = ((1.0 - progress) * foamCount).round();

    for (int i = 0; i < foamCount; i++) {
      // Deterministic positioning based on index
      final rng = math.Random(i * 997);
      final fx = rng.nextDouble() * w;
      final baseY = horizonY + rng.nextDouble() * 40 + 5;

      if (i >= remainingFoam) {
        // This foam particle has been "forgiven" — show rising light
        final riseT = ((progress - i / foamCount) * foamCount).clamp(0.0, 1.0);
        if (riseT < 0.01 || riseT > 0.95) continue;

        final riseY = baseY - riseT * 50;
        final riseAlpha = (1.0 - riseT) * 0.40;
        canvas.drawCircle(
          Offset(fx, riseY), 2.5 * (1.0 - riseT),
          Paint()
            ..color = _clearColor.withValues(alpha: riseAlpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      } else {
        // Foam still present — bobbing on waves
        final bobY = baseY + math.sin(wavePhase * math.pi * 2 + i * 0.8) * 3;
        final foamAlpha = 0.20 + math.sin(wavePhase * math.pi * 2 + i * 1.3) * 0.05;

        canvas.drawCircle(
          Offset(fx, bobY), 2.5,
          Paint()..color = _foamColor.withValues(alpha: foamAlpha),
        );
        canvas.drawCircle(
          Offset(fx, bobY), 4,
          Paint()
            ..color = _foamColor.withValues(alpha: foamAlpha * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }
  }

  /// Central SubhanAllah radiance above the ocean
  void _drawCore(Canvas canvas, double cx, double cy) {
    final coreAlpha = 0.15 + progress * 0.45;

    // Reflection on water below
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 50), width: 30 + progress * 20, height: 6),
      Paint()
        ..color = _clearColor.withValues(alpha: coreAlpha * 0.10 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Outer glow
    canvas.drawCircle(
      Offset(cx, cy), 18,
      Paint()
        ..color = _clearColor.withValues(alpha: coreAlpha * 0.12 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Inner core
    canvas.drawCircle(
      Offset(cx, cy), 8,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: coreAlpha * 0.7),
          _clearColor.withValues(alpha: coreAlpha * 0.4),
          Colors.transparent,
        ], stops: const [0.0, 0.5, 1.0])
        .createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 8)),
    );

    // On completion — expanded purity aura
    if (isComplete) {
      for (int i = 0; i < 3; i++) {
        final auraR = 15.0 + i * 12;
        final auraA = (0.08 - i * 0.02) * pulse;
        canvas.drawCircle(
          Offset(cx, cy), auraR,
          Paint()
            ..color = _clearColor.withValues(alpha: auraA)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0 + i * 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_OceanOfForgivenessPainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.particlePhase != particlePhase ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
      o.wavePhase != wavePhase;
}

// =============================================================================
// ⚖️ Unparalleled Scales (ميزان لا يُضاهى) — 10 slaves, 100 hasanat, shield
// =============================================================================
class _UnparalleledScales extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _UnparalleledScales({
    required this.progress, required this.isComplete,
    required this.tapCount, this.pointsToday = 0,
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

  final List<_Particle> _particles =
      List.generate(16, (i) => _Particle(seed: i + 2000));

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2100))
      ..repeat(reverse: true);

    _pCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _punchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.10)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.10, end: 0.96)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _rainCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
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
        _pulseCtrl, _growCtrl, _starCtrl, _pCtrl,
        _punchCtrl, _shockCtrl, _rainCtrl,
      ]),
      builder: (_, __) => SizedBox(
        height: 260,
        child: CustomPaint(
          painter: _UnparalleledScalesPainter(
            progress: _grow.value,
            pulse: _pulse.value,
            starPhase: _starCtrl.value,
            particlePhase: _pAnim.value,
            particles: _particles,
            isComplete: widget.isComplete,
            pointsToday: widget.pointsToday,
            punchScale: _punch.value,
            shockPhase: _shock.value,
            rainPhase: _rainCtrl.value,
          ),
        ),
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

  static const _goldColor = Color(0xFFD4AF37);   // golden hasanat
  static const _scaleColor = Color(0xFF8B5CF6);  // violet — mizan
  static const _chainColor = Color(0xFF10B981);  // emerald — freed chains
  static const _shieldColor = Color(0xFF3B82F6); // blue — shaytan shield

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
    final cx = w / 2;
    final cy = h * 0.42;

    // 1. Background — regal dark violet
    final depth = progress * 0.12;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO((12 + depth * 20).round(), (10 + depth * 15).round(), (20 + depth * 25).round(), 1.0),
            Color.fromRGBO((14 + depth * 25).round(), (12 + depth * 18).round(), (24 + depth * 30).round(), 1.0),
            Color.fromRGBO((10 + depth * 15).round(), (8 + depth * 12).round(), (18 + depth * 20).round(), 1.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars
    const starPos = [
      (0.10, 0.07), (0.24, 0.14), (0.40, 0.05), (0.56, 0.12),
      (0.72, 0.06), (0.86, 0.15), (0.48, 0.20), (0.30, 0.22),
      (0.66, 0.18), (0.14, 0.20),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      final starAlpha = (0.10 + progress * 0.25 + 0.30 * tw * progress).clamp(0.0, 0.6);
      sp.color = Colors.white.withValues(alpha: starAlpha);
      canvas.drawCircle(
          Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.7 + tw * 0.9, sp);
    }

    // Apply punch scale
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(punchScale, punchScale);
    canvas.translate(-cx, -cy);

    // 3. Scale (mizan) structure
    _drawScale(canvas, cx, cy, w);

    // 4. Four reward indicators around the scale
    _drawRewards(canvas, cx, cy, w);

    canvas.restore();

    // 5. Shockwave on tap
    if (shockPhase > 0 && shockPhase < 1) {
      final maxR = w * 0.38;
      final ringA = (1.0 - shockPhase) * 0.35;
      final r = maxR * shockPhase;
      canvas.drawCircle(
        Offset(cx, cy), r,
        Paint()
          ..color = _goldColor.withValues(alpha: ringA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - shockPhase),
      );
    }

    // 6. Golden hasanat raining down
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final angle = p.x * math.pi * 2;
        final dist = 15 + t * w * 0.28;
        final px = cx + math.cos(angle) * dist;
        final py = cy + math.sin(angle) * dist * 0.7 - t * 15;
        final a = (1.0 - t) * 0.70;
        final pSize = p.size * (1.0 - t * 0.3);

        canvas.drawCircle(Offset(px, py), pSize + 2,
          Paint()
            ..color = _goldColor.withValues(alpha: a * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(
            Offset(px, py), pSize, Paint()..color = _goldColor.withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35,
            Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      }
    }

    // 7. Progress label
    final pct = (progress * 100).round();
    final label = isComplete ? 'لَا إِلٰهَ إِلَّا الله' : '$pct%';
    final tp2 = TextPainter(
      text: TextSpan(
        text: label,
        style: _illusArabic(12, isComplete
              ? _goldColor
              : Colors.white.withValues(alpha: 0.82)),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    // 8. Points badge
    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(
          text: badgeLabel,
          style: const TextStyle(
            color: _goldColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: [
              Shadow(color: _goldColor, blurRadius: 6),
              Shadow(color: _goldColor, blurRadius: 14),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp3.width + 10;
      final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2;
      final badgeY = h * 0.88 + tp2.height + 6;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, badgeH),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, Paint()
        ..color = _goldColor.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rrect, Paint()
        ..color = _goldColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(badgeX + 5, badgeY + 3));
    }
  }

  /// Grand scale (mizan) — good deeds side rises higher with progress
  void _drawScale(Canvas canvas, double cx, double cy, double w) {
    final scaleAlpha = 0.20 + progress * 0.40;

    // Central pillar
    canvas.drawLine(
      Offset(cx, cy - 40), Offset(cx, cy + 15),
      Paint()
        ..color = _scaleColor.withValues(alpha: scaleAlpha * 0.5)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Fulcrum triangle at top
    final fulcrumPath = Path()
      ..moveTo(cx, cy - 42)
      ..lineTo(cx - 6, cy - 35)
      ..lineTo(cx + 6, cy - 35)
      ..close();
    canvas.drawPath(fulcrumPath, Paint()
      ..color = _scaleColor.withValues(alpha: scaleAlpha * 0.6));

    // Beam — tilts as good deeds accumulate (left side = good, right = empty)
    final tilt = progress * 12; // beam tilts as hasanat pile up
    final beamLen = w * 0.28;
    final beamLeftY = cy - 32 - tilt;
    final beamRightY = cy - 32 + tilt;

    canvas.drawLine(
      Offset(cx - beamLen, beamLeftY),
      Offset(cx + beamLen, beamRightY),
      Paint()
        ..color = _scaleColor.withValues(alpha: scaleAlpha * 0.5)
        ..strokeWidth = 1.8,
    );

    // Left pan — good deeds (heavy, descending with progress)
    final leftPanX = cx - beamLen;
    _drawPan(canvas, leftPanX, beamLeftY + 5, true, scaleAlpha);

    // Right pan — empty/lighter
    final rightPanX = cx + beamLen;
    _drawPan(canvas, rightPanX, beamRightY + 5, false, scaleAlpha);

    // Hasanat coins falling into left pan
    final coinCount = (progress * 8).floor().clamp(0, 8);
    for (int i = 0; i < coinCount; i++) {
      final coinX = leftPanX + (i - 3.5) * 5;
      final coinY = beamLeftY + 14 + (i % 3) * 4;
      canvas.drawCircle(
        Offset(coinX, coinY), 2.5,
        Paint()..color = _goldColor.withValues(alpha: scaleAlpha * 0.6),
      );
      canvas.drawCircle(
        Offset(coinX, coinY), 1.0,
        Paint()..color = Colors.white.withValues(alpha: scaleAlpha * 0.3),
      );
    }

    // Raining coins animation
    if (progress > 0.05) {
      for (int r = 0; r < 3; r++) {
        final rainT = (rainPhase + r * 0.33) % 1.0;
        final rainX = leftPanX + (r - 1) * 8;
        final rainY = beamLeftY - 20 + rainT * 25;
        final rainA = (1.0 - rainT) * 0.35 * progress;
        canvas.drawCircle(
          Offset(rainX, rainY), 2,
          Paint()..color = _goldColor.withValues(alpha: rainA),
        );
      }
    }
  }

  /// Scale pan — curved dish
  void _drawPan(Canvas canvas, double cx, double cy, bool isFull, double alpha) {
    final panW = 30.0;
    final panPath = Path()
      ..moveTo(cx - panW / 2, cy)
      ..quadraticBezierTo(cx, cy + (isFull ? 12 : 8), cx + panW / 2, cy);

    // Strings connecting pan to beam
    canvas.drawLine(Offset(cx - panW / 2, cy), Offset(cx, cy - 5),
      Paint()..color = _scaleColor.withValues(alpha: alpha * 0.3)..strokeWidth = 0.8);
    canvas.drawLine(Offset(cx + panW / 2, cy), Offset(cx, cy - 5),
      Paint()..color = _scaleColor.withValues(alpha: alpha * 0.3)..strokeWidth = 0.8);

    canvas.drawPath(panPath, Paint()
      ..color = (isFull ? _goldColor : _scaleColor).withValues(alpha: alpha * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    if (isFull) {
      // Glow for full pan
      canvas.drawCircle(Offset(cx, cy + 4), 12,
        Paint()
          ..color = _goldColor.withValues(alpha: alpha * 0.08 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
  }

  /// Four reward indicators: freed slaves, hasanat, sins erased, shaytan shield
  void _drawRewards(Canvas canvas, double cx, double cy, double w) {
    // Position 4 rewards evenly spread below the scale
    final rewardY = cy + 48;
    final spacing = w * 0.20;
    final rewards = [
      (cx - spacing * 1.5, rewardY, _chainColor, 'عِتْق', 0.25),       // freed slaves
      (cx - spacing * 0.5, rewardY, _goldColor, 'حَسَنَات', 0.50),     // 100 hasanat
      (cx + spacing * 0.5, rewardY, const Color(0xFFEF4444), 'مَحْو', 0.75), // sins erased
      (cx + spacing * 1.5, rewardY, _shieldColor, 'حِصْن', 1.0),       // shaytan shield
    ];

    for (int i = 0; i < rewards.length; i++) {
      final (rx, ry, color, label, threshold) = rewards[i];
      final reached = progress >= threshold;
      final rewardAlpha = reached
          ? 0.55 + 0.15 * pulse
          : (progress / threshold).clamp(0.0, 1.0) * 0.20;

      if (rewardAlpha < 0.03) continue;

      // Reward orb
      canvas.drawCircle(
        Offset(rx, ry), reached ? 7.0 * pulse : 4.5,
        Paint()..color = color.withValues(alpha: rewardAlpha),
      );
      if (reached) {
        canvas.drawCircle(
          Offset(rx, ry), 12,
          Paint()
            ..color = color.withValues(alpha: rewardAlpha * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      // Label — positioned below orb with good spacing
      if (progress > threshold * 0.5) {
        final labelAlpha = ((progress - threshold * 0.5) / (threshold * 0.5)).clamp(0.0, 0.70);
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: _illusTag(11, color.withValues(alpha: labelAlpha)),
          ),
          textDirection: TextDirection.rtl,
        )..layout();
        tp.paint(canvas, Offset(rx - tp.width / 2, ry + 14));
      }
    }

    // On completion — connecting golden rays from all 4 rewards to scale
    if (isComplete) {
      for (final (rx, ry, color, _, _) in rewards) {
        canvas.drawLine(
          Offset(rx, ry - 5), Offset(cx, cy),
          Paint()
            ..color = color.withValues(alpha: 0.10 * pulse)
            ..strokeWidth = 0.8,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_UnparalleledScalesPainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.particlePhase != particlePhase ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
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
  const _SunriseGlory({required this.progress, required this.isComplete, required this.tapCount, this.pointsToday = 0});
  @override
  State<_SunriseGlory> createState() => _SunriseGloryState();
}

class _SunriseGloryState extends State<_SunriseGlory> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _rayCtrl;
  late Animation<double> _pulse, _grow, _pAnim, _punch, _shock;
  double _prevProgress = 0.0;
  int _prevTap = 0;
  final List<_Particle> _particles = List.generate(16, (i) => _Particle(seed: i + 2100));

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress; _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _pCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _rayCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat();
  }

  @override
  void didUpdateWidget(_SunriseGlory old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) { _growCtrl.animateTo(widget.progress); _prevProgress = widget.progress; }
    if (widget.tapCount != _prevTap) { _prevTap = widget.tapCount; for (final p in _particles) p.reset(); _pCtrl.forward(from: 0); _punchCtrl.forward(from: 0); _shockCtrl.forward(from: 0); }
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose(); _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose(); _rayCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _rayCtrl]),
      builder: (_, __) => SizedBox(height: 260, child: CustomPaint(painter: _SunriseGloryPainter(
        progress: _grow.value, pulse: _pulse.value, starPhase: _starCtrl.value,
        particlePhase: _pAnim.value, particles: _particles, isComplete: widget.isComplete,
        pointsToday: widget.pointsToday, punchScale: _punch.value, shockPhase: _shock.value, rayPhase: _rayCtrl.value,
      ))),
    );
  }
}

class _SunriseGloryPainter extends CustomPainter {
  final double progress, pulse, starPhase, particlePhase, punchScale, shockPhase, rayPhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;

  static const _ringColors = [Color(0xFFF59E0B), Color(0xFF10B981), Color(0xFFEF4444)]; // SubhanAllah amber, Alhamdulillah emerald, Allahu Akbar ruby
  static const _ringLabels = ['سُبْحَان الله', 'الحَمْدُ لله', 'الله أَكْبَر'];

  const _SunriseGloryPainter({required this.progress, required this.pulse, required this.starPhase,
    required this.particlePhase, required this.particles, required this.isComplete,
    this.pointsToday = 0, this.punchScale = 1.0, this.shockPhase = 1.0, this.rayPhase = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w / 2, cy = h * 0.42;

    // Background — warm dawn
    final warmth = progress * 0.18;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
        Color.fromRGBO((20 + warmth * 60).round(), (16 + warmth * 30).round(), (10 + warmth * 15).round(), 1.0),
        Color.fromRGBO((18 + warmth * 50).round(), (14 + warmth * 25).round(), (8 + warmth * 12).round(), 1.0),
        Color.fromRGBO((14 + warmth * 40).round(), (10 + warmth * 20).round(), (6 + warmth * 10).round(), 1.0),
      ]).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Stars fade as sun rises
    const starPos = [(0.10, 0.06), (0.25, 0.14), (0.42, 0.05), (0.58, 0.10), (0.74, 0.07), (0.88, 0.13), (0.35, 0.20), (0.65, 0.18)];
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      final a = ((1.0 - progress * 0.8) * 0.35 * tw).clamp(0.0, 0.5);
      canvas.drawCircle(Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.7 + tw * 0.8, Paint()..color = Colors.white.withValues(alpha: a));
    }

    // Horizon line
    final horizonY = cy + 30;
    canvas.drawLine(Offset(0, horizonY), Offset(w, horizonY), Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.08 + progress * 0.12)..strokeWidth = 1.0);

    canvas.save(); canvas.translate(cx, cy); canvas.scale(punchScale, punchScale); canvas.translate(-cx, -cy);

    // Sun — grows and brightens with progress
    final sunR = 15 + progress * 25;
    final sunY = cy - 5 - progress * 15; // rises above horizon

    // Sun glow
    canvas.drawCircle(Offset(cx, sunY), sunR + 20, Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.08 * pulse)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));

    // Sun body
    canvas.drawCircle(Offset(cx, sunY), sunR, Paint()
      ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.70), const Color(0xFFF59E0B).withValues(alpha: 0.50), Colors.transparent], stops: const [0.0, 0.5, 1.0])
      .createShader(Rect.fromCircle(center: Offset(cx, sunY), radius: sunR)));

    // 3 concentric rings — SubhanAllah, Alhamdulillah, Allahu Akbar
    for (int i = 0; i < 3; i++) {
      final ringProgress = ((progress - i / 3.0) * 3.0).clamp(0.0, 1.0);
      if (ringProgress < 0.01) continue;
      final ringR = (sunR + 15 + i * 18) * ringProgress;
      final ringAlpha = (0.15 + ringProgress * 0.25) * pulse;
      final color = _ringColors[i];

      canvas.drawCircle(Offset(cx, sunY), ringR, Paint()..color = color.withValues(alpha: ringAlpha)..style = PaintingStyle.stroke..strokeWidth = 2.0);

      // Orbiting dot
      final dotAngle = rayPhase * math.pi * 2 + i * 2.1;
      canvas.drawCircle(Offset(cx + math.cos(dotAngle) * ringR, sunY + math.sin(dotAngle) * ringR), 2, Paint()..color = color.withValues(alpha: ringAlpha * 2));

      // Label
      if (ringProgress > 0.5) {
        final labelAlpha = ((ringProgress - 0.5) * 2).clamp(0.0, 0.6);
        final tp = TextPainter(text: TextSpan(text: _ringLabels[i], style: _illusTag(11, color.withValues(alpha: labelAlpha))), textDirection: TextDirection.rtl)..layout();
        final labelAngle = math.pi * 1.5 + (i - 1) * 0.6; // spread wider above
        final labelR = ringR + 14;
        tp.paint(canvas, Offset(cx + math.cos(labelAngle) * labelR - tp.width / 2, sunY + math.sin(labelAngle) * labelR - tp.height / 2));
      }
    }

    // Rays below horizon (reflection)
    if (progress > 0.3) {
      final rayAlpha = ((progress - 0.3) / 0.7).clamp(0.0, 1.0) * 0.06;
      for (int r = 0; r < 5; r++) {
        final rayAngle = math.pi * 0.3 + r * math.pi * 0.1;
        final rayLen = 30 + progress * 20;
        canvas.drawLine(Offset(cx, horizonY), Offset(cx + math.cos(rayAngle) * rayLen, horizonY + math.sin(rayAngle) * rayLen * 0.5),
          Paint()..color = const Color(0xFFF59E0B).withValues(alpha: rayAlpha)..strokeWidth = 1.0..strokeCap = StrokeCap.round);
      }
    }

    canvas.restore();

    // Shockwave
    if (shockPhase > 0 && shockPhase < 1) {
      canvas.drawCircle(Offset(cx, cy), w * 0.38 * shockPhase, Paint()..color = const Color(0xFFF59E0B).withValues(alpha: (1.0 - shockPhase) * 0.35)..style = PaintingStyle.stroke..strokeWidth = 2.5 * (1.0 - shockPhase));
    }

    // Particles
    if (particlePhase > 0 && particlePhase < 1) {
      for (final p in particles) {
        final t = (particlePhase / p.speed).clamp(0.0, 1.0); if (t <= 0) continue;
        final angle = p.x * math.pi * 2; final dist = 15 + t * w * 0.28;
        final px = cx + math.cos(angle) * dist, py = cy + math.sin(angle) * dist * 0.7 - t * 15;
        final a = (1.0 - t) * 0.70; final pSize = p.size * (1.0 - t * 0.3);
        canvas.drawCircle(Offset(px, py), pSize + 2, Paint()..color = const Color(0xFFF59E0B).withValues(alpha: a * 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        canvas.drawCircle(Offset(px, py), pSize, Paint()..color = const Color(0xFFF59E0B).withValues(alpha: a));
        canvas.drawCircle(Offset(px, py), pSize * 0.35, Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      }
    }

    // Label
    final label = isComplete ? 'خَيْرٌ مِمَّا طَلَعَتْ عَلَيْهِ الشَّمْس' : '${(progress * 100).round()}%';
    final tp2 = TextPainter(text: TextSpan(text: label, style: _illusArabic(12, isComplete ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.82))), textDirection: TextDirection.rtl)..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    if (pointsToday > 0) {
      final tp3 = TextPainter(text: TextSpan(text: '+$pointsToday pts', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, shadows: [Shadow(color: Color(0xFFF59E0B), blurRadius: 6)])), textDirection: TextDirection.ltr)..layout();
      final bx = cx - (tp3.width + 10) / 2, by = h * 0.88 + tp2.height + 6;
      final rr = RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, tp3.width + 10, tp3.height + 6), const Radius.circular(6));
      canvas.drawRRect(rr, Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rr, Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(bx + 5, by + 3));
    }
  }

  @override
  bool shouldRepaint(_SunriseGloryPainter o) => o.progress != progress || o.pulse != pulse || o.starPhase != starPhase || o.particlePhase != particlePhase || o.isComplete != isComplete || o.pointsToday != pointsToday || o.punchScale != punchScale || o.shockPhase != shockPhase || o.rayPhase != rayPhase;
}

// =============================================================================
// 🌙 Ten Salawat (عشر صلوات) — Receive the intercession of the Prophet
// =============================================================================
class _TenSalawat extends StatefulWidget {
  final double progress; final bool isComplete; final int tapCount; final int pointsToday;
  const _TenSalawat({required this.progress, required this.isComplete, required this.tapCount, this.pointsToday = 0});
  @override State<_TenSalawat> createState() => _TenSalawatState();
}

class _TenSalawatState extends State<_TenSalawat> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _orbitCtrl;
  late Animation<double> _pulse, _grow, _pAnim, _punch, _shock;
  double _prevProgress = 0.0; int _prevTap = 0;
  final List<_Particle> _particles = List.generate(16, (i) => _Particle(seed: i + 2200));

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress; _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2100))..repeat(reverse: true);
    _pCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut); _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000))..repeat();
  }

  @override void didUpdateWidget(_TenSalawat old) { super.didUpdateWidget(old); if (widget.progress != _prevProgress) { _growCtrl.animateTo(widget.progress); _prevProgress = widget.progress; } if (widget.tapCount != _prevTap) { _prevTap = widget.tapCount; for (final p in _particles) p.reset(); _pCtrl.forward(from: 0); _punchCtrl.forward(from: 0); _shockCtrl.forward(from: 0); } }
  @override void dispose() { _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose(); _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose(); _orbitCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _orbitCtrl]),
      builder: (_, __) => SizedBox(height: 260, child: CustomPaint(painter: _TenSalawatPainter(
        progress: _grow.value, pulse: _pulse.value, starPhase: _starCtrl.value,
        particlePhase: _pAnim.value, particles: _particles, isComplete: widget.isComplete,
        pointsToday: widget.pointsToday, punchScale: _punch.value, shockPhase: _shock.value, orbitPhase: _orbitCtrl.value,
      ))),
    );
  }
}

class _TenSalawatPainter extends CustomPainter {
  final double progress, pulse, starPhase, particlePhase, punchScale, shockPhase, orbitPhase;
  final List<_Particle> particles; final bool isComplete; final int pointsToday;
  static const _crescentColor = Color(0xFF10B981);
  static const _domeColor = Color(0xFFD4AF37);
  static const _beamColor = Color(0xFF34D399);

  const _TenSalawatPainter({required this.progress, required this.pulse, required this.starPhase, required this.particlePhase, required this.particles, required this.isComplete, this.pointsToday = 0, this.punchScale = 1.0, this.shockPhase = 1.0, this.orbitPhase = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w / 2, cy = h * 0.42;

    // Background — serene green-tinted night
    final depth = progress * 0.12;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
      Color.fromRGBO((10 + depth * 15).round(), (18 + depth * 30).round(), (16 + depth * 20).round(), 1.0),
      Color.fromRGBO((8 + depth * 12).round(), (16 + depth * 25).round(), (14 + depth * 18).round(), 1.0),
      Color.fromRGBO((6 + depth * 10).round(), (12 + depth * 20).round(), (10 + depth * 15).round(), 1.0),
    ]).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Stars
    const starPos = [(0.08, 0.06), (0.22, 0.14), (0.40, 0.04), (0.56, 0.12), (0.72, 0.07), (0.88, 0.15), (0.32, 0.20), (0.64, 0.18), (0.16, 0.22), (0.78, 0.10)];
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      canvas.drawCircle(Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.7 + tw * 0.8, Paint()..color = Colors.white.withValues(alpha: (0.10 + progress * 0.25 + 0.30 * tw * progress).clamp(0.0, 0.6)));
    }

    canvas.save(); canvas.translate(cx, cy); canvas.scale(punchScale, punchScale); canvas.translate(-cx, -cy);

    // Central dome silhouette (Madinah)
    final domeY = cy + 5;
    final domeW = 30.0, domeH = 22.0;
    final domePath = Path()..moveTo(cx - domeW, domeY)..quadraticBezierTo(cx - domeW, domeY - domeH, cx, domeY - domeH - 8 * pulse)..quadraticBezierTo(cx + domeW, domeY - domeH, cx + domeW, domeY)..close();
    canvas.drawPath(domePath, Paint()..color = _domeColor.withValues(alpha: 0.12 + progress * 0.20));
    canvas.drawPath(domePath, Paint()..color = _domeColor.withValues(alpha: 0.25 + progress * 0.15)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // Dome glow
    canvas.drawCircle(Offset(cx, domeY - 10), 20, Paint()..color = _domeColor.withValues(alpha: 0.06 * pulse)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));

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
      canvas.drawCircle(Offset(mx, my), 5, Paint()..color = _crescentColor.withValues(alpha: cAlpha));
      canvas.drawCircle(Offset(mx + 2, my - 1), 4, Paint()..color = Color.fromRGBO((10 + (depth * 15).round()).clamp(0, 255), (18 + (depth * 30).round()).clamp(0, 255), (16 + (depth * 20).round()).clamp(0, 255), 1.0)); // carve crescent shape

      if (isLit) {
        canvas.drawCircle(Offset(mx, my), 9, Paint()..color = _crescentColor.withValues(alpha: 0.08 * pulse)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      }
    }

    // Intercession beam on completion
    if (isComplete) {
      canvas.drawLine(Offset(cx, cy - 30 - domeH), Offset(cx, 0), Paint()..color = _beamColor.withValues(alpha: 0.12 * pulse)..strokeWidth = 3..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }

    canvas.restore();

    // Shockwave
    if (shockPhase > 0 && shockPhase < 1) { canvas.drawCircle(Offset(cx, cy), w * 0.38 * shockPhase, Paint()..color = _crescentColor.withValues(alpha: (1.0 - shockPhase) * 0.35)..style = PaintingStyle.stroke..strokeWidth = 2.5 * (1.0 - shockPhase)); }

    // Particles
    if (particlePhase > 0 && particlePhase < 1) { for (final p in particles) { final t = (particlePhase / p.speed).clamp(0.0, 1.0); if (t <= 0) continue; final angle = p.x * math.pi * 2; final dist = 15 + t * w * 0.28; final px = cx + math.cos(angle) * dist, py = cy + math.sin(angle) * dist * 0.7 - t * 15; final a = (1.0 - t) * 0.70; final pSize = p.size * (1.0 - t * 0.3); canvas.drawCircle(Offset(px, py), pSize + 2, Paint()..color = _crescentColor.withValues(alpha: a * 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)); canvas.drawCircle(Offset(px, py), pSize, Paint()..color = _crescentColor.withValues(alpha: a)); canvas.drawCircle(Offset(px, py), pSize * 0.35, Paint()..color = Colors.white.withValues(alpha: a * 0.6)); } }

    // Label
    final label = isComplete ? 'صَلَّى اللهُ عَلَيْهِ وَسَلَّم' : '${(progress * 100).round()}%';
    final tp2 = TextPainter(text: TextSpan(text: label, style: _illusArabic(12, isComplete ? _crescentColor : Colors.white.withValues(alpha: 0.82))), textDirection: TextDirection.rtl)..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    if (pointsToday > 0) { final tp3 = TextPainter(text: TextSpan(text: '+$pointsToday pts', style: const TextStyle(color: _crescentColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, shadows: [Shadow(color: _crescentColor, blurRadius: 6)])), textDirection: TextDirection.ltr)..layout(); final bx = cx - (tp3.width + 10) / 2, by = h * 0.88 + tp2.height + 6; final rr = RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, tp3.width + 10, tp3.height + 6), const Radius.circular(6)); canvas.drawRRect(rr, Paint()..color = _crescentColor.withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)); canvas.drawRRect(rr, Paint()..color = _crescentColor.withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 0.7); tp3.paint(canvas, Offset(bx + 5, by + 3)); }
  }

  @override bool shouldRepaint(_TenSalawatPainter o) => o.progress != progress || o.pulse != pulse || o.starPhase != starPhase || o.particlePhase != particlePhase || o.isComplete != isComplete || o.pointsToday != pointsToday || o.punchScale != punchScale || o.shockPhase != shockPhase || o.orbitPhase != orbitPhase;
}

// =============================================================================
// 🚪 Doors of Mercy (أبواب الرحمة) — Seek forgiveness 100x
// =============================================================================
class _DoorsOfMercy extends StatefulWidget {
  final double progress; final bool isComplete; final int tapCount; final int pointsToday;
  const _DoorsOfMercy({required this.progress, required this.isComplete, required this.tapCount, this.pointsToday = 0});
  @override State<_DoorsOfMercy> createState() => _DoorsOfMercyState();
}

class _DoorsOfMercyState extends State<_DoorsOfMercy> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _glowCtrl;
  late Animation<double> _pulse, _grow, _pAnim, _punch, _shock;
  double _prevProgress = 0.0; int _prevTap = 0;
  final List<_Particle> _particles = List.generate(16, (i) => _Particle(seed: i + 2300));

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress; _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _pCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut); _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))..repeat(reverse: true);
  }

  @override void didUpdateWidget(_DoorsOfMercy old) { super.didUpdateWidget(old); if (widget.progress != _prevProgress) { _growCtrl.animateTo(widget.progress); _prevProgress = widget.progress; } if (widget.tapCount != _prevTap) { _prevTap = widget.tapCount; for (final p in _particles) p.reset(); _pCtrl.forward(from: 0); _punchCtrl.forward(from: 0); _shockCtrl.forward(from: 0); } }
  @override void dispose() { _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose(); _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose(); _glowCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _glowCtrl]),
      builder: (_, __) => SizedBox(height: 260, child: CustomPaint(painter: _DoorsOfMercyPainter(
        progress: _grow.value, pulse: _pulse.value, starPhase: _starCtrl.value,
        particlePhase: _pAnim.value, particles: _particles, isComplete: widget.isComplete,
        pointsToday: widget.pointsToday, punchScale: _punch.value, shockPhase: _shock.value, glowPhase: _glowCtrl.value,
      ))),
    );
  }
}

class _DoorsOfMercyPainter extends CustomPainter {
  final double progress, pulse, starPhase, particlePhase, punchScale, shockPhase, glowPhase;
  final List<_Particle> particles; final bool isComplete; final int pointsToday;
  static const _doorColor = Color(0xFF8B5CF6);
  static const _mercyColor = Color(0xFFD4AF37);
  static const _lightColor = Color(0xFFF59E0B);

  const _DoorsOfMercyPainter({required this.progress, required this.pulse, required this.starPhase, required this.particlePhase, required this.particles, required this.isComplete, this.pointsToday = 0, this.punchScale = 1.0, this.shockPhase = 1.0, this.glowPhase = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w / 2, cy = h * 0.44;

    // Background — deep purple/violet
    final depth = progress * 0.12;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
      Color.fromRGBO((14 + depth * 20).round(), (10 + depth * 15).round(), (24 + depth * 30).round(), 1.0),
      Color.fromRGBO((16 + depth * 25).round(), (12 + depth * 18).round(), (28 + depth * 35).round(), 1.0),
      Color.fromRGBO((10 + depth * 15).round(), (8 + depth * 12).round(), (20 + depth * 25).round(), 1.0),
    ]).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Stars
    const starPos = [(0.10, 0.06), (0.24, 0.14), (0.42, 0.05), (0.58, 0.11), (0.72, 0.07), (0.88, 0.14), (0.34, 0.20), (0.66, 0.18), (0.16, 0.22)];
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      canvas.drawCircle(Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.7 + tw * 0.8, Paint()..color = Colors.white.withValues(alpha: (0.10 + progress * 0.25 + 0.30 * tw * progress).clamp(0.0, 0.6)));
    }

    canvas.save(); canvas.translate(cx, cy); canvas.scale(punchScale, punchScale); canvas.translate(-cx, -cy);

    // Grand double doors
    final doorW = 45.0, doorH = 70.0;
    final openAmount = progress * 15;
    final doorAlpha = 0.15 + progress * 0.35;

    // Light behind doors (mercy)
    if (progress > 0.1) {
      final glowAlpha = ((progress - 0.1) / 0.9).clamp(0.0, 1.0) * 0.25 * pulse;
      canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: openAmount * 2 + 6, height: doorH - 8), Paint()
        ..shader = RadialGradient(colors: [_mercyColor.withValues(alpha: glowAlpha), _lightColor.withValues(alpha: glowAlpha * 0.3), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: doorH * 0.5)));
    }

    // Light point grid on doors (100 points)
    final litPoints = (progress * 100).round().clamp(0, 100);
    final gridCols = 5, gridRows = 10;
    for (int door = 0; door < 2; door++) {
      final doorX = door == 0 ? cx - doorW / 2 - openAmount : cx + 1 + openAmount;
      final dW = doorW / 2 - 1;
      final doorRect = RRect.fromRectAndRadius(Rect.fromLTWH(doorX, cy - doorH / 2, dW, doorH), const Radius.circular(3));

      canvas.drawRRect(doorRect, Paint()..color = _doorColor.withValues(alpha: doorAlpha * 0.20));
      canvas.drawRRect(doorRect, Paint()..color = _doorColor.withValues(alpha: doorAlpha * 0.40)..style = PaintingStyle.stroke..strokeWidth = 1.2);

      // Light points on this door
      for (int r = 0; r < gridRows; r++) {
        for (int c = 0; c < gridCols; c++) {
          final ptIdx = door * 50 + r * gridCols + c;
          final isLit = ptIdx < litPoints;
          final px = doorX + (c + 0.5) * (dW / gridCols);
          final py = cy - doorH / 2 + (r + 0.5) * (doorH / gridRows);
          final ptAlpha = isLit ? (0.35 + 0.15 * math.sin(glowPhase * math.pi * 2 + ptIdx * 0.2)) : 0.05;
          canvas.drawCircle(Offset(px, py), isLit ? 1.5 : 1.0, Paint()..color = (isLit ? _mercyColor : _doorColor).withValues(alpha: ptAlpha));
        }
      }
    }

    // Arch above doors
    final archPath = Path()..moveTo(cx - doorW / 2 - openAmount - 3, cy - doorH / 2)..quadraticBezierTo(cx, cy - doorH / 2 - 20 * pulse, cx + doorW / 2 + openAmount + 3, cy - doorH / 2);
    canvas.drawPath(archPath, Paint()..color = _doorColor.withValues(alpha: doorAlpha * 0.50)..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round);

    // Mercy flooding through on completion
    if (isComplete) {
      final floodAlpha = 0.12 * pulse;
      for (int i = 0; i < 5; i++) {
        final rayAngle = -math.pi / 2 + (i - 2) * 0.25;
        final rayLen = 50.0;
        canvas.drawLine(Offset(cx, cy), Offset(cx + math.cos(rayAngle) * rayLen, cy + math.sin(rayAngle) * rayLen),
          Paint()..color = _mercyColor.withValues(alpha: floodAlpha)..strokeWidth = 2..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      }
    }

    canvas.restore();

    // Shockwave
    if (shockPhase > 0 && shockPhase < 1) { canvas.drawCircle(Offset(cx, cy), w * 0.38 * shockPhase, Paint()..color = _doorColor.withValues(alpha: (1.0 - shockPhase) * 0.35)..style = PaintingStyle.stroke..strokeWidth = 2.5 * (1.0 - shockPhase)); }

    // Particles
    if (particlePhase > 0 && particlePhase < 1) { for (final p in particles) { final t = (particlePhase / p.speed).clamp(0.0, 1.0); if (t <= 0) continue; final angle = p.x * math.pi * 2; final dist = 15 + t * w * 0.28; final px = cx + math.cos(angle) * dist, py = cy + math.sin(angle) * dist * 0.7 - t * 15; final a = (1.0 - t) * 0.70; final pSize = p.size * (1.0 - t * 0.3); canvas.drawCircle(Offset(px, py), pSize + 2, Paint()..color = _doorColor.withValues(alpha: a * 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)); canvas.drawCircle(Offset(px, py), pSize, Paint()..color = _doorColor.withValues(alpha: a)); canvas.drawCircle(Offset(px, py), pSize * 0.35, Paint()..color = Colors.white.withValues(alpha: a * 0.6)); } }

    // Label
    final label = isComplete ? 'أَسْتَغْفِرُ الله وَأَتُوبُ إِلَيْه' : '${(progress * 100).round()}%';
    final tp2 = TextPainter(text: TextSpan(text: label, style: _illusArabic(12, isComplete ? _mercyColor : Colors.white.withValues(alpha: 0.82))), textDirection: TextDirection.rtl)..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    if (pointsToday > 0) { final tp3 = TextPainter(text: TextSpan(text: '+$pointsToday pts', style: const TextStyle(color: _mercyColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, shadows: [Shadow(color: _mercyColor, blurRadius: 6)])), textDirection: TextDirection.ltr)..layout(); final bx = cx - (tp3.width + 10) / 2, by = h * 0.88 + tp2.height + 6; final rr = RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, tp3.width + 10, tp3.height + 6), const Radius.circular(6)); canvas.drawRRect(rr, Paint()..color = _mercyColor.withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)); canvas.drawRRect(rr, Paint()..color = _mercyColor.withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 0.7); tp3.paint(canvas, Offset(bx + 5, by + 3)); }
  }

  @override bool shouldRepaint(_DoorsOfMercyPainter o) => o.progress != progress || o.pulse != pulse || o.starPhase != starPhase || o.particlePhase != particlePhase || o.isComplete != isComplete || o.pointsToday != pointsToday || o.punchScale != punchScale || o.shockPhase != shockPhase || o.glowPhase != glowPhase;
}

// =============================================================================
// 🌌 Cosmic Weight (الوزن الكوني) — 4 phrases that outweigh all dhikr
// =============================================================================
class _CosmicWeight extends StatefulWidget {
  final double progress; final bool isComplete; final int tapCount; final int pointsToday;
  const _CosmicWeight({required this.progress, required this.isComplete, required this.tapCount, this.pointsToday = 0});
  @override State<_CosmicWeight> createState() => _CosmicWeightState();
}

class _CosmicWeightState extends State<_CosmicWeight> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _cosmicCtrl;
  late Animation<double> _pulse, _grow, _pAnim, _punch, _shock;
  double _prevProgress = 0.0; int _prevTap = 0;
  final List<_Particle> _particles = List.generate(18, (i) => _Particle(seed: i + 2400));

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress; _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    _pCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut); _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_punchCtrl);
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _cosmicCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))..repeat();
  }

  @override void didUpdateWidget(_CosmicWeight old) { super.didUpdateWidget(old); if (widget.progress != _prevProgress) { _growCtrl.animateTo(widget.progress); _prevProgress = widget.progress; } if (widget.tapCount != _prevTap) { _prevTap = widget.tapCount; for (final p in _particles) p.reset(); _pCtrl.forward(from: 0); _punchCtrl.forward(from: 0); _shockCtrl.forward(from: 0); } }
  @override void dispose() { _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose(); _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose(); _cosmicCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _cosmicCtrl]),
      builder: (_, __) => SizedBox(height: 260, child: CustomPaint(painter: _CosmicWeightPainter(
        progress: _grow.value, pulse: _pulse.value, starPhase: _starCtrl.value,
        particlePhase: _pAnim.value, particles: _particles, isComplete: widget.isComplete,
        pointsToday: widget.pointsToday, punchScale: _punch.value, shockPhase: _shock.value, cosmicPhase: _cosmicCtrl.value,
      ))),
    );
  }
}

class _CosmicWeightPainter extends CustomPainter {
  final double progress, pulse, starPhase, particlePhase, punchScale, shockPhase, cosmicPhase;
  final List<_Particle> particles; final bool isComplete; final int pointsToday;

  static const _phraseColors = [Color(0xFFD4AF37), Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFF8B5CF6)]; // عدد خلقه, رضا نفسه, زنة عرشه, مداد كلماته
  static const _phraseLabels = ['عَدَد خَلْقِه', 'رِضَا نَفْسِه', 'زِنَة عَرْشِه', 'مِدَاد كَلِمَاتِه'];

  const _CosmicWeightPainter({required this.progress, required this.pulse, required this.starPhase, required this.particlePhase, required this.particles, required this.isComplete, this.pointsToday = 0, this.punchScale = 1.0, this.shockPhase = 1.0, this.cosmicPhase = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w / 2, cy = h * 0.42;

    // Background — deep cosmic void
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
      const Color(0xFF080A14), const Color(0xFF0A0C18), const Color(0xFF060810),
    ]).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Dense star field — cosmic scale
    for (int i = 0; i < 25; i++) {
      final rng = math.Random(i * 313);
      final sx = rng.nextDouble() * w, sy = rng.nextDouble() * h * 0.7;
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.6);
      final a = (0.15 + 0.40 * tw + progress * 0.15).clamp(0.0, 0.7);
      canvas.drawCircle(Offset(sx, sy), 0.5 + tw * 0.8, Paint()..color = Colors.white.withValues(alpha: a));
    }

    canvas.save(); canvas.translate(cx, cy); canvas.scale(punchScale, punchScale); canvas.translate(-cx, -cy);

    // Cosmic scale — beam with two sides
    final beamY = cy - 10;
    final tilt = progress * 18; // the 4 phrases side goes down heavy
    final beamLen = w * 0.30;

    // Fulcrum
    canvas.drawCircle(Offset(cx, beamY), 3, Paint()..color = Colors.white.withValues(alpha: 0.25));

    // Beam
    canvas.drawLine(Offset(cx - beamLen, beamY + tilt), Offset(cx + beamLen, beamY - tilt),
      Paint()..color = Colors.white.withValues(alpha: 0.20)..strokeWidth = 1.5);

    // Left side — the 4 phrases (heavy, descending)
    final leftX = cx - beamLen, leftY = beamY + tilt + 8;

    // 4 phrase orbs
    for (int i = 0; i < 4; i++) {
      final phraseThreshold = (i + 1) * 0.25;
      final reached = progress >= phraseThreshold;
      final phraseProgress = ((progress - i * 0.25) / 0.25).clamp(0.0, 1.0);
      if (phraseProgress < 0.01) continue;

      final color = _phraseColors[i];
      // Spread orbs across the bottom half — evenly spaced
      final ox = cx + (i - 1.5) * (w * 0.18);
      final oy = leftY + 10;
      final orbR = 5.0 + phraseProgress * 3;

      // Orb glow
      if (reached) {
        canvas.drawCircle(Offset(ox, oy), orbR + 6, Paint()..color = color.withValues(alpha: 0.10 * pulse)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      }

      canvas.drawCircle(Offset(ox, oy), orbR, Paint()
        ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: reached ? 0.6 : 0.2), color.withValues(alpha: reached ? 0.5 : 0.15), Colors.transparent], stops: const [0.0, 0.5, 1.0])
        .createShader(Rect.fromCircle(center: Offset(ox, oy), radius: orbR)));

      // Label
      if (reached) {
        final tp = TextPainter(text: TextSpan(text: _phraseLabels[i], style: _illusTag(11, color.withValues(alpha: 0.55 * pulse))), textDirection: TextDirection.rtl)..layout();
        tp.paint(canvas, Offset(ox - tp.width / 2, oy + orbR + 8));
      }
    }

    // Right side — mountains of other dhikr (light, rising)
    final rightX = cx + beamLen, rightY = beamY - tilt + 8;
    // Small mountain shapes
    for (int m = 0; m < 3; m++) {
      final mx = rightX + (m - 1) * 12;
      final mh = 10.0 + m * 3;
      final mountainPath = Path()
        ..moveTo(mx - 8, rightY + 12)
        ..lineTo(mx, rightY + 12 - mh * 0.5)
        ..lineTo(mx + 8, rightY + 12)
        ..close();
      canvas.drawPath(mountainPath, Paint()..color = const Color(0xFF6B7280).withValues(alpha: 0.15));
    }

    // Connecting strings
    canvas.drawLine(Offset(leftX, beamY + tilt), Offset(leftX, leftY + 5), Paint()..color = Colors.white.withValues(alpha: 0.12)..strokeWidth = 0.8);
    canvas.drawLine(Offset(rightX, beamY - tilt), Offset(rightX, rightY + 5), Paint()..color = Colors.white.withValues(alpha: 0.12)..strokeWidth = 0.8);

    // Orbiting cosmic dust
    if (progress > 0.5) {
      for (int d = 0; d < 6; d++) {
        final angle = cosmicPhase * math.pi * 2 + d * math.pi / 3;
        final dustR = 50 + d * 8.0;
        final dx = cx + math.cos(angle) * dustR;
        final dy = cy + math.sin(angle) * dustR * 0.4;
        final dustA = ((progress - 0.5) * 2).clamp(0.0, 1.0) * 0.15;
        canvas.drawCircle(Offset(dx, dy), 1, Paint()..color = _phraseColors[d % 4].withValues(alpha: dustA));
      }
    }

    canvas.restore();

    // Shockwave
    if (shockPhase > 0 && shockPhase < 1) { canvas.drawCircle(Offset(cx, cy), w * 0.40 * shockPhase, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: (1.0 - shockPhase) * 0.35)..style = PaintingStyle.stroke..strokeWidth = 2.5 * (1.0 - shockPhase)); }

    // Particles
    if (particlePhase > 0 && particlePhase < 1) { for (final p in particles) { final t = (particlePhase / p.speed).clamp(0.0, 1.0); if (t <= 0) continue; final angle = p.x * math.pi * 2; final dist = 15 + t * w * 0.30; final px = cx + math.cos(angle) * dist, py = cy + math.sin(angle) * dist * 0.7 - t * 18; final a = (1.0 - t) * 0.70; final pSize = p.size * (1.0 - t * 0.3); final sc = _phraseColors[(t * 3).floor().clamp(0, 3)]; canvas.drawCircle(Offset(px, py), pSize + 2, Paint()..color = sc.withValues(alpha: a * 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)); canvas.drawCircle(Offset(px, py), pSize, Paint()..color = sc.withValues(alpha: a)); canvas.drawCircle(Offset(px, py), pSize * 0.35, Paint()..color = Colors.white.withValues(alpha: a * 0.6)); } }

    // Label
    final label = isComplete ? 'سُبْحَانَ اللهِ وَبِحَمْدِه' : '${(progress * 100).round()}%';
    final tp2 = TextPainter(text: TextSpan(text: label, style: _illusArabic(12, isComplete ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.82))), textDirection: TextDirection.rtl)..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.88));

    if (pointsToday > 0) { final tp3 = TextPainter(text: TextSpan(text: '+$pointsToday pts', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, shadows: [Shadow(color: Color(0xFFD4AF37), blurRadius: 6)])), textDirection: TextDirection.ltr)..layout(); final bx = cx - (tp3.width + 10) / 2, by = h * 0.88 + tp2.height + 6; final rr = RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, tp3.width + 10, tp3.height + 6), const Radius.circular(6)); canvas.drawRRect(rr, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)); canvas.drawRRect(rr, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 0.7); tp3.paint(canvas, Offset(bx + 5, by + 3)); }
  }

  @override bool shouldRepaint(_CosmicWeightPainter o) => o.progress != progress || o.pulse != pulse || o.starPhase != starPhase || o.particlePhase != particlePhase || o.isComplete != isComplete || o.pointsToday != pointsToday || o.punchScale != punchScale || o.shockPhase != shockPhase || o.cosmicPhase != cosmicPhase;
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
      height: 3,
      child: CustomPaint(
        size: Size(MediaQuery.of(context).size.width, 3),
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

  // Vibrant palette for completed segments — bright enough on dark AppBar
  static const _doneColors = [
    Color(0xFF34D399), // emerald
    Color(0xFFFBBF24), // amber
    Color(0xFFF87171), // coral red
    Color(0xFF60A5FA), // sky blue
    Color(0xFFA78BFA), // violet
    Color(0xFF2DD4BF), // teal
    Color(0xFFFB923C), // orange
    Color(0xFFF472B6), // pink
    Color(0xFF4ADE80), // green
    Color(0xFF38BDF8), // light blue
    Color(0xFFE879F9), // fuchsia
    Color(0xFFFCD34D), // yellow
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final w = size.width;
    final h = size.height;
    final segW = w / total;
    const gap = 1.5;

    for (int i = 0; i < total; i++) {
      final x = i * segW + gap / 2;
      final sW = segW - gap;
      if (sW <= 0) continue;

      final done = completedFlags[i];
      final isCurrent = i == currentIndex;
      final segColor = _doneColors[i % _doneColors.length];

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, sW, h),
        const Radius.circular(1.5),
      );

      if (done || isCurrent) {
        // Completed or active — show its vibrant color
        canvas.drawRRect(rect, Paint()..color = segColor);
        // Current segment gets a soft glow to stand out
        if (isCurrent && !done) {
          canvas.drawRRect(
            rect.inflate(1.5),
            Paint()
              ..color = segColor.withValues(alpha: 0.35)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );
        }
      } else {
        // Pending — dim
        canvas.drawRRect(rect, Paint()..color = Colors.white.withValues(alpha: 0.15));
      }
    }
  }

  @override
  bool shouldRepaint(_ProgressLinePainter o) =>
      o.total != total || o.currentIndex != currentIndex ||
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
      clipBehavior: Clip.hardEdge,
      child: isComplete
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
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
