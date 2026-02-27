// ignore_for_file: no-magic-number, avoid-non-null-assertion, avoid-late-keyword

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

void main() {
  group('TextfEditingController edge cases', () {
    late TextfEditingController controller;

    tearDown(() {
      controller.dispose();
    });

    group('markerVisibility setter', () {
      test('notifies listeners when changed', () {
        var notified = false;
        controller = TextfEditingController()
          ..addListener(() => notified = true)
          ..markerVisibility = MarkerVisibility.whenActive;

        expect(controller.markerVisibility, MarkerVisibility.whenActive);
        expect(notified, isTrue);
      });

      test('does not notify when value unchanged', () {
        var notified = false;
        controller = TextfEditingController()
          ..addListener(() => notified = true)
          ..markerVisibility = MarkerVisibility.always;

        expect(notified, isFalse);
      });
    });

    group('buildTextSpan with null style', () {
      testWidgets('uses empty TextStyle when style is null', (tester) async {
        controller = TextfEditingController(text: 'hello');
        late TextSpan result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                result = controller.buildTextSpan(
                  context: context,
                  withComposing: false,
                );
                return const SizedBox();
              },
            ),
          ),
        );

        expect(result, isA<TextSpan>());
        expect(result.children, isNotNull);
      });
    });

    group('buildTextSpan with links in editing mode', () {
      testWidgets('renders link syntax with broken link tokens as plain text', (tester) async {
        controller = TextfEditingController(text: '[link text](url)');
        late TextSpan result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                result = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(),
                  withComposing: false,
                );
                return const SizedBox();
              },
            ),
          ),
        );

        expect(result.children, isNotNull);
        // The controller should render all characters including [ ] ( )
        var totalLength = 0;
        for (final child in result.children!) {
          if (child is TextSpan) {
            totalLength += child.text?.length ?? 0;
          } else if (child is WidgetSpan) {
            totalLength += 1;
          }
        }
        expect(totalLength, '[link text](url)'.length);
      });
    });

    group('buildTextSpan with placeholder in link text', () {
      testWidgets('renders placeholder literally inside link text', (tester) async {
        controller = TextfEditingController(text: '[{icon} link](url)');
        late TextSpan result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                result = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(),
                  withComposing: false,
                );
                return const SizedBox();
              },
            ),
          ),
        );

        expect(result.children, isNotNull);
        var totalLength = 0;
        for (final child in result.children!) {
          if (child is TextSpan) {
            totalLength += child.text?.length ?? 0;
          } else if (child is WidgetSpan) {
            totalLength += 1;
          }
        }
        expect(totalLength, '[{icon} link](url)'.length);
      });
    });

    group('span builder cache hit', () {
      testWidgets('cache is used when useCache is true and text repeats', (tester) async {
        // First build populates the cache
        controller = TextfEditingController(text: '**bold**');
        late TextSpan result1;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Use buildTextSpan twice with same text to hit cache
                controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(),
                  withComposing: false,
                );
                // Rebuild to hit cache
                result1 = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(),
                  withComposing: false,
                );
                return const SizedBox();
              },
            ),
          ),
        );

        expect(result1.children, isNotNull);
      });
    });
  });
}
