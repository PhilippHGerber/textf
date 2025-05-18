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
