import 'package:flutter/material.dart';
import 'package:dot_navigation_bar/dot_navigation_bar.dart';
import 'package:vespera/elements/mini_music_player.dart';
import 'package:vespera/screens/home_screen.dart';
import 'package:vespera/screens/library_screen.dart';
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
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;
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

  void _onItemTapped(int index) {
    if (index == 3) {
      // Open Whisper as separate screen
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WhisperScreen()));
      return;
    }
    
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
                    onGenerateRoute: (settings) =>
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
            const MiniMusicPlayer(),
          ],
        ),
        extendBody: true,
        bottomNavigationBar: DotNavigationBar(
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 16,
          ),
          backgroundColor: Colors.black,
          selectedItemColor: Colors.transparent,
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          marginR: const EdgeInsets.only(left: 20, right: 20, bottom: 0),
          paddingR: const EdgeInsets.only(left: 10, right: 10, top: 6, bottom: 6),
          curve: Curves.bounceInOut,
          items: [
            DotNavigationBarItem(
              icon: const Icon(Icons.home),
              selectedColor: Colors.white,
            ),
            DotNavigationBarItem(
              icon: const Icon(Icons.search),
              selectedColor: Colors.white,
            ),
            DotNavigationBarItem(
              icon: const Icon(Icons.library_music),
              selectedColor: Colors.white,
            ),
            DotNavigationBarItem(
              icon: const Icon(Icons.earbuds),
              selectedColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}