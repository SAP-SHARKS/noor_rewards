// Level-2 codemod: apply the wraps described in TODO_I18N.md to the
// actual .dart source.
//
// SAFETY RULES (strict — anything failing a rule is left for manual pass):
//   R1. File must already import 'package:.../app_localizations.dart'.
//   R2. Literal must NOT contain Dart interpolation (`$var` / `${expr}`).
//   R3. Literal must NOT contain \n (multi-line prose).
//   R4. Literal must appear EXACTLY once on the target line
//       (both single- and double-quoted forms tried).
//   R5. The character immediately before the opening quote must NOT
//       introduce a const/case/enum-value context:
//         - `const ` prefix within the last 20 chars
//         - `case ` starting the trimmed line
//         - `static const ` earlier in the line
//         - inside a map literal key position (`key: 'literal'` where the
//           enclosing structure looks like a Map — skip if line has
//           `<String, String>` on it)
//   R6. Wrap only these host patterns:
//         - `Text('literal', ...)`  →  `Text(AppLocalizations.of(context)?.<key> ?? 'literal', ...)`
//         - `title: 'literal'` (and label/hintText/tooltip/semanticsLabel/
//            errorText/helperText/subtitle/body/message/placeholder/hint/
//            confirmText/cancelText/okText/buttonText)
//   R7. On success, run `flutter analyze <file>` after each file.
//       If NEW errors appear, revert the file to its previous contents.
//
// Usage:
//   dart run scripts/wrap_dart_i18n.dart --dry-run   # report only, no writes
//   dart run scripts/wrap_dart_i18n.dart             # apply

import 'dart:convert';
import 'dart:io';

const _todoPath = 'TODO_I18N.md';
const _wrappableProps = {
  'title', 'label', 'hintText', 'tooltip', 'semanticsLabel',
  'errorText', 'helperText', 'subtitle', 'body', 'message',
  'placeholder', 'hint', 'confirmText', 'cancelText', 'okText',
  'buttonText', 'labelText', 'header',
  // Broadening pass 2 — safe additions.
  // 'text' is TextSpan/RichText content — deliberately UI.
  // 'description' / 'caption' / 'heading' are widely used render props.
  'text', 'description', 'caption', 'heading',
};

class _Hit {
  final int line;
  final String key;
  final String literal;
  _Hit(this.line, this.key, this.literal);
}

Map<String, List<_Hit>> _parseTodo(String md) {
  final byFile = <String, List<_Hit>>{};
  String? currentFile;
  int? curLine;
  String? curKey;
  final lines = md.split('\n');
  for (final l in lines) {
    final fileMatch = RegExp(r'^## (lib/[^\s(]+)').firstMatch(l);
    if (fileMatch != null) {
      currentFile = fileMatch.group(1);
      byFile.putIfAbsent(currentFile!, () => []);
      continue;
    }
    final hitMatch = RegExp(r'^- \[ \] L(\d+) \\\[[^\]]+\\\] `([^`]+)`').firstMatch(l);
    if (hitMatch != null) {
      curLine = int.parse(hitMatch.group(1)!);
      curKey = hitMatch.group(2);
      continue;
    }
    final litMatch = RegExp(r'^\s*- literal: `"(.*)"`').firstMatch(l);
    if (litMatch != null && currentFile != null && curLine != null && curKey != null) {
      final literal = litMatch.group(1)!;
      byFile[currentFile]!.add(_Hit(curLine!, curKey!, literal));
      curLine = null;
      curKey = null;
    }
  }
  return byFile;
}

bool _fileImportsAppLocalizations(String content) {
  return content.contains('app_localizations.dart') ||
      content.contains('AppLocalizations');
}

bool _literalHasInterpolation(String literal) {
  // JSON-decoded literal — check for $ patterns.
  return literal.contains(r'$');
}

/// Extract Dart interpolation expressions from a literal, in source order.
/// `$foo` → 'foo';  `${obj.field}` → 'obj.field'
List<String> _extractInterpExpressions(String literal) {
  final out = <String>[];
  final re = RegExp(r'\$\{([^}]+)\}|\$([a-zA-Z_][a-zA-Z0-9_]*)');
  for (final m in re.allMatches(literal)) {
    out.add(m.group(1) ?? m.group(2)!);
  }
  return out;
}

