import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

import '../widgets/example_card.dart';

class ChatExampleScreen extends StatelessWidget {
  const ChatExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Bubble Example'),
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ExampleCard(
              title: 'Chat Bubble',
              description: 'Formatted text in a chat bubble',
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
                    constraints: BoxConstraints(maxWidth: 250),
                    child: ChatBubble(
                      isMe: true,
                      message: 'Hey! Did you read that **important** article I sent you about _Flutter performance_?',
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
                  constraints: BoxConstraints(maxWidth: 250),
                  child: ChatBubble(
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
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Full chat example
            const ChatExample(),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Textf(
        message,
        style: const TextStyle(fontSize: 16),
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
      message: 'Hey! Did you read that **important** article I sent you about _Flutter performance_?',
      isMe: true,
    ),
    ChatMessage(
      message: 'Yes! I found the section about **widget rebuilds** particularly _insightful_.',
      isMe: false,
    ),
    ChatMessage(
      message: 'We should apply those techniques to our ~~slow~~ `app`!',
      isMe: false,
    ),
  ];

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isMe = true;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _messages.add(
        ChatMessage(
          message: text,
          isMe: _isMe,
        ),
      );
      _isMe = !_isMe; // Toggle sender for demo purposes
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            reverse: true,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[_messages.length - 1 - index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Align(
                  alignment: message.isMe //
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: ChatBubble(
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
                controller: _textController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Type a message with **bold** and _italic_...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onSubmitted: _handleSubmitted,
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              mini: true,
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  _handleSubmitted(_textController.text);
                }
              },
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }
}

class ChatMessage {
  final String message;
  final bool isMe;

  ChatMessage({
    required this.message,
    required this.isMe,
  });
}
