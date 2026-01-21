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
        'album': '',
        'title': '18 Wannam',
        'titleLowercase': '18 wannam',
        'artist': 'Yuki Navaratne, Ravi Jay.',
        'artistLowercase': 'yuki navaratne ravi jay.',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/Yuki%20Navaratne,%20Ravi%20Jay%20-%2018%20Wannam.mp3?updatedAt=1768980911377',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/18%20Wannam%20-%20Yuki%20Nawarathen,%20Ravi%20Jay.jpg',
        'duration': 205,
        'genre': 'Pop',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'album': 'Bambara Pahasa',
        'title': 'Sande Oba',
        'titleLowercase': 'sande oba',
        'artist': 'Rookantha Gunathilake',
        'artistLowercase': 'rookantha gunathilake',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/Sande_Oba_Aida_Me_Yame_Rookantha_Gunathilaka_Sarigama_lk.mp3?updatedAt=1768980747800',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Sande%20Oba%20-%20Rookantha%20Goonathilake.jpg',
        'duration': 200,
        'genre': 'Sinhala Pop',
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
