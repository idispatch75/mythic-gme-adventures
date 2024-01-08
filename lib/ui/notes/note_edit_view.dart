import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../helpers/input_validators.dart';
import '../../helpers/string_extensions.dart';
import '../widgets/edit_dialog.dart';
import 'note.dart';

class NoteEditView extends HookWidget {
  final Note _note;
  final bool _canDelete;

  const NoteEditView(this._note, this._canDelete, {super.key});

  @override
  Widget build(BuildContext context) {
    final titleController = useTextEditingController(text: _note.title);
    final contentController = useTextEditingController(text: _note.content);

    final saveTrigger = false.obs;

    return EditDialog<bool>(
      itemTypeLabel: 'Note',
      canDelete: _canDelete,
      onSave: () {
        _note.title = titleController.text;
        _note.content = contentController.text.nullIfEmpty();

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
            onFieldSubmitted: (_) => EditDialog.triggerSave(saveTrigger),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: TextFormField(
              controller: contentController,
              maxLines: null,
              minLines: 3,
              decoration: const InputDecoration(labelText: 'Content'),
            ),
          ),
        ],
      ),
    );
  }
}
