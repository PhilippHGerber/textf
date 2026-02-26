// ignore_for_file: no-magic-number, avoid-late-keyword
//
// Hidden-marker layout trick — platform layout contribution tests.
//
// TextfSpanBuilder hides formatting markers by rendering them with a
// near-zero font size (0.01 px) and a negative letterSpacing (-0.02 px).
// The intent is that the hidden markers occupy zero — or sub-pixel — layout
// width, so they do not perturb the visible text layout.
//
// These tests measure the actual layout contribution of the hidden style
// and assert it stays below the acceptable threshold (0.5 px per raw
// character).  They run on the host platform during normal CI (macOS / Linux)
// and should also be executed on the full platform matrix:
//   • iOS        – flutter test --device-id <ios_device_id>
//   • Android    – flutter test --device-id <android_device_id>
//   • Web / CanvasKit – flutter test --platform chrome
//   • Web / HTML  – flutter test --platform chrome --web-renderer html
//
// Note: once the WidgetSpan FR (super/subscript) is implemented, the
// font-size trick will be replaced by SizedBox.shrink() for `^` and `~`
// markers.  At that point these tests apply only to the remaining format
// types that still use the tiny-font-size path (bold, italic, code, etc.).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/editing/textf_span_builder.dart';

void main() {
  // The exact TextStyle emitted by TextfSpanBuilder._resolveInactiveMarkerStyle
  // when opacity <= 0.0 (fully hidden path).  If the constants in
  // TextfSpanBuilder ever change, these tests will fail and draw attention
  // to the layout impact of the change.
  const hiddenStyle = TextStyle(
    color: Color(0x00000000),
    fontSize: 0.01,
    letterSpacing: -0.02,
  );

  // Acceptable layout contribution per raw character (logical pixels).
  // Each hidden marker character must contribute less than this to the
  // paragraph's advance width.
  const maxWidthPerChar = 0.5; // logical px

  // ---------------------------------------------------------------------------
  // Helper: lay out a single InlineSpan and return its painted width.
  // ---------------------------------------------------------------------------
  double measureSpan(InlineSpan span) {
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  // ---------------------------------------------------------------------------
  // Section 1: Direct TextStyle measurements
  //
  // These tests apply the hidden style to individual marker strings and verify
  // that the resulting TextPainter width is below the per-character threshold.
  // They are independent of TextfSpanBuilder and document the behaviour of
  // the hidden-style constants in isolation.
  // ---------------------------------------------------------------------------
  group('Hidden TextStyle — direct TextPainter measurements', () {
    double measureHidden(String text) => measureSpan(TextSpan(text: text, style: hiddenStyle));

    // Single-character markers (backtick `, caret ^, tilde ~).
    // letterSpacing has no effect on a single character (no gaps between chars),
    // so the full glyph advance at 0.01 px remains.  This is the worst case
    // for the trick.
    testWidgets('backtick (1 char) — width < $maxWidthPerChar px', (tester) async {
      expect(measureHidden('`'), lessThan(maxWidthPerChar));
    });

    testWidgets('caret ^ (1 char) — width < $maxWidthPerChar px', (tester) async {
      expect(measureHidden('^'), lessThan(maxWidthPerChar));
    });

    testWidgets('tilde ~ (1 char) — width < $maxWidthPerChar px', (tester) async {
      expect(measureHidden('~'), lessThan(maxWidthPerChar));
    });

    // Two-character markers (**, __, ~~, ==, ++).
    // Negative letterSpacing applies once between the two characters,
    // partially or fully cancelling the second character's advance.
    testWidgets('** (2 chars) — total width < ${maxWidthPerChar * 2} px', (tester) async {
      expect(measureHidden('**'), lessThan(maxWidthPerChar * 2));
    });

    testWidgets('~~ (2 chars) — total width < ${maxWidthPerChar * 2} px', (tester) async {
      expect(measureHidden('~~'), lessThan(maxWidthPerChar * 2));
    });

    testWidgets('== (2 chars) — total width < ${maxWidthPerChar * 2} px', (tester) async {
      expect(measureHidden('=='), lessThan(maxWidthPerChar * 2));
    });

    testWidgets('++ (2 chars) — total width < ${maxWidthPerChar * 2} px', (tester) async {
      expect(measureHidden('++'), lessThan(maxWidthPerChar * 2));
    });

    // Three-character marker (***).
    testWidgets('*** (3 chars) — total width < ${maxWidthPerChar * 3} px', (tester) async {
      expect(measureHidden('***'), lessThan(maxWidthPerChar * 3));
    });

    // Long URL — representative of the worst-case string length.
    // For N characters: total ≈ N × advance(0.01 px) + (N-1) × (-0.02 px).
    // The negative letter spacing should cancel most or all of the advances
    // for N ≥ 2.
    testWidgets('40-char URL — total width below threshold', (tester) async {
      const url = 'https://example.com/path?query=value#tag';
      expect(url.length, 40); // keep the test self-documenting
      expect(measureHidden(url), lessThan(maxWidthPerChar * url.length));
    });
  });

  // ---------------------------------------------------------------------------
  // Section 2: Integration measurements via TextfSpanBuilder
  //
  // These tests verify that the full builder pipeline produces hidden marker
  // spans whose combined width does not perturb the width of the visible text.
  // The cursor is placed after the end of the text so that all markers are
  // rendered in the inactive (hidden) style.
  // ---------------------------------------------------------------------------
  group('TextfSpanBuilder — hidden marker width vs visible content width', () {
    late TextfSpanBuilder builder;
    late BuildContext testContext;

    setUp(() {
      builder = TextfSpanBuilder();
      TextfSpanBuilder.clearCache();
    });

    /// Pumps a minimal MaterialApp and captures a BuildContext.
    Future<void> pumpContext(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              testContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    /// Builds spans with all markers in the fully-hidden inactive style
    /// (cursor placed beyond the end of [text]).
    List<InlineSpan> buildHidden(String text, TextStyle base) {
      return builder.build(
        text,
        testContext,
        base,
        cursorPosition: text.length + 1, // beyond all content → inactive
      );
    }

    testWidgets('**bold** — hidden markers add negligible width over bold text', (tester) async {
      await pumpContext(tester);
      const base = TextStyle(fontSize: 14);
      const text = '**bold**';

      final spans = buildHidden(text, base);
      final totalWidth = measureSpan(TextSpan(children: spans));

      // Reference: just the bold content without any markers.
      final refWidth = measureSpan(
        const TextSpan(
          text: 'bold',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );

      // The 4 hidden marker chars (**  and  **) must not add more than
      // 4 × maxWidthPerChar to the reference width.
      const markerChars = 4; // '**' + '**'
      expect(totalWidth, lessThan(refWidth + maxWidthPerChar * markerChars));
    });

    testWidgets('`code` — hidden markers add negligible width over code text', (tester) async {
      await pumpContext(tester);
      const base = TextStyle(fontSize: 14);
      const text = '`code`';

      final spans = buildHidden(text, base);
      final totalWidth = measureSpan(TextSpan(children: spans));

      // Reference: code text without markers.
      final refWidth = measureSpan(
        const TextSpan(
          text: 'code',
          style: TextStyle(fontSize: 14, fontFamily: 'monospace'),
        ),
      );

      const markerChars = 2; // opening ` + closing `
      expect(totalWidth, lessThan(refWidth + maxWidthPerChar * markerChars));
    });

    testWidgets('~~strike~~ — hidden markers add negligible width over plain text', (tester) async {
      await pumpContext(tester);
      const base = TextStyle(fontSize: 14);
      const text = '~~strike~~';

      final spans = buildHidden(text, base);
      final totalWidth = measureSpan(TextSpan(children: spans));

      final refWidth = measureSpan(
        const TextSpan(
          text: 'strike',
          style: TextStyle(fontSize: 14, decoration: TextDecoration.lineThrough),
        ),
      );

      const markerChars = 4; // ~~ + ~~
      expect(totalWidth, lessThan(refWidth + maxWidthPerChar * markerChars));
    });
  });
}
