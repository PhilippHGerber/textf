import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/widgets.dart';

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
