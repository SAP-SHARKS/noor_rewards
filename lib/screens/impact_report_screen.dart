// lib/screens/impact_report_screen.dart
//
// Akhirah Balance — a premium Islamic banking-style dashboard showing
// the user's spiritual portfolio: deeds, streaks, and earnings.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../utils/project_l10n.dart' as proj_l10n;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/streak_service.dart';
import '../services/stats_service.dart';
import '../services/donation_service.dart';
import '../utils/name_localizer.dart';
import '../widgets/noor_icons.dart';
import '../widgets/noor_offline.dart';
import '../widgets/project_media_carousel.dart';
import '../widgets/sabiq_coin.dart';
import '../widgets/orphans_strip.dart';
import '../models/orphan.dart';
import 'orphan_detail_screen.dart';
import '../services/settings_service.dart';
import '../models/app_config.dart';
import '../theme/y4_theme.dart';

// ── Palette (reads from admin-controlled AppConfig) ─────────────────────────
AppConfig get _icfg => SettingsService.instance.config;

class _C {
  static Color get bg => _icfg.dashBg;
  static Color get darkGreen => _icfg.primaryColor;
  static Color get teal => _icfg.dashTeal;
  static Color get gold => _icfg.donationColor;
  static Color get card =>
      _icfg.dashBg.computeLuminance() > 0.5
          ? Colors.white
          : const Color(0xFF1F2937);
  static Color get text => _icfg.dashText;
  static Color get sub =>
      _icfg.dashBg.computeLuminance() > 0.5
          ? const Color(0xFF8E8E93)
          : const Color(0xFF9CA3AF);
  static Color get border =>
      _icfg.dashBg.computeLuminance() > 0.5
          ? const Color(0xFFE8E8EC)
          : const Color(0xFF374151);
  static Color get rose => const Color(0xFFE05C6A);
  static Color get purple => _icfg.secondaryColor;
}

class ImpactReportScreen extends StatefulWidget {
  final bool isTab;
  final int visitCount;
  const ImpactReportScreen({
    super.key,
    this.isTab = false,
    this.visitCount = 0,
  });
  @override
  State<ImpactReportScreen> createState() => _ImpactReportScreenState();
}

