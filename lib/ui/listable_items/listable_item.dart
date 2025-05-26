import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../helpers/json_utils.dart';
import '../../helpers/rx_list_extensions.dart';
import '../../helpers/utils.dart';
import '../../persisters/persister.dart';
import '../global_settings/global_settings.dart';

abstract class ListableItem {
  final int id;
  String name;
  String? summary;
  String? notes;
  bool isArchived;
  int displayOrder;

  ListableItem(
    this.id,
    this.name, {
    this.summary,
    this.notes,
    this.isArchived = false,
    this.displayOrder = 0,
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
    'displayOrder': displayOrder,
  };

  ListableItem.fromJson(JsonObj json)
    : this(
        json['id'],
        json['name'],
        summary: json['summary'],
        notes: json['notes'],
        isArchived: json['isArchived'],
        displayOrder: json['displayOrder'] ?? 0,
      );
}

class ListableItemsService<TItem extends ListableItem> extends GetxService
    with SavableMixin {
  final items = <Rx<TItem>>[].obs;
  final itemsList = <Rx<TItem>>[].obs;

  ListableItemsService();

  Rx<TItem> add(TItem item) {
    item.displayOrder = items.length;

    final rx = item.obs;
    items.add(rx);
    _sortItems(items);

    requestSave();

    return rx;
  }

  void archive(TItem item, bool isArchived) {
    _archiveItem(item, isArchived, items, itemsList);
  }

  void delete(TItem item) {
    // IMPL use toList() to create a new list because itemsList is modified in replaceAll
    // and since where() is lazy, it will apply to the modified list
    itemsList.replaceAll(itemsList.where((e) => e.value != item).toList());
    items.removeWhere((e) => e.value == item);

    requestSave();
  }

  void replaceAll(List<Rx<TItem>> newItems) {
    for (var i = 0; i < newItems.length; i++) {
      newItems[i].value.displayOrder = i;
    }
    items.replaceAll(newItems);
    _sortItems(items);

    requestSave();
  }

  bool addToItemsList(Rx<TItem> item) {
    // prevent exceeding the recommended number of items
    final itemCount = itemsList
        .where((e) => e.value.id == item.value.id)
        .length;
    if (itemCount >= GlobalSettingsService.maxNumberOfItemsInList) {
      final globalSettings = Get.find<GlobalSettingsService>();
      if (!globalSettings.allowUnlimitedListCount) {
        if (Get.context != null) {
          showSnackBar(
            Get.context!,
            'The rules recommend not having more than ${GlobalSettingsService.maxNumberOfItemsInList} identical items in a List.'
            '\nYou can change this in the Global Settings.',
          );
        }

        return false;
      }
    }

    itemsList.add(item);

    requestSave();

    return true;
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
    final itemsListIds = List<int>.from(
      ((json['${listName}List'] ?? <int>[]) as List),
    );
    for (var item in fromJsonList(json[listName], itemFactory)) {
      final rxItem = add(item);

      for (final itemsListId in itemsListIds) {
        if (itemsListId == item.id) {
          itemsList.add(rxItem);
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
        return a.value.displayOrder - b.value.displayOrder;
      } else {
        return a.value.isArchived ? 1 : -1;
      }
    });

    itemsList.refresh();
  }
}
