import 'dart:io';

void main() {
  final f = File('lib/screens/dhikr_screen.dart');
  var content = f.readAsStringSync();

  const oldBlock = '''
    String cleanReward = azkar.reward.trim();
    extractReference(cleanReward, (clean, ref) {
      cleanReward = clean.replaceAll(RegExp(r\'^\\||\\|\$'), \'\').trim();
      if (bottomRef.isEmpty) bottomRef = ref;
    });
''';

  // Find the block and replace it
  final idx = content.indexOf('    String cleanReward = azkar.reward.trim();');
  if (idx == -1) {
    print('ERROR: could not find cleanReward block');
    return;
  }

  // Find end of this block (after the closing });)
  final endPattern = '    });\r\n';
  final endIdx = content.indexOf(endPattern, idx);
  if (endIdx == -1) {
    print('ERROR: could not find end of block');
    return;
  }

  final blockEnd = endIdx + endPattern.length;
  final existing = content.substring(idx, blockEnd);
  print('Found block:\n$existing');

  const newBlock = '''    String cleanReward = azkar.reward.trim();
    extractReference(cleanReward, (clean, ref) {
      cleanReward = clean.replaceAll(RegExp(r'^\\|'), '').replaceAll(RegExp(r'\\|\$'), '').trim();
      if (bottomRef.isEmpty) bottomRef = ref;
    });
    // Strip pipe-separated reference (e.g. "Knower of the Unseen | At-Tirmidhi 3392")
    if (cleanReward.contains('|')) {
      final pipeParts = cleanReward.split('|');
      cleanReward = pipeParts.first.trim();
      final pipedRef = pipeParts.skip(1).join(' ').trim();
      if (bottomRef.isEmpty && pipedRef.isNotEmpty) bottomRef = pipedRef;
    }
''';

  content = content.substring(0, idx) + newBlock + content.substring(blockEnd);
  f.writeAsStringSync(content);
  print('Done! Added pipe-split post-processing to cleanReward.');
}
