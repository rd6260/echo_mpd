import 'dart:io';
import 'package:dart_mpd/dart_mpd.dart';
import 'package:echo_mpd/utils/album_art_helper.dart';
import 'package:echo_mpd/widgets/album_art_placeholder.dart';
import 'package:flutter/material.dart';

class PlaylistTile extends StatelessWidget {
  final MpdSong song;
  final VoidCallback onTap;
  final VoidCallback onMorePressed;
  final bool isPlaying;

  const PlaylistTile({
    super.key,
    required this.song,
    required this.onTap,
    required this.onMorePressed,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isPlaying ? const Color(0xFF2A2A2A) : Colors.transparent,
              border: isPlaying 
                  ? Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 1)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                children: [
                  // Album Art with playing indicator
                  Stack(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: const Color(0xFF3A3A3A),
                        ),
                        child: (song.album != null && song.albumArtist != null)
                            ? FutureBuilder(
                                future: getAlbumArtPath(song.albumArtist!.join("/"), song.album!.join("/")),
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
                      // Playing indicator overlay
                      if (isPlaying)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.black.withOpacity(0.6),
                            ),
                            child: Icon(
                              Icons.volume_up,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Song Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                song.title?.join("/") ?? "",
                                style: TextStyle(
                                  color: isPlaying ? Theme.of(context).primaryColor : Colors.white,
                                  fontSize: 16,
                                  fontWeight: isPlaying ? FontWeight.w500 : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Playing animation icon
                            if (isPlaying)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.graphic_eq,
                                  color: Theme.of(context).primaryColor,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist?.join("/") ?? "",
                          style: TextStyle(
                            color: isPlaying ? Theme.of(context).primaryColor.withOpacity(0.8) : Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Duration (if available)
                  if (song.duration != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        _formatDuration(song.duration!),
                        style: TextStyle(
                          color: isPlaying ? Theme.of(context).primaryColor.withOpacity(0.7) : Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  // More options button
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: isPlaying ? Theme.of(context).primaryColor.withOpacity(0.7) : Colors.white54,
                      size: 20,
                    ),
                    onPressed: onMorePressed,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }
}