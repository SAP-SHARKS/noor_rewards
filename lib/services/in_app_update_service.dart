// lib/services/in_app_update_service.dart
//
// Thin wrapper around the `in_app_update` plugin (Google Play Core
// `app-update` SDK). Drives the two officially-sanctioned update flows:
//
//   • Flexible  — downloads in the background while the user keeps
//                 using the app, then prompts them to restart.
//   • Immediate — full-screen blocking dialog the user can't skip.
//
// Which one fires is decided by Google Play itself, driven by the
// "update priority" integer (0–5) set on the Play Console release:
//
//      Priority   Flow used
//      ────────   ─────────────────────────────
//      0 – 2      Flexible (background, optional UX nudge)
//      3 – 5      Immediate (mandatory blocking dialog)
//
// We default to Flexible when priority isn't returned. Android-only;
// silently no-ops on iOS / web / desktop.

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class InAppUpdateService {
  InAppUpdateService._();
  static final InAppUpdateService instance = InAppUpdateService._();

  bool _running = false;

  /// Threshold at which we switch from Flexible → Immediate. Tweak in one
  /// place if the team later decides "priority 4+" should be mandatory
  /// rather than 3+.
  static const int _immediateThreshold = 3;

  /// Probe Play for an available update and surface the appropriate flow.
  /// Safe to call from `main` on every launch — bails fast on iOS and on
  /// the "no update available" case.
  Future<void> checkOnLaunch() async {
    if (_running) return;
    _running = true;
    try {
      // The plugin throws PlatformException on non-Android. Catch it
      // silently so we don't crash other platforms.
      if (defaultTargetPlatform != TargetPlatform.android) return;

      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      final priority = info.updatePriority;
      final immediateAllowed = info.immediateUpdateAllowed;
      final flexibleAllowed = info.flexibleUpdateAllowed;

      if (priority >= _immediateThreshold && immediateAllowed) {
        // Critical release — blocking dialog. The user cannot bypass it.
        await InAppUpdate.performImmediateUpdate();
      } else if (flexibleAllowed) {
        // Standard release — quiet background download.
        await InAppUpdate.startFlexibleUpdate();
        // When the bytes are on device, hand control back to Play so the
        // 2-second install + auto-restart can happen.
        await InAppUpdate.completeFlexibleUpdate();
      } else if (immediateAllowed) {
        // Play didn't allow flexible but did allow immediate — fall back.
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      // Don't let an update-check failure ever block app launch.
      debugPrint('[InAppUpdate] check failed: $e');
    } finally {
      _running = false;
    }
  }
}
