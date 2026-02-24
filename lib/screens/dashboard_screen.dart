import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'quran_hub_screen.dart';
import 'dhikr_screen.dart';
import 'tafsir_hub_screen.dart';
import 'level_screen.dart';
import 'impact_report_screen.dart';
import 'admin/admin_dashboard.dart';
import '../services/xp_service.dart';
import '../services/tracking_service.dart';

// ── Admin email whitelist (client-side guard) ─────────────────────────────────
const _kAdminEmails = {'pak.zakn@gmail.com'};

// ── Palette ────────────────────────────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFFF7F3EE);
  static const text        = Color(0xFF1C1C1E);
  static const sub         = Color(0xFF8E8E93);
  static const darkBtn     = Color(0xFF1C1C1E);
  static const communityBg = Color(0xFFFEF3D4);
  static const communityBr = Color(0xFFE8C870);
  static const amber       = Color(0xFFF5A623);
  static const quranCard   = Color(0xFFC8ECE8);
  static const dhikrCard   = Color(0xFFF9D5D8);
  static const tafsirCard  = Color(0xFFCCE5CC);
  static const duaCard     = Color(0xFFFFD5B3);
  static const quranIcon   = Color(0xFF2BAE99);
  static const dhikrIcon   = Color(0xFFE05C6A);
  static const tafsirIcon  = Color(0xFF4A9B5F);
  static const duaIcon     = Color(0xFFD4783A);
  static const navHome     = Color(0xFFE8643A);
  static const navImpact   = Color(0xFF2BAE9B);
  static const navRanking  = Color(0xFFD4A017);
  static const navProfile  = Color(0xFF6B4EBB);
}

class DashboardScreen extends StatefulWidget {
  final String name;
  const DashboardScreen({super.key, required this.name});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;
  final _supabase = Supabase.instance.client;

  // Profile state
  int _noorPoints  = 0;
  int _todayPoints = 0;
  int _weekPoints  = 0;
  int _monthPoints = 0;
  int _streak      = 0;
  int _totalXp     = 0;
  int _level       = 1;
  String _levelTitle = 'Seeker';
  String? _country;

