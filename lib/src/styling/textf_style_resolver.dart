import 'package:flutter/material.dart';

import '../core/default_styles.dart';
import '../models/token_type.dart';
import '../widgets/textf_options.dart'; // Needed for options lookup

/// A class responsible for resolving the final TextStyle for formatted text segments.
///
/// It orchestrates the application of styles based on the following precedence:
/// 1. Explicit styles defined in the nearest ancestor `TextfOptions`.
/// 2. Styles inherited from higher `TextfOptions` ancestors.
/// 3. Theme-based default styles derived from the application's `ThemeData`
///    (for code, links, highlight).
/// 4. Relative default styles from `DefaultStyles`
///    (for bold, italic, strikethrough, underline).
///
/// The resolved style is always merged with the provided `baseStyle`.
class TextfStyleResolver {
  /// Creates a style resolver for the given context.
  TextfStyleResolver(this.context)
      : _theme = Theme.of(context),
        _nearestOptions = TextfOptions.maybeOf(context); // Find nearest options once

  /// The context in which the resolver operates.
  final BuildContext context;
  // Store theme and options for potential reuse within a single resolve cycle,
  // though looking them up on demand is also fine.
  final ThemeData _theme;
  final TextfOptions? _nearestOptions;

  /// Resolves the final TextStyle for a given token type and base style.
  ///
  /// Use this for standard formatting types like bold, italic, code, strikethrough,
  /// underline, highlight.
  /// For links, use `resolveLinkStyle` and `resolveLinkHoverStyle`.
  ///
  /// - [type]: The type of formatting marker (e.g., `TokenType.boldMarker`).
  /// - [baseStyle]: The style of the text segment *before* applying this format.
  ///
  /// Returns the final `TextStyle` to be applied.
  TextStyle resolveStyle(TokenType type, TextStyle baseStyle) {
    // Get the effective style from TextfOptions hierarchy first.
    // The getEffective... methods handle the lookup and return null if no option is set.
    final TextStyle? optionsStyle = _getEffectiveStyleFromOptions(type, baseStyle);

    if (optionsStyle != null) {
      // Precedence 1 & 2: Use the style derived from TextfOptions
      // The getEffective... methods already merge with the base style correctly.
      return optionsStyle;
    } else {
      // Precedence 3 & 4: No TextfOptions override found, use Theme or Default fallback
      switch (type) {
        case TokenType.boldMarker:
          return DefaultStyles.boldStyle(baseStyle); // Relative default
        case TokenType.italicMarker:
          return DefaultStyles.italicStyle(baseStyle); // Relative default
        case TokenType.boldItalicMarker:
          return DefaultStyles.boldItalicStyle(baseStyle); // Relative default
        case TokenType.strikeMarker:
          // No full style override from options, use default effect.
          // Check if a specific thickness is provided via options.
          final double? thicknessOption =
              _nearestOptions?.getEffectiveStrikethroughThickness(context);
          // Use the option thickness if provided, otherwise use the default thickness.
          final double finalThickness =
              thicknessOption ?? DefaultStyles.defaultStrikethroughThickness;

          // Apply the default strikethrough effect with the resolved thickness.
          return DefaultStyles.strikethroughStyle(
            baseStyle,
            thickness: finalThickness,
          );
        case TokenType.codeMarker:
          return _getThemeBasedCodeStyle(baseStyle); // Theme-based default
        case TokenType.underlineMarker:
          return DefaultStyles.underlineStyle(baseStyle); // Relative default
        case TokenType.highlightMarker:
          return _getThemeBasedHighlightStyle(baseStyle); // Theme-based default
        case TokenType.superscriptMarker:
          return DefaultStyles.superscriptStyle(baseStyle); // Relative default
        case TokenType.subscriptMarker:
          return DefaultStyles.subscriptStyle(baseStyle); // Relative default
        // Link styles are handled separately by resolveLinkStyle/resolveLinkHoverStyle
        case TokenType.linkStart:
        case TokenType.linkText:
        case TokenType.linkSeparator:
        case TokenType.linkUrl:
        case TokenType.linkEnd:
        case TokenType.text:
          return baseStyle; // No formatting applied
      }
    }
  }

  /// Resolves the final NORMAL TextStyle for a URL link.
  ///
  /// Checks TextfOptions first, then falls back to a theme-based style.
  /// Merges the result with the provided `baseStyle`.
  ///
  /// - [baseStyle]: The style of the link text *before* applying link-specific formatting
  ///                (might already include bold, italic etc. if the link is nested).
  ///
  /// Returns the final normal `TextStyle` for the link.
  TextStyle resolveLinkStyle(TextStyle baseStyle) {
    final TextStyle? optionsStyle = _nearestOptions?.getEffectiveUrlStyle(context, baseStyle);

    return optionsStyle ?? _getThemeBasedLinkStyle(baseStyle);
  }

