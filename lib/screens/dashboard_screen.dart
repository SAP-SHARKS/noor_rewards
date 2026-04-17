import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quran_hub_screen.dart';
import 'dhikr_hub_screen.dart';
import 'tafsir_hub_screen.dart';
import 'level_screen.dart';
import 'impact_report_screen.dart';
import 'profile_settings_screen.dart';
import 'admin/admin_dashboard.dart';
import '../services/xp_service.dart';
import '../services/tracking_service.dart';
import '../services/donation_service.dart';
import '../services/streak_service.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'streak_screen.dart';
import '../widgets/noor_icons.dart';
import '../widgets/noor_offline.dart';
import '../widgets/motivational_popup.dart';
import '../widgets/project_media_carousel.dart';

// ── Admin email whitelist (client-side guard) ─────────────────────────────────
const _kAdminEmails = {'pak.zakn@gmail.com', 'zaid_azam@zeir.io'};

// ── Palette ────────────────────────────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFFF7F3EE);
  static const text        = Color(0xFF1C1C1E);
  static const sub         = Color(0xFF8E8E93);
  static const darkBtn     = Color(0xFF1C1C1E);
  static const communityBg = Color(0xFFFEF3D4);
  static const amber       = Color(0xFFF5A623);
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
  int _akhirahVisitCount = 0;
  final _supabase = Supabase.instance.client;

  // Profile state
  int? _noorPoints;
  int? _todayPoints;
  int? _weekPoints;
  int? _monthPoints;
  int? _streak;
  int? _totalXp;
  int _level       = 1;
  String _levelTitle = 'Seeker';
  StreakSnapshot _streakSnap = StreakSnapshot.empty;
  String? _country;
  String? _avatarUrl;

  // Community project
  Map<String, dynamic>? _project;

  int _adminRefreshCount = 0;
  bool _navVisible = true;

  // Nav Keys for nested routing
  final List<GlobalKey<NavigatorState>> _navKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  Widget _buildTabNavigator(int index, Widget child) {
    return Navigator(
      key: _navKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => child,
          settings: settings,
        );
      },
    );
  }

  // ── Motivational popup ───────────────────────────────────────────────────
  Timer? _startupPopupTimer;     // First popup after drum-counter animation
  Timer? _repeatingPopupTimer;   // Next popup timer (re-armed after each dismissal)
  bool   _popupVisible      = false; // True while a popup sheet is on screen
  bool   _sessionDnd        = false; // True after first DND tap — resets on restart
  bool   _isInFocusScreen   = false; // True while user is reading Quran/Dhikr/Tafsir
  bool   _counterAnimating  = true;  // Blocks popup while drum counter is rolling
  static const _kDndKey       = 'motivational_popup_dnd';       // permanent flag
  static const _kDndCountKey  = 'motivational_popup_dnd_count'; // tap counter

  // ── Home-tab visit tracking (drives counter re-animation) ────────────────
  int _homeVisitCount = 0;  // increments each time user lands on Home

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    // Claim daily login pts once per day (fire & forget)
    XpService.instance.claimDailyLoginXp();
    // Record login streak
    StreakService.instance.recordActivity(StreakType.login);
    // Start privacy-first analytics session
    TrackingService.instance.beginSession();
    // Schedule random motivational popup
    _scheduleMotivationalPopup();
  }

  @override
  void dispose() {
    _startupPopupTimer?.cancel();
    _repeatingPopupTimer?.cancel();
    // End session — saves accumulated time + coins to Supabase
    TrackingService.instance.endSession();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────
  // Motivational popup scheduler
  //
  // KEY FIX: The countdown to the NEXT popup doesn't start until the user
  // dismisses the current one (via whenComplete). This prevents stacking when
  // the phone is left idle — no matter how long the app is open, only one
  // popup can ever be queued at a time.
  //
  // • Popup #1: fires 5 s after app opens.
  // • After dismissal, next popup is scheduled 160–200 s later.
  // • _popupVisible gate prevents a new show if one is already on screen.
  // ────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleMotivationalPopup() async {
    // DISABLED per user request (temporarily hidden)
  }

  // Arms the NEXT single popup timer — called only after current popup closes.
  void _scheduleNextPopup() {
    // DISABLED per user request (temporarily hidden)
  }

  // ignore: unused_element
  void _doShowPopup() {
    // Block completely if the user chose Do Not Disturb or a popup is already active.
    if (!mounted || _sessionDnd || _popupVisible) return;

    // Wait if temporarily blocked by a focus screen or rolling counter
    if (_isInFocusScreen || _counterAnimating) {
      _scheduleNextPopup();
      return;
    }

    _popupVisible = true;
    showMotivationalPopup(
      context,
      onGoQuran: () => _goToScreen(const QuranHubScreen()),
      onGoDhikr: () => _goToScreen(const DhikrHubScreen()),
      onGoBoost: () => _goToScreen(const QuranHubScreen()),
      onShare: () {
        final uid = _supabase.auth.currentUser?.id;
        if (uid == null) return;
        _supabase
            .from('profiles')
            .select('referral_code')
            .eq('id', uid)
            .single()
            .then((res) {
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
      onDoNotDisturb: _markDoNotDisturb,
    ).whenComplete(() {
      // Popup was dismissed (via any action or swipe-down).
      // Only NOW do we arm the next timer — countdown starts from dismissal.
      if (mounted && !_sessionDnd) {
        _popupVisible = false;
        _scheduleNextPopup();
      }
    });
  }

  // DND logic:
  //   Tap #1 (any session) — session-only: cancels timers but resets on next launch.
  //   Tap #2 (next session after first DND) — permanent: written to SharedPreferences.
  Future<void> _markDoNotDisturb() async {
    _sessionDnd = true;
    _startupPopupTimer?.cancel();
    _repeatingPopupTimer?.cancel();
    try {
      final prefs = await SharedPreferences.getInstance();
      // Increment the DND tap count across sessions
      final prevCount = prefs.getInt(_kDndCountKey) ?? 0;
      final newCount  = prevCount + 1;
      await prefs.setInt(_kDndCountKey, newCount);
      if (newCount >= 2) {
        // Second tap — permanent block
        await prefs.setBool(_kDndKey, true);
      }
      // First tap: timers cancelled for this session; next restart they re-fire
    } catch (_) {}
  }

  Future<void> _loadHomeData() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final profile = await _supabase.from('profiles')
          .select('noor_points, country, total_xp, level, avatar_url').eq('id', uid).maybeSingle();
          
      if (profile != null) {
        _noorPoints = (profile['noor_points'] as num?)?.toInt() ?? 0;
        _totalXp    = (profile['total_xp']    as num?)?.toInt() ?? 0;
        _level      = (profile['level']       as num?)?.toInt() ?? 1;
        _country    = profile['country'] as String?;
        _avatarUrl  = profile['avatar_url'] as String?;
      } else {
        _noorPoints = 0; // Better to show 0 explicitly rather than leave null
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile returned zero rows for $uid')));
        }
      }

      // Resolve level title
      try {
        final levels = await _supabase.from('xp_levels')
            .select('level, title').eq('level', _level).maybeSingle();
        if (_levelTitle == 'Seeker' || _levelTitle == 'Champion' || _levelTitle == 'Legend' || _levelTitle == 'Believer' || _levelTitle == 'Devoted') {
            _levelTitle = (levels?['title'] as String?) ?? _levelTitleFor(_level);
        }
      } catch (_) {}

      // Fetch points in parallel, but handle individual failures safely without throwing everything via catchError
      final results = await Future.wait([
        _supabase.rpc('get_today_points').catchError((e) { print('today err: $e'); return 0; }),
        _supabase.rpc('get_week_points').catchError((e) { print('week err: $e'); return 0; }),
        _supabase.rpc('get_month_points').catchError((e) { print('month err: $e'); return 0; }),
        _supabase.rpc('get_day_streak').catchError((e) { print('streak err: $e'); return 0; }),
      ]);
      _todayPoints = (results[0] as num?)?.toInt() ?? 0;
      _weekPoints  = (results[1] as num?)?.toInt() ?? 0;
      _monthPoints = (results[2] as num?)?.toInt() ?? 0;
      _streak      = (results[3] as num?)?.toInt() ?? 0;

      // Load streak snapshot safely
      try {
        final snap = await StreakService.instance.loadSnapshot();
        _streakSnap = snap;
      } catch (_) {}

      try {
        final proj = await _supabase.from('community_projects')
            .select().eq('is_active', true).eq('is_completed', false)
            .order('sort_order', ascending: true, nullsFirst: false).limit(1).maybeSingle();
        _project = proj;
      } catch (_) {}
    } catch (e) {
      _levelTitle = 'Root error: $e';
      _noorPoints ??= 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dashboard Load Error: $e')));
      }
    }
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
    // Suppress popups while user is in a reading/focus screen
    _isInFocusScreen = true;
    final nav = _navKeys[_tab].currentState ?? Navigator.of(context);
    await nav.push<int>(
        MaterialPageRoute(builder: (_) => screen));
    _isInFocusScreen = false;
    _loadHomeData(); // Refresh points constantly on return
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final activeNav = _navKeys[_tab].currentState;
        if (activeNav != null && activeNav.canPop()) {
          activeNav.pop();
        } else {
          if (_tab != 0) {
            setState(() => _tab = 0);
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: _C.bg,
        extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notif) {
          if (notif.metrics.axis == Axis.vertical) {
            if (notif.direction == ScrollDirection.reverse) {
              if (_navVisible) setState(() => _navVisible = false);
            } else if (notif.direction == ScrollDirection.forward) {
              if (!_navVisible) setState(() => _navVisible = true);
            }
          }
          return false;
        },
        child: IndexedStack(index: _tab, children: [
          _HomeTab(
            key: ValueKey('home_${_adminRefreshCount}_${_noorPoints}_${_streak}'),
            name: widget.name,
            noorPoints: _noorPoints,
            totalXp: _totalXp ?? 0,
            level: _level,
            levelTitle: _levelTitle,
            todayPoints: _todayPoints,
            weekPoints: _weekPoints,
            monthPoints: _monthPoints,
            streak: _streak,
            streakSnap: _streakSnap,
            project: _project,
            homeVisitCount: _homeVisitCount,
            avatarUrl: _avatarUrl,
            onGoQuran:       () => _goToScreen(const QuranHubScreen()),
            onGoDhikr:       () => _goToScreen(const DhikrHubScreen()),
            onGoTafsir:      () => _goToScreen(const TafsirHubScreen()),
            onGoAchievements:() => setState(() => _tab = 1),
            onGoProfile: () => setState(() => _tab = 3),
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
            hasError: _noorPoints == null,
          ),
          _buildTabNavigator(1, const LevelScreen()),           // Tab 1 — Journey
          _buildTabNavigator(2, ImpactReportScreen(
            key: ValueKey('impact_$_adminRefreshCount'),
            isTab: true,
            visitCount: _akhirahVisitCount,
          )), // Tab 2 — Akhirah
          _buildTabNavigator(3, _ProfileTab(
              name: widget.name, noorPoints: _noorPoints ?? 0,
              totalXp: _totalXp ?? 0, level: _level, levelTitle: _levelTitle,
              country: _country, streak: _streak ?? 0,
              avatarUrl: _avatarUrl,
              currentUserId: _supabase.auth.currentUser?.id ?? '',
              onSignOut: _signOut,
              onRefresh: _loadHomeData)),
        ]),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        offset: _navVisible ? Offset.zero : const Offset(0, 1.2),
        child: _BottomNav(
          tab: _tab,
          onTap: (i) {
            if (i == 0 && _tab != 0) {
              // User returning to Home tab: kick off a new counter animation
              // and block any popup for the duration (300ms + 1400ms + 500ms = 2200ms).
              setState(() {
                _tab = i;
                _homeVisitCount++;
                _counterAnimating = true;
              });
              Future.delayed(const Duration(milliseconds: 2200), () {
                if (mounted) setState(() => _counterAnimating = false);
              });
            } else {
              if (i == 2 && _tab != 2) {
                setState(() => _akhirahVisitCount++);
              }
              // Keep on current tab: pop if not root to simulate returning to root
              final activeNav = _navKeys[i].currentState;
              if (activeNav != null && activeNav.canPop()) {
                activeNav.popUntil((route) => route.isFirst);
              }
              setState(() => _tab = i);
              _loadHomeData(); // Refresh values proactively
            }
          },
        ),
        ),
      ),
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
  final String? avatarUrl;
  final int? noorPoints, todayPoints, weekPoints, monthPoints, streak;
  final int totalXp, level;
  final int homeVisitCount;
  final Map<String, dynamic>? project;
  final StreakSnapshot streakSnap;
  final VoidCallback onGoQuran, onGoDhikr, onGoTafsir, onGoAchievements, onGoInvite;
  final VoidCallback? onGoProfile;
  final Future<bool> Function() onValidate;
  final bool hasError;
  const _HomeTab({
    super.key,
    required this.name, required this.noorPoints, required this.todayPoints,
    required this.weekPoints, required this.monthPoints, required this.streak,
    required this.totalXp, required this.level, required this.levelTitle,
    required this.project, required this.streakSnap,
    required this.homeVisitCount,
    this.avatarUrl,
    this.onGoProfile,
    required this.onGoQuran, required this.onGoDhikr,
    required this.onGoTafsir, required this.onValidate, required this.onGoAchievements,
    required this.onGoInvite,
    this.hasError = false,
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
    showValidationRewardPopup(
      context,
      xpEarned: 20, // XpReward.validateCoins
      bonusPoints: 0, // streak bonus could be added here later
      onContinue: _triggerBoostPopup,
    );
  }

  // Shows the Noor Boost popup — called after validation is confirmed
  void _triggerBoostPopup() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      showNoorBoostPopup(
        context,
        onGoQuran:  widget.onGoQuran,
        onGoDhikr:  widget.onGoDhikr,
        onGoInvite: widget.onGoInvite,
      );
    });
  }

  Future<void> _loadDonations() async {
    try {
      // Load ALL active, non-completed projects so every card shows
      final projects = await Supabase.instance.client
          .from('community_projects')
          .select()
          .eq('is_active', true)
          .eq('is_completed', false)
          .order('sort_order', ascending: true, nullsFirst: false);

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
        // ── Subtle home background pattern ───────────────────────────────
        Positioned.fill(
          child: CustomPaint(
            painter: _HomeBgPainter(),
          ),
        ),
        SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
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
                  Text(widget.hasError || widget.noorPoints == null ? '---' : _fmt(widget.noorPoints ?? 0),
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
            onTap: () => widget.onGoProfile?.call(),
            child: Stack(clipBehavior: Clip.none, children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFFDD88FF), Color(0xFF9B59B6)]),
                  image: widget.avatarUrl != null
                      ? DecorationImage(image: NetworkImage(widget.avatarUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: widget.avatarUrl == null
                    ? Center(child: Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'N',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)))
                    : null),
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
          value: widget.noorPoints ?? 0,
          visitCount: widget.homeVisitCount,
        )),

        // ── Swipe-to-Validate button (close to Today's points) ────────────────
        const SizedBox(height: 18),
        _SwipeValidateButton(onValidate: () async {
          final awarded = await widget.onValidate();
          if (!mounted) return awarded;
          if (awarded) {
            // Fresh pts: play confetti + full celebration modal
            _confettiController.play();
            _showValidateModal(); // modal calls _triggerBoostPopup on dismiss
          } else {
            // Already validated today: skip the modal but still show boost nudge
            _triggerBoostPopup();
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
          hasError: widget.hasError,
        ),




        // ── My Donations ─────────────────────────────────────────────────
        if (_myDonations.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [NoorIcon.target(size: 18), const SizedBox(width: 6), Text('RECITE MORE.',
                    style: GoogleFonts.rajdhani(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _C.text,
                        letterSpacing: 0.8,
                        height: 1.0))]),
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
            availablePoints: widget.noorPoints ?? 0,
            onDonateMore: (project) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommunityImpactPage(scrollToProjectId: project['id'] as String?),
                ),
              );
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
            _ActivityCard('Read Quran',    NoorIcon.book(size: 28),
              solid: const Color(0xFF3B72F6),
              solidDeep: const Color(0xFF1A4DC4),
              reward: '+5 pts / ayah',
              patternType: _CardPattern.arcRings,
              onTap: widget.onGoQuran),
            _ActivityCard('Dhikar & Dua',  NoorIcon.beads(size: 28),
              solid: const Color(0xFF18B97A),
              solidDeep: const Color(0xFF0A7A50),
              reward: '+10 pts / set',
              patternType: _CardPattern.floatingDots,
              onTap: widget.onGoDhikr),
            _ActivityCard('Invite Friends', NoorIcon.handshake(size: 28),
              solid: const Color(0xFFE8446A),
              solidDeep: const Color(0xFFA81A43),
              reward: '+500 Coins',
              patternType: _CardPattern.speedLines,
              onTap: widget.onGoInvite),
            _ActivityCard('Achievements',   NoorIcon.trophy(size: 28),
              solid: const Color(0xFF8B5CF6),
              solidDeep: const Color(0xFF5B21B6),
              reward: '${_fmt(widget.totalXp)} pts • Lv ${widget.level}',
              patternType: _CardPattern.diamondSparks,
              onTap: widget.onGoAchievements),
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
      'Join me on Noor Rewards — earn points for daily Quran, Dhikr & good deeds!\n\n'
      'Use my code *${widget.referralCode}* and we both get 500 Noor Points!\n\n'
      '$_shareLink';

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
    Share.share(_shareMessage, subject: 'Join Noor Rewards');
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
      Share.share(_shareMessage, subject: 'Join Noor Rewards');
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
      setState(() => _success = '500 Noor Points rewarded to you both!');
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
                      child: Center(child: NoorIcon.handshake(size: 24)),
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
                          _RewardPill(icon: NoorIcon.pointing(size:20), label: 'You get', points: '+500'),
                          Container(height: 40, width: 1, color: Colors.white12),
                          _RewardPill(icon: NoorIcon.people(size:20), label: 'Friend gets', points: '+500'),
                          Container(height: 40, width: 1, color: Colors.white12),
                          _RewardPill(icon: NoorIcon.lightning(size:20), label: 'Instant', points: 'pts'),
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
                            NoorIcon.chat(size: 26),
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
                            NoorIcon.share(size: 26),
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
  final Widget icon;
  final String label, points;
  const _RewardPill({required this.icon, required this.label, required this.points});
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      icon,
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

  // Solid card colors — (light center, deep outer) for radial gradient
  static const _cardColors = [
    [Color(0xFFF9CB5C), Color(0xFFE08A0E)], // Login   — warm amber
    [Color(0xFF3DDBA0), Color(0xFF0B9E63)], // Dhikr   — emerald
    [Color(0xFF9B87F5), Color(0xFF4B35D4)], // Quran   — indigo violet
  ];
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 16, offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header row
            Row(children: [
              NoorIcon.fire(size:16),
              const SizedBox(width: 6),
              Text('STREAKS',
                  style: GoogleFonts.rajdhani(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D2C1E), letterSpacing: 1.2)),
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
                  color: Color(0xFFBB8B6E), size: 18),
            ]),
            const SizedBox(height: 14),

            // 3 streak chips — solid bold cards with sunburst rays
            Row(children: List.generate(3, (i) {
              final s      = streaks[i];
              final alive  = s > 0;
              final colors = _cardColors[i];
              final type   = types[i];

              return Expanded(child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
                child: AnimatedBuilder(
                  animation: _glow,
                  builder: (_, __) {
                    final decoration = BoxDecoration(
                      gradient: alive
                          ? RadialGradient(
                              colors: [colors[0], colors[1]],
                              center: const Alignment(-0.2, -0.5),
                              radius: 1.4,
                            )
                          : const RadialGradient(
                              colors: [Color(0xFFF4F4F4), Color(0xFFD8D8D8)],
                              center: Alignment(-0.2, -0.5),
                              radius: 1.3,
                            ),
                      borderRadius: BorderRadius.circular(18),
                    );
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: alive ? [
                          BoxShadow(
                            color: colors[1].withValues(alpha: _glow.value * 0.50),
                            blurRadius: 16, offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: colors[0].withValues(alpha: 0.25),
                            blurRadius: 4, offset: const Offset(0, 1),
                          ),
                        ] : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6, offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(children: [
                          // ── Solid gradient base ───────────────────────────
                          Positioned.fill(child: DecoratedBox(decoration: decoration)),

                          // ── Sunburst rays (only when alive) ──────────────
                          if (alive)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: const _SunburstPainter(
                                  count: 9,
                                  focalX: 0.5,
                                  focalY: -0.05,
                                  rayAlpha: 0.15,
                                ),
                              ),
                            ),

                          // ── Content ───────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 8),
                            child: Column(children: [
                              NoorIcon.fromEmoji(type.emoji, size: 22),
                              const SizedBox(height: 6),
                              Text('$s',
                                  style: GoogleFonts.rajdhani(
                                      fontSize: 28, fontWeight: FontWeight.w900,
                                      color: alive ? Colors.white : Colors.grey.shade400,
                                      height: 1.0,
                                      shadows: alive ? [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.25),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ] : null)),
                              Text('day${s == 1 ? '' : 's'}',
                                  style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      color: alive
                                          ? Colors.white.withValues(alpha: 0.80)
                                          : Colors.grey.shade400,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: alive
                                      ? Colors.white.withValues(alpha: 0.22)
                                      : Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(type.label,
                                    style: GoogleFonts.outfit(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: alive
                                            ? Colors.white.withValues(alpha: 0.9)
                                            : Colors.grey.shade400),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                          ),
                        ]),
                      ),
                    );
                  },
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
// Sunburst ray painter — radiating wedge rays from a focal point
// ─────────────────────────────────────────────────────────────────────────────
class _SunburstPainter extends CustomPainter {
  final int count;    // number of bright rays (gaps = equal count)
  final double focalX, focalY; // focal point as fraction of width/height
  final double rayAlpha;   // opacity of bright ray fills
  const _SunburstPainter({
    this.count    = 10,
    this.focalX   = 0.50,
    this.focalY   = -0.15,
    this.rayAlpha = 0.16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  * focalX;
    final cy = size.height * focalY;
    final r  = math.sqrt(size.width * size.width + size.height * size.height) * 1.6;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: rayAlpha)
      ..style = PaintingStyle.fill;

    final step = math.pi * 2 / (count * 2); // angle per slice
    for (int i = 0; i < count; i++) {
      final a0 = i * 2 * step;
      final a1 = a0 + step;
      final path = Path()
        ..moveTo(cx, cy)
        ..lineTo(cx + r * math.cos(a0), cy + r * math.sin(a0))
        ..lineTo(cx + r * math.cos(a1), cy + r * math.sin(a1))
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SunburstPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily / Weekly / Monthly Progress Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final int? todayPts, weekPts, monthPts, streak;
  final bool hasError;
  const _ProgressCard({
    required this.todayPts,
    required this.weekPts,
    required this.monthPts,
    required this.streak,
    this.hasError = false,
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
              NoorIcon.fire(size:13),
              const SizedBox(width: 4),
              Text(hasError ? '---' : '${streak ?? 0} day${streak == 1 ? '' : 's'}',
                style: GoogleFonts.rajdhani(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: 0.5)),
            ]),
          ),
        ]),

        const SizedBox(height: 16),

        // Three progress bars
        _ProgBar(label: 'Today',   pts: todayPts, goal: _dayGoal,
            color: const Color(0xFF00897B), icon: NoorIcon.sunrise(size:16), hasError: hasError),
        const SizedBox(height: 12),
        _ProgBar(label: 'This Week', pts: weekPts, goal: _weekGoal,
            color: const Color(0xFF5C6BC0), icon: NoorIcon.calendar(size:16), hasError: hasError),
        const SizedBox(height: 12),
        _ProgBar(label: 'This Month', pts: monthPts, goal: _monthGoal,
            color: const Color(0xFFE91E8C), icon: NoorIcon.calendar(size:16), hasError: hasError),
      ]),
    );
  }
}