bool _literalIsMultiline(String literal) {
  return literal.contains(r'\n') || literal.contains('\n');
}

/// Locate the exact quoted form of `literal` on `line`. Returns null if
/// the literal is not present exactly once.
({int start, int end, String quote})? _locateLiteral(String line, String literal) {
  for (final quote in ["'", '"']) {
    // The literal in TODO_I18N.md has any embedded quotes escaped as-is
    // (Dart source form). Try the raw form first.
    final needle = '$quote$literal$quote';
    final idx = line.indexOf(needle);
    if (idx < 0) continue;
    final second = line.indexOf(needle, idx + 1);
    if (second >= 0) return null; // ambiguous
    return (start: idx, end: idx + needle.length, quote: quote);
  }
  return null;
}

/// True if the position sits inside a const or case context.
bool _inUnsafeContext(String line, int litStart) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('case ')) return true;
  // `const ` within the 25 chars before the literal → const constructor.
  final start = (litStart - 25).clamp(0, line.length);
  final windowBefore = line.substring(start, litStart);
  if (RegExp(r'\bconst\b').hasMatch(windowBefore)) return true;
  // Map<String, String> on the line → likely a map literal.
  if (RegExp(r'<\s*String\s*,\s*String\s*>').hasMatch(line)) return true;
  // `static const ` anywhere on the line
  if (RegExp(r'\bstatic\s+const\b').hasMatch(line)) return true;
  return false;
}

/// Track whether we're inside a `static const List<...>` / `static const Map<...>` /
/// `const [` / `const {` initializer that opened on an earlier line and hasn't
/// closed yet. Uses a simple bracket-count of `[` and `{` since the open.
bool _insidePendingConstCollection(List<String> lines, int lineIdx) {
  final opens = <int>[]; // stack of line indices where a const collection opened
  for (var k = 0; k < lineIdx; k++) {
    final l = lines[k];
    // Opening: `static const List<...>` `= [` OR `static const Map<...>` `= {`
    //          or `const [` / `const {` as an expression.
    final openMatch = RegExp(
      r'\bstatic\s+const\s+(?:List|Map|Set)\b|=\s*const\s*[\[\{]|(?<![a-zA-Z0-9_])const\s*<[^>]*>\s*[\[\{]|(?<![a-zA-Z0-9_])const\s*[\[\{]',
    ).hasMatch(l);
    if (openMatch) opens.add(k);
    if (opens.isEmpty) continue;
    // Close when we see `];` `};` `],` `},` — cheap heuristic ignoring nesting
    if (RegExp(r'^\s*[\]\}]\s*[;,]?').hasMatch(l)) {
      opens.removeLast();
    }
  }
  return opens.isNotEmpty;
}

/// Detect the host pattern:
///   - Text('literal', ...)
///   - <propName>: 'literal'
///   - literal on the line immediately after `Text(` / `SelectableText(` /
///     `AutoSizeText(` (formatter-broken)
/// Returns 'text' | propName | null (not a wrappable host).
String? _detectHostPattern(List<String> lines, int lineIdx, int litStart) {
  final line = lines[lineIdx];
  // GUARD FIRST: reject record literals. If the line starts with `(` after
  // leading whitespace, we're inside a Dart 3 record — `(text: 'x', big: false)`
  // — the `text:` is a record field, not a widget prop.
  if (line.trimLeft().startsWith('(')) return null;
  // Look at the characters immediately before the literal quote.
  final beforeRaw = line.substring(0, litStart);
  final before = beforeRaw.trimRight();
  // Text( pattern
  if (before.endsWith('Text(')) return 'text';
  if (before.endsWith('SelectableText(')) return 'text';
  if (before.endsWith('AutoSizeText(')) return 'text';
  // <propName>: pattern
  final propMatch = RegExp(r'([a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*$').firstMatch(before);
  if (propMatch != null) {
    final prop = propMatch.group(1)!;
    if (_wrappableProps.contains(prop)) return prop;
  }
  // Multi-line Text( on previous line, literal alone on this line:
  //   Text(
  //     'literal',
  //     style: ...
  //   )
  if (before.trim().isEmpty) {
    // Look at the previous non-empty line for `Text(` / etc.
    for (var k = lineIdx - 1; k >= 0 && k >= lineIdx - 3; k--) {
      final prev = lines[k].trimRight();
      if (prev.isEmpty) continue;
      if (prev.endsWith('Text(') ||
          prev.endsWith('SelectableText(') ||
          prev.endsWith('AutoSizeText(')) {
        return 'text';
      }
      // <propName>: at end of prev line means multi-line named arg
      final m = RegExp(r'([a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*$').firstMatch(prev);
      if (m != null && _wrappableProps.contains(m.group(1))) {
        return m.group(1);
      }
      // Any other content on prev line — this isn't a multi-line Text.
      break;
    }
  }
  return null;
}

