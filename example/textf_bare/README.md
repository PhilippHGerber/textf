# Textf in a bare `WidgetsApp`

A workspace-only example (not published) showing `textf` 2.0 with no design system at all: the
app depends only on `flutter` and `textf`, imports only `package:flutter/widgets.dart`, and has no
`Theme`, `MaterialApp` or `CupertinoApp`.

## What it shows

- **Typography from `DefaultTextStyle`.** `WidgetsApp.textStyle` sets the font size, line height
  and text color. Every `Textf` builds on that style.
- **Neutral defaults.** Code chips, highlights and the `---` rule derive from the ambient text
  color. When the dark-mode toggle switches to light text, the code chip changes from 5 % to 15 %
  of the text color with no extra code.
- **One color option.** `TextfOptions(linkColor: brandColor)` colors links and keeps their
  underline.

## Running

```bash
cd example/textf_bare
flutter test                          # smoke test, color checks, and a widgets-only import check
flutter create --platforms=web .      # this package ships without platform folders
flutter run -d chrome
```

`textf` resolves from the repository root through the pub workspace declared in the root
`pubspec_overrides.yaml`.
