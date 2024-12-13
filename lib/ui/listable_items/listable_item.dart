import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../helpers/json_utils.dart';
import '../../helpers/rx_list_extensions.dart';
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

  JsonObj toJson() => {
        'id': id,
        'name': name,
        if (summary != null) 'summary': summary,
        if (notes != null) 'notes': notes,
        'isArchived': isArchived,
      };

  ListableItem.fromJson(JsonObj json)
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
    // IMPL use toList() to create a new list because itemsList is modified in replaceAll
    // and since where() is lazy, it will apply to the modified list
    itemsList.replaceAll(itemsList.where((e) => e.value != item).toList());
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

  JsonObj toJsonGeneric(String listName) => {
        listName: items,
        '${listName}List': itemsList.map((e) => e.value.id).toList(),
      };

  ListableItemsService.fromJson(
    JsonObj json,
    String listName,
    TItem Function(JsonObj) itemFactory,
  ) {
    final itemsListIds =
        List<int>.from(((json['${listName}List'] ?? <int>[]) as List));
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
        // IMPL use toList() to create a new list because itemsList is modified in replaceAll
        // and since where() is lazy, it will apply to the modified list
        itemsList.replaceAll(itemsList.where((e) => e.value != item).toList());
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
