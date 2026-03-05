// Override of buildTextSpan must match Flutter's parameter order.
// ignore_for_file: always_put_required_named_parameters_first

import 'package:flutter/material.dart';

import '../core/textf_limits.dart';
import '../styling/textf_style_resolver.dart';
import '../widgets/textf_options.dart';
import 'marker_visibility.dart';
import 'textf_span_builder.dart';

/// A [TextEditingController] that renders textf-formatted text in text fields.
///
/// Use this controller with any [TextField] or [TextFormField] to display
/// live-formatted text while the user types. The user edits plain text with
/// formatting markers, and the controller renders them with applied styles.
///
/// ## Supported formatting
///
/// All standard textf formatting types are supported:
/// * `**bold**` or `__bold__`
/// * `*italic*` or `_italic_`
/// * `***bold and italic***` or `___bold and italic___`
/// * `~~strikethrough~~`
/// * `++underline++`
/// * `==highlight==`
/// * `` `code` ``
/// * `^superscript^` (vertical offset in preview mode; font size only when editing)
/// * `~subscript~` (vertical offset in preview mode; font size only when editing)
/// * `[link text](url)` (all characters visible, styled)
///
/// ## Usage
///
/// ```dart
/// final controller = TextfEditingController();
///
/// TextField(controller: controller);
/// ```
///
/// With `TextfOptions` for custom styles:
///
/// ```dart
/// TextfOptions(
///   boldStyle: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
///   child: TextField(controller: TextfEditingController()),
/// )
/// ```
///
/// ## Marker Visibility
///
/// By default, all formatting markers are visible with a dimmed style. Set
/// [markerVisibility] to [MarkerVisibility.whenActive] to hide markers
/// instantly when the cursor leaves a formatted span.
///
/// When text is selected (non-collapsed selection) in [MarkerVisibility.whenActive]
/// mode, all markers are hidden. This prevents layout jumps on mobile where
/// marker visibility toggling during drag selection would shift selection handles.
///
/// ## How it works
///
/// All characters — including formatting markers — remain visible in the
/// text field. Markers (e.g., `**`, `~~`) are rendered with a dimmed style,
/// while the content between them gets the resolved formatting. This ensures
/// cursor positions map 1:1 to the raw text.
///
/// ## Limitations
///
/// - Widget placeholders (`{key}`) render as literal text (no substitution).
/// - Super/subscript text gets proper vertical offset in preview mode (cursor
///   outside, markers fully hidden). During editing or animation, it falls back
///   to a smaller font size on the baseline.
/// - Links show their full `[text](url)` syntax with styling applied.
class TextfEditingController extends TextEditingController {
  /// Creates a [TextfEditingController] with optional initial text.
  TextfEditingController({
    super.text,
    MarkerVisibility markerVisibility = MarkerVisibility.always,
    int maxLiveFormattingLength = TextfLimits.maxLiveFormattingLength,
  })  : _markerVisibility = markerVisibility,
        _maxLiveFormattingLength = maxLiveFormattingLength;

  /// Creates a [TextfEditingController] from a [TextEditingValue].
  TextfEditingController.fromValue(
    super.value, {
    MarkerVisibility markerVisibility = MarkerVisibility.always,
    int maxLiveFormattingLength = TextfLimits.maxLiveFormattingLength,
  })  : _markerVisibility = markerVisibility,
        _maxLiveFormattingLength = maxLiveFormattingLength,
        super.fromValue();

  static final TextfSpanBuilder _spanBuilder = TextfSpanBuilder();

  // --- Caching State ---
  // We heavily cache the expensive lists of InlineSpans to prevent Garbage Collection
  // jank caused by massive string allocations during cursor blink.
  // CRITICAL: We strictly DO NOT cache the final root TextSpan object. Returning the exact
  // same root TextSpan instance breaks Flutter's EditableText inline widget diffing
  // and causes memory leaks. We must always return a `new TextSpan(...)`.
  List<InlineSpan>? _cachedParsedSpans;
  List<InlineSpan>? _cachedFinalChildren;
  String? _lastText;
  int? _lastCursorPos;
  MarkerVisibility? _lastVisibility;
  TextStyle? _lastStyle;
  ThemeData? _lastTheme;
  TextfOptions? _lastNearestOptions;
  TextRange? _lastComposing;
  bool? _lastWithComposing;
  TextfStyleResolver? _cachedResolver;

