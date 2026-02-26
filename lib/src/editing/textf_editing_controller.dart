// Override of buildTextSpan must match Flutter's parameter order.
// ignore_for_file: always_put_required_named_parameters_first

import 'package:flutter/material.dart';

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
/// except when the cursor is inside the formatted span. Use [markerOpacity]
/// to animate the transition (driven by an external [AnimationController]).
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
  }) : _markerVisibility = markerVisibility;

  /// Creates a [TextfEditingController] from a [TextEditingValue].
  TextfEditingController.fromValue(
    super.value, {
    MarkerVisibility markerVisibility = MarkerVisibility.always,
  })  : _markerVisibility = markerVisibility,
        super.fromValue();

  static final TextfSpanBuilder _spanBuilder = TextfSpanBuilder();

  /// Controls how formatting markers are displayed.
  ///
  /// When set to [MarkerVisibility.always], all markers are visible with
  /// dimmed styling (default). When set to [MarkerVisibility.whenActive],
  /// only markers surrounding the cursor are visible; others are hidden
  /// based on [markerOpacity].
  ///
  /// Setting this property calls [notifyListeners] automatically.
  MarkerVisibility get markerVisibility => _markerVisibility;
  MarkerVisibility _markerVisibility;

  set markerVisibility(MarkerVisibility value) {
    if (_markerVisibility == value) return;
    _markerVisibility = value;
    notifyListeners();
  }

  /// Opacity for inactive markers when [markerVisibility] is
  /// [MarkerVisibility.whenActive].
  ///
  /// - `1.0`: markers appear with the default dimmed style.
  /// - `0.0`: markers are fully hidden (collapsed to near-zero font size).
  /// - Values between `0.0` and `1.0` produce a smooth fade effect.
  ///
  /// Values outside `[0.0, 1.0]` are clamped automatically.
  /// Setting this property calls [notifyListeners] automatically.
  ///
  /// This value is typically driven by an external [AnimationController]
  /// in the widget that owns this controller.
  double get markerOpacity => _markerOpacity;
  double _markerOpacity = 1;

  set markerOpacity(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if (_markerOpacity == clamped) return;
    _markerOpacity = clamped;
    notifyListeners();
  }

  /// Clears the internal span builder cache.
  ///
  /// Call this method to free memory in low-memory situations.
  /// The cache will automatically rebuild as text is parsed.
  static void clearCache() => TextfSpanBuilder.clearCache();

  /// Forces a rebuild of the text spans without changing state.
  ///
  /// The [markerOpacity] and [markerVisibility] setters already call
  /// [notifyListeners] automatically. Use this only when you need a
  /// rebuild triggered by external state not tracked by this controller.
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

    // Resolve cursor position for smart-hide mode.
    // When whenActive but no valid selection (e.g. no focus), use null so all
    // markers are treated as inactive (hidden at markerOpacity).
    final int? cursorPos = markerVisibility == MarkerVisibility.whenActive
        ? (value.selection.isValid ? value.selection.extentOffset : null)
        : null;

    // No composing region — parse the full text.
    if (!withComposing || !value.composing.isValid || value.composing.isCollapsed) {
      final spans = _spanBuilder.build(
        text,
        context,
        effectiveStyle,
        cursorPosition: cursorPos,
        markerOpacity: markerOpacity,
      );
      return TextSpan(style: effectiveStyle, children: spans);
    }

    // With composing region: split into before / composing / after segments.
    // Each segment is parsed independently. The composing segment gets an
    // additional underline decoration to indicate active IME composition.
    //
    // Note: If a formatting marker straddles the composing boundary, it becomes
    // unpaired in both segments and renders as plain text. This is acceptable
    // because composing regions are transient IME states.
    final TextRange composing = value.composing;
    // TextEditingValue.composing uses code unit offsets, matching substring.
    // ignore: avoid-substring
    final String beforeText = text.substring(0, composing.start);
    final String composingText =
        // ignore: avoid-substring
        text.substring(composing.start, composing.end);
    // ignore: avoid-substring
    final String afterText = text.substring(composing.end);

    final List<InlineSpan> children = <InlineSpan>[];

    if (beforeText.isNotEmpty) {
      children.addAll(
        _spanBuilder.build(
          beforeText,
          context,
          effectiveStyle,
          cursorPosition: cursorPos,
          markerOpacity: markerOpacity,
        ),
      );
    }

    // Composing text gets underline decoration merged on top.
    final composingStyle = effectiveStyle.merge(
      const TextStyle(decoration: TextDecoration.underline),
    );
    children.addAll(
      _spanBuilder.build(
        composingText,
        context,
        composingStyle,
        cursorPosition: cursorPos != null ? cursorPos - composing.start : null,
        markerOpacity: markerOpacity,
      ),
    );

    if (afterText.isNotEmpty) {
      children.addAll(
        _spanBuilder.build(
          afterText,
          context,
          effectiveStyle,
          // cursorPos - composing.end is negative when the cursor is before
          // composing.end (i.e. in beforeText or composingText). No token
          // position in afterText can be negative, so all afterText markers
          // are treated as inactive — which is the correct behaviour.
          cursorPosition: cursorPos != null ? cursorPos - composing.end : null,
          markerOpacity: markerOpacity,
        ),
      );
    }

    return TextSpan(style: effectiveStyle, children: children);
  }
}
