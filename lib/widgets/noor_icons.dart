import 'package:flutter/widgets.dart';
import 'dart:ui' as ui;

/// NoorIcon  3-D gradient SVG icon system.
/// Every method returns a sized, paint-rendered icon widget.
/// Usage:  NoorIcon.fire(size: 32)
class NoorIcon {
  NoorIcon._();

  static Widget fire({double size = 24}) => _w(_kFire, size);
  static Widget trophy({double size = 24}) => _w(_kTrophy, size);
  static Widget book({double size = 24}) => _w(_kBook, size);
  static Widget beads({double size = 24}) => _w(_kBeads, size);
  static Widget moon({double size = 24}) => _w(_kMoon, size);
  static Widget sun({double size = 24}) => _w(_kSun, size);
  static Widget sunrise({double size = 24}) => _w(_kSunrise, size);
  static Widget sunset({double size = 24}) => _w(_kSunset, size);
  static Widget coin({double size = 24}) => _w(_kCoin, size);
  static Widget sparkles({double size = 24}) => _w(_kSparkles, size);
  static Widget star({double size = 24}) => _w(_kStar, size);
  static Widget crown({double size = 24}) => _w(_kCrown, size);
  static Widget heart({double size = 24}) => _w(_kHeart, size);
  static Widget shield({double size = 24}) => _w(_kShield, size);
  static Widget globe({double size = 24}) => _w(_kGlobe, size);
  static Widget tree({double size = 24}) => _w(_kTree, size);
  static Widget seedling({double size = 24}) => _w(_kSeedling, size);
  static Widget leaf({double size = 24}) => _w(_kLeaf, size);
  static Widget hands({double size = 24}) => _w(_kHands, size);
  static Widget lightning({double size = 24}) => _w(_kLightning, size);
  static Widget drop({double size = 24}) => _w(_kDrop, size);
  static Widget mosque({double size = 24}) => _w(_kMosque, size);
  static Widget kaaba({double size = 24}) => _w(_kKaaba, size);
  static Widget medal({double size = 24}) => _w(_kMedal, size);
  static Widget goldMedal({double size = 24}) => _w(_kGoldMedal, size);
  static Widget silverMedal({double size = 24}) => _w(_kSilverMedal, size);
  static Widget bronzeMedal({double size = 24}) => _w(_kBronzeMedal, size);
  static Widget target({double size = 24}) => _w(_kTarget, size);
  static Widget gift({double size = 24}) => _w(_kGift, size);
  static Widget party({double size = 24}) => _w(_kParty, size);
  static Widget lock({double size = 24}) => _w(_kLock, size);
  static Widget calendar({double size = 24}) => _w(_kCalendar, size);
  static Widget microphone({double size = 24}) => _w(_kMicrophone, size);
  static Widget headphones({double size = 24}) => _w(_kHeadphones, size);
  static Widget books({double size = 24}) => _w(_kBooks, size);
  static Widget greenBook({double size = 24}) => _w(_kGreenBook, size);
  static Widget check({double size = 24}) => _w(_kCheck, size);
  static Widget handshake({double size = 24}) => _w(_kHandshake, size);
  static Widget share({double size = 24}) => _w(_kShare, size);
  static Widget chat({double size = 24}) => _w(_kChat, size);
  static Widget people({double size = 24}) => _w(_kPeople, size);
  static Widget compass({double size = 24}) => _w(_kCompass, size);
  static Widget airplane({double size = 24}) => _w(_kAirplane, size);
  static Widget flag({double size = 24}) => _w(_kFlag, size);
  static Widget megaphone({double size = 24}) => _w(_kMegaphone, size);
  static Widget palette({double size = 24}) => _w(_kPalette, size);
  static Widget gear({double size = 24}) => _w(_kGear, size);
  static Widget bookmark({double size = 24}) => _w(_kBookmark, size);
  static Widget scales({double size = 24}) => _w(_kScales, size);
  static Widget chains({double size = 24}) => _w(_kChains, size);
  static Widget bag({double size = 24}) => _w(_kBag, size);
  static Widget homeIcon({double size = 24}) => _w(_kHome, size);
  static Widget thunder({double size = 24}) => _w(_kThunder, size);
  static Widget image({double size = 24}) => _w(_kImage, size);
  static Widget play({double size = 24}) => _w(_kPlay, size);
  static Widget muscle({double size = 24}) => _w(_kMuscle, size);
  static Widget pointing({double size = 24}) => _w(_kPointing, size);
  static Widget rose({double size = 24}) => _w(_kRose, size);
  static Widget wave({double size = 24}) => _w(_kWave, size);
  static Widget crystal({double size = 24}) => _w(_kCrystal, size);
  static Widget blossom({double size = 24}) => _w(_kBlossom, size);
  static Widget night({double size = 24}) => _w(_kNight, size);
  static Widget food({double size = 24}) => _w(_kFood, size);
  static Widget shirt({double size = 24}) => _w(_kShirt, size);

  static Widget _w(List<_S> shapes, double sz) => SizedBox(
    width: sz,
    height: sz,
    child: CustomPaint(painter: _IconPainter(shapes)),
  );

  /// Maps an emoji string key to the appropriate NoorIcon widget.
  static Widget fromEmoji(String emoji, {double size = 24}) {
    switch (emoji) {
      case '🔥':
        return fire(size: size);
      case '🏆':
        return trophy(size: size);
      case '📖':
        return book(size: size);
      case '📿':
        return beads(size: size);
      case '🌙':
        return moon(size: size);
      case '☀️':
      case '🌅':
        return sunrise(size: size);
      case '🌇':
      case '🌆':
        return sunset(size: size);
      case '🪙':
        return coin(size: size);
      case '✨':
        return sparkles(size: size);
      case '⭐':
      case '🌟':
        return star(size: size);
      case '👑':
        return crown(size: size);
      case '❤️':
      case '💜':
      case '💚':
        return heart(size: size);
      case '🛡️':
        return shield(size: size);
      case '🌍':
      case '🌐':
        return globe(size: size);
      case '🌳':
        return tree(size: size);
      case '🌱':
        return seedling(size: size);
      case '🌿':
        return leaf(size: size);
      case '🤲':
        return hands(size: size);
      case '⚡':
        return lightning(size: size);
      case '💧':
        return drop(size: size);
      case '🕌':
        return mosque(size: size);
      case '🕋':
        return kaaba(size: size);
      case '🏅':
        return medal(size: size);
      case '🥇':
        return goldMedal(size: size);
      case '🥈':
        return silverMedal(size: size);
      case '🥉':
        return bronzeMedal(size: size);
      case '🎯':
        return target(size: size);
      case '🎁':
        return gift(size: size);
      case '🎉':
        return party(size: size);
      case '🔒':
        return lock(size: size);
      case '📅':
      case '🗓️':
        return calendar(size: size);
      case '🎙️':
        return microphone(size: size);
      case '🎧':
        return headphones(size: size);
      case '📚':
        return books(size: size);
      case '📗':
        return greenBook(size: size);
      case '✅':
        return check(size: size);
      case '🤝':
        return handshake(size: size);
      case '📤':
        return share(size: size);
      case '💬':
        return chat(size: size);
      case '👥':
        return people(size: size);
      case '🧭':
        return compass(size: size);
      case '✈️':
        return airplane(size: size);
      case '🚩':
        return flag(size: size);
      case '📢':
        return megaphone(size: size);
      case '🎨':
        return palette(size: size);
      case '⚙️':
        return gear(size: size);
      case '🔖':
        return bookmark(size: size);
      case '⚖️':
        return scales(size: size);
      case '⛓️':
        return chains(size: size);
      case '🛍️':
        return bag(size: size);
      case '🏠':
        return homeIcon(size: size);
      case '🌩️':
        return thunder(size: size);
      case '🖼️':
        return image(size: size);
      case '▶️':
        return play(size: size);
      case '💪':
        return muscle(size: size);
      case '🫵':
        return pointing(size: size);
      case '🥀':
        return rose(size: size);
      case '🌊':
        return wave(size: size);
      case '🔮':
        return crystal(size: size);
      case '🌸':
        return blossom(size: size);
      case '🌌':
      case '🌑':
        return night(size: size);
      case '🍽️':
        return food(size: size);
      case '👕':
        return shirt(size: size);
      case '📍':
        return pin(size: size);
      case '📱':
        return phone(size: size);
      case '👨\u200d👩\u200d👧':
        return family(size: size);
      case '🍂':
        return autumn(size: size);
      case '🎓':
        return graduation(size: size);
      case '📜':
        return scroll(size: size);
      case '🏛️':
        return arch(size: size);
      case '⏱️':
        return timer(size: size);
      case '🔡':
      case '🔤':
        return font(size: size);
      case '💎':
        return diamond(size: size);
      default:
        return star(size: size);
    }
  }

  static Widget family({double size = 24}) => _w(_kFamily, size);
  static Widget autumn({double size = 24}) => _w(_kAutumn, size);
  static Widget graduation({double size = 24}) => _w(_kGraduation, size);
  static Widget scroll({double size = 24}) => _w(_kScroll, size);
  static Widget arch({double size = 24}) => _w(_kArch, size);
  static Widget timer({double size = 24}) => _w(_kTimer, size);
  static Widget pin({double size = 24}) => _w(_kPin, size);
  static Widget phone({double size = 24}) => _w(_kPhone, size);
  static Widget font({double size = 24}) => _w(_kFont, size);
  static Widget record({double size = 24}) => _w(_kRecord, size);
  static Widget diamond({double size = 24}) => _w(_kDiamond, size);
  static Widget sword({double size = 24}) => _w(_kSword, size);
}

//  Shape record — supports fill gradient or stroke outline
class _S {
  final Color c1, c2;
  final String type; // 'circle','rect','path','stroke_path','stroke_circle'
  final String d;
  final bool radial;
  final double x, y, w, h, r, sw; // sw = stroke width fraction
  const _S({
    required this.type,
    this.d = '',
    this.c1 = const Color(0xFFFFFFFF),
    this.c2 = const Color(0xFFCCCCCC),
    this.x = 0,
    this.y = 0,
    this.w = 1,
    this.h = 1,
    this.r = 0,
    this.radial = false,
    this.sw = 0.06,
  });
}

