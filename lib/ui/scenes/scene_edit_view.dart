import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../helpers/get_extensions.dart';
import '../../helpers/input_validators.dart';
import '../layouts/layout.dart';
import '../widgets/edit_dialog.dart';
import '../widgets/rich_text_editor.dart';
import 'scene.dart';
import 'scene_edit_page_view.dart';

class SceneEditView extends HookWidget {
  final Scene _scene;
  final bool isNew;

  const SceneEditView(this._scene, {required this.isNew, super.key});

  @override
  Widget build(BuildContext context) {
    final summaryController = useTextEditingController(text: _scene.summary);
    final notesController = useRichTextEditorController(_scene.notes);

    final saveTrigger = false.obs;

    return EditDialog<bool>(
      itemTypeLabel: 'Scene',
      canDelete: !isNew,
      onSave: () {
        _scene.summary = summaryController.text;
        _scene.notes = notesController.text;

        return Future.value(true);
      },
      saveTrigger: saveTrigger,
      onDelete: () {
        Get.find<ScenesService>().delete(_scene);

        return Future.value();
      },
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: summaryController,
            validator: validateNotEmpty,
            decoration: const InputDecoration(labelText: 'Summary'),
            autofocus: _scene.summary.isEmpty,
            textCapitalization: TextCapitalization.sentences,
            onFieldSubmitted: (_) => EditDialog.triggerSave(saveTrigger),
          ),
          const SizedBox(height: 16),
          Flexible(
            fit: FlexFit.loose,
            child: RichTextEditor(
              controller: notesController,
              title: 'Notes',
            ),
          ),

          // fullscreen edit button
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.fullscreen),
                label: const Text('Full screen edition'),
                onPressed: () {
                  final temporaryData = Scene(
                    summary: summaryController.text,
                    notes: notesController.text,
                  );
                  Get.replaceForced(
                    SceneEditPageService(
                      _scene,
                      temporaryData: temporaryData,
                      isNew: isNew,
                    ),
                  );
                  Get.find<LayoutController>().hasEditScenePage.value = true;
                  Get.back<void>();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
