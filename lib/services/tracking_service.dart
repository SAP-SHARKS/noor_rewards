// lib/services/tracking_service.dart
//
// Privacy-first analytics.
//   • No IP addresses stored
//   • No GPS / location permissions required
//   • Country resolved server-side via ip-api.com (free, no key needed)
//   • All writes are tied to auth.uid() — RLS enforced on Supabase

import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

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

    try {
      // Accumulate session time into the existing row
      await _sb.rpc('analytics_add_session', params: {
        'p_user_id':    uid,
        'p_duration':   durationSec,
        'p_coins':      _coinsThisSession,
      });
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

    try {
      final country    = await _resolveCountryCode();
      final deviceInfo = await _resolveDevice();

      await _sb.from('user_analytics').upsert({
        'user_id':      uid,
        'country_code': country,
        'device_model': deviceInfo.$1,
        'device_type':  deviceInfo.$2,
        'last_active_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (_) {}
  }

  /// Returns ISO 3166-1 alpha-2 country code ('PK', 'GB', …) using ip-api.
  /// The raw IP is NEVER stored — we only keep the country code.
  Future<String?> _resolveCountryCode() async {
    try {
      final res = await http
          .get(Uri.parse('http://ip-api.com/json/?fields=countryCode'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['countryCode'] as String?;
      }
    } catch (_) {}
    return null;
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
