// Notification variant translation batch generator.
//
// The 7 push notification types below fall through to a static English
// fallback because `notification_variants` has no rows for them. This
// script writes one Gemini prompt asking for 7 non-EN translations of
// each fallback pair. After Gemini returns, `merge_notification_variant_batches.dart`
// emits a Supabase migration that seeds the missing rows.
//
// Output:
//   build/notification_variant_batches/source.json   — canonical EN
//   build/notification_variant_batches/prompt.md     — Gemini prompt
//   build/notification_variant_batches/output/       — drop LLM response here
//   build/notification_variant_batches/README.md     — workflow notes
//
// Usage:
//   dart run scripts/generate_notification_variant_batches.dart

import 'dart:convert';
import 'dart:io';

const _outDir = 'build/notification_variant_batches';

const _targetLocales = [
  ('ur', 'Urdu (Perso-Arabic script)'),
  ('ar', 'Arabic (Naskh script — MSA)'),
  ('fr', 'French'),
  ('id', 'Bahasa Indonesia'),
  ('ms', 'Bahasa Melayu'),
  ('ru', 'Russian (Cyrillic)'),
  ('tr', 'Turkish'),
];

// Static English fallbacks extracted from the 7 edge functions that
// lack DB variants (see conversation for source lines). Values match
// the `staticFallback` argument to `pickVariant()` in each function.
//
// Templated `${var}` is converted to `{var}` — that is the placeholder
// syntax `variants.ts::fillTemplate` substitutes at send time.
const _source = <String, Map<String, Object?>>{
  'akhirah_milestone': {
    'title': '{milestone} XP for your akhirah',
    'body': 'Subhan Allah — you\'ve earned {milestone} XP. Every point is a deed planted for the next life. Keep going.',
    'route': 'home',
    'placeholders': ['{milestone}'],
  },
  'disengagement_pause': {
    'title': 'Reminders paused',
    'body': 'It looks like our nudges aren\'t reaching you. We\'ll quiet them for now — open Sabiq whenever your heart calls and they\'ll come back on their own.',
    'route': 'home',
    'placeholders': <String>[],
  },
  'featured_dua': {
    'title': 'A dua for today',
    // The body is overridden at send time with the actual azkar text
    // (already localised in azkar_items). We only need the title.
    'body': null,
    'route': 'dhikr',
    'placeholders': <String>[],
  },
  'project_funded': {
    'title': 'Your sadaqah reached its goal',
    'body': '"{projectName}" is fully funded — jazak Allahu khayran for being part of it. Your reward continues with every soul it benefits.',
    'route': 'home',
    'placeholders': ['{projectName}'],
  },
  'streak_milestone': {
    'title': '{streak} days of {streakType}',
    'body': 'Ma sha Allah — {streak} days of {streakType} in a row. Consistency is what Allah loves most. Keep the chain alive.',
    'route': 'home',
    'placeholders': ['{streak}', '{streakType}'],
  },
  'surah_kahf_friday': {
    'title': 'It\'s Friday — read Surah Al-Kahf',
    'body': 'Whoever recites Surah Al-Kahf on Friday, light shines for them between the two Fridays.',
    'route': 'quran',
    'placeholders': <String>[],
  },
  'validate_seeds': {
    'title': 'Your Seeds are growing',
    'body': 'Donate your Sabiq Seeds to fund real projects — orphans, masjids, free meals. Every Seed plants a deed.',
    'route': 'cause',
    'placeholders': <String>[],
  },
};

