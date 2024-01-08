import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../helpers/rx_list_extensions.dart';
import '../../helpers/utils.dart';
import '../../persisters/persister.dart';

abstract class ListableItem {
  final int id;
  String name;
  String? summary;
  String? notes;
  bool isArchived;

  ListableItem(
    this.id,
    this.name, {
    this.summary,
    this.notes,
    this.isArchived = false,
  });

  @override
  int get hashCode => id;

  @override
  bool operator ==(Object other) {
    return other.runtimeType == runtimeType && id == (other as ListableItem).id;
  }

  String toTag() => id.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (summary != null) 'summary': summary,
        if (notes != null) 'notes': notes,
        'isArchived': isArchived,
      };

  ListableItem.fromJson(Map<String, dynamic> json)
      : this(
          json['id'],
          json['name'],
          summary: json['summary'],
          notes: json['notes'],
          isArchived: json['isArchived'],
        );
}

class ListableItemsService<TItem extends ListableItem> extends GetxService
    with SavableMixin {
  final items = <Rx<TItem>>[].obs;
  final itemsList = <Rx<TItem>>[].obs;

  ListableItemsService();

  Rx<TItem> add(TItem item) {
    final rx = item.obs;
    items.add(item.obs);
    _sortItems(items);

    requestSave();
    return rx;
  }

  void delete(TItem item) {
    itemsList.replaceAll(itemsList.where((e) => e.value != item));
    items.removeWhere((e) => e.value == item);

    requestSave();
  }

  void archive(TItem item, bool isArchived) {
    _archiveItem(item, isArchived, items, itemsList);
  }

  void addToItemsList(Rx<TItem> item) {
    itemsList.add(item);

    requestSave();
  }

  void removeFromItemsList(Rx<TItem> item) {
    itemsList.remove(item);

    requestSave();
  }

  Map<String, dynamic> toJsonGeneric(String listName) => {
        listName: items,
        '${listName}List': itemsList.map((e) => e.value.id).toList(),
      };

  ListableItemsService.fromJson(
    Map<String, dynamic> json,
    String listName,
    TItem Function(Map<String, dynamic>) itemFactory,
  ) {
    final itemsListIds =
        List<int>.from(((json['${listName}List'] ?? []) as List));
    for (var item in fromJsonList(json[listName], itemFactory)) {
      final rxItem = add(item);

      for (final itemsListId in itemsListIds) {
        if (itemsListId == item.id) {
          addToItemsList(rxItem);
        }
      }
    }
  }

  void _archiveItem(
    TItem item,
    bool isArchived,
    RxList<Rx<TItem>> items,
    RxList<Rx<TItem>> itemsList,
  ) {
    if (item.isArchived != isArchived) {
      // remove the archived item from the items List
      if (isArchived) {
        itemsList.replaceAll(itemsList.where((e) => e.value != item));
      }
      item.isArchived = isArchived;

      _sortItems(items);

      requestSave();
    }
  }

  void _sortItems(RxList<Rx<TItem>> items) {
    // sort the list of items based on archived status
    items.value = items.sorted((a, b) {
      if (a.value.isArchived == b.value.isArchived) {
        return a.value.id - b.value.id;
      } else {
        return a.value.isArchived ? 1 : -1;
      }
    });
  }
}
