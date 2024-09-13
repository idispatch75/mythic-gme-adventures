import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../roll_log/roll_lookup_view.dart';
import '../styles.dart';
import 'thread.dart';
import 'thread_ctl.dart';

class ThreadDiscoveryLookupView extends StatelessWidget {
  final Thread thread;

  const ThreadDiscoveryLookupView(this.thread, {super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ThreadController>(tag: thread.toTag());

    return RollLookupView(
      header: 'Thread Discovery - 1d10+${thread.progress()}',
      rollColors: AppStyles.genericColors,
      entries: [
        RollLookupEntry(
          value: '1 - 9',
          label: 'Progress +2',
          onApply: () => controller.addProgress(2),
        ),
        RollLookupEntry(
          value: '10',
          label: 'Flashpoint +2',
          onApply: () => controller.addFlashpoint(2),
        ),
        RollLookupEntry(
          value: '11 - 14',
          label: 'Track +1',
          onApply: () => controller.addProgress(1),
        ),
        RollLookupEntry(
          value: '15 - 17',
          label: 'Progress +3',
          onApply: () => controller.addProgress(3),
        ),
        RollLookupEntry(
          value: '18',
          label: 'Flashpoint +3',
          onApply: () => controller.addFlashpoint(3),
        ),
        RollLookupEntry(
          value: '19',
          label: 'Track +2',
          onApply: () => controller.addProgress(2),
        ),
        RollLookupEntry(
          value: '20 - 24',
          label: 'Strengthen Progress +1',
          onApply: () => controller.addProgress(1),
        ),
        RollLookupEntry(
          value: '25+',
          label: 'Strengthen Progress +2',
          onApply: () => controller.addProgress(2),
        ),
      ],
    );
  }
}
