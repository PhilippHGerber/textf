// ignore_for_file: no-magic-number

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// This will be generated after running build_runner
import 'widgetbook.directories.g.dart';

@widgetbook.App()
// ignore: prefer-match-file-name
class WidgetbookApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: directories,
      addons: [
        ViewportAddon([
          Viewports.none,
          IosViewports.iPhone13,
          AndroidViewports.samsungGalaxyNote20,
          MacosViewports.macbookPro,
          WindowsViewports.desktop,
          LinuxViewports.desktop,
        ]),
        // Theme addon to switch between light and dark mode
        ThemeAddon<ThemeData>(
          themes: [
            WidgetbookTheme(
              name: 'Light',
              data: FlexThemeData.light(scheme: FlexScheme.material),
            ),
            WidgetbookTheme(
              name: 'Dark',
              data: FlexThemeData.dark(scheme: FlexScheme.material),
            ),
            // Add various color schemes from FlexColorScheme
            for (final scheme in FlexScheme.values.take(6))
              WidgetbookTheme(
                name: scheme.name,
                data: FlexThemeData.light(scheme: scheme),
              ),
          ],
          initialTheme: WidgetbookTheme(
            name: 'Light',
            data: FlexThemeData.light(scheme: FlexScheme.material),
          ),
          themeBuilder: (context, theme, child) {
            return Theme(
              data: theme,
              child: ColoredBox(
                color: theme.scaffoldBackgroundColor,
                child: DefaultTextStyle(
                  style: theme.textTheme.bodyMedium ?? const TextStyle(),
                  child: child,
                ),
              ),
            );
          },
        ),

        // Text scale addon to test different text sizes
        TextScaleAddon(),

        // Localization addon to test different locales
        LocalizationAddon(
          locales: [
            const Locale('en', 'US'),
            const Locale('ar', 'SA'), // RTL language
            const Locale('zh', 'CN'),
            const Locale('de', 'DE'),
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ],
      appBuilder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          // theme: context.theme,
          // locale: context.locale,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          // supportedLocales: context.localizationAddon?.locales ?? const [Locale('en', 'US')],
          home: child,
        );
      },
    );
  }
}
