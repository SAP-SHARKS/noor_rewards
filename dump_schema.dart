import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://fwjzhtcxfiendofnhyzp.supabase.co/rest/v1/';
  final key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ3anpodGN4ZmllbmRvZm5oeXpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzMzkwNDksImV4cCI6MjA4NjkxNTA0OX0.gspfVlCH-S2Cs8_fhOeDWNZN2XH1NC53CJ8riyvJ5nw';
  
  // Try to hit OpenAPI spec to get schema
  final res = await http.get(
    Uri.parse(url),
    headers: { 'apikey': key, 'Authorization': 'Bearer $key' }
  );
  
  if (res.statusCode == 200) {
    final spec = jsonDecode(res.body);
    final definitions = spec['definitions'] as Map<String, dynamic>? ?? {};
    final quranTables = definitions.keys.where((k) => k.contains('quran')).toList();
    print('Quran Tables: $quranTables');
    for (final t in quranTables) {
      print('$t: ${definitions[t]['properties']?.keys.toList()}');
    }
  } else {
    print('Failed: ${res.statusCode}');
  }
}
