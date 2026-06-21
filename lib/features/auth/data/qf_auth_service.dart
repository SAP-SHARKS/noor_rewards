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

/// Thrown when the email returned by Quran Foundation userinfo already belongs
/// to an existing (non-anonymous) Sabiq Rewards account. The user should be
/// directed to sign in with their original method instead.
class QfEmailConflictException implements Exception {
  final String email;
  const QfEmailConflictException(this.email);
  @override
  String toString() =>
      'QfEmailConflictException: $email already has an account';
}

/// Manual PKCE OAuth2 service for Quran Foundation authentication.
class QfAuthService {
  static final QfAuthService instance = QfAuthService._();
  QfAuthService._();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final _supabase = Supabase.instance.client;

  static const String _redirectUri = 'noorrewards://oauth2/callback';

  // ── Session tokens (cleared on sign-out) ────────────────────────────────────
  static const String _accessTokenKey = 'qf_access_token';
  static const String _refreshTokenKey = 'qf_refresh_token';
  static const String _codeVerifierKey = 'qf_pkce_code_verifier';

  // ── Identity cache (kept across sign-outs so we can skip profile-setup) ─────
  static const String _qfSubKey = 'qf_user_sub';
  static const String _qfEmailKey = 'qf_user_email';
  static const String _qfNameKey = 'qf_user_name';
  static const String _qfPictureKey = 'qf_user_picture';

  // ── Persisted "QF user signed out" flag ─────────────────────────────────────
  // When a QF user taps Sign Out we keep the Supabase session alive
  // (to prevent a new anonymous user being created on next login) but set
  // this flag so the AuthGate can still show the login screen.
  static const String _qfSignedOutKey = 'qf_user_signed_out';

  // ── Observable state for AuthGate ───────────────────────────────────────────
  /// True while the QF token exchange + userinfo fetch is in progress.
  /// AuthGate watches this to show a loading screen instead of flashing
  /// ProfileSetupScreen between signInAnonymously() and updateUser().
  final loginInProgress = ValueNotifier<bool>(false);

  /// Captures the most recent QF sign-in failure so the diagnostic UI
  /// can surface it even when the original ScaffoldMessenger/AlertDialog
  /// path was suppressed by mid-flow widget rebuilds. Cleared at the
  /// start of each new sign-in attempt.
  ///
  /// Exposed as a ValueNotifier so screens (the login page in particular)
  /// can rebuild and show the captured message inline the moment the
  /// bounce-back happens — no need to navigate elsewhere to see it.
  final ValueNotifier<String?> lastSignInErrorN = ValueNotifier<String?>(null);
  String? get lastSignInError => lastSignInErrorN.value;
  set lastSignInError(String? v) => lastSignInErrorN.value = v;

  /// True when the QF user has explicitly signed out.
  /// AuthGate watches this to show the login screen even though the
  /// underlying Supabase session is still alive.
  final isQfSignedOut = ValueNotifier<bool>(false);

  Completer<Uri>? _pendingCallback;

  // ── Initialisation ──────────────────────────────────────────────────────────
  /// Call once from main() / AuthGate.initState() to restore persisted flags.
  Future<void> init() async {
    final v = await _secureStorage.read(key: _qfSignedOutKey);
    isQfSignedOut.value = v == 'true';
  }

  // ── Public getters ──────────────────────────────────────────────────────────
  Future<String?> get accessToken => _secureStorage.read(key: _accessTokenKey);
  Future<String?> get refreshToken =>
      _secureStorage.read(key: _refreshTokenKey);
  Future<String?> get qfEmail => _secureStorage.read(key: _qfEmailKey);
  Future<String?> get qfName => _secureStorage.read(key: _qfNameKey);
  Future<String?> get qfPicture => _secureStorage.read(key: _qfPictureKey);

  /// Called from main.dart's app_links listener.
  void handleCallback(Uri uri) {
    if (_pendingCallback != null && !_pendingCallback!.isCompleted) {
      _pendingCallback!.complete(uri);
    }
  }

  /// Called by AuthGate after a QF user completes ProfileSetupScreen for the
  /// first time — caches the chosen name so future logins can skip setup.
  Future<void> storeQfName(String name) async {
    if (name.isEmpty) return;
    await _secureStorage.write(key: _qfNameKey, value: name);
    debugPrint('[QF] storeQfName: "$name" cached for future logins');
  }

