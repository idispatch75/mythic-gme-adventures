import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../meaning_tables/meaning_table_lookup_view.dart';
import '../preferences/preferences.dart';
import '../roll_log/roll_log_view.dart';
import 'layout.dart';

class RollLogOrLookupView extends StatelessWidget {
  const RollLogOrLookupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isPhysicalDiceModeEnabled =
          Get.find<LocalPreferencesService>().enablePhysicalDiceMode.value;
      final meaningTableDetails =
          Get.find<LayoutController>().meaningTableDetails.value;

      final Widget widget;
      if (isPhysicalDiceModeEnabled) {
        if (meaningTableDetails == null) {
          widget = const Center(child: Text('Select a table to roll on'));
        } else {
          widget = MeaningTableLookupView(meaningTableDetails);
        }
      } else {
        widget = RollLogView();
      }

      return widget;
    });
  }
}
