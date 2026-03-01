import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dhikr_screen.dart';
import '../utils/asset_helper.dart';

const _kBg = Color(0xFFF7F3EE);
const _kText = Color(0xFF1C1C1E);

class DhikrHubScreen extends StatelessWidget {
  const DhikrHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _kText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Dhikar & Dua',
            style: GoogleFonts.playfairDisplay(
                fontSize: 24, fontWeight: FontWeight.w700, color: _kText)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Essentials',
                style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.w800, color: _kText)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.9,
              ),
              itemCount: essentials.length,
              itemBuilder: (context, index) {
                final item = essentials[index];
                return _buildGradientCard(context, item['title'], item['id'], item['icon'], item['color']);
              },
            ),

            const SizedBox(height: 32),
            Text('Other Categories',
                style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.w800, color: _kText)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: others.length,
              itemBuilder: (context, index) {
                final item = others[index];
                return _buildMiniGradientCard(context, item['title'], item['id'], item['icon'], item['color']);
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientCard(BuildContext context, String title, String id, String emoji, Color baseColor) {
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
        // Default color fallback for random images matching category theme!
      }
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DhikrScreen(initialCategory: id))),
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
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10), // slight padding so it doesn't overlap text
                      child: Image.asset(customImagePath!, fit: BoxFit.contain),
                    ),
                  ),
                )
              else
                Positioned(
                  right: -20,
                  bottom: -15,
                  child: Text(emoji,
                      style: const TextStyle(
                          fontSize: 90,
                          shadows: [Shadow(color: Colors.black26, offset: Offset(2, 5), blurRadius: 10)])),
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
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(title,
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DhikrScreen(initialCategory: id))),
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
                child: Text(emoji,
                    style: const TextStyle(
                        fontSize: 60,
                        shadows: [Shadow(color: Colors.black26, offset: Offset(2, 5), blurRadius: 10)])),
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
