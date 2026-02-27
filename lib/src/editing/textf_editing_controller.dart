// Override of buildTextSpan must match Flutter's parameter order.
// ignore_for_file: always_put_required_named_parameters_first

import 'package:flutter/material.dart';

import '../core/textf_limits.dart';
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

  /// Controls how formatting markers are displayed.
  ///
  /// When set to [MarkerVisibility.always], all markers are visible with
  /// dimmed styling (default). When set to [MarkerVisibility.whenActive],
  /// only markers surrounding the cursor are visible; others are instantly
  /// hidden. During text selection, all markers are hidden to prevent
  /// layout jumps.
  ///
  /// Setting this property calls [notifyListeners] automatically.
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
  /// Setting this property calls [notifyListeners] automatically.
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
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final TextStyle effectiveStyle = style ?? const TextStyle();

    // Fast path: empty text
    if (text.isEmpty) {
      return TextSpan(style: effectiveStyle);
    }

    // Circuit breaker: skip formatting for very long text.
    if (text.length > _maxLiveFormattingLength) {
      return TextSpan(text: text, style: effectiveStyle);
    }

    // Resolve cursor position for smart-hide mode.
    //
    // Three states:
    //   null  → always mode: show all markers with dimmed style.
    //   >= 0  → whenActive + collapsed cursor: show markers only at this pos.
    //   -1    → whenActive + active selection (or no valid selection): hide
    //           ALL markers. The sentinel -1 never matches any span range
    //           (openPos is always >= 0), so every marker gets the hidden
    //           style. This prevents layout jumps during drag selection on
    //           mobile, where toggling marker visibility would shift
    //           selection handles.
    final int? cursorPos;
    if (_markerVisibility == MarkerVisibility.whenActive) {
      final sel = value.selection;
      cursorPos = sel.isValid && sel.isCollapsed //
          ? sel.extentOffset
          : TextfSpanBuilder.hideAllMarkers;
    } else {
      cursorPos = null;
    }

    // 1. ALWAYS parse the entire text as a single unit first.
    // This ensures all formatting pairs, links, and nesting are resolved correctly.
    final List<InlineSpan> fullSpans = _spanBuilder.build(
      text,
      context,
      effectiveStyle,
      cursorPosition: cursorPos,
    );

    // 2. If no composing region is active, just return the parsed spans.
    if (!withComposing || !value.composing.isValid || value.composing.isCollapsed) {
      return TextSpan(style: effectiveStyle, children: fullSpans);
    }

    // 3. With composing region: inject the IME underline into the spans.
    // We iterate through the flat list of spans and "slice" any TextSpan
    // that overlaps with the composing range.
    final TextRange composing = value.composing;
    final List<InlineSpan> children = <InlineSpan>[];
    const TextStyle composingStyle = TextStyle(decoration: TextDecoration.underline);

    int currentOffset = 0;

    for (final InlineSpan span in fullSpans) {
      final int spanLength = span is TextSpan ? (span.text?.length ?? 0) : 1;
      final int spanStart = currentOffset;
      final int spanEnd = currentOffset + spanLength;

      if (spanEnd <= composing.start || spanStart >= composing.end) {
        // Span is completely outside the composing range
        children.add(span);
      } else {
        // Span overlaps with the composing range
        if (span is TextSpan) {
          final String? rawText = span.text;

          if (rawText == null || rawText.isEmpty) {
            // Safety fallback: if span has no text, pass it through untouched
            children.add(span);
          } else {
            // Calculate local intersection indices
            final int startInSpan = (composing.start > spanStart) //
                ? composing.start - spanStart
                : 0;
            final int endInSpan = (composing.end < spanEnd) //
                ? composing.end - spanStart
                : spanLength;

            // Note on avoid-substring:
            // It is strictly necessary to use `substring` here instead of `characters`.
            // Flutter's `TextEditingValue.composing` provides indices based on UTF-16
            // code units, which perfectly align with Dart's `String.substring`.
            // Using grapheme clusters (`characters`) would cause index mismatch crashes.

            // Segment before composing
            if (startInSpan > 0) {
              // ignore: avoid-substring, indices are based on UTF-16 code units
              children.add(TextSpan(text: rawText.substring(0, startInSpan), style: span.style));
            }

            // Segment currently composing (inject underline)
            if (endInSpan > startInSpan) {
              final TextStyle mergedStyle = span.style?.merge(composingStyle) ?? composingStyle;
              children.add(
                // ignore: avoid-substring, indices are based on UTF-16 code units
                TextSpan(text: rawText.substring(startInSpan, endInSpan), style: mergedStyle),
              );
            }

            // Segment after composing
            if (endInSpan < spanLength) {
              // ignore: avoid-substring
              children.add(TextSpan(text: rawText.substring(endInSpan), style: span.style));
            }
          }
        } else if (span is WidgetSpan) {
          // WidgetSpans (used for preview mode scripts) are atomic.
          // They take up 1 char space. We just pass them through.
          children.add(span);
        }
      }

      currentOffset += spanLength;
    }

    return TextSpan(style: effectiveStyle, children: children);
  }
}
