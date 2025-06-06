import 'dart:io';

import 'package:echo_mpd/utils/album_art_helper.dart';
import 'package:echo_mpd/utils/mpd_remote_service.dart';
import 'package:echo_mpd/widgets/album_art_placeholder.dart';
import 'package:flutter/material.dart';

class BottomIslandWidget extends StatefulWidget {
  final List<String> tabList;
  const BottomIslandWidget({super.key, required this.tabList});

  @override
  State<BottomIslandWidget> createState() => _BottomIslandWidgetState();
}

class _BottomIslandWidgetState extends State<BottomIslandWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _selectedIndex = 0;

  // Corner Radius
  static const double cornerRadiusEnd = 14;
  static const double cornerRadiusMiddle = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tabList.length, vsync: this);
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _centerTabInView(int index) {
    // Calculate the position to center the selected tab
    const double tabWidth = 90.0; // Approximate width of each tab
    // const double padding = 20.0;

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
  void onPlayPause() {}

  /// Action when the previous track button is pressed
  void onPrevious() {}

  /// Action when the next track button is pressed
  void onNext() {}

  /// Action when the settings button is pressed
  void onSettings() {}

  /// Action when the search button is pressed
  void onSearch() {}

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Music Player Control Section
          GestureDetector(
            onTapDown: (_) {
              _animationController.forward();
            },
            onTapUp: (_) {
              _animationController.reverse();
            },
            onTapCancel: () {
              _animationController.reverse();
            },
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => NewScreen()),
              // );
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
                    child: ValueListenableBuilder(
                      valueListenable: MpdRemoteService.instance.currentSong,
                      builder: (context, currentSong, child) {
                        // Get the current song information
                        String? songTitle = currentSong?.title?.join("");
                        String? album = currentSong?.album?.join("");
                        String? albumArtistName = currentSong?.albumArtist
                            ?.join("/");

                        return Row(
                          children: [
                            // Album _buildMusicPlayerart
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: (albumArtistName != null && album != null)
                                  ? FutureBuilder(
                                      future: getAlbumArtPath(
                                        albumArtistName,
                                        album,
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
                                    albumArtistName ?? "N/A",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
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

                                IconButton(
                                  onPressed: onPlayPause,
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
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          // spacing
          SizedBox(height: 3),
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
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.tabList.length,
                    itemBuilder: (context, index) {
                      bool isSelected = _selectedIndex == index;
                      return GestureDetector(
                        onTap: () {
                          _tabController.animateTo(index);
                          _centerTabInView(index);
                        },
                        behavior: HitTestBehavior.translucent,
                        child: Container(
                          height: double.maxFinite,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            widget.tabList[index],
                            style: TextStyle(
                              color: isSelected ? Colors.red : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
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
