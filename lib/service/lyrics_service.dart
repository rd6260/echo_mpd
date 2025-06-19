import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Exception thrown when lyrics service operations fail
class LyricsServiceException implements Exception {
  final String message;
  final String? code;

  const LyricsServiceException(this.message, [this.code]);

  @override
  String toString() =>
      'LyricsServiceException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Represents a single line of lyrics with timing information
class LyricsLine {
  final String text;
  final int startTimeMs;

  const LyricsLine({required this.text, required this.startTimeMs});

  /// Creates a LyricsLine from JSON data
  factory LyricsLine.fromJson(Map<String, dynamic> json) {
    return LyricsLine(
      text: json['text']?.toString() ?? '♪',
      startTimeMs: ((json['time']?['total'] ?? 0) * 1000).round(),
    );
  }

  /// Creates a LyricsLine from LRC format line
  factory LyricsLine.fromLrcLine(String lrcLine) {
    final timeRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\](.*)');
    final match = timeRegex.firstMatch(lrcLine);

    if (match == null) {
      return LyricsLine(text: lrcLine, startTimeMs: 0);
    }

    final minutes = int.parse(match.group(1)!);
    final seconds = int.parse(match.group(2)!);
    final hundredths = int.parse(match.group(3)!);
    final text = match.group(4)!;

    final startTimeMs =
        (minutes * 60 * 1000) + (seconds * 1000) + (hundredths * 10);

    return LyricsLine(text: text, startTimeMs: startTimeMs);
  }

  /// Formats the timestamp for LRC format (MM:SS.CC)
  String get formattedTime {
    final minutes = (startTimeMs / (1000 * 60)).floor();
    final seconds = ((startTimeMs / 1000) % 60).floor();
    final hundredths = ((startTimeMs % 1000) / 10).floor();

    return "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}."
        "${hundredths.toString().padLeft(2, '0')}";
  }

  /// Converts to LRC format line
  String toLrcLine() => "[$formattedTime]$text";

  @override
  String toString() => 'LyricsLine(text: $text, startTimeMs: $startTimeMs)';
}

/// Configuration for the lyrics service
class LyricsServiceConfig {
  final String baseUrl;
  final String appId;
  final Duration timeout;
  final bool enableLogging;
  final bool enableCaching;
  final String? customCacheDir;

  const LyricsServiceConfig({
    this.baseUrl = "https://apic.musixmatch.com/ws/1.1",
    this.appId = "web-desktop-app-v1.0",
    this.timeout = const Duration(seconds: 30),
    this.enableLogging = false,
    this.enableCaching = true,
    this.customCacheDir,
  });
}

/// Result of a lyrics search operation
class LyricsResult {
  final List<LyricsLine> lines;
  final bool isInstrumental;
  final String artist;
  final String title;
  final String? album;
  final bool fromCache;

  const LyricsResult({
    required this.lines,
    required this.isInstrumental,
    required this.artist,
    required this.title,
    this.album,
    this.fromCache = false,
  });

  /// Converts lyrics to LRC format string
  String toLrcString([String? customFilename]) {
    // final filename = customFilename ?? "$artist - $title.lrc";
    final buffer = StringBuffer();

    // Add metadata
    buffer.writeln("[ti:$title]");
    buffer.writeln("[ar:$artist]");
    if (album != null) buffer.writeln("[al:$album]");
    buffer.writeln("[by:LyricsService]");
    buffer.writeln();

    // Add lyrics lines
    for (final line in lines) {
      buffer.writeln(line.toLrcLine());
    }

    return buffer.toString();
  }

  /// Gets plain text lyrics without timing
  String get plainText => lines.map((line) => line.text).join('\n');
}

/// Service for fetching song lyrics from Musixmatch API with caching support
class LyricsService {
  final LyricsServiceConfig _config;
  final http.Client _httpClient;
  String? _token;
  Directory? _cacheDir;

  /// Creates a new LyricsService instance
  LyricsService([LyricsServiceConfig? config])
    : _config = config ?? const LyricsServiceConfig(),
      _httpClient = http.Client();

  /// Disposes of the HTTP client resources
  void dispose() {
    _httpClient.close();
  }

