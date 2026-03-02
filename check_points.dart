import 'dart:convert';
import 'dart:io';

main() async {
  var file = File('lib/services/supabase_service.dart');
  var content = file.readAsStringSync();
  var urlMatch = RegExp(r"url\s*=\s*'([^']+)'").firstMatch(content);
  var keyMatch = RegExp(r"anonKey\s*=\s*'([^']+)'").firstMatch(content);
  
  if (urlMatch != null && keyMatch != null) {
    var url = urlMatch.group(1)!;
    var key = keyMatch.group(1)!;
    
    var res = await Process.run('curl', [
      '-s',
      '-X', 'GET',
      '$url/rest/v1/community_projects?select=id,title,current_points,target_points',
      '-H', 'apikey: $key',
      '-H', 'Authorization: Bearer $key'
    ]);
    print("Community projects: ${res.stdout}\n");

    var res2 = await Process.run('curl', [
      '-s',
      '-X', 'GET',
      '$url/rest/v1/user_donations?select=project_id,points_donated',
      '-H', 'apikey: $key',
      '-H', 'Authorization: Bearer $key'
    ]);
    print("User donations: ${res2.stdout}");
  }
}
