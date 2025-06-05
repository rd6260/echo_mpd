import 'package:echo_mpd/utils/mpd_remote_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    MpdRemoteService.instance;
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: Column(
        children: [
          Expanded(child: _buildCurrentScreen()),
          _buildNowPlayingBar(),
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return _buildFoldersScreen();
      case 2:
        return _buildPlaylistsScreen();
      case 3:
        return _buildTracksScreen();
      case 4:
        return _buildAlbumsScreen();
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          Text(
            'Home',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 30),
          Text(
            'RECENTLY PLAYED',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildRecentlyPlayedItem(
                  title: 'Tracks',
                  subtitle: '1457 Tracks',
                  color: Color(0xFF2D2D2D),
                  icon: Icons.music_note,
                ),
                _buildRecentlyPlayedItem(
                  title: 'Favorite Tracks',
                  subtitle: '2 Tracks',
                  color: Color(0xFFD32F2F),
                  icon: Icons.favorite,
                ),
                _buildRecentlyPlayedItem(
                  title: 'Adventure Time: C...',
                  subtitle: 'Adventure Time',
                  color: Color(0xFFE0E0E0),
                  isImage: true,
                ),
                _buildRecentlyPlayedItem(
                  title: 'Sunflower Seed',
                  subtitle: 'Bryce Vine',
                  color: Color(0xFFFFC107),
                  icon: Icons.wb_sunny,
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
          Text(
            'FAVORITES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFD32F2F).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '2',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Tracks',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyPlayedItem({
    required String title,
    required String subtitle,
    required Color color,
    IconData? icon,
    bool isImage = false,
  }) {
    return Container(
      width: 120,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(
                child: isImage
                    ? Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'AT',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      )
                    : Icon(
                        icon ?? Icons.music_note,
                        size: 40,
                        color: color == Color(0xFFE0E0E0)
                            ? Colors.black
                            : Colors.white,
                      ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color == Color(0xFFE0E0E0)
                        ? Colors.black
                        : Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        (color == Color(0xFFE0E0E0)
                                ? Colors.black
                                : Colors.white)
                            .withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlayingBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D2D2D), Color(0xFF3D3D3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                // image: DecorationImage(
                //   image: AssetImage(
                //     'assets/album_art.jpg',
                //   ), // You'll need to add this asset
                //   fit: BoxFit.cover,
                // ),
                color: Color(0xFF4A90E2), // Fallback color
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Color(0xFF4A90E2),
                ),
                child: Icon(Icons.music_note, color: Colors.white, size: 24),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hypotheticals',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Fran Vasilić',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            _buildControlButton(Icons.skip_previous, 24),
            SizedBox(width: 8),
            _buildPlayPauseButton(),
            SizedBox(width: 8),
            _buildControlButton(Icons.skip_next, 24),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, double size) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: size),
        onPressed: () {},
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0xFFE91E63).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 24,
        ),
        onPressed: () {
          setState(() {
            _isPlaying = !_isPlaying;
          });
        },
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Color(0xFFE91E63),
        unselectedItemColor: Colors.white54,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'FOLDERS'),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play),
            label: 'PLAYLISTS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'TRACKS',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.album), label: 'ALBUMS'),
        ],
      ),
    );
  }

  // Placeholder screens for other tabs
  Widget _buildFoldersScreen() {
    return Center(
      child: Text(
        'Folders',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }

  Widget _buildPlaylistsScreen() {
    return Center(
      child: Text(
        'Playlists',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }

  Widget _buildTracksScreen() {
    return Center(
      child: Text(
        'Tracks',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }

  Widget _buildAlbumsScreen() {
    return Center(
      child: Text(
        'Albums',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}
