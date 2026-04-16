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
import '../services/settings_service.dart';
import '../widgets/noor_icons.dart';

// ── Arabic font options (shared with Quran screen) ────────────────────────────
typedef _ArabicFont = ({String name, String arabicPreview, TextStyle Function(double size, Color color, double height, FontWeight weight) style});

final List<_ArabicFont> _kArabicFonts = [
  (
    name: 'Uthmani',
    arabicPreview: 'بِسْمِ ٱللَّهِ',
    style: (size, color, height, weight) =>
        GoogleFonts.scheherazadeNew(fontSize: size, color: color, height: height, fontWeight: weight),
  ),
  (
    name: 'Indo pak',
    arabicPreview: 'بِسۡمِ اللهِ',
    style: (size, color, height, weight) =>
        TextStyle(fontFamily: 'AlQalamQuran', fontFamilyFallback: const ['ScheherazadeNew', 'Noto Naskh Arabic'], fontSize: size + 6, color: color, height: height, fontWeight: FontWeight.normal),
  ),
  (
    name: 'Madina',
    arabicPreview: 'بِسْمِ ٱللَّهِ',
    style: (size, color, height, weight) =>
        GoogleFonts.notoNaskhArabic(fontSize: size, color: color, height: height, fontWeight: weight),
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
  final String hadithFull;
  final String? audioUrl; // For online MP3 playback
  final int    sortOrder;

  const _Azkar({
    required this.id, required this.arabic, required this.transliteration,
    required this.translation, required this.recommendedCount,
    required this.category, required this.reward, required this.reference,
    this.hadithFull = '',
    this.audioUrl,
    this.sortOrder = 0,
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
    hadithFull:       j['hadith_full'] as String? ?? '',
    audioUrl:         j['audio_url'] as String?,
    sortOrder:        j['sort_order'] as int? ?? 0,
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
  double translationFontSize = 17.0;
  bool darkMode = false;
  int arabicFontIdx = 0;  // index into _kArabicFonts
  bool showTranslation = false;
  bool showTransliteration = true;
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
      _settings.translationFontSize = prefs.getDouble('dhikr_tr_size') ?? 17.0;
      _settings.darkMode = prefs.getBool('dhikr_dark_mode') ?? false;
      _settings.showTranslation = prefs.getBool('dhikr_show_translation_v2') ?? false;
      _settings.showTransliteration = prefs.getBool('dhikr_show_transliteration') ?? true;
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
    await prefs.setBool('dhikr_show_translation_v2', _settings.showTranslation);
    await prefs.setBool('dhikr_show_transliteration', _settings.showTransliteration);
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
      final fetchedCats = (catRes as List)
        .where((c) => c['is_visible'] != false)
        .map((c) => _Category(
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
      _filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
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
      final coins = SettingsService.instance.config.coinsPerDhikr;
      await Supabase.instance.client.rpc('earn_dhikr_points', params: {
        'p_type': dhikrId, 
        'p_count': target,
        'p_coins': coins
      });

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
        _pointsToday += coins;
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
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Show Translation',
                              style: GoogleFonts.outfit(fontSize: 16, color: txtColor)),
                          activeTrackColor: const Color(0xFF0D9488),
                          value: _settings.showTranslation,
                          onChanged: (val) {
                            setModalState(() => _settings.showTranslation = val);
                            setState(() => _settings.showTranslation = val);
                            onUpdate?.call();
                            _savePrefs();
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Show Transliteration',
                              style: GoogleFonts.outfit(fontSize: 16, color: txtColor)),
                          activeTrackColor: const Color(0xFF0D9488),
                          value: _settings.showTransliteration,
                          onChanged: (val) {
                            setModalState(() => _settings.showTransliteration = val);
                            setState(() => _settings.showTransliteration = val);
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
                            final translationSize = 16.0 + (val - 20.0) * (12.0 / 36.0);
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
    Color catColor(String catId) => switch (catId) {
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
              final catAccent = catColor(cat.id);
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Index badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isComplete
                                  ? catColor(azkar.category)
                                  : catColor(azkar.category).withValues(alpha: isDark ? 0.15 : 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: isComplete
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                : Text('${index + 1}', style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800, fontSize: 15,
                                    color: isComplete
                                        ? Colors.white
                                        : catColor(azkar.category).withValues(alpha: isDark ? 0.90 : 0.80))),
                          ),
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _categories.firstWhere((c) => c.id == azkar.category, orElse: () => _categories.first).icon,
                                size: 16,
                                color: catColor(azkar.category),
                              ),
                            ),
                          ),
                        ],
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

  // ── Draggable counter position ──
  Offset? _counterOffset; // null = default bottom-center
  bool _isDragging = false;

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

      if (!isSwipe) {
        final currentGlobalIndex = widget.azkars.indexOf(azkar);
        final nextIndex = currentGlobalIndex + 1;
        if (nextIndex > 0 && nextIndex < widget.azkars.length) {
          // Let the user enjoy the completed illustration before auto-swiping
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (!mounted) return;
            _pageController.animateToPage(
              nextIndex,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
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
      final appBarColor = _illustrationTopColor(widget.azkars[safeIndex].id, isDark);

      return PopScope(
        child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : _scaffoldBgForCategory(widget.azkars[safeIndex].category),
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          toolbarHeight: 92,
          flexibleSpace: Builder(
            builder: (context) {
              int ci = safeIndex;
              try {
                if (_pageController.hasClients && _pageController.page != null) {
                  ci = _pageController.page!.round().clamp(0, widget.azkars.length - 1);
                }
              } catch (_) {}
              final catId = widget.azkars[ci].category;
              final isMorning = catId == 'morning';
              final isEvening = catId == 'evening';
              final List<Color> gradColors = isMorning
                ? [const Color(0xFF0C4A3E), const Color(0xFF0A6B52), const Color(0xFF0D9488)]
                : isEvening
                  ? [const Color(0xFF1E1B4B), const Color(0xFF312E81), const Color(0xFF4338CA)]
                  : [appBarColor, appBarColor, appBarColor];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradColors,
                  ),
                  boxShadow: [
                    BoxShadow(color: gradColors.last.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
              );
            },
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white.withValues(alpha: 0.90), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Builder(
            builder: (context) {
              int ci = safeIndex;
              try {
                if (_pageController.hasClients && _pageController.page != null) {
                  ci = _pageController.page!.round().clamp(0, widget.azkars.length - 1);
                }
              } catch (_) {}
              final azkar = widget.azkars[ci];
              final catId = azkar.category;
              final catObj = widget.parentState._categories.cast<_Category?>().firstWhere((c) => c?.id == catId, orElse: () => null);
              final String catLabel = catObj?.label ?? 'Dhikr & Dua';
              final timing = _kTimingInfo[catId];
              final isMorning = catId == 'morning';
              final readCount = widget.parentState._getTarget(azkar.id, azkar.recommendedCount);
              final String readLabel = readCount == 1
                  ? 'Read once'
                  : 'Read $readCount times';
              return Column(mainAxisSize: MainAxisSize.min, children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(catLabel, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFE8F0FE)],
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
                      child: Text('${ci + 1} / ${widget.azkars.length}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isMorning ? const Color(0xFF0C4A3E) : const Color(0xFF1E1B4B),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                if (timing != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isMorning ? const Color(0xFFFFD700) : const Color(0xFF93C5FD),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(timing,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isMorning ? const Color(0xFFFFD700) : const Color(0xFF93C5FD),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD86B), Color(0xFFF5A623)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF5A623).withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(readLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3B1F00),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ]);
            }
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
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
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _toggleToolbar(),
          child: PageView.builder(
            controller: _pageController,
          onPageChanged: (nextIndex) {
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
                    padding: EdgeInsets.only(top: 0, bottom: 140 + MediaQuery.of(context).padding.bottom),
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
                // ── "Mark as Done" button for read-once azkaar ──
                if (tapTarget <= 1)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 32 + MediaQuery.of(context).padding.bottom),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOutCubic,
                        child: isComplete
                            ? Container(
                                key: const ValueKey('done'),
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFC9A87C), Color(0xFFB8956A)],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                                    const SizedBox(width: 10),
                                    Text('Done',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
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
                                  onTap: () => _tryComplete(azkar, tapTarget, isSwipe: false),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                                          const SizedBox(width: 10),
                                          Text('Mark as Done',
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
                    final safeBottom = MediaQuery.of(context).padding.bottom;
                    final defaultX = screenW / 2 - 55; // center (half of ~110 width)
                    final defaultY = screenH - 130 - safeBottom;
                    final dx = _counterOffset?.dx ?? defaultX;
                    final dy = _counterOffset?.dy ?? defaultY;

                    return Stack(
                      children: [
                        Positioned(
                          left: dx.clamp(0.0, screenW - 110),
                          top: dy.clamp(60.0, screenH - 70),
                          child: GestureDetector(
                            onTap: isComplete ? null : () => _tryComplete(azkar, tapTarget, isSwipe: false),
                            onPanStart: (_) => setState(() => _isDragging = true),
                            onPanEnd: (_) => setState(() => _isDragging = false),
                            onPanCancel: () => setState(() => _isDragging = false),
                            onPanUpdate: (details) {
                              setState(() {
                                _isDragging = true;
                                final cur = _counterOffset ?? Offset(defaultX, defaultY);
                                _counterOffset = Offset(
                                  (cur.dx + details.delta.dx).clamp(0.0, screenW - 110),
                                  (cur.dy + details.delta.dy).clamp(60.0, screenH - 70),
                                );
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: _isDragging ? [
                                  BoxShadow(
                                    color: const Color(0xFF0D9488).withValues(alpha: 0.6),
                                    blurRadius: 28,
                                    spreadRadius: 8,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                                    blurRadius: 50,
                                    spreadRadius: 14,
                                  ),
                                ] : [],
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
      ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arabic text cleaner — strips brackets, parentheses, and Quranic waqf/
// annotation characters that sometimes appear in source data.
// ─────────────────────────────────────────────────────────────────────────────
/// Ayah info for Quranic passages: start ayah number, total ayah count,
/// and whether Bismillah counts as ayah 1 (only true for Al-Fatiha).
typedef _AyahInfo = ({int start, int count, bool bismillahIsAyah});
/// Scaffold bg color matching bottom gradient for each category
Color _scaffoldBgForCategory(String cat) => switch (cat) {
  'morning' => const Color(0xFF0C4A3E),
  'evening' => const Color(0xFF1E1B4B),
  _         => const Color(0xFF065F53),
};

/// Timing info shown at top of azkar detail screen
const Map<String, String> _kTimingInfo = {
  'morning': 'Between Subh-e-Sadiq to Sunrise',
  'evening': 'Between Asr to Maghrib',
};

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
  'morning_9':  (start: 1, count: 4, bismillahIsAyah: false), // Al-Ikhlas
  'evening_9':  (start: 1, count: 4, bismillahIsAyah: false),
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
  s = s.replaceAll(RegExp(r'[\u0615-\u061A\u06D6-\u06DC\u06DE-\u06E4\u06E7-\u06E8\u06EA-\u06ED\u08D4-\u08FE\u200B\uE000-\uF8FF]'), '');
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
String _sectionLabel(_Azkar azkar) {
  return 'Benefit';
}

/// Builds a RichText widget with Bismillah/Isti'adhah in a distinct color.
Widget _buildStyledArabic(String raw, TextStyle baseStyle, Color highlightColor, {String azkarId = '', String fontName = ''}) {
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
  final tightNewline = baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 32) * 0.4, height: 1.0);

  // Splits a text span into pieces, switching style on every ﴿N﴾ marker
  // and rendering '\n' with tightNewline style for reduced vertical gap.
  List<TextSpan> splitMarkers(String text, TextStyle style) {
    final result = <TextSpan>[];
    final re = RegExp(r'﴿[٠-٩]+﴾|\n');
    int last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) {
        result.add(TextSpan(text: text.substring(last, m.start), style: style));
      }
      final matched = m.group(0)!;
      if (matched == '\n') {
        result.add(TextSpan(text: '\n', style: tightNewline));
      } else {
        result.add(TextSpan(text: matched, style: markerStyle.copyWith(color: style.color)));
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

    spans.addAll(splitMarkers('$highlightedText$suffix', baseStyle.copyWith(
      color: highlightColor,
      height: 1.3,
    )));
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
    final isHeader = textString.length < 80 && 
        (textString.contains('بِسْمِ') || 
         textString.contains('أَعُوذُ') || 
         textString.contains('أَعُوْذُ'));
         
    Widget textWidget = Text.rich(
      TextSpan(style: baseStyle, children: blockSpans),
      textAlign: TextAlign.center,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false, 
        applyHeightToLastDescent: false,
      ),
    );

    if (isHeader) {
      return FittedBox(fit: BoxFit.scaleDown, child: textWidget);
    }
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

    String rawRef = azkar.reference.replaceAll('Hisnul Muslim, Chapter: ', '').replaceAll('Hisnul Muslim, ', '').trim();
    String bottomRef = '';
    
    // Parse references at the end, either in brackets/parenthesis OR matching a known Hadith/Quran keyword
    void extractReference(String source, Function(String newSource, String extractedRef) onExtract) {
      if (source.isEmpty) return;
      
      // 1. Check for brackets or parentheses at the end
      final bracketMatch = RegExp(r'(\(|\[)([^\[\(\)\]]+)(\)|\])\s*$').firstMatch(source);
      if (bracketMatch != null) {
        final ref = bracketMatch.group(2)?.trim() ?? '';
        final cleanSource = source.substring(0, bracketMatch.start).replaceAll(RegExp(r'[-—\.,\|\s]+$'), '').trim();
        onExtract(cleanSource, ref);
        return;
      }
      
      // 2. Check for known Hadith keywords
      final keywordMatch = RegExp(r'(?:[-—\.,\s]+|^)((?:Sahih\s)?(?:Muslim|Bukhari|Abu Dawud|Tirmidhi|Ibn Majah|Nasai|Ahmad|Quran|Surah).*)$', caseSensitive: false).firstMatch(source);
      if (keywordMatch != null) {
        final ref = keywordMatch.group(1)?.trim() ?? '';
        final cleanSource = source.substring(0, keywordMatch.start).replaceAll(RegExp(r'[-—\.,\|\s]+$'), '').trim();
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
      cleanReward = clean.replaceAll(RegExp(r'^\|'), '').replaceAll(RegExp(r'\|$'), '').trim();
      if (bottomRef.isEmpty) bottomRef = ref;
    });
    // Strip pipe-separated reference (e.g. "Knower of the Unseen | At-Tirmidhi 3392")
    if (cleanReward.contains('|')) {
      final pipeParts = cleanReward.split('|');
      cleanReward = pipeParts.first.trim();
      final pipedRef = pipeParts.skip(1).join(' ').trim();
      if (bottomRef.isEmpty && pipedRef.isNotEmpty) bottomRef = pipedRef;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Illustration + pts badge overlaid at bottom-right ──
        SizedBox(
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
              ),
              if (pointsToday > 0)
                Positioned(
                  bottom: 10,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                        Icon(Icons.star_rounded, size: 12,
                            color: const Color(0xFFB8860B).withValues(alpha: 0.90)),
                        const SizedBox(width: 4),
                        Text(
                          '+$pointsToday pts',
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

        Builder(builder: (ctx) {
          final tagline = _pickTagline(azkar.id);
          if (tagline.isEmpty) return const SizedBox.shrink();
          final tagColor = _pickTaglineColor(azkar.id, isDark);
          return Container(
            width: double.infinity,
            color: kCardBg,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: isDark ? 0.14 : 0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: tagColor.withValues(alpha: isDark ? 0.45 : 0.30),
                    width: 1.4,
                  ),
                ),
                child: Text(
                  tagline,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w800,
                    color: tagColor,
                    letterSpacing: 0.1,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          );
        }),


        // ── Card section with smooth top transition ──
        Container(
          decoration: BoxDecoration(
            color: kCardBg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

            const SizedBox(height: 16),

            // ── Main Text Content ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildStyledArabic(
                    azkar.arabic,
                    _kArabicFonts[settings.arabicFontIdx.clamp(0, _kArabicFonts.length - 1)]
                        .style(settings.arabicFontSize, kText, 2.2, FontWeight.w700),
                    isDark ? const Color(0xFF5EADDB) : const Color(0xFF1A7A5C),
                    azkarId: azkar.id,
                    fontName: _kArabicFonts[settings.arabicFontIdx.clamp(0, _kArabicFonts.length - 1)].name,
                  ),
                  if (settings.showTransliteration) ...[
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
                  ],
                  if (settings.showTranslation) ...[
                    const SizedBox(height: 6),
                    Text(
                      azkar.translation,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: settings.translationFontSize,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.88)
                            : const Color(0xFF1C1C1E),
                        height: 1.65,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),
            ],
          ),
        ),

        // ══════════════════════════════════════════════════════════════════
        // Unified bottom section — Benefit, Hadith, Reference
        // ══════════════════════════════════════════════════════════════════
        if (cleanReward.isNotEmpty || azkar.hadithFull.isNotEmpty || rawRef.isNotEmpty || bottomRef.isNotEmpty)
          Builder(
            builder: (context) {
              final List<Color> sectionGrad = isDark
                ? [const Color(0xFF1A1A1A), const Color(0xFF1E1E1E)]
                : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)];
              final textColor = isDark ? Colors.white.withValues(alpha: 0.85) : kText;
              final subColor = isDark ? Colors.white.withValues(alpha: 0.55) : kSub.withValues(alpha: 0.90);
              final labelColor = isDark ? const Color(0xFF5EADDB) : const Color(0xFF0D9488);
              final dividerColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

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
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 15, color: labelColor.withValues(alpha: 0.70)),
                        const SizedBox(width: 8),
                        Text(_sectionLabel(azkar),
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: labelColor, letterSpacing: 0.5)),
                      ],
                    ),

                    // ── Virtue/Benefit title ──
                    if (cleanReward.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(cleanReward,
                        style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w600, color: textColor, height: 1.5)),
                    ],

                    // ── Hadith text ──
                    if (azkar.hadithFull.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Container(height: 0.5, color: dividerColor),
                      ),
                      Text(azkar.hadithFull,
                        style: GoogleFonts.outfit(fontSize: 15.5, color: textColor, height: 1.7)),
                    ],

                    // ── Reference ──
                    if (rawRef.isNotEmpty || bottomRef.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            rawRef.isNotEmpty ? rawRef : (bottomRef.isNotEmpty ? bottomRef : azkar.reference),
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor.withValues(alpha: 0.80)),
                          ),
                        ),
                      ),
                    ],
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
  final id = rawId.toLowerCase()
    .replaceFirst('evening_fixed_', 'evening_lwa_');

  // ── New morning/evening IDs (by content) ──
  // Al-Fateha & opening of Baqarah — dua scene
  if (id == 'morning_1' || id == 'morning_2' ||
      id == 'evening_1' || id == 'evening_2') return 'dua_scene';
  // Ayat al-Kursi
  if (id == 'morning_3' || id == 'evening_3') return 'shield';
  // Last verses of Baqarah — protection from evils
  if (id == 'morning_7' || id == 'evening_7' ||
      id == 'morning_8' || id == 'evening_8') return 'repelling';
  // Ikhlas, Falaq, Nas
  if (id == 'morning_9' || id == 'morning_10' || id == 'morning_11' ||
      id == 'evening_9' || id == 'evening_10' || id == 'evening_11') {
    return 'three_quls';
  }
  // Sovereignty & Fitrah — sunrise scene
  if (id == 'morning_12' || id == 'evening_12' ||
      id == 'morning_13' || id == 'evening_13') return 'dawn';
  // By Your Leave
  if (id == 'morning_14' || id == 'evening_14') return 'cycle';
  // Gratitude
  if (id == 'morning_16' || id == 'evening_16') return 'vessel';
  // Raditu billahi — pleased with Allah
  if (id == 'morning_18' || id == 'evening_18') return 'hand';
  // Well-being / Afiyah — 6 direction protection
  if (id == 'morning_19' || id == 'evening_19') return 'six_wards';
  // SubhanAllah 'adada khalqihi — cosmic weight
  if (id == 'morning_20' || id == 'evening_20') return 'cosmic';
  // Bismillah protection — invincible name
  if (id == 'morning_21' || id == 'evening_21') return 'invincible';
  // Perfect words — invincible name
  if (id == 'morning_23' || id == 'evening_23') return 'invincible';
  // Knower of unseen — repelling light
  if (id == 'morning_24' || id == 'evening_24') return 'repelling';
  // Ya Hayyu Ya Qayyum — cradled heart
  if (id == 'morning_25' || id == 'evening_25') return 'heart';
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
  // Durood Ibrahim (evening #32) — ten salawat
  if (id == 'evening_32' || id == 'morning_33') return 'salawat';

  // ── Old IDs (morning_lwa_*, evening_lwa_*, general categories) ──
  if (id == 'morning_lwa_1' || id == 'evening_lwa_1' ||
      id.contains('ayat_kursi') || id.contains('ayat-kursi') ||
      id.contains('ayatul_kursi') || id.contains('ayatul-kursi')) {
    return 'shield';
  }
  if (id == 'morning_lwa_2' || id == 'evening_lwa_2' ||
      id.contains('three_quls') || id.contains('3_quls')) {
    return 'three_quls';
  }
  if (id == 'morning_lwa_3' || id == 'evening_lwa_3' ||
      id.contains('sayyid_istighfar') || id.contains('sayyid-istighfar')) {
    return 'doors';
  }
  if (id == 'morning_lwa_4' || id == 'evening_lwa_4' ||
      id.contains('anxiety') || id.contains('hamm_hazan')) {
    return 'chains';
  }
  if (id == 'morning_lwa_5' || id == 'evening_lwa_5' ||
      id.contains('dua_afiyah') || id.contains('wellbeing')) {
    return 'six_wards';
  }
  if (id == 'morning_lwa_6' || id == 'evening_lwa_6' ||
      id.contains('four_evils') || id.contains('4_evils')) {
    return 'repelling';
  }
  if (id == 'morning_lwa_7' || id == 'evening_lwa_7' ||
      id.contains('entrust') || id.contains('ya_hayyu')) {
    return 'heart';
  }
  if (id == 'morning_lwa_8' || id == 'evening_lwa_8' ||
      id.contains('shukr') || id.contains('gratitude') || id.contains('nimat')) {
    return 'vessel';
  }
  if (id == 'morning_lwa_9' || id == 'evening_lwa_9' ||
      id.contains('fitrah') || id.contains('tawhid')) {
    return 'dawn';
  }
  if (id == 'morning_lwa_10' || id == 'evening_lwa_10' ||
      id.contains('praise_morning') || id.contains('uthni')) {
    return 'ripples';
  }
  if (id == 'morning_lwa_11' || id == 'evening_lwa_11' ||
      id.contains('good_day') || id.contains('khayr_yawm')) {
    return 'path';
  }
  if (id == 'morning_lwa_12' || id == 'evening_lwa_12' ||
      id.contains('bless_day') || id.contains('bless_evening') ||
      id.contains('fath') || id.contains('barakah_yawm')) {
    return 'blessings';
  }
  if (id == 'morning_lwa_13' || id == 'evening_lwa_13' ||
      id.contains('freed_hellfire') || id.contains('ush_hidu')) {
    return 'flame';
  }
  if (id == 'morning_lwa_14' || id == 'evening_lwa_14' ||
      id.contains('bika_asbahna') || id.contains('nushur')) {
    return 'cycle';
  }
  if (id == 'morning_lwa_15' || id == 'evening_lwa_15' ||
      id.contains('afini_badani') || id.contains('good_health')) {
    return 'vessels';
  }
  if (id == 'morning_lwa_16' || id == 'evening_lwa_16' ||
      id.contains('hasbiyallah') || id.contains('arsh_azeem')) {
    return 'pillars';
  }
  if (id == 'morning_lwa_17' || id == 'evening_lwa_17' ||
      id.contains('raditu_billah') || id.contains('pleased_allah')) {
    return 'hand';
  }
  if (id == 'morning_lwa_18' || id == 'evening_lwa_18' ||
      id.contains('la_yadurru') || id.contains('bismillah_protect')) {
    return 'invincible';
  }
  if (id == 'morning_lwa_19' || id == 'evening_lwa_19' ||
      id.contains('subhanallahi_wabihamdih') || id.contains('subhanallahi_wa_bihamdih')) {
    return 'ocean';
  }
  if (id == 'morning_lwa_20' || id == 'evening_lwa_20' ||
      id == 'la_ilaha_illallah' || id == 'post_prayer_la_ilaha' ||
      id.contains('unparalleled_reward')) {
    return 'scales';
  }
  if (id == 'morning_lwa_21' || id == 'evening_lwa_21' ||
      id == 'subhanallah' || id == 'alhamdulillah' || id == 'allahu_akbar' ||
      id == 'post_prayer_subhanallah' || id == 'post_prayer_alhamdulillah' ||
      id == 'post_prayer_allahu_akbar' ||
      id.contains('sleeping_tasbih')) {
    return 'glory';
  }
  if (id == 'morning_lwa_22' || id == 'evening_lwa_22' ||
      id == 'salawat_ibrahimiyya' || id == 'salawat_simple' ||
      id == 'salawat_friday' || id.contains('salawat')) {
    return 'salawat';
  }
  if (id == 'evening_lwa_23' || id.contains('kalimat_taammat')) return 'invincible';
  if (id == 'morning_lwa_23' ||
      id == 'astaghfirullah' || id == 'istighfar_extended' ||
      id.contains('astaghfiru') || id.contains('istighfar') ||
      id.contains('forgive')) {
    return 'doors';
  }
  if (id == 'morning_lwa_24' || id == 'evening_lwa_24' ||
      id.contains('adada_khalqih') || id.contains('cosmic_weight')) {
    return 'cosmic';
  }

  return 'tree'; // Default
}

/// Returns the top gradient color of each illustration to fill behind the app bar.
Color _illustrationTopColor(String azkarId, bool isDark) {
  if (isDark) return const Color(0xFF121212);
  return const Color(0xFFF0F5F2);
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
  final ill = _pickIllustration(azkarId);
  Widget w(Widget Function({required double progress, required bool isComplete, required int tapCount, required int pointsToday}) ctor) =>
    ctor(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday);

  return switch (ill) {
    'dua_scene'  => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _DuaScene(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'shield'     => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _ProtectionShield(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'three_quls' => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _ThreeQuls(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'gates'      => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _GatesOfJannah(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'chains'     => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _BreakingChains(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'six_wards'  => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _SixWards(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'repelling'  => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _RepellingLight(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'heart'      => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _CradledHeart(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'vessel'     => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _OverflowingVessel(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'dawn'       => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _RisingDawn(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'ripples'    => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _PraiseRipples(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'path'       => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _GlowingPath(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'blessings'  => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _FiveBlessings(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'flame'      => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _FreedomFlame(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'cycle'      => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _CycleOfReturn(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'vessels'    => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _ThreeVessels(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'pillars'    => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _SevenPillars(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'hand'       => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _GuidingHand(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'invincible' => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _InvincibleName(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'ocean'      => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _OceanOfForgiveness(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'scales'     => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _UnparalleledScales(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'glory'      => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _SunriseGlory(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'salawat'    => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _TenSalawat(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'doors'      => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _DoorsOfMercy(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    'cosmic'     => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _CosmicWeight(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
    _            => w(({required progress, required isComplete, required tapCount, required pointsToday}) => _NoorTree(progress: progress, isComplete: isComplete, tapCount: tapCount, pointsToday: pointsToday)),
  };
}

// =============================================================================
// Motivational tagline — short punchy benefit line shown inside illustration
// =============================================================================
String _pickTagline(String id) {
  // ── Specific numeric IDs first (most precise) ──
  if (id == 'morning_32' || id == 'evening_31')
    return 'Sins forgiven — even if like the foam of the sea';
  if (id == 'morning_31' || id == 'evening_30')
    return '10 freed · 100 hasanat · 100 sins erased · Shaytan repelled';
  if (id == 'morning_33' || id == 'evening_32')
    return '10 blessings descend from Allah upon you';
  if (id == 'morning_30')
    return 'Ask Allah to bless and beautify your day';
  if (id == 'morning_29' || id == 'evening_29')
    return 'Allah is sufficient for you in every affair';
  if (id == 'morning_28' || id == 'evening_28')
    return "Wellbeing of body, hearing & sight — granted";
  if (id == 'morning_27' || id == 'evening_27')
    return 'Freed from Hellfire every morning & evening';
  if (id == 'morning_26' || id == 'evening_26')
    return 'Guaranteed Jannah — if you die this day';
  if (id == 'morning_25' || id == 'evening_25')
    return 'Your life entrusted to the Ever-Living';
  if (id == 'morning_24' || id == 'evening_24')
    return 'All evil in His creation repelled from you';
  if (id == 'morning_23' || id == 'evening_23')
    return 'Nothing shall harm you — by perfect words';
  if (id == 'morning_21' || id == 'evening_21')
    return 'Complete protection in the name of Allah';
  if (id == 'morning_20' || id == 'evening_20')
    return 'Start surrendered — to Islam, sincerity & truth';

  // ── Illustration-key based fallback ──
  final ill = _pickIllustration(id);
  return switch (ill) {
    'shield'     => 'Guarded by Allah until morning comes',
    'three_quls' => 'Sufficient against every harm recited 3 times',
    'gates'      => 'Doors of Allah mercy open wide for you',
    'chains'     => 'Worry and sorrow lifted by the will of Allah',
    'six_wards'  => 'Guarded in your deen dunya and akhirah',
    'repelling'  => 'Evil repelled from every direction',
    'heart'      => 'Heart held by the Ever Living Ever Sustaining',
    'vessel'     => 'Gratitude that multiplies your blessings',
    'dawn'       => 'Start pure on the fitrah of Islam',
    'ripples'    => 'Praise that ripples through all creation',
    'path'       => 'Guided to every good this day',
    'invincible' => 'Nothing shall harm you by His name',
    'flame'      => 'Freed from Hellfire morning and evening',
    'doors'      => 'Guaranteed Jannah if you die today',
    'vessels'    => 'Wellbeing of body hearing and sight',
    'pillars'    => 'Allah is sufficient in every affair',
    'blessings'  => 'Seeking Allah blessing for a beautiful day',
    'scales'     => 'Ten freed 100 hasanat Shaytan repelled',
    'ocean'      => 'Sins forgiven even if like the foam of the sea',
    'salawat'    => 'Ten blessings from Allah upon you',
    'glory'      => 'Glorified and praised in morning light',
    'cycle'      => 'Return to Allah He is Ever Forgiving',
    'hand'       => 'Guided by the hand of Allah',
    'cosmic'     => 'Words heavier than the heavens and earth',
    'dua_scene'  => 'Begin your day in surrender to Allah',
    _            => '',
  };
}

/// Per-illustration tagline color — distinct for each category, always readable.
Color _pickTaglineColor(String id, bool isDark) {
  final ill = _pickIllustration(id);

  // Light mode: deep saturated tones (dark enough on white bg)
  // Dark mode:  bright vivid tones (light enough on dark bg)
  return switch (ill) {
    'shield'     => isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8), // royal blue
    'three_quls' => isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9), // violet
    'gates'      => isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D), // emerald green
    'chains'     => isDark ? const Color(0xFF34D399) : const Color(0xFF065F46), // deep teal
    'six_wards'  => isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534), // forest green
    'repelling'  => isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B), // deep red
    'heart'      => isDark ? const Color(0xFFF9A8D4) : const Color(0xFF9D174D), // rose/pink
    'vessel'     => isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1), // sky blue
    'dawn'       => isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E), // amber
    'ripples'    => isDark ? const Color(0xFF67E8F9) : const Color(0xFF0E7490), // cyan
    'path'       => isDark ? const Color(0xFF818CF8) : const Color(0xFF3730A3), // indigo
    'invincible' => isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A), // navy
    'flame'      => isDark ? const Color(0xFFFDA4AF) : const Color(0xFF9F1239), // crimson
    'doors'      => isDark ? const Color(0xFFC4B5FD) : const Color(0xFF5B21B6), // purple
    'vessels'    => isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E), // teal
    'pillars'    => isDark ? const Color(0xFFD8B4FE) : const Color(0xFF7E22CE), // deep violet
    'blessings'  => isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E), // golden amber
    'scales'     => isDark ? const Color(0xFF86EFAC) : const Color(0xFF14532D), // forest
    'ocean'      => isDark ? const Color(0xFF38BDF8) : const Color(0xFF075985), // ocean blue
    'salawat'    => isDark ? const Color(0xFFFDA4AF) : const Color(0xFF881337), // deep rose
    'glory'      => isDark ? const Color(0xFFFCD34D) : const Color(0xFF713F12), // golden
    'cycle'      => isDark ? const Color(0xFFA3E635) : const Color(0xFF3F6212), // lime green
    'hand'       => isDark ? const Color(0xFF6EE7B7) : const Color(0xFF134E4A), // teal-green
    'cosmic'     => isDark ? const Color(0xFFBAFA60) : const Color(0xFF1E1B4B), // deep indigo
    'dua_scene'  => isDark ? const Color(0xFFA7F3D0) : const Color(0xFF064E3B), // deep green
    _            => isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
  };
}

/// Arabic calligraphy text style used inside illustration canvases.
TextStyle _illusArabic(double size, Color color, {FontWeight weight = FontWeight.w700}) =>
    GoogleFonts.amiri(fontSize: size, color: color, fontWeight: weight, height: 1.4);

/// Small Arabic tag style for phase/reward markers inside illustrations.
TextStyle _illusTag(double size, Color color) =>
    GoogleFonts.amiri(fontSize: size, color: color, fontWeight: FontWeight.w700, height: 1.3);

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
  final List<_Particle> _particles = List.generate(15, (i) => _Particle(seed: i + 500));

  @override
  void initState() {
    super.initState();
    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _punchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _punch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.98).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _pCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
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
      for (final p in _particles) { p.reset(); }
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
      animation: Listenable.merge([_growCtrl, _pulseCtrl, _punchCtrl, _shockCtrl, _pCtrl]),
      builder: (_, __) => SizedBox(
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
            Color.fromRGBO((255 - warmth * 10).round(), (248 - warmth * 5).round(), (225 + warmth * 10).round(), 1.0),
            Color.fromRGBO((245 - warmth * 8).round(), (240 - warmth * 5).round(), (215 + warmth * 12).round(), 1.0),
            Color.fromRGBO((230 + warmth * 15).round(), (225 + warmth * 10).round(), (200 + warmth * 20).round(), 1.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    final groundY = h * 0.72;

    // ── 2. Sun ──
    final sunCy = h * 0.18;
    final sunR = 22 + progress * 8;
    final sunAlpha = 0.40 + progress * 0.40;
    // Corona
    canvas.drawCircle(Offset(cx, sunCy), sunR + 18, Paint()
      ..color = Color.fromRGBO(255, 220, 100, sunAlpha * 0.12 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    // Sun disc
    canvas.drawCircle(Offset(cx, sunCy), sunR, Paint()
      ..shader = RadialGradient(colors: [
        Color.fromRGBO(255, 255, 240, sunAlpha),
        Color.fromRGBO(255, 230, 150, sunAlpha * 0.9),
        Color.fromRGBO(255, 200, 80, sunAlpha * 0.6),
      ], stops: const [0.0, 0.5, 1.0])
      .createShader(Rect.fromCircle(center: Offset(cx, sunCy), radius: sunR)));
    // Bright core
    canvas.drawCircle(Offset(cx, sunCy), sunR * 0.4, Paint()
      ..color = Colors.white.withValues(alpha: sunAlpha * 0.65));
    // Sun rays
    if (progress > 0.1) {
      final rayA = progress * 0.15;
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi * 2 / 8;
        final sx = cx + math.cos(angle) * (sunR + 4);
        final sy = sunCy + math.sin(angle) * (sunR + 4);
        final ex = cx + math.cos(angle) * (sunR + 20 + progress * 12);
        final ey = sunCy + math.sin(angle) * (sunR + 20 + progress * 12);
        canvas.drawLine(Offset(sx, sy), Offset(ex, ey), Paint()
          ..color = Color.fromRGBO(255, 220, 120, rayA)
          ..strokeWidth = i.isEven ? 2.0 : 1.2
          ..strokeCap = StrokeCap.round);
      }
    }

    // ── 3. Mountains ──
    final mtColor1 = Color.lerp(const Color(0xFFB8C5D0), const Color(0xFFA8C0A8), progress)!;
    final mtColor2 = Color.lerp(const Color(0xFFC5CDD5), const Color(0xFFB5CCB5), progress)!;

    // Back mountain (larger, lighter)
    final mt1 = Path()
      ..moveTo(0, groundY)
      ..lineTo(w * 0.10, groundY)
      ..quadraticBezierTo(w * 0.20, groundY - 55, w * 0.35, groundY - 70)
      ..quadraticBezierTo(w * 0.42, groundY - 75, w * 0.50, groundY - 60)
      ..quadraticBezierTo(w * 0.58, groundY - 50, w * 0.65, groundY)
      ..close();
    canvas.drawPath(mt1, Paint()..color = mtColor2.withValues(alpha: 0.70));

    // Front mountain (smaller, darker)
    final mt2 = Path()
      ..moveTo(w * 0.35, groundY)
      ..quadraticBezierTo(w * 0.50, groundY - 45, w * 0.62, groundY - 55)
      ..quadraticBezierTo(w * 0.70, groundY - 60, w * 0.78, groundY - 45)
      ..quadraticBezierTo(w * 0.88, groundY - 25, w, groundY)
      ..close();
    canvas.drawPath(mt2, Paint()..color = mtColor1.withValues(alpha: 0.75));

    // ── 4. Ground ──
    final groundPath = Path()
      ..moveTo(0, groundY)
      ..quadraticBezierTo(w * 0.25, groundY - 3, w * 0.5, groundY)
      ..quadraticBezierTo(w * 0.75, groundY + 3, w, groundY)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final groundColor = Color.lerp(const Color(0xFFD5C8B0), const Color(0xFFC8D8B8), progress)!;
    canvas.drawPath(groundPath, Paint()..color = groundColor.withValues(alpha: 0.55));

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
    final leafColor = isComplete
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
      final bp = Paint()
        ..color = trunkColor.withValues(alpha: trunkAlpha * branchA)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(tx, trunkTop + trunkH * 0.25), Offset(tx - 22 * branchA, trunkTop + trunkH * 0.08), bp);
      canvas.drawLine(Offset(tx, trunkTop + trunkH * 0.35), Offset(tx + 24 * branchA, trunkTop + trunkH * 0.12), bp);
      canvas.drawLine(Offset(tx, trunkTop + trunkH * 0.48), Offset(tx - 18 * branchA, trunkTop + trunkH * 0.30), bp);
      canvas.drawLine(Offset(tx, trunkTop + trunkH * 0.58), Offset(tx + 16 * branchA, trunkTop + trunkH * 0.40), bp);
    }

    // Leaf canopy — bigger, lush overlapping ovals
    if (progress > 0.15) {
      final canopyA = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
      final lp = Paint()..color = leafColor.withValues(alpha: canopyA * leafColor.a);

      canvas.drawOval(Rect.fromCenter(center: Offset(tx, trunkTop - 8), width: 50 * canopyA, height: 38 * canopyA), lp);
      canvas.drawOval(Rect.fromCenter(center: Offset(tx - 16, trunkTop + 4), width: 35 * canopyA, height: 28 * canopyA), lp);
      canvas.drawOval(Rect.fromCenter(center: Offset(tx + 14, trunkTop + 2), width: 38 * canopyA, height: 26 * canopyA), lp);
      canvas.drawOval(Rect.fromCenter(center: Offset(tx - 8, trunkTop - 16), width: 30 * canopyA, height: 22 * canopyA), lp);
      canvas.drawOval(Rect.fromCenter(center: Offset(tx + 8, trunkTop - 14), width: 28 * canopyA, height: 20 * canopyA), lp);

      // Highlight
      canvas.drawOval(
        Rect.fromCenter(center: Offset(tx - 5, trunkTop - 12), width: 16 * canopyA, height: 12 * canopyA),
        Paint()..color = Colors.white.withValues(alpha: canopyA * 0.12));
    }
  }

  /// Person kneeling in side-profile dua pose (facing right, like reference)
  void _drawDuaPerson(Canvas canvas, double px, double groundY, double progress) {
    final alpha = 0.70 + progress * 0.25;
    // Thobe/garment: teal-green like reference
    final garmentColor = isComplete
        ? Color.fromRGBO(60, 130, 70, alpha)
        : Color.fromRGBO(55, 125, 100, alpha);
    // Skin tone
    final skinColor = Color.fromRGBO(220, 190, 160, alpha);
    final skinFill = Paint()..color = skinColor;
    final garmentFill = Paint()..color = garmentColor;
    final glowColor = isComplete ? const Color(0xFFD4AF37) : const Color(0xFF4A90D9);

    final baseY = groundY - 2;

    // Subtle glow behind person
    canvas.drawOval(
      Rect.fromCenter(center: Offset(px + 5, baseY - 28), width: 55, height: 60),
      Paint()
        ..color = glowColor.withValues(alpha: alpha * 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // ── Prayer mat (thin dark rectangle) ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(px + 2, baseY + 1), width: 50, height: 4),
        const Radius.circular(2),
      ),
      Paint()..color = Color.fromRGBO(80, 65, 50, alpha * 0.50),
    );

    // ── Kneeling lower body (longer thighs, side view) ──
    final kneeY = baseY - 2;
    // Thighs are longer — hip sits higher, knees extend further forward
    final lowerPath = Path()
      ..moveTo(px - 8, kneeY)         // back of seated area
      ..quadraticBezierTo(px - 14, kneeY - 14, px - 2, kneeY - 14) // smooth round hip
      ..lineTo(px + 12, kneeY - 14)    // across thigh
      ..quadraticBezierTo(px + 22, kneeY - 12, px + 22, kneeY - 4) // smooth round knee
      ..quadraticBezierTo(px + 20, kneeY + 2, px + 12, kneeY + 2)   // shin
      ..lineTo(px - 6, kneeY + 2)     // across bottom
      ..quadraticBezierTo(px - 10, kneeY + 1, px - 10, kneeY)
      ..close();
    canvas.drawPath(lowerPath, garmentFill);

    // ── Torso (shorter abdomen — side profile) ──
    final torsoTop = baseY - 42;
    final hipY = kneeY - 14;
    final torsoPath = Path()
      ..moveTo(px - 5, hipY)           // back hip
      ..quadraticBezierTo(px - 6, torsoTop + 10, px - 3, torsoTop + 2) // back curves up (shorter)
      ..quadraticBezierTo(px, torsoTop - 2, px + 6, torsoTop)          // shoulder top
      ..quadraticBezierTo(px + 12, torsoTop + 2, px + 14, torsoTop + 7) // front shoulder
      ..lineTo(px + 11, hipY)          // front waist
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
      math.pi * 0.8, math.pi * 1.0, false,
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

    final armPaint = Paint()
      ..color = skinColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Upper arm from shoulder forward
    final armPath = Path()
      ..moveTo(shoulderX, shoulderY)
      ..quadraticBezierTo(shoulderX + 8, shoulderY - 6, handX - 2, handY + 8)
      ..quadraticBezierTo(handX, handY + 4, handX, handY);
    canvas.drawPath(armPath, armPaint);

    // Second arm slightly behind (partially visible)
    final arm2Path = Path()
      ..moveTo(shoulderX - 2, shoulderY + 2)
      ..quadraticBezierTo(shoulderX + 5, shoulderY - 4, handX - 3, handY + 9)
      ..quadraticBezierTo(handX - 1, handY + 5, handX - 1, handY + 1);
    canvas.drawPath(arm2Path, Paint()
      ..color = skinColor.withValues(alpha: alpha * 0.75)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke);

    // Hands together (palms pressed in dua)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(handX, handY + 1), width: 6, height: 9),
      skinFill);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(handX - 1.5, handY + 1), width: 5, height: 8),
      Paint()..color = skinColor.withValues(alpha: alpha * 0.80));

    // ── Dua noor (light rising from hands) ──
    if (progress > 0.15) {
      final noorA = ((progress - 0.15) / 0.85).clamp(0.0, 1.0) * 0.25;
      // Small v-shaped lines above hands (like birds/breath in reference)
      for (int i = 0; i < 3; i++) {
        final ny = handY - 10 - i * 8;
        final nSize = 4.0 + i * 1.5;
        final na = noorA * (1.0 - i * 0.25) * pulse;
        canvas.drawLine(
          Offset(handX - nSize, ny + 3), Offset(handX, ny),
          Paint()..color = glowColor.withValues(alpha: na)..strokeWidth = 1.2..strokeCap = StrokeCap.round);
        canvas.drawLine(
          Offset(handX + nSize, ny + 3), Offset(handX, ny),
          Paint()..color = glowColor.withValues(alpha: na)..strokeWidth = 1.2..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(_DuaScenePainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.isComplete != isComplete || o.pointsToday != pointsToday ||
      o.punchScale != punchScale || o.shockPhase != shockPhase ||
      o.particlePhase != particlePhase;
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

    _swayCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))
      ..repeat(reverse: true);
    _sway = Tween<double>(begin: -1.0, end: 1.0)
        .animate(CurvedAnimation(parent: _swayCtrl, curve: Curves.easeInOut));

    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;

    _starCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat(reverse: true);

    _pCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.94, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _punchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _punch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.98).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_punchCtrl);

    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);

    _shootCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
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
          Color.fromRGBO((240 - warmth * 15).round(), (245 - warmth * 10).round(), (242 - warmth * 8).round(), 1.0),
          Color.fromRGBO((235 - warmth * 20).round(), (240 - warmth * 12).round(), (238 - warmth * 10).round(), 1.0),
          Color.fromRGBO((228 - warmth * 25).round(), (234 - warmth * 15).round(), (230 - warmth * 12).round(), 1.0),
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
      (0.08, 0.06), (0.18, 0.14), (0.32, 0.04), (0.55, 0.09),
      (0.71, 0.05), (0.84, 0.15), (0.92, 0.07), (0.45, 0.18),
      (0.63, 0.22), (0.25, 0.20), (0.77, 0.18), (0.12, 0.27),
      (0.90, 0.25), (0.38, 0.29), (0.59, 0.33),
    ];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.7);
      sp.color = Colors.white.withValues(alpha: 0.15 + 0.35 * tw);
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

    // 3. Crescent moon (proper path — no dark masking circle)
    final moonA = progress.clamp(0.05, 1.0);
    const moonX = 0.83;
    const moonY = 0.13;
    const moonR = 13.0;
    final mCx = moonX * w;
    final mCy = moonY * h;
    // Glow behind crescent
    canvas.drawCircle(
      Offset(mCx, mCy), moonR + 6,
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: moonA * 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    // Crescent via path difference (outer circle minus inner offset circle)
    final outerPath = Path()..addOval(Rect.fromCircle(center: Offset(mCx, mCy), radius: moonR));
    final innerPath = Path()..addOval(Rect.fromCircle(center: Offset(mCx + moonR * 0.55, mCy - moonR * 0.1), radius: moonR * 0.9));
    final crescentPath = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(crescentPath, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: moonA * 0.85));

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
      if (pTree > 0.15) {
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
      if (pTree > 0.15) {
        _drawBranches(canvas, trunkBot, trunkTop, sway, pTree,
          Paint()..color = const Color(0xFF6B4A2A)..strokeWidth = trunkW * 0.35..strokeCap = StrokeCap.round);
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
        if (pTree < minP) continue;
        final leafA = ((pTree - minP) / 0.10).clamp(0.0, 1.0);
        final leafPos = Offset(
          treeTop.dx + rx * halfW,
          treeTop.dy + ry * trunkH * 0.55,
        );
        final leafR = r * (0.65 + pTree * 0.35) * (isComplete ? pulse : 1.0);
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
    // tap-effect removed — smooth calm

    // 8. Floating noor particles — with trails
    // tap-effect removed — smooth calm

    // 9. Progress label
    // progress % label removed

    // 10. Noor points badge
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
    final personColor = isComplete
        ? Color.fromRGBO(190, 155, 30, baseAlpha)
        : Color.fromRGBO(75, 130, 190, baseAlpha);
    final glowColor = isComplete
        ? const Color(0xFFD4AF37).withValues(alpha: 0.16)
        : const Color(0xFF4A90D9).withValues(alpha: 0.12);

    final fill = Paint()..color = personColor;

    final baseY = groundY - 3;
    const headR = 7.5;
    final headCy = baseY - 62;

    // ── Glow behind ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY - 32), width: 40, height: 68),
      Paint()..color = glowColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // ── Head ──
    canvas.drawCircle(Offset(cx, headCy), headR, fill);

    // ── Neck ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, headCy + headR + 2.5), width: 5, height: 5),
        const Radius.circular(2),
      ),
      fill,
    );

    // ── Body (long thobe — single smooth shape from shoulders to feet) ──
    final shoulderY = headCy + headR + 5;
    final hemY = baseY - 1;

    final robePath = Path()
      ..moveTo(cx, shoulderY - 2)                                        // neckline center
      ..quadraticBezierTo(cx - 14, shoulderY, cx - 13, shoulderY + 6)   // left shoulder
      ..quadraticBezierTo(cx - 12, (shoulderY + hemY) * 0.45, cx - 10, hemY * 0.65 + shoulderY * 0.35) // left waist
      ..quadraticBezierTo(cx - 11, hemY - 8, cx - 14, hemY)             // left hem flare
      ..lineTo(cx + 14, hemY)                                            // across bottom
      ..quadraticBezierTo(cx + 11, hemY - 8, cx + 10, hemY * 0.65 + shoulderY * 0.35) // right waist
      ..quadraticBezierTo(cx + 12, (shoulderY + hemY) * 0.45, cx + 13, shoulderY + 6) // right shoulder
      ..quadraticBezierTo(cx + 14, shoulderY, cx, shoulderY - 2)         // back to neckline
      ..close();
    canvas.drawPath(robePath, fill);

    // Center fold line
    canvas.drawLine(
      Offset(cx, shoulderY + 4), Offset(cx, hemY - 3),
      Paint()..color = Colors.white.withValues(alpha: baseAlpha * 0.10)..strokeWidth = 0.6,
    );

    // ── Arms at sides (simple straight lines, relaxed) ──
    final armPaint = Paint()
      ..color = personColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(cx - 13, shoulderY + 5), Offset(cx - 12, shoulderY + 28), armPaint);
    canvas.drawLine(Offset(cx + 13, shoulderY + 5), Offset(cx + 12, shoulderY + 28), armPaint);

    // ── Feet (small) ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 6, hemY + 2), width: 8, height: 3), fill);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 6, hemY + 2), width: 8, height: 3), fill);
  }

  /// Large shield shape positioned in front of the person
  void _drawShieldDome(
      Canvas canvas, double cx, double cy, double w, double h, double groundY) {
    final personCy = groundY - 34;
    final baseColor = isComplete ? const Color(0xFFD4AF37) : const Color(0xFF4A90D9);
    final appear = progress.clamp(0.0, 1.0);

    // Shield dimensions — covers most of the person
    final shieldW = w * 0.22 * appear;
    final shieldH = (groundY - personCy + 20) * 0.85 * appear;
    final shieldCy = personCy + 2;

    // Glow behind shield
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, shieldCy), width: shieldW * 2.5, height: shieldH * 1.6),
      Paint()
        ..color = baseColor.withValues(alpha: appear * 0.08 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // Shield shape — pointed top, wide middle, pointed bottom
    final shieldPath = Path()
      ..moveTo(cx, shieldCy - shieldH * 0.52)                                    // top point
      ..quadraticBezierTo(cx + shieldW * 1.1, shieldCy - shieldH * 0.30, cx + shieldW, shieldCy) // right top curve
      ..quadraticBezierTo(cx + shieldW * 0.9, shieldCy + shieldH * 0.30, cx, shieldCy + shieldH * 0.52) // right bottom to point
      ..quadraticBezierTo(cx - shieldW * 0.9, shieldCy + shieldH * 0.30, cx - shieldW, shieldCy) // left bottom curve
      ..quadraticBezierTo(cx - shieldW * 1.1, shieldCy - shieldH * 0.30, cx, shieldCy - shieldH * 0.52) // left top back to top
      ..close();

    // Shield fill — gradient
    final fillAlpha = appear * (isComplete ? 0.35 : 0.20);
    canvas.drawPath(shieldPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [
          baseColor.withValues(alpha: fillAlpha * 1.2),
          baseColor.withValues(alpha: fillAlpha * 0.6),
          baseColor.withValues(alpha: fillAlpha * 0.3),
        ],
      ).createShader(Rect.fromCenter(center: Offset(cx, shieldCy), width: shieldW * 2, height: shieldH)));

    // Shield border — thick and prominent
    final borderAlpha = appear * (isComplete ? 0.80 : 0.60);
    canvas.drawPath(shieldPath, Paint()
      ..color = baseColor.withValues(alpha: borderAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isComplete ? 3.5 : 2.5
      ..strokeCap = StrokeCap.round);

    // Inner shield decoration — smaller shield outline inside
    if (appear > 0.4) {
      final innerA = ((appear - 0.4) / 0.6).clamp(0.0, 1.0);
      final iw = shieldW * 0.65;
      final ih = shieldH * 0.65;
      final innerPath = Path()
        ..moveTo(cx, shieldCy - ih * 0.52)
        ..quadraticBezierTo(cx + iw * 1.1, shieldCy - ih * 0.30, cx + iw, shieldCy)
        ..quadraticBezierTo(cx + iw * 0.9, shieldCy + ih * 0.30, cx, shieldCy + ih * 0.52)
        ..quadraticBezierTo(cx - iw * 0.9, shieldCy + ih * 0.30, cx - iw, shieldCy)
        ..quadraticBezierTo(cx - iw * 1.1, shieldCy - ih * 0.30, cx, shieldCy - ih * 0.52)
        ..close();
      canvas.drawPath(innerPath, Paint()
        ..color = baseColor.withValues(alpha: innerA * borderAlpha * 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
    }

    // Center emblem — small circle with dot
    if (appear > 0.3) {
      final emblemA = ((appear - 0.3) / 0.7).clamp(0.0, 1.0) * borderAlpha;
      canvas.drawCircle(Offset(cx, shieldCy), 6, Paint()
        ..color = baseColor.withValues(alpha: emblemA * 0.30)
        ..style = PaintingStyle.stroke..strokeWidth = 1.5);
      canvas.drawCircle(Offset(cx, shieldCy), 2.5, Paint()
        ..color = baseColor.withValues(alpha: emblemA * 0.50));
    }

    // Completion glow
    if (isComplete) {
      final haloAlpha = 0.12 * pulse;
      canvas.drawPath(shieldPath, Paint()
        ..color = baseColor.withValues(alpha: haloAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
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
        Offset(mx, my), 5.0,
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: mAlpha * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        Offset(mx, my), 2.5,
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
    final bookColor = isComplete
        ? Color.fromRGBO(212, 175, 55, bookAlpha)
        : Color.fromRGBO(200, 200, 220, bookAlpha);
    final glowAlpha = isComplete ? 0.15 : 0.08;

    // Glow behind book
    canvas.drawCircle(
      Offset(cx, cy), 38,
      Paint()
        ..color = (isComplete ? const Color(0xFFD4AF37) : const Color(0xFF8B5CF6))
            .withValues(alpha: glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // Open book shape — two pages (scaled up ~1.8x)
    final bookPaint = Paint()
      ..color = bookColor
      ..style = PaintingStyle.fill;

    // Left page
    final leftPage = Path()
      ..moveTo(cx - 2, cy - 18)
      ..quadraticBezierTo(cx - 25, cy - 22, cx - 28, cy - 10)
      ..lineTo(cx - 27, cy + 14)
      ..quadraticBezierTo(cx - 23, cy + 18, cx - 2, cy + 16)
      ..close();
    canvas.drawPath(leftPage, bookPaint);

    // Right page
    final rightPage = Path()
      ..moveTo(cx + 2, cy - 18)
      ..quadraticBezierTo(cx + 25, cy - 22, cx + 28, cy - 10)
      ..lineTo(cx + 27, cy + 14)
      ..quadraticBezierTo(cx + 23, cy + 18, cx + 2, cy + 16)
      ..close();
    canvas.drawPath(rightPage, bookPaint);

    // Spine
    canvas.drawLine(
      Offset(cx, cy - 20), Offset(cx, cy + 17),
      Paint()
        ..color = bookColor
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Page lines (subtle text lines)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: bookAlpha * 0.40)
      ..strokeWidth = 0.7;
    for (int i = 0; i < 5; i++) {
      final ly = cy - 10 + i * 5.0;
      canvas.drawLine(Offset(cx - 22, ly), Offset(cx - 5, ly), linePaint);
      canvas.drawLine(Offset(cx + 5, ly), Offset(cx + 22, ly), linePaint);
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
        math.pi, sweep, false,
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
  void _drawInnerLight(Canvas canvas, double cx, double groundY, double w, double h) {
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
    final gateH = 85.0;
    final gateW = 28.0;
    final gateTop = groundY - gateH;

    // Opening angle: 0 (closed) → progress-based swing outward
    final openAmount = progress * gateW * 0.9;

    final gateColor = isComplete
        ? const Color(0xFFD4AF37).withValues(alpha: 0.92)
        : Color.lerp(const Color(0xFFC5A044), const Color(0xFFD4AF37), progress)!.withValues(alpha: 0.85);
    final gateEdge = isComplete
        ? const Color(0xFFB8962E).withValues(alpha: 0.80)
        : const Color(0xFFA08030).withValues(alpha: 0.65);
    final decorColor = isComplete
        ? const Color(0xFFE8C860).withValues(alpha: 0.70)
        : const Color(0xFFBFA050).withValues(alpha: 0.50);

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
    final capColor = isComplete
        ? const Color(0xFFFFD97D).withValues(alpha: 0.80)
        : const Color(0xFFD4AF37).withValues(alpha: 0.70);
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
    final gateH = 85.0;
    final gateW = 28.0;
    final openAmount = progress * gateW * 0.9;
    final archTop = groundY - gateH - 22;
    final archLeft = cx - gateW - openAmount - 8;
    final archRight = cx + gateW + openAmount + 8;
    final archMidY = groundY - gateH - 4;

    final archColor = isComplete
        ? Color.fromRGBO(212, 175, 55, archAlpha * 0.85)
        : Color.fromRGBO(196, 160, 50, archAlpha * 0.75);

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
    _paintLightBg(canvas, w, h, progress: progress);

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
      final borderA = wardProgress * (isComplete ? 0.80 : 0.60);
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

      // Direction label removed
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

    // 7. Progress label
    // progress % label removed
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
    final shake = progress > 0.3 ? math.sin(driftPhase * math.pi * 8) * progress * 3 : 0.0;

    for (int side = 0; side < 2; side++) {
      final ex = side == 0 ? cx - eyeSpacing + shake : cx + eyeSpacing + shake;
      final mirror = side == 0 ? 1.0 : -1.0;

      // Thick smoky aura behind each eye
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, eyeY), width: eyeW * 3.5, height: eyeH * 3.5),
        Paint()
          ..color = const Color(0xFF3A0000).withValues(alpha: evilAlpha * 0.40)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );

      // Eye shape — elegant, smooth almond
      final eyePath = Path()
        ..moveTo(ex - eyeW * 1.1, eyeY)
        ..quadraticBezierTo(ex, eyeY - eyeH * 1.3, ex + eyeW * 1.1, eyeY)
        ..quadraticBezierTo(ex, eyeY + eyeH * 1.3, ex - eyeW * 1.1, eyeY)
        ..close();

      // Deep fiery golden-red radial gradient 
      canvas.drawPath(eyePath, Paint()
        ..shader = RadialGradient(colors: [
          Color.fromRGBO(255, 140, 40, evilAlpha * 0.95), // Bright inner fire
          Color.fromRGBO(190, 10, 10, evilAlpha * 0.85),  // Deep blood red
          Color.fromRGBO(40, 0, 0, evilAlpha * 0.70),     // Dark edges
        ], stops: const [0.15, 0.5, 1.0])
        .createShader(Rect.fromCenter(center: Offset(ex, eyeY), width: eyeW * 2.2, height: eyeH * 2.2)));

      // Outer rim
      canvas.drawPath(eyePath, Paint()
        ..color = Color.fromRGBO(30, 0, 0, evilAlpha * 0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0);

      // Elegant diamond-slit pupil
      final pupilPath = Path()
        ..moveTo(ex + eyeW * 0.05, eyeY - eyeH * 0.8)
        ..quadraticBezierTo(ex + eyeW * 0.25, eyeY, ex + eyeW * 0.05, eyeY + eyeH * 0.8)
        ..quadraticBezierTo(ex - eyeW * 0.15, eyeY, ex + eyeW * 0.05, eyeY - eyeH * 0.8)
        ..close();
      
      canvas.drawPath(pupilPath, Paint()
        ..color = Color.fromRGBO(15, 0, 0, evilAlpha * 0.95));

      // Soft white glint (spark of menace)
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex + eyeW * 0.3, eyeY - eyeH * 0.35), width: eyeW * 0.25, height: eyeH * 0.25),
        Paint()
          ..color = Colors.white.withValues(alpha: evilAlpha * 0.65)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
      );

      // ── Crack lines (appear as progress > 0.2, get more severe) ──
      if (progress > 0.2) {
        final crackIntensity = ((progress - 0.2) / 0.8).clamp(0.0, 1.0);
        final crackPaint = Paint()
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
          canvas.drawCircle(Offset(fx, fy), fragSize * (1.0 - shatterT * 0.5),
            Paint()..color = Color.fromRGBO(150, 20, 20, fragA));
          // Bright edge on fragment
          canvas.drawCircle(Offset(fx, fy), fragSize * 0.3 * (1.0 - shatterT),
            Paint()..color = Color.fromRGBO(255, 200, 100, fragA * 0.5));
        }
      }
    }
  }

  /// Central divine light that grows as shadows retreat
  void _drawCentralLight(Canvas canvas, double cx, double cy, double w) {
    final lightR = 14 + progress * 35;
    final alpha = progress * (isComplete ? 0.55 : 0.35) * pulse;

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
    final color = isComplete
        ? const Color(0xFFD4AF37)
        : const Color(0xFFE879F9);

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
        Rect.fromCenter(center: Offset(cx, shelterCy), width: r * 2, height: r * 1.8),
        0, math.pi * appear, false,
        Paint()
          ..color = color.withValues(alpha: layerAlpha * 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW + 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Main shelter arc — semicircle opening upward (U-shape cradle)
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, shelterCy), width: r * 2, height: r * 1.8),
        0, math.pi * appear, false,
        Paint()
          ..color = color.withValues(alpha: layerAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }

    // Ground line connecting the dome feet
    if (progress > 0.3) {
      final groundAlpha = ((progress - 0.3) / 0.7).clamp(0.0, 1.0) * alpha * 0.25;
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
        final dotAlpha = isComplete ? 0.60 : 0.40;

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
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
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
        height: 290,
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
    _paintLightBg(canvas, w, h, progress: progress);

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

    final vesselColor = isComplete
        ? const Color(0xFFD4AF37).withValues(alpha: 0.75)
        : const Color(0xFF8B7355).withValues(alpha: 0.65);
    final rimColor = isComplete
        ? const Color(0xFFFFD97D).withValues(alpha: 0.80)
        : const Color(0xFFB8976A).withValues(alpha: 0.60);

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
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
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
        height: 290,
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

    // 1. Sky gradient — warm sunrise palette (golden-yellow top, amber-orange bottom)
    final dawn = progress;
    final skyTop = Color.lerp(
      const Color(0xFFFFF8E1), const Color(0xFFFFF3C4), dawn)!;
    final skyMid = Color.lerp(
      const Color(0xFFFFECB3), const Color(0xFFFFD54F), dawn)!;
    final skyBot = Color.lerp(
      const Color(0xFFFFCC80), const Color(0xFFFB8C00), dawn)!;
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
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(const Color(0xFFE6A050), const Color(0xFFF5B041), dawn)!,
          Color.lerp(const Color(0xFFD4813A), const Color(0xFFEB984E), dawn)!,
        ],
      ).createShader(Rect.fromLTWH(0, horizonY, w, h - horizonY)));

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
        Rect.fromCenter(center: Offset(cx, horizonY), width: w * 0.9, height: 40 * progress),
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
  void _drawSun(Canvas canvas, double cx, double sunCy, double horizonY, double w) {
    final sunR = 28 + progress * 12;
    final sunAlpha = (0.30 + progress * 0.60).clamp(0.0, 0.90);

    // Outer corona (wide warm glow)
    canvas.drawCircle(Offset(cx, sunCy), sunR + 28, Paint()
      ..color = Color.fromRGBO(255, 220, 100, sunAlpha * 0.12 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28));

    // Mid corona
    canvas.drawCircle(Offset(cx, sunCy), sunR + 12, Paint()
      ..color = Color.fromRGBO(255, 200, 80, sunAlpha * 0.20 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));

    // Sun disc — mostly white/cream like reference image
    canvas.drawCircle(Offset(cx, sunCy), sunR * (isComplete ? pulse : 1.0), Paint()
      ..shader = RadialGradient(colors: [
        Color.fromRGBO(255, 255, 245, sunAlpha),
        Color.fromRGBO(255, 245, 210, sunAlpha),
        Color.fromRGBO(255, 220, 130, sunAlpha * 0.8),
      ], stops: const [0.0, 0.55, 1.0])
      .createShader(Rect.fromCircle(center: Offset(cx, sunCy), radius: sunR)));

    // Bright white core
    canvas.drawCircle(Offset(cx, sunCy), sunR * 0.45, Paint()
      ..color = Colors.white.withValues(alpha: sunAlpha * 0.80));
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
    final silColor = Color.lerp(
      const Color(0xFFCC7A30), const Color(0xFFE8A040), dawn)!.withValues(alpha: 0.70);

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

  /// Brownish trees scattered on the hills
  void _drawHillTrees(Canvas canvas, double w, double horizonY, double dawn) {
    final treeColor = Color.lerp(
      const Color(0xFFA06830), const Color(0xFFBB8040), dawn)!;
    final leafColor = Color.lerp(
      const Color(0xFF8B6530), const Color(0xFFA07838), dawn)!;

    // Tree positions: (x fraction, height, trunk width)
    const trees = [
      (0.08, 22.0, 3.0), (0.18, 18.0, 2.5), (0.28, 25.0, 3.5),
      (0.72, 20.0, 3.0), (0.82, 26.0, 3.5), (0.92, 16.0, 2.5),
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
        Rect.fromCenter(center: Offset(tx, trunkTop - 4), width: th * 0.7, height: th * 0.55),
        Paint()..color = leafColor.withValues(alpha: 0.60),
      );
    }
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
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
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
        height: 290,
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
    _paintLightBg(canvas, w, h, progress: progress);

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
    required this.progress, required this.isComplete,
    required this.tapCount, this.pointsToday = 0,
  });

  @override
  State<_FiveBlessings> createState() => _FiveBlessingsState();
}

class _FiveBlessingsState extends State<_FiveBlessings> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _starCtrl, _birdCtrl, _glowCtrl;
  late Animation<double> _pulse, _grow;
  double _prevProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress; _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))..repeat(reverse: true);
    _birdCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))..repeat();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
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
    _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose();
    _birdCtrl.dispose(); _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _starCtrl, _birdCtrl, _glowCtrl]),
      builder: (_, __) => SizedBox(
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
    required this.progress, required this.pulse, required this.starPhase,
    required this.birdPhase, required this.glowPhase,
    required this.isComplete, this.pointsToday = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // ── Sky gradient — warm sunrise to clear blue ──
    final skyTop = Color.lerp(const Color(0xFFFFD580), const Color(0xFF87CEEB), progress)!;
    final skyMid = Color.lerp(const Color(0xFFFF9F43), const Color(0xFF4FC3F7), progress)!;
    final skyBot = Color.lerp(const Color(0xFFFF7846), const Color(0xFF81D4FA), progress)!;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [skyTop, skyMid, skyBot],
      ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // ── Sun / soft glow ──
    final sunX = w * 0.72;
    final sunY = h * (0.22 - progress * 0.08);
    final sunR = 28.0 + pulse * 4;
    final sunAlpha = 0.3 + progress * 0.5;
    // outer halo
    canvas.drawCircle(Offset(sunX, sunY), sunR + 18, Paint()
      ..color = const Color(0xFFFFD580).withValues(alpha: sunAlpha * 0.35 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    canvas.drawCircle(Offset(sunX, sunY), sunR + 8, Paint()
      ..color = const Color(0xFFFFA726).withValues(alpha: sunAlpha * 0.55));
    canvas.drawCircle(Offset(sunX, sunY), sunR, Paint()
      ..color = const Color(0xFFFFE066).withValues(alpha: sunAlpha));

    // ── Distant mountains (back layer) ──
    final mtn1 = Paint()..color = Color.lerp(
      const Color(0xFFB0C4DE), const Color(0xFF7986CB), progress)!.withValues(alpha: 0.60 + progress * 0.20);
    _drawMountain(canvas, Offset(w * 0.05, h * 0.62), w * 0.38, h * 0.28, mtn1);
    _drawMountain(canvas, Offset(w * 0.35, h * 0.60), w * 0.32, h * 0.32, mtn1);
    _drawMountain(canvas, Offset(w * 0.62, h * 0.61), w * 0.42, h * 0.26, mtn1);

    // Mountain snow caps
    if (progress > 0.2) {
      final snowA = ((progress - 0.2) / 0.8).clamp(0.0, 0.9);
      final snowPaint = Paint()..color = Colors.white.withValues(alpha: snowA * 0.75);
      _drawMountainCap(canvas, Offset(w * 0.24, h * 0.34), w * 0.12, snowPaint);
      _drawMountainCap(canvas, Offset(w * 0.51, h * 0.28), w * 0.10, snowPaint);
    }

    // ── Green valley / ground ──
    final groundColor = Color.lerp(
      const Color(0xFF8D9A5E), const Color(0xFF4CAF50), progress)!;
    final groundPath = Path()
      ..moveTo(0, h * 0.70)
      ..quadraticBezierTo(w * 0.25, h * 0.66, w * 0.5, h * 0.68)
      ..quadraticBezierTo(w * 0.75, h * 0.70, w, h * 0.67)
      ..lineTo(w, h)..lineTo(0, h)..close();
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
    final treeColor = Color.lerp(
      const Color(0xFF2E7D32), const Color(0xFF1B5E20), 0.5)!;
    for (int i = 0; i < treeCount; i++) {
      final (tx, ty, tScale) = treePositions[i];
      final tAlpha = ((progress * 5 - i)).clamp(0.0, 1.0);
      _drawPineTree(canvas, Offset(tx, ty), h * 0.22 * tScale, treeColor.withValues(alpha: tAlpha));
    }

    // ── Cozy home — appears after 40% ──
    if (progress > 0.35) {
      final homeAlpha = ((progress - 0.35) / 0.65).clamp(0.0, 1.0);
      _drawHome(canvas, Offset(w * 0.42, h * 0.73), w * 0.18, homeAlpha, isComplete);
    }

    // ── Path / road leading to the home ──
    if (progress > 0.45) {
      final pathAlpha = ((progress - 0.45) / 0.55).clamp(0.0, 0.60);
      final roadPaint = Paint()
        ..color = const Color(0xFFD4A96A).withValues(alpha: pathAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      final road = Path()
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
          Offset(sunX + math.cos(angle) * (sunR + 4), sunY + math.sin(angle) * (sunR + 4)),
          Offset(sunX + math.cos(angle) * (sunR + rayLen), sunY + math.sin(angle) * rayLen),
          Paint()
            ..color = const Color(0xFFFFD700).withValues(alpha: 0.55 * glowPhase)
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
      }
      // Soft golden ground shimmer
      canvas.drawRect(
        Rect.fromLTWH(0, h * 0.66, w, h * 0.34),
        Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.08 * glowPhase)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  void _drawMountain(Canvas canvas, Offset tip, double width, double mtnH, Paint paint) {
    final path = Path()
      ..moveTo(tip.dx - width / 2, tip.dy + mtnH)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + width / 2, tip.dy + mtnH)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawMountainCap(Canvas canvas, Offset tip, double capW, Paint paint) {
    final path = Path()
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
        Rect.fromCenter(center: Offset(base.dx, base.dy - height * 0.08), width: height * 0.10, height: height * 0.18),
        const Radius.circular(2),
      ),
      trunk,
    );
    // Three tiers of pine foliage
    final tiers = [
      (0.0, 1.0, 0.55),   // bottom tier
      (0.28, 0.80, 0.45), // middle tier
      (0.54, 0.55, 0.32), // top tier
    ];
    for (final (yFrac, widthFrac, heightFrac) in tiers) {
      final ty = base.dy - height * yFrac;
      final tw = height * widthFrac;
      final th = height * heightFrac;
      final path = Path()
        ..moveTo(base.dx - tw / 2, ty)
        ..lineTo(base.dx, ty - th)
        ..lineTo(base.dx + tw / 2, ty)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  void _drawHome(Canvas canvas, Offset pos, double size, double alpha, bool complete) {
    // Wall
    final wallColor = Color.lerp(
      const Color(0xFFF5E6C8), complete ? const Color(0xFFFFF9E3) : const Color(0xFFF5E6C8), alpha)!;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy - size * 0.30),
        width: size, height: size * 0.60),
      Paint()..color = wallColor.withValues(alpha: alpha),
    );
    // Roof
    final roofPath = Path()
      ..moveTo(pos.dx - size * 0.60, pos.dy - size * 0.57)
      ..lineTo(pos.dx, pos.dy - size)
      ..lineTo(pos.dx + size * 0.60, pos.dy - size * 0.57)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFFB35C2E).withValues(alpha: alpha));
    // Door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx - size * 0.10, pos.dy - size * 0.38, size * 0.20, size * 0.38),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF6D4C41).withValues(alpha: alpha),
    );
    // Window
    canvas.drawRect(
      Rect.fromCenter(center: Offset(pos.dx - size * 0.27, pos.dy - size * 0.40),
        width: size * 0.18, height: size * 0.16),
      Paint()..color = complete
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
        Paint()..color = Colors.white.withValues(alpha: alpha * (0.25 - i * 0.07)),
      );
    }
  }

  void _drawFlyingBirds(Canvas canvas, double w, double h, double phase, double alpha, bool complete) {
    // Birds drift across the sky in a loose flock
    final birdPaint = Paint()
      ..color = const Color(0xFF37474F).withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final birdPositions = [
      (0.15, 0.18, 0.90, 1.0),  // x_frac, y_frac, x_speed, size
      (0.30, 0.14, 1.0,  0.85),
      (0.40, 0.20, 0.95, 0.75),
      (0.18, 0.22, 0.88, 0.70),
      (0.08, 0.16, 1.05, 0.80),
    ];
    for (final (xBase, yBase, speed, sz) in birdPositions) {
      final bx = ((xBase + phase * speed) % 1.1) * w - w * 0.05;
      final by = h * yBase + math.sin(phase * math.pi * 2 * speed + xBase * 5) * 5;
      _drawBirdV(canvas, Offset(bx, by), sz * 8, birdPaint);
    }
  }

  void _drawBirdV(Canvas canvas, Offset center, double span, Paint paint) {
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx - span / 2, center.dy), width: span, height: span * 0.4),
      math.pi, math.pi, false, paint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx + span / 2, center.dy), width: span, height: span * 0.4),
      math.pi, math.pi, false, paint,
    );
  }

  @override
  bool shouldRepaint(_FiveBlessingsPainter o) =>
      o.progress != progress || o.pulse != pulse ||
      o.starPhase != starPhase || o.birdPhase != birdPhase ||
      o.glowPhase != glowPhase || o.isComplete != isComplete ||
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
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
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
        height: 290,
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
    _paintLightBg(canvas, w, h, progress: progress);

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
    final lightAlpha = ((progress - 0.1) / 0.9) * (isComplete ? 0.60 : 0.38) * pulse;
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

    final walkerAlpha = (0.45 + progress * 0.40).clamp(0.0, 0.85);
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
    final topY = walkerY - 24 * s + bob;       // top of head area
    final shoulderY = walkerY - 10 * s + bob;  // shoulder level
    final waistY = walkerY + 4 * s + bob;      // waist
    final bottomY = walkerY + 20 * s + bob;    // bottom of garment

    // Draw a smooth silhouette shape — narrow at top (head), wider at shoulders,
    // tapers at waist, flows out slightly at bottom like a robe
    bodyPath.moveTo(cx + sway, topY); // top center
    // Right side
    bodyPath.cubicTo(
      cx + 7.5 * s + sway, topY + 3 * s,        // head curves out
      cx + 11 * s + sway, shoulderY,              // shoulder width
      cx + 9.5 * s + sway, waistY,                // tapers at waist
    );
    bodyPath.cubicTo(
      cx + 10 * s + sway, waistY + 6 * s,         // flows out
      cx + 12 * s + sway, bottomY - 3 * s,        // garment bottom
      cx + 7 * s + sway, bottomY,                  // bottom right
    );
    // Bottom curve
    bodyPath.quadraticBezierTo(cx + sway, bottomY + 2.5 * s, cx - 7 * s + sway, bottomY);
    // Left side (mirror)
    bodyPath.cubicTo(
      cx - 12 * s + sway, bottomY - 3 * s,
      cx - 10 * s + sway, waistY + 6 * s,
      cx - 9.5 * s + sway, waistY,
    );
    bodyPath.cubicTo(
      cx - 11 * s + sway, shoulderY,
      cx - 7.5 * s + sway, topY + 3 * s,
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
      ).createShader(Rect.fromLTRB(cx - 13 * s, topY, cx + 13 * s, bottomY)));

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
        height: 290,
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
    _paintLightBg(canvas, w, h, progress: progress);

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
    // punch scale removed — smooth calm tap

    // 3. Draw the 4 flame layers (outer ring of fire around center)
    _drawFlames(canvas, cx, cy, w, h);

    // 4. Central figure — silhouette of light (the person being freed)
    _drawFigure(canvas, cx, cy);

    canvas.restore();

    // 5. Shockwave on tap — cool blue instead of fire
    // tap-effect removed — smooth calm

    // 6. Tap particles — ember sparks transforming to cool light
    // tap-effect removed — smooth calm

    // 7. Progress label
    // progress % label removed

    // 8. Points badge
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
      final glowAlpha = (0.22 + strainProgress * 0.10) * pulse;
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

      final flameAlpha = (0.85 - strainProgress * 0.10).clamp(0.50, 0.90);
      canvas.drawPath(flamePath, Paint()
        ..color = flameColor.withValues(alpha: flameAlpha));

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
    final orbAlpha = fadeIn * 0.55 * pulse;

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
    final halfW = w / 2;
    final horizonY = h * 0.62;

    // ── LEFT HALF: Morning (warm sunrise) ──
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, halfW, h));
    // Sky gradient — warm golden-yellow
    canvas.drawRect(Rect.fromLTWH(0, 0, halfW, h), Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFF8E1),
          Color.lerp(const Color(0xFFFFECB3), const Color(0xFFFFD54F), progress)!,
          Color.lerp(const Color(0xFFFFCC80), const Color(0xFFFB8C00), progress)!,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, halfW, h)));

    // Morning sun
    final sunR = 18 + progress * 8;
    final sunCy = horizonY - progress * horizonY * 0.30;
    canvas.drawCircle(Offset(halfW * 0.5, sunCy), sunR + 12, Paint()
      ..color = Color.fromRGBO(255, 220, 100, 0.12 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    canvas.drawCircle(Offset(halfW * 0.5, sunCy), sunR, Paint()
      ..shader = RadialGradient(colors: [
        Colors.white.withValues(alpha: 0.85),
        const Color(0xFFFFE082).withValues(alpha: 0.75),
        const Color(0xFFFFB74D).withValues(alpha: 0.50),
      ]).createShader(Rect.fromCircle(center: Offset(halfW * 0.5, sunCy), radius: sunR)));
    // Sun rays
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi * 2 / 6;
      final sx = halfW * 0.5 + math.cos(angle) * (sunR + 3);
      final sy = sunCy + math.sin(angle) * (sunR + 3);
      final ex = halfW * 0.5 + math.cos(angle) * (sunR + 14 + progress * 8);
      final ey = sunCy + math.sin(angle) * (sunR + 14 + progress * 8);
      canvas.drawLine(Offset(sx, sy), Offset(ex, ey), Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.25 * progress)
        ..strokeWidth = 1.5..strokeCap = StrokeCap.round);
    }

    // Morning hills
    final hillPath = Path()
      ..moveTo(0, horizonY)
      ..quadraticBezierTo(halfW * 0.25, horizonY - 20, halfW * 0.5, horizonY - 15)
      ..quadraticBezierTo(halfW * 0.75, horizonY - 8, halfW, horizonY)
      ..lineTo(halfW, h)..lineTo(0, h)..close();
    canvas.drawPath(hillPath, Paint()..color = Color.lerp(
      const Color(0xFFE6A050), const Color(0xFFF5B041), progress)!);

    canvas.restore();

    // ── RIGHT HALF: Evening (cool night) ──
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(halfW, 0, halfW, h));
    // Sky gradient — deep blue-indigo
    canvas.drawRect(Rect.fromLTWH(halfW, 0, halfW, h), Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1A1A3E),
          Color.lerp(const Color(0xFF1E2952), const Color(0xFF2C3E6B), progress)!,
          Color.lerp(const Color(0xFF2A3555), const Color(0xFF3B4F7A), progress)!,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromLTWH(halfW, 0, halfW, h)));

    // Stars on night side
    const nightStars = [
      (0.55, 0.08), (0.62, 0.18), (0.70, 0.06), (0.78, 0.14),
      (0.85, 0.10), (0.92, 0.20), (0.58, 0.25), (0.75, 0.22),
    ];
    for (int i = 0; i < nightStars.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      canvas.drawCircle(
        Offset(nightStars[i].$1 * w, nightStars[i].$2 * h),
        0.8 + tw * 1.0,
        Paint()..color = Colors.white.withValues(alpha: 0.25 + 0.45 * tw));
    }

    // Crescent moon
    final moonCx = halfW + halfW * 0.5;
    final moonCy = horizonY * 0.35;
    final moonR = 16.0;
    final outerMoon = Path()..addOval(Rect.fromCircle(center: Offset(moonCx, moonCy), radius: moonR));
    final innerMoon = Path()..addOval(Rect.fromCircle(center: Offset(moonCx + moonR * 0.5, moonCy - moonR * 0.1), radius: moonR * 0.85));
    final crescentPath = Path.combine(PathOperation.difference, outerMoon, innerMoon);
    canvas.drawCircle(Offset(moonCx, moonCy), moonR + 6, Paint()
      ..color = const Color(0xFFE8D98A).withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawPath(crescentPath, Paint()..color = const Color(0xFFE8D98A).withValues(alpha: 0.80));

    // Evening hills
    final eHillPath = Path()
      ..moveTo(halfW, horizonY)
      ..quadraticBezierTo(halfW + halfW * 0.3, horizonY - 18, halfW + halfW * 0.6, horizonY - 12)
      ..quadraticBezierTo(halfW + halfW * 0.85, horizonY - 5, w, horizonY)
      ..lineTo(w, h)..lineTo(halfW, h)..close();
    canvas.drawPath(eHillPath, Paint()..color = const Color(0xFF1E2845).withValues(alpha: 0.85));

    canvas.restore();

    // ── Center divider — soft gradient blend ──
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, h / 2), width: 2, height: h * 0.65),
      Paint()..color = Colors.white.withValues(alpha: 0.20));

    // ── Progress label ──
    // progress % label removed

    // ── Points badge ──
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
// 💚 Body Hearing Sight — Allah's gift of wellbeing (morning_28 / evening_28)
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

