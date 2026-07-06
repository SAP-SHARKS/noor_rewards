// One-shot builder — takes the LLM-produced translation CSV, applies the
// Stage-1 source-data patches we agreed on, and emits two Supabase
// migration files:
//
//   supabase/migrations/20260706_010_azkar_short_benefit_ur_ar.sql
//     • Adds 7 locale columns to azkar_items.
//     • Applies Stage-1 English fixes to 5 rows.
//     • Populates short_benefit_ur + short_benefit_ar for every row.
//     • Safe to ship on its own — the app's `pick('short_benefit')` helper
//       already reads locale-suffixed columns and falls back to English +
//       runtime MT for locales without data.
//
//   supabase/migrations/20260706_020_azkar_short_benefit_fr_id_ms_ru_tr.sql
//     • Populates the remaining five locales.
//     • Ship after native review — you can also split further and run per
//       locale by copying the relevant VALUES block into its own file.
//
// Run once:
//   dart run scripts/build_short_benefit_migrations.dart

import 'dart:io';

const _csvPath =
    r'C:\Users\zahee\Downloads\short_benefit_translations - short_benefit_translations.csv.csv';
const _outStage2 =
    'supabase/migrations/20260706_010_azkar_short_benefit_ur_ar.sql';
const _outStage3 =
    'supabase/migrations/20260706_020_azkar_short_benefit_fr_id_ms_ru_tr.sql';

// ── Stage-1 source-data patches ──────────────────────────────────────────
//
// Each entry replaces the English `short_benefit` (and, where the meaning
// materially shifted, the 7 locale translations too). Rows omitted from the
// per-locale maps keep whatever the LLM produced.
final _patches = <String, Map<String, String>>{
  // Arabic is the "leaving the masjid" dua ("O Allah, I ask You of Your
  // bounty"). The English mistakenly copied the "entering" benefit from
  // daily_dua_012. Fix all 8 columns.
  'daily_dua_013': {
    'short_benefit': 'Said when leaving the masjid — asks Allah of His bounty.',
    'short_benefit_ur':
        'مسجد سے نکلتے وقت — اللہ سے اس کے فضل کا سوال۔',
    'short_benefit_ar':
        'تُقال عند الخروج من المسجد — سؤال الله من فضله.',
    'short_benefit_fr':
        'Dite en sortant de la mosquée — demande à Allah de Sa grâce.',
    'short_benefit_id':
        'Diucapkan saat keluar masjid — memohon karunia Allah.',
    'short_benefit_ms':
        'Diucapkan ketika keluar masjid — memohon kurniaan Allah.',
    'short_benefit_ru':
        'Произносится при выходе из мечети — просьба у Аллаха Его щедрости.',
    'short_benefit_tr':
        'Mescidden çıkarken söylenir — Allah\'tan lütfunu ister.',
  },
  // English drifted from the Arabic (Arabic says "relief from every worry,
  // way out from every hardship, safety from every trial" — not
  // "success after humiliation, peace after trial"). Realigning.
  'bocp_196': {
    'short_benefit':
        'Asks Allah for relief from every worry, way out of every hardship, and safety from every trial.',
    'short_benefit_ur':
        'ہر پریشانی سے راحت، ہر تنگی سے راستہ اور ہر آزمائش سے حفاظت کی دعا۔',
    'short_benefit_ar':
        'طلب الفرج من كل هم والمخرج من كل ضيق والعافية من كل بلاء.',
    'short_benefit_fr':
        'Demande à Allah la délivrance de tout souci, une issue à toute difficulté et la sécurité face à toute épreuve.',
    'short_benefit_id':
        'Memohon kepada Allah kelapangan dari setiap kesusahan, jalan keluar dari setiap kesempitan, dan keselamatan dari setiap ujian.',
    'short_benefit_ms':
        'Memohon kepada Allah kelapangan daripada setiap kesusahan, jalan keluar daripada setiap kesempitan, dan keselamatan daripada setiap ujian.',
    'short_benefit_ru':
        'Просьба к Аллаху об избавлении от всякой печали, выходе из всякой тяготы и защите от всякого испытания.',
    'short_benefit_tr':
        'Her sıkıntıdan kurtuluş, her darlıktan çıkış ve her beladan afiyet ister.',
  },
  // Arabic includes وَخُذْ بِثَأْرِي ("and take my revenge") — the English
  // omitted this. Restoring the retaliation clause.
  'bocp_104': {
    'short_benefit':
        'Asks Allah to preserve hearing and sight, and to grant justice over wrongdoers.',
    'short_benefit_ur':
        'سماعت اور بصارت کی حفاظت اور ظالموں پر انصاف کی دعا۔',
    'short_benefit_ar':
        'طلب حفظ السمع والبصر والانتصار من الظالم.',
    'short_benefit_fr':
        'Demande à Allah de préserver l\'ouïe et la vue et d\'accorder justice contre les injustes.',
    'short_benefit_id':
        'Memohon kepada Allah agar dijaga pendengaran dan penglihatan serta ditolong atas orang yang menzalimi.',
    'short_benefit_ms':
        'Memohon kepada Allah agar dipelihara pendengaran dan penglihatan serta ditolong terhadap orang yang menzalimi.',
    'short_benefit_ru':
        'Просьба сохранить слух и зрение и даровать справедливость над обидчиками.',
    'short_benefit_tr':
        'İşitme ve görmenin korunmasını ve zalimlere karşı adaleti ister.',
  },
  // Tighten English to match Arabic (praise via divine names). LLM
  // translations already reflect the Arabic — untouched.
  'bocp_105': {
    'short_benefit':
        'Praise of Allah by His majestic names — the Originator, the Ever-Living, the Everlasting.',
  },
  // sayyid_istighfar and bocp_141 are the same hadith. Reconcile both
  // English strings to a single canonical form so translators see the same
  // source. LLM translations for both already convey this — leaving as-is.
  'sayyid_istighfar': {
    'short_benefit':
        'Sayyid al-Istighfar — whoever says it with conviction and dies that day enters Paradise.',
  },
  'bocp_141': {
    'short_benefit':
        'Sayyid al-Istighfar — whoever says it with conviction and dies that day enters Paradise.',
  },
};

