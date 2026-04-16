import 'dart:io';
import 'dart:convert';

void main() {
  final f = File('lib/screens/dhikr_screen.dart');
  final lines = f.readAsLinesSync();
  final out = <String>[];

  int removedParticle = 0;
  int removedShock = 0;
  bool skipping = false;
  int braceDepth = 0;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    // === Detect start of a particle OR shockwave block ===
    if (!skipping) {
      final isParticle = line.contains('if (particlePhase > 0 && particlePhase < 1)');
      final isShock = line.contains('if (shockPhase > 0 && shockPhase < 1)');

      if (isParticle || isShock) {
        // Check if it's a one-liner (all on this line)
        final openCount = line.split('{').length - 1;
        final closeCount = line.split('}').length - 1;

        if (openCount > 0 && openCount == closeCount) {
          // Self-contained single line — skip it entirely
          if (isParticle) removedParticle++;
          if (isShock) removedShock++;
          out.add('    // tap-effect removed — smooth calm');
          continue;
        } else if (openCount > closeCount) {
          // Multi-line block starting here — enter skip mode
          skipping = true;
          braceDepth = openCount - closeCount;
          if (isParticle) removedParticle++;
          if (isShock) removedShock++;
          out.add('    // tap-effect removed — smooth calm');
          continue;
        }
      }
    } else {
      // Count braces to find end of block
      final openCount = line.split('{').length - 1;
      final closeCount = line.split('}').length - 1;
      braceDepth += openCount - closeCount;

      if (braceDepth <= 0) {
        skipping = false;
        braceDepth = 0;
      }
      continue; // skip this line
    }

    out.add(line);
  }

  f.writeAsStringSync(out.join('\r\n'));
  print('Done! Removed $removedParticle particle blocks, $removedShock shockwave blocks.');
}
