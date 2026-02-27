import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart';

// Please ensure `supabase` package is available in pubspec.yaml, or use the http package directly. Let's just use http.
void main() async {
  final supabaseUrl = 'https://fwjzhtcxfiendofnhyzp.supabase.co';
  final supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ3anpodGN4ZmllbmRvZm5oeXpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzMzkwNDksImV4cCI6MjA4NjkxNTA0OX0.gspfVlCH-S2Cs8_fhOeDWNZN2XH1NC53CJ8riyvJ5nw';

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  print('Fetching Uthmani Quran from api.alquran.cloud...');
  final uthmaniRes = await http.get(Uri.parse('https://api.alquran.cloud/v1/quran/quran-uthmani'));
  if (uthmaniRes.statusCode != 200) {
    print('Failed to fetch Arabic text');
    return;
  }
  final uthmaniData = jsonDecode(uthmaniRes.body)['data']['surahs'];

  print('Fetching English Sahih Translation...');
  final sahihRes = await http.get(Uri.parse('https://api.alquran.cloud/v1/quran/en.sahih'));
  if (sahihRes.statusCode != 200) {
    print('Failed to fetch Translation text');
    return;
  }
  final sahihData = jsonDecode(sahihRes.body)['data']['surahs'];

  print('Parsing data...');
  final verses = [];
  final translations = [];
  
  // We need to insert the edition first
  try {
    await client.from('quran_editions').upsert([
      {
        'identifier': 'en.sahih',
        'language': 'en',
        'name': 'Sahih International',
        'english_name': 'Sahih International',
        'format': 'text',
        'type': 'translation'
      },
      {
        'identifier': 'quran-uthmani',
        'language': 'ar',
        'name': 'Quran Uthmani',
        'english_name': 'Quran Uthmani',
        'format': 'text',
        'type': 'quran'
      }
    ]);
  } catch (e) {
    print('Error inserting editions: $e');
  }

  for (var sIdx = 0; sIdx < uthmaniData.length; sIdx++) {
    final surah = uthmaniData[sIdx];
    final tSurah = sahihData[sIdx];

    for (var aIdx = 0; aIdx < surah['ayahs'].length; aIdx++) {
      final ayah = surah['ayahs'][aIdx];
      final tAyah = tSurah['ayahs'][aIdx];

      verses.add({
        'id': ayah['number'],
        'surah': surah['number'],
        'ayah': ayah['numberInSurah'],
        'text_uthmani': ayah['text'],
        'juz': ayah['juz'],
        'manzil': ayah['manzil'],
        'page': ayah['page'],
        'ruku': ayah['ruku'],
        'hizb_quarter': ayah['hizbQuarter'],
        'sajdah': ayah['sajdah'] is bool ? ayah['sajdah'] : (ayah['sajdah'] != false),
      });

      translations.add({
        'verse_id': ayah['number'],
        'edition': 'en.sahih',
        'text': tAyah['text'],
      });
    }
  }

  print('Inserting ${verses.length} verses...');
  // Insert in chunks of 500
  for (var i = 0; i < verses.length; i += 500) {
    final end = i + 500 < verses.length ? i + 500 : verses.length;
    await client.from('quran_verses').upsert(verses.sublist(i, end));
    print('Inserted verses $i to $end');
  }

  print('Inserting ${translations.length} translations...');
  for (var i = 0; i < translations.length; i += 500) {
    final end = i + 500 < translations.length ? i + 500 : translations.length;
    await client.from('quran_translations').upsert(translations.sublist(i, end));
    print('Inserted translations $i to $end');
  }

  print('Seeding complete!');
  exit(0);
}
