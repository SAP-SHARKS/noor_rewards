import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/settings_service.dart';
import '../models/app_config.dart';
import 'tafsir_screen.dart';
import '../widgets/noor_offline.dart';

AppConfig get _thcfg => SettingsService.instance.config;

// ── Palette ────────────────────────────────────────────────────────────────────
Color get _kBg    => _thcfg.dashBg;
const _kWhite = Color(0xFFFFFFFF);
Color get _kText  => _thcfg.dashText;
Color get _kSub   => _thcfg.dashBg.computeLuminance() > 0.5
    ? const Color(0xFF8E8E93) : const Color(0xFF9CA3AF);
const _kGreen = Color(0xFF4A9B5F);

// ── Featured Surahs ──────────────────────────────────────────────────────────
const _featured = [
  (1,  'Al-Fatihah',     'The Opening',         '🌟', 7),
  (2,  'Al-Baqarah',     'The Cow',             '📖', 286),
  (18, 'Al-Kahf',        'The Cave',            '🕌', 110),
  (36, 'Ya-Sin',         'Ya-Sin',              '✨', 83),
  (55, 'Ar-Rahman',      'The Most Gracious',   '💚', 78),
  (56, "Al-Waqi'ah",     "The Inevitable",      '🌙', 96),
  (67, 'Al-Mulk',        'The Sovereignty',     '👑', 30),
  (112,'Al-Ikhlas',      'The Sincerity',       '❤️', 4),
];

// ─────────────────────────────────────────────────────────────────────────────
class TafsirHubScreen extends StatefulWidget {
  const TafsirHubScreen({super.key});
  @override
  State<TafsirHubScreen> createState() => _TafsirHubScreenState();
}

class _TafsirHubScreenState extends State<TafsirHubScreen> {
  final _sb = Supabase.instance.client;
  int _lastSurah = 1;
  int _lastAyah  = 1;
  bool _loadingProgress = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _loadingProgress = false);
      return;
    }
    try {
      final row = await _sb
          .from('user_progress')
          .select('last_surah, last_ayah')
          .eq('user_id', uid)
          .eq('activity_type', 'tafsir')
          .maybeSingle();
      if (row != null && mounted) {
        setState(() {
          _lastSurah = row['last_surah'] ?? 1;
          _lastAyah  = row['last_ayah']  ?? 1;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingProgress = false);
  }

  void _openTafsir({int surah = 1, int ayah = 1}) {
    Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) =>
            TafsirScreen(initialSurah: surah, initialAyah: ayah)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(slivers: [
        // ── Hero AppBar ──────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 240,
          floating: false,
          pinned: true,
          backgroundColor: _kGreen,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E6B3E), Color(0xFF4A9B5F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(children: [
                // Decorative circles
                Positioned(right: -40, top: -40,
                    child: Container(width: 180, height: 180,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06)))),
                Positioned(left: -30, bottom: -30,
                    child: Container(width: 140, height: 140,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06)))),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('📚', style: TextStyle(fontSize: 42)),
                      const SizedBox(height: 8),
                      Text('Read & Listen Tafsir',
                          style: GoogleFonts.outfit(
                              fontSize: 28, fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Deep understanding of the Holy Quran',
                          style: GoogleFonts.outfit(
                              fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),

        // ── Body ─────────────────────────────────────────────────────────
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Resume card ─────────────────────────────────────────────
            if (!_loadingProgress) ...[
              _ResumeCard(
                surah: _lastSurah,
                ayah:  _lastAyah,
                onTap: () => _openTafsir(surah: _lastSurah, ayah: _lastAyah),
              ),
              const SizedBox(height: 24),
            ] else ...[
              const Center(child: NoorInlineLoader()),
              const SizedBox(height: 24),
            ],

            // ── Points info ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kGreen.withValues(alpha: 0.2))),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle),
                  child: const Center(
                      child: Text('🎧', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('+50 Noor Points',
                      style: GoogleFonts.outfit(
                          fontSize: 15, fontWeight: FontWeight.w800,
                          color: _kGreen)),
                  Text('Earn points for every 10 min of Tafsir listening',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: _kSub)),
                ])),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Featured surahs ─────────────────────────────────────────
            Text('Featured Surahs',
                style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.w800, color: _kText)),
            const SizedBox(height: 14),

            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _featured.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12,
                mainAxisSpacing: 12, childAspectRatio: 1.15,
              ),
              itemBuilder: (_, i) {
                final s = _featured[i];
                return _SurahCard(
                  number: s.$1,
                  name:   s.$2,
                  meaning: s.$3,
                  emoji:  s.$4,
                  verses: s.$5,
                  onTap:  () => _openTafsir(surah: s.$1, ayah: 1),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Browse all ───────────────────────────────────────────────
            GestureDetector(
              onTap: () => _openTafsir(surah: 1, ayah: 1),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2E6B3E), _kGreen],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(
                      color: _kGreen.withValues(alpha: 0.4),
                      blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text('Browse All 114 Surahs',
                      style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ]),
              ),
            ),
            const SizedBox(height: 32),
          ]),
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Resume Card
// ─────────────────────────────────────────────────────────────────────────────
class _ResumeCard extends StatelessWidget {
  final int surah, ayah;
  final VoidCallback onTap;
  const _ResumeCard({required this.surah, required this.ayah, required this.onTap});

