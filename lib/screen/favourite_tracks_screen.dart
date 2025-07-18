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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(Settings.primaryColor),
            Color(Settings.primaryColor).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(Settings.primaryColor).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.favorite_rounded,
        color: Colors.white.withValues(alpha: 0.9),
        size: 28,
      ),
    );
  }
}
