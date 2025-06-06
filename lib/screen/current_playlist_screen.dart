import 'package:dart_mpd/dart_mpd.dart';
import 'package:echo_mpd/utils/mpd_remote_service.dart';
import 'package:echo_mpd/widgets/playlist_tile.dart';
import 'package:flutter/material.dart';

class CurrentPlaylistScreen extends StatefulWidget {
  const CurrentPlaylistScreen({super.key});

  @override
  State<CurrentPlaylistScreen> createState() => _CurrentPlaylistScreenState();
}

class _CurrentPlaylistScreenState extends State<CurrentPlaylistScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ValueListenableBuilder(
        valueListenable: MpdRemoteService.instance.currentPlaylist,
        builder: (context, value, child) {
          return _buildPlaylist(value);
        },
      ),
    );
  }

  Widget _buildPlaylist(List<MpdSong> queue) {
    if (queue.isEmpty) {
      return const Center(
        child: Text(
          'No songs in playlist',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    } else {
      return ListView.builder(
        padding: EdgeInsets.only(bottom: 200),
        itemCount: queue.length,
        itemBuilder: (context, index) {
          final song = queue[index];
          return PlaylistTile(
            song: song,
            onTap: () {
              // Handle song tap
            },
            onMorePressed: () {
              // Handle more options
            },
          );
        },
      );
    }
  }
}
