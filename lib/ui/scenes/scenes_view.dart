import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/dialogs.dart';
import '../../helpers/utils.dart';
import '../chaos_factor/chaos_factor.dart';
import '../random_events/random_event.dart';
import '../roll_log/roll_log.dart';
import '../styles.dart';
import '../widgets/button_row.dart';
import '../widgets/round_badge.dart';
import 'scene.dart';
import 'scene_edit_view.dart';

class ScenesView extends GetView<ScenesService> {
  final bool dense;

  const ScenesView({this.dense = false, super.key});

  @override
  Widget build(BuildContext context) {
    final scenes = controller.scenes;

    return Column(
      children: [
        ButtonRow(
          children: [
            // roll adjustment
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: OutlinedButton(
                onPressed: _rollAdjustment,
                child: Text(dense ? 'Roll Adjust.' : 'Roll Adjustment'),
              ),
            ),

            // test scene
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: OutlinedButton(
                onPressed: _testScene,
                child: Text(dense ? 'Test Scene' : 'Test Expected Scene'),
              ),
            ),

            // add scene
            IconButton.filled(
              onPressed: _create,
              icon: const Icon(Icons.add),
              tooltip: 'Create a Scene',
            ),
          ],
        ),

        // list
        Expanded(
          child: Obx(
            () => defaultListView(
              itemCount: scenes.length,
              itemBuilder: (_, index) {
                int reverseIndex = scenes.length - index - 1;
                return _SceneView(reverseIndex, scenes[reverseIndex]);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _create() async {
    final scene = Scene(summary: '');

    final result = await Get.dialog<bool>(
      SceneEditView(scene, isNew: true),
      barrierDismissible: false,
    );

    if (result ?? false) {
      controller.add(scene);
    }
  }

  Future<void> _testScene() async {
    int chaosFactor = Get.find<ChaosFactorService>().chaosFactor();
    int dieRoll = roll10Die();

    if (dieRoll > chaosFactor) {
      // expected
      await showAlertDialog(
        title: 'Expected Scene',
        message: 'The scene happens as expected.',
      );
    } else {
      if (dieRoll % 2 == 1) {
        // altered
        await showAlertDialog(
          title: 'Altered Scene',
          message: 'Your expectations are sightly altered.\n'
              'You may consult the Fate Chart or the Meaning Tables.\n'
              'You may also roll an Adjustment.',
        );
      } else {
        // interrupt
        await showAlertDialog(
          title: 'Interrupt Scene',
          message: 'Mythic derails your expectations.\n'
              'A Random Event will be rolled.',
        );

        rollRandomEvent();
      }
    }
  }

  void _rollAdjustment() {
    void addSceneAdjustmentRoll(int dieRoll) {
      final adjustment = switch (dieRoll) {
        1 => 'Remove a Character',
        2 => 'Add a Character',
        3 => 'Reduce/Remove an Activity',
        4 => 'Increase an Activity',
        5 => 'Remove an Object',
        6 => 'Add an Object',
        _ => 'Make 2 Adjustments'
      };

      Get.find<RollLogService>().addGenericRoll(
        title: 'Scene Adjustment',
        value: adjustment,
        dieRoll: dieRoll,
      );
    }

    var dieRoll = roll10Die();
    if (dieRoll >= 7) {
      dieRoll = rollDie(6);
      addSceneAdjustmentRoll(dieRoll);

      var dieRoll2 = rollDie(6);
      while (dieRoll2 == dieRoll) {
        dieRoll2 = rollDie(6);
      }
      addSceneAdjustmentRoll(dieRoll2);
    } else {
      addSceneAdjustmentRoll(dieRoll);
    }
  }
}

class _SceneView extends GetView<ScenesService> {
  final int _sceneIndex;
  final Rx<Scene> _scene;

  const _SceneView(this._sceneIndex, this._scene);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListTile(
        leading: RoundBadge(
          backgroundColor: AppStyles.sceneBadgeBackground,
          color: AppStyles.sceneBadgeOnBackground,
          text: (_sceneIndex + 1).toString(),
        ),
        title: Text(
          _scene().summary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: _edit,
      ),
    );
  }

  void _edit() async {
    final result = await Get.dialog<bool>(
      SceneEditView(_scene(), isNew: false),
      barrierDismissible: false,
    );

    if (result ?? false) {
      _scene.refresh();

      controller.requestSave();
    }
  }
}
