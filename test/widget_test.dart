// test/widget_test.dart
//
// Smoke test: verifies that a basic Flutter Material widget tree can be built
// and rendered without errors. Kept intentionally minimal because the full
// Vespera app requires Firebase initialisation which is unavailable in the
// unit-test environment.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp smoke test – renders without error',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Vespera')),
        ),
      ),
    );

    expect(find.text('Vespera'), findsOneWidget);
  });
}
