import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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
  const new({
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
  ///
  /// Merged onto the ambient [DefaultTextStyle] to form the *effective root
  /// style*, exactly as [Text] does, unless its [TextStyle.inherit] is false.
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

  /// Cached style resolver, rebuilt only when the inherited options change.
  TextfStyleResolver? _cachedResolver;

  // Cached dependencies to detect inherited changes. No design-system theme is
  // read: built-in defaults derive from the effective root style alone.
  TextfOptionsData? _lastOptions;
  TextScaler? _lastMediaQueryScaler;

  /// The effective root style the cached spans were parsed with.
  ///
  /// Combines the ambient [DefaultTextStyle], [TextfRenderer.style] and the
  /// platform bold-text setting, so a change to any of them that alters the
  /// root style — and only such a change — invalidates the cached spans. The
  /// parser derives the internal palette from this same style.
  TextStyle? _lastEffectiveStyle;

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

    final options = TextfOptions.maybeOf(context);
    final mediaQueryScaler = MediaQuery.textScalerOf(context);

    // The cached resolver is current when it exists and was built from equal
    // options (O(1) via TextfOptionsData's overridden == operator).
    final bool resolverCurrent = _cachedResolver != null && _lastOptions == options;

    final bool scalerMatch = _lastMediaQueryScaler == mediaQueryScaler;

    // Covers DefaultTextStyle and MediaQuery.boldTextOf — and with them the
    // palette the built-in colors derive from.
    final bool effectiveStyleChanged = _refreshEffectiveRootStyle();

    // If any inherited inputs to the parser have changed, clear the cache.
    if (!resolverCurrent || !scalerMatch || effectiveStyleChanged) {
      _cachedSpans = null;
      _lastOptions = options;
      _lastMediaQueryScaler = mediaQueryScaler;

      // Rebuild the resolver only when the options change.
      if (!resolverCurrent) {
        _cachedResolver = TextfStyleResolver.withState(options: options);
      }
    }
  }

  @override
  void didUpdateWidget(TextfRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A new style only matters if it changes the effective root style.
    final bool effectiveStyleChanged =
        widget.style != oldWidget.style && _refreshEffectiveRootStyle();

    // Only invalidate spans if parser inputs change.
    // Changing layout properties like maxLines or textAlign will NOT trigger a re-parse!
    if (effectiveStyleChanged ||
        widget.data != oldWidget.data ||
        widget.textScaler != oldWidget.textScaler ||
        !mapEquals(widget.placeholders, oldWidget.placeholders)) {
      _cachedSpans = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always set by didChangeDependencies before the first build; the fallback
    // only satisfies the type system.
    final TextStyle effectiveStyle =
        _lastEffectiveStyle ?? _effectiveRootStyleOf(context, widget.style);
    final effectiveScaler = widget.textScaler ?? MediaQuery.textScalerOf(context);

    // Local variable for type promotion
    List<InlineSpan>? spans = _cachedSpans;

    // Re-parse only if the cache was invalidated
    if (spans == null) {
      spans = widget.parser.parse(
        widget.data,
        context,
        effectiveStyle,
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

  /// Recomputes the effective root style into [_lastEffectiveStyle].
  ///
  /// Returns whether it changed, i.e. whether the cached spans are stale.
  bool _refreshEffectiveRootStyle() {
    final TextStyle effectiveStyle = _effectiveRootStyleOf(context, widget.style);
    if (effectiveStyle == _lastEffectiveStyle) return false;
    _lastEffectiveStyle = effectiveStyle;

    return true;
  }

  /// Computes the *effective root style* the way [Text] computes its
  /// effective text style.
  ///
  /// [style] is merged onto the ambient [DefaultTextStyle] unless its
  /// [TextStyle.inherit] is false, in which case it stands alone. When the
  /// platform asks for bold text ([MediaQuery.boldTextOf]), the result is
  /// bolded. Relative sizes (headings, scripts) and derived colors are then
  /// computed from this one style.
  static TextStyle _effectiveRootStyleOf(BuildContext context, TextStyle? style) {
    final TextStyle ambient = DefaultTextStyle.of(context).style;
    final TextStyle merged = (style == null || style.inherit) ? ambient.merge(style) : style;

    return MediaQuery.boldTextOf(context)
        ? merged.merge(const TextStyle(fontWeight: FontWeight.bold))
        : merged;
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
