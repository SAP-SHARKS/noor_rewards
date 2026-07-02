// lib/widgets/plot_illustrations.dart
//
// 3D-style illustrations for the four "Today's plots" home cards —
// Quran, Dhikr, Achievements, Invite Friends. The SVGs are taken from
// the approved design mockup (var3_unified_bg) and rendered with
// flutter_svg.
//
// NOTE: every translucent colour is written as a hex value plus a
// `*-opacity` attribute (stop-opacity / fill-opacity) rather than the
// CSS `rgba()` form. flutter_svg does not apply the alpha channel of
// `rgba()` consistently, which made the soft highlights render as
// opaque white patches. Hex + `*-opacity` renders identically to the
// browser mockup.

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/y4_theme.dart';

enum PlotIcon { quran, dhikr, achievements, invite }

/// Card gradients for the "Today's plots" grid. Derived from the active
/// theme palette so the tiles pick up the current mode instead of the
/// baked honey cream. A/B alternate so the grid reads as two subtly
/// different pastel surfaces.
List<Color> get kPlotGradientA => [
      Y4.palette.butter,
      Y4.palette.honey.withValues(alpha: 0.35),
    ];
List<Color> get kPlotGradientB => [
      Y4.palette.honey.withValues(alpha: 0.30),
      Y4.palette.honeyDeep.withValues(alpha: 0.35),
    ];

