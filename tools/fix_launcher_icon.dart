// Re-builds the launcher icon from the original backup with the coin
// sized at ~88% of the 1024 canvas — large enough to dwarf the
// background colour, small enough that no launcher mask (circle,
// squircle, rounded-square) clips the gold rim.
//
// Run with:  dart run tools/fix_launcher_icon.dart

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const sourceCandidates = [
    'assets/images/app_icon_launcher.before_crop.png',
    'assets/images/app_icon_launcher.original.png',
    'assets/images/app_icon_launcher.png', // last resort
  ];
  const outPath = 'assets/images/app_icon_launcher.png';
  const targetSize = 1024;
  // Coin should occupy this fraction of the 1024 canvas. 0.88 puts the
  // outer gold rim safely inside every common Android launcher mask
  // (Pixel ~0.92, Samsung ~0.95, Xiaomi ~0.90) while leaving only a
  // hair of brass-gold background visible at the very corners.
  const coinFraction = 0.88;

  String? srcPath;
  for (final p in sourceCandidates) {
    if (File(p).existsSync()) {
      srcPath = p;
      break;
    }
  }
  if (srcPath == null) {
    stderr.writeln('No source image found.');
    exit(1);
  }
  stdout.writeln('Using source: $srcPath');

  final src = img.decodePng(File(srcPath).readAsBytesSync());
  if (src == null) {
    stderr.writeln('Decode failed');
    exit(1);
  }

  // Find the opaque bounding box of the coin.
  int minX = src.width, minY = src.height, maxX = 0, maxY = 0;
  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      if (src.getPixel(x, y).a > 8) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }
  final bw = maxX - minX + 1;
  final bh = maxY - minY + 1;
  stdout.writeln('Coin bbox: ${bw}x$bh at ($minX,$minY)');

  // Crop to bbox first.
  final cropped =
      img.copyCrop(src, x: minX, y: minY, width: bw, height: bh);

  // Resize so the coin's diameter is `coinFraction × targetSize`.
  final coinPx = (targetSize * coinFraction).round();
  final scaled = img.copyResize(cropped,
      width: coinPx, height: coinPx, interpolation: img.Interpolation.cubic);

  // Place on a transparent square canvas at targetSize, centred.
  final out = img.Image(width: targetSize, height: targetSize, numChannels: 4);
  img.fill(out, color: img.ColorRgba8(0, 0, 0, 0));
  final off = ((targetSize - coinPx) / 2).round();
  img.compositeImage(out, scaled, dstX: off, dstY: off);

  File(outPath).writeAsBytesSync(img.encodePng(out));
  stdout.writeln('Wrote: $outPath  (coin = ${coinPx}px / ${targetSize}px = '
      '${(coinFraction * 100).round()}%)');
  stdout.writeln('Now run:  flutter pub run flutter_launcher_icons');
}
