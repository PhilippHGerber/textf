import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show TextSelection;

import 'marker_visibility.dart';

/// Dictates how formatting markers are rendered in the editing layer.
///
/// Computed each frame from `MarkerVisibility` and the current selection state,
/// then passed to `TextfSpanBuilder`.
@immutable
sealed class MarkerRenderMode {
  /// Base const constructor for subclasses.
  const new();

  /// Show markers only when active around [cursorPosition].
  // ignore: unnecessary_type_name_in_constructor, required by Dart syntax for redirecting factories.
  const factory MarkerRenderMode.active(int cursorPosition) = MarkerRenderModeActive;

  /// Computes the effective render mode from the controller's [visibility] setting
  /// and current text [selection].
  // ignore: unnecessary_type_name_in_constructor
  factory MarkerRenderMode.fromVisibility({
    required MarkerVisibility visibility,
    required TextSelection selection,
  }) {
    switch (visibility) {
      case MarkerVisibility.always:
        return MarkerRenderMode.always;
      case MarkerVisibility.whenActive:
        return selection.isValid && selection.isCollapsed
            ? MarkerRenderMode.active(selection.extentOffset)
            : MarkerRenderMode.hidden;
    }
  }

  /// Show all markers with dimmed styling.
  static const MarkerRenderMode always = MarkerRenderModeAlways();

  /// Suppress all markers (used during non-collapsed selection or when inactive).
  static const MarkerRenderMode hidden = MarkerRenderModeHidden();

  /// Returns whether this mode considers a marker active within [start] and [end]
  /// (inclusive).
  ///
  /// For [MarkerRenderModeAlways], always `true`.
  /// For [MarkerRenderModeHidden], always `false`.
  /// For [MarkerRenderModeActive], `true` when `cursorPosition` is in `[start, end]`.
  bool isActiveInRange(int start, int end) => switch (this) {
    MarkerRenderModeAlways() => true,
    MarkerRenderModeHidden() => false,
    MarkerRenderModeActive(:final cursorPosition) =>
      cursorPosition >= start && cursorPosition <= end,
  };
}

/// Mode where all formatting markers are displayed with dimmed styling.
@immutable
final class MarkerRenderModeAlways extends MarkerRenderMode {
  /// Creates a [MarkerRenderModeAlways] instance.
  const new();

  @override
  bool operator ==(Object other) => identical(this, other) || other is MarkerRenderModeAlways;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'MarkerRenderMode.always';
}

/// Mode where markers are only visible when the cursor is at [cursorPosition].
@immutable
final class MarkerRenderModeActive extends MarkerRenderMode {
  /// Creates a [MarkerRenderModeActive] instance for [cursorPosition].
  const new(this.cursorPosition);

  /// The cursor character offset within the text.
  final int cursorPosition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MarkerRenderModeActive && other.cursorPosition == cursorPosition);

  @override
  int get hashCode => Object.hash(runtimeType, cursorPosition);

  @override
  String toString() => 'MarkerRenderMode.active($cursorPosition)';
}

/// Mode where all formatting markers are suppressed.
@immutable
final class MarkerRenderModeHidden extends MarkerRenderMode {
  /// Creates a [MarkerRenderModeHidden] instance.
  const new();

  @override
  bool operator ==(Object other) => identical(this, other) || other is MarkerRenderModeHidden;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'MarkerRenderMode.hidden';
}
