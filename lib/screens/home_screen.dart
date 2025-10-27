import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/components/home_screen_lib_item.dart';
import 'package:vespera/components/home_screen_rec_item.dart';
import 'package:vespera/providers/user_provider.dart';
import 'package:vespera/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load user data only if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.username == 'User') {
        userProvider.loadUserData();
      }
    });
  }

  Future<void> _handleSignOut() async {
    // Clear user provider data
    Provider.of<UserProvider>(context, listen: false).clearUserData();
    
    // Sign out from AuthService
    await AuthService().signOut();
    
    // Navigate to welcome screen and remove all previous routes
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/welcome',
        (route) => false,
      );
    }
  }

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
        title: Text(
          'Hello ${Provider.of<UserProvider>(context).username}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppColors.textMuted,
          ),
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
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.settings, size: 30, color: AppColors.textPrimary),
              color: AppColors.backgroundDark,
              onSelected: (String value) {
                if (value == 'signout') {
                  _handleSignOut();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'signout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppColors.textPrimary),
                      SizedBox(width: 10),
                      Text(
                        'Sign Out',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
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
