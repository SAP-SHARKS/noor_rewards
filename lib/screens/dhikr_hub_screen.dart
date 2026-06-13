import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dhikr_screen.dart';
import 'akhirah_balance_screen.dart';
import '../utils/asset_helper.dart';
import '../widgets/noor_icons.dart';
import '../widgets/dhikr_exit_celebration.dart';
import '../services/settings_service.dart';
import '../services/streak_service.dart';
import '../models/app_config.dart';
import '../l10n/app_localizations.dart';
import '../widgets/noor_offline.dart';
import '../theme/y4_theme.dart';

AppConfig get _dhcfg => SettingsService.instance.config;
Color get _kBg => _dhcfg.dashBg;

class DhikrHubScreen extends StatefulWidget {
  const DhikrHubScreen({super.key});
  @override
  State<DhikrHubScreen> createState() => _DhikrHubScreenState();
}

class _DhikrHubScreenState extends State<DhikrHubScreen> {
  Set<String>? _hiddenIds;

  // ── Session accumulators ───────────────────────────────────────────────
  // Each category visit (DhikrScreen) pops back with the points it earned
  // and the number of zikr sets completed in that visit. We sum across
  // visits so the celebration on hub exit reflects the WHOLE Dua & Zikar
  // session, not the last category alone.
  int _sessionPoints = 0;
  int _sessionSets = 0;
  int _sessionSeconds = 0;
  bool _isExitingHub = false;

  @override
  void initState() {
    super.initState();
    _loadVisibility();
  }

