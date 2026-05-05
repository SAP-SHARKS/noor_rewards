import 'dart:io';

void main() async {
  final content = File('output.txt').readAsStringSync();
  print(content);
}