  bool _isSameTheme(ThemeData? a, ThemeData? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a.colorScheme.primary == b.colorScheme.primary &&
        a.colorScheme.onSurfaceVariant == b.colorScheme.onSurfaceVariant &&
        a.colorScheme.surfaceContainer == b.colorScheme.surfaceContainer &&
        a.colorScheme.brightness == b.colorScheme.brightness;
  }

  /// Controls how formatting markers are displayed.
  ///
  /// When set to[MarkerVisibility.always], all markers are visible with
  /// dimmed styling (default). When set to[MarkerVisibility.whenActive],
  /// only markers surrounding the cursor are visible; others are instantly
  /// hidden. During text selection, all markers are hidden to prevent
  /// layout jumps.
  ///
  /// Setting this property calls[notifyListeners] automatically.
  MarkerVisibility get markerVisibility => _markerVisibility;
  MarkerVisibility _markerVisibility;

  set markerVisibility(MarkerVisibility value) {
    if (_markerVisibility == value) return;
    _markerVisibility = value;
    notifyListeners();
  }

  /// Maximum text length for live formatting.
  ///
  /// When [text] exceeds this length, [buildTextSpan] returns a plain
  /// [TextSpan] with no formatting applied. This prevents UI freezes on
  /// very large inputs. Defaults to [TextfLimits.maxLiveFormattingLength].
  ///
  /// Setting this property calls[notifyListeners] automatically.
  int get maxLiveFormattingLength => _maxLiveFormattingLength;
  int _maxLiveFormattingLength;

  set maxLiveFormattingLength(int value) {
    if (_maxLiveFormattingLength == value) return;
    _maxLiveFormattingLength = value;
    notifyListeners();
  }

