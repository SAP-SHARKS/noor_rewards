// Tagline translation batch generator.
//
// Reads the `_pickTagline` function body inside
// `lib/screens/dhikr_screen.dart`, extracts every English tagline
// string literal, dedupes, and splits into ~150-key Gemini prompts.
//
// Writes:
//   build/tagline_batches/index.json           — synthetic-key -> EN string
//   build/tagline_batches/batch_NN_source.json — {t0001: "…"} for the batch
//   build/tagline_batches/batch_NN_prompt.md   — self-contained Gemini prompt
//   build/tagline_batches/README.md            — workflow notes
//
// Usage:
//   dart run scripts/generate_tagline_batches.dart

import 'dart:convert';
import 'dart:io';

const _sourcePath = 'lib/screens/dhikr_screen.dart';
const _outDir = 'build/tagline_batches';
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
  final source = File(_sourcePath).readAsStringSync();
  final start = source.indexOf('String _pickTagline(String id)');
  if (start < 0) {
    stderr.writeln('_pickTagline not found in $_sourcePath');
    exit(1);
  }
  var depth = 0;
  var end = -1;
  var seenOpen = false;
  for (var i = start; i < source.length; i++) {
    final c = source[i];
    if (c == '{') {
      depth++;
      seenOpen = true;
    } else if (c == '}') {
      depth--;
      if (seenOpen && depth == 0) {
        end = i;
        break;
      }
    }
  }
  if (end < 0) {
    stderr.writeln('Could not find end of _pickTagline body.');
    exit(1);
  }
  final body = source.substring(start, end + 1);

  // Match value strings preceded by `:`, `=>`, or `return`. Handles
  // both single- and double-quoted Dart literals with `\'` and `\"`
  // escapes inside.
  final rhsRe = RegExp(
    "(?::|=>|\\breturn)\\s*(?:'((?:\\\\.|[^'\\\\])*)'|\"((?:\\\\.|[^\"\\\\])*)\")",
    multiLine: true,
  );

  final ordered = <String>[];
  final seen = <String>{};
  for (final m in rhsRe.allMatches(body)) {
    final raw = m.group(1) ?? m.group(2) ?? '';
    if (raw.trim().isEmpty) continue;
    final unescaped = _unescape(raw);
    // Illustration-switch KEYS are single-word identifiers on the LHS;
    // values always contain a space. Defensive skip in case regex
    // ever grabs a bare identifier by accident.
    if (!unescaped.contains(' ') && unescaped.length < 6) continue;
    if (seen.add(unescaped)) ordered.add(unescaped);
  }

  print('Extracted ${ordered.length} unique taglines.');

  final outDir = Directory(_outDir);
  if (outDir.existsSync()) outDir.deleteSync(recursive: true);
  outDir.createSync(recursive: true);
  Directory('$_outDir/output').createSync();

  final index = <String, String>{};
  for (var i = 0; i < ordered.length; i++) {
    final key = 't${(i + 1).toString().padLeft(4, '0')}';
    index[key] = ordered[i];
  }
  File('$_outDir/index.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(index),
  );

  final entries = index.entries.toList();
  final batchCount = (entries.length / _batchSize).ceil();
  for (var b = 0; b < batchCount; b++) {
    final s = b * _batchSize;
    final e = (s + _batchSize).clamp(0, entries.length);
    _writeBatch((b + 1), batchCount, entries.sublist(s, e));
  }
  _writeReadme(batchCount);
  print('Wrote $batchCount batches into $_outDir/');
}

String _unescape(String s) {
  return s
      .replaceAll("\\'", "'")
      .replaceAll('\\"', '"')
      .replaceAll('\\n', '\n');
}

