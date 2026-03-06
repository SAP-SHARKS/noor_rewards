import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'quran_hub_screen.dart';
import 'dhikr_hub_screen.dart';
import 'tafsir_hub_screen.dart';
import 'level_screen.dart';
import 'impact_report_screen.dart';
import 'admin/admin_dashboard.dart';
import '../services/xp_service.dart';
import '../services/tracking_service.dart';
import '../services/donation_service.dart';
import '../services/streak_service.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'streak_screen.dart';
// ── Admin email whitelist (client-side guard) ─────────────────────────────────
const _kAdminEmails = {'pak.zakn@gmail.com', 'zaid_azam@zeir.io'};

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
  static const quranIcon   = Color(0xFF2BAE99);
  static const dhikrIcon   = Color(0xFFE05C6A);
  static const navHome     = Color(0xFFE8643A);
  static const navImpact   = Color(0xFF2BAE9B);
  static const navRanking  = Color(0xFFD4A017);
  static const navProfile  = Color(0xFF6B4EBB);
  static const teal        = Color(0xFF2BAE99);
  static const border      = Color(0xFFE8E8EC);
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
  StreakSnapshot _streakSnap = StreakSnapshot.empty;
  String? _country;

  // Community project
  Map<String, dynamic>? _project;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    // Claim daily login XP once per day (fire & forget)
    XpService.instance.claimDailyLoginXp();
    // Record login streak
    StreakService.instance.recordActivity(StreakType.login);
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

      // Load streak snapshot
      final snap = await StreakService.instance.loadSnapshot();
      _streakSnap = snap;

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
          streakSnap: _streakSnap,
          project: _project,
          onGoQuran:       () => _goToScreen(const QuranHubScreen()),
          onGoDhikr:       () => _goToScreen(const DhikrHubScreen()),
          onGoTafsir:      () => _goToScreen(const TafsirHubScreen()),
          onGoAchievements:() => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const LevelScreen())),
          onGoInvite: () {
            final uid = Supabase.instance.client.auth.currentUser?.id;
            if (uid == null) return;
            Supabase.instance.client.from('profiles').select('referral_code').eq('id', uid).single().then((res) {
              final code = res['referral_code'] as String?;
              if (!mounted) return;
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (ctx) => _InviteSheet(referralCode: code ?? ''),
              );
            });
          },
          onValidate: () async {
            final awarded = await XpService.instance.claimValidateXp();
            await _loadHomeData();
            return awarded;
          },
        ),
        const ImpactReportScreen(isTab: true),
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
// ─────────────────────────────────────────────────────────────────────────────
// HOME TAB
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final String name, levelTitle;
  final int noorPoints, todayPoints, weekPoints, monthPoints, streak, totalXp, level;
  final Map<String, dynamic>? project;
  final StreakSnapshot streakSnap;
  final VoidCallback onGoQuran, onGoDhikr, onGoTafsir, onGoAchievements, onGoInvite;
  final Future<bool> Function() onValidate;
  const _HomeTab({
    required this.name, required this.noorPoints, required this.todayPoints,
    required this.weekPoints, required this.monthPoints, required this.streak,
    required this.totalXp, required this.level, required this.levelTitle,
    required this.project, required this.streakSnap,
    required this.onGoQuran, required this.onGoDhikr,
    required this.onGoTafsir, required this.onValidate, required this.onGoAchievements,
    required this.onGoInvite,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<Map<String, dynamic>> _myDonations = [];
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadDonations();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showValidateModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.darkBtn,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFFDD88FF), Color(0xFF9B59B6)]),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF9B59B6).withValues(alpha: 0.5), blurRadius: 20)
                ],
              ),
              child: const Icon(Icons.nights_stay_rounded, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 24),
            Text(
              "🏆 Daily Azkaar Complete! Masha'Allah!",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              "You've completed your daily prayers and tracking. Keep up your streak, believer!",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDD88FF).withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🔥', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  '+20 XP',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFFDD88FF)),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A017),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Alhamdulillah',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDonations() async {
    try {
      // Load ALL active, non-completed projects so every card shows
      final projects = await Supabase.instance.client
          .from('community_projects')
          .select()
          .eq('is_active', true)
          .eq('is_completed', false)
          .order('sort_order');

      final data = List<Map<String, dynamic>>.from(
        (projects as List).map((p) => Map<String, dynamic>.from(p as Map))
      );

      if (data.isEmpty) {
        if (mounted) setState(() => _myDonations = []);
        return;
      }

      // Fetch the current user's donations to overlay my_donated per project
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        final pids = data.map((d) => d['id'] as String).toList();
        final myDonations = await Supabase.instance.client
            .from('user_donations')
            .select('project_id, points_donated')
            .eq('user_id', uid)
            .filter('project_id', 'in', pids);

        final Map<String, int> myPts = {};
        for (final r in (myDonations as List)) {
          final pid = r['project_id'] as String;
          myPts[pid] = (myPts[pid] ?? 0) + ((r['points_donated'] as num?)?.toInt() ?? 0);
        }
        for (final d in data) {
          d['my_donated'] = myPts[d['id']] ?? 0;
        }
      } else {
        for (final d in data) { d['my_donated'] = 0; }
      }

      // Also refresh current_points from actual donation totals
      final pids = data.map((d) => d['id'] as String).toList();
      final sumRes = await Supabase.instance.client
          .from('user_donations')
          .select('project_id, points_donated')
          .filter('project_id', 'in', pids);

      final Map<String, int> totalPts = {};
      for (final r in (sumRes as List)) {
        final pid = r['project_id'] as String;
        totalPts[pid] = (totalPts[pid] ?? 0) + ((r['points_donated'] as num?)?.toInt() ?? 0);
      }
      for (final d in data) {
        d['current_points'] = totalPts[d['id']] ?? 0;
      }

      if (mounted) setState(() => _myDonations = data);
    } catch (_) {
      if (mounted) setState(() => _myDonations = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.name.split(' ').first;
    return SafeArea(child: Stack(
      children: [
        SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),

        // ── Top bar ───────────────────────────────────────────────────────
        Row(children: [
          GestureDetector(
            onTap: widget.onGoAchievements,
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
                  Text(_fmt(widget.noorPoints),
                      style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
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
            onTap: widget.onGoAchievements,
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
                child: Text('LV ${widget.level}', style: GoogleFonts.rajdhani(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
              )),
            ]),
          ),
        ]),

        // ── Noor Counter (tasbih drum display) ────────────────────────────────
        const SizedBox(height: 22),
        Center(child: _NoorCounter(
          value: widget.todayPoints > 0 ? widget.todayPoints : widget.noorPoints,
        )),

        // ── Swipe-to-Validate button (close to Today's points) ────────────────
        const SizedBox(height: 18),
        _SwipeValidateButton(onValidate: () async {
          final awarded = await widget.onValidate();
          if (awarded && mounted) {
            _confettiController.play();
            _showValidateModal();
          }
          return awarded;
        }),

        // ── Streak Banner ─────────────────────────────────────────────────
        const SizedBox(height: 20),
        _StreakBanner(snap: widget.streakSnap),

        // ── Progress card (Daily / Weekly / Monthly) ──────────────────────
        const SizedBox(height: 20),
        _ProgressCard(
          todayPts: widget.todayPoints,
          weekPts:  widget.weekPoints,
          monthPts: widget.monthPoints,
          streak:   widget.streak,
        ),


        // ── Community progress ────────────────────────────────────────────
        const SizedBox(height: 20),
        if (widget.project != null) _CommunityCard(project: widget.project!),

        // ── My Donations ─────────────────────────────────────────────────
        if (_myDonations.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('🎯 RECITE MORE.',
                    style: GoogleFonts.rajdhani(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _C.text,
                        letterSpacing: 0.8,
                        height: 1.0)),
                Text('HELP REAL LIVES.',
                    style: GoogleFonts.rajdhani(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2BAE99),
                        letterSpacing: 0.8,
                        height: 1.1)),
                const SizedBox(height: 3),
                Text('Your Noor Points fund these projects',
                    style: GoogleFonts.outfit(
                        fontSize: 12, fontWeight: FontWeight.w500, color: _C.sub)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF2BAE99).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2BAE99).withValues(alpha: 0.3)),
              ),
              child: Text('${_myDonations.length} active',
                  style: GoogleFonts.rajdhani(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: const Color(0xFF2BAE99))),
            ),
          ]),
          const SizedBox(height: 12),
          _MyDonationsSection(
            donations: _myDonations,
            availablePoints: widget.noorPoints,
            onDonateMore: (project) {
              final parentState = context.findAncestorStateOfType<_DashboardScreenState>();
              parentState?.setState(() => parentState._tab = 1);
            },
          ),
        ],

        // ── Activity grid ─────────────────────────────────────────────────
        const SizedBox(height: 24),
        Text('EARN NOOR POINTS',
            style: GoogleFonts.rajdhani(fontSize: 20, fontWeight: FontWeight.w700,
                color: _C.text, letterSpacing: 1.0)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.92,
          children: [
            _ActivityCard('Read Quran',    '📖', _C.quranCard,  _C.quranIcon,  '+5 XP / ayah',  widget.onGoQuran),
            _ActivityCard('Dhikar & Dua',  '📿', _C.dhikrCard,  _C.dhikrIcon,  '+10 XP / set',  widget.onGoDhikr),
            _ActivityCard('Invite Friends','🤝', const Color(0xFFFFF0F5), const Color(0xFFE91E63), '+500 Coins', widget.onGoInvite),
            _ActivityCard('Achievements',  '🏆', const Color(0xFFEDE0FF), _C.navProfile, '${_fmt(widget.totalXp)} XP • Lv ${widget.level}', widget.onGoAchievements),
          ],
        ),

        // ── Ad Placement Placeholder ──────────────────────────────────────
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.ad_units_rounded, color: Colors.grey[400], size: 24),
              const SizedBox(height: 4),
              Text('Ad Placement Banner', 
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500])),
            ],
          ),
        ),
      ]),
    ),
      Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ],
            createParticlePath: (size) {
              final path = Path();
              path.addOval(Rect.fromCircle(center: Offset.zero, radius: 4));
              return path;
            }),
      ),
    ]));
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
// Invite Friends Sheet  — share · copy link · WhatsApp · apply code
// ─────────────────────────────────────────────────────────────────────────────
class _InviteSheet extends StatefulWidget {
  final String referralCode;
  const _InviteSheet({required this.referralCode});

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet>
    with SingleTickerProviderStateMixin {
  final _codeCtrl = TextEditingController();
  bool _loading   = false;
  String? _error;
  String? _success;
  bool _codeCopied = false;
  bool _linkCopied = false;

  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmer;

  String get _shareLink =>
      'https://noorrewards.app/join?ref=${widget.referralCode}';

  String get _shareMessage =>
      '🌙 Join me on Noor Rewards — earn points for daily Quran, Dhikr & good deeds!\n\n'
      'Use my code *${widget.referralCode}* and we both get 500 Noor Points! 🎁\n\n'
      '👉 $_shareLink';

  @override
  void initState() {
    super.initState();
    _shimmerCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _copyCode() {
    if (widget.referralCode.isEmpty) return;
    Clipboard.setData(ClipboardData(text: widget.referralCode));
    setState(() { _codeCopied = true; _linkCopied = false; });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _shareLink));
    setState(() { _linkCopied = true; _codeCopied = false; });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _linkCopied = false);
    });
  }

  void _shareGeneral() {
    // ignore: deprecated_member_use
    Share.share(_shareMessage, subject: 'Join Noor Rewards 🌙');
  }

  void _shareWhatsApp() async {
    final encoded = Uri.encodeComponent(_shareMessage);
    // whatsapp:// deep link — opens WhatsApp directly if installed
    final waUri = Uri.parse('whatsapp://send?text=$encoded');
    try {
      // ignore: deprecated_member_use
      await Share.shareUri(waUri);
    } catch (_) {
      // WhatsApp not installed or shareUri failed — fallback: copy + system share
      await Clipboard.setData(ClipboardData(text: _shareMessage));
      if (!mounted) return;
      // ignore: deprecated_member_use
      Share.share(_shareMessage, subject: 'Join Noor Rewards 🌙');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message copied — share or paste in WhatsApp!',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF25D366),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _applyCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      await Supabase.instance.client.rpc('apply_referral', params: {'inviter_code': code});
      setState(() => _success = '🎉 500 Noor Points rewarded to you both!');
    } catch (e) {
      final s = e.toString();
      if (s.contains('Already referred')) {
        setState(() => _error = 'You have already used a referral code.');
      } else if (s.contains('Invalid referral code')) {
        setState(() => _error = 'Invalid referral code.');
      } else if (s.contains('Cannot refer yourself')) {
        setState(() => _error = 'You cannot use your own code.');
      } else {
        setState(() => _error = 'An error occurred. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      if (mounted) {
        context.findAncestorStateOfType<_DashboardScreenState>()?._loadHomeData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.referralCode;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1923),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: EdgeInsets.fromLTRB(
                    22, 20, 22, MediaQuery.of(context).viewInsets.bottom + 30),
                children: [

                  // ── Header ──────────────────────────────────────────────────
                  Row(children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                          color: const Color(0xFF2BAE99).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Text('🤝', style: TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Invite Friends',
                          style: GoogleFonts.outfit(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      Text('You both earn 500 Noor Points!',
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: Colors.white54)),
                    ]),
                  ]),

                  const SizedBox(height: 22),

                  // ── Reward Banner ────────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _shimmer,
                    builder: (_, __) => Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A34), Color(0xFF0D2B26), Color(0xFF1E3A34)],
                          stops: [0.0, 0.5, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2BAE99).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _RewardPill(icon: '🫵', label: 'You get', points: '+500'),
                          Container(height: 40, width: 1, color: Colors.white12),
                          _RewardPill(icon: '👥', label: 'Friend gets', points: '+500'),
                          Container(height: 40, width: 1, color: Colors.white12),
                          _RewardPill(icon: '⚡', label: 'Instant', points: 'XP'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ── Your Code ────────────────────────────────────────────────
                  Text('YOUR REFERRAL CODE',
                      style: GoogleFonts.outfit(
                          fontSize: 11, fontWeight: FontWeight.w800,
                          color: Colors.white38, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2C38),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Text(
                          code.isNotEmpty ? code : '– – – – –',
                          style: GoogleFonts.outfit(
                              fontSize: 28, fontWeight: FontWeight.w900,
                              letterSpacing: 8, color: Colors.white),
                        ),
                      ),
                      GestureDetector(
                        onTap: _copyCode,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _codeCopied
                                ? const Color(0xFF2BAE99)
                                : const Color(0xFF2BAE99).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF2BAE99).withValues(alpha: 0.5)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(
                              _codeCopied ? Icons.check_rounded : Icons.copy_rounded,
                              size: 16, color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(_codeCopied ? 'Copied!' : 'Copy',
                                style: GoogleFonts.outfit(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ]),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 14),

                  // ── Share Link Row ────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2C38),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.link_rounded, size: 18, color: Colors.white38),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _shareLink,
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: Colors.white54),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: _copyLink,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _linkCopied
                                ? const Color(0xFF2BAE99)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _linkCopied ? 'Copied!' : 'Copy Link',
                            style: GoogleFonts.outfit(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 22),

                  // ── Share Buttons ─────────────────────────────────────────────
                  Text('SHARE VIA',
                      style: GoogleFonts.outfit(
                          fontSize: 11, fontWeight: FontWeight.w800,
                          color: Colors.white38, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Row(children: [
                    // WhatsApp
                    Expanded(
                      child: GestureDetector(
                        onTap: _shareWhatsApp,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A4731), Color(0xFF128C7E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFF25D366).withValues(alpha: 0.25),
                                  blurRadius: 12, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Text('💬', style: TextStyle(fontSize: 26)),
                            const SizedBox(height: 6),
                            Text('WhatsApp',
                                style: GoogleFonts.outfit(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // General Share
                    Expanded(
                      child: GestureDetector(
                        onTap: _shareGeneral,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A2A4A), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                                  blurRadius: 12, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Text('📤', style: TextStyle(fontSize: 26)),
                            const SizedBox(height: 6),
                            Text('Share More',
                                style: GoogleFonts.outfit(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ]),
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 30),

                  // ── Divider ──────────────────────────────────────────────────
                  Row(children: [
                    Expanded(child: Divider(color: Colors.white12)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Have an invite code?',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: Colors.white38)),
                    ),
                    Expanded(child: Divider(color: Colors.white12)),
                  ]),

                  const SizedBox(height: 16),

                  // ── Enter Code ───────────────────────────────────────────────
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: Colors.white, letterSpacing: 2),
                        decoration: InputDecoration(
                          hintText: 'Enter code…',
                          hintStyle: GoogleFonts.outfit(
                              fontSize: 15, color: Colors.white24),
                          filled: true,
                          fillColor: const Color(0xFF1C2C38),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFF2BAE99), width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _loading ? null : _applyCode,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 16),
                        decoration: BoxDecoration(
                          color: _loading
                              ? Colors.white10
                              : const Color(0xFF2BAE99),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text('Apply',
                                style: GoogleFonts.outfit(
                                    fontSize: 15, fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                      ),
                    ),
                  ]),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 16, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: GoogleFonts.outfit(
                                  color: Colors.redAccent,
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                      ]),
                    ),
                  ],
                  if (_success != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: const Color(0xFF2BAE99).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF2BAE99).withValues(alpha: 0.3))),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 16, color: Color(0xFF2BAE99)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_success!,
                              style: GoogleFonts.outfit(
                                  color: const Color(0xFF2BAE99),
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small reward pill widget used in the banner
class _RewardPill extends StatelessWidget {
  final String icon, label, points;
  const _RewardPill({required this.icon, required this.label, required this.points});
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 4),
      Text(points,
          style: GoogleFonts.outfit(
              fontSize: 16, fontWeight: FontWeight.w900,
              color: Color(0xFF2BAE99))),
      Text(label,
          style: GoogleFonts.outfit(
              fontSize: 11, color: Colors.white38)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak Banner — compact 3-card row shown on home tab
// ─────────────────────────────────────────────────────────────────────────────

class _StreakBanner extends StatefulWidget {
  final StreakSnapshot snap;
  const _StreakBanner({required this.snap});
  @override
  State<_StreakBanner> createState() => _StreakBannerState();
}

class _StreakBannerState extends State<_StreakBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  // Colors per streak type
  static const _cols = [Color(0xFFFF6B35), Color(0xFF00C875), Color(0xFF5856D6)];
  static const _bgCols = [Color(0xFFFFF0E6), Color(0xFFE6FFF5), Color(0xFFEEEDFF)];

  @override
  Widget build(BuildContext context) {
    final streaks = [widget.snap.login, widget.snap.dhikr, widget.snap.quran];
    final types   = StreakType.values;
    final best    = streaks.reduce((a, b) => a > b ? a : b);
    final next    = nextMilestone(best);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const StreakScreen())),
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, __) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1C1C2E), Color(0xFF2C1A3A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B35).withValues(alpha: _glow.value * 0.15),
                blurRadius: 20, spreadRadius: 2,
              ),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header row
            Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('STREAKS',
                  style: GoogleFonts.rajdhani(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: Colors.white, letterSpacing: 1.2)),
              const Spacer(),
              if (next != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.35)),
                  ),
                  child: Text('${next.emoji} Next: ${next.days}d',
                      style: GoogleFonts.rajdhani(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF9500))),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white30, size: 18),
            ]),
            const SizedBox(height: 14),

            // 3 streak chips
            Row(children: List.generate(3, (i) {
              final s = streaks[i];
              final c = _cols[i];
              final bg = _bgCols[i];
              final alive = s > 0;
              return Expanded(child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: alive
                        ? bg.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: alive
                          ? c.withValues(alpha: _glow.value * 0.55)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                    boxShadow: alive ? [BoxShadow(
                      color: c.withValues(alpha: _glow.value * 0.18),
                      blurRadius: 12,
                    )] : [],
                  ),
                  child: Column(children: [
                    Text(types[i].emoji,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text('$s',
                        style: GoogleFonts.rajdhani(
                            fontSize: 26, fontWeight: FontWeight.w900,
                            color: alive ? c : Colors.white24,
                            height: 1.0)),
                    Text('day${s == 1 ? '' : 's'}',
                        style: GoogleFonts.outfit(
                            fontSize: 9,
                            color: alive
                                ? c.withValues(alpha: 0.7)
                                : Colors.white24,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(types[i].label,
                        style: GoogleFonts.outfit(
                            fontSize: 9, color: Colors.white30),
                        overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ));
            })),
          ]),
        ),
      ),
    );
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
          Text('YOUR PROGRESS',
            style: GoogleFonts.rajdhani(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: _C.text, letterSpacing: 1.0)),
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
                style: GoogleFonts.rajdhani(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: 0.5)),
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
            style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w700,
                color: const Color(0xFF7A5C00), letterSpacing: 0.5),
            maxLines: 2, overflow: TextOverflow.ellipsis),
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
            style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w700,
                color: const Color(0xFF7A5C00), letterSpacing: 0.5)),
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
              Text(widget.title,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w700,
                    color: _C.text, letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Text(widget.reward,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: widget.iconColor)),
            ]),
          ]),
        ),
      ),
    );
  }
}


