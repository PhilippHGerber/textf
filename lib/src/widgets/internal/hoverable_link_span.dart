import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// An internal StatefulWidget used by Textf's LinkHandler to render interactive links
/// that can visually change style on hover.
///
/// This widget manages its own hover state (`_isHovering`) and switches
/// between the provided `normalStyle` and `hoverStyle`. It renders a
/// single `Text.rich` containing the link's content (either plain text
/// or pre-parsed child spans passed via `initialChildrenSpans` or `initialPlainText`).
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
  /// Should be empty if `initialPlainText` is provided.
  final List<InlineSpan> initialChildrenSpans;

  /// The plain display text of the link, used if `initialChildrenSpans` is empty.
  final String? initialPlainText;

  /// The style to apply when the link is not hovered. Resolved by TextfStyleResolver.
  final TextStyle normalStyle;

  /// The style to apply when the link is hovered. Resolved by TextfStyleResolver.
  final TextStyle hoverStyle;

  /// An optional pre-configured `TapGestureRecognizer` for handling taps.
  /// Created by LinkHandler if an `onUrlTap` callback is available.
  final TapGestureRecognizer? tapRecognizer;

  /// The mouse cursor to display when hovering over the link. Resolved by TextfStyleResolver.
  final MouseCursor mouseCursor;

  /// An optional callback function triggered when the hover state changes.
  /// Resolved by TextfStyleResolver. Provides the URL, the raw display text,
  /// and the new hover state (`true` for enter, `false` for exit).
  final Function(String url, String rawDisplayText, bool isHovering)? onHoverCallback;

  /// Creates an internal widget to manage hover state and interaction for a link.
  const HoverableLinkSpan({
    super.key,
    required this.url,
    required this.rawDisplayText,
    required this.initialChildrenSpans,
    this.initialPlainText,
    required this.normalStyle,
    required this.hoverStyle,
    required this.tapRecognizer,
    required this.mouseCursor,
    this.onHoverCallback,
  });

  @override
  State<HoverableLinkSpan> createState() => HoverableLinkSpanState();
}

class HoverableLinkSpanState extends State<HoverableLinkSpan> {
  /// Tracks whether the mouse cursor is currently over this specific link instance.
  bool _isHovering = false;

  @override
  void dispose() {
    // If a TapGestureRecognizer was created and passed in,
    // it must be disposed when the widget is removed to prevent memory leaks.
    widget.tapRecognizer?.dispose();
    super.dispose();
  }

  /// Handles the pointer entering the bounds of the link.
  void _onEnter(PointerEnterEvent event) {
    if (mounted) {
      setState(() => _isHovering = true);
      // Notify listener about hover start, passing URL and raw text
      widget.onHoverCallback?.call(widget.url, widget.rawDisplayText, true);
    }
  }

  /// Handles the pointer exiting the bounds of the link.
  void _onExit(PointerExitEvent event) {
    if (mounted) {
      setState(() => _isHovering = false);
      // Notify listener about hover end
      widget.onHoverCallback?.call(widget.url, widget.rawDisplayText, false);
    }
  }

  /// Recursively applies interaction handlers (tap recognizer, hover callbacks, cursor)
  /// and the correct style (normal or hover) to a given InlineSpan and its children.
  /// This ensures that the entire clickable/hoverable area of the link reacts appropriately.
  InlineSpan _applyInteraction(InlineSpan span) {
    if (span is TextSpan) {
      // Determine the effective style for this specific TextSpan part
      final TextStyle effectiveStyle = _isHovering
          ? widget.hoverStyle // Always apply the full resolved hover style when hovering
          : widget.normalStyle; // Always apply the full resolved normal style otherwise

      // Merge the effective style (normal or hover) ON TOP of the span's original style.
      // The span's original style might contain formatting applied *within* the link text
      // (e.g., bold). We want to preserve that inner formatting while applying the
      // overall link style (color, decoration) and hover changes.
      final TextStyle finalSpanStyle = (span.style ?? const TextStyle()).merge(effectiveStyle);

      return TextSpan(
        text: span.text,
        // Recursively apply interaction and styling to children
        children: span.children?.map(_applyInteraction).toList(),
        style: finalSpanStyle, // Apply the merged style
        recognizer: widget.tapRecognizer, // Attach the single recognizer
        mouseCursor: widget.mouseCursor, // Apply the link cursor
        onEnter: _onEnter, // Attach hover enter handler
        onExit: _onExit, // Attach hover exit handler
        semanticsLabel: span.semanticsLabel,
        locale: span.locale,
        spellOut: span.spellOut,
      );
    }
    // Return other span types (like WidgetSpan, although unlikely inside a link) unmodified.
    return span;
  }

  @override
  Widget build(BuildContext context) {
    // Determine the initial content spans: either the pre-parsed children
    // or a single TextSpan containing the plain text.
    // Note: The initial spans/text don't yet have the interaction handlers attached.
    final List<InlineSpan> initialContentSpans = widget.initialChildrenSpans.isNotEmpty
        ? widget.initialChildrenSpans
        // If plain text, wrap it in a TextSpan. Use normalStyle as the base here,
        // though _applyInteraction will merge the final normal/hover style again.
        : [TextSpan(text: widget.initialPlainText, style: widget.normalStyle)];

    // Apply interaction handlers and correct styling (normal/hover) recursively
    // to the initial content spans.
    final List<InlineSpan> interactiveSpans = initialContentSpans
        .map(_applyInteraction) // Apply handlers and styles
        .toList();

    // Render the resulting interactive spans within a Text.rich widget.
    // The outer TextSpan has no text or style itself, just acts as a container.
    return Text.rich(
      TextSpan(
        children: interactiveSpans,
      ),
      // Ensure Text.rich doesn't apply its own scaling if the spans already account for it.
      // textScaler: TextScaler.noScaling, // Consider if needed, depends on context
    );
  }
}
