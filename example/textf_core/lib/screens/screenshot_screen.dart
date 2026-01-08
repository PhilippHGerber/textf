// example/lib/screens/screenshot_screen.dart
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'; // Import kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:textf/textf.dart'; // Import TextfOptions

// Helper extension for cleaner null checks (optional)
extension TextStyleCopyWithExtension on TextStyle? {
  TextStyle copyWithNullable({
    bool? inherit,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    List<FontVariation>? fontVariations,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    String? debugLabel,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    String? package,
    TextOverflow? overflow,
  }) {
    // If the current style is null, start with an empty TextStyle
    final currentStyle = this ?? const TextStyle();
    return currentStyle.copyWith(
      inherit: inherit,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      fontVariations: fontVariations,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      debugLabel: debugLabel,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      package: package,
      overflow: overflow,
    );
  }
}

class ScreenshotScreen extends StatefulWidget {
  // Add theme parameters
  final ThemeMode currentThemeMode;
  final VoidCallback toggleThemeMode;

  const ScreenshotScreen({
    super.key,
    required this.currentThemeMode,
    required this.toggleThemeMode,
  });

  @override
  State<ScreenshotScreen> createState() => _ScreenshotScreenState();
}

class _ScreenshotScreenState extends State<ScreenshotScreen> {
  final TextEditingController _textController = TextEditingController(
    text:
        'Hello **bold** *italic* ~~strikethrought~~ ++underline++ ==highlight== \n'
        '`code` \n'
        'E = mc^2^ and H~2~O \n'
        '[link](https://example.com)',
  );
  final GlobalKey _screenshotKey = GlobalKey();

  // --- Base Styling State (Applied via DefaultTextStyle or Container) ---
  double _fontSize = 16;
  Color? _textColor; // Nullable: applied via DefaultTextStyle
  Color? _backgroundColor; // Nullable: applied via Container
  TextAlign _textAlign = TextAlign.left;
  double _textScaleFactor = 1.0;

  // --- TextfOptions State (Nullable to allow falling back to theme/defaults) ---
  TextStyle? _boldStyle;
  TextStyle? _italicStyle;
  TextStyle? _boldItalicStyle;
  TextStyle? _strikethroughStyle;
  TextStyle? _codeStyle;
  TextStyle? _urlStyle;
  TextStyle? _urlHoverStyle;
  MouseCursor? _urlMouseCursor;
  TextStyle? _underlineStyle;
  TextStyle? _highlightStyle;

  // --- Capture State ---
  bool _isCapturing = false;
  ui.Image? _capturedImage;
  Uint8List? _imageBytes;

