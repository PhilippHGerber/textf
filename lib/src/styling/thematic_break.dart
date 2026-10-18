// The public surface here is a top-level function; the private leaf widget's
// name intentionally does not match the file name.
// ignore_for_file: prefer-match-file-name

import 'package:flutter/widgets.dart';

/// Thickness of the default thematic-break rule, in logical pixels.
const double _thematicBreakThickness = 1;

/// Finite width the rule falls back to when it is laid out under a genuinely
/// unbounded-width parent (an unconstrained `Row`, a horizontal scroll view).
///
/// A width-bounded parent — the normal case — passes the paragraph width to the
/// `WidgetSpan` child as a *finite* `maxWidth`, so the rule fills it
/// responsively and this fallback never applies. It exists only so the
/// degenerate unbounded case degrades to a finite width instead of throwing a
/// layout error.
const double _thematicBreakFallbackWidth = 200;

/// Upper bound on distinct rule colors kept in [_defaultRuleSpans].
const int _maxCachedRuleSpans = 16;

/// Default rule spans already built, keyed by their resolved color.
///
/// Handing back the *identical* span (and so the identical child widget) for a
/// color seen before lets Flutter skip rebuilding the rule's element when the
/// surrounding text is re-parsed — what the `const` rule gave for free before
/// the rule took a color. Apps use a handful of rule colors, so the map is
/// simply cleared if it ever outgrows [_maxCachedRuleSpans].
final Map<Color, InlineSpan> _defaultRuleSpans = <Color, InlineSpan>{};

/// Builds the default thematic-break rule as an [InlineSpan].
///
/// A guarded, full-width 1px rule painted in [color], which the style resolver
/// has already resolved (the `thematicBreakColor` option, or the color of the
/// *effective root style* at a low alpha). The guard — reading the incoming layout constraint
/// and degrading an infinite `maxWidth` to [_thematicBreakFallbackWidth] — is
/// what lets the rule render without asserting even when the hosting `Textf`
/// sits in an unbounded-width parent.
///
/// Returns the identical span for a color it has built before (see
/// [_defaultRuleSpans]).
InlineSpan defaultThematicBreakSpan(Color color) {
  final InlineSpan? cached = _defaultRuleSpans[color];
  if (cached != null) {
    return cached;
  }
  if (_defaultRuleSpans.length >= _maxCachedRuleSpans) {
    _defaultRuleSpans.clear();
  }
  return _defaultRuleSpans[color] = WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: _ThematicBreakRule(color: color),
  );
}

/// Wraps a user-supplied [builder] as the thematic-break [InlineSpan].
///
/// The builder owns the rule's appearance and its own width behaviour, so —
/// unlike [defaultThematicBreakSpan] — there is no unbounded-width guard around
/// it. [Builder] gives the widget a [BuildContext] positioned at its render
/// location, so inherited widgets — the host's design-system theme,
/// [DefaultTextStyle], `TextfOptions.of` — resolve correctly.
InlineSpan customThematicBreakSpan(Widget Function(BuildContext context) builder) {
  return WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Builder(builder: builder),
  );
}

/// Re-wraps a thematic-break [rule] span for the editing pipeline, where it
/// stands in for the hidden marker characters of a rule line.
///
/// An editable field lays its text out slightly narrower than the width it
/// offers inline widgets (it reserves room for the caret), so a full-width rule
/// would overflow its line and push the slots after it onto an extra, empty
/// line. The wrapper therefore reports a zero advance width to the paragraph
/// and lets the rule paint across the offered width — or
/// [_thematicBreakFallbackWidth] when that is unbounded — from the line start.
InlineSpan editingThematicBreakSpan(InlineSpan rule) {
  if (rule is! WidgetSpan) {
    return rule;
  }
  return WidgetSpan(
    alignment: rule.alignment,
    baseline: rule.baseline,
    child: _ZeroAdvanceRule(child: rule.child),
  );
}

/// The leaf widget of the default rule: a 1px [ColoredBox] sized to the
/// available width, guarded against unbounded-width parents.
class _ThematicBreakRule extends StatelessWidget {
  const new({required this.color});

  /// The rule color, resolved at parse time.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _thematicBreakFallbackWidth;
        return SizedBox(
          height: _thematicBreakThickness,
          width: width,
          child: ColoredBox(color: color),
        );
      },
    );
  }
}

/// Lays [child] out across the available width while itself occupying no
/// horizontal space, so the paragraph never wraps around it.
class _ZeroAdvanceRule extends StatelessWidget {
  const new({required this.child});

  /// The rule widget to paint.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _thematicBreakFallbackWidth;
        return Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 0,
          child: SizedBox(width: width, child: child),
        );
      },
    );
  }
}
