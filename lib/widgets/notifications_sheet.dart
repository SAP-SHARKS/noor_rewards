// lib/widgets/notifications_sheet.dart
//
// Honey-themed bottom sheet listing in-app notifications.
// Master on/off toggle at top, list of items below, tap to navigate.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/notification_center.dart';
import '../theme/y4_theme.dart';
import '../l10n/app_localizations.dart';

/// Show the notifications inbox as a draggable bottom sheet.
Future<void> showNotificationsSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _NotificationsSheet(),
  );
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder:
          (ctx, scroll) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Y4.palette.cream, Y4.bg, Y4.bg],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
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
                    color: Y4.palette.muted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),

                // Header row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Y4.butter, Y4.honey],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Y4.palette.honeyDeep.withValues(alpha: 0.70),
                          ),
                        ),
                        child: const Icon(
                          Icons.notifications_rounded,
                          color: Y4.honeyDeep,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)?.notifications ??
                                  'Notifications',
                              style: Y4.display(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Y4.palette.ink,
                                letterSpacing: -0.3,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppLocalizations.of(
                                    context,
                                  )?.notificationsSubtitle ??
                                  'Stay on top of rewards & milestones',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Y4.palette.inkSoft,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // "Mark all" / "Clear" menu
                      ValueListenableBuilder<List<NotificationItem>>(
                        valueListenable:
                            NotificationCenter.instance.notifications,
                        builder:
                            (_, list, __) =>
                                list.isEmpty
                                    ? const SizedBox.shrink()
                                    : PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_horiz_rounded,
                                        color: Y4.inkSoft,
                                      ),
                                      color: Y4.surface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: const BorderSide(
                                          color: Y4.border,
                                        ),
                                      ),
                                      itemBuilder:
                                          (_) => [
                                            PopupMenuItem(
                                              value: 'mark',
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.done_all_rounded,
                                                    size: 18,
                                                    color: Y4.ink,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    AppLocalizations.of(
                                                          context,
                                                        )?.markAllAsRead ??
                                                        'Mark all as read',
                                                    style: GoogleFonts.outfit(
                                                      color: Y4.palette.ink,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'clear',
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    size: 18,
                                                    color: Y4.ink,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    AppLocalizations.of(
                                                          context,
                                                        )?.clearAll ??
                                                        'Clear all',
                                                    style: GoogleFonts.outfit(
                                                      color: Y4.palette.ink,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                      onSelected: (v) async {
                                        if (v == 'mark') {
                                          await NotificationCenter.instance
                                              .markAllRead();
                                        } else if (v == 'clear') {
                                          await NotificationCenter.instance
                                              .clear();
                                        }
                                      },
                                    ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Master on/off toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: NotificationCenter.instance.enabled,
                    builder:
                        (_, on, __) => Container(
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
                              Icon(
                                on
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_off_rounded,
                                size: 18,
                                color: on ? Y4.palette.honeyDeep : Y4.palette.muted,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      on
                                          ? (AppLocalizations.of(
                                                context,
                                              )?.notificationsOn ??
                                              'Notifications on')
                                          : (AppLocalizations.of(
                                                context,
                                              )?.notificationsOff ??
                                              'Notifications off'),
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Y4.palette.ink,
                                      ),
                                    ),
                                    Text(
                                      on
                                          ? (AppLocalizations.of(
                                                context,
                                              )?.notifOnDesc ??
                                              'You\'ll be notified about rewards, streaks & milestones.')
                                          : (AppLocalizations.of(
                                                context,
                                              )?.notifOffDesc ??
                                              'Inbox keeps existing items but no new ones will arrive.'),
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: Y4.palette.inkSoft,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: on,
                                onChanged:
                                    NotificationCenter.instance.setEnabled,
                                activeThumbColor: Y4.palette.honey,
                                activeTrackColor: Y4.palette.honeyDeep,
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: Y4.palette.track,
                              ),
                            ],
                          ),
                        ),
                  ),
                ),

                const SizedBox(height: 14),

                // List
                Expanded(
                  child: ValueListenableBuilder<List<NotificationItem>>(
                    valueListenable: NotificationCenter.instance.notifications,
                    builder: (_, list, __) {
                      if (list.isEmpty) {
                        return _EmptyState();
                      }
                      return ListView.separated(
                        controller: scroll,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder:
                            (_, i) => _NotificationTile(
                              n: list[i],
                              onTap: () {
                                Navigator.of(context).pop();
                                NotificationCenter.instance.requestNavigate(
                                  list[i],
                                );
                              },
                              onDismissed:
                                  () => NotificationCenter.instance.delete(
                                    list[i].id,
                                  ),
                            ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Y4.butter, Y4.honey]),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Y4.palette.honeyDeep.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Y4.honeyDeep,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppLocalizations.of(context)?.allCaughtUp ?? 'All caught up',
              style: Y4.display(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Y4.palette.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)?.whenYouEarnRewards ??
                  'When you earn rewards, hit a streak, or unlock a badge,\nit\'ll show up here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Y4.palette.inkSoft,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem n;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  const _NotificationTile({
    required this.n,
    required this.onTap,
    required this.onDismissed,
  });

  /// Per-category accent. We use Y4 tokens so the inbox blends with the
  /// rest of the app, but each category gets a slight identity tint.
  Color get _accent {
    switch (n.kind) {
      case NoorNotifKind.reward:
        return Y4.palette.honeyDeep;
      case NoorNotifKind.streak:
        return Y4.palette.honeyDeep;
      case NoorNotifKind.badge:
        return Y4.palette.amberY;
      case NoorNotifKind.donation:
        return Y4.palette.primary;
      case NoorNotifKind.validation:
        return Y4.palette.primaryDeep;
      case NoorNotifKind.system:
        return Y4.palette.inkSoft;
    }
  }

  String _localizeTitle(BuildContext context, String rawTitle) {
    if (rawTitle.startsWith('New badge unlocked')) {
      return '${AppLocalizations.of(context)?.newBadgeUnlocked ?? "New badge unlocked"} 🏆';
    }
    if (rawTitle.startsWith('Day sealed')) {
      return '${AppLocalizations.of(context)?.daySealed ?? "Day sealed"} 🌙';
    }
    if (rawTitle.startsWith('Daily login')) {
      return AppLocalizations.of(context)?.dailyLoginBonus ?? 'Daily login bonus';
    }
    if (rawTitle.contains('One Week')) return rawTitle.replaceFirst('One Week', AppLocalizations.of(context)?.oneWeek ?? 'One Week');
    if (rawTitle.contains('Two Weeks')) return rawTitle.replaceFirst('Two Weeks', AppLocalizations.of(context)?.twoWeeks ?? 'Two Weeks');
    return rawTitle;
  }

  String _localizeBody(BuildContext context, String rawBody) {
    if (rawBody.contains('Sabiq Seeds for sealing today')) {
      final pts = RegExp(r'\+(\d+)').firstMatch(rawBody)?.group(1) ?? '20';
      return AppLocalizations.of(context)?.pointsForSealing(pts) ?? '+$pts Sabiq Seeds for sealing today.';
    }
    if (rawBody.contains('welcome back')) {
      final pts = RegExp(r'\+(\d+)').firstMatch(rawBody)?.group(1) ?? '10';
      return AppLocalizations.of(context)?.welcomeBack(pts) ?? '+$pts Sabiq Seeds · welcome back!';
    }
    if (rawBody.contains('badge.')) {
      final badge = RegExp(r'"([^"]+)"').firstMatch(rawBody)?.group(1) ?? '';
      return AppLocalizations.of(context)?.badgeEarnedDesc(badge) ?? 'You have earned the "$badge" badge.';
    }
    if (rawBody.contains('streak')) {
      final parts = RegExp(r'(\d+)-day (.*?) streak · \+(\d+)').firstMatch(rawBody);
      if (parts != null) {
         final days = parts.group(1)!;
         final type = parts.group(2)!;
         final pts = parts.group(3)!;
         return AppLocalizations.of(context)?.streakBonus(days, type, pts) ?? rawBody;
      }
    }
    return rawBody;
  }

  @override
  Widget build(BuildContext context) {
    final String localTitle = _localizeTitle(context, n.title);
    final String localBody = _localizeBody(context, n.body);

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.redAccent,
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Y4.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: n.read ? Y4.border : _accent.withValues(alpha: 0.35),
              width: n.read ? 1 : 1.5,
            ),
            boxShadow:
                n.read
                    ? []
                    : [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon bubble
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Y4.palette.butter, _accent.withValues(alpha: 0.80)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: _accent.withValues(alpha: 0.80)),
                ),
                child: Center(
                  child: Text(
                    n.kind.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title + body + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            localTitle,
                            textDirection: RegExp(r'[\u0600-\u06FF]').hasMatch(localTitle) ? TextDirection.rtl : TextDirection.ltr,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight:
                                  n.read ? FontWeight.w600 : FontWeight.w800,
                              color: Y4.palette.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!n.read)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8, top: 5),
                            decoration: BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      localBody,
                      textDirection: RegExp(r'[\u0600-\u06FF]').hasMatch(n.body) ? TextDirection.rtl : TextDirection.ltr,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Y4.palette.inkSoft,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _relTime(context, n.createdAt),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: Y4.palette.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              if (n.route != null && n.route!.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 6, top: 14),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Y4.muted,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _relTime(BuildContext context, DateTime t) {
    final l10n = AppLocalizations.of(context);
    final delta = DateTime.now().difference(t);
    if (delta.inSeconds < 45) return l10n?.justNow ?? 'Just now';
    if (delta.inMinutes < 60) {
      return l10n?.mAgo(delta.inMinutes.toString()) ??
          '${delta.inMinutes}m ago';
    }
    if (delta.inHours < 24) {
      return l10n?.hAgo(delta.inHours.toString()) ?? '${delta.inHours}h ago';
    }
    if (delta.inDays < 7) {
      return l10n?.dAgo(delta.inDays.toString()) ?? '${delta.inDays}d ago';
    }
    return '${t.day}/${t.month}/${t.year}';
  }
}
