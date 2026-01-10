# benchmark

The Benchmark Code

## Getting Started

#### Step 1: Run in Profile Mode

Connect a physical device (iPhone or Android). Run the command:

> flutter devices
> flutter run --profile -t lib/benchmark.dart
> flutter run -d [id] --profile -t lib/benchmark.dart
> flutter run -d android --profile -t lib/benchmark.dart

#### Step 2: Observe the Performance Overlay

Once the app launches, you will see two graphs overlaying the screen (enabled by `showPerformanceOverlay: true` in the code).

1. **Top Graph (Raster/GPU):** How fast the GPU draws the frame.
2. **Bottom Graph (UI/CPU):** How fast Dart calculates layout and processes logic.

**The Test:**

1. Tap the **Play** button (FAB). Items will start adding rapidly.
2. **Scroll aggressively** up and down while items are adding.
3. **The Goal:** The graphs should stay **green**. Green bars mean the frame took less than 16ms (60 FPS) or 8ms (120 FPS).
    * If you see red bars, that is "Jank".

#### Step 3: Deep Dive with Flutter DevTools

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

#### Step 4: Analyze the Results

Look at the **Frame Analysis** chart:

* **Average Frame Time:** Look for the "UI" time.
  * **< 8ms:** Excellent (120 FPS capable).
  * **8ms - 16ms:** Good (60 FPS).
  * **> 16ms:** Jank.

**Specific check for Textf:**

1. In the **Timeline Events** (bottom flame chart).
2. Search (Ctrl+F) for `Textf`.
3. You won't see `Textf` parsing taking up huge blocks because your O(1) loop is fast. You will likely see `Text.rich` layout taking the most time (which is standard Flutter text rendering cost, not your parsing cost).
