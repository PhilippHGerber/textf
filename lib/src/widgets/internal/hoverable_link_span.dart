import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// An internal StatefulWidget used by Textf's LinkHandler to render interactive links
/// that can visually change style on hover.
///
/// This widget manages its own hover state (`_isHovering`) and switches
/// between the provided `normalStyle` and `hoverStyle`.
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

  /// The original, raw display text of the link.
  final String rawDisplayText;

  /// Pre-parsed list of [InlineSpan] children if the link's display
  /// text itself contained formatting (e.g., `[**bold** link](url)`).
  final List<InlineSpan> initialChildrenSpans;

  /// The plain display text of the link, used if [initialChildrenSpans] is empty.
  final String? initialPlainText;

  /// The style to apply when the link is not hovered.
  final TextStyle normalStyle;

  /// The style to apply when the link is hovered.
  final TextStyle hoverStyle;

  /// An optional pre-configured [TapGestureRecognizer] for handling taps.
  final TapGestureRecognizer? tapRecognizer;

  /// The mouse cursor to display when hovering over the link.
  final MouseCursor mouseCursor;

  /// An optional callback function triggered when the hover state changes.
  final void Function(String url, String rawDisplayText, {required bool isHovering})?
      onHoverCallback;

  @override
  State<HoverableLinkSpan> createState() => HoverableLinkSpanState();
}

/// The state class for [HoverableLinkSpan] that manages hover interactions.
class HoverableLinkSpanState extends State<HoverableLinkSpan> {
  /// Tracks whether the mouse cursor is currently over this specific link instance.
  bool _isHovering = false;

  /// Handles the pointer entering the bounds of the link.
  void _onEnter(PointerEnterEvent event) {
    if (mounted) {
      setState(() => _isHovering = true);
      widget.onHoverCallback?.call(widget.url, widget.rawDisplayText, isHovering: true);
    }
  }

  /// Handles the pointer exiting the bounds of the link.
  void _onExit(PointerExitEvent event) {
    if (mounted) {
      setState(() => _isHovering = false);
      widget.onHoverCallback?.call(widget.url, widget.rawDisplayText, isHovering: false);
    }
  }

  /// Recursively applies the correct visual styles (normal vs hover) to the span tree.
  InlineSpan _applyStyleRecursive(InlineSpan span) {
    if (span is TextSpan) {
      final TextStyle innerSpanOriginalStyle = span.style ?? widget.normalStyle;
      final TextStyle targetLinkAppearance = _isHovering ? widget.hoverStyle : widget.normalStyle;

      // 1. Determine Decoration (Merge logic)
      TextDecoration? finalDecoration;
      final TextDecoration? linkBaseDecoration = targetLinkAppearance.decoration;
      final TextDecoration? innerExistingDecoration = innerSpanOriginalStyle.decoration;

      if (linkBaseDecoration != null && linkBaseDecoration != TextDecoration.none) {
        // ignore: prefer-conditional-expressions
        if (innerExistingDecoration != null && innerExistingDecoration != TextDecoration.none) {
          finalDecoration = !innerExistingDecoration.contains(linkBaseDecoration)
              ? TextDecoration.combine([innerExistingDecoration, linkBaseDecoration])
              : innerExistingDecoration;
        } else {
          finalDecoration = linkBaseDecoration;
        }
      } else {
        finalDecoration = innerExistingDecoration;
      }

      // 2. Determine Decoration Color and Thickness
      final Color? finalDecorationColor =
          targetLinkAppearance.decorationColor ?? innerSpanOriginalStyle.decorationColor;
      final double? finalDecorationThickness =
          targetLinkAppearance.decorationThickness ?? innerSpanOriginalStyle.decorationThickness;

      // 3. Construct the merged style
      final TextStyle finalSpanStyle = innerSpanOriginalStyle.copyWith(
        color: targetLinkAppearance.color ?? innerSpanOriginalStyle.color,
        decoration: finalDecoration,
        decorationColor: finalDecorationColor,
        decorationThickness: finalDecorationThickness,
      );

      return TextSpan(
        text: span.text,
        children: span.children?.map(_applyStyleRecursive).toList(),
        style: finalSpanStyle,
        // Recognizer is deliberately NOT attached here.
        semanticsLabel: span.semanticsLabel,
        locale: span.locale,
        spellOut: span.spellOut,
      );
    }

    return span;
  }

  @override
  void didUpdateWidget(covariant HoverableLinkSpan oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dispose the old recognizer if it's different from the new one.
    // This prevents memory leaks when the widget rebuilds with a new recognizer
    if (oldWidget.tapRecognizer != widget.tapRecognizer) {
      oldWidget.tapRecognizer?.dispose();
    }
  }

  @override
  void dispose() {
    widget.tapRecognizer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Prepare Content
    final List<InlineSpan> sourceSpans = widget.initialChildrenSpans.isNotEmpty
        ? widget.initialChildrenSpans
        : [TextSpan(text: widget.initialPlainText, style: widget.normalStyle)];

    // 2. Apply Visual Styles
    final List<InlineSpan> styledSpans = sourceSpans.map(_applyStyleRecursive).toList();

    // 3. Render
    // We use GestureDetector instead of TextSpan.recognizer.
    // Why? Because TextSpan recognizers do NOT inherit to children.
    // Since our root span has no text (only children), a recognizer on the root
    // is effectively dead. A GestureDetector on the Text widget works perfectly
    // because WidgetSpans are treated as atomic boxes.
    Widget content = Text.rich(
      TextSpan(children: styledSpans),
      textScaler: TextScaler.noScaling,
    );

    final tapRecognizer = widget.tapRecognizer;
    if (tapRecognizer != null) {
      content = GestureDetector(
        // Extract the callback from the recognizer.
        onTap: tapRecognizer.onTap,
        child: content,
      );
    }

    return MouseRegion(
      cursor: widget.mouseCursor,
      onEnter: _onEnter,
      onExit: _onExit,
      opaque: false,
      child: Semantics(
        link: true,
        label: widget.rawDisplayText,
        onTap: widget.tapRecognizer?.onTap,
        child: content,
      ),
    );
  }
}
