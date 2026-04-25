import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dhikr_screen.dart';
import '../utils/asset_helper.dart';
import '../widgets/noor_icons.dart';
import '../services/settings_service.dart';
import '../models/app_config.dart';

AppConfig get _dhcfg => SettingsService.instance.config;
Color get _kBg => _dhcfg.dashBg;
Color get _kText => _dhcfg.dashText;

class DhikrHubScreen extends StatefulWidget {
  const DhikrHubScreen({super.key});
  @override State<DhikrHubScreen> createState() => _DhikrHubScreenState();
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
      final res = await Supabase.instance.client.from('azkar_categories').select('id, is_visible');
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
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF6B4EE6))),
      );
    }
    final List<Map<String, dynamic>> essentials = [
      {'title': 'Duas of Ummah', 'id': 'ummah', 'color': const Color(0xFF6B4EE6), 'icon': '🌍'},
      {'title': 'Morning', 'id': 'morning', 'color': const Color(0xFFF59E0B), 'icon': '🌅'},
      {'title': 'Evening', 'id': 'evening', 'color': const Color(0xFFD97706), 'icon': '🌇'},
      {'title': 'Before Sleep', 'id': 'sleeping', 'color': const Color(0xFF312E81), 'icon': '🌌'},
      {'title': 'Tahajjud', 'id': 'tahajjud', 'color': const Color(0xFF1E1B4B), 'icon': '🌑'},
      {'title': 'Salah', 'id': 'post_prayer', 'color': const Color(0xFF0EA5E9), 'icon': '🕌'},
      {'title': 'Salawat', 'id': 'salawat', 'color': const Color(0xFFEC4899), 'icon': '❤️'},
      {'title': 'Sunnah Duas', 'id': 'sunnah', 'color': const Color(0xFF10B981), 'icon': '📖'},
      {'title': 'Quranic Duas', 'id': 'quranic', 'color': const Color(0xFF059669), 'icon': '📗'},
      {'title': 'Istighfar', 'id': 'istighfar', 'color': const Color(0xFF64748B), 'icon': '📿'},
      {'title': 'Dhikar All Times', 'id': 'general', 'color': const Color(0xFF8B5CF6), 'icon': '🤲'},
      {'title': 'Names of Allah', 'id': 'asmaul_husna', 'color': const Color(0xFFD946EF), 'icon': '✨'},
    ];

    final List<Map<String, dynamic>> others = [
      {'title': 'Nightmares', 'id': 'nightmares', 'color': const Color(0xFF334155), 'icon': '🌩️'},
      {'title': 'Waking up', 'id': 'waking_up', 'color': const Color(0xFFFCD34D), 'icon': '☀️'},
      {'title': 'Clothes', 'id': 'clothes', 'color': const Color(0xFF38BDF8), 'icon': '👕'},
      {'title': 'Wudu', 'id': 'wudu', 'color': const Color(0xFF2DD4BF), 'icon': '💧'},
      {'title': 'Food & Drink', 'id': 'food_drink', 'color': const Color(0xFFF43F5E), 'icon': '🍽️'},
      {'title': 'Home', 'id': 'home', 'color': const Color(0xFF84CC16), 'icon': '🏠'},
      {'title': 'Istikharah', 'id': 'istikharah', 'color': const Color(0xFF0284C7), 'icon': '🧭'},
      {'title': 'Adaan & Masjid', 'id': 'masjid', 'color': const Color(0xFF65A30D), 'icon': '🕌'},
      {'title': 'Diff & Happy', 'id': 'difficulty', 'color': const Color(0xFFEAB308), 'icon': '⚖️'},
      {'title': 'Iman Protect', 'id': 'iman_protection', 'color': const Color(0xFF0F766E), 'icon': '🛡️'},
      {'title': 'Travel', 'id': 'travel', 'color': const Color(0xFF0284C7), 'icon': '✈️'},
      {'title': 'Shopping', 'id': 'shopping', 'color': const Color(0xFF14B8A6), 'icon': '🛍️'},
      {'title': 'Marriage', 'id': 'family', 'color': const Color(0xFFF43F5E), 'icon': '👨‍👩‍👧'},
      {'title': 'Social', 'id': 'social', 'color': const Color(0xFFA855F7), 'icon': '🤝'},
      {'title': 'Nature', 'id': 'nature', 'color': const Color(0xFF22C55E), 'icon': '🌿'},
      {'title': 'Death', 'id': 'death', 'color': const Color(0xFF475569), 'icon': '🥀'},
      {'title': 'Gatherings', 'id': 'gatherings', 'color': const Color(0xFFF59E0B), 'icon': '👥'},
      {'title': 'Hajj & Umrah', 'id': 'hajj', 'color': const Color(0xFF000000), 'icon': '🕋'},
    ];

    final visibleEssentials = essentials.where((e) => !_hiddenIds!.contains(e['id'])).toList();
    final visibleOthers = others.where((e) => !_hiddenIds!.contains(e['id'])).toList();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: _kText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Dhikar & Dua',
            style: GoogleFonts.playfairDisplay(
                fontSize: 24, fontWeight: FontWeight.w700, color: _kText)),
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
                Text('Daily Essentials',
                    style: GoogleFonts.outfit(
                        fontSize: 22, fontWeight: FontWeight.w800, color: _kText)),
                const SizedBox(height: 16),
                if (visibleEssentials.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(AppLocalizations.of(context)?.noCategoriesAvailable ?? 'No categories available.', style: const TextStyle(color: Colors.grey)),
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
                    return _buildGradientCard(context, _localTitle(item['title']), item['id'], item['icon'], item['color'], isStacked: essCols == 1);
                  },
                ),

                const SizedBox(height: 32),
                Text(AppLocalizations.of(context)?.otherCategories ?? 'Other Categories',
                    style: GoogleFonts.outfit(
                        fontSize: 22, fontWeight: FontWeight.w800, color: _kText)),
                const SizedBox(height: 16),
                if (visibleOthers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(AppLocalizations.of(context)?.noCategoriesAvailable ?? 'No categories available.', style: const TextStyle(color: Colors.grey)),
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
                    return _buildMiniGradientCard(context, _localTitle(item['title']), item['id'], item['icon'], item['color']);
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

  Widget _buildGradientCard(BuildContext context, String title, String id, String emoji, Color baseColor, {bool isStacked = false}) {
    String? customImagePath = AssetHelper.getCustomImagePath(title);
    bool isCustomCard = customImagePath != null;
    Color? customTextColor;

    if (isCustomCard) {
      if (id == 'evening') {
        customTextColor = const Color(0xFF1E3A8A); // Deep blue
      } else if (id == 'sleeping') {
        customTextColor = const Color(0xFF0F172A); // Midnight blue
      } else {
        customTextColor = baseColor.computeLuminance() > 0.5 ? Colors.black87 : baseColor;
      }
    }

    final double imgWidth = isStacked ? 180 : 120;
    final double imgBottom = isStacked ? 10 : 30;
    final double titleSize = isStacked ? 26 : 18;
    final double emojiSize = isStacked ? 130 : 90;

    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => DhikrScreen(initialCategory: id))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isCustomCard ? Colors.white : null,
          gradient: isCustomCard ? null : LinearGradient(
            colors: [baseColor, baseColor.withValues(alpha: 0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: baseColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
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
                    child: Image.asset(customImagePath, fit: BoxFit.contain, alignment: Alignment.centerRight),
                  ),
                )
              else
                Positioned(
                  right: -20,
                  bottom: -15,
                  child: Opacity(
                    opacity: 0.55,
                    child: SizedBox(
                      width: emojiSize, height: emojiSize,
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
                    Text(title,
                        style: GoogleFonts.outfit(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w900,
                            color: isCustomCard ? customTextColor : Colors.white,
                            height: 1.1,
                            letterSpacing: -0.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniGradientCard(BuildContext context, String title, String id, String emoji, Color baseColor) {
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => DhikrScreen(initialCategory: id))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [baseColor, baseColor.withValues(alpha: 0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: baseColor.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 6))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Opacity(opacity:0.6,child:SizedBox(width:60,height:60,child:NoorIcon.fromEmoji(emoji,size:60))),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(title,
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -0.3)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
