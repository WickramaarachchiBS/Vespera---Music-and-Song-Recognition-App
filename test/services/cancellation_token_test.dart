// test/services/cancellation_token_test.dart
//
// Unit tests for RecognitionCancellationToken behaviour.

import 'package:flutter_test/flutter_test.dart';
import 'package:vespera/services/recognition/recognizers.dart';

void main() {
  group('RecognitionCancellationToken', () {
    test('isCancelled is false initially', () {
      final RecognitionCancellationToken token = RecognitionCancellationToken();
      expect(token.isCancelled, isFalse);
    });

    test('isCancelled becomes true after cancel()', () {
      final RecognitionCancellationToken token = RecognitionCancellationToken();
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test('calling cancel() twice does not throw', () {
      final RecognitionCancellationToken token = RecognitionCancellationToken();
      expect(() {
        token.cancel();
        token.cancel(); // second call must be a no-op
      }, returnsNormally);
    });

    test('throwIfCancelled() does not throw when not cancelled', () {
      final RecognitionCancellationToken token = RecognitionCancellationToken();
      expect(token.throwIfCancelled, returnsNormally);
    });

    test('throwIfCancelled() throws after cancel()', () {
      final RecognitionCancellationToken token = RecognitionCancellationToken();
      token.cancel();
      expect(() => token.throwIfCancelled(), throwsA(anything));
    });

    test('cancelled Future completes after cancel()', () async {
      final RecognitionCancellationToken token = RecognitionCancellationToken();
      bool completed = false;
      // ignore: unawaited_futures
      token.cancelled.then((_) => completed = true);
      token.cancel();
      // Allow microtask queue to drain
      await Future<void>.delayed(Duration.zero);
      expect(completed, isTrue);
    });
  });
}
