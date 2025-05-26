import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/utils.dart';
import '../listable_items/listable_items_view.dart';
import 'thread.dart';
import 'thread_edit_view.dart';
import 'thread_progress_view.dart';

const threadItemTypeLabel = 'Thread';

class ThreadsView extends ListableItemsView<Thread> {
  ThreadsView({
    bool showAddToListNotification = false,
    Key? key,
  }) : super(
         _service,
         showAddToListNotification: showAddToListNotification,
         key: key,
       );

  @override
  void createItem() => createThread();

  @override
  Widget createItemView(Rx<Thread> item, {bool isDeleted = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // list item
        _ThreadView(
          _service,
          item,
          itemTypeLabel,
          showAddToListNotification,
          isDeleted: isDeleted,
        ),

        // progress view
        threadProgressViewWrapper(item(), isDeleted: isDeleted),
      ],
    );
  }

  @override
  String get itemTypeLabel => threadItemTypeLabel;
}

class _ThreadView extends ListableItemView<Thread> {
  const _ThreadView(
    super._controller,
    super.item,
    super.itemTypeLabel,
    super._showAddToListNotification, {
    super.isDeleted,
  });

  @override
  Widget createEditView(Thread item, bool canDelete) {
    return ThreadEditView(
      _service,
      item,
      threadItemTypeLabel,
      canDelete: canDelete,
    );
  }

  @override
  void onSaved(Thread item) {
    Get.find<ThreadComplementController>(tag: item.toTag()).save();
  }
}

Future<Rx<Thread>?> createThread() async {
  final thread = Thread(newId, '');
  final controller = _service;

  final result =
      await Get.dialog<bool>(
        ThreadEditView(
          controller,
          thread,
          threadItemTypeLabel,
          canDelete: false,
        ),
        barrierDismissible: false,
      ) ??
      false;

  if (result) {
    final result = controller.add(thread);
    Get.find<ThreadComplementController>(tag: thread.toTag()).save();
    return result;
  }

  return null;
}

ThreadsService get _service => Get.find<ThreadsService>();
