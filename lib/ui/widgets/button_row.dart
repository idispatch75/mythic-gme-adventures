import 'package:flutter/material.dart';

class ButtonRow extends StatelessWidget {
  final List<Widget> children;

  /// A row of buttons for a tab view,
  /// with background color and bottom divider.
  const ButtonRow({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.canvas,
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: children,
        ),
      ),
    );
  }
}
