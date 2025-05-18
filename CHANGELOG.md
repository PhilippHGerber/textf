# Changelog

All notable changes to the `textf` package will be documented in this file.

## 0.4.0

2025-05-18

### Added

- **Underline Formatting:** Implemented support for underline formatting with `++text++` syntax.

- **Highlight Formatting:** Implemented support for highlight formatting with `==text==` syntax.

- **Improved Decoration Handling:** Default styles for strikethrough and underline now attempt to combine with existing decorations on the base style, allowing for concurrent `++~~underline and strikethrough~~++`. `decorationColor` and `decorationThickness` from the most recently applied default decoration or `TextfOptions` will take precedence for the combined decoration.

### Changed

- **TextfOptions:** Extended with `underlineStyle` and `highlightStyle` properties.
- **Link Formatting:**
  - Nested text decorations within link display text (e.g., `[~~strikethrough~~](url)`) are now correctly combined with the link's own decoration (e.g., underline), ensuring both are visually applied.
  - Improved application of `TextfOptions.urlHoverStyle`, ensuring hover-specific styles correctly merge with the link's resolved normal appearance, preserving properties like color and font size unless explicitly overridden by the hover style.
- **Internal Refactoring:** Enhanced `TokenType` enum to directly indicate if a token is for links or formatting. This improves internal parsing logic in `PairingResolver` and `TextfParser` for minor performance gains and better code clarity. (Thanks @timmaffett!)

## 0.3.0

2025-04-18

### Added

- **Theme-Aware Default Styling:** Implemented theme-aware default styling for inline code (`` `code` ``) and links (`[text](url)`). Their appearance now automatically adapts to the application's `ThemeData` (e.g., using `colorScheme.primary` for links, theme-appropriate background/text for code) unless overridden by `TextfOptions`.
- **`strikethroughThickness` Option:** Added the `strikethroughThickness` property to `TextfOptions` to allow customizing the line thickness for `~~strikethrough~~` text when not providing a full `strikethroughStyle`.
- **`TextScaler` Support:** Added support for the `textScaler` property, allowing `Textf` to respect system font scaling settings and custom `TextScaler` instances, similar to the standard `Text` widget.

### Changed

- **Documentation:** Significantly enhanced `README.md` with detailed explanations of all `TextfOptions` properties, their inheritance behavior, and added styling recommendations.
- **Code Font Defaults:** Improved default font family fallbacks for inline code (`code`) for better cross-platform rendering when a specific `codeStyle` is not provided (uses `RobotoMono`, `Menlo`, `Courier New`, `monospace`).

### Removed

- **Internal Caching:** Removed the internal caching mechanism for parsed results to simplify the parsing logic and resolve potential inconsistencies during hot reload. Performance remains optimized through efficient algorithms.

### Fixed

- **Internal:** Updated internal tests to correctly account for the new theme-aware default styles.

## 0.2.1

2025-04-12

### Fixed

- **Hot Reload Reliability:** Fixed an issue where changes made to `TextfOptions` (e.g., custom colors, styles) or internal formatting logic might not render correctly immediately after using hot reload during development. The internal parser cache is now properly invalidated only in debug mode during `reassemble`, ensuring UI consistency and improving the development workflow without affecting release build performance.

## 0.2.0

2025-04-12

### Added

- **Link Support**: Implemented full support for Markdown-style links with `[text](url)` syntax
  - Added interactive link styling with customizable colors and decorations
  - Created hover effects for links with mouse cursor changes
  - Enabled nested formatting within link text (e.g., `[**bold** link](url)`)
  - Added `onUrlTap` and `onUrlHover` callbacks for link interaction

- **TextfOptions**: Introduced a new widget to customize text formatting styles
  - Global styling options for all formatting types (bold, italic, code, etc.)
  - Configurable link appearance and behavior
  - Inheritance-based configuration through the widget tree

- **Enhanced Styling**: Added support for more detailed text styling
  - Font family customization for code blocks
  - Expanded default styles for each formatting type

### Fixed

- Updated default font family for inline code text to RobotoMono for better readability
- Enabled trailing commas in analysis options for code consistency

## 0.1.1

2025-04-05

### Changed

- Updated pubspec.yaml with simpler description to meet pub.dev guidelines
- Added publisher information to pubspec.yaml
- Removed example directory from .pubignore for better documentation

### Fixed

- Formatted code for tests to meet Dart style guidelines

## 0.1.0

2025-04-04

### Added

- Initial release of Textf lightweight text formatting widget
- Support for bold formatting with `**text**` or `__text__`
- Support for italic formatting with `*text*` or `_text_`
- Support for combined bold+italic with `***text***` or `___text___`
- Support for strikethrough with `~~text~~`
- Support for inline code with `` `code` ``
- Escape character support with backslash
- Performance optimization with caching
- Nested formatting support (up to 2 levels deep)

## 0.0.1

- Initial release of Textf widget.
