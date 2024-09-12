import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../styles.dart';
import 'roll_log_view.dart';
import 'roll_lookup_entry_view.dart';

class RollLookupEntry {
  final String value;
  final String label;
  final VoidCallback? onRoll;
  final VoidCallback? onApply;

  const RollLookupEntry({
    required this.value,
    required this.label,
    this.onRoll,
    this.onApply,
  });
}

class RollLookupView extends StatelessWidget {
  final String header;
  final RollColors rollColors;
  final List<RollLookupEntry> entries;
  final Widget? additionalContent;

  const RollLookupView({
    required this.header,
    required this.rollColors,
    required this.entries,
    this.additionalContent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = rollColors.background;
    final alternateColor = baseColor.withOpacity(0.5);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // header
          RollHeader(header, rollColors),

          // entries
          ...entries.mapIndexed((index, entry) {
            final backgroundColor = index.isEven ? baseColor : alternateColor;

            return RollLookupEntryView(
              value: entry.value,
              label: entry.label,
              backgroundColor: backgroundColor,
              onRoll: entry.onRoll,
              onApply: entry.onApply,
            );
          }),

          // additional content
          if (additionalContent != null) ...[
            const SizedBox(height: 16),
            additionalContent!,
          ],
        ],
      ),
    );
  }
}
