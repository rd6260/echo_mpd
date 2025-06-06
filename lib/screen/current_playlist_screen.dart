import 'package:echo_mpd/types/playlist_item.dart';
import 'package:echo_mpd/utils/mpd_remote_service.dart';
import 'package:echo_mpd/widgets/playlist_tile.dart';
import 'package:flutter/material.dart';

class CurrentPlaylistScreen extends StatefulWidget {
  const CurrentPlaylistScreen({super.key});

  @override
  State<CurrentPlaylistScreen> createState() => _CurrentPlaylistScreenState();
}

class _CurrentPlaylistScreenState extends State<CurrentPlaylistScreen> {
  // List<PlaylistItem> playlistItems = [];
  bool isLoading = true;

  // @override
  // void initState() {
  //   super.initState();
  //   fetchPlaylistDetails();
  // }

  // Empty method for you to implement later
  // Future<void> fetchPlaylistDetails() async {
  //   MpdClient client = MpdRemoteService.instance.client;
  //   List<MpdSong> playlist = await client.playlistid();

  //   for (var song in playlist) {
  //     String? title, album, artist;
  //     Duration? duration;

  //     if (song.title != null) title = song.title!.join("/");
  //     if (song.album != null) album = song.album!.join("/");
  //     if (song.artist != null) artist = song.albumArtist!.join("/");
  //     if (song.duration != null) duration = song.duration!;

  //     playlistItems.add(
  //       PlaylistItem(
  //         title: title,
  //         album: album,
  //         artist: artist,
  //         duration: duration,
  //       ),
  //     );
  //   }

  //   // await Future.delayed(const Duration(seconds: 1));
  //   setState(() {
  //     isLoading = false;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
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
      // body: _buildPlaylist(),
      body: ValueListenableBuilder(
        valueListenable: MpdRemoteService.instance.currentPlaylist,
        builder: (context, value, child) {
          return _buildPlaylist(value);
        },
      ),
    );
  }

  Widget _buildPlaylist(List<PlaylistItem> queue) {
    return queue.isEmpty
        ? const Center(
            child: Text(
              'No songs in playlist',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          )
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final item = queue[index];
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
              ),
              SizedBox(height: 30),
            ],
          );
  }
}

// =============================================================================
