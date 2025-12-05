import 'package:cloud_firestore/cloud_firestore.dart';

class Playlist {
  final String id;
  final String name;
  final String imageUrl;
  final String userId;
  final DateTime? createdAt;

  const Playlist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.userId,
    required this.createdAt,
  });

  factory Playlist.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Playlist(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? '',
      imageUrl: (data['imageURL'] as String?)?.trim() ?? '',
      userId: (data['userId'] as String?)?.trim() ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageURL': imageUrl,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}