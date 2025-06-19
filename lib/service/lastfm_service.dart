import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ImageInfo {
  final String size;
  final String url;

  ImageInfo({required this.size, required this.url});

  factory ImageInfo.fromJson(Map<String, dynamic> json) {
    return ImageInfo(size: json['size'] ?? '', url: json['#text'] ?? '');
  }

  @override
  String toString() => '$size: $url';
}

class LastfmService {
  static const String _baseUrl = 'http://ws.audioscrobbler.com/2.0/';

  // Secondary Api key for development purposes
  static const String apiKey = String.fromEnvironment(
    "lastfm_api_key",
    defaultValue: "6fd88ef256bfc274dfa0797dded2bcdb",
  );


  LastfmService();

  /// Get all available album art URLs for a given artist and album
  Future<List<ImageInfo>> getAlbumArt(String artist, String album) async {
    final params = {
      'method': 'album.getinfo',
      'api_key': apiKey,
      'artist': artist,
      'album': album,
      'format': 'json',
    };

    try {
      final response = await _makeRequest(params);
      if (response != null && response['album'] != null) {
        final imageList = response['album']['image'] as List<dynamic>? ?? [];
        return imageList
            .map((img) => ImageInfo.fromJson(img as Map<String, dynamic>))
            .where((img) => img.url.isNotEmpty)
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching album art: $e');
      rethrow;
    }

    return [];
  }

  /// Get all available artist image URLs for a given artist
  Future<List<ImageInfo>> getArtistImage(String artist) async {
    final params = {
      'method': 'artist.getinfo',
      'api_key': apiKey,
      'artist': artist,
      'format': 'json',
    };

    try {
      final response = await _makeRequest(params);
      if (response != null && response['artist'] != null) {
        final imageList = response['artist']['image'] as List<dynamic>? ?? [];
        return imageList
            .map((img) => ImageInfo.fromJson(img as Map<String, dynamic>))
            .where((img) => img.url.isNotEmpty)
            .toList();
      }
    } catch (e) {
      // print('Error fetching artist image: $e');
      rethrow;
    }

    return [];
  }

  /// Get album art URL for a specific size (small, medium, large, extralarge, mega)
  Future<String?> getAlbumArtBySize(
    String artist,
    String album,
    String size,
  ) async {
    final images = await getAlbumArt(artist, album);
    return images
            .firstWhere(
              (img) => img.size == size,
              orElse: () => ImageInfo(size: '', url: ''),
            )
            .url
            .isEmpty
        ? null
        : images.firstWhere((img) => img.size == size).url;
  }

  /// Get artist image URL for a specific size (small, medium, large, extralarge, mega)
  Future<String?> getArtistImageBySize(String artist, String size) async {
    final images = await getArtistImage(artist);
    return images
            .firstWhere(
              (img) => img.size == size,
              orElse: () => ImageInfo(size: '', url: ''),
            )
            .url
            .isEmpty
        ? null
        : images.firstWhere((img) => img.size == size).url;
  }

  /// Get the largest available album art URL
  Future<String?> getLargestAlbumArt(String artist, String album) async {
    final images = await getAlbumArt(artist, album);
    if (images.isEmpty) return null;

    // Priority order for largest image
    const sizeOrder = ['mega', 'extralarge', 'large', 'medium', 'small'];

    for (final size in sizeOrder) {
      final image = images.firstWhere(
        (img) => img.size == size,
        orElse: () => ImageInfo(size: '', url: ''),
      );
      if (image.url.isNotEmpty) return image.url;
    }

    return images.first.url;
  }

  /// Get the largest available artist image URL
  Future<String?> getLargestArtistImage(String artist) async {
    final images = await getArtistImage(artist);
    if (images.isEmpty) return null;

    // Priority order for largest image
    const sizeOrder = ['mega', 'extralarge', 'large', 'medium', 'small'];

    for (final size in sizeOrder) {
      final image = images.firstWhere(
        (img) => img.size == size,
        orElse: () => ImageInfo(size: '', url: ''),
      );
      if (image.url.isNotEmpty) return image.url;
    }

    return images.first.url;
  }

  Future<Map<String, dynamic>?> _makeRequest(Map<String, String> params) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['error'] != null) {
          // print('Last.fm API Error: ${data['message']}');
          return null;
        }

        return data;
      } else {
        // print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // print('Request failed: $e');
      return null;
    }
  }
}