  // ── Smart cross-provider sign-out ───────────────────────────────────────────
  /// Use this instead of calling supabase.auth.signOut() directly.
  ///
  /// • Google / email users  → full Supabase sign-out (normal flow).
  /// • QF users              → only clears QF tokens; the Supabase anonymous
  ///   session is kept alive so the NEXT QF login reuses the same user row
  ///   (no more duplicate entries in the database).
  static Future<void> performSignOut(SupabaseClient supabase) async {
    final user = supabase.auth.currentUser;
    // Primary check: metadata provider (fast, no I/O)
    final metaProvider = user?.userMetadata?['provider'] as String?;

    // Fallback: metadata might not be set if _fetchAndStoreUserInfo's updateUser
    // call silently failed.  Anonymous users with a stored QF sub are QF users.
    final isAnonymous = user?.isAnonymous ?? false;
    String? storedSub;
    if (metaProvider != 'quran_com' && isAnonymous) {
      storedSub = await instance._secureStorage.read(key: _qfSubKey);
    }
    final isQf =
        metaProvider == 'quran_com' ||
        (isAnonymous && storedSub != null && storedSub.isNotEmpty);

    if (isQf) {
      await instance.signOut(); // QF-aware: keeps Supabase session alive
    } else {
      await supabase.auth.signOut(); // Regular full sign-out
    }
  }

  // ── Sign In ─────────────────────────────────────────────────────────────────
  Future<void> signIn() async {
    // Reset the captured-error slot so a fresh attempt is observable.
    lastSignInError = null;
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    await _secureStorage.write(key: _codeVerifierKey, value: codeVerifier);

    final authUri = Uri.parse('${Env.qfAuthBase}/oauth2/auth').replace(
      queryParameters: {
        'client_id': Env.qfClientId,
        'response_type': 'code',
        'redirect_uri': _redirectUri,
        // Full scope set is now enabled on both prelive and production
        // OAuth clients (QF support confirmed prod scope enablement on
        // 2026-05-14). All four resource scopes are singular — plural
        // names cause `invalid_scope`.
        'scope':
            'openid offline_access user bookmark collection reading_session',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': _generateState(),
        // prompt=login clears the cached QF browser session so the user can
        // pick their Google account — like "Continue with Google" does.
        'prompt': 'login',
      },
    );

    _pendingCallback = Completer<Uri>();

    if (!await launchUrl(authUri, mode: LaunchMode.externalApplication)) {
      _pendingCallback = null;
      throw Exception('Could not open browser for Quran Foundation login.');
    }

    final Uri callbackUri;
    try {
      callbackUri = await _pendingCallback!.future.timeout(
        const Duration(minutes: 5),
        onTimeout:
            () => throw TimeoutException('Login timed out, please try again.'),
      );
    } finally {
      _pendingCallback = null;
    }

    final error = callbackUri.queryParameters['error'];
    if (error != null) {
      throw Exception(
        'QF auth error: $error, ${callbackUri.queryParameters['error_description']}',
      );
    }

    final code = callbackUri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw Exception('No authorization code in callback URI.');
    }