class _ProgBar extends StatelessWidget {
  final String label;
  final int? pts;
  final int goal;
  final Widget icon;
  final Color color;
  final bool hasError;
  const _ProgBar({
    required this.label, required this.pts,
    required this.goal,  required this.color, required this.icon,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final cur = pts ?? 0;
    final pct = (cur / goal).clamp(0.0, 1.0);
    final done = cur >= goal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        icon,
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.outfit(
            fontSize: 13, fontWeight: FontWeight.w700, color: _C.text)),
        const Spacer(),
        if (hasError || pts == null)
          Text('--- / $goal', style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w700, color: _C.text))
        else if (done)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Text('Goal', style: GoogleFonts.outfit(
                fontSize: 10, fontWeight: FontWeight.w800, color: color)),
          )
        else
          RichText(text: TextSpan(children: [
            TextSpan(text: '$pts ',
                style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w800, color: _C.text)),
            TextSpan(text: '/ $goal pts',
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



// ─────────────────────────────────────────────────────────────────────────────
// Activity Card — bold solid card with unique per-type decoration
// ─────────────────────────────────────────────────────────────────────────────

enum _CardPattern { arcRings, floatingDots, speedLines, diamondSparks }

class _ActivityCard extends StatefulWidget {
  final String title, reward;
  final Widget icon;
  final Color solid, solidDeep;
  final _CardPattern patternType;
  final VoidCallback onTap;
  const _ActivityCard(this.title, this.icon, {
    required this.solid,
    required this.solidDeep,
    required this.reward,
    required this.patternType,
    required this.onTap,
  });
  @override State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    CustomPainter painter;
    switch (widget.patternType) {
      case _CardPattern.arcRings:      painter = const _ArcRingsPainter();     break;
      case _CardPattern.floatingDots:  painter = const _FloatingDotsPainter(); break;
      case _CardPattern.speedLines:    painter = const _SpeedLinesPainter();   break;
      case _CardPattern.diamondSparks: painter = const _DiamondSparksPainter();break;
    }
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.solidDeep.withValues(alpha: 0.40),
                blurRadius: 16, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(children: [
              // ── Radial gradient base ────────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [widget.solid, widget.solidDeep],
                      center: const Alignment(-0.3, -0.5),
                      radius: 1.5,
                    ),
                  ),
                ),
              ),
              // ── Unique decorative pattern ─────────────────────────────
              Positioned.fill(child: CustomPaint(painter: painter)),
              // ── Content ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Emoji bubble
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.30)),
                      ),
                      child: Center(child: widget.icon),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.title,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rajdhani(
                            fontSize: 17, fontWeight: FontWeight.w800,
                            color: Colors.white, letterSpacing: 0.3,
                            shadows: [Shadow(
                              color: Colors.black.withValues(alpha: 0.20),
                              blurRadius: 4,
                            )])),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(widget.reward,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                                fontSize: 11, fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ]),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─ Arc Rings — concentric quarter-circles emanating from top-right corner
