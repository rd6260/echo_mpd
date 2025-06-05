import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> fetchAlbumArtUrl(String artist, String title) async {
  // Step 1: Search MusicBrainz for the release
  final searchUrl = Uri.parse(
    'https://musicbrainz.org/ws/2/release/?query=album:"$title" AND artist:"$artist"&fmt=json',
  );

  final searchResponse = await http.get(searchUrl);

  if (searchResponse.statusCode != 200) {
    print('DEV: FAILD TO FETCH ALBUL ART | $artist | $title');
    return null;
  }

  final searchData = json.decode(searchResponse.body);
  final releases = searchData['releases'] as List<dynamic>;

  if (releases.isEmpty) {
    print('DEV: No releases found | $artist | $title');
    return null;
  }

  final mbid = releases[0]['id'];

  // Step 2: Get cover art from Cover Art Archive
  final coverUrl = Uri.parse('https://coverartarchive.org/release/$mbid');

  final coverResponse = await http.get(coverUrl);

  if (coverResponse.statusCode != 200) {
    print('DEV: No cover art found | $artist | $title');
    return null;
  }

  final coverData = json.decode(coverResponse.body);
  final images = coverData['images'] as List<dynamic>;

  if (images.isEmpty || images[0]['image'] == null) {
    print('DEV: No images in cover data | $artist | $title');
    return null;
  }

  return images[0]['image'];
}