/// Whether `final l = AppLocalizations.of(context);` is in scope in the
/// nearest enclosing method. Walks backward and stops at the FIRST method
/// signature encountered — declarations in outer methods aren't visible.
bool _hasLocalL(List<String> lines, int lineIdx) {
  final methodSig = RegExp(
    r'^\s*(?:@\w+\s+)*'
    r'(?:static\s+)?(?:final\s+)?(?:const\s+)?'
    r'(?:Future\s*<[^>]*>\s+|void\s+|Widget\s+|[A-Z]\w*(?:<[^>]*>)?\s+)?'
    r'[_a-zA-Z]\w*\s*\([^)]*\)\s*(?:async\s*\*?\s*)?[{=]',
  );
  for (var k = lineIdx - 1; k >= 0 && k >= lineIdx - 300; k--) {
    final l = lines[k];
    if (RegExp(r'\bfinal\s+l\s*=\s*AppLocalizations\.of\(').hasMatch(l)) {
      return true;
    }
    if (methodSig.hasMatch(l)) return false;
    if (RegExp(r'^\s*(?:abstract\s+)?class\s+').hasMatch(l)) return false;
  }
  return false;
}

/// True if the nearest enclosing method/function does NOT have a
/// `BuildContext context` param in scope.
///
/// Walks backward from `lineIdx` to the first method signature it finds.
/// - If that signature has `(BuildContext context)` → false (safe).
/// - If it has `(BuildContext someOtherName)` → true (unsafe: name mismatch).
/// - If it has no BuildContext param at all → true.
/// - If we reach a class boundary before any method → true.
///
/// Only stops at signature lines matching `\w+\s+\w+\s*\([...]\)\s*(async\s*)?{?`
/// (with or without return type), tolerant to leading `Future<...>`, `Widget`, etc.
/// Return the BuildContext parameter name in scope for the enclosing method
/// (usually 'context', sometimes 'ctx'). Returns null if BuildContext is not
/// available at all (CustomPainter, service classes, etc.).
String? _buildContextName(List<String> lines, int lineIdx) {
  final sigRegex = RegExp(
    r'^\s*(?:@\w+\s+)*'
    r'(?:static\s+)?(?:final\s+)?(?:const\s+)?'
    r'(?:Future\s*<[^>]*>\s+|void\s+|Widget\s+|[A-Z]\w*(?:<[^>]*>)?\s+)?'
    r'([_a-zA-Z]\w*)\s*'
    r'\(([^)]*)\)\s*'
    r'(?:async\s*\*?\s*)?[{=]',
  );
  final sigRegexOpen = RegExp(
    r'^\s*(?:@\w+\s+)*'
    r'(?:static\s+)?(?:final\s+)?(?:const\s+)?'
    r'(?:Future\s*<[^>]*>\s+|void\s+|Widget\s+|[A-Z]\w*(?:<[^>]*>)?\s+)?'
    r'([_a-zA-Z]\w*)\s*'
    r'\(([^)]*)$',
  );
  for (var k = lineIdx - 1; k >= 0 && k >= lineIdx - 400; k--) {
    final l = lines[k];
    if (RegExp(r'^\s*(?:abstract\s+)?class\s+\w+').hasMatch(l)) return null;
    final m = sigRegex.firstMatch(l) ?? sigRegexOpen.firstMatch(l);
    if (m == null) continue;
    var params = m.group(2)!;
    if (sigRegex.firstMatch(l) == null && sigRegexOpen.firstMatch(l) != null) {
      for (var j = k + 1; j < lines.length && j < k + 8; j++) {
        final part = lines[j];
        final closeIdx = part.indexOf(')');
        if (closeIdx >= 0) {
          params += ' ${part.substring(0, closeIdx)}';
          break;
        }
        params += ' $part';
      }
    }
    final ctxMatch =
        RegExp(r'\bBuildContext\s+([_a-zA-Z]\w*)').firstMatch(params);
    if (ctxMatch != null) return ctxMatch.group(1);
    return null;
  }
  return null;
}

