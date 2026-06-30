import 'package:flutter/material.dart';

import '../models/format_stack_entry.dart';
import '../styling/textf_style_resolver.dart';

/// Shared ATX-heading line logic for the read path (`ParserState`) and the edit
/// path (the span builder's build state).
///
/// Both pipelines consume the identical token stream and must end a heading
/// region the same way, so the begin/end/append logic lives here once — the two
/// pipelines cannot drift. Hosts provide the small set of state hooks below;
/// everything heading-specific (including the back-to-base re-resolution) is
/// implemented here.
mixin HeadingRegion {
  TextStyle? _headingStyle;

  /// The active heading style while inside a heading line, else `null`.
  TextStyle? get headingStyle => _headingStyle;

  /// The base (non-heading) text style.
  TextStyle get baseStyle;

  /// Resolver used for heading and inline-marker styles.
  TextfStyleResolver get headingResolver;

  /// The host's active formatting stack (re-resolved when a heading ends).
  List<FormatStackEntry> get formatStack;

  /// The host's text accumulation buffer.
  StringBuffer get textBuffer;

  /// Flushes [textBuffer] into the host's span list with the current style.
  void flushText();

  /// Begins a heading region for [level]. Subsequent content uses the resolved
  /// heading style as its root until [endHeading] is called.
  void beginHeading(int level) {
    _headingStyle = headingResolver.resolveHeadingStyle(level, baseStyle);
  }

  /// Ends the active heading region.
  ///
  /// Any still-open inline marker (e.g. a `**` opened on the heading line but
  /// not yet closed) was pushed with the heading style as its root, because the
  /// opening-marker path resolves against `currentStyle()` — which is the
  /// heading style inside a heading line. Once the line ends, that heading scope
  /// is gone, so each open entry is **recomputed** with [baseStyle] as the root
  /// (nesting preserved). This is what keeps the enlarged heading size from
  /// bleeding past the line break while a genuinely-paired inline format still
  /// applies (now at base size) to the following line.
  void endHeading() {
    _headingStyle = null;
    var previousStyle = baseStyle;
    for (var i = 0; i < formatStack.length; i++) {
      final entry = formatStack[i];
      final resolved = headingResolver.resolveStyle(entry.type, previousStyle);
      formatStack[i] = FormatStackEntry(
        index: entry.index,
        matchingIndex: entry.matchingIndex,
        type: entry.type,
        resolvedStyle: resolved,
      );
      previousStyle = resolved;
    }
  }

  /// Appends [value] to [textBuffer], terminating an active heading at the first
  /// newline (the newline and preceding text keep the heading style; anything
  /// after resumes the base style). Every character — including the newline — is
  /// still emitted exactly once via [flushText], preserving the 1:1 invariant.
  void appendText(String value) {
    if (_headingStyle == null) {
      textBuffer.write(value);
      return;
    }
    final int nl = value.indexOf('\n');
    if (nl < 0) {
      textBuffer.write(value);
      return;
    }
    // The split boundary is the index right after the newline. `\n` (U+000A) is
    // a single BMP code unit and can never be half of a surrogate pair, so
    // `nl + 1` is always a valid code-unit boundary — these substrings never
    // bisect an emoji. (Same invariant the tokenizer relies on.)
    // ignore: avoid-substring
    textBuffer.write(value.substring(0, nl + 1));
    flushText();
    endHeading();
    if (nl + 1 < value.length) {
      // ignore: avoid-substring
      appendText(value.substring(nl + 1));
    }
  }
}
