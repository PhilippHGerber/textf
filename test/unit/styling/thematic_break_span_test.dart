import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/styling/textf_palette.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';

/// Reads the rule color out of a default thematic-break span by rendering it.
Future<Color> _pumpRuleColor(WidgetTester tester, InlineSpan span) async {
  final Widget child = (span as WidgetSpan).child;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: SizedBox(width: 100, child: child)),
    ),
  );
  return tester.widget<ColoredBox>(find.byType(ColoredBox)).color;
}

void main() {
  group('Default thematic-break span reuse (T-PERF-01)', () {
    final resolver = TextfStyleResolver.withState(options: null);

    test('the same resolved color yields the identical span across parses', () {
      final palette = TextfPalette(const TextStyle(color: Color(0xFF000000)));

      final InlineSpan first = resolver.resolveThematicBreak(palette);
      final InlineSpan second = resolver.resolveThematicBreak(palette);

      // Identity (not just equality) is what lets Flutter skip rebuilding the
      // rule's element when the surrounding text is re-parsed.
      expect(identical(first, second), isTrue);
      expect(
        identical((first as WidgetSpan).child, (second as WidgetSpan).child),
        isTrue,
      );
    });

    testWidgets('a different resolved color yields a span painted in that color', (tester) async {
      final InlineSpan dark = resolver.resolveThematicBreak(
        TextfPalette(const TextStyle(color: Color(0xFF000000))),
      );
      final InlineSpan light = resolver.resolveThematicBreak(
        TextfPalette(const TextStyle(color: Color(0xFFFFFFFF))),
      );

      expect(identical(dark, light), isFalse);
      expect(
        await _pumpRuleColor(tester, dark),
        const Color(0xFF000000).withValues(alpha: 0.2),
      );
      expect(
        await _pumpRuleColor(tester, light),
        const Color(0xFFFFFFFF).withValues(alpha: 0.2),
      );
    });

    testWidgets('spans stay correct when many distinct colors cycle through', (tester) async {
      // More distinct colors than any reasonable cache bound: every span must
      // still carry its own color, and a repeated color must still be reused.
      final List<Color> colors = [
        for (int i = 0; i < 40; i++) Color(i * 0x010203 + 0xFF000000),
      ];
      for (final Color color in colors) {
        final InlineSpan span = resolver.resolveThematicBreak(
          TextfPalette(TextStyle(color: color)),
        );
        expect(await _pumpRuleColor(tester, span), color.withValues(alpha: 0.2));
      }

      final palette = TextfPalette(TextStyle(color: colors.last));
      expect(
        identical(resolver.resolveThematicBreak(palette), resolver.resolveThematicBreak(palette)),
        isTrue,
      );
    });
  });
}
