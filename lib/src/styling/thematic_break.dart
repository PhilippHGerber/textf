// The public surface here is a top-level function; the private leaf widget's
// name intentionally does not match the file name.
// ignore_for_file: prefer-match-file-name

import 'package:flutter/material.dart';

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

/// Builds the default thematic-break rule as an [InlineSpan].
///
/// A guarded, full-width 1px rule in the theme's `dividerColor`. The guard —
/// reading the incoming layout constraint and degrading an infinite `maxWidth`
/// to [_thematicBreakFallbackWidth] — is what lets the rule render without
/// asserting even when the hosting `Textf` sits in an unbounded-width parent.
InlineSpan defaultThematicBreakSpan() {
  return const WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: _ThematicBreakRule(),
  );
}

/// Wraps a user-supplied [builder] as the thematic-break [InlineSpan].
///
/// The builder owns the rule's appearance and its own width behaviour, so —
/// unlike [defaultThematicBreakSpan] — there is no unbounded-width guard around
/// it. [Builder] gives the widget a [BuildContext] positioned at its render
/// location, so `Theme.of` and friends resolve correctly.
InlineSpan customThematicBreakSpan(Widget Function(BuildContext context) builder) {
  return WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Builder(builder: builder),
  );
}

/// The leaf widget of the default rule: a 1px [ColoredBox] sized to the
/// available width, guarded against unbounded-width parents.
class _ThematicBreakRule extends StatelessWidget {
  const _ThematicBreakRule();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : _thematicBreakFallbackWidth;
        return SizedBox(
          height: _thematicBreakThickness,
          width: width,
          child: ColoredBox(color: Theme.of(context).dividerColor),
        );
      },
    );
  }
}