class _IconPainter extends CustomPainter {
  final List<_S> shapes;
  const _IconPainter(this.shapes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in shapes) {
      final isStroke = s.type.startsWith('stroke_');
      final paint =
          Paint()
            ..style = isStroke ? PaintingStyle.stroke : PaintingStyle.fill
            ..strokeWidth = isStroke ? s.sw * size.width : 0
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;
      if (!isStroke) {
        if (s.radial) {
          paint.shader = ui.Gradient.radial(
            Offset(size.width * (s.x + s.w / 2), size.height * (s.y + s.h / 2)),
            size.width * s.w * 0.6,
            [s.c1, s.c2],
          );
        } else {
          paint.shader = ui.Gradient.linear(
            Offset(size.width * s.x, size.height * s.y),
            Offset(size.width * (s.x + s.w), size.height * (s.y + s.h)),
            [s.c1, s.c2],
          );
        }
      } else {
        paint.color = s.c1;
      }
      if (s.type == 'circle' || s.type == 'stroke_circle') {
        canvas.drawCircle(
          Offset(size.width * (s.x + s.w / 2), size.height * (s.y + s.h / 2)),
          size.width * s.r,
          paint,
        );
      } else if (s.type == 'path' || s.type == 'stroke_path') {
        final path = _parsePath(s.d, size);
        canvas.drawPath(path, paint);
      } else if (s.type == 'rect') {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * s.x,
              size.height * s.y,
              size.width * s.w,
              size.height * s.h,
            ),
            Radius.circular(size.width * s.r),
          ),
          paint,
        );
      }
    }
  }

  Path _parsePath(String d, Size size) {
    final path = Path();
    final cmds = d.trim().split(RegExp(r'(?=[MLCQZAHVz])'));
    for (var cmd in cmds) {
      cmd = cmd.trim();
      if (cmd.isEmpty) continue;
      final op = cmd[0];
      final nums =
          RegExp(r'[-\d.]+')
              .allMatches(cmd.substring(1))
              .map((m) => double.tryParse(m.group(0)!) ?? 0.0)
              .toList();
      double n(int i) => i < nums.length ? nums[i] : 0;
      double px(int i) => n(i) * size.width;
      double py(int i) => n(i) * size.height;
      switch (op) {
        case 'M':
          path.moveTo(px(0), py(1));
        case 'L':
          path.lineTo(px(0), py(1));
        case 'C':
          path.cubicTo(px(0), py(1), px(2), py(3), px(4), py(5));
        case 'Q':
          path.quadraticBezierTo(px(0), py(1), px(2), py(3));
        case 'Z':
        case 'z':
          path.close();
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(_IconPainter o) => false;
}

//  SVG Shape Constants

const _kFire = [
  _S(
    type: 'path',
    d: 'M0.5 1.0 Q0.3 0.7 0.35 0.5 Q0.2 0.6 0.25 0.8 Q0.1 0.55 0.2 0.35 Q0.5 0.0 0.5 0.0 Q0.8 0.35 0.75 0.5 Q0.8 0.25 0.65 0.3 Q0.9 0.55 0.75 0.8 Q0.8 0.6 0.65 0.5 Q0.7 0.7 0.5 1.0Z',
    c1: Color(0xFFFF6B00),
    c2: Color(0xFFFF2D00),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.95 Q0.35 0.75 0.4 0.6 Q0.3 0.7 0.35 0.82 Q0.25 0.62 0.38 0.52 Q0.5 0.3 0.5 0.3 Q0.62 0.52 0.65 0.55 Q0.75 0.62 0.65 0.82 Q0.7 0.7 0.6 0.6 Q0.65 0.75 0.5 0.95Z',
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFF8C00),
  ),
];

const _kTrophy = [
  // Dark base block
  _S(
    type: 'rect',
    x: 0.12,
    y: 0.84,
    w: 0.76,
    h: 0.12,
    r: 0.04,
    c1: Color(0xFF37474F),
    c2: Color(0xFF263238),
  ),
  // Gold plaque on base
  _S(
    type: 'rect',
    x: 0.28,
    y: 0.87,
    w: 0.44,
    h: 0.06,
    r: 0.02,
    c1: Color(0xFFDAA520),
    c2: Color(0xFFB8860B),
  ),
  // Stem
  _S(
    type: 'rect',
    x: 0.40,
    y: 0.68,
    w: 0.20,
    h: 0.18,
    r: 0.03,
    c1: Color(0xFFDAA520),
    c2: Color(0xFFB8860B),
  ),
  // Stem base flare
  _S(
    type: 'rect',
    x: 0.28,
    y: 0.80,
    w: 0.44,
    h: 0.06,
    r: 0.03,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFDAA520),
  ),
  // Cup body
  _S(
    type: 'path',
    d: 'M0.22 0.10 L0.78 0.10 Q0.84 0.10 0.84 0.18 L0.84 0.46 Q0.84 0.68 0.50 0.70 Q0.16 0.68 0.16 0.46 L0.16 0.18 Q0.16 0.10 0.22 0.10Z',
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFDAA520),
  ),
  // Cup highlight
  _S(
    type: 'path',
    d: 'M0.24 0.12 L0.55 0.12 Q0.60 0.12 0.60 0.18 L0.60 0.44 Q0.58 0.55 0.50 0.58',
    c1: Color(0xFFFFFFAA),
    c2: Color(0xFFFFEC6E),
  ),
  // Left handle
  _S(
    type: 'path',
    d: 'M0.16 0.22 Q0.04 0.26 0.04 0.40 Q0.04 0.54 0.16 0.56',
    c1: Color(0xFFFFD700),
    c2: Color(0xFFDAA520),
  ),
  _S(
    type: 'stroke_path',
    d: 'M0.16 0.22 Q0.03 0.27 0.03 0.40 Q0.03 0.54 0.16 0.56',
    sw: 0.07,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFFD700),
  ),
  // Right handle
  _S(
    type: 'stroke_path',
    d: 'M0.84 0.22 Q0.97 0.27 0.97 0.40 Q0.97 0.54 0.84 0.56',
    sw: 0.07,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFFD700),
  ),
];

const _kBook = [
  _S(
    type: 'rect',
    x: 0.08,
    y: 0.12,
    w: 0.84,
    h: 0.76,
    r: 0.06,
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'rect',
    x: 0.12,
    y: 0.16,
    w: 0.37,
    h: 0.68,
    r: 0.03,
    c1: Color(0xFFF5F5F5),
    c2: Color(0xFFE0E0E0),
  ),
  _S(
    type: 'rect',
    x: 0.51,
    y: 0.16,
    w: 0.37,
    h: 0.68,
    r: 0.03,
    c1: Color(0xFFF5F5F5),
    c2: Color(0xFFE8E8E8),
  ),
  _S(
    type: 'rect',
    x: 0.465,
    y: 0.12,
    w: 0.07,
    h: 0.76,
    r: 0.02,
    c1: Color(0xFF42A5F5),
    c2: Color(0xFF1565C0),
  ),
  _S(
    type: 'rect',
    x: 0.18,
    y: 0.28,
    w: 0.25,
    h: 0.03,
    r: 0.015,
    c1: Color(0xFF90CAF9),
    c2: Color(0xFF42A5F5),
  ),
  _S(
    type: 'rect',
    x: 0.18,
    y: 0.36,
    w: 0.25,
    h: 0.03,
    r: 0.015,
    c1: Color(0xFF90CAF9),
    c2: Color(0xFF42A5F5),
  ),
  _S(
    type: 'rect',
    x: 0.18,
    y: 0.44,
    w: 0.2,
    h: 0.03,
    r: 0.015,
    c1: Color(0xFF90CAF9),
    c2: Color(0xFF42A5F5),
  ),
];

const _kBeads = [
  // Strand loop — smooth closed oval
  _S(
    type: 'stroke_path',
    d: 'M0.50 0.10 Q0.88 0.10 0.90 0.50 Q0.88 0.88 0.50 0.90 Q0.12 0.88 0.10 0.50 Q0.12 0.12 0.50 0.10Z',
    sw: 0.055,
    c1: Color(0xFFB8860B),
    c2: Color(0xFFB8860B),
  ),
  // 9 beads — all r:0.075, evenly spaced at 40° intervals around the oval
  // top
  _S(
    type: 'circle',
    x: 0.425,
    y: 0.04,
    w: 0.15,
    h: 0.15,
    r: 0.075,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFB8860B),
    radial: true,
  ),
  // top-right
  _S(
    type: 'circle',
    x: 0.68,
    y: 0.10,
    w: 0.15,
    h: 0.15,
    r: 0.075,
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFDAA520),
    radial: true,
  ),
  // right-top
  _S(
    type: 'circle',
    x: 0.845,
    y: 0.27,
    w: 0.15,
    h: 0.15,
    r: 0.075,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFB8860B),
    radial: true,
  ),
  // right
  _S(
    type: 'circle',
    x: 0.845,
    y: 0.50,
    w: 0.15,
    h: 0.15,
    r: 0.075,
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFDAA520),
    radial: true,
  ),
  // right-bottom
  _S(
    type: 'circle',
    x: 0.70,
    y: 0.76,
    w: 0.15,
    h: 0.15,
    r: 0.075,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFB8860B),
    radial: true,
  ),
  // bottom
  _S(
    type: 'circle',
    x: 0.425,
    y: 0.82,
    w: 0.15,
    h: 0.15,
    r: 0.075,
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFDAA520),
    radial: true,
  ),
  // left-bottom
  _S(
    type: 'circle',
    x: 0.155,
    y: 0.73,
    w: 0.15,
    h: 0.15,
    r: 0.075,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFB8860B),
    radial: true,
  ),
  // left
  _S(
    type: 'circle',
    x: 0.055,
    y: 0.50,
    w: 0.15,
    h: 0.15,
    r: 0.075,
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFDAA520),
    radial: true,
  ),
  // left-top
  _S(
    type: 'circle',
    x: 0.155,
    y: 0.24,
    w: 0.15,
    h: 0.15,
    r: 0.075,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFB8860B),
    radial: true,
  ),
  // Tassel connector
  _S(
    type: 'rect',
    x: 0.47,
    y: 0.90,
    w: 0.06,
    h: 0.05,
    r: 0.02,
    c1: Color(0xFFB8860B),
    c2: Color(0xFF8B6914),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.95 Q0.44 0.97 0.46 1.0 Q0.5 1.02 0.54 1.0 Q0.56 0.97 0.5 0.95Z',
    c1: Color(0xFFDAA520),
    c2: Color(0xFFB8860B),
  ),
];

const _kMoon = [
  _S(
    type: 'path',
    d: 'M0.68 0.1 Q0.35 0.15 0.18 0.42 Q0.05 0.65 0.18 0.82 Q0.35 0.98 0.6 0.92 Q0.82 0.85 0.9 0.65 Q0.75 0.72 0.6 0.65 Q0.38 0.5 0.42 0.25 Q0.45 0.1 0.68 0.1Z',
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFFFAA00),
    radial: true,
  ),
  _S(
    type: 'circle',
    x: 0.6,
    y: 0.2,
    w: 0.12,
    h: 0.12,
    r: 0.05,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFFAA00),
  ),
];

const _kSun = [
  _S(
    type: 'circle',
    x: 0.22,
    y: 0.22,
    w: 0.56,
    h: 0.56,
    r: 0.28,
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFFF8F00),
    radial: true,
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.02 L0.53 0.15 L0.47 0.15Z',
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFF8F00),
  ),
  _S(
    type: 'path',
    d: 'M0.98 0.5 L0.85 0.53 L0.85 0.47Z',
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFF8F00),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.98 L0.53 0.85 L0.47 0.85Z',
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFF8F00),
  ),
  _S(
    type: 'path',
    d: 'M0.02 0.5 L0.15 0.53 L0.15 0.47Z',
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFF8F00),
  ),
  _S(
    type: 'path',
    d: 'M0.85 0.15 L0.76 0.25 L0.72 0.22Z',
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFF8F00),
  ),
  _S(
    type: 'path',
    d: 'M0.85 0.85 L0.75 0.76 L0.78 0.72Z',
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFF8F00),
  ),
  _S(
    type: 'path',
    d: 'M0.15 0.85 L0.24 0.75 L0.28 0.78Z',
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFF8F00),
  ),
  _S(
    type: 'path',
    d: 'M0.15 0.15 L0.25 0.24 L0.22 0.28Z',
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFF8F00),
  ),
];

