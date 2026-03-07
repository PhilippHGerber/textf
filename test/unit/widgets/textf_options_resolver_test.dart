// ignore_for_file: no-magic-number, avoid-non-null-assertion

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/widgets/textf_options.dart';
import 'package:textf/src/widgets/textf_options_data.dart';

void main() {
  group('TextfOptionsData hashing and equality', () {
    testWidgets('returns null when no TextfOptions in tree', (tester) async {
      TextfOptionsData? data;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              data = TextfOptions.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(data, isNull);
    });

    testWidgets('returns non-null when TextfOptions present', (tester) async {
      TextfOptionsData? data;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            boldStyle: const TextStyle(fontWeight: FontWeight.bold),
            child: Builder(
              builder: (context) {
                data = TextfOptions.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(data, isNotNull);
      expect(data!.boldStyle?.fontWeight, FontWeight.bold);
    });

    testWidgets('different options produce unequal data', (tester) async {
      TextfOptionsData? data1;
      TextfOptionsData? data2;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            boldStyle: const TextStyle(fontWeight: FontWeight.bold),
            child: Builder(
              builder: (context) {
                data1 = TextfOptions.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            italicStyle: const TextStyle(fontStyle: FontStyle.italic),
            child: Builder(
              builder: (context) {
                data2 = TextfOptions.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(data1, isNotNull);
      expect(data2, isNotNull);
      expect(data1 == data2, isFalse);
      expect(data1.hashCode == data2.hashCode, isFalse);
    });

    testWidgets('merges styles from nested TextfOptions', (tester) async {
      TextfOptionsData? data;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            boldStyle: const TextStyle(color: Colors.red),
            child: TextfOptions(
              italicStyle: const TextStyle(fontStyle: FontStyle.italic),
              child: Builder(
                builder: (context) {
                  data = TextfOptions.maybeOf(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(data, isNotNull);
      // Both parent's bold and child's italic styles should be present
      expect(data!.boldStyle?.color, Colors.red);
      expect(data!.italicStyle?.fontStyle, FontStyle.italic);
    });

    testWidgets('same options produce equal data with same hashCode', (tester) async {
      TextfOptionsData? data1;
      TextfOptionsData? data2;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            boldStyle: const TextStyle(fontWeight: FontWeight.bold),
            child: Builder(
              builder: (context) {
                data1 = TextfOptions.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            boldStyle: const TextStyle(fontWeight: FontWeight.bold),
            child: Builder(
              builder: (context) {
                data2 = TextfOptions.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(data1 == data2, isTrue);
      expect(data1.hashCode, data2.hashCode);
    });

    testWidgets('includes all style properties in data', (tester) async {
      TextfOptionsData? data;
      // ignore: no-empty-block
      void onTap(String url, String text) {}
      // ignore: no-empty-block
      void onHover(String url, String text, {required bool isHovering}) {}

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            boldStyle: const TextStyle(fontWeight: FontWeight.bold),
            italicStyle: const TextStyle(fontStyle: FontStyle.italic),
            boldItalicStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            strikethroughStyle: const TextStyle(decoration: TextDecoration.lineThrough),
            codeStyle: const TextStyle(fontFamily: 'monospace'),
            underlineStyle: const TextStyle(decoration: TextDecoration.underline),
            highlightStyle: const TextStyle(backgroundColor: Colors.yellow),
            superscriptStyle: const TextStyle(fontSize: 10),
            subscriptStyle: const TextStyle(fontSize: 10),
            linkStyle: const TextStyle(color: Colors.blue),
            linkHoverStyle: const TextStyle(color: Colors.red),
            linkMouseCursor: SystemMouseCursors.click,
            linkAlignment: PlaceholderAlignment.middle,
            strikethroughThickness: 2,
            superscriptBaselineFactor: 0.4,
            subscriptBaselineFactor: 0.3,
            scriptFontSizeFactor: 0.6,
            onLinkTap: onTap,
            onLinkHover: onHover,
            child: Builder(
              builder: (context) {
                data = TextfOptions.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(data, isNotNull);
      expect(data!.boldStyle?.fontWeight, FontWeight.bold);
      expect(data!.italicStyle?.fontStyle, FontStyle.italic);
      expect(data!.linkStyle?.color, Colors.blue);
      expect(data!.linkMouseCursor, SystemMouseCursors.click);
      expect(data!.linkAlignment, PlaceholderAlignment.middle);
      expect(data!.strikethroughThickness, 2.0);
      expect(data!.superscriptBaselineFactor, 0.4);
      expect(data!.subscriptBaselineFactor, 0.3);
      expect(data!.scriptFontSizeFactor, 0.6);
      expect(data!.onLinkTap, onTap);
      expect(data!.onLinkHover, onHover);
    });
  });
}
