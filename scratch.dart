import 'dart:io';

void main() {
  final content = File('out2.txt').readAsStringSync();
  
  final vowelledWord = r'[^\s]*[\u064B-\u065F\u0670\u06D6-\u06ED][^\s]*';
  final regex = RegExp('((?:$vowelledWord(?:\\s+|\$))+)');
  
  final matches = regex.allMatches(content);
  for (final m in matches) {
    print('MATCH: [${m.group(0)?.trim()}]');
  }
}
