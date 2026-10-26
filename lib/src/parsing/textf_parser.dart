import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../core/constants.dart';
import '../core/formatting_utils.dart';
import '../core/textf_token_cache.dart';
import '../models/format_stack_entry.dart';
import '../models/textf_token.dart';
import '../styling/textf_palette.dart';
import '../styling/textf_style_resolver.dart';
import '../widgets/internal/hoverable_link_span.dart';
import 'components/link_validator.dart';
import 'heading_region.dart';

/// Parser for formatted text that converts formatting markers into styled text spans.
///
/// The [TextfParser] is the single module that owns read-path parsing. It processes
/// tokenized text, identifies matching formatting markers, handles nesting, resolves
/// styling using `TextfStyleResolver` (considering options and neutral defaults), and
/// generates properly styled [InlineSpan] objects for rendering.
///
/// The parser itself is stateless: every call to [parse] runs a private parse run that
/// owns all per-parse state (spans, text buffer, format stack, palette, placeholders) and
/// the link and placeholder handling. Nothing outside this library can reach that state.
///
/// Key features:
/// - Style resolution aware of TextfOptions, with design-system-neutral defaults.
/// - Fast paths for empty or plain unformatted text.
/// - Handles nested formatting.
/// - Handles malformed formatting by treating unpaired markers as plain text.
/// - Escaped character support (handled by the tokenizer).
/// - Support for [link text](url) with nested formatting inside links.
/// - Support for widget placeholders via {key} syntax.
/// - Performance: Caches tokens and formatting pairs for frequently used text.
class TextfParser {
  /// Creates a new [TextfParser] instance.
  new();

  /// Clears the shared token cache.
  ///
  /// Call this method to free memory in low-memory situations,
  /// or when navigating away from text-heavy screens.
  ///
  /// The cache will automatically rebuild as text is parsed.
  static void clearCache() => TextfTokenCache.clearCache();

  /// Returns the number of entries currently in the shared token cache.
  ///
  /// Exposed for testing purposes to verify cache hit/miss behavior
  /// without needing to inject a mock tokenizer.
  static int get cacheLength => TextfTokenCache.cacheLength;

  /// Retrieves tokenized text and valid pairs, utilizing the shared LRU cache.
  /// Used internally by the parser and exposed for shared utilities (like `stripFormatting`).
  static TokenCacheEntry getCachedTokensAndPairs(String text) =>
      TextfTokenCache.getTokensAndPairs(text);

  /// Parses formatted text into a list of styled [InlineSpan] objects.
  ///
  /// 1. Handles fast paths for empty or plain text (text without any potential markers).
  /// 2. Fetches the tokens and the valid marker pairs from the shared token cache.
  /// 3. Runs a parse run over the tokens: plain text accumulates in a buffer, paired
  ///    markers push and pop formats, headings, thematic breaks, links and placeholders
  ///    flush the buffer and emit their spans, and unpaired markers or broken links render
  ///    as literal text.
  /// 4. Flushes the remaining buffered text and returns the spans.
  ///
  /// - [text]: The input string potentially containing formatting markers.
  /// - [baseStyle]: The *effective root style*: the style of unformatted text, the
  ///   foundation for styled segments, and the source of the parse's [TextfPalette].
  /// - [styleResolver]: The resolver to style the spans with.
  /// - [placeholders]: Optional map of spans to substitute into placeholders like `{icon}`.
  ///
  /// Returns a list of [InlineSpan] objects representing the styled text.
  List<InlineSpan> parse(
    String text,
    TextStyle baseStyle,
    TextfStyleResolver styleResolver, {
    Map<String, InlineSpan>? placeholders,
  }) {
    return _parseWithFastPaths(
      text,
      baseStyle,
      styleResolver,
      TextfPalette(baseStyle),
      placeholders,
    );
  }
}

/// Parses [text] with the empty-text and plain-text fast paths in front of a
/// parse run. Shared by the top-level parse and the nested parse of a link's text.
List<InlineSpan> _parseWithFastPaths(
  String text,
  TextStyle baseStyle,
  TextfStyleResolver resolver,
  TextfPalette palette,
  Map<String, InlineSpan>? placeholders,
) {
  // Fast path for empty text
  if (text.isEmpty) {
    return <InlineSpan>[];
  }

  // Fast path for plain text without formatting markers
  // Note: FormattingUtils.hasFormatting checks for *any* potential marker,
  // including unpaired ones, link syntax characters, or braces.
  if (!FormattingUtils.hasFormatting(text)) {
    return <InlineSpan>[TextSpan(text: text, style: baseStyle)];
  }

  return _ParseRun(
    source: text,
    cacheEntry: TextfTokenCache.getTokensAndPairs(text),
    baseStyle: baseStyle,
    resolver: resolver,
    palette: palette,
    placeholders: placeholders,
  ).run();
}