class _ImpactReportScreenState extends State<ImpactReportScreen>
    with SingleTickerProviderStateMixin {
  final _sb = Supabase.instance.client;

  // Profile
  int _noorPoints = 0;
  int _level = 1;
  // Raw DB title — English ("Seeker"/"Champion"/etc.). Always run through
  // `_localizedTitle()` before display so non-English locales see the
  // translated tier name.
  String _levelTitle = 'Seeker';

  String _localizedTitle() {
    final l = AppLocalizations.of(context);
    switch (_levelTitle) {
      case 'Seeker':
        return l?.levelSeeker ?? 'Seeker';
      case 'Believer':
        return l?.levelBeliever ?? 'Believer';
      case 'Devoted':
        return l?.levelDevoted ?? 'Devoted';
      case 'Champion':
        return l?.levelChampion ?? 'Champion';
      case 'Legend':
        return l?.levelLegend ?? 'Legend';
      default:
        return _levelTitle;
    }
  }

  // Activity
  int _totalDonated = 0;
  int _todayPoints = 0;
  int _weekPoints = 0;
  // Last 7 days of worship time (oldest → newest) in seconds.
  // Aligned with `_weekDayLabels` below.
  List<int> _weekDayTimes = const [0, 0, 0, 0, 0, 0, 0];
  int _selectedDay = 6; // 0..6, defaults to today (last in window)
  // Current-month aggregates derived from user_daily_stats so the "Your Month"
  // card stays in sync with the same source of truth as the weekly chart.
  int _monthActiveDays = 0;
  int _monthQuranTimeSec = 0;
  int _monthDhikrTimeSec = 0;
  int _monthAyahs = 0;
  int _monthDhikrCount = 0;
  int _monthPoints = 0;
  // Today's own activity (from user_daily_stats row where stat_date = today).
  int _todayAyahs = 0;
  int _todayQuranSec = 0;

  // Streaks
  StreakSnapshot _snap = StreakSnapshot.empty;

  // Monthly stats

  // Real lifetime activity (sum of every recorded month) — drives holdings
  int _lifetimeAyahs = 0;
  int _lifetimeDhikr = 0;
  // Per-phrase lifetime counts keyed by azkar id
  Map<String, int> _phraseCounts = const {};

  // ── Phrase groups for hadith-grounded holdings ──────────────────────────
  // Trees in Jannah — Tirmidhi 3464: SubhanAllah, Alhamdulillah, La ilaha
  // illallah, Allahu Akbar — each plants a tree in Jannah. Any azkar item
  // whose recitation is exactly one of these four phrases contributes.
  static const List<String> _kTreePhraseIds = [
    'subhanallah',
    'alhamdulillah',
    'allahu_akbar',
    'la_ilaha_illallah',
    'post_prayer_subhanallah',
    'post_prayer_alhamdulillah',
    'post_prayer_allahu_akbar',
    'sleeping_tasbih_1',
    'sleeping_tasbih_2',
    'sleeping_tasbih_3',
    'morning_20',
    'evening_20',
    'hajj_tawaf',
  ];

  // Sins Forgiven — Bukhari 6405: "SubhanAllahi wa bihamdihi 100×" = 1 cycle.
  // morning_32 and evening_31 reference the same phrase + hadith.
  static const List<String> _kForgivenessPhraseIds = [
    'subhanallahi_wabihamdih',
    'morning_32',
    'evening_31',
  ];

  // Treasures of Jannah — Bukhari 4205: each "La hawla wa la quwwata illa
  // billah" is a treasure.
  static const List<String> _kTreasurePhraseIds = [
    'la_hawla',
    'iman_tawakkul',
  ];

  // Slaves Freed — Bukhari 6403: "La ilaha illallahu wahdahu la sharika
  // lahu..." 10× ≡ freeing 4 slaves. morning_31 and evening_30 reference
  // the same phrase + hadith.
  static const List<String> _kSlavesPhraseIds = [
    'post_prayer_la_ilaha',
    'waking_up_2',
    'morning_31',
    'evening_30',
  ];

  // Palaces Built — Bukhari 5017 cluster: Surah Al-Ikhlas 10× = 1 palace.
  // Each azkar item below is one full Ikhlas recitation per completion.
  static const List<String> _kIkhlasPhraseIds = [
    'sleeping_ikhlas',
    'morning_9',
    'evening_9',
  ];

  // Gates of Paradise Opened — Sahih Muslim 234: shahadah after wudu opens
  // all 8 gates of Jannah.
  static const String _kGatesPhraseId = 'wudu_shahada';

  // Blessings from Allah — Sahih Muslim 408: 1 salawat sent = 10 returned.
  static const List<String> _kSalawatPhraseIds = [
    'salawat_ibrahimiyya',
    'salawat_simple',
    'salawat_friday',
    'evening_32',
  ];

  // Times Protected — combined hadith references for divine protection:
  //   Ayat al-Kursi at sleep (Bukhari 2311) and after prayer (Nasai),
  //   Muawwidhatayn morning/evening (Abu Dawud 5082),
  //   "A'udhu bi-kalimatillah" (Muslim 2708 — home_protection),
  //   morning_21/evening_21 "Protect from all harm" (Tirmidhi 3388),
  //   morning_23/evening_23 "Protection from all evil" (Muslim 2709),
  //   morning_28/evening_28 "Good health & protection" (Abu Dawud 5090).
  static const List<String> _kProtectionPhraseIds = [
    'sleeping_ayat_kursi',
    'post_prayer_ayat_kursi',
    'home_protection',
    'iman_falaq_nas',
    'morning_21',
    'evening_21',
    'morning_23',
    'evening_23',
    'morning_28',
    'evening_28',
  ];

  // Bonus Million Hasanaat — Ibn Majah 2235: marketplace dua = 1,000,000
  // good deeds written, 1,000,000 sins erased, raised 1,000,000 levels.
  static const String _kMillionPhraseId = 'shopping_dua';

  // Whether the user has tapped "See All" to reveal the full holdings list.
  // When false, only the first 5 rows render; "See All" / "Show less" toggles
  // this inline (no separate bottom sheet).
  bool _holdingsExpanded = false;
  static const int _kHoldingsPreviewCount = 5;

  bool _loading = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;
  final ScrollController _scrollCtrl = ScrollController();

  // ── Rotating reminder pool (Akhirah / Jannah / sadaqah themed) ────────
  // One sentence is picked per app launch — never the same as the last
  // (persisted via SharedPreferences). Mirrors the pattern used in
  // akhirah_balance_screen.dart but with hereafter-themed content.
  static const String _kPrefKeyLastReminderIdx = 'impact_last_reminder_idx';
  static const List<String> _kReminderPool = [
    // — Quranic —
    '“Whoever does an atom\'s weight of good will see it.” — Surah Az-Zalzalah 99:7',
    '“The home of the Hereafter — that is the eternal life, if only they knew.” — Surah Al-Ankabut 29:64',
    '“Race towards forgiveness from your Lord and a Garden as wide as the heavens and the earth.” — Surah Al-Hadid 57:21',
    '“And what is the life of this world except amusement of delusion?” — Surah Ali Imran 3:185',
    '“Indeed, with hardship comes ease.” — Surah Ash-Sharh 94:6',
    // — Hadith-anchored —
    '“A single good deed in Ramadan equals 70 in any other month.” Stack while the door is open.',
    'The Prophet ✍ said: charity does not decrease wealth — it grows it. (Muslim)',
    '“Smiling at your brother is sadaqah.” You can earn even when your pockets are empty. (Tirmidhi)',
    '“The most beloved deeds to Allah are the most consistent, even if small.” (Bukhari)',
    '“In Jannah is what no eye has seen, no ear has heard, and no heart has imagined.” (Bukhari)',
    'Two rakats at Fajr are better than the world and everything in it. (Muslim)',
    'Every step toward salah erases a sin and raises a rank. (Muslim)',
    // — Coaching / motivation —
    'Every seed you donate plants a tree in someone else\'s Jannah — and in yours.',
    'You can\'t take wealth with you. Only the deeds it bought.',
    'The angels record nothing too small. One Subhanallah may outweigh a mountain.',
    'Today\'s sadaqah is tomorrow\'s shade on the day there is no shade.',
    'A heart that gives is a heart Allah keeps full. Don\'t close it.',
    'Death isn\'t the end — it\'s the receipt. What did you send ahead?',
    'Imagine your scale on Yawm al-Qiyamah. What weight are you adding today?',
    'The world is borrowed. The Akhirah is owned. Invest accordingly.',
    'You bury the body — but not the deeds. Send them ahead while you can.',
    'A righteous child who prays for you, a charity that flows, or knowledge that benefits — three eternal investments. (Muslim)',
    'You will meet Allah with your record. Make sure today\'s page is one you want Him to read.',
    'No deed is too small for the One who counts atoms.',
  ];
  String _reminder = _kReminderPool[0];

  // Pick a random reminder different from the last shown one. Persist the
  // chosen index so the next launch can avoid repeating it.
  Future<void> _loadReminder() async {
    int lastIdx = -1;
    try {
      final prefs = await SharedPreferences.getInstance();
      lastIdx = prefs.getInt(_kPrefKeyLastReminderIdx) ?? -1;
    } catch (_) {/* fall through with -1 */}
    final rand = math.Random();
    int idx;
    do {
      idx = rand.nextInt(_kReminderPool.length);
    } while (idx == lastIdx && _kReminderPool.length > 1);
    if (mounted) setState(() => _reminder = _kReminderPool[idx]);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kPrefKeyLastReminderIdx, idx);
    } catch (_) {/* best-effort */}
  }

  // Styled reminder card — same visual language as akhirah_balance_screen
  // ("A REMINDER" eyebrow + sparkle icon + warm honey gradient).
  Widget _reminderCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFCEC), Color(0xFFFFF6D6)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Y4.primary.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Y4.primary.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Y4.primary, Y4.primaryDeep],
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: Y4.primaryDeep.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.aReminderLabel ?? 'A REMINDER',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Y4.primaryDeep,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _reminder,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Y4.ink,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadReminder();
    // Listen for any new dhikr / ayah recorded in this session.
    // StatsService bumps `revision` synchronously after each record(),
    // so this fires the instant the user completes a set — even while the
    // Akhirah tab is offstage in the IndexedStack.
    StatsService.instance.revision.addListener(_onStatsChanged);
    // Re-run _load() whenever a screen-time flush commits. We can't rely
    // on didUpdateWidget here because the dashboard wraps each tab in a
    // Navigator(onGenerateRoute:) which captures the child widget once and
    // doesn't propagate later visitCount changes.
    StatsService.instance.chartRefresh.addListener(_onChartRefresh);
    _load();
  }

  void _onChartRefresh() {
    if (!mounted) return;
    // Re-render immediately so the optimistic local seconds show up; then
    // re-fetch from the server in the background. _load() will reset the
    // optimistic counter once the server numbers come back.
    setState(() {});
    _load();
  }

  @override
  void didUpdateWidget(ImpactReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-fetch holdings whenever the user returns to the Akhirah tab so
    // freshly recited dhikr / read ayahs are reflected immediately.
    if (widget.visitCount != oldWidget.visitCount) {
      _load();
    }
  }

  @override
  void dispose() {
    StatsService.instance.revision.removeListener(_onStatsChanged);
    StatsService.instance.chartRefresh.removeListener(_onChartRefresh);
    _fadeCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onStatsChanged() {
    if (!mounted) return;
    // Pull the latest snapshot from StatsService's in-memory cache.
    // No DB round-trip required — the cache is authoritative for the
    // current session and survives the offstage IndexedStack child.
    setState(() {
      _phraseCounts = StatsService.instance.phraseCountsSnapshot;
      _lifetimeAyahs = StatsService.instance.lifetimeAyahsSnapshot;
      _lifetimeDhikr = StatsService.instance.lifetimeDhikrSnapshot;
    });
  }

  Future<void> _load() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    // If the user just came from a Quran or Dhikr screen, its dispose() fired
    // exitScreen() but didn't await the RPC. Wait for that flush to commit so
    // the daily-stats read below includes the session that just ended.
    await StatsService.instance.awaitPendingFlush();

    try {
      // ── Wave 1: 11 independent reads in parallel ─────────────────────────
      // Each future is wrapped with catchError so one slow / failing source
      // never poisons the rest. Was: 4 unchecked items (any of which could
      // cancel the whole load) + 3 sequential reads at the end of the
      // function. Now everything that doesn't depend on _level runs at once.
      final results = await Future.wait<dynamic>([
        // 0: profile
        _sb
            .from('profiles')
            .select('display_name, total_xp, level, noor_points')
            .eq('id', uid)
            .maybeSingle()
            .then<Map<String, dynamic>?>((v) => v)
            .catchError((_) => null),
        // 1: user_analytics
        _sb
            .from('user_analytics')
            .select('session_duration_sec, noor_coins_earned')
            .eq('user_id', uid)
            .maybeSingle()
            .then<Map<String, dynamic>?>((v) => v)
            .catchError((_) => null),
        // 2: total donations lifetime
        DonationService.instance.getUserTotalDonations(),
        // 3: today points
        _sb.rpc('get_today_points').catchError((_) => 0),
        // 4: week points
        _sb.rpc('get_week_points').catchError((_) => 0),
        // 5: streak snapshot
        StreakService.instance
            .loadSnapshot()
            .catchError((_) => StreakSnapshot.empty),
        // 6: last 7 days of screen time
        _sb
            .rpc('get_week_screen_time', params: {'p_user_id': uid})
            .then<List<int>>((rows) {
              final list = (rows as List)
                  .map((r) => (r['total_sec'] as num?)?.toInt() ?? 0)
                  .toList();
              while (list.length < 7) list.insert(0, 0);
              return list.length > 7 ? list.sublist(list.length - 7) : list;
            })
            .catchError((_) => List<int>.filled(7, 0)),
        // 7: current-month daily rows (for the "Your Month" aggregates)
        () async {
          final now = DateTime.now();
          final firstOfMonth = DateTime(now.year, now.month, 1)
              .toIso8601String()
              .substring(0, 10);
          try {
            return await _sb
                .from('user_daily_stats')
                .select(
                    'stat_date, quran_time_sec, dhikr_time_sec, ayahs_read, dhikr_count')
                .eq('user_id', uid)
                .gte('stat_date', firstOfMonth);
          } catch (_) {
            return const <Map<String, dynamic>>[];
          }
        }(),
        // 8: month points
        _sb.rpc('get_month_points').catchError((_) => 0),
        // 9: lifetime activity (moved into wave 1 — was a 2nd round-trip)
        StatsService.instance
            .loadLifetimeActivity()
            .catchError((_) => (ayahsRead: 0, dhikrCount: 0, dhikrSets: 0)),
        // 10: per-phrase counts (moved into wave 1 — was a 3rd round-trip)
        StatsService.instance
            .loadPhraseCounts()
            .catchError((_) => const <String, int>{}),
      ]);

      final profile = results[0] as Map<String, dynamic>?;

      _level = (profile?['level'] as num?)?.toInt() ?? 1;
      _noorPoints = (profile?['noor_points'] as num?)?.toInt() ?? 0;
      _totalDonated = results[2] as int;
      _todayPoints = (results[3] as num?)?.toInt() ?? 0;
      _weekPoints = (results[4] as num?)?.toInt() ?? 0;
      _snap = results[5] as StreakSnapshot;
      _weekDayTimes = results[6] as List<int>;
      _selectedDay = 6; // today is the newest entry
      // Server values are now the truth; clear any optimistic seconds that
      // were prepended while the RPC was in flight.
      StatsService.instance.resetOptimisticToday();

      // Aggregate current-month daily rows.
      _monthActiveDays = 0;
      _monthQuranTimeSec = 0;
      _monthDhikrTimeSec = 0;
      _monthAyahs = 0;
      _monthDhikrCount = 0;
      _todayAyahs = 0;
      _todayQuranSec = 0;
      final todayKey = DateTime.now().toIso8601String().substring(0, 10);
      final monthRows = results[7] as List;
      for (final r in monthRows) {
        final m = r as Map<String, dynamic>;
        final qt = (m['quran_time_sec'] as num?)?.toInt() ?? 0;
        final dt = (m['dhikr_time_sec'] as num?)?.toInt() ?? 0;
        final ay = (m['ayahs_read'] as num?)?.toInt() ?? 0;
        final dc = (m['dhikr_count'] as num?)?.toInt() ?? 0;
        if (qt > 0 || dt > 0 || ay > 0 || dc > 0) _monthActiveDays++;
        _monthQuranTimeSec += qt;
        _monthDhikrTimeSec += dt;
        _monthAyahs += ay;
        _monthDhikrCount += dc;
        // Capture today's own values for the personalized badge.
        final d = (m['stat_date'] as String?) ?? '';
        if (d == todayKey) {
          _todayAyahs = ay;
          _todayQuranSec = qt;
        }
      }
      _monthPoints = (results[8] as num?)?.toInt() ?? 0;

      // Indices 9 & 10 — lifetime activity + phrase counts (moved from
      // trailing sequential reads into wave 1).
      final lifetime = results[9]
          as ({int ayahsRead, int dhikrCount, int dhikrSets});
      _lifetimeAyahs = lifetime.ayahsRead;
      _lifetimeDhikr = lifetime.dhikrCount;
      _phraseCounts = results[10] as Map<String, int>;

      // ── Wave 2: xp_levels title lookup needs _level from wave 1 ─────────
      try {
        final lv = await _sb
            .from('xp_levels')
            .select('title')
            .eq('level', _level)
            .maybeSingle();
        _levelTitle = (lv?['title'] as String?) ?? _fallbackTitle(_level);
      } catch (_) {
        _levelTitle = _fallbackTitle(_level);
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  int _sumPhrases(List<String> ids) {
    var total = 0;
    for (final id in ids) {
      total += _phraseCounts[id] ?? 0;
    }
    return total;
  }

  void _toggleHoldings() {
    final wasExpanded = _holdingsExpanded;
    setState(() => _holdingsExpanded = !_holdingsExpanded);
    if (!wasExpanded) {
      // Expanding: after the new rows lay out, scroll down so the user
      // sees the additional holdings. Rough estimate of one row height ×
      // the number of newly revealed rows.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollCtrl.hasClients) return;
        final viewport =
            _scrollCtrl.position.viewportDimension.clamp(0.0, 600.0);
        final target = (_scrollCtrl.offset + viewport * 0.55).clamp(
          _scrollCtrl.position.minScrollExtent,
          _scrollCtrl.position.maxScrollExtent,
        );
        _scrollCtrl.animateTo(
          target,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  String _fallbackTitle(int lv) {
    if (lv >= 51) return 'Legend';
    if (lv >= 21) return 'Champion';
    if (lv >= 11) return 'Devoted';
    if (lv >= 6) return 'Believer';
    return 'Seeker';
  }

  // ── Hadith-grounded holdings ────────────────────────────────────────────
  // Each value is derived from actual recorded activity (per-phrase dhikr
  // counts + lifetime ayahs read), not a fraction of total points.

  // Avg letters per ayah across the whole Quran. The Mushaf has roughly
  // 330,733 base letters spread across 6,236 ayahs (~53 letters per ayah);
  // we use 50 as a conservative round number to keep the count honest.
  static const int _kAvgLettersPerAyah = 50;

  // Hasanaat — combines two hadith:
  //   • Sahih Muslim 131 — every good deed multiplied by 10. Each dhikr
  //     recitation counts as one good deed → ×10 hasanat.
  //   • Tirmidhi 2910 — every LETTER of Quran read = 10 hasanat (Alif,
  //     Lam, Mim are three letters, not one). One ayah ≈ 50 letters →
  //     ×500 hasanat per ayah.
  // Previously this was a flat ×10 across both, which massively
  // undercounted Quran reading. The corrected per-letter math brings the
  // Quran contribution in line with the hadith.
  int get _hasanatFromDhikr => _lifetimeDhikr * 10;
  int get _hasanatFromQuran => _lifetimeAyahs * _kAvgLettersPerAyah * 10;
  int get _hasanaat => _hasanatFromDhikr + _hasanatFromQuran;

  // Trees in Jannah — Tirmidhi 3464.
  int get _treesPlanted => _sumPhrases(_kTreePhraseIds);

  // Sins Forgiven — Bukhari 6405.
  int get _forgivenessPhraseCount => _sumPhrases(_kForgivenessPhraseIds);
  int get _sinsWiped => _forgivenessPhraseCount ~/ 100;

  // Treasures of Jannah — Bukhari 4205.
  int get _treasures => _sumPhrases(_kTreasurePhraseIds);

  // Slaves Freed — Bukhari 6403: 10 recitations ≡ 4 slaves freed.
  int get _slavesPhraseCount => _sumPhrases(_kSlavesPhraseIds);
  int get _slavesFreed => (_slavesPhraseCount ~/ 10) * 4;

  // Palaces Built — Bukhari 5017 cluster: Surah Ikhlas 10× = 1 palace.
  int get _ikhlasCount => _sumPhrases(_kIkhlasPhraseIds);
  int get _palacesBuilt => _ikhlasCount ~/ 10;

  // Gates of Paradise Opened — Sahih Muslim 234: shahadah after wudu
  // opens all 8 gates.
  int get _wuduShahadaCount => _phraseCounts[_kGatesPhraseId] ?? 0;
  int get _gatesOpened => _wuduShahadaCount * 8;

  // Blessings from Allah — Sahih Muslim 408: 1 salawat = 10 blessings back.
  int get _salawatCount => _sumPhrases(_kSalawatPhraseIds);
  int get _blessingsReceived => _salawatCount * 10;

  // Times Protected — combined protection hadith.
  int get _protectionInvocations => _sumPhrases(_kProtectionPhraseIds);

  // Bonus Million Hasanaat — Ibn Majah 2235.
  int get _shoppingDuaCount => _phraseCounts[_kMillionPhraseId] ?? 0;
  int get _millionHasanaat => _shoppingDuaCount * 1000000;

  // Quran Completions via Ikhlas — Bukhari 5017: Surah Ikhlas 3× ≡ whole Quran.
  int get _quranCompletionsViaIkhlas => _ikhlasCount ~/ 3;
  int get _bestStreak => [
    _snap.bestLogin,
    _snap.bestDhikr,
    _snap.bestQuran,
  ].reduce((a, b) => a > b ? a : b);

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: _C.bg,
      body:
          _loading
              ? Center(
                child: NoorInlineLoader(
                  height: double.infinity,
                  label:
                      AppLocalizations.of(context)?.loadingYourReport ??
                      'Loading your report…',
                ),
              )
              : FadeTransition(
                opacity: _fade,
                child: CustomScrollView(
                  controller: _scrollCtrl,
                  slivers: [
                    _buildHero(),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 20),
                          _buildMiniStats(),
                          const SizedBox(height: 24),
                          _buildHoldingsSection(),
                          const SizedBox(height: 24),
                          _buildActivityCard(),
                          const SizedBox(height: 24),
                          _buildMonthlyStatsCard(),
                          const SizedBox(height: 24),
                          _buildRewardsCard(),
                          const SizedBox(height: 30),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // ── Hero / Balance Card ────────────────────────────────────────────────────
  Widget _buildHero() => SliverToBoxAdapter(
    child: Container(
      decoration: BoxDecoration(
        // Honey wash hero matching dashboard aesthetic
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Y4.cream, Y4.honey.withValues(alpha: 0.30), Y4.bg],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative arcs (subtle honey/sage on light bg)
            Positioned(
              top: -40,
              right: -40,
              child: _Arc(160, Y4.honey.withValues(alpha: 0.18)),
            ),
            Positioned(
              bottom: -20,
              left: -30,
              child: _Arc(120, Y4.primary.withValues(alpha: 0.08)),
            ),
            Positioned(
              top: 30,
              right: 30,
              child: _Arc(60, Y4.honeyDeep.withValues(alpha: 0.10)),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    children: [
                      if (!widget.isTab)
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Y4.ink,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32),
                        ),
                      if (!widget.isTab) const Spacer(),
                      if (widget.isTab)
                        Text(
                          AppLocalizations.of(context)?.akhirahBalance ??
                              'Akhirah Balance',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Y4.ink,
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Y4.honeyDeep,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              color: Y4.honeyDeep,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              AppLocalizations.of(context)
                                      ?.levelTitleFormat(_level, _localizedTitle()) ??
                                  'Lvl $_level · ${_localizedTitle()}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Y4.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Label
                  Text(
                    AppLocalizations.of(context)?.akhirahBalanceUpper ??
                        'AKHIRAH BALANCE',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Y4.inkSoft,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // "+N today" pill on its own line (replaces the Priceless
                  // heading + "Beyond what the world can hold" subtitle).
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Y4.primaryDeep.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.trending_up_rounded,
                              color: Y4.primaryDeep,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+${_todayPoints > 0 ? _todayPoints : 0} today',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Y4.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Today / this week badges
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _HeroBadge(
                        NoorIcon.sunrise(size: 14),
                        AppLocalizations.of(context)
                                ?.plusDeedsTodayBadge(_fmt(_todayPoints)) ??
                            '+${_fmt(_todayPoints)} deeds today',
                        Colors.white.withValues(alpha: 0.78),
                        Y4.primaryDeep,
                      ),
                      _HeroBadge(
                        NoorIcon.calendar(size: 14),
                        AppLocalizations.of(context)
                                ?.plusSeedsThisWeek(_fmt(_weekPoints)) ??
                            '+${_fmt(_weekPoints)} this week',
                        Colors.white.withValues(alpha: 0.78),
                        Y4.honeyDeep,
                      ),
                      if (_bestStreak > 0)
                        _HeroBadge(
                          NoorIcon.fire(size: 14),
                          AppLocalizations.of(context)
                                  ?.bestDayStreakBadge(_bestStreak) ??
                              'Best: $_bestStreak day streak',
                          Colors.white.withValues(alpha: 0.78),
                          const Color(0xFFB45309),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Rotating Akhirah/Jannah/good-deeds reminder — same
                  // visual language as the akhirah_balance reflection card.
                  _reminderCard(),

                  const SizedBox(height: 18),

                  GestureDetector(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CommunityImpactPage(),
                          ),
                        ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Y4.honeyDeep,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Y4.honeyDeep.withValues(alpha: 0.30),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NoorIcon.globe(size: 16),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)?.donateMoreEarn ??
                                'Donate More & Earn',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ],
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
  );

  // ── Mini stat pills ────────────────────────────────────────────────────────
  Widget _buildMiniStats() => Row(
    key: ValueKey(widget.visitCount),
    children: [
      Expanded(
        child: _MiniStat(
          NoorIcon.star(size: 20),
          _hasanaat,
          AppLocalizations.of(context)?.deedsLabel ?? 'DEEDS',
          _C.gold,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _MiniStat(
          NoorIcon.tree(size: 20),
          _treesPlanted,
          AppLocalizations.of(context)?.treesLabel ?? 'TREES',
          const Color(0xFF2D7A45),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _MiniStat(
          NoorIcon.drop(size: 20),
          _sinsWiped,
          AppLocalizations.of(context)?.forgivenLabel ?? 'FORGIVEN',
          _C.teal,
        ),
      ),
    ],
  );

  // ── Your Holdings ──────────────────────────────────────────────────────────
  Widget _buildHoldingsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)?.yourHoldings ?? 'Your Holdings',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _C.text,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleHoldings,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                _holdingsExpanded
                    ? (AppLocalizations.of(context)?.showLessAction ??
                        'Show Less ←')
                    : (AppLocalizations.of(context)?.seeAll ?? 'See All →'),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.teal,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _buildHoldingsCard(),
    ],
  );

  void _showHoldingDetail({
    required String title,
    required int value,
    required Color color,
    required String hadith,
    required String breakdown,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24, 20, 24,
            MediaQuery.of(context).padding.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title + value
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.rajdhani(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _C.text,
                      ),
                    ),
                  ),
                  Text(
                    _fmt(value),
                    style: GoogleFonts.rajdhani(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Hadith reference
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book_rounded, size: 16, color: color),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)?.hadithReference ??
                              'Hadith Reference',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hadith,
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        color: _C.text,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Breakdown
              Text(
                AppLocalizations.of(context)?.howYouEarnedThis ??
                    'How you earned this',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _C.text,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                breakdown,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: _C.sub,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHoldingsCard() {
    final allRows = _buildAllHoldingRows();
    final visibleRows = _holdingsExpanded
        ? allRows
        : allRows.take(_kHoldingsPreviewCount).toList();
    final children = <Widget>[];
    for (var i = 0; i < visibleRows.length; i++) {
      if (i > 0) {
        children.add(
          const Divider(height: 1, indent: 70, endIndent: 20),
        );
      }
      children.add(visibleRows[i]);
    }
    return Container(
      // Key is intentionally independent of `_holdingsExpanded` — toggling
      // See All / Show Less must not destroy the row subtree, otherwise the
      // _AnimatedNumText counters re-roll every time. Re-keys only when the
      // user re-enters the tab so the entry roll-up still plays.
      key: ValueKey('holdings-${widget.visitCount}'),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  List<Widget> _buildAllHoldingRows() {
    final rows = <_HoldingRow>[
        _HoldingRow(
          icon: NoorIcon.sparkles(size: 24),
          color: _C.gold,
          bgColor: const Color(0xFFFDF6E3),
          title: AppLocalizations.of(context)?.hasanaatEarned ?? 'Hasanaat Earned',
          subtitle: AppLocalizations.of(context)?.recordedInBookOfDeeds ??
              'Recorded in your Book of Deeds',
          value: _hasanaat,
          change: AppLocalizations.of(context)?.allTimeLabel ?? 'All time',
          positive: true,
          isFirst: true,
          isLast: false,
          onTap: () => _showHoldingDetail(
            title: 'Hasanaat Earned',
            value: _hasanaat,
            color: _C.gold,
            hadith: '"Whoever does a good deed shall have ten times the like thereof." (Sahih Muslim 131)\n'
                '"Whoever reads a letter from the Book of Allah, he will have one hasanah, and a hasanah is multiplied by ten." (Tirmidhi 2910)',
            breakdown: 'Two hadith grow this number side by side:\n\n'
                'From dhikr — every recitation is one good deed × 10:\n'
                '  Dhikr recited (lifetime): ${_fmt(_lifetimeDhikr)}\n'
                '  → Hasanat: ${_fmt(_hasanatFromDhikr)}\n\n'
                'From Quran — every letter recited × 10 (≈ $_kAvgLettersPerAyah letters per ayah):\n'
                '  Ayahs read (lifetime): ${_fmt(_lifetimeAyahs)}\n'
                '  → Hasanat: ${_fmt(_hasanatFromQuran)}\n\n'
                'Total hasanaat: ${_fmt(_hasanaat)}',
          ),
        ),
        _HoldingRow(
          icon: NoorIcon.book(size: 24),
          color: const Color(0xFF1F7A6B),
          bgColor: const Color(0xFFE0F2EE),
          title: AppLocalizations.of(context)?.hasanatFromQuran ??
              'Hasanat from Quran',
          subtitle: AppLocalizations.of(context)
                  ?.tenPerLetterSubtitle(_kAvgLettersPerAyah) ??
              '10 per letter, $_kAvgLettersPerAyah per ayah',
          value: _hasanatFromQuran,
          change: AppLocalizations.of(context)
                  ?.holdingChangeAyahs(_fmt(_lifetimeAyahs)) ??
              '${_fmt(_lifetimeAyahs)} ayahs',
          positive: true,
          isFirst: false,
          isLast: false,
          onTap: () => _showHoldingDetail(
            title: 'Hasanat from Quran',
            value: _hasanatFromQuran,
            color: const Color(0xFF1F7A6B),
            hadith: '"Whoever reads a letter from the Book of Allah, he will have one hasanah, and a hasanah is multiplied by ten. I do not say that Alif-Lam-Mim is one letter — rather Alif is a letter, Lam is a letter, and Mim is a letter." (Tirmidhi 2910)',
            breakdown: 'Every single letter of the Quran you recite is rewarded with 10 hasanat. The whole Mushaf holds ~330,733 letters across 6,236 ayahs, so the app uses a conservative $_kAvgLettersPerAyah-letter-per-ayah average to count this honestly.\n\n'
                'Ayahs read (lifetime): ${_fmt(_lifetimeAyahs)}\n'
                'Letters (≈): ${_fmt(_lifetimeAyahs * _kAvgLettersPerAyah)}\n'
                'Multiplier: ×10\n'
                'Total hasanat from Quran: ${_fmt(_hasanatFromQuran)}',
          ),
        ),
        _HoldingRow(
          icon: NoorIcon.tree(size: 24),
          color: const Color(0xFF2D7A45),
          bgColor: const Color(0xFFE8F5EC),
          title: AppLocalizations.of(context)?.treesInJannah ?? 'Trees in Jannah',
          subtitle: AppLocalizations.of(context)?.fromSubhanAllahTasbih ??
              'From SubhanAllah & Tasbih',
          value: _treesPlanted,
          change: AppLocalizations.of(context)
                  ?.holdingChangePlanted(_fmt(_treesPlanted)) ??
              '${_fmt(_treesPlanted)} planted',
          positive: true,
          isFirst: false,
          isLast: false,
          onTap: () => _showHoldingDetail(
            title: 'Trees in Jannah',
            value: _treesPlanted,
            color: const Color(0xFF2D7A45),
            hadith: '"SubhanAllah, Alhamdulillah, La ilaha illallah, Allahu Akbar, each one plants a tree for you in Jannah.", Tirmidhi 3464',
            breakdown: 'One tree is planted for every recitation of these four phrases (including post-prayer tasbih, bedtime tasbih, morning/evening tasbih, and tawaf):\n\n'
                '• SubhanAllah (all sources): ${_fmt((_phraseCounts['subhanallah'] ?? 0) + (_phraseCounts['post_prayer_subhanallah'] ?? 0) + (_phraseCounts['sleeping_tasbih_1'] ?? 0))}\n'
                '• Alhamdulillah (all sources): ${_fmt((_phraseCounts['alhamdulillah'] ?? 0) + (_phraseCounts['post_prayer_alhamdulillah'] ?? 0) + (_phraseCounts['sleeping_tasbih_2'] ?? 0))}\n'
                '• Allahu Akbar (all sources): ${_fmt((_phraseCounts['allahu_akbar'] ?? 0) + (_phraseCounts['post_prayer_allahu_akbar'] ?? 0) + (_phraseCounts['sleeping_tasbih_3'] ?? 0))}\n'
                '• La ilaha illallah: ${_fmt(_phraseCounts['la_ilaha_illallah'] ?? 0)}\n'
                '• Morning/evening tasbih (×2) & Tawaf: ${_fmt((_phraseCounts['morning_20'] ?? 0) + (_phraseCounts['evening_20'] ?? 0) + (_phraseCounts['hajj_tawaf'] ?? 0))}\n\n'
                'Total trees planted: ${_fmt(_treesPlanted)}',
          ),
        ),
        _HoldingRow(
          icon: NoorIcon.drop(size: 24),
          color: _C.teal,
          bgColor: const Color(0xFFE0F7F4),
          title: AppLocalizations.of(context)?.sinsForgiven ?? 'Sins Forgiven',
          subtitle: AppLocalizations.of(context)?.likeFoamOfSea ??
              'Like the foam of the sea',
          value: _sinsWiped,
          change: AppLocalizations.of(context)
                  ?.holdingChangeCycles(_fmt(_sinsWiped)) ??
              '${_fmt(_sinsWiped)} cycles',
          positive: true,
          isFirst: false,
          isLast: false,
          onTap: () => _showHoldingDetail(
            title: 'Sins Forgiven',
            value: _sinsWiped,
            color: _C.teal,
            hadith: '"Whoever says SubhanAllahi wa bihamdihi 100 times a day, his sins are forgiven even if they were like the foam of the sea.", Bukhari 6405',
            breakdown: 'Each set of 100 recitations of "SubhanAllahi wa bihamdihi" counts as one cycle of forgiveness.\n\n'
                'Standalone: ${_fmt(_phraseCounts['subhanallahi_wabihamdih'] ?? 0)}\n'
                'In morning azkar (item 32): ${_fmt(_phraseCounts['morning_32'] ?? 0)}\n'
                'In evening azkar (item 31): ${_fmt(_phraseCounts['evening_31'] ?? 0)}\n'
                'Total recitations: ${_fmt(_forgivenessPhraseCount)}\n'
                'Divided by 100 → forgiveness cycles: ${_fmt(_sinsWiped)}',
          ),
        ),
        _HoldingRow(
          icon: NoorIcon.mosque(size: 24),
          color: const Color(0xFF4A90E2),
          bgColor: const Color(0xFFEAF2F8),
          title: AppLocalizations.of(context)?.palacesBuilt ?? 'Palaces Built',
          subtitle: AppLocalizations.of(context)?.fromSurahIkhlasRecitation ??
              'From Surah Ikhlas recitation',
          value: _palacesBuilt,
          change: AppLocalizations.of(context)
                  ?.holdingChangeBuilt(_fmt(_palacesBuilt)) ??
              '${_fmt(_palacesBuilt)} built',
          positive: true,
          isFirst: false,
          isLast: false,
          onTap: () => _showHoldingDetail(
            title: 'Palaces Built',
            value: _palacesBuilt,
            color: const Color(0xFF4A90E2),
            hadith: '"Whoever reads Surah Ikhlas 10 times, Allah builds a palace for him in Jannah.", Musnad Ahmad',
            breakdown: 'Each 10 recitations of Surah Al-Ikhlas earns one palace.\n\n'
                'Before sleep (Ikhlas ×3): ${_fmt(_phraseCounts['sleeping_ikhlas'] ?? 0)}\n'
                'Morning Ikhlas: ${_fmt(_phraseCounts['morning_9'] ?? 0)}\n'
                'Evening Ikhlas: ${_fmt(_phraseCounts['evening_9'] ?? 0)}\n'
                'Total Ikhlas recitations: ${_fmt(_ikhlasCount)}\n'
                'Divided by 10 → palaces: ${_fmt(_palacesBuilt)}',
          ),
        ),
        _HoldingRow(
          icon: NoorIcon.diamond(size: 24),
          color: const Color(0xFF9B59B6),
          bgColor: const Color(0xFFF5EEF8),
          title: AppLocalizations.of(context)?.treasuresOfJannah ?? 'Treasures of Jannah',
          subtitle: AppLocalizations.of(context)?.laHawlaSubtitle ??
              'La Hawla Wa La Quwwata',
          value: _treasures,
          change: AppLocalizations.of(context)
                  ?.holdingChangeEarned(_fmt(_treasures)) ??
              '${_fmt(_treasures)} earned',
          positive: true,
          isFirst: false,
          isLast: false,
          onTap: () => _showHoldingDetail(
            title: 'Treasures of Jannah',
            value: _treasures,
            color: const Color(0xFF9B59B6),
            hadith: '"La hawla wa la quwwata illa billah is a treasure from the treasures of Jannah.", Bukhari 4205, Muslim 2704',
            breakdown: 'Each recitation of "La hawla wa la quwwata illa billah" earns one treasure.\n\n'
                '"La hawla" (standalone): ${_fmt(_phraseCounts['la_hawla'] ?? 0)}\n'
                '"Tawakkaltu... wa la hawla": ${_fmt(_phraseCounts['iman_tawakkul'] ?? 0)}\n'
                'Total treasures: ${_fmt(_treasures)}',
          ),
        ),
        _HoldingRow(
          icon: NoorIcon.chains(size: 24),
          color: _C.purple,
          bgColor: const Color(0xFFEEEAF8),
          title: AppLocalizations.of(context)?.slavesFreedom ?? 'Slaves Freed',
          subtitle: AppLocalizations.of(context)?.equivalentRewardEarned ??
              'Equivalent reward earned',
          value: _slavesFreed,
          change: AppLocalizations.of(context)
                  ?.equivalentChange(_fmt(_slavesFreed)) ??
              '${_fmt(_slavesFreed)} equivalent',
          positive: true,
          isFirst: false,
          isLast: false,
          onTap: () => _showHoldingDetail(
            title: 'Slaves Freed',
            value: _slavesFreed,
            color: _C.purple,
            hadith: '"Whoever says La ilaha illallahu wahdahu la sharika lahu, lahul-mulku wa lahul-hamdu wa huwa ala kulli shay\'in qadir 10 times, it is as if he freed 4 slaves from the children of Ismail.", Bukhari 6403',
            breakdown: 'Every 10 recitations of "La ilaha illallahu wahdahu la sharika lahu..." equals freeing 4 slaves.\n\n'
                'Post-prayer: ${_fmt(_phraseCounts['post_prayer_la_ilaha'] ?? 0)}\n'
                'Upon waking: ${_fmt(_phraseCounts['waking_up_2'] ?? 0)}\n'
                'Morning azkar (item 31): ${_fmt(_phraseCounts['morning_31'] ?? 0)}\n'
                'Evening azkar (item 30): ${_fmt(_phraseCounts['evening_30'] ?? 0)}\n'
                'Total recitations: ${_fmt(_slavesPhraseCount)}\n'
                'Sets of 10 → ${_fmt(_slavesPhraseCount ~/ 10)} sets × 4 slaves = ${_fmt(_slavesFreed)}',
          ),
        ),
        _HoldingRow(
          icon: NoorIcon.kaaba(size: 24),
          color: const Color(0xFFD4A017),
          bgColor: const Color(0xFFFFF8E1),
          title: AppLocalizations.of(context)?.gatesOfParadise ??
              'Gates of Paradise',
          subtitle: AppLocalizations.of(context)?.afterPerfectWudu ??
              'After perfect wudu',
          value: _gatesOpened,
          change: AppLocalizations.of(context)
                  ?.holdingChangeOpened(_fmt(_gatesOpened)) ??
              '${_fmt(_gatesOpened)} opened',
          positive: true,
          isFirst: false,
          isLast: false,
          onTap: () => _showHoldingDetail(
            title: 'Gates of Paradise Opened',
            value: _gatesOpened,
            color: const Color(0xFFD4A017),
            hadith: '"None of you performs wudu and completes it perfectly, then says: Ashhadu an la ilaha illallahu wahdahu la sharika lah, wa ashhadu anna Muhammadan abduhu wa rasuluh, except that all eight gates of Paradise will be opened for him, and he may enter from whichever one he wishes.", Sahih Muslim 234',
            breakdown: 'Each post-wudu shahadah opens all 8 gates of Paradise.\n\n'
                'Post-wudu shahadah recited: ${_fmt(_wuduShahadaCount)}\n'
                'Multiplied by 8 gates → ${_fmt(_gatesOpened)} openings',
          ),
        ),
        _HoldingRow(
          icon: NoorIcon.heart(size: 24),
          color: const Color(0xFFE91E63),
          bgColor: const Color(0xFFFCE4EC),
          title: AppLocalizations.of(context)?.blessingsFromAllah ??
              'Blessings from Allah',
          subtitle: AppLocalizations.of(context)?.salawatTenReturned ??
              'Salawat × 10 returned',
          value: _blessingsReceived,
          change: AppLocalizations.of(context)
                  ?.receivedChange(_fmt(_blessingsReceived)) ??
              '${_fmt(_blessingsReceived)} received',
          positive: true,
          isFirst: false,
          isLast: false,
          onTap: () => _showHoldingDetail(
            title: 'Blessings from Allah',
            value: _blessingsReceived,
            color: const Color(0xFFE91E63),
            hadith: '"Whoever sends one blessing upon me, Allah sends ten blessings upon him.", Sahih Muslim 408',
            breakdown: 'For every salawat (durood) you send upon the Prophet ﷺ, Allah returns ten upon you.\n\n'
                'Salawat Ibrahimiyya: ${_fmt(_phraseCounts['salawat_ibrahimiyya'] ?? 0)}\n'
                'Short salawat: ${_fmt(_phraseCounts['salawat_simple'] ?? 0)}\n'
                'Friday salawat: ${_fmt(_phraseCounts['salawat_friday'] ?? 0)}\n'
                'Evening durood (item 32): ${_fmt(_phraseCounts['evening_32'] ?? 0)}\n'
                'Total salawat sent: ${_fmt(_salawatCount)}\n'
                'Multiplied by 10 → ${_fmt(_blessingsReceived)} blessings received',
          ),
        ),
        _HoldingRow(
          icon: NoorIcon.shield(size: 24),
          color: const Color(0xFF455A64),
          bgColor: const Color(0xFFECEFF1),
          title: AppLocalizations.of(context)?.timesProtected ??
              'Times Protected',
          subtitle: AppLocalizations.of(context)?.refugeInvokedFromHarm ??
              'Refuge invoked from harm',
          value: _protectionInvocations,
          change: AppLocalizations.of(context)
                  ?.holdingChangeInvocations(_fmt(_protectionInvocations)) ??
              '${_fmt(_protectionInvocations)} invocations',
          positive: true,
          isFirst: false,
          isLast: false,
          onTap: () => _showHoldingDetail(
            title: 'Times Protected',
            value: _protectionInvocations,
            color: const Color(0xFF455A64),
            hadith: '"Whoever recites Ayat al-Kursi before sleeping, a guardian from Allah will protect him and Shaytan will not come near him until morning.", Bukhari 2311\n\n'
                '"Whoever says A\'udhu bi-kalimatillahit-tammati min sharri ma khalaq three times when arriving at a place, nothing will harm him until he leaves.", Muslim 2708\n\n'
                '"Recite Qul Huwa Allahu Ahad and the Mu\'awwidhatayn three times morning and evening, they will suffice you against everything.", Abu Dawud 5082',
            breakdown: 'Each protection-invoking azkar adds one to your shield.\n\n'
                'Ayat al-Kursi before sleep: ${_fmt(_phraseCounts['sleeping_ayat_kursi'] ?? 0)}\n'
                'Ayat al-Kursi after prayer: ${_fmt(_phraseCounts['post_prayer_ayat_kursi'] ?? 0)}\n'
                'Home protection (A\'udhu bi-kalimat): ${_fmt(_phraseCounts['home_protection'] ?? 0)}\n'
                'Mu\'awwidhatayn (Falaq + Nas): ${_fmt(_phraseCounts['iman_falaq_nas'] ?? 0)}\n'
                'Morning/Evening "Protect from harm" (21): ${_fmt((_phraseCounts['morning_21'] ?? 0) + (_phraseCounts['evening_21'] ?? 0))}\n'
                'Morning/Evening "Protection from evil" (23): ${_fmt((_phraseCounts['morning_23'] ?? 0) + (_phraseCounts['evening_23'] ?? 0))}\n'
                'Morning/Evening "Good health & protection" (28): ${_fmt((_phraseCounts['morning_28'] ?? 0) + (_phraseCounts['evening_28'] ?? 0))}\n\n'
                'Total invocations: ${_fmt(_protectionInvocations)}',
          ),
        ),
        _HoldingRow(
          icon: NoorIcon.greenBook(size: 24),
          color: const Color(0xFF2E7D32),
          bgColor: const Color(0xFFE8F5E9),
          title: AppLocalizations.of(context)?.quranCompletions ??
              'Quran Completions',
          subtitle: AppLocalizations.of(context)?.viaSurahIkhlas ??
              'Via Surah Al-Ikhlas ×3',
          value: _quranCompletionsViaIkhlas,
          change: AppLocalizations.of(context)
                  ?.equivalentChange(_fmt(_quranCompletionsViaIkhlas)) ??
              '${_fmt(_quranCompletionsViaIkhlas)} equivalent',
          positive: true,
          isFirst: false,
          isLast: false,
          onTap: () => _showHoldingDetail(
            title: 'Quran Completions',
            value: _quranCompletionsViaIkhlas,
            color: const Color(0xFF2E7D32),
            hadith: '"Reciting Qul Huwa Allahu Ahad (Surah Al-Ikhlas) three times equals reciting the entire Quran.", Sahih Bukhari 5017',
            breakdown: 'Every three Ikhlas recitations equal one complete recitation of the Qur\'an.\n\n'
                'Before sleep (item recites ×3): ${_fmt(_phraseCounts['sleeping_ikhlas'] ?? 0)}\n'
                'Morning Ikhlas: ${_fmt(_phraseCounts['morning_9'] ?? 0)}\n'
                'Evening Ikhlas: ${_fmt(_phraseCounts['evening_9'] ?? 0)}\n'
                'Total Ikhlas recitations: ${_fmt(_ikhlasCount)}\n'
                'Divided by 3 → ${_fmt(_quranCompletionsViaIkhlas)} Quran completions',
          ),
        ),
        if (_shoppingDuaCount > 0)
          _HoldingRow(
            icon: NoorIcon.trophy(size: 24),
            color: const Color(0xFFB8860B),
            bgColor: const Color(0xFFFFFBE6),
            title: AppLocalizations.of(context)?.bonusHasanaat ??
                'Bonus Hasanaat',
            subtitle: AppLocalizations.of(context)?.marketplaceDua ??
                "Marketplace du'a",
            value: _millionHasanaat,
            change: AppLocalizations.of(context)
                    ?.holdingChangeRecitations(_fmt(_shoppingDuaCount)) ??
                '${_fmt(_shoppingDuaCount)} recitations',
            positive: true,
            isFirst: false,
            isLast: false,
            onTap: () => _showHoldingDetail(
              title: 'Bonus Million Hasanaat',
              value: _millionHasanaat,
              color: const Color(0xFFB8860B),
              hadith: '"Whoever enters the marketplace and says: La ilaha illallahu wahdahu la sharika lahu, lahul-mulku wa lahul-hamdu, yuhyi wa yumitu, wa Huwa hayyun la yamut, biyadihil-khayr, wa Huwa ala kulli shay\'in Qadir, Allah will write for him a million good deeds, erase a million of his bad deeds, and raise him a million levels.", Ibn Majah 2235',
              breakdown: 'Each recitation of the marketplace du\'a writes 1,000,000 good deeds.\n\n'
                  'Times recited: ${_fmt(_shoppingDuaCount)}\n'
                  'Bonus hasanaat: ${_fmt(_millionHasanaat)}',
            ),
          ),
        _HoldingRow(
          icon: NoorIcon.hands(size: 24),
          color: const Color(0xFFE67E22),
          bgColor: const Color(0xFFFEF5E7),
          title: AppLocalizations.of(context)?.sadaqahGiven ?? 'Sadaqah Given',
          subtitle: AppLocalizations.of(context)?.seedsDonatedToCommunity ??
              'Seeds donated to community',
          value: _totalDonated,
          change: AppLocalizations.of(context)?.allTimeLabel ?? 'All time',
          positive: true,
          isFirst: false,
          isLast: true,
          onTap: () => _showHoldingDetail(
            title: 'Sadaqah Given',
            value: _totalDonated,
            color: const Color(0xFFE67E22),
            hadith: '"Sadaqah does not decrease wealth.", Muslim 2588',
            breakdown: 'Seeds you donated to community projects in the app.\n\nTotal donated: ${_fmt(_totalDonated)} ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
          ),
        ),
      ];
    // Sort highest-value holdings first so the user sees their biggest
    // rewards at the top of the list.
    rows.sort((a, b) => b.value.compareTo(a.value));
    return rows;
  }

  // Builds the personalized "today" badge text under the monthly stats.
  // Rules:
  //   • Ayahs only → "Read N ayahs today"
  //   • Mushaf/time only → "Spent Xm reading Quran today"
  //   • Both → "Read N ayahs · Xm reading Quran today"
  // Caller already guarantees at least one is > 0 before showing the badge.
  String _todayBadgeText() {
    final liveQuranSec =
        _todayQuranSec + StatsService.instance.optimisticTodaySec;
    final mins = liveQuranSec ~/ 60;
    final secs = liveQuranSec % 60;
    String timePart() {
      if (mins == 0 && secs > 0) return '${secs}s';
      if (mins > 0 && secs >= 30) return '${mins + 1}m';
      return '${mins}m';
    }

    final hasAyahs = _todayAyahs > 0;
    final hasTime = liveQuranSec > 0;
    final l = AppLocalizations.of(context);
    if (hasAyahs && hasTime) {
      return l?.readAyahsPlusTimeToday(_todayAyahs, timePart()) ??
          'Read ${_fmt(_todayAyahs)} ayah${_todayAyahs == 1 ? '' : 's'} plus ${timePart()} reading Quran today';
    }
    if (hasAyahs) {
      return l?.readAyahsToday(_todayAyahs) ??
          'Read ${_fmt(_todayAyahs)} ayah${_todayAyahs == 1 ? '' : 's'} today';
    }
    return l?.spentTimeReadingQuranToday(timePart()) ??
        'Spent ${timePart()} reading Quran today';
  }

  // ── Activity card (session time) ───────────────────────────────────────────
  // ── Monthly stats card ──────────────────────────────────────────────────
  Widget _buildMonthlyStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Y4.honey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Y4.honeyDeep,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.yourMonth ?? 'Your Month',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _C.text,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats grid
          Row(
            children: [
              Expanded(
                child: _MonthStat(
                  label: AppLocalizations.of(context)?.ayahsReadLabel ?? 'Ayahs Read',
                  value: _fmt(_monthAyahs),
                  delta: '',
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF2BAE99),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MonthStat(
                  label: AppLocalizations.of(context)?.dhikrCount ?? 'Dhikr Count',
                  value: _fmt(_monthDhikrCount),
                  delta: '',
                  icon: Icons.spa_rounded,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MonthStat(
                  label: AppLocalizations.of(context)?.quranTime ?? 'Quran Time',
                  value: MonthlyStats.formatDuration(
                      _monthQuranTimeSec +
                          StatsService.instance.optimisticTodaySec),
                  delta: '',
                  icon: Icons.timer_outlined,
                  color: const Color(0xFFE67E22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MonthStat(
                  label: AppLocalizations.of(context)?.dhikrTime ?? 'Dhikr Time',
                  value: MonthlyStats.formatDuration(_monthDhikrTimeSec),
                  delta: '',
                  icon: Icons.access_time_rounded,
                  color: const Color(0xFF9B59B6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MonthStat(
                  label: AppLocalizations.of(context)?.activeDays ?? 'Active Days',
                  value: '$_monthActiveDays',
                  delta: '',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF2D7A45),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MonthStat(
                  label: AppLocalizations.of(context)?.totalPoints ?? 'Total Seeds',
                  value: _fmt(_monthPoints),
                  delta: '',
                  icon: Icons.star_rounded,
                  iconWidget: const SabiqCoin(size: 18),
                  color: Y4.honeyDeep,
                ),
              ),
            ],
          ),
          // Personalized "today" badge — only shown when the user has
          // recorded ayahs read and/or time in the Quran screen today.
          if (_todayAyahs > 0 ||
              _todayQuranSec + StatsService.instance.optimisticTodaySec > 0) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Y4.honey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Y4.honey.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded,
                      size: 16, color: Y4.honeyDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _todayBadgeText(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Y4.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    // Labels for the 7-day window (oldest → newest). The newest entry is
    // today, so we compute labels by walking back from today's weekday.
    final todayWd = DateTime.now().weekday; // 1=Mon … 7=Sun
    const weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final days = List<String>.generate(7, (i) {
      // window position i (0..6) corresponds to (today - (6 - i)) days
      final wd = ((todayWd - 1 - (6 - i)) % 7 + 7) % 7;
      return weekdayLetters[wd];
    });
    // Apply the optimistic counter to today's seconds so the chart updates
    // instantly after a flush, before the RPC and re-fetch finish.
    final optimistic = StatsService.instance.optimisticTodaySec;
    final adjustedTimes = List<int>.from(_weekDayTimes);
    if (adjustedTimes.isNotEmpty) {
      adjustedTimes[adjustedTimes.length - 1] =
          adjustedTimes.last + optimistic;
    }
    final selectedSec = (_selectedDay >= 0 && _selectedDay < adjustedTimes.length)
        ? adjustedTimes[_selectedDay]
        : 0;
    final hours = selectedSec ~/ 3600;
    final mins = (selectedSec % 3600) ~/ 60;
    final maxSec = adjustedTimes.fold<int>(0, math.max);
    final bars = adjustedTimes
        .map((s) => maxSec == 0 ? 0.0 : (s / maxSec).clamp(0.0, 1.0))
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _C.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.show_chart_rounded, color: _C.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.worshipActivity ??
                        'Worship Activity',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _C.text,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)?.timeSpentInRemembrance ??
                        'Time spent in remembrance',
                    style: GoogleFonts.outfit(fontSize: 11, color: _C.sub),
                  ),
                ],
              ),
              const Spacer(),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${hours}h ',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _C.teal,
                      ),
                    ),
                    TextSpan(
                      text: '${mins}m',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _C.sub,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              7,
              (i) => _DayBar(
                days[i],
                bars[i],
                highlight: i == _selectedDay,
                onTap: () => setState(() => _selectedDay = i),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Rewards card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildRewardsCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Y4.cream, Y4.honey.withValues(alpha: 0.30), Y4.bg],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Y4.honey.withValues(alpha: 0.35)),
      boxShadow: [
        BoxShadow(
          color: Y4.honey.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            NoorIcon.sparkles(size: 22),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)?.noorPointsSummary ??
                  'Sabiq Seeds Summary',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Y4.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _DarkStat(
                AppLocalizations.of(context)?.totalPoints ?? 'Total Seeds',
                _fmt(_noorPoints),
                const SabiqCoin(size: 16),
              ),
            ),
            Container(height: 44, width: 1, color: Y4.honey.withValues(alpha: 0.4)),
            Expanded(
              child: _DarkStat('Level', '$_level', NoorIcon.medal(size: 16)),
            ),
            Container(height: 44, width: 1, color: Y4.honey.withValues(alpha: 0.4)),
            Expanded(
              child: _DarkStat(
                AppLocalizations.of(context)?.title ?? 'Title',
                _localizedTitle(),
                NoorIcon.crown(size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Y4.honey.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Y4.honey.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              AppLocalizations.of(context)?.everyDeedRecordedKeepGoing ??
                  '🌙  Every deed is recorded. Keep going!',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Y4.inkSoft,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ——————————————————————————————————————————————————————————————————————————
// Community Impact Page (previously embedded _ImpactTab)
// Navigated to from the Akhirah Balance tab
// ——————————————————————————————————————————————————————————————————————————
/// One donor's aggregated contribution to a single project — their summed
/// total, the number of separate gifts, and when they last gave.
class _DonorAgg {
  final String displayName;
  final String? avatarUrl;
  int total;
  final DateTime lastDonatedAt;
  _DonorAgg({
    required this.displayName,
    required this.avatarUrl,
    required this.total,
    required this.lastDonatedAt,
  });
}

class CommunityImpactPage extends StatefulWidget {
  final String? scrollToProjectId;
  final bool isTab;
  const CommunityImpactPage({
    super.key,
    this.scrollToProjectId,
    this.isTab = false,
  });
  @override
  State<CommunityImpactPage> createState() => _CommunityImpactPageState();
}

class _CommunityImpactPageState extends State<CommunityImpactPage> {
  List<Map<String, dynamic>> _projects = [];
  Map<String, List<ProjectMedia>> _projectMedia = {};
  Map<String, List<ProjectDonation>> _projectDonors = {};
  // Authoritative distinct-donor count per project (SECURITY DEFINER RPC,
  // unaffected by Row-Level Security on user_donations).
  Map<String, int> _donorCounts = {};
  int _myAvailablePoints = 0;
  List<Orphan> _orphans = const [];
  // Aggregated "Your Giving" footer stats
  int _myTotalSeedsLifetime = 0;
  int _myProjectsSupportedCount = 0;
  int _myOrphansSponsoredCount = 0;
  bool _loading = true;
  final Map<String, GlobalKey> _projectKeys = {};
  // Project ids whose donor list is expanded (showing all rows).
  final Set<String> _expandedDonors = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;

      // ── Wave 1 ───────────────────────────────────────────────────────────
      // 7 independent queries — fire them all at once. Was 9 sequential
      // round-trips on first load (~2.5s on a slow connection); now ~2.
      // Each future is wrapped so one failing won't poison the rest.
      final w1 = await Future.wait<dynamic>([
        // 0: active projects
        sb
            .from('community_projects')
            .select()
            .eq('is_active', true)
            .order('sort_order', ascending: true, nullsFirst: false)
            .then<List<dynamic>>((v) => v as List)
            .catchError((e) {
              debugPrint('community_projects load error: $e');
              return const <dynamic>[];
            }),
        // 1: community totals per project (SECURITY DEFINER RPC)
        sb
            .rpc('get_project_seed_totals')
            .then<List<dynamic>>((v) => v as List)
            .catchError((e) {
              debugPrint('Project totals RPC error: $e');
              return const <dynamic>[];
            }),
        // 2: my donations per project (only when signed in)
        uid == null
            ? Future.value(const <dynamic>[])
            : sb
                .rpc('get_my_project_donations', params: {'p_user_id': uid})
                .then<List<dynamic>>((v) => v as List)
                .catchError((e) {
                  debugPrint('My donations RPC error: $e');
                  return const <dynamic>[];
                }),
        // 3: my available Seeds balance
        uid == null
            ? Future<Map<String, dynamic>?>.value(null)
            : sb
                .from('profiles')
                .select('noor_points')
                .eq('id', uid)
                .maybeSingle()
                .then<Map<String, dynamic>?>((v) => v)
                .catchError((_) => null),
        // 4: distinct-donor counts (RLS-safe RPC)
        DonationService.instance.getProjectDonorCounts(),
        // 5: sponsored orphans + their aggregate stats
        DonationService.instance.getOrphans(),
        // 6: my orphan sponsorships (for the footer totals)
        uid == null
            ? Future.value(const <Map<String, dynamic>>[])
            : DonationService.instance.getUserOrphanSponsorships(),
      ]);

      _projects = List<Map<String, dynamic>>.from(w1[0] as List);
      _donorCounts = w1[4] as Map<String, int>;
      _orphans = w1[5] as List<Orphan>;
      final orphanSponsorships = w1[6] as List<Map<String, dynamic>>;

      final Map<String, int> communityTotals = {};
      for (final r in (w1[1] as List)) {
        final m = r as Map;
        final pid = m['project_id'] as String?;
        if (pid != null) {
          communityTotals[pid] = (m['current_seeds'] as num?)?.toInt() ?? 0;
        }
      }
      final Map<String, int> myDonations = {};
      for (final r in (w1[2] as List)) {
        final m = r as Map;
        final pid = m['project_id'] as String?;
        if (pid != null) {
          myDonations[pid] = (m['my_seeds'] as num?)?.toInt() ?? 0;
        }
      }
      if (uid != null) {
        final profile = w1[3] as Map<String, dynamic>?;
        _myAvailablePoints =
            (profile?['noor_points'] as num?)?.toInt() ?? 0;
      }

      for (var p in _projects) {
        final real = communityTotals[p['id']] ?? 0;
        p['current_points'] = real;
        p['my_points'] = myDonations[p['id']] ?? 0;
        p['is_completed'] =
            real >= ((p['target_points'] as num?)?.toInt() ?? 1);
      }

      // ── Wave 2 ───────────────────────────────────────────────────────────
      // These need the project ids from wave 1. Fire both at once; each has
      // its own internal parallelism for per-project work.
      final pids = _projects.map((p) => p['id'] as String).toList();
      final w2 = await Future.wait<dynamic>([
        DonationService.instance.getMediaForProjects(pids),
        Future.wait(
          pids.map(
            (pid) =>
                DonationService.instance.getProjectDonors(pid, limit: 20),
          ),
        ),
      ]);
      _projectMedia = w2[0] as Map<String, List<ProjectMedia>>;
      final donorLists = w2[1] as List<List<ProjectDonation>>;
      _projectDonors = {
        for (var i = 0; i < pids.length; i++) pids[i]: donorLists[i],
      };

      // ── Footer aggregation (pure CPU, no round-trips) ────────────────────
      _myOrphansSponsoredCount = orphanSponsorships.length;
      int orphanSeeds = 0;
      for (final row in orphanSponsorships) {
        orphanSeeds += (row['total_donated'] as num?)?.toInt() ?? 0;
      }
      int projectSeeds = 0;
      int projectsSupported = 0;
      if (uid != null) {
        for (final p in _projects) {
          final my = (p['my_points'] as num?)?.toInt() ?? 0;
          if (my > 0) {
            projectSeeds += my;
            projectsSupported++;
          }
        }
      }
      _myTotalSeedsLifetime = orphanSeeds + projectSeeds;
      _myProjectsSupportedCount = projectsSupported;
    } catch (e, st) {
      // Surfaced in dev so regressions show up instantly. No-op in release.
      debugPrint('CauseTab _load failed: $e');
      debugPrintStack(stackTrace: st);
    }
    if (mounted) {
      setState(() => _loading = false);
      // Warm the image cache for every project's media as soon as the
      // list is rendered. Users said the first paint of a carousel takes
      // too long; precaching here means by the time they scroll to a
      // project card or open its carousel, the bytes are already in
      // memory + on disk. Runs in the next frame so it never blocks the
      // initial paint of the list itself.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final media in _projectMedia.values) {
          for (final m in media) {
            if (m.isVideo) continue;
            precacheImage(
              CachedNetworkImageProvider(m.url),
              context,
              onError: (_, __) {},
            );
          }
        }
      });
      // Scroll to specific project if requested
      if (widget.scrollToProjectId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final key = _projectKeys[widget.scrollToProjectId];
          if (key?.currentContext != null) {
            Scrollable.ensureVisible(
              key!.currentContext!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              alignment: 0.1,
            );
          }
        });
      }
    }
  }

  String _fmt(num n) =>
      n >= 1000000
          ? '${(n / 1000000).toStringAsFixed(1)}M'
          : n >= 1000
          ? '${(n / 1000).toStringAsFixed(1)}k'
          : '$n';

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  // Recent-donors card shown inside each project: "X contributors" header
  // + up to 3 donor rows (avatar, name, last-gave time, total pill).
  // One row per person — repeat donations are aggregated.
  Widget _buildDonorsBlock(String pid) {
    final raw = _projectDonors[pid] ?? const <ProjectDonation>[];
    if (raw.isEmpty) return const SizedBox.shrink();
    // Collapse to one entry per person: sum their total, count their
    // gifts, keep their most-recent donation time. `raw` arrives
    // newest-first, so the first sighting of a user is their latest gift.
    final byUser = <String, _DonorAgg>{};
    for (final d in raw) {
      final e = byUser[d.userId];
      if (e == null) {
        byUser[d.userId] = _DonorAgg(
          displayName: d.displayName,
          avatarUrl: d.avatarUrl,
          total: d.amount,
          lastDonatedAt: d.donatedAt,
        );
      } else {
        e.total += d.amount;
      }
    }
    final donors = byUser.values.toList()
      ..sort((a, b) => b.lastDonatedAt.compareTo(a.lastDonatedAt));
    final expanded = _expandedDonors.contains(pid);
    final preview = expanded ? donors : donors.take(3).toList();
    final extra = donors.length - 3;
    // Header count comes from the RLS-safe RPC (true distinct donors),
    // not the donor list length (which is capped at the fetch limit).
    final count = _donorCounts[pid] ?? donors.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Y4.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people_alt_rounded,
                size: 16,
                color: Y4.honeyDeep,
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)?.contributorCount(count) ??
                    '$count ${count == 1 ? 'contributor' : 'contributors'}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _C.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < preview.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _impactDonorRow(preview[i]),
          ],
          if (extra > 0) ...[
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => setState(() {
                  if (expanded) {
                    _expandedDonors.remove(pid);
                  } else {
                    _expandedDonors.add(pid);
                  }
                }),
                child: Ink(
                  decoration: BoxDecoration(
                    color: Y4.honey.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Y4.honeyDeep.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          expanded
                              ? (AppLocalizations.of(context)?.showLess ??
                                  'Show less')
                              : (AppLocalizations.of(context)
                                      ?.viewAllDonors(donors.length) ??
                                  'View all ${donors.length} donors'),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Y4.honeyDeep,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Y4.honeyDeep,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _impactDonorRow(_DonorAgg d) {
    final localName = localizeName(context, d.displayName);
    final initial = localName.trim().isEmpty
        ? '?'
        : localName.trim().substring(0, 1).toUpperCase();
    final subtitle = _timeAgo(d.lastDonatedAt);
    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 40,
            height: 40,
            child: d.avatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: d.avatarUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _donorInitial(initial),
                    errorWidget: (_, __, ___) => _donorInitial(initial),
                  )
                : _donorInitial(initial),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _C.text,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: _C.sub,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Total donated by this person to this project.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Y4.honey.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Y4.honeyDeep.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SabiqCoin(size: 20),
              const SizedBox(width: 5),
              Text(
                _fmt(d.total),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Y4.honeyDeep,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _donorInitial(String initial) {
    return Container(
      color: Y4.honey.withValues(alpha: 0.25),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Y4.honeyDeep,
        ),
      ),
    );
  }

  void _showDonateSheet(Map<String, dynamic> project) {
    int selected = 50;
    showModalBottomSheet(
      context: context,
      // Use the root navigator so the sheet overlays the dashboard's bottom
      // navigation bar. Without this, the Cause-tab navigator clips the
      // sheet and the Donate CTA hides behind the bottom nav.
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLocal) => Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                    top: 24,
                    left: 24,
                    right: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        proj_l10n.projectTitle(context, project),
                        style: proj_l10n.localeAwareStyle(
                          context,
                          GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _C.text,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your available: ${_fmt(_myAvailablePoints)} ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                        style: GoogleFonts.outfit(fontSize: 13, color: _C.sub),
                      ),
                      const SizedBox(height: 20),
                      // Quick amount chips
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children:
                            [50, 100, 250, 500, 1000].map((amt) {
                              final sel = selected == amt;
                              return GestureDetector(
                                onTap: () => setLocal(() => selected = amt),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sel ? Y4.honeyDeep : _C.bg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: sel ? Y4.honeyDeep : _C.border,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SabiqCoin(size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$amt ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w700,
                                          color:
                                              sel ? Colors.white : _C.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Y4.butter, Y4.honey],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Y4.honeyDeep.withValues(alpha: 0.30),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Y4.ink,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed:
                                _myAvailablePoints < selected
                                    ? null
                                    : () async {
                                      Navigator.pop(ctx);
                                      try {
                                        final sb = Supabase.instance.client;
                                        final uid = sb.auth.currentUser?.id;
                                        if (uid == null) return;
                                        await sb.rpc(
                                          'donate_to_project',
                                          params: {
                                            'p_user_id': uid,
                                            'p_project_id': project['id'],
                                            'p_amount': selected,
                                          },
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'JazakAllah! ${_fmt(selected)} ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'} donated 🤲',
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              backgroundColor: Y4.honeyDeep,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                          setState(() => _loading = true);
                                          await _load();
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Failed: $e'),
                                              backgroundColor: _C.rose,
                                            ),
                                          );
                                        }
                                      }
                                    },
                            child: _myAvailablePoints < selected
                                ? Text(
                                    AppLocalizations.of(context)?.notEnoughSeeds ?? 'Insufficient Seeds',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Y4.ink,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SabiqCoin(size: 22),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Donate $selected ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'} 🤲',
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Y4.ink,
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
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        // Honey-wash app bar to match the rest of the app's theme (was
        // Y4.honeyDeep — too dark and saturated against the cream bg).
        backgroundColor: Y4.bg,
        surfaceTintColor: Y4.bg,
        foregroundColor: Y4.ink,
        title: Text(
          AppLocalizations.of(context)?.everyRecitationCanChangeLife ??
              'Every Recitation Can\nChange a Life',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            color: Y4.ink,
            fontSize: 14,
          ),
          maxLines: 2,
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Y4.ink),
      ),
      body:
          _loading
              ? const Center(child: NoorInlineLoader())
              : _buildCausePage(),
    );
  }

  // ── Cause page composition ────────────────────────────────────────────────
  // Hero (1 featured) → "Sponsor an Orphan" section → "Active Campaigns"
  // section → "Your Giving" footer. Each section owns its own header.
  Widget _buildCausePage() {
    final rows = <Widget>[];

    // 1. Hero — first orphan if any, else first non-completed project.
    final hero = _pickHero();
    if (hero != null) rows.add(hero);

    // 2. Sponsor an Orphan
    if (_orphans.isNotEmpty) {
      rows.add(_sectionHeader(
        title: AppLocalizations.of(context)?.sponsorAnOrphan ??
            'Sponsor an Orphan',
        subtitle: AppLocalizations.of(context)?.realChildrenSubtitle ??
            'Real children, their stories, their lives',
        actionLabel: _orphans.length > 1
            ? (AppLocalizations.of(context)?.seeAllAction ?? 'See all')
            : null,
        onAction: () => OrphansStrip.openGrid(
          context,
          availablePoints: _myAvailablePoints,
          onChanged: _load,
        ),
      ));
      rows.add(
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(bottom: 16),
          child: OrphansStrip(
            orphans: _orphans,
            availablePoints: _myAvailablePoints,
            onChanged: _load,
          ),
        ),
      );
      rows.add(_thinDivider());
    }

    // 3. Active Campaigns
    if (_projects.isNotEmpty) {
      rows.add(_sectionHeader(
        title: AppLocalizations.of(context)?.activeCampaigns ??
            'Active Campaigns',
        subtitle: AppLocalizations.of(context)?.poolSeedsImpact ??
            'Pool your Seeds toward lasting impact',
      ));
      for (int i = 0; i < _projects.length; i++) {
        rows.add(_buildProjectRow(_projects[i]));
        if (i < _projects.length - 1) rows.add(_thinDivider());
      }
      rows.add(_thinDivider());
    }

    // 4. Your Giving footer
    rows.add(_yourGivingFooter());

    return ListView.builder(
      padding: EdgeInsets.only(bottom: widget.isTab ? 100 : 0),
      itemCount: rows.length,
      itemBuilder: (_, i) => rows[i],
    );
  }

  Widget _thinDivider() => const Divider(
        height: 1, thickness: 1, color: Color(0xFFEEEEEE),
      );

  // ── Hero card ────────────────────────────────────────────────────────────
  Widget? _pickHero() {
    if (_orphans.isNotEmpty) {
      return _heroOrphan(_orphans.first);
    }
    final firstActive = _projects.cast<Map<String, dynamic>?>().firstWhere(
          (p) => p?['is_completed'] != true,
          orElse: () => null,
        );
    if (firstActive != null) return _heroProject(firstActive);
    return null;
  }

  Widget _heroOrphan(Orphan o) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: GestureDetector(
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => OrphanDetailScreen(
              orphan: o,
              availablePoints: _myAvailablePoints,
              onSponsored: (_) => _load(),
            ),
          ));
          _load();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 260,
            decoration: BoxDecoration(color: Y4.butter),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (o.photoUrl != null && o.photoUrl!.isNotEmpty)
                  CachedNetworkImage(imageUrl: o.photoUrl!, fit: BoxFit.cover)
                else
                  Container(
                    color: Y4.butter,
                    alignment: Alignment.center,
                    child: Icon(Icons.person_rounded,
                        size: 80, color: Y4.honeyDeep.withValues(alpha: 0.5)),
                  ),
                // Bottom gradient for legible text overlay
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.35, 1.0],
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                ),
                // Top-left pill
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.featuredSponsorChild ??
                          'Featured · Sponsor a child',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Y4.honeyDeep,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                // Bottom-left text + CTA
                Positioned(
                  left: 16, right: 16, bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                                ?.meetOrphanAge(
                                  localizeName(context, o.firstName),
                                  o.age,
                                ) ??
                            'Meet ${localizeName(context, o.firstName)}, ${o.age}',
                        style: GoogleFonts.fraunces(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                      if (o.displayLocation != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          o.displayLocation!,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: Y4.honey,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          AppLocalizations.of(context)
                                  ?.sponsorNameArrow(
                                    localizeName(context, o.firstName),
                                  ) ??
                              'Sponsor ${localizeName(context, o.firstName)} →',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Y4.ink,
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

  Widget _heroProject(Map<String, dynamic> p) {
    final cur = (p['current_points'] as num?)?.toInt() ?? 0;
    final tgt = (p['target_points'] as num?)?.toInt() ?? 1;
    final pct = (cur / tgt).clamp(0.0, 1.0);
    final dpUrl = (p['dp_url'] as String?) ?? '';
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: GestureDetector(
        onTap: () => _showDonateSheet(p),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 260,
            decoration: BoxDecoration(color: Y4.butter),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (dpUrl.isNotEmpty)
                  CachedNetworkImage(imageUrl: dpUrl, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.35, 1.0],
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                ),
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.featuredCampaign ??
                          'Featured Campaign',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Y4.honeyDeep,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16, right: 16, bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proj_l10n.projectTitle(context, p),
                        style: proj_l10n.localeAwareStyle(
                          context,
                          GoogleFonts.fraunces(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          valueColor:
                              const AlwaysStoppedAnimation(Y4.honey),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(pct * 100).round()}% funded',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
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

  // ── Section header (used by both orphan + campaign sections) ─────────────
  Widget _sectionHeader({
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _C.text,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: Y4.inkSoft,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  '$actionLabel →',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Y4.honeyDeep,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── "Your Giving" footer ─────────────────────────────────────────────────
  Widget _yourGivingFooter() {
    final hasGiving = _myTotalSeedsLifetime > 0;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Y4.cream, Y4.butter],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Y4.honey.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💝', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)?.yourGiving ?? 'Your Giving',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Y4.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!hasGiving)
              Text(
                AppLocalizations.of(context)?.havenNotGivenYet ??
                    "You haven't given yet. Pick someone above to begin your journey of impact.",
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Y4.inkSoft,
                  height: 1.4,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _statTile(
                      _fmt(_myTotalSeedsLifetime),
                      AppLocalizations.of(context)?.seedsDonatedLabel ??
                          'Seeds donated',
                      // localized via key
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Y4.honey.withValues(alpha: 0.5),
                  ),
                  Expanded(
                    child: _statTile(
                      '$_myOrphansSponsoredCount',
                      AppLocalizations.of(context)?.orphanCount(
                            _myOrphansSponsoredCount,
                          ) ??
                          (_myOrphansSponsoredCount == 1 ? 'Orphan' : 'Orphans'),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Y4.honey.withValues(alpha: 0.5),
                  ),
                  Expanded(
                    child: _statTile(
                      '$_myProjectsSupportedCount',
                      AppLocalizations.of(context)?.projectCount(
                            _myProjectsSupportedCount,
                          ) ??
                          (_myProjectsSupportedCount == 1
                              ? 'Project'
                              : 'Projects'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Y4.honeyDeep,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Y4.inkSoft,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── Existing project card (extracted from itemBuilder) ────────────────────
  Widget _buildProjectRow(Map<String, dynamic> p) {
                  final cur = (p['current_points'] as num?)?.toInt() ?? 0;
                  final tgt = (p['target_points'] as num?)?.toInt() ?? 1;
                  final myPts = (p['my_points'] as num?)?.toInt() ?? 0;
                  final pct = (cur / tgt).clamp(0.0, 1.0);
                  final myPct = (myPts / tgt).clamp(0.0, 1.0);
                  final done = p['is_completed'] == true;
                  final pid = p['id'] as String;
                  _projectKeys.putIfAbsent(pid, () => GlobalKey());
                  return Container(
                    key: _projectKeys[pid],
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          children: [
                            _ImpactProjectCover(project: p),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                proj_l10n.projectTitle(context, p),
                                style: proj_l10n.localeAwareStyle(
                                  context,
                                  GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _C.text,
                                  ),
                                ),
                              ),
                            ),
                            if (done)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _C.gold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '✅ Funded',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _C.gold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          proj_l10n.projectDescription(context, p),
                          style: proj_l10n.localeAwareStyle(
                            context,
                            GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1A1A1A),
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        if ((_projectMedia[p['id']] ?? []).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: ProjectMediaCarousel(
                                media: _projectMedia[p['id']]!,
                                height: 180,
                              ),
                            ),
                          ),

                        // Community progress bar
                        Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)?.communityProgress ??
                                  'Community Progress',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _C.sub,
                              ),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Text(
                                '${_fmt(cur)} / ${_fmt(tgt)} ${AppLocalizations.of(context)?.seedsUnit ?? 'Seeds'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: done ? _C.gold : Y4.honeyDeep,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 9,
                            backgroundColor: Y4.honey.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation(
                              done ? _C.gold : Y4.honey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // My contribution row
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Y4.honey.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Y4.honeyDeep.withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '🤲',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        AppLocalizations.of(context)?.myContributionSeeds(myPts) ?? 'My contribution: ${_fmt(myPts)} Seeds',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Y4.ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Recent donors — name, photo, amount, time.
                        _buildDonorsBlock(pid),

                        // Donate button
                        if (!done)
                          SizedBox(
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Y4.butter, Y4.honey],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Y4.honeyDeep.withValues(alpha: 0.30),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Y4.ink,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () => _showDonateSheet(p),
                                icon: const Text(
                                  '🤲',
                                  style: TextStyle(fontSize: 14),
                                ),
                                label: Text(
                                  AppLocalizations.of(context)?.donateEarnReward ??
                                      'Donate & Earn Reward',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Y4.ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
  }
}
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Arc extends StatelessWidget {
  final double size;
  final Color color;
  const _Arc(this.size, this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _HeroBadge extends StatelessWidget {
  final Widget icon;
  final String label;
  // [bg] paints the pill surface; [fg] colors the border so each badge
  // stays visually distinct. Text is always rendered in [Y4.ink] for
  // strong contrast against the honey hero gradient.
  final Color bg, fg;
  const _HeroBadge(this.icon, this.label, this.bg, this.fg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: fg.withValues(alpha: 0.55), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Y4.ink,
          ),
        ),
      ],
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final Widget icon;
  final String label;
  final int value;
  final Color color;
  const _MiniStat(this.icon, this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.border),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
      ],
    ),
    child: Column(
      children: [
        icon,
        const SizedBox(height: 6),
        _AnimatedNumText(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: _C.sub,
            letterSpacing: 0.8,
          ),
        ),
      ],
    ),
  );
}

class _AnimatedNumText extends StatelessWidget {
  final int value;
  final TextStyle style;
  const _AnimatedNumText(this.value, {required this.style});

  static String fmt(num n) =>
      n >= 1000000
          ? '${(n / 1000000).toStringAsFixed(1)}M'
          : n >= 1000
          ? '${(n / 1000).toStringAsFixed(1)}k'
          : n.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeOutExpo,
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      builder: (context, val, child) {
        return Text(fmt(val), style: style);
      },
    );
  }
}

class _HoldingRow extends StatelessWidget {
  final Widget icon;
  final String title, subtitle, change;
  final int value;
  final Color color, bgColor;
  final bool positive, isFirst, isLast;
  final VoidCallback? onTap;
  const _HoldingRow({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.change,
    required this.positive,
    required this.isFirst,
    required this.isLast,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.text,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(fontSize: 11, color: _C.sub),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _AnimatedNumText(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _C.text,
                ),
              ),
              Text(
                change,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: positive ? const Color(0xFF2D7A45) : _C.rose,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 16, color: _C.sub),
        ],
      ),
    ),
  );
}

class _DarkStat extends StatelessWidget {
  final String label;
  final dynamic value;
  final Widget icon;
  const _DarkStat(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      icon,
      const SizedBox(height: 4),
      value is int
          ? _AnimatedNumText(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Y4.ink,
            ),
          )
          : Text(
            value.toString(),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Y4.ink,
            ),
          ),
      Text(
        label,
        style: GoogleFonts.outfit(fontSize: 10, color: Y4.inkSoft),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class _MonthStat extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;
  // When set, replaces the [icon] glyph — used to show the SabiqCoin for
  // the Seeds stat instead of a generic Material icon.
  final Widget? iconWidget;

  const _MonthStat({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.color,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = delta.contains('↑');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconWidget ?? Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              if (delta.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  delta,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isUp ? const Color(0xFF2D7A45) : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Y4.inkSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final String day;
  final double value;
  final bool highlight;
  final VoidCallback? onTap;
  const _DayBar(this.day, this.value, {this.highlight = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    const maxH = 64.0;
    const minVisibleH = 14.0;
    // Empty days collapse to a thin sliver; any day with worship time
    // starts at minVisibleH and scales linearly up to maxH for the day
    // with the most time. This keeps small-vs-large differences obvious
    // without making zero-time days look like real activity.
    final h = value <= 0
        ? 2.0
        : (minVisibleH + value * (maxH - minVisibleH)).clamp(minVisibleH, maxH);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: highlight
                        ? [const Color(0xFFF59E0B), const Color(0xFFD4783A)]
                        : [_C.teal.withValues(alpha: 0.7), _C.teal],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                day,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
                  color: highlight ? _C.gold : _C.sub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Project cover for impact-report list (loads first media item or explicit dp_url) ──
class _ImpactProjectCover extends StatefulWidget {
  final Map<String, dynamic> project;
  const _ImpactProjectCover({required this.project});

  @override
  State<_ImpactProjectCover> createState() => _ImpactProjectCoverState();
}

class _ImpactProjectCoverState extends State<_ImpactProjectCover> {
  static final Map<String, ProjectMedia?> _cache = {};
  ProjectMedia? _cover;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final dpUrl = widget.project['dp_url'] as String?;
    if (dpUrl != null && dpUrl.isNotEmpty) {
      _loading = false;
      return;
    }

    final projectId = widget.project['id'] as String;
    if (_cache.containsKey(projectId)) {
      _cover = _cache[projectId];
      _loading = false;
    } else {
      _load(projectId);
    }
  }

  Future<void> _load(String projectId) async {
    final list = await DonationService.instance.getProjectMedia(projectId);
    final cover = list.isNotEmpty ? list.first : null;
    _cache[projectId] = cover;
    if (!mounted) return;
    setState(() {
      _cover = cover;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double s = 48; // increased size for DP visibility
    final radius = BorderRadius.circular(12);

    final dpUrl = widget.project['dp_url'] as String?;
    if (dpUrl != null && dpUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: dpUrl,
          width: s,
          height: s,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallbackCover(s, radius),
        ),
      );
    }

    if (_loading) {
      return Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F4),
          borderRadius: radius,
        ),
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFC9921A),
              ),
            ),
          ),
        ),
      );
    }
    if (_cover == null) return _fallbackCover(s, radius);

    if (_cover!.isVideo) {
      return Container(
        width: s,
        height: s,
        decoration: BoxDecoration(color: Colors.black, borderRadius: radius),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 22,
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
        errorWidget: (_, __, ___) => _fallbackCover(s, radius),
      ),
    );
  }

  Widget _fallbackCover(double s, BorderRadius r) => Container(
    width: s,
    height: s,
    decoration: BoxDecoration(
      color: Y4.honey.withValues(alpha: 0.12),
      borderRadius: r,
    ),
    child: Icon(
      Icons.volunteer_activism_rounded,
      size: 24,
      color: Y4.honeyDeep,
    ),
  );
}
