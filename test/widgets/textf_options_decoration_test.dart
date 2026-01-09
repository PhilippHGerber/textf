import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

// Helper to find the RichText widget rendered by Textf.
Finder _findRichText() => find.byType(RichText);

// Helper to find a specific TextSpan within the RichText widget by its text content.
// This is crucial for asserting styles on specific parts of the formatted string.
TextSpan _findSpanByText(WidgetTester tester, String text) {
  final richText = tester.widget<RichText>(_findRichText());
  final rootSpan = richText.text as TextSpan;

  TextSpan? foundSpan;
  rootSpan.visitChildren((span) {
    if (span is TextSpan && span.text == text) {
      foundSpan = span;
      return false; // Stop visiting
    }
    return true; // Continue visiting
  });

  final span = foundSpan;
  if (span != null) {
    return span;
  } else {
    throw StateError('TextSpan with text "$text" not found in the widget tree.');
  }
}

// Helper to find the TextSpan style
TextStyle? _findTextSpanStyle(WidgetTester tester, String textToFind) {
  final finder = find.byType(RichText);
  final richText = tester.widget<RichText>(finder.first);
  final rootSpan = richText.text as TextSpan;

  TextStyle? foundStyle;
  rootSpan.visitChildren((span) {
    if (span is TextSpan && span.text == textToFind) {
      foundStyle = span.style;
      return false; // Stop visiting
    }
    return true;
  });
  return foundStyle;
}

