import 'dart:io';

import 'package:dart_mpd/dart_mpd.dart';
import 'package:echo_mpd/utils/album_art_helper.dart';
import 'package:echo_mpd/utils/mpd_remote_service.dart';
import 'package:echo_mpd/widgets/album_art_placeholder.dart';
import 'package:flutter/material.dart';

class CurrentPlaylistScreen extends StatefulWidget {
  const CurrentPlaylistScreen({super.key});

  @override
  State<CurrentPlaylistScreen> createState() => _CurrentPlaylistScreenState();
}

class _CurrentPlaylistScreenState extends State<CurrentPlaylistScreen> {
  List<PlaylistItem> playlistItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPlaylistDetails();
  }

  // Empty method for you to implement later
  Future<void> fetchPlaylistDetails() async {
    MpdClient client = MpdRemoteService.instance.getCliet();
    List<MpdSong> playlist = await client.playlistid();

    for (var song in playlist) {
      String? title, album, artist;
      Duration? duration;

      if (song.title != null) title = song.title!.join("/");
      if (song.album != null) album = song.album!.join("/");
      if (song.artist != null) artist = song.albumArtist!.join("/");
      if (song.duration != null) duration = song.duration!;

      playlistItems.add(
        PlaylistItem(
          title: title,
          album: album,
          artist: artist,
          duration: duration,
        ),
      );
    }

    // await Future.delayed(const Duration(seconds: 1));
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text(
          'Playlist',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w300,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.repeat, color: Colors.white54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.shuffle, color: Colors.red),
            onPressed: () {},
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : playlistItems.isEmpty
          ? const Center(
              child: Text(
                'No songs in playlist',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: playlistItems.length,
              itemBuilder: (context, index) {
                final item = playlistItems[index];
                return PlaylistTile(
                  item: item,
                  onTap: () {
                    // Handle song tap
                  },
                  onMorePressed: () {
                    // Handle more options
                  },
                );
              },
            ),
    );
  }
}

class PlaylistItem {
  final String? title;
  final String? album;
  final String? artist;
  final Duration? duration;

  PlaylistItem({this.title, this.album, this.artist, this.duration});
}

class PlaylistTile extends StatelessWidget {
  final PlaylistItem item;
  final VoidCallback onTap;
  final VoidCallback onMorePressed;

  const PlaylistTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                // Album Art
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFF3A3A3A),
                  ),
                  child: (item.album != null && item.artist != null)
                      ? FutureBuilder(
                          future: getAlbumArtPath(item.artist!, item.album!),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.file(
                                  File(snapshot.data!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.music_note,
                                      color: Colors.white54,
                                      size: 24,
                                    );
                                  },
                                ),
                              );
                            }
                            return AlbumArtPlaceholder();
                          },
                        )
                      : AlbumArtPlaceholder(),
                ),
                const SizedBox(width: 12),
                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title ?? "",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.artist ?? "",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Duration (if available)
                if (item.duration != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      _formatDuration(item.duration!),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                // More options button
                IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: onMorePressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }
}

// Example usage and sample data (you can remove this when implementing)
class SamplePlaylistData {
  static List<PlaylistItem> getSamplePlaylist() {
    return [
      PlaylistItem(
        title: "1 step forward, 3 steps back",
        artist: "Olivia Rodrigo",
        duration: const Duration(minutes: 2, seconds: 43),
      ),
      PlaylistItem(
        title: "1, 2, 3 (feat. Jason Derulo & De La Ghetto)",
        artist: "Sofia Reyes/Jason Derulo/De La Ghetto",
        duration: const Duration(minutes: 3, seconds: 27),
      ),
      PlaylistItem(
        title: "10 I See",
        artist: "John Michael Howell",
        duration: const Duration(minutes: 3, seconds: 45),
      ),
      PlaylistItem(
        title: "10,000 Hours (with Justin Bieber)",
        artist: "Dan + Shay/Justin Bieber",
        duration: const Duration(minutes: 2, seconds: 47),
      ),
      PlaylistItem(
        title: "100 words",
        artist: "Prateek Kuhad",
        duration: const Duration(minutes: 4, seconds: 12),
      ),
    ];
  }
}