  // Community project
  Map<String, dynamic>? _project;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    // Claim daily login XP once per day (fire & forget)
    XpService.instance.claimDailyLoginXp();
    // Start privacy-first analytics session
    TrackingService.instance.beginSession();
  }

  @override
  void dispose() {
    // End session — saves accumulated time + coins to Supabase
    TrackingService.instance.endSession();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final profile = await _supabase.from('profiles')
          .select('noor_points, country, total_xp, level').eq('id', uid).maybeSingle();
      _noorPoints = (profile?['noor_points'] as num?)?.toInt() ?? 0;
      _totalXp    = (profile?['total_xp']    as num?)?.toInt() ?? 0;
      _level      = (profile?['level']       as num?)?.toInt() ?? 1;
      _country    = profile?['country'] as String?;

      // Resolve level title from xp_levels table
      final levels = await _supabase.from('xp_levels')
          .select('level, title').eq('level', _level).maybeSingle();
      _levelTitle = (levels?['title'] as String?) ?? _levelTitleFor(_level);

      // Fetch daily / weekly / monthly points + streak in parallel
      final results = await Future.wait([
        _supabase.rpc('get_today_points'),
        _supabase.rpc('get_week_points'),
        _supabase.rpc('get_month_points'),
        _supabase.rpc('get_day_streak'),
      ]);
      _todayPoints = (results[0] as num?)?.toInt() ?? 0;
      _weekPoints  = (results[1] as num?)?.toInt() ?? 0;
      _monthPoints = (results[2] as num?)?.toInt() ?? 0;
      _streak      = (results[3] as num?)?.toInt() ?? 0;

      final proj = await _supabase.from('community_projects')
          .select().eq('is_active', true).eq('is_completed', false).maybeSingle();
      _project = proj;
    } catch (_) {}
    if (mounted) setState(() {});
  }

  // Fallback level title if DB not reachable
  String _levelTitleFor(int lv) {
    if (lv >= 51) return 'Legend';
    if (lv >= 21) return 'Champion';
    if (lv >= 11) return 'Devoted';
    if (lv >= 6)  return 'Believer';
    return 'Seeker';
  }

  Future<void> _signOut() async => _supabase.auth.signOut();

  void _goToScreen(Widget screen) async {
    final result = await Navigator.push<int>(
        context, MaterialPageRoute(builder: (_) => screen));
    if ((result ?? 0) > 0) _loadHomeData(); // refresh points on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      extendBody: true,
      body: IndexedStack(index: _tab, children: [
        _HomeTab(
          name: widget.name,
          noorPoints: _noorPoints,
          totalXp: _totalXp,
          level: _level,
          levelTitle: _levelTitle,
          todayPoints: _todayPoints,
          weekPoints: _weekPoints,
          monthPoints: _monthPoints,
          streak: _streak,
          project: _project,
          onGoQuran:       () => _goToScreen(const QuranHubScreen()),
          onGoDhikr:       () => _goToScreen(const DhikrScreen()),
          onGoTafsir:      () => _goToScreen(const TafsirHubScreen()),
          onGoAchievements:() => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const LevelScreen())),
          onValidate: () async {
            final awarded = await XpService.instance.claimValidateXp();
            await _loadHomeData();
            return awarded;
          },
        ),
        _ImpactTab(),
        _RankingTab(currentUserId: _supabase.auth.currentUser?.id ?? ''),
        _ProfileTab(
            name: widget.name, noorPoints: _noorPoints,
            totalXp: _totalXp, level: _level, levelTitle: _levelTitle,
            country: _country, onSignOut: _signOut),
      ]),
      bottomNavigationBar: _BottomNav(tab: _tab, onTap: (i) => setState(() => _tab = i)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME TAB
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final String name, levelTitle;
  final int noorPoints, todayPoints, weekPoints, monthPoints, streak, totalXp, level;
  final Map<String, dynamic>? project;
  final VoidCallback onGoQuran, onGoDhikr, onGoTafsir, onGoAchievements;
  final Future<bool> Function() onValidate;
  const _HomeTab({
    required this.name, required this.noorPoints, required this.todayPoints,
    required this.weekPoints, required this.monthPoints, required this.streak,
    required this.totalXp, required this.level, required this.levelTitle,
    required this.project, required this.onGoQuran, required this.onGoDhikr,
    required this.onGoTafsir, required this.onValidate, required this.onGoAchievements,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;
    return SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),

        // ── Top bar ───────────────────────────────────────────────────────
        Row(children: [
          GestureDetector(
            onTap: onGoAchievements,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: _C.darkBtn,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8, offset: const Offset(0, 2),
                  )],
                ),
                child: Row(children: [
                  Container(
                    width: 22, height: 22,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFAA00)),
                    child: Center(child: Text('N',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black)))),
                  const SizedBox(width: 7),
                  Text(_fmt(noorPoints),
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text('Noor Points',
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600,
                        color: _C.sub)),
              ),
            ]),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onGoAchievements,
            child: Stack(clipBehavior: Clip.none, children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFFDD88FF), Color(0xFF9B59B6)])),
                child: Center(child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'N',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)))),
              Positioned(bottom: -4, right: -4, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF5856D6),
                    borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 1.5)),
                child: Text('LV $level', style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
              )),
            ]),
          ),
        ]),

        // ── Big points number ─────────────────────────────────────────────
        const SizedBox(height: 28),
        Center(child: Column(children: [
          Text(_fmt(todayPoints > 0 ? todayPoints : noorPoints),
              style: GoogleFonts.outfit(fontSize: 80, fontWeight: FontWeight.w700,
                  color: _C.text, height: 1.0, letterSpacing: -3)),
          const SizedBox(height: 6),
          Text('Noor Points Earned Today',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: _C.sub)),
        ])),

        // ── Progress card (Daily / Weekly / Monthly) ──────────────────────
        const SizedBox(height: 20),
        _ProgressCard(
          todayPts: todayPoints,
          weekPts:  weekPoints,
          monthPts: monthPoints,
          streak:   streak,
        ),

        // ── Community progress ────────────────────────────────────────────
        const SizedBox(height: 20),
        if (project != null) _CommunityCard(project: project!),

        // ── Swipe-to-Validate button ──────────────────────────────────────
        const SizedBox(height: 14),
        _SwipeValidateButton(onValidate: onValidate),


        // ── Activity grid ─────────────────────────────────────────────────
        const SizedBox(height: 24),
        Text('Earn Noor Points',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _C.text)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.92,
          children: [
            _ActivityCard('Read Quran',    '📖', _C.quranCard,  _C.quranIcon,  '+5 XP / ayah',  onGoQuran),
            _ActivityCard('Count Dhikr',   '📿', _C.dhikrCard,  _C.dhikrIcon,  '+10 XP / set',  onGoDhikr),
            _ComingSoonCard('Daily Hikmah', '✨', const Color(0xFFEEF6FF), const Color(0xFF3A86FF), 'New feature coming soon'),
            _ActivityCard('Achievements',  '🏆', const Color(0xFFEDE0FF), _C.navProfile, '$totalXp XP • Lv $level', onGoAchievements),
          ],
        ),
      ]),
    ));
  }

  String _fmt(int n) {
    if (n >= 1000) {
      final s = n.toString();
      return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return '$n';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily / Weekly / Monthly Progress Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final int todayPts, weekPts, monthPts, streak;
  const _ProgressCard({
    required this.todayPts,
    required this.weekPts,
    required this.monthPts,
    required this.streak,
  });

  // Target goals — gamification benchmarks
  static const int _dayGoal   = 50;
  static const int _weekGoal  = 250;
  static const int _monthGoal = 800;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row: title + streak bubble
        Row(children: [
          Text('Your Progress',
              style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w800, color: _C.text)),
          const Spacer(),
          // Streak flame
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF9500)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.30),
                  blurRadius: 8)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔥', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text('$streak day${streak == 1 ? '' : 's'}',
                  style: GoogleFonts.outfit(
                      fontSize: 12, fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ]),
          ),
        ]),

        const SizedBox(height: 16),

        // Three progress bars
        _ProgBar(label: 'Today',   pts: todayPts, goal: _dayGoal,
            color: const Color(0xFF00897B), emoji: '☀️'),
        const SizedBox(height: 12),
        _ProgBar(label: 'This Week', pts: weekPts, goal: _weekGoal,
            color: const Color(0xFF5C6BC0), emoji: '📅'),
        const SizedBox(height: 12),
        _ProgBar(label: 'This Month', pts: monthPts, goal: _monthGoal,
            color: const Color(0xFFE91E8C), emoji: '🗓️'),
      ]),
    );
  }
}

