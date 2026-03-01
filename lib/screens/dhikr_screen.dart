import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../services/xp_service.dart';
import '../services/settings_service.dart';
import '../models/app_config.dart';
import '../utils/asset_helper.dart';

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
  double arabicFontSize;
  double translationFontSize;
  bool darkMode;
  
  _DhikrSettings({
    this.arabicFontSize = 32.0,
    this.translationFontSize = 14.0,
    this.darkMode = false,
  });
}

IconData _parseIcon(String name) {
  switch (name) {
    case 'auto_awesome_rounded': return Icons.auto_awesome_rounded;
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

  @override
  void initState() {
    super.initState();
    _selectedCat = widget.initialCategory;
    _initData();
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
            _Category('general', 'General', Icons.auto_awesome_rounded),
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
    Share.share(text);
  }

  void _tap(String id, int target) {
    HapticFeedback.lightImpact();
    setState(() {
      final current = _counts[id] ?? 0;
      if (current < target) {
        _counts[id] = current + 1;
        if (_counts[id] == target) {
          Future.delayed(const Duration(milliseconds: 200), () => _showCompleteDialog(id, target));
        }
      }
    });
  }

  void _reset(String id) {
    setState(() { _counts[id] = 0; });
  }

  Future<void> _completeDhikr(String dhikrId, int target) async {
    try {
      await XpService.instance.earnDhikrXp(dhikrId);
      if (_setsCompleted == 0) await XpService.instance.awardBadge('first_dhikr');
      if (_setsCompleted + 1 >= 7) await XpService.instance.awardBadge('night_warrior');

      setState(() {
        _pointsToday += 20;
        _setsCompleted += 1;
        _counts[dhikrId] = 0;
      });
    } catch (_) {}
  }

  void _showCompleteDialog(String dhikrId, int target) {
    final xpEarned = XpReward.dhikrXp(dhikrId);
    final isDark = _settings.darkMode;
    final kText = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final kSub = isDark ? Colors.grey.shade400 : const Color(0xFF8E8E93);
    final kBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: kBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Masha\'Allah!',
                style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: kText)),
            const SizedBox(height: 8),
            Text('$target counts complete • +20 Noor Points • +$xpEarned XP',
                style: GoogleFonts.outfit(fontSize: 14, color: kSub),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () { 
                Navigator.pop(context); 
                _completeDhikr(dhikrId, target); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('Claim Rewards',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            )),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () { 
                Navigator.pop(context); 
                setState(() => _counts[dhikrId] = 0); 
              },
              child: Text('Reset', style: GoogleFonts.outfit(color: kSub)),
            ),
          ]),
        ),
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = _settings.darkMode;
          final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final txtColor = isDark ? Colors.white : const Color(0xFF1C1C1E);

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Dua & Azkar Settings', 
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: txtColor)),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: txtColor),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Appearance
                  Text('Appearance', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0D9488))),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Dark Mode', style: GoogleFonts.outfit(fontSize: 16, color: txtColor)),
                    activeColor: const Color(0xFF0D9488),
                    value: _settings.darkMode,
                    onChanged: (val) {
                      setModalState(() => _settings.darkMode = val);
                      setState(() => _settings.darkMode = val);
                      _savePrefs();
                    },
                  ),
                  const Divider(),

                  // Text Sizes
                  const SizedBox(height: 10),
                  Text('Arabic Text Size', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0D9488))),
                  Slider(
                    value: _settings.arabicFontSize,
                    min: 20.0,
                    max: 56.0,
                    activeColor: const Color(0xFF0D9488),
                    onChanged: (val) {
                      setModalState(() => _settings.arabicFontSize = val);
                      setState(() => _settings.arabicFontSize = val);
                      _savePrefs();
                    },
                  ),

                  Text('Translation Text Size', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0D9488))),
                  Slider(
                    value: _settings.translationFontSize,
                    min: 12.0,
                    max: 24.0,
                    activeColor: const Color(0xFF0D9488),
                    onChanged: (val) {
                      setModalState(() => _settings.translationFontSize = val);
                      setState(() => _settings.translationFontSize = val);
                      _savePrefs();
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        }
      )
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F3EE),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))),
      );
    }

    final isDark = _settings.darkMode;
    final kBg    = isDark ? const Color(0xFF121212) : const Color(0xFFF7F3EE);
    final kText  = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final kWhite = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final kSub   = isDark ? Colors.grey.shade400 : const Color(0xFF8E8E93);
    final kPrimary  = const Color(0xFF0D9488);
    final kPrimaryL = isDark ? const Color(0xFF3B2A30) : const Color(0xFFF9D5D8);

    return Scaffold(
      backgroundColor: kBg,
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
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded, color: kText),
            onPressed: _showSettingsSheet,
          )
        ],
      ),
      body: SafeArea(child: Column(children: [

        // ── Points banner (Optional) ────────────────────────────────────────
        if (_pointsToday > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: kPrimaryL, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Text('🌟', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('+$_pointsToday points earned today!',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: kPrimary)),
            ]),
          ),

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
            itemCount: _filtered.length + 1, // +1 for the top illustration header
            itemBuilder: (context, idx) {
              
              // ── Header Element ──
              if (idx == 0) {
                // Safely grab the actual title text for this category:
                final label = _categories.firstWhere((c) => c.id == _selectedCat, orElse: () => _categories.first).label;
                String? autoImagePath = AssetHelper.getCustomImagePath(label);
                
                if (autoImagePath != null) {
                  Color headerColor;
                  String subtitle;

                  // Define aesthetic tweaks depending on the vibe!
                  if (_selectedCat == 'evening') {
                    headerColor = isDark ? const Color(0xFFFDE68A) : const Color(0xFF1E3A8A); // Deep rich blue for evening mood
                    subtitle = 'Recite between Asr and Maghrib';
                  } else if (_selectedCat == 'sleeping') {
                    headerColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A); // Midnight blue
                    subtitle = 'Recite before falling asleep';
                  } else {
                    // Universal automatic matching theme for custom items like 'Morning' or 'Tahajjud'!
                    headerColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
                    subtitle = '${label} Adhkar & Duas';
                  }
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white, // Pure white blends with the image!
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                         BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                      ]
                    ),
                    child: Column(
                      children: [
                        // The user's image goes here implicitly.
                        Image.asset(
                          autoImagePath,
                          height: 160,
                          fit: BoxFit.contain, // Prevent frame/bounds clipping
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            alignment: Alignment.center,
                            child: Text('Add $autoImagePath', 
                                textAlign: TextAlign.center,
                                style: TextStyle(color: kSub, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(label, 
                            style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: headerColor)),
                        const SizedBox(height: 6),
                        Text(subtitle, 
                            style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                      ],
                    ),
                  );
                }
                // Don't render anything for categories right now until images are added
                return const SizedBox.shrink();
              }

              final index = idx - 1; // shift back by 1 because of the header
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
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => DhikrDetailScreen(
                    azkars: _filtered,
                    initialIndex: index,
                    counts: _counts,
                    favorites: _favorites,
                    settings: _settings,
                    parentState: this,
                  )));
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swipable Full Screen Detail Page
// ─────────────────────────────────────────────────────────────────────────────
class DhikrDetailScreen extends StatefulWidget {
  final List<_Azkar> azkars;
  final int initialIndex;
  final Map<String, int> counts;
  final List<String> favorites;
  final _DhikrSettings settings;
  final _DhikrScreenState parentState;

