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
        'album': 'METRO BOOMIN PRESENTS SPIDER-MAN: ACROSS THE SPIDER-VERSE',
        'title': 'Am I Dreaming',
        'titleLowercase': 'am i dreaming',
        'artist': 'A\$AP Rocky, Metro Boomin, and Roisee',
        'artistLowercase': 'a\$ap rocky, metro boomin, and roisee',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/Metro%20Boomin,%20ASAP%20Rocky,%20Roisee%20-%20Am%20I%20Dreaming.mp3',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Am%20I%20Dreaming%20-%20Metro%20Boomin,%20ASAP%20Rocky,%20Roisee%20(1).jpg',
        'duration': 0,
        'genre': 'R&B/Soul',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'album': 'THE CASTLE NEVER FALLS',
        'title': 'LET THE WORLD BURN',
        'titleLowercase': 'let the world burn',
        'artist': 'Chris Grey',
        'artistLowercase': 'chris grey',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/Chris-Grey%20-%20LET%20THE%20WORLD%20BURN.mp3?updatedAt=1770816194184',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Let%20The%20World%20Burn%20-%20Chris%20Grey.jpg?updatedAt=1770816643220',
        'duration': 0,
        'genre': 'Contemporary R&B',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'album': 'BEAUTIFUL CHAOS: The Remixes',
        'title': 'Gabriela',
        'titleLowercase': 'gabriela',
        'artist': 'KATSEYE',
        'artistLowercase': 'katseye',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/KATSEYE%20-%20Gabriela.mp3?updatedAt=1770816178168',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Gabriela%20-%20KATSEYE.jpg?updatedAt=1770816643221',
        'duration': 0,
        'genre': 'Rhythm and blues, Latin music',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'album': 'Still With You',
        'title': 'Still With You',
        'titleLowercase': 'still with you',
        'artist': 'Jung Kook',
        'artistLowercase': 'jung kook',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/Chris-Grey%20-%20LET%20THE%20WORLD%20BURN.mp3?updatedAt=1770816194184',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Let%20The%20World%20Burn%20-%20Chris%20Grey.jpg?updatedAt=1770816643220',
        'duration': 0,
        'genre': 'Rhythm and blues',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'album': 'JUST A BOY',
        'title': 'JUST A BOY',
        'titleLowercase': 'just a boy',
        'artist': 'DrINsaNE',
        'artistLowercase': 'drinsane',
        'audioUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/Music/DrINsaNE%20-%20JUST%20A%20BOY.mp3?updatedAt=1770816187101',
        'imageUrl':
            'https://ik.imagekit.io/k0z60e3cq/Vesper/MusicCovers/Just%20A%20Boy%20-%20DrINsaNE.jpg?updatedAt=1770816643172',
        'duration': 0,
        'genre': 'Pop',
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
