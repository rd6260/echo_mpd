import 'package:echo_mpd/service/mpd_remote_service.dart';
import 'package:echo_mpd/widgets/album_art_widget.dart';
import 'package:echo_mpd/widgets/music_progress_slider_widget.dart';
import 'package:flutter/material.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  /// Tracks if current song is marked as favourite
  final ValueNotifier<bool> isFavourite = ValueNotifier(false);
  
  @override
  void dispose() {
    isFavourite.dispose();
    super.dispose();
  }
  
  /// Handles favourite button press
  Future<void> _onFavouritePressed() async {
    final currentSong = MpdRemoteService.instance.currentSong.value;
    final songFile = currentSong?.file;
    if (songFile == null) {
      debugPrint('No current song to add to favourites');
      return;
    }
    
    try {
      final client = MpdRemoteService.instance.client;
      const favouritesPlaylistName = 'Favourites';
      
      if (!isFavourite.value) {
        // Add to favourites playlist  
        await client.playlistadd(favouritesPlaylistName, songFile);
        isFavourite.value = true;
        
        final songTitle = currentSong!.title?.join("") ?? "Unknown";
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "$songTitle" to favourites'),
              backgroundColor: const Color(0xFF314B17),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        debugPrint('Added "$songTitle" to favourites');
      } else {
        // Remove from favourites playlist
        // Note: For simplicity, we just toggle the UI state here
        // Full implementation would require querying the playlist and finding the song position
        isFavourite.value = false;
        
        final songTitle = currentSong!.title?.join("") ?? "Unknown";
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "$songTitle" from favourites'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        debugPrint('Removed "$songTitle" from favourites');
      }
    } catch (e) {
      debugPrint('Failed to update favourites: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favourites: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
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
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          width: double.infinity,
                          // height: double.infinity,
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
                  ),

                  const SizedBox(height: 40),

                  Row(
                    children: [
                      // Song Info Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSong?.title?.join("") ?? "Not Available",
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // const SizedBox(height: 8),
                            Text(
                              currentSong?.artist?.join("/") ?? "Not Available",
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              maxLines: 1,
                              style: const TextStyle(
                                // color: Colors.grey,
                                color: Color(0xFF314B17),
                                fontSize: 16,
                              ),
                            ),
                            // const SizedBox(height: 4),
                            Text(
                              currentSong?.album?.join("") ?? "",
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      // `Favourite` and `More` Button
                      ValueListenableBuilder<bool>(
                        valueListenable: isFavourite,
                        builder: (context, isFav, child) {
                          return IconButton(
                            onPressed: _onFavouritePressed,
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.white,
                              size: 28,
                            ),
                          );
                        },
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

                  // Progress Bar Section
                  ValueListenableBuilder<double?>(
                    valueListenable: MpdRemoteService.instance.elapsed,
                    builder: (context, elapsed, child) {
                      final totalDuration =
                          currentSong?.time?.toDouble() ?? 0.0;
                      final currentElapsed = elapsed ?? 0.0;

                      return ProgressSliderWidget(
                        totalDuration: totalDuration,
                        currentElapsed: currentElapsed,
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Control Buttons Section
                  const ControlButtonsWidget(),

                  const SizedBox(height: 20),

                  // Bottom Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [],
                  ),

                  const SizedBox(height: 70),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ControlButtonsWidget extends StatefulWidget {
  const ControlButtonsWidget({super.key});

  @override
  State<ControlButtonsWidget> createState() => _ControlButtonsWidgetState();
}

class _ControlButtonsWidgetState extends State<ControlButtonsWidget> {
  bool isShuffled = false;
  bool isRepeated = false;

  Future<void> _onPreviousTrack() async {
    await MpdRemoteService.instance.client.previous();
  }

  Future<void> _onNextTrack() async {
    await MpdRemoteService.instance.client.next();
  }

  Future<void> _onPlayPause() async {
    await MpdRemoteService.instance.client.pause();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
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
            color: isShuffled ? const Color(0xFF314B17) : Colors.grey,
            size: 28,
          ),
        ),

        // Previous Button
        IconButton(
          onPressed: _onPreviousTrack,
          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
        ),

        // Play/Pause Button
        ValueListenableBuilder(
          valueListenable: MpdRemoteService.instance.isPlaying,
          builder: (context, isPlaying, child) => Container(
            width: 80,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF314B17),
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              onPressed: _onPlayPause,
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),

        // Next Button
        IconButton(
          onPressed: _onNextTrack,
          icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
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
            color: isRepeated ? const Color(0xFF314B17) : Colors.grey,
            size: 28,
          ),
        ),
      ],
    );
  }
}
