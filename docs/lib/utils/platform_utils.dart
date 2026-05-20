// ignore_for_file: prefer-match-file-name

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// True on Android Chrome and iOS Safari (mobile web browsers).
bool get isMobileWeb =>
    kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Mixin: unfocus when iOS Safari "Done" hides the keyboard,
/// preventing phantom keyboard re-opens on the next tap.
mixin IOSKeyboardFocusFix<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  double _prevInset = 0;

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    final inset =
        WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    if (_prevInset > 0 && inset == 0) FocusManager.instance.primaryFocus?.unfocus();
    _prevInset = inset;
  }
}
