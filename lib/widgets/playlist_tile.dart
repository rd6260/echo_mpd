import 'dart:io';
import 'package:dart_mpd/dart_mpd.dart';
import 'package:echo_mpd/service/mpd_remote_service.dart';
import 'package:echo_mpd/service/settings.dart';
import 'package:echo_mpd/utils/album_art_helper.dart';
import 'package:echo_mpd/widgets/album_art_placeholder.dart';
import 'package:echo_mpd/widgets/conditional_value_listenable_builder.dart';
import 'package:echo_mpd/widgets/song_more_bottom_popup_sheet_widget.dart';
import 'package:flutter/material.dart';

class PlaylistTile extends StatefulWidget {
  final MpdSong song;
  final VoidCallback onTap;

  const PlaylistTile({super.key, required this.song, required this.onTap});

  @override
  State<PlaylistTile> createState() => _PlaylistTileState();
}

class _PlaylistTileState extends State<PlaylistTile> {
  bool isPlaying = false;

  bool isThisSongPlaying(MpdSong? currentSong) {
    String? currentFile = currentSong?.file;
    String thisFile = widget.song.file;

    return (thisFile == currentFile);
  }

  bool shouldRebuild(MpdSong? currentSong) {
    bool newState = isThisSongPlaying(currentSong);

    if (isPlaying == newState) {
      return false;
    } else {
      isPlaying = newState;
      return true;
    }
  }

  @override
  void initState() {
    super.initState();
    isPlaying = isThisSongPlaying(MpdRemoteService.instance.currentSong.value);
  }

  void onMorePressed() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SongMoreBottomPopupSheetWidget(song: widget.song),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConditionalValueListenableBuilder(
      valueListenable: MpdRemoteService.instance.currentSong,
      shouldRebuild: shouldRebuild,
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isPlaying
                      ? const Color(0xFF1A0F0F)
                      : Colors.transparent,
                  border: isPlaying
                      ? Border.all(
                          color: const Color(
                            Settings.primaryColor,
                          ).withValues(alpha: 0.4),
                          width: 1.5,
                        )
                      : null,
                  boxShadow: isPlaying
                      ? [
                          BoxShadow(
                            color: const Color(
                              Settings.primaryColor,
                            ).withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 8,
                  ),
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
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                          // Playing indicator overlay
                          if (isPlaying)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(
                                        Settings.primaryColor,
                                      ).withValues(alpha: 0.8),
                                      const Color(
                                        Settings.primaryColor,
                                      ).withValues(alpha: 0.6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 24,
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
                            Text(
                              widget.song.title?.join("/") ?? "",
                              style: TextStyle(
                                color: isPlaying
                                    ? const Color(Settings.primaryColor)
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: isPlaying
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // const SizedBox(height: 4),
                            Text(
                              widget.song.artist?.join("/") ?? "",
                              style: TextStyle(
                                color: isPlaying
                                    ? const Color(
                                        Settings.primaryColor,
                                      ).withValues(alpha: 0.9)
                                    : Colors.white70,
                                fontSize: 12,
                                fontWeight: isPlaying
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Duration (if available)
                      if (widget.song.duration != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            _formatDuration(widget.song.duration!),
                            style: TextStyle(
                              color: isPlaying
                                  ? const Color(
                                      Settings.primaryColor,
                                    ).withValues(alpha: 0.8)
                                  : Colors.white54,
                              fontSize: 12,
                              fontWeight: isPlaying
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      // More options button
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: isPlaying
                              ? const Color(
                                  Settings.primaryColor,
                                ).withValues(alpha: 0.8)
                              : Colors.white54,
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
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }
}
