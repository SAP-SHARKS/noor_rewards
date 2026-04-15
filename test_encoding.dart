import 'dart:io';
import 'dart:convert';

void main() {
  try {
    final text = File('lib/screens/dhikr_screen.dart').readAsStringSync(encoding: utf8);
    print("Success reading UTF-8. Length: ${text.length}");
  } catch(e) {
    print("Error: $e");
  }
}