bool _contextNotAvailable(List<String> lines, int lineIdx) {
  // Regex that matches typical method / top-level function signatures.
  // Deliberately conservative — we want to STOP as soon as we cross into
  // an enclosing method so we can inspect its parameter list.
  //
  // The params clause `\(([^)]*)\)` requires the ENTIRE param list on one
  // line. For multi-line signatures (spread over 2+ lines), we walk each
  // line and if it starts with a method-like prefix we accept whatever
  // params we can capture.
  final sigRegex = RegExp(
    r'^\s*(?:@\w+\s+)*'                              // annotations
    r'(?:static\s+)?(?:final\s+)?(?:const\s+)?'      // modifiers
    r'(?:Future\s*<[^>]*>\s+|void\s+|Widget\s+|[A-Z]\w*(?:<[^>]*>)?\s+)?' // return type
    r'([_a-zA-Z]\w*)\s*'                             // method name
    r'\(([^)]*)\)\s*'                                // params
    r'(?:async\s*\*?\s*)?[{=]',                      // body opener
  );

  // Additional signature regex — matches multi-line param lists (open paren
  // present, but no close paren on same line).
  final sigRegexOpen = RegExp(
    r'^\s*(?:@\w+\s+)*'
    r'(?:static\s+)?(?:final\s+)?(?:const\s+)?'
    r'(?:Future\s*<[^>]*>\s+|void\s+|Widget\s+|[A-Z]\w*(?:<[^>]*>)?\s+)?'
    r'([_a-zA-Z]\w*)\s*'
    r'\(([^)]*)$',
  );

  for (var k = lineIdx - 1; k >= 0 && k >= lineIdx - 400; k--) {
    final l = lines[k];
    // Class boundary — no enclosing method found.
    if (RegExp(r'^\s*(?:abstract\s+)?class\s+\w+').hasMatch(l)) {
      return true;
    }
    final m = sigRegex.firstMatch(l) ?? sigRegexOpen.firstMatch(l);
    if (m == null) continue;
    final params = m.group(2)!;
    // If it's an open (multi-line) signature, collect the rest of the params
    // by walking forward until we see the close paren.
    var fullParams = params;
    if (sigRegex.firstMatch(l) == null && sigRegexOpen.firstMatch(l) != null) {
      for (var j = k + 1; j < lines.length && j < k + 8; j++) {
        final part = lines[j];
        final closeIdx = part.indexOf(')');
        if (closeIdx >= 0) {
          fullParams += ' ${part.substring(0, closeIdx)}';
          break;
        }
        fullParams += ' $part';
      }
    }
    // Method has `BuildContext context` in the param list → safe.
    if (RegExp(r'\bBuildContext\s+context\b').hasMatch(fullParams)) return false;
    // Method has `BuildContext <otherName>` → unsafe (we'd have to rename).
    // Method has no BuildContext at all → unsafe.
    return true;
  }
  return true;
}

String _buildReplacement(
    String key, String quote, String literal, bool useLocalL, String ctxName) {
  final getterBase =
      useLocalL ? 'l?.$key' : 'AppLocalizations.of($ctxName)?.$key';
  // Interpolation → generate a method call with the raw expressions,
  // wrapping each in `.toString()` because the generated AppLocalizations
  // methods declare placeholders as `String` (the default). Calling
  // `.toString()` on a String is a no-op; on ints/Exceptions it's the
  // same conversion Dart string interpolation would perform.
  final exprs = _extractInterpExpressions(literal);
  final getter = exprs.isEmpty
      ? getterBase
      : '$getterBase(${exprs.map((e) => '($e).toString()').join(', ')})';
  return '$getter ?? $quote$literal$quote';
}

