import 'package:flutter/material.dart';

import '../styles.dart';

class RollLookupEntryView extends StatelessWidget {
  final String value;
  final String label;
  final Color backgroundColor;
  final VoidCallback? onRoll;
  final VoidCallback? onApply;

  const RollLookupEntryView({
    required this.value,
    required this.label,
    required this.backgroundColor,
    this.onRoll,
    this.onApply,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // value
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: SizedBox(
            width: 74,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // label
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              label,
              softWrap: false,
              overflow: TextOverflow.clip,
            ),
          ),
        ),

        // roll/apply button
        if (onRoll != null || onApply != null)
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: onRoll != null
                ? AppStyles.rollIcon
                : const Icon(
                    Icons.add,
                    size: 18,
                  ),
          ),
      ],
    );

    if (onRoll != null || onApply != null) {
      final onTap = onRoll != null
          ? () {
              Navigator.of(context).pop();

              onRoll!();
            }
          : onApply;

      row = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: row,
        ),
      );
    }

    return Container(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: row,
      ),
    );
  }
}