void _writeBatch(int i, int total, List<MapEntry<String, String>> slice) {
  final num = i.toString().padLeft(2, '0');
  final sourceJson = const JsonEncoder.withIndent('  ')
      .convert({for (final e in slice) e.key: e.value});
  File('$_outDir/batch_${num}_source.json').writeAsStringSync(sourceJson);

  final buf = StringBuffer();
  buf.writeln('# Dhikr tagline translation batch $i of $total');
  buf.writeln();
  buf.writeln('Paste EVERYTHING below into a fresh Gemini chat. Save the response as `output/batch_${num}_output.md` next to this file.');
  buf.writeln();
  buf.writeln('---');
  buf.writeln();
  buf.writeln('You are translating the **motivational tagline** shown under each dhikr illustration in **Sabiq Rewards**, an Islamic worship-tracking app. Each string is a one-line hook that summarises the reward, virtue, or benefit of a specific dua/dhikr as recorded in the Qur\'an, hadith, or classical works (Hisnul Muslim, Riyad us-Saliheen, etc.).');
  buf.writeln();
  buf.writeln('## Task');
  buf.writeln();
  buf.writeln('Translate the ${slice.length} English taglines below into these 7 target locales:');
  buf.writeln();
  for (final (code, name) in _targetLocales) {
    buf.writeln('- `$code` — $name');
  }
  buf.writeln();
  buf.writeln('## Absolute rules');
  buf.writeln();
  buf.writeln('1. **Keep it UI-short.** These sit inside a pill under an illustration — hard cap around 1.3× the English character count. Prefer natural short form.');
  buf.writeln();
  buf.writeln('2. **Preserve honorifics and proper nouns:**');
  buf.writeln('   - `ﷺ` after Prophet Muhammad — keep as-is in every locale.');
  buf.writeln('   - Prophet names: Ibrahim → إبراهيم (ar/ur), İbrahim (tr), Ibrahim (fr/id/ms), Ибрахим (ru).');
  buf.writeln('   - Musa, Isa, Sulayman, Yunus, Adam, Ismail, Ishaq, Harun → canonical local form.');
  buf.writeln('   - Islamic terms with settled per-locale spelling: Qur\'an, Jannah, Firdaws, Hajj, Umrah, Kaaba, Fatihah, Ikhlas, Falaq, Nas, Baqarah, Ayat al-Kursi, Sayyid al-Istighfar, salawat, dhikr, tasbeeh, istighfar, wudu, fitrah, ruqya, dua, sadaqah, shirk, tawheed, tawakkul, fitnah, Shaytan.');
  buf.writeln();
  buf.writeln('3. **Register:** short, warm, motivating — same feel as English source. No preamble like "The reward of…" if English doesn\'t have it.');
  buf.writeln();
  buf.writeln('4. **Do not translate:** `Sabiq Rewards`, `Sabiq Seeds`, `Seeds`.');
  buf.writeln();
  buf.writeln('5. **Do not add commentary, brackets, footnotes, or asterisks.** Output ONLY the translation strings.');
  buf.writeln();
  buf.writeln('## Output format');
  buf.writeln();
  buf.writeln('Return **ONE single JSON object** inside **ONE** fenced code block. Top-level keys are the locale codes `ur`, `ar`, `fr`, `id`, `ms`, `ru`, `tr` in that order. Each value is a flat `{key: translation}` map with the SAME synthetic keys as the source below.');
  buf.writeln();
  buf.writeln('```json');
  buf.writeln('{');
  buf.writeln('  "ur": { "t0001": "…", "t0002": "…" },');
  buf.writeln('  "ar": { "t0001": "…", "t0002": "…" },');
  buf.writeln('  "fr": { … },');
  buf.writeln('  "id": { … },');
  buf.writeln('  "ms": { … },');
  buf.writeln('  "ru": { … },');
  buf.writeln('  "tr": { … }');
  buf.writeln('}');
  buf.writeln('```');
  buf.writeln();
  buf.writeln('No preamble, no closing text — just the one fenced JSON block.');
  buf.writeln();
  buf.writeln('If the response would exceed your output cap, cut off cleanly at a key boundary and append ONE line after the closing fence:');
  buf.writeln();
  buf.writeln('    >>> CONTINUE FROM locale=<code> key=<lastKey>');
  buf.writeln();
  buf.writeln('## Source strings ($num of ${total.toString().padLeft(2, '0')}, ${slice.length} keys)');
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
  buf.writeln('# Dhikr tagline translation batches');
  buf.writeln();
  buf.writeln('Per-dhikr motivational tagline (the pill under each illustration) — LLM-translated across 7 non-EN locales. Source lives inside `_pickTagline()` in `lib/screens/dhikr_screen.dart`.');
  buf.writeln();
  buf.writeln('## Workflow');
  buf.writeln();
  buf.writeln('1. Open `batch_01_prompt.md`. Copy the WHOLE file into a fresh Gemini chat.');
  buf.writeln('2. Save Gemini\'s response verbatim as `output/batch_01_output.md` (or `.json` — merger accepts either).');
  buf.writeln('3. Repeat for batches 02 through ${total.toString().padLeft(2, '0')}. One fresh chat per batch.');
  buf.writeln('4. When all $total outputs are saved, run:');
  buf.writeln();
  buf.writeln('   ```');
  buf.writeln('   dart run scripts/merge_tagline_batches.dart');
  buf.writeln('   ```');
  buf.writeln();
  buf.writeln('   This writes `lib/data/tagline_translations.dart` — a locale -> synthetic-key -> translation map.');
  buf.writeln();
  buf.writeln('5. Wire the map into `_pickTagline` so it consults the current locale and falls back to English.');
  File('$_outDir/README.md').writeAsStringSync(buf.toString());
}
