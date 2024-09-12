import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/utils.dart';
import '../preferences/preferences.dart';
import '../roll_log/roll_log.dart';
import '../styles.dart';
import '../widgets/button_row.dart';
import 'player_character.dart';
import 'player_character_edit_view.dart';

class PlayerCharactersView extends GetView<PlayerCharactersService> {
  const PlayerCharactersView({super.key});

  @override
  Widget build(BuildContext context) {
    final players = controller.playerCharacters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Obx(() {
          final isPhysicalDiceModeEnabled = getPhysicalDiceModeEnabled;
          final canRoll = players.isNotEmpty;

          return ButtonRow(
            children: [
              // Roll button
              if (!isPhysicalDiceModeEnabled)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton.outlined(
                    onPressed: canRoll ? _roll : null,
                    icon: AppStyles.rollIcon,
                    tooltip: 'Roll a Player Character in this list',
                  ),
                ),

              // Create button
              IconButton.filled(
                onPressed: _create,
                icon: const Icon(Icons.add),
                tooltip: 'Create a Player Character',
              ),
            ],
          );
        }),
        Expanded(
          child: Obx(
            () => defaultListView(
              itemCount: players.length,
              itemBuilder: (_, index) {
                return _PlayerCharacterView(players[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _create() async {
    final player = PlayerCharacter('');

    final result = await Get.dialog<bool>(
      PlayerCharacterEditView(player, false),
      barrierDismissible: false,
    );

    if (result ?? false) {
      controller.add(player);
    }
  }

  void _roll() {
    final players = controller.playerCharacters;
    final dieRoll = rollDie(players.length);

    Get.find<RollLogService>().addGenericRoll(
      title: 'Player Characters',
      value: players[dieRoll - 1].value.name,
      dieRoll: dieRoll,
    );
  }
}

class _PlayerCharacterView extends GetView<PlayerCharactersService> {
  final Rx<PlayerCharacter> _player;

  const _PlayerCharacterView(this._player);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListTile(
        title: Text(_player().name),
        onTap: _edit,
      ),
    );
  }

  void _edit() async {
    final result = await Get.dialog<bool>(
      PlayerCharacterEditView(_player(), true),
      barrierDismissible: false,
    );

    if (result ?? false) {
      _player.refresh();

      controller.requestSave();
    }
  }
}