class _ArcRingsPainter extends CustomPainter {
  const _ArcRingsPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    for (int i = 1; i <= 5; i++) {
      final r = s.width * 0.22 * i;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(s.width, 0), radius: r),
        math.pi * 0.5, math.pi * 0.5, false, paint,
      );
    }
  }
  @override bool shouldRepaint(_ArcRingsPainter _) => false;
}

// ─ Floating Dots — scattered circles, largest bottom-right
class _FloatingDotsPainter extends CustomPainter {
  const _FloatingDotsPainter();
  static const _positions = [
    [0.80, 0.12, 22.0], [0.60, 0.28, 8.0], [0.92, 0.55, 14.0],
    [0.15, 0.72, 10.0], [0.70, 0.80, 30.0], [0.35, 0.18, 6.0],
    [0.05, 0.42, 18.0],
  ];
  @override
  void paint(Canvas canvas, Size s) {
    for (final p in _positions) {
      canvas.drawCircle(
        Offset(s.width * p[0], s.height * p[1]),
        p[2],
        Paint()
          ..color = Colors.white.withValues(alpha: 0.13)
          ..style = PaintingStyle.fill,
      );
      // Ring outline
      canvas.drawCircle(
        Offset(s.width * p[0], s.height * p[1]),
        p[2] + 4,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }
  @override bool shouldRepaint(_FloatingDotsPainter _) => false;
}

// ─ Speed Lines — diagonal parallel lines top-left to bottom-right
class _SpeedLinesPainter extends CustomPainter {
  const _SpeedLinesPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.11)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const gap = 22.0;
    final diag = s.width + s.height;
    for (double offset = -diag; offset < diag; offset += gap) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + diag, diag),
        paint,
      );
    }
    // Bold accent line
    final boldPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 3.5;
    canvas.drawLine(Offset(s.width * 0.1, 0), Offset(s.width, s.height * 0.82), boldPaint);
  }
  @override bool shouldRepaint(_SpeedLinesPainter _) => false;
}

