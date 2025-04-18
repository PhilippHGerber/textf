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

  /// Applies default bold formatting (`**bold**` or `__bold__`) to a base style.
  /// Used as a fallback by TextfStyleResolver if no `boldStyle` is found via TextfOptions.
  static TextStyle boldStyle(final TextStyle baseStyle) {
    return baseStyle.copyWith(fontWeight: FontWeight.bold);
  }

  /// Applies default italic formatting (`*italic*` or `_italic_`) to a base style.
  /// Used as a fallback by TextfStyleResolver if no `italicStyle` is found via TextfOptions.
  static TextStyle italicStyle(final TextStyle baseStyle) {
    return baseStyle.copyWith(fontStyle: FontStyle.italic);
  }

  /// Applies default bold and italic formatting (`***both***` or `___both___`) to a base style.
  /// Used as a fallback by TextfStyleResolver if no `boldItalicStyle` is found via TextfOptions.
  static TextStyle boldItalicStyle(final TextStyle baseStyle) {
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
    final TextStyle baseStyle, {
    // Default value here is mainly for direct calls, resolver provides the actual value.
    final double thickness = defaultStrikethroughThickness,
  }) {
    // Use the base color for the line, if available and appropriate.
    return baseStyle.copyWith(
      decoration: TextDecoration.lineThrough,
      // Only apply decorationColor if baseStyle has a color, otherwise let it be default
      decorationColor: baseStyle.color,
      decorationThickness: thickness, // Use the resolved thickness
    );
  }
}