  Future<void> _openCategory(String id) async {
    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => DhikrScreen(initialCategory: id)),
    );
    // DhikrScreen pops with {points, sets, seconds}. Accumulate. (Old
    // contract was a single int = points, so accept that shape too.)
    if (result is Map) {
      _sessionPoints += (result['points'] as int?) ?? 0;
      _sessionSets += (result['sets'] as int?) ?? 0;
      _sessionSeconds += (result['seconds'] as int?) ?? 0;
    } else if (result is int) {
      _sessionPoints += result;
    }
  }

  // Daily dhikr-time persistence. We store accumulated seconds keyed by
  // today's date so the Akhirah summary can show "Time spent today" that
  // accurately reflects multiple sessions through the day, not just the
  // one the user just finished.
  static const String _kDhikrSecondsPrefix = 'dhikr_seconds_';
  static String _todayKey() {
    final n = DateTime.now();
    return '$_kDhikrSecondsPrefix${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  Future<int> _bumpAndReadTodaySeconds(int add) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _todayKey();
      final prev = prefs.getInt(key) ?? 0;
      final next = prev + add;
      await prefs.setInt(key, next);
      return next;
    } catch (_) {
      return add;
    }
  }

  // Fires the two-popup celebration if the user actually completed any zikr
  // set during this hub session, then pops the hub. Returns false to let
  // PopScope handle the actual pop after our async work is done.
  Future<bool> _handleHubExit() async {
    if (_isExitingHub) return false;
    _isExitingHub = true;
    if (_sessionSets <= 0) {
      // No completed sets — just pop silently.
      if (mounted) Navigator.of(context).pop(_sessionPoints);
      return false;
    }

    int streakDays = 0;
    try {
      final snap = await StreakService.instance.loadSnapshot().timeout(
        const Duration(seconds: 2),
      );
      streakDays = snap.dhikr;
    } catch (_) {
      // Don't block the exit on a network hiccup.
    }
    if (!mounted) return false;

    // Persist session seconds into today's cumulative total before
    // surfacing the summary so the pill shows the *whole* day.
    final todaySeconds = await _bumpAndReadTodaySeconds(_sessionSeconds);
    if (!mounted) return false;

    await showDhikrExitCelebration(
      context,
      pointsEarned: _sessionPoints,
      streakDays: streakDays,
    );
    if (!mounted) return false;

    // Replace the hub with the Akhirah Balance summary; it pops back
    // with `_sessionPoints` so the dashboard refresh path still works.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AkhirahBalanceScreen(
          sessionPoints: _sessionPoints,
          popResult: _sessionPoints,
          dhikrSecondsToday: todaySeconds,
        ),
      ),
      result: _sessionPoints,
    );
    return false;
  }

  // Translates a category by its stable Supabase `id` (not the English label).
  // Fallback is the original English title so unmapped admin-added categories
  // still render.
  String _localTitle(String title, [String? id]) {
    final l = AppLocalizations.of(context);
    if (l == null) return title;
    switch (id ?? '') {
      case 'morning':
        return l.morning;
      case 'evening':
        return l.evening;
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
      case 'general':
        return l.dhikarAllTimes;
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
        // Legacy fallback for the few places still passing only the English
        // title without an id.
        if (title == 'Morning') return l.morning;
        if (title == 'Evening') return l.evening;
        return title;
    }
  }

  Future<void> _loadVisibility() async {
    try {
      final res = await Supabase.instance.client
          .from('azkar_categories')
          .select('id, is_visible');
      if (!mounted) return;
      final hidden = <String>{};
      for (final r in (res as List)) {
        if (r['is_visible'] == false) hidden.add(r['id'] as String);
      }
      setState(() => _hiddenIds = hidden);
    } catch (_) {
      if (mounted) setState(() => _hiddenIds = <String>{});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hiddenIds == null) {
      return Scaffold(
        backgroundColor: _kBg,
        body: const Center(child: NoorInlineLoader()),
      );
    }
    // Y4-tuned palette: warm/sun categories use honey, night categories use sage.
    // Per-category color identity is preserved but routed through the Y4 token set.
    final List<Map<String, dynamic>> essentials = [
      {
        'title': AppLocalizations.of(context)?.duasOfUmmah ?? 'Duas of Ummah',
        'id': 'ummah',
        'color': Y4.primary,
        'icon': '🌍',
      },
      {
        'title': 'Morning',
        'id': 'morning',
        'color': Y4.honeyDeep,
        'icon': '🌅',
      },
      {'title': 'Evening', 'id': 'evening', 'color': Y4.amberY, 'icon': '🌇'},
      {
        'title': 'Duas before Sleep',
        'id': 'duas_before_sleep',
        'color': Y4.primaryDeep,
        'icon': '🌌',
      },
      {
        'title': AppLocalizations.of(context)?.tahajjud ?? 'Tahajjud',
        'id': 'tahajjud',
        'color': Y4.primaryDeep,
        'icon': '🌑',
      },
      {
        'title': 'Duas after Salah',
        'id': 'duas_after_salah',
        'color': Y4.primary,
        'icon': '🕌',
      },
      {
        'title': AppLocalizations.of(context)?.salawat ?? 'Salawat',
        'id': 'salawat',
        'color': Y4.honeyDeep,
        'icon': '❤️',
      },
      {
        'title': AppLocalizations.of(context)?.sunnahDuas ?? 'Sunnah Duas',
        'id': 'sunnah',
        'color': Y4.primary,
        'icon': '📖',
      },
      {
        'title': '40 Rabbana Duas',
        'id': 'rabbana_40',
        'color': Y4.primaryDeep,
        'icon': '📜',
      },
      {
        'title': AppLocalizations.of(context)?.istighfar ?? 'Istighfar',
        'id': 'istighfar',
        'color': Y4.soil,
        'icon': '📿',
      },
      {
        'title': 'Daily Duas',
        'id': 'daily_duas',
        'color': Y4.honeyDeep,
        'icon': '✨',
      },
      {
        'title': 'Ruquiya',
        'id': 'ruquiya',
        'color': Y4.primaryDeep,
        'icon': '🛡️',
      },
      {
        'title':
            AppLocalizations.of(context)?.dhikarAllTimes ?? 'Dhikar All Times',
        'id': 'general',
        'color': Y4.amberY,
        'icon': '🤲',
      },
      {
        'title': AppLocalizations.of(context)?.namesOfAllah ?? 'Names of Allah',
        'id': 'asmaul_husna',
        'color': Y4.honeyDeep,
        'icon': '✨',
      },
    ];

    // Mini cards in "Other Categories" â€” Y4 palette with subtle hue variation.
    // We rotate through a small set of Y4 tokens so each tile still feels
    // distinct without breaking the honey/sage cohesion.
    const altPrimary = Y4.primary; // sage
    const altPrimaryD = Y4.primaryDeep; // deep sage
    const altHoney = Y4.honeyDeep; // honey-deep
    const altAmber = Y4.amberY; // soft amber
    const altSoil = Y4.soil; // warm earth
    const altSoilD = Y4.soilDeep; // deep earth

    final List<Map<String, dynamic>> others = [
      {
        'title': AppLocalizations.of(context)?.nightmares ?? 'Nightmares',
        'id': 'nightmares',
        'color': altSoilD,
        'icon': '🌩️',
      },
      {
        'title': AppLocalizations.of(context)?.wakingUp ?? 'Waking up',
        'id': 'waking_up',
        'color': altHoney,
        'icon': '☀️',
      },
      {
        'title': AppLocalizations.of(context)?.clothes ?? 'Clothes',
        'id': 'clothes',
        'color': altPrimary,
        'icon': '👕',
      },
      {
        'title': AppLocalizations.of(context)?.wudu ?? 'Wudu',
        'id': 'wudu',
        'color': altPrimary,
        'icon': '💧',
      },
      {
        'title': AppLocalizations.of(context)?.foodAndDrink ?? 'Food & Drink',
        'id': 'food_drink',
        'color': altAmber,
        'icon': '🍽️',
      },
      {
        'title': AppLocalizations.of(context)?.home ?? 'Home',
        'id': 'home',
        'color': altPrimary,
        'icon': '🏠',
      },
      {
        'title': AppLocalizations.of(context)?.istikharah ?? 'Istikharah',
        'id': 'istikharah',
        'color': altPrimaryD,
        'icon': '🧭',
      },
      {
        'title':
            AppLocalizations.of(context)?.adaanAndMasjid ?? 'Adaan & Masjid',
        'id': 'masjid',
        'color': altPrimary,
        'icon': '🕌',
      },
      {
        'title': AppLocalizations.of(context)?.diffAndHappy ?? 'Diff & Happy',
        'id': 'difficulty',
        'color': altHoney,
        'icon': '⚖️',
      },
      {
        'title': AppLocalizations.of(context)?.imanProtect ?? 'Iman Protect',
        'id': 'iman_protection',
        'color': altPrimaryD,
        'icon': '🛡️',
      },
      {
        'title': AppLocalizations.of(context)?.travel ?? 'Travel',
        'id': 'travel',
        'color': altPrimary,
        'icon': '✈️',
      },
      {
        'title': AppLocalizations.of(context)?.shopping ?? 'Shopping',
        'id': 'shopping',
        'color': altAmber,
        'icon': '🛍️',
      },
      {
        'title': AppLocalizations.of(context)?.marriage ?? 'Marriage',
        'id': 'family',
        'color': altHoney,
        'icon': '👨‍👩‍👧',
      },
      {
        'title': AppLocalizations.of(context)?.social ?? 'Social',
        'id': 'social',
        'color': altPrimary,
        'icon': '🤝',
      },
      {
        'title': AppLocalizations.of(context)?.nature ?? 'Nature',
        'id': 'nature',
        'color': altPrimary,
        'icon': '🌿',
      },
      {
        'title': AppLocalizations.of(context)?.death ?? 'Death',
        'id': 'death',
        'color': altSoil,
        'icon': '🥀',
      },
      {
        'title': AppLocalizations.of(context)?.gatherings ?? 'Gatherings',
        'id': 'gatherings',
        'color': altHoney,
        'icon': '👥',
      },
      {
        'title': AppLocalizations.of(context)?.hajjAndUmrah ?? 'Hajj & Umrah',
        'id': 'hajj',
        'color': altPrimaryD,
        'icon': '🕋',
      },
    ];

    final visibleEssentials =
        essentials.where((e) => !_hiddenIds!.contains(e['id'])).toList();
    final visibleOthers =
        others.where((e) => !_hiddenIds!.contains(e['id'])).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleHubExit();
      },
      child: Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Y4.bg,
        surfaceTintColor: Y4.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Y4.ink,
            size: 20,
          ),
          onPressed: _handleHubExit,
        ),
        title: Text(
          AppLocalizations.of(context)?.dhikarAndDua ?? 'Dhikar & Dua',
          style: Y4.display(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Y4.ink,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive columns for essentials based on count
          final essCount = visibleEssentials.length;
          final int essCols;
          final double essAspect;
          if (essCount <= 2) {
            essCols = 1;
            essAspect = 1.8;
          } else {
            essCols = 2;
            essAspect = 0.9;
          }

          // Responsive columns for others based on count
          final othCount = visibleOthers.length;
          final int othCols;
          final double othAspect;
          if (othCount <= 2) {
            othCols = 2;
            othAspect = 1.1;
          } else {
            othCols = 3;
            othAspect = 0.85;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: AppLocalizations.of(context)?.dailyWordPrefix ??
                            'Daily ',
                        style: Y4.display(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Y4.ink,
                          height: 1.0,
                        ),
                      ),
                      TextSpan(
                        text: AppLocalizations.of(context)?.essentialsWord ??
                            'Essentials',
                        style: Y4.display(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Y4.ink,
                          fontStyle: FontStyle.italic,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (visibleEssentials.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      AppLocalizations.of(context)?.noCategoriesAvailable ??
                          'No categories available.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: essCols,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: essAspect,
                    ),
                    itemCount: visibleEssentials.length,
                    itemBuilder: (context, index) {
                      final item = visibleEssentials[index];
                      // Pass the ENGLISH title — the card builder needs it
                      // for asset filename lookup (e.g. "Duas before Sleep.png").
                      // It computes the localized display label internally
                      // using the stable category id.
                      return _buildGradientCard(
                        context,
                        item['title'] as String,
                        item['id'],
                        item['icon'],
                        item['color'],
                        isStacked: essCols == 1,
                      );
                    },
                  ),

                const SizedBox(height: 32),
                Builder(
                  builder: (ctx) {
                    final full =
                        AppLocalizations.of(ctx)?.otherCategories ??
                        'Other Categories';
                    // Split on first space so localized strings still get the
                    // italic-on-second-word treatment.
                    final spaceIdx = full.indexOf(' ');
                    final first =
                        spaceIdx < 0 ? full : full.substring(0, spaceIdx + 1);
                    final rest =
                        spaceIdx < 0 ? '' : full.substring(spaceIdx + 1);
                    return RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: first,
                            style: Y4.display(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Y4.ink,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: rest,
                            style: Y4.display(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Y4.ink,
                              fontStyle: FontStyle.italic,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (visibleOthers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      AppLocalizations.of(context)?.noCategoriesAvailable ??
                          'No categories available.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: othCols,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: othAspect,
                    ),
                    itemCount: visibleOthers.length,
                    itemBuilder: (context, index) {
                      final item = visibleOthers[index];
                      // Pass the ENGLISH title — see _buildGradientCard
                      // comment above for the reason.
                      return _buildMiniGradientCard(
                        context,
                        item['title'] as String,
                        item['id'],
                        item['icon'],
                        item['color'],
                      );
                    },
                  ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildGradientCard(
    BuildContext context,
    String title,
    String id,
    String emoji,
    Color baseColor, {
    bool isStacked = false,
  }) {
    // Try the ID first (e.g. 'morning' -> morning_header.png via legacy
    // map), then fall back to the label (e.g. 'Duas before Sleep' ->
    // 'Duas before Sleep.png' which the user added with spaces in the
    // filename, matched via the lowercase query in AssetHelper).
    String? customImagePath =
        AssetHelper.getCustomImagePath(id) ??
        AssetHelper.getCustomImagePath(title);
    bool isCustomCard = customImagePath != null;
    Color? customTextColor;

    // New screenshot-imported categories that don't have a PNG yet fall
    // through to a clean white card with emoji watermark, instead of the
    // dark colored gradient. Drops out automatically once the user adds
    // a matching image into assets/images/.
    const _whiteIds = {
      'duas_before_sleep',
      'duas_after_salah',
      'daily_duas',
      'rabbana_40',
      'ruquiya',
    };
    final bool isWhiteCard = !isCustomCard && _whiteIds.contains(id);

    if (isCustomCard) {
      if (id == 'evening') {
        customTextColor = const Color(0xFF7A5200); // Deep blue
      } else if (id == 'sleeping') {
        customTextColor = const Color(0xFF5E3F00); // Midnight blue
      } else {
        customTextColor =
            baseColor.computeLuminance() > 0.5 ? Colors.black87 : baseColor;
      }
    }

    final double imgWidth = isStacked ? 180 : 120;
    final double imgBottom = isStacked ? 10 : 30;
    final double titleSize = isStacked ? 26 : 18;
    final double emojiSize = isStacked ? 130 : 90;

    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return GestureDetector(
      onTap: () => _openCategory(id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: (isCustomCard || isWhiteCard) ? Colors.white : null,
          gradient:
              (isCustomCard || isWhiteCard)
                  ? null
                  : LinearGradient(
                    colors: [baseColor, baseColor.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: isWhiteCard ? 0.18 : 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Vibrant emoji watermark mimicking a 3D character glow OR custom image
              if (isCustomCard)
                Positioned(
                  top: 0,
                  right: isRtl ? null : -10,
                  left: isRtl ? -10 : null,
                  bottom: imgBottom,
                  width: imgWidth,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      customImagePath,
                      fit: BoxFit.contain,
                      alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
                    ),
                  ),
                )
              else if (isWhiteCard)
                // Soft emoji watermark in the tile's accent color so the
                // white card still has visual identity without an image.
                Positioned(
                  right: -10,
                  top: -10,
                  child: Opacity(
                    opacity: 0.85,
                    child: SizedBox(
                      width: emojiSize * 0.95,
                      height: emojiSize * 0.95,
                      child: NoorIcon.fromEmoji(emoji, size: emojiSize * 0.95),
                    ),
                  ),
                )
              else
                Positioned(
                  right: -20,
                  bottom: -15,
                  child: Opacity(
                    opacity: 0.55,
                    child: SizedBox(
                      width: emojiSize,
                      height: emojiSize,
                      child: NoorIcon.fromEmoji(emoji, size: emojiSize),
                    ),
                  ),
                ),
              // Glassmorphic protection mask (only keep it for non-image cards, or make it subtle)
              if (isCustomCard)
                // Ensure the text has a solid readable white background area that fades into the image
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withValues(alpha: 0.8),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                )
              else if (!isWhiteCard)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _localTitle(title, id),
                      style: GoogleFonts.outfit(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        color: isCustomCard
                            ? customTextColor
                            : (isWhiteCard ? Y4.ink : Colors.white),
                        height: 1.1,
                        letterSpacing: -0.5,
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

  Widget _buildMiniGradientCard(
    BuildContext context,
    String title,
    String id,
    String emoji,
    Color baseColor,
  ) {
    // Mirror _buildGradientCard's image-resolution + white-card logic so
    // mini-tiles in "Other Categories" can also pick up user-added PNG
    // headers (e.g. assets/images/Ruquiya.png) and fall back to a white
    // emoji card when no image exists.
    final String? customImagePath =
        AssetHelper.getCustomImagePath(id) ??
        AssetHelper.getCustomImagePath(title);
    final bool isCustomCard = customImagePath != null;
    const _whiteIds = {
      'duas_before_sleep',
      'duas_after_salah',
      'daily_duas',
      'rabbana_40',
      'ruquiya',
    };
    final bool isWhiteCard = !isCustomCard && _whiteIds.contains(id);

    return GestureDetector(
      onTap: () => _openCategory(id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: (isCustomCard || isWhiteCard) ? Colors.white : null,
          gradient: (isCustomCard || isWhiteCard)
              ? null
              : LinearGradient(
                  colors: [baseColor, baseColor.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: isWhiteCard ? 0.15 : 0.2),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (isCustomCard)
                Positioned.fill(
                  bottom: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Image.asset(
                      customImagePath,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                )
              else
                Positioned(
                  right: isWhiteCard ? -6 : -10,
                  top: isWhiteCard ? -6 : null,
                  bottom: isWhiteCard ? null : -10,
                  child: Opacity(
                    opacity: isWhiteCard ? 0.85 : 0.6,
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: NoorIcon.fromEmoji(emoji, size: 60),
                    ),
                  ),
                ),
              // Glassmorphic protection mask — only for colored gradient
              // cards. White / image cards don't need a dark overlay.
              if (!isWhiteCard && !isCustomCard)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    _localTitle(title, id),
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: (isWhiteCard || isCustomCard) ? Y4.ink : Colors.white,
                      height: 1.1,
                      letterSpacing: -0.3,
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
}