class _ThreeVesselsState extends State<_ThreeVessels> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _glowCtrl;
  late Animation<double> _pulse, _grow, _glow;
  double _prevProgress = 0.0;

  static const _rows = [
    (label: 'Wellbeing',  sub: 'in your body',                    hex: 0xFF0D8A6A, isGood: true),
    (label: 'Wellbeing',  sub: 'in your hearing',                  hex: 0xFF1565C0, isGood: true),
    (label: 'Wellbeing',  sub: 'in your sight',                    hex: 0xFF6A1B9A, isGood: true),
    (label: 'Protection', sub: 'from disbelief and poverty',       hex: 0xFFC84B31, isGood: false),
    (label: 'Protection', sub: 'from the punishment of the grave', hex: 0xFF8B4513, isGood: false),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.97, end: 1.03).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress; _growCtrl.value = widget.progress;
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
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
    _pulseCtrl.dispose(); _growCtrl.dispose(); _glowCtrl.dispose();
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
                    colors: isDark
                        ? [const Color(0xFF1A2030), const Color(0xFF1A2828)]
                        : [const Color(0xFFF5F9FF), const Color(0xFFEDF8F3)],
                  ),
                ),
              ),
              CustomPaint(painter: _VesselDotPainter(isDark: isDark)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i < _rows.length; i++)
                      _buildRow(rowIdx: i, total: _rows.length, progress: progress, isDark: isDark),
                  ],
                ),
              ),
              if (widget.isComplete)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        const Color(0xFF26C485).withValues(alpha: _glow.value * 0.85),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow({required int rowIdx, required int total, required double progress, required bool isDark}) {
    final row = _rows[rowIdx];
    final accent = Color(row.hex);
    final threshold = rowIdx / total;
    final rowP = ((progress - threshold) * total).clamp(0.0, 1.0);
    return AnimatedOpacity(
      opacity: rowP,
      duration: const Duration(milliseconds: 350),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.11 : 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: isDark ? 0.35 : 0.22), width: 1.2),
        ),
        child: Row(
          children: [
            Container(width: 8, height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: accent.withValues(alpha: rowP * (isDark ? 0.9 : 0.75)))),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(text: '${row.label}  ',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800,
                      color: accent.withValues(alpha: rowP * (isDark ? 1.0 : 0.9)))),
                  TextSpan(text: row.sub,
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white70.withValues(alpha: rowP)
                          : const Color(0xFF2D3748).withValues(alpha: rowP * 0.75))),
                ]),
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
    final paint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF0D6B52)).withValues(alpha: isDark ? 0.04 : 0.05);
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
    required this.progress, required this.isComplete,
    required this.tapCount, this.pointsToday = 0,
  });

  @override
  State<_SevenPillars> createState() => _SevenPillarsState();
}

