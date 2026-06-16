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
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
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

    // Resolve country + device independently so one failure can't kill the
    // other. Each helper has its own try/catch and returns sane defaults.
    String? country;
    try {
      country = await _resolveCountryCode();
    } catch (e) {
      debugPrint('[TrackingService] country resolve failed: $e');
    }

    (String, String) deviceInfo = ('Unknown', Platform.operatingSystem);
    try {
      deviceInfo = await _resolveDevice();
    } catch (e) {
      debugPrint('[TrackingService] device resolve failed: $e');
    }

    try {
      await _sb.from('user_analytics').upsert({
        'user_id': uid,
        'country_code': country,
        'device_model': deviceInfo.$1,
        'device_type': deviceInfo.$2,
        'last_active_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('[TrackingService] upsert failed: $e');
    }
  }

  /// Returns ISO 3166-1 alpha-2 country code ('PK', 'GB', …).
  ///
  /// Tries two HTTPS-only free providers in order so a single outage or rate
  /// limit on one doesn't blank out everyone's country. The raw IP is NEVER
  /// stored — we only keep the country code.
  Future<String?> _resolveCountryCode() async {
    // Provider 1: api.country.is — simplest, no rate limit, returns
    // {"ip":"...","country":"PK"}.
    final fromCountryIs = await _fetchCountry(
      Uri.parse('https://api.country.is/'),
      jsonKey: 'country',
    );
    if (fromCountryIs != null) return fromCountryIs;

    // Provider 2: ipapi.co — free 1000/day, returns
    // {"country_code":"PK", ...}.
    final fromIpApi = await _fetchCountry(
      Uri.parse('https://ipapi.co/json/'),
      jsonKey: 'country_code',
    );
    if (fromIpApi != null) return fromIpApi;

    debugPrint('[TrackingService] both country providers failed');
    return null;
  }

  Future<String?> _fetchCountry(Uri url, {required String jsonKey}) async {
    try {
      final res = await http
          .get(
            url,
            headers: const {'User-Agent': 'noor-rewards/1.0'},
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) {
        debugPrint(
          '[TrackingService] $url returned HTTP ${res.statusCode}: ${res.body.substring(0, res.body.length < 120 ? res.body.length : 120)}',
        );
        return null;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final code = data[jsonKey] as String?;
      if (code != null && code.length == 2) return code.toUpperCase();
      debugPrint('[TrackingService] $url returned unexpected body: ${res.body}');
    } catch (e) {
      debugPrint('[TrackingService] $url fetch threw: $e');
    }
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
