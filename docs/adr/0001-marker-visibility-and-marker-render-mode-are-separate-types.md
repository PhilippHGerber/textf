# MarkerVisibility and MarkerRenderMode are separate types

`TextfEditingController` exposes a `MarkerVisibility` enum (`always` / `whenActive`) as its public API for configuring marker display. Internally, the controller computes a `MarkerRenderMode` sealed type (`always` / `active(int cursorPosition)` / `hidden`) each frame and passes it to `TextfSpanBuilder`. These are distinct concepts — configuration vs computed state — and intentionally kept as two types.

The alternative was to collapse them: remove `MarkerVisibility`, expose `MarkerRenderMode` publicly, and let callers set the mode directly. This was rejected because `MarkerRenderMode.active(int)` and `MarkerRenderMode.hidden` are frame-level state that callers should never set manually; exposing them would leak internal frame logic into the public API. Keeping `MarkerVisibility` as the stable public type preserves a non-breaking API surface while `MarkerRenderMode` remains a private implementation detail of the editing layer.
