import 'package:flutter/material.dart';

class RoundBadge extends StatelessWidget {
  final Color? backgroundColor;
  final Color? color;
  final String text;
  final double size;

  const RoundBadge({
    required this.text,
    this.backgroundColor,
    this.color,
    this.size = 32,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: Center(
        child: Baseline(
          baseline: 17,
          baselineType: TextBaseline.alphabetic,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
