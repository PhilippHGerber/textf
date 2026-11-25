// ignore_for_file: no-magic-number

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/parsing/textf_parser.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';

// Flanking as observed through `TextfParser.parse()` (ADR 0009). Each span is
// rendered as its text wrapped in HTML-like tags for its formatting, and
// adjacent identical tags are merged, so an expectation reads like
// CommonMark's HTML output for single-level emphasis.

String _render(String text) {
  final spans = TextfParser().parse(
    text,
    const TextStyle(),
    TextfStyleResolver(options: null),
  );
  final out = StringBuffer();
  for (final span in spans) {
    if (span is! TextSpan) fail('unexpected span ${span.runtimeType}');
    final style = span.style;
    var piece = span.text ?? '';
    if (style?.fontWeight == FontWeight.bold) piece = '<strong>$piece</strong>';
    if (style?.fontStyle == FontStyle.italic) piece = '<em>$piece</em>';
    final decoration = style?.decoration;
    if (decoration != null && decoration.contains(TextDecoration.lineThrough)) {
      piece = '<del>$piece</del>';
    }
    if (decoration != null && decoration.contains(TextDecoration.underline)) {
      piece = '<u>$piece</u>';
    }
    if (style?.backgroundColor != null) piece = '<mark>$piece</mark>';
    out.write(piece);
  }
  return out
      .toString()
      .replaceAll('</em><em>', '')
      .replaceAll('</strong><strong>', '')
      .replaceAll('</del><del>', '')
      .replaceAll('</u><u>', '')
      .replaceAll('</mark><mark>', '');
}

