// Azkar translation batch generator.
//
// Reads build/azkar_translation.csv (id, category_id, arabic, translation),
// splits into ~120-row Gemini batches, and emits self-contained prompts
// that ask Gemini to translate each dhikr's English rendering into 7
// non-EN locales — grounded, where possible, in the canonical Hisnul
// Muslim / Fortress of the Muslim edition for that language.
//
// Writes:
//   build/azkar_translation_batches/index.json        — id -> {arabic, en}
//   build/azkar_translation_batches/batch_NN_source.json
//   build/azkar_translation_batches/batch_NN_prompt.md
//   build/azkar_translation_batches/output/            — drop LLM outputs here
//   build/azkar_translation_batches/README.md
//
// Usage:
//   dart run scripts/generate_azkar_translation_batches.dart

import 'dart:convert';
import 'dart:io';

const _csvPath = 'build/azkar_translation.csv';
const _outDir = 'build/azkar_translation_batches';
const _batchSize = 120;

const _targetLocales = [
  ('ur', 'Urdu (Perso-Arabic script)'),
  ('ar', 'Arabic (Naskh script — MSA)'),
  ('fr', 'French'),
  ('id', 'Bahasa Indonesia'),
  ('ms', 'Bahasa Melayu'),
  ('ru', 'Russian (Cyrillic)'),
  ('tr', 'Turkish'),
];

class _Row {
  final String id;
  final String categoryId;
  final String arabic;
  final String en;
  _Row(this.id, this.categoryId, this.arabic, this.en);
}

void main() {
  final rows = _parseCsv(File(_csvPath).readAsStringSync());
  print('Loaded ${rows.length} azkar rows.');

  final outDir = Directory(_outDir);
  if (outDir.existsSync()) outDir.deleteSync(recursive: true);
  outDir.createSync(recursive: true);
  Directory('$_outDir/output').createSync();

  final index = <String, Map<String, String>>{
    for (final r in rows) r.id: {'arabic': r.arabic, 'en': r.en, 'category': r.categoryId},
  };
  File('$_outDir/index.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(index),
  );

  final batchCount = (rows.length / _batchSize).ceil();
  for (var b = 0; b < batchCount; b++) {
    final s = b * _batchSize;
    final e = (s + _batchSize).clamp(0, rows.length);
    _writeBatch((b + 1), batchCount, rows.sublist(s, e));
  }
  _writeReadme(batchCount);
  print('Wrote $batchCount batches into $_outDir/');
}

void _writeBatch(int i, int total, List<_Row> slice) {
  final num = i.toString().padLeft(2, '0');
  final source = <String, Map<String, String>>{
    for (final r in slice) r.id: {'arabic': r.arabic, 'en': r.en},
  };
  File('$_outDir/batch_${num}_source.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(source),
  );

  final buf = StringBuffer();
  buf.writeln('# Azkar translation batch $i of $total');
  buf.writeln();
  buf.writeln('Paste EVERYTHING below into a fresh Gemini chat. Save the response as `output/batch_${num}_output.md` next to this file.');
  buf.writeln();
  buf.writeln('---');
  buf.writeln();
  buf.writeln('You are translating **English renderings of Qur\'anic and Prophetic supplications (adhkar)** for **Sabiq Rewards**, an Islamic worship-tracking app. Each entry pairs the Arabic source with its established English rendering — you must translate the ENGLISH rendering into 7 target locales.');
  buf.writeln();
  buf.writeln('## Task');
  buf.writeln();
  buf.writeln('For each of the ${slice.length} entries below, produce a rendering in each of these 7 locales:');
  buf.writeln();
  for (final (code, name) in _targetLocales) {
    buf.writeln('- `$code` — $name');
  }
  buf.writeln();
  buf.writeln('## Source of truth');
  buf.writeln();
  buf.writeln('Wherever possible, use the **canonical rendering as it appears in the published edition of Hisnul Muslim / Fortress of the Muslim (Sa\'id ibn Ali ibn Wahf al-Qahtani)** in the target language — this is the authoritative reference used by scholars and mosques worldwide. Where a canonical Fortress of the Muslim rendering does not exist for a particular dhikr, use:');
  buf.writeln();
  buf.writeln('  1. The rendering used by **Sunnah.com** for that hadith reference');
  buf.writeln('  2. The rendering in **Riyad us-Saliheen** in that language');
  buf.writeln('  3. A faithful literal translation grounded strictly in the Arabic source shown, with theological terminology matching the target language\'s scholarly convention');
  buf.writeln();
  buf.writeln('**Never paraphrase, dramatize, or add.** The translation must be safe to display next to the Arabic text on a mobile screen.');
  buf.writeln();
  buf.writeln('## Absolute rules');
  buf.writeln();
  buf.writeln('1. **The Arabic text is the source of truth.** Cross-check every translation against the Arabic — if the English rendering has drifted, translate the Arabic, not the English.');
  buf.writeln();
  buf.writeln('2. **Preserve honorifics:** ﷺ (peace be upon him) stays as ﷺ in every locale. Do not expand or replace.');
  buf.writeln();
  buf.writeln('3. **Divine names and Islamic terms — use the target-language convention:**');
  buf.writeln('   - "Allah" → Allah (all locales; do not translate as "God" in fr/ru — "Allah" is standard in Islamic literature in every language).');
  buf.writeln('   - "Lord" (as in "O Lord") → the target language\'s canonical honorific for Allah as Lord (e.g. Rab, Rabb, Seigneur, Tuhan, Господь, Rabbimiz).');
  buf.writeln('   - Prophet names (Ibrahim, Musa, Isa, Sulayman, Yunus, Adam, Ismail, Ishaq, Harun, Yusuf) → the canonical local form as used in Qur\'an translations for that language.');
  buf.writeln();
  buf.writeln('4. **Register:** faithful, dignified, worship-appropriate. Second-person address to Allah where the Arabic uses second-person (yaa Rabb / يا رب → target-language equivalent). Never colloquial.');
  buf.writeln();
  buf.writeln('5. **Do not translate:** brand `Sabiq`, product `Sabiq Seeds`.');
  buf.writeln();
  buf.writeln('6. **Do not add commentary, brackets, footnotes, or explanations.** Output ONLY the translation string.');
  buf.writeln();
  buf.writeln('7. **Length:** roughly match the English character count. UI shows this next to the Arabic — long paraphrases break the layout.');
  buf.writeln();
  buf.writeln('## Output format');
  buf.writeln();
  buf.writeln('Return **ONE single JSON object** inside **ONE** fenced code block. Top-level keys are the locale codes `ur`, `ar`, `fr`, `id`, `ms`, `ru`, `tr` in that order. Each value is a flat `{id: translation}` map with the SAME dhikr ids as the source below.');
  buf.writeln();
  buf.writeln('```json');
  buf.writeln('{');
  buf.writeln('  "ur": { "alhamdulillah": "…", "allahu_akbar": "…", … },');
  buf.writeln('  "ar": { "alhamdulillah": "…", "allahu_akbar": "…", … },');
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
  buf.writeln('    >>> CONTINUE FROM locale=<code> id=<lastId>');
  buf.writeln();
  buf.writeln('## Source entries ($num of ${total.toString().padLeft(2, '0')}, ${slice.length} rows)');
  buf.writeln();
  buf.writeln('Each entry has `arabic` (the source text — authoritative) and `en` (the current English rendering — cross-reference).');
  buf.writeln();
  buf.writeln('```json');
  buf.write(const JsonEncoder.withIndent('  ').convert({
    for (final r in slice) r.id: {'arabic': r.arabic, 'en': r.en},
  }));
  buf.writeln();
  buf.writeln('```');

  File('$_outDir/batch_${num}_prompt.md').writeAsStringSync(buf.toString());
}

