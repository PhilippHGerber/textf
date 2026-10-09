# benchmark

Two ways to measure `textf` performance:

- **Headless scaling benchmark** (`test/parse_scaling_benchmark_test.dart`): parse and span-build
  timings at several input sizes, run with `flutter test`. Use it to check O(N) scaling and to
  compare two versions of the package (T-PERF-01, the 2.0 theming
  regression check).
- **Profile-mode stress app** (`lib/main.dart`): frame timings on a real device, below.

## Headless scaling benchmark

```bash
cd example/benchmark
flutter test test/parse_scaling_benchmark_test.dart
```

It times four scenarios on a representative chunk (a heading, every inline construct, nested
formatting and code inside links, escapes and a `---` rule) repeated to N = 268 … 8576 characters:

| Scenario         | What one operation is                                                          |
| ---------------- | ------------------------------------------------------------------------------ |
| `parse`          | `TextfParser.parse` on a cold token cache: tokenize, pair, resolve styles, build spans |
| `editing`        | `TextfEditingController.buildTextSpan` on a cold cache                          |
| `widget`         | `pumpWidget` of a `Textf` (with `style`) whose text changed: build + layout + paint |
| `widget_ambient` | the same without `Textf.style`, so only the ambient `DefaultTextStyle` applies  |

For each scenario and N it prints one `TEXTF_BENCH` line with the median, p25 and p75 of 21 samples
(each sample averages enough operations to process about 32,000 characters) and the cost per
character. The test fails if the per-character cost at the largest N exceeds 3x the cost at
N = 1072: linear parsing gives about 1x (less, as fixed per-call overhead is amortized), quadratic
parsing about 8x.

Timings come from a debug-mode (JIT) `flutter test` run, so the absolute numbers are higher than a
release build's. Use them to compare, not as frame budgets.

### Comparing two versions

A single run is too noisy to compare. Run the same test file against both package versions,
alternating (`A B A B …`, at least 5 rounds each) so that machine drift hits both equally, and
compare the **median of the per-run medians** for each scenario and N.

**Run-to-run noise** is what the same code measures against itself: split the baseline's runs into
odd and even rounds and compare their medians (an A/A comparison). On an Apple-silicon laptop this
was at most 0.5–2.8% per scenario (one outlier of 6.8% for `parse`). A difference is a regression
only if it exceeds that A/A band **and** has the same sign in almost every paired round.

`widget_ambient` is the like-for-like layout comparison against 1.x. Since 2.0, `Textf.style` is
merged with the ambient `DefaultTextStyle` (as in `Text`) instead of replacing it, so in `widget`
the spans carry a richer style than they did in 1.x.

The chunk has a `---` rule every 268 characters, far denser than real text, so anything that makes
thematic breaks costlier is amplified in the `widget` scenarios.

## Profile-mode stress app

### Step 1: Run in Profile Mode

Connect a physical device (iPhone or Android). Run the command:

> flutter devices
> flutter run --profile -t lib/main.dart
> flutter run -d [id] --profile -t lib/main.dart
> flutter run -d android --profile -t lib/main.dart

### Step 2: Observe the Performance Overlay

Once the app launches, you will see two graphs overlaying the screen (enabled by `showPerformanceOverlay: true` in the code).

1. **Top Graph (Raster/GPU):** How fast the GPU draws the frame.
2. **Bottom Graph (UI/CPU):** How fast Dart calculates layout and processes logic.

**The Test:**

1. Tap the **Play** button (FAB). Items will start adding rapidly.
2. **Scroll aggressively** up and down while items are adding.
3. **The Goal:** The graphs should stay **green**. Green bars mean the frame took less than 16ms (60 FPS) or 8ms (120 FPS).
    * If you see red bars, that is "Jank".

### Step 3: Deep Dive with Flutter DevTools

For scientific proof (actual millisecond timings):

1. While the app is running in Profile mode, open DevTools:
    * **VS Code:** Open Command Palette -> `Flutter: Open DevTools` -> `Open DevTools in Browser`.
    * **Terminal:** Click the link printed in the terminal (usually `http://127.0.0.1:9100...`).
2. Click on the **Performance** tab in DevTools.
3. Click **"Enhance Tracing"** and ensure "Track Widget Builds" is checked.
4. In the app, ensure the stress test is running (Play button).
5. In DevTools, click the **Record** button (circle icon).
6. Scroll the app list for 5-10 seconds.
7. Click **Stop**.

### Step 4: Analyze the Results

Look at the **Frame Analysis** chart:

* **Average Frame Time:** Look for the "UI" time.
  * **< 8ms:** Excellent (120 FPS capable).
  * **8ms - 16ms:** Good (60 FPS).
  * **> 16ms:** Jank.
