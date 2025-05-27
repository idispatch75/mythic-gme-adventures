import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../rules_help/rules_help_button.dart';
import '../rules_help/rules_help_view.dart';
import '../styles.dart';
import 'fate_chart.dart';

class FateChartView extends GetView<FateChartService> {
  const FateChartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppStyles.fateChartColors.background,
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RulesHelpWrapper.header(
              helpEntry: fateChartHelp,
              child: controller.getHeader(),
            ),
            ...controller.getRows(context),
          ],
        ),
      ),
    );
  }
}

class FateChartButton extends GetView<FateChartService> {
  static final borderSide = BorderSide(color: AppStyles.headerColor, width: 2);

  final String text;
  final VoidCallback? onPressed;
  final RollColors rollColors;
  final bool hasRightBorder;
  final bool hasFullWidth;

  const FateChartButton({
    required this.text,
    required this.onPressed,
    required this.rollColors,
    required this.hasRightBorder,
    required this.hasFullWidth,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final rightBorderSide = hasRightBorder ? borderSide : BorderSide.none;

    final button = Container(
      color: rollColors.background,
      constraints: const BoxConstraints(
        maxHeight: AppStyles.oraclesButtonMaxHeight,
      ),
      foregroundDecoration: BoxDecoration(
        border: Border(
          left: borderSide,
          right: rightBorderSide,
          top: BorderSide.none,
          bottom: borderSide,
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
