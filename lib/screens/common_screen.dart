import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:vespera/elements/mini_music_player.dart';
import 'package:vespera/screens/home_screen.dart';
import 'package:vespera/screens/library_screen.dart';
import 'package:vespera/screens/playlist_detail_screen.dart';
import 'package:vespera/screens/search_screen.dart';
import 'package:vespera/screens/whisper_screen_refactored.dart';

class CommonScreen extends StatefulWidget {
  final int? initialIndex;
  
  const CommonScreen({super.key, this.initialIndex});

  @override
  State<CommonScreen> createState() => _CommonScreenState();
}

class _CommonScreenState extends State<CommonScreen> {
  late int _selectedIndex;

  // Navigator keys for each tab (except Whisper which opens separately)
  final GlobalKey<NavigatorState> _homeKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _searchKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _libraryKey = GlobalKey<NavigatorState>();

  int _safeTabIndex(int? index) {
    if (index == null) return 0;
    if (index < 0) return 0;
    if (index > 2) return 0;
    return index;
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = _safeTabIndex(widget.initialIndex);
  }
  Future<bool> _onWillPop() async {
    final keys = [_homeKey, _searchKey, _libraryKey];
    final currentKey = keys[_selectedIndex];
    if (currentKey.currentState?.canPop() ?? false) {
      currentKey.currentState!.pop();
      return false; // handled inside the tab
    }
    return true; // allow app to pop
  }

  void _openPlaylistInLibrary(String playlistId, String playlistName) {
    setState(() {
      _selectedIndex = 2;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _libraryKey.currentState?.push(
        MaterialPageRoute(
          builder:
              (_) => PlaylistDetailScreen(
                playlistId: playlistId,
                playlistName: playlistName,
              ),
        ),
      );
    });
  }

  void _openWhisper() {
    // Open Whisper as separate screen, remember current tab to restore on return
    final previousIndex = _selectedIndex;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WhisperScreen())).then((_) {
      // Restore the tab that was active before opening Whisper
      if (mounted) {
        setState(() {
          _selectedIndex = previousIndex;
        });
      }
    });
  }

  void _onItemTapped(int index) {
    // If tapping the same tab, pop to root
    if (index == _selectedIndex) {
      final keys = [_homeKey, _searchKey, _libraryKey];
      final navState = keys[index].currentState;
      if (navState?.canPop() ?? false) {
        navState!.popUntil((route) => route.isFirst);
      }
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  Navigator(
                    key: _homeKey,
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      builder:
                          (_) => HomeScreen(
                            onOpenPlaylistFromHome: _openPlaylistInLibrary,
                          ),
                    ),
                  ),
                  Navigator(
                    key: _searchKey,
                    onGenerateRoute: (settings) =>
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                  Navigator(
                    key: _libraryKey,
                    onGenerateRoute: (settings) =>
                        MaterialPageRoute(builder: (_) => const LibraryScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
        extendBody: false,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniMusicPlayer(),
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: GNav(
                          key: ValueKey<int>(_selectedIndex),
                          rippleColor: Colors.grey[800]!,
                          hoverColor: Colors.grey[900]!,
                          haptic: true,
                          tabBorderRadius: 15,
                          tabActiveBorder: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                          curve: Curves.easeInOut,
                          duration: const Duration(milliseconds: 300),
                          gap: 8,
                          color: Colors.grey[500],
                          activeColor: Colors.white,
                          iconSize: 24,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          tabBackgroundColor: Colors.white.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          selectedIndex: _selectedIndex,
                          onTabChange: _onItemTapped,
                          tabs: const [
                            GButton(
                              icon: Icons.home_rounded,
                              text: 'Home',
                            ),
                            GButton(
                              icon: Icons.search_rounded,
                              text: 'Search',
                            ),
                            GButton(
                              icon: Icons.library_music_rounded,
                              text: 'Library',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _openWhisper,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white.withOpacity(0.1),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Icon(
                            Icons.graphic_eq_rounded,
                            color: Colors.grey[500],
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}