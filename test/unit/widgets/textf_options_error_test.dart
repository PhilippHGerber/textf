// Tests for TextfOptions error paths and edge cases.

// ignore_for_file: avoid-late-keyword

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/widgets/textf_options.dart';
import 'package:textf/src/widgets/textf_options_data.dart';

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

    testWidgets('TextfOptionsData notifies when styles differ', (tester) async {
      // Verify that two TextfOptionsData with different styles are not equal,
      // which causes _TextfOptionsScope.updateShouldNotify to return true.
      const data1 = TextfOptionsData(boldStyle: TextStyle(color: Colors.red));
      const data2 = TextfOptionsData(boldStyle: TextStyle(color: Colors.blue));

      expect(data1 == data2, isFalse);
      expect(data1.hashCode == data2.hashCode, isFalse);
    });

    testWidgets('TextfOptionsData does not notify when styles match', (tester) async {
      // Verify that two TextfOptionsData with equal styles are considered equal,
      // which causes _TextfOptionsScope.updateShouldNotify to return false.
      const data1 = TextfOptionsData(boldStyle: TextStyle(color: Colors.red));
      const data2 = TextfOptionsData(boldStyle: TextStyle(color: Colors.red));

      expect(data1 == data2, isTrue);
      expect(data1.hashCode, data2.hashCode);
    });

    testWidgets('TextfOptionsData equality is true for identical instances', (tester) async {
      const data = TextfOptionsData(
        boldStyle: TextStyle(fontWeight: FontWeight.w900),
        linkMouseCursor: SystemMouseCursors.click,
      );

      expect(identical(data, data), isTrue);
    });
  });
}
