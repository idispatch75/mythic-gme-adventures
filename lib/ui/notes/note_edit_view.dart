import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../helpers/input_validators.dart';
import '../widgets/edit_dialog.dart';
import '../widgets/rich_text_editor.dart';
import 'note.dart';

class NoteEditView extends HookWidget {
  final Note _note;
  final bool canDelete;

  const NoteEditView(this._note, {required this.canDelete, super.key});

  @override
  Widget build(BuildContext context) {
    final titleController = useTextEditingController(text: _note.title);
    final contentController = useRichTextEditorController(_note.content);

    final saveTrigger = false.obs;

    return EditDialog<bool>(
      itemTypeLabel: 'Note',
      canDelete: canDelete,
      onSave: () {
        _note.title = titleController.text;
        _note.content = contentController.text;

        return Future.value(true);
      },
      saveTrigger: saveTrigger,
      onDelete: () {
        Get.find<NotesService>().delete(_note);

        return Future.value();
      },
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: titleController,
            validator: validateNotEmpty,
            decoration: const InputDecoration(labelText: 'Title'),
            autofocus: _note.title.isEmpty,
            textCapitalization: TextCapitalization.sentences,
            onFieldSubmitted: (_) => EditDialog.triggerSave(saveTrigger),
          ),
          const SizedBox(height: 16),
          Flexible(
            fit: FlexFit.loose,
            child: RichTextEditor(
              controller: contentController,
              title: 'Content',
            ),
          ),
        ],
      ),
    );
  }
}