const _kSunrise = [
  _S(
    type: 'rect',
    x: 0.0,
    y: 0.65,
    w: 1.0,
    h: 0.35,
    r: 0.0,
    c1: Color(0xFF1A237E),
    c2: Color(0xFF283593),
  ),
  _S(
    type: 'path',
    d: 'M0.0 0.65 Q0.25 0.35 0.5 0.35 Q0.75 0.35 1.0 0.65Z',
    c1: Color(0xFFFF6F00),
    c2: Color(0xFFFFAB00),
  ),
  _S(
    type: 'circle',
    x: 0.32,
    y: 0.32,
    w: 0.36,
    h: 0.36,
    r: 0.18,
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFFF8F00),
    radial: true,
  ),
];

const _kSunset = [
  _S(
    type: 'rect',
    x: 0.0,
    y: 0.0,
    w: 1.0,
    h: 0.65,
    r: 0.0,
    c1: Color(0xFFFF6F00),
    c2: Color(0xFFE53935),
  ),
  _S(
    type: 'rect',
    x: 0.0,
    y: 0.65,
    w: 1.0,
    h: 0.35,
    r: 0.0,
    c1: Color(0xFF1A237E),
    c2: Color(0xFF0D1450),
  ),
  _S(
    type: 'path',
    d: 'M0.0 0.65 Q0.25 0.35 0.5 0.35 Q0.75 0.35 1.0 0.65Z',
    c1: Color(0xFFFFAB40),
    c2: Color(0xFFFF6F00),
  ),
];

const _kCoin = [
  _S(
    type: 'circle',
    x: 0.05,
    y: 0.05,
    w: 0.9,
    h: 0.9,
    r: 0.45,
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFDAA520),
    radial: true,
  ),
  _S(
    type: 'circle',
    x: 0.12,
    y: 0.12,
    w: 0.76,
    h: 0.76,
    r: 0.35,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFB8860B),
  ),
  _S(
    type: 'path',
    d: 'M0.42 0.28 L0.42 0.38 Q0.32 0.4 0.3 0.5 Q0.3 0.62 0.42 0.65 L0.42 0.72 L0.5 0.72 L0.5 0.65 Q0.6 0.63 0.65 0.55 L0.57 0.5 Q0.55 0.57 0.5 0.58 L0.42 0.58 Q0.38 0.55 0.38 0.5 Q0.38 0.45 0.42 0.43 L0.58 0.43 Q0.7 0.4 0.7 0.3 Q0.7 0.2 0.58 0.18 L0.58 0.12 L0.5 0.12 L0.5 0.18 Q0.4 0.2 0.36 0.28Z',
    c1: Color(0xFF8B6914),
    c2: Color(0xFF5C4400),
  ),
];

const _kSparkles = [
  _S(
    type: 'path',
    d: 'M0.5 0.05 L0.54 0.42 L0.9 0.38 L0.54 0.5 L0.9 0.62 L0.54 0.58 L0.5 0.95 L0.46 0.58 L0.1 0.62 L0.46 0.5 L0.1 0.38 L0.46 0.42Z',
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFFFAA00),
  ),
  _S(
    type: 'path',
    d: 'M0.82 0.08 L0.84 0.22 L0.96 0.22 L0.86 0.3 L0.9 0.44 L0.82 0.34 L0.74 0.44 L0.78 0.3 L0.68 0.22 L0.8 0.22Z',
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFF8F00),
  ),
  _S(
    type: 'path',
    d: 'M0.18 0.55 L0.2 0.66 L0.3 0.66 L0.22 0.72 L0.25 0.82 L0.18 0.76 L0.11 0.82 L0.14 0.72 L0.06 0.66 L0.16 0.66Z',
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFF8F00),
  ),
];

const _kStar = [
  _S(
    type: 'path',
    d: 'M0.5 0.05 L0.61 0.38 L0.96 0.38 L0.68 0.59 L0.79 0.92 L0.5 0.72 L0.21 0.92 L0.32 0.59 L0.04 0.38 L0.39 0.38Z',
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFFFAA00),
  ),
];

const _kCrown = [
  _S(
    type: 'path',
    d: 'M0.08 0.75 L0.08 0.45 L0.25 0.65 L0.5 0.15 L0.75 0.65 L0.92 0.45 L0.92 0.75Z',
    c1: Color(0xFFFFD700),
    c2: Color(0xFFBC8C00),
  ),
  _S(
    type: 'rect',
    x: 0.08,
    y: 0.75,
    w: 0.84,
    h: 0.12,
    r: 0.03,
    c1: Color(0xFFDAA520),
    c2: Color(0xFF8B6914),
  ),
  _S(
    type: 'circle',
    x: 0.44,
    y: 0.1,
    w: 0.12,
    h: 0.12,
    r: 0.05,
    c1: Color(0xFFE53935),
    c2: Color(0xFFB71C1C),
  ),
  _S(
    type: 'circle',
    x: 0.2,
    y: 0.6,
    w: 0.1,
    h: 0.1,
    r: 0.04,
    c1: Color(0xFF42A5F5),
    c2: Color(0xFF1565C0),
  ),
  _S(
    type: 'circle',
    x: 0.7,
    y: 0.6,
    w: 0.1,
    h: 0.1,
    r: 0.04,
    c1: Color(0xFF66BB6A),
    c2: Color(0xFF2E7D32),
  ),
];

const _kHeart = [
  _S(
    type: 'path',
    d: 'M0.5 0.88 Q0.1 0.6 0.1 0.38 Q0.1 0.12 0.3 0.12 Q0.42 0.12 0.5 0.25 Q0.58 0.12 0.7 0.12 Q0.9 0.12 0.9 0.38 Q0.9 0.6 0.5 0.88Z',
    c1: Color(0xFFFF4081),
    c2: Color(0xFFE91E63),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.75 Q0.22 0.54 0.22 0.38 Q0.22 0.25 0.35 0.25 Q0.44 0.25 0.5 0.35 Q0.56 0.25 0.65 0.25 Q0.78 0.25 0.78 0.38 Q0.78 0.54 0.5 0.75Z',
    c1: Color(0xFFFF80AB),
    c2: Color(0xFFFF4081),
  ),
];

const _kShield = [
  _S(
    type: 'path',
    d: 'M0.5 0.05 L0.9 0.22 L0.9 0.5 Q0.9 0.82 0.5 0.95 Q0.1 0.82 0.1 0.5 L0.1 0.22Z',
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.15 L0.82 0.28 L0.82 0.5 Q0.82 0.75 0.5 0.86 Q0.18 0.75 0.18 0.5 L0.18 0.28Z',
    c1: Color(0xFF42A5F5),
    c2: Color(0xFF1565C0),
  ),
  _S(
    type: 'path',
    d: 'M0.35 0.5 L0.45 0.62 L0.65 0.36',
    c1: Color(0xFFFFFFFF),
    c2: Color(0xFFE0E0E0),
  ),
];

const _kGlobe = [
  _S(
    type: 'circle',
    x: 0.05,
    y: 0.05,
    w: 0.9,
    h: 0.9,
    r: 0.45,
    c1: Color(0xFF1E88E5),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.05 Q0.35 0.25 0.35 0.5 Q0.35 0.75 0.5 0.95 Q0.65 0.75 0.65 0.5 Q0.65 0.25 0.5 0.05Z',
    c1: Color(0xFF66BB6A),
    c2: Color(0xFF2E7D32),
  ),
  _S(
    type: 'rect',
    x: 0.08,
    y: 0.47,
    w: 0.84,
    h: 0.06,
    r: 0.03,
    c1: Color(0xFF90CAF9),
    c2: Color(0xFF42A5F5),
  ),
  _S(
    type: 'path',
    d: 'M0.2 0.22 Q0.5 0.3 0.8 0.22',
    c1: Color(0xFF90CAF9),
    c2: Color(0xFF42A5F5),
  ),
  _S(
    type: 'path',
    d: 'M0.2 0.78 Q0.5 0.7 0.8 0.78',
    c1: Color(0xFF90CAF9),
    c2: Color(0xFF42A5F5),
  ),
];

const _kTree = [
  _S(
    type: 'rect',
    x: 0.43,
    y: 0.65,
    w: 0.14,
    h: 0.3,
    r: 0.03,
    c1: Color(0xFF6D4C41),
    c2: Color(0xFF4E342E),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.05 L0.78 0.42 L0.64 0.42 L0.85 0.7 L0.62 0.7 L0.82 0.92 L0.18 0.92 L0.38 0.7 L0.15 0.7 L0.36 0.42 L0.22 0.42Z',
    c1: Color(0xFF66BB6A),
    c2: Color(0xFF1B5E20),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.05 L0.68 0.35 L0.58 0.35 L0.5 0.2Z',
    c1: Color(0xFFA5D6A7),
    c2: Color(0xFF66BB6A),
  ),
];

const _kSeedling = [
  _S(
    type: 'rect',
    x: 0.46,
    y: 0.55,
    w: 0.08,
    h: 0.38,
    r: 0.03,
    c1: Color(0xFF6D4C41),
    c2: Color(0xFF4E342E),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.55 Q0.3 0.3 0.15 0.35 Q0.12 0.55 0.3 0.6 Q0.4 0.62 0.5 0.55Z',
    c1: Color(0xFF66BB6A),
    c2: Color(0xFF2E7D32),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.55 Q0.7 0.3 0.85 0.35 Q0.88 0.55 0.7 0.6 Q0.6 0.62 0.5 0.55Z',
    c1: Color(0xFF81C784),
    c2: Color(0xFF388E3C),
  ),
];

const _kLeaf = [
  _S(
    type: 'path',
    d: 'M0.5 0.9 Q0.08 0.6 0.2 0.2 Q0.5 0.0 0.8 0.2 Q0.92 0.6 0.5 0.9Z',
    c1: Color(0xFF66BB6A),
    c2: Color(0xFF1B5E20),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.9 L0.5 0.2',
    c1: Color(0xFFA5D6A7),
    c2: Color(0xFF66BB6A),
  ),
];

const _kHands = [
  _S(
    type: 'path',
    d: 'M0.5 0.85 Q0.18 0.65 0.15 0.45 L0.25 0.42 L0.28 0.55 Q0.28 0.38 0.32 0.3 L0.4 0.3 L0.42 0.45 Q0.42 0.25 0.46 0.18 L0.54 0.18 L0.56 0.35 Q0.58 0.22 0.62 0.2 L0.68 0.22 L0.68 0.4 Q0.7 0.28 0.76 0.28 L0.8 0.32 Q0.82 0.5 0.75 0.6 Q0.7 0.7 0.5 0.85Z',
    c1: Color(0xFFFFCC80),
    c2: Color(0xFFE65100),
  ),
  _S(
    type: 'path',
    d: 'M0.35 0.2 Q0.42 0.15 0.5 0.15 Q0.58 0.15 0.65 0.2',
    c1: Color(0xFF00BCD4),
    c2: Color(0xFF006064),
  ),
];

const _kLightning = [
  _S(
    type: 'path',
    d: 'M0.62 0.05 L0.3 0.48 L0.52 0.48 L0.38 0.95 L0.72 0.42 L0.5 0.42Z',
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFFFAA00),
  ),
  _S(
    type: 'path',
    d: 'M0.58 0.05 L0.35 0.44 L0.5 0.44 L0.42 0.72 L0.62 0.38 L0.48 0.38Z',
    c1: Color(0xFFFFFFFF),
    c2: Color(0xFFFFEC6E),
  ),
];

const _kDrop = [
  _S(
    type: 'path',
    d: 'M0.5 0.05 Q0.7 0.35 0.7 0.55 Q0.7 0.78 0.5 0.92 Q0.3 0.78 0.3 0.55 Q0.3 0.35 0.5 0.05Z',
    c1: Color(0xFF29B6F6),
    c2: Color(0xFF0277BD),
    radial: true,
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.12 Q0.63 0.35 0.63 0.52 Q0.63 0.68 0.5 0.8',
    c1: Color(0xFF81D4FA),
    c2: Color(0xFF29B6F6),
  ),
];

