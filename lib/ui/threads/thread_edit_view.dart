import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/get_extensions.dart';
import '../listable_items/listable_item_edit_view.dart';
import '../widgets/boolean_setting.dart';
import '../widgets/rich_text_editor.dart';
import 'thread.dart';
import 'thread_ctl.dart';

class ThreadEditView extends ListableItemEditView<Thread> {
  ThreadEditView(
    super.controller,
    super.item,
    super.itemTypeLabel, {
    required super.canDelete,
    super.key,
  }) {
    Get.replaceForced(ThreadComplementController(item), tag: item.toTag());
  }

  @override
  Widget? getComplement({
    required RichTextEditorController notesController,
  }) => _ThreadComplementEditView(item);
}

class ThreadComplementController extends GetxController {
  final Thread _thread;
  final RxBool isTracked;
  final Rx<int> nbPhases;

  ThreadComplementController(this._thread)
    : isTracked = _thread.isTracked().obs,
      nbPhases = (_thread.phases.isEmpty ? 3 : _thread.phases.length).obs;

  void save() {
    final controller = Get.find<ThreadController>(tag: _thread.toTag());

    if (isTracked()) {
      if (isTracked() != _thread.isTracked() ||
          nbPhases() != _thread.phases.length) {
        controller.track(nbPhases());
      }
    } else {
      controller.untrack();
    }
  }
}

class _ThreadComplementEditView extends StatelessWidget {
  final Thread _thread;

  const _ThreadComplementEditView(this._thread);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ThreadComplementController>(
      tag: _thread.toTag(),
    );

    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Is tracked
          BooleanSetting(setting: controller.isTracked, text: 'Track Progress'),

          // track size
          if (controller.isTracked())
            SegmentedButton<int>(
              selected: {controller.nbPhases()},
              onSelectionChanged: (nbPhases) =>
                  controller.nbPhases.value = nbPhases.first,
              segments: [
                for (int nbPhases = 2; nbPhases < 5; nbPhases++)
                  ButtonSegment<int>(
                    value: nbPhases,
                    label: Text((nbPhases * 5).toString()),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
