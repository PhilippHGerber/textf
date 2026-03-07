// ignore_for_file: no-magic-number, avoid-late-keyword

import 'package:flutter/material.dart';
import 'package:textf/textf.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: 'Hey! Did you read that **important** article I sent about _Flutter performance_?',
      isMe: true,
    ),
    _ChatMessage(
      text: 'Yes! The section about **widget rebuilds** was _insightful_.',
      isMe: false,
    ),
    _ChatMessage(
      text: 'We should apply those to our ~~slow~~ `app`! ++Check the docs++ too.',
      isMe: false,
    ),
    _ChatMessage(
      text:
          'Also see the [textf package](https://pub.dev/packages/textf) for ==rich text== in chat!',
      isMe: true,
    ),
  ];

  late final TextfEditingController _inputController;
  final FocusNode _focusNode = FocusNode();
  bool _isMe = true;

  @override
  void initState() {
    super.initState();
    _inputController = TextfEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.insert(0, _ChatMessage(text: text, isMe: _isMe));
      _isMe = !_isMe;
      _inputController.clear();
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            'Messages rendered with Textf · Input uses TextfEditingController',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: TextfOptions(
            onLinkTap: (url, _) => _launchUrl(url),
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: _Bubble(message: msg),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Type **formatted** message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _send,
                icon: const Icon(Icons.send_rounded),
                tooltip: 'Send',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMe = message.isMe;
    final bg = isMe ? cs.primaryContainer : cs.surfaceContainerHighest;
    final fg = isMe ? cs.onPrimaryContainer : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
      ),
      child: Textf(message.text, style: TextStyle(color: fg)),
    );
  }
}

class _ChatMessage {
  _ChatMessage({required this.text, required this.isMe});

  final String text;
  final bool isMe;
}
