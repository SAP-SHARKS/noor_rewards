import 'dart:io';

void main() {
  final f = File('lib/screens/dhikr_screen.dart');
  final lines = f.readAsLinesSync();
  final out = <String>[];
  int removed = 0;

  bool hasArabic(String s) {
    // Arabic Unicode block U+0600–U+06FF + extended
    return s.runes.any((r) => r >= 0x0600 && r <= 0x06FF);
  }

  bool isArabicPainterStart(String trimmed) {
    // TextPainter declarations that draw Arabic
    return (trimmed.startsWith('final tp') || trimmed.startsWith('final tpA') ||
            trimmed.startsWith('final tpM') || trimmed.startsWith('final tpE') ||
            trimmed.startsWith('final tpL')) &&
           trimmed.contains('TextPainter(');
  }

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    // === Detect start of a TextPainter block that renders Arabic text ===
    if (isArabicPainterStart(trimmed)) {
      // Look ahead to see if this block uses _illusArabic, _illusTag, or Arabic chars
      final lookahead = StringBuffer(line);
      int j = i + 1;
      int depth = trimmed.split('(').length - 1 - (trimmed.split(')').length - 1);
      // collect until the block closes AND the .paint() call
      while (j < lines.length && j < i + 30) {
        lookahead.write('\n${lines[j]}');
        depth += lines[j].split('(').length - 1;
        depth -= lines[j].split(')').length - 1;
        if (depth <= 0) { j++; break; }
        j++;
      }
      // also grab the .paint() or ..layout() line if next
      while (j < lines.length && j < i + 35) {
        final next = lines[j].trim();
        lookahead.write('\n${lines[j]}');
        j++;
        if (next.startsWith('tp') && next.contains('.paint(')) break;
        if (!next.startsWith('tp') && !next.startsWith(')') && !next.startsWith('..')) break;
      }
      final block = lookahead.toString();
      final isArabic = block.contains('_illusArabic(') ||
                       block.contains('_illusTag(') ||
                       hasArabic(block);

      if (isArabic) {
        // Also skip any wrapping `if` statement (look back 1–2 lines)
        // Check if previous output line is an `if (...)` that references this block
        while (out.isNotEmpty) {
          final prev = out.last.trim();
          if (prev.startsWith('// label') ||
              prev.startsWith('//') && (prev.contains('label') || prev.contains('Label') || prev.contains('arabic') || prev.contains('Arabic') || prev.contains('text') || prev.contains('Text'))) {
            out.removeLast();
          } else {
            break;
          }
        }
        // Check if the context has an unclosed `if (` that belongs to this painter
        // We need to skip from i to j (inclusive of paint line)
        // But ALSO skip any surrounding if block
        // Scan backward in out for unclosed if
        if (out.isNotEmpty) {
          final checkPrev = out.last.trim();
          if (checkPrev.startsWith('if (') && !checkPrev.endsWith(';')) {
            // there might be an opening if — skip it
            out.removeLast();
          }
        }
        removed++;
        i = j - 1; // skip the whole block
        continue;
      }
    }

    // === Remove any remaining stray _illusArabic or _illusTag paint calls ===
    if (trimmed.contains('_illusArabic(') || trimmed.contains('_illusTag(')) {
      // If it's inside a TextSpan still in the file — skip it
      removed++;
      continue;
    }

    // === Remove any remaining Arabic string labels===
    // Lines that contain text: TextSpan(text: 'Arabic...'
    if (trimmed.startsWith('text: TextSpan(') && hasArabic(line)) {
      removed++;
      continue;
    }

    out.add(line);
  }

  f.writeAsStringSync(out.join('\r\n'));
  print('Done. Removed $removed Arabic text painter blocks/lines from illustrations.');
}