/// The state and handling of one read-path parse.
///
/// Owns the token list, the valid pairs, the span list, the text buffer, the format
/// stack, the resolver, the palette and the placeholders. Link and placeholder handling
/// are private methods, so their flush and ordering rules live next to the loop that
/// depends on them. Heading regions are shared with the edit path through [HeadingRegion].
class _ParseRun with HeadingRegion {
  new({
    required this._source,
    required TokenCacheEntry cacheEntry,
    required this.baseStyle,
    required this._resolver,
    required this.palette,
    required this._placeholders,
  }) : _tokens = cacheEntry.tokens,
       _matchingPairs = cacheEntry.validPairs;

  final String _source;
  final List<TextfToken> _tokens;
  final Map<int, int> _matchingPairs;
  final TextfStyleResolver _resolver;
  final Map<String, InlineSpan>? _placeholders;
  final List<InlineSpan> _spans = [];

  @override
  final TextStyle baseStyle;

  /// Derived from the *effective root style* of the render pass, not from the
  /// style of the segment being resolved.
  @override
  final TextfPalette palette;

  @override
  final StringBuffer textBuffer = StringBuffer();

  @override
  final List<FormatStackEntry> formatStack = [];

  @override
  TextfStyleResolver get headingResolver => _resolver;

  /// Processes every token and returns the generated spans.
  List<InlineSpan> run() {
    int i = 0;
    while (i < _tokens.length) {
      final token = _tokens[i];

      // Placeholder Handling
      if (token is PlaceholderToken) {
        _processPlaceholder(token);
        i++;
        continue;
      }

      // Heading Handling (line-prefix ATX marker, scoped to end of line)
      if (token is HeadingToken) {
        flushText();
        endHeading();
        beginHeading(token.level);
        i++;
        continue;
      }

      // Heading suffix (trailing whitespace + optional closing `#` run) is a
      // consumed region: the read-only view renders nothing for it. The still
      // buffered content flushes at the line terminator (or final flush).
      if (token is HeadingSuffixToken) {
        i++;
        continue;
      }

      // Thematic break (`---`, `***`, `___`): flush any pending text, then
      // insert the rule as a WidgetSpan. The line terminator that followed the
      // rule is a separate TextToken and resumes ordinary text after it.
      if (token is ThematicBreakToken) {
        flushText();
        _spans.add(_resolver.resolveThematicBreak(palette));
        i++;
        continue;
      }

      // Link Handling
      if (token is LinkStartToken) {
        final int? nextIndex = _processLink(i);
        if (nextIndex != null) {
          i = nextIndex;
          continue;
        }
        // Not a valid link. Fall through to process as plain text.
      }

      // Formatting Handling
      if (token is FormatMarkerToken) {
        final int? matchingIndex = _matchingPairs[i];
        if (matchingIndex != null) {
          flushText();
          if (matchingIndex > i) {
            _pushFormat(i);
          } else {
            _popFormat(i);
          }
          i++;
          continue;
        }
        // Unpaired or invalidly nested marker. Fall through to process as plain text.
      }

      // Plain Text Handling
      // Accumulate content into the buffer. This applies to:
      // 1. TextToken
      // 2. Unpaired/Invalid FormatMarkerTokens
      // 3. Broken/Partial Link tokens
      switch (token) {
        case TextToken(:final value):
          appendText(value);
        case FormatMarkerToken(:final value):
          textBuffer.write(value);
        case LinkStartToken():
          textBuffer.write('[');
        case LinkSeparatorToken():
          textBuffer.write('](');
        case LinkEndToken():
          textBuffer.write(')');
        case PlaceholderToken(:final key):
          textBuffer.write('{$key}');
        case HeadingToken(:final position, :final contentStart):
          // ignore: avoid-substring
          textBuffer.write(_source.substring(position, contentStart));
        case HeadingSuffixToken():
          // Handled above (consumed, renders nothing); unreachable here.
          break;
        case ThematicBreakToken():
          // Handled above (emits a WidgetSpan rule); unreachable here.
          break;
        case EscapeMarkerToken():
          // Do nothing. This effectively strips the '\' from the visual output.
          break;
      }
      i++;
    }

    flushText();

    return _spans;
  }

  /// Flushes the accumulated [textBuffer] as a span in the current style.
  ///
  /// Text inside a superscript or subscript becomes a script span; anything else
  /// a plain `TextSpan`.
  @override
  void flushText() {
    if (textBuffer.isEmpty) return;

    final String text = textBuffer.toString();
    final TextStyle resolvedStyle = _currentStyle();

    final bool isSuperscript = formatStack.any((e) => e.type == FormatMarkerType.superscript);
    final bool isSubscript = formatStack.any((e) => e.type == FormatMarkerType.subscript);

    if (isSuperscript || isSubscript) {
      _spans.add(
        _resolver.createScriptSpan(
          text: text,
          style: resolvedStyle,
          isSuperscript: isSuperscript,
        ),
      );
    } else {
      _spans.add(TextSpan(text: text, style: resolvedStyle));
    }

    textBuffer.clear();
  }

  /// The current style: the stack top's pre-computed style, the active heading
  /// style (when the stack is empty inside a heading line), or [baseStyle].
  TextStyle _currentStyle() {
    if (formatStack.isNotEmpty) return formatStack.last.resolvedStyle;
    return headingStyle ?? baseStyle;
  }

