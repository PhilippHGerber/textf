import 'package:flutter/material.dart';

/// Configuration options for Textf widgets in the widget tree.
///
/// Enables centralized configuration of formatting styles and
/// interaction behavior, especially for URLs.
class TextfOptions extends InheritedWidget {
  /// Callback function executed when tapping/clicking on a URL.
  final void Function(String url, String displayText)? onUrlTap;

  /// Callback function executed when hovering over a URL.
  /// The parameter [isHovering] is true when entering, false when leaving.
  final void Function(String url, String displayText, bool isHovering)? onUrlHover;

  /// Styling for URLs in normal state.
  final TextStyle? urlStyle;

  /// Styling for URLs in hover state.
  final TextStyle? urlHoverStyle;

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
    this.urlStyle,
    this.urlHoverStyle,
    this.boldStyle,
    this.italicStyle,
    this.boldItalicStyle,
    this.strikethroughStyle,
    this.codeStyle,
  });

  /// Default styling for URLs in normal state.
  static final TextStyle defaultUrlStyle = TextStyle(
    color: Colors.blue,
    decoration: TextDecoration.underline,
  );

  /// Default styling for URLs in hover state.
  static final TextStyle defaultUrlHoverStyle = TextStyle(
    color: Colors.blue[700],
    decoration: TextDecoration.underline,
  );

  /// Default styling for bold formatted text.
  static TextStyle defaultBoldStyle(TextStyle baseStyle) => baseStyle.copyWith(fontWeight: FontWeight.bold);

  /// Default styling for italic formatted text.
  static TextStyle defaultItalicStyle(TextStyle baseStyle) => baseStyle.copyWith(fontStyle: FontStyle.italic);

  /// Default styling for bold and italic formatted text.
  static TextStyle defaultBoldItalicStyle(TextStyle baseStyle) => baseStyle.copyWith(
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
      );

  /// Default styling for strikethrough text.
  static TextStyle defaultStrikethroughStyle(TextStyle baseStyle) =>
      baseStyle.copyWith(decoration: TextDecoration.lineThrough);

  /// Default styling for inline code text.
  static TextStyle defaultCodeStyle(TextStyle baseStyle) => baseStyle.copyWith(
        fontFamily: 'monospace',
        backgroundColor: const Color(0xFFF5F5F5),
        letterSpacing: 0,
      );

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
    return boldStyle ?? defaultBoldStyle(baseStyle);
  }

  /// Determines the effective style for italic formatted text.
  TextStyle getEffectiveItalicStyle(TextStyle baseStyle) {
    return italicStyle ?? defaultItalicStyle(baseStyle);
  }

  /// Determines the effective style for bold and italic formatted text.
  TextStyle getEffectiveBoldItalicStyle(TextStyle baseStyle) {
    return boldItalicStyle ?? defaultBoldItalicStyle(baseStyle);
  }

  /// Determines the effective style for strikethrough text.
  TextStyle getEffectiveStrikethroughStyle(TextStyle baseStyle) {
    return strikethroughStyle ?? defaultStrikethroughStyle(baseStyle);
  }

  /// Determines the effective style for inline code text.
  TextStyle getEffectiveCodeStyle(TextStyle baseStyle) {
    return codeStyle ?? defaultCodeStyle(baseStyle);
  }

  /// Determines the effective style for URLs in normal state.
  TextStyle getEffectiveUrlStyle(TextStyle baseStyle) {
    return (urlStyle ?? defaultUrlStyle).merge(baseStyle);
  }

  /// Determines the effective style for URLs in hover state.
  TextStyle getEffectiveUrlHoverStyle(TextStyle baseStyle) {
    final effectiveUrlStyle = getEffectiveUrlStyle(baseStyle);
    return (urlHoverStyle ?? defaultUrlHoverStyle).merge(effectiveUrlStyle);
  }

  @override
  bool updateShouldNotify(TextfOptions oldWidget) {
    return onUrlTap != oldWidget.onUrlTap ||
        onUrlHover != oldWidget.onUrlHover ||
        urlStyle != oldWidget.urlStyle ||
        urlHoverStyle != oldWidget.urlHoverStyle ||
        boldStyle != oldWidget.boldStyle ||
        italicStyle != oldWidget.italicStyle ||
        boldItalicStyle != oldWidget.boldItalicStyle ||
        strikethroughStyle != oldWidget.strikethroughStyle ||
        codeStyle != oldWidget.codeStyle;
  }
}
