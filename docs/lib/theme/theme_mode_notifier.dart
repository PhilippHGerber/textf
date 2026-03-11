import 'package:flutter/material.dart';

class ThemeModeNotifier extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const ThemeModeNotifier({
    required ValueNotifier<ThemeMode> notifier,
    required super.child,
    super.key,
  }) : super(notifier: notifier);

  static ValueNotifier<ThemeMode> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeModeNotifier>()!.notifier!;
}