void _writeReadme(int total) {
  final buf = StringBuffer()
    ..writeln('# Azkar translation batches')
    ..writeln()
    ..writeln('Per-dhikr English translation → 7 non-EN locales, grounded in Hisnul Muslim / Fortress of the Muslim wording per locale.')
    ..writeln()
    ..writeln('## Workflow')
    ..writeln()
    ..writeln('1. Open `batch_01_prompt.md`. Copy the WHOLE file into a fresh Gemini chat.')
    ..writeln('2. Save Gemini\'s response verbatim as `output/batch_01_output.md` (or `.json` — merger accepts either).')
    ..writeln('3. Repeat for batches 02 through ${total.toString().padLeft(2, '0')}. One fresh chat per batch.')
    ..writeln('4. When all $total outputs are saved, run:')
    ..writeln()
    ..writeln('   ```')
    ..writeln('   dart run scripts/merge_azkar_translation_batches.dart')
    ..writeln('   ```')
    ..writeln()
    ..writeln('   Emits two Supabase migrations:')
    ..writeln('   - `<date>_010_azkar_translation_add_cols.sql` — ALTER TABLE + populate ur, ar')
    ..writeln('   - `<date>_020_azkar_translation_fr_id_ms_ru_tr.sql` — populate remaining 5 locales')
    ..writeln()
    ..writeln('5. Apply both migrations in Supabase (SQL Editor or `supabase db push`).')
    ..writeln()
    ..writeln('The runtime `_Azkar.fromJson` already uses `pick(\'translation\')`, so translations light up the moment the DB has data.');
  File('$_outDir/README.md').writeAsStringSync(buf.toString());
}

// ── Minimal CSV parser: RFC 4180-lite with quoted-field support ────────────
// Handles embedded commas and newlines inside double-quoted fields, and
// "" escaping inside a quoted field. All the CSV Supabase exports use
// this convention.
List<_Row> _parseCsv(String content) {
  final fields = <List<String>>[];
  var field = StringBuffer();
  var row = <String>[];
  var inQuotes = false;
  for (var i = 0; i < content.length; i++) {
    final c = content[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < content.length && content[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
      continue;
    }
    if (c == '"') {
      inQuotes = true;
    } else if (c == ',') {
      row.add(field.toString());
      field = StringBuffer();
    } else if (c == '\n') {
      row.add(field.toString());
      fields.add(row);
      row = <String>[];
      field = StringBuffer();
    } else if (c == '\r') {
      // ignore
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    fields.add(row);
  }

  final rows = <_Row>[];
  for (var i = 0; i < fields.length; i++) {
    if (i == 0) continue; // header
    final f = fields[i];
    if (f.length < 4) continue;
    final id = f[0].trim();
    if (id.isEmpty) continue;
    rows.add(_Row(id, f[1].trim(), f[2].trim(), f[3].trim()));
  }
  return rows;
}
