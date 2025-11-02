import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String duration; // kept as string to match your data
  final String imageUrl;
  final String audioUrl;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.imageUrl,
    required this.audioUrl,
  });

  factory Song.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Song(
      id: doc.id,
      title: (data['title'] as String?)?.trim() ?? 'Unknown Title',
      artist: (data['artist'] as String?)?.trim() ?? 'Unknown Artist',
      album: (data['album'] as String?)?.trim() ?? '',
      duration: (data['duration'] as String?)?.trim() ?? '0:00',
      imageUrl: (data['imageURL'] as String?)?.trim() ?? '',
      audioUrl: (data['audioUrl'] as String?)?.trim() ?? '',
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
    };
  }
}