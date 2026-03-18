import 'dart:convert';
import 'dart:io';

void main() {
  final azkarStr = File('assets/data/azkar.json').readAsStringSync();
  final List<dynamic> azkarMerged = jsonDecode(azkarStr);
  int printCount = 0;
  final StringBuffer buf = StringBuffer();
  for (final item in azkarMerged) {
    if (item['category'] == 'morning' || item['category'] == 'evening') {
      buf.writeln("${item['id']} - Count: ${item['recommended_count']}");
      printCount++;
    }
  }
  buf.writeln('Total Morning/Evening items: $printCount');
  File('countstmp2.txt').writeAsStringSync(buf.toString());
}
