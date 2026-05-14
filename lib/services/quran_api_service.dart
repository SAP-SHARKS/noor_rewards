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
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/env/env.dart';
import '../features/auth/data/qf_auth_service.dart';
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
      'Accept': 'application/json',
      'Content-Type': 'application/json',
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
        DateTime.now().isBefore(
          _tokenExpiry!.subtract(const Duration(seconds: 60)),
        )) {
      return _accessToken;
    }

    // Detect placeholder / unconfigured credentials — skip auth fetch
    String clientId, clientSecret;
    try {
      clientId = QuranApiConfig.clientId;
      clientSecret = QuranApiConfig.clientSecret;
    } catch (_) {
      // .env not yet filled in — run without auth
      return null;
    }

    // Fetch new token via OAuth2 client-credentials + HTTP Basic Auth.
    // Quran Foundation requires credentials in the Authorization header
    // (base64-encoded client_id:client_secret), NOT in the request body.
    try {
      final credentials = base64Encode('$clientId:$clientSecret'.codeUnits);
      final res = await http
          .post(
            Uri.parse(QuranApiConfig.tokenEndpoint),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Authorization': 'Basic $credentials',
            },
            body: 'grant_type=client_credentials',
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final js = jsonDecode(res.body);
        _accessToken = js['access_token'] as String?;
        final expiresIn = (js['expires_in'] as num?)?.toInt() ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
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

  // ── User Authentication (Bookmarks / Profile) ─────────────────────────────
  // Switches between prelive + production depending on Env.isDev so tokens
  // minted by `<env>-oauth2.quran.foundation` reach the matching API host.
  String get _kUserApiBase => Env.qfUserApiBase;
  // Use config clientId or default if missing
  String get _kClientId => QuranApiConfig.clientId;

  Future<String?> _getUserAccessToken() async {
    return await QfAuthService.instance.accessToken;
  }

  Future<Map<String, String>?> _userAuthHeaders() async {
    final token = await _getUserAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('QF_API: No user access token found!');
      return null;
    }
    return {
      'Authorization': 'Bearer $token',
      'x-auth-token': token,
      'x-client-id': _kClientId,
      'Content-Type': 'application/json',
    };
  }

  Future<bool> isUserLoggedIn() async {
    final token = await _getUserAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Wraps a QF user-API call with a one-time refresh-and-retry on an
  /// auth failure. QF returns expired-token errors as either HTTP 401 OR
  /// HTTP 403 with `type: "invalid_token"` in the body — without this
  /// helper we treated 403 as a permanent failure and never refreshed.
  /// On a real auth failure we call `qf-token-refresh` to mint a fresh
  /// access token using the stored refresh token and replay the request
  /// once.
  Future<http.Response?> _qfRequest(
    Future<http.Response> Function(Map<String, String> headers) makeRequest,
  ) async {
    final headers = await _userAuthHeaders();
    if (headers == null) return null;
    http.Response response;
    try {
      response = await makeRequest(headers);
    } catch (e) {
      debugPrint('QF_API: request threw: $e');
      return null;
    }
    if (!_isAuthFailure(response)) return response;

    debugPrint(
        'QF_API: auth failure (HTTP ${response.statusCode}) — '
        'attempting token refresh + retry. body=${response.body}');
    try {
      await QfAuthService.instance.refresh();
    } catch (e) {
      debugPrint('QF_API: token refresh failed — user must sign in again: $e');
      return response;
    }
    final retryHeaders = await _userAuthHeaders();
    if (retryHeaders == null) return response;
    try {
      return await makeRequest(retryHeaders);
    } catch (e) {
      debugPrint('QF_API: retry threw: $e');
      return response;
    }
  }

  // Returns true when the response indicates the access token is no longer
  // valid (expired, revoked, malformed) and a refresh should be attempted.
  // QF uses both 401 and 403 for these cases, so we look at both the status
  // code and an optional `invalid_token` / "expired" hint in the body.
  static bool _isAuthFailure(http.Response response) {
    if (response.statusCode == 401) return true;
    if (response.statusCode == 403) {
      final body = response.body.toLowerCase();
      if (body.contains('invalid_token') ||
          body.contains('expired') ||
          body.contains('inactive')) {
        return true;
      }
    }
    return false;
  }

  // ── User Profile ──
  Future<Map<String, dynamic>?> getUserProfile() async {
    final headers = await _userAuthHeaders();
    if (headers == null) return null;
    try {
      final response = await http
          .get(
            Uri.parse('$_kUserApiBase/auth/v1/users/profile'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('QF_API: Profile error: $e');
    }
    return null;
  }

  // ── Get Bookmarks ──
  //
  // QF requires a `mushafId` query param; we use the same Uthmani Mushaf
  // (mushafId=1) the POST body sends — keeps GET and POST consistent.
  // Responses can arrive in several shapes:
  //   • a bare List of bookmark objects
  //   • `{ bookmarks: [...] }`
  //   • `{ data: [...] }`  (newer QF wrapper format)
  //   • `{ data: { items: [...] } }`
  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final response = await _qfRequest((headers) => http
        .get(
          Uri.parse('$_kUserApiBase/auth/v1/bookmarks?mushafId=1&first=20'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 10)));
    if (response == null) return [];
    if (response.statusCode != 200) {
      debugPrint(
          'QF_API: GetBookmarks ${response.statusCode}: ${response.body}');
      return [];
    }
    try {
      final data = jsonDecode(response.body);
      List? rows;
      if (data is List) {
        rows = data;
      } else if (data is Map) {
        if (data['bookmarks'] is List) {
          rows = data['bookmarks'] as List;
        } else if (data['data'] is List) {
          rows = data['data'] as List;
        } else if (data['data'] is Map && (data['data'] as Map)['items'] is List) {
          rows = (data['data'] as Map)['items'] as List;
        }
      }
      if (rows != null) return rows.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('QF_API: GetBookmarks parse error: $e');
    }
    return [];
  }

  // ── Add Bookmark ──
  Future<bool> addBookmark({
    required int surahNumber,
    required int ayatNumber,
  }) async {
    final response = await _qfRequest((headers) => http
        .post(
          Uri.parse('$_kUserApiBase/auth/v1/bookmarks'),
          headers: headers,
          body: jsonEncode({
            'key': surahNumber,
            'type': 'ayah',
            'verseNumber': ayatNumber,
            'mushaf': 1,
          }),
        )
        .timeout(const Duration(seconds: 10)));
    if (response == null) return false;
    final ok = response.statusCode == 200 || response.statusCode == 201;
    if (!ok) {
      debugPrint(
          'QF_API: AddBookmark ${response.statusCode}: ${response.body}');
    }
    return ok;
  }

  // ── Remove Bookmark ──
  //
  // QF requires the bookmark's UUID `id` in the DELETE URL — not the
  // verse_key composite (`<surah>:<ayah>`), which returns 404 NotFound.
  // We fetch the list, find the matching entry, then delete by its id.
  Future<bool> removeBookmark({
    required int surahNumber,
    required int ayatNumber,
  }) async {
    // Look up the bookmark's QF id by verse coordinates.
    String? bookmarkId;
    try {
      final list = await getBookmarks();
      for (final b in list) {
        final s = (b['chapterNumber'] ?? b['key']) as int?;
        final a = b['verseNumber'] as int?;
        if (s == surahNumber && a == ayatNumber) {
          bookmarkId = b['id'] as String?;
          break;
        }
      }
    } catch (e) {
      debugPrint('QF_API: RemoveBookmark id lookup failed: $e');
    }
    if (bookmarkId == null || bookmarkId.isEmpty) {
      // Nothing to delete on QF — already gone (or never synced). Treat as
      // success so the local state can move on without rolling back.
      debugPrint(
          'QF_API: RemoveBookmark — no QF row for $surahNumber:$ayatNumber, skipping');
      return true;
    }

    final response = await _qfRequest((headers) => http
        .delete(
          Uri.parse('$_kUserApiBase/auth/v1/bookmarks/$bookmarkId'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 10)));
    if (response == null) return false;
    final ok = response.statusCode == 200 || response.statusCode == 204;
    if (!ok) {
      debugPrint(
          'QF_API: RemoveBookmark ${response.statusCode}: ${response.body}');
    }
    return ok;
  }

  // ── Log Reading Session ──
  Future<bool> logReadingSession({
    required int surahNumber,
    required int ayatNumber,
    required int durationSeconds,
  }) async {
    final response = await _qfRequest((headers) => http
        .post(
          Uri.parse('$_kUserApiBase/auth/v1/reading_sessions'),
          headers: headers,
          body: jsonEncode({
            'chapterNumber': surahNumber,
            'verseNumber': ayatNumber,
            'duration': durationSeconds,
          }),
        )
        .timeout(const Duration(seconds: 10)));
    if (response == null) return false;
    final ok = response.statusCode == 200 || response.statusCode == 201;
    if (!ok) {
      debugPrint(
          'QF_API: ReadingSession ${response.statusCode}: ${response.body}');
    }
    return ok;
  }

  // ── Sync Bookmarks (two-way) ──
  //
  // Reconciles the user's Supabase `quran_bookmarks` table with their
  // Quran.com (QF) bookmarks. Bookmarks only on QF are inserted into
  // Supabase; bookmarks only in Supabase are pushed up to QF. After this
  // returns, both stores hold the union.
  //
  // Safe to call from anywhere — e.g. right after the user completes QF
  // sign-in. Skips silently if either side is not authenticated.
  Future<SyncResult> syncBookmarks() async {
    if (!await isUserLoggedIn()) {
      return SyncResult(success: false, message: 'Not connected to Quran.com');
    }
    final sb = Supabase.instance.client;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) {
      return SyncResult(success: false, message: 'Not signed in to Noor');
    }

    int uploaded = 0;
    int downloaded = 0;
    int failed = 0;

    try {
      // Pull from both sources in parallel.
      final results = await Future.wait<dynamic>([
        getBookmarks(),
        sb.from('quran_bookmarks').select('surah, ayah').eq('user_id', uid),
      ]);
      final qfList = results[0] as List<Map<String, dynamic>>;
      final sbList = (results[1] as List).cast<Map<String, dynamic>>();

      final Set<String> qfSet = {};
      for (final b in qfList) {
        final s = b['chapterNumber'] ?? b['key'];
        final a = b['verseNumber'];
        if (s != null && a != null) qfSet.add('$s:$a');
      }
      final Set<String> sbSet = {};
      for (final r in sbList) {
        sbSet.add('${r['surah']}:${r['ayah']}');
      }

      // QF → Supabase (download): persist quran.com bookmarks locally.
      for (final key in qfSet.difference(sbSet)) {
        final parts = key.split(':');
        if (parts.length != 2) continue;
        final s = int.tryParse(parts[0]);
        final a = int.tryParse(parts[1]);
        if (s == null || a == null) continue;
        try {
          await sb.from('quran_bookmarks').upsert({
            'user_id': uid,
            'surah': s,
            'ayah': a,
          }, onConflict: 'user_id,surah,ayah');
          downloaded++;
        } catch (_) {
          failed++;
        }
      }

      // Supabase → QF (upload): push app bookmarks to quran.com.
      for (final key in sbSet.difference(qfSet)) {
        final parts = key.split(':');
        if (parts.length != 2) continue;
        final s = int.tryParse(parts[0]);
        final a = int.tryParse(parts[1]);
        if (s == null || a == null) continue;
        final ok = await addBookmark(surahNumber: s, ayatNumber: a);
        if (ok) {
          uploaded++;
        } else {
          failed++;
        }
      }

      final total = uploaded + downloaded;
      String message;
      if (failed > 0 && total == 0) {
        message =
            'Sync failed — $failed bookmark(s) could not be pushed to Quran.com (check token / endpoint).';
      } else if (total == 0 && failed == 0) {
        message = 'Bookmarks already in sync';
      } else {
        message = 'Synced $total bookmarks ($uploaded up, $downloaded down)';
        if (failed > 0) message += ', $failed failed';
      }
      return SyncResult(
        success: failed == 0,
        uploaded: uploaded,
        failed: failed,
        message: message,
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Sync failed: $e');
    }
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
    if (res.statusCode == 401) {
      invalidateToken();
      return [];
    }
    if (res.statusCode != 200) return [];
    final verses = (jsonDecode(res.body)['verses'] as List? ?? []);
    final mapped =
        verses.map<Map<String, dynamic>>((v) {
          final key = (v['verse_key'] as String).split(':');
          return {
            'surah': int.tryParse(key[0]) ?? 1,
            'ayah': int.tryParse(key[1]) ?? 1,
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
    if (res.statusCode == 401) {
      invalidateToken();
      return [];
    }
    if (res.statusCode != 200) return [];
    final rawWords = (jsonDecode(res.body)['verse']?['words'] as List? ?? []);
    final mapped =
        rawWords
            .where((w) => w['char_type_name'] != 'end')
            .map<Map<String, dynamic>>(
              (w) => {
                'arabic': w['text_uthmani'] ?? w['text'] ?? '',
                'arabic_indopak': w['text_indopak'] ?? w['text_uthmani'] ?? '',
                'transliteration': w['transliteration']?['text'] ?? '',
                'translation': w['translation']?['text'] ?? '',
              },
            )
            .toList();

    box.put(cacheKey, jsonEncode(mapped));
    return mapped;
  }

  /// Bulk word-by-word for an entire surah. Returns `Map<ayahNumber, List<word>>`.
  Future<Map<int, List<Map<String, dynamic>>>> wordsBySurah(int surah) async {
    final box = await _cacheBox;
    final cacheKey = 'wordsBySurah_$surah';
    if (box.containsKey(cacheKey)) {
      final cached = jsonDecode(box.get(cacheKey)) as Map<String, dynamic>;
      return cached.map(
        (k, v) => MapEntry(
          int.parse(k),
          (v as List).map((e) => Map<String, dynamic>.from(e)).toList(),
        ),
      );
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
      if (res.statusCode == 401) {
        invalidateToken();
        break;
      }
      if (res.statusCode != 200) break;
      final body = jsonDecode(res.body);
      final verses = body['verses'] as List? ?? [];
      if (verses.isEmpty) break;
      for (final v in verses) {
        final ayahNum = v['verse_number'] as int? ?? 0;
        final rawWords = (v['words'] as List? ?? []);
        result[ayahNum] =
            rawWords
                .where((w) => w['char_type_name'] != 'end')
                .map<Map<String, dynamic>>(
                  (w) => {
                    'arabic': w['text_uthmani'] ?? w['text'] ?? '',
                    'arabic_indopak':
                        w['text_indopak'] ?? w['text_uthmani'] ?? '',
                    'transliteration': w['transliteration']?['text'] ?? '',
                    'translation': w['translation']?['text'] ?? '',
                  },
                )
                .toList();
      }
      final totalPages = body['pagination']?['total_pages'] as int? ?? 1;
      if (page >= totalPages) break;
      page++;
    }

    box.put(
      cacheKey,
      jsonEncode(result.map((k, v) => MapEntry(k.toString(), v))),
    );
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
      '?chapter_number=$surah',
    );
    try {
      final res = await http
          .get(url, headers: await _headers())
          .timeout(const Duration(seconds: 15));
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
          box.put(
            cacheKey,
            jsonEncode(map.map((k, v) => MapEntry(k.toString(), v))),
          );
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
    required String edition, // e.g. 'en.sahih', 'ur.jalandhry'
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
            map[startVerseId + an - 1] = _stripHtml(
              item['text'] as String? ?? '',
            );
          }
          if (map.isNotEmpty) {
            box.put(
              cacheKey,
              jsonEncode(map.map((k, v) => MapEntry(k.toString(), v))),
            );
            return map;
          }
        }
      }
    } catch (_) {}

    // Fallback → alquran.cloud (kept only for editions not on quran.com)
    try {
      final apiUrl = 'https://api.alquran.cloud/v1/surah/$surah/$edition';
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
          box.put(
            cacheKey,
            jsonEncode(map.map((k, v) => MapEntry(k.toString(), v))),
          );
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
      'en.sahih': 131, // Saheeh International
      'en.yusufali': 37, // Yusuf Ali
      'en.pickthall': 38, // Pickthall
      'en.shakir': 21, // Shakir
      'en.transliteration': 57,
      'ur.jalandhry': 54, // Jalandhry (Urdu)
      'ur.maududi': 97, // Maududi (Urdu)
      'ur.ahmedali': 158, // Ahmed Ali (Urdu)
      'fr.hamidullah': 31, // Hamidullah (French)
      'fr.montada': 136, // Montada (French)
      'de.aburida': 27, // Abu Rida (German)
      'tr.diyanet': 77, // Diyanet (Turkish)
      'tr.golpinarli': 82, // Golpinarli (Turkish)
      'es.asad': 83, // Muhammad Asad (Spanish)
      'id.indonesian': 33, // Indonesian Ministry
      'ms.basmeih': 39, // Basmeih (Malay)
      'bn.bengali': 161, // Muhiuddin Khan (Bengali)
      'ru.kuliev': 79, // Kuliev (Russian)
      'zh.jian': 109, // Ma Jian (Chinese)
    };
    return map[edition];
  }

  /// Strips simple HTML tags from translation text (quran.com wraps some text).
  static String _stripHtml(String s) =>
      s.replaceAll(RegExp(r'<[^>]+>'), '').trim();
}

class SyncResult {
  final bool success;
  final String message;
  final int uploaded;
  final int failed;

  SyncResult({
    required this.success,
    required this.message,
    this.uploaded = 0,
    this.failed = 0,
  });
}
