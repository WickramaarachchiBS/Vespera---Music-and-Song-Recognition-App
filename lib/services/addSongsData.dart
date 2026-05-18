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
        'album': 'Gini Malak',
        'title': 'Malata Suwanda Se',
        'titleLowercase': 'malata suwanda se',
        'artist': 'Sunil Edirisinghe',
        'artistLowercase': 'sunil edirisinghe',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/Sunil%20Edirisinghe%20-%20Malata%20Suwanda%20Se.mp3?updatedAt=1779018497232',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Malata%20Suwada%20Se.jpg',
        'duration': 213,
        'genre': 'Sri Lankan/Traditional',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'album': 'Pineapple Sunrise',
        'title': 'Sex, Drugs, Etc.',
        'titleLowercase': 'sex, drugs, etc.',
        'artist': 'Beach Weather',
        'artistLowercase': 'beach weather',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/Beach%20Weather%20-%20Sex,%20Drugs,%20Etc.mp3?updatedAt=1779018497323',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Sex,%20Drugs,%20Etc.jpg',
        'duration': 209,
        'genre': 'Alternative/Indie',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'album': 'Sweet Boy',
        'title': 'Mr. Incorrect',
        'titleLowercase': 'mr. incorrect',
        'artist': 'Malcolm Todd',
        'artistLowercase': 'malcolm todd',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/Malcolm%20Todd%20-%20Mr%20Incorrect.mp3?updatedAt=1779018497121',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Mr.%20Incorrect.jpg',
        'duration': 171,
        'genre': 'Alternative/Indie',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'album': 'Shoba',
        'title': 'Shoba',
        'titleLowercase': 'shoba',
        'artist': 'Bashi Devanga',
        'artistLowercase': 'bashi devanga',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/Bhashi%20Devanga%20-%20Shoba.mp3?updatedAt=1779019610873',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Shoba.jpg',
        'duration': 156,
        'genre': 'Sri Lankan/Traditional',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'album': 'Majboor',
        'title': 'Majboor',
        'titleLowercase': 'majboor',
        'artist': 'Sheheryar Rehan, Zoha Waseem',
        'artistLowercase': 'sheheryar rehan, zoha waseem',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/Sheheryar%20Rehan,%20Zoha%20Waseem%20-%20Majboor.mp3?updatedAt=1779018497052',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Majiboor.jpg',
        'duration': 159,
        'genre': 'Indian Pop',
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
        debugPrint('Title: ${song['title']}, Artist: ${song['artist']}');
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
