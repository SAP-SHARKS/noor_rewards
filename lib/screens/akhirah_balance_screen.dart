// lib/screens/akhirah_balance_screen.dart
//
// Shown right after the Dhikr-exit celebration popup is dismissed. Gives the
// user a moment to absorb their balance — lifetime points, today vs their
// 7-day average, and a tiny weekly trend chart — so the session ends with
// a sense of accumulating reward rather than just "+X seeds".
//
// Wired from `_handleExitDhikr` in `dhikr_screen.dart` via pushReplacement,
// so the back stack reads: dashboard → akhirah balance (dhikr is replaced).
// The "View full stats →" link opens the dedicated `AkhirahStatsScreen`.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/y4_theme.dart';
import '../widgets/sabiq_coin.dart';
import 'impact_report_screen.dart';

class AkhirahBalanceScreen extends StatefulWidget {
  /// Seeds earned in the dhikr session that just finished. Used only for the
  /// "this session" delta chip (the chart pulls per-day totals from the DB).
  final int sessionPoints;

  /// Optional payload to bubble back when this screen pops (so the dashboard
  /// can still refresh tiles the way it used to when dhikr_screen popped).
  final int? popResult;

  /// Total seconds the user has spent in Dua & Zikar across the whole day
  /// (cumulative across multiple sessions). Surfaced alongside today's azkar
  /// count on the "TODAY" pill so the user sees both volume and time invested.
  /// Null = caller didn't pass it; the pill quietly hides the time column.
  final int? dhikrSecondsToday;

  const AkhirahBalanceScreen({
    super.key,
    this.sessionPoints = 0,
    this.popResult,
    this.dhikrSecondsToday,
  });

  @override
  State<AkhirahBalanceScreen> createState() => _AkhirahBalanceScreenState();
}

