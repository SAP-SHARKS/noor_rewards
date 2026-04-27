import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/dhikr_screen.dart';

/// Global navigator key — pass to [MaterialApp.navigatorKey] in main.dart.
/// Used to push routes from FCM tap handlers outside the widget tree.
final GlobalKey<NavigatorState> notificationNavigatorKey =
    GlobalKey<NavigatorState>();

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // ── Public entry point ──────────────────────────────────────────────────────
  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // Request notification permission
    await messaging.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );

    // Get FCM token
    final token = await messaging.getToken();
    debugPrint('FCM_TOKEN: $token');

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (token != null && userId != null) {
      await _saveTokenWithLocation(token: token, userId: userId);
    }

    // Re-save on token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) await _saveTokenWithLocation(token: newToken, userId: uid);
    });

    // ── Deep-link handling ────────────────────────────────────────────────────
    // Cold start (app was killed)
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      _handleMessageTap(initialMessage);
    }

    // Background → foreground
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }

  // ── GPS + timezone detection ────────────────────────────────────────────────
  Future<void> _saveTokenWithLocation({
    required String token,
    required String userId,
  }) async {
    // Attempt GPS → precise IANA timezone first, system tz as fallback
    String timezone = 'UTC';
    double? latitude;
    double? longitude;

    try {
      final pos = await _getLocation();
      if (pos != null) {
        latitude  = pos.latitude;
        longitude = pos.longitude;
        timezone  = await _timezoneFromCoords(pos.latitude, pos.longitude)
                    ?? await _systemTimezone();
        debugPrint('📍 GPS timezone: $timezone ($latitude, $longitude)');
      } else {
        timezone = await _systemTimezone();
        debugPrint('📍 System timezone fallback: $timezone');
      }
    } catch (e) {
      timezone = await _systemTimezone();
      debugPrint('📍 Location error ($e) — using system timezone: $timezone');
    }

    try {
      await Supabase.instance.client.from('fcm_tokens').upsert({
        'user_id':    userId,
        'token':      token,
        'timezone':   timezone,
        'latitude':   latitude,
        'longitude':  longitude,
        'device_type': 'android',
        'last_seen':  DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Requests location permission and returns current position.
  /// Returns null if denied or unavailable.
  Future<Position?> _getLocation() async {
    // Check if location services are enabled at OS level
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('📍 Location services disabled');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // This triggers the Android system permission dialog
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('📍 Location permission denied');
      return null;
    }

    // Get a low-accuracy position quickly (good enough for timezone)
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Calls timeapi.io (free, no API key) to get IANA timezone from coordinates.
  Future<String?> _timezoneFromCoords(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://timeapi.io/api/timezone/coordinate?latitude=$lat&longitude=$lng',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final tz = data['timeZone'] as String?;
        return (tz != null && tz.isNotEmpty) ? tz : null;
      }
    } catch (e) {
      debugPrint('timeapi.io error: $e');
    }
    return null;
  }

  /// Reads device system timezone (accurate when "auto timezone" is on).
  Future<String> _systemTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      return info.identifier;
    } catch (_) {
      return 'UTC';
    }
  }

  // ── Notification tap → deep link ────────────────────────────────────────────
  void _handleMessageTap(RemoteMessage message) {
    final route = message.data['route'] as String?;
    debugPrint('FCM tap — route: $route');

    final nav = notificationNavigatorKey.currentState;
    if (nav == null) return;

    switch (route) {
      case 'morning':
        nav.push(MaterialPageRoute(
          builder: (_) => const DhikrScreen(initialCategory: 'morning'),
        ));
        break;
      case 'evening':
        nav.push(MaterialPageRoute(
          builder: (_) => const DhikrScreen(initialCategory: 'evening'),
        ));
        break;
      case 'sleeping':
        nav.push(MaterialPageRoute(
          builder: (_) => const DhikrScreen(initialCategory: 'sleeping'),
        ));
        break;
      default:
        // Nightly check-in or unknown — just brings app to foreground
        break;
    }
  }
}
