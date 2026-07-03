// Level-1 i18n codemod.
//
// Reads i18n-audit.txt, generates a stable key name for each hit,
// adds the key + English value to app_en.arb (and mirrors to all 7
// non-EN .arb files as an EN placeholder), and emits TODO_I18N.md —
// a per-file worklist of `file:line — key: "literal"` entries so a
// human/agent can do the Dart-side wrap in a follow-up.
//
// Does NOT modify any .dart source. Safe to re-run: duplicate
// (file, literal) pairs get the SAME key; already-present .arb
// entries are preserved.
//
// Usage: `dart run scripts/apply_i18n_keys.dart`

import 'dart:convert';
import 'dart:io';

const _auditPath = 'i18n-audit.txt';
const _enArbPath = 'lib/l10n/app_en.arb';
const _targetLocales = ['ur', 'ar', 'fr', 'id', 'ms', 'ru', 'tr'];
const _todoPath = 'TODO_I18N.md';

/// Turn `lib/screens/dashboard_screen.dart` into `dashboardScreen`.
String _fileSlug(String path) {
  final base = path.split('/').last.replaceAll('.dart', '');
  final parts = base.split('_');
  final camel = parts.first + parts.skip(1).map(_capitalize).join();
  return camel;
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Slug of the literal — first 4 meaningful words, camelCased.
String _literalSlug(String literal) {
  final s = literal
      .replaceAll(RegExp(r'\$\{[^}]+\}'), '')
      .replaceAll(RegExp(r'\$[a-zA-Z_][a-zA-Z0-9_]*'), '')
      .replaceAll(RegExp(r'[^A-Za-z ]'), ' ')
      .trim();
  final words = s
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && w.length > 1)
      .take(4)
      .toList();
  if (words.isEmpty) return '';
  final first = words.first.toLowerCase();
  final rest = words.skip(1).map(_capitalize).join();
  return first + rest;
}

/// Stable short hash suffix for uniqueness.
String _hash(String s) {
  var h = 0x811c9dc5;
  for (final r in s.runes) {
    h = ((h ^ r) * 0x01000193) & 0xFFFFFFFF;
  }
  return h.toRadixString(16).padLeft(8, '0').substring(0, 6);
}

/// Ensure the key is a valid Dart identifier and unique against `existing`.
String _uniqueKey(String base, Set<String> existing, String literal) {
  var key = base;
  // Sanitize
  key = key.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
  if (key.isEmpty || RegExp(r'^\d').hasMatch(key)) {
    key = 'k$key';
  }
  if (!existing.contains(key)) return key;
  final suffix = _hash(literal);
  return '${key}_$suffix';
}

/// Parse `path:line: [tag] "literal"` audit line.
({String path, int line, String tag, String literal})? _parseAuditLine(
    String raw) {
  // Match `path:line: [tag] "literal"`
  final m = RegExp(r'^([^:]+):(\d+):\s+\[([^\]]+)\]\s+"(.*)"$').firstMatch(raw);
  if (m == null) return null;
  return (
    path: m.group(1)!,
    line: int.parse(m.group(2)!),
    tag: m.group(3)!,
    literal: m.group(4)!,
  );
}

/// Detect Dart interpolation placeholders in a literal and return a list
/// of (name, expr) pairs. `$var` → (var, var); `${expr}` → (arg1, expr).
List<({String name, String expr})> _extractPlaceholders(String literal) {
  final result = <({String name, String expr})>[];
  final re = RegExp(r'\$\{([^}]+)\}|\$([a-zA-Z_][a-zA-Z0-9_]*)');
  var argIdx = 0;
  for (final m in re.allMatches(literal)) {
    if (m.group(1) != null) {
      argIdx++;
      result.add((name: 'arg$argIdx', expr: m.group(1)!));
    } else if (m.group(2) != null) {
      result.add((name: m.group(2)!, expr: m.group(2)!));
    }
  }
  return result;
}

/// Convert Dart interpolation `Sponsor $name, ${o.age}` → ICU `Sponsor {name}, {arg1}`
String _toIcu(String literal, List<({String name, String expr})> placeholders) {
  var out = literal;
  final re = RegExp(r'\$\{[^}]+\}|\$[a-zA-Z_][a-zA-Z0-9_]*');
  var idx = 0;
  out = out.replaceAllMapped(re, (m) {
    final p = placeholders[idx++];
    return '{${p.name}}';
  });
  return out;
}

