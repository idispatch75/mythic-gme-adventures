import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../layouts/layout.dart';
import '../preferences/preferences.dart';
import '../styles.dart';
import 'meaning_table.dart';
import 'meaning_tables_ctl.dart';

class MeaningTablesView extends GetView<MeaningTablesController> {
  final bool isSmallLayout;

  const MeaningTablesView({required this.isSmallLayout, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        controller.getHeader(),
        Expanded(
          child: Obx(() {
            final buttons = controller.getButtons(isSmallLayout: isSmallLayout);

            return ListView.builder(
              itemCount: buttons.length,
              itemBuilder: (_, index) => buttons[index],
            );
          }),
        )
      ],
    );
  }
}

class MeaningTableButton extends GetView<MeaningTablesController> {
  final _borderSide = BorderSide(color: AppStyles.headerColor, width: 2);

  final MeaningTable _table;
  final bool isFavorite;
  final bool isSmallLayout;

  MeaningTableButton(
    this._table, {
    required this.isFavorite,
    required this.isSmallLayout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints:
          const BoxConstraints(maxHeight: AppStyles.oraclesButtonMaxHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: _borderSide,
            right: _borderSide,
            top: BorderSide.none,
            bottom: _borderSide,
          ),
        ),
        position: DecorationPosition.foreground,
        child: Container(
          color: AppStyles.meaningTableColors.background,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.passthrough,
            children: [
              // roll button
              Obx(() {
                final isPhysicalDiceModeEnabled =
                    Get.find<LocalPreferencesService>()
                        .enablePhysicalDiceMode
                        .value;

                return TextButton(
                  onPressed: () {
                    if (isPhysicalDiceModeEnabled) {
                      controller.showDetails(_table);

                      if (isSmallLayout) {
                        Get.find<LayoutController>().oraclesTabIndex(1);
                      }
                    } else {
                      controller.roll(_table.id);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppStyles.meaningTableColors.onBackground,
                    padding: const EdgeInsets.all(0),
                  ),
                  child: Text(
                    _table.name.toUpperCase(),
                    style: AppStyles.oraclesButtonTextStyle,
                  ),
                );
              }),

              // favorite
              Positioned(
                right: 0,
                child: IconButton(
                  onPressed: () => controller.chooseFavorite(_table),
                  iconSize: 16,
                  icon: Icon(isFavorite ? Icons.star : Icons.star_outline),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
