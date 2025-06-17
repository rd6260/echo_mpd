import 'package:echo_mpd/service/lyrics_service.dart';
import 'package:flutter/material.dart';
import 'package:dart_mpd/dart_mpd.dart';

// Import your lyrics service
// import 'lyrics_service.dart';

class LyricsScreen extends StatefulWidget {
  final MpdSong song;

  const LyricsScreen({
    super.key,
    required this.song,
  });

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen>
    with TickerProviderStateMixin {
  final LyricsService _lyricsService = LyricsService();
  final ScrollController _scrollController = ScrollController();
  
  LyricsResult? _lyricsResult;
  bool _isLoading = true;
  String? _error;
  
  int _currentLineIndex = 0;
  double _currentProgress = 0.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchLyrics();
    _setupProgressTimer();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _setupProgressTimer() {
    // Simulate progress updates - you'll replace this with actual MPD integration
    Stream.periodic(const Duration(milliseconds: 100), (count) {
      return count * 100; // milliseconds
    }).listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = Duration(milliseconds: position);
          _currentProgress = _totalDuration.inMilliseconds > 0
              ? position / _totalDuration.inMilliseconds
              : 0.0;
        });
        _updateCurrentLine();
      }
    });
  }

  Future<void> _fetchLyrics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await _lyricsService.fetchLyrics(
        artist: widget.song.artist?.join("/") ?? 'Unknown Artist',
        title: widget.song.title?.join("/") ?? 'Unknown Title',
        album: widget.song.album?.join("/") ?? '',
        synced: true,
      );

      if (mounted) {
        setState(() {
          _lyricsResult = result;
          _isLoading = false;
          _totalDuration = Duration(seconds: widget.song.time?.toInt() ?? 180);
        });
        
        if (result != null) {
          _fadeController.forward();
          _slideController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _updateCurrentLine() {
    if (_lyricsResult == null || _lyricsResult!.lines.isEmpty) return;

    final currentTimeMs = _currentPosition.inMilliseconds;
    int newLineIndex = _currentLineIndex;

    // Find the current line based on timestamp
    for (int i = 0; i < _lyricsResult!.lines.length; i++) {
      if (i < _lyricsResult!.lines.length - 1) {
        if (currentTimeMs >= _lyricsResult!.lines[i].startTimeMs &&
            currentTimeMs < _lyricsResult!.lines[i + 1].startTimeMs) {
          newLineIndex = i;
          break;
        }
      } else if (currentTimeMs >= _lyricsResult!.lines[i].startTimeMs) {
        newLineIndex = i;
      }
    }

    if (newLineIndex != _currentLineIndex) {
      setState(() {
        _currentLineIndex = newLineIndex;
      });
      _scrollToCurrentLine();
    }
  }

  void _scrollToCurrentLine() {
    if (_scrollController.hasClients && _lyricsResult != null) {
      const double lineHeight = 60.0;
      const double padding = 20.0;
      
      final targetOffset = (_currentLineIndex * lineHeight) - 
          (MediaQuery.of(context).size.height * 0.4);
      
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildAlbumArt() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.grey[800],
          child: const Icon(
            Icons.music_note,
            size: 80,
            color: Colors.white54,
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo() {
    return Column(
      children: [
        Text(
          widget.song.title?.join("/") ?? 'Unknown Title',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          widget.song.artist?.join("/") ?? 'Unknown Artist',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.song.album != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.song.album?.join("/") ?? "",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildLyricsView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load lyrics',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchLyrics,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_lyricsResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 48,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No lyrics found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      );
    }

    if (_lyricsResult!.isInstrumental) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 48,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              '♪ Instrumental ♪',
              style: TextStyle(
                fontSize: 24,
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          itemCount: _lyricsResult!.lines.length,
          itemBuilder: (context, index) {
            final line = _lyricsResult!.lines[index];
            final isCurrentLine = index == _currentLineIndex;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                line.text,
                style: TextStyle(
                  fontSize: isCurrentLine ? 20 : 18,
                  fontWeight: isCurrentLine ? FontWeight.w600 : FontWeight.w400,
                  color: isCurrentLine 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.5),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressSlider() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _currentProgress.clamp(0.0, 1.0),
                  onChanged: (value) {
                    // Handle seek - you'll implement this
                  },
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withOpacity(0.3),
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 40,
            color: Colors.white,
            onPressed: () {
              // Handle previous - you'll implement this
            },
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.play_arrow), // You'll toggle this with pause
              iconSize: 40,
              color: Colors.black,
              onPressed: () {
                // Handle play/pause - you'll implement this
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 40,
            color: Colors.white,
            onPressed: () {
              // Handle next - you'll implement this
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _lyricsService.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade900,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with album art and song info
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildAlbumArt(),
                    const SizedBox(height: 24),
                    _buildSongInfo(),
                  ],
                ),
              ),
              
              // Lyrics view
              Expanded(
                child: _buildLyricsView(),
              ),
              
              // Progress slider
              _buildProgressSlider(),
              const SizedBox(height: 16),
              
              // Playback controls
              _buildControls(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}