import 'package:dart_mpd/dart_mpd.dart';
import 'package:echo_mpd/service/mpd_remote_service.dart';
import 'package:echo_mpd/service/settings.dart';
import 'package:echo_mpd/utils/wait_for_notifier.dart';
import 'package:echo_mpd/widgets/track_group_view.dart';
import 'package:flutter/material.dart';

class FavouriteTracksScreen extends StatelessWidget {
  const FavouriteTracksScreen({super.key});

  Future<void> onTrackTap(MpdSong song) async {
    int index = MpdRemoteService.instance.currentPlaylist.value.indexWhere(
      (queuedSong) => queuedSong.file == song.file,
    );

    if (index != -1) {
      await MpdRemoteService.instance.client.play(index);
      return;
    }

    await MpdRemoteService.instance.client.add(song.file);
    await waitForNotifier(MpdRemoteService.instance.currentPlaylist);

    index = MpdRemoteService.instance.currentPlaylist.value.indexWhere(
      (queuedSong) => queuedSong.file == song.file,
    );

    if (index != -1) await MpdRemoteService.instance.client.play(index);
  }

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
        onTrackTap: onTrackTap,
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
