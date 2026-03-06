import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/widgets.dart';

import '../core/formatting_utils.dart';
import 'textf.dart';

/// Convenience extension on [String] for creating [Textf] widgets inline.
///
/// ```dart
/// 'Hello **bold** *italic*'.textf(style: TextStyle(fontSize: 16))
/// ```
extension TextfExt on String {
  /// Renders the string as a [Textf] widget.
  ///
  /// All parameters are forwarded directly to the [Textf] constructor.
  Textf textf({
    Key? key,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    TextOverflow? overflow,
    TextScaler? textScaler,
    int? maxLines,
    String? semanticsLabel,
    TextWidthBasis? textWidthBasis,
    ui.TextHeightBehavior? textHeightBehavior,
    Color? selectionColor,
    Map<String, InlineSpan>? placeholders,
  }) =>
      Textf(
        this,
        key: key,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
        placeholders: placeholders,
      );
}

/// Convenience extension on [String] for extracting plain text.
extension TextfStringExt on String {
  /// Strips all valid textf formatting markers from the string, returning plain text.
  ///
  /// For example:
  /// `'**bold** and[link](url)'.stripFormatting()` returns `'bold and link'`.
  ///
  /// Unpaired markers (e.g., `2 * 3`) and widget placeholders (e.g., `{icon}`)
  /// are left untouched. Escaped characters lose their backslash but remain visible.
  String stripFormatting() => FormattingUtils.stripFormatting(this);
}
