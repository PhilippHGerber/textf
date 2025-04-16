import 'package:flutter/material.dart';

import '../core/default_styles.dart';
import '../models/token.dart';
import '../widgets/textf_options.dart'; // Needed for options lookup

/// A class responsible for resolving the final TextStyle for formatted text segments.
///
/// It orchestrates the application of styles based on the following precedence:
/// 1. Explicit styles defined in the nearest ancestor `TextfOptions`.
/// 2. Styles inherited from higher `TextfOptions` ancestors.
/// 3. Theme-based default styles derived from the application's `ThemeData` (for code, links).
/// 4. Relative default styles from `DefaultStyles` (for bold, italic, strikethrough).
///
/// The resolved style is always merged with the provided `baseStyle`.
class TextfStyleResolver {
  final BuildContext context;
  // Store theme and options for potential reuse within a single resolve cycle,
  // though looking them up on demand is also fine.
  final ThemeData _theme;
  final TextfOptions? _nearestOptions;

  /// Creates a style resolver for the given context.
  TextfStyleResolver(this.context)
      : _theme = Theme.of(context),
        _nearestOptions = TextfOptions.maybeOf(context); // Find nearest options once

  /// Resolves the final TextStyle for a given token type and base style.
  ///
  /// Use this for standard formatting types like bold, italic, code, strikethrough.
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
          return DefaultStyles.strikethroughStyle(baseStyle); // Relative default
        case TokenType.codeMarker:
          return _getThemeBasedCodeStyle(baseStyle); // Theme-based default
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

    if (optionsStyle != null) {
      return optionsStyle; // Use style from TextfOptions hierarchy
    } else {
      // Fallback to theme-based default
      return _getThemeBasedLinkStyle(baseStyle);
    }
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
    final TextStyle? optionsStyle = _nearestOptions?.getEffectiveUrlHoverStyle(context, baseStyle);

    if (optionsStyle != null) {
      return optionsStyle; // Use style from TextfOptions hierarchy
    } else {
      // Fallback to theme-based default (which might be same as normal if not themed differently)
      // For simplicity, the default hover style without options is the same as the normal link style.
      // Specific hover effects require TextfOptions.
      return _getThemeBasedLinkStyle(baseStyle);
    }
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
  void Function(String url, String displayText, bool isHovering)? resolveOnUrlHover() {
    return _nearestOptions?.getEffectiveOnUrlHover(context);
  }

  // --- Private Helper Methods ---

  /// Internal helper to retrieve the effective style from TextfOptions hierarchy.
  /// Returns null if no option is defined for the given type.
  TextStyle? _getEffectiveStyleFromOptions(TokenType type, TextStyle baseStyle) {
    if (_nearestOptions == null) return null;

    // Call the appropriate getter on the TextfOptions instance.
    // These methods handle the ancestor lookup internally.
    switch (type) {
      case TokenType.boldMarker:
        return _nearestOptions!.getEffectiveBoldStyle(context, baseStyle);
      case TokenType.italicMarker:
        return _nearestOptions!.getEffectiveItalicStyle(context, baseStyle);
      case TokenType.boldItalicMarker:
        return _nearestOptions!.getEffectiveBoldItalicStyle(context, baseStyle);
      case TokenType.strikeMarker:
        return _nearestOptions!.getEffectiveStrikethroughStyle(context, baseStyle);
      case TokenType.codeMarker:
        return _nearestOptions!.getEffectiveCodeStyle(context, baseStyle);
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
    final List<String> codeFontFamilyFallback =
        DefaultStyles.codeStyle(baseStyle).fontFamilyFallback ?? // Keep original fallbacks
            ['RobotoMono', 'Menlo', 'Courier New'];

    // Merge theme defaults with the base style
    return baseStyle.copyWith(
      fontFamily: codeFontFamily,
      fontFamilyFallback: codeFontFamilyFallback,
      backgroundColor: codeBackgroundColor,
      color: codeForegroundColor, // Override base color for code
      letterSpacing: baseStyle.letterSpacing ?? 0, // Keep or reset letter spacing
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
}

// Helper extension for cleaner null checks (optional)
extension ScopeFunctions<T extends Object> on T {
  R let<R>(R Function(T self) op) => op(this);
}
