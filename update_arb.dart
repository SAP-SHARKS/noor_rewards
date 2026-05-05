import 'dart:convert';
import 'dart:io';

void main() async {
  final keysJson = '''
  {
    "notificationsSubtitle": "Stay on top of rewards & milestones",
    "markAllAsRead": "Mark all as read",
    "clearAll": "Clear all",
    "notificationsOn": "Notifications on",
    "notificationsOff": "Notifications off",
    "allCaughtUp": "All caught up",
    "whenYouEarnRewards": "When you earn rewards, hit a streak, or unlock a badge,\\nit'll show up here.",
    "justNow": "Just now",
    "mAgo": "{delta}m ago",
    "@mAgo": {
      "placeholders": {
        "delta": {"type": "String"}
      }
    },
    "hAgo": "{delta}h ago",
    "@hAgo": {
      "placeholders": {
        "delta": {"type": "String"}
      }
    },
    "dAgo": "{delta}d ago",
    "@dAgo": {
      "placeholders": {
        "delta": {"type": "String"}
      }
    }
  }
  ''';

  final urKeysJson = '''
  {
    "notificationsSubtitle": "انعامات اور سنگ میل پر نظر رکھیں",
    "markAllAsRead": "سب کو پڑھا ہوا نشان زد کریں",
    "clearAll": "سب صاف کریں",
    "notificationsOn": "اطلاعات آن ہیں",
    "notificationsOff": "اطلاعات آف ہیں",
    "allCaughtUp": "سب دیکھ لیا",
    "whenYouEarnRewards": "جب آپ انعامات کمائیں گے، سلسلہ بنائیں گے، یا بیج حاصل کریں گے،\\nیہ یہاں ظاہر ہوگا۔",
    "justNow": "ابھی",
    "mAgo": "{delta}m پہلے",
    "@mAgo": {
      "placeholders": {
        "delta": {"type": "String"}
      }
    },
    "hAgo": "{delta}h پہلے",
    "@hAgo": {
      "placeholders": {
        "delta": {"type": "String"}
      }
    },
    "dAgo": "{delta}d پہلے",
    "@dAgo": {
      "placeholders": {
        "delta": {"type": "String"}
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
