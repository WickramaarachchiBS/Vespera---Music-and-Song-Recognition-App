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
        'album': 'Deadbeat',
        'title': 'Dracula',
        'titleLowercase': 'dracula',
        'artist': 'Tame Impala',
        'artistLowercase': 'tame impala',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/Tame%20Impala%20-%20Dracula.mp3?updatedAt=1775548248976',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Dracula.jpg',
        'duration': 205,
        'genre': 'Indie',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'album': 'Currents',
        'title': 'The Less I Know The Better',
        'titleLowercase': 'the less i know the better',
        'artist': 'Tame Impala',
        'artistLowercase': 'tame impala',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/Tame%20Impala%20-%20The%20Less%20I%20Know%20The%20Better.mp3?updatedAt=1775548249741',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/The%20less%20i%20know%20the%20better.jpg',
        'duration': 217,
        'genre': 'Funk/Indie/Pop/Disco',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'album': 'Her',
        'title': 'Her',
        'titleLowercase': 'her',
        'artist': 'American Dawn',
        'artistLowercase': 'american dawn',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/The%20American%20Dawn%20-%20Her.mp3?updatedAt=1775548251542',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Her.jpg',
        'duration': 214,
        'genre': 'Rock/Indie',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'album': 'Dawn FM',
        'title': 'Is There Someone Else?',
        'titleLowercase': 'is there someone else?',
        'artist': 'The Weeknd',
        'artistLowercase': 'the weeknd',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/The%20Weeknd%20-%20Is%20There%20Someone%20Else.mp3?updatedAt=1775548251292',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Is%20there%20someone%20else.jpg',
        'duration': 199,
        'genre': 'R&B/Soul',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'album': 'Starboy',
        'title': 'Starboy',
        'titleLowercase': 'starboy',
        'artist': 'The Weeknd, Daft Punk',
        'artistLowercase': 'the weeknd, daft punk',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/The%20Weeknd,%20Daft%20Punk%20-%20Starboy.mp3?updatedAt=1775548251219',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Starboy.jpg',
        'duration': 230,
        'genre': 'R&B/Pop',
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

  static Future<void> displayALlSongsWithNameAndLink(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final songsColl = firestore.collection('songs');

    try {
      final snapshot = await songsColl.get();
      final songs = snapshot.docs.map((doc) => doc.data()).toList();

      debugPrint('🎶 All Songs in Database:');
      for (final song in songs) {
        debugPrint('Title: ${song['title']}, Artist: ${song['artist']}, URL: ${song['audioUrl']}');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check console for all songs with names and links')),
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching songs: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
