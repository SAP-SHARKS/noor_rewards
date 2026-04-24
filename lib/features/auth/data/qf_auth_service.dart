import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/env/env.dart';

/// Manual PKCE OAuth2 service for Quran Foundation authentication.
///
/// Mirrors the approach used by the friend's working "Islam Focus" app:
///   - url_launcher opens the browser with the auth URL
///   - app_links (wired in main.dart) calls [handleCallback] when the
///     noorrewards://oauth2/callback URI arrives
///   - A Completer bridges the async gap, so [signIn] awaits the callback
///
/// No flutter_appauth activities are involved — no more process-kill crashes.
class QfAuthService {
  static final QfAuthService instance = QfAuthService._();
  QfAuthService._();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final _supabase = Supabase.instance.client;

  static const String _redirectUri = 'noorrewards://oauth2/callback';

  // ── Storage keys ────────────────────────────────────────────────────────────
  static const String _accessTokenKey  = 'qf_access_token';
  static const String _refreshTokenKey = 'qf_refresh_token';
  static const String _codeVerifierKey = 'qf_pkce_code_verifier';
  // QF user-profile keys (populated after userinfo fetch)
  static const String _qfEmailKey      = 'qf_user_email';
  static const String _qfNameKey       = 'qf_user_name';
  static const String _qfPictureKey    = 'qf_user_picture';

  /// Set by main.dart when a noorrewards://oauth2/callback URI arrives.
  Completer<Uri>? _pendingCallback;

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<String?> get accessToken  => _secureStorage.read(key: _accessTokenKey);
  Future<String?> get refreshToken => _secureStorage.read(key: _refreshTokenKey);
  Future<String?> get qfEmail      => _secureStorage.read(key: _qfEmailKey);
  Future<String?> get qfName       => _secureStorage.read(key: _qfNameKey);
  Future<String?> get qfPicture    => _secureStorage.read(key: _qfPictureKey);

  /// Called from main.dart's app_links listener whenever a
  /// `noorrewards://oauth2/callback` URI is received.
  void handleCallback(Uri uri) {
    if (_pendingCallback != null && !_pendingCallback!.isCompleted) {
      _pendingCallback!.complete(uri);
    }
  }

  Future<void> signIn() async {
    // 1. Generate PKCE parameters
    final codeVerifier  = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    // 2. Persist verifier so we can send it to the Edge Function after callback
    await _secureStorage.write(key: _codeVerifierKey, value: codeVerifier);

    // 3. Build the authorization URL
    final authUri = Uri.parse('${Env.qfAuthBase}/oauth2/auth').replace(
      queryParameters: {
        'client_id':             Env.qfClientId,
        'response_type':         'code',
        'redirect_uri':          _redirectUri,
          'scope':                 'openid',
        'code_challenge':        codeChallenge,
        'code_challenge_method': 'S256',
        'state':                 _generateState(),
      },
    );

    // 4. Register the Completer before launching, so we never miss the callback
    _pendingCallback = Completer<Uri>();

    // 5. Open the system browser
    if (!await launchUrl(authUri, mode: LaunchMode.externalApplication)) {
      _pendingCallback = null;
      throw Exception('Could not open browser for Quran Foundation login.');
    }

    // 6. Await the redirect callback (5-minute timeout for user interaction)
    final Uri callbackUri;
    try {
      callbackUri = await _pendingCallback!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw TimeoutException('Login timed out — please try again.'),
      );
    } finally {
      _pendingCallback = null;
    }

    // 7. Check for errors from the provider
    final error = callbackUri.queryParameters['error'];
    if (error != null) {
      throw Exception('QF auth error: $error — ${callbackUri.queryParameters['error_description']}');
    }