class _SevenPillarsState extends State<_SevenPillars> with TickerProviderStateMixin {
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
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress; _growCtrl.value = widget.progress;
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
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
    _pulseCtrl.dispose(); _growCtrl.dispose();
    _glowCtrl.dispose(); _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _glowCtrl, _fadeCtrl]),
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
                    colors: isDark
                        ? [const Color(0xFF1A2E3A), const Color(0xFF1E3D30)]
                        : [const Color(0xFFF0F7FF), const Color(0xFFE8F5F0)],
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
                        const Color(0xFFD4AF37).withValues(alpha: 0.12 * _glow.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Lines revealed progressively ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFFD4AF37).withValues(alpha: _glow.value * 0.8),
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
    // Each line reveals when progress passes its threshold
    final threshold = lineIndex / totalLines;
    final lineProgress = ((progress - threshold) * totalLines).clamp(0.0, 1.0);

    // Style varies: two lines big + bold, rest smaller
    final isBig = lineIndex == 0 || lineIndex == totalLines - 1;
    final isHighlight = lineIndex == 3; // "this world AND the Hereafter" lines

    final Color textColor;
    final double fontSize;

    if (isHighlight || isComplete) {
      textColor = const Color(0xFFFFD700);
      fontSize = isBig ? 20 : 17;
    } else if (lineIndex == 0) {
      textColor = isDark
          ? Colors.white.withValues(alpha: lineProgress)
          : const Color(0xFF0C3547).withValues(alpha: lineProgress);
      fontSize = 22;
    } else {
      textColor = isDark
          ? Colors.white.withValues(alpha: lineProgress * 0.85)
          : const Color(0xFF0C4A3E).withValues(alpha: lineProgress * 0.85);
      fontSize = isBig ? 19 : 15;
    }

    return AnimatedOpacity(
      opacity: lineProgress.clamp(0.0, 1.0),
      duration: const Duration(milliseconds: 400),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: fontSize * (lineIndex == 0 ? _pulse.value : 1.0),
          fontWeight: lineIndex == 0 || isComplete
              ? FontWeight.w800
              : FontWeight.w600,
          color: textColor,
          letterSpacing: lineIndex == 0 ? 0.5 : 0.2,
          height: 1.3,
        ),
      ),
    );
  }
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
    _paintLightBg(canvas, w, h, progress: progress);

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
    final edgeColor = isComplete
        ? _gateColor.withValues(alpha: alpha * 0.70)
        : _handColor.withValues(alpha: alpha * 0.55);
    final panelColor = isComplete
        ? _gateColor.withValues(alpha: alpha * 0.50)
        : _handColor.withValues(alpha: alpha * 0.35);

    // Arch above gates
    final archLeft = cx - gateW - openAmt - 6;
    final archRight = cx + gateW + openAmt + 6;
    final archTop = gateTop - 18;
    final archPath = Path()
      ..moveTo(archLeft, gateTop)
      ..quadraticBezierTo(archLeft, archTop + 6, cx, archTop)
      ..quadraticBezierTo(archRight, archTop + 6, archRight, gateTop);
    canvas.drawPath(archPath, Paint()
      ..color = edgeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round);

    // Circle ornament on top of arch
    canvas.drawCircle(Offset(cx, archTop - 2), 5, Paint()..color = edgeColor);
    canvas.drawCircle(Offset(cx, archTop - 2), 3, Paint()..color = Colors.white.withValues(alpha: alpha * 0.4));

    // Left door
    final leftX = cx - 2 - openAmt;
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(leftX - gateW, gateTop, gateW, gateH), const Radius.circular(2));
    canvas.drawRRect(leftRect, Paint()..color = doorColor);
    canvas.drawRRect(leftRect, Paint()..color = edgeColor..style = PaintingStyle.stroke..strokeWidth = 1.2);
    // Panels
    for (int i = 0; i < 2; i++) {
      final py = gateTop + 6 + i * (gateH * 0.44);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(leftX - gateW + 3, py, gateW - 6, gateH * 0.34), const Radius.circular(1.5)),
        Paint()..color = panelColor..style = PaintingStyle.stroke..strokeWidth = 0.8);
    }
    canvas.drawCircle(Offset(leftX - 4, gateY - gateH * 0.45), 2, Paint()..color = panelColor);

    // Right door
    final rightX = cx + 2 + openAmt;
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rightX, gateTop, gateW, gateH), const Radius.circular(2));
    canvas.drawRRect(rightRect, Paint()..color = doorColor);
    canvas.drawRRect(rightRect, Paint()..color = edgeColor..style = PaintingStyle.stroke..strokeWidth = 1.2);
    for (int i = 0; i < 2; i++) {
      final py = gateTop + 6 + i * (gateH * 0.44);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(rightX + 3, py, gateW - 6, gateH * 0.34), const Radius.circular(1.5)),
        Paint()..color = panelColor..style = PaintingStyle.stroke..strokeWidth = 0.8);
    }
    canvas.drawCircle(Offset(rightX + 4, gateY - gateH * 0.45), 2, Paint()..color = panelColor);

    // Light behind open gates
    if (progress > 0.1) {
      final lightA = progress * (isComplete ? 0.25 : 0.12) * pulse;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, gateY - gateH * 0.4), width: openAmt * 1.8, height: gateH * 0.8),
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
            Colors.white.withValues(alpha: lightA * 1.5),
            _gateColor.withValues(alpha: lightA),
            Colors.transparent,
          ]).createShader(Rect.fromLTRB(0, gateTop, w, gateY)));
    }

    // Noor emanating from center of gates
    if (progress > 0.3) {
      final noorAlpha = ((progress - 0.3) / 0.7).clamp(0.0, 1.0) * 0.20 * pulse;
      canvas.drawCircle(
        Offset(cx, gateY - gateH * 0.4), 10,
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
        height: 290,
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
    _paintLightBg(canvas, w, h, progress: progress);

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
    // punch scale removed — smooth calm tap

    // 3. Approaching threats that dissolve on the dome
    _drawThreats(canvas, cx, cy, w);

    // 4. Protection dome — 3 layers building with progress (3 reps)
    _drawDome(canvas, cx, cy, w);

    // 5. Central Bismillah core
    _drawCore(canvas, cx, cy);

    canvas.restore();

    // 6. Shockwave on tap
    // tap-effect removed — smooth calm

    // 7. Tap particles
    // tap-effect removed — smooth calm

    // 8. Progress label
    // progress % label removed

    // 9. Points badge
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
    _paintLightBg(canvas, w, h, progress: progress);

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
    final foamCount = 25;
    final remainingFoam = ((1.0 - progress) * foamCount).round();

    for (int i = 0; i < foamCount; i++) {
      final rng = math.Random(i * 997);
      final fx = w * 0.08 + rng.nextDouble() * w * 0.84;
      final baseY = horizonY + rng.nextDouble() * 45 + 5;
      final blobSize = 3.0 + rng.nextDouble() * 4.0;

      if (i >= remainingFoam) {
        // Foam dissolved — rises as white light (sin forgiven)
        final riseT = ((progress - i / foamCount) * foamCount).clamp(0.0, 1.0);
        if (riseT < 0.01 || riseT > 0.95) continue;

        final riseY = baseY - riseT * 60;
        final riseAlpha = (1.0 - riseT) * 0.55;
        final shrink = blobSize * (1.0 - riseT * 0.7);
        // White sparkle rising
        canvas.drawCircle(
          Offset(fx, riseY), shrink + 3,
          Paint()
            ..color = Colors.white.withValues(alpha: riseAlpha * 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(fx, riseY), shrink,
          Paint()..color = Colors.white.withValues(alpha: riseAlpha),
        );
      } else {
        // Foam still on water — dark blobs (sins) bobbing
        final bobY = baseY + math.sin(wavePhase * math.pi * 2 + i * 0.8) * 4;
        final bobX = fx + math.sin(wavePhase * math.pi * 2 + i * 1.5) * 3;
        final foamAlpha = 0.30 + math.sin(wavePhase * math.pi * 2 + i * 1.3) * 0.08;

        // Dark smudge (sin)
        canvas.drawCircle(
          Offset(bobX, bobY), blobSize + 2,
          Paint()
            ..color = const Color(0xFF475569).withValues(alpha: foamAlpha * 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawCircle(
          Offset(bobX, bobY), blobSize,
          Paint()..color = _foamColor.withValues(alpha: foamAlpha),
        );
        // White foam highlight on top
        canvas.drawCircle(
          Offset(bobX - 1, bobY - 1), blobSize * 0.35,
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
      Rect.fromCenter(center: Offset(cx, cy + 50), width: 30 + progress * 20, height: 6),
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
        height: 290,
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
    _paintLightBg(canvas, w, h, progress: progress);

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
    // punch scale removed — smooth calm tap

    // 3. Cage & Freed Souls structure
    _drawCageAndSouls(canvas, cx, cy, w);

    // 4. Four reward indicators around it
    _drawRewards(canvas, cx, cy, w);

    canvas.restore();

    // 5. Shockwave on tap
    // tap-effect removed — smooth calm

    // 6. Golden hasanat raining down
    // tap-effect removed — smooth calm

    // 7. Progress label
    // progress % label removed

    // 8. Points badge
  }

  /// A breaking cage releasing 10 abstract human silhouettes with chains shattering
  void _drawCageAndSouls(Canvas canvas, double cx, double cy, double w) {
    final cageAlpha = (1.0 - progress * 0.85).clamp(0.0, 1.0);
    final cageColor = const Color(0xFF64748B);
    final baseY = cy + 30;
    final topY = cy - 40;
    final cageW = 72.0;

    // ── Cage floor (oval base) ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY), width: cageW, height: 14),
      Paint()
        ..color = cageColor.withValues(alpha: cageAlpha * 0.80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    // ── Cage top ring ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, topY), width: cageW * 0.60, height: 10),
      Paint()
        ..color = cageColor.withValues(alpha: cageAlpha * 0.60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    // ── Hook above ──
    canvas.drawLine(
      Offset(cx, topY - 5), Offset(cx, topY - 14),
      Paint()..color = cageColor.withValues(alpha: cageAlpha * 0.55)
             ..strokeWidth = 2.0..strokeCap = StrokeCap.round,
    );

    // ── Bars — bend outward as progress rises ──
    final bend = progress * 40.0;
    for (int i = 0; i < 6; i++) {
      final t = i / 5.0;
      final bx = cx - cageW / 2 + cageW * t;
      final pushX = bx + (t < 0.5 ? -bend * (0.5 - t) * 2 : bend * (t - 0.5) * 2);
      final barAlpha = cageAlpha * (0.55 + (1 - t.abs()) * 0.10);
      final barPath = Path()
        ..moveTo(bx, baseY - 7)
        ..quadraticBezierTo(pushX, cy - 8, cx * (0.4 + 0.6 * (1 - t.abs())), topY + 5);
      canvas.drawPath(barPath, Paint()
        ..color = cageColor.withValues(alpha: barAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round);
    }

    // ── 10 figures: inside caged until threshold, then break free and rise ──
    for (int i = 0; i < 10; i++) {
      final threshold = i / 10.0;
      final freed = progress > threshold;

      if (!freed) {
        // Waiting inside cage — tiny silhouette (head + body)
        final col = i % 5;
        final row = i ~/ 5;
        final fx = cx - 16.0 + col * 8.0;
        final fy = cy + 8.0 + row * 14.0;
        final a = 0.18 + starPhase * 0.05;
        // head
        canvas.drawCircle(Offset(fx, fy - 6), 3.2, Paint()..color = Colors.white.withValues(alpha: a));
        // body
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(fx, fy + 1), width: 5, height: 8), const Radius.circular(2)),
          Paint()..color = Colors.white.withValues(alpha: a * 0.75),
        );
        // chain link (horizontal bar at waist)
        canvas.drawLine(
          Offset(fx - 5, fy + 1), Offset(fx + 5, fy + 1),
          Paint()..color = cageColor.withValues(alpha: a * 1.5)
                 ..strokeWidth = 1.2..strokeCap = StrokeCap.round,
        );
      } else {
        // Freed — figure rising with broken chain glowing
        final sp = ((progress - threshold) * 10.0).clamp(0.0, 1.0);
        final floatDir = i % 2 == 0 ? 1.0 : -1.0;
        final riseX = cx + math.sin(sp * math.pi * 1.8 + i * 0.7) * 28 * floatDir;
        final riseY = cy + 15 - sp * 115;
        final figAlpha = (1.0 - sp * 0.30).clamp(0.0, 1.0);

        // Soft freedom glow
        canvas.drawCircle(Offset(riseX, riseY), 14,
          Paint()
            ..color = const Color(0xFFD4AF37).withValues(alpha: sp * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

        // Head
        canvas.drawCircle(Offset(riseX, riseY - 9), 4.5,
          Paint()..color = Colors.white.withValues(alpha: figAlpha));
        // Body
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(riseX, riseY + 1), width: 7, height: 12), const Radius.circular(3)),
          Paint()..color = Colors.white.withValues(alpha: figAlpha * 0.80),
        );
        // Arms raised in freedom (two short lines going up)
        canvas.drawLine(
          Offset(riseX - 3, riseY - 2), Offset(riseX - 8, riseY - 8),
          Paint()..color = Colors.white.withValues(alpha: figAlpha * 0.70)
                 ..strokeWidth = 1.4..strokeCap = StrokeCap.round);
        canvas.drawLine(
          Offset(riseX + 3, riseY - 2), Offset(riseX + 8, riseY - 8),
          Paint()..color = Colors.white.withValues(alpha: figAlpha * 0.70)
                 ..strokeWidth = 1.4..strokeCap = StrokeCap.round);

        // Broken chain flash (only at moment of breaking)
        if (sp < 0.25) {
          final breakA = (1.0 - sp / 0.25) * 0.80;
          canvas.drawLine(
            Offset(riseX - 6, riseY + 5), Offset(riseX - 2, riseY + 3),
            Paint()..color = const Color(0xFFD4AF37).withValues(alpha: breakA)
                   ..strokeWidth = 1.8..strokeCap = StrokeCap.round);
          canvas.drawLine(
            Offset(riseX + 2, riseY + 3), Offset(riseX + 6, riseY + 5),
            Paint()..color = const Color(0xFFD4AF37).withValues(alpha: breakA)
                   ..strokeWidth = 1.8..strokeCap = StrokeCap.round);
        }
      }
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
          ? 0.75 + 0.15 * pulse
          : (progress / threshold).clamp(0.0, 1.0) * 0.35;

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
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _rayCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat();
  }

  @override
  void didUpdateWidget(_SunriseGlory old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) { _growCtrl.animateTo(widget.progress); _prevProgress = widget.progress; }
    if (widget.tapCount != _prevTap) { _prevTap = widget.tapCount; for (final p in _particles) { p.reset(); } _pCtrl.forward(from: 0); _punchCtrl.forward(from: 0); _shockCtrl.forward(from: 0); }
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose(); _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose(); _rayCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _rayCtrl]),
      builder: (_, __) => SizedBox(height: 290, child: CustomPaint(painter: _SunriseGloryPainter(
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
    _paintLightBg(canvas, w, h, progress: progress);

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

    // punch scale removed — smooth calm tap

    // Sun — grows and brightens with progress (stays in safe zone)
    final sunR = 14 + progress * 18;
    final sunY = cy + 2 - progress * 8; // gentle rise, stays well within bounds

    // Sun glow
    canvas.drawCircle(Offset(cx, sunY), sunR + 15, Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.08 * pulse)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));

    // Sun body
    canvas.drawCircle(Offset(cx, sunY), sunR, Paint()
      ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.70), const Color(0xFFF59E0B).withValues(alpha: 0.50), Colors.transparent], stops: const [0.0, 0.5, 1.0])
      .createShader(Rect.fromCircle(center: Offset(cx, sunY), radius: sunR)));

    // 3 concentric rings — SubhanAllah, Alhamdulillah, Allahu Akbar
    for (int i = 0; i < 3; i++) {
      final ringProgress = ((progress - i / 3.0) * 3.0).clamp(0.0, 1.0);
      if (ringProgress < 0.01) continue;
      final ringR = (sunR + 10 + i * 14) * ringProgress; // tighter rings
      final ringAlpha = (0.15 + ringProgress * 0.25) * pulse;
      final color = _ringColors[i];

      canvas.drawCircle(Offset(cx, sunY), ringR, Paint()..color = color.withValues(alpha: ringAlpha)..style = PaintingStyle.stroke..strokeWidth = 2.0);

      // Orbiting dot
      final dotAngle = rayPhase * math.pi * 2 + i * 2.1;
      canvas.drawCircle(Offset(cx + math.cos(dotAngle) * ringR, sunY + math.sin(dotAngle) * ringR), 2, Paint()..color = color.withValues(alpha: ringAlpha * 2));
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
        canvas.drawLine(Offset(cx, horizonY), Offset(cx + math.cos(rayAngle) * rayLen, horizonY + math.sin(rayAngle) * rayLen * 0.5),
          Paint()..color = const Color(0xFFF59E0B).withValues(alpha: rayAlpha)..strokeWidth = 1.0..strokeCap = StrokeCap.round);
      }
    }

    canvas.restore();

    // Shockwave
    // tap-effect removed — smooth calm

    // Particles
    // tap-effect removed — smooth calm

    // Label
    // progress % label removed

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
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000))..repeat();
  }

  @override void didUpdateWidget(_TenSalawat old) { super.didUpdateWidget(old); if (widget.progress != _prevProgress) { _growCtrl.animateTo(widget.progress); _prevProgress = widget.progress; } if (widget.tapCount != _prevTap) { _prevTap = widget.tapCount; for (final p in _particles) { p.reset(); } _pCtrl.forward(from: 0); _punchCtrl.forward(from: 0); _shockCtrl.forward(from: 0); } }
  @override void dispose() { _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose(); _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose(); _orbitCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _orbitCtrl]),
      builder: (_, __) => SizedBox(height: 290, child: CustomPaint(painter: _TenSalawatPainter(
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
    _paintLightBg(canvas, w, h, progress: progress);

    // Stars
    const starPos = [(0.08, 0.06), (0.22, 0.14), (0.40, 0.04), (0.56, 0.12), (0.72, 0.07), (0.88, 0.15), (0.32, 0.20), (0.64, 0.18), (0.16, 0.22), (0.78, 0.10)];
    for (int i = 0; i < starPos.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
      canvas.drawCircle(Offset(starPos[i].$1 * w, starPos[i].$2 * h), 0.7 + tw * 0.8, Paint()..color = Colors.white.withValues(alpha: (0.10 + progress * 0.25 + 0.30 * tw * progress).clamp(0.0, 0.6)));
    }

    // punch scale removed — smooth calm tap

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
    // tap-effect removed — smooth calm

    // Particles
    // tap-effect removed — smooth calm

    // Label
    // progress % label removed

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
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))..repeat(reverse: true);
  }

  @override void didUpdateWidget(_DoorsOfMercy old) { super.didUpdateWidget(old); if (widget.progress != _prevProgress) { _growCtrl.animateTo(widget.progress); _prevProgress = widget.progress; } if (widget.tapCount != _prevTap) { _prevTap = widget.tapCount; for (final p in _particles) { p.reset(); } _pCtrl.forward(from: 0); _punchCtrl.forward(from: 0); _shockCtrl.forward(from: 0); } }
  @override void dispose() { _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose(); _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose(); _glowCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _glowCtrl]),
      builder: (_, __) => SizedBox(height: 290, child: CustomPaint(painter: _DoorsOfMercyPainter(
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
  static const _heartColor = Color(0xFFF06292);   // vibrant pink like reference
  static const _heartDark = Color(0xFFE91E63);    // deeper pink-red
  static const _spotColor = Color(0xFF7B4055);     // dark sin spots
  static const _mercyColor = Color(0xFFD4AF37);

  const _DoorsOfMercyPainter({required this.progress, required this.pulse, required this.starPhase, required this.particlePhase, required this.particles, required this.isComplete, this.pointsToday = 0, this.punchScale = 1.0, this.shockPhase = 1.0, this.glowPhase = 0.0});

  // Spots (sins) on the heart — deterministic positions
  static const _spotPositions = [
    (-0.12, -0.05, 7.0), (0.10, 0.08, 5.5), (-0.06, 0.15, 7.5),
    (0.15, -0.08, 5.0), (-0.18, 0.10, 6.0), (0.04, -0.12, 6.5),
    (0.18, 0.16, 5.2), (-0.14, -0.15, 5.8), (0.08, 0.22, 4.5),
    (-0.04, 0.04, 7.2), (0.12, -0.02, 6.2), (-0.10, 0.20, 5.0),
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
    canvas.drawCircle(Offset(cx, heartCy), heartR * 1.3, Paint()
      ..color = _heartColor.withValues(alpha: 0.08 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));

    // Heart path — proper shape with two bumps at top and pointed bottom
    final heartPath = Path();
    final r = heartR;
    // Start at bottom tip
    heartPath.moveTo(cx, heartCy + r * 0.9);
    // Bottom-right to right bump
    heartPath.cubicTo(
      cx + r * 0.4, heartCy + r * 0.4,
      cx + r * 1.1, heartCy + r * 0.1,
      cx + r * 1.0, heartCy - r * 0.3,
    );
    // Right bump top arc
    heartPath.cubicTo(
      cx + r * 0.9, heartCy - r * 0.7,
      cx + r * 0.35, heartCy - r * 0.8,
      cx, heartCy - r * 0.4,
    );
    // Left bump top arc
    heartPath.cubicTo(
      cx - r * 0.35, heartCy - r * 0.8,
      cx - r * 0.9, heartCy - r * 0.7,
      cx - r * 1.0, heartCy - r * 0.3,
    );
    // Left bump to bottom tip
    heartPath.cubicTo(
      cx - r * 1.1, heartCy + r * 0.1,
      cx - r * 0.4, heartCy + r * 0.4,
      cx, heartCy + r * 0.9,
    );
    heartPath.close();

    // Heart fill — gradient from light pink to deeper pink
    canvas.drawPath(heartPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [
          isComplete ? const Color(0xFFF06292) : _heartColor,
          isComplete ? const Color(0xFFEC407A) : _heartDark,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, heartCy), radius: heartR)));

    // Highlight on upper-left bump (soft light reflection like reference)
    canvas.drawCircle(Offset(cx - heartR * 0.45, heartCy - heartR * 0.45), heartR * 0.20, Paint()
      ..color = Colors.white.withValues(alpha: 0.22));
    // Curved highlight stroke on left bump
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - heartR * 0.45, heartCy - heartR * 0.30), width: heartR * 0.5, height: heartR * 0.6),
      math.pi * 1.1, math.pi * 0.5, false,
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
        canvas.drawCircle(Offset(spotX, spotY), sr + bobble + 3, Paint()
          ..color = _spotColor.withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawCircle(Offset(spotX, spotY), sr + bobble, Paint()
          ..color = _spotColor.withValues(alpha: 0.65));
      } else {
        // Spot cleared — light sparkle fading out
        final clearT = ((progress - i / _spotPositions.length) * _spotPositions.length).clamp(0.0, 1.0);
        if (clearT < 0.01 || clearT > 0.90) continue;
        final fadeAlpha = (1.0 - clearT) * 0.60;
        canvas.drawCircle(Offset(spotX, spotY), sr * (1.0 - clearT * 0.5) + 3, Paint()
          ..color = Colors.white.withValues(alpha: fadeAlpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawCircle(Offset(spotX, spotY), sr * (1.0 - clearT * 0.6), Paint()
          ..color = Colors.white.withValues(alpha: fadeAlpha));
      }
    }

    // Completion glow — heart glows warm
    if (isComplete) {
      canvas.drawPath(heartPath, Paint()
        ..color = const Color(0xFFFF8A80).withValues(alpha: 0.08 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }

    canvas.restore();

    // Shockwave
    // tap-effect removed — smooth calm

    // Particles
    // tap-effect removed — smooth calm

    // Label
    // progress % label removed

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
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
    _cosmicCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))..repeat();
  }

  @override void didUpdateWidget(_CosmicWeight old) { super.didUpdateWidget(old); if (widget.progress != _prevProgress) { _growCtrl.animateTo(widget.progress); _prevProgress = widget.progress; } if (widget.tapCount != _prevTap) { _prevTap = widget.tapCount; for (final p in _particles) { p.reset(); } _pCtrl.forward(from: 0); _punchCtrl.forward(from: 0); _shockCtrl.forward(from: 0); } }
  @override void dispose() { _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose(); _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose(); _cosmicCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _cosmicCtrl]),
      builder: (_, __) => SizedBox(height: 290, child: CustomPaint(painter: _CosmicWeightPainter(
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
    final w = size.width, h = size.height, cx = w / 2, cy = h * 0.38;

    // Background
    _paintLightBg(canvas, w, h, progress: progress);

    // punch scale removed — smooth calm tap

    // ── Scale structure — thick, bright, prominent ──
    final beamY = cy;
    final tilt = progress * 14;
    final beamLen = w * 0.34;

    // Central pillar
    canvas.drawLine(Offset(cx, beamY - 42), Offset(cx, beamY + 10), Paint()
      ..color = const Color(0xFF8B7355).withValues(alpha: 0.80)
      ..strokeWidth = 4.0..strokeCap = StrokeCap.round);

    // Fulcrum triangle
    final fulPath = Path()
      ..moveTo(cx, beamY - 45)
      ..lineTo(cx - 10, beamY - 32)
      ..lineTo(cx + 10, beamY - 32)
      ..close();
    canvas.drawPath(fulPath, Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.85));
    canvas.drawPath(fulPath, Paint()..color = const Color(0xFFB8962E).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Beam — thick and gold
    final leftBeamY = beamY - 30 + tilt;
    final rightBeamY = beamY - 30 - tilt;
    canvas.drawLine(Offset(cx - beamLen, leftBeamY), Offset(cx + beamLen, rightBeamY), Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.80)
      ..strokeWidth = 3.5);

    // ── Left pan chains (heavy side — phrases) ──
    final leftPanX = cx - beamLen;
    final leftPanY = leftBeamY + 30;
    canvas.drawLine(Offset(leftPanX - 18, leftPanY - 2), Offset(leftPanX, leftBeamY + 2), Paint()
      ..color = const Color(0xFF8B7355).withValues(alpha: 0.70)..strokeWidth = 2.0);
    canvas.drawLine(Offset(leftPanX + 18, leftPanY - 2), Offset(leftPanX, leftBeamY + 2), Paint()
      ..color = const Color(0xFF8B7355).withValues(alpha: 0.70)..strokeWidth = 2.0);

    // Left pan dish — curved, thick
    final leftPanPath = Path()
      ..moveTo(leftPanX - 22, leftPanY)
      ..quadraticBezierTo(leftPanX, leftPanY + 14, leftPanX + 22, leftPanY);
    canvas.drawPath(leftPanPath, Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke..strokeWidth = 3.0..strokeCap = StrokeCap.round);

    // ── 4 phrase circles inside left pan (transparent circles with text) ──
    for (int i = 0; i < 4; i++) {
      final phraseThreshold = (i + 1) * 0.25;
      final reached = progress >= phraseThreshold;
      final phraseA = reached ? 0.75 : ((progress / phraseThreshold).clamp(0.0, 1.0) * 0.25);
      if (phraseA < 0.03) continue;

      final color = _phraseColors[i];
      // 2x2 grid inside the pan area
      final col = i % 2;
      final row = i ~/ 2;
      final ox = leftPanX - 10 + col * 20;
      final oy = leftPanY + 18 + row * 22;
      final orbR = 10.0;

      // Transparent circle with border
      canvas.drawCircle(Offset(ox, oy), orbR, Paint()
        ..color = color.withValues(alpha: phraseA * 0.15));
      canvas.drawCircle(Offset(ox, oy), orbR, Paint()
        ..color = color.withValues(alpha: phraseA * 0.70)
        ..style = PaintingStyle.stroke..strokeWidth = 1.8);

      // Label inside circle — removed
    }

    // ── Right pan chains (light side — empty) ──
    final rightPanX = cx + beamLen;
    final rightPanY = rightBeamY + 30;
    canvas.drawLine(Offset(rightPanX - 18, rightPanY - 2), Offset(rightPanX, rightBeamY + 2), Paint()
      ..color = const Color(0xFF8B7355).withValues(alpha: 0.70)..strokeWidth = 2.0);
    canvas.drawLine(Offset(rightPanX + 18, rightPanY - 2), Offset(rightPanX, rightBeamY + 2), Paint()
      ..color = const Color(0xFF8B7355).withValues(alpha: 0.70)..strokeWidth = 2.0);

    // Right pan dish
    final rightPanPath = Path()
      ..moveTo(rightPanX - 22, rightPanY)
      ..quadraticBezierTo(rightPanX, rightPanY + 10, rightPanX + 22, rightPanY);
    canvas.drawPath(rightPanPath, Paint()
      ..color = const Color(0xFF9CA3AF).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round);

    canvas.restore();

    // Shockwave
    // tap-effect removed — smooth calm

    // Particles
    // tap-effect removed — smooth calm

    // Label
    // progress % label removed

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
    const teal = Color(0xFF0D9488);
    const green = Color(0xFF2BAE7C);

    // Responsive sizing based on screen width
    final sw = MediaQuery.of(context).size.width;
    final size = sw < 360 ? 100.0 : sw < 400 ? 110.0 : 120.0;
    final stroke = sw < 360 ? 4.5 : 5.5;
    final countFontSize = sw < 360 ? 28.0 : sw < 400 ? 32.0 : 36.0;
    final labelFontSize = sw < 360 ? 11.0 : 12.5;
    final completedWidth = sw < 360 ? 170.0 : 190.0;
    final completedHeight = sw < 360 ? 58.0 : 64.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: isComplete ? completedWidth : size,
      height: isComplete ? completedHeight : size,
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
                Icon(Icons.check_circle_rounded, color: Colors.white, size: completedHeight * 0.38),
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
                        fontSize: countFontSize,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : teal,
                        height: 1.1,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: teal.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'of $target',
                        style: GoogleFonts.outfit(
                          fontSize: labelFontSize,
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