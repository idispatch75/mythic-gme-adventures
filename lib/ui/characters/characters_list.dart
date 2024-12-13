import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../listable_items/listable_items_list.dart';
import 'character.dart';
import 'character_edit_view.dart';
import 'characters_view.dart';

class CharactersListController extends ListableItemsListController<Character> {
  @override
  RxList<Rx<Character>> get sourceItemsList =>
      Get.find<CharactersService>().itemsList;
}

class CharactersListView extends ListableItemsListView<Character> {
  static const listItemTypeLabel = 'Character';

  const CharactersListView({super.key});

  @override
  ListableItemsListController<Character> get controller =>
      Get.find<CharactersListController>();

  @override
  String get itemTypeLabel => listItemTypeLabel;

  @override
  Future<void> createItem() async {
    final character = await createCharacter();
    if (character != null) {
      _service.addToItemsList(character);
    }
  }

  @override
  Widget createItemView(ListItem item, String itemLabel) {
    return _CharacterView(_service, item, itemLabel);
  }
}

class _CharacterView extends ListableItemListItemView<Character> {
  const _CharacterView(super._controller, super._item, super._itemTypeLabel);

  @override
  Widget createEditView(Character item, bool canDelete) {
    return CharacterEditView(
      _service,
      item,
      characterItemTypeLabel,
      canDelete: canDelete,
    );
  }
}

CharactersService get _service => Get.find<CharactersService>();
