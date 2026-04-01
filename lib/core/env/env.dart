import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  static String get qfEnv => dotenv.env['QF_ENV'] ?? 'prelive';
  static String get qfClientId => dotenv.env['QF_CLIENT_ID'] ?? '';

  static String get qfAuthBase {
    return qfEnv == 'production'
        ? 'https://oauth2.quran.foundation'
        : 'https://prelive-oauth2.quran.foundation';
  }

  static String get qfApiBase {
    return qfAuthBase; 
  }
}
