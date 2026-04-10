import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    print('FCM_TOKEN: $token');

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (token != null && userId != null) {
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        final String currentTimeZone = timezoneInfo.identifier;
        await Supabase.instance.client.from('fcm_tokens').upsert({
          'user_id': userId,
          'token': token,
          'timezone': currentTimeZone,
        });
      } catch (e) {
        print('Error saving FCM token and timezone: $e');
      }
    }
  }
}
