// ignore_for_file: no-magic-number

// `Theme` is imported only for the negative test: an ancestor design-system theme must not
// invalidate Textf's cache, because Textf no longer reads it.
import 'package:flutter/material.dart' show Theme, ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/styling/textf_palette.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/internal/textf_renderer.dart';
import 'package:textf/textf.dart';

import 'pump_textf_widget.dart';

// T-CACHE-01: renderer cache invalidation.
//
// The renderer re-parses only when a parser input changes: the data, placeholders, text scaler,
// the inherited TextfOptionsData, or the effective root style (ambient DefaultTextStyle merged
// with Textf.style, plus bold text). The effective root style is also the palette's source, so
// no further cache key — in particular no design-system theme — is needed (CACHE-5).

const Color _black = Color(0xFF000000);
const Color _white = Color(0xFFFFFFFF);
const String _data = 'a `code` b';

/// Parser that counts parse calls and otherwise parses normally.
class _CountingParser extends TextfParser {
  int parseCount = 0;

  @override
  List<InlineSpan> parse(
    String text,
    BuildContext context,
    TextStyle baseStyle, {
    TextScaler? textScaler,
    Map<String, InlineSpan>? placeholders,
    TextfStyleResolver? styleResolver,
    TextfPalette? palette,
  }) {
    parseCount++;
    return super.parse(
      text,
      context,
      baseStyle,
      textScaler: textScaler,
      placeholders: placeholders,
      styleResolver: styleResolver,
      palette: palette,
    );
  }
}

/// A [TextfRenderer] as `Textf` builds it, but with an injectable [parser].
Widget _renderer(TextfParser parser, {String data = _data, TextStyle? style}) {
  return TextfRenderer(
    data: data,
    style: style,
    parser: parser,
    strutStyle: null,
    textAlign: null,
    textDirection: null,
    locale: null,
    softWrap: null,
    overflow: null,
    textScaler: null,
    maxLines: null,
    semanticsLabel: null,
    textWidthBasis: null,
    textHeightBehavior: null,
    selectionColor: null,
  );
}

/// Hosts [child] under an ambient text [color] and an optional `codeBackgroundColor` option.
Widget _host(Widget child, {Color color = _black, Color? codeBackgroundColor}) {
  final Widget ambient = DefaultTextStyle(
    style: TextStyle(fontSize: 16, color: color),
    child: child,
  );
  return neutralTestApp(
    child: Center(
      child: codeBackgroundColor == null
          ? ambient
          : TextfOptions(codeBackgroundColor: codeBackgroundColor, child: ambient),
    ),
  );
}

/// The rendered background of the `code` span.
Color? _codeBackground(WidgetTester tester) => renderedSpanStyle(tester, 'code').backgroundColor;

void main() {
  group('T-CACHE-01: renderer cache invalidation', () {
    testWidgets('CACHE-5 proof: an ambient color change re-derives the palette', (tester) async {
      // The same const Textf instance under a black, then a white ambient color. Only the
      // effective root style changes; if it were not a cache key, the cached 0.05 chip would
      // survive the switch.
      const textf = Textf(_data);

      await tester.pumpWidget(_host(textf));
      expect(_codeBackground(tester), _black.withValues(alpha: 0.05));

      await tester.pumpWidget(_host(textf, color: _white));
      expect(_codeBackground(tester), _white.withValues(alpha: 0.15));
    });

    testWidgets('an ambient color change re-parses exactly once', (tester) async {
      final parser = _CountingParser();

      await tester.pumpWidget(_host(_renderer(parser)));
      await tester.pumpWidget(_host(_renderer(parser), color: _white));

      expect(parser.parseCount, 2);
    });

    testWidgets('a changed TextfOptionsData (color option) re-parses', (tester) async {
      final parser = _CountingParser();

      await tester.pumpWidget(
        _host(_renderer(parser), codeBackgroundColor: const Color(0xFF111111)),
      );
      await tester.pumpWidget(
        _host(_renderer(parser), codeBackgroundColor: const Color(0xFF222222)),
      );

      expect(parser.parseCount, 2);
      expect(_codeBackground(tester), const Color(0xFF222222));
    });

    testWidgets('a changed Textf.style re-parses', (tester) async {
      final parser = _CountingParser();

      await tester.pumpWidget(_host(_renderer(parser, style: const TextStyle(color: _black))));
      await tester.pumpWidget(_host(_renderer(parser, style: const TextStyle(color: _white))));

      expect(parser.parseCount, 2);
      expect(_codeBackground(tester), _white.withValues(alpha: 0.15));
    });

    testWidgets('identical inputs hit the cache', (tester) async {
      final parser = _CountingParser();

      await tester.pumpWidget(
        _host(_renderer(parser), codeBackgroundColor: const Color(0xFF111111)),
      );
      // New but equal DefaultTextStyle, TextfOptions and renderer instances.
      await tester.pumpWidget(
        _host(_renderer(parser), codeBackgroundColor: const Color(0xFF111111)),
      );

      expect(parser.parseCount, 1);
    });

    testWidgets('an ancestor Theme change does NOT invalidate the cache', (tester) async {
      final parser = _CountingParser();
      Widget themed(ThemeData theme) => _host(
        Theme(
          data: theme,
          child: _renderer(parser, data: '[link](url) and `code`'),
        ),
      );

      await tester.pumpWidget(themed(ThemeData.light()));
      await tester.pumpWidget(themed(ThemeData.dark()));
      await tester.pumpAndSettle();

      expect(parser.parseCount, 1, reason: 'Textf reads no design-system theme');
    });

    testWidgets('the default thematic-break rule follows an ambient color change', (
      tester,
    ) async {
      const textf = Textf('---');
      Color ruleColor() => tester.widget<ColoredBox>(defaultThematicBreakRule).color;

      await tester.pumpWidget(_host(const SizedBox(width: 200, child: textf)));
      expect(ruleColor(), _black.withValues(alpha: 0.20));

      await tester.pumpWidget(_host(const SizedBox(width: 200, child: textf), color: _white));
      expect(ruleColor(), _white.withValues(alpha: 0.20));
    });
  });
}
