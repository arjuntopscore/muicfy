import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final query = 'hello';
  final url1 = Uri.parse('https://jiosaavn-api2.arjunktp88.workers.dev/api/search/songs?query=\$query');
  final url2 = Uri.parse('https://jiosaavn-api2.arjunktp88.workers.dev/api/search/songs?query=\$query&language=tamil,malayalam');
  
  try {
    final res1 = await http.get(url1);
    final res2 = await http.get(url2);
    
    final data1 = json.decode(res1.body)['data']['results'] as List;
    final data2 = json.decode(res2.body)['data']['results'] as List;
    
    print('Default search first song: \${data1[0]['title']} (\${data1[0]['language']})');
    print('Language filter search first song: \${data2[0]['title']} (\${data2[0]['language']})');
  } catch (e) {
    print('Error: \$e');
  }
}
