import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/components/home_screen_lib_item.dart';
import 'package:vespera/components/home_screen_rec_item.dart';
import 'package:vespera/components/song_recommendation_item.dart';
import 'package:vespera/models/playlist.dart';
import 'package:vespera/models/song.dart';
import 'package:vespera/providers/user_provider.dart';
import 'package:vespera/screens/playlist_detail_screen.dart';
import 'package:vespera/screens/profile_screen.dart';
import 'package:vespera/services/auth_service.dart';
import 'package:vespera/services/playlist_service.dart';
import 'package:vespera/services/recommendation_service.dart';
import 'package:vespera/services/audio_service.dart';

class HomeScreen extends StatefulWidget {
  final void Function(String playlistId, String playlistName)? onOpenPlaylistFromHome;

  const HomeScreen({super.key, this.onOpenPlaylistFromHome});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlaylistService _playlistService = PlaylistService();
  final RecommendationService _recommendationService = RecommendationService();

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

  // Navigate to profile screen
  void _handleProfile() {
    Navigator.of(context, rootNavigator: false).push(
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  // Clear user provider data and sign out
  Future<void> _handleSignOut() async {
    Provider.of<UserProvider>(context, listen: false).clearUserData();
    await AuthService().signOut();
  }

  // Play a song using the audio service
  void _playSong(Song song, List<Song> playlist) async {
    try {
      final audioService = AudioService();
      final songIndex = playlist.indexWhere((s) => s.id == song.id);
      if (songIndex != -1) {
        await audioService.playSongs(playlist: playlist, startIndex: songIndex, playlistName: 'Your Library');
      } else {
        // If song not in playlist, play as single song
        await audioService.playSong(
          audioUrl: song.audioUrl,
          title: song.title,
          artist: song.artist,
          imageUrl: song.imageUrl,
          playSource: 'Your Library',
        );
      }
    } catch (e) {
      print('Error playing song: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing song: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    String username = Provider.of<UserProvider>(context).username;
    String capitalizedUsername = username.isEmpty ? '' : username[0].toUpperCase() + username.substring(1);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(
          'Hello $capitalizedUsername',
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
              icon: const Icon(Icons.more_vert_rounded, size: 25, color: AppColors.textMuted),
              color: AppColors.backgroundDark,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              onSelected: (String value) {
                switch
                (value) {
                  case 'profile':
                   _handleProfile();
                    break;
                  case 'signOut':
                    _handleSignOut();
                    break;
                }
              },
              itemBuilder:
                  (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: AppColors.textPrimary),
                          SizedBox(width: 10),
                          Text('My Profile', style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
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
                        final openInLibrary = widget.onOpenPlaylistFromHome;
                        if (openInLibrary != null) {
                          openInLibrary(playlists[i].id, playlists[i].name);
                          return;
                        }
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
                          final openInLibrary = widget.onOpenPlaylistFromHome;
                          if (openInLibrary != null) {
                            openInLibrary(playlists[i + 1].id, playlists[i + 1].name);
                            return;
                          }
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
            const SizedBox(height: 15.0),
            // RECOMMENDED SONGS SECTION
            Container(
              alignment: Alignment.bottomLeft,
              margin: const EdgeInsets.only(left: 18.0),
              child: const Text(
                'Recommended for You',
                style: TextStyle(
                  fontSize: 21.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            StreamBuilder<List<Song>>(
              stream: _recommendationService.getRecommendedSongs(limit: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 200,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.textPrimary),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    margin: const EdgeInsets.all(15.0),
                    child: const Text(
                      'Error loading recommendations',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                final songs = snapshot.data ?? [];

                if (songs.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(15.0),
                    child: const Text(
                      'No recommendations available',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: songs
                        .map(
                          (song) => SongRecommendationItem(
                            song: song,
                            onTap: () => _playSong(song, songs),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10.0),
            // POPULAR SONGS SECTION
            Container(
              alignment: Alignment.bottomLeft,
              margin: const EdgeInsets.only(left: 18.0),
              child: const Text(
                'Popular Right Now',
                style: TextStyle(
                  fontSize: 21.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            StreamBuilder<List<Song>>(
              stream: _recommendationService.getPopularSongs(limit: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 200,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.textPrimary),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const SizedBox.shrink();
                }

                final songs = snapshot.data ?? [];
                if (songs.isEmpty) {
                  return const SizedBox.shrink();
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: songs
                        .map(
                          (song) => SongRecommendationItem(
                            song: song,
                            onTap: () => _playSong(song, songs),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10.0),
            // RECOMMENDED PLAYLISTS SECTION
            Container(
              alignment: Alignment.bottomLeft,
              margin: const EdgeInsets.only(left: 18.0),
              child: const Text(
                'Featured Playlists',
                style: TextStyle(
                  fontSize: 21.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            StreamBuilder<List<Playlist>>(
              stream: _recommendationService.getRecommendedPlaylists(limit: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 200,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.textPrimary),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    margin: const EdgeInsets.all(15.0),
                    child: const Text(
                      'Error loading playlists',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                final playlists = snapshot.data ?? [];

                if (playlists.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(15.0),
                    child: const Text(
                      'No featured playlists available',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: playlists
                        .map(
                          (playlist) => GestureDetector(
                            onTap: () {
                              final openInLibrary = widget.onOpenPlaylistFromHome;
                              if (openInLibrary != null) {
                                openInLibrary(playlist.id, playlist.name);
                                return;
                              }
                              Navigator.of(context, rootNavigator: false).push(
                                MaterialPageRoute(
                                  builder: (context) => PlaylistDetailScreen(
                                    playlistId: playlist.id,
                                    playlistName: playlist.name,
                                  ),
                                ),
                              );
                            },
                            child: HomeScreenRecItem(
                              title: playlist.name,
                              imageAsset: playlist.imageUrl.isNotEmpty
                                  ? playlist.imageUrl
                                  : 'assets/playlistImages/default.png',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
