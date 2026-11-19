// ignore_for_file: no-magic-number

// This file verifies that Textf renders the same way inside a `material_ui` and a
// `cupertino_ui` app as in a bare WidgetsApp. Both packages are dev dependencies only.
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoApp, CupertinoPageScaffold;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show ColorScheme, MaterialApp, Scaffold, ThemeData;
import 'package:textf/src/widgets/internal/hoverable_link_span.dart';
import 'package:textf/textf.dart';

import 'pump_textf_widget.dart';

// T-ENV-01: Textf renders without errors and without theme lookups in every host.

const String _sample =
    '# Title\n'
    '**bold** *italic* ***both*** `code` ==mark== ~~strike~~ ++under++ '
    'H~2~O x^2^ [link](https://example.com) {icon}\n'
    '---\n'
    'end';

const Color _defaultLinkColor = Color(0xFF1A73E8);

/// A Textf exercising every construct, at a bounded width.
Widget _sampleTextf() {
  return const SizedBox(
    width: 400,
    child: Textf(
      _sample,
      style: TextStyle(fontSize: 16, color: Color(0xFF202020)),
      placeholders: {'icon': WidgetSpan(child: SizedBox(width: 8, height: 8))},
    ),
  );
}

/// Pumps [host], asserts it rendered cleanly, and returns the rendered link's color.
Future<Color?> _pumpAndCheck(WidgetTester tester, Widget host) async {
  await tester.pumpWidget(host);
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
  expect(find.byType(Textf), findsOneWidget);
  expect(find.byType(HoverableLinkSpan), findsOneWidget);
  return tester.widget<HoverableLinkSpan>(find.byType(HoverableLinkSpan)).normalStyle.color;
}

void main() {
  group('T-ENV-01: host environments', () {
    testWidgets('bare WidgetsApp', (tester) async {
      final linkColor = await _pumpAndCheck(tester, neutralTestApp(child: _sampleTextf()));

      expect(linkColor, _defaultLinkColor);
    });

    testWidgets('bare Directionality, no app at all', (tester) async {
      final linkColor = await _pumpAndCheck(
        tester,
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: _sampleTextf()),
        ),
      );

      expect(linkColor, _defaultLinkColor);
    });

    testWidgets('material_ui MaterialApp: a custom theme does not leak into the defaults', (
      tester,
    ) async {
      final linkColor = await _pumpAndCheck(
        tester,
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE91E63)),
          ),
          home: Scaffold(body: Center(child: _sampleTextf())),
        ),
      );

      expect(linkColor, _defaultLinkColor, reason: 'no Theme.of lookup feeds the link color');
    });

    testWidgets('material_ui MaterialApp in dark mode', (tester) async {
      final linkColor = await _pumpAndCheck(
        tester,
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(body: Center(child: _sampleTextf())),
        ),
      );

      expect(linkColor, _defaultLinkColor);
    });

    testWidgets('cupertino_ui CupertinoApp', (tester) async {
      final linkColor = await _pumpAndCheck(
        tester,
        CupertinoApp(
          home: CupertinoPageScaffold(child: Center(child: _sampleTextf())),
        ),
      );

      expect(linkColor, _defaultLinkColor);
    });

    testWidgets('color options apply identically in every host', (tester) async {
      const brand = Color(0xFF6200EE);
      Widget branded() => TextfOptions(linkColor: brand, child: _sampleTextf());

      for (final host in <Widget>[
        neutralTestApp(child: branded()),
        MaterialApp(
          home: Scaffold(body: Center(child: branded())),
        ),
        CupertinoApp(
          home: CupertinoPageScaffold(child: Center(child: branded())),
        ),
      ]) {
        expect(await _pumpAndCheck(tester, host), brand);
      }
    });
  });
}
