import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../styles.dart';
import 'meaning_table.dart';
import 'meaning_tables_ctl.dart';

class MeaningTablesView extends GetView<MeaningTablesController> {
  const MeaningTablesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        controller.getHeader(),
        Expanded(
          child: Obx(() {
            final buttons = controller.getButtons();

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
  final bool _isFavorite;

  MeaningTableButton(this._table, this._isFavorite, {super.key});

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
              TextButton(
                onPressed: () => controller.roll(_table.id),
                style: TextButton.styleFrom(
                  foregroundColor: AppStyles.meaningTableColors.onBackground,
                  padding: const EdgeInsets.all(0),
                ),
                child: Text(
                  _table.name.toUpperCase(),
                  style: AppStyles.oraclesButtonTextStyle,
                ),
              ),

              // favorite
              Positioned(
                right: 0,
                child: IconButton(
                  onPressed: () => controller.chooseFavorite(_table),
                  iconSize: 16,
                  icon: Icon(_isFavorite ? Icons.star : Icons.star_outline),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
