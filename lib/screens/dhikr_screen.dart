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
  final Map<String, int> _customTargets = {};
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
              final tapTarget = _getTarget(azkar.id, azkar.recommendedCount);
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
              int currentIndex = _pageController.positions.isNotEmpty ? _pageController.page?.round() ?? widget.initialIndex : widget.initialIndex;
              final catId = widget.azkars[currentIndex].category;
              final catObj = widget.parentState._categories.cast<_Category?>().firstWhere((c) => c?.id == catId, orElse: () => null);
              final String catLabel = catObj?.label ?? 'Dhikr & Dua';
              return Text(catLabel, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.90)));
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

  for (final m in _kHighlightPatterns.allMatches(cleaned)) {
    if (m.start > lastEnd) {
      spans.add(TextSpan(text: cleaned.substring(lastEnd, m.start)));
    }
    spans.add(TextSpan(
      text: m.group(0),
      style: baseStyle.copyWith(color: highlightColor),
    ));
    lastEnd = m.end;
  }
  if (lastEnd < cleaned.length) {
    spans.add(TextSpan(text: cleaned.substring(lastEnd)));
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
  final id = azkarId.toLowerCase();
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
  final id = azkarId.toLowerCase();
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
  // Default: Noor Tree
  return _NoorTree(
    progress: progress,
    isComplete: isComplete,
    tapCount: tapCount,
    pointsToday: pointsToday,
  );
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
        style: TextStyle(
          color: isComplete
              ? const Color(0xFFD4AF37)
              : Colors.white.withValues(alpha: 0.82),
          fontSize: isComplete ? 12 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.86));

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
      final badgeY = h * 0.86 + tp2.height + 4;
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
        style: TextStyle(
          color: isComplete
              ? const Color(0xFFD4AF37)
              : Colors.white.withValues(alpha: 0.82),
          fontSize: isComplete ? 12 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.86));

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
      final badgeY = h * 0.86 + tp2.height + 4;
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
        style: TextStyle(
          color: isComplete
              ? const Color(0xFFD4AF37)
              : Colors.white.withValues(alpha: 0.82),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.86));

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
      final badgeY = h * 0.86 + tp2.height + 4;
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
        style: TextStyle(
          color: isComplete
              ? const Color(0xFF10B981)
              : Colors.white.withValues(alpha: 0.82),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.86));

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
      final badgeY = h * 0.86 + tp2.height + 4;
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
      text: TextSpan(text: label, style: TextStyle(
        color: isComplete ? const Color(0xFF2EC4A9) : Colors.white.withValues(alpha: 0.82),
        fontSize: 12, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.86));

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
      final badgeY = h * 0.86 + tp2.height + 4;
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
          text: TextSpan(text: _wardLabels[i], style: TextStyle(
            color: color.withValues(alpha: 0.55),
            fontSize: 8, fontWeight: FontWeight.w700)),
          textDirection: TextDirection.rtl,
        )..layout();
        tp.paint(canvas, Offset(wx - tp.width / 2, wy + panelSize + 3));
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
      text: TextSpan(text: label, style: TextStyle(
        color: isComplete ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.82),
        fontSize: 12, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.86));

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
      final badgeY = h * 0.86 + tp2.height + 4;
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
      text: TextSpan(text: label, style: TextStyle(
        color: isComplete ? const Color(0xFFE879F9) : Colors.white.withValues(alpha: 0.82),
        fontSize: 12, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.86));

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
      final badgeY = h * 0.86 + tp2.height + 4;
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
      text: TextSpan(text: label, style: TextStyle(
        color: isComplete ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.82),
        fontSize: 12, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.86));

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
      final badgeX = cx - badgeW / 2; final badgeY = h * 0.86 + tp2.height + 4;
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
      text: TextSpan(text: label, style: TextStyle(
        color: isComplete ? const Color(0xFFFFD97D) : Colors.white.withValues(alpha: 0.82),
        fontSize: 12, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.86));

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
      final badgeX = cx - badgeW / 2; final badgeY = h * 0.86 + tp2.height + 4;
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
      text: TextSpan(text: label, style: TextStyle(
        color: isComplete ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.82),
        fontSize: 12, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.rtl,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.86));

    if (pointsToday > 0) {
      final badgeLabel = '+$pointsToday pts';
      final tp3 = TextPainter(
        text: TextSpan(text: badgeLabel, style: const TextStyle(
          color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w800,
          letterSpacing: 0.5, shadows: [Shadow(color: Color(0xFFD4AF37), blurRadius: 6)])),
        textDirection: TextDirection.ltr,
      )..layout();
      final badgeW = tp3.width + 10; final badgeH = tp3.height + 6;
      final badgeX = cx - badgeW / 2; final badgeY = h * 0.86 + tp2.height + 4;
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