// ─ Diamond Sparks — rotated small square gems scattered across card
class _DiamondSparksPainter extends CustomPainter {
  const _DiamondSparksPainter();
  static const _gems = [
    [0.75, 0.10, 12.0, 0.18], [0.85, 0.45, 7.0,  0.12],
    [0.60, 0.72, 10.0, 0.14], [0.15, 0.15, 8.0,  0.10],
    [0.30, 0.80, 14.0, 0.16], [0.90, 0.25, 5.0,  0.09],
    [0.50, 0.35, 6.0,  0.08],
  ];
  @override
  void paint(Canvas canvas, Size s) {
    for (final g in _gems) {
      final cx = s.width  * g[0];
      final cy = s.height * g[1];
      final r  = g[2];
      final a  = g[3];
      final path = Path()
        ..moveTo(cx,     cy - r)
        ..lineTo(cx + r, cy)
        ..lineTo(cx,     cy + r)
        ..lineTo(cx - r, cy)
        ..close();
      canvas.drawPath(path, Paint()
        ..color = Colors.white.withValues(alpha: a)
        ..style = PaintingStyle.fill);
      canvas.drawPath(path, Paint()
        ..color = Colors.white.withValues(alpha: a * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0);
    }
  }
  @override bool shouldRepaint(_DiamondSparksPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Background — very subtle Islamic-inspired lattice at low opacity
// ─────────────────────────────────────────────────────────────────────────────
class _HomeBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = const Color(0xFF2BAE99).withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    final arcPaint = Paint()
      ..color = const Color(0xFF2BAE99).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Dot grid — every 38px, off-center
    const spacing = 38.0;
    const dotR    = 2.2;
    for (double x = spacing * 0.5; x < size.width; x += spacing) {
      for (double y = spacing * 0.5; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotR, dotPaint);
      }
    }

    // Soft wide arcs from top-right — Islamic crescent feel
    for (int i = 1; i <= 4; i++) {
      final r = size.width * 0.45 * i;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width, 0), radius: r),
        math.pi * 0.45, math.pi * 0.65,
        false, arcPaint,
      );
    }

    // Faint large circle bottom-left
    canvas.drawCircle(
      Offset(0, size.height),
      size.width * 0.55,
      Paint()
        ..color = const Color(0xFF2BAE99).withValues(alpha: 0.03)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_HomeBgPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Project cover thumbnail — loads first media item for the project from Supabase.
class _ProjectCover extends StatefulWidget {
  final String projectId;
  final double size;
  const _ProjectCover({required this.projectId, this.size = 28});

  @override
  State<_ProjectCover> createState() => _ProjectCoverState();
}

class _ProjectCoverState extends State<_ProjectCover> {
  static final Map<String, ProjectMedia?> _cache = {};
  /// Call this to invalidate all cached covers (e.g. after admin upload).
  static void clearCache() => _cache.clear();

  ProjectMedia? _cover;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (_cache.containsKey(widget.projectId)) {
      _cover = _cache[widget.projectId];
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final list =
        await DonationService.instance.getProjectMedia(widget.projectId);
    final cover = list.isNotEmpty ? list.first : null;
    _cache[widget.projectId] = cover;
    if (!mounted) return;
    setState(() {
      _cover = cover;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final radius = BorderRadius.circular(widget.size * 0.25);
    if (_loading) {
      return Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F4EF),
          borderRadius: radius,
        ),
        child: Center(
          child: SizedBox(
            width: widget.size * 0.6,
            height: widget.size * 0.6,
            child: const CircularProgressIndicator(
                strokeWidth: 1.5, color: _C.teal),
          ),
        ),
      );
    }
    if (_cover == null) {
      return Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F4EF),
          borderRadius: radius,
        ),
        child: Icon(Icons.volunteer_activism_rounded,
            size: widget.size * 0.6, color: _C.teal),
      );
    }
    if (_cover!.isVideo) {
      return Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: radius,
        ),
        child: Icon(Icons.play_arrow_rounded,
            color: Colors.white, size: widget.size * 1.1),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        _cover!.url,
        width: s,
        height: s,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => NoorIcon.image(size: widget.size),
      ),
    );
  }
}

