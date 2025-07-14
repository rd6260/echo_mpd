import 'package:echo_mpd/service/mpd_remote_service.dart';
import 'package:echo_mpd/service/settings.dart';
import 'package:echo_mpd/widgets/track_group_view.dart';
import 'package:flutter/material.dart';

class FavouriteTracksScreen extends StatelessWidget {
  const FavouriteTracksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: TrackGroupView(
        artWork: _buildArtWork(),
        tracks: MpdRemoteService.instance.favoriteSongList.value,
        type: 'PLAYLIST',
        name: 'FAVORITE TRACKS',
      ),
    );
  }

  Widget _buildArtWork() {
    return Container(
      decoration: const BoxDecoration(
        color:  Color(Settings.primaryColor),
      ),
      child: const Icon(Icons.music_note, color: Colors.white54, size: 24),
    );
  }
}
