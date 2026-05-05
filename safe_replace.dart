import 'dart:io';

void main() {
  String content = File('lib/screens/dhikr_screen.dart').readAsStringSync();
  
  // 1. Hex codes
  content = content.replaceAll('0xFF10B981', '0xFFD89A1E');
  content = content.replaceAll('0xFF34D399', '0xFFFFC83D');
  content = content.replaceAll('0xFF059669', '0xFF7A5200');
  content = content.replaceAll('0xFF22C55E', '0xFFD89A1E');
  content = content.replaceAll('0xFF047857', '0xFF7A5200'); // emerald-700
  content = content.replaceAll('0xFF065F46', '0xFF7A5200'); // emerald-800
  content = content.replaceAll('0xFF6EE7B7', '0xFFFFC83D'); // emerald-300
  content = content.replaceAll('0xFFA7F3D0', '0xFFFFF4D2'); // emerald-200
  
  // 2. RGBO colors in _DuaScenePainter and elsewhere
  content = content.replaceAll('Color.fromRGBO(70, 150, 55', 'Color.fromRGBO(216, 154, 30');
  content = content.replaceAll('Color.fromRGBO(55, 130, 70', 'Color.fromRGBO(255, 200, 61');
  content = content.replaceAll('Color.fromRGBO(60, 130, 70', 'Color.fromRGBO(122, 82, 0');
  content = content.replaceAll('Color.fromRGBO(55, 125, 100', 'Color.fromRGBO(216, 154, 30');
  content = content.replaceAll('Color.fromRGBO(52, 211, 153', 'Color.fromRGBO(255, 200, 61');
  content = content.replaceAll('Color.fromRGBO(16, 185, 129', 'Color.fromRGBO(216, 154, 30');
  
  // 3. _pickTaglineColor
  // The original has a full switch statement. We will replace the entire function.
  // We'll find 'Color _pickTaglineColor(String id, bool isDark) {' and replace until the matching '}'
  final regex = RegExp(r'Color _pickTaglineColor\(String id, bool isDark\) \{.*?\n\}', dotAll: true);
  content = content.replaceFirst(regex, 'Color _pickTaglineColor(String id, bool isDark) { return isDark ? const Color(0xFFFFC83D) : const Color(0xFF7A5200); }');

  File('lib/screens/dhikr_screen.dart').writeAsStringSync(content);
  print('Safe replacements done!');
}
