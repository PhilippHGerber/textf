# Textf Example App

This example app demonstrates various use cases of the Textf widget, showcasing its formatting capabilities and real-world applications.

## Getting Started

1. **Navigate to the example directory:**

    ```bash
    cd example/textf_core
    ```

2. **Ensure Full Project Structure:**
    Run the following command within the `textf_flex` directory. This ensures all necessary platform-specific directories (`android`, `ios`, `web`, etc.) and files are present, even if they were missing (e.g., after cloning). It will *not* overwrite your existing code in `lib/` or your `pubspec.yaml`.

    ```bash
    flutter create .
    ```

3. **Ensure Dependencies are Installed:**

    Fetch the packages:

    ```bash
    flutter pub get
    ```

4. **Run the app:**

    ```bash
    flutter run
    ```

## What's Included

The example app contains:

- **Basic Formatting** - Bold, italic, strikethrough, and code formatting examples
- **Nested Formatting** - Demonstration of proper nesting with different marker types
- **Complex Formatting** - Unicode support, custom styling, and overflow handling
- **Chat Bubbles** - Interactive chat interface with formatted messages
- **Notifications** - System notification examples with formatted text
- **URL Examples** - URL fromatting and callback examples
- **Screenshot Generator** - Create and capture formatted text with custom styling

## Screenshots

The app includes a screenshot tool to help generate examples for your own documentation.

## Directory Structure

```bash
textf_core
├── lib
│   ├── main.dart
│   ├── screens
│   │   ├── basic_formatting_screen.dart
│   │   ├── chat_example_screen.dart
│   │   ├── complex_formatting_screen.dart
│   │   ├── home_screen.dart
│   │   ├── nested_formatting_screen.dart
│   │   ├── notification_example_screen.dart
│   │   ├── screenshot_screen.dart
│   │   ├── theme_example_screen.dart
│   │   └── url_example_screen.dart
│   └── widgets
│       └── example_card.dart
├── README.md
├── analysis_options.yaml
├── assets
│   └── fonts
│       ├── RobotoMono-Italic-VariableFont_wght.ttf
│       └── RobotoMono-VariableFont_wght.ttf
└── pubspec.yaml
```

## Creating Screenshot Examples

Use the screenshot tool to create examples for documentation:

1. Navigate to the "Screenshot Generator" screen
2. Enter your formatted text with Markdown-style syntax
3. Customize the appearance using the formatting options
4. Tap "Capture Screenshot" to save the image
