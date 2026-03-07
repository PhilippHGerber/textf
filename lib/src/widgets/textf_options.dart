import 'package:flutter/material.dart';

import '../core/textf_style_utils.dart';
import 'textf_options_data.dart';

/// An internal InheritedWidget that securely passes the O(1) pre-merged data down the tree.
class _TextfOptionsScope extends InheritedWidget {
  const _TextfOptionsScope({
    required this.data,
    required super.child,
  });

  final TextfOptionsData data;

  @override
  bool updateShouldNotify(_TextfOptionsScope oldWidget) => data != oldWidget.data;
}

/// Configuration options for Textf widgets within a specific scope.
///
/// This widget pre-merges its properties with any ancestor `TextfOptions`
/// when it is built. This guarantees O(1) style resolution for all descendant
/// `Textf` widgets, preventing list-scrolling jank.
///
/// ## Inheritance Logic
/// - **Styles** are merged (Parent styles are kept, but overridden by child properties).
/// - **Callbacks and values** use a "nearest ancestor wins" strategy.
class TextfOptions extends StatelessWidget {
  /// Creates a new TextfOptions instance to provide configuration down the tree.
  /// All properties are optional and will be merged with ancestors if not null.
  const TextfOptions({
    required this.child,
    super.key,
    this.onLinkTap,
    this.onLinkHover,
    this.linkMouseCursor,
    this.linkStyle,
    this.linkAlignment,
    this.linkHoverStyle,
    this.boldStyle,
    this.italicStyle,
    this.boldItalicStyle,
    this.strikethroughStyle,
    this.codeStyle,
    this.strikethroughThickness,
    this.underlineStyle,
    this.highlightStyle,
    this.superscriptStyle,
    this.subscriptStyle,
    this.superscriptBaselineFactor,
    this.subscriptBaselineFactor,
    this.scriptFontSizeFactor,
  });

  /// The child subtree that will have access to the merged TextfOptions configuration.
  final Widget child;

  /// Callback function executed when tapping or clicking on a link.
  /// Provides the resolved `url` and the raw `displayText` including any
  /// original formatting markers (e.g., `**bold link**`).
  final void Function(String url, String displayText)? onLinkTap;

  /// Callback function executed when the mouse pointer enters or exits a link.
  /// Provides the resolved `url`, the raw `displayText`, and the hover state
  /// (`isHovering` is `true` on enter, `false` on exit).
  final void Function(String url, String displayText, {required bool isHovering})? onLinkHover;

  /// The [MouseCursor] to display when hovering over a link.
  final MouseCursor? linkMouseCursor;

  /// Custom alignment for link widgets.
  ///
  /// Defaults to [PlaceholderAlignment.baseline] if not specified.
  final PlaceholderAlignment? linkAlignment;

  /// A specific thickness for the strikethrough line decoration.
  /// This property is **only used if `strikethroughStyle` is `null`**.
  final double? strikethroughThickness;

  /// Custom baseline offset factor for superscript text.
  ///
  /// Determines the vertical offset magnitude relative to the font size.
  /// The value is treated as an absolute offset; superscript is always raised.
  ///
  /// If null, defaults to `DefaultStyles.superscriptBaselineFactor`.
  final double? superscriptBaselineFactor;

  /// Custom baseline offset factor for subscript text.
  ///
  /// Determines the vertical offset magnitude relative to the font size.
  /// The value is treated as an absolute offset; subscript is always lowered.
  ///
  /// If null, defaults to `DefaultStyles.subscriptBaselineFactor`.
  final double? subscriptBaselineFactor;

  /// Custom font size scaling factor for both superscript and subscript text.
  ///
  /// Multiplies the base font size by this factor.
  /// For example, `0.6` means the script text will be 60% the size of the body text.
  ///
  /// If null, defaults to `DefaultStyles.scriptFontSizeFactor` (0.6).
  final double? scriptFontSizeFactor;

  /// The [TextStyle] for link text (`[text](url)`) in its normal (non-hovered) state.
  /// Merged onto the base style if provided.
  final TextStyle? linkStyle;

  /// The [TextStyle] for link text when hovered.
  /// This style is merged on top of the link's final normal style.
  final TextStyle? linkHoverStyle;

