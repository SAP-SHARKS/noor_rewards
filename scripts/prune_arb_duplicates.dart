// Removes dead duplicate keys from every app_XX.arb file, then fixes two
// source-string bugs in en.arb:
//   1. `akhirahBalanceScreen_astaghfirullahTheProphetSaid_7625ff` has ✍
//      (writing-hand emoji) instead of ﷺ (peace-be-upon-him ligature).
//   2. `authScreen_haveAnAccountSign` = "t have an account? Sign Up" —
//      a truncated typo; the clean sibling `authScreen_dontHaveAnAccountSignUp`
//      has the correct text. Dropping the broken sibling.
//
// The "dead duplicate" set is discovered by scripts/audit_arb_duplicates.dart:
//   - clean-and-hash pair, clean unused, hash used → drop clean (190)
//   - clean-and-hash pair, hash  unused, clean used → drop hash  (1)
//   - both variants unused anywhere in lib/screens|widgets|services → drop both (1018)
//
// This script recomputes those sets from scratch so it stays in sync as
// screens change; the audit is just for reporting.
import 'dart:convert';
import 'dart:io';

const _arbDir = 'lib/l10n';
const _locales = ['en', 'ur', 'ar', 'fr', 'id', 'ms', 'ru', 'tr'];

void main() {
  // ── 1. Discover dead keys from en.arb + code scan ───────────────────
  final en = jsonDecode(File('$_arbDir/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;
  final hashRe = RegExp(r'^(.+)_[a-f0-9]{6}$');

  final messageKeys = en.entries
      .where((e) => !e.key.startsWith('@') && e.value is String)
      .map((e) => MapEntry(e.key, e.value as String))
      .toList();

  final byBase = <String, List<MapEntry<String, String>>>{};
  for (final e in messageKeys) {
    final m = hashRe.firstMatch(e.key);
    final base = m != null ? m.group(1)! : e.key;
    byBase.putIfAbsent(base, () => []).add(e);
  }

  final dartFiles = <File>[];
  for (final d in ['lib/screens', 'lib/widgets', 'lib/services']) {
    final dir = Directory(d);
    if (!dir.existsSync()) continue;
    dartFiles.addAll(dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart')));
  }
  final code = dartFiles.map((f) => f.readAsStringSync()).join('\n');
  final usedRe = <String, bool>{};
  bool isUsed(String key) => usedRe.putIfAbsent(
      key, () => RegExp(r'\.' + RegExp.escape(key) + r'\b').hasMatch(code));

  final toDrop = <String>{};
  for (final entry in byBase.entries) {
    if (entry.value.length < 2) continue;
    final clean = entry.value.firstWhere(
      (e) => !hashRe.hasMatch(e.key),
      orElse: () => const MapEntry('', ''),
    );
    final hashed = entry.value.where((e) => hashRe.hasMatch(e.key)).toList();
    if (clean.key.isEmpty || hashed.isEmpty) continue;
    for (final h in hashed) {
      if (h.value != clean.value) continue;
      final cleanUsed = isUsed(clean.key);
      final hashUsed = isUsed(h.key);
      if (hashUsed && !cleanUsed) toDrop.add(clean.key);
      else if (cleanUsed && !hashUsed) toDrop.add(h.key);
      else if (!cleanUsed && !hashUsed) {
        toDrop..add(clean.key)..add(h.key);
      }
    }
  }

  // Also drop the truncated typo key.
  toDrop.add('authScreen_haveAnAccountSign');

  print('Will drop ${toDrop.length} keys from every .arb.');

  // ── 2. Apply pruning across every locale ────────────────────────────
  for (final loc in _locales) {
    final path = '$_arbDir/app_$loc.arb';
    final f = File(path);
    if (!f.existsSync()) continue;
    final arb = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;

    var removed = 0;
    for (final key in toDrop) {
      if (arb.remove(key) != null) removed++;
      if (arb.remove('@$key') != null) removed++;
    }

    // Fix the ✍ → ﷺ typo in the surviving hash-suffixed key.
    const emojiKey = 'akhirahBalanceScreen_astaghfirullahTheProphetSaid_7625ff';
    if (arb[emojiKey] is String) {
      arb[emojiKey] = (arb[emojiKey] as String).replaceAll('✍', 'ﷺ');
    }

    File(path).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(arb)}\n',
    );
    print('  $loc: removed $removed entries.');
  }
  print('');
  print('Next: dart run scripts/generate_ui_translation_batches.dart');
  print('      flutter gen-l10n');
}
