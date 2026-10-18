import 'package:material_ui/material_ui.dart';

class ThemeModeNotifier extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const new({
    required ValueNotifier<ThemeMode> notifier,
    required super.child,
    super.key,
  }) : super(notifier: notifier);

  static ValueNotifier<ThemeMode> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeModeNotifier>()!.notifier!;
}
