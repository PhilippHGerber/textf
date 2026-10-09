# Textf + FlexColorScheme on `material_ui`

A workspace-only example (not published) showing how `textf` 2.0 picks up brand colors in an app
built on [`material_ui`](https://pub.dev/packages/material_ui) `^1.0.0` and
[`flex_color_scheme`](https://pub.dev/packages/flex_color_scheme) `^9.0.0`.

## Why a recipe is needed

`textf` is design-system-neutral: it never calls `Theme.of`, so it works the same under SDK
Material, `material_ui`, Cupertino and a bare `WidgetsApp`. Out of the box, links are
`#1A73E8` and code chips are a light tint of the text color. To use your theme's colors instead,
pass them to `TextfOptions` once, in `MaterialApp.builder`:

```dart
MaterialApp(
  theme: FlexThemeData.light(scheme: FlexScheme.material),
  darkTheme: FlexThemeData.dark(scheme: FlexScheme.material),
  builder: (context, child) {
    final theme = Theme.of(context);
    return TextfOptions(
      linkColor: theme.colorScheme.primary,
      codeBackgroundColor: theme.colorScheme.surfaceContainer,
      highlightColor: theme.colorScheme.tertiaryContainer,
      thematicBreakColor: theme.dividerColor,
      child: child ?? const SizedBox.shrink(),
    );
  },
  home: const HomeScreen(),
);
```

`builder` runs below the theme, so every descendant `Textf` follows scheme and light/dark changes.
Color options only tint the built-in defaults: links keep their underline and code keeps its
monospace font stack.

Import `package:material_ui/material_ui.dart` (not `package:flutter/material.dart`) in every file
that touches `Theme`, `ThemeData` or `ThemeMode`, and list `material_ui` as a direct dependency.
`flex_color_scheme` 9 returns `material_ui`'s `ThemeData`, which is a different type from the SDK's.

## What the app shows

- A scheme picker (every `FlexScheme`) and a light / dark / system toggle in the app bar.
- A "Brand Colors" card rendering a link, inline code, a highlight and a `---` rule with the colors
  from the recipe.
- Cards for basic formatting, links, and a `TextfOptions.linkStyle` override (a style option
  replaces the default, so it wins over `linkColor`).

## Running

```bash
cd example/textf_flex
flutter run
flutter test   # T-MIG-01: the recipe renders brand colors and follows theme-mode switches
```

The package resolves `textf` from the repository root through the pub workspace declared in the
root `pubspec_overrides.yaml`.
