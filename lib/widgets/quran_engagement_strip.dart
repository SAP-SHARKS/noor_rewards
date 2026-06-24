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
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/stats_service.dart';
import '../theme/y4_theme.dart';

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
    final hasanatToday = _global.todayAyahs * 10;
    final liveLabel = l?.peopleReadingNow ?? 'reading right now';
    final readersTodayLabel = l?.readToday ?? 'read today';
    final hasanatLabel = l?.communityHasanat ?? 'community hasanat';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Y4.cream,
            Y4.butter.withValues(alpha: 0.45),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Y4.honey.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Y4.honeyDeep.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero row: pulsing dot + big count + label ─────────────────
          Row(
            children: [
              _PulsingDot(controller: _pulseCtrl),
              const SizedBox(width: 10),
              Text(
                _formatNumber(_liveReaders),
                style: GoogleFonts.fraunces(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Y4.ink,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  liveLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Y4.inkSoft,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          // ── Divider + community footer row ────────────────────────────
          if (_global.todayReaders > 0 || hasanatToday > 0) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: Y4.honey.withValues(alpha: 0.18)),
            const SizedBox(height: 10),
            Row(
              children: [
                if (_global.todayReaders > 0)
                  _FooterStat(
                    icon: Icons.menu_book_rounded,
                    iconColor: Y4.honeyDeep,
                    value: _formatNumber(_global.todayReaders),
                    label: readersTodayLabel,
                  ),
                if (_global.todayReaders > 0 && hasanatToday > 0)
                  Container(
                    width: 1,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: Y4.honey.withValues(alpha: 0.18),
                  ),
                if (hasanatToday > 0)
                  _FooterStat(
                    icon: Icons.auto_awesome_rounded,
                    iconColor: const Color(0xFFD4A017),
                    value: '+${_formatNumber(hasanatToday)}',
                    label: hasanatLabel,
                  ),
              ],
            ),
          ],
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
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Y4.ink,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Y4.inkSoft,
          ),
        ),
      ],
    );
  }
}
