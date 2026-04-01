import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/env/env.dart';

class QfAuthService {
  static final QfAuthService instance = QfAuthService._();
  QfAuthService._();

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final _supabase = Supabase.instance.client;

  static const String _redirectUri = 'com.example.noor_rewards://oauth2/callback';
  static const String _accessTokenKey = 'qf_access_token';
  static const String _refreshTokenKey = 'qf_refresh_token';

  Future<String?> get accessToken => _secureStorage.read(key: _accessTokenKey);
  Future<String?> get refreshToken => _secureStorage.read(key: _refreshTokenKey);

  Future<void> signIn() async {
    try {
      final AuthorizationResponse? authResponse = await _appAuth.authorize(
        AuthorizationRequest(
          Env.qfClientId,
          _redirectUri,
          discoveryUrl: '${Env.qfAuthBase}/.well-known/openid-configuration',
          scopes: ['openid', 'profile', 'email'], 
        ),
      );

      if (authResponse != null && authResponse.authorizationCode != null) {
        // Exchange code for token using Supabase Edge Function as QF requires Confidential Client
        final response = await _supabase.functions.invoke(
          'qf-token-exchange',
          body: {
            'code': authResponse.authorizationCode,
            'code_verifier': authResponse.codeVerifier,
            'redirect_uri': _redirectUri,
            'client_id': Env.qfClientId,
          },
        );

        if (response.status == 200) {
          final data = response.data;
          if (data != null && data['access_token'] != null) {
            await _secureStorage.write(key: _accessTokenKey, value: data['access_token']);
          }
          if (data != null && data['refresh_token'] != null) {
            await _secureStorage.write(key: _refreshTokenKey, value: data['refresh_token']);
          }
        } else {
          throw Exception('Token exchange failed: ${response.data}');
        }
      } else {
         throw Exception('Authorization failed or was canceled.');
      }
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  Future<void> refresh() async {
    try {
      final String? currentRefreshToken = await refreshToken;
      if (currentRefreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _supabase.functions.invoke(
        'qf-token-refresh',
        body: {
          'refresh_token': currentRefreshToken,
          'client_id': Env.qfClientId,
        },
      );

      if (response.status == 200) {
        final data = response.data;
        if (data != null && data['access_token'] != null) {
          await _secureStorage.write(key: _accessTokenKey, value: data['access_token']);
        }
        if (data != null && data['refresh_token'] != null) {
          await _secureStorage.write(key: _refreshTokenKey, value: data['refresh_token']);
        }
      } else {
        throw Exception('Token refresh failed: ${response.data}');
      }
    } catch (e) {
      throw Exception('Refresh failed: $e');
    }
  }

  Future<void> signOut() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }
}
