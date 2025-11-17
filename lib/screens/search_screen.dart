import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/models/song.dart';
import 'package:vespera/services/search_service.dart';
import 'dart:async';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  List<Song> _searchResults = [];
  bool _isLoading = false;
  List<Map<String, String>> recentSearches = [];

  // Debounce to avoid hitting Firestore on every keystroke
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
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

  void _addToRecent(Song song) {
    final item = {'title': song.title, 'artist': song.artist};
    // Remove any existing duplicate
    recentSearches.removeWhere(
      (e) => e['title'] == item['title'] && e['artist'] == item['artist'],
    );
    setState(() {
      recentSearches.insert(0, item);
      if (recentSearches.length > 10) {
        recentSearches.removeLast();
      }
    });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textPrimary, size: 25),
            onPressed: () {
              // Add songs to firebase function (TEMP)
              // debugPrint('Add song button pressed');
            },
          ),
        ],
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
                suffixIcon: _searchController.text.isNotEmpty
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
            child: hasQuery
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
                            separatorBuilder: (_, __) => Divider(
                              color: AppColors.textPrimary.withOpacity(0.08),
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              final song = _searchResults[index];
                              return ListTile(
                                leading: song.imageUrl != null && song.imageUrl!.isNotEmpty
                                    ? CircleAvatar(backgroundImage: NetworkImage(song.imageUrl!))
                                    : const CircleAvatar(
                                        child: Icon(Icons.music_note),
                                      ),
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
                                  // TODO: navigate to player or open song details
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
