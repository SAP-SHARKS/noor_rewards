// QuranEngagementStrip
//
// Quranly-style live engagement card shown on the Quran hub page in place of
// the old static "Today's Progress" bar. One unified card with:
//
//   • Hero row — animated pulsing green dot + big count, "X reading right
//     now". Driven by a Supabase Realtime presence channel (per-surah when
//     a surah is passed, hub-wide otherwise). No DB writes; presence state
//     is in-memory on the Realtime server.
//   • Footer row — two slim community chips: today's readers count and the
//     community-earned hasanat estimate (today's ayahs × 10). Sourced from
//     the existing `StatsService.loadGlobalStats()` RPC, cached locally and
//     refreshed every 60s while mounted. Chips with a count of 0 are hidden
//     so the card doesn't look empty on cold-start days.
//
// Failures degrade silently — a flaky Realtime or RPC connection never
// breaks the reading UI.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/stats_service.dart';
import '../theme/y4_theme.dart';

// English transliterations for the 114 surahs — used by the popular-surah
// rows. Translator can swap to a localized map later.
const Map<int, String> _kSurahNames = {
  1: 'Al-Fatiha', 2: 'Al-Baqarah', 3: 'Ali Imran', 4: 'An-Nisa', 5: 'Al-Maidah',
  6: 'Al-Anam', 7: 'Al-Araf', 8: 'Al-Anfal', 9: 'At-Tawbah', 10: 'Yunus',
  11: 'Hud', 12: 'Yusuf', 13: 'Ar-Rad', 14: 'Ibrahim', 15: 'Al-Hijr',
  16: 'An-Nahl', 17: 'Al-Isra', 18: 'Al-Kahf', 19: 'Maryam', 20: 'Ta-Ha',
  21: 'Al-Anbiya', 22: 'Al-Hajj', 23: 'Al-Muminun', 24: 'An-Nur', 25: 'Al-Furqan',
  26: 'Ash-Shuara', 27: 'An-Naml', 28: 'Al-Qasas', 29: 'Al-Ankabut', 30: 'Ar-Rum',
  31: 'Luqman', 32: 'As-Sajdah', 33: 'Al-Ahzab', 34: 'Saba', 35: 'Fatir',
  36: 'Ya-Sin', 37: 'As-Saffat', 38: 'Sad', 39: 'Az-Zumar', 40: 'Ghafir',
  41: 'Fussilat', 42: 'Ash-Shura', 43: 'Az-Zukhruf', 44: 'Ad-Dukhan',
  45: 'Al-Jathiyah', 46: 'Al-Ahqaf', 47: 'Muhammad', 48: 'Al-Fath',
  49: 'Al-Hujurat', 50: 'Qaf', 51: 'Adh-Dhariyat', 52: 'At-Tur', 53: 'An-Najm',
  54: 'Al-Qamar', 55: 'Ar-Rahman', 56: 'Al-Waqiah', 57: 'Al-Hadid',
  58: 'Al-Mujadilah', 59: 'Al-Hashr', 60: 'Al-Mumtahanah', 61: 'As-Saff',
  62: 'Al-Jumuah', 63: 'Al-Munafiqun', 64: 'At-Taghabun', 65: 'At-Talaq',
  66: 'At-Tahrim', 67: 'Al-Mulk', 68: 'Al-Qalam', 69: 'Al-Haqqah',
  70: 'Al-Maarij', 71: 'Nuh', 72: 'Al-Jinn', 73: 'Al-Muzzammil',
  74: 'Al-Muddaththir', 75: 'Al-Qiyamah', 76: 'Al-Insan', 77: 'Al-Mursalat',
  78: 'An-Naba', 79: 'An-Naziat', 80: 'Abasa', 81: 'At-Takwir', 82: 'Al-Infitar',
  83: 'Al-Mutaffifin', 84: 'Al-Inshiqaq', 85: 'Al-Buruj', 86: 'At-Tariq',
  87: 'Al-Ala', 88: 'Al-Ghashiyah', 89: 'Al-Fajr', 90: 'Al-Balad',
  91: 'Ash-Shams', 92: 'Al-Layl', 93: 'Ad-Duha', 94: 'Ash-Sharh', 95: 'At-Tin',
  96: 'Al-Alaq', 97: 'Al-Qadr', 98: 'Al-Bayyinah', 99: 'Az-Zalzalah',
  100: 'Al-Adiyat', 101: 'Al-Qariah', 102: 'At-Takathur', 103: 'Al-Asr',
  104: 'Al-Humazah', 105: 'Al-Fil', 106: 'Quraysh', 107: 'Al-Maun',
  108: 'Al-Kawthar', 109: 'Al-Kafirun', 110: 'An-Nasr', 111: 'Al-Masad',
  112: 'Al-Ikhlas', 113: 'Al-Falaq', 114: 'An-Nas',
};

