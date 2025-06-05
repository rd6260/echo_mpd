import 'package:dart_mpd/dart_mpd.dart';

class MpdRemoteService {
  MpdRemoteService._();

  static get instance => MpdRemoteService._();

  MpdClient? client;

  MpdClient getCliet() {
    if (client != null) return client!;
    return MpdClient(
      connectionDetails: MpdConnectionDetails(
        host: "192.168.252.3",
        port: 6600,
      ),
      // onConnect: () => print("DEV: Connected to mpd"),
    );
  }

  
}
