import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dhikr_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBg = Color(0xFFF7F3EE);
const _kText = Color(0xFF1C1C1E);

class DhikrHubScreen extends StatelessWidget {
  const DhikrHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            style: GoogleFonts.outfit(
                fontSize: 22, fontWeight: FontWeight.w800, color: _kText)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Essentials',
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.w900, color: _kText)),
            const SizedBox(height: 16),
            
            // Full Width items
            _buildWideCard(context, 'Morning Adhkar', 'morning', '🌅',
                const Color(0xFFE2F0D9), const Color(0xFF4CAF50)),
            
            _buildWideCard(context, 'Evening Adhkar', 'evening', '🌇',
                const Color(0xFFFFE8D6), const Color(0xFFFF9800)),
            
            const SizedBox(height: 24),
            Text('Routine Insights',
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.w900, color: _kText)),
            const SizedBox(height: 16),

            // Grid items
            Row(
              children: [
                Expanded(child: _buildSquareCard(context, 'After Salah', 'post_prayer', '🕌',
                    const Color(0xFFE1F5FE), const Color(0xFF03A9F4))),
                const SizedBox(width: 14),
                Expanded(child: _buildSquareCard(context, 'Before Sleep', 'sleeping', '🌌',
                    const Color(0xFFE8EAF6), const Color(0xFF3F51B5))),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildSquareCard(context, 'Protection', 'protection', '🛡️',
                    const Color(0xFFFFEBEE), const Color(0xFFF44336))),
                const SizedBox(width: 14),
                Expanded(child: _buildSquareCard(context, 'General', 'general', '🤲',
                    const Color(0xFFF3E5F5), const Color(0xFF9C27B0))),
              ],
            ),

            const SizedBox(height: 32),
            Text('Explore More',
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.w900, color: _kText)),
            const SizedBox(height: 16),
            
            _buildWideCard(context, 'Du\'as for the Ummah', 'ummah', '🌍',
                const Color(0xFFFFF8E1), const Color(0xFFFFC107)),
            _buildWideCard(context, 'Tahajjud Prayers', 'tahajjud', '🌑',
                const Color(0xFF263238), const Color(0xFFECEFF1), isDark: true),
            _buildWideCard(context, 'Travel & Journey', 'travel', '✈️',
                const Color(0xFFE0F2F1), const Color(0xFF009688)),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWideCard(BuildContext context, String title, String id, String emoji,
      Color bgColor, Color iconColor, {bool isDark = false}) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DhikrScreen(initialCategory: id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 120,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background watermarked emoji at the right
            Positioned(
              right: -10, bottom: -20,
              child: Text(emoji,
                  style: TextStyle(
                      fontSize: 100,
                      color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.6))),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                    const Spacer(),
                    Text(title,
                        style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : _kText,
                            letterSpacing: -0.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareCard(BuildContext context, String title, String id, String emoji,
      Color bgColor, Color iconColor) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DhikrScreen(initialCategory: id))),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Watermarked background emoji
            Positioned(
              right: -15, bottom: -15,
              child: Text(emoji,
                  style: TextStyle(fontSize: 90, color: Colors.white.withValues(alpha: 0.6))),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const Spacer(),
                  Text(title,
                      style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _kText,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Read Now',
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: iconColor)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 12, color: iconColor),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
