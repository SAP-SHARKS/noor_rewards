import 'dart:io';

void main() {
  final f = File('lib/screens/dhikr_screen.dart');
  var c = f.readAsStringSync();

  // Pattern 1: multiline blocks — extract the 3-line punch scale block
  // canvas.translate(cx, cy);
  // canvas.scale(punchScale, punchScale);
  // canvas.translate(-cx, -cy);
  c = c.replaceAll(
    'canvas.translate(cx, cy);\r\n    canvas.scale(punchScale, punchScale);\r\n    canvas.translate(-cx, -cy);',
    '// punch scale removed — smooth calm tap'
  );
  c = c.replaceAll(
    'canvas.translate(cx, cy);\n    canvas.scale(punchScale, punchScale);\n    canvas.translate(-cx, -cy);',
    '// punch scale removed — smooth calm tap'
  );

  // Pattern 2: inline one-liners 
  c = c.replaceAll(
    'canvas.save(); canvas.translate(cx, cy); canvas.scale(punchScale, punchScale); canvas.translate(-cx, -cy);',
    '// punch scale removed — smooth calm tap'
  );

  // Remaining stragglers — any line still calling canvas.scale(punchScale, punchScale):
  // Replace just the scale call (keeping save/restore intact so no crash)
  c = c.replaceAll(
    'canvas.scale(punchScale, punchScale);',
    '// punch scale removed'
  );

  f.writeAsStringSync(c);
  print('Done! Removed ${RegExp(r'punch scale removed').allMatches(c).length} punch scale calls.');
}
