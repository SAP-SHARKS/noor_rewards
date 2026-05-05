import 'dart:io';

void main() {
  final bytes = File('dhikr_diff.patch').readAsBytesSync();
  print('First 10 bytes: ${bytes.sublist(0, 10)}');
}
