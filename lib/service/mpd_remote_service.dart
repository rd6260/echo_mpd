import 'dart:async';
import 'package:dart_mpd/dart_mpd.dart';
import 'package:flutter/foundation.dart';

/// A singleton service for managing MPD (Music Player Daemon) connections and operations.
///
/// This service provides:
/// - Connection management with automatic reconnection
/// - Real-time status monitoring via MPD's idle command
/// - Current song and playlist state management
/// - Thread-safe operations with proper error handling
///
/// Usage:
/// ```dart
/// // Initialize the service
/// await MpdRemoteService.instance.initialize(host: '192.168.1.100', port: 6600);
///
/// // Listen to current song changes
/// MpdRemoteService.instance.currentSong.addListener(() {
///   final song = MpdRemoteService.instance.currentSong.value;
///   print('Now playing: ${song?.title}');
/// });
///
/// // Use MPD commands
/// await MpdRemoteService.instance.client.play();
/// ```
class MpdRemoteService {
  // ==========================================
  // SINGLETON PATTERN
  // ==========================================
  
  MpdRemoteService._();
  static final MpdRemoteService _instance = MpdRemoteService._();
  static MpdRemoteService get instance => _instance;

  // ==========================================
  // PRIVATE FIELDS
  // ==========================================
  
  // MPD Connection
  MpdClient? _client;
  MpdClient? _statusClient;
  String? _host;
  int? _port;
  
  // State Management
  bool _isInitialized = false;
  bool _isPolling = false;
  Timer? _elapsedTimer;

  // ==========================================
  // PUBLIC NOTIFIERS
  // ==========================================
  
  /// Current song being played (null when no song is playing or disconnected)
  final ValueNotifier<MpdSong?> currentSong = ValueNotifier(null);
  
  /// Connection status to MPD server
  final ValueNotifier<bool> isConnected = ValueNotifier(false);
  
  /// Player state (playing/paused)
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  
  /// Current playlist (queue) content
  final ValueNotifier<List<MpdSong>> currentPlaylist = ValueNotifier([]);
  
  /// Elapsed time of current song in seconds
  final ValueNotifier<double?> elapsed = ValueNotifier(null);

  // ==========================================
  // PUBLIC API - INITIALIZATION
  // ==========================================

  /// Initializes the MPD service with the specified connection details
  ///
  /// [host] - The MPD server hostname or IP address
  /// [port] - The MPD server port (typically 6600)
  ///
  /// Throws [StateError] if already initialized
  /// Throws [MpdException] or [SocketException] on connection failure
  Future<void> initialize({required String host, required int port}) async {
    if (_isInitialized) {
      throw StateError('MpdRemoteService is already initialized');
    }

    _host = host;
    _port = port;

    try {
      await _createClients(host, port);
      await _initializeState();
      _isInitialized = true;
      _startStatusPolling();

      debugPrint('MPD Service initialized successfully ($host:$port)');
    } catch (e) {
      debugPrint('MPD Service initialization failed: $e');
      isConnected.value = false;
      _cleanup();
      rethrow;
    }
  }

  /// Reinitializes the service with the same connection details
  ///
  /// Useful for recovering from connection issues or resetting service state
  /// Throws [StateError] if the service was never initialized
  Future<void> reconnect() async {
    if (_host == null || _port == null) {
      throw StateError('Cannot reconnect: service was never initialized');
    }

    dispose();
    await initialize(host: _host!, port: _port!);
  }

  /// Disposes the service and cleans up all resources
  ///
  /// After calling this method, you need to call [initialize] again to use the service.
  /// This should be called when the app is disposed or when resetting the service.
  void dispose() {
    _isInitialized = false;
    _cleanup();

    // Dispose ValueNotifiers to prevent memory leaks
    currentSong.dispose();
    isConnected.dispose();
    isPlaying.dispose();
    currentPlaylist.dispose();
    elapsed.dispose();

    debugPrint('MPD Service disposed');
  }

  // ==========================================
  // PUBLIC API - CLIENT ACCESS
  // ==========================================

