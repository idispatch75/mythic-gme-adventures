import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../helpers/input_validators.dart';
import '../widgets/boolean_setting.dart';
import '../widgets/edit_dialog.dart';
import '../widgets/rich_text_editor.dart';
import 'feature.dart';

class FeatureEditView extends HookWidget {
  final Feature _feature;
  final bool canDelete;

  const FeatureEditView(
    this._feature, {
    required this.canDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(text: _feature.name);
    final notesController = useRichTextEditorController(_feature.notes);

    final isArchived = _feature.isArchived.obs;

    final saveTrigger = false.obs;

    return EditDialog<bool>(
      itemTypeLabel: 'Feature',
      canDelete: canDelete,
      saveTrigger: saveTrigger,
      onSave: () {
        _feature.name = nameController.text;
        _feature.notes = notesController.text;
        Get.find<FeaturesService>().archive(_feature, isArchived());

        return Future.value(true);
      },
      onDelete: () {
        Get.find<FeaturesService>().delete(_feature);

        return Future.value();
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nameController,
            validator: validateNotEmpty,
            decoration: const InputDecoration(labelText: 'Name'),
            autofocus: _feature.name.isEmpty,
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

          // archive
          if (canDelete)
            BooleanSetting(
              setting: isArchived,
              text: 'Archived',
              subtext:
                  'Archiving a Feature excludes it from Random Event rolls',
              withTopPadding: true,
            ),
        ],
      ),
    );
  }
}
