import 'package:flutter/material.dart';

class SongMoreBottomPopupSheetWidget extends StatelessWidget {
  const SongMoreBottomPopupSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Add to Playlist option
          _buildOptionTile(
            icon: Icons.playlist_add,
            title: 'Add to Playlist',
            onTap: () {},
          ),
          
          // Add to Queue option
          _buildOptionTile(
            icon: Icons.queue_music,
            title: 'Add to Queue',
            onTap: () {},
          ),
          
          const SizedBox(height: 32),
          
          // Artist option
          _buildOptionTile(
            icon: Icons.person,
            title: 'Artist',
            onTap: () {},
          ),
          
          // Album option
          _buildOptionTile(
            icon: Icons.album,
            title: 'Album',
            onTap: () {},
          ),
          
          const SizedBox(height: 32),
          
          // Playlist option
          _buildOptionTile(
            icon: Icons.playlist_play,
            title: 'Playlist',
            onTap: () {},
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}