import 'dart:async';
import 'package:dart_mpd/dart_mpd.dart';
import 'package:flutter/material.dart';

/// A singleton service for managing MPD (Music Player Daemon) connections and operations.
///
/// This service provides:
/// - Connection management with automatic reconnection
/// - Real-time status monitoring via MPD's idle command
/// - Current song and playlist state management
/// - Thread-safe operations with proper error handling
/// - App lifecycle awareness for background/foreground handling
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
class MpdRemoteService with WidgetsBindingObserver {
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
  bool _isAppInBackground = false;
  bool _needsReconnectionOnResume = true;
  Timer? _elapsedTimer;
  Timer? _reconnectionTimer;
  AppLifecycleListener? _lifecycleListener;

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

    // Setup lifecycle observers
    _setupLifecycleObservers();

    try {
      await _createClients(host, port);
      await _initializeState();
      _isInitialized = true;
      
      if (!_isAppInBackground) {
        _startStatusPolling();
      }

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

    debugPrint('Reconnecting MPD service...');
    _pauseOperations();
    
    try {
      await _createClients(_host!, _port!);
      await _initializeState();
      
      if (!_isAppInBackground) {
        _resumeOperations();
      }
      
      debugPrint('MPD service reconnected successfully');
    } catch (e) {
      debugPrint('MPD service reconnection failed: $e');
      isConnected.value = false;
      rethrow;
    }
  }

  /// Disposes the service and cleans up all resources
  ///
  /// After calling this method, you need to call [initialize] again to use the service.
  /// This should be called when the app is disposed or when resetting the service.
  void dispose() {
    // Remove lifecycle observers
    _cleanupLifecycleObservers();
    
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
  // APP LIFECYCLE HANDLING
  // ==========================================

  void _setupLifecycleObservers() {
    // Use modern AppLifecycleListener if available (Flutter 3.13+)
    try {
      _lifecycleListener = AppLifecycleListener(
        onShow: () => _handleAppForeground(),
        onHide: () => _handleAppBackground(),
        onResume: () => _handleAppForeground(),
        onInactive: () => _handleAppBackground(),
        onPause: () => _handleAppBackground(),
        onDetach: () => _handleAppBackground(),
      );
      debugPrint('Using modern AppLifecycleListener');
    } catch (e) {
      // Fallback to WidgetsBindingObserver for older Flutter versions
      WidgetsBinding.instance.addObserver(this);
      debugPrint('Using WidgetsBindingObserver fallback');
    }
  }

  void _cleanupLifecycleObservers() {
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('App lifecycle state changed: $state');
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        debugPrint('App going to background - pausing MPD operations');
        _handleAppBackground();
        break;
        
      case AppLifecycleState.resumed:
        debugPrint('App resumed - resuming MPD operations');
        _handleAppForeground();
        break;
        
      case AppLifecycleState.inactive:
        // Don't pause on inactive as it's triggered during transitions
        debugPrint('App inactive - not changing MPD operations');
        break;
    }
  }

  /// Handles app going to background
  void _handleAppBackground() {
    if (_isAppInBackground) return; // Already in background
    
    debugPrint('Handling app background');
    _isAppInBackground = true;
    _pauseOperations();
  }

  /// Handles app coming to foreground
  void _handleAppForeground() {
    if (!_isAppInBackground) return; // Already in foreground
    
    debugPrint('Handling app foreground');
    _isAppInBackground = false;
    
    if (_isInitialized) {
      if (_needsReconnectionOnResume) {
        debugPrint('Attempting deferred reconnection on app resume');
        _needsReconnectionOnResume = true;
        // Attempt reconnection after a short delay to ensure app is fully resumed
        Timer(const Duration(milliseconds: 1000), () {
          if (!_isAppInBackground && _isInitialized) {
            reconnect().catchError((e) {
              debugPrint('Failed to reconnect on app resume: $e');
              _scheduleReconnection();
            });
          }
        });
      } else {
        _resumeOperations();
      }
    }
  }

  /// Pauses all background operations
  void _pauseOperations() {
    debugPrint('Pausing MPD operations');
    _isPolling = false;
    _stopElapsedTimer();
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
    
    // Close connections gracefully but don't set clients to null
    // so we can try to reuse them when resuming
    try {
      _statusClient?.connection.close();
      _client?.connection.close();
    } catch (e) {
      debugPrint('Error closing connections during pause: $e');
    }
  }

  /// Resumes background operations
  void _resumeOperations() {
    debugPrint('Resuming MPD operations');
    
    if (_isInitialized && !_isAppInBackground) {
      // Test connection before resuming polling
      _testConnectionAndResume();
    }
  }

  /// Tests connection and resumes operations or schedules reconnection
  void _testConnectionAndResume() {
    if (_client == null) {
      debugPrint('Client is null, scheduling reconnection');
      _needsReconnectionOnResume = true;
      _scheduleReconnection();
      return;
    }

    // Try a simple command to test connection
    _client!.ping().then((_) {
      debugPrint('Connection test successful, resuming operations');
      isConnected.value = true;
      _startStatusPolling();
      
      // Refresh state after resume
      Future.microtask(() async {
        try {
          await refreshPlayerStatus();
          await refreshCurrentSong();
        } catch (e) {
          debugPrint('Failed to refresh state on resume: $e');
        }
      });
    }).catchError((e) {
      debugPrint('Connection test failed: $e, scheduling reconnection');
      isConnected.value = false;
      _needsReconnectionOnResume = true;
      _scheduleReconnection();
    });
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

  /// Returns whether the app is currently in background
  bool get isAppInBackground => _isAppInBackground;

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
      _handleConnectionError(e);
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
      _handleConnectionError(e);
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
    
    // Close existing clients if they exist
    try {
      _client?.connection.close();
      _statusClient?.connection.close();
    } catch (e) {
      debugPrint('Error closing existing clients: $e');
    }
    
    _client = MpdClient(connectionDetails: connectionDetails);
    _statusClient = MpdClient(connectionDetails: connectionDetails);
  }

