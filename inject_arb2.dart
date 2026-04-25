import 'dart:convert';
import 'dart:io';

void main() async {
  final l10nDir = Directory('lib/l10n');
  final arbFiles = await l10nDir.list().where((e) => e.path.endsWith('.arb')).toList();

  final newKeys = {
    "navHome": "Home",
    "navJourney": "Journey",
    "navAkhirah": "Akhirah",
    "navProfile": "Profile",
    "communityLeaderboard": "Community Leaderboard",
    "topContributors": "Top contributors by lifetime pts",
    "myProfile": "My Profile",
    "startStreak": "Start your streak today!",
    "alreadySealed": "Already sealed today",
    "sealTheDay": "Seal the Day",
    "alhamdulillah": "Alhamdulillah!",
  };

  final urduKeys = {
    "navHome": "ہوم",
    "navJourney": "سفر",
    "navAkhirah": "آخرت",
    "navProfile": "پروفائل",
    "communityLeaderboard": "برادری کا لیڈر بورڈ",
    "topContributors": "سب سے زیادہ پوائنٹس والے افراد",
    "myProfile": "میرا پروفائل",
    "startStreak": "آج ہی اپنا سلسلہ شروع کریں!",
    "alreadySealed": "آج پہلے ہی مکمل ہو چکا",
    "sealTheDay": "دن کو مکمل کریں",
    "alhamdulillah": "الحمد للہ!",
  };
  
  final arabicKeys = {
    "navHome": "الرئيسية",
    "navJourney": "الرحلة",
    "navAkhirah": "الآخرة",
    "navProfile": "الملف الشخصي",
    "communityLeaderboard": "لوحة صدارة المجتمع",
    "topContributors": "أفضل المساهمين بالنقاط",
    "myProfile": "ملفي الشخصي",
    "startStreak": "ابدأ سلسلتك اليوم!",
    "alreadySealed": "تم الختم اليوم بالفعل",
    "sealTheDay": "اختم اليوم",
    "alhamdulillah": "الحمد لله!",
  };

  for (var file in arbFiles) {
    var content = await File(file.path).readAsString();
    var jsonMap = jsonDecode(content) as Map<String, dynamic>;
    
    // Select translations based on locale
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
