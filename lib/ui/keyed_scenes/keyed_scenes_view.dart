import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/utils.dart';
import '../widgets/button_row.dart';
import 'keyed_scene.dart';
import 'keyed_scene_edit_view.dart';

class KeyedScenesView extends GetView<KeyedScenesService> {
  const KeyedScenesView({super.key});

  @override
  Widget build(BuildContext context) {
    final scenes = controller.scenes;

    return Column(
      children: [
        ButtonRow(
          children: [
            // add scene
            IconButton.filled(
              onPressed: _create,
              icon: const Icon(Icons.add),
              tooltip: 'Create a Keyed Scene',
            ),
          ],
        ),

        // list
        Expanded(
          child: Obx(
            () => defaultListView(
              itemCount: scenes.length,
              itemBuilder: (_, index) {
                return _SceneView(scenes[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _create() async {
    final scene = KeyedScene(trigger: '', event: '');

    final result = await Get.dialog<bool>(
      KeyedSceneEditView(scene, isNew: true),
      barrierDismissible: false,
    );

    if (result ?? false) {
      controller.add(scene);
    }
  }
}

class _SceneView extends GetView<KeyedScenesService> {
  final Rx<KeyedScene> _scene;

  const _SceneView(this._scene);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListTile(
        title: Text(
          _scene().trigger,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: _edit,
      ),
    );
  }

  void _edit() async {
    final result = await Get.dialog<bool>(
      KeyedSceneEditView(_scene(), isNew: false),
      barrierDismissible: false,
    );

    if (result ?? false) {
      _scene.refresh();

      controller.requestSave();
    }
  }
}