class QuranEngagementStrip extends StatefulWidget {
  /// When provided, presence is scoped to readers of this surah. When null
  /// (e.g. on the Quran hub before any surah is selected), presence joins a
  /// single `quran-hub` channel — "X reading the Quran right now".
  final int? surah;
  const QuranEngagementStrip({super.key, this.surah});

  @override
  State<QuranEngagementStrip> createState() => _QuranEngagementStripState();
}

class _QuranEngagementStripState extends State<QuranEngagementStrip>
    with SingleTickerProviderStateMixin {
  RealtimeChannel? _channel;
  int _liveReaders = 0;
  GlobalStats _global = const GlobalStats();
  List<({int surah, int count})> _popular = const [];
  Timer? _globalRefresh;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _joinChannel(widget.surah);
    _refreshGlobal();
    _globalRefresh = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _refreshGlobal(),
    );
  }

  @override
  void didUpdateWidget(covariant QuranEngagementStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surah != widget.surah) {
      _leaveChannel();
      _joinChannel(widget.surah);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _globalRefresh?.cancel();
    _leaveChannel();
    super.dispose();
  }

  void _joinChannel(int? surah) {
    final sb = Supabase.instance.client;
    final uid = sb.auth.currentUser?.id ??
        'anon-${DateTime.now().millisecondsSinceEpoch}';
    final channelName = surah != null ? 'quran-surah-$surah' : 'quran-hub';
    final channel = sb.channel(
      channelName,
      opts: RealtimeChannelConfig(key: uid),
    );

    channel.onPresenceSync((_) => _recomputeReaders(channel));
    channel.onPresenceJoin((_) => _recomputeReaders(channel));
    channel.onPresenceLeave((_) => _recomputeReaders(channel));

    channel.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        channel.track({'online_at': DateTime.now().toIso8601String()});
      }
    });

    _channel = channel;
  }

  void _recomputeReaders(RealtimeChannel ch) {
    try {
      final count = ch.presenceState().length;
      if (mounted && count != _liveReaders) {
        setState(() => _liveReaders = count);
      }
    } catch (_) {}
  }

  void _leaveChannel() {
    try {
      _channel?.untrack();
      _channel?.unsubscribe();
    } catch (_) {}
    _channel = null;
  }

  Future<void> _refreshGlobal() async {
    try {
      final stats = await StatsService.instance.loadGlobalStats();
      if (mounted) setState(() => _global = stats);
    } catch (_) {}
    try {
      final pop = await StatsService.instance.loadPopularSurahs(limit: 3);
      if (mounted) setState(() => _popular = pop);
    } catch (_) {}
  }

  String _formatNumber(int n) {
    if (n < 1000) return '$n';
    if (n < 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    if (n < 1000000) return '${(n / 1000).toStringAsFixed(0)}k';
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final liveLabel = l?.peopleReadingNow ?? 'reading right now';
    final readersTodayLabel = l?.readToday ?? 'read today';

    // Fresher palette — cool mint-sage on the right contrasts the honey
    // brand colour on the left of the card.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF8E6), // soft cream-honey
            Color(0xFFEDF8EE), // pale mint
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8FCFA0).withValues(alpha: 0.55), width: 1.2),
        boxShadow: [
          // Mint halo
          BoxShadow(
            color: const Color(0xFF8FCFA0).withValues(alpha: 0.28),
            blurRadius: 16,
          ),
          // Subtle green drop
          BoxShadow(
            color: const Color(0xFF3F8C5E).withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
            // ── LEFT half: live readers + today's community stats ──────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/stat_quran.svg',
                          width: 22,
                          height: 22,
                        ),
                        const SizedBox(width: 5),
                        _PulsingDot(controller: _pulseCtrl),
                        const SizedBox(width: 5),
                        Text(
                          _formatNumber(_liveReaders),
                          style: GoogleFonts.fraunces(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Y4.ink,
                            letterSpacing: -0.5,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      liveLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Y4.inkSoft,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_global.todayReaders > 0) ...[
                      const SizedBox(height: 4),
                      _FooterStat(
                        icon: Icons.menu_book_rounded,
                        iconColor: Y4.honeyDeep,
                        value: _formatNumber(_global.todayReaders),
                        label: readersTodayLabel,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // ── Dotted vertical separator — fixed-height column of mint
            // dots so layout doesn't depend on shared intrinsic heights.
            const SizedBox(
              width: 10,
              height: 56,
              child: _DottedDivider(),
            ),
            // ── RIGHT half: top 3 surahs the community is reading ────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l?.frequentlyReadByCommunity ?? 'FREQUENTLY READ',
                      style: GoogleFonts.rajdhani(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3F8C5E),
                        letterSpacing: 0.8,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    if (_popular.isEmpty)
                      Text(
                        '—',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Y4.inkSoft,
                        ),
                      )
                    else
                      ..._popular.asMap().entries.map((e) {
                        final idx = e.key + 1;
                        final p = e.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: _PopularSurahRow(
                            rank: idx,
                            name: _kSurahNames[p.surah] ?? 'Surah ${p.surah}',
                            count: _formatNumber(p.count),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live-presence pulsing dot — soft halo + solid centre, breathes 1.5s/cycle.
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingDot extends StatelessWidget {
  final AnimationController controller;
  const _PulsingDot({required this.controller});

  @override
  Widget build(BuildContext context) {
    const live = Color(0xFF22C55E);
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return SizedBox(
          width: 18,
          height: 18,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft expanding halo
              Container(
                width: 8 + (10 * t),
                height: 8 + (10 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: live.withValues(alpha: 0.35 * (1 - t)),
                ),
              ),
              // Solid centre
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: live,
                  boxShadow: [
                    BoxShadow(
                      color: live,
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dotted vertical divider — renders a column of evenly-spaced mint dots that
// fill the parent's height (sized via SizedBox + LayoutBuilder).
// ─────────────────────────────────────────────────────────────────────────────
class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    // Fixed count of dots spread evenly. LayoutBuilder was reporting
    // unbounded constraints inside the engagement-strip IntrinsicHeight,
    // which made the whole header render at zero size.
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        9,
        (_) => Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF8FCFA0).withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Popular-surah row — small rank pill + surah name + count, used in the
// "Frequently read by Community" half of the engagement strip.
// ─────────────────────────────────────────────────────────────────────────────
class _PopularSurahRow extends StatelessWidget {
  final int rank;
  final String name;
  final String count;
  const _PopularSurahRow({
    required this.rank,
    required this.name,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 15,
          height: 15,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFE2F5DE), Color(0xFF8FCFA0)],
            ),
          ),
          child: Text(
            '$rank',
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Y4.ink,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Y4.ink,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          count,
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
// Footer community-stat: icon + bold number + small label.
// ─────────────────────────────────────────────────────────────────────────────
class _FooterStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _FooterStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Y4.ink,
          ),
        ),
        const SizedBox(width: 3),
        // Flexible so the label can ellipsize when the card is narrow,
        // instead of overflowing the row.
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Y4.inkSoft,
            ),
          ),
        ),
      ],
    );
  }
}
