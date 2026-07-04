// Machine-translate the English placeholders in a non-EN .arb file using
// the same free Google Translate endpoint as the `auto-translate-orphan`
// Edge Function.
//
// - Only touches keys whose current value EQUALS the EN value (i.e.
//   untranslated placeholders). Existing human translations are
//   preserved.
// - ICU `{placeholder}` tokens are extracted and re-inserted verbatim
//   after translation so runtime substitution still works.
// - Writes back to the .arb after every batch, so the script is fully
//   resumable — kill it any time and re-run.
// - Small polite delay between calls to avoid rate-limiting.
//
// Usage:
//   dart run scripts/translate_arb.dart ur          # translate Urdu
//   dart run scripts/translate_arb.dart ur ar fr    # multiple locales
//   dart run scripts/translate_arb.dart all         # all 7 non-EN
//
// Environment:
//   TRANSLATE_DELAY_MS   — override the per-request delay (default 200)
//   TRANSLATE_LIMIT      — stop after N translations (for testing)

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _allLocales = ['ur', 'ar', 'fr', 'id', 'ms', 'ru', 'tr'];
const _enArbPath = 'lib/l10n/app_en.arb';

int _delayMs = 200;
int _limit = 1 << 30; // effectively unlimited

/// Google Translate free web endpoint — same one auto-translate-orphan uses.
Uri _translateUri(String text, String target) => Uri.parse(
      'https://translate.googleapis.com/translate_a/single'
      '?client=gtx&sl=en&tl=${Uri.encodeComponent(target)}&dt=t&q=${Uri.encodeComponent(text)}',
    );

Future<String?> _translate(HttpClient client, String text, String target) async {
  if (text.trim().isEmpty) return null;
  try {
    final req = await client.getUrl(_translateUri(text, target));
    req.headers.set('User-Agent',
        'Mozilla/5.0 (compatible; Sabiq-i18n-batch/1.0)');
    final res = await req.close().timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    final body = await res.transform(utf8.decoder).join();
    final decoded = jsonDecode(body);
    if (decoded is! List) return null;
    final segments = decoded[0];
    if (segments is! List) return null;
    final buf = StringBuffer();
    for (final seg in segments) {
      if (seg is List && seg.isNotEmpty && seg[0] is String) {
        buf.write(seg[0] as String);
      }
    }
    final out = buf.toString().trim();
    return out.isEmpty ? null : out;
  } catch (_) {
    return null;
  }
}

/// Extract `{placeholder}` tokens, translate the surrounding text with
/// tokens replaced by sentinels the MT won't touch, then re-insert.
///
/// Strategy: replace each `{x}` with a placeholder marker like `__P0__`,
/// `__P1__`, ... . Google Translate preserves such tokens verbatim in
/// most languages. After translation we restore the original tokens by
/// mapping the markers back.
Future<String?> _translatePreservingIcu(
    HttpClient client, String text, String target) async {
  final tokenRe = RegExp(r'\{[^}]+\}');
  final tokens = tokenRe.allMatches(text).map((m) => m.group(0)!).toList();
  if (tokens.isEmpty) {
    return _translate(client, text, target);
  }
  // Replace tokens with markers. Use two underscores + digits + two
  // underscores — Google Translate very rarely alters this pattern.
  var i = 0;
  final marked = text.replaceAllMapped(tokenRe, (_) => '__P${i++}__');
  final translated = await _translate(client, marked, target);
  if (translated == null) return null;
  var restored = translated;
  for (var k = 0; k < tokens.length; k++) {
    restored = restored.replaceAll('__P${k}__', tokens[k]);
    // Some MT outputs lowercase or split the marker across whitespace.
    // Handle common variants.
    restored = restored.replaceAll('__p${k}__', tokens[k]);
    restored = restored.replaceAll('__ P${k} __', tokens[k]);
  }
  // If any marker survived intact, the MT likely failed on this string —
  // fall back to a plain translation without protection.
  if (restored.contains(RegExp(r'__P?\d+__'))) {
    return _translate(client, text, target);
  }
  return restored;
}

Future<int> _processLocale(String loc, Map<String, dynamic> en) async {
  final path = 'lib/l10n/app_$loc.arb';
  final file = File(path);
  final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  final untranslated = <String>[];
  final enKeys = en.keys
      .where((k) => !k.startsWith('@') && k != '@@locale')
      .toList();
  for (final k in enKeys) {
    final ev = en[k];
    final lv = map[k];
    if (ev is String && lv is String && ev == lv && ev.trim().isNotEmpty) {
      untranslated.add(k);
    }
  }
  stdout.writeln('[$loc] ${untranslated.length} placeholders to translate '
      '(of ${enKeys.length} total keys)');

  if (untranslated.isEmpty) return 0;

  final client = HttpClient();
  client.userAgent = 'Sabiq-i18n-batch/1.0';

  var done = 0;
  var failed = 0;
  final start = DateTime.now();
  const saveEvery = 25;

  void persist() {
    final ordered = <String, dynamic>{'@@locale': loc};
    for (final k in enKeys) {
      if (k == '@@locale') continue;
      if (map.containsKey(k)) ordered[k] = map[k];
    }
    // Preserve any orphan keys / @-metadata not in enKeys.
    for (final k in map.keys) {
      if (!ordered.containsKey(k) && k != '@@locale') ordered[k] = map[k];
    }
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(ordered)}\n',
    );
  }

  for (final k in untranslated) {
    if (done >= _limit) break;
    final ev = en[k] as String;
    final translated = await _translatePreservingIcu(client, ev, loc);
    if (translated == null) {
      failed++;
    } else {
      map[k] = translated;
    }
    done++;
    if (done % saveEvery == 0) {
      persist();
      final elapsed = DateTime.now().difference(start);
      final rate = done / elapsed.inSeconds.clamp(1, 1 << 30);
      final remaining = untranslated.length - done;
      final etaSec = rate > 0 ? (remaining / rate).round() : 0;
      stdout.writeln('[$loc] $done/${untranslated.length} '
          '(failed $failed, ~${etaSec}s remaining)');
    }
    // Polite delay between requests.
    await Future<void>.delayed(Duration(milliseconds: _delayMs));
  }
  // Always persist at the end — catches limit-triggered breaks and any
  // trailing entries below the saveEvery threshold.
  persist();
  client.close(force: true);
  stdout.writeln('[$loc] complete — $done translated, $failed failed');
  return done;
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run scripts/translate_arb.dart <locale...|all>');
    exit(64);
  }
  final delayEnv = Platform.environment['TRANSLATE_DELAY_MS'];
  if (delayEnv != null) _delayMs = int.tryParse(delayEnv) ?? _delayMs;
  final limitEnv = Platform.environment['TRANSLATE_LIMIT'];
  if (limitEnv != null) _limit = int.tryParse(limitEnv) ?? _limit;

  final targets = args.contains('all') ? _allLocales : args;
  for (final t in targets) {
    if (!_allLocales.contains(t)) {
      stderr.writeln('Unknown locale: $t (expected one of $_allLocales or "all")');
      exit(64);
    }
  }

  final en = jsonDecode(File(_enArbPath).readAsStringSync())
      as Map<String, dynamic>;
  var total = 0;
  for (final loc in targets) {
    total += await _processLocale(loc, en);
  }
  stdout.writeln('===');
  stdout.writeln('DONE — $total translations across ${targets.length} locale(s)');
  stdout.writeln('Now run: flutter gen-l10n');
}