Widget _buildProjIcon(dynamic emojiVal, double size) {
  final e = emojiVal?.toString() ?? '🕌';
  if (e.startsWith('http')) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 3),
      child: Image.network(e, width: size * 1.5, height: size * 1.5, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text('🖼️', style: TextStyle(fontSize: size))),
    );
  }
  return Text(e, style: TextStyle(fontSize: size));
}

// ─────────────────────────────────────────────────────────────────────────────
// MY DONATIONS SECTION – shared by Home and Impact tabs
// ─────────────────────────────────────────────────────────────────────────────
class _MyDonationsSection extends StatelessWidget {
  final List<Map<String, dynamic>> donations;
  final int availablePoints;
  final void Function(Map<String, dynamic> project) onDonateMore;

  const _MyDonationsSection({
    required this.donations,
    required this.availablePoints,
    required this.onDonateMore,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 220,
          child: ListView.separated(
            clipBehavior: Clip.hardEdge,   // ← cards are clipped; no peeking until swipe
            scrollDirection: Axis.horizontal,
                itemCount: donations.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (ctx, i) {
                  final d = donations[i];
                  final target  = (d['target_points']  as num).toInt();
                  final current = (d['current_points'] as num).toInt();
                  final myPts   = (d['my_donated'] as num).toInt();
                  final remaining = (target - current).clamp(0, target);
                  
                  final pct = (current / target).clamp(0.0, 1.0);
                  final myPct = (myPts / target).clamp(0.0, 1.0);
                  final isCompleted = d['is_completed'] == true;

                  String fmt(int n) => n >= 1000000 ? '${(n/1000000).toStringAsFixed(1)}M' : (n >= 1000 ? '${(n/1000).toStringAsFixed(1)}k' : '$n');

                  return Container(
                    width: donations.length == 1 ? constraints.maxWidth : 280,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12, offset: const Offset(0, 4))],
                      border: Border.all(color: Colors.grey.shade100, width: 1.5),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Header
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFF7F4EF), borderRadius: BorderRadius.circular(12)),
                          child: _buildProjIcon(d['emoji'], 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(d['title'] ?? '',
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: _C.text),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                      const Spacer(),
                      
                      // Chart & Stats Row
                      Row(
                        children: [
                          // Circular Chart
                          SizedBox(
                            height: 74, width: 74,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(value: 1.0, strokeWidth: 7, color: Colors.grey.shade100, strokeCap: StrokeCap.round),
                                CircularProgressIndicator(value: pct, strokeWidth: 7, color: const Color(0xFFF59E0B), strokeCap: StrokeCap.round),
                                CircularProgressIndicator(value: myPct, strokeWidth: 7, color: const Color(0xFF2BAE7C), strokeCap: StrokeCap.round),
                                Center(
                                  child: isCompleted 
                                    ? const Icon(Icons.check_rounded, color: Color(0xFF2BAE7C), size: 28)
                                    : Text('${(pct * 100).toInt()}%', 
                                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: _C.text)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          
                          // Legends
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF2BAE7C), shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Text('Your Contribution', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                    const Spacer(),
                                    Text(fmt(myPts), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: _C.text)),
                                  ]
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Text("Others' Contribution", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                    const Spacer(),
                                    Text(fmt((current - myPts).clamp(0, current)), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: _C.text)),
                                  ]
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Text('Needed', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                    const Spacer(),
                                    Text(fmt(remaining), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: _C.text)),
                                  ]
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      
                      // Donate More button
                      if (!isCompleted && availablePoints > 0)
                        GestureDetector(
                          onTap: () => onDonateMore(d),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2BAE99), // matching _C.navImpact
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(myPts == 0 ? 'Donate Now →' : 'Donate More →',
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ),
                    ]),
                  );
                },
              ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOOR COUNTER — Tasbih drum-wheel style
