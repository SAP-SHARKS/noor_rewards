import 'package:firebase_messaging/firebase_messaging.dart';

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

    // Optional: get token for testing
    // final token = await messaging.getToken();
    // print('FCM Token: $token');
  }
}
