import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'quran_hub_screen.dart';
import 'dhikr_hub_screen.dart';
import 'tafsir_hub_screen.dart';
import 'level_screen.dart';
import 'impact_report_screen.dart';
import 'profile_settings_screen.dart';
import '../features/auth/data/qf_auth_service.dart';

import '../services/xp_service.dart';
import '../services/tracking_service.dart';
import '../services/donation_service.dart';
import '../services/streak_service.dart';
import '../services/settings_service.dart';
import '../services/stats_service.dart';
import '../models/app_config.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import '../services/notification_center.dart';
import '../l10n/app_localizations.dart';
import 'streak_screen.dart';
import '../widgets/noor_icons.dart';
import '../widgets/plot_illustrations.dart';
import '../widgets/noor_offline.dart';
import '../widgets/motivational_popup.dart';
import '../widgets/project_media_carousel.dart';
import '../widgets/sabiq_coin.dart';
import '../widgets/seal_coin_animation.dart';
import '../config/feature_flags.dart';
import 'project_detail_screen.dart';
import 'orphan_detail_screen.dart';
import '../models/orphan.dart';
import '../services/profile_name_notifier.dart';
import '../services/live_notification_service.dart';
import '../theme/y4_theme.dart';
import '../widgets/notifications_sheet.dart';

/// Global key on the top-right profile/avatar tile. After sealing the day,
/// the celebration coin flies to this widget so the user sees the Seeds
/// arrive at their wallet (the profile icon doubles as the Seeds wallet).
final GlobalKey sabiqProfileIconKey = GlobalKey();

/// Global key on the Garden hero card's Sabiq Seed coin. After sealing the
/// day, the celebration coins fly here so the user sees the freshly-sealed
/// Seeds settle into their garden balance — which then counts up.
final GlobalKey gardenSeedKey = GlobalKey();

// ── Palette (reads from admin-controlled AppConfig) ─────────────────────────
AppConfig get _cfg => SettingsService.instance.config;

class _C {
  static Color get bg => _cfg.dashBg;
  static Color get text => _cfg.dashText;
  static Color get sub =>
      _cfg.dashBg.computeLuminance() > 0.5
          ? const Color(0xFF8E8E93)
          : const Color(0xFF9CA3AF);
  static Color get darkBtn =>
      _cfg.dashBg.computeLuminance() > 0.5
          ? const Color(0xFF1C1C1E)
          : const Color(0xFF374151);
  static Color get communityBg => _cfg.donationColor.withValues(alpha: 0.12);
  static Color get amber => _cfg.donationColor;
  static Color get navHome => _cfg.primaryColor;
  static Color get navImpact => _cfg.primaryColor;
  static Color get navRanking => _cfg.donationColor;
  static Color get navProfile => _cfg.secondaryColor;
  static Color get teal => _cfg.dashTeal;
  static Color get border =>
      _cfg.dashBg.computeLuminance() > 0.5
          ? const Color(0xFFE8E8EC)
          : const Color(0xFF374151);
}

// Y4 palette is now exported from `lib/theme/y4_theme.dart` as `Y4`.
// All `Y4.xxx` references below use that shared module.

String _localizeLevel(BuildContext context, String? dbLevel) {
  final l10n = AppLocalizations.of(context);
  if (dbLevel == 'Seeker') return l10n?.levelSeeker ?? 'Seeker';
  if (dbLevel == 'Believer') return l10n?.levelBeliever ?? 'Believer';
  if (dbLevel == 'Devoted') return l10n?.levelDevoted ?? 'Devoted';
  if (dbLevel == 'Champion') return l10n?.levelChampion ?? 'Champion';
  if (dbLevel == 'Legend') return l10n?.levelLegend ?? 'Legend';
  return dbLevel ?? 'Seeker';
}

String _localizeStreakType(BuildContext context, String label) {
  final l10n = AppLocalizations.of(context);
  if (label == 'Quran') return l10n?.quran ?? label;
  if (label == 'Zikr') return l10n?.zikr ?? label;
  if (label == 'Daily Login') return l10n?.dailyLogin ?? label;
  return label;
}

class DashboardScreen extends StatefulWidget {
  final String name;
  const DashboardScreen({super.key, required this.name});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
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
  int? _totalPts;
  int _level = 1;
  String _levelTitle = 'Seeker';
  StreakSnapshot _streakSnap = StreakSnapshot.empty;
  String? _country;
  String? _avatarUrl;

  // Community project
  Map<String, dynamic>? _project;

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
  Timer? _startupPopupTimer; // First popup after drum-counter animation
  Timer?
  _repeatingPopupTimer; // Next popup timer (re-armed after each dismissal)
  bool _popupVisible = false; // True while a popup sheet is on screen
  bool _sessionDnd = false; // True after first DND tap — resets on restart
  bool _isInFocusScreen =
      false; // True while user is reading Quran/Dhikr/Tafsir
  bool _counterAnimating = true; // Blocks popup while drum counter is rolling
  static const _kDndKey = 'motivational_popup_dnd'; // permanent flag
  static const _kDndCountKey = 'motivational_popup_dnd_count'; // tap counter