  /// Gets the main MPD client for sending commands
  ///
  /// Throws [StateError] if the service is not initialized
  MpdClient get client {
    if (!_isInitialized || _client == null) {
      throw StateError('MpdRemoteService not initialized. Call initialize() first.');
    }
    return _client!;
  }

  // ==========================================
  // PUBLIC API - GETTERS
  // ==========================================

  /// Returns whether the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Returns the current MPD server hostname
  String? get host => _host;

  /// Returns the current MPD server port
  int? get port => _port;

  // ==========================================
  // PUBLIC API - PLAYBACK CONTROL
  // ==========================================

  /// Seeks to a specific position in the current song
  ///
  /// [position] - The position to seek to in seconds
  Future<void> seekToPosition(double position) async {
    if (_client == null) {
      throw StateError('MpdRemoteService not initialized');
    }

    try {
      await _client!.seekcur(position.toString());
      elapsed.value = position; // Immediate UI feedback
      debugPrint('Seeked to position: ${position.toStringAsFixed(1)}s');
    } catch (e) {
      debugPrint('Failed to seek to position $position: $e');
      rethrow;
    }
  }

  /// Seeks by a relative amount from the current position
  ///
  /// [offset] - The offset in seconds (positive for forward, negative for backward)
  Future<void> seekRelative(double offset) async {
    if (_client == null) {
      throw StateError('MpdRemoteService not initialized');
    }

    try {
      final currentElapsed = elapsed.value ?? 0.0;
      final newPosition = (currentElapsed + offset).clamp(0.0, double.maxFinite);
      await seekToPosition(newPosition);
    } catch (e) {
      debugPrint('Failed to seek by relative offset $offset: $e');
      rethrow;
    }
  }

  // ==========================================
  // PUBLIC API - MANUAL REFRESH
  // ==========================================

  /// Forces an update of the current playlist
  ///
  /// Useful when you want to refresh without waiting for automatic updates
  Future<void> refreshPlaylist() async {
    await _updateCurrentPlaylist();
  }

  /// Forces an update of the current song
  ///
  /// Useful when you want to refresh without waiting for automatic updates
  Future<void> refreshCurrentSong() async {
    await _updateCurrentSong();
  }

  /// Forces an update of the player status including elapsed time
  ///
  /// Useful when you want to refresh without waiting for automatic updates
  Future<void> refreshPlayerStatus() async {
    await _updatePlayerStatus();
  }

  // ==========================================
  // PRIVATE - INITIALIZATION HELPERS
  // ==========================================

  /// Creates the MPD client instances for main operations and status polling
  Future<void> _createClients(String host, int port) async {
    final connectionDetails = MpdConnectionDetails(host: host, port: port);
    _client = MpdClient(connectionDetails: connectionDetails);
    _statusClient = MpdClient(connectionDetails: connectionDetails);
  }

  /// Initializes the service state by fetching current data from MPD
  Future<void> _initializeState() async {
    if (_client == null) return;

    currentSong.value = await _client!.currentsong();
    isConnected.value = _client!.connection.isConnected;
    await _updatePlayerStatus();
    await _updateCurrentPlaylist();
  }

  // ==========================================
  // PRIVATE - STATUS POLLING
  // ==========================================

  /// Starts the background status polling using MPD's idle command
  void _startStatusPolling() {
    if (_isPolling) return;
    
    _isPolling = true;
    Future.microtask(_statusPollingLoop);
  }

  /// Main polling loop that listens for MPD subsystem changes
  Future<void> _statusPollingLoop() async {
    while (_isInitialized && _statusClient != null && _isPolling) {
      try {
        final changes = await _statusClient!.idle();
        
        if (!_isInitialized || !_isPolling) break;
        
        await _handleSubsystemChanges(changes);
      } catch (e) {
        debugPrint('MPD polling error: $e');
        isConnected.value = false;
        await _attemptReconnection();
      }
    }
  }