void main() {
  group('footnote asterisks (#13)', () {
    test('two footnote asterisks stay literal', () {
      expect(_render('Price*, shipping* and discount'), 'Price*, shipping* and discount');
    });

    test('rows that were already correct stay unchanged', () {
      expect(_render('Price*'), 'Price*');
      expect(_render('Price* online only.\n*Incl. VAT.'), 'Price* online only.\n*Incl. VAT.');
      expect(_render('5 * 3 = 15'), '5 * 3 = 15');
      expect(_render(r'Price\*, shipping\*'), 'Price*, shipping*');
    });

    test('the punctuation rule applies to every flanking-checked marker', () {
      expect(_render('Price~~, cost~~ and fee'), 'Price~~, cost~~ and fee');
      expect(_render('Price==, cost== and fee'), 'Price==, cost== and fee');
      expect(_render('Price++, cost++ and fee'), 'Price++, cost++ and fee');
    });

    test('markers wrapping punctuated text at word boundaries still format', () {
      expect(_render('say **"hi"** now'), 'say <strong>"hi"</strong> now');
      expect(_render('(**bold**)'), '(<strong>bold</strong>)');
      expect(_render('**bold**, then more'), '<strong>bold</strong>, then more');
      expect(_render('~~gone~~.'), '<del>gone</del>.');
    });

    test('CJK: a closer after punctuation and before a letter no longer closes', () {
      // Accepted consequence in ADR 0009, shared with every CommonMark renderer.
      expect(_render('**重要。**です'), '**重要。**です');
      expect(_render('**重要**です'), '<strong>重要</strong>です');
    });
  });

  group('intraword underscore (#14)', () {
    test('underscores inside words stay literal', () {
      expect(_render('a_b_c and file_name_x'), 'a_b_c and file_name_x');
      expect(_render('snake__case__key'), 'snake__case__key');
    });

    test('underscores at word boundaries still format', () {
      expect(_render('_italic_ and __bold__'), '<em>italic</em> and <strong>bold</strong>');
      expect(_render('___both___'), '<em><strong>both</strong></em>');
    });

    test('asterisk keeps intraword emphasis', () {
      expect(_render('un*frigging*believable'), 'un<em>frigging</em>believable');
    });
  });

  // Delimiter runs longer than one token diverge from CommonMark until
  // issues/maximal-delimiter-runs lands. These pin today's behavior, so that
  // change shows up as a deliberate edit here.
  group('known divergences: runs split into several tokens', () {
    test('****foo**** (CommonMark: <strong><strong>foo</strong></strong>)', () {
      expect(_render('****foo****'), '****foo****');
    });

    test('~~~x~~~', () {
      expect(_render('~~~x~~~'), '~~~x~~~');
    });
  });

  // CommonMark 0.31 §6.2 examples, by spec example number. Only examples with
  // single-level emphasis are transcribed; excluded and why:
  // - nested emphasis the flat rendering can't express: 371, 375, 391,
  //   395-397, 401, 408-421, 426-435, 463, 465, 471-474
  // - links: 406, 424, 475, 476; raw HTML and autolinks: 477-479, 482, 483
  // - runs of four or more, the rule of 3 and unbalanced runs
  //   (issues/maximal-delimiter-runs): 423, 437, 439-461, 466-468, 470
  // - code spans inside emphasis: 480, 481
  // - `_` pairing with `*` (both italic), a pairing defect outside flanking: 367
  group('CommonMark §6.2 conformance', () {
    const cases = <(int, String, String)>[
      (352, '*foo bar*', '<em>foo bar</em>'),
      (353, 'a * foo bar*', 'a * foo bar*'),
      (354, 'a*"foo"*', 'a*"foo"*'),
      (355, '*\u00A0a\u00A0*', '*\u00A0a\u00A0*'),
      (357, 'foo*bar*', 'foo<em>bar</em>'),
      (358, '5*6*78', '5<em>6</em>78'),
      (359, '_foo bar_', '<em>foo bar</em>'),
      (360, '_ foo bar_', '_ foo bar_'),
      (361, 'a_"foo"_', 'a_"foo"_'),
      (362, 'foo_bar_', 'foo_bar_'),
      (363, '5_6_78', '5_6_78'),
      (364, 'пристаням_стремятся_', 'пристаням_стремятся_'),
      (365, 'aa_"bb"_cc', 'aa_"bb"_cc'),
      (366, 'foo-_(bar)_', 'foo-<em>(bar)</em>'),
      (368, '*foo bar *', '*foo bar *'),
      (369, '*foo bar\n*', '*foo bar\n*'),
      (370, '*(*foo)', '*(*foo)'),
      (372, '*foo*bar', '<em>foo</em>bar'),
      (373, '_foo bar _', '_foo bar _'),
      (374, '_(_foo)', '_(_foo)'),
      (376, '_foo_bar', '_foo_bar'),
      (377, '_пристаням_стремятся', '_пристаням_стремятся'),
      (378, '_foo_bar_baz_', '<em>foo_bar_baz</em>'),
      (379, '_(bar)_.', '<em>(bar)</em>.'),
      (380, '**foo bar**', '<strong>foo bar</strong>'),
      (381, '** foo bar**', '** foo bar**'),
      (382, 'a**"foo"**', 'a**"foo"**'),
      (383, 'foo**bar**', 'foo<strong>bar</strong>'),
      (384, '__foo bar__', '<strong>foo bar</strong>'),
      (385, '__ foo bar__', '__ foo bar__'),
      (386, '__\nfoo bar__', '__\nfoo bar__'),
      (387, 'a__"foo"__', 'a__"foo"__'),
      (388, 'foo__bar__', 'foo__bar__'),
      (389, '5__6__78', '5__6__78'),
      (390, 'пристаням__стремятся__', 'пристаням__стремятся__'),
      (392, 'foo-__(bar)__', 'foo-<strong>(bar)</strong>'),
      (393, '**foo bar **', '**foo bar **'),
      (394, '**(**foo)', '**(**foo)'),
      (398, '**foo**bar', '<strong>foo</strong>bar'),
      (399, '__foo bar __', '__foo bar __'),
      (400, '__(__foo)', '__(__foo)'),
      (402, '__foo__bar', '__foo__bar'),
      (403, '__пристаням__стремятся', '__пристаням__стремятся'),
      (404, '__foo__bar__baz__', '<strong>foo__bar__baz</strong>'),
      (405, '__(bar)__.', '<strong>(bar)</strong>.'),
      (407, '*foo\nbar*', '<em>foo\nbar</em>'),
      (422, '** is not an empty emphasis', '** is not an empty emphasis'),
      (425, '**foo\nbar**', '<strong>foo\nbar</strong>'),
      (436, '__ is not an empty emphasis', '__ is not an empty emphasis'),
      (438, 'foo ***', 'foo ***'),
      (462, '**foo**', '<strong>foo</strong>'),
      (464, '__foo__', '<strong>foo</strong>'),
      (469, '***foo***', '<em><strong>foo</strong></em>'),
      (356, r'*$*alpha.', r'*$*alpha.'),
      (356, '*£*bravo.', '*£*bravo.'),
      (356, '*€*charlie.', '*€*charlie.'),
      (356, '*\u{1E2FF}*delta.', '*\u{1E2FF}*delta.'),
    ];

    for (final (number, input, expected) in cases) {
      test('example $number: ${input.replaceAll('\n', r'\n')}', () {
        expect(_render(input), expected);
      });
    }
  });
}
