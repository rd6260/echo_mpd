import 'dart:async';
import 'package:dart_mpd/dart_mpd.dart';
import 'package:echo_mpd/service/mpd_remote_service.dart';
import 'package:flutter/material.dart';

/// Service for managing user favourites using MPD stored playlists
/// 
/// This service handles adding/removing songs from a "Favourites" playlist
/// stored on the MPD server. It uses MPD's stored playlist functionality
/// to maintain a persistent list of favourite tracks.
class FavouritesService {
  static const String favouritesPlaylistName = 'Favourites';
  
  // Singleton pattern
  FavouritesService._();
  static final FavouritesService _instance = FavouritesService._();
  static FavouritesService get instance => _instance;
  
  /// Tracks if current song is in favourites
  final ValueNotifier<bool> isCurrentSongFavourite = ValueNotifier(false);
  
  /// List of all favourite songs
  final ValueNotifier<List<MpdSong>> favouriteSongs = ValueNotifier([]);
  
  bool _isInitialized = false;
  
  /// Initializes the favourites service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Listen to current song changes to update favourite status
      MpdRemoteService.instance.currentSong.addListener(_onCurrentSongChanged);
      
      // Load initial favourites
      await refreshFavourites();
      
      _isInitialized = true;
      debugPrint('FavouritesService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize FavouritesService: $e');
      rethrow;
    }
  }
  
  /// Refreshes the favourites list from MPD
  Future<void> refreshFavourites() async {
    try {
      final client = MpdRemoteService.instance.client;
      
      // Try to load the favourites playlist
      try {
        final playlistSongs = await client.listplaylistinfo(favouritesPlaylistName);
        favouriteSongs.value = playlistSongs;
        debugPrint('Loaded ${playlistSongs.length} favourite songs');
      } catch (e) {
        // Playlist might not exist yet, that's okay
        debugPrint('Favourites playlist does not exist yet or is empty: $e');
        favouriteSongs.value = [];
      }
      
      // Update current song favourite status
      _updateCurrentSongFavouriteStatus();
    } catch (e) {
      debugPrint('Failed to refresh favourites: $e');
      rethrow;
    }
  }
  
  /// Adds the current song to favourites
  Future<bool> addCurrentSongToFavourites() async {
    final currentSong = MpdRemoteService.instance.currentSong.value;
    if (currentSong?.file == null) {
      debugPrint('No current song to add to favourites');
      return false;
    }
    
    return addToFavourites(currentSong!);
  }
  
  /// Adds a specific song to favourites
  Future<bool> addToFavourites(MpdSong song) async {
    final songFile = song.file;
    
    try {
      final client = MpdRemoteService.instance.client;
      
      // Check if song is already in favourites
      if (await isSongInFavourites(song)) {
        debugPrint('Song is already in favourites');
        return true;
      }
      
      // Add the song to the favourites playlist
      await client.playlistadd(favouritesPlaylistName, songFile);
      
      debugPrint('Added "${song.title?.join("")}" to favourites');
      
      // Refresh the favourites list
      await refreshFavourites();
      
      return true;
    } catch (e) {
      debugPrint('Failed to add song to favourites: $e');
      return false;
    }
  }
  
  /// Removes the current song from favourites
  Future<bool> removeCurrentSongFromFavourites() async {
    final currentSong = MpdRemoteService.instance.currentSong.value;
    if (currentSong?.file == null) {
      debugPrint('No current song to remove from favourites');
      return false;
    }
    
    return removeFromFavourites(currentSong!);
  }
  
  /// Removes a specific song from favourites
  Future<bool> removeFromFavourites(MpdSong song) async {
    final songFile = song.file;
    
    try {
      final client = MpdRemoteService.instance.client;

      // Determine the song's index inside the favourites playlist (0-based).
      final favourites = favouriteSongs.value;
      final index = favourites.indexWhere((favSong) => favSong.file == songFile);

      if (index == -1) {
        debugPrint('Song not found in favourites');
        return false;
      }

      // Remove the single track at the located index using an MpdRange.
      await client.playlistdelete(
        favouritesPlaylistName,
        MpdRange(index, index),
      );

      debugPrint('Removed "${song.title?.join("")}" from favourites');

      // Refresh the favourites list so listeners are updated.
      await refreshFavourites();

      return true;
    } catch (e) {
      debugPrint('Failed to remove song from favourites: $e');
      return false;
    }
  }
  
  /// Toggles the current song's favourite status
  Future<bool> toggleCurrentSongFavourite() async {
    if (isCurrentSongFavourite.value) {
      return await removeCurrentSongFromFavourites();
    } else {
      return await addCurrentSongToFavourites();
    }
  }
  
  /// Checks if a specific song is in favourites
  Future<bool> isSongInFavourites(MpdSong song) async {
    final songFile = song.file;
    
    return favouriteSongs.value.any((favSong) => favSong.file == songFile);
  }
  
  /// Loads all favourite songs into the current queue
  Future<bool> loadFavouritesToQueue() async {
    try {
      final client = MpdRemoteService.instance.client;
      
      // Load the favourites playlist into the queue
      await client.load(favouritesPlaylistName);
      
      debugPrint('Loaded favourites playlist to queue');
      return true;
    } catch (e) {
      debugPrint('Failed to load favourites to queue: $e');
      return false;
    }
  }
  
  /// Updates the current song's favourite status
  void _updateCurrentSongFavouriteStatus() {
    final currentSong = MpdRemoteService.instance.currentSong.value;
    final currentSongFile = currentSong?.file;
    if (currentSongFile == null) {
      isCurrentSongFavourite.value = false;
      return;
    }
    
    isCurrentSongFavourite.value = favouriteSongs.value
        .any((favSong) => favSong.file == currentSongFile);
  }
  
  /// Handles current song changes
  void _onCurrentSongChanged() {
    _updateCurrentSongFavouriteStatus();
  }
  
  /// Disposes the service
  void dispose() {
    MpdRemoteService.instance.currentSong.removeListener(_onCurrentSongChanged);
    isCurrentSongFavourite.dispose();
    favouriteSongs.dispose();
    _isInitialized = false;
    debugPrint('FavouritesService disposed');
  }
} 