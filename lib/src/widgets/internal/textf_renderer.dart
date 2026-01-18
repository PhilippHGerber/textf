import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/material.dart';

import '../../parsing/textf_parser.dart';

/// Internal StatefulWidget that handles parsing, styling resolution via the parser,
/// and hot reload notification. It bridges the Textf widget parameters with
/// the parsing and rendering logic provided by the TextfParser.
class TextfRenderer extends StatefulWidget {
  /// Creates a new TextfRenderer widget.
  const TextfRenderer({
    required this.data,
    required this.style,
    required this.parser,
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
    required this.inlineSpans,
    super.key,
  });

  /// The text data containing potential formatting markers.
  final String data;

  /// The explicit base text style provided to the Textf widget.
  /// If null, DefaultTextStyle will be used.
  final TextStyle? style;

  /// The parser instance responsible for converting the data string
  /// into a list of InlineSpans, using its internal style resolver.
  final TextfParser parser;

  /// {@macro flutter.widgets.basic.strutStyle}
  final StrutStyle? strutStyle;

  /// {@macro flutter.widgets.basic.textAlign}
  final TextAlign? textAlign;

  /// {@macro flutter.widgets.basic.textDirection}
  final TextDirection? textDirection;

  /// {@macro flutter.widgets.basic.locale}
  final Locale? locale;

  /// {@macro flutter.widgets.basic.softWrap}
  final bool? softWrap;

  /// {@macro flutter.widgets.basic.overflow}
  final TextOverflow? overflow;

  /// {@macro flutter.widgets.basic.textScaler}
  final TextScaler? textScaler;

  /// {@macro flutter.widgets.basic.maxLines}
  final int? maxLines;

  /// {@macro flutter.widgets.basic.semanticsLabel}
  final String? semanticsLabel;

  /// {@macro flutter.widgets.basic.textWidthBasis}
  final TextWidthBasis? textWidthBasis;

  /// {@macro flutter.widgets.basic.textHeightBehavior}
  final ui.TextHeightBehavior? textHeightBehavior;

  /// {@macro flutter.widgets.basic.selectionColor}
  final Color? selectionColor;

  /// The inline spans to replace the placeholders (##1, ##2, etc.)
  final List<InlineSpan>? inlineSpans;

  @override
  State<TextfRenderer> createState() => TextfRendererState();
}

/// The state class for [TextfRenderer] that builds the text widget
class TextfRendererState extends State<TextfRenderer> {
  @override
  Widget build(BuildContext context) {
    // Determine the effective base text style for parsing.
    // It considers the widget's explicit style and the ambient DefaultTextStyle.
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    final TextStyle currentBaseStyle = widget.style ?? defaultTextStyle.style;
    final TextScaler effectiveScaler = widget.textScaler ?? MediaQuery.textScalerOf(context);

    // Invoke the parser. The parser instance (widget.parser) is expected
    // to handle the creation and usage of TextfStyleResolver internally
    // using the provided context.
    final List<InlineSpan> spans = widget.parser.parse(
      widget.data,
      context, // Pass the current BuildContext, needed by the style resolver within the parser.
      currentBaseStyle,
      textScaler: effectiveScaler,
      inlineSpans: widget.inlineSpans,
    );

    // Render the parsed spans using Text.rich.
    // Pass all the standard Text properties through.
    return Text.rich(
      TextSpan(
        // The root TextSpan's style is taken from the explicit widget style.
        // If widget.style is null, Text.rich implicitly uses DefaultTextStyle.
        // The `currentBaseStyle` was used by the parser for *calculating* child styles.
        style: widget.style,
        children: spans,
      ),
      strutStyle: widget.strutStyle,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      locale: widget.locale,
      softWrap: widget.softWrap,
      overflow: widget.overflow,
      textScaler: effectiveScaler,
      maxLines: widget.maxLines,
      semanticsLabel: widget.semanticsLabel,
      textWidthBasis: widget.textWidthBasis,
      textHeightBehavior: widget.textHeightBehavior,
      selectionColor: widget.selectionColor,
    );
  }
}
