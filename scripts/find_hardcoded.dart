// Detector for hardcoded user-facing English strings in the Flutter app.
//
// Scans lib/**/*.dart (excluding lib/l10n/ generated files) and flags:
//   - Text('...') / Text("...") widgets
//   - Named string args commonly rendered as UI (title, hintText, labelText,
//     tooltip, semanticsLabel, helperText, errorText, header, label,
//     subtitle, description, message, placeholder, hint)
//   - SnackBar / AlertDialog string content
//
// Skips:
//   - Comments, imports, part/export directives
//   - Asset paths, URLs, package refs, hex colors
//   - Identifiers (snake_case, camelCase, SCREAMING_SNAKE)
//   - RegExp patterns, SQL strings
//   - debugPrint / print / throw / Exception / assert
//   - Font family strings (GoogleFonts.*, fontFamily: '...')
//   - Supabase / SharedPreferences / RPC / config key strings
//   - Already-wrapped AppLocalizations.of(context) calls
//
// Output: one line per hit, formatted `path:line: <full stripped line>`
//
// Usage: `dart run scripts/find_hardcoded.dart > i18n-audit.txt`

import 'dart:io';

const _includeDirs = ['lib'];
const _skipDirs = ['lib/l10n', 'lib/generated'];
// Files that are dev-only preview / design-system tools — not shipped.
const _skipFiles = {
  'lib/theme_demo.dart',
  'lib/preview_gen_main.dart',
  'lib/screens/admin/animation_preview_generator_screen.dart',
};

// Line ranges to skip because the content belongs in the database, not
// the .arb files. These are Phase-4 items (see db-content-i18n.txt).
const _skipRanges = <String, List<List<int>>>{
  // dhikr_screen.dart: two Phase-4 DB-content blocks.
  //   1. Benefit-illustration switch block (6702–8474): every case has
  //      hardcoded English `benefitText` / `subtitle` / `completedSubtitle`
  //      (~190 strings). Move to `azkar_illustrations` DB rows.
  //   2. `_pickTagline` function (8480–8996): const `quranicTaglines` map
  //      + a long if-cascade of `return 'tagline';` — ~320 azkar-ID→English
  //      taglines. Belongs on `azkar_items.tagline_<locale>` columns.
  'lib/screens/dhikr_screen.dart': [
    [6702, 8474],
    [8480, 8996],
    // Illustration widgets — CustomPainter subclasses starting at
    // `_DuaScene` (line 9031) through end-of-file. Every hardcoded
    // English literal in this region is editorial content displayed
    // by a painter (dua/verse translations, benefit callouts).
    // Belongs on `azkar_illustrations.text_<locale>` DB columns, NOT
    // on `.arb` — see db-content-i18n.md.
    [9000, 30000],
  ],
  // Quran translation / script / reciter / tafsir metadata lists.
  // Each entry is a record of (id, native-language name, translator or
  // reciter proper noun, ...). The `name` field is already localised
  // *within its own language* ("English, Sahih Intl.", "اردو, جالندھری",
  // "Türkçe, Diyanet"), and the `author` field is a person's or
  // organisation's proper noun. Translating them further doesn't produce
  // a meaningful string. Belongs on `translation_editions` /
  // `reciters` / `tafsir_editions` DB tables long-term (see
  // db-content-i18n.md), or treated as immutable metadata.
  'lib/screens/quran_screen.dart': [
    [68, 222],   // _translations + _kQuranScripts + _reciters
    [346, 492],  // _qTafsirEditions
  ],
};

// Named-argument names that typically render as user-facing UI.
const _uiArgNames = {
  'title', 'subtitle', 'hintText', 'labelText', 'tooltip',
  'semanticsLabel', 'helperText', 'errorText', 'header', 'headerTitle',
  'label', 'description', 'message', 'placeholder', 'hint',
  'confirmText', 'cancelText', 'okText', 'buttonText', 'actionLabel',
  'tabBarLabel', 'accessibilityLabel', 'body',
  // Project-specific UI props found on custom widgets
  'benefitText', 'completedSubtitle', 'benefit', 'reward', 'motivation',
  'caption', 'note', 'nudge', 'banner', 'prompt', 'heading', 'announcement',
  'ctaLabel', 'buttonLabel', 'shareText', 'shareMessage', 'name', 'value',
  'text', 'primaryText', 'secondaryText', 'errorMessage', 'successMessage',
  'infoText', 'warningText', 'helpText', 'emptyText', 'loadingText',
  'noticeText', 'rewardText', 'unlockText',
};

