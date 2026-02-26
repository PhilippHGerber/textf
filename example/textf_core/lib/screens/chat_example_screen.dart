import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '../widgets/example_card.dart';

class ChatExampleScreen extends StatelessWidget {
  // Add theme constructor parameters
  final ThemeMode currentThemeMode;
  final VoidCallback toggleThemeMode;

  const ChatExampleScreen({
    super.key,
    required this.currentThemeMode,
    required this.toggleThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    // Add theme icon logic
    final Brightness currentBrightness = Theme.of(context).brightness;
    final IconData themeIcon =
        currentBrightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Bubble Example'),
        actions: [
          // Add actions here
          IconButton(
            icon: Icon(themeIcon),
            tooltip: 'Toggle Theme',
            onPressed: toggleThemeMode,
          ),
        ],
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ExampleCard(
              // No need to pass theme info to ExampleCard directly
              title: 'Chat Bubble',
              description:
                  'Formatted text in a chat bubble using theme colors', // Updated description
              code: '''Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.blue.shade100,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Textf(
    'Hey! Did you read that **important** article '
    'I sent you about _Flutter performance_?',
    style: TextStyle(fontSize: 16),
  ),
)''',
              child: SizedBox(
                width: double.infinity,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: const ChatBubble(
                      // Use const if no params change
                      isMe: true,
                      message:
                          'Hey! Did you read that **important** article I sent you about _Flutter performance_?',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 250),
                  child: const ChatBubble(
                    // Use const
                    isMe: false,
                    message:
                        'Yes! I found the section about **widget rebuilds** particularly _insightful_. We should apply those techniques to our ~~slow~~ `app`!',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Interactive Chat Example',
              style: Theme.of(context).textTheme.titleLarge, // Use theme style
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Full chat example
            const ChatExample(), // Use const
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final bool isMe;
  final String message;

  const ChatBubble({
    super.key,
    required this.isMe,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme
    // Use theme colors for bubbles
    final bubbleColor =
        isMe ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest;
    // Determine appropriate text color based on bubble color for contrast
    final textColor = isMe
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant; // Or onSurface

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjusted padding
      decoration: BoxDecoration(
        color: bubbleColor, // Use theme color
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isMe ? 12 : 0),
          bottomRight: Radius.circular(isMe ? 0 : 12),
        ),
      ),
      child: Textf(
        message,
        // Set explicit text color for contrast
        style: TextStyle(fontSize: 16, color: textColor),
      ),
    );
  }
}

class ChatExample extends StatefulWidget {
  const ChatExample({super.key});

  @override
  State<ChatExample> createState() => _ChatExampleState();
}

class _ChatExampleState extends State<ChatExample> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      message:
          'Hey! Did you read that **important** article I sent you about _Flutter performance_?',
      isMe: true,
    ),
    ChatMessage(
      message: 'Yes! I found the section about **widget rebuilds** particularly _insightful_.',
      isMe: false,
    ),
    ChatMessage(
      message:
          'We should apply those techniques to our ~~slow~~ `app`! ++Remember to check the docs++.',
      isMe: false,
    ),
    ChatMessage(
      message:
          'Also check out the default [link](https://flutter.dev) and `code` styling, ++underline++ and ==highlighting==.',
      isMe: true,
    ),
  ];

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isMe = true; // Keep toggling for demo

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return; // Don't add empty messages
    _textController.clear();
    setState(() {
      _messages.insert(
        0, // Insert at the beginning for reverse list view
        ChatMessage(
          message: text,
          isMe: _isMe,
        ),
      );
      _isMe = !_isMe; // Toggle sender for demo purposes
    });
    // Delay focus request slightly if needed
    // Future.delayed(Duration(milliseconds: 50), () => _focusNode.requestFocus());
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme

    return Column(
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
            // Use theme color for list background
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: .5)),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            reverse: true, // Keep reverse order
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              // Access messages directly in reverse order for clarity
              final message = _messages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Align(
                  alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: ChatBubble(
                      // ChatBubble now handles its own theme colors
                      isMe: message.isMe,
                      message: message.message,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                // TextField adapts to theme automatically
                controller: _textController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Type message (**bold**, _italic_, `code`, [link](url))...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      // Use theme color for border
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    // Border when not focused
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: .7),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    // Border when focused
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary, // Highlight with primary color
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10, // Adjusted padding
                  ),
                  isDense: true, // Make it more compact
                ),
                onSubmitted: _handleSubmitted,
                textInputAction: TextInputAction.send, // Action button on keyboard
                onTapOutside: (event) {
                  // Dismiss keyboard on tap outside
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            const SizedBox(width: 8),
            // Consider using IconButton for sending for better alignment/theming
            IconButton.filled(
              // Use filled tonal for less emphasis than primary filled
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
              ),
              tooltip: 'Send',
              icon: const Icon(Icons.send),
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  _handleSubmitted(_textController.text);
                }
              },
            ),
            // FloatingActionButton(
            //   mini: true,
            //   onPressed: () {
            //     if (_textController.text.isNotEmpty) {
            //       _handleSubmitted(_textController.text);
            //     }
            //   },
            //   child: const Icon(Icons.send),
            // ),
          ],
        ),
      ],
    );
  }
}

// ChatMessage class remains the same
class ChatMessage {
  final String message;
  final bool isMe;

  ChatMessage({
    required this.message,
    required this.isMe,
  });
}
