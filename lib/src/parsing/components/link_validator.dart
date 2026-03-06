import '../../core/constants.dart';
import '../../core/formatting_utils.dart' show FormattingUtils;
import '../../editing/textf_span_builder.dart' show TextfSpanBuilder;
import '../../models/textf_token.dart';
import 'link_handler.dart' show LinkHandler;

/// Shared utility for validating the 5-token link structure `[text](url)`.
///
/// Extracted from the formerly independent `_isCompleteLink` helpers in
/// [LinkHandler], [TextfSpanBuilder], and [FormattingUtils] to ensure all
/// paths apply the same validation rule. Any future change to link syntax
/// only needs to be made here.
class LinkValidator {
  LinkValidator._();

  /// Returns `true` if the tokens starting at [index] form a complete
  /// `[text](url)` link structure.
  ///
  /// A complete link requires exactly 5 consecutive tokens:
  /// - `tokens[index]`     : `LinkStartToken`  — the opening `[`
  /// - `tokens[index + 1]` : `TextToken`        — link text (may be empty)
  /// - `tokens[index + 2]` : `LinkSeparatorToken` — the `](`
  /// - `tokens[index + 3]` : `TextToken`        — URL text (may be empty)
  /// - `tokens[index + 4]` : `LinkEndToken`     — the closing `)`
  static bool isCompleteLink(List<TextfToken> tokens, int index) {
    if (index + kLinkEndTokenOffset >= tokens.length) return false;

    return tokens[index] is LinkStartToken &&
        tokens[index + kLinkTextOffset] is TextToken &&
        tokens[index + kLinkSeparatorOffset] is LinkSeparatorToken &&
        tokens[index + kLinkUrlOffset] is TextToken &&
        tokens[index + kLinkEndTokenOffset] is LinkEndToken;
  }
}