    // 8. Extract the authorization code
    final code = callbackUri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw Exception('No authorization code in callback URI.');
    }

    // 9. Exchange the code for tokens via Supabase Edge Function
    final storedVerifier = await _secureStorage.read(key: _codeVerifierKey);
    await _exchangeCode(code, storedVerifier ?? codeVerifier);
  }

  Future<void> refresh() async {
    final currentRefreshToken = await refreshToken;
    if (currentRefreshToken == null) {
      throw Exception('No refresh token available — please sign in again.');
    }

    final response = await _supabase.functions.invoke(
      'qf-token-refresh',
      body: {
        'refresh_token': currentRefreshToken,
        'client_id':     Env.qfClientId,
      },
    );

    if (response.status == 200) {
      final data = response.data;
      if (data?['access_token']  != null) await _secureStorage.write(key: _accessTokenKey,  value: data['access_token']);
      if (data?['refresh_token'] != null) await _secureStorage.write(key: _refreshTokenKey, value: data['refresh_token']);
    } else {
      throw Exception('Token refresh failed: ${response.data}');
    }
  }

  Future<void> signOut() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _codeVerifierKey);
    await _secureStorage.delete(key: _qfEmailKey);
    await _secureStorage.delete(key: _qfNameKey);
    await _secureStorage.delete(key: _qfPictureKey);
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<void> _exchangeCode(String code, String codeVerifier) async {
    final response = await _supabase.functions.invoke(
      'qf-token-exchange',
      body: {
        'code':          code,
        'code_verifier': codeVerifier,
        'redirect_uri':  _redirectUri,
        'client_id':     Env.qfClientId,
      },
    );

    if (response.status == 200) {
      final data = response.data;
      final qfAccessToken  = data?['access_token']  as String?;
      final qfRefreshToken = data?['refresh_token'] as String?;

      // Store QF tokens locally (same as the colleague's app)
      if (qfAccessToken  != null) await _secureStorage.write(key: _accessTokenKey,  value: qfAccessToken);
      if (qfRefreshToken != null) await _secureStorage.write(key: _refreshTokenKey, value: qfRefreshToken);

      // Create an anonymous Supabase session so AuthGate can proceed.
      // QF auth and Supabase auth are independent — we just need any valid session.
      if (_supabase.auth.currentSession == null) {
        await _supabase.auth.signInAnonymously();
      }

      // Fetch QF user profile and persist it to Supabase user metadata + profiles table.
      // Non-fatal: if this fails, auth still succeeds — user just won't see their QF name yet.
      if (qfAccessToken != null) {
        await _fetchAndStoreUserInfo(qfAccessToken);
      }
    } else {
      throw Exception('Token exchange failed (${response.status}): ${response.data}');
    }
  }

  /// Calls the QF userinfo endpoint using [accessToken], stores the returned
  /// profile (email, name, picture) in SecureStorage and Supabase user metadata.
  Future<void> _fetchAndStoreUserInfo(String accessToken) async {
    try {
      final res = await http.get(
        Uri.parse('${Env.qfAuthBase}/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return;

      final info    = jsonDecode(res.body) as Map<String, dynamic>;
      final email   = (info['email']   as String?) ?? '';
      final name    = (info['name']    as String?) ?? '';
      final picture = (info['picture'] as String?) ?? '';
      final sub     = (info['sub']     as String?) ?? '';

      debugPrint('[QF] userinfo → email=$email name=$name sub=$sub');

      // Persist locally so we can read without a round‑trip
      await _secureStorage.write(key: _qfEmailKey,   value: email);
      await _secureStorage.write(key: _qfNameKey,    value: name);
      await _secureStorage.write(key: _qfPictureKey, value: picture);

      // Tag the anonymous Supabase user with QF identity so the profile
      // screen (and any other screen) can detect the provider and display
      // the right information without extra network calls.
      await _supabase.auth.updateUser(UserAttributes(
        data: {
          'provider':   'quran_com',   // used by profile screen for badge
          'qf_email':   email,
          'qf_name':    name,
          'qf_picture': picture,
          'qf_sub':     sub,
          // Shared keys used by Supabase metadata conventions
          'full_name':  name,
          'avatar_url': picture,
        },
      ));

      // Also upsert into `profiles` table so the dashboard shows QF name/avatar
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final upsertData = <String, dynamic>{'id': user.id};
        if (name.isNotEmpty)    upsertData['display_name'] = name;
        if (picture.isNotEmpty) upsertData['avatar_url']   = picture;
        if (upsertData.length > 1) {
          await _supabase.from('profiles').upsert(upsertData);
        }
      }
    } catch (e) {
      // Non-fatal — token exchange already succeeded, session is valid.
      debugPrint('[QF] userinfo fetch failed (non-fatal): $e');
    }
  }

  /// 32-byte random value, base64url-encoded without padding.
  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes  = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// S256: SHA-256 of the verifier, base64url-encoded without padding.
  String _generateCodeChallenge(String codeVerifier) {
    final digest = sha256.convert(utf8.encode(codeVerifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Random opaque state value for CSRF protection.
  String _generateState() {
    final random = Random.secure();
    final bytes  = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
