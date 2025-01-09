import 'package:flutter/material.dart';

class ClearLogButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const ClearLogButton({
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
          ),
        ),
        color: theme.colorScheme.surfaceContainerLow,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: onPressed,
          child: const Text('Clear'),
        ),
      ),
    );
  }
}