// ── CSV parsing ──────────────────────────────────────────────────────────
//
// The file mixes quoted and unquoted rows (rows with commas inside a
// translation are quoted, the rest are bare). Standard RFC-4180 parser:
//   - a field starts either at position 0 or right after a `,`
//   - if it begins with `"`, read until an unescaped `"` (doubled `""`
//     inside means one literal quote); otherwise read until the next `,`.
List<String> _parseCsvRow(String line) {
  final out = <String>[];
  var i = 0;
  while (i < line.length) {
    if (line[i] == '"') {
      // Quoted field.
      final buf = StringBuffer();
      i++; // Skip opening quote.
      while (i < line.length) {
        if (line[i] == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            buf.write('"');
            i += 2;
            continue;
          }
          i++; // Closing quote.
          break;
        }
        buf.write(line[i]);
        i++;
      }
      out.add(buf.toString());
      // Consume the trailing comma if there is one.
      if (i < line.length && line[i] == ',') i++;
    } else {
      // Unquoted field — read to next comma or end of line.
      final start = i;
      while (i < line.length && line[i] != ',') {
        i++;
      }
      out.add(line.substring(start, i));
      if (i < line.length && line[i] == ',') i++;
    }
  }
  return out;
}

// PostgreSQL dollar-quoted string — safest way to embed a literal that
// might contain single quotes, backslashes, curly quotes, em-dashes, or
// Arabic script without any escaping. `$sb$…$sb$` will not collide with
// the content because none of our rows ship a literal `$sb$` sequence.
String _pgQuote(String s) => '\$sb\$$s\$sb\$';

