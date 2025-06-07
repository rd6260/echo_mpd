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
  /// Private constructor for singleton pattern
  MpdRemoteService._();

  /// Singleton instance of [MpdRemoteService]
  static final MpdRemoteService _instance = MpdRemoteService._();

  /// Gets the singleton instance of [MpdRemoteService]
  static MpdRemoteService get instance => _instance;

  // Private fields
  MpdClient? _client;
  MpdClient? _statusClient;
  bool _isInitialized = false;
  bool _isPolling = false;
  String? _host;
  int? _port;

  // Public notifiers for state management

  /// Notifies listeners when the current song changes
  ///
  /// Value is `null` when no song is playing or when disconnected
  final ValueNotifier<MpdSong?> currentSong = ValueNotifier(null);

  /// Notifies listeners when the connection status changes
  final ValueNotifier<bool> isConnected = ValueNotifier(false);

  /// Notifies listeners when player is playing or pause
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);

  /// Notifies listeners when the current playlist (queue) changes
  final ValueNotifier<List<MpdSong>> currentPlaylist = ValueNotifier([]);

  /// Initializes the MPD service with the specified connection details
  ///
  /// [host] - The MPD server hostname or IP address
  /// [port] - The MPD server port (typically 6600)
  ///
  /// Throws [StateError] if already initialized
  /// Throws [MpdException] or [SocketException] on connection failure
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await MpdRemoteService.instance.initialize(
  ///     host: '192.168.1.100',
  ///     port: 6600
  ///   );
  /// } catch (e) {
  ///   print('Failed to connect to MPD: $e');
  /// }
  /// ```
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

  /// Creates the MPD client instances
  Future<void> _createClients(String host, int port) async {
    final connectionDetails = MpdConnectionDetails(host: host, port: port);

    _client = MpdClient(connectionDetails: connectionDetails);
    _statusClient = MpdClient(connectionDetails: connectionDetails);
  }

  /// Initializes the service state by fetching current song and playlist
  Future<void> _initializeState() async {
    if (_client == null) return;

    // Test connection and fetch initial state
    currentSong.value = await _client!.currentsong();
    isConnected.value = _client!.connection.isConnected;
    await _updatePlayerStatus();
    await _updateCurrentPlaylist();
  }

  /// Starts the background status polling using MPD's idle command
  void _startStatusPolling() {
    if (_isPolling) return;

    _isPolling = true;
    // Use microtask to avoid blocking the current execution
    Future.microtask(_statusPollingLoop);
  }

  /// Main polling loop that listens for MPD subsystem changes
  Future<void> _statusPollingLoop() async {
    while (_isInitialized && _statusClient != null && _isPolling) {
      try {
        // Wait for changes in any MPD subsystem
        final changes = await _statusClient!.idle();

        if (!_isInitialized || !_isPolling) break;

        await _handleSubsystemChanges(changes);
      } catch (e) {
        debugPrint('MPD polling error: $e');
        isConnected.value = false;

        // Attempt reconnection after delay
        await _attemptReconnection();
      }
    }
  }

  /// Handles changes in MPD subsystems
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
          // Database was updated (new songs added, etc.)
          debugPrint('MPD database updated');
          break;

        case MpdSubsystem.mixer:
          // Volume or other mixer settings changed
          debugPrint('MPD mixer settings changed');
          break;

        case MpdSubsystem.output:
          // Audio output configuration changed
          debugPrint('MPD output configuration changed');
          break;

        case MpdSubsystem.options:
          // Playback options changed (repeat, random, etc.)
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
          // Handle other subsystem changes as needed
          debugPrint('MPD subsystem $change changed (not handled)');
          break;
      }
    }
  }

  /// Updates the current song information
  Future<void> _updateCurrentSong() async {
    if (_client == null) return;

    try {
      currentSong.value = await _client!.currentsong();
    } catch (e) {
      debugPrint('Failed to update current song: $e');
    }
  }

  /// Updates the current playlist (queue) information
  Future<void> _updateCurrentPlaylist() async {
    if (_client == null) return;

    try {
      final queue = await _client!.playlistid();
      currentPlaylist.value = queue;
    } catch (e) {
      debugPrint('Failed to update current playlist: $e');
    }
  }

  /// Updates to be done when Player Status changes (Play, Pause, Stoped)
  /// 
  ///  - Updates value of `isPlaying` ValueNotifier.
  Future<void> _updatePlayerStatus() async {
    MpdStatus serverStatus = await _client!.status();yer:
          await _updateCurrentSong();
    isPlaying.value = serverStatus.state == MpdState.play;
  }

  /// Attempts to reconnect to the MPD server after a connection failure
  Future<void> _attemptReconnection() async {
    if (_host == null || _port == null) return;

    // Wait before attempting reconnection
    await Future.delayed(const Duration(seconds: 5));

    if (!_isInitialized) return; // Service was disposed

    try {
      debugPrint('Attempting to reconnect to MPD...');

      // Reinitialize the service
      _cleanup();
      await initialize(host: _host!, port: _port!);

      debugPrint('Successfully reconnected to MPD');
    } catch (e) {
      debugPrint('MPD reconnection failed: $e');
      // The polling loop will continue and try again
    }
  }

  /// Gets the main MPD client for sending commands
  ///
  /// Throws [StateError] if the service is not initialized
  ///
  /// Example:
  /// ```dart
  /// final client = MpdRemoteService.instance.client;
  /// await client.play();
  /// await client.pause();
  /// ```
  MpdClient get client {
    if (!_isInitialized || _client == null) {
      throw StateError(
        'MpdRemoteService not initialized. Call initialize() first.',
      );
    }
    return _client!;
  }

  /// Returns whether the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Returns the current MPD server hostname
  String? get host => _host;

  /// Returns the current MPD server port
  int? get port => _port;

  /// Forces an update of the current playlist
  ///
  /// This method is useful when you want to refresh the playlist
  /// without waiting for the automatic update from MPD's idle command
  Future<void> refreshPlaylist() async {
    await _updateCurrentPlaylist();
  }

  /// Forces an update of the current song
  ///
  /// This method is useful when you want to refresh the current song
  /// without waiting for the automatic update from MPD's idle command
  Future<void> refreshCurrentSong() async {
    await _updateCurrentSong();
  }

  /// Cleans up internal resources
  void _cleanup() {
    _isPolling = false;
    _client = null;
    _statusClient = null;
  }

  /// Disposes the service and cleans up all resources
  ///
  /// After calling this method, you need to call [initialize] again
  /// to use the service. This method should be called when the app
  /// is being disposed or when you want to completely reset the service.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   MpdRemoteService.instance.dispose();
  ///   super.dispose();
  /// }
  /// ```
  void dispose() {
    _isInitialized = false;
    _cleanup();

    // Dispose ValueNotifiers to prevent memory leaks
    currentSong.dispose();
    isConnected.dispose();
    currentPlaylist.dispose();

    debugPrint('MPD Service disposed');
  }

  /// Reinitializes the service with the same connection details
  ///
  /// This is useful for recovering from connection issues or
  /// when you want to reset the service state.
  ///
  /// Throws [StateError] if the service was never initialized
  Future<void> reconnect() async {
    if (_host == null || _port == null) {
      throw StateError('Cannot reconnect: service was never initialized');
    }

    dispose();
    await initialize(host: _host!, port: _port!);
  }
}
