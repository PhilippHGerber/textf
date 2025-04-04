import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const TextfExampleApp());
}

class TextfExampleApp extends StatelessWidget {
  const TextfExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Textf Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
