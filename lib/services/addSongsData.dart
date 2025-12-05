import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Adds a few sample songs to Firestore for testing.
class AddSongsData {
  /// Adds a few sample songs to Firestore for testing.
  static Future<void> addSampleSongs(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final songsColl = firestore.collection('songs');

    final sampleSongs = <Map<String, dynamic>>[
      {
        'album': 'Speak for Yourself',
        'title': 'Headlock',
        'artist': 'Imogen Heap.',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/Headlock%20-%20Imogen%20Heap.mp3?updatedAt=1762086248780',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Headlock%20-%20Imogen%20Heap.jpg?updatedAt=1762086265374',
        'duration': 205,
        'genre': 'Pop',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'album': 'Xscape',
        'title': 'Chicago',
        'artist': 'Michael Jackson',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/Michael_Jackson%20-%20Chicago.mp3?updatedAt=1762086888663',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Chicago%20-%20Michael%20Jackson.jpg?updatedAt=1762086895823',
        'duration': 200,
        'genre': 'Synthwave',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    try {
      final batch = firestore.batch();
      int addedCount = 0;

      for (final s in sampleSongs) {
        final id = '${s['title']}--${s['artist']}'.toLowerCase().replaceAll(RegExp(r'\s+'), '-');

        final docRef = songsColl.doc(id);
        final existing = await docRef.get();

        if (existing.exists) {
          debugPrint('✅ Skipping existing: ${s['title']} by ${s['artist']}');
          continue;
        }

        batch.set(docRef, s, SetOptions(merge: true));
        addedCount++;
        debugPrint('➕ Adding: ${s['title']} by ${s['artist']}');
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$addedCount sample songs added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      debugPrint('🎵 Successfully added $addedCount songs to database');
    } catch (e) {
      debugPrint('❌ Error adding sample songs: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
