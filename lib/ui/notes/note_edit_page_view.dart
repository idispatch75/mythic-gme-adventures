import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../helpers/dialogs.dart';
import '../../helpers/input_validators.dart';
import '../layouts/layout.dart';
import '../widgets/rich_text_editor.dart';
import 'note.dart';

class NoteEditPageService extends GetxService {
  final Note note;
  final Note temporaryData;
  final TextEditingController titleController;
  final RichTextEditorController contentController;
  bool isNew;

  Note get editedData => isNew ? temporaryData : note;

  NoteEditPageService(
    this.note, {
    required this.temporaryData,
    required this.isNew,
  }) : titleController = TextEditingController(text: temporaryData.title),
       contentController = RichTextEditorController(temporaryData.content);

  void save(String title, String? content) {
    note.title = title;
    note.content = content;

    if (isNew) {
      Get.find<NotesService>().add(note);
      isNew = false;
    }

    Get.find<NotesService>().requestSave();
  }

  void close() {
    titleController.dispose();
    contentController.dispose();

    Get.delete<NoteEditPageService>(force: true);
    Get.find<LayoutController>().hasEditNotePage.value = false;
  }
}

class NoteEditPageView extends HookWidget {
  final _formKey = GlobalKey<FormState>();

  NoteEditPageView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NoteEditPageService>();

    final titleController = controller.titleController;
    final contentController = controller.contentController;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: titleController,
            validator: validateNotEmpty,
            decoration: const InputDecoration(labelText: 'Title'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RichTextEditor(
              controller: contentController,
              title: 'Content',
              expands: true,
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
                    final title = titleController.text;
                    final content = contentController.text;
                    if (title != controller.editedData.title ||
                        content != controller.editedData.content) {
                      if (!await Dialogs.showConfirmation(
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
                        titleController.text,
                        contentController.text,
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