  /// Forces a rebuild of the text spans without changing state.
  ///
  /// The [markerVisibility] setter already calls [notifyListeners]
  /// automatically. Use this only when you need a rebuild triggered by
  /// external state not tracked by this controller.
  void invalidate() {
    _cachedParsedSpans = null;
    _cachedFinalChildren = null;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // START TIMER
    // final stopwatch = Stopwatch()..start();

    // 1. Fast path: Empty Text
    // Mimics native TextEditingController, bypassing all custom logic.
    // This drops high UI/Raster time down to baseline when the field is empty.
    if (text.isEmpty) {
      return TextSpan(style: style, text: text);
    }

    // 2. Resolve cursor position for smart-hide mode (O(1)).
    final int? cursorPos;
    if (_markerVisibility == MarkerVisibility.whenActive) {
      final sel = value.selection;
      cursorPos =
          sel.isValid && sel.isCollapsed ? sel.extentOffset : TextfSpanBuilder.hideAllMarkers;
    } else {
      cursorPos = null;
    }

    // 3. Extract inputs for cache matching (O(1)).
    final ThemeData theme = Theme.of(context);
    final TextfOptions? nearestOptions = TextfOptions.maybeOf(context);

    final bool themeMatch = _isSameTheme(_lastTheme, theme);
    // InheritedWidgets are immutable. O(1) identity check completely removes
    // the expensive O(Depth) tree-walk on every frame.
    final bool optionsMatch = _lastNearestOptions == nearestOptions;

    final bool coreCacheHit = _cachedParsedSpans != null &&
        _lastText == text &&
        _lastCursorPos == cursorPos &&
        _lastVisibility == _markerVisibility &&
        _lastStyle == style &&
        themeMatch &&
        optionsMatch;

    // 4. FULL CACHE HIT (Core Spans + Composing Region)
    // If nothing changed, we reuse the fully composed children list.
    // We MUST return a `new TextSpan` to safely satisfy EditableText's update
    // contract without leaking WidgetSpans, but skipping the list allocations
    // eliminates the Garbage Collection stutter.
    if (coreCacheHit &&
        _cachedFinalChildren != null &&
        _lastComposing == value.composing &&
        _lastWithComposing == withComposing) {
      return TextSpan(style: style, children: _cachedFinalChildren);
    }

    // 5. CACHE MISS (Core Spans)
    List<InlineSpan> fullSpans;
    if (coreCacheHit) {
      fullSpans = _cachedParsedSpans!;
    } else {
      if (text.length > _maxLiveFormattingLength) {
        fullSpans = <InlineSpan>[TextSpan(text: text)];
      } else {
        if (_cachedResolver == null || !themeMatch || !optionsMatch) {
          _cachedResolver = TextfStyleResolver(context);
        }

        fullSpans = _spanBuilder.build(
          text,
          context,
          style ?? const TextStyle(),
          cursorPosition: cursorPos,
          styleResolver: _cachedResolver,
        );
      }

      _cachedParsedSpans = fullSpans;
      _lastText = text;
      _lastCursorPos = cursorPos;
      _lastVisibility = _markerVisibility;
      _lastStyle = style;
      _lastTheme = theme;
      _lastNearestOptions = nearestOptions;
    }

    // 6. APPLY COMPOSING REGION
    final List<InlineSpan> finalChildren;

    if (!withComposing || !value.composing.isValid || value.composing.isCollapsed) {
      // No active composing region, just use the raw parsed spans.
      finalChildren = fullSpans;
    } else {
      // Inject IME underline into the spans
      final TextRange composing = value.composing;
      finalChildren = <InlineSpan>[];
      const TextStyle composingStyle = TextStyle(decoration: TextDecoration.underline);

      int currentOffset = 0;

      for (int i = 0; i < fullSpans.length; i++) {
        final InlineSpan span = fullSpans[i];
        final int spanLength = span is TextSpan ? (span.text?.length ?? 0) : 1;
        final int spanStart = currentOffset;
        final int spanEnd = currentOffset + spanLength;

        if (spanEnd <= composing.start || spanStart >= composing.end) {
          finalChildren.add(span);
        } else if (span is TextSpan && span.text != null && span.text!.isNotEmpty) {
          final String rawText = span.text!;
          final int startInSpan = (composing.start > spanStart) ? composing.start - spanStart : 0;
          final int endInSpan = (composing.end < spanEnd) ? composing.end - spanStart : spanLength;

          if (startInSpan > 0) {
            // ignore: avoid-substring, indices are based on UTF-16 code units
            finalChildren.add(TextSpan(text: rawText.substring(0, startInSpan), style: span.style));
          }

          if (endInSpan > startInSpan) {
            final TextStyle mergedStyle;
            if (span.style case final TextStyle spanStyle?) {
              final TextDecoration combined;
              final existingDeco = spanStyle.decoration;
              if (existingDeco != null &&
                  existingDeco != TextDecoration.none &&
                  !existingDeco.contains(TextDecoration.underline)) {
                combined = TextDecoration.combine([existingDeco, TextDecoration.underline]);
              } else if (existingDeco == null || existingDeco == TextDecoration.none) {
                combined = TextDecoration.underline;
              } else {
                combined = existingDeco;
              }
              mergedStyle = spanStyle.copyWith(decoration: combined);
            } else {
              mergedStyle = composingStyle;
            }

            finalChildren.add(
              // ignore: avoid-substring, indices are based on UTF-16 code units
              TextSpan(text: rawText.substring(startInSpan, endInSpan), style: mergedStyle),
            );
          }

          if (endInSpan < spanLength) {
            // ignore: avoid-substring
            finalChildren.add(TextSpan(text: rawText.substring(endInSpan), style: span.style));
          }
        } else {
          finalChildren.add(span);
        }
        currentOffset += spanLength;
      }
    }

    _cachedFinalChildren = finalChildren;
    _lastComposing = value.composing;
    _lastWithComposing = withComposing;

    // Always return a fresh TextSpan instance containing the cached children.
    // return TextSpan(style: style, children: finalChildren);
    final result = TextSpan(style: style, children: finalChildren);

    // STOP TIMER
    // stopwatch.stop();
    // PRINT THE RESULT TO CONSOLE
    // final isHit = coreCacheHit ? 'HIT ' : 'MISS';
    // debugPrint('\n\nbuildTextSpan ($isHit): ${stopwatch.elapsedMicroseconds} μs\n');

    return result;
  }
}
