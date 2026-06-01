// Crops the launcher icon so the coin fills the entire canvas with NO
// transparent padding. The Android adaptive-icon system was rendering the
// coin smaller than the icon because the source had transparent corners +
// padding, letting the background colour bleed through as a visible ring.
//
// Run with:
//   dart run tools/crop_launcher_icon.dart
//
// Reads:  assets/images/app_icon_launcher.png
// Writes: assets/images/app_icon_launcher.png  (overwrites the source)
// Backup: assets/images/app_icon_launcher.original.png

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const inPath = 'assets/images/app_icon_launcher.png';
  const backupPath = 'assets/images/app_icon_launcher.before_crop.png';
  const targetSize = 1024;

  final file = File(inPath);
  if (!file.existsSync()) {
    stderr.writeln('Source not found: $inPath');
    exit(1);
  }

  final bytes = file.readAsBytesSync();
  final src = img.decodePng(bytes);
  if (src == null) {
    stderr.writeln('Failed to decode PNG');
    exit(1);
  }

  // Backup the original before overwriting.
  if (!File(backupPath).existsSync()) {
    File(backupPath).writeAsBytesSync(bytes);
    stdout.writeln('Backup written: $backupPath');
  }

  // Find the bounding box of any non-transparent (alpha > 8) pixel.
  int minX = src.width, minY = src.height, maxX = 0, maxY = 0;
  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      final px = src.getPixel(x, y);
      if (px.a > 8) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (maxX <= minX || maxY <= minY) {
    stderr.writeln('Source appears fully transparent — nothing to crop.');
    exit(1);
  }

  final w = maxX - minX + 1;
  final h = maxY - minY + 1;
  stdout.writeln(
      'Source: ${src.width}x${src.height}, opaque bbox: ${w}x$h at ($minX,$minY)');

  // Crop to that bounding box.
  final cropped = img.copyCrop(src, x: minX, y: minY, width: w, height: h);

  // Resize to a perfect square at the target size while preserving the
  // bbox's aspect (it should already be 1:1 for the coin). If not square,
  // pad equally on the shorter axis with transparency so the visible coin
  // stays centred.
  img.Image squared;
  if (w == h) {
    squared = img.copyResize(cropped, width: targetSize, height: targetSize,
        interpolation: img.Interpolation.cubic);
  } else {
    final side = w > h ? w : h;
    final pad = img.Image(width: side, height: side, numChannels: 4);
    img.fill(pad, color: img.ColorRgba8(0, 0, 0, 0));
    img.compositeImage(pad, cropped,
        dstX: ((side - w) / 2).round(), dstY: ((side - h) / 2).round());
    squared = img.copyResize(pad, width: targetSize, height: targetSize,
        interpolation: img.Interpolation.cubic);
  }

  File(inPath).writeAsBytesSync(img.encodePng(squared));
  stdout.writeln('Wrote tightly-cropped ${targetSize}x$targetSize → $inPath');
  stdout.writeln('Now run:  flutter pub run flutter_launcher_icons');
}
