import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  static bool get isDev => (dotenv.env['IS_DEV']?.toLowerCase() ?? 'true') == 'true';

  static String get qfEnv => isDev ? 'prelive' : 'production';

  static String get qfClientId {
    final devId = dotenv.env['QURAN_PRELIVE_CLIENT_ID'];
    final prodId = dotenv.env['QURAN_PROD_CLIENT_ID'];
    
    if (isDev) {
      return (devId != null && devId.isNotEmpty) 
          ? devId 
          : '74985a30-ba9a-4a4e-995c-3d8c88d32d16'; // Fallback
    } else {
      return (prodId != null && prodId.isNotEmpty) 
          ? prodId 
          : 'b0b2b612-b905-4d0e-9164-559f03ccb265'; // Fallback
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
