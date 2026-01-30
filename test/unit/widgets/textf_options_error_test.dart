// Tests for TextfOptions error paths and edge cases.

// ignore_for_file: avoid-late-keyword

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/widgets/textf_options.dart';

void main() {
  group('TextfOptions Error Handling', () {
    testWidgets('TextfOptions.of throws when no ancestor exists', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        () => TextfOptions.of(capturedContext),
        throwsA(isA<FlutterError>()),
        reason: 'Should throw FlutterError when no TextfOptions ancestor exists',
      );
    });

    testWidgets('TextfOptions.maybeOf returns null when no ancestor exists', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final result = TextfOptions.maybeOf(capturedContext);

      expect(result, isNull);
    });

    testWidgets('updateShouldNotify returns true when styles differ', (tester) async {
      const options1 = TextfOptions(
        boldStyle: TextStyle(color: Colors.red),
        child: SizedBox.shrink(),
      );
      const options2 = TextfOptions(
        boldStyle: TextStyle(color: Colors.blue),
        child: SizedBox.shrink(),
      );

      expect(options1.updateShouldNotify(options2), isTrue);
    });

    testWidgets('updateShouldNotify returns false when styles match', (tester) async {
      const options1 = TextfOptions(
        boldStyle: TextStyle(color: Colors.red),
        child: SizedBox.shrink(),
      );
      const options2 = TextfOptions(
        boldStyle: TextStyle(color: Colors.red),
        child: SizedBox.shrink(),
      );

      expect(options1.updateShouldNotify(options2), isFalse);
    });

    testWidgets('hasSameStyle returns true for identical options', (tester) async {
      const options = TextfOptions(
        boldStyle: TextStyle(fontWeight: FontWeight.w900),
        linkMouseCursor: SystemMouseCursors.click,
        child: SizedBox.shrink(),
      );

      expect(options.hasSameStyle(options), isTrue);
    });
  });
}
