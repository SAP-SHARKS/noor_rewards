import 'dart:io';
import 'package:http/http.dart' as http;

main() async {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  var urlMatch = RegExp(r"url:\s*'([^']+)'").firstMatch(content);
  var keyMatch = RegExp(r"anonKey:\s*'([^']+)'").firstMatch(content);
  if (urlMatch != null && keyMatch != null) {
    var url = urlMatch.group(1)!;
    var key = keyMatch.group(1)!;

    // Check existing columns first
    var res = await http.get(
      Uri.parse('$url/rest/v1/community_projects?limit=1'),
      headers: {'apikey': key, 'Authorization': 'Bearer $key'},
    );
    print(res.body);
  }
}
