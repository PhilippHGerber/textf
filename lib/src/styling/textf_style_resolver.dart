import 'package:flutter/material.dart';

import '../core/default_styles.dart';
import '../core/textf_limits.dart';
import '../core/textf_style_utils.dart';
import '../models/textf_token.dart';
import '../widgets/textf_options.dart';
import '../widgets/textf_options_data.dart';

/// A class responsible for resolving the final TextStyle for formatted text segments.
///
/// It orchestrates the application of styles based on the following precedence:
/// 1. Explicit styles defined in the pre-merged `TextfOptionsData` from the widget tree.
/// 2. Theme-based default styles derived from the application's `ThemeData`
///    (for code, links, highlight).
/// 3. Relative default styles from `DefaultStyles`
///    (for bold, italic, strikethrough, underline).
///
/// The resolved style is always merged with the provided `baseStyle`.
class TextfStyleResolver {
  /// Creates a style resolver from the given context.
  ///
  /// Extracts [ThemeData] and the pre-merged [TextfOptionsData] immediately.
  /// This ensures that no [BuildContext] is retained in the instance,
  /// preventing memory leaks when the resolver is cached by controllers
  /// that outlive the widget tree.
  factory TextfStyleResolver(BuildContext context) {
    return TextfStyleResolver.withState(
      theme: Theme.of(context),
      options: TextfOptions.maybeOf(context),
    );
  }

  /// Creates a style resolver directly from dependencies.
  ///
  /// Use this constructor if you have already extracted the theme and
  /// options from the context.
  TextfStyleResolver.withState({
    required ThemeData theme,
    required TextfOptionsData? options,
  })  : _theme = theme,
        _options = options;

  final ThemeData _theme;
  final TextfOptionsData? _options;

  /// Resolves the final TextStyle for a given format marker type and base style.
  ///
  /// Use this for standard formatting types like bold, italic, code, strikethrough,
  /// underline, highlight.
  /// For links, use `resolveLinkStyle` and `resolveLinkHoverStyle`.
  ///
  /// - [type]: The type of formatting marker (e.g., `FormatMarkerType.bold`).
  /// - [baseStyle]: The style of the text segment *before* applying this format.
  ///
  /// Returns the final `TextStyle` to be applied.
  TextStyle resolveStyle(FormatMarkerType type, TextStyle baseStyle) {
    // Handle script font size adjustment first
    TextStyle effectiveBaseStyle = baseStyle;

    if (type == FormatMarkerType.superscript || type == FormatMarkerType.subscript) {
      // Resolve the scale factor (Option -> Default)
      final double scaleFactor =
          _options?.scriptFontSizeFactor ?? DefaultStyles.scriptFontSizeFactor;

      // Apply scaling to the base style FIRST
      // This ensures that if the user only overrides color later, the size is already correct.
      final double currentSize = baseStyle.fontSize ?? DefaultStyles.defaultFontSize;
      effectiveBaseStyle = baseStyle.copyWith(fontSize: currentSize * scaleFactor);
    }

    // Get the effective style from the pre-merged TextfOptionsData first.
    final TextStyle? optionsStyle = _getStyleFromOptions(type);

    if (optionsStyle != null) {
      // Precedence 1: Use the style derived from TextfOptions
      return mergeTextStyles(effectiveBaseStyle, optionsStyle);
    } else {
      // Precedence 2 & 3: No TextfOptions override found, use Theme or Default fallback
      switch (type) {
        case FormatMarkerType.bold:
          return DefaultStyles.boldStyle(effectiveBaseStyle); // Relative default
        case FormatMarkerType.italic:
          return DefaultStyles.italicStyle(effectiveBaseStyle); // Relative default
        case FormatMarkerType.boldItalic:
          return DefaultStyles.boldItalicStyle(effectiveBaseStyle); // Relative default
        case FormatMarkerType.strikethrough:
          // No full style override from options, use default effect.
          // Check if a specific thickness is provided via options.
          final double finalThickness =
              _options?.strikethroughThickness ?? DefaultStyles.defaultStrikethroughThickness;

          // Apply the default strikethrough effect with the resolved thickness.
          return DefaultStyles.strikethroughStyle(
            effectiveBaseStyle,
            thickness: finalThickness,
          );
        case FormatMarkerType.code:
          return _getThemeBasedCodeStyle(effectiveBaseStyle); // Theme-based default
        case FormatMarkerType.underline:
          return DefaultStyles.underlineStyle(effectiveBaseStyle); // Relative default
        case FormatMarkerType.highlight:
          return _getThemeBasedHighlightStyle(effectiveBaseStyle); // Theme-based default
        case FormatMarkerType.superscript:
          return effectiveBaseStyle;
        case FormatMarkerType.subscript:
          return effectiveBaseStyle;
      }
    }
  }

