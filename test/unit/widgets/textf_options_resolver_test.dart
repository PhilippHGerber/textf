// ignore_for_file: no-magic-number, avoid-non-null-assertion

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/widgets/textf_options.dart';

void main() {
  const baseStyle = TextStyle(fontSize: 14, color: Colors.black);

  group('computeOptionsResolvedHash', () {
    testWidgets('returns 0 when no TextfOptions in tree', (tester) async {
      int? hash;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              hash = TextfOptions.computeResolvedHash(context, baseStyle);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(hash, 0);
    });

    testWidgets('returns non-zero when TextfOptions present', (tester) async {
      int? hash;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            boldStyle: const TextStyle(fontWeight: FontWeight.bold),
            child: Builder(
              builder: (context) {
                hash = TextfOptions.computeResolvedHash(context, baseStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(hash, isNot(0));
    });

    testWidgets('different options produce different hashes', (tester) async {
      int? hash1;
      int? hash2;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            boldStyle: const TextStyle(fontWeight: FontWeight.bold),
            child: Builder(
              builder: (context) {
                hash1 = TextfOptions.computeResolvedHash(context, baseStyle);
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
                hash2 = TextfOptions.computeResolvedHash(context, baseStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(hash1, isNot(hash2));
    });

    testWidgets('merges styles from nested TextfOptions', (tester) async {
      int? hash;

      await tester.pumpWidget(
        MaterialApp(
          home: TextfOptions(
            boldStyle: const TextStyle(color: Colors.red),
            child: TextfOptions(
              italicStyle: const TextStyle(fontStyle: FontStyle.italic),
              child: Builder(
                builder: (context) {
                  hash = TextfOptions.computeResolvedHash(context, baseStyle);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      expect(hash, isNot(0));
    });

    testWidgets('includes all style properties in hash', (tester) async {
      int? hash;

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
            // ignore: no-empty-block
            onLinkTap: (url, text) {},
            // ignore: no-empty-block
            onLinkHover: (url, text, {required isHovering}) {},
            child: Builder(
              builder: (context) {
                hash = TextfOptions.computeResolvedHash(context, baseStyle);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(hash, isNot(0));
    });
  });
}
