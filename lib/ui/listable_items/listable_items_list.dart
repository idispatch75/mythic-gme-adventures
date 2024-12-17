import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/list_view_utils.dart';
import '../../helpers/rx_list_extensions.dart';
import '../preferences/preferences.dart';
import '../random_events/random_event.dart';
import '../roll_log/roll_log.dart';
import '../styles.dart';
import '../widgets/button_row.dart';
import '../widgets/header.dart';
import '../widgets/round_badge.dart';
import 'listable_item.dart';

/// An item in a items list.
class ListItem<TItem extends ListableItem> {
  final TItem item;

  /// The number of occurrences of the item in the list
  final int count;

  const ListItem({required this.item, required this.count});

  // IMPL for some reason, if you pass around the Rx<Item>,
  // you cannot react to its changes.
  // So we store the item instead
  // and we retrieve the Rx<Item> from the source RxList.
}

abstract class ListableItemsListController<TItem extends ListableItem>
    extends GetxController {
  /// The list items aggregated from [sourceItemsList].
  final items = <ListItem<TItem>>[].obs;

  late StreamSubscription<List<Rx<TItem>>> _subscription;

  /// The individual listable items in the list.
  ///
  /// A same item can appear multiple times in the list.
  RxList<Rx<TItem>> get sourceItemsList;

  @override
  void onInit() {
    super.onInit();

    _subscription = sourceItemsList.listenAndPump((items) {
      this.items.replaceAll(groupBy(items, (e) => e.value)
          .entries
          .map((e) => ListItem(item: e.key, count: e.value.length))
          .sorted((a, b) => a.item.displayOrder - b.item.displayOrder));
    });
  }

  @override
  void onClose() {
    super.onClose();

    _subscription.cancel();
  }
}

abstract class ListableItemsListView<TItem extends ListableItem>
    extends StatelessWidget {
  const ListableItemsListView({super.key});

  ListableItemsListController<TItem> get controller;

  String get itemTypeLabel;

  String get listLabel => '${itemTypeLabel}s List';

  Future<void> createItem();

  Widget createItemView(ListItem<TItem> item, String itemLabel,
      {bool isDeleted = false});

  @override
  Widget build(BuildContext context) {
    final items = controller.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // header
        Header(listLabel),

        // buttons
        ButtonRow(
          children: [
            // roll
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Obx(
                () => IconButton.outlined(
                  onPressed: items.length > 1 ? () => _roll(context) : null,
                  icon: AppStyles.rollIcon,
                  tooltip: 'Roll a $itemTypeLabel in this list',
                ),
              ),
            ),

            // create new
            IconButton.filled(
              onPressed: createItem,
              icon: const Icon(Icons.add),
              tooltip: 'Create a $itemTypeLabel and adds it to this List',
            ),
          ],
        ),

        // list
        Expanded(
          child: Obx(
            () => defaultAnimatedListView(
              items: items(),
              itemBuilder: (_, item, __) {
                return createItemView(item, itemTypeLabel);
              },
              removedItemBuilder: (_, item) {
                return createItemView(item, itemTypeLabel, isDeleted: true);
              },
              comparer: (a, b) => a.item.id == b.item.id,
            ),
          ),
        ),
      ],
    );
  }

  void _roll(BuildContext context) {
    if (getPhysicalDiceModeEnabled) {
      showListItemsLookup<TItem>(context, listLabel,
          controller.sourceItemsList.map((e) => e.value).toList());
      return;
    }

    final result = rollListItem(controller.sourceItemsList);

    if (result != null) {
      Get.find<RollLogService>().addGenericRoll(
        title: listLabel,
        value: result.choose ? 'Choose' : result.item!.value.name,
        dieRoll: result.dieRoll,
      );
    }
  }
}

abstract class ListableItemListItemView<TItem extends ListableItem>
    extends StatelessWidget {
  final ListableItemsService<TItem> _controller;
  final ListItem<TItem> _listItem;
  final String _itemTypeLabel;
  final bool isDeleted;

  const ListableItemListItemView(
    this._controller,
    this._listItem,
    this._itemTypeLabel, {
    this.isDeleted = false,
    super.key,
  });

  Widget createEditView(TItem item, bool canDelete);

  void onSaved(TItem item) {}

  @override
  Widget build(BuildContext context) {
    final item = _controller.items
            .firstWhereOrNull((e) => e.value.id == _listItem.item.id) ??
        _listItem.item.obs;

    final title = LayoutBuilder(builder: (_, constraints) {
      Widget text = Obx(() => Text(
            item().name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ));

      if (constraints.maxWidth < 400) {
        text = Tooltip(
          message: item().name,
          waitDuration: const Duration(seconds: 1),
          child: text,
        );
      }

      return text;
    });

    final colorScheme = Theme.of(context).colorScheme;

    return ListTileTheme(
      key: ValueKey(_listItem.item.id),
      contentPadding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
      child: ListTile(
        key: ValueKey(_listItem.item.id),
        title: title,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // remove item
            IconButton(
              onPressed: !isDeleted
                  ? () => _controller.removeFromItemsList(item)
                  : null,
              icon: const Icon(Icons.remove),
              tooltip: 'Remove this $_itemTypeLabel from the List once',
            ),

            // number of items
            RoundBadge(
              key: key,
              backgroundColor: colorScheme.secondary,
              color: colorScheme.onSecondary,
              text: 'x${_listItem.count}',
            ),

            // add item
            IconButton(
              onPressed:
                  !isDeleted ? () => _controller.addToItemsList(item) : null,
              icon: const Icon(Icons.add),
              tooltip: 'Add this $_itemTypeLabel to the List again',
            ),
          ],
        ),
        onTap: !isDeleted ? () => _edit(item) : null,
      ),
    );
  }

  void _edit(Rx<TItem> item) async {
    final result = await Get.dialog<bool>(
      createEditView(item(), true),
      barrierDismissible: false,
    );

    if (result ?? false) {
      onSaved(item());
      item.refresh();
    }
  }
}
