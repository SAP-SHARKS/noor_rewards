// Reports keys in app_en.arb where a `<key>` and `<key>_<hash6>` both
// exist with byte-identical English values. Also reports which variant
// (if any) is actually referenced by code, so we can drop the dead one.
import 'dart:convert';
import 'dart:io';

void main() async {
  final arb = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;
  final messageKeys = arb.entries
      .where((e) => !e.key.startsWith('@') && e.value is String)
      .map((e) => MapEntry(e.key, e.value as String))
      .toList();

  final hashRe = RegExp(r'^(.+)_[a-f0-9]{6}$');
  final byBase = <String, List<MapEntry<String, String>>>{};
  for (final e in messageKeys) {
    final m = hashRe.firstMatch(e.key);
    final base = m != null ? m.group(1)! : e.key;
    byBase.putIfAbsent(base, () => []).add(e);
  }

  // Scan all screen/widget dart files for `.<key>` occurrences.
  final dartFiles = <File>[];
  for (final d in ['lib/screens', 'lib/widgets', 'lib/services']) {
    final dir = Directory(d);
    if (!dir.existsSync()) continue;
    dartFiles.addAll(dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart')));
  }
  final code = dartFiles
      .map((f) => f.readAsStringSync())
      .join('\n');

  bool isUsed(String key) => RegExp(r'\.' + RegExp.escape(key) + r'\b').hasMatch(code);

  int identical = 0;
  int dropCleanCount = 0;
  int dropHashCount = 0;
  final dropClean = <String>[];
  final dropHash = <String>[];
  final conflict = <String>[];
  for (final entry in byBase.entries) {
    if (entry.value.length < 2) continue;
    // Find the clean base key (no hash suffix) if present.
    final clean = entry.value.firstWhere(
      (e) => !hashRe.hasMatch(e.key),
      orElse: () => const MapEntry('', ''),
    );
    final hashed = entry.value.where((e) => hashRe.hasMatch(e.key)).toList();
    if (clean.key.isEmpty || hashed.isEmpty) continue;
    // Compare values.
    for (final h in hashed) {
      if (h.value == clean.value) {
        identical++;
        final cleanUsed = isUsed(clean.key);
        final hashUsed = isUsed(h.key);
        if (hashUsed && !cleanUsed) {
          dropClean.add(clean.key);
          dropCleanCount++;
        } else if (cleanUsed && !hashUsed) {
          dropHash.add(h.key);
          dropHashCount++;
        } else if (!cleanUsed && !hashUsed) {
          // Neither used → drop both eventually, but for now flag.
          conflict.add('${clean.key} & ${h.key}: both dead');
        } else {
          conflict.add('${clean.key} & ${h.key}: both used');
        }
      }
    }
  }

  print('Total identical dup pairs: $identical');
  print('Safe to drop the CLEAN variant of $dropCleanCount pairs.');
  print('Safe to drop the HASH  variant of $dropHashCount pairs.');
  print('Needs manual review:      ${conflict.length} pairs.');
  print('');
  print('=== dropClean (keep hash-suffixed, drop clean) ===');
  for (final k in dropClean) print(k);
  print('');
  print('=== dropHash (keep clean, drop hash-suffixed) ===');
  for (final k in dropHash) print(k);
  print('');
  print('=== conflict (manual) ===');
  for (final c in conflict) print(c);
}
