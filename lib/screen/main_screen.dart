import 'package:echo_mpd/screen/current_playlist_screen.dart';
import 'package:echo_mpd/screen/home_screen.dart';
import 'package:echo_mpd/widgets/bottom_island_widget.dart';
import 'package:flutter/material.dart';

/// Main screen that holds the pages
class MainScreen extends StatelessWidget {
  MainScreen({super.key});
  final _pageController = PageController();
  final List<String> _tabs = [
    'HOME',
    'PLAYLISTS',
    'TRACKS',
    'ALBUMS',
    'ARTISTS',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Pages
            PageView(
              controller: _pageController,
              children: [HomeScreen(), CurrentPlaylistScreen()],
            ),

            // Bottom music player island
            Align(
              alignment: Alignment.bottomCenter,
              child: BottomIslandWidget(tabList: _tabs),
            ),
          ],
        ),
      ),
    );
  }
}
