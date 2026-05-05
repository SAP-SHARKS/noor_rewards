import 'dart:io';

void main() {
  String content = File('lib/screens/dhikr_screen.dart').readAsStringSync();
  
  // 1. Hex codes
  content = content.replaceAll('0xFF10B981', '0xFFD89A1E');
  content = content.replaceAll('0xFF34D399', '0xFFFFC83D');
  content = content.replaceAll('0xFF059669', '0xFF7A5200');
  content = content.replaceAll('0xFF22C55E', '0xFFD89A1E');
  content = content.replaceAll('0xFF047857', '0xFF7A5200');
  content = content.replaceAll('0xFF065F46', '0xFF7A5200');
  content = content.replaceAll('0xFF6EE7B7', '0xFFFFC83D');
  content = content.replaceAll('0xFFA7F3D0', '0xFFFFF4D2');
  
  // 2. SettingsService dynamic overrides
  content = content.replaceAll('SettingsService.instance.config.azkarAccent', 'const Color(0xFFD89A1E)');
  content = content.replaceAll('SettingsService.instance.config.azkarHighlight', 'const Color(0xFFFFC83D)');
  content = content.replaceAll('SettingsService.instance.config.azkarTextHighlight', 'const Color(0xFFD89A1E)');

  // 3. _pickTaglineColor safely
  // We locate 'Color _pickTaglineColor(String id, bool isDark) {'
  // and replace the entire function until its ending brace.
  final startStr = 'Color _pickTaglineColor(String id, bool isDark) {';
  final endStr = 'return AppLocalizations.of(context)?.duaTitle ?? \'Dua\';';
  
  int startIdx = content.indexOf(startStr);
  if (startIdx != -1) {
    // We just find the start of the next function which is `String _duaTitle`
    int nextFuncIdx = content.indexOf('String _duaTitle', startIdx);
    if (nextFuncIdx != -1) {
      // Find the closing brace of _pickTaglineColor before nextFuncIdx
      int lastBrace = content.lastIndexOf('}', nextFuncIdx);
      if (lastBrace != -1) {
        final prefix = content.substring(0, startIdx);
        final suffix = content.substring(lastBrace + 1);
        content = prefix + 'Color _pickTaglineColor(String id, bool isDark) { return isDark ? const Color(0xFFFFC83D) : const Color(0xFF7A5200); }\n\n' + suffix;
      }
    }
  }

  File('lib/screens/dhikr_screen.dart').writeAsStringSync(content);
  
  // Also clean up dhikr_hub_screen.dart
  String hubContent = File('lib/screens/dhikr_hub_screen.dart').readAsStringSync();
  hubContent = hubContent.replaceAll('SettingsService.instance.config.azkarAccent', 'const Color(0xFFD89A1E)');
  hubContent = hubContent.replaceAll('SettingsService.instance.config.azkarHighlight', 'const Color(0xFFFFC83D)');
  hubContent = hubContent.replaceAll('SettingsService.instance.config.azkarTextHighlight', 'const Color(0xFFD89A1E)');
  hubContent = hubContent.replaceAll('0xFF1E3A8A', '0xFF7A5200'); // Deep blue to honey
  hubContent = hubContent.replaceAll('0xFF0F172A', '0xFF5E3F00'); // Midnight blue to dark honey
  
  // Replace the gradients in dhikr_hub_screen.dart
  hubContent = hubContent.replaceAll('0xFF10B981', '0xFFD89A1E');
  hubContent = hubContent.replaceAll('0xFF059669', '0xFF7A5200');
  hubContent = hubContent.replaceAll('0xFFD1FAE5', '0xFFFFF4D2');
  hubContent = hubContent.replaceAll('0xFF34D399', '0xFFFFC83D');
  
  File('lib/screens/dhikr_hub_screen.dart').writeAsStringSync(hubContent);

  print('Final safe sweep done!');
}