class _ProgBar extends StatelessWidget {
  final String label, emoji;
  final int pts, goal;
  final Color color;
  const _ProgBar({
    required this.label, required this.pts,
    required this.goal,  required this.color, required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (pts / goal).clamp(0.0, 1.0);
    final done = pts >= goal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.outfit(
            fontSize: 13, fontWeight: FontWeight.w700, color: _C.text)),
        const Spacer(),
        if (done)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Text('Goal ✅', style: GoogleFonts.outfit(
                fontSize: 10, fontWeight: FontWeight.w800, color: color)),
          )
        else
          RichText(text: TextSpan(children: [
            TextSpan(text: '$pts ',
                style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w800, color: _C.text)),
            TextSpan(text: '/ $goal XP',
                style: GoogleFonts.outfit(
                    fontSize: 11, color: _C.sub)),
          ])),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: pct,
          minHeight: 8,
          backgroundColor: color.withValues(alpha: 0.10),
          valueColor: AlwaysStoppedAnimation<Color>(
              done ? color : color.withValues(alpha: 0.85)),
        ),
      ),
    ]);
  }
}

class _CommunityCard extends StatelessWidget {
  final Map<String, dynamic> project;
  const _CommunityCard({required this.project});
  @override
  Widget build(BuildContext context) {
    final cur = (project['current_points'] as num?)?.toInt() ?? 4200000;
    final tgt = (project['target_points'] as num?)?.toInt() ?? 10000000;
    final pct = (cur / tgt).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.communityBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.communityBr.withValues(alpha: 0.6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Community Progress: ${project['title']} ${project['emoji']}',
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF7A5C00))),
        const SizedBox(height: 14),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct),
          duration: const Duration(milliseconds: 1400), curve: Curves.easeOut,
          builder: (_, v, __) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: v, minHeight: 10,
                backgroundColor: const Color(0xFFE8C870).withValues(alpha: 0.4),
                valueColor: const AlwaysStoppedAnimation(_C.amber)),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Text('${_fmtM(cur)} / ${_fmtM(tgt)} points',
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7A5C00), fontWeight: FontWeight.w500)),
          const Spacer(),
          Text('${(pct * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF7A5C00))),
        ]),
      ]),
    );
  }

  String _fmtM(int n) => n >= 1000000 ? '${(n / 1000000).toStringAsFixed(1)}M' : '$n';
}

