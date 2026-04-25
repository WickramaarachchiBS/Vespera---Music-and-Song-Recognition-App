class DurationFormatter {
  static String formatDuration(Duration duration) {
    final totalHours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (totalHours > 0) return '${totalHours}h ${minutes}m';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    return '${duration.inSeconds}s';
  }
}
