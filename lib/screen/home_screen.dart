import 'package:echo_mpd/screen/favourite_tracks_screen.dart';
import 'package:echo_mpd/service/mpd_remote_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void onFavouriteTracksTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FavouriteTracksScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Home title
              const Text(
                'Home',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 32),

              // Recently Played section
              const Text(
                'RECENTLY PLAYED',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 16),

              // Recently played grid
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    SizedBox(height: 100),
                    // Add your recently played items here
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Favorites section
              const Text(
                'FAVORITES',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 16),

              // Favorites Section - Fixed: Removed Expanded and added shrinkWrap
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true, // Important: allows GridView to size itself
                physics:
                    const NeverScrollableScrollPhysics(), // Prevents scroll conflict
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildFavouriteTracksCard(),
                  // Add more cards here if needed
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavouriteTracksCard() {
    return InkWell(
      onTap: onFavouriteTracksTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(16), // Add padding if needed
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder(
                valueListenable: MpdRemoteService.instance.favoriteSongList,
                builder: (context, value, child) => Text(
                  value.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Text(
                'Tracks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
