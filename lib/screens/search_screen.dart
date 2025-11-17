import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/models/song.dart';
import 'package:vespera/services/search_service.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vespera/services/audio_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  final AudioService _audioService = AudioService();
  List<Song> _searchResults = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> recentSearches = [];

  // Debounce to avoid hitting Firestore on every keystroke
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _playPlaylist(List<Song> songs, int startIndex) async {
    await _audioService.playSongs(playlist: songs, startIndex: startIndex);
  }

  Future<void> _loadRecentSearches() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final recent = await _searchService.getRecentSongSearches(userId);
      if (mounted) {
        setState(() {
          recentSearches = recent;
          print('recentSearches loaded: ${recentSearches.length} items');
        });
      }
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    final results = await _searchService.searchSongs(query);
    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final q = value.trim();
      if (q.isEmpty) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      } else {
        _performSearch(q);
      }
    });
  }

  Future<void> _addToRecent(Song song) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Save to Firestore
    await _searchService.addRecentSongSearch(userId: userId, song: song);

    // Reload recent searches to update UI
    await _loadRecentSearches();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.textPrimary),
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 15.0),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.0),
            child: CircleAvatar(backgroundImage: AssetImage('assets/profilePic.jpg')),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search for songs, artists...',
                hintStyle: TextStyle(color: AppColors.textPrimary.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: AppColors.textPrimary, size: 25),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textPrimary),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchResults = [];
                              _isLoading = false;
                            });
                          },
                        )
                        : null,
                filled: true,
                fillColor: AppColors.textPrimary.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: _performSearch,
            ),
          ),

          // Results or Recent Searches
          Expanded(
            child:
                hasQuery
                    ? _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(color: AppColors.accentBlue),
                        )
                        : _searchResults.isEmpty
                        ? Center(
                          child: Text(
                            'No results found',
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                        )
                        : ListView.separated(
                          itemCount: _searchResults.length,
                          separatorBuilder:
                              (_, __) => Divider(
                                color: AppColors.textPrimary.withOpacity(0.08),
                                height: 1,
                              ),
                          itemBuilder: (context, index) {
                            final song = _searchResults[index];
                            return ListTile(
                              leading:
                                  song.imageUrl != null && song.imageUrl!.isNotEmpty
                                      ? CircleAvatar(backgroundImage: NetworkImage(song.imageUrl!))
                                      : const CircleAvatar(child: Icon(Icons.music_note)),
                              title: Text(
                                song.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                song.artist,
                                style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7)),
                              ),
                              onTap: () {
                                _addToRecent(song);

                                if (song.audioUrl.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Audio URL missing for this song'),
                                    ),
                                  );
                                  return;
                                }
                                print(song.title);
                                print(song.artist);
                                print(song.audioUrl);
                                _playPlaylist([song], 0);
                              },
                            );
                          },
                        )
                    : recentSearches.isEmpty
                    ? Center(
                      child: Text(
                        'No recent searches',
                        style: TextStyle(
                          color: AppColors.textPrimary.withOpacity(0.5),
                          fontSize: 16,
                        ),
                      ),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Searches',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    recentSearches.clear();
                                  });
                                },
                                child: const Text(
                                  'Clear All',
                                  style: TextStyle(color: AppColors.accentBlue),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: recentSearches.length,
                            itemBuilder: (context, index) {
                              final item = recentSearches[index];
                              return ListTile(
                                leading: const Icon(Icons.history, color: AppColors.textPrimary),
                                title: Text(
                                  item['title']!,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  item['artist']!,
                                  style: TextStyle(color: AppColors.textPrimary.withOpacity(0.6)),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: AppColors.textPrimary.withOpacity(0.6),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      recentSearches.removeAt(index);
                                    });
                                  },
                                ),
                                onTap: () {
                                  _searchController.text = item['title']!;
                                  _onSearchChanged(item['title']!);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
