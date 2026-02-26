import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'quran_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBg    = Color(0xFFF7F3EE);
const _kWhite = Color(0xFFFFFFFF);
const _kText  = Color(0xFF1C1C1E);
const _kSub   = Color(0xFF8E8E93);
const _kTeal  = Color(0xFF2BAE99);
const _kTealL = Color(0xFFC8ECE8);
const _kGold  = Color(0xFFFFAA00);
const _kRed   = Color(0xFFEF5350);

// ── Surah names (1-indexed, index 0 unused) ───────────────────────────────────
const _surahNames = [
  '',
  'Al-Fatihah','Al-Baqarah','Ali \'Imran','An-Nisa\'','Al-Ma\'idah',
  'Al-An\'am','Al-A\'raf','Al-Anfal','At-Tawbah','Yunus',
  'Hud','Yusuf','Ar-Ra\'d','Ibrahim','Al-Hijr',
  'An-Nahl','Al-Isra\'','Al-Kahf','Maryam','Ta-Ha',
  'Al-Anbiya\'','Al-Hajj','Al-Mu\'minun','An-Nur','Al-Furqan',
  'Ash-Shu\'ara\'','An-Naml','Al-Qasas','Al-\'Ankabut','Ar-Rum',
  'Luqman','As-Sajdah','Al-Ahzab','Saba\'','Fatir',
  'Ya-Sin','As-Saffat','Sad','Az-Zumar','Ghafir',
  'Fussilat','Ash-Shura','Az-Zukhruf','Ad-Dukhan','Al-Jathiyah',
  'Al-Ahqaf','Muhammad','Al-Fath','Al-Hujurat','Qaf',
  'Ad-Dhariyat','At-Tur','An-Najm','Al-Qamar','Ar-Rahman',
  'Al-Waqi\'ah','Al-Hadid','Al-Mujadila','Al-Hashr','Al-Mumtahanah',
  'As-Saf','Al-Jumu\'ah','Al-Munafiqun','At-Taghabun','At-Talaq',
  'At-Tahrim','Al-Mulk','Al-Qalam','Al-Haqqah','Al-Ma\'arij',
  'Nuh','Al-Jinn','Al-Muzzammil','Al-Muddathir','Al-Qiyamah',
  'Al-Insan','Al-Mursalat','An-Naba\'','An-Naz\'iat','Abasa',
  'At-Takwir','Al-Infitar','Al-Mutaffifin','Al-Inshiqaq','Al-Buruj',
  'At-Tariq','Al-A\'la','Al-Ghashiyah','Al-Fajr','Al-Balad',
  'Ash-Shams','Al-Layl','Ad-Duha','Ash-Sharh','At-Tin',
  'Al-\'Alaq','Al-Qadr','Al-Bayyinah','Az-Zalzalah','Al-\'Adiyat',
  'Al-Qari\'ah','At-Takathur','Al-\'Asr','Al-Humazah','Al-Fil',
  'Quraysh','Al-Ma\'un','Al-Kawthar','Al-Kafirun','An-Nasr',
  'Al-Masad','Al-Ikhlas','Al-Falaq','An-Nas',
];

const _surahLengths = [
  0,
  7,  286, 200, 176, 120, 165, 206,  75, 129, 109,
 123, 111,  43,  52,  99, 128, 111, 110,  98, 135,
 112,  78, 118,  64,  77, 227,  93,  88,  69,  60,
  34,  30,  73,  54,  45,  83, 182,  88,  75,  85,
  54,  53,  89,  59,  37,  35,  38,  29,  18,  45,
  60,  49,  62,  55,  78,  96,  29,  22,  24,  13,
  14,  11,  11,  18,  12,  12,  30,  52,  52,  44,
  28,  28,  20,  56,  40,  31,  50,  40,  46,  42,
  29,  19,  36,  25,  22,  17,  19,  26,  30,  20,
  15,  21,  11,   8,   8,  19,   5,   8,   8,  11,
  11,   8,   3,   9,   5,   4,   7,   3,   6,   3,
   5,   4,   5,   6,
];

