// Rebuilds the launcher icon so the coin fills the FULL 1024 canvas.
// Used as adaptive_icon_background, the launcher's mask trims its corners
// (which are transparent on a round coin) — visible result is just the
// gold coin, no surrounding colour.
//
// Run with:  dart run tools/fill_launcher_icon.dart

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const sourceCandidates = [
    'assets/images/app_icon_launcher.before_crop.png',
    'assets/images/app_icon_launcher.original.png',
    'assets/images/app_icon_launcher.png',
  ];
  const outPath = 'assets/images/app_icon_launcher.png';
  const targetSize = 1024;

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

  // Opaque bbox
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
  stdout.writeln('Coin bbox: ${bw}x$bh');

  final cropped =
      img.copyCrop(src, x: minX, y: minY, width: bw, height: bh);

  // Resize so the coin fills the full 1024 canvas (square).
  final scaled = img.copyResize(cropped,
      width: targetSize,
      height: targetSize,
      interpolation: img.Interpolation.cubic);

  File(outPath).writeAsBytesSync(img.encodePng(scaled));
  stdout.writeln(
      'Wrote: $outPath  (coin = ${targetSize}px / ${targetSize}px = 100%)');
  stdout.writeln('Now run:  flutter pub run flutter_launcher_icons');
}
