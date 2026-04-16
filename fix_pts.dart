import 'dart:io';

void main() {
  final f = File('lib/screens/dhikr_screen.dart');
  var c = f.readAsStringSync();
  
  // shift the capsule UP significantly (0.82 -> 0.74) for more boundary spacing
  c = c.replaceAll(
    'final badgeY = h * 0.82 + tp2.height + 6;', 
    'final badgeY = h * 0.73 + tp2.height + 12;'
  );
  
  // Nudge the text vertically within the capsule by 1.5 pixels natively to offset ascenders
  c = c.replaceAll(
    'tp3.paint(canvas, Offset(badgeX + 18, badgeY + 9));', 
    'tp3.paint(canvas, Offset(badgeX + 18, badgeY + (badgeH - tp3.height) / 2));'
  );
  
  c = c.replaceAll(
    'final bx = cx - (tp3.width + 20) / 2, by = h * 0.80 + tp2.height + 6;', 
    'final bx = cx - (tp3.width + 20) / 2, by = h * 0.73 + tp2.height + 12;'
  );
  
  c = c.replaceAll(
    'tp3.paint(canvas, Offset(bx + 10, by + 5));', 
    'tp3.paint(canvas, Offset(bx + 10, by + (tp3.height + 10 - tp3.height) / 2));'
  );
  
  f.writeAsStringSync(c);
}