class _ActivityCard extends StatefulWidget {
  final String title, emoji, reward;
  final Color bg, iconColor;
  final VoidCallback onTap;
  const _ActivityCard(this.title, this.emoji, this.bg, this.iconColor, this.reward, this.onTap);
  @override State<_ActivityCard> createState() => _ActivityCardState();
}
class _ActivityCardState extends State<_ActivityCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0, duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.bg, borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: widget.iconColor.withValues(alpha: 0.14), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 24))),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: _C.text)),
              const SizedBox(height: 2),
              Text(widget.reward, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: widget.iconColor)),
            ]),
          ]),
        ),
      ),
    );
  }
}

// – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – –
class _ComingSoonCard extends StatelessWidget {
  final String title, emoji, label;
  final Color bg, accentColor;
  const _ComingSoonCard(this.title, this.emoji, this.bg, this.accentColor, this.label);

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          // Icon area (slightly dimmed)
          Opacity(opacity: 0.55, child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: _C.text.withValues(alpha: 0.55))),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor.withValues(alpha: 0.7))),
          ]),
        ]),
      ),
      // Lock badge top-right
      Positioned(top: 10, right: 10,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_rounded, color: Colors.white, size: 10),
            const SizedBox(width: 3),
            Text('Soon', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMPACT TAB  — reads from community_projects
// ─────────────────────────────────────────────────────────────────────────────
class _ImpactTab extends StatefulWidget {
  @override State<_ImpactTab> createState() => _ImpactTabState();
}
class _ImpactTabState extends State<_ImpactTab> {
  List<Map<String, dynamic>> _projects = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await Supabase.instance.client.from('community_projects')
          .select().order('sort_order');
      _projects = List<Map<String, dynamic>>.from(res);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _fmtM(num n) => n >= 1000000 ? '${(n / 1000000).toStringAsFixed(1)}M' : '$n';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _C.navImpact));
    final active    = _projects.where((p) => p['is_active'] == true).toList();
    final completed = _projects.where((p) => p['is_completed'] == true).toList();

    return SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── My personal stats banner ─────────────────────────────────────
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ImpactReportScreen())),
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A9E8C), Color(0xFF2BAE99)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF2BAE99).withValues(alpha: 0.3),
                  blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(children: [
              const Text('📊', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('My Impact Stats',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('See your worship time, XP & coins earned',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
              ])),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
            ]),
          ),
        ),
        Text('Community Impact', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: _C.text)),
        const SizedBox(height: 20),

        for (final p in active) ...[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('${p['emoji']} ${p['title']}',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _C.text))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3D4), borderRadius: BorderRadius.circular(12)),
                  child: Text('\$${p['estimated_usd'].toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: _C.amber)),
                ),
              ]),
              const SizedBox(height: 16),
              Container(
                height: 130, width: double.infinity,
                decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF89CFF0), Color(0xFF4ECDC4)]),
                    borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('💧', style: TextStyle(fontSize: 64))),
              ),
              const SizedBox(height: 16),
              ClipRRect(borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ((p['current_points'] as num) / (p['target_points'] as num)).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: const Color(0xFFFFE8A0),
                  valueColor: const AlwaysStoppedAnimation(_C.amber),
                )),
              const SizedBox(height: 10),
              Row(children: [
                Text('${_fmtM(p['current_points'])} / ${_fmtM(p['target_points'])} points',
                    style: GoogleFonts.outfit(fontSize: 13, color: _C.sub, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text('${((p['current_points'] as num) / (p['target_points'] as num) * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: _C.amber)),
              ]),
              const SizedBox(height: 8),
              Text('Sponsored by ${p['sponsor']}',
                  style: GoogleFonts.outfit(fontSize: 12, color: _C.sub)),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        if (completed.isNotEmpty) ...[
          Text('Completed Projects ✅',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _C.text)),
          const SizedBox(height: 12),
          for (final p in completed)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFFEF3D4), borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE8C870).withValues(alpha: 0.5))),
              child: Row(children: [
                Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(50)),
                    child: Center(child: Text(p['emoji'], style: const TextStyle(fontSize: 24)))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p['title'], style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: _C.text)),
                  Text('\$${p['estimated_usd'].toStringAsFixed(0)} funded • ${p['sponsor']}',
                      style: GoogleFonts.outfit(fontSize: 12, color: _C.sub)),
                ])),
              ]),
            ),
        ],
      ]),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RANKING TAB  — reads from profiles, shows leaderboard
