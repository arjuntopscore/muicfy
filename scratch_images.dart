import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final artists = ['Anirudh Ravichander', 'Yuvan Shankar Raja', 'Sushin Shyam', 'Jakes Bejoy', 'Hesham Abdul Wahab', 'Sai Abhyankar'];
  for (final artist in artists) {
    try {
      final res = await http.get(Uri.parse('https://jiosaavn-api2.arjunktp88.workers.dev/api/search/artists?query=$artist'));
      final data = json.decode(res.body);
      final results = data['data']['results'];
      if (results != null && results.isNotEmpty) {
        final images = results[0]['image'];
        if (images != null && images is List && images.isNotEmpty) {
          final url = images.last['url']; // highest quality
          print('$artist: $url');
        } else {
          print('$artist: No image list found');
        }
      } else {
        print('$artist: No results');
      }
    } catch (e) {
      print('Error for $artist: $e');
    }
  }
}
