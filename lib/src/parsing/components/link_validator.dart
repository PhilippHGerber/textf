import '../../core/constants.dart';
import '../../core/formatting_utils.dart' show FormattingUtils;
import '../../models/parsed_link.dart';
import '../../models/textf_token.dart';
import 'link_handler.dart' show LinkHandler;

/// Shared utility for validating the 5-token link structure `[text](url)`.
///
/// Sole factory for [ParsedLink]. Extracted from the formerly independent
/// link helpers in [LinkHandler], `TextfSpanBuilder`, and [FormattingUtils] to
/// ensure all paths apply the same validation rule. Any future change to link syntax
/// only needs to be made here.
class LinkValidator {
  new _();

  static const int _linkTextOffset = 1;
  static const int _linkSeparatorOffset = 2;
  static const int _linkUrlOffset = 3;
  static const int _linkEndOffset = 4;

  /// Validates whether the tokens starting at [index] form a complete
  /// `[text](url)` link structure.
  ///
  /// A complete link requires exactly 5 consecutive tokens:
  /// - `tokens[index]`     : `LinkStartToken`     — the opening `[`
  /// - `tokens[index + 1]` : `TextToken`          — link text (may be empty)
  /// - `tokens[index + 2]` : `LinkSeparatorToken` — the `](`
  /// - `tokens[index + 3]` : `TextToken`          — URL text (may be empty)
  /// - `tokens[index + 4]` : `LinkEndToken`       — the closing `)`
  ///
  /// Returns a [ParsedLink] on success, or `null` if the tokens do not form
  /// a valid link structure.
  static ParsedLink? validate(List<TextfToken> tokens, int index) {
    if (index < 0 || index + kLinkTokenCount > tokens.length) {
      return null;
    }

    if ((
          tokens[index],
          tokens[index + _linkTextOffset],
          tokens[index + _linkSeparatorOffset],
          tokens[index + _linkUrlOffset],
          tokens[index + _linkEndOffset],
        )
        case (
          final LinkStartToken start,
          final TextToken text,
          LinkSeparatorToken(),
          final TextToken url,
          final LinkEndToken end,
        )) {
      return ParsedLink(
        displayText: text.value,
        url: url.value,
        startPosition: start.position,
        endPosition: end.position + end.length,
      );
    }

    return null;
  }
}
