// Bring all non-EN .arb files up to key parity with app_en.arb.
//
// For each key present in app_en.arb but missing from a target .arb:
//   - Insert with the English value as a placeholder.
//   - Insert @-metadata (placeholders block) alongside if present in en.arb.
//
// Preserves existing translated values. Rewrites files pretty-printed with
// the en.arb key order so future diffs are stable.
//
// Usage: `dart run scripts/mirror_arb_keys.dart`

import 'dart:convert';
import 'dart:io';

const _targetLocales = ['ur', 'ar', 'fr', 'id', 'ms', 'ru', 'tr'];

void main() {
  final enFile = File('lib/l10n/app_en.arb');
  final enRaw = enFile.readAsStringSync();
  final enMap = jsonDecode(enRaw) as Map<String, dynamic>;
  final enKeys = enMap.keys.toList();

  final summary = <String, int>{};
  for (final loc in _targetLocales) {
    final f = File('lib/l10n/app_$loc.arb');
    final map = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;

    var added = 0;
    for (final k in enKeys) {
      if (k == '@@locale') continue;
      if (map.containsKey(k)) continue;
      // Insert English value as placeholder.
      map[k] = enMap[k];
      added++;
    }

    // Rebuild in en.arb order, forcing @@locale first.
    final ordered = <String, dynamic>{'@@locale': loc};
    for (final k in enKeys) {
      if (k == '@@locale') continue;
      if (map.containsKey(k)) ordered[k] = map[k];
    }
    // Include any orphan keys that exist in target but not in en (rare).
    for (final k in map.keys) {
      if (!ordered.containsKey(k) && k != '@@locale') {
        ordered[k] = map[k];
      }
    }

    final encoded = const JsonEncoder.withIndent('  ').convert(ordered);
    f.writeAsStringSync('$encoded\n');
    summary[loc] = added;
    stdout.writeln(
        '$loc: +$added missing keys mirrored from en (${ordered.length - 1} total keys)');
  }

  final total = summary.values.fold<int>(0, (a, b) => a + b);
  stdout.writeln('---');
  stdout.writeln('Total keys mirrored: $total across ${summary.length} locales');
}
