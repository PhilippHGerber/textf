# Changelog

All notable changes to the `textf` package will be documented in this file.

## 0.2.0 - 2025-04-12

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

## 0.1.1 - 2025-04-05

### Changed

- Updated pubspec.yaml with simpler description to meet pub.dev guidelines
- Added publisher information to pubspec.yaml
- Removed example directory from .pubignore for better documentation

### Fixed

- Formatted code for tests to meet Dart style guidelines

## 0.1.0 - 2025-04-04

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
