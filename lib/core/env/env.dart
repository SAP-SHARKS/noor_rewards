import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  static bool get isDev => (dotenv.env['IS_DEV']?.toLowerCase() ?? 'true') == 'true';

  static String get qfEnv => isDev ? 'prelive' : 'production';

  static String get qfClientId => isDev 
      ? (dotenv.env['QURAN_PRELIVE_CLIENT_ID'] ?? '') 
      : (dotenv.env['QURAN_PROD_CLIENT_ID'] ?? '');

  static String get qfAuthBase {
    return isDev
        ? 'https://prelive-oauth2.quran.foundation'
        : 'https://oauth2.quran.foundation';
  }

  static String get qfApiBase {
    return qfAuthBase; 
  }
}
