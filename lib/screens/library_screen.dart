import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // Sample list of songs/playlists
  final List<Map<String, String>> playlists = [
    {'title': 'My Playlist 1', 'artist': 'Artist Name', 'imagePath': 'assets/dandelion.jpg'},
    {'title': 'Top Hits', 'artist': 'Various Artists', 'imagePath': 'assets/daddyIssues.jpg'},
    {'title': 'Chill Vibes', 'artist': 'Various Artists', 'imagePath': 'assets/her.jpg'},
    {'title': 'Workout Mix', 'artist': 'DJ Mix', 'imagePath': 'assets/newJeans.jpg'},
    {'title': 'Road Trip', 'artist': 'Travel Songs', 'imagePath': 'assets/dandelion.jpg'},
    {'title': 'Study Session', 'artist': 'Lo-Fi Beats', 'imagePath': 'assets/daddyIssues.jpg'},
    {'title': 'Party Time', 'artist': 'Dance Hits', 'imagePath': 'assets/her.jpg'},
    {'title': 'Relaxing Tunes', 'artist': 'Calm Music', 'imagePath': 'assets/newJeans.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(
          'Your Library',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.textPrimary),
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 15.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: CircleAvatar(backgroundImage: AssetImage('assets/profilePic.jpg')),
          ),
        ),
        actions: [
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(right: 8.0),
                child: IconButton(
                  //USE A CUSTOM ICON FOR THIS
                  icon: const Icon(Icons.search_rounded, size: 30, color: AppColors.textPrimary),
                  // Handle settings button press
                  onPressed: () {},
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 8.0),
                child: IconButton(
                  //USE A CUSTOM ICON FOR THIS
                  icon: const Icon(Icons.add, size: 35, color: AppColors.textPrimary),
                  // Handle settings button press
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                  color: AppColors.textMuted.withOpacity(0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                  child: ListTile(
                    style: ListTileStyle.drawer,
                    // ADD DYNAMIC IMAGES FOR EACH PLAYLIST
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.asset(
                        playlists[index]['imagePath']!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      playlists[index]['title']!,
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      playlists[index]['artist']!,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