// ─────────────────────────────────────────────────────────────────────────────
class _RankingTab extends StatefulWidget {
  final String currentUserId;
  const _RankingTab({required this.currentUserId});
  @override State<_RankingTab> createState() => _RankingTabState();
}
class _RankingTabState extends State<_RankingTab> {
  List<Map<String, dynamic>> _leaders = [];
  int _myRank = 0;
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      // Use the leaderboard_global view which includes level_title & xp
      final res = await Supabase.instance.client
          .from('leaderboard_global')
          .select()
          .limit(100);
      _leaders = List<Map<String, dynamic>>.from(res);
      _myRank  = _leaders.indexWhere((p) => p['id'] == widget.currentUserId) + 1;
      if (_myRank == 0) _myRank = _leaders.length + 1;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _C.navRanking));
    return SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Leaderboard', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: _C.text)),
        const SizedBox(height: 20),

        // User rank card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFF3D4), Color(0xFFFFE0A0)]),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8C870))),
          child: Row(children: [
            const Text('🏅', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your Rank: #$_myRank',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: _C.text)),
              Text('Out of ${_leaders.length} users',
                  style: GoogleFonts.outfit(fontSize: 13, color: _C.sub)),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        Text('Top Contributors — All Time XP',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: _C.text)),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)]),
          child: Column(children: List.generate(_leaders.take(10).length, (i) {
            final p = _leaders[i];
            final isMe = p['id'] == widget.currentUserId;
            // Badge colors: gold / silver / bronze / teal for rest
            final badgeColors = [
              [const Color(0xFFFFD700), const Color(0xFFFFA500)], // gold
              [const Color(0xFFB0BEC5), const Color(0xFF78909C)], // silver
              [const Color(0xFFCD7F32), const Color(0xFFA0522D)], // bronze
            ];
            final isTop3 = i < 3;
            final badgeGrad = isTop3 ? badgeColors[i] : [const Color(0xFF2BAE99), const Color(0xFF1A9E8C)];
            final medalEmoji = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : null;
            final xp    = (p['total_xp']      as num?)?.toInt() ?? 0;
            final lv    = (p['level']         as num?)?.toInt() ?? 1;
            final title = (p['level_title']   as String?) ?? 'Seeker';
            final name  = (p['display_name']  as String?)?.split(' ').first ?? 'User';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFFFF3D4) : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                border: i < _leaders.take(10).length - 1
                    ? const Border(bottom: BorderSide(color: Color(0xFFF5F5F5))) : null,
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                // Uniform 40×40 badge for ALL ranks
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: badgeGrad,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [BoxShadow(
                      color: badgeGrad.last.withValues(alpha: 0.35),
                      blurRadius: 8, offset: const Offset(0, 3),
                    )],
                  ),
                  child: Center(
                    child: medalEmoji != null
                        ? Text(medalEmoji, style: const TextStyle(fontSize: 20))
                        : Text('${i + 1}',
                            style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isMe ? '$name (you)' : name,
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: _C.text)),
                  Text('$title • Lv $lv',
                      style: GoogleFonts.outfit(fontSize: 11, color: _C.sub)),
                ])),
                Text('$xp XP',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: _C.navRanking)),
              ]),
            );
          })),
        ),

        const SizedBox(height: 16),
        // Streak banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFF0F5), Color(0xFFFFE0EC)]),
              borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Center(child: Text('🔥', style: TextStyle(fontSize: 26)))),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('7 Day Streak!',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFFFF6B9D))),
              Text('Keep it going to unlock rewards',
                  style: GoogleFonts.outfit(fontSize: 13, color: _C.sub)),
            ]),
          ]),
        ),
      ]),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE TAB
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final String name, levelTitle;
  final int noorPoints, totalXp, level;
  final String? country;
  final VoidCallback onSignOut;
  const _ProfileTab({required this.name, required this.noorPoints,
      required this.totalXp, required this.level, required this.levelTitle,
      required this.country, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final first = name.split(' ').first;
    return SafeArea(child: SingleChildScrollView(
      child: Column(children: [
        // Profile header (warm gradient)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFFFE5D9), Color(0xFFFFD4BF)]),
          ),
          child: Column(children: [
            Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFFDD88FF), Color(0xFF9B59B6)]),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: const Color(0xFFDD88FF).withValues(alpha: 0.4), blurRadius: 20)]),
                child: Center(child: Text(first.isNotEmpty ? first[0].toUpperCase() : 'N',
                    style: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
              Positioned(bottom: -6, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFF9671), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2)),
                child: Text('$levelTitle • Level $level',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              )),
            ]),
            const SizedBox(height: 20),
            Text(name, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: _C.text)),
            const SizedBox(height: 4),
            if (country != null && country!.isNotEmpty)
              Text(country!, style: GoogleFonts.outfit(fontSize: 13, color: _C.sub)),
          ]),
        ),

        Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          // Stats grid
          Row(children: [
            _StatCard('Noor Points', '$noorPoints', _C.navRanking),
            const SizedBox(width: 12),
            _StatCard('Total XP',   '$totalXp',    const Color(0xFF6B4EBB)),
            const SizedBox(width: 12),
            _StatCard('Level',      'Lv $level',   _C.navImpact),
            const SizedBox(width: 12),
            _StatCard('Title',      levelTitle,    _C.navHome),
          ]),
          const SizedBox(height: 20),

          // Streak card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFF0F5), Color(0xFFFFE0EC)]),
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Center(child: Text('🔥', style: TextStyle(fontSize: 26)))),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('7 Day Streak',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFFFF6B9D))),
                Text('Current streak', style: GoogleFonts.outfit(fontSize: 13, color: _C.sub)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Email
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
            child: Row(children: [
              const Icon(Icons.email_rounded, color: Color(0xFF4FC3F7), size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(user?.email ?? '',
                  style: GoogleFonts.outfit(fontSize: 14, color: _C.text))),
            ]),
          ),
          const SizedBox(height: 8),

          // Admin Panel button (only for admin emails)
          if (_kAdminEmails.contains(user?.email)) ...[  
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminDashboard())),
              child: Container(
                width: double.infinity, height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)]),
                  boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF2BAE99), size: 22),
                  const SizedBox(width: 10),
                  Text('Admin Panel', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ])),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Sign out
          GestureDetector(
            onTap: onSignOut,
            child: Container(
              width: double.infinity, height: 54,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                  color: Colors.red.withValues(alpha: 0.08),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.25))),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                const SizedBox(width: 10),
                Text('Sign Out', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red)),
              ])),
            ),
          ),
        ])),
      ]),
    ));
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);
  @override Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.1), border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Column(children: [
      Text(value, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 3),
      Text(label, style: GoogleFonts.outfit(fontSize: 9, color: _C.sub), textAlign: TextAlign.center),
    ]),
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int tab;
  final void Function(int) onTap;
  const _BottomNav({required this.tab, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded,         Icons.home_outlined,        'Home',    _C.navHome),
      (Icons.public_rounded,       Icons.public_outlined,      'Impact',  _C.navImpact),
      (Icons.emoji_events_rounded, Icons.emoji_events_outlined,'Ranking', _C.navRanking),
      (Icons.person_rounded,       Icons.person_outline_rounded,'Profile', _C.navProfile),
    ];
    return Container(
      height: 72,
      decoration: BoxDecoration(color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))]),
      child: SafeArea(top: false, child: Row(children: List.generate(items.length, (i) {
        final (filled, outline, label, color) = items[i];
        final sel = i == tab;
        return Expanded(child: GestureDetector(
          onTap: () => onTap(i),
          behavior: HitTestBehavior.opaque,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(sel ? filled : outline, size: 26, color: sel ? color : const Color(0xFFBBBBBB)),
            const SizedBox(height: 3),
            Text(label, style: GoogleFonts.outfit(fontSize: 11,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                color: sel ? color : const Color(0xFFBBBBBB))),
          ]),
        ));
      }))),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swipe-to-Validate Button
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeValidateButton extends StatefulWidget {
  /// Returns true if XP was freshly awarded, false if already claimed today.
  final Future<bool> Function() onValidate;
  const _SwipeValidateButton({required this.onValidate});
  @override
  State<_SwipeValidateButton> createState() => _SwipeValidateButtonState();
}