// Each digit lives in its own physical scroll-wheel slot: dark Islamic-green
// gradient with top/bottom depth shadows, amber gold fold line, white glow text.
// Amber beads flank the drums like tasbih prayer beads.
// ─────────────────────────────────────────────────────────────────────────────
class _NoorCounter extends StatelessWidget {
  final int value;
  const _NoorCounter({required this.value});

  /// Insert commas: 12345 → "12,345"
  String _withCommas() {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = _withCommas();
    // One unified game-panel: drum display at top, label strip snapped at bottom.
    // ClipRRect clips both sections to shared rounded corners; the outer
    // DecoratedBox draws the single border + shadow around the whole unit.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFAA00).withValues(alpha: 0.22), width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFAA00).withValues(alpha: 0.16),
            blurRadius: 22, offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 8, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Drum display ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF14220F), Color(0xFF0A1208)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _NoorBead(),
                      const SizedBox(width: 10),
                      for (int i = 0; i < fmt.length; i++)
                        if (fmt[i] == ',')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(',',
                              style: GoogleFonts.rajdhani(
                                fontSize: 20, fontWeight: FontWeight.w700,
                                color: const Color(0xFFFFAA00).withValues(alpha: 0.55),
                              ),
                            ),
                          )
                        else
                          _DrumDigit(digit: fmt[i]),
                      const SizedBox(width: 10),
                      const _NoorBead(),
                    ],
                  ),
                ),
              ),

              // ── Thin amber divider — the seam between the two panels ──────
              Container(
                height: 0.8,
                color: const Color(0xFFFFAA00).withValues(alpha: 0.35),
              ),

              // ── Label strip — snapped directly to drums, no gap ───────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A6B5A), Color(0xFF2BAE99)],
                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                  ),
                ),
                child: Center(
                  child: Text('NOOR POINTS EARNED TODAY',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: Colors.white, letterSpacing: 2.0,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual digit scroll-wheel slot
class _DrumDigit extends StatelessWidget {
  final String digit;
  const _DrumDigit({required this.digit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 33,
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        // Lighter in the middle → looks like a cylinder curving away from us
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3414), Color(0xFF2E5228), Color(0xFF1A3414)],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFAA00).withValues(alpha: 0.28), width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(children: [
        // Top depth shadow — receding top of the drum
        Positioned(
          top: 0, left: 0, right: 0, height: 12,
          child: DecoratedBox(decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            gradient: LinearGradient(
              colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          )),
        ),
        // Bottom depth shadow
        Positioned(
          bottom: 0, left: 0, right: 0, height: 12,
          child: DecoratedBox(decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            gradient: LinearGradient(
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          )),
        ),
        // Amber fold line — the physical number-change crease of the drum
        Center(child: Container(
          height: 0.8,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFAA00).withValues(alpha: 0.45),
            boxShadow: [BoxShadow(
              color: const Color(0xFFFFAA00).withValues(alpha: 0.3),
              blurRadius: 4,
            )],
          ),
        )),
        // The digit
        Center(child: Text(digit,
          style: GoogleFonts.rajdhani(
            fontSize: 26, fontWeight: FontWeight.w700,
            color: Colors.white, height: 1,
            shadows: [
              Shadow(
                color: const Color(0xFFFFAA00).withValues(alpha: 0.45),
                blurRadius: 12,
              ),
            ],
          ),
        )),
      ]),
    );
  }
}

