import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // Request notification permissions
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Get token
    final token = await messaging.getToken();
    debugPrint('FCM_TOKEN: $token');

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (token != null && userId != null) {
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        final String currentTimeZone = timezoneInfo.identifier;
        await Supabase.instance.client.from('fcm_tokens').upsert({
          'user_id': userId,
          'token': token,
          'timezone': currentTimeZone,
          'device_type': 'android',
          'last_seen': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'user_id');
      } catch (e) {
        debugPrint('Error saving FCM token and timezone: $e');
      }
    }

    // Listen for continuous native token refreshes to ensure notifications never break
    messaging.onTokenRefresh.listen((newToken) async {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId != null) {
        try {
          final tzInfo = await FlutterTimezone.getLocalTimezone();
          await Supabase.instance.client.from('fcm_tokens').upsert({
            'user_id': currentUserId,
            'token': newToken,
            'timezone': tzInfo.identifier,
            'device_type': 'android',
            'last_seen': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id');
          debugPrint('FCM_TOKEN REFRESHED: $newToken');
        } catch (e) {
          debugPrint('Error saving refreshed FCM token: $e');
        }
      }
    });
  }
}
