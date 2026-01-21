import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vespera/models/discovered_song.dart';

class DiscoveredSongsService {
  static const String _storageKey = 'discovered_songs';
  
  Future<List<DiscoveredSong>> getDiscoveredSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => DiscoveredSong.fromJson(json)).toList();
  }

  Future<void> addDiscoveredSong(DiscoveredSong song) async {
    final songs = await getDiscoveredSongs();
    
    // Check if song already exists (by title and artist)
    final exists = songs.any((s) => 
      s.title.toLowerCase() == song.title.toLowerCase() && 
      s.artist.toLowerCase() == song.artist.toLowerCase()
    );
    
    if (!exists) {
      songs.insert(0, song); // Add to beginning
      await _saveSongs(songs);
    }
  }

  Future<void> removeDiscoveredSong(int index) async {
    final songs = await getDiscoveredSongs();
    if (index >= 0 && index < songs.length) {
      songs.removeAt(index);
      await _saveSongs(songs);
    }
  }

  Future<void> clearAllSongs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _saveSongs(List<DiscoveredSong> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = songs.map((song) => song.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }
}