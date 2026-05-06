import 'dart:io';

void main() {
  final file = File('lib/widgets/notifications_sheet.dart');
  var content = file.readAsStringSync();
  
  // Replace the broken lines
  content = content.replaceAll(
      'return AppLocalizations.of(context)?.badgeEarnedDesc(badge) ?? "You\\'ve earned the \\\\\\"\\\$badge\\\\\\" badge.";',
      'return AppLocalizations.of(context)?.badgeEarnedDesc(badge) ?? "You\\'ve earned the \\"\$badge\\" badge.";'
  );
  
  file.writeAsStringSync(content);
  print('Fixed!');
}
