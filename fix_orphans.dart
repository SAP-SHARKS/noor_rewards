import 'dart:io';

void main() {
  final f = File('lib/screens/dhikr_screen.dart');
  var content = f.readAsStringSync();

  int before = content.length;

  // Pattern 1: leftover TextSpan(text: label...) + textDirection block
  // These look like:
  //   text: TextSpan(
  //     text: label,
  //     style: ...,
  //   ),
  //   textDirection: TextDirection.rtl|ltr,
  // Remove the whole fragment including surrounding blank lines

  // Match from `text: TextSpan(` (with varying indents) through `textDirection: TextDirection.xxx,`
  final r1 = RegExp(
    r'[ \t]+text: TextSpan\(\r?\n'
    r'[ \t]+text: label,\r?\n'
    r'[ \t]+style: [^\n]+\r?\n'
    r'(?:[ \t]+[^\n]+\r?\n)*?' // optional extra lines (colors etc.)
    r'[ \t]+\),\r?\n'
    r'[ \t]+textDirection: TextDirection\.\w+,\r?\n',
    multiLine: true,
  );
  content = content.replaceAll(r1, '');

  // Pattern 2: simple orphan pairs
  // `      text: TextSpan(\n        text: label,\n        style: ...,\n      ),\n`
  final r2 = RegExp(
    r'\r?\n[ \t]+text: TextSpan\([^\n]*label[^\)]*\)[^\n]*\r?\n',
    multiLine: true,
  );

  // Pattern 3: standalone `textDirection: TextDirection.rtl,` or ltr following a `),`
  final r3 = RegExp(
    r'\r?\n([ \t]+textDirection: TextDirection\.\w+,\r?\n)',
    multiLine: true,
  );

  // Pattern 4: orphan `tp.paint(canvas, Offset(cx - tp.width / 2, ...));` lines
  // where tp was the label TextPainter (tp2)
  final r4 = RegExp(
    r'[ \t]+tp2\.paint\(canvas, Offset\([^\)]*\)\);\r?\n',
    multiLine: true,
  );

  // Pattern 5: leftover `// ── Points badge ──` comment with nothing after (inside paint method)
  // Already harmless, leave.

  // Apply pattern 1 (most comprehensive for the TextSpan block)
  var prev = '';
  while (prev != content) {
    prev = content;
    content = content.replaceAll(r1, '');
  }

  // Find remaining `text: label` references (simple, fallback)
  final lines = content.split('\r\n');
  final out = <String>[];
  
  for (int i = 0; i < lines.length; i++) {
    final t = lines[i].trim();
    
    // Skip orphan text: label, TextSpan fragments
    if (t == 'text: label,' || t.startsWith('text: TextSpan(') && t.contains('label')) {
      // skip until closing `),.` and textDirection
      while (i < lines.length - 1) {
        i++;
        final nt = lines[i].trim();
        if (nt == 'textDirection: TextDirection.rtl,' || nt == 'textDirection: TextDirection.ltr,') break;
        if (nt.startsWith('//') || nt.isEmpty) { i--; break; }
      }
      continue;
    }
    
    // Skip orphan textDirection: TextDirection lines not preceded by a text: line
    if ((t == 'textDirection: TextDirection.rtl,' || t == 'textDirection: TextDirection.ltr,') && i > 0) {
      final prev2 = out.isNotEmpty ? out.last.trim() : '';
      // If previous kept line isn't a text: or a TextPainter arg, this is orphan
      if (!prev2.startsWith('text:') && !prev2.endsWith('(,') && !prev2.startsWith('TextPainter(')) {
        continue;
      }
    }
    
    // Skip stray )..layout(); lines not in a valid context
    if (t == ')..layout();' && i > 0) {
      final prev2 = out.isNotEmpty ? out.last.trim() : '';
      if (!prev2.endsWith(',') || prev2 == '// progress % label removed') {
        continue;
      }
    }
    
    // Skip stray tp2.paint(...) lines if tp2 wasn't declared recently
    if (t.startsWith('tp2.paint(canvas, Offset(')) {
      bool hasDecl = false;
      final recent = out.length > 20 ? out.sublist(out.length - 20) : out;
      for (final rl in recent) {
        if (rl.contains('final tp2 =') || rl.contains('tp2 = TextPainter')) {
          hasDecl = true; break;
        }
      }
      if (!hasDecl) continue;
    }

    out.add(lines[i]);
  }

  f.writeAsStringSync(out.join('\r\n'));
  print('Done. File size: ${before} -> ${f.lengthSync()} bytes');
}