  // ── Home-tab visit tracking (drives counter re-animation) ────────────────
  int _homeVisitCount = 0; // increments each time user lands on Home

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    // Load pending points from yesterday (expires if not sealed)
    XpService.instance.loadPending();
    // Claim daily login pts once per day (fire & forget)
    XpService.instance.claimDailyLogin();
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
      final newCount = prevCount + 1;
      await prefs.setInt(_kDndCountKey, newCount);
      if (newCount >= 2) {
        // Second tap — permanent block
        await prefs.setBool(_kDndKey, true);
      }
      // First tap: timers cancelled for this session; next restart they re-fire
    } catch (_) {}
  }

  Future<void> _checkPendingReminder() async {
    final pending = XpService.instance.pendingPoints;
    if (pending <= 0) return;

    // ── System-level scheduled notification (fires even if app is closed) ──
    // Runs unconditionally whenever pending > 0; the service itself
    // de-dupes via SharedPreferences so we only schedule once per day.
    unawaited(
      NoorLiveNotificationService.instance.scheduleValidateReminder(pending),
    );

    // ── In-app banner (only after 8 PM, once a day) ──
    final hour = DateTime.now().hour;
    if (hour < 20) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastReminder = prefs.getString('pending_reminder_date') ?? '';
    if (lastReminder == today) return;

    await prefs.setString('pending_reminder_date', today);
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    NotificationCenter.instance.add(
      kind: NoorNotifKind.validation,
      title: l?.seedsExpiringNotificationTitle ??
          'Seeds expiring at midnight!',
      body: l?.seedsExpiringNotificationBody(pending) ??
          'You have $pending Seeds pending. Seal the Day now or they expire!',
      route: '/home',
    );
  }

  Future<void> _loadHomeData() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    // Record daily active user (once per session)
    StatsService.instance.recordDailyActive();
    // Evening reminder: if pending points exist and it's after 8 PM
    _checkPendingReminder();
    try {
      // ── Wave 1 ───────────────────────────────────────────────────────────
      // 7 independent fetches in parallel (was 6 sequential round-trips).
      // Each is wrapped so one failing won't cancel the rest.
      final w1 = await Future.wait<dynamic>([
        // 0: profile
        _supabase
            .from('profiles')
            .select('noor_points, country, total_xp, level, avatar_url')
            .eq('id', uid)
            .maybeSingle()
            .then<Map<String, dynamic>?>((v) => v)
            .catchError((_) => null),
        // 1: today points
        _supabase.rpc('get_today_points').catchError((e) {
          debugPrint('today err: $e');
          return 0;
        }),
        // 2: week points
        _supabase.rpc('get_week_points').catchError((e) {
          debugPrint('week err: $e');
          return 0;
        }),
        // 3: month points
        _supabase.rpc('get_month_points').catchError((e) {
          debugPrint('month err: $e');
          return 0;
        }),
        // 4: day streak
        _supabase.rpc('get_day_streak').catchError((e) {
          debugPrint('streak err: $e');
          return 0;
        }),
        // 5: streak snapshot (Hive + Supabase composite)
        StreakService.instance.loadSnapshot().catchError(
          (_) => StreakSnapshot.empty,
        ),
        // 6: featured community project
        _supabase
            .from('community_projects')
            .select()
            .eq('is_active', true)
            .eq('is_completed', false)
            .order('sort_order', ascending: true, nullsFirst: false)
            .limit(1)
            .maybeSingle()
            .then<Map<String, dynamic>?>((v) => v)
            .catchError((_) => null),
      ]);

      final profile = w1[0] as Map<String, dynamic>?;
      if (profile != null) {
        _noorPoints = (profile['noor_points'] as num?)?.toInt() ?? 0;
        _totalPts = (profile['total_xp'] as num?)?.toInt() ?? 0;
        _level = (profile['level'] as num?)?.toInt() ?? 1;
        _country = profile['country'] as String?;
        _avatarUrl = profile['avatar_url'] as String?;
      } else {
        _noorPoints = 0;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile returned zero rows for $uid')),
          );
        }
      }

      _todayPoints = (w1[1] as num?)?.toInt() ?? 0;
      _weekPoints = (w1[2] as num?)?.toInt() ?? 0;
      _monthPoints = (w1[3] as num?)?.toInt() ?? 0;
      _streak = (w1[4] as num?)?.toInt() ?? 0;
      _streakSnap = w1[5] as StreakSnapshot;
      _project = w1[6] as Map<String, dynamic>?;

      // ── Wave 2 ───────────────────────────────────────────────────────────
      // xp_levels needs _level from profile — tiny lookup, run after wave 1.
      try {
        final levels = await _supabase
            .from('xp_levels')
            .select('level, title')
            .eq('level', _level)
            .maybeSingle();
        if (_levelTitle == 'Seeker' ||
            _levelTitle == 'Champion' ||
            _levelTitle == 'Legend' ||
            _levelTitle == 'Believer' ||
            _levelTitle == 'Devoted') {
          _levelTitle =
              (levels?['title'] as String?) ?? _levelTitleFor(_level);
        }
      } catch (_) {}
    } catch (e) {
      _levelTitle = 'Root error: $e';
      _noorPoints ??= 0;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Dashboard Load Error: $e')));
      }
    }
    if (mounted) {
      setState(() {});
      _checkAndApplyPendingReferral();
    }
  }

  Future<void> _checkAndApplyPendingReferral() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingCode = prefs.getString('pending_referral_code');
      if (pendingCode != null && pendingCode.isNotEmpty) {
        await _supabase.rpc(
          'apply_referral',
          params: {'inviter_code': pendingCode},
        );
        await prefs.remove('pending_referral_code');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Referral code "$pendingCode" applied successfully! 500 Sabiq Seeds rewarded to you both! 🎉',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              backgroundColor: const Color(0xFF6D28D9),
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      final s = e.toString();
      if (s.contains('Already referred') || s.contains('Invalid referral code') || s.contains('Cannot refer yourself')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pending_referral_code');
      }
    }
  }

  // Fallback level title if DB not reachable
  String _levelTitleFor(int lv) {
    if (lv >= 51) return 'Legend';
    if (lv >= 21) return 'Champion';
    if (lv >= 11) return 'Devoted';
    if (lv >= 6) return 'Believer';
    return 'Seeker';
  }

  Future<void> _signOut() async {
    await QfAuthService.performSignOut(_supabase);
    // Pop all pushed routes (profile screen, settings, etc.) so AuthGate
    // surfaces and shows the login screen.
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _goToScreen(Widget screen) async {
    // Suppress popups while user is in a reading/focus screen
    _isInFocusScreen = true;
    final nav = _navKeys[_tab].currentState ?? Navigator.of(context);
    await nav.push<int>(MaterialPageRoute(builder: (_) => screen));
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
        body: IndexedStack(
            index: _tab,
            children: [
              _HomeTab(
                // Stable key — the tab must keep its State across a seal so
                // the post-seal popups (which run after an await and check
                // `mounted`) survive. A key tied to _noorPoints/_streak
                // recreated the whole tab the moment sealing credited the
                // garden, disposing the State mid-flow. The hero card still
                // animates its count-up via didUpdateWidget.
                key: const ValueKey('home_tab'),
                name: widget.name,
                noorPoints: _noorPoints,
                totalXp: _totalPts ?? 0,
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
                onGoQuran: () => _goToScreen(const QuranHubScreen()),
                onGoDhikr: () => _goToScreen(const DhikrHubScreen()),
                onGoTafsir: () => _goToScreen(const TafsirHubScreen()),
                onGoAchievements: () {
                  // Achievements live on the Journey tab — only jump there
                  // if that tab is enabled.
                  if (FeatureFlags.journeyTab) setState(() => _tab = 2);
                },
                onGoProfile: () {
                  final uid = _supabase.auth.currentUser?.id ?? '';
                  // Prefer the live name from settings (`noor_name` is
                  // written by profile_settings_screen on save) and only
                  // fall back to provider-supplied names if it's empty.
                  // Was previously reading `full_name` first, which is
                  // the OAuth provider's original name and so masked any
                  // user rename done in Settings.
                  final meta = _supabase.auth.currentUser?.userMetadata;
                  final displayName = (() {
                    final widgetName = widget.name.trim();
                    if (widgetName.isNotEmpty && widgetName != 'Friend') {
                      return widgetName;
                    }
                    final noorName = (meta?['noor_name'] as String?)?.trim();
                    if (noorName != null && noorName.isNotEmpty) return noorName;
                    final fullName = (meta?['full_name'] as String?)?.trim();
                    if (fullName != null && fullName.isNotEmpty) return fullName;
                    return _supabase.auth.currentUser?.email?.split('@').first ??
                        'User';
                  })();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => Scaffold(
                            body: _ProfileTab(
                              name: displayName,
                              noorPoints: _noorPoints ?? 0,
                              totalXp: _totalPts ?? 0,
                              level: _level,
                              levelTitle: _levelTitle,
                              country: _country,
                              streak: _streak ?? 0,
                              currentUserId: uid,
                              avatarUrl: _avatarUrl,
                              onRefresh: _loadHomeData,
                            ),
                          ),
                    ),
                  );
                },
                onGoInvite: () {
                  final uid = Supabase.instance.client.auth.currentUser?.id;
                  if (uid == null) return;
                  Supabase.instance.client
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
                          builder:
                              (ctx) => _InviteSheet(referralCode: code ?? ''),
                        );
                      });
                },
                onValidate: () async {
                  final awarded = await XpService.instance.claimValidate();
                  // Seal succeeded — cancel any scheduled "seal before
                  // midnight" reminder so the user doesn't get a stale
                  // push later in the day.
                  unawaited(
                    NoorLiveNotificationService.instance
                        .cancelValidateReminder(),
                  );
                  await _loadHomeData();
                  return awarded;
                },
                hasError: _noorPoints == null,
              ),
              // Tab 1 — Cause. Hidden tabs keep a placeholder so the fixed
              // 0-3 indices (used by _tab, _navKeys, the nav bar) never shift.
              FeatureFlags.causeTab
                  ? _buildTabNavigator(
                      1,
                      const CommunityImpactPage(isTab: true),
                    )
                  : const SizedBox.shrink(),
              // Tab 2 — Journey
              FeatureFlags.journeyTab
                  ? _buildTabNavigator(2, const LevelScreen())
                  : const SizedBox.shrink(),
              // Tab 3 — Akhirah
              FeatureFlags.akhirahTab
                  ? _buildTabNavigator(
                      3,
                      ImpactReportScreen(
                        key: const ValueKey('impact'),
                        isTab: true,
                        visitCount: _akhirahVisitCount,
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        bottomNavigationBar: _BottomNav(
            tab: _tab,
            onTap: (i) {
              // Flush any Quran/Dhikr screen time accumulated under the
              // current tab (the screen stays mounted inside its tab Navigator,
              // so exitScreen() won't fire). Fire-and-forget — the in-flight
              // Future is stored in StatsService for the destination tab
              // (e.g. Impact Report) to await before reading per-day stats.
              // Always bump chartRefresh on Akhirah-tab entry so the Impact
              // Report re-fetches even if nothing was flushed (the tab's
              // child widget is captured by its Navigator and won't receive
              // didUpdateWidget).
              if (i != _tab) {
                StatsService.instance.flushAndContinue();
                if (i == 3) {
                  StatsService.instance.bumpChartRefresh();
                }
              }
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
                if (i == 3 && _tab != 3) {
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
  final VoidCallback onGoQuran,
      onGoDhikr,
      onGoTafsir,
      onGoAchievements,
      onGoInvite;
  final VoidCallback? onGoProfile;
  final Future<bool> Function() onValidate;
  final bool hasError;
  const _HomeTab({
    super.key,
    required this.name,
    required this.noorPoints,
    required this.todayPoints,
    required this.weekPoints,
    required this.monthPoints,
    required this.streak,
    required this.totalXp,
    required this.level,
    required this.levelTitle,
    required this.project,
    required this.streakSnap,
    required this.homeVisitCount,
    this.avatarUrl,
    this.onGoProfile,
    required this.onGoQuran,
    required this.onGoDhikr,
    required this.onGoTafsir,
    required this.onValidate,
    required this.onGoAchievements,
    required this.onGoInvite,
    this.hasError = false,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<Map<String, dynamic>> _myDonations = [];
  late final ConfettiController _confettiController;

  // ── Tile sub-text "real data" (best-effort, with safe fallbacks) ───────────
  String? _lastSurahName; // e.g. "Al-Mulk"
  int? _lastAyah; // e.g. 7
  int _ayahsToday = 0; // for Quran tile sub
  int _dhikrToday = 0; // dhikr sets done today (best-effort)
  String? _recentBadgeName; // most recent earned badge

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _loadDonations();
    _loadTileExtras();
  }

  /// Best-effort fetch for activity-tile sub-text. Failures fall back silently.
  Future<void> _loadTileExtras() async {
    final sb = Supabase.instance.client;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return;

    // ── 3 independent reads in parallel (was 3 sequential round-trips). ──
    // One setState at the end instead of 3 separate rebuilds.
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day)
        .toIso8601String();

    final results = await Future.wait<dynamic>([
      // 0: last-read Quran progress
      sb
          .from('quran_progress')
          .select('current_surah, current_ayah, last_read_date, ayahs_read_today')
          .eq('user_id', uid)
          .maybeSingle()
          .then<Map<String, dynamic>?>((v) => v)
          .catchError((_) => null),
      // 1: most recently earned badge
      sb
          .from('user_badges')
          .select('badge_id, earned_at, badges(name)')
          .eq('user_id', uid)
          .order('earned_at', ascending: false)
          .limit(1)
          .maybeSingle()
          .then<Map<String, dynamic>?>((v) => v)
          .catchError((_) => null),
      // 2: today's dhikr session count
      sb
          .from('user_activities')
          .select('id')
          .eq('user_id', uid)
          .eq('activity_type', 'dhikr')
          .gte('created_at', startOfDay)
          .then<List<dynamic>>((v) => v as List)
          .catchError((_) => const <dynamic>[]),
    ]);

    if (!mounted) return;
    final prog = results[0] as Map<String, dynamic>?;
    final earned = results[1] as Map<String, dynamic>?;
    final dhikrRows = results[2] as List;

    final todayKey = today.toIso8601String().split('T')[0];
    String? newSurah;
    int? newAyah;
    int? newAyahsToday;
    if (prog != null) {
      final s = (prog['current_surah'] as num?)?.toInt() ?? 1;
      newSurah = _surahNameFor(s);
      newAyah = (prog['current_ayah'] as num?)?.toInt() ?? 1;
      final isToday = (prog['last_read_date'] ?? '') == todayKey;
      newAyahsToday =
          isToday ? ((prog['ayahs_read_today'] as num?)?.toInt() ?? 0) : 0;
    }
    String? newBadgeName;
    if (earned != null) {
      final badgeRow = earned['badges'];
      final name = (badgeRow is Map ? badgeRow['name'] : null) as String?;
      if (name != null && name.isNotEmpty) newBadgeName = name;
    }

    setState(() {
      if (newSurah != null) _lastSurahName = newSurah;
      if (newAyah != null) _lastAyah = newAyah;
      if (newAyahsToday != null) _ayahsToday = newAyahsToday;
      if (newBadgeName != null) _recentBadgeName = newBadgeName;
      _dhikrToday = dhikrRows.length;
    });
  }

  /// Minimal surah-name lookup for the home tile sub-text. Falls back to "Surah N".
  static String _surahNameFor(int n) {
    const names = [
      '',
      'Al-Fatihah',
      'Al-Baqarah',
      "Al 'Imran",
      'An-Nisa',
      'Al-Maidah',
      'Al-Anam',
      'Al-Araf',
      'Al-Anfal',
      'At-Tawbah',
      'Yunus',
      'Hud',
      'Yusuf',
      'Ar-Rad',
      'Ibrahim',
      'Al-Hijr',
      'An-Nahl',
      'Al-Isra',
      'Al-Kahf',
      'Maryam',
      'Ta-Ha',
      'Al-Anbiya',
      'Al-Hajj',
      'Al-Muminun',
      'An-Nur',
      'Al-Furqan',
      'Ash-Shuara',
      'An-Naml',
      'Al-Qasas',
      'Al-Ankabut',
      'Ar-Rum',
      'Luqman',
      'As-Sajdah',
      'Al-Ahzab',
      'Saba',
      'Fatir',
      'Ya-Sin',
      'As-Saffat',
      'Sad',
      'Az-Zumar',
      'Ghafir',
      'Fussilat',
      'Ash-Shura',
      'Az-Zukhruf',
      'Ad-Dukhan',
      'Al-Jathiya',
      'Al-Ahqaf',
      'Muhammad',
      'Al-Fath',
      'Al-Hujurat',
      'Qaf',
      'Adh-Dhariyat',
      'At-Tur',
      'An-Najm',
      'Al-Qamar',
      'Ar-Rahman',
      'Al-Waqia',
      'Al-Hadid',
      'Al-Mujadila',
      'Al-Hashr',
      'Al-Mumtahanah',
      'As-Saff',
      'Al-Jumua',
      'Al-Munafiqun',
      'At-Taghabun',
      'At-Talaq',
      'At-Tahrim',
      'Al-Mulk',
      'Al-Qalam',
      'Al-Haqqah',
      'Al-Maarij',
      'Nuh',
      'Al-Jinn',
      'Al-Muzzammil',
      'Al-Muddaththir',
      'Al-Qiyamah',
      'Al-Insan',
      'Al-Mursalat',
      'An-Naba',
      'An-Naziat',
      'Abasa',
      'At-Takwir',
      'Al-Infitar',
      'Al-Mutaffifin',
      'Al-Inshiqaq',
      'Al-Buruj',
      'At-Tariq',
      'Al-Ala',
      'Al-Ghashiyah',
      'Al-Fajr',
      'Al-Balad',
      'Ash-Shams',
      'Al-Lail',
      'Ad-Duha',
      'Ash-Sharh',
      'At-Tin',
      'Al-Alaq',
      'Al-Qadr',
      'Al-Bayyinah',
      'Az-Zalzalah',
      'Al-Adiyat',
      'Al-Qariah',
      'At-Takathur',
      'Al-Asr',
      'Al-Humazah',
      'Al-Fil',
      'Quraish',
      'Al-Maun',
      'Al-Kawthar',
      'Al-Kafirun',
      'An-Nasr',
      'Al-Masad',
      'Al-Ikhlas',
      'Al-Falaq',
      'An-Nas',
    ];
    if (n <= 0 || n >= names.length) return 'Surah $n';
    return names[n];
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showValidateModal() {
    // The +bonus row is only honest on the first seal of the day. On a
    // repeat seal claimValidate() flushes pending Seeds without the bonus,
    // so pass 0 and the popup hides the reward breakdown. Captured now,
    // before the async gap, since it reflects the seal that just ran.
    final gotBonus = XpService.instance.lastSealAwardedBonus;
    Future<void>(() async {
      // The seal-coin animation starts a beat after this callback returns.
      // Wait for it to register, then hold the "Coins Sealed!" popup until
      // the coins have finished flying into the garden.
      await Future.delayed(const Duration(milliseconds: 60));
      final inFlight = sealCoinAnimationInFlight;
      if (inFlight != null) await inFlight;
      if (!mounted) return;
      showValidationRewardPopup(
        context,
        pointsEarned: gotBonus ? PointReward.validate : 0,
        bonusPoints: 0, // streak bonus could be added here later
        onContinue: _triggerBoostPopup,
      );
    });
  }

  // Shows the Noor Boost popup — called after validation is confirmed.
  // Waits for the seal-coin animation to finish first, so the popup never
  // appears while coins are still flying into the garden.
  void _triggerBoostPopup() {
    Future<void>(() async {
      final inFlight = sealCoinAnimationInFlight;
      if (inFlight != null) {
        await inFlight;
      }
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      showNoorBoostPopup(
        context,
        onGoQuran: widget.onGoQuran,
        onGoDhikr: widget.onGoDhikr,
        onGoInvite: widget.onGoInvite,
      );
    });
  }

  Future<void> _loadDonations() async {
    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;

      // ── Wave 1: 4 independent reads in parallel ─────────────────────────
      // Was 5 sequential round-trips. The only dependency is "my donations"
      // which needs the project ids, so it stays in wave 2.
      final w1 = await Future.wait<dynamic>([
        // 0: active projects
        sb
            .from('community_projects')
            .select()
            .eq('is_active', true)
            .eq('is_completed', false)
            .order('sort_order', ascending: true, nullsFirst: false)
            .then<List<dynamic>>((v) => v as List)
            .catchError((_) => const <dynamic>[]),
        // 1: community totals per project
        sb
            .rpc('get_project_seed_totals')
            .then<List<dynamic>>((v) => v as List)
            .catchError((e) {
              debugPrint('Dashboard project totals RPC error: $e');
              return const <dynamic>[];
            }),
        // 2: distinct donor counts per project
        DonationService.instance.getProjectDonorCounts(),
        // 3: active orphans (best-effort)
        DonationService.instance.getOrphans().catchError(
          (_) => const <Orphan>[],
        ),
      ]);

      final data = List<Map<String, dynamic>>.from(
        (w1[0] as List).map((p) => Map<String, dynamic>.from(p as Map)),
      );

      if (data.isEmpty) {
        // Still surface orphans even if there are no community projects.
        final orphans = w1[3] as List<Orphan>;
        if (mounted) {
          setState(() {
            _myDonations =
                orphans.map(_orphanToDonationMap).toList(growable: false);
          });
        }
        return;
      }

      // Build totals + donor-count lookups from wave 1.
      final Map<String, int> totalPts = {};
      for (final r in (w1[1] as List)) {
        final m = r as Map;
        final pid = m['project_id'] as String?;
        if (pid != null) {
          totalPts[pid] = (m['current_seeds'] as num?)?.toInt() ?? 0;
        }
      }
      final donorCounts = w1[2] as Map<String, int>;

      // ── Wave 2: my donations (needs project ids from wave 1) ────────────
      Map<String, int> myPts = const {};
      if (uid != null) {
        final pids = data.map((d) => d['id'] as String).toList();
        try {
          final myDonations = await sb
              .from('user_donations')
              .select('project_id, points_donated')
              .eq('user_id', uid)
              .filter('project_id', 'in', pids);
          final m = <String, int>{};
          for (final r in (myDonations as List)) {
            final pid = r['project_id'] as String?;
            if (pid == null) continue;
            m[pid] = (m[pid] ?? 0) +
                ((r['points_donated'] as num?)?.toInt() ?? 0);
          }
          myPts = m;
        } catch (_) {}
      }

      // Merge everything onto the project rows.
      for (final d in data) {
        final id = d['id'] as String;
        d['current_points'] = totalPts[id] ?? 0;
        d['donor_count'] = donorCounts[id] ?? 0;
        d['my_donated'] = myPts[id] ?? 0;
        d['_type'] = 'project';
      }

      // Append orphans to the same strip (already fetched in wave 1).
      for (final o in (w1[3] as List<Orphan>)) {
        data.add(_orphanToDonationMap(o));
      }

      if (mounted) setState(() => _myDonations = data);
    } catch (_) {
      if (mounted) setState(() => _myDonations = []);
    }
  }

  /// Converts an [Orphan] to the same Map shape the `_MyDonationsSection`
  /// card already renders for community projects. `_type` is set to
  /// `'orphan'` so the tap handler routes to OrphanDetailScreen.
  Map<String, dynamic> _orphanToDonationMap(Orphan o) {
    final name = o.lastInitial != null && o.lastInitial!.isNotEmpty
        ? '${o.firstName} ${o.lastInitial}.'
        : o.firstName;
    return {
      '_type': 'orphan',
      '_orphan': o,
      'id': o.id,
      'title': 'Sponsor $name, ${o.age}',
      'sponsor': o.partnerOrg ?? 'Sponsored Orphan',
      'category': 'Orphan',
      'location': o.displayLocation ?? '',
      'description': o.story ?? '',
      'story': o.story ?? '',
      'short_description': o.story ?? '',
      'impact_quote': '',
      'target_points': o.targetSeeds,
      'current_points': o.currentSeeds,
      'my_donated': 0, // dashboard doesn't track per-orphan my-donated here
      'donor_count': o.sponsorCount,
      'dp_url': o.photoUrl ?? '',
      'is_active': true,
      'is_completed': o.currentSeeds >= o.targetSeeds,
      'sort_order': 0,
      'end_date': '',
      'estimated_usd': 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.name.split(' ').first;
    final greetingPrefix =
        AppLocalizations.of(context)?.greetingPrefix ?? 'Assalamu alaikum,';

    // Sub-text per activity tile (real data; safe fallbacks)
    final l10n = AppLocalizations.of(context);
    final quranSub =
        (_lastSurahName != null && _lastAyah != null)
            ? (_ayahsToday > 0
                ? '${_lastSurahName!} · $_lastAyah  · +$_ayahsToday today'
                : '${_lastSurahName!} · $_lastAyah')
            : 'Continue reading';
    final dhikrSub =
        _dhikrToday > 0
            ? (l10n?.setsTodayCount(_dhikrToday.toString()) ??
                '$_dhikrToday sets today')
            : (snapDhikrStreak() > 0
                ? '${snapDhikrStreak()}-day streak'
                : 'Start your daily azkar');
    final achievementsSub =
        _recentBadgeName != null
            ? (l10n?.lastAchievement(_recentBadgeName!) ??
                'Last: ${_recentBadgeName!}')
            : 'Lv ${widget.level} · ${_fmt(widget.totalXp)} ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}';
    final inviteSub = l10n?.earnPerFriend ?? 'Earn +500 per friend';

    return Container(
      // Honey-wash background replaces _HomeBgPainter pattern
      color: Y4.bg,
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header: greeting + bell + avatar tile ───────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greetingPrefix,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Y4.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Listen DIRECTLY to ProfileNameNotifier so a
                              // settings rename rebuilds just this text node
                              // even if the parent's widget.name happens to
                              // be stale due to nav-stack timing.
                              ValueListenableBuilder<String?>(
                                valueListenable:
                                    ProfileNameNotifier.instance.name,
                                builder: (context, override, _) {
                                  final overrideFirst =
                                      override?.trim().split(' ').first ?? '';
                                  final display = overrideFirst.isNotEmpty
                                      ? overrideFirst
                                      : (firstName.isEmpty ? 'Friend' : firstName);
                                  // Diagnostic: confirms whether this Text
                                  // widget actually rebuilds when the
                                  // notifier fires. Remove once verified.
                                  debugPrint(
                                      '[HomeTab greeting] rebuild: override=$override widget.name="${widget.name}" → "$display"');
                                  return Text(
                                    display,
                                    style: Y4.display(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                      height: 1.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Language selector moved to Profile > Settings
                        // Bell button — opens NotificationSheet
                        GestureDetector(
                          onTap: () => showNotificationsSheet(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            margin: const EdgeInsetsDirectional.only(end: 8),
                            decoration: BoxDecoration(
                              color: Y4.surface,
                              border: Border.all(color: Y4.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                ValueListenableBuilder<List<NotificationItem>>(
                                  valueListenable:
                                      NotificationCenter.instance.notifications,
                                  builder: (context, notifs, _) {
                                    final unreadCount =
                                        notifs.where((n) => !n.read).length;
                                    return Stack(
                                      alignment: Alignment.center,
                                      clipBehavior: Clip.none,
                                      children: [
                                        const Icon(
                                          Icons.notifications_none_rounded,
                                          size: 20,
                                          color: Y4.ink,
                                        ),
                                        if (unreadCount > 0)
                                          PositionedDirectional(
                                            top: 6,
                                            end: 6,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 14,
                                                minHeight: 14,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  unreadCount > 9
                                                      ? '9+'
                                                      : unreadCount.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                    height: 1.0,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                          ),
                        ),
                        // Avatar tile — preserves user image + level badge.
                        // Doubles as the Sabiq Seeds wallet target — the seal
                        // animation flies the coin into this widget.
                        GestureDetector(
                          key: sabiqProfileIconKey,
                          onTap: () => widget.onGoProfile?.call(),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Y4.honey,
                                  borderRadius: BorderRadius.circular(12),
                                  image:
                                      widget.avatarUrl != null
                                          ? DecorationImage(
                                            image: NetworkImage(
                                              widget.avatarUrl!,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                          : null,
                                ),
                                child:
                                    widget.avatarUrl == null
                                        ? Center(
                                          child: Text(
                                            firstName.isNotEmpty
                                                ? firstName[0].toUpperCase()
                                                : 'N',
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: Y4.ink,
                                            ),
                                          ),
                                        )
                                        : null,
                              ),
                              PositionedDirectional(
                                bottom: -5,
                                end: -5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Y4.ink,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Y4.bg,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    'LV ${widget.level}',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Y4.honey,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Garden hero (count-up + sun + 5 plants) ─────────────────────
                  const SizedBox(height: 4),
                  _Y4HeroCard(
                    value: widget.noorPoints ?? 0,
                    pendingPoints: XpService.instance.pendingPoints,
                    visitCount: widget.homeVisitCount,
                  ),

                  // ── Swipe-to-validate (honey-deep palette, gesture preserved) ───
                  const SizedBox(height: 12),
                  _SwipeValidateButton(
                    pendingPoints: XpService.instance.pendingPoints,
                    onValidate: () async {
                      final awarded = await widget.onValidate();
                      if (!mounted) return awarded;
                      if (awarded) {
                        _confettiController.play();
                        _showValidateModal();
                      } else {
                        _triggerBoostPopup();
                      }
                      return awarded;
                    },
                  ),

                  // ── Streak (single garden card with 7-day plant row) ────────────
                  const SizedBox(height: 16),
                  _Y4StreakCard(
                    snap: widget.streakSnap,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StreakScreen(),
                          ),
                        ),
                  ),

                  // ── Progress (tabbed sun-arc) ───────────────────────────────────
                  const SizedBox(height: 12),
                  _Y4ProgressCard(
                    todayPts: widget.todayPoints,
                    weekPts: widget.weekPoints,
                    monthPts: widget.monthPoints,
                    hasError: widget.hasError,
                  ),

                  // ── Activity grid: Quran, Dhikr, Achievements, Invite ───────────
                  // Per Y4: keep painted patterns + light rays effect, switch to
                  // honey palette per tile.
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 10),
                    child: Text(
                      AppLocalizations.of(context)?.todaysPlots ??
                          "Today's plots",
                      style: Y4.display(
                        fontSize: 20,
                        color: Y4.ink,
                        height: 1.0,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.78,
                    children: [
                      _ActivityCard(
                        title:
                            AppLocalizations.of(context)?.readQuran ?? 'Quran',
                        illustration: const PlotIllustration(PlotIcon.quran),
                        gradient: kPlotGradientA,
                        reward: quranSub,
                        onTap: widget.onGoQuran,
                      ),
                      _ActivityCard(
                        title:
                            AppLocalizations.of(context)?.dailyDhikr ??
                            'Dhikr',
                        illustration: const PlotIllustration(PlotIcon.dhikr),
                        gradient: kPlotGradientB,
                        reward: dhikrSub,
                        onTap: widget.onGoDhikr,
                      ),
                      _ActivityCard(
                        title:
                            AppLocalizations.of(context)?.achievements ??
                            'Achievements',
                        illustration: const PlotIllustration(
                          PlotIcon.achievements,
                        ),
                        gradient: kPlotGradientA,
                        reward: achievementsSub,
                        onTap: widget.onGoAchievements,
                      ),
                      _ActivityCard(
                        title:
                            AppLocalizations.of(context)?.inviteFriends ??
                            'Invite',
                        illustration: const PlotIllustration(PlotIcon.invite),
                        gradient: kPlotGradientB,
                        reward: inviteSub,
                        onTap: widget.onGoInvite,
                      ),
                    ],
                  ),

                  // ── Donations: section header (kept) + horizontal scroll
                  //    + quick-donate row + "See Details for more Projects" row ───
                  if (_myDonations.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  NoorIcon.target(size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppLocalizations.of(context)?.reciteMore ??
                                        'RECITE MORE.',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Y4.ink,
                                      letterSpacing: 0.8,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                AppLocalizations.of(context)?.helpRealLives ??
                                    'HELP REAL LIVES.',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Y4.honeyDeep,
                                  letterSpacing: 0.8,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                AppLocalizations.of(
                                      context,
                                    )?.fundProjectsText ??
                                    'Your Sabiq Seeds fund these projects',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Y4.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Y4.honey.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Y4.honey.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.activeCount(
                                  _myDonations.length.toString(),
                                ) ??
                                '${_myDonations.length} active',
                            style: GoogleFonts.rajdhani(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Y4.honeyDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Image-heavy horizontal list — RepaintBoundary keeps its
                    // inner scroll / image-loading paints from invalidating
                    // the rest of the home scroll layer.
                    RepaintBoundary(
                      child: _MyDonationsSection(
                        donations: _myDonations,
                        availablePoints: widget.noorPoints ?? 0,
                        onDonateMore: (item) {
                          // Route based on entity type — orphan or project.
                          if (item['_type'] == 'orphan' &&
                              item['_orphan'] is Orphan) {
                            final orphan = item['_orphan'] as Orphan;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrphanDetailScreen(
                                  orphan: orphan,
                                  availablePoints: widget.noorPoints ?? 0,
                                  onSponsored: (_) => _loadDonations(),
                                ),
                              ),
                            ).then((_) => _loadDonations());
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CommunityImpactPage(
                                scrollToProjectId: item['id'] as String?,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // ── Ad placement banner (Y4 styling) ────────────────────────────
                  if (context.watch<SettingsService>().config.adBannerEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: GestureDetector(
                        onTap: () async {
                          final config = context.read<SettingsService>().config;
                          if (config.adBannerLink.isNotEmpty) {
                            final uri = Uri.parse(config.adBannerLink);
                            if (await url_launcher.canLaunchUrl(uri)) {
                              await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 80),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Y4.cream,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Y4.border),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (context.watch<SettingsService>().config.adBannerIconUrl.isNotEmpty)
                                CachedNetworkImage(imageUrl: context.watch<SettingsService>().config.adBannerIconUrl, height: 32)
                              else
                                Icon(Icons.ad_units_rounded, color: Y4.muted, size: 24),
                              const SizedBox(height: 6),
                              Text(
                                context.watch<SettingsService>().config.adBannerText,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Y4.inkSoft,
                                ),
                              ),
                              if (context.watch<SettingsService>().config.adBannerSubtitle.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    context.watch<SettingsService>().config.adBannerSubtitle,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Y4.muted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                // Y4 honey/sage celebration palette
                colors: const [
                  Y4.honey,
                  Y4.honeyDeep,
                  Y4.butter,
                  Y4.primary,
                  Y4.amberY,
                ],
                createParticlePath: (size) {
                  final path = Path();
                  path.addOval(Rect.fromCircle(center: Offset.zero, radius: 4));
                  return path;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Convenience accessor used by tile sub-text.
  int snapDhikrStreak() => widget.streakSnap.dhikr;

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
  bool _loading = false;
  String? _error;
  String? _success;
  bool _codeCopied = false;
  bool _linkCopied = false;

  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmer;

  String get _shareLink =>
      'https://sabiq-rewards.vercel.app/join?ref=${widget.referralCode}';

  String get _shareMessage =>
      'Join me on Sabiq Rewards, earn Seeds for daily Quran, Dhikr & good deeds!\n\n'
      'Use my code *${widget.referralCode}* and we both get 500 Sabiq Seeds!\n\n'
      '$_shareLink';

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _shimmer = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
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
    setState(() {
      _codeCopied = true;
      _linkCopied = false;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _shareLink));
    setState(() {
      _linkCopied = true;
      _codeCopied = false;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _linkCopied = false);
    });
  }

  void _shareGeneral() {
    // ignore: deprecated_member_use
    Share.share(_shareMessage, subject: 'Join Sabiq Rewards');
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
      Share.share(_shareMessage, subject: 'Join Sabiq Rewards');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message copied, share or paste in WhatsApp!',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF25D366),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _applyCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      await Supabase.instance.client.rpc(
        'apply_referral',
        params: {'inviter_code': code},
      );
      setState(() => _success = '500 Sabiq Seeds rewarded to you both!');
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
        context
            .findAncestorStateOfType<_DashboardScreenState>()
            ?._loadHomeData();
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
      builder:
          (ctx, scroll) => Container(
            decoration: BoxDecoration(
              // Honey wash gradient sheet — matches dashboard hero
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Y4.cream, Y4.bg, Y4.bg],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Drag handle
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Y4.muted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scroll,
                    padding: EdgeInsets.fromLTRB(
                      22,
                      20,
                      22,
                      MediaQuery.of(context).viewInsets.bottom + 30,
                    ),
                    children: [
                      // ── Header ──────────────────────────────────────────────────
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Y4.honey,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Y4.honeyDeep.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Center(child: NoorIcon.handshake(size: 24)),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)?.inviteFriends ??
                                    'Invite Friends',
                                style: Y4.display(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: Y4.ink,
                                  letterSpacing: -0.3,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)?.youBothEarnSeeds ??
                                    'You both earn 500 Sabiq Seeds!',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Y4.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ── Reward Banner — light honey gradient ─────────────────────
                      // RepaintBoundary isolates the shimmer's 60fps repaints so
                      // they don't dirty the rest of the home scroll layer.
                      RepaintBoundary(
                        child: AnimatedBuilder(
                        animation: _shimmer,
                        builder:
                            (_, __) => Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Y4.butter, Y4.honey, Y4.butter],
                                  stops: [0.0, 0.5, 1.0],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Y4.honeyDeep.withValues(alpha: 0.6),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Y4.honeyDeep.withValues(alpha: 0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _RewardPill(
                                    icon: NoorIcon.pointing(size: 20),
                                    label:
                                        AppLocalizations.of(context)?.youGet ??
                                            'You get',
                                    points: '+500',
                                  ),
                                  Container(
                                    height: 40,
                                    width: 1,
                                    color: Y4.honeyDeep.withValues(alpha: 0.25),
                                  ),
                                  _RewardPill(
                                    icon: NoorIcon.people(size: 20),
                                    label:
                                        AppLocalizations.of(context)?.friendGets ??
                                            'Friend gets',
                                    points: '+500',
                                  ),
                                ],
                              ),
                            ),
                      ),
                      ),

                      const SizedBox(height: 22),

                      // ── Your Code ────────────────────────────────────────────────
                      Text(
                        AppLocalizations.of(context)?.yourReferralCode ??
                            'YOUR REFERRAL CODE',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Y4.inkSoft,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Y4.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Y4.border),
                          boxShadow: [
                            BoxShadow(
                              color: Y4.ink.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                code.isNotEmpty ? code : '– – – – –',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 8,
                                  color: Y4.ink,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _copyCode,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _codeCopied
                                          ? Y4.honeyDeep
                                          : Y4.honey.withValues(alpha: 0.30),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Y4.honeyDeep.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _codeCopied
                                          ? Icons.check_rounded
                                          : Icons.copy_rounded,
                                      size: 16,
                                      color:
                                          _codeCopied
                                              ? Colors.white
                                              : Y4.honeyDeep,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _codeCopied
                                          ? (AppLocalizations.of(context)
                                                  ?.copiedLabel ??
                                              'Copied!')
                                          : (AppLocalizations.of(context)
                                                  ?.copyLabel ??
                                              'Copy'),
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            _codeCopied
                                                ? Colors.white
                                                : Y4.honeyDeep,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Share Link Row ────────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Y4.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Y4.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.link_rounded,
                              size: 18,
                              color: Y4.muted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _shareLink,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Y4.inkSoft,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: _copyLink,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _linkCopied ? Y4.honeyDeep : Y4.cream,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        _linkCopied ? Y4.honeyDeep : Y4.border,
                                  ),
                                ),
                                child: Text(
                                  _linkCopied
                                      ? (AppLocalizations.of(context)
                                              ?.copiedLabel ??
                                          'Copied!')
                                      : (AppLocalizations.of(context)
                                              ?.copyLink ??
                                          'Copy Link'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        _linkCopied
                                            ? Colors.white
                                            : Y4.honeyDeep,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ── Share Buttons ─────────────────────────────────────────────
                      Text(
                        AppLocalizations.of(context)?.shareVia ?? 'SHARE VIA',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Y4.inkSoft,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // WhatsApp — keep brand green for recognizability
                          Expanded(
                            child: GestureDetector(
                              onTap: _shareWhatsApp,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF25D366),
                                      Color(0xFF128C7E),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF25D366,
                                      ).withValues(alpha: 0.30),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    NoorIcon.chat(size: 26),
                                    const SizedBox(height: 6),
                                    Text(
                                      AppLocalizations.of(context)
                                              ?.whatsappLabel ??
                                          'WhatsApp',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // General Share — Y4 honey gradient
                          Expanded(
                            child: GestureDetector(
                              onTap: _shareGeneral,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Y4.honey, Y4.honeyDeep],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Y4.honeyDeep.withValues(
                                        alpha: 0.30,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    NoorIcon.share(size: 26),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Share More',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // ── Divider ──────────────────────────────────────────────────
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Y4.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Have an invite code?',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Y4.inkSoft,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: Y4.border)),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Enter Code ───────────────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _codeCtrl,
                              textCapitalization: TextCapitalization.characters,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Y4.ink,
                                letterSpacing: 2,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    AppLocalizations.of(context)?.enterCodeHint ??
                                        'Enter code…',
                                hintStyle: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: Y4.muted,
                                ),
                                filled: true,
                                fillColor: Y4.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Y4.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Y4.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Y4.honeyDeep,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _loading ? null : _applyCode,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: _loading ? Y4.muted : Y4.honeyDeep,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow:
                                    _loading
                                        ? []
                                        : [
                                          BoxShadow(
                                            color: Y4.honeyDeep.withValues(
                                              alpha: 0.30,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                              ),
                              child:
                                  _loading
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text(
                                        'Apply',
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 16,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.outfit(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_success != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Y4.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Y4.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: Y4.primaryDeep,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _success!,
                                  style: GoogleFonts.outfit(
                                    color: Y4.primaryDeep,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

// Small reward pill widget used in the banner — Y4 honey ink palette
class _RewardPill extends StatelessWidget {
  final Widget icon;
  final String label, points;
  const _RewardPill({
    required this.icon,
    required this.label,
    required this.points,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Y4.honey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Y4.honeyDeep.withValues(alpha: 0.6)),
          ),
          child: Center(child: icon),
        ),
        const SizedBox(height: 6),
        Text(
          points,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Y4.ink,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Y4.inkSoft,
          ),
        ),
      ],
    );
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
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // Solid card colors — (light center, deep outer) for radial gradient
  static const _cardColors = [
    [Color(0xFFF9CB5C), Color(0xFFE08A0E)], // Login   — warm amber
    [Color(0xFF3DDBA0), Color(0xFF0B9E63)], // Dhikr   — emerald
    [Color(0xFF9B87F5), Color(0xFF4B35D4)], // Quran   — indigo violet
  ];
  @override
  Widget build(BuildContext context) {
    final streaks = [widget.snap.login, widget.snap.dhikr, widget.snap.quran];
    final types = StreakType.values;
    final best = streaks.reduce((a, b) => a > b ? a : b);
    final next = nextMilestone(best);

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StreakScreen()),
          ),
      child: AnimatedBuilder(
        animation: _glow,
        builder:
            (_, __) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      NoorIcon.fire(size: 16),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)?.streaks.toUpperCase() ??
                            'STREAKS',
                        style: GoogleFonts.rajdhani(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3D2C1E),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      if (next != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF6B35,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFFFF6B35,
                              ).withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            '${next.emoji} ${AppLocalizations.of(context)?.next ?? 'Next'}: ${next.days}d',
                            style: GoogleFonts.rajdhani(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF9500),
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFBB8B6E),
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3 streak chips — solid bold cards with sunburst rays
                  Row(
                    children: [
                      for (int i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Builder(
                          builder: (context) {
                            final s = streaks[i];
                            final alive = s > 0;
                            final colors = _cardColors[i];
                            final type = types[i];
                            return Expanded(
                              child: AnimatedBuilder(
                                animation: _glow,
                                builder: (_, __) {
                                  final decoration = BoxDecoration(
                                    gradient:
                                        alive
                                            ? RadialGradient(
                                              colors: [colors[0], colors[1]],
                                              center: const Alignment(
                                                -0.2,
                                                -0.5,
                                              ),
                                              radius: 1.4,
                                            )
                                            : const RadialGradient(
                                              colors: [
                                                Color(0xFFF4F4F4),
                                                Color(0xFFD8D8D8),
                                              ],
                                              center: Alignment(-0.2, -0.5),
                                              radius: 1.3,
                                            ),
                                    borderRadius: BorderRadius.circular(18),
                                  );
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow:
                                          alive
                                              ? [
                                                BoxShadow(
                                                  color: colors[1].withValues(
                                                    alpha: _glow.value * 0.50,
                                                  ),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                                BoxShadow(
                                                  color: colors[0].withValues(
                                                    alpha: 0.25,
                                                  ),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ]
                                              : [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.06),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Stack(
                                        children: [
                                          // ── Solid gradient base ───────────────────────────
                                          Positioned.fill(
                                            child: DecoratedBox(
                                              decoration: decoration,
                                            ),
                                          ),

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
                                              vertical: 16,
                                              horizontal: 8,
                                            ),
                                            child: Column(
                                              children: [
                                                NoorIcon.fromEmoji(
                                                  type.emoji,
                                                  size: 22,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '$s',
                                                  style: GoogleFonts.rajdhani(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w900,
                                                    color:
                                                        alive
                                                            ? Colors.white
                                                            : Colors
                                                                .grey
                                                                .shade400,
                                                    height: 1.0,
                                                    shadows:
                                                        alive
                                                            ? [
                                                              Shadow(
                                                                color: Colors
                                                                    .black
                                                                    .withValues(
                                                                      alpha:
                                                                          0.25,
                                                                    ),
                                                                blurRadius: 4,
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      2,
                                                                    ),
                                                              ),
                                                            ]
                                                            : null,
                                                  ),
                                                ),
                                                Text(
                                                  s == 1
                                                      ? (AppLocalizations.of(
                                                            context,
                                                          )?.day ??
                                                          'day')
                                                      : (AppLocalizations.of(
                                                            context,
                                                          )?.days ??
                                                          'days'),
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 9,
                                                    color:
                                                        alive
                                                            ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.80,
                                                                )
                                                            : Colors
                                                                .grey
                                                                .shade400,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        alive
                                                            ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.22,
                                                                )
                                                            : Colors.grey
                                                                .withValues(
                                                                  alpha: 0.15,
                                                                ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _localizeStreakType(
                                                      context,
                                                      type.label,
                                                    ),
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          alive
                                                              ? Colors.white
                                                                  .withValues(
                                                                    alpha: 0.9,
                                                                  )
                                                              : Colors
                                                                  .grey
                                                                  .shade400,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sunburst ray painter — radiating wedge rays from a focal point
// ─────────────────────────────────────────────────────────────────────────────
class _SunburstPainter extends CustomPainter {
  final int count; // number of bright rays (gaps = equal count)
  final double focalX, focalY; // focal point as fraction of width/height
  final double rayAlpha; // opacity of bright ray fills
  const _SunburstPainter({
    this.count = 10,
    this.focalX = 0.50,
    this.focalY = -0.15,
    this.rayAlpha = 0.16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * focalX;
    final cy = size.height * focalY;
    final r =
        math.sqrt(size.width * size.width + size.height * size.height) * 1.6;
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: rayAlpha)
          ..style = PaintingStyle.fill;

    final step = math.pi * 2 / (count * 2); // angle per slice
    for (int i = 0; i < count; i++) {
      final a0 = i * 2 * step;
      final a1 = a0 + step;
      final path =
          Path()
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

  @override
  Widget build(BuildContext context) {
    final ss = context.watch<SettingsService>();
    final dayGoal = ss.dayGoal;
    final weekGoal = ss.weekGoal;
    final monthGoal = ss.monthGoal;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + streak bubble
          Row(
            children: [
              Text(
                AppLocalizations.of(context)?.yourProgress.toUpperCase() ??
                    'YOUR PROGRESS',
                style: GoogleFonts.rajdhani(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _C.text,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              // Streak flame
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF9500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.30),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NoorIcon.fire(size: 13),
                    const SizedBox(width: 4),
                    Text(
                      hasError
                          ? '---'
                          : '${streak ?? 0} day${streak == 1 ? '' : 's'}',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Three progress bars
          _ProgBar(
            label: AppLocalizations.of(context)?.todayTab ?? 'Today',
            pts: todayPts,
            goal: dayGoal,
            color: const Color(0xFF00897B),
            icon: NoorIcon.sunrise(size: 16),
            hasError: hasError,
          ),
          const SizedBox(height: 12),
          _ProgBar(
            label: AppLocalizations.of(context)?.thisWeek ?? 'This Week',
            pts: weekPts,
            goal: weekGoal,
            color: const Color(0xFF5C6BC0),
            icon: NoorIcon.calendar(size: 16),
            hasError: hasError,
          ),
          const SizedBox(height: 12),
          _ProgBar(
            label: AppLocalizations.of(context)?.thisMonth ?? 'This Month',
            pts: monthPts,
            goal: monthGoal,
            color: const Color(0xFFE91E8C),
            icon: NoorIcon.calendar(size: 16),
            hasError: hasError,
          ),
        ],
      ),
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
    required this.label,
    required this.pts,
    required this.goal,
    required this.color,
    required this.icon,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final cur = pts ?? 0;
    final pct = (cur / goal).clamp(0.0, 1.0);
    final done = cur >= goal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _C.text,
              ),
            ),
            const Spacer(),
            if (hasError || pts == null)
              Text(
                '--- / $goal',
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _C.text,
                ),
              )
            else if (done)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context)?.goalLabel ?? 'Goal',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              )
            else
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$pts ',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _C.text,
                      ),
                    ),
                    TextSpan(
                      text:
                          '/ $goal ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                      style: GoogleFonts.outfit(fontSize: 11, color: _C.sub),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(
              done ? color : color.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity Card — bold solid card with unique per-type decoration
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityCard extends StatefulWidget {
  final String title, reward;
  final Widget illustration;
  /// Two-stop pale-cream card gradient (kPlotGradientA / kPlotGradientB).
  final List<Color> gradient;
  final VoidCallback onTap;
  const _ActivityCard({
    required this.title,
    required this.illustration,
    required this.gradient,
    required this.reward,
    required this.onTap,
  });
  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  // Deep brown — the mockup's card text colour.
  static const _ink = Color(0xFF5A4818);
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF785014).withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // ── Big 3D illustration — sits at the top of the card ──
                Positioned(
                  top: 6,
                  left: 0,
                  right: 0,
                  child: Center(child: widget.illustration),
                ),
                // ── Title + info pill — anchored bottom-left ───────────
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fraunces(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.reward,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Background — very subtle Islamic-inspired lattice at low opacity
// ─────────────────────────────────────────────────────────────────────────────
class _HomeBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint =
        Paint()
          ..color = _C.teal.withValues(alpha: 0.07)
          ..style = PaintingStyle.fill;
    final arcPaint =
        Paint()
          ..color = _C.teal.withValues(alpha: 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Dot grid — every 38px, off-center
    const spacing = 38.0;
    const dotR = 2.2;
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
        math.pi * 0.45,
        math.pi * 0.65,
        false,
        arcPaint,
      );
    }

    // Faint large circle bottom-left
    canvas.drawCircle(
      Offset(0, size.height),
      size.width * 0.55,
      Paint()
        ..color = _C.teal.withValues(alpha: 0.03)
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
    final list = await DonationService.instance.getProjectMedia(
      widget.projectId,
    );
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
            child: CircularProgressIndicator(strokeWidth: 1.5, color: _C.teal),
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
        child: Icon(
          Icons.volunteer_activism_rounded,
          size: widget.size * 0.6,
          color: _C.teal,
        ),
      );
    }
    if (_cover!.isVideo) {
      return Container(
        width: s,
        height: s,
        decoration: BoxDecoration(color: Colors.black, borderRadius: radius),
        child: Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: widget.size * 1.1,
        ),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: _cover!.url,
        width: s,
        height: s,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => NoorIcon.image(size: widget.size),
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
      child: CachedNetworkImage(
        imageUrl: dpUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorWidget:
            (_, __, ___) =>
                _ProjectCover(projectId: project['id'] as String, size: size),
      ),
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
          height: 460,
          child: ListView.separated(
            clipBehavior: Clip.hardEdge,
            scrollDirection: Axis.horizontal,
            itemCount: donations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (ctx, i) {
              final d = donations[i];
              final target = (d['target_points'] as num).toInt();
              final current = (d['current_points'] as num).toInt();
              final myPts = (d['my_donated'] as num).toInt();
              final donorCount = (d['donor_count'] as num?)?.toInt() ?? 0;
              final pct =
                  target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
              final isCompleted = d['is_completed'] == true;

              final dpUrl = d['dp_url'] as String?;
              Widget banner;
              if (dpUrl != null && dpUrl.isNotEmpty) {
                banner = SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: CachedNetworkImage(
                    imageUrl: dpUrl,
                    fit: BoxFit.cover,
                    errorWidget:
                        (_, __, ___) => Container(
                          color: Y4.cream,
                          child: Center(
                            child: Icon(
                              Icons.volunteer_activism_rounded,
                              size: 44,
                              color: Y4.honeyDeep,
                            ),
                          ),
                        ),
                  ),
                );
              } else {
                banner = Container(
                  width: double.infinity,
                  height: 160,
                  color: Y4.cream,
                  child: Center(
                    child: Icon(
                      Icons.volunteer_activism_rounded,
                      size: 44,
                      color: Y4.honeyDeep,
                    ),
                  ),
                );
              }

              String fmt(int n) =>
                  n >= 1000000
                      ? '${(n / 1000000).toStringAsFixed(1)}M'
                      : (n >= 1000
                          ? '${(n / 1000).toStringAsFixed(1)}k'
                          : '$n');

              return Container(
                width: donations.length == 1 ? constraints.maxWidth : 320,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Y4.ink.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Image banner (kept) ─────────────────────────────
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: banner,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Caption
                            Text(
                              AppLocalizations.of(context)?.plantGoodDeeds ??
                                  'PLANT GOOD DEEDS',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Y4.honeyDeep,
                                letterSpacing: 1.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Title (Fraunces serif, italic accent in honey)
                            Text(
                              (d['title'] ?? '').toString(),
                              style: Y4.display(
                                fontSize: 20,
                                color: Y4.ink,
                                fontWeight: FontWeight.w400,
                                height: 1.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),

                            // ── Raised + % row (LaunchGood-style headline) ──
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SabiqCoin(size: 22),
                                const SizedBox(width: 6),
                                Text(
                                  '${fmt(current)} ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                                  style: Y4.display(
                                    fontSize: 22,
                                    color: Y4.honeyDeep,
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'raised',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Y4.inkSoft,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  // Show "<1%" instead of "0%" when there's
                                  // any progress at all — even a single
                                  // donation shouldn't read as zero.
                                  (pct > 0 && pct * 100 < 1)
                                      ? '<1%'
                                      : '${(pct * 100).round()}%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Y4.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // ── Honey→butter progress bar ──
                            // The Column above uses crossAxisAlignment.start
                            // so the Container won't stretch horizontally on
                            // its own — it would size to the fractional
                            // child's intrinsic width (the 5% fill) and the
                            // empty portion would visually vanish. Wrap in
                            // SizedBox(width: infinity) to force full width
                            // so the track pill is always visible.
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Y4.honey.withValues(alpha: 0.38),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Y4.honeyDeep.withValues(alpha: 0.65),
                                    width: 1.5,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: pct,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Y4.honey, Y4.honeyDeep],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // ── Goal + contributors row ──
                            Row(
                              children: [
                                Text(
                                  '${AppLocalizations.of(context)?.goalLabel ?? 'Goal'}: ',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Y4.ink,
                                  ),
                                ),
                                const SabiqCoin(size: 22),
                                const SizedBox(width: 4),
                                Text(
                                  '${fmt(target)} ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Y4.ink,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.people_alt_rounded,
                                  size: 13,
                                  color: Y4.inkSoft,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)
                                          ?.contributorCount(donorCount) ??
                                      '$donorCount ${donorCount == 1 ? 'contributor' : 'contributors'}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Y4.ink,
                                  ),
                                ),
                              ],
                            ),
                            // "You donated" small caption
                            if (myPts > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                '${AppLocalizations.of(context)?.youDonated ?? 'You donated'} ${fmt(myPts)} ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Y4.honeyDeep,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),

                            // Quick donate row: 50 / 100 / 250
                            if (!isCompleted) ...[
                              Row(
                                children: [
                                  _Y4DonateChip(
                                    amount: 50,
                                    onTap: () => onDonateMore(d),
                                  ),
                                  const SizedBox(width: 8),
                                  _Y4DonateChip(
                                    amount: 100,
                                    onTap: () => onDonateMore(d),
                                  ),
                                  const SizedBox(width: 8),
                                  _Y4DonateChip(
                                    amount: 250,
                                    onTap: () => onDonateMore(d),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],

                            // CTA — copy depends on entity type. Orphan
                            // cards say "See details" (no "more projects"
                            // suffix since orphans aren't projects).
                            GestureDetector(
                              onTap: () => onDonateMore(d),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: Y4.honey,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Center(
                                  child: Text(
                                    d['_type'] == 'orphan'
                                        ? 'See details →'
                                        : (AppLocalizations.of(context)
                                                ?.seeDetailsForMoreProjects ??
                                            'See Details for more Projects →'),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Y4.ink,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Quick-donate chip (50 / 100 / 250 pts) — Y4 ghost button style.
class _Y4DonateChip extends StatelessWidget {
  final int amount;
  final VoidCallback onTap;
  const _Y4DonateChip({required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: Y4.border,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SabiqCoin(size: 22),
                const SizedBox(width: 4),
                Text(
                  '$amount ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Y4.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    final fmtFull = _withCommasStr(targetStr);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _C.teal.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _C.teal.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFF5FAF9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
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
                                  child: Text(
                                    ',',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: _C.teal.withValues(alpha: 0.55),
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
                  Container(height: 0.8, color: _C.teal.withValues(alpha: 0.3)),

                  // ── Label strip ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A9E8C), _C.teal],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(
                              context,
                            )?.yourTotalNoorPoints.toUpperCase() ??
                            'YOUR TOTAL SABIQ SEEDS',
                        style: GoogleFonts.rajdhani(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
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
  static const double _kExtraSpinsBase = 3.0; // minimum extra full rotations
  static const double _kExtraSpinsStep =
      0.8; // additional spins per slot from right
  static const double _digitHeight = 62.0;
  static const double _slotH = 62.0;

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
    final extraSpins = _kExtraSpinsBase + posFromRight * _kExtraSpinsStep;

    // Stagger: rightmost starts immediately, leftmost starts a little later.
    // This way the first digit that settles is the rightmost one.
    final staggerDelay =
        slotIndex * 0.04; // leftmost slots start slightly later
    final localProg = ((progress - staggerDelay) / (1.0 - staggerDelay)).clamp(
      0.0,
      1.0,
    );

    // Apply easeOut so the spin decelerates nicely.
    final easedProg = Curves.easeOut.transform(localProg);

    // Total scroll distance in digits:
    //   We scroll from 0 downward (digit 0 at top → digit 9 at bottom = 1 rotation).
    //   extraSpins full rotations + arrive exactly at targetDigit.
    final totalDigitScroll = extraSpins * 10 + targetDigit;
    // Current scroll in pixels (upward scroll = translate negative Y).
    final scrolledDigits = easedProg * totalDigitScroll;
    // Which digit row we are currently at (fractional).
    final fractionalRow = scrolledDigits % 10;
    // Translate the 10-digit column upward by fractionalRow * digitHeight.
    final translateY = -fractionalRow * _digitHeight;

    return ClipRect(
      child: SizedBox(
        width: 48,
        height: _slotH,
        child: Stack(
          children: [
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
              top: 0,
              left: 0,
              right: 0,
              height: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF5FAF9),
                      const Color(0xFFF5FAF9).withValues(alpha: 0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // ── Bottom fade mask ────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF5FAF9).withValues(alpha: 0),
                      const Color(0xFFF5FAF9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // ── Centre fold line ───────────────────────────────────────
            Center(
              child: Container(
                height: 0.8,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                color: _C.teal.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.teal.withValues(alpha: 0.4), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: _C.teal.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$digit',
          style: GoogleFonts.rajdhani(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E5040),
            height: 1,
            shadows: [
              Shadow(color: _C.teal.withValues(alpha: 0.35), blurRadius: 8),
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
      width: 10,
      height: 10,
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
            blurRadius: 8,
            spreadRadius: 0,
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
  @override
  State<_ImpactTab> createState() => _ImpactTabState();
}

class _ImpactTabState extends State<_ImpactTab> {
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _myDonations = [];
  Map<String, List<ProjectMedia>> _projectMedia = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Supabase.instance.client
          .from('community_projects')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true, nullsFirst: false);
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
      _projectMedia = await DonationService.instance.getMediaForProjects(
        projectIds,
      );
    } catch (_) {}

    // Load user's donations in parallel
    _myDonations = await DonationService.instance.getUserProjectDonations();

    // Load contributor counts (distinct donors per project) so each card
    // can surface "X contributors" like LaunchGood.
    final donorCounts = await DonationService.instance
        .getProjectDonorCounts();

    // Sync the correct current_points + donor count into myDonations.
    for (var m in _myDonations) {
      final realPts =
          _projects.cast<Map<String, dynamic>?>().firstWhere(
            (p) => p?['id'] == m['id'],
            orElse: () => null,
          )?['current_points'];
      if (realPts != null) m['current_points'] = realPts;
      final pid = m['id'] as String?;
      if (pid != null) m['donor_count'] = donorCounts[pid] ?? 0;
    }
    // And into the active project list (used elsewhere on the dashboard).
    for (var p in _projects) {
      final pid = p['id'] as String?;
      if (pid != null) p['donor_count'] = donorCounts[pid] ?? 0;
    }

    if (mounted) setState(() => _loading = false);
  }

  String _fmtM(num n) =>
      n >= 1000000
          ? '${(n / 1000000).toStringAsFixed(1)}M'
          : (n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n');

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: NoorInlineLoader());
    final active = _projects.where((p) => p['is_active'] == true).toList();
    final completed =
        _projects.where((p) => p['is_completed'] == true).toList();

    // Get the user's available points from the main screen's state context
    final parentState =
        context.findAncestorStateOfType<_DashboardScreenState>();
    final availablePoints = parentState?._noorPoints ?? 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                AppLocalizations.of(context)?.communityImpact ??
                    'Community Impact',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _C.text,
                ),
              ),
            ),
            const SizedBox(height: 16),

            for (final p in active) ...[
              _ProjectCard(
                project: p,
                mediaList: _projectMedia[p['id']] ?? [],
                availablePoints: availablePoints,
                fmtM: _fmtM,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ProjectDetailScreen(
                            project: p,
                            availablePoints: availablePoints,
                            onDonationSuccess: () => _load(),
                          ),
                    ),
                  );
                  _load();
                },
              ),
              const SizedBox(height: 1), // thin divider gap between cards
            ],

            if (completed.isNotEmpty) ...[
              Text(
                AppLocalizations.of(context)?.completedProjects ??
                    'Completed Projects',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _C.text,
                ),
              ),
              const SizedBox(height: 12),
              for (final p in completed)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3D4),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE8C870).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(child: _buildProjIcon(p, 56)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['title'],
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _C.text,
                              ),
                            ),
                            Text(
                              '\$${p['estimated_usd'].toStringAsFixed(0)} funded • ${p['sponsor']}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: _C.sub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Donate Dialog ──────────────────────────────────────────────────────────
  void _showDonateSheet(
    BuildContext context,
    Map<String, dynamic> project,
    int availablePoints,
    _DashboardScreenState? parentState,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: _DonateSheetContent(
              project: project,
              availablePoints: availablePoints,
              onSuccess: (amount) {
                // Refresh the Impact tab
                _load();
                // Update the parent dashboard (header) balance smoothly
                if (parentState != null) {
                  parentState.setState(() {
                    parentState._noorPoints = ((parentState._noorPoints ?? 0) -
                            amount)
                        .clamp(0, 99999999);
                  });
                }
              },
            ),
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROJECT CARD — tappable preview in the Impact tab
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final List<ProjectMedia> mediaList;
  final int availablePoints;
  final String Function(num) fmtM;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.mediaList,
    required this.availablePoints,
    required this.fmtM,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = project;
    final dpUrl = p['dp_url'] as String?;
    final current = (p['current_points'] as num?)?.toInt() ?? 0;
    final target = (p['target_points'] as num?)?.toInt() ?? 1;
    final pct = (current / target).clamp(0.0, 1.0);
    final category = p['category'] as String?;
    final location = p['location'] as String?;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            SizedBox(
              height: 200,
              child:
                  mediaList.isNotEmpty
                      ? ProjectMediaCarousel(media: mediaList, height: 200)
                      : dpUrl != null && dpUrl.isNotEmpty
                      ? Stack(
                        fit: StackFit.expand,
                        children: [CachedNetworkImage(imageUrl: dpUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity)],
                      )
                      : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_C.teal, Color(0xFF1A9E8C)],
                          ),
                        ),
                        child: Center(child: NoorIcon.drop(size: 64)),
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  if (category != null || location != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 6,
                        children: [
                          if (category != null && category.isNotEmpty)
                            _ImpactChip(
                              category,
                              const Color(0xFFE8F8F5),
                              _C.teal,
                            ),
                          if (location != null && location.isNotEmpty)
                            _ImpactChip(
                              '📍 $location',
                              const Color(0xFFFFF3D4),
                              _C.amber,
                            ),
                        ],
                      ),
                    ),

                  // Title
                  Text(
                    p['title'] ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _C.text,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Sponsor
                  Text(
                    'By ${p['sponsor'] ?? ''}',
                    style: GoogleFonts.outfit(fontSize: 12, color: _C.sub),
                  ),
                  const SizedBox(height: 14),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE8F8F5),
                      valueColor: AlwaysStoppedAnimation(_C.teal),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const SabiqCoin(size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${fmtM(current)} / ${fmtM(target)} ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                        style: GoogleFonts.outfit(fontSize: 12, color: _C.sub),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3D4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '\$${(p['estimated_usd'] ?? 0).toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _C.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // CTA button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient:
                          availablePoints > 0
                              ? LinearGradient(
                                colors: [_C.teal, Color(0xFF1A9883)],
                              )
                              : null,
                      color: availablePoints > 0 ? null : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow:
                          availablePoints > 0
                              ? [
                                BoxShadow(
                                  color: _C.teal.withValues(alpha: 0.28),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                              : null,
                    ),
                    child: Center(
                      child: Text(
                        availablePoints > 0
                            ? '🤲  View Campaign & Donate'
                            : 'View Campaign',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: availablePoints > 0 ? Colors.white : _C.sub,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _ImpactChip(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
    ),
  );
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
    if (_selectedAmount <= 0 || _selectedAmount > widget.availablePoints)
      return;

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
                Icon(Icons.check_circle_rounded, color: _C.teal, size: 72),
                const SizedBox(height: 20),
                Text(
                  'Alhamdulillah!',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _C.text,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You donated $_selectedAmount Seeds to\n${widget.project['title']}.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: _C.sub,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
              ] else ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _C.communityBg,
                        shape: BoxShape.circle,
                      ),
                      child: _buildProjIcon(widget.project, 54),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Support this Cause',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _C.text,
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.project['title'],
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: _C.sub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // Available Balance
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _C.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _C.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SabiqCoin(size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Available Balance:',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: _C.sub,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.availablePoints} ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _C.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick amount selectors
                Row(
                  children: [
                    _AmountPill(
                      50,
                      _selectedAmount,
                      widget.availablePoints,
                      () => _setAmount(50),
                    ),
                    const SizedBox(width: 10),
                    _AmountPill(
                      100,
                      _selectedAmount,
                      widget.availablePoints,
                      () => _setAmount(100),
                    ),
                    const SizedBox(width: 10),
                    _AmountPill(
                      500,
                      _selectedAmount,
                      widget.availablePoints,
                      () => _setAmount(500),
                    ),
                    const SizedBox(width: 10),
                    _AmountPill(
                      widget.availablePoints,
                      _selectedAmount,
                      widget.availablePoints,
                      () => _setAmount(widget.availablePoints),
                      isMax: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  'Donation Amount',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _C.sub,
                  ),
                ),
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
                        child: Text(
                          '$_selectedAmount',
                          style: GoogleFonts.outfit(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: _C.navImpact,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        AppLocalizations.of(context)?.seedsUnit ?? 'Seeds',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _C.sub,
                        ),
                      ),
                    ),
                  ],
                ),

                // Slider
                Slider(
                  value: _selectedAmount.toDouble(),
                  min: 1,
                  max: widget.availablePoints.toDouble().clamp(
                    1.0,
                    double.infinity,
                  ),
                  activeColor: _C.navImpact,
                  inactiveColor: _C.navImpact.withValues(alpha: 0.2),
                  onChanged:
                      widget.availablePoints > 0
                          ? (val) => _setAmount(val.round())
                          : null,
                ),

                if (_errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMsg!,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  const SizedBox(height: 16),
                ],

                // ── Optional Media Carousel ──
                if (_mediaLoading)
                  Container(
                    height: 180,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFFC9921A),
                          ),
                        ),
                      ),
                    ),
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
                    onPressed:
                        _donating || widget.availablePoints <= 0
                            ? null
                            : _processDonation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.navImpact,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _donating
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFC9921A),
                                ),
                              ),
                            )
                            : Text(
                              'Donate & Earn Reward',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

  const _AmountPill(
    this.amount,
    this.selected,
    this.max,
    this.onTap, {
    this.isMax = false,
  });

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
            color:
                isSelected
                    ? _C.navImpact
                    : (isDisabled ? Colors.grey.shade100 : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? _C.navImpact
                      : (isDisabled ? Colors.grey.shade200 : _C.border),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              isMax ? 'MAX' : '$amount',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color:
                    isSelected
                        ? Colors.white
                        : (isDisabled ? Colors.grey.shade400 : _C.text),
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
  @override
  State<_RankingSheet> createState() => _RankingSheetState();
}

class _RankingSheetState extends State<_RankingSheet> {
  List<Map<String, dynamic>> _leaders = [];
  int _myRank = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Supabase.instance.client
          .from('leaderboard_global_v2')
          .select()
          .limit(100);
      _leaders = List<Map<String, dynamic>>.from(res);
      _myRank = _leaders.indexWhere((p) => p['id'] == widget.currentUserId) + 1;
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
      builder:
          (ctx, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Handle + header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Y4.primaryDeep, Y4.primary],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(child: NoorIcon.trophy(size: 22)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Leaderboard',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: _C.text,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)?.topContribByLifetimeSeeds ?? 'Top contributors by lifetime Seeds',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: _C.sub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: Colors.grey.shade100),

                Expanded(
                  child:
                      _loading
                          ? NoorInlineLoader(
                            height: double.infinity,
                            color: _C.navRanking,
                            label: AppLocalizations.of(context)?.loading ??
                                'Loading…',
                          )
                          : ListView(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                            children: [
                              // My rank hero card
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Y4.butter, Y4.honey],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Y4.honeyDeep.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    NoorIcon.medal(size: 40),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Your Rank: #$_myRank',
                                            style: GoogleFonts.outfit(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: Y4.ink,
                                            ),
                                          ),
                                          Text(
                                            'Out of ${_leaders.length} believers',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: Y4.inkSoft,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              Text(
                                AppLocalizations.of(context)
                                        ?.top10Contributors ??
                                    'Top 10 Contributors',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _C.text,
                                ),
                              ),
                              const SizedBox(height: 12),

                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: const Color(0xFFF0F0F5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: List.generate(_leaders.take(10).length, (
                                    i,
                                  ) {
                                    final p = _leaders[i];
                                    final isMe =
                                        p['id'] == widget.currentUserId;
                                    final badgeColors = [
                                      [Y4.butter, Y4.honey],
                                      [
                                        const Color(0xFFB0BEC5),
                                        const Color(0xFF78909C),
                                      ],
                                      [
                                        const Color(0xFFCD7F32),
                                        const Color(0xFFA0522D),
                                      ],
                                    ];
                                    final isTop3 = i < 3;
                                    final badgeGrad =
                                        isTop3
                                            ? badgeColors[i]
                                            : [
                                              _C.teal,
                                              const Color(0xFF1A9E8C),
                                            ];
                                    final pts =
                                        (p['total_xp'] as num?)?.toInt() ?? 0;
                                    final lv =
                                        (p['level'] as num?)?.toInt() ?? 1;
                                    final title =
                                        (p['level_title'] as String?) ??
                                        'Seeker';
                                    final nm =
                                        (p['display_name'] as String?)
                                            ?.split(' ')
                                            .first ??
                                        'User';
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isMe
                                                ? const Color(0xFFFFF3D4)
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(22),
                                        border:
                                            i < _leaders.take(10).length - 1
                                                ? const Border(
                                                  bottom: BorderSide(
                                                    color: Color(0xFFF5F5F5),
                                                  ),
                                                )
                                                : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: badgeGrad,
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: badgeGrad.last
                                                      .withValues(alpha: 0.35),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${i + 1}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  color: isTop3
                                                      ? Y4.ink
                                                      : Colors.white,
                                                  height: 1.0,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  isMe ? '$nm (you)' : nm,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: _C.text,
                                                  ),
                                                ),
                                                Text(
                                                  '$title • Lv $lv',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 11,
                                                    color: _C.sub,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '$pts ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: _C.navRanking,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                ),
              ],
            ),
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
  final VoidCallback onRefresh;
  const _ProfileTab({
    required this.name,
    required this.noorPoints,
    required this.totalXp,
    required this.level,
    required this.levelTitle,
    required this.country,
    required this.streak,
    required this.currentUserId,
    this.avatarUrl,
    required this.onRefresh,
  });
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  List<Map<String, dynamic>> _leaders = [];
  int _myRank = 0;
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
      // Fire both queries in parallel — total time = max(t1,t2) not t1+t2
      final results = await Future.wait([
        // Query 1: top 10 contributors (v2 = filtered view, no merged dupes)
        Supabase.instance.client
            .from('leaderboard_global_v2')
            .select()
            .order('total_xp', ascending: false)
            .limit(10),
        // Query 2: my own row. If my auth.uid() row got merged into a
        // canonical (cross-method dedup), the v2 view hides me — fall
        // back to reading from `profiles` directly and follow
        // merged_into_id to the canonical.
        Supabase.instance.client
            .from('profiles')
            .select('total_xp, merged_into_id')
            .eq('id', widget.currentUserId)
            .maybeSingle(),
      ]);

      _leaders = List<Map<String, dynamic>>.from(results[0] as List);
      final myRow = results[1] as Map<String, dynamic>?;
      final myXp = (myRow?['total_xp'] as num?)?.toInt() ?? 0;
      // If this user's auth.uid() row was merged into a canonical, follow
      // the pointer so rank / XP reflect the consolidated identity.
      // (Not strictly needed for rank math, but keeps display consistent.)
      final canonicalId =
          (myRow?['merged_into_id'] as String?) ?? widget.currentUserId;

      // Rank within top-10: count how many have more Seeds than me + 1
      final posInTop10 = _leaders.indexWhere(
        (p) => p['id'] == widget.currentUserId || p['id'] == canonicalId,
      );
      if (posInTop10 >= 0) {
        _myRank = posInTop10 + 1;
      } else {
        // Not in top 10 — count how many top-10 members beat my Seeds total
        final beatenBy =
            _leaders
                .where((p) => ((p['total_xp'] as num?)?.toInt() ?? 0) > myXp)
                .length;
        _myRank = beatenBy + 1;
      }
    } catch (_) {}
    if (mounted) setState(() => _lbLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final first = widget.name.split(' ').first;
    final name = widget.name;
    final country = widget.country;
    final level = widget.level;
    final levelTitle = widget.levelTitle;
    final streak = widget.streak;
    final avatarUrl = widget.avatarUrl;
    final statusBarH = MediaQuery.of(context).padding.top;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile header — honey wash hero matching dashboard ──────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Y4.cream, Y4.honey.withValues(alpha: 0.30), Y4.bg],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Decorative arc circles (subtle honey/sage on light bg)
                  Positioned(
                    top: -40,
                    right: -40,
                    child: _ProfileArc(180, Y4.honey.withValues(alpha: 0.18)),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -30,
                    child: _ProfileArc(130, Y4.primary.withValues(alpha: 0.08)),
                  ),
                  Positioned(
                    top: 40,
                    right: 40,
                    child: _ProfileArc(
                      70,
                      Y4.honeyDeep.withValues(alpha: 0.10),
                    ),
                  ),
                  Positioned(
                    top: -10,
                    left: 60,
                    child: _ProfileArc(
                      50,
                      Y4.primaryDeep.withValues(alpha: 0.06),
                    ),
                  ),

                  // Content — padded below status bar
                  Padding(
                    padding: EdgeInsets.fromLTRB(22, statusBarH + 12, 22, 20),
                    child: Column(
                      children: [
                        // Top row: Back button + "My Profile" title + level pill + settings
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              behavior: HitTestBehavior.opaque,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: Y4.ink,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Level pill — solid honey gradient with white
                            // text. Takes whatever horizontal room is left
                            // after the back arrow + settings button.
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Y4.honey, Y4.honeyDeep],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Y4.honeyDeep.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.workspace_premium_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Lvl $level · ${_localizeLevel(context, levelTitle)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Settings button
                            GestureDetector(
                              onTap: () => _openSettings(context),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Y4.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Y4.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Y4.ink.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.settings_rounded,
                                  color: Y4.ink,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Avatar (honey gradient circle) — compacted
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Y4.honey, Y4.honeyDeep],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(color: Y4.surface, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Y4.honeyDeep.withValues(alpha: 0.30),
                                    blurRadius: 24,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                                image:
                                    avatarUrl != null
                                        ? DecorationImage(
                                          image: NetworkImage(avatarUrl),
                                          fit: BoxFit.cover,
                                        )
                                        : null,
                              ),
                              child:
                                  avatarUrl == null
                                      ? Center(
                                        child: Text(
                                          first.isNotEmpty
                                              ? first[0].toUpperCase()
                                              : 'N',
                                          style: GoogleFonts.outfit(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: Y4.ink,
                                          ),
                                        ),
                                      )
                                      : null,
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Name (Fraunces serif) — compacted from 28 → 20
                        Text(
                          name,
                          style: Y4.display(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Y4.ink,
                            letterSpacing: -0.2,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // Email / Country
                        if ((user?.email ?? user?.userMetadata?['qf_email']) !=
                            null)
                          Text(
                            (user?.email ?? user?.userMetadata?['qf_email'])
                                    as String? ??
                                '',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Y4.inkSoft,
                            ),
                          ),
                        if (country != null && country.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.public_rounded,
                                size: 12,
                                color: Y4.muted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                country,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Y4.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body — warm beige background matching the rest of the app ──────
            Container(
              color: _C.bg,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: Column(
                  children: [
                    // ── Community Leaderboard — inline card ─────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _C.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Y4.primaryDeep, Y4.primary],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: NoorIcon.trophy(size: 20),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                              context,
                                            )?.communityLeaderboard ??
                                            'Community Leaderboard',
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: _C.text,
                                        ),
                                      ),
                                      Text(
                                        AppLocalizations.of(
                                              context,
                                            )?.topContributors ??
                                            AppLocalizations.of(context)?.topContribByLifetimeSeeds ?? 'Top contributors by lifetime Seeds',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: _C.sub,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // My rank hero — honey theme
                          if (!_lbLoading)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Y4.butter, Y4.honey, Y4.honeyDeep],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Y4.honeyDeep.withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    NoorIcon.medal(size: 36),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Your Rank: #$_myRank',
                                            style: GoogleFonts.outfit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Y4.ink,
                                            ),
                                          ),
                                          Text(
                                            'Out of ${_leaders.length} believers',
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              color: Y4.ink.withValues(alpha: 0.70),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Loading indicator — fixed height to prevent layout shift
                          if (_lbLoading)
                            const SizedBox(
                              height: 80,
                              child: Center(child: NoorInlineLoader()),
                            ),

                          // Top 10 list
                          if (!_lbLoading && _leaders.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                              child: Text(
                                AppLocalizations.of(context)
                                        ?.top10Contributors ??
                                    'Top 10 Contributors',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _C.sub,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            ...List.generate(_leaders.take(10).length, (i) {
                              final p = _leaders[i];
                              final isMe = p['id'] == widget.currentUserId;
                              final isTop3 = i < 3;
                              final badgeColors = [
                                [Y4.butter, Y4.honey],
                                [
                                  const Color(0xFFB0BEC5),
                                  const Color(0xFF78909C),
                                ],
                                [
                                  const Color(0xFFCD7F32),
                                  const Color(0xFFA0522D),
                                ],
                              ];
                              final badgeGrad =
                                  isTop3
                                      ? badgeColors[i]
                                      : [_C.teal, const Color(0xFF1A9E8C)];
                              final pts = (p['total_xp'] as num?)?.toInt() ?? 0;
                              final lv = (p['level'] as num?)?.toInt() ?? 1;
                              final title = _localizeLevel(
                                context,
                                p['level_title'] as String?,
                              );
                              final nm =
                                  (p['display_name'] as String?)
                                      ?.split(' ')
                                      .first ??
                                  'User';
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isMe
                                          ? const Color(0xFFFFF3D4)
                                          : Colors.transparent,
                                  borderRadius:
                                      i == _leaders.take(10).length - 1
                                          ? const BorderRadius.vertical(
                                            bottom: Radius.circular(22),
                                          )
                                          : BorderRadius.zero,
                                  border:
                                      i < _leaders.take(10).length - 1
                                          ? const Border(
                                            bottom: BorderSide(
                                              color: Color(0xFFF5F5F5),
                                            ),
                                          )
                                          : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: badgeGrad,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: badgeGrad.last.withValues(
                                              alpha: 0.35,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: isTop3 ? Y4.ink : Colors.white,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isMe ? '$nm (you)' : nm,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: _C.text,
                                            ),
                                          ),
                                          Text(
                                            '$title • Lv $lv',
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              color: _C.sub,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '$pts ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _C.navRanking,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Streak card — warm beige with amber/teal accents
                    GestureDetector(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LevelScreen(),
                            ),
                          ),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _C.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: _C.amber.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _C.amber.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Center(child: NoorIcon.fire(size: 26)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    streak > 0
                                        ? (AppLocalizations.of(context)
                                                ?.dayStreakCount(streak) ??
                                            '$streak Day Streak 🔥')
                                        : (AppLocalizations.of(context)
                                                ?.startStreakToday ??
                                            'Start your streak today!'),
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: streak > 0 ? _C.amber : _C.sub,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Text(
                                    AppLocalizations.of(context)?.navJourney ??
                                        'Tap to view your Journey',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: _C.sub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 15,
                              color: streak > 0 ? _C.amber : _C.sub,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    width: size,
    height: size,
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
    // Each item carries its real tab index (0-3) so hiding a tab never
    // shifts the others. Home is always present; the rest are gated by
    // FeatureFlags. Tuple: (realIndex, filledIcon, outlineIcon, label, color).
    final navItems = <(int, IconData, IconData, String, Color)>[
      (
        0,
        Icons.home_rounded,
        Icons.home_outlined,
        AppLocalizations.of(context)?.navHome ?? 'Home',
        _C.navHome,
      ),
      if (FeatureFlags.causeTab)
        (
          1,
          Icons.volunteer_activism_rounded,
          Icons.volunteer_activism_outlined,
          AppLocalizations.of(context)?.navCause ?? 'Cause',
          _C.navRanking,
        ),
      if (FeatureFlags.journeyTab)
        (
          2,
          Icons.trending_up_rounded,
          Icons.trending_up_outlined,
          AppLocalizations.of(context)?.navJourney ?? 'Journey',
          _C.navRanking,
        ),
      if (FeatureFlags.akhirahTab)
        (
          3,
          Icons.mosque_rounded,
          Icons.mosque_outlined,
          AppLocalizations.of(context)?.navAkhirah ?? 'Akhirah',
          _C.navImpact,
        ),
    ];
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 72 + bottomPad,
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: navItems.map((item) {
          final (realIndex, filled, outline, label, color) = item;
          final sel = realIndex == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(realIndex),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    sel ? filled : outline,
                    size: 26,
                    color: sel ? color : const Color(0xFFBBBBBB),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel ? color : const Color(0xFFBBBBBB),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swipe-to-Validate  ✦  "Circuit Connect" Edition
// Drag the crescent orb into the receptor socket to seal the day.
// ─────────────────────────────────────────────────────────────────────────────

// ── Energy particle behind the dragging orb ───────────────────────────────────
class _EnergyParticle {
  double x, y; // position relative to track
  double vx, vy; // velocity
  double life; // 1.0 → 0.0
  final double size;
  final Color color;
  _EnergyParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
  }) : life = 1.0;
}

// ── Arc segments painter (lightning bolt between orb and socket) ──────────────
class _ArcPainter extends CustomPainter {
  final double fromX, toX, cy;
  final double progress; // 0–1, drives opacity
  final Color color;
  const _ArcPainter({
    required this.fromX,
    required this.toX,
    required this.cy,
    required this.progress,
    required this.color,
  });
  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rng = math.Random(7);
    final paint =
        Paint()
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
    final glowPaint =
        Paint()
          ..color = color.withValues(alpha: progress * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(fromX, cy), 8 * progress, glowPaint);
    canvas.drawCircle(Offset(toX, cy), 10 * progress, glowPaint);
  }

  @override
  bool shouldRepaint(_ArcPainter o) =>
      o.progress != progress || o.fromX != fromX;
}

// ── Main widget ───────────────────────────────────────────────────────────────
class _SwipeValidateButton extends StatefulWidget {
  final Future<bool> Function() onValidate;
  final int pendingPoints;
  const _SwipeValidateButton({
    required this.onValidate,
    this.pendingPoints = 0,
  });
  @override
  State<_SwipeValidateButton> createState() => _SwipeValidateButtonState();
}

class _SwipeValidateButtonState extends State<_SwipeValidateButton>
    with TickerProviderStateMixin {
  // ── Geometry ─────────────────────────────────────────────────────────────
  static const double _trackH = 68.0;
  static const double _thumbSize = 56.0;
  static const double _padding = 6.0;

  // ── State ──────────────────────────────────────────────────────────────
  double _drag = 0;
  bool _completed = false;
  bool _resetting = false;
  bool _freshXp = true;
  bool _dragging = false;

  // Particles
  final List<_EnergyParticle> _particles = [];
  final _rng = math.Random();

  // ── Colors — Y4 honey/butter palette (matches activity cards) ──────
  static const _neonGreen = Y4.honey; // primary track / arc color
  static const _neonGold = Y4.butter; // accent on completion
  static const _socketRing = Y4.butter; // bright butter ring

  static const _sparkPalette = [
    Y4.honey,
    Y4.butter,
    Y4.honeyDeep,
    Y4.amberY,
    Color(0xFFFFFFFF),
  ];

  // ── Controllers ──────────────────────────────────────────────────────
  // Particle / trail ticker
  late AnimationController _particleCtrl;

  // Socket pulse (proximity-driven speed)
  late AnimationController _socketCtrl;
  late Animation<double> _socketPulse;

  // Arc flash on connect
  late AnimationController _arcCtrl;
  late Animation<double> _arcAnim;

  // Completion burst
  late AnimationController _burstCtrl;
  late Animation<double> _burstAnim;

  // Merged emblem scale-bounce
  late AnimationController _snapCtrl;
  late Animation<double> _snapScale;

  // Halo rotation
  late AnimationController _haloCtrl;

  // Circuit fill (golden wash left→right after connect)
  late AnimationController _fillCtrl;
  late Animation<double> _fillAnim;

  // Idle shimmer on text
  late AnimationController _shimmerCtrl;

  // Pending-pill: drop-in from above + slow glow pulse.
  late AnimationController _pendingDropCtrl;
  late Animation<double> _pendingDropAnim;
  late AnimationController _pendingPulseCtrl;
  late Animation<double> _pendingPulseAnim;

  @override
  void initState() {
    super.initState();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
    _particleCtrl.addListener(_tickParticles);

    _socketCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _socketPulse = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _socketCtrl, curve: Curves.easeInOut));

    _arcCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _arcAnim = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOut));

    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _burstAnim = CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOut);

    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _snapScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.90), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.00), weight: 15),
    ]).animate(CurvedAnimation(parent: _snapCtrl, curve: Curves.linear));

    _haloCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _fillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fillAnim = CurvedAnimation(parent: _fillCtrl, curve: Curves.easeOut);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pendingDropCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _pendingDropAnim = CurvedAnimation(
      parent: _pendingDropCtrl,
      curve: Curves.elasticOut,
    );
    _pendingPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pendingPulseAnim = CurvedAnimation(
      parent: _pendingPulseCtrl,
      curve: Curves.easeInOut,
    );
    if (widget.pendingPoints > 0) {
      Future.delayed(const Duration(milliseconds: 240), () {
        if (mounted) _pendingDropCtrl.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(_SwipeValidateButton old) {
    super.didUpdateWidget(old);
    // Re-drop the pill whenever pending transitions from 0 to a positive
    // value (e.g. user just earned new seeds and returned to the dashboard).
    if (old.pendingPoints <= 0 && widget.pendingPoints > 0) {
      _pendingDropCtrl.forward(from: 0);
    }
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
    _pendingDropCtrl.dispose();
    _pendingPulseCtrl.dispose();
    super.dispose();
  }

  // ── Particle tick ─────────────────────────────────────────────────────
  void _tickParticles() {
    if (!mounted) return;
    setState(() {
      for (final p in _particles) {
        p.x += p.vx;
        p.y += p.vy;
        p.life -= 0.045;
        p.vx *= 0.94;
        p.vy *= 0.94;
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
      _particles.add(
        _EnergyParticle(
          x: knobCx + (_rng.nextDouble() - 0.5) * 10,
          y: cy + (_rng.nextDouble() - 0.5) * 10,
          vx: math.cos(angle) * speed - 0.5, // slight leftward drift
          vy: math.sin(angle) * speed * 0.55,
          size: 1.8 + _rng.nextDouble() * 2.2,
          color: _sparkPalette[_rng.nextInt(_sparkPalette.length)],
        ),
      );
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
    setState(() {
      _dragging = false;
      _resetting = true;
    });
    _resetKnob(maxDrag);
  }

  Future<void> _resetKnob(double maxDrag) async {
    for (double t = _drag; t > 0; t -= 11) {
      if (!mounted) return;
      setState(() => _drag = t.clamp(0.0, maxDrag));
      await Future.delayed(const Duration(milliseconds: 9));
    }
    if (mounted)
      setState(() {
        _drag = 0;
        _resetting = false;
        _particles.clear();
      });
  }

  void _complete(double maxDrag) {
    // Snapshot pending NOW — `claimValidate()` zeroes XpService's pending
    // counter before our `.then` callback runs, so reading
    // `widget.pendingPoints` later would always be 0 and skip the
    // celebration animation.
    final pendingAtSwipe = widget.pendingPoints;
    setState(() {
      _drag = maxDrag;
      _completed = true;
      _dragging = false;
    });
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
      // Sabiq Seed celebration — spin the coins, then fly them into the
      // Garden hero card so the sealed Seeds visibly land in the garden
      // (and the balance counts up). Best-effort; never blocks the
      // existing burst/snap/fill animation.
      if (awarded && pendingAtSwipe > 0) {
        // Resolve the garden coin's centre in global screen coordinates
        // so the coins land exactly on it.
        Offset? target;
        final box = gardenSeedKey.currentContext
            ?.findRenderObject() as RenderBox?;
        if (box != null && box.attached) {
          target = box.localToGlobal(box.size.center(Offset.zero));
        }
        playSealCoinAnimation(
          context,
          pointsSealed: pendingAtSwipe,
          targetPosition: target,
        );
      }
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
            _drag = 0;
            _completed = false;
            _freshXp = true;
            _particles.clear();
          });
        }
      });
    });
  }

  // ── Seal-track countdown ─────────────────────────────────────────────
  // Returns the full inline prompt: "Seal within 2h" / "Seal within 45m" /
  // "Seal now".
  String _sealCountdownText() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final diff = nextMidnight.difference(now);
    final l = AppLocalizations.of(context);
    if (diff.inHours >= 1) {
      return l?.sealWithinHours(diff.inHours) ?? 'Seal within ${diff.inHours}h';
    }
    if (diff.inMinutes >= 1) {
      return l?.sealWithinMinutes(diff.inMinutes) ??
          'Seal within ${diff.inMinutes}m';
    }
    return l?.sealNow ?? 'Seal now';
  }

  // Builds a single chevron with the staggered pulse-wave animation that
  // travels through all three chevrons in sequence.
  Widget _buildTrackChevron(int index, {double size = 40}) {
    // 3 chevrons stagger evenly across the wave cycle.
    final d = (_haloCtrl.value - index * 0.22) % 1.0;
    final wave = d < 0.45 ? (1 - d / 0.45) : 0.0;
    return Icon(
      Icons.keyboard_double_arrow_right_rounded,
      size: size,
      color: const Color(0xFFFAF3E3).withValues(
        alpha: 0.40 + wave * 0.55,
      ),
    );
  }

  // ── Pending-seeds pill (drops in above the seal track) ──────────────
  // Shares the emerald gradient with the seal slider so the eye reads them
  // as one component — the seeds the user is about to lock in, and the
  // action that locks them in. Hidden while the seal animation plays.
  Widget _buildPendingPill() {
    final pending = widget.pendingPoints;
    if (pending <= 0 || _completed) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: Listenable.merge([_pendingDropAnim, _pendingPulseAnim]),
      builder: (_, __) {
        final t = _pendingDropAnim.value.clamp(0.0, 1.0);
        final pulse = _pendingPulseAnim.value; // 0..1
        // Slide down from -22px with the elastic curve already applied.
        final dy = (1 - t) * -22;
        final fade = (_pendingDropAnim.value * 1.4).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Center(
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Opacity(
                opacity: fade,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A9B8E), Color(0xFF1F4F3D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Y4.butter.withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1F4F3D).withValues(alpha: 0.32),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Y4.honey.withValues(
                          alpha: 0.22 + 0.18 * pulse,
                        ),
                        blurRadius: 16 + 6 * pulse,
                        spreadRadius: 0.5 + 1.0 * pulse,
                      ),
                    ],
                  ),
                  // FittedBox auto-shrinks the whole pill when the localized
                  // text is wider than English (Urdu / Arabic / Russian),
                  // preventing horizontal overflow on narrow phones.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bright butter-coin badge — pops against emerald.
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Y4.butter, Y4.honey],
                            radius: 0.85,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Y4.honey.withValues(
                                alpha: 0.55 + 0.25 * pulse,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          '+',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Y4.ink,
                            height: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        AppLocalizations.of(context)
                                ?.seedsPendingCount(pending) ??
                            '$pending ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'} pending',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Y4.butter,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 14,
                        color: Y4.butter.withValues(alpha: 0.35),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)?.sealToSave ??
                            'Seal to save',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Y4.butter.withValues(alpha: 0.88),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Subtle bobbing chevron — visually points to the
                      // seal slider directly below.
                      Transform.translate(
                        offset: Offset(0, 1 + 1.5 * pulse),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Y4.butter,
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const radius = _trackH / 2;

    return LayoutBuilder(
      builder: (_, box) {
        final maxDrag = box.maxWidth - _thumbSize - _padding * 2;
        final pct = maxDrag > 0 ? (_drag / maxDrag).clamp(0.0, 1.0) : 0.0;
        final knobCx = _padding + _drag + _thumbSize / 2;
        final socketCx =
            box.maxWidth - _padding - _thumbSize / 2; // right socket centre
        final trackCy = _trackH / 2;
        final proximity = pct; // 0 = far, 1 = touching

        return AnimatedBuilder(
          animation: Listenable.merge([
            _socketPulse,
            _arcAnim,
            _burstAnim,
            _snapScale,
            _haloCtrl,
            _fillAnim,
            _shimmerCtrl,
            _particleCtrl,
          ]),
          builder: (_, __) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPendingPill(),
                GestureDetector(
              onHorizontalDragStart: _onPanStart,
              onHorizontalDragUpdate: (d) => _onPanUpdate(d, maxDrag),
              onHorizontalDragEnd: (_) => _onPanEnd(maxDrag),
              child: SizedBox(
                height: _trackH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Track background — emerald (so the pill pops off
                    // the honey-wash dashboard and matches the seed coin's
                    // emerald inner disc).
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF53A99B), // light emerald
                              Color(0xFF4A9B8E), // emerald — kept light so the
                              // right end stays as bright as the left
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(radius),
                          border: Border.all(
                            color: const Color(0xFF2E6B62).withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1F4F3D).withValues(alpha: 0.30),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Standalone arrows row removed — chevrons are now
                    // inline with the label below to avoid overlap.


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
                                      const Color(
                                        0xFFFFD166,
                                      ).withValues(alpha: 0.25),
                                      const Color(
                                        0xFFFF9F1C,
                                      ).withValues(alpha: 0.15),
                                      const Color(
                                        0xFF00FFA3,
                                      ).withValues(alpha: 0.20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ── Progress fill (butter → bright amber → honey on full) ──
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: (_thumbSize + _padding + _drag).clamp(
                          0.0,
                          box.maxWidth,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.25),
                              Colors.white.withValues(alpha: 0.10),
                              Colors.white.withValues(alpha: 0.05),
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

                    // ── Centre label with inline chevrons ────────────────
                    // Row: › Swipe › Seal before 2h ›
                    // Chevrons act as rhythm markers around the text — they
                    // are never under or behind it. FittedBox auto-shrinks
                    // the whole row on narrow phones.
                    if (!_completed)
                      Positioned(
                        left: _padding + _thumbSize + 4,
                        right: _padding + _thumbSize + 4,
                        top: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: (1 - pct * 2.2).clamp(0.0, 1.0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                children: [
                                  _buildTrackChevron(0),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _sealCountdownText(),
                                        maxLines: 1,
                                        style: GoogleFonts.rajdhani(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFFAF3E3),
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _buildTrackChevron(2),
                                ],
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
                              ? (XpService.instance.lastSealAwardedBonus
                                    ? (AppLocalizations.of(context)
                                            ?.jazakAllahPlusSeeds(
                                              PointReward.validate,
                                            ) ??
                                        'JazakAllah!  +${PointReward.validate} ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}')
                                    : (AppLocalizations.of(context)
                                            ?.jazakAllahDaySealed ??
                                        'JazakAllah!  Day sealed'))
                              : (AppLocalizations.of(context)?.alreadySealed ??
                                  'Already sealed today'),
                          style: GoogleFonts.rajdhani(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: _freshXp ? _neonGold : Colors.white,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),

                    // ── Lightning arc flash ───────────────────────────────
                    // Note: the knob-to-socket connecting arc was removed
                    // per design — only the localized socket flash on
                    // completion remains below.
                    if (_arcAnim.value > 0 && _completed)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(radius),
                          child: CustomPaint(
                            painter: _ArcPainter(
                              fromX: socketCx - 20,
                              toX: socketCx + 20,
                              cy: trackCy,
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
                  ],
                ),
              ),
            ),
              ],
            );
          },
        );
      },
    );
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
    required this.size,
    required this.pulse,
    required this.proximity,
    required this.neonGreen,
    required this.socketRing,
  });
  @override
  Widget build(BuildContext context) {
    final glowAlpha = (0.15 + pulse * 0.5 * proximity).clamp(0.0, 0.9);
    final ringScale = 1.0 + pulse * 0.18 * proximity;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
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
            // Ring border + cream fill so the socket reads as the bright
            // goal at the end of the track. The brown-stemmed green
            // seedling icon contrasts cleanly against the cream.
            Container(
              width: size - 6,
              height: size - 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFFFAE3), // cream
                    Color(0xFFF4E4B8), // warm cream edge
                  ],
                ),
                border: Border.all(
                  color: socketRing.withValues(alpha: 0.55 + proximity * 0.35),
                  width: 1.5,
                ),
              ),
            ),
            // Inner ring — butter accent so the socket still reads as the
            // golden goal at the end of the track.
            Container(
              width: size - 18,
              height: size - 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: socketRing.withValues(alpha: 0.25 + proximity * 0.45),
                  width: 1,
                ),
              ),
            ),
            // The S coin (seed) sits on the left socket; this end shows
            // the seedling sprouting from it — completing the "seed →
            // sprout" metaphor as the user seals the day. Sized up from
            // 20 → 26 to read at a glance against the dark soil fill.
            NoorIcon.seedling(size: 26),
          ],
        ),
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
    required this.size,
    required this.pct,
    required this.completed,
    required this.snapScale,
    required this.burstProgress,
    required this.haloAngle,
    required this.freshXp,
    required this.neonGreen,
    required this.neonGold,
  });

  @override
  Widget build(BuildContext context) {
    final orbColor =
        Color.lerp(
          const Color(0xFFE8A020),
          const Color(0xFFFFEE66),
          pct * pct,
        )!;
    final glowColor =
        completed
            ? (freshXp ? neonGold : neonGreen)
            : Color.lerp(
              const Color(0xFFFFB300),
              const Color(0xFFFFEE44),
              pct,
            )!;
    final glowAlpha = completed ? 0.80 : (0.30 + pct * 0.65);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
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

          // ── Orb body (Sabiq Seed coin) ────────────────────────────────
          Transform.scale(
            scale: snapScale,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x4D000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Color(0x80FFFFFF),
                    blurRadius: 4,
                    offset: Offset(-1, -2),
                  ),
                ],
              ),
              child: completed && !freshXp
                  ? Center(child: NoorIcon.check(size: size * 0.55))
                  : SabiqCoin(size: size, sprouting: completed && freshXp),
            ),
          ),

          // ── Burst sparks (radial explosion on connect) ─────────────────
          if (burstProgress > 0)
            ...List.generate(16, (i) {
              final angle = (i / 16.0) * math.pi * 2;
              final r1 = burstProgress * (i.isEven ? 46.0 : 30.0);
              final opacity = (1 - burstProgress * 1.1).clamp(0.0, 1.0);
              final colors = [
                neonGold,
                neonGreen,
                Colors.white,
                neonGold,
                const Color(0xFF39FFD6),
                Colors.white,
              ];
              return Transform.translate(
                offset: Offset(r1 * math.cos(angle), r1 * math.sin(angle)),
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
                          color: colors[i % colors.length].withValues(
                            alpha: 0.7,
                          ),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Y4 — HONEY + SAGE GARDEN WIDGETS
// Custom painters that recreate the SVG plant / sun / arc graphics used in the
// Y4 dashboard design (Copy of Sabiq Rewards V1).
// ═════════════════════════════════════════════════════════════════════════════

/// A small potted plant — used in the hero garden floor.
/// `grow` ranges 0..1; controls stem height, leaf count, and bloom presence.
class _Y4Plant extends StatelessWidget {
  final double grow;
  final double size;
  const _Y4Plant({required this.grow, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _Y4PlantPainter(grow: grow)),
    );
  }
}

class _Y4PlantPainter extends CustomPainter {
  final double grow;
  const _Y4PlantPainter({required this.grow});

  @override
  void paint(Canvas canvas, Size s) {
    final scale = s.width / 64.0;
    Offset p(double x, double y) => Offset(x * scale, y * scale);

    final leaves = (grow * 4).ceil().clamp(0, 4);

    // Pot trapezoid (16,48 -> 48,48 -> 44,60 -> 20,60)
    final potPath =
        Path()
          ..moveTo(p(16, 48).dx, p(16, 48).dy)
          ..lineTo(p(48, 48).dx, p(48, 48).dy)
          ..lineTo(p(44, 60).dx, p(44, 60).dy)
          ..lineTo(p(20, 60).dx, p(20, 60).dy)
          ..close();
    canvas.drawPath(
      potPath,
      Paint()
        ..color = Y4.soil
        ..style = PaintingStyle.fill,
    );

    // Pot rim ellipse cx=32 cy=48 rx=16 ry=3
    canvas.drawOval(
      Rect.fromCenter(center: p(32, 48), width: 32 * scale, height: 6 * scale),
      Paint()
        ..color = Y4.soilDeep
        ..style = PaintingStyle.fill,
    );

    // Stem M32 48 Q32 (48-grow*30) 32 (30-grow*10)
    final stem =
        Path()
          ..moveTo(p(32, 48).dx, p(32, 48).dy)
          ..quadraticBezierTo(
            p(32, 48 - grow * 30).dx,
            p(32, 48 - grow * 30).dy,
            p(32, 30 - grow * 10).dx,
            p(32, 30 - grow * 10).dy,
          );
    canvas.drawPath(
      stem,
      Paint()
        ..color = Y4.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Leaves (drawn progressively as grow increases)
    Paint sageFill =
        Paint()
          ..color = Y4.primary
          ..style = PaintingStyle.fill;
    Paint sageDeepFill =
        Paint()
          ..color = Y4.primaryDeep
          ..style = PaintingStyle.fill;

    if (leaves >= 1) {
      // M32 40 Q24 36 22 30 Q28 30 32 38
      final leaf1 =
          Path()
            ..moveTo(p(32, 40).dx, p(32, 40).dy)
            ..quadraticBezierTo(
              p(24, 36).dx,
              p(24, 36).dy,
              p(22, 30).dx,
              p(22, 30).dy,
            )
            ..quadraticBezierTo(
              p(28, 30).dx,
              p(28, 30).dy,
              p(32, 38).dx,
              p(32, 38).dy,
            )
            ..close();
      canvas.drawPath(leaf1, sageFill);
    }
    if (leaves >= 2) {
      final leaf2 =
          Path()
            ..moveTo(p(32, 36).dx, p(32, 36).dy)
            ..quadraticBezierTo(
              p(40, 32).dx,
              p(40, 32).dy,
              p(42, 26).dx,
              p(42, 26).dy,
            )
            ..quadraticBezierTo(
              p(36, 26).dx,
              p(36, 26).dy,
              p(32, 34).dx,
              p(32, 34).dy,
            )
            ..close();
      canvas.drawPath(leaf2, sageFill);
    }
    if (leaves >= 3) {
      final leaf3 =
          Path()
            ..moveTo(p(32, 28).dx, p(32, 28).dy)
            ..quadraticBezierTo(
              p(26, 24).dx,
              p(26, 24).dy,
              p(24, 18).dx,
              p(24, 18).dy,
            )
            ..quadraticBezierTo(
              p(30, 18).dx,
              p(30, 18).dy,
              p(32, 26).dx,
              p(32, 26).dy,
            )
            ..close();
      canvas.drawPath(leaf3, sageDeepFill);
    }
    if (leaves >= 4) {
      // Honey bloom circle cx=32 cy=20 r=5
      canvas.drawCircle(
        p(32, 20),
        5 * scale,
        Paint()
          ..color = Y4.honey
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_Y4PlantPainter old) => old.grow != grow;
}

/// A miniature streak-day plant. State: `done` (filled past day),
/// `today` (in progress), `future` (empty soil only).
class _Y4StreakPlant extends StatelessWidget {
  final bool done;
  final bool today;
  const _Y4StreakPlant({this.done = false, this.today = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 28,
      child: CustomPaint(
        painter: _Y4StreakPlantPainter(done: done, today: today),
      ),
    );
  }
}

class _Y4StreakPlantPainter extends CustomPainter {
  final bool done;
  final bool today;
  const _Y4StreakPlantPainter({required this.done, required this.today});

  @override
  void paint(Canvas canvas, Size s) {
    final sx = s.width / 24.0;
    final sy = s.height / 28.0;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    // Soil base rect x=4 y=22 w=16 h=5 rx=1
    final soilColor = done ? Y4.soil : Y4.track;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(p(4, 22).dx, p(4, 22).dy, 16 * sx, 5 * sy),
        Radius.circular(1 * sx),
      ),
      Paint()
        ..color = soilColor
        ..style = PaintingStyle.fill,
    );

    if (done) {
      // Stem M12 22 Q12 14 12 10
      final stem =
          Path()
            ..moveTo(p(12, 22).dx, p(12, 22).dy)
            ..quadraticBezierTo(
              p(12, 14).dx,
              p(12, 14).dy,
              p(12, 10).dx,
              p(12, 10).dy,
            );
      canvas.drawPath(
        stem,
        Paint()
          ..color = Y4.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * sx,
      );

      // Left leaf M12 16 Q8 14 7 10 Q11 10 12 14
      final l1 =
          Path()
            ..moveTo(p(12, 16).dx, p(12, 16).dy)
            ..quadraticBezierTo(
              p(8, 14).dx,
              p(8, 14).dy,
              p(7, 10).dx,
              p(7, 10).dy,
            )
            ..quadraticBezierTo(
              p(11, 10).dx,
              p(11, 10).dy,
              p(12, 14).dx,
              p(12, 14).dy,
            )
            ..close();
      canvas.drawPath(
        l1,
        Paint()
          ..color = Y4.primary
          ..style = PaintingStyle.fill,
      );

      // Right leaf M12 14 Q16 12 17 8 Q13 8 12 12
      final l2 =
          Path()
            ..moveTo(p(12, 14).dx, p(12, 14).dy)
            ..quadraticBezierTo(
              p(16, 12).dx,
              p(16, 12).dy,
              p(17, 8).dx,
              p(17, 8).dy,
            )
            ..quadraticBezierTo(
              p(13, 8).dx,
              p(13, 8).dy,
              p(12, 12).dx,
              p(12, 12).dy,
            )
            ..close();
      canvas.drawPath(
        l2,
        Paint()
          ..color = Y4.primaryDeep
          ..style = PaintingStyle.fill,
      );
    } else if (today) {
      // Dashed honey-deep stem M12 22 L12 18
      final dash =
          Paint()
            ..color = Y4.honeyDeep
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 * sx
            ..strokeCap = StrokeCap.round;
      const dashLen = 1.5;
      const gap = 1.5;
      double y = 22;
      while (y > 18) {
        final yEnd = (y - dashLen).clamp(18.0, 22.0);
        canvas.drawLine(p(12, y), p(12, yEnd), dash);
        y -= dashLen + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_Y4StreakPlantPainter old) =>
      old.done != done || old.today != today;
}

/// The decorative honey sun used in the hero card.
class _Y4Sun extends StatelessWidget {
  final double size;
  const _Y4Sun({this.size = 44});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _Y4SunPainter()),
    );
  }
}

class _Y4SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final coreR = s.width * (12 / 44);
    final rayR = s.width * (20 / 44);

    final core =
        Paint()
          ..color = Y4.honey
          ..style = PaintingStyle.fill;
    canvas.drawCircle(c, coreR, core);

    final ray =
        Paint()
          ..color = Y4.honey.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * (2 / 44)
          ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final a = (i * 45) * math.pi / 180;
      canvas.drawLine(
        c,
        c + Offset(math.cos(a) * rayR, math.sin(a) * rayR),
        ray,
      );
    }
  }

  @override
  bool shouldRepaint(_Y4SunPainter _) => false;
}

/// Sun-arc progress: a 180° arc from left to right with a sun-circle that
/// travels along it as `pct` (0..1) increases.
class _Y4SunArc extends StatelessWidget {
  final double pct; // 0..1
  const _Y4SunArc({required this.pct});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 60,
      child: CustomPaint(painter: _Y4SunArcPainter(pct: pct.clamp(0.0, 1.0))),
    );
  }
}

class _Y4SunArcPainter extends CustomPainter {
  final double pct;
  const _Y4SunArcPainter({required this.pct});

  @override
  void paint(Canvas canvas, Size s) {
    // Arc geometry: center (50,55) radius 40, sweeping from 180° to 360° (top half)
    final center = Offset(s.width * 0.5, s.height * (55 / 60));
    final radius = s.width * (40 / 100);

    // Track
    final track =
        Paint()
          ..color = Y4.track
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      track,
    );

    // Filled portion
    final fill =
        Paint()
          ..color = Y4.honeyDeep
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * pct,
      false,
      fill,
    );

    // Travelling sun marker (matches Y4 jsx geometry)
    final ang = math.pi - pct * math.pi;
    final sunCx = center.dx + math.cos(ang) * radius;
    final sunCy = center.dy - math.sin(pct * math.pi) * radius;
    final sunPaint =
        Paint()
          ..color = Y4.honey
          ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(sunCx, sunCy), 6, sunPaint);
    canvas.drawCircle(
      Offset(sunCx, sunCy),
      6,
      Paint()
        ..color = Y4.honeyDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_Y4SunArcPainter old) => old.pct != pct;
}

/// Garden hero card: sun + label + animated count-up number + "+today" pill
/// (skipped per spec) + 5-plant garden floor.
class _Y4HeroCard extends StatefulWidget {
  final int value;
  final int pendingPoints;
  final int visitCount;
  const _Y4HeroCard({required this.value, this.pendingPoints = 0, this.visitCount = 0});

  @override
  State<_Y4HeroCard> createState() => _Y4HeroCardState();
}

class _Y4HeroCardState extends State<_Y4HeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _from = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void didUpdateWidget(_Y4HeroCard old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || old.visitCount != widget.visitCount) {
      _from = old.value;
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

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.3, -1.0),
          end: const Alignment(0.5, 1.0),
          colors: [Y4.cream, Y4.honey.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Y4.border),
      ),
      // Clip children to the outer rounded shape directly. The previous
      // inner ClipRRect was inset by the 20 px padding but still used a
      // radius of 28, which made its top-left corner curve clip the "Y"
      // of "YOUR GARDEN" right at the origin.
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
            // Sun (top-right)
            Positioned(top: 0, right: 0, child: _Y4Sun(size: 44)),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.yourGarden ??
                              'YOUR GARDEN',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Y4.inkSoft,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Sabiq Seed coin — the currency mark next to
                            // the big balance number. Keyed so sealed-day
                            // coins can fly here and land in the garden.
                            SabiqCoin(
                              key: gardenSeedKey,
                              size: 44,
                              sprouting: true,
                            ),
                            const SizedBox(width: 10),
                            AnimatedBuilder(
                              animation: _anim,
                              builder: (_, __) {
                                final v =
                                    (_from +
                                            (widget.value - _from) *
                                                _anim.value)
                                        .round();
                                return Text(
                                  _fmt(v),
                                  style: Y4.display(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w400,
                                    color: Y4.honeyDeep,
                                    letterSpacing: -0.02 * 52,
                                    height: 0.95,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        // "Sabiq Seeds bloomed" caption removed — the big
                        // honey-deep number plus the seed coin already read
                        // as the wallet total without an extra label.
                        // Pending-seeds messaging lives in the drop-in pill
                        // above the Seal-the-Day slider.
                      ],
                    ),
                  ),
                ),

                // Garden floor with 5 plants
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Y4.honey.withValues(alpha: 0.13),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      _Y4Plant(grow: 1.0, size: 50),
                      _Y4Plant(grow: 0.75, size: 56),
                      _Y4Plant(grow: 0.4, size: 48),
                      _Y4Plant(grow: 0.9, size: 58),
                      _Y4Plant(grow: 0.2, size: 42),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

/// "Growing streak" garden card — single big number + 7-day plant row.
/// Streak source is max(dhikr, quran). Plant row built from snap histories.
class _Y4StreakCard extends StatelessWidget {
  final StreakSnapshot snap;
  final VoidCallback onTap;
  const _Y4StreakCard({required this.snap, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final streak = snap.dhikr > snap.quran ? snap.dhikr : snap.quran;
    final today = DateTime.now();

    // Build a unified set of "active" days in the last 7 days from
    // dhikr + quran histories.
    final Set<int> activeDays = {};
    for (final d in [...snap.dhikrHistory, ...snap.quranHistory]) {
      final delta = today.difference(DateTime(d.year, d.month, d.day)).inDays;
      if (delta >= 0 && delta < 7) activeDays.add(delta);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Y4.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Y4.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.growingStreakTitle ??
                            'GROWING STREAK',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Y4.inkSoft,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$streak ${streak == 1 ? (AppLocalizations.of(context)?.daySingular ?? 'day') : (AppLocalizations.of(context)?.daysPlural ?? 'days')}',
                            style: Y4.display(
                              fontSize: 28,
                              fontWeight: FontWeight.w400,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '· ${AppLocalizations.of(context)?.keepGrowing ?? 'keep growing'}',
                            style: Y4.display(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Y4.honeyDeep,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 7 days: oldest (6 days ago) → today
            Row(
              children: List.generate(7, (i) {
                final daysAgo = 6 - i;
                final isToday = daysAgo == 0;
                final done = activeDays.contains(daysAgo);
                const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                // Build labels such that today aligns with the user's actual weekday.
                final dt = today.subtract(Duration(days: daysAgo));
                final letter =
                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][(dt.weekday - 1) % 7];
                final _ = labels; // suppress unused (kept for reference)
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        letter,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Y4.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _Y4StreakPlant(done: done, today: isToday && !done),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tabbed sun-arc progress card. Today / Week / Month with shared 50/250/800
/// goals.
class _Y4ProgressCard extends StatefulWidget {
  final int? todayPts, weekPts, monthPts;
  final bool hasError;
  const _Y4ProgressCard({
    required this.todayPts,
    required this.weekPts,
    required this.monthPts,
    required this.hasError,
  });

  @override
  State<_Y4ProgressCard> createState() => _Y4ProgressCardState();
}

class _Y4ProgressCardState extends State<_Y4ProgressCard> {
  String _tab = 'Week';

  @override
  Widget build(BuildContext context) {
    final ss = context.watch<SettingsService>();
    final pts = switch (_tab) {
      'Today' => widget.todayPts ?? 0,
      'Week' => widget.weekPts ?? 0,
      _ => widget.monthPts ?? 0,
    };
    final goal = switch (_tab) {
      'Today' => ss.dayGoal,
      'Week' => ss.weekGoal,
      _ => ss.monthGoal,
    };
    final pct = goal == 0 ? 0.0 : (pts / goal).clamp(0.0, 1.0);

    String fmt(int n) {
      final s = n.toString();
      final buf = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Y4.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Y4.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context)?.progressLabel ?? 'Progress',
                style: Y4.display(
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  height: 1.0,
                ),
              ),
              const Spacer(),
              // Tab pill
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Y4.track,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      [
                        {
                          'id': 'Today',
                          'label':
                              AppLocalizations.of(context)?.todayTab ?? 'Today',
                        },
                        {
                          'id': 'Week',
                          'label':
                              AppLocalizations.of(context)?.weekTab ?? 'Week',
                        },
                        {
                          'id': 'Month',
                          'label':
                              AppLocalizations.of(context)?.monthTab ?? 'Month',
                        },
                      ].map((item) {
                        final t = item['id'] as String;
                        final label = item['label'] as String;
                        final on = _tab == t;
                        return GestureDetector(
                          onTap: () => setState(() => _tab = t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: on ? Y4.ink : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              label,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: on ? Colors.white : Y4.inkSoft,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Animate between the tab's pct values so the swap is
              // visually unambiguous — without this the arc snaps and on
              // similar values looks like nothing changed.
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: pct.toDouble()),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => _Y4SunArc(pct: v),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  // Align number + "of X week goal" to the right edge so
                  // they sit directly under the Today/Week/Month tab pill
                  // above (which is pinned to the card's right edge).
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.hasError ? '---' : fmt(pts),
                      style: Y4.display(
                        fontSize: 30,
                        letterSpacing: -0.02 * 30,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)?.ofTabGoal(
                            fmt(goal),
                            _tab == 'Today'
                                ? (AppLocalizations.of(
                                      context,
                                    )?.todayTab?.toLowerCase() ??
                                    'today')
                                : _tab == 'Week'
                                ? (AppLocalizations.of(
                                      context,
                                    )?.weekTab?.toLowerCase() ??
                                    'week')
                                : (AppLocalizations.of(
                                      context,
                                    )?.monthTab?.toLowerCase() ??
                                    'month'),
                          ) ??
                          'of ${fmt(goal)} ${_tab.toLowerCase()} goal',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Y4.inkSoft,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
