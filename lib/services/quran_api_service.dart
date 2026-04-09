// lib/services/quran_api_service.dart
//
// Authenticated HTTP client for the Quran Foundation API.
//
// Usage:
//   final service = QuranApiService.instance;
//   final verses  = await service.versesByPage(5);
//   final words   = await service.wordsByKey('2:255');
//   final trans   = await service.surahTranslation(2, 'en.sahih');
//
// Authentication strategy:
//   • Client-credentials OAuth2 flow (client_id + client_secret → Bearer token)
//   • Token is cached in-memory and refreshed 60 s before expiry.
//   • If credentials are not yet set in .env (isDev placeholder values),
//     the service falls back to the un-authenticated public API so the app
//     continues to work during initial setup.

import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'quran_api_config.dart';

class QuranApiService {
  QuranApiService._();
  static final QuranApiService instance = QuranApiService._();

  // ── Cache ───────────────────────────────────────────────────────────────────
  Future<Box> get _cacheBox async {
    const boxName = 'quran_api_cache';
    if (!Hive.isBoxOpen(boxName)) return await Hive.openBox(boxName);
    return Hive.box(boxName);
  }

  // ── Token cache ─────────────────────────────────────────────────────────────
  String? _accessToken;
  DateTime? _tokenExpiry;

  // ── Auth header ─────────────────────────────────────────────────────────────
  Future<Map<String, String>> _headers() async {
    final token = await _bearerToken();
    return {
      'Accept':        'application/json',
      'Content-Type':  'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Returns a valid Bearer token, refreshing if needed.
  /// Returns null when credentials are placeholder values (dev mode, not yet
  /// configured) so the app degrades gracefully to the public API.
  Future<String?> _bearerToken() async {
    // If token is fresh, reuse it
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(seconds: 60)))) {
      return _accessToken;
    }

    // Detect placeholder / unconfigured credentials — skip auth fetch
    String clientId, clientSecret;
    try {
      clientId     = QuranApiConfig.clientId;
      clientSecret = QuranApiConfig.clientSecret;
    } catch (_) {
      // .env not yet filled in — run without auth
      return null;
    }