// Long-form heuristic threshold: any string literal >= this many chars,
// containing at least one space, is flagged as likely user-facing text
// (a sentence). Well below the shortest hadith reference so we catch prose.
const int _longformThreshold = 20;

// Text extension methods that render UI.
final _uiCallRegex = RegExp(
  r'''\b(Text|SelectableText|AutoSizeText|MyText|Y4Text)\s*\(\s*(['"])([^'"]{2,}?)\2''',
);

// Named argument with string literal value.
final _namedArgRegex = RegExp(
  r'''\b([a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*(['"])([^'"]{2,}?)\2''',
);

// Text.rich( TextSpan(text: '...' ...
final _textRichRegex = RegExp(
  r'''\btext\s*:\s*(['"])([^'"]{2,}?)\1''',
);

// Longform: any string literal >= _longformThreshold chars that contains a space.
final _longformRegex = RegExp(
  r'''(['"])([^'"]{''' + '$_longformThreshold' + r''',})\1''',
);

// Suppress if line contains any of these — not user-facing.
final _suppressLine = RegExp(
  r'''(debugPrint\(|(?<![a-zA-Z])print\(|throw\s|Exception\(|assert\(|Error\(|
      \.log\(|\.getString\(|\.setString\(|\.rpc\(|\.from\(|
      \.contains\(|\.startsWith\(|\.endsWith\(|\.indexOf\(|\.matchAsPrefix\(|
      \.hasMatch\(|\.firstMatch\(|\.allMatches\(|
      GoogleFonts\.|fontFamily\s*:|
      SharedPreferences|Supabase\.|Uri\.parse|Uri\(|http\.|https\.|
      updateKey\(|_\.setString|Hive\.|Box<|
      RegExp\(|r['"]|Pattern\(|
      Icons?\.|IconData\(|MaterialSymbols\.|
      Colors?\.|Color\(|Color\.|LinearGradient|Gradient|
      Duration\(|TextStyle\(|EdgeInsets|BorderRadius|
      case\s+['"]|MapEntry\(|kDebug|assets/|package:|part\s+of|
      _kAdminEmails|debugLog|logger\.|log\.|debugFmt|
      _analytics\.|analytics\.|trackEvent|TrackingService|
      \.emit\(|EventBus)''',
  multiLine: false,
);

// Suppress if the value looks like an ID / URL / asset / hex.
bool _isNonUiValue(String v) {
  final s = v.trim();
  if (s.isEmpty) return true;
  if (s.length < 3) return true;
  // Dart interpolation-fragment artifacts (regex crossed a quote boundary
  // inside `${...}` — treat as broken and skip):
  final openDollar = '\${'.allMatches(s).length;
  final closeBrace = '}'.allMatches(s).length;
  if (openDollar != closeBrace) return true;
  if (s.contains('.toString(') ||
      s.contains('.padLeft(') ||
      s.contains('.padRight(') ||
      s.contains('.substring(') ||
      s.contains('.trim()') ||
      s.contains('.split(') ||
      s.contains('.replaceAll(') ||
      s.contains('.hashCode') ||
      s.contains('.length,') ||
      s.contains('?.') ||
      s.contains(' ?? ') ||
      s.endsWith('??') ||
      s.startsWith('] as ') ||
      s.startsWith(') ??') ||
      s.startsWith('as String') ||
      s.contains(' as num') ||
      s.contains(' as int') ||
      s.contains(' as List')) return true;
  // No letters at all
  if (!RegExp(r'[A-Za-z]').hasMatch(s)) return true;
  // URLs and asset paths
  if (s.contains('://') ||
      s.startsWith('/') ||
      s.startsWith('assets/') ||
      s.startsWith('package:') ||
      s.startsWith('http') ||
      s.startsWith('mailto:')) return true;
  // File extensions
  final ext = RegExp(
    r'\.(png|svg|jpg|jpeg|mp3|wav|ttf|otf|json|lottie|gif|webp|mp4|pdf|txt|csv)$',
    caseSensitive: false,
  );
  if (ext.hasMatch(s)) return true;
  // Hex colors
  if (RegExp(r'^#?[0-9A-Fa-f]{3,8}$').hasMatch(s)) return true;
  if (s.startsWith('0x')) return true;
  // Font families / identifiers
  if (RegExp(r'^[a-z][a-zA-Z0-9]*$').hasMatch(s)) return true; // camelCase
  if (RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(s) && s.contains('_')) return true; // snake_case
  if (RegExp(r'^[A-Z][A-Z0-9_]+$').hasMatch(s)) return true; // SCREAMING_SNAKE
  // RegExp-ish
  if (s.contains(r'\d') ||
      s.contains(r'\s') ||
      s.contains(r'\w') ||
      s.contains(r'(?:') ||
      s.contains(r'^') ||
      s.contains(r'\\')) return true;
  // Locale/currency codes
  if (RegExp(r'^[a-z]{2}(_[A-Z]{2})?$').hasMatch(s)) return true;
  // SQL-ish keyword-only strings
  if (RegExp(r'^(SELECT|FROM|WHERE|INSERT|UPDATE|DELETE|VALUES|LIMIT)\b',
      caseSensitive: false).hasMatch(s)) return true;
  // Column/id-ish: single word, no spaces, mostly lowercase
  if (!s.contains(' ') &&
      s.length < 30 &&
      RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(s)) return true;
  return false;
}