  // --- Available Colors (Example lists) ---
  final List<Color> _availableColors = [
    Colors.black, Colors.white, Colors.grey.shade700, Colors.grey.shade200, // Basic
    Colors.blue.shade700, Colors.blue.shade100, // Blue tones
    Colors.red.shade700, Colors.red.shade100, // Red tones
    Colors.green.shade700, Colors.green.shade100, // Green tones
    Colors.purple.shade700, Colors.purple.shade100, // Purple tones
    Colors.orange.shade700, Colors.orange.shade100, // Orange tones
    Colors.teal.shade700, Colors.teal.shade100, // Teal tones
    Colors.yellow.shade800, Colors.yellow.shade100, // Yellow tones
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // --- Capture/Copy/Share methods remain the same ---
  Future<void> _captureScreenshot() async {
    if (!mounted) return;
    setState(() => _isCapturing = true);

    try {
      // Short delay to ensure UI with potential TextfOptions changes is rendered
      await Future.delayed(const Duration(milliseconds: 150));

      RenderRepaintBoundary? boundary =
          _screenshotKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (kDebugMode) {
          print("Error: Could not find RenderRepaintBoundary.");
        }
        throw Exception("Render boundary not found");
      }

      if (!mounted) return;
      ui.Image image = await boundary.toImage(pixelRatio: MediaQuery.of(context).devicePixelRatio);

      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      _imageBytes = byteData?.buffer.asUint8List();

      if (!mounted) return; // Check again after async gaps
      setState(() {
        _capturedImage = image;
        _isCapturing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Screenshot captured! Long-press image to copy/share.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Screenshot capture failed: $e");
      }
      if (!mounted) return;
      setState(() => _isCapturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture screenshot: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyImageToClipboard() async {
    if (_imageBytes == null) return;
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        throw Exception("Clipboard instance is not available.");
      }
      final item = DataWriterItem();
      item.add(Formats.png(_imageBytes!));
      await clipboard.write([item]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Copy image failed: $e");
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to copy image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showImageOptions() async {
    if (_imageBytes == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy to Clipboard'),
                onTap: () {
                  Navigator.pop(context);
                  _copyImageToClipboard();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Image'),
                onTap: () {
                  Navigator.pop(context);
                  _shareImage(); // Call share method
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Add a basic share method (requires share_plus)
  Future<void> _shareImage() async {
    if (_imageBytes == null) return;
    // Placeholder if share_plus is not added
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality requires the share_plus package (see example pubspec).'),
      ),
    );
  }
  // --- End Capture/Copy/Share methods ---

  @override
  Widget build(BuildContext context) {
    // Theme setup for AppBar icon
    final Brightness currentBrightness = Theme.of(context).brightness;
    final IconData themeIcon =
        currentBrightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
    final theme = Theme.of(context); // Get theme for defaults

    // Determine the effective background color for the preview Container
    final Color effectiveBackgroundColor = _backgroundColor ?? theme.colorScheme.surface;

    // --- Build Method ---
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshot Generator'),
        actions: [
          IconButton(
            icon: Icon(themeIcon),
            tooltip: 'Toggle Theme',
            onPressed: widget.toggleThemeMode, // Use widget callback
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Text Input ---
            const Text(
              'Enter formatted text:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter text with **bold**, *italic*, `code`, '
                    '++underline++, ==highlight==, [link](url)...',
                helperText: 'Supports **bold**, *italic*, ~~strike~~, `code`, '
                    '++underline++, ==highlight==, [link](url) ^super^ ~sub~',
                isDense: true,
              ),
              maxLines: 4,
              onChanged: (value) {
                setState(() {}); // Rebuild preview on text change
              },
            ),
            const SizedBox(height: 16),

            // --- Formatting Options Expansion Tile ---
            ExpansionTile(
              title: const Text('Formatting Options'),
              initiallyExpanded: false,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 8.0,
                  ), // Reduced horizontal padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Base Styling Section ---
                      _buildSectionHeader('Base Styling'),
                      _buildFontSizeSlider(),
                      _buildTextScalerSlider(),
                      _buildTextAlignSelector(),
                      _buildColorPickerRow(
                        label: 'Base Text Color:',
                        selectedColor: _textColor, // Use nullable state
                        onColorSelected: (color) => setState(() => _textColor = color),
                        onReset: () => setState(() => _textColor = null), // Reset to null
                      ),
                      _buildColorPickerRow(
                        label: 'Background Color:',
                        selectedColor: _backgroundColor, // Use nullable state
                        onColorSelected: (color) => setState(() => _backgroundColor = color),
                        onReset: () => setState(() => _backgroundColor = null), // Reset to null
                      ),
                      const Divider(height: 20),

                      // URL Mouse Cursor Override
                      _buildMouseCursorSelector(),
                    ],
                  ),
                ),
              ],
            ), // End ExpansionTile

            const SizedBox(height: 24),

            // --- Preview Section ---
            const Text(
              'Preview:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // --- Refactored Preview Structure ---
            Center(
              // Ensure the RepaintBoundary captures the final composed widget
              child: RepaintBoundary(
                key: _screenshotKey,
                child: SizedBox(
                  width: double.infinity,
                  child: Card(
                    // Use theme card styling
                    clipBehavior: Clip.antiAlias, // Ensure container color respects border radius
                    // Apply background color here, falling back to theme surface
                    color: effectiveBackgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0), // Padding inside the card
                      // Apply base font size, alignment, and optional text color here
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                          fontSize: _fontSize,
                          color: _textColor, // If null, DefaultTextStyle inherits from theme
                        ),
                        child: TextfOptions(
                          // Pass the nullable option styles
                          boldStyle: _boldStyle,
                          italicStyle: _italicStyle,
                          boldItalicStyle: _boldItalicStyle,
                          strikethroughStyle: _strikethroughStyle,
                          codeStyle: _codeStyle,
                          urlStyle: _urlStyle,
                          urlHoverStyle: _urlHoverStyle,
                          urlMouseCursor: _urlMouseCursor,
                          underlineStyle: _underlineStyle,
                          highlightStyle: _highlightStyle,
                          // Important: Textf widget *without* the explicit style parameter
                          child: Textf(
                            _textController.text,
                            textAlign: _textAlign,
                            textScaler: TextScaler.linear(_textScaleFactor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // --- End Refactored Preview Structure ---

            const SizedBox(height: 24),
            // --- Capture Button ---
            Center(
              child: ElevatedButton.icon(
                onPressed: _isCapturing ? null : _captureScreenshot,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(_isCapturing ? 'Capturing...' : 'Capture Screenshot'),
              ),
            ),

            // --- Captured Image Display (remains the same) ---
            if (_capturedImage != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Captured Screenshot:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Center(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Prevent excessive height
                      children: [
                        GestureDetector(
                          onLongPress: _showImageOptions,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.8, // Limit width
                              maxHeight: MediaQuery.of(context).size.height * 0.4, // Limit height
                            ),
                            child: RawImage(
                              image: _capturedImage,
                              fit: BoxFit.contain, // Use contain to see the whole image
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Long-press image to copy/share',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets for Options UI ---

  // Builds a header for a section in the options
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }

  // Builds the Font Size Slider
  Widget _buildFontSizeSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Font Size: ${_fontSize.round()}'),
          Slider(
            value: _fontSize,
            min: 12,
            max: 32,
            divisions: 20,
            label: _fontSize.round().toString(),
            onChanged: (value) {
              setState(() => _fontSize = value);
            },
          ),
        ],
      ),
    );
  }

  // Builds the Text Scale Factor Slider
  Widget _buildTextScalerSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Text Scale Factor: ${_textScaleFactor.toStringAsFixed(1)}x'),
          Slider(
            value: _textScaleFactor,
            min: 0.5, // Minimaler Skalierungsfaktor
            max: 2.5, // Maximaler Skalierungsfaktor
            divisions: 20, // Anzahl der Schritte
            label: _textScaleFactor.toStringAsFixed(1),
            onChanged: (value) {
              setState(() => _textScaleFactor = value);
            },
          ),
        ],
      ),
    );
  }

  // Builds the Text Alignment Selector
  Widget _buildTextAlignSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Text Alignment:'),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity, // Make segmented button take full width
            child: SegmentedButton<TextAlign>(
              segments: const [
                ButtonSegment(
                  value: TextAlign.left,
                  icon: Icon(Icons.align_horizontal_left),
                  label: Text('Left'),
                ),
                ButtonSegment(
                  value: TextAlign.center,
                  icon: Icon(Icons.align_horizontal_center),
                  label: Text('Center'),
                ),
                ButtonSegment(
                  value: TextAlign.right,
                  icon: Icon(Icons.align_horizontal_right),
                  label: Text('Right'),
                ),
              ],
              selected: {_textAlign},
              onSelectionChanged: (Set<TextAlign> selection) {
                setState(() => _textAlign = selection.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Builds a row for picking a color with a reset button
  Widget _buildColorPickerRow({
    required String label,
    required Color? selectedColor,
    required ValueChanged<Color?> onColorSelected,
    required VoidCallback onReset,
    String resetButtonLabel = 'Use Theme/Default',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onReset,
                child: Text(resetButtonLabel),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _availableColors.map((color) {
                final bool isSelected = selectedColor == color;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => onColorSelected(color),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.blueAccent : Colors.grey.shade400,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.blueAccent.withValues(alpha: .5),
                                  blurRadius: 3,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: (color == Colors.white || color.computeLuminance() > 0.8) && isSelected
                          ? const Icon(Icons.check, color: Colors.black54, size: 16)
                          : isSelected
                              ? const Icon(Icons.check, color: Colors.white70, size: 16)
                              : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the Mouse Cursor Selector
  Widget _buildMouseCursorSelector() {
    final availableCursors = {
      'Default': null, // Represents resetting to Textf default
      'Basic': SystemMouseCursors.basic,
      'Click': SystemMouseCursors.click,
      'Text': SystemMouseCursors.text,
      'Forbidden': SystemMouseCursors.forbidden,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('URL Mouse Cursor Override:'),
          const SizedBox(height: 4),
          DropdownButton<MouseCursor?>(
            value: _urlMouseCursor, // Current state
            isExpanded: true,
            items: availableCursors.entries.map((entry) {
              return DropdownMenuItem<MouseCursor?>(
                value: entry.value,
                child: Text(entry.key),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() => _urlMouseCursor = newValue);
            },
            // Display 'Default' when state is null
            hint: _urlMouseCursor == null ? const Text('Default (from Textf)') : null,
          ),
        ],
      ),
    );
  }
}
