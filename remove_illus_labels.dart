import 'dart:io';

void main() {
  final f = File('lib/screens/dhikr_screen.dart');
  final lines = f.readAsLinesSync();
  final out = <String>[];

  int removedPts = 0;
  int removedLabel = 0;
  bool skipping = false;
  int braceDepth = 0;
  String skipReason = '';

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    // === Already in a skip block ===
    if (skipping) {
      final opens = line.split('{').length - 1;
      final closes = line.split('}').length - 1;
      braceDepth += opens - closes;
      if (braceDepth <= 0) {
        skipping = false;
        braceDepth = 0;
        if (skipReason == 'pts') removedPts++;
        if (skipReason == 'label') removedLabel++;
      }
      continue;
    }

    // === Detect pointsToday > 0 block ===
    if (trimmed.startsWith('if (pointsToday > 0)') ||
        trimmed.startsWith('if (pointsToday> 0)')) {
      final opens = line.split('{').length - 1;
      final closes = line.split('}').length - 1;
      if (opens > closes) {
        skipping = true;
        braceDepth = opens - closes;
        skipReason = 'pts';
      } else {
        removedPts++; // single-line
      }
      continue;
    }

    // === Detect % progress label — find 'final label = isComplete ?' lines that deal with %
    // OR 'final pct = (progress * 100).round();'
    // We remove: final pct, final label, final tp2 TextPainter block, tp2.paint line
    if (trimmed.startsWith('final pct = (progress * 100)') ||
        trimmed.startsWith('final pct=(progress')) {
      // skip this line + label + TextPainter + .paint
      removedLabel++;
      // Mark that we need to skip until tp2.paint(...)
      // Use a lookahead approach: just skip next sequential matching lines
      out.add('    // progress % label removed');
      // Skip consecutive related lines
      int j = i + 1;
      while (j < lines.length) {
        final next = lines[j].trim();
        if (next.startsWith('final label =') ||
            next.startsWith('final tp2 =') ||
            next.startsWith('final labelTp') ||
            next.contains('TextPainter(') ||
            next.contains('TextSpan(text: label') ||
            next.contains('textDirection: TextDirection') ||
            next.contains(')..layout()') ||
            next.startsWith('tp2.paint(') ||
            next.contains('..layout()') ||
            next.startsWith('text: label') ||
            next.startsWith('text: TextSpan(text: label') ||
            next == ')..layout();' ||
            (next.startsWith(')') && next.endsWith('layout();'))) {
          j++;
        } else if (next.isEmpty || next == '') {
          j++; // skip blank lines too
          break;
        } else {
          break;
        }
      }
      i = j - 1;
      continue;
    }

    // final label = isComplete ? ... : '${(progress * 100).round()}%'
    if ((trimmed.startsWith('final label =') || trimmed.startsWith('final label=')) &&
        line.contains('%')) {
      out.add('    // progress % label removed');
      // Skip tp2 TextPainter and tp2.paint block
      int j = i + 1;
      int depth = 0;
      while (j < lines.length) {
        final next = lines[j].trim();
        depth += lines[j].split('(').length - 1 - (lines[j].split(')').length - 1);
        if (next.startsWith('tp2.paint(') && depth <= 0) {
          j++;
          break;
        }
        if (next.startsWith('tp2.paint(')) { j++; break; }
        j++;
        if (j > i + 25) break; // safety limit
      }
      i = j - 1;
      removedLabel++;
      continue;
    }

    // Catch stray tp2 lines after a removed label
    // (if the label was removed but tp2 was somehow kept)
    // This is a safety net — only kick in if line doesn't reference other things
    if ((trimmed.startsWith('tp2.paint(canvas') || trimmed == ')..layout();') &&
        !line.contains('tp2 =')) {
      // likely orphan — skip
      continue;
    }

    out.add(line);
  }

  f.writeAsStringSync(out.join('\r\n'));
  print('Done! Removed $removedPts pts-badge blocks, $removedLabel % label blocks.');
}
