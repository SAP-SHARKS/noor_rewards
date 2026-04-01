import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://api.quran.com/api/v4/quran/verses/indopak?chapter_number=2');
  final res = await http.get(url);
  final body = jsonDecode(res.body);
  print(body['verses'][138]);
}