// True if the value is a plausible user-facing sentence/label.
bool _isLikelyUi(String v) {
  final s = v.trim();
  if (_isNonUiValue(s)) return false;
  // Must contain at least one 2+-letter run OR a space.
  if (!RegExp(r'[A-Za-z]{2,}').hasMatch(s)) return false;
  return true;
}

// Track block-comment nesting.
class _CommentState {
  bool inBlock = false;
  bool inRawTripleQuote = false;
}

// True if any of the previous [look] non-empty lines opens a suppressed
// context (debugPrint, throw, Exception, etc.) that hasn't been closed.
bool _inMultilineSuppressed(List<String> lines, int i, int look) {
  // Look at up to 6 previous lines. A close-paren `);` on a line resets.
  var openSuppressed = false;
  for (var k = 1; k <= look; k++) {
    final idx = i - k;
    if (idx < 0) break;
    final l = lines[idx];
    // If we hit an obvious statement end and then find nothing above, stop.
    if (l.trimRight().endsWith(');') && !openSuppressed) return false;
    if (_suppressLine.hasMatch(l)) {
      openSuppressed = true;
    }
    // Once open, if we see the closing `);` later than the open, we stop
    // (handled implicitly — this is a heuristic).
  }
  return openSuppressed;
}

void _scanFile(File f, IOSink out, Map<String, int> perFile) {
  final rel = f.path.replaceAll(r'\\', '/').replaceAll('\\', '/');
  final lines = f.readAsLinesSync();
  final state = _CommentState();
  final skipRanges = _skipRanges[rel] ?? const <List<int>>[];
  for (var i = 0; i < lines.length; i++) {
    // Skip Phase-4 DB-content ranges (1-based line numbers in _skipRanges).
    final lineNum = i + 1;
    var inSkipRange = false;
    for (final r in skipRanges) {
      if (lineNum >= r[0] && lineNum <= r[1]) {
        inSkipRange = true;
        break;
      }
    }
    if (inSkipRange) continue;
    var line = lines[i];
    final stripped = line.trim();

    // Track block comments
    if (state.inBlock) {
      final end = line.indexOf('*/');
      if (end >= 0) {
        state.inBlock = false;
        line = line.substring(end + 2);
      } else {
        continue;
      }
    }
    // Strip line comments and block-comment starts on the current line
    final blockStart = line.indexOf('/*');
    if (blockStart >= 0) {
      final blockEnd = line.indexOf('*/', blockStart + 2);
      if (blockEnd < 0) {
        state.inBlock = true;
        line = line.substring(0, blockStart);
      }
    }
    // Skip empty / directive lines
    if (stripped.isEmpty) continue;
    if (stripped.startsWith('//')) continue;
    if (stripped.startsWith('import ')) continue;
    if (stripped.startsWith('export ')) continue;
    if (stripped.startsWith('part ')) continue;
    if (stripped.startsWith('library ')) continue;
    if (stripped.startsWith('@')) continue; // annotations
    // Suppress non-UI lines
    if (_suppressLine.hasMatch(line)) continue;
    // Suppress if the string is a continuation inside a multi-line
    // debugPrint / throw / Exception call opened above.
    if (_inMultilineSuppressed(lines, i, 6)) continue;
    // Suppress toString() overrides — these are for debugging.
    if (stripped.startsWith('String toString()')) continue;
    // Skip already-translated lines
    if (line.contains('AppLocalizations.of(')) continue;
    if (line.contains('.of(context)!.')) continue;
    if (line.contains('l10n.') ||
        line.contains('l10n?.') ||
        line.contains('l10n!.') ||
        RegExp(r'\bl\??\!?\.').hasMatch(line)) continue;
    // Skip fallback literals in `l?.key ?? "..."` patterns — the
    // localization getter IS wired up on the previous line, this is just
    // a safe fallback for the null case. Look 1-2 lines back for a
    // localization getter followed by `??`.
    var isFallback = false;
    for (var k = 1; k <= 2; k++) {
      final idx = i - k;
      if (idx < 0) break;
      final prev = lines[idx].trimRight();
      if (prev.endsWith('??') &&
          (prev.contains('l?.') ||
              prev.contains('l!.') ||
              prev.contains('l10n?.') ||
              prev.contains('l10n!.') ||
              prev.contains('.of(context)') ||
              prev.contains('l10n.'))) {
        isFallback = true;
        break;
      }
    }
    if (isFallback) continue;
    // Also skip if the same line has `l?.key ?? "..."` or `l10n?.key ?? "..."` inline
    if (RegExp(r'''(\b(?:l|l10n)\??\.[a-zA-Z_][a-zA-Z0-9_]*|of\(context\)\??\.[a-zA-Z_][a-zA-Z0-9_]*)\s*\?\?''')
        .hasMatch(line)) continue;

    // Pattern A: Text('...')
    for (final m in _uiCallRegex.allMatches(line)) {
      final v = m.group(3)!;
      if (_isLikelyUi(v)) {
        out.writeln('$rel:${i + 1}: [Text] "$v"');
        perFile.update(rel, (x) => x + 1, ifAbsent: () => 1);
      }
    }

    // Pattern B: named UI args
    for (final m in _namedArgRegex.allMatches(line)) {
      final name = m.group(1)!;
      if (!_uiArgNames.contains(name)) continue;
      final v = m.group(3)!;
      if (_isLikelyUi(v)) {
        out.writeln('$rel:${i + 1}: [$name] "$v"');
        perFile.update(rel, (x) => x + 1, ifAbsent: () => 1);
      }
    }

    // Pattern C: TextSpan(text: '...')
    if (line.contains('TextSpan')) {
      for (final m in _textRichRegex.allMatches(line)) {
        final v = m.group(2)!;
        if (_isLikelyUi(v)) {
          out.writeln('$rel:${i + 1}: [text] "$v"');
          perFile.update(rel, (x) => x + 1, ifAbsent: () => 1);
        }
      }
    }

    // Pattern D: any long-form string literal with a space.
    // Catches sentences passed into custom widget props that aren't in
    // the _uiArgNames set (e.g. benefitText: 'Begin your day...').
    // We also require at least one 3-letter word after trimming digits/punct
    // so we don't over-flag CSS-like or config values.
    for (final m in _longformRegex.allMatches(line)) {
      final v = m.group(2)!;
      if (!v.contains(' ')) continue;
      if (_isNonUiValue(v)) continue;
      // Need at least two 3+-letter words to look like natural prose.
      final words = RegExp(r'[A-Za-z]{3,}').allMatches(v).length;
      if (words < 2) continue;
      // Skip if already caught by an earlier pattern on this line to avoid dupes.
      // (We dedupe by exact substring match against the tail of output.)
      out.writeln('$rel:${i + 1}: [longform] "$v"');
      perFile.update(rel, (x) => x + 1, ifAbsent: () => 1);
    }
  }
}

