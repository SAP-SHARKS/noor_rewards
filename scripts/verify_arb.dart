import 'dart:convert';
import 'dart:io';

void main() {
  final locales = ['en', 'ur', 'ar', 'fr', 'id', 'ms', 'ru', 'tr'];
  final counts = <String, int>{};
  for (final loc in locales) {
    try {
      final m = jsonDecode(File('lib/l10n/app_$loc.arb').readAsStringSync())
          as Map<String, dynamic>;
      final nonMetaKeys =
          m.keys.where((k) => !k.startsWith('@') && k != '@@locale').length;
      counts[loc] = nonMetaKeys;
      stdout.writeln('$loc: OK ($nonMetaKeys translatable keys, ${m.length} total)');
    } catch (e) {
      stdout.writeln('$loc: FAIL — $e');
    }
  }
  // Parity check
  final ref = counts['en'] ?? -1;
  stdout.writeln('---');
  for (final loc in locales) {
    if (loc == 'en') continue;
    final c = counts[loc] ?? -1;
    final delta = ref - c;
    stdout.writeln('$loc parity with en: ${delta == 0 ? "OK" : "$delta missing"}');
  }
}
