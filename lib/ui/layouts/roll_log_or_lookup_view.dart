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
      final meaningTableDetails =
          Get.find<LayoutController>().meaningTableDetails.value;

      final Widget widget;
      if (getPhysicalDiceModeEnabled) {
        if (meaningTableDetails == null) {
          widget = const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
                child: Text(
              'Click on a Meaning Table to display its content here',
              textAlign: TextAlign.center,
            )),
          );
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
