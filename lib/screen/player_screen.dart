import 'package:echo_mpd/utils/mpd_remote_service.dart';
import 'package:echo_mpd/widgets/album_art_widget.dart';
import 'package:flutter/material.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool isPlaying = false;
  double currentPosition = 1.26;
  double totalDuration = 2.58;
  bool isShuffled = false;
  bool isRepeated = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // title: Text("Track", style: TextStyle(color: Colors.white)),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: ValueListenableBuilder(
            valueListenable: MpdRemoteService.instance.currentSong,
            builder: (context, currentSong, child) {
              return Column(
                children: [
                  // Top spacing
                  const SizedBox(height: 40),

                  // Album Art Section
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AlbumArtWidget(song: currentSong),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Song Info Section
                  Column(
                    children: [
                      Text(
                        currentSong?.title?.join("") ?? "N/A",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentSong?.artist?.join("/") ?? "",
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentSong?.album?.join("") ?? "",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Progress Bar Section
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFFE91E63),
                          inactiveTrackColor: Colors.grey[800],
                          thumbColor: const Color(0xFFE91E63),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16,
                          ),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value:
                              currentSong?.duration?.inSeconds.toDouble() ??
                              currentPosition,
                          min: 0,
                          max: currentSong?.time?.toDouble() ?? totalDuration,
                          onChanged: (value) {
                            setState(() {
                              currentPosition = value;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Show
                            Text(
                              _formatTime(
                                currentSong?.time?.toDouble() ??
                                    currentPosition,
                              ),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _formatTime(
                                currentSong?.time?.toDouble() ?? totalDuration,
                              ),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Control Buttons Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Shuffle Button
                      IconButton(
                        onPressed: () {
                          setState(() {
                            isShuffled = !isShuffled;
                          });
                        },
                        icon: Icon(
                          Icons.shuffle,
                          color: isShuffled
                              ? const Color(0xFFE91E63)
                              : Colors.grey,
                          size: 28,
                        ),
                      ),

                      // Previous Button
                      IconButton(
                        onPressed: () {
                          // Handle previous track
                        },
                        icon: const Icon(
                          Icons.skip_previous,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),

                      // Play/Pause Button
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE91E63),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              isPlaying = !isPlaying;
                            });
                          },
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),

                      // Next Button
                      IconButton(
                        onPressed: () {
                          // Handle next track
                        },
                        icon: const Icon(
                          Icons.skip_next,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),

                      // Repeat Button
                      IconButton(
                        onPressed: () {
                          setState(() {
                            isRepeated = !isRepeated;
                          });
                        },
                        icon: Icon(
                          Icons.repeat,
                          color: isRepeated
                              ? const Color(0xFFE91E63)
                              : Colors.grey,
                          size: 28,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Bottom Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          // Handle favorite
                        },
                        icon: const Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Handle more options
                        },
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
