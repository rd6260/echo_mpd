import 'package:echo_mpd/screen/albums_screen.dart';
import 'package:echo_mpd/screen/artists_screen.dart';
import 'package:echo_mpd/screen/home_screen.dart';
import 'package:echo_mpd/screen/playlists_screen.dart';
import 'package:echo_mpd/screen/queue_screen.dart';
import 'package:echo_mpd/screen/tracks_screen.dart';
import 'package:echo_mpd/widgets/bottom_island_widget.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;
  final _currentIndexNotifier = ValueNotifier<int>(0);

  final List<String> _tabs = [
    'HOME',
    'QUEUE',
    'TRACKS',
    'PLAYLISTS',
    'ALBUMS',
    'ARTISTS',
  ];

  final List<Widget> _screens = [
    HomeScreen(),
    QueueScreen(),
    TracksScreen(),
    PlaylistsScreen(),
    AlbumsScreen(),
    ArtistsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (_currentIndexNotifier.value == index) return;
    
    _currentIndexNotifier.value = index;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                _currentIndexNotifier.value = index;
              },
              children: _screens,
            ),

            // Bottom music player island
            Align(
              alignment: Alignment.bottomCenter,
              child: BottomIslandWidget(
                tabList: _tabs,
                currentIndexNotifier: _currentIndexNotifier,
                onTabChanged: _onTabChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}