const _kMosque = [
  _S(
    type: 'rect',
    x: 0.05,
    y: 0.55,
    w: 0.9,
    h: 0.4,
    r: 0.04,
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.08 Q0.7 0.15 0.7 0.35 L0.7 0.55 L0.3 0.55 L0.3 0.35 Q0.3 0.15 0.5 0.08Z',
    c1: Color(0xFF42A5F5),
    c2: Color(0xFF1565C0),
  ),
  _S(
    type: 'rect',
    x: 0.12,
    y: 0.55,
    w: 0.22,
    h: 0.38,
    r: 0.06,
    c1: Color(0xFF1976D2),
    c2: Color(0xFF1565C0),
  ),
  _S(
    type: 'rect',
    x: 0.66,
    y: 0.55,
    w: 0.22,
    h: 0.38,
    r: 0.06,
    c1: Color(0xFF1976D2),
    c2: Color(0xFF1565C0),
  ),
  _S(
    type: 'path',
    d: 'M0.48 0.02 L0.52 0.02 L0.54 0.1 L0.5 0.13 L0.46 0.1Z',
    c1: Color(0xFFFFD700),
    c2: Color(0xFFDAA520),
  ),
  _S(
    type: 'path',
    d: 'M0.38 0.62 L0.62 0.62 L0.62 0.9 L0.38 0.9Z',
    c1: Color(0xFF0D47A1),
    c2: Color(0xFF1A237E),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.62 Q0.62 0.68 0.62 0.78 Q0.62 0.88 0.5 0.9 Q0.38 0.88 0.38 0.78 Q0.38 0.68 0.5 0.62Z',
    c1: Color(0xFF0D47A1),
    c2: Color(0xFF1A237E),
  ),
];

const _kKaaba = [
  _S(
    type: 'path',
    d: 'M0.15 0.35 L0.5 0.12 L0.85 0.35 L0.85 0.88 L0.15 0.88Z',
    c1: Color(0xFF212121),
    c2: Color(0xFF000000),
  ),
  _S(
    type: 'path',
    d: 'M0.15 0.35 L0.5 0.12 L0.85 0.35',
    c1: Color(0xFF424242),
    c2: Color(0xFF212121),
  ),
  _S(
    type: 'rect',
    x: 0.25,
    y: 0.52,
    w: 0.5,
    h: 0.06,
    r: 0.02,
    c1: Color(0xFFDAA520),
    c2: Color(0xFF8B6914),
  ),
  _S(
    type: 'rect',
    x: 0.38,
    y: 0.62,
    w: 0.24,
    h: 0.18,
    r: 0.03,
    c1: Color(0xFF4E342E),
    c2: Color(0xFF3E2723),
  ),
];

const _kMedal = [
  _S(
    type: 'path',
    d: 'M0.45 0.02 L0.55 0.02 L0.65 0.35 L0.35 0.35Z',
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'circle',
    x: 0.22,
    y: 0.42,
    w: 0.56,
    h: 0.56,
    r: 0.28,
    c1: Color(0xFFDAA520),
    c2: Color(0xFF8B6914),
    radial: true,
  ),
  _S(
    type: 'circle',
    x: 0.28,
    y: 0.48,
    w: 0.44,
    h: 0.44,
    r: 0.22,
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFDAA520),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.54 L0.54 0.65 L0.64 0.65 L0.56 0.72 L0.6 0.82 L0.5 0.76 L0.4 0.82 L0.44 0.72 L0.36 0.65 L0.46 0.65Z',
    c1: Color(0xFF8B6914),
    c2: Color(0xFF5C4400),
  ),
];

const _kGoldMedal = [
  _S(
    type: 'circle',
    x: 0.1,
    y: 0.1,
    w: 0.8,
    h: 0.8,
    r: 0.4,
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFDAA520),
    radial: true,
  ),
  _S(
    type: 'circle',
    x: 0.18,
    y: 0.18,
    w: 0.64,
    h: 0.64,
    r: 0.3,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFB8860B),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.28 L0.54 0.42 L0.68 0.42 L0.56 0.5 L0.6 0.65 L0.5 0.56 L0.4 0.65 L0.44 0.5 L0.32 0.42 L0.46 0.42Z',
    c1: Color(0xFF8B6914),
    c2: Color(0xFF5C4400),
  ),
];

const _kSilverMedal = [
  _S(
    type: 'circle',
    x: 0.1,
    y: 0.1,
    w: 0.8,
    h: 0.8,
    r: 0.4,
    c1: Color(0xFFEEEEEE),
    c2: Color(0xFF9E9E9E),
    radial: true,
  ),
  _S(
    type: 'circle',
    x: 0.18,
    y: 0.18,
    w: 0.64,
    h: 0.64,
    r: 0.3,
    c1: Color(0xFFE0E0E0),
    c2: Color(0xFF757575),
  ),
  _S(
    type: 'path',
    d: 'M0.42 0.35 Q0.42 0.28 0.5 0.25 Q0.62 0.25 0.62 0.35 Q0.62 0.45 0.5 0.5 L0.5 0.58 L0.62 0.58 L0.62 0.65 L0.38 0.65 L0.38 0.6 Q0.52 0.48 0.52 0.5 Q0.6 0.42 0.58 0.36 Q0.56 0.3 0.5 0.3 Q0.45 0.3 0.44 0.35Z',
    c1: Color(0xFF616161),
    c2: Color(0xFF424242),
  ),
];

const _kBronzeMedal = [
  _S(
    type: 'circle',
    x: 0.1,
    y: 0.1,
    w: 0.8,
    h: 0.8,
    r: 0.4,
    c1: Color(0xFFFFCC80),
    c2: Color(0xFFE65100),
    radial: true,
  ),
  _S(
    type: 'circle',
    x: 0.18,
    y: 0.18,
    w: 0.64,
    h: 0.64,
    r: 0.3,
    c1: Color(0xFFFFB74D),
    c2: Color(0xFFBF360C),
  ),
  _S(
    type: 'path',
    d: 'M0.4 0.32 Q0.4 0.25 0.5 0.25 Q0.6 0.25 0.62 0.32 Q0.64 0.4 0.56 0.42 Q0.65 0.45 0.65 0.53 Q0.65 0.65 0.5 0.68 Q0.35 0.65 0.35 0.53 Q0.35 0.45 0.44 0.42 Q0.38 0.39 0.4 0.32Z',
    c1: Color(0xFFBF360C),
    c2: Color(0xFF7F1A00),
  ),
];

const _kTarget = [
  _S(
    type: 'circle',
    x: 0.05,
    y: 0.05,
    w: 0.9,
    h: 0.9,
    r: 0.45,
    c1: Color(0xFFE53935),
    c2: Color(0xFFB71C1C),
  ),
  _S(
    type: 'circle',
    x: 0.18,
    y: 0.18,
    w: 0.64,
    h: 0.64,
    r: 0.3,
    c1: Color(0xFFFFFFFF),
    c2: Color(0xFFEEEEEE),
  ),
  _S(
    type: 'circle',
    x: 0.3,
    y: 0.3,
    w: 0.4,
    h: 0.4,
    r: 0.18,
    c1: Color(0xFFE53935),
    c2: Color(0xFFB71C1C),
  ),
  _S(
    type: 'circle',
    x: 0.4,
    y: 0.4,
    w: 0.2,
    h: 0.2,
    r: 0.09,
    c1: Color(0xFFFFFFFF),
    c2: Color(0xFFEEEEEE),
  ),
  _S(
    type: 'circle',
    x: 0.44,
    y: 0.44,
    w: 0.12,
    h: 0.12,
    r: 0.055,
    c1: Color(0xFFE53935),
    c2: Color(0xFFB71C1C),
  ),
];

const _kGift = [
  _S(
    type: 'rect',
    x: 0.08,
    y: 0.45,
    w: 0.84,
    h: 0.5,
    r: 0.05,
    c1: Color(0xFFE91E63),
    c2: Color(0xFFAD1457),
  ),
  _S(
    type: 'rect',
    x: 0.05,
    y: 0.35,
    w: 0.9,
    h: 0.14,
    r: 0.04,
    c1: Color(0xFFFF4081),
    c2: Color(0xFFE91E63),
  ),
  _S(
    type: 'rect',
    x: 0.44,
    y: 0.35,
    w: 0.12,
    h: 0.6,
    r: 0.02,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFDAA520),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.35 Q0.35 0.15 0.25 0.2 Q0.18 0.28 0.28 0.35Z',
    c1: Color(0xFFFF4081),
    c2: Color(0xFFE91E63),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.35 Q0.65 0.15 0.75 0.2 Q0.82 0.28 0.72 0.35Z',
    c1: Color(0xFFFF80AB),
    c2: Color(0xFFFF4081),
  ),
];

const _kParty = [
  _S(
    type: 'path',
    d: 'M0.1 0.9 L0.42 0.45 L0.55 0.58Z',
    c1: Color(0xFFFF6F00),
    c2: Color(0xFFE65100),
  ),
  _S(
    type: 'circle',
    x: 0.52,
    y: 0.08,
    w: 0.18,
    h: 0.18,
    r: 0.08,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFF8F00),
  ),
  _S(
    type: 'circle',
    x: 0.72,
    y: 0.25,
    w: 0.14,
    h: 0.14,
    r: 0.06,
    c1: Color(0xFFE91E63),
    c2: Color(0xFFAD1457),
  ),
  _S(
    type: 'circle',
    x: 0.65,
    y: 0.52,
    w: 0.12,
    h: 0.12,
    r: 0.055,
    c1: Color(0xFF7E57C2),
    c2: Color(0xFF4527A0),
  ),
  _S(
    type: 'circle',
    x: 0.82,
    y: 0.45,
    w: 0.1,
    h: 0.1,
    r: 0.045,
    c1: Color(0xFF26A69A),
    c2: Color(0xFF00695C),
  ),
  _S(
    type: 'path',
    d: 'M0.55 0.3 L0.6 0.18 M0.7 0.38 L0.78 0.28 M0.62 0.5 L0.72 0.45',
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFF8F00),
  ),
];

const _kLock = [
  _S(
    type: 'rect',
    x: 0.2,
    y: 0.45,
    w: 0.6,
    h: 0.48,
    r: 0.07,
    c1: Color(0xFF5C6BC0),
    c2: Color(0xFF283593),
  ),
  _S(
    type: 'path',
    d: 'M0.33 0.45 L0.33 0.3 Q0.33 0.1 0.5 0.1 Q0.67 0.1 0.67 0.3 L0.67 0.45',
    c1: Color(0xFF7986CB),
    c2: Color(0xFF3949AB),
  ),
  _S(
    type: 'circle',
    x: 0.42,
    y: 0.6,
    w: 0.16,
    h: 0.16,
    r: 0.07,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFDAA520),
  ),
  _S(
    type: 'rect',
    x: 0.47,
    y: 0.66,
    w: 0.06,
    h: 0.1,
    r: 0.02,
    c1: Color(0xFFDAA520),
    c2: Color(0xFF8B6914),
  ),
];

