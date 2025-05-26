import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../listable_items/listable_items_list.dart';
import 'thread.dart';
import 'thread_edit_view.dart';
import 'thread_progress_view.dart';
import 'threads_view.dart';

class ThreadsListController extends ListableItemsListController<Thread> {
  @override
  RxList<Rx<Thread>> get sourceItemsList => _service.itemsList;
}

class ThreadsListView extends ListableItemsListView<Thread> {
  static const listItemTypeLabel = 'Thread';

  const ThreadsListView({super.key});

  @override
  ListableItemsListController<Thread> get controller =>
      Get.find<ThreadsListController>();

  @override
  String get itemTypeLabel => listItemTypeLabel;

  @override
  Future<void> createItem() async {
    final item = await createThread();
    if (item != null) {
      _service.addToItemsList(item);
    }
  }

  @override
  Widget createItemView(
    ListItem<Thread> item,
    String itemLabel, {
    bool isDeleted = false,
  }) {
    final thread =
        _service.items.firstWhereOrNull((e) => e.value.id == item.item.id) ??
        item.item.obs;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // thread view
        _ThreadView(_service, item, itemLabel, isDeleted: isDeleted),

        // progress view
        threadProgressViewWrapper(thread(), isDeleted: isDeleted),
      ],
    );
  }
}

class _ThreadView extends ListableItemListItemView<Thread> {
  const _ThreadView(
    super._controller,
    super._item,
    super._itemTypeLabel, {
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

ThreadsService get _service => Get.find<ThreadsService>();
