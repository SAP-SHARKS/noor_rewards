// lib/services/settings_service.dart
// Singleton that:
//  1) Fetches ALL rows from app_config on startup.
//  2) Subscribes to Supabase Realtime for instant live updates.
//  3) Notifies listeners (via ChangeNotifier) so Provider rebuilds the tree.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_config.dart';

class SettingsService extends ChangeNotifier {
  // ── Singleton ────────────────────────────────────────────────────────────
  SettingsService._();
  static final instance = SettingsService._();

  // ── State ────────────────────────────────────────────────────────────────
  AppConfig _config = AppConfig.empty();
  bool _loaded = false;
  RealtimeChannel? _channel;

  AppConfig get config => _config;
  bool      get loaded => _loaded;

  // ── Supabase client ───────────────────────────────────────────────────────
  final _sb = Supabase.instance.client;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Call once from main() before runApp.  Subscribes to Realtime.
  Future<void> initialize() async {
    await _fetch();
    _subscribeRealtime();
  }

  /// Update a single key (called from Admin panel). Persists to DB.
  Future<void> updateKey(String key, String value, {String? adminEmail}) async {
    // Optimistic UI update
    _config = _config.copyWith(key, value);
    notifyListeners();

    await _sb.from('app_config').update({
      'value':      value,
      'updated_at': DateTime.now().toIso8601String(),
      if (adminEmail != null) 'updated_by': adminEmail,
    }).eq('key', key);
    // Realtime will broadcast the official change back; we stay in sync.
  }

  /// Update multiple keys in one shot.
  Future<void> updateKeys(Map<String, String> updates, {String? adminEmail}) async {
    final raw = Map<String, String>.from(_config.raw);
    raw.addAll(updates);
    _config = AppConfig(raw);
    notifyListeners();

    for (final entry in updates.entries) {
      await _sb.from('app_config').update({
        'value':      entry.value,
        'updated_at': DateTime.now().toIso8601String(),
        if (adminEmail != null) 'updated_by': adminEmail,
      }).eq('key', entry.key);
    }
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _fetch() async {
    try {
      final rows = await _sb
          .from('app_config')
          .select('key, value');
      final map = <String, String>{};
      for (final row in rows) {
        map[row['key'] as String] = row['value'] as String;
      }
      _config = AppConfig(map);
      _loaded = true;
    } catch (e) {
      debugPrint('SettingsService: fetch error: $e');
    }
    notifyListeners();
  }

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = _sb
        .channel('app_config_changes')
        .onPostgresChanges(
          event:  PostgresChangeEvent.all,
          schema: 'public',
          table:  'app_config',
          callback: (payload) {
            // Any INSERT / UPDATE / DELETE → re-fetch the full table
            // (cheap: ~30 tiny rows)
            _fetch();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
