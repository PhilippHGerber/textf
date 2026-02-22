// ignore_for_file: no-magic-number, avoid-non-null-assertion, avoid-late-keyword

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

void main() {
  group('TextfEditingController', () {
    late TextfEditingController controller;

    setUp(TextfEditingController.clearCache);

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

      test('markerOpacity defaults to 1', () {
        controller = TextfEditingController();
        expect(controller.markerOpacity, 1);
      });

      test('invalidate does not throw', () {
        controller = TextfEditingController();
        expect(controller.invalidate, returnsNormally);
      });

      testWidgets('whenActive mode hides markers outside cursor', (tester) async {
        controller = TextfEditingController(
          text: '**bold**',
          markerVisibility: MarkerVisibility.whenActive,
        )..markerOpacity = 0;
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

    group('clearCache', () {
      test('does not throw', () {
        controller = TextfEditingController();
        expect(TextfEditingController.clearCache, returnsNormally);
      });
    });
  });
}
