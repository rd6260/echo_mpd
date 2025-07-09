import 'package:echo_mpd/screen/lyrics_screen.dart';
import 'package:echo_mpd/service/mpd_remote_service.dart';
import 'package:echo_mpd/service/settings.dart';
import 'package:echo_mpd/widgets/album_art_widget.dart';
import 'package:echo_mpd/widgets/music_progress_slider_widget.dart';
import 'package:dart_mpd/dart_mpd.dart';
import 'package:echo_mpd/widgets/song_more_bottom_popup_sheet_widget.dart';
import 'package:flutter/material.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {

  /// Tracks if current song is marked as favourite
  final ValueNotifier<bool> isFavourite = ValueNotifier(false);

  /// update the [isFavourite] ValueNotifier
  void updateIsFavouriteValue(MpdSong? song) async {
    isFavourite.value = await _getIndexInFevourite(song) == null ? false : true;
  }

  /// Fetch the index of the song in the favourite playlist
  /// if the song is not present in the favourite playlist
  Future<int?> _getIndexInFevourite(MpdSong? song) async {
    int index = MpdRemoteService.instance.favoriteSongList.value.indexWhere((favSong) => favSong.file == song?.file);

    // if index is -1 then return null
    return index >= 0 ? index : null;
  }

  /// Handles favourite button press for a given [song].
  ///
  /// Provides full toggle functionality: if the song is already present in the
  /// `Favourites` playlist it will be removed, otherwise it will be added.
  Future<void> _onFavouritePressed(MpdSong? song) async {
    if (song == null) {
      debugPrint('No current song to toggle favourites');
      return;
    }

    try {
      final client = MpdRemoteService.instance.client;

      if (!isFavourite.value) {
        // Add to favourites if not already present.
        await client.playlistadd(Settings.defaultFavoritePlaylistName, song.file);
        isFavourite.value = true;
        debugPrint(
          'Added "${song.title?.join("") ?? "Unknown"}" to favourites',
        );
      } else {
        final int? index = await _getIndexInFevourite(song);

        if (index == null) {
          debugPrint('Song not found in favourites playlist');
          isFavourite.value = false;
          return;
        }

        // Remove the song at [index] from the playlist.
        await client.playlistdelete(Settings.defaultFavoritePlaylistName, MpdPosition(index));
        isFavourite.value = false;
        debugPrint(
          'Removed "${song.title?.join("") ?? "Unknown"}" from favourites',
        );
      }
    } catch (e) {
      debugPrint('Failed to update favourites: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favourites: $e'),
            backgroundColor: const Color(Settings.primaryColor),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    isFavourite.dispose();
    super.dispose();
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
              updateIsFavouriteValue(currentSong);
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
                          child: GestureDetector(
                            onTap: () {
                              if (currentSong == null) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LyricsScreen(),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AlbumArtWidget(song: currentSong),
                            ),
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
                                color: Color(Settings.primaryColor),
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
                            onPressed: () => _onFavouritePressed(currentSong),
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? const Color(Settings.primaryColor) : Colors.white,
                              size: 28,
                            ),
                          );
                        },
                      ),
                      // More options
                      IconButton(
                        onPressed: () {
                          if (currentSong == null) return;
                          showModalBottomSheet(
                            context: context,
                            builder: (context) =>
                                SongMoreBottomPopupSheetWidget(
                                  song: currentSong,
                                ),
                          );
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
                  ValueListenableBuilder<Duration?>(
                    valueListenable: MpdRemoteService.instance.elapsed,
                    builder: (context, elapsed, child) {
                      final totalDuration =
                          currentSong?.time?.toDouble() ?? 0.0;
                      final currentElapsed =
                          elapsed?.inSeconds.toDouble() ?? 0.0;

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
            color: isShuffled ? const Color(Settings.primaryColor) : Colors.grey,
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
              color: const Color(Settings.primaryColor),
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
            color: isRepeated ? const Color(Settings.primaryColor) : Colors.grey,
            size: 28,
          ),
        ),
      ],
    );
  }
}
