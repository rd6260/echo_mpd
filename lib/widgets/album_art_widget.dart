import 'dart:io';
import 'package:dart_mpd/dart_mpd.dart';
import 'package:echo_mpd/utils/album_art_helper.dart';
import 'package:flutter/material.dart';


/// Widget for displaying album art
class AlbumArtWidget extends StatelessWidget {
  final MpdSong? song;
  const AlbumArtWidget({super.key, this.song});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _buildAlbumArt(song),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return snapshot.data!;
        }
        return _buildPlaceholder();
      },
    );
  }

  Future<Widget> _buildAlbumArt(MpdSong? currentSong) async {
    String? albumArtist = currentSong?.albumArtist?[0];
    String? album = currentSong?.album?[0];

    if (albumArtist != null && album != null) {
      String? filePath = await getAlbumArtPath(albumArtist, album);

      if (filePath != null) {
        // If file path is available, show the image
        return Image.file(
          File(filePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        );
      }
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[800]!, Colors.grey[900]!],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Album Art',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