    // Fetch new token via OAuth2 client-credentials + HTTP Basic Auth.
    // Quran Foundation requires credentials in the Authorization header
    // (base64-encoded client_id:client_secret), NOT in the request body.
    try {
      final credentials =
          base64Encode('$clientId:$clientSecret'.codeUnits);
      final res = await http
          .post(
            Uri.parse(QuranApiConfig.tokenEndpoint),
            headers: {
              'Content-Type':  'application/x-www-form-urlencoded',
              'Authorization': 'Basic $credentials',
            },
            body: 'grant_type=client_credentials',
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final js       = jsonDecode(res.body);
        _accessToken   = js['access_token'] as String?;
        final expiresIn = (js['expires_in'] as num?)?.toInt() ?? 3600;
        _tokenExpiry   = DateTime.now().add(Duration(seconds: expiresIn));
        return _accessToken;
      }
    } catch (_) {
      // Token fetch failed — degrade gracefully to unauthenticated public API
    }
    return null;
  }

  // ── Invalidate token (call if you get a 401) ─────────────────────────────
  void invalidateToken() {
    _accessToken = null;
    _tokenExpiry = null;
  }

  // ── API methods ─────────────────────────────────────────────────────────────

  /// All verses on a Quran page (1–604).
  /// Returns [{surah, ayah, arabic}]
  Future<List<Map<String, dynamic>>> versesByPage(int page) async {
    final box = await _cacheBox;
    final cacheKey = 'versesByPage_$page';
    if (box.containsKey(cacheKey)) {
      return (jsonDecode(box.get(cacheKey)) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    final url = Uri.parse(
      '${QuranApiConfig.apiBase}/verses/by_page/$page'
      '?words=false&fields=text_uthmani,text_indopak,verse_key,page_number&per_page=50',
    );
    final res = await http
        .get(url, headers: await _headers())
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 401) { invalidateToken(); return []; }
    if (res.statusCode != 200) return [];
    final verses = (jsonDecode(res.body)['verses'] as List? ?? []);
    final mapped = verses.map<Map<String, dynamic>>((v) {
      final key = (v['verse_key'] as String).split(':');
      return {
        'surah':  int.tryParse(key[0]) ?? 1,
        'ayah':   int.tryParse(key[1]) ?? 1,
        'arabic': v['text_uthmani'] ?? '',
        'arabic_indopak': v['text_indopak'] ?? v['text_uthmani'] ?? '',
      };
    }).toList();
    
    box.put(cacheKey, jsonEncode(mapped));
    return mapped;
  }

  /// Word-by-word data for a single verse key (e.g. "2:255").
  /// Returns [{arabic, transliteration, translation}]
  Future<List<Map<String, dynamic>>> wordsByKey(String verseKey) async {
    final box = await _cacheBox;
    final cacheKey = 'wordsByKey_$verseKey';
    if (box.containsKey(cacheKey)) {
      return (jsonDecode(box.get(cacheKey)) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    final url = Uri.parse(
      '${QuranApiConfig.apiBase}/verses/by_key/$verseKey'
      '?words=true'
      '&word_fields=text_uthmani,text_indopak,transliteration'
      '&word_translation_language=en',
    );
    final res = await http
        .get(url, headers: await _headers())
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 401) { invalidateToken(); return []; }
    if (res.statusCode != 200) return [];
    final rawWords = (jsonDecode(res.body)['verse']?['words'] as List? ?? []);
    final mapped = rawWords
        .where((w) => w['char_type_name'] != 'end')
        .map<Map<String, dynamic>>((w) => {
              'arabic':          w['text_uthmani'] ?? w['text'] ?? '',
              'arabic_indopak':  w['text_indopak'] ?? w['text_uthmani'] ?? '',
              'transliteration': w['transliteration']?['text'] ?? '',
              'translation':     w['translation']?['text'] ?? '',
            })
        .toList();
        
    box.put(cacheKey, jsonEncode(mapped));
    return mapped;
  }

  /// Bulk word-by-word for an entire surah. Returns Map<ayahNumber, List<word>>.
  Future<Map<int, List<Map<String, dynamic>>>> wordsBySurah(int surah) async {
    final box = await _cacheBox;
    final cacheKey = 'wordsBySurah_$surah';
    if (box.containsKey(cacheKey)) {
      final cached = jsonDecode(box.get(cacheKey)) as Map<String, dynamic>;
      return cached.map((k, v) => MapEntry(
        int.parse(k),
        (v as List).map((e) => Map<String, dynamic>.from(e)).toList(),
      ));
    }

    final result = <int, List<Map<String, dynamic>>>{};
    // Quran.com API supports per_page up to 50 verses; paginate for long surahs
    int page = 1;
    while (true) {
      final url = Uri.parse(
        '${QuranApiConfig.apiBase}/verses/by_chapter/$surah'
        '?words=true'
        '&word_fields=text_uthmani,text_indopak,transliteration'
        '&word_translation_language=en'
        '&per_page=50'
        '&page=$page',
      );
      final res = await http
          .get(url, headers: await _headers())
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 401) { invalidateToken(); break; }
      if (res.statusCode != 200) break;
      final body = jsonDecode(res.body);
      final verses = body['verses'] as List? ?? [];
      if (verses.isEmpty) break;
      for (final v in verses) {
        final ayahNum = v['verse_number'] as int? ?? 0;
        final rawWords = (v['words'] as List? ?? []);
        result[ayahNum] = rawWords
            .where((w) => w['char_type_name'] != 'end')
            .map<Map<String, dynamic>>((w) => {
                  'arabic':          w['text_uthmani'] ?? w['text'] ?? '',
                  'arabic_indopak':  w['text_indopak'] ?? w['text_uthmani'] ?? '',
                  'transliteration': w['transliteration']?['text'] ?? '',
                  'translation':     w['translation']?['text'] ?? '',
                })
            .toList();
      }
      final totalPages = body['pagination']?['total_pages'] as int? ?? 1;
      if (page >= totalPages) break;
      page++;
    }
    
    box.put(cacheKey, jsonEncode(result.map((k, v) => MapEntry(k.toString(), v))));
    return result;
  }

  /// Full surah text in the given script slug (e.g. 'uthmani', 'indopak', 'imlaei').
  Future<Map<int, String>> surahScript({
    required int surah,
    required String scriptSlug,
  }) async {
    final box = await _cacheBox;
    final cacheKey = 'surahScript_${surah}_$scriptSlug';
    if (box.containsKey(cacheKey)) {
      final cached = jsonDecode(box.get(cacheKey)) as Map<String, dynamic>;
      return cached.map((k, v) => MapEntry(int.parse(k), v as String));
    }

    final url = Uri.parse(
      '${QuranApiConfig.apiBase}/quran/verses/$scriptSlug'
      '?chapter_number=$surah'
    );
    try {
      final res = await http.get(url, headers: await _headers()).timeout(const Duration(seconds: 15));
      if (res.statusCode == 401) invalidateToken();
      if (res.statusCode == 200) {
        final verses = jsonDecode(res.body)['verses'] as List? ?? [];
        final map = <int, String>{};
        for (final v in verses) {
          final vk = (v['verse_key'] as String).split(':');
          final ayah = int.tryParse(vk.length > 1 ? vk[1] : '0') ?? 0;
          map[ayah] = v['text_$scriptSlug'] as String? ?? '';
        }
        if (map.isNotEmpty) {
          box.put(cacheKey, jsonEncode(map.map((k, v) => MapEntry(k.toString(), v))));
          return map;
        }
      }
    } catch (_) {}
    return {};
  }

  /// Full surah translation in the given edition identifier.
  ///
  /// The Quran.com v4 API supports these edition identifiers for translations:
  ///   en.sahih, en.yusufali, ur.jalandhry, ur.maududi, fr.hamidullah, etc.
  /// Resolves an (ayahNumber → translationText) map for the whole surah.
  ///
  /// Falls back to the alquran.cloud API only when no authenticated response
  /// is available AND the edition is not in Supabase.
  Future<Map<int, String>> surahTranslation({
    required int surah,
    required String edition,       // e.g. 'en.sahih', 'ur.jalandhry'
    required int surahLength,
    required int startVerseId,
  }) async {
    final box = await _cacheBox;
    final cacheKey = 'surahTranslation_${surah}_$edition';
    if (box.containsKey(cacheKey)) {
      final cached = jsonDecode(box.get(cacheKey)) as Map<String, dynamic>;
      return cached.map((k, v) => MapEntry(int.parse(k), v as String));
    }

    // Try Quran.com v4 translations endpoint
    try {
      final translationId = _quranComTranslationId(edition);
      if (translationId != null) {
        final url = Uri.parse(
          '${QuranApiConfig.apiBase}/quran/translations/$translationId'
          '?chapter_number=$surah',
        );
        final res = await http
            .get(url, headers: await _headers())
            .timeout(const Duration(seconds: 15));
        if (res.statusCode == 401) invalidateToken();
        if (res.statusCode == 200) {
          final items = jsonDecode(res.body)['translations'] as List? ?? [];
          final map = <int, String>{};
          for (final item in items) {
            final vk = (item['verse_key'] as String).split(':');
            final an = int.tryParse(vk.length > 1 ? vk[1] : '0') ?? 0;
            map[startVerseId + an - 1] = _stripHtml(item['text'] as String? ?? '');
          }
          if (map.isNotEmpty) {
            box.put(cacheKey, jsonEncode(map.map((k, v) => MapEntry(k.toString(), v))));
            return map;
          }
        }
      }
    } catch (_) {}

    // Fallback → alquran.cloud (kept only for editions not on quran.com)
    try {
      final apiUrl =
          'https://api.alquran.cloud/v1/surah/$surah/$edition';
      final res = await http
          .get(Uri.parse(apiUrl), headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final ayahs = jsonDecode(res.body)['data']?['ayahs'] as List? ?? [];
        final map = <int, String>{};
        for (final a in ayahs) {
          final num = a['numberInSurah'] as int? ?? 0;
          map[startVerseId + num - 1] = a['text'] as String? ?? '';
        }
        if (map.isNotEmpty) {
          box.put(cacheKey, jsonEncode(map.map((k, v) => MapEntry(k.toString(), v))));
          return map;
        }
      }
    } catch (_) {}

    return {};
  }

  /// Resolves an alquran.cloud edition slug to the quran.com v4 translation ID.
  /// Returns null if no mapping is known (→ fall back to alquran.cloud).
  static int? _quranComTranslationId(String edition) {
    // Mapping: alquran.cloud slug → quran.com integer translation resource ID
    // Full list: https://api.quran.com/api/v4/resources/translations
    const map = {
      'en.sahih':       131,  // Saheeh International
      'en.yusufali':    37,   // Yusuf Ali
      'en.pickthall':   38,   // Pickthall
      'en.shakir':      21,   // Shakir
      'en.transliteration': 57,
      'ur.jalandhry':   54,   // Jalandhry (Urdu)
      'ur.maududi':     97,   // Maududi (Urdu)
      'ur.ahmedali':    158,  // Ahmed Ali (Urdu)
      'fr.hamidullah':  31,   // Hamidullah (French)
      'fr.montada':     136,  // Montada (French)
      'de.aburida':     27,   // Abu Rida (German)
      'tr.diyanet':     77,   // Diyanet (Turkish)
      'tr.golpinarli':  82,   // Golpinarli (Turkish)
      'es.asad':        83,   // Muhammad Asad (Spanish)
      'id.indonesian':  33,   // Indonesian Ministry
      'ms.basmeih':     39,   // Basmeih (Malay)
      'bn.bengali':     161,  // Muhiuddin Khan (Bengali)
      'ru.kuliev':      79,   // Kuliev (Russian)
      'zh.jian':        109,  // Ma Jian (Chinese)
    };
    return map[edition];
  }

  /// Strips simple HTML tags from translation text (quran.com wraps some text).
  static String _stripHtml(String s) =>
      s.replaceAll(RegExp(r'<[^>]+>'), '').trim();
}
