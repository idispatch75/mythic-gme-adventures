import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../styles.dart';
import 'fate_chart.dart';

class FateChartView extends GetView<FateChartService> {
  const FateChartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppStyles.fateChartColors.background,
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            controller.getHeader(),
            ...controller.getRows(context),
          ],
        );
      }),
    );
  }
}

class FateChartButton extends GetView<FateChartService> {
  final _borderSide = BorderSide(color: AppStyles.headerColor, width: 2);

  final String text;
  final VoidCallback? onPressed;
  final RollColors rollColors;
  final bool hasRightBorder;
  final bool hasFullWidth;

  FateChartButton({
    required this.text,
    required this.onPressed,
    required this.rollColors,
    required this.hasRightBorder,
    required this.hasFullWidth,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final rightBorderSide = hasRightBorder ? _borderSide : BorderSide.none;

    final button = Container(
      color: rollColors.background,
      constraints:
          const BoxConstraints(maxHeight: AppStyles.oraclesButtonMaxHeight),
      foregroundDecoration: BoxDecoration(
        border: Border(
          left: _borderSide,
          right: rightBorderSide,
          top: BorderSide.none,
          bottom: _borderSide,
        ),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: rollColors.onBackground,
          padding: const EdgeInsets.all(0),
        ),
        child: Text(
          text.toUpperCase(),
          style: AppStyles.oraclesButtonTextStyle,
        ),
      ),
    );

    return hasFullWidth ? button : Expanded(child: button);
  }
}