// ─────────────────────────────────────────────────────────────────────────────
class QuranHubScreen extends StatefulWidget {
  const QuranHubScreen({super.key});
  @override State<QuranHubScreen> createState() => _QuranHubScreenState();
}

class _QuranHubScreenState extends State<QuranHubScreen>
    with SingleTickerProviderStateMixin {
  final _sb = Supabase.instance.client;

  // Last-read / resume position
  int _lastSurah = 2, _lastAyah = 1;
  String _lastSurahName = 'Al-Baqarah';

  // Selected position for starting
  int _selSurah = 1, _selAyah = 1;

  // Favourites & bookmarks counts
  int _bookmarkCount = 0, _favouriteCount = 0;

  // Bookmarked+Favourite ayah lists for the list views
  List<Map<String, dynamic>> _bookmarks = [];
  List<Map<String, dynamic>> _favourites = [];

  // Today progress
  int _ayahsToday = 0;

  bool _loading = true;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) { setState(() => _loading = false); return; }
    try {
      // Last read + daily progress
      await _sb.from('quran_progress').upsert({'user_id': uid}, onConflict: 'user_id');
      final prog = await _sb.from('quran_progress').select().eq('user_id', uid).single();
      _lastSurah     = prog['current_surah'] ?? 2;
      _lastAyah      = prog['current_ayah']  ?? 1;
      _lastSurahName = _surahNames[_lastSurah.clamp(1, 114)];
      _selSurah      = _lastSurah;
      _selAyah       = _lastAyah;

      final today = DateTime.now().toIso8601String().split('T')[0];
      if ((prog['last_read_date'] ?? '') == today) {
        _ayahsToday = prog['ayahs_read_today'] ?? 0;
      }

      // Bookmarks
      final bmarks = await _sb.from('quran_bookmarks')
          .select('surah, ayah').eq('user_id', uid).order('created_at', ascending: false);
      _bookmarks      = List<Map<String, dynamic>>.from(bmarks);
      _bookmarkCount  = _bookmarks.length;

      // Favourites (same table but with is_favourite flag, or separate table)
      // Using bookmarks table with is_favourite column if it exists, else 0
      try {
        final favs = await _sb.from('quran_bookmarks')
            .select('surah, ayah').eq('user_id', uid).eq('is_favourite', true)
            .order('created_at', ascending: false);
        _favourites     = List<Map<String, dynamic>>.from(favs);
        _favouriteCount = _favourites.length;
      } catch (_) {
        _favouriteCount = 0;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      _fadeCtrl.forward();
    }
  }

  // ── Navigate into the reading screen ─────────────────────────────────────────
  Future<void> _startReading({int? surah, int? ayah}) async {
    HapticFeedback.mediumImpact();
    final pts = await Navigator.push<int>(context,
      MaterialPageRoute(builder: (_) => QuranScreen(
        initialSurah: surah ?? _selSurah,
        initialAyah: ayah ?? _selAyah,
      )));
    if ((pts ?? 0) > 0 && mounted) _loadData();
  }

  // ── Surah picker sheet ────────────────────────────────────────────────────────
  void _pickSurah() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Choose Surah', style: GoogleFonts.outfit(fontSize: 20,
                  fontWeight: FontWeight.w800, color: _kText)),
            ),
            const SizedBox(height: 16),
            Expanded(child: ListView.builder(
              controller: ctrl,
              itemCount: 114,
              itemBuilder: (_, i) {
                final n = i + 1;
                final name = _surahNames[n];
                final len  = _surahLengths[n];
                final sel  = n == _selSurah;
                return GestureDetector(
                  onTap: () {
                    setState(() { _selSurah = n; _selAyah = 1; });
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    color: sel ? _kTeal.withValues(alpha: 0.07) : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: sel ? _kTeal : _kTealL,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text('$n',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800,
                                color: sel ? Colors.white : _kTeal))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: GoogleFonts.outfit(fontSize: 15,
                            fontWeight: FontWeight.w700, color: _kText)),
                        Text('$len verses', style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
                      ])),
                      if (sel) const Icon(Icons.check_circle_rounded, color: _kTeal, size: 22),
                    ]),
                  ),
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  // ── Verse / Ayah picker ───────────────────────────────────────────────────────
  void _pickAyah() {
    final maxAyah = _surahLengths[_selSurah];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65, minChildSize: 0.4, maxChildSize: 0.9,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Choose Verse', style: GoogleFonts.outfit(fontSize: 20,
                  fontWeight: FontWeight.w800, color: _kText)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('${_surahNames[_selSurah]} has $maxAyah verses',
                  style: GoogleFonts.outfit(fontSize: 13, color: _kSub)),
            ),
            const SizedBox(height: 16),
            Expanded(child: GridView.builder(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6, mainAxisSpacing: 10, crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: maxAyah,
              itemBuilder: (_, i) {
                final n = i + 1;
                final sel = n == _selAyah;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selAyah = n);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    decoration: BoxDecoration(
                      color: sel ? _kTeal : _kWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? _kTeal : Colors.grey.shade200),
                      boxShadow: sel ? [BoxShadow(color: _kTeal.withValues(alpha: 0.3), blurRadius: 8)] : null,
                    ),
                    child: Center(child: Text('$n',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : _kText))),
                  ),
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  // ── Bookmarks / Favourites list sheet ─────────────────────────────────────────
  void _showSavedList({required bool isFavourites}) {
    final list = isFavourites ? _favourites : _bookmarks;
    final title = isFavourites ? 'Favourites' : 'Bookmarks';
    final color = isFavourites ? _kRed : _kTeal;
    final icon  = isFavourites ? Icons.favorite_rounded : Icons.bookmark_rounded;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6, minChildSize: 0.35, maxChildSize: 0.92,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(title, style: GoogleFonts.outfit(fontSize: 20,
                    fontWeight: FontWeight.w800, color: _kText)),
                const Spacer(),
                Text('${list.length} saved', style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
              ]),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 56, color: Colors.grey.shade200),
                const SizedBox(height: 12),
                Text('No $title yet', style: GoogleFonts.outfit(fontSize: 16, color: _kSub)),
                const SizedBox(height: 6),
                Text('Tap the ${isFavourites ? '❤️' : '🔖'} icon while reading to save verses.',
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade400),
                    textAlign: TextAlign.center),
              ])))
            else
              Expanded(child: ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final item = list[i];
                  final s = item['surah'] as int? ?? 1;
                  final a = item['ayah'] as int? ?? 1;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _startReading(surah: s, ayah: a);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: 0.15)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Icon(icon, color: color, size: 20)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_surahNames[s.clamp(1, 114)],
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: _kText)),
                          Text('Surah $s  •  Verse $a',
                              style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
                        ])),
                        const Icon(Icons.chevron_right_rounded, color: _kSub, size: 20),
                      ]),
                    ),
                  );
                },
              )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kTeal, strokeWidth: 2))
          : FadeTransition(opacity: _fadeAnim, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(slivers: [
      // ── Sticky header ─────────────────────────────────────────────────────
      SliverAppBar(
        expandedHeight: 120,
        pinned: true,
        backgroundColor: _kTeal,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: FlexibleSpaceBar(
          collapseMode: CollapseMode.pin,
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A8F7A), Color(0xFF2BAE99), Color(0xFF3DCFBA)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                // Arabic header
                Text('القرآن الكريم',
                    style: GoogleFonts.amiri(fontSize: 26, fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9)),
                    textDirection: TextDirection.rtl),
                const SizedBox(height: 10),
                Text('Earn +10 Noor Points per verse read',
                    style: GoogleFonts.outfit(fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75))),
              ]),
            )),
          ),

        ),
      ),

      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Daily progress strip ─────────────────────────────────────────
          _ProgressStrip(ayahsToday: _ayahsToday),
          const SizedBox(height: 20),

          // ── Continue reading card ─────────────────────────────────────────
          _SectionLabel(label: 'Resume Reading'),
          const SizedBox(height: 10),
          _ContinueCard(
            surahName: _lastSurahName,
            surah: _lastSurah,
            ayah: _lastAyah,
            onTap: () => _startReading(surah: _lastSurah, ayah: _lastAyah),
          ),
          const SizedBox(height: 24),

          // ── Start new position ────────────────────────────────────────────
          _SectionLabel(label: 'Choose Where to Start'),
          const SizedBox(height: 10),

          // Surah selector row
          _PickerRow(
            icon: Icons.menu_book_rounded,
            iconColor: _kTeal,
            label: 'Surah',
            value: _surahNames[_selSurah],
            subtitle: '${_surahLengths[_selSurah]} verses',
            onTap: _pickSurah,
          ),
          const SizedBox(height: 10),

          // Ayah selector row
          _PickerRow(
            icon: Icons.format_list_numbered_rounded,
            iconColor: const Color(0xFF5856D6),
            label: 'Start from Verse',
            value: 'Verse $_selAyah',
            subtitle: 'of ${_surahLengths[_selSurah]}',
            onTap: _pickAyah,
          ),
          const SizedBox(height: 20),

          // ── Big start button ──────────────────────────────────────────────
          GestureDetector(
            onTap: () => _startReading(),
            child: Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1A8F7A), Color(0xFF2BAE99)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(
                    color: _kTeal.withValues(alpha: 0.4),
                    blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text('Start Reading from ${_surahNames[_selSurah]} : $_selAyah',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ]),
            ),
          ),
          const SizedBox(height: 28),

          // ── Saved / Favourites grid ───────────────────────────────────────
          _SectionLabel(label: 'Your Library'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _LibraryCard(
              icon: Icons.favorite_rounded,
              color: _kRed,
              label: 'Favourites',
              count: _favouriteCount,
              onTap: () => _showSavedList(isFavourites: true),
            )),
            const SizedBox(width: 12),
            Expanded(child: _LibraryCard(
              icon: Icons.bookmark_rounded,
              color: _kTeal,
              label: 'Bookmarks',
              count: _bookmarkCount,
              onTap: () => _showSavedList(isFavourites: false),
            )),
          ]),
          const SizedBox(height: 14),

          // ── Quick access tiles ────────────────────────────────────────────
          Row(children: [
            Expanded(child: _QuickTile(
              icon: Icons.shuffle_rounded,
              color: const Color(0xFF5856D6),
              label: 'Random Verse',
              onTap: () {
                final s = 1 + (DateTime.now().millisecondsSinceEpoch % 114);
                final a = 1 + (DateTime.now().microsecond % _surahLengths[s]);
                _startReading(surah: s, ayah: a.clamp(1, _surahLengths[s]));
              },
            )),
            const SizedBox(width: 10),
            Expanded(child: _QuickTile(
              icon: Icons.water_drop_rounded,
              color: _kGold,
              label: 'Al-Fatihah',
              onTap: () => _startReading(surah: 1, ayah: 1),
            )),
            const SizedBox(width: 10),
            Expanded(child: _QuickTile(
              icon: Icons.nights_stay_rounded,
              color: const Color(0xFF4A9B5F),
              label: 'Al-Kahf',
              subtitle: 'Sunnah Friday',
              onTap: () => _startReading(surah: 18, ayah: 1),
            )),
          ]),
          const SizedBox(height: 24),

        ]),
      )),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label,
      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800,
          color: const Color(0xFF8E8E93)));
}

