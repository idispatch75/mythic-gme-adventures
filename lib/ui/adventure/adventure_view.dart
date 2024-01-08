import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/get_extensions.dart';
import '../../helpers/utils.dart';
import '../layouts/large_layout.dart';
import '../layouts/layout.dart';
import '../layouts/medium_layout.dart';
import '../layouts/small_layout.dart';
import '../widgets/progress_indicators.dart';
import 'adventure_ctl.dart';

class AdventureView extends GetView<AdventureController> {
  AdventureView(int id, {super.key}) {
    Get.replaceForced(AdventureController(id));
  }

  @override
  Widget build(BuildContext context) {
    return protectClose(
      child: controller.obx(
        (state) => SafeArea(
          child: LayoutBuilder(builder: (_, constraints) {
            if (constraints.maxWidth > 1160) {
              return const LargeLayout();
            } else if (constraints.maxWidth > kPhoneBreakPoint) {
              return const MediumLayout();
            } else {
              return const SmallLayout();
            }
          }),
        ),
        onLoading: const Scaffold(body: loadingIndicator),
      ),
    );
  }
}
