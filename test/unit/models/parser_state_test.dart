// ignore_for_file: cascade_invocations // cascade_invocations for readability and chaining methods.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textf/src/models/format_stack_entry.dart';
import 'package:textf/src/models/parser_state.dart';
import 'package:textf/src/models/token_type.dart';
import 'package:textf/src/styling/textf_style_resolver.dart';

// ---- Mock class for TextfStyleResolver ----
// This class simulates the behavior of the real resolver, allowing us to
// test ParserState in isolation. We can tell it which TextStyle to return
// for a given TokenType.
// ignore: prefer-match-file-name
class _MockTextfStyleResolver implements TextfStyleResolver {
  _MockTextfStyleResolver(this.context);
  // Ignore the unused 'context' field, as it's not needed for the mock.
  @override
  final BuildContext context;

  final Map<TokenType, TextStyle> _styleMap = {};

  // A method to configure the mock for a specific test.
  void whenResolveStyle(TokenType type, TextStyle styleToReturn) {
    _styleMap[type] = styleToReturn;
  }

  @override
  TextStyle resolveStyle(TokenType type, TextStyle baseStyle) {
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

  // Helper function to set up a valid BuildContext and mock resolver for each test.
  // It takes the `tester` from `testWidgets` to ensure it runs in a valid environment.
  Future<(BuildContext, _MockTextfStyleResolver)> setupTest(WidgetTester tester) async {
    // ignore: avoid-late-keyword
    late BuildContext mockContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            mockContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    final mockResolver = _MockTextfStyleResolver(mockContext);
    return (mockContext, mockResolver);
  }

  group('ParserState Tests', () {
    testWidgets('flushText does nothing when textBuffer is empty', (tester) async {
      // ARRANGE
      final (mockContext, mockResolver) = await setupTest(tester);
      final state = ParserState(
        tokens: [],
        baseStyle: baseStyle,
        matchingPairs: {},
        styleResolver: mockResolver,
      );

      // ACT
      state.flushText(mockContext);

      // ASSERT
      expect(state.spans, isEmpty, reason: 'Spans list should remain empty');
      expect(state.textBuffer, isEmpty, reason: 'Text buffer should still be empty');
    });

    testWidgets('flushText creates a simple TextSpan with baseStyle when formatStack is empty',
        (tester) async {
      // ARRANGE
      final (mockContext, mockResolver) = await setupTest(tester);
      final state = ParserState(
        tokens: [],
        baseStyle: baseStyle,
        matchingPairs: {},
        styleResolver: mockResolver,
      );
      state.textBuffer = 'Plain text';

      // ACT
      state.flushText(mockContext);

      // ASSERT
      expect(state.spans, hasLength(1), reason: 'One span should be created');
      final span = state.spans.first as TextSpan;
      expect(span.text, 'Plain text');
      expect(span.style, baseStyle, reason: 'The style should be the baseStyle');
      expect(state.textBuffer, isEmpty, reason: 'Text buffer should be cleared after flushing');
    });

    testWidgets('flushText applies a single style from the formatStack', (tester) async {
      // ARRANGE
      final (mockContext, mockResolver) = await setupTest(tester);

      // Configure the mock to return a bold style for boldMarker.
      const boldStyle = TextStyle(fontWeight: FontWeight.bold);
      mockResolver.whenResolveStyle(TokenType.boldMarker, boldStyle);

      final state = ParserState(
        tokens: [],
        baseStyle: baseStyle,
        matchingPairs: {},
        styleResolver: mockResolver,
      );
      state.textBuffer = 'Bold text';
      state.formatStack.add(
        const FormatStackEntry(index: 0, matchingIndex: 1, type: TokenType.boldMarker),
      );

      // ACT
      state.flushText(mockContext);

      // ASSERT
      expect(state.spans, hasLength(1));
      final span = state.spans.first as TextSpan;
      expect(span.text, 'Bold text');
      // The style should have the base properties plus the merged properties.
      expect(span.style?.fontWeight, FontWeight.bold);
      expect(
        span.style?.fontSize,
        baseStyle.fontSize,
        reason: 'Font size from base style should be preserved',
      );
      expect(
        span.style?.color,
        baseStyle.color,
        reason: 'Color from base style should be preserved',
      );
      expect(state.textBuffer, isEmpty);
    });

    testWidgets('flushText correctly applies multiple nested styles from the formatStack',
        (tester) async {
      // ARRANGE
      final (mockContext, mockResolver) = await setupTest(tester);
      const boldStyle = TextStyle(fontWeight: FontWeight.bold);
      const italicStyle =
          TextStyle(fontStyle: FontStyle.italic, color: Colors.red); // Overrides color
      mockResolver.whenResolveStyle(TokenType.boldMarker, boldStyle);
      mockResolver.whenResolveStyle(TokenType.italicMarker, italicStyle);

      final state = ParserState(
        tokens: [],
        baseStyle: baseStyle, // Black text
        matchingPairs: {},
        styleResolver: mockResolver,
      );
      state.textBuffer = 'Nested style';
      // Simulate a nested state: **_Text_**
      state.formatStack.add(
        const FormatStackEntry(index: 0, matchingIndex: 3, type: TokenType.boldMarker),
      );
      state.formatStack.add(
        const FormatStackEntry(index: 1, matchingIndex: 2, type: TokenType.italicMarker),
      );

      // ACT
      state.flushText(mockContext);

      // ASSERT
      expect(state.spans, hasLength(1));
      final span = state.spans.first as TextSpan;
      expect(span.text, 'Nested style');

      // Check if all styles were applied correctly.
      // The order of application in `flushText` is important.
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