// Convenience helper that picks the right widget for a project map.
Widget _buildProjIcon(Map<String, dynamic> project, double size) {
  final dpUrl = project['dp_url'] as String?;
  if (dpUrl != null && dpUrl.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: Image.network(dpUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              _ProjectCover(projectId: project['id'] as String, size: size)),
    );
  }
  return _ProjectCover(projectId: project['id'] as String, size: size);
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
          height: 480,
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

                  final dpUrl = d['dp_url'] as String?;
                  Widget banner;
                  if (dpUrl != null && dpUrl.isNotEmpty) {
                    banner = SizedBox(
                      width: double.infinity,
                      height: 240,
                      child: Image.network(
                        dpUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF7F4EF),
                          child: const Center(child: Icon(Icons.volunteer_activism_rounded, size: 48, color: Color(0xFF2BAE99))),
                        ),
                      ),
                    );
                  } else {
                    banner = Container(
                      width: double.infinity, height: 240,
                      color: const Color(0xFFF7F4EF),
                      child: const Icon(Icons.volunteer_activism_rounded, size: 48, color: Color(0xFF2BAE99)),
                    );
                  }

                  String fmt(int n) => n >= 1000000 ? '${(n/1000000).toStringAsFixed(1)}M' : (n >= 1000 ? '${(n/1000).toStringAsFixed(1)}k' : '$n');

                  return Container(
                    width: donations.length == 1 ? constraints.maxWidth : 300,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12, offset: const Offset(0, 4))],
                      border: Border.all(color: Colors.grey.shade100, width: 1.5),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      // Wide Banner
                      banner,
                      
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Center(
                                child: Text((d['title'] ?? '').toString().toUpperCase(),
                                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _C.text, letterSpacing: -0.2),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              // Description snippet
                              if ((d['description'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  (d['description'] ?? '').toString(),
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A), height: 1.35),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
                                    Flexible(child: Text('Your Contribution', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500))),
                                    const SizedBox(width: 4),
                                    Text(fmt(myPts), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: _C.text)),
                                  ]
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Flexible(child: Text("Others'", maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500))),
                                    const SizedBox(width: 4),
                                    Text(fmt((current - myPts).clamp(0, current)), style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: _C.text)),
                                  ]
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Flexible(child: Text('Needed', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500))),
                                    const SizedBox(width: 4),
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
                              child: Text('See Details →',
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ),
                            ],
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
// NOOR COUNTER — Tasbih drum-wheel style with slot-machine roll animation
// Each digit rapidly spins through 0→9 before landing on the final value.
// ─────────────────────────────────────────────────────────────────────────────
class _NoorCounter extends StatefulWidget {
  final int value;
  /// Increments each time the user navigates to the Home tab.
  /// A change here re-fires the slot-machine animation regardless of value.
  final int visitCount;
  const _NoorCounter({required this.value, this.visitCount = 0});
  @override
  State<_NoorCounter> createState() => _NoorCounterState();
}

class _NoorCounterState extends State<_NoorCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    // Small delay so the screen finishes building first
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void didUpdateWidget(_NoorCounter old) {
    super.didUpdateWidget(old);
    // Re-animate if value OR visit-count changes (triggers every home tab switch)
    if (old.value != widget.value || old.visitCount != widget.visitCount) {
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Insert commas into an already-padded digit string (preserves leading zeros)
  String _withCommasStr(String s) {
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    // fmtFull drives the structural layout (stable widths/commas)
    final targetStr = widget.value.toString();
    final fmtFull   = _withCommasStr(targetStr);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF2BAE99).withValues(alpha: 0.25), width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2BAE99).withValues(alpha: 0.12),
                  blurRadius: 16, offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6, offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Drum display ──────────────────────────────────────────
                  SizedBox(
                    height: 114,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFF5FAF9)],
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
                            for (int i = 0; i < fmtFull.length; i++)
                              if (fmtFull[i] == ',')
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(',',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 20, fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2BAE99).withValues(alpha: 0.55),
                                    ),
                                  ),
                                )
                              else
                                _DrumDigit(
                                  targetDigit: int.parse(fmtFull[i]),
                                  progress: _anim.value,
                                  slotIndex: i,
                                  totalSlots: fmtFull.length,
                                ),
                            const SizedBox(width: 10),
                            const _NoorBead(),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Thin teal divider ───────────────────────────────────
                  Container(
                    height: 0.8,
                    color: const Color(0xFF2BAE99).withValues(alpha: 0.3),
                  ),

                  // ── Label strip ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A9E8C), Color(0xFF2BAE99)],
                        begin: Alignment.centerLeft, end: Alignment.centerRight,
                      ),
                    ),
                    child: Center(
                      child: Text('YOUR TOTAL NOOR POINTS',
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
      },
    );
  }
}

/// Slot-machine drum digit — scrolls a column of 0-9 rapidly before landing.
/// Each slot spins [_kExtraSpins] full rotations plus the target digit offset,
/// giving the authentic odometer / tasbih-counter roll feel.
class _DrumDigit extends StatelessWidget {
  /// The actual digit to land on (0-9).
  final int targetDigit;
  /// Overall counter progress 0.0 → 1.0.
  final double progress;
  /// Slot position (0 = leftmost).
  final int slotIndex;
  final int totalSlots;

  // How many extra full rotations each slot does before landing.
  // Rightmost digit spins most (cascading slot-machine feel).
  static const double _kExtraSpinsBase  = 3.0;  // minimum extra full rotations
  static const double _kExtraSpinsStep  = 0.8;  // additional spins per slot from right
  static const double _digitHeight      = 62.0;
  static const double _slotH            = 62.0;

