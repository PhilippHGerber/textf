// T-COLOPT-03: color options on TextfOptions / TextfOptionsData — equality, hashing,
// child ?? parent merging and diagnostics.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

const _brand = Color(0xFF6750A4);
const _other = Color(0xFF00897B);

/// Each color option, as a way to build [TextfOptionsData] with only that option set.
final Map<String, TextfOptionsData Function(Color? color)> _dataWith = {
  'linkColor': (c) => TextfOptionsData(linkColor: c),
  'codeBackgroundColor': (c) => TextfOptionsData(codeBackgroundColor: c),
  'highlightColor': (c) => TextfOptionsData(highlightColor: c),
  'thematicBreakColor': (c) => TextfOptionsData(thematicBreakColor: c),
};

/// Reads the merged [TextfOptionsData] a descendant of [tree] sees.
///
/// [tree] receives the probe widget and must place it below its `TextfOptions`.
Future<TextfOptionsData?> _mergedData(
  WidgetTester tester,
  Widget Function(Widget probe) tree,
) async {
  TextfOptionsData? data;
  await tester.pumpWidget(
    tree(
      Builder(
        builder: (context) {
          data = TextfOptions.maybeOf(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return data;
}

void main() {
  group('T-COLOPT-03 TextfOptionsData equality and hashing', () {
    for (final MapEntry(key: name, value: build) in _dataWith.entries) {
      test('$name: equal colors give equal data and equal hashCode', () {
        final a = build(_brand);
        final b = build(const Color(0xFF6750A4));

        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('$name: different colors give unequal data and different hashCode', () {
        final a = build(_brand);
        final b = build(_other);

        expect(a, isNot(equals(b)));
        expect(a.hashCode, isNot(b.hashCode));
      });

      test('$name: set versus unset gives unequal data', () {
        expect(build(_brand), isNot(equals(build(null))));
        expect(build(_brand), isNot(equals(const TextfOptionsData())));
      });

      test('$name: alpha participates in equality', () {
        final opaque = build(_brand);
        final translucent = build(_brand.withValues(alpha: 0.5));

        expect(opaque, isNot(equals(translucent)));
        expect(opaque.hashCode, isNot(translucent.hashCode));
      });
    }

    test('the four color options are distinct fields', () {
      final values = _dataWith.values.map((build) => build(_brand)).toList();

      for (var i = 0; i < values.length; i++) {
        for (var j = i + 1; j < values.length; j++) {
          expect(values[i], isNot(equals(values[j])), reason: 'option $i vs option $j');
        }
      }
    });
  });

  group('T-COLOPT-03 TextfOptions merges color options with child ?? parent', () {
    testWidgets('a single TextfOptions exposes its color options verbatim', (tester) async {
      final translucent = _brand.withValues(alpha: 0.35);
      final data = await _mergedData(
        tester,
        (probe) => TextfOptions(
          linkColor: _brand,
          codeBackgroundColor: translucent,
          highlightColor: _other,
          thematicBreakColor: const Color(0x33000000),
          child: probe,
        ),
      );

      expect(data?.linkColor, _brand);
      expect(data?.codeBackgroundColor, translucent);
      expect(data?.codeBackgroundColor?.a, closeTo(0.35, 0.001));
      expect(data?.highlightColor, _other);
      expect(data?.thematicBreakColor, const Color(0x33000000));
    });

    testWidgets('a descendant without color options inherits the ancestor colors', (
      tester,
    ) async {
      final data = await _mergedData(
        tester,
        (probe) => TextfOptions(
          linkColor: _brand,
          codeBackgroundColor: _brand,
          highlightColor: _brand,
          thematicBreakColor: _brand,
          child: TextfOptions(
            boldStyle: const TextStyle(fontWeight: FontWeight.w900),
            child: probe,
          ),
        ),
      );

      expect(data?.linkColor, _brand);
      expect(data?.codeBackgroundColor, _brand);
      expect(data?.highlightColor, _brand);
      expect(data?.thematicBreakColor, _brand);
      expect(data?.boldStyle?.fontWeight, FontWeight.w900);
    });

    testWidgets('the nearest color option wins, per option', (tester) async {
      final data = await _mergedData(
        tester,
        (probe) => TextfOptions(
          linkColor: _brand,
          codeBackgroundColor: _brand,
          highlightColor: _brand,
          thematicBreakColor: _brand,
          child: TextfOptions(
            linkColor: _other,
            thematicBreakColor: _other,
            child: probe,
          ),
        ),
      );

      expect(data?.linkColor, _other);
      expect(data?.codeBackgroundColor, _brand);
      expect(data?.highlightColor, _brand);
      expect(data?.thematicBreakColor, _other);
    });

    testWidgets('colors are inherited through several levels', (tester) async {
      final data = await _mergedData(
        tester,
        (probe) => TextfOptions(
          highlightColor: _brand,
          child: TextfOptions(
            codeBackgroundColor: _other,
            child: TextfOptions(
              linkColor: _other,
              child: probe,
            ),
          ),
        ),
      );

      expect(data?.linkColor, _other);
      expect(data?.codeBackgroundColor, _other);
      expect(data?.highlightColor, _brand);
      expect(data?.thematicBreakColor, isNull);
    });

    testWidgets('changing only a color option notifies dependents', (tester) async {
      var builds = 0;
      // One dependent instance reused across pumps: it rebuilds only when notified.
      final dependent = Builder(
        builder: (context) {
          TextfOptions.of(context);
          builds++;
          return const SizedBox.shrink();
        },
      );
      Widget tree(Color linkColor) => TextfOptions(linkColor: linkColor, child: dependent);

      await tester.pumpWidget(tree(_brand));
      await tester.pumpWidget(tree(_brand));
      expect(builds, 1, reason: 'equal options must not rebuild dependents');

      await tester.pumpWidget(tree(_other));
      expect(builds, 2, reason: 'a changed color option must rebuild dependents');
    });
  });

  group('T-COLOPT-03 TextfOptions diagnostics', () {
    DiagnosticsNode? property(TextfOptions options, String name) {
      final properties = options.toDiagnosticsNode().getProperties();
      return properties.where((p) => p.name == name).firstOrNull;
    }

    test('records each color option with its exact value', () {
      final translucent = _brand.withValues(alpha: 0.35);
      final options = TextfOptions(
        linkColor: _brand,
        codeBackgroundColor: translucent,
        highlightColor: _other,
        thematicBreakColor: const Color(0x33000000),
        child: const SizedBox.shrink(),
      );

      final expected = {
        'linkColor': _brand,
        'codeBackgroundColor': translucent,
        'highlightColor': _other,
        'thematicBreakColor': const Color(0x33000000),
      };
      for (final MapEntry(key: name, value: color) in expected.entries) {
        final node = property(options, name);
        expect(node, isA<ColorProperty>(), reason: name);
        expect(node?.value, color, reason: name);
        expect(node?.isFiltered(DiagnosticLevel.info), isFalse, reason: '$name is shown');
      }

      final description = options.toDiagnosticsNode().toStringDeep();
      for (final name in expected.keys) {
        expect(description, contains('$name:'));
      }
    });

    test('hides unset color options', () {
      const options = TextfOptions(child: SizedBox.shrink());

      for (final name in _dataWith.keys) {
        final node = property(options, name);
        expect(node, isNotNull, reason: '$name is registered');
        expect(node?.value, isNull, reason: name);
        expect(node?.isFiltered(DiagnosticLevel.info), isTrue, reason: '$name is hidden');
      }
      expect(options.toDiagnosticsNode().toStringDeep(), isNot(contains('Color:')));
    });
  });
}
