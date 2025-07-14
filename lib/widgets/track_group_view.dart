import 'package:dart_mpd/dart_mpd.dart';
import 'package:echo_mpd/service/settings.dart';
import 'package:echo_mpd/utils/time_format_utils.dart';
import 'package:echo_mpd/widgets/playlist_tile.dart';
import 'package:flutter/material.dart';

class TrackGroupView extends StatelessWidget {
  final Widget artWork;
  final List<MpdSong> tracks;

  final String type;
  final String name;
  final String? artist;
  final String? year;

  const TrackGroupView({
    super.key,
    required this.artWork,
    required this.tracks,
    required this.type,
    required this.name,
    this.artist,
    this.year,
  });

  String _totalTime() {
    int time = 0;
    for (var track in tracks) {
      time += track.duration?.inSeconds ?? 0;
    }

    return secondsToTimeString(time);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // heading part
        SizedBox(
          height: 130,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadiusGeometry.all(Radius.circular(12)),
                child: SizedBox(height: 130, width: 130, child: artWork),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Center the text content
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            if (artist != null)
                              Text(
                                artist!,
                                style: const TextStyle(
                                  color: Color(Settings.primaryColor),
                                ),
                              ),
                            // Text(year!, style: const TextStyle(color: Colors.white)),
                            Row(
                              children: [
                                if (year != null)
                                  Text(
                                    "$year  •  ",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                Text(
                                  "${tracks.length.toString()} Tracks  •  ",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.grey,
                                  size: 12,
                                ),
                                // SizedBox(width: 2),
                                Text(
                                  " ${_totalTime()}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.repeat, color: Colors.white),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.shuffle, color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          GestureDetector(
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Color(Settings.primaryColor),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Divider
        Padding(
          padding: const EdgeInsetsGeometry.only(top: 16),
          child: Container(height: 1, color: const Color(0xFF262626)),
        ),

        // Track list
        Expanded(
          child: ListView.builder(
            itemCount: tracks.length,
            padding: EdgeInsets.only(top: 16),
            itemBuilder: (context, index) =>
                PlaylistTile(song: tracks[index], onTap: () {}),
          ),
        ),
      ],
    );
  }
}
