/// A simple example demonstrating the core features of the Textf package.
///
/// This example shows:
/// - Basic text formatting without configuration
/// - Custom styling with TextfOptions
/// - Interactive links with hover effects
library;

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Textf Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Textf Examples'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Example 1: Basic usage with default styling
            const Text('Example 1: Basic Usage', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Textf supports markdown-like syntax out of the box
            const Textf('This is **bold** text and this is *italic*.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),

            // Strikethrough and inline code formatting
            const Textf('Text with ~~strikethrough~~ and `inline code`.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),

            // Additional formatting options
            const Textf('Also supports ++underline++ and ==highlight==!', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),

            // Links are rendered with theme colors by default
            const Textf('A [link to Flutter](https://flutter.dev) in text.', style: TextStyle(fontSize: 16)),

            const SizedBox(height: 32),

            // Example 2: Custom styling with TextfOptions
            const Text(
              'Example 2: Custom Styling with TextfOptions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // TextfOptions allows customization of formatting styles
            TextfOptions(
              // Make bold text red and extra bold
              boldStyle: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red),

              // Add background to inline code
              codeStyle: TextStyle(backgroundColor: Colors.green.shade200, fontStyle: FontStyle.italic),

              // Style links: blue without underline
              urlStyle: const TextStyle(color: Colors.blue, decoration: TextDecoration.none),

              // Add underline on hover
              urlHoverStyle: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
                decorationColor: Colors.blue,
              ),

              // Handle link clicks
              onUrlTap: (url, displayText) {
                debugPrint('Link clicked: $displayText -> $url');
              },

              // Handle hover state changes
              onUrlHover: (url, displayText, {required bool isHovering}) {
                debugPrint('Hovering over "$displayText": $isHovering');
              },

              // All Textf widgets inside this will use these custom styles
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Textf('**Red bold text** with normal text.', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Textf('Code has `green background` with italic style.', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Textf(
                    'Links are [blue without underline](https://example.com) - '
                    'they get underlined on hover.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
