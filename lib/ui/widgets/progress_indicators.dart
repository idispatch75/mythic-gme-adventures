import 'package:flutter/material.dart';

/// A centered [CircularProgressIndicator].
const Widget loadingIndicator = Center(
  child: CircularProgressIndicator.adaptive(),
);

class StackedProgressIndicator extends StatelessWidget {
  final Widget child;

  /// A [CircularProgressIndicator] with a [child] in its center.
  const StackedProgressIndicator({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        loadingIndicator,
        child,
      ],
    );
  }
}
