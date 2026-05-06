import 'dart:convert';
import 'dart:io';

void main() async {
  final keysJson = '''
  {
    "newBadgeUnlocked": "New badge unlocked",
    "daySealed": "Day sealed",
    "dailyLoginBonus": "Daily login bonus",
    "oneWeek": "One Week",
    "twoWeeks": "Two Weeks",
    "badgeEarnedDesc": "You've earned the \\"{badge}\\" badge.",
    "@badgeEarnedDesc": {
      "placeholders": {
        "badge": {"type": "String"}
      }
    },
    "pointsForSealing": "+{points} Noor Points for sealing today.",
    "@pointsForSealing": {
      "placeholders": {
        "points": {"type": "String"}
      }
    },
    "welcomeBack": "+{points} Noor Points · welcome back!",
    "@welcomeBack": {
      "placeholders": {
        "points": {"type": "String"}
      }
    },
    "streakBonus": "{days}-day {type} streak · +{points} bonus pts unlocked",
    "@streakBonus": {
      "placeholders": {
        "days": {"type": "String"},
        "type": {"type": "String"},
        "points": {"type": "String"}
      }
    }
  }
  ''';

  final urKeysJson = '''
  {
    "newBadgeUnlocked": "نئا بیج مل گیا",
    "daySealed": "دن مکمل",
    "dailyLoginBonus": "روزانہ لاگ ان بونس",
    "oneWeek": "ایک ہفتہ",
    "twoWeeks": "دو ہفتے",
    "badgeEarnedDesc": "آپ نے \\"{badge}\\" بیج حاصل کر لیا ہے۔",
    "@badgeEarnedDesc": {
      "placeholders": {
        "badge": {"type": "String"}
      }
    },
    "pointsForSealing": "آج مکمل کرنے پر +{points} نور پوائنٹس۔",
    "@pointsForSealing": {
      "placeholders": {
        "points": {"type": "String"}
      }
    },
    "welcomeBack": "+{points} نور پوائنٹس · خوش آمدید!",
    "@welcomeBack": {
      "placeholders": {
        "points": {"type": "String"}
      }
    },
    "streakBonus": "{days} دن کا {type} سلسلہ · +{points} بونس پوائنٹس ملے۔",
    "@streakBonus": {
      "placeholders": {
        "days": {"type": "String"},
        "type": {"type": "String"},
        "points": {"type": "String"}
      }
    }
  }
  ''';

  final keys = jsonDecode(keysJson) as Map<String, dynamic>;
  final urKeys = jsonDecode(urKeysJson) as Map<String, dynamic>;

  final dir = Directory('lib/l10n');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb'));

  for (final file in files) {
    String content = await file.readAsString();
    Map<String, dynamic> jsonMap = jsonDecode(content);

    if (file.path.endsWith('app_ur.arb')) {
      for (final key in urKeys.keys) {
        jsonMap[key] = urKeys[key];
      }
    } else {
      for (final key in keys.keys) {
        if (!jsonMap.containsKey(key)) {
          jsonMap[key] = keys[key];
        }
      }
    }

    final newContent = const JsonEncoder.withIndent('  ').convert(jsonMap);
    await file.writeAsString(newContent);
    print('Updated \${file.path}');
  }
}