void main() {
  final outDir = Directory(_outDir);
  if (outDir.existsSync()) outDir.deleteSync(recursive: true);
  outDir.createSync(recursive: true);
  Directory('$_outDir/output').createSync();

  // Flat source for the prompt: `type.title` and `type.body` keys.
  final flat = <String, String>{};
  _source.forEach((type, m) {
    flat['$type.title'] = m['title'] as String;
    final body = m['body'];
    if (body is String) flat['$type.body'] = body;
  });

  File('$_outDir/source.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(_source),
  );

  final buf = StringBuffer();
  buf.writeln('# Push-notification variant translation');
  buf.writeln();
  buf.writeln('Paste EVERYTHING below into a fresh Gemini chat. Save the response as `output/output.md` (or `.json`) next to this file.');
  buf.writeln();
  buf.writeln('---');
  buf.writeln();
  buf.writeln('You are translating **push notification titles + bodies** for **Sabiq Rewards**, an Islamic worship-tracking app (Quran, dhikr, streaks, community donations, Seeds — an in-app currency). These messages arrive on lock screens, so tone is warm, motivating, and terse.');
  buf.writeln();
  buf.writeln('## Task');
  buf.writeln();
  buf.writeln('Translate the ${flat.length} English strings below into these 7 target locales:');
  buf.writeln();
  for (final (code, name) in _targetLocales) {
    buf.writeln('- `$code` — $name');
  }
  buf.writeln();
  buf.writeln('## Absolute rules');
  buf.writeln();
  buf.writeln('1. **Preserve every `{placeholder}` verbatim.** e.g. `{milestone}`, `{streak}`, `{streakType}`, `{projectName}`. Do NOT translate or rename them. They are substituted with real values at send time.');
  buf.writeln();
  buf.writeln('2. **Keep it lock-screen short.** Title ≤ 40 chars where possible, body ≤ 120 chars. Match the register of the English source: warm, prophetic, motivating — not preachy or verbose.');
  buf.writeln();
  buf.writeln('3. **Do not translate:**');
  buf.writeln('   - Brand: `Sabiq`, `Sabiq Seeds`, `Seeds`');
  buf.writeln('   - Islamic terms with settled per-locale spelling. Use the natural local form: Subhan Allah, Ma sha Allah, jazak Allahu khayran, sadaqah, Surah Al-Kahf, dua, akhirah, XP. In ar/ur use Arabic script for the phrases (سبحان الله، ما شاء الله، جزاك الله خيراً، صدقة، سورة الكهف، دعاء، آخرة). In fr/id/ms/ru/tr keep the settled transliteration.');
  buf.writeln('   - `XP` stays as-is in every locale (like Seeds).');
  buf.writeln();
  buf.writeln('4. **No commentary, brackets, footnotes, asterisks, or emoji** unless the English source had one.');
  buf.writeln();
  buf.writeln('## Output format');
  buf.writeln();
  buf.writeln('Return **ONE single JSON object** inside **ONE** fenced code block. Top-level keys are the locale codes `ur`, `ar`, `fr`, `id`, `ms`, `ru`, `tr` in that order. Each value is a flat `{key: translation}` map with the SAME keys as the source below (e.g. `akhirah_milestone.title`, `akhirah_milestone.body`, …).');
  buf.writeln();
  buf.writeln('```json');
  buf.writeln('{');
  buf.writeln('  "ur": {');
  buf.writeln('    "akhirah_milestone.title": "…",');
  buf.writeln('    "akhirah_milestone.body":  "…",');
  buf.writeln('    "disengagement_pause.title": "…",');
  buf.writeln('    "disengagement_pause.body":  "…",');
  buf.writeln('    …');
  buf.writeln('  },');
  buf.writeln('  "ar": { … },');
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
  buf.writeln('## Source strings (${flat.length} keys)');
  buf.writeln();
  buf.writeln('```json');
  buf.write(const JsonEncoder.withIndent('  ').convert(flat));
  buf.writeln();
  buf.writeln('```');

  File('$_outDir/prompt.md').writeAsStringSync(buf.toString());

  // Workflow readme.
  final readme = StringBuffer()
    ..writeln('# Push-notification variant translation')
    ..writeln()
    ..writeln('One-shot Gemini pipeline that fills the gap for 7 push types')
    ..writeln('(`akhirah_milestone`, `disengagement_pause`, `featured_dua`,')
    ..writeln('`project_funded`, `streak_milestone`, `surah_kahf_friday`,')
    ..writeln('`validate_seeds`) that currently fall through to the static')
    ..writeln('English fallback in each edge function.')
    ..writeln()
    ..writeln('## Workflow')
    ..writeln()
    ..writeln('1. Open `prompt.md`. Copy the WHOLE file into a fresh Gemini chat.')
    ..writeln('2. Save the response verbatim as `output/output.md`.')
    ..writeln('3. Run:')
    ..writeln()
    ..writeln('   ```')
    ..writeln('   dart run scripts/merge_notification_variant_batches.dart')
    ..writeln('   ```')
    ..writeln()
    ..writeln('   Emits `supabase/migrations/<date>_notification_variants_fallback_translations.sql`.')
    ..writeln()
    ..writeln('4. Apply the migration in Supabase (SQL Editor or `supabase db push`).');

  File('$_outDir/README.md').writeAsStringSync(readme.toString());

  print('Wrote prompt for ${flat.length} strings into $_outDir/');
}
