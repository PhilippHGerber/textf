// ignore_for_file: no-empty-block, prefer-match-file-name, avoid-top-level-members-in-tests

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/widgets/internal/hoverable_link_span.dart';

/// A TapGestureRecognizer that tracks whether dispose() was called.
class TrackingTapGestureRecognizer extends TapGestureRecognizer {
  bool wasDisposed = false;

  @override
  void dispose() {
    wasDisposed = true;
    super.dispose();
  }
}

void main() {
  group('HoverableLinkSpan Lifecycle Tests', () {
    group('TapGestureRecognizer Disposal', () {
      testWidgets('disposes TapGestureRecognizer when widget is removed from tree', (tester) async {
        final recognizer = TrackingTapGestureRecognizer()..onTap = () {};

        // Build widget with the recognizer
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HoverableLinkSpan(
                url: 'https://example.com',
                rawDisplayText: 'Test Link',
                initialChildrenSpans: const [],
                initialPlainText: 'Test Link',
                normalStyle: const TextStyle(color: Colors.blue),
                hoverStyle: const TextStyle(color: Colors.red),
                tapRecognizer: recognizer,
                mouseCursor: SystemMouseCursors.click,
              ),
            ),
          ),
        );

        // Verify widget is in tree
        expect(find.text('Test Link'), findsOneWidget);
        expect(recognizer.wasDisposed, isFalse);

        // Remove the widget from tree (triggers dispose)
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox.shrink(),
            ),
          ),
        );

        // Recognizer should be disposed
        expect(
          recognizer.wasDisposed,
          isTrue,
          reason: 'Recognizer should be disposed when widget is removed from tree',
        );
      });

      testWidgets('handles null TapGestureRecognizer gracefully', (tester) async {
        // Build widget without a recognizer
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HoverableLinkSpan(
                url: 'https://example.com',
                rawDisplayText: 'Test Link',
                initialChildrenSpans: [],
                initialPlainText: 'Test Link',
                normalStyle: TextStyle(color: Colors.blue),
                hoverStyle: TextStyle(color: Colors.red),
                tapRecognizer: null,
                mouseCursor: SystemMouseCursors.click,
              ),
            ),
          ),
        );

        expect(find.text('Test Link'), findsOneWidget);

        // Remove widget - should not throw even with null recognizer
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox.shrink(),
            ),
          ),
        );

        // No exception means the test passes
      });

      testWidgets('disposes old recognizer when widget is rebuilt with different recognizer',
          (tester) async {
        final recognizer1 = TrackingTapGestureRecognizer()..onTap = () {};
        final recognizer2 = TrackingTapGestureRecognizer()..onTap = () {};

        // Build with first recognizer
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HoverableLinkSpan(
                key: const ValueKey('link'),
                url: 'https://example.com',
                rawDisplayText: 'Test Link',
                initialChildrenSpans: const [],
                initialPlainText: 'Test Link',
                normalStyle: const TextStyle(color: Colors.blue),
                hoverStyle: const TextStyle(color: Colors.red),
                tapRecognizer: recognizer1,
                mouseCursor: SystemMouseCursors.click,
              ),
            ),
          ),
        );

        expect(recognizer1.wasDisposed, isFalse);
        expect(recognizer2.wasDisposed, isFalse);

        // Rebuild with second recognizer (simulates re-parse)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HoverableLinkSpan(
                key: const ValueKey('link'),
                url: 'https://example.com',
                rawDisplayText: 'Test Link',
                initialChildrenSpans: const [],
                initialPlainText: 'Test Link',
                normalStyle: const TextStyle(color: Colors.blue),
                hoverStyle: const TextStyle(color: Colors.red),
                tapRecognizer: recognizer2,
                mouseCursor: SystemMouseCursors.click,
              ),
            ),
          ),
        );

        // First recognizer should be disposed after didUpdateWidget
        expect(
          recognizer1.wasDisposed,
          isTrue,
          reason: 'Old recognizer should be disposed when widget updates with new one',
        );

        // Second recognizer should NOT be disposed yet
        expect(
          recognizer2.wasDisposed,
          isFalse,
          reason: 'New recognizer should not be disposed yet',
        );
      });

      testWidgets('does not dispose recognizer if same instance on rebuild', (tester) async {
        final recognizer = TrackingTapGestureRecognizer()..onTap = () {};

        // Build with recognizer
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HoverableLinkSpan(
                key: const ValueKey('link'),
                url: 'https://example.com',
                rawDisplayText: 'Test Link',
                initialChildrenSpans: const [],
                initialPlainText: 'Test Link',
                normalStyle: const TextStyle(color: Colors.blue),
                hoverStyle: const TextStyle(color: Colors.red),
                tapRecognizer: recognizer,
                mouseCursor: SystemMouseCursors.click,
              ),
            ),
          ),
        );

        expect(recognizer.wasDisposed, isFalse);

        // Rebuild with SAME recognizer instance (e.g., parent rebuild without re-parse)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HoverableLinkSpan(
                key: const ValueKey('link'),
                url: 'https://example.com',
                rawDisplayText: 'Test Link',
                initialChildrenSpans: const [],
                initialPlainText: 'Test Link',
                normalStyle: const TextStyle(color: Colors.blue),
                hoverStyle: const TextStyle(color: Colors.red),
                tapRecognizer: recognizer,
                mouseCursor: SystemMouseCursors.click,
              ),
            ),
          ),
        );

        // Recognizer should NOT be disposed (same instance)
        expect(
          recognizer.wasDisposed,
          isFalse,
          reason: 'Same recognizer instance should not be disposed on rebuild',
        );
      });

      testWidgets('disposes recognizer when transitioning from non-null to null', (tester) async {
        final recognizer = TrackingTapGestureRecognizer()..onTap = () {};

        // Build with recognizer
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HoverableLinkSpan(
                key: const ValueKey('link'),
                url: 'https://example.com',
                rawDisplayText: 'Test Link',
                initialChildrenSpans: const [],
                initialPlainText: 'Test Link',
                normalStyle: const TextStyle(color: Colors.blue),
                hoverStyle: const TextStyle(color: Colors.red),
                tapRecognizer: recognizer,
                mouseCursor: SystemMouseCursors.click,
              ),
            ),
          ),
        );

        expect(recognizer.wasDisposed, isFalse);

        // Rebuild with null recognizer
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HoverableLinkSpan(
                key: ValueKey('link'),
                url: 'https://example.com',
                rawDisplayText: 'Test Link',
                initialChildrenSpans: [],
                initialPlainText: 'Test Link',
                normalStyle: TextStyle(color: Colors.blue),
                hoverStyle: TextStyle(color: Colors.red),
                tapRecognizer: null, // Changed to null
                mouseCursor: SystemMouseCursors.click,
              ),
            ),
          ),
        );

        // Old recognizer should be disposed
        expect(
          recognizer.wasDisposed,
          isTrue,
          reason: 'Recognizer should be disposed when replaced with null',
        );
      });
    });

    group('Widget Functionality', () {
      testWidgets('renders plain text correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HoverableLinkSpan(
                url: 'https://example.com',
                rawDisplayText: 'Click Here',
                initialChildrenSpans: [],
                initialPlainText: 'Click Here',
                normalStyle: TextStyle(color: Colors.blue),
                hoverStyle: TextStyle(color: Colors.red),
                tapRecognizer: null,
                mouseCursor: SystemMouseCursors.click,
              ),
            ),
          ),
        );

        expect(find.text('Click Here'), findsOneWidget);
      });

      testWidgets('renders with child spans correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HoverableLinkSpan(
                url: 'https://example.com',
                rawDisplayText: '**Bold Link**',
                initialChildrenSpans: [
                  TextSpan(
                    text: 'Bold Link',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
                normalStyle: TextStyle(color: Colors.blue),
                hoverStyle: TextStyle(color: Colors.red),
                tapRecognizer: null,
                mouseCursor: SystemMouseCursors.click,
              ),
            ),
          ),
        );

        expect(find.text('Bold Link'), findsOneWidget);
      });

      testWidgets('hover callback is invoked on enter and exit', (tester) async {
        bool? lastHoverState;
        String? lastUrl;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: HoverableLinkSpan(
                  url: 'https://example.com',
                  rawDisplayText: 'Hover Me',
                  initialChildrenSpans: const [],
                  initialPlainText: 'Hover Me',
                  normalStyle: const TextStyle(color: Colors.blue),
                  hoverStyle: const TextStyle(color: Colors.red),
                  tapRecognizer: null,
                  mouseCursor: SystemMouseCursors.click,
                  onHoverCallback: (url, displayText, {required isHovering}) {
                    lastUrl = url;
                    lastHoverState = isHovering;
                  },
                ),
              ),
            ),
          ),
        );

        // Create mouse gesture
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        // Move into the widget
        final center = tester.getCenter(find.text('Hover Me'));
        await gesture.moveTo(center);
        await tester.pump();

        expect(lastHoverState, isTrue);
        expect(lastUrl, 'https://example.com');

        // Move out of the widget
        await gesture.moveTo(Offset.zero);
        await tester.pump();

        expect(lastHoverState, isFalse);
      });
    });
  });
}
