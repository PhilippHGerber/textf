// lib/src/widgets/internal/_textf_renderer.dart
import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/material.dart';

import '../../parsing/parser.dart';

/// Internal StatefulWidget that handles parsing and hot reload.
class TextfRenderer extends StatefulWidget {
  // Nimm alle Parameter von Textf entgegen
  const TextfRenderer({
    super.key,
    // key wird automatisch behandelt
    required this.data,
    required this.style,
    required this.parser, // Benötigt den Parser
    required this.strutStyle,
    required this.textAlign,
    required this.textDirection,
    required this.locale,
    required this.softWrap,
    required this.overflow,
    required this.textScaler,
    required this.maxLines,
    required this.semanticsLabel,
    required this.textWidthBasis,
    required this.textHeightBehavior,
    required this.selectionColor,
  });

  /// The text to display with formatting
  final String data;

  /// The base text style to apply to the text
  final TextStyle? style;

  /// The parser to use for formatting the text
  final TextfParser parser;

  /// The strut style to use for vertical layout
  final StrutStyle? strutStyle;

  /// How the text should be aligned horizontally
  final TextAlign? textAlign;

  /// The directionality of the text
  final TextDirection? textDirection;

  /// The locale to use for the text
  final Locale? locale;

  /// Whether the text should break at soft line breaks
  final bool? softWrap;

  /// How visual overflow should be handled
  final TextOverflow? overflow;

  /// The text scaling factor to apply
  final TextScaler? textScaler;

  /// The maximum number of lines for the text to span
  final int? maxLines;

  /// An alternative semantics label for the text
  final String? semanticsLabel;

  /// Defines how the paragraph width is determined
  final TextWidthBasis? textWidthBasis;

  /// Defines how the paragraph will position lines vertically
  final ui.TextHeightBehavior? textHeightBehavior;

  /// The color to use when painting the selection
  final Color? selectionColor;

  @override
  State<TextfRenderer> createState() => TextfRendererState();
}

class TextfRendererState extends State<TextfRenderer> {
  @override
  void reassemble() {
    super.reassemble();
    // Invalidate future cache keys.
    TextfParser.onHotReload();
  }

  @override
  Widget build(BuildContext context) {
    // Determine the base text style to use for parsing.
    // This respects the DefaultTextStyle potentially higher up the tree.
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    final TextStyle currentBaseStyle = widget.style ?? defaultTextStyle.style;

    final List<InlineSpan> spans = widget.parser.parse(
      widget.data,
      context, // Pass the current, up-to-date BuildContext
      currentBaseStyle,
    );

    // Build the Text.rich widget using the result of the parse.
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: spans,
      ),
      strutStyle: widget.strutStyle,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      locale: widget.locale,
      softWrap: widget.softWrap,
      overflow: widget.overflow,
      textScaler: widget.textScaler,
      maxLines: widget.maxLines,
      semanticsLabel: widget.semanticsLabel,
      textWidthBasis: widget.textWidthBasis,
      textHeightBehavior: widget.textHeightBehavior,
      selectionColor: widget.selectionColor,
    );
  }
}