const _kCalendar = [
  _S(
    type: 'rect',
    x: 0.05,
    y: 0.15,
    w: 0.9,
    h: 0.8,
    r: 0.06,
    c1: Color(0xFFF5F5F5),
    c2: Color(0xFFE0E0E0),
  ),
  _S(
    type: 'rect',
    x: 0.05,
    y: 0.15,
    w: 0.9,
    h: 0.22,
    r: 0.06,
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'rect',
    x: 0.28,
    y: 0.06,
    w: 0.08,
    h: 0.18,
    r: 0.03,
    c1: Color(0xFF90CAF9),
    c2: Color(0xFF42A5F5),
  ),
  _S(
    type: 'rect',
    x: 0.64,
    y: 0.06,
    w: 0.08,
    h: 0.18,
    r: 0.03,
    c1: Color(0xFF90CAF9),
    c2: Color(0xFF42A5F5),
  ),
  _S(
    type: 'rect',
    x: 0.12,
    y: 0.46,
    w: 0.12,
    h: 0.1,
    r: 0.02,
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'rect',
    x: 0.3,
    y: 0.46,
    w: 0.12,
    h: 0.1,
    r: 0.02,
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'rect',
    x: 0.48,
    y: 0.46,
    w: 0.12,
    h: 0.1,
    r: 0.02,
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'rect',
    x: 0.66,
    y: 0.46,
    w: 0.12,
    h: 0.1,
    r: 0.02,
    c1: Color(0xFFE53935),
    c2: Color(0xFFB71C1C),
  ),
  _S(
    type: 'rect',
    x: 0.12,
    y: 0.62,
    w: 0.12,
    h: 0.1,
    r: 0.02,
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'rect',
    x: 0.3,
    y: 0.62,
    w: 0.12,
    h: 0.1,
    r: 0.02,
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
];

const _kMicrophone = [
  _S(
    type: 'rect',
    x: 0.35,
    y: 0.05,
    w: 0.3,
    h: 0.5,
    r: 0.12,
    c1: Color(0xFF7E57C2),
    c2: Color(0xFF4527A0),
  ),
  _S(
    type: 'path',
    d: 'M0.18 0.42 Q0.18 0.72 0.5 0.72 Q0.82 0.72 0.82 0.42',
    c1: Color(0xFF9575CD),
    c2: Color(0xFF512DA8),
  ),
  _S(
    type: 'rect',
    x: 0.46,
    y: 0.72,
    w: 0.08,
    h: 0.2,
    r: 0.02,
    c1: Color(0xFF7E57C2),
    c2: Color(0xFF4527A0),
  ),
  _S(
    type: 'rect',
    x: 0.3,
    y: 0.88,
    w: 0.4,
    h: 0.06,
    r: 0.03,
    c1: Color(0xFF9575CD),
    c2: Color(0xFF7E57C2),
  ),
];

const _kHeadphones = [
  _S(
    type: 'path',
    d: 'M0.15 0.55 Q0.15 0.18 0.5 0.1 Q0.85 0.18 0.85 0.55',
    c1: Color(0xFF0277BD),
    c2: Color(0xFF01579B),
  ),
  _S(
    type: 'rect',
    x: 0.08,
    y: 0.52,
    w: 0.2,
    h: 0.3,
    r: 0.07,
    c1: Color(0xFF29B6F6),
    c2: Color(0xFF0277BD),
  ),
  _S(
    type: 'rect',
    x: 0.72,
    y: 0.52,
    w: 0.2,
    h: 0.3,
    r: 0.07,
    c1: Color(0xFF29B6F6),
    c2: Color(0xFF0277BD),
  ),
];

const _kBooks = [
  _S(
    type: 'rect',
    x: 0.05,
    y: 0.15,
    w: 0.22,
    h: 0.7,
    r: 0.04,
    c1: Color(0xFFE53935),
    c2: Color(0xFFB71C1C),
  ),
  _S(
    type: 'rect',
    x: 0.32,
    y: 0.1,
    w: 0.22,
    h: 0.75,
    r: 0.04,
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'rect',
    x: 0.59,
    y: 0.18,
    w: 0.22,
    h: 0.67,
    r: 0.04,
    c1: Color(0xFF2E7D32),
    c2: Color(0xFF1B5E20),
  ),
  _S(
    type: 'rect',
    x: 0.05,
    y: 0.82,
    w: 0.76,
    h: 0.06,
    r: 0.02,
    c1: Color(0xFF5D4037),
    c2: Color(0xFF3E2723),
  ),
];

const _kGreenBook = [
  // Spine — deep honey-brown left strip for 3-D depth
  _S(
    type: 'rect',
    x: 0.05,
    y: 0.06,
    w: 0.12,
    h: 0.88,
    r: 0.04,
    c1: Color(0xFF7A5200),
    c2: Color(0xFF4E3200),
  ),
  // Main cover — warm amber/honey gradient
  _S(
    type: 'rect',
    x: 0.15,
    y: 0.04,
    w: 0.72,
    h: 0.92,
    r: 0.05,
    c1: Color(0xFFD89A1E),
    c2: Color(0xFFB87A0C),
  ),
  // Page edges — cream/parchment right side
  _S(
    type: 'rect',
    x: 0.85,
    y: 0.08,
    w: 0.10,
    h: 0.84,
    r: 0.02,
    c1: Color(0xFFFFF8E8),
    c2: Color(0xFFEEE0C0),
  ),
  // Outer ornamental border — bright gold
  _S(
    type: 'stroke_path',
    d: 'M0.22 0.12 L0.82 0.12 L0.82 0.88 L0.22 0.88 L0.22 0.12Z',
    sw: 0.024,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFFFD700),
  ),
  // Inner border — softer gold
  _S(
    type: 'stroke_path',
    d: 'M0.27 0.18 L0.77 0.18 L0.77 0.82 L0.27 0.82 L0.27 0.18Z',
    sw: 0.013,
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFFFEC6E),
  ),
  // Centre medallion — radial honey glow
  _S(
    type: 'circle',
    x: 0.36,
    y: 0.28,
    w: 0.28,
    h: 0.28,
    r: 0.13,
    c1: Color(0xFFFFF4C2),
    c2: Color(0xFFDAA520),
    radial: true,
  ),
  // Arabic calligraphy lines — dark ink on gold
  _S(
    type: 'rect',
    x: 0.41,
    y: 0.41,
    w: 0.18,
    h: 0.022,
    r: 0.01,
    c1: Color(0xFF5A3C00),
    c2: Color(0xFF3A2200),
  ),
  _S(
    type: 'rect',
    x: 0.39,
    y: 0.46,
    w: 0.22,
    h: 0.022,
    r: 0.01,
    c1: Color(0xFF5A3C00),
    c2: Color(0xFF3A2200),
  ),
  _S(
    type: 'rect',
    x: 0.43,
    y: 0.51,
    w: 0.14,
    h: 0.022,
    r: 0.01,
    c1: Color(0xFF5A3C00),
    c2: Color(0xFF3A2200),
  ),
];

const _kCheck = [
  _S(
    type: 'circle',
    x: 0.05,
    y: 0.05,
    w: 0.9,
    h: 0.9,
    r: 0.45,
    c1: Color(0xFF66BB6A),
    c2: Color(0xFF2E7D32),
  ),
  _S(
    type: 'path',
    d: 'M0.25 0.5 L0.42 0.68 L0.75 0.32',
    c1: Color(0xFFFFFFFF),
    c2: Color(0xFFE8F5E9),
  ),
];

const _kHandshake = [
  // ── Left person — warm amber ──────────────────────────────────
  _S(
    type: 'circle',
    x: 0.08,
    y: 0.04,
    w: 0.30,
    h: 0.30,
    r: 0.15,
    c1: Color(0xFFFFD27F),
    c2: Color(0xFFD89A1E),
  ),
  _S(
    type: 'rect',
    x: 0.02,
    y: 0.38,
    w: 0.46,
    h: 0.42,
    r: 0.14,
    c1: Color(0xFFD89A1E),
    c2: Color(0xFF9E6B00),
  ),
  _S(
    type: 'rect',
    x: 0.16,
    y: 0.32,
    w: 0.16,
    h: 0.12,
    r: 0.04,
    c1: Color(0xFFFFD27F),
    c2: Color(0xFFD89A1E),
  ),

  // ── Right person — honey-deep brown ───────────────────────────
  _S(
    type: 'circle',
    x: 0.62,
    y: 0.04,
    w: 0.30,
    h: 0.30,
    r: 0.15,
    c1: Color(0xFFFFC83D),
    c2: Color(0xFFB87A0C),
  ),
  _S(
    type: 'rect',
    x: 0.56,
    y: 0.38,
    w: 0.46,
    h: 0.42,
    r: 0.14,
    c1: Color(0xFFFFC83D),
    c2: Color(0xFF9E6B00),
  ),
  _S(
    type: 'rect',
    x: 0.70,
    y: 0.32,
    w: 0.16,
    h: 0.12,
    r: 0.04,
    c1: Color(0xFFFFC83D),
    c2: Color(0xFFB87A0C),
  ),
];

const _kShare = [
  _S(
    type: 'circle',
    x: 0.65,
    y: 0.05,
    w: 0.2,
    h: 0.2,
    r: 0.1,
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'circle',
    x: 0.15,
    y: 0.39,
    w: 0.2,
    h: 0.2,
    r: 0.1,
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'circle',
    x: 0.65,
    y: 0.73,
    w: 0.2,
    h: 0.2,
    r: 0.1,
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'path',
    d: 'M0.72 0.15 L0.28 0.42',
    c1: Color(0xFF42A5F5),
    c2: Color(0xFF1565C0),
  ),
  _S(
    type: 'path',
    d: 'M0.28 0.52 L0.72 0.76',
    c1: Color(0xFF42A5F5),
    c2: Color(0xFF1565C0),
  ),
];

const _kChat = [
  _S(
    type: 'path',
    d: 'M0.05 0.1 Q0.05 0.05 0.1 0.05 L0.9 0.05 Q0.95 0.05 0.95 0.1 L0.95 0.68 Q0.95 0.73 0.9 0.73 L0.35 0.73 L0.12 0.95 L0.12 0.73 L0.1 0.73 Q0.05 0.73 0.05 0.68Z',
    c1: Color(0xFF25D366),
    c2: Color(0xFF128C7E),
  ),
  _S(
    type: 'rect',
    x: 0.2,
    y: 0.28,
    w: 0.4,
    h: 0.06,
    r: 0.03,
    c1: Color(0xFFFFFFFF),
    c2: Color(0xFFE0E0E0),
  ),
  _S(
    type: 'rect',
    x: 0.2,
    y: 0.42,
    w: 0.55,
    h: 0.06,
    r: 0.03,
    c1: Color(0xFFFFFFFF),
    c2: Color(0xFFE0E0E0),
  ),
];

const _kPeople = [
  _S(
    type: 'circle',
    x: 0.28,
    y: 0.1,
    w: 0.22,
    h: 0.22,
    r: 0.1,
    c1: Color(0xFFFFCC80),
    c2: Color(0xFFE65100),
  ),
  _S(
    type: 'path',
    d: 'M0.18 0.38 Q0.18 0.28 0.39 0.28 Q0.6 0.28 0.6 0.38 L0.6 0.68 L0.18 0.68Z',
    c1: Color(0xFF5C6BC0),
    c2: Color(0xFF283593),
  ),
  _S(
    type: 'circle',
    x: 0.5,
    y: 0.08,
    w: 0.22,
    h: 0.22,
    r: 0.1,
    c1: Color(0xFFFFCC80),
    c2: Color(0xFFE65100),
  ),
  _S(
    type: 'path',
    d: 'M0.4 0.36 Q0.4 0.26 0.61 0.26 Q0.82 0.26 0.82 0.36 L0.82 0.65 L0.4 0.65Z',
    c1: Color(0xFF7986CB),
    c2: Color(0xFF3949AB),
  ),
  _S(
    type: 'rect',
    x: 0.1,
    y: 0.68,
    w: 0.55,
    h: 0.26,
    r: 0.04,
    c1: Color(0xFF5C6BC0),
    c2: Color(0xFF283593),
  ),
  _S(
    type: 'rect',
    x: 0.35,
    y: 0.65,
    w: 0.55,
    h: 0.28,
    r: 0.04,
    c1: Color(0xFF7986CB),
    c2: Color(0xFF3949AB),
  ),
];