  const DhikrDetailScreen({
     super.key, required this.azkars, required this.initialIndex,
     required this.counts, required this.favorites,
     required this.settings, required this.parentState,
  });

  @override
  State<DhikrDetailScreen> createState() => _DhikrDetailScreenState();
}

class _DhikrDetailScreenState extends State<DhikrDetailScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
      final isDark = widget.settings.darkMode;
      final kBg    = isDark ? const Color(0xFF121212) : const Color(0xFFF7F3EE);
      final kText  = isDark ? Colors.white : const Color(0xFF1C1C1E);
      final kWhite = isDark ? const Color(0xFF1E1E1E) : Colors.white;

      return Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kWhite,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: kText, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Recite', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
          centerTitle: true,
        ),
        body: PageView.builder(
          controller: _pageController,
          itemCount: widget.azkars.length,
          itemBuilder: (context, index) {
            final azkar = widget.azkars[index];
            final count = widget.counts[azkar.id] ?? 0;
            final tapTarget = azkar.recommendedCount;
            final isComplete = count >= tapTarget;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
              child: _AzkarCard(
                azkar: azkar,
                currentCount: count,
                isComplete: isComplete,
                isFavorite: widget.favorites.contains(azkar.id),
                settings: widget.settings,
                onTap: () {
                    widget.parentState._tap(azkar.id, tapTarget);
                    setState((){});
                },
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
            );
          },
        ),
      );
  }
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
  final VoidCallback onTap;
  final VoidCallback onReset;
  final VoidCallback onFavorite;
  final VoidCallback onShare;

  const _AzkarCard({
    required this.azkar,
    required this.currentCount,
    required this.isComplete,
    required this.isFavorite,
    required this.settings,
    required this.onTap,
    required this.onReset,
    required this.onFavorite,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (currentCount / azkar.recommendedCount).clamp(0.0, 1.0);

    final isDark = settings.darkMode;
    final kCardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final kText  = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final kSub   = isDark ? Colors.grey.shade400 : const Color(0xFF8E8E93);
    final kPrimary  = const Color(0xFF0D9488);
    final kPrimaryL = isDark ? const Color(0xFF3B2A30) : const Color(0xFFF9D5D8);
    final kGold  = const Color(0xFFD4AF37);
    final kBeneBg = isDark ? const Color(0xFF2A2416) : const Color(0xFFFBF8F1);
    final kBeneTxt = isDark ? const Color(0xFFEADBBE) : const Color(0xFF5A4D2E);

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20, 
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // ── Top Bar (Count Goal & Header) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isComplete ? (isDark ? const Color(0xFF1E4031) : const Color(0xFFE8F8F0)) : kPrimaryL.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isComplete ? 'Completed ✓' : 'Target: ${azkar.recommendedCount}',
                      style: GoogleFonts.outfit(
                        fontSize: 12, 
                        fontWeight: FontWeight.w700, 
                        color: isComplete ? const Color(0xFF2BAE7C) : kPrimary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Favorite
                  IconButton(
                    onPressed: onFavorite,
                    icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded, 
                               size: 20, color: isFavorite ? const Color(0xFF0D9488) : Colors.grey.shade400),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    splashRadius: 20,
                  ),
                  
                  // Share
                  IconButton(
                    onPressed: onShare,
                    icon: Icon(Icons.ios_share_rounded, size: 20, color: Colors.grey.shade400),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    splashRadius: 20,
                  ),
                  
                  // Refresh/Reset
                  IconButton(
                    onPressed: onReset,
                    icon: Icon(Icons.refresh_rounded, size: 20, color: Colors.grey.shade400),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            // ── Main Text Content ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    azkar.arabic,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: settings.arabicFontSize, 
                      fontWeight: FontWeight.w700, 
                      color: kText, 
                      height: 1.8
                    ),
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
                  if (azkar.reward.isEmpty && azkar.reference.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      azkar.reference,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimary),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Highly Visible Benefit Box ──
            if (azkar.reward.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kBeneBg, 
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kGold.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Virtue & Benefit', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: kGold)),
                          const SizedBox(height: 4),
                          Text(azkar.reward, style: GoogleFonts.outfit(fontSize: 13, color: kBeneTxt, height: 1.5)),
                          if (azkar.reference.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                azkar.reference,
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimary),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),

            // ── Interactive Count Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: GestureDetector(
                onTap: isComplete ? null : onTap,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    decoration: BoxDecoration(
                      color: isComplete ? const Color(0xFF2BAE7C) : kPrimary,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: isComplete ? [] : [
                        BoxShadow(
                          color: kPrimary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Text(
                      isComplete ? 'Completed ✓' : '$currentCount / ${azkar.recommendedCount}',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            )
            
          ],
        ),
      ),
    );
  }
}
