// PushNotificationBuilder
//
// Turns an FCM RemoteMessage into a rich Android notification with a
// category-driven large icon and optional BigPicture preview. Used by
// both `NotificationService.onMessage` (foreground) and the top-level
// `firebaseMessagingBackgroundHandler` (killed/background) so the visual
// treatment is identical regardless of app state.
//
// Payload contract (all custom keys live under RemoteMessage.data):
//   type                — notification_type (mapped to a bundled drawable)
//   notification_category — optional explicit category override
//                           ('streak' | 'milestone' | 'community' | 'reminder')
//   avatar_icon_url     — optional URL for a per-user round largeIcon
//                         (e.g. a donor's profile pic). Takes precedence
//                         over the category drawable.
//   large_preview_url   — optional URL for a BigPicture attachment shown
//                         at the bottom of an expanded notification.
//   image               — alias for large_preview_url so servers can
//                         continue to use the FCM-standard field name
//                         when the message is sent data-only.
//   title / body        — mandatory when the server sends data-only.
//                         (When both notification+data are present the
//                         builder falls back to notification.title/body.)
//   route               — deep-link destination consumed on tap by
//                         `NotificationService.handleDeepLinkRoute`.
//   nid                 — notification-log id, passed through unchanged
//                         so tap logging via `mark_notification_opened`
//                         still works.
//
// Robust fallbacks (all silent so a bad server payload never suppresses
// the user's notification):
//   avatar_icon_url fetch fails → category drawable
//   category drawable missing  → app launcher icon
//   large_preview_url fetch fails → no BigPicture, notification still
//                                    shows title + body + icon
//   Firebase re-init errors in background isolate → notification
//                                    suppressed rather than crash-loop

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

/// Channel details are duplicated (not imported) so the top-level
/// background handler doesn't accidentally pull in the whole service
/// graph.
const String kPushChannelId = 'sabiq_default_channel';
const String kPushChannelName = 'Sabiq Rewards Notifications';

class PushNotificationBuilder {
  PushNotificationBuilder._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Non-negative modulo so `.hashCode` maps cleanly to a positive
  /// Android notification id (the plugin rejects negatives).
  static int _idFor(String seed) {
    final h = seed.hashCode;
    return (h < 0 ? -h : h) & 0x7fffffff;
  }

  /// Foreground and background entrypoint. Reads the RemoteMessage,
  /// resolves the icon + image, and posts a rich local notification.
  static Future<void> show(RemoteMessage message) async {
    try {
      final data = message.data;
      final rn = message.notification;

      final title = (data['title'] as String?) ??
          rn?.title ??
          'Sabiq Rewards';
      final body = (data['body'] as String?) ?? rn?.body ?? '';
      if (title.trim().isEmpty && body.trim().isEmpty) return;

      final route = data['route'] as String?;
      final nid = data['nid'] as String?;
      final largePreviewUrl = (data['large_preview_url'] as String?) ??
          (data['image'] as String?) ??
          rn?.android?.imageUrl ??
          rn?.apple?.imageUrl;

      // Rolled back to the app's launcher icon for every notification.
      // Rationale: category-based small icons render tiny on MIUI (24dp
      // slot with MIUI's own dark chrome around it), which reads as
      // "small icon with a black layer". Using the launcher icon lets
      // MIUI apply its "this is the app" decoration which renders it
      // large and cleanly — matching the pre-customisation look the
      // user preferred. Category differentiation via icon is on hold.
      //
      // Payload keys still parsed (route, nid, category, type) so tap
      // handling, deep-link routing, and open-tracking keep working;
      // only the icon-selection logic is neutralised here.

      StyleInformation? style;
      if (largePreviewUrl != null && largePreviewUrl.isNotEmpty) {
        final imgBytes = await _downloadImage(largePreviewUrl);
        if (imgBytes != null) {
          style = BigPictureStyleInformation(
            ByteArrayAndroidBitmap(imgBytes),
            hideExpandedLargeIcon: true,
            contentTitle: title,
            summaryText: body,
          );
        }
      }

      final android = AndroidNotificationDetails(
        kPushChannelId,
        kPushChannelName,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: style,
      );

      // Encode route + nid in the payload so the tap handler in
      // LocalReminderScheduler.init (which shares FCM's deep-link
      // router) still gets the routing info even though this message
      // was originally an FCM push, not a locally-scheduled reminder.
      final payload = jsonEncode({
        'route': route ?? '',
        'nid': nid ?? '',
      });

      await _plugin.show(
        id: _idFor(message.messageId ?? nid ?? '${title}_$body'),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: android,
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      // Never crash a background isolate — a swallowed push is
      // survivable, a crash loop is not.
      debugPrint('[PushNotificationBuilder] show failed: $e');
    }
  }

  /// Category → coloured coin drawable NAME. Category wins over type
  static Future<Uint8List?> _downloadImage(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return res.bodyBytes;
      }
    } catch (e) {
      debugPrint('[PushNotificationBuilder] download failed for $url: $e');
    }
    return null;
  }
}
