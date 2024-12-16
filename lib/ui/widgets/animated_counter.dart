import 'package:flutter/widgets.dart';

class AnimatedCounter extends StatelessWidget {
  final Widget child;

  const AnimatedCounter({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return child;
    // return AnimatedSwitcher(
    //   duration: const Duration(milliseconds: 300),
    //   switchInCurve: Curves.easeIn,
    //   switchOutCurve: Curves.easeOut,
    //   transitionBuilder: (child, animation) => FadeTransition(
    //     key: ValueKey<Key?>(child.key),
    //     opacity: animation,
    //     child: child,
    //   ),
    //   child: child,
    // );
  }
}
