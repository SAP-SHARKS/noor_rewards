import 'dart:io';

void main() {
  final f = File('lib/screens/dhikr_screen.dart');
  final content = f.readAsStringSync();

  // The old duplicated code starts at 'late AnimationController _pulseCtrl, _growCtrl, _starCtrl, _pCtrl'
  // inside _FiveBlessingsState and runs through the old _FiveBlessingsPainter's shouldRepaint closing }
  // We need to remove from the second _FiveBlessingsState body down to the old } closing _FiveBlessingsPainter

  // Marker: first occurrence is our NEW code, second occurrence is the OLD leftover
  const marker1 = '  late AnimationController _pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _flowCtrl;\r\n  late Animation<double> _pulse, _grow, _pAnim, _punch, _shock;';
  
  const endOld = '  bool shouldRepaint(_FiveBlessingsPainter o) =>\r\n      o.progress != progress || o.pulse != pulse ||\r\n      o.starPhase != starPhase || o.particlePhase != particlePhase ||\r\n      o.isComplete != isComplete || o.pointsToday != pointsToday ||\r\n      o.punchScale != punchScale || o.shockPhase != shockPhase ||\r\n      o.flowPhase != flowPhase;\r\n}';

  // Also need to remove the stray @override + createState + class redeclaration
  const strayBlock = '\r\n\r\n  @override\r\n  State<_FiveBlessings> createState() => _FiveBlessingsState();\r\n}\r\n\r\nclass _FiveBlessingsState extends State<_FiveBlessings> with TickerProviderStateMixin {\r\n  late AnimationController _pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl, _flowCtrl;';

  if (!content.contains(marker1)) {
    print('ERROR: marker1 not found');
    return;
  }
  if (!content.contains(endOld)) {
    print('ERROR: endOld not found');
    print('Looking for partial...');
    if (content.contains('o.flowPhase != flowPhase;')) print('flowPhase line found');
    return;
  }

  // Find the stray block and remove it along with everything up to endOld
  final strayStart = content.indexOf(strayBlock);
  final endOldIdx = content.indexOf(endOld);

  if (strayStart == -1) {
    print('ERROR: strayBlock not found');
    return;
  }

  print('strayStart=$strayStart, endOldIdx=$endOldIdx');
  
  // Remove from strayStart to end of endOld
  final removeEnd = endOldIdx + endOld.length;
  final newContent = content.substring(0, strayStart) + content.substring(removeEnd);
  
  f.writeAsStringSync(newContent);
  print('Done! Removed ${removeEnd - strayStart} chars of old duplicate code.');
}
