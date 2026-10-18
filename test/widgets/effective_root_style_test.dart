// ignore_for_file: no-magic-number

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/core/default_styles.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/styling/textf_palette.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/internal/textf_renderer.dart';
import 'package:textf/textf.dart';

import 'pump_textf_widget.dart';

// T-BASE-01..03: the effective root style.
//
// Textf computes one *effective root style* per render pass, the way Flutter's `Text.build`
// does: the ambient `DefaultTextStyle` merged with `Textf.style` (unless that style has
// `inherit: false`), then bolded when `MediaQuery.boldTextOf` is set. That single style is
// the parser's `baseStyle` and the source of the internal `TextfPalette`.

const Color _red = Color(0xFFF44336);
const Color _blue = Color(0xFF2196F3);
const Color _white = Color(0xFFFFFFFF);

/// Parser that counts parse calls and records the root style and palette it was given.
class _RecordingParser extends TextfParser {
  int parseCount = 0;
  TextStyle? lastBaseStyle;
  TextfPalette? lastPalette;

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
    lastBaseStyle = baseStyle;
    lastPalette = palette;
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
Widget _renderer(String data, TextfParser parser, {TextStyle? style}) {
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

/// Hosts [child] under an ambient [ambient] style and the given bold-text setting.
Widget _host({required Widget child, TextStyle? ambient, bool boldText = false}) {
  return neutralTestApp(
    child: MediaQuery(
      data: MediaQueryData(boldText: boldText),
      child: ambient == null ? child : DefaultTextStyle(style: ambient, child: child),
    ),
  );
}

/// Returns the style of the rendered [TextSpan] whose trimmed text is [text].
///
/// Searches every [RichText] (script spans render their own nested `Text.rich`).
TextStyle? _styleOf(WidgetTester tester, String text) {
  TextStyle? found;
  for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
    richText.text.visitChildren((span) {
      if (span is TextSpan && span.text?.trim() == text) {
        found = span.style;
        return false;
      }
      return true;
    });
    if (found != null) break;
  }
  expect(found, isNotNull, reason: 'No rendered TextSpan with text "$text"');
  return found;
}

void main() {
  group('T-BASE-01: relative sizes scale from the effective root style', () {
    testWidgets('h1 under ambient 28px with a color-only Textf.style renders at 56px', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ambient: const TextStyle(fontSize: 28),
          child: const Textf('# Title\nbody', style: TextStyle(color: _red)),
        ),
      );

      final heading = _styleOf(tester, 'Title');
      expect(heading?.fontSize, 56, reason: 'h1 = 28 × 2.0, not the 14px fallback × 2.0');
      expect(heading?.color, _red);

      final body = _styleOf(tester, 'body');
      expect(body?.fontSize, 28, reason: 'plain text keeps the ambient size');
      expect(body?.color, _red, reason: 'Textf.style still wins for the fields it sets');
    });

    testWidgets('every heading level scales from the ambient size', (tester) async {
      await tester.pumpWidget(
        _host(
          ambient: const TextStyle(fontSize: 40),
          child: const Textf(
            '# A\n## B\n### C\n#### D\n##### E\n###### F',
            style: TextStyle(color: _red),
          ),
        ),
      );

      const labels = ['A', 'B', 'C', 'D', 'E', 'F'];
      for (int i = 0; i < labels.length; i++) {
        expect(
          _styleOf(tester, labels[i])?.fontSize,
          closeTo(40 * DefaultStyles.headingFontSizeFactors[i], 0.001),
          reason: 'h${i + 1}',
        );
      }
    });

    testWidgets('superscript and subscript scale from the ambient size', (tester) async {
      await tester.pumpWidget(
        _host(
          ambient: const TextStyle(fontSize: 30),
          child: const Textf('E = mc^sup^ and H~sub~O', style: TextStyle(color: _red)),
        ),
      );

      const double scriptSize = 30 * DefaultStyles.scriptFontSizeFactor;
      for (final text in ['sup', 'sub']) {
        final style = _styleOf(tester, text);
        expect(style?.fontSize, closeTo(scriptSize, 0.001), reason: text);
        expect(style?.color, _red, reason: text);
      }
    });

