class DiscoveredSong {
  final String title;
  final String artist;
  final double? confidence;
  final String? imageUrl;
  final String? audioUrl;
  final DateTime discoveredAt;

  DiscoveredSong({
    required this.title,
    required this.artist,
    this.confidence,
    this.imageUrl,
    this.audioUrl,
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'confidence': confidence,
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'discoveredAt': discoveredAt.toIso8601String(),
      };

  factory DiscoveredSong.fromJson(Map<String, dynamic> json) => DiscoveredSong(
        title: json['title'] as String,
        artist: json['artist'] as String,
        confidence: json['confidence'] as double?,
        imageUrl: json['imageUrl'] as String?,
        audioUrl: json['audioUrl'] as String?,
        discoveredAt: DateTime.parse(json['discoveredAt'] as String),
      );
}