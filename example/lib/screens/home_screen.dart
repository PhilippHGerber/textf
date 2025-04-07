import 'package:flutter/material.dart';

import '../widgets/selectable_scaffold.dart';
import 'basic_formatting_screen.dart';
import 'chat_example_screen.dart';
import 'complex_formatting_screen.dart';
import 'nested_formatting_screen.dart';
import 'notification_example_screen.dart';
import 'screenshot_screen.dart';
import 'url_example_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectableScaffold(
      appBar: AppBar(
        title: const Text('Textf Examples'),
      ),
      body: ListView(
        children: [
          _buildExampleTile(
            context,
            'Basic Formatting',
            'Simple examples of bold, italic, strikethrough, and code formatting',
            const BasicFormattingScreen(),
          ),
          _buildExampleTile(
            context,
            'Nested Formatting',
            'Examples of nested formatting styles',
            const NestedFormattingScreen(),
          ),
          _buildExampleTile(
            context,
            'Complex Formatting',
            'More advanced text formatting combinations',
            const ComplexFormattingScreen(),
          ),
          _buildExampleTile(
            context,
            'Chat Bubble Example',
            'Example of formatting in a chat bubble',
            const ChatExampleScreen(),
          ),
          _buildExampleTile(
            context,
            'Notification Example',
            'Example of formatting in a notification',
            const NotificationExampleScreen(),
          ),
          _buildExampleTile(
            context,
            'URL Examples',
            'Examples of URL formatting and interaction',
            const UrlExampleScreen(),
          ),
          _buildExampleTile(
            context,
            'Screenshot Generator',
            'Create custom formatted text and take screenshots',
            const ScreenshotScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleTile(BuildContext context, String title, String subtitle, Widget destination) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
      ),
    );
  }
}
