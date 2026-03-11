import 'package:flutter/material.dart';

class TextBadge extends WidgetSpan {
  TextBadge({required String text})
      : super(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, top: 3, bottom: 2),
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 7),
              ),
            ),
          ),
        );
}
