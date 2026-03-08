import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/textf_token_cache.dart';
import '../../parsing/textf_parser.dart';
import '../../styling/textf_style_resolver.dart';
import '../textf_options.dart';
import '../textf_options_data.dart';

/// Internal StatefulWidget that handles parsing, styling resolution via the parser,
/// and cache invalidation. It bridges the Textf widget parameters with
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

/// The state class for [TextfRenderer] that builds the text widget and manages caching.
///
/// Implements [WidgetsBindingObserver] to automatically clear the shared token
/// cache on memory pressure, preventing the need for manual 'Textf.clearCache' calls.
class TextfRendererState extends State<TextfRenderer> with WidgetsBindingObserver {
  /// Cached list of spans from the last parse.
  List<InlineSpan>? _cachedSpans;

  /// Cached style resolver to avoid redundant Theme.of / TextfOptions.maybeOf lookups.
  TextfStyleResolver? _cachedResolver;

  // Cached dependencies to detect inherited changes
  ThemeData? _lastTheme;
  TextfOptionsData? _lastOptions;
  DefaultTextStyle? _lastDefaultTextStyle;
  TextScaler? _lastMediaQueryScaler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    TextfTokenCache.clearCache();
    _cachedSpans = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final theme = Theme.of(context);
    final options = TextfOptions.maybeOf(context);
    final defaultTextStyle = DefaultTextStyle.of(context);
    final mediaQueryScaler = MediaQuery.textScalerOf(context);

    // Smart Theme comparison: only invalidate if properties affecting parsing change.
    final lastTheme = _lastTheme;
    final bool themeMatch = lastTheme != null &&
        lastTheme.colorScheme.primary == theme.colorScheme.primary &&
        lastTheme.colorScheme.onSurfaceVariant == theme.colorScheme.onSurfaceVariant &&
        lastTheme.colorScheme.surfaceContainer == theme.colorScheme.surfaceContainer &&
        lastTheme.colorScheme.brightness == theme.colorScheme.brightness;

    // O(1) equality check via TextfOptionsData's overridden == operator.
    final bool optionsMatch = _lastOptions == options;

    // DefaultTextStyle affects our baseStyle fallback.
    final lastDefaultStyle = _lastDefaultTextStyle;
    final bool defaultStyleMatch = lastDefaultStyle?.style == defaultTextStyle.style;

    final bool scalerMatch = _lastMediaQueryScaler == mediaQueryScaler;

    // If any inherited inputs to the parser have changed, clear the cache.
    if (!themeMatch || !optionsMatch || !defaultStyleMatch || !scalerMatch) {
      _cachedSpans = null;
      _lastTheme = theme;
      _lastOptions = options;
      _lastDefaultTextStyle = defaultTextStyle;
      _lastMediaQueryScaler = mediaQueryScaler;

      // Rebuild the resolver only when theme or options change.
      if (!themeMatch || !optionsMatch) {
        _cachedResolver = TextfStyleResolver.withState(theme: theme, options: options);
      }
    }
  }

  @override
  void didUpdateWidget(TextfRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only invalidate spans if parser inputs change.
    // Changing layout properties like maxLines or textAlign will NOT trigger a re-parse!
    if (widget.data != oldWidget.data ||
        widget.style != oldWidget.style ||
        widget.textScaler != oldWidget.textScaler ||
        !mapEquals(widget.placeholders, oldWidget.placeholders)) {
      _cachedSpans = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read directly from context or widget to guarantee non-null without '!'
    final currentBaseStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final effectiveScaler = widget.textScaler ?? MediaQuery.textScalerOf(context);

    // Local variable for type promotion
    List<InlineSpan>? spans = _cachedSpans;

    // Re-parse only if the cache was invalidated
    if (spans == null) {
      spans = widget.parser.parse(
        widget.data,
        context,
        currentBaseStyle,
        textScaler: effectiveScaler,
        placeholders: widget.placeholders,
        styleResolver: _cachedResolver,
      );
      _cachedSpans = spans;
    }

    // Build the underlying rich text widget
    final Widget result = _buildRichText(spans, effectiveScaler);

    // Apply DefaultTextStyle merging for layout properties
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
