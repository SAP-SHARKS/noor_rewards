// lib/services/notification_center.dart
//
// Local in-app notification inbox.
// ─────────────────────────────────────────────────────────────────────────────
// Stores notifications in a Hive box so they persist across sessions,
// works fully offline, and never blocks the UI thread.
//
// Public surface
//   • NotificationCenter.instance      — singleton
//   • notifications  (ValueListenable<List<NotificationItem>>)
//   • unreadCount    (ValueListenable<int>)
//   • enabled        (ValueListenable<bool>)  — master on/off
//   • init(), add(), markRead(), markAllRead(), delete(), clear()
//   • setEnabled(bool)
//
// The dashboard bell button rebuilds via the unreadCount listenable; the
// inbox sheet rebuilds via the notifications listenable. No Provider needed.
//
// Tapping a notification fires its [route] through Flutter's root navigator
// using onNavigateRequest — wired up in the dashboard so we can switch tabs
// or push the right hub screen.

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Categories of in-app notifications. The user can toggle them individually
/// (per-category toggles surface in profile settings; for now we only ship a
/// master on/off).
enum NoorNotifKind {
  reward, // +XP / +pts earned
  streak, // streak milestone hit
  badge, // new achievement unlocked
  donation, // donation succeeded
  validation, // user sealed the day
  system, // generic info
}

extension NoorNotifKindIcon on NoorNotifKind {
  /// Default emoji icon for the category. The sheet UI uses this when a
  /// notification doesn't carry its own custom icon.
  String get emoji {
    switch (this) {
      case NoorNotifKind.reward:
        return '⭐';
      case NoorNotifKind.streak:
        return '🔥';
      case NoorNotifKind.badge:
        return '🏆';
      case NoorNotifKind.donation:
        return '💝';
      case NoorNotifKind.validation:
        return '🌙';
      case NoorNotifKind.system:
        return '🔔';
    }
  }
}

/// A single inbox entry. Hive stores these as JSON-friendly maps so we don't
/// need to register a TypeAdapter — keeps the dependency surface tiny.
class NotificationItem {
  final String id;
  final NoorNotifKind kind;
  final String title;
  final String body;
  final String? route; // e.g. '/journey', '/quran', '/akhirah'
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool read;

  NotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.route,
    this.data,
    required this.createdAt,
    this.read = false,
  });

  NotificationItem copyWith({bool? read}) => NotificationItem(
    id: id,
    kind: kind,
    title: title,
    body: body,
    route: route,
    data: data,
    createdAt: createdAt,
    read: read ?? this.read,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'body': body,
    'route': route,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
  };

  static NotificationItem fromMap(Map m) => NotificationItem(
    id: m['id'] as String,
    kind: NoorNotifKind.values.firstWhere(
      (k) => k.name == (m['kind'] as String?),
      orElse: () => NoorNotifKind.system,
    ),
    title: m['title'] as String? ?? '',
    body: m['body'] as String? ?? '',
    route: m['route'] as String?,
    data: (m['data'] as Map?)?.cast<String, dynamic>(),
    createdAt:
        DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
    read: m['read'] as bool? ?? false,
  );
}

class NotificationCenter {
  NotificationCenter._();
  static final instance = NotificationCenter._();

  static const _boxName = 'noor_notifications';
  static const _itemsKey = 'items';
  static const _enabledKey = 'enabled';

  Box? _box;
  bool _initialized = false;

  /// Live list of notifications, newest first. Listenable so widgets can
  /// rebuild via [ValueListenableBuilder] without any Provider plumbing.
  final ValueNotifier<List<NotificationItem>> notifications = ValueNotifier(
    const [],
  );

  /// Count of unread notifications — drives the dashboard bell badge.
  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  /// Master on/off switch. When `false`, [add] is a no-op so the user
  /// genuinely stops getting new notifications. Existing inbox items are kept.
  final ValueNotifier<bool> enabled = ValueNotifier(true);

  /// Optional callback that hands a route string back to the parent so it
  /// can drive navigation (switch tab, push screen, etc.). Set this once
  /// from the dashboard.
  void Function(String route, Map<String, dynamic>? data)? onNavigateRequest;

  /// Open Hive box and hydrate state. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;
    try {
      _box = await Hive.openBox(_boxName);
      _hydrate();
      _initialized = true;
    } catch (e) {
      debugPrint('[NotificationCenter] init failed: $e');
    }
  }

  void _hydrate() {
    final raw = _box?.get(_itemsKey);
    if (raw is List) {
      final list = <NotificationItem>[];
      for (final m in raw) {
        if (m is Map) {
          try {
            list.add(NotificationItem.fromMap(m));
          } catch (_) {}
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifications.value = list;
      unreadCount.value = list.where((n) => !n.read).length;
    }
    final on = _box?.get(_enabledKey);
    if (on is bool) enabled.value = on;
  }

  Future<void> _persist() async {
    try {
      await _box?.put(
        _itemsKey,
        notifications.value.map((n) => n.toMap()).toList(),
      );
    } catch (e) {
      debugPrint('[NotificationCenter] persist failed: $e');
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────

  /// Add a new notification. No-op if [enabled] is `false`.
  /// Returns the inserted item, or `null` if notifications are disabled.
  NotificationItem? add({
    required NoorNotifKind kind,
    required String title,
    required String body,
    String? route,
    Map<String, dynamic>? data,
  }) {
    if (!enabled.value) return null;
    final item = NotificationItem(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      title: title,
      body: body,
      route: route,
      data: data,
      createdAt: DateTime.now(),
    );
    final next = [item, ...notifications.value];
    // Cap the inbox at 100 items to keep storage tiny.
    if (next.length > 100) next.removeRange(100, next.length);
    notifications.value = next;
    unreadCount.value = unreadCount.value + 1;
    _persist();
    return item;
  }

  Future<void> markRead(String id) async {
    var changed = false;
    final next =
        notifications.value.map((n) {
          if (n.id == id && !n.read) {
            changed = true;
            return n.copyWith(read: true);
          }
          return n;
        }).toList();
    if (!changed) return;
    notifications.value = next;
    unreadCount.value = next.where((n) => !n.read).length;
    await _persist();
  }

  Future<void> markAllRead() async {
    if (notifications.value.every((n) => n.read)) return;
    notifications.value =
        notifications.value.map((n) => n.copyWith(read: true)).toList();
    unreadCount.value = 0;
    await _persist();
  }

  Future<void> delete(String id) async {
    final next = notifications.value.where((n) => n.id != id).toList();
    notifications.value = next;
    unreadCount.value = next.where((n) => !n.read).length;
    await _persist();
  }

  Future<void> clear() async {
    notifications.value = const [];
    unreadCount.value = 0;
    await _persist();
  }

  Future<void> setEnabled(bool on) async {
    enabled.value = on;
    try {
      await _box?.put(_enabledKey, on);
    } catch (_) {}
  }

  /// Trigger navigation request for a notification. The dashboard wires
  /// [onNavigateRequest] to handle this — switches tab, pushes hub screen, etc.
  void requestNavigate(NotificationItem n) {
    markRead(n.id);
    final route = n.route;
    if (route == null || route.isEmpty) return;
    onNavigateRequest?.call(route, n.data);
  }
}
