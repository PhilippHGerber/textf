import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'router/app_router.dart';
import 'theme/theme_mode_notifier.dart';

const _lightBlendLevel = 4;
const _darkBlendLevel = 18;

void main() {
  usePathUrlStrategy();
  runApp(const TextfDocsApp());
}

class TextfDocsApp extends StatefulWidget {
  const TextfDocsApp({super.key});

  @override
  State<TextfDocsApp> createState() => _TextfDocsAppState();
}

class _TextfDocsAppState extends State<TextfDocsApp> {
  // ignore: avoid-late-keyword
  late final ValueNotifier<ThemeMode> _themeModeNotifier;

  @override
  void initState() {
    super.initState();
    final platformBrightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    _themeModeNotifier = ValueNotifier(
      platformBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    );
  }

  @override
  void dispose() {
    _themeModeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeModeNotifier(
      notifier: _themeModeNotifier,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeModeNotifier,
        builder: (context, currentMode, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Textf Docs',
            routerConfig: appRouter,
            theme: FlexThemeData.light(
              scheme: FlexScheme.flutterDash,
              surfaceMode: FlexSurfaceMode.level,
              blendLevel: _lightBlendLevel,
              subThemesData: const FlexSubThemesData(
                interactionEffects: true,
                tintedDisabledControls: true,
                defaultRadius: 12,
                elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
                elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
                inputDecoratorBorderType: FlexInputBorderType.outline,
                inputDecoratorRadius: 8,
                chipRadius: 8,
                navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
                navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
                navigationBarIndicatorSchemeColor: SchemeColor.primary,
                navigationBarBackgroundSchemeColor: SchemeColor.surface,
              ),
              visualDensity: FlexColorScheme.comfortablePlatformDensity,
            ),
            darkTheme: FlexThemeData.dark(
              scheme: FlexScheme.flutterDash,
              surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
              blendLevel: _darkBlendLevel,
              subThemesData: const FlexSubThemesData(
                interactionEffects: true,
                tintedDisabledControls: true,
                defaultRadius: 12,
                elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
                elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
                inputDecoratorBorderType: FlexInputBorderType.outline,
                inputDecoratorRadius: 8,
                chipRadius: 8,
                navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
                navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
                navigationBarIndicatorSchemeColor: SchemeColor.primary,
                navigationBarBackgroundSchemeColor: SchemeColor.surface,
              ),
              visualDensity: FlexColorScheme.comfortablePlatformDensity,
            ),
            themeMode: currentMode,
          );
        },
      ),
    );
  }
}
