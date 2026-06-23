// QuranEngagementStrip
//
// Slim social-proof bar shown on the Quran reading screen, just below the
// surah header. Three rotating chips:
//
//   1) "X reading now"  — live count of users on this same surah, via a
//      Supabase Realtime presence channel scoped to the surah number. No
//      DB writes; presence state is in-memory on the Realtime server.
//   2) "Y read today"   — global community readers today, from the
//      existing `StatsService.loadGlobalStats()` RPC. Cached 60s.
//   3) "+Z hasanat"     — today's community-earned hasanat estimate
//      (todayAyahs × 10), again from the cached global stats.
//
// The widget is self-contained: takes only the surah number, joins/leaves the
// presence channel as the surah changes, polls global stats every 60s while
// mounted. Failures degrade silently (chip hides), so a flaky connection
// never breaks the reading UI.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/stats_service.dart';
import '../theme/y4_theme.dart';

class QuranEngagementStrip extends StatefulWidget {
  final int surah;
  const QuranEngagementStrip({super.key, required this.surah});

  @override
  State<QuranEngagementStrip> createState() => _QuranEngagementStripState();
}

class _QuranEngagementStripState extends State<QuranEngagementStrip> {
  RealtimeChannel? _channel;
  int _liveReaders = 0;
  GlobalStats _global = const GlobalStats();
  Timer? _globalRefresh;

  @override
  void initState() {
    super.initState();
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
    _globalRefresh?.cancel();
    _leaveChannel();
    super.dispose();
  }

  void _joinChannel(int surah) {
    final sb = Supabase.instance.client;
    final uid = sb.auth.currentUser?.id ?? 'anon-${DateTime.now().millisecondsSinceEpoch}';

    // Per-surah channel: everyone reading the same surah is in the same room.
    final channel = sb.channel(
      'quran-surah-$surah',
      opts: RealtimeChannelConfig(key: uid),
    );

    channel.onPresenceSync((_) => _recomputeReaders(channel));
    channel.onPresenceJoin((_) => _recomputeReaders(channel));
    channel.onPresenceLeave((_) => _recomputeReaders(channel));

    channel.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        // Announce our presence so the count includes us.
        channel.track({
          'online_at': DateTime.now().toIso8601String(),
        });
      }
    });

    _channel = channel;
  }

  void _recomputeReaders(RealtimeChannel ch) {
    try {
      final state = ch.presenceState();
      // presenceState returns a list of presences; each entry is a key with
      // a list of metas. The unique-user count is the number of keys.
      final count = state.length;
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
    } catch (_) {
      // silent — chip will just show stale/zero values
    }
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
    // Today's global hasanat (rough estimate: ayahs × 10 per the hadith).
    final hasanatToday = _global.todayAyahs * 10;

    final chips = <_Chip>[
      _Chip(
        icon: Icons.circle,
        iconColor: const Color(0xFF22C55E),
        iconSize: 8,
        label: (l?.liveReadersNow(_formatNumber(_liveReaders)) ??
            '$_liveReaders reading now'),
        accent: const Color(0xFF22C55E),
      ),
      _Chip(
        icon: Icons.menu_book_rounded,
        iconColor: Y4.honeyDeep,
        iconSize: 13,
        label: (l?.communityReadingToday(_formatNumber(_global.todayReaders)) ??
            '${_formatNumber(_global.todayReaders)} reading today'),
        accent: Y4.honeyDeep,
      ),
      if (hasanatToday > 0)
        _Chip(
          icon: Icons.bolt_rounded,
          iconColor: const Color(0xFFEAB308),
          iconSize: 13,
          label: (l?.communityHasanatToday(_formatNumber(hasanatToday)) ??
              '+${_formatNumber(hasanatToday)} hasanat today'),
          accent: const Color(0xFFEAB308),
        ),
    ];

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i].build(),
      ),
    );
  }
}

class _Chip {
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final String label;
  final Color accent;
  _Chip({
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.label,
    required this.accent,
  });

  Widget build() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