Future<bool> _analyzeFile(String path) async {
  final r = await Process.run('flutter', ['analyze', path],
      runInShell: Platform.isWindows);
  return r.exitCode == 0;
}

Future<Map<String, dynamic>> _analyzeCount(String path) async {
  final r = await Process.run('flutter', ['analyze', path],
      runInShell: Platform.isWindows);
  final out = (r.stdout as String) + (r.stderr as String);
  final errors = RegExp(r'\berror\b -').allMatches(out).length;
  return {'errors': errors, 'exit': r.exitCode, 'out': out};
}

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final onlyFile = args.firstWhere((a) => a.startsWith('--only='),
      orElse: () => '').replaceFirst('--only=', '');

  // Pre-regenerate the AppLocalizations bindings so analyze sees any keys
  // added since the last codegen. Without this, the first analyzer call
  // uses stale bindings and reports false `undefined_method` errors that
  // trigger unnecessary reverts.
  if (!dryRun) {
    stdout.writeln('Pre-generating l10n bindings…');
    await Process.run('flutter', ['gen-l10n'],
        runInShell: Platform.isWindows);
  }

  final md = File(_todoPath).readAsStringSync();
  final byFile = _parseTodo(md);

  var totalHits = 0;
  var totalWrapped = 0;
  var totalSkipped = 0;
  final skippedReasons = <String, int>{};
  final wrappedByFile = <String, int>{};
  final revertedFiles = <String>[];

  final files = byFile.keys.toList()..sort();

  for (final path in files) {
    if (onlyFile.isNotEmpty && path != onlyFile) continue;

    final f = File(path);
    if (!f.existsSync()) {
      stderr.writeln('Missing: $path');
      continue;
    }
    final originalContent = f.readAsStringSync();
    if (!_fileImportsAppLocalizations(originalContent)) {
      // R1 violation — whole-file skip.
      final n = byFile[path]!.length;
      totalHits += n;
      totalSkipped += n;
      skippedReasons.update('R1_no_import', (v) => v + n, ifAbsent: () => n);
      continue;
    }

    final lines = originalContent.split('\n');
    final hits = byFile[path]!;
    var wrapped = 0;
    // Sort DESC so earlier edits don't shift later line indices (same-line
    // edits are done via string replacement below, but sorting DESC keeps
    // the mental model simple).
    hits.sort((a, b) => b.line.compareTo(a.line));

    for (final hit in hits) {
      totalHits++;
      if (_literalHasInterpolation(hit.literal)) {
        // R2b: interpolation is now supported IF every extracted expression
        // is a "simple" Dart expression — a bare identifier, a chained
        // access, or a `.method()` call with no nested string literals
        // and no ternary/logical ops. Anything more complex (nested quotes,
        // conditional expressions) risks generating a syntactically bad
        // arg list — leave those for manual.
        final exprs = _extractInterpExpressions(hit.literal);
        final unsafe = exprs.any((e) {
          final t = e.trim();
          if (t.isEmpty) return true;
          // Nested string literal — could break arg parsing on our end
          // when combined with quote flipping.
          if (t.contains("'") || t.contains('"')) return true;
          // Ternary / logical / control flow
          if (t.contains('?') || t.contains('&&') || t.contains('||')) return true;
          // Nested interpolation
          if (t.contains(r'$')) return true;
          return false;
        });
        if (unsafe) {
          totalSkipped++;
          skippedReasons.update('R2_interpolation_complex', (v) => v + 1, ifAbsent: () => 1);
          continue;
        }
      }
      if (_literalIsMultiline(hit.literal)) {
        totalSkipped++;
        skippedReasons.update('R3_multiline', (v) => v + 1, ifAbsent: () => 1);
        continue;
      }
      final lineIdx = hit.line - 1;
      if (lineIdx < 0 || lineIdx >= lines.length) {
        totalSkipped++;
        skippedReasons.update('R_out_of_range', (v) => v + 1, ifAbsent: () => 1);
        continue;
      }
      final line = lines[lineIdx];
      final loc = _locateLiteral(line, hit.literal);
      if (loc == null) {
        totalSkipped++;
        skippedReasons.update('R4_not_found_or_ambiguous', (v) => v + 1, ifAbsent: () => 1);
        continue;
      }
      if (_inUnsafeContext(line, loc.start)) {
        totalSkipped++;
        skippedReasons.update('R5_const_or_case', (v) => v + 1, ifAbsent: () => 1);
        continue;
      }
      if (_insidePendingConstCollection(lines, lineIdx)) {
        totalSkipped++;
        skippedReasons.update('R5_const_collection', (v) => v + 1, ifAbsent: () => 1);
        continue;
      }
      final host = _detectHostPattern(lines, lineIdx, loc.start);
      if (host == null) {
        totalSkipped++;
        skippedReasons.update('R6_host_not_wrappable', (v) => v + 1, ifAbsent: () => 1);
        if (args.contains('--debug-r6')) {
          stderr.writeln('R6 $path:${hit.line} ${line.trim()}');
        }
        continue;
      }
      final useLocalL = _hasLocalL(lines, lineIdx);
      // R7: BuildContext unavailable (CustomPainter, service classes, etc.)
      // Only permit inline `AppLocalizations.of(<ctx>)?.` when a BuildContext
      // parameter is actually in scope. If `l` local exists we're fine either
      // way.
      final ctxName = _buildContextName(lines, lineIdx);
      if (args.contains('--debug-r7')) {
        stderr.writeln('R7? $path:${hit.line} useLocalL=$useLocalL ctxName=$ctxName');
      }
      if (!useLocalL && ctxName == null) {
        totalSkipped++;
        skippedReasons.update('R7_no_build_context', (v) => v + 1, ifAbsent: () => 1);
        continue;
      }
      final replacement = _buildReplacement(
          hit.key, loc.quote, hit.literal, useLocalL, ctxName ?? 'context');
      final newLine =
          line.substring(0, loc.start) + replacement + line.substring(loc.end);
      lines[lineIdx] = newLine;
      if (args.contains('--debug-wraps')) {
        stderr.writeln('WRAP $path:${hit.line} [$host] $line');
      }
      wrapped++;
      totalWrapped++;
    }

    if (wrapped == 0) continue;
    wrappedByFile[path] = wrapped;

    if (dryRun) continue;

    // Get baseline error count on the ORIGINAL file, then compare after write.
    final beforeAnalyze = await _analyzeCount(path);
    final newContent = lines.join('\n');
    f.writeAsStringSync(newContent);
    final afterAnalyze = await _analyzeCount(path);

    if ((afterAnalyze['errors'] as int) > (beforeAnalyze['errors'] as int)) {
      // Revert.
      f.writeAsStringSync(originalContent);
      revertedFiles.add(path);
      totalWrapped -= wrapped;
      wrappedByFile.remove(path);
      stderr.writeln(
          'REVERTED $path (new errors: ${afterAnalyze['errors']} > ${beforeAnalyze['errors']})');
      if (args.contains('--debug-revert')) {
        final out = afterAnalyze['out'] as String;
        for (final l in out.split('\n')) {
          if (l.contains('error -') || l.contains('  error ')) {
            stderr.writeln('  $l');
          }
        }
      }
    } else {
      stdout.writeln('OK  $path : wrapped $wrapped');
    }
  }

  stdout.writeln('');
  stdout.writeln('=== wrap_dart_i18n.dart ${dryRun ? "(DRY RUN)" : ""} ===');
  stdout.writeln('Files considered: ${files.length}');
  stdout.writeln('Total hits: $totalHits');
  stdout.writeln('Wrapped: $totalWrapped');
  stdout.writeln('Skipped: $totalSkipped');
  stdout.writeln('Reverted files: ${revertedFiles.length}');
  if (revertedFiles.isNotEmpty) {
    for (final r in revertedFiles) {
      stdout.writeln('  reverted: $r');
    }
  }
  stdout.writeln('');
  stdout.writeln('Skip reasons:');
  final sortedReasons = skippedReasons.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final e in sortedReasons) {
    stdout.writeln('  ${e.value.toString().padLeft(5)}  ${e.key}');
  }
  stdout.writeln('');
  stdout.writeln('Wrapped per file:');
  final sortedFiles = wrappedByFile.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final e in sortedFiles.take(20)) {
    stdout.writeln('  ${e.value.toString().padLeft(5)}  ${e.key}');
  }
}