  /// Pushes a format for the opening marker at [tokenIndex], caching the style
  /// it resolves to on top of [_currentStyle].
  void _pushFormat(int tokenIndex) {
    final TextfToken token = _tokens[tokenIndex];
    assert(token is FormatMarkerToken, 'pushFormat called with non-marker token');
    if (token is! FormatMarkerToken) return;

    final int? matchingIndex = _matchingPairs[tokenIndex];
    assert(matchingIndex != null, 'pushFormat called without a matching pair');
    if (matchingIndex == null) return;

    formatStack.add(
      FormatStackEntry(
        index: tokenIndex,
        matchingIndex: matchingIndex,
        type: token.markerType,
        resolvedStyle: _resolver.resolveStyle(token.markerType, _currentStyle(), palette),
      ),
    );
  }

  /// Pops the top entry for the closing marker at [closingTokenIndex].
  ///
  /// `PairValidator` guarantees proper nesting, so a mismatch is a bug.
  void _popFormat(int closingTokenIndex) {
    assert(
      formatStack.isNotEmpty && formatStack.last.matchingIndex == closingTokenIndex,
      'Closing marker does not match stack top - nesting validation failed',
    );
    if (formatStack.isEmpty || formatStack.last.matchingIndex != closingTokenIndex) {
      throw StateError('Closing marker does not match stack top');
    }

    formatStack.removeLast();
  }

  /// Substitutes a placeholder token.
  ///
  /// A known key flushes the preceding text (to keep the order) and inserts the
  /// user's span wrapped in the current style, so a `TextSpan` without its own
  /// style inherits the active formatting. An unknown key, or no placeholder map,
  /// appends the literal `{key}` without flushing, so `Hello {x}` stays one span.
  void _processPlaceholder(PlaceholderToken token) {
    final String key = token.key;
    final InlineSpan? span = _placeholders?[key];
    if (span == null) {
      textBuffer.write('{$key}');
      return;
    }

    flushText();
    _spans.add(TextSpan(style: _currentStyle(), children: [span]));
  }

  /// Processes a potential link structure starting at [index].
  ///
  /// Returns the index immediately following the link, or `null` when the tokens
  /// do not form a valid link. The structure is validated before flushing: a `[`
  /// that does not start a link stays in the current text run, which preserves
  /// ligatures and keeps the surrounding text in one span.
  int? _processLink(int index) {
    final parsedLink = LinkValidator.validate(_tokens, index);
    if (parsedLink == null) return null;

    flushText();

    final String rawLinkText = parsedLink.displayText;
    final String url = normalizeUrl(parsedLink.url);

    // Link styles and callbacks derive from the style inherited from formatting
    // markers outside the link.
    final linkConfig = _resolver.resolveLinkConfiguration(_currentStyle());
    final onTap = linkConfig.onTap;
    final TapGestureRecognizer? recognizer = onTap == null
        ? null
        : (TapGestureRecognizer()..onTap = () => onTap(url, rawLinkText));

    // One cache entry decides between plain text and child spans, and supplies the
    // tokens for stripping escapes. The nested parse run hits the same entry.
    final List<TextfToken> labelTokens = TextfTokenCache.getTokensAndPairs(rawLinkText).tokens;
    // Escapes carry no formatting of their own, so they alone don't need child spans.
    final bool needsChildSpans = labelTokens.any(
      (token) => token is! TextToken && token is! EscapeMarkerToken,
    );

    final hoverableWidget = HoverableLinkSpan(
      url: url,
      rawDisplayText: rawLinkText,
      initialChildrenSpans: needsChildSpans
          // A nested parse run reuses this run's resolver, palette and placeholders,
          // so link text needs no second `TextfOptions` lookup and its colors derive
          // from the effective root style, not from the link color.
          ? _parseWithFastPaths(rawLinkText, linkConfig.style, _resolver, palette, _placeholders)
          : const <InlineSpan>[],
      initialPlainText: needsChildSpans ? null : _plainLabel(rawLinkText, labelTokens),
      normalStyle: linkConfig.style,
      hoverStyle: linkConfig.hoverStyle,
      tapRecognizer: recognizer,
      mouseCursor: linkConfig.cursor,
      onHoverCallback: linkConfig.onHover,
    );

    // The inner Text in HoverableLinkSpan uses TextScaler.noScaling because RichText
    // already applies the textScaler to WidgetSpan dimensions.
    _spans.add(
      WidgetSpan(
        child: hoverableWidget,
        alignment: linkConfig.alignment,
        baseline: TextBaseline.alphabetic,
      ),
    );

    return index + kLinkTokenCount;
  }

  /// The display text of a plain link label: [rawLinkText] with the escape
  /// backslashes stripped.
  static String _plainLabel(String rawLinkText, List<TextfToken> labelTokens) {
    if (!labelTokens.any((token) => token is EscapeMarkerToken)) return rawLinkText;

    final buffer = StringBuffer();
    for (final token in labelTokens) {
      if (token is TextToken) buffer.write(token.value);
    }

    return buffer.toString();
  }
}