class _SwipeValidateButtonState extends State<_SwipeValidateButton>
    with SingleTickerProviderStateMixin {
  double _drag       = 0;
  bool   _completed  = false;
  bool   _resetting  = false;
  bool   _freshXp    = true;   // true = new XP, false = already claimed today
  late AnimationController _sparkCtrl;
  late Animation<double>   _sparkAnim;

  static const double _trackH    = 62.0;
  static const double _thumbSize = 52.0;
  static const double _padding   = 5.0;

  @override
  void initState() {
    super.initState();
    _sparkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _sparkAnim = CurvedAnimation(parent: _sparkCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _sparkCtrl.dispose(); super.dispose(); }

  void _onPanUpdate(DragUpdateDetails d, double maxDrag) {
    if (_completed || _resetting) return;
    setState(() => _drag = (_drag + d.delta.dx).clamp(0, maxDrag));
    if (_drag >= maxDrag) _complete(maxDrag);
  }

  void _onPanEnd(double maxDrag) {
    if (_completed || _resetting) return;
    setState(() => _resetting = true);
    Future.microtask(() async {
      for (double t = _drag; t > 0; t -= 10) {
        if (!mounted) return;
        setState(() => _drag = t.clamp(0, maxDrag));
        await Future.delayed(const Duration(milliseconds: 8));
      }
      if (mounted) setState(() { _drag = 0; _resetting = false; });
    });
  }

  void _complete(double maxDrag) {
    setState(() { _drag = maxDrag; _completed = true; });
    widget.onValidate().then((awarded) {
      if (!mounted) return;
      setState(() => _freshXp = awarded);
      // Only burst sparkles for a fresh XP award
      if (awarded) _sparkCtrl.forward(from: 0);
      // Auto-reset after brief display
      Future.delayed(const Duration(milliseconds: 1800), () async {
        if (!mounted) return;
        _sparkCtrl.reset();
        for (double t = maxDrag; t > 0; t -= 12) {
          if (!mounted) return;
          setState(() => _drag = t.clamp(0, maxDrag));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        if (mounted) setState(() { _drag = 0; _completed = false; _freshXp = true; });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const trackBg = Color(0xFF1A1A2E);
    const gold1   = Color(0xFFD4AF37);
    const gold2   = Color(0xFFF5C842);
    const radius  = 31.0;

    return LayoutBuilder(builder: (_, box) {
      final maxDrag = box.maxWidth - _thumbSize - _padding * 2;
      final pct     = maxDrag > 0 ? (_drag / maxDrag).clamp(0.0, 1.0) : 0.0;

      return GestureDetector(
        onHorizontalDragUpdate: (d) => _onPanUpdate(d, maxDrag),
        onHorizontalDragEnd:    (_) => _onPanEnd(maxDrag),
        child: Container(
          height: _trackH,
          decoration: BoxDecoration(
            color: trackBg,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Stack(alignment: Alignment.centerLeft, children: [

            // Gold fill grows with drag
            Container(
              width: (_thumbSize + _padding + _drag).clamp(0.0, box.maxWidth),
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [gold1, gold2],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(radius),
              ),
            ),

            // Hint text fades as thumb slides right
            Center(
              child: Opacity(
                opacity: (1 - pct * 2.4).clamp(0.0, 1.0),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white54, size: 16),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white30, size: 16),
                  const SizedBox(width: 4),
                  Text('Swipe to Validate  ☭',
                      style: GoogleFonts.outfit(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: Colors.white70)),
                ]),
              ),
            ),

            // Completed celebration / already-claimed label
            if (_completed)
              Center(
                child: Text(
                  _freshXp
                      ? '✅  JazakAllah! +${XpReward.validateCoins} XP'
                      : '☑️  Already validated today',
                  style: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ),

            // Draggable thumb
            Positioned(
              left: _padding + _drag,
              child: AnimatedBuilder(
                animation: _sparkAnim,
                builder: (_, child) => Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Particle burst on complete
                    if (_sparkAnim.value > 0)
                      ...List.generate(8, (i) {
                        final r = _sparkAnim.value * 30.0;
                        return Transform.translate(
                          offset: Offset(
                              r * (i.isEven ? 1.0 : -0.8) * (i < 4 ? 1 : -0.6),
                              r * (i < 4 ? -1.0 : 0.9)),
                          child: Opacity(
                            opacity: (1 - _sparkAnim.value).clamp(0.0, 1.0),
                            child: Container(
                              width: 5, height: 5,
                              decoration: BoxDecoration(
                                color: i.isEven ? gold2 : Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    child!,
                  ],
                ),
                child: Container(
                  width: _thumbSize, height: _thumbSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [gold1, gold2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(
                        color: gold2.withValues(alpha: 0.55),
                        blurRadius: 14, spreadRadius: 1)],
                  ),
                  child: Center(
                    child: _completed
                        ? const Icon(Icons.check_rounded,
                            color: Color(0xFF1A1A2E), size: 26)
                        : Text('☭',
                            style: GoogleFonts.outfit(
                                fontSize: 22,
                                color: const Color(0xFF1A1A2E),
                                fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ),

          ]),
        ),
      );
    });
  }
}
