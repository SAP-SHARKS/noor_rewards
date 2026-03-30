import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final res = await http.get(Uri.parse('https://api.quran.com/api/v4/verses/by_key/3:27?fields=text_indopak'));
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    final text = data['verse']['text_indopak'] as String;
    for (int i = 0; i < text.length; i++) {
        print('${text[i]} - U+${text.codeUnitAt(i).toRadixString(16).padLeft(4, '0')}');
    }
  }
}
