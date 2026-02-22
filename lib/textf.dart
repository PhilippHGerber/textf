// Copyright (c) 2025 Philipp H. Gerber
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

/// A lightweight text widget library for simple inline Markdown-like formatting.
///
/// ## Exports
///
/// - [Textf]: A drop-in replacement for Flutter's [Text] widget that supports
///   inline formatting markers for bold, italic, code, links, highlights,
///   superscript, subscript, and widget placeholders.
///
/// - [TextfOptions]: An [InheritedWidget] for configuring formatting styles,
///   link callbacks, and script geometry for all descendant [Textf] widgets.
///
/// - [TextfEditingController]: A [TextEditingController] that renders
///   textf-formatted text inside [TextField] and [TextFormField] widgets.
///
/// ## Example
///
/// ```dart
/// import 'package:textf/textf.dart';
///
/// Textf('Hello **bold** *italic* `code` [link](https://example.com)');
/// ```
/// @docImport 'package:flutter/material.dart';
/// @docImport 'textf.dart';
library;

export 'src/editing/marker_visibility.dart';
export 'src/editing/textf_editing_controller.dart';
export 'src/widgets/textf.dart';
export 'src/widgets/textf_options.dart';
