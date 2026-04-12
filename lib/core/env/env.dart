import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  // changed default fallback from 'true' to 'false' so production is the default
  static bool get isDev => (dotenv.env['IS_DEV']?.toLowerCase() ?? 'false') == 'true';

  static String get qfEnv => isDev ? 'prelive' : 'production';

  static String get qfClientId {
    final devId = dotenv.env['QURAN_PRELIVE_CLIENT_ID'];
    final prodId = dotenv.env['QURAN_PROD_CLIENT_ID'];
    
    if (isDev) {
      return (devId != null && devId.isNotEmpty) 
          ? devId 
          : 'a9a32c8d-b110-4ac0-b8d8-fa4714be01c6'; // Pre-Prod provided by QF
    } else {
      return (prodId != null && prodId.isNotEmpty) 
          ? prodId 
          : '44f22d7d-b4dc-467b-b4c8-04f545c124e1'; // Production provided by QF
    }
  }

  static String get qfAuthBase {
    return isDev
        ? 'https://prelive-oauth2.quran.foundation'
        : 'https://oauth2.quran.foundation';
  }

  static String get qfApiBase {
    return qfAuthBase; 
  }
}
