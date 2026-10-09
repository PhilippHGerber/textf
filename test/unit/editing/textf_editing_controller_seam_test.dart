// ignore_for_file: no-magic-number, avoid-non-null-assertion, avoid-late-keyword
// ignore_for_file: prefer-match-file-name, avoid-top-level-members-in-tests

/// Editing seam (PRD "Testing Seams" §2): `TextfEditingController.buildTextSpan`
/// styles text without any design-system theme in scope, dims inactive markers
/// from the text style alone, and re-parses exactly when one of its inputs
/// changes (`T-CACHE-02`).
///
/// Hosts are widgets-layer only (`Directionality`, `TextfOptions`) — no
/// `MaterialApp`, no `Theme`.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/textf.dart';

/// Dimmed-marker alpha, pinned from the spec (PRD §6 "Editing Marker").
const double _markerAlpha = 0.4;

/// Pumps a theme-free host and returns a [BuildContext] that `buildTextSpan`
/// can be called with, placed under whatever [wrap] builds (e.g. `TextfOptions`).
Future<BuildContext> _pumpHost(WidgetTester tester, {Widget Function(Widget child)? wrap}) async {
  late BuildContext captured;
  final Widget probe = Builder(
    builder: (context) {
      captured = context;
      return const SizedBox();
    },
  );
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: wrap == null ? probe : wrap(probe),
    ),
  );
  return captured;
}

TextSpan _build(
  TextfEditingController controller,
  BuildContext context, {
  TextStyle? style,
  bool withComposing = false,
}) {
  return controller.buildTextSpan(context: context, style: style, withComposing: withComposing);
}

List<TextSpan> _textChildren(TextSpan span) => span.children!.whereType<TextSpan>().toList();

TextSpan _spanWithText(TextSpan root, String text) =>
    _textChildren(root).firstWhere((s) => s.text == text);

int _slotCount(TextSpan root) {
  final children = root.children;
  if (children == null) return root.text?.length ?? 0;
  var slots = 0;
  for (final child in children) {
    if (child is TextSpan) slots += child.text?.length ?? 0;
    if (child is WidgetSpan) slots += 1;
  }
  return slots;
}

