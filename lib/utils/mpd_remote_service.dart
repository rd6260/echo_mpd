import 'package:dart_mpd/dart_mpd.dart';
import 'package:flutter/foundation.dart';

class MpdRemoteService {
  MpdRemoteService._() {
    _initialize();
  }

  // Static instance created immediately
  static final MpdRemoteService _instance = MpdRemoteService._();

  static MpdRemoteService get instance => _instance;

  MpdClient? _client;
  final ValueNotifier<MpdSong?> currentSong = ValueNotifier(null);

  void _initialize() async {
    // Initialize the client first before using it
    _client = MpdClient(
      connectionDetails: MpdConnectionDetails(
        host: "192.168.252.3",
        port: 6600,
      ),
    );
    
    // Now it's safe to use the client
    currentSong.value = await _client!.currentsong();
    mpdStatusPoll();
  }

  void mpdStatusPoll() async {
    while (true) {
      Set<MpdSubsystem> idleResponse = await _client!.idle();
      for (var response in idleResponse) {
        debugPrint("DEV: mpd change | $response");
        if (response == MpdSubsystem.database) {
        } else if (response == MpdSubsystem.update) {
        } else if (response == MpdSubsystem.storedPlaylist) {
        } else if (response == MpdSubsystem.playlist) {
        } else if (response == MpdSubsystem.player) {
        } else if (response == MpdSubsystem.mixer) {
        } else if (response == MpdSubsystem.output) {
        } else if (response == MpdSubsystem.options) {
        } else if (response == MpdSubsystem.partition) {
        } else if (response == MpdSubsystem.sticker) {
        } else if (response == MpdSubsystem.subscription) {
        } else if (response == MpdSubsystem.message) {
        } else if (response == MpdSubsystem.neighbor) {
        } else if (response == MpdSubsystem.mount) {}
      }
    }
  }

  MpdClient get client {
    _client ??= MpdClient(
      connectionDetails: MpdConnectionDetails(
        host: "192.168.252.3",
        port: 6600,
      ),
    );
    return _client!;
  }
}