  /// Initializes the service state by fetching current data from MPD
  Future<void> _initializeState() async {
    if (_client == null) return;

    try {
      currentSong.value = await _client!.currentsong();
      isConnected.value = _client!.connection.isConnected;
      await _updatePlayerStatus();
      await _updateCurrentPlaylist();
    } catch (e) {
      debugPrint('Failed to initialize state: $e');
      isConnected.value = false;
      rethrow;
    }
  }

  // ==========================================
  // PRIVATE - STATUS POLLING
  // ==========================================

  /// Starts the background status polling using MPD's idle command
  void _startStatusPolling() {
    if (_isPolling || _isAppInBackground) {
      debugPrint('Not starting polling: isPolling=$_isPolling, isBackground=$_isAppInBackground');
      return;
    }
    
    debugPrint('Starting status polling');
    _isPolling = true;
    Future.microtask(_statusPollingLoop);
  }

  /// Main polling loop that listens for MPD subsystem changes
  Future<void> _statusPollingLoop() async {
    debugPrint('Status polling loop started');
    
    while (_isInitialized && _statusClient != null && _isPolling && !_isAppInBackground) {
      try {
        debugPrint('Waiting for MPD idle...');
        final changes = await _statusClient!.idle();
        
        if (!_isInitialized || !_isPolling || _isAppInBackground) {
          debugPrint('Breaking polling loop: initialized=$_isInitialized, polling=$_isPolling, background=$_isAppInBackground');
          break;
        }
        
        isConnected.value = true;
        await _handleSubsystemChanges(changes);
      } catch (e) {
        debugPrint('MPD polling error: $e');
        isConnected.value = false;
        _handleConnectionError(e);
        break; // Exit the loop, reconnection will be handled separately
      }
    }
    
    debugPrint('Status polling loop ended');
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
    if (_client == null || _isAppInBackground) return;

    try {
      currentSong.value = await _client!.currentsong();
    } catch (e) {
      debugPrint('Failed to update current song: $e');
      _handleConnectionError(e);
    }
  }

  /// Updates the current playlist (queue) information from MPD
  Future<void> _updateCurrentPlaylist() async {
    if (_client == null || _isAppInBackground) return;

    try {
      final queue = await _client!.playlistid();
      currentPlaylist.value = queue;
    } catch (e) {
      debugPrint('Failed to update current playlist: $e');
      _handleConnectionError(e);
    }
  }

  /// Updates player status (play/pause state, elapsed time) and manages elapsed timer
  Future<void> _updatePlayerStatus() async {
    if (_client == null || _isAppInBackground) return;

    try {
      final serverStatus = await _client!.status();
      final wasPlaying = isPlaying.value;
      
      isPlaying.value = serverStatus.state == MpdState.play;
      elapsed.value = serverStatus.elapsed;
      
      // Manage elapsed timer based on playing state
      if (isPlaying.value && !wasPlaying && !_isAppInBackground) {
        _startElapsedTimer();
      } else if (!isPlaying.value && wasPlaying) {
        _stopElapsedTimer();
      }
    } catch (e) {
      debugPrint('Failed to update player status: $e');
      _handleConnectionError(e);
    }
  }

  // ==========================================
  // PRIVATE - ELAPSED TIME MANAGEMENT
  // ==========================================

  /// Starts a timer to update elapsed time every second during playback
  void _startElapsedTimer() {
    _stopElapsedTimer(); // Stop any existing timer
    
    if (_isAppInBackground) return; // Don't start timer in background
    
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPlaying.value || elapsed.value == null || _isAppInBackground) {
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

  /// Handles connection errors and triggers reconnection if needed
  void _handleConnectionError(dynamic error) {
    debugPrint('Handling connection error: $error');
    
    if (_isAppInBackground) {
      debugPrint('App in background, deferring reconnection');
      _needsReconnectionOnResume = true;
      return;
    }
    
    isConnected.value = false;
    _scheduleReconnection();
  }

  /// Schedules a reconnection attempt
  void _scheduleReconnection() {
    if (_isAppInBackground || _reconnectionTimer != null) {
      debugPrint('Not scheduling reconnection: background=$_isAppInBackground, timer exists=${_reconnectionTimer != null}');
      return;
    }
    
    debugPrint('Scheduling reconnection in 5 seconds');
    _reconnectionTimer = Timer(const Duration(seconds: 5), () {
      _reconnectionTimer = null;
      if (!_isAppInBackground && _isInitialized) {
        _attemptReconnection();
      }
    });
  }

  /// Attempts to reconnect to the MPD server after a connection failure
  Future<void> _attemptReconnection() async {
    if (_host == null || _port == null || _isAppInBackground) {
      debugPrint('Cannot attempt reconnection: host=$_host, port=$_port, background=$_isAppInBackground');
      return;
    }

    try {
      debugPrint('Attempting to reconnect to MPD...');
      await reconnect();
      debugPrint('Successfully reconnected to MPD');
    } catch (e) {
      debugPrint('MPD reconnection failed: $e');
      _scheduleReconnection(); // Try again later
    }
  }

  /// Cleans up internal resources without disposing ValueNotifiers
  void _cleanup() {
    debugPrint('Cleaning up MPD service resources');
    _isPolling = false;
    _stopElapsedTimer();
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
    
    try {
      _statusClient?.connection.close();
      _client?.connection.close();
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
    
    _client = null;
    _statusClient = null;
  }
}