const _kCompass = [
  _S(
    type: 'circle',
    x: 0.05,
    y: 0.05,
    w: 0.9,
    h: 0.9,
    r: 0.45,
    c1: Color(0xFF455A64),
    c2: Color(0xFF263238),
  ),
  _S(
    type: 'circle',
    x: 0.1,
    y: 0.1,
    w: 0.8,
    h: 0.8,
    r: 0.38,
    c1: Color(0xFF546E7A),
    c2: Color(0xFF37474F),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.12 L0.56 0.45 L0.5 0.5 L0.44 0.45Z',
    c1: Color(0xFFE53935),
    c2: Color(0xFFB71C1C),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.88 L0.56 0.55 L0.5 0.5 L0.44 0.55Z',
    c1: Color(0xFFEEEEEE),
    c2: Color(0xFFBDBDBD),
  ),
  _S(
    type: 'circle',
    x: 0.44,
    y: 0.44,
    w: 0.12,
    h: 0.12,
    r: 0.055,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFDAA520),
  ),
];

const _kAirplane = [
  _S(
    type: 'path',
    d: 'M0.5 0.08 Q0.72 0.08 0.88 0.3 Q0.96 0.45 0.88 0.58 L0.65 0.52 L0.62 0.72 L0.5 0.68 L0.5 0.52 L0.25 0.58 L0.22 0.48 L0.5 0.38 L0.5 0.22 Q0.38 0.2 0.18 0.28 L0.15 0.2 Q0.28 0.08 0.5 0.08Z',
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.08 Q0.62 0.12 0.72 0.25 Q0.58 0.2 0.5 0.22Z',
    c1: Color(0xFF64B5F6),
    c2: Color(0xFF1565C0),
  ),
];

const _kFlag = [
  _S(
    type: 'rect',
    x: 0.2,
    y: 0.08,
    w: 0.05,
    h: 0.84,
    r: 0.02,
    c1: Color(0xFF5D4037),
    c2: Color(0xFF3E2723),
  ),
  _S(
    type: 'path',
    d: 'M0.25 0.1 L0.82 0.18 L0.82 0.52 L0.25 0.52Z',
    c1: Color(0xFFE53935),
    c2: Color(0xFFB71C1C),
  ),
  _S(
    type: 'path',
    d: 'M0.25 0.1 L0.82 0.18 L0.54 0.18 L0.54 0.35 L0.25 0.35Z',
    c1: Color(0xFFFFFFFF),
    c2: Color(0xFFEEEEEE),
  ),
];

const _kMegaphone = [
  _S(
    type: 'path',
    d: 'M0.15 0.35 L0.15 0.65 L0.42 0.65 L0.82 0.88 L0.82 0.12 L0.42 0.35Z',
    c1: Color(0xFFF57C00),
    c2: Color(0xFFE65100),
  ),
  _S(
    type: 'rect',
    x: 0.05,
    y: 0.37,
    w: 0.12,
    h: 0.26,
    r: 0.04,
    c1: Color(0xFFFF9800),
    c2: Color(0xFFF57C00),
  ),
  _S(
    type: 'rect',
    x: 0.15,
    y: 0.65,
    w: 0.15,
    h: 0.2,
    r: 0.03,
    c1: Color(0xFFFFB74D),
    c2: Color(0xFFF57C00),
  ),
  _S(
    type: 'circle',
    x: 0.76,
    y: 0.36,
    w: 0.16,
    h: 0.16,
    r: 0.07,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFDAA520),
  ),
];

const _kPalette = [
  _S(
    type: 'path',
    d: 'M0.5 0.08 Q0.85 0.08 0.92 0.45 Q0.92 0.78 0.65 0.88 Q0.5 0.92 0.38 0.82 Q0.28 0.72 0.38 0.62 Q0.5 0.52 0.38 0.48 Q0.08 0.42 0.08 0.3 Q0.08 0.08 0.5 0.08Z',
    c1: Color(0xFFFFF8E1),
    c2: Color(0xFFFFF3CD),
  ),
  _S(
    type: 'circle',
    x: 0.28,
    y: 0.18,
    w: 0.12,
    h: 0.12,
    r: 0.055,
    c1: Color(0xFFE53935),
    c2: Color(0xFFB71C1C),
  ),
  _S(
    type: 'circle',
    x: 0.5,
    y: 0.12,
    w: 0.12,
    h: 0.12,
    r: 0.055,
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'circle',
    x: 0.7,
    y: 0.2,
    w: 0.12,
    h: 0.12,
    r: 0.055,
    c1: Color(0xFF2E7D32),
    c2: Color(0xFF1B5E20),
  ),
  _S(
    type: 'circle',
    x: 0.78,
    y: 0.42,
    w: 0.12,
    h: 0.12,
    r: 0.055,
    c1: Color(0xFFE91E63),
    c2: Color(0xFFAD1457),
  ),
  _S(
    type: 'circle',
    x: 0.35,
    y: 0.6,
    w: 0.15,
    h: 0.15,
    r: 0.065,
    c1: Color(0xFF424242),
    c2: Color(0xFF212121),
  ),
];

const _kGear = [
  _S(
    type: 'path',
    d: 'M0.42 0.05 L0.42 0.18 Q0.32 0.22 0.25 0.3 L0.12 0.24 L0.04 0.38 L0.15 0.46 Q0.13 0.5 0.13 0.54 L0.04 0.62 L0.12 0.76 L0.25 0.7 Q0.32 0.78 0.42 0.82 L0.42 0.95 L0.58 0.95 L0.58 0.82 Q0.68 0.78 0.75 0.7 L0.88 0.76 L0.96 0.62 L0.85 0.54 Q0.87 0.5 0.87 0.46 L0.96 0.38 L0.88 0.24 L0.75 0.3 Q0.68 0.22 0.58 0.18 L0.58 0.05Z',
    c1: Color(0xFF455A64),
    c2: Color(0xFF263238),
  ),
  _S(
    type: 'circle',
    x: 0.32,
    y: 0.32,
    w: 0.36,
    h: 0.36,
    r: 0.18,
    c1: Color(0xFF78909C),
    c2: Color(0xFF455A64),
    radial: true,
  ),
  _S(
    type: 'circle',
    x: 0.4,
    y: 0.4,
    w: 0.2,
    h: 0.2,
    r: 0.09,
    c1: Color(0xFF263238),
    c2: Color(0xFF1C2E36),
  ),
];

const _kBookmark = [
  _S(
    type: 'path',
    d: 'M0.2 0.05 L0.8 0.05 L0.8 0.95 L0.5 0.75 L0.2 0.95Z',
    c1: Color(0xFFE91E63),
    c2: Color(0xFFAD1457),
  ),
  _S(
    type: 'path',
    d: 'M0.2 0.05 L0.65 0.05 L0.65 0.8 L0.5 0.7 L0.2 0.88Z',
    c1: Color(0xFFFF4081),
    c2: Color(0xFFE91E63),
  ),
];

const _kScales = [
  _S(
    type: 'rect',
    x: 0.47,
    y: 0.1,
    w: 0.06,
    h: 0.78,
    r: 0.02,
    c1: Color(0xFFDAA520),
    c2: Color(0xFF8B6914),
  ),
  _S(
    type: 'rect',
    x: 0.05,
    y: 0.88,
    w: 0.9,
    h: 0.06,
    r: 0.03,
    c1: Color(0xFF6D4C41),
    c2: Color(0xFF4E342E),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.12 L0.12 0.3 M0.5 0.12 L0.88 0.3',
    c1: Color(0xFFDAA520),
    c2: Color(0xFF8B6914),
  ),
  _S(
    type: 'path',
    d: 'M0.05 0.3 Q0.05 0.5 0.2 0.5 Q0.35 0.5 0.35 0.3Z',
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFDAA520),
  ),
  _S(
    type: 'path',
    d: 'M0.65 0.3 Q0.65 0.5 0.8 0.5 Q0.95 0.5 0.95 0.3Z',
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFDAA520),
  ),
];

const _kChains = [
  _S(
    type: 'path',
    d: 'M0.25 0.35 Q0.15 0.28 0.18 0.18 Q0.22 0.08 0.35 0.1 Q0.45 0.12 0.5 0.2 Q0.55 0.28 0.5 0.38 Q0.42 0.48 0.3 0.45Z',
    c1: Color(0xFF78909C),
    c2: Color(0xFF455A64),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.38 Q0.55 0.5 0.5 0.6 Q0.42 0.72 0.3 0.68 Q0.18 0.62 0.18 0.52 Q0.18 0.4 0.28 0.38Z',
    c1: Color(0xFF90A4AE),
    c2: Color(0xFF607D8B),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.62 Q0.58 0.72 0.55 0.82 Q0.5 0.92 0.38 0.9 Q0.28 0.88 0.28 0.78 Q0.28 0.68 0.38 0.62Z',
    c1: Color(0xFF78909C),
    c2: Color(0xFF455A64),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.38 L0.72 0.35 Q0.82 0.28 0.82 0.18 Q0.8 0.08 0.68 0.1 Q0.58 0.12 0.55 0.22',
    c1: Color(0xFF90A4AE),
    c2: Color(0xFF607D8B),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.62 L0.72 0.58 Q0.82 0.52 0.82 0.42 Q0.78 0.32 0.68 0.34',
    c1: Color(0xFF78909C),
    c2: Color(0xFF455A64),
  ),
];

const _kBag = [
  _S(
    type: 'path',
    d: 'M0.35 0.3 Q0.35 0.12 0.5 0.08 Q0.65 0.12 0.65 0.3',
    c1: Color(0xFFFF4081),
    c2: Color(0xFFE91E63),
  ),
  _S(
    type: 'rect',
    x: 0.12,
    y: 0.28,
    w: 0.76,
    h: 0.65,
    r: 0.06,
    c1: Color(0xFFFF80AB),
    c2: Color(0xFFE91E63),
  ),
  _S(
    type: 'rect',
    x: 0.12,
    y: 0.28,
    w: 0.76,
    h: 0.16,
    r: 0.06,
    c1: Color(0xFFFF4081),
    c2: Color(0xFFE91E63),
  ),
  _S(
    type: 'path',
    d: 'M0.35 0.28 Q0.35 0.42 0.5 0.45 Q0.65 0.42 0.65 0.28',
    c1: Color(0xFFFFFFFF),
    c2: Color(0xFFFFCDD2),
  ),
];

const _kHome = [
  _S(
    type: 'path',
    d: 'M0.5 0.08 L0.92 0.45 L0.78 0.45 L0.78 0.9 L0.22 0.9 L0.22 0.45 L0.08 0.45Z',
    c1: Color(0xFF66BB6A),
    c2: Color(0xFF2E7D32),
  ),
  _S(
    type: 'rect',
    x: 0.38,
    y: 0.6,
    w: 0.24,
    h: 0.3,
    r: 0.04,
    c1: Color(0xFF4E342E),
    c2: Color(0xFF3E2723),
  ),
  _S(
    type: 'rect',
    x: 0.25,
    y: 0.52,
    w: 0.2,
    h: 0.2,
    r: 0.03,
    c1: Color(0xFF29B6F6),
    c2: Color(0xFF0277BD),
  ),
];

