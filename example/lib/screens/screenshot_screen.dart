import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:textf/textf.dart';

class ScreenshotScreen extends StatefulWidget {
  const ScreenshotScreen({super.key});

  @override
  State<ScreenshotScreen> createState() => _ScreenshotScreenState();
}

class _ScreenshotScreenState extends State<ScreenshotScreen> {
  final TextEditingController _textController = TextEditingController(
    text: 'Hello **bold** *italic* ~~strikethrough~~ `code`',
  );
  final GlobalKey _screenshotKey = GlobalKey();

  double _fontSize = 16;
  Color _textColor = Colors.black;
  Color _backgroundColor = Colors.white;
  TextAlign _textAlign = TextAlign.left;

  bool _isCapturing = false;
  ui.Image? _capturedImage;
  Uint8List? _imageBytes;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _captureScreenshot() async {
    setState(() {
      _isCapturing = true;
    });

    try {
      // Delay to ensure UI is built
      await Future.delayed(const Duration(milliseconds: 100));

      // Find the RenderRepaintBoundary
      RenderRepaintBoundary boundary = _screenshotKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Capture the image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // Convert to bytes
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      _imageBytes = byteData?.buffer.asUint8List();

      setState(() {
        _capturedImage = image;
        _isCapturing = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screenshot captured! Long-press to copy/save.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture screenshot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyImageToClipboard() async {
    if (_imageBytes == null) return;

    try {
      // Use super_clipboard to copy image data
      final clipboard = SystemClipboard.instance;
      final item = DataWriterItem();

      // Add image to clipboard item
      item.add(Formats.png(_imageBytes!));

      // Write to clipboard
      await clipboard?.write([item]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share functionality requires additional plugins'),
                    ),
                  );
                  // To implement sharing, you would need to add a package like share_plus
                  // and use it with _imageBytes
                },
              ),
              ListTile(
                leading: const Icon(Icons.save),
                title: const Text('Save to Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Save functionality requires additional plugins'),
                    ),
                  );
                  // To implement saving, you would need to add a package like
                  // image_gallery_saver and use it with _imageBytes
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshot Generator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter formatted text:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _textController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter text with **bold**, *italic*, etc.',
                helperText: 'Supports **bold**, *italic*, ~~strikethrough~~, `code`',
              ),
              maxLines: 3,
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 16),

            // Formatting options
            ExpansionTile(
              title: const Text('Formatting Options'),
              initiallyExpanded: true,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Font Size:'),
                      Slider(
                        value: _fontSize,
                        min: 12,
                        max: 32,
                        divisions: 20,
                        label: _fontSize.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            _fontSize = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text('Text Color:'),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _colorButton(Colors.black),
                            _colorButton(Colors.blue),
                            _colorButton(Colors.red),
                            _colorButton(Colors.green),
                            _colorButton(Colors.purple),
                            _colorButton(Colors.orange),
                            _colorButton(Colors.teal),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Background Color:'),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _backgroundColorButton(Colors.white),
                            _backgroundColorButton(Colors.grey.shade200),
                            _backgroundColorButton(Colors.blue.shade50),
                            _backgroundColorButton(Colors.red.shade50),
                            _backgroundColorButton(Colors.green.shade50),
                            _backgroundColorButton(Colors.yellow.shade50),
                            _backgroundColorButton(Colors.purple.shade50),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Text Alignment:'),
                      SegmentedButton<TextAlign>(
                        segments: const [
                          ButtonSegment(
                            value: TextAlign.left,
                            icon: Icon(Icons.align_horizontal_left),
                          ),
                          ButtonSegment(
                            value: TextAlign.center,
                            icon: Icon(Icons.align_horizontal_center),
                          ),
                          ButtonSegment(
                            value: TextAlign.right,
                            icon: Icon(Icons.align_horizontal_right),
                          ),
                        ],
                        selected: {_textAlign},
                        onSelectionChanged: (Set<TextAlign> selection) {
                          setState(() {
                            _textAlign = selection.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              'Preview:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Preview area
            Center(
              child: Card(
                elevation: 4,
                child: RepaintBoundary(
                  key: _screenshotKey,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: _backgroundColor,
                    child: Textf(
                      _textController.text,
                      style: TextStyle(
                        fontSize: _fontSize,
                        color: _textColor,
                      ),
                      textAlign: _textAlign,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            // Capture button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isCapturing ? null : _captureScreenshot,
                icon: const Icon(Icons.camera),
                label: Text(_isCapturing ? 'Capturing...' : 'Capture Screenshot'),
              ),
            ),

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
                      children: [
                        GestureDetector(
                          onLongPress: _showImageOptions,
                          child: RawImage(
                            image: _capturedImage,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Long-press image to copy/share/save',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _colorButton(Color color) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _textColor = color;
          });
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: _textColor == color ? Colors.blue : Colors.grey,
              width: _textColor == color ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _backgroundColorButton(Color color) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _backgroundColor = color;
          });
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: _backgroundColor == color ? Colors.blue : Colors.grey,
              width: _backgroundColor == color ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}
