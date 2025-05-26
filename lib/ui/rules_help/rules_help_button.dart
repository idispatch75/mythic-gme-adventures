import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../global_settings/global_settings.dart';
import '../styles.dart';
import 'rules_help_view.dart';

class RulesHelpButton extends StatelessWidget {
  final RulesHelpEntry helpEntry;
  final Color? color;

  const RulesHelpButton({
    required this.helpEntry,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: const Icon(Icons.help_outline),
        color: iconColor.withAlpha(100),
        padding: EdgeInsets.zero,
        onPressed: () => showRulesHelp(helpEntry),
      ),
    );
  }
}

class RulesHelpWrapper extends StatelessWidget {
  final RulesHelpEntry helpEntry;
  final AlignmentGeometry alignment;
  final Color? iconColor;
  final Widget child;

  const RulesHelpWrapper({
    required this.helpEntry,
    required this.alignment,
    this.iconColor,
    required this.child,
    super.key,
  });

  RulesHelpWrapper.header({
    required this.helpEntry,
    required this.child,
    super.key,
  }) : iconColor = AppStyles.onHeaderColor,
       alignment = AlignmentDirectional.centerEnd;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hideButton = Get.find<GlobalSettingsService>().hideHelpButtons();
      if (hideButton) {
        return child;
      }

      return Stack(
        fit: StackFit.loose,
        alignment: alignment,
        children: [
          child,
          RulesHelpButton(
            color: iconColor,
            helpEntry: helpEntry,
          ),
        ],
      );
    });
  }
}

Future<void> showRulesHelp([RulesHelpEntry? helpEntry]) {
  return Get.dialog<void>(
    RulesHelpView(initialEntry: helpEntry),
    barrierDismissible: true,
  );
}
