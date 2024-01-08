import '../listable_items/listable_item_edit_view.dart';
import 'character.dart';

class CharacterEditView extends ListableItemEditView<Character> {
  const CharacterEditView(
      super._controller, super.item, super._itemTypeLabel, super.canDelete,
      {super.key});
}
