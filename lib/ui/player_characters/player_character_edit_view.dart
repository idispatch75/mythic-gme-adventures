import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../helpers/input_validators.dart';
import '../../helpers/string_extensions.dart';
import '../widgets/edit_dialog.dart';
import 'player_character.dart';

class PlayerCharacterEditView extends HookWidget {
  final PlayerCharacter _player;
  final bool _canDelete;

  const PlayerCharacterEditView(this._player, this._canDelete, {super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(text: _player.name);
    final notesController = useTextEditingController(text: _player.notes);

    final saveTrigger = false.obs;

    return EditDialog<bool>(
      itemTypeLabel: 'Player Character',
      canDelete: _canDelete,
      onSave: () {
        _player.name = nameController.text;
        _player.notes = notesController.text.nullIfEmpty();

        return Future.value(true);
      },
      saveTrigger: saveTrigger,
      onDelete: () {
        Get.find<PlayerCharactersService>().delete(_player);

        return Future.value();
      },
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nameController,
            validator: validateNotEmpty,
            decoration: const InputDecoration(labelText: 'Name'),
            autofocus: _player.name.isEmpty,
            onFieldSubmitted: (_) => EditDialog.triggerSave(saveTrigger),
          ),
          const SizedBox(height: 16),
          Flexible(
            fit: FlexFit.loose,
            child: TextFormField(
              controller: notesController,
              maxLines: null,
              minLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ),
        ],
      ),
    );
  }
}
