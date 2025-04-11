import 'package:flutter/material.dart';

/// Provides default styling for different formatting types.
///
/// This class centralizes all default styling configurations for
/// the Textf widget, ensuring consistent formatting and reducing
/// dependencies between components.
class DefaultStyles {
  /// Defaul
  static const MaterialColor _blue = Colors.blue;
  static Color urlColor = _blue.shade500;
  static Color urlHoverColor = _blue.shade700;

  /// Default styling for URLs in normal state.
  static final TextStyle urlStyle = TextStyle(
    color: urlColor,
    decoration: TextDecoration.underline,
    decorationColor: urlColor,
  );

  /// Default styling for URLs in hover state.
  static final TextStyle urlHoverStyle = TextStyle(
    color: urlHoverColor,
    decoration: TextDecoration.underline,
    decorationColor: urlHoverColor,
  );

  /// Default mouse cursor for URLs.
  static const MouseCursor urlMouseCursor = SystemMouseCursors.click;

  /// Default styling for bold formatted text.
  static TextStyle boldStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(fontWeight: FontWeight.bold);
  }

  /// Default styling for italic formatted text.
  static TextStyle italicStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(fontStyle: FontStyle.italic);
  }

  /// Default styling for bold and italic formatted text.
  static TextStyle boldItalicStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      fontStyle: FontStyle.italic,
    );
  }

  /// Default styling for strikethrough text.
  static TextStyle strikethroughStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      decoration: TextDecoration.lineThrough,
      decorationColor: baseStyle.color,
      decorationThickness: 2,
    );
  }

  /// Default styling for inline code text.
  static TextStyle codeStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: ['RobotoMono', 'Menlo', 'Courier New'],
      backgroundColor: const Color(0xFFF5F5F5),
      letterSpacing: 0,
    );
  }
}
