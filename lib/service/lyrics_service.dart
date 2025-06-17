import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// Exception thrown when lyrics service operations fail
class LyricsServiceException implements Exception {
  final String message;
  final String? code;
  
  const LyricsServiceException(this.message, [this.code]);
  
  @override
  String toString() => 'LyricsServiceException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Represents a single line of lyrics with timing information
class LyricsLine {
  final String text;
  final int startTimeMs;
  
  const LyricsLine({
    required this.text,
    required this.startTimeMs,
  });
  
  /// Creates a LyricsLine from JSON data
  factory LyricsLine.fromJson(Map<String, dynamic> json) {
    return LyricsLine(
      text: json['text']?.toString() ?? '♪',
      startTimeMs: ((json['time']?['total'] ?? 0) * 1000).round(),
    );
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
  
  const LyricsServiceConfig({
    this.baseUrl = "https://apic.musixmatch.com/ws/1.1",
    this.appId = "web-desktop-app-v1.0",
    this.timeout = const Duration(seconds: 30),
    this.enableLogging = false,
  });
}

/// Result of a lyrics search operation
class LyricsResult {
  final List<LyricsLine> lines;
  final bool isInstrumental;
  final String artist;
  final String title;
  final String? album;
  
  const LyricsResult({
    required this.lines,
    required this.isInstrumental,
    required this.artist,
    required this.title,
    this.album,
  });
  
  /// Converts lyrics to LRC format string
  String toLrcString([String? customFilename]) {
    final filename = customFilename ?? "$artist - $title.lrc";
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

/// Service for fetching song lyrics from Musixmatch API
class LyricsService {
  final LyricsServiceConfig _config;
  final http.Client _httpClient;
  String? _token;
  
  /// Creates a new LyricsService instance
  LyricsService([LyricsServiceConfig? config])
      : _config = config ?? const LyricsServiceConfig(),
        _httpClient = http.Client();
  
  /// Disposes of the HTTP client resources
  void dispose() {
    _httpClient.close();
  }
  
  /// Fetches lyrics for a song
  /// 
  /// Parameters:
  /// - [artist]: The artist name (required)
  /// - [title]: The song title (required)  
  /// - [album]: The album name (optional)
  /// - [synced]: Whether to fetch synced lyrics with timestamps (default: true)
  /// 
  /// Returns a [LyricsResult] if successful, null if no lyrics found
  /// 
  /// Throws [LyricsServiceException] on API errors
  Future<LyricsResult?> fetchLyrics({
    required String artist,
    required String title,
    String? album,
    bool synced = true,
  }) async {
    try {
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
        return LyricsResult(
          lines: [LyricsLine(text: "♪ Instrumental ♪", startTimeMs: 0)],
          isInstrumental: true,
          artist: artist,
          title: title,
          album: album,
        );
      }
      
      // Parse lyrics
      final lines = _parseLyrics(lyricsData, synced);
      if (lines.isEmpty) {
        _log("Failed to parse lyrics for '$title' by '$artist'");
        return null;
      }
      
      return LyricsResult(
        lines: lines,
        isInstrumental: false,
        artist: artist,
        title: title,
        album: album,
      );
      
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
      final uri = Uri.parse("${_config.baseUrl}/token.get")
          .replace(queryParameters: {'app_id': _config.appId});
      
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers['cookie'] = 'security=true';
      
      final response = await _httpClient.send(request)
          .timeout(_config.timeout);
      
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
      final uri = Uri.parse("${_config.baseUrl}/macro.subtitles.get")
          .replace(queryParameters: params);
      
      final request = http.Request("GET", uri)
        ..followRedirects = false
        ..headers["cookie"] = "security=true";
      
      final response = await _httpClient.send(request)
          .timeout(_config.timeout);
      
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
      final instrumental = lyricsData["track.lyrics.get"]?["message"]?["body"]?["lyrics"]?["instrumental"];
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
    final subtitleList = lyricsData["track.subtitles.get"]?["message"]?["body"]?["subtitle_list"] as List?;
    
    if (subtitleList == null || subtitleList.isEmpty) {
      throw const LyricsServiceException(
        "No subtitle data found",
        'NO_SUBTITLE_DATA',
      );
    }
    
    final subtitleBody = subtitleList[0]["subtitle"]?["subtitle_body"] as String?;
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
    final lyricsBody = lyricsData["track.lyrics.get"]?["message"]?["body"]?["lyrics"]?["lyrics_body"] as String?;
    
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
      // print("[LyricsService] $message");
    }
  }
}
