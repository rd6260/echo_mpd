import 'package:flutter/material.dart';

class CurrentPlaylistScreen extends StatelessWidget {
  const CurrentPlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Playlist")),
      body: Center(
        child: ElevatedButton(onPressed: () {}, child: Text("Get info")),
      ),
    );
  }
}
