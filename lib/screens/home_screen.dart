import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/components/home_screen_lib_item.dart';
import 'package:vespera/components/home_screen_rec_item.dart';
import 'package:vespera/models/playlist.dart';
import 'package:vespera/providers/user_provider.dart';
import 'package:vespera/screens/playlist_detail_screen.dart';
import 'package:vespera/services/auth_service.dart';
import 'package:vespera/services/playlist_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlaylistService _playlistService = PlaylistService();

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
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
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
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.settings, size: 30, color: AppColors.textPrimary),
              color: AppColors.backgroundDark,
              onSelected: (String value) {
                if (value == 'signOut') {
                  _handleSignOut();
                }
              },
              itemBuilder:
                  (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'signOut',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: AppColors.textPrimary),
                          SizedBox(width: 10),
                          Text('Sign Out', style: TextStyle(color: AppColors.textPrimary)),
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
            // DYNAMIC PLAYLISTS LOADED FROM DATABASE
            StreamBuilder<List<Playlist>>(
              stream: _playlistService.getUserPlaylistsTyped(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
                    child: Center(child: CircularProgressIndicator(color: AppColors.textPrimary)),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
                    child: Center(
                      child: Text(
                        'Error loading playlists',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }

                final allPlaylists = snapshot.data ?? [];
                // Limit to first 6 playlists
                final playlists = allPlaylists.take(6).toList();

                if (playlists.isEmpty) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
                    child: Center(
                      child: Text(
                        'No playlists yet. Create one to get started!',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                // Build playlist items in a grid layout (2 columns)
                List<Widget> playlistRows = [];
                for (int i = 0; i < playlists.length; i += 2) {
                  List<Widget> rowChildren = [];

                  // First item in the row
                  rowChildren.add(
                    HomeScreenLibItem(
                      screenHeight: screenHeight,
                      screenWidth: screenWidth,
                      playlist: playlists[i],
                      onTap: () {
                        print('\x1B[32mPlaylist tapped: ${playlists[i].name}\x1B[0m');
                        Navigator.of(context, rootNavigator: false).push(
                          MaterialPageRoute(
                            builder:
                                (context) => PlaylistDetailScreen(
                                  playlistId: playlists[i].id,
                                  playlistName: playlists[i].name,
                                ),
                          ),
                        );
                      },
                    ),
                  );

                  // Second item in the row (if exists)
                  if (i + 1 < playlists.length) {
                    rowChildren.add(
                      HomeScreenLibItem(
                        screenHeight: screenHeight,
                        screenWidth: screenWidth,
                        playlist: playlists[i + 1],
                        onTap: () {
                          print('\x1B[32mPlaylist tapped: ${playlists[i + 1].name}\x1B[0m');
                          Navigator.of(context, rootNavigator: false).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => PlaylistDetailScreen(
                                    playlistId: playlists[i + 1].id,
                                    playlistName: playlists[i + 1].name,
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    // Add empty container to maintain spacing
                    rowChildren.add(SizedBox(width: (screenWidth * 0.5) - 20));
                  }

                  playlistRows.add(
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: rowChildren),
                  );
                }

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(children: playlistRows),
                );
              },
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
