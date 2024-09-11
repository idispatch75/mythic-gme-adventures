import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../layouts/layout.dart';
import '../meaning_tables/meaning_table_details_view.dart';
import '../preferences/preferences.dart';
import 'roll_log_view.dart';

class PhysicalRollLogView extends StatelessWidget {
  const PhysicalRollLogView({super.key});

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
          widget = MeaningTableDetailsView(meaningTableDetails);
        }
      } else {
        widget = RollLogView();
      }

      return widget;
    });
  }
}
