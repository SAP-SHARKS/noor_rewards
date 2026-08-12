// lib/widgets/initials_avatar.dart
//
// InitialsAvatar — the ONLY avatar widget in Sabiq.
//
// Renders a circular badge with the user's initials over their persisted
// `profiles.avatar_color`. No network image loading, no user-uploaded
// photos anywhere. This is a UGC-compliance-driven design decision — we
// do not accept any user-supplied images in the app.
//
// Initials logic:
//   • null / empty displayName          → "?"
//   • single word ("Ahmed")             → "A"
//   • two+ words ("Ahmed Zaid")         → "AZ"
//   • three+ words ("Ahmed Zaid Khan")  → "AK"  (first + last, not middle)
//
// Uses grapheme-safe splitting (String.characters.first) so Arabic /
// Urdu / emoji names don't crash on a byte-level substring.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InitialsAvatar extends StatelessWidget {
  /// The user's display name — first letter drives the initial.
  /// Nullable/empty falls back to "?".
  final String? displayName;

  /// Persisted per-user color from `profiles.avatar_color` (hex int
  /// stored in the DB, e.g. `0xFF2BAE99`). Null falls back to a neutral
  /// gray so the avatar still reads cleanly.
  final int? avatarColor;

  /// Diameter of the circle in logical pixels.
  final double size;

  /// Text size override. Defaults to `size * 0.4` which reads well from
  /// 20px thumbnails up to 128px hero avatars.
  final double? fontSize;

  const InitialsAvatar({
    super.key,
    required this.displayName,
    this.avatarColor,
    this.size = 40,
    this.fontSize,
  });

  /// Neutral default when the DB row has no avatar_color set. Matches
  /// Tailwind gray-500 so it looks intentional against both light and
  /// dark backgrounds.
  static const Color _defaultColor = Color(0xFF6B7280);

  static String _initialsFor(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return '?';

    // Grapheme-safe word split. `String.split(RegExp(r'\s+'))` is fine
    // for whitespace, but the per-word first character must come from
    // `.characters.first` so Arabic composed characters or emoji stay
    // intact instead of crashing on byte-level `[0]`.
    final words = trimmed.split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return '?';

    String firstGrapheme(String s) {
      if (s.isEmpty) return '';
      // `.characters` walks grapheme clusters — safe for combining
      // marks, ZWJ sequences, and RTL scripts.
      return s.characters.first;
    }

    if (words.length == 1) {
      return firstGrapheme(words.first).toUpperCase();
    }
    // 2+ words → first letter of first word + first letter of LAST word
    // (skipping middle names). Matches how most humans read "Ahmed Zaid
    // Khan" → AK.
    final first = firstGrapheme(words.first).toUpperCase();
    final last = firstGrapheme(words.last).toUpperCase();
    return '$first$last';
  }

  @override
  Widget build(BuildContext context) {
    final bg = avatarColor != null ? Color(avatarColor!) : _defaultColor;
    final initials = _initialsFor(displayName);
    final effectiveFontSize = fontSize ?? size * 0.4;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: GoogleFonts.outfit(
          fontSize: effectiveFontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}
