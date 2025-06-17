import 'package:echo_mpd/service/lyrics_service.dart';
import 'package:echo_mpd/service/mpd_remote_service.dart';
import 'package:flutter/material.dart';

class LyricsView extends StatefulWidget {
  const LyricsView({super.key});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView>
    with SingleTickerProviderStateMixin {
  final LyricsService _lyricsService = LyricsService();
  final ScrollController _scrollController = ScrollController();

  LyricsResult? _lyricsResult;
  bool _isLoading = true;
  int _currentLineIndex = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fetchLyrics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchLyrics() async {
    try {
      var currentSong = MpdRemoteService.instance.currentSong.value;
      final result = await _lyricsService.fetchLyrics(
        artist: currentSong?.albumArtist?[0],
        title: currentSong?.title?[0],
      );
      setState(() {
        _lyricsResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _getCurrentLineIndex(Duration? elapsed) {
    if (_lyricsResult == null || elapsed == null) return 0;

    final elapsedMs = elapsed.inMilliseconds;
    int currentIndex = 0;

    for (int i = 0; i < _lyricsResult!.lines.length; i++) {
      if (elapsedMs >= _lyricsResult!.lines[i].startTimeMs) {
        currentIndex = i;
      } else {
        break;
      }
    }

    return currentIndex;
  }

  void _scrollToCurrentLine(int lineIndex) {
    if (_scrollController.hasClients && _lyricsResult != null) {
      const itemHeight = 60.0; // Approximate height of each lyric line
      final targetOffset =
          lineIndex * itemHeight -
          (_scrollController.position.viewportDimension / 2) +
          (itemHeight / 2);

      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: ValueListenableBuilder<Duration?>(
        valueListenable: MpdRemoteService.instance.elapsed,
        builder: (context, elapsedDuration, child) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_lyricsResult == null || _lyricsResult!.lines.isEmpty) {
            return const Center(
              child: Text(
                'No lyrics available',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          final newCurrentLineIndex = _getCurrentLineIndex(elapsedDuration);

          // Trigger animation and scroll when line changes
          if (newCurrentLineIndex != _currentLineIndex) {
            _currentLineIndex = newCurrentLineIndex;
            _animationController.forward().then((_) {
              _animationController.reverse();
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToCurrentLine(_currentLineIndex);
            });
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 100),
            itemCount: _lyricsResult!.lines.length,
            itemBuilder: (context, index) {
              final line = _lyricsResult!.lines[index];
              final isCurrentLine = index == _currentLineIndex;

              return AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        fontSize: isCurrentLine ? 20 : 16,
                        fontWeight: isCurrentLine
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrentLine
                            ? Colors.white.withValues(
                                alpha: _fadeAnimation.value,
                              )
                            : Colors.white70,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        transform: Matrix4.identity()
                          ..scale(isCurrentLine ? 1.05 : 1.0),
                        child: Text(
                          line.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            shadows: isCurrentLine
                                ? [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
