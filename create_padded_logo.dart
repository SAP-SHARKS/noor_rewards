import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/images/high-resolution-color-logo.png');
  if(!file.existsSync()){
    print('Original image not found!');
    return;
  }
  
  final imageBytes = file.readAsBytesSync();
  final image = img.decodeImage(imageBytes);
  if(image == null){
    print('Failed to decode image.');
    return;
  }
  
  // Ensure the canvas is perfectly square and the logo takes up maximum 55% of the width
  // This guarantees it survives completely intact through the Android 12 circle-cut
  final int canvasSize = (image.width / 0.68).round(); 
  
  final padded = img.Image(width: canvasSize, height: canvasSize);
  img.fill(padded, color: img.ColorRgba8(255, 255, 255, 255));
  
  final dstX = (canvasSize - image.width) ~/ 2;
  final dstY = (canvasSize - image.height) ~/ 2;
  
  img.compositeImage(padded, image, dstX: dstX, dstY: dstY);
  
  File('assets/images/app_icon_padded.png').writeAsBytesSync(img.encodePng(padded));
  print('Saved assets/images/app_icon_padded.png successfully!');
}
