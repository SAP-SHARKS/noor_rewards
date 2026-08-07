// lib/services/tracking_service.dart
//
// Privacy-first analytics.
//   • No IP addresses stored
//   • No GPS / location permissions required
//   • No external IP → country lookup — profiles.country (user-entered at
//     onboarding) is the authoritative source; user_analytics.country_code
//     is left NULL for new rows (column + analytics_country_summary view
//     preserved for historical data)
//   • All writes are tied to auth.uid() — RLS enforced on Supabase

import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'stats_service.dart';

class TrackingService {
  TrackingService._();
  static final TrackingService instance = TrackingService._();

  final _sb = Supabase.instance.client;
  final _deviceInfo = DeviceInfoPlugin();

  DateTime? _sessionStart;
  int _coinsThisSession = 0;

  // ── Session lifecycle ──────────────────────────────────────────────────────

  /// Call once when the user is authenticated and home screen is shown.
  Future<void> beginSession() async {
    _sessionStart = DateTime.now();
    _coinsThisSession = 0;

    // Fire-and-forget initial upsert so the user_analytics row exists
    await _ensureRow();
  }

  /// Call when the user background the app or signs out.
  Future<void> endSession() async {
    if (_sessionStart == null) return;
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;

    final durationSec = DateTime.now().difference(_sessionStart!).inSeconds;
    _sessionStart = null;

    // Flush any pending screen time before ending session
    await StatsService.instance.exitScreen();

    try {
      // Accumulate session time into the existing row
      await _sb.rpc(
        'analytics_add_session',
        params: {
          'p_user_id': uid,
          'p_duration': durationSec,
          'p_coins': _coinsThisSession,
        },
      );
    } catch (_) {
      // Fail silently — analytics must never crash the app
    }
  }

  /// Call whenever the user earns coins (from XpService etc.)
  void recordCoins(int amount) {
    _coinsThisSession += amount;
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _ensureRow() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;

    (String, String) deviceInfo = ('Unknown', Platform.operatingSystem);
    try {
      deviceInfo = await _resolveDevice();
    } catch (e) {
      debugPrint('[TrackingService] device resolve failed: $e');
    }

    try {
      // country_code intentionally OMITTED from the payload — the app no
      // longer performs an IP → country lookup, and profiles.country
      // (user-entered at onboarding) is the authoritative source.
      // Do NOT write `'country_code': null` here: this is an upsert with
      // onConflict: 'user_id', so explicitly writing null would overwrite
      // any existing value for returning users. Omitting the key means
      // new rows default to NULL while existing rows keep whatever value
      // was written before this change, preserving historical data.
      await _sb.from('user_analytics').upsert({
        'user_id': uid,
        'device_model': deviceInfo.$1,
        'device_type': deviceInfo.$2,
        'last_active_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('[TrackingService] upsert failed: $e');
    }
  }

  /// Returns (model, type) e.g. ('Pixel 7', 'Android').
  Future<(String, String)> _resolveDevice() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return ('${info.brand} ${info.model}', 'Android');
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return (info.utsname.machine, 'iOS');
      }
    } catch (_) {}
    return ('Unknown', Platform.operatingSystem);
  }
}
