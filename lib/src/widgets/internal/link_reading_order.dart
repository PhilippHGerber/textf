import 'package:flutter/semantics.dart' show OrdinalSortKey;
import 'package:flutter/widgets.dart';

import '../../styling/thematic_break.dart';
import 'hoverable_link_span.dart';

/// Puts the links of a paragraph in sentence order for screen readers (ADR 0007).
///
/// Returns [spans] unchanged when they contain no link, so paragraphs without
/// links keep one merged semantics node. Otherwise it returns a copy that:
///
/// * ends in [_marker], a `TextSpan` with a `semanticsIdentifier`, which
///   switches `RenderParagraph` from one merged label to one node per text run
///   and per placeholder; and
/// * gives every placeholder (links, scripts, widget placeholders) an
///   [OrdinalSortKey] between the keys of the text runs around it. The key
///   merges into the placeholder's own node. A widget placeholder without
///   semantics, or with a container node, gets an empty node instead, which
///   screen readers do not focus. The default thematic-break rule has no
///   semantics and stays unkeyed.
///
/// `RenderParagraph` keys its text runs `0, 1, 2, …` but leaves placeholder
/// nodes unkeyed, and the geometric fallback misorders them: the padded run
/// rects overlap the placeholders. With every node keyed, screen readers follow
/// the keys, which is source order.
List<InlineSpan> withLinkReadingOrder(List<InlineSpan> spans) {
  if (!_containsLink(spans)) return spans;

  final keys = _PlaceholderSortKeys();

  return [...spans.map(keys.visit), _marker];
}

/// Switches the paragraph to ordered child nodes (ADR 0007). It has no text,
/// so it produces no node of its own.
const TextSpan _marker = TextSpan(text: '', semanticsIdentifier: 'textf-link-reading-order');

/// The first placeholder after a text run sits halfway to the next run's key.
const int _firstPlaceholderDivisor = 2;

bool _containsLink(List<InlineSpan> spans) {
  bool found = false;
  for (final span in spans) {
    span.visitChildren((child) {
      found = child is WidgetSpan && child.child is HoverableLinkSpan;

      return !found;
    });
    if (found) return true;
  }

  return false;
}

/// Walks a span tree in semantics order and keys each placeholder.
///
/// Mirrors how `RenderParagraph` splits text into runs (`combineSemanticsInfo`):
/// consecutive text merges into one run, and a placeholder or a span with a
/// recognizer or `semanticsIdentifier` ends the run. Empty runs get no key.
final class _PlaceholderSortKeys {
  /// Text runs closed so far; the next run gets this key.
  int _runs = 0;

  /// Whether text has accumulated since the last closed run.
  bool _openRun = false;

  /// Placeholders keyed since the last closed run.
  int _placeholdersSinceRun = 0;

  InlineSpan visit(InlineSpan span) => switch (span) {
    TextSpan() => _visitText(span),
    WidgetSpan() => _visitWidget(span),
    _ => span,
  };

  TextSpan _visitText(TextSpan span) {
    final String? text = span.text;
    if (text != null) {
      if (span.recognizer != null || span.semanticsIdentifier != null) {
        _closeRun();
        if (text.isNotEmpty) _startRun();
        _closeRun();
      } else if (text.isNotEmpty) {
        _startRun();
      }
    }

    final List<InlineSpan>? children = span.children;
    if (children == null) return span;

    return TextSpan(
      text: span.text,
      children: children.map(visit).toList(),
      style: span.style,
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel,
      semanticsIdentifier: span.semanticsIdentifier,
      locale: span.locale,
      spellOut: span.spellOut,
    );
  }

  WidgetSpan _visitWidget(WidgetSpan span) {
    _closeRun();
    // A key would give the rule an empty node of its own.
    if (isDefaultThematicBreakSpan(span)) return span;
    // Strictly between the previous run (_runs - 1) and the next (_runs),
    // increasing for consecutive placeholders: _runs - 1/2, _runs - 1/3, …
    final double order = _runs - 1 / (_firstPlaceholderDivisor + _placeholdersSinceRun);
    _placeholdersSinceRun += 1;

    return WidgetSpan(
      alignment: span.alignment,
      baseline: span.baseline,
      style: span.style,
      child: Semantics(sortKey: OrdinalSortKey(order), child: span.child),
    );
  }

  void _startRun() => _openRun = true;

  void _closeRun() {
    if (!_openRun) return;
    _runs += 1;
    _openRun = false;
    _placeholdersSinceRun = 0;
  }
}
