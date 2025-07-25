import 'dart:io';

import 'package:echo_mpd/screen/player_screen.dart';
import 'package:echo_mpd/screen/settings_screen.dart';
import 'package:echo_mpd/service/settings.dart';
import 'package:echo_mpd/utils/album_art_helper.dart';
import 'package:echo_mpd/service/mpd_remote_service.dart';
import 'package:echo_mpd/widgets/album_art_placeholder.dart';
import 'package:flutter/material.dart';

class BottomIslandWidget extends StatefulWidget {
  final List<String> tabList;
  final ValueNotifier<int> currentIndexNotifier;
  final Function(int) onTabChanged;

  const BottomIslandWidget({
    super.key,
    required this.tabList,
    required this.currentIndexNotifier,
    required this.onTabChanged,
  });

  @override
  State<BottomIslandWidget> createState() => _BottomIslandWidgetState();
}

class _BottomIslandWidgetState extends State<BottomIslandWidget>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Corner Radius
  static const double cornerRadiusEnd = 14;
  static const double cornerRadiusMiddle = 3;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Listen to index changes and center the tab
    widget.currentIndexNotifier.addListener(_onIndexChanged);
  }

  void _onIndexChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerTabInView(widget.currentIndexNotifier.value);
    });
  }

  @override
  void dispose() {
    widget.currentIndexNotifier.removeListener(_onIndexChanged);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _centerTabInView(int index) {
    if (!_scrollController.hasClients) return;

    // Calculate the position to center the selected tab
    const double tabWidth = 90.0; // Approximate width of each tab

    // Get the screen width to calculate center position
    final screenWidth = MediaQuery.of(context).size.width;
    final targetPosition =
        (index * tabWidth) - (screenWidth / 2) + (tabWidth / 2);

    // Ensure we don't scroll beyond the bounds
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final clampedPosition = targetPosition.clamp(0.0, maxScrollExtent);

    _scrollController.animateTo(
      clampedPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Action when the play/pause track button is pressed
  void onPlayPause() {
    MpdRemoteService.instance.client.pause();
  }

  /// Action when the previous track button is pressed
  void onPrevious() {
    MpdRemoteService.instance.client.previous();
  }

  /// Action when the next track button is pressed
  void onNext() {
    MpdRemoteService.instance.client.next();
  }

  /// Action when the settings button is pressed
  void onSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );
  }

  /// Action when the search button is pressed
  void onSearch() {}

  /// Action when pressed on the music island
  onMusicIsland() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlayerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Music Player Control Section
          GestureDetector(
            onTap: onMusicIsland,
            onTapDown: (_) {
              _animationController.forward();
            },
            onTapUp: (_) {
              _animationController.reverse();
            },
            onTapCancel: () {
              _animationController.reverse();
            },
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(cornerRadiusEnd),
                        topRight: Radius.circular(cornerRadiusEnd),
                        bottomLeft: Radius.circular(cornerRadiusMiddle),
                        bottomRight: Radius.circular(cornerRadiusMiddle),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Album art, title and artist section
                        Expanded(
                          child: ValueListenableBuilder(
                            valueListenable:
                                MpdRemoteService.instance.currentSong,
                            builder: (context, currentSong, child) {
                              // Get the current song information
                              String? songTitle = currentSong?.title?.join("");
                              String? album = currentSong?.album?.join("");
                              String? albumArtistName = currentSong?.albumArtist
                                  ?.join("/");

                              return Row(
                                children: [
                                  // Album art
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child:
                                        (albumArtistName != null &&
                                            album != null)
                                        ? FutureBuilder(
                                            future: getAlbumArtPath(
                                              albumArtistName,
                                              album,
                                            ),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: Image.file(
                                                    File(snapshot.data!),
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) =>
                                                            const AlbumArtPlaceholder(),
                                                  ),
                                                );
                                              }
                                              return const AlbumArtPlaceholder();
                                            },
                                          )
                                        : const AlbumArtPlaceholder(),
                                  ),

                                  const SizedBox(width: 12),

                                  // Song info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          songTitle ?? "N/A",
                                          overflow: TextOverflow.fade,
                                          softWrap: false,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          albumArtistName ?? "N/A",
                                          overflow: TextOverflow.fade,
                                          softWrap: false,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // Control buttons (Previous, Play/Pause, Next)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: onPrevious,
                              icon: const Icon(
                                Icons.skip_previous,
                                color: Colors.white,
                                size: 24,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),

                            const SizedBox(width: 8),

                            ValueListenableBuilder(
                              valueListenable:
                                  MpdRemoteService.instance.isPlaying,
                              builder: (context, isPlaying, child) {
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: onPlayPause,
                                    borderRadius: BorderRadius.circular(32),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Icon(
                                        isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: const Color(
                                          Settings.primaryColor,
                                        ),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(width: 8),

                            IconButton(
                              onPressed: onNext,
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
                  ),
                );
              },
            ),
          ),
          // spacing
          const SizedBox(height: 3),
          // Bottom Navigation Section
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(cornerRadiusMiddle),
                topRight: Radius.circular(cornerRadiusMiddle),
                bottomLeft: Radius.circular(cornerRadiusEnd),
                bottomRight: Radius.circular(cornerRadiusEnd),
              ),
            ),
            child: Row(
              children: [
                // Scrollable text buttons
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: widget.currentIndexNotifier,
                    builder: (context, selectedIndex, child) {
                      return ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.tabList.length,
                        itemBuilder: (context, index) {
                          bool isSelected = selectedIndex == index;
                          return GestureDetector(
                            onTap: () {
                              widget.onTabChanged(index);
                              _centerTabInView(index);
                            },
                            behavior: HitTestBehavior.translucent,
                            child: Container(
                              height: double.maxFinite,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                widget.tabList[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(Settings.primaryColor)
                                      : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Fixed icon buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: onSearch,
                        icon: const Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        onPressed: onSettings,
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