class _ProgressStrip extends StatelessWidget {
  final int ayahsToday;
  const _ProgressStrip({required this.ayahsToday});
  @override
  Widget build(BuildContext context) {
    final progress = (ayahsToday / 50).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [_kTeal.withValues(alpha: 0.08), _kTeal.withValues(alpha: 0.04)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kTeal.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🌟', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text("Today's Progress",
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: _kTeal)),
            const Spacer(),
            Text('+${ayahsToday * 10} pts',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: _kGold)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 6,
                backgroundColor: _kTealL,
                valueColor: const AlwaysStoppedAnimation(_kTeal))),
          const SizedBox(height: 5),
          Text('$ayahsToday / 50 verses today',
              style: GoogleFonts.outfit(fontSize: 11, color: _kSub)),
        ])),
      ]),
    );
  }
}

class _ContinueCard extends StatefulWidget {
  final String surahName;
  final int surah, ayah;
  final VoidCallback onTap;
  const _ContinueCard({required this.surahName, required this.surah,
    required this.ayah, required this.onTap});
  @override State<_ContinueCard> createState() => _ContinueCardState();
}
class _ContinueCardState extends State<_ContinueCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1A8F7A), Color(0xFF2BAE99)],
                begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(
                color: _kTeal.withValues(alpha: 0.35),
                blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(children: [
            // Book icon circle
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('📖', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.surahName,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 2),
              Text('Surah ${widget.surah}  •  Verse ${widget.ayah}  •  Continue reading',
                  style: GoogleFonts.outfit(fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Resume', style: GoogleFonts.outfit(fontSize: 13,
                    fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(width: 4),
                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PickerRow extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value, subtitle;
  final VoidCallback onTap;
  const _PickerRow({required this.icon, required this.iconColor,
    required this.label, required this.value, required this.subtitle,
    required this.onTap});
  @override State<_PickerRow> createState() => _PickerRowState();
}
class _PickerRowState extends State<_PickerRow> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _pressed ? Colors.grey.shade100 : _kWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: widget.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(widget.icon, color: widget.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.label, style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
            const SizedBox(height: 2),
            Text(widget.value, style: GoogleFonts.outfit(fontSize: 15,
                fontWeight: FontWeight.w700, color: _kText)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(widget.subtitle, style: GoogleFonts.outfit(fontSize: 11, color: _kSub)),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right_rounded, color: _kSub, size: 20),
          ]),
        ]),
      ),
    );
  }
}

