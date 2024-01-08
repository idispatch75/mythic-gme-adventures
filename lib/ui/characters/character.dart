import '../listable_items/listable_item.dart';

class Character extends ListableItem {
  Character(super.id, super.name);

  Character.fromJson(super.json) : super.fromJson();
}

class CharactersService extends ListableItemsService<Character> {
  CharactersService();

  Map<String, dynamic> toJson() => toJsonGeneric('characters');

  CharactersService.fromJson(Map<String, dynamic> json)
      : super.fromJson(json, 'characters', Character.fromJson);
}