class _AkhirahBalanceScreenState extends State<AkhirahBalanceScreen>
    with SingleTickerProviderStateMixin {
  final _sb = Supabase.instance.client;

  bool _loading = true;
  int _lifetimePoints = 0;
  // Last 7 daily rows oldest → newest (index 6 = today). Each entry holds
  // both the dhikr count and points so the card + chart can use either.
  List<_DayRow> _days = const [];

  late AnimationController _intro;
  // Reflection picked once per screen build so it stays stable while the
  // user reads, but varies between visits. Defaults to a fixed line until
  // _loadReflection() picks a fresh one (which also persists the chosen
  // index so the next visit is guaranteed to be different).
  String _reflection = _kReflectionPool[0];
  static const String _kPrefKeyLastReflectionIdx = 'akhirah_last_reflection_idx';

  // Dhikr-focused motivational nudges shown after the session reward.
  // Mix of three flavours:
  //   • Hadith-anchored: cite a specific phrase the user just recited,
  //     so the reward feels concrete and traceable.
  //   • Quranic: short ayat about remembrance.
  //   • Habit-coaching: pure motivation, no scripture, focused on
  //     consistency and the long-term scale-of-the-soul payoff.
  // Each <= ~20 words so it fits in a single card without truncation.
  static const List<String> _kReflectionPool = [
    // — Hadith-anchored —
    '“Subhanallahi wa bi-hamdihi” — said 100 times a day wipes sins, even like the foam of the sea. (Bukhari)',
    'Say La ilaha illallah 100 times — equals freeing 10 slaves and 100 hasanat. (Bukhari)',
    'Light on the tongue, heavy on the scales: Subhanallahi wa bi-hamdihi, Subhanallahil-azim. (Bukhari 6406)',
    'The dhikr of Allah is heavier on the scales than gold of equal weight. Keep going.',
    '“Your tongue should stay moist with the remembrance of Allah.” — Is it still moist?',
    'Astaghfirullah — the Prophet ✍ said it 100 times a day, and he had no sin. How many have you?',
    'When you remember Allah quietly, He remembers you in an assembly far greater.',
    'Recite Ayat al-Kursi after every salah — nothing keeps you from Jannah but death.',
    'One Alhamdulillah fills the scale. One Subhanallah fills what is between heaven and earth.',
    // — Quranic —
    '“The remembrance of Allah is greater than everything else.” — Surah Al-Ankabut 29:45',
    '“Remember Me — I will remember you.” — Surah Al-Baqarah 2:152. Will you?',
    '“In the remembrance of Allah, hearts find rest.” — Surah Ar-Ra’d 13:28',
    // — Habit-coaching / pure motivation —
    'Five minutes of dhikr now shapes the next 24 hours of your heart.',
    'A streak isn’t about today — it’s about who you become in 30 days.',
    'Small drops fill an ocean. Your daily dhikr is filling something far bigger.',
    'No one sees the dhikr in your heart — but every angel writing your record does.',
    'The biggest wins are built from the smallest daily habits. Don’t break the chain.',
    'You came back today. That’s already worship. Stay one more minute?',
    'Tomorrow’s peace is built on today’s remembrance. Plant one more seed.',
    'Are you done? Allah’s door is always open — even after you’ve closed it.',
    'Dhikr is the language of the heart. Has yours spoken to its Lord today?',
    'Every Subhanallah is a sadaqah. How many will you give before sleep?',
    'A heart that forgets dhikr begins to rust. A heart that remembers stays alight.',
    'Have you fortified yourself with the morning and evening adhkar today?',
  ];

  // Pick a fresh reflection that differs from whatever was shown last
  // time the user landed here. We avoid microsecondsSinceEpoch (it can
  // cluster on the same modulo when the screen is opened in quick
  // succession) and use dart:math Random, which is properly seeded by
  // the runtime. Persist the chosen index so consecutive visits are
  // guaranteed not to repeat.
  Future<void> _loadReflection() async {
    int lastIdx = -1;
    try {
      final prefs = await SharedPreferences.getInstance();
      lastIdx = prefs.getInt(_kPrefKeyLastReflectionIdx) ?? -1;
    } catch (_) {/* prefs failure → fall through with lastIdx = -1 */}
    final rand = math.Random();
    int idx;
    do {
      idx = rand.nextInt(_kReflectionPool.length);
    } while (idx == lastIdx && _kReflectionPool.length > 1);
    if (mounted) setState(() => _reflection = _kReflectionPool[idx]);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kPrefKeyLastReflectionIdx, idx);
    } catch (_) {/* best-effort persistence; not critical */}
  }

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _loadReflection();
    _load();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final today = DateTime.now();
    final from = today.subtract(const Duration(days: 6));
    final fromKey = _dateKey(from);

    try {
      final results = await Future.wait([
        _sb
            .from('profiles')
            .select('noor_points')
            .eq('id', uid)
            .maybeSingle(),
        _sb
            .from('user_daily_stats')
            .select('stat_date, dhikr_count')
            .eq('user_id', uid)
            .gte('stat_date', fromKey)
            .order('stat_date'),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final rows = (results[1] as List).cast<Map<String, dynamic>>();

      // Build a complete 7-day window even if some days have no row.
      final byDate = <String, _DayRow>{};
      for (final r in rows) {
        final key = (r['stat_date'] as String?) ?? '';
        if (key.isEmpty) continue;
        byDate[key] = _DayRow(
          date: DateTime.parse(key),
          azkaar: (r['dhikr_count'] as num?)?.toInt() ?? 0,
        );
      }
      final filled = <_DayRow>[];
      for (int i = 0; i < 7; i++) {
        final d = from.add(Duration(days: i));
        final key = _dateKey(d);
        filled.add(byDate[key] ?? _DayRow(date: d, azkaar: 0));
      }

      if (!mounted) return;
      setState(() {
        _lifetimePoints = (profile?['noor_points'] as num?)?.toInt() ?? 0;
        _days = filled;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  void _done() {
    Navigator.of(context).pop(widget.popResult);
  }

  @override
  Widget build(BuildContext context) {
    final today = _days.isNotEmpty ? _days.last : _DayRow.empty();
    final history = _days.length > 1 ? _days.sublist(0, _days.length - 1) : <_DayRow>[];
    final avgAzkaar = history.isEmpty
        ? 0.0
        : history.map((d) => d.azkaar).reduce((a, b) => a + b) / history.length;

    return Scaffold(
      backgroundColor: Y4.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Y4.honeyDeep),
                    )
                  : FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _intro,
                        curve: Curves.easeOut,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _hero(),
                            const SizedBox(height: 16),
                            _reflectionCard(),
                            const SizedBox(height: 20),
                            _todayVsAvg(
                              today: today,
                              avgAzkaar: avgAzkaar,
                            ),
                            const SizedBox(height: 20),
                            _weeklyChart(),
                            const SizedBox(height: 24),
                            _viewFullStatsButton(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reflection prompt ──────────────────────────────────────────────────
  // Eye-catching dhikr-motivation card. Sage-honey gradient + accent
  // border + glowing icon badge so the eye is drawn here right after
  // the session reward sinks in. Pool-rotated so a fresh line shows
  // up each visit.
  Widget _reflectionCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8F2D9), // soft sage tint
            Color(0xFFFFF6D6), // warm honey tint
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Y4.primary.withValues(alpha: 0.55),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Y4.primary.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Glowing icon badge — circular, gradient fill, soft halo so
          // the reflection feels like an "aha" prompt rather than a
          // muted hint.
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Y4.primary, Y4.primaryDeep],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Y4.primaryDeep.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A REMINDER',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Y4.primaryDeep,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _reflection,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
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

  // ── Top bar with Done button ───────────────────────────────────────────
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Y4.ink),
            tooltip: 'Done',
            onPressed: _done,
          ),
          const Spacer(),
          TextButton(
            onPressed: _done,
            child: Text(
              'Done',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Y4.honeyDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero: lifetime points ──────────────────────────────────────────────
  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Y4.cream, Y4.butter],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Y4.honey.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Y4.honeyDeep.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'YOUR AKHIRAH BALANCE',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: Y4.honeyDeep,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SabiqCoin(size: 36),
              const SizedBox(width: 10),
              Text(
                _formatNumber(_lifetimePoints),
                style: GoogleFonts.fraunces(
                  fontSize: 52,
                  fontWeight: FontWeight.w500,
                  color: Y4.ink,
                  letterSpacing: -1.0,
                  height: 1.0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Seeds collected since you joined',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Y4.inkSoft,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (widget.sessionPoints > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Y4.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: Y4.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_upward_rounded,
                    color: Y4.primaryDeep,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'This session: +${widget.sessionPoints}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Y4.primaryDeep,
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

  // ── Today vs avg card ──────────────────────────────────────────────────
  Widget _todayVsAvg({
    required _DayRow today,
    required double avgAzkaar,
  }) {
    final azkaarDelta = avgAzkaar > 0
        ? ((today.azkaar - avgAzkaar) / avgAzkaar * 100).round()
        : null;
    final above = today.azkaar > avgAzkaar && avgAzkaar > 0;
    final equal = (today.azkaar - avgAzkaar).abs() < 0.5;

    final String comparison;
    final Color comparisonColor;
    final IconData comparisonIcon;
    if (avgAzkaar == 0) {
      comparison = 'Your first tracked week — keep going!';
      comparisonColor = Y4.inkSoft;
      comparisonIcon = Icons.auto_awesome_rounded;
    } else if (equal) {
      comparison = 'Right on your 7-day pace';
      comparisonColor = Y4.honeyDeep;
      comparisonIcon = Icons.horizontal_rule_rounded;
    } else if (above) {
      comparison = '${azkaarDelta!.abs()}% above your 7-day average';
      comparisonColor = Y4.primaryDeep;
      comparisonIcon = Icons.trending_up_rounded;
    } else {
      comparison = '${azkaarDelta!.abs()}% below your 7-day average';
      comparisonColor = Y4.amberY;
      comparisonIcon = Icons.trending_down_rounded;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Y4.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Y4.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: Y4.inkSoft,
            ),
          ),
          const SizedBox(height: 10),
          // Two side-by-side columns: azkar count + time spent today.
          // Time column shows only when the caller supplied a duration.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${today.azkaar}',
                      style: GoogleFonts.fraunces(
                        fontSize: 42,
                        fontWeight: FontWeight.w500,
                        color: Y4.ink,
                        height: 1.0,
                        letterSpacing: -0.6,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        today.azkaar == 1 ? 'azkar' : 'azkaar',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Y4.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if ((widget.dhikrSecondsToday ?? 0) > 0) ...[
                Container(
                  width: 1,
                  height: 44,
                  color: Y4.border,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                ),
                Expanded(
                  child: Builder(builder: (_) {
                    final s = widget.dhikrSecondsToday ?? 0;
                    final h = s ~/ 3600;
                    final m = (s % 3600) ~/ 60;
                    final sec = s % 60;
                    final String value;
                    final String label;
                    if (h > 0) {
                      value = '$h:${m.toString().padLeft(2, '0')}';
                      label = h == 1 && m == 0 ? 'hour' : 'hours';
                    } else if (m > 0) {
                      value = '$m';
                      label = m == 1 ? 'minute' : 'minutes';
                    } else {
                      value = '$sec';
                      label = sec == 1 ? 'second' : 'seconds';
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          value,
                          style: GoogleFonts.fraunces(
                            fontSize: 42,
                            fontWeight: FontWeight.w500,
                            color: Y4.ink,
                            height: 1.0,
                            letterSpacing: -0.6,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            label,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Y4.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ],
          ),
          if (widget.sessionPoints > 0) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const SabiqCoin(size: 14),
                const SizedBox(width: 5),
                Text(
                  '+${widget.sessionPoints} seeds this session',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Y4.honeyDeep,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: Y4.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(comparisonIcon, size: 16, color: comparisonColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  comparison,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: comparisonColor,
                  ),
                ),
              ),
            ],
          ),
          if (avgAzkaar > 0) ...[
            const SizedBox(height: 4),
            Text(
              '7-day avg: ${avgAzkaar.toStringAsFixed(0)} azkaar/day',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Y4.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 7-day chart ────────────────────────────────────────────────────────
  Widget _weeklyChart() {
    final maxVal = _days.isEmpty
        ? 1
        : _days.map((d) => d.azkaar).reduce((a, b) => a > b ? a : b);
    final scaleMax = maxVal == 0 ? 1 : maxVal;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Y4.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Y4.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LAST 7 DAYS',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: Y4.inkSoft,
                ),
              ),
              Text(
                'azkaar per day',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Y4.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < _days.length; i++)
                  Expanded(child: _bar(_days[i], i == _days.length - 1, scaleMax)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (int i = 0; i < _days.length; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      _dayLetter(_days[i].date),
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: i == _days.length - 1
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: i == _days.length - 1
                            ? Y4.honeyDeep
                            : Y4.muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(_DayRow d, bool isToday, int scaleMax) {
    final ratio = scaleMax == 0 ? 0.0 : d.azkaar / scaleMax;
    final isEmpty = d.azkaar == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${d.azkaar}',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isToday ? Y4.honeyDeep : Y4.inkSoft,
                ),
              ),
            ),
          AnimatedBuilder(
            animation: _intro,
            builder: (_, __) {
              final h = (90 * ratio * Curves.easeOut.transform(_intro.value))
                  .clamp(0.0, 90.0);
              return Container(
                height: isEmpty ? 4 : h.toDouble(),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: isEmpty
                      ? null
                      : LinearGradient(
                          colors: isToday
                              ? const [Y4.honey, Y4.honeyDeep]
                              : [Y4.butter, Y4.honey],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                  color: isEmpty ? Y4.track : null,
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _dayLetter(DateTime d) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    // DateTime.weekday: Mon=1..Sun=7
    return labels[(d.weekday - 1).clamp(0, 6)];
  }

  // ── Deep link button ──────────────────────────────────────────────────
  Widget _viewFullStatsButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ImpactReportScreen(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Y4.honeyDeep, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View full stats',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Y4.honeyDeep,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded,
                color: Y4.honeyDeep, size: 18),
          ],
        ),
      ),
    );
  }

  static String _formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────
class _DayRow {
  final DateTime date;
  final int azkaar;
  const _DayRow({required this.date, required this.azkaar});

  factory _DayRow.empty() => _DayRow(date: DateTime.now(), azkaar: 0);
}
