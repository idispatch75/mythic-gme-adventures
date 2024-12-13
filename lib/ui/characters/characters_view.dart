import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/utils.dart';
import '../listable_items/listable_items_view.dart';
import 'character.dart';
import 'character_edit_view.dart';

const characterItemTypeLabel = 'Character';

class CharactersView extends ListableItemsView<Character> {
  CharactersView({
    bool showAddToListNotification = false,
    Key? key,
  }) : super(
          _service,
          showAddToListNotification: showAddToListNotification,
          key: key,
        );

  @override
  void createItem() => createCharacter();

  @override
  Widget createItemView(Rx<Character> item) {
    return _CharacterView(
      _service,
      item,
      itemTypeLabel,
      showAddToListNotification,
    );
  }

  @override
  String get itemTypeLabel => characterItemTypeLabel;
}

class _CharacterView extends ListableItemView<Character> {
  const _CharacterView(
    super._controller,
    super.item,
    super.itemTypeLabel,
    super._showAddToListNotification,
  );

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

Future<Rx<Character>?> createCharacter() async {
  final character = Character(newId, '');
  final controller = _service;

  final result = await Get.dialog<bool>(
        CharacterEditView(
          controller,
          character,
          characterItemTypeLabel,
          canDelete: false,
        ),
        barrierDismissible: false,
      ) ??
      false;

  if (result) {
    return controller.add(character);
  }

  return null;
}

CharactersService get _service => Get.find<CharactersService>();