void main() {
  group('TextfOptions Decoration Combining Tests', () {
    testWidgets(
      'Test Case 1: Nested decorations are correctly combined',
      (tester) async {
        // ARRANGE: Set up a parent with underline and a child with strikethrough.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TextfOptions(
                boldStyle: TextStyle(decoration: TextDecoration.underline),
                child: TextfOptions(
                  boldStyle: TextStyle(
                    decoration: TextDecoration.lineThrough,
                  ),
                  child: Textf(
                    'Some **bold** text.',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
        );

        // ACT: Find the styled span.
        final boldSpan = _findSpanByText(tester, 'bold');

        // ASSERT: Verify that both decorations have been combined.
        expect(
          boldSpan.style?.decoration,
          TextDecoration.combine([
            TextDecoration.underline,
            TextDecoration.lineThrough,
          ]),
          reason: 'Decorations from parent and child options should be combined.',
        );
      },
    );

    testWidgets(
      'Test Case 2: A child option with TextDecoration.none removes parent decoration',
      (tester) async {
        // ARRANGE: Set up a parent with underline and a child that removes it.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TextfOptions(
                boldStyle: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.blue,
                ),
                child: TextfOptions(
                  boldStyle: TextStyle(decoration: TextDecoration.none),
                  child: Textf(
                    'Some **bold** text.',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
        );

        // ACT: Find the styled span.
        final boldSpan = _findSpanByText(tester, 'bold');

        // ASSERT: Verify that the decoration has been removed.
        expect(
          boldSpan.style?.decoration,
          TextDecoration.none,
          reason: 'Child with TextDecoration.none should remove parent decoration.',
        );
      },
    );

    testWidgets(
      'Test Case 3: Child decoration properties take precedence when combining',
      (tester) async {
        // ARRANGE: Parent and child both define decorations and their properties.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TextfOptions(
                boldStyle: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.blue,
                  decorationThickness: 2,
                  decorationStyle: TextDecorationStyle.solid,
                ),
                child: TextfOptions(
                  boldStyle: TextStyle(
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.red,
                    decorationThickness: 4,
                    decorationStyle: TextDecorationStyle.wavy,
                  ),
                  child: Textf('Some **bold** text.'),
                ),
              ),
            ),
          ),
        );

        // ACT: Find the styled span.
        final boldSpan = _findSpanByText(tester, 'bold');

        // ASSERT: Verify the final properties are from the child option.
        expect(
          boldSpan.style?.decoration,
          TextDecoration.combine([
            TextDecoration.underline,
            TextDecoration.lineThrough,
          ]),
        );
        expect(
          boldSpan.style?.decorationColor,
          Colors.red,
          reason: 'Child decorationColor should take precedence.',
        );
        const expectDecorationThickness = 4.0;
        expect(
          boldSpan.style?.decorationThickness,
          expectDecorationThickness,
          reason: 'Child decorationThickness should take precedence.',
        );
        expect(
          boldSpan.style?.decorationStyle,
          TextDecorationStyle.wavy,
          reason: 'Child decorationStyle should take precedence.',
        );
      },
    );

    testWidgets(
      'Test Case 4: No-op test (unrelated options do not interfere)',
      (tester) async {
        // ARRANGE: Parent defines a bold style with decoration.
        // Child defines an unrelated italic style.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TextfOptions(
                boldStyle: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.green,
                ),
                child: TextfOptions(
                  italicStyle: TextStyle(fontStyle: FontStyle.italic),
                  child: Textf('Some **bold** and *italic* text.'),
                ),
              ),
            ),
          ),
        );

        // ACT & ASSERT for bold text.
        final boldSpan = _findSpanByText(tester, 'bold');
        expect(
          boldSpan.style?.decoration,
          TextDecoration.underline,
          reason: 'Bold text should still have its underline from the parent.',
        );
        expect(
          boldSpan.style?.decorationColor,
          Colors.green,
          reason: 'Bold text should have its decoration color from the parent.',
        );

        // ACT & ASSERT for italic text.
        final italicSpan = _findSpanByText(tester, 'italic');
        expect(
          italicSpan.style?.fontStyle,
          FontStyle.italic,
          reason: 'Italic text should have its style from the child option.',
        );
        expect(
          italicSpan.style?.decoration,
          anyOf(isNull, TextDecoration.none),
          reason: 'Italic text should not have any decoration.',
        );
      },
    );

    testWidgets('Preserves existing flags when options add duplicated decoration', (tester) async {
      // Scenario:
      // Parent sets: Underline + LineThrough
      // Child sets: Underline (Redundant)
      // Result should be: Underline + LineThrough (NOT just Underline)

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            // Parent establishes base decoration
            boldStyle: TextStyle(
              decoration:
                  TextDecoration.combine([TextDecoration.underline, TextDecoration.lineThrough]),
            ),
            child: const TextfOptions(
              // Child tries to apply Underline again
              boldStyle: TextStyle(decoration: TextDecoration.underline),
              child: Textf('**Target**'),
            ),
          ),
        ),
      );

      final style = _findTextSpanStyle(tester, 'Target');

      expect(
        style?.decoration?.contains(TextDecoration.lineThrough),
        isTrue,
        reason: 'LineThrough should be preserved even if child applies Underline again',
      );
      expect(style?.decoration?.contains(TextDecoration.underline), isTrue);
    });

    testWidgets('Combines distinct decorations', (tester) async {
      // Scenario: Parent=Underline, Child=LineThrough -> Result=Both
      await tester.pumpWidget(
        const MaterialApp(
          home: TextfOptions(
            boldStyle: TextStyle(decoration: TextDecoration.underline),
            child: TextfOptions(
              boldStyle: TextStyle(decoration: TextDecoration.lineThrough),
              child: Textf('**Target**'),
            ),
          ),
        ),
      );

      final style = _findTextSpanStyle(tester, 'Target');
      expect(style?.decoration?.contains(TextDecoration.underline), isTrue);
      expect(style?.decoration?.contains(TextDecoration.lineThrough), isTrue);
    });

    testWidgets('TextDecoration.none removes decoration', (tester) async {
      // Scenario: Parent=Underline, Child=None -> Result=None
      await tester.pumpWidget(
        const MaterialApp(
          home: TextfOptions(
            boldStyle: TextStyle(decoration: TextDecoration.underline),
            child: TextfOptions(
              boldStyle: TextStyle(decoration: TextDecoration.none),
              child: Textf('**Target**'),
            ),
          ),
        ),
      );

      final style = _findTextSpanStyle(tester, 'Target');
      // Flutter might treat it as null or none depending on merge logic,
      // but it definitely shouldn't contain underline.
      final hasUnderline = style?.decoration?.contains(TextDecoration.underline) ?? false;
      expect(hasUnderline, isFalse);
    });
  });
}