  /// Resolves the final NORMAL TextStyle for a link.
  ///
  /// Checks TextfOptions first, then falls back to a theme-based style.
  /// Merges the result with the provided `baseStyle`.
  ///
  /// - [baseStyle]: The style of the link text *before* applying link-specific formatting
  ///                (might already include bold, italic etc. if the link is nested).
  ///
  /// Returns the final normal `TextStyle` for the link.
  TextStyle resolveLinkStyle(TextStyle baseStyle) {
    final TextStyle? optionsStyle = _options?.linkStyle;

    if (optionsStyle != null) {
      return mergeTextStyles(baseStyle, optionsStyle);
    }
    return _getThemeBasedLinkStyle(baseStyle);
  }

  /// Resolves the final HOVER TextStyle for a link.
  ///
  /// Checks TextfOptions first, then falls back to the normal link style.
  /// Merges the result with the provided `baseStyle`.
  ///
  /// - [baseStyle]: The style of the link text *before* applying link-specific formatting.
  ///
  /// Returns the final hover `TextStyle` for the link.
  TextStyle resolveLinkHoverStyle(TextStyle baseStyle) {
    // 1. Resolve the normal link style first
    final TextStyle normalLinkStyle = resolveLinkStyle(baseStyle);

    // 2. Try to get a hover-specific style from options, merging it onto the normalLinkStyle
    final TextStyle? optionsStyle = _options?.linkHoverStyle;

    if (optionsStyle == null) return normalLinkStyle;
    return mergeTextStyles(normalLinkStyle, optionsStyle);
  }

  /// Resolves the effective MouseCursor for a link.
  ///
  /// Checks TextfOptions first, then falls back to `DefaultStyles.linkMouseCursor`.
  MouseCursor resolveLinkMouseCursor() {
    return _options?.linkMouseCursor ?? DefaultStyles.linkMouseCursor;
  }

  /// Resolves the effective onLinkTap callback for a link.
  ///
  /// Checks TextfOptions for the callback. Returns null if none found.
  void Function(String url, String displayText)? resolveOnLinkTap() {
    return _options?.onLinkTap;
  }

  /// Resolves the effective onLinkHover callback for a link.
  ///
  /// Checks TextfOptions for the callback. Returns null if none found.
  void Function(String url, String displayText, {required bool isHovering})? resolveOnLinkHover() {
    return _options?.onLinkHover;
  }

  /// Resolves the effective placeholder alignment for a link widget.
  ///
  /// Checks TextfOptions. Defaults to [PlaceholderAlignment.baseline] if not found.
  PlaceholderAlignment resolveLinkAlignment() {
    return _options?.linkAlignment ?? PlaceholderAlignment.baseline;
  }

  /// Calculates the vertical padding required to achieve the script's visual
  /// displacement, respecting any overrides in the [TextfOptions].
  ///
  /// Superscript uses bottom padding (pushes text up when aligned to middle).
  /// Subscript uses top padding (pushes text down).
  ///
  /// The padding magnitude is `fontSize × offsetFactor × 2`, where the `× 2`
  /// comes from[TextfLimits.scriptAlignmentPaddingFactor] (because
  /// [PlaceholderAlignment.middle] centers the widget, so shifting the visual
  /// center by `offset` requires `2 × offset` padding).
  EdgeInsetsGeometry resolveScriptPadding({
    required TextStyle style,
    required bool isSuperscript,
  }) {
    final double fontSize = style.fontSize ?? DefaultStyles.defaultFontSize;

    final double? optionFactor =
        isSuperscript ? _options?.superscriptBaselineFactor : _options?.subscriptBaselineFactor;

    final double offsetFactor = optionFactor ??
        (isSuperscript
            ? DefaultStyles.superscriptBaselineFactor
            : DefaultStyles.subscriptBaselineFactor);

    final double offsetY = fontSize * offsetFactor;

    return isSuperscript
        ? EdgeInsets.only(bottom: offsetY.abs() * TextfLimits.scriptAlignmentPaddingFactor)
        : EdgeInsets.only(top: offsetY.abs() * TextfLimits.scriptAlignmentPaddingFactor);
  }

