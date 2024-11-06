import '../../helpers/json_utils.dart';
import '../listable_items/listable_item.dart';

class Character extends ListableItem {
  Character(super.id, super.name);

  Character.fromJson(super.json) : super.fromJson();
}

class CharactersService extends ListableItemsService<Character> {
  CharactersService();

  JsonObj toJson() => toJsonGeneric('characters');

  CharactersService.fromJson(JsonObj json)
      : super.fromJson(json, 'characters', Character.fromJson);
}
