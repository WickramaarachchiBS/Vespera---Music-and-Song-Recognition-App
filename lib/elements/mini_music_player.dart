import 'package:flutter/material.dart';
import 'package:vespera/elements/music_player.dart';
import 'package:vespera/helpers/slide_up_music_player.dart';

class MiniMusicPlayer extends StatefulWidget {
  const MiniMusicPlayer({super.key});

  @override
  State<MiniMusicPlayer> createState() => _MiniMusicPlayerState();
}

class _MiniMusicPlayerState extends State<MiniMusicPlayer> {
  @override
  Widget build(BuildContext context) {
    // GestureDetector allows the whole container to be tappable
    return GestureDetector(
      onTap: () {
        // Navigate to the full-screen player
        Navigator.push(context, SlideUpPageRoute(page: const PlayerScreen()));
        print('Mini Player Tapped!');
      },
      child: Container(
        height: 60,
        color: Colors.blueGrey[900], // A nice dark color for the player
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  ClipRRect(
                    // Added ClipRRect here
                    borderRadius: BorderRadius.all(Radius.circular(4)), // Adjust radius as desired
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image(
                        image: AssetImage('assets/newJeans.jpg'), // Add a placeholder album art
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  // Song Title and Artist
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Song Title',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 5),
                          Text('Artist Name', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      Text(
                        'Playing Device Icon/Device Name',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Play/Pause Button
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.pause, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}