const _kThunder = [
  _S(
    type: 'path',
    d: 'M0.35 0.05 L0.28 0.45 L0.18 0.45 Q0.1 0.55 0.2 0.6 L0.55 0.6 L0.45 0.95 L0.78 0.52 L0.65 0.52 Q0.72 0.42 0.62 0.38 L0.65 0.38 L0.7 0.05Z',
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFFFAA00),
  ),
];

const _kImage = [
  _S(
    type: 'rect',
    x: 0.05,
    y: 0.1,
    w: 0.9,
    h: 0.8,
    r: 0.06,
    c1: Color(0xFFEEEEEE),
    c2: Color(0xFFBDBDBD),
  ),
  _S(
    type: 'circle',
    x: 0.18,
    y: 0.2,
    w: 0.2,
    h: 0.2,
    r: 0.09,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFDAA520),
  ),
  _S(
    type: 'path',
    d: 'M0.05 0.75 L0.35 0.45 L0.55 0.62 L0.72 0.42 L0.95 0.72 L0.95 0.88 L0.05 0.88Z',
    c1: Color(0xFF66BB6A),
    c2: Color(0xFF2E7D32),
  ),
];

const _kPlay = [
  _S(
    type: 'circle',
    x: 0.05,
    y: 0.05,
    w: 0.9,
    h: 0.9,
    r: 0.45,
    c1: Color(0xFF7E57C2),
    c2: Color(0xFF4527A0),
  ),
  _S(
    type: 'path',
    d: 'M0.38 0.28 L0.38 0.72 L0.75 0.5Z',
    c1: Color(0xFFFFFFFF),
    c2: Color(0xFFE0E0E0),
  ),
];

const _kMuscle = [
  _S(
    type: 'path',
    d: 'M0.18 0.5 Q0.12 0.38 0.18 0.28 Q0.28 0.15 0.42 0.2 Q0.5 0.08 0.6 0.12 Q0.72 0.08 0.78 0.18 Q0.88 0.15 0.88 0.28 Q0.9 0.42 0.8 0.5 Q0.88 0.62 0.8 0.72 Q0.72 0.82 0.62 0.78 Q0.5 0.88 0.38 0.82 Q0.28 0.88 0.2 0.78 Q0.12 0.68 0.18 0.5Z',
    c1: Color(0xFFFFCC80),
    c2: Color(0xFFE65100),
  ),
];

const _kPointing = [
  _S(
    type: 'path',
    d: 'M0.5 0.05 Q0.58 0.05 0.6 0.12 L0.6 0.42 Q0.68 0.38 0.72 0.4 Q0.78 0.42 0.78 0.5 Q0.82 0.48 0.85 0.52 Q0.88 0.58 0.85 0.62 Q0.9 0.65 0.88 0.72 Q0.85 0.82 0.7 0.88 L0.5 0.92 Q0.35 0.92 0.28 0.8 L0.25 0.6 Q0.22 0.5 0.28 0.45 Q0.3 0.38 0.42 0.38 L0.42 0.12 Q0.42 0.05 0.5 0.05Z',
    c1: Color(0xFFFFCC80),
    c2: Color(0xFFE65100),
  ),
];

const _kRose = [
  _S(
    type: 'rect',
    x: 0.46,
    y: 0.6,
    w: 0.08,
    h: 0.35,
    r: 0.03,
    c1: Color(0xFF388E3C),
    c2: Color(0xFF1B5E20),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.62 Q0.35 0.45 0.38 0.28 Q0.42 0.12 0.5 0.08 Q0.58 0.12 0.62 0.28 Q0.65 0.45 0.5 0.62Z',
    c1: Color(0xFFE91E63),
    c2: Color(0xFFAD1457),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.62 Q0.3 0.58 0.22 0.45 Q0.28 0.38 0.38 0.4 Q0.44 0.5 0.5 0.55Z',
    c1: Color(0xFFFF4081),
    c2: Color(0xFFE91E63),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.62 Q0.7 0.58 0.78 0.45 Q0.72 0.38 0.62 0.4 Q0.56 0.5 0.5 0.55Z',
    c1: Color(0xFFFF4081),
    c2: Color(0xFFE91E63),
  ),
];

const _kWave = [
  _S(
    type: 'rect',
    x: 0.0,
    y: 0.0,
    w: 1.0,
    h: 1.0,
    r: 0.0,
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'path',
    d: 'M0.0 0.55 Q0.12 0.35 0.25 0.55 Q0.37 0.75 0.5 0.55 Q0.62 0.35 0.75 0.55 Q0.87 0.75 1.0 0.55 L1.0 1.0 L0.0 1.0Z',
    c1: Color(0xFF29B6F6),
    c2: Color(0xFF0277BD),
  ),
  _S(
    type: 'path',
    d: 'M0.0 0.65 Q0.12 0.48 0.25 0.65 Q0.37 0.82 0.5 0.65 Q0.62 0.48 0.75 0.65 Q0.87 0.82 1.0 0.65 L1.0 1.0 L0.0 1.0Z',
    c1: Color(0xFF64B5F6),
    c2: Color(0xFF1565C0),
  ),
];

const _kCrystal = [
  _S(
    type: 'path',
    d: 'M0.5 0.05 L0.8 0.35 L0.65 0.95 L0.35 0.95 L0.2 0.35Z',
    c1: Color(0xFF9C27B0),
    c2: Color(0xFF4A148C),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.05 L0.65 0.35 L0.5 0.95 L0.35 0.35Z',
    c1: Color(0xFFCE93D8),
    c2: Color(0xFF9C27B0),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.05 L0.8 0.35 L0.65 0.35Z',
    c1: Color(0xFFEA80FC),
    c2: Color(0xFFCE93D8),
  ),
];

const _kBlossom = [
  _S(
    type: 'circle',
    x: 0.36,
    y: 0.08,
    w: 0.28,
    h: 0.28,
    r: 0.13,
    c1: Color(0xFFFF80AB),
    c2: Color(0xFFE91E63),
  ),
  _S(
    type: 'circle',
    x: 0.62,
    y: 0.2,
    w: 0.28,
    h: 0.28,
    r: 0.13,
    c1: Color(0xFFFF80AB),
    c2: Color(0xFFE91E63),
  ),
  _S(
    type: 'circle',
    x: 0.68,
    y: 0.5,
    w: 0.28,
    h: 0.28,
    r: 0.13,
    c1: Color(0xFFFF80AB),
    c2: Color(0xFFE91E63),
  ),
  _S(
    type: 'circle',
    x: 0.5,
    y: 0.68,
    w: 0.28,
    h: 0.28,
    r: 0.13,
    c1: Color(0xFFFF80AB),
    c2: Color(0xFFE91E63),
  ),
  _S(
    type: 'circle',
    x: 0.22,
    y: 0.55,
    w: 0.28,
    h: 0.28,
    r: 0.13,
    c1: Color(0xFFFF80AB),
    c2: Color(0xFFE91E63),
  ),
  _S(
    type: 'circle',
    x: 0.38,
    y: 0.38,
    w: 0.24,
    h: 0.24,
    r: 0.11,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFDAA520),
  ),
];

const _kNight = [
  _S(
    type: 'rect',
    x: 0.0,
    y: 0.0,
    w: 1.0,
    h: 1.0,
    r: 0.0,
    c1: Color(0xFF1A237E),
    c2: Color(0xFF0D1450),
  ),
  _S(
    type: 'path',
    d: 'M0.62 0.08 Q0.35 0.15 0.2 0.42 Q0.08 0.65 0.2 0.82 Q0.35 0.98 0.6 0.92 Q0.82 0.85 0.9 0.65 Q0.75 0.72 0.6 0.65 Q0.38 0.5 0.42 0.25 Q0.45 0.1 0.62 0.08Z',
    c1: Color(0xFFFFEC6E),
    c2: Color(0xFFFFAA00),
    radial: true,
  ),
];

const _kFood = [
  _S(
    type: 'circle',
    x: 0.05,
    y: 0.08,
    w: 0.9,
    h: 0.9,
    r: 0.44,
    c1: Color(0xFFF5F5F5),
    c2: Color(0xFFE0E0E0),
  ),
  _S(
    type: 'path',
    d: 'M0.25 0.35 Q0.3 0.55 0.5 0.58 Q0.7 0.55 0.75 0.35Z',
    c1: Color(0xFFFFCC80),
    c2: Color(0xFFE65100),
  ),
  _S(
    type: 'rect',
    x: 0.12,
    y: 0.3,
    w: 0.76,
    h: 0.06,
    r: 0.02,
    c1: Color(0xFF5D4037),
    c2: Color(0xFF3E2723),
  ),
  _S(
    type: 'rect',
    x: 0.46,
    y: 0.1,
    w: 0.06,
    h: 0.22,
    r: 0.02,
    c1: Color(0xFF5D4037),
    c2: Color(0xFF3E2723),
  ),
  _S(
    type: 'rect',
    x: 0.64,
    y: 0.1,
    w: 0.06,
    h: 0.22,
    r: 0.02,
    c1: Color(0xFF5D4037),
    c2: Color(0xFF3E2723),
  ),
];

const _kShirt = [
  _S(
    type: 'path',
    d: 'M0.05 0.35 L0.28 0.12 Q0.38 0.22 0.5 0.22 Q0.62 0.22 0.72 0.12 L0.95 0.35 L0.78 0.48 L0.78 0.9 L0.22 0.9 L0.22 0.48Z',
    c1: Color(0xFF42A5F5),
    c2: Color(0xFF1565C0),
  ),
  _S(
    type: 'path',
    d: 'M0.05 0.35 L0.28 0.12 L0.22 0.48 Z',
    c1: Color(0xFF64B5F6),
    c2: Color(0xFF42A5F5),
  ),
  _S(
    type: 'path',
    d: 'M0.95 0.35 L0.72 0.12 L0.78 0.48 Z',
    c1: Color(0xFF64B5F6),
    c2: Color(0xFF42A5F5),
  ),
];

// ── New Icons ─────────────────────────────────────────────────────────────────

// 👨‍👩‍👧 Family — three outline figures
const _kFamily = [
  _S(
    type: 'stroke_circle',
    x: 0.14,
    y: 0.0,
    w: 0.2,
    h: 0.2,
    r: 0.10,
    sw: 0.07,
    c1: Color(0xFF5C6BC0),
    c2: Color(0xFF5C6BC0),
  ),
  _S(
    type: 'stroke_circle',
    x: 0.63,
    y: 0.0,
    w: 0.2,
    h: 0.2,
    r: 0.10,
    sw: 0.07,
    c1: Color(0xFF26A69A),
    c2: Color(0xFF26A69A),
  ),
  _S(
    type: 'stroke_circle',
    x: 0.38,
    y: 0.06,
    w: 0.16,
    h: 0.16,
    r: 0.08,
    sw: 0.06,
    c1: Color(0xFFEC407A),
    c2: Color(0xFFEC407A),
  ),
  _S(
    type: 'stroke_path',
    d: 'M0.04 0.92 Q0.04 0.62 0.24 0.62 Q0.44 0.62 0.44 0.92',
    sw: 0.07,
    c1: Color(0xFF5C6BC0),
    c2: Color(0xFF5C6BC0),
  ),
  _S(
    type: 'stroke_path',
    d: 'M0.56 0.92 Q0.56 0.62 0.76 0.62 Q0.96 0.62 0.96 0.92',
    sw: 0.07,
    c1: Color(0xFF26A69A),
    c2: Color(0xFF26A69A),
  ),
  _S(
    type: 'stroke_path',
    d: 'M0.3 0.92 Q0.3 0.68 0.46 0.68 Q0.62 0.68 0.62 0.92',
    sw: 0.06,
    c1: Color(0xFFEC407A),
    c2: Color(0xFFEC407A),
  ),
];

