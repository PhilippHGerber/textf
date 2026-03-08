// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';

import 'links_tab.dart';
import 'widgets_tab.dart';

class LinksWidgetsSection extends StatelessWidget {
  const LinksWidgetsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Links'),
              Tab(text: 'Widgets'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                LinksTab(),
                WidgetsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
