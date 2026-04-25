import 'dart:convert';
import 'dart:io';

void main() async {
  final l10nDir = Directory('lib/l10n');
  final arbFiles = await l10nDir.list().where((e) => e.path.endsWith('.arb')).toList();

  final newKeys = {
    "levelSeeker": "Seeker",
    "levelBeliever": "Believer",
    "levelDevoted": "Devoted",
    "levelChampion": "Champion",
    "levelLegend": "Legend",
  };

  final urduKeys = {
    "levelSeeker": "تلاش کرنے والا",
    "levelBeliever": "مومن",
    "levelDevoted": "عقیدت مند",
    "levelChampion": "چیمپئن",
    "levelLegend": "لیجنڈ",
  };
  
  final arabicKeys = {
    "levelSeeker": "طالب",
    "levelBeliever": "مؤمن",
    "levelDevoted": "مخلص",
    "levelChampion": "بطل",
    "levelLegend": "أسطورة",
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
