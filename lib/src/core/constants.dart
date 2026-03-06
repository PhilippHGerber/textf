/// Asterisk character * (ASCII code 42)
///
/// Used for bold formatting (**) and italic formatting (*).
const int kAsterisk = 0x2A;

/// Underscore character _ (ASCII code 95)
///
/// Alternative marker for bold formatting (__) and italic formatting (_).
const int kUnderscore = 0x5F;

/// Tilde character ~ (ASCII code 126)
///
/// Used for strikethrough formatting (~~).
const int kTilde = 0x7E;

/// Backtick character ` (ASCII code 96)
///
/// Used for inline code formatting.
const int kBacktick = 0x60;

/// Equals character = (ASCII code 61)
/// Used for highlight formatting (==).
const int kEquals = 0x3D;

/// Caret character ^ (ASCII code 94)
/// Used for superscript formatting (^).
const int kCaret = 0x5E;

/// Plus character + (ASCII code 43)
/// Used for underline formatting (++).
const int kPlus = 0x2B;

/// Escape character \ (ASCII code 92)
///
/// Used to escape formatting characters, preventing them from being interpreted
/// as formatting markers.
const int kEscape = 0x5C;

/// Opening square bracket [ (ASCII code 91)
///
/// Used at the start of a link to denote the link text.
const int kOpenBracket = 0x5B;

/// Closing square bracket ] (ASCII code 93)
///
/// Used at the end of link text.
const int kCloseBracket = 0x5D;

/// Opening parenthesis ( (ASCII code 40)
///
/// Used at the start of a link URL.
const int kOpenParen = 0x28;

/// Closing parenthesis ) (ASCII code 41)
///
/// Used at the end of a link URL.
const int kCloseParen = 0x29;

/// Opening curly brace { (ASCII code 123)
///
/// Used for widget placeholders (e.g., {0}).
const int kOpenBrace = 0x7B;

/// Closing curly brace } (ASCII code 125)
///
/// Used for widget placeholders (e.g., {0}).
const int kCloseBrace = 0x7D;

/// Line Feed / Newline character \n (ASCII code 10)
const int kNewline = 0x0A;

/// Number of tokens in a complete link structure: `[`, text, `](`, url, `)`.
const int kLinkTokenCount = 5;

/// Token offsets within a complete link structure relative to the opening `[`.
///
/// A link is tokenized as: `[`(0), text(1), `](`(2), url(3), `)`(4).
const int kLinkTextOffset = 1;

/// Offset from the opening `[` token to the `](` separator token in a link.
const int kLinkSeparatorOffset = 2;

/// Offset from the opening `[` token to the URL text token in a link.
const int kLinkUrlOffset = 3;

/// Offset from the opening `[` token to the closing `)` token in a link.
const int kLinkEndTokenOffset = 4;

/// Carriage Return character \r (ASCII code 13)
const int kCarriageReturn = 0x0D;