void main() {
  final auditFile = File(_auditPath);
  if (!auditFile.existsSync()) {
    stderr.writeln('Missing $_auditPath — run find_hardcoded.dart first.');
    exit(1);
  }

  // Load en.arb, preserving order.
  final enFile = File(_enArbPath);
  final enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
  final existingKeys = enMap.keys
      .where((k) => !k.startsWith('@') && k != '@@locale')
      .toSet();

  // Per-file worklist and dedup: (path, literal) → key.
  final dedup = <String, String>{}; // "$path::$literal" → key
  final worklist = <String, List<Map<String, dynamic>>>{}; // file → hits
  final newKeys = <String, ({String value, List<({String name, String expr})> placeholders})>{};

  final auditLines = auditFile.readAsLinesSync();
  var totalHits = 0;
  for (final raw in auditLines) {
    final hit = _parseAuditLine(raw);
    if (hit == null) continue;
    totalHits++;
    final key = () {
      final dedupKey = '${hit.path}::${hit.literal}';
      if (dedup.containsKey(dedupKey)) return dedup[dedupKey]!;
      final placeholders = _extractPlaceholders(hit.literal);
      final baseSlug = _literalSlug(hit.literal);
      final base = '${_fileSlug(hit.path)}_${baseSlug.isEmpty ? _hash(hit.literal) : baseSlug}';
      final k = _uniqueKey(base, existingKeys, hit.literal);
      existingKeys.add(k);
      final icuValue = _toIcu(hit.literal, placeholders);
      newKeys[k] = (value: icuValue, placeholders: placeholders);
      dedup[dedupKey] = k;
      return k;
    }();

    worklist.putIfAbsent(hit.path, () => []).add({
      'line': hit.line,
      'tag': hit.tag,
      'key': key,
      'literal': hit.literal,
    });
  }

  // Add new keys to en.arb (preserve original order, append new).
  for (final e in newKeys.entries) {
    final key = e.key;
    if (enMap.containsKey(key)) continue;
    enMap[key] = e.value.value;
    if (e.value.placeholders.isNotEmpty) {
      final ph = <String, dynamic>{};
      for (final p in e.value.placeholders) {
        // Use `Object` so callers can pass ints, doubles, exceptions, etc.
        // without a `.toString()` at every call site — ICU stringifies at
        // substitution time.
        ph[p.name] = {'type': 'Object'};
      }
      enMap['@$key'] = {'placeholders': ph};
    }
  }

  final encoder = const JsonEncoder.withIndent('  ');
  enFile.writeAsStringSync('${encoder.convert(enMap)}\n');

  // Mirror to non-EN locales (append missing keys with EN value).
  for (final loc in _targetLocales) {
    final f = File('lib/l10n/app_$loc.arb');
    final map = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    for (final e in newKeys.entries) {
      if (map.containsKey(e.key)) continue;
      map[e.key] = e.value.value;
      if (e.value.placeholders.isNotEmpty) {
        map['@${e.key}'] = enMap['@${e.key}'];
      }
    }
    // Re-order per en.arb key order.
    final ordered = <String, dynamic>{'@@locale': loc};
    for (final k in enMap.keys) {
      if (k == '@@locale') continue;
      if (map.containsKey(k)) ordered[k] = map[k];
    }
    f.writeAsStringSync('${encoder.convert(ordered)}\n');
  }

  // Emit TODO_I18N.md worklist.
  final todo = StringBuffer();
  todo.writeln('# i18n Wrapping Worklist');
  todo.writeln();
  todo.writeln('Generated by `dart run scripts/apply_i18n_keys.dart`.');
  todo.writeln('${newKeys.length} unique keys added across ${worklist.length} files.');
  todo.writeln('');
  todo.writeln(
      'For each entry, replace the literal in the Dart source with the shown replacement.');
  todo.writeln(
      'Use `l?.<key> ?? "literal"` for null-safety in Widget code (with `final l = AppLocalizations.of(context);`).');
  todo.writeln();

  final sortedFiles = worklist.keys.toList()..sort();
  for (final file in sortedFiles) {
    final hits = worklist[file]!..sort((a, b) => (a['line'] as int).compareTo(b['line'] as int));
    todo.writeln('## $file (${hits.length} hits)');
    todo.writeln();
    for (final h in hits) {
      final key = h['key'];
      final lit = h['literal'];
      final line = h['line'];
      final tag = h['tag'];
      final placeholders = newKeys[key]?.placeholders ?? const [];
      final replacement = () {
        if (placeholders.isEmpty) {
          return 'l?.$key ?? "$lit"';
        }
        final args = placeholders.map((p) => p.expr).join(', ');
        return 'l?.$key($args) ?? "$lit"';
      }();
      todo.writeln('- [ ] L$line \\[$tag\\] `$key`');
      todo.writeln('  - literal: `"$lit"`');
      todo.writeln('  - replace with: `$replacement`');
    }
    todo.writeln();
  }

  File(_todoPath).writeAsStringSync(todo.toString());

  stdout.writeln('=== apply_i18n_keys.dart ===');
  stdout.writeln('Audit hits: $totalHits');
  stdout.writeln('Unique keys added: ${newKeys.length}');
  stdout.writeln('Files with hits: ${worklist.length}');
  stdout.writeln('.arb files updated: 8 (en + 7 target locales)');
  stdout.writeln('Worklist: $_todoPath');
}
