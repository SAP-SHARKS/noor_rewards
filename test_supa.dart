import 'dart:io';

main() async {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  var urlMatch = RegExp(r"url\s*:\s*'([^']+)'").firstMatch(content);
  var keyMatch = RegExp(r"anonKey\s*:\s*'([^']+)'").firstMatch(content);
  
  if (urlMatch != null && keyMatch != null) {
    var url = urlMatch.group(1)!;
    var key = keyMatch.group(1)!;
    print(url);
    
    var res = await Process.run('curl', [
      '-s',
      '-X', 'POST',
      '$url/rest/v1/user_activities',
      '-H', 'apikey: $key',
      '-H', 'Authorization: Bearer $key',
      '-H', 'Content-Type: application/json',
      '-H', 'Prefer: return=representation',
      '-d', '{"user_id": "00000000-0000-0000-0000-000000000000", "activity_type": "daily_dhikr_goal", "points_earned": 50}'
    ]);
    print("Insert response: ${res.stdout}\n");
    print("Insert error: ${res.stderr}\n");

    var res2 = await Process.run('curl', [
      '-s', '-X', 'DELETE',
      '$url/rest/v1/user_activities?activity_type=eq.daily_dhikr_goal',
      '-H', 'apikey: $key',
      '-H', 'Authorization: Bearer $key'
    ]);
    print("Deleted all daily_dhikr_goals to reset test: ${res2.stdout}");
  }
}
