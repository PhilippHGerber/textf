import 'package:flutter/material.dart';
import 'package:textf/textf.dart';

class SelectableScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const SelectableScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextfOptions(
      codeStyle: const TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 12,
      ),
      child: Scaffold(
        appBar: appBar,
        backgroundColor: backgroundColor,
        body: SelectionArea(child: body),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
