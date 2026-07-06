// UI translation batch generator.
//
// Reads lib/l10n/app_en.arb, drops @metadata entries, and splits the
// remaining ~2500 translatable keys into ~150-key batches. For each
// batch it writes:
//
//   build/ui_translation_batches/batch_NN_prompt.md
//     Copy-paste this whole file into a fresh Claude Sonnet chat.
//     The LLM returns 7 fenced JSON blocks, one per target locale.
//     Save that response verbatim as batch_NN_output.md next to the
//     prompt file.
//
//   build/ui_translation_batches/batch_NN_source.json
//     The raw {key: EN_value} slice for that batch. Useful for
//     manual spot-checks and for the merger script.
//
//   build/ui_translation_batches/README.md
//     Step-by-step workflow.
//
// Usage:
//   dart run scripts/generate_ui_translation_batches.dart

import 'dart:convert';
import 'dart:io';

const _arbPath = 'lib/l10n/app_en.arb';
const _outDir = 'build/ui_translation_batches';
const _batchSize = 150;
const _targetLocales = [
  ('ur', 'Urdu (Perso-Arabic script)'),
  ('ar', 'Arabic (Naskh script — MSA)'),
  ('fr', 'French'),
  ('id', 'Bahasa Indonesia'),
  ('ms', 'Bahasa Melayu'),
  ('ru', 'Russian (Cyrillic)'),
  ('tr', 'Turkish'),
];

void main() {
  final arb = jsonDecode(File(_arbPath).readAsStringSync()) as Map<String, dynamic>;

  // Keep only actual message keys: string values whose key doesn't start
  // with '@'. `@@locale` is the file-level tag; `@keyName` blocks hold
  // placeholder metadata for ICU strings — both must be excluded from the
  // translation payload (but preserved in the .arb file itself during the
  // later merge step).
  final entries = <MapEntry<String, String>>[];
  for (final e in arb.entries) {
    if (e.key.startsWith('@')) continue;
    final v = e.value;
    if (v is! String) continue;
    entries.add(MapEntry(e.key, v));
  }
  entries.sort((a, b) => a.key.compareTo(b.key));
  print('${entries.length} translatable keys.');

  final outDir = Directory(_outDir);
  if (outDir.existsSync()) outDir.deleteSync(recursive: true);
  outDir.createSync(recursive: true);
  Directory('$_outDir/output').createSync();

  final batchCount = (entries.length / _batchSize).ceil();
  for (var b = 0; b < batchCount; b++) {
    final start = b * _batchSize;
    final end = (start + _batchSize).clamp(0, entries.length);
    final slice = entries.sublist(start, end);
    final num = (b + 1).toString().padLeft(2, '0');
    _writeBatch(num, b + 1, batchCount, slice);
  }

  _writeReadme(batchCount);
  print('Wrote $batchCount batches into $_outDir/');
}

