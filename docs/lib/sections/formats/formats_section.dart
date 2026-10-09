// ignore_for_file: no-magic-number

import 'package:material_ui/material_ui.dart';

import 'advanced_formatting_tab.dart';
import 'basic_formatting_tab.dart';
import 'block_formatting_tab.dart';

class FormatsSection extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Basic'),
              Tab(text: 'Blocks'),
              Tab(text: 'Advanced'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                BasicFormattingTab(),
                BlockFormattingTab(),
                AdvancedFormattingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
