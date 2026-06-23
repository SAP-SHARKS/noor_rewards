// Locale-aware reader for community_projects rows.
//
// Reads the per-locale column (e.g. `title_ur`) when the active app locale
// has a non-empty value, otherwise falls back to the canonical English
// `title` / `description` column. Safe to use on any map-like row coming
// out of Supabase — works whether the new columns exist or not (a missing
// key reads as null, which falls back to English).
//
// See `supabase/migrations/20260621_010_community_projects_translations.sql`
// for the schema this depends on.

import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

String _localizedField(
  BuildContext context,
  Map<dynamic, dynamic> row,
  String baseKey,
) {
  final lang = Localizations.localeOf(context).languageCode;
  final localized = row['${baseKey}_$lang'] as String?;
  if (localized != null && localized.trim().isNotEmpty) return localized;
  return (row[baseKey] as String?) ?? '';
}

/// Returns the project title in the active app locale (falls back to English).
String projectTitle(BuildContext context, Map<dynamic, dynamic> row) =>
    _localizedField(context, row, 'title');

/// Returns the project description in the active app locale (falls back to
/// English). Returns the empty string when both locale-specific and English
/// descriptions are null.
String projectDescription(BuildContext context, Map<dynamic, dynamic> row) =>
    _localizedField(context, row, 'description');

/// Swaps the font of `baseStyle` to one with proper Arabic/Urdu glyphs when
/// the active locale is ar or ur. Latin sans-serif fonts like Outfit render
/// Urdu as garbled disconnected letters — this picks Noto Naskh Arabic for
/// those locales, leaves other locales untouched.
TextStyle localeAwareStyle(BuildContext context, TextStyle baseStyle) {
  final lang = Localizations.localeOf(context).languageCode;
  if (lang == 'ar' || lang == 'ur') {
    return GoogleFonts.notoNaskhArabic(textStyle: baseStyle);
  }
  return baseStyle;
}
