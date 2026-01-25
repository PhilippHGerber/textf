// ignore_for_file: avoid-non-null-assertion, no-magic-number, no-empty-block

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/widgets/internal/hoverable_link_span.dart';
import 'package:textf/textf.dart';

void main() {
  group('Link TextScaler Regression Tests', () {
    group('HoverableLinkSpan inner Text uses noScaling', () {
      testWidgets('plain link text has TextScaler.noScaling', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HoverableLinkSpan(
                url: 'https://example.com',
                rawDisplayText: 'Example',
                initialChildrenSpans: [],
                initialPlainText: 'Example',
                normalStyle: TextStyle(color: Colors.blue, fontSize: 16),
                hoverStyle: TextStyle(color: Colors.red, fontSize: 16),
                tapRecognizer: null,
                mouseCursor: SystemMouseCursors.click,
              ),
            ),
          ),
        );

        // Find the inner Text widget
        final textFinder = find.byType(Text);
        expect(textFinder, findsOneWidget);

        final Text textWidget = tester.widget(textFinder);

        expect(
          textWidget.textScaler,
          equals(TextScaler.noScaling),
          reason: 'Inner Text should use noScaling to prevent double-scaling',
        );
      });

      testWidgets('link with nested formatting has TextScaler.noScaling', (tester) async {
        // Simulate a link with pre-parsed children (e.g., [**bold** link](url))
        const childSpans = [
          TextSpan(
            text: 'bold',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          TextSpan(text: ' link', style: TextStyle(color: Colors.blue)),
        ];

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HoverableLinkSpan(
                url: 'https://example.com',
                rawDisplayText: 'bold link',
                initialChildrenSpans: childSpans,
                normalStyle: TextStyle(color: Colors.blue, fontSize: 16),
                hoverStyle: TextStyle(color: Colors.red, fontSize: 16),
                tapRecognizer: null,
                mouseCursor: SystemMouseCursors.click,
              ),
            ),
          ),
        );

        final Text textWidget = tester.widget(find.byType(Text));

        expect(
          textWidget.textScaler,
          equals(TextScaler.noScaling),
          reason: 'Nested formatting links should also use noScaling',
        );
      });
    });

    group('Textf link scaling with MediaQuery', () {
      testWidgets('link does not double-scale with MediaQuery textScaler', (tester) async {
        const double baseFontSize = 20;
        const double scaleFactor = 2;

        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(scaleFactor),
              ),
              child: Scaffold(
                body: TextfOptions(
                  onLinkTap: _noopLinkTap, // Enable link rendering
                  child: Textf(
                    '[Flutter](https://flutter.dev)',
                    style: TextStyle(fontSize: baseFontSize),
                  ),
                ),
              ),
            ),
          ),
        );

        // Find the HoverableLinkSpan
        final hoverableFinder = find.byType(HoverableLinkSpan);
        expect(hoverableFinder, findsOneWidget);

        // Find the inner Text widget inside HoverableLinkSpan
        final innerTextFinder = find.descendant(
          of: hoverableFinder,
          matching: find.byType(Text),
        );
        expect(innerTextFinder, findsOneWidget);

        final Text innerText = tester.widget(innerTextFinder);

        // Critical: Inner Text must use noScaling
        expect(
          innerText.textScaler,
          equals(TextScaler.noScaling),
          reason: 'Link inner Text must use noScaling to prevent double-scaling',
        );

        // The style fontSize should be the logical (unscaled) size
        final TextSpan? rootSpan = innerText.textSpan as TextSpan?;
        final TextStyle? style = _extractFirstTextStyle(rootSpan);

        expect(
          style?.fontSize,
          equals(baseFontSize),
          reason: 'Font size should be logical size ($baseFontSize), not scaled',
        );
      });

      testWidgets('link scales correctly once via parent RichText', (tester) async {
        const double baseFontSize = 16;
        const double scaleFactor = 1.5;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TextfOptions(
                onLinkTap: _noopLinkTap,
                child: Textf(
                  '[Link](https://example.com)',
                  style: TextStyle(fontSize: baseFontSize),
                  textScaler: TextScaler.linear(scaleFactor),
                ),
              ),
            ),
          ),
        );

        // Find the parent RichText (from TextfRenderer)
        final richTextFinder = find.byType(RichText);
        expect(richTextFinder, findsWidgets); // May find multiple

        // The outermost RichText should have the scaler applied
        final RichText parentRichText = tester.widget(richTextFinder.first);
        expect(
          parentRichText.textScaler,
          equals(const TextScaler.linear(scaleFactor)),
          reason: 'Parent RichText should apply the textScaler',
        );

        // Inner link Text should NOT have scaler
        final hoverableFinder = find.byType(HoverableLinkSpan);
        final innerTextFinder = find.descendant(
          of: hoverableFinder,
          matching: find.byType(Text),
        );

        final Text innerText = tester.widget(innerTextFinder);
        expect(
          innerText.textScaler,
          equals(TextScaler.noScaling),
          reason: 'Inner link Text should use noScaling',
        );
      });

      testWidgets('mixed content: regular text and links scale consistently', (tester) async {
        const double scaleFactor = 2;

        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(scaleFactor),
              ),
              child: Scaffold(
                body: TextfOptions(
                  onLinkTap: _noopLinkTap,
                  child: Textf(
                    'Hello [World](https://example.com)!',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        );

        // Find HoverableLinkSpan's inner Text
        final hoverableFinder = find.byType(HoverableLinkSpan);
        expect(hoverableFinder, findsOneWidget);

        final innerTextFinder = find.descendant(
          of: hoverableFinder,
          matching: find.byType(Text),
        );

        final Text linkText = tester.widget(innerTextFinder);

        expect(
          linkText.textScaler,
          equals(TextScaler.noScaling),
          reason: 'Link text should not apply scaler internally',
        );
      });
    });

    group('Consistency with script spans', () {
      testWidgets('links and scripts both use noScaling pattern', (tester) async {
        const double scaleFactor = 2;

        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(scaleFactor),
              ),
              child: Scaffold(
                body: TextfOptions(
                  onLinkTap: _noopLinkTap,
                  child: Textf(
                    'E = mc^2^ and [link](url)',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        );

        // Find all Text widgets that are children of WidgetSpans
        // (both scripts and links use WidgetSpan with inner Text)

        // Script text (inside Padding)
        final paddingFinder = find.byType(Padding);
        for (final element in paddingFinder.evaluate()) {
          final padding = element.widget as Padding;
          if (padding.child is Text) {
            final Text scriptText = padding.child! as Text;
            expect(
              scriptText.textScaler,
              equals(TextScaler.noScaling),
              reason: 'Script Text should use noScaling',
            );
          }
        }

        // Link text (inside HoverableLinkSpan)
        final hoverableFinder = find.byType(HoverableLinkSpan);
        if (hoverableFinder.evaluate().isNotEmpty) {
          final innerTextFinder = find.descendant(
            of: hoverableFinder,
            matching: find.byType(Text),
          );

          final Text linkText = tester.widget(innerTextFinder);
          expect(
            linkText.textScaler,
            equals(TextScaler.noScaling),
            reason: 'Link Text should use noScaling (same pattern as scripts)',
          );
        }
      });
    });
  });
}

// Helper to extract the first TextStyle from a TextSpan tree
TextStyle? _extractFirstTextStyle(TextSpan? span) {
  if (span == null) return null;
  if (span.style != null) return span.style;

  final children = span.children;
  if (children != null) {
    for (final child in children) {
      if (child is TextSpan) {
        final style = _extractFirstTextStyle(child);
        if (style != null) return style;
      }
    }
  }
  return null;
}

// No-op link tap handler to enable link rendering
void _noopLinkTap(String url, String text) {}
