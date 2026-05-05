import 'dart:io';
import 'dart:convert';

void main() {
  final diffLines = File('dhikr_diff_utf8.patch').readAsLinesSync(encoding: utf8);
  String dartContent = File('lib/screens/dhikr_screen.dart').readAsStringSync(encoding: utf8);
  
  String? minusLine;
  int count = 0;
  
  for (final line in diffLines) {
    if (line.startsWith('-') && !line.startsWith('--- ')) {
      minusLine = line.substring(1).trim();
    } else if (line.startsWith('+') && !line.startsWith('+++ ') && minusLine != null) {
      final plusLine = line.substring(1).trim();
      
      // ONLY replace if the minus line contains Color or SettingsService
      if ((minusLine.contains('Color(') || minusLine.contains('SettingsService')) &&
          !RegExp(r'[^\x00-\x7F]').hasMatch(minusLine) && !RegExp(r'[^\x00-\x7F]').hasMatch(plusLine)) {
        
        if (dartContent.contains(minusLine)) {
          dartContent = dartContent.replaceFirst(minusLine, plusLine);
          count++;
        }
      }
      minusLine = null;
    } else if (!line.startsWith('-')) {
      minusLine = null;
    }
  }
  
  File('lib/screens/dhikr_screen.dart').writeAsStringSync(dartContent, encoding: utf8);
  print('Color replacements applied safely! $count replacements made.');
}
