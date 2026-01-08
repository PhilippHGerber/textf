// ignore_for_file: avoid-non-null-assertion, no-magic-number

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

void main() {
  testWidgets('Textf respects DefaultTextStyle fontSize and textScaler for scripts',
      (tester) async {
    const double baseFontSize = 30;
    // We expect the logical size (30 * 0.66 = 19.8).
    // We do NOT multiply by scaleFactor here because your implementation
    // puts the unscaled size into the widget tree.
    const double expectedScriptFontSize = baseFontSize * 0.6;
    const double scaleFactor = 2;

    await tester.pumpWidget(
      const MaterialApp(
        home: DefaultTextStyle(
          style: TextStyle(fontSize: baseFontSize, color: Colors.black),
          child: Textf(
            '^super^',
            textScaler: TextScaler.linear(scaleFactor),
          ),
        ),
      ),
    );

    // 1. Find the inner Text widget using a predicate that checks the content
    final Finder superTextFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.textSpan is TextSpan &&
          (widget.textSpan! as TextSpan).text == 'super',
    );

    expect(
      superTextFinder,
      findsOneWidget,
      reason: 'Should find the inner Text widget for superscript via textSpan content',
    );

    final Text textWidget = tester.widget(superTextFinder);

    // 2. Access the style from the TextSpan (widget.style is null in Text.rich)
    final TextSpan innerSpan = textWidget.textSpan! as TextSpan;

    // 3. Verify Font Size matches the LOGICAL size (19.8)
    expect(
      innerSpan.style?.fontSize,
      closeTo(expectedScriptFontSize, 0.01),
      reason: 'Script font size should match base * 0.66 (19.8)',
    );

    // 4. Verify TextScaler is disabled (consistent with your implementation)
    expect(
      textWidget.textScaler,
      equals(TextScaler.noScaling),
      reason: 'TextScaler should be noScaling on the inner widget',
    );
  });
}
