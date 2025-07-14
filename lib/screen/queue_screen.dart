import 'package:dart_mpd/dart_mpd.dart';
import 'package:echo_mpd/service/mpd_remote_service.dart';
import 'package:echo_mpd/service/settings.dart';
import 'package:echo_mpd/widgets/playlist_tile.dart';
import 'package:flutter/material.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0.0);
  final double _stickyOffset = 60.0; // Height at which the bar becomes sticky

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollOffset.value = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: ValueListenableBuilder(
        valueListenable: MpdRemoteService.instance.currentPlaylist,
        builder: (context, value, child) {
          return _buildPlaylist(value);
        },
      ),
    );
  }

  /// When taped on a song
  ///
  /// It takes the index of the song and plays it
  onSongTap(int songIndex) {
    MpdRemoteService.instance.client.play(songIndex);
  }

  Widget _buildPlaylist(List<MpdSong> queue) {
    if (queue.isEmpty) {
      return const Center(
        child: Text(
          'No songs in playlist',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(), // Ensures smooth scrolling
          slivers: [
            // Add space for the title at the top
            SliverToBoxAdapter(
              child: Container(
                height: 120.0,
                color: Colors.black,
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.only(left: 20, bottom: 20),
                child: const Text(
                  'Playlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Add space for the floating control bar
            SliverToBoxAdapter(
              child: Container(
                height: 80.0, // Space for the control bar
                color: Colors.black,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final song = queue[index];
                return PlaylistTile(song: song, onTap: () => onSongTap(index));
              }, childCount: queue.length),
            ),
            // Add some bottom padding to prevent overlap with any bottom navigation
            const SliverPadding(padding: EdgeInsets.only(bottom: 200)),
          ],
        ),
        // Floating control bar that moves with scroll initially, then sticks
        ValueListenableBuilder<double>(
          valueListenable: _scrollOffset,
          builder: (context, scrollOffset, child) {
            // Calculate the bar position based on scroll offset
            double barTop = 140.0 - scrollOffset;
            if (barTop < _stickyOffset) {
              barTop = _stickyOffset;
            }

            return Positioned(
              top: barTop,
              left: 16.0,
              right: 16.0,
              child: Container(
                height: 60.0,
                decoration: BoxDecoration(
                  color: Colors.grey[900]?.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Icon(Icons.menu, color: Colors.white, size: 20),
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.only(right: 8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.shuffle,
                              color: Color(Settings.primaryColor),
                              size: 20,
                            ),
                            onPressed: () {
                              // Handle shuffle
                            },
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(Settings.primaryColor),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
