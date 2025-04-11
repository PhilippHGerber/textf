// This is an internal widget used by the Textf package.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../parsing/parser.dart';

/// An internal StatefulWidget used by Textf to render interactive links
/// that can visually change style on hover.
///
/// This widget manages its own hover state (`_isHovering`) and switches
/// between the provided `normalStyle` and `hoverStyle`. It renders a
/// single `Text.rich` containing the link's content (either plain text
/// or pre-parsed child spans).
///
/// It's intended to be wrapped within a `WidgetSpan` by the `LinkHandler`.
class HoverableLinkSpan extends StatefulWidget {
  /// The target URL of the link.
  final String url;

  /// The original, raw display text of the link as it appeared in the
  /// source string (including formatting markers). Used for callbacks.
  final String rawDisplayText;

  /// Pre-parsed list of `InlineSpan` children if the link's display
  /// text itself contained formatting (e.g., `[**bold** link](url)`).
  /// Should be empty if `plainText` is provided.
  final List<InlineSpan> initialChildrenSpans;

  /// The plain display text of the link, used if `childrenSpans` is empty.
  final String? initialPlainText;

  /// The style to apply when the link is not hovered.
  final TextStyle normalStyle;

  /// The style to apply when the link is hovered.
  final TextStyle hoverStyle;

  /// An optional pre-configured `TapGestureRecognizer` for handling taps.
  final TapGestureRecognizer? tapRecognizer;

  /// The mouse cursor to display when hovering over the link.
  final MouseCursor mouseCursor;

  /// An optional callback function triggered when the hover state changes.
  /// Provides the URL, the raw display text, and the new hover state.
  final Function(String url, String rawDisplayText, bool isHovering)?
      onHoverCallback;

  /// Creates an internal widget to manage hover state for a link.
  const HoverableLinkSpan({
    super.key,
    required this.url,
    required this.rawDisplayText,
    required this.initialChildrenSpans,
    this.initialPlainText,
    required this.normalStyle, // Pass the base style
    required this.hoverStyle, // Pass hover *changes*
    required this.tapRecognizer,
    required this.mouseCursor,
    this.onHoverCallback,
  });

  @override
  State<HoverableLinkSpan> createState() => HoverableLinkSpanState();
}

class HoverableLinkSpanState extends State<HoverableLinkSpan> {
  /// Tracks whether the mouse cursor is currently over this link span.
  bool _isHovering = false;
  // Cache the parser instance - can be static or instance variable
  // Creating a new one each build might be okay for small link texts
  final TextfParser _linkContentParser = TextfParser(maxCacheSize: 5);

  void _onEnter(PointerEnterEvent event) {
    if (mounted) {
      setState(() => _isHovering = true);
      widget.onHoverCallback?.call(widget.url, widget.rawDisplayText, true);
    }
  }

  void _onExit(PointerExitEvent event) {
    if (mounted) {
      setState(() => _isHovering = false);
      widget.onHoverCallback?.call(widget.url, widget.rawDisplayText, false);
    }
  }

  /// Helper to apply interaction handlers and hover style to a single span.
  InlineSpan _applyInteraction(InlineSpan span) {
    if (span is TextSpan) {
      // Determine the effective style for this span based on hover state
      final TextStyle effectiveStyle = _isHovering
          ? (span.style ?? widget.normalStyle)
              .merge(widget.hoverStyle) // Merge hover onto existing span style
          : (span.style ??
              widget
                  .normalStyle); // Use existing span style or normal as fallback

      return TextSpan(
        text: span.text,
        // Recursively apply interaction to children as well!
        children: span.children?.map(_applyInteraction).toList(),
        style: effectiveStyle, // Apply the calculated style
        recognizer: widget.tapRecognizer,
        mouseCursor: widget.mouseCursor,
        onEnter: _onEnter,
        onExit: _onExit,
        semanticsLabel: span.semanticsLabel,
        locale: span.locale,
        spellOut: span.spellOut,
      );
    }
    // Return other span types (like WidgetSpan) unmodified for now
    return span;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get the initial list of spans to render.
    //    If initialPlainText is provided, wrap it in a TextSpan.
    //    Use the normalStyle as the base style for the plain text case.
    final List<InlineSpan> spansToRender = widget
            .initialChildrenSpans.isNotEmpty
        ? widget.initialChildrenSpans
        : [TextSpan(text: widget.initialPlainText, style: widget.normalStyle)];

    // 2. Apply interaction handlers and hover styling recursively to all spans.
    final List<InlineSpan> interactiveSpans = spansToRender
        .map(_applyInteraction) // Use the recursive helper
        .toList();

    // 3. Render the modified spans.
    return Text.rich(
      TextSpan(
        // Outer span has no style/text, just holds interactive children
        children: interactiveSpans,
      ),
    );
  }
}
