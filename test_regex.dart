void main() {
  final s1 = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
  final s2 = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ';
  final s3 = 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ';
  final s4 = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ يَا أَيُّهَا النَّاسُ';

  final opt = r'[\u064B-\u065F\u0670\u06DF-\u06E8\u0600-\u060F\u0610-\u061A\u0640]*';
  final sp = r'[\s]*'; 
  final basmalaRegex = RegExp(
      '^' +
      'ب' + opt + 'س' + opt + 'م' + opt + sp +
      '[اٱإ]' + opt + 'ل' + opt + 'ل' + opt + 'ه' + opt + sp +
      '[اٱإ]' + opt + 'ل' + opt + 'ر' + opt + 'ح' + opt + 'م' + opt + 'ن' + opt + sp +
      '[اٱإ]' + opt + 'ل' + opt + 'ر' + opt + 'ح' + opt + '[يی]' + opt + 'م' + opt + sp
  );

  for (final s in [s1, s2, s3, s4]) {
    final match = basmalaRegex.firstMatch(s);
    if (match != null) {
      print('Matched: ${s.substring(0, match.end)}');
      print('Remaining: ${s.substring(match.end).trimLeft()}');
    } else {
      print('No Match: $s');
    }
  }
}
