/// Controls how formatting markers are displayed in the text field.
enum MarkerVisibility {
  /// Markers are always visible with a dimmed style. This is the default.
  ///
  /// Text selection does not affect marker visibility in this mode.
  always,

  /// Markers are only visible when the cursor is inside the formatted span.
  /// Inactive markers are instantly hidden.
  ///
  /// During text selection (non-collapsed), all markers are hidden to prevent
  /// layout jumps caused by markers toggling visibility as the selection
  /// changes. This is especially important on mobile, where layout shifts
  /// during drag selection would displace selection handles.
  whenActive,
}
