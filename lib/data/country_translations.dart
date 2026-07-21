// Country name translations keyed by canonical English name.
//
// Storage in Supabase (`profiles.country`) remains canonical English so
// the join / IP-lookup / analytics pipelines don't need to change; this
// map is a display-time overlay. Consumers should call
// [localizedCountryName] whenever they render a country name in the UI.
//
// Scope: seeded for the ~40 countries covering the app's Muslim-majority
// and top English-speaking user base. Untranslated countries fall back
// to English so nothing goes blank. Other locales (fr, id, ms, ru, tr)
// are also stubbed as empty — the helper returns English until entries
// are added.
//
// To extend: add either a whole locale block (top-level key = locale
// code) or individual country entries inside an existing locale block.
// Keys must match `_kCountries` in profile_settings_screen.dart exactly.

const Map<String, Map<String, String>> kCountryTranslations = {
  'ur': {
    'Afghanistan': 'افغانستان',
    'Algeria': 'الجزائر',
    'Australia': 'آسٹریلیا',
    'Bahrain': 'بحرین',
    'Bangladesh': 'بنگلہ دیش',
    'Brunei': 'برونائی',
    'Canada': 'کینیڈا',
    'China': 'چین',
    'Egypt': 'مصر',
    'Ethiopia': 'ایتھوپیا',
    'France': 'فرانس',
    'Germany': 'جرمنی',
    'India': 'بھارت',
    'Indonesia': 'انڈونیشیا',
    'Iran': 'ایران',
    'Iraq': 'عراق',
    'Italy': 'اٹلی',
    'Japan': 'جاپان',
    'Jordan': 'اردن',
    'Kuwait': 'کویت',
    'Lebanon': 'لبنان',
    'Libya': 'لیبیا',
    'Malaysia': 'ملائیشیا',
    'Maldives': 'مالدیپ',
    'Morocco': 'مراکش',
    'Nigeria': 'نائجیریا',
    'Oman': 'عمان',
    'Pakistan': 'پاکستان',
    'Palestine': 'فلسطین',
    'Qatar': 'قطر',
    'Russia': 'روس',
    'Saudi Arabia': 'سعودی عرب',
    'Somalia': 'صومالیہ',
    'Spain': 'سپین',
    'Sri Lanka': 'سری لنکا',
    'Sudan': 'سوڈان',
    'Syria': 'شام',
    'Tunisia': 'تیونس',
    'Turkey': 'ترکی',
    'United Arab Emirates': 'متحدہ عرب امارات',
    'United Kingdom': 'برطانیہ',
    'United States': 'ریاستہائے متحدہ',
    'Yemen': 'یمن',
  },
  'ar': {
    'Afghanistan': 'أفغانستان',
    'Algeria': 'الجزائر',
    'Australia': 'أستراليا',
    'Bahrain': 'البحرين',
    'Bangladesh': 'بنغلاديش',
    'Brunei': 'بروناي',
    'Canada': 'كندا',
    'China': 'الصين',
    'Egypt': 'مصر',
    'Ethiopia': 'إثيوبيا',
    'France': 'فرنسا',
    'Germany': 'ألمانيا',
    'India': 'الهند',
    'Indonesia': 'إندونيسيا',
    'Iran': 'إيران',
    'Iraq': 'العراق',
    'Italy': 'إيطاليا',
    'Japan': 'اليابان',
    'Jordan': 'الأردن',
    'Kuwait': 'الكويت',
    'Lebanon': 'لبنان',
    'Libya': 'ليبيا',
    'Malaysia': 'ماليزيا',
    'Maldives': 'جزر المالديف',
    'Morocco': 'المغرب',
    'Nigeria': 'نيجيريا',
    'Oman': 'عُمان',
    'Pakistan': 'باكستان',
    'Palestine': 'فلسطين',
    'Qatar': 'قطر',
    'Russia': 'روسيا',
    'Saudi Arabia': 'المملكة العربية السعودية',
    'Somalia': 'الصومال',
    'Spain': 'إسبانيا',
    'Sri Lanka': 'سريلانكا',
    'Sudan': 'السودان',
    'Syria': 'سوريا',
    'Tunisia': 'تونس',
    'Turkey': 'تركيا',
    'United Arab Emirates': 'الإمارات العربية المتحدة',
    'United Kingdom': 'المملكة المتحدة',
    'United States': 'الولايات المتحدة',
    'Yemen': 'اليمن',
  },
  // fr, id, ms, ru, tr — stubbed empty; helper returns English fallback
  // for those locales until translations are added.
};

/// Returns the localised display name for [englishCountry] in [locale].
/// Falls back to [englishCountry] itself when no translation exists.
String localizedCountryName(String englishCountry, String? locale) {
  if (englishCountry.isEmpty || locale == null) return englishCountry;
  final code = locale.split(RegExp(r'[_-]')).first.toLowerCase();
  return kCountryTranslations[code]?[englishCountry] ?? englishCountry;
}
