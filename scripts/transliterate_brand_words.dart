// One-shot transliteration script for the brand words `Seeds` and
// `Sabiq` across the 3 non-Latin-script .arb files (ur, ar, ru).
//
// Why: leaving Latin "Seeds" inside an Urdu/Arabic/Russian sentence
// forces a mid-line script switch that hurts readability. Standard
// mobile-app practice is to transliterate the brand into the local
// script (like YouTube → یوٹیوب on Urdu Google Play) so it flows
// naturally while preserving brand identity.
//
// Preserved: the compound "Sabiq Rewards" (the app's store-listed
// name) stays Latin in every locale. All other standalone occurrences
// of Sabiq / Seeds / Seed are transliterated.
//
// Substitution table:
//   Locale   Seed(s)      Sabiq
//   ur       سیڈز / سیڈ    سابق
//   ar       سيدز / سيد    سابق
//   ru       Сидс / Сид    Сабик
//
// Idempotent — running twice is a no-op because the second pass
// doesn't find the Latin tokens anymore.
//
// Usage:
//   dart run scripts/transliterate_brand_words.dart

import 'dart:convert';
import 'dart:io';

const _arbDir = 'lib/l10n';

const _substitutions = <String, Map<String, String>>{
  'ur': {
    'Seeds': 'سیڈز',
    'Seed': 'سیڈ',
    'Sabiq': 'سابق',
  },
  'ar': {
    'Seeds': 'سيدز',
    'Seed': 'سيد',
    'Sabiq': 'سابق',
  },
  'ru': {
    'Seeds': 'Сидс',
    'Seed': 'Сид',
    'Sabiq': 'Сабик',
  },
};

const _appName = 'Sabiq Rewards';
// Sentinel used to preserve the app name across word-boundary regex
// replacements. Chosen to be a string that will never appear anywhere
// in .arb payloads.
const _appNameSentinel = 'APPNAME';

void main() {
  for (final locale in _substitutions.keys) {
    final path = '$_arbDir/app_$locale.arb';
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('Missing $path — skipping.');
      continue;
    }
    final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final subs = _substitutions[locale]!;

    var replacements = 0;
    arb.updateAll((key, value) {
      if (key.startsWith('@')) return value;
      if (value is! String) return value;

      var out = value;

      // Sentinel-protect the app name so per-word substitutions
      // don't rewrite "Sabiq Rewards" into "سابق Rewards".
      out = out.replaceAll(_appName, _appNameSentinel);

      // Word-boundary matches only. Order matters: longer first
      // (Seeds before Seed) so "Seeds" doesn't get partially
      // replaced twice.
      for (final entry in _orderedEntries(subs)) {
        final before = out;
        // Negative lookbehind/lookahead: skip when the token is
        // enclosed in `{…}` — that is a Flutter/ICU placeholder name
        // and rewriting it breaks the binding to the declared arg.
        out = out.replaceAll(
          RegExp(
            r'(?<!\{)\b' + RegExp.escape(entry.key) + r'\b(?!\})',
            caseSensitive: false,
          ),
          entry.value,
        );
        if (out != before) replacements++;
      }

      out = out.replaceAll(_appNameSentinel, _appName);
      return out;
    });

    File(path).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(arb)}\n',
    );
    print('$locale: $replacements strings touched.');
  }
}

List<MapEntry<String, String>> _orderedEntries(Map<String, String> m) {
  final list = m.entries.toList();
  // Longer keys first so `Seeds` matches before `Seed`.
  list.sort((a, b) => b.key.length.compareTo(a.key.length));
  return list;
}
