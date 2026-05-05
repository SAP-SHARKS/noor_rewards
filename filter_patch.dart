import 'dart:io';
import 'dart:convert';

void main() {
  final diffLines = File('dhikr_diff_utf8.patch').readAsLinesSync(encoding: utf8);
  
  final filteredLines = <String>[];
  List<String> currentHunk = [];
  bool hunkHasNonAsciiChange = false;
  
  for (int i = 0; i < diffLines.length; i++) {
    final line = diffLines[i];
    if (line.startsWith('@@ ')) {
      // Flush previous hunk
      if (currentHunk.isNotEmpty && !hunkHasNonAsciiChange) {
        filteredLines.addAll(currentHunk);
      }
      currentHunk = [line];
      hunkHasNonAsciiChange = false;
    } else if (line.startsWith('diff --git') || line.startsWith('index ') || line.startsWith('--- ') || line.startsWith('+++ ')) {
      if (currentHunk.isNotEmpty && !hunkHasNonAsciiChange) {
        filteredLines.addAll(currentHunk);
      }
      currentHunk = [];
      filteredLines.add(line);
    } else {
      if (currentHunk.isNotEmpty) {
        currentHunk.add(line);
        if (line.startsWith('-') || line.startsWith('+')) {
          if (RegExp(r'[^\x00-\x7F]').hasMatch(line)) {
            hunkHasNonAsciiChange = true;
          }
        }
      }
    }
  }
  
  if (currentHunk.isNotEmpty && !hunkHasNonAsciiChange) {
    filteredLines.addAll(currentHunk);
  }
  
  File('filtered.patch').writeAsStringSync(filteredLines.join('\n'), encoding: utf8);
  print('Done. Original lines: ${diffLines.length}, Filtered: ${filteredLines.length}');
}