// 🍂 Autumn leaf
const _kAutumn = [
  _S(
    type: 'path',
    d: 'M0.5 0.9 Q0.18 0.72 0.12 0.45 Q0.08 0.2 0.3 0.1 Q0.5 0.02 0.68 0.18 Q0.9 0.08 0.92 0.3 Q0.95 0.55 0.7 0.72Z',
    c1: Color(0xFFE64A19),
    c2: Color(0xFFBF360C),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.9 L0.44 0.5 L0.3 0.1',
    c1: Color(0xFFFF7043),
    c2: Color(0xFFE64A19),
  ),
  _S(
    type: 'rect',
    x: 0.46,
    y: 0.82,
    w: 0.08,
    h: 0.14,
    r: 0.03,
    c1: Color(0xFF5D4037),
    c2: Color(0xFF3E2723),
  ),
];

// 🎓 Graduation cap
const _kGraduation = [
  _S(
    type: 'path',
    d: 'M0.1 0.42 L0.5 0.22 L0.9 0.42 L0.5 0.62Z',
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'path',
    d: 'M0.1 0.42 L0.5 0.62 L0.5 0.78 Q0.35 0.82 0.22 0.9 L0.22 0.6Z',
    c1: Color(0xFF1976D2),
    c2: Color(0xFF1565C0),
  ),
  _S(
    type: 'rect',
    x: 0.82,
    y: 0.4,
    w: 0.06,
    h: 0.36,
    r: 0.02,
    c1: Color(0xFF1565C0),
    c2: Color(0xFF0D47A1),
  ),
  _S(
    type: 'circle',
    x: 0.8,
    y: 0.74,
    w: 0.12,
    h: 0.12,
    r: 0.06,
    c1: Color(0xFFFFD700),
    c2: Color(0xFFDAA520),
  ),
];

// 📜 Scroll / Parchment
const _kScroll = [
  _S(
    type: 'rect',
    x: 0.12,
    y: 0.12,
    w: 0.76,
    h: 0.76,
    r: 0.06,
    c1: Color(0xFFFFF8E1),
    c2: Color(0xFFFFECB3),
  ),
  _S(
    type: 'circle',
    x: 0.04,
    y: 0.12,
    w: 0.18,
    h: 0.76,
    r: 0.09,
    c1: Color(0xFFFFCC80),
    c2: Color(0xFFE65100),
  ),
  _S(
    type: 'circle',
    x: 0.76,
    y: 0.12,
    w: 0.18,
    h: 0.76,
    r: 0.09,
    c1: Color(0xFFFFCC80),
    c2: Color(0xFFE65100),
  ),
  _S(
    type: 'rect',
    x: 0.24,
    y: 0.28,
    w: 0.52,
    h: 0.06,
    r: 0.02,
    c1: Color(0xFF8D6E63),
    c2: Color(0xFF5D4037),
  ),
  _S(
    type: 'rect',
    x: 0.24,
    y: 0.42,
    w: 0.52,
    h: 0.06,
    r: 0.02,
    c1: Color(0xFF8D6E63),
    c2: Color(0xFF5D4037),
  ),
  _S(
    type: 'rect',
    x: 0.24,
    y: 0.56,
    w: 0.36,
    h: 0.06,
    r: 0.02,
    c1: Color(0xFF8D6E63),
    c2: Color(0xFF5D4037),
  ),
];

// 🏛️ Arch / Pillars
const _kArch = [
  _S(
    type: 'rect',
    x: 0.0,
    y: 0.88,
    w: 1.0,
    h: 0.1,
    r: 0.0,
    c1: Color(0xFF78909C),
    c2: Color(0xFF546E7A),
  ),
  _S(
    type: 'rect',
    x: 0.06,
    y: 0.36,
    w: 0.14,
    h: 0.54,
    r: 0.02,
    c1: Color(0xFF90A4AE),
    c2: Color(0xFF607D8B),
  ),
  _S(
    type: 'rect',
    x: 0.8,
    y: 0.36,
    w: 0.14,
    h: 0.54,
    r: 0.02,
    c1: Color(0xFF90A4AE),
    c2: Color(0xFF607D8B),
  ),
  _S(
    type: 'rect',
    x: 0.4,
    y: 0.36,
    w: 0.2,
    h: 0.54,
    r: 0.02,
    c1: Color(0xFF90A4AE),
    c2: Color(0xFF607D8B),
  ),
  _S(
    type: 'path',
    d: 'M0.06 0.38 Q0.06 0.06 0.5 0.06 Q0.94 0.06 0.94 0.38',
    c1: Color(0xFFB0BEC5),
    c2: Color(0xFF78909C),
  ),
  _S(
    type: 'rect',
    x: 0.0,
    y: 0.28,
    w: 1.0,
    h: 0.1,
    r: 0.0,
    c1: Color(0xFF78909C),
    c2: Color(0xFF546E7A),
  ),
];

// ⏱️ Stopwatch / Timer
const _kTimer = [
  _S(
    type: 'stroke_circle',
    x: 0.12,
    y: 0.22,
    w: 0.76,
    h: 0.76,
    r: 0.38,
    sw: 0.08,
    c1: Color(0xFF00ACC1),
    c2: Color(0xFF00ACC1),
  ),
  _S(
    type: 'stroke_path',
    d: 'M0.5 0.6 L0.5 0.38 L0.65 0.32',
    sw: 0.07,
    c1: Color(0xFF00ACC1),
    c2: Color(0xFF00ACC1),
  ),
  _S(
    type: 'rect',
    x: 0.4,
    y: 0.06,
    w: 0.2,
    h: 0.1,
    r: 0.04,
    c1: Color(0xFF00ACC1),
    c2: Color(0xFF00838F),
  ),
  _S(
    type: 'rect',
    x: 0.62,
    y: 0.02,
    w: 0.1,
    h: 0.1,
    r: 0.04,
    c1: Color(0xFF00ACC1),
    c2: Color(0xFF00838F),
  ),
];

// 📍 Location pin
const _kPin = [
  _S(
    type: 'path',
    d: 'M0.5 0.04 Q0.22 0.04 0.18 0.34 Q0.18 0.56 0.5 0.88 Q0.82 0.56 0.82 0.34 Q0.78 0.04 0.5 0.04Z',
    c1: Color(0xFFE53935),
    c2: Color(0xFFB71C1C),
  ),
  _S(
    type: 'circle',
    x: 0.36,
    y: 0.24,
    w: 0.28,
    h: 0.28,
    r: 0.14,
    c1: Color(0xFFFFFFFF),
    c2: Color(0xFFFFCDD2),
  ),
];

// 📱 Mobile phone
const _kPhone = [
  _S(
    type: 'rect',
    x: 0.22,
    y: 0.04,
    w: 0.56,
    h: 0.92,
    r: 0.1,
    c1: Color(0xFF37474F),
    c2: Color(0xFF263238),
  ),
  _S(
    type: 'rect',
    x: 0.28,
    y: 0.14,
    w: 0.44,
    h: 0.62,
    r: 0.04,
    c1: Color(0xFF90A4AE),
    c2: Color(0xFF607D8B),
  ),
  _S(
    type: 'circle',
    x: 0.42,
    y: 0.84,
    w: 0.16,
    h: 0.1,
    r: 0.05,
    c1: Color(0xFF78909C),
    c2: Color(0xFF546E7A),
  ),
];

// 🔤 Font / Text
const _kFont = [
  _S(
    type: 'rect',
    x: 0.1,
    y: 0.12,
    w: 0.8,
    h: 0.14,
    r: 0.05,
    c1: Color(0xFF6B4EBB),
    c2: Color(0xFF4527A0),
  ),
  _S(
    type: 'rect',
    x: 0.1,
    y: 0.34,
    w: 0.6,
    h: 0.12,
    r: 0.05,
    c1: Color(0xFF8B6FCB),
    c2: Color(0xFF6B4EBB),
  ),
  _S(
    type: 'rect',
    x: 0.1,
    y: 0.54,
    w: 0.7,
    h: 0.12,
    r: 0.05,
    c1: Color(0xFF6B4EBB),
    c2: Color(0xFF4527A0),
  ),
  _S(
    type: 'rect',
    x: 0.1,
    y: 0.74,
    w: 0.45,
    h: 0.12,
    r: 0.05,
    c1: Color(0xFF8B6FCB),
    c2: Color(0xFF6B4EBB),
  ),
];

// Record — red dot
const _kRecord = [
  _S(
    type: 'circle',
    x: 0.12,
    y: 0.12,
    w: 0.76,
    h: 0.76,
    r: 0.38,
    c1: Color(0xFFE53935),
    c2: Color(0xFFB71C1C),
    radial: true,
  ),
  _S(
    type: 'circle',
    x: 0.34,
    y: 0.34,
    w: 0.32,
    h: 0.32,
    r: 0.16,
    c1: Color(0xFFEF9A9A),
    c2: Color(0xFFE53935),
    radial: true,
  ),
];

// 💎 Diamond gem
const _kDiamond = [
  _S(
    type: 'path',
    d: 'M0.3 0.08 L0.7 0.08 L0.92 0.38 L0.5 0.92 L0.08 0.38Z',
    c1: Color(0xFF29B6F6),
    c2: Color(0xFF0277BD),
  ),
  _S(
    type: 'path',
    d: 'M0.3 0.08 L0.5 0.38 L0.08 0.38Z',
    c1: Color(0xFF81D4FA),
    c2: Color(0xFF29B6F6),
  ),
  _S(
    type: 'path',
    d: 'M0.7 0.08 L0.5 0.38 L0.92 0.38Z',
    c1: Color(0xFF4FC3F7),
    c2: Color(0xFF0288D1),
  ),
  _S(
    type: 'path',
    d: 'M0.08 0.38 L0.5 0.38 L0.5 0.92Z',
    c1: Color(0xFF0288D1),
    c2: Color(0xFF0277BD),
  ),
  _S(
    type: 'path',
    d: 'M0.5 0.38 L0.92 0.38 L0.5 0.92Z',
    c1: Color(0xFF039BE5),
    c2: Color(0xFF0277BD),
  ),
];

// ⚔️ Sword
const _kSword = [
  _S(
    type: 'rect',
    x: 0.46,
    y: 0.08,
    w: 0.08,
    h: 0.7,
    r: 0.04,
    c1: Color(0xFFB0BEC5),
    c2: Color(0xFF607D8B),
  ),
  _S(
    type: 'rect',
    x: 0.24,
    y: 0.6,
    w: 0.52,
    h: 0.08,
    r: 0.03,
    c1: Color(0xFF78909C),
    c2: Color(0xFF455A64),
  ),
  _S(
    type: 'rect',
    x: 0.44,
    y: 0.78,
    w: 0.12,
    h: 0.16,
    r: 0.04,
    c1: Color(0xFFFFD54F),
    c2: Color(0xFFFF8F00),
  ),
];
