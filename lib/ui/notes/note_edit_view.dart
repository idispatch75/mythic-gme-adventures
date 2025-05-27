import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../helpers/get_extensions.dart';
import '../../helpers/input_validators.dart';
import '../layouts/layout.dart';
import '../widgets/edit_dialog.dart';
import '../widgets/rich_text_editor.dart';
import 'note.dart';
import 'note_edit_page_view.dart' show NoteEditPageService;

class NoteEditView extends HookWidget {
  final Note _note;
  final bool isNew;

  const NoteEditView(this._note, {required this.isNew, super.key});

  @override
  Widget build(BuildContext context) {
    final titleController = useTextEditingController(text: _note.title);
    final contentController = useRichTextEditorController(_note.content);

    final saveTrigger = false.obs;

    return EditDialog<bool>(
      itemTypeLabel: 'Note',
      canDelete: !isNew,
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

          // fullscreen edit button
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.fullscreen),
                label: const Text('Full screen edition'),
                onPressed: () {
                  final temporaryData = Note(
                    titleController.text,
                    content: contentController.text,
                  );
                  Get.replaceForced(
                    NoteEditPageService(
                      _note,
                      temporaryData: temporaryData,
                      isNew: isNew,
                    ),
                  );
                  Get.find<LayoutController>().hasEditNotePage.value = true;
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