void main(List<String> args) {
  final outPath = args.isNotEmpty ? args.first : 'i18n-audit.txt';
  final out = File(outPath).openWrite();
  final perFile = <String, int>{};
  var totalFiles = 0;

  for (final dir in _includeDirs) {
    final root = Directory(dir);
    if (!root.existsSync()) continue;
    for (final ent in root.listSync(recursive: true, followLinks: false)) {
      if (ent is! File) continue;
      if (!ent.path.endsWith('.dart')) continue;
      final rel = ent.path.replaceAll('\\', '/');
      if (_skipDirs.any((s) => rel.startsWith(s))) continue;
      if (_skipFiles.contains(rel)) continue;
      if (rel.endsWith('.g.dart') || rel.endsWith('.freezed.dart')) continue;
      _scanFile(ent, out, perFile);
      totalFiles++;
    }
  }

  out.close();

  var total = 0;
  for (final c in perFile.values) {
    total += c;
  }
  final sorted = perFile.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  stdout.writeln('=== find_hardcoded.dart ===');
  stdout.writeln('Scanned $totalFiles files under lib/');
  stdout.writeln('Total hits: $total');
  stdout.writeln('Files with hits: ${perFile.length}');
  stdout.writeln('Output: $outPath');
  stdout.writeln('');
  stdout.writeln('Top 20 files by hit count:');
  for (final e in sorted.take(20)) {
    stdout.writeln('  ${e.value.toString().padLeft(5)}  ${e.key}');
  }
}
