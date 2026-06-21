// lib/services/translation_service.dart
//
// Runtime auto-translation for short, mostly-static strings (e.g. the
// curated azkar benefit lines). Uses Google Translate's free public
// endpoint (the one the official Google Translate web page calls when you
// haven't signed in). No API key needed.
//
// All results are cached in a Hive box keyed by (locale, original-text).
// Once a string is translated for a given locale, it's served from cache
// forever — every successive launch is instant and offline.
//
// Why not pre-translate at build time:
//   • content can grow, so we don't want every new benefit to require a
//     separate SQL migration in 7 locales
//   • the curated English line is the source of truth; translations are
//     derivative and can be re-built any time
//
// Failure mode: if the network call fails, returns the original English
// string. The user still gets a meaningful line, never a blank.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  static const String _boxName = 'auto_translations_v1';

  Box<String>? _box;
  bool _ready = false;
  final Map<String, Future<String>> _inFlight = {};

  /// Open the Hive cache box. Safe to call multiple times.
  Future<void> init() async {
    if (_ready) return;
    try {
      _box = await Hive.openBox<String>(_boxName);
      _ready = true;
    } catch (e) {
      debugPrint('[TranslationService] init failed: $e');
    }
  }

  String _key(String text, String locale) => '$locale|${text.hashCode}';

  /// Synchronous lookup — returns the cached translation if it's already in
  /// the box, otherwise null. Use this on the hot render path; combine with
  /// [translate] to lazily populate on cache miss.
  String? cached(String text, String locale) {
    if (!_ready || text.isEmpty || locale == 'en') return text;
    return _box?.get(_key(text, locale));
  }

  /// Async translate + cache. Falls back to the original text on any error
  /// so the UI never goes blank. Deduplicates in-flight requests for the
  /// same (text, locale) pair so a list of 100 identical strings makes one
  /// network call, not 100.
  Future<String> translate(String text, String locale) async {
    if (text.isEmpty || locale == 'en') return text;
    await init();
    final hit = cached(text, locale);
    if (hit != null) return hit;

    final key = _key(text, locale);
    final pending = _inFlight[key];
    if (pending != null) return pending;

    final future = _doTranslate(text, locale).then((translated) async {
      if (translated.isNotEmpty && translated != text) {
        await _box?.put(key, translated);
      }
      _inFlight.remove(key);
      return translated;
    }).catchError((e) {
      _inFlight.remove(key);
      debugPrint('[TranslationService] $locale fetch failed: $e');
      return text;
    });
    _inFlight[key] = future;
    return future;
  }

  Future<String> _doTranslate(String text, String target) async {
    // Free unofficial endpoint used by translate.google.com itself. No key,
    // no quota, but no SLA either — wrap in try/catch + timeout.
    final uri = Uri.https(
      'translate.googleapis.com',
      '/translate_a/single',
      {
        'client': 'gtx',
        'sl': 'en',
        'tl': target,
        'dt': 't',
        'q': text,
      },
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) {
      throw StateError('HTTP ${res.statusCode}');
    }
    // Response shape:
    //   [[[ "<translated>", "<original>", null, null, 1 ], ...], ...]
    // Concatenate every chunk in the outer first array so multi-sentence
    // input stays intact.
    final decoded = jsonDecode(res.body) as List<dynamic>;
    final segments = decoded.first as List<dynamic>;
    final buf = StringBuffer();
    for (final seg in segments) {
      if (seg is List && seg.isNotEmpty && seg.first is String) {
        buf.write(seg.first as String);
      }
    }
    final out = buf.toString().trim();
    return out.isEmpty ? text : out;
  }
}
