import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dhikr_screen.dart';
import '../utils/asset_helper.dart';
import '../widgets/noor_icons.dart';
import '../services/settings_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadVisibility();
  }

  String _localTitle(String title) {
    final l = AppLocalizations.of(context);
    if (title == 'Morning') return l?.morning ?? title;
    if (title == 'Evening') return l?.evening ?? title;
    return title;
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
        'icon': 'ðŸŒ',
      },
      {
        'title': 'Morning',
        'id': 'morning',
        'color': Y4.honeyDeep,
        'icon': 'ðŸŒ…',
      },
      {'title': 'Evening', 'id': 'evening', 'color': Y4.amberY, 'icon': 'ðŸŒ‡'},
      {
        'title': AppLocalizations.of(context)?.beforeSleepCat ?? 'Before Sleep',
        'id': 'sleeping',
        'color': Y4.primaryDeep,
        'icon': 'ðŸŒŒ',
      },
      {
        'title': AppLocalizations.of(context)?.tahajjud ?? 'Tahajjud',
        'id': 'tahajjud',
        'color': Y4.primaryDeep,
        'icon': 'ðŸŒ‘',
      },
      {
        'title': AppLocalizations.of(context)?.salah ?? 'Salah',
        'id': 'post_prayer',
        'color': Y4.primary,
        'icon': 'ðŸ•Œ',
      },
      {
        'title': AppLocalizations.of(context)?.salawat ?? 'Salawat',
        'id': 'salawat',
        'color': Y4.honeyDeep,
        'icon': 'â¤ï¸',
      },
      {
        'title': AppLocalizations.of(context)?.sunnahDuas ?? 'Sunnah Duas',
        'id': 'sunnah',
        'color': Y4.primary,
        'icon': 'ðŸ“–',
      },
      {
        'title': AppLocalizations.of(context)?.quranicDuas ?? 'Quranic Duas',
        'id': 'quranic',
        'color': Y4.primaryDeep,
        'icon': 'ðŸ“—',
      },
      {
        'title': AppLocalizations.of(context)?.istighfar ?? 'Istighfar',
        'id': 'istighfar',
        'color': Y4.soil,
        'icon': 'ðŸ“¿',
      },
      {
        'title':
            AppLocalizations.of(context)?.dhikarAllTimes ?? 'Dhikar All Times',
        'id': 'general',
        'color': Y4.amberY,
        'icon': 'ðŸ¤²',
      },
      {
        'title': AppLocalizations.of(context)?.namesOfAllah ?? 'Names of Allah',
        'id': 'asmaul_husna',
        'color': Y4.honeyDeep,
        'icon': 'âœ¨',
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
        'icon': 'ðŸŒ©ï¸',
      },
      {
        'title': AppLocalizations.of(context)?.wakingUp ?? 'Waking up',
        'id': 'waking_up',
        'color': altHoney,
        'icon': 'â˜€ï¸',
      },
      {
        'title': AppLocalizations.of(context)?.clothes ?? 'Clothes',
        'id': 'clothes',
        'color': altPrimary,
        'icon': 'ðŸ‘•',
      },
      {
        'title': AppLocalizations.of(context)?.wudu ?? 'Wudu',
        'id': 'wudu',
        'color': altPrimary,
        'icon': 'ðŸ’§',
      },
      {
        'title': AppLocalizations.of(context)?.foodAndDrink ?? 'Food & Drink',
        'id': 'food_drink',
        'color': altAmber,
        'icon': 'ðŸ½ï¸',
      },
      {
        'title': AppLocalizations.of(context)?.home ?? 'Home',
        'id': 'home',
        'color': altPrimary,
        'icon': 'ðŸ ',
      },
      {
        'title': AppLocalizations.of(context)?.istikharah ?? 'Istikharah',
        'id': 'istikharah',
        'color': altPrimaryD,
        'icon': 'ðŸ§­',
      },
      {
        'title':
            AppLocalizations.of(context)?.adaanAndMasjid ?? 'Adaan & Masjid',
        'id': 'masjid',
        'color': altPrimary,
        'icon': 'ðŸ•Œ',
      },
      {
        'title': AppLocalizations.of(context)?.diffAndHappy ?? 'Diff & Happy',
        'id': 'difficulty',
        'color': altHoney,
        'icon': 'âš–ï¸',
      },
      {
        'title': AppLocalizations.of(context)?.imanProtect ?? 'Iman Protect',
        'id': 'iman_protection',
        'color': altPrimaryD,
        'icon': 'ðŸ›¡ï¸',
      },
      {
        'title': AppLocalizations.of(context)?.travel ?? 'Travel',
        'id': 'travel',
        'color': altPrimary,
        'icon': 'âœˆï¸',
      },
      {
        'title': AppLocalizations.of(context)?.shopping ?? 'Shopping',
        'id': 'shopping',
        'color': altAmber,
        'icon': 'ðŸ›ï¸',
      },
      {
        'title': AppLocalizations.of(context)?.marriage ?? 'Marriage',
        'id': 'family',
        'color': altHoney,
        'icon': 'ðŸ‘¨â€ðŸ‘©â€ðŸ‘§',
      },
      {
        'title': AppLocalizations.of(context)?.social ?? 'Social',
        'id': 'social',
        'color': altPrimary,
        'icon': 'ðŸ¤',
      },
      {
        'title': AppLocalizations.of(context)?.nature ?? 'Nature',
        'id': 'nature',
        'color': altPrimary,
        'icon': 'ðŸŒ¿',
      },
      {
        'title': AppLocalizations.of(context)?.death ?? 'Death',
        'id': 'death',
        'color': altSoil,
        'icon': 'ðŸ¥€',
      },
      {
        'title': AppLocalizations.of(context)?.gatherings ?? 'Gatherings',
        'id': 'gatherings',
        'color': altHoney,
        'icon': 'ðŸ‘¥',
      },
      {
        'title': AppLocalizations.of(context)?.hajjAndUmrah ?? 'Hajj & Umrah',
        'id': 'hajj',
        'color': altPrimaryD,
        'icon': 'ðŸ•‹',
      },
    ];

    final visibleEssentials =
        essentials.where((e) => !_hiddenIds!.contains(e['id'])).toList();
    final visibleOthers =
        others.where((e) => !_hiddenIds!.contains(e['id'])).toList();

    return Scaffold(
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Dhikar & Dua',
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
                        text: 'Daily ',
                        style: Y4.display(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Y4.ink,
                          height: 1.0,
                        ),
                      ),
                      TextSpan(
                        text: 'Essentials',
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
                      return _buildGradientCard(
                        context,
                        _localTitle(item['title']),
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
                      return _buildMiniGradientCard(
                        context,
                        _localTitle(item['title']),
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
    String? customImagePath = AssetHelper.getCustomImagePath(title);
    bool isCustomCard = customImagePath != null;
    Color? customTextColor;

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

    return GestureDetector(
      onTap:
          () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => DhikrScreen(initialCategory: id)),
          ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isCustomCard ? Colors.white : null,
          gradient:
              isCustomCard
                  ? null
                  : LinearGradient(
                    colors: [baseColor, baseColor.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.3),
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
                  right: -10,
                  bottom: imgBottom,
                  width: imgWidth,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      customImagePath,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerRight,
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
              if (!isCustomCard)
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
                )
              else
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
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        color: isCustomCard ? customTextColor : Colors.white,
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
    return GestureDetector(
      onTap:
          () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => DhikrScreen(initialCategory: id)),
          ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [baseColor, baseColor.withValues(alpha: 0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Opacity(
                  opacity: 0.6,
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: NoorIcon.fromEmoji(emoji, size: 60),
                  ),
                ),
              ),
              // Glassmorphic protection mask
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
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
