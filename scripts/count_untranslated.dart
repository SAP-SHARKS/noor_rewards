// Count how many keys in each non-EN .arb are exactly-equal to the EN value
// (i.e. still English placeholders that need translation) vs. genuinely
// localised.
//
// Usage: `dart run scripts/count_untranslated.dart`

import 'dart:convert';
import 'dart:io';

const _locales = ['ur', 'ar', 'fr', 'id', 'ms', 'ru', 'tr'];

void main() {
  final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;
  final enKeys = en.keys
      .where((k) => !k.startsWith('@') && k != '@@locale')
      .toList();

  stdout.writeln('EN total translatable keys: ${enKeys.length}');
  stdout.writeln('');
  stdout.writeln('Per-locale untranslated (value equals EN):');
  stdout.writeln('  locale | placeholder | translated | %translated');
  stdout.writeln('  -------+-------------+------------+------------');

  for (final loc in _locales) {
    final m = jsonDecode(File('lib/l10n/app_$loc.arb').readAsStringSync())
        as Map<String, dynamic>;
    var placeholder = 0;
    var translated = 0;
    for (final k in enKeys) {
      final ev = en[k];
      final lv = m[k];
      if (lv == null) continue;
      if (ev is String && lv is String && ev == lv) {
        placeholder++;
      } else {
        translated++;
      }
    }
    final total = placeholder + translated;
    final pct = total == 0 ? 0 : ((translated / total) * 100).round();
    stdout.writeln(
      '  ${loc.padRight(6)} | ${placeholder.toString().padLeft(11)} | '
      '${translated.toString().padLeft(10)} | $pct%',
    );
  }
}
