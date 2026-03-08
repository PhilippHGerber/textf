// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';

import 'advanced_formatting_tab.dart';
import 'basic_formatting_tab.dart';

class FormatsSection extends StatelessWidget {
  const FormatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Basic'),
              Tab(text: 'Advanced'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                BasicFormattingTab(),
                AdvancedFormattingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
