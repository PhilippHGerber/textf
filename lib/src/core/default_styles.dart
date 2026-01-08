import 'package:flutter/material.dart';

/// Provides default styling behaviours used as fallbacks by TextfStyleResolver.
///
/// This class centralizes fallback styling configurations when neither
/// TextfOptions nor the application Theme provide specific guidance for a
/// particular formatting type.
class DefaultStyles {
  /// Default mouse cursor for URLs.
  /// Used as a fallback by TextfStyleResolver when no cursor is specified
  /// via TextfOptions in the widget tree.
  static const MouseCursor urlMouseCursor = SystemMouseCursors.click;

  /// Default alpha values for highlight background color.
  static const highlightAlphaDark = 0.4;

  /// Default alpha values for highlight background color.
  static const highlightAlphaLight = 0.5;

  /// Default font family fallback list for inline code (`code`).
  /// Used by TextfStyleResolver when applying theme-based code styling
  /// if no specific `codeStyle` (with font information) is provided via TextfOptions.
  /// Includes 'monospace' as a final generic fallback.
  static const List<String> defaultCodeFontFamilyFallback = [
    'RobotoMono', // Commonly included via assets in Flutter projects using this package
    'Menlo', // Common monospace font on macOS
    'Courier New', // Common monospace font on Windows
    'monospace', // Generic CSS/platform fallback
  ];

  /// Default thickness for the strikethrough line decoration (`~~strikethrough~~`).
  /// Used by TextfStyleResolver when applying the default strikethrough effect
  /// if no specific `strikethroughThickness` is provided via TextfOptions.
  static const double defaultStrikethroughThickness = 1.5;

  /// Default font size used for relative calculations when base style has no font size.
  static const double defaultFontSize = 14;

  /// Default font size factor for superscript and subscript.
  static const double scriptFontSizeFactor = 0.6;

  /// Default baseline offset factor for superscript (relative to font size).
  static const double superscriptBaselineFactor = -0.4; // Move up

  /// Default baseline offset factor for subscript (relative to font size).
  static const double subscriptBaselineFactor = 0.4; // Move down

  /// Applies default bold formatting (`**bold**` or `__bold__`) to a base style.
  /// Used as a fallback by TextfStyleResolver if no `boldStyle` is found via TextfOptions.
  static TextStyle boldStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(fontWeight: FontWeight.bold);
  }

  /// Applies default italic formatting (`*italic*` or `_italic_`) to a base style.
  /// Used as a fallback by TextfStyleResolver if no `italicStyle` is found via TextfOptions.
  static TextStyle italicStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(fontStyle: FontStyle.italic);
  }

  /// Applies default bold and italic formatting (`***both***` or `___both___`) to a base style.
  /// Used as a fallback by TextfStyleResolver if no `boldItalicStyle` is found via TextfOptions.
  static TextStyle boldItalicStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      fontStyle: FontStyle.italic,
    );
  }

  /// Applies default strikethrough formatting (`~~strikethrough~~`) to a base style,
  /// using the specified line thickness.
  /// Used as a fallback by TextfStyleResolver if no `strikethroughStyle` is found
  /// via TextfOptions. The thickness resolved by the resolver (considering TextfOptions
  /// or the default) is passed in here.
  static TextStyle strikethroughStyle(
    TextStyle baseStyle, {
    double thickness = defaultStrikethroughThickness,
  }) {
    TextDecoration newDecoration = TextDecoration.lineThrough;
    // Combine with existing decoration if present
    if (baseStyle.decoration != null) {
      // Prevent combining with itself if somehow applied twice (defensive)
      final decoration = baseStyle.decoration;
      if (decoration != null && decoration.contains(TextDecoration.lineThrough)) {
        newDecoration = decoration;
      } else if (decoration != null) {
        newDecoration = TextDecoration.combine([decoration, TextDecoration.lineThrough]);
      }
    }

    // Use the base color for the line if available, otherwise let Flutter decide.
    // If combining decorations, the original decorationColor might be for a different part.
    // It's safer to let Flutter pick or for the user to specify a combined decorationColor
    // via TextfOptions.
    // For simplicity here, we might just use baseStyle.color if no decorationColor is set.
    final Color? decorationColorToApply = baseStyle.decorationColor ?? baseStyle.color;

    return baseStyle.copyWith(
      decoration: newDecoration,
      decorationColor: decorationColorToApply,
      decorationThickness: thickness,
    );
  }

  /// Applies default underline formatting (`++underline++`) to a base style.
  /// Used as a fallback by TextfStyleResolver if no `underlineStyle` is found via TextfOptions.
  static TextStyle underlineStyle(TextStyle baseStyle) {
    TextDecoration newDecoration = TextDecoration.underline;
    // Combine with existing decoration if present
    final TextDecoration? decoration = baseStyle.decoration;
    if (decoration != null) {
      // Prevent combining with itself (defensive)
      newDecoration = decoration.contains(TextDecoration.underline)
          ? decoration
          : TextDecoration.combine([decoration, TextDecoration.underline]);
    }

    final Color? decorationColorToApply = baseStyle.decorationColor ?? baseStyle.color;

    return baseStyle.copyWith(
      decoration: newDecoration,
      decorationColor: decorationColorToApply,
      // Use baseStyle.decorationThickness if available, otherwise a sensible default or null.
      // This thickness applies to the new underline part.
      decorationThickness: baseStyle.decorationThickness ?? 1.0,
    );
  }

  /// Applies a simple default highlight formatting (`==highlight==`) to a base style.
  /// This is a very basic fallback. A theme-aware highlight style is generally preferred
  /// and would be implemented in `TextfStyleResolver`.
  /// Used as a fallback by TextfStyleResolver if no `highlightStyle` is found via TextfOptions
  /// AND no theme-based default is implemented or chosen in the resolver.
  static TextStyle highlightStyle(TextStyle baseStyle) {
    // A common, though not necessarily theme-adaptive, highlight color.
    // Brightness check could make it slightly more adaptive if used as a true last resort.
    final baseStyleColor = baseStyle.color;
    final bool isDark = baseStyleColor != null &&
        ThemeData.estimateBrightnessForColor(baseStyleColor) == Brightness.dark;

    return baseStyle.copyWith(
      backgroundColor: isDark
          ? Colors.yellow.withValues(alpha: highlightAlphaDark)
          : Colors.yellow.withValues(alpha: highlightAlphaLight),
      // Retain the original text color unless a specific contrast logic is needed.
      // color: baseStyle.color, // Text color usually remains the same for highlight
    );
  }

  /// Applies default superscript formatting (`^superscript^`) to a base style.
  static TextStyle superscriptStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? defaultFontSize) * scriptFontSizeFactor,
    );
  }

  /// Applies default subscript formatting (`~subscript~`) to a base style.
  static TextStyle subscriptStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? defaultFontSize) * scriptFontSizeFactor,
    );
  }
}
