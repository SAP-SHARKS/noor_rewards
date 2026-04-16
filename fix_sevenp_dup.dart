import 'dart:io';

void main() {
  final f = File('lib/screens/dhikr_screen.dart');
  final content = f.readAsStringSync();

  // Remove the old stray code — from the stray '@override\n  State<_SevenPillars>'
  // down through and including the old _SevenPillarsPainter closing }
  const strayMarker = '\r\n\r\n  @override\r\n  State<_SevenPillars> createState() => _SevenPillarsState();\r\n}\r\n\r\nclass _SevenPillarsState extends State<_SevenPillars>\r\n    with TickerProviderStateMixin {\r\n  late AnimationController _pulseCtrl;';

  const endMarker = '  bool shouldRepaint(_SevenPillarsPainter o) =>\r\n      o.progress != progress || o.pulse != pulse ||\r\n      o.starPhase != starPhase || o.particlePhase != particlePhase ||\r\n      o.isComplete != isComplete || o.pointsToday != pointsToday ||\r\n      o.punchScale != punchScale || o.shockPhase != shockPhase ||\r\n      o.shimmerPhase != shimmerPhase;\r\n}';

  final strayIdx = content.indexOf(strayMarker);
  final endIdx   = content.indexOf(endMarker);

  if (strayIdx == -1) { print('ERROR: strayMarker not found'); return; }
  if (endIdx   == -1) { print('ERROR: endMarker not found'); return; }

  final removeEnd = endIdx + endMarker.length;
  print('Removing chars $strayIdx to $removeEnd');

  final newContent = content.substring(0, strayIdx) + content.substring(removeEnd);
  f.writeAsStringSync(newContent);
  print('Done. Removed ${removeEnd - strayIdx} chars of old _SevenPillars duplicate.');
}
