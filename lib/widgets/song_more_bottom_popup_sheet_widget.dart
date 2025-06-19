import 'dart:io';

import 'package:dart_mpd/dart_mpd.dart';
import 'package:echo_mpd/utils/album_art_helper.dart';
import 'package:echo_mpd/widgets/album_art_placeholder.dart';
import 'package:flutter/material.dart';

class SongMoreBottomPopupSheetWidget extends StatefulWidget {
  final MpdSong song;
  const SongMoreBottomPopupSheetWidget({super.key, required this.song});

  @override
  State<SongMoreBottomPopupSheetWidget> createState() =>
      _SongMoreBottomPopupSheetWidgetState();
}

class _SongMoreBottomPopupSheetWidgetState
    extends State<SongMoreBottomPopupSheetWidget> {
  /// for formating Last Modified DateTime
  String _formatDate(DateTime? date) {
    if (date == null) return "";
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// format time for runtime of the song
  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D0D),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF444444),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Song info section
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Album art
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF2A2A2A),
                    ),
                    child: Stack(
                      children: [
                        // Album Art picture
                        Container(
                          height: double.infinity,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: const Color(0xFF3A3A3A),
                          ),
                          child:
                              (widget.song.album != null &&
                                  widget.song.albumArtist != null)
                              ? FutureBuilder(
                                  future: getAlbumArtPath(
                                    widget.song.albumArtist!.join("/"),
                                    widget.song.album!.join("/"),
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.file(
                                          File(snapshot.data!),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  AlbumArtPlaceholder(),
                                        ),
                                      );
                                    }
                                    return AlbumArtPlaceholder();
                                  },
                                )
                              : AlbumArtPlaceholder(),
                        ),
                        // Heart icon in top right
                        Positioned(
                          top: 1,
                          right: 1,
                          child: Container(
                            padding: EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF0D0D0D).withValues(alpha: 0.85),
                            ),
                            child: Icon(
                              Icons.favorite_border,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Song details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // artist text
                        Text(
                          widget.song.artist?.join("/") ?? "Not Available",
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // title text
                        Text(
                          widget.song.title?.join("/") ?? "Not Available",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // album text
                        Text(
                          widget.song.album?.join("/") ?? "Not Available",
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Audio info
                        Row(
                          children: [
                            const Icon(
                              Icons.audiotrack,
                              color: Color(0xFF888888),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(widget.song.time?.toDouble() ?? 0),
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // File info section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Divider
                  Container(height: 1, color: const Color(0xFF262626)),
                  const SizedBox(height: 16),

                  // File details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BITRATE',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'N/A',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'SIZE',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'N/A',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SAMPLE RATE',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'N/A',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'LAST MODIFIED',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(widget.song.lastModified),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // File path
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FILE PATH',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.song.file,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Divider
                      const SizedBox(height: 16),
                      Container(height: 1, color: const Color(0xFF262626)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons with exact styling from image
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // First row - Add to Playlist and Add to Queue
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoundedButton(
                          icon: Icons.playlist_add,
                          title: 'Add to Playlist',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRoundedButton(
                          icon: Icons.queue_music,
                          title: 'Add to Queue',
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Divider
                  Container(height: 1, color: const Color(0xFF262626)),
                  const SizedBox(height: 16),

                  // Second row - Artist and Album
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoundedButton(
                          icon: Icons.person_outline,
                          title: 'Artist',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRoundedButton(
                          icon: Icons.album_outlined,
                          title: 'Album',
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),

                  // Bottom padding for safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundedButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C1E),
          borderRadius: BorderRadius.circular(12),
          // border: Border.all(color: const Color(0xFF333333), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
