# Textf on Cupertino

A workspace-only example (not published) showing `textf` 2.0 in a Cupertino app, on the
standalone [`cupertino_ui`](https://pub.dev/packages/cupertino_ui) `^1.0.0` package and on the
SDK's `package:flutter/cupertino.dart`.

## The recipe

`textf` never reads `CupertinoTheme` (or any other theme). To use your Cupertino colors, pass them
to `TextfOptions` once, in `CupertinoApp.builder`:

```dart
CupertinoApp(
  theme: const CupertinoThemeData(primaryColor: CupertinoColors.systemIndigo),
  builder: (context, child) {
    return TextfOptions(
      linkColor: CupertinoTheme.of(context).primaryColor,
      codeBackgroundColor: CupertinoColors.tertiarySystemFill.resolveFrom(context),
      highlightColor: CupertinoColors.systemYellow.resolveFrom(context).withValues(alpha: 0.35),
      thematicBreakColor: CupertinoColors.separator.resolveFrom(context),
      child: child ?? const SizedBox.shrink(),
    );
  },
  home: const HomePage(),
);
```

`builder` runs below the theme, so `CupertinoTheme.of` and `resolveFrom` return the light or dark
variant and every descendant `Textf` follows brightness changes. The same source compiles against
`package:cupertino_ui/cupertino_ui.dart` and `package:flutter/cupertino.dart`: `TextfOptions` only
takes `Color`s, which both share.

## Files

- `lib/main.dart`: the `cupertino_ui` app (`CupertinoPageScaffold`, a dark-mode switch, and a
  `CupertinoTextField` driven by `TextfEditingController`).
- `test/cupertino_recipe_test.dart`: checks that the app renders the recipe colors and follows a
  brightness switch.

## Running

```bash
cd example/textf_cupertino
flutter test
flutter create --platforms=ios,macos .   # platform folders are not checked in
flutter run
```

`textf` resolves from the repository root through the pub workspace declared in the root
`pubspec_overrides.yaml`.
