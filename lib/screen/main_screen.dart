import 'package:echo_mpd/screen/albums_screen.dart';
import 'package:echo_mpd/screen/artists_screen.dart';
import 'package:echo_mpd/screen/home_screen.dart';
import 'package:echo_mpd/screen/playlists_screen.dart';
import 'package:echo_mpd/screen/queue_screen.dart';
import 'package:echo_mpd/screen/tracks_screen.dart';
import 'package:echo_mpd/widgets/bottom_island_widget.dart';
import 'package:flutter/material.dart';

/// Main screen with custom smooth sliding animation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  final _currentIndexNotifier = ValueNotifier<int>(0);
  int _previousIndex = 0;
  bool _isAnimating = false;

  final List<String> _tabs = [
    'HOME',
    'QUEUE',
    'TRACKS',
    'PLAYLISTS',
    'ALBUMS',
    'ARTISTS',
  ];

  // screens corresponding to each tab
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
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) async {
    if (_currentIndexNotifier.value == index || _isAnimating) return;

    _isAnimating = true;
    _previousIndex = _currentIndexNotifier.value;

    _currentIndexNotifier.value = index;

    await _slideController.forward();
    _slideController.reset();
    _isAnimating = false;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Custom sliding pages
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                final currentIndex = _currentIndexNotifier.value;
                final isMovingRight = currentIndex > _previousIndex;
                final slideOffset = _slideAnimation.value;

                return Stack(
                  children: [
                    // Previous screen sliding out
                    if (_isAnimating)
                      Transform.translate(
                        offset: Offset(
                          isMovingRight
                              ? -screenWidth * slideOffset
                              : screenWidth * slideOffset,
                          0,
                        ),
                        child: _screens[_previousIndex],
                      ),

                    // Current screen sliding in
                    Transform.translate(
                      offset: Offset(
                        _isAnimating
                            ? (isMovingRight
                                  ? screenWidth * (1 - slideOffset)
                                  : -screenWidth * (1 - slideOffset))
                            : 0,
                        0,
                      ),
                      child: _screens[currentIndex],
                    ),
                  ],
                );
              },
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