  /// Handles changes in MPD subsystems and updates corresponding state
  Future<void> _handleSubsystemChanges(Set<MpdSubsystem> changes) async {
    for (final change in changes) {
      debugPrint('MPD subsystem changed: $change');

      switch (change) {
        case MpdSubsystem.player:
          await _updateCurrentSong();
          await _updatePlayerStatus();
          break;

        case MpdSubsystem.playlist:
          await _updateCurrentPlaylist();
          break;

        case MpdSubsystem.database:
          debugPrint('MPD database updated');
          break;

        case MpdSubsystem.mixer:
          debugPrint('MPD mixer settings changed');
          break;

        case MpdSubsystem.output:
          debugPrint('MPD output configuration changed');
          break;

        case MpdSubsystem.options:
          debugPrint('MPD playback options changed');
          break;

        case MpdSubsystem.update:
        case MpdSubsystem.storedPlaylist:
        case MpdSubsystem.partition:
        case MpdSubsystem.sticker:
        case MpdSubsystem.subscription:
        case MpdSubsystem.message:
        case MpdSubsystem.neighbor:
        case MpdSubsystem.mount:
          debugPrint('MPD subsystem $change changed (not handled)');
          break;
      }
    }
  }

  // ==========================================
  // PRIVATE - STATE UPDATES
  // ==========================================

  /// Updates the current song information from MPD
  Future<void> _updateCurrentSong() async {
    if (_client == null) return;

    try {
      currentSong.value = await _client!.currentsong();
    } catch (e) {
      debugPrint('Failed to update current song: $e');
    }
  }

  /// Updates the current playlist (queue) information from MPD
  Future<void> _updateCurrentPlaylist() async {
    if (_client == null) return;

    try {
      final queue = await _client!.playlistid();
      currentPlaylist.value = queue;
    } catch (e) {
      debugPrint('Failed to update current playlist: $e');
    }
  }

  /// Updates player status (play/pause state, elapsed time) and manages elapsed timer
  Future<void> _updatePlayerStatus() async {
    final serverStatus = await _client!.status();
    final wasPlaying = isPlaying.value;
    
    isPlaying.value = serverStatus.state == MpdState.play;
    elapsed.value = serverStatus.elapsed;
    
    // Manage elapsed timer based on playing state
    if (isPlaying.value && !wasPlaying) {
      _startElapsedTimer();
    } else if (!isPlaying.value && wasPlaying) {
      _stopElapsedTimer();
    }
  }

  // ==========================================
  // PRIVATE - ELAPSED TIME MANAGEMENT
  // ==========================================

  /// Starts a timer to update elapsed time every second during playback
  void _startElapsedTimer() {
    _stopElapsedTimer(); // Stop any existing timer
    
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPlaying.value || elapsed.value == null) {
        _stopElapsedTimer();
        return;
      }

      final currentElapsed = elapsed.value!;
      final songDuration = currentSong.value?.time?.toDouble();
      final newElapsed = currentElapsed + 1.0;
      
      // Check if we've reached the end of the song
      if (songDuration != null && newElapsed >= songDuration) {
        elapsed.value = songDuration;
        _stopElapsedTimer();
      } else {
        elapsed.value = newElapsed;
      }
    });
  }

  /// Stops the elapsed time timer
  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  // ==========================================
  // PRIVATE - CONNECTION MANAGEMENT
  // ==========================================

  /// Attempts to reconnect to the MPD server after a connection failure
  Future<void> _attemptReconnection() async {
    if (_host == null || _port == null) return;

    await Future.delayed(const Duration(seconds: 5));
    
    if (!_isInitialized) return; // Service was disposed

    try {
      debugPrint('Attempting to reconnect to MPD...');
      _cleanup();
      await initialize(host: _host!, port: _port!);
      debugPrint('Successfully reconnected to MPD');
    } catch (e) {
      debugPrint('MPD reconnection failed: $e');
      // The polling loop will continue and try again
    }
  }

  /// Cleans up internal resources without disposing ValueNotifiers
  void _cleanup() {
    _isPolling = false;
    _stopElapsedTimer();
    _client = null;
    _statusClient = null;
  }
}