void main() {
  group('Editing seam: dimmed marker color', () {
    testWidgets('marker uses the style color at alpha 0.4', (tester) async {
      final controller = TextfEditingController(text: '**bold**');
      addTearDown(controller.dispose);
      final context = await _pumpHost(tester);

      final result = _build(controller, context, style: const TextStyle(color: Color(0xFF123456)));

      final markers = _textChildren(result).where((s) => s.text == '**').toList();
      expect(markers, hasLength(2));
      for (final marker in markers) {
        expect(marker.style!.color, const Color(0xFF123456).withValues(alpha: _markerAlpha));
      }
    });

    testWidgets('marker falls back to opaque black at alpha 0.4 when the style has no color', (
      tester,
    ) async {
      final controller = TextfEditingController(text: '**bold**');
      addTearDown(controller.dispose);
      final context = await _pumpHost(tester);

      final result = _build(controller, context, style: const TextStyle(fontSize: 18));

      final marker = _textChildren(result).first;
      expect(marker.text, '**');
      expect(marker.style!.color, const Color(0xFF000000).withValues(alpha: _markerAlpha));
      expect(marker.style!.fontSize, 18);
    });

    testWidgets('marker falls back to opaque black at alpha 0.4 when no style is given', (
      tester,
    ) async {
      final controller = TextfEditingController(text: '~~gone~~');
      addTearDown(controller.dispose);
      final context = await _pumpHost(tester);

      final result = _build(controller, context);

      expect(
        _textChildren(result).first.style!.color,
        const Color(0xFF000000).withValues(alpha: _markerAlpha),
      );
    });

    testWidgets('a translucent style color is replaced by alpha 0.4, not multiplied', (
      tester,
    ) async {
      final controller = TextfEditingController(text: '*it*');
      addTearDown(controller.dispose);
      final context = await _pumpHost(tester);

      final result = _build(controller, context, style: const TextStyle(color: Color(0x80FFFFFF)));

      expect(
        _textChildren(result).first.style!.color,
        const Color(0xFFFFFFFF).withValues(alpha: _markerAlpha),
      );
    });

    testWidgets('link brackets and URL are dimmed like any other marker', (tester) async {
      final controller = TextfEditingController(text: '[a](b)');
      addTearDown(controller.dispose);
      final context = await _pumpHost(tester);

      final result = _build(controller, context, style: const TextStyle(color: Color(0xFF334455)));

      final dimmed = const Color(0xFF334455).withValues(alpha: _markerAlpha);
      expect(_spanWithText(result, '[').style!.color, dimmed);
      expect(_spanWithText(result, 'a').style!.color, const Color(0xFF1A73E8));
      expect(_slotCount(result), '[a](b)'.length);
    });
  });

  group('Editing seam: active-line marker brightening', () {
    testWidgets('heading marker on the cursor line is heading-sized and dimmed; hidden off-line', (
      tester,
    ) async {
      const text = '# Title\nbody';
      final controller = TextfEditingController(
        text: text,
        markerVisibility: MarkerVisibility.whenActive,
      );
      addTearDown(controller.dispose);
      final context = await _pumpHost(tester);
      const style = TextStyle(color: Color(0xFF222222), fontSize: 10);

      controller.selection = const TextSelection.collapsed(offset: 3);
      final onLine = _build(controller, context, style: style);
      final activeMarker = _textChildren(onLine).first;
      expect(activeMarker.text, '# ');
      expect(activeMarker.style!.color, const Color(0xFF222222).withValues(alpha: _markerAlpha));
      expect(activeMarker.style!.fontSize, 20, reason: 'h1 = 2.0 x the 10px base');
      expect(_slotCount(onLine), text.length);

      controller.selection = const TextSelection.collapsed(offset: text.length);
      final offLine = _build(controller, context, style: style);
      expect(_textChildren(offLine).first.style!.color!.a, 0);
      expect(_slotCount(offLine), text.length);
    });

    testWidgets('slot count equals text length in every marker mode', (tester) async {
      const text = '**b** *i* ~~s~~ `c` [l](u) ^sup^ ~sub~ ==h== ++u++\n## H\n---';
      final context = await _pumpHost(tester);
      for (final visibility in MarkerVisibility.values) {
        for (final selection in [
          const TextSelection.collapsed(offset: 0),
          const TextSelection.collapsed(offset: 3),
          const TextSelection.collapsed(offset: 30),
          const TextSelection(baseOffset: 2, extentOffset: 12),
        ]) {
          final controller = TextfEditingController(text: text, markerVisibility: visibility)
            ..selection = selection;
          final result = _build(controller, context, style: const TextStyle(fontSize: 14));
          expect(_slotCount(result), text.length, reason: '$visibility / $selection');
          controller.dispose();
        }
      }
    });
  });

  group('Editing seam: cache invalidation (T-CACHE-02)', () {
    testWidgets('identical inputs reuse the cached spans', (tester) async {
      final controller = TextfEditingController(text: '**bold**');
      addTearDown(controller.dispose);
      final context = await _pumpHost(tester);
      const style = TextStyle(color: Color(0xFF000000));

      final first = _build(controller, context, style: style);
      final second = _build(controller, context, style: const TextStyle(color: Color(0xFF000000)));

      expect(identical(first.children, second.children), isTrue);
    });

    testWidgets('selection moves that cannot change the output reuse the cached spans', (
      tester,
    ) async {
      final always = TextfEditingController(text: '**a** **b**')
        ..selection = const TextSelection.collapsed(offset: 1);
      addTearDown(always.dispose);
      final whenActive = TextfEditingController(
        text: '**a** **b**',
        markerVisibility: MarkerVisibility.whenActive,
      )..selection = const TextSelection(baseOffset: 0, extentOffset: 3);
      addTearDown(whenActive.dispose);
      final context = await _pumpHost(tester);

      // MarkerVisibility.always shows every marker wherever the cursor is.
      final alwaysBefore = _build(always, context, style: const TextStyle());
      always.selection = const TextSelection.collapsed(offset: 8);
      final alwaysAfter = _build(always, context, style: const TextStyle());
      expect(identical(alwaysBefore.children, alwaysAfter.children), isTrue);

      // Any non-collapsed selection hides every marker, whatever its range.
      final rangeBefore = _build(whenActive, context, style: const TextStyle());
      whenActive.selection = const TextSelection(baseOffset: 2, extentOffset: 9);
      final rangeAfter = _build(whenActive, context, style: const TextStyle());
      expect(identical(rangeBefore.children, rangeAfter.children), isTrue);
    });

    testWidgets('a text change re-parses', (tester) async {
      final controller = TextfEditingController(text: '**bold**');
      addTearDown(controller.dispose);
      final context = await _pumpHost(tester);

      final first = _build(controller, context, style: const TextStyle());
      controller.text = '*it*';
      final second = _build(controller, context, style: const TextStyle());

      expect(identical(first.children, second.children), isFalse);
      expect(_spanWithText(second, 'it').style!.fontStyle, FontStyle.italic);
    });

    testWidgets('a cursor move re-parses when marker visibility depends on it', (tester) async {
      const text = '**a** **b**';
      final controller = TextfEditingController(
        text: text,
        markerVisibility: MarkerVisibility.whenActive,
      )..selection = const TextSelection.collapsed(offset: 1);
      addTearDown(controller.dispose);
      final context = await _pumpHost(tester);

      final first = _build(controller, context, style: const TextStyle());
      expect(_textChildren(first).first.style!.color!.a, greaterThan(0));

      controller.selection = const TextSelection.collapsed(offset: 8);
      final second = _build(controller, context, style: const TextStyle());

      expect(identical(first.children, second.children), isFalse);
      expect(_textChildren(second).first.style!.color!.a, 0, reason: 'first pair now inactive');
      expect(_slotCount(second), text.length);
    });

    testWidgets('a collapsed-to-range selection change re-parses and hides all markers', (
      tester,
    ) async {
      final controller = TextfEditingController(
        text: '**a**',
        markerVisibility: MarkerVisibility.whenActive,
      )..selection = const TextSelection.collapsed(offset: 2);
      addTearDown(controller.dispose);
      final context = await _pumpHost(tester);

      final first = _build(controller, context, style: const TextStyle());
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      final second = _build(controller, context, style: const TextStyle());

      expect(_textChildren(first).first.style!.color!.a, greaterThan(0));
      expect(identical(first.children, second.children), isFalse);
      for (final marker in _textChildren(second).where((s) => s.text == '**')) {
        expect(marker.style!.color!.a, 0);
      }
    });

    testWidgets('a composing change re-applies the IME underline', (tester) async {
      final controller = TextfEditingController(text: '**bold** tail');
      addTearDown(controller.dispose);
      final context = await _pumpHost(tester);

      final first = _build(controller, context, style: const TextStyle(), withComposing: true);
      controller.value = controller.value.copyWith(composing: const TextRange(start: 9, end: 13));
      final second = _build(controller, context, style: const TextStyle(), withComposing: true);

      expect(_spanWithText(first, ' tail').style?.decoration, isNot(TextDecoration.underline));
      expect(_spanWithText(second, 'tail').style!.decoration, TextDecoration.underline);
    });

    testWidgets('a style change re-parses and recolors markers and content', (tester) async {
      final controller = TextfEditingController(text: '**bold**');
      addTearDown(controller.dispose);
      final context = await _pumpHost(tester);

      final first = _build(controller, context, style: const TextStyle(color: Color(0xFF000000)));
      final second = _build(
        controller,
        context,
        style: const TextStyle(color: Color(0xFFFFFFFF)),
      );

      expect(identical(first.children, second.children), isFalse);
      expect(
        _textChildren(second).first.style!.color,
        const Color(0xFFFFFFFF).withValues(alpha: _markerAlpha),
      );
      expect(_spanWithText(second, 'bold').style!.color, const Color(0xFFFFFFFF));
    });

    testWidgets('a TextfOptionsData change re-parses with the new options', (tester) async {
      final controller = TextfEditingController(text: '**bold** [l](u)');
      addTearDown(controller.dispose);

      final contextA = await _pumpHost(
        tester,
        wrap: (child) => TextfOptions(linkColor: const Color(0xFF00AA00), child: child),
      );
      final first = _build(controller, contextA, style: const TextStyle());
      expect(_spanWithText(first, 'l').style!.color, const Color(0xFF00AA00));

      final contextB = await _pumpHost(
        tester,
        wrap: (child) => TextfOptions(
          linkColor: const Color(0xFFAA0000),
          boldStyle: const TextStyle(fontWeight: FontWeight.w900),
          child: child,
        ),
      );
      final second = _build(controller, contextB, style: const TextStyle());

      expect(identical(first.children, second.children), isFalse);
      expect(_spanWithText(second, 'l').style!.color, const Color(0xFFAA0000));
      expect(_spanWithText(second, 'bold').style!.fontWeight, FontWeight.w900);
    });
  });
}
