import 'dart:io';

import 'package:echo_mpd/utils/album_art_helper.dart';
import 'package:echo_mpd/utils/mpd_remote_service.dart';
import 'package:echo_mpd/widgets/album_art_placeholder.dart';
import 'package:flutter/material.dart';
// import 'your_mpd_service.dart'; // Import your MpdRemoteService

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Main content
            Expanded(
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
                        children: [
                          _buildRecentlyPlayedItem(
                            'Kendrick Lamar',
                            '6 Tracks',
                            Colors.white,
                          ),
                          _buildRecentlyPlayedItem(
                            'Tracks',
                            '1457 Tracks',
                            Colors.white,
                          ),
                          _buildRecentlyPlayedItem(
                            'Favorite Tracks',
                            '2 Tracks',
                            const Color(0xFFDC2626), // Red accent
                          ),
                          _buildRecentlyPlayedItem(
                            'Adventure Time',
                            'Adventure Time',
                            Colors.blue,
                            hasImage: true,
                          ),
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

                    // Favorites card
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
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
                  ],
                ),
              ),
            ),

            // Bottom music player island
            _buildBottomMusicPlayer(),

            // Bottom navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyPlayedItem(
    String title,
    String subtitle,
    Color dotColor, {
    bool hasImage = false,
  }) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.cyan],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  )
                : Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: dotColor, width: 2),
                      ),
                      child: _buildDotPattern(dotColor),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDotPattern(Color color) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 36,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
      },
    );
  }

  Widget _buildBottomMusicPlayer() {
    return ValueListenableBuilder(
      valueListenable: MpdRemoteService.instance.currentSong,
      builder: (context, currentSong, child) {
        // Get the current song information
        String? songTitle = currentSong?.title?.join("");
        String? album = currentSong?.album?.join("");
        String? artistName = currentSong?.artist?.join("/");

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Album art
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: (artistName != null && album != null)
                    ? FutureBuilder(
                        future: getAlbumArtPath(artistName, album),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.file(
                                File(snapshot.data!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    AlbumArtPlaceholder(),
                              ),
                            );
                          }
                          return AlbumArtPlaceholder();
                        },
                      )
                    : AlbumArtPlaceholder(),
              ),

              const SizedBox(width: 12),

              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      songTitle ?? "N/A",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      artistName ?? "N/A",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Control buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      // Add previous track functionality
                      // MpdRemoteService.instance.client.previous();
                    },
                    icon: const Icon(
                      Icons.skip_previous,
                      color: Colors.white,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    onPressed: () {
                      // Add play/pause functionality
                      // MpdRemoteService.instance.client.pause();
                    },
                    icon: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    onPressed: () {
                      // Add next track functionality
                      // MpdRemoteService.instance.client.next();
                    },
                    icon: const Icon(
                      Icons.skip_next,
                      color: Colors.white,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('HOME', Icons.home, true),
          _buildNavItem('FOLDERS', Icons.folder_outlined, false),
          _buildNavItem('PLAYLISTS', Icons.playlist_play, false),
          _buildNavItem('TRACKS', Icons.music_note, false),
          _buildNavItem('ALBUMS', Icons.album, false),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.grey, size: 24),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings, color: Colors.grey, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? const Color(0xFFDC2626) : Colors.grey,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFFDC2626) : Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
