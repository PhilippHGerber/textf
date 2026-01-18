import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:textf/textf.dart';

void main() {
  runApp(const MaterialApp(home: ScalingReproScreen()));
}

class ScalingReproScreen extends StatefulWidget {
  @Preview(
    name: 'Scaling Repro Screen',
  )
  const ScalingReproScreen({super.key});

  @override
  State<ScalingReproScreen> createState() => _ScalingReproScreenState();
}

class _ScalingReproScreenState extends State<ScalingReproScreen> {
  double _textScaleFactor = 1.0;
  double _fontSize = 14.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Textf Scaling Superscript/Subscript")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            TextfOptions(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                padding: const EdgeInsets.all(8),
                child: SelectionArea(
                  child: Textf(
                    ' **hello** ==world== \n'
                    ' E = mc^2^ \n'
                    ' H~2~O \n'
                    ' a^log~a~b^ \n'
                    ' This is a ~~cat~~ bird {0} \n',
                    style: TextStyle(fontSize: _fontSize),
                    textScaler: TextScaler.linear(_textScaleFactor),
                    inlineSpans: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Image.asset(
                          'assets/img/bird.gif',
                          width: _fontSize*2,
                          height: _fontSize*2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text("Font Size: ${_fontSize.toStringAsFixed(0)}px"),
            Slider(
              min: 14.0,
              max: 48.0,
              divisions: 34,
              value: _fontSize,
              onChanged: (v) => setState(() => _fontSize = v),
            ),
            const SizedBox(height: 8),
            Text("Text Scale Factor: ${_textScaleFactor.toStringAsFixed(1)}x"),
            Slider(
              min: 1.0,
              max: 2.5,
              value: _textScaleFactor,
              onChanged: (v) => setState(() => _textScaleFactor = v),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
