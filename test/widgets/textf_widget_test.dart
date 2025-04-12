import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_textf_widget.dart';

// Helper to find the RichText widget rendered by Textf
Finder findRichText() => find.byType(RichText);

// Helper to get the root TextSpan from the found RichText
TextSpan getRootTextSpan(WidgetTester tester) {
  final richText = tester.widget<RichText>(findRichText());
  expect(richText.text, isA<TextSpan>());
  return richText.text as TextSpan;
}

void main() {
  group('Textf Widget Tests', () {
    testWidgets('Renders plain text correctly', (tester) async {
      const text = 'This is plain text.';
      await pumpTextfWidget(tester, data: text);

      // --- Basic Checks ---
      expect(find.text(text), findsOneWidget); // Verify the text exists visually
      expect(findRichText(), findsOneWidget); // Verify RichText is used

      // --- Inspecting the Span Tree ---
      final rootSpan = getRootTextSpan(tester); // This is the span passed to Text.rich

      // Expectation 1: The root span itself usually has no direct text
      expect(rootSpan.text, isNull, reason: 'Root span from Text.rich usually has null text');

      // Expectation 2: The root span's children list contains the spans from the parser
      expect(rootSpan.children, isNotNull, reason: 'Root span should have children from parser');
      expect(rootSpan.children!.length, 1, reason: 'Parser fast-path should return one primary span');

      // Get the first span returned by the parser
      final parserSpan = rootSpan.children![0];
      expect(parserSpan, isA<TextSpan>(), reason: 'Parser result should be a TextSpan');

      // --- Accommodation for the observed deeper nesting ---
      // Based on your feedback, we check if this parserSpan *also* nests the text
      final actualTextSpan = parserSpan as TextSpan;

      expect(actualTextSpan.children!.length, 1, reason: 'Nested structure should contain one text span');
      final innermostSpan = actualTextSpan.children![0];
      expect(innermostSpan, isA<TextSpan>(), reason: 'Innermost element should be a TextSpan');
      expect((innermostSpan as TextSpan).text, text, reason: 'Innermost span should contain the text');
      expect((innermostSpan).children, isNull, reason: 'Innermost span should not have further children');
    });

    testWidgets('Renders basic bold formatting', (tester) async {
      const text = 'Some **bold** text';
      await pumpTextfWidget(tester, data: text);

      expect(find.textContaining('Some bold text'), findsOneWidget);
      final rootSpan = getRootTextSpan(tester);
      // Root span should have no text itself, but children
      expect(rootSpan.text, isNull);
      expect(rootSpan.children, isNotNull);

      expect(rootSpan.children!.length, 1, reason: "Test failure indicates only one direct child");
      final containerSpan = rootSpan.children![0] as TextSpan;
      expect(containerSpan.children, isNotNull, reason: "The container span should hold the actual segments");
      final actualSpans = containerSpan.children!;

      // Now assert the length and content of the *actual* spans
      expect(actualSpans.length, 3, reason: "Expected 3 segments: 'Some ', bold, ' text'");

      expect((actualSpans[0] as TextSpan).text, 'Some ');
      expect((actualSpans[1] as TextSpan).text, 'bold');
      expect((actualSpans[1] as TextSpan).style?.fontWeight, FontWeight.bold);
      expect((actualSpans[2] as TextSpan).text, ' text');
    });

    testWidgets('Renders basic italic formatting', (tester) async {
      const text = 'Some *italic* text';
      await pumpTextfWidget(tester, data: text);

      final rootSpan = getRootTextSpan(tester);
      expect(rootSpan.children, isNotNull);

      expect(rootSpan.children!.length, 1, reason: "Test failure indicates only one direct child");
      final containerSpan = rootSpan.children![0] as TextSpan;
      expect(containerSpan.children, isNotNull);
      final actualSpans = containerSpan.children!;
      expect(actualSpans.length, 3, reason: "Expected 3 segments: 'Some ', italic, ' text'");

      expect((actualSpans[0] as TextSpan).text, 'Some ');
      expect((actualSpans[1] as TextSpan).text, 'italic');
      expect((actualSpans[1] as TextSpan).style?.fontStyle, FontStyle.italic);
      expect((actualSpans[2] as TextSpan).text, ' text');
    });

    testWidgets('Renders mixed formatting', (tester) async {
      const text = '**Bold** and *italic*.';
      await pumpTextfWidget(tester, data: text);

      expect(find.textContaining('Bold and italic.'), findsOneWidget);
      final rootSpan = getRootTextSpan(tester);
      expect(rootSpan.children, isNotNull);

      expect(rootSpan.children!.length, 1, reason: "Test failure indicates only one direct child");
      final containerSpan = rootSpan.children![0] as TextSpan;
      expect(containerSpan.children, isNotNull);
      final actualSpans = containerSpan.children!;
      expect(actualSpans.length, 4, reason: "Expected 4 segments: bold, ' and ', italic, '.'");

      final boldSpan = actualSpans[0] as TextSpan;
      expect(boldSpan.style?.fontWeight, FontWeight.bold);
      expect(boldSpan.text, 'Bold');

      final italicSpan = actualSpans[2] as TextSpan;
      expect(italicSpan.style?.fontStyle, FontStyle.italic);
      expect(italicSpan.text, 'italic');

      expect((actualSpans[1] as TextSpan).text, ' and ');
      expect((actualSpans[3] as TextSpan).text, '.');
    });

    testWidgets('Applies textAlign correctly', (tester) async {
      const text = 'Some **centered** text';
      await pumpTextfWidget(tester, data: text, textAlign: TextAlign.center);

      final richText = tester.widget<RichText>(findRichText());
      expect(richText.textAlign, TextAlign.center);
    });

    testWidgets('Applies maxLines and overflow correctly', (tester) async {
      const text = 'This is **very long text** that will definitely overflow '
          'when maxLines is set to one.';
      await pumpTextfWidget(
        tester,
        data: text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

      final richText = tester.widget<RichText>(findRichText());
      expect(richText.maxLines, 1);
      expect(richText.overflow, TextOverflow.ellipsis);
      // NOTE: Verifying the actual visual ellipsis is hard in widget tests.
      // Checking the properties is usually sufficient. Golden tests are better for visuals.
    });

    testWidgets('Applies softWrap correctly', (tester) async {
      const text = 'Some **text** to wrap or not wrap.';
      await pumpTextfWidget(tester, data: text, softWrap: false);

      final richText = tester.widget<RichText>(findRichText());
      expect(richText.softWrap, false);

      await pumpTextfWidget(tester, data: text, softWrap: true);
      final richTextWrapped = tester.widget<RichText>(findRichText());
      expect(richTextWrapped.softWrap, true);
    });

    testWidgets('Applies textScaler correctly', (tester) async {
      const text = 'Some **scalable** text';
      const scaler = TextScaler.linear(1.5);
      await pumpTextfWidget(tester, data: text, textScaler: scaler);

      final richText = tester.widget<RichText>(findRichText());
      expect(richText.textScaler, scaler);
    });

    testWidgets('Applies textDirection correctly', (tester) async {
      const text = '**RTL** text example';
      await pumpTextfWidget(tester, data: text, textDirection: TextDirection.rtl);

      final richText = tester.widget<RichText>(findRichText());
      expect(richText.textDirection, TextDirection.rtl);
    });

    testWidgets('Inherits style from DefaultTextStyle', (tester) async {
      const text = 'Inherited **style**';
      const defaultStyle = TextStyle(color: Colors.red, fontSize: 20);

      await pumpTextfWidget(
        tester,
        data: text,
        defaultTextStyle: const DefaultTextStyle(style: defaultStyle, child: SizedBox()),
      );

      final rootSpan = getRootTextSpan(tester);

      // --- Check Root Span Style ---
      // The root span itself should have the default style merged by Text.rich
      expect(rootSpan.style?.color, defaultStyle.color);
      expect(rootSpan.style?.fontSize, defaultStyle.fontSize);
      expect(rootSpan.children, isNotNull);

      // --- Apply Nesting ---
      expect(rootSpan.children!.length, 1, reason: "Structure has container span");
      final containerSpan = rootSpan.children![0] as TextSpan;
      expect(containerSpan.children, isNotNull);
      final actualSpans = containerSpan.children!;
      expect(actualSpans.length, 2, reason: "Expected 2 segments: 'Inherited ', style");

      // --- Check Inherited Span ---
      final plainSpan = actualSpans[0] as TextSpan;
      // This plain span *should* also inherit the default style
      expect(plainSpan.style?.color, defaultStyle.color);
      expect(plainSpan.style?.fontSize, defaultStyle.fontSize);
      expect(plainSpan.text, 'Inherited ');

      // --- Check Bold Span ---
      // Find the bold span within the *actual* segments
      final boldSpan = actualSpans[1] as TextSpan; // We know it's the second one
      expect(boldSpan.text, 'style');
      // Verify it inherited default style properties
      expect(boldSpan.style?.color, defaultStyle.color);
      expect(boldSpan.style?.fontSize, defaultStyle.fontSize);
      // Verify bold was applied on top
      expect(boldSpan.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('Explicit style overrides DefaultTextStyle', (tester) async {
      const text = 'Explicit **style** wins'; // Input has 3 parts
      const defaultStyle = TextStyle(color: Colors.red, fontSize: 20);
      const explicitStyle = TextStyle(color: Colors.blue, fontSize: 16);

      await pumpTextfWidget(
        tester,
        data: text,
        style: explicitStyle, // Explicit style provided to Textf
        defaultTextStyle: const DefaultTextStyle(style: defaultStyle, child: SizedBox()),
      );

      final rootSpan = getRootTextSpan(tester);

      // Root span reflects ambient DefaultTextStyle
      expect(rootSpan.style?.color, defaultStyle.color);
      expect(rootSpan.style?.fontSize, defaultStyle.fontSize);
      expect(rootSpan.children, isNotNull);

      // Apply Nesting
      expect(rootSpan.children!.length, 1);
      final containerSpan = rootSpan.children![0] as TextSpan;
      expect(containerSpan.children, isNotNull);
      final actualSpans = containerSpan.children!;

      expect(actualSpans.length, 3, reason: "Expected 3 segments: 'Explicit ', style (bold), ' wins'");

      // --- Check Inner Spans ---
      final plainSpan1 = actualSpans[0] as TextSpan;
      final boldSpan = actualSpans[1] as TextSpan;
      final plainSpan2 = actualSpans[2] as TextSpan;

      // Check Segment 1: "Explicit "
      expect(plainSpan1.text, 'Explicit ');
      expect(plainSpan1.style?.color, explicitStyle.color); // Parsed with explicitStyle
      expect(plainSpan1.style?.fontSize, explicitStyle.fontSize); // Parsed with explicitStyle

      // Check Segment 2: "style" (bold)
      expect(boldSpan.text, 'style');
      expect(boldSpan.style?.color, explicitStyle.color); // Inherited from explicitStyle base
      expect(boldSpan.style?.fontSize, explicitStyle.fontSize); // Inherited from explicitStyle base
      expect(boldSpan.style?.fontWeight, FontWeight.bold); // Added by formatting

      // Check Segment 3: " wins"
      expect(plainSpan2.text, ' wins');
      expect(plainSpan2.style?.color, explicitStyle.color); // Parsed with explicitStyle
      expect(plainSpan2.style?.fontSize, explicitStyle.fontSize); // Parsed with explicitStyle
    });

    testWidgets('Integrates with SelectionArea', (tester) async {
      const text = 'Select **this** text';

      await pumpTextfWidget(
        tester,
        data: text,
        wrapInSelectionArea: true, // <<< TELL THE HELPER TO WRAP
      );

      // Verify the core widgets are present
      expect(find.byType(SelectionArea), findsOneWidget); // <<< THIS SHOULD PASS NOW
      expect(findRichText(), findsOneWidget);

      // Verify the text content is rendered somewhere within the RichText
      expect(find.textContaining('Select this text', findRichText: true), findsOneWidget);

      // Check if RichText got a selection color from the SelectionArea context
      final richText = tester.widget<RichText>(findRichText());
      expect(richText.selectionColor, isNotNull);
    });
  });
}
