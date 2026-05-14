class DiscoveredSong {
  final String title;
  final String artist;
  final double? confidence;
  final int? matchCount;
  final int? queriedPeakCount;
  final String? imageUrl;
  final String? audioUrl;
  final DateTime discoveredAt;

  DiscoveredSong({
    required this.title,
    required this.artist,
    this.confidence,
    this.matchCount,
    this.queriedPeakCount,
    this.imageUrl,
    this.audioUrl,
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'confidence': confidence,
        'matchCount': matchCount,
        'queriedPeakCount': queriedPeakCount,
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'discoveredAt': discoveredAt.toIso8601String(),
      };

  factory DiscoveredSong.fromJson(Map<String, dynamic> json) => DiscoveredSong(
        title: json['title'] as String,
        artist: json['artist'] as String,
        confidence: json['confidence'] as double?,
        matchCount: json['matchCount'] is int ? json['matchCount'] as int : (json['matchCount'] != null ? int.tryParse(json['matchCount'].toString()) : null),
        queriedPeakCount: json['queriedPeakCount'] is int ? json['queriedPeakCount'] as int : (json['queriedPeakCount'] != null ? int.tryParse(json['queriedPeakCount'].toString()) : null),
        imageUrl: json['imageUrl'] as String?,
        audioUrl: json['audioUrl'] as String?,
        discoveredAt: DateTime.parse(json['discoveredAt'] as String),
      );
}