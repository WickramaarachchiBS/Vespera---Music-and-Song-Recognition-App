import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/components/home_screen_lib_item.dart';
import 'package:vespera/components/home_screen_rec_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //sample data - replace with real data from API/database
  final List<Map<String, String>> recommendations = [
    {'title': 'Chill Evening', 'image': 'assets/her.jpg'},
    {'title': 'Workout Mix', 'image': 'assets/newJeans.jpg'},
    {'title': 'Study Focus', 'image': 'assets/daddyIssues.jpg'},
    {'title': 'Party Hits', 'image': 'assets/dandelion.jpg'},
    {'title': 'Morning Boost', 'image': 'assets/her.jpg'},
    {'title': 'Acoustic Vibes', 'image': 'assets/newJeans.jpg'},
  ];

  final List<Map<String, String>> recentPlaylists = [
    {'title': 'My Favorites', 'image': 'assets/newJeans.jpg'},
    {'title': 'Daily Mix', 'image': 'assets/her.jpg'},
    {'title': 'Road Trip', 'image': 'assets/dandelion.jpg'},
    {'title': 'Relaxing Tunes', 'image': 'assets/daddyIssues.jpg'},
    {'title': 'Top Hits', 'image': 'assets/newJeans.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(
          'Hello Banuka',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textMuted),
        ),
        leading: Container(
          margin: EdgeInsets.only(left: 15.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: CircleAvatar(backgroundImage: AssetImage('assets/profilePic.jpg')),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8.0),
            child: IconButton(
              //USE A CUSTOM ICON FOR THIS
              icon: const Icon(Icons.settings, size: 30, color: AppColors.textPrimary),
              // Handle settings button press
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                children: [
                  //LIBRARY ITEMS MUST BE AUTOMATED ACCORDING TO NO.OF PLAYLISTS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HomeScreenLibItem(screenHeight: screenHeight, screenWidth: screenWidth),
                      HomeScreenLibItem(screenHeight: screenHeight, screenWidth: screenWidth),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HomeScreenLibItem(screenHeight: screenHeight, screenWidth: screenWidth),
                      HomeScreenLibItem(screenHeight: screenHeight, screenWidth: screenWidth),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HomeScreenLibItem(screenHeight: screenHeight, screenWidth: screenWidth),
                      HomeScreenLibItem(screenHeight: screenHeight, screenWidth: screenWidth),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.0),
            // TEXT FOR RECOMMENDED ITEMS
            Container(
              alignment: Alignment.bottomLeft,
              margin: EdgeInsets.only(left: 18.0),
              child: Text(
                'More of what you like',
                style: TextStyle(
                  fontSize: 21.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // RECOMMENDATION ITEMS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    recommendations
                        .map(
                          (item) =>
                              HomeScreenRecItem(title: item['title']!, imageAsset: item['image']!),
                        )
                        .toList(),
              ),
            ),
            SizedBox(height: 10.0),
            // TEXT FOR RECENT PLAYLIST ITEMS
            Container(
              alignment: Alignment.bottomLeft,
              margin: EdgeInsets.only(left: 18.0),
              child: Text(
                'Recent Playlists',
                style: TextStyle(
                  fontSize: 21.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // RECENT PLAYLIST ITEMS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    recentPlaylists
                        .map(
                          (item) =>
                              HomeScreenRecItem(title: item['title']!, imageAsset: item['image']!),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