  const _DrumDigit({
    required this.targetDigit,
    this.progress = 1.0,
    this.slotIndex = 0,
    this.totalSlots = 1,
  });

  @override
  Widget build(BuildContext context) {
    // Rightmost digit: more spins; leftmost: fewer.
    final posFromRight = totalSlots - 1 - slotIndex;
    final extraSpins   = _kExtraSpinsBase + posFromRight * _kExtraSpinsStep;

    // Stagger: rightmost starts immediately, leftmost starts a little later.
    // This way the first digit that settles is the rightmost one.
    final staggerDelay = slotIndex * 0.04;   // leftmost slots start slightly later
    final localProg    = ((progress - staggerDelay) / (1.0 - staggerDelay)).clamp(0.0, 1.0);

    // Apply easeOut so the spin decelerates nicely.
    final easedProg = Curves.easeOut.transform(localProg);

    // Total scroll distance in digits:
    //   We scroll from 0 downward (digit 0 at top → digit 9 at bottom = 1 rotation).
    //   extraSpins full rotations + arrive exactly at targetDigit.
    final totalDigitScroll = extraSpins * 10 + targetDigit;
    // Current scroll in pixels (upward scroll = translate negative Y).
    final scrolledDigits   = easedProg * totalDigitScroll;
    // Which digit row we are currently at (fractional).
    final fractionalRow    = scrolledDigits % 10;
    // Translate the 10-digit column upward by fractionalRow * digitHeight.
    final translateY       = -fractionalRow * _digitHeight;

    return ClipRect(
      child: SizedBox(
        width: 48,
        height: _slotH,
        child: Stack(children: [
          // ── Dig column: renders 0-9 twice for seamless wrap ──────────
          Transform.translate(
            offset: Offset(0, translateY),
            child: OverflowBox(
              maxHeight: double.infinity,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 48,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int d = 0; d <= 9; d++)
                      _DigitCell(digit: d, height: _digitHeight),
                    // Duplicate first row so the column wraps seamlessly
                    _DigitCell(digit: 0, height: _digitHeight),
                  ],
                ),
              ),
            ),
          ),

          // ── Top fade mask ───────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0, height: 14,
            child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFF5FAF9), const Color(0xFFF5FAF9).withValues(alpha: 0)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            )),
          ),

          // ── Bottom fade mask ────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0, height: 14,
            child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFF5FAF9).withValues(alpha: 0), const Color(0xFFF5FAF9)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            )),
          ),

          // ── Centre fold line ───────────────────────────────────────
          Center(child: Container(
            height: 0.8,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            color: const Color(0xFF2BAE99).withValues(alpha: 0.35),
          )),
        ]),
      ),
    );
  }
}

