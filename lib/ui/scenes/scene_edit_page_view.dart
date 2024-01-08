import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../helpers/dialogs.dart';
import '../../helpers/input_validators.dart';
import '../../helpers/string_extensions.dart';
import '../layouts/layout.dart';
import 'scene.dart';

class SceneEditPageService extends GetxService {
  final Scene scene;
  final Scene temporaryData;
  bool isNew;

  Scene get editedData => isNew ? temporaryData : scene;

  SceneEditPageService(
    this.scene, {
    required this.temporaryData,
    required this.isNew,
  });

  void save(String summary, String? notes) {
    scene.summary = summary;
    scene.notes = notes;

    if (isNew) {
      Get.find<ScenesService>().add(scene);
      isNew = false;
    }

    Get.find<ScenesService>().requestSave();
  }

  void close() {
    Get.delete<SceneEditPageService>(force: true);
    Get.find<LayoutController>().hasEditScenePage.value = false;
  }
}

class SceneEditPageView extends HookWidget {
  final _formKey = GlobalKey<FormState>();

  SceneEditPageView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SceneEditPageService>();

    final summaryController =
        useTextEditingController(text: controller.editedData.summary);
    final notesController =
        useTextEditingController(text: controller.editedData.notes);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: summaryController,
            validator: validateNotEmpty,
            decoration: const InputDecoration(labelText: 'Summary'),
          ),
          Expanded(
            child: TextFormField(
              controller: notesController,
              maxLines: null,
              minLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ),

          // OK button
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: dialogButtonDirection == TextDirection.ltr
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              textDirection: dialogButtonDirection,
              children: [
                // Close button
                TextButton(
                  onPressed: () async {
                    final summary = summaryController.text;
                    final notes = notesController.text.nullIfEmpty();
                    if (summary != controller.editedData.summary ||
                        notes != controller.editedData.notes) {
                      if (!await showConfirmationDialog(
                        title: 'Close without saving',
                        message: 'You have unsaved changes.\nClose anyway?',
                      )) {
                        return;
                      }
                    }

                    controller.close();
                  },
                  child: const Text('Close'),
                ),

                const SizedBox(width: 8.0),

                // Save button
                FilledButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      controller.save(
                        summaryController.text,
                        notesController.text.nullIfEmpty(),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
