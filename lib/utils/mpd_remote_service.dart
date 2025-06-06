import 'package:dart_mpd/dart_mpd.dart';
import 'package:echo_mpd/types/playlist_item.dart';
import 'package:flutter/foundation.dart';

class MpdRemoteService {
  MpdRemoteService._();

  // Static instance created immediately
  static final MpdRemoteService _instance = MpdRemoteService._();
  static MpdRemoteService get instance => _instance;

  MpdClient? _client;
  bool _isInitialized = false;
  String? _host;
  int? _port;
  final ValueNotifier<MpdSong?> currentSong = ValueNotifier(null);
  final ValueNotifier<bool> isConnected = ValueNotifier(false);
  final ValueNotifier<List<PlaylistItem>> currentPlaylist = ValueNotifier([]);

  // Initialize method to be called from your starting screen
  Future<void> initialize({required String host, required int port}) async {
    if (_isInitialized) return; // Prevent multiple initializations

    // Store connection details
    _host = host;
    _port = port;

    try {
      // Initialize the client
      _client = MpdClient(
        connectionDetails: MpdConnectionDetails(host: host, port: port),
        // onConnect: () => debugPrint("DEV: Connection successful!"),
      );

      // Test connection and get current song
      currentSong.value = await _client!.currentsong();
      //
      isConnected.value = _client!.connection.isConnected;
      updateCurrentPlaylist();
      //
      _isInitialized = true;

      // Start the polling in background
      _startStatusPolling();

      debugPrint("DEV: MPD Service initialized successfully");
    } catch (e) {
      debugPrint("DEV: MPD Service initialization failed: $e");
      isConnected.value = false;
      rethrow; // Re-throw to handle in UI if needed
    }
  }

  void _startStatusPolling() {
    // Run polling in a separate isolate/background to avoid blocking UI
    Future.microtask(() => _mpdStatusPoll());
  }

  void _mpdStatusPoll() async {
    while (_isInitialized && _client != null) {
      try {
        Set<MpdSubsystem> idleResponse = await _client!.idle();

        for (var response in idleResponse) {
          debugPrint("DEV: mpd change | $response");

          switch (response) {
            case MpdSubsystem.player:
              // Update current song when player state changes
              currentSong.value = await _client!.currentsong();
              break;
            case MpdSubsystem.database:
              // Handle database changes
              break;
            case MpdSubsystem.update:
              // Handle update changes
              break;
            case MpdSubsystem.storedPlaylist:
              // Handle stored playlist changes
              break;
            case MpdSubsystem.playlist:
              updateCurrentPlaylist();
              break;
            case MpdSubsystem.mixer:
              // Handle mixer changes
              break;
            case MpdSubsystem.output:
              // Handle output changes
              break;
            case MpdSubsystem.options:
              // Handle options changes
              break;
            case MpdSubsystem.partition:
              // Handle partition changes
              break;
            case MpdSubsystem.sticker:
              // Handle sticker changes
              break;
            case MpdSubsystem.subscription:
              // Handle subscription changes
              break;
            case MpdSubsystem.message:
              // Handle message changes
              break;
            case MpdSubsystem.neighbor:
              // Handle neighbor changes
              break;
            case MpdSubsystem.mount:
              // Handle mount changes
              break;
          }
        }
      } catch (e) {
        debugPrint("DEV: MPD polling error: $e");
        isConnected.value = false;

        // Wait a bit before retrying
        await Future.delayed(Duration(seconds: 5));

        // Try to reconnect using stored connection details
        try {
          if (_host != null && _port != null) {
            await initialize(host: _host!, port: _port!);
          }
        } catch (reconnectError) {
          debugPrint("DEV: MPD reconnection failed: $reconnectError");
        }
      }
    }
  }

  // Getter for the client - ensures it's initialized
  MpdClient get client {
    if (!_isInitialized || _client == null) {
      throw StateError(
        'MpdRemoteService not initialized. Call initialize() first.',
      );
    }
    return _client!;
  }

  // Method to check if service is ready
  bool get isInitialized => _isInitialized;

  // Getters for connection details
  String? get host => _host;
  int? get port => _port;

  /// Update the current playlist (queue)
  void updateCurrentPlaylist() async {
    List<PlaylistItem> newPlaylist = [];
    List<MpdSong> queue = await _client!.playlistid();

    for (var song in queue) {
      newPlaylist.add(
        PlaylistItem(
          album: song.album?.join("/"),
          artist: song.artist?.join("/"),
          duration: song.duration,
          title: song.title?.join("/"),
        ),
      );
    }
    currentPlaylist.value = newPlaylist;
  }

  // Cleanup method (call this when app is disposed)
  void dispose() {
    _isInitialized = false;
    // _client?.disconnect();
    _client = null;
    currentSong.dispose();
    isConnected.dispose();
  }
}
