// ignore_for_file: no-magic-number, avoid-substring, avoid-late-keyword

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:url_launcher/url_launcher.dart';

class TitleAnimation extends StatefulWidget {
  const TitleAnimation({super.key});

  @override
  State<TitleAnimation> createState() => _TitleAnimationState();
}

/// Simulates an IDE-like typing animation that progressively adds Textf
/// formatting markers to a line of code, showing how plain text transforms
/// into rich formatted text.
///
/// ## How it works
///
/// The animation steps through a list of keyframes ([_animationSteps]).
/// Each keyframe is a raw Textf string rendered by a [TextField] with
/// [TextfEditingController]. A `|` in each keyframe marks the cursor
/// position (removed before setting the text).
///
/// Between keyframes, the cursor animates to the insertion point, then
/// characters are typed one-by-one into the raw string, so the user sees
/// formatting markers being inserted in real time.
///
/// With [MarkerVisibility.whenActive], markers hide automatically when the
/// cursor leaves a formatted span — no ZWS tricks needed for bold, italic,
/// or highlight. ZWS is only used for link syntax to prevent premature
/// `[Textf](url)` rendering while typing.
///
/// The final keyframe switches to a [Textf] widget with a clickable link.
class _TitleAnimationState extends State<TitleAnimation> {
  /// Whether the blinking cursor is visible.
  bool _showCursor = false;

  /// Whether the final resting frame is shown (Textf with clickable link).
  bool _showFinalFrame = false;

  /// Controls the animation loop lifecycle.
  bool _isAnimating = true;

  /// The editing controller that renders live textf formatting.
  late TextfEditingController _controller;

  /// Focus node — the TextField needs focus to show a cursor.
  late FocusNode _focusNode;

  /// Zero-width space — used in link keyframes to prevent premature formatting.
  static const String _zws = '\u200B';

  /// Horizontal padding of the container (must match [build] decoration).
  static const double _horizontalPadding = 24;

  // -- Timing constants --

  /// How long each keyframe is held before moving to the next.
  static const Duration _keyframeHoldDuration = Duration(milliseconds: 500);

  /// Extra pause after a ZWS→formatted link transition, so the rendered link is visible briefly.
  static const Duration _linkRevealPause = Duration(milliseconds: 1500);

  /// How long the final keyframe is held before the loop restarts.
  static const Duration _loopRestartDelay = Duration(seconds: 10);

  /// Pause after the cursor reaches the insertion point, before typing begins.
  static const Duration _cursorPositionDelay = Duration(milliseconds: 40);

  /// Delay between each typed character.
  static const Duration _characterTypeDelay = Duration(milliseconds: 100);

  /// Delay between each cursor movement step (one character at a time).
  static const Duration _cursorMoveStepDelay = Duration(milliseconds: 80);

  /// Text style used for the TextField.
  /// Uses the bundled RobotoMono variable font for consistent monospace rendering.
  static const TextStyle _style = TextStyle(
    fontSize: 16,
    fontFamily: 'RobotoMono',
    height: 1.5,
  );

  /// Animation keyframes — each is a raw Textf string with `|` marking
  /// the cursor position.

  // Build **rich**, *styled* text^fast^ using textf with ==zero boilerplate==.
  final List<String> _animationSteps = [
    "Text(\n  'Build rich, styled text using '\n  'Textf with zero boilerplate.'\n)",
    "|Text(\n  'Build rich, styled text using '\n  'Textf with zero boilerplate.'\n)",
    // Textf
    "Textf|(\n  'Build rich, styled text using '\n  'Textf with zero boilerplate.'\n)",
    // bold rich
    "Textf(\n  'Build **|rich, styled text using '\n  'Textf with zero boilerplate.'\n)",
    "Textf(\n  'Build **rich**|, styled text using '\n  'Textf with zero boilerplate.'\n)",
    // underline styled
    "Textf(\n  'Build **rich**, *|styled text using '\n  'Textf with zero boilerplate.'\n)",
    "Textf(\n  'Build **rich**, *styled*| text using '\n  'Textf with zero boilerplate.'\n)",
    // superscript fast
    // "Textf('Build **rich**, *styled* text using textf with zero boilerplate.')",
    "Textf(\n  'Build **rich**, *styled* text^fast^| using '\n  'Textf with zero boilerplate.'\n)",
    // Link textf
    "Textf(\n  'Build **rich**, *styled* text^fast^ using '\n  '[|Textf with zero boilerplate.'\n)",
    "Textf(\n  'Build **rich**, *styled* text^fast^ using '\n  '[Textf]$_zws(https://pub.dev/packages/textf)| with zero boilerplate.'\n)",
    "Textf(\n  'Build **rich**, *styled* text^fast^ using '\n  '[Textf](https://pub.dev/packages/textf)| with zero boilerplate.'\n)",
    // Highlight zero boilerplate
    "Textf(\n  'Build **rich**, *styled* text^fast^ using '\n  '[Textf](https://pub.dev/packages/textf) with ==|zero boilerplate.'\n)",
    "Textf(\n  'Build **rich**, *styled* text^fast^ using '\n  '[Textf](https://pub.dev/packages/textf) with ==zero boilerplate==|.'\n)",
    "Textf(\n  'Build **rich**, *styled* text^fast^ using '\n  '[Textf](https://pub.dev/packages/textf) with ==zero boilerplate==.'\n)",

    // highlight zero boilerplate
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextfEditingController(
      markerVisibility: MarkerVisibility.whenActive,
    );
    _focusNode = FocusNode();
    unawaited(_startAnimationSequence());
  }

