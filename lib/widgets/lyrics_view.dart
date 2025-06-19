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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
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
      final screenHeight = MediaQuery.of(context).size.height;
      const lineHeight = 50.0;
      final targetOffset =
          (lineIndex * lineHeight) - (screenHeight / 2) + (lineHeight / 2);

      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: ValueListenableBuilder<Duration?>(
        valueListenable: MpdRemoteService.instance.elapsed,
        builder: (context, elapsedDuration, child) {
          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white54,
              ),
            );
          }

          if (_lyricsResult == null || _lyricsResult!.lines.isEmpty) {
            return const Center(
              child: Text(
                'No lyrics available',
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
            );
          }

          final newCurrentLineIndex = _getCurrentLineIndex(elapsedDuration);

          if (newCurrentLineIndex != _currentLineIndex) {
            _currentLineIndex = newCurrentLineIndex;
            _animationController.forward().then((_) {
              _animationController.reset();
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToCurrentLine(_currentLineIndex);
            });
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: _lyricsResult!.lines.length,
            itemBuilder: (context, index) {
              final line = _lyricsResult!.lines[index];
              final isCurrentLine = index == _currentLineIndex;
              final isPastLine = index < _currentLineIndex;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 50,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: isCurrentLine ? 22 : 16,
                    fontWeight: isCurrentLine
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: _getLineColor(isCurrentLine, isPastLine),
                    height: 1.4,
                    shadows: isCurrentLine
                        ? [
                            const Shadow(
                              blurRadius: 8,
                              color: Colors.black54,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : [],
                  ),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: isCurrentLine ? 1.0 : 0.95,
                    child: Text(
                      line.text,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getLineColor(bool isCurrentLine, bool isPastLine) {
    if (isCurrentLine) return Colors.greenAccent.shade100;
    if (isPastLine) return Colors.white70;
    return Colors.white38;
  }
}
