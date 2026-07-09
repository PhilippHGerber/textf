// ignore_for_file: no-magic-number, avoid-non-null-assertion

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

/// Ticket 3 (options seam) checks for thematic breaks:
///  - the guarded default rule fills the paragraph width in a bounded frame and
///    does NOT throw when the `Textf` is hosted in an unbounded-width parent;
///  - a `TextfOptions.thematicBreakBuilder` overrides the default;
///  - the builder resolves through the option hierarchy (nearest ancestor wins).
void main() {
  group('Textf — thematic break options seam', () {
    // The default rule paints an opaque [ColoredBox] in the theme's
    // dividerColor; Material chrome contributes a separate *transparent* one, so
    // match on a non-zero alpha to isolate the rule.
    final defaultRule = find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color.a > 0,
    );

    const customKey = Key('custom-rule');
    const outerKey = Key('outer-rule');
    const innerKey = Key('inner-rule');

    Widget host(Widget child) => MaterialApp(
          home: Scaffold(body: Center(child: child)),
        );

    testWidgets('default rule fills the paragraph width in a bounded frame', (tester) async {
      await tester.pumpWidget(
        host(const SizedBox(width: 300, child: Textf('---'))),
      );

      expect(tester.takeException(), isNull);
      final box = tester.renderObject<RenderBox>(defaultRule);
      expect(box.size.width, 300, reason: 'the default rule fills the bounded width');
      expect(box.size.height, 1, reason: '1px rule');
    });

    testWidgets('default rule does not throw under an unbounded-width parent', (tester) async {
      // A Row gives its (non-flex) child unbounded horizontal constraints — the
      // real "unbounded width" `Text.rich` context the guard exists for.
      await tester.pumpWidget(
        host(const Row(children: [Textf('---')])),
      );

      expect(tester.takeException(), isNull, reason: 'the guard degrades to a finite width');
      expect(defaultRule, findsOneWidget, reason: 'the rule still renders');
    });

    testWidgets('a supplied thematicBreakBuilder overrides the default rule', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: TextfOptions(
              thematicBreakBuilder: _sizedRule(customKey),
              child: const Textf('---'),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(customKey), findsOneWidget, reason: 'the custom rule renders');
      expect(defaultRule, findsNothing, reason: 'the default rule is replaced');
    });

    testWidgets('nearest-ancestor TextfOptions wins for the builder', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: TextfOptions(
              thematicBreakBuilder: _sizedRule(outerKey),
              child: TextfOptions(
                thematicBreakBuilder: _sizedRule(innerKey),
                child: const Textf('---'),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(innerKey), findsOneWidget, reason: 'the nearest builder wins');
      expect(find.byKey(outerKey), findsNothing, reason: 'the farther builder is shadowed');
    });
  });
}

/// A const-constructible thematic-break builder rendering a keyed, colorless
/// [SizedBox] — so it never registers as the default rule's opaque `ColoredBox`.
Widget Function(BuildContext) _sizedRule(Key key) => (context) => SizedBox(key: key, height: 8);
