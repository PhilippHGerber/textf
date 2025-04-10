import 'package:flutter/material.dart';

import '../core/default_styles.dart';

/// Configuration options for Textf widgets in the widget tree.
///
/// Enables centralized configuration of formatting styles and
/// interaction behavior, especially for URLs.
class TextfOptions extends InheritedWidget {
  /// Callback function executed when tapping/clicking on a URL.
  ///
  /// Provides the resolved [url] (e.g., "https://example.com") and the raw
  /// [displayText] string exactly as it appeared between the square brackets
  /// `[...]` in the original input text.
  ///
  /// **Note:** The [displayText] includes any formatting markers (like `**`, `*`,
  /// `~~`, `` ` ``) present in the input source. It is *not* the processed plain
  /// text content that is visually rendered. Developers using this callback may
  /// need to strip or handle these markers separately if the plain text content
  /// is required.
  final void Function(String url, String displayText)? onUrlTap;

  /// Callback function executed when hovering over a URL.
  ///
  /// Provides the resolved [url], the raw [displayText] string (as found between
  /// `[...]` in the input), and a boolean [isHovering] which is `true` when
  /// the pointer enters the link region and `false` when it exits.
  ///
  /// **Note:** Similar to [onUrlTap], the [displayText] parameter contains the
  /// raw string from the input source, including any formatting markers. It is
  /// *not* the processed plain text content visually rendered.
  final void Function(String url, String displayText, bool isHovering)?
      onUrlHover;

  /// Styling for URLs in normal state.
  final TextStyle? urlStyle;

  /// Styling for URLs in hover state.
  final TextStyle? urlHoverStyle;

  /// The mouse cursor to use when hovering over a URL link.
  final MouseCursor? urlMouseCursor;

  // Formatting styles for text formatting
  /// Styling for bold formatted text.
  final TextStyle? boldStyle;

  /// Styling for italic formatted text.
  final TextStyle? italicStyle;

  /// Styling for bold and italic formatted text.
  final TextStyle? boldItalicStyle;

  /// Styling for strikethrough text.
  final TextStyle? strikethroughStyle;

  /// Styling for inline code text.
  final TextStyle? codeStyle;

  /// Creates a new TextfOptions instance.
  const TextfOptions({
    super.key,
    required super.child,
    this.onUrlTap,
    this.onUrlHover,
    this.urlMouseCursor,
    this.urlStyle,
    this.urlHoverStyle,
    this.boldStyle,
    this.italicStyle,
    this.boldItalicStyle,
    this.strikethroughStyle,
    this.codeStyle,
  });

  /// Looks for TextfOptions in the widget tree and returns it.
  /// Returns null if no instance was found.
  static TextfOptions? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TextfOptions>();
  }

  /// Looks for TextfOptions in the widget tree and returns it.
  /// Triggers an assertion if no instance was found.
  static TextfOptions of(BuildContext context) {
    final TextfOptions? result = maybeOf(context);
    assert(result != null, 'No TextfOptions found in context');
    return result!;
  }

  /// Determines the effective style for bold formatted text.
  TextStyle getEffectiveBoldStyle(TextStyle baseStyle) {
    return boldStyle ?? DefaultStyles.boldStyle(baseStyle);
  }

  /// Determines the effective style for italic formatted text.
  TextStyle getEffectiveItalicStyle(TextStyle baseStyle) {
    return italicStyle ?? DefaultStyles.italicStyle(baseStyle);
  }

  /// Determines the effective style for bold and italic formatted text.
  TextStyle getEffectiveBoldItalicStyle(TextStyle baseStyle) {
    return boldItalicStyle ?? DefaultStyles.boldItalicStyle(baseStyle);
  }

  /// Determines the effective style for strikethrough text.
  TextStyle getEffectiveStrikethroughStyle(TextStyle baseStyle) {
    return strikethroughStyle ?? DefaultStyles.strikethroughStyle(baseStyle);
  }

  /// Determines the effective style for inline code text.
  TextStyle getEffectiveCodeStyle(TextStyle baseStyle) {
    return codeStyle ?? DefaultStyles.codeStyle(baseStyle);
  }

  /// Determines the effective style for URLs in normal state.
  TextStyle getEffectiveUrlStyle(TextStyle baseStyle) {
    // Corrected Order: Properties from urlStyle (or default) override baseStyle
    return baseStyle.merge(urlStyle ?? DefaultStyles.urlStyle);
  }

  /// Determines the effective style for URLs in hover state.
  TextStyle getEffectiveUrlHoverStyle(TextStyle baseStyle) {
    final effectiveUrlStyle =
        getEffectiveUrlStyle(baseStyle); // Uses the corrected merge above
    // Now merge the base link style with the hover-specific style
    return effectiveUrlStyle
        .merge(urlHoverStyle ?? DefaultStyles.urlHoverStyle);
    // Note: Merging urlHoverStyle directly onto baseStyle might lose intermediate
    // urlStyle properties if urlHoverStyle doesn't define them. Merging onto
    // effectiveUrlStyle is safer.
  }

  /// Determines the effective mouse cursor for URLs.
  MouseCursor getEffectiveUrlMouseCursor() {
    return urlMouseCursor ?? DefaultStyles.urlMouseCursor;
  }

  @override
  bool updateShouldNotify(TextfOptions oldWidget) {
    return onUrlTap != oldWidget.onUrlTap ||
        onUrlHover != oldWidget.onUrlHover ||
        urlStyle != oldWidget.urlStyle ||
        urlHoverStyle != oldWidget.urlHoverStyle ||
        urlMouseCursor != oldWidget.urlMouseCursor ||
        boldStyle != oldWidget.boldStyle ||
        italicStyle != oldWidget.italicStyle ||
        boldItalicStyle != oldWidget.boldItalicStyle ||
        strikethroughStyle != oldWidget.strikethroughStyle ||
        codeStyle != oldWidget.codeStyle;
  }
}
