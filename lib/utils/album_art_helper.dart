// import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:echo_mpd/service/lastfm_service.dart';

Future<String?> getAlbumArtPath(String albumArtist, String album) async {
  try {
    // Get cache directory
    final Directory cacheDir = await getTemporaryDirectory();
    final String fileName = '$albumArtist - $album.jpg';
    final String filePath = path.join(cacheDir.path, fileName);
    final File file = File(filePath);

    // Check if album art already exists in cache
    if (await file.exists()) {
      // print("DEV: art cache found | $albumArtist | $album");
      return filePath;
    }

    // Album art not in cache, try to fetch URL
    // final String? albumArtUrl = await fetchAlbumArtUrl(albumArtist, album);
    final String? albumArtUrl = await LastfmService().getLargestAlbumArt(albumArtist, album);

    if (albumArtUrl == null) {
      // No album art found
      return null;
    }

    // Try to get higher resolution version first
    String? downloadUrl = _getHigherResolutionUrl(albumArtUrl);
    
    // Download and save album art to cache
    try {
      http.Response response = await http.get(Uri.parse(downloadUrl));

      // If higher resolution fails (404), try original URL
      if (response.statusCode == 404 && downloadUrl != albumArtUrl) {
        response = await http.get(Uri.parse(albumArtUrl));
      }

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

/// Replaces 300x300 with 600x600 in the album art URL if possible
String _getHigherResolutionUrl(String originalUrl) {
  // Check if URL contains 300x300 pattern
  if (originalUrl.contains('300x300')) {
    return originalUrl.replaceAll('300x300', '600x600');
  }
  
  // Return original URL if no 300x300 pattern found
  return originalUrl;
}