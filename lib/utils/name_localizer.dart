import 'package:flutter/widgets.dart';

// Latin → Arabic-script transliteration for common Muslim given names.
// Used only when the active locale is Arabic ('ar') or Urdu ('ur'); other
// locales render the original Latin form.
//
// Keys are lower-cased; match is case-insensitive. Any name not in this
// table renders unchanged — safe fallback for new sign-ups whose name
// hasn't been added yet.
const Map<String, String> _kLatinToArabicNames = {
  // ── men ──
  'muhammad': 'محمد',
  'mohammed': 'محمد',
  'mohammad': 'محمد',
  'ahmad': 'أحمد',
  'ahmed': 'أحمد',
  'ali': 'علي',
  'omar': 'عمر',
  'umar': 'عمر',
  'yusuf': 'يوسف',
  'yousuf': 'يوسف',
  'ibrahim': 'إبراهيم',
  'ismail': 'إسماعيل',
  'ishaq': 'إسحاق',
  'hassan': 'حسن',
  'hasan': 'حسن',
  'hussain': 'حسين',
  'hussein': 'حسين',
  'khalid': 'خالد',
  'hamza': 'حمزة',
  'bilal': 'بلال',
  'zaid': 'زيد',
  'saad': 'سعد',
  'salman': 'سلمان',
  'tariq': 'طارق',
  'abdullah': 'عبد الله',
  'abdul rahman': 'عبد الرحمن',
  'abdulrahman': 'عبد الرحمن',
  'usman': 'عثمان',
  'uthman': 'عثمان',
  'salah': 'صلاح',
  'idris': 'إدريس',
  'kareem': 'كريم',
  'karim': 'كريم',
  'faisal': 'فيصل',
  'haroon': 'هارون',
  'harun': 'هارون',
  'musa': 'موسى',
  'dawud': 'داود',
  'suleiman': 'سليمان',
  'sulaiman': 'سليمان',
  'nuh': 'نوح',
  'haris': 'حارث',
  'harith': 'حارث',
  'imran': 'عمران',
  'rashid': 'راشد',
  'jamal': 'جمال',
  'majid': 'ماجد',
  'nasir': 'ناصر',
  'tahir': 'طاهر',
  'yahya': 'يحيى',
  'zakaria': 'زكريا',
  'isa': 'عيسى',

  // ── women ──
  'fatima': 'فاطمة',
  'fatimah': 'فاطمة',
  'aisha': 'عائشة',
  'ayesha': 'عائشة',
  'maryam': 'مريم',
  'mariam': 'مريم',
  'zainab': 'زينب',
  'zaynab': 'زينب',
  'amina': 'آمنة',
  'aminah': 'آمنة',
  'khadija': 'خديجة',
  'khadijah': 'خديجة',
  'hajar': 'هاجر',
  'safiya': 'صفية',
  'safiyyah': 'صفية',
  'ruqayyah': 'رقية',
  'ruqayya': 'رقية',
  'halima': 'حليمة',
  'sumayya': 'سمية',
  'sumayyah': 'سمية',
  'asma': 'أسماء',
  'sara': 'سارة',
  'sarah': 'سارة',
  'laila': 'ليلى',
  'layla': 'ليلى',
  'noor': 'نور',
  'nur': 'نور',
  'huda': 'هدى',
  'salma': 'سلمى',
  'yasmin': 'ياسمين',
  'muqqadas': 'مقدسة',
  'muqaddas': 'مقدسة',
  'bibi': 'بی بی',
  'rabia': 'رابعة',
  'rabiah': 'رابعة',
  'nadia': 'ناديا',
  'samina': 'ثمينة',
  'naseem': 'نسيم',
  'shazia': 'شازيہ',
};

/// Returns [name] transliterated into Arabic script if the active locale is
/// Arabic or Urdu, else returns [name] unchanged. Empty/null → ''.
///
/// Handles space-separated multi-token names ("Abdul Rahman", "Muhammad Ali")
/// by translating each token independently — so unknown tokens still render
/// as-is in the original Latin form. Trailing initials like "H." pass through
/// untouched.
String localizeName(BuildContext context, String? name) {
  if (name == null) return '';
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';

  final lang = Localizations.maybeLocaleOf(context)?.languageCode;
  if (lang != 'ar' && lang != 'ur') return trimmed;

  // First try the whole string as a compound match (e.g. "Abdul Rahman").
  final whole = _kLatinToArabicNames[trimmed.toLowerCase()];
  if (whole != null) return whole;

  // Token-by-token: translate any token we recognize, keep the rest as-is.
  final tokens = trimmed.split(RegExp(r'\s+'));
  final out = <String>[];
  for (final t in tokens) {
    final tLower = t.toLowerCase();
    out.add(_kLatinToArabicNames[tLower] ?? t);
  }
  return out.join(' ');
}