  static const _names = [
    '',
    'Al-Fatihah','Al-Baqarah','Ali Imran','An-Nisa','Al-Maidah',
    'Al-Anam','Al-Araf','Al-Anfal','At-Tawbah','Yunus',
    'Hud','Yusuf','Ar-Ra\'d','Ibrahim','Al-Hijr',
    'An-Nahl','Al-Isra','Al-Kahf','Maryam','Ta-Ha',
    'Al-Anbiya','Al-Hajj','Al-Muminun','An-Nur','Al-Furqan',
    'Ash-Shu\'ara','An-Naml','Al-Qasas','Al-Ankabut','Ar-Rum',
    'Luqman','As-Sajdah','Al-Ahzab','Saba','Fatir',
    'Ya-Sin','As-Saffat','Sad','Az-Zumar','Ghafir',
    'Fussilat','Ash-Shura','Az-Zukhruf','Ad-Dukhan','Al-Jathiyah',
    'Al-Ahqaf','Muhammad','Al-Fath','Al-Hujurat','Qaf',
    'Adh-Dhariyat','At-Tur','An-Najm','Al-Qamar','Ar-Rahman',
    "Al-Waqi'ah",'Al-Hadid','Al-Mujadila','Al-Hashr','Al-Mumtahanah',
    'As-Saf','Al-Jumuah','Al-Munafiqun','At-Taghabun','At-Talaq',
    'At-Tahrim','Al-Mulk','Al-Qalam','Al-Haqqah',"Al-Ma'arij",
    'Nuh','Al-Jinn','Al-Muzzammil','Al-Muddaththir','Al-Qiyamah',
    'Al-Insan','Al-Mursalat','An-Naba','An-Naziat','Abasa',
    'At-Takwir','Al-Infitar','Al-Mutaffifin','Al-Inshiqaq','Al-Buruj',
    'At-Tariq','Al-Ala','Al-Ghashiyah','Al-Fajr','Al-Balad',
    'Ash-Shams','Al-Layl','Ad-Duha','Ash-Sharh','At-Tin',
    'Al-Alaq','Al-Qadr','Al-Bayyinah','Az-Zalzalah','Al-Adiyat',
    "Al-Qari'ah",'At-Takathur','Al-Asr','Al-Humazah','Al-Fil',
    "Quraysh","Al-Ma'un",'Al-Kawthar','Al-Kafirun','An-Nasr',
    'Al-Masad','Al-Ikhlas','Al-Falaq','An-Nas',
  ];

  @override
  Widget build(BuildContext context) {
    final name = surah < _names.length ? _names[surah] : 'Surah $surah';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: _kGreen.withValues(alpha: 0.15),
                blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14)),
            child: const Center(
                child: Text('▶️', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Resume Reading',
                style: GoogleFonts.outfit(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: _kGreen, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(name,
                style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w800, color: _kText)),
            Text('Ayah $ayah',
                style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: _kGreen, size: 16),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Surah Card
// ─────────────────────────────────────────────────────────────────────────────
class _SurahCard extends StatelessWidget {
  final int    number, verses;
  final String name, meaning, emoji;
  final VoidCallback onTap;

  const _SurahCard({
    required this.number, required this.name, required this.meaning,
    required this.emoji,  required this.verses, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('$number',
                    style: GoogleFonts.outfit(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: _kGreen)),
              ),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: _kText),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(meaning,
                  style: GoogleFonts.outfit(fontSize: 11, color: _kSub),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('$verses verses',
                  style: GoogleFonts.outfit(
                      fontSize: 10, color: _kGreen,
                      fontWeight: FontWeight.w600)),
            ]),
          ],
        ),
      ),
    );
  }
}
