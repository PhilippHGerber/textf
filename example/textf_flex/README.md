# Textf + FlexColorScheme Example App

This example application demonstrates the integration of the `textf` widget with the popular `flex_color_scheme` package, showcasing how `textf`'s theme-aware features adapt to dynamically changing application themes.

## Purpose

* Showcase how `textf` automatically styles links and code blocks based on the active `ThemeData`.
* Demonstrate dynamic theme switching using various `FlexColorScheme` schemes.
* Provide visual examples of different `textf` formatting options within themed cards.
* Illustrate how `TextfOptions` can be used to override theme-based default styles.
* Show various standard Flutter UI elements adapting to the selected theme alongside `textf`.

## Features Demonstrated

* **Dynamic Theme Selection:** Choose from all available `FlexColorScheme` schemes via a dropdown in the AppBar.
* **Theme Mode Switching:** Toggle between Light, Dark, and System theme modes.
* **`textf` Theme Adaptation:** Observe how the default appearance of `[links](url)` (using `colorScheme.primary`) and `` `code` `` (using theme-appropriate background/text colors) changes with the theme.
* **Basic `textf` Formatting:** Examples of **bold**, *italic*, ~~strikethrough~~.
* **`TextfOptions` Overrides:** Examples showing how to customize specific styles (like link color or strikethrough thickness) using `TextfOptions`, taking precedence over the theme defaults.
* **UI Element Theming:** A dedicated card shows various Flutter widgets (Buttons, Chips, Slider, TextField, etc.) adopting the colors from the currently selected `FlexColorScheme` theme.

## Getting Started

1. **Navigate to the example directory:**

    ```bash
    cd example/textf_flex
    ```

2. **Ensure Full Project Structure:**
    Run the following command within the `textf_flex` directory. This ensures all necessary platform-specific directories (`android`, `ios`, `web`, etc.) and files are present, even if they were missing (e.g., after cloning). It will *not* overwrite your existing code in `lib/` or your `pubspec.yaml`.

    ```bash
    flutter create .
    ```

3. **Ensure Dependencies are Installed:**
    Make sure you have the necessary dependencies listed in `pubspec.yaml`, especially `flex_color_scheme` and the local path dependency for `textf`:

    ```yaml
    # example/textf_flex_example/pubspec.yaml
    dependencies:
      flutter:
        sdk: flutter
      flex_color_scheme: ^7.3.1 # Or latest
      textf:
        path: ../../ # Path to the main textf package
    ```

    Then, fetch the packages:

    ```bash
    flutter pub get
    ```

4. **Run the app:**

    ```bash
    flutter run
    ```

## How it Works

* **`main.dart`**: Manages the application's theme state (`selectedScheme`, `themeMode`). It uses `FlexThemeData.light()` and `FlexThemeData.dark()` to generate the `ThemeData` based on the selected scheme and passes the state and update callbacks down to the `HomeScreen`.
* **`home_screen.dart`**: Displays the main UI.
  * The `AppBar` contains the `DropdownButton` for selecting the `FlexScheme` and an `IconButton` to toggle the `ThemeMode`.
  * The body displays a `ListView` of `Card`s.
  * The `_buildExampleCard` helper function creates each card. Crucially, the `Textf` widgets within these cards are instantiated *without* an explicit `style` property, allowing them to inherit the base text style from the `DefaultTextStyle` provided by the theme. This enables the automatic theme adaptation for links and code.
  * Specific examples demonstrate wrapping `Textf` with `TextfOptions` to show how overrides work.

This setup clearly shows how `textf` integrates with Flutter's theming system, especially when using powerful theming packages like `FlexColorScheme`.
