// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';

import 'article_tab.dart';
import 'chat_tab.dart';
import 'notification_tab.dart';

class RealWorldSection extends StatelessWidget {
  const RealWorldSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Chat'),
              Tab(text: 'Notifications'),
              Tab(text: 'Article'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ChatTab(),
                NotificationTab(),
                ArticleTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