void _writeBatch(String num, int i, int total, List<MapEntry<String, String>> slice) {
  // Source JSON — flat {key: english_value}, sorted for stable diffs.
  final sourceJson = const JsonEncoder.withIndent('  ')
      .convert({for (final e in slice) e.key: e.value});
  File('$_outDir/batch_${num}_source.json').writeAsStringSync(sourceJson);

  // Prompt file — self-contained; user just pastes this whole thing.
  final buf = StringBuffer();
  buf.writeln('# UI translation batch $i of $total');
  buf.writeln();
  buf.writeln('Paste EVERYTHING below into Claude Sonnet 4 (or newer). Save the response verbatim as `batch_${num}_output.md` next to this file. Do not edit.');
  buf.writeln();
  buf.writeln('---');
  buf.writeln();
  buf.writeln('You are re-translating the mobile-app UI copy for **Sabiq Rewards**, an Islamic worship-tracking app (Quran reading, dhikr, streaks, donations, Seeds — an in-app worship currency).');
  buf.writeln();
  buf.writeln('## Task');
  buf.writeln();
  buf.writeln('Translate the ${slice.length} English strings in the JSON block below into these 7 target locales:');
  buf.writeln();
  for (final (code, name) in _targetLocales) {
    buf.writeln('- `$code` — $name');
  }
  buf.writeln();
  buf.writeln('## Absolute rules (deviations break the app)');
  buf.writeln();
  buf.writeln('1. **Preserve every `{placeholder}` token verbatim.** e.g. if the source is `Welcome, {name}!` your output must contain `{name}` byte-for-byte. Do NOT translate the token, do NOT rename it, do NOT drop the braces.');
  buf.writeln();
  buf.writeln('2. **Preserve ICU plural / select structures byte-for-byte.** e.g. `{count, plural, =1{1 day} other{{count} days}}` — the words `plural`, `select`, `=0`, `=1`, `=2`, `other`, `few`, `many`, `zero` are ICU keywords, NOT English. Translate only the human-readable strings inside the `{…}` branches. Every locale needs `other{…}`; other plural forms are optional but keep them if you produce them.');
  buf.writeln();
  buf.writeln('3. **Keep it UI-short.** Roughly match the English length (mobile widgets have tight width). Aim ≤ 1.3× the character count of the English. Prefer natural short form over literal-verbose.');
  buf.writeln();
  buf.writeln('4. **Do not translate:**');
  buf.writeln('   - Product/brand: `Sabiq Rewards`, `Sabiq Seeds`, `Seeds`, `Sabiq`, `Google`, `Quran.com`');
  buf.writeln('   - Islamic terms with settled per-locale spelling — use the locale-native form. E.g.:');
  buf.writeln('     - "Quran" → قرآن (ar/ur), Kur\'an (tr), Al-Quran (id/ms), Coran (fr), Коран (ru)');
  buf.writeln('     - "dhikr" → ذكر (ar), ذکر (ur), zikir (id), zikr (ms), zikir (tr), dhikr (fr), зикр (ru)');
  buf.writeln('     - "SubhanAllah", "Alhamdulillah", "Astaghfirullah", "Bismillah" → Arabic script for ar/ur, transliterated everywhere else');
  buf.writeln('     - Prophet ﷺ / Nabi / Peygamber — canonical local form');
  buf.writeln();
  buf.writeln('5. **Register:** concise mobile-app copy, friendly-but-not-cutesy. Second-person address ("you"/"your"). For ur/ar prefer respectful-neutral form (آپ / أنت, not intimate تو / أنتي).');
  buf.writeln();
  buf.writeln('6. **Do not add commentary, brackets, or footnotes.** Do not translate one key across two rows. Do not merge or split keys.');
  buf.writeln();
  buf.writeln('## Output format');
  buf.writeln();
  buf.writeln('Return exactly 7 fenced JSON blocks in this order (`ur`, `ar`, `fr`, `id`, `ms`, `ru`, `tr`). Each block is a flat `{key: translation}` object with the SAME keys as the source below, one translation per key. No preamble, no closing text, no comments — just the 7 fences back-to-back.');
  buf.writeln();
  buf.writeln('Template:');
  buf.writeln();
  buf.writeln('~~~ur');
  buf.writeln('{');
  buf.writeln('  "someKey": "…اردو ترجمہ…",');
  buf.writeln('  "otherKey": "…"');
  buf.writeln('}');
  buf.writeln('~~~');
  buf.writeln('~~~ar');
  buf.writeln('{');
  buf.writeln('  "someKey": "…الترجمة…",');
  buf.writeln('  "otherKey": "…"');
  buf.writeln('}');
  buf.writeln('~~~');
  buf.writeln('… (and so on for fr, id, ms, ru, tr)');
  buf.writeln();
  buf.writeln('If your response is going to be truncated, output as many complete locale blocks as fit and then on the very last line write:');
  buf.writeln();
  buf.writeln('    >>> CONTINUE FROM locale=<code> key=<lastKey>');
  buf.writeln();
  buf.writeln('so a follow-up chat can resume.');
  buf.writeln();
  buf.writeln('## Source strings ($num of $total, ${slice.length} keys)');
  buf.writeln();
  buf.writeln('```json');
  buf.write(const JsonEncoder.withIndent('  ')
      .convert({for (final e in slice) e.key: e.value}));
  buf.writeln();
  buf.writeln('```');

  File('$_outDir/batch_${num}_prompt.md').writeAsStringSync(buf.toString());
}

void _writeReadme(int total) {
  final buf = StringBuffer();
  buf.writeln('# UI translation batches');
  buf.writeln();
  buf.writeln('Regenerating `.arb` translations for the app with an LLM (Claude Sonnet 4 recommended) instead of Google Translate. This gives you human-review-quality UI copy across all 7 non-EN locales.');
  buf.writeln();
  buf.writeln('## Workflow');
  buf.writeln();
  buf.writeln('1. Open `batch_01_prompt.md`. Copy the WHOLE file.');
  buf.writeln('2. Paste into a fresh Claude Sonnet chat. Wait for the response.');
  buf.writeln('3. Save the LLM\'s response verbatim as `output/batch_01_output.md`.');
  buf.writeln('4. Repeat for batches 02 through ${total.toString().padLeft(2, '0')}. Fresh chat per batch keeps context clean.');
  buf.writeln('5. When all $total outputs are saved, run:');
  buf.writeln();
  buf.writeln('   ```');
  buf.writeln('   dart run scripts/merge_ui_translation_batches.dart');
  buf.writeln('   ```');
  buf.writeln();
  buf.writeln('   This validates (placeholders + ICU intact, no missing keys), merges into all 7 non-EN .arb files, and regenerates the l10n Dart bindings.');
  buf.writeln();
  buf.writeln('6. Run `flutter analyze` and open the app on Urdu → confirm the strings render natively.');
  buf.writeln();
  buf.writeln('## If a batch\'s output is truncated');
  buf.writeln();
  buf.writeln('The prompt asks the LLM to output `>>> CONTINUE FROM locale=X key=Y` at the end if it hit its cap. If you see that:');
  buf.writeln();
  buf.writeln('1. Copy the prompt into a fresh chat.');
  buf.writeln('2. Append: `Resume from locale=X key=Y — output only the remaining locales and keys, in the same fenced-block format.`');
  buf.writeln('3. Concatenate the second response after the first in `batch_NN_output.md`.');
  buf.writeln();
  buf.writeln('## Notes');
  buf.writeln();
  buf.writeln('- Every batch is self-contained — one chat per batch.');
  buf.writeln('- The merger overwrites current Google-translated values wholesale. If you want to keep any hand-corrected entry, extract it before running the merge (or restore from git after).');
  buf.writeln('- `batch_NN_source.json` files are the raw EN slices — safe to spot-check the LLM against.');
  buf.writeln('- All output files are gitignored — check them in only if you want the paste history archived.');
  buf.writeln();
  File('$_outDir/README.md').writeAsStringSync(buf.toString());
}
