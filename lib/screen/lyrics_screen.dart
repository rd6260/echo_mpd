import 'package:echo_mpd/service/mpd_remote_service.dart';
import 'package:echo_mpd/widgets/lyrics_view.dart';
import 'package:echo_mpd/widgets/music_progress_slider_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  void _onPlayPause() {
    MpdRemoteService.instance.client.pause();
  }

  void _onNextTrack() {
    MpdRemoteService.instance.client.next();
  }

  void _onPreviousTrack() {
    MpdRemoteService.instance.client.previous();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // lyrics view
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: MpdRemoteService.instance.currentSong,
              builder: (context, value, child) {
                return LyricsView();
              },
            ),
          ),

          // Music progress slider
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 20,
            children: [
              // Previous Button
              IconButton(
                onPressed: _onPreviousTrack,
                icon: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              // Play/Pause Button
              ValueListenableBuilder(
                valueListenable: MpdRemoteService.instance.isPlaying,
                builder: (context, isPlaying, child) => Container(
                  width: 80,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF314B17),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    onPressed: _onPlayPause,
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              // Next Button
              IconButton(
                onPressed: _onNextTrack,
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }
}