/// Renders the 3D illustration for [kind]. The SVG art is baked in honey/
/// gold tones — at build time we HSL-shift every hex colour in the SVG so
/// the artwork retints to the active palette hue (Sky/Mint/Rose/etc.)
/// while keeping its own shading, highlights, and shadows intact.
class PlotIllustration extends StatelessWidget {
  final PlotIcon kind;
  final double width;
  final double height;
  const PlotIllustration(
    this.kind, {
    super.key,
    this.width = 132,
    this.height = 128,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _themedSvg(_svg[kind]!, Y4.palette.honey),
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }

  /// Substitutes every hex colour in [svg] with a hue-shifted version
  /// where the hue is rotated to match [target]. Honey hues (~40°) stay
  /// as-is when target is honey; other modes shift to their brand hue.
  static String _themedSvg(String svg, Color target) {
    final targetHsv = HSVColor.fromColor(target);
    // Delta from the artwork's canonical honey hue (~40°) to the target.
    // If target IS honey, delta == 0 so the SVG is unchanged.
    const artHue = 40.0;
    final delta = _wrapHue(targetHsv.hue - artHue);
    if (delta.abs() < 0.5) return svg;
    return svg.replaceAllMapped(
      RegExp(r'#([0-9a-fA-F]{6})'),
      (m) {
        final rgb = int.parse(m.group(1)!, radix: 16);
        final color = Color(0xFF000000 | rgb);
        final hsv = HSVColor.fromColor(color);
        // Only shift saturated pixels — leaves near-white/near-black alone
        // so shadows and highlights stay neutral.
        if (hsv.saturation < 0.05) return m.group(0)!;
        final shifted = hsv.withHue(_wrapHue(hsv.hue + delta)).toColor();
        final hex = shifted.toARGB32() & 0xFFFFFF;
        return '#${hex.toRadixString(16).padLeft(6, '0')}';
      },
    );
  }

  static double _wrapHue(double h) {
    var v = h % 360;
    if (v < 0) v += 360;
    return v;
  }
}

const Map<PlotIcon, String> _svg = {
  PlotIcon.quran: _quranSvg,
  PlotIcon.dhikr: _dhikrSvg,
  PlotIcon.achievements: _trophySvg,
  PlotIcon.invite: _inviteSvg,
};

// ── Quran — 3D gold book with star emblem + bookmark ────────────────────────
const String _quranSvg = '''
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="qCover" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#f5e0a8"/>
      <stop offset="60%" stop-color="#d4a850"/>
      <stop offset="100%" stop-color="#9a7020"/>
    </linearGradient>
    <linearGradient id="qCside" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#fff4d0"/>
      <stop offset="100%" stop-color="#d4a850"/>
    </linearGradient>
    <linearGradient id="qPages" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#fffaea"/>
      <stop offset="100%" stop-color="#f0d890"/>
    </linearGradient>
    <radialGradient id="qHi" cx="25%" cy="20%" r="65%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.7"/>
      <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <ellipse cx="100" cy="180" rx="72" ry="6" fill="#785014" fill-opacity="0.18"/>
  <path d="M 30 158 L 170 158 L 168 168 L 32 168 Z" fill="url(#qCside)"/>
  <path d="M 32 54 L 168 54 L 168 158 L 32 158 Z" fill="url(#qPages)"/>
  <path d="M 30 46 L 170 46 L 170 154 L 30 154 Z" fill="url(#qCover)"/>
  <rect x="30" y="46" width="6" height="108" fill="#9a7020"/>
  <path d="M 30 46 L 170 46 L 170 154 L 30 154 Z" fill="url(#qHi)"/>
  <rect x="48" y="62" width="108" height="80" fill="none" stroke="#fff5d0" stroke-width="2.5" rx="2"/>
  <rect x="52" y="66" width="100" height="72" fill="none" stroke="#fff5d0" stroke-width="1" rx="2"/>
  <circle cx="102" cy="102" r="22" fill="none" stroke="#fff5d0" stroke-width="2"/>
  <circle cx="102" cy="102" r="16" fill="none" stroke="#fff5d0" stroke-width="1"/>
  <g transform="translate(102,102)">
    <path d="M 0 -11 L 3 -3 L 11 0 L 3 3 L 0 11 L -3 3 L -11 0 L -3 -3 Z" fill="#fff5d0" opacity="0.95"/>
    <circle cx="0" cy="0" r="3" fill="#9a7020"/>
  </g>
  <line x1="60" y1="74"  x2="144" y2="74"  stroke="#fff5d0" stroke-width="0.8"/>
  <line x1="60" y1="130" x2="144" y2="130" stroke="#fff5d0" stroke-width="0.8"/>
  <path d="M 130 46 L 130 80 L 134 76 L 138 80 L 138 46 Z" fill="#e8a040"/>
  <path d="M 130 46 L 138 46 L 138 52 L 130 52 Z" fill="#c47a18"/>
</svg>
''';

// ── Dhikr — 3D prayer-bead (tasbih) ring with tassel ────────────────────────
const String _dhikrSvg = '''
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="dBead" cx="32%" cy="28%" r="72%">
      <stop offset="0%"   stop-color="#fffaea"/>
      <stop offset="40%"  stop-color="#f0d480"/>
      <stop offset="80%"  stop-color="#b88c30"/>
      <stop offset="100%" stop-color="#704818"/>
    </radialGradient>
    <radialGradient id="dLead" cx="30%" cy="25%" r="72%">
      <stop offset="0%"   stop-color="#fffce8"/>
      <stop offset="40%"  stop-color="#f5dc90"/>
      <stop offset="100%" stop-color="#8a6018"/>
    </radialGradient>
  </defs>
  <ellipse cx="100" cy="180" rx="62" ry="7" fill="#785014" fill-opacity="0.16"/>
  <ellipse cx="100" cy="95" rx="58" ry="62" fill="none" stroke="#8a6020" stroke-width="0.8" opacity="0.5"/>
  <g>
    <circle cx="100" cy="33" r="13" fill="url(#dLead)"/>
    <ellipse cx="96" cy="28" rx="3.5" ry="2.5" fill="#ffffff" fill-opacity="0.75"/>
  </g>
  <g><circle cx="76"  cy="40"  r="9" fill="url(#dBead)"/><ellipse cx="73.5"  cy="37.5"  rx="2" ry="1.5" fill="#ffffff" fill-opacity="0.7"/></g>
  <g><circle cx="56"  cy="54"  r="9" fill="url(#dBead)"/><ellipse cx="53.5"  cy="51.5"  rx="2" ry="1.5" fill="#ffffff" fill-opacity="0.7"/></g>
  <g><circle cx="44"  cy="74"  r="9" fill="url(#dBead)"/><ellipse cx="41.5"  cy="71.5"  rx="2" ry="1.5" fill="#ffffff" fill-opacity="0.7"/></g>
  <g><circle cx="40"  cy="98"  r="9" fill="url(#dBead)"/><ellipse cx="37.5"  cy="95.5"  rx="2" ry="1.5" fill="#ffffff" fill-opacity="0.7"/></g>
  <g><circle cx="44"  cy="122" r="9" fill="url(#dBead)"/><ellipse cx="41.5"  cy="119.5" rx="2" ry="1.5" fill="#ffffff" fill-opacity="0.7"/></g>
  <g><circle cx="58"  cy="142" r="9" fill="url(#dBead)"/><ellipse cx="55.5"  cy="139.5" rx="2" ry="1.5" fill="#ffffff" fill-opacity="0.7"/></g>
  <g><circle cx="80"  cy="155" r="9" fill="url(#dBead)"/><ellipse cx="77.5"  cy="152.5" rx="2" ry="1.5" fill="#ffffff" fill-opacity="0.7"/></g>
  <g><circle cx="120" cy="155" r="9" fill="url(#dBead)"/><ellipse cx="117.5" cy="152.5" rx="2" ry="1.5" fill="#ffffff" fill-opacity="0.7"/></g>
  <g><circle cx="142" cy="142" r="9" fill="url(#dBead)"/><ellipse cx="139.5" cy="139.5" rx="2" ry="1.5" fill="#ffffff" fill-opacity="0.7"/></g>
  <g><circle cx="156" cy="122" r="9" fill="url(#dBead)"/><ellipse cx="153.5" cy="119.5" rx="2" ry="1.5" fill="#ffffff" fill-opacity="0.7"/></g>
  <g><circle cx="160" cy="98"  r="9" fill="url(#dBead)"/><ellipse cx="157.5" cy="95.5"  rx="2" ry="1.5" fill="#ffffff" fill-opacity="0.7"/></g>
  <g><circle cx="156" cy="74"  r="9" fill="url(#dBead)"/><ellipse cx="153.5" cy="71.5"  rx="2" ry="1.5" fill="#ffffff" fill-opacity="0.7"/></g>
  <g><circle cx="144" cy="54"  r="9" fill="url(#dBead)"/><ellipse cx="141.5" cy="51.5"  rx="2" ry="1.5" fill="#ffffff" fill-opacity="0.7"/></g>
  <g><circle cx="124" cy="40"  r="9" fill="url(#dBead)"/><ellipse cx="121.5" cy="37.5"  rx="2" ry="1.5" fill="#ffffff" fill-opacity="0.7"/></g>
  <line x1="100" y1="46" x2="100" y2="60" stroke="#a8801c" stroke-width="2"/>
  <path d="M 90 60 L 110 60 L 112 70 L 88 70 Z" fill="#d4a850"/>
  <ellipse cx="100" cy="60" rx="10" ry="1.5" fill="#a8801c"/>
  <g stroke="#c89438" stroke-width="1.6" stroke-linecap="round">
    <line x1="91"  y1="70" x2="88"  y2="100"/>
    <line x1="95"  y1="70" x2="93"  y2="105"/>
    <line x1="100" y1="70" x2="100" y2="108"/>
    <line x1="105" y1="70" x2="107" y2="105"/>
    <line x1="109" y1="70" x2="112" y2="100"/>
    <line x1="93"  y1="70" x2="91"  y2="103"/>
    <line x1="107" y1="70" x2="109" y2="103"/>
  </g>
</svg>
''';

// ── Achievements — 3D gold trophy on a plinth ───────────────────────────────
const String _trophySvg = '''
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="tCup" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#fff5c8"/>
      <stop offset="40%" stop-color="#f0c860"/>
      <stop offset="100%" stop-color="#9a6818"/>
    </linearGradient>
    <linearGradient id="tCupRim" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#a87018"/>
      <stop offset="50%" stop-color="#fff5d0"/>
      <stop offset="100%" stop-color="#a87018"/>
    </linearGradient>
    <linearGradient id="tHandle" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#d4a040"/>
      <stop offset="50%" stop-color="#8a5818"/>
      <stop offset="100%" stop-color="#d4a040"/>
    </linearGradient>
    <linearGradient id="tBase" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#f0c860"/>
      <stop offset="100%" stop-color="#7a4a10"/>
    </linearGradient>
    <linearGradient id="tPlinth" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#d4a850"/>
      <stop offset="100%" stop-color="#6a4010"/>
    </linearGradient>
    <radialGradient id="tHi" cx="30%" cy="25%" r="65%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.6"/>
      <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <ellipse cx="100" cy="180" rx="58" ry="6" fill="#785014" fill-opacity="0.2"/>
  <rect x="60" y="160" width="80" height="14" rx="2" fill="url(#tPlinth)"/>
  <rect x="60" y="160" width="80" height="3" fill="#fff5d0" opacity="0.5"/>
  <path d="M 72 138 L 128 138 L 134 160 L 66 160 Z" fill="url(#tBase)"/>
  <path d="M 72 138 L 128 138 L 126 141 L 74 141 Z" fill="#fff5d0" opacity="0.4"/>
  <path d="M 90 124 L 110 124 L 112 138 L 88 138 Z" fill="url(#tBase)"/>
  <path d="M 52 60 Q 30 70 32 95 Q 34 115 56 112 L 56 102 Q 46 102 46 92 Q 46 78 60 74 Z" fill="url(#tHandle)"/>
  <path d="M 148 60 Q 170 70 168 95 Q 166 115 144 112 L 144 102 Q 154 102 154 92 Q 154 78 140 74 Z" fill="url(#tHandle)"/>
  <path d="M 54 46 L 146 46 L 140 118 Q 100 138 60 118 Z" fill="url(#tCup)"/>
  <path d="M 54 46 L 146 46 L 140 118 Q 100 138 60 118 Z" fill="url(#tHi)"/>
  <ellipse cx="100" cy="46" rx="46" ry="8" fill="url(#tCupRim)"/>
  <ellipse cx="100" cy="46" rx="46" ry="8" fill="none" stroke="#7a4a10" stroke-width="0.5"/>
  <ellipse cx="100" cy="46" rx="40" ry="6" fill="#5a3a08"/>
  <ellipse cx="100" cy="44" rx="38" ry="4" fill="#7a5018"/>
  <g transform="translate(100,82)">
    <path d="M 0 -14 L 4 -4 L 14 -4 L 6 3 L 9 13 L 0 7 L -9 13 L -6 3 L -14 -4 L -4 -4 Z"
          fill="#fff5d0" opacity="0.95" stroke="#a87018" stroke-width="0.5"/>
  </g>
  <path d="M 62 102 Q 100 110 138 102" fill="none" stroke="#a87018" stroke-width="0.8" opacity="0.7"/>
</svg>
''';

// ── Invite Friends — 3D two figures + star badge ────────────────────────────
const String _inviteSvg = '''
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="fHead1" cx="32%" cy="28%" r="70%">
      <stop offset="0%" stop-color="#fff5c8"/>
      <stop offset="50%" stop-color="#f0c060"/>
      <stop offset="100%" stop-color="#8a5818"/>
    </radialGradient>
    <radialGradient id="fHead2" cx="32%" cy="28%" r="70%">
      <stop offset="0%" stop-color="#fde0a8"/>
      <stop offset="50%" stop-color="#d4a040"/>
      <stop offset="100%" stop-color="#6a4010"/>
    </radialGradient>
    <linearGradient id="fBody1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#f5dc8a"/>
      <stop offset="60%" stop-color="#d4a040"/>
      <stop offset="100%" stop-color="#7a4a10"/>
    </linearGradient>
    <linearGradient id="fBody2" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#f0c860"/>
      <stop offset="60%" stop-color="#b88830"/>
      <stop offset="100%" stop-color="#5a3a08"/>
    </linearGradient>
    <radialGradient id="fStar" cx="35%" cy="30%" r="70%">
      <stop offset="0%" stop-color="#fffce8"/>
      <stop offset="60%" stop-color="#f5d090"/>
      <stop offset="100%" stop-color="#a87018"/>
    </radialGradient>
    <radialGradient id="fHi" cx="30%" cy="25%" r="70%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.4"/>
      <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <ellipse cx="100" cy="180" rx="68" ry="6" fill="#785014" fill-opacity="0.2"/>
  <path d="M 110 100 Q 138 100 144 130 L 148 170 Q 130 178 110 178 Q 100 178 100 170 L 100 130 Q 100 100 110 100 Z" fill="url(#fBody2)"/>
  <path d="M 110 100 Q 138 100 144 130 L 148 170 Q 130 178 110 178 Q 100 178 100 170 L 100 130 Q 100 100 110 100 Z" fill="url(#fHi)"/>
  <path d="M 116 92 L 132 92 L 132 104 L 116 104 Z" fill="#b88830"/>
  <circle cx="124" cy="78" r="20" fill="url(#fHead2)"/>
  <ellipse cx="117" cy="70" rx="6" ry="4" fill="#ffffff" fill-opacity="0.5"/>
  <path d="M 82 100 Q 56 100 50 130 L 46 170 Q 64 180 82 180 Q 100 180 100 170 L 100 130 Q 100 100 82 100 Z" fill="url(#fBody1)"/>
  <path d="M 82 100 Q 56 100 50 130 L 46 170 Q 64 180 82 180 Q 100 180 100 170 L 100 130 Q 100 100 82 100 Z" fill="url(#fHi)"/>
  <path d="M 68 92 L 84 92 L 84 104 L 68 104 Z" fill="#a8761e"/>
  <circle cx="76" cy="76" r="22" fill="url(#fHead1)"/>
  <ellipse cx="68" cy="68" rx="7" ry="5" fill="#ffffff" fill-opacity="0.55"/>
  <g transform="translate(154,46)">
    <circle cx="0" cy="0" r="18" fill="url(#fStar)"/>
    <circle cx="0" cy="0" r="18" fill="none" stroke="#a87018" stroke-width="0.5"/>
    <ellipse cx="-5" cy="-7" rx="5" ry="3" fill="#ffffff" fill-opacity="0.5"/>
    <rect x="-7" y="-2" width="14" height="4" rx="1" fill="#7a4a10"/>
    <rect x="-2" y="-7" width="4" height="14" rx="1" fill="#7a4a10"/>
  </g>
  <g fill="#fff5d0" opacity="0.9">
    <path d="M 28 50 L 30 54 L 34 56 L 30 58 L 28 62 L 26 58 L 22 56 L 26 54 Z"/>
    <path d="M 178 110 L 180 113 L 183 115 L 180 117 L 178 120 L 176 117 L 173 115 L 176 113 Z" opacity="0.7"/>
  </g>
</svg>
''';
