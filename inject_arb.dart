import 'dart:convert';
import 'dart:io';

void main() async {
  final l10nDir = Directory('lib/l10n');
  final arbFiles = await l10nDir.list().where((e) => e.path.endsWith('.arb')).toList();

  final newKeys = {
    "callYou": "What should we\\ncall you?",
    "personaliseJourney": "Personalise your spiritual journey with your name",
    "whereFrom": "Where are\\nyou from?",
    "joinMuslims": "Join Muslims from around the world on this journey",
    "whatBringsYou": "What brings\\nyou here?",
    "chooseGoals": "Choose your spiritual goals — you can select multiple",
  };

  final urduKeys = {
    "callYou": "ہم آپ کو کیا کہہ کر\\nپکاریں؟",
    "personaliseJourney": "اپنے نام کے ساتھ اپنے روحانی سفر کو ذاتی نوعیت دیں",
    "whereFrom": "آپ کہاں سے\\nہیں؟",
    "joinMuslims": "اس سفر میں دنیا بھر کے مسلمانوں کے ساتھ شامل ہوں",
    "whatBringsYou": "آپ کو یہاں کیا چیز\\nلائی ہے؟",
    "chooseGoals": "اپنے روحانی اہداف منتخب کریں — آپ ایک سے زیادہ کا انتخاب کر سکتے ہیں",
  };
  
  final arabicKeys = {
    "callYou": "ماذا ينبغي أن\\nنناديك؟",
    "personaliseJourney": "قم بتخصيص رحلتك الروحية باسمك",
    "whereFrom": "من أين\\nأنت؟",
    "joinMuslims": "انضم إلى المسلمين من جميع أنحاء العالم في هذه الرحلة",
    "whatBringsYou": "ما الذي\\nأتى بك إلى هنا؟",
    "chooseGoals": "اختر أهدافك الروحية — يمكنك اختيار أكثر من هدف",
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
