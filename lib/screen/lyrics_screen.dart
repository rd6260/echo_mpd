import 'package:echo_mpd/service/mpd_remote_service.dart';
import 'package:echo_mpd/widgets/lyrics_view.dart';
import 'package:echo_mpd/widgets/music_progress_slider_widget.dart';
import 'package:flutter/material.dart';

class LyricsScreen extends StatelessWidget {
  const LyricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: MpdRemoteService.instance.currentSong,
              builder: (context, value, child) {
                return LyricsView();
              },
            ),
          ),
          ValueListenableBuilder<Duration?>(
            valueListenable: MpdRemoteService.instance.elapsed,
            builder: (context, elapsed, child) {
              final totalDuration =
                  MpdRemoteService.instance.currentSong.value?.time
                      ?.toDouble() ??
                  0.0;
              final currentElapsed = elapsed?.inSeconds.toDouble() ?? 0.0;

              return ProgressSliderWidget(
                totalDuration: totalDuration,
                currentElapsed: currentElapsed,
              );
            },
          ),
          SizedBox(height: 100),
        ],
      ),
    );
  }
}
