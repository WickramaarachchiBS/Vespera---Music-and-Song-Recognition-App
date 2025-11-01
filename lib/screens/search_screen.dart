import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Sample recent searches - replace with actual data from your database/storage
  List<Map<String, String>> recentSearches = [
    {'title': 'Blinding Lights', 'artist': 'The Weeknd'},
    {'title': 'Shape of You', 'artist': 'Ed Sheeran'},
    {'title': 'Levitating', 'artist': 'Dua Lipa'},
    {'title': 'Save Your Tears', 'artist': 'The Weeknd'},
    {'title': 'Peaches', 'artist': 'Justin Bieber'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.textPrimary),
        ),
        leading: Container(
          margin: EdgeInsets.only(left: 15.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: CircleAvatar(backgroundImage: AssetImage('assets/profilePic.jpg')),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.textPrimary, size: 25),
            onPressed: () {
              // Add songs to firebase function (TEMP)
              print('Add song button pressed');

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
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search for songs, artists...',
                hintStyle: TextStyle(color: AppColors.textPrimary.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: AppColors.textPrimary, size: 25),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear, color: AppColors.textPrimary),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
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
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Recent Searches Section
          Expanded(
            child:
                recentSearches.isEmpty
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
                              Text(
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
                                child: Text(
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
                              final song = recentSearches[index];
                              return ListTile(
                                leading: Icon(Icons.history, color: AppColors.textPrimary),
                                title: Text(
                                  song['title']!,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  song['artist']!,
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
                                  // Handle song selection
                                  _searchController.text = song['title']!;
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