  /// Resolves the final HOVER TextStyle for a URL link.
  ///
  /// Checks TextfOptions first, then falls back to a theme-based style
  /// (which, by default, might be the same as the normal style unless overridden).
  /// Merges the result with the provided `baseStyle`.
  ///
  /// - [baseStyle]: The style of the link text *before* applying link-specific formatting.
  ///
  /// Returns the final hover `TextStyle` for the link.
  TextStyle resolveLinkHoverStyle(TextStyle baseStyle) {
    // 1. Resolve the normal link style first
    final TextStyle normalLinkStyle = resolveLinkStyle(baseStyle);
    // 2. Try to get a hover-specific style from options, merging it onto the normalLinkStyle
    final TextStyle? optionsStyle =
        _nearestOptions?.getEffectiveUrlHoverStyle(context, normalLinkStyle);

    return optionsStyle ?? normalLinkStyle;
  }

  /// Resolves the effective MouseCursor for a URL link.
  ///
  /// Checks TextfOptions first, then falls back to `DefaultStyles.urlMouseCursor`.
  MouseCursor resolveLinkMouseCursor() {
    return _nearestOptions?.getEffectiveUrlMouseCursor(context) ?? DefaultStyles.urlMouseCursor;
  }

  /// Resolves the effective onUrlTap callback for a URL link.
  ///
  /// Checks TextfOptions hierarchy for the callback. Returns null if none found.
  void Function(String url, String displayText)? resolveOnUrlTap() {
    return _nearestOptions?.getEffectiveOnUrlTap(context);
  }

  /// Resolves the effective onUrlHover callback for a URL link.
  ///
  /// Checks TextfOptions hierarchy for the callback. Returns null if none found.
  void Function(String url, String displayText, {required bool isHovering})? resolveOnUrlHover() {
    return _nearestOptions?.getEffectiveOnUrlHover(context);
  }

  // --- Private Helper Methods ---

  /// Internal helper to retrieve the effective style from TextfOptions hierarchy.
  /// Returns null if no option is defined for the given type.
  TextStyle? _getEffectiveStyleFromOptions(TokenType type, TextStyle baseStyle) {
    final TextfOptions? options = _nearestOptions;
    if (options == null) return null;

    // Call the appropriate getter on the TextfOptions instance.
    // These methods handle the ancestor lookup internally.
    switch (type) {
      case TokenType.boldMarker:
        return options.getEffectiveBoldStyle(context, baseStyle);
      case TokenType.italicMarker:
        return options.getEffectiveItalicStyle(context, baseStyle);
      case TokenType.boldItalicMarker:
        return options.getEffectiveBoldItalicStyle(context, baseStyle);
      case TokenType.strikeMarker:
        return options.getEffectiveStrikethroughStyle(context, baseStyle);
      case TokenType.codeMarker:
        return options.getEffectiveCodeStyle(context, baseStyle);
      case TokenType.underlineMarker:
        return options.getEffectiveUnderlineStyle(context, baseStyle);
      case TokenType.highlightMarker:
        return options.getEffectiveHighlightStyle(context, baseStyle);
      case TokenType.superscriptMarker:
        return options.getEffectiveSuperscriptStyle(context, baseStyle);
      case TokenType.subscriptMarker:
        return options.getEffectiveSubscriptStyle(context, baseStyle);
      // Link styles are handled by resolveLinkStyle/resolveLinkHoverStyle directly
      case TokenType.linkStart:
      case TokenType.linkText:
      case TokenType.linkSeparator:
      case TokenType.linkUrl:
      case TokenType.linkEnd:
      case TokenType.text:
        return null; // No specific option style for these types
    }
  }

  /// Internal helper to create the default code style based on the current theme.
  TextStyle _getThemeBasedCodeStyle(TextStyle baseStyle) {
    final ColorScheme colorScheme = _theme.colorScheme;
    // final TextTheme textTheme = _theme.textTheme; // Potentially use textTheme for font details

    final Color codeBackgroundColor = colorScheme.surfaceContainer; // Example theme color
    final Color codeForegroundColor = colorScheme.onSurfaceVariant; // Example theme color

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
    final Color themeLinkColor = _theme.colorScheme.primary; // Use primary color

    // Merge theme link appearance (color, decoration) ON TOP of the base style.
    return baseStyle.merge(
      TextStyle(
        color: themeLinkColor,
        decoration: TextDecoration.underline, // Default underline for links
        decorationColor: themeLinkColor,
      ),
    );
  }

  /// Internal helper to create the default highlight style based on the current theme.
  TextStyle _getThemeBasedHighlightStyle(TextStyle baseStyle) {
    final ColorScheme colorScheme = _theme.colorScheme;

    // A common "highlighter yellow":
    // force yellow for now to see it clearly
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
