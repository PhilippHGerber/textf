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
  /// Creates an internal widget to manage hover state and interaction for a link.
  const HoverableLinkSpan({
    required this.url,
    required this.rawDisplayText,
    required this.initialChildrenSpans,
    required this.normalStyle,
    required this.hoverStyle,
    required this.tapRecognizer,
    required this.mouseCursor,
    super.key,
    this.initialPlainText,
    this.onHoverCallback,
  });

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
  final void Function(String url, String rawDisplayText, {required bool isHovering})? onHoverCallback;

  @override
  State<HoverableLinkSpan> createState() => HoverableLinkSpanState();
}

/// The state class for [HoverableLinkSpan] that manages hover interactions
/// and applies the appropriate styles based on hover state.
class HoverableLinkSpanState extends State<HoverableLinkSpan> {
  /// Tracks whether the mouse cursor is currently over this specific link instance.
  bool _isHovering = false;

  /// Handles the pointer entering the bounds of the link.
  void _onEnter(PointerEnterEvent event) {
    if (mounted) {
      setState(() => _isHovering = true);
      // Notify listener about hover start, passing URL and raw text
      widget.onHoverCallback?.call(widget.url, widget.rawDisplayText, isHovering: true);
    }
  }

  /// Handles the pointer exiting the bounds of the link.
  void _onExit(PointerExitEvent event) {
    if (mounted) {
      setState(() => _isHovering = false);
      // Notify listener about hover end
      widget.onHoverCallback?.call(widget.url, widget.rawDisplayText, isHovering: false);
    }
  }

  /// Recursively applies interaction handlers (tap recognizer, hover callbacks, cursor)
  /// and the correct style (normal or hover) to a given InlineSpan and its children.
  /// This ensures that the entire clickable/hoverable area of the link reacts appropriately.
  InlineSpan _applyInteraction(InlineSpan span) {
    if (span is TextSpan) {
      final TextStyle innerSpanOriginalStyle = span.style ?? widget.normalStyle;
      final TextStyle targetLinkAppearance = _isHovering ? widget.hoverStyle : widget.normalStyle;

      // Determine the final decoration for this span segment
      TextDecoration? finalDecoration;

      // The decoration from the link itself (e.g., underline from normalStyle/hoverStyle)
      final TextDecoration? linkBaseDecoration = targetLinkAppearance.decoration;

      // The decoration already present on the inner span (e.g., lineThrough, or combine)
      final TextDecoration? innerExistingDecoration = innerSpanOriginalStyle.decoration;

      finalDecoration = (linkBaseDecoration != null && linkBaseDecoration != TextDecoration.none)
          ? ((innerExistingDecoration != null && innerExistingDecoration != TextDecoration.none)
              ? (innerExistingDecoration.contains(linkBaseDecoration)
                  ? innerExistingDecoration
                  : TextDecoration.combine([innerExistingDecoration, linkBaseDecoration]))
              : linkBaseDecoration)
          : innerExistingDecoration;

      // Determine final decoration color and thickness
      // Priority:
      // 1. If targetLinkAppearance (the link's current style) defines them.
      // 2. Else, if innerSpanOriginalStyle defines them.
      // 3. Else, null (let Flutter decide or inherit).
      // This logic might need refinement based on desired visual outcome for combined decorations.
      // For now, let the targetLinkAppearance's properties (if set) take precedence for the overall link feel.
      final Color? finalDecorationColor =
          targetLinkAppearance.decorationColor ?? innerSpanOriginalStyle.decorationColor;
      final double? finalDecorationThickness =
          targetLinkAppearance.decorationThickness ?? innerSpanOriginalStyle.decorationThickness;

      final TextStyle finalSpanStyle = innerSpanOriginalStyle.copyWith(
        color: targetLinkAppearance.color ?? innerSpanOriginalStyle.color, // Link color takes precedence
        decoration: finalDecoration, // Apply the intelligently combined/chosen decoration
        decorationColor: finalDecorationColor,
        decorationThickness: finalDecorationThickness,
        // Preserve other properties from innerSpanOriginalStyle like fontWeight, fontStyle, backgroundColor
        // by not specifying them here if targetLinkAppearance doesn't override them.
        // backgroundColor, letterSpacing etc. should come from innerSpanOriginalStyle unless
        // targetLinkAppearance explicitly sets them (which it usually doesn't for these).
      );

      return TextSpan(
        text: span.text,
        children: span.children?.map(_applyInteraction).toList(),
        style: finalSpanStyle,
        recognizer: widget.tapRecognizer,
        semanticsLabel: span.semanticsLabel,
        locale: span.locale,
        spellOut: span.spellOut,
      );
    }

    return span;
  }

  @override
  void dispose() {
    // If a TapGestureRecognizer was created and passed in,
    // it must be disposed when the widget is removed to prevent memory leaks.
    widget.tapRecognizer?.dispose();
    super.dispose();
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
    return MouseRegion(
      cursor: widget.mouseCursor, // Der übergebene Cursor (z.B. help)
      onEnter: _onEnter, // Eigene Methode für Hover-Effekte
      onExit: _onExit, // Eigene Methode für Hover-Effekte
      opaque: false, // Wichtig für Textselektion
      child: Text.rich(
        TextSpan(
          children: interactiveSpans,
        ),
      ),
    );
  }
}
