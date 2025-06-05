import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<String?> getAlbumArtPath(String artist, String album) async {
  try {
    // Get cache directory
    final Directory cacheDir = await getTemporaryDirectory();
    final String fileName = '$artist - $album.jpg';
    final String filePath = path.join(cacheDir.path, fileName);
    final File file = File(filePath);

    // Check if album art already exists in cache
    if (await file.exists()) {
      return filePath;
    }

    // Album art not in cache, try to fetch URL
    final String? albumArtUrl = await fetchAlbumArtUrl(artist, album);

    if (albumArtUrl == null) {
      // No album art found
      return null;
    }

    // Download and save album art to cache
    try {
      final http.Response response = await http.get(Uri.parse(albumArtUrl));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        // Failed to download
        return null;
      }
    } catch (e) {
      // Error downloading album art
      // print('Error downloading album art: $e');
      return null;
    }
  } catch (e) {
    // Error accessing cache directory or other filesystem operations
    // print('Error in getAlbumArtPath: $e');
    return null;
  }
}

Future<String?> fetchAlbumArtUrl(String artist, String album) async {
  // Step 1: Search MusicBrainz for the release
  final searchUrl = Uri.parse(
    'https://musicbrainz.org/ws/2/release/?query=album:"$album" AND artist:"$artist"&fmt=json',
  );

  final searchResponse = await http.get(searchUrl);

  if (searchResponse.statusCode != 200) {
    // print('DEV: FAILD TO FETCH ALBUL ART | $artist | $title');
    return null;
  }

  final searchData = json.decode(searchResponse.body);
  final releases = searchData['releases'] as List<dynamic>;

  if (releases.isEmpty) {
    // print('DEV: No releases found | $artist | $title');
    return null;
  }

  final mbid = releases[0]['id'];

  // Step 2: Get cover art from Cover Art Archive
  final coverUrl = Uri.parse('https://coverartarchive.org/release/$mbid');

  final coverResponse = await http.get(coverUrl);

  if (coverResponse.statusCode != 200) {
    // print('DEV: No cover art found | $artist | $title');
    return null;
  }

  final coverData = json.decode(coverResponse.body);
  final images = coverData['images'] as List<dynamic>;

  if (images.isEmpty || images[0]['image'] == null) {
    // print('DEV: No images in cover data | $artist | $title');
    return null;
  }

  return images[0]['image'];
}
