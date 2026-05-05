import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://fwjzhtcxfiendofnhyzp.supabase.co/functions/v1/monthly-quran-reminder';
  final key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ3anpodGN4ZmllbmRvZm5oeXpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzMzkwNDksImV4cCI6MjA4NjkxNTA0OX0.gspfVlCH-S2Cs8_fhOeDWNZN2XH1NC53CJ8riyvJ5nw';
  
  final res = await http.post(
    Uri.parse(url),
    headers: { 'Authorization': 'Bearer $key', 'Content-Type': 'application/json' },
    body: jsonEncode({}),
  );
  
  print('Status: ${res.statusCode}');
  print('Body: ${res.body}');
}
