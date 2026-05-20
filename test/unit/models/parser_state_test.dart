// ignore_for_file: cascade_invocations // cascade_invocations for readability and chaining methods.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/parser_state.dart';
import 'package:textf/src/models/textf_token.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';

// ---- Mock class for TextfStyleResolver ----
// This class simulates the behavior of the real resolver, allowing us to
// test ParserState in isolation. We can tell it which TextStyle to return
// for a given FormatMarkerType.
// ignore: prefer-match-file-name
class _MockTextfStyleResolver implements TextfStyleResolver {
  final Map<FormatMarkerType, TextStyle> _styleMap = {};

  // A method to configure the mock for a specific test.
  void whenResolveStyle(FormatMarkerType type, TextStyle styleToReturn) {
    _styleMap[type] = styleToReturn;
  }

  @override
  TextStyle resolveStyle(FormatMarkerType type, TextStyle baseStyle) {
    final style = _styleMap[type];
    if (style != null) {
      // Simulate the real resolver's behavior: the option style is
      // merged onto the base style.
      return baseStyle.merge(style);
    }
    // If no style is configured, just return the base style.
    return baseStyle;
  }

  // The remaining methods are not needed for this test and can be
  // implemented with an exception to ensure they are not accidentally called.
  @override
  TextStyle resolveLinkStyle(TextStyle baseStyle) => throw UnimplementedError();
  @override
  TextStyle resolveLinkHoverStyle(TextStyle baseStyle) => throw UnimplementedError();
  @override
  MouseCursor resolveLinkMouseCursor() => throw UnimplementedError();
  @override
  void Function(String url, String displayText)? resolveOnLinkTap() => throw UnimplementedError();
  @override
  void Function(String url, String displayText, {required bool isHovering})? resolveOnLinkHover() =>
      throw UnimplementedError();

  @override
  PlaceholderAlignment resolveLinkAlignment() => throw UnimplementedError();

  @override
  EdgeInsetsGeometry resolveScriptPadding({
    required TextStyle style,
    required bool isSuperscript,
  }) =>
      throw UnimplementedError();

  @override
  InlineSpan createScriptSpan({
    required String text,
    required TextStyle style,
    required bool isSuperscript,
  }) {
    // Return a dummy span for testing ParserState logic
    return WidgetSpan(child: Text(text, style: style));
  }
}

