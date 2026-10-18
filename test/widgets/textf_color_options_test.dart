// ignore_for_file: no-magic-number

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';
import 'package:textf/src/widgets/internal/hoverable_link_span.dart';
import 'package:textf/textf.dart';

import 'pump_textf_widget.dart';

// Neutral defaults and T-COLOPT-01..02 (+ highlight and thematic-break color options).
//
// Styles resolve in four tiers: an explicit `*Style` option (or `thematicBreakBuilder`) beats
// the matching color option, which beats the neutral default derived from the effective root
// style, which sits on the relative defaults. Every test here runs on the neutral `WidgetsApp`
// harness: no `Theme` is in scope, so nothing may depend on one.

const Color _black = Color(0xFF000000);
const Color _white = Color(0xFFFFFFFF);
const Color _brand = Color(0xFF6200EE);
const Color _translucentBrand = Color(0x806200EE);
const Color _red = Color(0xFFF44336);

const TextStyle _ambient = TextStyle(fontSize: 16, color: _black);

/// Pumps [data] under an ambient [ambient] style, optional [options] and a bounded width.
Future<void> _pump(
  WidgetTester tester,
  String data, {
  TextStyle ambient = _ambient,
  TextStyle? style,
  TextfOptions Function(Widget child)? options,
}) async {
  final Widget textf = Textf(data, style: style);
  await tester.pumpWidget(
    neutralTestApp(
      child: Center(
        child: SizedBox(
          width: 300,
          child: DefaultTextStyle(
            style: ambient,
            child: options == null ? textf : options(textf),
          ),
        ),
      ),
    ),
  );
}

/// The single rendered link.
HoverableLinkSpan _link(WidgetTester tester) =>
    tester.widget<HoverableLinkSpan>(find.byType(HoverableLinkSpan));

Color _ruleColor(WidgetTester tester) => tester.widget<ColoredBox>(defaultThematicBreakRule).color;