/// Amber tasbih bead flanking the drum row
class _NoorBead extends StatelessWidget {
  const _NoorBead();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10, height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFEE88), Color(0xFFFFAA00), Color(0xFFBB7700)],
          stops: [0.0, 0.55, 1.0],
          center: Alignment(-0.35, -0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFAA00).withValues(alpha: 0.65),
            blurRadius: 8, spreadRadius: 0,
          ),
        ],
      ),
    );
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
  List<Map<String, dynamic>> _myDonations = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await Supabase.instance.client.from('community_projects')
          .select().order('sort_order');
      _projects = List<Map<String, dynamic>>.from(res);
      
      // Calculate real total from user_donations
      final donationsSumRes = await Supabase.instance.client
          .from('user_donations')
          .select('project_id, points_donated');
          
      final Map<String, int> actualPoints = {};
      for (final d in (donationsSumRes as List)) {
        final pid = d['project_id'] as String;
        final pts = (d['points_donated'] as num?)?.toInt() ?? 0;
        actualPoints[pid] = (actualPoints[pid] ?? 0) + pts;
      }
      
      // Apply real totals and update completion status dynamically
      for (var p in _projects) {
        final realPts = actualPoints[p['id']] ?? 0;
        p['current_points'] = realPts;
        if (realPts >= ((p['target_points'] as num?)?.toInt() ?? 1)) {
          p['is_completed'] = true;
        } else {
          p['is_completed'] = false;
        }
      }
    } catch (_) {}
    
    // Load user's donations in parallel
    _myDonations = await DonationService.instance.getUserProjectDonations();
    
    // Sync the correct current_points into myDonations as well
    for (var m in _myDonations) {
      final realPts = _projects.cast<Map<String,dynamic>?>().firstWhere(
        (p) => p?['id'] == m['id'], orElse: () => null
      )?['current_points'];
      if (realPts != null) m['current_points'] = realPts;
    }

    if (mounted) setState(() => _loading = false);
  }

  String _fmtM(num n) => n >= 1000000 ? '${(n / 1000000).toStringAsFixed(1)}M' : (n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n');

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _C.navImpact));
    final active    = _projects.where((p) => p['is_active'] == true).toList();
    final completed = _projects.where((p) => p['is_completed'] == true).toList();
    
    // Get the user's available points from the main screen's state context
    final parentState = context.findAncestorStateOfType<_DashboardScreenState>();
    final availablePoints = parentState?._noorPoints ?? 0;

    return SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Community Impact heading only (Akhirah Balance is now the tab) ────
        // ── My personal donation history block removed (prevent repetition from Dashboard) ──

        Text('Community Impact', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: _C.text)),
        const SizedBox(height: 20),

        for (final p in active) ...[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _buildProjIcon(p['emoji'], 18),
                const SizedBox(width: 8),
                Expanded(child: Text('${p['title']}',
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
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Text('Sponsored by ${p['sponsor']}',
                    style: GoogleFonts.outfit(fontSize: 12, color: _C.sub),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                // ── Donate Button ──
                InkWell(
                  onTap: availablePoints > 0 ? () {
                    _showDonateSheet(context, p, availablePoints, parentState);
                  } : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: availablePoints > 0 ? _C.navImpact : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: availablePoints > 0 ? [BoxShadow(color: _C.navImpact.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
                    ),
                    child: Row(children: [
                      const Text('🪙', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text('Donate', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: availablePoints > 0 ? Colors.white : Colors.grey.shade600)),
                    ]),
                  ),
                ),
              ]),
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
                    child: Center(child: _buildProjIcon(p['emoji'], 24))),
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

  // ── Donate Dialog ──────────────────────────────────────────────────────────
  void _showDonateSheet(BuildContext context, Map<String, dynamic> project, int availablePoints, _DashboardScreenState? parentState) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: _DonateSheetContent(
          project: project,
          availablePoints: availablePoints,
          onSuccess: (amount) {
            // Refresh the Impact tab
            _load();
            // Update the parent dashboard (header) balance smoothly
            if (parentState != null) {
              parentState.setState(() {
                parentState._noorPoints = (parentState._noorPoints - amount).clamp(0, 99999999);
              });
            }
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DONATE BOTTOM SHEET CONTENT
// ─────────────────────────────────────────────────────────────────────────────
class _DonateSheetContent extends StatefulWidget {
  final Map<String, dynamic> project;
  final int availablePoints;
  final Function(int) onSuccess;

  const _DonateSheetContent({
    required this.project,
    required this.availablePoints,
    required this.onSuccess,
  });

  @override
  State<_DonateSheetContent> createState() => _DonateSheetContentState();
}

class _DonateSheetContentState extends State<_DonateSheetContent> {
  int _selectedAmount = 50;
  bool _donating = false;
  bool _success = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    if (widget.availablePoints < 50) _selectedAmount = widget.availablePoints;
  }

  void _setAmount(int amt) {
    setState(() {
      _selectedAmount = amt.clamp(1, widget.availablePoints);
      _errorMsg = null;
    });
  }

  Future<void> _processDonation() async {
    if (_selectedAmount <= 0 || _selectedAmount > widget.availablePoints) return;
    
    setState(() {
      _donating = true;
      _errorMsg = null;
    });

    final error = await DonationService.instance.donate(
      widget.project['id'] as String, 
      _selectedAmount,
    );

    if (!mounted) return;

    if (error == null) {
      // Success
      setState(() {
        _donating = false;
        _success = true;
      });
      widget.onSuccess(_selectedAmount);
      
      // Auto-close after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    } else {
      // Error
      setState(() {
        _donating = false;
        _success = false;
        _errorMsg = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_success) ...[
                // SUCCESS STATE
                const SizedBox(height: 8),
                const Icon(Icons.check_circle_rounded, color: _C.teal, size: 72),
                const SizedBox(height: 20),
                Text('Alhamdulillah!', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: _C.text)),
                const SizedBox(height: 12),
                Text('You donated $_selectedAmount points to\n${widget.project['title']}.', 
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 16, color: _C.sub, height: 1.4)),
                const SizedBox(height: 32),
              ] else ...[
              // INPUT STATE
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _C.communityBg, shape: BoxShape.circle),
                    child: _buildProjIcon(widget.project['emoji'], 28),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Support this Cause', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: _C.text)),
              Text(widget.project['title'], style: GoogleFonts.outfit(fontSize: 14, color: _C.sub, fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),

              // Available Balance
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Flexible(child: Text('Available Balance:', style: GoogleFonts.outfit(fontSize: 14, color: _C.sub), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text('${widget.availablePoints} pts', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: _C.text)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick amount selectors
              Row(
                children: [
                  _AmountPill(50, _selectedAmount, widget.availablePoints, () => _setAmount(50)),
                  const SizedBox(width: 10),
                  _AmountPill(100, _selectedAmount, widget.availablePoints, () => _setAmount(100)),
                  const SizedBox(width: 10),
                  _AmountPill(500, _selectedAmount, widget.availablePoints, () => _setAmount(500)),
                  const SizedBox(width: 10),
                  _AmountPill(widget.availablePoints, _selectedAmount, widget.availablePoints, () => _setAmount(widget.availablePoints), isMax: true),
                ],
              ),
              const SizedBox(height: 24),
              
              Text('Donation Amount', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: _C.sub)),
              const SizedBox(height: 8),
              
              // Big Number Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$_selectedAmount', style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w800, color: _C.navImpact, height: 1.0)),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('points', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: _C.sub)),
                  ),
                ],
              ),
              
              // Slider
              Slider(
                value: _selectedAmount.toDouble(),
                min: 1,
                max: widget.availablePoints.toDouble().clamp(1.0, double.infinity),
                activeColor: _C.navImpact,
                inactiveColor: _C.navImpact.withValues(alpha: 0.2),
                onChanged: widget.availablePoints > 0 ? (val) => _setAmount(val.round()) : null,
              ),

              if (_errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(_errorMsg!, style: GoogleFonts.outfit(fontSize: 13, color: Colors.red.shade700, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
              ] else ...[
                const SizedBox(height: 16),
              ],

              // Donate Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _donating || widget.availablePoints <= 0 ? null : _processDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.navImpact,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _donating
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text('Confirm Donation', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  }
}

class _AmountPill extends StatelessWidget {
  final int amount;
  final int selected;
  final int max;
  final VoidCallback onTap;
  final bool isMax;

  const _AmountPill(this.amount, this.selected, this.max, this.onTap, {this.isMax = false});

  @override
  Widget build(BuildContext context) {
    final isSelected = amount == selected;
    final isDisabled = amount > max && !isMax;

    return Expanded(
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _C.navImpact : (isDisabled ? Colors.grey.shade100 : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _C.navImpact : (isDisabled ? Colors.grey.shade200 : _C.border),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              isMax ? 'MAX' : '$amount',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : (isDisabled ? Colors.grey.shade400 : _C.text),
              ),
            ),
          ),
        ),
      ),
    );
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
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your Rank: #$_myRank',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: _C.text)),
              Text('Out of ${_leaders.length} users',
                  style: GoogleFonts.outfit(fontSize: 13, color: _C.sub)),
            ])),
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
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('7 Day Streak!',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFFFF6B9D))),
              Text('Keep it going to unlock rewards',
                  style: GoogleFonts.outfit(fontSize: 13, color: _C.sub)),
            ])),
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
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('7 Day Streak',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFFFF6B9D))),
                Text('Current streak', style: GoogleFonts.outfit(fontSize: 13, color: _C.sub)),
              ])),
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
// Swipe-to-Validate  ✦  "Circuit Connect" Edition
// Drag the crescent orb into the receptor socket to seal the day.
// ─────────────────────────────────────────────────────────────────────────────

