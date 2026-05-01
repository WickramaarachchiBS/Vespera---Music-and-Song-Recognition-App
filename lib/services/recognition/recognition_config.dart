enum RecognizerMode { peakPrimary, audioOnly, peakOnly }

class RecognitionConfig {
  final Uri peakEndpoint;
  final Uri audioEndpoint;
  final RecognizerMode mode;
  final Duration apiTimeout;
  final int retryCount;
  final bool enableGzipForLargePayload;
  final int targetSampleRateHz;
  final int windowSize;
  final int hopSize;
  final int localMaxNeighborhoodSize;
  final double minAmplitudeDb;
  final double minFrequencyHz;
  final double maxFrequencyHz;
  final int maxPeaks;
  final double minDurationSeconds;
  final double maxDurationSeconds;
  final int minPeakMatchCountForAcceptance;
  final double minPeakConfidenceForAcceptance;
  final String schemaVersion;
  final String appVersion;

  const RecognitionConfig({
    required this.peakEndpoint,
    required this.audioEndpoint,
    required this.mode,
    this.apiTimeout = const Duration(seconds: 20),
    this.retryCount = 0,
    this.enableGzipForLargePayload = false,
    this.targetSampleRateHz = 44100,
    this.windowSize = 4096,
    this.hopSize = 512,
    this.localMaxNeighborhoodSize = 10,
    this.minAmplitudeDb = 10.0,
    this.minFrequencyHz = 300.0,
    this.maxFrequencyHz = 5000.0,
    this.maxPeaks = 3500,
    this.minDurationSeconds = 8.0,
    this.maxDurationSeconds = 15.0,
    this.minPeakMatchCountForAcceptance = 5,
    this.minPeakConfidenceForAcceptance = 0.0,
    this.schemaVersion = '1.0',
    this.appVersion = '1.0.0',
  });

  static RecognizerMode modeFromEnvironment() {
    const String raw = String.fromEnvironment(
      'VESPER_RECOGNIZER_MODE',
      defaultValue: 'peak_only',
    );
    switch (raw.trim().toLowerCase()) {
      case 'audio_only':
        return RecognizerMode.audioOnly;
      case 'peak_only':
        return RecognizerMode.peakOnly;
      case 'peak_primary':
      default:
        return RecognizerMode.peakPrimary;
    }
  }
}
