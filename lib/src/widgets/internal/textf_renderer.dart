import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../parsing/textf_parser.dart';
import '../textf_options.dart';

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
    this.placeholders,
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

  /// The map of [InlineSpan] objects to insert into placeholders (e.g., {icon}).
  final Map<String, InlineSpan>? placeholders;

  @override
  State<TextfRenderer> createState() => TextfRendererState();
}

/// The state class for [TextfRenderer] that builds the text widget
class TextfRendererState extends State<TextfRenderer> {
  /// Cached list of spans from the last parse.
  List<InlineSpan>? _cachedSpans;

  /// Cache keys to detect if inputs have changed.
  String? _lastData;
  TextStyle? _lastStyle;
  TextScaler? _lastScaler;
  Map<String, InlineSpan>? _lastPlaceholders;
  TextAlign? _lastTextAlign;
  TextDirection? _lastTextDirection;
  bool? _lastSoftWrap;
  TextOverflow? _lastOverflow;
  int? _lastMaxLines;
  TextWidthBasis? _lastTextWidthBasis;
  ThemeData? _lastTheme;
  TextfOptions? _lastOptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = TextfOptions.maybeOf(context);

    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    final TextStyle currentBaseStyle = widget.style ?? defaultTextStyle.style;
    final TextScaler effectiveScaler = widget.textScaler ?? MediaQuery.textScalerOf(context);

    // --- Memoization Check ---
    final List<InlineSpan>? cachedSpans = _cachedSpans;

    // 1. Check placeholders
    final bool placeholdersMatch = mapEquals(_lastPlaceholders, widget.placeholders);

    // 2. Check Options (Fixing Critical Flaw)
    // We check if it is the same instance OR if it logically equals the last one.
    final TextfOptions? lastOptions = _lastOptions;
    final bool optionsMatch = (lastOptions == options) ||
        (lastOptions != null && options != null && options.hasSameStyle(lastOptions));

    // 3. Check Theme
    // Compare only the ColorScheme properties that TextfStyleResolver uses:
    // - primary: link color/decoration
    // - onSurfaceVariant: code text color
    // - surfaceContainer: code background color
    // This avoids unnecessary re-parses when unrelated theme properties change,
    // while still correctly invalidating when theme-derived styles would differ.
    final ThemeData? lastTheme = _lastTheme;
    final bool themeMatch = lastTheme == theme ||
        (lastTheme != null &&
            lastTheme.colorScheme.primary == theme.colorScheme.primary &&
            lastTheme.colorScheme.onSurfaceVariant == theme.colorScheme.onSurfaceVariant &&
            lastTheme.colorScheme.surfaceContainer == theme.colorScheme.surfaceContainer);

    if (cachedSpans != null &&
        placeholdersMatch &&
        optionsMatch &&
        themeMatch &&
        _lastData == widget.data &&
        _lastStyle == currentBaseStyle &&
        _lastScaler == effectiveScaler &&
        _lastTextAlign == widget.textAlign &&
        _lastTextDirection == widget.textDirection &&
        _lastSoftWrap == widget.softWrap &&
        _lastOverflow == widget.overflow &&
        _lastMaxLines == widget.maxLines &&
        _lastTextWidthBasis == widget.textWidthBasis) {
      // Cache Hit!
      return DefaultTextStyle.merge(
        textAlign: widget.textAlign,
        softWrap: widget.softWrap,
        overflow: widget.overflow,
        maxLines: widget.maxLines,
        textWidthBasis: widget.textWidthBasis,
        child: _buildRichText(cachedSpans, effectiveScaler),
      );
    }

    // --- Cache Miss: Re-parse ---
    final List<InlineSpan> spans = widget.parser.parse(
      widget.data,
      context,
      currentBaseStyle,
      textScaler: effectiveScaler,
      placeholders: widget.placeholders,
    );

    final Widget result = _buildRichText(spans, effectiveScaler);

    // Update Cache
    _cachedSpans = spans;
    _lastData = widget.data;
    _lastStyle = currentBaseStyle;
    _lastScaler = effectiveScaler;
    _lastPlaceholders = widget.placeholders;
    _lastTheme = theme;
    _lastOptions = options;
    _lastTextAlign = widget.textAlign;
    _lastTextDirection = widget.textDirection;
    _lastSoftWrap = widget.softWrap;
    _lastOverflow = widget.overflow;
    _lastMaxLines = widget.maxLines;
    _lastTextWidthBasis = widget.textWidthBasis;

    return DefaultTextStyle.merge(
      textAlign: widget.textAlign,
      softWrap: widget.softWrap,
      overflow: widget.overflow,
      maxLines: widget.maxLines,
      textWidthBasis: widget.textWidthBasis,
      child: result,
    );
  }

  /// Helper to build the actual Text.rich widget.
  Widget _buildRichText(List<InlineSpan> spans, TextScaler effectiveScaler) {
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
      textScaler: effectiveScaler,
      maxLines: widget.maxLines,
      semanticsLabel: widget.semanticsLabel,
      textWidthBasis: widget.textWidthBasis,
      textHeightBehavior: widget.textHeightBehavior,
      selectionColor: widget.selectionColor,
    );
  }
}