// ── Energy particle behind the dragging orb ───────────────────────────────────
class _EnergyParticle {
  double x, y;       // position relative to track
  double vx, vy;    // velocity
  double life;      // 1.0 → 0.0
  final double size;
  final Color color;
  _EnergyParticle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.size, required this.color,
  }) : life = 1.0;
}

// ── Arc segments painter (lightning bolt between orb and socket) ──────────────
class _ArcPainter extends CustomPainter {
  final double fromX, toX, cy;
  final double progress; // 0–1, drives opacity
  final Color color;
  const _ArcPainter({
    required this.fromX, required this.toX,
    required this.cy, required this.progress, required this.color,
  });
  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rng = math.Random(7);
    final paint = Paint()
      ..color = color.withValues(alpha: progress * 0.9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    // Draw 3 jagged arcs
    for (int arc = 0; arc < 3; arc++) {
      final path = Path();
      path.moveTo(fromX, cy);
      final steps = 6;
      for (int s = 1; s <= steps; s++) {
        final t = s / steps;
        final bx = fromX + (toX - fromX) * t;
        final jitter = (rng.nextDouble() - 0.5) * 14 * progress;
        path.lineTo(bx, cy + (arc == 1 ? -jitter : jitter));
      }
      path.lineTo(toX, cy);
      paint.color = color.withValues(alpha: progress * (arc == 1 ? 0.9 : 0.45));
      canvas.drawPath(path, paint);
    }
    // Glow at endpoints
    final glowPaint = Paint()
      ..color = color.withValues(alpha: progress * 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(fromX, cy), 8 * progress, glowPaint);
    canvas.drawCircle(Offset(toX, cy), 10 * progress, glowPaint);
  }
  @override
  bool shouldRepaint(_ArcPainter o) => o.progress != progress || o.fromX != fromX;
}

