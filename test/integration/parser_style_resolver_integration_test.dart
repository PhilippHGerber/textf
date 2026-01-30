// Integration tests verifying parser and style resolver work together.

// ignore_for_file: avoid-late-keyword, no-magic-number

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';

void main() {
  group('Parser and StyleResolver Integration', () {
    late TextfParser parser;

    setUp(() {
      parser = TextfParser();
      TextfParser.clearCache();
    });

    tearDown(TextfParser.clearCache);

    testWidgets('applies theme colors to code blocks', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              surfaceContainer: Color(0xFFE0E0E0),
              onSurfaceVariant: Color(0xFF424242),
            ),
          ),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final spans = parser.parse('`code`', capturedContext, const TextStyle());

      expect(spans.length, 1);
      final codeSpan = spans.first as TextSpan;
      expect(codeSpan.style?.fontFamily, 'monospace');
      expect(codeSpan.style?.backgroundColor, const Color(0xFFE0E0E0));
    });

    testWidgets('applies theme colors to links', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
            ),
          ),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final spans = parser.parse('[link](url)', capturedContext, const TextStyle());

      expect(spans.length, 1);
      // Link creates a WidgetSpan with HoverableLinkSpan inside
      expect(spans.first, isA<WidgetSpan>());
    });

    testWidgets('preserves base style properties through formatting', (tester) async {
      late BuildContext capturedContext;
      const baseStyle = TextStyle(
        fontSize: 20,
        fontFamily: 'CustomFont',
        letterSpacing: 1.5,
      );

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

      final spans = parser.parse('**bold**', capturedContext, baseStyle);

      expect(spans.length, 1);
      final boldSpan = spans.first as TextSpan;
      expect(boldSpan.style?.fontSize, 20);
      expect(boldSpan.style?.fontFamily, 'CustomFont');
      expect(boldSpan.style?.letterSpacing, 1.5);
      expect(boldSpan.style?.fontWeight, FontWeight.bold);
    });
  });
}
