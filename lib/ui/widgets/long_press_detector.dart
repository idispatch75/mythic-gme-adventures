import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class LongPressDetector extends StatelessWidget {
  final Duration duration;
  final VoidCallback onLongPress;
  final Widget? child;

  const LongPressDetector({
    required this.duration,
    required this.onLongPress,
    this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(duration: duration),
              (instance) => instance.onLongPress = onLongPress,
            ),
      },
      child: child,
    );
  }
}
