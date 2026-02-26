// ignore_for_file: no-magic-number

// example/lib/screens/editing_controller_screen.dart
import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

class EditingControllerScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final VoidCallback toggleThemeMode;

  const EditingControllerScreen({
    super.key,
    required this.currentThemeMode,
    required this.toggleThemeMode,
  });

  @override
  State<EditingControllerScreen> createState() => _EditingControllerScreenState();
}

class _EditingControllerScreenState extends State<EditingControllerScreen>
    with SingleTickerProviderStateMixin {
  late final TextfEditingController _controller;
  late final TextfEditingController _chatController;
  late final AnimationController _markerAnim;
  final List<String> _chatMessages = [];
  MarkerVisibility _visibility = MarkerVisibility.whenActive;

  @override
  void initState() {
    super.initState();
    _controller = TextfEditingController(
        //text: 'Try **bold**, *italic*, `code`, and ~~strike~~!',
        );
    _chatController = TextfEditingController();
    _markerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
      value: 1,
    );
    _markerAnim.addListener(_onMarkerAnimTick);
    _controller.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    _markerAnim
      ..removeListener(_onMarkerAnimTick)
      ..dispose();
    _controller
      ..removeListener(_onSelectionChanged)
      ..dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _onMarkerAnimTick() {
    _controller
      ..markerOpacity = _markerAnim.value
      ..invalidate();
  }

  void _onSelectionChanged() {
    if (_visibility == MarkerVisibility.whenActive) {
      // Always keep animation at target — the span builder handles
      // per-span cursor checks internally.
      if (_markerAnim.status != AnimationStatus.forward) {
        setState(() {});
      }
    }
  }

  void _setVisibility(MarkerVisibility visibility) {
    setState(() {
      _visibility = visibility;
      _controller.markerVisibility = visibility;
      if (visibility == MarkerVisibility.always) {
        _markerAnim.forward();
      } else {
        _markerAnim.reverse();
      }
    });
  }

  void _insertText(String insertText) {
    final text = _controller.text;
    final selection = _controller.selection;

    final int start;
    final int end;
    if (selection.isValid && !selection.isCollapsed) {
      start = selection.start;
      end = selection.end;
    } else if (selection.isValid) {
      start = selection.baseOffset;
      end = start;
    } else {
      start = text.length;
      end = start;
    }

    // ignore: avoid-substring
    final newText = text.substring(0, start) + insertText + text.substring(end);
    _controller
      ..text = newText
      ..selection = TextSelection.collapsed(
        offset: start + insertText.length,
      );
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _chatMessages.add(text);
      _chatController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final themeIcon =
        brightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;

    return Scaffold(
      appBar: AppBar(
        title: const Textf('Textf ^_1.2.0-dev.1_^'),
        actions: [
          IconButton(
            icon: Icon(themeIcon),
            tooltip: 'Toggle Theme',
            onPressed: widget.toggleThemeMode,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Section 1: Basic Demo ---
          _SectionHeader(title: 'Live Formatting Preview', theme: theme),
          const SizedBox(height: 8),
          Textf(
            'New `Text==f==EditingController`:',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Textf(
            'TextField with real-time marker rendering as you type.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Type formatted text here...',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLowest,
            ),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),

          // // Marker visibility toggle
          // _MarkerVisibilityToggle(
          //   visibility: _visibility,
          //   onChanged: _setVisibility,
          //   theme: theme,
          // ),
          const SizedBox(height: 8),

          // Clickable format chips
          _FormatChips(
            onInsert: _insertText,
            theme: theme,
          ),

          const SizedBox(height: 32),

          // Marker visibility toggle
          _MarkerVisibilityToggle(
            visibility: _visibility,
            onChanged: _setVisibility,
            theme: theme,
          ),

          const SizedBox(height: 32),
          // --- Section 2: Custom Styled ---
          _SectionHeader(
            title: 'Custom Styles via TextfOptions',
            theme: theme,
          ),
          const SizedBox(height: 8),
          Text(
            'Wrap any TextField in TextfOptions to customize formatting '
            'appearance.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextfOptions(
            boldStyle: TextStyle(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
            italicStyle: TextStyle(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.tertiary,
            ),
            codeStyle: TextStyle(
              fontFamily: 'RobotoMono',
              backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              color: theme.colorScheme.primary,
            ),
            highlightStyle: TextStyle(
              backgroundColor: Colors.amber.withValues(alpha: 0.4),
            ),
            child: TextField(
              controller: TextfEditingController(
                text: '**Primary bold** with *tertiary italic* and '
                    '`styled code`',
              ),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Custom styled',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
              ),
              style: theme.textTheme.bodyLarge,
            ),
          ),

          const SizedBox(height: 32),

          // --- Section 3: TextFormField ---
          _SectionHeader(title: 'TextFormField Integration', theme: theme),
          const SizedBox(height: 8),
          Text(
            'Works seamlessly with TextFormField for form validation.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: TextfEditingController(
              text: 'A **required** field with *formatted* hints',
            ),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Bio',
              helperText: 'Supports bold, italic, code, and more',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLowest,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            style: theme.textTheme.bodyLarge,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your bio';
              }
              return null;
            },
          ),

          const SizedBox(height: 32),

          // --- Section 4: Chat-like demo ---
          _SectionHeader(title: 'Chat Composer', theme: theme),
          const SizedBox(height: 8),
          Text(
            'A chat-like input that renders formatting as you type.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _ChatDemo(
            controller: _chatController,
            messages: _chatMessages,
            onSend: _sendMessage,
            theme: theme,
          ),

          const SizedBox(height: 32),

          // --- Section 5: Side by side comparison ---
          _SectionHeader(title: 'Side-by-Side Comparison', theme: theme),
          const SizedBox(height: 8),
          Text(
            'Same text rendered in TextField (editable) vs Textf (read-only).',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _SideBySideComparison(theme: theme),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _MarkerVisibilityToggle extends StatelessWidget {
  final MarkerVisibility visibility;
  final ValueChanged<MarkerVisibility> onChanged;
  final ThemeData theme;

  const _MarkerVisibilityToggle({
    required this.visibility,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MarkerVisibility>(
      segments: const [
        ButtonSegment(
          value: MarkerVisibility.always,
          label: Text('Markers visible'),
          icon: Icon(Icons.visibility_outlined),
        ),
        ButtonSegment(
          value: MarkerVisibility.whenActive,
          label: Text('Smart hide'),
          icon: Icon(Icons.visibility_off_outlined),
        ),
      ],
      selected: {visibility},
      onSelectionChanged: (selected) => onChanged(selected.first),
      showSelectedIcon: false,
    );
  }
}

class _FormatChips extends StatelessWidget {
  final ValueChanged<String> onInsert;
  final ThemeData theme;

  const _FormatChips({required this.onInsert, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _chip('**bold**'),
          _chip('*italic*'),
          _chip('~~strike~~'),
          _chip('++underline++'),
          _chip('==highlight=='),
          _chip('`code`'),
          // _chip('^super^'),
          // _chip('~sub~'),
          _chip('[link](https://example.com)'),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 11),
      ),
      onPressed: () => onInsert(label),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _ChatDemo extends StatelessWidget {
  final TextfEditingController controller;
  final List<String> messages;
  final VoidCallback onSend;
  final ThemeData theme;

  const _ChatDemo({
    required this.controller,
    required this.messages,
    required this.onSend,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Messages area
          Container(
            height: 200,
            padding: const EdgeInsets.all(12),
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'Type a formatted message and tap send',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[messages.length - 1 - index];
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8, left: 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(4),
                            ),
                          ),
                          child: Textf(
                            msg,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Input area
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a **formatted** message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                IconButton.filled(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideBySideComparison extends StatefulWidget {
  final ThemeData theme;

  const _SideBySideComparison({required this.theme});

  @override
  State<_SideBySideComparison> createState() => _SideBySideComparisonState();
}

class _SideBySideComparisonState extends State<_SideBySideComparison> {
  late final TextfEditingController _comparisonController;

  @override
  void initState() {
    super.initState();
    _comparisonController = TextfEditingController(
      text: 'Hello **bold** and *italic* `code` world!',
    );
    _comparisonController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _comparisonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Column(
      children: [
        TextField(
          controller: _comparisonController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Editable (TextField)',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
          ),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Read-only (Textf)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Textf(
                _comparisonController.text,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