  /// Initializes the cache directory
  Future<void> _initializeCacheDir() async {
    if (!_config.enableCaching || _cacheDir != null) return;

    try {
      Directory baseDir;
      if (_config.customCacheDir != null) {
        baseDir = Directory(_config.customCacheDir!);
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        baseDir = appDir;
      }

      _cacheDir = Directory(path.join(baseDir.path, 'lyrics'));
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
        _log("Created cache directory: ${_cacheDir!.path}");
      }
    } catch (e) {
      _log("Failed to initialize cache directory: $e");
      // Disable caching if we can't create the directory
      _cacheDir = null;
    }
  }

  /// Generates a safe filename for caching
  String _getSafeFilename(String artist, String title, String? album) {
    // Remove invalid characters and limit length
    final cleanArtist = artist.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final cleanTitle = title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final cleanAlbum = album?.replaceAll(RegExp(r'[^\w\s-]'), '').trim();

    String filename = "${cleanArtist}_$cleanTitle";
    if (cleanAlbum != null && cleanAlbum.isNotEmpty) {
      filename += "_$cleanAlbum";
    }

    // Limit filename length and add extension
    if (filename.length > 200) {
      filename = filename.substring(0, 200);
    }

    return "$filename.lrc";
  }

  /// Gets the cache file for given song details
  File? _getCacheFile(String artist, String title, String? album) {
    if (_cacheDir == null) return null;

    final filename = _getSafeFilename(artist, title, album);
    return File(path.join(_cacheDir!.path, filename));
  }

  /// Loads lyrics from cache file
  Future<LyricsResult?> _loadFromCache(
    String artist,
    String title,
    String? album,
  ) async {
    if (!_config.enableCaching) return null;

    await _initializeCacheDir();
    final cacheFile = _getCacheFile(artist, title, album);

    if (cacheFile == null || !await cacheFile.exists()) {
      return null;
    }

    try {
      final content = await cacheFile.readAsString();
      final lines = <LyricsLine>[];
      bool isInstrumental = false;
      String? cachedArtist = artist;
      String? cachedTitle = title;
      String? cachedAlbum = album;

      for (final line in content.split('\n')) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;

        // Parse metadata
        if (trimmedLine.startsWith('[ti:')) {
          cachedTitle = trimmedLine.substring(4, trimmedLine.length - 1);
        } else if (trimmedLine.startsWith('[ar:')) {
          cachedArtist = trimmedLine.substring(4, trimmedLine.length - 1);
        } else if (trimmedLine.startsWith('[al:')) {
          cachedAlbum = trimmedLine.substring(4, trimmedLine.length - 1);
        } else if (trimmedLine.startsWith('[by:')) {
          // Skip author line
          continue;
        } else if (trimmedLine.startsWith('[') && trimmedLine.contains(']')) {
          // Parse lyric line
          final lyricsLine = LyricsLine.fromLrcLine(trimmedLine);
          lines.add(lyricsLine);

          if (lyricsLine.text.contains('♪ Instrumental ♪')) {
            isInstrumental = true;
          }
        }
      }

      _log("Loaded lyrics from cache: ${cacheFile.path}");

      return LyricsResult(
        lines: lines,
        isInstrumental: isInstrumental,
        artist: cachedArtist ?? artist,
        title: cachedTitle ?? title,
        album: cachedAlbum,
        fromCache: true,
      );
    } catch (e) {
      _log("Failed to load lyrics from cache: $e");
      // Try to delete corrupted cache file
      try {
        await cacheFile.delete();
      } catch (_) {}
      return null;
    }
  }

  /// Saves lyrics to cache file
  Future<void> _saveToCache(LyricsResult result) async {
    if (!_config.enableCaching) return;

    await _initializeCacheDir();
    final cacheFile = _getCacheFile(result.artist, result.title, result.album);

    if (cacheFile == null) return;

    try {
      final lrcContent = result.toLrcString();
      await cacheFile.writeAsString(lrcContent);
      _log("Saved lyrics to cache: ${cacheFile.path}");
    } catch (e) {
      _log("Failed to save lyrics to cache: $e");
    }
  }

  /// Clears all cached lyrics files
  Future<void> clearCache() async {
    if (!_config.enableCaching) return;

    await _initializeCacheDir();
    if (_cacheDir == null || !await _cacheDir!.exists()) return;

    try {
      final files = await _cacheDir!.list().toList();
      for (final file in files) {
        if (file is File && file.path.endsWith('.lrc')) {
          await file.delete();
        }
      }
      _log("Cleared lyrics cache");
    } catch (e) {
      _log("Failed to clear cache: $e");
    }
  }

  /// Gets cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final stats = <String, dynamic>{
      'enabled': _config.enableCaching,
      'directory': null,
      'fileCount': 0,
      'totalSize': 0,
    };

    if (!_config.enableCaching) return stats;

    await _initializeCacheDir();
    if (_cacheDir == null || !await _cacheDir!.exists()) return stats;

    try {
      stats['directory'] = _cacheDir!.path;
      final files = await _cacheDir!.list().toList();
      int fileCount = 0;
      int totalSize = 0;

      for (final file in files) {
        if (file is File && file.path.endsWith('.lrc')) {
          fileCount++;
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }

      stats['fileCount'] = fileCount;
      stats['totalSize'] = totalSize;
    } catch (e) {
      _log("Failed to get cache stats: $e");
    }

    return stats;
  }

  /// Fetches lyrics for a song with caching support
  ///
  /// Parameters:
  /// - [artist]: The artist name (required)
  /// - [title]: The song title (required)
  /// - [album]: The album name (optional)
  /// - [synced]: Whether to fetch synced lyrics with timestamps (default: true)
  /// - [forceRefresh]: Whether to bypass cache and fetch fresh data (default: false)
  ///
  /// Returns a [LyricsResult] if successful, null if no lyrics found
  ///
  /// Throws [LyricsServiceException] on API errors
  Future<LyricsResult?> fetchLyrics({
    required String? artist,
    required String? title,
    String? album,
    bool synced = true,
    bool forceRefresh = false,
  }) async {
    if (artist == null || title == null) return null;
    try {
      // Try to load from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedResult = await _loadFromCache(artist, title, album);
        if (cachedResult != null) {
          _log("Using cached lyrics for '$title' by '$artist'");
          return cachedResult;
        }
      }

      // Ensure we have a valid token
      await _ensureValidToken();

      // Search for lyrics
      final lyricsData = await _findLyrics(
        artist: artist,
        title: title,
        album: album,
      );

      if (lyricsData == null) {
        _log("No lyrics found for '$title' by '$artist'");
        return null;
      }

      // Handle instrumental tracks
      if (lyricsData['instrumental'] == true) {
        final result = LyricsResult(
          lines: [LyricsLine(text: "♪ Instrumental ♪", startTimeMs: 0)],
          isInstrumental: true,
          artist: artist,
          title: title,
          album: album,
        );

        // Save instrumental info to cache
        await _saveToCache(result);
        return result;
      }

      // Parse lyrics
      final lines = _parseLyrics(lyricsData, synced);
      if (lines.isEmpty) {
        _log("Failed to parse lyrics for '$title' by '$artist'");
        return null;
      }

      final result = LyricsResult(
        lines: lines,
        isInstrumental: false,
        artist: artist,
        title: title,
        album: album,
      );

      // Save to cache
      await _saveToCache(result);

      return result;
    } catch (e) {
      if (e is LyricsServiceException) rethrow;
      throw LyricsServiceException(
        "Failed to fetch lyrics for '$title' by '$artist': $e",
        'FETCH_ERROR',
      );
    }
  }

  /// Ensures we have a valid authentication token
  Future<void> _ensureValidToken() async {
    if (_token != null) return;

    _token = await _refreshToken();
    if (_token == null) {
      throw const LyricsServiceException(
        "Failed to obtain authentication token",
        'AUTH_ERROR',
      );
    }
  }

  /// Refreshes the authentication token
  Future<String?> _refreshToken() async {
    try {
      final uri = Uri.parse(
        "${_config.baseUrl}/token.get",
      ).replace(queryParameters: {'app_id': _config.appId});

      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers['cookie'] = 'security=true';

      final response = await _httpClient.send(request).timeout(_config.timeout);

      if (response.statusCode != 200) {
        throw LyricsServiceException(
          "Token request failed with status ${response.statusCode}",
          'TOKEN_REQUEST_FAILED',
        );
      }

      final body = await response.stream.bytesToString();
      final data = json.decode(body);
      final token = data['message']?['body']?['user_token'] as String?;

      if (token == null) {
        throw const LyricsServiceException(
          "Token not found in response",
          'TOKEN_NOT_FOUND',
        );
      }

      _log("Successfully obtained token: ${token.substring(0, 10)}...");
      return token;
    } on SocketException {
      throw const LyricsServiceException(
        "Network error while fetching token",
        'NETWORK_ERROR',
      );
    } catch (e) {
      if (e is LyricsServiceException) rethrow;
      throw LyricsServiceException(
        "Unexpected error while refreshing token: $e",
        'TOKEN_ERROR',
      );
    }
  }

  /// Searches for lyrics data
  Future<Map<String, dynamic>?> _findLyrics({
    required String artist,
    required String title,
    String? album,
  }) async {
    final params = <String, String>{
      "format": "json",
      "namespace": "lyrics_richsynched",
      "subtitle_format": "mxm",
      "app_id": _config.appId,
      "q_artist": artist,
      "q_track": title,
      "usertoken": _token!,
      if (album != null) "q_album": album,
    };

    try {
      final uri = Uri.parse(
        "${_config.baseUrl}/macro.subtitles.get",
      ).replace(queryParameters: params);

      final request = http.Request("GET", uri)
        ..followRedirects = false
        ..headers["cookie"] = "security=true";

      final response = await _httpClient.send(request).timeout(_config.timeout);

      if (response.statusCode != 200) {
        throw LyricsServiceException(
          "Lyrics search failed with status ${response.statusCode}",
          'SEARCH_FAILED',
        );
      }

      final body = await response.stream.bytesToString();
      final data = json.decode(body);
      final lyricsData = data["message"]?["body"]?["macro_calls"];

      if (lyricsData == null) {
        _log("No lyrics data found in response");
        return null;
      }

      // Check if the song is instrumental
      final instrumental =
          lyricsData["track.lyrics.get"]?["message"]?["body"]?["lyrics"]?["instrumental"];
      if (instrumental == 1) {
        return {"instrumental": true};
      }

      return lyricsData;
    } on SocketException {
      throw const LyricsServiceException(
        "Network error while searching for lyrics",
        'NETWORK_ERROR',
      );
    } catch (e) {
      if (e is LyricsServiceException) rethrow;
      throw LyricsServiceException(
        "Unexpected error while searching for lyrics: $e",
        'SEARCH_ERROR',
      );
    }
  }

  /// Parses lyrics data into LyricsLine objects
  List<LyricsLine> _parseLyrics(Map<String, dynamic> lyricsData, bool synced) {
    try {
      if (synced) {
        return _parseSyncedLyrics(lyricsData);
      } else {
        return _parsePlainLyrics(lyricsData);
      }
    } catch (e) {
      _log("Error parsing lyrics: $e");
      return [];
    }
  }

  /// Parses synced lyrics with timestamps
  List<LyricsLine> _parseSyncedLyrics(Map<String, dynamic> lyricsData) {
    final subtitleList =
        lyricsData["track.subtitles.get"]?["message"]?["body"]?["subtitle_list"]
            as List?;

    if (subtitleList == null || subtitleList.isEmpty) {
      throw const LyricsServiceException(
        "No subtitle data found",
        'NO_SUBTITLE_DATA',
      );
    }

    final subtitleBody =
        subtitleList[0]["subtitle"]?["subtitle_body"] as String?;
    if (subtitleBody == null) {
      throw const LyricsServiceException(
        "No subtitle body found",
        'NO_SUBTITLE_BODY',
      );
    }

    final parsedLyrics = json.decode(subtitleBody) as List;
    return parsedLyrics
        .map((line) => LyricsLine.fromJson(line as Map<String, dynamic>))
        .toList();
  }

  /// Parses plain lyrics without timestamps
  List<LyricsLine> _parsePlainLyrics(Map<String, dynamic> lyricsData) {
    final lyricsBody =
        lyricsData["track.lyrics.get"]?["message"]?["body"]?["lyrics"]?["lyrics_body"]
            as String?;

    if (lyricsBody == null) {
      throw const LyricsServiceException(
        "No lyrics body found",
        'NO_LYRICS_BODY',
      );
    }

    return lyricsBody
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => LyricsLine(text: line.trim(), startTimeMs: 0))
        .toList();
  }

  /// Logs a message if logging is enabled
  void _log(String message) {
    if (_config.enableLogging) {
      debugPrint("[LyricsService] $message");
    }
  }
}
