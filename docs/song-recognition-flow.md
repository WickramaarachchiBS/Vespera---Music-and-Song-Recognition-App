# Song Recognition Flow (Mobile)

This project now supports a dual-path recognition pipeline:

- Primary path: on-device peak extraction + JSON request to `/api/identify-peaks`
- Fallback path: legacy audio upload to `/api/identify` with `audio_file`

## Architecture

- `WhisperProvider.startRecordingAndIdentify()` remains the UI entrypoint.
- `WhisperService` records audio and delegates recognition to `RecognitionOrchestrator`.
- `RecognitionOrchestrator` selects strategy by runtime mode:
  - `peak_primary`: peak first, audio fallback on failure
  - `audio_only`: legacy audio upload only
  - `peak_only`: peak endpoint only (no fallback)

Default mode is `peak_primary`.

### New mobile recognition files

- `lib/services/recognition/recognition_config.dart`
- `lib/services/recognition/recognition_models.dart`
- `lib/services/recognition/peak_extractor.dart`
- `lib/services/recognition/recognizers.dart`

## Runtime configuration

Set recognizer mode using Dart define:

- `--dart-define=VESPER_RECOGNIZER_MODE=peak_primary`
- `--dart-define=VESPER_RECOGNIZER_MODE=audio_only`
- `--dart-define=VESPER_RECOGNIZER_MODE=peak_only`

Optional app version metadata:

- `--dart-define=VESPER_APP_VERSION=1.0.0`

## Backend contract used

### Peak endpoint (primary)

- Method: `POST`
- Path: `/api/identify-peaks`
- Content-Type: `application/json`

Request shape:

```json
{
  "schema_version": "1.0",
  "clip_duration_seconds": 10.0,
  "sample_rate_hz": 44100,
  "hop_size": 512,
  "window_size": 4096,
  "peaks": [{ "freq_idx": 123, "time_idx": 456 }],
  "client_meta": {
    "platform": "android_or_ios",
    "app_version": "x.y.z"
  }
}
```

### Audio endpoint (fallback)

- Method: `POST`
- Path: `/api/identify`
- Content-Type: `multipart/form-data`
- Field: `audio_file`

## Signal processing details

- Recording config targets `44100 Hz`, mono WAV (`16-bit PCM expected by parser`).
- Window size: `4096`
- Hop size: `512`
- STFT: Hann window + deterministic radix-2 FFT implementation
- Peak picking: local maxima over time-frequency neighborhood size `15`
- Amplitude threshold: `-60 dB`
- Frequency band: approximately `300 Hz` to `5000 Hz` bins
- Clip duration support: validates around `8s` to `15s` and trims to max duration

If device recording sample rate differs from `44100`, the app applies linear resampling to `44100` before extraction and reports source/output sample rates in logs.

## Validation and failure handling

Before POSTing peaks:

- Validate schema fields and numeric ranges
- Validate peak array non-empty and below max size
- Validate index bounds (`freq_idx`, `time_idx`)
- Enforce exact backend parameters in payload: `44100`, `4096`, `512`

Recognition reliability behavior:

- Peak request uses timeout and retry for transient failures
- If mode is `peak_primary`, failure or low-quality/no-match peak response triggers fallback to audio upload
- User cancellation stops recording and in-flight recognition requests

## Structured logging

Logs use `vespera.recognition` logger with JSON payloads, including:

- `request_bytes`
- `preprocessing_ms`
- `api_latency_ms`
- `total_ms`
- source/output sample rate and peak count where applicable
- first 20 peaks for backend contract debugging

## Reproducible A/B Runner

Use the CLI runner to compare peak endpoint against audio endpoint on the same clips.

Requirements:

- Provide at least 5 clips
- Clips should be WAV files representative of your production capture conditions

Run:

```bash
dart run tool/recognition_ab_runner.dart \
  --base-url https://vesper-song-recognition-hrd3bsgagre6adc0.centralindia-01.azurewebsites.net \
  --clip C:/path/clip1.wav \
  --clip C:/path/clip2.wav \
  --clip C:/path/clip3.wav \
  --clip C:/path/clip4.wav \
  --clip C:/path/clip5.wav
```

Output includes per-clip pass/fail and summary metrics:

- agreement rate with audio baseline
- average peak payload bytes
- average peak endpoint latency
- average audio endpoint latency

## Testing

Implemented tests:

- Payload validation + deterministic extraction:
  - `test/services/recognition_payload_test.dart`
- Fallback behavior (unit):
  - `test/services/recognizer_fallback_test.dart`
- Integration-style success and fallback:
  - `test/services/recognition_integration_test.dart`

Run:

```bash
flutter test test/services/recognition_payload_test.dart
flutter test test/services/recognizer_fallback_test.dart
flutter test test/services/recognition_integration_test.dart
```
