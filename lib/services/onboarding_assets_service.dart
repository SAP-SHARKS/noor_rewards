// lib/services/onboarding_assets_service.dart
//
// Resolves admin-managed onboarding images by slot key.
//
// The admin web panel writes rows to the `onboarding_images` table
// (slot_key → image_url + image_fit) and uploads files to the
// `onboarding-images` storage bucket. This singleton caches that mapping
// in Hive so the onboarding flow renders instantly even on a cold start
// with no network.
//
// Slot keys (13):
//   onb_hero_1, onb_aid_2, onb_quran_2, onb_quran_3,
//   onb_step_quran, onb_step_orphans, onb_zikr_4,
//   onb_impact_5, onb_akhirah_7,
//   cause_orphans, cause_water, cause_war, cause_disaster

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One admin-managed onboarding image: its public URL plus an optional
/// crop/fit preference the admin picked in the web panel.
///
/// [fit] is one of: 'cover_center', 'cover_top', 'cover_bottom',
/// 'contain', 'fill'. Null means "use the app's built-in default for the
/// slot" (the fit the calling screen passed to PhotoSlot).
class OnbImage {
  final String url;
  final String? fit;
  const OnbImage({required this.url, this.fit});
}

class OnboardingAssetsService {
  OnboardingAssetsService._();
  static final OnboardingAssetsService instance = OnboardingAssetsService._();

  static const _boxName = 'onboarding_images_cache';

  /// Reactive map of slot_key → [OnbImage]. Widgets watch this notifier so
  /// hot-swapped images / fit changes (after an admin edit during the same
  /// session) take effect immediately.
  final ValueNotifier<Map<String, OnbImage>> images = ValueNotifier({});

  bool _initialized = false;

  /// Load cached values from Hive, then fetch fresh values from Supabase
  /// in the background. Safe to call multiple times — no-ops after the
  /// first successful init.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final box = await Hive.openBox<String>(_boxName);
      final cached = <String, OnbImage>{};
      for (final k in box.keys) {
        final parsed = _decode(box.get(k));
        if (parsed != null) cached[k.toString()] = parsed;
      }
      if (cached.isNotEmpty) images.value = cached;
    } catch (_) {
      // Hive not ready — fall through to network fetch.
    }
    // Warm whatever URLs we already have cached (instant on 2nd+ runs),
    // then refresh from Supabase.
    _warmCache();
    refresh();
  }

  /// Pull latest rows from `onboarding_images` and update both the in-memory
  /// notifier and the Hive cache. Safe to call any time.
  Future<void> refresh() async {
    try {
      final rows = await Supabase.instance.client
          .from('onboarding_images')
          .select('slot_key, image_url, image_fit');
      final next = <String, OnbImage>{};
      for (final r in rows as List) {
        final key = r['slot_key'] as String?;
        final url = r['image_url'] as String?;
        final fit = r['image_fit'] as String?;
        if (key != null && url != null && url.isNotEmpty) {
          next[key] = OnbImage(
            url: url,
            fit: (fit != null && fit.isNotEmpty) ? fit : null,
          );
        }
      }
      images.value = next;
      _warmCache();
      try {
        final box = await Hive.openBox<String>(_boxName);
        await box.clear();
        await box.putAll(next.map((k, v) => MapEntry(k, _encode(v))));
      } catch (_) {}
    } catch (_) {
      // Silent — preserve whatever was cached.
    }
  }

  static String _encode(OnbImage img) =>
      jsonEncode({'url': img.url, 'fit': img.fit});

  static OnbImage? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final url = m['url'] as String?;
      if (url == null || url.isEmpty) return null;
      return OnbImage(url: url, fit: m['fit'] as String?);
    } catch (_) {
      // Legacy cache entries were stored as a plain URL string.
      return raw.startsWith('http') ? OnbImage(url: raw) : null;
    }
  }

  /// Returns the image URL for [slotKey] or null if no upload exists yet.
  String? urlFor(String slotKey) => images.value[slotKey]?.url;

  /// Returns the admin-chosen crop/fit token for [slotKey], or null when
  /// the admin hasn't overridden it.
  String? fitFor(String slotKey) => images.value[slotKey]?.fit;

  /// Downloads every known onboarding image into the cached_network_image
  /// disk cache and Flutter's image cache — with NO BuildContext required.
  ///
  /// Called from [init]/[refresh], which run at app boot while the splash
  /// plays. By the time the user reaches the onboarding flow the images
  /// are already decoded in memory, so each slide paints instantly instead
  /// of kicking off a download when its page first appears.
  void _warmCache() {
    for (final img in images.value.values) {
      if (img.url.isEmpty) continue;
      final stream = CachedNetworkImageProvider(
        img.url,
      ).resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (_, __) => stream.removeListener(listener),
        onError: (_, __) => stream.removeListener(listener),
      );
      stream.addListener(listener);
    }
  }

  /// Warm Flutter's image cache with every known onboarding URL so the
  /// slides paint instantly — no spinners, no blank slots — even on the
  /// user's first session.
  ///
  /// Safe to call multiple times; precacheImage is idempotent (a second
  /// call for an already-cached image is a no-op). Fire-and-forget.
  void precacheAll(BuildContext context) {
    for (final img in images.value.values) {
      if (img.url.isEmpty) continue;
      precacheImage(
        CachedNetworkImageProvider(img.url),
        context,
        onError: (_, __) {},
      );
    }
  }
}