void main() {
  const baseStyle = TextStyle(fontSize: 16, color: Colors.black);
  const boldStyle = TextStyle(fontWeight: FontWeight.bold);
  const italicStyle = TextStyle(fontStyle: FontStyle.italic, color: Colors.red);
  const italicClosingIndex = 2;

  List<TextfToken> nestedFormatTokens() => const <TextfToken>[
        FormatMarkerToken(FormatMarkerType.bold, '**', position: 0, length: 2),
        FormatMarkerToken(FormatMarkerType.italic, '_', position: 2, length: 1),
        FormatMarkerToken(FormatMarkerType.italic, '_', position: 3, length: 1),
        FormatMarkerToken(FormatMarkerType.bold, '**', position: 4, length: 2),
      ];

  Map<int, int> nestedFormatPairs() => const <int, int>{
        0: 3,
        1: 2,
        2: 1,
        3: 0,
      };

  ParserState createState({
    List<TextfToken>? tokens,
    Map<int, int>? matchingPairs,
    _MockTextfStyleResolver? resolver,
  }) {
    final styleResolver = resolver ?? _MockTextfStyleResolver();
    return ParserState(
      tokens: tokens ?? const <TextfToken>[],
      baseStyle: baseStyle,
      matchingPairs: matchingPairs ?? const <int, int>{},
      styleResolver: styleResolver,
    );
  }

  group('ParserState Tests', () {
    test('currentStyle returns baseStyle when the stack is empty', () {
      final state = createState();

      expect(state.currentStyle(), baseStyle);
    });

    test('pushFormat for bold then italic returns the combined style', () {
      final mockResolver = _MockTextfStyleResolver()
        ..whenResolveStyle(FormatMarkerType.bold, boldStyle)
        ..whenResolveStyle(FormatMarkerType.italic, italicStyle);
      final state = createState(
        tokens: nestedFormatTokens(),
        matchingPairs: nestedFormatPairs(),
        resolver: mockResolver,
      );

      state.pushFormat(0);
      state.pushFormat(1);

      final resolvedStyle = state.currentStyle();
      expect(resolvedStyle.fontWeight, FontWeight.bold);
      expect(resolvedStyle.fontStyle, FontStyle.italic);
      expect(resolvedStyle.color, Colors.red);
      expect(resolvedStyle.fontSize, baseStyle.fontSize);
    });

    test('push and pop round-trip restores the previous style', () {
      final mockResolver = _MockTextfStyleResolver()
        ..whenResolveStyle(FormatMarkerType.bold, boldStyle)
        ..whenResolveStyle(FormatMarkerType.italic, italicStyle);
      final state = createState(
        tokens: nestedFormatTokens(),
        matchingPairs: nestedFormatPairs(),
        resolver: mockResolver,
      );

      state.pushFormat(0);
      final boldResolvedStyle = state.currentStyle();
      state.pushFormat(1);

      expect(state.currentStyle().fontStyle, FontStyle.italic);

      state.popFormat(italicClosingIndex);

      expect(state.currentStyle(), boldResolvedStyle);
    });

    test('popFormat on an empty stack triggers an assertion', () {
      final state = createState();

      expect(() => state.popFormat(0), throwsA(isA<AssertionError>()));
    });

    test('popFormat with a mismatched closing token triggers an assertion', () {
      final mockResolver = _MockTextfStyleResolver()
        ..whenResolveStyle(FormatMarkerType.bold, boldStyle);
      final state = createState(
        tokens: nestedFormatTokens(),
        matchingPairs: nestedFormatPairs(),
        resolver: mockResolver,
      );
      state.pushFormat(0);

      expect(() => state.popFormat(italicClosingIndex), throwsA(isA<AssertionError>()));
    });

    test('flushText does nothing when textBuffer is empty', () {
      final state = createState();

      state.flushText();

      expect(state.spans, isEmpty, reason: 'Spans list should remain empty');
      expect(state.textBuffer, isEmpty, reason: 'Text buffer should still be empty');
    });

    test('flushText creates a simple TextSpan with baseStyle when the stack is empty', () {
      final state = createState();
      state.textBuffer.write('Plain text');

      state.flushText();

      expect(state.spans, hasLength(1), reason: 'One span should be created');
      final span = state.spans.first as TextSpan;
      expect(span.text, 'Plain text');
      expect(span.style, baseStyle, reason: 'The style should be the baseStyle');
      expect(state.textBuffer, isEmpty, reason: 'Text buffer should be cleared after flushing');
    });

    test('flushText applies a single style from the stack', () {
      final mockResolver = _MockTextfStyleResolver()
        ..whenResolveStyle(FormatMarkerType.bold, boldStyle);
      final state = createState(
        tokens: nestedFormatTokens(),
        matchingPairs: nestedFormatPairs(),
        resolver: mockResolver,
      );
      state.textBuffer.write('Bold text');
      state.pushFormat(0);

      state.flushText();

      expect(state.spans, hasLength(1));
      final span = state.spans.first as TextSpan;
      expect(span.text, 'Bold text');
      expect(span.style?.fontWeight, FontWeight.bold);
      expect(span.style?.fontSize, baseStyle.fontSize, reason: 'base font size preserved');
      expect(span.style?.color, baseStyle.color, reason: 'base color preserved');
      expect(state.textBuffer, isEmpty);
    });

    test('flushText applies nested styles from the encapsulated stack API', () {
      final mockResolver = _MockTextfStyleResolver()
        ..whenResolveStyle(FormatMarkerType.bold, boldStyle)
        ..whenResolveStyle(FormatMarkerType.italic, italicStyle);
      final state = createState(
        tokens: nestedFormatTokens(),
        matchingPairs: nestedFormatPairs(),
        resolver: mockResolver,
      );
      state.textBuffer.write('Bold text');
      state.pushFormat(0);
      state.pushFormat(1);

      state.flushText();

      expect(state.spans, hasLength(1));
      final span = state.spans.first as TextSpan;
      expect(span.text, 'Bold text');
      expect(span.style?.fontWeight, FontWeight.bold, reason: 'Bold style should be applied');
      expect(span.style?.fontStyle, FontStyle.italic, reason: 'Italic style should be applied');
      expect(
        span.style?.color,
        Colors.red,
        reason: 'Italic style color should override base and bold color',
      );
      expect(
        span.style?.fontSize,
        baseStyle.fontSize,
        reason: 'Font size should be inherited from base',
      );
      expect(state.textBuffer, isEmpty);
    });
  });
}
