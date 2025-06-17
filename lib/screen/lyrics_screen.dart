import 'package:echo_mpd/service/mpd_remote_service.dart';
import 'package:echo_mpd/widgets/lyrics_view.dart';
import 'package:flutter/material.dart';

class LyricsScreen extends StatelessWidget {
  const LyricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black),
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
        ],
      ),
    );
  }
}
