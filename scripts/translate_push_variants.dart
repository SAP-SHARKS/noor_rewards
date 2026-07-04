// Machine-translate the English rows in notification_variants into all 7
// non-EN locales and emit a Supabase migration SQL file with the
// INSERTs. Uses the same free Google Translate endpoint the
// auto-translate-project / auto-translate-orphan Edge Functions use,
// and the same ICU-token-preservation trick from `translate_arb.dart`.
//
// Input:  supabase/migrations/20260624_020_notification_variants.sql
// Output: supabase/migrations/<datestamp>_notification_variants_i18n.sql
//
// Usage:  dart run scripts/translate_push_variants.dart
//
// Environment: TRANSLATE_DELAY_MS (default 200)

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _seedPath =
    'supabase/migrations/20260624_020_notification_variants.sql';
const _locales = ['ar', 'ur', 'fr', 'id', 'ms', 'ru', 'tr'];

int _delayMs = 200;

class Variant {
  final String type;
  final String title;
  final String body;
  final String? route;
  Variant(this.type, this.title, this.body, this.route);
}

/// Parse rows of the form:
///   ('streak_at_risk', 'en', 'Title', 'Body body', 'route'),
///
/// Uses a small state machine so single-quoted content with embedded
/// SQL-escaped `''` (doubled single quote → literal `'`) parses cleanly.
List<Variant> _parseSeed(String sql) {
  final rows = <Variant>[];
  final lines = sql.split('\n');
  for (final raw in lines) {
    if (!raw.trimLeft().startsWith("('")) continue;
    // Strip trailing whitespace + trailing `),` or `);`
    var line = raw.trimRight();
    if (line.endsWith(',')) line = line.substring(0, line.length - 1);
    if (!line.endsWith(')')) continue;
    // Strip outer parens.
    line = line.substring(1, line.length - 1);

    // State-machine tokenise on top-level commas, respecting single-quoted
    // strings with SQL-escaped `''`.
    final tokens = <String>[];
    final buf = StringBuffer();
    var inStr = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (inStr) {
        if (c == "'") {
          if (i + 1 < line.length && line[i + 1] == "'") {
            buf.write("'");
            i++;
          } else {
            inStr = false;
          }
        } else {
          buf.write(c);
        }
      } else {
        if (c == "'") {
          inStr = true;
        } else if (c == ',') {
          tokens.add(buf.toString().trim());
          buf.clear();
        } else if (c == ' ') {
          // ignore top-level whitespace
        } else {
          buf.write(c);
        }
      }
    }
    tokens.add(buf.toString().trim());
    // Expect 5 tokens: type, locale, title, body, route
    if (tokens.length != 5) continue;
    final locale = tokens[1];
    if (locale != 'en') continue;
    final route = tokens[4] == 'NULL' ? null : tokens[4];
    rows.add(Variant(tokens[0], tokens[2], tokens[3], route));
  }
  return rows;
}

Uri _uri(String text, String target) => Uri.parse(
      'https://translate.googleapis.com/translate_a/single'
      '?client=gtx&sl=en&tl=${Uri.encodeComponent(target)}&dt=t&q=${Uri.encodeComponent(text)}',
    );

Future<String?> _translate(HttpClient client, String text, String target) async {
  if (text.trim().isEmpty) return text;
  try {
    final req = await client.getUrl(_uri(text, target));
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

Future<String?> _translatePreservingIcu(
    HttpClient client, String text, String target) async {
  final tokenRe = RegExp(r'\{[^}]+\}');
  final tokens = tokenRe.allMatches(text).map((m) => m.group(0)!).toList();
  if (tokens.isEmpty) return _translate(client, text, target);
  var i = 0;
  final marked = text.replaceAllMapped(tokenRe, (_) => '__P${i++}__');
  final translated = await _translate(client, marked, target);
  if (translated == null) return null;
  var restored = translated;
  for (var k = 0; k < tokens.length; k++) {
    restored = restored.replaceAll('__P${k}__', tokens[k]);
    restored = restored.replaceAll('__p${k}__', tokens[k]);
    restored = restored.replaceAll('__ P${k} __', tokens[k]);
  }
  if (restored.contains(RegExp(r'__P?\d+__'))) {
    return _translate(client, text, target);
  }
  return restored;
}

/// SQL-escape a single-quoted literal: double every `'`.
String _sq(String? v) => v == null ? 'NULL' : "'${v.replaceAll("'", "''")}'";

Future<void> main() async {
  final delayEnv = Platform.environment['TRANSLATE_DELAY_MS'];
  if (delayEnv != null) _delayMs = int.tryParse(delayEnv) ?? _delayMs;

  final seed = File(_seedPath).readAsStringSync();
  final variants = _parseSeed(seed);
  stdout.writeln('Parsed ${variants.length} English variants from seed.');

  final client = HttpClient();
  client.userAgent = 'Sabiq-i18n-batch/1.0';

  final outLines = <String>[
    '-- Machine-translated push-notification variants for the 7 non-EN',
    '-- locales. Generated by scripts/translate_push_variants.dart from',
    '-- 20260624_020_notification_variants.sql seed rows. Uses Google',
    '-- Translate free endpoint — same one auto-translate-project and',
    '-- auto-translate-orphan use. ICU {placeholder} tokens preserved.',
    '--',
    '-- Idempotency: `unique_variants_active` index on (notification_type,',
    '-- locale, active) means duplicate INSERTs would fail on rerun. Use',
    '-- ON CONFLICT DO NOTHING so re-applying this migration is safe.',
    '',
    'INSERT INTO public.notification_variants',
    '  (notification_type, locale, title, body, route)',
    'VALUES',
  ];

  final valueLines = <String>[];
  var done = 0;
  final total = variants.length * _locales.length;
  final start = DateTime.now();
  for (final v in variants) {
    for (final loc in _locales) {
      final title = await _translatePreservingIcu(client, v.title, loc);
      final body = await _translatePreservingIcu(client, v.body, loc);
      if (title == null || body == null) {
        stderr.writeln('[skip] ${v.type} → $loc failed');
        done++;
        continue;
      }
      valueLines.add(
        '  (${_sq(v.type)}, ${_sq(loc)}, ${_sq(title)}, ${_sq(body)}, ${_sq(v.route)})',
      );
      done++;
      if (done % 20 == 0) {
        final elapsed = DateTime.now().difference(start);
        final rate = done / elapsed.inSeconds.clamp(1, 1 << 30);
        final remaining = total - done;
        final etaSec = rate > 0 ? (remaining / rate).round() : 0;
        stdout.writeln('progress: $done/$total (~${etaSec}s remaining)');
      }
      await Future<void>.delayed(Duration(milliseconds: _delayMs));
    }
  }
  client.close(force: true);

  outLines.add(valueLines.join(',\n'));
  outLines.add('ON CONFLICT DO NOTHING;');
  outLines.add('');

  final now = DateTime.now().toUtc();
  final stamp = '${now.year}${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}';
  final outPath =
      'supabase/migrations/${stamp}_010_notification_variants_i18n.sql';
  File(outPath).writeAsStringSync(outLines.join('\n'));
  stdout.writeln('===');
  stdout.writeln('DONE — ${valueLines.length} rows written to $outPath');
  stdout.writeln('Review, then: supabase db push  (or run in Studio SQL editor)');
}
