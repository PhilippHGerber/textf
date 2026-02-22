/// Controls how formatting markers are displayed in the text field.
enum MarkerVisibility {
  /// Markers are always visible with a dimmed style. This is the default.
  always,

  /// Markers are only visible when the cursor is inside the formatted span.
  /// Inactive markers are hidden (or fading) based on
  /// `TextfEditingController.markerOpacity`.
  whenActive,
}