/// Single digit cell inside the rolling column.
class _DigitCell extends StatelessWidget {
  final int digit;
  final double height;
  const _DigitCell({required this.digit, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: height,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4F0E8), Color(0xFFEBF9F4), Color(0xFFD4F0E8)],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF2BAE99).withValues(alpha: 0.4), width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2BAE99).withValues(alpha: 0.12),
            blurRadius: 6, offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 3, offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$digit',
          style: GoogleFonts.rajdhani(
            fontSize: 36, fontWeight: FontWeight.w800,
            color: const Color(0xFF0E5040), height: 1,
            shadows: [
              Shadow(
                color: const Color(0xFF2BAE99).withValues(alpha: 0.35),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
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
  Map<String, List<ProjectMedia>> _projectMedia = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await Supabase.instance.client.from('community_projects')
          .select().order('sort_order', ascending: true, nullsFirst: false);
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

      final projectIds = _projects.map((p) => p['id'] as String).toList();
      _projectMedia = await DonationService.instance.getMediaForProjects(projectIds);
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
              Builder(
                builder: (context) {
                  final mediaList = _projectMedia[p['id']] ?? [];
                  final dpUrl = p['dp_url'] as String?;
                  if (mediaList.isNotEmpty) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ProjectMediaCarousel(media: mediaList, height: 180),
                    );
                  }
                  if (dpUrl != null && dpUrl.isNotEmpty) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 180, width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(dpUrl, fit: BoxFit.cover),
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                              child: Container(color: Colors.black.withValues(alpha: 0.2)),
                            ),
                            Image.network(dpUrl, fit: BoxFit.contain),
                          ],
                        ),
                      ),
                    );
                  }
                  return Container(
                    height: 130, width: double.infinity,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF89CFF0), Color(0xFF4ECDC4)]),
                        borderRadius: BorderRadius.circular(16)),
                    child: Center(child: NoorIcon.drop(size: 64)),
                  );
                }
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
                      NoorIcon.coin(size: 14),
                      const SizedBox(width: 4),
                      Text('See Details', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: availablePoints > 0 ? Colors.white : Colors.grey.shade600)),
                    ]),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        if (completed.isNotEmpty) ...[
          Text('Completed Projects',
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
                Container(width: 66, height: 66, decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(50)),
                    child: Center(child: _buildProjIcon(p, 56))),
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
                parentState._noorPoints = ((parentState._noorPoints ?? 0) - amount).clamp(0, 99999999);
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
  List<ProjectMedia> _media = [];
  bool _mediaLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.availablePoints < 50) _selectedAmount = widget.availablePoints;
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    final id = widget.project['id'] as String?;
    if (id == null) {
      setState(() => _mediaLoading = false);
      return;
    }
    final list = await DonationService.instance.getProjectMedia(id);
    if (!mounted) return;
    setState(() {
      _media = list;
      _mediaLoading = false;
    });
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _C.communityBg, shape: BoxShape.circle),
                    child: _buildProjIcon(widget.project, 54),
                  ),
                  const SizedBox(width: 12),
                  Text('Support this Cause', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: _C.text)),
                ]
              ),
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
                    NoorIcon.coin(size: 18),
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
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('$_selectedAmount',
                          style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w800,
                              color: _C.navImpact, height: 1.0)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('points', style: GoogleFonts.outfit(fontSize: 16,
                        fontWeight: FontWeight.w600, color: _C.sub)),
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

              // ── Optional Media Carousel ──
              if (_mediaLoading)
                Container(
                  height: 180,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F4), borderRadius: BorderRadius.circular(20)),
                  child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: _C.teal))),
                )
              else if (_media.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ProjectMediaCarousel(media: _media, height: 180),
                  ),
                ),

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
                    : Text('Donate & Earn Reward', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
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
// RANKING SHEET — modal bottom sheet leaderboard (demoted from nav tab)
// ─────────────────────────────────────────────────────────────────────────────
class _RankingSheet extends StatefulWidget {
  final String currentUserId;
  const _RankingSheet({required this.currentUserId});
  @override State<_RankingSheet> createState() => _RankingSheetState();
}
class _RankingSheetState extends State<_RankingSheet> {
  List<Map<String, dynamic>> _leaders = [];
  int _myRank = 0;
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
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
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Column(children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1A1040), Color(0xFF2D1B69)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: NoorIcon.trophy(size: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Leaderboard',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: _C.text)),
                  Text('Top contributors by lifetime pts',
                      style: GoogleFonts.outfit(fontSize: 12, color: _C.sub)),
                ])),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF8E8E93)),
                ),
              ]),
            ]),
          ),

          Divider(height: 1, color: Colors.grey.shade100),

          Expanded(child: _loading
            ? const NoorInlineLoader(height: double.infinity, color: _C.navRanking, label: 'Loading…')
            : ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  // My rank hero card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A1040), Color(0xFF2D1B69)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(
                            color: const Color(0xFF2D1B69).withValues(alpha: 0.35),
                            blurRadius: 16, offset: const Offset(0, 6))]),
                    child: Row(children: [
                      NoorIcon.medal(size: 40),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Your Rank: #$_myRank',
                            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text('Out of ${_leaders.length} believers',
                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60)),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  Text('Top 10 Contributors',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: _C.text)),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFF0F0F5)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)]),
                    child: Column(children: List.generate(_leaders.take(10).length, (i) {
                      final p = _leaders[i];
                      final isMe = p['id'] == widget.currentUserId;
                      final badgeColors = [
                        [const Color(0xFFFFD700), const Color(0xFFFFA500)],
                        [const Color(0xFFB0BEC5), const Color(0xFF78909C)],
                        [const Color(0xFFCD7F32), const Color(0xFFA0522D)],
                      ];
                      final isTop3 = i < 3;
                      final badgeGrad = isTop3 ? badgeColors[i] : [const Color(0xFF2BAE99), const Color(0xFF1A9E8C)];
                      final xp    = (p['total_xp']     as num?)?.toInt() ?? 0;
                      final lv    = (p['level']        as num?)?.toInt() ?? 1;
                      final title = (p['level_title']  as String?) ?? 'Seeker';
                      final nm    = (p['display_name'] as String?)?.split(' ').first ?? 'User';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFFFF3D4) : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                          border: i < _leaders.take(10).length - 1
                              ? const Border(bottom: BorderSide(color: Color(0xFFF5F5F5))) : null,
                        ),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: badgeGrad,
                                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                              boxShadow: [BoxShadow(
                                  color: badgeGrad.last.withValues(alpha: 0.35),
                                  blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: Center(child: i < 3
                              ? (i == 0 ? NoorIcon.goldMedal(size: 20)
                                : i == 1 ? NoorIcon.silverMedal(size: 20)
                                : NoorIcon.bronzeMedal(size: 20))
                              : Text('${i + 1}',
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(isMe ? '$nm (you)' : nm,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: _C.text)),
                            Text('$title • Lv $lv',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontSize: 11, color: _C.sub)),
                          ])),
                          Text('$xp pts',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: _C.navRanking)),
                        ]),
                      );
                    })),
                  ),
                ],
              ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE TAB
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTab extends StatefulWidget {
  final String name, levelTitle, currentUserId;
  final int noorPoints, totalXp, level, streak;
  final String? country;
  final String? avatarUrl;
  final VoidCallback onSignOut;
  final VoidCallback onRefresh;
  const _ProfileTab({required this.name, required this.noorPoints,
      required this.totalXp, required this.level, required this.levelTitle,
      required this.country, required this.streak, required this.currentUserId,
      this.avatarUrl,
      required this.onSignOut,
      required this.onRefresh});
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  List<Map<String, dynamic>> _leaders = [];
  int  _myRank    = 0;
  bool _lbLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
    );
    // Reload leaderboard in case anything changed
    _loadLeaderboard();
    widget.onRefresh();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final res = await Supabase.instance.client
          .from('leaderboard_global')
          .select()
          .limit(100);
      _leaders = List<Map<String, dynamic>>.from(res);
      _myRank  = _leaders.indexWhere((p) => p['id'] == widget.currentUserId) + 1;
      if (_myRank == 0) _myRank = _leaders.length + 1;
    } catch (_) {}
    if (mounted) setState(() => _lbLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user    = Supabase.instance.client.auth.currentUser;
    final first   = widget.name.split(' ').first;
    final name    = widget.name;
    final country = widget.country;
    final level   = widget.level;
    final levelTitle = widget.levelTitle;
    final streak  = widget.streak;
    final avatarUrl  = widget.avatarUrl;
    final statusBarH = MediaQuery.of(context).padding.top;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
      child: Column(children: [

        // ── Profile header — Akhirah-style deep green + arcs ──────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A2318), Color(0xFF133828), Color(0xFF1A4731)],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Decorative arc circles — same as Akhirah
              Positioned(top: -40, right: -40,
                  child: _ProfileArc(180, Colors.white.withValues(alpha: 0.04))),
              Positioned(bottom: -20, left: -30,
                  child: _ProfileArc(130, Colors.white.withValues(alpha: 0.03))),
              Positioned(top: 40, right: 40,
                  child: _ProfileArc(70, const Color(0xFFD4AF37).withValues(alpha: 0.08))),
              Positioned(top: -10, left: 60,
                  child: _ProfileArc(50, const Color(0xFF2BAE99).withValues(alpha: 0.06))),

              // Content — padded below status bar
              Padding(
                padding: EdgeInsets.fromLTRB(22, statusBarH + 18, 22, 36),
                child: Column(children: [
                  // Top row: "My Profile" title + level pill (mirrors Akhirah top bar)
                  Row(children: [
                    Text('My Profile',
                        style: GoogleFonts.outfit(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const Spacer(),
                    // Level pill — Flexible so long titles don't overflow
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.workspace_premium_rounded,
                              color: Color(0xFFD4AF37), size: 14),
                          const SizedBox(width: 5),
                          Flexible(child: Text('Lvl $level · $levelTitle',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: const Color(0xFFD4AF37)))),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Settings button
                    GestureDetector(
                      onTap: () => _openSettings(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.settings_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // Avatar
                  Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDD88FF), Color(0xFF9B59B6)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9B59B6).withValues(alpha: 0.5),
                            blurRadius: 28, offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.06),
                            blurRadius: 0, spreadRadius: 4,
                          ),
                        ],
                        image: avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: avatarUrl == null
                          ? Center(child: Text(
                              first.isNotEmpty ? first[0].toUpperCase() : 'N',
                              style: GoogleFonts.outfit(
                                  fontSize: 44, fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ))
                          : null,
                    ),
                  ]),

                  const SizedBox(height: 18),

                  // Name
                  Text(name,
                      style: GoogleFonts.rajdhani(
                          fontSize: 28, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: 0.5)),
                  const SizedBox(height: 4),

                  // Email / Country
                  if (user?.email != null)
                    Text(user!.email ?? '',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5))),
                  if (country != null && country.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.public_rounded,
                          size: 12, color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(country,
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.55))),
                    ]),
                  ],
                ]),
              ),
            ],
          ),
        ),

          // ── Body — warm beige background matching the rest of the app ──────
          Container(
            color: _C.bg,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(children: [

                // ── Community Leaderboard — inline card ─────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _C.border),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12, offset: const Offset(0, 4),
                    )],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Header row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A1040), Color(0xFF2D1B69)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: NoorIcon.trophy(size: 20)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Community Leaderboard',
                              style: GoogleFonts.outfit(
                                  fontSize: 15, fontWeight: FontWeight.w800,
                                  color: _C.text)),
                          Text('Top contributors by lifetime pts',
                              style: GoogleFonts.outfit(fontSize: 11, color: _C.sub)),
                        ])),
                      ]),
                    ),

                    // My rank hero
                    if (!_lbLoading)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A1040), Color(0xFF2D1B69)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFF2D1B69).withValues(alpha: 0.35),
                              blurRadius: 14, offset: const Offset(0, 5),
                            )],
                          ),
                          child: Row(children: [
                            NoorIcon.medal(size: 36),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Your Rank: #$_myRank',
                                  style: GoogleFonts.outfit(
                                      fontSize: 18, fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                              Text('Out of ${_leaders.length} believers',
                                  style: GoogleFonts.outfit(
                                      fontSize: 11, color: Colors.white60)),
                            ])),
                          ]),
                        ),
                      ),

                    // Loading indicator
                    if (_lbLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(
                            color: Color(0xFF2BAE99), strokeWidth: 2.5)),
                      ),

                    // Top 10 list
                    if (!_lbLoading && _leaders.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: Text('Top 10 Contributors',
                            style: GoogleFonts.outfit(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: _C.sub, letterSpacing: 0.5)),
                      ),
                      ...List.generate(_leaders.take(10).length, (i) {
                        final p      = _leaders[i];
                        final isMe   = p['id'] == widget.currentUserId;
                        final isTop3 = i < 3;
                        final badgeColors = [
                          [const Color(0xFFFFD700), const Color(0xFFFFA500)],
                          [const Color(0xFFB0BEC5), const Color(0xFF78909C)],
                          [const Color(0xFFCD7F32), const Color(0xFFA0522D)],
                        ];
                        final badgeGrad = isTop3
                            ? badgeColors[i]
                            : [const Color(0xFF2BAE99), const Color(0xFF1A9E8C)];
                        final xp    = (p['total_xp']     as num?)?.toInt() ?? 0;
                        final lv    = (p['level']        as num?)?.toInt() ?? 1;
                        final title = (p['level_title']  as String?) ?? 'Seeker';
                        final nm    = (p['display_name'] as String?)?.split(' ').first ?? 'User';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFFFFF3D4)
                                : Colors.transparent,
                            borderRadius: i == _leaders.take(10).length - 1
                                ? const BorderRadius.vertical(bottom: Radius.circular(22))
                                : BorderRadius.zero,
                            border: i < _leaders.take(10).length - 1
                                ? const Border(bottom: BorderSide(color: Color(0xFFF5F5F5)))
                                : null,
                          ),
                          child: Row(children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                    colors: badgeGrad,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                boxShadow: [BoxShadow(
                                    color: badgeGrad.last.withValues(alpha: 0.35),
                                    blurRadius: 8, offset: const Offset(0, 3))],
                              ),
                              child: Center(child: i < 3
                                ? (i == 0 ? NoorIcon.goldMedal(size: 18)
                                  : i == 1 ? NoorIcon.silverMedal(size: 18)
                                  : NoorIcon.bronzeMedal(size: 18))
                                : Text('${i + 1}',
                                    style: GoogleFonts.outfit(
                                        fontSize: 13, fontWeight: FontWeight.w800,
                                        color: Colors.white))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(isMe ? '$nm (you)' : nm,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                      fontSize: 14, fontWeight: FontWeight.w700,
                                      color: _C.text)),
                              Text('$title • Lv $lv',
                                  style: GoogleFonts.outfit(fontSize: 11, color: _C.sub)),
                            ])),
                            Text('$xp pts',
                                style: GoogleFonts.outfit(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: _C.navRanking)),
                          ]),
                        );
                      }),
                    ],
                    const SizedBox(height: 8),
                  ]),
                ),
                const SizedBox(height: 14),

                // Streak card — warm beige with amber/teal accents
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LevelScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _C.border),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10, offset: const Offset(0, 3),
                      )],
                    ),
                    child: Row(children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: _C.amber.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.amber.withValues(alpha: 0.3)),
                        ),
                        child: Center(child: NoorIcon.fire(size: 26)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          streak > 0 ? '$streak Day Streak 🔥' : 'Start your streak today!',
                          style: GoogleFonts.rajdhani(
                            fontSize: 20, fontWeight: FontWeight.w800,
                            color: streak > 0 ? _C.amber : _C.sub,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text('Tap to view your Journey',
                            style: GoogleFonts.outfit(fontSize: 12, color: _C.sub)),
                      ])),
                      Icon(Icons.arrow_forward_ios_rounded, size: 15,
                          color: streak > 0 ? _C.amber : _C.sub),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                // Email row — standard white card matching app style
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _C.border),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                    )],
                  ),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _C.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.email_outlined, color: _C.teal, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(user?.email ?? '',
                        style: GoogleFonts.outfit(fontSize: 14, color: _C.text),
                        overflow: TextOverflow.ellipsis)),
                  ]),
                ),
                const SizedBox(height: 14),

                // Admin Panel button (admins only)
                if (_kAdminEmails.contains(user?.email)) ...[
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AdminDashboard()));
                      if (!context.mounted) return;
                      // Refresh dashboard tabs on return to update sequences/projects
                      _ProjectCoverState.clearCache();
                      final dashboard = context.findAncestorStateOfType<_DashboardScreenState>();
                      if (dashboard != null) {
                        dashboard._adminRefreshCount++;
                        dashboard._loadHomeData();
                      }
                    },
                    child: Container(
                      width: double.infinity, height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _C.darkBtn,
                        boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12, offset: const Offset(0, 4),
                        )],
                      ),
                      child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.admin_panel_settings_rounded, color: _C.teal, size: 22),
                        const SizedBox(width: 10),
                        Text('Admin Panel', style: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      ])),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Sign Out
                GestureDetector(
                  onTap: widget.onSignOut,
                  child: Container(
                    width: double.infinity, height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFFFECEC)),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFFD32F2F).withValues(alpha: 0.06),
                        blurRadius: 12, offset: const Offset(0, 4),
                      )],
                    ),
                    child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F), size: 20),
                      const SizedBox(width: 10),
                      Text('Sign Out', style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: const Color(0xFFD32F2F))),
                    ])),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// Decorative circle arc — identical to Akhirah's _Arc widget but scoped here
