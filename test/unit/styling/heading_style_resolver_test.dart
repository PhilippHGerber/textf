// ignore_for_file: no-magic-number, avoid-late-keyword, avoid-non-null-assertion

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';
import 'package:textf/src/widgets/textf_options_data.dart';

/// Test-first specification for heading style resolution (case B11).
///
/// ----------------------------------------------------------------------------
/// ASSUMED API — NOT YET IMPLEMENTED. Expected to be RED until the heading
/// feature lands.
/// ----------------------------------------------------------------------------
///
/// [TextfStyleResolver] gains:
///
///   TextStyle resolveHeadingStyle(int level, TextStyle baseStyle);
///
/// Contract:
///  * `level` is 1..6.
///  * The result is MERGED on top of 'baseStyle' — base properties (e.g.
///    fontFamily, color) survive unless the heading style overrides them.
///  * Without any override, a sensible default scale is applied: H1 is the
///    largest, sizes decrease monotonically through H6, and headings are bold.
///  * When a custom heading style is supplied via [TextfOptionsData], it is
///    merged on top of the default/base — not used as a wholesale replacement.
///    (This test assumes `TextfOptionsData.headingStyle` as the override hook;
///    adjust the field name if the implementation differs.)
void main() {
  group('TextfStyleResolver.resolveHeadingStyle', () {
    const baseStyle = TextStyle(
      fontSize: 14,
      color: Color(0xFF123456),
      fontFamily: 'BaseFamily',
    );

    TextfStyleResolver resolverWith({TextfOptionsData? options}) {
      return TextfStyleResolver.withState(
        theme: ThemeData.light(),
        options: options,
      );
    }

    group('default scale', () {
      test('every level produces a usable, non-null style merged onto the base', () {
        final resolver = resolverWith();
        for (var level = 1; level <= 6; level++) {
          final style = resolver.resolveHeadingStyle(level, baseStyle);
          // Base properties survive the merge.
          expect(style.color, baseStyle.color, reason: 'level $level keeps base color');
          expect(style.fontFamily, baseStyle.fontFamily, reason: 'level $level keeps base family');
        }
      });

      test('font sizes decrease monotonically from H1 to H6', () {
        final resolver = resolverWith();
        final sizes = <double>[
          for (var level = 1; level <= 6; level++)
            resolver.resolveHeadingStyle(level, baseStyle).fontSize!,
        ];

        for (var i = 0; i < sizes.length - 1; i++) {
          expect(
            sizes[i],
            greaterThanOrEqualTo(sizes[i + 1]),
            reason: 'H${i + 1} must not be smaller than H${i + 2}',
          );
        }
        // H1 is the most prominent and at least as large as the base text.
        expect(sizes.first, greaterThanOrEqualTo(baseStyle.fontSize!));
        // H1 is strictly larger than H6 (the scale is not flat).
        expect(sizes.first, greaterThan(sizes.last));
      });

      test('headings are bold by default', () {
        final resolver = resolverWith();
        for (var level = 1; level <= 6; level++) {
          final weight = resolver.resolveHeadingStyle(level, baseStyle).fontWeight;
          expect(
            weight,
            anyOf(FontWeight.w600, FontWeight.w700, FontWeight.w800, FontWeight.bold),
            reason: 'level $level should be bold',
          );
        }
      });

      test('H2 default matches B11 expectation (level 2 resolves to the H2 default)', () {
        final resolver = resolverWith();
        final h2 = resolver.resolveHeadingStyle(2, baseStyle);
        final h1 = resolver.resolveHeadingStyle(1, baseStyle);
        final h3 = resolver.resolveHeadingStyle(3, baseStyle);

        expect(h2.fontSize, lessThanOrEqualTo(h1.fontSize!));
        expect(h2.fontSize, greaterThanOrEqualTo(h3.fontSize!));
      });
    });

    group('custom override', () {
      test('a per-level h{n}Style override applies and keeps untouched base properties', () {
        const customColor = Color(0xFFAB12CD);
        // Per-level override hook: h1Style applies to level-1 headings.
        final resolver = resolverWith(
          options: const TextfOptionsData(h1Style: TextStyle(color: customColor)),
        );

        final style = resolver.resolveHeadingStyle(1, baseStyle);

        // The custom color wins.
        expect(style.color, customColor);
        // Base family that the custom style did not touch survives the merge.
        expect(style.fontFamily, baseStyle.fontFamily);
      });

      test('a color-only override still inherits the default size and weight', () {
        const customColor = Color(0xFFAB12CD);
        final base = resolverWith();
        final overridden = resolverWith(
          options: const TextfOptionsData(h1Style: TextStyle(color: customColor)),
        );

        final defaultH1 = base.resolveHeadingStyle(1, baseStyle);
        final overriddenH1 = overridden.resolveHeadingStyle(1, baseStyle);

        // The delta (color) applies...
        expect(overriddenH1.color, customColor);
        // ...while the default heading scale and weight survive the merge.
        expect(overriddenH1.fontSize, defaultH1.fontSize);
        expect(overriddenH1.fontWeight, defaultH1.fontWeight);
        expect(overriddenH1.height, defaultH1.height);
      });

      test('an override may replace the default size and weight', () {
        final resolver = resolverWith(
          options: const TextfOptionsData(
            h3Style: TextStyle(fontSize: 99, fontWeight: FontWeight.w300),
          ),
        );

        final style = resolver.resolveHeadingStyle(3, baseStyle);

        expect(style.fontSize, 99);
        expect(style.fontWeight, FontWeight.w300);
        // Base color the override did not touch still survives.
        expect(style.color, baseStyle.color);
      });

      test('per-level overrides are independent (h2 override does not affect h1)', () {
        const h2Color = Color(0xFF00FF00);
        final resolver = resolverWith(
          options: const TextfOptionsData(h2Style: TextStyle(color: h2Color)),
        );
        final plain = resolverWith();

        // h2 picks up the override.
        expect(resolver.resolveHeadingStyle(2, baseStyle).color, h2Color);
        // h1 is unaffected and matches the un-overridden default.
        expect(
          resolver.resolveHeadingStyle(1, baseStyle).color,
          plain.resolveHeadingStyle(1, baseStyle).color,
        );
      });
    });

    group('cache correctness (re-resolution under a changed base)', () {
      test('the same heading level under two base styles yields distinct sizes', () {
        final resolver = resolverWith();

        const smallBase = TextStyle(fontSize: 10);
        const largeBase = TextStyle(fontSize: 40);

        final small = resolver.resolveHeadingStyle(1, smallBase);
        final large = resolver.resolveHeadingStyle(1, largeBase);

        // Heading size scales off the base; a stale result would collide.
        expect(small.fontSize, lessThan(large.fontSize!));
        expect(small.fontSize, smallBase.fontSize! * 2.0);
        expect(large.fontSize, largeBase.fontSize! * 2.0);
      });
    });
  });
}