// ── Main widget ───────────────────────────────────────────────────────────────
class _SwipeValidateButton extends StatefulWidget {
  final Future<bool> Function() onValidate;
  const _SwipeValidateButton({required this.onValidate});
  @override
  State<_SwipeValidateButton> createState() => _SwipeValidateButtonState();
}

class _SwipeValidateButtonState extends State<_SwipeValidateButton>
    with TickerProviderStateMixin {

  // ── Geometry ─────────────────────────────────────────────────────────────
  static const double _trackH    = 68.0;
  static const double _thumbSize = 56.0;
  static const double _padding   = 6.0;

  // ── State ──────────────────────────────────────────────────────────────
  double _drag      = 0;
  bool   _completed = false;
  bool   _resetting = false;
  bool   _freshXp   = true;
  bool   _dragging  = false;

  // Particles
  final List<_EnergyParticle> _particles = [];
  final _rng = math.Random();

  // ── Colors ────────────────────────────────────────────────────────────
  static const _trackBg    = Color(0xFF0A1F18);
  static const _neonGreen  = Color(0xFF00FFA3);
  static const _neonGold   = Color(0xFFFFD166);
  static const _socketRing = Color(0xFF1C5C45);

  static const _sparkPalette = [
    Color(0xFF00FFA3), Color(0xFF00FFCC), Color(0xFFFFFFFF),
    Color(0xFFFFD166), Color(0xFF39FFB6), Color(0xFFA0FFE0),
  ];

  // ── Controllers ──────────────────────────────────────────────────────
  // Particle / trail ticker
  late AnimationController _particleCtrl;

  // Socket pulse (proximity-driven speed)
  late AnimationController _socketCtrl;
  late Animation<double>   _socketPulse;

  // Arc flash on connect
  late AnimationController _arcCtrl;
  late Animation<double>   _arcAnim;

  // Completion burst
  late AnimationController _burstCtrl;
  late Animation<double>   _burstAnim;

  // Merged emblem scale-bounce
  late AnimationController _snapCtrl;
  late Animation<double>   _snapScale;

  // Halo rotation
  late AnimationController _haloCtrl;

  // Circuit fill (golden wash left→right after connect)
  late AnimationController _fillCtrl;
  late Animation<double>   _fillAnim;

  // Idle shimmer on text
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 16))
      ..repeat();
    _particleCtrl.addListener(_tickParticles);

    _socketCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _socketPulse = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _socketCtrl, curve: Curves.easeInOut));

    _arcCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _arcAnim = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOut));

    _burstCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _burstAnim = CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOut);

    _snapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _snapScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.90), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.00), weight: 15),
    ]).animate(CurvedAnimation(parent: _snapCtrl, curve: Curves.linear));

    _haloCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();

    _fillCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fillAnim = CurvedAnimation(parent: _fillCtrl, curve: Curves.easeOut);

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    _socketCtrl.dispose();
    _arcCtrl.dispose();
    _burstCtrl.dispose();
    _snapCtrl.dispose();
    _haloCtrl.dispose();
    _fillCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ── Particle tick ─────────────────────────────────────────────────────
  void _tickParticles() {
    if (!mounted) return;
    setState(() {
      for (final p in _particles) {
        p.x   += p.vx;
        p.y   += p.vy;
        p.life -= 0.045;
        p.vx  *= 0.94;
        p.vy  *= 0.94;
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  void _spawnParticles(double knobCx, double cy) {
    if (!_dragging) return;
    final count = 2 + _rng.nextInt(2);
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 0.6 + _rng.nextDouble() * 1.4;
      _particles.add(_EnergyParticle(
        x: knobCx + (_rng.nextDouble() - 0.5) * 10,
        y: cy    + (_rng.nextDouble() - 0.5) * 10,
        vx: math.cos(angle) * speed - 0.5,   // slight leftward drift
        vy: math.sin(angle) * speed * 0.55,
        size: 1.8 + _rng.nextDouble() * 2.2,
        color: _sparkPalette[_rng.nextInt(_sparkPalette.length)],
      ));
      if (_particles.length > 60) _particles.removeAt(0);
    }
  }

  // ── Socket pulse speed (proximity) ───────────────────────────────────
  void _updateSocketSpeed(double pct) {
    // 0% proximity → 800ms period, 100% → 200ms
    final ms = (800 - pct * 600).clamp(200.0, 800.0).toInt();
    if (_socketCtrl.duration?.inMilliseconds != ms) {
      _socketCtrl.duration = Duration(milliseconds: ms);
    }
  }

  // ── Input handlers ────────────────────────────────────────────────────
  void _onPanStart(DragStartDetails _) {
    if (_completed || _resetting) return;
    HapticFeedback.lightImpact();
    setState(() => _dragging = true);
  }

  void _onPanUpdate(DragUpdateDetails d, double maxDrag) {
    if (_completed || _resetting) return;
    setState(() {
      _drag = (_drag + d.delta.dx).clamp(0.0, maxDrag);
    });
    final pct = maxDrag > 0 ? _drag / maxDrag : 0.0;
    _updateSocketSpeed(pct);
    // spawn particles behind the orb
    _spawnParticles(_padding + _drag + _thumbSize / 2, _trackH / 2);
    if (_drag >= maxDrag) _complete(maxDrag);
  }

  void _onPanEnd(double maxDrag) {
    if (_completed || _resetting) return;
    HapticFeedback.selectionClick();
    setState(() { _dragging = false; _resetting = true; });
    _resetKnob(maxDrag);
  }

  Future<void> _resetKnob(double maxDrag) async {
    for (double t = _drag; t > 0; t -= 11) {
      if (!mounted) return;
      setState(() => _drag = t.clamp(0.0, maxDrag));
      await Future.delayed(const Duration(milliseconds: 9));
    }
    if (mounted) setState(() { _drag = 0; _resetting = false; _particles.clear(); });
  }

  void _complete(double maxDrag) {
    setState(() { _drag = maxDrag; _completed = true; _dragging = false; });
    // Step 1: heavy haptic snap
    HapticFeedback.heavyImpact();
    // Step 2: arc flash
    _arcCtrl.forward(from: 0);
    // Step 3: burst + snap scale + fill
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      _burstCtrl.forward(from: 0);
      _snapCtrl.forward(from: 0);
      _fillCtrl.forward(from: 0);
      HapticFeedback.mediumImpact();
    });

    widget.onValidate().then((awarded) {
      if (!mounted) return;
      setState(() => _freshXp = awarded);
      // Hold completed state, then reset
      Future.delayed(const Duration(milliseconds: 2200), () async {
        if (!mounted) return;
        _burstCtrl.reset();
        _arcCtrl.reset();
        _fillCtrl.reset();
        _particles.clear();
        for (double t = maxDrag; t > 0; t -= 14) {
          if (!mounted) return;
          setState(() => _drag = t.clamp(0.0, maxDrag));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        if (mounted) {
          setState(() {
            _drag = 0; _completed = false;
            _freshXp = true; _particles.clear();
          });
        }
      });
    });
  }


  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const radius = _trackH / 2;

    return LayoutBuilder(builder: (_, box) {
      final maxDrag   = box.maxWidth - _thumbSize - _padding * 2;
      final pct       = maxDrag > 0 ? (_drag / maxDrag).clamp(0.0, 1.0) : 0.0;
      final knobCx    = _padding + _drag + _thumbSize / 2;
      final socketCx  = box.maxWidth - _padding - _thumbSize / 2;  // right socket centre
      final trackCy   = _trackH / 2;
      final proximity = pct;  // 0 = far, 1 = touching

      return AnimatedBuilder(
        animation: Listenable.merge([
          _socketPulse, _arcAnim, _burstAnim, _snapScale,
          _haloCtrl, _fillAnim, _shimmerCtrl, _particleCtrl,
        ]),
        builder: (_, __) {
          return GestureDetector(
            onHorizontalDragStart:  _onPanStart,
            onHorizontalDragUpdate: (d) => _onPanUpdate(d, maxDrag),
            onHorizontalDragEnd:    (_) => _onPanEnd(maxDrag),
            child: SizedBox(
              height: _trackH,
              child: Stack(clipBehavior: Clip.none, children: [

                // ── Track background ───────────────────────────────────
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _trackBg,
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: _socketRing.withValues(alpha: 0.5), width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 20, offset: Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Golden circuit fill (animates left→right on complete)
                if (_fillAnim.value > 0)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _fillAnim.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFFD166).withValues(alpha: 0.25),
                                  const Color(0xFFFF9F1C).withValues(alpha: 0.15),
                                  const Color(0xFF00FFA3).withValues(alpha: 0.20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Progress fill (green, grows with drag) ────────────
                Positioned(
                  left: 0, top: 0, bottom: 0,
                  child: Container(
                    width: (_thumbSize + _padding + _drag).clamp(0.0, box.maxWidth),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0D3826),
                          const Color(0xFF115C3D),
                          Color.lerp(
                            const Color(0xFF1A7A52),
                            _neonGold,
                            (pct - 0.6).clamp(0.0, 1.0) / 0.4,
                          )!,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(radius),
                    ),
                  ),
                ),

                // ── Energy particles (CustomPaint) ────────────────────
                if (_particles.isNotEmpty)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: CustomPaint(
                        painter: _ParticlePainter(
                          particles: _particles,
                          trackH: _trackH,
                        ),
                      ),
                    ),
                  ),

                // ── Dashed dots on track (static circuit pattern) ─────
                Positioned(
                  left: _thumbSize + _padding * 2 + 8,
                  right: _thumbSize + _padding * 2 + 8,
                  top: 0, bottom: 0,
                  child: Opacity(
                    opacity: (1 - pct * 2).clamp(0.0, 0.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (i) => Container(
                        width: 3, height: 3,
                        decoration: BoxDecoration(
                          color: _neonGreen.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                      )),
                    ),
                  ),
                ),

                // ── Centre label ──────────────────────────────────────
                if (!_completed)
                  Center(
                    child: Opacity(
                      opacity: (1 - pct * 2.2).clamp(0.0, 1.0),
                      child: AnimatedBuilder(
                        animation: _shimmerCtrl,
                        builder: (_, __) => ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.55),
                              Colors.white.withValues(alpha: 0.9),
                              Colors.white.withValues(alpha: 0.55),
                            ],
                            stops: [
                              0.0,
                              _shimmerCtrl.value,
                              1.0,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'Seal the Day  ☽',
                            style: GoogleFonts.rajdhani(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Completed label ───────────────────────────────────
                if (_completed)
                  Center(
                    child: Text(
                      _freshXp
                          ? '✦  JazakAllah!  +${XpReward.validateCoins} XP'
                          : '✓  Already sealed today',
                      style: GoogleFonts.rajdhani(
                        fontSize: 14.5, fontWeight: FontWeight.w700,
                        color: _freshXp ? _neonGold : Colors.white,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),

                // ── Lightning arc flash ───────────────────────────────
                if (_arcAnim.value > 0 && !_completed)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: CustomPaint(
                        painter: _ArcPainter(
                          fromX: knobCx,
                          toX:   socketCx,
                          cy:    trackCy,
                          progress: _arcAnim.value,
                          color: _neonGreen,
                        ),
                      ),
                    ),
                  ),
                if (_arcAnim.value > 0 && _completed)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: CustomPaint(
                        painter: _ArcPainter(
                          fromX: socketCx - 20,
                          toX:   socketCx + 20,
                          cy:    trackCy,
                          progress: _arcAnim.value,
                          color: _neonGold,
                        ),
                      ),
                    ),
                  ),

                // ── Socket receptor (right side) ──────────────────────
                if (!_completed)
                  Positioned(
                    right: _padding,
                    top: (_trackH - _thumbSize) / 2,
                    child: _SocketWidget(
                      size: _thumbSize,
                      pulse: _socketPulse.value,
                      proximity: proximity,
                      neonGreen: _neonGreen,
                      socketRing: _socketRing,
                    ),
                  ),

                // ── Draggable orb (knob) ───────────────────────────────
                Positioned(
                  left: _padding + _drag,
                  top: (_trackH - _thumbSize) / 2,
                  child: _OrbWidget(
                    size: _thumbSize,
                    pct: pct,
                    completed: _completed,
                    snapScale: _snapScale.value,
                    burstProgress: _burstAnim.value,
                    haloAngle: _haloCtrl.value * math.pi * 2,
                    freshXp: _freshXp,
                    neonGreen: _neonGreen,
                    neonGold: _neonGold,
                  ),
                ),

              ]),
            ),
          );
        },
      );
    });
  }
}

