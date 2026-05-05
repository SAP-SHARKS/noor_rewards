import 'dart:io';

void main() {
  String content = File('lib/screens/dhikr_screen.dart').readAsStringSync();
  
  // Replace SettingsService dynamic colors with hardcoded Honey constants
  content = content.replaceAll('SettingsService.instance.config.azkarAccent', 'const Color(0xFFD89A1E)');
  content = content.replaceAll('SettingsService.instance.config.azkarHighlight', 'const Color(0xFFFFC83D)');
  content = content.replaceAll('SettingsService.instance.config.azkarTextHighlight', 'const Color(0xFFD89A1E)');
  
  // Also fix dhikr_hub_screen.dart if needed
  String hubContent = File('lib/screens/dhikr_hub_screen.dart').readAsStringSync();
  hubContent = hubContent.replaceAll('SettingsService.instance.config.azkarAccent', 'const Color(0xFFD89A1E)');
  hubContent = hubContent.replaceAll('SettingsService.instance.config.azkarHighlight', 'const Color(0xFFFFC83D)');
  hubContent = hubContent.replaceAll('SettingsService.instance.config.azkarTextHighlight', 'const Color(0xFFD89A1E)');
  File('lib/screens/dhikr_hub_screen.dart').writeAsStringSync(hubContent);

  File('lib/screens/dhikr_screen.dart').writeAsStringSync(content);
  print('Theme overrides applied!');
}
