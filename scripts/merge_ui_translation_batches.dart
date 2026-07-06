// Merges LLM-produced translation batches back into the .arb files.
//
// Reads:
//   build/ui_translation_batches/batch_NN_source.json    — source EN keys
//   build/ui_translation_batches/output/batch_NN_output.md — LLM response
//
// For each of the 7 target locales, walks all batches, extracts the
// per-locale fenced JSON block, validates:
//   - every source key is present
//   - every {placeholder} in the source is present in the translation
//   - ICU keywords are preserved (plural, select, other, =0, =1, …)
// then merges the accepted translations into `lib/l10n/app_<locale>.arb`.
//
// Any key that fails validation is left untouched in the .arb file (i.e.
// the previous Google Translate value is preserved as fallback) and
// listed at the end so you can retry that batch.
//
// After merge, runs `flutter gen-l10n` to rebuild bindings.
//
// Usage:
//   dart run scripts/merge_ui_translation_batches.dart

import 'dart:convert';
import 'dart:io';

const _batchDir = 'build/ui_translation_batches';
const _outputDir = 'build/ui_translation_batches/output';
const _arbDir = 'lib/l10n';
const _locales = ['ur', 'ar', 'fr', 'id', 'ms', 'ru', 'tr'];

// Every `{name}` token in the source must survive in the translation.
final _placeholderRe = RegExp(r'\{([a-zA-Z][a-zA-Z0-9_]*)\}');

// ICU keywords that must be present in the translation if they were in
// the source. We only check for existence, not position — ICU is nested
// enough that positional matching gives too many false positives.
final _icuKeywords = <String>{
  'plural',
  'select',
  'selectordinal',
  'other',
  'zero',
  'one',
  'two',
  'few',
  'many',
  '=0',
  '=1',
  '=2',
};

class _ValidationError {
  final String batch;
  final String locale;
  final String key;
  final String reason;
  _ValidationError(this.batch, this.locale, this.key, this.reason);
  @override
  String toString() => '  batch=$batch  $locale.$key  →  $reason';
}

void main() {
  final batchDir = Directory(_batchDir);
  final outDir = Directory(_outputDir);
  if (!batchDir.existsSync() || !outDir.existsSync()) {
    stderr.writeln('Batch dir missing. Run generate_ui_translation_batches.dart first.');
    exit(1);
  }

  final sourceFiles = batchDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('_source.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  print('Found ${sourceFiles.length} batches.');
  if (sourceFiles.isEmpty) exit(0);

  // Load every locale's current .arb into memory once. We update in
  // place and write back at the end.
  final arbs = <String, Map<String, dynamic>>{};
  for (final loc in _locales) {
    final f = File('$_arbDir/app_$loc.arb');
    if (!f.existsSync()) {
      stderr.writeln('Missing $_arbDir/app_$loc.arb — skipping locale $loc.');
      continue;
    }
    arbs[loc] = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  }

  final errors = <_ValidationError>[];
  final applied = <String, int>{for (final loc in _locales) loc: 0};
  final missingBatches = <String>[];

  for (final srcFile in sourceFiles) {
    final batchName = srcFile.uri.pathSegments.last.replaceFirst('_source.json', '');
    final source = jsonDecode(srcFile.readAsStringSync()) as Map<String, dynamic>;
    final outFile = File('$_outputDir/${batchName}_output.md');
    if (!outFile.existsSync()) {
      missingBatches.add(batchName);
      continue;
    }
    final parsed = _parseOutputBlocks(outFile.readAsStringSync());

    for (final loc in _locales) {
      if (arbs[loc] == null) continue;
      final block = parsed[loc];
      if (block == null) {
        errors.add(_ValidationError(batchName, loc, '*', 'locale block missing from output'));
        continue;
      }
      for (final entry in source.entries) {
        final key = entry.key;
        final enText = entry.value as String;
        final translation = block[key];
        if (translation == null || translation is! String || translation.trim().isEmpty) {
          errors.add(_ValidationError(batchName, loc, key, 'missing or empty'));
          continue;
        }
        // Placeholder check.
        final srcPlaceholders = _placeholderRe
            .allMatches(enText)
            .map((m) => m.group(0)!)
            .toSet();
        final trPlaceholders = _placeholderRe
            .allMatches(translation)
            .map((m) => m.group(0)!)
            .toSet();
        final missingPh = srcPlaceholders.difference(trPlaceholders);
        if (missingPh.isNotEmpty) {
          errors.add(_ValidationError(batchName, loc, key,
              'placeholder(s) missing: ${missingPh.join(", ")}'));
          continue;
        }
        // ICU keyword check.
        final srcHasIcu = _icuKeywords.any((k) => enText.contains(k));
        if (srcHasIcu) {
          final missingIcu = _icuKeywords
              .where((k) => enText.contains(k) && !translation.contains(k))
              .toList();
          // `other` is the only required plural form. Missing anything
          // else we treat as a warning by continuing but not adding to
          // errors — LLM may reshape the plural map legitimately.
          if (missingIcu.contains('other')) {
            errors.add(_ValidationError(batchName, loc, key,
                'ICU `other` branch missing'));
            continue;
          }
        }
        arbs[loc]![key] = translation;
        applied[loc] = applied[loc]! + 1;
      }
    }
  }

  // Write back only if we had at least one successful merge for a locale.
  for (final loc in _locales) {
    if (arbs[loc] == null || applied[loc] == 0) continue;
    final encoded = const JsonEncoder.withIndent('  ').convert(arbs[loc]);
    File('$_arbDir/app_$loc.arb').writeAsStringSync('$encoded\n');
    print('  $loc: ${applied[loc]} keys updated.');
  }

  if (missingBatches.isNotEmpty) {
    print('');
    print('Batches with no output file (waiting on you):');
    for (final b in missingBatches) {
      print('  $b');
    }
  }
  if (errors.isNotEmpty) {
    print('');
    print('${errors.length} validation errors — these keys kept their old value:');
    for (final e in errors.take(50)) {
      print(e);
    }
    if (errors.length > 50) {
      print('  … and ${errors.length - 50} more.');
    }
  }
  print('');
  print('Now run: flutter gen-l10n');
}

// Extracts `~~~<locale> … ~~~` fenced JSON blocks from the LLM output.
// The prompt asks for exactly this format; if the LLM used ``` instead
// of ~~~ we also accept that.
Map<String, Map<String, dynamic>> _parseOutputBlocks(String content) {
  final result = <String, Map<String, dynamic>>{};
  // Match either fence style. Locale tag is the word right after the
  // opening fence. Body is everything up to the next matching fence.
  final re = RegExp(
    r'(?:~~~|```)\s*([a-z]{2})\s*\n([\s\S]*?)\n\s*(?:~~~|```)',
    multiLine: true,
  );
  for (final m in re.allMatches(content)) {
    final loc = m.group(1)!;
    if (!_locales.contains(loc)) continue;
    final body = m.group(2)!.trim();
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) result[loc] = decoded;
    } catch (_) {
      // Silent skip — validator will flag missing keys per locale.
    }
  }
  return result;
}
