import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String duration; // kept as string to match your data
  final String imageUrl;
  final String audioUrl;
  final String titleLowercase;
  final String artistLowercase;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.imageUrl,
    required this.audioUrl,
    required this.titleLowercase,
    required this.artistLowercase,
  });

  factory Song.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final title = (data['title'] as String? ?? '').trim();
    final artist = (data['artist'] as String? ?? '').trim();
    
    return Song(
      id: doc.id,
      title: (data['title'] as String?)?.trim() ?? 'Unknown Title',
      artist: (data['artist'] as String?)?.trim() ?? 'Unknown Artist',
      album: (data['album'] as String?)?.trim() ?? '',
      duration: (data['duration'] as String?)?.trim() ?? '0:00',
      imageUrl: (data['imageURL'] as String?)?.trim() ?? '',
      audioUrl: (data['audioUrl'] as String?)?.trim() ?? '',
      titleLowercase: (data['titleLowercase'] as String?) ?? title.toLowerCase(),
      artistLowercase: (data['artistLowercase'] as String?) ?? artist.toLowerCase(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'imageURL': imageUrl,
      'audioURL': audioUrl,
      'titleLowercase': title.toLowerCase(),
      'artistLowercase': artist.toLowerCase(),
    };
  }
}