  /// Creates an [InlineSpan] representing a single script fragment.
  ///
  /// The returned span uses [WidgetSpan] with [PlaceholderAlignment.middle]
  /// and directional [Padding] (resolved via [resolveScriptPadding]) to
  /// vertically displace the text. The child [Text.rich] uses
  /// [TextScaler.noScaling] to prevent double-scaling.
  InlineSpan createScriptSpan({
    required String text,
    required TextStyle style,
    required bool isSuperscript,
  }) {
    final EdgeInsetsGeometry padding = resolveScriptPadding(
      style: style,
      isSuperscript: isSuperscript,
    );

    return WidgetSpan(
      // Aligning to middle keeps the widget anchored to the line center,
      // ensuring SelectionArea sorts it correctly (e.g. "E = mc2")
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: padding,
        child: Text.rich(
          TextSpan(text: text, style: style),
          // Disable scaling here to prevent double-scaling.
          // The parent RichText already applies the scaler
          // to WidgetSpan dimensions.
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
  }

  // --- Private Helper Methods ---

  /// Internal helper to retrieve the pre-merged style from the TextfOptionsData.
  /// Returns null if no option is defined for the given type.
  TextStyle? _getStyleFromOptions(FormatMarkerType type) {
    switch (type) {
      case FormatMarkerType.bold:
        return _options?.boldStyle;
      case FormatMarkerType.italic:
        return _options?.italicStyle;
      case FormatMarkerType.boldItalic:
        return _options?.boldItalicStyle;
      case FormatMarkerType.strikethrough:
        return _options?.strikethroughStyle;
      case FormatMarkerType.code:
        return _options?.codeStyle;
      case FormatMarkerType.underline:
        return _options?.underlineStyle;
      case FormatMarkerType.highlight:
        return _options?.highlightStyle;
      case FormatMarkerType.superscript:
        return _options?.superscriptStyle;
      case FormatMarkerType.subscript:
        return _options?.subscriptStyle;
    }
  }

  /// Internal helper to create the default code style based on the current theme.
  TextStyle _getThemeBasedCodeStyle(TextStyle baseStyle) {
    final ColorScheme colorScheme = _theme.colorScheme;

    final Color codeBackgroundColor = colorScheme.surfaceContainer;
    final Color codeForegroundColor = colorScheme.onSurfaceVariant;

    // Use monospace font family
    const String codeFontFamily = 'monospace';
    // Use the constant list directly from DefaultStyles
    const List<String> codeFontFamilyFallback = DefaultStyles.defaultCodeFontFamilyFallback;

    // Merge theme defaults with the base style
    return baseStyle.copyWith(
      fontFamily: codeFontFamily,
      fontFamilyFallback: codeFontFamilyFallback,
      backgroundColor: codeBackgroundColor,
      color: codeForegroundColor,
      letterSpacing: baseStyle.letterSpacing ?? 0,
    );
  }

  /// Internal helper to create the default link style based on the current theme.
  TextStyle _getThemeBasedLinkStyle(TextStyle baseStyle) {
    final Color themeLinkColor = _theme.colorScheme.primary;

    // Merge theme link appearance (color, decoration) ON TOP of the base style.
    return baseStyle.merge(
      TextStyle(
        color: themeLinkColor,
        decoration: TextDecoration.underline,
        decorationColor: themeLinkColor,
      ),
    );
  }

  /// Internal helper to create the default highlight style based on the current theme.
  TextStyle _getThemeBasedHighlightStyle(TextStyle baseStyle) {
    final ColorScheme colorScheme = _theme.colorScheme;

    // A common "highlighter yellow":
    final Color highlightBgColor = colorScheme.brightness == Brightness.light
        ? Colors.yellow.withValues(alpha: DefaultStyles.highlightAlphaLight)
        : Colors.yellow.shade700.withValues(alpha: DefaultStyles.highlightAlphaDark);
    final Color highlightTextColor = baseStyle.color ??
        (colorScheme.brightness == Brightness.light ? Colors.black87 : Colors.white);

    return baseStyle.copyWith(
      backgroundColor: highlightBgColor,
      color: highlightTextColor,
    );
  }
}
