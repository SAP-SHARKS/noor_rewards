import 'dart:io';

void main() {
  for (var f in Directory('lib/screens').listSync().whereType<File>()) {
    var c = f.readAsStringSync();
    if (c.contains('AppLocalizations') && !c.contains('app_localizations.dart')) {
      c = c.replaceFirst('import \\'package:flutter/material.dart\\';', 'import \\'package:flutter/material.dart\\';\\nimport \\'../l10n/app_localizations.dart\\';');
      f.writeAsStringSync(c);
      print('Fixed \${f.path}');
    }
  }
}