// ── Particle painter ──────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_EnergyParticle> particles;
  final double trackH;
  const _ParticlePainter({required this.particles, required this.trackH});
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final a = p.life.clamp(0.0, 1.0);
      // Glow
      canvas.drawCircle(
        Offset(p.x, trackH / 2 + p.y - trackH / 2),
        p.size + 3,
        Paint()
          ..color = p.color.withValues(alpha: a * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Core
      canvas.drawCircle(
        Offset(p.x, trackH / 2 + p.y - trackH / 2),
        p.size,
        Paint()..color = p.color.withValues(alpha: a * 0.85),
      );
    }
  }
  @override
  bool shouldRepaint(_ParticlePainter o) => true;
}

// ── Socket widget (the right-side receptor that pulses and attracts) ──────────
class _SocketWidget extends StatelessWidget {
  final double size, pulse, proximity;
  final Color neonGreen, socketRing;
  const _SocketWidget({
    required this.size, required this.pulse, required this.proximity,
    required this.neonGreen, required this.socketRing,
  });
  @override
  Widget build(BuildContext context) {
    final glowAlpha  = (0.15 + pulse * 0.5 * proximity).clamp(0.0, 0.9);
    final ringScale  = 1.0 + pulse * 0.18 * proximity;
    return SizedBox(
      width: size, height: size,
      child: Center(
        child: Stack(alignment: Alignment.center, children: [
          // Outer proximity glow
          Transform.scale(
            scale: ringScale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: neonGreen.withValues(alpha: glowAlpha),
                    blurRadius: 18 + proximity * 16,
                    spreadRadius: proximity * 6,
                  ),
                ],
              ),
            ),
          ),
          // Ring border
          Container(
            width: size - 6,
            height: size - 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: neonGreen.withValues(alpha: 0.20 + proximity * 0.55),
                width: 1.5,
              ),
              color: socketRing.withValues(alpha: 0.3 + proximity * 0.3),
            ),
          ),
          // Inner ring
          Container(
            width: size - 18,
            height: size - 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: neonGreen.withValues(alpha: 0.10 + proximity * 0.40),
                width: 1,
              ),
            ),
          ),
          // Star icon in socket
          Text(
            '✦',
            style: TextStyle(
              fontSize: 18,
              color: neonGreen.withValues(alpha: 0.25 + proximity * 0.65),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Orb / knob widget ─────────────────────────────────────────────────────────
class _OrbWidget extends StatelessWidget {
  final double size, pct, snapScale, burstProgress, haloAngle;
  final bool completed, freshXp;
  final Color neonGreen, neonGold;
  const _OrbWidget({
    required this.size, required this.pct, required this.completed,
    required this.snapScale, required this.burstProgress, required this.haloAngle,
    required this.freshXp, required this.neonGreen, required this.neonGold,
  });

  @override
  Widget build(BuildContext context) {
    final orbColor  = Color.lerp(const Color(0xFF1A4A34), neonGold, pct * pct)!;
    final glowColor = completed
        ? (freshXp ? neonGold : neonGreen)
        : neonGreen;
    final glowAlpha = completed ? 0.70 : (0.15 + pct * 0.55);

    return SizedBox(
      width: size, height: size,
      child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [

        // ── Halo ring (spins when completed) ──────────────────────────
        if (completed)
          Transform.rotate(
            angle: haloAngle,
            child: Container(
              width: size + 14,
              height: size + 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    neonGold.withValues(alpha: 0.0),
                    neonGold.withValues(alpha: 0.6),
                    neonGold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

        // ── Glow aura ─────────────────────────────────────────────────
        Transform.scale(
          scale: snapScale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: glowAlpha),
                  blurRadius: 18 + pct * 14,
                  spreadRadius: pct * 5,
                ),
              ],
            ),
          ),
        ),

        // ── Orb body ──────────────────────────────────────────────────
        Transform.scale(
          scale: snapScale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: completed && freshXp
                  ? const RadialGradient(
                      colors: [Color(0xFFFFEEAA), Color(0xFFFFD166), Color(0xFF8B5E00)],
                      stops: [0.0, 0.55, 1.0],
                      center: Alignment(-0.25, -0.3),
                    )
                  : RadialGradient(
                      colors: [const Color(0xFFF0F0F0), orbColor, const Color(0xFF0A1F18)],
                      stops: const [0.0, 0.5, 1.0],
                      center: const Alignment(-0.3, -0.35),
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 12, offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 4, offset: const Offset(-1, -2),
                ),
              ],
            ),
            child: Center(
              child: completed
                  ? Text(
                      freshXp ? '☀' : '✓',
                      style: TextStyle(
                        fontSize: freshXp ? 26 : 22,
                        color: freshXp ? const Color(0xFF7A4500) : neonGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : Text(
                      '☽',
                      style: TextStyle(
                        fontSize: 22,
                        color: Color.lerp(
                          const Color(0xFF1A3E2F),
                          neonGold,
                          pct,
                        ),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ),

        // ── Burst sparks (radial explosion on connect) ─────────────────
        if (burstProgress > 0)
          ...List.generate(16, (i) {
            final angle = (i / 16.0) * math.pi * 2;
            final r1 = burstProgress * (i.isEven ? 46.0 : 30.0);
            final opacity = (1 - burstProgress * 1.1).clamp(0.0, 1.0);
            final colors = [
              neonGold, neonGreen, Colors.white,
              neonGold, const Color(0xFF39FFD6), Colors.white,
            ];
            return Transform.translate(
              offset: Offset(
                r1 * math.cos(angle),
                r1 * math.sin(angle),
              ),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: i.isEven ? 6 : 3.5,
                  height: i.isEven ? 6 : 3.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors[i % colors.length],
                    boxShadow: [
                      BoxShadow(
                        color: colors[i % colors.length].withValues(alpha: 0.7),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ]),
    );
  }
}

