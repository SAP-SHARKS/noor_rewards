import 'dart:convert';
import 'dart:io';

void main() {
  final azkarStr = File('assets/data/azkar.json').readAsStringSync();
  final List<dynamic> azkar = jsonDecode(azkarStr);

  StringBuffer sb = StringBuffer();
  for (final item in azkar) {
    if (item['category'] != 'morning' && item['category'] != 'evening') {
      sb.writeln("${item['id']} | Count: ${item['recommended_count']} | Ref: ${item['reference']} | Reward: ${item['reward']}");
    }
  }
  File('other_azkar_counts_utf8.txt').writeAsStringSync(sb.toString());
}
