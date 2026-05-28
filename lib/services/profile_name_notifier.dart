// lib/services/profile_name_notifier.dart
//
// A small global ValueNotifier that broadcasts the user's current display
// name across the app. Acts as a *fallback* signal so a settings save is
// guaranteed to propagate even if the Supabase auth stream's userUpdated
// event is missed (timing / cache edge cases).
//
// Write: profile_settings_screen.dart on successful save.
// Read:  AuthGate uses this as the highest-priority source for displayName.

import 'package:flutter/foundation.dart';

class ProfileNameNotifier {
  ProfileNameNotifier._();
  static final ProfileNameNotifier instance = ProfileNameNotifier._();

  /// Current display name. `null` means "no override — fall back to whatever
  /// the auth/profile source says".
  final ValueNotifier<String?> name = ValueNotifier<String?>(null);

  /// Push a freshly saved name. Listeners (e.g. AuthGate) rebuild instantly.
  void set(String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      name.value = null;
      return;
    }
    name.value = trimmed;
  }

  /// Clear the override (e.g. on logout) so the next session starts fresh.
  void clear() {
    name.value = null;
  }
}