    testWidgets('Textf.style fields override the ambient style field by field', (tester) async {
      await tester.pumpWidget(
        _host(
          ambient: const TextStyle(fontSize: 28, color: _blue, fontFamily: 'Ambient'),
          child: const Textf('# Big\nplain', style: TextStyle(fontSize: 10)),
        ),
      );

      final body = _styleOf(tester, 'plain');
      expect(body?.fontSize, 10);
      expect(body?.color, _blue, reason: 'unset fields inherit from DefaultTextStyle');
      expect(body?.fontFamily, 'Ambient');
      expect(_styleOf(tester, 'Big')?.fontSize, 20);
    });

    testWidgets('without Textf.style, the ambient style is the root style', (tester) async {
      await tester.pumpWidget(
        _host(
          ambient: const TextStyle(fontSize: 28, color: _blue),
          child: const Textf('# Hi'),
        ),
      );

      final heading = _styleOf(tester, 'Hi');
      expect(heading?.fontSize, 56);
      expect(heading?.color, _blue);
    });
  });

  group('T-BASE-02: inherit: false', () {
    testWidgets('a non-inheriting Textf.style ignores the ambient DefaultTextStyle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ambient: const TextStyle(fontSize: 28, color: _blue, fontFamily: 'Ambient'),
          child: const Textf(
            '# Head\nbody',
            style: TextStyle(inherit: false, fontSize: 12, color: _red),
          ),
        ),
      );

      final body = _styleOf(tester, 'body');
      expect(body?.fontSize, 12);
      expect(body?.color, _red);
      expect(body?.fontFamily, isNull, reason: 'ambient fontFamily must not leak in');
      expect(body?.inherit, isFalse);

      expect(_styleOf(tester, 'Head')?.fontSize, 24, reason: 'h1 = 12 × 2.0');
    });

    testWidgets('a non-inheriting ambient style is the root style when Textf.style is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ambient: const TextStyle(inherit: false, fontSize: 18, color: _blue),
          child: const Textf('# Head\nbody'),
        ),
      );

      final body = _styleOf(tester, 'body');
      expect(body?.fontSize, 18);
      expect(body?.color, _blue);
      expect(_styleOf(tester, 'Head')?.fontSize, 36);
    });

    testWidgets('ambient changes do not re-parse a non-inheriting Textf.style', (tester) async {
      final parser = _RecordingParser();
      const style = TextStyle(inherit: false, fontSize: 12, color: _red);

      await tester.pumpWidget(
        _host(
          ambient: const TextStyle(fontSize: 20),
          child: _renderer('**x**', parser, style: style),
        ),
      );
      expect(parser.parseCount, 1);

      await tester.pumpWidget(
        _host(
          ambient: const TextStyle(fontSize: 40, color: _blue),
          child: _renderer('**x**', parser, style: style),
        ),
      );
      expect(parser.parseCount, 1, reason: 'the effective root style did not change');
    });
  });

  group('T-BASE-03: MediaQuery.boldTextOf', () {
    testWidgets('bold text setting bolds the root style', (tester) async {
      await tester.pumpWidget(
        _host(
          boldText: true,
          ambient: const TextStyle(fontSize: 16),
          child: const Textf('plain _italic_', style: TextStyle(fontWeight: FontWeight.w300)),
        ),
      );

      expect(_styleOf(tester, 'plain')?.fontWeight, FontWeight.bold);
      expect(_styleOf(tester, 'italic')?.fontWeight, FontWeight.bold);
      expect(_styleOf(tester, 'italic')?.fontStyle, FontStyle.italic);
    });

    testWidgets('bold text setting applies to a non-inheriting Textf.style too', (tester) async {
      await tester.pumpWidget(
        _host(
          boldText: true,
          child: const Textf('plain', style: TextStyle(inherit: false, fontSize: 12)),
        ),
      );

      // Plain text takes the parser's fast path: one span carrying the root style.
      expect(_styleOf(tester, 'plain')?.fontWeight, FontWeight.bold);
    });

    testWidgets('without the setting, weights are left alone', (tester) async {
      await tester.pumpWidget(
        _host(
          ambient: const TextStyle(fontSize: 16),
          child: const Textf('plain _italic_', style: TextStyle(fontWeight: FontWeight.w300)),
        ),
      );

      expect(_styleOf(tester, 'plain')?.fontWeight, FontWeight.w300);
    });
  });

  group('Effective root style: parser input', () {
    testWidgets('the parser receives the effective root style as baseStyle', (tester) async {
      final parser = _RecordingParser();

      await tester.pumpWidget(
        _host(
          boldText: true,
          ambient: const TextStyle(fontSize: 28, color: _white),
          child: _renderer('**x**', parser, style: const TextStyle(fontFamily: 'Own')),
        ),
      );

      const expected = TextStyle(
        fontSize: 28,
        color: _white,
        fontFamily: 'Own',
        fontWeight: FontWeight.bold,
      );
      expect(parser.lastBaseStyle, expected);
      expect(
        parser.lastPalette,
        isNull,
        reason: 'a top-level parse derives its palette from baseStyle (see ParserState tests)',
      );
    });
  });

  group('Effective root style: cache invalidation', () {
    testWidgets('ambient font size change re-parses and rescales headings', (tester) async {
      await tester.pumpWidget(
        _host(
          ambient: const TextStyle(fontSize: 20),
          child: const Textf('# Hi', style: TextStyle(color: _red)),
        ),
      );
      expect(_styleOf(tester, 'Hi')?.fontSize, 40);

      await tester.pumpWidget(
        _host(
          ambient: const TextStyle(fontSize: 30),
          child: const Textf('# Hi', style: TextStyle(color: _red)),
        ),
      );
      expect(_styleOf(tester, 'Hi')?.fontSize, 60);
    });

    testWidgets('ambient color change re-parses', (tester) async {
      await tester.pumpWidget(
        _host(
          ambient: const TextStyle(color: _red),
          child: const Textf('**x**'),
        ),
      );
      expect(_styleOf(tester, 'x')?.color, _red);

      await tester.pumpWidget(
        _host(
          ambient: const TextStyle(color: _blue),
          child: const Textf('**x**'),
        ),
      );
      expect(_styleOf(tester, 'x')?.color, _blue);
    });

    testWidgets('bold text setting change re-parses', (tester) async {
      await tester.pumpWidget(_host(child: const Textf('_x_')));
      expect(_styleOf(tester, 'x')?.fontWeight, isNull);

      await tester.pumpWidget(_host(boldText: true, child: const Textf('_x_')));
      expect(_styleOf(tester, 'x')?.fontWeight, FontWeight.bold);

      await tester.pumpWidget(_host(child: const Textf('_x_')));
      expect(_styleOf(tester, 'x')?.fontWeight, isNull);
    });

    testWidgets('Textf.style change re-parses', (tester) async {
      final parser = _RecordingParser();

      await tester.pumpWidget(
        _host(
          child: _renderer('**x**', parser, style: const TextStyle(color: _red)),
        ),
      );
      await tester.pumpWidget(
        _host(
          child: _renderer('**x**', parser, style: const TextStyle(color: _blue)),
        ),
      );

      expect(parser.parseCount, 2);
      expect(parser.lastBaseStyle?.color, _blue);
    });

    testWidgets('identical effective root style does not re-parse', (tester) async {
      final parser = _RecordingParser();
      const ambient = TextStyle(fontSize: 20, color: _red);

      await tester.pumpWidget(_host(ambient: ambient, child: _renderer('**x**', parser)));
      await tester.pumpWidget(_host(ambient: ambient, child: _renderer('**x**', parser)));
      expect(parser.parseCount, 1, reason: 'unchanged inputs hit the span cache');

      // Restating an ambient field in Textf.style leaves the effective root style unchanged.
      await tester.pumpWidget(
        _host(
          ambient: ambient,
          child: _renderer('**x**', parser, style: const TextStyle(color: _red)),
        ),
      );
      expect(parser.parseCount, 1, reason: 'the effective root style is what is compared');
    });
  });
}
