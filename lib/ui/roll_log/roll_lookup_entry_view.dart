import 'package:flutter/material.dart';

import '../styles.dart';

class RollLookupEntryView extends StatelessWidget {
  final String value;
  final String label;
  final Color backgroundColor;
  final VoidCallback? onRoll;

  const RollLookupEntryView({
    required this.value,
    required this.label,
    required this.backgroundColor,
    this.onRoll,
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
          child: Text(
            label,
            softWrap: false,
            overflow: TextOverflow.clip,
          ),
        ),

        // roll button
        if (onRoll != null)
          const Padding(
            padding: EdgeInsets.only(right: 4.0),
            child: AppStyles.rollIcon,
          ),
      ],
    );

    if (onRoll != null) {
      row = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onRoll != null
              ? () {
                  Navigator.of(context).pop();

                  onRoll!();
                }
              : null,
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