class _LibraryCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final VoidCallback onTap;
  const _LibraryCard({required this.icon, required this.color,
    required this.label, required this.count, required this.onTap});
  @override State<_LibraryCard> createState() => _LibraryCardState();
}
class _LibraryCardState extends State<_LibraryCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: _kWhite, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color.withValues(alpha: 0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(widget.label, style: GoogleFonts.outfit(fontSize: 13,
                fontWeight: FontWeight.w700, color: _kText)),
            const SizedBox(height: 2),
            Text('${widget.count} saved', style: GoogleFonts.outfit(fontSize: 11, color: _kSub)),
          ]),
        ),
      ),
    );
  }
}

class _QuickTile extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  const _QuickTile({required this.icon, required this.color,
    required this.label, this.subtitle, required this.onTap});
  @override State<_QuickTile> createState() => _QuickTileState();
}
class _QuickTileState extends State<_QuickTile> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withValues(alpha: 0.2)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, color: widget.color, size: 26),
            const SizedBox(height: 6),
            Text(widget.label, style: GoogleFonts.outfit(fontSize: 11,
                fontWeight: FontWeight.w700, color: _kText), textAlign: TextAlign.center),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(widget.subtitle!, style: GoogleFonts.outfit(fontSize: 9, color: _kSub),
                  textAlign: TextAlign.center),
            ],
          ]),
        ),
      ),
    );
  }
}
