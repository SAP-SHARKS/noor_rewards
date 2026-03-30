void main() {
  try {
    RegExp(r'[\u0615-\u061A\u06D6-\u06DE\u06DF-\u06E4\u06E7-\u06E8\u06EA-\u06ED\u08D4-\u08FE\u200B\uE000-\uF8FF]');
    print('regex built OK');
  } catch (e) {
    print('ERROR: $e');
  }
}