    final storedVerifier = await _secureStorage.read(key: _codeVerifierKey);
    await _exchangeCode(code, storedVerifier ?? codeVerifier);
  }

  // ── Sign Out (QF-aware) ─────────────────────────────────────────────────────
  Future<void> signOut() async {
    // Clear QF session tokens
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _codeVerifierKey);

    // Mark as signed out so AuthGate shows the login screen even though
    // the Supabase anonymous session is still alive.
    await _secureStorage.write(key: _qfSignedOutKey, value: 'true');
    isQfSignedOut.value = true;

    // NOTE: We intentionally do NOT call _supabase.auth.signOut() for QF users.
    // Keeping the Supabase session alive means the next QF login will reuse the
    // same anonymous user row — no more duplicate profiles in the database.
  }

  Future<void> refresh() async {
    final currentRefreshToken = await refreshToken;
    if (currentRefreshToken == null) {
      throw Exception('No refresh token available, please sign in again.');
    }
    final response = await _supabase.functions.invoke(
      'qf-token-refresh',
      body: {'refresh_token': currentRefreshToken, 'client_id': Env.qfClientId},
    );
    if (response.status == 200) {
      final data = response.data;
      if (data?['access_token'] != null)
        await _secureStorage.write(
          key: _accessTokenKey,
          value: data['access_token'],
        );
      if (data?['refresh_token'] != null)
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: data['refresh_token'],
        );
    } else {
      throw Exception('Token refresh failed: ${response.data}');
    }
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  Future<void> _exchangeCode(String code, String codeVerifier) async {
    // Signal AuthGate to show a loading screen for the entire exchange,
    // preventing ProfileSetupScreen from flashing between signInAnonymously()
    // and the subsequent updateUser({noor_setup_complete: true}) call.
    loginInProgress.value = true;

    try {
      // Clear the signed-out flag — user is actively logging back in.
      await _secureStorage.delete(key: _qfSignedOutKey);
      isQfSignedOut.value = false;

      final response = await _supabase.functions.invoke(
        'qf-token-exchange',
        body: {
          'code': code,
          'code_verifier': codeVerifier,
          'redirect_uri': _redirectUri,
          'client_id': Env.qfClientId,
        },
      );

      if (response.status != 200) {
        final msg =
            'Token exchange failed (${response.status}): ${response.data}';
        lastSignInError = msg;
        debugPrint('[QF] $msg');
        throw Exception(msg);
      }

      final data = response.data;
      final qfAccessToken = data?['access_token'] as String?;
      final qfRefreshToken = data?['refresh_token'] as String?;

      if (qfAccessToken != null)
        await _secureStorage.write(key: _accessTokenKey, value: qfAccessToken);
      if (qfRefreshToken != null)
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: qfRefreshToken,
        );

      // ── Session decision ─────────────────────────────────────────────────
      // Get the QF sub FIRST so we can verify identity before touching the
      // Supabase session.  This prevents "Fatima's" session from being reused
      // when a completely different person logs in on the same device.
      String? incomingQfSub;
      if (qfAccessToken != null) {
        try {
          final res = await http
              .get(
                Uri.parse('${Env.qfAuthBase}/userinfo'),
                headers: {'Authorization': 'Bearer $qfAccessToken'},
              )
              .timeout(const Duration(seconds: 8));
          if (res.statusCode == 200) {
            final info = jsonDecode(res.body) as Map<String, dynamic>;
            incomingQfSub = info['sub'] as String?;
          }
        } catch (_) {}
      }

      // ── Identity check via SecureStorage (more reliable than metadata) ────
      // SecureStorage persists across QF sign-outs — we never clear it on
      // sign-out, so it reliably records "same QF user, same device" without
      // depending on user metadata (which can silently fail to write).
      //
      // Only create a NEW anonymous session when we can POSITIVELY CONFIRM a
      // different QF identity (both subs known AND mismatched).  If the sub is
      // unknown (userinfo timed out) or matches, reuse the existing session.
      final storedSubForSession = await _secureStorage.read(key: _qfSubKey);
      final isConfirmedDifferentUser =
          incomingQfSub != null &&
          incomingQfSub.isNotEmpty &&
          storedSubForSession != null &&
          storedSubForSession
              .isNotEmpty // empty stored sub = first login, never "different"
              &&
          incomingQfSub != storedSubForSession;

      if (_supabase.auth.currentSession != null && !isConfirmedDifferentUser) {
        debugPrint(
          '[QF] reusing session '
          '(incoming=$incomingQfSub stored=$storedSubForSession)',
        );
      } else {
        // Hand off to the `qf-resolve-session` edge function. It looks up
        // any existing Supabase user by qf_sub (then email), mints a
        // magic-link `token_hash` for that user, and we exchange it for a
        // proper session locally via verifyOTP — no more
        // signInAnonymously + merge churn.
        if (_supabase.auth.currentSession != null) {
          debugPrint(
            '[QF] confirmed different user → signing out '
            '(was $storedSubForSession, now $incomingQfSub)',
          );
          await _supabase.auth.signOut();
        }
        if (qfAccessToken == null || qfAccessToken.isEmpty) {
          // Without a QF access token the edge function can't verify
          // the identity. Fall back to the legacy anon-then-merge path
          // so login still completes (this path is the source of the
          // merged-out rows; only fires when QF userinfo isn't
          // reachable).
          debugPrint('[QF] no qf_access_token — falling back to signInAnonymously');
          await _supabase.auth.signInAnonymously();
        } else {
          try {
            final res = await _supabase.functions.invoke(
              'qf-resolve-session',
              body: {'qf_access_token': qfAccessToken},
            );
            final data = res.data;
            final tokenHash = (data is Map ? data['token_hash'] : null) as String?;
            if (tokenHash == null || tokenHash.isEmpty) {
              throw Exception('qf-resolve-session returned no token_hash: $data');
            }
            await _supabase.auth.verifyOTP(
              type: OtpType.magiclink,
              tokenHash: tokenHash,
            );
            debugPrint(
              '[QF] qf-resolve-session succeeded — signed in as '
              '${_supabase.auth.currentUser?.email}',
            );
          } catch (e) {
            debugPrint('[QF] qf-resolve-session failed ($e) — falling back to signInAnonymously');
            await _supabase.auth.signInAnonymously();
          }
        }
      }

      // Fetch QF profile and stamp Supabase metadata BEFORE releasing the
      // loginInProgress flag — this ensures noor_setup_complete is set before
      // AuthGate evaluates the routing decision.
      if (qfAccessToken != null) {
        await _fetchAndStoreUserInfo(qfAccessToken);
      }
    } catch (e) {
      // Capture every failure mode so the diagnostic UI can surface it even
      // when the ScaffoldMessenger/AlertDialog path is suppressed by a
      // mid-flow widget rebuild. Rethrow so existing handlers
      // (QfEmailConflictException → conflict screen, etc.) keep working.
      lastSignInError ??= e.toString();
      debugPrint('[QF] _exchangeCode failed: $e');
      rethrow;
    } finally {
      loginInProgress.value = false;
    }
  }

  Future<void> _fetchAndStoreUserInfo(String accessToken) async {
    try {
      final res = await http
          .get(
            Uri.parse('${Env.qfAuthBase}/userinfo'),
            headers: {'Authorization': 'Bearer $accessToken'},
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return;

      final info = jsonDecode(res.body) as Map<String, dynamic>;
      final email = (info['email'] as String?) ?? '';
      final name = (info['name'] as String?) ?? '';
      final picture = (info['picture'] as String?) ?? '';
      final sub = (info['sub'] as String?) ?? '';

      debugPrint('[QF] userinfo → email=$email name=$name sub=$sub');

      // ── Returning-user detection (must happen BEFORE the email conflict
      //    check so a returning user is never bounced as a "conflict") ─────
      final storedSub = await _secureStorage.read(key: _qfSubKey);
      final storedName = await _secureStorage.read(key: _qfNameKey);

      final isSameSub = sub.isNotEmpty && sub == storedSub;

      // ── Email conflict detection ─────────────────────────────────────────
      // Only treat a matching email as a conflict when the QF sub differs —
      // i.e. a *different* user is trying to sign in with an email that's
      // already attached to an existing profile. Same-sub re-link must
      // always be allowed (e.g. swapping QF environments, re-login after
      // token expiry, etc.).
      if (email.isNotEmpty && !isSameSub) {
        try {
          final exists =
              await _supabase
                      .rpc(
                        'email_account_exists',
                        params: {'email_param': email},
                      )
                      .single()
                  as bool? ??
              false;
          if (exists) {
            await _supabase.auth.signOut();
            await _secureStorage.delete(key: _accessTokenKey);
            await _secureStorage.delete(key: _refreshTokenKey);
            throw QfEmailConflictException(email);
          }
        } on QfEmailConflictException {
          rethrow;
        } catch (rpcError) {
          debugPrint('[QF] email_account_exists RPC skipped: $rpcError');
        }
      } else if (isSameSub) {
        debugPrint(
            '[QF] same sub as stored ($storedSub), skipping email conflict check');
      }

      // Display name resolution — SecureStorage is only used as a hint for the
      // same identity.  Never inherit another user's cached name.
      var displayName =
          name.isNotEmpty ? name : (isSameSub ? (storedName ?? '') : '');

      debugPrint('[QF] isSameSub=$isSameSub displayName="$displayName"');

      // ── DB authoritative check ────────────────────────────────────────────
      // Rely on profiles.setup_done as the single source of truth.
      // SecureStorage can be stale (same device, different test accounts).
      bool dbSetupDone = false;
      try {
        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null) {
          final profile =
              await _supabase
                  .from('profiles')
                  .select('setup_done, display_name')
                  .eq('id', currentUser.id)
                  .maybeSingle();
          dbSetupDone = profile?['setup_done'] == true;
          // If DB already has a real name (from a completed setup), prefer it.
          final dbName = (profile?['display_name'] as String?) ?? '';
          if (dbSetupDone && dbName.isNotEmpty) {
            displayName = dbName;
            debugPrint(
              '[QF] using DB display_name="$dbName" (setup_done=true by id)',
            );
          }

          // ── Email-based fallback & progress recovery ────────────────────────
          if (!dbSetupDone && email.isNotEmpty) {
            try {
              final result =
                  await _supabase.rpc(
                        'link_qf_profile',
                        params: {
                          'p_email': email,
                          'p_new_id': currentUser.id,
                          'p_name': displayName,
                          'p_picture': picture,
                        },
                      )
                      as String? ??
                  'ERROR: Null response';

              if (result == 'SUCCESS') {
                dbSetupDone = true;
                debugPrint(
                  '[QF] successfully recovered old profile and linked to new anonymous ID',
                );
              } else {
                debugPrint('[QF] RPC failed: $result');
              }
            } catch (e) {
              debugPrint('[QF] profile recovery RPC failed (skipping): $e');
            }
          }
        }
      } catch (e) {
        debugPrint('[QF] DB setup_done check failed (skipping): $e');
      }

      // Persist identity keys — update sub/email/picture always,
      // but only write displayName when we have one.
      await _secureStorage.write(key: _qfSubKey, value: sub);
      await _secureStorage.write(key: _qfEmailKey, value: email);
      await _secureStorage.write(key: _qfPictureKey, value: picture);
      if (displayName.isNotEmpty) {
        await _secureStorage.write(key: _qfNameKey, value: displayName);
      }

      // ── Update Supabase user metadata ────────────────────────────────────
      final meta = <String, dynamic>{
        'provider': 'quran_com',
        'qf_email': email,
        'qf_name': displayName,
        'qf_picture': picture,
        'qf_sub': sub,
        'full_name': displayName,
        'avatar_url': picture,
      };

      // IMPORTANT: Supabase merges metadata — it doesn't replace.
      if (dbSetupDone || name.isNotEmpty) {
        meta['noor_setup_complete'] = true;
        if (displayName.isNotEmpty) meta['noor_name'] = displayName;
        debugPrint(
          '[QF] noor_setup_complete=true (dbSetupDone=$dbSetupDone qfName="$name")',
        );
      } else {
        // Explicitly overwrite any stale 'true' from previous sessions.
        meta['noor_setup_complete'] = false;
        debugPrint(
          '[QF] noor_setup_complete=false → ProfileSetupScreen will show',
        );
      }

      await _supabase.auth.updateUser(UserAttributes(data: meta));

      // ── Upsert into profiles table ────────────────────────────────────────
      // Only write display_name from AUTHORITATIVE sources:
      //   • name.isNotEmpty → QF userinfo returned it directly
      //   • dbSetupDone     → user completed setup; DB name already correct
      // NEVER write a stale SecureStorage name for a new/incomplete user
      // (that's how "Fatima" kept appearing for different users).
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final row = <String, dynamic>{'id': user.id};
        if (email.isNotEmpty) row['email'] = email;
        if (picture.isNotEmpty) row['avatar_url'] = picture;

        // Authoritative name only — from QF directly or completed-setup DB row
        final authoritativeName =
            name.isNotEmpty ? name : (dbSetupDone ? displayName : '');
        if (authoritativeName.isNotEmpty)
          row['display_name'] = authoritativeName;

        if (row.length > 1) {
          await _supabase
              .from('profiles')
              .upsert(row, onConflict: 'id', ignoreDuplicates: false);
          debugPrint('[QF] profiles upserted → ${row.keys.toList()}');
        }
      }
    } catch (e) {
      if (e is QfEmailConflictException) rethrow;
      debugPrint('[QF] userinfo fetch failed (non-fatal): $e');
    }
  }

  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _generateCodeChallenge(String codeVerifier) {
    final digest = sha256.convert(utf8.encode(codeVerifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String _generateState() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
