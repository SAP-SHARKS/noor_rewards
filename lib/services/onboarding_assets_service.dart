// lib/services/onboarding_assets_service.dart
//
// Resolves admin-uploaded onboarding images by slot key.
//
// The admin web panel writes rows to the `onboarding_images` table
// (slot_key → image_url) and uploads files to the `onboarding-images`
// storage bucket. This singleton caches that mapping in Hive so the
// onboarding flow renders instantly even on a cold start with no network.
//
// Slot keys (11):
//   onb_hero_1, onb_aid_2, onb_quran_2, onb_quran_3, onb_zikr_4,
//   onb_impact_5, onb_akhirah_7,
//   cause_orphans, cause_water, cause_war, cause_disaster

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingAssetsService {
  OnboardingAssetsService._();
  static final OnboardingAssetsService instance = OnboardingAssetsService._();

  static const _boxName = 'onboarding_images_cache';

  /// Reactive map of slot_key → image_url. Widgets watch this notifier so
  /// hot-swapped URLs (after an admin upload during the same session) take
  /// effect immediately.
  final ValueNotifier<Map<String, String>> images = ValueNotifier({});

  bool _initialized = false;

  /// Load cached values from Hive, then fetch fresh values from Supabase
  /// in the background. Safe to call multiple times — no-ops after the
  /// first successful init.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final box = await Hive.openBox<String>(_boxName);
      final cached = <String, String>{};
      for (final k in box.keys) {
        final v = box.get(k);
        if (v != null && v.isNotEmpty) cached[k.toString()] = v;
      }
      if (cached.isNotEmpty) images.value = cached;
    } catch (_) {
      // Hive not ready — fall through to network fetch.
    }
    // Fire-and-forget refresh from Supabase.
    refresh();
  }

  /// Pull latest rows from `onboarding_images` and update both the in-memory
  /// notifier and the Hive cache. Safe to call any time.
  Future<void> refresh() async {
    try {
      final rows = await Supabase.instance.client
          .from('onboarding_images')
          .select('slot_key, image_url');
      final next = <String, String>{};
      for (final r in rows as List) {
        final key = r['slot_key'] as String?;
        final url = r['image_url'] as String?;
        if (key != null && url != null && url.isNotEmpty) next[key] = url;
      }
      images.value = next;
      try {
        final box = await Hive.openBox<String>(_boxName);
        await box.clear();
        await box.putAll(next);
      } catch (_) {}
    } catch (_) {
      // Silent — preserve whatever was cached.
    }
  }

  /// Returns the image URL for [slotKey] or null if no upload exists yet.
  String? urlFor(String slotKey) => images.value[slotKey];
}
