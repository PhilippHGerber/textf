import 'package:flutter/material.dart';

import '../../core/default_styles.dart';
import '../../models/token.dart';
import '../../widgets/textf_options.dart';

/// Utility class for applying text styles based on formatting markers.
///
/// This class provides static methods to determine the appropriate
/// text style for different formatting markers, taking into account
/// custom styles provided via TextfOptions.
class StyleApplicator {
  /// Applies the appropriate style for a formatting marker.
  ///
  /// This method takes a base style and a marker type and returns
  /// a new style with the appropriate formatting applied. It uses
  /// TextfOptions if available, otherwise falls back to default styles.
  ///
  /// @param context The BuildContext
  /// @param style The base text style to modify
  /// @param markerType The type of formatting to apply
  /// @param options Optional TextfOptions for custom styling
  /// @return A new TextStyle with the appropriate formatting applied
  static TextStyle applyStyle(
    BuildContext context,
    TextStyle style,
    TokenType markerType,
    TextfOptions? options,
  ) {
    switch (markerType) {
      case TokenType.boldMarker:
        return options?.getEffectiveBoldStyle(context, style) ?? DefaultStyles.boldStyle(style);

      case TokenType.italicMarker:
        return options?.getEffectiveItalicStyle(context, style) ?? DefaultStyles.italicStyle(style);

      case TokenType.boldItalicMarker:
        return options?.getEffectiveBoldItalicStyle(context, style) ?? DefaultStyles.boldItalicStyle(style);

      case TokenType.strikeMarker:
        return options?.getEffectiveStrikethroughStyle(context, style) ?? DefaultStyles.strikethroughStyle(style);

      case TokenType.codeMarker:
        return options?.getEffectiveCodeStyle(context, style) ?? DefaultStyles.codeStyle(style);

      case TokenType.linkStart: // Should not reach here directly
        return options?.getEffectiveUrlStyle(context, style) ?? DefaultStyles.urlStyle.merge(style);

      case TokenType.text:
      case TokenType.linkText:
      case TokenType.linkSeparator:
      case TokenType.linkUrl:
      case TokenType.linkEnd:
        // These token types don't affect styling directly
        return style;
    }
  }
}
