import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../roll_log/roll_log_view.dart';
import '../roll_log/roll_lookup_entry_view.dart';
import '../styles.dart';

class ListableItemsLookupView extends StatelessWidget {
  final String _itemTypeLabel;
  final List<String?> _itemNames;

  const ListableItemsLookupView(
    this._itemTypeLabel,
    this._itemNames, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mainRows = _itemNames.splitAfterIndexed(
      (index, element) => (index + 1) % 5 == 0,
    );

    var header = _itemTypeLabel;
    if (mainRows.length > 1) {
      header += ' - 1d${mainRows.length * 2}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // header
        RollHeader(header, AppStyles.genericColors),

        // entries
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: mainRows.expandIndexed((index, rowItems) {
                return [
                  // row
                  _MainRow(
                    index: index,
                    itemNames: rowItems,
                    backgroundColorOffset: index.isEven ? 0 : 1,
                    showValue: mainRows.length > 1,
                  ),

                  // divider
                  if (index < mainRows.length - 1)
                    Divider(
                      thickness: 2,
                      height: 3,
                      color: AppStyles.headerColor,
                    ),
                ];
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _MainRow extends StatelessWidget {
  final int index;
  final List<String?> itemNames;
  final int backgroundColorOffset;
  final bool showValue;

  const _MainRow({
    required this.index,
    required this.itemNames,
    required this.backgroundColorOffset,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final baseColor = AppStyles.genericColors.background;
    final alternateColor = Color.alphaBlend(
      baseColor.withValues(alpha: 0.5),
      colors.surface,
    );

    return Container(
      color: AppStyles.headerColor,
      child: Row(
        children: [
          // row roll
          SizedBox(
            width: 48,
            child: showValue
                ? Text(
                    '${index * 2 + 1} - ${index * 2 + 2}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppStyles.onHeaderColor,
                    ),
                    textAlign: TextAlign.center,
                  )
                : null,
          ),

          // items
          Expanded(
            child: Column(
              children: itemNames.mapIndexed((index, name) {
                final backgroundColor = (index + backgroundColorOffset).isEven
                    ? baseColor
                    : alternateColor;

                Widget entry = RollLookupEntryView(
                  value: '${index * 2 + 1} - ${index * 2 + 2}',
                  label: name ?? 'Choose',
                  backgroundColor: backgroundColor,
                );

                if (name == null) {
                  entry = DefaultTextStyle.merge(
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: colors.onSurface.withValues(alpha: 0.5),
                    ),
                    child: entry,
                  );
                }

                return entry;
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