  /// The [TextStyle] for bold text (`**bold**` or `__bold__`).
  /// Merged onto the base style if provided.
  final TextStyle? boldStyle;

  /// The [TextStyle] for italic text (`*italic*` or `_italic_`).
  /// Merged onto the base style if provided.
  final TextStyle? italicStyle;

  /// The [TextStyle] for bold and italic text (`***both***` or `___both___`).
  /// Merged onto the base style if provided.
  final TextStyle? boldItalicStyle;

  /// The [TextStyle] for strikethrough text (`~~strike~~`).
  /// Merged onto the base style if provided.
  final TextStyle? strikethroughStyle;

  /// The [TextStyle] for inline code text (`` `code` ``).
  /// Merged onto the base style if provided.
  final TextStyle? codeStyle;

  /// The [TextStyle] for underlined text (`++underline++`).
  /// Merged onto the base style if provided.
  final TextStyle? underlineStyle;

  /// The [TextStyle] for highlighted text (`==highlight==`).
  /// Merged onto the base style if provided.
  final TextStyle? highlightStyle;

  /// The [TextStyle] for superscript text (`^superscript^`).
  /// Merged onto the base style if provided.
  final TextStyle? superscriptStyle;

  /// The [TextStyle] for subscript text (`~subscript~`).
  /// Merged onto the base style if provided.
  final TextStyle? subscriptStyle;

  /// Finds the nearest pre-merged [TextfOptionsData] ancestor in the widget tree.
  static TextfOptionsData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_TextfOptionsScope>()?.data;
  }

  /// Finds the nearest pre-merged [TextfOptionsData] ancestor and establishes a dependency.
  static TextfOptionsData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_TextfOptionsScope>();
    if (scope == null) {
      throw FlutterError(
        'No TextfOptions found in context. To use TextfOptions.of, a TextfOptions widget must be an ancestor of the calling widget.',
      );
    }
    return scope.data;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Fetch the parent's already-merged data in O(1) time
    final parent = maybeOf(context);

    // 2. Pre-merge styles and properties (This happens only once when this widget builds)
    final mergedData = TextfOptionsData(
      // Nearest wins for non-styles
      onLinkTap: onLinkTap ?? parent?.onLinkTap,
      onLinkHover: onLinkHover ?? parent?.onLinkHover,
      linkMouseCursor: linkMouseCursor ?? parent?.linkMouseCursor,
      linkAlignment: linkAlignment ?? parent?.linkAlignment,
      strikethroughThickness: strikethroughThickness ?? parent?.strikethroughThickness,
      superscriptBaselineFactor: superscriptBaselineFactor ?? parent?.superscriptBaselineFactor,
      subscriptBaselineFactor: subscriptBaselineFactor ?? parent?.subscriptBaselineFactor,
      scriptFontSizeFactor: scriptFontSizeFactor ?? parent?.scriptFontSizeFactor,

      // Intelligent merge for styles (Child overrides parent)
      linkStyle: _merge(parent?.linkStyle, linkStyle),
      linkHoverStyle: _merge(parent?.linkHoverStyle, linkHoverStyle),
      boldStyle: _merge(parent?.boldStyle, boldStyle),
      italicStyle: _merge(parent?.italicStyle, italicStyle),
      boldItalicStyle: _merge(parent?.boldItalicStyle, boldItalicStyle),
      strikethroughStyle: _merge(parent?.strikethroughStyle, strikethroughStyle),
      codeStyle: _merge(parent?.codeStyle, codeStyle),
      underlineStyle: _merge(parent?.underlineStyle, underlineStyle),
      highlightStyle: _merge(parent?.highlightStyle, highlightStyle),
      superscriptStyle: _merge(parent?.superscriptStyle, superscriptStyle),
      subscriptStyle: _merge(parent?.subscriptStyle, subscriptStyle),
    );

    // 3. Provide the pre-merged O(1) object down the tree
    return _TextfOptionsScope(
      data: mergedData,
      child: child,
    );
  }

  static TextStyle? _merge(TextStyle? parentStyle, TextStyle? childStyle) {
    if (parentStyle == null) return childStyle;
    if (childStyle == null) return parentStyle;
    return mergeTextStyles(parentStyle, childStyle);
  }
}
