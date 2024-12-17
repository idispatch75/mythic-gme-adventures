import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/list_view_utils.dart';
import '../../helpers/utils.dart';
import '../preferences/preferences.dart';
import '../roll_log/roll_log.dart';
import '../styles.dart';
import '../widgets/button_row.dart';
import 'listable_item.dart';

abstract class ListableItemsView<TItem extends ListableItem>
    extends StatelessWidget {
  final ListableItemsService<TItem> _controller;
  final bool showAddToListNotification;

  const ListableItemsView(
    this._controller, {
    this.showAddToListNotification = false,
    super.key,
  });

  String get itemTypeLabel;

  void createItem();

  Widget createItemView(Rx<TItem> item, {bool isDeleted = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Obx(() {
          final isPhysicalDiceModeEnabled = getPhysicalDiceModeEnabled;
          final canRoll =
              _controller.items.where((e) => !e.value.isArchived).length > 1;

          return ButtonRow(
            children: [
              // Roll button
              if (!isPhysicalDiceModeEnabled)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton.outlined(
                    onPressed: canRoll ? _roll : null,
                    icon: AppStyles.rollIcon,
                    tooltip: 'Roll a $itemTypeLabel in this list',
                  ),
                ),

              // Create button
              IconButton.filled(
                onPressed: createItem,
                icon: const Icon(Icons.add),
                tooltip: 'Create a $itemTypeLabel',
              ),
            ],
          );
        }),

        // list
        Expanded(
          child: Obx(
            () => defaultReorderableListView(
              items: _controller.items(),
              itemBuilder: (_, item, __) {
                return createItemView(item);
              },
              removedItemBuilder: (_, item) {
                return createItemView(item, isDeleted: true);
              },
              comparer: (a, b) => a().id == b().id,
              keyProvider: (item) => ValueKey(item().id),
              onReorderFinished: _controller.replaceAll,
            ),
          ),
        ),
      ],
    );
  }

  void _roll() {
    final validItems =
        _controller.items.where((e) => !e.value.isArchived).toList();
    final dieRoll = rollDie(validItems.length);

    Get.find<RollLogService>().addGenericRoll(
      title: '${itemTypeLabel}s',
      value: validItems[dieRoll - 1].value.name,
      dieRoll: dieRoll,
    );
  }
}

abstract class ListableItemView<TItem extends ListableItem>
    extends StatelessWidget {
  final ListableItemsService<TItem> _controller;
  final Rx<TItem> _item;
  final String _itemTypeLabel;
  final bool _showAddToListNotification;
  final bool isDeleted;

  const ListableItemView(
    this._controller,
    this._item,
    this._itemTypeLabel,
    this._showAddToListNotification, {
    this.isDeleted = false,
    super.key,
  });

  Widget createEditView(TItem item, bool canDelete);

  void onSaved(TItem item) {}

  @override
  Widget build(BuildContext context) {
    return ListTileTheme(
      key: ValueKey(_item().id),
      contentPadding: AppStyles.listTileTitlePadding,
      child: Obx(() {
        final item = _item.value;

        TextStyle? textStyle;
        if (item.isArchived) {
          textStyle = const TextStyle(color: AppStyles.archivedColor);
        }

        Widget? subtitle;
        if (item.summary != null && !item.isArchived) {
          subtitle = Text(item.summary!, style: textStyle);
        }

        Widget? addToListButton;
        if (!item.isArchived) {
          addToListButton = IconButton(
            onPressed: !isDeleted ? () => _addToList(context) : null,
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Add this $_itemTypeLabel'
                ' to the ${_itemTypeLabel}s List',
          );
        }

        return ListTile(
          title: Text(item.name, style: textStyle),
          subtitle: subtitle,
          trailing: addToListButton,
          onTap: !isDeleted ? _edit : null,
        );
      }),
    );
  }

  void _edit() async {
    final result = await Get.dialog<bool>(
      createEditView(_item.value, true),
      barrierDismissible: false,
    );

    if (result ?? false) {
      onSaved(_item());
      _item.refresh();
    }
  }

  void _addToList(BuildContext context) {
    _controller.addToItemsList(_item);

    if (_showAddToListNotification) {
      showSnackBar(
        context,
        '"${_item.value.name}" was added to the ${_itemTypeLabel}s List.',
      );
    }
  }
}