void main() {
  final file = File(_csvPath);
  if (!file.existsSync()) {
    stderr.writeln('CSV not found: $_csvPath');
    exit(1);
  }
  final lines = file
      .readAsStringSync()
      .split(RegExp(r'\r?\n'))
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.isEmpty) {
    stderr.writeln('CSV is empty.');
    exit(1);
  }

  final headerCells = _parseCsvRow(lines.first);
  final colIndex = <String, int>{
    for (var i = 0; i < headerCells.length; i++) headerCells[i]: i,
  };
  final required = [
    'id',
    'short_benefit',
    'short_benefit_ur',
    'short_benefit_ar',
    'short_benefit_fr',
    'short_benefit_id',
    'short_benefit_ms',
    'short_benefit_ru',
    'short_benefit_tr',
  ];
  for (final c in required) {
    if (!colIndex.containsKey(c)) {
      stderr.writeln('Missing column: $c');
      exit(1);
    }
  }

  final rows = <Map<String, String>>[];
  for (var i = 1; i < lines.length; i++) {
    final cells = _parseCsvRow(lines[i]);
    if (cells.length < headerCells.length) continue;
    final row = <String, String>{
      for (var j = 0; j < headerCells.length; j++)
        headerCells[j]: cells[j].trim(),
    };
    final patch = _patches[row['id']];
    if (patch != null) row.addAll(patch);
    rows.add(row);
  }
  print('Parsed ${rows.length} rows. Patched ${_patches.length} entries.');

  final patchedIds = _patches.keys.toList()..sort();

  // ── Stage 2: add columns + patch English + populate ur/ar ───────────
  final s2 = StringBuffer();
  s2.writeln('-- Stage 2: azkar_items short_benefit — Urdu + Arabic');
  s2.writeln('-- Adds 7 locale columns (all populated over Stage 2 + 3).');
  s2.writeln('-- Applies Stage-1 English source-data patches to 5 rows.');
  s2.writeln('-- Populates only short_benefit_ur + short_benefit_ar.');
  s2.writeln('-- Idempotent — safe to re-run.');
  s2.writeln();
  s2.writeln('BEGIN;');
  s2.writeln();
  s2.writeln(
    'ALTER TABLE azkar_items ADD COLUMN IF NOT EXISTS short_benefit_ur text;',
  );
  s2.writeln(
    'ALTER TABLE azkar_items ADD COLUMN IF NOT EXISTS short_benefit_ar text;',
  );
  s2.writeln(
    'ALTER TABLE azkar_items ADD COLUMN IF NOT EXISTS short_benefit_fr text;',
  );
  s2.writeln(
    'ALTER TABLE azkar_items ADD COLUMN IF NOT EXISTS short_benefit_id text;',
  );
  s2.writeln(
    'ALTER TABLE azkar_items ADD COLUMN IF NOT EXISTS short_benefit_ms text;',
  );
  s2.writeln(
    'ALTER TABLE azkar_items ADD COLUMN IF NOT EXISTS short_benefit_ru text;',
  );
  s2.writeln(
    'ALTER TABLE azkar_items ADD COLUMN IF NOT EXISTS short_benefit_tr text;',
  );
  s2.writeln();
  s2.writeln('-- ── Stage-1 English patches ────────────────────────────');
  for (final id in patchedIds) {
    final en = _patches[id]!['short_benefit'];
    if (en == null) continue;
    s2.writeln(
      'UPDATE azkar_items SET short_benefit = ${_pgQuote(en)} WHERE id = ${_pgQuote(id)};',
    );
  }
  s2.writeln();
  s2.writeln('-- ── Populate Urdu + Arabic (${rows.length} rows) ───────');
  s2.writeln('WITH v(id, sb_ur, sb_ar) AS (VALUES');
  for (var i = 0; i < rows.length; i++) {
    final r = rows[i];
    final trail = i == rows.length - 1 ? '' : ',';
    s2.writeln(
      '  (${_pgQuote(r['id']!)}, ${_pgQuote(r['short_benefit_ur']!)}, ${_pgQuote(r['short_benefit_ar']!)})$trail',
    );
  }
  s2.writeln(')');
  s2.writeln('UPDATE azkar_items a SET');
  s2.writeln('  short_benefit_ur = v.sb_ur,');
  s2.writeln('  short_benefit_ar = v.sb_ar');
  s2.writeln('FROM v WHERE a.id = v.id;');
  s2.writeln();
  s2.writeln('COMMIT;');

  Directory('supabase/migrations').createSync(recursive: true);
  File(_outStage2).writeAsStringSync(s2.toString());
  print('Wrote $_outStage2');

  // ── Stage 3: populate fr/id/ms/ru/tr ────────────────────────────────
  final s3 = StringBuffer();
  s3.writeln('-- Stage 3: azkar_items short_benefit — fr / id / ms / ru / tr');
  s3.writeln('-- Ship after native review. Idempotent.');
  s3.writeln('-- To ship a single locale in isolation, keep only its column');
  s3.writeln('-- in the UPDATE SET clause below and drop the others.');
  s3.writeln();
  s3.writeln('BEGIN;');
  s3.writeln();
  s3.writeln(
    'WITH v(id, sb_fr, sb_id, sb_ms, sb_ru, sb_tr) AS (VALUES',
  );
  for (var i = 0; i < rows.length; i++) {
    final r = rows[i];
    final trail = i == rows.length - 1 ? '' : ',';
    s3.writeln(
      '  (${_pgQuote(r['id']!)}, ${_pgQuote(r['short_benefit_fr']!)}, ${_pgQuote(r['short_benefit_id']!)}, ${_pgQuote(r['short_benefit_ms']!)}, ${_pgQuote(r['short_benefit_ru']!)}, ${_pgQuote(r['short_benefit_tr']!)})$trail',
    );
  }
  s3.writeln(')');
  s3.writeln('UPDATE azkar_items a SET');
  s3.writeln('  short_benefit_fr = v.sb_fr,');
  s3.writeln('  short_benefit_id = v.sb_id,');
  s3.writeln('  short_benefit_ms = v.sb_ms,');
  s3.writeln('  short_benefit_ru = v.sb_ru,');
  s3.writeln('  short_benefit_tr = v.sb_tr');
  s3.writeln('FROM v WHERE a.id = v.id;');
  s3.writeln();
  s3.writeln('COMMIT;');

  File(_outStage3).writeAsStringSync(s3.toString());
  print('Wrote $_outStage3');
  print('Done.');
}
