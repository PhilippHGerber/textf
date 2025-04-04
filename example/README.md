# Textf Example App

This example app demonstrates various use cases of the Textf widget, showcasing its formatting capabilities and real-world applications.

## Running the Example

```bash
cd example
flutter pub get
flutter run
```

## What's Included

The example app contains:

- **Basic Formatting** - Bold, italic, strikethrough, and code formatting examples
- **Nested Formatting** - Demonstration of proper nesting with different marker types
- **Complex Formatting** - Unicode support, custom styling, and overflow handling
- **Chat Bubbles** - Interactive chat interface with formatted messages
- **Notifications** - System notification examples with formatted text
- **Screenshot Generator** - Create and capture formatted text with custom styling

## Screenshots

The app includes a screenshot tool to help generate examples for your own documentation.

## Directory Structure

```bash
example/
├── lib/
│   ├── main.dart              # Main application entry
│   ├── screens/               # Example screens
│   │   ├── home_screen.dart   # Main navigation screen
│   │   ├── basic_formatting_screen.dart
│   │   ├── nested_formatting_screen.dart
│   │   ├── complex_formatting_screen.dart
│   │   ├── chat_example_screen.dart
│   │   ├── notification_example_screen.dart
│   │   └── screenshot_screen.dart
│   └── widgets/
│       └── example_card.dart  # Reusable example display widget
└── pubspec.yaml
```

## Creating Screenshot Examples

Use the screenshot tool to create examples for documentation:

1. Navigate to the "Screenshot Generator" screen
2. Enter your formatted text with Markdown-style syntax
3. Customize the appearance using the formatting options
4. Tap "Capture Screenshot" to save the image