class _ProfileArc extends StatelessWidget {
  final double size;
  final Color color;
  const _ProfileArc(this.size, this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
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
      (Icons.home_rounded,                Icons.home_outlined,                'Home',    _C.navHome),
      (Icons.trending_up_rounded,         Icons.trending_up_outlined,         'Journey', _C.navRanking),
      (Icons.mosque_rounded,              Icons.mosque_outlined,              'Akhirah', _C.navImpact),
      (Icons.person_rounded,              Icons.person_outline_rounded,       'Profile', _C.navProfile),
    ];
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 72 + bottomPad,
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: BoxDecoration(color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))]),
      child: Row(children: List.generate(items.length, (i) {
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
      })),
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

  // ── Colors — app-native teal/green palette ────────────────────────────
  // Matches the Akhira/Profile header and the app's signature teal accent.
  static const _neonGreen  = Color(0xFF2BAE99);   // app teal
  static const _neonGold   = Color(0xFFD4AF37);   // soft Islamic gold
  static const _socketRing = Color(0xFF1A9E8C);   // deeper teal ring

  static const _sparkPalette = [
    Color(0xFF2BAE99), Color(0xFF1A9E8C), Color(0xFF4ECDC4),
    Color(0xFFD4AF37), Color(0xFF80E5D8), Color(0xFFFFFFFF),
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A2318), Color(0xFF133828), Color(0xFF1A4731)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: const Color(0xFF2BAE99).withValues(alpha: 0.5), width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2BAE99).withValues(alpha: 0.22),
                          blurRadius: 24, offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12, offset: const Offset(0, 4),
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

                // ── Progress fill (teal→gold, grows with drag) ──────────
                Positioned(
                  left: 0, top: 0, bottom: 0,
                  child: Container(
                    width: (_thumbSize + _padding + _drag).clamp(0.0, box.maxWidth),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1A9E8C).withValues(alpha: 0.5),
                          const Color(0xFF2BAE99).withValues(alpha: 0.65),
                          Color.lerp(
                            const Color(0xFF2BAE99),
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

                // ── Centre label — glowing white on dark bg ────────────
                if (!_completed)
                  Center(
                    child: Opacity(
                      opacity: (1 - pct * 2.2).clamp(0.0, 1.0),
                      child: AnimatedBuilder(
                        animation: _shimmerCtrl,
                        builder: (_, __) => ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.7),
                              const Color(0xFFD4AF37),
                              Colors.white.withValues(alpha: 0.7),
                            ],
                            stops: [
                              0.0,
                              _shimmerCtrl.value,
                              1.0,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'Seal the Day  ✨',
                            style: GoogleFonts.rajdhani(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.5,
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
                          ? 'JazakAllah!  +${XpReward.validateCoins} pts'
                          : 'Already sealed today',
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
          NoorIcon.sparkles(size: 18),
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
                  ? (freshXp
                      ? NoorIcon.sun(size: 26)
                      : NoorIcon.check(size: 22))
                  : NoorIcon.moon(size: 22),
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