void main() {
  group('Neutral defaults (no Theme, no color options)', () {
    testWidgets('link: fixed #1A73E8 with a matching underline', (tester) async {
      await _pump(tester, '[docs](https://example.com)');

      final style = _link(tester).normalStyle;
      expect(style.color, const Color(0xFF1A73E8));
      expect(style.decoration, TextDecoration.underline);
      expect(style.decorationColor, const Color(0xFF1A73E8));
      expect(style.fontSize, 16, reason: 'typography comes from the effective root style');
    });

    testWidgets('link: the default blue does not follow the text color', (tester) async {
      await _pump(tester, '[docs](https://example.com)', ambient: const TextStyle(color: _white));

      expect(_link(tester).normalStyle.color, const Color(0xFF1A73E8));
    });

    testWidgets('code on dark text: monospace, base text color, foreground @ 0.05', (
      tester,
    ) async {
      await _pump(tester, 'a `code` b');

      final style = renderedSpanStyle(tester, 'code');
      expect(style.fontFamily, 'monospace');
      expect(style.fontFamilyFallback, DefaultStyles.defaultCodeFontFamilyFallback);
      expect(style.color, _black, reason: 'code text inherits the segment color');
      expect(style.backgroundColor, _black.withValues(alpha: 0.05));
    });

    testWidgets('code on light text (dark surface implied): foreground @ 0.15', (tester) async {
      await _pump(tester, 'a `code` b', ambient: const TextStyle(color: _white));

      final style = renderedSpanStyle(tester, 'code');
      expect(style.color, _white);
      expect(style.backgroundColor, _white.withValues(alpha: 0.15));
    });

    testWidgets('code chip follows Textf.style color, not just the ambient one', (tester) async {
      await _pump(tester, 'a `code` b', style: const TextStyle(color: _white));

      expect(renderedSpanStyle(tester, 'code').backgroundColor, _white.withValues(alpha: 0.15));
    });

    testWidgets('highlight on dark text: light-surface yellow, base text color', (tester) async {
      await _pump(tester, 'a ==mark== b');

      final style = renderedSpanStyle(tester, 'mark');
      expect(style.backgroundColor, const Color(0xFFFFEB3B).withValues(alpha: 0.5));
      expect(style.color, _black);
    });

    testWidgets('highlight on light text: dark-surface yellow', (tester) async {
      await _pump(tester, 'a ==mark== b', ambient: const TextStyle(color: _white));

      final style = renderedSpanStyle(tester, 'mark');
      expect(style.backgroundColor, const Color(0xFFFBC02D).withValues(alpha: 0.4));
      expect(style.color, _white);
    });

    testWidgets('highlight without any text color falls back to near-black text', (
      tester,
    ) async {
      // A bare host: no ambient color at all, so the palette assumes black on a light surface.
      await _pump(tester, 'a ==mark== b', ambient: const TextStyle(fontSize: 16));

      expect(renderedSpanStyle(tester, 'mark').color, const Color(0xDD000000));
    });

    testWidgets('thematic break: 1px rule at the ambient text color @ 0.20', (tester) async {
      await _pump(tester, '---', ambient: const TextStyle(color: _red));

      expect(_ruleColor(tester), _red.withValues(alpha: 0.20));
      final box = tester.renderObject<RenderBox>(defaultThematicBreakRule);
      expect(box.size.height, 1);
      expect(box.size.width, 300);
    });

    testWidgets('thematic break: follows the effective root style color', (tester) async {
      await _pump(tester, '---', style: const TextStyle(color: _white));

      expect(_ruleColor(tester), _white.withValues(alpha: 0.20));
    });

    testWidgets('thematic break: black @ 0.20 when no text color is set', (tester) async {
      await _pump(tester, '---', ambient: const TextStyle(fontSize: 16));

      expect(_ruleColor(tester), _black.withValues(alpha: 0.20));
    });
  });

  group('T-COLOPT-01: linkColor tints the link and keeps its decoration', () {
    testWidgets('sets color and decorationColor, keeps the underline', (tester) async {
      await _pump(
        tester,
        '[docs](https://example.com)',
        options: (child) => TextfOptions(linkColor: _brand, child: child),
      );

      final style = _link(tester).normalStyle;
      expect(style.color, _brand);
      expect(style.decoration, TextDecoration.underline);
      expect(style.decorationColor, _brand);
      expect(style.fontSize, 16);
    });

    testWidgets('is applied verbatim, alpha included', (tester) async {
      await _pump(
        tester,
        '[docs](https://example.com)',
        options: (child) => TextfOptions(linkColor: _translucentBrand, child: child),
      );

      expect(_link(tester).normalStyle.color, _translucentBrand);
    });

    testWidgets('linkHoverStyle still merges on top of the tinted link', (tester) async {
      await _pump(
        tester,
        '[docs](https://example.com)',
        options: (child) => TextfOptions(
          linkColor: _brand,
          linkHoverStyle: const TextStyle(fontWeight: FontWeight.bold),
          child: child,
        ),
      );

      final hover = _link(tester).hoverStyle;
      expect(hover.color, _brand);
      expect(hover.decoration, TextDecoration.underline);
      expect(hover.fontWeight, FontWeight.bold);
    });

    testWidgets('linkStyle beats linkColor', (tester) async {
      await _pump(
        tester,
        '[docs](https://example.com)',
        options: (child) => TextfOptions(
          linkColor: _brand,
          linkStyle: const TextStyle(color: _red),
          child: child,
        ),
      );

      final style = _link(tester).normalStyle;
      expect(style.color, _red);
      expect(style.decoration, isNot(TextDecoration.underline), reason: 'linkStyle replaces');
    });

    testWidgets('nearest TextfOptions wins', (tester) async {
      await _pump(
        tester,
        '[docs](https://example.com)',
        options: (child) => TextfOptions(
          linkColor: _red,
          child: TextfOptions(linkColor: _brand, child: child),
        ),
      );

      expect(_link(tester).normalStyle.color, _brand);
    });
  });

  group('T-COLOPT-02: codeBackgroundColor tints the chip and keeps its typography', () {
    testWidgets('keeps monospace family, fallbacks and the text color', (tester) async {
      await _pump(
        tester,
        'a `code` b',
        options: (child) => TextfOptions(codeBackgroundColor: _brand, child: child),
      );

      final style = renderedSpanStyle(tester, 'code');
      expect(style.backgroundColor, _brand);
      expect(style.fontFamily, 'monospace');
      expect(style.fontFamilyFallback, DefaultStyles.defaultCodeFontFamilyFallback);
      expect(style.color, _black);
      expect(style.fontSize, 16);
    });

    testWidgets('is applied verbatim, alpha included', (tester) async {
      await _pump(
        tester,
        'a `code` b',
        options: (child) => TextfOptions(codeBackgroundColor: _translucentBrand, child: child),
      );

      expect(renderedSpanStyle(tester, 'code').backgroundColor, _translucentBrand);
    });

    testWidgets('codeStyle beats codeBackgroundColor', (tester) async {
      await _pump(
        tester,
        'a `code` b',
        options: (child) => TextfOptions(
          codeBackgroundColor: _brand,
          codeStyle: const TextStyle(backgroundColor: _red),
          child: child,
        ),
      );

      final style = renderedSpanStyle(tester, 'code');
      expect(style.backgroundColor, _red);
      expect(style.fontFamily, isNot('monospace'), reason: 'codeStyle replaces the default');
    });
  });

  group('highlightColor', () {
    testWidgets('replaces the highlight background verbatim, keeps the text color', (
      tester,
    ) async {
      await _pump(
        tester,
        'a ==mark== b',
        options: (child) => TextfOptions(highlightColor: _translucentBrand, child: child),
      );

      final style = renderedSpanStyle(tester, 'mark');
      expect(style.backgroundColor, _translucentBrand);
      expect(style.color, _black);
    });

    testWidgets('highlightStyle beats highlightColor', (tester) async {
      await _pump(
        tester,
        'a ==mark== b',
        options: (child) => TextfOptions(
          highlightColor: _brand,
          highlightStyle: const TextStyle(backgroundColor: _red),
          child: child,
        ),
      );

      expect(renderedSpanStyle(tester, 'mark').backgroundColor, _red);
    });
  });

  group('thematicBreakColor', () {
    testWidgets('colors the default 1px rule verbatim', (tester) async {
      await _pump(
        tester,
        '---',
        options: (child) => TextfOptions(thematicBreakColor: _translucentBrand, child: child),
      );

      expect(_ruleColor(tester), _translucentBrand);
      final box = tester.renderObject<RenderBox>(defaultThematicBreakRule);
      expect(box.size.height, 1);
      expect(box.size.width, 300);
    });

    testWidgets('thematicBreakBuilder beats thematicBreakColor', (tester) async {
      const customKey = Key('custom-rule');
      await _pump(
        tester,
        '---',
        options: (child) => TextfOptions(
          thematicBreakColor: _brand,
          thematicBreakBuilder: (_) => const SizedBox(key: customKey, height: 4),
          child: child,
        ),
      );

      expect(find.byKey(customKey), findsOneWidget);
      expect(defaultThematicBreakRule, findsNothing);
    });
  });
}
