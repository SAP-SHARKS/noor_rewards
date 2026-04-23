import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  static const String _accessTokenKey  = 'qf_access_token';
  static const String _refreshTokenKey = 'qf_refresh_token';
  static const String _codeVerifierKey = 'qf_pkce_code_verifier';

  /// Set by main.dart when a noorrewards://oauth2/callback URI arrives.
  Completer<Uri>? _pendingCallback;

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<String?> get accessToken  => _secureStorage.read(key: _accessTokenKey);
  Future<String?> get refreshToken => _secureStorage.read(key: _refreshTokenKey);

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
      // Store QF tokens
      if (data?['access_token']  != null) await _secureStorage.write(key: _accessTokenKey,  value: data['access_token']);
      if (data?['refresh_token'] != null) await _secureStorage.write(key: _refreshTokenKey, value: data['refresh_token']);

      // Create a Supabase session using the OTP token the Edge Function generated.
      // This links the QF user to a Supabase account so AuthGate can proceed.
      final supabaseEmail = data?['supabase_email'] as String?;
      final supabaseToken = data?['supabase_token'] as String?;
      if (supabaseEmail != null && supabaseToken != null) {
        await _supabase.auth.verifyOTP(
          email: supabaseEmail,
          token: supabaseToken,
          type: OtpType.magiclink,
        );
      }
    } else {
      throw Exception('Token exchange failed (${response.status}): ${response.data}');
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