  /// Parses a keyframe string: removes the `|` cursor marker and returns
  /// the clean text and the cursor position within it.
  (String text, int cursorPos) _parseKeyframe(String keyframe) {
    final idx = keyframe.indexOf('|');
    if (idx == -1) return (keyframe, keyframe.length);
    return (
      keyframe.substring(0, idx) + keyframe.substring(idx + 1),
      idx,
    );
  }

  /// Sets the controller's text and cursor position atomically.
  void _setTextAndCursor(String text, int cursorPos) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursorPos),
    );
  }

  /// Main animation loop — steps through keyframes, typing characters
  /// one-by-one between them.
  Future<void> _startAnimationSequence() async {
    while (mounted && _isAnimating) {
      // Reset state at the start of each loop
      setState(() {
        _showCursor = false;
        _showFinalFrame = false;
      });
      _setTextAndCursor('', 0);

      for (int i = 0; i < _animationSteps.length; i++) {
        if (!mounted || !_isAnimating) return;

        final isLastFrame = i == _animationSteps.length - 1;
        final (nextText, nextCursor) = _parseKeyframe(_animationSteps[i]);

        if (i == 0) {
          // Step 0: just show the first keyframe, no cursor.
          _setTextAndCursor(nextText, nextCursor);
        } else {
          final (prevText, _) = _parseKeyframe(_animationSteps[i - 1]);
          final prevHasZws = prevText.contains(_zws);

          if (prevHasZws) {
            // ZWS→formatted transition: instant swap, no typing animation.
            setState(() => _showCursor = true);
            _focusNode.requestFocus();
            _setTextAndCursor(nextText, nextCursor);
            await Future<void>.delayed(_linkRevealPause);
          } else {
            // Normal step: animate cursor to insertion point, then type.
            setState(() => _showCursor = true);
            _focusNode.requestFocus();
            await _animateTyping(prevText, nextText, nextCursor);
          }
        }

        if (isLastFrame) {
          // Switch to Textf widget for clickable link
          setState(() {
            _showCursor = false;
            _showFinalFrame = true;
          });
          await Future<void>.delayed(_loopRestartDelay);
        } else {
          await Future<void>.delayed(_keyframeHoldDuration);
        }
      }
    }
  }

  /// Types the characters that differ between [prev] and [next] one-by-one.
  ///
  /// First animates the cursor from its current position to the insertion
  /// point, then inserts each character with a delay.
  Future<void> _animateTyping(
    String prev,
    String next,
    int finalCursor,
  ) async {
    // Find common prefix
    int prefixLen = 0;
    while (
        prefixLen < prev.length && prefixLen < next.length && prev[prefixLen] == next[prefixLen]) {
      prefixLen++;
    }

    // Find common suffix
    int suffixLen = 0;
    while (suffixLen < prev.length - prefixLen &&
        suffixLen < next.length - prefixLen &&
        prev[prev.length - 1 - suffixLen] == next[next.length - 1 - suffixLen]) {
      suffixLen++;
    }

    final insertEnd = next.length - suffixLen;
    final suffix = suffixLen > 0 ? next.substring(next.length - suffixLen) : '';

    // Animate cursor from current position to insertion point
    await _animateCursorTo(prefixLen);

    // Pause at insertion point before typing
    await Future<void>.delayed(_cursorPositionDelay);

    // Type each inserted character
    for (int j = 1; j <= insertEnd - prefixLen; j++) {
      if (!mounted || !_isAnimating) return;
      final partial = next.substring(0, prefixLen + j) + suffix;
      _setTextAndCursor(partial, prefixLen + j);
      await Future<void>.delayed(_characterTypeDelay);
    }

    // Ensure final state matches the keyframe exactly
    _setTextAndCursor(next, finalCursor);
  }

  /// Animates the cursor from its current position to [targetPos],
  /// stepping one character at a time.
  Future<void> _animateCursorTo(int targetPos) async {
    final currentPos = _controller.selection.baseOffset;
    if (currentPos == targetPos) return;

    final text = _controller.text;
    final step = targetPos > currentPos ? 1 : -1;
    var pos = currentPos;
    while (pos != targetPos) {
      if (!mounted || !_isAnimating) return;
      pos += step;
      _setTextAndCursor(text, pos);
      await Future<void>.delayed(_cursorMoveStepDelay);
    }
  }

  @override
  void dispose() {
    _isAnimating = false;
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (finalText, _) = _parseKeyframe(_animationSteps.last);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: TextfOptions(
        onLinkTap: (url, _) => launchUrl(Uri.parse(url)),
        superscriptStyle: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
        child: _showFinalFrame
            ? SizedBox(width: double.infinity, child: Textf(finalText, style: _style))
            : IgnorePointer(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  readOnly: true,
                  showCursor: _showCursor,
                  cursorColor: Theme.of(context).colorScheme.onSurface,
                  style: _style,
                  maxLines: null,
                  decoration: const InputDecoration.collapsed(hintText: ''),
                ),
              ),
      ),
    );
  }
}
