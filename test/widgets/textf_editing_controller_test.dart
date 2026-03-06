// ignore_for_file: no-magic-number, avoid-non-null-assertion, avoid-late-keyword

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/textf_limits.dart';
import 'package:textf/textf.dart';

void main() {
  group('TextfEditingController', () {
    late TextfEditingController controller;

    tearDown(() {
      controller.dispose();
    });

    group('Construction', () {
      test('creates with default empty text', () {
        controller = TextfEditingController();
        expect(controller.text, isEmpty);
      });

      test('creates with initial text', () {
        controller = TextfEditingController(text: 'hello **bold**');
        expect(controller.text, 'hello **bold**');
      });

      test('creates from TextEditingValue', () {
        controller = TextfEditingController.fromValue(
          const TextEditingValue(text: 'hello'),
        );
        expect(controller.text, 'hello');
      });
    });

    group('buildTextSpan', () {
      testWidgets('returns styled TextSpan for empty text', (tester) async {
        controller = TextfEditingController();
        late TextSpan result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                result = controller.buildTextSpan(
                  context: context,
                  withComposing: false,
                );
                return Container();
              },
            ),
          ),
        );

        expect(result, isA<TextSpan>());
      });

      testWidgets('returns formatted TextSpan for bold text', (tester) async {
        controller = TextfEditingController(text: '**bold**');
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
                return Container();
              },
            ),
          ),
        );

        expect(result.children, isNotNull);
        // 3 spans: ** (dimmed) + bold (styled) + ** (dimmed)
        expect(result.children!.length, 3);
        final content = result.children![1] as TextSpan;
        expect(content.text, 'bold');
        expect(content.style?.fontWeight, FontWeight.bold);
      });

      testWidgets('returns plain TextSpan for unformatted text', (tester) async {
        controller = TextfEditingController(text: 'hello world');
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
                return Container();
              },
            ),
          ),
        );

        expect(result.children, isNotNull);
        expect(result.children!.length, 1);
        final child = result.children!.first as TextSpan;
        expect(child.text, 'hello world');
      });

      testWidgets('applies composing underline decoration', (tester) async {
        controller = TextfEditingController()
          ..value = const TextEditingValue(
            text: 'hello',
            composing: TextRange(start: 0, end: 5),
          );
        late TextSpan result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                result = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(),
                  withComposing: true,
                );
                return Container();
              },
            ),
          ),
        );

        expect(result.children, isNotNull);
        final child = result.children!.first as TextSpan;
        expect(child.style?.decoration, TextDecoration.underline);
      });

      testWidgets('applies composing underline while preserving existing decoration',
          (tester) async {
        controller = TextfEditingController(text: '~~strike~~')
          ..value = const TextEditingValue(
            text: '~~strike~~',
            composing: TextRange(start: 2, end: 8), // Over "strike"
          );
        late TextSpan result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                result = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(),
                  withComposing: true,
                );
                return Container();
              },
            ),
          ),
        );

        expect(result.children, isNotNull);
        // Spans: ~~ (dim), strike (composing + strike), ~~ (dim)
        expect(result.children!.length, 3);
        final composingSpan = result.children![1] as TextSpan;
        expect(composingSpan.text, 'strike');

        final expectedDecoration = TextDecoration.combine([
          TextDecoration.lineThrough,
          TextDecoration.underline,
        ]);
        expect(composingSpan.style?.decoration, expectedDecoration);
      });

      testWidgets('composing region splits text correctly', (tester) async {
        controller = TextfEditingController()
          ..value = const TextEditingValue(
            text: 'hello world',
            composing: TextRange(start: 6, end: 11),
          );
        late TextSpan result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                result = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(),
                  withComposing: true,
                );
                return Container();
              },
            ),
          ),
        );

        expect(result.children, isNotNull);
        // "hello " (before) + "world" (composing)
        expect(result.children!.length, 2);
        final before = result.children!.first as TextSpan;
        final composing = result.children!.last as TextSpan;
        expect(before.text, 'hello ');
        expect(composing.text, 'world');
        expect(composing.style?.decoration, TextDecoration.underline);
      });

      testWidgets('composing underline over bold span (null decoration) uses underline only',
          (tester) async {
        // Covers the else-if(existingDeco == null) branch in the composing injection loop.
        // A bold span has a non-null style but null decoration.
        controller = TextfEditingController()
          ..value = const TextEditingValue(
            text: '**bold**',
            composing: TextRange(start: 2, end: 6), // Over "bold"
          );
        late TextSpan result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                result = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(),
                  withComposing: true,
                );
                return Container();
              },
            ),
          ),
        );

        expect(result.children, isNotNull);
        final boldSpan = result.children!
            .whereType<TextSpan>()
            .firstWhere((s) => s.text == 'bold', orElse: () => const TextSpan());
        expect(boldSpan.style?.fontWeight, FontWeight.bold);
        expect(boldSpan.style?.decoration, TextDecoration.underline);
      });

      testWidgets('core cache hit reuses parsed spans when withComposing changes', (tester) async {
        // Covers the `fullSpans = _cachedParsedSpans!` branch (line 238):
        // core inputs are identical, but withComposing differs → composing miss.
        controller = TextfEditingController(text: 'hello world');

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // First call: fills _cachedParsedSpans and _cachedFinalChildren.
                controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(),
                  withComposing: false,
                );
                // Second call: same core inputs, different withComposing
                // → coreCacheHit=true but _lastWithComposing differs → hits line 238.
                final result = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(),
                  withComposing: true,
                );
                expect(result.children, isNotNull);
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('different themes trigger full reparse via _isSameTheme', (tester) async {
        // Covers lines 115-118 (_isSameTheme body):
        // Uses nested Theme widgets within a single pump so the two ThemeData
        // objects are guaranteed to be non-identical Dart instances with
        // different colorScheme.primary values, forcing the comparison.
        controller = TextfEditingController(text: '**bold**');

        // Two ThemeData objects created from the SAME seed → same colorScheme
        // property values but different Dart object identities (!identical).
        // All four comparisons in _isSameTheme evaluate (none short-circuit)
        // and return true, covering lines 115-118.
        final themeA = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        );
        final themeB = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Theme(
              data: themeA,
              child: Builder(
                builder: (ctxA) {
                  // First call: sets _lastTheme = themeA.
                  controller.buildTextSpan(
                    context: ctxA,
                    style: const TextStyle(),
                    withComposing: false,
                  );
                  return Theme(
                    data: themeB,
                    child: Builder(
                      builder: (ctxB) {
                        // Second call: _lastTheme=themeA, current=themeB.
                        // Not identical but all four color fields match
                        // → lines 115-118 are all evaluated, returns true.
                        final result = controller.buildTextSpan(
                          context: ctxB,
                          style: const TextStyle(),
                          withComposing: false,
                        );
                        expect(result.children, isNotNull);
                        return Container();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
      });

      testWidgets('no composing when withComposing is false', (tester) async {
        controller = TextfEditingController()
          ..value = const TextEditingValue(
            text: 'hello',
            composing: TextRange(start: 0, end: 5),
          );
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
                return Container();
              },
            ),
          ),
        );

        // Should not apply composing underline when withComposing is false
        final child = result.children!.first as TextSpan;
        expect(child.style?.decoration, isNot(TextDecoration.underline));
      });
    });

    group('TextField Integration', () {
      testWidgets('works with TextField', (tester) async {
        controller = TextfEditingController(text: '**bold** text');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextField(controller: controller),
            ),
          ),
        );

        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('works with TextFormField', (tester) async {
        controller = TextfEditingController(text: '*italic* text');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextFormField(controller: controller),
            ),
          ),
        );

        expect(find.byType(TextFormField), findsOneWidget);
      });

      testWidgets('text editing updates formatting', (tester) async {
        controller = TextfEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextField(controller: controller),
            ),
          ),
        );

        // Type text with formatting markers
        await tester.enterText(find.byType(TextField), '**bold**');
        await tester.pump();

        expect(controller.text, '**bold**');
      });
    });

    group('TextfOptions Integration', () {
      testWidgets('respects TextfOptions from widget tree', (tester) async {
        controller = TextfEditingController(text: '**bold**');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextfOptions(
                boldStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
                child: TextField(controller: controller),
              ),
            ),
          ),
        );

        expect(find.byType(TextField), findsOneWidget);
      });
    });

    group('MarkerVisibility', () {
      test('defaults to always', () {
        controller = TextfEditingController();
        expect(controller.markerVisibility, MarkerVisibility.always);
      });

      test('can be set via constructor', () {
        controller = TextfEditingController(
          markerVisibility: MarkerVisibility.whenActive,
        );
        expect(controller.markerVisibility, MarkerVisibility.whenActive);
      });

      test('invalidate does not throw', () {
        controller = TextfEditingController();
        expect(controller.invalidate, returnsNormally);
      });

      testWidgets('whenActive mode hides markers outside cursor', (tester) async {
        controller = TextfEditingController(
          text: '**bold**',
          markerVisibility: MarkerVisibility.whenActive,
        );
        late TextSpan result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Set selection to position 0 (on opening marker)
                controller.selection = const TextSelection.collapsed(offset: 0);
                result = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(color: Color(0xFF000000)),
                  withComposing: false,
                );
                return Container();
              },
            ),
          ),
        );

        // With cursor at position 0, the markers for **bold** should be active
        expect(result.children, isNotNull);
        expect(result.children!.length, 3);
        final openMarker = result.children!.first as TextSpan;
        expect(openMarker.text, '**');
        // Cursor is on the marker, so it should be visible (not transparent)
        expect(openMarker.style?.color?.a, greaterThan(0));
      });
    });

    group('maxLiveFormattingLength', () {
      test('defaults to TextfLimits.maxLiveFormattingLength', () {
        controller = TextfEditingController();
        expect(controller.maxLiveFormattingLength, TextfLimits.maxLiveFormattingLength);
      });

      test('accepts custom value in constructor', () {
        controller = TextfEditingController(maxLiveFormattingLength: 100);
        expect(controller.maxLiveFormattingLength, 100);
      });

      test('fromValue constructor accepts custom value', () {
        controller = TextfEditingController.fromValue(
          const TextEditingValue(text: 'hello'),
          maxLiveFormattingLength: 50,
        );
        expect(controller.maxLiveFormattingLength, 50);
      });

      test('setter updates value and notifies listeners', () {
        controller = TextfEditingController();
        var notified = false;
        controller
          ..addListener(() => notified = true)
          ..maxLiveFormattingLength = 100;
        expect(controller.maxLiveFormattingLength, 100);
        expect(notified, isTrue);
      });

      test('setter does not notify when value unchanged', () {
        controller = TextfEditingController(maxLiveFormattingLength: 100);
        var notified = false;
        controller
          ..addListener(() => notified = true)
          ..maxLiveFormattingLength = 100;
        expect(notified, isFalse);
      });

      testWidgets('returns plain TextSpan when text exceeds limit', (tester) async {
        controller = TextfEditingController(
          text: '**bold** ' * 20,
          maxLiveFormattingLength: 10,
        );
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
                return Container();
              },
            ),
          ),
        );

        // The text is now returned as a single unformatted child span
        // so that it can participate in the IME composing logic.
        expect(result.text, isNull);
        expect(result.children, isNotNull);
        expect(result.children!.length, 1);

        final child = result.children!.first as TextSpan;
        expect(child.text, controller.text);
        expect(child.style, isNull); // Ensures no formatting was applied
      });

      testWidgets('returns formatted TextSpan when text is within limit', (tester) async {
        controller = TextfEditingController(
          text: '**bold**',
          maxLiveFormattingLength: 100,
        );
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
                return Container();
              },
            ),
          ),
        );

        // Should have children (formatted spans)
        expect(result.children, isNotNull);
        expect(result.children!.length, greaterThan(1));
      });
    });

    group('plainText', () {
      test('empty text returns empty string', () {
        controller = TextfEditingController();
        expect(controller.plainText, '');
      });

      test('plain text returns same value as text', () {
        controller = TextfEditingController(text: 'hello world');
        expect(controller.plainText, 'hello world');
      });

      test('strips bold markers', () {
        controller = TextfEditingController(text: '**bold**');
        expect(controller.plainText, 'bold');
      });

      test('strips link and returns display text', () {
        controller = TextfEditingController(text: '[text](url)');
        expect(controller.plainText, 'text');
      });

      test('strips mixed formatting', () {
        controller = TextfEditingController(text: '**Hello** [World](url)!');
        expect(controller.plainText, 'Hello World!');
      });

      test('preserves widget placeholder', () {
        controller = TextfEditingController(text: '{icon}');
        expect(controller.plainText, '{icon}');
      });

      test('updates when text changes', () {
        controller = TextfEditingController(text: '**bold**');
        expect(controller.plainText, 'bold');
        controller.text = 'plain';
        expect(controller.plainText, 'plain');
      });
    });

    group('Super/Subscript Preview Mode', () {
      testWidgets('buildTextSpan emits WidgetSpans for superscript when cursor outside',
          (tester) async {
        controller = TextfEditingController(
          text: 'E=mc^2^',
          markerVisibility: MarkerVisibility.whenActive,
        );
        late TextSpan result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Place cursor at position 0 (outside ^2^)
                controller.selection = const TextSelection.collapsed(offset: 0);
                result = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(fontSize: 16),
                  withComposing: false,
                );
                return Container();
              },
            ),
          ),
        );

        expect(result.children, isNotNull);
        // Should contain WidgetSpans for the ^2^ region
        final widgetSpans = result.children!.whereType<WidgetSpan>().toList();
        expect(widgetSpans, isNotEmpty);
        // Each WidgetSpan contributes 1 slot; total slots must equal text length
        var totalSlots = 0;
        for (final child in result.children!) {
          if (child is TextSpan) {
            totalSlots += child.text?.length ?? 0;
          } else if (child is WidgetSpan) {
            totalSlots += 1;
          }
        }
        expect(totalSlots, 'E=mc^2^'.length);
      });

      testWidgets('buildTextSpan: cursor inside uses TextSpan markers, WidgetSpan content',
          (tester) async {
        controller = TextfEditingController(
          text: 'H~2~O',
          markerVisibility: MarkerVisibility.whenActive,
        );
        late TextSpan result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Place cursor at position 2 (inside ~2~)
                controller.selection = const TextSelection.collapsed(offset: 2);
                result = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(fontSize: 16),
                  withComposing: false,
                );
                return Container();
              },
            ),
          ),
        );

        expect(result.children, isNotNull);
        // Cursor inside → markers are visible TextSpan, content is WidgetSpan
        // for vertical displacement (subscript). The "2" character = 1 WidgetSpan.
        final widgetSpans = result.children!.whereType<WidgetSpan>().toList();
        expect(widgetSpans, isNotEmpty);
        // Total slots must equal text length
        var totalSlots = 0;
        for (final child in result.children!) {
          if (child is TextSpan) totalSlots += child.text?.length ?? 0;
          if (child is WidgetSpan) totalSlots += 1;
        }
        expect(totalSlots, 'H~2~O'.length);
      });
    });
  });
}
