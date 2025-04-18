import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';

void main() {
  runApp(const FlexTextfExampleApp());
}

class FlexTextfExampleApp extends StatefulWidget {
  const FlexTextfExampleApp({super.key});

  @override
  State<FlexTextfExampleApp> createState() => _FlexTextfExampleAppState();
}

class _FlexTextfExampleAppState extends State<FlexTextfExampleApp> {
  // State for the selected FlexScheme and ThemeMode
  FlexScheme _selectedScheme = FlexScheme.material;
  ThemeMode _themeMode = ThemeMode.light;

  // Callback to change the selected theme scheme
  void _handleSchemeChange(FlexScheme? scheme) {
    if (scheme != null) {
      setState(() {
        _selectedScheme = scheme;
      });
    }
  }

  // Callback to toggle the ThemeMode (Light/Dark/System)
  void _handleThemeModeChange() {
    setState(() {
      switch (_themeMode) {
        case ThemeMode.light:
          _themeMode = ThemeMode.dark;
          break;
        case ThemeMode.dark:
          _themeMode = ThemeMode.system;
          break;
        case ThemeMode.system:
          _themeMode = ThemeMode.light;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use Material 3
    const bool useMaterial3 = true;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Textf + FlexColorScheme',
      theme: FlexThemeData.light(
        scheme: _selectedScheme,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 20,
        subThemesData: const FlexSubThemesData(),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: useMaterial3,
        swapLegacyOnMaterial3: useMaterial3,
      ),
      darkTheme: FlexThemeData.dark(
        scheme: _selectedScheme,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 20,
        subThemesData: const FlexSubThemesData(),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: useMaterial3,
        swapLegacyOnMaterial3: useMaterial3,
      ),
      themeMode: _themeMode,
      home: HomeScreen(
        selectedScheme: _selectedScheme,
        themeMode: _themeMode,
        onSchemeChanged: _handleSchemeChange,
        onThemeModeChanged: _handleThemeModeChange,
      ),
    );
  }
}
