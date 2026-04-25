import 'dart:convert';
import 'dart:io';

void main() async {
  final l10nDir = Directory('lib/l10n');
  final arbFiles = await l10nDir.list().where((e) => e.path.endsWith('.arb')).toList();

  final newKeys = {
    "next": "Next",
    "day": "day",
    "days": "days",
    "quran": "Quran",
    "zikr": "Zikr",
    "dailyLogin": "Daily Login",
    "todaysProgress": "Today's Progress",
    "versesToday": "verses today",
    "resumeReading": "Resume Reading",
    "continueReading": "Continue reading",
    "chooseWhereToStart": "Choose Where to Start",
    "startReadingFrom": "Start Reading from",
    "yourLibrary": "Your Library",
    "browse": "Browse",
    "listen": "Listen",
    "tafsir": "Tafsir",
    "wordByWord": "Word by Word",
    "mushaf": "Mushaf",
    "morning": "Morning",
    "evening": "Evening",
    "otherCategories": "Other Categories",
    "noCategoriesAvailable": "No categories available",
    "nextPts": "Next",
    "prev": "Prev"
  };

  final urduKeys = {
    "next": "اگلا",
    "day": "دن",
    "days": "دن",
    "quran": "قرآن",
    "zikr": "ذکر",
    "dailyLogin": "روزانہ لاگ ان",
    "todaysProgress": "آج کی پیشرفت",
    "versesToday": "آج کی آیات",
    "resumeReading": "پڑھنا جاری رکھیں",
    "continueReading": "آگے پڑھیں",
    "chooseWhereToStart": "کہاں سے شروع کرنا ہے منتخب کریں",
    "startReadingFrom": "پڑھنا شروع کریں",
    "yourLibrary": "آپ کی لائبریری",
    "browse": "تلاش کریں",
    "listen": "سنیں",
    "tafsir": "تفسیر",
    "wordByWord": "لفظ بہ لفظ",
    "mushaf": "مصحف",
    "morning": "صبح",
    "evening": "شام",
    "otherCategories": "دیگر زمرے",
    "noCategoriesAvailable": "کوئی زمرہ دستیاب نہیں",
    "nextPts": "اگلا",
    "prev": "پچھلا"
  };
  
  final arabicKeys = {
    "next": "التالي",
    "day": "يوم",
    "days": "أيام",
    "quran": "القرآن",
    "zikr": "الذكر",
    "dailyLogin": "الدخول اليومي",
    "todaysProgress": "تقدم اليوم",
    "versesToday": "آيات اليوم",
    "resumeReading": "استئناف القراءة",
    "continueReading": "مواصلة القراءة",
    "chooseWhereToStart": "اختر من أين تبدأ",
    "startReadingFrom": "ابدأ القراءة من",
    "yourLibrary": "مكتبتك",
    "browse": "تصفح",
    "listen": "استمع",
    "tafsir": "تفسير",
    "wordByWord": "كلمة بكلمة",
    "mushaf": "مصحف",
    "morning": "الصباح",
    "evening": "المساء",
    "otherCategories": "فئات أخرى",
    "noCategoriesAvailable": "لا توجد فئات",
    "nextPts": "التالي",
    "prev": "السابق"
  };

  for (var file in arbFiles) {
    var content = await File(file.path).readAsString();
    var jsonMap = jsonDecode(content) as Map<String, dynamic>;
    
    var targetKeys = newKeys;
    if (file.path.endsWith('app_ur.arb')) targetKeys = urduKeys;
    if (file.path.endsWith('app_ar.arb')) targetKeys = arabicKeys;
    
    targetKeys.forEach((key, value) {
      if (!jsonMap.containsKey(key)) {
        jsonMap[key] = value;
      }
    });

    final encoder = JsonEncoder.withIndent('  ');
    await File(file.path).writeAsString(encoder.convert(jsonMap));
    print('Updated ${file.path}');
  }
}
